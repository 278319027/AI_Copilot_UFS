# SSD 固件 AI 辅助编程方法论

> **AI 完整工作流**（4 阶段闭环、4 Iron Rules、Bootstrap 决策表、4 阶段详细流程）见 `.opencode/skills/sd-firmware-copilot/SKILL.md` —— 本文件仅含人类可读的方法论概览（双路径、闭环图、核心原则、目录结构、Quick Start）。

## 1. 两种驱动路径

本方法论支持两种 AI 辅助编程路径：「有设计文档」和「无设计文档」场景。

### 路径 A：设计文档驱动（Design → Code）

已有 SAD/SDD/ICD 等设计文档时使用：

```
设计文档 → [KNOW] 理解设计 + 定位代码 → [PLAN] 规格化变更 → [BUILD] 实现 + 测试 → [FEEDBACK] 归档
```

### 路径 B：代码驱动（Code → Design → Code）

无设计文档时，AI 先分析代码自动生成设计文档再实现：

```
现有代码 → [KNOW] 分析代码 + 生成设计文档 → [PLAN] 规格化变更 → [BUILD] 实现 + 测试 → [FEEDBACK] 归档
```

两种路径的区别仅在 **KNOW 阶段**：路径 A 以设计文档为输入，路径 B 以代码为输入、AI 自动生成设计文档。从 PLAN 阶段开始完全一致。

---

## 2. 核心闭环：KNOW → PLAN → BUILD → FEEDBACK

| 阶段 | 工具 | 职责 |
|------|------|------|
| **KNOW** | Graphify（知识图谱）+ CodeGraph（调用图） | 理解现有系统结构 |
| **PLAN** | OpenSpec CLI（规格驱动） | 创建变更提案、设计方案、任务分解 |
| **BUILD** | Superpowers（工程纪律）+ sd-firmware-copilot（领域规则） | 代码实现 + 测试验证 + 根因调试 + 验证完成。须通过 BUILD Gate（编码前加载 3 个验证 skill） |
| **FEEDBACK** | OpenSpec CLI + Graphify | 规格归档 + 知识图谱增量更新 |

由 `OpenCode Agent` 统一编排四阶段，形成可审计的闭环。**阶段详细流程见 `sd-firmware-copilot/SKILL.md` 与 `openspec-workflow/SKILL.md`。**

---

## 7. 快速上手

### 路径 A：设计文档驱动（完整流程）

```bash
# ─── KNOW：理解设计 ───
graphify query "<设计关键词>"
graphify explain "<核心概念>"
codegraph explore <代码区域>
# → 输出：需求摘要 + 关键接口

# ─── PLAN：创建变更 ───
/opsx:propose my-change "根据 SDD 第 X 章实现 Y 功能"
# → 生成 proposal.md + design.md + tasks.md + specs/ 增量
# → Design Gate：人工确认架构 → BUILD Gate：AI 加载验证 skill 后开始编码

# ─── BUILD：实现 + 测试验证 ───
/opsx:apply my-change
# → 按 tasks.md 实现 → 编写测试覆盖正常/边界/错误路径 → 编译零警告 → 测试全部通过

# ─── FEEDBACK：Review + 归档 ───
# → Review Skill 产出 review.md
/opsx:archive my-change
graphify update <子目录>   # 大项目避免全仓库扫描
```

### 路径 B：代码驱动（完整流程）

```bash
# ─── KNOW：分析代码 + 生成设计文档 ───
codegraph explore <代码区域>
codegraph callers <核心函数>
codegraph impact <关键接口>
graphify explain "<核心概念>"
# → AI 自动生成设计文档到 openspec/changes/<id>/design.md

# ─── PLAN → BUILD → FEEDBACK 同路径 A ───
/opsx:propose my-change "基于代码分析扩展 X 功能"
/opsx:apply my-change
# → 同路径 A：实现 + 测试验证 → Review + 归档
/opsx:archive my-change
graphify update <子目录>   # 大项目避免全仓库扫描
```

