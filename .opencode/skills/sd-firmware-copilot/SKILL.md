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

> 所有 AI 输出 MUST 先通过 Superpowers 四条铁律（TDD + 根因调试 + 验证完成 + 未审查不合并）再输出。

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
需求 → proposal.md + specs/增量
              ↓
         Proposal Gate（动机 OK）
              ↓
         CodeGraph 查询
              ↓
         design.md + tasks.md
              ↓
         Design Gate（架构 OK）
              ↓
         编码（BUILD）
              ↓
         Review Gate（代码匹配 spec）
              ↓
         Archive Gate（归档合并）
              ↓
         baseline
```

> 详细步骤 → [openspec-workflow](../openspec-workflow/SKILL.md)。每个门禁都有对应工件（`proposal.md` / `design.md` / `tasks.md`，加上 `specs/` 增量作为第 4 个产出）。

### 必须遵守

- **代码优先**：`Source Code > Design Docs > Specs > Memory > Prompt`
- **小任务原则**：每次变更 200-500 行
- **修改前必查 CodeGraph**：`codegraph explore` 确认影响范围
- **只读文件不修改**：测试框架、构建脚本、适配层
- **cscope 补充**（函数指针 / 宏 / 头文件包含）— CodeGraph 基于 AST，cscope 补盲区

## KNOW 阶段

进入 PLAN 前必须完成：

1. `bash verify.sh` — 环境就绪
2. `graphify update .` — 知识图谱最新
3. CodeGraph 探索 — 影响范围明确
4. **读取 `.opencode/memory/` 全部规则文件** — 架构、并发、风格、设计、审查、测试共 6 个约束文件

---

## BUILD 阶段

### 前置检查

1. `tasks.md` 所有 Task 就绪，blockedBy 解析
2. CodeGraph 探索完成（影响范围明确）
3. 理解现有代码模式（错误处理、并发、日志）

### 实现流程 — 强制加载 Superpowers

> **🚨 在写第一行代码前**加载 `superpowers` 主框架及其子 skill（通过 `skill()` 工具逐一显式加载）：
> 1. `skill(name="superpowers")` — 加载框架决策表
`skill(name="superpowers-executing-plans")` — 按 tasks.md 顺序，逐条勾选
`skill(name="superpowers-verification-before-completion")` — 完成前验证命令 + 读输出
`skill(name="superpowers-subagent-driven-development")` 或 `skill(name="superpowers-dispatching-parallel-agents")` — 多任务/并行调度（按需）
`skill(name="superpowers-test-driven-development")` — Path A 纯逻辑 / Path B 硬件依赖（按需）
> 缺一（上述 2-3）= 铁律失效。触发场景 → [本 skill §Superpowers 框架整合](#superpowers-框架整合)。

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
- 硬件依赖验证（如 QEMU 运行时测试）：若 KVM/root/硬件环境暂不可用，编译通过 + `verify.sh` 可视作阶段验证完成，待环境就绪后补测

## FEEDBACK 阶段

### 审查前 — 强制加载

> 1. `skill(name="superpowers")` — 加载主框架
`skill(name="superpowers-requesting-code-review")` — 发起正式审查
`skill(name="superpowers-verification-before-completion")` — 确保验证命令可跑
`skill(name="superpowers-receiving-code-review")` — 接收反馈时用
> 5. 收集所有已变更文件的 CodeGraph 影响数据。

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

1. `skill(name="superpowers-receiving-code-review")` — 接收反馈时用
2. 分类：严重 → 设计 → 代码质量 → 可选
3. 先止血后修复：严重问题立即解决；设计问题走 openspec
4. 每个修复经 `tests/unit/` 验证

### 审查后

- `skill(name="superpowers-finishing-a-development-branch")` — 清理并合并分支
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

### 四级门禁（Proposal → Design → Review → Archive）

每个变更必须经过四级门禁。每级门禁有**输入工件**、**通过标准（Checklist）**、**校验命令**、**人工确认点**。

#### 简化豁免规则

| 变更类型 | 豁免门禁 | 仍需执行 |
|----------|----------|----------|
| 单文件 bugfix | Proposal Gate（人工确认即可） | Design Gate（简述影响范围）、Review Gate、Archive Gate |
| 文档/注释/配置变更 | Proposal Gate、Design Gate | Review Gate（文档 review）、Archive Gate（如影响 spec） |
| 跨模块重构 | 无豁免 | 完整四级门禁 + CodeGraph 影响分析 |

---

#### Proposal Gate（动机 OK）

**输入工件**：`openspec/changes/{id}/proposal.md`

**Checklist**：
- [ ] 变更动机清晰：解决什么问题、带来什么价值
- [ ] 范围明确：修改哪些 capability、不修改哪些
- [ ] 与基线 specs 的关系明确：ADDED / MODIFIED / REMOVED 哪个 Requirement
- [ ] 非目标（Non-goals）已声明
- [ ] 适用的 Superpowers 铁律已声明（TDD / 根因调试 / 验证完成）
- [ ] 预估任务数 ≤ 5 个（每个 200-500 行）

**校验命令**：
```bash
openspec status --change "<name>" --json | jq '.applyRequires.proposal == "done"'
```

**人工确认**：AI 完成 proposal.md 后，提示用户审阅动机和范围。

---

#### Design Gate（架构 OK）

**输入工件**：`openspec/changes/{id}/design.md` + `openspec/changes/{id}/tasks.md`

**Checklist**：
- [ ] CodeGraph 影响分析完成：修改的函数/文件的 callers、callees、blast radius
- [ ] 模块边界遵守：不跨层调用、不反向依赖（见 `memory/design_rules.md`）
- [ ] 并发安全评估完成：涉及共享状态变更时，锁策略已定义
- [ ] 错误处理路径已设计：每个新增错误码有传播路径和恢复策略
- [ ] OpenSpec delta 计划明确：哪个 capability 的 spec.md 接收 ADDED/MODIFIED/REMOVED
- [ ] tasks.md 每个任务有：关联 spec Requirement、测试计划、验证命令
- [ ] 任务粒度 200-500 行/任务，blockedBy 关系无循环

**校验命令**：
```bash
openspec status --change "<name>" --json | jq '.applyRequires.design == "done" and .applyRequires.tasks == "done"'
```

**人工确认**：AI 完成 design.md 和 tasks.md 后，提示用户审阅架构决策和任务分解。

---

#### Review Gate（代码匹配 spec）

**输入工件**：编码完成的代码变更 + `openspec/changes/{id}/review.md`

**Checklist**：
- [ ] 代码匹配 design.md 中的设计（无未经批准的架构变更）
- [ ] 代码匹配 OpenSpec delta（每个代码变更对应一个 spec Requirement）
- [ ] 测试覆盖：Path A（纯逻辑）有失败测试→通过测试的完整记录；Path B（硬件依赖）有编译通过记录
- [ ] Memory 规则检查通过：命名规范、并发规则、错误处理（见 `memory/*.md`）
- [ ] CodeGraph 查询验证：修改的符号影响范围与设计阶段一致
- [ ] 无回归：现有测试/编译全部通过
- [ ] review.md 已填写：审查人、审查意见、修改记录

**校验命令**：
```bash
# 1. 验证 spec 与代码一致性
openspec validate --strict --changes

# 2. 编译验证（Path B）
make clean && make -j$(nproc)

# 3. 测试验证（Path A）
make test

# 4. 代码风格检查（如有配置）
```

**人工确认**：
- AI 不能自批自审。必须由人类审查员批准。
- AI 负责准备 review.md（审查材料、测试报告、CodeGraph 影响摘要），提交审查请求。
- 人类审查员确认后，AI 才能进入 Archive Gate。

---

#### Archive Gate（归档合并）

**输入工件**：`openspec/changes/{id}/` 下所有 artifacts + review.md

**Checklist**：
- [ ] 所有 artifact 已完成（proposal/design/tasks/specs/review）
- [ ] tasks.md 所有任务已勾选 `- [x]`
- [ ] OpenSpec delta 已合并到基线（`/opsx:sync` 完成）
- [ ] 归档目录格式正确：`openspec/changes/archive/YYYY-MM-DD-{id}/`
- [ ] 归档 commit 格式：`chore(spec): archive {change-id}`

**校验命令**：
```bash
# 1. 检查 artifact 完成度
openspec status --change "<name>" --json | jq '.applyRequires | to_entries | all(.value == "done")'

# 2. 检查任务勾选数
grep -c '^\- \[x\]' openspec/changes/{id}/tasks.md

# 3. 验证基线合并后 specs 有效
openspec validate --strict --specs
```

**人工确认**：AI 提示用户确认归档，用户确认后执行 `mv` 和 `git commit`。

> **详细步骤** → [openspec-workflow/SKILL.md § archive](../openspec-workflow/SKILL.md)。

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

## Superpowers 框架整合

本 skill 是 zsf 的"sole integrating skill"。下层 Superpowers 14 个 sub-skill 协同工作：4 条 Iron Rules 强制执行，Bootstrap 决策表告诉 AI 在哪种场景下加载哪个 sub-skill，阶段转换触发器串联四阶段闭环。

### Iron Rules（4 条，不可妥协）

- **NO COMPLETION CLAIMS WITHOUT FRESH VERIFICATION EVIDENCE** — 完成前必须实际运行测试/编译/命令并验证结果，禁止「应该没问题」。见 [`superpowers-verification-before-computation`](../superpowers-verification-before-completion/SKILL.md)。
- **NO PRODUCTION CODE WITHOUT VERIFICATION** — 纯逻辑代码（Path A）先写失败测试再写实现；硬件依赖代码（Path B）BUILD 阶段编译通过，FEEDBACK 阶段系统测试。见 [`superpowers-test-driven-development`](../superpowers-test-driven-development/SKILL.md)。
- **NO FIXES WITHOUT ROOT CAUSE INVESTIGATION FIRST** — 复现、读错误、查变更、形成假设、最小验证，禁止凭直觉打补丁。见 [`superpowers-systematic-debugging`](../superpowers-systematic-debugging/SKILL.md)。
- **NO MERGE WITHOUT CODE REVIEW** — 每个非平凡变更必须经正式审查，接收反馈以技术为准不表演性认同。见 [`superpowers-requesting-code-review`](../superpowers-requesting-code-review/SKILL.md) 与 [`superpowers-receiving-code-review`](../superpowers-receiving-code-review/SKILL.md)。

### Bootstrap 决策表（场景 → 必加载 skill）

| 触发场景 | 必加载 skill | 缺失后果 |
|----------|-------------|----------|
| 会话开始 / 收到新需求 | `superpowers-using-superpowers` | 上下文无纪律约束 |
| 涉及 bug、test failure、异常行为 | `superpowers-systematic-debugging` | 凭直觉打补丁 |
| 写生产代码（Path A 纯逻辑 / Path B 硬件依赖） | `superpowers-test-driven-development` | 无失败测试、无回归保护 |
| 进入 BUILD 阶段 | `superpowers-executing-plans` + `superpowers-verification-before-completion` | 跳过任务、跳过验证 |
| 复杂任务（多文件、多模块） | `superpowers-subagent-driven-development` | 上下文爆炸、需求漂移 |
| 2+ 独立可并行任务 | `superpowers-dispatching-parallel-agents` | 串行浪费 |
| 合并前 / 用户说「review my work」 | `superpowers-requesting-code-review` | AI 自批自审 |
| 收到审查反馈 | `superpowers-receiving-code-review` | 表演性认同 / 盲目实现 |
| 所有任务完成，准备合并 | `superpowers-finishing-a-development-branch` | 直接合并不清理 |
| 宣称「完成 / 修复 / 通过」 | `superpowers-verification-before-completion` | 无证据断言 |
| 写计划（5+ 步骤任务） | `superpowers-writing-plans` | 无 plan 直接 coding |
| 写新 skill | `superpowers-writing-skills` | 不符合 agentskills.io 规范 |
| 复杂/创造性问题 | `superpowers-brainstorming` | 需求理解偏差 |
| 隔离工作区 | `superpowers-using-git-worktrees` | 主分支污染 |

### 阶段转换触发器（4 阶段闭环）

| 阶段转换 | 应读取并遵循 |
|----------|-------------|
| **KNOW → PLAN** | `openspec-workflow` 概念层 + 具体 phase skill（propose / explore） |
| **PLAN → BUILD** | `superpowers-test-driven-development` + `superpowers-executing-plans` + `superpowers-verification-before-completion` |
| **BUILD → FEEDBACK** | `superpowers-requesting-code-review` |
| **FEEDBACK → Archive** | `superpowers-finishing-a-development-branch` |

### Red-line 自检（每次动作前问自己）

- [ ] 即将「声称完成」？→ 使用 `superpowers-verification-before-completion` 并实际跑命令
- [ ] 即将「修 bug」？→ 使用 `superpowers-systematic-debugging` 并完成根因调查
- [ ] 即将「写生产代码」？→ 使用 `superpowers-test-driven-development` 并按 Path A/B 走
- [ ] 即将「合并」？→ 使用 `superpowers-requesting-code-review` 并完成 Review Gate

### Skill map 速查（14 sub-skill）

| Sub-skill | 何时调用 |
|-----------|----------|
| `superpowers-using-superpowers` | 任何会话开始 |
| `superpowers-brainstorming` | 创意/需求探索 |
| `superpowers-writing-plans` | 5+ 步骤任务前写 plan |
| `superpowers-writing-skills` | 写新 skill 前 |
| `superpowers-test-driven-development` | 写新功能 / 修 bug 前 |
| `superpowers-systematic-debugging` | 任何 bug / test failure / 异常行为 |
| `superpowers-verification-before-completion` | 任何"完成"声明前 |
| `superpowers-executing-plans` | 按 plan 顺序执行 |
| `superpowers-subagent-driven-development` | 多文件复杂 plan 配 review |
| `superpowers-dispatching-parallel-agents` | 2+ 独立并行任务 |
| `superpowers-requesting-code-review` | 合并前 / 完成后 |
| `superpowers-receiving-code-review` | 收到审查反馈时 |
| `superpowers-finishing-a-development-branch` | 全部完成准备集成 |
| `superpowers-using-git-worktrees` | 隔离工作区 |

## 初始化

```bash
bash verify.sh                                                       # 环境检查
OPENSPEC_TELEMETRY=0 openspec validate --strict --specs              # 基线有效
ls .opencode/memory/{architecture,concurrency_rules,coding_style,design_rules,review_rules,testing_rules}.md
grep '"codegraph"' opencode.json && test -r .opencode/plugins/graphify.js
```
