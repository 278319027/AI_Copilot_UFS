## Context

`superpowers/SKILL.md`（144 行）是 Superpowers 框架的元入口。它声明自己是"lower layer in a two-layer architecture"，与 `sd-firmware-copilot` 的"upper layer"形成两阶段分工。

**当前问题**：
- `superpowers/SKILL.md` 内容丰富（Bootstrap 决策表、Iron Rules、Skill map）但与其他位置存在内容割裂
- `superpowers-using-superpowers/SKILL.md` 讲"如何用 skills"的一般规则（Instruction Priority / Red Flags / Skill Types），与 `superpowers/SKILL.md` 的"何时加载哪个"职责**不重叠**——但容易让读者困惑
- `sd-firmware-copilot/SKILL.md:86` 显式引用 `superpowers/SKILL.md §Bootstrap 决策表`——但 Bootstrap 表实际在另一个文件，跨文件跳转繁琐
- `verify.sh` 现在检查 `superpowers/` 顶层目录存在——增加了 1 个易碎的"目录"依赖

**目标状态**：
- `superpowers/SKILL.md` 删除
- 14 个 `superpowers-*` sub-skill 保留（独立 description 触发，不依赖顶层入口）
- `sd-firmware-copilot/SKILL.md` 追加"Superpowers 框架整合"段，集中展示 Bootstrap 决策表 + Iron Rules + Skill map
- 8+ 处引用全部改向到 `sd-firmware-copilot/SKILL.md`

## Goals / Non-Goals

**Goals**:
- 删除 `superpowers/SKILL.md` 144 行
- 把最有价值的 5 段合并到 `sd-firmware-copilot/SKILL.md`（不超过 80 行追加）
- 更新 8+ 处引用
- `verify.sh` 期望从 21 改为 20 skill dirs
- 跑 `verify.sh` 11/12 通过 + grep 8 处引用全部更新

**Non-Goals**:
- 不修改 14 个 `superpowers-*` sub-skill
- 不修改 OpenSpec skill（1+5 结构）
- 不修改 `superpowers-using-superpowers/SKILL.md`
- 不修改 5 个 baseline spec
- 不修改 `AGENTS.md` / `README.md` 的"项目入口"大段（仅修引用）

## Decisions

### 决策 1：合并到 `sd-firmware-copilot/SKILL.md`（与"sole integrating skill"声明一致）

**选择**：在 `sd-firmware-copilot/SKILL.md` 末尾（"## 初始化" 之前）追加 "## Superpowers 框架整合" 段，含 5 子段：
- `### Iron Rules (4 条)` — 4 Iron Rules 全文
- `### Bootstrap 决策表` — 场景→skill 映射表
- `### 阶段转换触发器` — KNOW/PLAN/BUILD/FEEDBACK 4 阶段
- `### Red-line 自检` — 4 个 yes/no 问题
- `### Skill map 速查` — 14 个 sub-skill 简表

**理由**：
- `sd-firmware-copilot` 文档自称为"sole integrating skill"——但实际上没有真正的 Bootstrap 表
- 追加后，`sd-firmware-copilot` 真正成为全项目唯一入口
- 与 1+5 OpenSpec 拆分哲学一致——只保留有独特价值的"概念层"

**备选**：
- 新建独立的 `superpowers-meta/SKILL.md` 单独承载 → 增加碎片，违背 1+5 哲学（拒绝）
- 把内容分散到 14 个 sub-skill 的 description 中 → 失去"何时加载哪个"的统一视图（拒绝）

### 决策 2：内链锚点用 GitHub 风格 `§Section` 引用

**选择**：所有指向新位置的内链用 `../sd-firmware-copilot/SKILL.md §Bootstrap 决策表` 格式。

**理由**：与 1+5 OpenSpec 拆分时 `openspec-workflow` 引用的格式一致（参见 `openspec-propose/SKILL.md` 中的 `../openspec-workflow/SKILL.md` 引用）。

### 决策 3：verify.sh 期望从 21 改为 20

**选择**：
- 去掉 `[ -d "$PROJECT_ROOT/.opencode/skills/superpowers" ]` 检查
- 总期望：`5 openspec-* + 1 openspec-workflow + 13 superpowers-* + 1 sd-firmware-copilot = 20`

**理由**：删除 superpowers 顶层目录后，14 个 `superpowers-*` 仍存在但无框架入口——结构对称。

### 决策 4：deploy_tools.sh 的引用

**选择**：
- line 14-15 注释改向：`superpowers/SKILL.md` → `sd-firmware-copilot/SKILL.md §Superpowers 框架整合`
- line 309-315 目录检查改为检查 `superpowers-*/` 数量（实际已检查的是 14 个 sub-skill）
- line 336 + 362 其他引用同样改向

**理由**：deploy_tools.sh 是部署工具，需要反映新的 skill 结构。

## Risks / Trade-offs

| Risk | Mitigation |
|------|------------|
| 14 个 sub-skill 失去框架入口，新用户找不到 | 14 个 sub-skill 自身 description 完整（含 trigger 词）；`sd-firmware-copilot` 末尾新增 Skill map 速查表 |
| `sd-firmware-copilot` 变得过长（350 + 80 = 430 行） | 合并内容控制在 ≤ 80 行；超过 500 行触发 `agentskills.io` 规范警告 |
| 删除后回滚成本 | `git revert` 即可恢复，无运行时依赖 |
| Bootstrap 决策表整合到 350 行 SKILL.md 后视觉不突出 | 用 `## Superpowers 框架整合` 顶级标题，与 KNOW/BUILD/FEEDBACK 阶段对称 |
| 14 个 `superpowers-*` sub-skill 自检时丢失 | 它们的 description 已含 "Stage N of OpenSpec" 或 trigger 词，OpenCode auto-match 不依赖顶层入口 |

## Migration Plan

无运行时 migration。`git rm` + 新建即可，回滚用 `git revert`。

**部署顺序**：
1. 先在 `sd-firmware-copilot/SKILL.md` 追加新段（不破坏现状）
2. 更新 8+ 处引用
3. 更新 `verify.sh` 期望
4. 最后 `git rm superpowers/SKILL.md`（此时所有引用已重定向）
5. 跑 `bash verify.sh` 确认 11/12 通过
6. grep 8 处引用全部更新

**回滚**：`git revert <commit>`。

## Open Questions

无。已与用户对齐：删 + 合并到 sd-firmware-copilot。
