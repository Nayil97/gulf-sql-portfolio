# Project Changelog - Database Load & Power BI Setup

**Date:** October 23, 2025  
**Session:** Database Loading and Power BI Integration

---

## 🗄️ Database Changes

### PostgreSQL Database Created: `gulf_dw`

**Connection Details:**
- **Server:** 172.26.88.10:5432 (WSL network interface)
- **Database:** gulf_dw
- **User Created:** powerbi_user (read-only access)
- **Password:** powerbi_readonly_2024
- **SSL:** Disabled for local development

### Configuration Changes:

1. **PostgreSQL Server Configuration** (`/etc/postgresql/17/main/postgresql.conf`):
   - `listen_addresses = '*'` (changed from 'localhost')
   - `ssl = off` (disabled for compatibility)

2. **Access Control** (`/etc/postgresql/17/main/pg_hba.conf`):
   - Added: `host all all 0.0.0.0/0 scram-sha-256`
   - Allows network connections from Power BI Desktop

### Data Loaded:

- **Raw Layer:** 179,229 Dubai property transactions (2021-2025)
- **Raw Layer:** 12 quarterly CPI data points from GASTAT
- **Staging Layer:** Cleaned and transformed data
- **Data Warehouse:** 3 dimensions, 2 facts
- **Power BI Layer:** 3 materialized views, 2 regular views

---

## 📝 SQL File Modifications

### 1. `/sql/10_raw_load/ddl_raw_dld.sql`

**Modified:** October 23, 2025 17:11

**Changes:**
- Expanded table definition from 11 columns to 22 columns to match actual CSV structure
- Changed numeric columns to text for initial load flexibility:
  - `trans_value` (numeric → text)
  - `procedure_area` (numeric → text)
  - `actual_area` (numeric → text)
- Added missing columns:
  - `group_en`, `procedure_en`, `area_en`, `rooms_en`, `parking`
  - `nearest_metro_en`, `nearest_mall_en`, `nearest_landmark_en`
  - `total_buyer`, `total_seller`

**Reason:** CSV file contained more columns than original DDL expected. Raw layer now matches source data exactly.

### 2. `/sql/10_raw_load/load_raw_gastat.sql`

**Modified:** October 23, 2025 17:15

**Changes:**
- Changed file reference: `data/gastat.csv` → `data/gastat_utf8.csv`
- Added delimiter specification: `DELIMITER E'\t'` (tab-separated)

**Reason:** Original file was UTF-16LE encoded, causing load errors. Converted to UTF-8 and adjusted delimiter.

**Supporting File Created:** `data/gastat_utf8.csv` (UTF-8 converted version)

### 3. `/sql/20_staging_transform/stg_dld_transactions.sql`

**Modified:** October 23, 2025 17:16

**Changes:**
- Updated boolean logic for `is_offplan`:
  ```sql
  -- Before:
  WHEN is_offplan_en ILIKE 'Yes' THEN true
  WHEN is_offplan_en ILIKE 'No' THEN false
  
  -- After:
  WHEN is_offplan_en ILIKE '%Off%Plan%' THEN true
  WHEN is_offplan_en ILIKE '%Ready%' THEN false
  ```
- Changed `NULLIF` comparison from integer to empty string:
  ```sql
  -- Before: NULLIF(trans_value, 0)
  -- After:  NULLIF(trans_value, '')
  ```

**Reason:** Actual data used "Off-Plan"/"Ready" text, not "Yes"/"No". Raw columns are text, not numeric.

### 4. `/sql/20_staging_transform/stg_gastat_cpi_long.sql`

**Modified:** October 23, 2025 17:17

**Changes:**
- Fixed quarter parsing logic:
  ```sql
  -- Added REPLACE to strip 'Q' from quarter label
  REPLACE(split_part(quarter_label, '_', 2), 'Q', '')::int
  ```

**Reason:** Quarter labels are '2021_Q1' format, not '2021_1'. Needed to remove 'Q' before casting to integer.

---

## 🔧 Additional Database Objects Created

### Schemas:
- `raw` - Raw data import layer
- `stg` - Staging/transformation layer
- `dw` - Data warehouse layer
- `power_bi` - Power BI optimized views

### Materialized Views in `power_bi` schema:

1. **mv_monthly_metrics** (54 rows)
   - Monthly aggregated metrics by property segment
   - Includes: txn_count, total_value, avg_price_sqm, percentiles

2. **mv_project_leaderboard** (21 rows)
   - Top projects ranked by transaction value
   - Includes: sales count, total value, avg price, market share

3. **mv_macro_correlation** (12 rows)
   - CPI correlation analysis by quarter
   - Includes: correlation coefficients, lagged analysis

### Regular Views in `power_bi` schema:

1. **v_model_transactions** (179K rows)
   - Full transaction details with denormalized dimensions
   - Ready for Power BI import

2. **v_model_cpi** (12 rows)
   - CPI time series data
   - Quarterly granularity

### Indexes Created:
- 20+ performance indexes on fact tables and materialized views
- Covering: date ranges, property types, projects, geographic areas

### User Access:
- **powerbi_user:** SELECT-only permissions on all schemas
- No write/update/delete privileges (read-only for dashboards)

---

## 📊 Power BI Documentation Created

### New Files in `power_bi/` Directory:

