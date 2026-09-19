# 01 · 方法论：ATDD 与测试设计

**版本**：V2.0
**状态**：Design Baseline（分册展开；**只做展开，不得与主文档冲突**）
**上游基准**：[`00-总体设计-V2.0.md`](00-总体设计-V2.0.md)——术语与契约一律以主文档为准
**范围**：工程方法论层 —— `ATDD → Acceptance Test → Test Design → UT Design → TDD → Verification`
**非范围**：平台工具层（Agent 名册 / Plugin / Hook / 状态机 / 目录）归主文档与分册 03；Comet 节点契约归主文档 §2、§4；**逐 Skill 的输入输出契约归分册 02**；Stage 0 需求分解归分册 04

```text
本册回答：行为怎么定义 → 怎么验证 → 怎么实现 → 怎么给出证据
本册不回答：谁在什么节点被调用（主文档 §4）、每个 Skill 的 I/O 是什么（分册 02）
```

---

# 1. 本册说明与术语基线

## 1.1 本册的地位与范围

- 本册是**方法论层的单点权威**：ATDD、Acceptance Test、Test Design、UT Design、TDD、Verification 的规则只在本册定义一次。
- 本册**不重新定义**平台机制。凡涉及 Agent、Plugin、Hook、节点契约、Skill I/O 的内容，本册只按名引用：节点与产物归属见主文档 §4、§8；Agent 名册与职责边界见主文档 §6；逐 Skill 的输入输出与硬规则见**分册 02**；Stage 0 需求分解与 Challenge 见**分册 04**。
- 本册若与主文档冲突，**先改主文档，再改本册**（主文档 §0.1）。

## 1.2 术语基线

本册一律使用**规范表述**列。

| # | 旧写法 | 规范表述 | 依据 |
|---|---|---|---|
| T1 | "Close"、"Close 阶段" | **`archive` 阶段**（phase 之一） | 主文档 §2.7 |
| T2 | "Build Plan 阶段" | **`plan` 节点**（属 `build` 阶段） | 主文档 §2.7 |
| T3 | "Open 阶段（工程调查）" | **`design` 节点 Step 0**，由 `ufs-exploration` 执行 | 主文档 §4.3 |
| T4 | "六阶段" | **不存在**。只有 `open / design / build / verify / archive` 五个 phase 与八个 node | 主文档 §2.7 |
| T5 | `Test Level Decision`、`Verification Level Decision` | **Verification Level** | 主文档 §5.1.3 |
| T6 | Implementation Problem | **`CODE_PROBLEM`**（失败分类第二类） | 主文档 §9.3 |
| T7 | `verifying-before-completion` | **`verification-before-completion`**（真实 Skill 名） | 主文档 §7.1 |
| T8 | Test Design Agent（泛指） | **`ufs-test-design`**（承担 `design` 节点 Step 2） | 主文档 §6.2 |
| T9 | Coding Agent（泛指） | **`ufs-coding`**（承担 `execute` 节点） | 主文档 §6.2 |
| T10 | `AT-FC-001` / `UT-ST-002` 等域标签前缀 | **两段式 `PREFIX-STORY-SEQ`**；域标签只可出现在**名称**中 | 主文档 §5.1 |
| T11 | 层名 `Unit TDD` / `Unit Test`、`Hardware Verification` / `Firmware/HARDWARE Verification` | 五层统一名为 **Unit / Component / Integration / Hardware-Firmware Verification / ATDD** | 本册 §14 |
| T12 | 六个 Verification Level | **七个**：`UNIT / COMPONENT / INTEGRATION / SIMULATOR / HARDWARE / INSPECTION / MANUAL` | 主文档 §5.1.3、本册 §9 |
| **T13** | 裸用“层级”/“层”/“级” | **三套分类各配固定词，禁止裸用**：① **ATDD 三个层次**（ATDD / Design Test / TDD，§3.2）；② **TDD 五层**（Unit / Component / Integration / Hardware-Firmware Verification / ATDD，§14.2）；③ **Verification Level 七级**（`UNIT`…`MANUAL`，§9.1）。写“层级”时必须带限定词（如“验证层级”/“TDD 层”）；三套**不得互称**、不得互称子集（G01）。**唯一例外（M13）**：TDD 五层的 `Component` / `Integration` 与 Verification Level 的 `COMPONENT` / `INTEGRATION` **同名且边界等同**——差别只在**书写大小写**：引用**TDD 分层**时写 `Component` / `Integration`（如 §14.2/§14.3），引用**验证层级取值**时写 `COMPONENT` / `INTEGRATION`。这两级**允许**被视为同一验证范围的两种视角；其余层级名（`Unit` / `HW-FW Verification` / `ATDD`）不得与七级枚举名互换。 | 主文档 §5.1.3 |
| **T14** | 七级层级名的缩写/大小写变体（`Unit` / `Unit Test` / `UT` / `HARDWARE` / `Simulator`） | **一律使用冻结的全大写枚举**：`UNIT` / `COMPONENT` / `INTEGRATION` / `SIMULATOR` / `HARDWARE` / `INSPECTION` / `MANUAL`。`UT` 只作“单元测试用例”的**历史别名前缀**（主文档 §5.1.1 表 N3），`HARDWARE` 为**禁用缩写**（G14） | 主文档 §5.1.3 |
| **T15** | `BLOCK` / `BLOCKED` / `Block` / `blockers` 四者混用 | **四个不同命名空间**：① `BLOCK` = Hook/门禁的**失败动作**（结果码）；② `BLOCKED` = **状态值**（`comet.verify.v1.result` 三态之一、失败分类的阻塞路由态）；③ `Block`（首字母大写）= **行为/用例类别示例名**（八类 Category 的取值见 §5.2，`Block` 不单独作枚举值）；④ `blockers` = `comet.review.v1` 中的**未关闭阻塞 finding 集合**。**四者不得互换**（G15） | 主文档 §5.1.1；分册 02 §0.4 |

**阶段与节点的固定写法**（主文档 §2.7）：

```text
phase（5，Comet 常量，不可改）
  open → design → build → verify → archive

node（8，Comet 原生契约，可按 preset 裁剪）
  open / design / plan / execute / subagent-execute / review / verify / archive
  ※ plan、execute、subagent-execute、review 都在 build 阶段内
```

## 1.3 参考资料

下列资料是本册方法论的来源与依据。

| 资料 | 用途 |
|---|---|
| `Comet + ATDD + UT Design.txt` | 方法论基线 |
| `Comet + ATDD + UT Design_讨论.txt` | 方法论讨论与补充 |
| `Comet + ATDD + UT Design_skills.txt` | Skill 化视角的工程方法 |
| `Comet + ATDD + UT Design_总体架构设计.txt` | Verification Level / Regression Level 的工程约束 |
| `AI辅助UFS_SSD固件开发_ATDD_Comet_完整设计文档_V1.0.md` | 历史版本设计文档 |
| `00-总体设计-V2.0.md` | 术语、生命周期、节点与追溯基准（**唯一权威**） |

## 1.4 关键取舍

方法论来源之间存在若干分歧，本册取定如下，不再保留多版本。

| 议题 | 取定 |
|---|---|
| UT Design 步骤数（16 vs 13） | **16 项超集**（§7） |
| `test-design.md` 章节数（8 vs 16） | **16 节**（§25） |
| UFS TDD 层数（5 vs 4） | **5 层为完整模型**（§14） |
| Legacy 流程 REFACTOR / Regression 顺序 | **REFACTOR → Regression**（§15、§16） |
| Build Plan 必含字段（三版） | **合并超集**，保留 CodeGraph evidence（§12） |
| stock TDD Skill 的处置 | **采用为底层，并经 `ufs-tdd` 特化后使用**（§24） |
| 采用 Skill 的清单与命名 | **使用 Superpowers 真实名称 + UFS 特化清单**（§24） |
| 失败分类第二类的命名 | **`CODE_PROBLEM`**（§19） |
| 有效 RED 的判定 | **必须是可观察的行为失配**（§13.4） |
| 五条正式规则的措辞 | 采用基线文本（§28） |
| 判定环节的命名 | **`Verification Level`**（§9） |
| 验证 Skill 的名称 | **`verification-before-completion`**（§24） |

---

# 2. 核心方法论原则

## 2.1 十条原则

十条原则是方法论的**公理层**：任何 Skill、Agent 行为都不得与之冲突；其**可机器检查的部分落到相应 Hook**（§28）。P7、P8 是强制前置条件，其与 `FR-1..5` 的关系见 §28.7。

| # | 原则 | 规范规则 | 约束对象与落地 |
|---|---|---|---|
| P1 | **Requirement First** | **AI 不应该自行定义需求。需求首先由 `User Story → Acceptance Criteria` 确定。** | 全体 Agent；需求由 Stage 0（`ufs-requirements` + `ufs-challenge`）冻结。§4、§5 |
| P2 | **Behavior First** | **Design 阶段的测试设计首先描述「系统应该表现出什么行为？」，而不是「应该测试哪个函数？」** | `ufs-design` / `ufs-test-design`；`Requirement → Behavior → Acceptance Test`，**禁止** `Existing Function → Test Function → Requirement`。§6 |
| P3 | **Implementation Independent Test Design** | Design 阶段的 UT **不得过早绑定函数名称**（正确写法见 §6.2）。 | `ufs-test-design`；函数级映射延迟到 `plan` / `execute`。§7、§11 |
| P4 | **Verification Level Must Match Behavior** | **不是所有 Firmware 代码都适合 Unit Test。Test Design 必须首先确定验证层级。** | `ufs-test-design`；层级枚举见 §9。 |
| P5 | **Test Is a Contract** | **Test 不是 `ufs-coding` 为了获得 GREEN 可以随意修改的目标。** | `ufs-coding`；禁止 `Test Failed → 修改 Expected → PASS`。§18 |
| P6 | **Testability is a Design quality attribute** | Test Design 必须**反向检查「当前 Implementation Design 是否可测试？」** | `ufs-design`；不可测试判定为**架构问题**。§8 |
| P7 | **Test-First Design Principle** | **任何具有可测试业务逻辑的新功能，在进入 Build 前必须完成对应的 UT Strategy 和 UT Case Design。Build 阶段不得由 `ufs-coding` 临时定义功能行为；`ufs-coding` 必须依据已批准的 Test Design，通过 RED → GREEN → REFACTOR 完成实现。** | `ufs-build-plan` / `ufs-coding`；**`full` preset 的强制前置**：`design` 未产出 UT Strategy / Case → `plan` 不得排任务。`tweak` / `hotfix` 下豁免独立 `test-design.md`，改由 `build-plan.md` 的最小验证设计承担（§4.8）。`execute` 出现"测试里没有的新行为" → Scope 漂移，回 Test Design。§12、§13 |
| P8 | **Legacy Characterization Principle** | **对已有代码进行功能修改时，如果目标代码缺乏可靠的行为测试，Build 前必须优先建立 Characterization Test，形成可验证的 Baseline，然后再针对新行为进入 TDD。** | `ufs-coding`。§16 |
| P9 | **No new behavior without executable evidence**（平台铁律） | **No new behavior without executable evidence.**（新行为 → 必须有验证证据） | 全平台；证据按行为性质分流：可自动化纯逻辑 `RED → GREEN → REFACTOR`；硬件绑定逻辑 `明确测试边界 → 模拟/集成验证 → Hardware Verification`；Legacy `先 Characterize → 建立 Baseline → 再进入 TDD`。§14、§26 |
| P10 | **Test 是 Executable Specification** | **测试不是开发结束后的检查工具，而是需求和实现之间的可执行契约。**（`Requirement → Acceptance Criteria → Executable Test Specification → Design → Implementation`） | 全平台。§22、§29 |

> 说明：P9 **取代** Superpowers 的 `No production code without a failing test first.`；后者作为"可自动化逻辑"分支的具体化保留（§24.6）。

---

# 3. ATDD：定义与三个层次

## 3.1 ATDD 定义

ATDD 的核心作用：**定义系统最终必须表现出的行为。**

```text
AC-001-01
Given:  Free block < Critical Threshold
When:   Host Write arrives
Then:   Host Write shall be blocked
```

ATDD 关注 **External / System Behavior**，而不是内部实现。ATDD 的产物是**可验收的行为契约**，其权威载体是 Stage 0 冻结的 Story / AC / Scenario（主文档 §4.1、§8.2）。

## 3.2 三个层次：ATDD / Design Test / TDD

```text
ATDD        = What                   系统最终必须表现成什么？
Design Test = What internal behavior 为实现该行为需要验证哪些内部行为？
TDD         = How to implement       写代码能不能让这些测试通过？
```

第三层最终才落到：

```text
TC-001-01 → FlowControl_GetPermission() → test_flow_control.c → RED → Implementation → GREEN
```

**层次归属（本册规范）**：

| 层次 | 问题 | 产物 | 归属节点 | 承担 Agent |
|---|---|---|---|---|
| ATDD | 系统必须表现什么 | Story / AC / Scenario / AT | Stage 0 → `open` | `ufs-requirements` / `ufs-main` |
| Design Test | 内部行为如何验证 | `test-design.md`（Verification Level + Behavioral UT） | `design` | `ufs-test-design` |
| TDD | 如何实现并使其通过 | 可执行测试 + 实现 + Evidence | `plan` → `execute` | `ufs-build-plan` / `ufs-coding` |

## 3.3 层次之间的三条硬边界

1. **ATDD 层不写函数名**：AC / AT 只描述可观察行为，不出现文件、函数、Mock 框架。
2. **Design Test 层不写测试代码**：`ufs-test-design` 产出的是策略与用例矩阵，不是 `test_*.c`。
3. **TDD 层不改行为定义**：`ufs-coding` 只能让已批准的测试变 GREEN，不得新增行为或调整 Expected。

```text
ATDD（行为契约，人批准） ──冻结──► Design Test（验证契约，人批准） ──约束──► TDD（实现纪律，机械执行）
```

---

# 4. ATDD 在五个 phase 中的贯彻与职责边界

## 4.1 五 phase 职责表

阶段划分固定为五个 phase（主文档 §2.7）。

| phase | 核心问题 | ATDD / TDD 产物 | 对应节点 |
|---|---|---|---|
| `open` | 做什么？ | User Story / AC / Acceptance Scenario | `open` |
| `design` | 怎么设计？怎么验证？ | Architecture / Interface / **UT Design** | `design` |
| `build` | 怎么实现？ | **RED → GREEN → REFACTOR** | `plan` / `execute` / `subagent-execute` / `review` |
| `verify` | 是否真正满足？ | `UNIT` / `COMPONENT` / `INTEGRATION` / Acceptance Result | `verify` |
| `archive` | 是否形成完整交付？ | Traceability / Final Evidence | `archive` |

## 4.2 一句话职责链与动作链

```text
OPEN   → What?
DESIGN → How should the system behave internally? How can we verify it?
BUILD  → Make it pass.
VERIFY → Does the whole system actually satisfy it?
ARCHIVE→ Is the delivery complete and traceable?

动作链：open 定义测试目标 → design 设计测试 → build 实现测试 + 用测试驱动代码
        → verify 执行完整测试体系 → archive 收口证据与追溯
```

## 4.3 phase `open` 职责边界

核心问题 **What behavior is required?**。**承担**：Requirement Exploration / Requirement Clarification / User Story 分析 / Acceptance Criteria 定义 / Acceptance Scenario 初步定义 / Scope 定义 / 非功能性要求识别。**不承担**：函数级 UT / Mock 设计 / 测试代码 / TDD / 具体实现任务——因为此时**还没有完成具体技术设计**。

**输出**：`User Story / Acceptance Criteria / Acceptance Scenarios / Requirement Constraints`。

**与 Comet 的对齐**：Comet `open` 节点语义是 intake + 确认 + 初始化 state，产物为 OpenSpec `proposal.md` / `spec.md`（**镜像，非权威**，主文档 §4.2、§8.2）；方法论上 AC 的权威在 Stage 0 需求基线。

## 4.4 phase `design` 职责边界

核心问题 **How should the behavior be designed, and what internal behavior must be verified?**——且此时**还没有函数级实现**。产物：`System Design / Architecture Design / Behavior Design / Test Strategy / Test Design / UT Scenario / Testability Design`。

**双轨设计**，两轨互相反馈：

```text
COMET DESIGN
├── System Design ── Architecture / Module / Interface / State Machine / Data Flow
└── Test Design ──── Test Strategy / Unit Boundary / UT Cases / Boundary Cases
                     Error Cases / Recovery Cases / Mock-Stub / Traceability / Exit Criteria

反馈：System Design ↕ Test Design
      若 UT 很难设计：Test Design → 发现不可测试 → System Design → 重新设计
节点 Step（主文档 §4.3）：Step 0 ufs-exploration → Step 1 ufs-design → Step 2 ufs-test-design
```

## 4.5 phase `build` 职责边界

目标：**将 Design 中定义的行为转化为可执行测试和实现**。节点 `plan`（排任务）→ `execute` / `subagent-execute`（写码）→ `review`（独立核查）。输入：已批准 Build Task、Design、Test Contract。产物：Code / Test / Regression Result / TDD Evidence / Implementation Notes。原则：**一次只实现一个已批准 Build Task**。

**禁止**：为通过测试而修改 AC；为取得 GREEN 而修改预期行为；静默修改已批准 Design；扩大 Scope；修无关缺陷；自行修改 Test Contract。

```text
TDD    ：Build Task → Test Preparation → RED → Implementation → GREEN → REFACTOR → Regression → Evidence
Legacy ：CodeGraph → Existing Behavior → Characterization Test → Baseline GREEN
         → New Behavioral Test → RED → Implementation → GREEN → REFACTOR → Regression
```

## 4.6 phase `verify` 职责边界

核心问题 **Does the whole system actually satisfy it?**

```text
verify 不只是 `UNIT` PASS：
`UNIT` → `COMPONENT` → `INTEGRATION` → `SIMULATOR` → `HARDWARE` → Acceptance Test
```

**采用哪些层级由 `design` 节点的 Test Design 决定**（§9、§26）。承担 Agent 为 `ufs-verification`，原则为 **Tests passing alone is insufficient**（主文档 §4.7）。

## 4.7 phase `archive` 职责边界

核心问题 **Is evidence complete and traceable?** 方法论侧判据：确认「需求是否有完整的验证证据」，并形成闭合链：

```text
Requirement → Acceptance Criteria → Acceptance Test → Design → Test Design
→ UT → Build Task → Code → Test Result → Verification Evidence
```

归档前 Hook 机器检查 `REQ → AC → AT → TEST → CODE → RESULT` 是否完整（主文档 §4.8 给出 7 项归档条件的完整清单，本册不重复）。

## 4.8 preset 裁剪与补偿

**节点级裁剪**：

| 能力 | `full` | `tweak` | `hotfix` |
|---|---|---|---|
| Stage 0 需求分解 | ✅ 完整 | ⚠️ 轻量：仅 Story 边界与 AC | ⚠️ 跳过 |
| Stage 0 Challenge | ✅ | ⚠️ 仅 AC 可验证性 | ❌ 跳过 |
| `design` / `ufs-test-design` | ✅ 完整 | ❌ 跳过 | ❌ 跳过 |
| `plan` / `ufs-writing-plans` | ✅ 完整计划 | ⚠️ 简化任务清单 | ⚠️ 简化任务清单 |
| `execute` / `ufs-tdd` | ✅ RED→GREEN→REFACTOR | ✅ 可省 REFACTOR 证据 | ✅ + 根因消除检查 |

**`any` preset**：`any` 是 Skill 创建工作流（主文档 §2.4），**不承载本方法论**，不参与裁剪与豁免。

### 4.8.1 最小验证设计

`tweak` / `hotfix` 跳过 `design` 节点、`ufs-test-design` 不运行，因此需要 `test-design.md` 的**替代载体**：内嵌于 `build-plan.md` 的**最小验证设计**，至少含三节：

1. **Verification Strategy（最小形态）**：本次改动涉及的每个行为 → 一句验证方法。
2. **Verification Level（最小形态）**：每个 Build Task 的 `verification_level`（七级枚举）与判定理由各一行。
3. **UT Case Matrix（最小形态）**：本次改动的行为 → `test_refs` → Expected；至少覆盖正常路径 + 缺陷路径（`hotfix`）或正常路径 + 边界（`tweak`）。

**载体唯一**：这节就是 `build-plan.md` 的 **第 17 节 `Minimal Validation Design`**（分册 02 §9.6.2 第 17 项、§9.8 Step 0）。三块内容分别落到该节的 ①/②/③，**不写入 `§12 Regression Scope`**，也不另建文件。`full` preset 下该节可省，但必须显式写 `not_applicable: full-preset`。

**规则**：「跳过 `design` 节点」**不等于**「跳过验证设计」；最小验证设计的缺失与 `test-design.md` 的缺失同等对待。判定点唯一：`plan` 节点自查 + `H03` 门禁（缺该节或字段不全 → `BLOCK`）。

### 4.8.2 豁免矩阵

**豁免不是「不适用」，而是「改由哪条路径承担 + 必须留痕」。**

