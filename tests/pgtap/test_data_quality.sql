-- -----------------------------------------------------------------------------
-- pgTAP tests: Data quality and integrity
--
-- This test suite validates data quality rules, business constraints, and
-- referential integrity across the data warehouse.  Tests ensure that:
-- - No negative or zero values exist where inappropriate
-- - All foreign keys reference existing dimension rows
-- - Date ranges are valid
-- - Aggregations produce expected results
-- -----------------------------------------------------------------------------

CREATE EXTENSION IF NOT EXISTS pgtap;

BEGIN;

SELECT plan(25);

-- ============================================================================
-- RAW LAYER DATA QUALITY
-- ============================================================================

-- Test 1: Raw table has data
SELECT cmp_ok(
    (SELECT COUNT(*) FROM raw.dld_transactions),
    '>',
    0,
    'raw.dld_transactions contains data'
);

-- Test 2: Raw CPI table has data
SELECT cmp_ok(
    (SELECT COUNT(*) FROM raw.gastat_cpi_wide),
    '>',
    0,
    'raw.gastat_cpi_wide contains data'
);

-- ============================================================================
-- STAGING LAYER DATA QUALITY
-- ============================================================================

-- Test 3: No future dates in staging
SELECT is(
    (SELECT COUNT(*) FROM stg.dld_transactions WHERE txn_date > CURRENT_DATE),
    0::bigint,
    'No future transaction dates in staging'
);

-- Test 4: No negative transaction values
SELECT is(
    (SELECT COUNT(*) FROM stg.dld_transactions WHERE trans_value < 0),
    0::bigint,
    'No negative transaction values'
);

-- Test 5: No negative areas
SELECT is(
    (SELECT COUNT(*) FROM stg.dld_transactions WHERE actual_area < 0),
    0::bigint,
    'No negative property areas'
);

-- Test 6: Transaction dates are within reasonable range
SELECT ok(
    (SELECT MIN(txn_date) FROM stg.dld_transactions) >= DATE '2020-01-01',
    'Minimum transaction date is reasonable (>= 2020-01-01)'
);

SELECT ok(
    (SELECT MAX(txn_date) FROM stg.dld_transactions) <= CURRENT_DATE,
    'Maximum transaction date is not in the future'
);

-- Test 7: Off-plan flag is properly boolean
SELECT is(
    (SELECT COUNT(*) FROM stg.dld_transactions WHERE is_offplan IS NULL),
    0::bigint,
    'Off-plan flag has no NULL values'
);

-- Test 8: CPI staging has valid data
SELECT cmp_ok(
    (SELECT COUNT(*) FROM stg.gastat_cpi_long WHERE cpi_index IS NOT NULL),
    '>',
    0,
    'CPI staging has non-null index values'
);

-- Test 9: Quarter dates are valid
SELECT is(
    (SELECT COUNT(*) FROM stg.gastat_cpi_long WHERE quarter_start IS NULL),
    0::bigint,
    'All CPI records have valid quarter_start dates'
);

-- ============================================================================
-- DIMENSION TABLE INTEGRITY
-- ============================================================================

-- Test 10: Date dimension has unique keys
SELECT is(
    (SELECT COUNT(*) FROM dw.dim_date),
    (SELECT COUNT(DISTINCT date_key) FROM dw.dim_date),
    'dim_date has unique date_keys'
);

-- Test 11: Date dimension covers all transaction dates
SELECT ok(
    NOT EXISTS (
        SELECT 1 FROM stg.dld_transactions st
        LEFT JOIN dw.dim_date dd ON dd.date = st.txn_date
        WHERE dd.date_key IS NULL
    ),
    'All transaction dates exist in dim_date'
);

-- Test 12: Property dimension has unique keys
SELECT is(
    (SELECT COUNT(*) FROM dw.dim_property),
    (SELECT COUNT(DISTINCT property_key) FROM dw.dim_property),
    'dim_property has unique property_keys'
);

-- Test 13: Project dimension has unique keys
SELECT is(
    (SELECT COUNT(*) FROM dw.dim_project),
    (SELECT COUNT(DISTINCT project_key) FROM dw.dim_project),
    'dim_project has unique project_keys'
);

-- Test 14: No NULL values in dimension primary keys
SELECT is(
    (SELECT COUNT(*) FROM dw.dim_date WHERE date_key IS NULL),
    0::bigint,
    'dim_date has no NULL primary keys'
);

