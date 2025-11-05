-- -----------------------------------------------------------------------------
-- View: v_model_transactions
--
-- This view denormalises the transaction fact table with its associated
-- dimensions to expose a star‑schema structure suitable for BI tools such as
-- Power BI.  It includes commonly used fields for slicing and dicing, but
-- keeps measures at the transaction level.
-- -----------------------------------------------------------------------------

CREATE OR REPLACE VIEW dw.v_model_transactions AS
SELECT
    ft.transaction_key,
    dd.date_key,
    dd.date,
    dd.year,
    dd.month,
    dd.day,
    dd.quarter,
    dd.year_month,
    dp.property_key,
    dp.usage_en,
    dp.prop_type_en,
    dp.prop_sb_type_en,
    dp.is_offplan,
    dp.is_freehold,
    pr.project_key,
    pr.master_project_en,
    pr.project_en,
    ft.trans_value,
    ft.actual_area,
    ft.price_per_sqm
FROM dw.fact_transactions ft
JOIN dw.dim_date dd ON dd.date_key = ft.date_key
JOIN dw.dim_property dp ON dp.property_key = ft.property_key
JOIN dw.dim_project pr ON pr.project_key = ft.project_key;