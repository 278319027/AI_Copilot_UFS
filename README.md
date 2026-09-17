下面是一套可直接落地到 Comet 流程的 ATDD 完整闭环。核心原则是：**ATDD 从需求分解开始贯穿到验收，而不是 Build 后才开始测试。**
```text
Epic
  → Requirement Decomposition（人主导、Agent 辅助）
  → Human Approval / Story Freeze
  → Open（工程上下文与影响分析）
  → Design（详细 HOW）
  → Build（实现与单测）
  → Verify（按 AC 验收并保留证据）
  → Accepted / Release / Retrospective
```

## 1. 统一对象与追溯关系

每一个开发项必须可追溯：
```text
REQ → Capability → Story → AC → Scenario
    → Design Item → Code Change → Test → Evidence
```

最小标识规范：

| 对象    | 示例            |
| ----- | ------------- |
| 需求    | `REQ-001`     |
| 决策    | `DEC-003`     |
| 假设    | `ASM-002`     |
| Story | `STORY-012`   |
| 验收标准  | `AC-012-03`   |
| 设计项   | `DES-012-03`  |
| 测试    | `TEST-012-03` |
| 验收证据  | `EVD-012-03`  |

任何代码、设计或测试无法关联到 Story / AC 时，都应视为范围不清或潜在冗余。

## 2. 角色边界

| 角色                | 负责                      | 不负责            |
| ----------------- | ----------------------- | -------------- |
| Human / 产品与技术负责人  | 需求目标、范围、关键架构、优先级、最终验收   | 把每个细节写成代码      |
| 主控 Agent          | 阶段调度、产物管理、状态推进、问题回流     | 擅自冻结需求或关键架构    |
| Requirement Agent | 澄清、能力拆分、Story、AC、概念架构建议 | 直接编码、详细 API 设计 |
| Open Agent        | 仓库理解、影响分析、约束、风险、就绪检查    | 重定义需求          |
| Design Agent      | 模块/API/状态机/算法/并发/错误设计   | 改变已冻结的业务目标     |
| Build Agent       | 代码、单测、构建修复              | 以实现方便为由改变 AC   |
| Verify Agent      | 按 AC 执行验收、收集证据、回归       | 用“代码看起来合理”替代验收 |

## 3. Requirement Decomposition：把需求变成可验收 Story

输入是 Epic，输出是可进入 Comet Open 的冻结 Story，而不是代码任务。

### 3.1 Step 1：需求理解

Agent 先输出需求模型：
```yaml
requirement:
  id: REQ-001
  goal: 要解决的问题与预期价值
  actors: 用户、系统、外部组件
  in_scope: 本次必须实现的能力
  out_of_scope: 明确不做的事情
  constraints: 性能、资源、兼容性、安全、硬件限制
  dependencies: 外部系统、协议、已有模块
  unknowns: 尚未确认的问题
```

此时不能直接生成代码计划。未知项必须被显式列出来。

### 3.2 Step 2：Human-in-the-loop 访谈与决策

Agent 将不确定性转为少量、高价值问题，由人确认。例如：
```yaml
id: DEC-003
question: FTL 是否需要可插拔？
options:
  - 是：支持后续接入自定义 FTL
  - 否：当前只实现内置 FTL
decision: 是
owner: Human
reason: 后续算法研究需要
status: accepted
```

必须人工确认的内容：

- 产品目标与范围；
- 性能、实时性、内存、安全等关键约束；
- 系统边界与外部依赖；
- 关键架构方向；
- Story 边界与优先级；
- 验收标准。

### 3.3 Step 3：Capability 分解

先按能力而非源码模块拆分。例如 SSD Simulator：
```text
SSD Simulator
├─ Runtime：初始化、事件循环、计时、统计
├─ Host IO：读、写、Flush、队列
├─ FTL：映射、分配、回收、调度
├─ NAND Model：Channel / Die / Plane / Block / Page
├─ Workload：顺序、随机、混合负载
└─ Observability：延迟、带宽、GC 与 NAND 统计
```

Capability 不等于 Story，也不等于 `ftl.c` 或 `nand.c`。

### 3.4 Step 4：概念架构（L1）

在 Story 冻结前，先定义架构骨架：

- 系统边界；
- 核心组件与职责；
- 主数据流和控制流；
- 主要接口边界；
- 依赖关系；
- 架构约束。

例如：
```text
Host IO → Scheduler → FTL → NAND Model → Completion
                     ↓
                Statistics
```

此阶段只定义 `FTL.submit_io` 的职责、输入输出概念和调用边界；不定义 C 函数签名、结构体布局、队列实现或内存池。

### 3.5 Step 5：Story Mapping 与 ATDD 验收标准

Story 必须是纵向价值切片，能够形成可观察的系统增量。

错误拆分：
```text
STORY-001：实现 ftl.c
STORY-002：实现 nand.c
```

正确拆分：
```text
STORY-001：最小 Host Write 全链路
STORY-002：Read/Write 数据一致性
STORY-003：地址映射能力
STORY-004：垃圾回收
STORY-005：工作负载与性能统计
```

每个 Story 采用统一模板：
```yaml
id: STORY-001
title: 最小 Host Write 全链路
source_requirements: [REQ-001]

business_value: 用户能够提交一次完整 Write IO 并收到完成通知。

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
    statement: Simulator 可成功启动。
  - id: AC-002
    statement: Host 可提交合法 Write IO。
  - id: AC-003
    statement: 请求会到达 FTL。
  - id: AC-004
    statement: FTL 会创建对应 NAND 操作。
  - id: AC-005
    statement: NAND 操作完成后 Host 收到一次且仅一次 completion。

dependencies: []
architecture_boundaries: [Host, Scheduler, FTL, NAND]
major_interfaces: [Host.submit_io, FTL.submit_io, NAND.submit_request]
status: draft
```

对复杂 AC，补充 Given / When / Then 场景：
```gherkin
Scenario: Submit a host write

Given Simulator 已初始化
When Host 提交一个合法 Write 请求
Then 请求到达 FTL
And FTL 生成 NAND 操作
And NAND 操作完成
And Host 收到一次 completion
```

### 3.6 Step 6：Challenge 与 Freeze

冻结前由 Challenge Agent 检查：

- Story 是否过大、过小、重叠或漏项；
- 是否是可独立验收的价值切片；
- AC 是否可测试、可观察、无歧义；
- 是否把实现方案误写成需求；
- 依赖是否真实存在；
- 架构边界是否冲突；
- 是否存在未记录的假设。

冻结后，以下内容不允许 Build Agent 自行修改：
```text
Story Scope
Out of Scope
Acceptance Criteria
关键架构边界
关键约束
Human Decision
```

如发现问题，必须回流到需求或设计阶段。

## 4. Open：确认工程上下文，而非重新理解需求

