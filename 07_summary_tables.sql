-- 07_summary_tables.sql
-- Purpose: small summary tables for the Power BI dashboard, so Power BI loads
-- a few rows instead of 6.36M. Built from clean_transactions.

USE paysim_fraud;

-- 1. Fraud by transaction type
CREATE TABLE summary_by_type AS
SELECT type,
       COUNT(*) AS txns,
       SUM(isFraud) AS fraud_txns,
       ROUND(SUM(isFraud) * 100.0 / COUNT(*), 4) AS fraud_rate_pct
FROM clean_transactions
GROUP BY type;

-- 2. Fraud by amount band
CREATE TABLE summary_by_amount_band AS
SELECT amount_band,
       COUNT(*) AS txns,
       SUM(isFraud) AS fraud_txns,
       ROUND(SUM(isFraud) * 100.0 / COUNT(*), 4) AS fraud_rate_pct,
       ROUND(SUM(isFraud) * 100.0 /
             (SELECT SUM(isFraud) FROM clean_transactions), 2) AS share_of_fraud_pct
FROM clean_transactions
GROUP BY amount_band;

-- 3. Fraud by simulated day
CREATE TABLE summary_by_day AS
SELECT sim_day,
       COUNT(*) AS txns,
       SUM(isFraud) AS fraud_txns,
       ROUND(SUM(isFraud) * 100.0 / COUNT(*), 4) AS fraud_rate_pct
FROM clean_transactions
GROUP BY sim_day;

-- 4. Review rules compared (precision = share of reviewed that are fraud,
--    recall = share of all 8,213 frauds caught)
CREATE TABLE summary_rules AS
SELECT 'Existing flag' AS rule_name,
       COUNT(*) AS reviewed_txns,
       SUM(isFraud) AS fraud_caught,
       ROUND(SUM(isFraud) * 100.0 / COUNT(*), 2) AS precision_pct,
       ROUND(SUM(isFraud) * 100.0 / 8213, 2) AS recall_pct
FROM clean_transactions
WHERE isFlaggedFraud = 1
UNION ALL
SELECT 'CASH_OUT 1M and above', COUNT(*), SUM(isFraud),
       ROUND(SUM(isFraud) * 100.0 / COUNT(*), 2),
       ROUND(SUM(isFraud) * 100.0 / 8213, 2)
FROM clean_transactions
WHERE type = 'CASH_OUT' AND amount >= 1000000
UNION ALL
SELECT 'Balance rule holds (TRANSFER or CASH_OUT)', COUNT(*), SUM(isFraud),
       ROUND(SUM(isFraud) * 100.0 / COUNT(*), 2),
       ROUND(SUM(isFraud) * 100.0 / 8213, 2)
FROM clean_transactions
WHERE type IN ('TRANSFER', 'CASH_OUT') AND balance_mismatch = 0;

-- Verify: expect 5, 6, 31 and 3 rows
SELECT (SELECT COUNT(*) FROM summary_by_type) AS type_rows,
       (SELECT COUNT(*) FROM summary_by_amount_band) AS band_rows,
       (SELECT COUNT(*) FROM summary_by_day) AS day_rows,
       (SELECT COUNT(*) FROM summary_rules) AS rule_rows;

-- Verify totals: expect 6,362,620 and 8,213
SELECT SUM(txns) AS total_txns, SUM(fraud_txns) AS total_fraud
FROM summary_by_day;
