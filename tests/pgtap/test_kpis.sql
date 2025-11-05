-- -----------------------------------------------------------------------------
-- pgTAP tests: KPI calculations
--
-- Verifies that KPI queries return results and that key metrics are
-- non‑null.  Each test wraps the KPI logic in a subquery and asserts
-- existence of at least one row.  Requires the data warehouse to be built.
-- -----------------------------------------------------------------------------

CREATE EXTENSION IF NOT EXISTS pgtap;

BEGIN;

SELECT plan(3);

-- Test that fact table has price_per_sqm values
SELECT ok(
    EXISTS (SELECT 1 FROM dw.fact_transactions WHERE price_per_sqm IS NOT NULL),
    'fact_transactions.price_per_sqm has non‑null values'
);

-- Test that median price per sqm query returns results
SELECT ok(
    EXISTS (
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
        SELECT 1 FROM (
            SELECT month_start, prop_type_en, usage_en, is_offplan,
                   percentile_cont(0.5) WITHIN GROUP (ORDER BY price_per_sqm) AS median_price_sqm
            FROM base
            GROUP BY 1,2,3,4
        ) AS sub WHERE median_price_sqm IS NOT NULL
        LIMIT 1
    ),
    'median price per sqm query yields non‑null results'
);

-- Test that off‑plan share query returns a proportion between 0 and 1
SELECT ok(
    EXISTS (
        SELECT 1
        FROM (
            SELECT
                SUM(CASE WHEN is_offplan THEN 1 ELSE 0 END)::numeric / COUNT(*) AS share
            FROM stg.dld_transactions
            GROUP BY date_trunc('month', txn_date)
        ) AS s
        WHERE share >= 0 AND share <= 1
        LIMIT 1
    ),
    'off‑plan share is between 0 and 1'
);

SELECT finish();

ROLLBACK;