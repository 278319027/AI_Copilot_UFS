# SSD Simulator ATDD + Wave + Comet 全流程开发方法论设计

**版本：V1.0**

---

# 1. 文档目的

本文定义一套面向 **SSD/UFS Firmware Simulator** 的 AI 辅助开发方法论。

目标是在从零开发 SSD Simulator 时，将：

* ATDD
* Story / Acceptance Criteria
* Wave 增量开发
* Comet Open
* Comet Design
* AC → Design Reverse Inference
* STUB / Skeleton
* TDD / UT
* Comet Build
* Comet Verify
* 人机协同
* AI Agent

统一到一个完整、可执行、可验证的工程闭环中。

核心目标不是让 Agent “直接写代码”，而是让 Agent 按照：

> **需求 → 验收 → 增量 → 需求澄清 → 设计 → Stub → 实现 → 测试 → 验收**

逐步构建 Simulator。

---

# 2. 总体设计原则

## 2.1 行为优先，而不是模块优先

传统 SSD Simulator 开发容易按照软件模块拆分：

```text
FTL
Mapping
NAND
GC
Block Manager
Page Manager
```

本方法论不采用这种方式作为第一层需求拆分。

采用：

```text
Epic
  ↓
Feature
  ↓
Story
  ↓
Acceptance Criteria
```

Story 描述的是：

> 一个可以独立验证的系统行为。

例如：

```text
Single LBA Write
Single LBA Read
LBA Overwrite
Random Write
GC Trigger
GC Valid Data Migration
GC Block Reclaim
```

而不是：

```text
Implement FTL
Implement NAND
Implement GC
```

---

# 3. 核心闭环

整个开发流程定义为：

```text
PRD
 ↓
prd-split
 ↓
Story + AC
 ↓
Wave Planning
 ↓
Wave
 ↓
Comet Open
 ↓
Requirement Contract
 ↓
Comet Design
 ↓
AC Reverse Inference
 ↓
Design + Stub Strategy
 ↓
Design Review
 ↓
Build Plan
 ↓
Stub / Skeleton / Code
 ↓
UT / TDD
 ↓
Comet Verify
 ↓
Acceptance Test
 ↓
Wave Acceptance
 ↓
Wave Baseline
 ↓
Next Wave
```

最终形成：

```text
Requirement
    ↓
Acceptance
    ↓
Increment
    ↓
Design
    ↓
Implementation
    ↓
Verification
    ↓
Evidence
```

---

# 4. Story、AC、Wave 三者关系

这是整个方法论的核心。

## 4.1 Story

回答：

> **我要实现什么行为？**

例如：

```text
Story:
作为 Simulator 用户，
我希望向一个 LBA 写入数据后能够重新读取，
从而验证最基本的 SSD I/O 闭环。
```

---

## 4.2 Acceptance Criteria

回答：

> **什么条件下才算完成？**

例如：

```text
Given LBA 100 尚未写入

When Write LBA 100 = Data A

Then Write 成功

And Read LBA 100

Then 返回 Data A
```

---

## 4.3 Wave

回答：

> **这些 Story 应该如何组成一个可以运行、验证和交付的系统增量？**

因此：

```text
Story = 行为单元

AC = 验收标准

Wave = 增量交付单元
```

Wave 不是简单的 Story 打包。

---

# 5. Wave 的定义

Wave 是：

> **由一组具有依赖关系的 Story/AC 组成的、能够形成一个可运行 Vertical Slice 的最小系统增量。**

每个 Wave 必须定义：

```text
Wave
 ├── Goal
 ├── Included Stories
 ├── Acceptance Criteria
 ├── Dependencies
 ├── Vertical Slice
 ├── Required Real Components
 ├── Allowed Stubs
 ├── Stub Replacement Conditions
 ├── UT Requirements
 ├── Integration Tests
 ├── Acceptance Tests
 ├── Entry Criteria
 └── Exit Criteria
```

---

# 6. 为什么需要 Wave

如果没有 Wave：

```text
29 Stories
 ↓
Agent 一次性开发
 ↓
上下文过大
 ↓
依赖关系复杂
 ↓
大量模块同时半成品
 ↓
难以验证
```

引入 Wave：

```text
Wave 1
 ↓
可运行
 ↓
验证
 ↓
冻结 Baseline

Wave 2
 ↓
在 Wave 1 基础上演进
 ↓
验证
 ↓
冻结 Baseline

Wave 3
...
```

因此 Wave 同时解决：

* 增量开发
* Agent 上下文控制
* 依赖管理
* Stub 管理
* Acceptance 管理
* 系统演进
* 回归验证

---

# 7. SSD Simulator 第一版需求拆分

建议第一版按照行为划分为以下 Epic。

```text
E1 Simulator Lifecycle

E2 Host I/O

E3 Logical-to-Physical Mapping

E4 NAND / Flash Media Model

E5 Garbage Collection

E6 Block / Page Management

E7 Error / Recovery

E8 Observability / Validation
```

注意：

**FTL 不作为一个独立 Epic。**

FTL 是实现多个行为所需要的技术体系。

---

# 8. Story 清单

## E1 Simulator Lifecycle

### S1 Simulator Initialization

初始化合法 NAND Geometry 后 Simulator 成功进入工作状态。

### S2 Simulator Reset

Simulator 可以恢复到定义的初始状态。

