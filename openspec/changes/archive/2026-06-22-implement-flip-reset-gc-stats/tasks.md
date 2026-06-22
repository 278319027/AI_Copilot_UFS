# Tasks — implement-flip-reset-gc-stats

## 1. Data Structure

- [x] 1.1 Add `FEMU_RESET_GC_STATS = 8` enum value in `bbssd/ftl.h` after `FEMU_DISABLE_LOG` (line 49). Verify: `grep -n FEMU_RESET_GC_STATS bbssd/ftl.h` shows the new value.
- [x] 1.2 Add `int64_t nr_gc_cycles` and `int64_t nr_gc_data_moves` fields to `FemuCtrl` struct in `nvme.h` (after `nr_tt_late_ios` at line 1729). Verify: `grep -n "nr_gc_cycles\|nr_gc_data_moves" nvme.h` shows two new lines.

## 2. Reset Operation (FEMU_RESET_GC_STATS)

- [x] 2.1 Add `case FEMU_RESET_GC_STATS:` branch in `bb_flip()` switch in `bbssd/bb.c` (after `case FEMU_DISABLE_LOG:` at line 64, before `default:` at line 68). Branch body: assign 0 to both `n->nr_gc_cycles` and `n->nr_gc_data_moves`; emit a `femu_log` line confirming the reset (mirror the `FEMU_RESET_ACCT` log format at line 57-58). Verify: `grep -A5 "FEMU_RESET_GC_STATS" bbssd/bb.c` shows the new case with both field resets.

## 3. GC Counter Increments

- [x] 3.1 In `do_gc()` in `bbssd/ftl.c` (line 844-888), add one line before the `return 0;` at line 887 to increment `ssd->n->nr_gc_cycles` by 1. Verify: `grep -B1 -A2 "return 0;" bbssd/ftl.c | head -20` shows the increment in `do_gc()` (and not in other return-0 functions where it's not wanted).
- [x] 3.2 In `do_gc_fdp_style()` in `bbssd/ftl.c` (line 1755-1902), add one line before the `return 0;` at line 1901 to increment `ssd->n->nr_gc_data_moves` by `vpc_cnt`. Verify: `grep -B1 "return 0;" bbssd/ftl.c` shows the `nr_gc_data_moves += vpc_cnt` line in the FDP-style function.

## 4. Verification

- [x] 4.1 Run `make -j$(nproc)` from FEMU root and capture output. Verify: zero new warnings (`-Werror` is enforced in FEMU build), zero errors. Save full log to `review.md`.
- [x] 4.2 Confirm `openspec validate --strict --specs` passes from `zsf` root. Save exit code + output excerpt to `review.md`.
- [x] 4.3 Confirm `openspec validate --strict --changes` passes for this change. Save exit code to `review.md`.

## 5. Inject Validation (Test Validity Check)

- [x] 5.1 Inject validation for `bb_flip()` reset path: temporarily comment out the `n->nr_gc_cycles = 0;` line in the new case, manually increment the counter via debugger or test harness, run FEMU with a FEMU_FLIP cdw10=8 host command, confirm counter does NOT go to zero. Restore the line. Document the inject validation result in `review.md`.
- [x] 5.2 Inject validation for `do_gc()` counter increment: temporarily comment out the increment, run a synthetic GC cycle (or rely on natural GC during a workload run), confirm `nr_gc_cycles` does NOT increment. Restore the line. Document in `review.md`.
- [x] 5.3 Inject validation for `do_gc_fdp_style()` counter increment: same pattern as 5.2 but for `nr_gc_data_moves`. Document in `review.md`.
