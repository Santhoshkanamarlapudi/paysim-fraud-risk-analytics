# Data Quality Summary

| Check | Result | Decision |
|---|---|---|
| Row count | 6,362,620, matches the source file | Raw table verified |
| Nulls and blanks | None found | No imputation needed |
| Duplicates | 0 duplicate groups | Nothing to remove |
| Negative values | None in amounts or balances | None needed |
| Step range | 1 to 743, 743 distinct steps | Derive simulated day and hour |
| Zero-amount rows | 16 rows, all CASH_OUT, all labeled fraud, none flagged by the system | Keep, add is_zero_amount flag |
| Sender balance rule | Fails for most non-CASH_IN rows; most failures have an amount larger than the sender's balance, and about half show zero balances | Keep, add balance_mismatch flag, treat as a finding |
| Existing fraud flag | 16 flagged, all real fraud; catches 16 of 8,213 frauds (0.19%) | Use as a comparison point for recommendations |

## Load incident

An interrupted load (client timeout, error 2013) later produced a doubled table of 12,725,240 rows. The table was truncated and reloaded once; the final count reconciled to 6,362,620.

## Limitation

The data is simulated. Patterns found here are hypotheses that would need investigation on real data.