Open 的核心问题是：**这个已冻结的 Story 在当前工程中应该在哪里实现、会影响什么？**

### Existing Codebase 模式

Open Agent 分析：

- 现有架构、模块、调用链、数据流；
- 可复用实现；
- 受影响文件、接口和测试；
- 兼容性风险；
- 编译、测试、静态检查约束；
- 已有设计规则与历史决策。

输出：
```text
open/
├─ engineering-context.md
├─ impact-analysis.md
├─ constraints.md
└─ open-questions.md
```

### Greenfield 模式

没有代码库时，Open 不应伪造“现有代码影响”，而要输出：

- 领域上下文；
- 技术栈与构建约束；
- 外部依赖；
- 已确认的架构决策；
- 待解决技术问题；
- 初始工程骨架建议。

### Open Gate

只有全部满足才进入 Design：
```text
Story scope clear?           YES
Acceptance Criteria clear?   YES
Architecture boundary clear? YES
Engineering context known?   YES
Blocking question?           NO
```

若出现需求类问题，回到 Requirement Decomposition；若只是实现细节问题，进入 Design 解决。

## 5. Design：把 AC 映射到详细实现方案

Design 的输入：
```text
Frozen Story + AC + Conceptual Architecture
+ Open Context + Constraints + Impact Analysis
```

输出为可实现、可评审的详细技术设计：

- 模块改动；
- API 与协议；
- 数据结构；
- 算法；
- 状态机；
- 并发模型；
- 内存与资源生命周期；
- 错误处理与恢复；
- 可观测性；
- 测试策略；
- 风险与回滚方案。

关键要求：每条 AC 必须有设计覆盖。

| AC     | 设计项                       | 验证方法       |
| ------ | ------------------------- | ---------- |
| AC-002 | `DES-001`：Host IO 校验与提交接口 | 单测 + 集成测试  |
| AC-003 | `DES-002`：Host → FTL 路由   | 调用链断言      |
| AC-004 | `DES-003`：FTL → NAND 操作生成 | 模拟 NAND 测试 |
| AC-005 | `DES-004`：Completion 生命周期 | 端到端验收场景    |

若存在“AC 无设计覆盖”，Design Review 必须阻断 Build。

## 6. Build：严格按冻结 Story 和设计实现

Build Agent 工作顺序：
```text
Implementation Plan
→ Code Change
→ Unit Test
→ Local Build
→ Static Check
→ Test Result
```

每次变更都应关联：
```text
代码变更 → Story ID → AC ID → Design ID
```

Build 阶段发现问题的回流规则：
```text
实现与设计不一致      → Design
AC 不明确或彼此冲突   → Requirement Decomposition
构建失败              → Build
单测失败              → Build / Design
```

禁止通过以下方式“完成”任务：

- 静默修改验收标准；
- 删除失败场景；
- 把未实现功能标记为非范围；
- 仅因测试困难而跳过 AC；
- 用 mock 掩盖真实主链路问题。

## 7. Verify：以 AC 为唯一验收基线

Verify 不从“代码写了什么”出发，而从“AC 是否已被证明满足”出发。

每条 AC 都要有：
```yaml
ac: AC-005
test_case: TEST-005
method: integration / e2e / simulation / manual
result: pass | fail | blocked
evidence:
  - test-report link
  - log link
  - trace link
  - screenshot or waveform link
regression_result: pass
verified_by: Verify Agent
```

验收矩阵示例：

| AC     | 场景              | 结果   | 证据                  |
| ------ | --------------- | ---- | ------------------- |
| AC-001 | Simulator 启动    | PASS | 构建与启动日志             |
| AC-002 | 提交 Write IO     | PASS | 集成测试日志              |
| AC-003 | 请求进入 FTL        | PASS | Trace / mock 断言     |
| AC-004 | 创建 NAND 操作      | PASS | NAND 操作记录           |
| AC-005 | 收到唯一 completion | FAIL | 重复 completion Trace |

只要存在一个必须 AC 为 `FAIL` 或 `BLOCKED`，Story 不能进入 `Accepted`。

## 8. Comet 状态机与回流规则

建议将流程状态固化为：
```text
EPIC_CREATED
  → DECOMPOSITION
  → HUMAN_REVIEW
  → STORY_FROZEN
  → OPEN
  → OPEN_REVIEW
  → READY_FOR_DESIGN
  → DESIGN
  → DESIGN_REVIEW
  → READY_FOR_BUILD
  → BUILD
  → VERIFY
  → ACCEPTED
  → RELEASED
```

异常状态：
```text
NEEDS_REQUIREMENT_CLARIFICATION
NEEDS_ARCHITECTURE_DECISION
NEEDS_DESIGN_REVISION
BUILD_FAILED
VERIFICATION_FAILED
```

关键回流关系：
```text
Verify fail → Build / Design
Design 无法覆盖 AC → Requirement Decomposition
Open 发现需求冲突 → Requirement Decomposition
Build 发现设计漏洞 → Design
Human 修改范围 → Story 重新冻结
```

## 9. 人工 Gate

建议至少保留六个 Gate：

| Gate | 人工确认内容                    |
| ---- | ------------------------- |
| G1   | Epic 范围、目标、约束             |
| G2   | 概念架构与主要边界                 |
| G3   | Story Map、依赖和优先级          |
| G4   | Acceptance Criteria 与验收场景 |
| G5   | 详细设计与 AC 覆盖               |
| G6   | Verify 结果与发布接受            |

其中 G1～G4 最重要；这些决策一旦错误，后续自动化越强，偏离速度反而越快。

## 10. 推荐产物目录
```text
comet-artifacts/
├─ requirements/
│  ├─ requirement.md
│  ├─ decisions.md
│  ├─ assumptions.md
│  ├─ capability-map.md
│  ├─ conceptual-architecture.md
│  ├─ interface-boundaries.md
│  ├─ dependency-map.md
│  └─ stories/
│     └─ STORY-001.md
├─ open/
│  └─ STORY-001/
│     ├─ engineering-context.md
│     ├─ impact-analysis.md
│     ├─ constraints.md
│     └─ open-questions.md
├─ design/
│  └─ STORY-001/
│     ├─ detailed-design.md
│     ├─ ac-coverage.md
│     └─ test-strategy.md
├─ build/
│  └─ STORY-001/
│     ├─ implementation-summary.md
│     └─ unit-test-result.md
└─ verify/
   └─ STORY-001/
      ├─ acceptance-matrix.md
      ├─ regression-result.md
      └─ evidence/
```

## 11. 在 Comet 中的自动化触发点