| 规则 / 机制 | preset | 承担者 | 是否豁免 | 留痕 |
|---|---|---|---|---|
| **P7**（Build 前完成 UT Strategy / Case） | `full` | `ufs-test-design`（`design` 节点） | 不豁免 | `test-design.md` 的 §2 / §3 / §6 / §7 节 + 验证策略 Human 批准 |
| **P7** | `tweak` | `ufs-build-plan`（`plan` 节点） | 豁免完整形态，改由最小验证设计承担 | `build-plan.md` 的最小验证设计节（逐 Task 的 `verification_level`） |
| **P7** | `hotfix` | `ufs-build-plan`（`plan` 节点） | 同 `tweak`，且只覆盖本次缺陷影响的行为 | 同上 + 缺陷复现用例 ID + 根因消除检查记录 |
| **`test-design.md` 载体** | `full` | `ufs-test-design` | 不豁免 | 文件存在 + 16 节齐全（§25.2） |
| **`test-design.md` 载体** | `tweak` | `ufs-build-plan` | 豁免独立文件，内容内嵌 | `build-plan.md` 的最小验证设计节 |
| **`test-design.md` 载体** | `hotfix` | `ufs-build-plan` | 同 `tweak` | 同上 |
| **Characterization Baseline**（§16） | `full` | `ufs-coding`（`execute` 节点） | 不豁免（目标代码被改动时） | Baseline 用例 + 观测值（`execute` evidence） |
| **Characterization Baseline** | `tweak` | `ufs-coding`（`execute` 节点） | 不豁免（不随 preset 放宽） | 同上 |
| **Characterization Baseline** | `hotfix` | `ufs-coding`（`execute` 节点） | 不豁免；缺陷已有既有行为，以复现用例作为基线 | 复现用例 + RED 证据 |
| **有效 RED**（§13.4） | `full` | `ufs-coding`（`execute` 节点） | 不豁免 | `expected` / `actual` 非空的 RED 证据 |
| **有效 RED** | `tweak` | `ufs-coding`（`execute` 节点） | 不豁免 | 同上 |
| **有效 RED** | `hotfix` | `ufs-coding`（`execute` 节点） | 不豁免 | 同上 + 根因消除检查记录 |
| **Stage 0 Challenge** | `full` | `ufs-challenge`（Stage 0-b） | 不豁免 | `challenge-report.md` + `Verdict` |
| **Stage 0 Challenge** | `tweak` | `ufs-challenge`（Stage 0-b） | 轻量：只质询 AC 可验证性 | `challenge-report.md`（轻量版）+ Freeze 记录 |
| **Stage 0 Challenge** | `hotfix` | `ufs-main` + Human | 豁免独立质询，改由缺陷复现与既有行为确认承担；发现需求缺陷时 `preset-escalate` | 复现用例 + Human 确认记录（`DEC-nnn`） |

### 4.8.3 design 缺口的实现层挂载

| design 缺口 | 承担者（实现层） | 规范出处 |
|---|---|---|
| Verification Level 判定缺失 | `plan` 节点内轻量补做，写入 Build Task 的 `verification_level` | 本册 §4.8 / 分册 02 §9.8；实现挂载见分册 03 §5.2 |
| 无 `test-design.md` | 计划内嵌测试形态与最小验证集合 | 本册 §4.8 / 分册 02 §9.8；分册 03 §5.2 |
| 无架构批准 Gate | 由 **Build Plan 批准 Gate** 合并承担 | 主文档 §10.2 |
| 无 `ufs-test-design` 运行 | Test Contract Protection Hook（H08）仍生效 | 分册 03 §7.3 |
| 无探索报告 | CodeGraph Impact Check（H06）在写入时补事实 | 分册 03 §7.3 |
| 需求本身有缺陷 | `preset-escalate` 升级到 `full` | 主文档 §9.2；分册 03 §5.2 |

### 4.8.4 留痕与引用链

- **豁免项必须进入 gap 记录**：所有豁免项在 `verify` 节点由 `ufs-verification` 记入 gap 记录（Known Issues / Traceability Report），否则不得归档。
- **引用链（单向）**：本册 §4.8 = 方法论规范文本；`ufs-writing-plans` 的轻量补偿条款见**分册 02 §9.8**；实现层挂载（Node / Gate / Hook）见**分册 03 §5.2**。三处不得并行定义同一机制。

---

# 5. Acceptance Criteria 与 Acceptance Test

本章定义「需求怎样才算被说清楚」。AC / Scenario 的产生与冻结属 Stage 0，见分册 04；本章只定义**质量标准与书写规则**。

## 5.1 AC 的定义与质量要求

**Acceptance Criteria 必须满足** `Specific / Observable / Testable / Unambiguous / Traceable`。推荐格式：

```yaml
id: AC-001-01
given: [free_blocks <= critical_threshold]
when:  [host_write_request_arrives]
then:  [host_write_acceptance: BLOCK]
```

下表是 AC 质量的六条硬规则，使用 **`ACR-1`…`ACR-6`** 命名空间（`ACR` = Acceptance Criteria Rules；前缀登记见主文档 §5.1.1 表 N4）：

| # | 要求 | 判定 |
|---|---|---|
| ACR-1 | 可观察 | `then` 中每一项都是外部可观测的状态 / 数值 / 事件，而非"内部逻辑正确" |
| ACR-2 | 可判定 | 存在明确的通过条件，不含大小比较以外的评价性词汇 |
| ACR-3 | 无歧义 | 同一 Scenario 在相同初始条件下只有一个期望结果 |
| ACR-4 | 可追溯 | 可追到 `REQ`，并向后派生 `AT`（主文档 §5.2、§5.3） |
| ACR-5 | 不绑定实现 | 不出现函数名 / 文件名 / 数据结构 / Mock 框架 / 测试框架 |
| ACR-6 | **声明验证意图**（**不声明层级取值**） | `design` 阶段为该 AC 派生的每个行为产出 `verification_strategy` 行（§9）；**层级取值的唯一权威是 `design` 节点**（`test-design.md` §2/§3）。AC 侧只要求“存在验证意图”，**不得**写死 `UNIT`/`HARDWARE` 等层级值——Stage 0 无法预知层级（层级取值的枚举域由 `design` 节点定义，见 `99 D84`）。`tweak`/`hotfix` 跳过 `design` 时，层级取值唯一由 `plan` 节点按 `MR-6` 补做 |

## 5.2 AC 的 8 个类别

| # | 类别 | 覆盖内容 | 固件示例 |
|---|---|---|---|
| 1 | **Normal 正常行为** | 正常输入 / 正常状态 / 正常流程 | GC IDLE 下 Host Write 正常写入 |
| 2 | **Boundary 边界** | `threshold-1 / threshold / threshold+1` 等阈值邻域 | free block == Critical 时是否 block |
| 3 | **Negative 负向** | invalid request / invalid state / resource unavailable | 非法 LBA、非法状态下的命令 |
| 4 | **Error 错误** | NAND error / DMA failure / mapping failure / queue failure | NAND program fail 的处理 |
| 5 | **Recovery 恢复** | 从异常状态回到正常状态 | `BLOCKED → resources recovered → NORMAL` |
| 6 | **State Transition 状态转换** | 合法链路与非法转换 | `NORMAL → WARNING → CRITICAL → RECOVERING → NORMAL` |
| 7 | **Timing 时序** | latency / timeout / periodic behavior / deadline / ordering | GC 生效时点、命令超时 |
| 8 | **Concurrency 并发** | interrupt / ISR / main loop / DMA callback / background task / host IO / GC | ISR 与主循环对同一状态字段的更新 |

**硬规则**：八类是**覆盖面检查清单**（一个 AC 可同时属于多类）；凡**不适用**者必须显式写"不适用 + 理由"，尤其第 3、4、5、8 类——它们是固件最危险的路径。

## 5.3 Acceptance Scenario 书写约定

```gherkin
Scenario: Block host write under critical resource pressure
Given the firmware is in normal operation
And the available block count is above the critical threshold
When the available block count reaches the critical threshold
And a new host write request arrives
Then the firmware shall reject or defer the host write according to the defined flow-control policy
```

| # | 约定 | 说明 |
|---|---|---|
| S1 | 使用 `Given / When / Then`，必要时 `And / But` | 不写自由叙述式场景 |
| S2 | **显式 Scenario ID** | `SC-<STORY>-<SEQ>`（主文档 §5.1）；场景必须在 AC 下可枚举 |
| S3 | `Then` 必须是**可观察通过条件** | 观测点 + 期望值/区间 + 观测时机三者齐全 |
| S4 | 一个 AC → 1..N 个 Scenario | 覆盖不同侧面，不建议把八类压进一个 Scenario |
| S5 | 不写实现细节 | 不出现函数、文件、状态变量名、Mock |
| S6 | Scenario 与 AT 可一对一或一对多 | Scenario 是行为描述，AT 是可执行契约（§5.6） |

> **裁定**：**AT 由 AC 派生；Scenario 是 AC 的实例化描述。** 一个 AC → 1..N 个 Scenario；一个 Scenario → 1..N 个 AT（同一 Scenario 可被多层级的 AT 复用）。**Scenario 不得作为 AT 的父节点**——两者是「实例」与「验证实现」的关系（与分册 04 一致）。

## 5.4 禁止的模糊措辞

为可机器检查，`Then` 中禁止以下写法：

| 禁止出现在 `Then` 中的写法 | 原因 | 替代写法 |
|---|---|---|
| 正常工作 / 正确 / 合适 / 合理 / 应该没问题 | 不可观察、不可判定 | 写明被观测量与期望值："Host Write 被拒绝，返回 `FLOW_CONTROL`" |
| 适当 / 尽量 / 尽可能 / 足够快 / 等等 / 若干 / 必要时 | 不可判定，无法机械扫描出通过条件 | 写明具体取值、范围或枚举 |
| 尽快 / 及时 / 快速地 | 无阈值 | 写明 `timeout <= N ms` 或 `within N cycles` |
| 性能良好 / 效率高 | 无度量 | 写明吞吐 / 延迟 / 资源占用的具体阈值 |
| 与之前一致 | 无基线 | 指向 Characterization Baseline 的具体行为条目 |
| 函数 `Xxx_Handle()` 行为正确 | 违反 `ACR-5` | 改为系统级可观察行为 |

**反向判据（人工）**：把 `Then` 交给另一个未读过实现的工程师，若他给出两个以上不同的通过判据 → 由 `ufs-document-review` **人工**判定 `NEEDS_REVISION`（主文档 §6.3、§7.3）。

**效力（99 D31）**：上述禁例立即生效并进入 Freeze Checklist。AC / Scenario 出现这些不可判定措辞时，Stage 0-b **必须**开 `BLOCK` Finding；Freeze Checklist 的"每条 AC 都可被观察、执行与判定"由"人工确认"升级为"人工确认 + 关键词机械扫描"。

## 5.5 AC 完整性检查清单

```text
Functional   [ ] normal        [ ] boundary      [ ] negative      [ ] error        [ ] recovery
State        [ ] state transition  [ ] invalid transition  [ ] recovery transition
Timing       [ ] timeout       [ ] latency       [ ] ordering
Concurrency  [ ] interrupt     [ ] concurrent IO [ ] background task  [ ] DMA
Hardware     [ ] hardware boundary  [ ] register behavior  [ ] reset behavior
Traceability [ ] Requirement → AC   [ ] AC → AT
```

`open` 阶段结束前需 `★ Human Approval`，至少确认：`Acceptance Criteria / Acceptance Scenarios / Acceptance Tests / Major assumptions / Open Questions / Behavior changes`（完整 Gate 清单见主文档 §10.2，不重复）。

## 5.6 Acceptance Test 的职责

Acceptance Test 验证：**从系统/用户视角看，需求是否成立。**

```text
AT-001-01
1. Start firmware      2. Create low-free-block condition    3. Issue Host Write
4. Observe Host Write behavior                                5. Verify write is blocked
```

```yaml
test_id: AT-001-01
acceptance_refs:   [AC-001-01]
preconditions:     [firmware initialized, flow control enabled]
stimulus:          [free block count reaches critical threshold, host write request arrives]
expected_behavior: [host write is blocked or deferred, no invalid NAND operation is issued]
postconditions:    [firmware remains in valid flow-control state]
```

**关键约束**：AT **不要求在 `open` 阶段**就已经知道 `function name / file name / mock framework / test framework`。

## 5.7 Acceptance Test 是需求层测试，且不默认是 `UNIT`

```text
AC（需求层）→ AT → UT（内部行为层）→ TDD（实现层）

        AC-001-01
            │
            ▼
        AT-001-01
            │
    ┌───────┴───────┐
    ▼               ▼
TC-001-01       TC-001-02
    └───────┬───────┘
            ▼
      Implementation
```

AT 可以运行在 `Firmware Simulator / Integration Environment / Hardware / System Test Environment`；**AT 的验证层级由 `Verification Level` 决定（§9），不默认是 `UNIT`**。

## 5.8 AC 不直接连 UT

**Acceptance Criteria 不应该直接连接到 UT**。推荐链路：

```text
Acceptance Criteria → Acceptance Test → Design → UT
AC-001-01 → AT-001-01 → { TC-001-01, TC-001-02, TC-001-03 }
```

中间**必须**经过 Acceptance Test / Scenario 与 System / Component Behavior。**禁止**的写法：`AC = UT`；强制一对一 `AC-001-01 → AT-001-01 → TC-001-01`。

## 5.9 Acceptance Test 与 Characterization Test 的分工

> **Characterization Test 固化 Existing Behavior；Acceptance Test 固化 Required Behavior。**

| 维度 | Acceptance Test | Characterization Test |
|---|---|---|
| 固化对象 | **Required Behavior**（需求要求的行为） | **Existing Behavior**（旧代码实际表现的行为） |
| 来源 | Requirement / AC | CodeGraph + 运行时观测 |
| 用途 | 验收 | 建立 Legacy 基线，保护既有行为 |
| 变化政策 | 变更须有需求/设计依据 | 变更须记录 `Behavior Change` 并经批准（§16.4） |
| 是否证明"正确" | 是（相对需求） | **否**（只记录"实际做了什么"） |

**硬规则**：必须区分 `Requirement` 与 `Existing Behavior`；**不能让 `ufs-coding` 偷偷修改测试去适配旧行为**。

---

# 6. Test Design：从函数级到行为级

## 6.1 Behavioral Test Design，而非 Function-level Test Implementation

`design` 阶段还没有函数级实现，因此此阶段设计的是 **Behavioral Test Design**，而不是 **Function-level Test Implementation**。

| 阶段 | 确定内容 | 问题形式 |
|---|---|---|
| `design` | **WHAT TO TEST** | 系统/单元必须表现什么行为？ |
| `plan` | **WHERE TO TEST**（映射到接口/函数/文件） | 这些行为在哪里被实现与被测试？ |
| `execute` | **HOW TO IMPLEMENT TEST** | 测试代码怎么写、怎么跑 |

**硬规则**：`design` 节点的 `test-design.md` 中出现具体函数名 → 违反 Implementation Independence（`FR-4`，§28.4）。

## 6.2 Behavioral UT Design 示例（Flow Control）

```text
TC-001-01  Condition: free blocks > Recovery Threshold              Behavior: evaluate write permission  Expected: ALLOW
TC-001-02  Condition: free blocks < Critical Threshold              Behavior: evaluate write permission  Expected: BLOCK
TC-001-03  Condition: state = BLOCKED, free blocks 介于两阈值之间    Behavior: evaluate state             Expected: remain BLOCKED
TC-001-04  Condition: state = BLOCKED, free blocks >= Recovery      Behavior: evaluate recovery          Expected: ALLOW
```

此时**不要求知道**这些行为最终落在哪些函数上——函数映射属于 `plan` / `execute` 节点（§12.4、§13.9）。

## 6.3 Design 阶段的 UT Case 面向「测试对象」

行为级 UT Case 以**测试对象**（test object）为锚，而不是函数：

```yaml
test_object:
  name: Host Write Flow Control
  behavior:
    - determine whether host write is allowed
    - maintain flow control state
    - recover from critical condition
```

`test_object` 是 `design` 节点的合法粒度；函数是该 test object 在 `plan` / `execute` 节点的**实现选择**。

## 6.4 为什么必须延迟函数绑定

**过早绑定的失败链**：

```text
Requirement → Design → 猜函数 → 设计 UT → Build 发现函数设计改变 → UT 全部需要重写
```

AI Coding 场景尤其容易发生：AI 会在 `design` 阶段"顺手"猜出函数边界，而这些边界在真实实现中经常改变。

| 写法 | 后果 |
|---|---|
| 以函数命名测试（如 `Test Xxx_Evaluate()`） | 测试设计被实现绑死；函数改名 / 拆分 → 测试全部重写 |
| `TC-001-02: Given free block < Critical → Then write permission == BLOCK` | 实现怎么变化都不影响测试设计 |

## 6.5 Test Design 的正式输入与输出

验证架构由 `ufs-test-design` 承担（`design` 节点 Step 2）。

```text
输入：Acceptance Criteria + Implementation Design + CodeGraph
      （Greenfield 另含 Architecture Design；Legacy 另含 Existing Code / Existing Behavior Analysis）
输出：Test Strategy / Verification Level / Test Boundary / Behavioral UT Scenario / UT Case Matrix
      Boundary Cases / State Transition Cases / Error-Recovery Cases / Mock-Stub Strategy
      Testability Analysis / Requirement Traceability / Characterization Test

职责链：Acceptance Criteria → Design → Testability → UT Strategy → UT Case Matrix → Mock/Stub → Traceability
```

**边界**：`ufs-test-design` **不负责写最终 UT 代码**；也不应在 `open` 阶段独立工作——**UT 是实现级测试，它依赖于设计**，位置是 `open → ATDD → design → ufs-test-design`。逐项 I/O 契约见**分册 02**。

## 6.6 UT 设计不得由 `ufs-coding` 主导

若 `design` 完成后由 `ufs-coding`「顺便想几个 UT」，链路退化为：

```text
AI 决定怎么实现 → AI 根据自己的实现设计 UT → UT 验证 AI 自己的代码
```

**TDD 的核心价值在此完全丧失。** 正确顺序：`Requirement → Acceptance Criteria → Architecture/Interface → UT Design → Implementation`。

> **测试设计应该先于生产代码实现，但可以晚于需求和架构设计。**

因此 **「UT Test Design」和「UT Implementation」必须分开**：

| 活动 | 归属节点 | 承担 Agent |
|---|---|---|
| UT 用例**设计**（行为级） | `design` | `ufs-test-design` |
| UT 用例**映射**（→ 接口 / 函数） | `plan` | `ufs-build-plan` |
| UT 用例**编码、执行、驱动实现** | `execute` | `ufs-coding` |

**硬规则**：`full` preset 下，`plan` 节点无 `test-design.md` 不排任务；`tweak` / `hotfix` 下，`plan` 节点无 **`build-plan.md` 的最小验证设计节**（§4.8.1）不排任务；`ufs-coding` 不得修改 `test-design.md`，测试变更走 §18 路径。

---

# 7. UT Design 方法论（16 项超集）

## 7.0 定位与构成

**核心公式**：

```text
Behavior → Boundary → State → Error → Interaction → Test Case
```

展开为：`需求行为 → 正常行为 → 边界行为 → 状态转换 → 异常行为 → 依赖交互 → 测试用例`。

**方法论构成**：UT Design 由 16 项构成——第 1–13 项逐项分析行为与风险，第 14–16 项把分析结果收敛为用例矩阵、追溯链与完成条件。规范顺序先分析、后综合。

**16 项规范清单**：

```text
UT Design Methodology（16 项）
   1. Unit Boundary             2. Observable Behavior      3. Input Domain
   4. Equivalence Partition     5. Boundary Analysis        6. State Transition
   7. Error / Recovery          8. Dependency Interaction   9. Mock / Stub Strategy
  10. Concurrency / Interrupt  11. Timing                 12. Resource Exhaustion
  13. Hardware Boundary        14. Test Case Matrix       15. Requirement Traceability
  16. Coverage / Exit Criteria
```

## 7.1 第 1 项：Unit Boundary

第一件事不是写测试，而是确定「**什么东西算一个 Unit？**」——**必须用行为名表达**（`FR-4`，§28.4）：`Flow Control`（Host Write 流量控制行为边界）可以作为一个 Unit；`Host Write Request Handling` 太大（内含 `Host → Queue → Scheduler → GC → FTL → NAND`，测试需启动整个 Firmware，成本极高）；`Unit: HostWrite module` 是错误表述（模块不是 Unit）。**`design` 制品（含 `test-design.md`）不得出现函数名**；函数级示例只允许出现在 `plan`（§12.4、§12.5）与 `execute`（§13.9）语境。

**规则**：Unit 必须能用有限输入集合触发其**全部**可观察输出；Unit 过大 ⇒ 拆分为 `Pure Logic + Hardware Adapter`（§8.3），而不是加大 Mock 规模；Unit Boundary 是 `test-design.md` 的必填节（§25）。

## 7.2 第 2 项：Observable Behavior

可观察行为取值域：`ALLOW / BLOCK / STATE CHANGE / ERROR / RECOVERY`。Unit 必须存在可观察结果（`Input → Function → Output`）。**行为空间**示例（GC × Outstanding）：

| GC | Outstanding | Expected | GC | Outstanding | Expected |
|---|---:|---|---|---:|---|
| IDLE | 0 | ALLOW | ACTIVE | 8 | BLOCK |
| IDLE | 8 | ALLOW | CRITICAL | 4 | ALLOW |
| ACTIVE | 4 | ALLOW | CRITICAL | 8 | BLOCK |

**规则**：先枚举行为空间，再写用例；**没有可观察输出的 Unit 不是可测 Unit**，其验证层级应改判（§9）。

> **唯一权威（A03）**：**可观察结果词表** = `ALLOW / BLOCK / STATE CHANGE / ERROR / RECOVERY`（本节）；上例的 `NORMAL / THROTTLE / BLOCK` 是**该示例域内的结果取值**，是词表在“GC × Outstanding”域上的实例化，**不是第二套词表**。本册其它位置的示例结果（如 §16.5 的 `THROTTLE`、§14.3 的 `limited/blocked`）**必须以本节词表为准**：`allowed → ALLOW`、`throttled / limited / blocked → BLOCK`、`recovered → RECOVERY`。**同一个 `Input`（GC=CRITICAL, Outstanding=8）在全册只有一个期望：`BLOCK`**（§16.5 的 `THROTTLE` 已按此更正）。

## 7.3 第 3 项：Input Domain

阈值为 `Recovery` / `Critical` 时：

