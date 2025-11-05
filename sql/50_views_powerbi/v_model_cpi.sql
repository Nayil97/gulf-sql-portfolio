-- -----------------------------------------------------------------------------
-- View: v_model_cpi
--
-- Denormalises the CPI fact table with the date dimension for BI consumption.
-- Provides human‑readable date fields alongside CPI indices and growth rates.
-- -----------------------------------------------------------------------------

CREATE OR REPLACE VIEW dw.v_model_cpi AS
SELECT
    fc.cpi_key,
    fc.date_key,
    dd.date AS quarter_start_date,
    dd.year,
    dd.quarter,
    fc.item_code,
    fc.item_desc,
    fc.cpi_index,
    fc.qoq,
    fc.yoy
FROM dw.fact_cpi fc
JOIN dw.dim_date dd ON dd.date_key = fc.date_key;