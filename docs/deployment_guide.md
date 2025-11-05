># Deployment Guide

This guide provides step-by-step instructions for deploying the GCC Real Estate Analytics data warehouse to production environments.

---

## 📋 Table of Contents

1. [Prerequisites](#prerequisites)
2. [Local Development Setup](#local-development-setup)
3. [Production Deployment](#production-deployment)
4. [Cloud Deployment Options](#cloud-deployment-options)
5. [Data Loading & Refresh Strategy](#data-loading--refresh-strategy)
6. [Performance Tuning](#performance-tuning)
7. [Monitoring & Maintenance](#monitoring--maintenance)
8. [Backup & Recovery](#backup--recovery)
9. [Security Considerations](#security-considerations)
10. [Troubleshooting](#troubleshooting)

---

## 1. Prerequisites

### Required Software
- **PostgreSQL 13+** (recommended: 14 or 15 for performance improvements)
- **psql** command-line client
- **pgTAP** extension (for testing)
- **Git** (for version control)

### Recommended Tools
- **pgAdmin** or **DBeaver** (GUI database management)
- **sqlfluff** (SQL linting, optional)
- **Python 3.8+** (if extending with ETL scripts)

### System Requirements

| Environment | CPU | RAM | Storage | PostgreSQL Version |
|-------------|-----|-----|---------|-------------------|
| Development | 2 cores | 4 GB | 10 GB | 13+ |
| Staging | 4 cores | 8 GB | 50 GB | 14+ |
| Production | 8+ cores | 16+ GB | 200+ GB | 14 or 15 |

---

## 2. Local Development Setup

### Step 1: Install PostgreSQL

**Ubuntu/Debian:**
```bash
sudo apt-get update
sudo apt-get install postgresql-14 postgresql-client-14
```

**macOS (Homebrew):**
```bash
brew install postgresql@14
brew services start postgresql@14
```

**Windows:**
Download and install from [postgresql.org](https://www.postgresql.org/download/windows/)

### Step 2: Create Database and User

```bash
# Connect as postgres superuser
sudo -u postgres psql

# Create database and user
CREATE DATABASE gulf;
CREATE USER gulf_user WITH PASSWORD 'your_secure_password';
GRANT ALL PRIVILEGES ON DATABASE gulf TO gulf_user;

# Exit psql
\q
```

### Step 3: Clone Repository

```bash
git clone https://github.com/yourusername/gulf-sql-portfolio.git
cd gulf-sql-portfolio
```

### Step 4: Set Environment Variables

Create a `.env` file (do not commit this file):

```bash
export PGHOST=localhost
export PGPORT=5432
export PGDATABASE=gulf
export PGUSER=gulf_user
export PGPASSWORD=your_secure_password
```

Load environment variables:
```bash
source .env
```

### Step 5: Run Initial Setup

```bash
# Execute setup script
bash scripts/psql_load.sh

# Build data warehouse
psql -f sql/20_staging_transform/stg_dld_transactions.sql
psql -f sql/20_staging_transform/stg_gastat_cpi_long.sql
psql -f sql/30_dw_model/dw_dim_date.sql
psql -f sql/30_dw_model/dw_dim_property.sql
psql -f sql/30_dw_model/dw_dim_project.sql
psql -f sql/30_dw_model/dw_fact_transactions.sql
psql -f sql/30_dw_model/dw_fact_cpi.sql
psql -f sql/99_performance/indexes.sql
psql -f sql/50_views_powerbi/materialized_views.sql
```

### Step 6: Run Tests

```bash
bash scripts/run_tests.sh
```

Expected output: All tests should pass (35/35).

---

## 3. Production Deployment

### Step 1: Provision Production Database

Choose a cloud provider or on-premise server:

- **AWS RDS for PostgreSQL**
- **Azure Database for PostgreSQL**
- **Google Cloud SQL for PostgreSQL**
- **Self-managed on EC2/VM**

### Step 2: Configure Production Database

```sql
-- Connect to production database
psql -h production-host.example.com -U gulf_admin -d gulf

-- Set production-grade configuration
ALTER SYSTEM SET shared_buffers = '4GB';
ALTER SYSTEM SET effective_cache_size = '12GB';
ALTER SYSTEM SET maintenance_work_mem = '1GB';
ALTER SYSTEM SET checkpoint_completion_target = 0.9;
ALTER SYSTEM SET wal_buffers = '16MB';
ALTER SYSTEM SET default_statistics_target = 100;
ALTER SYSTEM SET random_page_cost = 1.1;  -- For SSD
ALTER SYSTEM SET effective_io_concurrency = 200;
ALTER SYSTEM SET work_mem = '64MB';
ALTER SYSTEM SET max_worker_processes = 8;
ALTER SYSTEM SET max_parallel_workers_per_gather = 4;
ALTER SYSTEM SET max_parallel_workers = 8;

-- Reload configuration
SELECT pg_reload_conf();
```

### Step 3: Deploy Schema and Data

```bash
# Set production environment variables
export PGHOST=production-host.example.com
export PGPORT=5432
export PGDATABASE=gulf
export PGUSER=gulf_admin
export PGPASSWORD=<secure_production_password>

# Run deployment script
bash scripts/psql_load.sh

# Build warehouse (in order)
for script in \
  sql/20_staging_transform/*.sql \
  sql/30_dw_model/*.sql \
  sql/99_performance/*.sql \
  sql/50_views_powerbi/*.sql
do
  echo "Executing $script..."
  psql -v ON_ERROR_STOP=1 -f "$script"
done
```

### Step 4: Create Read-Only User for BI Tools

```sql
-- Create read-only role for Power BI and analysts
CREATE ROLE powerbi_reader WITH LOGIN PASSWORD 'readonly_password';
GRANT CONNECT ON DATABASE gulf TO powerbi_reader;
GRANT USAGE ON SCHEMA dw TO powerbi_reader;
GRANT SELECT ON ALL TABLES IN SCHEMA dw TO powerbi_reader;
GRANT SELECT ON ALL MATERIALIZED VIEWS IN SCHEMA dw TO powerbi_reader;

-- Automatically grant SELECT on future tables
ALTER DEFAULT PRIVILEGES IN SCHEMA dw 
  GRANT SELECT ON TABLES TO powerbi_reader;
```

---

## 4. Cloud Deployment Options

### Option A: AWS RDS for PostgreSQL

```bash
# Create RDS instance using AWS CLI
aws rds create-db-instance \
  --db-instance-identifier gulf-analytics-prod \
  --db-instance-class db.r5.xlarge \
  --engine postgres \
  --engine-version 14.7 \
  --master-username gulf_admin \
  --master-user-password <secure_password> \
  --allocated-storage 200 \
  --storage-type gp3 \
  --storage-encrypted \
  --backup-retention-period 7 \
  --preferred-backup-window "03:00-04:00" \
  --preferred-maintenance-window "sun:04:00-sun:05:00" \
  --publicly-accessible false \
  --vpc-security-group-ids sg-xxxxxxxxx \
  --db-subnet-group-name gulf-db-subnet-group
```

**Connection String:**
```
postgresql://gulf_admin:<password>@gulf-analytics-prod.xxxxxx.us-east-1.rds.amazonaws.com:5432/gulf
```

### Option B: Azure Database for PostgreSQL

```bash
# Create Azure PostgreSQL server
az postgres flexible-server create \
  --resource-group gulf-analytics-rg \
  --name gulf-analytics-prod \
  --location eastus \
  --admin-user gulf_admin \
  --admin-password <secure_password> \
  --sku-name Standard_D4s_v3 \
  --tier GeneralPurpose \
  --storage-size 256 \
  --version 14 \
  --backup-retention 7 \
  --high-availability Enabled
```

### Option C: Google Cloud SQL

```bash
# Create Cloud SQL instance
gcloud sql instances create gulf-analytics-prod \
  --database-version=POSTGRES_14 \
  --tier=db-custom-4-16384 \
  --region=us-central1 \
  --storage-size=200GB \
  --storage-type=SSD \
  --storage-auto-increase \
  --backup-start-time=03:00 \
  --maintenance-window-day=SUN \
  --maintenance-window-hour=4
```

---

## 5. Data Loading & Refresh Strategy

### Initial Load

Use `scripts/psql_load.sh` for initial one-time load.

### Incremental Refresh (Production Pattern)

Create a refresh script `scripts/incremental_refresh.sh`:

```bash
#!/usr/bin/env bash
# Incremental data refresh for production

set -euo pipefail

echo "Starting incremental refresh at $(date)"

# 1. Load new raw data (append-only)
psql -c "\copy raw.dld_transactions FROM '/data/new/dld_incremental.csv' WITH (FORMAT csv, HEADER true)"

# 2. Refresh staging (recreate from raw)
psql -f sql/20_staging_transform/stg_dld_transactions.sql
psql -f sql/20_staging_transform/stg_gastat_cpi_long.sql

# 3. Refresh dimensions (merge new records)
psql -f sql/30_dw_model/dw_dim_date.sql
psql -f sql/30_dw_model/dw_dim_property.sql
psql -f sql/30_dw_model/dw_dim_project.sql

# 4. Append to fact tables (incremental insert)
psql -f sql/30_dw_model/dw_fact_transactions.sql
psql -f sql/30_dw_model/dw_fact_cpi.sql

# 5. Refresh materialized views
psql -c "REFRESH MATERIALIZED VIEW CONCURRENTLY dw.mv_monthly_metrics;"
psql -c "REFRESH MATERIALIZED VIEW CONCURRENTLY dw.mv_project_leaderboard;"
psql -c "REFRESH MATERIALIZED VIEW CONCURRENTLY dw.mv_trends;"
psql -c "REFRESH MATERIALIZED VIEW CONCURRENTLY dw.mv_offplan_share;"
psql -c "REFRESH MATERIALIZED VIEW CONCURRENTLY dw.mv_macro_correlation;"

# 6. Maintenance
psql -f sql/99_performance/analyze_vacuum.sql

echo "Incremental refresh completed at $(date)"
```

### Automated Refresh (Cron Job)

```bash
# Add to crontab for daily refresh at 2 AM
0 2 * * * /path/to/gulf-sql-portfolio/scripts/incremental_refresh.sh >> /var/log/gulf_refresh.log 2>&1
```

---

## 6. Performance Tuning

### Query Performance Monitoring

```sql
-- Enable query statistics
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;

-- View slow queries (> 100ms)
SELECT
    query,
    calls,
    total_exec_time / 1000 AS total_sec,
    mean_exec_time AS avg_ms,
    max_exec_time AS max_ms
FROM pg_stat_statements
WHERE mean_exec_time > 100
ORDER BY total_exec_time DESC
LIMIT 20;
```

### Index Usage Analysis

```sql
-- Identify unused indexes (candidates for removal)
SELECT
    schemaname,
    tablename,
    indexname,
    idx_scan,
    pg_size_pretty(pg_relation_size(indexrelid)) AS size
FROM pg_stat_user_indexes
WHERE idx_scan = 0
  AND schemaname = 'dw'
ORDER BY pg_relation_size(indexrelid) DESC;
```

### Connection Pooling (pgBouncer)

For high-concurrency BI workloads, deploy pgBouncer:

```ini
# /etc/pgbouncer/pgbouncer.ini
[databases]
gulf = host=localhost port=5432 dbname=gulf

[pgbouncer]
listen_port = 6432
listen_addr = *
auth_type = md5
auth_file = /etc/pgbouncer/userlist.txt
pool_mode = transaction
max_client_conn = 200
default_pool_size = 25
```

---

## 7. Monitoring & Maintenance

### Health Check Script

Create `scripts/health_check.sh`:

```bash
#!/usr/bin/env bash

echo "=== Database Health Check ==="
echo ""

# Row counts
echo "Row Counts:"
psql -t -c "SELECT 'Raw DLD: ' || COUNT(*) FROM raw.dld_transactions;"
psql -t -c "SELECT 'Fact Txns: ' || COUNT(*) FROM dw.fact_transactions;"

# Data freshness
echo ""
echo "Data Freshness:"
psql -t -c "SELECT 'Latest Transaction Date: ' || MAX(date) FROM dw.dim_date JOIN dw.fact_transactions ON fact_transactions.date_key = dim_date.date_key;"

# Database size
echo ""
echo "Database Size:"
psql -t -c "SELECT pg_size_pretty(pg_database_size('gulf'));"

# Active connections
echo ""
echo "Active Connections:"
psql -t -c "SELECT COUNT(*) || ' active connections' FROM pg_stat_activity WHERE datname = 'gulf';"

echo ""
echo "=== Health Check Complete ==="
```

### Weekly Maintenance

```bash
#!/usr/bin/env bash
# Weekly maintenance script

# Full vacuum and analyze
psql -c "VACUUM FULL ANALYZE;"

# Reindex critical tables
psql -c "REINDEX TABLE dw.fact_transactions;"
psql -c "REINDEX TABLE dw.dim_date;"

# Update statistics
psql -c "ANALYZE;"
```

---

## 8. Backup & Recovery

### Automated Backups (pg_dump)

```bash
#!/usr/bin/env bash
# Daily backup script

BACKUP_DIR="/var/backups/gulf"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="$BACKUP_DIR/gulf_$DATE.sql.gz"

# Create backup
pg_dump -h localhost -U gulf_admin -d gulf | gzip > "$BACKUP_FILE"

# Retention: keep last 7 days
find "$BACKUP_DIR" -name "gulf_*.sql.gz" -mtime +7 -delete

echo "Backup completed: $BACKUP_FILE"
```

### Restore from Backup

```bash
# Restore full database
gunzip -c gulf_20241023_020000.sql.gz | psql -h localhost -U gulf_admin -d gulf_restored

# Restore specific schema
pg_restore -h localhost -U gulf_admin -d gulf -n dw backup_file.dump
```

### Cloud-Native Backups

- **AWS RDS**: Automated snapshots (7-35 day retention)
- **Azure**: Point-in-time restore (up to 35 days)
- **GCP**: Automated daily backups with 7-day default retention

---

## 9. Security Considerations

### SSL/TLS Encryption

```sql
-- Require SSL for connections
ALTER SYSTEM SET ssl = on;
ALTER SYSTEM SET ssl_cert_file = '/path/to/server.crt';
ALTER SYSTEM SET ssl_key_file = '/path/to/server.key';
```

### Role-Based Access Control

```sql
-- Analyst role (read-only on dw schema)
CREATE ROLE analyst WITH LOGIN PASSWORD 'analyst_password';
GRANT CONNECT ON DATABASE gulf TO analyst;
GRANT USAGE ON SCHEMA dw TO analyst;
GRANT SELECT ON ALL TABLES IN SCHEMA dw TO analyst;

-- ETL role (read-write on raw and stg, read dw)
CREATE ROLE etl_user WITH LOGIN PASSWORD 'etl_password';
GRANT CONNECT ON DATABASE gulf TO etl_user;
GRANT ALL ON SCHEMA raw, stg TO etl_user;
GRANT SELECT ON SCHEMA dw TO etl_user;
```

### Audit Logging

```sql
-- Enable query logging for auditing
ALTER SYSTEM SET log_statement = 'mod';  -- Log all DDL and DML
ALTER SYSTEM SET log_duration = on;
ALTER SYSTEM SET log_min_duration_statement = 1000;  -- Log queries > 1s
SELECT pg_reload_conf();
```

---

## 10. Troubleshooting

### Issue: Slow Query Performance

**Diagnosis:**
```sql
EXPLAIN (ANALYZE, BUFFERS) <your_query>;
```

**Common Fixes:**
- Add missing indexes
- Increase `work_mem` for sort/hash operations
- Update statistics: `ANALYZE <table>;`

### Issue: Connection Limit Exceeded

```sql
-- Check current connections
SELECT COUNT(*) FROM pg_stat_activity;

-- Increase max_connections
ALTER SYSTEM SET max_connections = 200;
SELECT pg_reload_conf();
```

### Issue: Disk Space Full

```bash
# Check table sizes
psql -c "SELECT schemaname, tablename, pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size FROM pg_tables WHERE schemaname IN ('raw', 'stg', 'dw') ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC LIMIT 10;"

# Drop old raw data if needed
psql -c "DELETE FROM raw.dld_transactions WHERE instance_date < '2022-01-01';"
psql -c "VACUUM FULL raw.dld_transactions;"
```

### Issue: Materialized View Out of Sync

```sql
-- Refresh all materialized views
REFRESH MATERIALIZED VIEW CONCURRENTLY dw.mv_monthly_metrics;
REFRESH MATERIALIZED VIEW CONCURRENTLY dw.mv_project_leaderboard;
REFRESH MATERIALIZED VIEW CONCURRENTLY dw.mv_trends;
```

---

## Support & Escalation

For issues not covered in this guide:

1. Check PostgreSQL logs: `/var/log/postgresql/postgresql-14-main.log`
2. Review GitHub Issues: `https://github.com/yourusername/gulf-sql-portfolio/issues`
3. Consult PostgreSQL documentation: `https://www.postgresql.org/docs/14/`

---

**Last Updated**: October 2025  
**Maintained By**: Project Team  
**Version**: 1.0
