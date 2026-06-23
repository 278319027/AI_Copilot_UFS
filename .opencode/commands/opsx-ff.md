---
name: opsx:ff
description: Stage 1c of OpenSpec 5-phase lifecycle — fast-forward: create change + generate all 4 artifacts in one step. Skips interview. Use when the change is well-understood. Loads openspec-propose skill.
---

# /opsx:ff

**Fast-Forward**：一次创建变更 + 生成全部 4 个 artifacts（`proposal.md` / `specs/` delta / `design.md` / `tasks.md`）。**跳过苏格拉底访谈**——要求使用者已经清楚要做什么。

**用法**：`/opsx:ff <change-name> [intent-description]`

- `<change-name>`：kebab-case 名称（必填，动词开头）
- `[intent-description]`：1-2 句话的意图（必填——这是 AI 生成 proposal 的输入）

**入口操作**：
1. `skill(name="superpowers-using-superpowers")` — 加载纪律约束
2. `skill(name="openspec-propose")` — 加载 propose skill
3. `openspec list --json` 校验 `<change-name>` 唯一
4. `openspec new change "<name>"` 建骨架
5. `openspec status --change "<name>" --json` 解析 artifact 路径
6. 对每个 artifact 调 `openspec instructions <id> --change --json` → 写 `resolvedOutputPath`
7. 跑 `openspec validate --strict --changes`

**与 `/opsx:propose` 的差异**：

| 命令 | 行为 | 关键差异 |
|------|------|----------|
| `/opsx:propose` | 苏格拉底访谈 + 生成 4 artifacts | 强制问澄清问题 → 适合需求模糊 |
| `/opsx:ff` | 直接生成 4 artifacts | 跳过访谈 → 适合需求明确 |
| `/opsx:new` | 仅建空骨架 | 不生成任何内容 |

**前置条件**（`/opsx:ff` 适用前必须确认）：

- [ ] change 的目标清晰（不是"我想改点东西"而是"我想加 X 功能修复 Y 问题"）
- [ ] 修改的 capability 已明确（`nvme-commands` / `ftl-mapping` / `nand-driver` / 跨切）
- [ ] 设计方向已确定（不需要 AI 探索替代方案）
- [ ] 任务粒度可预估（200-500 行 / task）

如果以上任何一项模糊 → 改用 `/opsx:propose`（触发访谈）或 `/opsx:explore`（先调研）。

**完整流程**：
1. `openspec new change "<name>"` 建空骨架
2. 对 4 个 artifact（proposal / specs / design / tasks）依次：
   - 调 `openspec instructions <id> --change "<name>" --json` 拿模板指引
   - 按模板生成内容（基于 `intent-description` + `.opencode/memory/` + `openspec/specs/`)
   - 写入 `resolvedOutputPath`
3. `openspec validate --strict --changes` 校验
4. 提示用户审阅 → 过 Proposal Gate / Design Gate

**关键约束**：
- intent-description **必填**且 ≥ 1 句话（否则 AI 没输入可生成）
- 生成的 artifacts **不直接进 BUILD**——必须经 Proposal Gate + Design Gate 人工审阅
- 若 validate 失败 → 人工修订，不循环 `/opsx:ff`

**校验命令**：
```bash
openspec validate --strict --changes
bash check_change.sh <change-name>
```
