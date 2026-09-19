# 04 Stage 0：需求分解与 Challenge

**版本：V1.1　基线：`00-总体设计-V2.0.md`**
**状态：Design Baseline 分册**
**定位：定义 Stage 0 的位置论证、两个承担 Agent 的职能与契约、向 Comet `open` 的交接、回流规则与接口一致性**

> 本册是《00 总体设计》（下称**主文档**）的下游分册，只做展开，不新增与主文档冲突的契约；冲突时以主文档为准。资料见 §0.3。

---

# 0. 文档说明

## 0.1 本册要解决的问题

主文档 §4.1 只给出 Stage 0 的**位置结论**与契约总表，未展开论证，也未把两个 Agent 的职能、边界、权限、产物、交接逐条冻结。本册补足三件事：

1. **位置**：用硬证据证明 Stage 0 **不可能**位于 Comet `open` 节点之内；
2. **职能**：分别冻结 `ufs-requirements` 与 `ufs-challenge` 的"回答什么 / 不回答什么"；
3. **契约**：把 Skill / Agent / 模板固化为可执行合同，并给出设计裁定。

## 0.2 术语与命名约束（硬约束）

| 约束 | 规则 | 依据 |
|---|---|---|
| phase 数量 | **只有 5 个 phase**：`open/design/build/verify/archive`；禁止"六阶段" | 主文档 §2.1、§2.7 |
| node 数量 | **8 个 Workflow Node**；禁止把 `plan` 称为"Build Plan 阶段" | 主文档 §2.3、§2.7 |
| archive | 一律称 `archive` 阶段；**禁止 "Close"** | 主文档 §2.7 |
| Stage 0 | 一律称 "Stage 0"；它**在 Comet 五阶段之外**，不是第 6 个 phase | 主文档 §4.1 |
| 子阶段 | `Stage 0-a` = Requirement Decomposition；`Stage 0-b` = Challenge。**缩写规则**：后文可用 **`0-a` / `0-b`**（半角数字 + 连字符 + 小写字母）；**禁止** `0a` / `0-A` / `Stage 0a` / `0.a` | 主文档 §4.1、§4.0 |
| Agent 名 | Stage 0 owner 为 `ufs-requirements` 与 `ufs-challenge`；全平台 13 个 Agent | 主文档 §6.1、§6.2 |
| grill-me | **grill-me** 是参照模板 / 方法名；**`ufs-challenge`** 是 Agent 与 Skill 的正式名 | 主文档 §7.1 |
| ID | 两段式：`<对象前缀>-<Story 号>-<序号>`；禁止域标签进入 ID | 主文档 §5.1 |

## 0.3 参考资料

| 资料 | 用途与简称 |
|---|---|
| `docs/design/00-总体设计-V2.0.md` | **主文档**：总体设计基准 |
| `.opencode/skills/prd-split/SKILL.md` | **prd-split SKILL**：需求分解 Skill 契约 |
| `.opencode/agents/prd-split.md` | **prd-split agent**：需求分解 Agent 定义与权限模型 |
| `docs/grill-me-atdd-challenge-template.md` | **grill-me 模板**：Challenge 模板 |
| `docs/prd-split.md`、`docs/prd-split-implementation-guide.md` | **设计稿 / 指南**：需求分解的设计依据与落地指南 |
| `docs/Comet + ATDD + UT Design_skills.txt` | **方法论参考资料**：AC 八类分类法与场景规范 |

---

# 1. Stage 0 的位置：为什么它不可能在 `open` 节点内

## 1.1 硬证据：`open` 的 guard 与 Stage 0 的产物目录

主文档冻结了 `open` 节点的契约：

| 项 | `open` 节点 | Stage 0 |
|---|---|---|
| kind | control | 非 Comet node（**在 Comet 五阶段之外**） |
| 原生 Skill | `comet-open` | `prd-split`（0-a）/ `ufs-challenge`（0-b） |
| Output Schema | `comet.intake.v1` | 无 Comet Schema（Phase 1） |
| **guard** | **`.comet.yaml exists`**（state-transition） | 无 guard；出口是 **Human Story Freeze** |
| 产物 | `<openSpecRoot>/changes/<change>/proposal.md`、`.../specs/**/spec.md`、`.../.comet.yaml` | `comet-artifacts/requirements/**`、`challenge-report.md` |

**论证（三点，逐条不可替代）**：

1. **guard 语义**：`open` 的 guard 是 `.comet.yaml exists`。guard 是**进入条件**——当 `open` 作为 Comet 节点开始运行时，`.comet.yaml`（change 描述符）**已经存在**，即 **change 已经创建**。
2. **产物位置**：Stage 0 的权威产物目录 `comet-artifacts/requirements/` 与 OpenSpec change 目录（`<changesRoot>/<change>/`）**并列**，而不是它的子目录。它由 `ufs-requirements` 的权限白名单 `edit: comet-artifacts/requirements/**` 硬绑定。
3. **时序**：`comet-artifacts/requirements/` 必须在 **change 创建之前**产出——因为 `open` 的输入正是 Stage 0 冻结的 Story / AC / Scenario。

**反证（归谬）**：假设 Stage 0 ⊂ `open`，则：

- 要么 Stage 0 在 `.comet.yaml` 存在前运行 —— 与 `open` 的 guard 矛盾，Stage 0 不可达；
- 要么先创建 `.comet.yaml` 再跑 Stage 0 —— 则 change 先于需求基线存在，`open` 的输入（Frozen Story）在其自身运行中才产生，**自环**；
- 要么由 `open` 持有需求权威 —— 则 OpenSpec `proposal.md` 成为需求权威，直接违反主文档 §8.1 的**唯一权威来源原则**。

三点均不可接受，故 Stage 0 **在 Comet 五阶段之外**，且**早于任何 change 的存在**。

## 1.2 端到端流水线与 phase 边界
```text
Epic / PRD → 〔Stage 0-a〕Requirement Decomposition → Human Review
           → 〔Stage 0-b〕grill-me Challenge → Human Story Freeze
═══ Comet phase boundary (the change is created only here) ═══
           → open → design → build(plan→execute / subagent-execute→review) → verify → archive
```
与主文档 §4.1 同构：Stage 0-a 产出 `comet-artifacts/requirements/`，Stage 0-b 产出 `challenge-report.md`，**Human Story Freeze 是离开 Stage 0 的唯一闸门**。
**三条边界规则**：

| # | 规则 |
|---|---|
| B1 | 边界左侧**不存在** `.comet.yaml`、change 目录、`proposal.md`、`spec.md`、`tasks.md` |
| B2 | 边界右侧**不得**成为 Story / AC / Scenario 的权威来源，只能镜像 |
| B3 | 穿越边界的**唯一合法载体**是 Human Story Freeze 记录 + 冻结后的需求基线 |

## 1.3 Stage 0 两个子阶段的契约总表

| 项 | Stage 0-a | Stage 0-b |
|---|---|---|
| 目标 | Human Intent → 可审查的 ATDD 需求基线 | 对抗式质询需求本身的正确性、完整性、可验证性 |
| 输入 | PRD/Epic、项目 ATDD 规则、既有需求与决策 | 草稿 Story/AC/Scenario、原始 Requirement |
| Agent | `ufs-requirements` | `ufs-challenge` |
| Skill | `prd-split` | `ufs-challenge`（grill-me 规范化） |
| 产物 | `comet-artifacts/requirements/**` | `challenge-report.md` |
| 状态 | `NEEDS_HUMAN_DECISION` / `DRAFT_READY_FOR_CHALLENGE` / `BLOCKED` | `Verdict` + `Blocking/Non-blocking Findings` |
| Human Gate | Human Review | **Story Freeze** |

## 1.4 与 phase/node 双轨的关系

主文档明确：phase=5（Comet 常量，不可改）、node=8（Comet 原生契约，可按 preset 裁剪）。Stage 0 既**不是 phase**、也**不是 Comet node**，而是主文档 §4.0 总表中的一条独立**轨道**（`0-a Requirement Decomposition` / `0-b Challenge`，与 5 phase × 8 node 并列而不相交）。
**结论**：Stage 0 不占 node 槽位、不参与 `classic-transitions.ts` 的迁移表、不写 `.comet.yaml`。任何把 Stage 0 描述为"第 0 个 phase"或"第 9 个 node"的表述都是违规。

## 1.5 preset 下的 Stage 0 裁剪

| 能力 | `full` | `tweak` | `hotfix` |
|---|---|---|---|
| Stage 0-a 需求分解 | ✅ 完整 | ⚠️ 轻量：仅 Story 边界与 AC | ⚠️ 跳过：缺陷已有既有行为 |
| Stage 0-b Challenge | ✅ | ⚠️ 仅 AC 可验证性 | ❌ 跳过 |

`tweak` / `hotfix` 的裁剪幅度由 Human 在 intake 时决定，且**裁剪本身必须留痕**。裁掉 Stage 0-b 不等于裁掉 Freeze：即使 `hotfix` 也必须有明确的需求/故障边界确认，否则 `open` 缺少输入。

## 1.6 位置论证的边界条件

以下三条是本册在位置论证上额外冻结的边界条件：

