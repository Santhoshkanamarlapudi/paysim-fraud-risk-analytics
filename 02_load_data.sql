-- 02_load_data.sql
-- Purpose: bulk-load the PaySim CSV into the raw staging table.
-- Notes:
--   * Uses server-side LOAD DATA INFILE (no LOCAL). The CSV must sit inside the
--     folder returned by:  SHOW VARIABLES LIKE 'secure_file_priv';
--   * Use forward slashes in the path (backslash is MySQL's escape character).
--   * Adjust the path below to where your CSV is stored.
--   * TRUNCATE first so a re-run never duplicates rows.

USE paysim_fraud;
TRUNCATE TABLE raw_transactions;

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/paysim.csv'
INTO TABLE raw_transactions
FIELDS TERMINATED BY ','
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

-- Reconcile against the source: expected 6,362,620 rows
SELECT COUNT(*) AS total_rows FROM raw_transactions;
