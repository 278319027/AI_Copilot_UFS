## Why

`.opencode/skills/superpowers/SKILL.md`（144 行）是 Superpowers 框架的"元入口"，含 Bootstrap 决策表、Iron Rules、Skill map、阶段转换触发器等。**它包含高价值内容但与其他 skill 职责重叠**：

- 与 1+5 OpenSpec 拆分哲学冲突（保留概念层，但此处概念层与上层域规则未对齐）
- `superpowers-using-superpowers` 讲"如何使用 skills"的一般规则，不覆盖此处的"何时加载哪个 sub-skill"
- `sd-firmware-copilot` 文档自称为"sole integrating skill"，但缺乏 Bootstrap 决策表——形成"上层声明整合 vs 下层才有路由表"的割裂

**本次目标**：把 `superpowers/SKILL.md` 的**独特价值**（Bootstrap 决策表 + Iron Rules + Skill map + 阶段转换 + Red-line）合并到 `sd-firmware-copilot/SKILL.md`，让 `sd-firmware-copilot` 成为真正唯一的"全项目入口"，删除冗余的 `superpowers/SKILL.md`。

## What Changes

- **删除** `.opencode/skills/superpowers/SKILL.md`（144 行）
- **追加** 到 `.opencode/skills/sd-firmware-copilot/SKILL.md`：
  - Bootstrap 决策表（场景→skill 映射）
  - 阶段转换触发器（KNOW→PLAN→BUILD→FEEDBACK→Archive）
  - 红线自检（4 个 yes/no 问题）
  - 4 Iron Rules
  - Skill map 速查表
- **更新** `verify.sh` [12/12] 检查：从 21 skill dirs（5+1+13+1+1）改为 20（5+1+13+1，去掉 `superpowers` 顶层）
- **更新** 8+ 处引用指向 `sd-firmware-copilot/SKILL.md` §Bootstrap 等新位置：
  - `sd-firmware-copilot/SKILL.md:86` 自身引用（指向新锚点）
  - `AGENTS.md:72, 82`
  - `README.md:52`
  - `SSD_Firmware_AI_Copilot_Methodology.md:284`
  - `docs/roadmap.md:66`
  - `docs/maintainer.md:126`
  - `deploy_tools.sh:14, 15, 309, 310, 312, 315, 336, 362`（8 处注释/检查）

## Non-goals

- **不修改 14 个 `superpowers-*` sub-skill**——它们各自 description 完整，可独立触发
- **不修改 OpenSpec skill（1+5 结构）**——已通过 `split-openspec-workflow-skill` 归档
- **不修改 `superpowers-using-superpowers/SKILL.md`**——它讲"如何用 skills"的一般规则，与本变更无关
- **不引入新 baseline capability**——纯 skill 组织变更，无 spec 行为改动

## Capabilities

### New Capabilities

无。

### Modified Capabilities

无。5 个 baseline capability（ssd-firmware-overview / nvme-commands / ftl-mapping / nand-driver / error-handling）的 REQUIREMENTS 不变。

## Impact

| 路径 | 影响 |
|------|------|
| `.opencode/skills/superpowers/SKILL.md` | 删除（144 行） |
| `.opencode/skills/sd-firmware-copilot/SKILL.md` | 追加 ~80 行（Bootstrap 决策表 + Iron Rules + Skill map + 阶段转换 + Red-line） |
| `verify.sh` | [12/12] 检查从 21 改为 20 skill dirs |
| 8 处 markdown 引用 | 指向 `superpowers/SKILL.md` → `sd-firmware-copilot/SKILL.md` |
| `deploy_tools.sh` | 8 处引用 + 1 个目录检查（line 309-315） |

## Superpowers 铁律适用

- **TDD**：纯 markdown 重构，验证手段 = `verify.sh` 11/12 + 人工 grep 检查无悬空引用
- **verification-before-completion**：完成前跑 `bash verify.sh` + `openspec validate --strict --specs` + grep 8 处引用是否都更新

## CodeGraph 查询

无。本变更不涉及 FEMU 目标代码库。

## Validate Limitation

与 `split-openspec-workflow-skill` 相同：`openspec validate --strict --changes` 强制要求至少 1 个 spec delta。本 change 无 baseline spec 改动。`openspec validate --strict --specs`（baseline）5/5 通过即满足人工 4-gate。