| # | 条件 | 理由 |
|---|---|---|
| P1 | Stage 0 的任何 Agent **不得**调用 Comet CLI（含 `comet status` / `comet next`）来推进阶段 | Stage 0 不在生命周期内，调用会把状态机置于未定义态 |
| P2 | Stage 0 的任何产物**不得**写入 change 目录或 `<openSpecRoot>` | 否则边界左侧出现 change 语义，违反 B1 |
| P3 | 离开 Stage 0 的闸门**只有** Human Story Freeze；`ufs-requirements` 与 `ufs-challenge` 都无权宣布 Frozen | prd-split 明确不得冻结；grill-me 明确不拥有 Freeze 权 |

---

# 2. Stage 0-a：`ufs-requirements` —— 职能与契约

## 2.1 职能定位

> **命名说明（G53）**：该 Agent 的**逻辑名固定为 `ufs-requirements`**，但其**文件名历史上是 `prd-split.md`**（沿用它已有的 Skill 名 `prd-split`）——这与 `99 D42`“Agent 文件名固定为 `<agent-name>.md`”存在张力，**本设计按历史事实保留 `prd-split.md`**，**并已在 `04 §6.4` 的接口约束中显式声明该历史命名**；引用时**一律用逻辑名 `ufs-requirements`**。

> `ufs-requirements` 是 Comet 流程中的 **Requirement Decomposition Agent**。它处理 PRD / Epic / 需求拆分，回答 **Why / What / Acceptance**（以及 L1 概念架构建议），并把结果整理为可供 Challenge 与 Comet `open` 消费的 **ATDD 需求基线**。

- **Skill**：`prd-split`
- **入口**：`primary` Agent，由 Human 直接发起（`opencode --agent prd-split` / `opencode run --agent prd-split "<PRD>"`）
- **唯一写路径**：`comet-artifacts/requirements/**`
- **不进入**：`open` / `design` / `build` / `verify` / 发布 / 回顾
- **Human 保留**：目标、范围、优先级、关键约束、关键架构方向、Story 边界、最终 Freeze

## 2.2 回答边界：只回答 Why / What / Acceptance + L1 概念架构建议

| 维度 | `ufs-requirements` 回答 | 形式 |
|---|---|---|
| Why | 要解决什么问题、预期业务价值 | `requirement.md` 的 `goal` / `business_value` |
| What | 系统应提供哪些能力、哪些可独立验收的价值切片 | `capability-map.md`、`story-map.md`、`stories/*.md` |
| Acceptance | 每条 AC 的可观察通过条件与 Given/When/Then 场景 | `stories/*.md` 的 `## Acceptance Criteria` |
| L1 概念架构（**建议**） | 系统边界、核心组件职责、主数据/控制流、主要接口概念、外部依赖、架构约束 | `conceptual-architecture.md`、`interface-boundaries.md` |
| Human 决策 | 会改变 Story 边界 / 验收 / 兼容性 / 安全 / 性能 / 资源 / 架构方向的未知项 | `decisions.md`（`DEC-nnn`）+ Human 回答 |

## 2.3 明确不做：工程影响分析属于 `design` 节点的 Exploration

这是本册要论证的**第二个位置关系**（第一个是 §1.1 的 change 边界）：

| 问题 | 归属 | 理由 |
|---|---|---|
| 这个问题**为什么做 / 做什么 / 怎么算验收** | **Stage 0-a** | ATDD 的起点是模糊 Intent → 可确认的需求基线 |
| 现有固件**当前实际怎么做**、改动会**影响什么** | **`design` 节点 Step 0（`ufs-exploration`）** | 主文档把"工程调查"归入 `design` Step 0，`open` 只做 intake + 确认 + 初始化 state |
| 具体**怎样实现**、AC → Design 覆盖 | **`design` 节点** | AC 是行为契约，Design 才是架构契约 |
| 代码怎么写、测试怎么跑 | **`build` 节点** | 唯一允许改代码的位置 |
| 每条 AC 是否被证明 | **`verify` 节点** | 证据闭环 |

**硬结论**：`ufs-requirements` **不得**做工程影响分析、**不得**引用 CodeGraph 结论作为需求、**不得**把既有实现当作需求来源。CodeGraph 是**代码事实**，不是事实的需求来源。

## 2.4 绝对禁止清单

| # | 禁止项 |
|---|---|
| F1 | 编写**函数签名 / API 签名 / 表结构 / 数据结构** |
| F2 | 编写**算法 / 队列实现 / 并发方案 / 状态机细节 / 内存布局** |
| F3 | 指定具体**函数名 / 文件名 / 类名 / 变量名**作为需求内容 |
| F4 | 编写**具体阈值 / 超时 / 重试次数**等实现参数（应作为待 Human 决策的 `DEC-` 或 Assumption） |
| F5 | 越界做**工程影响分析**（Callers / Callees / 影响面）——那是 `design` 节点 Step 0 的职责 |
| F6 | 调用 `comet` CLI / 写 change 目录 / `<openSpecRoot>`（P1/P2 硬约束，§1.6） |
| F7 | 编写代码 / 测试代码 / 构建脚本 / 发布计划 |
| F8 | 把**源码模块 / 文件 / 目录**当作需求或 Story |
| F9 | 把**实现细节**掺入 AC |
| F10 | 自行填补会改变 Story 切分 / 验收边界 / 系统边界 / 性能资源 / 安全 / 兼容性 / 关键架构方向的未知项 |
| F11 | 冻结 Story、批准需求、宣布 Ready / Frozen / Accepted |
| F12 | 为 `design` / 代码 / 测试 / 证据创建**虚假的完成记录**（含 `AT-` / `DES-` / `TC-` / `EVD-` ID；`UT-` 为历史别名） |
| F13 | 以源码文件命名 Story（`实现 ftl.c`、`新增 nand 模块`） |

**固件特化补充**：UFS/SSD 固件中以下内容**一律属于实现，不属于需求**——FTL 映射表项格式、块/页/通道位域、GC 触发阈值实现、队列深度与调度器实现、中断向量与 ISR 体、DMA 描述符结构、寄存器地址与位定义、NAND 命令时序参数、内存分区与链接脚本。它们可以**出现在需求里的是**：可观察的行为、边界与约束阈值（作为约束条件），而不是其实现。

## 2.5 L1 概念架构：允许与禁止的内容

**允许（且仅允许）**：

| 维度 | 说明 | 在 UFS 固件中的示例（概念级） |
|---|---|---|
| 系统边界 | 哪些在系统内、哪些是外部 | Host 与 Device 的职责边界 |
| 核心组件职责 | 组件**负责什么**，不写怎么实现 | Host IO 入口、调度、FTL 映射、NAND 抽象各自职责 |
| 主数据 / 控制流 | 主要路径的**走向** | Host Write → 调度 → FTL → NAND → Completion |
| 主要接口概念 | 交互的**角色与概念**，不是可调用签名 | "Host 提交 IO 的入口概念"、"FTL 接收写请求的概念" |
| 外部依赖 | 外部系统 / 协议 / 已有能力 / 已确认决策 | UFS 协议版本、Simulator、既有驱动能力 |
| 架构约束 | 硬件与协议施加的约束 | 单队列 / 多队列、实时性上限、可测试性约束 |

**禁止**：函数签名、表结构、算法、队列实现、状态机细节、内存布局。可写 `Host IO → Scheduler → FTL → NAND Model → Completion`，不可写任何带参数/返回值/字段的形态。

## 2.6 输入合同

最小输入是一个 PRD 或 Epic；建议 Human 尽量提供：
```yaml
epic:
  title: <需求标题>
  goal: <要解决的问题>
  business_value: <预期价值>
  actors: [<用户或系统角色>]
  in_scope: [<已知范围>]
  out_of_scope: [<明确不做的内容>]
  constraints: [<性能、资源、协议、安全、兼容性等>]
  dependencies: [<外部系统、前置能力、已有决策>]
  acceptance_intent: <用户如何判断需求成功>
```
输入优先级：① Human 提供的 PRD / Epic；② 项目 ATDD 规则；③ 既有需求、决策、约束；④ `grill-me-atdd-challenge-template.md`（若存在，作为 Challenge 前的质量门槛）。

## 2.7 六步工作流

| Step | 动作 | 关键产物 | 强制规则 |
|---|---|---|---|
| 1 | 建立**需求模型** | `requirement.md` | 所有未知项必须显式化；禁止直接进入 Coding Plan |
| 2 | 把关键未知项转为**编号 DEC 问题** | `decisions.md` | 影响 Story 切分/验收/边界/架构的未知项**不得**假设答案 |
| 3 | **Capability Map + L1 概念架构** | `capability-map.md`、`conceptual-architecture.md` | Capability 不是源码模块，也不是 Story |
| 4 | **Story Map** | `story-map.md`、`stories/*.md` | 纵向价值切片；可独立验收 |
| 5 | **ATDD 验收标准 + Given/When/Then 场景** | Story 的 `## Acceptance Criteria` | 每条 AC 至少一个显式关联场景 |
| 6 | **产出、校验与交接** | `prd-split-result.md` | 恰好一个状态；不得宣布 Frozen |

