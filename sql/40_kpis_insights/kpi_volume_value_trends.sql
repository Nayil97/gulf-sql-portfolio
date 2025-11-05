-- -----------------------------------------------------------------------------
-- KPI: Transaction volume and value trends
--
-- Aggregates transaction counts and total transaction value by calendar month.
-- Calculates month‑over‑month (MoM) and year‑over‑year (YoY) growth rates
-- using window functions.  Growth rates are expressed as decimals (e.g. 0.05
-- represents 5 %).
-- -----------------------------------------------------------------------------

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
ORDER BY month_start;