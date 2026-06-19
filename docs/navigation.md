# 项目导航

> 本仓库是 **SSD 固件 AI 辅助编程方法论项目**（"zsf"）。本文档面向**人类读者**做整体导航。
> 仓库约 85% 的内容是给 AI 代理消费的（技能、配置、命令），只有约 5% 是给人类读的——本文档属于那 5%。

## 这是什么

本项目不是 SSD 固件本身，而是 **AI 辅助 SSD 固件开发的方法论与工具链**：

- 一套**四阶段闭环**：KNOW（理解）→ PLAN（规划）→ BUILD（实现）→ FEEDBACK（归档）
- 四个工具协同：Graphify（知识图谱）+ CodeGraph（调用图）+ OpenSpec（规格驱动）+ Superpowers（工程纪律）
- 由 OpenCode Agent 统一编排，运行在 `.opencode/` 下的 Skill/Rule/Memory 三层结构中

## 四阶段闭环（30 秒读懂）

| 阶段 | 做什么 | 用什么工具 |
|------|--------|-----------|
| **KNOW** | 读懂现有代码、设计文档、规格 | CodeGraph（查调用/影响）+ Graphify（查概念/关系） |
| **PLAN** | 写出 `proposal.md` + `design.md` + `tasks.md`，过 Proposal/Design Gate | OpenSpec CLI |
| **BUILD** | TDD 编码、调试、查证式 Review、过 Review Gate | Superpowers（铁律）+ sd-firmware-copilot（域规则） |
| **FEEDBACK** | 归档 `changes/` → `openspec/specs/`，更新知识图谱 | OpenSpec archive + Graphify update |

每一个变更都要走完一圈；不允许跳过 KNOW 或 FEEDBACK。

## 新手上路

刚看完 [README](../README.md)？接下来按你的角色走：

1. 往下翻到「你是谁，要看哪里」→ 找到你的角色入口
2. 往下翻到「关键目录速查」→ 找到你要改的文件位置
3. 往下翻到「项目结构」→ 理解文件之间的层级关系

## 你是谁，要看哪里

| 你的角色 | 入口 | 看完之后看哪里 |
|---------|------|---------------|
| **新人**（了解项目） | [README.md](../README.md) | [SSD_Firmware_AI_Copilot_Methodology.md](../SSD_Firmware_AI_Copilot_Methodology.md) → [docs/roadmap.md](roadmap.md) |
│ **贡献者**（修改 Skill/Rule/Spec） | `.opencode/memory/`（6 个规则文件）→ `openspec/specs/`（基线规格）→ `.opencode/skills/`（技能包） | 跑 `bash verify.sh` 验证环境 |
| **工具部署者**（搭环境） | `deploy_tools.sh` | `deploy_tools.sh` 头部注释（工具链分工 / C 语言限制） |
| **AI 代理**（执行任务） | [AGENTS.md](../AGENTS.md) | 不要读本文档——`AGENTS.md` 才是给你的 |

## 关键目录速查

| 目录 | 用途 | 给谁看 |
|------|------|--------|
| `openspec/` | **规格驱动开发**：基线（`specs/`） + 活跃变更（`changes/`） | 人 + AI |
| `.opencode/skills/` | **AI 技能包**：Superpowers 纪律 + sd-firmware-copilot 领域规则 + OpenSpec 适配器 | AI（人偶尔查阅） |
| `.opencode/memory/` | **项目规则**：6 个规则文件（架构/并发/编码/设计/审查/测试） | AI（人审阅） |
| `docs/` | **人类文档**：roadmap、navigation | 人 |
| `graphify-out/` | **知识图谱产物**：在目标代码库运行 graphify 后生成，zsf 自身无此目录 | AI |
| `AGENTS.md` | **AI 运行时指令**：graphify / openspec / superpowers 三工具规则 | AI |
| `README.md` | **项目入口**：双路径、四工具架构、推荐阅读顺序 | 人 |

## 项目结构