```text
free_blocks > Recovery
free_blocks == Recovery
Critical < free_blocks < Recovery
free_blocks == Critical
free_blocks < Critical
```

**规则**：Input Domain 必须**覆盖全部区间及每个边界点**，并与 Equivalence Partition（第 4 项）、Boundary Analysis（第 5 项）一一对应；区间定义必须写出开闭性（`>` vs `>=`）。

## 7.4 第 4 项：Equivalence Partition

**输入等价类**（对 *输入域* 的划分）：

```text
Normal / Boundary / Critical / Invalid / Recovery
```

**规则**：每个等价类至少 1 个用例；`Invalid` 类不得省略；等价类必须与 Input Domain 的区间划分一致（不得出现"未归类"的输入）。

**两套分类系统的关系（B14，唯一映射表）**：本节的 **等价类**划分的是*输入域*，`§5.2` / `§7.14` 的 **Category（八类）**划分的是*用例动机*。二者不是同一维度，必须按下表映射，**不得互称**：

| 输入等价类（本节） | 对应 Category（§5.2 八类） | 说明 |
|---|---|---|
| `Normal` | `Normal` | 正常路径 |
| `Boundary` | `Boundary` | 阈值/边界取值 |
| `Critical` | `Boundary` | 临界阈值（`threshold` 与 `threshold±1`）——**归入 `Boundary`**，不另立 Category |
| `Invalid` | `Negative` | 非法输入；`State Transition` 的**非法转换**行也归 `Negative` |
| `Recovery` | `Recovery` | 恢复路径 |

**未覆盖项**：`§5.2` 八类中的 `Error` / `State Transition` / `Timing` / `Concurrency` 四类**不是输入等价类**，不由本节划分——它们由 `§7.7`（Error）、`§7.6`（State Transition）、`§7.11`（Timing）、`§7.10`（Concurrency）覆盖。
**"一一对应"的正确含义**：每条 `TC-*` 的 `Category` 必须能由上表的某个等价类**或**上述四个专项分析项解释，**不得出现无来源的 Category**。。

## 7.5 第 5 项：Boundary Analysis

重点测试 `Critical-1 / Critical / Critical+1` 与 `Recovery-1 / Recovery / Recovery+1`。

完整边界集（**唯一权威 = §25.3 第 8 节**；本节只给常用子集）：

```text
min / min+1 / normal / threshold-1 / threshold / threshold+1 / max-1 / max / invalid
```

> **权威归属（A17）**：边界集的**权威超集是 §25.3 第 8 节的 10 项**（`0 / 1 / threshold-1 / threshold / threshold+1 / MAX / overflow / underflow / invalid state / unexpected transition`）。
> 本节的 9 项与 §20.5 的 4 项（`min / max / max+1 / min-1`；`min-1` 即下溢/`underflow` 边界）都是**其子集**，冲突时以 §25.3 第 8 节为准。

**固件重点**：大量 Bug 来自 `> / >= / < / <=` 的错用，以及 `overflow / underflow / wraparound`。高危类型：`uint16_t / uint32_t / counter / queue depth / LBA / length / timeout / retry count`。

## 7.6 第 6 项：State Transition

需要测试：

```text
NORMAL → CRITICAL → BLOCKED → RECOVERY → NORMAL
（GC 状态机表述：GC_IDLE → GC_ACTIVE → GC_CRITICAL → GC_RECOVERY → GC_IDLE）
```

**规则**：

- UT **不应只测试单个状态**（如 `GC_CRITICAL`），还要测试每条转换：`IDLE→ACTIVE`、`ACTIVE→CRITICAL`、`CRITICAL→RECOVERY`、`RECOVERY→IDLE`；
- **必须包含非法转换**（如 `IDLE→RECOVERY`），期望为拒绝 / 报错 / 保持原状态；
- 需要 **State Transition Coverage**：所有合法转换 + 所有非法转换。

## 7.7 第 7 项：Error / Recovery

测试项：`Invalid Input / Resource Exhaustion / Timeout / Error State / Retry / Recovery / Unexpected State`。**正常路径远远不够**，Firmware 必须重点考虑 `Timeout / Retry / Resource unavailable / Invalid parameter / Queue full / Memory unavailable / Hardware error / Unexpected state`。

```text
Normal → Error → Retry → Recovery → Normal

必须测试的转换：Error → Retry      Error → Fatal      Retry → Success
                Retry → Timeout    Recovery → Resume
```

**规则**：否则 UT 可能覆盖 90% 正常路径，却没有覆盖真正危险的 firmware path；重试需验证计数——`retry_count == 2` 仍继续重试，`retry_count == MAX_RETRY` 必须进入 `Fatal / Recovery`。

## 7.8 第 8 项：Dependency Interaction

分析依赖：`NAND / DMA / Queue / Scheduler / Resource Manager / Hardware Adapter`。

**规则**：UT 不只验证 return value，**还可能验证交互是否发生**：

```text
GC_CRITICAL + outstanding > threshold → Expected: 产生一次「调度器抑制通知」行为
```

交互型断言必须明确"**调用发生 + 参数正确 + 次数正确**"三者中的哪些。函数级形态（通知哪个函数、传什么参数）属于 `plan` / `execute` 节点的映射内容（§12.4、§13.9）。

## 7.9 第 9 项：Mock / Stub Strategy

**明确哪些依赖应该 Mock / Stub / Fake / Spy / Real Component**，并在 `design` 阶段就定义，使 `ufs-coding` **不需要自己临时决定测试架构**：

```text
GC 等级查询行为         → Mock
队列未完成数查询行为     → Stub
调度器通知行为           → Spy
寄存器读取行为           → Mock
```

函数级映射见 §12.4（`plan`）、§13.9（`execute`）；`design` 语境不得出现函数名（`FR-4`）。

**规则**：

| 替身 | 用途 | 断言形态 |
|---|---|---|
| Mock | 提供受控返回值 / 校验调用 | 返回值 + 调用校验 |
| Stub | 只提供固定输入 | 返回值 |
| Spy | 记录调用 | 调用次数 / 参数 |
| Fake | 轻量可运行替代实现 | 行为等价性 |
| Real Component | 真实依赖（成本允许时优先） | 端到端行为 |

禁止"为了覆盖率强行 Mock 所有硬件"（§9.7）。

## 7.10 第 10 项：Concurrency / Interrupt

必须覆盖 `ISR / Concurrent Access / Race Condition / Atomicity / Critical Section / Locking / Event Ordering`。**规则**：涉及共享状态字段的 Unit 必须至少有一条用例构造"ISR 与主流程交错"的可复现顺序；不可复现的并发 → 提升验证层级（§9）。

## 7.11 第 11 项：Timing

必须定义并测试 `Timeout / Deadline / Timer / Retry Interval / Scheduling Timing`。时序断言必须写明**观测时机**（"下一次 IO 生效"还是"立即生效"）；依赖真实时钟或硬件计时的部分归 `SIMULATOR` / `HARDWARE`（§9.7）。

## 7.12 第 12 项：Resource Exhaustion

覆盖 `Memory Exhaustion / Queue Full / Buffer Exhaustion / NAND Resource Exhaustion / DMA Resource Exhaustion`。每类资源至少一条"耗尽后行为"与一条"恢复后行为"用例；计数断言同时覆盖 `0` 与 `MAX`（第 5 项）。

## 7.13 第 13 项：Hardware Boundary

必须明确 `Pure Logic / Hardware Adapter / Hardware-dependent Code` 三者边界。只有 `Pure Logic` 强制 UT + TDD；`Hardware Adapter` 走 Integration / Hardware Test；`Hardware-dependent Code` 必须显式声明测试边界与不可测理由（不可测声明按 §16.4 的 `non_testable[]` 机制审批，99 D22）。

## 7.14 第 14 项：Test Case Matrix

> **UT 不是为了覆盖代码，而是覆盖行为空间。**
>
> **列契约唯一权威 = §25.3 第 7 节**：`ID / Category / Input / Expected / refs`（5 列）。本节示例省略了 `refs` 列以便阅读；`§21.1` 的 `Operation` 列与分册 02 早期版本的 `Behavior / Boundary / Type` 列**均已撤回**，统一按 §25.3 第 7 节。

| ID | Category | Input | Expected | refs |
|---|---|---|---|---|
| TC-001-01 | Normal | GC_IDLE / 0 | ALLOW | `AC-001-01` / `BEH-001-01` |
| TC-001-02 | Negative | GC_CRITICAL / 8 | BLOCK | `AC-001-02` / `BEH-001-02` |
| TC-001-03 | Boundary | GC_CRITICAL / 5 | BLOCK | `AC-001-02` / `BEH-001-03` |
| TC-001-04 | State Transition | CRITICAL → RECOVERY | RECOVERY | `AC-001-04` / `BEH-001-04` |
| TC-001-05 | Error | Retry 耗尽 | ERROR | `AC-001-05` / `BEH-001-05` |
| TC-001-06 | Negative | INVALID_GC | ERROR | `DES-001-02` / `BEH-001-06` |
| TC-001-07 | Concurrency | BLOCK（调度器抑制通知） | STATE CHANGE | `DES-001-03` / `BEH-001-07` |

> **两处口径的落实（B4/B5）**：① `Category` 列**只取 §5.2 的八类**（`Normal / Boundary / Negative / Error / Recovery / State Transition / Timing / Concurrency`）——上表已把原 `Block` 改为 `Negative`、`Invalid` 改为 `Negative`、`Error / Recovery` 拆为 `Error` 与 `Recovery`（本表 `TC-001-05` 取 `Error`），`Interaction` 属**名称**而非类别；② `Expected` 列**只取 §7.2 的五词闭集** `ALLOW / BLOCK / STATE CHANGE / ERROR / RECOVERY`（原 `NORMAL`/`THROTTLE`/`RESUME`/`FATAL` 已按 A03 的映射更正）。

**示例 TC ID 的语义（全册统一，保证追溯骨架无歧义）**：`TC-001-01` = 正常、`TC-001-02` = 阻塞、`TC-001-03` = 边界、`TC-001-04` = 状态转换、`TC-001-05` = 错误恢复；`TC-001-06` 及以后按用例追加。以上示例的 `level` 均为 `UNIT`；`TC-001-08` = 集成示例（`level: INTEGRATION`），`TC-001-09`/`TC-001-10` = 表征示例（`case_type: characterization`），`TC-001-21`–`TC-001-23` = 无 AC 的单元示例。

**规则**：`Category` 列必须取自 §5.2 的八类（**`Interaction` 不是类别值**，只作名称）；每一行必须能追到 AC 或 Design Constraint（第 15 项）；**UT Case 是 Build Plan 的行为约束，不是 Build Task**（§12.4）。

## 7.15 第 15 项：Requirement Traceability

每个 Test 都应能追溯 `Test → Acceptance Criteria → Requirement`，并能回答反向问题：「**这个 UT 是为了哪个需求？**」

**规则**：每个 UT Case 至少携带一个 `acceptance_refs` 或 `design_constraint` 引用；无直接 AC 的 UT 按 §11.4 处置（标注来源类型与理由，进入审查），**不得静默存在，也不得反向伪造 AC**；机器可读形态见 §22.2。

## 7.16 第 16 项：Coverage / Exit Criteria

> **Coverage 可以是指标，但不能作为唯一完成条件。**

**规则**：Exit Criteria 是**清单式**而非数值式（§27.1）；覆盖率不设统一阈值（§30.1 MR-3）。本项的逐条可判定形态见 §27.1（`design`）与 §26.1（`verify`）。

---

# 8. Testability Design 与架构反馈

## 8.1 不可测试 = 架构问题

典型反例：

```text
行为边界（过大的 Unit）：
Host Write 处理入口
  内部：读寄存器 / 检查 GC / 检查队列 / 修改全局状态
        / 调用 Scheduler / 访问 DMA / 触发 NAND
```

为了测试一个判断，需要初始化 20 个 global variable、8 个 register、3 个 interrupt state、2 个 DMA descriptor。

**此时真正的问题不是「UT 太难写」，而是这个设计的可测试性有问题。** 不能简单说「那就 Mock 一下」——因为可能意味着架构设计本身存在问题。应反馈为：

```text
Testability Issue / HostWriteHandler:
- hardware coupling
- global state coupling
- DMA coupling
- NAND dependency
```

> 本节与下一节的代码块是**架构反例 / 拆分示意**，其中的函数形态仅用于说明耦合问题；**正式 `design` 制品不得出现函数名**（`FR-4`）。

**规则**：`ufs-test-design` 在 `design` 节点写出 Testability Issue 后，属**设计返工信号**，不得以"降低测试要求"收口。

## 8.2 Testability 驱动架构

`design` 阶段应发生：

```text
Design → 设计 UT → 发现难以测试 → 重新审视接口 → 降低耦合 → 重新设计
```

拆分示例（**design 语境用行为名**）：

```text
行为边界 1：判定流控状态          （输入：GC 级别、outstanding 计数）
行为边界 2：判定是否抑制          （输入：流控状态、阈值）
转换入口  ：真实 Hardware State → 纯逻辑输入（归属 Hardware Adapter）
函数签名层示例见 §12.4 / §13.9（plan / execute 语境）
```

于是形成单向依赖：

```text
Hardware → Adapter → Pure Logic → UNIT
```

> **Test Design 不只是测试代码设计，它应该反向约束 Implementation Design。**

## 8.3 Adapter 拆分模式

```text
HostWriteHandler
    ├── FlowControl ── Pure Logic      → UNIT + TDD
    ├── NandAdapter      ┐
    ├── DmaAdapter       ├─ Hardware Adapter → Integration / Hardware Test
    └── HardwareAdapter  ┘
```

**规则**：Adapter 只做「真实硬件状态 ↔ 纯逻辑输入输出」的转换，**不得承载业务判断**；业务判断留在 Pure Logic，以保持 UT 可覆盖。

## 8.4 Testability 的产物与门禁

| 产物 | 内容 | 门禁 |
|---|---|---|
| Testability Analysis | 耦合点清单（hardware / global state / DMA / NAND / timing） | `design` 节点 Human Gate：验证策略批准 |
| Adapter 划分 | Pure Logic / Hardware Adapter / Hardware-dependent 清单 | 同上 |
| 不可测声明 | 无法 UT 的行为 + 理由 + 替代验证层级 | 按 §30.1 MR-9 审批 |

---

# 9. Verification Level（层级判定）

## 9.0 行为（Behavior）—— 本方法论的核心对象

**定义**：一个**可独立验证的系统行为**，形如「在条件 C 下，系统表现出 B」；粒度由 §7.1 的 Unit Boundary 界定。

**ID**：`BEH-<STORY>-<SEQ>`（主文档 §5.1），**全链唯一**。

**枚举域（穷举来源）**——三者之外不存在行为：

1. Stage 0 的每条 **AC**；
2. 每条 **Scenario** 所描述的行为；
3. `design` 阶段由 **Testability 分析**或 **Design Constraint** 识别出的内部行为（须按 §11.4 标注来源类型）。

`verification_strategy` **不得出现无来源的行**。

**与下游的关系**：

```text
BEH-* （行为）
  ├── levels[]（一个或多个层级，§9.4）
  ├── TC-*（一个或多个测试用例，层级由 level 属性承载）
  └── （经 plan）被 ≥1 个 Build Task 的 test_refs 引用
```

**规则**：Build Task 的 `verification_level` 仍是**单值**（该 Task 必须提供的最高执行型层级，§12.5）；行为的完整层级集合由 `BEH-*` 的 `levels[]` 承载（§9.4）。

## 9.1 原则

不是所有需求都需要 `UNIT`。`ufs-test-design` **首先判断验证层级**：

```text
Behavior → Verification Level（七级闭集，取值不分行优先级）
  UNIT / COMPONENT / INTEGRATION / SIMULATOR / HARDWARE / INSPECTION / MANUAL
```

**不能**建立「每一个 Acceptance Criteria → 必须有 UT」；**应**建立「每一个 Acceptance Criteria → 必须有适当层级的 Verification」。

> **`UNIT`（单元测试）是验证策略的一部分，而不是验证策略本身。**

**术语归一**：`Test Level Decision` 与 `Verification Level Decision` 同义；本册**只用 `Verification Level`**。

## 9.2 七个 Verification Level 与边界

| # | Level | 边界（验证什么） | 环境 | 典型对象 | 证据形态 |
|---|---|---|---|---|---|
| 1 | `UNIT` | 单个 Unit 的纯逻辑，依赖被替换 | host 编译 + 测试框架 | 状态机 / 阈值判断 / 队列算法 / 区间计算 / FTL mapping / GC decision / 错误分类 / 重试策略 / 调度策略 | 测试用例执行报告 |
| 2 | `COMPONENT` | 同一组件内多个 Unit 的协作行为 | host 或目标机上的组件测试桩 | Host Write Flow Control（`HostWrite → Scheduler → GC`） | 组件测试报告 |
| 3 | `INTEGRATION` | 跨组件的数据流与控制流 | 固件集成环境 | `Host Write → Queue → Scheduler → FTL → NAND simulator` | 集成测试报告 + 时序/事件记录 |
| 4 | `SIMULATOR` | 真实固件在仿真模型上的行为（含时序模型） | Firmware Simulator / FEMU 类环境 | interrupt latency、power transition、超时与调度时序 | 仿真回归记录 + 波形/日志 |
| 5 | `HARDWARE` | 只有真实硅片/控制器可观测的行为 | 真实 UFS/SSD 硬件、HIL | NAND timing、PHY configuration、DMA 实流、reset、power sequence、clock switching | 硬件测试记录 + 仪器数据 |
| 6 | `INSPECTION` | **不可执行**的静态约束：配置表 / 寄存器映射 / 常量约束 / 时序参数表 / 设计规则符合性 | 文档与代码静态检查 | 寄存器配置表、阈值常量表、状态机可达性表 | 检查记录 + 结论（`PASS/FAIL` + 依据） |
| 7 | `MANUAL` | 必须由人按步骤操作并判断的行为 | 人工台架 / 现场 | 复位后人工确认、指示灯/日志人工判读 | 人工执行记录 + 步骤与观测值 |

> **`INSPECTION` 与 `MANUAL` 的判定（99 D20 / D21）**：`INSPECTION` 只用于**不可执行**的静态约束，四项同时成立才算通过——① 被检查对象有版本号或 commit hash；② 检查项逐条列出；③ 每条给出 `PASS/FAIL` 与依据（文件路径 + 行号或表项名）；④ 检查记录已持久化。**附加要求**：必须携带**明确审批方**（`approver`）与 `DEC-nnn`（`99 D20` 不计入四项）。执行者为 `ufs-verification` 或 Human，`ufs-coding` 不得自判，结论形态为 `PASS/FAIL`。`MANUAL` 必须含"人执行的操作步骤 + 观测值 + 执行人 + 时间"。**"可执行但不想跑"的行为只能选 `MANUAL`，不得选 `INSPECTION`**；`INSPECTION` 不得作为跳过测试的通用出口。**补充约束（99 D20）**：① `INSPECTION` **不是独立的「通过等级」**；② 若该行为**存在可执行路径**，必须**同时**落到执行型等级（`UNIT` / `COMPONENT` / `INTEGRATION` / `SIMULATOR` / `HARDWARE`）；③ 无任何执行型证据时，须以 `DEC-nnn` 登记并由 Human 批准。

**硬规则**：每个行为**必须**落到七级中的至少一级；同一声明可以多级并存（如 `GC Policy → UNIT + COMPONENT`、`Interrupt Latency → SIMULATOR + HARDWARE`）。

## 9.3 决策流程

```text
Behavior
   │
   ├─ 纯逻辑、依赖可替换、无硬件副作用？ ────────────────► UNIT
   ├─ 跨多个 Unit、仍在同一组件内？ ─────────────────────► COMPONENT
   ├─ 跨组件（数据流/控制流）？ ─────────────────────────► INTEGRATION
   ├─ 依赖时序模型 / 中断延迟 / 功耗转换的仿真？ ────────► SIMULATOR
   ├─ 只有真实硅片/仪器可观测？ ─────────────────────────► HARDWARE
   ├─ 不可执行（配置表 / 常量 / 静态约束）？ ────────────► INSPECTION
   ├─ 必须人工操作与判读？ ──────────────────────────────► MANUAL
   └─ 以上皆不成立（描述不清 / 输入不足） ────────────────► BLOCKED（回 `design` 补全行为定义）
```

**读法（B01，必须按此理解）**：本树**不是 if-else 首命中链**，而是**并集筛选**——对每个行为**逐条问一遍**，命中几条就取几级（`levels[]`）；任一条都问不出结论时走**默认分支 `BLOCKED`**（不得默认取 `UNIT`）。
因此"跨组件且依赖仿真时序"的行为可以同时是 `INTEGRATION + SIMULATOR`，不因先命中前者而丢弃后者。

**规则**：

- 判定发生在 `design` 节点，产出 `verification_strategy`（§9.4）；`tweak` / `hotfix` 下在 `plan` 节点轻量补做（本册 §4.8；主文档 §4.9）。
- 一个行为可同时选择多级；**选择"更多级"必须以风险为依据，不是以"更保险"为依据**（避免成本无界增长）。
- 选定层级后，`plan` 节点必须为其排验证任务；`verify` 节点必须核对该层级的证据是否真实存在（§26.1）。

## 9.4 输出契约 `verification_strategy`

```yaml
verification_strategy:
  - { behavior_id: BEH-001-03, behavior: FlowControlDecision, levels: [UNIT, COMPONENT] }
  - { behavior_id: BEH-001-07, behavior: DMAConfiguration,    levels: [INTEGRATION] }
  - { behavior_id: BEH-001-11, behavior: NANDTiming,          levels: [HARDWARE] }
  - { behavior_id: BEH-001-12, behavior: PowerRecovery,       levels: [HARDWARE] }
```