1. **CONNECTION_DETAILS.md** (3.7K) - NEW
   - Quick reference card with connection credentials
   - Table listing with row counts
   - Troubleshooting guide

2. **IMPLEMENTATION_GUIDE.md** (32K) - UPDATED
   - Added "Database Already Loaded" section
   - Updated all connection strings to use WSL IP (172.26.88.10)
   - Updated credentials to powerbi_user
   - Added SSL disabled notes
   - Updated troubleshooting section

3. **pbi_measures.md** (2.6K) - EXISTING
   - 13 DAX measures for KPI calculations
   - No changes

4. **visual_recipes.md** (3.7K) - EXISTING
   - 5 dashboard page specifications
   - No changes

5. **HHI_GAUGE_USAGE.md** - EXISTING
   - Custom visual import instructions
   - No changes

6. **CUSTOM_VISUAL_SUMMARY.md** (4.2K) - EXISTING
   - HHI Gauge overview
   - No changes

7. **POWER_BI_SUMMARY.md** (8.7K) - EXISTING
   - Complete project summary
   - No changes

8. **README.md** (6.8K) - EXISTING
   - Navigation hub for all Power BI resources
   - No changes

### Custom Visual Artifacts:

**Directory:** `power_bi/pbiviz/hhiGauge/`

- **dist/*.pbiviz** (5.9K) - Packaged custom visual for import
- **src/visual.ts** - TypeScript implementation
- **capabilities.json** - Data binding configuration
- **pbiviz.json** - Visual metadata
- **README.md** - Developer documentation

---

## 🔄 Data Pipeline Summary

```
CSV Files (data/)
    ↓
Raw Layer (raw schema)
    ↓ Transformation & Cleaning
Staging Layer (stg schema)
    ↓ Dimensional Modeling
Data Warehouse (dw schema)
    ↓ Aggregation & Optimization
Power BI Layer (power_bi schema)
    ↓
Power BI Desktop Dashboards
```

**Total Row Counts:**
- Raw transactions: 179,229
- Staging transactions: 179,229 (after cleaning)
- DW fact_transactions: 179,229
- Dimensions: Date (245), Property (54), Project (2,580)
- Power BI MVs: 54 + 21 + 12 = 87 pre-aggregated rows

**Data Quality:**
- 0 rows removed in staging (no future dates)
- All transactions have valid dates (2021-2025)
- CPI data covers 2021 Q1 through 2025 Q1 (17 quarters)

---

## 📁 New Files Created in Project

### Database Support:
- `data/gastat_utf8.csv` - UTF-8 converted CPI data

### Documentation:
- `power_bi/CONNECTION_DETAILS.md` - Connection quick reference
- `CHANGELOG.md` (this file) - Complete change log

### Custom Visual:
- `power_bi/pbiviz/hhiGauge/` - Complete pbiviz project directory
- `power_bi/pbiviz/hhiGauge/dist/*.pbiviz` - Packaged visual

---

## ✅ Status Summary

### Database Status:
- ✅ PostgreSQL 17 running on WSL
- ✅ Database: gulf_dw created and loaded
- ✅ 179,229 transactions imported
- ✅ All dimensions and facts built
- ✅ Power BI views optimized and ready
- ✅ Indexes created for performance
- ✅ User access configured (powerbi_user)

### Network Status:
- ✅ PostgreSQL listening on 0.0.0.0:5432
- ✅ SSL disabled (no certificate issues)
- ✅ Firewall configured for connections
- ✅ WSL IP accessible: 172.26.88.10

### Documentation Status:
- ✅ 8 Power BI documentation files
- ✅ Connection details updated everywhere
- ✅ Implementation guide current
- ✅ Custom visual packaged and documented

### Power BI Status:
- ✅ Custom HHI Gauge visual built (5.9K)
- ✅ 13 DAX measures documented
- ✅ 5 dashboard pages specified
- ⏳ Awaiting Power BI Desktop connection by user

---

## 🚀 Next Steps for User

1. **Connect Power BI Desktop:**
   - Server: 172.26.88.10:5432
   - Database: gulf_dw
   - Username: powerbi_user
   - Password: powerbi_readonly_2024

2. **Import Tables:**
   - power_bi.mv_monthly_metrics
   - power_bi.mv_project_leaderboard
   - power_bi.mv_macro_correlation
   - power_bi.v_model_transactions
   - power_bi.v_model_cpi
   - dw.dim_date
   - dw.dim_property
   - dw.dim_project

3. **Import Custom Visual:**
   - File: `power_bi/pbiviz/hhiGauge/dist/*.pbiviz`

4. **Create DAX Measures:**
   - Follow: `power_bi/pbi_measures.md`

5. **Build Dashboards:**
   - Follow: `power_bi/visual_recipes.md`

---

## 📞 Support Information

**Documentation Files:**
- Quick Start: `power_bi/CONNECTION_DETAILS.md`
- Full Guide: `power_bi/IMPLEMENTATION_GUIDE.md`
- DAX Measures: `power_bi/pbi_measures.md`
- Dashboard Specs: `power_bi/visual_recipes.md`

**Database Connection Test:**
```bash
PGPASSWORD='powerbi_readonly_2024' psql -h 172.26.88.10 -U powerbi_user -d gulf_dw -c "SELECT COUNT(*) FROM power_bi.mv_monthly_metrics;"
```

**Expected Result:** `54` (confirms connection working)

---

**End of Changelog**
