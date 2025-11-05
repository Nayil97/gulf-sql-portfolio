-- -----------------------------------------------------------------------------
-- Materialized views for Power BI and dashboard performance
--
-- These materialized views pre-aggregate expensive calculations to provide
-- sub-second response times for dashboard queries.  They should be refreshed
-- periodically (e.g., daily or after data loads) using the refresh scripts.
-- -----------------------------------------------------------------------------

-- ============================================================================
-- MV 1: Monthly metrics by segment (replaces v_dashboard_metrics)
-- ============================================================================

DROP MATERIALIZED VIEW IF EXISTS dw.mv_monthly_metrics CASCADE;

CREATE MATERIALIZED VIEW dw.mv_monthly_metrics AS
SELECT
    dd.year_month AS period,
    dd.year,
    dd.month,
    dp.prop_type_en,
    dp.usage_en,
    dp.is_offplan,
    COUNT(*) AS txn_count,
    SUM(ft.trans_value) AS total_value,
    SUM(ft.actual_area) AS total_area,
    AVG(ft.price_per_sqm) AS avg_price_sqm,
    percentile_cont(0.5) WITHIN GROUP (ORDER BY ft.price_per_sqm) AS median_price_sqm,
    percentile_cont(0.25) WITHIN GROUP (ORDER BY ft.price_per_sqm) AS p25_price_sqm,
    percentile_cont(0.75) WITHIN GROUP (ORDER BY ft.price_per_sqm) AS p75_price_sqm,
    MIN(ft.price_per_sqm) AS min_price_sqm,
    MAX(ft.price_per_sqm) AS max_price_sqm,
    stddev(ft.price_per_sqm) AS stddev_price_sqm
FROM dw.fact_transactions ft
JOIN dw.dim_date dd ON dd.date_key = ft.date_key
JOIN dw.dim_property dp ON dp.property_key = ft.property_key
GROUP BY dd.year_month, dd.year, dd.month, dp.prop_type_en, dp.usage_en, dp.is_offplan;

-- Indexes for efficient filtering and sorting
CREATE INDEX mv_monthly_metrics_period_idx ON dw.mv_monthly_metrics (period);
CREATE INDEX mv_monthly_metrics_segment_idx ON dw.mv_monthly_metrics (prop_type_en, usage_en, is_offplan);
CREATE INDEX mv_monthly_metrics_year_month_idx ON dw.mv_monthly_metrics (year, month);

COMMENT ON MATERIALIZED VIEW dw.mv_monthly_metrics IS 
'Pre-aggregated monthly metrics by property segment for dashboard performance. Refresh daily or after data loads.';

-- ============================================================================
-- MV 2: Quarterly project leaderboard
-- ============================================================================

DROP MATERIALIZED VIEW IF EXISTS dw.mv_project_leaderboard CASCADE;

CREATE MATERIALIZED VIEW dw.mv_project_leaderboard AS
WITH base AS (
    SELECT
        dd.quarter_start,
        dd.year,
        dd.quarter,
        pr.master_project_en,
        pr.project_en,
        SUM(ft.trans_value) AS total_value,
        COUNT(*) AS total_volume,
        percentile_cont(0.5) WITHIN GROUP (ORDER BY ft.price_per_sqm) AS median_price_sqm,
        AVG(ft.price_per_sqm) AS avg_price_sqm
    FROM dw.fact_transactions ft
    JOIN dw.dim_date dd ON dd.date_key = ft.date_key
    JOIN dw.dim_project pr ON pr.project_key = ft.project_key
    WHERE pr.master_project_en IS NOT NULL 
      AND pr.master_project_en != ''
    GROUP BY dd.quarter_start, dd.year, dd.quarter, pr.master_project_en, pr.project_en
)
SELECT
    *,
    DENSE_RANK() OVER (PARTITION BY quarter_start ORDER BY median_price_sqm DESC) AS rank_by_price,
    DENSE_RANK() OVER (PARTITION BY quarter_start ORDER BY total_value DESC) AS rank_by_value,
    DENSE_RANK() OVER (PARTITION BY quarter_start ORDER BY total_volume DESC) AS rank_by_volume
