-- -----------------------------------------------------------------------------
-- Stage DLD transactions
--
-- This script cleans and transforms the raw DLD transactions into a structured
-- table.  It parses dates, casts numeric columns, and standardises boolean
-- flags for off‑plan and freehold.  Additional data quality checks (e.g.
-- removing negative values) may be added here.
-- -----------------------------------------------------------------------------

DROP TABLE IF EXISTS stg.dld_transactions;

CREATE TABLE stg.dld_transactions AS
SELECT
    transaction_number,
    to_date(instance_date, 'YYYY-MM-DD') AS txn_date,
    date_trunc('month', to_date(instance_date, 'YYYY-MM-DD'))::date AS month_start,
    CASE
        WHEN is_offplan_en ILIKE '%Off%Plan%' THEN true
        WHEN is_offplan_en ILIKE '%Ready%' THEN false
        ELSE NULL
    END AS is_offplan,
    CASE
        WHEN is_free_hold_en ILIKE '%Free%Hold%' THEN true
        ELSE false
    END AS is_freehold,
    usage_en,
    prop_type_en,
    prop_sb_type_en,
    NULLIF(trans_value, '')::numeric AS trans_value,
    NULLIF(actual_area, '')::numeric AS actual_area,
    master_project_en,
    project_en
FROM raw.dld_transactions;

-- Basic data quality check: ensure no future dates (will silently drop such rows)
DELETE FROM stg.dld_transactions WHERE txn_date > current_date;

ANALYZE stg.dld_transactions;