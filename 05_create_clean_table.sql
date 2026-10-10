-- 05_create_clean_table.sql
-- Purpose: build the analysis-ready table. raw_transactions is left untouched.
-- No rows are removed (the checks found no nulls, duplicates or negatives);
-- helper columns are added to support the root-cause analysis.

USE paysim_fraud;

CREATE TABLE clean_transactions AS
SELECT
    step,
    CEIL(step / 24) AS sim_day,                 -- simulated day (1 to 31)
    ((step - 1) % 24) + 1 AS hour_of_day,       -- simulated hour (1 to 24)
    type,
    amount,
    CASE
        WHEN amount = 0        THEN '0. Zero'
        WHEN amount < 1000     THEN '1. Under 1K'
        WHEN amount < 10000    THEN '2. 1K to 10K'
        WHEN amount < 100000   THEN '3. 10K to 100K'
        WHEN amount < 1000000  THEN '4. 100K to 1M'
        ELSE                        '5. 1M and above'
    END AS amount_band,
    nameOrig, oldbalanceOrg, newbalanceOrig,
    nameDest, oldbalanceDest, newbalanceDest,
    (amount = 0) AS is_zero_amount,
    (type <> 'CASH_IN'
     AND ROUND(oldbalanceOrg - amount - newbalanceOrig, 2) <> 0) AS balance_mismatch,
    isFraud,
    isFlaggedFraud
FROM raw_transactions;

-- Verify: expect 6,362,620 rows, 8,213 fraud rows, 16 zero-amount rows
SELECT COUNT(*) AS total_rows,
       SUM(isFraud) AS fraud_rows,
       SUM(is_zero_amount) AS zero_amount_rows,
       SUM(balance_mismatch) AS mismatch_rows
FROM clean_transactions;
