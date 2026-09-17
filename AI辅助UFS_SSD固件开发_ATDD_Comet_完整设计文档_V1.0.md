# AI 辅助 UFS/SSD 固件开发平台

## ATDD × Comet 五阶段闭环总体设计

**版本：V1.0**\
**定位：公司内部 AI 辅助 UFS/SSD Firmware 开发平台方法论与实现设计**\
**核心技术栈：Comet / OpenCode / CodeGraph / graphify /
OpenViking(OpenWiki) / OpenCode Plugins & Hooks / 本地 LLM**

------------------------------------------------------------------------

## 1. 设计目标

本方案面向 UFS/SSD Firmware、Embedded C、ARM Controller 及 Simulator
等研发场景，目标不是让 Agent
"自动写更多代码"，而是建立一个**需求可验收、工程上下文可追溯、设计可验证、实现可审查、结果有证据**的
AI 辅助研发闭环。

核心原则：

> **ATDD 从需求分解开始，而不是从 Build 或测试阶段才开始。**

完整链路：

``` text
Epic / PRD
    │
    ▼
Requirement Decomposition
    │
    ├─ Requirement
    ├─ Capability
    ├─ Story
    ├─ Acceptance Criteria
    ├─ Scenario
    └─ Conceptual Architecture
    │
    ▼
Human Review / Story Freeze
    │
    ▼
Open
    │
    ├─ Engineering Context
    ├─ Impact Analysis
    ├─ Constraints
    └─ AC → Engineering Boundary
    │
    ▼
Design
    │
    ├─ Detailed Design
    ├─ AC → Design Coverage
    ├─ Interface / State / Failure Model
    └─ Test Strategy
    │
    ▼
Build
    │
    ├─ Implementation Plan
    ├─ Code
    ├─ Unit Test
    ├─ Build
    ├─ Static Analysis
    └─ Implementation Review
    │
    ▼
Verify
    │
    ├─ AC / Scenario Execution
    ├─ System / Integration / E2E Test
    └─ Evidence
    │
    ▼
Accepted → Release → Retrospective
```

------------------------------------------------------------------------

# 2. 核心方法论：ATDD 是贯穿所有阶段的主线

传统 AI Coding 容易形成：

``` text
需求
 → Agent 理解
 → Agent 设计
 → Agent 写代码
 → Agent 自测
```

问题是每一步都可能产生新的"解释"，最终代码实现的东西可能已经偏离原始需求。

本方案采用：

``` text
REQ
 ↓
Capability
 ↓
Story
 ↓
AC
 ↓
Scenario
 ↓
Engineering Boundary
 ↓
Design
 ↓
Implementation
 ↓
Test
 ↓
Evidence
```

也就是：

``` text
REQ → Capability → Story → AC → Scenario
                         ↓
                     Design
                         ↓
                       Code
                         ↓
                       Test
                         ↓
                     Evidence
```

因此 ATDD 不只是"写测试"，而是整个研发流程的**需求契约与追溯骨架**。

------------------------------------------------------------------------

# 3. 统一追溯模型

每一个开发项必须能够沿以下链路追溯：

``` text
REQ
 ↓
Capability
 ↓
Story
 ↓
AC
 ↓
Scenario
 ↓
Design Item
 ↓
Implementation
 ↓
Test
 ↓
Evidence
```

建议统一 ID：

  对象                  示例           产生阶段
  --------------------- -------------- ---------------------
  Requirement           REQ-001        Requirement
  Decision              DEC-003        Requirement / Human
  Assumption            ASM-002        Requirement
  Capability            CAP-001        Requirement
  Story                 STORY-012      Requirement
  Acceptance Criteria   AC-012-03      Requirement
  Scenario              SC-012-03-01   Requirement
  Design Item           DES-012-03     Design
  Implementation Item   IMP-012-03     Build
  Test                  TEST-012-03    Build / Verify
  Evidence              EVD-012-03     Verify

最低要求：

``` text
Code Change → STORY → AC → DES
Test        → AC
Evidence    → TEST → AC
```

任何代码、设计或测试无法关联 Story /
AC，都应进入审查，而不是默认视为合理工作。

------------------------------------------------------------------------

# 4. 五阶段职责总览

  -------------------------------------------------------------------------------------------------------------
  阶段            核心问题                     输入                输出            不负责
  --------------- ---------------------------- ------------------- --------------- ----------------------------
  Requirement     为什么做、做什么、验收什么   Epic / PRD          Frozen Story +  详细技术设计、编码
  Decomposition                                                    AC + Scenario + 
                                                                   L1 Architecture 

  Open            当前工程在哪里做、影响什么   Frozen Story + AC   Engineering     重新定义需求
                                                                   Context +       
                                                                   Impact +        
                                                                   Constraints +   
                                                                   Readiness       

  Design          为满足 AC，具体如何做        Frozen Story + Open Detailed        编码、改变冻结需求
                                               Context             Design +        
                                                                   AC→DES + Test   
                                                                   Strategy        

  Build           如何把设计可靠实现           READY_FOR_BUILD +   Code + Unit     修改 AC、替需求做决策
                                               Design              Test + Build +  
                                                                   Review          

  Verify          是否已经证明满足 AC          Code + AC + Test    AC→TEST→EVD +   以"代码看起来正确"代替验收
                                               Strategy            Regression +    
                                                                   Acceptance      
  -------------------------------------------------------------------------------------------------------------

