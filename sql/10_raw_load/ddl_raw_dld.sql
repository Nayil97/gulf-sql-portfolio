-- -----------------------------------------------------------------------------
-- Define raw.dld_transactions table
--
-- The raw layer mirrors the input CSV file as closely as possible.  All
-- columns are defined as text or numeric to allow for flexible ingestion
-- before transformation in the staging layer.  No constraints are placed on
-- the raw table.
-- -----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS raw.dld_transactions (
    transaction_number     text,
    instance_date          text,
    group_en               text,
    procedure_en           text,
    is_offplan_en          text,
    is_free_hold_en        text,
    usage_en               text,
    area_en                text,
    prop_type_en           text,
    prop_sb_type_en        text,
    trans_value            text,
    procedure_area         text,
    actual_area            text,
    rooms_en               text,
    parking                text,
    nearest_metro_en       text,
    nearest_mall_en        text,
    nearest_landmark_en    text,
    total_buyer            text,
    total_seller           text,
    master_project_en      text,
    project_en             text
);