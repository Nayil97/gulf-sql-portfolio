# SQL Style Guide

This document defines the SQL coding standards for the GCC Real Estate Analytics project. Consistency in style improves readability, maintainability, and collaboration.

---

## General Principles

1. **Readability First**: Code is read more often than written
2. **Consistency**: Follow existing patterns in the codebase
3. **Self-Documenting**: Use clear names and comments
4. **Performance-Aware**: Write efficient queries, but prioritize clarity

---

## Naming Conventions

### Tables

- **Schema prefix**: Always qualify tables with schema (`dw.fact_transactions`, not `fact_transactions`)
- **Lowercase with underscores**: `dim_date`, `fact_transactions`, `stg_dld_transactions`
- **Prefixes**:
  - `dim_` for dimension tables
  - `fact_` for fact tables
  - `stg_` for staging tables
  - `mv_` for materialized views
  - `v_` for views

**Examples:**
```sql
✅ Good: dw.dim_property, stg.dld_transactions, dw.mv_monthly_metrics
❌ Bad: Property, DLD_TXN, monthlyMetrics
```

### Columns

- **Lowercase with underscores**: `trans_value`, `master_project_en`, `is_offplan`
- **Boolean columns**: Prefix with `is_`, `has_`, or `can_`
- **Foreign keys**: Match referenced primary key name: `date_key`, `property_key`
- **Avoid abbreviations** unless widely understood (e.g., `txn` for transaction is acceptable)

**Examples:**
```sql
✅ Good: is_offplan, trans_value, date_key
❌ Bad: offplan_flag, val, dt_key
```

### Aliases

- **Use meaningful abbreviations**: `dd` for `dim_date`, `ft` for `fact_transactions`, `st` for staging
- **Consistent across project**: Use same alias for same table everywhere

**Examples:**
```sql
✅ Good:
FROM dw.fact_transactions ft
JOIN dw.dim_date dd ON dd.date_key = ft.date_key

❌ Bad:
FROM dw.fact_transactions AS transactions
JOIN dw.dim_date AS dates ON dates.date_key = transactions.date_key
```

---

## Formatting

### Indentation

- **2 spaces** (not tabs)
- Indent within CTEs, subqueries, and CASE statements

### Capitalization

- **SQL keywords**: Lowercase for readability in modern editors
  - Acceptable: `select`, `from`, `where`, `join`
  - Also acceptable: `SELECT`, `FROM`, `WHERE`, `JOIN` (but be consistent)
- **This project uses lowercase** for consistency

### Line Length

- **Aim for <80 characters** per line
- Break long lines after commas or logical operators

### SELECT Clauses

- **One column per line** in SELECT statements
- Comma at the **start of the line** for easy commenting/uncommenting

**Example:**
```sql
SELECT
    dd.year_month
    , dd.year
    , dd.month
    , dp.prop_type_en
    , dp.is_offplan
    , COUNT(*) AS txn_count
    , SUM(ft.trans_value) AS total_value
FROM dw.fact_transactions ft
JOIN dw.dim_date dd ON dd.date_key = ft.date_key
JOIN dw.dim_property dp ON dp.property_key = ft.property_key
WHERE dd.year >= 2023
GROUP BY 1, 2, 3, 4, 5
ORDER BY dd.year_month DESC;
```

### JOINs

- **Use explicit JOIN syntax**: `INNER JOIN`, `LEFT JOIN`, not old comma syntax
- **Align ON clauses** for readability
- **Put JOIN conditions on same line as JOIN** if short, otherwise indent

**Example:**
```sql
FROM stg.dld_transactions st
JOIN dw.dim_date dd 
    ON dd.date = st.txn_date
JOIN dw.dim_property dp 
    ON dp.usage_en = st.usage_en
   AND dp.prop_type_en = st.prop_type_en
   AND dp.is_offplan = st.is_offplan
```

### WHERE Clauses

- **One condition per line** for complex filters
- **Use AND at the start of the line** for easy commenting

**Example:**
```sql
WHERE st.trans_value > 0
  AND st.actual_area > 0
  AND st.is_offplan = true
  AND dd.year >= 2023
```

### CTEs (Common Table Expressions)

