## Context

最近 2 个 OpenSpec change（`split-openspec-workflow-skill` + `consolidate-superpowers-entry-into-sd-firmware-copilot`）让 `.opencode/skills/` 成为项目真正入口：

- `sd-firmware-copilot/SKILL.md` 含 4 Iron Rules、Bootstrap 决策表、Skill map、4 阶段（KNOW/PLAN/BUILD/FEEDBACK）详细流程
- `openspec-workflow/SKILL.md` 含 OpenSpec 5 phase 路由
- 14 个 `superpowers-*` sub-skill 各自独立 description 触发

但 2 份"老黄历"文档仍与 skill 重复——`AGENTS.md` 与 `SSD_Firmware_AI_Copilot_Methodology.md`。

### 当前冗余

**`AGENTS.md`（82 行）**：
- Line 3-9「superpowers 四条铁律」—— 完全重复 `sd-firmware-copilot §Iron Rules`
- Line 75-81「写代码/修 bug/完成前/审查/多任务/执行 tasks.md」7 条规则清单 —— 完全重复 `sd-firmware-copilot §Bootstrap 决策表`
- Line 64-68「OpenSpec 流程」—— 已正确指向 1+5 skill 拆分（无需改）

**`SSD_Firmware_AI_Copilot_Methodology.md`（286 行）**：
- §3 KNOW 阶段（lines 41-92）—— 重复 `sd-firmware-copilot §KNOW`
- §4 PLAN 阶段（lines 95-122）—— 重复 `openspec-workflow + openspec-propose`
- §5 BUILD 阶段（lines 125-205）—— 重复 `sd-firmware-copilot §BUILD`
- §6 FEEDBACK 阶段（lines 208-223）—— 重复 `sd-firmware-copilot §FEEDBACK`
- §8 目录结构（lines 257-283）—— 我们已在前 2 个 refactor 同步过，继续维护负担

### 保留的内容

`AGENTS.md`：
- 顶部 1 行项目说明
- §codegraph 与 FEMU_ROOT（lines 10-34）—— zsf 项目特有（环境变量说明）
- §graphify（lines 38-52）—— zsf 项目特有（插件规则）
- §openspec（lines 54-68）—— 已含 1+5 正确指针

`Methodology.md`：
- §1 两种驱动路径（Design/Code-driven）—— 人类可读概览
- §2 核心闭环（KNOW→PLAN→BUILD→FEEDBACK 图）—— 人类可读概览
- §7 快速上手（bash 命令）—— 实操可执行
- §8 目录结构（轻量版）—— 项目结构参照
- §9 核心原则（表格）—— 跨文档统一口径
- §10 下一步 —— 链接导航

## Goals / Non-Goals

**Goals**:
- AGENTS.md 从 82 行瘦身到 ≤ 60 行（-27%）
- Methodology.md 从 286 行瘦身到 ≤ 130 行（-55%）
- 保留所有项目特有内容（环境变量、插件规则、Quick Start）
- 删除与 skill 重复的所有内容，替换为指针
- verify.sh 新增 [13/13] `.omo/` 干净检查

**Non-Goals**:
- 不修改 docs/{navigation,roadmap,maintainer,state-of-art-2026}.md
- 不修改 6 个 `.opencode/memory/*.md`
- 不删 AGENTS.md / Methodology.md
- 不改 README.md

## Decisions

### 决策 1：AGENTS.md 保留 ≤ 60 行，定位为「OpenCode 启动指令」

**选择**：
- 删除 lines 3-9（4 Iron Rules）→ 替换为 1 行指针
- 删除 lines 75-81（7 superpowers 规则）→ 替换为 1 行指针
- 保留 lines 10-34（FEMU_ROOT）、38-52（Graphify）、54-68（OpenSpec CLI 命令清单）
- 顶部加 1 行说明"AI 完整工作流见 `sd-firmware-copilot/SKILL.md`"

**理由**：
- AGENTS.md 真正的独特价值是项目环境配置（`FEMU_ROOT`）和插件规则（`graphify.js`）—— 这些是"启动时必读"信息
- 重复内容改指针后，AI 仍能找到完整规则（不会丢信息），但减少 token 浪费

### 决策 2：Methodology.md 保留 ≤ 130 行，定位为「人类可读概览」

**选择**：
- 删除 §3-6（4 阶段详细流程，~150 行）→ 替换为 1 段指针
- 保留 §1（双路径）、§2（核心闭环图）、§7（Quick Start）、§8（目录结构）、§9（核心原则）、§10（Next Steps）

**理由**：
- Methodology.md 是给"5 分钟快速了解项目"的人类读者看的
- skill 是给"实际执行任务"的 AI 看的——两者粒度不同
- 但内容不应重复，应各司其职

### 决策 3：verify.sh 新增 [13/13] `.omo/` 干净检查

**选择**：
- 改 `verify.sh` summary 从 "12/12" 改为 "13/13"
- 在 [12/12] 后追加 [13/13] 检查 `.omo/` 目录应为空
- 若 `.omo/` 不为空 → bad 并列出文件

**理由**：
- `.gitignore` 已排除 `.omo/`，但本地可能有遗留
- verify.sh 应捕获"开发环境脏"
- 防止 `.omo/tasks/*.json` 重新堆积

## Risks / Trade-offs

| Risk | Mitigation |
|------|------------|
| AGENTS.md 删 4 Iron Rules 后 AI 不再读到——但 sd-firmware-copilot 必加载 | AGENTS.md 顶部加明确指针："完整工作流见 `sd-firmware-copilot/SKILL.md`" |
| Methodology.md 删 4 阶段细节——但 skill 仍含 | Methodology.md §2 末尾加指针："阶段详细流程见 sd-firmware-copilot/SKILL.md" |
| verify.sh 总数 12→13，破坏 CI/下游脚本期望 | 改 summary 数字，但保持"0 失败 = exit 0"语义不变；如需严格兼容，可保留 "12/12" 文案并新增 [13/13] 但不计入"通过数"——**当前 zsf 无 CI 自动化，采用前者** |

## Migration Plan

无运行时 migration。`git mv`/`rm` + 文本编辑即可，回滚用 `git revert`。

**部署顺序**：
1. 先瘦身 AGENTS.md（不破坏现状）
2. 再瘦身 Methodology.md
3. 追加 verify.sh [13/13] 检查
4. 跑 `bash verify.sh` 确认 13/13（除 FEMU_ROOT 环境项）
5. grep 验证 0 悬空引用

**回滚**：`git revert <commit>`。

## Open Questions

无。
