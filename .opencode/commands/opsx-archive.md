---
name: opsx:archive
description: Stage 5 of OpenSpec 5-phase lifecycle — finalize change by moving changes/{id}/ to changes/archive/YYYY-MM-DD-{id}/. Loads openspec-archive-change skill.
---

# /opsx:archive

归档 OpenSpec 变更到 `archive/YYYY-MM-DD-{id}/`。

**用法**：`/opsx:archive [change-name]`

- 无参数：取唯一活跃变更
- `[change-name]`：指定变更

**入口操作**：
1. `skill(name="openspec-archive-change")` — 加载 archive skill
2. `skill(name="superpowers-finishing-a-development-branch")` — 加载收尾 skill
3. 按 skill 指引执行：检查完成度 → 同步基线 → 归档 → 提交

**完整流程**：
1. `openspec status --change "<name>" --json` 检查 artifact 完成 + 任务勾选
2. 评估 delta：先 `/opsx:sync` 或 archive-without-sync（用户决定）
3. `mv openspec/changes/<id>/ openspec/changes/archive/$(date +%Y-%m-%d)-<id>/`
4. 保留 `.openspec.yaml` 在移动后目录内
5. `git add openspec/changes/ && git commit -m "chore(spec): archive <id>"`

**commit 格式固定**：`chore(spec): archive {change-id}`

**关键约束**：
- 不自动 archive（用户决策）
- 永远 `mv`，不 `rm -rf`
- 警告不完整项让用户确认
- Workspace planning 模式下跳过

**校验命令**：
```bash
bash scripts/check_change.sh <change-name>
openspec validate --strict --specs
```
