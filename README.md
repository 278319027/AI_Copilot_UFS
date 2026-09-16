下面这份我按你刚刚确认的最终方案整理成可以直接落地到当前 Comet/OpenCode 平台的 Markdown 设计文档。重点把 ATDD、Human-in-the-loop、Requirement Decomposition、Conceptual Architecture、Open、Design、Build、Verify 的边界和产物固定下来，同时兼容 有 Codebase / 无 Codebase 两种模式。

Comet AI 辅助固件开发流程

ATDD 需求分解与 Open / Design 优化设计

版本：V1.0
状态：Architecture Proposal / 可用于现有开发流程适配
适用范围：UFS / SSD Firmware、SSD Simulator、Firmware Simulator、FTL、底层嵌入式软件等项目

---

1. 文档目标

本文档定义在现有 Comet 五阶段流程前增加 Requirement Decomposition（需求分解）阶段后的完整开发方法。

优化后的核心流程：

Epic Requirement
       │
       ▼
Requirement Decomposition
       │
       │  Human Lead + Agent Assist
       │
       ├── Requirement Clarification
       ├── Capability Decomposition
       ├── Story Mapping
       ├── Acceptance Criteria
       ├── Conceptual Architecture
       ├── Major Interface
       └── Dependency / Constraint
       │
       ▼
Human Approval
       │
       ▼
     Stories
       │
       ▼
      OPEN
       │
       ├── Context Discovery
       ├── Codebase Analysis
       ├── Impact Analysis
       └── Readiness Check
       │
       ▼
     DESIGN
       │
       ├── Detailed Architecture
       ├── Module Design
       ├── Interface Design
       ├── Data Structure
       ├── Algorithm
       ├── State Machine
       └── Error / Concurrency / Memory
       │
       ▼
      BUILD
       │
       ▼
     VERIFY

核心目标是：

1. 防止 Agent 在需求尚未明确时直接进入 Coding。
2. 让 Human 掌握需求和架构关键决策。
3. 使用 ATDD 将需求转换成可验收的 Stories。
4. 在 Story 拆分阶段允许必要的高层架构设计。
5. 精简 Comet Open，避免重复进行需求分析。
6. 保留 Comet Design 的详细技术设计能力。
7. 建立 Requirement → Story → AC → Design → Code → Test 的完整追踪关系。
8. 支持 Greenfield（无 Codebase）和 Existing Codebase 两种开发模式。

---

2. 核心方法论

2.1 三层核心模型

整个流程采用三层设计模型：

L0 Requirement
       │
       ├── Epic
       ├── Capability
       ├── Story
       └── Acceptance Criteria
       
L1 Conceptual Design
       │
       ├── System Boundary
       ├── Major Components
       ├── Responsibility
       ├── Major Data Flow
       ├── Major Interface
       └── Dependency

L2 Detailed Design
       │
       ├── Module
       ├── API
       ├── Data Structure
       ├── Algorithm
       ├── State Machine
       ├── Concurrency
       ├── Memory
       └── Error Handling

对应三个核心问题：

L0：Why / What
L1：What does the system look like?
L2：How exactly is it implemented?

---

3. 总体原则

3.1 Human Lead, Agent Assist

需求分解阶段采用：

«Human 主导，Agent 辅助。»

Agent 可以：

- 分析
- 提问
- 发现歧义
- 建议能力划分
- 建议 Story
- 建议 Acceptance Criteria
- 建议高层架构
- 建议主要接口
- 检查遗漏
- 检查 Story 边界

但不能自行决定：

- 需求目标
- 产品范围
- 关键架构方向
- 重要接口边界
- 关键技术约束
- Story 最终边界

最终决策权：

Human
  ↓
Approve / Modify / Reject
  ↓
Frozen Requirement Baseline

---

4. ATDD 在整个流程中的定位

ATDD 不作为单独的测试阶段，而作为整个开发流程的需求主线。

User Story
    ↓
Acceptance Criteria
    ↓
Acceptance Scenario
    ↓
Conceptual Architecture
    ↓
Detailed Design
    ↓
