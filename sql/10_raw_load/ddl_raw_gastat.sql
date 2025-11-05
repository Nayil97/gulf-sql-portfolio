-- -----------------------------------------------------------------------------
-- Define raw.gastat_cpi_wide table
--
-- The GASTAT CPI file contains one column per quarter.  We enumerate the
-- quarters explicitly so that COPY can load the values into separate numeric
-- columns.  New quarters can be added by altering the table and adjusting
-- staging logic accordingly.
-- -----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS raw.gastat_cpi_wide (
    "Item"               text,
    "En Basket Rs Desc"  text,
    "2021 / Q1"          numeric,
    "2021 / Q2"          numeric,
    "2021 / Q3"          numeric,
    "2021 / Q4"          numeric,
    "2022 / Q1"          numeric,
    "2022 / Q2"          numeric,
    "2022 / Q3"          numeric,
    "2022 / Q4"          numeric,
    "2023 / Q1"          numeric,
    "2023 / Q2"          numeric,
    "2023 / Q3"          numeric,
    "2023 / Q4"          numeric,
    "2024 / Q1"          numeric,
    "2024 / Q2"          numeric,
    "2024 / Q3"          numeric,
    "2024 / Q4"          numeric,
    "2025 / Q1"          numeric
);