一句话：

``` text
Requirement：为什么做、做什么、验收什么
Open：当前工程哪里做、影响什么、约束什么
Design：为满足每条 AC，具体如何做
Build：把确认过的设计实现出来
Verify：证明每条 AC 已满足
```

------------------------------------------------------------------------

# 5. Requirement Decomposition

## 5.1 定位

Requirement Decomposition 是 ATDD 的起点。

输入是模糊的 Epic / PRD / User Story；输出不是代码任务，而是：

> **可以被人确认、可以被测试、可以被后续阶段消费的 Frozen Story。**

------------------------------------------------------------------------

## 5.2 Step 1：需求理解

Requirement Agent 首先建立需求模型：

``` yaml
requirement:
  id: REQ-001
  goal: 要解决的问题与预期价值
  actors:
    - user
    - system
    - external_component
  in_scope:
    - ...
  out_of_scope:
    - ...
  constraints:
    - performance
    - memory
    - compatibility
    - hardware
  dependencies:
    - ...
  unknowns:
    - ...
```

此时禁止直接进入 Coding Plan。

所有未知项必须显式化。

------------------------------------------------------------------------

## 5.3 Step 2：Human-in-the-loop

Agent 不替人做关键产品和架构决策，而是把不确定性转换为少量高价值问题。

例如：

``` yaml
id: DEC-003
question: FTL 是否需要可插拔？
options:
  - 支持可插拔
  - 当前只支持内置实现
decision: 支持可插拔
owner: Human
reason: 后续算法研究需要
status: accepted
```

Human 必须确认：

-   产品目标；
-   Scope / Out of Scope；
-   关键性能、实时性、资源约束；
-   系统边界；
-   关键架构方向；
-   Story 边界；
-   优先级；
-   Acceptance Criteria。

------------------------------------------------------------------------

## 5.4 Step 3：Capability-first 分解

不要按照源码文件拆需求。

错误：

``` text
STORY-001：实现 ftl.c
STORY-002：实现 nand.c
```

正确：

``` text
SSD Simulator
├── Runtime
├── Host IO
├── FTL
├── NAND Model
├── Workload
└── Observability
```

然后形成纵向价值切片：

``` text
STORY-001：最小 Host Write 全链路
STORY-002：Read/Write 数据一致性
STORY-003：地址映射
STORY-004：垃圾回收
STORY-005：工作负载与性能统计
```

核心原则：

> Capability 是能力分类，不是源码模块；Story 是可独立验收的价值切片。

------------------------------------------------------------------------

# 6. Conceptual Architecture：需求阶段定义 L1 架构

在 Story Freeze 前建立概念架构。

定义：

-   系统边界；
-   组件；
-   组件职责；
-   主数据流；
-   主控制流；
-   主要接口边界；
-   依赖关系；
-   架构约束。

例如：

``` text
Host IO
   ↓
Scheduler
   ↓
FTL
   ↓
NAND Model
   ↓
Completion
   ↓
Host

FTL ─────→ Statistics
```

但这一阶段不定义：

-   C 函数签名；
-   struct；
-   队列实现；
-   lock；
-   memory pool；
-   具体算法；
-   具体状态机实现。

即：

``` text
Requirement L1：
“FTL 负责将 Host IO 转换为 NAND 操作”

Design：
“FTL.submit_io(...) 使用 xxx struct，
通过 xxx queue，
采用 xxx state machine，
在 xxx lock 下执行”
```

这样可以防止需求阶段过早陷入实现细节。

------------------------------------------------------------------------

# 7. Story + Acceptance Criteria

Story 必须是可观察的系统增量。

示例：

``` yaml
id: STORY-001
title: 最小 Host Write 全链路
source_requirements:
  - REQ-001

business_value:
  Host 能提交 Write IO 并收到 completion

scope:
  - Host 提交写请求
  - 请求进入 FTL
  - FTL 创建 NAND 操作
  - NAND 操作完成
  - Host 获得 completion

out_of_scope:
  - GC
  - 高级调度
  - 性能优化

acceptance_criteria:
  - id: AC-001
    statement: Simulator 可成功启动
  - id: AC-002
    statement: Host 可提交合法 Write IO
  - id: AC-003
    statement: 请求会到达 FTL
  - id: AC-004
    statement: FTL 会创建对应 NAND 操作
  - id: AC-005
    statement: NAND 完成后 Host 收到一次且仅一次 completion
```

复杂 AC 使用 Gherkin：

``` gherkin
Scenario: Submit a host write

Given Simulator 已初始化
When Host 提交合法 Write 请求
Then 请求到达 FTL
And FTL 生成 NAND 操作
And NAND 操作完成
And Host 收到一次 completion
```

------------------------------------------------------------------------

# 8. Challenge 与 Story Freeze

Freeze 前由 Challenge Agent / grill-me 对需求进行攻击性审查：

-   Story 是否过大；
-   是否过小；
-   Story 是否重叠；
-   是否存在能力遗漏；
-   是否可以独立验收；
-   AC 是否可测试；
-   AC 是否可观察；
-   AC 是否有歧义；
-   是否把实现方案写成需求；
-   依赖是否真实；
-   架构边界是否冲突；
-   是否存在隐藏假设。