```
zsf/
├── 📖 人类阅读层
│   ├── README.md                    ← 项目入口：两路径、四工具、核心原则
│   ├── AGENTS.md                    ← AI 运行时指令
│   ├── SSD_Firmware_AI_Copilot_Methodology.md  ← 完整方法论
│   └── docs/
│       ├── navigation.md            ← 本文档：文件地图 + 按角色找入口
│       ├── roadmap.md               ← 实施进度与规划
│       └── maintainer.md            ← 维护者日常操作
│
├── 🔧 AI 运行时 (.opencode/)
│   ├── memory/                      ← 编码规则（6 文件，运行时加载）
│   ├── plugins/graphify.js          ← KNOW：知识图谱
│   └── skills/                      ← 四阶段执行引擎
│       ├── sd-firmware-copilot/     ← 顶层：BUILD + FEEDBACK 内联
│       │   └── SKILL.md              ← 主体（含 Spec 规则）
│       ├── superpowers/             ← 工程纪律层（10 子技能）
│       ├── openspec-workflow/       ← OpenSpec 完整工作流（propose→archive）
│
├── 📐 规格层
│   └── openspec/
│       ├── config.yaml              ← 项目上下文
│       └── specs/                   ← 5 个领域规格（唯一真相源）
│
├── 🚀 入口脚本
│   ├── deploy_tools.sh              ← 一键部署工具链
│   ├── verify.sh                    ← 一键健康检查（12 项）
│
*graphify-out/ 存在于目标代码库（如 FEMU），zsf 根目录无此目录*
```


### zsf 与目标代码库的关系

本项目采用**方法论层与目标代码库解耦**的架构设计：

```
zsf 项目 (/home/tcb/AI_Proj/zsf/)
├─ .opencode/skills/      ← Superpowers 工程纪律（随仓库分发）
├─ .opencode/memory/      ← 架构/并发/编码风格规则
├─ openspec/specs/        ← 规格基线（SSD 域知识）
├─ openspec/changes/      ← 变更追踪与审计
└─ opencode.json          ← Agent 配置（指向目标代码库）

目标代码库 (/home/tcb/AI_Proj/femu/hw/femu/)
├─ *.c / *.h              ← 实际固件源码（唯一可变源）
├─ graphify-out/          ← 代码知识图谱（版本强绑定）
└─ my-docs/               ← 代码自带的设计文档
```

#### 设计理由

| 考量 | 说明 |
|------|------|
| **不污染代码库** | femu 是 QEMU fork，有自己的 Git 历史和上游同步需求；避免 `.opencode/` 和 `openspec/` 混入其提交历史 |
| **一套方法论 → 多目标** | 通过 `opencode.json` 的 `FEMU_ROOT` 变量可切换任意 SSD 固件代码库，无需重复部署 |
| **职责分离** | zsf 是"驾驶舱"（方法论、配置、变更追踪），femu 是"引擎"（源码、构建、运行） |
| **分析产物就近** | `graphify-out/` 放在 femu 中是因为它与代码版本强绑定，重建时需定位到代码根目录 |

#### 常见问题

**Q：为什么 `verify.sh` 通过，但 femu 目录下没有 `.opencode/` 和 `openspec/`？**
A：这是有意为之。`.opencode/` 和 `openspec/` 位于 zsf（方法论仓库），而非 femu（目标代码库）。Agent 从 zsf 加载配置与技能，通过 `FEMU_ROOT` 指向 femu 进行代码分析与修改。

**Q：能否把 zsf 的方法论文件复制/软链接到 femu 中？**
A：不推荐。这会污染 femu 的 Git 状态，与上游 QEMU 同步时产生冲突。保持分离是更干净的设计。

## 几条重要约定

1. **代码优先**：`Source Code > Design Docs > Specs > Memory > Prompt`。代码是真实实现。
2. **小任务原则**：单次变更 200-500 行。
3. **修改前必查 CodeGraph**：用 `codegraph impact` 确认影响范围。
4. **四级门禁**：Proposal Gate → Design Gate → Review Gate → Archive Gate，每一步有工件（`proposal.md` / `design.md` / `tasks.md` / `review.md`）。
5. **四条铁律**：不验证不宣称完成 / 无验证不写实现 / 无根因不修 bug / 未审查不合并。
6. **AI 辅助不替代人**：架构决策与风险判断由人负责。

## 如果你只想看 3 份文档

1. [README.md](../README.md) — 项目是什么、怎么用
2. [SSD_Firmware_AI_Copilot_Methodology.md](../SSD_Firmware_AI_Copilot_Methodology.md) — 方法论核心
3. [docs/roadmap.md](roadmap.md) — 当前进度与规划

## 如果你是 AI 代理

请直接读 [AGENTS.md](../AGENTS.md)，**不要**读本文档——本文档是给人看的导航，AGENTS.md 才是给你的运行时指令。

## 配置索引

项目的关键配置文件与对应职责：

| 配置文件 | 职责 |
|---------|------|
| `opencode.json` | OpenCode 运行时配置（MCP、插件） |
| `openspec/config.yaml` | OpenSpec 上下文（语言/C 域、工具链） |
| `.opencode/memory/*.md` | 编码规则（架构/并发/代码风格/设计/审查/测试） |
| `.gitignore` | 排除模式 |
