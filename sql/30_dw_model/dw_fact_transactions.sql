-- -----------------------------------------------------------------------------
-- Fact table for real estate transactions
--
-- This table is built by joining the staging transactions to the date,
-- property and project dimensions.  It stores numeric measures such as
-- transaction value, area and price per square metre.  A surrogate key
-- (`transaction_key`) provides a simple identifier.
-- -----------------------------------------------------------------------------

DROP TABLE IF EXISTS dw.fact_transactions;

CREATE TABLE dw.fact_transactions (
    transaction_key SERIAL PRIMARY KEY,
    date_key int NOT NULL,
    property_key int NOT NULL,
    project_key int NOT NULL,
    trans_value numeric,
    actual_area numeric,
    price_per_sqm numeric
);

INSERT INTO dw.fact_transactions (date_key, property_key, project_key, trans_value, actual_area, price_per_sqm)
SELECT
    dd.date_key,
    dp.property_key,
    pr.project_key,
    st.trans_value,
    st.actual_area,
    CASE WHEN st.actual_area > 0 THEN st.trans_value / st.actual_area ELSE NULL END AS price_per_sqm
FROM stg.dld_transactions st
JOIN dw.dim_date dd
    ON dd.date = st.txn_date
JOIN dw.dim_property dp
    ON dp.usage_en = st.usage_en
   AND dp.prop_type_en = st.prop_type_en
   AND dp.prop_sb_type_en IS NOT DISTINCT FROM st.prop_sb_type_en
   AND dp.is_offplan = st.is_offplan
   AND dp.is_freehold = st.is_freehold
JOIN dw.dim_project pr
    ON pr.master_project_en = st.master_project_en
   AND pr.project_en = st.project_en;

-- Add foreign key constraints for referential integrity
ALTER TABLE dw.fact_transactions 
    ADD CONSTRAINT fact_transactions_date_fk 
    FOREIGN KEY (date_key) REFERENCES dw.dim_date(date_key);

ALTER TABLE dw.fact_transactions 
    ADD CONSTRAINT fact_transactions_property_fk 
    FOREIGN KEY (property_key) REFERENCES dw.dim_property(property_key);

ALTER TABLE dw.fact_transactions 
    ADD CONSTRAINT fact_transactions_project_fk 
    FOREIGN KEY (project_key) REFERENCES dw.dim_project(project_key);

-- Create indexes for query performance
CREATE INDEX IF NOT EXISTS fact_transactions_date_key_idx ON dw.fact_transactions (date_key);
CREATE INDEX IF NOT EXISTS fact_transactions_property_key_idx ON dw.fact_transactions (property_key);
CREATE INDEX IF NOT EXISTS fact_transactions_project_key_idx ON dw.fact_transactions (project_key);
CREATE INDEX IF NOT EXISTS fact_transactions_date_property_idx ON dw.fact_transactions (date_key, property_key);

ANALYZE dw.fact_transactions;