-- -----------------------------------------------------------------------------
-- KPI: Macro‑real estate correlation (enhanced with lagged analysis)
--
-- Joins quarterly aggregates of real estate transactions with CPI data and
-- computes the Pearson correlation coefficient between selected real estate
-- metrics (value, volume, median price per square metre) and CPI indices.
-- Includes zero-lag (concurrent), 1-quarter lag, and 2-quarter lag analysis
-- to detect delayed economic effects on real estate markets.
-- -----------------------------------------------------------------------------

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
        cpi_index,
        qoq,
        yoy
    FROM stg.gastat_cpi_long
),
cpi_lagged AS (
    SELECT
        item_code,
        item_desc,
        quarter_start,
        cpi_index,
        qoq,
        yoy,
        LAG(cpi_index, 1) OVER (PARTITION BY item_code ORDER BY quarter_start) AS cpi_index_lag1,
        LAG(cpi_index, 2) OVER (PARTITION BY item_code ORDER BY quarter_start) AS cpi_index_lag2
    FROM cpi
)
SELECT
    c.item_desc,
    -- Zero-lag (concurrent quarter) correlations
    corr(d.q_value::numeric, c.cpi_index) AS corr_value_lag0,
    corr(d.q_volume::numeric, c.cpi_index) AS corr_volume_lag0,
    corr(d.q_median_price_sqm, c.cpi_index) AS corr_price_sqm_lag0,
    -- 1-quarter lag (CPI leads real estate by 1 quarter)
    corr(d.q_value::numeric, c.cpi_index_lag1) AS corr_value_lag1,
    corr(d.q_volume::numeric, c.cpi_index_lag1) AS corr_volume_lag1,
    corr(d.q_median_price_sqm, c.cpi_index_lag1) AS corr_price_sqm_lag1,
    -- 2-quarter lag (CPI leads real estate by 2 quarters)
    corr(d.q_value::numeric, c.cpi_index_lag2) AS corr_value_lag2,
    corr(d.q_volume::numeric, c.cpi_index_lag2) AS corr_volume_lag2,
    corr(d.q_median_price_sqm, c.cpi_index_lag2) AS corr_price_sqm_lag2,
    -- Sample size for validation
    COUNT(*) AS n_quarters
FROM dld_q d
JOIN cpi_lagged c ON c.quarter_start = d.quarter_start
WHERE c.cpi_index IS NOT NULL
GROUP BY c.item_desc
HAVING COUNT(*) >= 8  -- Require at least 8 quarters for meaningful correlation
ORDER BY ABS(corr_price_sqm_lag0) DESC NULLS LAST;