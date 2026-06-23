## 1. Code refactor — extract handlers

- [x] 1.1 Add `struct bb_flip_table_entry` definition at top of `bb.c` (after includes): `{ int64_t cmd; void (*handler)(FemuCtrl *, struct ssd *); const char *name; }`
- [x] 1.2 Extract `case FEMU_ENABLE_GC_DELAY` to `static void bb_flip_enable_gc_delay(FemuCtrl *n, struct ssd *ssd)`
- [x] 1.3 Extract `case FEMU_DISABLE_GC_DELAY` to `static void bb_flip_disable_gc_delay(FemuCtrl *n, struct ssd *ssd)`
- [x] 1.4 Extract `case FEMU_ENABLE_DELAY_EMU` to `static void bb_flip_enable_delay_emu(FemuCtrl *n, struct ssd *ssd)`
- [x] 1.5 Extract `case FEMU_DISABLE_DELAY_EMU` to `static void bb_flip_disable_delay_emu(FemuCtrl *n, struct ssd *ssd)`
- [x] 1.6 Extract `case FEMU_RESET_ACCT` to `static void bb_flip_reset_acct(FemuCtrl *n, struct ssd *ssd)`
- [x] 1.7 Extract `case FEMU_ENABLE_LOG` to `static void bb_flip_enable_log(FemuCtrl *n, struct ssd *ssd)`
- [x] 1.8 Extract `case FEMU_DISABLE_LOG` to `static void bb_flip_disable_log(FemuCtrl *n, struct ssd *ssd)`
- [x] 1.9 Extract `case FEMU_RESET_CRT_STATS` to `static void bb_flip_reset_crt_stats(FemuCtrl *n, struct ssd *ssd)`
- [x] 1.10 Extract `case FEMU_PRINT_CRT_STATS` to `static void bb_flip_print_crt_stats(FemuCtrl *n, struct ssd *ssd)`
- [x] 1.11 Extract `case FEMU_LOG_VERSION` to `static void bb_flip_log_version(FemuCtrl *n, struct ssd *ssd)`
- [x] 1.12 Extract `case FEMU_PRINT_BB_CONFIG` to `static void bb_flip_print_bb_config(FemuCtrl *n, struct ssd *ssd)`

## 2. Code refactor — build table + dispatch

- [x] 2.1 Add `static const struct bb_flip_table_entry bb_flip_table[]` array with 11 entries (per handlers 1.2-1.12)
- [x] 2.2 Replace `switch` in `bb_flip` with `for` loop over `bb_flip_table[]`, calling matched handler
- [x] 2.3 Preserve default case (`printf("FEMU:%s,Not implemented flip cmd (%lu)\n", n->devname, cdw10);`) as fallback after loop
- [x] 2.4 Add `ARRAY_SIZE` macro definition (local, fallback if not in headers)

## 3. Build + behavior verification

- [x] 3.1 From `FEMU_ROOT/build-femu`, force rebuild bb.c.o: `touch -d "2020-01-01" libsystem.a.p/hw_femu_bbssd_bb.c.o && make libsystem.a.p/hw_femu_bbssd_bb.c.o`
- [x] 3.2 Confirm build exit 0, no errors
- [x] 3.3 Run `strings libsystem.a.p/hw_femu_bbssd_bb.c.o | grep "FEMU,"` and verify **12 distinct strings present** (11 case + 1 default + 1 prior "FEMU BB mode" overlap; total ~12 unique)
- [x] 3.4 Run `nm libsystem.a.p/hw_femu_bbssd_bb.c.o | grep bb_flip` and confirm only `bb_flip` (lowercase `t` = static) + new handlers (also `t` = static); no global `bb_flip_table`
- [x] 3.5 Visually inspect `git diff bbssd/bb.c` to confirm 11 handler functions + 1 table + for-loop dispatch

## 4. Spec validation

- [x] 4.1 Run `openspec validate --strict --changes` and confirm 1/1 PASS (new ADDED Requirement about dispatch architecture is valid)
- [x] 4.2 Run `openspec validate --strict --specs` and confirm 3/3 PASS (baseline unchanged, refactor has no baseline delta)

## 5. M-1 verify-report artifact

- [x] 5.1 Write `openspec/changes/refactor-bb-flip-table/verify-report.md` per `.opencode/templates/verify-report.md` template, populating all 6 check items

## 6. M-3 review artifact (per P2-2 ask-user flow)

- [x] 6.1 Write `openspec/changes/refactor-bb-flip-table/review.md` with design rationale (per D1-D7)
- [x] 6.2 **Ask user to sign review.md** (per new `openspec-archive-change/SKILL.md §1.0` hard constraint — AI cannot self-approve per AP-005)
- [x] 6.3 Verify review.md has real signature (not placeholder) before archive

## 7. Archive

- [ ] 7.1 Run `bash scripts/sync_change.sh refactor-bb-flip-table` to merge ADDED Requirement to baseline
- [ ] 7.2 Run `bash scripts/verify.sh` and confirm 19/19 still PASS
- [ ] 7.3 `mv openspec/changes/refactor-bb-flip-table/ openspec/changes/archive/$(date +%Y-%m-%d)-refactor-bb-flip-table/`
- [ ] 7.4 `git add openspec/changes/ openspec/specs/ scripts/ && git commit -m "chore(spec): archive refactor-bb-flip-table"`
- [ ] 7.5 Final `bash scripts/verify.sh` → 19/19 PASS
