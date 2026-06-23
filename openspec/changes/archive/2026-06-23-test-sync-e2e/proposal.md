## Why

E2E test for `scripts/sync_change.sh` (P0-1 fix for AP-009 from retro 2026-06-add-bb-config-print). This change exercises the manual sync fallback path that was missing — when `openspec sync` CLI is unavailable, operators can use `bash scripts/sync_change.sh <change-id>` to smart-merge delta specs into baseline.

## What Changes

- Add `### Requirement: Sync Script E2E Test` to `openspec/specs/ftl-mapping/spec.md` baseline (proves the merge succeeded).
- No code changes; no new public API; this is a tooling test.

## Capabilities

### New Capabilities
- 无

### Modified Capabilities
- `ftl-mapping`: add 1 ADDED Requirement (`Sync Script E2E Test`) documenting the sync fallback contract.

## Impact

- **Code**: 0 lines of code.
- **Spec**: 1 ADDED Requirement in `openspec/specs/ftl-mapping/spec.md` (this is the proof artifact).
- **Tools**: `scripts/sync_change.sh` exercised end-to-end.

## Non-goals

- Not a real feature change; this is a verification test only.
- Will be archived to `archive/2026-06-23-test-sync-e2e/` after sync.

## Superpowers iron rules

- **test-coverage** — applies (per M-2: the sync script is the "public surface"; verified via the e2e test itself).
- **systematic-debugging** — N/A.
- **verification-before-completion** — applies (per M-1: this e2e test is the verification evidence).
