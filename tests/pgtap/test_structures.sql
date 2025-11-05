-- -----------------------------------------------------------------------------
-- pgTAP tests: structure and schema
--
-- This test script verifies that the key tables and columns exist and have
-- expected data types.  Run via `psql -f` after the data warehouse has been
-- built.  The script uses transactional tests so that it does not modify
-- persistent data.  Requires the `pgtap` extension to be installed.
-- -----------------------------------------------------------------------------

CREATE EXTENSION IF NOT EXISTS pgtap;

BEGIN;

SELECT plan(7);

-- Check that the dimension and fact tables exist
SELECT has_table('dw', 'dim_date', 'dim_date table exists');
SELECT has_table('dw', 'dim_property', 'dim_property table exists');
SELECT has_table('dw', 'dim_project', 'dim_project table exists');
SELECT has_table('dw', 'fact_transactions', 'fact_transactions table exists');

-- Check that key columns exist
SELECT has_column('dw', 'fact_transactions', 'price_per_sqm', 'price_per_sqm column exists');
SELECT col_type_is('dw', 'fact_transactions', 'price_per_sqm', 'numeric', 'price_per_sqm is numeric');

-- Check that the date dimension has at least one row
SELECT cmp_ok((SELECT COUNT(*) FROM dw.dim_date), '>', 0, 'dim_date contains rows');

SELECT finish();

ROLLBACK;