Freeze 后，以下对象成为不可被 Build Agent 静默修改的基线：

``` text
Story Scope
Out of Scope
Acceptance Criteria
Scenario
关键架构边界
关键约束
Human Decision
```

如果发现问题：

``` text
需求问题 → Requirement
架构方向问题 → Human Decision
设计问题 → Design
实现问题 → Build
```

而不是由当前 Agent 自行"修正需求"。

------------------------------------------------------------------------

# 9. Human Gates

建议保留六个 Gate：

  Gate   内容
  ------ ----------------------------------
  G1     Epic 目标、范围、约束
  G2     概念架构与主要边界
  G3     Story Map、依赖、优先级
  G4     AC 与 Scenario
  G5     Detailed Design 与 AC Coverage
  G6     Verify 结果与 Release Acceptance

其中 G1～G4 是最重要的需求控制点。

原则：

> Agent 可以提高决策质量，但不能替 Human 决定产品目标和关键架构。

------------------------------------------------------------------------

# 10. Open 阶段

## 10.1 核心定位

Open 不再重新理解 PRD。

它回答：

> 这个已经冻结、可验收的
> Story，在当前工程中应该在哪里实现，会影响什么，哪些事实和约束必须带进
> Design？

------------------------------------------------------------------------

## 10.2 输入

``` text
Frozen Story
+ REQ / DEC / ASM
+ AC / Scenario
+ Conceptual Architecture
+ Challenge Result
+ Freeze Record
```

Open 首先执行 Frozen Story Validation：

``` text
Story = frozen?
source requirements = present?
scope / out-of-scope = complete?
AC = uniquely identified?
AC = observable?
Scenario = present?
Challenge = passed?
Decision = accepted?
Freeze Record = present?
```

失败则禁止进入工程 Open。

------------------------------------------------------------------------

# 11. Open 工程调查

对于 Existing Codebase：

``` text
Architecture
Modules
Call Chain
Data Flow
Reusable Components
Affected Files
Affected Interfaces
Affected Tests
Compatibility
Build Rules
Static Analysis
Historical Decisions
```

核心工具：

``` text
CodeGraph
graphify
OpenViking / OpenWiki
Repository Search
OpenCode Agent
```

推荐查询模式：

``` text
Story / AC
   ↓
CodeGraph
   ↓
Architecture / Call Chain / Data Flow
   ↓
Affected Engineering Boundary
```

------------------------------------------------------------------------

# 12. Open 的核心产物

``` text
comet-artifacts/open/
└── STORY-001/
    ├── engineering-context.md
    ├── impact-analysis.md
    ├── constraints.md
    ├── ac-boundary-map.md
    ├── open-questions.md
    └── readiness-check.md
```

职责：

  文件                  内容
  --------------------- -------------------------------------------
  engineering-context   架构、模块、调用链、数据流、可复用能力
  impact-analysis       Story / AC 对模块、接口、配置、测试的影响
  constraints           编译、平台、性能、资源、协议、规范
  ac-boundary-map       AC → 工程边界 → Design 待决事项
  open-questions        需求/设计/工程阻断问题
  readiness-check       是否 Ready for Design

------------------------------------------------------------------------

# 13. AC → Engineering Boundary

这是 Requirement 与 Design 之间的关键桥梁。

例如：

  AC       工程边界          已确认事实         Design 待决
  -------- ----------------- ------------------ ------------------------
  AC-001   Runtime Init      已存在启动入口     错误状态如何传播
  AC-002   Host→FTL          Scheduler 已存在   请求生命周期
  AC-005   NAND→Completion   已存在 callback    一次性 completion 保证

Open 不解决"怎么实现"。

它只确保 Design 知道：

``` text
这条 AC
↓
对应哪个工程边界
↓
现有工程事实是什么
↓
Design 必须解决什么
```

------------------------------------------------------------------------

# 14. Open Readiness

只有满足：

``` text
Story Scope Clear              PASS
AC Clear                       PASS
Architecture Boundary Clear   PASS
Engineering Context Known     PASS
Blocking Requirement Issue     NONE
```

才能：

``` text
READY_FOR_DESIGN
```

否则：

``` text
NEEDS_REQUIREMENT_CLARIFICATION
NEEDS_ARCHITECTURE_DECISION
BLOCKED
```

------------------------------------------------------------------------

# 15. Design 阶段

## 15.1 核心定位

Design 回答：

> 在已冻结 Story、AC、工程上下文和约束下，为满足每一条
> AC，具体如何实现？

------------------------------------------------------------------------

## 15.2 输入

``` text
Frozen Story
+ AC
+ Scenario
+ Conceptual Architecture
+ Open Engineering Context
+ Impact Analysis
+ Constraints
+ AC Boundary Map
+ Confirmed Decisions
```

------------------------------------------------------------------------

# 16. Design 的核心输出

``` text
comet-artifacts/design/
└── STORY-001/
    ├── detailed-design.md
    ├── ac-coverage.md
    ├── interface-contracts.md
    ├── state-and-lifecycle.md
    ├── failure-modes.md
    ├── test-strategy.md
    └── design-readiness.md
```