- **Prefer CTEs over subqueries** for readability
- **Name CTEs descriptively**: `monthly_aggregates`, `project_launch`, not `cte1`, `cte2`
- **One CTE per logical step**

**Example:**
```sql
WITH monthly_aggregates AS (
    SELECT
        date_trunc('month', txn_date)::date AS month_start,
        SUM(trans_value) AS total_value,
        COUNT(*) AS txn_count
    FROM stg.dld_transactions
    GROUP BY 1
),
growth_rates AS (
    SELECT
        month_start,
        total_value,
        (total_value / NULLIF(LAG(total_value) OVER (ORDER BY month_start), 0) - 1) AS mom_growth
    FROM monthly_aggregates
)
SELECT *
FROM growth_rates
WHERE mom_growth IS NOT NULL
ORDER BY month_start DESC;
```

### Window Functions

- **Use readable PARTITION BY and ORDER BY**
- **Align window clauses** for clarity

**Example:**
```sql
SELECT
    master_project_en,
    quarter_start,
    median_price_sqm,
    DENSE_RANK() OVER (
        PARTITION BY quarter_start 
        ORDER BY median_price_sqm DESC
    ) AS rank_by_price
FROM project_quarterly_metrics
```

---

## Comments

### File Headers

Every SQL file should have a header comment:

```sql
-- -----------------------------------------------------------------------------
-- <File Purpose: one-line description>
--
-- <Detailed description of what this script does, any assumptions, and
-- prerequisites. Include information about idempotency, data sources, and
-- expected outcomes.>
-- -----------------------------------------------------------------------------
```

### Inline Comments

- **Use `--` for single-line comments**
- **Explain WHY, not WHAT**: Code should be self-explanatory; comments explain reasoning

**Example:**
```sql
-- Use median instead of average to reduce influence of outliers
percentile_cont(0.5) WITHIN GROUP (ORDER BY price_per_sqm) AS median_price_sqm

-- NULLIF protects against division by zero
trans_value / NULLIF(actual_area, 0) AS price_per_sqm
```

### Section Dividers

Use consistent dividers for major sections:

```sql
-- ============================================================================
-- SECTION TITLE
-- ============================================================================
```

---

## Best Practices

### 1. Always Use Explicit Column Names

**Don't use `SELECT *`** in production code:

```sql
❌ Bad:
SELECT *
FROM dw.fact_transactions;

✅ Good:
SELECT
    transaction_key,
    date_key,
    trans_value,
    actual_area,
    price_per_sqm
FROM dw.fact_transactions;
```

### 2. Use NULLIF for Division

Protect against division by zero:

```sql
✅ Good:
trans_value / NULLIF(actual_area, 0)

❌ Bad:
trans_value / actual_area  -- Can error if actual_area = 0
```

### 3. Use IS NOT DISTINCT FROM for NULL-Safe Comparisons

When joining on columns that may contain NULL:

```sql
✅ Good:
AND dp.prop_sb_type_en IS NOT DISTINCT FROM st.prop_sb_type_en

❌ Bad:
AND dp.prop_sb_type_en = st.prop_sb_type_en  -- Excludes NULL matches
```

### 4. Use Explicit Casting

Make data type conversions explicit:

```sql
✅ Good:
date_trunc('month', txn_date)::date

❌ Avoid:
date_trunc('month', txn_date)  -- Returns timestamp, not date
```

### 5. Use ANALYZE After Large Data Changes

Always run ANALYZE after bulk inserts/updates to update statistics:

```sql
INSERT INTO dw.fact_transactions (...) SELECT ...;
ANALYZE dw.fact_transactions;
```

### 6. Use Idempotent Scripts

Make scripts safe to re-run:

```sql
✅ Good:
DROP TABLE IF EXISTS dw.dim_property;
CREATE TABLE dw.dim_property (...);

CREATE INDEX IF NOT EXISTS idx_name ON table_name (column);

❌ Bad:
DROP TABLE dw.dim_property;  -- Errors if table doesn't exist
CREATE INDEX idx_name ON table_name (column);  -- Errors if index exists
```

### 7. Use Descriptive Aggregation Aliases

