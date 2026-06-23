## ADDED Requirements

### Requirement: BB Configuration Reporting Flip
The system SHALL provide an admin flip `FEMU_PRINT_BB_CONFIG` that prints a single line containing the current state of all BB mode feature flags. The output MUST be emitted via the existing `femu_log` helper and MUST list, in a fixed order, the following four flags: `enable_gc_delay`, `print_log`, `enable_crt`, and the delay-emulation state (derived as `pg_rd_lat != 0`). Each flag MUST be rendered as `name=on` or `name=off`.

#### Scenario: Operator queries config with all flags at default
- **WHEN** operator issues the `FEMU_PRINT_BB_CONFIG` flip and no prior enable flips have been issued
- **THEN** system prints a single line of the form `FEMU BB config: gc_delay=off, log=off, crt=off, delay_emu=off`

#### Scenario: Operator queries config after enabling GC delay
- **WHEN** operator issues `FEMU_ENABLE_GC_DELAY` followed by `FEMU_PRINT_BB_CONFIG`
- **THEN** system prints a single line with `gc_delay=on` and the other three flags reflecting their current state

#### Scenario: Operator queries config after enabling delay emulation
- **WHEN** operator issues `FEMU_ENABLE_DELAY_EMU` followed by `FEMU_PRINT_BB_CONFIG`
- **THEN** system prints a single line with `delay_emu=on` (derived from `pg_rd_lat != 0`) and the other three flags reflecting their current state

#### Scenario: Flip id not recognized
- **WHEN** operator issues any flip with a `cdw10` value that is not a defined `FEMU_*` enum value
- **THEN** system falls through to the existing default branch (per `add-print-version-flip` precedent) and prints the existing not-implemented message
