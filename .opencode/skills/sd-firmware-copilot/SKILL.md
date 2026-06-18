---
name: sd-firmware-copilot
description: SSD 固件 AI 编程助手，基于四阶段闭环（KNOW→PLAN→BUILD→FEEDBACK）和两层架构（Superpowers 工程纪律 + SSD 固件领域知识）。BUILD 和 FEEDBACK 阶段委托 Superpowers；PLAN 和规格管理委托 openspec-workflow。
compatibility: Requires OpenSpec CLI (v1.4.1+), CodeGraph MCP, Graphify plugin.
metadata:
  author: zsf
  version: "1.0"
---

# SSD 固件 AI Copilot

SSD 固件开发的 AI 编程 Copilot。只做 SSD 固件开发任务。每个 TODO 可跟踪；每个决策都有 OpenSpec 工件。

> 所有 AI 输出 MUST 先通过 Superpowers 铁律（TDD + 根因调试 + 验证完成）再输出。

## 快速入口

| 场景 | 流程 |
|------|------|
| 有设计文档 | 按「核心流程」完整执行 |
| 无设计文档 | `codegraph explore <区域>` 生成 `design.md`，再执行 |
| 代码审查 | 按「FEEDBACK 阶段」执行 |
| 规格变更 | [openspec-workflow](../openspec-workflow/SKILL.md) |

**触发词**：`sd-firmware`、`ssd`、`femu`、`nand-controller`、`nvme`，或路径包含 `hw/femu/`。

## 核心流程

```
需求 → proposal.md → specs/增量 → Design Gate → CodeGraph查询 → design.md → tasks.md
                                    ↓                                              ↓
                               Proposal Gate                               Review Gate → review.md
                                                                                 ↓
                                                                           归档合并 → baseline
```

> 详细步骤 → [openspec-workflow](../openspec-workflow/SKILL.md)。每个门禁都有对应工件（`proposal.md` / `design.md` / `tasks.md`，加上 `specs/` 增量作为第 4 个产出）。

### 必须遵守

- **代码优先**：`Source Code > Design Docs > Specs > Memory > Prompt`
- **小任务原则**：每次变更 200-500 行
- **修改前必查 CodeGraph**：`codegraph explore` 确认影响范围
- **只读文件不修改**：测试框架、构建脚本、适配层
- **cscope 补充**（函数指针 / 宏 / 头文件包含）— CodeGraph 基于 AST，cscope 补盲区

## BUILD 阶段

### 前置检查

1. `tasks.md` 所有 Task 就绪，blockedBy 解析
2. CodeGraph 探索完成（影响范围明确）
3. 理解现有代码模式（错误处理、并发、日志）

### 实现流程 — 强制加载 Superpowers

> **🚨 在写第一行代码前**通过 skill tool 加载：`test-driven-development`（Path A 纯逻辑 / Path B 硬件依赖）→ `executing-plans`（按 tasks.md 顺序）→ `subagent-driven-development` 或 `dispatching-parallel-agents` → `verification-before-completion`。缺一 = 铁律失效。触发场景 → [superpowers/SKILL.md §Bootstrap 决策表](../superpowers/SKILL.md)。

### 子代理调度策略

| 用例 | 策略 |
|------|------|
| 单一文件修改 | `subagent-driven-development`（单代理集中） |
| 独立并行任务 | `dispatching-parallel-agents`（最多 5 并行） |
| 代码生成 | 直接生成（Simple Agent） |
| 复杂逻辑 | `ultrabrain` — 提供目标而非步骤 |

**调度契约**：提示词必须完整（代码模式、错误处理、并发约束）；不跳过 task 步（tasks.md 是合同）；不扩大需求（不在代码生成时添加额外功能）；人负责架构设计与风险判断。

### BUILD 关键约束

- 不创建多余 stub/skeleton 文件
- 不修改只读文件
- 代码在 `src/`，单元测试在 `tests/unit/`
- 禁止：`as any`、`@ts-ignore`、空 catch、抑制类型错误
- 变量/函数名用英文，注释/文档用中文

## FEEDBACK 阶段

### 审查前 — 强制加载

> 加载 `requesting-code-review`（发起正式审查）→ `verification-before-completion`（确保验证命令可跑）→ `receiving-code-review`（接收反馈时用）。收集所有已变更文件的 CodeGraph 影响数据。

### 审查内容

**通用检查**（委托 Superpowers `requesting-code-review`）：逻辑错误、边界条件、潜在崩溃、设计对齐。

**SSD 固件专项**：

- **NAND 控制器**：ECC 页大小、坏块、写入缓存对齐
- **NVMe 命令**：队列管理、PRP/SGL 完整性、Admin/IO 命令生命周期
- **FTL 映射**：映射表一致性、磨损均衡、GC 安全
- **错误处理**：超时、重试、断电/崩溃恢复、数据完整性
- **并发安全**：共享状态并发原语；中断/线程安全
- **宏和预处理器**：条件编译块正确性

### 接收反馈

1. 加载 `receiving-code-review`
2. 分类：严重 → 设计 → 代码质量 → 可选
3. 先止血后修复：严重问题立即解决；设计问题走 openspec
4. 每个修复经 `tests/unit/` 验证