建议将 Hook / Plugin 设计成“校验与推进”，而不是自动替人做关键决策：
```text
Story Freeze
  → 校验 Story 模板、AC、依赖、决策引用
  → 创建 Open 任务

Open Complete
  → 执行 Readiness Check
  → 通过后创建 Design 任务

Design Complete
  → 校验 AC → Design 覆盖矩阵
  → 通过后创建 Build 任务

Build Complete
  → 校验构建、单测、静态检查
  → 创建 Verify 任务

Verify Complete
  → 检查所有必需 AC 是否 PASS
  → PASS：Accepted
  → FAIL：回流至 Build / Design / Requirement
```

## 12. 最终落地准则

一句话定义各阶段：
```text
Requirement Decomposition：为什么做、做什么、验收什么。
Open：在当前工程中在哪里做、会影响什么。
Design：具体如何做。
Build：把设计实现出来。
Verify：是否已经证明满足验收标准。
```

这套流程特别适合 SSD/UFS Firmware、FTL、嵌入式系统与 Simulator：它把高风险的状态机、接口、并发、资源约束前置到概念架构和 ATDD 验收基线中，同时避免 Agent 在需求尚未冻结时直接进入编码。


当前的 `comet-open` 不是纯粹的“工程 Open”阶段；它把四类职责混在了一起：

1. 需求探索与 PRD 澄清  
2. PRD 拆分与 change 命名  
3. 工作区、OpenSpec、Comet state 初始化  
4. OpenSpec 的 `proposal / specs / design / tasks` 产物生成与确认  

因此，它更像“从模糊请求创建完整 Classic change 的前置规划器”，而不是你定义的：

> 已冻结 Story 在当前工程中的落点、影响、约束、风险与 Design Readiness 检查。

这正是需要改造的核心。

## 当前行为与目标行为的差异

| 维度 | 当前 `comet-open` | ATDD 目标形态 |
|---|---|---|
| 输入 | 原始自然语言、PRD、模糊想法 | 已冻结的 `STORY-*`、AC、Scenario、决策、约束 |
| 需求澄清 | Open 内负责 | `prd-split` + Human + grill-me 前置完成 |
| PRD 拆分 | Open 内预检并创建多个 change | Capability / Story Map 阶段完成 |
| 工程调查 | 较弱，未形成固定工程上下文合同 | Open 的主职责 |
| `design.md` | Open 即可生成高层设计 | 只记录工程约束与影响；详细 HOW 留给 Design |
| `tasks.md` | Open 阶段生成 | 应由 Design/Build 基于已确认设计形成 |
| 退出条件 | OpenSpec 产物齐全并确认 | Story 可追溯、工程上下文明确、无阻断项、Ready for Design |
| 回流 | 主要是 OpenSpec 产物补齐 | 明确分流到 Requirement / Design / Build |

当前实现中，`comet-open` 在第 1 步询问目标、范围、非目标和验收场景，又在第 1a 步拆 PRD；第 2 步要求创建 proposal、可能的 design 和 tasks。这会和新的 `prd-split` agent 职责重叠。与此同时，[`comet-design`](H:\Coding\ATDD_COMET\.opencode\skills\comet-design\SKILL.md) 又被定义为深度技术设计阶段，导致 `design.md` 的责任边界不清。

## 推荐改造：先采用“兼容式两阶段”方案

不建议第一步就向 Classic 状态机增加 `requirements` phase。那会涉及 `.comet.yaml` schema、guard、transition、CLI、恢复协议和批量工作流，改动面很大。

更稳妥的第一阶段是把 Requirement Decomposition 设为 Classic 之外、但受强校验的前置阶段：

```text
PRD / Epic
  → prd-split
  → grill-me Challenge
  → Human Story Freeze
  → requirements validator
  → comet-open
  → comet-design
  → comet-build
  → comet-verify
```

Classic 仍从 `open` 开始，不改变已有 phase enum；但 `open` 的输入不再是模糊 PRD，而是一个合格、已冻结的 Story。

这样可保留现有 OpenSpec 与 Comet state 的兼容性，逐步替换 Open 的职责。

## 改造后的 Open 阶段

```text
输入：
  Frozen STORY-001
  + REQ / DEC / ASM 引用
  + AC / Scenario
  + Challenge 结果
  + Freeze Record

处理：
  1. 验证需求基线
  2. 绑定 Story 与 Classic change
  3. 准备工作区
  4. 调查当前工程
  5. 输出工程上下文、影响、约束与问题
  6. 建立 AC → 工程边界初步映射
  7. Human 确认 Design Readiness

输出：
  READY_FOR_DESIGN
  | NEEDS_REQUIREMENT_CLARIFICATION
  | BLOCKED
```

### 1. 新增 Open 前置校验

`comet-open` 的第一步应从“探索 PRD”改成“验证 Frozen Story”。

最低检查项：

```text
- Story 状态是否 frozen
- 是否具备 source_requirements
- Scope / Out of Scope 是否完整
- 每条 AC 是否有唯一 ID 和可观察 Pass condition
- 每条 AC 是否至少有一个显式 Scenario
- Challenge 是否通过，或所有 BLOCK 已关闭
- 所引用的 DEC 是否已 accepted
- 关键 ASM 是否已被接受并记录风险
- Freeze Record 是否存在且由 Human 确认
```

不通过时禁止创建 Classic change，按问题类别回流：

| 发现 | 回流位置 |
|---|---|
| AC、Scope、依赖、场景缺失 | `prd-split` |
| Challenge BLOCK 未关闭 | grill-me / Human |
| 关键架构方向未决 | Human Decision |
| 需求可用但工程信息不足 | 留在 Open 调查 |

这会让 Open 真正成为“消费冻结需求”的阶段，而不再悄悄重写需求。

### 2. 一个 Frozen Story 对应一个 Classic change

建议默认映射：

```text
STORY-001
  → change: story-001-minimal-host-write
```

change 名称可由 Story ID + 规范化标题构成，但必须把关联信息写入产物，例如：

```yaml
# proposal.md 或单独 traceability.md
story_id: STORY-001
source_requirements:
  - REQ-001
source_decisions:
  - DEC-003
source_assumptions:
  - ASM-002
freeze_record: comet-artifacts/requirements/challenge/STORY-001-freeze-record.md
```

现有 `.comet.yaml` 的字段定义并没有 `story_id`、`requirement_root` 或 `freeze_record`。第一阶段不建议直接扩展它的 schema；先把这些信息放在 OpenSpec change 内的可验证追溯文档。后续若要让 Runtime 强制追溯，再扩展 state schema。

### 3. 把工程调查变为核心产物

建议新增固定目录：

```text
comet-artifacts/open/
└─ STORY-001/
   ├─ engineering-context.md
   ├─ impact-analysis.md
   ├─ constraints.md
   ├─ ac-boundary-map.md
   ├─ open-questions.md
   └─ readiness-check.md
```

各文件的职责：

