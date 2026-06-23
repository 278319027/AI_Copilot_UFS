# Refactor crt_insert Helpers (Extract Slot Finding + Eviction)

## Why

`crt_insert()` in `bbssd/crt.c` is 46 lines (lines 90-135) and mixes two distinct responsibilities: empty-slot probing (linear scan with wrap-around modulo) and oldest-entry eviction (linear scan over `insert_seq`). The mixed structure makes the function hard to read, and the eviction logic — which contains its own warn-counter modulo and `fprintf` side effect — is the most complex sub-block. Extracting both sub-logics into named static helpers improves readability, makes each helper individually testable, and sets a pattern for future CRT maintainers.

This is a **pure refactor**: zero behavior change. All 3 callers of `crt_insert()` (FTL write path, GC move path, FDP hint path) MUST see identical eviction counter increments, identical slot selection, and identical warn messages.

## What Changes

- **Extract** `crt_find_empty_slot()` from `crt_insert()` (currently lines 102-109, 8 lines): linear probe starting at hash `h`, returning the first slot where `entries[i].valid == false`, or `(uint32_t)-1` if all slots are valid.
- **Extract** `crt_evict_oldest()` from `crt_insert()` (currently lines 111-127, 17 lines): find entry with smallest `insert_seq`, increment `stat_evict`, and emit the `evict_warn_modulo` warning `fprintf` to stderr.
- **Add** forward declarations for both helpers near the top of `crt.c` (after the existing `crt_hash` declaration).
- **Refactor** `crt_insert()` to call the two helpers; body shrinks from 46 → ~22 lines.
- **No** header (`crt.h`) changes — both helpers are `static`, file-local.
- **No** behavior change: identical slot selection, identical eviction counter increments, identical warn messages.

## Capabilities

### New Capabilities

None. Per `openspec-propose §1b` (AP-010 workaround), refactor changes do not introduce new capabilities; they add an `## ADDED Requirements` block to an existing capability documenting the new architecture.

### Modified Capabilities

Empty. Per `openspec-propose §1b`, refactor changes have **no** behavior-level requirement changes, so no existing capability's REQUIREMENTS change. The architecture documentation is added via `## ADDED Requirements` to the relevant capability below.

## Impact

- **Code**:
  - `bbssd/crt.c` (only file modified): add 2 forward declarations + 2 helper definitions + replace 2 inline blocks in `crt_insert` with 2 calls. Net change: +~30 lines (helpers + declarations), -25 lines (inline blocks), ~+5 net LOC.
- **APIs**: none (both helpers are `static`, not in `crt.h`).
- **External callers**: none. `crt_insert` has 3 in-tree callers in `ftl.c` (write / GC / FDP paths) — none see ABI change.
- **Build**: `make` must remain green; `__attribute__((noinline))` is **not** needed (helpers are file-local, compiler will inline naturally; preserving inlining profile is the goal).
- **Tests**: blackbox test only — same FEMU `FEMU_PRINT_CRT_STATS` flip as prior drills, used to verify `crt_insert` behavior unchanged.
- **Superpowers iron rules**:
  - `verification-before-completion`: compile + `FEMU_PRINT_CRT_STATS` flip test (M-1 verify-report.md).
  - `test-driven-development`: existing blackbox coverage applies; new helpers are static and exercised by every `crt_insert` call path.
  - `systematic-debugging`: not applicable (no bug).
- **CodeGraph MCP**: skip (CodeGraph DB not present in workspace; static `grep -nE "crt_insert\(" /home/zsf/AI_Proj/femu/hw/femu/` is sufficient for in-tree caller scan).
- **Spec baseline**: `openspec/specs/ftl-mapping/spec.md` gets 1 new `## ADDED Requirements` block (per §1b workaround) + 1 `#### Scenario: behavior identical`.
- **Graphify**: not applicable (refactor of 1 file, no architecture graph change).
