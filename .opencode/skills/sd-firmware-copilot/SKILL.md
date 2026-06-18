---
name: sd-firmware-copilot
description: SSD 固件 AI 编程助手，基于四阶段闭环（KNOW→PLAN→BUILD→FEEDBACK）和两层架构（Superpowers 工程纪律 + SSD 固件领域知识）。BUILD 和 FEEDBACK 阶段委托 Superpowers；PLAN 和规格管理委托 openspec-workflow。
compatibility: Requires OpenSpec CLI (v1.4.1+), CodeGraph MCP, Graphify plugin.
metadata:
  author: zsf
  version: "1.0"
---

# SSD 固件 AI Copilot

SSD 固件开发的 AI 编程 Copilot。这不是通用 Agent——只做 SSD 固件开发任务。每个 TODO 都可跟踪；每个决策都有设计文档（OpenSpec）。

> 所有 AI 输出（代码/审查/文档）MUST 先通过 Superpowers 铁律（TDD + 根因调试 + 验证完成）再输出。

## 快速入口

**触发词**：`sd-firmware`、`ssd`、`femu`、`nand-controller`、`nvme`，或路径包含 `hw/femu/`。

| 场景 | 流程 |
|------|------|
| 有设计文档 | 按「核心流程」完整执行 |
| 无设计文档 | 先 `codegraph explore <区域>` 生成 `design.md`，再执行 |
| 代码审查 | 按「FEEDBACK 阶段」执行 |
| 规格变更 | 参考 [openspec-workflow](../openspec-workflow/SKILL.md) |

## 核心流程

```
需求 → proposal.md → specs/增量 → Design Gate → CodeGraph查询 → design.md → tasks.md
                                    ↓                                              ↓
                               Proposal Gate                               Review Gate → review.md
                                                                                 ↓
                                                                           归档合并 → baseline
```

> 详细步骤见 [openspec-workflow](../openspec-workflow/SKILL.md)。每个门禁都有对应工件（`proposal.md`/`design.md`/`tasks.md`/`review.md`）。

### 必须遵守

- **代码优先**：`Source Code > Design Docs > Specs > Memory > Prompt`
- **小任务原则**：每次变更 200-500 行
- **修改前必查 CodeGraph**：用 `codegraph explore` 确认影响范围
- **只读文件不修改**：测试框架、构建脚本、适配层

### CodeGraph 查询（必须使用）

- **修改前**：`codegraph explore <函数名或模块>` 找到影响上下游
- **设计时**：`codegraph callers <关键函数>` 确认调用关系
- **审查时**：`codegraph callers <被修改的函数>` 验证改动范围

### cscope 补充

CodeGraph 基于 AST，关注函数级调用关系；cscope 补充：
- 函数指针：`cscope -d -L2funcPtr` 或 `cscope -d -L3symbol`
- 宏使用：`cscope -d -L4MACRO_NAME`
- 头文件包含：`cscope -d -L1header.h`

## BUILD 阶段

### 前置检查

1. 所有 tasks.md 中的 Task 已就绪，blockedBy 已解析
2. CodeGraph 探索已完成（影响范围明确）
3. 理解现有代码模式（错误处理、并发、日志）

### 实现流程（Superpowers 铁律驱动 — 强制加载）

**🚨 必做清单**：在写第一行代码前，通过 skill tool 加载以下所有 skills。**缺一个 = 铁律失效，方法论退化为手动检查清单**。

> 1. `superpowers:test-driven-development` — Path A（纯逻辑）或 Path B（硬件依赖）必走
> 2. `superpowers:executing-plans` — 按 tasks.md 顺序执行
> 3. `superpowers:subagent-driven-development` 或 `superpowers:dispatching-parallel-agents` — 视任务而定
> 4. `superpowers:verification-before-completion` — 每步验证后才进入下一步
>
> 加载列表与触发场景详见 [superpowers/SKILL.md §Bootstrap 决策表](../superpowers/SKILL.md)。

1. **加载 `test-driven-development`**：按 Path A（红→绿→重构）或 Path B（编译→验证→FEEDBACK 测试）执行
2. **加载 `executing-plans`**：按 tasks.md 逐项执行
3. **加载 `subagent-driven-development` 或 `dispatching-parallel-agents`**：复杂任务独立代理；可独立的任务并行
4. **加载 `verification-before-completion`**：每步验证后才进入下一步

> BUILD 阶段从不孤立执行。必须先经过 KNOW（CodeGraph 探索）→ PLAN（OpenSpec proposal/design/tasks），再进入 BUILD。

### 子代理调度策略

