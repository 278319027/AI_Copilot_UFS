---
name: openspec-workflow
description: Full OpenSpec workflow — propose, explore, apply, sync, archive. Covers the complete PLAN and FEEDBACK stages of the four-stage loop (KNOW → PLAN → BUILD → FEEDBACK).
license: MIT
compatibility: Requires openspec CLI (v1.4.1+).
metadata:
  author: openspec
  version: "1.0"
---

# OpenSpec Workflow

OpenSpec CLI manages SSD firmware requirements, design, and tasks under `openspec/specs/` (baseline) and `openspec/changes/{id}/` (deltas). This skill covers the five-stage change lifecycle, corresponding to the **PLAN** (propose/explore/sync) and **FEEDBACK** (archive) phases.

See `../sd-firmware-copilot/SKILL.md` for domain-specific spec rules, delta format details, and gate checklists.

## Three Iron Rules

- **Spec changes are the authoritative source of system behavior.** Read `openspec/specs/` before changing documented behavior.
- **Every change passes four gates:** Proposal Gate → Design Gate → Review Gate → Archive.
- **Never delete `openspec/changes/` entries.** They form the audit trail.

## When to Use This Skill

- User says `/opsx:propose`, `/opsx:explore`, `/opsx:apply`, `/opsx:sync`, or `/opsx:archive`.
- User needs to create, investigate, implement, merge specs, or finalize an OpenSpec change.
- The change is non-trivial enough to benefit from tracked artifacts.

## Five-Stage Workflow

### 1. propose

Create a change and generate all required artifacts (proposal, design, specs, tasks) in dependency order.

Use `openspec new change "<name>"`, then `openspec status --change "<name>" --json` to read `applyRequires`, `artifactPaths`, and `actionContext`. For each ready artifact, run `openspec instructions <artifact-id> --change "<name>" --json` and write to `resolvedOutputPath` following the provided `instruction`/`template`. Re-check status after each artifact until `applyRequires` are `done`. Never copy raw `<context>` / `<rules>` blocks into artifacts. If the name is missing, ask.

### 2. explore

Think with the user. Read files, investigate the codebase, compare options, draw diagrams. **Do not write implementation code.** You may create or update OpenSpec artifacts when the user asks. Start with `openspec list --json`; if a change is active, read its artifacts via `openspec status --change "<name>" --json`. Propose where insights belong, but let the user decide.

### 3. apply

Implement `tasks.md` one task at a time. Run `openspec status --change "<name>" --json`, then `openspec instructions apply --change "<name>" --json` to get `contextFiles` and the task list. Read all context files first. For each pending task, make the minimal change, mark `- [ ]` as `- [x]`, and continue. Stop if a task is unclear, the design seems wrong, or `actionContext.mode == "workspace-planning"` (do not edit linked workspaces without explicit scope selection).

### 4. sync

Merge delta specs from `openspec/changes/{id}/specs/<capability>/spec.md` into `openspec/specs/<capability>/spec.md`. Identify `## ADDED` / `## MODIFIED` / `## REMOVED` / `## RENAMED Requirements` sections. Apply changes intelligently: add only new requirements or scenarios, preserve untouched content, and rename via `FROM:` / `TO:`. Do not programmatically merge; read both delta and baseline, then edit. Skip if `actionContext.mode == "workspace-planning"`.

### 5. archive

Finalize the change by moving `openspec/changes/{id}/` to `openspec/changes/archive/YYYY-MM-DD-{id}/`. Check artifact completion via `openspec status --change "<name>" --json` and task completion by counting `- [x]` vs `- [ ]`. Warn the user about incomplete items, but let them confirm. Evaluate delta specs first: offer to sync before archiving or archive without syncing. Use `mv`; keep `.openspec.yaml` inside the moved directory. Skip if `actionContext.mode == "workspace-planning"`.

## CLI Cheatsheet

| Stage | Command | Key CLI calls |
|-------|---------|---------------|
| propose | `/opsx:propose <name>` | `openspec new change`, `openspec status --change --json`, `openspec instructions <artifact> --change --json` |
| explore | `/opsx:explore` | `openspec list --json`, `openspec status --change --json` |
| apply | `/opsx:apply [name]` | `openspec status --change --json`, `openspec instructions apply --change --json` |
| sync | `/opsx:sync` | `openspec list --json`, `openspec status --change --json` |
| archive | `/opsx:archive [name]` | `openspec list --json`, `openspec status --change --json`, then `mv` to `archive/YYYY-MM-DD-<name>/` |

Also useful:

```bash
openspec list --json                         # active changes
openspec status --change "<name>" --json     # artifact paths + action context
openspec validate --strict --changes         # validate all active changes
openspec show <capability>                   # baseline spec
```

## Cross-Cutting Rules

- **Parse paths from JSON.** Do not assume repo-local paths. Use `planningHome`, `changeRoot`, `artifactPaths`, and `actionContext` from `openspec status`.
- **Workspace guard.** If `actionContext.mode == "workspace-planning"`, stop `apply`/`sync`/`archive` and ask the user to select scope or use repo-local planning.
- **Names.** Use kebab-case change names. Ask when ambiguous; never guess except single active change in `apply` context.
- **Sync smartly.** Deltas express intent, not full replacement. Preserve baseline content not mentioned in the delta.
- **Audit trail.** Keep `openspec/changes/` entries. Archive commit format: `chore(spec): archive {change-id}`.
- **Domain details.** Delta format, directory layout, proposal/design/tasks/review rules, gate checklists, and simplification guidance are in `../sd-firmware-copilot/SKILL.md`.