Implementation
    ↓
Verification

最终形成：

Requirement
    ↓
Story
    ↓
Acceptance Criteria
    ↓
Design
    ↓
Code
    ↓
Test
    ↓
Evidence

---

5. Requirement Decomposition 阶段

5.1 阶段目标

Requirement Decomposition 的职责不是简单地：

«“把 Epic 拆成几个 Story。”»

而是：

«将一个高层 Epic 转换成一组经过 Human 确认、具有明确验收标准、具有合理架构边界、能够进入 Comet Open 的 Stories。»

输入：

Epic Requirement

输出：

Requirement Model
Capability Map
Story Map
Acceptance Criteria
Conceptual Architecture
Major Interfaces
Dependency Map
Constraints
Human Decisions
Stories

---

6. Requirement Decomposition 六步模型

Step 1  Requirement Understanding
          ↓
Step 2  Requirement Interview
          ↓
Step 3  Capability Decomposition
          ↓
Step 4  Conceptual Architecture
          ↓
Step 5  Story Mapping + Acceptance Criteria
          ↓
Step 6  Human Review / Freeze

---

7. Step 1：Requirement Understanding

Agent 首先分析 Epic。

重点提取：

Goal
Users / Actors
Expected Behavior
Business Value
Scope
Constraints
Known Dependencies
Unknowns

例如：

Epic:

构建一个 SSD Simulator，
支持 Host IO、FTL、NAND、GC 和 Workload。

Agent 不立即生成 Stories。

首先形成：

Goal:
提供一个可执行的 SSD Simulator。

Potential Capabilities:
- Host IO
- FTL
- NAND
- GC
- Workload
- Runtime
- Statistics

---

8. Step 2：Requirement Interview

Agent 进入需求访谈模式。

目标是发现：

- Ambiguity
- Missing Requirement
- Hidden Assumption
- Scope Boundary
- Technical Constraint
- Acceptance Boundary

例如：

Simulator 的主要目标是什么？

A. FTL 算法研究
B. SSD 性能模拟
C. Firmware 算法验证
D. Host IO 行为模拟
E. NAND timing 模拟

Human 选择后，Agent 根据选择继续提问。

---

9. Human Decision Gate

对于高价值问题，Agent 不应该自动决定。

采用：

Agent Question
      ↓
Human Decision
      ↓
Decision Record
      ↓
Requirement Model Update

例如：

id: DEC-003
question: FTL 是否需要可插拔？
decision: Yes
owner: Human
reason: 后续需要接入自定义 FTL

---

10. Step 3：Capability Decomposition

将 Epic 转换为能力树。

例如：

SSD Simulator
│
├── Simulator Runtime
│   ├── Initialization
│   ├── Event Loop
│   ├── Timer
│   └── Statistics
│
├── Host Interface
│   ├── Read
│   ├── Write
│   ├── Flush
│   └── Queue
│
├── FTL
│   ├── Mapping
│   ├── Allocation
│   ├── Read
│   ├── Write
│   └── GC
│
├── NAND Model
│   ├── Channel
│   ├── Die
│   ├── Plane
│   ├── Block
│   └── Page
│
├── Workload
│   ├── Sequential
│   ├── Random
│   └── Mixed
│
└── Observability
    ├── Latency
    ├── Bandwidth
    ├── GC Statistics
    └── NAND Statistics

注意：

«Capability 不等于 Story，也不等于代码模块。»

---

11. Step 4：Conceptual Architecture

这是 Requirement Decomposition 与传统流程相比增加的关键能力。

11.1 目的

在 Story 拆分之前确定：

System Boundary
Major Components
Responsibility
Major Data Flow
Major Interface
Dependency
Architecture Constraint

---

12. Conceptual Architecture 示例

SSD Simulator：

                         Simulator
                             │
          ┌──────────────────┼─────────────────┐
          │                  │                 │
       Host IO            Runtime          Workload
          │                  │
          ▼                  │
      Scheduler              │
          │                  │
          ▼                  │
          FTL ◄──────────────┘
           │
           ▼
       NAND Model
           │
           ▼
       Statistics

