---
name: openspec-archive-change
description: Stage 5 of OpenSpec 5-phase lifecycle — finalize change by moving changes/{id}/ to changes/archive/YYYY-MM-DD-{id}/. Check artifact completion and task checkboxes first. Use when user says /opsx:archive, "归档", or "提交变更".
license: MIT
compatibility: Requires openspec CLI (v1.4.1+).
metadata:
  author: openspec
  version: "2.0"
  parent: openspec-workflow
---

# OpenSpec Archive Change — Stage 5

完成 OpenSpec 变更的最后一步：把 `openspec/changes/<id>/` 移动到 `openspec/changes/archive/YYYY-MM-DD-{id}/`，触发 Archive Gate。共享概念（Iron Rules、跨切约束）见 `../openspec-workflow/SKILL.md`。

## When to Use

- 用户说 `/opsx:archive [name]` 或 "归档"
- `tasks.md` 全勾选
- 准备合并到主分支并发布

## 关键步骤

### 1. 检查 artifact 完成 + 任务勾选

```bash
openspec status --change "<name>" --json
```

读出：
- `applyRequires` 全部 `done`
- `tasks.md` 中 `- [x]` 数量 ≥ `- [ ]` 数量

### 2. 评估 delta 是否先 sync

判断：
- 若 `openspec/changes/<id>/specs/<capability>/spec.md` 含 `## ADDED` / `## MODIFIED` 等 delta → 提议先 `/opsx:sync`
- 若无 delta（纯 skill/command 重构）→ 可直接 archive

**让用户决定**：
- 选项 A：先 sync 再 archive（保留变更意图在 baseline）
- 选项 B：archive without sync（baseline 不动）

### 3. 移动目录

```bash
TODAY=$(date +%Y-%m-%d)
mv openspec/changes/<id>/ openspec/changes/archive/${TODAY}-<id>/
```

**保留 `.openspec.yaml`** 在移动后的目录内（不要 `-r` 删除隐藏文件）。

### 4. 提交（git）

```bash
git add openspec/changes/
git commit -m "chore(spec): archive <id>"
```

**commit 格式必须**：`chore(spec): archive {change-id}`（与 `superpowers-verification-before-completion` 一致）。

### 5. 验证归档

```bash
openspec list --json
```

- 活跃变更列表中应不再有 `<id>`
- `openspec/changes/archive/YYYY-MM-DD-<id>/` 应存在并含 `proposal.md` / `design.md` / `tasks.md`（如有）+ `.openspec.yaml`

## 关键约束

- **不自动 archive** —— 即便 tasks 全勾选，也必须用户明确决策
- **不删 `openspec/changes/` 条目** —— 永远用 `mv` 到 `archive/`，禁止 `rm -rf`
- **commit 格式固定** —— `chore(spec): archive {change-id}`
- **保留 `.openspec.yaml`** —— OpenSpec 用它反查 artifact schema
- **Workspace guard**：`actionContext.mode == "workspace-planning"` → 跳过

## CLI 调用清单

```bash
openspec list --json                              # 盘点活跃变更
openspec status --change "<name>" --json          # 解析 artifact 状态
openspec validate --strict --specs                # baseline 校验（若 sync 过）
mv openspec/changes/<id>/ openspec/changes/archive/YYYY-MM-DD-<id>/
git add openspec/changes/ && git commit -m "chore(spec): archive <id>"
```

## 错误处理

| 错误 | 应对 |
|------|------|
| 仍有 `- [ ]` 未勾选 | 警告用户，**不归档**。让用户决定：(a) 继续完成 (b) 强制 archive（不推荐） |
| `applyRequires` 含非 done 项 | 警告并阻止 archive |
| delta 存在但未 sync | 提示先 `/opsx:sync` 或让用户显式确认 archive-without-sync |
| 目标目录 `archive/YYYY-MM-DD-<id>/` 已存在（重复 archive） | 改名追加 `-v2` 或检查是否已 archive 过 |
| `actionContext.mode == "workspace-planning"` | 跳过 archive，让用户选作用域 |
