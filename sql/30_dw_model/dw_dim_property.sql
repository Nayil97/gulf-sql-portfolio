-- -----------------------------------------------------------------------------
-- Dimension table for property attributes
--
-- Generates a surrogate key for each unique combination of usage, property
-- type, subtype, off‑plan flag and freehold flag.  These keys allow the
-- transaction fact table to be normalised and enable efficient grouping.
-- -----------------------------------------------------------------------------

DROP TABLE IF EXISTS dw.dim_property;

CREATE TABLE dw.dim_property (
    property_key SERIAL PRIMARY KEY,
    usage_en text NOT NULL,
    prop_type_en text NOT NULL,
    prop_sb_type_en text,
    is_offplan boolean NOT NULL,
    is_freehold boolean NOT NULL,
    UNIQUE (usage_en, prop_type_en, prop_sb_type_en, is_offplan, is_freehold)
);

INSERT INTO dw.dim_property (usage_en, prop_type_en, prop_sb_type_en, is_offplan, is_freehold)
SELECT DISTINCT
    usage_en,
    prop_type_en,
    prop_sb_type_en,
    is_offplan,
    is_freehold
FROM stg.dld_transactions
ORDER BY usage_en, prop_type_en, prop_sb_type_en, is_offplan, is_freehold;

ANALYZE dw.dim_property;