| 文件 | 内容 |
|---|---|
| `engineering-context.md` | 现有架构、模块职责、调用链、数据流、可复用能力 |
| `impact-analysis.md` | Story / AC 涉及的模块、接口、配置、测试与兼容性影响 |
| `constraints.md` | 编译、平台、性能、资源、协议、安全、代码规范与测试约束 |
| `ac-boundary-map.md` | `AC → 现有工程边界 → 需由 Design 决定的事项` |
| `open-questions.md` | 分类后的需求问题、设计问题、阻断项及回流方向 |
| `readiness-check.md` | 是否可进入 Design 的判定证据 |

特别是 `ac-boundary-map.md`，它是当前流程缺失的桥梁。例如：

| AC | 现有边界 | 已证实上下文 | Design 待决事项 |
|---|---|---|---|
| AC-001-01 | Runtime 初始化 | 已有启动入口与配置加载 | 错误状态如何暴露 |
| AC-001-02 | Host → FTL | Scheduler 已存在 | 请求生命周期与失败语义 |
| AC-001-05 | NAND → Completion | 有 completion 回调 | 一次且仅一次的状态约束 |

这份映射不写方案，但能确保 Design 不会遗漏某条 AC。

### 4. 重定义 OpenSpec 产物职责

现有 Open 强制生成 `proposal.md`、`tasks.md`，并可能生成 `design.md`。这与新阶段边界有冲突。

建议调整为：

| 现有产物 | 改造后职责 |
|---|---|
| `proposal.md` | 从 Frozen Story 派生：业务目标、范围、非目标、需求追溯链接；不再重新澄清 |
| `specs/**/spec.md` | AC 与 Scenario 的规范化镜像；标明原始 Story 为权威来源或明确单一权威来源 |
| `design.md` | 仅记录工程上下文、影响和约束摘要；不得出现方案选型、API、算法、状态机等详细 HOW |
| `tasks.md` | 不再在 Open 创造实现任务；改为待 Design 确认后形成并作为 Build 权威任务清单 |

这里有一个真实的技术约束：当前 Classic 的 OpenSpec 依赖闭包要求 `proposal` 与 `tasks`，而 `tasks.md` 也是 Build 的完成状态权威。因此不能只改 skill 文案，必须同步调整 OpenSpec schema / Runtime 对 task 依赖的要求。

有两种选择：

- 兼容方案：Open 写入“尚未分解的 Design/Build task”，Design 生成正式任务前替换它们；缺点是任务权威性较弱。
- 正确方案：让 `tasks.md` 在 Design 或 Build 才成为必需产物；Open 的必要产物改为 `open-context` 和 `traceability`。我建议采用这一方案。

## 需要改动的组件

第一批改造应集中在以下边界：

| 组件 | 改造 |
|---|---|
| [`comet-open/SKILL.md`](H:\Coding\ATDD_COMET\.opencode\skills\comet-open\SKILL.md) | 删除 PRD 探索/拆分主职责；替换为 Frozen Story 验证、工程调查、Open Readiness |
| `prd-split` agent + skill | 增加 Challenge / Freeze handoff 位置与可被机器校验的 Story 完整性合同 |
| `grill-me` 模板 | 输出可关联 Story、AC、DEC 的结构化 Challenge 结果 |
| Comet CLI / Runtime | 增加 `requirements validate <story>`，由 Open 入口调用 |
| OpenSpec schema | 重新安排 `tasks` 的必需时点；新增或正式承认 `open-context` 类产物 |
| `comet guard <change> open` | 校验 Story 追溯、Freeze、Open 产物与 Readiness 结果 |
| `comet-design` | 消费 `ac-boundary-map.md`，强制产出 `AC → DES` 覆盖矩阵 |
| `comet-verify` | 消费同一 Story 的 AC，强制产出 `AC → TEST → EVD` 验收矩阵 |

## 推荐的最终状态机

长期目标可扩展为：

```text
DECOMPOSITION
  → HUMAN_REVIEW
  → STORY_FROZEN
  → OPEN
  → READY_FOR_DESIGN
  → DESIGN
  → READY_FOR_BUILD
  → BUILD
  → VERIFY
  → ACCEPTED
  → RELEASED
```

但不建议立即把全部状态塞入现有 Classic runtime。更可控的演进路径是：

```text
第 1 期：requirements 在 Classic 外，Open 强制验证 Frozen Story
第 2 期：Runtime 引入 Requirement Manifest 与 requirement validator
第 3 期：将 DECOMPOSITION / STORY_FROZEN 纳入正式状态机
第 4 期：Guard 强制全链路 REQ → AC → DES → TEST → EVD 追溯
```

最关键的结论是：`prd-split` 不是给现有 `comet-open` 增加一个步骤，而是要把现有 Open 的“需求生成职责”移出去。改造后，Open 应只回答：

> 这个已经被冻结、可验收的 Story，在当前工程里落在哪里，会影响什么，哪些事实和约束必须带进 Design？
>
> Design 阶段同样需要收缩和重定位。

当前 `comet-design` 已经具备比较完整的技术设计流程：生成 handoff、执行 brainstorming、用户确认、创建 Design Doc、更新 state 并进入 Build。问题在于它目前主要围绕 OpenSpec 文档和 brainstorming 运转，缺少 ATDD 闭环中最关键的一条硬约束：

```text
每个 AC 必须有明确的 Design 覆盖；
每个 Design 决策必须能追溯到 Story / AC / Open Context。
```

改造后的 Design 应回答：

> 为满足已冻结的每条 AC，在已知工程边界与约束下，具体采用什么实现方案，以及如何验证该方案。

而不是重新讨论业务目标，也不是直接分配编码任务。

```text
输入：
  Frozen Story + AC + Scenario
  + Open Context / Impact / Constraints
  + 已确认的架构决策

输出：
  Detailed Design
  + AC → Design Coverage Matrix
  + Test Strategy
  + Risk / Failure Model
  + Design Readiness
```

## 当前 Design 与目标 Design 的差异

| 维度 | 当前 `comet-design` | ATDD 改造后 |
|---|---|---|
| 需求来源 | OpenSpec proposal / spec / tasks | Frozen Story 与 AC 为需求权威 |
| Open 输入 | handoff 文档 | Open 的工程上下文、影响分析、约束、AC 边界映射 |
| 核心活动 | brainstorming 技术方案 | 为每条 AC 形成可追溯设计覆盖 |
| Spec Patch | 可补充场景或边界 | 必须区分“需求变更”与“实现设计” |
| 任务规划 | 与 OpenSpec tasks 有重叠 | 不创建实现任务；Build 才创建计划和任务 |
| 退出条件 | Design Doc、handoff、guard | 所有 AC 有设计覆盖、风险/测试策略齐备、Human G5 确认 |

## 改造后的 Design 流程

```text
1. 验证 Open Readiness
2. 读取冻结 Story、AC、Scenario 与 Open Context
3. 建立 AC → Design Item 覆盖矩阵
4. 完成详细技术设计
5. 完成测试策略与失败模型
6. 处理设计发现的需求回流
7. Human 确认设计
8. Design Guard → Build
```

