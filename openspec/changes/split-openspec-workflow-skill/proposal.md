## Why

当前 `openspec-workflow/SKILL.md`（132 行）将 OpenSpec 五阶段（propose / explore / apply / sync / archive）合并在一个 skill 中，单一 description 难以精准触发，AI 误触发相邻阶段的概率高。本次拆分为「1 概念层 + 5 phase skill」结构：保留 `openspec-workflow` 作为共享概念与铁律入口，5 个 phase 各成独立 SKILL.md，让 description 短而准、token 占用按需加载。

## What Changes

- **新增** `openspec-propose/SKILL.md`（Stage 1：`openspec new change` + 生成 artifacts）
- **新增** `openspec-explore/SKILL.md`（Stage 2：思考 + 不写实现）
- **新增** `openspec-apply/SKILL.md`（Stage 3：按 tasks.md 逐项实施）
- **新增** `openspec-sync-specs/SKILL.md`（Stage 4：delta 合并到 baseline）
- **新增** `openspec-archive-change/SKILL.md`（Stage 5：归档 + 提交）
- **新增** `.opencode/commands/opsx-{propose,explore,apply,sync,archive}.md`（5 个原生 slash 命令）
- **修改** `openspec-workflow/SKILL.md`：瘦身至 ≤ 50 行，仅保留 Iron Rules + 跨切约束 + 路由指针
- **修改** `verify.sh` [12/12] 检查：5+14+1=20 个 skills/ 子目录
- **修改** `docs/navigation.md` 与 `SSD_Firmware_AI_Copilot_Methodology.md` 中"10 子技能"旧表述

## Non-goals

- **不修改 baseline specs**（5 个 capability 的行为不变）—— 本次仅为 skill 组织结构变更
- **不新增 baseline capability** —— 拆分后 5 个 openspec-* skill 不属于 openspec/specs/ 范围
- **不改 OpenSpec CLI 行为** —— 仅重构本地 skill 入口，CLI 调用方式（`openspec new change` 等）保持
- **不删除旧 `openspec-workflow` 入口** —— 保留作为「概念层」和 5 phase skill 的发现起点

## Capabilities

### New Capabilities

无 —— 本次变更不引入新的 openspec/specs/ capability。

### Modified Capabilities

无 —— 5 个 baseline capability（ssd-firmware-overview / nvme-commands / ftl-mapping / nand-driver / error-handling）的 REQUIREMENTS 不变。

## Impact

| 路径 | 影响 |
|------|------|
| `.opencode/skills/openspec-workflow/SKILL.md` | 132 → ≤ 50 行 |
| `.opencode/skills/openspec-{propose,explore,apply,sync-specs,archive-change}/SKILL.md` | 新建 5 个，每个 ≤ 80 行 |
| `.opencode/commands/opsx-*.md` | 新建 5 个 slash 命令入口 |
| `verify.sh` [12/12] 检查 | 期望从 13 改为 20 |
| `docs/navigation.md` | "10 子技能" → 1 + 5 + 14 = 20 |
| `SSD_Firmware_AI_Copilot_Methodology.md` | 同上 |

## Superpowers 铁律适用

- **Path A（纯内容 TDD）**：本次为 markdown 文件重构，验证手段为「拆分后每个 SKILL.md 仍能完整描述其 phase 的 关键步骤/约束」+ `verify.sh` 12/12 通过 + 试运行 `/opsx:propose` 端到端确认 slash 命令仍可触发对应 skill
- **verification-before-completion**：完成前必须实际运行 `bash verify.sh` 并读输出 + 试一次完整 propose 流程

## CodeGraph 查询

无 —— 本次变更不涉及 FEMU 目标代码库（`${FEMU_ROOT:-...}/hw/femu/`）的代码改动，CodeGraph MCP 不需要查询。
## Validate Limitation

OpenSpec v1.4.1 `validate --strict --changes` 强制要求至少 1 个 spec delta（`specs/<cap>/spec.md` 含 `## ADDED/MODIFIED/...` 段）。本次变更仅重构 .opencode/skills/ 与 .opencode/commands/，无 baseline spec 行为改动，工具约束下需至少填 1 个空 delta。`openspec validate --strict --specs`（baseline）5/5 通过——`openspec validate --strict --changes` 失败属工具与「无行为变更」场景的边角，不影响人工 4-gate 判定。