**规则**：每行**必须**含 `behavior_id`（§9.0 定义的行为锚点）；多级行为写 `levels[]`（或拆成多行）。该结构必须写入 `test-design.md` 的 §2 Verification Strategy 与 §3 Verification Level（§25），并被 `plan` 节点消费。

## 9.5 Test Scope 判定表

**表 9.5-A：类型 → Verification Level（层级维度）**

| 类型 | Verification Level |
|---|---|
| Flow Control Logic | `UNIT` |
| Queue Algorithm | `UNIT` |
| Scheduler Decision | `UNIT` |
| State Machine | `UNIT` |
| ISR（被 ISR 调用的纯逻辑） | `UNIT`（ISR 集成路径 → `INTEGRATION`） |
| Register Access（位域 / 保留位语义） | `INTEGRATION`（不可执行时 `INSPECTION`） |
| DMA Register Programming | `INTEGRATION` |
| DMA 实流与一致性 | `SIMULATOR`（先行）→ `HARDWARE` |
| NAND PHY / 器件物理时序 | `HARDWARE` |

**表 9.5-B：类型 → 测试替身（替身维度，与上表正交）**

| 类型 | 替身 |
|---|---|
| `Register Access` | Mock |
| `Queue 未完成数查询` | Stub |
| `调度器通知` | Spy |
| 稳定外部依赖 | Stub / Fake |
| 硬件 | `SIMULATOR` / `HARDWARE`（真实组件优先） |

**维度澄清（重要）**：`Register Access → Mock` 属**测试替身维度**，不是验证层级；硬件寄存器访问在**层级维度**上仍归 `INTEGRATION` / `HARDWARE`。两列不是同一坐标系，两个维度回答不同问题，不能互相替代（§30.1 MR-7）。

## 9.6 适合 `UNIT` 的代码

```text
State Machine / Threshold Decision / Queue Management / Range Calculation
FTL Mapping Logic / GC Decision / Resource Allocation / Error Classification
Retry Policy / Scheduling Policy
```

**规则**：这些应**优先 UT + TDD**——它们是固件中行为密度最高、回归成本最低的部分。

## 9.7 更适合 Integration / Hardware Test 的代码

```text
DMA Register Programming / PHY Configuration / NAND Timing
Interrupt Latency / Power Sequence / Clock Switching / Hardware Reset
```

> **不能为了追求 `UNIT` 覆盖率而强行 Mock 所有硬件。**

**规则**：此类代码的 DoD 是「**明确测试边界 + 模拟/集成/HARDWARE 验证证据**」，而不是 `UNIT` 覆盖率。

## 9.8 Verification Level 与要求的对应示例

```text
FTL Mapping         → UNIT
GC Policy           → UNIT + COMPONENT
DMA Configuration   → INTEGRATION
NAND Timing         → HARDWARE
Interrupt Latency   → SIMULATOR + HARDWARE
```

**示例（AC 侧）**：

```text
AC: DMA transfer must complete within the required hardware timing constraint.
Verification Level: `INTEGRATION` + `HARDWARE`（而非 `UNIT`）
```

---

# 10. Verification Level × Regression L0–L5 正交映射

> 本章给出 Verification Level 与 Regression Level 的正交映射与证据下限。**它不是默认选取策略**（§30.1 MR-8）。

## 10.1 两个维度为什么必须分开

| 维度 | 问题 | 取值 | 决定者 | 何时决定 |
|---|---|---|---|---|
| **Verification Level** | 「这个行为**用什么手段**证明正确？」 | `UNIT / COMPONENT / INTEGRATION / SIMULATOR / HARDWARE / INSPECTION / MANUAL` | `ufs-test-design` | `design` 节点 |
| **Regression Level** | 「这次改动**必须回归到多大范围**？」 | `L0 / L1 / L2 / L3 / L4 / L5` | Test Design + Build Plan | `design` 给定策略，`plan` 落实到任务 |

**正交性含义**：

```text
一个 L0（只跑当前测试）的变更 → 其行为仍可能声明 HARDWARE 层级证据（一次性动作，不构成回归范围）
一个 VERIFICATION=UNIT 的行为 → 其回归范围可能高达 L3（因为它被多个子系统依赖）
```

**禁止的混淆**：用"回归跑过了"替代"该行为在正确层级被验证"；或用"`UNIT` 全绿"替代"L5 硬件回归已执行"。

## 10.2 Regression L0–L5

| Level | 名称 | 覆盖范围 |
|---|---|---|
| `L0` | 当前测试 | 本次改动直接对应的测试用例 |
| `L1` | 受影响 Unit | 与改动 Unit 有直接调用 / 数据关系的单元测试 |
| `L2` | 受影响组件 | 组件内全部单元 + 组件测试 |
| `L3` | 子系统 | 受影响子系统的集成测试 |
| `L4` | 固件级（仿真） | 仿真环境下的固件回归 |
| `L5` | 仿真 + 硬件 | 台架 / 真实器件验证 |

**规则**：

- 等级由 Test Design / Build Plan 确定；语义按 99 D19 冻结，取值如下表。
- **不设默认选取策略**（§30.1 MR-8、99 D18）：任何按 Verification Level 或改动大小自动取值的做法都是越权自算，本册与其他分册都不得采纳。
- 每个 Build Task **必须显式写入 `required_regression_level`**；`verify` 节点按该字段核对证据。
- 回归等级只能由 `plan` 节点写定、或由 Human 调整；**`ufs-coding` 不得降低**。
- 本章是 Verification Level × Regression Level 映射的**唯一持有者**；其他分册只可引用，不得自算数值。

## 10.3 正交映射（证据下限）

> 本节两张表给出「某个 Verification Level 的证据在回归阶梯上最低覆盖到哪里」，是**证据下限**，**不是默认选取策略**。具体 Regression 等级必须由 Build Task 显式写入 `required_regression_level`（§10.2）。

**正向（证据下限）**：某 Verification Level 的证据本身，最低可覆盖的回归范围

| Verification Level | 该层级证据本身覆盖的回归范围 | 最低可覆盖的 Regression Level（证据下限） | 说明 |
|---|---|---|---|
| `UNIT` | 当前 Unit | **L0 + L1** | 变更 Unit 必跑；有调用关系者进 L1 |
| `COMPONENT` | 组件内协作 | **L2** | 组件成员全部纳入 |
| `INTEGRATION` | 跨组件数据 / 控制流 | **L2–L3** | 影响面跨子系统时取 L3 |
| `SIMULATOR` | 固件级 + 时序模型 | **L4** | 仿真回归必须重跑 |
| `HARDWARE` | 真实器件行为 | **L5** | 只在真机可观测 |
| `INSPECTION` | 静态检查，无执行 | **不进入回归阶梯**；遇 `INSPECTION` 时**必须由 Human 指定回归等级，不得默认放行**（99 D20） | 责任人与节点：`ufs-verification` 在 `verify` 节点确认等级已指定、变更后已重新检查并记录版本 |
| `MANUAL` | 人工执行 | **不适用（N/A）**（按 L5 记录人工证据） | 不进入自动化回归阶梯，但证据必须入档 |

**多级行为的校验下限（不是推导）**：当一个行为有多级证据（如 `UNIT + COMPONENT`）时，取各层级**证据下限的并集上界（即取最大）**作为**校验下限**。**该值不得用于自动填充 `required_regression_level`**：字段必须由 Build Task 显式声明（`RG-1`）；声明值**低于**该下限即 `H03` `BLOCK`，**高于**即允许（可显式提高，见 `99 D18`）。

**反向**：某 Regression Level 通过时，可证明成立的最低 Verification Level

| Regression Level | 可证明成立的最低 Verification Level | 不能证明的层级 |
|---|---|---|
| `L0` | `UNIT`（仅当前用例） | COMPONENT 及以上 |
| `L1` | `UNIT`（受影响集合） | COMPONENT 及以上 |
| `L2` | `UNIT` + `COMPONENT` | INTEGRATION 及以上 |
| `L3` | `UNIT` + `COMPONENT` + `INTEGRATION` | SIMULATOR / HARDWARE |
| `L4` | 至 `SIMULATOR` | `HARDWARE` |
| `L5` | 至 `HARDWARE` | `INSPECTION` / `MANUAL`（非执行类） |

**读法**：`L5` 不覆盖 `INSPECTION` / `MANUAL`——它们不是"执行后通过"的证据类型；`INSPECTION` / `MANUAL` 不进入回归阶梯——它们不是"范围"而是"手段"。

## 10.4 选取责任

| # | 项 | 规则 |
|---|---|---|
| RG-1 | **默认选取策略** | 不设默认值（§30.1 MR-8、99 D18）。每个 Build Task 必须显式写入 `required_regression_level`；未声明即判 `NEEDS_REVISION` |
| RG-2 | **L3 / L4 的边界** | `L4` = 仿真环境回归；`L5` = 仿真 + 真实硬件回归（§30.1 MR-8） |
| RG-3 | **多级行为与单值字段的对应（校验，非推导）** | ① 降级判定**逐 `TC-*` 比较**（经 `BEH-*` 归属，§9.0）：Build Task 的 `verification_level` 低于其 `test_refs` 中任一 `TC-*` 声明的最高 `level`，即 **H03 `BLOCK`**；② `required_regression_level` **必须显式声明**（`RG-1`），§10.3 的并集上界只作**校验下限**：声明值低于下限即 `H03` `BLOCK`，高于即允许；**禁止**用该下限自动填字段。**两条比较均由 H03 实现**（分册 03 §7.3.3） |

---

# 11. AT ↔ UT 映射规则

## 11.1 禁止一对一映射

**不采用 `AC → AT → UT` 一对一映射。** 正确关系：

```text
AC
 ├── AT
 │    ├── UT
 │    ├── UT
 │    └── UT
 └── Design Constraint
      └── UT
```

## 11.2 允许 AC 1:N AT，AT 1:N UT

| 关系 | 允许 | 理由 | 例 |
|---|---|---|---|
| AC → AT | **1 : N** | AC 描述完整行为要求，AT 是验证该要求的具体场景 | `AC-001-01 → AT-001-01 正常写入 / AT-001-02 临界阻塞 / AT-001-03 恢复` |
| AT → UT | **1 : N** | 一个系统级场景需要多个内部行为共同成立 | `AT-001-02 → TC-001-02 写权限判定 / TC-001-03 阈值判定 / TC-001-04 状态转换` |
| UT → AC | **0 : 1** | 允许无 AC 的 UT（§11.3） | `TC-001-21 NULL 依赖处理` |

**硬规则**：任何工具/Hook 都**不得**假定 `AC ↔ UT` 的基数关系；追溯模型只要求"可回答"（§22），不要求"一一对应"。

## 11.3 不是所有 UT 都对应 AC

允许某些 UT 来源于 `Design Constraint / Robustness / Error Handling / Safety / Implementation Invariant`，而不直接对应 Acceptance Criteria：

```text
TC-001-21 NULL dependency handling
TC-001-22 Memory allocation failure
TC-001-23 Invalid state recovery
```

这些属于 Implementation Safety / Robustness，**不一定存在直接对应的 AC**。因此应允许 `UT → Design Requirement`，而不是强制 `UT → AC`：

```text
REQ → AC ─┬─ AT → UT
          └─ Design Constraint → UT
```

## 11.4 无 AC 的 UT 如何处置

主文档 §5.4 的规则（本册按方法论角度重申其操作面）：

| 步骤 | 要求 |
|---|---|
| 1 | 该 UT **不得丢弃** |
| 2 | **显式标注来源类型**：`Design Constraint` / `Robustness` / `Error Handling` / `Safety` / `Implementation Invariant` |
| 3 | **显式写明理由**（为什么该安全/健壮性行为必须被测） |
| 4 | **进入审查**（`ufs-document-review` 门禁，`design` / `plan` 节点） |
| 5 | **不得静默存在**，**不得反向伪造 AC** 来"补齐"追溯 |
| 6 | 该 UT 在 `verify` 节点同样需要证据（不因无 AC 而降低证据要求） |

---

# 12. Build Plan × UT Design 的交互

## 12.1 核心结论与五个影响

> **UT Design 和 Build Plan 是两个不同层次的设计。UT Design 定义「如何证明代码正确」，Build Plan 定义「如何把代码做出来」。UT Design 会影响 Build Plan，但不应该替代 Build Plan，更不能让 Build Plan 退化成「按照测试用例逐条写代码」。UT Cases 是 Build Plan 的约束输入，而不是 Task 列表。**

**不采用**把 `TC-001-01 / TC-001-02 / TC-001-03` 简单转换成 `Task 1 / Task 2 / Task 3` 的机械做法（与主文档 §4.4 一致：**不得把每个 UT case 直接转成一个 Build Task**）。

| # | 影响项 | 规则 |
|---|---|---|
| ① | **Task Boundary** | UT Design 告诉 `ufs-build-plan` 哪些行为必须实现，因此影响 Task 拆分 |
| ② | **Implementation Boundary** | 若 `Function A` 很难测试，可能要拆成 `Pure Logic + Hardware Adapter`，反向影响 Implementation Plan |
| ③ | **Interface Design** | Mock/Stub 需求可能要求 Dependency Injection / Adapter / Interface；若 UT 需要 `GC_GetLevel()`、`Queue_GetOutstanding()`，Build Plan 可能需**先完成 DI 或 Mock Interface** |
| ④ | **Implementation Order** | 状态机与依赖关系影响实现顺序：`1 Define State Model → 2 State Transition → 3 Decision Logic → 4 Integrate Queue → 5 Integrate GC → 6 Integration Test` |
| ⑤ | **Verification Task** | Build Plan 必须明确 `Implementation → UT → Regression`，而不是「Code complete」就结束 |

## 12.2 Build Plan 的三输入约束

```text
                    Build Plan
                        ↑
        ┌───────────────┼───────────────┐
Implementation Design   UT Design   Acceptance Criteria
        └───────────────┼───────────────┘
                        ↓
                   Build Plan（ufs-writing-plans）
```

| 输入 | 回答的问题 |
|---|---|
| **Acceptance Criteria** | 最终必须满足什么？ |
| **Implementation Design** | 系统准备怎么实现？ |
| **UT Design** | 实现过程中如何证明行为正确？ |

更准确地说：

> **UT Design 定义 Build Plan 的「验证约束」；Implementation Design 定义 Build Plan 的「实现约束」；Build Plan 负责把这两种约束整合成可执行的工程任务。**

## 12.3 Build Plan 被 TDD 约束，不被 TDD 改写

**规则**：

| 允许 | 禁止 |
|---|---|
| TDD 过程中发现 Task 顺序/粒度需要调整 → 更新 Build Plan 并留痕 | 以"测试需要"为由重写 Build Plan 的目标与验收范围 |
| 发现接口不可测 → 回到 `design` 反馈（§8.2） | 在 `execute` 节点静默扩大实现范围 |
| Build Plan 中的验证任务按实际 UT 集合细化 | 把 Build Plan 退化为 UT Case 的逐条翻译 |

## 12.4 UT Case 是行为约束，不是 Build Task

```yaml
task_id: IMP-001-02
design_refs:      [DES-001-02]
acceptance_refs:  [AC-001-03]
test_refs:        [TC-001-04, TC-001-05]
scope:
  files:          [src/host/flow_control.c]
  functions:      [FlowControl_UpdateState, FlowControl_GetPermission]
dependencies:     [ResourceManager, HostWrite]
verification:     [TC-001-04, TC-001-05]
```

> **Task 是实现结构；UT Case 是行为约束。**

## 12.5 Build Plan 必含字段

Build Plan 的字段采用下列**超集**；骨架与主文档 §4.4 一致，带 `★` 的是 UFS 固件必需的扩展字段。**本节与分册 02 §9.6.3 必须逐字一致**（字段名、★ 标记、注释口径）；两处冲突时以 **分册 02 §9.6.3** 为准。

```yaml
task_id:                 # 实现项 ID（`IMP-` 前缀）
title:
purpose:

design_refs:      [DES-001-02]        # 设计依据
acceptance_refs:  [AC-001-03]         # 验收依据
test_refs:        [TC-001-04]         # UT Case

scope:                                 # ★ 写入范围（H04/H05 的唯一读取字段）
  files:          [src/host/flow_control.c]     # 精确路径 / 前缀 / glob
  functions:      [FlowControl_UpdateState]     # role: candidate_implementation_point | required_interface
dependencies:     [ResourceManager, HostWrite]

implementation_steps: [ ... ]
verification:     [TC-001-04, TC-001-05]
expected_result:  [all listed tests pass, no regression]
risks:            [ ... ]
tdd:              {mode: greenfield|legacy|hardware_bound, red: [], green: [], refactor: []}
testability_constraints: []

# ★ 六个 UFS 扩展字段（分册 01 §12.5；缺任一 → H03 BLOCK）
verification_method:                  # ★ 验证方法（可执行的判定描述）

codegraph_evidence:                   # ★ 变更影响的代码事实证据
  source: codegraph
  query:
  result:
  repository:
  commit:
  timestamp:

state_machine_impact:                 # ★ 状态机影响
data_structure_impact:                # ★ 数据结构影响
concurrency_interrupt_impact:         # ★ 并发 / 中断影响
verification_level:                   # ★ 每个 Build Task 必填（§30.1 MR-6）
required_regression_level:            # ★ 每个 Build Task 必填（§30.1 MR-8）

verification_strategy_consumed: []    # ★ 本 Task 覆盖的 BEH-* 行（H03 判定已消费的依据）
non_testable_consumed: []             # ★ 本 Task 触及的 non_testable[] 项（H03 判定审批齐备的依据）
```

> **载体归属**：本节的字段集是**方法论视图**；`build-plan.md` 中 Build Task 的**唯一定义处是分册 02 §9.6.3**，两者字段名必须逐字一致。门禁 `03 H03`/`H04` 按分册 02 §9.6.3 的字段名读取——**缺任一 ★ 字段即 `BLOCK`**。

| 字段 | 说明 |
|---|---|
| `task_id / design_refs / acceptance_refs / test_refs / scope.files / scope.functions / dependencies / verification` | 规范骨架 |
| `title / purpose / implementation_steps / risks` | 与主文档 §4.4 一致 |
| `expected_result` | 该 Task 完成后的期望结果（H03/RG 判定用）；不得为 `implementation: done` |
| `tdd` | `{mode, red, green, refactor}`；`mode` ∈ `greenfield` / `legacy` / `hardware_bound` |
| `testability_constraints` | 来自 ④ 的 `item_type: testability_constraint` 约束（归 `DES-*`） |
| `codegraph_evidence` | 变更影响的代码事实证据，必填 |
| `state_machine_impact / data_structure_impact / concurrency_interrupt_impact / verification_method` | UFS 固件必需 |
| `verification_level / required_regression_level` | 每个 Build Task 必填 |
| `verification_strategy_consumed / non_testable_consumed` | H03 判定“Build Plan 已消费 `verification_strategy`”与“`non_testable[]` 审批齐备”的字段载体 |

**`verification_level` 的定义**：它是该 Build Task **必须提供的最高执行型验证层级**；该 Task 的**完整层级集合**由其 `test_refs` 指向的各 UT **各自声明的层级**承载，**不需要新增字段**。

**行为归属**：`test_refs` 中的每个 `TC-*` 经 `BEH-*`（§9.0）归属到某个行为；`verification_level` 的语义不因多级行为而改变。

## 12.6 `ufs-writing-plans` 的强制引用要求

**不修改 Superpowers 原始 Skill，而是派生 `ufs-writing-plans`。** Build Plan 必须引用：

```text
1. Design Element        2. Acceptance Criteria    3. UT Design
4. UT Case IDs           5. CodeGraph evidence     6. Implementation files
7. Dependencies          8. Verification steps
```

`ufs-writing-plans` 的逐节 I/O 契约见**分册 02**，本册不重复。

> **UT 全覆盖**：`test-design.md` 中**每一条 UT 必须被至少一个 Build Task 的 `test_refs` 引用**。存在未被任何 Task 引用的 UT ⇒ 该 Build Plan **不完整**，`ufs-build-plan` 必须补齐引用，或把该 UT 显式标记为 `deferred` 并记录理由与 Human 批准（`DEC-nnn`）。**未被引用且未标记的 UT 一律视为设计缺口。**
>
> 该检查由 **H03 Build Gate Hook 第 8 项**执行（分册 03 §7.3.3），不可豁免。

## 12.7 与 `tasks.md` 归属的关系

- `tasks.md` 是 **`plan` 节点**产出的**任务状态权威**，不是 `open` 节点的需求拆解产物；
- `plans/*.md` 承载 §12.5 的字段契约；`tasks.md` 承载任务状态闭包；
- 二者都不得由 `ufs-coding` 改写（写权限见主文档 §6.5）。

## 12.8 Test Design 与 Build Plan 的边界

`test-design.md` 定「**验证什么、用哪一级**」；`build-plan.md` 定「**怎么排、回归到哪一级**」。二者互不覆盖（99 D33）：

- 验证层级冲突时，以 `test-design.md` 的 Verification Level 为准；
- 回归范围冲突时，以 `build-plan.md` 的 `required_regression_level` 为准；
- 出现「Build Plan 降低了 Test Design 要求的层级」时，**H03 BLOCK** 并要求 Human 裁决；
- **降级判定逐 UT 比较**（UT 经 `BEH-*` 归属，§9.0）：若某 Build Task 的 `verification_level` **低于**其 `test_refs` 中任一 UT 声明的**最高层级**，即 **H03 BLOCK**。**该比较须由 H03 实现**（分册 03）。

---

# 13. phase `build`：TDD 实现纪律

## 13.1 定位与核心循环

`build` 阶段负责：**将 Design 中定义的行为转化为可执行测试和实现。**（等价表述：`RED → Implementation → GREEN → REFACTOR → Regression`；本册统一采用下式。）