### 审查后

- `finishing-a-development-branch`：清理并合并分支
- 所有严重和设计问题验证通过
- 归档审查结果和修复记录

**关键约束**：AI 不能批准自己代码（人审批）；重复模式提出重构但需批准后执行。

## Spec 规则

SSD 固件规格层规则。基于 OpenSpec CLI 实现，zsf 注入 SSD 域知识（基线查询优先级、CodeGraph 协同、200-500 行任务粒度）。

### 规格层定位

规格层独立于约束层（Memory）和基础设施层（CodeGraph），是「系统当前行为」的权威描述。

```
┌─────────────────────────────────────────┐
│  规格层 (OpenSpec)  — 当前行为的权威描述  │  openspec/specs/<cap>/spec.md
├─────────────────────────────────────────┤
│  约束层 (Memory)    — 规则、风格、知识     │  .opencode/memory/*.md
├─────────────────────────────────────────┤
│  基础设施层 (CodeGraph/cscope/Graphify)  │
├─────────────────────────────────────────┤
│  流程层 (Skills)      — 开发/审查流程     │  .opencode/skills/
└─────────────────────────────────────────┘
```

**Memory ≠ Spec**：Memory 是约束（"必须遵守什么"），Spec 是行为（"系统当前做什么"），独立演进。

### 目录结构

```
openspec/
├── config.yaml
├── specs/                          # 已归档的活基线
│   └── <capability>/spec.md
└── changes/                        # 进行中的变更
    └── {change-id}/
        ├── .openspec.yaml
        ├── proposal.md
        ├── specs/<capability>/spec.md  # Delta: ## ADDED / MODIFIED / REMOVED
        ├── design.md                   # 含 CodeGraph 查询结果
        └── tasks.md                    # 200-500 行/任务
```

**基线位置**：`openspec/specs/{ssd-firmware-overview, nvme-commands, ftl-mapping, nand-driver, error-handling}/spec.md`。

### 基线规格管理

每个 `spec.md` 包含：`## Purpose`（≥ 50 字符）+ `## Requirements`（`### Requirement: <name>`）+ `#### Scenario: <name>`（强制 4 个 `#`）使用 `**WHEN**` / `**THEN**`。规范词 SHALL / MUST，避免 should / may。

**基线更新**：Review Gate 通过后 `/opsx:archive`（OpenSpec 自动合并 delta → `openspec/specs/`，ADDED 追加 / MODIFIED 替换 / REMOVED 删除；`openspec/changes/<id>/` 移至 `archive/`，不删除；commit `chore(spec): archive <change-id>`）。

**基线查询优先级**：`openspec/specs/<cap>/spec.md` → CodeGraph 局部验证 → 读代码。CLI：`openspec spec list` / `openspec spec show <cap>`。

**Delta 格式**（3 类 header + 强制 4 个 `#`）：

```markdown
## ADDED Requirements
### Requirement: <name>
The <layer> SHALL <behavior>.
#### Scenario: <name>
- **WHEN** <condition>
- **THEN** <expected outcome>
```

- **MODIFIED Requirements**：复制 baseline 整个 `### Requirement:` 块（含所有 Scenario），头文本必须与原 Requirement 完全一致（不一致 = 归档丢失细节）。
- **REMOVED Requirements**：`### Requirement: <name>` + `**Reason**:` + `**Migration**:`。

**3 个不可违反的规则**：(1) Scenario 强制 4 个 `#`（3 个 `#` 静默失败）；(2) 规范词 SHALL / MUST，避免 should / may；(3) 每个 Scenario 必须是潜在测试用例。

**四级门禁**（Proposal → Design → Review → Archive） → 详见 [openspec-workflow/SKILL.md § Five-Stage Workflow](../openspec-workflow/SKILL.md)。**简化规则**：单文件 bugfix 跳 Proposal 人工；文档/注释跳全部门禁；其他完整流程。

### 跨规则关系

| 规则 | 关系 |
|------|------|
| `memory/design_rules.md` | 四级门禁统一定义 |
| `memory/{review,testing,architecture}_rules.md` | 门禁检查项引用 / 可验证性落地 / CodeGraph 查询 |
| `openspec-workflow/SKILL.md` | CLI 与 zsf 流程衔接 |
| 本 Skill BUILD 阶段 | 开发工件对应规格层 |

## 规则与知识

**Memory 规则**（`.opencode/memory/`）：`architecture` / `concurrency_rules` / `coding_style` / `design_rules` / `review_rules` / `testing_rules`。

**硬件知识**：NVMe Admin/IO 命令、NAND 设备管理（ECC/坏块/写入放大/磨损均衡）、固件更新（安全下载/回滚/原子性）、IO 调度（读/写优先级/QoS）→ 详见 `openspec/specs/` 各 capability。

## 初始化

```bash
bash verify.sh                                                       # 环境检查
OPENSPEC_TELEMETRY=0 openspec validate --strict --specs              # 基线有效
ls .opencode/memory/{architecture,concurrency_rules,coding_style,design_rules,review_rules,testing_rules}.md
grep '"codegraph"' opencode.json && test -r .opencode/plugins/graphify.js
```
