-- -----------------------------------------------------------------------------
-- KPI: Geographic concentration analysis (Herfindahl-Hirschman Index)
--
-- Measures market concentration across master projects to identify whether
-- transaction value and volume are concentrated in a few dominant projects
-- or distributed across many.  Uses the Herfindahl-Hirschman Index (HHI), a
-- standard measure of market concentration where:
--   - HHI < 1000: Competitive, diversified market
--   - HHI 1000-1800: Moderate concentration
--   - HHI > 1800: High concentration (oligopoly/monopoly)
--
-- Also calculates the CR4 (Concentration Ratio for top 4 projects) and
-- identifies the dominant projects by quarter.
-- -----------------------------------------------------------------------------

WITH quarterly_project_shares AS (
    -- Calculate each project's market share by value and volume per quarter
    SELECT
        date_trunc('quarter', st.txn_date)::date AS quarter_start,
        st.master_project_en,
        COUNT(*) AS txn_count,
        SUM(st.trans_value) AS project_value,
        SUM(SUM(st.trans_value)) OVER (PARTITION BY date_trunc('quarter', st.txn_date)) AS total_market_value,
        SUM(COUNT(*)) OVER (PARTITION BY date_trunc('quarter', st.txn_date)) AS total_market_volume
    FROM stg.dld_transactions st
    WHERE st.master_project_en IS NOT NULL 
      AND st.master_project_en != ''
      AND st.trans_value > 0
    GROUP BY 1, 2
),
market_shares AS (
    -- Calculate market share percentages
    SELECT
        quarter_start,
        master_project_en,
        txn_count,
        project_value,
        total_market_value,
        total_market_volume,
        (project_value::numeric / NULLIF(total_market_value, 0)) AS value_share,
        (txn_count::numeric / NULLIF(total_market_volume, 0)) AS volume_share
    FROM quarterly_project_shares
),
hhi_calculation AS (
    -- Calculate Herfindahl-Hirschman Index (sum of squared market shares)
    SELECT
        quarter_start,
        -- HHI by value (multiply by 10,000 to get standard HHI scale)
        SUM(POWER(value_share, 2)) * 10000 AS hhi_value,
        -- HHI by volume
        SUM(POWER(volume_share, 2)) * 10000 AS hhi_volume,
        -- Number of projects in the market
        COUNT(DISTINCT master_project_en) AS num_projects,
        -- Total market metrics
        MAX(total_market_value) AS total_market_value,
        MAX(total_market_volume) AS total_market_volume
    FROM market_shares
    GROUP BY quarter_start
),
top_projects AS (
    -- Identify top 4 projects by value each quarter
    SELECT
        quarter_start,
        master_project_en,
        project_value,
        value_share,
        ROW_NUMBER() OVER (PARTITION BY quarter_start ORDER BY project_value DESC) AS rank_by_value
    FROM market_shares
),
cr4_calculation AS (
    -- Calculate CR4 (Concentration Ratio for top 4 projects)
    SELECT
        quarter_start,
        SUM(value_share) AS cr4_value_share,
        STRING_AGG(master_project_en, ', ' ORDER BY rank_by_value) AS top_4_projects
    FROM top_projects
    WHERE rank_by_value <= 4
    GROUP BY quarter_start
)
SELECT
    h.quarter_start,
    h.num_projects,
    h.total_market_value,
    h.total_market_volume,
    ROUND(h.hhi_value::numeric, 2) AS hhi_value,
    ROUND(h.hhi_volume::numeric, 2) AS hhi_volume,
    ROUND((c.cr4_value_share * 100)::numeric, 2) AS cr4_percentage,
    c.top_4_projects,
    -- Concentration interpretation
    CASE
        WHEN h.hhi_value < 1000 THEN 'Competitive'
        WHEN h.hhi_value BETWEEN 1000 AND 1800 THEN 'Moderate Concentration'
        ELSE 'High Concentration'
    END AS market_structure_value,
    -- Calculate effective number of competitors (1/HHI when normalized)
    ROUND((10000.0 / NULLIF(h.hhi_value, 0))::numeric, 2) AS effective_competitors_value
FROM hhi_calculation h
JOIN cr4_calculation c ON c.quarter_start = h.quarter_start
ORDER BY h.quarter_start DESC;

-- ============================================================================
-- Additional query: Top 10 projects by market share (latest quarter)
-- ============================================================================

\echo ''
\echo 'Top 10 Projects by Market Share (Latest Quarter):'
\echo ''

WITH latest_quarter AS (
    SELECT MAX(date_trunc('quarter', txn_date)::date) AS quarter_start
    FROM stg.dld_transactions
),
quarterly_project_shares AS (
    SELECT
        date_trunc('quarter', st.txn_date)::date AS quarter_start,
        st.master_project_en,
        COUNT(*) AS txn_count,
        SUM(st.trans_value) AS project_value,
        SUM(SUM(st.trans_value)) OVER (PARTITION BY date_trunc('quarter', st.txn_date)) AS total_market_value,
        SUM(COUNT(*)) OVER (PARTITION BY date_trunc('quarter', st.txn_date)) AS total_market_volume
    FROM stg.dld_transactions st
    WHERE st.master_project_en IS NOT NULL 
      AND st.master_project_en != ''
      AND st.trans_value > 0
    GROUP BY 1, 2
)
SELECT
    master_project_en,
    txn_count,
    project_value,
    ROUND((project_value::numeric / NULLIF(total_market_value, 0) * 100)::numeric, 2) AS value_share_pct,
    ROUND((txn_count::numeric / NULLIF(total_market_volume, 0) * 100)::numeric, 2) AS volume_share_pct
FROM quarterly_project_shares
WHERE quarter_start = (SELECT quarter_start FROM latest_quarter)
ORDER BY project_value DESC
LIMIT 10;

-- ============================================================================
-- Insights from this analysis:
-- ============================================================================
--
-- 1. Market Concentration Trends:
--    - Is the market becoming more concentrated (HHI increasing) or more
--      competitive (HHI decreasing) over time?
--
-- 2. Dominant Players:
--    - Which 4 projects consistently dominate transaction value each quarter?
--    - Are the same projects always in the top 4, or is there turnover?
--
-- 3. Effective Competition:
--    - The "effective_competitors_value" metric shows how many equal-sized
--      competitors would produce the same HHI. E.g., HHI=2000 → ~5 effective
--      competitors even if there are 50+ actual projects.
--
-- 4. Investment Implications:
--    - High HHI (>1800) suggests limited competition, potentially indicating
--      strong pricing power for dominant developers.
--    - Declining HHI suggests new entrants fragmenting the market.
--
-- 5. CR4 Interpretation:
--    - CR4 > 50%: Top 4 projects control majority of market
--    - CR4 < 30%: Highly fragmented market with no dominant players
--
-- Example: If Q4 2024 shows HHI=1450 (moderate concentration) and CR4=42%,
-- this indicates a moderately concentrated market where the top 4 projects
-- account for 42% of transaction value, with meaningful competition from
-- mid-tier projects.