### 2.7.1 Step 1：建立需求模型
```yaml
requirement:
  id: REQ-001
  goal: 要解决的问题与预期业务价值
  actors: [用户或系统角色]
  in_scope: [本次必须实现的能力]
  out_of_scope: [明确不做的内容]
  constraints: [性能、资源、兼容性、安全或硬件限制]
  dependencies: [外部系统、协议、已有能力或已确认决策]
  unknowns: [尚未确认的问题]
```
`unknowns` 非空并不阻断产出；但每一条未知项必须在 Step 2 中被转成 `DEC-nnn` 或 `ASM-nnn`。

### 2.7.2 Step 2：转化关键未知项 → 编号 DEC 问题

若某项不确定性会改变 **Story 切分 / 验收边界 / 系统边界 / 性能 / 资源 / 安全 / 兼容性 / 关键架构方向**，必须变成编号问题或决策记录，**不得假设答案**：
```yaml
id: DEC-003
question: FTL 是否需要可插拔？
options:
  - 是：支持后续接入自定义 FTL
  - 否：当前只实现内置 FTL
owner: Human
impact: 会改变系统边界、依赖与验收场景。
status: needs_human_decision
```
**状态规则**：关键问题未答复时可以产出草案，但状态**只能**是 `NEEDS_HUMAN_DECISION`；**不得**称其为 Ready、Frozen 或 Accepted。

### 2.7.3 Step 3：Capability Map + L1 概念架构

先按用户/系统能力创建 Capability Map。**Capability 不是源码模块，也不是 Story**。示例：`订单系统 → 商品浏览 / 下单 / 支付 / 库存管理 / 订单查询`；固件域中 **"最小 Host Write 全链路"** 可以依赖 Host IO、FTL 与 NAND Model 等能力，但**不要把 `ftl.c` 或 `nand.c` 写成 Story**。

随后提出 L1 概念架构，覆盖面见 §2.5。此步禁止进入函数签名、表结构、算法、队列或内存布局。

### 2.7.4 Step 4：Story Map

按最小可行价值和依赖顺序，将 Capability 拆为**可独立验收的纵向价值切片**。每个 Story 必须：

- 产生**可观察**的用户或系统价值；
- 有清晰的 Scope 与 Out of Scope；
- 具有明确依赖，并尽可能形成**可运行增量**；
- 具备**可判定**的 AC 与验收场景；
- 可独立进入 Comet `open`；
- **不**将实现细节、源码模块、文件或目录当作需求。

Story 太大时拆分；不能独立验收时合并或定义前置 Story。**Story 边界、排序和优先级必须由 Human 确认。**

反例/正例：
```text
错误：实现 payment-service 模块
正确：用户可完成一次支付并收到支付结果
```

### 2.7.5 Step 5：ATDD 验收标准与 Given/When/Then 场景

每个 Story 的每条 AC 必须有**唯一 ID**、**可观察的通过条件**，以及**至少一个显式关联的场景**：

- `Given`：可重复建立的前置状态、数据与依赖；
- `When`：**一个**可执行动作或系统事件；
- `Then`：可观察、可断言的结果；**不得**使用"正常""正确""合适"等不可验证措辞；
- 对错误、边界值、状态转换、性能或资源等高风险行为，**补充失败或边界场景**；
- 每条 AC **显式列出**覆盖它的 Scenario ID；**禁止**仅靠隐含关联。
```markdown
### AC-001-01：用户可提交合法订单
**Pass condition**：系统接受包含有效商品、地址和支付信息的订单请求，并返回可追踪的订单标识。
**Covered by**：SC-001-01
#### SC-001-01：提交合法订单
Given 用户已登录且购物车中存在可售商品
When 用户提交包含有效收货地址和支付方式的订单
Then 系统创建订单并返回唯一订单标识
```
**进入 Challenge 的门槛**：缺少场景、缺少可观察通过条件、或依赖隐含前提的 AC，**不可**进入 Challenge。

### 2.7.6 Step 6：产出、校验与交接

完成后的交接序列：`DRAFT_READY_FOR_CHALLENGE → ufs-challenge 评审（Story 边界 / AC / 场景 / 依赖 / 架构边界 / 假设）→ Human 处理 BLOCK·WARN·Question → 实质修改则重新 Challenge → Human Story Freeze → Comet open`。
**校验清单（进入 `DRAFT_READY_FOR_CHALLENGE` 前自检）**：

- [ ] 每条 AC 至少一个 Given/When/Then 场景；
- [ ] 每条 AC 显式列出 `Covered by` 的 Scenario ID；
- [ ] `Then` 无不可验证措辞；
- [ ] AC 无内部实现细节；
- [ ] Story 有 Scope / Out of Scope / 依赖 / 约束 / 开放问题；
- [ ] 所有产物落在 `comet-artifacts/requirements/` 内；
- [ ] 未知项已转成 `DEC-nnn` 或 `ASM-nnn`。

## 2.8 输出合同

### 2.8.1 目录树

所有产物写入**固定目录**（**不可覆盖**；§7.1 S0R-6 已撤销“目录可覆盖”）：
```text
comet-artifacts/requirements/
├─ requirement.md
├─ decisions.md
├─ assumptions.md
├─ capability-map.md
├─ conceptual-architecture.md
├─ interface-boundaries.md
├─ dependency-map.md
├─ constraints.md
├─ story-map.md
├─ prd-split-result.md
└─ stories/
   ├─ EPIC-001.md
   └─ STORY-001.md
```

### 2.8.2 Story front-matter 与章节

可**增加**字段，**不得删除**必填字段：
```markdown
---
id: STORY-001
title: <标题>
parent_epic: EPIC-001
status: draft
source_requirements: [REQ-001]
dependencies: []
architecture_boundaries: []
major_interfaces: []
decisions: []
assumptions: []
---
# <Story 标题>
## Business Value
## Scope
## Out of Scope
## Acceptance Criteria
## Dependencies
## Architecture Boundaries
## Major Interface Concepts
## Constraints
## Decisions
## Assumptions
## Open Questions
```
必填字段语义：`id`=`STORY-nnn`（不得复用）；`title` 以**用户/系统可观察价值**命名，不得以模块/文件命名；`parent_epic`=`EPIC-nnn`；`status` 在 Stage 0-a 内**只能**是 `draft`；`source_requirements`=`[REQ-nnn,…]` 至少一个；`dependencies` 无则空数组；`architecture_boundaries` 为本 Story 触及的 L1 组件边界名；`major_interfaces` 为接口**概念名**（不得带参数/返回/字段）；`decisions` / `assumptions` 分别关联 `DEC-nnn` / `ASM-nnn`。允许**增加**字段，**不得删除**必填字段。

### 2.8.3 `prd-split-result.md` 合同

必须包含：本次输入摘要、已产出的 Epic / Story 列表、依赖顺序、关键决策问题、未决假设、已知风险、下一步动作，以及**恰好一个**状态：

| 状态 | 含义 | 下一步 |
|---|---|---|
| `NEEDS_HUMAN_DECISION` | 关键需求、约束或边界尚未确认 | Human 回答问题，更新草案 |
| `DRAFT_READY_FOR_CHALLENGE` | 需求材料足够，**未冻结** | 交给 `ufs-challenge` |
| `BLOCKED` | 缺少无法安全假设的必要输入 | 补充必要 PRD / 决策 |

## 2.9 三态状态机

**字段名（G51）**：三态是 `prd-split-result.md` **front-matter 的 `status` 字段**取值，闭集为 `NEEDS_HUMAN_DECISION` / `DRAFT_READY_FOR_CHALLENGE` / `BLOCKED`（全大写下划线）。`ufs.stage0-validator.v1` 的 guard 二级按 **`status`** 字段名读取，不得依赖正文措辞。

`NEEDS_HUMAN_DECISION`（关键 DEC 未答复）/ `DRAFT_READY_FOR_CHALLENGE`（材料足够，未冻结）/ `BLOCKED`（缺少不可安全假设的必要输入）三态互斥，且 `prd-split-result.md` 中**恰好一个**。

| 迁移 | 条件 | 谁决定 |
|---|---|---|
| → `NEEDS_HUMAN_DECISION` | 存在未答复的 `DEC-nnn`，且该问题会影响 Story 切分/验收/边界/架构 | Agent 判定 + Human 回答 |
| → `DRAFT_READY_FOR_CHALLENGE` | 自检清单全通过，且无未答复的**阻断级** DEC | Agent 判定 |
| → `BLOCKED` | 缺少无法安全假设的必要输入（PRD 缺失、关键前置不存在） | Agent 判定 + Human 补充 |

**注**：`Frozen` **不是**第四态，也**不是** `ufs-requirements` 可写的状态。Freeze 是 Human 行为，记录在 `comet-artifacts/challenge/`（见 §3.9）。

## 2.10 权限模型（deny-all + 单写路径）

`prd-split` 已实现了正确的权限模型，本设计沿用该模式：
```yaml
permissions:
  - action: "*"
    resource: "*"
    effect: deny
  - action: read
    resource: "*"
    effect: allow
  - action: glob
    resource: "*"
    effect: allow
  - action: grep
    resource: "*"
    effect: allow
  - action: edit
    resource: "comet-artifacts/requirements/**"
    effect: allow
  - action: skill
    resource: "prd-split"
    effect: allow
```
Agent 头部其余字段：`mode: primary`、`steps: 24`、`color: "#2563EB"`、`description: 将 PRD 或 Epic 拆分为可供 Comet 消费的 ATDD 需求基线；保留 Human 决策，不进入设计或编码。`

