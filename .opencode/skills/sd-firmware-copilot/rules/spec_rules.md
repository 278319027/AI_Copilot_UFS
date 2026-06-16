# Spec Rules

SSD 固件规格层规则。定义规格基线管理、增量追踪、门禁联动和归档合并机制。

## 1. 规格层定位

规格层独立于约束层（Memory）和基础设施层（CodeGraph），是「系统当前行为」的权威描述。

```
┌─────────────────────────────────────────┐
│  规格层 (Spec)     — 当前行为的权威描述   │  ← 本规则
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

## 2. 目录结构

```
.openspec/
├── proposals/
│   └── {change-id}/
│       ├── proposal.md      ← 为什么做、做什么
│       ├── specs/            ← 行为变更增量
│       │   ├── ADDED.md
│       │   ├── MODIFIED.md
│       │   └── REMOVED.md
│       ├── design.md         ← 怎么做（含 CodeGraph 查询结果）
│       ├── tasks.md          ← 实现清单
│       └── review.md         ← Review 记录
└── specs/
    └── baseline/             ← 活规格基线
        ├── README.md         ← 基线索引
        ├── nvme-commands.md
        ├── ftl-mapping.md
        ├── nand-driver.md
        ├── error-handling.md
        └── ...
```

## 3. 基线规格管理

### 3.1 基线文件结构

每个基线文件描述当前系统的实际行为，按模块划分：

| 基线文件 | 描述内容 |
|---------|---------|
| nvme-commands.md | NVMe 命令处理流程、SQ/CQ 管理、PRP/SGL 处理 |
| ftl-mapping.md | LBA→PBA 映射、磨损均衡、GC、SLC Cache |
| nand-driver.md | Page 级读写、Block 级擦除、ECC、坏块管理 |
| error-handling.md | 错误传播路径、恢复策略、断电恢复流程 |

### 3.2 基线文件内容规范

每个基线文件包含：
1. **模块概述**：模块职责、对外接口、约束条件
2. **核心数据结构**：关键 Context、状态枚举、缓冲池
3. **行为描述**：主要流程（正常路径、错误路径）
4. **接口契约**：公开函数签名、前置/后置条件
5. **依赖关系**：依赖哪些模块、被哪些模块依赖
6. **已知限制**：已知的性能约束、并发假设

### 3.3 基线更新规则

- **何时更新**：每次变更完成并通过 Review Gate 后
- **更新方式**：将 `proposals/{change-id}/specs/` 的增量合并到对应基线文件
- **合并原则**：ADDED → 追加到对应章节；MODIFIED → 替换原有描述；REMOVED → 删除对应内容
- **冲突处理**：如增量与基线冲突，优先审查基线是否过时
- **版本标记**：每个基线文件头部标注最后更新时间和关联 change-id

### 3.4 基线查询优先级

AI 在理解系统行为时，优先查询基线 spec 而非从头读代码：

1. 先查 `specs/baseline/` → 获取当前行为全貌
2. 再用 CodeGraph **局部**验证 → 补充调用关系和依赖细节
3. 最后读代码 → 仅在基线与代码不一致或基线信息不足时

## 4. 变更增量格式

每次变更在 `proposals/{change-id}/specs/` 下产生 3 个文件：

### 4.1 ADDED.md

记录本次变更新增的行为：

```markdown
# Added: {change-id}

## {新增行为 1}
- **描述**：...
- **触发条件**：...
- **预期结果**：...
- **涉及模块**：...

## {新增行为 2}
...
```

### 4.2 MODIFIED.md

记录本次变更修改的已有行为：

```markdown
# Modified: {change-id}

## {修改行为 1}
- **原行为**：...
- **新行为**：...
- **影响范围**：...
- **兼容性影响**：...
```

### 4.3 REMOVED.md

记录本次变更移除的已有行为：

```markdown
# Removed: {change-id}

