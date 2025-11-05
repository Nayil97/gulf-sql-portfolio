-- -----------------------------------------------------------------------------
-- Query performance benchmarks
--
-- This script documents query execution plans and performance metrics for
-- key analytical queries.  Run EXPLAIN ANALYZE on production-scale data to
-- validate index effectiveness and identify optimization opportunities.
--
-- Usage:
--   psql -f sql/99_performance/query_benchmarks.sql > benchmarks_output.txt
-- -----------------------------------------------------------------------------

\timing on
\echo ''
\echo '========================================================================'
\echo 'QUERY BENCHMARK SUITE - GCC Real Estate Analytics'
\echo '========================================================================'
\echo ''

-- ============================================================================
-- Benchmark 1: Median price per sqm by segment (common dashboard query)
-- ============================================================================

\echo 'Benchmark 1: Median price per sqm by segment'
\echo 'Expected: <50ms with indexes, <500ms without'
\echo ''

EXPLAIN (ANALYZE, BUFFERS, VERBOSE)
WITH base AS (
    SELECT
        dd.month_start,
        st.prop_type_en,
        st.usage_en,
        st.is_offplan,
        st.trans_value / NULLIF(st.actual_area, 0) AS price_per_sqm
    FROM stg.dld_transactions st
    JOIN dw.dim_date dd ON dd.date = st.txn_date
    WHERE st.trans_value > 0 AND st.actual_area > 0
)
SELECT
    month_start,
    prop_type_en,
    usage_en,
    is_offplan,
    percentile_cont(0.5) WITHIN GROUP (ORDER BY price_per_sqm) AS median_price_sqm,
    COUNT(*) AS txn_count
FROM base
GROUP BY 1,2,3,4
ORDER BY 1 DESC
LIMIT 100;

\echo ''
\echo '------------------------------------------------------------------------'
\echo ''

-- ============================================================================
-- Benchmark 2: Monthly volume and value trends with growth rates
-- ============================================================================

\echo 'Benchmark 2: Monthly trends with MoM and YoY growth'
\echo 'Expected: <100ms with window function optimization'
\echo ''

EXPLAIN (ANALYZE, BUFFERS, VERBOSE)
WITH monthly AS (
    SELECT
        date_trunc('month', txn_date)::date AS month_start,
        SUM(trans_value) AS total_value,
        COUNT(*) AS total_volume
    FROM stg.dld_transactions
    GROUP BY 1
),
enriched AS (
    SELECT
        month_start,
        total_value,
        total_volume,
        (total_value / NULLIF(LAG(total_value) OVER (ORDER BY month_start), 0) - 1) AS mom_value_growth,
        (total_volume::numeric / NULLIF(LAG(total_volume) OVER (ORDER BY month_start), 0) - 1) AS mom_volume_growth,
        (total_value / NULLIF(LAG(total_value, 12) OVER (ORDER BY month_start), 0) - 1) AS yoy_value_growth,
        (total_volume::numeric / NULLIF(LAG(total_volume, 12) OVER (ORDER BY month_start), 0) - 1) AS yoy_volume_growth
    FROM monthly
)
SELECT *
FROM enriched
ORDER BY month_start DESC
LIMIT 50;

\echo ''
\echo '------------------------------------------------------------------------'
\echo ''

-- ============================================================================
-- Benchmark 3: Project leaderboard (dense ranking with window functions)
-- ============================================================================

\echo 'Benchmark 3: Quarterly project leaderboard'
\echo 'Expected: <200ms for complex window functions'
\echo ''

EXPLAIN (ANALYZE, BUFFERS, VERBOSE)
WITH base AS (
    SELECT
        st.master_project_en,
        date_trunc('quarter', st.txn_date)::date AS quarter_start,
        SUM(st.trans_value) AS total_value,
        COUNT(*) AS total_volume,
        percentile_cont(0.5) WITHIN GROUP (ORDER BY st.trans_value / NULLIF(st.actual_area, 0)) AS median_price_sqm
    FROM stg.dld_transactions st
    WHERE st.trans_value > 0 
      AND st.actual_area > 0
      AND st.master_project_en IS NOT NULL
      AND st.master_project_en != ''
    GROUP BY 1, 2
),
ranked AS (
    SELECT
        *,
        DENSE_RANK() OVER (PARTITION BY quarter_start ORDER BY median_price_sqm DESC) AS rank_by_price,
        DENSE_RANK() OVER (PARTITION BY quarter_start ORDER BY total_value DESC) AS rank_by_value
    FROM base
)
SELECT
    quarter_start,
    master_project_en,
    median_price_sqm,
    total_value,
    total_volume,
    rank_by_price,
    rank_by_value
FROM ranked
WHERE rank_by_price <= 10 OR rank_by_value <= 10
ORDER BY quarter_start DESC, rank_by_value
LIMIT 100;

\echo ''
\echo '------------------------------------------------------------------------'
\echo ''

-- ============================================================================
-- Benchmark 4: Fact table star schema join (typical BI query pattern)
-- ============================================================================

\echo 'Benchmark 4: Star schema join with filters'
\echo 'Expected: <30ms with foreign key indexes'
\echo ''

EXPLAIN (ANALYZE, BUFFERS, VERBOSE)
SELECT
    dd.year_month,
    dp.prop_type_en,
    dp.is_offplan,
    COUNT(*) AS txn_count,
    SUM(ft.trans_value) AS total_value,
    AVG(ft.price_per_sqm) AS avg_price_sqm
FROM dw.fact_transactions ft
JOIN dw.dim_date dd ON dd.date_key = ft.date_key
JOIN dw.dim_property dp ON dp.property_key = ft.property_key
WHERE dd.year = 2024
  AND dp.usage_en = 'Residential'
