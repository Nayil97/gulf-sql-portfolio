-- -----------------------------------------------------------------------------
-- Enable PostgreSQL extensions
--
-- pgcrypto is used for surrogate key generation or hashing if required.
-- Additional extensions can be enabled here.
-- -----------------------------------------------------------------------------

CREATE EXTENSION IF NOT EXISTS pgcrypto;
-- Uncomment the line below if pgTAP is installed in the database; CI handles installation
-- CREATE EXTENSION IF NOT EXISTS pgtap;