### 1. 入口：验证 Open，而不是重新读 PRD

进入 Design 前，必须确认 Open 的 `readiness-check.md` 为 `READY_FOR_DESIGN`，并读取：

```text
requirements/STORY-001.md
open/STORY-001/engineering-context.md
open/STORY-001/impact-analysis.md
open/STORY-001/constraints.md
open/STORY-001/ac-boundary-map.md
open/STORY-001/open-questions.md
```

若发现问题，按类型回流：

| Design 发现 | 回流 |
|---|---|
| AC 含义不清、互相冲突 | Requirement Decomposition |
| Scope、非目标、优先级变化 | Human / Story Freeze |
| 系统边界与原概念架构冲突 | Human Architecture Decision |
| 实现方法未定，但需求清楚 | 留在 Design |
| Open 未找到真实调用链或约束 | 回 Open |

Design 不应自己改写已冻结的 Scope、AC 或关键约束。

### 2. AC → Design 覆盖矩阵成为必需产物

这是最重要的改造点。

```text
AC-001
  → DES-001：启动流程与配置校验
  → DES-002：错误状态传播

AC-002
  → DES-003：Host IO 合法性校验与提交边界

AC-005
  → DES-004：Completion 生命周期
  → DES-005：重复 completion 防护
```

建议输出：

`comet-artifacts/design/STORY-001/ac-coverage.md`

```md
| AC | Scenario | Design Item | 涉及边界 | 验证策略 | 状态 |
|---|---|---|---|---|---|
| AC-001-01 | SC-001-01 | DES-001 | Runtime / Config | 启动集成测试 | covered |
| AC-001-02 | SC-001-02 | DES-002 | Host → Scheduler | 调用链断言 | covered |
| AC-001-05 | SC-001-05 | DES-005 | NAND → Completion | E2E 唯一性断言 | covered |
```

任何 AC 为 `uncovered`，Design Guard 必须阻断 Build。

反向也要检查：没有关联 `AC-*` 的 `DES-*`，通常意味着无需求依据的实现复杂度；应删除、下沉为技术债，或由 Human 扩展需求后重新 Freeze。

### 3. Detailed Design 写“如何做”，但保持边界

Design 可以且应该定义：

- 模块、组件与职责变化
- API、消息、协议和数据契约
- 数据结构与生命周期
- 状态机、并发模型与同步边界
- 错误处理、重试、回滚与恢复
- 内存、性能、资源和安全设计
- 可观测性、日志、metric、trace
- 兼容性和迁移策略
- 各 AC 对应的验证方法

但不应该：

- 用“实现方便”为由删改 AC
- 修改已冻结 Story Scope
- 编写生产代码或测试代码
- 把 implementation plan 当成 Design
- 创建 Build 的完成状态任务清单

建议文件布局：

```text
comet-artifacts/design/
└─ STORY-001/
   ├─ detailed-design.md
   ├─ ac-coverage.md
   ├─ interface-contracts.md
   ├─ state-and-lifecycle.md
   ├─ failure-modes.md
   ├─ test-strategy.md
   └─ design-readiness.md
```

对简单 Story，不需要强制生成所有文件；但 `detailed-design.md`、`ac-coverage.md`、`test-strategy.md` 应是必需的。

### 4. 让现有 OpenSpec `design.md` 成为索引，而非第二份设计

当前流程已经把 OpenSpec `design.md` 和 Comet `design_doc` 都视为设计载体，容易产生双份真相。

推荐明确唯一权威：

```text
技术设计权威：
comet-artifacts/design/STORY-001/detailed-design.md

OpenSpec design.md：
只保存摘要、关联路径、来源 Story、Design Doc hash
```

例如 OpenSpec `design.md`：

```md
# Design Reference

- Story: STORY-001
- Canonical design:
  `comet-artifacts/design/STORY-001/detailed-design.md`
- AC coverage:
  `comet-artifacts/design/STORY-001/ac-coverage.md`
- Test strategy:
  `comet-artifacts/design/STORY-001/test-strategy.md`
```

然后把这一权威设计路径登记到现有 `.comet.yaml` 的 `design_doc`。这样能继续兼容当前 `comet state complete-design` 和 handoff/guard 机制，而不会维护两份技术方案。

### 5. 重新定义 Spec Patch 的边界

当前 `comet-design` 允许补充验收场景或边界条件。ATDD 化后应严格区分：

| 改动 | 处理方式 |
|---|---|
| 补充明确、未改变行为的场景表达 | Requirement Patch + 重新 Challenge |
| AC 语义、范围、优先级变化 | 回 Requirement / Human Freeze |
| 增加错误处理或内部状态设计 | Design 内完成 |
| 新接口、组件、数据流导致公开行为变化 | Human 确认后回 Requirement 或重开 Story |
| 代码级参数、结构体、算法选型 | Design 内完成 |

原则是：Design 可以发现需求缺陷，但不能直接把“设计决定”伪装成“需求澄清”。

### 6. Design Gate

进入 Build 前，建议强制检查：

```text
Frozen Story 已关联                    PASS
Open Readiness = READY_FOR_DESIGN      PASS
所有 AC 有至少一个 DES 覆盖             PASS
所有 DES 均有 Story / AC 依据            PASS
接口边界、状态和错误路径已定义            PASS
高风险 AC 有失败/边界策略                PASS
测试策略覆盖所有 AC                      PASS
需求类未决问题                           NONE
Human G5 确认                            PASS
```

结果只能是：

```text
READY_FOR_BUILD
NEEDS_REQUIREMENT_CLARIFICATION
NEEDS_ARCHITECTURE_DECISION
NEEDS_OPEN_INVESTIGATION
BLOCKED
```

## 对现有 `comet-design` 的具体改造重点

1. handoff 输入增加 requirements 与 open 目录，而非只依赖 OpenSpec proposal/spec/tasks。  
2. brainstorming 固定围绕 `AC → DES` 覆盖矩阵展开。  
3. `brainstorm-summary.md` 记录已确认的技术决策，并附关联 Story / AC / DES ID。  
4. Design Guard 校验 AC 覆盖矩阵、设计文件存在性、测试策略与未决问题。  
5. Build 不再从模糊 `tasks.md` 推导范围，而从已确认 Design 与 `READY_FOR_BUILD` 进入。  
6. `design_doc` 保持现有 Runtime 字段，但指向 `comet-artifacts/design/STORY-xxx/detailed-design.md`。  

最终边界应非常清晰：

```text
Requirement：为什么做、做什么、验收什么
Open：当前工程哪里做、影响什么、约束是什么
Design：为满足每条 AC，具体如何做
Build：实现已确认的设计
Verify：对每条 AC 留下测试与证据
```

