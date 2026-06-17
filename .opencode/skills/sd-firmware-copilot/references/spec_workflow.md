# Spec Workflow Reference

OpenSpec 是 SSD 固件规格驱动开发的事实标准。本文档描述 zsf 工作流如何与 OpenSpec CLI 协作——OpenSpec 负责工件（proposal / specs / design / tasks）的结构、校验和归档，zsf 在每个工件中注入 SSD 固件域知识（CodeGraph 查询、并发安全、基线查询优先级、200-500 行任务粒度、三级门禁）。

**核心变化**：原本手刻的 `proposal.md` / `design.md` / `tasks.md` / `review.md` / `specs/{ADDED,MODIFIED,REMOVED}.md` 模板不再手动维护，OpenSpec CLI 接管工件结构与校验。zsf 流程专注于工件内容中的 SSD 域规则。

---

## 1. OpenSpec 目录结构与 CLI 速查

### 1.1 OpenSpec 目录布局

```text
openspec/
├── AGENTS.md                    # OpenSpec 注入给 AI 的指令（自动生成）
├── config.yaml                  # schema: spec-driven + 项目上下文
├── specs/                       # 已通过归档合并的活基线（READ-ONLY 派生）
│   ├── ssd-firmware-overview/
│   ├── nvme-commands/
│   ├── ftl-mapping/
│   ├── nand-driver/
│   └── error-handling/
└── changes/                     # 进行中的变更（每个目录 = 一个 change）
    └── {change-id}/
        ├── .openspec.yaml       # 变更元数据
        ├── README.md            # 变更说明
        ├── proposal.md          # /opsx:propose 生成
        ├── specs/               # /opsx:propose 生成（delta 格式）
        │   ├── <capability>/spec.md  # ADDED / MODIFIED / REMOVED
        │   └── ...
        ├── design.md            # /opsx:propose 生成
        └── tasks.md             # /opsx:propose 生成
```

### 1.2 核心 CLI 命令

| 命令 | 用途 |
|------|------|
| `openspec init` | 在项目根目录初始化 OpenSpec（生成 `openspec/` 与 OpenCode 集成） |
| `openspec new change <id>` | 创建新变更目录（含 `.openspec.yaml` 与 `README.md`） |
| `/opsx:propose` | 生成 proposal + specs + design + tasks 全部工件 |
| `/opsx:apply` | 按 tasks.md 逐项实现代码 |
| `/opsx:archive` | 归档变更：将 deltas 合并到 `openspec/specs/` 基线 |
| `openspec validate --strict` | 严格校验所有 specs / changes |
| `openspec validate --strict --specs` | 仅校验基线 specs |
| `openspec validate --strict --changes` | 仅校验进行中的 changes |
| `openspec list` | 列出所有进行中的 changes |
| `openspec show <id>` | 查看某个 change 或 spec 的内容 |
| `openspec spec list` | 列出所有基线 specs |

### 1.3 旧版 `.openspec/` 的迁移

旧版手刻工件存放在 `.openspec/proposals/{change-id}/{proposal,design,tasks,review}.md`。新版本统一由 OpenSpec CLI 接管，目录变更为 `openspec/changes/{change-id}/`。**旧目录可保留作为历史审计，但不再生成新内容**。

---

## 2. Proposal 阶段 → `/opsx:propose`

### 2.1 职责