## {移除行为 1}
- **原行为**：...
- **移除原因**：...
- **替代方案**：...
```

### 4.4 增量规范

- **增量文件不写代码**：描述行为，不描述实现
- **增量与 CodeGraph 互补**：增量描述行为变化，design.md 中的 CodeGraph 查询记录实现路径
- **增量必须可验证**：每个增量项必须能被测试场景覆盖

## 5. 三级门禁体系

### 5.1 Gate 1：Proposal Gate（提案门禁）

- **时机**：proposal.md 完成后
- **输入**：proposal.md、specs/ 增量
- **检查项**：
  - [ ] 变更动机是否清晰？
  - [ ] 影响范围是否识别？
  - [ ] 是否与现有 baseline spec 冲突？
  - [ ] 是否有更简单的替代方案？
  - [ ] specs/ 增量是否正确描述了行为变更？
- **通过后**：→ 进入 CodeGraph 深度查询 + design 阶段

### 5.2 Gate 2：Design Gate（设计门禁）

- **时机**：design.md + tasks.md 完成后
- **输入**：proposal.md、design.md、tasks.md
- **检查项**：
  - [ ] 架构假设是否正确？
  - [ ] CodeGraph 影响查询是否完整？（impact/callers/imports/dep graph）
  - [ ] 是否有更简单的替代方案？
  - [ ] specs/ 增量是否覆盖所有变更？
  - [ ] tasks.md 每个任务是否在 200-500 行？
  - [ ] 并发/资源/错误路径是否已考虑？
- **通过后**：→ 进入编码阶段

### 5.3 Gate 3：Review Gate（审查门禁）

- **时机**：编码完成 + Review 后
- **输入**：review.md、design.md、specs/ 增量、代码 diff
- **检查项**：
  - [ ] Review 检查项全部通过（review_rules.md）
  - [ ] CodeGraph 验证影响范围与 design.md 一致（查证式）
  - [ ] specs/ 增量与实际代码变更一致
  - [ ] 测试场景覆盖（testing_rules.md）
  - [ ] 审查问题已全部解决
- **通过后**：→ 归档，specs 增量合并到 baseline

## 6. 归档与合并

### 6.1 归档时机

Review Gate 全部检查项通过后执行归档。

### 6.2 合并流程

1. 将 `proposals/{change-id}/specs/ADDED.md` 中内容追加到对应基线文件
2. 将 `proposals/{change-id}/specs/MODIFIED.md` 中内容替换基线文件对应描述
3. 将 `proposals/{change-id}/specs/REMOVED.md` 中描述的内容从基线文件中删除
4. 更新基线文件头部的版本标记（时间 + change-id）
5. 更新 `specs/baseline/README.md` 索引

### 6.3 历史保留

- `proposals/{change-id}/` 目录**不删除**，作为变更审计历史保留
- 归档 commit message 格式：`chore(spec): merge {change-id} into baseline`
- 所有 spec 文件纳入 Git 版本管理（`.gitignore` 中不排除 `.openspec/`）

### 6.4 简化规则

以下场景可跳过部分或全部门禁和归档：

| 变更类型 | 简化规则 | 必需工件 |
|---------|---------|---------|
| 单文件 bugfix（影响范围明确） | 跳过 Proposal Gate | design.md + tasks.md |
| 文档/注释更新 | 跳过全部门禁 | 无需 OpenSpec 工件 |
| 配置变更（无逻辑影响） | 跳过 Design Gate | proposal.md |
| 新功能/重构/接口变更 | **完整流程** | 全部工件 |
| 跨模块变更 | **完整流程 + 额外 Review** | 全部工件 + 双人 Review |

## 7. 与其他规则的关系

| 规则文件 | 关系 |
|---------|------|
| design_rules.md | 三级门禁体系统一实体描述在 design_rules.md §7；本规则为规格层操作规范 |
| review_rules.md | Review Gate 的检查项引用 review_rules.md |
| testing_rules.md | 增量可验证性要求通过 testing_rules.md 的测试场景落地 |
| architecture.md | CodeGraph 查询规则已被 OpenSpec 门禁引用 |
| development/skill.md | 开发流程产出的工件对应本规则的规格层 |