可以。结合你现在这套 **Requirement Decomposition → Open → Design → Build → Verify** 的新架构，以及你上传的设计文档，我认为 **Build 阶段应该进行一次比较大的职责重构**。

核心不是简单地把现在的 `comet-build` 改成“执行 tasks.md”，而是把它明确成：

> **Build = 将已经通过 Design Gate 的技术设计，转换成可验证的代码增量；Build Agent 不再拥有需求解释权和架构决策权。**

你现在的 ATDD 闭环已经把 Build 的输入定义得非常清楚：Frozen Story + AC + Detailed Design + Test Strategy。文档也明确规定 Build 发现需求问题时必须回流，而不能自行修改 AC。

---

# 一、先重新定义 Comet-Build

我建议最终把 Build 定义为：

```text
Build
=
Implementation Planning
+
Code Implementation
+
Unit Test
+
Build
+
Static Analysis
+
Implementation Review
+
Handoff to Verify
```

而不是：

```text
tasks.md
   ↓
Agent 写代码
   ↓
编译
   ↓
结束
```

完整链路应该变成：

```text
                 ┌──────────────────────────┐
                 │ READY_FOR_BUILD          │
                 │                          │
                 │ Frozen Story             │
                 │ AC / Scenario            │
                 │ Conceptual Architecture  │
                 │ Detailed Design          │
                 │ AC → DES Coverage        │
                 │ Test Strategy            │
                 └────────────┬─────────────┘
                              │
                              ▼
                    ┌─────────────────┐
                    │ Build Agent      │
                    │ Implementation   │
                    │ Planning         │
                    └────────┬────────┘
                             │
                             ▼
                    ┌─────────────────┐
                    │ Code Agent      │
                    │ Implementation  │
                    └────────┬────────┘
                             │
              ┌──────────────┼──────────────┐
              ▼              ▼              ▼
           Unit Test       Build       Static Check
              │              │              │
              └──────────────┼──────────────┘
                             ▼
                    ┌─────────────────┐
                    │ Build Review    │
                    │ Agent           │
                    └────────┬────────┘
                             │
                    ┌────────┴────────┐
                    │                 │
                  PASS              FAIL
                    │                 │
                    ▼                 ▼
               BUILD_READY       回流
                    │
                    ▼
                  Verify
```

这和你前面确定的：

```text
Requirement：为什么做、做什么、验收什么
Open：在哪里做、影响什么、约束什么
Design：具体如何做
Build：实现设计
Verify：证明 AC 满足
```

是完全一致的。

---

# 二、Build 最大的问题：不要让 tasks.md 成为“需求来源”

这是我认为改造中最重要的一点。

你当前 Comet/OpenSpec 体系里面很可能存在：

```text
tasks.md
   ↓
Build
```

但在新的 ATDD 架构下，这个关系应该改成：

```text
Frozen Story
     │
     ├── AC
     ├── Scenario
     ├── Conceptual Architecture
     │
     ▼
Detailed Design
     │
     ├── DES-001
     ├── DES-002
     ├── DES-003
     │
     ▼
Implementation Plan
     │
     ├── IMP-001
     ├── IMP-002
     └── IMP-003
     │
     ▼
Build
```

也就是说：

> **tasks 是实现计划，不是需求定义。**

这一点与你上传文档中 Design 阶段的重新定位是一致的：Build 不应该从模糊的 `tasks.md` 推导范围，而应该从已经确认的 Design 和 `READY_FOR_BUILD` 进入。

---

# 三、我建议把 Build 拆成 6 个内部步骤

## Build Step 0：Build Preflight

进入 Build 后，第一件事不是写代码。

而是检查：

```text
Story Frozen                  PASS
Open Readiness                PASS
Design Readiness              PASS
AC → Design Coverage          PASS
Test Strategy                 PASS
Human Design Approval         PASS
Blocking Questions            NONE
```

例如：

```yaml
build_preflight:
  story: STORY-001
  status: pass

  requirements:
    frozen: true
    ac_count: 5

  design:
    ready: true
    ac_coverage: 100%

  test_strategy:
    ready: true

  blocking_questions: []

  result: READY
```

如果：

```text
AC-005 → uncovered
```

那么：

```text
Build 不允许开始
        ↓
回 Design
```

而不是：

```text
Build Agent 自己决定“这个 AC 暂时不做”
```

---

# 四、Build Step 1：Implementation Planning

这是我建议新增的一个非常重要的环节。

### Design 和 Implementation Plan 不应该混在一起

Design 回答：

> 怎么设计？

Implementation Plan 回答：

> **按照这个设计，具体先改什么、后改什么？**

例如 SSD Simulator：

```text
DES-001 Runtime Event Model
DES-002 Host IO Interface
DES-003 FTL Request Lifecycle
DES-004 NAND Request
DES-005 Completion Lifecycle
```

Build Planner 将它转换成：

```text
IMP-001
创建 Runtime Event 基础结构

IMP-002
实现 Host IO request object

IMP-003
实现 Host → Scheduler 路由

IMP-004
实现 Scheduler → FTL

IMP-005
实现 FTL → NAND request

IMP-006
实现 completion lifecycle

IMP-007
增加 Host Write integration test
```

然后形成：

```text
DES → IMP → CODE → TEST
```

因此整个追溯链进一步增强：

```text
REQ
 ↓
STORY
 ↓
AC
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

你原设计已经定义了：

```text
REQ → Capability → Story → AC → Scenario
    → Design Item → Code Change → Test → Evidence
```

Build 只是把中间的 **Implementation 层显式化**，并不会破坏原来的追溯关系。

---

# 五、Build Step 2：CodeGraph 驱动的 Implementation

这里非常适合你的 SSD/UFS 固件场景。

Build Agent 不应该只依赖：

```text
Design.md
```

而应该：

```text
Design
   +
CodeGraph
   +
Repository
   +
OpenViking / OpenWiki
```

形成：

```text
                    Build Agent
                         │
          ┌──────────────┼──────────────┐
          ▼              ▼              ▼
      Detailed        CodeGraph      Knowledge
       Design           │           Base
          │             │              │
          └─────────────┼──────────────┘
                        ▼
                 Implementation
                    Context
```

例如 Design 说：

```text
修改 FTL request lifecycle
```

Build Agent 不应该直接：

```text
grep "ftl_request"
```

而应该先通过 CodeGraph 查询：

```text
FTL request entry
 ↓
callers
 ↓
callees
 ↓
related structures
 ↓
state transitions
 ↓
existing tests
```

然后形成：

```text
Implementation Context
```

例如：

```text
Affected Components:
  - HostIO
  - Scheduler
  - FTL
  - NAND

Affected APIs:
  - host_submit_io()
  - ftl_submit_io()
  - nand_submit_request()

Affected Structures:
  - io_request
  - ftl_request
  - nand_request

