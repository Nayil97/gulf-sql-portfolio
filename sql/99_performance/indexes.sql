-- -----------------------------------------------------------------------------
-- Performance tuning: indexes (enhanced)
--
-- Adds b‑tree, composite, and partial indexes to frequently filtered columns.
-- These indexes accelerate grouping by date and segment attributes, and
-- optimize common query patterns identified in KPI and dashboard queries.
-- Adjust or add additional indexes based on query patterns observed in production.
-- -----------------------------------------------------------------------------

-- ============================================================================
-- STAGING TABLE INDEXES
-- ============================================================================

-- Date-based queries (time-series analysis)
CREATE INDEX IF NOT EXISTS stg_dld_transactions_txn_date_idx
    ON stg.dld_transactions (txn_date);

CREATE INDEX IF NOT EXISTS stg_dld_transactions_month_start_idx
    ON stg.dld_transactions (month_start);

-- Composite index for segment analysis (most common GROUP BY pattern)
CREATE INDEX IF NOT EXISTS stg_dld_transactions_offplan_type_usage_idx
    ON stg.dld_transactions (is_offplan, prop_type_en, usage_en);

-- Project-based queries
CREATE INDEX IF NOT EXISTS stg_dld_transactions_master_project_idx
    ON stg.dld_transactions (master_project_en);

-- Partial index for off-plan transactions (saves space, faster queries)
CREATE INDEX IF NOT EXISTS stg_dld_transactions_offplan_only_idx
    ON stg.dld_transactions (txn_date, trans_value, actual_area)
    WHERE is_offplan = true;

-- Partial index for high-value transactions (outlier analysis)
CREATE INDEX IF NOT EXISTS stg_dld_transactions_high_value_idx
    ON stg.dld_transactions (trans_value, actual_area, prop_type_en)
    WHERE trans_value > 5000000;

-- Expression index for price per sqm (frequently calculated in WHERE clauses)
CREATE INDEX IF NOT EXISTS stg_dld_transactions_price_per_sqm_idx
    ON stg.dld_transactions ((trans_value / NULLIF(actual_area, 0)));

-- ============================================================================
-- FACT TABLE INDEXES
-- ============================================================================

-- Foreign key indexes (already created in fact table script, included for completeness)
CREATE INDEX IF NOT EXISTS fact_transactions_date_key_idx
    ON dw.fact_transactions (date_key);

CREATE INDEX IF NOT EXISTS fact_transactions_property_key_idx
    ON dw.fact_transactions (property_key);

CREATE INDEX IF NOT EXISTS fact_transactions_project_key_idx
    ON dw.fact_transactions (project_key);

-- Composite index for common time-series segment queries
CREATE INDEX IF NOT EXISTS fact_transactions_date_property_idx
    ON dw.fact_transactions (date_key, property_key);

CREATE INDEX IF NOT EXISTS fact_transactions_date_project_idx
    ON dw.fact_transactions (date_key, project_key);

-- Index for price per sqm analysis
CREATE INDEX IF NOT EXISTS fact_transactions_price_per_sqm_idx
    ON dw.fact_transactions (price_per_sqm)
    WHERE price_per_sqm IS NOT NULL;

-- Partial index for high-value transactions
CREATE INDEX IF NOT EXISTS fact_transactions_luxury_segment_idx
    ON dw.fact_transactions (property_key, price_per_sqm)
    WHERE trans_value > 5000000;

-- Covering index for dashboard aggregations (includes commonly selected columns)
CREATE INDEX IF NOT EXISTS fact_transactions_dashboard_covering_idx
    ON dw.fact_transactions (date_key, property_key)
    INCLUDE (trans_value, actual_area, price_per_sqm);

-- ============================================================================
-- DIMENSION TABLE INDEXES
-- ============================================================================

-- Natural key indexes for lookups (in addition to primary keys)
CREATE INDEX IF NOT EXISTS dim_property_natural_key_idx
    ON dw.dim_property (usage_en, prop_type_en, is_offplan);

CREATE INDEX IF NOT EXISTS dim_project_master_idx
    ON dw.dim_project (master_project_en)
    WHERE master_project_en IS NOT NULL AND master_project_en != '';

-- Date dimension indexes for common filters
CREATE INDEX IF NOT EXISTS dim_date_year_month_idx
    ON dw.dim_date (year, month);

CREATE INDEX IF NOT EXISTS dim_date_quarter_idx
    ON dw.dim_date (quarter_start);

-- ============================================================================
-- CPI FACT TABLE INDEXES
-- ============================================================================

CREATE INDEX IF NOT EXISTS fact_cpi_date_key_idx
    ON dw.fact_cpi (date_key);

CREATE INDEX IF NOT EXISTS fact_cpi_item_code_idx
    ON dw.fact_cpi (item_code);

CREATE INDEX IF NOT EXISTS fact_cpi_item_date_idx
    ON dw.fact_cpi (item_code, date_key);

-- ============================================================================
-- MATERIALIZED VIEW INDEXES (if materialized views exist)
-- ============================================================================

-- These will be created by the materialized_views.sql script
-- Documented here for reference

-- ============================================================================
-- MAINTENANCE
-- ============================================================================

ANALYZE stg.dld_transactions;
ANALYZE dw.fact_transactions;
ANALYZE dw.dim_date;
ANALYZE dw.dim_property;
ANALYZE dw.dim_project;
ANALYZE dw.fact_cpi;

-- Display index usage statistics (diagnostic query)
-- Uncomment to check which indexes are being used:
/*
SELECT
    schemaname,
    tablename,
    indexname,
    idx_scan AS times_used,
    pg_size_pretty(pg_relation_size(indexrelid)) AS index_size
FROM pg_stat_user_indexes
WHERE schemaname IN ('stg', 'dw')
ORDER BY idx_scan DESC;
*/