其中至少必须存在：

``` text
detailed-design.md
ac-coverage.md
test-strategy.md
```

复杂 Story 再增加其他文件。

------------------------------------------------------------------------

# 17. AC → Design Coverage

这是整个 Design 阶段最重要的 ATDD 约束。

``` text
AC-001
 ├─ DES-001：启动流程
 └─ DES-002：错误状态传播

AC-002
 └─ DES-003：Host IO 校验

AC-005
 ├─ DES-004：Completion 生命周期
 └─ DES-005：重复 completion 防护
```

矩阵：

  AC       Scenario   Design        工程边界          验证策略           状态
  -------- ---------- ------------- ----------------- ------------------ ---------
  AC-001   SC-001     DES-001       Runtime           Integration        covered
  AC-002   SC-002     DES-003       Host/FTL          Unit+Integration   covered
  AC-005   SC-005     DES-004/005   NAND/Completion   E2E                covered

规则：

``` text
任何 AC = uncovered
→ Design Review FAIL
→ 禁止 Build
```

反向检查：

``` text
DES 没有关联 AC
→ 检查是否属于无需求依据的复杂度
```

------------------------------------------------------------------------

# 18. Detailed Design 的边界

Design 可以定义：

-   模块；
-   API；
-   消息；
-   数据结构；
-   生命周期；
-   状态机；
-   并发；
-   锁；
-   内存；
-   错误处理；
-   Retry；
-   Recovery；
-   Performance；
-   Observability；
-   Compatibility；
-   Test Strategy。

但不能：

-   修改 Frozen Scope；
-   删除 AC；
-   把实现方便性写成需求；
-   编写生产代码；
-   编写最终测试代码；
-   替 Build 创建实现任务清单。

------------------------------------------------------------------------

# 19. Design 与 OpenSpec 的关系

避免两份技术设计成为"双重真相"。

建议：

``` text
Canonical Design：
comet-artifacts/design/STORY-001/detailed-design.md
```

OpenSpec `design.md` 只作为索引：

``` text
Story: STORY-001

Canonical Design:
comet-artifacts/design/STORY-001/detailed-design.md

AC Coverage:
comet-artifacts/design/STORY-001/ac-coverage.md

Test Strategy:
comet-artifacts/design/STORY-001/test-strategy.md
```

现有 `.comet.yaml` 的 `design_doc` 指向 Canonical Design。

------------------------------------------------------------------------

# 20. Design Readiness

Build 前必须：

``` text
Frozen Story                 PASS
Open Readiness               PASS
Every AC → DES               PASS
Every DES → Story/AC         PASS
Interface Defined            PASS
State Defined                PASS
Error Path Defined           PASS
High-risk AC Strategy        PASS
Test Strategy Complete       PASS
Requirement Blockers         NONE
Human G5                     PASS
```

结果：

``` text
READY_FOR_BUILD
NEEDS_REQUIREMENT_CLARIFICATION
NEEDS_ARCHITECTURE_DECISION
NEEDS_OPEN_INVESTIGATION
BLOCKED
```

------------------------------------------------------------------------

# 21. Build 阶段

## 21.1 核心定位

Build 不是"让 Agent 自己想怎么写"。

它回答：

> 如何把已经确认的 Design
> 可靠地实现成代码，并证明实现本身通过工程质量检查？

Build 输入必须是：

``` text
READY_FOR_BUILD
+
Frozen Story
+
AC / Scenario
+
Detailed Design
+
AC → DES Coverage
+
Test Strategy
```

------------------------------------------------------------------------

# 22. Build 五层职责

Build 建议拆成：

``` text
Preflight
   ↓
Implementation Planning
   ↓
Code Implementation
   ↓
Unit Test / Build / Static Check
   ↓
Implementation Review
   ↓
Handoff to Verify
```

------------------------------------------------------------------------

# 23. Build Step 0：Preflight

检查：

``` text
Story frozen?
Open ready?
Design ready?
AC coverage complete?
Test strategy complete?
Human G5 approved?
No blocking requirement?
```

任何失败禁止编码。

------------------------------------------------------------------------

# 24. Build Step 1：Implementation Planning

把 Design Item 转换为 Implementation Item：

``` text
DES
 ↓
IMP
 ↓
CODE
 ↓
TEST
```

例如：

``` yaml
id: IMP-001
story: STORY-001
ac:
  - AC-005
design:
  - DES-004
  - DES-005

target:
  modules:
    - ftl
    - completion

changes:
  - implement completion lifecycle
  - prevent duplicate completion

tests:
  - TEST-005-01
```

这里的 Implementation Plan 是 Build 的工作计划，不是新的需求来源。

------------------------------------------------------------------------

# 25. Build Step 2：CodeGraph 驱动实现

Coding Agent 开始编码前，应先建立代码上下文：

``` text
Detailed Design
      ↓
CodeGraph
      ↓
Affected Components
      ↓
Call Chain
      ↓
Data Flow
      ↓
Existing API / Struct / State
      ↓
Tests
      ↓
Implementation
```

工具职责：

### CodeGraph

回答：

``` text
谁调用谁？
谁依赖谁？
这个结构在哪里使用？
这个 API 的调用链是什么？
修改这个模块会影响什么？
```

### graphify