`/opsx:propose` 一次生成 proposal.md + specs/*.md（deltas）+ design.md + tasks.md 全部工件，AI 在 OpenSpec 指令引导下填充 zsf 域知识。

### 2.2 触发与流程

```bash
# 1. 创建变更目录
openspec new change <change-id> --description "<一句话变更意图>"

# 2. 进入变更目录，启动 OpenSpec 提案（OpenCode IDE slash command）
#    IDE 中输入: /opsx:propose "<详细意图>"
#    AI 会读取 openspec/AGENTS.md + openspec/changes/<change-id>/ 并生成 4 个工件

# 3. 校验（AI 自检 + 人工抽查）
openspec validate --strict --changes
```

### 2.3 zsf 域注入（AI 在 proposal 阶段必须回答）

| 字段 | zsf 域要求 |
|------|-----------|
| Why | 引用 `openspec/specs/<related-capability>/spec.md` 中的相关 Requirement 作为现状；说明本次变更的动机与对系统行为的改变 |
| What Changes | 列出新增 / 修改 / 移除的 capabilities；**破坏性变更必须标记 `**BREAKING**`** |
| Capabilities (New) | 命名规范：kebab-case（如 `ftl-slc-folding`、`nvme-sanitize`） |
| Capabilities (Modified) | 必须在 `openspec/specs/` 中存在；列出受影响的 Requirement ID |
| Impact | 列出潜在影响模块：NVMe / FTL / NAND / 错误处理；用 CodeGraph 预查（callers/impact）记录关键调用链 |
| 验收标准 | 每个验收点必须可在 review 阶段通过 `openspec validate --strict` + CodeGraph 查证 + 测试场景覆盖来核对 |

### 2.4 简化场景

| 变更类型 | 是否可跳过 proposal | 必需工件 |
|---------|--------------------|---------|
| 单文件 bugfix（影响范围明确） | ✅ 跳过 `proposal.md`，但仍可走 `/opsx:propose` | `/opsx:propose` 全部 4 个工件即可 |
| 文档 / 注释更新 | ✅ 跳过 OpenSpec | 无 |
| 配置变更（无逻辑影响） | ✅ 跳过 `proposal.md` | tasks.md |
| 新功能 / 重构 / 接口变更 | ❌ 必须完整流程 | 全部 4 个工件 |
| 跨模块变更 | ❌ 必须完整流程 + 额外 Review | 全部 4 个工件 + 双人 Review |

---

## 3. Specs 增量格式（OpenSpec Delta 规范）

### 3.1 OpenSpec Delta 格式

OpenSpec 增量以 `## ADDED Requirements` / `## MODIFIED Requirements` / `## REMOVED Requirements` 三个 `##` 级 header 标识，每条 Requirement 包含：

- `### Requirement: <name>`（3 个 `#`）
- 描述文本（使用 SHALL / MUST 等规范性词）
- `#### Scenario: <name>`（4 个 `#`）—— **必须使用 4 个 `#`，3 个 `#` 或列表会导致静默失败**
- Scenario 用 `**WHEN**` / `**THEN**` 描述

### 3.2 完整示例

```markdown
## ADDED Requirements

### Requirement: FTL MUST fold SLC blocks when full
The FTL SHALL migrate data from SLC blocks to TLC blocks when SLC free block count falls below the configured threshold.

#### Scenario: SLC threshold reached
- **WHEN** SLC free block count < threshold
- **THEN** the FTL MUST pick a victim SLC block
- **AND THEN** it MUST copy valid pages to a free TLC block
- **AND THEN** it MUST erase the victim SLC block and return it to the free pool

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

## REMOVED Requirements

### Requirement: Legacy pblock allocation
**Reason**: Replaced by SLC-aware allocation policy
**Migration**: All write paths use the new SLC allocation logic
```

### 3.3 zsf 域规范（与 OpenSpec 一致 + 域增强）

- **规范词**：使用 SHALL / MUST，**避免** should / may
- **可验证性**：每个 Scenario 必须是潜在测试用例（参见 `.opencode/memory/testing_rules.md`）
- **不写代码**：delta 描述「系统做什么」，不描述「代码怎么写」
- **可追溯性**：每条 delta 对应一个或多个 `tasks.md` 中的任务项
- **基线查询**：写 delta 前先读 `openspec/specs/<capability>/spec.md` 确认基线行为，避免无谓的 MODIFIED

### 3.4 MODIFIED 要求的特殊处理

OpenSpec 对 MODIFIED Requirement 的处理：

1. 在 `openspec/specs/<capability>/spec.md` 中找到原有 Requirement
2. **复制整个 Requirement 块**（从 `### Requirement:` 到所有 Scenario）
3. 粘贴到 delta 文件的 `## MODIFIED Requirements` 下
4. 编辑内容以反映新行为
5. 头文本必须与原有 Requirement 完全一致（whitespace-insensitive）

> **常见陷阱**：使用 MODIFIED 时只写部分内容会导致归档时丢失细节。如新增关注点不改变现有行为，使用 ADDED 而非 MODIFIED。

---

## 4. Design 阶段 → OpenSpec `design.md`

### 4.1 职责

`design.md` 由 `/opsx:propose` 自动生成，AI 在 OpenSpec 引导下填充内容。zsf 域要求 design.md 必须包含 **CodeGraph 查询结果** 与 **待人工确认清单**——这两项是 zsf Design Gate 的强制输入。

### 4.2 zsf 域注入（AI 在 design 阶段必须执行）

#### 4.2.1 CodeGraph 查询（强制）

修改任何代码前，必须先执行以下查询并把结果粘贴到 design.md 的对应章节：

```bash
# 必查 4 项
codegraph impact <symbol>       # 影响范围（函数 / 结构体 / 宏）
codegraph callers <symbol>      # 谁调用了
codegraph find_by_imports <header>  # 头文件 include 影响
codegraph get_dependency_graph  # 模块边界 / 循环依赖
```

#### 4.2.2 cscope 补充（函数指针 / 宏场景）

```bash
cscope -d -L2 "<func_ptr>"      # 函数指针调用者
cscope -d -L3 "<func_ptr>"      # 函数指针指向
cscope -d -L4 "<MACRO>"         # 宏使用位置
cscope -d -L8 "<header.h>"      # 谁包含了这个头文件
```

> CodeGraph 在函数指针 / 宏场景有盲区，cscope 是强制补充。

#### 4.2.3 待人工确认清单（Design Gate 输入）

design.md 必须包含以下清单，人工逐条确认才能进入 Coding 阶段：

1. 架构假设是否正确？
2. CodeGraph 查询是否完整？（是否覆盖所有调用者和依赖？）
3. 是否有更简单的替代方案？
4. tasks.md 粒度是否合适（200-500 行/任务）？
5. 并发 / 资源 / 错误路径是否已考虑？（参见 `memory/concurrency_rules.md`）
6. 模块边界是否违反？（参见 `memory/architecture.md`）
7. specs/ delta 是否覆盖所有变更？（参见 `openspec/changes/<id>/specs/`）

### 4.3 简化场景

单文件 bugfix 的 design.md 可精简为仅含「架构假设」和「CodeGraph 查询结果」两个字段。

---

## 5. Tasks 阶段 → OpenSpec `tasks.md`

### 5.1 职责

`tasks.md` 由 `/opsx:propose` 自动生成，AI 在 OpenSpec 引导下填充任务清单。zsf 的 **200-500 行/任务** 小任务原则在 tasks.md 中以「预期行数」字段强制表达。

### 5.2 zsf 域注入

| 字段 | 约束 |
|------|------|
| 任务粒度 | 每个任务 200-500 行（与 zsf 小任务原则一致） |
| 依赖 | 任务间依赖关系显式标注（前序任务 ID） |
| 可独立验证 | 每个任务必须有自己的测试场景（参见 `.opencode/memory/testing_rules.md`） |
| 不扩大需求 | 任务清单严格对应 proposal.md 中的 What Changes；不接受范围蔓延 |
| 与 spec 增量对应 | 每个任务项至少对应一条 `specs/` delta 中的 Scenario |

### 5.3 任务执行流程

```bash
# 1. 进入 Apply 阶段（OpenCode IDE slash command）
#    IDE 中输入: /opsx:apply
#    AI 按 tasks.md 逐项实现，每完成一项标记 [x]

# 2. 任务执行中持续校验
openspec validate --strict --changes

# 3. CodeGraph 影响范围查证（Design 中记录的影响 vs 实际改动）
```

---

## 6. Review 阶段 → 查证式验证

### 6.1 职责

Review 阶段是 **查证式验证**（不重新查询 CodeGraph），对照 design.md 中记录的 CodeGraph 结果验证代码变更是否在预期范围内。

### 6.2 Review 检查项

| 检查项 | 验证方法 | 风险等级 |
|--------|---------|---------|
| 空指针 | 查 review.md + 静态分析 | 高 |
| 数组越界 | 查 review.md + 静态分析 | 高 |
| 资源泄漏 | valgrind / asan | 高 |
| 竞态条件 | 对照 `memory/concurrency_rules.md` + 重新阅读并发代码 | 高 |
| 死循环 | 静态分析 + 状态机审查 | 中 |
| 模块边界违反 | CodeGraph import 关系 | 中 |
| 接口兼容性 | 对照 baseline spec | 中 |
| 函数指针调用遗漏 | cscope -L2 / -L3 | 中 |
| **CodeGraph 影响范围查证** | 对照 design.md vs 实际 diff | 高 |
| **specs/ delta 覆盖** | 对照 tasks.md vs openspec/changes/<id>/specs/ | 高 |
| **`openspec validate --strict` 通过** | CI / 命令行 | 强制 |

### 6.3 Review 工具

```bash
# 校验 OpenSpec 工件
openspec validate --strict --changes

# 查证 CodeGraph 影响（仅在 design.md 查证发现偏差时）
codegraph impact <symbol>

# 函数指针 / 宏补充
cscope -d -L2 "<func_ptr>"

# 基线对比
openspec show <capability>
```

### 6.4 Review 输出

Review 输出不再使用手刻的 `review.md`。改为：

1. 在 PR / Change 中以评审评论形式记录（人工 + AI）
2. 关键问题记录到 `openspec/changes/<id>/design.md` 的「Review Notes」追加段落（由 AI 在 `/opsx:apply` 完成后追加）
3. **绝不** 重新写手刻 review.md 模板

---

## 7. 归档阶段 → `/opsx:archive`

### 7.1 归档时机

Review Gate 全部检查项通过 + `openspec validate --strict` 全部通过后执行归档。

### 7.2 归档流程

```bash
# OpenCode IDE slash command
#    IDE 中输入: /opsx:archive
#    AI 会自动：
#    1. 验证所有 change 工件
#    2. 将 openspec/changes/<id>/specs/*.md 的 deltas 合并到 openspec/specs/
#    3. 生成 commit: chore(spec): archive <id>
#    4. 移动 openspec/changes/<id>/ → openspec/changes/archive/

# 等效 CLI
openspec archive <change-id>
```

### 7.3 合并原则

- **ADDED → 追加**：将 `## ADDED Requirements` 合并到 `openspec/specs/<capability>/spec.md` 的 `## Requirements` 末尾
- **MODIFIED → 替换**：将 `## MODIFIED Requirements` 中同名 Requirement 替换基线中的对应 Requirement
- **REMOVED → 删除**：将 `## REMOVED Requirements` 中列出的 Requirement 从基线中删除（含 Reason / Migration 审计信息保留在 archive）
- **冲突处理**：如 delta 与基线冲突，优先审查基线是否过时，必要时手动裁决
- **原子性**：一次归档必须完成单个 change 的全部 deltas
- **可逆性**：归档前由 Git 跟踪 openspec/ 目录，可回滚

### 7.4 历史保留

- `openspec/changes/<id>/` 目录**不删除**（自动移至 `openspec/changes/archive/`），作为变更审计历史保留
- 归档 commit message 格式：`chore(spec): archive <change-id>`
- 所有 `openspec/` 文件纳入 Git 版本管理（**`.gitignore` 中不排除** `openspec/`）

---

## 8. 三级门禁体系（zsf 增强）

OpenSpec 工件是门禁的输入，**门禁本身** 仍是 zsf 流程的核心。三级门禁（Proposal / Design / Review）的权威定义、checklist、校验命令见 `rules/spec_rules.md` §5；简化豁免规则见 §6.5。

本节补充 OpenSpec CLI 命令在门禁流程中的衔接点（与 `rules/spec_rules.md` §5 互补）：

| 阶段 | OpenSpec 命令 | 触发点 | 通过后 |
|------|--------------|--------|--------|
| Proposal Gate | `openspec validate --strict --changes` | `/opsx:propose` 完成后 | → Design 阶段 |
| Design Gate | `openspec validate --strict --changes` | design.md + tasks.md 完成后 | → `/opsx:apply` |
| Review Gate | `openspec validate --strict --changes` | 编码 + Review 后 | → `openspec archive <change-id>` |

具体人工 checklist 见 `rules/spec_rules.md` §5 各小节。

---

## 9. 与 zsf 现有流程的映射

### 9.1 替代关系

| zsf 旧手刻工件 | OpenSpec 替代 |
|---------------|---------------|
| `.openspec/proposals/<id>/proposal.md` 手刻 | `/opsx:propose` 生成 `openspec/changes/<id>/proposal.md` |
| `.openspec/proposals/<id>/design.md` 手刻 | `/opsx:propose` 生成 `openspec/changes/<id>/design.md` |
| `.openspec/proposals/<id>/tasks.md` 手刻 | `/opsx:propose` 生成 `openspec/changes/<id>/tasks.md` |
| `.openspec/proposals/<id>/specs/ADDED.md` 手刻 | `/opsx:propose` 生成 `openspec/changes/<id>/specs/<cap>/spec.md`（ADDED Requirements） |
| `.openspec/proposals/<id>/specs/MODIFIED.md` 手刻 | `/opsx:propose` 生成（MODIFIED Requirements） |
| `.openspec/proposals/<id>/specs/REMOVED.md` 手刻 | `/opsx:propose` 生成（REMOVED Requirements） |
| `.openspec/proposals/<id>/review.md` 手刻 | Review 输出在 PR 评论 + design.md 追加段落（不写手刻文件） |
| 手工合并 ADDED/MODIFIED/REMOVED 到 `.openspec/specs/baseline/` | `/opsx:archive` 自动合并到 `openspec/specs/` |
| `.openspec/specs/baseline/<module>.md` 手刻格式 | `openspec/specs/<capability>/spec.md`（OpenSpec 标准格式） |
| `chore(spec): merge <id> into baseline` commit | `chore(spec): archive <id>` commit |
| 跨 session 上下文重建（读 5 个手刻文件） | `openspec show <id>` 一条命令恢复完整上下文 |

### 9.2 不替代的部分

| zsf 现有机制 | 保持不变 |
|-------------|---------|
| CodeGraph 查询本身（Design 阶段强制） | OpenSpec 工件记录结果，不替代查询动作 |
| cscope 补充（函数指针 / 宏） | OpenSpec 工件记录结果，不替代查询动作 |
| 人工确认门禁（三级） | OpenSpec 工件作为门禁输入，门禁本身不变 |
| `memory/review_rules.md` 检查项 | Review 检查项不变，仅执行方式变为查证式 + `openspec validate --strict` |
| `memory/architecture.md` 分层规则 | 分层规则不变；OpenSpec 工件记录分层假设 |
| `memory/concurrency_rules.md` | 并发规则不变；Review 中对照检查 |
| `memory/testing_rules.md` | 测试规则不变；tasks.md 中的测试场景仍由 testing_rules.md 规范 |
| `development/skill.md` | 开发流程框架不变，融入 OpenSpec 工件 |
| 200-500 行小任务原则 | tasks.md 强制粒度约束 |

### 9.3 旧 `.openspec/` 目录的处理

旧版手刻工件（`.openspec/proposals/...` 和 `.openspec/specs/baseline/...`）保留在仓库中作为：

1. **历史审计**：已归档变更的 review 记录、合并决策不可丢弃
2. **新流程不再写入**：所有新变更走 OpenSpec CLI（`openspec/changes/<id>/`）
3. **手工迁移已完成**：5 个 baseline specs（ssd-firmware-overview / nvme-commands / ftl-mapping / nand-driver / error-handling）已迁移到 `openspec/specs/<capability>/spec.md`

---

## 10. 工具链快速参考

### 10.1 安装

```bash
npm install -g @fission-ai/openspec
openspec --version   # 应输出 1.x
```

### 10.2 项目初始化

```bash
# 在项目根目录
openspec init --tools opencode
# 生成 openspec/ + OpenCode 集成（5 个 skill + 5 个 command）
```

### 10.3 日常命令

```bash
# 查看所有进行中变更
openspec list

# 查看某个变更的完整内容
openspec show <change-id>

# 查看某个基线 spec
openspec spec show <capability>

# 严格校验
openspec validate --strict --all
openspec validate --strict --specs
openspec validate --strict --changes
openspec validate --strict <change-id>

# 创建新变更
openspec new change <change-id> --description "<意图>"

# 归档
openspec archive <change-id>
```

### 10.4 OpenCode Slash Commands（IDE 中使用）

| 命令 | 用途 |
|------|------|
| `/opsx:propose` | 生成 proposal + specs + design + tasks |
| `/opsx:apply` | 按 tasks.md 逐项实现 |
| `/opsx:archive` | 归档合并到基线 |
| `/opsx:explore` | 探索 OpenSpec 流程（教学） |
| `/opsx:sync-specs` | 同步 specs 状态 |

### 10.5 与 CodeGraph 配合

```bash
# 1. CodeGraph 查影响（在 design.md 阶段）
codegraph impact <symbol>          # → 粘贴到 design.md
codegraph callers <symbol>         # → 粘贴到 design.md
codegraph find_by_imports <header> # → 粘贴到 design.md

# 2. OpenSpec 校验（持续）
openspec validate --strict --changes

# 3. Review 查证（不重查 CodeGraph，对照 design.md 验证）
```

---

## 11. 版本兼容说明

- **Step 1**（已完成）：引入 design.md + tasks.md 两个手刻工件。
- **Step 2**（已完成）：引入 proposal.md + review.md + specs/ 增量手刻工件。
- **Step 3**（当前）：迁移到 OpenSpec CLI——手刻工件模板移除，全部由 `/opsx:propose` / `/opsx:apply` / `/opsx:archive` 生成；旧 `.openspec/proposals/` 与 `.openspec/specs/baseline/` 目录保留作为历史。
- **Step 4**（已完成）：5 个 baseline specs（ssd-firmware-overview / nvme-commands / ftl-mapping / nand-driver / error-handling）从 `.opencode/skills/sd-firmware-copilot/specs/baseline/` 迁移到 `openspec/specs/<capability>/spec.md`，全部通过 `openspec validate --strict`。
- **向后兼容**：未使用 OpenSpec CLI 的旧手刻变更仍可走 `.openspec/proposals/` 流程；所有新变更**必须**走 OpenSpec CLI。
- **渐进采用**：简单 bugfix 可使用 `/opsx:propose` 一次性生成 4 个工件；跨模块变更必须按 Proposal / Design / Review 三级门禁逐项校验。