| 用例 | 策略 |
|------|------|
| 单一文件修改 | `subagent-driven-development` — 单代理集中执行 |
| 独立并行任务 | `dispatching-parallel-agents` — 最多 5 并行 |
| 代码生成 | 直接生成（Simple Agent） |
| 复杂逻辑 | `ultrabrain` — 提供目标而非步骤 |

### 子代理调度契约

- 提示词必须完整：包含代码模式参考、错误处理约定、并发约束
- 不跳过 task 步：tasks.md 是合同，每个 task 完成即标记
- 不扩大需求：不在代码生成时添加额外功能
- AI 辅助不替代人：人负责架构设计与风险判断

### BUILD 关键约束

- 不创建多余 stub/skeleton 文件——只创建有实际代码的源文件
- 不修改只读文件——跳过测试框架、构建脚本、适配层
- 代码在 `src/` 中编写，单元测试在 `tests/unit/` 中编写
- 禁止：`as any`、`@ts-ignore`、空 catch、抑制类型错误
- 变量/函数名使用英文，注释和文档使用中文

## FEEDBACK 阶段

### 审查前（强制加载）

**🚨 必做清单**：在开始审查前，通过 skill tool 加载以下所有 skills。

> 1. `superpowers:requesting-code-review` — 发起正式审查
> 2. `superpowers:verification-before-completion` — 确保审查用的验证命令真的能跑
> 3. `superpowers:receiving-code-review` — 接收反馈时使用

1. 加载 `requesting-code-review`：按其工作流执行
2. 收集所有已变更文件的 CodeGraph 影响数据

### 审查内容（SSD 领域专项检查）

**通用检查（委托 Superpowers `requesting-code-review`）**：逻辑错误、边界条件、潜在崩溃、设计对齐。

**SSD 固件专项检查**：
- **NAND 控制器**：EEC 页面大小、坏块处理、写入缓存对齐
- **NVMe 命令**：队列管理、PRP/SGL 完整性、Admin/IO 命令生命周期
- **FTL 映射**：映射表一致性、磨损均衡、垃圾回收安全
- **错误处理**：超时、重试策略、断电/崩溃恢复、数据完整性
- **并发安全**：检查共享状态的并发原语；验证中断/线程安全
- **宏和预处理器**：检查条件编译块正确性

### 接收反馈

1. 加载 `receiving-code-review`
2. 问题分类：严重 → 设计 → 代码质量 → 可选
3. 先止血后修复：严重问题立即解决；设计问题通过 openspec 处理
4. 每个修复都经过 tests/unit/ 验证

### 审查后

- 使用 `finishing-a-development-branch`：清理并合并分支
- 所有严重和设计问题验证通过
- 归档审查结果和修复记录

### FEEDBACK 关键约束

- AI 不能批准自己的代码——必须由人类工程负责人批准
- 发现重复模式时提出重构但获得批准后才能执行

## 规则文件

### Memory 规则（全局，运行时自动加载）

| 规则类型 | 描述 | 路径 |
|---------|------|------|
| 架构规则 | SSD 固件架构约束、层次划分 | `.opencode/memory/architecture.md` |
| 并发规则 | 线程模型、锁策略、临界区 | `.opencode/memory/concurrency_rules.md` |
| 编码风格 | C 代码风格、命名、代码组织 | `.opencode/memory/coding_style.md` |
| 设计规则 | 门禁流程、文档要求 | `.opencode/memory/design_rules.md` |
| 审查规则 | 审查清单、质量标准 | `.opencode/memory/review_rules.md` |
| 测试规则 | 测试结构、覆盖率要求 | `.opencode/memory/testing_rules.md` |

## Spec 规则

SSD 固件规格层规则。定义规格基线管理、增量追踪、门禁联动和归档合并机制。本规则基于 **OpenSpec CLI**（`@fission-ai/openspec`）实现，OpenSpec 负责工件结构、校验和归档，zsf 流程注入 SSD 固件域知识（基线查询优先级、CodeGraph 协同、200-500 行任务粒度）。

### 规格层定位

规格层独立于约束层（Memory）和基础设施层（CodeGraph），是「系统当前行为」的权威描述。

```
┌─────────────────────────────────────────┐
│  规格层 (OpenSpec)  — 当前行为的权威描述  │
│  openspec/specs/<cap>/spec.md            │
├─────────────────────────────────────────┤
│  约束层 (Memory)    — 规则、风格、知识     │
├─────────────────────────────────────────┤
│  基础设施层 (CodeGraph/cscope/Graphify)  │
├─────────────────────────────────────────┤
│  流程层 (Skills)      — 开发/审查流程     │
└─────────────────────────────────────────┘
```

