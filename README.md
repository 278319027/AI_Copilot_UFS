# SSD Firmware AI Copilot

面向 SSD 固件团队的 AI 辅助编程体系，基于四工具架构：**Graphify**（知识图谱 / KNOW 层）+ **CodeGraph**（调用图 / KNOW 层）+ **OpenSpec CLI**（规格驱动 / PLAN 层）+ **Superpowers**（工程纪律 / BUILD 层），由 `OpenCode Agent` 统一编排 KNOW→PLAN→BUILD→FEEDBACK 闭环。

## 交付形式

本仓库交付 **五件套产物 + 四件套工具**（四工具架构 = KNOW→PLAN→BUILD→FEEDBACK）：

**五件套产物：**

| 组件 | 位置 | 用途 |
|------|------|------|
| **方法论平台** | `SSD_Firmware_AI_Copilot_Methodology.md` + `.opencode/`（memory/knowledge/skills） | 固件开发团队的 AI 工作环境 |
| **Skill 可分发包** | `.opencode/skills/sd-firmware-copilot/`（init.sh + rules + references + knowledge-templates） | 复制到任何项目，`bash init.sh` 一键部署全套能力 |
| **参考实现** | `../femu/hw/femu/`（独立仓库） | CodeGraph + Graphify + WAF 改进，验证方法论可行 |
| **规格基线** | `openspec/specs/baseline/` | 系统当前行为的权威描述（NVMe/FTL/NAND/错误处理） |
| **集成方案** | `.omo/plans/openspec-integration-plan.md` | 完整 OpenSpec 集成方案与设计决策 |

**四件套工具（架构分层）：**

| 工具 | 部署位置 | 角色 | 架构层 |
|------|---------|------|--------|
| **Graphify** | `uv tool install graphify[all]` | 知识图谱 / 社区检测 / 概念解释 | **KNOW** |
| **CodeGraph** | `npm install -g @optave/codegraph` | 调用图 / 影响分析 / MCP 集成 | **KNOW** |
| **OpenSpec CLI** | `npm install -g @fission-ai/openspec`（v1.4.1 已部署） | 规格驱动：`/opsx:propose` → `/opsx:apply` → `/opsx:archive` | **PLAN** |
| **Superpowers** | `.opencode/skills/superpowers/`（10 子技能） | 工程纪律引擎：TDD + systematic-debugging + verification-before-completion | **BUILD** |

## 能力概览

按 **KNOW→PLAN→BUILD→FEEDBACK** 四层架构组织：

### KNOW 层（理解系统）

| 能力 | 工具支撑 | 状态 |
|------|---------|------|
| 需求理解 | Graphify `query` + Memory 规则 | ✅ 已部署 |
| 设计理解 | Graphify `explain` / `path` + CodeGraph `explore` | ✅ 已部署 |
| 代码结构分析 | CodeGraph（callers / callees / impact） | ✅ 已部署（FEMU） |
| 函数指针/宏查询 | cscope 补充 CodeGraph 盲区 | ✅ 已部署（FEMU） |
| 知识图谱查询 | Graphify（社区检测 / 概念解释） | ✅ 已部署（FEMU） |

### PLAN 层（规格化变更）

| 能力 | 工具支撑 | 状态 |
|------|---------|------|
| 规格查询与追溯 | OpenSpec CLI `openspec list/specs` + `openspec/specs/baseline/` | ✅ 已建立 |
| 提案与范围管理 | `/opsx:propose`（proposal.md + specs/ 增量） | ✅ 已建立 |
| 设计方案生成 | `/opsx:propose` 生成 design.md（CodeGraph 查询已持久化） | ✅ 已建立 |
| 任务分解 | OpenSpec tasks.md（200~500 行/任务）+ 验收标准 | ✅ 已建立 |

### BUILD 层（执行 + 验证）