**四条硬性质**：① **默认全拒**（未列出的 action × resource 一律 deny，含 `shell`）；② **单写路径**（唯一可写路径是 `comet-artifacts/requirements/**`）；③ **读全开、写极窄**（`read/glob/grep` 全仓允许）；④ **Skill 白名单**（只能加载 `prd-split`）。

## 2.11 最终响应格式

仅汇报五项：**产物位置**、**Epic/Story 列表**、**当前状态**（三态之一）、**必须由 Human 回答的问题**、**是否可交给 grill-me Challenge**。

**禁止**：把草案称为 Frozen 或 Accepted；宣称已经实现或验收通过。

## 2.12 验收标准

实现完成应满足：

- [ ] `opencode agent list` 可发现 `prd-split (primary)`；
- [ ] Agent 读取当前项目的 ATDD 规则和既有资料；
- [ ] Agent 在关键问题未决时**不会**输出 Ready 或 Frozen；
- [ ] 输出包含 Epic、Capability、概念架构、Story Map 和 Story 文档；
- [ ] 每条 Story 都包含 Scope、Out of Scope、依赖、约束和开放问题；
- [ ] 每条 AC 都有至少一个 Given/When/Then 场景；
- [ ] 所有产物满足 `comet-artifacts/requirements/` 合同；
- [ ] 可将结果直接交给 grill-me Challenge，再进入 Comet `open`。

---

# 3. Stage 0-b：`ufs-challenge` —— 职能与契约

## 3.1 目的与边界

`ufs-challenge` 把 `docs/grill-me-atdd-challenge-template.md` 规范化为 Skill，Agent 以**对抗式**姿态（Challenge Reviewer）在 Story Freeze 前系统检查 Story 的**交付边界、验收标准、依赖、概念架构边界及隐含假设**。

- **拥有**：发现问题、提出质疑、给出修改建议；
- **不拥有**：需求决策权、架构决策权、Story Freeze 权。

流程：`Story Draft → ufs-challenge（grill-me）→ Findings / Questions / Risks → Human Review → Modify / Accept → Story Freeze`。

## 3.2 适用时机与重新 Challenge 触发条件

对每一条准备进入 `open` 阶段的 Story，在以下材料齐备后执行**一次** Challenge：Story 标题、业务价值、Scope 与 Out of Scope；AC 及其每条 AC 对应的 Given/When/Then 验收场景；前置依赖与关联决策；概念架构边界、主要接口边界；已知约束与假设。

**必须重新执行**的情形：Scope / Out of Scope / AC 有实质修改；新增、删除或变更关键依赖；关键架构边界或 Human Decision 变化；上一次评审结果为 `BLOCK_FREEZE`。

## 3.3 AC 场景强制规范

每一条 AC **必须**拥有至少一个与其**一一关联**的 Given/When/Then 场景；没有场景的 AC 视为**未完成，不能 Freeze**。

- `Given`：可重复建立的前置状态、测试数据和依赖条件；
- `When`：**单一**、可执行的业务动作或系统事件；
- `Then`：可观察、可断言的结果，包含**明确的通过判定**；
- 高风险、异常处理、边界值或状态转换相关的 AC，除正常路径外还应增加**失败/边界场景**；
- 一个场景可辅助证明多个 AC，但**每个 AC 都必须显式列出其覆盖场景**，禁止仅凭隐含关联验收。

## 3.4 输入模板

将以下内容连同 §3.5 Prompt 一起提供给 `ufs-challenge`：
```yaml
story:
  id: STORY-001
  title: 最小 Host Write 全链路
  business_value: 用户能够提交一次完整 Write IO 并收到完成通知。
  scope:
    - Host 提交写请求
    - 请求进入 FTL
    - FTL 创建 NAND 操作
    - NAND 操作完成
    - Host 获得 completion
  out_of_scope:
    - Garbage Collection
    - 高级调度
    - 性能优化
  acceptance_criteria:
    - id: AC-001-01
      statement: Simulator 可成功启动。
      scenarios:
        - name: 启动 Simulator
          given: 已提供合法的 Simulator 配置。
          when: 用户启动 Simulator。
          then: Simulator 成功进入可接受 Host IO 的就绪状态。
    - id: AC-001-02
      statement: Host 可提交合法 Write IO。
      scenarios:
        - name: 提交合法 Write IO
          given: Simulator 已初始化且 Host 可用。
          when: Host 提交一个符合协议的 Write 请求。
          then: 系统接受该请求，且返回的请求标识可用于后续追踪。
    - id: AC-001-03
      statement: 请求会到达 FTL。
      scenarios:
        - name: Write IO 路由至 FTL
          given: 已接受一个合法的 Host Write 请求。
          when: 系统调度该请求。
          then: FTL 收到与该请求标识关联的操作。
    - id: AC-001-04
      statement: FTL 会创建对应 NAND 操作。
      scenarios:
        - name: FTL 创建 NAND 操作
          given: FTL 已收到一个合法 Write 请求。
          when: FTL 处理该请求。
          then: FTL 创建一个与该请求关联的 NAND 写操作。
    - id: AC-001-05
      statement: NAND 操作完成后 Host 收到一次且仅一次 completion。
      scenarios:
        - name: 写请求完成通知
          given: 已为 Host Write 请求创建 NAND 操作。
          when: NAND 操作成功完成。
          then: Host 收到一次且仅一次与原请求关联的成功 completion。
  dependencies: []
  architecture_boundaries:
    - Host
    - Scheduler
    - FTL
    - NAND
  major_interfaces:
    - Host.submit_io
    - FTL.submit_io
    - NAND.submit_request
  decisions: []
  assumptions: []
  constraints: []
```
**归一说明**：源模板正文使用一段式 `AC-001`；本设计**已在契约中归一**，上例的 `acceptance_criteria[].id` 一律为两段式 `AC-001-01`…`AC-001-05`（Story 001），Scenario 进平台后归一为 `SC-001-01` 起（见 §6.3）。因此本节契约产出物可直接通过主文档 §5.1.1 的 ID 形态断言，无需二次改写。模板中 `major_interfaces` 的 `Host.submit_io` 属**接口概念标签**，不得扩展为带参数/返回值的签名（见 §7.1 S0R-12）。

## 3.5 Challenge Prompt
```text
你是 ATDD Story Challenge Reviewer。你的职责不是设计方案或编写代码，
而是寻找当前 Story 在可交付性、可验收性、边界和依赖上的缺陷。
请严格检查：
1. Story 是否过大、过小，或包含多个不可独立交付的能力？
2. Story 是否是用户可观察、可独立验收的价值切片，而非源码模块任务？
3. 每条 Acceptance Criteria 是否：
   - 可测试；
   - 可观察；
   - 无歧义；
   - 有明确通过/失败条件；
   - 不依赖未说明的前提；
   - 有至少一个完整的 Given / When / Then 场景，且场景能证明该 AC？
4. 是否混入了实现细节、具体算法、数据结构或 API 设计？
5. Scope / Out of Scope 是否完整，是否存在范围蔓延？
6. 依赖的 Story、组件、外部系统或前置决策是否真实、明确、可获得？
7. 概念架构边界、职责划分、主要接口是否存在冲突或遗漏？
8. 是否存在隐含假设、未决策项、术语不一致或冲突需求？
9. 是否存在无法在 Verify 阶段通过 Given / When / Then 场景证明的 AC？
10. 是否应拆分、合并、重排该 Story？
输出必须使用以下格式：
## Verdict
PASS | PASS_WITH_CONCERNS | BLOCK_FREEZE
## Blocking Findings
- [BLOCK-001] 问题
  - 影响：
  - 涉及 Story / AC：
  - 建议：
## Non-blocking Findings
- [WARN-001] 问题
  - 建议：
## Questions for Human
- [Q-001] 需要人工确认的问题
  - 选项：
  - 不确认的风险：
## Suggested Changes
- Story Scope：
- Out of Scope：
- Acceptance Criteria：
- Dependencies：
- Assumptions：
- Split / Merge Proposal：
不要自行修改需求，也不要做最终 Freeze 决策。
```

## 3.6 Verdict 与状态迁移

| Verdict | 含义 | 后续动作 | Stage 0-b 派生态 |
|---|---|---|---|
| `PASS` | 没有阻断项 | 进入 Human Approval；批准后冻结 | 可 `freeze` |
| `PASS_WITH_CONCERNS` | 可继续，但存在需接受或记录的风险 | Human 处理 Concern 后批准或退回修改 | 条件 `freeze`（风险须进 Freeze Record） |
| `BLOCK_FREEZE` | Story 尚不具备冻结条件 | 回到需求澄清、概念架构或 Story Mapping | 回流 0-a |

**至少**判定为 `BLOCK_FREEZE` 的情况：主文档 §10.3 的 5 条为**下限**，本册 BF1–BF7 是其**超集**（BF2 为强化、BF7 为更严格项）。逐条对应关系：

