## 1. Code changes

- [x] 1.1 Add `FEMU_PRINT_NUM_IO = 12,` to `FEMU_*` enum in `bbssd/ftl.h` (append after `FEMU_PRINT_BB_CONFIG = 11,` at line 57)
- [x] 1.2 Add `static void bb_flip_print_num_io(FemuCtrl *n, struct ssd *ssd)` handler in `bbssd/bb.c` (per design D3, after `bb_flip_print_bb_config` at line 124-129)
- [x] 1.3 Add entry `{FEMU_PRINT_NUM_IO, bb_flip_print_num_io, "FEMU_PRINT_NUM_IO"},` to `bb_flip_table[]` in `bbssd/bb.c` (after FEMU_PRINT_BB_CONFIG at line 127)

## 2. Build + behavior verification

- [x] 2.1 From `FEMU_ROOT/build-femu`, force rebuild bb.c.o: `touch -d "2020-01-01" libsystem.a.p/hw_femu_bbssd_bb.c.o && make libsystem.a.p/hw_femu_bbssd_bb.c.o`
- [x] 2.2 Confirm build exit 0, no errors
- [x] 2.3 Run `strings libsystem.a.p/hw_femu_bbssd_bb.c.o | grep "Num tt_late_ios"` and confirm the new string is present
- [x] 2.4 Run `nm libsystem.a.p/hw_femu_bbssd_bb.c.o | grep -E "bb_flip_print_num_io|bb_flip_table"` and confirm `t` (static) + `d` (static const)

## 3. Spec validation

- [x] 3.1 Run `openspec validate --strict --changes` and confirm 1/1 PASS (new ADDED Requirement valid)
- [x] 3.2 Run `openspec validate --strict --specs` and confirm 3/3 PASS (baseline unchanged)

## 4. M-1 verify-report artifact

- [x] 4.1 Write `openspec/changes/add-print-num-io/verify-report.md` per `.opencode/templates/verify-report.md` template

## 5. M-3 review artifact + P2-2 ask user

- [x] 5.1 Write `openspec/changes/add-print-num-io/review.md` with design rationale (per D1-D5)
- [x] 5.2 **Verify verify.sh [19/19] FAILS** (review.md placeholder triggers FAIL per b9c42b5)
- [x] 5.3 **Ask user to sign review.md** (per new `openspec-archive-change/SKILL.md §1.0` hard constraint — AI cannot self-approve per AP-005)
- [x] 5.4 Verify verify.sh [19/19] PASSES after user signature

## 6. Archive

- [x] 6.1 Run `bash scripts/sync_change.sh add-print-num-io` to merge ADDED Requirement to baseline
- [x] 6.2 Verify `verify.sh [18/19] baseline no delta headers` PASS (no delta header in baseline)
- [x] 6.3 Run `bash scripts/verify.sh` and confirm 19/19 PASS
- [x] 6.4 `mv openspec/changes/add-print-num-io/ openspec/changes/archive/$(date +%Y-%m-%d)-add-print-num-io/`
- [x] 6.5 `git add openspec/changes/ openspec/specs/ && git commit -m "chore(spec): archive add-print-num-io"`
- [ ] 6.6 Final `bash scripts/verify.sh` → 19/19 PASS