主要数据流：

Host IO
   ↓
Scheduler
   ↓
FTL
   ↓
NAND
   ↓
Completion

---

13. Major Interface Definition

Requirement Decomposition 阶段允许定义主要接口。

但只定义：

- Interface Name
- Purpose
- Responsibility
- Input Concept
- Output Concept
- Caller / Callee
- Boundary
- Dependency

例如：

FTL.submit_io

Purpose:
    将 Host IO 转换为 FTL operation。

Responsibility:
    Mapping / allocation / FTL scheduling。

Input:
    IO Request

Output:
    FTL Operation / Completion

Not Responsible For:
    NAND timing

此阶段不定义完整 C API。

禁止过早进入：

FtlStatus FtlSubmitIo(
    FtlContext *ctx,
    IoRequest *req,
    FtlCallback callback,
    void *user_data);

完整函数签名、结构体、内存布局等进入 Design 阶段。

---

14. L1 Conceptual Design 的边界

允许：

Component
Responsibility
Data Flow
Major Interface
Dependency
System Boundary
Architecture Constraints

不允许在此阶段过度深入：

具体函数签名
结构体字段
具体算法
锁
内存池实现
Queue 实现
数据结构选择
具体代码组织

原则：

«定义“架构骨架”，而不是“施工图”。»

---

15. Step 5：Story Mapping

完成 Capability + Conceptual Architecture 后开始拆 Story。

Story 不按照代码文件拆。

错误：

Story-001: ftl.c
Story-002: nand.c
Story-003: scheduler.c

也不简单按照模块拆：

Story-001: Host
Story-002: FTL
Story-003: NAND

优先采用：

«Vertical Slice + Independent Value»

---

16. Vertical Slice 原则

优先让 Story 形成一个可运行的系统增量。

例如：

Story-001
Minimal Host Write Path

Host
 ↓
FTL
 ↓
NAND
 ↓
Completion

然后：

Story-002
Read Path

Host
 ↓
FTL
 ↓
NAND
 ↓
Data

再：

Story-003
FTL Mapping

再：

Story-004
Garbage Collection

---

17. Story 拆分原则

每个 Story 应尽量满足：

1. 有明确价值。
2. 有明确边界。
3. 有明确 Acceptance Criteria。
4. 可以进入 Design。
5. 可以独立验证。
6. 尽可能形成可运行增量。
7. 具有明确依赖。
8. 不依赖隐含需求。
9. 不应该只是一个代码模块。
10. 不应该包含过多无关能力。

---

18. Story 可以跨多个组件

例如：

Story:

用户可以执行一次完整 Write IO。

它可能涉及：

Host
 ↓
Scheduler
 ↓
FTL
 ↓
NAND

这是合理的。

因为 Story 表达的是：

«用户可观察的系统能力。»

而不是：

«软件内部的模块边界。»

---

19. Acceptance Criteria

每个 Story 必须包含 Acceptance Criteria。

例如：

STORY-001

Title:
Minimal Host Write Path

Acceptance Criteria：

AC-001:
Simulator 可以成功启动。

AC-002:
Host 可以提交 Write IO。

AC-003:
Write IO 可以进入 FTL。

AC-004:
FTL 可以生成 NAND operation。

AC-005:
NAND operation 可以完成。

AC-006:
Host 可以获得 Write completion。

---

20. Acceptance Scenario

必要时进一步定义：

Scenario: Submit a Host Write

Given:
    Simulator is initialized

When:
    Host submits a Write request

Then:
    Request enters the simulator
    Request reaches FTL
    FTL generates NAND operation
    NAND operation completes
    Host receives completion

---

21. Step 6：Story Challenge

在 Human Approval 之前增加 Challenge。

Challenge Agent 检查：

Story 是否过大？
Story 是否过小？
是否存在重复？
是否存在遗漏？
是否可以验收？
是否包含隐藏需求？
是否误把 Design 当 Requirement？
是否违反 Vertical Slice 原则？
依赖是否正确？
Acceptance Criteria 是否覆盖目标？

