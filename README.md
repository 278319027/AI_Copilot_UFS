# SSD 固件 AI 辅助编程

面向 SSD 固件团队的 AI 辅助编程体系，基于四工具架构：**Graphify**（知识图谱）+ **CodeGraph**（调用图）+ **OpenSpec CLI**（规格驱动）+ **Superpowers**（工程纪律），由 `OpenCode Agent` 统一编排 **KNOW → PLAN → BUILD → FEEDBACK** 闭环。

## 两种使用路径

### 路径 A：设计文档驱动

已有设计文档（SAD/SDD/ICD），AI 直接理解设计并实现。

```bash
# KNOW：理解设计
graphify query "<设计关键词>" && codegraph explore <代码区域>

# PLAN：创建变更
/opsx:propose my-change "根据 SDD 第 X 章实现 Y 功能"

# BUILD：TDD 实现
/opsx:apply my-change

# FEEDBACK：归档
/opsx:archive my-change && graphify update .
```

### 路径 B：代码驱动

无设计文档，AI 先分析代码自动生成设计文档，再按路径 A 执行。

```bash
# KNOW：分析代码 + 生成设计文档
codegraph explore <区域> && codegraph callers <核心函数>
graphify explain "<概念>"
# → AI 自动生成设计文档

# PLAN → BUILD → FEEDBACK 同路径 A
```

## 四工具架构

| 阶段 | 工具 | 部署方式 |
|------|------|---------|
| **KNOW** | Graphify + CodeGraph | `bash deploy_tools.sh` |
| **PLAN** | OpenSpec CLI v1.4.1 | `npm install -g @fission-ai/openspec` |
| **BUILD** | Superpowers + sd-firmware-copilot | `.opencode/skills/superpowers/` |
| **FEEDBACK** | OpenSpec CLI + Graphify | 同上 |

## 项目结构

```
zsf/
├── 📖 人类阅读层
│   ├── README.md                    ← 本文件：30 秒上手
│   ├── AGENTS.md                    ← AI 代理规则（graphify/openspec/superpowers）
│   ├── docs/
│   │   ├── navigation.md            ← 新人导航：项目是什么、文件去哪找
│   │   └── roadmap.md               ← 实施进度与规划
│   └── SSD_Firmware_AI_Copilot_Methodology.md  ← 完整方法论
│
├── 🔧 AI 代理运行时 (.opencode/)
│   ├── memory/                      ← 编码规则（6 文件，运行时自动加载）
│   │   └── architecture / design / coding / concurrency / review / testing
│   ├── plugins/graphify.js          ← KNOW：知识图谱生成/查询
│   └── skills/                      ← 四阶段的执行引擎
│       ├── sd-firmware-copilot/     ← 顶层：SSD 固件 AI 助手统一入口
│       │   ├── rules/spec_rules.md  ← OpenSpec 流程规则
│       │   ├── references/          ← 工作流模板 / 部署指南 / 提示库
│       │   └── init.sh              ← 一键初始化
│       ├── superpowers/             ← 工程纪律层（10 子技能）
│       │   ├── test-driven-development
│       │   ├── verification-before-completion
│       │   ├── systematic-debugging
│       │   ├── executing-plans
│       │   ├── requesting-code-review
│       │   └── ...（共 10 个）
│       ├── development/skill.md     ← BUILD 薄适配器（委托 Superpowers）
│       ├── review/skill.md          ← FEEDBACK 薄适配器
│       └── openspec-*/ ×5           ← OpenSpec CLI 包装器
│
└── 📐 规格层 (openspec/)
    ├── config.yaml                  ← 项目上下文（C 语言、SSD 固件）
    └── specs/                       ← 5 个领域规格（系统行为的唯一真相源）
        ├── ssd-firmware-overview/
        ├── nvme-commands/
        ├── ftl-mapping/
        ├── nand-driver/
        └── error-handling/
```

**数据流**：

```
KNOW                 PLAN                  BUILD                  FEEDBACK
graphify ─┐          openspec-propose ──┐  development ──┐       review
CodeGraph ─┤  ───→   openspec-explore ──┤→ superpowers ──┤ ───→ superpowers
memory/ ───┘          openspec/specs/ ───┘  spec rules ───┘       openspec-archive
(知识图谱+调用图)     (Delta Spec 变更)     (TDD+验证+调试)      (审查+归档)
```
## 快速部署

```bash
bash deploy_tools.sh                     # 一键安装全部工具链
bash .opencode/skills/sd-firmware-copilot/init.sh  # 部署规则和知识模板到当前项目
```

## 推荐阅读

| 序号 | 文档 | 内容 |
|------|------|------|
| 1 | [方法论](./SSD_Firmware_AI_Copilot_Methodology.md) | 双路径、四阶段闭环、三条铁律 |
| 2 | [路线图](./docs/roadmap.md) | 实施进度与规划 |
| 3 | [工程纪律](./.opencode/skills/superpowers/SKILL.md) | TDD / 根因调试 / 验证完成 铁律 |
| 4 | [规格工作流](./.opencode/skills/sd-firmware-copilot/references/spec_workflow.md) | proposal/design/tasks/review 模板 |
| 5 | [规格层规则](./.opencode/skills/sd-firmware-copilot/rules/spec_rules.md) | 基线管理、增量格式、三级门禁 |

## 核心原则

- **代码优先**：`Source Code > Design Docs > Specs > Memory > Prompt`
- **小任务原则**：每次 200-500 行，不扩大需求
- **修改前必查 CodeGraph**：确认影响范围
- **三级门禁**：Proposal Gate → Design Gate → Review Gate
- **三条铁律**：无失败测试不写实现 / 无根因不修 bug / 不验证不宣称完成
- **AI 辅助不替代人**：人负责架构决策和风险判断
