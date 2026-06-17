# Spec Rules

SSD 固件规格层规则。定义规格基线管理、增量追踪、门禁联动和归档合并机制。本规则基于 **OpenSpec CLI**（`@fission-ai/openspec`）实现，OpenSpec 负责工件结构、校验和归档，zsf 流程注入 SSD 固件域知识（基线查询优先级、CodeGraph 协同、200-500 行任务粒度）。

---

## 1. 规格层定位

规格层独立于约束层（Memory）和基础设施层（CodeGraph），是「系统当前行为」的权威描述。

```
┌─────────────────────────────────────────┐
│  规格层 (OpenSpec)  — 当前行为的权威描述  │  ← 本规则
│  openspec/specs/<cap>/spec.md            │
├─────────────────────────────────────────┤
│  约束层 (Memory)    — 规则、风格、知识     │  ← 不变
├─────────────────────────────────────────┤
│  基础设施层 (CodeGraph/cscope/Graphify)  │  ← 不变
├─────────────────────────────────────────┤
│  流程层 (Skills)      — 开发/审查流程     │  ← 对齐
└─────────────────────────────────────────┘
```

**Memory ≠ Spec**：
- Memory 是约束（「必须遵守什么」）
- Spec 是行为（「系统当前做什么」）
- 两者独立演进，不冲突

---

## 2. 目录结构

### 2.1 OpenSpec 目录布局

```
openspec/
├── AGENTS.md                       # OpenSpec 注入给 AI 的指令（自动生成）
├── config.yaml                     # schema: spec-driven + 项目上下文
├── specs/                          # 已通过归档合并的活基线
│   ├── ssd-firmware-overview/spec.md
│   ├── nvme-commands/spec.md
│   ├── ftl-mapping/spec.md
│   ├── nand-driver/spec.md
│   └── error-handling/spec.md
└── changes/                        # 进行中的变更（每个目录 = 一个 change）
    └── {change-id}/
        ├── .openspec.yaml          # 变更元数据
        ├── README.md               # 变更说明
        ├── proposal.md             # /opsx:propose 生成
        ├── specs/                  # /opsx:propose 生成（OpenSpec delta 格式）
        │   └── <capability>/
        │       └── spec.md         # 含 ## ADDED / ## MODIFIED / ## REMOVED Requirements
        ├── design.md               # /opsx:propose 生成（含 CodeGraph 查询结果）
        └── tasks.md                # /opsx:propose 生成（200-500 行/任务）
```

### 2.2 旧版 `.openspec/` 的处理

旧版手刻工件存放于 `.openspec/proposals/<id>/{proposal,design,tasks,review}.md` 与 `.openspec/specs/baseline/<module>.md`。**新版本统一由 OpenSpec CLI 接管，目录变更为 `openspec/changes/<id>/` 与 `openspec/specs/<cap>/`**。旧目录保留作为历史审计，但不再生成新内容。

---

## 3. 基线规格管理

### 3.1 基线文件结构

每个基线文件描述当前系统的实际行为，按 capability 划分：

| 基线 spec | 描述内容 |
|---------|---------|
| `ssd-firmware-overview` | 顶层架构、模块分层、跨模块契约 |
| `nvme-commands` | NVMe 命令处理流程、SQ/CQ 管理、PRP/SGL 处理 |
| `ftl-mapping` | LBA→PBA 映射、磨损均衡、GC、SLC Cache |
| `nand-driver` | Page 级读写、Block 级擦除、ECC、坏块管理 |
| `error-handling` | 错误传播路径、恢复策略、断电恢复流程 |

### 3.2 基线文件内容规范（OpenSpec 标准格式）

每个基线 `spec.md` 包含：

1. **`## Purpose`**（强制，≥ 50 字符）：描述该 capability 的意图
2. **`## Requirements`**：每条 Requirement 用 `### Requirement: <name>`（3 个 `#`）
3. **`#### Scenario: <name>`**（4 个 `#`，**强制 4 个**）：用 `**WHEN**` / `**THEN**` 描述
4. **规范词**：使用 SHALL / MUST，**避免** should / may

### 3.3 基线更新规则

- **何时更新**：每次变更完成并通过 Review Gate 后
- **更新方式**：执行 `/opsx:archive`（或 `openspec archive <id>`），OpenSpec CLI 自动将 `openspec/changes/<id>/specs/` 的 deltas 合并到 `openspec/specs/`
- **合并原则**：ADDED → 追加到对应 capability；MODIFIED → 替换原有 Requirement；REMOVED → 删除对应内容（保留 Reason / Migration 审计）
- **冲突处理**：如 delta 与基线冲突，优先审查基线是否过时
- **版本标记**：OpenSpec 自动维护基线（无手动版本号）

