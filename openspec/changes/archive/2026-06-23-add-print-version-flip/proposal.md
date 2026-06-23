## Why

FEMU BB mode exposes admin flip commands via `bb_flip` (e.g. `FEMU_ENABLE_GC_DELAY`, `FEMU_RESET_ACCT`). Operators currently have no way to query the running FEMU instance's version, build options, or stat counters from inside the device. This change adds `FEMU_LOG_VERSION` admin flip that prints a one-line version + CRT toggle state. Trivial in scope; the goal is to exercise the full M-1~M-7 methodology end-to-end (per `docs/retrospectives/2026-06-add-crt-mapping-cache.md` M-8 verification).

## What Changes

- Add `FEMU_LOG_VERSION = 10` enum value to `bbssd/ftl.h` flip enum.
- Extend `bb_flip` switch in `bbssd/bb.c` with a case that prints a one-line version string via `femu_log`.
- No new public API surface; the flip is consumed via existing `bb_admin_cmd` dispatch.

## Capabilities

### New Capabilities
- 无

### Modified Capabilities
- `ftl-mapping`: add 1 ADDED Requirement for the version-reporting flip.

## Impact

- **Code**: 2 files modified (`bbssd/ftl.h` enum, `bbssd/bb.c` switch case). ~10 lines total.
- **Spec**: 1 ADDED Requirement in `openspec/specs/ftl-mapping/spec.md`.
- **No new memory rules, no QOM property, no test framework** — the flip is too simple to warrant a unit test; verified manually at QEMU CLI.

## Non-goals

- Full version string with build options / git commit (out of scope; v2).
- Remote fetch of version from a server (out of scope; v3).
- Per-tenant version query (out of scope; FDP-aware flips are a separate change).

## Superpowers iron rules

- **test-coverage** — applies (per M-2: each new public surface needs bug-injection evidence). The new enum value is the only "public surface"; we'll cover it in the verification phase.
- **systematic-debugging** — N/A (no bug fix).
- **verification-before-completion** — applies (per M-1: verify-report.md mandatory).

## CodeGraph queries used in KNOW phase (per M-4)

- `graphify query "bb_flip admin command"` → confirmed `bb.c` is in community 35 (FTL layer).
- `codegraph where bb_flip` → 1 caller (`bb_admin_cmd` at bb.c:100).
- `codegraph context bb_flip` → cognitive 11, cyclomatic 12, no nested dispatch.
- `codegraph impact bbssd/bb.c` → 0 external dependents; safe to modify.
