-- -----------------------------------------------------------------------------
-- Dimension table for projects
--
-- Creates a surrogate key for each unique master project and project name.
-- Projects are ordered alphabetically to ensure stable surrogate assignment.
-- -----------------------------------------------------------------------------

DROP TABLE IF EXISTS dw.dim_project;

CREATE TABLE dw.dim_project (
    project_key SERIAL PRIMARY KEY,
    master_project_en text,
    project_en text,
    UNIQUE (master_project_en, project_en)
);

INSERT INTO dw.dim_project (master_project_en, project_en)
SELECT DISTINCT
    master_project_en,
    project_en
FROM stg.dld_transactions
ORDER BY master_project_en, project_en;

ANALYZE dw.dim_project;