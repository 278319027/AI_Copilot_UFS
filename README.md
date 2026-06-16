# SSD Firmware AI Copilot

面向 SSD 固件团队的 AI 辅助编程体系，基于 `OpenCode Agent` + `CodeGraph`（调用图分析）+ `Graphify`（知识图谱）+ `OpenSpec`（规格驱动开发）。

## 交付形式

本仓库交付 **五件套**：

| 组件 | 位置 | 用途 |
|------|------|------|
| **方法论平台** | `SSD_Firmware_AI_Copilot_Methodology.md` + `.opencode/`（memory/knowledge/skills） | 固件开发团队的 AI 工作环境 |
| **Skill 可分发包** | `.opencode/skills/sd-firmware-copilot/`（init.sh + rules + references + knowledge-templates） | 复制到任何项目，`bash init.sh` 一步部署全套能力 |
| **参考实现** | `../femu/hw/femu/`（独立仓库） | CodeGraph + Graphify + WAF 改进，验证方法论可行 |
| **规格基线** | `.opencode/skills/sd-firmware-copilot/specs/baseline/` | 系统当前行为的权威描述（NVMe/FTL/NAND/错误处理） |
| **集成方案** | `.omo/plans/openspec-integration-plan.md` | 完整 OpenSpec 集成方案与设计决策 |

## 能力概览

| 能力 | 工具支撑 | 状态 |
|------|---------|------|
| 需求理解 | 提示词库 + Memory 规则 | ✅ 已建立 |
| 设计理解 | 提示词库 + Memory 规则 | ✅ 已建立 |
| 代码结构分析 | CodeGraph（调用图/影响分析/MCP） | ✅ 已部署（FEMU） |
| 知识图谱查询 | Graphify（社区检测/概念解释） | ✅ 已部署（FEMU） |
| 规格查询与追溯 | OpenSpec（基线规范 + 增量追踪 + 归档审计） | ✅ 已建立 |
| 提案与范围管理 | proposal.md + Proposal Gate | ✅ 已建立 |
| 实现方案生成 | 提示词库 + Memory 规则 + design.md | ✅ 已建立 |
| 代码生成 | Development Skill + 小任务原则 + tasks.md | ✅ 已建立 |
| Review 辅助 | Review Skill + 查证式验证 + review.md | ✅ 已建立 |
| 测试建议生成 | 提示词库 + tasks.md 测试场景 | ✅ 已建立 |
| 归档与审计 | specs/ 增量合并 + chore(spec) commit | ✅ 已建立 |

## 仓库结构

```text
zsf/
├── README.md                                # 本文件
├── opencode.json                            # 统一配置（MCP → FEMU + Graphify 插件）
│
├── SSD_Firmware_AI_Copilot_Methodology.md   # 方法论总文档
├── .opencode/                   # OpenCode Agent 配置
│   ├── memory/                 # 项目规则与约束
│   │   ├── architecture.md      # 分层规则 + CodeGraph/OpenSpec 查询规则
│   │   ├── coding_style.md      # 编码风格
│   │   ├── concurrency_rules.md # 并发安全规则
│   │   ├── design_rules.md      # 设计规则（状态机/Context/资源管理 + 三级门禁）
│   │   ├── review_rules.md      # Review 检查项
│   │   └── testing_rules.md     # 测试规则
│   └── skills/                 # 可复用工作流
│       ├── development/         # 开发 Skill（含 OpenSpec 提案、CodeGraph 查询）
│       ├── review/              # Review Skill（查证式验证 + review.md 产出）
│       └── sd-firmware-copilot/ # ✅ 可分发 Skill 包
│           ├── init.sh           # 一键部署（含 .openspec/ 目录初始化）
│           ├── SKILL.md          # 主 Skill 定义（含 OpenSpec 流程）
│           ├── rules/            # 规则文件（7 个：含 spec_rules.md）
│           │   └── spec_rules.md # 规格层规则（基线管理、增量格式、三级门禁、归档）
│           ├── references/       # 参考文档与模板
│           │   └── spec_workflow.md  # OpenSpec 工件模板（proposal/design/tasks/review/specs/archive）
│           ├── knowledge-templates/ # 硬件知识模板
│           └── specs/            # 规格基线
│               └── baseline/     # 活规格基线（nvme-commands/ftl-mapping/nand-driver/error-handling）
│
├── deploy_tools.sh                            # 一键部署工具链（codegraph + cscope + doxygen + graphify）
└── .gitignore
```