## 8. 目录结构（当前状态）

```
zsf/
├── README.md                          # 项目入口（两路径 + 快速上手 + 推荐阅读）
├── AGENTS.md                          # AI Agent 运行时指令（启动配置）
├── SSD_Firmware_AI_Copilot_Methodology.md  # 本文件
├── opencode.json                      # OpenCode 配置（MCP + Graphify 插件）
├── deploy_tools.sh                    # 一键部署工具链
├── verify.sh                          # 一键健康检查（13 项）
├── .gitignore
├── docs/
│   ├── navigation.md                  # 项目导航（文件地图 + 按角色找入口）
│   ├── roadmap.md                     # 实施路线图与指标
│   └── maintainer.md                  # 维护者日常操作指南
├── openspec/
│   ├── config.yaml                    # OpenSpec 上下文配置（C 语言/SSD 域）
│   ├── changes/                       # 活跃变更（archive/ 为历史归档）
│   └── specs/                         # 基线规格（3 个 capability: nvme-commands, ftl-mapping, nand-driver）
├── .opencode/
│   ├── memory/                        # 项目规则（6 文件，运行时自动加载）
│   ├── plugins/graphify.js            # 知识图谱插件
│   ├── commands/                      # 5 个 opsx-* 原生 slash 命令
│   └── skills/                        # 20 个项目级 Skill
│       ├── sd-firmware-copilot/       # 顶层：域规则 + Superpowers 整合（sole integrating skill）
│       ├── openspec-workflow/         # OpenSpec 概念层（Iron Rules + 5 phase 路由）
│       ├── openspec-{propose,explore,apply,sync-specs,archive-change}/  # 5 phase skill
│       └── superpowers-{12 子技能}/   # 工程纪律层
```

*graphify-out/ 目录在首次运行 `graphify update .` 后自动生成于目标代码库（如 FEMU），zsf 自身无此目录。*

---

## 9. 核心原则

| 原则 | 说明 |
|------|------|
| **代码优先** | `Source Code > Design Docs > Specs > Memory > Prompt`。代码是真实实现 |
| **小任务原则** | 每次 200-500 行，不扩大需求，tasks.md 强制粒度约束 |
| **修改前必查 CodeGraph** | 修改函数签名/结构体/头文件前必须查询影响范围 |
| **AI 辅助不替代** | 人负责架构决策、设计确认、风险判断、最终责任 |
| **五级门禁不跳过** | Proposal Gate → Design Gate → BUILD Gate → Review Gate → Archive Gate。单文件 bugfix 可跳过 Proposal Gate；BUILD Gate 强制编码前加载验证 skill |
| **规格优先于记忆** | Specs（基线规范）描述系统当前行为，查询优先级：基线 → CodeGraph → 代码 |
| **全部工件版本化** | proposal / design / tasks / review / specs 纳入 Git，不可丢弃 |

---

## 10. 下一步

- **部署工具链**：`bash deploy_tools.sh /path/to/c-source`（CodeGraph + Doxygen + Graphify + OpenSpec CLI）
- **验证环境**：`bash verify.sh`，确认 12/13 通过
- **AI 完整工作流**：`.opencode/skills/sd-firmware-copilot/SKILL.md`（域规则 + 4 Iron Rules + Bootstrap 决策表 + 4 阶段流程）
- **OpenSpec 概念层**：`.opencode/skills/openspec-workflow/SKILL.md`（Iron Rules + 跨切约束 + 5 phase 路由）
- **执行具体 phase**：`.opencode/skills/openspec-{propose,explore,apply,sync-specs,archive-change}/SKILL.md`
- **查看路线图**：`docs/roadmap.md`
- **了解项目结构**：`docs/navigation.md`（完整文件地图 + 按角色找入口）
- **熟悉领域规则**：`.opencode/memory/`（6 个规则文件，运行时自动加载）