用于辅助代码知识图谱、关系探索及工程上下文组织。

### OpenViking / OpenWiki

用于：

``` text
历史设计
开发规范
架构知识
技术决策
团队经验
项目文档
```

核心原则：

> CodeGraph 更偏"当前代码事实"；知识库更偏"工程知识与历史上下文"。

------------------------------------------------------------------------

# 26. Build Step 3：纵向实现

对于 Firmware / Simulator，不建议简单按照文件逐个实现：

``` text
ftl.c
nand.c
scheduler.c
```

更适合按照可验证链路：

``` text
Host
 ↓
Scheduler
 ↓
FTL
 ↓
NAND
 ↓
Completion
```

例如 Story-001：

``` text
Slice-1
Host submit
 ↓
FTL receive

Slice-2
FTL
 ↓
NAND request

Slice-3
NAND completion
 ↓
Host completion
```

每个 Slice 都保持：

``` text
AC
→ Design
→ Code
→ Unit Test
```

------------------------------------------------------------------------

# 27. Build Agent / Coding Agent / Review Agent

建议不无限增加 Agent。

推荐：

``` text
Main Developer Agent
       │
       ├── Build Agent
       │      ├── Implementation Planning
       │      ├── CodeGraph Exploration
       │      ├── Coding Agent
       │      └── Test/Build
       │
       └── Build Review Agent
```

Build Review Agent 检查：

### Requirement Compliance

代码是否仍在 Frozen Scope 内。

### Design Compliance

代码是否实现 Design。

### Scope Compliance

是否出现未授权功能。

### Engineering Quality

是否符合 C/ARM/Firmware 规范。

### Test Completeness

新增代码是否具有对应测试。

但 Build Review 不替代 Verify。

------------------------------------------------------------------------

# 28. Build Review 与 Verify 的边界

Build Review：

> **代码有没有正确实现 Design？**

Verify：

> **系统行为有没有满足 AC？**

因此：

``` text
Design
  ↓
Build
  ↓
Implementation Review
  ↓
Verify
  ↓
AC Acceptance
```

即使 Build Review PASS，也不能直接 Accepted。

------------------------------------------------------------------------

# 29. Build 问题分类与回流

严格分类：

``` text
AC 不清楚 / 冲突
        ↓
Requirement

架构方向错误
        ↓
Human Architecture Decision

Design 有漏洞
        ↓
Design

Open 缺少工程事实
        ↓
Open

代码 bug / 编译失败 / 单测失败
        ↓
Build
```

禁止：

``` text
Build Agent 为了通过测试
→ 偷改 AC
→ 删除 Scenario
→ 把功能改成 Out of Scope
→ 用 Mock 掩盖主链路问题
```

------------------------------------------------------------------------

# 30. Build 产物

推荐：

``` text
comet-artifacts/build/
└── STORY-001/
    ├── preflight.md
    ├── implementation-plan.md
    ├── implementation-log.md
    ├── code-changes.md
    ├── unit-test-plan.md
    ├── unit-test-result.md
    ├── build-result.md
    ├── static-analysis.md
    ├── review.md
    └── build-handoff.md
```

------------------------------------------------------------------------

# 31. Verify 阶段

## 31.1 核心定位

Verify 不从代码出发。

它从：

``` text
Frozen AC
```

出发。

核心问题：

> 每一条 AC 是否已经被真实测试和证据证明？

------------------------------------------------------------------------

# 32. Verify 输入

``` text
Frozen Story
+ AC
+ Scenario
+ Design
+ Test Strategy
+ Code
+ Unit Test Result
+ Build Result
+ Static Analysis
```

------------------------------------------------------------------------

# 33. AC → TEST → EVIDENCE

每条 AC 必须有：

``` yaml
ac: AC-005
scenario: SC-005-01
test_case: TEST-005
method: integration
result: pass

evidence:
  - test-report
  - log
  - trace
  - waveform

regression_result: pass
verified_by: Verify Agent
```

最终验收矩阵：

  AC       Scenario   Test       Result   Evidence
  -------- ---------- ---------- -------- ----------------------------
  AC-001   SC-001     TEST-001   PASS     startup log
  AC-002   SC-002     TEST-002   PASS     IO log
  AC-003   SC-003     TEST-003   PASS     trace
  AC-004   SC-004     TEST-004   PASS     NAND trace
  AC-005   SC-005     TEST-005   FAIL     duplicate completion trace

只要必需 AC 为：

``` text
FAIL
BLOCKED
```

就不能：

``` text
Accepted
```

------------------------------------------------------------------------

# 34. Verify 的测试层级

根据 AC 选择：

``` text
Unit Test
Integration Test
System Test
Simulator Test
End-to-End Test
Regression Test
Manual Test
```

不是所有 AC 都必须使用 E2E。

关键是：

> **验证方法必须足以证明 AC。**

例如：

``` text
内部算法 AC → Unit
模块交互 AC → Integration
完整 IO 行为 → System / Simulator
Host → FTL → NAND → Completion → E2E
```

------------------------------------------------------------------------

# 35. Verify Failure 回流

``` text
AC FAIL
   │
   ├── Code implementation bug → Build
   │
   ├── Design insufficient      → Design
   │
   ├── Requirement ambiguous    → Requirement
   │
   └── Environment issue        → Verify / Environment
```