| 本册 | 条件 | 与主文档 §10.3 的关系 |
|---|---|---|
| **BF1** | AC 不可验证，或没有明确通过条件 | = §10.3 第 1 条（"通过条件不可观察"） |
| **BF2** | 任一 AC 缺少 Given/When/Then 场景，**或场景不足以覆盖该 AC** | **§10.3 第 1 条的强化**：第 1 条只说"AC 没有场景"，BF2 追加"场景不能证明/覆盖该 AC" |
| **BF3** | Story 依赖未定义的能力、接口或前置 Story | = §10.3 第 3 条 |
| **BF4** | Scope / Out of Scope 缺失，或实现边界无法判定 | = §10.3 第 2 条 |
| **BF5** | 存在影响目标、架构边界、性能或资源约束的未决问题 | = §10.3 第 4 条 |
| **BF6** | 一个 Story 含多个不可独立交付的价值切片 | = §10.3 第 5 条 |
| **BF7** | **关键术语存在多种合理解释** | **比 §10.3 更严格**：§10.3 未列此项 |

Challenge 判定取**超集**：命中 BF1–BF7 任一条即 `BLOCK_FREEZE`；主文档 §10.3 不因本册的强化与更严格项而被修改。

## 3.7 Blocking vs Non-blocking Findings

| 维度 | Blocking（`BLOCK-nnn`） | Non-blocking（`WARN-nnn`） |
|---|---|---|
| 定义 | 使 Story 不具备冻结条件的问题 | 不阻断冻结、但必须被记录或接受的风险 |
| 必填字段 | 问题 / **影响** / **涉及 Story·AC** / 建议 | 问题 / 建议 |
| 处置 | Human 关闭或**明确撤销**（须写理由） | Human 接受并记录，或退回修改 |
| 与 Verdict 关系 | 存在任一未关闭 BLOCK → 不得为 `PASS`；达到 §3.6 任一条件 → `BLOCK_FREEZE` | 存在 WARN → 至多 `PASS_WITH_CONCERNS` |
| 归档 | 必须进 `challenge-report.md`，并建立 Finding → Story / AC / DEC 关联 | 同左 |

**问题与决策的分界**：`BLOCK` 是**评审结论**，`Q-nnn`（Questions for Human）是**待决问题**；`Q-nnn` 关闭后必须升级为 `DEC-nnn`（Human 决策）或 `ASM-nnn`（假设），**不得**让 `Q-nnn` 成为长期权威 ID。

## 3.8 Freeze Checklist

Human 在冻结前**逐条**确认：

- [ ] 所有 `BLOCK` 已关闭或被明确撤销；
- [ ] 所有必要 Human Question 已有 Decision Record；
- [ ] Story 的业务价值、Scope、Out of Scope 清晰；
- [ ] 每条 AC 都可被观察、执行与判定通过/失败；
- [ ] 每条 AC 至少有一个完整的 Given/When/Then 场景，且场景覆盖其通过与失败判定；
- [ ] AC 未掺入不必要的实现细节；
- [ ] 依赖、假设、约束和架构边界已记录；
- [ ] 需要拆分或合并的 Story 已处理；
- [ ] Challenge 结论与 Human 处理结果均已归档。

**本册追加两条**（对齐分册 01 的 AC 八类，见 §6.1）：

- [ ] AC 集合已按**八类**（Normal / Boundary / Negative / Error / Recovery / State Transition / Timing / Concurrency）逐类检查，不适用的类别已写明理由；
- [ ] 关键术语表（Glossary）在多份 Story 间**一致**，同一术语不出现两种解释。

> **权威条款声明**：以上两条是 **Stage 0-b Freeze 门禁的权威条款**，权威文本在本册（`99 D41`）；分册 02 的 `ufs-challenge` Skill 契约（§6.15 / §6.16）必须**逐字镜像**这两条，不得改写、不得删减、不得另立同义条款。
**门禁效力**：两条均属 Human 在 Story Freeze 前必须逐条确认的检查项；任一条不满足即不得 Freeze，回流入 Stage 0-a 补充，或经 `ufs-challenge` 重新质询。
清单中"每条 AC 都可被观察、执行与判定"一条按 `99 D31` 升级为**人工确认 + 关键词机械扫描**：AC / Scenario 出现"适当 / 尽量 / 尽可能 / 足够快 / 合理 / 等等 / 若干 / 必要时"等不可判定措辞时，Stage 0-b 必须开 `BLOCK` Finding。

## 3.9 建议归档结构

模板建议把 Challenge 产物放在 `requirements/challenge/`（`STORY-001-review-v1.md` / `-v2.md` / `STORY-001-freeze-record.md`）。**`review-v<N>` 命名已撤回**：现行为 `challenge-report.md`（本次报告）+ `STORY-<id>-challenge-v<N>.md`（版本化归档，`<N>` 从 1 起递增不复用）+ `STORY-<id>-freeze-record.md`（Freeze 记录）。**本册裁定**：按主文档 §6.5 / §8.3，权威目录是 **`comet-artifacts/challenge/`**（`ufs-challenge` 的唯一写路径）：
```text
comet-artifacts/
├─ requirements/
│  ├─ stories/STORY-001.md
│  ├─ decisions.md
│  └─ assumptions.md
└─ challenge/
   ├─ challenge-report.md            # 本次 Challenge 报告（report_id: CHAL-nnn）
   ├─ STORY-001-challenge-v1.md
   ├─ STORY-001-challenge-v2.md
   └─ STORY-001-freeze-record.md
```
理由：① 主文档 §6.5 把 `ufs-challenge` 的写路径硬绑定为 `comet-artifacts/challenge/**`；② 若 `freeze-record.md` 落在 `requirements/` 内，则 `ufs-requirements` 的写权限会覆盖它，形成**自我冻结**，违反 §3.1 的独立性边界。**Freeze Record 位于 Challenge 侧**是独立性要求，不是目录偏好。

`freeze-record` 至少记录：**冻结时间、批准人、Story 版本、评审版本、未关闭但已接受的风险及对应 Decision ID**。

## 3.10 `challenge-report.md` 的契约字段

`challenge-report.md` 必须同时满足主文档 §4.1/§6.3 与模板 §4 的两个要求，冻结为**五段式**：

| 段 | 必填 | 内容 | 归一要求 |
|---|---|---|---|
| `Verdict` | ✅ | `PASS` / `PASS_WITH_CONCERNS` / `BLOCK_FREEZE` | 恰好一个 |
| `Blocking Findings` | ✅ | `BLOCK-nnn` + 影响 + 涉及 Story/AC + 建议 | Finding ID → Story/AC/DEC 关联必填 |
| `Non-blocking Findings` | ✅ | `WARN-nnn` + 建议 | 空则显式写"无" |
| `Questions for Human` | ✅ | `Q-nnn` + 选项 + 不确认的风险 | 关闭后升级为 `DEC-nnn` / `ASM-nnn` |
| `Suggested Changes` | ✅ | Scope / Out of Scope / AC / Dependencies / Assumptions / Split-Merge | **建议**,不是结论 |

**文件头**（本册追加）：
```yaml
report_id: CHAL-001
story_id: STORY-001
story_version: <v1 | commit | hash>
review_version: 1
reviewed_at: <ISO8601>
reviewed_by: ufs-challenge
inputs: [comet-artifacts/requirements/stories/STORY-001.md, comet-artifacts/requirements/requirement.md]
```
> **持久化与校验限制**：`challenge-report.md` 属主文档 C19 的"**新增但无 Output Schema 槽位**"产物——当前**不能**被 Comet 的 `artifact-structured`（guard 三级）校验；**guard 一级（文件存在）/ 二级（章节齐全）已可用**，由 `ufs.stage0-validator.v1` 承担。本册冻结的是**内容契约**；把"报告存在且五段齐全"纳入强制层，**必须**先扩展 Output Schema（与 C19 同批解决；与 C17 的 Node Projection 无关）。

## 3.11 与 `ufs-document-review` / `ufs-code-review` / `ufs-verification` 的区别

主文档 §6.3 冻结了**四个**审查/验证职能的分工，`ufs-challenge` 是其中唯一在 Stage 0 的、唯一**对抗式**的：

| 职能 | 问的问题 | 姿态 | 时机 | 对象 | 独立性规则 |
|---|---|---|---|---|---|
| **`ufs-challenge`** | 这个需求**对不对**？完整吗？可验证吗？ | **对抗式** | Stage 0 / Story Freeze 前 | 草稿 Story / AC / Scenario | 不改被审对象；Blocking Finding 阻断 Freeze |
| `ufs-document-review` | 这些制品之间**自洽吗**？可追溯吗？ | **一致性** | 各节点门禁 | 各阶段已产出制品 | 不改被审文档；`PASS` / `NEEDS_REVISION` |
| `ufs-code-review` | 这段代码**对不对**？符合设计与计划吗？ | **技术核查** | `review` 节点 | Code diff + 测试代码 | 与代码编写者不得是同一执行实例 |
| `ufs-verification` | **整条契约链**是否真正被满足？ | **独立验收** | `verify` 节点 | 契约全集 + Git Diff + Test Result + Code Review | 必须独立于 Build 的局部成功；`Tests passing alone is insufficient` |

**关键区别**（逐职能，按主文档 §6.3）：`ufs-challenge` 问"**需求本身是否值得冻结**"，其独立性规则是**不改被审对象**、Blocking Finding 阻断 Freeze；`ufs-document-review` 问"**制品之间是否自洽、可追溯**"，其规则是**不改被审文档**、`PASS` / `NEEDS_REVISION`（它**接受**已冻结的 AC 为前提，不质疑 AC 的正确性）；`ufs-code-review` 看**代码本身**，其规则是**与代码编写者不得是同一执行实例**；`ufs-verification` 看**代码到契约的整条链**，其规则是**必须独立于 Build 的局部成功**（`Tests passing alone is insufficient`）。`ufs-code-review` 的结论是 `ufs-verification` 的输入之一。

