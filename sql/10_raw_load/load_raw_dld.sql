-- -----------------------------------------------------------------------------
-- Load data into raw.dld_transactions
--
-- This script uses the psql meta-command \copy to read the CSV file from the
-- relative data directory.  It assumes that the working directory is the
-- project root when executed.  Ensure that column order in the CSV matches
-- the table definition in ddl_raw_dld.sql.
-- -----------------------------------------------------------------------------

\copy raw.dld_transactions FROM 'data/dld.csv' WITH (FORMAT csv, HEADER true);