---

22. Human Approval

最终：

Agent Proposal
      ↓
Challenge
      ↓
Human Review
      ↓
Modify / Accept
      ↓
Story Freeze

Freeze 后：

Story ID
Acceptance Criteria
Scope
Out of Scope
Dependencies
Major Architecture Boundary

成为后续 Comet 流程的基准。

---

23. Requirement Decomposition 输出目录

建议：

requirement-decomposition/
│
├── requirement.md
├── decisions.md
├── assumptions.md
├── capability-map.md
├── conceptual-architecture.md
├── interface-boundaries.md
├── dependency-map.md
├── constraints.md
├── story-map.md
│
└── stories/
    ├── STORY-001.md
    ├── STORY-002.md
    ├── STORY-003.md
    └── ...

---

24. Story 数据模型

推荐：

id: STORY-001

title: Minimal Host Write Path

source_requirement:
  - REQ-001

business_goal:
  description: >
    Enable a complete Host Write operation.

scope:
  - Host submission
  - FTL processing
  - NAND operation
  - Completion

out_of_scope:
  - Garbage Collection
  - Performance optimization
  - Advanced scheduling

acceptance_criteria:
  - AC-001
  - AC-002
  - AC-003
  - AC-004

dependencies:
  - STORY-000

architecture_boundaries:
  - Host
  - FTL
  - NAND

major_interfaces:
  - Host.submit_io
  - FTL.submit_io
  - NAND.submit_request

decisions:
  - DEC-001

assumptions:
  - ASM-001

status: frozen

---

25. Open 阶段重新定位

由于 Requirement Decomposition 已经完成：

Requirement
Capability
Story
AC
Conceptual Architecture
Major Interface

所以 Open 不再负责：

需求拆分
重新定义 Scope
重新设计系统
重新定义 Story

Open 的核心职责变成：

«理解 Story 所处的工程环境。»

---

26. Open 的四项任务

Story
  ↓
Context Discovery
  ↓
Impact Analysis
  ↓
Technical Constraints
  ↓
Readiness Check

---

27. 有 Codebase 模式

如果存在 Codebase：

Story
 +
Conceptual Architecture
        ↓
CodeGraph
        ↓
Repository
        ↓
OpenViking / Knowledge Base
        ↓
Existing Architecture
        ↓
Impact Analysis

分析：

现有架构
相关模块
相关函数
调用关系
数据流
复用点
修改点
潜在冲突

---

28. 无 Codebase 模式

如果没有 Codebase：

Open 不应该假装存在现有架构。

重点变成：

Domain Context
Technical Constraints
Existing Knowledge
External Dependencies
Architecture Decisions
Open Technical Questions

例如 SSD Simulator：

Simulator runtime
Event-driven model
FTL abstraction
NAND abstraction
Timing model
Workload model
Statistics

---

29. Open 输出

建议：

open/
├── engineering-context.md
├── impact-analysis.md
├── constraints.md
└── open-questions.md

其中：

engineering-context.md

描述 Story 所处的工程环境。

impact-analysis.md

描述影响范围。

constraints.md

描述技术限制。

open-questions.md

只保留尚未解决的工程问题。

---

30. Open Readiness Gate

Open 最终只回答：

«是否具备进入 Design 的条件？»

判断：

Requirement clear?       YES
Story scope clear?       YES
Acceptance clear?        YES
Architecture boundary?   YES
Technical context?       YES
Blocking question?       NO

则：

READY_FOR_DESIGN

如果发现需求级问题：

Open
 ↓
Requirement Decomposition

如果只是技术问题：

Open
 ↓
Design

---

31. Design 阶段重新定位

Design 不再重新理解需求。

输入：

Story
Acceptance Criteria
Conceptual Architecture
Major Interfaces
Engineering Context
Impact Analysis
Constraints

输出：

Detailed Technical Design

---

32. Design 的核心职责

Conceptual Architecture
        ↓
Detailed Architecture
        ↓
Module Design
        ↓
Interface Design
        ↓
Data Structure
        ↓
