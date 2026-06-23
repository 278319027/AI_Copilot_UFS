---
name: opsx:new
description: Stage 1a of OpenSpec 5-phase lifecycle — scaffold only (create empty change folder structure). Does NOT generate artifacts. For users who want to fill in artifacts manually or one at a time. Cf. opsx:propose and opsx:ff.
---

# /opsx:new

仅创建 OpenSpec 变更的**空骨架**（不生成任何 artifact 内容）。适用于"我知道要做什么但要自己填"或"先建空壳再用 `/opsx:continue` 逐步生成"的场景。

**用法**：`/opsx:new <change-name>`

- `<change-name>`：kebab-case 名称（必填，动词开头：`add-` / `update-` / `refactor-` / `fix-`）

**与 `/opsx:propose` 的差异**：

| 命令 | 行为 | 适用场景 |
|------|------|----------|
| `/opsx:new` | 仅建空骨架 | 想自己填 / 增量式生成（`/opsx:continue`） |
| `/opsx:propose` | 建骨架 + 生成全部 4 artifacts | 苏格拉底式访谈 + 一次性生成 |
| `/opsx:ff` | 建骨架 + 快速生成所有 artifacts | 已知方案，跳过访谈 |

**入口操作**：
1. `skill(name="superpowers-using-superpowers")` — 加载纪律约束
2. `skill(name="openspec-workflow")` — 加载概念层
3. 按 skill 指引：校验 change-id 唯一性 → 建空骨架 → 让用户决定下一步

**完整流程**：
1. 校验 change-id 不与 `openspec/changes/` 和 `openspec/changes/archive/` 冲突
2. `openspec new change "<change-name>"` 建空骨架（`.openspec.yaml` + `specs/<cap>/spec.md` 模板）
3. 输出后续可选命令：
   - `/opsx:continue` — 按依赖图生成下一个 artifact
   - `/opsx:ff` — 一次性生成所有 artifacts
   - 手动编辑 — 直接写 `proposal.md` 等

**校验命令**：
```bash
openspec list --json | jq '.[] | select(.name == "<change-name>")'  # 确认创建成功
ls openspec/changes/<change-name>/                                    # 确认目录结构
```

**关键约束**：
- 绝不删除 `openspec/changes/` 任何条目（审计追踪）
- 与 `/opsx:propose` 互斥：若已 `/opsx:propose` 创建完整内容，再用 `/opsx:new` 是重复操作