**Memory ≠ Spec**：Memory 是约束（「必须遵守什么」），Spec 是行为（「系统当前做什么」），两者独立演进。

### 目录结构

```
openspec/
├── AGENTS.md                       # OpenSpec 注入给 AI 的指令（自动生成）
├── config.yaml                     # schema: spec-driven + 项目上下文
├── specs/                          # 已归档合并的活基线
│   ├── ssd-firmware-overview/spec.md
│   ├── nvme-commands/spec.md
│   ├── ftl-mapping/spec.md
│   ├── nand-driver/spec.md
│   └── error-handling/spec.md
└── changes/                        # 进行中的变更
    └── {change-id}/
        ├── .openspec.yaml          # 变更元数据
        ├── proposal.md
        ├── specs/                  # Delta 规格
        │   └── <capability>/
        │       └── spec.md         # 含 ## ADDED / ## MODIFIED / ## REMOVED
        ├── design.md               # 含 CodeGraph 查询结果
        └── tasks.md                # 200-500 行/任务
```

### 基线规格管理

每个基线 `spec.md` 包含：
1. **`## Purpose`**（强制，≥ 50 字符）：描述 capability 意图
2. **`## Requirements`**：每条用 `### Requirement: <name>`
3. **`#### Scenario: <name>`**（**强制 4 个 `#`**）：用 `**WHEN**` / `**THEN**`
4. **规范词**：使用 SHALL / MUST，避免 should / may

**基线更新规则**：
- 何时更新：每次变更完成并通过 Review Gate 后
- 更新方式：`/opsx:archive`，OpenSpec CLI 自动将 deltas 合并到 `openspec/specs/`
- 合并原则：ADDED → 追加；MODIFIED → 替换同名 Requirement；REMOVED → 删除
- 冲突处理：delta 与基线冲突时，优先审查基线是否过时

**基线查询优先级**：先查 `openspec/specs/<cap>/spec.md` → CodeGraph 局部验证 → 最后读代码

```bash
openspec spec list                  # 列出所有基线
openspec spec show <capability>     # 查看具体 capability
```

### 变更增量格式（OpenSpec Delta 规范）

每次变更在 `openspec/changes/<id>/specs/<capability>/spec.md` 下产生 delta 文件，含 3 类 header。

**ADDED Requirements**（新增行为）：
```markdown
## ADDED Requirements
### Requirement: FTL MUST fold SLC blocks when full
The FTL SHALL migrate data from SLC blocks to TLC blocks when SLC free block count falls below configured threshold.
#### Scenario: SLC threshold reached
- **WHEN** SLC free block count < threshold
- **THEN** the FTL MUST pick a victim SLC block
- **AND THEN** it MUST copy valid pages to a free TLC block
- **AND THEN** it MUST erase the victim SLC block and return it to the free pool
```

**MODIFIED Requirements**（修改行为）：
- 在基线 `specs/<cap>/spec.md` 中找到原有 Requirement
- **复制整个 Requirement 块**（从 `### Requirement:` 到所有 Scenario）
- 粘贴到 delta 文件的 `## MODIFIED Requirements` 下并编辑
- 头文本必须与原有 Requirement 完全一致（缺失会导致归档丢失细节）

```markdown
## MODIFIED Requirements
### Requirement: FTL write path
The FTL MUST allocate a new PBA from the SLC region when possible, or from TLC when SLC is exhausted.
#### Scenario: SLC has free blocks
- **WHEN** the FTL processes a host write
- **THEN** it MUST allocate the new PBA from the SLC region
#### Scenario: SLC exhausted
- **WHEN** the FTL processes a host write and SLC has no free blocks
- **THEN** it MUST allocate the new PBA from the TLC region
- **AND THEN** it MUST schedule an SLC-to-TLC folding pass
```

**REMOVED Requirements**（移除行为）：
```markdown
## REMOVED Requirements
### Requirement: Legacy pblock allocation
**Reason**: Replaced by SLC-aware allocation policy
**Migration**: All write paths use the new SLC allocation logic
```

**增量规范**：
- 使用 SHALL / MUST，避免 should / may
- **4 个 `#` 是强制**：3 个 `#` 或列表会导致 OpenSpec 静默失败
- **可验证性**：每个 Scenario 必须是潜在测试用例
- delta 与 CodeGraph 互补：delta 描述行为变化，design.md 中的 CodeGraph 查询记录实现路径

### 三级门禁体系

