-- -----------------------------------------------------------------------------
-- Maintenance: vacuum and analyse
--
-- Runs VACUUM ANALYZE on key tables.  Should be executed periodically in
-- production environments to update planner statistics and reclaim space.
-- -----------------------------------------------------------------------------

VACUUM ANALYZE stg.dld_transactions;
VACUUM ANALYZE stg.gastat_cpi_long;
VACUUM ANALYZE dw.dim_date;
VACUUM ANALYZE dw.dim_property;
VACUUM ANALYZE dw.dim_project;
VACUUM ANALYZE dw.fact_transactions;
VACUUM ANALYZE dw.fact_cpi;