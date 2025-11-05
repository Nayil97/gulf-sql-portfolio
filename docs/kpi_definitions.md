# KPI Definitions

This document defines the key performance indicators calculated in the project.  All KPIs are implemented in pure SQL and are suitable for direct consumption in dashboards or reports.

| KPI                         | Definition                                                      | Formula (SQL)                                                                                                                                                                                       |
|-----------------------------|-----------------------------------------------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| **Price per square metre**  | Median price paid per square metre for a given segment.         | `percentile_cont(0.5) WITHIN GROUP (ORDER BY trans_value / NULLIF(actual_area, 0))`                                                                        |
| **Transaction volume**      | Count of transactions in a period and segment.                 | `COUNT(*)`                                                                                                                                                                                          |
| **Transaction value**       | Sum of transaction values in a period and segment.             | `SUM(trans_value)`                                                                                                                                                                                  |
| **Off‑plan share (volume)** | Proportion of transactions that are off‑plan.                  | `SUM(CASE WHEN is_offplan THEN 1 ELSE 0 END)::numeric / COUNT(*)`                                                                                           |
| **Off‑plan share (value)**  | Proportion of transaction value that is off‑plan.              | `SUM(CASE WHEN is_offplan THEN trans_value ELSE 0 END) / NULLIF(SUM(trans_value),0)`                                                                       |
| **Master‑project ranking**  | Rank of each master project by chosen metric.                  | Use `DENSE_RANK()` or `ROW_NUMBER()` window functions over `MASTER_PROJECT_EN` partitioned by period and ordered by the metric in descending order.          |
| **Quarter‑over‑quarter (QoQ)** | Growth rate between consecutive quarters.                    | `(metric - LAG(metric) OVER (PARTITION BY segment ORDER BY quarter)) / NULLIF(LAG(metric) OVER (...), 0)`                                                     |
| **Year‑over‑year (YoY)**    | Growth rate between the same quarter in consecutive years.     | `(metric - LAG(metric,4) OVER (PARTITION BY segment ORDER BY quarter)) / NULLIF(LAG(metric,4) OVER (...), 0)`                                                   |
| **CPI QoQ / YoY**           | CPI growth rates by item.                                      | Similar to above but applied to `cpi_index` in `dw.fact_cpi`.                                                                                                |

### Notes

- The price per square metre uses a median instead of an average to reduce the influence of outliers.  Percentile functions are implemented using the `percentile_cont` window function in PostgreSQL.
- Off‑plan share is computed both by volume and value to capture different dynamics: a high volume share may correspond to lower value transactions or vice versa.
- Growth rates are expressed as decimals (e.g. 0.1 = 10 %).  Multiply by 100 to present them as percentages in reports.