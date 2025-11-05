#!/usr/bin/env bash
#
# Load raw data into PostgreSQL
#
# This script creates the necessary schemas and raw tables, then loads the
# CSV files from the `data/` directory.  It relies on environment variables
# accepted by `psql` (`PGHOST`, `PGPORT`, `PGDATABASE`, `PGUSER`, `PGPASSWORD`).
# Execute it from the project root: `bash scripts/psql_load.sh`.

set -euo pipefail

echo "Creating schemas and enabling extensions..."
psql -v ON_ERROR_STOP=1 -f sql/00_init/00_create_schemas.sql
psql -v ON_ERROR_STOP=1 -f sql/00_init/01_extensions.sql

echo "Creating raw tables..."
psql -v ON_ERROR_STOP=1 -f sql/10_raw_load/ddl_raw_dld.sql
psql -v ON_ERROR_STOP=1 -f sql/10_raw_load/ddl_raw_gastat.sql

echo "Loading data from CSVs..."
psql -v ON_ERROR_STOP=1 -f sql/10_raw_load/load_raw_dld.sql
psql -v ON_ERROR_STOP=1 -f sql/10_raw_load/load_raw_gastat.sql

echo "Data loaded successfully.  Proceed to run staging and warehouse scripts."