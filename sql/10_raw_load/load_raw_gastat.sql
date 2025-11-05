-- -----------------------------------------------------------------------------
-- Load data into raw.gastat_cpi_wide
--
-- This script uses the psql meta-command \copy to read the CPI CSV file.  The
-- header row in the CSV should contain columns matching those defined in
-- ddl_raw_gastat.sql.  Any additional quarters will require table alteration
-- before loading.
-- -----------------------------------------------------------------------------

\copy raw.gastat_cpi_wide FROM 'data/gastat_utf8.csv' WITH (FORMAT csv, HEADER true, DELIMITER E'\t');