---

## E2 Host I/O

### S3 Single LBA Write

```text
Write(LBA, Data)
 ↓
Read(LBA)
 ↓
Data
```

### S4 Single LBA Read

已经写入的数据可以正确读取。

### S5 Read Unwritten LBA

读取未写入 LBA 时产生规定行为。

### S6 LBA Overwrite

```text
Write(100,A)
Write(100,B)

Read(100) == B
```

并且旧物理 Page 不再作为当前有效数据。

### S7 Sequential Write

连续 LBA 写入正确完成。

### S8 Random Write

随机 LBA 写入正确完成。

---

# 9. Mapping Stories

### S9 Mapping Creation

首次写入 LBA 后建立有效：

```text
LBA → PPA
```

### S10 Mapping Update

Overwrite 后：

```text
Old Mapping
    ↓
New Mapping
```

### S11 Mapping Consistency

保证：

```text
Mapping
 ↕
Page State
 ↕
Data
```

保持一致。

---

# 10. NAND Stories

### S12 Page Program

Erased Page 可以 Program。

### S13 Page Read

Program 后能够正确 Read。

### S14 Page Invalidation

Overwrite 后旧 Page 变成 Invalid。

### S15 Block Erase

Block 可以 Erase 并重新进入可用状态。

---

# 11. GC Stories

### S16 GC Trigger

Free Block 低于规定阈值时触发 GC。

### S17 GC Victim Selection

根据规定 Policy 选择 Victim Block。

### S18 GC Valid Data Migration

Victim Block 中所有有效数据得到保留和迁移。

### S19 GC Block Reclaim

有效数据迁移完成后 Victim Block 被回收。

### S20 GC Data Consistency

GC 前后：

```text
LBA → Data
```

保持正确。

---

# 12. Block / Page Management

### S21 Page Allocation

能够分配可用物理 Page。

### S22 Block State Management

Block 状态按照定义正确变化。

例如：

```text
FREE
 ↓
OPEN
 ↓
FULL
 ↓
VICTIM
 ↓
ERASE
 ↓
FREE
```

具体状态机由 Design 阶段确定。

---

# 13. Error / Recovery

### S23 Invalid LBA

非法 LBA 得到规定错误。

### S24 NAND Program Failure

Program Failure 注入后系统状态保持一致。

### S25 NAND Read Failure

Read Failure 注入后系统正确处理。

---

# 14. Observability / Validation

### S26 Mapping Inspection

能够查看：

```text
LBA → PPA
```

### S27 NAND State Inspection

能够查看：

```text
Block State
Page State
Valid / Invalid
```

### S28 GC Statistics

能够观察：

```text
GC Count
Victim Block
Migration Count
Reclaim Count
```

### S29 Invariant Check

自动验证：

```text
Mapping → Valid Page

Valid Page → 合法 Mapping

Erased Page → 不存在有效 Mapping

Reclaimed Block → 不存在有效 Mapping
```

---

# 15. SSD Simulator 的 Wave 规划

建议第一版采用 6 个主要 Wave。

---

## Wave 0：Simulator Foundation

### Goal

建立最小可运行 Simulator。

### Stories

```text
S1 Initialization
S2 Reset
```

### 目标

得到：

```text
Simulator Context
NAND Geometry
LBA Space
Runtime
Test Framework
```

---

# 16. Wave 1：最小 I/O Vertical Slice

### Goal

建立第一个完整：

```text
Write → Read
```

闭环。

### Stories

```text
S3 Single LBA Write
S4 Single LBA Read
S5 Read Unwritten LBA
```

### 初期架构

```text
Host
 ↓
FTL
 ↓
Simple Mapping
 ↓
NAND Stub
```

### Exit Criteria

```text
Write(100,A)
Read(100) == A
```

以及所有 Wave 1 AC、UT、Invariant 全部通过。

---

# 17. Wave 2：Mapping + Overwrite

### Goal

从最简单 I/O 进入真正的 FTL 基础行为。

### Stories

```text
S6 Overwrite
S9 Mapping Creation
S10 Mapping Update
S14 Page Invalidation
```

系统状态：

```text
Write(100,A)

100 → PPA10
PPA10 = VALID

Write(100,B)

100 → PPA25
PPA10 = INVALID
PPA25 = VALID
```

这一 Wave 开始逐步替换 Wave 1 的 NAND Stub。

---

# 18. Wave 3：Normal Workload

### Goal

验证正常工作负载下的 Mapping / Allocation 一致性。

### Stories

```text
S7 Sequential Write
S8 Random Write
S11 Mapping Consistency
S21 Page Allocation
S22 Block State
```

加入：

```text
Invariant Check
```

确保大量写入和覆盖写之后状态一致。

---

# 19. Wave 4：GC Vertical Slice

### Goal

形成完整 GC 生命周期。

### Stories

```text
S16 GC Trigger
S17 Victim Selection
S18 Valid Data Migration
S19 Block Reclaim
```

完整流程：

```text
Write
 ↓
Free Block ↓
 ↓
GC Trigger
 ↓
Victim Selection
 ↓
Find Valid Pages
 ↓
Migration
 ↓
Mapping Update
 ↓
Erase
 ↓
Free Block
```

---

# 20. Wave 5：GC + I/O 完整闭环

### Goal

证明 GC 不破坏系统数据正确性。

核心：

