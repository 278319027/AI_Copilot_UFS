## Why

最近 2 个 refactor（`split-openspec-workflow-skill` + `consolidate-superpowers-entry-into-sd-firmware-copilot`）让 skill 层成为项目真正入口，但**两份"老黄历"文档仍与 skill 重复**：

- `AGENTS.md`（82 行）含 4 Iron Rules + 7 superpowers-* 规则清单——已在 `sd-firmware-copilot/SKILL.md §Superpowers 框架整合` 中
- `SSD_Firmware_AI_Copilot_Methodology.md`（286 行）含 4 阶段（KNOW/PLAN/BUILD/FEEDBACK）的详细流程——已在 `sd-firmware-copilot/SKILL.md` 4 阶段段 + `openspec-workflow/SKILL.md` 中

每次 skill 改完都要手动同步这 2 份文档，**违反"单一真相源"原则**。本次清理让文档回归"指针 + 概览"角色。

## What Changes

- **瘦身** `AGENTS.md` 82 → ≤ 60 行：删除 4 Iron Rules + 7 superpowers 规则清单，替换为指针到 `sd-firmware-copilot §Superpowers 框架整合`。保留项目特有内容：FEMU_ROOT 环境变量、Graphify 插件规则、OpenSpec CLI 命令清单。
- **瘦身** `SSD_Firmware_AI_Copilot_Methodology.md` 286 → ≤ 130 行：删除 4 阶段详细流程（已在 skill），保留：双路径概览、四阶段闭环图、核心原则表、目录结构、Quick Start、Next Steps。
- **追加** `verify.sh` [13/13] 检查：`.omo/` 目录应为空或仅含 `archive/` 子目录（之前 138 个陈旧 JSON 任务文件已通过 `.gitignore` 排除，目录无内容）。

## Non-goals

- **不修改** `docs/{navigation,roadmap,maintainer,state-of-art-2026}.md`——这 4 份是导航/历史/状态文档，与 skill 不重叠
- **不修改** 6 个 `.opencode/memory/*.md` 规则文件——这些是项目级编码规则，不是文档冗余
- **不删** `AGENTS.md` / `Methodology.md`——保留作为人类可读的概览入口，但内容瘦身
- **不动** `README.md`——已 130 行，结构清晰

## Capabilities

### New Capabilities

无。

### Modified Capabilities

无。5 个 baseline capability 不变。

## Impact

| 路径 | 影响 |
|------|------|
| `AGENTS.md` | 82 → ≤ 60 行（-27%） |
| `SSD_Firmware_AI_Copilot_Methodology.md` | 286 → ≤ 130 行（-55%） |
| `verify.sh` | 12/12 → 13/13（新增 [13/13] `.omo/` 干净检查） |

## Superpowers 铁律适用

- **verification-before-completion**：完成前跑 `bash verify.sh` 13/13 + grep 验证无悬空引用
- **TDD**：纯内容重构，验证 = 文档瘦身 + 仍能引导读者找到正确 skill

## CodeGraph 查询

无。本变更不涉及 FEMU 目标代码库。

## Validate Limitation

同前 2 个 change：`openspec validate --strict --changes` 强制要求至少 1 个 spec delta。本 change 无 spec 行为改动。`openspec validate --strict --specs`（baseline）5/5 通过即满足人工 4-gate。