FROM base;

CREATE INDEX mv_project_leaderboard_quarter_idx ON dw.mv_project_leaderboard (quarter_start);
CREATE INDEX mv_project_leaderboard_master_idx ON dw.mv_project_leaderboard (master_project_en);
CREATE INDEX mv_project_leaderboard_rank_price_idx ON dw.mv_project_leaderboard (rank_by_price);

COMMENT ON MATERIALIZED VIEW dw.mv_project_leaderboard IS
'Quarterly project rankings by price, value, and volume. Refresh after data loads.';

-- ============================================================================
-- MV 3: Time-series trends with growth rates
-- ============================================================================

DROP MATERIALIZED VIEW IF EXISTS dw.mv_trends CASCADE;

CREATE MATERIALIZED VIEW dw.mv_trends AS
WITH monthly AS (
    SELECT
        dd.year_month,
        MIN(dd.date) AS month_start,
        dp.is_offplan,
        SUM(ft.trans_value) AS total_value,
        COUNT(*) AS total_volume,
        percentile_cont(0.5) WITHIN GROUP (ORDER BY ft.price_per_sqm) AS median_price_sqm
    FROM dw.fact_transactions ft
    JOIN dw.dim_date dd ON dd.date_key = ft.date_key
    JOIN dw.dim_property dp ON dp.property_key = ft.property_key
    GROUP BY dd.year_month, dp.is_offplan
)
SELECT
    year_month,
    month_start,
    is_offplan,
    total_value,
    total_volume,
    median_price_sqm,
    -- Month-over-month growth
    (total_value / NULLIF(LAG(total_value) OVER (PARTITION BY is_offplan ORDER BY month_start), 0) - 1) AS mom_value_growth,
    (total_volume::numeric / NULLIF(LAG(total_volume) OVER (PARTITION BY is_offplan ORDER BY month_start), 0) - 1) AS mom_volume_growth,
    (median_price_sqm / NULLIF(LAG(median_price_sqm) OVER (PARTITION BY is_offplan ORDER BY month_start), 0) - 1) AS mom_price_growth,
    -- Year-over-year growth
    (total_value / NULLIF(LAG(total_value, 12) OVER (PARTITION BY is_offplan ORDER BY month_start), 0) - 1) AS yoy_value_growth,
    (total_volume::numeric / NULLIF(LAG(total_volume, 12) OVER (PARTITION BY is_offplan ORDER BY month_start), 0) - 1) AS yoy_volume_growth,
    (median_price_sqm / NULLIF(LAG(median_price_sqm, 12) OVER (PARTITION BY is_offplan ORDER BY month_start), 0) - 1) AS yoy_price_growth,
    -- Rolling 3-month averages for smoothing
    AVG(total_value) OVER (PARTITION BY is_offplan ORDER BY month_start ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS ma3_value,
    AVG(total_volume) OVER (PARTITION BY is_offplan ORDER BY month_start ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS ma3_volume,
    AVG(median_price_sqm) OVER (PARTITION BY is_offplan ORDER BY month_start ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS ma3_price_sqm
FROM monthly;

CREATE INDEX mv_trends_month_idx ON dw.mv_trends (month_start);
CREATE INDEX mv_trends_offplan_idx ON dw.mv_trends (is_offplan);

COMMENT ON MATERIALIZED VIEW dw.mv_trends IS
'Pre-calculated time-series trends with MoM, YoY, and moving averages. Refresh daily.';

-- ============================================================================
-- MV 4: Off-plan share metrics
-- ============================================================================

DROP MATERIALIZED VIEW IF EXISTS dw.mv_offplan_share CASCADE;

CREATE MATERIALIZED VIEW dw.mv_offplan_share AS
WITH monthly_total AS (
    SELECT
        dd.year_month,
        MIN(dd.date) AS month_start,
        SUM(ft.trans_value) AS total_value_all,
        COUNT(*) AS total_volume_all
    FROM dw.fact_transactions ft
    JOIN dw.dim_date dd ON dd.date_key = ft.date_key
    GROUP BY dd.year_month
),
monthly_offplan AS (
    SELECT
        dd.year_month,
        MIN(dd.date) AS month_start,
        SUM(ft.trans_value) AS total_value_offplan,
        COUNT(*) AS total_volume_offplan
    FROM dw.fact_transactions ft
    JOIN dw.dim_date dd ON dd.date_key = ft.date_key
    JOIN dw.dim_property dp ON dp.property_key = ft.property_key
    WHERE dp.is_offplan = true
    GROUP BY dd.year_month
)
SELECT
    t.year_month,
    t.month_start,
    t.total_value_all,
    t.total_volume_all,
    COALESCE(o.total_value_offplan, 0) AS total_value_offplan,
    COALESCE(o.total_volume_offplan, 0) AS total_volume_offplan,
    COALESCE(o.total_value_offplan, 0)::numeric / NULLIF(t.total_value_all, 0) AS offplan_value_share,
    COALESCE(o.total_volume_offplan, 0)::numeric / NULLIF(t.total_volume_all, 0) AS offplan_volume_share
FROM monthly_total t
LEFT JOIN monthly_offplan o ON o.year_month = t.year_month;

CREATE INDEX mv_offplan_share_month_idx ON dw.mv_offplan_share (month_start);

COMMENT ON MATERIALIZED VIEW dw.mv_offplan_share IS
'Off-plan transaction share by value and volume over time. Refresh daily.';

-- ============================================================================
-- MV 5: CPI correlation pre-calculated
-- ============================================================================

DROP MATERIALIZED VIEW IF EXISTS dw.mv_macro_correlation CASCADE;

CREATE MATERIALIZED VIEW dw.mv_macro_correlation AS
WITH dld_q AS (
    SELECT
        dd.quarter_start,
        SUM(ft.trans_value) AS q_value,
        COUNT(*) AS q_volume,
        percentile_cont(0.5) WITHIN GROUP (ORDER BY ft.price_per_sqm) AS q_median_price_sqm
    FROM dw.fact_transactions ft
    JOIN dw.dim_date dd ON dd.date_key = ft.date_key
    GROUP BY dd.quarter_start
),
cpi AS (
    SELECT
        item_code,
        item_desc,
        quarter_start,
        cpi_index,
        qoq,
        yoy
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
GROUP BY c.item_desc;

COMMENT ON MATERIALIZED VIEW dw.mv_macro_correlation IS
'Pre-calculated correlation coefficients between real estate and CPI. Refresh after data loads.';

-- ============================================================================
-- Refresh script (run after data loads)
-- ============================================================================

-- Uncomment and run to refresh all materialized views:
-- REFRESH MATERIALIZED VIEW CONCURRENTLY dw.mv_monthly_metrics;
-- REFRESH MATERIALIZED VIEW CONCURRENTLY dw.mv_project_leaderboard;
-- REFRESH MATERIALIZED VIEW CONCURRENTLY dw.mv_trends;
-- REFRESH MATERIALIZED VIEW CONCURRENTLY dw.mv_offplan_share;
-- REFRESH MATERIALIZED VIEW CONCURRENTLY dw.mv_macro_correlation;

-- Note: CONCURRENTLY requires unique indexes on the materialized views
-- For production, add unique indexes if concurrent refresh is needed

ANALYZE dw.mv_monthly_metrics;
ANALYZE dw.mv_project_leaderboard;
ANALYZE dw.mv_trends;
ANALYZE dw.mv_offplan_share;
ANALYZE dw.mv_macro_correlation;