详见 [openspec-workflow/SKILL.md §工件模板与门禁流程](../openspec-workflow/SKILL.md)。本规则的门禁速查：

| 门禁 | 输入 | 校验 | 通过后 |
|------|------|------|-------|
| **Proposal Gate** | proposal.md + specs/ delta | `openspec validate --strict --changes` + 人工 5 项 | → Design 阶段 |
| **Design Gate** | design.md + tasks.md | `openspec validate --strict --changes` + CodeGraph + 人工 7 项 | → 编码 |
| **Review Gate** | design.md + specs/ delta + 代码 diff | `openspec validate --strict --changes` + 人工 11 项 | → 归档 |

### 归档与合并

Review Gate 全部通过 + `openspec validate --strict` 通过后执行归档。

```bash
# OpenCode IDE slash command（推荐）
/opsx:archive

# 等效 CLI
openspec archive <change-id>
```

**合并原则**（OpenSpec 自动执行）：ADDED → 追加；MODIFIED → 替换；REMOVED → 删除（审计保留）。原子性、可逆性（Git 跟踪）。

**历史保留**：`openspec/changes/<id>/` 自动移至 `archive/`，不删除。归档 commit：`chore(spec): archive <change-id>`。

**简化规则**：

| 变更类型 | 简化 | 必需工件 |
|---------|------|---------|
| 单文件 bugfix | 跳过 Proposal Gate 人工 | `/opsx:propose` 全部 4 个 |
| 文档/注释更新 | 跳过全部门禁 | 无需工件 |
| 配置变更 | 跳过 Design Gate 人工 | tasks.md |
| 新功能/重构 | 完整流程 | 全部 4 个 + 三级门禁 |
| 跨模块变更 | 完整流程 + 额外 Review | 全部 4 个 + 双人 Review |

### OpenSpec CLI 速查

```bash
npm install -g @fission-ai/openspec        # 一次性
openspec init --tools opencode              # 项目初始化
openspec list                               # 列出 changes
openspec show <id>                          # 查看 change
openspec spec list                          # 列出基线 specs
openspec spec show <cap>                    # 查看基线
openspec validate --strict --all            # 全部校验
openspec validate --strict --specs          # 仅校验基线
openspec validate --strict --changes        # 仅校验 changes
openspec archive <id>                       # 归档

# IDE slash commands
/opsx:propose   /opsx:apply   /opsx:archive
```

### 与其他规则的关系

| 规则 | 关系 |
|------|------|
| `memory/design_rules.md` | 三级门禁统一定义 |
| `memory/review_rules.md` | Review Gate 检查项引用 |
| `memory/testing_rules.md` | 增量可验证性落地 |
| `memory/architecture.md` | CodeGraph 查询被门禁引用 |
| `openspec-workflow/SKILL.md` | CLI 与 zsf 流程衔接 |
| 本 Skill BUILD 阶段 | 开发工件对应规格层 |

## 硬件知识

| 知识主题 | 内容 |
|---------|------|
| NVMe Admin 命令 | 规范要求、实现细节 |
| NVMe IO 命令 | 命令生命周期、队列管理 |
| NAND 设备管理 | ECC、坏块、写入放大、磨损均衡 |
| 固件更新 | 安全下载、回滚、原子性 |
| IO 调度 | 读/写优先级、QoS 保证 |

## 规格基线

| 规格 | 描述 | 路径 |
|------|------|------|
| SSD 固件概述 | 系统架构和数据流 | `openspec/specs/ssd-firmware-overview/spec.md` |
| NVMe 命令 | 命令实现规格 | `openspec/specs/nvme-commands/spec.md` |
| FTL 映射 | 闪存转换层规格 | `openspec/specs/ftl-mapping/spec.md` |
| NAND 驱动 | 底层 NAND 硬件接口 | `openspec/specs/nand-driver/spec.md` |
| 错误处理 | 跨组件错误处理规格 | `openspec/specs/error-handling/spec.md` |

## 初始化

```bash
# 1. 确认环境
bash verify.sh

# 2. 确认 OpenSpec 规格有效
OPENSPEC_TELEMETRY=0 openspec validate --strict --specs

# 3. 确认规则文件到位
ls .opencode/memory/architecture.md .opencode/memory/concurrency_rules.md \
   .opencode/memory/coding_style.md .opencode/memory/design_rules.md \
   .opencode/memory/review_rules.md .opencode/memory/testing_rules.md

# 4. 确认 CodeGraph MCP 已配置
grep '"codegraph"' opencode.json

# 5. 确认 Graphify 插件可读
test -r .opencode/plugins/graphify.js
```
