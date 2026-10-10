# Fintech Transaction Fraud & Risk Analytics (PaySim, MySQL and Power BI)

Fraud and risk analysis of 6.36M simulated mobile-money transactions using MySQL and Power BI.

## Goal

Find where labeled fraud is concentrated, evaluate how well the existing fraud rule performs, and turn the findings into monitoring recommendations.

## Dataset

PaySim, a synthetic mobile-money transaction dataset: 6,362,620 transactions, 11 columns, `isFraud` as the label. The CSV is not stored in this repository because of its size. Download it from the PaySim source (Kaggle) and see `02_load_data.sql` for loading.

Because the data is simulated, findings describe patterns in the simulation and are hypotheses worth investigating, not proof of real-world causes.

## Tools

MySQL (analysis), Power BI (dashboard)

## Workflow

1. Load the raw data into a staging table and reconcile the row count
2. Profile the data and run data-quality checks
3. Build an analysis-ready table with helper columns
4. Root-cause analysis in SQL: fraud by type, amount, time, account behavior
5. Power BI dashboard and recommendations

## Findings so far

- Labeled fraud appears only in TRANSFER and CASH_OUT. TRANSFER has the higher fraud rate (0.77% versus 0.18% for CASH_OUT).
- The existing rule-based flag caught 16 of 8,213 fraud cases (0.19%) with no false alarms, so its coverage is very low.
- About 99.4% of the fraud in TRANSFER and CASH_OUT sits in the roughly 9.5% of those rows where the sender-balance arithmetic holds. This pattern warrants investigation.
- All 16 zero-amount transactions are CASH_OUT and labeled fraud.

## Repository contents

| File | Purpose |
|---|---|
| 01_create_database_and_table.sql | Database and raw staging table |
| 02_load_data.sql | Bulk load and row-count reconciliation |
| 03_profiling.sql | Fraud baseline, fraud by type, amounts, flag performance |
| 04_data_quality_checks.sql | Nulls, ranges, duplicates, balance consistency |
| 05_create_clean_table.sql | Analysis-ready table with derived columns |
| data_dictionary.md | Column meanings and derived fields |
| data_quality_summary.md | Check results and decisions |

## Status

In progress: root-cause analysis and Power BI dashboard to follow.