```text
S20 GC Data Consistency
```

测试流程：

```text
大量 Write
 ↓
触发 GC
 ↓
Migration
 ↓
Reclaim
 ↓
继续 Write
 ↓
Read 历史 LBA
```

要求：

```text
所有 LBA
 ↓
返回最后一次写入的数据
```

同时验证：

```text
Mapping
Page State
Block State
Free Block Count
GC State
```

---

# 21. Wave 6：Error + Observability

### Stories

```text
S23 Invalid LBA
S24 Program Failure
S25 Read Failure

S26 Mapping Inspection
S27 NAND State Inspection
S28 GC Statistics
S29 Invariant Check
```

目标：

从：

```text
能运行
```

提升到：

```text
可验证
可诊断
可调试
可扩展
```

---

# 22. Wave 与 STUB 的关系

STUB 是 Wave 内部的工程实现策略。

两者不能混淆：

```text
Wave
 = 系统增量

Stub
 = 尚未实现的依赖的临时实现
```

---

# 23. Stub Strategy

Design 阶段需要明确：

```text
当前 Story
 ↓
依赖分析
 ↓
哪些必须 Real？
哪些允许 Stub？
 ↓
Stub Contract
```

例如 Wave 1：

```text
Host        Real
FTL         Real
Mapping     Real
NAND        Stub
```

Wave 2：

```text
Host        Real
FTL         Real
Mapping     Real
Page State  Real
NAND Model  Real
```

Wave 3：

```text
Allocator       Real
Block Manager   Real
Page Manager    Real
```

Wave 4：

```text
GC              Real
```

---

# 24. Stub Contract

每一个 Stub 必须定义：

```text
Stub ID
Reason
Interface
Behavior
Covered Stories
Known Limitations
Replacement Condition
Target Real Component
```

例如：

```text
NAND-STUB-001

Reason:
真实 NAND Model 尚未完成

Interface:
Program()
Read()
Erase()

Behavior:
提供确定性的 PPA → Data 存储

Used By:
S3
S4
S6

Replacement:
NAND Page Model 完成后替换
```

---

# 25. Stub 的原则

## 原则 1

Stub 不能违反当前 AC。

## 原则 2

Stub 只能模拟尚未实现的能力。

## 原则 3

Stub 必须有明确替换条件。

## 原则 4

Stub 必须能够被测试。

## 原则 5

Stub 不能掩盖真实实现所需要解决的问题。

---

# 26. prd-split Agent

职责：

> **PRD → Story + AC**

负责：

```text
PRD Understanding
Epic / Feature Identification
Story Decomposition
Story Boundary
Acceptance Criteria
Initial Acceptance Test
Dependency Identification
```

不负责：

```text
Technical Architecture
Detailed Design
Code
Stub Implementation
```

---

# 27. Wave Planner

Wave Planner 位于：

```text
prd-split
 ↓
Story + AC
 ↓
Wave Planner
```

职责不是重新拆 Story，而是：

```text
Dependency Analysis
Vertical Slice Construction
Increment Planning
Stub Strategy Planning
Wave Acceptance Planning
```

输出：

```text
Wave Goal
Stories
Dependencies
Vertical Slice
Expected Baseline
Initial Stub Strategy
Entry / Exit Criteria
```

---

# 28. Comet Open

Comet Open 输入：

```text
One Story
+
Corresponding AC Set
+
Wave Context
```

Comet Open 不重新拆 Story。

它负责：

> **Requirement Exploration / Requirement Elaboration**

主要工作：

```text
需求澄清
边界分析
约束发现
依赖分析
异常行为
时序行为
并发行为
性能约束
人机决策
```

例如 GC：

```text
Threshold 是多少？
同步还是异步？
GC 期间 Host IO 是否允许？
Valid Page 如何定义？
Migration 是否允许失败？
```

---

# 29. Requirement Contract

Comet Open 输出：

```text
Requirement Contract
```

至少包含：

```text
Story
Scope
Out of Scope
AC
Acceptance Behavior
Constraints
Assumptions
Dependencies
Boundary Conditions
Human Decisions
Open Questions
```

Requirement Contract 是 Design 的正式输入。

---

# 30. Comet Design

Design 的核心职责：

> **Requirement Contract → Technical Design**

不是重新解释需求。

核心方法：

> **AC Reverse Inference**

---

# 31. AC Reverse Inference

完整链路：

```text
AC
 ↓
Required Behavior
 ↓
Required Facts
 ↓
Required State
 ↓
Responsibilities
 ↓
Components
 ↓
Interfaces
 ↓
Data Structures
 ↓
Algorithms
 ↓
UT
 ↓
AC Traceability
```

---

# 32. AC Reverse Inference 示例

AC：

```text
Given LBA 100 = Data A

When Write LBA 100 = Data B

Then Read LBA 100 = Data B

And old physical data is no longer current
```

反推：

### Required Facts

```text
LBA 100 当前映射
New PPA
Old PPA
Page State
Data
```

### Required State

```text
LBA → PPA Mapping
Page State
Page Data
```

### Required Responsibilities

```text
Mapping Manager
Page Allocator
NAND Model
FTL
```

### Required Interfaces

```text
mapping_lookup()
mapping_update()

page_allocate()

nand_program()
nand_read()
page_invalidate()
```

### Required Algorithm

