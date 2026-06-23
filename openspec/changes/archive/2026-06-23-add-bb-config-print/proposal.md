## Why

FEMU BB mode currently lets operators toggle individual features (`FEMU_ENABLE_GC_DELAY` / `FEMU_ENABLE_LOG` / `FEMU_ENABLE_DELAY_EMU` / `ssd->sp.enable_crt` via spec init) but offers no way to **view the current combined state** of these flags in one place. The only existing `FEMU_LOG_VERSION` (added in `add-print-version-flip`) prints CRT state alone; the rest of BB mode is invisible at runtime. This change adds a one-shot `FEMU_PRINT_BB_CONFIG` admin flip that prints all BB mode feature flags on a single line, so operators can verify the running configuration without reading source or attaching a debugger.

## What Changes

- Add `FEMU_PRINT_BB_CONFIG = 11` enum value to `bbssd/ftl.h` flip enum (appended after `FEMU_LOG_VERSION = 10`).
- Extend `bb_flip` switch in `bbssd/bb.c` with one case that prints a single-line config summary via `femu_log`, covering: `enable_gc_delay`, `enable_crt`, `print_log`, and the delay-emulation state (derived from `pg_rd_lat != 0`).
- No new public API surface beyond the new enum value; consumed via existing `bb_admin_cmd` dispatch.
- Spec delta: 1 ADDED Requirement in `openspec/specs/ftl-mapping/spec.md` documenting the flip's contract.

## Capabilities

### New Capabilities
- 无

### Modified Capabilities
- `ftl-mapping`: add 1 ADDED Requirement (`BB Configuration Reporting Flip`) defining the flip's output contract (which flags, in what format, when invoked).

## Impact

- **Code**: 2 files modified (`bbssd/ftl.h` enum, `bbssd/bb.c` switch case). ~10 lines total.
- **Spec**: 1 ADDED Requirement in `openspec/specs/ftl-mapping/spec.md`.
- **No new memory rules, no QOM property, no test framework** — the flip is a 5-line `printf`-style helper; verified manually at QEMU CLI (consistent with `add-print-version-flip` decision D3).
- **No external dependencies**: uses only existing `femu_log` helper and `ssd->sp.*` / `n->print_log` fields.

## Non-goals

- **Real-time config updates** (no change to flip semantics; existing `enable_*` flips still required to mutate state).
- **Including latency values** (e.g., `pg_rd_lat` numeric) — out of scope; would make output multi-line and harder to grep.
- **Per-channel / per-LUN config** — BB mode is a single-instance config; per-channel reporting is a separate (non-trivial) change.
- **JSON output** — operator-friendly one-line format is sufficient; structured output is overkill for a status query.

## Superpowers iron rules

- **test-coverage** — applies (per M-2: each new public surface needs bug-injection evidence). The new enum value is the only "public surface"; per `add-print-version-flip` design D3 precedent, the "test" is "operator runs the flip and sees the expected string" — no automated test for a 5-line `printf`.
- **systematic-debugging** — N/A (no bug fix; new feature).
- **verification-before-completion** — applies (per M-1: `verify-report.md` + `review.md` mandatory before archive).

## CodeGraph queries used in KNOW phase (per M-4)

- `grep bb_flip` in `bbssd/bb.c` → confirmed 10-case switch in `bb_flip` function (line 26).
- `grep FEMU_*` in `bbssd/ftl.h` → confirmed max enum value = 10 (`FEMU_LOG_VERSION`); new value 11 is safe.
- `grep ssd->sp\.\|n->print_log` → confirmed available flag fields: `ssd->sp.enable_gc_delay`, `ssd->sp.enable_crt`, `ssd->sp.pg_rd_lat` (proxy for delay-emulation), `n->print_log`.
- (CodeGraph MCP `where` / `impact` deferred to design phase — single-file change in `bb.c` with 0 external dependents per prior `add-print-version-flip` impact analysis.)
