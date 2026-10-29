# Fintech Transaction Fraud & Risk Analytics (PaySim, MySQL and Power BI)

Fraud and risk analysis of 6.36M simulated mobile-money transactions. The project finds where labeled fraud is concentrated, tests how well the existing fraud rule performs, compares candidate review rules, and presents the results in a Power BI dashboard.

![Dashboard](dashboard_screenshot.png)

## Goal

Answer four questions a risk team would ask:

1. Where is fraud concentrated: by transaction type, amount and time?
2. How well does the existing rule-based flag perform?
3. Do fraud accounts show repeat behavior?
4. Which review rules would catch the most fraud for the least review effort?

## Dataset

PaySim, a synthetic mobile-money transaction dataset: 6,362,620 transactions, 11 columns, `isFraud` as the label (8,213 fraud cases). The CSV is not stored in this repository because of its size. Download it from the PaySim source on Kaggle and see `02_load_data.sql` for loading.

Because the data is simulated, every finding describes a pattern in the simulation and is a hypothesis worth investigating, not proof of a real-world cause.

## Tools

MySQL (loading, data quality, analysis) and Power BI (dashboard).

## Method

1. Load the raw CSV into an untouched staging table and reconcile the row count (6,362,620).
2. Profile the data and run data-quality checks: nulls, duplicates, ranges, zero amounts and balance consistency.
3. Build an analysis table with derived columns: simulated day and hour, amount band, zero-amount flag and balance-mismatch flag.
4. Run root-cause queries by type, amount, time, account behavior and candidate review rules.
5. Build four small summary tables and a one-page Power BI dashboard from them.

## Key findings

| # | Finding | Evidence |
|---|---|---|
| 1 | Labeled fraud appears only in TRANSFER and CASH_OUT. | TRANSFER: 4,097 of 532,909 (0.77%). CASH_OUT: 4,116 of 2,237,500 (0.18%). PAYMENT, DEBIT and CASH_IN: 0 fraud. |
| 2 | Very large transactions carry much higher fraud rates, driven by one segment. | The 1M and above band is about 2% of transactions but 33% of fraud (2.07% rate). Within it, CASH_OUT of 1M and above is 81.6% fraud (1,345 of 1,648). |
| 3 | Fraud arrives at a steady pace while normal volume swings widely. | 216 to 320 fraud cases per simulated day, against 272 to 574,255 transactions per day. Extreme daily or hourly rates reflect small denominators. |
| 4 | The existing flag has almost no coverage. | It flagged 16 transactions, all fraud, and caught 16 of 8,213 frauds (0.19%). |
| 5 | The sender-balance pattern separates fraud sharply. | Reviewing the 262,688 TRANSFER and CASH_OUT rows where the balance arithmetic holds (about 4% of all transactions) catches 8,168 frauds (99.45%), at 3.11% precision. |
| 6 | Fraud does not come from repeat accounts or follow-on cash-outs. | 8,213 fraud transactions come from 8,213 distinct senders, and only 1 of 4,097 fraud transfers had its receiver cash out later. |

## Rule comparison

Precision is the share of reviewed transactions that are fraud. Recall is the share of all fraud a rule catches.

| Rule | Reviewed | Fraud caught | Precision | Recall |
|---|---|---|---|---|
| Existing flag | 16 | 16 | 100.00% | 0.19% |
| CASH_OUT of 1M and above | 1,648 | 1,345 | 81.61% | 16.38% |
| Balance rule holds (TRANSFER or CASH_OUT) | 262,688 | 8,168 | 3.11% | 99.45% |

## Recommendations to investigate

1. Focus monitoring on TRANSFER and CASH_OUT, the only types with labeled fraud.
2. Use two review tiers: CASH_OUT of 1M and above first, then the wider balance-pattern group for coverage.
3. Replace or expand the existing flag, whose coverage is 0.19%.
4. Do not rely on account-history rules on this data, because each fraud came from a one-time sender.
5. Treat all rules as candidates to test on real data before any deployment.

## Data quality

No nulls, duplicates or negative values were found. 16 zero-amount rows (all CASH_OUT and all fraud) were kept and flagged. The sender-balance rule fails for most non-CASH_IN rows, so it was flagged and analyzed as a feature. One interrupted load doubled the table to 12,725,240 rows. It was truncated and reloaded, and the final count reconciled to 6,362,620. Full details are in `data_quality_summary.md`.

## Repository contents

| File | Purpose |
|---|---|
| 01_create_database_and_table.sql | Database and raw staging table |
| 02_load_data.sql | Bulk load and row-count reconciliation |
| 03_profiling.sql | Fraud baseline, fraud by type, amounts, flag performance |
| 04_data_quality_checks.sql | Nulls, ranges, duplicates, balance consistency |
| 05_create_clean_table.sql | Analysis table with derived columns |
| 06_rca_queries.sql | Root-cause queries and rule comparison |
| 07_summary_tables.sql | Summary tables used by the dashboard |
| data_dictionary.md | Column meanings and derived fields |
| data_quality_summary.md | Check results and decisions |
| paysim_fraud_dashboard.pbix | Power BI dashboard |
| dashboard_screenshot.png | Dashboard screenshot |

## How to reproduce

1. Download the PaySim CSV and place it in the folder allowed by `secure_file_priv`.
2. Run the SQL files in order, 01 to 07. Adjust the file path in `02_load_data.sql`.
3. Export the four summary tables as CSV and load them into Power BI, or open the included `.pbix`.

## Limitations

- The data is simulated. Patterns such as the balance-rule result may reflect how PaySim generates fraud and may not hold on real data.
- Time is simulated hours (743 steps, about 31 days), not a real clock, so no real-world time-of-day conclusions are drawn.
- The balance rule has low precision (3.11%), so it narrows a review list and is not suited to automatic blocking.