```text
Lookup Old Mapping
 ↓
Allocate New PPA
 ↓
Program New Data
 ↓
Update Mapping
 ↓
Invalidate Old Page
```

### Required UT

```text
Mapping Creation
Mapping Update
Old Page Invalid
Read After Overwrite
```

---

# 33. Design Decision Point

AC 通常不能唯一决定实现方式。

例如 Mapping 可以是：

```text
Page-level
Block-level
Hybrid
```

因此 Design Agent 不应该擅自决定。

应该输出：

```text
Design Decision Point
 ↓
Alternative A
Alternative B
Alternative C
 ↓
Impact
 ↓
Recommendation
 ↓
Human Decision
```

最终形成冻结的 Design Contract。

---

# 34. Design Write Agent

Design Write 是设计生产 Agent。

职责：

```text
Requirement Contract
 ↓
AC Reverse Inference
 ↓
Technical Design
```

输出：

```text
Architecture
Component Responsibilities
Interfaces
Data Structures
Algorithms
State Machines
Error Handling
Concurrency / Timing
UT Design
Stub Strategy
AC ↔ Design Traceability
Build Input
```

Design Write 不负责：

```text
修改代码
重新拆 Story
替用户做关键架构决策
```

---

# 35. Design Review Agent

Design Review 独立于 Design Write。

核心原则：

```text
Design Write
     ↓
Technical Design
     ↓
Design Review
     ↓
AC Coverage
```

检查：

```text
每个 AC 是否有对应 Design？

每个 Required State 是否存在？

Interface 是否足够？

Algorithm 是否可实现？

异常路径是否覆盖？

边界条件是否覆盖？

UT 是否覆盖？

Stub 是否合理？

是否存在未定义 Design Decision？
```

最终输出：

```text
Approved
Needs Revision
Human Decision Required
```

---

# 36. Build Plan

Build Plan 的输入：

```text
Design Contract
+
Wave Context
```

输出：

```text
Implementation Tasks
Dependency Graph
Stub Tasks
Real Implementation Tasks
UT Tasks
Integration Tasks
```

Build Plan 不重新设计系统。

---

# 37. Comet Build

Build 的职责：

> **Design → Code**

执行：

```text
Stub / Skeleton
 ↓
Implementation
 ↓
UT
 ↓
Integration
```

严格按照 Design Contract 执行。

如果发现设计问题：

```text
Build
 ↓
Design Issue
 ↓
回 Design
```

而不是 Agent 私自修改架构。

---

# 38. TDD / UT

UT 应该在 Design 阶段提前设计。

因此：

```text
AC
 ↓
Design
 ↓
UT Design
 ↓
Build Plan
 ↓
Implementation
 ↓
UT
```

UT 不应该等代码写完以后才临时生成。

---

# 39. Acceptance Test

整个流程至少存在两层验收。

## External Acceptance

验证：

```text
Host
 ↓
SSD
 ↓
Observable Behavior
```

例如：

```text
Write(100,A)
Read(100)
== A
```

## Internal Acceptance

验证：

```text
Mapping
Page State
Block State
GC State
```

例如：

```text
Mapping[100] == PPA_B
PPA_A == INVALID
```

---

# 40. Wave Acceptance

Wave 完成后必须执行 Wave Acceptance。

验证：

```text
所有 Wave Stories
+
所有 AC
+
UT
+
Integration Test
+
Invariant
```

全部通过以后才能形成：

```text
Wave Baseline
```

---

# 41. Wave Baseline

每一个 Wave 完成以后记录：

```text
Wave ID
Goal
Implemented Stories
Passed AC
Architecture State
Real Components
Remaining Stubs
Known Limitations
Invariant Status
Test Status
Known Issues
```

例如：

```text
Wave 1 Baseline

Capability:
Single LBA Write/Read

Architecture:
Host → FTL → Mapping → NAND Stub

UT:
PASS

Acceptance:
PASS

Invariant:
PASS

Known Stub:
NAND

Next Wave:
Overwrite + Real Page State
```

---

# 42. Wave 与 Agent 上下文管理

Wave 对 AI Agent 非常重要。

Agent 不应该一次处理：

```text
全部 PRD
+
29 Stories
+
全部 Design
+
整个 Codebase
```

而应该：

```text
Current Wave
+
Relevant Stories
+
Relevant AC
+
Previous Wave Baseline
+
Requirement Contract
+
Design Contract
+
Relevant CodeGraph Context
+
Relevant OpenViking Knowledge
```

这样可以显著降低 Agent 上下文复杂度。

---

# 43. Wave 与 OMO Team Mode

对于复杂 Wave，可以使用 OMO Team Mode。

例如 GC Wave：

```text
             GC Coordinator
                   │
       ┌───────────┼───────────┐
       ↓           ↓           ↓
   Mapping      GC Agent    NAND Agent
    Agent                    Agent
       │           │           │
       └───────────┼───────────┘
                   ↓
             Design Review
```

Team Mode 主要用于：

```text
复杂 Design
复杂技术问题
多领域分析
并行探索
```

不需要每个简单 Story 都启动多 Agent。

---

# 44. Human-in-the-loop

人负责：

```text
需求决策
架构决策
Design Decision
Trade-off
Scope
关键异常行为
关键性能要求
```

Agent 负责：

```text
分析
推导
搜索知识库
生成方案
生成 Design
生成 UT
实现
测试
验证
```