Algorithm
        ↓
State Machine
        ↓
Concurrency
        ↓
Memory
        ↓
Error Handling
        ↓
Test Strategy

---

33. Design Coverage

Design Agent 必须检查：

Acceptance Criteria
        ↓
Design Coverage

例如：

AC-001 → D-001
AC-002 → D-002
AC-003 → D-003
AC-004 → D-004

不能出现：

AC-005
   ↓
No Design Coverage

如果存在，Design Review 必须阻止继续。

---

34. Build 阶段

Build 输入：

Story
Acceptance Criteria
Detailed Design

输出：

Implementation
Unit Tests
Build Result

Build Agent 不应重新定义需求。

如果发现：

Requirement problem

回退：

Build
 ↓
Design / Requirement Decomposition

而不是自行改变需求。

---

35. Verify 阶段

Verify 的核心是：

«根据 Acceptance Criteria 判断系统是否真正满足需求。»

例如：

AC-001 PASS
AC-002 PASS
AC-003 PASS
AC-004 FAIL

最终输出：

Verification Result
Test Evidence
Failed Criteria
Regression Result

---

36. 完整 Traceability

整个流程建立：

REQ-001
   │
   ├── STORY-001
   │      │
   │      ├── AC-001
   │      ├── AC-002
   │      └── AC-003
   │             │
   │             ├── Design D-001
   │             ├── Code C-001
   │             └── Test T-001
   │
   └── STORY-002
          │
          ├── AC-004
          └── AC-005

最终：

Requirement
     ↓
Story
     ↓
Acceptance Criteria
     ↓
Design
     ↓
Code
     ↓
Test
     ↓
Evidence

---

37. CodeGraph 的定位

CodeGraph 主要负责：

Code
 ↓
Architecture
 ↓
Module
 ↓
Function
 ↓
Call Graph
 ↓
Data Flow

对于 Existing Codebase：

Story
 ↓
Acceptance Criteria
 ↓
Open
 ↓
CodeGraph
 ↓
Affected Code

从而帮助 Agent 理解：

Where to modify?
What already exists?
What can be reused?
What will be affected?

---

38. OpenViking / Knowledge Base 的定位

OpenViking / Knowledge Base 更适合：

Requirement
Design
Decision
Architecture Knowledge
Domain Knowledge
Historical Context
Engineering Rules

形成：

Human Decision
      ↓
Knowledge
      ↓
Future Agent

避免 Agent 每次重新推理相同的问题。

---

39. Agent 架构

推荐保持 Agent 数量可控。

                    Main Agent
                        │
                        ▼
          Requirement Decomposition
              Agent + Human
                        │
                        ▼
                     Stories
                        │
                        ▼
                   Open Agent
                        │
                        ▼
                  Design Agent
                        │
                        ▼
                  Build Agent
                        │
                        ▼
                 Verify Agent

Review / Challenge 可以作为横向能力：

Requirement → Challenge
Open        → Review
Design      → Review
Build       → Code Review
Verify      → Verification Review

---

40. Requirement Decomposition Agent

职责：

Requirement Analysis
Requirement Interview
Ambiguity Detection
Capability Decomposition
Conceptual Architecture Proposal
Major Interface Proposal
Story Proposal
Acceptance Criteria Proposal
Dependency Analysis
Consistency Check
Completeness Check

禁止：

自动冻结需求
自动改变 Human Decision
直接 Coding
直接进入详细设计

---

41. Challenge / Review Agent

职责：

Completeness
Consistency
Story Boundary
Acceptance Testability
Architecture Fit
Dependency
Scope Creep
Hidden Assumption

核心问题：

«“如果这个需求交给另一个工程师，他是否可以不依赖原始对话而正确理解？”»

---

42. Main Agent

Main Agent 是整个流程的 Orchestrator。

负责：

阶段切换
Agent 调度
Human Interaction
Artifact Management
Decision Tracking
State Tracking
Failure Recovery

但不替代 Human 的关键决策。

---

43. Human Decision Points

建议保留以下 Gate：

GATE-01
Requirement Scope Approval