### 3.4 基线查询优先级

AI 在理解系统行为时，优先查询基线 spec 而非从头读代码：

1. 先查 `openspec/specs/<capability>/spec.md` → 获取当前行为全貌
2. 再用 CodeGraph **局部**验证 → 补充调用关系和依赖细节
3. 最后读代码 → 仅在基线与代码不一致或基线信息不足时

查询命令：

```bash
# 列出所有基线
openspec spec list

# 查看具体 capability
openspec spec show <capability>
# 例: openspec spec show ftl-mapping
# 例: openspec spec show error-handling
```

---

## 4. 变更增量格式（OpenSpec Delta 规范）

每次变更在 `openspec/changes/<id>/specs/<capability>/spec.md` 下产生 1 个文件，包含 3 类 delta header。

### 4.1 ADDED Requirements（新增行为）

```markdown
## ADDED Requirements

### Requirement: FTL MUST fold SLC blocks when full
The FTL SHALL migrate data from SLC blocks to TLC blocks when SLC free block count falls below the configured threshold.

#### Scenario: SLC threshold reached
- **WHEN** SLC free block count < threshold
- **THEN** the FTL MUST pick a victim SLC block
- **AND THEN** it MUST copy valid pages to a free TLC block
- **AND THEN** it MUST erase the victim SLC block and return it to the free pool
```

### 4.2 MODIFIED Requirements（修改行为）

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

> **OpenSpec 对 MODIFIED 的特殊要求**：
> 1. 在 `openspec/specs/<capability>/spec.md` 中找到原有 Requirement
> 2. **复制整个 Requirement 块**（从 `### Requirement:` 到所有 Scenario）
> 3. 粘贴到 delta 文件的 `## MODIFIED Requirements` 下并编辑
> 4. 头文本必须与原有 Requirement 完全一致（whitespace-insensitive）
> 5. 缺失内容会导致归档时丢失细节

### 4.3 REMOVED Requirements（移除行为）

```markdown
## REMOVED Requirements

### Requirement: Legacy pblock allocation
**Reason**: Replaced by SLC-aware allocation policy
**Migration**: All write paths use the new SLC allocation logic
```

### 4.4 增量规范

- **使用 SHALL / MUST**：避免 should / may
- **不写代码**：delta 描述「系统做什么」，不描述「代码怎么写」
- **4 个 `#` 是强制**：3 个 `#` 或列表会导致 OpenSpec 静默失败
- **可验证性**：每个 Scenario 必须是潜在测试用例（参见 `memory/testing_rules.md`）
- **delta 与 CodeGraph 互补**：delta 描述行为变化，design.md 中的 CodeGraph 查询记录实现路径
- **MODIFIED 的备份原则**：修改前必须先复制基线 Requirement 全文，再编辑

---

## 5. 三级门禁体系

OpenSpec 工件是门禁的输入，**门禁本身** 仍是 zsf 流程的核心。

### 5.1 Gate 1：Proposal Gate（提案门禁）

- **时机**：`/opsx:propose` 完成后
- **输入**：`openspec/changes/<id>/proposal.md` + `specs/<cap>/spec.md`
- **校验命令**：`openspec validate --strict --changes` 必须通过
- **人工检查**：
  - [ ] 变更动机是否清晰？
  - [ ] 影响范围是否识别？
  - [ ] 是否与 `openspec/specs/` 现有基线冲突？
  - [ ] 是否有更简单的替代方案？
  - [ ] specs/ delta 是否正确描述了行为变更？
- **通过后**：→ 进入 Design 阶段（design.md 填充 + CodeGraph 查询）

### 5.2 Gate 2：Design Gate（设计门禁）

- **时机**：design.md + tasks.md 完成后
- **输入**：proposal.md、design.md、tasks.md
- **校验命令**：`openspec validate --strict --changes` 必须通过
- **人工检查**（design.md「待人工确认清单」7 项，参见 `openspec-workflow/SKILL.md`「工件模板与门禁流程」）：
  - [ ] 架构假设是否正确？
  - [ ] CodeGraph 影响查询是否完整？（impact/callers/imports/dep graph）
  - [ ] 是否有更简单的替代方案？
  - [ ] specs/ delta 是否覆盖所有变更？
  - [ ] tasks.md 每个任务是否在 200-500 行？
  - [ ] 并发/资源/错误路径是否已考虑？
- **通过后**：→ 进入编码阶段（`/opsx:apply`）

### 5.3 Gate 3：Review Gate（审查门禁）