因此：

```text
Human
  ↓
Decision Point
  ↓
Agent Execution
  ↓
Evidence
  ↓
Human Confirmation
```

---

# 45. OpenCode Hooks / Plugins

整个流程应该充分利用 OpenCode 的：

```text
Skills
Plugins
Hooks
Agent
Tools
```

例如：

### Hook

用于：

```text
Story 状态变化
Wave 状态变化
Design 完成
Build 完成
Test 完成
```

自动触发下一阶段。

### Plugin / Tools

用于：

```text
CodeGraph
graphify
OpenViking
OpenWiki
```

提供：

```text
代码结构
调用关系
知识库
历史设计
项目规范
```

---

# 46. 最终 Agent 职责

```text
                    PRD
                     ↓
                prd-split
                     ↓
                 Story + AC
                     ↓
                Wave Planner
                     ↓
               Wave Definition
                     ↓
                Comet Open
                     ↓
          Requirement Contract
                     ↓
               Design Write
                     ↓
          AC Reverse Inference
                     ↓
              Design Review
                     ↓
              Design Contract
                     ↓
                Build Plan
                     ↓
               Comet Build
                     ↓
               Code + UT
                     ↓
              Comet Verify
                     ↓
          Acceptance Evidence
                     ↓
             Wave Acceptance
                     ↓
              Wave Baseline
                     ↓
                Next Wave
```

---

# 47. 每个 Agent 的核心职责边界

| Agent           | 输入                   | 核心职责            | 输出                   |
| --------------- | -------------------- | --------------- | -------------------- |
| prd-split       | PRD                  | PRD → Story/AC  | Story + AC           |
| Wave Planner    | Story/AC             | 增量规划            | Wave                 |
| Comet Open      | Story/AC/Wave        | 需求澄清            | Requirement Contract |
| Design Write    | Requirement Contract | AC → Design     | Technical Design     |
| Design Review   | Design/AC            | Design → AC 验证  | Review               |
| Build Plan      | Design               | Design → Tasks  | Build Plan           |
| Build           | Tasks                | Tasks → Code    | Code + UT            |
| Verify          | Code + AC            | Code → Evidence | Verification         |
| Wave Acceptance | Wave                 | 增量验收            | Wave Baseline        |

---

# 48. 最终职责边界

最重要的边界如下：

```text
prd-split
回答：
“应该拆成哪些可验收行为？”

Wave Planner
回答：
“这些行为应该如何组成增量？”

Comet Open
回答：
“这个行为的需求到底是什么意思？”

Comet Design
回答：
“如何实现这些已经确认的 AC？”

Stub Strategy
回答：
“哪些依赖现在可以暂时不实现？”

Build
回答：
“如何把确定的 Design 实现出来？”

Verify
回答：
“实现是否真的满足 AC？”

Wave Acceptance
回答：
“这一轮增量是否真正形成了可工作的系统能力？”
```

---

# 49. 最终方法论

整个方法论可以浓缩成：

```text
ATDD
 ↓
Story + AC
 ↓
Wave
 ↓
Requirement Contract
 ↓
AC Reverse Inference
 ↓
Design
 ↓
Stub Strategy
 ↓
UT / TDD
 ↓
Build
 ↓
Verify
 ↓
Wave Acceptance
 ↓
Baseline
```

其中：

> **Story 是行为单元，AC 是验收标准，Wave 是增量单元，Design 是 AC 的技术反推结果，Stub 是增量实现策略，UT 是 Design 的验证手段，Verify 是最终证据生成，Wave Acceptance 是系统增量的闭环确认。**

---

# 50. 最终结论

针对 SSD Simulator，从零开始开发时，不应该采用：

```text
FTL → NAND → GC → Mapping → ...
```

这种模块串行开发方式作为主要驱动。

更适合采用：

```text
Behavior
 ↓
Story
 ↓
AC
 ↓
Wave
 ↓
Vertical Slice
 ↓
Requirement Clarification
 ↓
AC Reverse Design
 ↓
Stub / Real Implementation
 ↓
TDD / UT
 ↓
Build
 ↓
Verify
 ↓
Wave Acceptance
```

最终得到的是一个**逐 Wave 增长、每一 Wave 都可运行和验收的 SSD Simulator**。

第一轮：

```text
Wave 1
Write → Read
```

第二轮：

```text
Wave 2
Overwrite + Mapping
```

第三轮：

```text
Wave 3
Sequential / Random Workload
```

第四轮：

```text
Wave 4
GC Lifecycle
```

第五轮：

```text
Wave 5
GC + I/O Full Loop
```

第六轮：

```text
Wave 6
Error + Observability
```

因此整个系统不是：

> “先把所有模块写出来，再想办法测试。”

而是：

> **“每一个 Wave 都从可验收行为出发，反推最小技术实现，通过 Stub 快速形成 Vertical Slice，再逐 Wave 用真实实现替换 Stub，最终形成完整 SSD Simulator。”**

这就是本方案中 **ATDD + Wave + AC Reverse Inference + Stub + TDD + Comet** 的统一闭环。


可以。这里其实是我们整个方案里一个非常关键的点：**Design Write Agent 设计 UT，不能采用“先写代码，再让 AI 猜几个 UT”这种传统方式。**

