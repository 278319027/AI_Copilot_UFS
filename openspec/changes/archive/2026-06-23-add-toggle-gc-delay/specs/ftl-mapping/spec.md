## ADDED Requirements

### Requirement: BB Toggle GC Delay Flip
The system SHALL provide an admin flip `FEMU_TOGGLE_GC_DELAY` that **atomically toggles** the `enable_gc_delay` field: each invocation inverts the current value (`true` becomes `false`, `false` becomes `true`). The output MUST be emitted via the existing `femu_log` helper in the format `"<devname>,FEMU GC Delay Emulation [<Enabled|Disabled>]!\n"` (same prefix as `FEMU_ENABLE_GC_DELAY` / `FEMU_DISABLE_GC_DELAY`, with `Enabled` or `Disabled` reflecting the **new** state after toggle).

This flip is independent of and complementary to the existing `FEMU_ENABLE_GC_DELAY` / `FEMU_DISABLE_GC_DELAY` pair: all three flips operate on the same `ssd->sp.enable_gc_delay` field, and any combination is valid (e.g., ENABLE then TOGGLE then DISABLE).

#### Scenario: Operator toggles from default (off) to on
- **WHEN** operator issues `FEMU_TOGGLE_GC_DELAY` flip and `enable_gc_delay` is currently `false` (default)
- **THEN** system sets `enable_gc_delay = true` and prints `"<devname>,FEMU GC Delay Emulation [Enabled]!\n"`

#### Scenario: Operator toggles from on to off
- **WHEN** operator issues `FEMU_TOGGLE_GC_DELAY` flip and `enable_gc_delay` is currently `true` (e.g., after `FEMU_ENABLE_GC_DELAY`)
- **THEN** system sets `enable_gc_delay = false` and prints `"<devname>,FEMU GC Delay Emulation [Disabled]!\n"`

#### Scenario: Operator toggles twice (idempotent cycle: off→on→off)
- **WHEN** operator issues `FEMU_TOGGLE_GC_DELAY` twice in a row
- **THEN** system prints `"[Enabled]!"` followed by `"[Disabled]!"`, and `enable_gc_delay` returns to its original value

#### Scenario: Flip id not recognized (default case)
- **WHEN** operator issues any flip with a `cdw10` value that is not a defined `FEMU_*` enum value
- **THEN** system falls through to the existing default branch (per `add-print-version-flip` / `refactor-bb-flip-table` / `add-print-num-io` precedent) and prints the existing not-implemented message
