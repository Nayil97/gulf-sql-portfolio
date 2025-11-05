-- -----------------------------------------------------------------------------
-- Dimension table for dates
--
-- Generates a row for each calendar date between the minimum and maximum
-- transaction dates in the staging table.  If no data exists, a default
-- range is used.  The surrogate key `date_key` is represented as an integer
-- in YYYYMMDD format for efficient joins.
-- -----------------------------------------------------------------------------

DROP TABLE IF EXISTS dw.dim_date;

-- Determine date range; fallback to a default if staging table is empty
WITH date_bounds AS (
    SELECT
        COALESCE(MIN(txn_date), DATE '2021-01-01') AS start_date,
        COALESCE(MAX(txn_date), DATE '2025-12-31') AS end_date
    FROM stg.dld_transactions
)
SELECT
    to_char(d, 'YYYYMMDD')::int AS date_key,
    d::date AS date,
    extract(year FROM d)::int AS year,
    extract(month FROM d)::int AS month,
    extract(day FROM d)::int AS day,
    extract(quarter FROM d)::int AS quarter,
    to_char(d, 'YYYY_MM') AS year_month,
    date_trunc('quarter', d)::date AS quarter_start
INTO dw.dim_date
FROM (
    SELECT generate_series(start_date, end_date, INTERVAL '1 day') AS d
    FROM date_bounds
 ) AS gs;

ALTER TABLE dw.dim_date ADD CONSTRAINT dim_date_pk PRIMARY KEY (date_key);

ANALYZE dw.dim_date;