在我们确定的 ATDD 方法论里，UT 应该是 **Design Write 在执行 AC → Design 反推时同步产生的设计产物**。

核心关系是：

```text
Story
  ↓
AC
  ↓
Required Behavior
  ↓
Required State
  ↓
Design
  ↓
Unit Boundary
  ↓
UT Scenario
  ↓
UT Case
  ↓
Build Implementation
```

也就是说：

> **UT 是 Design 的验证投影，而不是 Code 的附属测试。**

---

# 1. Design Write Agent 的 UT 设计目标

Design Write Agent 设计 UT 时，不应该只问：

> “这个函数怎么测？”

而应该依次回答 5 个问题：

```text
1. AC 要求什么行为？
2. Design 为了满足 AC 引入了哪些状态/职责？
3. 哪些状态/职责需要被独立验证？
4. 哪些边界/异常可能导致 Design 失效？
5. 如何用最小 UT 集合证明这些 Design 正确？
```

因此 UT 设计实际上是：

> **从 AC 和 Design 两端同时反推测试。**

---

# 2. AC → Design → UT 的完整链路

例如我们前面的 Overwrite Story。

### AC

```text
Given:
LBA 100 = Data A

When:
Write LBA 100 = Data B

Then:
Read LBA 100 = Data B

And:
Old physical page is no longer current
```

Design Write 首先进行 AC Reverse Inference：

```text
AC
 ↓
需要维护当前 Mapping
 ↓
需要分配新 PPA
 ↓
需要更新 Mapping
 ↓
需要维护 Page State
 ↓
需要使旧 Page Invalid
```

得到：

```text
Mapping Manager
Page Allocator
Page State
FTL Write Path
```

然后 UT 设计自然产生。

---

# 3. 第一层：Behavior UT

首先测试核心行为。

例如：

```text
UT-OVW-001

Given:
LBA 100 → PPA 10
Data A

When:
Write LBA 100 = Data B

Then:
Read LBA 100 == Data B
```

这个 UT 最接近 AC。

它证明：

> 整个 Overwrite Design 的行为是正确的。

---

# 4. 第二层：State Transition UT

然后验证 Design 中隐含的状态变化。

Overwrite 的状态：

```text
Before:

LBA100 → PPA10
PPA10 = VALID


After:

LBA100 → PPA20
PPA10 = INVALID
PPA20 = VALID
```

因此至少需要：

```text
UT-OVW-002
Mapping Update

UT-OVW-003
Old Page Invalidation

UT-OVW-004
New Page Valid
```

这类测试不是直接来自 External AC，而是：

> **从 Design Reverse Inference 得到的 Required State 派生出来的。**

---

# 5. 第三层：Interface Contract UT

Design Write 会定义接口，例如：

```c
Ppa mapping_lookup(Lba lba);

int mapping_update(Lba lba, Ppa new_ppa);

Ppa page_allocate(void);

int nand_program(Ppa ppa, const void *data);

int page_invalidate(Ppa ppa);
```

那么每一个关键 Interface 都应该有 Contract Test。

例如：

```text
UT-MAP-001

Given:
LBA100 → PPA10

When:
mapping_lookup(100)

Then:
return PPA10
```

再比如：

```text
UT-MAP-002

When:
mapping_update(100, PPA20)

Then:
lookup(100) == PPA20
```

---

# 6. 第四层：Boundary UT

SSD Firmware 的 UT 不能只测正常路径。

Design Write Agent 应该从 AC + Design 中主动找边界。

例如：

```text
LBA = 0
LBA = MAX_LBA
LBA = MAX_LBA + 1
```

Mapping：

```text
不存在 Mapping
Mapping 已存在
Mapping 更新失败
```

Page：

```text
First Page
Last Page
Full Block
No Free Page
```

所以会产生：

```text
UT-OVW-010
First LBA

UT-OVW-011
Last LBA

UT-OVW-012
Invalid LBA

UT-ALLOC-010
No Free Page
```

---

# 7. 第五层：Error Path UT

这是 SSD Firmware 非常重要的一类。

例如：

```text
page_allocate()
```

可能失败。

那么 Design 必须定义：

```text
Allocation Failure
 ↓
Write Failure
 ↓
Mapping 是否更新？
```

正确的 UT 应该验证：

```text
UT-OVW-020

Given:
LBA100 → PPA10
Data A

And:
page_allocate() fails

When:
Write LBA100 = Data B

Then:
Write fails

And:
Mapping[100] remains PPA10

And:
Read(100) == Data A
```

这里 UT 实际上反过来帮助我们验证：

> Design 的事务一致性是否正确。

---

# 8. 一个非常重要的原则：UT 不应该只测试函数

例如：

```c
mapping_update()
```

如果只写：

```text
test_mapping_update()
```

这其实是不够的。

Design Write Agent 应该考虑：

```text
Function
 ↓
State
 ↓
Invariant
 ↓
Behavior
```

所以更合理的是：

```text
Mapping Function UT
+
Mapping State UT
+
Mapping Invariant UT
+
AC Behavior UT
```

---

# 9. SSD Simulator 中建议的 UT 四层结构

我建议正式定义成：

```text
                 AC
                  │
        ┌─────────┴─────────┐
        ↓                   ↓
  Behavior UT          Design State
                            ↓
                    ┌───────┼───────┐
                    ↓       ↓       ↓
                Interface State  Invariant
                    UT      UT      UT
```

