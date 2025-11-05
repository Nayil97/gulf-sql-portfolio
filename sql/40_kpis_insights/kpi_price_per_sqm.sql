-- -----------------------------------------------------------------------------
-- KPI: Median price per square metre by segment and period
--
-- Calculates the median price per square metre for each combination of
-- property type, usage, off‑plan flag and calendar month.  Only positive
-- areas and transaction values are considered.  Results can be grouped by
-- month_start or by quarter_start depending on analytical needs.
-- -----------------------------------------------------------------------------

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
ORDER BY 1,2,3,4;