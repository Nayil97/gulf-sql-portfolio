# Power BI Integration Notes

Although this repository is SQL‑only, the downstream consumer of the data model is expected to be a Power BI dashboard.  This note outlines how to connect Power BI to the PostgreSQL warehouse and leverage the star schema to build interactive reports.

## Connecting to PostgreSQL

1. **Install the Npgsql provider** if not already present.  In Power BI Desktop, select **Get Data → PostgreSQL**.  Provide the connection details to your database (host, port, database name, user and password).  Ensure that the PostgreSQL server is reachable from your machine.
2. **Import only the views** needed for the dashboard.  Under the `dw` schema, tables may be numerous; instead, select the views defined in `sql/50_views_powerbi/` (e.g. `v_model_transactions`, `v_dashboard_metrics`, `v_model_cpi`).  These views already join the necessary dimension tables and pre‑aggregate certain metrics to simplify the data model on the Power BI side.
3. **Define relationships.**  In the data modelling interface, Power BI will detect the foreign key relationships between the imported tables.  If you import the dimension tables as well, ensure the relationships are set as:

| From                     | To                       | Cardinality | Direction |
|--------------------------|--------------------------|-------------|-----------|
| `v_model_transactions.date_key` | `dw.dim_date.date_key` | Many‑to‑One | Single    |
| `v_model_transactions.property_key` | `dw.dim_property.property_key` | Many‑to‑One | Single |
| `v_model_transactions.project_key` | `dw.dim_project.project_key` | Many‑to‑One | Single |
| `v_model_cpi.date_key`  | `dw.dim_date.date_key` | Many‑to‑One | Single |

## Recommended visuals

- **Segment price/sqm heat map:** Use a matrix or heat map visual with property type and usage on the axes and median price per square metre as the colour.  Add a slicer to toggle off‑plan vs ready.
- **Volume and value trend lines:** A line chart displaying monthly or quarterly transaction volume and value, with separate lines for off‑plan and ready segments.  Use the date dimension’s year and month fields.
- **Off‑plan share area chart:** Show the percentage of volume or value accounted for by off‑plan transactions over time.
- **Project leaderboard:** A ranked table visual listing the top master projects by price per square metre and transaction value.  Include conditional formatting to highlight significant outperformance.
- **Optional macro overlay:** If you import `v_model_cpi`, create a combo chart plotting CPI growth (YoY) alongside real estate metrics to examine possible lagged relationships.

## Measures in DAX

While the heavy lifting is done in SQL, you may still create lightweight DAX measures to combine or format metrics.  For example, to display off‑plan share as a percentage, define a measure:

```DAX
Offplan Share % = SUM(v_model_transactions.offplan_value) / SUM(v_model_transactions.total_value)
```

However, wherever possible, reuse the pre‑computed fields from the SQL views to maintain consistency between the database and the BI layer.