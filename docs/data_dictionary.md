# Data Dictionary

This document describes the structure and purpose of each table in the data warehouse pipeline.  The model follows a layered approach: **raw** tables mirror the input CSVs, **staging** tables standardise formats and apply basic cleaning, **dw** (data warehouse) tables implement a star schema with dimension and fact tables, and **kpi** views present derived metrics.

## Raw layer (`raw` schema)

### `raw.dld_transactions`

| Column                | Type    | Description                                                |
|-----------------------|---------|------------------------------------------------------------|
| `transaction_number`  | text    | Unique identifier for each transaction                    |
| `instance_date`       | text    | Original date of transaction as a string (YYYY‑MM‑DD)     |
| `prop_type_en`        | text    | High‑level property type (e.g. Apartment, Villa, Land)     |
| `usage_en`            | text    | Usage of property (e.g. Residential, Commercial)           |
| `is_offplan_en`       | text    | Off‑plan flag as provided (Yes/No)                        |
| `is_free_hold_en`     | text    | Freehold flag (Free Hold)                                  |
| `prop_sb_type_en`     | text    | Subtype of property (optional)                            |
| `trans_value`         | numeric | Transaction value in local currency                       |
| `actual_area`         | numeric | Built‑up area in square metres                            |
| `master_project_en`   | text    | Name of the master project (development)                  |
| `project_en`          | text    | Name of the specific project or sub‑development           |

### `raw.gastat_cpi_wide`

The wide CPI table contains one row per item in the Saudi CPI basket.  Each quarter is represented as a separate numeric column, with names in the format `YYYY_QN` (e.g. `2021_Q1`, `2021_Q2`).  The dictionary below lists the core columns.  The full set of quarter columns extends from 2021_Q1 through 2025_Q1.

| Column           | Type    | Description                                    |
|------------------|---------|------------------------------------------------|
| `item`           | text    | Unique code for the CPI basket item           |
| `item_desc`      | text    | Description of the basket item in English     |
| `2021_Q1` ...    | numeric | CPI index for the given item and quarter      |


## Staging layer (`stg` schema)

### `stg.dld_transactions`

Cleaned and typed version of the raw transactions table.

| Column              | Type     | Description                                           |
|---------------------|----------|-------------------------------------------------------|
| `transaction_number`| text     | Pass‑through from raw                                  |
| `txn_date`          | date     | Parsed date                                           |
| `month_start`       | date     | First day of the month for `txn_date`                |
| `is_offplan`        | boolean  | True if off‑plan, false if ready                      |
| `is_freehold`       | boolean  | True if freehold                                      |
| `usage_en`          | text     | Usage category                                        |
| `prop_type_en`      | text     | High‑level property type                              |
| `prop_sb_type_en`   | text     | Subtype                                               |
| `trans_value`       | numeric  | Cast from raw                                         |
| `actual_area`       | numeric  | Cast from raw                                         |
| `master_project_en` | text     | Cleaned name                                          |
| `project_en`        | text     | Cleaned name                                          |

### `stg.gastat_cpi_long`

Unpivoted version of the CPI wide table.  Each row corresponds to a single basket item and quarter.

| Column         | Type    | Description                                               |
|----------------|---------|-----------------------------------------------------------|
| `item_code`    | text    | CPI basket code                                           |
| `item_desc`    | text    | CPI basket description                                    |
| `quarter_label`| text    | Quarter in `YYYY_QN` format (e.g. 2023_Q2)               |
| `quarter_start`| date    | First day of the quarter                                 |
| `cpi_index`    | numeric | CPI index                                                 |
| `qoq`          | numeric | Quarter‑over‑quarter percentage change                    |
| `yoy`          | numeric | Year‑over‑year percentage change                          |


## Data warehouse layer (`dw` schema)

### `dw.dim_date`

Date dimension table covering all dates in the data set.  Includes fields for day, month, quarter, year, and common date keys.

| Column       | Type | Description                                         |
|--------------|------|-----------------------------------------------------|
| `date_key`   | int  | Surrogate key (YYYYMMDD)                            |
| `date`       | date | Actual calendar date                                |
| `year`       | int  | Four‑digit year                                     |
| `month`      | int  | Month number (1–12)                                 |
| `day`        | int  | Day of month (1–31)                                 |
| `quarter`    | int  | Quarter number (1–4)                                |
| `year_month` | text | Concatenation `YYYY_MM` for easy filtering           |
| `quarter_start`| date| First day of the quarter                            |

### `dw.dim_property`

Dimension capturing the categorical attributes of a property.  Each unique combination of usage, type, off‑plan flag, freehold flag and subtype receives a surrogate key.

| Column          | Type    | Description                                      |
|-----------------|---------|--------------------------------------------------|
| `property_key`  | serial  | Surrogate key                                    |
| `usage_en`      | text    | Usage (residential, commercial, etc.)            |
| `prop_type_en`  | text    | High‑level property type                         |
| `prop_sb_type_en`| text   | Subtype                                          |
| `is_offplan`    | boolean | Off‑plan flag                                    |
| `is_freehold`   | boolean | Freehold flag                                    |

### `dw.dim_project`

Dimension for projects and master projects.

| Column           | Type    | Description                                    |
|------------------|---------|------------------------------------------------|
| `project_key`    | serial  | Surrogate key                                  |
| `master_project_en`| text  | Master project name                            |
| `project_en`     | text    | Project name                                   |

### `dw.fact_transactions`

Fact table at the grain of each transaction.  Links to the date, property and project dimensions and stores numeric measures.

| Column            | Type    | Description                                     |
|-------------------|---------|-------------------------------------------------|
| `transaction_key` | serial  | Surrogate key                                   |
| `date_key`        | int     | Foreign key to `dw.dim_date.date_key`           |
| `property_key`    | int     | Foreign key to `dw.dim_property.property_key`   |
| `project_key`     | int     | Foreign key to `dw.dim_project.project_key`     |
| `trans_value`     | numeric | Transaction value                               |
| `actual_area`     | numeric | Actual area                                    |
| `price_per_sqm`   | numeric | Derived: `trans_value / actual_area`           |

### `dw.fact_cpi`

Fact table at the grain of (CPI item, quarter).

| Column         | Type    | Description                                  |
|----------------|---------|----------------------------------------------|
| `cpi_key`      | serial  | Surrogate key                                |
| `date_key`     | int     | Quarter start date key                       |
| `item_code`    | text    | CPI basket code                              |
| `item_desc`    | text    | Basket description                           |
| `cpi_index`    | numeric | CPI index                                    |
| `qoq`          | numeric | Quarter‑over‑quarter change                  |
| `yoy`          | numeric | Year‑over‑year change                        |


## KPI views

The `sql/40_kpis_insights` directory contains SQL queries that calculate common KPIs such as median price per square metre, transaction volumes and off‑plan share.  The `sql/50_views_powerbi` directory contains materialised views that join fact and dimension tables into star‑schema structures optimised for Power BI.