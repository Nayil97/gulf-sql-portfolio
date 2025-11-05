# Business Case: Off‑Plan vs Ready Real Estate Insights

## Context

Dubai’s real estate market is a bellwether for the Gulf Cooperation Council (GCC) region.  Investors and developers must decide whether to invest in **off‑plan** (pre‑construction) properties, which offer lower entry prices but higher risk, or **ready** units, which provide immediate occupancy or rental income.  The performance of each segment can vary significantly by property type (e.g. apartment, villa, land), usage (residential vs commercial) and location (master project).  Understanding where price per square metre, transaction values, and growth rates are highest informs smarter product strategy and capital allocation.

Although macroeconomic factors such as inflation influence real estate sentiment, this project focuses primarily on the micro‑level question of **segment economics**.  We integrate quarterly Saudi CPI data to provide optional macro context for analysts who wish to explore correlations, but the core business problem is to identify the **price efficiencies and growth hotspots** across off‑plan versus ready segments.

## Objective

Build a transparent, reproducible analytical pipeline in PostgreSQL that answers the following questions:

1. **Where are price‑per‑square‑metre efficiencies found across off‑plan and ready segments?**  Identify combinations of property type (`PROP_TYPE_EN`), usage (`USAGE_EN`) and master project (`MASTER_PROJECT_EN`) where the median price per square metre is significantly above or below the market median.
2. **How are transaction volumes and values trending over time across these segments?**  Analyse month‑over‑month (MoM) and year‑over‑year (YoY) changes in transaction counts and total value, highlighting surges or declines.
3. **Which master projects consistently outperform on price and growth?**  Rank master projects by transaction value, price per square metre and growth to surface “alpha” locations for potential launches or investments.

The outputs of the pipeline will include KPI tables, leaderboard rankings and time‑series trends that can be visualised in Power BI.  The results will enable decision makers to allocate capital more effectively, plan product launches and communicate market insights to stakeholders.

## Key performance indicators (KPIs)

- **Median price per square metre**: `TRANS_VALUE / ACTUAL_AREA`, aggregated at monthly and quarterly levels by segment (off‑plan vs ready, property type, usage).
- **Transaction volume**: number of transactions per period by segment.
- **Transaction value**: sum of `TRANS_VALUE` per period by segment.
- **Off‑plan share**: proportion of value and volume represented by off‑plan transactions.
- **Project leaderboard**: ranking of master projects by median price per square metre, total transaction value, growth rate and stability (number of periods in the top quintile).

For optional macro analysis, additional KPIs include:

- **CPI YoY and QoQ change**: percentage change in CPI index for each item over the previous quarter and previous year.
- **Correlation between CPI and real estate metrics**: correlation coefficients computed at the quarterly level with zero‑, one‑ and two‑quarter lags.

## Decision context

Developers can use these insights to decide which segment to target (off‑plan or ready), what product mix to launch and where to focus marketing budgets.  Investors and agents gain a clearer view of where price efficiencies exist and which master projects are poised for growth.  Policymakers gain evidence to inform regulations on off‑plan development or support measures for affordable housing.  Because the entire pipeline is written in SQL and version‑controlled in GitHub, it is auditable and extensible by data teams.