对应四类 UT：

### L1：Behavior UT

验证：

> 功能行为是否正确。

### L2：State UT

验证：

> 内部状态变化是否正确。

### L3：Interface UT

验证：

> Component Contract 是否正确。

### L4：Invariant UT

验证：

> 系统内部永远不应该被破坏的规则。

---

# 10. Invariant 是 SSD Simulator 特别重要的一层

例如：

```text
Invariant 1:

一个 LBA 最多只能有一个 Current Mapping。
```

```text
Invariant 2:

Current Mapping 必须指向 Valid Page。
```

```text
Invariant 3:

Invalid Page 不能作为 Current Mapping。
```

```text
Invariant 4:

Erased Page 不能存在有效 Mapping。
```

那么 Design Write Agent 应该产生：

```text
UT-INV-001
One LBA → One Current Mapping

UT-INV-002
Mapping → Valid Page

UT-INV-003
Invalid Page → No Current Mapping

UT-INV-004
Erased Page → No Mapping
```

这些测试对于发现 FTL Bug 非常有价值。

---

# 11. GC 的 UT 设计会更加有意思

例如 AC：

```text
Given:
Victim Block contains:

Page A = Valid
Page B = Invalid
Page C = Valid

When:
GC executes

Then:
A and C are migrated
B is not migrated

And:
LBA A still reads Data A
LBA C still reads Data C
```

Design Reverse Inference：

```text
GC
 ↓
Victim Selection
 ↓
Page Scan
 ↓
Valid Page Detection
 ↓
Migration
 ↓
New PPA Allocation
 ↓
Mapping Update
 ↓
Old Block Erase
```

于是 UT 会自动形成几个层次。

---

## GC Algorithm UT

```text
UT-GC-001

Victim contains:
V
I
V

Expected:
Migration Count = 2
```

---

## Valid Page Detection UT

```text
UT-GC-002

Given:
Page A = VALID
Page B = INVALID

When:
is_page_valid()

Then:
A → true
B → false
```

---

## Migration UT

```text
UT-GC-003

Given:
LBA100 → PPA10

When:
Migrate PPA10 → PPA50

Then:
LBA100 → PPA50
```

---

## Reclaim UT

```text
UT-GC-004

Given:
All valid pages migrated

When:
reclaim(victim)

Then:
Block state = FREE
```

---

# 12. GC Failure UT

再进一步。

假设：

```text
Migration Page A
成功

Migration Page C
失败
```

Design 必须回答：

```text
Mapping A 怎么办？
Mapping C 怎么办？
Victim Block 能不能 Erase？
```

这时候 Design Write Agent 应该发现：

> **需求/Design 存在一个 Decision Point。**

而不是直接生成一个 UT 假装这个问题不存在。

应该：

```text
Design Decision
 ↓
Human Decision
 ↓
Frozen Contract
 ↓
UT
```

---

# 13. Wave 对 UT Design 也有影响

这个是我们刚刚引入 Wave 后非常重要的一点。

UT 不是一次性设计完整个 Simulator。

而应该：

```text
Wave 1
 ↓
Wave 1 Design
 ↓
Wave 1 UT

Wave 2
 ↓
Wave 2 Design
 ↓
Wave 2 UT

Wave 3
 ↓
...
```

例如：

### Wave 1

```text
Write
Read
Mapping Basic
```

UT：

```text
Write
Read
Mapping Creation
```

### Wave 2

增加：

```text
Overwrite
Page Invalidation
Mapping Update
```

UT：

```text
Old Mapping
New Mapping
Old Page Invalid
```

### Wave 4

增加：

```text
GC
Migration
Reclaim
```

UT：

```text
Victim Selection
Valid Page Migration
Mapping Update
Reclaim
```

---

# 14. Stub 也必须进入 UT 设计

这个非常重要。

假设：

```text
Wave 1

NAND = Stub
```

那么 Design Write Agent 必须设计：

```text
NAND Stub Contract UT
```

例如：

```text
UT-STUB-NAND-001

Program(PPA10,A)

Read(PPA10)

== A
```

以及：

```text
UT-STUB-NAND-002

Erase(Block0)

Then:
all Pages = Erased
```

所以：

> **Stub 不是测试盲区。**

Stub 本身也必须具有 Contract。

---

# 15. Design Write Agent 的 UT 生成算法

我建议把它固化成 Skill 中的标准流程。

```text
Step 1
读取 Story + AC

        ↓

Step 2
提取 Required Behaviors

        ↓

Step 3
执行 AC Reverse Inference

        ↓

Step 4
得到 Required State

        ↓

Step 5
得到 Component / Interface

        ↓

Step 6
识别 State Transition

        ↓

Step 7
识别 Invariants

        ↓

Step 8
识别 Boundary Conditions

        ↓

Step 9
识别 Error Paths

        ↓

Step 10
识别 Stub Contracts

        ↓

Step 11
生成 UT Scenarios

        ↓

Step 12
生成 UT Cases

        ↓

Step 13
AC ↔ Design ↔ UT Traceability

        ↓

Step 14
检查 UT 是否足以证明 Design
```

---

# 16. 最关键的输出：Traceability Matrix

Design Write Agent 最终不应该只输出：

```text
UT-001
UT-002
UT-003
...
```

而应该输出：