GATE-02
Conceptual Architecture Approval

GATE-03
Story Map Approval

GATE-04
Acceptance Criteria Approval

GATE-05
Design Approval

GATE-06
Implementation Acceptance

其中最重要的是：

GATE-01
GATE-02
GATE-03

因为这些决定会影响整个后续工程。

---

44. OpenCode Hooks / Plugins

整个流程可以通过 OpenCode 的 Hooks / Plugins 实现自动化控制。

例如：

Story Freeze
    ↓
Hook
    ↓
Validate Story
    ↓
Generate Context Task
    ↓
Open Agent

Design 完成：

Design Complete
    ↓
Hook
    ↓
AC Coverage Check
    ↓
Review Agent
    ↓
PASS
    ↓
Build

Verify：

Verify Complete
    ↓
Hook
    ↓
Check AC Status
    ↓
All PASS?
    │
    ├── YES → Complete
    └── NO  → Failure Handling

---

45. 状态机

建议定义统一 Workflow State：

EPIC_CREATED
     ↓
DECOMPOSITION
     ↓
HUMAN_REVIEW
     ↓
STORY_FROZEN
     ↓
OPEN
     ↓
OPEN_REVIEW
     ↓
READY_FOR_DESIGN
     ↓
DESIGN
     ↓
DESIGN_REVIEW
     ↓
READY_FOR_BUILD
     ↓
BUILD
     ↓
VERIFY
     ↓
ACCEPTED

异常状态：

NEEDS_REQUIREMENT_CLARIFICATION
NEEDS_ARCHITECTURE_DECISION
NEEDS_DESIGN_REVISION
BUILD_FAILED
VERIFICATION_FAILED

---

46. Greenfield SSD Simulator 示例

完整流程：

Epic:

构建 SSD Simulator

Requirement Decomposition

得到：

Goal:
SSD algorithm research simulator

Capabilities:
- Runtime
- Host IO
- FTL
- NAND
- Workload
- Statistics

Conceptual Architecture：

Host
 ↓
Scheduler
 ↓
FTL
 ↓
NAND

Major Interfaces：

Host.submit_io
FTL.submit_io
NAND.submit_request
Runtime.schedule_event

Stories：

STORY-001
Minimal Write Path

STORY-002
Read / Write Data Consistency

STORY-003
FTL Mapping

STORY-004
NAND Model

STORY-005
Garbage Collection

STORY-006
Workload

STORY-007
Statistics

---

47. STORY-001 进入 Open

Open 不再讨论：

SSD Simulator 是什么？

而是分析：

Event Runtime
IO abstraction
FTL boundary
NAND boundary
Timing model
Relevant domain knowledge

然后：

READY_FOR_DESIGN

---

48. STORY-001 进入 Design

Design：

Simulator
│
├── Runtime
├── Host Interface
├── FTL Interface
├── NAND Interface
└── Event Queue

详细定义：

IORequest
FtlRequest
NandRequest
SimEvent

定义：

FtlSubmitIO()
NandSubmitRequest()
ScheduleEvent()

设计：

IO state machine
Event lifecycle
Completion path
Error handling

---

49. 为什么这个模式特别适合 SSD Firmware

SSD / UFS Firmware 通常具有：

复杂状态机
大量模块
严格接口
实时约束
资源限制
硬件依赖
并发
异常路径
性能约束

如果直接：

Requirement → Coding

Agent 很容易产生：

错误架构理解
错误接口
错误模块边界
错误状态转换
错误资源模型

加入：

Requirement
 ↓
Conceptual Architecture
 ↓
Open
 ↓
Detailed Design

可以显著降低这种风险。

---

50. 最终流程定义

最终建议将公司内部 AI Firmware Development Workflow 定义为：

┌──────────────────────────────────────┐
│         REQUIREMENT DECOMPOSITION   │
│                                      │
│ Human Lead + Agent Assist            │
│                                      │
│ Requirement                          │
│ Capability                           │
│ Story                                │
│ Acceptance Criteria                  │
│ Conceptual Architecture              │
│ Major Interface                      │
│ Dependency                           │
│ Constraint                            │
└──────────────────┬───────────────────┘
                   │
             HUMAN APPROVAL
                   │
                   ▼