| 能力 | 工具支撑 | 状态 |
|------|---------|------|
| 代码生成 | Development Skill + Superpowers `test-driven-development`（TDD 铁律） | ✅ 已建立 |
| 实现纠错 | Superpowers `systematic-debugging`（无根因不修） | ✅ 已建立 |
| Review 辅助 | Review Skill + Superpowers `verification-before-completion`（查证式） | ✅ 已建立 |
| Code Review 流程 | Superpowers `requesting-code-review` / `receiving-code-review` | ✅ 已建立 |
| 测试建议生成 | Superpowers TDD + tasks.md 测试场景 | ✅ 已建立 |
| 领域规则 | `.opencode/skills/sd-firmware-copilot/`（SSD 固件专项：并发/ECC/NVMe） | ✅ 已建立 |

### FEEDBACK 层（反馈与归档）

| 能力 | 工具支撑 | 状态 |
|------|---------|------|
| 知识图谱增量更新 | `graphify update .`（AST-only，无 API 成本） | ✅ 已建立 |
| 规格归档 | `/opsx:archive`（specs/ 增量合并到 baseline） | ✅ 已建立 |
| 同步基线 | `openspec sync-specs`（与代码 diff 同步 baseline） | ✅ 已建立 |
| 审计追溯 | OpenSpec `openspec/changes/` + `chore(spec): merge` commit | ✅ 已建立 |

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
│   ├── commands/              # OpenCode 斜杠命令
│   │   ├── opsx-propose.md    # 启动变更 + 生成工件
│   │   ├── opsx-apply.md      # 调度 tasks.md 执行
│   │   ├── opsx-archive.md    # 合并到 baseline
│   │   ├── opsx-sync.md       # 与代码 diff 同步
│   │   └── opsx-explore.md    # 探索性变更（不归档）
│   └── skills/                 # 可复用工作流（4 块 + Superpowers + 领域包）
│       ├── development/         # 开发 Skill（含 OpenSpec 提案、CodeGraph 查询）
│       ├── review/              # Review Skill（查证式验证 + review.md 产出）
│       ├── openspec-propose/    # OpenSpec /opsx:propose 包装
│       ├── openspec-apply-change/  # OpenSpec /opsx:apply 包装
│       ├── openspec-archive-change/ # OpenSpec /opsx:archive 包装
│       ├── openspec-sync-specs/  # OpenSpec /opsx:sync 包装
│       ├── openspec-explore/    # OpenSpec /opsx:explore 包装
│       ├── superpowers/         # ✅ 工程纪律引擎（10 子技能：TDD/debugging/verification/...）
│       │   ├── SKILL.md         # 入口 + 铁律说明
│       │   ├── test-driven-development/  # TDD 铁律
│       │   ├── systematic-debugging/     # 根因调查铁律
│       │   ├── verification-before-completion/  # 完成前验证铁律
│       │   ├── requesting-code-review/   # 代码评审请求
│       │   ├── receiving-code-review/    # 接收评审反馈
│       │   ├── subagent-driven-development/  # 并行子 Agent 驱动
│       │   ├── dispatching-parallel-agents/   # 并行 Agent 调度
│       │   ├── executing-plans/          # 计划执行
│       │   └── finishing-a-development-branch/  # 分支收尾
│       └── sd-firmware-copilot/ # ✅ 可分发 Skill 包
│           ├── init.sh           # 一键部署（含 openspec/ 目录初始化）
│           ├── SKILL.md          # 主 Skill 定义（含 OpenSpec 流程）
│           ├── rules/            # 规则文件（7 个：含 spec_rules.md）
│           │   └── spec_rules.md # 规格层规则（基线管理、增量格式、三级门禁、归档）
│           ├── references/       # 参考文档与模板
│           │   └── spec_workflow.md  # OpenSpec 工件模板（proposal/design/tasks/review/specs/archive）
│           ├── knowledge-templates/ # 硬件知识模板
│           └── specs/            # 规格基线（兼容 openspec/）
│               └── baseline/     # 活规格基线（nvme-commands/ftl-mapping/nand-driver/error-handling）
│
├── openspec/                                 # ✅ OpenSpec 规格仓库（Phase 1 建立）
│   ├── config.yaml             # OpenSpec 配置
│   ├── changes/                # 活跃变更（proposal.md + design.md + tasks.md + specs/）
│   └── specs/                  # 基线规格（nvme-commands/ftl-mapping/nand-driver/error-handling）
│
├── deploy_tools.sh                            # 一键部署工具链（codegraph + cscope + doxygen + graphify + openspec）
└── .gitignore
```

## 推荐阅读顺序

| 序号 | 文档 | 内容 |
|------|------|------|
| 1 | [方法论总文档](./SSD_Firmware_AI_Copilot_Methodology.md) | 核心原则、五大核心组成、标准工作流、四工具架构、路线图 |
| 2 | [Superpowers SKILL.md](./.opencode/skills/superpowers/SKILL.md) | 工程纪律引擎入口：TDD + systematic-debugging + verification-before-completion 铁律 |
| 3 | [OpenSpec 规格工作流](./.opencode/skills/sd-firmware-copilot/references/spec_workflow.md) | proposal/design/tasks/review/specs/archive 全部工件模板与使用规范 |
| 4 | [OpenSpec 规格层规则](./.opencode/skills/sd-firmware-copilot/rules/spec_rules.md) | 基线管理、增量格式（ADDED/MODIFIED/REMOVED）、三级门禁、归档机制 |
| 5 | [OpenSpec 配置](./openspec/config.yaml) | OpenSpec CLI 配置 + 变更/基线目录布局 |
| 6 | [CodeGraph 部署教程](./.opencode/skills/sd-firmware-copilot/references/deploy-guide.md) | 工具选型、安装部署、MCP 集成 |
| 7 | [Architecture 规则](./.opencode/memory/architecture.md) | 分层规则 + CodeGraph 查询规则 + OpenSpec 基线查询优先级 |
| 8 | [Concurrency 规则](./.opencode/memory/concurrency_rules.md) | 并发安全：volatile/ISR/锁/DMA/原子/多核 |
| 9 | [Design 规则](./.opencode/memory/design_rules.md) | 状态机/Context/资源管理/错误处理 + Proposal/Design/Review 三级门禁 |
| 10 | [Review 规则](./.opencode/memory/review_rules.md) | Review 检查项 + SSD 固件专项 + 查证式验证 |
| 11 | [NAND ECC 知识](./.opencode/knowledge/nand_controller/ecc.md) | ECC 纠错、弱块标记、坏块管理 |
| 12 | [NVMe 错误处理](./.opencode/knowledge/nvme_spec/error_handling.md) | NVMe 状态码、重试策略、断电恢复 |
| 13 | [Development Skill](./.opencode/skills/development/skill.md) | 开发流程（含 OpenSpec 提案 + CodeGraph 查询 + design.md/tasks.md） |
| 14 | [提示词库](./.opencode/skills/sd-firmware-copilot/references/prompt_library.md) | 需求理解/设计方案/编码/Review/测试 |

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
- **Superpowers 铁律**：TDD（先写失败测试）/ systematic-debugging（无根因不修）/ verification-before-completion（不验证不宣称完成）

## 标准使用流程

```text
需求 / 设计文档
  │
  ▼