```text
┌──────────┐     ┌──────────┐     ┌───────────┐
│   RED    │ ──→ │  GREEN   │ ──→ │ REFACTOR  │ ──→ 保持 GREEN ──→ 下一个行为
│ 写失败测试│     │ 最小实现 │     │ 重构/清理 │
└──────────┘     └──────────┘     └───────────┘
   确认它确实失败    确认测试通过
```

## 13.2 TDD 的定义

> **用可执行的测试，把需求中的行为定义固定下来，再让实现代码逐步逼近这个行为。**

## 13.3 为什么一定要 RED

「先写代码再写测试」与「先写测试再写代码」最终结果并不相同。**反例（先写实现）**：

```c
if (gc_active && outstanding >= threshold) { return FLOW_CONTROL; }
```

测试当然通过，但**没有证明「如果代码错误地没有执行 flow control，这个测试真的会失败」**。TDD 要求先看到 `FAIL / expected FLOW_CONTROL / actual NORMAL`，加入实现后 `PASS`——这样才证明测试**真的具有检测能力**。

> **先建立一个可观测的失败，再用最小实现消除这个失败。** 没有亲眼看到测试失败，就不能证明该测试能捕获你要实现的行为。

## 13.4 有效 RED 的规则

> **规则**：RED 必须是**可观察的行为失配**——测试必须真实运行到断言点，并产生 `expected X / actual Y` 形态的失败。

| 现象 | 是否构成有效 RED | 处理 |
|---|---|---|
| 断言失败，输出 `expected X / actual Y` | ✅ 有效 | 进入实现 |
| 测试通过（未失败） | ❌ 无效 | 检查测试是否真的在测目标行为 |
| 编译失败 / 链接失败（无 `expected/actual`） | ❌ **无效** | 先补齐被测对象骨架 / 签名，使编译通过，**再重新确认 RED** |
| 测试框架未收集到用例 / 被 skip | ❌ 无效 | 修正测试装配后重跑 |

**理由**：编译或链接失败只说明代码尚不存在，不能证明测试对被实现行为具有检测能力；只有测试真实运行到断言点并产生 `expected X / actual Y`，RED 才构成证据（99 D27）。

**Legacy 例外**：Legacy 模式下允许以 `Characterization Test` + `Baseline GREEN` 替代 RED，但**必须**在同一 Task 的 evidence 中标注替代原因。

## 13.5 RED 证据的形态

`execute` 节点必须为每个 RED 留下可核查证据（写入 TDD Evidence）：

```yaml
red:
  test:         TC-001-02
  result:       FAIL
  expected:     BLOCK
  actual:       ALLOW
  command:      <test runner 命令>
  timestamp:
  commit:
```

**硬规则**：`expected` 与 `actual` 字段不得为空；仅有"运行失败"而无 `expected/actual` 的记录，视为**RED 证据不足**，`verify` 节点必须判 `NEEDS_REVISION`。

## 13.6 TDD 解决的三个问题（对 AI Coding 尤其重要）

| # | 问题 | 没有 TDD 时的退化链 | TDD 的约束 |
|---|---|---|---|
| 1 | **防止 AI 自己定义需求** | `Requirement → AI 理解 → AI 写代码 → AI 自己认为完成` | `Requirement → AC → Test → Failure → Implementation`，测试成为**客观约束** |
| 2 | **防止 AI 过度实现** | 需求只是「retry 3 次」，AI 写成 backoff / exponential_backoff / timeout / callback / statistics / logging / dynamic configuration | GREEN 阶段只写让当前测试通过的**最小代码** |
| 3 | **防止重构破坏行为** | 重构无安全网 | **Refactoring safety net**：`已有 100 个测试 → 重构 Scheduler → 运行测试 → 98 PASS / 2 FAIL → 知道行为被破坏` |

**对固件的额外含义**（第 2 点）：

```text
代码越多 → 状态越多 → 并发关系越复杂 → 验证成本越高 → firmware risk 越高
```

## 13.7 最小实现原则

> **GREEN 阶段只写能够让当前测试通过的最小代码，禁止加入测试没有要求的功能。**

**操作判据**：新增的每个分支 / 状态 / 配置项，必须能指向一条已批准的 UT Case；否则删除或回到 `design` 变更 Test Design。

## 13.8 TDD ≠ Test Coverage

代码覆盖率 95% 不代表 TDD 做得好，因为可能是 `代码写完 → 补测试 → Coverage 95%`（**Test-after**）。TDD 强调 `Test → RED → Implementation`：

> **测试参与设计和实现过程，而不仅仅是最终验证。**

**对 AI Agent 这个区别更加重要**，因为 AI 最容易出现 `Requirement → AI 写代码 → AI 写测试 → AI 自己测试自己 → PASS`——看起来漂亮，但 **AI 写出来的测试可能只是证明 AI 自己的实现**。推荐 Workflow：

```text
ATDD / Human → Acceptance Criteria → Test Agent → RED
→ Implementation Agent → GREEN → Review Agent → Verify Agent
```

> **测试设计和实现最好不要完全由同一个 Agent 无约束地完成。**

**平台映射**：`ufs-test-design`（设计测试）→ `ufs-coding`（实现）→ `ufs-code-review`（核查）→ `ufs-verification`（验证）。其中**必须严格分离的只有两处**：代码审查者不得是代码作者（`ufs-code-review` 不与 `ufs-coding` 同实例），且验证独立于 Build 的局部成功（`ufs-verification` 不因"测试通过"而放行）。其余角色**不设全局互斥约束**——把四个角色一律强制分实例会徒增成本而无收益（主文档 §6.3）。

## 13.9 行为测试 → 函数的映射在何处建立

```text
Behavioral UT → Test Interface → Function → Test Implementation
例：TC-001-02 → FlowControl_GetPermission() → test_flow_control.c
```

| 映射环节 | 建立于 | 承担者 |
|---|---|---|
| Behavior → Test Interface（接口/文件/函数候选） | `plan` 节点 | `ufs-build-plan` |
| Test Interface → Function（最终函数） | `execute` 节点 | `ufs-coding` |
| Function → Test Implementation（`test_*.c`） | `execute` 节点 | `ufs-coding` |

**规则**：设计节点不允许出现函数级映射（§6.1）；`plan` 节点出现的是**候选映射**，`execute` 节点固化。

---

# 14. UFS Firmware TDD 五层

## 14.1 为什么必须分层

传统软件是 `Function → Unit Test`；UFS Firmware 是 `Pure Logic → UNIT + TDD` 与 `Hardware Boundary → COMPONENT / INTEGRATION / HARDWARE` 并存。因此 TDD 必须允许 Unit TDD / Component TDD / Integration Verification / Hardware Verification，**而不是所有问题都强行 Unit Test**。

> **平台铁律：分层 TDD，而不是「所有代码统一 Unit Test」。**

## 14.2 五层模型

```text
                ATDD
                 │
        Acceptance Criteria
                 │
        ┌────────▼────────┐
        │ Behavior Test / │
        │    Acceptance   │
        └────────┬────────┘
        ┌────────▼────────┐
        │ Integration Test│
        └────────┬────────┘
        ┌────────▼────────┐
        │  Component Test │
        └────────┬────────┘
        ┌────────▼────────┐
        │    Unit Test    │
        └────────┬────────┘
        ┌────────▼────────┐
        │ Firmware / HARDWARE   │
        │   Verification  │
        └─────────────────┘
```

## 14.3 统一层名与各层边界

五层统一命名为：

| 层 | 统一层名 | 边界 | 典型对象 | 例 |
|---|---|---|---|---|
| 5（最上层驱动） | **ATDD** | 定义「必须满足什么」 | Acceptance Criteria / Behavior Test | `AC-001-01` GC critical → Host Write = `BLOCK` |
| 4 | **Integration** | 跨组件、可在仿真/集成环境观察的整链路行为 | Host Write → Queue → Scheduler → FTL → NAND simulator | `Host Write 4KB / Host Write 4KB / GC Trigger / Host Write 4KB` |
| 3 | **Component** | 同一组件内跨多个 Unit 的协作 | Host Write Flow Control（`HostWrite → Scheduler → GC`） | `GC idle → ALLOW；GC active → BLOCK（受限期）；GC urgent → BLOCK；GC finished → RECOVERY` |
| 2 | **Unit** | 纯逻辑单 Unit，依赖替换 | state machine / algorithm / queue / range / threshold / retry / timeout / mapping / scheduler decision / FTL metadata / GC decision / error handling | `GC 是否应抑制 Host Write`（行为级；**不得写函数名**，函数签名见 §12.4、§13.9） |
| 1（最底层验证） | **Hardware-Firmware Verification** | 真实硬件 / 控制器 / PHY / 中断 / 功耗转换 | DMA / ISR / Register / PHY / NAND / UFS controller / Power transition | 走 `TDD → 尽可能测试可抽象行为 → Integration → Simulator → Hardware Validation` |

**边界硬规则**：

- Unit 层**必须**是纯逻辑；出现寄存器、DMA、中断即越界，应下沉为 Adapter（§8.3）；
- Component 层**不要求**纯逻辑，但要求环境可复现；
- Integration 层**允许**仿真器替代 NAND；
- Hardware-Firmware Verification 层**不可被 Unit 层替代**；
- **TDD 不意味着所有东西都必须 Unit Test。**

## 14.4 ATDD 是最上层驱动

```text
ATDD = 定义「必须满足什么」；TDD = 定义「如何一步一步把它实现出来」。

ATDD ─┬─ AC1 GC idle → Host Write 正常
      ├─ AC2 GC active → Host Write outstanding 不超过 X
      ├─ AC3 GC critical → 新 Host Write 被 throttle
      ├─ AC4 GC recovery → Host Write 自动恢复
      └─ AC5 不得影响已经 outstanding 的 request
            ↓    Unit / Component / Integration tests
```

**五层是完整模型**：`execute` 节点实际执行第 1–4 层；第 5 层 ATDD 是驱动与验收来源，不在 `execute` 内执行。

---

# 15. Greenfield TDD 与 Legacy TDD

## 15.1 Greenfield 模式

**Mode A** 适用于新模块 / 新 Feature / 新算法 / 新状态机 / 新组件：

```text
UT Design → Build Plan → RED → Implement → GREEN → REFACTOR → Regression
即 ATDD → Design → Test Interface → RED → GREEN → REFACTOR → Integration → Verify
```

**Greenfield 的最大优势：TDD 会反过来推动设计。** 若测试写起来特别困难（需初始化 15 个全局变量、启动 Scheduler、模拟 8 个寄存器、构造 20 个对象），则暴露设计耦合太严重：`Test difficult → Interface difficult → Architecture may be coupled`。

> **从零开发时，TDD 不只是测试方法，也是 Architecture Feedback。**

## 15.2 Legacy 为什么不能直接进入普通 TDD

Legacy Firmware 的旧代码可能**根本没有测试**；若强制要求「每一个修改函数都必须先建立完整 TDD」，成本极高；更危险的是 AI **不知道当前代码的真实行为**（§16.6）。

## 15.3 Legacy 正确流程与两个起点

```text
Requirement → CodeGraph Exploration → Existing Behavior Analysis → Characterization Test
→ Baseline GREEN → New Behavior Test → RED → Implementation → GREEN → REFACTOR → Regression
```

**两个 TDD 起点**：`Existing Behavior: Characterization Test → GREEN`；`New Behavior: New Test → RED → Implementation → GREEN`。与从零开发的区别：`从零开发: RED → GREEN → REFACTOR`；`Legacy: Characterize → GREEN BASELINE → RED → GREEN → REFACTOR`。

## 15.4 两种开发模式对比表

| 维度 | 从零开发 | 基于已有 UFS 仓库 |
|---|---|---|
| 起点 | 空白模块 | 已存在代码 |
| 第一件事 | 定义行为/接口 | **理解现有行为** |
| CodeGraph | 辅助设计 | **非常重要** |
| OpenViking | 设计知识 | 历史 / 规范 / 经验 |
| 第一个测试 | 新行为测试 | Characterization Test |
| 初始 RED | **是** | 不一定 |
| Baseline | 不需要 | **非常重要** |
| 正式 TDD | RED → GREEN | Baseline GREEN → RED → GREEN |
| 重构 | Green 后 | Green 后 |
| Bug Fix | 先写 reproducer | 先写 regression / characterization |
| 硬件代码 | Boundary / HIL | Boundary / HIL |
| AI 风险 | 过度实现 | **误解已有行为** |
| 最重要的能力 | 设计反馈 | **行为保护** |

## 15.5 `build` 阶段分流图

```text
Build Task ─┬─ Greenfield → Strict TDD ─────────┐
            └─ Legacy     → Characterization ───┤
                                                ▼
                       RED → GREEN → REFACTOR → Integration → Verify
```

## 15.6 REFACTOR 与 Regression 的顺序

**规则**：Legacy 与 Bug-fix 路径统一为 `... → GREEN → REFACTOR → Regression`（99 D28）。

**采纳**：

```text
... → GREEN → REFACTOR → Regression
```

**REFACTOR 完成后必须重新执行 Regression 并全绿**，不得沿用 REFACTOR 之前的回归结果。理由：只有"先重构、再回归"才能证明重构未破坏既有行为。

---

# 16. Characterization Test（单一权威定义）

> 本节给出 Characterization Test 的**单一权威定义**及其四个展开面：目的、过程、与需求的区别、与 Acceptance Test 的分工。

## 16.1 权威定义

> **Characterization Test 是在修改 Legacy 代码之前，为「该代码当前实际表现出的行为」建立的可执行基线记录。它固化的是 Existing Behavior，不是 Required Behavior；它的目的不是证明当前行为正确，而是让后续行为变化成为受控、可观察、可追溯的。**

**四个限定语缺一不可**：

| 限定语 | 含义 |
|---|---|
| **修改之前** | 必须在任何行为改动前建立并转绿 |
| **当前实际表现** | 来自运行观测 + CodeGraph，不来自文档或推测 |
| **可执行** | 必须是能跑出结果的测试，不是注释或文档 |
| **基线** | 后续新行为对比的参照；一旦建立即受 Test Contract 保护 |

## 16.2 目的与过程（第一、二处定义）

目的**不是**判断「当前行为是否正确」，而是记录**当前代码实际上做了什么**：

```text
Existing Behavior:
free block < X  AND  GC == ACTIVE  AND  queue depth > Y   → block Host Write
```

即使该行为尚未被新的需求文档描述，也可以先固定下来——这些测试证明的是「**我知道旧代码现在实际上干什么**」。

**过程**：`CodeGraph → Call Graph → Data Flow → State → Existing behavior`，然后建立 `Input → Existing Firmware → Observed Output`：

```text
GC_LEVEL = 0 / Outstanding = 10 → NORMAL
GC_LEVEL = 2 / Outstanding = 10 → BLOCK
GC_LEVEL = 3 / Outstanding = 10 → BLOCK

TC-001-09  Existing behavior: When free block > X, Host Write proceeds normally.
TC-001-10  Existing behavior: When free block < Y, Host Write is blocked.
```

（ID 按主文档 §5.1 两段式；域标签只出现在名称中。表征测试不是独立对象，统一用 `TC-` 承载，类型写在 `case_type: characterization`。）

## 16.3 与需求的区别（第三处定义）

| 维度 | Characterization Test | Acceptance Test |
|---|---|---|
| 固化对象 | **Existing Behavior** | **Required Behavior** |
| 权威来源 | 运行观测 + CodeGraph | Requirement / AC |
| 通过的含义 | 行为与基线一致 | 需求被满足 |
| 变更含义 | **Behavior Change**（须记录与批准） | 需求/设计变更 |

**硬规则**：**必须区分 `Requirement` 与 `Existing Behavior`**（§5.9）。

## 16.4 Legacy 行为变化政策（受控变化）

Characterization Test 固定的是 Existing Behavior，**而不是「永远不能改变」**。如果新需求明确要求改变行为：

```text
Existing Behavior → Characterization Test → New Requirement
→ Update Test Contract / Update Characterization Test → New Test → TDD
```

这就形成了**受控变化**：统一表述为「**更新测试契约并留痕**」，路径见 §18.2。

**判定流程**：

```text
Existing Behavior == New Requirement
    → 直接把新行为测试加入（无需改 Characterization Test）

Existing Behavior != New Requirement
    → 记录 Behavior Change（必须留痕）
    → 走 Test Contract 变更路径（§18.2）
    → Human Approval
    → 更新 Characterization Test / 新增 New Test → TDD
```

**禁止**：`ufs-coding` 偷偷修改 Characterization Test 来适配旧行为；或为了 GREEN 把基线改掉而不记录行为变化。

**不可测声明（99 D22）**：无法建立 Characterization Test 的 Legacy 代码必须**显式标记**——写入 `test-design.md` 的 `non_testable[]`，每条含 `{item_id, reason, alternative_verification_level, approver, decision_ref}`；审批方为项目架构负责人（或技术负责人），以 `DEC-nnn` 记录；缺 `approver` / `decision_ref` 即视为未批准。批准后该行为必须落到 `INSPECTION` 或 `MANUAL`；标记齐备前该豁免分支不可用。

## 16.5 Legacy 完整示例（GC Critical 限制 Host Write）

需求：GC 进入 Critical 时 Host Write 最多 4 个 outstanding request。

**① 不要马上修改。** 先 CodeGraph 探索 `HostWriteReqHandle → Call Graph → GC status → Scheduler → Outstanding counter`，找到 `GC_GetLevel() / HostQueue_GetOutstanding() / HostQueue_Throttle()`。

> 本节示例中的函数名与 C 代码属 **`execute` 节点**的 CodeGraph 探索与测试代码语境，不进入 `design` 制品（`FR-4`）。

**② 建立 Characterization Tests**：

```text
Test 1  GC = IDLE,     Outstanding = 8 → Observed: Host Write = ALLOW
Test 2  GC = ACTIVE,   Outstanding = 8 → Observed: Host Write = ALLOW
Test 3  GC = CRITICAL, Outstanding = 8 → Observed: Host Write = ALLOW     ← 旧代码可能真的允许
```

**③ 把新需求转成 RED**：

```c
TEST(gc_critical_limits_outstanding) {
    set_gc_level(GC_CRITICAL); set_outstanding(8);
    result = HostWriteReqHandle();
    ASSERT_EQ(result, BLOCK);        /* Host Write 被阻止；词表见 §7.2 */
}
```

```text
FAIL / expected BLOCK / actual ALLOW      ← 这才进入真正 TDD
```

**④ GREEN（最小代码）→ REFACTOR → Regression 全绿**：

```c
if (gc_level == GC_CRITICAL && outstanding > 4) { return BLOCK; }
```

## 16.6 对 AI Coding 的意义

AI 面对已有仓库最大的问题之一是：**它不知道当前代码的真实行为**。它可能「看代码 → 理解 → 认为行为是 A」，但在 runtime + state + interrupt + global variable + callback 共同作用下真正行为是 B。

> **所以 `CodeGraph + Characterization Test` 组合非常关键。**

## 16.7 Legacy 流程的出现顺序

```text
Requirement
  → CodeGraph Exploration
  → Existing Behavior Analysis
  → Characterization Test
  → Baseline GREEN
  → New Behavior Test → RED
  → Implementation
  → GREEN
  → REFACTOR
  → Regression
```

---

# 17. Bug-fix TDD

**传统做法**：`Debug → 找到代码 → 修改 → 测试`。**TDD 化**：

```text
Bug → Reproduce → Write regression test → RED → Root Cause Analysis → Fix → GREEN → REFACTOR → Regression
```

**规则**：

- 该 Bug 会**永久留下一个 Regression Test**，以后再也不会轻易复发；
- **Bug Fix 属于 Mode B Legacy TDD 的适用场景**（`build` 阶段分流见 §15.5）；
- **RED 必须在修复之前产生**——`Reproduce` 阶段的失败测试就是 RED（有效 RED 规则见 §13.4）；
- **Root Cause Analysis 必须在 RED 之后、Fix 之前**：`systematic-debugging` 在此优先于"直接改代码"（§24.3）；
- `hotfix` preset 下 `execute` 节点额外要求**根因消除检查**（主文档 §4.9）；
- 修复后若 Regression 出现无关用例失败 → 按 §19 四分类处理，不得顺手修无关缺陷（主文档 §4.5 禁止项）。

---

# 18. Test Contract Protection

## 18.1 禁止模式

平台必须防止：

```text
Test Failed → 修改 Expected → PASS
```

`ufs-coding` **不能**把 `Expected = BLOCK` 直接改成 `Expected = ALLOW` 来获得 `PASS`。

> **Test 是契约，不是 `ufs-coding` 为了获得 GREEN 可以随意修改的目标。**

**禁止模式清单**：

| # | 禁止模式 | 为什么 |
|---|---|---|
| 1 | 修 Expected 使测试通过 | 需求被实现方稀释（主文档 P2/P3） |
| 2 | 删测试 / 注释断言 / 加 skip | 同上，且不可追溯 |
| 3 | 放宽断言（`==` 改 `>=`、精确值改区间）而不改契约 | 检测能力被静默削弱 |
| 4 | 改测试输入使其绕过目标路径 | 覆盖率幻觉 |
| 5 | 修改 AC / Requirement 以匹配现有实现 | 主文档 §9.2 硬规则 |
| 6 | 在 `verify` 阶段回改测试以获得 `verify-pass` | 证据链造假 |

## 18.2 唯一允许的测试变更路径

```text
Test Change → Reason → Requirement / Design Change → Review → Human Approval
```

（本册采用**含 Review** 的完整路径，与主文档 §10.2 的 `execute` 阶段内决策点一致。）

**路径的四个必要条件**：

| # | 条件 | 证据 |
|---|---|---|
| 1 | **Reason** | 变更理由（为什么原契约不正确/不完整） |
| 2 | **Requirement / Design Change** | 对应的需求或设计变更记录（`AC` / `DES` ID） |
| 3 | **Review** | `ufs-document-review` 或 `ufs-code-review` 的核查结论 |
| 4 | **Human Approval** | 阻塞式人类确认（主文档 §10.1） |

