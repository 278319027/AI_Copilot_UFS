## ADDED Requirements

### Requirement: Sync Script E2E Test
The system SHALL provide a manual sync fallback script (per AP-009 retro 2026-06-add-bb-config-print) that smart-merges delta spec files into baseline when the OpenSpec CLI sync subcommand is unavailable.

#### Scenario: Operator runs sync with an ADDED delta
- **WHEN** operator runs `bash scripts/sync_change.sh <change-id>` and the change contains a delta file with `## ADDED Requirements`
- **THEN** system merges the new Requirements into `openspec/specs/<cap>/spec.md` and strips the delta header

#### Scenario: Operator runs sync with no delta files
- **WHEN** operator runs `bash scripts/sync_change.sh <change-id>` and the change has no `specs/` directory
- **THEN** system exits 0 with an info message and no baseline mutation
