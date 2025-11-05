-- -----------------------------------------------------------------------------
-- KPI: Off‑plan share of volume and value
--
-- Calculates the proportion of transactions and transaction value that are
-- off‑plan (pre‑construction) in each calendar month.  Useful to assess
-- developer activity and investor appetite for off‑plan products.
-- -----------------------------------------------------------------------------

SELECT
    date_trunc('month', txn_date)::date AS month_start,
    SUM(CASE WHEN is_offplan THEN 1 ELSE 0 END)::numeric / COUNT(*) AS offplan_volume_share,
    SUM(CASE WHEN is_offplan THEN trans_value ELSE 0 END) / NULLIF(SUM(trans_value), 0) AS offplan_value_share,
    COUNT(*) AS total_volume,
    SUM(trans_value) AS total_value
FROM stg.dld_transactions
GROUP BY 1
ORDER BY 1;