**没有这四项之一 → 变更被判定为违规**，`test-contract-protection` Hook 必须阻断（主文档 §12）。

## 18.3 硬规则

> **`ufs-coding` 不得未经批准修改 Requirement、Acceptance Criteria 或 Test Contract。**

**关联规则**：

| # | 规则 | 来源 |
|---|---|---|
| TCP-1 | Coding Agent 不得改 AC / Requirement / Test Contract | 本条 |
| TCP-2 | Design 阶段 Test Case 描述行为，不绑定具体函数；Build 阶段才建立映射 | `FR-4`（§28.4） |
| TCP-3 | 测试契约不得为获取 GREEN 而修改 | 主文档 I4 |
| TCP-4 | 测试变化必须有 Requirement / Design 变化依据 | 主文档 §9.4 |
| TCP-5 | 区分 Required / Existing：Characterization Test 不得被偷偷改写 | §16.4 |

## 18.4 自动检查点

OpenCode Hooks 负责自动检查，例如：

```text
检测 Test Contract Change
   ├── 有对应 Requirement Change / Design Change / Approval → 放行（留痕）
   └── 无对应依据                                           → 阻止或要求人工确认
```

**平台映射**：`test-contract-protection` 是主文档 §12 第一版 6 个 Hook 之一；其 fail-closed 语义见分册 03。

## 18.5 什么算「测试契约变更」

| 变更类型 | 是否受保护 | 备注 |
|---|---|---|
| `Expected` 值 / 断言条件 | ✅ 受保护 | 必须走 §18.2 |
| 测试输入 / 前置条件（改变被测行为路径） | ✅ 受保护 | 必须走 §18.2 |
| 删除 / 跳过用例 | ✅ 受保护 | 必须走 §18.2 |
| `test-design.md` 中的 UT Case 定义 | ✅ 受保护 | 属 `design` 节点产物 |
| 新增加用例（不改变已有契约） | ⚠️ 允许但需落 Traceability | 须挂 AC 或 Design Constraint（§11.4） |
| REFACTOR 中的测试可读性改写（断言不变） | ⚠️ 允许 | 断言语义必须完全等价 |

---

# 19. TDD 失败处理：四分类

## 19.1 不能设计成 `Test Failed → AI Fix`

正确形态是 `Test Failure → Failure Analysis → Classification`：

```text
Test Failure → Failure Analysis → { `TEST_PROBLEM` | `CODE_PROBLEM` | `DESIGN_PROBLEM` | `ENVIRONMENT_PROBLEM` }
```

否则 `ufs-coding` 很容易进入 `Test Failed → 改代码 → Failed → 再改 → Failed → 继续改`，最后甚至出现「为了让测试通过而修改测试」。

## 19.2 四分类表

**命名规范**：第二类为 **`CODE_PROBLEM`**；`Implementation Problem` 是旧称，不作为独立分类。四分类枚举值全大写下划线，作为 `ufs-failure-analysis` 的闭集输出（99 D29）。

| 分类 | 判据 / 例子 | 必须的处理动作 | 路由 |
|---|---|---|---|
| **`TEST_PROBLEM`** | Mock 配置错误 / Test Setup 错误 / Expected Value 错误 / Test Implementation Bug | 回到 **Test Design / Test Implementation**；若需修改 Test Contract，则必须有相应依据 | `ufs-test-design` → 若属契约变更则走 §18.2 |
| **`CODE_PROBLEM`** | `Expected: BLOCK / Actual: ALLOW`，而 Design 与 Test 正确 | `ufs-coding → Debug → Fix → Test`，继续 TDD | `ufs-coding`（节点 `execute`） |
| **`DESIGN_PROBLEM`** | `UT: State A → State C`，但 Architecture 规定 `State A 只能 → State B` | **不能让 `ufs-coding` 自行决定**：`Build → Design Conflict → Design Review → Human Decision → Design Revision → Build Plan Revision → Build`（即 **Build → Design Feedback Loop**） | 停止 Build，请求 Design Review |
| **`ENVIRONMENT_PROBLEM`** | Compiler Failure / Toolchain Failure / Simulator Crash / Test Infrastructure Failure / Hardware Unavailable | **不应通过修改业务代码解决**；进入 `Infrastructure / Environment Recovery` | Infrastructure / Environment |

**重入与关闭**（与上表一一对应）：

| 分类 | 重入节点 | 关闭判据 | 关闭裁判 | 检测者 |
|---|---|---|---|---|
| `TEST_PROBLEM`（仅测试实现错） | `execute` | 修订后 RED → GREEN 通过 | **`ufs-code-review`**（**不得是改测试者**） | `ufs-coding` 或 `ufs-verification` |
| `TEST_PROBLEM`（涉契约变更） | `design`（走 §18.2） | 契约变更依据齐备 + 重新 RED | Human | `ufs-test-design` |
| `CODE_PROBLEM` | `execute` | GREEN + 按 `required_regression_level` 回归通过 | `ufs-verification` | `ufs-failure-analysis` |
| `DESIGN_PROBLEM` | 停止 Build → Design Review | Design Revision + Build Plan Revision 完成 | Human | `ufs-failure-analysis` |
| `ENVIRONMENT_PROBLEM` | **环境恢复后回到失败前节点重跑** | 原失败命令重跑通过并留痕 | 环境负责人 | 环境负责人 |

> **UT 未被引用**（Build Plan 不完整）**不属于失败四分类**：其检测者为 `ufs-build-plan`（自查）或 H03（门禁），关闭判据见 §12.6。

**关键约束**：分类发生在**纠正动作之前**；`ufs-failure-analysis` **不得直接修改源代码**，只分类与路由（主文档 §6.4）。

## 19.3 完整失败回路

```text
REGRESSION ─┬─ PASS → 关闭
            └─ FAIL → Failure Analysis
                        ├─ TEST_PROBLEM（仅测试实现错） → execute：修订测试 → 重跑 RED→GREEN
                        ├─ TEST_PROBLEM（涉契约变更）   → design：§18.2 契约变更 → 重新 RED
                        ├─ CODE_PROBLEM                → execute：Debug → Fix → GREEN + 回归
                        ├─ DESIGN_PROBLEM              → Design Review → Human → Design / Plan 修订
                        └─ ENVIRONMENT_PROBLEM         → 环境恢复 → 回到失败前节点重跑
```

重入与关闭判据见 §19.2 的重入表；`TEST_PROBLEM`（涉契约变更）**必须**走 §18.2 的测试变更路径，不得在 `execute` 直接改 Expected。

## 19.4 失败分类的判定流程

```text
Test / Regression FAIL
        │
        ▼
① 测试本身能否自证？ 能否复现？环境是否可用？   ── 否 ──► ENVIRONMENT_PROBLEM
        │ 是
        ▼
② Test 与 Design 是否一致？（Expected 是否来自已批准契约？） ── 否 ──► TEST_PROBLEM
        │ 是
        ▼
③ Design 是否自洽？（该转换/该行为在设计上是否被允许？）   ── 否 ──► DESIGN_PROBLEM
        │ 是
        ▼
④ CODE_PROBLEM → 交 `ufs-coding`，继续 TDD
```

**顺序理由**：先排除"外部不可用"，再排除"测试写错"，再排除"设计本身矛盾"，最后才认定是实现缺陷——否则 `ufs-coding` 会在错误的前提下反复改代码。

## 19.5 分类者与执行者的分离

| 角色 | 职责 | 禁止 |
|---|---|---|
| `ufs-failure-analysis` | 给出 `分类 + 证据 + 根因假设 + 置信度 + 建议动作` | 不得直接修改源代码 |
| `ufs-coding` | 仅执行 `CODE_PROBLEM` 分支的修复 | 不得自行改分类、改测试、改设计 |
| `ufs-test-design` | 处理 `TEST_PROBLEM` 中属契约定义的部分 | 不得为让实现通过而放宽契约 |
| Human | `DESIGN_PROBLEM` 的决策 | — |
| `ufs-verification` | 在 `verify` 节点核对失败是否被正确分类与关闭 | 不得把未分类失败计入 PASS |

---

# 20. Firmware 特化要点

> 本章规则的领域事实（寄存器语义、时序参数、硬件约束）由 `ufs-firmware-expert` 按需提供，且必须区分 `FACT / REFERENCE / ANALYSIS / ASSUMPTION`（主文档 §6.2、§6.4）。

## 20.1 特化汇总表

| 维度 | 规则 |
|---|---|
| **中断上下文 / 并发** | 必须考虑 ISR、Concurrent Access、Race Condition、Atomicity、Critical Section、Locking、Event Ordering（方法论第 10 项） |
| **DMA** | DMA Register Programming 属 `INTEGRATION`；DMA Resource Exhaustion 属 Error/Recovery；DMA 依赖须在 Dependency Interaction 中列出 |
| **Timing 敏感逻辑** | 必须定义 Timeout / Deadline / Timer / Retry Interval / Scheduling Timing；NAND Timing、Interrupt Latency 属 `HARDWARE`（必要时 `SIMULATOR` 先行） |
| **硬件寄存器访问** | Register Access → Mock（替身维度）；**不能为覆盖率强行 Mock 所有硬件**；硬件绑定代码只要求明确边界 + 模拟/集成/HARDWARE 验证 |
| **Adapter 模式** | `HostWriteHandler → FlowControl(Pure Logic) / NandAdapter / DmaAdapter / HardwareAdapter`；Pure Logic 走 UT+TDD，Adapter 走 `INTEGRATION` / `HARDWARE` Test |
| **Mock 纪律** | `design` 阶段即定义 Mock/Stub/Spy 归属（`GC 等级查询行为→Mock`、`队列未完成数查询行为→Stub`、`调度器通知行为→Spy`、`寄存器读取行为→Mock`）；明确区分 Mock / Stub / Fake / Spy / Real Component |
| **资源耗尽** | Memory Exhaustion / Queue Full / Buffer Exhaustion / NAND Resource Exhaustion / DMA Resource Exhaustion |
| **硬件边界** | 必须明确 `Pure Logic / Hardware Adapter / Hardware-dependent Code` 的边界 |
| **数值安全** | 关注 `> >= < <=` 与 overflow / underflow / wraparound，尤其 `uint16_t / uint32_t / counter / queue depth / LBA / length / timeout / retry count` |

## 20.2 中断上下文与并发

| 要点 | 规则 |
|---|---|
| 共享状态 | 被 ISR 与主流程共同访问的字段必须在 `test-design.md` 标注并给出保护方式 |
| 原子性 | read-modify-write 必须声明是否原子；非原子必须给出临界区 |
| 事件顺序 | 排序假设必须显式（如"Timer 先于 DMA 完成回调"）并写成用例 |
| 不可复现并发 | 无法在 `UNIT` 层稳定复现 → 提升到 `INTEGRATION` / `SIMULATOR`（§9.3） |
| Mock 边界 | ISR 通常不在 `UNIT` 内执行；`UNIT` 只验证被 ISR 调用的纯逻辑 |

## 20.3 DMA / 时序 / 寄存器

| 子项 | 归属 |
|---|---|
| DMA Register Programming | `INTEGRATION` |
| DMA 实流与一致性（cache / barrier） | `HARDWARE`（`SIMULATOR` 先行） |
| DMA descriptor 耗尽 | Error / Recovery 用例（§7.7、§7.12） |
| DMA 依赖关系 / 回调时序 | 第 8 项 Dependency Interaction / 第 11 项 Timing + 第 10 项 Concurrency |
| 纯计数/比较时序（`retry_count < MAX`） | `UNIT` |
| 依赖真实时钟推进 | `SIMULATOR` |
| 器件物理时序（NAND tPROG / tR 等） | `HARDWARE`；中断延迟为 `SIMULATOR` + `HARDWARE` |
| 寄存器读写（替身维度） | Mock（§9.5）；寄存器**语义**（位域 / 保留位 / 写 1 清零）属 `INSPECTION` 或 `INTEGRATION`；硬件绑定代码的完成判据是「边界明确 + 模拟/集成/HARDWARE 证据」，**禁止为覆盖率强行 Mock 所有硬件** |

**硬规则**：时序用例必须写明**观测时机**与**允许误差**；"立即生效"是无效表述（§5.4）。

## 20.4 Adapter 拆分与 Mock 纪律

```text
HostWriteHandler
    ├── FlowControl ── Pure Logic      → UNIT + TDD
    ├── NandAdapter      ┐
    ├── DmaAdapter       ├─ Hardware Adapter → Integration / Hardware Test
    └── HardwareAdapter  ┘

GC 等级查询行为 → Mock        队列未完成数查询行为 → Stub
调度器通知行为 → Spy          寄存器读取行为 → Mock
```

函数级映射见 §12.4（`plan`）、§13.9（`execute`）；`design` 语境不得出现函数名（`FR-4`）。

**Mock 纪律**：MK-1 每个被替换的依赖必须写明替身类型与理由；MK-2 Mock 的返回值必须来自 Input Domain / Boundary（§7.3、§7.5）；MK-3 允许 `Real Component` 时优先真实组件；MK-4 禁止在 `execute` 节点新增 `test-design.md` 未声明的 Mock。

## 20.5 资源耗尽 / 硬件边界 / 数值安全

```text
资源耗尽：Memory Exhaustion / Queue Full / Buffer Exhaustion / NAND Resource Exhaustion / DMA Resource Exhaustion
硬件边界：Pure Logic / Hardware Adapter / Hardware-dependent Code
数值安全：> >= < <= 与 overflow / underflow / wraparound
高危类型：uint16_t / uint32_t / counter / queue depth / LBA / length / timeout / retry count
```

- 每类资源 ≥ 2 条用例：**耗尽时的行为** + **恢复后的行为**；计数断言覆盖 `0` 与 `MAX`。
- 三类边界必须写入 `test-design.md`：Pure Logic → `UNIT` + TDD；Hardware Adapter → `INTEGRATION`（必要时 `SIMULATOR`）；Hardware-dependent Code → `HARDWARE` + 显式测试边界声明。
- 每个高危类型参与比较或累加的位置，至少一条边界用例；**边界集以 §25.3 第 8 节的 10 项为唯一权威超集**（本节列出的 `min / max / max+1 / 0-1` 是其子集）。

## 20.6 测试数据

测试数据的构造与管理规则如下：

| # | 规则 |
|---|---|
| TDATA-1 | 数据必须来自 Input Domain 与 Boundary 的显式取值，不得"随手凑一个"（§7.3、§7.5） |
| TDATA-2 | 每个 UT Case 的输入数据必须与 Case Matrix 行一一对应（§7.14） |
| TDATA-3 | 硬件相关数据必须标注来源：仿真模型 / 抓取波形 / 器件手册 / 合成 |
| TDATA-4 | Characterization Baseline 使用的数据须与观测时一致，变更留痕（§16） |
| TDATA-5 | 存在随机 / 遍历的用例必须固定种子并记录 |
| TDATA-6 | 测试数据不得包含真实用户数据 / 量产密钥 |
| TDATA-7 | golden data 与测试用例**同版本控制**，按 `data/<case_id>/` 存放并记录生成 commit |
| TDATA-8 | 硬件抓取数据入库前**必须脱敏**（去除序列号、密钥、客户标识），并在 `test-design.md` 登记来源与脱敏方式 |

**规则**：TDATA-1..8 是 `design` 节点 DoD 的一部分（§27.2）；其**内容完备性由 `ufs-document-review` 人工评审**，不满足即 `NEEDS_REVISION`（99 D26）。

---

# 21. UT 用例成熟度三级与节点归属

> **效力**：本章的三级成熟度模型由 [`99-共识裁定表.md`](99-共识裁定表.md) 的 `99 D32` 裁定采纳——**Level 1（行为级设计可追溯）为 MVP 必须**；**Level 2 / Level 3 只作为演进目标，不得作为任何 Hook 的门禁条件**；分册 02 的 DoD 只引用 Level 1。

UT 用例在三类节点上逐级成熟：`design` 形成行为级用例，`plan` 建立实现映射，`execute` 实例化为可执行测试。三级共用同一个 UT ID，逐级加细而**不改变行为定义**。分册 02 的 DoD 直接引用本章。

## 21.1 三级定义

| Level | 名称 | 形态 | 决定者（阶段） |
|---|---|---|---|
| **Level 1** | **Behavioral UT** | 五列形态 `ID / Category / Input / Expected / refs`（§25.3 第 7 节）；例：`TC-001-02` ／ `Boundary` ／ `free_block < Critical` ／ `BLOCK` ／ `AC-001-02`。**没有函数。**（原 `Operation` 列已撤回；例中分隔符用全角斜杠，避免与表格分隔符冲突） | `design` 节点 |
| **Level 2** | **Implementation Mapping** | `TC-001-02 → FlowControl_UpdateState() → FlowControl_GetPermission()`，建立 `UT → Interface → Function` | `plan` 节点 |
| **Level 3** | **Executable UT** | `TEST(FlowControl, CriticalBlocksWrite)`，最终建立 `REQ → AC → TC-001-02 → FlowControl_GetPermission() → test_flow_control.c → PASS` | `execute` 节点 |

> **UT Design 在 `design` 节点不能是「函数测试设计」，而应该是「行为测试设计」；函数级映射必须延迟到 `build` 阶段。**

## 21.2 节点 → 问题 → 产物对照

| phase | 节点 | 核心问题 | UT 相关产物 | 成熟度 |
|---|---|---|---|---|
| `open` | `open` | **What behavior is required?** | Acceptance Criteria | — |
| `design` | `design` | **What behaviors must be tested?** | Test Design / UT Scenario | **Level 1** |
| `build` | `plan` | **Where/how will those behaviors be implemented and tested?** | Test Mapping | **Level 2** |
| `build` | `execute` / `subagent-execute` | **Can implementation satisfy those tests?** | Executable UT + TDD | **Level 3** |
| `verify` | `verify` | **Does the implementation satisfy requirements?** | `UNIT` / `INTEGRATION` / Acceptance Result | — |
| `archive` | `archive` | **Is evidence complete and traceable?** | Traceability + Test Evidence | — |

## 21.3 成熟度升级的硬规则

| # | 规则 |
|---|---|
| ML-1 | Level 1 中出现函数名 → `ufs-document-review` 判定 `NEEDS_REVISION` |
| ML-2 | Level 2 的映射**不得改变** Level 1 的行为描述与 Expected |
| ML-3 | Level 2 的映射以 `plan` 节点 Build Task 的 **`scope.functions`** 字段为载体（§12.5） |
| ML-4 | Level 3 的实现不得出现 Level 1 未声明的行为（§13.7 最小实现） |
| ML-5 | 三级之间的追溯链必须完整：`TC-001-02` 在三级中保持同一 ID |

**门禁范围**：门禁只针对 Level 1；Level 2 / Level 3 是演进目标，不得作为任何 Hook 的门禁条件（99 D32）。

---

# 22. 追溯模型（方法论视角）

## 22.1 Traceability Graph

```text
REQ → AC → AT → DESIGN → TEST DESIGN → TC（七级验证层级）
    → BUILD TASK → CODE → TEST RESULT → VERIFICATION EVIDENCE

关联关系：REQ → AC → DESIGN ─┬─→ TC ──┐
                                        │          ├→ IMPLEMENTATION ← BUILD TASK
                                        ↓          │
                                   IMPLEMENTATION → CODE → TEST RESULT
```

**Test Case 只有一个前缀 `TC-`**，验证层级由该用例的 `level` 属性承载（`UNIT` / `COMPONENT` / `INTEGRATION` / `SIMULATOR` / `HARDWARE` / `INSPECTION` / `MANUAL`，主文档 §5.1.3）。历史上按用例类型区分的 `UT-`（单元）/`IT-`（集成）已并入 `TC-`，属**历史别名**（主文档 §5.1.1 表 N3）。图中"层级"不是另一个维度，用例类型也不再是独立维度。

**与主文档 §5.3 的关系**：主文档完整脊柱为 `REQ → Capability → Story → AC → Scenario → Engineering Boundary → Design → Implementation → Test → Evidence → Archive`；本图是其**方法论投影**（突出 Test Design 与验证层级这一环）。

## 22.2 机器可读形态

```yaml
requirement: REQ-001
acceptance:        [AC-001-01]
scenario:          [SC-001-01]
acceptance_tests:  [AT-001-01]
design:            [DES-001-01]
test_cases:        [TC-001-01, TC-001-02]
implementation_items: [IMP-001-01]
implementation:
  files:           [src/flow_control.c]
  functions:       [FlowControl_UpdateState]
verification:
  - TC-001-01: PASS
  - TC-001-02: PASS
  - AT-001-01: PASS
```

这样最后可以回答 **「这个需求到底有没有被验证？」**，而不是仅仅"AI 说代码写完了"。

> **ID 规范**：一律两段式 `PREFIX-STORY-SEQ`；域标签只出现在名称中。`BUILD-` 前缀作废，实现项一律用 `IMP-`；`CHG-` 不属 ID 体系（主文档 §5.1）。

## 22.3 必须链接什么

- 每个 Test 都应能追溯 `Test → Acceptance Criteria → Requirement`（示例：`TC-001-04 → AC-001-03 → REQ-001`）；
- Scenario 必须可追溯：`SC → AC`（实例化哪条验收标准）与 `SC → AT`（被哪些验收测试实现）；
- 也能回答反向问题：「**这个 UT 是为了哪个需求？**」；
- Build Plan Task 必须携带 **`design_refs` / `acceptance_refs` / `test_refs` / `scope.files` / `scope.functions` / `verification`**（字段名逐字引用 §12.5；唯一权威为分册 02 §9.6.3）。

## 22.4 无 AC 的 UT

```text
REQ → AC ─┬─ AT → UT
          └─ Design Constraint → UT
```

**不能丢弃，也不能强行绑 AC**；来源类别：`Design Constraint / Robustness / Error Handling / Safety / Implementation Invariant`。处置规则见 §11.4（六步）。

