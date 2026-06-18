# SSD 固件 AI 辅助编程方法论

## 1. 两种驱动模式

本方法论支持两种 AI 辅助编程路径，覆盖「有设计文档」和「无设计文档」两种常见场景。

### 模式 A：设计文档驱动（Design → Code）

**适用场景**：已有 SAD/SDD/ICD 等设计文档，需要按文档实现功能。

```
设计文档 → [KNOW] 理解设计 + 定位代码 → [PLAN] 规格化变更 → [BUILD] TDD 实现 → [FEEDBACK] 归档
```

### 模式 B：代码驱动（Code → Design → Code）

**适用场景**：无设计文档，需要基于现有代码理解系统，AI 自动生成设计文档后再实现。

```
现有代码 → [KNOW] 分析代码 + 生成设计文档 → [PLAN] 规格化变更 → [BUILD] TDD 实现 → [FEEDBACK] 归档
```

两种模式的区别仅在 **KNOW 阶段**：模式 A 以设计文档为输入理解系统，模式 B 以代码为输入、AI 自动生成设计文档作为输出。从 PLAN 阶段开始，两条路径完全一致。

---

## 2. 核心闭环：KNOW → PLAN → BUILD → FEEDBACK

| 阶段 | 工具 | 职责 |
|------|------|------|
| **KNOW** | Graphify（知识图谱）+ CodeGraph（调用图） | 理解现有系统结构 |
| **PLAN** | OpenSpec CLI（规格驱动） | 创建变更提案、设计方案、任务分解 |
| **BUILD** | Superpowers（工程纪律）+ sd-firmware-copilot（领域规则） | TDD 实现 + 根因调试 + 验证完成 |
| **FEEDBACK** | OpenSpec CLI + Graphify | 规格归档 + 知识图谱增量更新 |

由 `OpenCode Agent` 统一编排四阶段，形成可审计的闭环。

---

## 3. KNOW 阶段：理解系统

### 3.1 模式 A（设计文档驱动）

1. 读取设计文档（SAD/SDD/ICD）
2. 使用 Graphify 查询相关概念：`graphify query "<关键词>"` / `graphify explain "<概念>"`
3. 使用 CodeGraph 定位相关代码：`codegraph explore <区域>`
4. 输出：需求摘要 + 关键接口 + 风险点

### 3.2 模式 B（代码驱动）

1. 使用 CodeGraph 分析代码结构：调用链（callers/callees）、依赖关系、模块边界
2. 使用 Graphify 查询知识图谱：概念关系、社区结构
3. AI 自动生成设计文档（模块划分、接口定义、状态机、数据流），输出到 `openspec/changes/<id>/design.md`
4. 输出：自动生成的设计文档 + 需求摘要

### 3.3 核心工具

| 工具 | 用途 | 典型查询 |
|------|------|---------|
| **CodeGraph** | 调用图、影响分析 | `codegraph callers <func>`, `codegraph impact <func>`, `codegraph explore <区域>` |
| **Graphify** | 知识图谱、概念解释 | `graphify query "<问题>"`, `graphify explain "<概念>"`, `graphify path "<A>" "<B>"` |
| **cscope** | 函数指针/宏（补充树解析盲区） | `cscope -d -L2 <ptr>`, `cscope -d -L4 <MACRO>` |

### 3.4 Graphify 最佳实践（避免超时）

**根因**：graphify 为每个文件启动 tree-sitter 解析器，大项目文件总量决定耗时。以 FEMU（123K 文件，34K `.c/.h`）为例：子目录 `hw/femu/`+`hw/nvme/` 仅 ~150 文件（< 3s），全仓库即使剔除 `.o/.d` 仍有 118K 文件，实际不可行。

**分场景策略**：

| 项目规模 | 策略 | 命令 |
|----------|------|------|
| < 5K 文件 | 直接全量 | `graphify update .` |
| 5K~15K 文件 | 先清理再全量 | `make clean && graphify update .` |
| > 15K 文件 | **子目录限定**（推荐） | 见下 |

**子目录分构建 + 合并**（最通用，任何规模可用）：

```bash
# 1. 清理构建产物（可选但推荐，减少无关文件扫描）
make clean

# 2. 仅在相关子目录构建
graphify update hw/femu/      # FEMU SSD 代码（< 100 文件，< 3s）
graphify update hw/nvme/      # NVMe 层（< 50 文件，< 2s）

# 3. 合并子图为项目根图谱
graphify merge-graphs hw/femu/graphify-out/graph.json \
                    hw/nvme/graphify-out/graph.json \
                    --out graph.json
```

