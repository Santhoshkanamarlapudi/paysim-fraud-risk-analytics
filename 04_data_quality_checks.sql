-- 04_data_quality_checks.sql
-- Purpose: test the raw data for missing values, invalid ranges, odd rows,
-- balance consistency and duplicates before any analysis.

USE paysim_fraud;

-- Check 1: nulls and blanks
SELECT
  SUM(step IS NULL) AS null_step,
  SUM(type IS NULL OR type = '') AS bad_type,
  SUM(amount IS NULL) AS null_amount,
  SUM(nameOrig IS NULL OR nameOrig = '') AS bad_orig,
  SUM(nameDest IS NULL OR nameDest = '') AS bad_dest,
  SUM(oldbalanceOrg IS NULL) AS null_old_orig,
  SUM(newbalanceOrig IS NULL) AS null_new_orig,
  SUM(oldbalanceDest IS NULL) AS null_old_dest,
  SUM(newbalanceDest IS NULL) AS null_new_dest,
  SUM(isFraud IS NULL) AS null_fraud,
  SUM(isFlaggedFraud IS NULL) AS null_flagged
FROM raw_transactions;

-- Check 2: time range and negative values
SELECT MIN(step) AS min_step, MAX(step) AS max_step,
       COUNT(DISTINCT step) AS distinct_steps,
       SUM(amount < 0) AS neg_amount,
       SUM(oldbalanceOrg < 0 OR newbalanceOrig < 0
           OR oldbalanceDest < 0 OR newbalanceDest < 0) AS neg_balance
FROM raw_transactions;

-- Check 3: zero-amount rows
SELECT type, isFraud, isFlaggedFraud, COUNT(*) AS txns
FROM raw_transactions
WHERE amount = 0
GROUP BY type, isFraud, isFlaggedFraud;

-- Check 4: sender-balance rule (balance before - amount = balance after),
-- tested for every type except CASH_IN (a deposit increases the balance)
SELECT type, COUNT(*) AS mismatches
FROM raw_transactions
WHERE type <> 'CASH_IN'
  AND ROUND(oldbalanceOrg - amount - newbalanceOrig, 2) <> 0
GROUP BY type;

-- Check 4b: what do the mismatching rows look like?
SELECT type,
       COUNT(*) AS mismatches,
       SUM(oldbalanceOrg = 0 AND newbalanceOrig = 0) AS both_balances_zero,
       SUM(newbalanceOrig = oldbalanceOrg) AS balance_unchanged,
       SUM(amount > oldbalanceOrg) AS amount_exceeds_balance
FROM raw_transactions
WHERE type <> 'CASH_IN'
  AND ROUND(oldbalanceOrg - amount - newbalanceOrig, 2) <> 0
GROUP BY type;

-- Check 4c: do balance mismatches relate to fraud?
SELECT type,
       (ROUND(oldbalanceOrg - amount - newbalanceOrig, 2) <> 0) AS balance_mismatch,
       COUNT(*) AS txns,
       SUM(isFraud) AS fraud_txns
FROM raw_transactions
WHERE type IN ('TRANSFER', 'CASH_OUT')
GROUP BY type, balance_mismatch;

-- Check 5: exact duplicates (may take a few minutes without an index)
SELECT COUNT(*) AS duplicate_groups
FROM (
  SELECT step, type, amount, nameOrig, nameDest, COUNT(*) AS c
  FROM raw_transactions
  GROUP BY step, type, amount, nameOrig, nameDest
  HAVING c > 1
) d;