绝不能：

``` text
测试失败
→ 修改 AC
→ 删除 Scenario
→ Accepted
```

------------------------------------------------------------------------

# 36. Comet 最终状态机

长期目标：

``` text
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
    ↓
RELEASED
```

异常状态：

``` text
NEEDS_REQUIREMENT_CLARIFICATION
NEEDS_ARCHITECTURE_DECISION
NEEDS_OPEN_INVESTIGATION
NEEDS_DESIGN_REVISION
BUILD_FAILED
VERIFICATION_FAILED
BLOCKED
```

------------------------------------------------------------------------

# 37. ATDD 在五阶段中的贯彻方式

这是整个设计的核心。

## Requirement

建立：

``` text
REQ
 ↓
Story
 ↓
AC
 ↓
Scenario
```

形成"验收契约"。

## Open

建立：

``` text
AC
 ↓
Engineering Boundary
```

确保每条 AC 有真实工程落点。

## Design

建立：

``` text
AC
 ↓
DES
```

确保每条 AC 有实现方案。

## Build

建立：

``` text
DES
 ↓
IMP
 ↓
CODE
 ↓
UNIT TEST
```

确保实现严格来源于设计。

## Verify

建立：

``` text
AC
 ↓
TEST
 ↓
EVIDENCE
```

证明需求已经真正实现。

最终形成：

``` text
REQ
 ↓
STORY
 ↓
AC
 ↓
ENGINEERING BOUNDARY
 ↓
DES
 ↓
IMP
 ↓
CODE
 ↓
TEST
 ↓
EVIDENCE
```

这就是完整 ATDD 闭环。

------------------------------------------------------------------------

# 38. Agent 总体架构

推荐：

``` text
                    Human
                      │
                      ▼
              Main Developer Agent
                      │
       ┌──────────────┼───────────────┐
       ▼              ▼               ▼
Requirement        Open            Design
Agent              Agent           Agent
       │              │               │
       │          CodeGraph        Brainstorm
       │          graphify         Design Review
       │          Knowledge Base      │
       │                              ▼
       └────────────────────────── Build
                                      │
                              ┌───────┴────────┐
                              ▼                ▼
                         Coding Agent     Build Review
                              │
                              ▼
                           Verify
                              │
                              ▼
                        Verify Agent
```

建议保持 Agent 数量可控。

Agent 是职责边界，不是越多越好。

------------------------------------------------------------------------

# 39. Agent 职责

  Agent                   核心职责
  ----------------------- ------------------------------------------------------
  Main Agent              阶段调度、状态管理、Human Interaction、Artifact 管理
  Requirement Agent       需求澄清、Capability、Story、AC、L1 架构
  Challenge Agent         Challenge、发现遗漏和歧义
  Open Agent              CodeGraph 调查、影响分析、工程上下文
  Design Agent            详细技术设计、AC→DES
  Build Agent             Implementation Plan、代码实现、测试、构建
  Build Review Agent      设计符合性、范围、工程质量
  Verify Agent            AC 验收、测试、证据、回归
  Firmware Expert Agent   专项技术问题、知识库查询

------------------------------------------------------------------------

# 40. OMO Team Mode 的使用位置

OMO Team Mode 不需要替代 Comet。

更适合在：

``` text
Requirement Decomposition
Design
```

这些需要并行探索、讨论和角色协作的阶段使用。

例如 Requirement：

``` text
Main Agent
 ├─ Requirement Explorer
 ├─ Architecture Explorer
 └─ Challenge Agent
```

Design：

``` text
Main Design Agent
 ├─ Firmware Design Expert
 ├─ Concurrency Expert
 └─ Review Agent
```

但最终：

``` text
Human
```

仍负责关键决策。

尽量复用 OMO 自身的 Agent orchestration / communication
机制，不再重复建设一套平行 mailbox 协议。

------------------------------------------------------------------------

# 41. OpenCode Hooks / Plugins

OpenCode Hook / Plugin 的定位：

> **校验、记录、触发、推进，而不是替 Human 做关键决策。**

推荐自动化点：

``` text
Story Freeze
   ↓
Story Validator
   ↓
创建 Open

Open Complete
   ↓
Readiness Hook
   ↓
创建 Design

Design Complete
   ↓
AC→DES Validator
   ↓
创建 Build

Build Complete
   ↓
Build/Test/Static Validator
   ↓
创建 Verify

Verify Complete
   ↓
AC→TEST→EVD Validator
   ↓
Accepted / 回流
```

------------------------------------------------------------------------

# 42. Hook 应该做什么

适合 Hook：

-   检查文件存在；
-   检查 YAML/Markdown schema；
-   检查 ID；
-   检查 AC coverage；
-   检查 state；
-   检查 build；
-   检查 unit test；
-   检查 static analysis；
-   检查 traceability；
-   自动生成 handoff；
-   自动创建下一阶段任务。

不适合 Hook：

-   决定产品目标；
-   决定关键架构；
-   自行修改 AC；
-   自动改变 Scope；
-   自动接受风险。

原则：

``` text
Agent = Think
Human = Decide
Hook = Enforce
Runtime = Orchestrate
```

------------------------------------------------------------------------

# 43. OpenSpec / Comet 的兼容式改造

