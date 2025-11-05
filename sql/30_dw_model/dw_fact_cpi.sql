-- -----------------------------------------------------------------------------
-- Fact table for CPI indices
--
-- Associates each CPI basket item and quarter with a surrogate key and links
-- to the date dimension.  Includes quarter‑over‑quarter (qoq) and
-- year‑over‑year (yoy) changes.
-- -----------------------------------------------------------------------------

DROP TABLE IF EXISTS dw.fact_cpi;

CREATE TABLE dw.fact_cpi (
    cpi_key SERIAL PRIMARY KEY,
    date_key int NOT NULL,
    item_code text NOT NULL,
    item_desc text,
    cpi_index numeric,
    qoq numeric,
    yoy numeric
);

INSERT INTO dw.fact_cpi (date_key, item_code, item_desc, cpi_index, qoq, yoy)
SELECT
    dd.date_key,
    gl.item_code,
    gl.item_desc,
    gl.cpi_index,
    gl.qoq,
    gl.yoy
FROM stg.gastat_cpi_long gl
JOIN dw.dim_date dd ON dd.date = gl.quarter_start;

-- Add foreign key constraint
ALTER TABLE dw.fact_cpi 
    ADD CONSTRAINT fact_cpi_date_fk 
    FOREIGN KEY (date_key) REFERENCES dw.dim_date(date_key);

-- Create indexes
CREATE INDEX IF NOT EXISTS fact_cpi_date_key_idx ON dw.fact_cpi (date_key);
CREATE INDEX IF NOT EXISTS fact_cpi_item_code_idx ON dw.fact_cpi (item_code);

ANALYZE dw.fact_cpi;