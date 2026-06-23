## ADDED Requirements

### Requirement: BB Print Num IO Flip
The system SHALL provide an admin flip `FEMU_PRINT_NUM_IO` that prints the current value of `nr_tt_ios` and `nr_tt_late_ios` to `femu_log` **without resetting** them. The output MUST be emitted via the existing `femu_log` helper in the same format as `FEMU_RESET_ACCT` (per "Reset tt_late_ios/tt_ios,%lu/%lu" pattern), with the leading "Reset" replaced by "Num" (i.e., `"%s,Num tt_late_ios/tt_ios,%lu/%lu\n"`). The system MUST NOT modify `nr_tt_ios` or `nr_tt_late_ios` as a side effect of this flip.

#### Scenario: Operator queries ACCT counters at default (no IOs yet)
- **WHEN** operator issues `FEMU_PRINT_NUM_IO` flip and no IOs have been issued
- **THEN** system prints `"<devname>,Num tt_late_ios/tt_ios,0/0\n"` and `nr_tt_ios` and `nr_tt_late_ios` remain 0

#### Scenario: Operator queries ACCT counters after some IOs
- **WHEN** operator issues `N` IOs (some early, some late) and then issues `FEMU_PRINT_NUM_IO` flip
- **THEN** system prints `"<devname>,Num tt_late_ios/tt_ios,<late_count>/<N>\n"` with non-zero counts and `nr_tt_ios` and `nr_tt_late_ios` remain unchanged after the query

#### Scenario: Operator queries after FEMU_RESET_ACCT (counters should be 0)
- **WHEN** operator issues `FEMU_RESET_ACCT` followed by `FEMU_PRINT_NUM_IO`
- **THEN** system prints `"<devname>,Num tt_late_ios/tt_ios,0/0\n"` (the new flip does NOT reset; it only reads current values which are now 0)

#### Scenario: Flip id not recognized (default case)
- **WHEN** operator issues any flip with a `cdw10` value that is not a defined `FEMU_*` enum value
- **THEN** system falls through to the existing default branch (per `add-print-version-flip` / `refactor-bb-flip-table` precedent) and prints the existing not-implemented message