**跨职能约束仅两条**：`ufs-code-review` 不与代码作者同实例；`ufs-verification` 独立于 Build 的局部成功。**不得**升格为"四者互斥"或"四者不得由同一执行实例承担"。

## 3.12 权限模型与禁止项

沿用与 `ufs-requirements` 相同的 **deny-all + 单写路径**模式：
```yaml
permissions:
  - {action: "*",   resource: "*",                              effect: deny}
  - {action: read,  resource: "*",                              effect: allow}
  - {action: glob,  resource: "*",                              effect: allow}
  - {action: grep,  resource: "*",                              effect: allow}
  - {action: edit,  resource: "comet-artifacts/challenge/**",   effect: allow}
  - {action: skill, resource: "ufs-challenge",                  effect: allow}
```
**禁止项**：

| # | 禁止 | 依据 |
|---|---|---|
| C-1 | 改写被审对象（Story / AC / Scenario / 需求基线） | 模板"不拥有需求决策权" |
| C-2 | 凭空发明需求、Scope 或 AC | 对抗式评审只能质疑既有内容 |
| C-3 | 代替 Human 做 Freeze 决策 | 模板"不做最终 Freeze 决策" |
| C-4 | 把 `Suggested Changes` 当作结论 | 模板明确它是建议 |
| C-5 | 直接修改源代码 / 测试代码 / Design | 权限模型仅允许写 challenge 目录 |
| C-6 | 写 `AT-` / `DES-` / `UT-` / `EVD-` ID | 这些对象不属于 Stage 0 |

---

# 4. 交接给 Comet `open`

## 4.1 权威与镜像的镜像关系

交接的本质是**单向镜像**：Stage 0 冻结的需求基线是**权威**，OpenSpec 产物是**规范化镜像**。

**“镜像”的三种含义（G50，必须区分）**：① **数据映射**（`proposal.md`/`spec.md` 由基线机械生成）——用“**映射**”；② **文本一致**（同一份内容在两处逐字相同）——用“**逐字镜像**”；③ **跨册条款一致**（五册对同一议题给出同向结论）——用“**逐字对齐**”，**不用“镜像”**。

| 权威（`comet-artifacts/requirements/`） | 镜像（OpenSpec，`<openSpecRoot>/changes/<change>/`） | 映射规则 | 写入者 |
|---|---|---|---|
| `stories/STORY-001.md`（front-matter + Business Value + Scope + Out of Scope） | `proposal.md` | Story 的 What / Why / 边界 → proposal 对应段；**不得新增语义** | `ufs-main` |
| `AC-001-01`（statement + Pass condition） | `specs/**/spec.md`（delta spec）的 requirement | 一条 AC → 一条 requirement；**保留 AC ID** | `ufs-main` |
| `SC-001-01`（Given / When / Then） | `specs/**/spec.md`（delta spec）的 scenario | **逐字镜像**，不得改写措辞 | `ufs-main` |
| `capability-map.md` / `conceptual-architecture.md` | `proposal.md` 的上下文 / 边界段 | **仅作上下文**，不产生新需求 | `ufs-main` |
| `decisions.md` / `assumptions.md` | `proposal.md` 的 Decisions / Assumptions 段 | **保留原 ID**（`DEC-nnn` / `ASM-nnn`） | `ufs-main` |
| （无） | `AT-001-01` | 由 `open` 从 AC **派生**；Stage 0 **不产生** AT ID | `ufs-main` |

**镜像的三条硬规则**：① **不新增**（不得引入基线中不存在的 AC / Scenario / Scope）；② **不删减**（不得丢弃任何已冻结的 AC 或 Scenario）；③ **不改号**（保留 `REQ/EPIC/STORY/AC/SC/DEC/ASM` 原始 ID，漂移即为审查缺陷）。

## 4.2 唯一权威来源原则

> 不要让 OpenSpec、Comet Artifact、Design Doc 三处同时成为技术设计的权威来源。

落到 Stage 0 的推论：**Story / AC / Scenario 的权威只有 `comet-artifacts/requirements/` 一处**。OpenSpec `proposal.md` / `spec.md` 是镜像；Design Doc 只对技术决策（`DES-`）权威，不得反向定义 AC。

## 4.3 Phase 1：兼容式落地
```text
Stage 0（prd-split + Challenge）
   ↓
External Validator
   ↓
Comet open → design → build → verify → archive
```
**三条性质**：**不修改 Comet Runtime**；Stage 0 作为**受强校验的前置阶段**存在；产物通过 validator 后交给 `comet-open`。

**validator 的输入 / 输出**：输入为 `comet-artifacts/requirements/**` + `comet-artifacts/challenge/**`；输出为 `PASS` / `FAIL` + findings。至少校验：目录合同完整、每条 AC 有场景、每条 AC 有 `Covered by`、无未关闭 `BLOCK`、存在 `freeze-record.md`。校验深度分三级：**guard 一级** = 文件存在 + 目录合同；**guard 二级** = 章节齐全（内容级）；**guard 三级** = 复用 `artifact-structured`（待 `EXT-04`）。**不使用 `L1`/`L2`/`L3` 指代校验深度**（与 §2.5 的“L1 概念架构”同形不同义）。validator 的 schema 与失败动作**已裁定**：schema 固定为 `ufs.stage0-validator.v1`，失败动作固定为 `FAIL → 退回 Stage 0-b 重跑 Challenge`；产物校验按三级执行——**L1** 文件存在 + 目录合同、**L2** 章节齐全为 MVP 必须，**L3** 复用 `artifact-structured` 待 schema 扩展生效（`99 D48`、`99 D01`）。

> **与 C19 的关系**：`challenge-report.md` / `freeze-record.md` 无 Output Schema 槽位（主文档 C19）。扩展载体固定为 `.opencode/comet-ufs/schema-ext.json`，登记 `artifact_id / pathBase / required / sections[]`（`99 D10`）；在其生效前，契约只能声明"内容契约已校验"，**不得**声明"可机器校验"（`99 D01`）。

## 4.4 Phase 2 / Phase 3：把 Stage 0 纳入运行时

| Phase | Comet Runtime 增加 | 对 Stage 0 的影响 |
|---|---|---|
| **Phase 2** | `Requirement Manifest` / `Story Manifest` / `Freeze Record` / `Requirement Validator` | Freeze 从"文件记录"升级为**机器可校验的 Manifest**；`ufs-challenge` 的 Verdict 成为 validator 的输入 |
| **Phase 3** | 把 Stage 0 的状态纳入 Comet Runtime（对应草稿的 `DECOMPOSITION` / `HUMAN_REVIEW` / `STORY_FROZEN`） | Stage 0 三态与 `Verdict` 进入状态机；`ufs-requirements` 的 `primary` 模式与 `ufs-main` 的分派关系需重新裁定（见 §7.1 S0R-8） |

**边界不变式**：即使到 Phase 3，Stage 0 也**不得**成为 `PHASES` 常量的第 6 项。可行形态是把 Stage 0 状态作为 **Comet 之外的前置 Manifest + Freeze 记录**，由 Runtime 读取并校验。

## 4.5 交接前置条件与失败处理

| # | 前置条件 | 不满足时的动作 |
|---|---|---|
| H1 | `prd-split-result.md` 存在且状态为 `DRAFT_READY_FOR_CHALLENGE` 或已经过 Challenge | 退回 Stage 0-a |
| H2 | 每条拟交接 Story 有 `challenge-report.md`，Verdict ≠ `BLOCK_FREEZE` | 退回 Stage 0-b |
| H3 | 存在 `freeze-record.md`（含批准人与 Story 版本） | **不得**进入 `open` |
| H4 | External Validator（Phase 1）返回 `PASS` | `FAIL` → 退回 Stage 0-b 重跑 Challenge（`99 D48`） |
| H5 | 无未关闭 `BLOCK`，`Q-nnn` 均已升级为 `DEC-nnn` / `ASM-nnn` | 退回 Human |
| H6 | 仓库 Comet 布局可用（`artifact_layout` 与实际产物根一致，`comet` CLI 可用） | **外部条件**（主文档附录 C `EXT-01` / `EXT-02`）：事实到位前**跳过并记 `WARN`**，**不阻塞** H1–H5 与 `open`；事实到位后 H6 自动生效（`99 D49`） |

---

# 5. 回流规则

## 5.1 回流路径总表

| 事件 | 路径 | 语义 | 承担者 |
|---|---|---|---|
| `open` 发现需求冲突 | `open` → **Stage 0** | 需求基线内部冲突 / 与既有需求冲突 | 重新 Challenge（`ufs-challenge`） |
| `design` 无法覆盖 AC | `design` → **Stage 0** | AC 不可实现 / 不完整 / 矛盾 | 重新 Challenge |
| `DESIGN_BLOCKER` | `design` → 停止 | 需求错误或不完整，**不得静默重新解释** | `ufs-design` 报，`ufs-main` 路由 |
| `verify-fail` | verify → **build** | 验证未通过（Comet 原生） | `ufs-verification` |
| `preset-escalate` | build → **full** | 修复中发现变更超出 hotfix/tweak 适用条件 | `ufs-main` + Human |

