## ADDED Requirements

### Requirement: BB Flip Dispatch Architecture
The system SHALL implement the `bb_flip` admin flip dispatch as a **table-driven pattern**: a `static const` array of `{cmd, handler, name}` entries indexed by `cdw10`, with a linear `for` loop over the array to find the matching handler. Each FEMU_* enum value MUST be mapped to a static handler function via the table (not via `switch`/`case`).

This requirement documents the implementation architecture chosen in the `refactor-bb-flip-table` change (2026-06-23) and applies to **future implementations**: any new admin flip MUST be added to the table, not as a new `case` block in `bb_flip`. This requirement does NOT change the observable behavior of any existing flip — all 11 admin flip commands (FEMU_ENABLE_GC_DELAY through FEMU_PRINT_BB_CONFIG) MUST produce identical `femu_log` output and identical side effects as the prior switch-based implementation.

#### Scenario: All 11 existing admin flips remain behavior-identical after refactor
- **WHEN** operator issues any of FEMU_ENABLE_GC_DELAY, FEMU_DISABLE_GC_DELAY, FEMU_ENABLE_DELAY_EMU, FEMU_DISABLE_DELAY_EMU, FEMU_RESET_ACCT, FEMU_ENABLE_LOG, FEMU_DISABLE_LOG, FEMU_RESET_CRT_STATS, FEMU_PRINT_CRT_STATS, FEMU_LOG_VERSION, or FEMU_PRINT_BB_CONFIG
- **THEN** system produces the same `femu_log` string and same state changes as documented in their respective requirements
- **AND THEN** the dispatch mechanism SHALL be the `bb_flip_table[]` array (verified via `nm`: `bb_flip_table` is `static const`; `bb_flip` calls handler via function pointer from the table)

#### Scenario: Unknown flip id falls through to default case
- **WHEN** operator issues a flip with a `cdw10` value that is not a defined `FEMU_*` enum value
- **THEN** system prints `"FEMU:%s,Not implemented flip cmd (%lu)\n"` (same default behavior as the prior switch implementation)

#### Scenario: New admin flip added in a future change
- **WHEN** a future change introduces a new FEMU_* admin flip
- **THEN** the new flip MUST be added to `bb_flip_table[]` (not as a new `case` in `bb_flip`)
- **AND THEN** a corresponding ADDED Requirement SHALL be added to this spec documenting the new flip's behavior