## 推荐阅读顺序

| 序号 | 文档 | 内容 |
|------|------|------|
| 1 | [方法论总文档](./SSD_Firmware_AI_Copilot_Methodology.md) | 核心原则、五大核心组成、标准工作流、OpenSpec 集成、路线图 |
| 2 | [规格工作流](./.opencode/skills/sd-firmware-copilot/references/spec_workflow.md) | proposal/design/tasks/review/specs/archive 全部工件模板与使用规范 |
| 3 | [规格层规则](./.opencode/skills/sd-firmware-copilot/rules/spec_rules.md) | 基线管理、增量格式（ADDED/MODIFIED/REMOVED）、三级门禁、归档机制 |
| 4 | [CodeGraph 部署教程](./.opencode/skills/sd-firmware-copilot/references/deploy-guide.md) | 工具选型、安装部署、MCP 集成 |
| 5 | [Architecture 规则](./.opencode/memory/architecture.md) | 分层规则 + CodeGraph 查询规则 + OpenSpec 基线查询优先级 |
| 6 | [Concurrency 规则](./.opencode/memory/concurrency_rules.md) | 并发安全：volatile/ISR/锁/DMA/原子/多核 |
| 7 | [Design 规则](./.opencode/memory/design_rules.md) | 状态机/Context/资源管理/错误处理 + Proposal/Design/Review 三级门禁 |
| 8 | [Review 规则](./.opencode/memory/review_rules.md) | Review 检查项 + SSD 固件专项 + 查证式验证 |
| 9 | [NAND ECC 知识](./.opencode/knowledge/nand_controller/ecc.md) | ECC 纠错、弱块标记、坏块管理 |
| 10 | [NVMe 错误处理](./.opencode/knowledge/nvme_spec/error_handling.md) | NVMe 状态码、重试策略、断电恢复 |
| 11 | [Development Skill](./.opencode/skills/development/skill.md) | 开发流程（含 OpenSpec 提案 + CodeGraph 查询 + design.md/tasks.md） |
| 12 | [提示词库](./.opencode/skills/sd-firmware-copilot/references/prompt_library.md) | 需求理解/设计方案/编码/Review/测试 |

## 核心原则

```text
Source Code > Design Docs > Specs > Memory > Prompt
```

- **代码优先**：代码是真实实现，文档可能滞后，Memory 保存规则，Prompt 只是当前输入
- **规格优先于记忆**：Specs（基线规范）描述系统当前行为，查询优先级：基线 → CodeGraph → 代码
- **小任务原则**：每次 200~500 行，不扩大需求，tasks.md 强制粒度约束
- **AI 辅助不替代**：人负责架构决策、设计确认、风险判断、最终责任
- **CodeGraph 先查再改**：修改前必须查询影响范围（当前部署于 FEMU `../femu/hw/femu/`）
- **OpenSpec 三级门禁**：Proposal Gate（提案确认）→ Design Gate（设计确认）→ Review Gate（审查验证）

## 标准使用流程