## 22.5 ID 约定

> **唯一权威 = 主文档 §5.1.1 的五张命名空间子表。** 下表是本册的**完整镜像**，只作阅读便利；本册不得独立增删前缀或改变段数。

**单段集（对象没有 Story 维度）**

| 对象 | 形态 | 产生节点 |
|---|---|---|
| Requirement | `REQ-<SEQ>` | Stage 0 |
| Decision | `DEC-<SEQ>` | Stage 0 / Human |
| Assumption | `ASM-<SEQ>` | Stage 0 |
| Epic | `EPIC-<SEQ>` | Stage 0 |
| Capability | `CAP-<SEQ>` | Stage 0 |
| Story | `STORY-<SEQ>` | Stage 0 |

**两段集（`PREFIX-STORY-SEQ`）**

| 对象 | 形态 | 产生节点 |
|---|---|---|
| Acceptance Criteria | `AC-<STORY>-<SEQ>` | Stage 0 |
| Scenario | `SC-<STORY>-<SEQ>` | Stage 0 |
| Acceptance Test | `AT-<STORY>-<SEQ>` | `open` |
| Behavior | `BEH-<STORY>-<SEQ>` | `design`（行为清单；全链引用锚点） |
| Design Item | `DES-<STORY>-<SEQ>` | `design` |
| Test Case | `TC-<STORY>-<SEQ>`（层级由 `level` 属性承载） | `design`（行为级）→ `plan`（映射级）→ `execute`（可执行级） |
| Implementation Item | `IMP-<STORY>-<SEQ>` | `plan` |
| Review Record | `RVW-<STORY>-<SEQ>` | `review` |
| Review Finding | `REV-<STORY>-<SEQ>` | `review` |
| Evidence | `EVD-<STORY>-<SEQ>` | `execute` / `verify` |

> **两段式 `PREFIX-STORY-SEQ`**：域标签（`FC`、`ST` 等）**只允许出现在名称中**，不出现在 ID 中，因为 ID 必须可被 Hook 机器解析（主文档 §5.1）。
> **历史别名**：`UT-` / `IT-` 是 `TC-` 在 `UNIT` / `INTEGRATION` 层级的别名，`CHAR-` 是 `TC-` 在 `case_type: characterization` 下的别名；**新产物统一用 `TC-`**（主文档 §5.1.1 表 N3）。
> **非对象编号**：本册的 `FR-*` / `SYS-*` / `SR-*` / `ACR-*` / `TD-*` / `TDATA-*` / `ML-*` / `RG-*` / `TCP-*` / `MK-*` / `MR-*` 是规则与本册裁定编号，**不是**对象 ID，不得出现在追溯主干（主文档 §5.1.1 表 N4）。

## 22.6 追溯的最低要求

```text
Code Change → STORY → AC → DES
Test        → AC
Evidence    → TEST → AC
```

任何代码、设计或测试无法关联 Story / AC，都应**进入审查**，而不是默认视为合理工作。

---

# 23. Human-in-the-Loop / Human Gate

> 本节的 Gate 清单是**方法论侧的必要条件**；完整的节点级 Gate 清单见**主文档 §10.2**，本册不重复。

## 23.1 推荐 Gate 链

**不应该让所有步骤都需要人工。** 推荐 Gate：

```text
open → ★Human Approval → design → ★Human Approval → plan
     → ★Human Approval → execute → verify → ★Human Acceptance → archive
```

| 必须人工审查 | 可自动化 |
|---|---|
| Acceptance Criteria / Architecture / Behavior / Test Boundary | Run UT / Run Regression / Collect Logs |
| Error-Recovery / Hardware Behavior / Build Plan | Generate Traceability / Format Code |

## 23.2 Test Design 的 Human Gate

Test Design 实际上是在定义「我们认为这个 Feature 什么情况下算正确」，因此**必须保留 Human Gate**：

```text
ufs-design → ufs-test-design → UT Design → Review Agent → ★Human Approval → plan
```

**尤其是 `Boundary behavior / Error behavior / Recovery behavior / Timeout / Resource exhaustion / Concurrency`，不能让 AI 自己悄悄决定。**

## 23.3 方法论侧 Gate 点表

| # | Gate | 触发条件 | 决策内容（Human 批什么） | 拒绝后路径 | 关联规则 |
|---|---|---|---|---|---|
| G-M1 | Story Freeze（Stage 0） | Stage 0-b Challenge 完成，准备离开 Stage 0 | Story 边界 / Scope / AC / Scenario / 关键架构边界 | 回 Stage 0-a 修订 Story / AC 后重新 Challenge | §5.1、§5.5；主文档 §10.3 |
| G-M2 | AC 批准（`open`） | `open` 节点完成 intake 与镜像产物 | AC / AT 清单是否可验收 | 回 Stage 0（AC 不可验收）或 `open` 重做镜像产物 | §5 |
| G-M3 | **验证策略批准**（`design`） | `design` 节点 Step 2 产出 `test-design.md` | Verification Level / Boundary / Error / Recovery / Mock 策略 | `design` 返工（回 `design` Step 1 / Step 2）；若发现 AC 不可验证 → 走 §26.4 的「AC 无法覆盖 → Stage 0」 | §9、§23.2 |
| G-M4 | **Build Plan 批准**（`plan`） | `plan` 节点产出 `plans/*.md` 与 `tasks.md` | Build Task 拆分 / UT 映射 / Regression 等级 | 回 `plan` 重排；若属需求缺陷 → `preset-escalate` 或回 Stage 0 | §12 |
| G-M5 | 阶段内决策点（`execute`） | Test Contract 变更 / Scope 变更 / 预设升级条件成立 | 是否批准该变更 | 保持原契约继续 `execute`；不得自行实施变更 | §18.2；主文档 §10.1 |
| G-M6 | 验收（`verify`） | `verify` 节点产出结论并请求验收 | 是否接受 `READY_FOR_HUMAN_ACCEPTANCE` | `verify-fail` → `build`（§26.4） | §26 |
| G-M7 | 最终决策（`archive`） | 归档条件 7 项全部满足 | 是否归档 | `archive-reopen` → 回 `verify` / `build` | §26.3；主文档 §4.8 |

## 23.4 决策点协议要点

- **决策点是阻塞点**：必须暂停，等待用户明确选择后才能继续；不得用推荐规则、默认值、历史偏好或"用户应该会同意"的推断代替当前确认。
- 用户明确选择前，不得写入对应状态字段、执行对应分支操作或自动继续下一阶段；无法列出真实选项时（缺少事实/路径），说明缺什么并请求补充，**不编造答案**。
- **对方法论的影响**：AC 变更、Verification Level 降级、Test Contract 变更、Legacy「不可测」声明——四者都是**阻塞式决策点**。

---

# 24. Superpowers 定位与 `ufs-tdd`

## 24.1 分层定位

```text
Comet       → Lifecycle / Stage Orchestration        ATDD        → Behavior Contract
Test Design → Verification Design                    Superpowers → Engineering Method
TDD         → Implementation Discipline              CodeGraph   → Code Facts
```

> **Comet 决定「什么时候做什么」；ATDD 决定「做出来必须满足什么」；Superpowers 决定「`ufs-coding` 应该怎样把它实现出来」；CodeGraph/OpenViking 决定「Agent 实现时应该知道什么」。**

## 24.2 采用的 Skill 清单

**底层通用 Skill（采用为底层）**：`brainstorming` / `writing-plans` / `executing-plans` / `test-driven-development` / `systematic-debugging` / `requesting-code-review` / `receiving-code-review` / **`verification-before-completion`** / **`subagent-driven-development`** / **`dispatching-parallel-agents`**。

| Skill | 在方法论中的角色 | 备注 |
|---|---|---|
| `writing-plans` | 计划方法基座 | **必须特化为 `ufs-writing-plans`**（§12.7） |
| `test-driven-development` | TDD 方法基座 | **采用为底层，必须经 `ufs-tdd` 特化后使用** |
| `systematic-debugging` | 根因分析 | 对 SSD/UFS 固件，根因分析优先于直接改代码（§19） |
| `requesting-code-review` / `receiving-code-review` | 评审请求与接收 | UFS 侧特化为 `ufs-code-review` |
| **`verification-before-completion`** | 完成前必须取得证据 | 名称以此为准 |
| **`subagent-driven-development`** / **`dispatching-parallel-agents`** | `subagent-execute` 派发与多 Agent 并行 | 须与主文档 I2（只有 `ufs-main` 持生命周期）兼容 |

**UFS 特化 Skill（派生，不覆盖社区原始 Skill）**：`ufs-writing-plans / ufs-tdd / ufs-code-review`。调试能力由 stock `systematic-debugging` 承担，由 ⑥ `ufs-tdd` 在需要时调用；本册不另立调试 Skill，也不另立失败分析 Skill——失败分类由 `ufs-failure-analysis` **Agent** 承担（§19.5）。逐 Skill 的 I/O 契约见**分册 02**；节点挂载见主文档 §7.3。

## 24.3 为什么不能照搬 stock TDD

Superpowers 强调 `RED → GREEN → REFACTOR`，其 TDD Skill 原则为 `No production code without a failing test first.`。但对 UFS/SSD embedded firmware **不能机械地要求「所有代码 → 先写 Unit Test → 再写 Firmware」**，因为存在大量 `Hardware abstraction / Interrupt / DMA / NAND interface / Controller register / RTOS-scheduler / ISR / boot flow / low-level memory / timing-sensitive code`。

```text
             ATDD → Acceptance Criteria
                      │
             ┌────────┴────────┐
        可测试逻辑          硬件相关
             │                 │
            TDD         Simulation / Mock
             └────────┬────────┘
                      ↓
                 Integration → Firmware Verify
```

> **Superpowers 提供 TDD 方法论，但必须做 Embedded Firmware TDD Adaptation。**

## 24.4 `ufs-tdd` 必须增加的四种模式

| # | 模式 | 内容 |
|---|---|---|
| 1 | **Greenfield 模式** | 允许 Strict TDD（Test-first） |
| 2 | **Legacy 模式** | 允许 Characterization Test，先建立 Baseline，然后才进入 `RED → GREEN → REFACTOR` |
| 3 | **Hardware-bound 模式** | `Unit Test → Component Test → Simulator → HIL / Hardware`，而不是强行要求所有代码 Unit TDD |
| 4 | **ATDD Traceability** | 每个测试都应能追溯 `Test → Acceptance Criteria → Requirement` |

**保留的核心思想**：`RED → Verify RED → GREEN → Verify GREEN → REFACTOR`。

## 24.5 Skill 处置的落地口径

| 议题 | 落地口径 |
|---|---|
| stock `test-driven-development` | **采用为底层，并必须经 `ufs-tdd` 叠加四种模式后才可执行** |
| 验证 Skill 的名称 | 以 **`verification-before-completion`** 为准 |
| 协同 Skill | **`subagent-driven-development`**、**`dispatching-parallel-agents`** 纳入清单；使用时须服从主文档 I2（只有 `ufs-main` 持生命周期） |

## 24.6 与平台铁律的关系

```text
stock TDD 原则：No production code without a failing test first.
平台铁律      ：No new behavior without executable evidence.
```

**关系**：`ufs-tdd` 在**可自动化纯逻辑**上执行 stock 原则（RED 必须先失败）；在**硬件绑定 / Legacy** 上用平台铁律的等效证据替代（模拟 / 集成 / HARDWARE 证据 / Baseline）。**铁律是上位规则**，stock 原则是它在"可自动化逻辑"分支上的具体化。

---

# 25. Design 阶段正式产物：`test-design.md`

## 25.1 位置与地位

`design` 阶段不应只产出 `design.md`，而应增加验证契约产物：

```text
<superpowersRoot>/specs/          # 物理根由 pathBase 决定（主文档 §8.2 唯一权威）
├── <Canonical Design Doc: *.md>  # 技术设计权威（design-doc）
└── test-design.md       ★  ← 验证契约权威，必须成为 build 阶段 TDD 的输入
```

> **不要照“design/”建目录**：本设计**不新建第四个根**，`design` 阶段产物与同阶段原生产物**同根**——`<superpowersRoot>/specs/`（见主文档 §8.3）。

**平台映射**（主文档 §4.3、§8.3）：`test-design.md` 的权威所有者是 **`design` 节点**，写入者为 `ufs-test-design`，位于 `<superpowersRoot>/specs/`（即 `docs/superpowers/specs/`）。

## 25.2 权威 16 节清单（99 D30）

```text
 1. Test Scope             2. Verification Strategy   3. Verification Level
 4. Unit Boundary          5. Observable Behavior     6. Test Scenarios
 7. UT Case Matrix         8. Boundary Analysis       9. State Transition
10. Error / Recovery      11. Dependency Interaction 12. Mock / Stub Strategy
13. Testability Analysis  14. Characterization Tests 15. Requirement Traceability
16. Coverage / Exit Criteria (design 部分)
```

> 该节名同时是 `sections[]` 的登记名（分册 02 的 schema 与之一致，99 D30）。

## 25.3 各节内容契约

| § | 节 | 内容契约 | 必填 |
|---|---|---|---|
| 1 | **Test Scope** | 哪些逻辑需要 UT？哪些不适合 UT？哪些进入 Component / Integration / Simulator / Hardware / Inspection / Manual？（含 §9.5 判定表） | ✅ |
| 2 | **Verification Strategy** | 行为 → **验证层级**的总策略；说明为何不使用更高验证层级 | ✅ |
| 3 | **Verification Level** | 验证层级取值列表（`verification_strategy`，§9.4）；**每个 `BEH-*` 至少一行，不得有空缺** | ✅ |
| 4 | **Unit Boundary** | 明确的 test object **行为边界**（如 `Unit: Flow Control`），使 `ufs-coding` 知道「一个 Unit → 一个测试边界」。**必须用行为名，不得写函数名**（`FR-4`；函数级映射见 §12.4、§13.9） | ✅ |
| 5 | **Observable Behavior** | 行为空间（`ALLOW / BLOCK / STATE CHANGE / ERROR / RECOVERY`）+ 行为空间表（§7.2） | ✅ |
| 6 | **Test Scenarios** | Behavioral UT Scenario 清单（Level 1），Given/When/Then，含 Scenario ID | ✅ |
| 7 | **UT Case Matrix** | **最核心**：行为空间覆盖矩阵（ID / Category / Input / Expected / refs）；含并发、时序、资源耗尽行 | ✅ |
| 8 | **Boundary Analysis** | `0 / 1 / threshold-1 / threshold / threshold+1 / MAX / overflow / underflow / invalid state / unexpected transition`；对 `uint16_t / uint32_t / counter / queue depth / LBA / length / timeout / retry count` 尤其必需 | ✅ |
| 9 | **State Transition** | 合法转换 + **非法转换** + State Transition Coverage | ✅ |
| 10 | **Error / Recovery** | `Error→Retry / Error→Fatal / Retry→Success / Retry→Timeout / Recovery→Resume` | ✅ |
| 11 | **Dependency Interaction** | 依赖清单 + 交互断言（调用发生 / 参数 / 次数） | ✅ |
| 12 | **Mock / Stub Strategy** | 每个依赖的替身归属（Mock/Stub/Fake/Spy/Real）+ 理由 | ✅ |
| 13 | **Testability Analysis** | 耦合点、Adapter 划分，以及**不可测声明块 `non_testable[]`**（字段名与五字段契约见分册 02 §8.6）：`item_id` / `reason` / `alternative_verification_level`（只能 `INSPECTION` 或 `MANUAL`）/ `approver` / `decision_ref`。**无不可测项时必须写 `non_testable: []`，不得省略该键**（`99 D22`；`MR-9`） | ✅ |
| 14 | **Characterization Tests** | Legacy 模式下必填：Baseline 清单与观测值；Greenfield 填"不适用" | ✅ |
| 15 | **Requirement Traceability** | `Requirement → Acceptance Criteria → Design Element → UT Case → Implementation → Verification` | ✅ |
| 16 | **Coverage / Exit Criteria (design 部分)** | `design` 阶段部分的退出判据（§27.1）+ 覆盖率作为指标而非唯一判据的声明。**硬规则：该节不得出现非 `design` 阶段可判定的条件**（如"UT 可自动执行""UT PASS"） | ✅ |

**门禁范围**：H02 只校验**文件存在与章节存在**；**内容完备性由人工评审**（`ufs-document-review`），不由 Hook 判定。

## 25.4 章节构成

早先的 8 个部分（Test Scope / Unit Boundary / UT Case Matrix / Boundary & Corner Cases / Error-Recovery Cases / Mock-Stub Design / Test Traceability / UT Exit Criteria）全部被 16 节包含，不再保留。**`test-design.md` 一律按 16 节组织。**

## 25.5 与其他产物的关系

```text
design.md（技术决策权威）  ──┐
                            ├──► test-design.md（验证契约权威）──► plans/*.md ──► tasks.md
AC / AT（行为契约权威）    ──┘
```

| 产物 | 权威所有者 | 消费方 |
|---|---|---|
| `design.md` | `design` 节点（`ufs-design`） | `ufs-test-design`、`ufs-build-plan` |
| `test-design.md` | `design` 节点（`ufs-test-design`） | `ufs-build-plan`（§12.2）、`ufs-verification`（§26） |
| `plans/*.md` / `tasks.md` | `plan` 节点（`ufs-build-plan`） | `ufs-coding` |

> `test-design.md` 的 Skill 包装与结构化 schema 见**分册 02**（`ufs-test-design` 规范），本册只定义其内容契约。该产物在 Comet Output Schema 中的槽位尚未建立，门禁方式见 §30.2 MR-11。

---

# 26. Verify 与 Archive 的方法论判据

> 本节只写**方法论侧**的判据；节点契约、12 问、归档 7 条件见主文档 §4.7、§4.8，本册不重复。

## 26.1 Verify 不只是 `UNIT` PASS

Verify 应该验证整个 Requirement：`UNIT → COMPONENT → INTEGRATION → SIMULATOR → HARDWARE → Acceptance Test`。**具体采用哪些层级，由 `design` 节点的 Test Design 决定**（§9）。

**方法论判据**：`ufs-verification` 必须按 `test-design.md` 的 `verification_strategy` **逐行核对证据是否真实存在**：

| 核对项 | 通过条件 | 不通过结论 |
|---|---|---|
| 层级覆盖（Verification Level 覆盖） | 每个行为声明的**验证层级**都有对应证据 | `NEEDS_REVISION` |
| 证据可信 —— 执行型（`UNIT` / `COMPONENT` / `INTEGRATION` / `SIMULATOR` / `HARDWARE`） | 证据含**命令 / 环境 / 版本 / `expected`-`actual`** | `NEEDS_REVISION` |
| 证据可信 —— `INSPECTION` | 证据含**被检查对象版本（commit / hash）/ 检查项清单 / 逐条 `PASS\|FAIL` + 依据 / 已持久化**（§9.2 MR-4 四项） | `NEEDS_REVISION` |
| 证据可信 —— `MANUAL` | 证据含**人执行的操作步骤 / 观测值 / 执行人 / 时间** | `NEEDS_REVISION` |
| 验证层级不得降级 | 声明的 `HARDWARE` 不能用 `UNIT` 结果替代 | `BLOCKED` |
| 回归等级达标 | 每个 Build Task 的 `required_regression_level` 已执行（§10.3） | `NEEDS_REVISION` |
| 失败已分类关闭 | 所有失败均有四分类结论（§19） | `NEEDS_REVISION` |
| AC 全覆盖 | 每个 AC 至少一条 AT 证据 | `BLOCKED` |
| UT 全覆盖 | 每条 UT 至少被一个 Build Task 引用（或已标记 `deferred` + 批准） | `NEEDS_REVISION` |

## 26.2 不使用 UT 的行为如何验收

| Level | 可接受的验收证据（字段逐项引用 §26.1，不弱化） |
|---|---|
| `UNIT` / `COMPONENT` | 执行型证据：**命令 / 环境 / 版本 / `expected`-`actual`**（§26.1 第 2 行） |
| `INTEGRATION` | 集成测试报告 + 事件 / 时序记录 + **命令 / 环境 / 版本 / `expected`-`actual`**（同上） |
| `SIMULATOR` | 仿真回归记录 + 日志 / 波形 + **命令 / 环境 / 版本 / `expected`-`actual`**（同上） |
| `HARDWARE` | 台架测试记录 + 仪器数据 + 器件 / 固件版本 + **命令 / 环境 / `expected`-`actual`**（同上） |
| `INSPECTION` | **被检查对象版本（commit / hash）/ 检查项清单 / 逐条 `PASS`\|`FAIL` + 依据 / 已持久化**（§26.1 第 3 行，四项齐备） |
| `MANUAL` | **人执行的操作步骤 / 观测值 / 执行人 / 时间**（§26.1 第 4 行，四项齐备） |

> **本节不另立证据字段**：上表是 §26.1 分层证据要求在各验证层级上的投影。二者冲突时以 **§26.1 为准**。

**硬规则**：任何层级都**不得以"没有 UT"为由免于证据**（平台铁律 §2.1/P9）。

## 26.3 Archive 的方法论判据

归档的核心不是生成文档，而是确认：**需求是否有完整的验证证据。**

```text
Requirement → Acceptance Criteria → Acceptance Test → Design → Test Design
→ UT → Build Task → Code → Test Result → Verification Evidence
```

归档前 Hook 自动检查 `REQ → AC → AT → TEST → CODE → RESULT` 是否完整（主文档 §12 的 `pre-close` Hook）。

> **归档 = 行为契约（AC/AT）与验证契约（`test-design.md`）之间的每一行都有一条已执行、已留痕、可复现的证据。**

## 26.4 回流的方法论含义