GROUP BY 1, 2, 3
ORDER BY 1, 2, 3;

\echo ''
\echo '------------------------------------------------------------------------'
\echo ''

-- ============================================================================
-- Benchmark 5: Correlation calculation (macro-RE analysis)
-- ============================================================================

\echo 'Benchmark 5: Macro-economic correlation'
\echo 'Expected: <150ms for correlation across quarters'
\echo ''

EXPLAIN (ANALYZE, BUFFERS, VERBOSE)
WITH dld_q AS (
    SELECT
        date_trunc('quarter', txn_date)::date AS quarter_start,
        SUM(trans_value) AS q_value,
        COUNT(*) AS q_volume,
        percentile_cont(0.5) WITHIN GROUP (ORDER BY trans_value / NULLIF(actual_area, 0)) AS q_median_price_sqm
    FROM stg.dld_transactions
    WHERE trans_value > 0 AND actual_area > 0
    GROUP BY 1
),
cpi AS (
    SELECT
        item_code,
        item_desc,
        quarter_start,
        cpi_index
    FROM stg.gastat_cpi_long
)
SELECT
    c.item_desc,
    corr(d.q_value::numeric, c.cpi_index) AS corr_value,
    corr(d.q_volume::numeric, c.cpi_index) AS corr_volume,
    corr(d.q_median_price_sqm, c.cpi_index) AS corr_price_sqm,
    COUNT(*) AS n_quarters
FROM dld_q d
JOIN cpi c ON c.quarter_start = d.quarter_start
GROUP BY c.item_desc
HAVING COUNT(*) >= 8
ORDER BY ABS(corr_value) DESC NULLS LAST;

\echo ''
\echo '------------------------------------------------------------------------'
\echo ''

-- ============================================================================
-- Benchmark 6: Off-plan share calculation
-- ============================================================================

\echo 'Benchmark 6: Off-plan share by period'
\echo 'Expected: <50ms with segment indexes'
\echo ''

EXPLAIN (ANALYZE, BUFFERS, VERBOSE)
SELECT
    date_trunc('month', txn_date)::date AS month_start,
    SUM(CASE WHEN is_offplan THEN 1 ELSE 0 END)::numeric / COUNT(*) AS offplan_volume_share,
    SUM(CASE WHEN is_offplan THEN trans_value ELSE 0 END) / NULLIF(SUM(trans_value), 0) AS offplan_value_share,
    COUNT(*) AS total_volume,
    SUM(trans_value) AS total_value
FROM stg.dld_transactions
GROUP BY 1
ORDER BY 1 DESC
LIMIT 48;

\echo ''
\echo '------------------------------------------------------------------------'
\echo ''

-- ============================================================================
-- Benchmark 7: High-value transactions (partial index test)
-- ============================================================================

\echo 'Benchmark 7: High-value luxury segment query (partial index)'
\echo 'Expected: <10ms with partial index on high values'
\echo ''

EXPLAIN (ANALYZE, BUFFERS, VERBOSE)
SELECT
    prop_type_en,
    master_project_en,
    COUNT(*) AS high_value_txns,
    AVG(trans_value) AS avg_value,
    AVG(actual_area) AS avg_area,
    AVG(trans_value / NULLIF(actual_area, 0)) AS avg_price_sqm
FROM stg.dld_transactions
WHERE trans_value > 5000000
GROUP BY 1, 2
HAVING COUNT(*) >= 5
ORDER BY high_value_txns DESC
LIMIT 20;

\echo ''
\echo '------------------------------------------------------------------------'
\echo ''

-- ============================================================================
-- Benchmark 8: Expression index test (price per sqm)
-- ============================================================================

\echo 'Benchmark 8: Query using price per sqm expression index'
\echo 'Expected: <20ms with expression index'
\echo ''

EXPLAIN (ANALYZE, BUFFERS, VERBOSE)
SELECT
    month_start,
    prop_type_en,
    COUNT(*) AS txn_count
FROM stg.dld_transactions
WHERE (trans_value / NULLIF(actual_area, 0)) BETWEEN 8000 AND 15000
  AND is_offplan = false
GROUP BY 1, 2
ORDER BY 1 DESC
LIMIT 100;

\echo ''
\echo '------------------------------------------------------------------------'
\echo ''

-- ============================================================================
-- Summary: Index Usage Statistics
-- ============================================================================

\echo 'Index Usage Statistics (Top 20 most-used indexes):'
\echo ''

SELECT
    schemaname,
    tablename,
    indexname,
    idx_scan AS times_used,
    idx_tup_read AS tuples_read,
    idx_tup_fetch AS tuples_fetched,
    pg_size_pretty(pg_relation_size(indexrelid)) AS index_size
FROM pg_stat_user_indexes
WHERE schemaname IN ('stg', 'dw')
ORDER BY idx_scan DESC
LIMIT 20;

\echo ''
\echo '========================================================================'
\echo 'BENCHMARK COMPLETE'
\echo '========================================================================'
\echo ''
\echo 'Review the EXPLAIN ANALYZE output above to identify:'
\echo '  - Sequential scans (may need indexes)'
\echo '  - High execution times (>100ms)'
\echo '  - Buffer usage (shared_buffers tuning)'
\echo '  - Sort operations (consider indexed columns)'
\echo ''
\echo 'For production deployment:'
\echo '  1. Run these benchmarks on representative data volumes'
\echo '  2. Adjust shared_buffers and work_mem based on buffer statistics'
\echo '  3. Monitor idx_scan in pg_stat_user_indexes to identify unused indexes'
\echo '  4. Consider VACUUM ANALYZE if query plans are sub-optimal'
\echo ''

\timing off
