-- -----------------------------------------------------------------------------
-- Define raw.gastat_cpi_wide table
--
-- The GASTAT CPI file contains one column per quarter.  We enumerate the
-- quarters explicitly so that COPY can load the values into separate numeric
-- columns.  New quarters can be added by altering the table and adjusting
-- staging logic accordingly.
-- -----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS raw.gastat_cpi_wide (
    item               text,
    item_desc          text,
    "2021_Q1"          numeric,
    "2021_Q2"          numeric,
    "2021_Q3"          numeric,
    "2021_Q4"          numeric,
    "2022_Q1"          numeric,
    "2022_Q2"          numeric,
    "2022_Q3"          numeric,
    "2022_Q4"          numeric,
    "2023_Q1"          numeric,
    "2023_Q2"          numeric,
    "2023_Q3"          numeric,
    "2023_Q4"          numeric,
    "2024_Q1"          numeric,
    "2024_Q2"          numeric,
    "2024_Q3"          numeric,
    "2024_Q4"          numeric,
    "2025_Q1"          numeric
);