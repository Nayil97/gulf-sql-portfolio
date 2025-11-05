-- -----------------------------------------------------------------------------
-- KPI: Cohort analysis for project launches
--
-- Tracks project performance over time by identifying when projects first
-- appeared in the market (launch quarter) and analyzing their subsequent
-- performance trajectory.  This identifies which launch periods produced
-- the most successful projects and whether early momentum predicts long-term
-- success.
-- -----------------------------------------------------------------------------

WITH project_launch AS (
    -- Identify the first quarter each project appeared in transactions
    SELECT
        master_project_en,
        project_en,
        MIN(date_trunc('quarter', txn_date)::date) AS launch_quarter
    FROM stg.dld_transactions
    WHERE master_project_en IS NOT NULL 
      AND master_project_en != ''
    GROUP BY 1, 2
),
quarterly_performance AS (
    -- Calculate performance metrics by project and quarter
    SELECT
        st.master_project_en,
        st.project_en,
        date_trunc('quarter', st.txn_date)::date AS activity_quarter,
        COUNT(*) AS txn_count,
        SUM(st.trans_value) AS total_value,
        percentile_cont(0.5) WITHIN GROUP (ORDER BY st.trans_value / NULLIF(st.actual_area, 0)) AS median_price_sqm
    FROM stg.dld_transactions st
    WHERE st.master_project_en IS NOT NULL 
      AND st.master_project_en != ''
      AND st.trans_value > 0
      AND st.actual_area > 0
    GROUP BY 1, 2, 3
),
cohort_enriched AS (
    -- Join launch dates with performance and calculate quarters since launch
    SELECT
        qp.*,
        pl.launch_quarter,
        (EXTRACT(YEAR FROM qp.activity_quarter) - EXTRACT(YEAR FROM pl.launch_quarter)) * 4 +
        (EXTRACT(QUARTER FROM qp.activity_quarter) - EXTRACT(QUARTER FROM pl.launch_quarter)) AS quarters_since_launch
    FROM quarterly_performance qp
    JOIN project_launch pl 
        ON pl.master_project_en = qp.master_project_en
       AND pl.project_en = qp.project_en
)
SELECT
    launch_quarter,
    quarters_since_launch,
    COUNT(DISTINCT master_project_en || '|' || project_en) AS project_count,
    SUM(txn_count) AS total_transactions,
    SUM(total_value) AS total_value,
    AVG(median_price_sqm) AS avg_median_price_sqm,
    percentile_cont(0.5) WITHIN GROUP (ORDER BY median_price_sqm) AS cohort_median_price_sqm,
    -- Retention metric: how many projects are still active
    SUM(CASE WHEN txn_count >= 10 THEN 1 ELSE 0 END) AS active_projects
FROM cohort_enriched
WHERE quarters_since_launch BETWEEN 0 AND 12  -- First 3 years after launch
GROUP BY launch_quarter, quarters_since_launch
HAVING COUNT(DISTINCT master_project_en || '|' || project_en) >= 3  -- At least 3 projects in cohort
ORDER BY launch_quarter, quarters_since_launch;

-- ============================================================================
-- Insights from this query:
-- ============================================================================
-- 
-- 1. Launch Quarter Performance:
--    - Which launch quarters (e.g., 2022 Q1) produced the most successful
--      projects based on subsequent transaction volume and value?
--
-- 2. Time-to-Maturity:
--    - How many quarters does it take for projects to reach peak transaction
--      volume after launch?
--
-- 3. Project Survival Rate:
--    - What percentage of projects remain active (>10 txns/quarter) after
--      2, 4, or 8 quarters?
--
-- 4. Launch Timing Strategy:
--    - Are projects launched in certain quarters (e.g., Q4 pre-holiday season)
--      more successful than others?
--
-- Example interpretation:
-- If 2022 Q1 cohort shows consistently higher avg_median_price_sqm across
-- all quarters_since_launch compared to 2023 Q1, this suggests favorable
-- market conditions or higher-quality project launches in early 2022.
