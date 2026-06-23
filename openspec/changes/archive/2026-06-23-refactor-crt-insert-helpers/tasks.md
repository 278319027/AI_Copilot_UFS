# Tasks — Refactor crt_insert Helpers

## T0. Pre-flight (M-5 session start)

- [x] Re-read 5 memory files (`.opencode/memory/{architecture,design_rules,coding_style,concurrency_rules,testing_rules}.md`) — M-5 closure
- [x] `bash scripts/verify.sh` baseline → 22/20 PASS expected
- [x] Re-read 5 openspec-* skills — focus on `openspec-propose §1b` (Refactor type)
- [x] `openspec list --json` → 0 active changes (workspace clean for this drill)

## T1. KNOW — locate the inline blocks

- [x] `grep -nE "^static|crt_hash|insert|lookup" /home/zsf/AI_Proj/femu/hw/femu/bbssd/crt.c` — found `crt_hash` at line 43, `crt_insert` at line 90
- [x] Read `crt_insert` body (lines 90-135) — confirmed two sub-blocks:
  - Slot finding: lines 102-109 (8 lines, linear probe with wrap)
  - Eviction: lines 111-127 (17 lines, scan + counter + warn)
- [x] Read `crt.h` (lines 1-119) — confirmed no surface change needed; both helpers are `static`

## T2. PLAN — create 4 artifacts (this file + proposal + specs + design)

- [x] `openspec new change refactor-crt-insert-helpers` (Stage 1a scaffold)
- [x] Write `proposal.md` (Why + What Changes + empty Modified Capabilities per §1b)
- [x] Write `specs/ftl-mapping/spec.md` (ADDED Requirements + behavior-identical scenario per §1b)
- [x] Write `design.md` (CodeGraph impact + module boundaries + behavior equivalence)
- [x] Write `tasks.md` (this file)
- [ ] `openspec validate --strict --changes` must pass before T3

## T3. BUILD — extract helpers

### T3.1 Add forward declarations

- [ ] Edit `crt.c` after line 50 (after `crt_hash` definition closing brace) to add 2 forward declarations:
  - `static uint32_t crt_find_empty_slot(const struct crt *crt, uint32_t h);`
  - `static uint32_t crt_evict_oldest(struct crt *crt);`

### T3.2 Add helper definitions

- [ ] Add `crt_find_empty_slot()` body in `crt.c` (8 lines, identical to prior inline loop lines 102-109):
  - Loop `for (uint32_t i = 0; i < cap; i++)` with `k = (h + i) % cap`
  - Return `k` on `!entries[k].valid`, else `(uint32_t)-1`
- [ ] Add `crt_evict_oldest()` body in `crt.c` (17 lines, identical to prior inline block lines 111-127):
  - Initialize `oldest_idx = 0; oldest_seq = entries[0].insert_seq`
  - Loop from `i=1` to find smaller `insert_seq`
  - Return `oldest_idx`; increment `stat_evict`; `fprintf` on modulo hit

### T3.3 Refactor `crt_insert()`

- [ ] Replace inline slot-probe loop (lines 102-109) with `uint32_t slot = crt_find_empty_slot(crt, h);`
- [ ] Replace inline eviction block (lines 111-127) with:
  ```c
  if (slot == (uint32_t)-1) {
      slot = crt_evict_oldest(crt);
  }
  ```
- [ ] Keep the trailing write-back (lines 129-134) unchanged

## T4. Verify build (M-1 verification-before-completion)

- [ ] `cd /home/zsf/AI_Proj/femu/hw/femu && make -j$(nproc)` — must exit 0
- [ ] Check `crt.o` compiles (no warnings about `static` functions unused; helpers are used by `crt_insert`)
- [ ] `nm crt.o | grep -E "crt_find_empty_slot|crt_evict_oldest"` — both must appear as `t` (local text symbol)

## T5. Verify spec validity

- [ ] `cd /home/zsf/AI_Proj/AI_Copilot_UFS && openspec validate --strict --changes` — must exit 0
- [ ] `openspec validate --strict --specs` — must still pass (no baseline change yet)

## T6. Verify project hygiene

- [ ] `bash scripts/verify.sh` — must still be 22/20 PASS (no regression in M-2 [20/20] check)
- [ ] `cd /home/zsf/AI_Proj/AI_Copilot_UFS && openspec list --json` — 1 active change `refactor-crt-insert-helpers`

## T7. Write verify-report.md (M-1)

- [ ] Copy template from `.opencode/templates/verify-report.md` (or per `add-toggle-gc-delay` archive)
- [ ] Fill: change-id, build cmd + output, validate output, behavior equivalence table excerpt from design.md D5
- [ ] Mark "Tests run" = N/A (no behavior change; blackbox implicit via identical inline-body extraction)

## T8. Write review.md (per `openspec-archive-change §1.0`)

- [ ] Author: ZSF (per prior drill signature convention)
- [ ] Summary: refactor + helpers + zero behavior change
- [ ] Sign: ✅ APPROVED (after self-review against §1b checklist)
- [ ] Date: 2026-06-23

## T9. Ask user to sign (per §1.0 enforcement)

- [ ] Present review.md to user via `question` tool
- [ ] Wait for APPROVED or APPROVED WITH COMMENTS

## T10. Sync + archive (Stage 4-5)

- [ ] Run `bash scripts/sync_change.sh refactor-crt-insert-helpers` (P0-1 workaround) — verify the ADDED Requirements are appended to `openspec/specs/ftl-mapping/spec.md` (per sync 6 # Delta Header Rule)
- [ ] `openspec validate --strict --specs` — must pass (ADDED Requirements now in baseline)
- [ ] `openspec validate --strict --changes` — must pass (change now empty of pending artifacts)
- [ ] Move `openspec/changes/refactor-crt-insert-helpers/` → `openspec/changes/archive/2026-06-23-refactor-crt-insert-helpers/`
- [ ] `git add` precise files (per AGENTS.md: not `-A`):
  - `openspec/changes/refactor-crt-insert-helpers/` (move target)
  - `openspec/specs/ftl-mapping/spec.md` (sync target)
  - `FEMU_ROOT/hw/femu/bbssd/crt.c` (if committed to FEMU; else leave as untracked note in this drill)
- [ ] `git commit -m "chore(spec): archive refactor-crt-insert-helpers"`
- [ ] `bash scripts/verify.sh` — final 22/20 check

## T11. RETRO (per drill discipline)

- [ ] Write `docs/retrospectives/2026-06-23-refactor-crt-insert-helpers.md`:
  - §1 Context: C-style refactor drill, target = crt_insert helpers
  - §2 What went well: §1b workflow exercised end-to-end (ADDED Requirements + behavior identical)
  - §3 What went wrong: (none expected; capture if any)
  - §4 §1b workaround validation: confirm `## ADDED Requirements` block was sufficient to pass `openspec validate --strict --changes` without modifying existing behavior
  - §5 Action items (if any)

## T12. Final close-out

- [ ] Re-run `bash scripts/verify.sh` (should be 22/20, no regression)
- [ ] Report to user: archive path, commit hash, retro path