```text
需求 / 设计文档
  │
  ▼
Step 0: Proposal（产出 proposal.md + specs/ 增量）
  │  明确意图、范围、验收标准、行为变更声明
  │  → Proposal Gate：人工确认动机清晰、范围正确
  │
  ▼
Step 1: CodeGraph 查询（design.md 阶段强制）    ← MCP 工具（当前部署于 FEMU）
  │  codegraph callers <symbol>                ← 谁调用了？
  │  codegraph callees <symbol>                ← 调用了谁？
  │  codegraph impact <symbol>                 ← 影响范围？
  │  codegraph explore <query>                 ← 区域探索
  │  cscope -L2/-L4 <ptr/macro>                ← 函数指针/宏（补充）
  │
  ▼
Step 2: 输出设计方案（产出 design.md + tasks.md）
  │  → Design Gate：人工确认架构假设、CodeGraph 完整性、替代方案
  │
  ▼
Step 3: 小步编码（200~500 行/任务，按 tasks.md 执行）
  │
  ▼
Step 4: Review（产出 review.md，查证式验证）
  │  对照 design.md CodeGraph 结果 + specs/ 增量一致性
  │  → Review Gate：确认影响范围正确、增量一致、测试覆盖
  │
  ▼
Step 5: 归档（specs/ 增量合并到 baseline，chore(spec) commit）
  │
  ▼
Step 6: 人工确认 + 提交
```

所有 OpenSpec 变更工件（proposal/design/tasks/review/specs）Git 版本化、可追溯、不可丢弃。
简化豁免：单文件 bugfix 可跳过 Proposal Gate，文档/注释变更无需 OpenSpec 工件。

## CodeGraph 快速入门

### 工具组成

| 工具 | 用途 | 覆盖场景 | 安装 |
|------|------|----------|------|
| **ops-codegraph** | 调用图/依赖图/影响分析，30+ MCP 工具 | ~80% | `npm install -g @optave/codegraph` |
| **ctags + cscope** | 函数指针/宏查询（tree-sitter 盲区） | ~15% | `apt install universal-ctags cscope` |
| **Doxygen** | 交互式 HTML 文档+可视化图（按需） | ~5% | `apt install doxygen graphviz` |

### 安装部署

详细安装步骤见 [CodeGraph 部署与使用教程](./.opencode/skills/sd-firmware-copilot/references/deploy-guide.md)。

### 常用查询

```bash
# ops-codegraph MCP（AI 直接调用）
codegraph query nand_read_page                  # 搜索符号
codegraph callers nand_read_page                # 谁调用了
codegraph callees nand_read_page                # 调用了谁
codegraph impact nand_read_page                 # 影响分析
codegraph explore "nand read write"             # 区域探索
codegraph status                                # 索引统计

# cscope（补充函数指针和宏）
cscope -d -L2 "func_ptr_name"    # 函数指针调用者
cscope -d -L3 "func_ptr_name"    # 函数指针指向
cscope -d -L4 "MACRO_NAME"       # 宏使用位置
cscope -d -L8 "nand_ctx.h"       # 谁包含了这个头文件
```

### MCP 集成（OpenCode Agent）

在项目根目录 `opencode.json` 中添加（使用 `opencode mcp add codegraph` 或手动编辑）：

```json
{
  "$schema": "https://opencode.ai/config.json",
  "mcp": {
    "codegraph": {
      "type": "local",
      "command": ["codegraph", "serve", "--mcp", "--path", "/home/tcb/AI_Proj/femu/hw/femu"],
      "enabled": true,
      "env": {}
    }
  }
}
```

> 注意：opencode 配置键是 `mcp` 而非 `mcpServers`，`command` 是数组而非字符串。修改后需重启 opencode。

> 详细教程见 [CodeGraph 部署与使用教程](./.opencode/skills/sd-firmware-copilot/references/deploy-guide.md)

## Graphify 知识图谱

Graphify 是项目级多模态知识图谱，与 CodeGraph 互补：

| 维度 | Graphify | CodeGraph |
|------|----------|-----------|
| 分析粒度 | 文件级 + 语义级 | 函数级（调用图） |
| 覆盖内容 | 代码 + Markdown + PDF | 纯代码结构 |
| 核心能力 | 社区检测、概念解释、路径查询 | 调用链、影响分析、CI 门禁 |
| 典型问题 | "为什么这样设计"、"相关概念有哪些" | "谁调用了这个函数"、"改了影响谁" |

### 常用命令

```bash
graphify query "<问题>"           # 知识图谱查询
graphify path "<A>" "<B>"         # 两个概念间的关系路径
graphify explain "<概念>"          # 概念聚焦解释
graphify update .                 # 代码变更后更新图谱（AST-only，无需 LLM）
graphify extract <path>           # 首次构建或论文/文档语义提取（需 LLM API key）
```