```sql
✅ Good:
COUNT(*) AS txn_count
SUM(trans_value) AS total_value
AVG(price_per_sqm) AS avg_price_sqm

❌ Bad:
COUNT(*) AS cnt
SUM(trans_value) AS sum_val
AVG(price_per_sqm) AS avg_pps
```

### 8. Group By Column Position (When Clear)

Use column positions for short GROUP BY clauses:

```sql
✅ Acceptable:
GROUP BY 1, 2, 3  -- When SELECT has 3 grouping columns

✅ Also Good:
GROUP BY year_month, prop_type_en, is_offplan  -- More explicit
```

### 9. Use Window Functions Over Self-Joins

Prefer window functions for calculations requiring row context:

```sql
✅ Good (Window Function):
SELECT
    month_start,
    total_value,
    LAG(total_value) OVER (ORDER BY month_start) AS prev_month_value
FROM monthly_data

❌ Bad (Self-Join):
SELECT
    m1.month_start,
    m1.total_value,
    m2.total_value AS prev_month_value
FROM monthly_data m1
LEFT JOIN monthly_data m2 
    ON m2.month_start = m1.month_start - INTERVAL '1 month'
```

### 10. Add NOT NULL Constraints Where Appropriate

Enforce data integrity at the database level:

```sql
CREATE TABLE dw.dim_property (
    property_key SERIAL PRIMARY KEY,
    usage_en text NOT NULL,
    prop_type_en text NOT NULL,
    is_offplan boolean NOT NULL
);
```

---

## Anti-Patterns to Avoid

### ❌ Using UNION Instead of UNION ALL (When Duplicates Are OK)

UNION performs an implicit DISTINCT, which is slower:

```sql
✅ Good (if duplicates are acceptable):
SELECT month_start FROM table1
UNION ALL
SELECT month_start FROM table2

❌ Bad (unnecessary deduplication):
SELECT month_start FROM table1
UNION
SELECT month_start FROM table2
```

### ❌ Using NOT IN with Nullable Columns

NOT IN returns unexpected results if the subquery returns NULL:

```sql
❌ Bad:
WHERE column NOT IN (SELECT nullable_column FROM other_table)

✅ Good:
WHERE NOT EXISTS (
    SELECT 1 FROM other_table 
    WHERE other_table.nullable_column = table.column
)
```

### ❌ Over-Indexing

Don't create indexes on every column; focus on query patterns:

```sql
❌ Bad:
CREATE INDEX ON table (col1);
CREATE INDEX ON table (col2);
CREATE INDEX ON table (col3);
-- ... etc for every column

✅ Good:
CREATE INDEX ON table (col1, col2);  -- Composite index for common query
```

### ❌ String Concatenation with NULL

Use COALESCE to handle NULLs in concatenation:

```sql
❌ Bad:
first_name || ' ' || last_name  -- Returns NULL if either is NULL

✅ Good:
COALESCE(first_name, '') || ' ' || COALESCE(last_name, '')
```

---

## Testing Queries

Before committing, test queries for:

1. **Correctness**: Results match expectations
2. **Performance**: Use `EXPLAIN ANALYZE` for slow queries (>100ms)
3. **Edge Cases**: NULL values, zero values, empty result sets
4. **Idempotency**: Script can be run multiple times safely

**Example Test Workflow:**
```sql
-- 1. Test with small data subset
SELECT ... LIMIT 100;

-- 2. Check execution plan
EXPLAIN ANALYZE
SELECT ...;

-- 3. Verify counts
SELECT COUNT(*) FROM result;

-- 4. Check for NULLs
SELECT COUNT(*) FROM result WHERE key_column IS NULL;
```

---

## Version Control

- **One logical change per commit**
- **Descriptive commit messages**: "Add price per sqm KPI query" not "Update file"
- **Test before committing**: Run pgTAP tests with `bash scripts/run_tests.sh`
- **Keep queries in separate files**: One KPI per file for maintainability

---

## References

- PostgreSQL Style Guide: https://www.postgresql.org/docs/current/sql.html
- SQL Style Guide (Mozilla): https://docs.telemetry.mozilla.org/concepts/sql_style.html
- Simon Holywell's SQL Style Guide: https://www.sqlstyle.guide/

---

**Questions?** See the project README or open an issue on GitHub.