**回退**：项目根图谱为空时，`graphify query` 会优雅降级，代码内联分析（CodeGraph、grep）仍可用。
---

## 4. PLAN 阶段：规格化变更

使用 OpenSpec CLI 将变更意图转化为结构化工件。

### 4.1 步骤

```
/opsx:propose <change-id> "<意图描述>"
```

一条命令自动生成：

| 产物 | 内容 |
|------|------|
| `proposal.md` | 为什么做、做什么、验收标准 |
| `design.md` | 怎么做（方案设计 + CodeGraph 影响范围 + 待确认清单） |
| `tasks.md` | 实现清单（200-500 行/任务） |
| `specs/` 增量 | ADDED / MODIFIED / REMOVED Requirements 段 |

### 4.2 门禁

| 门禁 | 时机 | 人工确认项 |
|------|------|-----------|
| **Proposal Gate** | proposal.md 完成后 | 动机是否清晰、范围是否正确 |
| **Design Gate** | design.md 完成后 | 架构假设是否正确、CodeGraph 影响范围是否完整、是否有更简单的替代方案 |

> Design Gate 通过后，方可进入编码阶段。

---

## 5. BUILD 阶段：实现与验证

### 5.1 三条铁律（Superpowers，强制执行）

| 铁律 | Skill | 说明 |
|------|-------|------|
| **无验证不写实现** | `test-driven-development` | **Path A**（纯逻辑：红→绿→重构，先写失败测试）；**Path B**（硬件依赖：BUILD 编译验证 + FEEDBACK 系统测试） |
| **无根因不修 bug** | `systematic-debugging` | 禁止凭直觉打补丁；必须先复现、读错误、查变更、形成假设、最小验证 |
| **不验证不宣称完成** | `verification-before-completion` | 完成前必须实际运行测试/编译/命令并验证结果，禁止「应该没问题」 |

### 5.2 领域规则层（sd-firmware-copilot）

在 Superpowers 之上叠加 SSD 固件领域约束：

*Superpowers 是独立开源项目 (obra/superpowers, MIT)，非 SSD 专用。10 个子技能提供通用工程纪律（TDD/验证/调试/审查/并行调度），本项目仅调用它们。SSD 固件领域约束由以下内容叠加。*
- **并发安全**：volatile、ISR 边界、锁、DMA 一致性、多核可见性
- **NVMe 错误处理**：状态码完整、重试策略、断电恢复
- **FTL 不变量**：LBA→PBA 原子性、GC 互斥、磨损均衡
- **NAND 操作**：ECC 强度、弱块标记、坏块替换

### 5.3 执行命令

```
/opsx:apply <change-id>
```

按 `tasks.md` 逐项执行。每项任务按代码性质选 Path A（纯逻辑）或 Path B（硬件依赖）。

---

## 6. FEEDBACK 阶段：反馈与归档

### 6.1 Review（查证式）

由 Review Skill 调度 Superpowers `requesting-code-review` 产出 `review.md`：
- 对照 `specs/` 增量查证代码行为一致性
- SSD 专项检查（并发/NVMe/FTL/NAND）
- 问题按 Critical / Important / Minor 风险分级

### 6.2 归档

```
/opsx:archive <change-id>
```

- `specs/` 增量合并到 `openspec/specs/` baseline
- 知识图谱更新：`graphify update <子目录>`（大项目避免全仓库扫描，见 §3.4）
- 提交：`git commit -m "chore(spec): archive <change-id>"`

### 6.3 闭环返回

归档后，更新后的 baseline 和知识图谱进入下一轮 KNOW 阶段。

---

## 7. 快速上手

### 模式 A：设计文档驱动（完整流程）

```bash
# ─── KNOW：理解设计 ───
graphify query "<设计关键词>"
graphify explain "<核心概念>"
codegraph explore <代码区域>
# → 输出：需求摘要 + 关键接口

# ─── PLAN：创建变更 ───
/opsx:propose my-change "根据 SDD 第 X 章实现 Y 功能"
# → 生成 proposal.md + design.md + tasks.md + specs/ 增量
# → Design Gate：人工确认后进入编码

# ─── BUILD：TDD 实现 ───
/opsx:apply my-change
# → Superpowers 自动执行 Path A（红→绿→重构）或 Path B（编译+FEEDBACK）

# ─── FEEDBACK：Review + 归档 ───
# → Review Skill 产出 review.md
/opsx:archive my-change
graphify update <子目录>   # 大项目避免全仓库扫描（见 §3.4）
```

