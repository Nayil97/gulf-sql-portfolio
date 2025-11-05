-- -----------------------------------------------------------------------------
-- Stage GASTAT CPI data (unpivot)
--
-- The wide CPI table contains one numeric column per quarter.  This script
-- unpivots those columns into a long format with one row per item and
-- quarter.  It also derives the start date of each quarter and computes
-- quarter‑over‑quarter (qoq) and year‑over‑year (yoy) percentage changes.
-- -----------------------------------------------------------------------------

DROP TABLE IF EXISTS stg.gastat_cpi_long;

WITH long_form AS (
    SELECT "Item" AS item_code, "En Basket Rs Desc" AS item_desc,
           '2021_Q1' AS quarter_label, "2021 / Q1" AS cpi_index FROM raw.gastat_cpi_wide
    UNION ALL SELECT "Item", "En Basket Rs Desc", '2021_Q2', "2021 / Q2" FROM raw.gastat_cpi_wide
    UNION ALL SELECT "Item", "En Basket Rs Desc", '2021_Q3', "2021 / Q3" FROM raw.gastat_cpi_wide
    UNION ALL SELECT "Item", "En Basket Rs Desc", '2021_Q4', "2021 / Q4" FROM raw.gastat_cpi_wide
    UNION ALL SELECT "Item", "En Basket Rs Desc", '2022_Q1', "2022 / Q1" FROM raw.gastat_cpi_wide
    UNION ALL SELECT "Item", "En Basket Rs Desc", '2022_Q2', "2022 / Q2" FROM raw.gastat_cpi_wide
    UNION ALL SELECT "Item", "En Basket Rs Desc", '2022_Q3', "2022 / Q3" FROM raw.gastat_cpi_wide
    UNION ALL SELECT "Item", "En Basket Rs Desc", '2022_Q4', "2022 / Q4" FROM raw.gastat_cpi_wide
    UNION ALL SELECT "Item", "En Basket Rs Desc", '2023_Q1', "2023 / Q1" FROM raw.gastat_cpi_wide
    UNION ALL SELECT "Item", "En Basket Rs Desc", '2023_Q2', "2023 / Q2" FROM raw.gastat_cpi_wide
    UNION ALL SELECT "Item", "En Basket Rs Desc", '2023_Q3', "2023 / Q3" FROM raw.gastat_cpi_wide
    UNION ALL SELECT "Item", "En Basket Rs Desc", '2023_Q4', "2023 / Q4" FROM raw.gastat_cpi_wide
    UNION ALL SELECT "Item", "En Basket Rs Desc", '2024_Q1', "2024 / Q1" FROM raw.gastat_cpi_wide
    UNION ALL SELECT "Item", "En Basket Rs Desc", '2024_Q2', "2024 / Q2" FROM raw.gastat_cpi_wide
    UNION ALL SELECT "Item", "En Basket Rs Desc", '2024_Q3', "2024 / Q3" FROM raw.gastat_cpi_wide
    UNION ALL SELECT "Item", "En Basket Rs Desc", '2024_Q4', "2024 / Q4" FROM raw.gastat_cpi_wide
    UNION ALL SELECT "Item", "En Basket Rs Desc", '2025_Q1', "2025 / Q1" FROM raw.gastat_cpi_wide
),
quarter_dates AS (
    SELECT
        item_code,
        item_desc,
        quarter_label,
        to_date(split_part(quarter_label, '_', 1) || '-' ||
                ((REPLACE(split_part(quarter_label, '_', 2), 'Q', '')::int - 1) * 3 + 1)::text || '-01',
                'YYYY-MM-DD') AS quarter_start,
        cpi_index
    FROM long_form
)
SELECT
    item_code,
    item_desc,
    quarter_label,
    quarter_start,
    cpi_index,
    (cpi_index / NULLIF(LAG(cpi_index) OVER (PARTITION BY item_code ORDER BY quarter_start), 0) - 1) AS qoq,
    (cpi_index / NULLIF(LAG(cpi_index, 4) OVER (PARTITION BY item_code ORDER BY quarter_start), 0) - 1) AS yoy
INTO stg.gastat_cpi_long
FROM quarter_dates
ORDER BY item_code, quarter_start;

ANALYZE stg.gastat_cpi_long;