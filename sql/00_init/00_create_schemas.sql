-- -----------------------------------------------------------------------------
-- Create database schemas
--
-- This script creates logical schemas for raw ingestion, staging,
-- data warehouse modelling and utility functions.  Executing this script
-- multiple times is idempotent thanks to IF NOT EXISTS guards.
-- -----------------------------------------------------------------------------

CREATE SCHEMA IF NOT EXISTS raw;
CREATE SCHEMA IF NOT EXISTS stg;
CREATE SCHEMA IF NOT EXISTS dw;
CREATE SCHEMA IF NOT EXISTS util;