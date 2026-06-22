---
name: openspec-workflow
description: OpenSpec 概念层与 Iron Rules 入口。5 phase 路由索引（propose/explore/apply/sync-specs/archive-change）。执行具体阶段请加载对应 openspec-{phase}/ skill。
license: MIT
compatibility: Requires openspec CLI (v1.4.1+).
metadata:
  author: openspec
  version: "2.0"
---

# OpenSpec Workflow — 概念层

OpenSpec CLI 管理 `openspec/specs/`（基线）与 `openspec/changes/{id}/`（delta）的 SSD 固件需求/设计/任务。本 skill 是 **5 phase 的概念入口**——不重复各 phase 流程。

## Three Iron Rules

- **Spec changes are the authoritative source of system behavior.** Read `openspec/specs/` before changing documented behavior.
- **Every change passes five gates:** Proposal Gate → Design Gate → BUILD Gate → Review Gate → Archive.
- **Never delete `openspec/changes/` entries.** They form the audit trail.

## 5 Phase 路由表

| Phase | Skill | 触发场景 |
|-------|-------|----------|
| 1. propose | `openspec-propose/` | 创建新变更（`openspec new change` + 生成 4 artifacts） |
| 2. explore | `openspec-explore/` | 思考/调研当前实现（不写应用代码） |
| 3. apply | `openspec-apply/` | 按 `tasks.md` 逐项实施 + 勾选 |
| 4. sync | `openspec-sync-specs/` | delta 合并到 baseline specs |
| 5. archive | `openspec-archive-change/` | 归档 `changes/{id}/` → `archive/YYYY-MM-DD-{id}/` |

5 phase 共享的 OpenSpec 概念（Delta 三类 header、4-gate 门禁、kebab-case 命名、workspace guard）**只在本 skill 定义一次**，各 phase skill 通过 `references/` 复用。

## 跨切约束（适用所有 phase）

- **Parse paths from JSON.** Do not assume repo-local paths. Use `planningHome` / `changeRoot` / `artifactPaths` / `actionContext` from `openspec status --change --json`.
- **Workspace guard.** `actionContext.mode == "workspace-planning"` 且 `allowedEditRoots` 空 → 停下让用户选作用域。
- **Names.** Use kebab-case change names（`add-user-auth` 风格）。
- **Sync smartly.** Deltas express intent, not full replacement. ADDED 增 / MODIFIED 替换同名 Requirement / REMOVED 删 / RENAMED 用 `FROM:` `TO:`。保留未提及 baseline 内容。
- **Audit trail.** Keep `openspec/changes/` entries. Archive commit 格式：`chore(spec): archive {change-id}`.
- **Domain details.** Delta 格式 / directory layout / proposal-design-tasks-review 规则 / gate checklists / 简化豁免规则见 `../sd-firmware-copilot/SKILL.md`。

## CLI Cheatsheet（5 phase 共享）

```bash
openspec list --json                         # 活跃变更
openspec status --change "<name>" --json     # artifact paths + action context
openspec validate --strict --specs           # baseline 校验
openspec validate --strict --changes         # 活跃变更校验
openspec show <capability>                   # baseline spec 内容
```