**硬规则**：`build` / `verify` 发现实现问题时，**不以改写需求作为默认修复方式**。

## 5.2 回流到 Stage 0 的入口条件

回流**不是**"重写需求"，而是**重新走 Stage 0-b**。触发条件必须可判定：

| 触发 | 判定方式 | 回流入点 |
|---|---|---|
| AC 之间互相矛盾 | 同一 Story 内两条 AC 对同一 `When` 给出互斥 `Then` | 0-b Challenge |
| AC 与 Scenario 不匹配 | 场景无法证明 AC，或 AC 无场景 | 0-b Challenge |
| AC 无法被 Design 覆盖 | `design` 报 `DESIGN_BLOCKER` 并给出具体 AC ID | 0-b Challenge → 必要时回 0-a |
| Scope 与既有需求冲突 | `open` 的 intake 比对既有 `specs/**` | 0-b Challenge |
| 关键依赖不成立 | 依赖的组件/前置 Story 不存在或不可获得 | 0-a（重切 Story） |
| Human Decision 被推翻 | Human 主动改变已记录 `DEC-nnn` | 0-a + 0-b（实质变更） |

## 5.3 冻结后不可静默变更的对象

冻结后，以下对象**不得被任何后续 Agent 静默改变**：**Scope / Out of Scope / AC / 关键架构边界 / 关键约束 / Human Decision**。

**变更的唯一合法路径**：提出变更请求 → 记录理由与影响 → **重新 Challenge** → Human 重新 Freeze → 更新镜像。

## 5.4 实质变更 → 强制重新 Challenge

**实质变更的量化集合（逐字引用 `99 D50`；本节与之一致，不得收窄）**——以下**任一**发生即构成实质变更，必须**重新 Challenge 并重签 `freeze-record`**：

1. 任何 AC 的**新增 / 删除 / 语义修改**；
2. **Scope 或 Out of Scope 变更**；
3. **Story 拆分 / 合并**；
4. **新增或变更 `DEC-` / `ASM-`**；
5. **架构边界或主要接口概念变更**。

**不构成实质变更**的变更：仅文字润色、错别字、格式调整——但**必须**在 `challenge-report.md` **追加一条 `WARN` 记录**（不是“留 diff”）。

**判定门槛**：任何导致**已冻结对象的语义、边界或可验证性发生改变**的修改都是实质变更；与上列 5 条取**并集**（上列是下界，不是上限）。

## 5.5 禁止的反模式

| 反模式 | 为什么禁止 |
|---|---|
| `open` 重新定义需求 | `open` 只做 intake + 镜像；重定义使 OpenSpec 成为需求权威 |
| `design` 静默重新解释 AC | 需求错误时应 `STOP` 并报 `DESIGN_BLOCKER` |
| `build` 为通过测试改 AC / 删 Scenario | 违反 `Test Contract Protection`；`Test Failed → 修改 Expected → PASS` 是明令禁止的模式 |
| `build` / `verify` 把实现问题"修"成需求变更 | 问题必须按类回流，不能在错误阶段偷偷修正 |
| `ufs-requirements` 自行宣布 Frozen | 冻结权在 Human |
| `ufs-challenge` 直接改需求 | Challenge 只质疑，不修改 |

---

# 6. 与分册 01 / 02 的接口一致性

> **接口基准**：本章的术语与 ID 规范以主文档 §5.1 与 §5.1.2 为准；Stage 0 的契约以主文档 §4.1、§6.2、§7.3、§8.3 为准。分册 01 与分册 02 若与本章不一致，以主文档为准并回改本章。

## 6.1 AC 八类分类（与分册 01 一致）

分册 01（方法论）冻结 **Acceptance Criteria Categories（八类，至少检查）**。Stage 0-a 产出的每条 AC 集合、以及 Stage 0-b 的每次 Challenge，都必须**逐类**对照：

| # | 类别 | 内容 / 检查示例 | Stage 0 义务 |
|---|---|---|---|
| 1 | Normal Behavior | 正常输入、正常状态、正常流程 | 至少一条 AC 覆盖主路径 |
| 2 | Boundary | `threshold - 1` / `threshold` / `threshold + 1` | 存在阈值即必须有边界 AC |
| 3 | Negative | invalid request / invalid state / resource unavailable | 至少一条失败或拒绝路径 |
| 4 | Error | NAND error / DMA failure / mapping failure / queue failure | 固件必须列出错误注入类 AC |
| 5 | Recovery | `BLOCKED → resources recovered → NORMAL` | 有降级/阻塞态即必须有恢复 AC |
| 6 | State Transition | `NORMAL → WARNING → CRITICAL → RECOVERING → NORMAL` | 有状态机语义即必须有迁移 AC |
| 7 | Timing | latency / timeout / periodic behavior / deadline / ordering | 有实时性约束即必须有 Timing AC |
| 8 | Concurrency | interrupt / ISR / main loop / DMA callback / background task / host IO / GC | **ARM firmware 特别检查** |

**一致性结论**：八类是分册 01 的权威分类，本册只绑定 Stage 0 的**执行义务**（检查 + 记录 N/A 理由 + 进 Freeze Checklist），**不重新定义**类别语义。

**两侧义务对等**：Stage 0-a 的 AC 集合（`prd-split`）与 Stage 0-b 的 Challenge（`ufs-challenge`）**都**承担八类逐类对照义务——0-a 负责**产出时覆盖**，0-b 负责**评审时核验**。**设计契约已增补**：分册 02 §5.10 `P-12` 与 `ufs-challenge` 契约已写入同一义务（**不改写已冻结的 `prd-split` SKILL 正文**，`99 D54`）；**`.opencode/skills/prd-split/SKILL.md` 实现文件待落地**，两处必须一致；本册不因 0-b 有核验义务而免除 0-a 的产出义务。

## 6.2 强制场景规范（与分册 01 一致）

| 规则 | 分册 01 | Stage 0 |
|---|---|---|
| 每条 AC 至少一个 Given/When/Then 场景 | ✅ | prd-split SKILL、grill-me 模板同 |
| 每条 AC 显式列出覆盖它的 Scenario ID | ✅ | prd-split SKILL 强制 |
| `Given` = 可重复建立的前置状态 | ✅ | 同 |
| `When` = **单一**可执行动作或事件 | ✅ | prd-split SKILL、模板同 |
| `Then` = 可观察、可断言，禁用"正常/合理/正确" | ✅ | 同 |
| 高风险行为补充失败/边界场景 | ✅ | prd-split SKILL、模板同 |
| 必要时用 `And` / `But` 扩展 | ✅ | 与一字不改镜像兼容 |

**接口含义**：Stage 0 的场景写法必须与分册 01 的验收场景规范**逐条同构**，否则 `open` 的镜像是语义漂移。

## 6.3 ID 规范（遵循主文档 §5.1 的段数规则与五张命名空间子表）

> **唯一权威 = 主文档 §5.1.1 的五张子表。** 本节只说明"Stage 0 产生哪些对象"，不另立前缀空间。

| 归属 | 对象与格式 |
|---|---|
| **Stage 0 产生** ✅ | Requirement `REQ-001`、Decision `DEC-001`、Assumption `ASM-001`、Epic `EPIC-001`、Capability `CAP-001`（归一，见 §7.1 S0R-1）、Story `STORY-001`、Acceptance Criteria `AC-001-01`、Scenario `SC-001-01` |
| **Stage 0 不产生** ❌ | Acceptance Test `AT-001-01`（`open`）、Design Item `DES-001-01`（`design`）、Test Case `TC-001-01`（`design`→`plan`→`execute`；验证层级由 `level` 承载，如 `level: UNIT` / `level: INTEGRATION`）、Implementation Item `IMP-001-01`（`plan`）、Review Record `RVW-001-01` 与 Review Finding `REV-001-01`（`review`）、Evidence `EVD-001-01`（`execute`/`verify`） |
| **Stage 0 的局部命名空间** ⚠️ | Challenge 报告的 `BLOCK-nnn` / `WARN-nnn` / `Q-nnn` 与报告号 `CHAL-nnn` **永不进入** `REQ→…→EVD` 主干（主文档 §5.1.1 表 N5）；`Q-nnn` 关闭后升级为 `DEC-nnn` 或 `ASM-nnn`（§7.1 S0R-4） |

**段数规则**：对象 ID 为 `<前缀>-<序号>`（单段，表 N1）或 `<前缀>-<Story 号>-<序号>`（两段，表 N2）；域标签（`FC`、`ST` 等）**只允许出现在名称中**，不得出现在 ID 中。因此模板/指南中的 `AC-001`、`SC-001` 属**历史一段式**，进入本平台必须归一为 `AC-001-01`、`SC-001-01`。

## 6.4 与分册 02（Skill 规范）的接口

