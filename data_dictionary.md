# Data Dictionary

Source: PaySim, a simulated mobile-money transaction dataset (6,362,620 rows, 11 columns).
Because the data is synthetic, findings describe patterns in the simulation, not real-world causes of fraud.

## Raw columns

| Column | Meaning | Type | Role |
|---|---|---|---|
| step | Hour of simulated time (1 to 743, about 31 days) | INT | Time |
| type | Transaction type: PAYMENT, TRANSFER, CASH_OUT, CASH_IN, DEBIT | VARCHAR | Dimension |
| amount | Transaction amount (0 to about 92.4M, heavily right-skewed) | DECIMAL | Measure |
| nameOrig | Account that starts the transaction | VARCHAR | Entity |
| oldbalanceOrg | Sender balance before the transaction | DECIMAL | Feature |
| newbalanceOrig | Sender balance after the transaction | DECIMAL | Feature |
| nameDest | Receiving account | VARCHAR | Entity |
| oldbalanceDest | Receiver balance before the transaction | DECIMAL | Feature |
| newbalanceDest | Receiver balance after the transaction | DECIMAL | Feature |
| isFraud | 1 = fraud, 0 = not fraud | TINYINT | Target |
| isFlaggedFraud | 1 = flagged by the system's built-in rule | TINYINT | Indicator |

## Derived columns (clean_transactions)

| Column | Definition | Purpose |
|---|---|---|
| sim_day | CEIL(step / 24) | Fraud by simulated day |
| hour_of_day | ((step - 1) % 24) + 1 | Fraud by simulated hour |
| amount_band | Size groups from Zero to 1M and above | Fraud by amount range |
| is_zero_amount | 1 if amount = 0 | Isolates the 16 zero-amount rows |
| balance_mismatch | 1 if sender balance before - amount does not equal balance after (CASH_IN excluded) | Balance-consistency pattern |
