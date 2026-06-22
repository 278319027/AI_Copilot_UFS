## Why

`openspec/specs/nvme-commands/spec.md` already documents `NVME_ADM_CMD_FEMU_FLIP` with 8 operations, including `FEMU_RESET_GC_STATS` (cdw10=8) that resets `nr_gc_cycles` and `nr_gc_data_moves` counters, and increment rules for `do_gc()` and `do_gc_fdp_style()`. The code is missing the implementation: the FEMU_FLIP enum stops at 7 (`FEMU_DISABLE_LOG`), the corresponding case in `bb_flip()` falls into `default:`, and neither `nr_gc_cycles` nor `nr_gc_data_moves` fields exist in the `FemuCtrl` struct. The spec is ahead of the code — this change closes the gap.

## What Changes

- Add `FEMU_RESET_GC_STATS = 8` enum value in `bbssd/ftl.h`.
- Add `int64_t nr_gc_cycles` and `int64_t nr_gc_data_moves` fields to `FemuCtrl` in `nvme.h`.
- Add `FEMU_RESET_GC_STATS` case in `bb_flip()` (`bbssd/bb.c`) that zeroes both counters and logs the reset.
- Increment `nr_gc_cycles` on successful `do_gc()` completion (`bbssd/ftl.c`).
- Increment `nr_gc_data_moves` by `vpc_cnt` on successful `do_gc_fdp_style()` completion (`bbssd/ftl.c`).
- Add a `FemuCtrl`-level getter (or log statement) so operators can observe counter values after GC activity.

## Non-goals

- No changes to GC algorithm or victim-line selection logic.
- No new admin commands beyond completing the spec's documented `FEMU_RESET_GC_STATS`.
- No backwards-incompatible changes to existing FEMU_FLIP opcodes (1-7).
- No multi-controller counter aggregation (each `FemuCtrl` tracks its own).

## Capabilities

### New Capabilities

_None._

### Modified Capabilities

- `nvme-commands`: The `FEMU FLIP Admin Command Dispatch` requirement is moving from "spec-only promise" to "fully implemented." Operation 8 (`FEMU_RESET_GC_STATS`) is added to the implementation; counter increment rules for `do_gc()` and `do_gc_fdp_style()` are added to satisfy the existing scenarios.

## Impact

- **Code touched** (FEMU):
  - `hw/femu/bbssd/ftl.h` — add `FEMU_RESET_GC_STATS` enum value (~1 line)
  - `hw/femu/nvme.h` — add 2 fields to `FemuCtrl` (~2 lines)
  - `hw/femu/bbssd/bb.c` — add 1 case in `bb_flip()` switch (~6 lines)
  - `hw/femu/bbssd/ftl.c` — add 2 counter increment lines + variable plumbing (~4 lines)
- **CodeGraph queries needed**:
  - `codegraph context bb_flip` — confirm the current `bb_flip` body and where to add the new case
  - `codegraph context do_gc` and `codegraph context do_gc_fdp_style` — confirm exit points
  - `codegraph symbol_search nr_tt_ios` — to find the FemuCtrl struct pattern for the new fields
- **Tests**: This is Path B (hardware-dependent — register access through QEMU device model). Compile-clean via `make` is the BUILD verification; inject validation done in mock by simulating a manual counter increment and confirming the reset zeros them.
- **Build target**: FEMU's QEMU build (cross-compiled), no embedded firmware target.
- **Spec delta**: `specs/nvme-commands/spec.md` MODIFIED requirement `FEMU FLIP Admin Command Dispatch` — operation 8's status changes from "spec-defined but unimplemented" to "spec-defined and implemented."

## Superpowers iron rules applying

- **test-coverage** — every new branch in `bb_flip()` and the new counter increment lines must have test coverage. Path B (hardware-dependent): no host unit test possible; verification via compile + targeted inject validation in review.md.
- **systematic-debugging** — N/A (no bug, this is a missing feature).
- **verification-before-completion** — every task must produce a fresh `make` log showing zero new warnings.
