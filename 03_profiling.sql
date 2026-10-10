-- 03_profiling.sql
-- Purpose: first look at the data (structure, fraud baseline, fraud by type,
-- amount range, performance of the existing fraud flag).

USE paysim_fraud;

-- 1. Structure check
DESCRIBE raw_transactions;

-- 2. Overall fraud baseline
SELECT COUNT(*) AS total_txns,
       SUM(isFraud) AS fraud_txns,
       ROUND(SUM(isFraud) * 100.0 / COUNT(*), 4) AS fraud_rate_pct
FROM raw_transactions;

-- 3. Fraud by transaction type
SELECT type,
       COUNT(*) AS total_txns,
       SUM(isFraud) AS fraud_txns,
       ROUND(SUM(isFraud) * 100.0 / COUNT(*), 4) AS fraud_rate_pct
FROM raw_transactions
GROUP BY type
ORDER BY fraud_txns DESC;

-- 4a. Amount range
SELECT MIN(amount) AS min_amt,
       MAX(amount) AS max_amt,
       ROUND(AVG(amount), 2) AS avg_amt,
       SUM(amount = 0) AS zero_amount_txns
FROM raw_transactions;

-- 4b. How well does the existing rule-based flag perform?
SELECT isFlaggedFraud, isFraud, COUNT(*) AS txns
FROM raw_transactions
GROUP BY isFlaggedFraud, isFraud;