| 接口点 | 约束 |
|---|---|
| Skill 章节骨架 | 分册 02 把全部 Skill 归一为**统一 18 节模板**（主文档 §7.1、`99 D43`）；`prd-split` 与 `ufs-challenge` 按该模板补充元数据，但**正文不得改写已实现契约** |
| Trigger 章节 | `prd-split` / `ufs-challenge` 均需补齐 Trigger（`99 D39` 的统一要求） |
| Outputs 章节 | `ufs-challenge` 的 Outputs = `challenge-report.md`（五段式，见 §3.10）；`prd-split` 的 Outputs = §2.8 目录合同 |
| Skill 边界 | Skill 描述方法，不保存企业知识；知识归 OpenViking（主文档 §7.2） |
| 调用链 | 固定为 `Comet Node → Skill → Agent → Tool / Plugin`；Stage 0 无 Comet Node，故调用链退化为 `Human → Agent → Skill` |

---

# 7. 设计裁定与外部依赖

## 7.1 裁定清单

下列 20 项是已实现契约与主文档之间需要定性的问题。本册逐条给出**裁定**与理由；裁定即刻生效，后续分册与实现按此执行。

| # | 议题 | 裁定 | 理由 |
|---|---|---|---|
| **S0R-1** | Capability 的 ID | 采用 `CAP-001`；`capability-map.md` 为每个 Capability 写 ID 列 | 主文档 §5.1 以 `CAP-` 登记 Capability；缺 ID 会断 `REQ → Capability → Story` 链（`99 D11`） |
| **S0R-2** | Challenge 产物归档目录 | `comet-artifacts/challenge/` | 主文档 §8.3 已把该目录与 `ufs-challenge` 绑定；`requirements/` 侧会造成自我冻结（`99 D06`） |
| **S0R-3** | AC / Scenario 的 ID 形式 | 两段式 `AC-001-01` / `SC-001-01` | 主文档 §5.1 把单段式列为废弃形式；ID 必须可被 Hook 机器解析（`99 D11`） |
| **S0R-4** | 决策 ID 与评审问题 ID | `DEC-nnn` 是唯一可追溯的 Human 决策 ID；`Q-nnn` 仅限 Challenge 报告内的临时问题，关闭后升级为 `DEC-nnn` 或 `ASM-nnn` | `Q-` 不是主文档 §5.1 登记的对象，不能成为长期权威 ID（`99 D12`） |
| **S0R-5** | `freeze-record.md` 的位置与写入者 | 置于 `comet-artifacts/challenge/`，由 `ufs-challenge` 在 Human 指示下写入；`ufs-requirements` 不得写 | Freeze 记录必须与需求侧分离，否则 `ufs-requirements` 可自我冻结（`99 D06`） |
| **S0R-6** | 输出目录可否覆盖 | 不可覆盖；写路径固定为 `comet-artifacts/requirements/**` | 目录变更等价于变更 Agent 权限，须由 Human 显式改配置（`99 D52`） |
| **S0R-7** | Stage 0-b 的状态表达 | 不设第四态；由 `Verdict` + Human 处置 + `freeze-record.md` 共同表达 | 冻结是 Human 行为，不是 `ufs-requirements` 可写的状态（`99 D51`） |
| **S0R-8** | `ufs-requirements` 的 `primary` 形态 | Phase 1 保持 `primary`，由 Human 直接发起 | Stage 0 在 Comet 生命周期之外，不违反"只有 `ufs-main` 持有生命周期"（`99 D53`） |
| **S0R-9** | AC 八类的强制位置 | 作为 0-a 与 0-b 的双侧义务：0-a 产出时覆盖、0-b 评审时核验 | 分册 01 的八类是权威分类；本册只绑定执行义务，不改写类别语义（`99 D54`） |
| **S0R-10** | `AT-` ID 的归属 | Stage 0 不产生任何 `AT-` ID；由 `open` 从 AC 派生 | 主文档 §5.1 把 `AT-001-01` 的产生位置定为 `open`（`99 D11`、`99 D47`） |
| **S0R-11** | Epic 文件的目录 | 保留 `stories/EPIC-001.md` | 该布局已被 prd-split 实现固化，改名会破坏既有合同 |
| **S0R-12** | 接口概念的表示 | 点号概念名只作标签，不得携带参数、返回值、字段、错误码 | L1 概念架构允许"主要接口概念"，但禁止函数签名 |
| **S0R-13** | Phase 1 的产物校验方式 | 由 `ufs.stage0-validator.v1` 执行三级校验：**guard 一级**（文件存在 + 目录合同）、**guard 二级**（章节齐全）、**guard 三级**（`artifact-structured`）。**不再使用 `L1`/`L2`/`L3` 指代校验深度**（与 §2.5 的“L1 概念架构”同形不同义，G48）；失败动作固定为退回 Stage 0-b 重跑 Challenge；校验集见 §4.3 | `challenge-report.md` / `freeze-record.md` 无 Output Schema 槽位，L3 待 `schema-ext.json` 生效（`99 D01`、`99 D10`、`99 D48`） |
| **S0R-14** | `ufs-challenge` 的契约落地 | 本册第 3 章即其契约；实现落 `.opencode/agents/ufs-challenge.md` 与 `.opencode/skills/ufs-challenge/SKILL.md` | 契约先于实现冻结，避免实现反向定义边界 |
| **S0R-15** | Agent 的温度与步数预算 | `ufs-requirements` 0.1、`ufs-challenge` 0.0；`steps` 作为预算上限 | 对抗式质询需要确定性输出，需求分解允许适度发散 |
| **S0R-16** | Stage 0 的边界纪律 | 禁止调用 Comet CLI 推进阶段；禁止写入 change 目录或 `<openSpecRoot>`；离开 Stage 0 的闸门只有 Human Story Freeze | Stage 0 不在生命周期内，越界会使状态机进入未定义态（`99 D47`） |
| **S0R-17** | `challenge-report.md` 的文件头 | 固定 `report_id` / `story_id` / `story_version` / `review_version` / `reviewed_at` / `reviewed_by` / `inputs` | 评审可复现与版本可追溯的前提 |
| **S0R-18** | Freeze Checklist 的追加条款 | §3.8 的两条（AC 八类覆盖、术语一致）为 Stage 0-b 门禁的权威条款，分册 02 必须逐字镜像 | 0-b 是唯一对抗式门禁，其条款不能在镜像中被稀释（`99 D41`） |
| **S0R-19** | 交接前置条件 | H1–H5 为 `open` 的前置检查，任一不满足即不得进入 `open`；H6 依赖外部事实，归入 §7.2（`EXT-01` / `EXT-02`） | 交接必须可判定，否则 `open` 会消费未冻结的输入（`99 D49`） |
| **S0R-20** | "实质变更"的判定门槛 | 任何改变已冻结对象的语义、边界或可验证性的修改都是实质变更；纯措辞/排版/术语统一不算，但必须留 diff | 保证"重新 Challenge"可触发、可判定 |

## 7.2 依赖外部条件

下列事项的成立不取决于本册，而依赖 Comet Runtime、Output Schema 或本仓库环境的先行条件；条件满足后，本册裁定即可执行。

外部依赖事项的**唯一登记处是主文档附录 C**（编号 `EXT-01`…`EXT-13`）；本表是分册视图，用其编号引用，不另立编号空间。

| # | 事项 | 依赖条件 | 对 Stage 0 的影响 |
|---|---|---|---|
| **`EXT-08`** | External Validator 的运行形态（本地脚本 / 独立服务） | Phase 1 落地形态与可调用的 Comet 能力（`99 §2`） | schema 与失败动作**已裁定**：`ufs.stage0-validator.v1`，`FAIL → 退回 Stage 0-b`（`99 D48`）；三级 guard 见 `99 D01` |
| **`EXT-04`** | 新增产物的 guard 三级启用时点 | 目标 Comet 版本是否支持注册新的 Output Schema 条目（`99 §2`） | guard 一级 / 二级为 MVP 必须；guard 三级复用 `artifact-structured`，待 `schema-ext.json` 生效；登记格式见 `99 D10` |
| **`EXT-01`** / **`EXT-02`** | 本仓库 Comet 布局与 CLI | 配置声明 `artifact_layout: docs`，但 `docs/openspec/` 不存在、产物在根 `openspec/`；`comet` CLI 不在 `PATH`（`99 §2`） | 阻塞 Phase 1 落地；须先修正布局并安装 CLI |
| **`EXT-09`** | Freeze 记录的 Hook 校验挂载点 | `traceability` / `evidence` 两事件面**不新增 Hook**，其语义按 `99 D70`（分册 03 §14.1 IR-13）**指派给现有 H07/H11/H12/H13**；具体挂载点编号与触发时机待 `03` 落地 | 冻结目前由 Human Gate 与文件存在性保证；事件面落地后转由 Hook 校验 |
| **`EXT-10`** | Stage 0 状态纳入 Comet Runtime | 主文档 §13 Phase 2/3 的 Manifest 与状态机 | Stage 0 当前不写 Node Projection、不参与迁移表；纳入时需与投影机制协调 |
| **`EXT-11`** | Capability Token | 仍为提案，不进入 MVP（`99 D68`） | 当前以"写路径白名单 + Hook 放行"为准 |

---

**文档结束。**

配套分册：[00 总体设计](00-总体设计-V2.0.md) ·
[01 方法论](01-方法论-ATDD与测试设计.md) ·
[02 Skill 规范](02-Skill规范.md) ·
[03 Comet 实现设计](03-Comet实现设计-节点特化·Plugin·Hook.md)