> Graphify 已部署于 FEMU 项目（`../femu/hw/femu/`），与 CodeGraph 配合提供代码结构 + 语义查询双通道。论文语义索引需 `DEEPSEEK_API_KEY` 或 `OPENAI_API_KEY`。

## 项目架构（五层）

```
┌─────────────────────────────────────────┐
│  规格层 (OpenSpec)  — 当前行为的权威描述   │  ← 新增
│  specs/baseline/ + proposals/{id}/specs/ │
├─────────────────────────────────────────┤
│  约束层 (Memory)    — 规则、风格、知识     │  ← 已有
│  memory/ + knowledge/                    │
├─────────────────────────────────────────┤
│  基础设施层        — CodeGraph/cscope/Doxygen/Graphify │  ← 已有
├─────────────────────────────────────────┤
│  流程层 (Skills)   — 开发/审查/规格管理   │  ← 增强
│  development/ + review/ + spec workflow  │
├─────────────────────────────────────────┤
│  代码层 (Source Code) — 最终真实实现      │  ← 参考
│  ../femu/hw/femu/                        │
└─────────────────────────────────────────┘
```

## 快速关联外部项目

将本方法论应用到其他固件项目只需两步：

### 1. CodeGraph 部署与索引

```bash
# 在目标代码目录执行
npm install -g @optave/codegraph
codegraph init <代码路径>
```

### 2. 更新 MCP 指向

编辑本仓库 `opencode.json`，更改 `--path` 参数为目标项目代码目录：

```json
{
  "mcp": {
    "codegraph": {
      "command": ["codegraph", "serve", "--mcp", "--path", "<目标项目绝对路径>"],
      "enabled": true
    }
  }
}
```

重启 OpenCode 后，所有 CodeGraph 工具和 Agent Skill 自动指向新项目。

### 3. 部署 Skill 包（可选）

```bash
bash .opencode/skills/sd-firmware-copilot/init.sh
```

将方法论规则、知识模板和 OpenSpec 目录结构（含 .openspec/）复制到目标项目中。

> 当前配置：`--path /home/tcb/AI_Proj/femu/hw/femu` — 参考实现 FEMU 项目

## 团队落地原则

- 以文档为输入，以代码为事实，以规则为约束，以规格为行为基准。
- 每次只做一个明确任务，避免大范围改动。变更的意图、设计、实现、Review 全过程有工件追溯。
- 所有 AI 输出都必须经过人工确认和工程验证。三级门禁（Proposal/Design/Review）强制执行。
- 设计、规则、规格、代码四者必须分离维护。
- 修改前必须查询 CodeGraph（当前部署于 FEMU `../femu/hw/femu/`），确认影响范围不超出预期。
- 每次变更产生可审计的 OpenSpec 工件（proposal/design/tasks/review/specs），Git 版本化，不可丢弃。

## 可行性结论

> 基于 13 项学术研究（EmbedEval、AutoEmbed、RespCode、NOKHAB Lab 等）和产业案例（Solidigm、Promwad、Claude Code Zephyr）的综合评估。

| 场景 | 可行性 | 前提 |
|------|--------|------|
| 需求理解 & 文档解析 | ★★★★★ | 设计文档质量要高 |
| 代码定位 & CodeGraph | ★★★★★ | 需建设索引 |
| 影响范围分析 | ★★★★ | 依赖 CodeGraph 完整性 |
| 接口层代码生成 | ★★★★ | 需注入接口规约 |
| Review 辅助 | ★★★★ | 内存安全类成熟，并发安全需增强 |
| 测试用例生成 | ★★★★ | 正常路径好，故障注入需领域知识 |
| 方案生成（模块内） | ★★★ | 需完整文档 + 约束规则 |
| FTL 核心算法生成 | ★ | 不可行，纯人工 |
| NAND 物理层驱动 | ★ | 不可行，纯人工 |
