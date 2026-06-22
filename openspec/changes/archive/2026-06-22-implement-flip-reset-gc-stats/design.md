## Context

The spec `openspec/specs/nvme-commands/spec.md` documents a `FEMU FLIP Admin Command Dispatch` requirement that defines 8 operations. The current code implements only operations 1-7. Operation 8 (`FEMU_RESET_GC_STATS`) is documented in the spec but unimplemented in `bbssd/bb.c::bb_flip()`. The spec also documents counter increment rules for `do_gc()` and `do_gc_fdp_style()` that are unimplemented because the counters themselves (`nr_gc_cycles`, `nr_gc_data_moves`) do not exist on `FemuCtrl`.

This change closes the gap so that the spec and code are aligned. After this change, an operator can issue `NVME_ADM_CMD_FEMU_FLIP` with cdw10=8 to reset the two GC counters, and the counters will accumulate during normal GC activity.

### CodeGraph impact analysis

- **`bb_flip` (bbssd/bb.c:26-71)**: 1 callers (`bb_admin_cmd`, line 94). Cognitive complexity 8, cyclomatic 9. Adding one `case` to the switch keeps complexity manageable (< 11). The current `default:` branch will keep handling truly unknown opcodes.
- **`do_gc` (bbssd/ftl.c:844)**: Returns 0 on success, -1 on no victim line. Single exit point at line 887. Adding one line before `return 0` to increment `nr_gc_cycles` is the natural insertion point.
- **`do_gc_fdp_style` (bbssd/ftl.c:1755)**: Returns 0 on success. Has access to `vpc_cnt` (valid page count). Adding one line before `return 0` to increment `nr_gc_data_moves` by `vpc_cnt` is the natural insertion point.
- **`FemuCtrl` (nvme.h:1728-1729)**: Already has `int64_t nr_tt_ios` and `int64_t nr_tt_late_ios` — same pattern. Adding two more `int64_t` fields after these is consistent.
- **`FemuCtrl` lifecycle**: `g_malloc0` allocates the struct, so new fields are zero-initialized for free. No init function change needed.
- **cscope supplement**: macro usage `le64_to_cpu` (byte-swap helper) — confirmed to be in scope, no new macro introduction.

### HAL/abstraction analysis

The new counters live in `FemuCtrl` (QEMU device state), accessed by `bb_flip` (NVMe admin handler) and `ftl.c::do_gc` (FTL internal). Both are in the same compilation unit boundary. No cross-layer violation: the FTL layer can directly access `ssd->n->nr_gc_cycles` (already uses `ssd->n->subsys`, `ssd->n->dataplane_started`, etc.). No HAL refactor needed.

## Goals / Non-Goals

**Goals:**

- Make `FEMU_RESET_GC_STATS` (cdw10=8) a fully working operation that zeros the two GC counters.
- Make `nr_gc_cycles` increment on each successful `do_gc()` and `nr_gc_data_moves` increment by `vpc_cnt` on each successful `do_gc_fdp_style()`.
- Keep the change minimal: ~13 lines of new code across 4 files, no refactor of existing logic.
- Provide a log line on reset so operators can confirm the operation took effect.

**Non-Goals:**

- No atomic/thread-safe counter operations (single-threaded GC path in FEMU; existing `nr_tt_ios` follows the same non-atomic pattern).
- No user-facing counter query command (operators can read counters via the existing FEMU debug log).
- No new GC algorithm, no changes to victim selection, no changes to write path.
- No cross-controller counter aggregation.

## Decisions

### Decision 1: Use `int64_t` for new counters, matching existing `nr_tt_ios` / `nr_tt_late_ios`

**Rationale**: Consistency with existing pattern. `int64_t` is large enough (2^63 - 1 = ~9.2 × 10^18) for any practical GC count.

**Alternatives considered**:
- `uint64_t`: rejected — would diverge from existing `int64_t` pattern.
- `uint32_t`: rejected — could overflow in long-running SSDs.
- `atomic_t`: rejected — `do_gc()` runs in the poller thread; not concurrently incremented.

### Decision 2: Counters live on `FemuCtrl`, not `struct ssd`

**Rationale**: Matches the existing `nr_tt_ios` placement. `bb_flip()` already accesses `n->nr_tt_ios` directly. Adding `n->nr_gc_cycles` keeps the reset path in `bb_flip()` natural.

**Alternatives considered**:
- Place on `struct ssd`: rejected — would require `ssd->n->...` indirection in the reset path, and the reset lives in the NVMe layer (which already uses `FemuCtrl`-level state).

### Decision 3: Add counter increments before the `return 0` in `do_gc()` and `do_gc_fdp_style()`

**Rationale**: Single exit point. The spec says counters increment "on successful GC cycle" (return 0), so placing the increment before the success-return is exact.

**Alternatives considered**:
- Increment at call site (e.g., the `do_gc(ssd, true)` in line 944): rejected — `do_gc()` is called from multiple sites; spec says "on each successful `do_gc()` completion", which is naturally the function-internal point.

### Decision 4: Log line on reset

**Rationale**: Operator feedback. Existing reset cases (`FEMU_RESET_ACCT`) log, so this is consistent.

## Risks / Trade-offs

| Risk | Mitigation |
|------|------------|
| Forgetting to wire counter increments in one of the two GC functions → spec still diverges from code. | The tasks.md list includes a dedicated task for each GC function. Review Gate verifies both functions. |
| Adding fields to `FemuCtrl` changes struct size, potentially affecting memory layout assumptions in older binaries. | FEMU is loaded as a QEMU shared object; field addition is fully compatible. `g_malloc0` zero-initializes new fields. No migration needed. |
| Operators who scripted FEMU_FLIP may have assumed only opcodes 1-7 exist. | Existing scripts use only the documented opcodes 1-7. Opcode 8 is a new addition; the `default:` branch already logs "Not implemented" for genuinely unknown opcodes, so behavior for opcodes outside {1..8} is unchanged. |
| Compile error in FTL because `FemuCtrl` not visible in `ftl.c`. | `ftl.c` already accesses `ssd->n` as `FemuCtrl *` (existing pattern for `n->subsys`, `n->dataplane_started`). The `FemuCtrl *` type is fully visible via `#include "../nvme.h"` (already present at the top of `ftl.c`). |

## Migration Plan

This is a development-tree change, not a deployed firmware update. After the change is merged:
- Operators using FEMU in development can immediately use `FEMU_RESET_GC_STATS`.
- No data migration, no schema migration, no version bump.
- The change is backwards-compatible: existing FEMU_FLIP users (opcodes 1-7) are unaffected.

## Open Questions

_None — all decisions are made within this design._
