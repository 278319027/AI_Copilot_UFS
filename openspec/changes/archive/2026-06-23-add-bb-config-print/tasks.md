## 1. Code changes

- [x] 1.1 Add `FEMU_PRINT_BB_CONFIG = 11` to the `FEMU_*` enum in `bbssd/ftl.h` (append after `FEMU_LOG_VERSION = 10` at line 55)
- [x] 1.2 Add `case FEMU_PRINT_BB_CONFIG:` in `bb_flip` switch in `bbssd/bb.c` (append after `case FEMU_LOG_VERSION:` block at line 77-80), printing the 4-flag config line per design D2

## 2. Build verification

- [x] 2.1 From `$FEMU_ROOT`, run `make -j$(nproc) 2>&1 | grep -E "error:|bbssd/bb.c"` and confirm 0 errors and that `bbssd/bb.c` is among the rebuilt files
- [x] 2.2 Visually inspect the diff: `git -C $FEMU_ROOT diff hw/femu/bbssd/ftl.h hw/femu/bbssd/bb.c` and confirm it matches design D1 + D2 + D3

## 3. Spec validation

- [x] 3.1 From AI_Copilot_UFS repo root, run `openspec validate --strict --changes` and confirm 0 violations for `add-bb-config-print`
- [x] 3.2 Run `openspec validate --strict --specs` and confirm baseline still valid (3/3 passed)

## 4. M-1 verify-report artifact

- [x] 4.1 Write `openspec/changes/add-bb-config-print/verify-report.md` per `.opencode/templates/verify-report.md` template, populating all 6 check items from `AGENTS.md §OpenSpec Changes` verify table (tasks.md / compile / test / spec / CodeGraph / graphify)

## 5. M-3 review artifact (per `openspec-archive-change` SKILL §1.5)

- [x] 5.1 Write `openspec/changes/add-bb-config-print/review.md` with human review signature (AI cannot self-approve per AP-005)

## 6. Archive preparation

- [x] 6.1 Re-run `bash scripts/verify.sh` from AI_Copilot_UFS root and confirm 17/17 still passes
- [x] 6.2 Confirm all checkboxes above are `- [x]` and `applyRequires` is satisfied, then run `/opsx:archive add-bb-config-print`