┌──────────────────────────────────────┐
│                 OPEN                 │
│                                      │
│ Context                              │
│ Existing Architecture                │
│ Codebase Analysis                    │
│ Impact                               │
│ Constraints                          │
│ Open Questions                       │
└──────────────────┬───────────────────┘
                   │
                   ▼
┌──────────────────────────────────────┐
│                DESIGN                │
│                                      │
│ Detailed Architecture               │
│ Module                               │
│ API                                  │
│ Data Structure                       │
│ Algorithm                            │
│ State Machine                        │
│ Concurrency                          │
│ Memory                               │
│ Error Handling                       │
│ Test Strategy                        │
└──────────────────┬───────────────────┘
                   │
                   ▼
┌──────────────────────────────────────┐
│                 BUILD                │
│                                      │
│ Plan → Code → Unit Test              │
└──────────────────┬───────────────────┘
                   │
                   ▼
┌──────────────────────────────────────┐
│                VERIFY                │
│                                      │
│ Acceptance Criteria                  │
│ Test → Evidence → Result             │
└──────────────────────────────────────┘

---

51. 最终职责边界

阶段| 核心问题| 主要责任
Requirement Decomposition| Why / What| 需求、Story、AC、概念架构
Open| Where / Context| 环境、代码、影响、约束
Design| How| 详细技术设计
Build| Implement| 代码实现
Verify| Does it satisfy?| 验证和验收

最重要的边界：

«Requirement Decomposition 定义“要解决什么问题以及系统的大致边界”。»

«Open 理解“这个问题所处的工程环境”。»

«Design 定义“具体如何实现”。»

---

52. 核心设计原则总结

Principle 1

Human owns requirements and major architecture decisions.

Principle 2

Agent assists through analysis, questioning, proposal and review.

Principle 3

Story is a value-oriented unit, not a source-code unit.

Principle 4

Conceptual Architecture belongs before Story freeze for Greenfield projects.

Principle 5

Major Interfaces can be defined during Requirement Decomposition, detailed APIs belong to Design.

Principle 6

Open focuses on engineering context, not requirement re-analysis.

Principle 7

Design focuses on detailed HOW, not redefining WHAT.

Principle 8

Acceptance Criteria remain the invariant requirement baseline throughout the workflow.

Principle 9

Every downstream artifact should be traceable back to Story / AC.

Principle 10

Human decision points should be explicit and persisted as Decision Records.

---

53. 推荐最终模型

整个方法论可以最终浓缩成：

                  HUMAN
                    │
                    ▼
              Epic Requirement
                    │
                    ▼
        ┌───────────────────────┐
        │ Requirement           │
        │ Decomposition         │
        │                       │
        │ ATDD                  │
        │ Story Mapping         │
        │ Conceptual Design     │
        │ Major Interfaces      │
        └───────────┬───────────┘
                    │
              Human Approval
                    │
                    ▼
                 Stories
                    │
                    ▼
                  OPEN
                    │
          Context / Impact
                    │
                    ▼
                 DESIGN
                    │
             Detailed HOW
                    │
                    ▼
                  BUILD
                    │
                    ▼
                 VERIFY
                    │
                    ▼
               Acceptance

最终形成：

        Human Intent
             │
             ▼
        Requirement
             │
             ▼
          Story
             │
             ▼
           ATDD
             │
             ▼
Conceptual Architecture
             │
             ▼
            Open
             │
             ▼
       Detailed Design
             │
             ▼
            Code
             │
             ▼
           Verify
             │
             ▼
         Evidence

这套结构可以作为当前 Comet 工作流适配时的方法论基线。这份版本我建议你先作为 V1.0 冻结基线，然后再针对你当前的 Comet 0.4.0-beta.1 实现，逐项映射成 Command / Skill / Agent / Hook / Artifact / State Transition，这样不会把“方法论”和“Comet 具体实现”过早耦合。