- **时机**：编码完成 + Review 后
- **输入**：design.md、specs/ delta、代码 diff
- **校验命令**：`openspec validate --strict --changes` 必须通过
- **人工检查**（参见 `openspec-workflow/SKILL.md`「工件模板与门禁流程」Review 检查项 11 条）
- **通过后**：→ 归档（`/opsx:archive`），deltas 合并到 `openspec/specs/`

---

## 6. 归档与合并

### 6.1 归档时机

Review Gate 全部检查项通过 + `openspec validate --strict` 全部通过后执行归档。

### 6.2 归档流程（OpenSpec CLI）

```bash
# OpenCode IDE slash command（推荐）
#    IDE 中输入: /opsx:archive

# 等效 CLI 命令
openspec archive <change-id>

# 手动流程（不推荐）
# 1. cd openspec/changes/<id>/
# 2. 合并 specs/<cap>/spec.md 的 deltas 到 ../../specs/<cap>/spec.md
# 3. git commit -m "chore(spec): archive <id>"
# 4. mv openspec/changes/<id> openspec/changes/archive/<id>
```

### 6.3 合并原则（OpenSpec 自动执行）

- **ADDED → 追加**：将 `## ADDED Requirements` 合并到 `openspec/specs/<capability>/spec.md` 的 `## Requirements` 末尾
- **MODIFIED → 替换**：将 `## MODIFIED Requirements` 中同名 Requirement 替换基线中的对应 Requirement
- **REMOVED → 删除**：将 `## REMOVED Requirements` 中列出的 Requirement 从基线中删除（Reason / Migration 审计信息保留在 archive）
- **冲突处理**：如 delta 与基线冲突，优先审查基线是否过时，必要时手动裁决
- **原子性**：一次归档必须完成单个 change 的全部 deltas
- **可逆性**：归档前由 Git 跟踪 openspec/ 目录，可回滚

### 6.4 历史保留

- `openspec/changes/<id>/` 目录**不删除**（自动移至 `openspec/changes/archive/`），作为变更审计历史保留
- 归档 commit message 格式：`chore(spec): archive <change-id>`（OpenSpec 自动生成）
- 所有 `openspec/` 文件纳入 Git 版本管理（**`.gitignore` 中不排除** `openspec/`）

### 6.5 简化规则

| 变更类型 | 简化规则 | 必需工件 |
|---------|---------|---------|
| 单文件 bugfix（影响范围明确） | 跳过 Proposal Gate 人工评审 | `/opsx:propose` 全部 4 个工件即可 |
| 文档/注释更新 | 跳过全部门禁 | 无需 OpenSpec 工件 |
| 配置变更（无逻辑影响） | 跳过 Design Gate 人工评审 | tasks.md 即可 |
| 新功能/重构/接口变更 | **完整流程** | 全部 4 个工件 + 三级门禁 |
| 跨模块变更 | **完整流程 + 额外 Review** | 全部 4 个工件 + 双人 Review |

---

## 7. OpenSpec CLI 速查

```bash
# 项目初始化（一次性）
npm install -g @fission-ai/openspec
openspec init --tools opencode      # 在项目根目录执行

# 日常使用
openspec list                       # 列出进行中的 changes
openspec show <id>                  # 查看某个 change 详情
openspec spec list                  # 列出所有基线 specs
openspec spec show <cap>            # 查看某个基线 spec
openspec new change <id>            # 创建新变更目录
openspec validate --strict --all    # 严格校验全部
openspec validate --strict --specs  # 仅校验基线
openspec validate --strict --changes  # 仅校验进行中的 changes
openspec archive <id>               # 归档变更

# OpenCode IDE slash commands
#    /opsx:propose   生成 proposal + specs + design + tasks
#    /opsx:apply     按 tasks.md 逐项实现
#    /opsx:archive   归档合并到基线
```

---

## 8. 与其他规则的关系

| 规则文件 | 关系 |
|---------|------|
| `memory/design_rules.md` | 三级门禁体系统一实体描述在 design_rules.md §7；本规则为规格层操作规范 |
| `memory/review_rules.md` | Review Gate 的检查项引用 review_rules.md |
| `memory/testing_rules.md` | 增量可验证性要求通过 testing_rules.md 的测试场景落地 |
| `memory/architecture.md` | CodeGraph 查询规则已被 OpenSpec 门禁引用 |
| `development/skill.md` | 开发流程产出的工件对应本规则的规格层 |
| `openspec-workflow/SKILL.md` | OpenSpec CLI 与 zsf 流程的具体衔接（CLI 命令、模板示例、门禁清单） |
