-- -----------------------------------------------------------------------------
-- View: v_dashboard_metrics
--
-- Aggregates transaction metrics by period and segment for quick consumption
-- in dashboards.  Provides counts, sums and medians in a single result set.
-- Period can be changed from year_month to quarter_start or other
-- dimension attributes as needed.
-- -----------------------------------------------------------------------------

CREATE OR REPLACE VIEW dw.v_dashboard_metrics AS
SELECT
    dd.year_month AS period,
    dp.prop_type_en,
    dp.usage_en,
    dp.is_offplan,
    COUNT(*) AS txn_count,
    SUM(ft.trans_value) AS total_value,
    SUM(ft.actual_area) AS total_area,
    percentile_cont(0.5) WITHIN GROUP (ORDER BY ft.price_per_sqm) AS median_price_sqm
FROM dw.fact_transactions ft
JOIN dw.dim_date dd ON dd.date_key = ft.date_key
JOIN dw.dim_property dp ON dp.property_key = ft.property_key
GROUP BY 1,2,3,4
ORDER BY period, prop_type_en, usage_en, is_offplan;