[KNOW] Step 0: 理解系统 — Graphify + CodeGraph
  │  graphify query "<需求关键词>"           ← 知识图谱查询
  │  graphify explain "<概念>"              ← 概念聚焦解释
  │  codegraph explore <区域>               ← 代码区域探索
  │  → 产出：需求摘要 + 关键接口 + 风险点
  │
  ▼
[PLAN] Step 1: Proposal — /opsx:propose
  │  产出 proposal.md + design.md + tasks.md + specs/ 增量
  │  /opsx:propose "<change-id>" "<意图描述>"
  │  → Proposal Gate：人工确认动机清晰、范围正确
  │
  ▼
[PLAN] Step 2: 影响分析 — CodeGraph（持久化到 design.md）
  │  codegraph callers <symbol>              ← 谁调用了？
  │  codegraph callees <symbol>              ← 调用了谁？
  │  codegraph impact <symbol>               ← 影响范围？
  │  cscope -L2/-L4 <ptr/macro>              ← 函数指针/宏（补充）
  │  → Design Gate：人工确认架构假设、CodeGraph 完整性、替代方案
  │
  ▼
[BUILD] Step 3: 小步 TDD 编码 — /opsx:apply + Superpowers
  │  /opsx:apply "<change-id>"               ← 按 tasks.md 执行
  │  200~500 行/任务
  │  Superpowers: test-driven-development     ← 红→绿→重构
  │  Superpowers: systematic-debugging        ← 无根因不修
  │  → 产出：代码 + 测试
  │
  ▼
