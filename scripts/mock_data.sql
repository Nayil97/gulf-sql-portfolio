-- -----------------------------------------------------------------------------
-- Populate mock data
--
-- This script inserts a small number of rows into the raw tables so that
-- developers can test the pipeline without access to real data.  Run it
-- before staging and warehouse scripts if `data/` CSVs are absent.
-- -----------------------------------------------------------------------------

INSERT INTO raw.dld_transactions (
    transaction_number,
    instance_date,
    prop_type_en,
    usage_en,
    is_offplan_en,
    is_free_hold_en,
    prop_sb_type_en,
    trans_value,
    actual_area,
    master_project_en,
    project_en
) VALUES
    ('TST001', '2024-01-15', 'Apartment', 'Residential', 'Yes', 'Free Hold', 'Standard', 1000000, 85, 'Test Master', 'Test Project'),
    ('TST002', '2024-02-10', 'Villa',     'Residential', 'No',  'Free Hold', 'Deluxe',   2500000, 350, 'Test Master', 'Test Project');

INSERT INTO raw.gastat_cpi_wide (
    item,
    item_desc,
    "2021_Q1",
    "2021_Q2",
    "2021_Q3",
    "2021_Q4",
    "2022_Q1",
    "2022_Q2",
    "2022_Q3",
    "2022_Q4",
    "2023_Q1",
    "2023_Q2",
    "2023_Q3",
    "2023_Q4",
    "2024_Q1",
    "2024_Q2",
    "2024_Q3",
    "2024_Q4",
    "2025_Q1"
) VALUES
    ('CPI001', 'Test Item',
     100, 101, 102, 103,
     104, 105, 106, 107,
     108, 109, 110, 111,
     112, 113, 114, 115,
     116);