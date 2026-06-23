## Context

This is an e2e test for `scripts/sync_change.sh` (P0-1 fix for AP-009). The test:
1. Creates a dummy change with a delta spec containing `## ADDED Requirements`
2. Runs `bash scripts/sync_change.sh test-sync-e2e`
3. Verifies the requirement was merged into baseline, no delta header left, validation passes

## Goals / Non-Goals

**Goals:**
- Prove `sync_change.sh` works end-to-end (smart-merge + strip delta header + validate).
- Generate archive evidence (proposal/design/tasks/specs) for the test.

**Non-Goals:** Real feature change; this is a tooling test.

## Decisions

### D1. Reuse `ftl-mapping` capability
- **Choice**: Add the test requirement to existing `ftl-mapping` capability.
- **Rationale**: Avoid creating a new capability for a test; reuse existing baseline structure.

### D2. Minimal artifacts
- **Choice**: 1 Requirement + 2 Scenarios in the delta spec.
- **Rationale**: Sufficient to exercise the sync logic without bloating test data.

## Risks / Trade-offs

- **R1: test-sync-e2e in archive might be mistaken for a real feature** → Mitigation: proposal.md clearly labels it as "E2E test" in Why + Non-goals.
- **R2: baseline will have an orphan requirement after this archive** → Accepted (test artifact; users can read proposal.md to understand it's a test).

## Verification commands (per M-1)

```bash
# 1. Sync runs without error
bash scripts/sync_change.sh test-sync-e2e

# 2. Baseline has new requirement
grep -c "^### Requirement" openspec/specs/ftl-mapping/spec.md  # expect +1

# 3. No delta header in baseline
grep -cE "^## ADDED Requirements" openspec/specs/ftl-mapping/spec.md  # expect 0

# 4. Validation passes
openspec validate --strict --specs
```

## Verification result (2026-06-23)

- Pre-sync: 17 requirements in baseline
- Post-sync: 18 requirements in baseline (added "Sync Script E2E Test")
- `openspec validate --strict --specs` → 3/3 PASS
- Delta header in baseline: 0
- `verify.sh [18/18] baseline specs no delta headers` → PASS