当前 Classic Comet 从 Open 开始。

第一阶段不建议立即修改 Classic Runtime，把 Requirement Phase
强行加入现有 state enum。

采用：

``` text
PRD / Epic
   ↓
prd-split
   ↓
grill-me Challenge
   ↓
Human Story Freeze
   ↓
requirements validator
   ↓
comet-open
   ↓
comet-design
   ↓
comet-build
   ↓
comet-verify
```

这样：

-   保留 Classic Open/Design/Build/Verify；
-   Requirement 成为受强校验的前置阶段；
-   Open 输入从模糊 PRD 变成 Frozen Story；
-   后续再逐步把 Requirement 纳入 Runtime。

------------------------------------------------------------------------

# 44. OpenSpec 产物职责

建议：

  OpenSpec 产物        新职责
  -------------------- --------------------------------------------------
  proposal.md          Frozen Story 的规范化镜像
  specs/\*\*/spec.md   AC / Scenario 的规范化镜像
  design.md            工程上下文/影响/约束摘要或 Canonical Design 索引
  tasks.md             Design 确认后形成的 Build 实现任务

关键原则：

> 不要让 OpenSpec、Comet Artifact、Design Doc
> 三处同时成为技术设计的权威来源。

Canonical Source 应明确。

------------------------------------------------------------------------

# 45. tasks.md 的处理

当前 Classic 可能依赖 `tasks.md` 才能完成状态闭包。

因此有两个方案：

### 兼容方案

Open 临时产生未细化任务，Design / Build 再替换。

缺点：

``` text
tasks.md 权威性不清楚
```

### 推荐方案

调整 OpenSpec Schema / Runtime：

``` text
Open：
proposal + spec + open-context + traceability

Design：
Detailed Design

Build：
tasks / implementation-plan
```

即：

> `tasks.md` 应成为 Build 的实现权威，而不是 Open 的需求拆解产物。

------------------------------------------------------------------------

# 46. 推荐 Artifact 目录

``` text
comet-artifacts/
│
├── requirements/
│   ├── requirement.md
│   ├── decisions.md
│   ├── assumptions.md
│   ├── capability-map.md
│   ├── conceptual-architecture.md
│   ├── interface-boundaries.md
│   ├── dependency-map.md
│   ├── challenge/
│   └── stories/
│       └── STORY-001.md
│
├── open/
│   └── STORY-001/
│       ├── engineering-context.md
│       ├── impact-analysis.md
│       ├── constraints.md
│       ├── ac-boundary-map.md
│       ├── open-questions.md
│       └── readiness-check.md
│
├── design/
│   └── STORY-001/
│       ├── detailed-design.md
│       ├── ac-coverage.md
│       ├── interface-contracts.md
│       ├── state-and-lifecycle.md
│       ├── failure-modes.md
│       ├── test-strategy.md
│       └── design-readiness.md
│
├── build/
│   └── STORY-001/
│       ├── preflight.md
│       ├── implementation-plan.md
│       ├── implementation-log.md
│       ├── code-changes.md
│       ├── unit-test-plan.md
│       ├── unit-test-result.md
│       ├── build-result.md
│       ├── static-analysis.md
│       ├── review.md
│       └── build-handoff.md
│
└── verify/
    └── STORY-001/
        ├── acceptance-matrix.md
        ├── regression-result.md
        └── evidence/
```

------------------------------------------------------------------------

# 47. 全流程输入输出合同

## Requirement

``` text
INPUT
Epic / PRD / User Story

PROCESS
Clarify
Capability Split
L1 Architecture
Story Mapping
ATDD
Challenge
Human Freeze

OUTPUT
Frozen Story
REQ / DEC / ASM
AC / Scenario
Conceptual Architecture
```

## Open

``` text
INPUT
Frozen Story
AC
Scenario
Architecture
Decision

PROCESS
Validate
CodeGraph Exploration
Impact Analysis
Constraint Analysis

OUTPUT
Engineering Context
Impact
Constraints
AC Boundary Map
Open Questions
Readiness
```

## Design

``` text
INPUT
Frozen Story
AC
Open Context
Impact
Constraints
Architecture

PROCESS
AC Coverage
Detailed Design
Interface Design
State Design
Failure Design
Test Strategy
Human Review

OUTPUT
Detailed Design
AC → DES
Test Strategy
Design Readiness
```

## Build

``` text
INPUT
READY_FOR_BUILD
Design
AC → DES
Test Strategy

PROCESS
Implementation Plan
Code
Unit Test
Build
Static Analysis
Review

OUTPUT
Code
Tests
Build Result
Static Result
Implementation Review
Build Handoff
```

## Verify

``` text
INPUT
Frozen AC
Scenario
Code
Test Strategy
Build Result

PROCESS
Execute Tests
Regression
Evidence Collection
Acceptance

OUTPUT
AC → TEST → EVIDENCE
Acceptance Matrix
Regression Result
Accepted / Failure
```

------------------------------------------------------------------------

# 48. 典型 SSD/UFS 示例

假设需求：

> Simulator 支持完整 Host Write。

Requirement 阶段：

``` text
REQ-001
 ↓
CAP-Host-IO
 ↓
STORY-001
 ↓
AC-001...AC-005
```

L1：

