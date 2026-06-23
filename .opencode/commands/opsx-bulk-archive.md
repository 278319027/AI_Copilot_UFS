---
name: opsx:bulk-archive
description: Stage 5b of OpenSpec 5-phase lifecycle — archive multiple completed changes in one batch. Use when several stale changes have piled up and all have passed Review + verify. Loads openspec-archive-change skill.
---

# /opsx:bulk-archive

批量归档多个**已完成且通过 Review + `/opsx:verify`** 的变更。一次会话处理多个 change，避免逐个 `/opsx:archive`。

**用法**：`/opsx:bulk-archive [change-name-1] [change-name-2] ...`

- 无参数：扫描所有 `openspec/changes/`（不含 `archive/`）中满足归档条件的变更
- 显式列表：归档指定 change（即使不满足条件也强制——**危险**，慎用）

**入口操作**：
1. `skill(name="superpowers-using-superpowers")` — 加载纪律约束
2. `skill(name="openspec-archive-change")` — 加载归档 skill
3. `skill(name="superpowers-verification-before-completion")` — 强制每个 change 都跑 verify
4. 按 skill 指引：扫描 → 过滤 → 逐个归档 → 单一 commit

**完整流程**：
1. `openspec list --json` 扫描活跃变更
2. 对每个 change 跑 6 项归档条件检查（见下表）——任何不满足的默认**跳过**并报告
3. 列出"将归档的 change"清单给用户确认
4. 逐个 change 跑 `/opsx:archive` 流程（含 `/opsx:sync`）：
   - `openspec status --change "<name>" --json` 校验完成度
   - `mv openspec/changes/<id>/ openspec/changes/archive/$(date +%Y-%m-%d)-<id>/`
   - 保留 `.openspec.yaml` 在移动后目录内
5. 单一 commit：`chore(spec): bulk-archive <id1>,<id2>,<id3>`
6. `openspec validate --strict --specs` 最终校验

**6 项归档条件**（每个 change 必须满足）：

| # | 条件 | 验证方法 |
|---|------|----------|
| 1 | `tasks.md` 所有任务 `- [x]` | `grep -c '^\- \[ \]' openspec/changes/<id>/tasks.md` 返回 0 |
| 2 | 所有 artifact 完整 | `openspec status --change "<id>" --json` `applyRequires` 全部 `done` |
| 3 | `review.md` 存在且有人类审阅签字 | `ls openspec/changes/<id>/review.md` |
| 4 | `/opsx:verify` 通过 | 已生成 `verify-report.md` 且 6 项全过 |
| 5 | Delta 已合并到 baseline | `openspec show <affected-capability>` 反映 ADDED/MODIFIED/REMOVED |
| 6 | 无未解决冲突 | `openspec validate --strict --changes` 无 violation |

**关键约束**：
- 默认**跳过**不满足条件的 change（不强制归档）
- 显式列表参数时**强制归档**——仅在用户明确同意下使用
- 批量 commit 格式固定：`chore(spec): bulk-archive <id1>,<id2>,<id3>`（逗号分隔，不超过 5 个 / commit；超出则分批）
- 与单 change `/opsx:archive` 的差异：bulk 用**单一 commit**，single 用**单 change commit**

**与单 change `/opsx:archive` 的差异**：

| 命令 | 处理对象 | Commit 数量 | 适用场景 |
|------|----------|------------|----------|
| `/opsx:archive` | 1 个 change | 1 commit / change | 正常流程，1-2 个变更 |
| `/opsx:bulk-archive` | N 个 change | 1 commit / batch | 清理积压的已完成变更 |

**校验命令**：
```bash
openspec list --json
openspec validate --strict --changes
openspec validate --strict --specs
```
