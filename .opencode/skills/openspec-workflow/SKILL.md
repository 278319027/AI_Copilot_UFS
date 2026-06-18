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

**关键步骤** (4):
1. 确认输入：kebab-case 名称（`add-user-auth` 风格）
2. `openspec new change "<name>"` 创建目录
3. `openspec status --change "<name>" --json` 解析 `applyRequires`/`artifactPaths`/`actionContext`
4. 对每个 ready artifact：`openspec instructions <id> --change --json` → 写 `resolvedOutputPath`
5. 循环 `status` 直到 `applyRequires` 全 done

**关键约束** (3):
- **不要**复制 `<context>` / `<rules>` / `<project_context>` 到 artifact（仅作约束）
- 严格按 `template` 结构 + `instruction` 字段写
- 每写完一个 artifact 立即验证文件存在

### 2. explore

Think with the user. Read files, investigate the codebase, compare options, draw diagrams. **Do not write implementation code.** You may create or update OpenSpec artifacts when the user asks. Start with `openspec list --json`; if a change is active, read its artifacts via `openspec status --change "<name>" --json`. Propose where insights belong, but let the user decide.

**关键步骤** (3):
1. 开局 `openspec list --json` 了解活跃变更
2. 无活跃变更：自由思考；提议建 proposal 但不强制
3. 有活跃变更：读 `status --change --json` + `artifactPaths.<artifact>.existingOutputPaths`

**关键约束** (3):
- **不实现**——可创建 OpenSpec artifacts，绝不写应用代码
- **不自动归档**——决策明确时提议，用户决定
- **不清就继续挖**——不假装懂

### 3. apply

Implement `tasks.md` one task at a time. Run `openspec status --change "<name>" --json`, then `openspec instructions apply --change "<name>" --json` to get `contextFiles` and the task list. Read all context files first. For each pending task, make the minimal change, mark `- [ ]` as `- [x]`, and continue. Stop if a task is unclear, the design seems wrong, or `actionContext.mode == "workspace-planning"` (do not edit linked workspaces without explicit scope selection).

**关键步骤** (5):
1. 选定变更：`openspec list --json` → 公告 `Using change: <name>`
2. `openspec status --change --json` 解析 `schemaName` / `actionContext`
3. `openspec instructions apply --change --json` 取 `contextFiles` + 任务列表
4. 处理状态分支：`blocked`（缺 artifacts）→ `/opsx:continue-change`；`all_done` → `/opsx:archive`
5. 逐个 pending task：最小改动 → 勾选 `- [x]` → 下一个

**关键约束** (3):
- **实施前必读** `contextFiles`（不只是 `tasks.md`）
- **工作区护栏**：`actionContext.mode == "workspace-planning"` 且 `allowedEditRoots` 空 → **停下**让用户选作用域
- **任务不清 / 暴露 design 问题** → 暂停问，不猜

### 4. sync

Merge delta specs from `openspec/changes/{id}/specs/<capability>/spec.md` into `openspec/specs/<capability>/spec.md`. Identify `## ADDED` / `## MODIFIED` / `## REMOVED` / `## RENAMED Requirements` sections. Apply changes intelligently: add only new requirements or scenarios, preserve untouched content, and rename via `FROM:` / `TO:`. Do not programmatically merge; read both delta and baseline, then edit. Skip if `actionContext.mode == "workspace-planning"`.

**关键步骤** (3):
1. 读 `openspec/changes/{id}/specs/<cap>/spec.md` 找 `## ADDED` / `MODIFIED` / `REMOVED` / `RENAMED` sections
2. 读 baseline `openspec/specs/<cap>/spec.md`
3. 智能合并：只增新 requirement；MODIFIED 替换同名 Requirement；保留未提及内容

**关键约束** (2):
- **不**走纯程序化合并——读两边再编辑
- `actionContext.mode == "workspace-planning"` → 跳过

### 5. archive

Finalize the change by moving `openspec/changes/{id}/` to `openspec/changes/archive/YYYY-MM-DD-{id}/`. Check artifact completion via `openspec status --change "<name>" --json` and task completion by counting `- [x]` vs `- [ ]`. Warn the user about incomplete items, but let them confirm. Evaluate delta specs first: offer to sync before archiving or archive without syncing. Use `mv`; keep `.openspec.yaml` inside the moved directory. Skip if `actionContext.mode == "workspace-planning"`.

**关键步骤** (3):
1. `openspec status --change --json` 检查 artifact 完成 + 任务勾选数
2. 评估 delta：先 `/opsx:sync` 或 archive-without-sync（用户决定）
3. `mv openspec/changes/<id>/ openspec/changes/archive/YYYY-MM-DD-<id>/`（保留 `.openspec.yaml`）

**关键约束** (3):
- 警告不完整项让用户确认（不自动 archive）
- `actionContext.mode == "workspace-planning"` → 跳过
- 归档 commit 格式：`chore(spec): archive {change-id}`

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