``` text
Host
 ↓
Scheduler
 ↓
FTL
 ↓
NAND
 ↓
Completion
```

Open：

``` text
AC-002 → Host API
AC-003 → Scheduler → FTL
AC-004 → FTL → NAND
AC-005 → NAND → Completion
```

Design：

``` text
AC-003 → DES-003 Host→FTL routing
AC-004 → DES-004 FTL→NAND operation
AC-005 → DES-005 completion lifecycle
```

Build：

``` text
DES-003 → IMP-003 → code → unit test
DES-004 → IMP-004 → code → unit test
DES-005 → IMP-005 → code → unit test
```

Verify：

``` text
AC-003 → TEST-003 → trace
AC-004 → TEST-004 → NAND record
AC-005 → TEST-005 → completion trace
```

最终：

``` text
REQ-001
 ↓
STORY-001
 ↓
AC-005
 ↓
DES-005
 ↓
IMP-005
 ↓
CODE
 ↓
TEST-005
 ↓
EVD-005
```

任何环节断开，都可以定位流程缺陷。

------------------------------------------------------------------------

# 49. 关键边界总结

## Requirement 与 Open

``` text
Requirement：
“我要什么？”

Open：
“现有系统哪里可以实现它？”
```

## Open 与 Design

``` text
Open：
“事实、影响、约束是什么？”

Design：
“基于这些事实，怎么实现？”
```

## Design 与 Build

``` text
Design：
“应该采用什么方案？”

Build：
“按照方案实现。”
```

## Build 与 Verify

``` text
Build：
“代码是否正确实现设计？”

Verify：
“系统是否满足需求？”
```

------------------------------------------------------------------------

# 50. 演进路线

### Phase 1：兼容式落地

``` text
Requirement
   ↓
External Validator
   ↓
Classic Open
   ↓
Design
   ↓
Build
   ↓
Verify
```

不修改 Classic Runtime。

### Phase 2：Requirement Manifest

Runtime 增加：

``` text
Requirement Manifest
Story Manifest
Freeze Record
Requirement Validator
```

### Phase 3：正式状态机

将：

``` text
DECOMPOSITION
HUMAN_REVIEW
STORY_FROZEN
```

纳入 Comet Runtime。

### Phase 4：全链路 Guard

强制：

``` text
REQ
→ STORY
→ AC
→ DES
→ TEST
→ EVD
```

并能够机器检查。

### Phase 5：平台化

最终形成：

``` text
Human
  ↓
Main Agent
  ↓
Comet Runtime
  ├── Requirement
  ├── Open
  ├── Design
  ├── Build
  └── Verify
       │
       ├── OpenCode
       ├── OMO
       ├── CodeGraph
       ├── graphify
       ├── OpenViking
       ├── Plugins
       └── Hooks
```

------------------------------------------------------------------------

# 51. 最终设计原则

1.  **ATDD 是整个流程的主线，不是测试阶段的附属功能。**
2.  **Story 是需求与工程之间的最小业务闭环。**
3.  **AC 是冻结后的行为契约。**
4.  **Requirement 定义 Why / What / Acceptance。**
5.  **Open 只研究工程事实，不重新定义需求。**
6.  **Design 必须做到 AC → Design 全覆盖。**
7.  **Build 必须严格消费已确认 Design。**
8.  **Verify 必须从 AC 出发，而不是从代码出发。**
9.  **每一次代码和测试都必须能够追溯到 Story / AC。**
10. **Agent 可以提出方案，Human 决定关键目标与架构。**
11. **Hook / Plugin 负责 Enforcement，不负责替人决策。**
12. **OpenSpec / Comet / Artifact 必须有明确的唯一权威来源。**
13. **问题必须按类别回流，不能在错误阶段偷偷修正。**
14. **对于 SSD/UFS Firmware，纵向价值切片优先于按源码文件拆分。**
15. **最终目标不是 Agent 自动完成流程，而是让 Agent
    在可验证的工程边界内持续推进。**

------------------------------------------------------------------------

# 52. 最终闭环

整个系统最终形成：

``` text
                     HUMAN
                       │
                       ▼
                 Requirement
                       │
             Why / What / AC
                       │
                       ▼
                STORY FROZEN
                       │
                       ▼
                     OPEN
                       │
          Where / Impact / Constraints
                       │
                       ▼
                    DESIGN
                       │
                AC → DES → Test
                       │
                       ▼
                     BUILD
                       │
            DES → IMP → CODE → UNIT
                       │
                       ▼
                    VERIFY
                       │
              AC → TEST → EVIDENCE
                       │
                       ▼
                   ACCEPTED
```

最终的核心追溯链：

``` text
REQ
 ↓
Capability
 ↓
Story
 ↓
AC
 ↓
Scenario
 ↓
Engineering Boundary
 ↓
Design
 ↓
Implementation
 ↓
Test
 ↓
Evidence
 ↓
Acceptance
```

这条链就是本平台的**ATDD 主脊柱**。

它把 AI Coding 从：

> "Agent 帮我写代码"

升级为：

> **"Agent 在 Human
> 定义并冻结的可验收目标下，利用工程知识、代码图谱、设计和自动化工具，沿着可追溯的工程链路完成实现，并最终以测试证据证明需求。"**