| 触发 | 回流路径 | 检测者（谁触发） | 方法论含义 |
|---|---|---|---|
| `verify-fail` | `verify` → `build` | `ufs-verification` | 证据链不完整或行为不满足 → 回实现 |
| `DESIGN_PROBLEM` | `build` → Design Review → Human → Design Revision | `ufs-failure-analysis`（分类） | 验证契约与设计冲突，不能由实现方消解 |
| AC 无法覆盖 | `open` / `design` → Stage 0 | `ufs-test-design`（在 `design` 发现 AC 不可验证）或 `ufs-document-review`（门禁） | 需求本身不完整 → 重做 Challenge（**不得静默改写 AC**） |
| Test Contract 变更 | 阶段内决策点 | `ufs-coding` 提出；`ufs-document-review` / `ufs-code-review` 核查 | 必须有 Requirement / Design 变更依据（§18.2） |

---

# 27. Exit Criteria / Definition of Done

## 27.1 `design` 阶段的 UT 设计完成条件

`design` 阶段只产出 **Level 1 行为级用例**（§21.1），因此其完成条件**只包含该阶段可判定的项**：

```text
[ ] 所有 P0/P1 acceptance behavior 在 `test-design.md` §3 的 `verification_strategy` 中**各有一行**，且其 `BEH-*` 至少被一个 Build Task 的 `test_refs` 覆盖（§9、§12.6）
[ ] Boundary / Error / Recovery 路径已设计（§7.5、§7.7、§7.12）
[ ] Mock / Stub 已定义（§7.9）
[ ] 每条 UT 为 Level 1 形态：只有行为与 Expected，无函数名（§21.1、§21.3）
[ ] 每条 UT 有 ID 与 refs（`acceptance_refs` 或 `design_constraint`）
```

> **Coverage 可以是指标，但不能作为唯一完成条件。**
>
> **唯一判定点**：「验证意图」不设独立判据，也不在 `design`/`verify` 两处各判一次。它的可判定形态就是上面第 1 项（`verification_strategy` 每个 `BEH-*` 一行 + 被 `test_refs` 覆盖），**判定点为 `plan` 节点自查 + `H03` 门禁**（`BLOCK`）；`verify` 阶段只在 §26.1「层级覆盖」中复核证据是否存在，不重复判定意图本身。

**优先级判定（逐字引用 `99 D23`；`99 D25` 补结构化字段）**：每条 AC 必须且只能有一个结构化字段 `priority: P0|P1|P2`——`P0` = 缺失即无法验收、阻塞归档：数据丢失 / 损坏、不可恢复错误、安全或掉电一致性风险、量产阻塞；`P1` = 不阻塞归档但缺失必须记为 **Known Issue**：用户可见功能不满足 AC，或性能 / 时序不达标且可通过重试 / 复位恢复；`P2` = 内部质量（可维护性、日志、错误码、性能微调），不影响 AC 判定。三档**互斥且穷尽**；**无标注的 AC 不得进入 Freeze**；`P0` 行为必须有 `UNIT` 或更高层级的验证证据（不可执行的静态约束按 `INSPECTION`）。

> **边界**：UT 的**可自动执行**与**执行通过**不属于本阶段——它们是 `execute` 阶段的完成条件（§27.1.1）。

### 27.1.1 `execute` 阶段的 UT 完成条件

```text
[ ] RED 证据齐备：`expected` 与 `actual` 均非空（§13.5）
[ ] 所有 UT 可自动执行
[ ] 所有 UT 用例 PASS
[ ] 回归按该 Build Task 的 `required_regression_level` 执行（§10.2）
```

> 声明为 `INSPECTION` / `MANUAL` 层级的行为**不要求「可自动执行」**，其完成条件按 §9.2 的判定式与证据要求评估（99 D20 / D21）。

**`plan` 阶段的完整性条件**：每条 UT 至少被一个 Build Task 的 `test_refs` 引用（§12.6）——由 `plan` 节点自查，并由 H03 门禁复核。

## 27.2 Design 阶段的 DoD

| # | 条件 |
|---|---|
| 1 | `test-design.md` 16 节齐全（§25.3） |
| 2 | 每个已设计行为有 Verification Level（§9.2 硬规则） |
| 3 | Behavioral UT 为 Level 1 形态，**无函数名**（§21） |
| 4 | Testability Analysis 已产出，不可测项有替代验证层级（§8.4） |
| 5 | Legacy 模式下 Characterization Baseline 计划已定义（§16） |
| 6 | Traceability 可回答正/反向问题（§22.3） |
| 7 | Human 已批准验证策略（**§23.1 G-M3**） |

## 27.3 Verify / Archive 层完成条件

| # | 条件 | 钩子 |
|---|---|---|
| V1 | Build Task 是否存在 Design Ref / **Acceptance Ref 或来源类型标注**（§11.4 的 `Design Constraint` / `Robustness` / `Error Handling` / `Safety` / `Implementation Invariant`）/ Test Ref | `H12` |
| V2 | UT Design 是否存在、Build Plan 是否批准 | `H12` |
| V3 | Test Contract Change 是否有对应 Requirement Change / Design Change / Approval | `test-contract-protection` |
| V4 | **归档前** `REQ → AC → AT → TEST → CODE → RESULT` 是否完整 | `pre-close` |

> 无 AC 的 UT 以**来源类型标注**替代 `Acceptance Ref`（§11.4），**不降低证据要求**。

> **权威归属**：Verify 侧的判据**唯一权威是 §26.1 的九条核对项**。V1–V4 是这九条在"节点/钩子"视角下的投影，不构成第二套清单：
> V1 → §26.1「UT 全覆盖」+「层级覆盖」；V2 → §26.1「回归等级达标」的前提（Build Plan 已批准）；V3 → §28.5 `FR-5` / §18.2（不在九条内，属 Test Contract 保护）；V4 → §26.1「AC 全覆盖」。二者冲突时以 **§26.1** 为准。

## 27.4 Coverage 的定位

- Coverage 是**指标**，可用于发现"行为空间漏测"；
- Coverage **不得**作为唯一完成条件（主文档 N9）；
- **行为空间覆盖**（§7.14 的 Category 列）优先于**代码行覆盖**；
- **不设覆盖率阈值**：覆盖率只作观测指标，不得作为任何门禁的通过条件、归档必要条件，也不得写入任何 Skill 的 Exit Criteria（99 D24）；
- DoD 为**行为 ↔ 证据对齐**：每个 P0 / P1 行为都有对应层级的验证证据。

---

# 28. 五条正式规则

五条正式规则 `FR-1..FR-5` 的规范文本如下，措辞不得改写。

**编号（R2）**：五条正式规则全书统一记为 **`FR-1` … `FR-5`**（Formal Rules），**禁止裸用 "Rule N"**；分册 02 的 Skill 侧规则记为 `SR-*`，跨 Skill 体系级规则记为 `SYS-*`（主文档 §5.1.2）。本册 §28 是 `FR-1..5` 的**唯一权威文本**。

**强制方式**：`FR-*` 是**规则层声明**，**不逐条绑定 Hook**；其可机器检查的部分已分别落到 **H02 / H03 / H08 / H12 / H13**（见分册 03 §7.5 强制承诺对照表），其余部分由人工评审承担。

## 28.1 FR-1 — Acceptance Traceability

> **一个 Acceptance Criteria 可以对应多个 Acceptance Test，一个 Acceptance Test 可以对应多个 UT；UT 也可以来源于 Design Constraint、Robustness 等内部质量要求。**

## 28.2 FR-2 — Verification Level

> **所有需求都必须具有适当的 Verification Strategy，但不是所有代码都必须进行 Unit Test。**

（术语归一说明：判定环节的规范术语为 `Verification Level`；本条基线文本使用 `Verification Strategy`，指同一判定环节的产出。两者在本册中均合法：`Verification Level` 指层级取值，`Verification Strategy` 指层级选择的总体策略。）

## 28.3 FR-3 — Legacy TDD

> **Legacy Firmware 必须优先建立 Characterization Baseline，再进入新行为的 RED → GREEN → REFACTOR。**

## 28.4 FR-4 — Implementation Independence

> **Design 阶段 Test Case 描述行为，不绑定具体函数；Build 阶段才建立 Behavioral Test → Interface → Function 的实现映射。**

## 28.5 FR-5 — Controlled Failure Loop

> **Test Failure 必须进行分类处理；Coding Agent 不得未经批准修改 Requirement、Acceptance Criteria 或 Test Contract 来获得 GREEN。**

## 28.6 术语口径

`FR-2` 使用 `Verification Strategy` 指**层级选择的总体策略**；本册其余章节使用 `Verification Level` 指**层级取值本身**。二者不冲突。

## 28.7 规则编号与层级关系

三套编号不得同号，禁止裸用 "Rule N"：

| 前缀 | 名称 | 归属 | 内容 |
|---|---|---|---|
| **`FR-1` … `FR-5`** | 五条正式规则（Formal Rules） | **本册 §28（唯一权威文本）** | `FR-1` Acceptance Traceability / `FR-2` Verification Level / `FR-3` Legacy TDD / `FR-4` Implementation Independence / `FR-5` Controlled Failure Loop |
| **`SR-1` … `SR-7`** | Skill 侧附加规则（Skill Rules） | 分册 02，各 Skill 的 Hard Rules | 见分册 02 |
| **`SYS-1` … `SYS-7`** | 跨 Skill 体系级硬规则 | 分册 02 §3 | 见分册 02 |

**裁定**（[`99-共识裁定表.md`](99-共识裁定表.md) `99 D14`）：

1. `FR-1..FR-5` 是**正式规则层**；`SR-1..SR-7`、`SYS-1..SYS-7` 是其**执行细则**，不与之并列，也不另立第三层。
2. 冲突消解顺序固定为 **`FR-*` → `SYS-*` → `SR-*` → Skill Steps**（上位优先）；**只在同一层级内部**，才按"更具体者优先"处理。
3. "可机器检查者优先"**不是冲突消解顺序**，只是实现顺序。
4. P7（Test-First Design Principle）与 P8（Legacy Characterization Principle）**不占用 `FR-*` 编号**（正式规则固定为五条）；二者作为平台设计原则生效。

---

# 29. 端到端方法论链条

## 29.1 全链条图

```text
USER STORY → phase open → Acceptance Criteria → Acceptance Test → phase design
    │
    ├── Implementation Design ─┐
    └── Test Design ───────────┤  Verification Level / Behavioral UT / Testability
                               ▼
                        node plan（Design + UT + CodeGraph）
                               ▼
                        phase build
                  ┌────────────┴────────────┐
              Greenfield                  Legacy
                  │                  Characterization
                  └────────────┬────────────┘
                               ▼
        RED → IMPLEMENTATION → GREEN → REFACTOR → REGRESSION
                               ▼
                        phase verify（UT / Integration / Acceptance）
                               ▼
                        phase archive → Evidence + Traceability
```

## 29.2 各环节一句话定义

| 环节 | 一句话定义 | 环节 | 一句话定义 |
|---|---|---|---|
| Comet | 生命周期与阶段编排 | ATDD | 系统行为契约 |
| Acceptance Test | 系统级可执行验证 | Test Design | 内部行为与验证策略设计 |
| UT | 实现行为验证 | TDD | 实现纪律 |
| Characterization Test | Legacy 行为保护 | CodeGraph | 代码事实与结构上下文 |
| OpenViking | 企业知识与历史经验 | Superpowers | 工程方法 Skill |

**最终定义**：

> **Requirement defines what must happen. Acceptance Test proves the system behavior. Design defines how the behavior is structured. Test Design defines what internal behavior must be verified. Build Plan defines what must be changed. TDD drives implementation. Verification provides evidence. Traceability proves completeness.**

## 29.3 五个基本问题的结论

| # | 问题 | 结论 |
|---|---|---|
| 1 | AT 与 UT 如何映射？ | 一个 AC 可以对应多个 AT、多个 UT；**不要强制一对一**（§11） |
| 2 | 哪些代码需要 UT？ | `ufs-test-design` 决定验证层级，**不强制全部 UT**（§9） |
| 3 | Legacy 怎么进入 TDD？ | Characterization Test → Baseline GREEN → New Test RED（§15、§16） |
| 4 | UT 与函数如何关联？ | `design` 阶段不绑定函数，`build` 阶段建立 `UT → Interface → Function`（§21） |
| 5 | Test Failure 怎么处理？ | 建立 `TEST_PROBLEM` / `CODE_PROBLEM` / `DESIGN_PROBLEM` / `ENVIRONMENT_PROBLEM` 四分类及反馈环（§19） |

> 这 5 点确定后，方法论提升为 **`Requirement → Acceptance → Design → Test Design → Plan → TDD → Verification → Evidence`** 的 AI-assisted Embedded Firmware Development Methodology。

---

# 30. 方法论裁定

本章是本册的裁定索引。**本册裁定统一使用 `MR-` 前缀**，与全局裁定表 [`99-共识裁定表.md`](99-共识裁定表.md) 的 `D##` 编号区分；凡全局已裁定的议题，本册只落执行口径并标注来源。

**历史编号 → 现编号对照**：

| 旧编号 | 现编号 | 关系 |
|---|---|---|
| `D-1` | `MR-1` | 一对一 |
| `D-2` | `MR-2` | 一对一 |
| `D-3` | `MR-3` | 一对一 |
| `D-4` | `MR-4` | 一对一 |
| `D-5` | `MR-5` | 一对一 |
| `D-6` | `MR-6` | 一对一 |
| `D-7` | `MR-7` | 一对一 |
| `D-8` | `MR-8` | 一对一 |
| `D-9` | `MR-9` | 一对一 |
| `D-10` | `MR-10` | 一对一 |
| `X-1`（旧 §30.2） | `MR-8` | **并入**（`MR-8` 吸收旧 `D-8` 与 `X-1` 两条） |
| `X-2`（旧 §30.2） | `MR-9` | **并入**（`MR-9` 吸收旧 `D-9` 与 `X-2` 两条） |
| `X-3`（旧 §30.2） | `MR-11` | 一对一 |
| `X-4`（旧 §30.2） | `MR-12` | 一对一 |
| —（本轮新增） | `MR-13` | 无历史编号（与 Comet 版本适配，新识别） |

> **映射是函数，不是单射**：`MR-*` 是新编号空间，一个 `MR-*` 可以吸收多个旧编号（见"关系"列的**并入**）。任何旧编号都能唯一解析到一个 `MR-*`；反向不唯一，**不得据旧编号断言两条现行裁定**。
> **全覆盖**：`MR-1`…`MR-13` 全部有落点（`MR-13` 无历史编号）。`99-共识裁定表.md` 中残留的 `01 §30.1 D-#` 引用按本表解析；**新引用一律写 `MR-#`**。

## 30.1 本册裁定（MR-1 … MR-10）

| # | 议题 | 裁定 | 全局来源 |
|---|---|---|---|
| MR-1 | P0 / P1 分级 | **逐字引用 `99 D23`（全局唯一权威），不得另行改写**：**P0** = 缺失即无法验收、**阻塞归档**：数据丢失 / 损坏、不可恢复错误、安全或掉电一致性风险、量产阻塞；**P1** = **不阻塞归档**但缺失必须记为 **Known Issue**：用户可见功能不满足 AC，或性能 / 时序不达标且可通过重试 / 复位恢复；**P2** = 内部质量（可维护性、日志、错误码、性能微调），不影响 AC 判定。三档**互斥且穷尽**；每条 AC 必须且只能有一个 `priority: P0\|P1\|P2` 标注，无标注不得进入 Freeze；P0 行为必须有 `UNIT` 或更高层级的验证证据（不可执行的静态约束按 `INSPECTION`） | 99 D23、99 D25 |
| MR-2 | 测试数据 | 采用 **TDATA-1..8**（§20.6）：TDATA-1..6 为最小纪律；**TDATA-7** golden data 与测试用例同版本控制、按 `data/<case_id>/` 存放并记录生成 commit；**TDATA-8** 硬件抓取数据入库前必须脱敏（序列号、密钥、客户标识）并在 `test-design.md` 登记来源与脱敏方式 | 99 D26 |
| MR-3 | 覆盖率阈值 | **不设覆盖率阈值**。覆盖率只作观测指标，不得作为任何门禁的通过条件、不得作为归档必要条件，也不得写入任何 Skill 的 Exit Criteria。DoD 改为**行为 ↔ 证据对齐**：每个 P0 / P1 行为都有对应层级的验证证据 | 99 D24 |
| MR-4 | `INSPECTION` 与 `MANUAL` 的语义 | `INSPECTION` 只用于**不可执行**的静态约束，通过判定为**四项同时成立（逐字引用 `99 D20`，不得改写）**：① 被检查对象有版本号或 commit hash；② 检查项被逐条列出；③ 每条给出 `PASS/FAIL` 与依据（文件路径 + 行号或表项名）；④ 检查记录已持久化。**附加要求**：必须携带**明确审批方**（`approver`）与 `DEC-nnn`（`99 D20` 不计入四项）。执行者为 `ufs-verification` 或 Human，`ufs-coding` 不得自判，结论形态为 `PASS/FAIL`。`MANUAL` 必须含"人执行的操作步骤 + 观测值 + 执行人 + 时间"。**补充约束**：① `INSPECTION` 不是独立的「通过等级」；② 若该行为存在可执行路径，必须同时落到执行型等级（`UNIT` / `COMPONENT` / `INTEGRATION` / `SIMULATOR` / `HARDWARE`）；③ 无任何执行型证据时，须以 `DEC-nnn` 登记并由 Human 批准。"可执行但不想跑"的行为只能选 `MANUAL`，不得选 `INSPECTION` | 99 D20、99 D21 |
| MR-5 | 规则编号与层级 | `FR-1..FR-5` 是**正式规则层**；`SR-1..SR-7`、`SYS-1..SYS-7` 是其**执行细则**，不与其并列，也不另立第三层。冲突消解顺序固定为 **`FR-*` → `SYS-*` → `SR-*` → Skill Steps**（上位优先）；**只在同一层级内部**才按"更具体者优先"。"可机器检查者优先"不是消解顺序，只是实现顺序。P7 / P8 不占用 `FR-*` 编号 | 99 D14 |
| MR-6 | `tweak` / `hotfix` 下 Verification Level 的判定位置 | 在 `plan` 节点补做，由 `ufs-build-plan` 为每个 Build Task 写入 `verification_level` 与 `required_regression_level`，并产出 `build-plan.md` **第 17 节 Minimal Validation Design** | **本册裁定**（落点：主文档 §4.9；分册 02 §9.6.2 第 17 节 / §9.8 Step 0）。`99` 未为该议题单列全局裁定——**原引 `99 D40` 已更正**（`D40` 裁的是 `ufs-challenge` 在 `tweak` 下的裁剪粒度） |
| MR-7 | `Register Access` 的归属 | 替身维度用 Mock；验证层级维度归 `INTEGRATION` / `HARDWARE`，两者并存不互斥 | 99 D13 |
| MR-8 | Regression 等级的语义与默认 | `L0` 当前测试 / `L1` 受影响 Unit / `L2` 受影响组件 / `L3` 子系统集成 / `L4` 固件级仿真回归 / `L5` 仿真 + 硬件回归。**不设默认**：等级一律由 `plan` 节点显式声明 `required_regression_level`，禁止按 Verification Level 或改动大小自动推导；缺该字段的 Build Task 视为不完整；`ufs-coding` 不得降低等级 | 99 D18、99 D19 |
| MR-9 | Legacy 不可测声明与行为变更 | 不可测项写入 `test-design.md` 的 `non_testable[]`，每条含 `{item_id, reason, alternative_verification_level, approver, decision_ref}`；审批方为项目架构负责人（或技术负责人），以 `DEC-nnn` 记录；缺 `approver` / `decision_ref` 即视为未批准。批准后该行为必须落到 `INSPECTION` 或 `MANUAL`。Legacy 行为变更必须记录 Behavior Change 并更新测试契约后留痕 | 99 D22 |
| MR-10 | 产物位置与 Test Design / Build Plan 的边界 | Canonical Design Doc 是技术设计的唯一权威，`test-design.md` 是验证契约的唯一权威，路径按全局裁定冻结。`test-design.md` 定"验证什么、用哪一级"；`build-plan.md` 定"怎么排、回归到哪一级"；二者互不覆盖，出现 Build Plan 降低 Test Design 要求的层级时 **H03 BLOCK** 并要求 Human 裁决 | 99 D03、99 D33 |

## 30.2 跨册与平台依赖（MR-11 … MR-13）

| # | 依赖 | 本册执行口径 | 全局来源 |
|---|---|---|---|
| MR-11 | 新产物在 Comet Output Schema 中的槽位 | 扩展前，`test-design.md` / `exploration-report.md` 等产物以"文件存在 + 人工审查"作为门禁依据，不依赖 `artifact-structured` 校验；schema 登记格式与 `sections[]` 对齐要求按全局裁定执行 | 99 D01、99 D10 |
| MR-12 | Evidence 的持久化 | **第一层（Comet 原生事实）**：`comet.review.v1` / `comet.verify.v1` / `comet.archive.v1` 的 `artifacts` 为空数组，其判定依据是**运行时从真实文件推导的 evidence**；**不存在** `review.json` / `verification.json` 这类产物文件。**第二层（本设计新增）**：审计副本落盘到 `comet-artifacts/evidence/<change>/{review,verify}/**` 并纳入版本控制；副本是审计副本，不是 Comet 原生产物 | 99 D02、99 D07、99 D44 |
| MR-13 | 与 Comet 具体版本的适配 | 本册方法论在架构冻结后映射到目标 Comet 版本；映射完成前不改动本册的规则语义 | 主文档 §13 |

**文档结束。**

配套分册：[00 总体设计](00-总体设计-V2.0.md) ·
[02 Skill 规范](02-Skill规范.md) ·
[03 Comet 实现设计](03-Comet实现设计-节点特化·Plugin·Hook.md) ·
[04 Stage 0](04-Stage0-需求分解与Challenge.md)