Existing Tests:
  - test_host_write
  - test_ftl_mapping
```

这样 Build Agent 才真正具备“工程实现能力”。

---

# 六、Build Step 3：代码实现

这里建议不要让一个 Agent 一口气完成所有事情。

你之前设计的 Agent 架构可以进一步优化成：

```text
Main Agent
    │
    ▼
Build Planner
    │
    ├───────────────┐
    ▼               ▼
Code Agent       Test Agent
    │               │
    └───────┬───────┘
            ▼
       Build System
```

但我不建议 Build 阶段搞太多 Agent。

对于你这个场景，我更推荐：

### ① Build Agent

负责：

```text
读取 Design
↓
生成 Implementation Plan
↓
协调 Coding
↓
协调 Test
↓
运行 Build
```

### ② Coding Agent

负责：

```text
代码修改
```

### ③ Build Review Agent

负责：

```text
检查代码是否符合 Design / AC
```

测试不一定需要独立 Agent。

可以由 Build Agent 执行测试工具，或者 Coding Agent 在实现过程中编写单测。

所以最终：

```text
Main Agent
   │
   └── Build Agent
          │
          ├── Coding Agent
          │
          └── Build Review Agent
```

比：

```text
Planner
Coder
UnitTest
Compile
Static
Review
Refactor
...
```

一堆 Agent 更适合你的目标。

---

# 七、Build 阶段应该强制“边实现边验证 AC”

这里是 ATDD 真正发挥作用的地方。

不要：

```text
先把全部代码写完
        ↓
最后才测试
```

应该：

```text
AC-001
 ↓
DES-001
 ↓
IMP-001
 ↓
CODE
 ↓
TEST
 ↓
PASS

AC-002
 ↓
DES-002
 ↓
IMP-002
 ↓
CODE
 ↓
TEST
 ↓
PASS
```

即：

```text
Implementation Slice
=
Design Slice
+
Code
+
Unit Test
```

对于复杂 Story：

```text
IMP-001
  ↓
Code
  ↓
Unit Test
  ↓
Build

IMP-002
  ↓
Code
  ↓
Unit Test
  ↓
Build

IMP-003
  ↓
Code
  ↓
Integration Test
```

这样 Build 过程本身就是一个逐步收敛过程。

---

# 八、尤其适合你的 SSD Firmware：Vertical Build Slice

这一点我非常建议保留。

例如 Story：

> STORY-001：最小 Host Write 全链路

不要让 Build 按模块：

```text
1. 写完 Host
2. 写完 Scheduler
3. 写完 FTL
4. 写完 NAND
5. 最后再连接
```

而应该：

```text
Vertical Slice #1

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

先跑通：

```text
Host Write
```

然后：

```text
Vertical Slice #2

Host Read
 ↓
Scheduler
 ↓
FTL
 ↓
NAND
 ↓
Completion
```

再：

```text
Vertical Slice #3

Mapping
```

再：

```text
Vertical Slice #4

GC
```

这和你在 Requirement Decomposition 阶段确定的 Story 应该是“纵向价值切片”是一致的。

---

# 九、Build Review Agent 应该审什么？

这里不要把它变成普通 Code Review Agent。

它应该同时检查三个层次：

```text
        Frozen Requirement
               │
               ▼
              AC
               │
               ▼
             Design
               │
               ▼
              Code
```

Review Agent 检查：

### ① Requirement Compliance

```text
Code 是否满足 AC？
```

### ② Design Compliance

```text
Code 是否按照 Design 实现？
```

### ③ Scope Compliance

```text
有没有偷偷实现 Out-of-Scope？
有没有修改不相关模块？
```

### ④ Engineering Quality

```text
代码规范
错误处理
资源生命周期
并发
内存
性能
已有架构兼容性
```

### ⑤ Test Completeness

```text
每个 Implementation 是否有测试？
```

最终输出：

```yaml
build_review:
  story: STORY-001

  ac_compliance:
    AC-001: pass
    AC-002: pass
    AC-003: pass

  design_compliance:
    DES-001: pass
    DES-002: pass

  scope_compliance: pass

  code_quality: pass

  tests:
    unit: pass
    integration: pass

  unexpected_changes: []

  result: PASS
```

---

# 十、非常重要：Build Review 不应该替代 Verify

这两个 Agent 很容易混淆。

我建议明确：

### Build Review

回答：

> **代码是否正确实现了 Design？**

### Verify

回答：

> **产品/系统行为是否满足 AC？**

因此：

```text
Build Review

Design
  ↓
Code
  ↓
是否实现正确？
```

而：

```text
Verify

AC
 ↓
Scenario
 ↓
System
 ↓
Evidence
 ↓
是否满足？
```

这两个层次不能合并。

你的原设计已经明确 Verify 是“从 AC 出发，而不是从代码出发”，并且每条 AC 必须产生测试结果和证据。

---

# 十一、Build 的回流机制要重新设计

这是 Comet 自动化非常关键的地方。

我建议 Build Agent 每遇到问题，必须分类：

```text
                Build Problem
                     │
       ┌─────────────┼─────────────┐
       ▼             ▼             ▼
 Requirement       Design        Implementation
   Problem          Problem          Problem
       │             │             │
       ▼             ▼             ▼
Requirement       Design          Build
Decomposition
```

具体：

| Build 发现                    | 去哪里                         |
| --------------------------- | --------------------------- |
| AC 不明确                      | Requirement Decomposition   |
| AC 冲突                       | Requirement Decomposition   |
| Story Scope 不合理             | Requirement Decomposition   |
| Conceptual Architecture 有问题 | Human Architecture Decision |
| Detailed Design 无法实现        | Design                      |
| API 设计错误                    | Design                      |
| 状态机设计错误                     | Design                      |
| 普通代码 Bug                    | Build                       |
| 编译错误                        | Build                       |
| 单测失败                        | Build / Design              |
| 外部环境问题                      | Build / Infrastructure      |

这与你现有设计的回流规则一致。

---

# 十二、特别重要：禁止 Build Agent“偷偷修改 Design”

例如 Design：

```text
FTL.submit_io()
```

要求：

```text
synchronous request
```

Build Agent 发现异步实现更方便。

它不能直接：

```text
修改 Design
↓
改成 asynchronous
↓
继续 Coding
```

必须：

```text
Build Agent
    ↓
发现 Design 问题
    ↓
Design Revision Request
    ↓
Design Agent
    ↓
Human Review
    ↓
新的 Design
    ↓
重新 Build
```

否则 AI Coding 很容易出现：

> Agent 为了让代码能跑，逐渐改变原始设计。

最终形成：

```text
Requirement
    ↓
Design A
    ↓
Code B
    ↓
Test C
```

三者完全不一致。

---

# 十三、Build Artifact 建议重新设计

我建议：

