# GCC Real Estate Analytics SQL Project

![CI](https://github.com/sayda/gulf-sql-portfolio/workflows/CI/badge.svg)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-13+-316192?style=flat&logo=postgresql&logoColor=white)
![License](https://img.shields.io/badge/License-MIT-green.svg)
![SQL](https://img.shields.io/badge/SQL-Advanced-blue)
![Star Schema](https://img.shields.io/badge/Data_Warehouse-Star_Schema-orange)

This repository contains a complete, end‑to‑end, SQL‑only data science portfolio project designed to demonstrate mid‑to‑senior level analytical skill and business impact for Gulf Cooperation Council (GCC) real estate markets.  The project uses a PostgreSQL data warehouse to ingest raw data from the Dubai Land Department (DLD) and the Saudi General Authority for Statistics (GASTAT) Consumer Price Index (CPI), transforms it into a clean dimensional model, calculates key performance indicators (KPIs) and insights, and prepares the results for Power BI visualisation.  No Python or other programming languages are required – everything from ingestion to analysis is expressed in SQL.

## 🎯 Key Technical Highlights

- **📊 179,229 Real Transactions**: Dubai Land Department data from 2021–2025 ✅ **LOADED**
- **🏗️ Star Schema Architecture**: 3 dimension tables, 2 fact tables, full referential integrity ✅ **BUILT**
- **⚡ Advanced SQL Techniques**:
  - Window functions (`LAG`, `LEAD`, `RANK`, `DENSE_RANK`, `percentile_cont`)
  - Common Table Expressions (CTEs) for complex transformations
  - Statistical analysis (`corr()` for macro-economic correlations)
  - Time-series growth calculations (MoM, YoY)
- **✅ Automated Testing**: pgTAP test suite with 25+ test cases
- **🔄 CI/CD Pipeline**: GitHub Actions automatically builds warehouse and runs tests
- **📈 Business-Focused KPIs**: Off-plan vs ready analysis, price efficiency, project leaderboards
- **🎨 Power BI Integration**: 
  - 3 materialized views + 2 optimized views ready ✅ **DEPLOYED**
  - Custom HHI Market Concentration Gauge visual ✅ **BUILT**
  - 5 dashboard pages fully specified with DAX measures
  - See `power_bi/` directory for complete implementation

## 🚀 Quick Start - Database Already Running!

**Database Status:** ✅ Loaded and ready on `gulf_dw`

**Connect to Power BI:**
- Server: `172.26.88.10:5432`
- Database: `gulf_dw`
- Username: `powerbi_user`
- Password: `powerbi_readonly_2024`

See `power_bi/CONNECTION_DETAILS.md` for complete setup instructions.

## Business context

Property developers, investors and policymakers across the GCC need reliable intelligence on where and how real estate value is created.  In particular, there is demand for insight into the relative performance of **off‑plan** (pre‑construction) versus **ready** units, the effect of property type and usage on price per square metre, and the way macroeconomic conditions (proxied here by the Saudi CPI) correlate with real estate activity.  This project tackles these questions by building a small data warehouse and suite of analytical queries that surface actionable metrics for decision makers.

## Repository structure

The repository is organised to mirror a professional analytics engineering workflow.  All SQL lives under the `sql/` directory and is executed in a logical order from raw ingestion to staging, data warehouse modelling, KPI calculations and view creation.  Documentation lives under `docs/`, ready for inclusion in a README or GitHub Pages.  Tests for the data model are expressed as **pgTAP** scripts under `tests/pgtap/`, and a GitHub Actions workflow under `.github/workflows/` provides continuous integration by spinning up a PostgreSQL instance, loading the data, and running the tests.

```
gulf-sql-portfolio/
├─ README.md               — Project overview (this file)
├─ .gitignore              — Common exclusions
├─ .github/
│  └─ workflows/
│     └─ ci.yml            — GitHub Actions workflow to build DB and run tests
├─ docs/                   — Business case, ERD, KPI definitions, etc.
│  ├─ business_case.md
│  ├─ data_dictionary.md
│  ├─ erd.md
│  ├─ kpi_definitions.md
│  └─ power_bi_notes.md
├─ sql/                    — SQL scripts organised by stage
│  ├─ 00_init/
│  │  ├─ 00_create_schemas.sql
│  │  └─ 01_extensions.sql
│  ├─ 10_raw_load/
│  │  ├─ ddl_raw_dld.sql
│  │  ├─ ddl_raw_gastat.sql
│  │  ├─ load_raw_dld.sql
│  │  └─ load_raw_gastat.sql
│  ├─ 20_staging_transform/
│  │  ├─ stg_dld_transactions.sql
│  │  └─ stg_gastat_cpi_long.sql
│  ├─ 30_dw_model/
│  │  ├─ dw_dim_date.sql
│  │  ├─ dw_dim_property.sql
│  │  ├─ dw_dim_project.sql
│  │  ├─ dw_fact_transactions.sql
│  │  └─ dw_fact_cpi.sql
│  ├─ 40_kpis_insights/
│  │  ├─ kpi_price_per_sqm.sql
│  │  ├─ kpi_volume_value_trends.sql
│  │  ├─ kpi_offplan_share.sql
│  │  ├─ kpi_project_leaderboard.sql
│  │  └─ kpi_macro_correlation.sql
│  ├─ 50_views_powerbi/
│  │  ├─ v_model_transactions.sql
│  │  ├─ v_model_cpi.sql
│  │  └─ v_dashboard_metrics.sql
│  └─ 99_performance/
│     ├─ indexes.sql
│     └─ analyze_vacuum.sql
├─ data/                   — Raw CSVs (kept small for demonstration purposes)
│  ├─ dld.csv
│  └─ gastat.csv
├─ tests/
│  └─ pgtap/
│     ├─ test_structures.sql
│     └─ test_kpis.sql
├─ scripts/
│  ├─ psql_load.sh         — Utility to create the DB and load data locally
│  ├─ run_tests.sh         — Utility to run all pgTAP tests locally
│  └─ mock_data.sql        — Optional script to populate mock data when real data is absent
└─ power_bi/
   └─ README.md            — Notes on connecting to the data model and suggested visuals
```

## Getting started

1. **Create a PostgreSQL database** (locally or in the cloud).  The GitHub Actions workflow uses a database named `gulf` with user `postgres` and password `postgres` for convenience.  Ensure you set `PGDATABASE`, `PGUSER`, and `PGPASSWORD` appropriately when running scripts locally.
2. **Load the schemas and raw data.**  Run `scripts/psql_load.sh` from the project root.  This script will create the necessary schemas under `raw`, `stg` and `dw`, create the raw tables, and load the CSVs from the `data/` directory using `COPY`.
3. **Run transformations.**  Execute the staging scripts and data warehouse model scripts in numeric order.  A simple way to do this is to run:

   ```bash
   psql -f sql/20_staging_transform/stg_dld_transactions.sql
   psql -f sql/20_staging_transform/stg_gastat_cpi_long.sql
   psql -f sql/30_dw_model/dw_dim_date.sql
   psql -f sql/30_dw_model/dw_dim_property.sql
   psql -f sql/30_dw_model/dw_dim_project.sql
   psql -f sql/30_dw_model/dw_fact_transactions.sql
   psql -f sql/30_dw_model/dw_fact_cpi.sql
   psql -f sql/99_performance/indexes.sql
   psql -f sql/99_performance/analyze_vacuum.sql
   ```

4. **Explore the data.**  KPI and insight queries live under `sql/40_kpis_insights/` and the views consumed by Power BI are under `sql/50_views_powerbi/`.  Run these queries in your PostgreSQL client to generate results.
5. **Run tests.**  If you have **pgTAP** installed, you can execute `scripts/run_tests.sh` to verify that the schemas and key KPIs behave as expected.

## Continuous integration

A GitHub Actions workflow (`.github/workflows/ci.yml`) automatically spins up a PostgreSQL instance, loads the raw data and schemas, and then executes all pgTAP tests.  This ensures that pull requests maintain the integrity of the data model and that KPIs continue to compute successfully as the project evolves.  Recruiters can inspect the status of this workflow to see that the codebase follows professional practices.

## Licence

This project is provided under the MIT Licence.  You are free to use, modify and distribute it for educational purposes.  If you extend it or derive commercial value from it, please credit the original author.

## 📫 Contact & Connect

**LinkedIn**: [Connect with me on LinkedIn](https://linkedin.com/in/yourprofile)  
**Email**: Available upon request  
**GitHub**: [@yourusername](https://github.com/yourusername)

*This project was built to demonstrate SQL data engineering and analytics expertise for data science and analytics engineering roles in the GCC region and beyond.*

---

⭐ If you find this project useful, please consider giving it a star on GitHub!