### 模式 B：代码驱动（完整流程）

```bash
# ─── KNOW：分析代码 + 生成设计文档 ───
codegraph explore <代码区域>
codegraph callers <核心函数>
codegraph impact <关键接口>
graphify explain "<核心概念>"
# → AI 自动生成设计文档到 openspec/changes/<id>/design.md

# ─── PLAN → BUILD → FEEDBACK 同模式 A ───
/opsx:propose my-change "基于代码分析扩展 X 功能"
/opsx:apply my-change
# → Review + 归档
/opsx:archive my-change
graphify update <子目录>   # 大项目避免全仓库扫描（见 §3.4）
```

## 8. 目录结构（当前状态）

```
zsf/
├── README.md                          # 项目入口（两路径 + 快速上手 + 推荐阅读）
├── AGENTS.md                          # AI Agent 运行时指令
├── SSD_Firmware_AI_Copilot_Methodology.md  # 本文件
├── opencode.json                      # OpenCode 配置（MCP + Graphify 插件）
├── deploy_tools.sh                    # 一键部署工具链
├── verify.sh                          # 一键健康检查（8 项）
├── .gitignore
├── docs/
│   ├── navigation.md                  # 项目导航（文件地图 + 按角色找入口）
│   ├── roadmap.md                     # 实施路线图与指标
│   └── maintainer.md                  # 维护者日常操作指南
├── openspec/
│   ├── config.yaml                    # OpenSpec 上下文配置（C 语言/SSD 域）
│   ├── changes/                       # 活跃变更
│   └── specs/                         # 基线规格（5 个 capability）
├── .opencode/
│   ├── memory/                        # 项目规则（6 文件，运行时自动加载）
│   ├── plugins/graphify.js            # 知识图谱插件
│   └── skills/                        # 三个独立 Skill
│       ├── superpowers/               # 通用工程纪律引擎（10 子技能，独立开源 MIT）
│       ├── openspec-workflow/         # OpenSpec 五阶段完整工作流
│       └── sd-firmware-copilot/       # SSD 固件领域规则 + BUILD/FEEDBACK 编排
│           └── SKILL.md               # 唯一主体文件
```

*graphify-out/ 目录在首次运行 graphify update . 后自动生成*

*实际结构截至 2026-06-18。已删除模块（development/review/rules/references/commands/knowledge-templates/specs-baseline/init.sh）均不在此树中。*

---

## 9. 核心原则

| 原则 | 说明 |
|------|------|
| **代码优先** | `Source Code > Design Docs > Specs > Memory > Prompt`。代码是真实实现 |
| **小任务原则** | 每次 200-500 行，不扩大需求，tasks.md 强制粒度约束 |
| **修改前必查 CodeGraph** | 修改函数签名/结构体/头文件前必须查询影响范围 |
| **AI 辅助不替代** | 人负责架构决策、设计确认、风险判断、最终责任 |
| **四级门禁不跳过** | Proposal Gate → Design Gate → Review Gate → Archive Gate，单文件 bugfix 可跳过 Proposal Gate |
| **规格优先于记忆** | Specs（基线规范）描述系统当前行为，查询优先级：基线 → CodeGraph → 代码 |
| **全部工件版本化** | proposal / design / tasks / review / specs 纳入 Git，不可丢弃 |

---

## 10. 下一步

- **部署工具链**：`bash deploy_tools.sh /path/to/c-source`（CodeGraph + cscope + Doxygen + Graphify + OpenSpec CLI）
- **验证环境**：`bash verify.sh`，确认 8/8 通过
- **阅读规格工作流**：`.opencode/skills/openspec-workflow/SKILL.md`（五阶段流程 + 工件模板与门禁清单）
- **查看路线图**：`docs/roadmap.md`
- **理解工程纪律**：`.opencode/skills/superpowers/SKILL.md`
- **了解项目结构**：`docs/navigation.md`（完整文件地图 + 按角色找入口）
- **熟悉领域规则**：`.opencode/memory/`（6 个规则文件，运行时自动加载）