```text
comet-artifacts/
└── build/
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

其中最重要的是：

```text
implementation-plan.md
implementation-log.md
review.md
build-handoff.md
```

---

# 十四、Implementation Plan 建议采用结构化格式

例如：

```yaml
implementation:
  story_id: STORY-001

  items:

    - id: IMP-001
      design_ids:
        - DES-001
      ac_ids:
        - AC-001
      description: Create runtime event infrastructure
      affected_components:
        - Runtime
      status: pending

    - id: IMP-002
      design_ids:
        - DES-002
      ac_ids:
        - AC-002
        - AC-003
      description: Implement Host IO submission path
      affected_components:
        - Host
        - Scheduler
      status: pending

    - id: IMP-003
      design_ids:
        - DES-003
        - DES-004
      ac_ids:
        - AC-004
        - AC-005
      description: Implement FTL to NAND request lifecycle
      affected_components:
        - FTL
        - NAND
      status: pending
```

这样未来你的 Hook 就非常容易检查：

```text
IMP 是否有 DES？
IMP 是否有 AC？
IMP 是否有测试？
```

---

# 十五、代码修改也应该留下 Traceability

例如：

```text
commit / change
       │
       ├── STORY-001
       ├── AC-003
       ├── DES-002
       └── IMP-002
```

或者代码变更摘要：

```yaml
change:
  id: CHG-001
  story: STORY-001
  ac:
    - AC-002
    - AC-003
  design:
    - DES-002
  implementation:
    - IMP-002

  files:
    - src/host/io.c
    - src/scheduler/scheduler.c

  tests:
    - TEST-002
```

这会让后面 CodeGraph + Git + Comet Artifact 真正形成闭环。

---

# 十六、OpenCode Hook 在 Build 阶段非常适合做“自动守门”

你之前特别强调希望充分利用 OpenCode Plugin + Hook，我认为 Build 是最适合 Hook 发挥作用的阶段之一。

例如：

```text
Build Start Hook
       ↓
validate build preflight
       ↓
validate Design
       ↓
validate AC coverage
```

代码修改后：

```text
Code Change Hook
       ↓
检查 modified files
       ↓
是否属于允许的 scope？
       ↓
是否存在对应 IMP/DES/AC？
```

测试后：

```text
Test Hook
       ↓
记录 TEST result
       ↓
更新 implementation status
```

Build 完成：

```text
Build Complete Hook
       ↓
compile PASS?
unit test PASS?
static check PASS?
review PASS?
       ↓
READY_FOR_VERIFY
```

因此 Hook 不负责“思考”。

而负责：

> **阻止违反流程的行为。**

这正符合你整个架构的人机职责划分。

---

# 十七、Build Agent 的 Skill 可以这样设计

我建议不要继续堆很多 Skill。

Build 阶段核心可以只有：

```text
comet-build
```

下面内部组合几个能力：

```text
comet-build
├── preflight
├── implementation-planning
├── codegraph-exploration
├── implementation
├── test
├── build
├── review
└── handoff
```

而不是：

```text
build-skill
code-skill
test-skill
compile-skill
review-skill
...
```

这样更符合你之前希望“Skills 尽量少、职责清晰”的方向。

---

# 十八、我建议 Build Agent 的实际工作循环

最终我会把 Build Agent 的核心 Loop 定义成：

```text
┌─────────────────────────────┐
│ 1. Read Frozen Story        │
└──────────────┬──────────────┘
               ↓
┌─────────────────────────────┐
│ 2. Read Detailed Design     │
└──────────────┬──────────────┘
               ↓
┌─────────────────────────────┐
│ 3. Validate AC → DES        │
└──────────────┬──────────────┘
               ↓
┌─────────────────────────────┐
│ 4. Query CodeGraph          │
└──────────────┬──────────────┘
               ↓
┌─────────────────────────────┐
│ 5. Create Implementation    │
│    Plan                     │
└──────────────┬──────────────┘
               ↓
        ┌──────────────┐
        │ Implement    │
        └──────┬───────┘
               ↓
        ┌──────────────┐
        │ Unit Test    │
        └──────┬───────┘
               ↓
        ┌──────────────┐
        │ Build        │
        └──────┬───────┘
               ↓
        ┌──────────────┐
        │ Static Check │
        └──────┬───────┘
               ↓
        ┌──────────────┐
        │ Build Review │
        └──────┬───────┘
               ↓
          PASS / FAIL
```

如果失败：

```text
Implementation Bug
       ↓
继续 Build
```

```text
Design Problem
       ↓
Design
```

```text
Requirement Problem
       ↓
Requirement Decomposition
```

通过：

```text
BUILD_READY
    ↓
Verify
```

---

# 十九、最终 Comet 四阶段的职责会非常漂亮

经过这次改造，我认为你的整个体系可以稳定成：

```text
┌──────────────────────────────────────────────┐
│ Requirement Decomposition                    │
│                                              │
│ Why / What / Scope / Story / AC / L1 Arch    │
└─────────────────────┬────────────────────────┘
                      ↓
┌──────────────────────────────────────────────┐
│ Open                                         │
│                                              │
│ Where / Impact / Context / Constraints       │
└─────────────────────┬────────────────────────┘
                      ↓
┌──────────────────────────────────────────────┐
│ Design                                       │
│                                              │
│ How / API / Data / State / Algorithm         │
└─────────────────────┬────────────────────────┘
                      ↓
┌──────────────────────────────────────────────┐
│ Build                                        │
│                                              │
│ Plan / Code / Unit Test / Build / Review     │
└─────────────────────┬────────────────────────┘
                      ↓
┌──────────────────────────────────────────────┐
│ Verify                                       │
│                                              │
│ AC / Scenario / System Test / Evidence       │
└──────────────────────────────────────────────┘
```

其中最重要的四个“真相源”变成：

```text
Requirement Decomposition
        ↓
Frozen Story + AC
        │
        ▼
Design
        ↓
Detailed Design
        │
        ▼
Build
        ↓
Implementation
        │
        ▼
Verify
        ↓
Evidence
```

最终形成：

```text
REQ
 ↓
STORY
 ↓
AC
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

**我认为这比单纯修改 `comet-build/SKILL.md` 更重要：应该把 Build 的“输入契约、Agent 职责、Artifact、回流机制、Hook Gate”一起改掉。**

下一步如果继续往你的实际 Comet 源码落地，我建议直接做 **“现有 `comet-build` → 新 ATDD Build 的逐项改造设计”**：把 `comet-build/SKILL.md`、Build Agent、现有 `tasks.md`、`state`、Guard、OpenCode Hook、CodeGraph 调用以及 OMO Team Mode 分别对应起来，最终给出**哪些文件删、哪些文件改、哪些新增，以及 Build Agent 的完整 Skill Prompt/状态机**。这一步就可以开始接近真正的代码级改造方案了。


