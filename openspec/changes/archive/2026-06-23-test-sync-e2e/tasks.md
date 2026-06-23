## 1. Setup

- [x] 1.1 Create dummy change `test-sync-e2e` with `openspec new change`
- [x] 1.2 Build delta spec at `specs/ftl-mapping/spec.md` with `## ADDED Requirements` (1 Requirement + 2 Scenarios)

## 2. Run sync

- [x] 2.1 Run `bash scripts/sync_change.sh test-sync-e2e` and confirm exit 0
- [x] 2.2 Verify baseline `openspec/specs/ftl-mapping/spec.md` has +1 Requirement
- [x] 2.3 Verify no `## ADDED Requirements` header in baseline
- [x] 2.4 Run `openspec validate --strict --specs` and confirm 3/3 PASS

## 3. Archive

- [x] 3.1 Move `openspec/changes/test-sync-e2e/` to `openspec/changes/archive/2026-06-23-test-sync-e2e/`
- [x] 3.2 `git add` + `git commit -m "chore(spec): archive test-sync-e2e"`
- [x] 3.3 `bash scripts/verify.sh` → 18/18 still PASS