| AC   | Design Element     | UT       | 类型        |
| ---- | ------------------ | -------- | --------- |
| AC-1 | FTL Write          | UT-W-001 | Behavior  |
| AC-1 | Mapping            | UT-M-001 | State     |
| AC-1 | NAND Program       | UT-N-001 | Interface |
| AC-2 | Mapping Update     | UT-M-002 | State     |
| AC-2 | Page Invalidation  | UT-P-001 | State     |
| AC-2 | Mapping Invariant  | UT-I-001 | Invariant |
| AC-3 | LBA Boundary       | UT-B-001 | Boundary  |
| AC-3 | Allocation Failure | UT-E-001 | Error     |

这样 Build Agent 就不需要自己猜：

> “这个 Design 到底应该测试什么？”

---

# 17. Design Review Agent 如何审 UT？

这也应该纳入 Design Review。

Review Agent 不仅检查：

```text
AC → Design
```

还检查：

```text
Design → UT
```

最终形成双向验证：

```text
              AC
             ↕
        Technical Design
             ↕
             UT
```

具体检查：

### AC Coverage

每个 AC 是否至少有一个测试？

### Design Coverage

每个关键 Design Element 是否被验证？

### State Coverage

关键状态是否覆盖？

### Transition Coverage

关键状态转换是否覆盖？

### Error Coverage

异常路径是否覆盖？

### Boundary Coverage

边界是否覆盖？

### Invariant Coverage

核心不变量是否覆盖？

---

# 18. 这会形成一个非常漂亮的三角闭环

最终我们不是：

```text
AC → Design → Code
```

而是：

```text
                 AC
                /  \
               /    \
              ↓      ↓
          Design ←→ UT
             \
              ↓
             Code
```

进一步：

```text
AC
 ↓
Design
 ↓
UT
 ↓
Build
 ↓
Code
 ↓
Verify
 ↓
AC
```

---

# 19. 对 Build Agent 的意义

这样 Build Plan 就可以直接从 Design 中得到：

```text
Design Element
      ↓
Implementation Task
      +
UT Task
```

例如：

```text
Task-001
Implement Mapping Manager

UT:
UT-MAP-001
UT-MAP-002
UT-MAP-003
```

再比如：

```text
Task-002
Implement Page State

UT:
UT-PAGE-001
UT-PAGE-002
UT-PAGE-003
```

Build Agent 不需要自己设计测试策略。

---

# 20. 对 AI Coding 最大的价值

这个设计实际上解决了 AI Coding 中一个很常见的问题：

```text
传统：

需求
 ↓
AI 写代码
 ↓
AI 再写几个 UT
 ↓
“看起来测试通过了”
```

我们采用：

```text
ATDD
 ↓
AC
 ↓
Design Reverse Inference
 ↓
UT Design
 ↓
Design Review
 ↓
Build
 ↓
UT
 ↓
Acceptance
```

于是 Agent 在写代码之前就已经知道：

```text
我必须实现什么
我必须维护什么状态
我必须满足什么接口
我必须通过哪些 UT
最终必须满足哪些 AC
```

---

# 21. 我建议最终把 Design Write Agent 的 UT 能力定义为一个独立 Skill

例如：

```text
design-write
├── requirement-analysis
├── ac-reverse-inference
├── architecture-design
├── interface-design
├── state-machine-design
├── data-structure-design
├── algorithm-design
├── stub-strategy
├── ut-design              ← 核心
└── traceability
```

其中 `ut-design` 不应该独立于 Design，而应该是：

> **Design Write 的必经步骤。**

---

# 22. 最终定义

因此我们可以把 Design Write Agent 的核心职责正式定义为：

> **Design Write Agent 接收经过 Comet Open 冻结的 Requirement Contract，以 AC 为起点执行 Reverse Inference，形成可实现的 Technical Design，并从 AC、Design State、Interface Contract、State Transition、Boundary、Error Path、Invariant 和 Stub Contract 等维度推导完整 UT Specification，同时建立 AC ↔ Design ↔ UT 的双向 Traceability，为 Build Plan 和 TDD 实现提供直接输入。**

整个过程最终变成：

```text
                 Story
                   ↓
                  AC
                   ↓
          Requirement Contract
                   ↓
          ┌─────────────────┐
          │ Design Reverse  │
          │   Inference     │
          └────────┬────────┘
                   ↓
              Technical
                Design
                   │
       ┌───────────┼────────────┐
       ↓           ↓            ↓
   Interface     State      Algorithm
       │           │            │
       └───────────┼────────────┘
                   ↓
              UT Design
       ┌───────────┼─────────────┐
       ↓           ↓             ↓
   Behavior     Boundary      Error
       ↓           ↓             ↓
    State      Invariant      Stub
       └───────────┼─────────────┘
                   ↓
             Traceability
                   ↓
              Build Plan
                   ↓
             Code + UT
                   ↓
               Verify
                   ↓
                  AC
```

**所以，在我们当前方案里，Design Write Agent 不是“设计模块 + 顺便设计 UT”，而应该是“AC → Design → UT”三个动作一次性完成。** 这会让 Comet Design 和 Comet Build 之间真正形成一个强 Contract，也正好解决了你之前提出的“Design 阶段 UT 设计如何影响 Build 任务拆分”这个问题：**UT 不再是 Build 的附属物，而是直接参与 Build Task 的生成。**
