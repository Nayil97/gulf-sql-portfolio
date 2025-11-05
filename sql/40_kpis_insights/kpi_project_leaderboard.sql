-- -----------------------------------------------------------------------------
-- KPI: Master project leaderboard
--
-- Ranks master projects by median price per square metre and total transaction
-- value for each quarter.  Produces dense ranks so that ties receive the same
-- rank.  Analysts can filter on rank thresholds to identify outperformers.
-- -----------------------------------------------------------------------------

WITH base AS (
    SELECT
        st.master_project_en,
        date_trunc('quarter', st.txn_date)::date AS quarter_start,
        SUM(st.trans_value) AS total_value,
        COUNT(*) AS total_volume,
        percentile_cont(0.5) WITHIN GROUP (ORDER BY st.trans_value / NULLIF(st.actual_area, 0)) AS median_price_sqm
    FROM stg.dld_transactions st
    WHERE st.trans_value > 0 AND st.actual_area > 0
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
ORDER BY quarter_start, rank_by_value, rank_by_price;