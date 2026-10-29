-- 06_rca_queries.sql
-- Purpose: root-cause analysis of labeled fraud on clean_transactions.
-- Order: amount, amount within the two risky types, time, rule comparison,
-- account behavior. All fraud labels come from simulated data, so results are
-- patterns to investigate, not proof of real-world causes.

USE paysim_fraud;

-- Query 1: fraud by amount band (rate and share of all fraud)
SELECT amount_band,
       COUNT(*) AS txns,
       SUM(isFraud) AS fraud_txns,
       ROUND(SUM(isFraud) * 100.0 / COUNT(*), 4) AS fraud_rate_pct,
       ROUND(SUM(isFraud) * 100.0 /
             (SELECT SUM(isFraud) FROM clean_transactions), 2) AS share_of_all_fraud_pct
FROM clean_transactions
GROUP BY amount_band
ORDER BY amount_band;

-- Query 2: amount band within TRANSFER and CASH_OUT
SELECT type, amount_band,
       COUNT(*) AS txns,
       SUM(isFraud) AS fraud_txns,
       ROUND(SUM(isFraud) * 100.0 / COUNT(*), 4) AS fraud_rate_pct
FROM clean_transactions
WHERE type IN ('TRANSFER', 'CASH_OUT')
GROUP BY type, amount_band
ORDER BY type, amount_band;

-- Query 3: fraud by simulated day (compare rates AND counts; day 31 has 23 hours)
SELECT sim_day,
       COUNT(*) AS txns,
       SUM(isFraud) AS fraud_txns,
       ROUND(SUM(isFraud) * 100.0 / COUNT(*), 4) AS fraud_rate_pct
FROM clean_transactions
GROUP BY sim_day
ORDER BY sim_day;

-- Query 4: fraud by simulated hour of day (simulated hours, not a real clock)
SELECT hour_of_day,
       COUNT(*) AS txns,
       SUM(isFraud) AS fraud_txns,
       ROUND(SUM(isFraud) * 100.0 / COUNT(*), 4) AS fraud_rate_pct
FROM clean_transactions
GROUP BY hour_of_day
ORDER BY hour_of_day;

-- Query 5: compare candidate rules with the existing flag
-- precision = share of reviewed transactions that are fraud
-- recall    = share of all 8,213 frauds the rule catches
SELECT 'Existing flag' AS rule_name,
       COUNT(*) AS reviewed_txns, SUM(isFraud) AS fraud_caught,
       ROUND(SUM(isFraud) * 100.0 / COUNT(*), 2) AS precision_pct,
       ROUND(SUM(isFraud) * 100.0 / 8213, 2) AS recall_pct
FROM clean_transactions WHERE isFlaggedFraud = 1
UNION ALL
SELECT 'CASH_OUT 1M and above', COUNT(*), SUM(isFraud),
       ROUND(SUM(isFraud) * 100.0 / COUNT(*), 2),
       ROUND(SUM(isFraud) * 100.0 / 8213, 2)
FROM clean_transactions WHERE type = 'CASH_OUT' AND amount >= 1000000
UNION ALL
SELECT 'TRANSFER 1M and above', COUNT(*), SUM(isFraud),
       ROUND(SUM(isFraud) * 100.0 / COUNT(*), 2),
       ROUND(SUM(isFraud) * 100.0 / 8213, 2)
FROM clean_transactions WHERE type = 'TRANSFER' AND amount >= 1000000;

-- Query 6: how often do accounts repeat?
SELECT COUNT(*) AS txns,
       COUNT(DISTINCT nameOrig) AS distinct_senders,
       COUNT(DISTINCT nameDest) AS distinct_receivers
FROM clean_transactions;

-- Query 7: do fraud accounts repeat?
SELECT COUNT(*) AS fraud_txns,
       COUNT(DISTINCT nameOrig) AS fraud_senders,
       COUNT(DISTINCT nameDest) AS fraud_receivers
FROM clean_transactions
WHERE isFraud = 1;

-- Query 8: does fraud money move on (TRANSFER then CASH_OUT from the receiver)?
-- The index lets MySQL look up accounts without scanning every row.
CREATE INDEX idx_orig ON clean_transactions (nameOrig);

WITH fraud_transfers AS (
    SELECT nameDest, step
    FROM clean_transactions
    WHERE type = 'TRANSFER' AND isFraud = 1
)
SELECT COUNT(*) AS fraud_transfers,
       SUM(EXISTS (SELECT 1
                   FROM clean_transactions c
                   WHERE c.nameOrig = f.nameDest
                     AND c.type = 'CASH_OUT'
                     AND c.step >= f.step)) AS receiver_later_cashed_out
FROM fraud_transfers f;

-- Query 5b: the sender-balance pattern as a review rule
-- balance_mismatch = 0 means the rule (balance before - amount = balance after) holds
SELECT 'Balance rule holds, TRANSFER or CASH_OUT' AS rule_name,
       COUNT(*) AS reviewed_txns, SUM(isFraud) AS fraud_caught,
       ROUND(SUM(isFraud) * 100.0 / COUNT(*), 2) AS precision_pct,
       ROUND(SUM(isFraud) * 100.0 / 8213, 2) AS recall_pct
FROM clean_transactions
WHERE type IN ('TRANSFER', 'CASH_OUT') AND balance_mismatch = 0
UNION ALL
SELECT 'Balance rule holds, TRANSFER', COUNT(*), SUM(isFraud),
       ROUND(SUM(isFraud) * 100.0 / COUNT(*), 2),
       ROUND(SUM(isFraud) * 100.0 / 8213, 2)
FROM clean_transactions
WHERE type = 'TRANSFER' AND balance_mismatch = 0
UNION ALL
SELECT 'Balance rule holds, CASH_OUT', COUNT(*), SUM(isFraud),
       ROUND(SUM(isFraud) * 100.0 / COUNT(*), 2),
       ROUND(SUM(isFraud) * 100.0 / 8213, 2)
FROM clean_transactions
WHERE type = 'CASH_OUT' AND balance_mismatch = 0
UNION ALL
SELECT 'Combined: balance rule, or CASH_OUT 1M and above', COUNT(*), SUM(isFraud),
       ROUND(SUM(isFraud) * 100.0 / COUNT(*), 2),
       ROUND(SUM(isFraud) * 100.0 / 8213, 2)
FROM clean_transactions
WHERE (type IN ('TRANSFER', 'CASH_OUT') AND balance_mismatch = 0)
   OR (type = 'CASH_OUT' AND amount >= 1000000);