SELECT is(
    (SELECT COUNT(*) FROM dw.dim_property WHERE property_key IS NULL),
    0::bigint,
    'dim_property has no NULL primary keys'
);

SELECT is(
    (SELECT COUNT(*) FROM dw.dim_project WHERE project_key IS NULL),
    0::bigint,
    'dim_project has no NULL primary keys'
);

-- ============================================================================
-- FACT TABLE INTEGRITY
-- ============================================================================

-- Test 15: All fact_transactions have valid foreign keys to dim_date
SELECT is(
    (SELECT COUNT(*) FROM dw.fact_transactions ft
     LEFT JOIN dw.dim_date dd ON dd.date_key = ft.date_key
     WHERE dd.date_key IS NULL),
    0::bigint,
    'All transactions have valid date_key references'
);

-- Test 16: All fact_transactions have valid foreign keys to dim_property
SELECT is(
    (SELECT COUNT(*) FROM dw.fact_transactions ft
     LEFT JOIN dw.dim_property dp ON dp.property_key = ft.property_key
     WHERE dp.property_key IS NULL),
    0::bigint,
    'All transactions have valid property_key references'
);

-- Test 17: All fact_transactions have valid foreign keys to dim_project
SELECT is(
    (SELECT COUNT(*) FROM dw.fact_transactions ft
     LEFT JOIN dw.dim_project pr ON pr.project_key = ft.project_key
     WHERE pr.project_key IS NULL),
    0::bigint,
    'All transactions have valid project_key references'
);

-- Test 18: Price per sqm is calculated correctly
SELECT ok(
    NOT EXISTS (
        SELECT 1 FROM dw.fact_transactions
        WHERE actual_area > 0 
          AND price_per_sqm IS NOT NULL
          AND ABS((trans_value / actual_area) - price_per_sqm) > 0.01
    ),
    'price_per_sqm is calculated correctly (trans_value / actual_area)'
);

-- Test 19: No negative price per sqm
SELECT is(
    (SELECT COUNT(*) FROM dw.fact_transactions WHERE price_per_sqm < 0),
    0::bigint,
    'No negative price per square metre values'
);

-- Test 20: Fact CPI has valid foreign keys to dim_date
SELECT is(
    (SELECT COUNT(*) FROM dw.fact_cpi fc
     LEFT JOIN dw.dim_date dd ON dd.date_key = fc.date_key
     WHERE dd.date_key IS NULL),
    0::bigint,
    'All CPI records have valid date_key references'
);

-- ============================================================================
-- BUSINESS RULE VALIDATION
-- ============================================================================

-- Test 21: Transaction values are reasonable (between 1,000 and 1 billion)
SELECT ok(
    (SELECT COUNT(*) FROM dw.fact_transactions 
     WHERE trans_value < 1000 OR trans_value > 1000000000) < 
    (SELECT COUNT(*) FROM dw.fact_transactions) * 0.01,
    'Less than 1% of transactions have extreme values'
);

-- Test 22: Property areas are reasonable (between 10 and 100,000 sqm)
SELECT ok(
    (SELECT COUNT(*) FROM dw.fact_transactions 
     WHERE actual_area < 10 OR actual_area > 100000) < 
    (SELECT COUNT(*) FROM dw.fact_transactions) * 0.01,
    'Less than 1% of transactions have extreme area values'
);

-- Test 23: Price per sqm is in reasonable range (100 to 100,000 per sqm)
SELECT ok(
    (SELECT COUNT(*) FROM dw.fact_transactions 
     WHERE price_per_sqm < 100 OR price_per_sqm > 100000) < 
    (SELECT COUNT(*) FROM dw.fact_transactions) * 0.05,
    'Less than 5% of transactions have extreme price per sqm'
);

-- Test 24: Each quarter has at least one CPI record
SELECT cmp_ok(
    (SELECT COUNT(DISTINCT date_key) FROM dw.fact_cpi),
    '>=',
    12,
    'At least 12 quarters of CPI data exist'
);

-- Test 25: Staging and fact table row counts are consistent
SELECT is(
    (SELECT COUNT(*) FROM stg.dld_transactions),
    (SELECT COUNT(*) FROM dw.fact_transactions),
    'Staging and fact_transactions have same row count (no data loss)'
);

SELECT finish();

ROLLBACK;