[BUILD] Step 4: Review — Superpowers + Review Skill
  │  产出 review.md（查证式）
  │  Superpowers: verification-before-completion  ← 不验证不完成
  │  Superpowers: requesting-code-review     ← 交叉评审
  │  → Review Gate：影响范围正确、增量一致、测试覆盖
  │
  ▼
[FEEDBACK] Step 5: 归档 — /opsx:archive
  │  /opsx:archive "<change-id>"             ← specs/ 增量合并到 baseline
  │  graphify update .                       ← 知识图谱增量更新（AST-only）
  │  commit: chore(spec): merge
  │
  ▼
[FEEDBACK] Step 6: 人工确认 + 提交
```

四工具协同总结：

| 阶段 | 主导工具 | OpenCode 命令 / Skill |
|------|---------|----------------------|
| **KNOW** | Graphify + CodeGraph | `graphify query/explain/path` + `codegraph explore` |
| **PLAN** | OpenSpec CLI | `/opsx:propose` → `/opsx:apply` 调度 |
| **BUILD** | Superpowers + sd-firmware-copilot | `test-driven-development` + `systematic-debugging` + `verification-before-completion` |
| **FEEDBACK** | OpenSpec CLI + Graphify | `/opsx:archive` + `graphify update .` |

所有 OpenSpec 变更工件（proposal/design/tasks/review/specs）Git 版本化、可追溯、不可丢弃。
简化豁免：单文件 bugfix 可跳过 Proposal Gate，文档/注释变更无需 OpenSpec 工件。
**Superpowers 铁律**：未做验证不宣称完成、未写失败测试不写实现、未查根因不修 bug。

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

## 项目架构（五层 × 四环）

五层是静态分层（依赖关系），四环是动态闭环（执行流程）：

### 静态分层（五层）

```
┌─────────────────────────────────────────────────────────────┐
│  规格层 (OpenSpec CLI) — 当前行为的权威描述    │  PLAN    │
│  openspec/specs/baseline/ + openspec/changes/{id}/         │
│  → /opsx:propose / /opsx:apply / /opsx:archive            │
├─────────────────────────────────────────────────────────────┤
│  约束层 (Memory)  — 规则、风格、知识          │  —        │
│  .opencode/memory/ + .opencode/knowledge/                  │
├─────────────────────────────────────────────────────────────┤
│  基础设施层 (KNOW) — Graphify + CodeGraph + cscope          │
│  graphify-out/ + .codegraph/ (MCP 集成)                   │
├─────────────────────────────────────────────────────────────┤
│  流程层 (BUILD) — Superpowers + sd-firmware-copilot        │
│  .opencode/skills/superpowers/  (TDD / debugging / verify) │
│  + .opencode/skills/{development,review,sd-firmware-copilot}│
├─────────────────────────────────────────────────────────────┤
│  代码层 (Source Code) — 最终真实实现           │  FEEDBACK │
│  ../femu/hw/femu/                                          │
└─────────────────────────────────────────────────────────────┘
```

### 动态闭环（四环 = KNOW→PLAN→BUILD→FEEDBACK）

```
     ┌──────── KNOW ────────┐
     │  Graphify + CodeGraph │
     │  (理解现有系统)        │
     └──────────┬───────────┘
                │ 需求摘要 + 关键接口
                ▼
     ┌──────── PLAN ────────┐
     │  OpenSpec CLI         │
     │  /opsx:propose        │
     │  (proposal/design/    │
     │   tasks/specs 增量)   │
     └──────────┬───────────┘
                │ tasks.md
                ▼
     ┌──────── BUILD ────────┐
     │  Superpowers + 领域规则 │
     │  test-driven-dev       │
     │  systematic-debugging  │
     │  verification-before-  │
     │  completion            │
     └──────────┬───────────┘
                │ review.md
                ▼
     ┌────── FEEDBACK ──────┐
     │  OpenSpec + Graphify   │
     │  /opsx:archive         │
     │  graphify update .     │
     │  (chore(spec): merge)  │
     └──────────┬────────────┘
                │ 新一轮 KNOW 带着更新后的 baseline
                └──────────► (回到 KNOW)
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
