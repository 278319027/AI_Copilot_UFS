# AI 辅助 UFS/SSD 固件开发平台 · Skill 规范
**分册编号：02**
**版本：V1.0（对齐总体设计 `00-总体设计-V2.0.md`）**
**状态：Design Baseline（Skill 契约层）**
**定位：定义 8 个 Comet 企业 Skill 的输入输出、硬规则、失败契约与门禁，不重述方法论（归分册 01）与节点实现（归分册 03）**

---
# 0. 本册说明
## 0.1 本册的地位与边界

本册是 Skill 契约层分册，是 [`01-方法论-ATDD与测试设计.md`](01-方法论-ATDD与测试设计.md) 的**契约化产物**：分册 01 回答"行为怎么定义、怎么验证、怎么实现"，本册回答"**每个 Skill 的输入、输出、硬规则、失败契约与门禁是什么**"。

| 本册**拥有** | 本册**不拥有**（归属） |
|---|---|
| 8 个 Skill 的 Purpose / Comet Stage / Trigger / Inputs / Outputs | ATDD、UT Design、TDD、Verification 的工程方法论（分册 01） |
| 每个 Skill 的 Steps、枚举与矩阵、Hard Rules、Forbidden Behaviours | Comet 节点特化、Plugin、Hook 的实现（分册 03） |
| 每个 Skill 的 Failure Contract、Agent Responsibilities、Tool Usage | Stage 0 的执行细节与 freeze 记录格式（分册 04） |
| Human Gate、Definition of Done、Relationships、Final Principle | Agent 的 System Prompt 全文（分册 03） |
| Skill 级与体系级硬规则、结构化输出要求、调用矩阵 | 追溯图的存储实现（分册 03 与附录 C） |
**硬约束**：本册任何内容与总体设计冲突时，**先改总体设计，再改本册**（总体设计 §0.1）。本册不得引入总体设计未定义的新阶段名、新节点名或新 Agent 名。
## 0.2 与总体设计的分工：本册不重复什么

为避免与本册目标的重复计数，以下内容**只在本册引用、不重述**：

| 内容 | 只引用 | 总体设计位置 |
|---|---|---|
| 五阶段常量与八节点契约 / Output Schema | `phase=5`、`node=8` | 总体设计 §2.1、§2.3 |
| 迁移表与 preset 路由 | — | 总体设计 §2.2、§2.4 |
| 13 个 Agent 名册、权限矩阵、四个审查/验证职能职责划分 | — | 总体设计 §6.1、§6.2、§6.5、§6.3 |
| 节点挂载总表（目标/输入/产物/guard/Human Gate） | — | 总体设计 §4.0–§4.9 |
| 产物所有者表 / 失败四分类与路由 / Story Freeze 阻断条件 / 统一 ID 对象表 | — | 总体设计 §8.2、§9.3、§10.3、§5.1 |
本册在需要时以"见总体设计 §X"的交叉引用代替转述；对分册 01 一律以**章节名**引用（如"分册 01《UT Design 方法论 · Boundary Analysis》"），不复制其推导。
## 0.3 参考资料
本册的设计依据集中在下列文档。

| 文档 | 用途 |
|---|---|
| [`00-总体设计-V2.0.md`](00-总体设计-V2.0.md) | 契约基准：阶段与节点、Agent 名册、产物位置、追溯模型 |
| `Comet + ATDD + UT Design_skills.txt` | 企业 Skill 规范的原始素材 |
| [`01-方法论-ATDD与测试设计.md`](01-方法论-ATDD与测试设计.md) | 工程方法论：行为定义、验证分级、UT 设计、TDD、失败分类 |
| `.opencode/skills/prd-split/SKILL.md` | 已实现的 `prd-split` Skill |
| `docs/grill-me-atdd-challenge-template.md` | `ufs-challenge` 的规范化素材 |
| `.agents/skills/requesting-code-review/SKILL.md` | `ufs-code-review` 的特化对象 |

**引用口径**：正文以 `§X.Y` 交叉引用总体设计与各分册。`ufs-verification` 在参考素材中没有成文规范，其完整契约由本册第 12 章直接定义。对方法论本身（为什么这样设计测试）的论述归分册 01，本册不重述。
## 0.4 术语基线

本册**强制使用**下列术语，不得混用：

| 维度 | 合法术语 | 禁止/废弃表述 |
|---|---|---|
| 阶段 | **五阶段 `open / design / build / verify / archive`**（`phase=5`） | 自造的"第 6 阶段"表述、任何自造阶段名 |
| 节点 | **八节点 `open / design / plan / execute / subagent-execute / review / verify / archive`**（`node=8`） | 把 `plan` 叫"阶段"；把 `archive` 叫旧称 |
| 归档 | **`archive` 阶段 / `archive` 节点** | 源文档的旧称（已废弃） |
| 工程调查 | `design` 节点 **Step 0**（`ufs-exploration`） | 把"工程调查"叫 `open` 阶段 |
| Build Plan | **`plan` 节点** | "Build Plan 阶段" |
| Verification Level | **全大写七级 `UNIT / COMPONENT / INTEGRATION / SIMULATOR / HARDWARE / INSPECTION / MANUAL`**（总体设计 §5.1.3） | 用 `UT` 表示层级；`Test Level Decision` |
| Test Case | **统一前缀 `TC-<Story>-<Seq>`**；验证层级由 `level` 承载（`UNIT` / `COMPONENT` / `INTEGRATION` / `SIMULATOR` / `HARDWARE` / `INSPECTION` / `MANUAL`），用例类型由 `case_type` 承载（如 `state_sequence` / `characterization`） | 按用例类型另起前缀（`UT-` / `CT-` / `IT-` / `CHAR-` 均为历史别名或废弃形式）；把 `UT` 当 Verification Level 名 |
| Regression Level | 命名与正交映射**引用分册 01 §10**（唯一持有者） | 本册自算数值或另起一套命名 |
| 规则编号 | `FR-1..FR-5`（分册 01 §28）、`SR-1..SR-7`（本册各 Skill Hard Rules）、`SYS-1..SYS-7`（本册 §3） | 裸用 `Rule N`；三套编号混用（总体设计 §5.1.2） |
| **失败动作 vs 状态值** | **`BLOCK`** = Hook/门禁的**失败动作**（结果码）；**`BLOCKED`** = **状态值**（`comet.verify.v1.result` 三态之一、失败分类的路由阻塞态） | 用 `BLOCKED` 充当 Hook 失败动作；用 `BLOCK` 充当状态值；`Block` / `BLOCKED` 作动词混用 |
| **失败分类第二类** | **`CODE_PROBLEM`**（全大写下划线，闭集） | `Implementation Problem`（旧称，已撤回） |
| **`DESIGN_PROBLEM` vs `DESIGN_BLOCKER`** | **两个不同对象，不得互换**：`DESIGN_PROBLEM` = TDD 失败四分类之一（失败的**原因**，路由 Design Review）；`DESIGN_BLOCKER` = `design` 节点发现**需求错误/不完整**时的**停止信号**（路由回 Stage 0） | 用 `DESIGN_PROBLEM` 指需求错误；用 `DESIGN_BLOCKER` 指失败分类；`Design Problem` 大小写变体 |
| **Stage 0 子阶段** | **`0-a` / `0-b`**（半角数字 + 连字符 + 小写字母） | `0a` / `0-A` / `Stage 0a` / `0.a` 等变体 |
| **册别指代** | **`主文档`** = `00`；**`本册`** = 当前册 | `主册`、`本卷`、`本设计`（作册别指代时） |
| **替身顺序** | 固定 **`Mock / Stub / Fake / Spy / Real`**（首现与枚举处一律按此序） | `Stub / Mock`、`Spy / Fake` 等反序 |
| **来源类型值**（无 AC 的 `TC-*`） | 固定闭集 **`Design Constraint / Robustness / Error Handling / Safety / Implementation Invariant`** | 自造来源名；用 `Other` 兜底 |
| **`TEST_PROBLEM` 的处置方** | **`④ ufs-test-design`** | `Test Owner`（未定义的旧称） |
| **Skill 章编号 vs Agent vs 节点** | **`①`–`⑧` 只指 Skill 章**（如 `⑥` = Skill 章 `ufs-tdd`）；**Agent 一律写名**（`ufs-coding`）；**节点一律写小写名**（`execute`）。禁止写 `⑥ execute` 或 `build（⑥）`（G32） | 用编号指 Agent/节点；用 Agent 名指节点 |
| **两层 evidence** | **`第一层（Comet 原生事实）`** / **`第二层（审计副本）`** | `副本`、`归档副本`、`evidence 副本` 等混称 |
| **五层 vs 七级** | TDD 的**五层**（`Unit / Component / Integration / Hardware-Firmware Verification / ATDD`）与 **Verification Level 七级**是两套切分 | 混称两者；互称子集；把 `UT` 当层级名 |
**13 个 Agent 名册**（本册只能使用这些名字；旧名册如 Main Developer Agent / Exploration Agent / Review Agent 已作废）：

| 层 | Agent |
|---|---|
| Stage 0 前置（2，Comet phase 之外） | `ufs-requirements`、`ufs-challenge` |
| 编排（1） | `ufs-main` |
| 执行（5） | `ufs-exploration`、`ufs-design`、`ufs-test-design`、`ufs-build-plan`、`ufs-coding` |
| 审查（3） | `ufs-document-review`、`ufs-code-review`、`ufs-verification` |
| 专家（2，按需） | `ufs-firmware-expert`、`ufs-failure-analysis` |
**说明**：总体设计 §6.1 标题写"名册总览（11 + 2）"，其中 11 = 编排 1 + 执行 5 + 审查 3 + 专家 2，另加 Stage 0 前置 2。本册按总体设计 §4.0 与 §7.3 的节点表引用全部 13 个。
## 0.5 本册章节层级约定

参考规范的章节层级不统一。本册统一为下述约定，并作为全书唯一口径：

| 层级 | 用途 | 示例 |
|---|---|---|
| `#` 一级 | 本册**章**（Chapter），全局连续编号 | `# 5. Skill ① prd-split` |
| `##` 二级 | 18 节模板槽位或章内小节，章内编号 | `## 5.4 Trigger 触发` |
| `###` 三级 | 槽位内子项 | `### 5.8.1 Step 1 …` |
即：**同一语义层级只用一种标题级别**；"单级"指每个 Skill 的 18 个槽位一律处于 `##`，不再出现源文档 `##`/`#` 混排。

---
# 1. 声明、去重与 ID 约定
## 1.1 被取代的源表述

| 被取代的表述 | 取代为 | 理由 |
|---|---|---|
| "冻结五个核心 Skill" | **8 个 Skill** | 对齐 Comet `review` 节点与 Stage 0 两个前置 Skill |
| "Company Skills 只有 5 个" | **Stage 0 前置 2 + Comet 内 6** | 同上 |
| 把 `plan` 当作独立阶段 | **phase=5 / node=8 双轨** | 对齐 Comet Workflow Node |
| 把 `archive` 称作前一阶段名 | **`archive` 阶段 / `archive` 节点** | 对齐 Comet `PHASES` 常量 |
| `ufs-verification` 无规范 | **本册第 12 章定义其契约** | 五个 Skill 的闭环缺最后一环 |

## 1.2 源稿去重结论
参考稿中 UFS Test Design、UFS Writing Plans、UFS TDD 各存在两份副本，规范正文逐字一致，差异仅在正文之外的过渡文字，未影响任何规则、枚举或表格。本设计取后副本为唯一版本，三份规范各只呈现一个版本。

## 1.3 ID 约定

> **唯一权威 = 主文档 §5.1.1 的五张命名空间子表**（单段集 N1 / 两段集 N2 / 历史别名集 N3 / 规则与事项命名空间集 N4 / 局部命名空间排除集 N5）。本节只补充"本册产物的历史前缀如何归一"，**不得**独立增删前缀或改变段数。

**问题**：历史产物中 7 种前缀并存：`AT-FC-001`、`UT-FC-001`、`UT-ST-001`、`IT-FC-001`、`TESTABILITY-FC-001`、`TEST-DESIGN-FC-001`、`VERIFY-FC-001`。

**统一规则**：对象 ID 一律为 `<前缀>-<序号>`（单段）或 `<前缀>-<Story 号>-<序号>`（两段）；域标签（`FC`、`ST` 等）**只允许出现在名称（title）中**，不出现在 ID 中。理由：ID 必须可被 Hook 机器解析，域标签是自由文本（主文档 §5.1）。

| 历史前缀（已废弃） | 规范形式 | 对象 | 产生位置（节点） | 备注 |
|---|---|---|---|---|
| `REQ-FC-001` | `REQ-001` | Requirement | Stage 0 | 单段集 |
| `DEC-FC-001` | `DEC-001` | Decision | Stage 0 / Human | 单段集 |
| `ASM-FC-001` | `ASM-001` | Assumption | Stage 0 | 单段集 |
| `EPIC-FC-001` | `EPIC-001` | Epic | Stage 0 | 单段集 |
| — | `CAP-001` | Capability | Stage 0 | 单段集 |
| `STORY-FC-001` | `STORY-001` | Story | Stage 0 | 单段集 |
| `AC-FC-001` | `AC-001-01` | Acceptance Criteria | Stage 0 | Story 号 + 序号 |
| `SC-FC-001` | `SC-001-01` | Scenario | Stage 0 | 同上 |
| `AT-FC-001` | `AT-001-01` | Acceptance Test | `open` | 去域标签 |
| `DESIGN-FC-001` | `DES-001-01` | Design Item | `design` | 去域标签 |
| `TEST-DESIGN-FC-001` | `DES-001-01`（`item_type: test_design`） | Test Design Item | `design` | 归入 Design Item，类型在字段中区分 |
| `TESTABILITY-FC-001` | `DES-001-01`（`item_type: testability_constraint`） | Testability Constraint | `design` | 归入 Design Item |
| `UT-FC-001` | `TC-001-01`（`level: UNIT`） | Unit Test Case | `design`（行为级）→ `plan`（映射级）→ `execute`（可执行级） | `UT-` 为 `TC-` 的历史别名 |
| `UT-ST-001` | `TC-001-01`（`case_type: state_sequence`） | State Sequence Test | 同上 | 类型在字段中区分 |
| `IT-FC-001` | `TC-001-08`（`level: INTEGRATION`） | Integration Test Case | 同上 | `IT-` 为 `TC-` 的历史别名 |
| `CHAR-FC-001` | `TC-001-09`（`case_type: characterization`） | Characterization Test | 同上 | 表征测试不是独立对象，归入 Test Case |
| `BUILD-FC-002` | `IMP-001-02` | Implementation Item / Build Task | `plan` | 用 `IMP`；源 `BUILD` 为废弃别名 |
| `EVD-FC-001` | `EVD-001-01` | Evidence | `execute` / `verify` | 去域标签 |
| `VERIFY-FC-001` | `EVD-001-01`（`evidence_type: verification`） | Verification Evidence | `verify` | 归入 Evidence |
| — | `RVW-001-01` | Review Record（一轮审查的记录） | `review` | 承载 `comet.review.v1.review_id`（本册 §11.6） |
| — | `REV-001-01` | Review Finding（`findings[].id`） | `review` | 承载 `comet.review.v1.findings[].id` 与 `blockers[]` |
| `CHG-FC-001` | **无 ID**（变更以 change 名标识） | Change | — | 主文档 §5.1 废弃形式表：`CHG-` 不属 ID 体系 |

**硬规则**：

1. 同一 Story 下，序号从 `01` 连续编号，**不得跳号复用**；
2. 跨 Story 引用时使用完整 ID（`AC-001-01`），**不得只写 `AC-01`**；
3. 域标签（`FC`/`ST`）只能出现在 `title` / `name` 字段，例如 `title: "Host Write Flow Control（FC）"`；
4. `BUILD-`、`CHG-` 作为 ID 前缀**已废弃**（主文档 §5.1 废弃形式表）；若历史产物仍使用，Hook 在迁移期接受，但新产物一律 `IMP-` / 无 ID；
5. Challenge 的 Finding ID 使用**局部命名空间** `BLOCK-`/`WARN-`/`Q-`，**永不进入** `REQ→…→EVD` 主干（主文档 §5.1.1 表 N5；见第 6 章 §6.9）；
6. `TESTABILITY-` / `TEST-DESIGN-` / `VERIFY-` **不是对象**，是属性，归入所属 `DES-` / `TC-` / `EVD-`（主文档 §5.1）；
7. 本册的规则编号 `FR-*` / `SYS-*` / `SR-*` / `TD-*` / `TDD-*` / `CR-*` / `WP-*` / `SKR-*` 属主文档 §5.1.1 **表 N4**：它们是规则编号，**不是**对象 ID，不得写入任何对象 ID 字段；
8. Review 的两类编号不得互换：`review_id` 用 `RVW-*`，`findings[].id` 与 `blockers[]` 用 `REV-*`（主文档 §5.1）；**`CR-` 只用于 Code Review 硬规则**（本册 §11.10），不得再作为 finding ID。
## 1.4 Skill 状态与权威副本裁定

| # | Skill | 服务节点 | 承担 Agent | 状态 | 章节 |
|---|---|---|---|---|---|
| ① | `prd-split` | Stage 0-a | `ufs-requirements` | `exists` | 第 5 章 |
| ② | `ufs-challenge` | Stage 0-b | `ufs-challenge` | `new` | 第 6 章 |
| ③ | `atdd-development` | `open` | `ufs-main` | `active` | 第 7 章 |
| ④ | `ufs-test-design` | `design` | `ufs-test-design` | `active` | 第 8 章 |
| ⑤ | `ufs-writing-plans` | `plan` | `ufs-build-plan` | `active`（沿用，Outputs 由本册补齐） | 第 9 章 |
| ⑥ | `ufs-tdd` | `execute` | `ufs-coding` | `active` | 第 10 章 |
| ⑦ | `ufs-code-review` | `review` | `ufs-code-review` | `new` | 第 11 章 |
| ⑧ | `ufs-verification` | `verify` | `ufs-verification` | `active`（源缺失，本册补全并冻结为权威） | 第 12 章 |
**Skill 存放路径**：`.opencode/skills/<skill-name>/SKILL.md`。

---
# 2. 统一 18 节 Skill 模板
## 2.1 为什么统一骨架

| 问题 | 危害 |
|---|---|
| 各规范的章节数不一致（28 / 50 / 37 / 52） | 无法判断某个 Skill 是否"完整"；无法机器检查缺失章节 |
| 标题层级混用 | 目录抽取与 Hook 校验失败 |
| 同一槽位出现两种键名（`Comet Stage` / `Position in Comet`） | 无法跨 Skill 检索同一语义 |
| 关键槽位缺失（无 Trigger、无 Outputs） | Skill 无法被 Comet 自动触发；产物契约空缺 |
**计数口径（G46）**：**18 节 = 正文节 `x.1`–`x.18`**，**不含** `x.0` 元信息头。因此一章共有 19 个二级标题（`x.0` + 18 节），Hook 逐节比对时**必须排除 `x.0`**，否则会把元信息头误判为多出的节。

**裁定**：18 节模板是**规范性骨架**。任一 Skill 缺少任一槽位，即为**规范不完整**，不得进入冻结（对应本册第 3 章 SYS-6 与第 4 章结构化输出来源）。
## 2.2 模板槽位定义

| # | 槽位（EN） | 槽位（中文） | 必含内容 | "已填"最小判定 | 常见缺失 |
|---|---|---|---|---|---|
| 1 | Purpose | 目的 | 该 Skill 服务哪个节点、把什么转成什么、明确不负责什么 | 有"输入→输出"一句话 + 否定边界清单 | 只写"用于做 X"而无边界 |
| 2 | Core Principle | 核心原则 | 1 条可引用的原则原文，说明该 Skill 存在的理由 | 有引文块，且能被 Hard Rules 引用 | 与 Purpose 重复 |
| 3 | Comet Stage | Comet 阶段 | 服务节点（`phase` + `node`）、在链路中的位置、消费/被消费关系 | 用词为五阶段/八节点的合法名 | 自造阶段名 |
| 4 | Trigger | 触发 | 何时必须调用、何时重新调用、前置材料清单 | 至少 1 类"强制调用"条件 + 1 类"重跑"条件 | 只写阶段位置，无触发条件 |
| 5 | Inputs | 输入 | 必读产物、可选产物、外部查询、**输入硬约束** | 区分"必须"与"可选" | 只列文件名，无硬约束 |
| 6 | Outputs | 输出 | 产物名、目录形状、"至少包含"清单、Schema 引用 | 有可枚举的字段/章节清单 | 只有一句"输出 X.md" |
| 7 | Overall Workflow | 总体流程 | 一段式链路（箭头图） | 覆盖从输入加载到 Human Gate | 流程与 Steps 不一致 |
| 8 | Steps | 步骤 | 编号步骤 + 每步强制规则（表格） | 每步有"动作/产物 + 强制规则" | 只写步骤名 |
| 9 | Key Enumerations & Matrices | 关键枚举与矩阵 | 枚举全集（不得只给示例）+ 决策矩阵 | 枚举可被 Hook 解析为闭集 | 用"等"省略枚举 |
| 10 | Hard Rules | 硬规则 | 编号规则全集，可被判 True/False | 每条可检查 | 与 Forbidden 混写 |
| 11 | Forbidden Behaviours | 禁止行为 | `❌` 清单，行为级 | 每条是一个可观察的动作 | 写成价值观陈述 |
| 12 | Failure Contract | 失败契约 | 失败分类、输出状态、回流目标、阻断条件 | 有状态枚举 + 路由 | 只写"报错" |
| 13 | Agent Responsibilities | Agent 职责 | 以 13 Agent 名册为准的职责矩阵 | 只出现合法 Agent 名 | 使用旧名册（Main Developer Agent 等） |
| 14 | Tool Usage | 工具使用 | 工具 + 用途 + 约束；证据格式 | 每个工具有一条约束 | 只列工具名 |
| 15 | Human Gate | 人工门禁 | 门禁名、闸门对象、确认清单 | 与总体设计 §10.2 对应 | 遗漏确认项 |
| 16 | Definition of Done | 完成定义 | checkbox 清单 | 全部可判定 | 与 Hard Rules 重复 |
| 17 | Relationships with Other Skills | 与其他 Skill 的关系 | 上游/下游/回流；边界一句话 | 覆盖直接邻居 | 只画箭头 |
| 18 | Final Principle | 最终原则 | 1 条引文 + 端到端链 | 有引文块 | 复制 Core Principle |
## 2.3 Skill 元信息头（模板前置块）

每个 Skill 章节在 18 槽位之前**必须**先给出元信息表：

**元信息**: `name`=<skill 名，与 .opencode/skills/<name>/ 一致> · `serves`=<phase > node 或 Stage 0-a/0-b> · `executing_agent`=<13 名册中的 Agent> · `gate_agent`=<门禁 Agent / Hook，可空> · `output_schema`=<comet.*.v1 或产物文件名> · `write_path`=<该 Skill 唯一合法写路径> · `presets`={full: <行为>, tweak: <行为>, hotfix: <行为>} · `status`={exists | new | active}（**无 `backfilled` 取值**：由本设计补写并已冻结为权威的 Skill 一律记 `active`，`99 D35`）
## 2.4 模板使用规则

1. **槽位顺序不可调整**，槽位编号即"1–18"语义编号，章内显示为 `<章号>.<槽位号>`；
2. 槽位内子项用 `###`，且**不得新增第 19 个槽位**；确需扩展时扩展子项；
3. 任一槽位标记 `不适用` 时，必须写明"为什么不适用 + 若将来适用由谁补"——**不允许留空**；
4. 同一语义在不同 Skill 中必须使用同一槽位名（尤其槽位 3 一律为 `Comet Stage`）。

---
# 3. 跨 Skill 体系级硬规则
## 3.1 体系级硬规则全集（SYS-1…SYS-7）

同一约束在多份 Skill 规范中独立重复，说明它是**平台级约束**而非某个 Skill 的局部规则。本册将其**只陈述一次**为 SYS 规则，各 Skill 章不再重复展开，只在其 Hard Rules 中以 `SYS-n` 引用。

| # | 体系级硬规则 | 规范表述 | 违反示例 | 强制层 |
|---|---|---|---|---|
| **SYS-1** | **Design 阶段不绑定函数** | Test Case 在 `design` 阶段描述行为，**不得出现具体函数名**；`Behavioral Test → Interface → Function` 映射由 **`plan` 节点**建立；`execute` 只做可执行实例化，不重新决定映射（总体设计 §5.1；分册 01 §6.6；`FR-4`） | 在 `design` 节点写 `TC-001-01: Test FlowControl_Evaluate()` | Hook：`design` artifacts 检查函数名模式 |
| **SYS-2** | **不得自造或篡改需求与契约** | Agent 不得自行创造 Requirement，也不得为获得 GREEN 修改 Requirement / AC / Expected Behavior / Test Contract（分册 01《Test Contract Protection》） | `Test Failed → 修改 Expected → PASS` | Hook：`test-contract-protection` |
| **SYS-3** | **区分 Existing Behavior 与 Required Behavior** | Legacy 必须先记录当前实际行为（Characterization Baseline），并与 Required Behavior 显式区分、标注来源 | 把 CodeGraph 查到的现有行为直接当作新需求 | Hook：Legacy 产物要求 `existing_behavior`/`required_behavior` 字段 |
| **SYS-4** | **CodeGraph 只是证据，不是需求定义** | CodeGraph 查询结果属 Implementation Evidence / Change Impact / Existing Behavior，**不能**推导新需求（总体设计 I5、§11.1） | "CodeGraph 显示 HostWriteHandler 调用 FlowControl_Check，所以 Host Write 必须被阻断" | **被检产物与字段（A31）**：① `comet-artifacts/requirements/**` 与 `challenge-report.md` 中**不得**出现 `source: codegraph` 作为 REQ/AC/ASM 的来源（这些产物无 `source` 字段，故该形态只会以非法字段出现）；② `design.md` / `exploration-report.md` 的 `Existing Behavior` 条目**必须**带 `source: codegraph`（合法）；③ `evidence` 载荷的 `codegraph_evidence` 结构按分册 03 §6.3 校验；④ **附加派生视图**（`test-matrix.yaml` / `characterization-test-plan.md` 等）若带 `source` 字段，其取值只能来自上游产物（`design.md` / `test-design.md`）的既有来源，**不得**自行标注 `codegraph`。**落地**：本条**不设独立 Hook**——需求类产物的来源合法性由 **`H02`**（design artifacts 门禁，检查函数名与来源形态）与 **`H12`**（`level_review.evidence_executable` 核对证据来源）承接，内容完备性由 `ufs-document-review` 人工评审。**（原“H13 需求类产物来源合法性 + 分册 03 §7.6”引用已撤回：`03` 无该行。）** |
| **SYS-5** | **每个需求必须有验证意图** | 每个 Requirement 最终必须能回答"怎么知道它被满足"；允许不同 Verification Level，但**不允许没有验证策略** | AC 无对应 AT、无 Verification Level | Hook：`REQ→AC→AT` 与 Verification Level 完整性检查 |
| **SYS-6** | **Skill 输出必须结构化** | 每个节点必须产出结构化 Artifact，否则 guard 无法校验、下游无法消费（总体设计 I6、§7.2） | 只留一段对话式"设计说明" | Hook：Artifact Schema 校验（总体设计 §2.3 Output Schema） |
| **SYS-7** | **强制优先于 Agent 自觉** | 阶段推进、写路径、契约变更由 Hook 强制，不依赖 Agent 自律（总体设计 I1/I2、§3.2"Plugin 不能绕过 Hook"） | Coding Agent 自行宣布进入 `verify` | Hook：`stage-gate` / `code-write-scope` |
**注 1**：SYS-1…SYS-5 是多个 Skill 独立重复的约束，故升格为体系级规则；SYS-6、SYS-7 由总体设计的架构不变量 I6、I1/I2 升格而来。
**注 2（编号）**：`FR-1..FR-5` 是正式规则层（分册 01 §28），`SYS-*` 与 `SR-*` 是该层的**执行细则**，不与之并列。冲突消解顺序固定为 `FR-*` > `SYS-*` > `SR-*` > 具体 Skill Steps（**上位优先**）；只有**同层之内**才按"更具体者优先"（99 D14）。
## 3.2 SYS 规则 × Skill 矩阵
> 图例: ● = 该 Skill 显式声明；○ = 由 SYS 规则以 `SYS-n` 引用继承；— = 不适用。表内 § 均指**本册**章节。

| SYS 规则 | ① prd-split | ② ufs-challenge | ③ atdd-development | ④ ufs-test-design | ⑤ ufs-writing-plans | ⑥ ufs-tdd | ⑦ ufs-code-review | ⑧ ufs-verification |
|---|---|---|---|---|---|---|---|---|
| SYS-1 Design 不绑定函数 | ● §5.10 P-5 | ● §6.10 C-10 | ● §7.10 `SR-3` | ● §8.2 | ● §9.9.8 | ● §10.8.2（`plan` 已给映射） | ● §11.8 Step 3 | ● §12.9.1 Q05 |
| SYS-2 不得自造/篡改契约 | ● §5.10 P-2/P-9 | ● §6.10 C-1/C-2 | ● §7.10 `SR-4`/`SR-5` | ● §8.11（11 条） | ● §9.11（10 条） | ● §10.10 TDD-6 | ● §11.10 CR-2 | ● §12.10 V-5 |
| SYS-3 Existing vs Required | ● §5.5 | ● §6.9.5 | ● §7.10 `SR-6` | ● §8.10 TD-11 | ● §9.9.7（TDD-aware Legacy） | ● §10.9.8 | ● §11.8 Step 3 | ● §12.9.1 Q01 |
| SYS-4 CodeGraph 只是证据 | ○ | ○ | ● §7.5 输入硬约束 | ● §8.14 工具使用 | ● §9.14 | ● §10.14 | ○ | ○ |
| SYS-5 每个需求有验证意图 | ● §5.10 P-7 | ● §6.9.4 | ● §7.10 `SR-7` | ● §8.16 DoD / §10.16 Exit Criteria | ● §9.6.3 acceptance_refs | ● §10.16 DoD | ○ | ● §12.9.1 Q04 |
| SYS-6 输出结构化 | ● §5.6 | ● §6.6 固定 5 块 | ● §7.6 | ● §8.6（16 项） | ○（§9.6 本册定义） | ● §10.6 TDD Evidence | ● §11.6 `comet.review.v1` | ● §12.6 `comet.verify.v1` |
| SYS-7 强制优先于自觉 | ○ | ○ | ○ | ○ | ○ | ● §10.14 Hooks | ● §11.3 guard evidence-only | ● §12.14 pre-verify Hook |
## 3.3 冲突与升格规则

1. **冲突消解口径（99 D14）**：顺序固定为 `FR-*` > `SYS-*` > `SR-*` > 具体 Skill Steps，**上位优先**；仅**同层之内**才按"更具体者优先"。可机器检查不是消解顺序，只是实现顺序。若某 Skill 的 Steps 与之冲突，以上位为准并回改该 Skill 章；
2. **SYS 规则只能由总体设计新增或废止**：本册只能在附录记录候选，不得自行扩展 SYS 编号；
3. **新增 SYS 候选的判据**：同一约束在 ≥3 个 Skill 中独立声明，且违反后无法被现有 Hook 检出时，才升格；
4. **SYS-6 是"结构化输出"的唯一权威表述**，各 Skill 的 Outputs 章只需给出具体字段，不再论证必要性；
5. **三套编号不得混用，禁止裸用 `Rule N`**；层级与消解顺序见第 1 条（99 D14）。

---
# 4. 调用矩阵与 Skill 边界
## 4.1 节点 × Agent × Skill 调用矩阵

| 节点 / 轨道 | 主 Agent | Skill | 门禁 Agent | 专家（按需） | Output Schema | 本册章节 |
|---|---|---|---|---|---|---|
| Stage 0-a Requirement Decomposition | `ufs-requirements` | **① `prd-split`** | — | `ufs-firmware-expert` | `comet-artifacts/requirements/**` | 第 5 章 |
| Stage 0-b Challenge | `ufs-challenge` | **② `ufs-challenge`** | — | `ufs-firmware-expert` | `challenge-report.md` | 第 6 章 |
| `open`（phase open） | `ufs-main` | **③ `atdd-development`** | `ufs-document-review` | `ufs-firmware-expert` | `comet.intake.v1` | 第 7 章 |
| `design`（phase design） | `ufs-exploration`(Step 0) → `ufs-design` → `ufs-test-design` | **④ `ufs-test-design`** | `ufs-document-review` | `ufs-firmware-expert`、OMO | `comet.design.v1` | 第 8 章 |
| `plan`（phase build） | `ufs-build-plan` | **⑤ `ufs-writing-plans`** | `ufs-document-review` | — | `comet.plan.v1` | 第 9 章 |
| `execute`（phase build） | `ufs-coding` | **⑥ `ufs-tdd`** | Code Write Hook | `ufs-firmware-expert`、`ufs-failure-analysis` | `comet.execution-evidence.v1` | 第 10 章 |
| `subagent-execute` | OMO / 子代理 | `subagent-driven-development` | Handoff Evidence Hook | — | `comet.handoff.v1` | 本册不拥有（总体设计 §4.5） |
| `review`（phase build） | `ufs-code-review` | **⑦ `ufs-code-review`** | Review Evidence Hook | — | `comet.review.v1` | 第 11 章 |
| `verify`（phase verify） | `ufs-verification` | **⑧ `ufs-verification`** | Verify Hook | `ufs-failure-analysis` | `comet.verify.v1` | 第 12 章 |
| `archive`（phase archive） | `ufs-main` + Human | `comet-archive`（Comet 原生，非本册 8 个） | archive Hook | — | `comet.archive.v1` | 总体设计 §4.8 |
| 门禁（横切各节点） | `ufs-document-review` | — | — | — | findings | 总体设计 §6.3 |
| 按需（全程） | `ufs-firmware-expert`、`ufs-failure-analysis` | — | — | — | 分析结论 / 失败分类 | 总体设计 §6.2 |
**调用链固定**：`Comet Node → Skill → Agent → Tool / Plugin`。Skill 决定"什么时候调用 / 为什么调用 / 如何使用结果"；Plugin 决定"如何真正执行"（总体设计 §7.2）。
## 4.2 Skill × preset 降级矩阵

| Skill | `full` | `tweak` | `hotfix` | 降级后果 |
|---|---|---|---|---|
| ① `prd-split` | ✅ 完整 | ⚠️ 轻量：仅 Story 边界与 AC | ⚠️ 跳过：缺陷已有既有行为 | hotfix 下无新 Story，直接使用既有行为 |
| ② `ufs-challenge` | ✅ | ⚠️ 仅 AC 可验证性 | ❌ 跳过 | hotfix 不产生 `challenge-report.md` |
| ③ `atdd-development` | ✅ | ✅ | ✅ | — |
| ④ `ufs-test-design` | ✅ 完整 | ❌ 跳过（open → build） | ❌ 跳过 | **Verification Level 必须在 `plan` 节点轻量补做**（总体设计 §4.9；99 D40、99 D58） |
| ⑤ `ufs-writing-plans` | ✅ 完整计划 | ⚠️ 简化任务清单 | ⚠️ 简化任务清单 | 任务粒度可放宽，但 Task 必备字段不得减少 |
| ⑥ `ufs-tdd` | ✅ RED→GREEN→REFACTOR | ✅ 可省 REFACTOR 证据 | ✅ + **根因消除检查** | hotfix 缺根因消除检查即为违规 |
| ⑦ `ufs-code-review` | ✅ | ✅ | ✅ | 三个 preset 均不得跳过 |
| ⑧ `ufs-verification` | ✅ | ✅ | ✅ | 三个 preset 均不得跳过 |
**关键约束**（总体设计 §4.9）：`hotfix`/`tweak` 跳过 `design` 节点 ⇒ ④ 不运行 ⇒ Verification Level 判定必须在 `plan` 节点内以轻量形式补做。该约束的承载者是 ⑤ `ufs-writing-plans` 的 Steps（见 §9.8 Step 0）。
## 4.3 Skill 输出必须结构化（SYS-6）

- Skill **不能**只是"请按照 ATDD 方法做测试"；**必须要求结构化产物**，以便被 Hook 校验、被下游节点消费。
- 正式数据流：

```text
requirements.md → test-design.md → build-plan.md → verification.md
```
- 总体设计裁决后的产物归属（主文档 **§8.3** 产物所有者表）：

```text
comet-artifacts/requirements/**  →  <superpowersRoot>/specs/<canonical-design>.md
  →  <superpowersRoot>/specs/test-design.md  →  <superpowersRoot>/plans/*.md
  →  <openSpecRoot>/changes/<change>/tasks.md  →  code + TDD Evidence
  →  comet.review.v1 / comet.verify.v1（evidence，非文件）  →  <archiveRoot>
```
**Skill 结构化输出的三条最低要求**：

| # | 要求 | 判定 |
|---|---|---|
| O1 | 有稳定的**顶层键/章节名**（可被 Hook 抽取） | 章节名与模板槽位或 Schema 字段对应 |
| O2 | 有**稳定 ID**（见 §1.3） | 每条可追对象有 `PREFIX-STORY-SEQ` |
| O3 | 有**来源与状态字段**（`source` / `status` / `confidence`） | 可与 Evidence 链拼接 |
## 4.4 Skill 不是知识库

| Skill 不承担 | 承担者 | 边界公式 |
|---|---|---|
| Knowledge Base | `OpenViking` | `Skill = 方法论` |
| Lifecycle Management | `Comet` | `Comet = 生命周期` |
| Agent Communication | OMO | `OMO = 协作` |
| Security / Enforcement | Hooks | `Hook = 强制执行` |
| Code Facts | CodeGraph | `CodeGraph = 代码事实` |
**Skill 只负责六类内容**：**规则、流程、决策、检查项、输出格式、禁止事项**。

**反例**：`ufs-tdd` 不得塞入 UFS 协议知识、NAND 知识、SSD 架构知识、ARM 知识——这些由 OpenViking / CodeGraph / Firmware Knowledge Base 提供。

**候选 Skill 的否决先例**（fewer is better）：

| 候选 | 否决理由 | 替代方案 |
|---|---|---|
| `characterization-test` | 否则 Skill 会越来越多 | 降级为 `development_mode: legacy`；④ 负责 Characterization Test Design，⑥ 负责 Characterization Baseline |
| `failure-analysis` | 不必再造 Skill | ⑥ 调用 `systematic-debugging`，再套四分类 |
## 4.5 生命周期调用权与"不得自决"规则

1. **只有 `ufs-main` 持有生命周期状态**；Skill 不得自行推进节点，Agent 不得自决下一阶段（I2）；
2. **Skill 只被节点调用**，不得被另一个 Skill 直接调用（如 ⑤ 不得调用 ⑥，见 §9.10；总体设计 §4.5 与 1.2.1）；
3. **代码修改只发生在 `execute` / `subagent-execute`**，且必须 guard 通过 + 持有已批准 Build Task（I3）；
4. **Skill 的产物写入路径唯一**（总体设计 §6.5 写路径白名单）——超出路径的 Skill 输出视为违规。

---
# 5. Skill ① `prd-split`
## 5.0 元信息头

**元信息**: `name`=prd-split · `serves`=Stage 0-a（Comet 五阶段之外） · `executing_agent`=ufs-requirements · `gate_agent`=— · `output_schema`=comet-artifacts/requirements/**（非 comet.*.v1，Stage 0 不在节点契约内） · `write_path`=comet-artifacts/requirements/** · `presets`={full: 完整, tweak: 轻量（仅 Story 边界与 AC）, hotfix: 跳过} · `status`=exists
## 5.1 Purpose 目的

处理 Comet 闭环的 **Requirement Decomposition** 阶段：将 **Human Intent 转化为可审查的需求基线，而非编码任务**。

```text
Epic → Requirement Decomposition → ★ Story Freeze（Human Gate）→ 对抗式质询
     → Human Story Freeze → Comet Open
```
| 本 Skill **负责** | 本 Skill **不负责** |
|---|---|
| Why / What / Acceptance | 当前工程的影响分析（`design` Step 0，`ufs-exploration`） |
| L1 概念架构建议 | 详细 HOW（`design` 节点，`ufs-design`） |
| Requirement → AC → Scenario | 实现（`execute` 节点，`ufs-coding`） |
| Capability / Story 拆分 | 按 AC 留存验收证据（`verify` 节点，`ufs-verification`） |
**边界一句话**：只把 Human Intent 变成**可被质询、可被冻结**的需求基线，不进入工程实现。
## 5.2 Core Principle 核心原则

> **Human 拥有目标、范围、优先级、关键约束、关键架构方向、Story 边界和最终 Freeze 的决策权。不得自行填补会影响这些决策的未知项。**

推论（正文原文）：

1. **Capability 不是源码模块，也不是 Story**；
2. L1 概念架构**只覆盖**系统边界、核心组件职责、主数据/控制流、主要接口概念、外部依赖与架构约束；
3. **Story 必须有可判定的 AC 与验收场景**，且不将实现细节、源码模块、文件或目录当作需求。
## 5.3 Comet Stage Comet 阶段

服务 **Stage 0-a（Requirement Decomposition）**，位于 Comet 五阶段**之外**、早于任何 change 的存在。

**为什么不可能在 `open` 节点内**（总体设计 §4.1）：`open` 节点的 guard 是 `.comet.yaml exists`，即进入 `open` 时 change 已创建；而 Stage 0 的产物目录 `comet-artifacts/requirements/` 与 OpenSpec change 目录**并列**，发生在 change 创建之前。

```text
Epic / PRD
   ▼
[Stage 0-a] Requirement Decomposition ── ufs-requirements ── comet-artifacts/requirements/
   ▼  ★ Story Freeze（Human Gate）
[Stage 0-b] Challenge ─────────────────── ufs-challenge
   ▼  Human Story Freeze   ← 离开 Stage 0 的唯一闸门
═══ Comet phase 边界（此时才创建 change）═══
```
**消费/被消费**：被 ② `ufs-challenge`、③ `atdd-development`、④ `ufs-test-design`、⑤ `ufs-writing-plans` 消费；本身不消费任何 Comet 节点产物。
## 5.4 Trigger 触发

| 类型 | 条件 | 强制动作 |
|---|---|---|
| 首次触发 | 出现 `PRD` / `Epic` / `Requirement` / `Feature Request` / `Change Request`，且尚无对应需求基线 | 调用本 Skill |
| 重跑触发 | Key unknown 被 Human 回答（`needs_human_decision` → decided） | 重跑并更新 `decisions.md` / Story |
| 重跑触发 | Scope / Out of Scope / AC / 关键依赖 / 关键架构边界 / Human Decision 实质变更 | 重跑并重新提交 Challenge |
| 上游回流 | `open` 发现需求冲突，或 `design` 无法覆盖 AC | 回流 Stage 0-a |
| **不触发** | `hotfix` preset（缺陷已有既有行为） | 跳过（总体设计 §4.9） |
**前置材料**（进入 Challenge 前必须齐备，否则不进入评审）：Story 标题/业务价值/Scope/Out of Scope、AC 及 Given/When/Then 场景、依赖与关联决策、概念架构边界与主要接口边界、已知约束与假设。
## 5.5 Inputs 输入

**必读**：项目中的 ATDD 规则、既有需求、决策、约束和相关材料；若存在对抗式质询模板，将其作为 Challenge 前的质量门槛。

输入整理为需求模型：

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
**输入硬约束**：任何会改变 Story 切分、验收边界、系统边界、性能/资源、安全、兼容性或关键架构方向的不确定性**必须**变为编号问题或决策记录，**不得假设答案**。
## 5.6 Outputs 输出

除非 Human 指定其他目录，所有产物写入：

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
**每个 Story 必须保留以下字段与章节**：

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
**`prd-split-result.md` 必须包含**：输入摘要、产出的 Epic/Story、依赖顺序、关键决策问题、未决假设、已知风险、下一步动作，以及**恰好一个状态**。

**ID 规范**（本册 §1.3）：`REQ-001`、`DEC-001`、`ASM-001`、`EPIC-001`、`STORY-001`、`AC-001-01`、`SC-001-01`。
## 5.7 Overall Workflow 总体流程

```text
输入材料 → 建立需求模型 → 转化关键未知项为 Decision
  → Capability Map + L1 概念架构 → Story Map（纵向价值切片）
  → 每 Story 的 AC + Scenario → 输出合同（requirements/**）
  → 【交给 ② ufs-challenge】 → Human 处理 findings → Story Freeze
```
## 5.8 Steps 步骤

| Step | 动作 | 产物 | 强制规则 |
|---|---|---|---|
| Step 1 — 建立需求模型 | 阅读 ATDD 规则 / 既有需求 / 决策 / 约束；整理 `requirement` yaml | 需求模型 | 未知项不得假设 |
| Step 2 — 转化关键未知项 | 把影响 Story 切分/验收边界/系统边界/性能资源/安全/兼容性/架构方向的未知项变为 `DEC-n` | `decisions.md` | 关键问题未答复时状态只能 `NEEDS_HUMAN_DECISION`，不得称 Ready/Frozen/Accepted |
| Step 3 — Capability 与概念架构 | 按用户/系统能力建 Capability Map；提出 L1 概念架构 | `capability-map.md`、`conceptual-architecture.md` | Capability 不是源码模块；禁止函数签名/表结构/算法/队列实现/状态机细节/内存布局 |
| Step 4 — Story Map | 按最小可行价值与依赖顺序拆为可独立验收的**纵向价值切片** | `story-map.md`、`stories/*.md` | Story 边界、排序、优先级必须由 Human 确认 |
| Step 5 — ATDD 验收标准 | 每 Story 每条 AC：唯一 ID + 可观察通过条件 + 至少一个显式关联场景 | AC + Scenario | 缺场景、缺可观察通过条件、依赖隐含前提的 AC **不可进入 Challenge** |
| Step 6 — 输出合同 | 落盘 11 项产物 + stories/ | `prd-split-result.md` | 恰好一个状态 |
## 5.9 Key Enumerations & Matrices 关键枚举与矩阵
### 5.9.1 状态枚举（闭集，3 值）
| 状态 | 含义 |
|---|---|
| `NEEDS_HUMAN_DECISION` | 关键问题尚未确认 |
| `DRAFT_READY_FOR_CHALLENGE` | 资料完整，可交给对抗式质询 |
| `BLOCKED` | 缺少不能安全假设的必要输入 |
`DRAFT_READY_FOR_CHALLENGE` **不等于** Frozen。
### 5.9.2 AC / Scenario 最小形态
| 元素 | 要求 | 禁止 |
|---|---|---|
| `Given` | 可重复建立的前置状态、数据与依赖 | 隐含前提 |
| `When` | 单一、可执行的业务动作或系统事件 | 复合动作 |
| `Then` | 可观察、可断言的结果 | "正常""正确""合适"等不可验证措辞 |
| `Covered by` | 每条 AC 显式列出覆盖它的 Scenario ID | 仅靠隐含关联 |
### 5.9.3 Story 五条准入要求
产生可观察的用户或系统价值；有清晰 Scope 与 Out of Scope；有明确依赖并尽可能形成可运行增量；有可判定的 AC 与验收场景；**不将实现细节、源码模块、文件或目录当作需求**。
### 5.9.4 至少阻断 Freeze 的问题（5 类，= 总体设计 §10.3）
| # | 阻断条件 |
|---|---|
| B1 | AC 没有场景，或通过条件不可观察 |
| B2 | Scope / Out of Scope 不清晰 |
| B3 | 依赖未定义或不可获得 |
| B4 | 关键性能、资源、安全、兼容性或架构问题未决 |
| B5 | Story 包含多个不可独立交付的价值切片 |
### 5.9.5 Story 必备字段矩阵
| 类别 | 字段 / 章节 |
|---|---|
| front-matter | `id` / `title` / `parent_epic` / `status` / `source_requirements` / `dependencies` / `architecture_boundaries` / `major_interfaces` / `decisions` / `assumptions` |
| 正文章节 | Business Value / Scope / Out of Scope / Acceptance Criteria / Dependencies / Architecture Boundaries / Major Interface Concepts / Constraints / Decisions / Assumptions / Open Questions |
### 5.9.6 AC 八类（Stage 0-a 的执行义务）

| # | 类别 | Stage 0-a 义务（与分册 04 §6.1 一致；类别语义归分册 01，本册不重定义） |
|---|---|---|
| 1 | Normal Behavior | 至少一条 AC 覆盖主路径 |
| 2 | Boundary | 存在阈值即必须有边界 AC |
| 3 | Negative | 至少一条失败或拒绝路径 |
| 4 | Error | 固件必须列出错误注入类 AC |
| 5 | Recovery | 有降级/阻塞态即必须有恢复 AC |
| 6 | State Transition | 有状态机语义即必须有迁移 AC |
| 7 | Timing | 有实时性约束即必须有 Timing AC |
| 8 | Concurrency | **ARM firmware 特别检查**（ISR / main loop / DMA callback / background / host IO / GC） |

**规则**：不适用的类别**必须写明 N/A 理由**，不得留空；该义务在 Stage 0-b 由 Freeze Checklist 复检（本册 §6.15、分册 04 §3.8）。
## 5.10 Hard Rules 硬规则

| # | 规则 | 可检查点 |
|---|---|---|
| P-1 | Human 拥有目标/范围/优先级/关键约束/关键架构方向/Story 边界/最终 Freeze 决策权 | 决策项有 `owner: Human` |
| P-2 | 不得自行填补会影响 Human 决策的未知项 | `unknowns` 非空时状态不得为 Ready |
| P-3 | 关键问题未答复时可产出草案，但状态只能是 `NEEDS_HUMAN_DECISION` | `prd-split-result.md` 状态字段 |
| P-4 | Capability 不是源码模块，不是 Story；不得把 `ftl.c` / `nand.c` 写成 Story | Story 标题/内容无文件路径 |
| P-5 | L1 概念架构禁止函数签名/表结构/算法/队列实现/状态机细节/内存布局 | 文档 grep 函数签名模式 |
| P-6 | Story 必须是可独立验收的纵向价值切片，边界/排序/优先级由 Human 确认 | Story Scope/Out of Scope 存在 |
| P-7 | 每条 AC 必须有唯一 ID、可观察通过条件、至少一个显式关联场景 | `Covered by` 非空 |
| P-8 | 缺场景 / 不可观察 / 依赖隐含前提的 AC 不可进入 Challenge | Challenge 前置校验 |
| P-9 | 不为设计、代码、测试或证据创建虚假的完成记录 | 产物中无 DES/UT/EVD 的"完成"声明 |
| P-10 | 冻结后的 Scope / Out of Scope / AC / 关键架构边界 / 关键约束 / Human Decision 不得被后续 Agent 静默改变 | Freeze 后 diff 检查 |
| P-11 | `open` 发现需求冲突或 `design` 无法覆盖 AC 时回流 Stage 0；`build`/`verify` 发现实现问题不以改写需求为默认修复方式 | 回流记录 |
| P-12 | **AC 集合必须按八类逐类检查并记录 N/A 理由**：`Normal / Boundary / Negative / Error / Recovery / State Transition / Timing / Concurrency`（对齐分册 04 §6.1；八类语义归分册 01，本 Skill 不重新定义） | 八类逐类有 AC 或写明 N/A 理由；Stage 0-b 的 Freeze Checklist 会复检（本册 §6.15、分册 04 §3.8） |
## 5.11 Forbidden Behaviours 禁止行为

```text
❌ 写函数签名、表结构、算法、队列实现、状态机细节、内存布局   ❌ 把源码模块 / 文件 / 目录当作需求或 Story   ❌ 用 Agent 假设答案代替 Human Decision
❌ 为设计、代码、测试、证据创建虚假的完成记录   ❌ 把 `DRAFT_READY_FOR_CHALLENGE` 称为 Frozen 或 Accepted   ❌ 宣称"已经实现"或"验收通过"
❌ 在 build / verify 发现实现问题时改需求作为默认修复   ❌ 在关键问题未确认时把草案称为 Ready / Frozen / Accepted
```
## 5.12 Failure Contract 失败契约

| 失败情形 | 输出状态 | 回流 / 动作 | 阻断 |
|---|---|---|---|
| 缺少不能安全假设的必要输入 | `BLOCKED` | 请求 Human 补充输入 | 阻断 Stage 0 前进 |
| 关键问题未确认 | `NEEDS_HUMAN_DECISION` | 生成 `DEC-n`，等待 Human | 阻断 Challenge |
| AC 缺场景 / 不可观察 / 隐含前提 | `NEEDS_HUMAN_DECISION` | 回 Step 5 | 阻断 Challenge |
| 资料完整 | `DRAFT_READY_FOR_CHALLENGE` | 交 ② `ufs-challenge` | 不阻断 |
| 冻结后需求冲突 | — | 回流 Stage 0-a（不是改写已冻结 Story） | 阻断下游节点 |
**硬约束**：`build` / `verify` 发现实现问题时，**不以改写需求作为默认修复方式**（总体设计 §9.2）。
## 5.13 Agent Responsibilities Agent 职责

| Agent | 职责 | 权威 |
|---|---|---|
| `ufs-requirements` | 主执行：需求分解、产出需求基线；`primary / 0.1` | 总体设计 §6.2 |
| `ufs-firmware-expert` | 按需提供领域技术事实与分析（区分 FACT/REFERENCE/ANALYSIS/ASSUMPTION） | 总体设计 §7.3 |
| `ufs-document-review` | 横切门禁：检查需求制品自洽性与可追溯性（**不审代码**） | 总体设计 §6.3 |
| Human | 需求决策者：目标/范围/优先级/关键约束/关键架构方向/Story 边界/Freeze | 总体设计 §10.2 |
## 5.14 Tool Usage 工具使用

| 工具 | 用途 | 约束 |
|---|---|---|
| `read` / `glob` / `grep` | 读取 ATDD 规则、既有需求、决策、约束与相关材料 | 默认全拒 + 白名单放行（总体设计 §6.5 范本） |
| `edit` | 仅写 `comet-artifacts/requirements/**` | **唯一合法写路径**；越界为违规 |
| skill `prd-split` | 调用本 Skill | 总体设计 §6.5 |
| CodeGraph | — | **不得用于定义需求**（总体设计 I5、§11.1、SYS-4） |
## 5.15 Human Gate 人工门禁

| Gate | 闸门对象 | 确认清单 |
|---|---|---|
| **★ Story Freeze**（Stage 0-a 结束；Human Gate） | 需求基线 | Capability Map / Story Map / AC / Scenario / 依赖 / 架构边界 / 假设 / 风险 |
| **Story Freeze**（Stage 0-b，属 ②） | Story 边界 / Scope / AC / 场景 / 关键架构边界 | 由 Human 在所有 BLOCK 关闭后执行 |
**规则**：Story 边界、排序和优先级**必须由 Human 确认**；关键问题未答复时不得冻结。冻结后，Scope / Out of Scope / AC / 关键架构边界 / 关键约束 / Human Decision **不得被后续 Agent 静默改变**。
## 5.16 Definition of Done 完成定义

```text
[ ] 输入材料已读（ATDD 规则 / 既有需求 / 决策 / 约束）   [ ] requirement 模型完整（含 unknowns 与 out_of_scope）
[ ] 所有影响 Story 切分的未知项已转为 DEC-n 或已获 Human 回答   [ ] Capability Map 已产出，且 Capability 不是源码模块
[ ] L1 概念架构仅覆盖边界/职责/主流程/接口概念/依赖/约束   [ ] Story Map 为纵向价值切片，边界与排序经 Human 确认
[ ] 每个 Story 具备 **10 个 front-matter 字段**（见 §2.8）与 11 个正文章节   [ ] 每条 AC 有唯一 ID、可观察通过条件、至少一个显式关联 Scenario
[ ] Boundary / Error-Recovery / State / Concurrency / Hardware 风险已考虑
[ ] AC 集合已按八类（Normal / Boundary / Negative / Error / Recovery / State Transition / Timing / Concurrency）逐类检查，不适用的类别已写明 N/A 理由
[ ] decisions.md / assumptions.md / constraints.md / dependency-map.md 已产出   [ ] prd-split-result.md 含 7 项内容与恰好一个状态
[ ] 5 类 Freeze 阻断条件均不成立   [ ] 未创建任何虚假的 Design/Code/Test/Evidence 完成记录
```
## 5.17 Relationships with Other Skills 与其他 Skill 的关系

```text
① prd-split（Stage 0-a）
   └─► ② ufs-challenge（Stage 0-b）──► Human Story Freeze
                                          └─► ③ atdd-development（open 节点）
```
| 关系 | 内容 |
|---|---|
| 下游 | **② `ufs-challenge`**：`DRAFT_READY_FOR_CHALLENGE` 后交其质询；`DRAFT_READY_FOR_CHALLENGE` ≠ Frozen |
| 下游 | **③ `atdd-development`**：Story Freeze 后进入 `open` 节点，把 Requirement/AC 转成 Acceptance Test |
| 回流来源 | `open`（需求冲突）、`design`（无法覆盖 AC）→ 回流本 Skill（总体设计 §9.2） |
| 边界对照 | ① 定义"要交付什么价值"；③ 定义"系统必须表现什么可观察行为"；**① 不写任何行为测试形状** |
## 5.18 Final Principle 最终原则

> **只汇报：产物位置、Epic/Story 列表、当前状态、必须由 Human 回答的问题、风险和下一步。不要将草案称为 Frozen 或 Accepted，也不要宣称已经实现或验收通过。**

```text
Human Intent → prd-split → 可审查需求基线 → Challenge → Story Freeze → Comet Open
```
**最终原则**：Agent 可以完成大量需求分析与产物生成，但**需求定义权始终在 Human**；Agent 的唯一合法动作是"把未知项变成问题"，而不是"把未知项变成答案"。

---
# 6. Skill ② `ufs-challenge`
## 6.0 元信息头

**元信息**: `name`=ufs-challenge · `serves`=Stage 0-b（Comet 五阶段之外，Story Freeze 前） · `executing_agent`=ufs-challenge · `gate_agent`=—（Story Freeze 是闸门） · `output_schema`=comet-artifacts/challenge/challenge-report.md（非 comet.*.v1） · `write_path`=comet-artifacts/challenge/** · `presets`={full: 完整, tweak: 仅 AC 可验证性, hotfix: 跳过} · `status`=new
## 6.1 Purpose 目的

在 **Story Freeze 前**，以**反方评审（Challenge Reviewer）**姿态，系统检查 Story 的交付边界、验收标准、依赖、概念架构边界及隐含假设。

```text
Story Draft
  → 对抗式质询
  → Findings / Questions / Risks
  → ★ Story Freeze（Human Gate）
  → Modify / Accept
  → Story Freeze
```
| 本 Skill **负责** | 本 Skill **不负责**（归属） |
|---|---|
| 发现缺陷、提出质疑、给出修改建议 | 需求决策权（Human） |
| 判定 `PASS` / `PASS_WITH_CONCERNS` / `BLOCK_FREEZE` | 架构决策权（Human / `ufs-design`） |
| 产出 `challenge-report.md` | Story Freeze 权（Human） |
| 检查 AC 是否满足强制 Given/When/Then 规范 | 修改被审 Story / AC（`ufs-requirements`） |
**边界一句话**：它是**对抗式质询者**，不是需求作者，也不是决策者。
## 6.2 Core Principle 核心原则

> **对抗式姿态：它不设计、不编码、不决策，只寻找需求本身的缺陷；`Suggested Changes` 是建议，不是结论。**

三条推论：

1. **只质疑，不修复**：输出 findings，由 Human 决定 Modify / Accept；
2. **只证明，不代替**：它不能替 Human 做 Freeze 决策；
3. **只针对需求层**：可质疑 AC 是否可验证、Scope 是否清晰、概念架构边界是否冲突；不得进入实现设计。
## 6.3 Comet Stage Comet 阶段

服务 **Stage 0-b（Challenge）**，位于 Comet 五阶段**之外**、`open` 节点之前，是 **Story Freeze 的前置质询**。

```text
[Stage 0-a] prd-split
   ▼  ★ Story Freeze（Human Gate）
[Stage 0-b] ufs-challenge  ←── 本 Skill
   ▼  Human Story Freeze   ← 离开 Stage 0 的唯一闸门
═══ Comet phase 边界 ═══
   ▼
open / ③ atdd-development
```
| 项 | 内容（总体设计 §4.1） |
|---|---|
| 目标 | 对抗式质询需求本身的正确性、完整性、可验证性 |
| 输入 | 草稿 Story/AC/Scenario、原始 Requirement |
| Agent | `ufs-challenge` |
| 产物 | `challenge-report.md` |
| 状态 | `Verdict` + `Blocking/Non-blocking Findings` |
| Human Gate | **Story Freeze** |
## 6.4 Trigger 触发

**首次触发**：

- Story 标题、业务价值、Scope 与 Out of Scope；
- AC 及每条 AC 对应的 Given/When/Then 验收场景；
- 前置依赖与关联决策；
- 概念架构边界、主要接口边界；
- 已知约束与假设。

**重跑触发**：

| # | 重跑条件 |
|---|---|
| T1 | Scope、Out of Scope 或 AC 有实质修改 |
| T2 | 新增、删除或变更关键依赖 |
| T3 | 关键架构边界或 Human Decision 变化 |
| T4 | 上一次评审结果为 `BLOCK_FREEZE` |
**前置校验**：主控 Agent 校验输入是否齐全；**缺失项先补充，不进入评审**。

**不触发**：`hotfix` preset（总体设计 §4.9）。
## 6.5 Inputs 输入

**必读输入**（模板 §3 的 yaml 输入模板）：

```yaml
story:
  id: STORY-001
  title: <标题>
  business_value: <业务价值>
  scope: [...]
  out_of_scope: [...]
  acceptance_criteria:
    - id: AC-001-01
      statement: <可观察的通过条件>
      scenarios:
        - name: <场景名>
          given: <前置状态>
          when: <单一动作>
          then: <可观察结果>
  dependencies: []
  architecture_boundaries: [Host, Scheduler, FTL, NAND]
  major_interfaces: [Host.submit_io, FTL.submit_io, NAND.submit_request]
  decisions: []
  assumptions: []
  constraints: []
```
外加质询 Prompt，二者一起提供给执行者。

**输入硬约束**：

1. 材料不齐**不得进入评审**；
2. 输入是**草稿**（Draft），`DRAFT_READY_FOR_CHALLENGE` ≠ Frozen（`prd-split` SKILL L196）；
3. 原始 Requirement 必须一并提供，**不允许只给改写后的 Story**——否则无法判断 Story 是否偏离原始意图（总体设计 §4.1 输入列）。
## 6.6 Outputs 输出

**主产物**：`comet-artifacts/challenge/challenge-report.md`（总体设计 §8.1 新增目录）。

报告**必须**使用以下固定块：

```markdown
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
```
**归档结构**（权威根为 `comet-artifacts/`，99 D05）：

```text
comet-artifacts/
├─ requirements/                     # ① 的写路径
│  ├─ stories/
│  │  └─ STORY-001.md
│  ├─ decisions.md
│  └─ assumptions.md
└─ challenge/                        # ② 的写路径（唯一权威）
   ├─ challenge-report.md            # 本次 Challenge 报告（report_id: CHAL-nnn）
   ├─ STORY-001-challenge-v1.md
   ├─ STORY-001-challenge-v2.md
   └─ STORY-001-freeze-record.md
```

**归档名唯一化规则（G02）**：Challenge 报告有**两个历史命名**——`challenge-report.md`（源模板的单文件形态）与 `STORY-<id>-review-v<N>.md`（按 Story 分版本）。**本设计冻结为**：
- **`challenge-report.md`** = 本次 Challenge 的报告（`report_id: CHAL-nnn`），用于 Stage 0-b 即时评审；`tweak` 下可省（§6.15）；
- **`STORY-<id>-challenge-v<N>.md`** = 按 Story 归档的版本化副本，`<N>` 从 `1` 起严格递增、**不复用不覆盖**（`v1 → v2` 的落点即此目录）；
- **`STORY-<id>-review-v<N>.md` 已撤回**——`review` 一词已被 `comet.review.v1` 与 `REV-*` 占用，继续使用会造成指代歧义；
- **Freeze 记录**固定为 `STORY-<id>-freeze-record.md`（`99 D06`）。
**不得**把 Challenge 产物放入 `requirements/` 目录（废弃做法，99 D05）；`challenge/` 与 `requirements/` 在 `comet-artifacts/` 下并列。
**硬要求**：必须建立 **Finding ID 到 Story / AC / Decision 的关联**。
## 6.7 Overall Workflow 总体流程

```text
Story Draft → 前置校验（材料是否齐全）
  → 对抗式质询 → Findings / Questions / Risks
  → ★ Story Freeze（Human Gate；处理所有 BLOCK / WARN / 问题）
  → Modify / Accept
  → 实质变更则重跑 Challenge
  → 所有阻断项关闭 → Human Story Freeze
```
## 6.8 Steps 步骤

| Step | 动作 | 强制规则 |
|---|---|---|
| Step 1 | `ufs-requirements` 完成 Story 草案及其 ATDD 验收标准 | 前置条件 |
| Step 2 | 校验 §6.5 输入是否齐全 | 缺失项先补充，**不进入评审** |
| Step 3 | 将输入材料和 Prompt 发送给 `ufs-challenge` | 必须同时提供原始 Requirement |
| Step 4 | 保存输出并建立 Finding → Story/AC/Decision 关联 | 关联不可缺 |
| Step 5 | Human 审查所有 `BLOCK`、`WARN` 与需决策问题 | 四类处理：修改 Story/AC、新增 Decision Record、接受并记录风险、拒绝建议并写明理由 |
| Step 6 | 若 Story、AC、依赖或架构边界实质变更 | **重新运行 `ufs-challenge`** |
| Step 7 | 所有阻断项关闭后 | 由 **Human** 执行 Story Freeze；随后才允许进入 `open` |
## 6.9 Key Enumerations & Matrices 关键枚举与矩阵
### 6.9.1 Verdict 枚举（闭集，3 值）与状态迁移
| Verdict | 含义 | 后续动作 |
|---|---|---|
| `PASS` | 没有阻断项 | 进入 Human Approval；批准后冻结 |
| `PASS_WITH_CONCERNS` | 可继续，但存在需接受或记录的风险 | Human 处理 Concern 后批准或退回修改 |
| `BLOCK_FREEZE` | Story 尚不具备冻结条件 | 回到需求澄清、概念架构或 Story Mapping |
### 6.9.2 至少判定为 `BLOCK_FREEZE` 的 7 类情况
| # | 情况 | 与总体设计 §10.3 的对应 |
|---|---|---|
| BF1 | AC 不可验证，或没有明确通过条件 | = 总体设计 B1 |
| BF2 | 任一 AC 缺少 Given/When/Then 场景，或场景不能覆盖该 AC | = 总体设计 B1（强化） |
| BF3 | Story 依赖未定义的能力、接口或前置 Story | = 总体设计 B3 |
| BF4 | Scope 与 Out of Scope 缺失，导致实现边界无法判定 | = 总体设计 B2 |
| BF5 | 存在影响目标、架构边界、性能或资源约束的未决问题 | = 总体设计 B4 |
| BF6 | 一个 Story 含多个不可独立交付的价值切片 | = 总体设计 B5 |
| BF7 | 关键术语存在多种合理解释 | **超出**总体设计 §10.3，更严格 |
**裁定**：总体设计 §10.3 是"**至少**阻断"的下限；本 Skill 的 BF1–BF7 是**执行清单**，其中 BF7 是更严格项，予以保留。
### 6.9.3 Finding ID 命名空间
| 前缀 | 类别 | 是否阻断 Freeze |
|---|---|---|
| `BLOCK-nnn` | Blocking Finding | **是** |
| `WARN-nnn` | Non-blocking Finding | 否（须记录或接受） |
| `Q-nnn` | Questions for Human | 未回答则阻断 |
**注**：该命名空间**不进入** `REQ→…→EVD` 主干（本册 §1.3 规则 5）。
### 6.9.4 AC 场景强制规范矩阵
| 元素 | 强制要求 |
|---|---|
| 关联 | 每条 AC 必须拥有**至少一个一一关联**的 Given/When/Then 场景；没有场景的 AC 视为未完成 |
| `Given` | 可重复建立的前置状态、测试数据和依赖条件 |
| `When` | **单一**、可执行的业务动作或系统事件 |
| `Then` | 可观察、可断言的结果，**包含明确的通过判定** |
| 高风险 AC | 异常处理、边界值或状态转换相关 AC 除正常路径外还应增加失败/边界场景 |
| 显式性 | 一个场景可辅助证明多个 AC，但每个 AC 都必须**显式列出**其覆盖场景 |
### 6.9.5 质询问题集
| # | 质询维度 |
|---|---|
| 1 | Story 是否过大、过小，或包含多个不可独立交付的能力 |
| 2 | Story 是否是用户可观察、可独立验收的价值切片，而非源码模块任务 |
| 3 | 每条 AC 是否可测试 / 可观察 / 无歧义 / 有明确通过失败条件 / 不依赖未说明前提 / 有完整 GWT 场景 |
| 4 | 是否混入实现细节、具体算法、数据结构或 API 设计 |
| 5 | Scope / Out of Scope 是否完整，是否存在范围蔓延 |
| 6 | 依赖的 Story / 组件 / 外部系统 / 前置决策是否真实、明确、可获得 |
| 7 | 概念架构边界、职责划分、主要接口是否存在冲突或遗漏 |
| 8 | 是否存在隐含假设、未决策项、术语不一致或冲突需求 |
| 9 | 是否存在无法在 `verify` 阶段通过 GWT 场景证明的 AC |
| 10 | 是否应拆分、合并、重排该 Story |
## 6.10 Hard Rules 硬规则

| # | 规则 | 可检查点 |
|---|---|---|
| C-1 | **不得改写被审对象**：只发现问题、提出质疑、给出建议 | 报告为只读产物；不写 `comet-artifacts/requirements/**` |
| C-2 | **不得自造需求** | 报告不含新 AC 定义，只有 `Suggested Changes` |
| C-3 | **不得替 Human 决策** | 报告必须含 `Questions for Human`，无 `Freeze` 声明 |
| C-4 | **不得把 `Suggested Changes` 当作结论** | 建议项必须由 Human Modify / Accept |
| C-5 | 每条 AC 必须拥有至少一个一一关联的 Given/When/Then 场景 | 逐 AC 计数 |
| C-6 | 场景必须显式列出，禁止仅凭隐含关联验收 | `scenarios` 非空 |
| C-7 | 材料不齐不得进入评审 | 前置校验记录 |
| C-8 | **Blocking Finding 阻断 Story Freeze** | Verdict 与 finding 状态（总体设计 §10.3） |
| C-9 | 实质变更后必须重跑 | 版本号 `v1 → v2` |
| C-10 | 不得设计方案或编写代码 | 报告无实现级内容 |
## 6.11 Forbidden Behaviours 禁止行为

```text
❌ 修改被审的 Story / AC / Scenario 文件   ❌ 用 Suggested Changes 直接改写需求并视为已决定   ❌ 自行决定 Story Freeze
❌ 替 Human 在 Questions for Human 中选一个答案   ❌ 设计方案、算法、数据结构或 API   ❌ 编写或修改代码、测试   ❌ 用隐含关联代替显式 Scenario 关联
❌ 在材料不齐时给出 Verdict   ❌ 把「没有发现问题」等同于「需求已正确」
```
## 6.12 Failure Contract 失败契约

| 失败情形 | 输出 | 路由 | 阻断 |
|---|---|---|---|
| 存在任一 BF1–BF7 | `Verdict = BLOCK_FREEZE` | 回到需求澄清 / 概念架构 / Story Mapping（`ufs-requirements`） | **阻断 Story Freeze** |
| 存在需 Human 接受的风险 | `Verdict = PASS_WITH_CONCERNS` | Human 处理 Concern 后批准或退回 | 未处理则阻断 |
| 无阻断项 | `Verdict = PASS` | 进入 Human Approval；批准后冻结 | 不阻断 |
| 输入材料不齐 | 不产生 Verdict | 补材料后重跑 | 阻断评审 |
| 关键术语歧义（BF7） | `BLOCK_FREEZE` | 需求澄清 + 建立术语表 | 阻断 |
**硬规则**：**一个 Blocking Finding 即阻断 Story Freeze**；冻结后 Scope / Out of Scope / AC / 关键架构边界 / 关键约束 / Human Decision 不得被后续 Agent 静默改变（总体设计 §10.3）。
## 6.13 Agent Responsibilities Agent 职责

| 角色（模板） | 映射到 13 名册 | 职责 | 权威 |
|---|---|---|---|
| Challenge Reviewer | **`ufs-challenge`**（subagent / 0.0） | 对抗式质询；输出报告；不改被审对象 | 总体设计 §6.2、§6.3 |
| Requirement Agent（模板旧称，废弃） | `ufs-requirements` | 产出草稿 Story/AC/Scenario；按 findings 修订 | 总体设计 §6.2 |
| 主控 Agent | `ufs-main` | 校验输入齐全、发起 Challenge、汇总 findings、提交 Human | 总体设计 §6.2 |
| Human | Human | 处理所有 BLOCK/WARN/Q；执行 Story Freeze | 总体设计 §10.2 |
| 领域事实 | `ufs-firmware-expert`（按需） | 提供硬件/协议约束事实 | 总体设计 §7.3 |
**独立性规则**（总体设计 §6.3）：`ufs-challenge` **不改被审对象**；Blocking Finding 阻断 Freeze。
## 6.14 Tool Usage 工具使用

| 工具 | 用途 | 约束 |
|---|---|---|
| `read` / `glob` / `grep` | 读取草稿 Story/AC、原始 Requirement、既有需求与决策 | 全仓只读 |
| `edit` | 仅写 `comet-artifacts/challenge/**` | **唯一合法写路径** |
| skill `ufs-challenge` | 调用本 Skill | 总体设计 §6.5 |
| CodeGraph | — | 仅可作 Existing Behavior 事实；**不得用于定义需求**（SYS-4） |
## 6.15 Human Gate 人工门禁

| Gate | 闸门对象 | 确认清单 |
|---|---|---|
| **Story Freeze** | Story 边界 / Scope / AC / 场景 / 关键架构边界 | 见下 |
**Freeze Checklist（模板 9 项 + 本设计追加 2 项 = 11 项）**：

> 本清单**逐字镜像分册 04 §3.8**（Stage 0-b 门禁的权威执行册），同一门禁不得出现两个版本。

```text
[ ] 所有 BLOCK 已关闭或被明确撤销   [ ] 所有必要 Human Question 已有 Decision Record   [ ] Story 的业务价值、Scope、Out of Scope 清晰
[ ] 每条 AC 都可被观察、执行与判定通过/失败   [ ] 每条 AC 至少有一个完整的 Given/When/Then 场景，且场景覆盖其通过与失败判定   [ ] AC 未掺入不必要的实现细节
[ ] 依赖、假设、约束和架构边界已记录   [ ] 需要拆分或合并的 Story 已处理   [ ] Challenge 结论与 Human 处理结果均已归档
[ ] AC 集合已按**八类**（Normal / Boundary / Negative / Error / Recovery / State Transition / Timing / Concurrency）逐类检查，不适用的类别已写明理由；
[ ] 关键术语表（Glossary）在多份 Story 间**一致**，同一术语不出现两种解释。
```
**追加两条的依据**：分册 04 §3.8（对齐分册 01 的 AC 八类，见分册 04 §6.1）。本册以分册 04 为 Stage 0-b 门禁权威，**不得改写**该两条。
**`freeze-record` 至少记录**：冻结时间、批准人、Story 版本、评审版本、未关闭但已接受的风险及对应 Decision ID。
## 6.16 Definition of Done 完成定义

```text
[ ] challenge-report.md 含 5 个固定块：Verdict / Blocking / Non-blocking / Questions for Human / Suggested Changes
[ ] Verdict 为 3 值枚举之一   [ ] 每条 Blocking Finding 有：影响 / 涉及 Story·AC / 建议
[ ] 每个 Finding 已建立到 Story / AC / Decision 的关联   [ ] 逐条 AC 检查了「至少一个一一关联的 GWT 场景」   [ ] 高风险 AC 的失败/边界场景已被检查
[ ] 问题集 10 项全部检查   [ ] 报告已归档到 `comet-artifacts/challenge/STORY-<id>-challenge-v<N>.md`（命名规则见 §3.9；**`review-v<N>` 已撤回**）   [ ] 结论与 Human 处理结果均已归档（freeze-record）
[ ] AC 集合已按八类逐类检查并记录 N/A 理由（镜像分册 04 §3.8）
[ ] 关键术语表（Glossary）在多份 Story 间一致，同一术语不出现两种解释（镜像分册 04 §3.8）
```
## 6.17 Relationships with Other Skills 与其他 Skill 的关系

| 关系 | 内容 |
|---|---|
| 上游 | **① `prd-split`**：消费其 `DRAFT_READY_FOR_CHALLENGE` 产物 |
| 下游 | **③ `atdd-development`**：Story Freeze 后 `open` 节点启动；② 的结论是 ③ 的输入前提 |
| 同层对照 | **`ufs-document-review`**（一致性，各节点门禁，审文档自洽性）、**⑦ `ufs-code-review`**（技术核查，审代码） |
| 回流 | 需求实质变更 → 重跑 ② |
**四个审查 / 验证职能的边界（总体设计 §6.3）**：

> **按职能划分，不按实例划分**：每个职能有自己的独立性规则；**不得**升格为"四者必须互斥实例"——那会误强制无关角色分实例。唯一跨职能约束是：`ufs-code-review` 不与代码作者同实例、`ufs-verification` 独立于 Build 的局部成功。

| 职能 | 问的问题 | 姿态 | 时机 | 对象 | 独立性规则 |
|---|---|---|---|---|---|
| ② `ufs-challenge` | 这个需求**对不对**？完整吗？可验证吗？ | **对抗式** | Stage 0-b / Freeze 前 | 草稿 Story/AC/Scenario | 不改被审对象；Blocking Finding 阻断 Freeze |
| `ufs-document-review` | 这些制品之间**自洽吗**？可追溯吗？ | **一致性** | 各节点门禁 | 各阶段已产出制品 | 不改被审文档；`PASS` / `NEEDS_REVISION` |
| ⑦ `ufs-code-review` | 这段代码**对不对**？符合设计与计划吗？ | **技术核查** | `review` 节点 | Git Diff + 测试代码 | **与代码编写者不得是同一执行实例** |
| ⑧ `ufs-verification` | **整条契约链**是否真正被满足？ | **独立验收** | `verify` 节点 | 契约全集 + Git Diff + Test Result + Code Review | **独立于 Build 的局部成功**；`Tests passing alone is insufficient` |

**Stage 0-b 的专家列**：总体设计 §7.3 在 Stage 0-b 一栏列 `ufs-firmware-expert`。依据是总体设计 §7.3 的说明——`ufs-firmware-expert` 是**横切专家**，可在任意节点按需挂载，**不占节点槽位**（与总体设计 §4.0"按需·全程"一致）；因此本册 §4.1 与 §6.13 均允许其在 Stage 0-b 按需参与，不构成对 ② 独立性的破坏。
## 6.18 Final Principle 最终原则

> **在 Story 进入工程之前，让需求本身的缺陷先暴露出来；质询者只提供判断依据，不提供决策。**

```text
Story Draft → ufs-challenge → Verdict + Findings → Human Decision → Story Freeze
```
**最终原则**：`BLOCK_FREEZE` 的价值不在于否决，而在于**把"不可验证的需求"挡在 Change 之外**；一旦 Freeze，Scope/AC/关键架构边界即成为后续所有节点的不可静默变更契约。

---
# 7. Skill ③ `atdd-development`
## 7.0 元信息头

**元信息**: `name`=atdd-development · `serves`=phase open / node open · `executing_agent`=ufs-main · `gate_agent`=ufs-document-review · `output_schema`=comet.intake.v1（OpenSpec proposal.md + specs/**/spec.md 为镜像） · `write_path`=<openSpecRoot>/changes/<change>/（proposal.md / specs/**/spec.md 为镜像；权威在 `comet-artifacts/requirements/`） · `presets`={full: 完整, tweak: 完整, hotfix: 完整} · `status`=exists
## 7.1 Purpose 目的

用于 Comet **`open` 节点**，将用户需求转化为**可验证、可追踪的行为契约**。

```text
User Story → Requirement → Acceptance Criteria → Acceptance Scenario → Acceptance Test
```
**核心能力链**：`Requirement → AC → Scenario → Acceptance Test`，要求覆盖 Given/When/Then、Positive Case、Negative Case、Boundary、Error、Recovery、Observable Result、Requirement Traceability。

| 本 Skill **不负责** |
|---|
| 系统架构设计 / 函数设计 / C 代码实现 / Unit Test 实现 / Build Plan / 最终 Verification |
## 7.2 Core Principle 核心原则

> **ATDD 的核心不是「先写测试代码」，而是：在实现之前明确系统必须表现出的可观察行为。**

因此 Acceptance Test **必须描述 `Given / When / Then`**，而不是"调用哪个函数 / 修改哪个变量 / 增加哪个结构体 / 使用哪个 API"。

**正确形**：

```gherkin
Given the number of available NAND blocks is below the critical threshold
When the firmware evaluates host-write permission
Then new host writes shall be blocked
```
**错误形**：`调用 FlowControl_Evaluate()` / `检查 g_free_block_count` / `返回 FLOW_BLOCK`——"后者已经进入 Implementation Design"。
## 7.3 Comet Stage Comet 阶段

服务 **`open` 节点（phase `open`）**。产物被后续阶段持续使用：

```text
open ── Acceptance Criteria / Acceptance Scenarios / Acceptance Tests
  → design → test design → build → verify
```
| 项（总体设计 §4.2） | 内容 |
|---|---|
| 目标 | intake 用户请求、选择 change 形态、初始化 Comet state，并把 Frozen Story 镜像为 OpenSpec 产物 |
| 产物 | OpenSpec `proposal.md`、`specs/**/spec.md`（**均为镜像，非权威**）、`.comet.yaml` |
| Schema | `comet.intake.v1` |
| guard | `.comet.yaml exists`（state-transition） |
## 7.4 Trigger 触发

| 场景 | 条件 | 强制动作 |
|---|---|---|
| 首次触发 —— 新需求 | `User Story` / `Requirement` / `Feature Request` / `Change Request` | 调用本 Skill |
| 触发 —— 需求不完整 | 例"增加 GC 期间 Host Write Flow Control" | **不能直接进入 `design`，必须先需求澄清** |
| 触发 —— 需求有歧义 | 例"系统资源不足时限制 Host Write" | 必须明确：什么叫资源不足？阈值多少？是否立即限制？已执行的 IO 怎么处理？什么时候恢复？是否允许特殊 IO？是否存在多个状态？ |
## 7.5 Inputs 输入

```text
User Story / Requirement / Existing Acceptance Criteria / Existing Acceptance Test
Change Request / Product Requirement / Software Module Design / Existing System Behavior
```
若已有代码，可通过 CodeGraph 查询 `Existing behavior` / `State machine` / `Data flow` / `Dependency` / `Call graph` / `Existing interfaces`。

**输入硬约束**：

> **CodeGraph 只能用于理解 Existing System Behavior，不能让现有代码自动成为新需求的定义。**
## 7.6 Outputs 输出

```text
comet-artifacts/requirements/         # 权威（Stage 0-a）
├─ requirement.md  ├─ acceptance-criteria.md  └─ acceptance-tests.md

<openSpecRoot>/changes/<change>/      # 镜像（非权威），位置见总体设计 §8.2
├── proposal.md  └── specs/**/spec.md
```
**输出至少必须包含**：`Requirement IDs` / `Acceptance Criteria IDs` / `Acceptance Test IDs` / `Traceability` / `Open Questions` / `Human Decisions`。

**产物权威裁决**（总体设计 §8.1/§8.3）：`proposal.md` 与 `specs/**/spec.md` 均为**镜像**，权威在需求基线（Stage 0-a）。源文档的 `openspec/<change>/requirements.md` / `acceptance-tests.md` 不是 Comet 原生产物名，本册不采用。
## 7.7 Overall Workflow 总体流程

```text
Understand User Intent → Identify Ambiguity（六类）→ Requirement Clarification
  → Acceptance Criteria → 八类 Categories 检查 → Acceptance Scenario
  → Acceptance Test（契约形状）→ Behavior-First 校验
  → Legacy: Existing Code Analysis + Characterization
  → AT ↔ UT 关系 + Verification Level → Traceability → Completeness Check
  → ★ Human Approval →（open → design）
```
## 7.8 Steps 步骤

| Step | 动作 | 强制规则 |
|---|---|---|
| Step 1 — Understand User Intent | 识别 `What` / `Why` / `Who` / `When` / `Expected Behavior` / `Constraints` | **不要直接开始设计代码** |
| Step 2 — Identify Ambiguity | 逐类检查六类歧义（见 §7.9.1） | 歧义未消除不得进入下一步 |
| Step 3 — Requirement Clarification | `Requirement → Open Questions → Human Interaction → Clarified Requirement` | **Agent 不得自行猜测关键行为** |
| Step 4 — Acceptance Criteria | 每条 AC 满足 Specific / Observable / Testable / Unambiguous / Traceable | AC 不得不可验证 |
| Step 5 — 八类 Categories 检查 | Normal / Boundary / Negative / Error / Recovery / State Transition / Timing / Concurrency | 至少检查全部八类 |
| Step 6 — Acceptance Scenario | 每个重要 AC 至少一个 Scenario，GWT 描述 | 必要时用 `And` / `But` |
| Step 7 — Acceptance Test | 按 test contract 形状产出 `AT-` 契约 | **豁免**：Open 阶段不要求知道 function/file/mock/test framework |
| Step 8 — Behavior-First 校验 | `Requirement → Behavior → Acceptance Test` | **禁止** `Existing Function → Test Function → Requirement` |
| Step 9 — Legacy Existing Code Analysis | 用 CodeGraph/OpenViking/graphify 调查既有行为 | **必须区分 Existing Behavior 与 Required Behavior** 并显式记录来源 |
| Step 10 — Legacy Characterization | `Existing Behavior → Characterization Test → Baseline` | 记录当前实际行为；`Existing != Required` 时必须记录 Behavior Change；不能让 Coding Agent 偷偷改测试适配旧行为 |
| Step 11 — AT 与 TC 关系 | `AC → AT → Design → Behavioral Test Design → TC（按 Verification Level 取七级之一）` | **禁止假设 `AC = UT`**；禁止强制 `AC-001-01 → AT-001-01 → TC-001-01` |
| Step 12 — Verification Level | 判定 `Verification Level ∈ {UNIT, COMPONENT, INTEGRATION, SIMULATOR, HARDWARE, INSPECTION, MANUAL}` | **不能规定所有需求都必须 `UNIT`** |
| Step 13 — Traceability | `REQ → AC → AT → Design → Test Design → Build → Verification` | 每个 Requirement 至少可追到 AC；AC 可追到 AT |
| Step 14 — Completeness Check | 六维检查（Functional / State / Timing / Concurrency / Hardware / Traceability） | 见 §7.9.5 |
## 7.9 Key Enumerations & Matrices 关键枚举与矩阵
### 7.9.1 六类歧义（闭集）
| 类别 | 检查问题示例 |
|---|---|
| Functional | 什么时候触发？什么时候结束？ |
| Boundary | 阈值是 `< 10` 还是 `<= 10`？ |
| State | `NORMAL → BLOCKED` 之后，什么时候 `BLOCKED → NORMAL`？ |
| Error | 资源分配失败怎么办？ |
| Timing | 必须立即生效还是下一次 IO 生效？ |
| Hardware | DMA 正在运行时是否允许进入新的状态？ |
### 7.9.2 AC 质量五属性（闭集）
`Specific` / `Observable` / `Testable` / `Unambiguous` / `Traceable`。

AC 契约形状：

```yaml
id: AC-001-01          # 源作 AC-FC-001，统一后见本册 §1.3
given: [free_blocks <= critical_threshold]
when:  [host_write_request_arrives]
then:  [host_write_acceptance: BLOCK]
```
### 7.9.3 Acceptance Criteria 八类（至少检查）
| # | 类别 | 内容 / 示例 |
|---|---|---|
| 1 | Normal Behavior | 正常输入、正常状态、正常流程 |
| 2 | Boundary | `threshold - 1` / `threshold` / `threshold + 1` |
| 3 | Negative | invalid request / invalid state / resource unavailable |
| 4 | Error | NAND error / DMA failure / mapping failure / queue failure |
| 5 | Recovery | `BLOCKED → resources recovered → NORMAL` |
| 6 | State Transition | `NORMAL → WARNING → CRITICAL → RECOVERING → NORMAL` |
| 7 | Timing | latency / timeout / periodic behavior / deadline / ordering |
| 8 | Concurrency | interrupt / ISR / main loop / DMA callback / background task / host IO / GC（ARM firmware 特别检查） |
### 7.9.4 Verification Level 七级
| Level | 用途 |
|---|---|
| `UNIT` | 纯逻辑、状态机、策略判定 |
| `COMPONENT` | 组件内交互 |
| `INTEGRATION` | 跨组件/驱动交互 |
| `SIMULATOR` | 需要时序/中断语义但无硬件 |
| `HARDWARE` | 真实寄存器 / PHY / 功耗 / 实际时序 |
| `INSPECTION` | 用于不可执行的静态约束；四项判定式见 SKR-6（99 D20、99 D21） |
| `MANUAL` | 人工验证 |
本册统一采用以上 **7 级**；④ 章与 ⑧ 章使用同一枚举与同一语义。
### 7.9.5 Completeness Check 六维矩阵
| 维度 | 检查项 |
|---|---|
| Functional | normal behavior / boundary / negative / error / recovery |
| State | state transition / invalid transition / recovery transition |
| Timing | timeout / latency / ordering |
| Concurrency | interrupt / concurrent IO / background task / DMA |
| Hardware | hardware boundary / register behavior / reset behavior |
| Traceability | Requirement → AC / AC → AT |
### 7.9.6 Acceptance Test 契约形状
```yaml
test_id: AT-001-01
acceptance_refs: [AC-001-01]
preconditions: [firmware initialized, flow control enabled]
stimulus: [free block count reaches critical threshold, host write request arrives]
expected_behavior: [host write is blocked or deferred, no invalid NAND operation is issued]
postconditions: [firmware remains in valid flow-control state]
```
**明确豁免**：Acceptance Test **不要求**在 `open` 阶段已经知道 `function name` / `file name` / `mock framework` / `test framework`。
### 7.9.7 AT ↔ UT 映射规则
```text
AC → AT → Design → Behavioral Test Design → TC（用例统一前缀；验证层级由 level 承载，取七级之一）
允许 1 AC → multiple AT，1 AT → multiple UT
例: AC-001-01 → AT-001-01 → {TC-001-01, TC-001-02, TC-001-03}
```
## 7.10 Hard Rules 硬规则（`SR-1`…`SR-7`，全部）

**编号口径（总体设计 §5.1.2）**：源文档的 `Rule 1–7` **改名为 `SR-1..SR-7`（Skill Rules）**，避免与分册 01 §28 的 `FR-1..FR-5` 同号不同义。总体设计 §5.1.2 同时规定三套编号并存：

```text
FR-1..FR-5  五条正式规则（Formal Rules）       — 分册 01 §28（唯一权威文本）
SR-1..SR-7  Skill 侧附加规则（Skill Rules）    — 本册各 Skill 的 Hard Rules（本节为 ③ 的 7 条）
SYS-1..SYS-7 跨 Skill 体系级规则               — 本册 §3
```

```text
SR-1 — No hidden assumptions
       关键业务行为不得由 Agent 自行假设

SR-2 — Behavior before implementation
       Acceptance Test 必须描述行为，而不是代码结构

SR-3 — No function binding
       design 阶段禁止出现 Function = xxx()；函数映射在 plan 节点建立（总体设计 §5.1；分册 01 §6.6）

SR-4 — No self-defined requirements
       Agent 不得根据代码自行创造新 Requirement

SR-5 — No test-contract manipulation
       不能为通过测试而修改 Acceptance Criteria / 修改 Expected Behavior
       / 删除 Test Case / 降低测试要求，除非需求或设计经过正式 Review

SR-6 — Legacy behavior must be distinguished
       必须明确 Existing Behavior vs Required Behavior

SR-7 — Every requirement needs verification intent
       每个 Requirement 最终必须能回答：How will we know this requirement is satisfied?
```

**与 `SYS-*` 的语义对应（不构成层级裁决）**：`SR-3` 对应 `SYS-1`、`SR-4`+`SR-5` 覆盖 `SYS-2`、`SR-6` 覆盖 `SYS-3`、`SR-7` 覆盖 `SYS-5`；这是**语义对照**，不是"从属关系"。

**编号层级（99 D14）**：`FR-1`–`FR-5` 是正式规则层（分册 01 §28）；`SYS-*`（本册 §3）与 `SR-*`（各 Skill 的 Hard Rules）是该层的**执行细则**，不与之并列。冲突消解顺序固定为 `FR-*` > `SYS-*` > `SR-*` > 具体 Skill Steps（上位优先），同层内才"更具体者优先"；**三套编号不得混用，禁止裸用 `Rule N`**。
## 7.11 Forbidden Behaviours 禁止行为

```text
❌ 假设 AC = UT，或强制 `AC-001-01 → AT-001-01 → TC-001-01` 一对一映射   ❌ 通过函数名反向定义需求（Existing Function → Test Function → Requirement）
❌ 在 open 阶段要求 Function = xxx()、文件名、mock 框架或测试框架   ❌ Agent 自行猜测关键业务行为，代替 Human Decision   ❌ 用"正常""正确""合适"等不可验证措辞描述 Then
❌ 让 Coding Agent 偷偷修改测试来适配旧行为   ❌ 把 CodeGraph 查询结果当作新需求的定义   ❌ 规定所有需求都必须 `UNIT`   ❌ 允许 AC 缺少可观察通过条件或缺少显式关联 Scenario
❌ 仅依赖 Line/Branch Coverage 作为完成依据
```
## 7.12 Failure Contract 失败契约

| 失败情形 | 输出 | 路由 | 阻断 |
|---|---|---|---|
| 需求不完整 | Open Questions 清单 | **必须先需求澄清**，不得进入 `design` | 阻断 `open` 完成 |
| 需求有歧义 | 六类歧义检查表 | 消除歧义后才进入 Step 4 | 阻断 |
| 关键行为无法确定 | `Human Decision` 请求 | Human Interaction | 阻断 |
| 需求冲突 / AC 无法覆盖 | — | 回流 Stage 0（总体设计 §9.2） | 阻断 |
| `design` 阶段发现需求错误或不完整 | — | `ufs-design` 报 `DESIGN_BLOCKER`，停止（总体设计 §9.2） | 阻断 |
| 六维 Completeness Check 未过 | — | 回 Step 4–12 补全 | 阻断 Human Approval |
## 7.13 Agent Responsibilities Agent 职责

| 源角色 | 映射到 13 名册 | 职责 |
|---|---|---|
| Main Developer Agent（旧称，废弃） | **`ufs-main`** | 启动 ATDD、协调用户、调用 Exploration、调用 Review、提交 Human Gate |
| Exploration Agent（旧称，废弃） | **`ufs-exploration`** | 发现歧义、分析影响范围、调查 Existing Behavior、提出 Clarification Questions |
| Review Agent（旧称，废弃） | **`ufs-document-review`** | 检查 Requirement completeness / Acceptance completeness / Ambiguity / Traceability / Contradiction / Missing boundary / Missing error-recovery |
| Domain/Firmware Expert（旧称，废弃） | **`ufs-firmware-expert`** | 硬件/协议约束事实 |
| （设计补全） | **`ufs-design`** | Design Agent 在下游消费 AC/AT；本 Skill 的输出是 `design` 节点的输入，须在交付时标注 Design 消费者 |
**受控性质**（总体设计 §6.1）：只有 `ufs-main` 持有生命周期状态；其余为窄职责 subagent。
## 7.14 Tool Usage 工具使用

| 工具 | 用途 | 约束 |
|---|---|---|
| CodeGraph | Call Graph / Dependency / State Machine / Existing Behavior / Affected Components | **不能用于定义新需求**= SYS-4 |
| OpenViking | 历史需求 / 企业规范 / 已有设计 / 过去类似 Feature / 历史 Bug / 经验 | 知识查询必须带 provenance（总体设计 §11.3） |
| graphify | 跨文件关系聚合（CodeGraph 无结果时的补充查询） | 优先级已裁定（99 D64）：CodeGraph 优先；一次查询中两者不得同时调用 |
| OMO | `open` 阶段 Team Mode：Main + Exploration + Domain/Firmware Expert + Review | **本 Skill 不负责定义 OMO 通信协议** |
## 7.15 Human Gate 人工门禁

Open 阶段结束前 **★ Human Approval**，至少确认：

```text
★ Acceptance Criteria
★ Acceptance Scenarios
★ Acceptance Tests
★ Major assumptions
★ Open Questions
★ Behavior changes
```
**规则**：只有 Human Approval 后才允许 `open → design`。
## 7.16 Definition of Done 完成定义

```text
[ ] User intent understood / Requirements identified / Ambiguities resolved
[ ] Acceptance Criteria defined / Acceptance Scenarios defined / Acceptance Tests defined
[ ] Boundary cases considered / Error-recovery considered / State transitions considered
[ ] Concurrency considered where applicable / Hardware boundary considered where applicable
[ ] Verification level identified   [ ] Requirement → AC → AT traceability established
[ ] Existing vs Required behavior distinguished   [ ] Human approval obtained
```
只有满足以上条件才能进入 `design`。
## 7.17 Relationships with Other Skills 与其他 Skill 的关系

```text
atdd-development ─┬→ ufs-test-design
                  └→ Design → ufs-writing-plans → ufs-tdd → ufs-verification

ATDD          "What must the system do?"
Test Design   "How should that behavior be verified?"
Writing Plans "What implementation work must be performed?"
TDD           "How do we implement it safely?"
Verification  "How do we prove it is correct?"
```
| 关系 | 内容 |
|---|---|
| 上游 | ② `ufs-challenge` 冻结后的 Story/AC/Scenario |
| 下游 | ④ `ufs-test-design`（consumes AC + AT）、`ufs-design`（consumes AC/AT） |
| 回流 | `design` / `build` / `verify` 发现需求问题 → 回流 Stage 0 |
| 边界 | ③ 定义"必须实现什么行为"；④ 定义"这些行为如何被证明"；**两者都不负责告诉 AI 具体修改哪个函数** |
## 7.18 Final Principle 最终原则

> **先定义可观察行为，再讨论实现。**

```text
Human Intent → ATDD → Behavior Contract → Design → Test Design → Implementation → Verification
```
AI 可以帮助完成大量分析和产物生成，但 `Requirement` / `Acceptance Criteria` / `Behavior Change` / `Test Contract` **这些决定不能由 Coding Agent 在没有授权的情况下自行修改**。

---
# 8. Skill ④ `ufs-test-design`
## 8.0 元信息头

**元信息**: `name`=ufs-test-design · `serves`=phase design / node design（Step 2） · `executing_agent`=ufs-test-design · `gate_agent`=ufs-document-review · `output_schema`=comet.design.v1 · `write_path`=<superpowersRoot>/specs/test-design.md（位置见主文档 **§8.3** 产物所有者表；schema 槽位待 `EXT-04`） · `presets`={full: 完整, tweak: 跳过, hotfix: 跳过} · `status`=exists
**命名裁定**：备选 `test-design`，最终选 `ufs-test-design`，因为"平台最终是 Firmware 专用平台"。
## 8.1 Purpose 目的

用于 Comet **`design` 节点**，把 `Acceptance Criteria + Acceptance Tests + Implementation Design + Existing Firmware Behavior + CodeGraph 信息 + UFS/Firmware 技术约束` 转换为**与实现解耦的 Behavioral Test Design**。

```text
Acceptance Criteria → Acceptance Test → Behavioral Test Design
→ Verification Strategy → TC（用例统一前缀；验证层级由 level 承载，取七级之一）
```
**本 Skill 不负责具体代码实现。** 体系层输出**共 16 项**（权威清单 = `test-design.md` 的 16 项，见 §8.6；体系层摘要行曾只列 12 项且用词不同，不是权威清单）：`Test Scope` / `Verification Strategy` / `Verification Level` / `Unit Boundary` / `Observable Behavior` / `Test Scenarios` / `UT Case Matrix` / `Boundary Analysis` / `State Transition` / `Error-Recovery` / `Dependency Interaction` / `Mock-Stub Strategy` / `Testability Analysis` / `Characterization Test` / `Requirement Traceability` / `Coverage / Exit Criteria`。

## 8.2 Core Principle 核心原则

> **Design 阶段设计行为，不设计函数级测试实现。**

Design 阶段**不要求知道**：具体函数名 / 具体文件 / 具体测试框架 / 具体 Mock API / 具体测试代码。而应描述：什么行为必须验证、什么输入必须覆盖、什么状态必须覆盖、什么边界必须覆盖、什么错误必须覆盖、什么依赖交互必须验证、什么验证层级最合适。

```yaml
# 允许
test_id: TC-001-01
given:  {free_blocks: below_critical_threshold}
when:   host_write_request_arrives
then:   {host_write_permission: BLOCK}
# 禁止：Test FlowControl_Evaluate()
```
体系层把这条称为"**Test Design Skill 最重要的一条规则**"，并规定**`design` 阶段禁止出现 `FlowControl_Evaluate()` 这类函数名；只允许在 `plan` 节点的 Build Mapping 中出现**（总体设计 §5.1）。
## 8.3 Comet Stage Comet 阶段

服务 **`design` 节点（phase `design`）**，是 `design` 节点 **Step 2**（Step 0 = `ufs-exploration`，Step 1 = `ufs-design`）。

| 项（总体设计 §4.3） | 内容 |
|---|---|
| 目标 | 把确认过的请求转成设计产物与 OpenSpec delta context |
| 承担 Agent | Step 0 `ufs-exploration`；Step 1 `ufs-design`；**Step 2 `ufs-test-design`** |
| 产物 | `design.md` / Design Doc（技术决策权威）、**`test-design.md`（验证契约权威）** |
| Schema | `comet.design.v1` |
| Human Gate | 架构批准、验证策略批准 |
| 禁止项 | 不重定义用户可见行为；需求错误或不完整时 `STOP` 并报 `DESIGN_BLOCKER` |
## 8.4 Trigger 触发

| 类型 | 条件 | 强制动作 |
|---|---|---|
| 首次触发 | `design` 节点进入 **Step 2**，且 Step 1 已产出 `design.md`、`open` 已产出 AC + AT | 调用本 Skill |
| 重跑触发 | `design.md` 变更（架构/边界/接口/状态模型） | 重跑并更新 `test-design.md` |
| 重跑触发 | AC / AT 实质变更 | 重跑 |
| 重跑触发 | Testability 反馈导致 Design Revision | 重跑 |
| **不触发** | `tweak` / `hotfix` preset（`design` 节点被跳过） | 由 ⑤ 在 `plan` 节点轻量补做 Verification Level（总体设计 §4.9、本册 §4.2） |
## 8.5 Inputs 输入

**必须优先读取**：

```text
requirements.md / acceptance-criteria.md / acceptance-tests.md / proposal.md / design.md
+ CodeGraph / OpenViking / graphify
```
**可选**：Existing Test Cases / Existing Test Results / Historical Bugs / Characterization Tests / Coding Standards / Hardware Constraints。

**输入硬约束**：行为必须能追溯到 AC（Step 1 强制规则）。
## 8.6 Outputs 输出

**核心产物**：`test-design.md`，交给 ⑤ `ufs-writing-plans`。**物理位置**：`<superpowersRoot>/specs/test-design.md`（`<superpowersRoot>` 恒为 `docs/superpowers/`，唯一权威见主文档 **§8.2/§8.3**）。

**必要时附加**：`test-matrix.yaml` / `characterization-test-plan.md`（同为 `<superpowersRoot>/specs/` 下的派生视图）。**`traceability.yaml` 不在此列**——追溯关系的唯一序列化载体是 `comet-artifacts/traceability/traceability.yaml`（`99 D09`），路径与格式均不得改写。

`test-design.md` **至少包含 16 项**：

```text
Test Scope / Verification Strategy / Verification Level / Unit Boundary / Observable Behavior
Test Scenarios / UT Case Matrix / Boundary Analysis / State Transition / Error / Recovery
Dependency Interaction / Mock / Stub Strategy / Testability Analysis / Characterization Tests
Requirement Traceability / Coverage / Exit Criteria (design 部分)
```
**`non_testable[]` 契约（第 13 项 Testability Analysis 内的必填块；`99 D22` / 分册 01 `MR-9`；`H03` 的"审批齐备"按此判定）**：

```yaml
non_testable:
  - item_id: DES-001-05            # 被声明为不可测的对象（DES-* / BEH-*）
    reason: <为什么无法建立可执行验证>   # 必填，不得写 "hard to test"
    alternative_verification_level: INSPECTION | MANUAL   # 必填，只能取这两级之一
    approver: <项目架构负责人>       # 必填；角色未指派时按主文档附录 C `EXT-12` 一律 BLOCK
    decision_ref: DEC-001           # 必填；Human 决策记录 ID（`DEC-*`）
```

**五字段缺一不可**：`item_id` / `reason` / `alternative_verification_level` / `approver` / `decision_ref`。**无不可测项时必须写 `non_testable: []`**，不得省略该键（否则 H03 视为"缺失"而非"无"）。`full` preset 下由 `test-design.md` 持有；`tweak` / `hotfix` 下由 `build-plan.md` §17 持有（字段名相同）。
**`Verification Strategy` / `Verification Level` 两节的机器可读形态**：按分册 01 §9.4 的 `verification_strategy` 契约填写，**每行必须含 `behavior_id`**（`BEH-<STORY>-<SEQ>`，定义见分册 01 §9.0）与 `levels[]`（七级枚举，可多级）。

`BEH-*` 是「行为 → 验证层级 → 回归等级 → 测试用例 → Build Task」链条的**引用锚点**；其**枚举域穷举**为三条来源——Stage 0 的 AC、Scenario、以及 `design` 阶段由 Testability 分析或 Design Constraint 识别出的内部行为。**`verification_strategy` 不得出现无来源的行。**

**测试用例 ID 口径**：`UT-` / `IT-` 是 `TC-` 在 `UNIT` / `INTEGRATION` 层的历史别名，新产物统一用 `TC-`（分册 01 §9.0）；本册 §8.9 的 `UT-*` 示例按此口径理解。

**不一致记录**：附加产物与体系层 openspec 目录（只列 `test-design.md`）不一致。本册裁定：`test-design.md` 为**唯一权威**，附加 YAML 为**可选的机器可读派生视图**，不得与 `test-design.md` 冲突；权威所有者仍为 `design` 节点（总体设计 §8.2）。
## 8.7 Overall Workflow 总体流程

```text
Acceptance Criteria → Understand Behavior → Identify Verification Level → Define Test Boundary
→ Identify Observable Behavior → Analyze Input Domain → Boundary Analysis
→ State Transition Analysis → Error / Recovery Analysis → Dependency Interaction
→ Testability Analysis → Characterization Test → UT Case Matrix → Traceability
→ Coverage / Exit Criteria → Review → Human Approval
```
## 8.8 Steps 步骤

| Step | 动作 / 产物 | 强制规则 |
|---|---|---|
| Step 1 — Understand Acceptance Behavior | 读 REQ/AC/AT，建立 `Requirement → AC → Acceptance Behavior`，提取 Input / Stimulus / Expected Behavior | 行为必须能追溯到 AC |
| Step 2 — Determine Verification Level | 第一个重要决策，选 7 级之一（§8.9.2） | **不能默认所有行为都使用 Unit Test** |
| Step 3 — Define Test Boundary | 边界可为 State Machine / Decision Logic / Resource Manager / Queue Manager / Mapping Logic / Error Handler / Scheduler / Protocol Handler | **Test Boundary 不等于函数**；写成 `Flow Control Boundary` 而非 `FlowControl_Evaluate()` |
| Step 4 — Observable Behavior | 每个测试必须有 Input / Stimulus / Observable / Expected | 固件尤重 state transition / queue mutation / resource ownership / error classification / retry decision |
| Step 5 — Input Domain Analysis | 等价类 + 边界（§8.9.4） | 必须识别 Normal / Boundary / Invalid / Extreme；**不要求每一个整数都测试** |
| Step 6 — State Transition Analysis | `Current State → Event → Next State → Observable Effect` + 非法转换 | 不仅测合法转换；哪些合法、哪些非法必须明确 |
| Step 7 — Error Analysis | Error Matrix | **不能只设计 Happy Path** |
| （专项）| Recovery / Concurrency / Interrupt / Timing / Resource / Dependency（§8.7 表） | 见 §8.9.6 |
| （Mock）| **替身**：Mock / Stub / Fake / Spy / Real；**执行环境（独立维度）**：Simulator / Hardware 选择 | **不要简单要求所有依赖都 Mock** |
| （Testability）| 反向检查"当前 Design 是否足够可测试" | 若 `Behavior cannot be isolated`，必须反馈 `TESTABILITY ISSUE` |
| （Characterization）| Legacy 模式下设计 Characterization Test | 禁止直接删除；更新测试契约必须经 Review |
### 8.8.1 Step 2 推荐映射表
| 被测对象 | 层级 | 被测对象 | 层级 |
|---|---|---|---|
| Pure Logic / State Machine / Policy-Decision | Unit Test | DMA | Integration / Simulator / HW |
| Queue Management | Unit / Component | PHY | Hardware |
| Driver Interaction | Component / Integration | Interrupt Timing | Simulator / Hardware |
| — | — | Power Sequence | Hardware |
**Verification-Level Rule（原文）**：

> **What is the lowest practical verification level that can reliably prove this behavior?**

示例裁定：`Flow Control Decision` → 可以 Unit Test；`DMA Register Programming` → **不能仅依赖 Unit Test**，须分层 `Unit: logic around DMA request` / `Integration: DMA interaction` / `Hardware: actual DMA behavior`。
### 8.8.2 Unit Boundary 契约形状
```yaml
unit_boundary:
  name: Host Write Flow Control Logic
  responsibility: [determine whether host writes are permitted]
  included_behavior: [threshold evaluation, state transition, recovery decision]
  excluded_behavior: [NAND programming, DMA programming, hardware register access]
```
原文注：这会**直接影响后续 Build 阶段的代码结构**。
## 8.9 Key Enumerations & Matrices 关键枚举与矩阵
### 8.9.1 Verification Level 七级
`UNIT` / `COMPONENT` / `INTEGRATION` / `SIMULATOR` / `HARDWARE` / `INSPECTION` / `MANUAL`（语义同 §7.9.4；统一采用全大写规范值）。
### 8.9.2 等价类与边界
```text
等价类示例 free_blocks:
  A: > threshold   B: == threshold   C: < threshold   D: == 0   E: invalid value
边界: threshold-1 / threshold / threshold+1
多阈值: warning-1, warning, warning+1 / critical-1, critical, critical+1 / recovery-1, recovery, recovery+1
```
### 8.9.3 专项分析枚举（Recovery / Concurrency / Interrupt / Timing / Resource / Dependency）
| 分析 | 必须检查 / 必须回答 |
|---|---|
| State Transition 矩阵 | `state_tests: [{current: NORMAL, event: resource_low, expected_result: WARNING}, {current: WARNING, event: resource_critical, expected: BLOCKED}, {current: BLOCKED, event: resource_recovered, expected: NORMAL}]` |
| Recovery | Firmware 最容易遗漏的是 Recovery。每个重要错误必须回答：进入什么状态？哪些资源需释放？是否允许 retry？retry 次数？什么时候恢复？是否需要 reset？是否通知 Host？ |
| Concurrency | Main Loop / ISR / DMA / Host IO / GC / Background Task / Timer / Completion Callback；必须定义 ordering / atomicity / race behavior / priority / serialization |
| Interrupt | `before / during / after interrupt`；`ISR modifies state` + `Main loop observes state`；判断是否需要 atomic operation / critical section / memory barrier / lock / disable interrupt |
| Timing | timeout / latency / deadline / periodic timer / retry interval / ordering。**硬规则：如果需求没有给出具体时间，不允许 Agent 自己编造一个数字，必须形成 `Open Question`** |
| Resource Exhaustion | Memory / Queue / NAND Blocks / DMA Descriptor / Request Entry / Mapping Entry / Timer / Context；对 `queue full` 必须明确 `reject? / block? / drop? / retry? / backpressure?` |
| Dependency Interaction | NAND / DMA / Scheduler / Queue / Resource Manager / Timer / Interrupt / Hardware Register；建立 `Dependency → Interaction → Expected Behavior` |
### 8.9.4 Mock / Stub / Fake 策略
| 依赖类型 | 策略 | 依赖类型 | 策略 |
|---|---|---|---|
| Pure logic | No Mock | NAND interface | Fake / Mock |
| DMA | Fake + Integration Test | Hardware Register | Simulator / Hardware |
### 8.9.5 UT Case Matrix（核心矩阵）
**列契约唯一权威 = 分册 01 §25.3 第 7 节**：`ID / Category / Input / Expected / refs`（5 列，`refs` 必填）。本册早期版本的 `Behavior / Boundary / Type` 列**已撤回**。

| ID | Category | Input | Expected | refs |
|---|---|---|---|---|
| TC-001-01 | Normal | resource high | ALLOW | `AC-001-01` / `BEH-001-01` |
| TC-001-02 | Boundary | resource = threshold | BLOCK | `AC-001-02` / `BEH-001-03` |
| TC-001-03 | Boundary | resource < threshold | BLOCK | `AC-001-02` / `BEH-001-03` |
| TC-001-04 | Recovery | resource recovered | RECOVERY | `AC-001-04` / `BEH-001-05` |
| TC-001-05 | Negative | invalid transition | ERROR | `DES-001-02` / `BEH-001-06` |
原文注：**这里仍然不要求函数名**。ID 已按本册 §1.3 统一（源作 `UT-FC-001`）。
### 8.9.6 Test Case Independence 与 State Sequence Test
每个 Test Case 必须尽可能 `Independent` / `Deterministic` / `Repeatable` / `Observable`；避免 `TC-001-02 depends on TC-001-01`，**除非测试本身明确属于 State Sequence**：

```text
TC-001-01（case_type: state_sequence）: NORMAL → WARNING → CRITICAL → RECOVERING → NORMAL
```
### 8.9.7 Acceptance → Test Design 映射（禁止 1:1 强制映射）
```text
AC-001-01 → AT-001-01 → Test Design ─┬── TC-001-01 / TC-001-02 / TC-001-03
                                     └── TC-001-08
同时 Design Constraint → TC-001-04
```
UT 可以来自：`Acceptance + Design Constraint + Robustness + Error Handling + Safety + Implementation Invariant`。
### 8.9.8 Coverage Dimensions 与 Coverage Matrix
```text
不能用 Line/Branch Coverage 代替：Requirement / Behavior / State / Boundary / Error / Recovery
/ Concurrency / Timing Coverage；Firmware 还应考虑 Hardware Boundary Coverage
```
| Dimension | Required | Dimension | Required |
|---|---:|---|---|
| Requirement | 已统计并列出未覆盖项 | Recovery | Yes |
| Acceptance | 已统计并列出未覆盖项 | State Transition | Yes |
| Normal Behavior | Yes | Concurrency | If applicable |
| Boundary | Yes | Timing | If applicable |
| Error | Yes | Hardware Boundary | If applicable |

**硬规则（99 D24 / `SKR-8`）**：`Requirement` / `Acceptance` 两行**不设百分比阈值**；要求是“**已统计并列出未覆盖项**”，不是“达到 100%”。覆盖率只作观测指标，**不得**作为门禁通过条件、归档必要条件，也**不得**写入任何 Skill 的 Exit Criteria；DoD 为行为 ↔ 证据对齐（每个 P0/P1 行为有对应层级的验证证据）。

## 8.10 Hard Rules 硬规则

| # | 规则 | 可检查点 |
|---|---|---|
| TD-1 | 行为必须能追溯到 AC | 每个 test item 有 `acceptance_refs` |
| TD-2 | 不能默认所有行为都使用 Unit Test | 每个行为有显式 Verification Level |
| TD-3 | Test Boundary ≠ 函数（SYS-1） | 无函数名 |
| TD-4 | 每个测试必须有 Input / Stimulus / Observable / Expected | 四元组齐全 |
| TD-5 | 必须识别 Normal / Boundary / Invalid / Extreme；不要求每个整数都测 | 等价类与边界齐 |
| TD-6 | 不仅测合法转换，非法转换也必须明确 | State Transition 表含非法项 |
| TD-7 | 不能只设计 Happy Path | Error Matrix 存在 |
| TD-8 | Timing 无明确需求时间时**不得编造数字**，必须形成 `Open Question` | Timing 项有来源 |
| TD-9 | 不强制 `AC-001-01 = TC-001-01` 映射 | 允许 1:N / N:1 |
| TD-10 | Testability 不足必须反馈 `TESTABILITY ISSUE`，**不得强行设计复杂 Mock** | Testability 章节存在 |
| TD-11 | 禁止直接删除 Characterization Test；更新测试契约必须经 Review | Characterization 记录 |
| TD-12 | Test Failure 必须按四类区分；本 Skill 负责确保 Test Contract 清晰 | Failure Contract |
| TD-13 | `verification_strategy` 每行必须有 `behavior_id`；每个 `BEH-*` 至少一个验证层级且无空缺（分册 01 §9.2 硬规则、§9.4 契约） | 逐行 `behavior_id` 非空；`BEH-*` 闭包无空缺 |
## 8.11 Forbidden Behaviours 禁止行为（11 条，全部）

```text
❌ 为了方便测试修改需求          ❌ 为了覆盖率删除困难 Case   ❌ 把所有代码强制做 UT           ❌ 在 design 阶段强行绑定函数
❌ 用函数数量代替测试边界         ❌ 只测试 Happy Path   ❌ 忽略 Recovery                ❌ 忽略 State Transition
❌ 忽略 Interrupt/Concurrency    ❌ 忽略 Hardware Boundary   ❌ Coding Agent 自己修改 Test Contract
```
## 8.12 Failure Contract 失败契约

**四类失败区分**：

```text
Test Failure → Failure Analysis
必须区分: TEST_PROBLEM / CODE_PROBLEM / DESIGN_PROBLEM / ENVIRONMENT_PROBLEM
本 Skill 负责确保 Test Contract 清晰
```
**Design Feedback Loop（非单向流水线）**：

| 发现 | 回流目标 |
|---|---|
| `Requirement ambiguous` | 返回 `open`（③/Stage 0） |
| `Architecture cannot be tested` | 返回 `design`（`ufs-design`） |
| `Implementation detail missing` | 记录为 Build Plan Input（⑤） |
```text
open ↕ design ↕ test design
```
**Testability 回流链**：`Test Design → Testability Problem → Design Revision → Test Design Revision`，必要时 ★ Human Decision。

**契约缺口判据**：`verification_strategy` 的行**缺 `behavior_id`**，或某个 `BEH-*` **无任何层级**（空缺）⇒ 本 Skill 的输出判为 `NEEDS_REVISION`；对应分册 03 的 H02 **BLOCK**。
## 8.13 Agent Responsibilities Agent 职责

| 源角色 | 映射到 13 名册 | 职责 |
|---|---|---|
| Design Agent | **`ufs-design`** | Architecture / Component / Interface / State Model / Data Flow |
| Test Design Agent | **`ufs-test-design`** | Verification Strategy / Behavioral Test / UT Design / Boundary / State / Error / Recovery / Testability / Characterization / Traceability |
| Review Agent | **`ufs-document-review`** | Test completeness / Requirement coverage / Behavior coverage / Missing boundaries / Missing error-recovery / Testability / Traceability |
| （设计补全） | `ufs-exploration`（Step 0） | 提供 Existing Behavior / Affected Code 事实 |
| OMO Team | OMO | Design Agent + Test Design Agent + Firmware Expert + Review Agent 并行 |
## 8.14 Tool Usage 工具使用

| 工具 | 用途 |
|---|---|
| CodeGraph | Existing Unit Boundary / Call Graph / Dependency / State / Data Flow / Existing Test / Affected Code |
| OpenViking | Historical Test / Known Bugs / Past Verification / Coding Standards / Hardware Knowledge / Existing Test Strategy |
| graphify | Code relationship / Dependency exploration / Structure visualization |
**OMO Team Mode（`design` 阶段）**：可并行 Architecture Analysis + Testability Analysis + Existing Behavior Analysis，再由 `ufs-main` 汇总。

**约束**：CodeGraph 仅作 Existing Boundary 证据，不得用现有函数结构反推需求（SYS-4）。
## 8.15 Human Gate 人工门禁

至少人工确认：

```text
★ Verification Level   ★ Test Boundary   ★ Important Behaviors   ★ Error/Recovery
★ Hardware Behavior    ★ Testability Changes   ★ Characterization Strategy
```
特别是 `UT vs Integration vs Simulator vs Hardware` 的选择"属于重要工程判断"。
## 8.16 Definition of Done 完成定义

```text
[ ] Verification Level determined / Test Boundary defined / Observable Behaviors identified
[ ] Input domains analyzed / Equivalence partitions defined / Boundary cases defined
[ ] State transitions analyzed / Error paths analyzed / Recovery paths analyzed
[ ] Concurrency analyzed / Timing analyzed where applicable / Resource exhaustion analyzed
[ ] Dependency interactions analyzed / Mock-Stub strategy defined / Testability reviewed
[ ] Characterization strategy defined where required / UT Matrix created
[ ] Requirement Traceability created / Coverage criteria defined   [ ] Review completed / Human approval obtained
[ ] 每个 BEH-* 至少一个验证层级且无空缺（分册 01 §9.2 硬规则）
```
## 8.17 Relationships with Other Skills 与其他 Skill 的关系

| 关系 | 内容 |
|---|---|
| 与 ③ `atdd-development` | 输入 `Requirement / AC / AT` ⇒ `Acceptance → Verification Strategy → Behavioral Test`；链路 `atdd-development → ufs-test-design` |
| 与 ⑤ `ufs-writing-plans` | 本 Skill 输出 `Test Design / UT Matrix / Testability Constraints / Verification Strategy`；⑤ 输入 `Acceptance + Design + Test Design + CodeGraph`；链路 `Test Design → Implementation Boundary → Build Task` |
| **Build Plan Constraint** | 若声明"Flow control logic must be independently testable"，⑤ 应产生 `IMP-001-01 Extract flow-control decision logic` / `IMP-001-02 Define testable interface` / `IMP-001-03 Implement normal-critical-recovery behavior` / `IMP-001-04 Implement UT`，而**不是** `IMP-001-01 Implement feature` |
| **No Function Premature Binding** | `design`（含 `test-design.md`）**不得出现具体函数名**（总体设计 §5.1；SYS-1）。候选实现点只在 **`plan` 节点**记录为 `candidate_implementation_point`（`source: existing_code`）；**不能把 candidate function 直接变成 design requirement**；`required_interface` 必须由 `plan` 依据已批准 Design 显式给出 |
## 8.18 Final Principle 最终原则

> **Design 阶段不是设计「测试哪个函数」，而是设计「哪些行为必须被证明」。**

```text
ATDD → Acceptance Behavior → Test Design → Behavioral Test → Build → Function Mapping → Executable Test
```
它保证 AI 不会形成：

```text
AI 决定需求 → AI 决定设计 → AI 自己写代码 → AI 自己写测试 → AI 自己宣布通过
```
而是形成：

```text
Human Intent → ATDD Contract → Engineering Design → Independent Test Design
→ TDD Implementation → Independent Verification
```
---
# 9. Skill ⑤ `ufs-writing-plans`
## 9.0 元信息头

**元信息**: `name`=ufs-writing-plans · `serves`=phase build / node plan · `executing_agent`=ufs-build-plan · `gate_agent`=ufs-document-review · `output_schema`=comet.plan.v1 · `write_path`=<superpowersRoot>/plans/build-plan.md、<superpowersRoot>/plans/*.md、<openSpecRoot>/changes/<change>/tasks.md · `presets`={full: 完整计划, tweak: 简化任务清单, hotfix: 简化任务清单} · `status`=exists
## 9.1 Purpose 目的

用于 Comet **`plan` 节点**，把 `Acceptance Criteria + Acceptance Tests + Implementation Design + Behavioral Test Design + CodeGraph + Existing Firmware Code` 转换为 **Executable Build Plan**。

核心目标：

> **将「系统应该做什么」和「系统准备如何验证」转换成「开发者应该按什么顺序修改什么」。**

| 本 Skill **负责** | 本 Skill **不负责** |
|---|---|
| 实施边界、变更顺序、Build Task 契约、任务 DAG | 需求 / AC 的定义（①③） |
| 实现映射（Design → Component → File → Function） | 架构设计（`ufs-design`） |
| Change Impact / Regression Scope / CodeGraph Evidence | 验证策略（④ `ufs-test-design`） |
| 产出经 Human Gate 的 Build Plan | **实际代码修改（⑥ `ufs-tdd`）** |
## 9.2 Core Principle 核心原则

> **Build Plan 是 Implementation Plan，而不是 Test Case List。**

```text
错误: TC-001-01 → Task 1 / TC-001-02 → Task 2 / TC-001-03 → Task 3
正确: Define interface → Establish implementation boundary → Implement core behavior
      → Implement state transitions → Implement error/recovery → Implement dependency adapters
      → Implement tests → Run regression
```
因此 `Test Design → constrains implementation`，但 **`Test Case ≠ Build Task`**。体系层点明本 Skill 要解决的关键问题：**如何避免 Build Plan 退化成「一个 UT Case 一个 Task」**。
## 9.3 Comet Stage Comet 阶段

服务 **`plan` 节点（phase `build`）**。源文档的"Build Plan 阶段"一律表述为 **`plan` 节点**（主文档 §2.7）。

| 项（总体设计 §4.4） | 内容 |
|---|---|
| 目标 | 把 Design 转成可执行的工程修改计划与任务契约 |
| 输入 | Requirement / AC / AT / Design / Test Design / CodeGraph / 既有固件 |
| 承担 Agent | `ufs-build-plan` |
| 产物 | `plans/*.md`（实施计划）、`tasks.md`（**任务状态权威**）、**`build-plan.md`（契约权威，见 §9.6）** |
| Schema | `comet.plan.v1` |
| guard | plan artifacts（artifact-structured） |
| Human Gate | Build Plan 批准 |
| Task 规则 | 一个 Build Task 必须代表一个**工程实现步骤**；**不得把每个 UT case 直接转成一个 Build Task** |
```text
Comet: open → design → ★ plan → build → verify → archive

输入来源: ③ atdd-development → Acceptance Contract
          ufs-design       → Implementation Design
          ④ ufs-test-design → Behavioral Test Design
          CodeGraph        → Implementation Reality
输出:     ⑤ ufs-writing-plans → Build Plan
```
## 9.4 Trigger 触发

| 类型 | 条件 | 强制动作 |
|---|---|---|
| 首次触发 | `design` 节点完成（`design-complete` guard 通过）或 `open-complete` 直接进入 `build`（tweak/hotfix） | 调用本 Skill |
| 重跑触发 | Design / Test Design 实质变更 | 重跑并重建 Task DAG |
| 重跑触发 | Testability Constraint 变化 | 重跑 |
| 重跑触发 | 发现 `Design ≠ Existing Code` 且 Human 已裁决 | 重跑并记录裁决 |
| 重跑触发 | Human 驳回 Build Plan | 重跑并重新提交批准 |
| **必须触发** | 任何代码修改之前 | 无已批准 Build Task 时**不得进入 `execute`**（总体设计 I3） |
**轻量补做（tweak / hotfix）**：因 `design` 节点被跳过，④ 不运行，Verification Level 判定必须在本节点以轻量形式补做（总体设计 §4.9、本册 §4.2）。承载位置见 §9.8 Step 0。
## 9.5 Inputs 输入

**必须读取**：

```text
requirements.md / acceptance-criteria.md / acceptance-tests.md / design.md / test-design.md
必须查询: CodeGraph
必要时:   OpenViking / graphify / Existing Tests / Existing Build System
```
**Build Plan 生成之前必须建立**：

```text
Affected Components / Affected Files / Affected Functions / Call Graph
Dependency Graph / Existing Tests / Interface Boundaries / State Machine
链路: Requirement → Design Component → CodeGraph → Existing Implementation
```
**输入硬约束**：`Design ≠ Existing Code` 时**不得偷偷修改 Design**，必须 `Flag Conflict → Design Review → Human Decision`。

**测试用例的上游归属**：⑤ 的 Build Task 通过 `test_refs` 引用测试用例，而测试用例经 **`BEH-*`**（分册 01 §9.0）归属到行为；`test-design.md` 的 `verification_strategy` 是这条归属的权威来源（分册 01 §12.5）。
## 9.6 Outputs 输出

### 9.6.1 目录形状

```text
<superpowersRoot>/                        # 恒为 docs/superpowers/，不随 artifact_layout 变化（总体设计 §8.2）
├─ specs/
│  ├─ <canonical-design>.md               # ufs-design 产出：技术设计的唯一权威（Comet `design-doc`）
│  └─ test-design.md                      # ④ 产出：验证契约权威（建议位置；需扩 schema）
├─ plans/
│  ├─ build-plan.md                       # ⑤ 产出：实施契约权威（单文件；本册新增产物，需扩 schema）
│  └─ IMP-001-01.md / IMP-001-02.md       # ⑤ 产出：可选拆分视图，不得与 build-plan.md 冲突
└─ reports/
   └─ exploration-report.md               # ufs-exploration Step 0（建议位置）

<openSpecRoot>/changes/<change>/          # openSpecRoot 随 artifact_layout 在 docs/openspec 与 openspec 间切换
├─ .comet.yaml                            # Comet Runtime（经 ufs-main CLI 写入）
├─ proposal.md                            # ③ 镜像（权威在需求基线）
├─ specs/**/spec.md                       # delta spec，③ 镜像
├─ design.md                              # OpenSpec 侧：工程上下文 / 影响 / 约束，或 Canonical Design 的索引（总体设计 §8.4）
└─ tasks.md                               # ⑤ 产出并维护：任务状态权威（Classic 依赖其完成状态闭包）

comet-artifacts/                          # change 之外（Stage 0 轨道）
├─ requirements/**                        # ① 产出：需求基线（权威）
└─ challenge/**                           # ② 产出：challenge-report.md / freeze-record.md
```
**注**：`requirements.md` / `acceptance-criteria.md` / `acceptance-tests.md` 不是 Comet 原生路径——它们是 ③ 的**镜像**，权威在 `comet-artifacts/requirements/`；其落盘位置随 OpenSpec 约定，不构成新的权威来源（唯一权威来源原则，总体设计 §8.1）。
**`review` / `verify` / `archive` 没有产物文件**：三个 schema 的 `artifacts` 为空数组，只有 Runtime 运行时推导的 **evidence 记录**（总体设计 §8.2）。因此本册 §11、§12 **不声明任何 review/verify 的 Comet 原生「产物文件」路径**（第一层是 evidence 记录，不是文件）；两者的**审计副本路径**（`comet-artifacts/evidence/<change>/{review,verify}/**`）照常声明。
### 9.6.2 `build-plan.md` 必含章节（17 项）

| # | 章节 | 必含内容 |
|---|---|---|
| 1 | Plan Meta | `feature_id` / `story_refs` / `design_refs` / `test_design_refs` / `preset` / `development_mode` / `status` |
| 2 | Inputs Loaded | 已加载的 requirements/acceptance/AT/design/test-design + 版本/哈希 |
| 3 | Implementation Boundary | `What components must change?` + `Which component owns the behavior?` |
| 4 | Design → Code Mapping | `design_element → component → files → functions`，函数带 `role` |
| 5 | Change Strategy | 每组件六选一：Modify / Extend / Refactor / Extract / Introduce / Remove |
| 6 | Task DAG | 有序依赖图（不得生成无法执行的顺序） |
| 7 | Build Tasks | 每个 Task 含 §9.6.3 的**全部字段**（骨架 + ★ 扩展） |
| 8 | TDD Mode per Task | `tdd: {mode, red, green, refactor}` |
| 9 | Testability Constraints | 来自 ④ 的 `item_type: testability_constraint` 约束（归 `DES-`）及落实 Task；其来源行为以 `BEH-*` 标注（分册 01 §9.0） |
| 10 | Change Impact Analysis | Callers / Callees / Shared State / Global Variables / Interrupt Context / DMA / Queue / Scheduler / Tests |
| 11 | Risk & Safety Rules | 高风险项标 `risk: high` + `review_required: true` |
| 12 | Regression Scope | 回归范围与触发条件（**等级命名与正交映射引用分册 01 §10**） |
| 13 | Traceability Matrix | `Requirement → Acceptance → Design → Test → Build Task → Code` |
| 14 | CodeGraph Evidence | 查询 + 结果 + 仓库版本 + commit（总体设计 §11.1 格式） |
| 15 | Open Conflicts | `Design ≠ Existing Code` 的 flag 与裁决记录 |
| 16 | Human Approval | 批准人 / 时间 / 版本 / 附条件 |
| **17** | **Minimal Validation Design（最小验证设计）** | **`tweak` / `hotfix` 跳过 `design` 节点时的 `test-design.md` 替代载体**（分册 01 §4.8.1）。必含三块：① 每个行为 → 一句验证方法；② 每个 Build Task 的 `verification_level` + 判定理由；③ 行为 → `test_refs` → Expected 的最小用例矩阵。**`full` preset 下本节可省，但必须显式写 `not_applicable: full-preset`；`tweak`/`hotfix` 下本节缺失 = `plan` 不得排任务** |

**载体唯一性**：最小验证设计的**唯一载体是本节 §17**。`§12 Regression Scope` 不承载它，`§9.8 Step 0` 也不另建载体。
### 9.6.3 Build Task 必备字段（唯一权威字段集）

**本节是 `build-plan.md` 中 Build Task 字段的唯一定义处**；分册 01 §12.5 是同一字段集的方法论视图，门禁 `03 H03`/`H04` 按本节字段名读取。字段集是分册 01 §12.5 的**超集**，带 `★` 的是 UFS 固件必需的扩展字段（缺任一 ★ 字段 → `H03` `BLOCK`）。

```yaml
task_id:              # IMP-001-01（统一 ID，本册 §1.3）
title:                # 工程实现步骤名，不得写 "Implement xxx"
purpose:              # 为什么需要这一步

design_refs: [DES-001-01]
acceptance_refs: [AC-001-01]                 # 无 AC 的用例改填来源类型标注（分册 01 §11.4）
test_refs: [TC-001-01, TC-001-02]            # 每个 TC 经 BEH-* 归属到行为（分册 01 §9.0）

scope:                                       # ★ 写入范围（H04/H05 的唯一读取字段）
  files: [src/host/flow_control.c]           # 精确路径 / 前缀 / glob
  functions: [FlowControl_CheckPermission]   # role: candidate_implementation_point | required_interface

dependencies: [ResourceManager, IMP-001-01]
implementation_steps: []
verification: [TC-001-01, TC-001-02]         # 不得为 "implementation: done"
expected_result: [all listed tests pass, no regression]
risks: []                                    # 高风险项 risk: high

codegraph_evidence: {query:, result:, repository:, commit:, timestamp:}
tdd: {mode: greenfield|legacy|hardware_bound, red: [], green: [], refactor: []}
testability_constraints: []

# ★ 六个 UFS 扩展字段（分册 01 §12.5；缺任一 → H03 BLOCK）
verification_method:                          # ★ 该 Task 采用什么方法验证（可执行的判定描述）
verification_level:                           # ★ 该 Task 必须提供的最高执行型验证层级（七级枚举）
required_regression_level:                    # ★ 该 Task 必须执行的回归等级（L0…L5；不设默认，见 RG-1）
state_machine_impact:                         # ★ 状态机影响
data_structure_impact:                        # ★ 数据结构影响
concurrency_interrupt_impact:                 # ★ 并发 / 中断影响

# ★ 消费声明（H03 逐项判定"是否已消费"，不要求复制内容）
verification_strategy_consumed: []            # ★ 本 Task 覆盖的 BEH-* 行（来自 test-design.md §3 / §17.①）
non_testable_consumed: []                     # ★ 本 Task 触及的 non_testable[] 项及其替代层级
```

**字段语义**：

| 字段 | 语义 | 谁读 |
|---|---|---|
| `scope.files` | 允许写入的文件清单（精确路径 / 前缀 / glob） | `H04` 第 ④ 级、`H05` |
| `scope.functions` | 允许改动的函数（含 `role`） | `H04`；`design` 阶段的函数名禁令只约束 `design` 产物，不约束本节 |
| `verification_level` | 该 Task **必须提供的最高执行型验证层级**；Task 的**完整层级集合**由其 `test_refs` 指向的各 `TC-*` 各自声明的 `level` 承载，**不需要新增字段** | `H03`、`RG-1` |
| `required_regression_level` | 该 Task 必须执行的回归等级；**不设默认**（`RG-1`/`99 D18`），必须显式写入 | `H03`、`H10` |
| `verification_method` | 该 Task 的具体验证方法（命令 / 检查方式 / 观测对象） | `H03`、人工评审 |
| `*_impact` 三项 | 状态机 / 数据结构 / 并发中断三类影响；无影响必须显式写 `none`，不得留空 | `H03`、`H04` |
| `verification_strategy_consumed` | 本 Task 覆盖的行为行（`BEH-*`）；**H03 判定为"Build Plan 已消费 `verification_strategy`"** | `H03` |
| `non_testable_consumed` | 本 Task 触及的不可测项及其替代层级；**H03 判定为"`non_testable[]` 审批齐备"** | `H03` |

**`full` preset**：`verification_strategy_consumed` 取自 `test-design.md` §3；**`tweak` / `hotfix` preset**：取自 `build-plan.md` §17.①（最小验证设计），字段名与语义完全相同。

**行为归属**：`test_refs` 中的每个 `TC-*` 经 `BEH-*`（分册 01 §9.0）归属到某个行为；`verification_level` 的语义不因多级行为而改变。
### 9.6.4 三处产物名的张力与裁决

| 产物 | 角色 | 位置（主文档 **§8.3** 产物所有者表） | 裁决 |
|---|---|---|---|
| `build-plan.md` | **实施契约权威**（单文件）：Section 1–17；被 ⑥ `ufs-tdd` 作为 `build-plan.md` 输入读取 | `<superpowersRoot>/plans/`（本册新增产物的建议位置） | **权威**；⑥ 的 Inputs 已硬需求该名 |
| `plans/*.md` | 可选拆分视图（按 Task / 子系统） | `<superpowersRoot>/plans/`（Comet 原生 `implementation-plan`） | 派生视图，**不得与 `build-plan.md` 冲突** |
| `tasks.md` | **任务状态权威**（完成状态闭包） | `<openSpecRoot>/changes/<change>/tasks.md` | 由 Classic 依赖；本 Skill 产出并维护 |
**规则**：若 `plans/*.md` 与 `build-plan.md` 内容冲突，以 `build-plan.md` 为准；若 `tasks.md` 状态与 `build-plan.md` 的 Task 集合不一致，以 `build-plan.md` 为任务集合权威、`tasks.md` 为状态权威，并触发不一致告警。
### 9.6.5 Traceability Matrix（必产）

| Requirement | Acceptance | Design | Test | Build Task | Code |
|---|---|---|---|---|---|
| REQ-001 | AC-001-01 | DES-001-01 | TC-001-01 | IMP-001-02 | flow_control.c |
| REQ-001 | AC-001-01 | DES-001-02 | TC-001-02 | IMP-001-03 | flow_control.c |
| REQ-002 | AC-002-01 | DES-002-01 | TC-002-01 | IMP-002-05 | host_write.c |
## 9.7 Overall Workflow 总体流程

```text
Load Requirements → Load Acceptance → Load Design → Load Test Design → Analyze CodeGraph
→ Identify Implementation Boundary → Identify Dependencies → Determine Change Order
→ Create Build Tasks → Attach Test / Acceptance References → Attach Code Evidence
→ Determine Verification → Dependency Check → Review → Human Approval
```
## 9.8 Steps 步骤

| Step | 动作 / 产物 | 强制规则 |
|---|---|---|
| **Step 0 — 最小验证设计（Verification Level 补偿）** | tweak/hotfix 下按 ④ 的 7 级枚举为每个行为补做 Verification Level 判定，并补齐最小验证设计三块 | 仅当 `design` 节点被跳过时执行；产出写入 **`build-plan.md` §17 Minimal Validation Design`**（唯一载体，见 §9.6.2 第 17 项；**不写 §12**） |
| Step 1 — Identify Implementation Boundary | 回答 `What components must change?`、`Which component owns the behavior?` | **不要一开始就按照文件组织 Task** |
| Step 2 — Map Design to Code | `Design Element → Existing Component → Existing Function → Existing File` | 若不存在现成函数，必须 `status: NEW`，**不能假装它已经存在** |
| Step 3 — Determine Change Strategy | 每组件六选一 | 见 §9.9.2 |
| Step 4 — Determine Change Order | 建立 Task DAG | **不能生成无法执行的顺序** |
| Step 5 — Create Build Tasks | 每个 Task 具备 §9.6.3 的全部字段（含 6 个 ★ 字段与 2 个消费声明） | 粒度规则见 §9.9.3；缺任一 ★ 字段 → H03 `BLOCK` |
| Step 6 — Attach Test / Acceptance References | `test_refs` / `acceptance_refs` | 每个 Task 至少说明它影响哪些 AC |
| Step 7 — Attach Code Evidence | `codegraph_evidence` | 见 §9.6.3 |
| Step 8 — Determine Verification | `verification` / `expected` | **不能只有 `implementation: done`** |
| Step 9 — Change Impact Analysis | 5 维度必查（§9.9.5） | 回答 `What else could this change break?` |
| Step 10 — Safety & Regression | 高风险项标 `risk: high` + `review_required: true`，增加回归 | §9.9.6 |
| Step 11 — Traceability Matrix | 6 列表 | 必产 |
| Step 12 — Review → Human Approval | 提交 Build Plan 批准 | 未批准不得进入 `execute` |
## 9.9 Key Enumerations & Matrices 关键枚举与矩阵
### 9.9.1 Relationship with Superpowers（定位枚举）
```text
Superpowers writing-plans + UFS-specific constraints + ATDD traceability + Test Design + CodeGraph
Superpowers       = Generic Engineering Planning
ufs-writing-plans = UFS-specific Planning Adapter
```
原则：**不要复制整个 Superpowers。**
### 9.9.2 Change Strategy 六选一（闭集）
| 策略 | 含义 | 示例 |
|---|---|---|
| `Modify` | 改现有实现 | FlowControl 逻辑调整 |
| `Extend` | 扩展现有能力 | 增加新阈值档 |
| `Refactor` | 结构变更、行为不变 | 抽出纯决策逻辑 |
| `Extract` | 抽离可测试单元 | `FlowControl → Extract pure decision logic` |
| `Introduce` | 新增接口/组件 | 新增 DmaAdapter |
| `Remove` | 删除 | 移除死代码 |
### 9.9.3 Task Granularity（粒度硬规则）
不能过大（`Implement entire feature`），也不能过小（`Add one variable` / `Add one if statement` / `Add one test assertion`）。

> **一个 Task 对应一个具有独立工程意义的 Implementation Step。**

合规示例：`Define Flow Control State Model` / `Extract Flow Control Decision Logic` / `Implement Critical Resource Blocking` / `Implement Recovery Logic` / `Integrate Host Write Path` / `Implement Behavioral Unit Tests` / `Run Integration Regression`。
### 9.9.4 Task Dependency 与 Implementation Order
```text
IMP-001-01 → IMP-001-02 →┬→ IMP-001-03 ─┐
                          └→ IMP-001-04 ─┴→ IMP-001-05 → 006 → 007
```
通常优先顺序：`Architecture Boundary → Interface → Pure Logic → State Machine → Dependency Adapter → Integration → Test → Regression`；**实际顺序必须根据 CodeGraph 和现有代码决定**。
### 9.9.5 Change Impact / Firmware-specific Checklist（5 维度）
| 维度 | 必查项 |
|---|---|
| Interrupt | ISR / Main Loop |
| Concurrency | Host IO / GC / Background / DMA |
| Hardware | Registers / DMA / NAND / PHY |
| Resource | Queue / Memory / Descriptor / NAND Blocks |
| Timing | Timer / Timeout / Latency |
### 9.9.6 Safety Rules（高风险触发条件）
若修改 `Shared State` / `Interrupt Context` / `DMA` / `NAND Mapping` / `Power Management` / `Error Recovery`，必须标记 `risk: high` + `review_required: true`，并增加 `Regression` / `Integration Test` / `Hardware Validation`。
### 9.9.7 TDD-aware Planning（三模式）
```yaml
task_id: IMP-001-03
tdd:
  mode: greenfield
  red:     [implement TC-001-01, verify failure]
  green:   [implement minimal flow-control logic, verify TC-001-01 passes]
  refactor:[remove duplication, preserve behavior, rerun regression]
```
Legacy Firmware **不应直接** `write new test → change code`，而应拆为：`Analyze existing behavior / Create characterization test / Establish baseline / Create new behavioral test / Implement behavior change / Refactor / Regression`。
### 9.9.8 Candidate Function vs Required Function
CodeGraph 找到的函数（如 `FlowControl_CheckPermission()`）首先标记 `role: candidate_implementation_point`；**只有 Design 明确要求**时才能标记 `role: required_interface`。目的：避免 AI 被现有代码结构绑架。
### 9.9.9 Test Case Mapping 与 Acceptance Mapping（双向）
允许 `一个 Build Task → 多个 Test`，也允许 `一个 Test → 多个 Build Task`：

```yaml
task_id: IMP-001-03
test_refs: [TC-001-01, TC-001-02, TC-001-03]   # 每个用例经 BEH-* 归属到行为（分册 01 §9.0 / §12.5）
# 反向例: TC-001-04 需要 state model + recovery logic + host integration
#   → TC-001-04 ├── IMP-001-01 ├── IMP-001-04 └── IMP-001-05
```
## 9.10 Hard Rules 硬规则

| # | 规则 | 可检查点 |
|---|---|---|
| WP-1 | Build Plan 是 Implementation Plan，不是 Test Case List | Task 集合 ≠ UT 集合 |
| WP-2 | 一个 Task 对应一个具有独立工程意义的 Implementation Step | 粒度检查 |
| WP-3 | 每个 Task 必须有 `design_refs` / `acceptance_refs` / `test_refs` / `verification` | 字段非空 |
| WP-4 | `verification` 不得退化为 `implementation: done` | 字段值可执行 |
| WP-5 | 不能生成无法执行的 Task 顺序 | DAG 无环、依赖存在 |
| WP-6 | 不存在的函数必须标 `status: NEW`，不得假装已存在 | 映射表 |
| WP-7 | CodeGraph 只作 Implementation Evidence（SYS-4） | `codegraph_evidence` 含 `source` / `query` / `result` / `repository` / `commit` / `timestamp` |
| WP-8 | Refactor 必须显式化为独立 Task，不得隐藏在功能 Task 中 | Task 标题 |
| WP-9 | 高风险修改必须标 `risk: high` + `review_required: true` | 字段 |
| WP-10 | `Design ≠ Existing Code` 时必须 `Flag Conflict → Design Review → Human Decision`，**不得偷偷修改 Design** | `Open Conflicts` 章节 |
| WP-11 | **`ufs-writing-plans` 不得直接调用 Coding Agent**；真正进入代码修改的是 ⑥ `ufs-tdd` | 调用链无 `ufs-coding` |
| WP-12 | tweak/hotfix 下必须补做 Verification Level 判定（Step 0） | **`build-plan.md` §17 Minimal Validation Design 非空**（唯一载体；**不是 §12**） |
| WP-13 | `Test Design` 约束 Build Plan，但 Test Design 不是 Build Plan 本身 | 输入引用而非复制 |
## 9.11 Forbidden Behaviours 禁止行为（10 条，全部）

```text
❌ 自行修改 Acceptance Criteria       ❌ 自行修改 Requirement   ❌ 把 UT Case 直接变成 Task          ❌ 根据函数数量生成 Task
❌ 忽略 CodeGraph                    ❌ 忽略 Existing Tests   ❌ 忽略 Legacy Behavior              ❌ 忽略 Testability Constraint
❌ 忽略 Integration Impact           ❌ 把所有任务写成 "Implement xxx"
```
**附加禁止**（据 WP-10/WP-11）：❌ 偷偷修改 Design 以匹配现有代码；❌ 直接调用 Coding Agent 执行实现。
## 9.12 Failure Contract 失败契约

| 失败情形 | 输出 | 路由 | 阻断 |
|---|---|---|---|
| `Design ≠ Existing Code` | `Open Conflict` 记录 | Design Review → Human Decision（不得静默改 Design） | 阻断批准 |
| Requirement/AC 歧义 | 回流 ③ / Stage 0 | 需求澄清 | 阻断 |
| Test Design 宣称不可测试 | `TESTABILITY ISSUE` 回流 | ④ → `ufs-design` | 阻断 |
| CodeGraph 不可用 | `build-plan.md` 缺 `codegraph_evidence` | 不得生成映射级 Task；转人工 | 阻断批准 |
| Task DAG 无法执行 | 计划不可批准 | 重排 | 阻断 |
| Human 驳回 | 未批准 | 重跑 | 阻断 `execute` |
## 9.13 Agent Responsibilities Agent 职责

| Agent | 职责 |
|---|---|
| **`ufs-build-plan`** | 主执行：产出 `build-plan.md` / `plans/*.md` / `tasks.md`；维护任务状态 |
| `ufs-design` | 处理 Design Conflict / 架构裁决输入 |
| `ufs-test-design` | 提供 Testability Constraint 与 UT Matrix |
| `ufs-document-review` | 门禁：检查计划与 Design/Test Design 的自洽与可追溯 |
| `ufs-main` | 汇总、提交 Human Approval、推进 `plan → execute` |
| Human | **Build Plan 批准**；架构与 Scope 变更决策 |
## 9.14 Tool Usage 工具使用

| 工具 | 用途 | 约束 |
|---|---|---|
| CodeGraph | Affected Components / Files / Functions / Call Graph / Dependency Graph / Existing Tests / Interface Boundaries / State Machine | **`CodeGraph Is Evidence`**：结果属 Implementation Evidence，不是 Requirement Definition |
| OpenViking | Historical Implementation / Past Bugs / Past Design Decisions / Existing Patterns / Coding Standards | 最终代码影响仍需要 CodeGraph 确认 |
| graphify | 关系聚合补充查询 | 优先级已裁定（99 D64），CodeGraph 优先 |
| `read` / `edit` | 读全仓；写 `build-plan.md` / `plans/*.md` / `tasks.md` | 唯一合法写路径 |
**CodeGraph Evidence 示例**：

```yaml
code_evidence:
  existing_files: [src/host/host_write.c]
  existing_functions: [HostWriteHandler]
  call_path: [HostWriteHandler, FlowControl_CheckPermission]
  dependencies: [ResourceManager, GcManager]
```
## 9.15 Human Gate 人工门禁

Build Plan 完成后 **★ Human Approval**，人工重点确认：

```text
Architecture / Implementation Boundary / Change Scope / Task Order
Risk / Testability / Hardware Impact / Regression Scope
```
通过后 `plan → execute`。
## 9.16 Definition of Done 完成定义

```text
[ ] Requirements loaded / Acceptance loaded / Design loaded / Test Design loaded
[ ] CodeGraph analysis completed / Affected components identified / Affected files identified
[ ] Affected functions identified / Implementation boundary defined / Dependencies identified
[ ] Change impact analyzed / Build tasks created / Tasks have meaningful granularity
[ ] Task dependency order defined / Acceptance refs attached / Test refs attached
[ ] CodeGraph evidence attached / Verification defined / TDD mode identified
[ ] Legacy characterization handled / Testability constraints handled
[ ] Regression scope defined / Human approval obtained
```
**附加 DoD**：`build-plan.md` 17 章节齐备（含第 17 节 Minimal Validation Design）；Traceability Matrix 6 列齐备；`tasks.md` 任务集合与 `build-plan.md` 一致；`plans/*.md` 与 `build-plan.md` 无冲突。
## 9.17 Relationships with Other Skills 与其他 Skill 的关系

| 关系 | 内容 |
|---|---|
| 上游 | ③ 提供 Acceptance Contract；`ufs-design` 提供 Implementation Design；④ 提供 Behavioral Test Design；CodeGraph 提供 Implementation Reality |
| 下游 | **⑥ `ufs-tdd`**：本 Skill 定义 `WHAT TO IMPLEMENT`，⑥ 定义 `HOW TO IMPLEMENT SAFELY` |
| 与 ④ | `④ → Behavioral Test → Testability Constraint → ⑤ → Implementation Task`；**Test Design 是 Build Plan 的重要输入，但不是 Build Plan 本身** |
| 与 ⑥ 的边界 | ⑤ 只产生经 Human Gate 的 Build Plan；**真正进入代码修改的是 ⑥** |
| 与 CodeGraph | Design 提供 `Intent`，CodeGraph 提供 `Reality`，⑤ 结合两者；冲突时 Flag → Design Review → Human Decision |
## 9.18 Final Principle 最终原则

```text
Acceptance + Design + Test Design + CodeGraph → Writing Plans → Implementation DAG → TDD
```
> **Build Plan 应该描述「如何把设计可靠地变成代码」，而不是描述「AI 要修改哪些行代码」。**

```text
REQ → AC → AT → DES → TEST DESIGN → BUILD PLAN → TDD → CODE → VERIFICATION
约束链: Test Design → constrains → Build Plan → constrains → Coding Agent
```
"从而避免 Coding Agent 自由发挥。"

---
# 10. Skill ⑥ `ufs-tdd`
## 10.0 元信息头

**元信息**: `name`=ufs-tdd · `serves`=phase build / node execute（subagent-execute 用 subagent-driven-development） · `executing_agent`=ufs-coding · `gate_agent`=Code Write Hook / Test Runner Plugin / Evidence Plugin · `output_schema`=comet.execution-evidence.v1 · `write_path`=源码 + 测试代码（唯一允许修改代码的 Skill） · `presets`={full: RED→GREEN→REFACTOR, tweak: 可省 REFACTOR 证据, hotfix: + 根因消除检查} · `status`=exists
## 10.1 Purpose 目的

用于 Comet **`execute` 节点**，按已批准的 Build Plan，**以 TDD 为核心纪律**实施 Firmware 修改。

```text
Build Task → Test Preparation → RED → Implementation → GREEN → REFACTOR → Regression → Evidence

Legacy: Existing Behavior → Characterization Test → Baseline GREEN
        → New Behavioral Test → RED → Implementation → GREEN → REFACTOR
```
**三模式摘要**：

```text
Greenfield:     Test → RED → Implementation → GREEN → REFACTOR
Legacy:         CodeGraph → Existing Behavior → Characterization Test → Baseline GREEN
                → New Behavior Test → RED → Implementation → GREEN → REFACTOR
Hardware-bound: Pure Logic → UT + TDD ; Hardware Adapter → Integration
                ; Register / PHY / Timing → Simulator / Hardware Verification
```
目的：**避免 Agent 强行给所有硬件代码写 Mock UT。**
## 10.2 Core Principle 核心原则

> **测试必须先于实现定义新行为；Legacy 代码必须先捕获现有行为，再修改行为。**

```text
禁止: AI 修改代码 → AI 编写一个测试 → 测试通过 → 宣布完成
正确: Approved Test Contract → RED → Implementation → GREEN → REFACTOR
```
## 10.3 Comet Stage Comet 阶段

服务 **`execute` 节点（phase `build`）**，是**唯一允许修改代码**的位置（总体设计 I3）。

| 项（总体设计 §4.5） | 内容 |
|---|---|
| 目标 | 按已批准计划实施 |
| 输入 | 已批准 Build Task、Design、Test Contract |
| 承担 Agent | `ufs-coding`（`execute`）；OMO / 子代理（`subagent-execute`） |
| Skill | ⑥ `ufs-tdd`；派发用 `subagent-driven-development` |
| 产物 | Code / Test / Regression Result / TDD Evidence / Implementation Notes |
| Schema | `comet.execution-evidence.v1` / `comet.handoff.v1` |
| 原则 | **一次只实现一个已批准 Build Task** |
## 10.4 Trigger 触发

| 类型 | 条件 | 强制动作 |
|---|---|---|
| 首次触发 | 存在已批准 Build Task，且 `build-complete` 前的 `execute` 节点被调用 | 调用本 Skill，一次一个 Task |
| 重跑触发 | 上一 Task 的 `verification` 全过（GREEN + Regression） | 选取下一个 Build Task |
| 重跑触发 | `review` 节点返回 BLOCKER（CODE_PROBLEM） | 修复后重跑本 Task |
| 重跑触发 | `verify` 返回 `NEEDS_REVISION`（`verify-fail` → `build`） | 按路由重跑 |
| **必须触发** | 任何源码/测试修改之前 | 无 Test Ref、无 Design Ref、无批准 Task 时**不得修改代码** |
| **不触发** | 无已批准 Build Task | 直接改代码 = 违规 |
## 10.5 Inputs 输入

输入：`Build Plan / Implementation Design / Test Design / Acceptance Tests / Existing Code`。

**必须读取**：

```text
requirements.md / acceptance-criteria.md / acceptance-tests.md / design.md / test-design.md / build-plan.md
必须获取: CodeGraph / Existing Code / Existing Tests / Build Configuration / Test Environment
必要时:   OpenViking / Historical Bugs / Historical Fixes / Existing Characterization Tests
```
**关键**：`build-plan.md` 是 ⑤ 的产出（本册 §9.6.4），也是本 Skill 的硬输入。
## 10.6 Outputs 输出

```text
Modified Source Code / Executable Tests / Test Results / Implementation Evidence / Change Log
```
**TDD Evidence 骨架**：

```yaml
task: IMP-001-03
red:     {test: TC-001-02, result: FAIL, reason: "expected BLOCK, got ALLOW"}
green:   {test: TC-001-02, result: PASS}
refactor:{changes: [extracted decision helper]}
regression: {result: PASS}
```
## 10.7 Overall Workflow 总体流程

```text
Select Build Task → Identify Test → Write Test → Run Test → Confirm RED
→ Implement Minimum Code → Run Test → GREEN → Refactor → Regression → Evidence
```
```text
                 build → Build Plan → ufs-tdd
                          ┌────────┴────────┐
                      Greenfield          Legacy
                          │                 │
                         RED        Characterization
                          │                 │
                    Implementation      Baseline
                          │                 │
                       GREEN             RED
                          │                 │
                      REFACTOR      Implementation
                          └────────┬────────┘
                                   ↓ GREEN → REFACTOR → Regression → Evidence
```
**权威循环（总体设计 §4.5）**：`Build Task → Test Preparation → RED → Implementation → GREEN → REFACTOR → Regression → Evidence`。**`Implementation` 不可省略**——它是 RED 与 GREEN 之间唯一的实现步骤。
## 10.8 Steps 步骤

| Step | 动作 | 强制规则 |
|---|---|---|
| Step 1 — Select Build Task | 选取一个已批准 Build Task | **一次只执行 `One Build Task`** |
| Step 2 — Operating Mode | `GREENFIELD` / `LEGACY` / `HARDWARE_BOUND`（可组合 LEGACY + HARDWARE_BOUND） | 模式决定流程分支 |
| Step 3 — Legacy: Existing Behavior | CodeGraph / Existing Tests / Logs / Historical Knowledge | **不允许直接假设 `Existing behavior = requirement`** |
| Step 4 — Characterization Test | `Existing Behavior → Characterization Test → Baseline` | 标记 `correctness_assertion: false`；**不得删除它来掩盖变化** |
| Step 5 — Test Preparation | 从 `test_refs` 选测试，**落地 `plan` 节点已给出的 Behavioral Test → Interface → Function 映射**（不重新决定映射） | Test Interface 优先级见 §10.9.3；映射不可行时按 §10.12 回流，不自行改映射 |
| Step 6 — RED | 写测试并运行，确认失败 | **必须是有效 RED**（§10.9.2） |
| Step 7 — Implementation | 最小实现 | 禁止大规模重构/无关优化/架构重写/性能优化 |
| Step 8 — GREEN | 运行测试至通过 | **用最小实现让当前测试通过** |
| Step 9 — REFACTOR | Remove duplication / Improve naming / Extract helper / Improve interface / Reduce coupling | `Behavior must remain unchanged`；必须重跑 Unit + Regression（`hotfix` 可省证据） |
| Step 10 — Regression | `Local Test → Affected Component Test → Regression` | 范围由 Build Plan 定义；**未定义时不得声称 `Full Regression Passed`** |
| Step 11 — Evidence | 按骨架收集 TDD Evidence | 见 §10.6 |
| Step 12 — CodeGraph 复查 | 修改前确认 Callers/Callees/Shared State；修改后重新确认 | 证据留档 |
| Step 13 — Failure 分类 | 失败时先分类（四类），**不要立即改代码** | 见 §10.12 |
| Step 14 — Scope 检查 | 发现额外变更时按四类分类 | 只有 `Necessary Dependency` 可在严格范围内处理 |
| Step 15 — Commit 边界 | 每个逻辑 TDD Cycle 形成清晰变更边界 | 例 `Commit: Implement critical flow-control blocking` |
### 10.8.1 Build Task Discipline

Coding Agent **一次只执行 `One Build Task`**，完成 `Implementation + Test + Verification` 后再进入下一 Task。每个 Task 必须包含：`Task ID / Design Ref / Acceptance Ref / Test Ref / Files / Functions / Dependencies / Verification`。

不得随意扩大 Scope。若需修改额外模块（`Additional Change`），必须做 `Impact Analysis`，必要时 `Human Approval`。
### 10.8.2 落地 `plan` 节点已给出的 Behavioral Test → Function 映射

**归属声明**：映射**不是由 ⑥ `ufs-tdd` 决定的**。`plan` 节点（⑤ `ufs-writing-plans`）已在 Build Task 的 `scope.files` / `scope.functions` 中给出映射；`execute` 只把该映射**落地为可执行实例**（选具体 Test Interface、生成可执行测试）。

```text
plan 节点已给映射: Behavioral Test → Interface → Function（见 build-plan.md）
execute 落地:      按该映射选 Test Interface → 生成 Executable Test
例: TC-001-01 → plan 给出 interface FlowControl_CheckPermission
    → execute 落地为 {file: src/host/flow_control.c, function: FlowControl_CheckPermission}
```
若 `execute` 发现 `plan` 给出的映射不可行，**不得自行改映射**：按 §10.12 的 `DESIGN_PROBLEM` / ⑤ 计划偏差路径处理（`Flag Conflict → Design/Plan Review → Human Decision`）。"这与 Design 阶段保持分离。"（= SYS-1）
## 10.9 Key Enumerations & Matrices 关键枚举与矩阵
### 10.9.1 Operating Modes（闭集）
`GREENFIELD` / `LEGACY` / `HARDWARE_BOUND`；可组合 `LEGACY + HARDWARE_BOUND`。
### 10.9.2 有效 RED / 无效 RED
```text
无效 RED: Compiler Error / Segmentation Fault / Test Setup Failure
          / Missing Symbol / Mock Failure / Environment Failure
有效 RED 必须: Test executes successfully
             + Expected behavior is not yet implemented
             + Assertion fails
```
**RED 必须证明**：新测试确实能够检测缺失或错误的行为。例：`TC-001-02 Expected: BLOCK / Current: ALLOW` ⇒ `FAIL`，这是正确的 RED。
### 10.9.3 Test Interface 优先级（闭集）
| 优先级 | 来源 |
|---|---|
| ① | `Existing Public Interface` |
| ② | `Existing Internal Interface` |
| ③ | `Introduce Testable Interface`（必要时） |
| ④ | `Direct White-box Access`（**最后才考虑**） |
### 10.9.4 Regression 范围（引用分册 01，不自立命名）
**Regression Level 的命名（`L0`…`L5`）与 Verification Level ↔ Regression Level 的正交映射表由分册 01 §10 唯一持有**（总体设计 §5.1.3）。本册**只引用、不复述**，也**不给出自己的等级数值或名称**（否则与分册 01 冲突）。

本 Skill 只保留两条硬规则：

1. 具体 Regression 范围由 `plan` 节点（⑤ `ufs-writing-plans`）的 `Regression Scope` 定义；
2. **如果 Build Plan 未定义，Coding Agent 不得擅自声称 `Full Regression Passed`**。
**与 Verification Level 的关系**：二者正交；映射查分册 01 §10，不在本册展开。
### 10.9.5 Scope Creep 四分类
发现 `Required change outside Build Plan` 时：`Necessary Dependency` / `Potential Improvement` / `Unrelated Refactor` / `DESIGN_PROBLEM`。**只有 `Necessary Dependency` 才可以在严格范围内处理**，其他进入 Review。
### 10.9.6 Firmware-specific TDD 分层矩阵
| 场景 | 必查 / 分层 |
|---|---|
| Pure Logic | `State Machine / Threshold / Queue Decision / Retry Policy / Resource Allocation / Mapping Logic` → Unit TDD |
| Hardware 直接依赖 | `Register / DMA / NAND / PHY / Clock / Interrupt` → **不能强行 Unit Test 全部行为** |
| Interrupt Context | 必查 Reentrancy / Atomicity / Shared State / Interrupt Ordering / Memory Visibility / Latency。分层：`Decision Logic → UT` / `ISR Integration → Simulator/Integration` / `Real Interrupt → Hardware` |
| DMA | 可 Unit Test：`Descriptor Calculation` / `State Machine` / `Error Handling`；实际行为：`Integration` / `Simulator` / `Hardware` |
| Timing-sensitive | 区分 `Logical Timing → UT` 与 `Real Hardware Timing → Simulator/Hardware` |
**Adapter Pattern**：

```text
Pure Logic       → Unit Test
Hardware Adapter → Integration / Simulator / Hardware

Business Logic ─┬── Hardware Adapter     测试: Business Logic → Fake Adapter → Unit Test
                ├── DMA Adapter          实际: Business Logic → Real Adapter → Hardware
                └── NAND Adapter
```
### 10.9.7 Mock Discipline 与 Test Data
**禁止 `Mock Everything`。**

```text
Pure Logic                  → No Mock
Stable External Dependency  → Stub/Fake
Interaction Contract        → Mock/Spy
Hardware                    → Simulator/HW
```
Test Data 必须覆盖 `Normal / Boundary / Invalid / Extreme / Recovery`，避免 `Only convenient values`。示例（threshold = 10）：`9 / 10 / 11 / 0 / MAX`。
### 10.9.8 Characterization Test 标记（闭集）
```yaml
type: characterization
purpose: {capture_existing_behavior: true}
correctness_assertion: false
```
即 `Characterization ≠ Correctness Test`。
## 10.10 Hard Rules 硬规则

| # | 规则 | 可检查点 |
|---|---|---|
| TDD-1 | 一次只实现一个已批准 Build Task | 变更文件 ⊆ `scope.files` |
| TDD-2 | RED 必须是**可观察的行为失配**，不是编译/环境失败 | RED 证据含 `expected ≠ actual` |
| TDD-3 | GREEN 用最小实现；禁止提前大规模重构/优化/架构重写 | diff 规模 |
| TDD-4 | REFACTOR 后行为不变，且必须重跑 Unit + Regression | refactor 证据 + 回归结果 |
| TDD-5 | 最小变更原则：`Minimal / Localized / Traceable / Reversible` | diff 范围 |
| TDD-6 | **不得为获得 GREEN 修改** `Requirement` / `AC` / `Expected Behavior` / `Test Contract`（SYS-2） | 契约 diff |
| TDD-7 | Legacy 必须先建 Characterization Baseline；`Existing != Required` 必须记录 Behavior Change | baseline 证据 |
| TDD-8 | 不得删除 Characterization Test 来掩盖变化 | 测试文件 diff |
| TDD-9 | 失败必须先分类（四类），**不得立即改代码** | 失败记录 |
| TDD-10 | `DESIGN_PROBLEM` 必须退出 Coding Loop，交 Design Review | 路由记录 |
| TDD-11 | 禁止用修改业务代码绕过环境问题 | 环境失败处理 |
| TDD-12 | Build Plan 未定义 Regression 范围时，不得声称 `Full Regression Passed` | 回归声明 |
| TDD-13 | 修改 `Shared State`/`Interrupt`/`DMA`/`NAND Mapping`/`Power`/`Error Recovery` 需 `risk: high` | 风险标记 |
| TDD-14 | 只有 `Necessary Dependency` 的额外变更可在严格范围内处理 | Scope 分类记录 |
## 10.11 Forbidden Behaviours 禁止行为

```text
❌ 为通过测试而修改 AC / Expected Behavior / Test Contract   ❌ 静默修改已批准 Design   ❌ 扩大 Scope（除 Necessary Dependency 且经批准）
❌ 修无关缺陷   ❌ 自行修改 Test Contract   ❌ 随机补丁（Random Patch）代替系统性调试   ❌ Mock Everything   ❌ 强行给所有硬件代码写 Mock UT
❌ 用环境修复为名修改业务代码   ❌ 在没有 Build Plan 定义时宣称 Full Regression Passed   ❌ 一次实现多个 Build Task
❌ 未经批准修改 Requirement / Acceptance Criteria 以获得 GREEN
```
## 10.12 Failure Contract 失败契约

**四类失败判据与路由（全部）**：

| 类别 | 判据 / 包含内容 | 处理后链路 | 硬约束 |
|---|---|---|---|
| `TEST_PROBLEM` | Mock 配置错误 / Stub 错误 / Test Setup 错误 / Expected Value 错误 / Test Harness Bug / Test Timing Bug / Test Data Bug | `Fix Test → Review if Contract Changed → Rerun` | 只是实现错误的 Test 可以修复；**若修改了 Test Contract，必须升级 Review** |
| `CODE_PROBLEM` | `Test Contract 正确` + `Design 正确` + `Environment 正常`，但 `Implementation behavior != expected` | `Systematic Debugging → Minimal Fix → Test` | — |
| `DESIGN_PROBLEM` | `Test requires behavior X` 但 `Design architecture only supports Y` | `Design Review → Human Decision → Design Revision → Test Design Revision → Build Plan Revision → build` | **不能让 Coding Agent 自己修改 Architecture** |
| `ENVIRONMENT_PROBLEM` | Compiler / Toolchain / Simulator / Hardware / Infrastructure / Missing dependency / Broken build environment | 环境修复 | **禁止修改业务代码来绕过环境问题** |
**Systematic Debugging 流程**：

```text
Observe → Reproduce → Collect Evidence → Form Hypothesis → Experiment
→ Identify Root Cause → Minimal Fix → Regression
禁止: Random Patch
```
**Test Contract Change 路径**：

```text
Identify Conflict → Record Reason → Design / Requirement Review → Human Decision
批准后更新: AC / AT / Test Design / Build Plan，然后重新执行
```
## 10.13 Agent Responsibilities Agent 职责

| 源角色 | 映射到 13 名册 | 职责 |
|---|---|---|
| Coding Agent | **`ufs-coding`** | RED / GREEN / REFACTOR / Debug / Implementation / Test Execution |
| Main Developer Agent | **`ufs-main`** | Build Task Scheduling / Failure Routing / Scope Control / Human Interaction |
| Design Agent | **`ufs-design`** | 处理 Design Conflict / Architecture Change |
| Review Agent | **`ufs-document-review`**（文档）+ **⑦ `ufs-code-review`**（代码） | Implementation Review / TDD Evidence Review / Scope Review |
| 失败分类 | **`ufs-failure-analysis`** | 在纠正动作**之前**分析失败并分类；不得直接改代码 |
## 10.14 Tool Usage 工具使用

| 工具 | 用途 | 约束 |
|---|---|---|
| CodeGraph（修改前） | 确认 Callers / Callees / Shared State / Dependencies / Affected Components | 证据留档 |
| CodeGraph（修改后） | 重新确认 Call Graph / Dependency / Interface | 证据留档 |
| OpenViking | 历史实现 / 类似功能 / 历史 Bug / Coding Convention / Known Workaround / Hardware Constraint | 先查询知识库 |
| Plugins | `Test Runner / Compiler / Simulator / CodeGraph / Artifact Collector` | **Skill 不负责实现这些能力** |
**Hooks（三层时点）**：

| 时点 | 动作 |
|---|---|
| Before Code Modification | 确认 `Build Task exists` / `Test refs exist` / `Design approved` |
| After Test | 自动 `Collect result` / `Classify status` / `Store evidence` |
| Before Completion | 检查 `Required tests executed?` / `Tests passing?` / `Regression executed?` / `Task scope respected?` |
## 10.15 Human Gate 人工门禁

**不是每一次 RED/GREEN 都需要人工**——自动执行 `RED / GREEN / REFACTOR / Regression`。但以下情况必须停并 **★ Human Decision**：

```text
Requirement conflict / Design conflict / Unexpected architecture change
Hardware behavior uncertainty / Safety-critical behavior / Large scope expansion / Test Contract change
```
## 10.16 Definition of Done 完成定义

**每个 Build Task 的 DoD**：

```text
[ ] Correct Build Task selected / Test Contract loaded / Existing behavior understood
[ ] Characterization completed if required / Test interface identified
[ ] RED achieved / Implementation completed / GREEN achieved / Refactor completed if needed
[ ] Unit tests passed / Required regression passed / CodeGraph impact checked
[ ] Scope respected / Evidence collected
```
**Build 阶段 Exit Criteria（进入 `verify` 的门槛）**：

```text
[ ] All approved Build Tasks completed / Required tests implemented / TDD evidence collected
[ ] No unresolved CODE_PROBLEM / No unresolved DESIGN_PROBLEM
[ ] No unresolved TEST_PROBLEM / No unresolved ENVIRONMENT_PROBLEM
[ ] Regression completed / No unauthorized contract changes   [ ] Code changes traceable to Build Plan
```
**hotfix 追加**（总体设计 §4.9）：必须完成**根因消除检查**（不只是让测试变绿）。
## 10.17 Relationships with Other Skills 与其他 Skill 的关系

| 关系 | 内容 |
|---|---|
| 上游 | ⑤ `ufs-writing-plans` 提供已批准 Build Plan；`ufs-design` 提供 Design；④ 提供 Test Design |
| 下游 | ⑦ `ufs-code-review`（Code Review）、⑧ `ufs-verification`（Evidence → Traceability） |
| 同节点 | `subagent-execute` 使用 `subagent-driven-development` 派发；派发产物 `comet.handoff.v1` |
| 失败回流 | `DESIGN_PROBLEM → design`；`TEST_PROBLEM → ④`；`ENVIRONMENT_PROBLEM → 环境`；`CODE_PROBLEM → 本 Skill` |
| 边界 | ⑥ 按计划安全地实现代码；**不拥有** Requirement / Design / Test Contract（Final Principle） |
## 10.18 Final Principle 最终原则

```text
Coding Agent ≠ Requirement Owner
Coding Agent ≠ Design Owner
Coding Agent ≠ Test Contract Owner
```
Coding Agent 的职责是：在批准的 `Requirement + Design + Test Design + Build Plan` 约束下执行 `RED → GREEN → REFACTOR`。

```text
Human Intent → ATDD → Design → Test Design → Build Plan → TDD → Code → Evidence → Verification
```
因此 AI 不再是"会写代码的聊天机器人"，而成为：

```text
受需求契约、设计约束、测试契约、Build Plan 和 Hooks 共同约束的 Firmware Coding Agent
```
---
# 11. Skill ⑦ `ufs-code-review`
## 11.0 元信息头

**元信息**: `name`=ufs-code-review · `serves`=phase build / node review（guardrail, optional: true） · `executing_agent`=ufs-code-review · `gate_agent`=Review Evidence Hook · `output_schema`=comet.review.v1 · `write_path`=comet-artifacts/evidence/<change>/review/**（审计副本；Comet 原生 `comet.review.v1` 无产物文件） · `presets`={full: 必须, tweak: 必须, hotfix: 必须} · `status`=new
**原生对照**（总体设计 §2.3）：`review` 节点 `kind = guardrail`、`optional: true`、原生 Skill = `requesting-code-review`、Output Schema = `comet.review.v1`、Guard = review evidence（evidence-only）。本 Skill 是其在 UFS 固件域的**特化实现**，取代通用 `requesting-code-review`（总体设计 §4.6）。
## 11.1 Purpose 目的

在 `verify` 之前**独立核查实现**：回答"这段代码**对不对**？符合设计与计划吗？"

| 项 | 内容（总体设计 §4.6） |
|---|---|
| 目标 | 在 `verify` 之前独立核查实现（Comet 原生 `guardrail` 节点，`optional: true`） |
| 输入 | Git Diff、测试代码、已批准 Design、Build Plan、Test Contract |
| 承担 Agent | `ufs-code-review` |
| 产物 | 两层：① Comet 原生 `comet.review.v1`（evidence，**无产物文件**）；② 审计副本 `comet-artifacts/evidence/<change>/review/**`（本设计新增，99 D07） |
| guard | review evidence（evidence-only） |
| 独立性规则 | 与被审代码的编写者**不得是同一执行实例**；不改被审代码，只返回结论 + findings |

| 本 Skill **负责** | 本 Skill **不负责** |
|---|---|
| 技术核查代码与测试 | 一致性审查（→ `ufs-document-review`） |
| 发现 blockers 与缺陷模式 | 需求质询（→ ② `ufs-challenge`） |
| 判定是否满足 Design / Build Plan | 修改代码 / 测试（→ ⑥ `ufs-coding`） |
| 输出结构化审查证据 | 最终验收（→ ⑧ / Human） |
## 11.2 Core Principle 核心原则

> **审查者与被审代码不是同一执行实例；审查只产出证据与结论，不产出修复。**

三条推论：

1. **审查早、审查频**：每个 Build Task 完成后、重大特性完成时、合并前；
2. **证据只用于判断**：`comet.review.v1` 是 evidence-only guard，审查者**不得**修改被审代码或测试；
3. **审查给下游用**：⑧ `ufs-verification` 的输入明确包含 **Code Review**（总体设计 §4.7），因此结论必须结构化、可引用。
## 11.3 Comet Stage Comet 阶段

服务 **`review` 节点（phase `build`）**：Comet 原生 `guardrail` 节点，`optional: true`。

```text
phase build:
  plan → execute / subagent-execute → ★ review → （build-complete）→ verify
```
**关键事实**（总体设计 §4.6）："这是 Comet 原生已解决的闸门。草稿文档把它漏成'无归属'，本设计据 Comet 契约恢复其位置，并注入 UFS 固件特有审查维度。"

| guard 语义 | 含义 |
|---|---|
| review evidence（evidence-only） | guard 只检查"是否产出合法的 `comet.review.v1` 证据"（第一层）与审计副本是否存在（第二层，99 D07），**不替审查者判断代码对错** |
| `optional: true` | 节点可被 preset 裁剪，但本设计的 UFS 契约要求三个 preset 均执行（本册 §4.2） |
## 11.4 Trigger 触发

| 类型 | 条件 | 依据 |
|---|---|---|
| **强制** | 每个 Build Task 在 `subagent-execute` 派发完成后 | 本册规则 |
| **强制** | 一个 change 的 `execute` 节点完成、进入 `verify` 之前 | 总体设计 §4.6（在 verify 之前） |
| **强制** | 合并前 / 归档前 | 总体设计 §4.8 归档条件含 Code Review Complete |
| **强制** | Build Plan 中标记 `review_required: true` 的 Task | ⑤ 的 Safety Rules |
| 可选 | 卡住时（获取新视角） | 按需 |
| 可选 | 重构前（基线检查） | 同上 |
| 可选 | 修复复杂缺陷后 | 同上 |
| 重跑 | 上次结论为 `CHANGES_REQUIRED` 且已修复 | 本册 §11.12 |
| **不触发** | 无 Git Diff / 无已批准 Design 或 Build Plan | 输入缺失时无法核查 |
## 11.5 Inputs 输入

**必读**：

```text
Git Diff（BASE_SHA → HEAD_SHA）
测试代码（新增 / 修改的 Test）
已批准 Design（design.md / Design Doc）
已批准 Build Plan（build-plan.md / tasks.md）
Test Contract（AC / AT / test-design.md 中的 Test Contract 部分）
```
**上下文注入要求**：审查者获得**精确裁剪的上下文**，**绝不获得作者会话历史**。

| 占位符 | 含义 |
|---|---|
| `{DESCRIPTION}` | 简要说明实现了什么 |
| `{PLAN_OR_REQUIREMENTS}` | 应该做什么（Build Task + 引用） |
| `{BASE_SHA}` | 起始 commit |
| `{HEAD_SHA}` | 结束 commit |
**输入硬约束**：CodeGraph 查询结果**必须带完整证据字段**（总体设计 §11.1）：

```yaml
source: codegraph
query:
result:
repository:
commit:
timestamp:
```
## 11.6 Outputs 输出

**产物按两层落盘（99 D07 / 99 D44）**：

| 层 | 内容 | 位置 | 性质 |
|---|---|---|---|
| 第一层：Comet 原生事实 | `comet.review.v1` | —— | **不是文件**；由 Runtime 从真实文件推导的 evidence（总体设计 §8.2：`artifacts` 为空数组）。**不得**创建 `review.json` 之类的"Comet 产物" |
| 第二层：本设计新增的审计副本 | 审查结论副本（结构化 YAML 头 + 正文；YAML 字段与本节 Schema 逐字段同名） | **`comet-artifacts/evidence/<change>/review/**`** | **审计副本**，供归档审计与离线复核；不是 Comet 原生产物，副本缺失不影响第一层判定，但**阻断归档** |

字段级 Schema（99 D08、99 D36 冻结）：

```yaml
schema: comet.review.v1
review_id: RVW-001-01        # Review Record ID（一轮审查的记录）；主文档 §5.1 已登记（本册 §1.3）
base_sha: <sha>
head_sha: <sha>
reviewed_scope:
  build_tasks: [IMP-001-03]
  files: [src/host/flow_control.c, tests/test_flow_control.c]
independence:
  reviewer_agent: ufs-code-review
  reviewer_execution_id: <id>
  author_agent: ufs-coding
  author_execution_id: <id>
  same_execution_instance: false        # 必须为 false，否则审查无效
summary: |
  <review summary：实现了什么、是否满足 Design / Build Plan>
verdict: APPROVED | APPROVED_WITH_CONCERNS | CHANGES_REQUIRED
findings:
  - id: REV-001-01
    severity: BLOCKER | MAJOR | MINOR | NOTE
    dimension: design_compliance | build_plan_compliance | scope_drift
               | defect_pattern | firmware_risk
    location: {file:, line:, function:}
    problem:
    evidence:                            # 必须给证据，不得只给判断
    required_action:
blockers: [REV-001-01]                   # findings 中 severity == BLOCKER 的集合（引用 REV-*）
codegraph_evidence: [{source: codegraph, query:, result:, repository:, commit:, timestamp:}]
```
| 字段组 | 作用 | 下游消费者 |
|---|---|---|
| `summary` | 供 ⑧ 与 Human 快速了解实现 | ⑧ `ufs-verification` |
| `findings[]` | 逐条缺陷/风险，带 `dimension` 与 `evidence` | ⑥ 修复、Human 复核 |
| `blockers[]` | **必须阻断进入 `verify` 的项** | `ufs-main` 路由、⑧ 归档条件 |
| `independence` | 证明"非同一执行实例" | Review Evidence Hook |
**证据规则（evidence-only）**：每条 finding 必须附 `evidence`（diff 片段 / 测试输出 / CodeGraph 查询 / 规范条款）；**只有判断没有证据的 finding 视为无效**。
## 11.7 Overall Workflow 总体流程

```text
取得 BASE_SHA / HEAD_SHA
  → 组装精确上下文（DESCRIPTION / PLAN_OR_REQUIREMENTS / 引用产物）
  → 派发独立审查实例（≠ 作者执行实例）
  → 五维审查（Design / Build Plan / Scope / Defect / Firmware Risk）
  → 逐条 finding 附证据 + 定 severity
  → 产出 `comet.review.v1`（summary + blockers）+ 写入审计副本 `comet-artifacts/evidence/<change>/review/**`
  → BLOCKER? ── 是 → 回流 ⑥ `ufs-tdd`（`CODE_PROBLEM`；节点为 `execute`）
              └─ 否 → 交 ⑧ ufs-verification / Human
```
## 11.8 Steps 步骤

| Step | 动作 | 强制规则 |
|---|---|---|
| Step 1 — 确定审查范围 | `BASE_SHA` / `HEAD_SHA` / 被审 Build Task / 文件清单 | 范围必须限定在已批准 Task 的 `files` 内 |
| Step 2 — 独立性自检 | 记录 `reviewer_execution_id` 与 `author_execution_id` | **两者相同则审查无效** |
| Step 3 — 维度 A：Design 合规 | 代码是否实现 `design.md` 所述结构/接口/状态模型 | 不得以"更好的设计"为由要求改架构；应报 `DESIGN_PROBLEM` |
| Step 4 — 维度 B：Build Plan 合规 | 是否按 Task 的 `implementation` / `implementation_steps` / `dependencies` 执行 | 偏离必须记为 `scope_drift` 或 `design_conflict` |
| Step 5 — 维度 C：Scope 漂移 | 是否修改了 `scope.files` 之外的代码；是否顺带重构/修无关缺陷 | 未批准变更一律 finding |
| Step 6 — 维度 D：缺陷模式 | 空指针/越界/资源泄漏/未初始化/错误码忽略/魔数/竞态/锁缺失/复制粘贴错误 | 逐项扫描 |
| Step 7 — 维度 E：固件风险 | 中断上下文安全 / 寄存器访问 / DMA 一致性 / 时序假设（§11.9.3） | 逐项检查，缺证据不得放行 |
| Step 8 — 测试代码审查 | 测试是否真实断言行为；是否有被削弱的断言；是否与 Test Contract 一致 | **怀疑为过 GREEN 而弱化测试时，报 BLOCKER** |
| Step 9 — 证据补齐 | 每条 finding 附 diff / 测试输出 / CodeGraph 查询 / 规范条款 | 无证据的 finding 无效 |
| Step 10 — 产出结论 | 写 `comet.review.v1`，给出 verdict 与 blockers | **不修改被审代码** |
| Step 11 — 路由 | BLOCKER → ⑥；无 BLOCKER → ⑧ / Human | 见 §11.12 |
### 11.8.1 五维审查矩阵

| 维度 | 审查问题 | 主要证据 | 典型 severity |
|---|---|---|---|
| A Design 合规 | 代码是否符合已批准 Design 的结构与接口？ | `design.md` vs diff | MAJOR / BLOCKER |
| B Build Plan 合规 | 是否按 Task 的步骤、依赖、文件范围实施？ | `build-plan.md` / `tasks.md` vs diff | MAJOR |
| C Scope 漂移 | 是否改了 Task 外文件、做了未批准重构？ | diff 文件集 vs `scope.files` | MAJOR / BLOCKER |
| D 缺陷模式 | 是否存在实现级缺陷？ | 静态阅读 + 测试 | BLOCKER / MAJOR / MINOR |
| E 固件风险 | 是否违反中断/寄存器/DMA/时序约束？ | CodeGraph + 规范 | BLOCKER |
## 11.9 Key Enumerations & Matrices 关键枚举与矩阵
### 11.9.1 Verdict 枚举（闭集，3 值）
| Verdict | 含义 | 后续动作 |
|---|---|---|
| `APPROVED` | 无 blocker，代码符合 Design 与 Build Plan | 交 ⑧ `ufs-verification` |
| `APPROVED_WITH_CONCERNS` | 无 blocker，但有需记录的 MAJOR/MINOR | 交 ⑧，concerns 进入 Known Issues |
| `CHANGES_REQUIRED` | 存在 blocker | 回流 ⑥ `ufs-coding`，修复后重审 |
### 11.9.2 Severity 枚举与路由（闭集）
| Severity | 判据 | 路由 | 是否 blocker |
|---|---|---|---|
| `BLOCKER` | 违反 Design / 越过 Scope / 固件安全风险 / 测试被弱化 | ⑥ `ufs-coding` | **是** |
| `MAJOR` | 不符合 Build Plan、明显缺陷模式但不致命 | ⑥ 或记录为 Known Issue | 否（须处理或记录） |
| `MINOR` | 命名/可读性/局部改进 | 记录 | 否 |
| `NOTE` | 观察、非问题 | 记录 | 否 |
**映射到通用 Skill 分级**：`BLOCKER` = Critical（立即修）、`MAJOR` = Important（继续前修）、`MINOR` = Minor（记录）。
### 11.9.3 固件特化风险清单（UFS Firmware Checklist）

| # | 风险 | 检查项 |
|---|---|---|
| F1 | **中断上下文安全** | 是否在 ISR 中做阻塞/加锁/分配；共享状态是否 atomic / critical section / memory barrier / disable interrupt；是否存在 ISR 与主循环的可见性竞态 |
| F2 | **寄存器访问** | 寄存器读改写是否保护；是否有 volatile / 位域歧义；是否访问了未定义或保留位；时序要求是否在访问间满足；是否假设了寄存器初值 |
| F3 | **DMA 一致性** | descriptor 地址/长度/对齐是否正确；cache 一致性（clean/invalidate）是否处理；DMA 与 CPU 的并发访问是否同步；完成回调与 buffer 生命周期是否匹配 |
| F4 | **时序假设** | 是否硬编码了未在需求中给出的超时/延迟数字；是否依赖未保证的时序顺序；是否忽略最坏情况延迟；timing 数字是否有需求或 Design 来源 |
| F5 | 资源所有权 | queue entry / descriptor / buffer 的申请与释放是否配对；错误路径是否泄漏 |
| F6 | 错误处理 | 错误码是否被忽略；recovery 路径是否与 Test Design 一致 |
### 11.9.4 审查结论 → 失败分类的映射

| finding 类型 | 失败分类 | 路由 |
|---|---|---|
| 实现与 Design 不符 | `CODE_PROBLEM` | ⑥ `ufs-coding` |
| 测试写错/断言过弱 | `TEST_PROBLEM` | ④ `ufs-test-design` |
| Design 本身无法满足 AC | `DESIGN_PROBLEM` | 停止 build → Design Review |
| 工具链/环境导致无法核查 | `ENVIRONMENT_PROBLEM` | Infrastructure |
## 11.10 Hard Rules 硬规则

| # | 规则 | 可检查点 |
|---|---|---|
| CR-1 | **独立性**：审查者与被审代码编写者**不得是同一执行实例** | `independence.same_execution_instance == false` |
| CR-2 | **不得修改被审代码**（含测试） | `write_path` 不含源码/测试 |
| CR-3 | 只返回结论 + findings，不返回 patch | 产物为 `comet.review.v1` |
| CR-4 | 每条 finding 必须附证据；无证据的 finding 无效 | `evidence` 非空 |
| CR-5 | 出现 `BLOCKER` 时不得给 `APPROVED` | verdict 与 blockers 一致 |
| CR-6 | 不得因为"改动很小"而跳过审查 | 审查记录存在 |
| CR-7 | 不得忽略 Critical/Blocker 项 | blockers 已路由 |
| CR-8 | 不得与被审作者争辩式审查；对不成立的技术反馈须给理由 | findings 有 `required_action` |
| CR-9 | 测试被弱化（断言删除/预期改写）必须报 BLOCKER（SYS-2） | 测试 diff 检查 |
| CR-10 | 固件四维（F1–F4）逐项检查，缺证据不得放行 | checklist 完整 |

**命名空间**：`CR-1`…`CR-10` 是 **Code Review 硬规则的规则编号**（主文档 §5.1.1 表 N4），**不是** finding ID。finding 的 ID 用 `REV-<Story>-<Seq>`，本轮审查记录用 `RVW-<Story>-<Seq>`（本册 §1.3、§11.6）。

**Hard Rule 的例外**：审查者认为"作者正确、自己判断有误"时，**不得**直接改代码；应退回澄清或降级为 `NOTE`。

## 11.11 Forbidden Behaviours 禁止行为

```text
❌ 审查自己写的代码（同一执行实例）   ❌ 直接修改被审代码或测试   ❌ 以"顺手修复"为名提交 patch   ❌ 跳过审查（"这个很简单"）   ❌ 忽略 Blocker / Critical
❌ 在存在未修复 Blocker 时给出 APPROVED   ❌ 用主观偏好代替规范依据（"我更喜欢另一种写法"）   ❌ 要求超出已批准 Design / Build Plan 的重构   ❌ 只给结论不给证据
❌ 把 Suggested fix 当作已完成的修复
```
## 11.12 Failure Contract 失败契约

| 失败情形 | 输出 | 路由 | 阻断 |
|---|---|---|---|
| 存在 `BLOCKER` | `verdict = CHANGES_REQUIRED` + `blockers[]` | 回流 ⑥ `ufs-coding`（`CODE_PROBLEM`）；修复后重审 | **阻断进入 `verify`** |
| 存在需记录的 `MAJOR` | `APPROVED_WITH_CONCERNS` | 交 ⑧，进入 Known Issues | 不阻断 |
| 测试被弱化 | `BLOCKER` | ④ / ⑥，引用 SYS-2 | 阻断 |
| 缺乏证据无法判断 | `verdict` 不给出，报"证据不足" | 补齐 diff / 测试输出 / CodeGraph 后重跑 | 阻断 |
| Design 本身不可满足 AC | `DESIGN_PROBLEM` | 停止 build → Design Review | 阻断 |
| 审查者 = 作者实例 | 审查结果**作废** | 重新派发独立实例 | 阻断 |
**硬规则**：review 节点的 guard 是 **evidence-only**——它只校验 `comet.review.v1` 的结构合法性，**不替代**审查判断；因此"有报告"不等于"审查通过"，`blockers` 必须被消费。
## 11.13 Agent Responsibilities Agent 职责

| Agent | 职责 |
|---|---|
| **`ufs-code-review`** | 主执行：独立核查、产出 `comet.review.v1`；`subagent / 0.0` |
| `ufs-main` | 派发审查（不得派发作者自身）、汇总 blockers、路由回流 |
| `ufs-coding` | 作者；**不得自审**；按 findings 修复后重新提交审查 |
| `ufs-verification` | 消费 `comet.review.v1` 作为 `verify` 输入（总体设计 §4.7） |
| `ufs-failure-analysis` | 对 `CHANGES_REQUIRED` 复现失败时分类（按需） |
| Human | 处理 `MAJOR` 记录的接受/拒绝；Scope 变更决策 |
**三重已生效保护的应用**（主文档 §6.5 为唯一权威；Capability Token 为 Phase 2 提案，不计入防线）：审查者的唯一写目标是审计副本目录 `comet-artifacts/evidence/<change>/review/**`（99 D07）；Comet 原生 `comet.review.v1` 无产物文件；审查者的读范围为全仓只读。
## 11.14 Tool Usage 工具使用

| 工具 | 用途 | 约束 |
|---|---|---|
| `CodeGraph:READ` | 确认 Callers / Callees / Shared State / Interface / Affected Components | 只读；查询必须带 `source` / `query` / `result` / `repository` / `commit` / `timestamp`（§11.5） |
| `Git:READ` | 取得 `BASE_SHA` / `HEAD_SHA`、diff、历史 | 只读；不得 commit / checkout 修改 |
| `read` / `grep` / `glob` | 阅读 Design / Build Plan / Test Contract / 测试代码 | 全仓只读 |
| Skill `ufs-code-review` | 调用本 Skill | 总体设计 §6.5 |
| `edit` | 仅写审计副本 `comet-artifacts/evidence/<change>/review/**` | **不得写源码 / 测试** |
**禁止的 Plugin 使用**：审查者不得调用 Code Write Plugin / Test Runner 的写入能力（总体设计 §3.2：Plugin 不能绕过 Hook）。
## 11.15 Human Gate 人工门禁

**`review` 节点没有 Human Gate**：`（自动，由 Hook 保证证据）`（总体设计 §10.2）。

| 机制 | 说明 |
|---|---|
| 自动性 | review 是 `guardrail` 节点，由 Review Evidence Hook 保证证据存在 |
| Human 介入点 | 仅当 findings 涉及 Scope 变更 / Test Contract 变更 / 架构变更时，走 `execute` 阶段内决策点（总体设计 §10.2） |
| 升级点 | `DESIGN_PROBLEM` → Design Review → Human Decision（本册 §11.12） |
## 11.16 Definition of Done 完成定义

```text
[ ] BASE_SHA / HEAD_SHA 已记录，审查范围限定在已批准 Build Task 内   [ ] independence.same_execution_instance == false 已证明
[ ] 五维审查已执行（Design / Build Plan / Scope / Defect / Firmware Risk）   [ ] 固件清单 F1–F6 已逐项检查   [ ] 测试代码已审查（断言真实、未被弱化）
[ ] 每条 finding 有 severity / dimension / location / problem / evidence / required_action
[ ] verdict ∈ {APPROVED, APPROVED_WITH_CONCERNS, CHANGES_REQUIRED}
[ ] blockers == findings 中 severity == BLOCKER 的集合   [ ] CodeGraph 证据带 source/query/result/repository/commit/timestamp
[ ] 已产出合规的 `comet.review.v1`（第一层 evidence）并写入审计副本 `comet-artifacts/evidence/<change>/review/**`（99 D07）   [ ] 被审代码与测试未被修改（diff 为空）   [ ] blockers 已路由（或已记录为 Known Issue）
```
## 11.17 Relationships with Other Skills 与其他 Skill 的关系

| 关系 | 内容 |
|---|---|
| **取代** | 取代通用 `requesting-code-review`：`ufs-code-review` = Comet `review` 节点的 UFS 特化实现（总体设计 §4.6） |
| 上游 | ⑥ `ufs-tdd` / `subagent-execute` 的代码与测试；⑤ 的 Build Plan；`ufs-design` 的 Design |
| 下游 | **⑧ `ufs-verification`**：`comet.review.v1` 是其**必读输入**（总体设计 §4.7） |
| 回流 | `CHANGES_REQUIRED` → ⑥（`CODE_PROBLEM`）；`DESIGN_PROBLEM` → Design Review |
| 同层对照 | `ufs-document-review`（一致性）、② `ufs-challenge`（对抗式需求质询） |
| 归档 | ⑧ 与 `archive` 的归档条件包含 **Code Review Complete**（总体设计 §4.8） |
**四个审查/验证职能的边界**（总体设计 §6.3）：⑦ 问"这段代码对不对？符合设计与计划吗？"，姿态为**技术核查**，对象为 **Git Diff + 测试代码**，独立性规则为"与代码编写者不得是同一执行实例"。**这是逐职能规则，不是"四者必须互斥实例"**；② 与 `ufs-document-review` 的独立性各按总体设计 §6.3 本行执行。
## 11.18 Final Principle 最终原则

> **审查者不是作者，审查只产出判断与证据，不产出修复。**

```text
ufs-tdd（实现） → ufs-code-review（独立核查 + 证据） → ufs-verification（验收）
```
**最终原则**：`review` 节点的价值在于**在 `verify` 之前把"代码是否真的符合已批准契约"变成一个独立、可引用、带证据的问题**；一旦审查者与作者合流，该节点的 guard 就退化为形式。

---
# 12. Skill ⑧ `ufs-verification`
## 12.0 元信息头

**元信息**: `name`=ufs-verification · `serves`=phase verify / node verify · `executing_agent`=ufs-verification · `gate_agent`=Verify Hook（pre-verify Hook） · `output_schema`=comet.verify.v1 · `write_path`=comet-artifacts/evidence/<change>/verify/**（审计副本；Comet 原生 `comet.verify.v1` 无产物文件） · `presets`={full: 必须, tweak: 必须, hotfix: 必须} · `status`=active
## 12.1 Purpose 目的

用于 Comet **`verify` 节点**，**验证整条链，而非执行一次 `pytest`**（总体设计 §4.7），回答"怎么证明做对了？"

```text
UT Result / Component Result / Integration Result / Acceptance Result
        ↓
Verification Evidence
        ↓
Traceability
```
| 项（总体设计 §4.7） | 内容 |
|---|---|
| 目标 | 验证**整条链**，而非执行一次 `pytest` |
| 原则 | **Tests passing alone is insufficient** |
| 产物 | 两层：① Comet 原生 `comet.verify.v1` = `READY_FOR_HUMAN_ACCEPTANCE` / `NEEDS_REVISION` / `BLOCKED` + 证据（evidence，**无产物文件**）；② 审计副本 `comet-artifacts/evidence/<change>/verify/**`（本设计新增，99 D07） |
| 回流 | `verify-fail` → **build**（Comet 原生迁移） |

| 本 Skill **负责** | 本 Skill **不负责** |
|---|---|
| 判定需求/AC/AT 是否被验证 | 编写或修改代码（→ ⑥） |
| 判定 Test Result 是否可信 | 执行一次性的测试（→ Test Runner Plugin） |
| 判定 Code 是否符合 Design / Build Plan | 代码质量审查（→ ⑦） |
| 判定 Evidence / Traceability 是否完整 | 归档决策（→ `archive` + Human） |
| 产出结构化验收输入 | 最终验收决策（→ Human） |
## 12.2 Core Principle 核心原则

> **Tests passing alone is insufficient.**

三条推论：

1. **从 AC 出发，不从代码出发**（总体设计 §14 第 7 条）：验证链是 `Requirement → Acceptance → … → Evidence`，不是"代码看起来对"；
2. **独立于 Build 的局部成功**（总体设计 §14 第 7 条）：`ufs-verification` 必须尽可能避免"自己写代码 → 自己说代码正确"（总体设计 §6.4）；
3. **验证层级可不同，验证意图不可缺**（SYS-5）：每个需求必须有合理的 Verification Strategy，但不是所有代码都必须 Unit Test。
## 12.3 Comet Stage Comet 阶段

服务 **`verify` 节点（phase `verify`）**，`kind = control`，Output Schema = `comet.verify.v1`，guard = verify result（evidence-only）。

```text
open → design → build → ★ verify → archive
                          │
                    verify-fail
                          ▼
                        build（Comet 原生回流）
```
| 项（总体设计 §2.3 / §4.7） | 内容 |
|---|---|
| 节点 | `verify`（control） |
| guard | verify result（evidence-only） |
| 输入 | Requirement / AC / AT / Design / Test Design / Build Plan / Git Diff / Test·Regression Result / **Code Review** / Evidence |
| 原则 | Tests passing alone is insufficient |
| 回流 | `verify-fail` → `build` |
## 12.4 Trigger 触发

| 类型 | 条件 | 强制动作 |
|---|---|---|
| 首次触发 | `build-complete` guard（`build-decisions-selected`）通过，进入 `verify` 节点 | 调用本 Skill |
| 重跑触发 | `verify-fail` 后修复完成再次进入 `verify` | 重跑全链验证（不得只重跑失败项） |
| 重跑触发 | Design / Test Design / Build Plan 在上次验证后变更 | 重跑 |
| **前置条件** | ⑧ 的输入齐备（含 **Code Review**） | Code Review 缺失时不得给出 `READY_FOR_HUMAN_ACCEPTANCE` |
| **不触发** | `review` 存在未关闭 BLOCKER | 先回流 ⑥ |
## 12.5 Inputs 输入

**必读（契约全集）**：

```text
Requirement / AC / AT
Design（design.md）
Test Design（test-design.md）
Build Plan（build-plan.md / tasks.md）
Git Diff
Test Result / Regression Result
Code Review（comet.review.v1）      ← 总体设计 §4.7 明确列入
Evidence
```
**输入硬约束**：缺任一契约类输入时，只能给出 `BLOCKED`，不得给出 `NEEDS_REVISION` 以外的判断；缺 Code Review 时**不得判定 Code Review Complete**。
## 12.6 Outputs 输出

**产物按两层落盘（99 D07）**：

| 层 | 内容 | 位置 | 性质 |
|---|---|---|---|
| 第一层：Comet 原生事实 | `comet.verify.v1` | —— | **不是文件**；由 Runtime 从真实文件推导的 evidence（总体设计 §8.2：`artifacts` 为空数组） |
| 第二层：本设计新增的审计副本 | 验证结论副本（结构化 YAML 头 + 正文；字段与本节 Schema 逐字段同名） | **`comet-artifacts/evidence/<change>/verify/**`** | **审计副本**；不是 Comet 原生产物，副本缺失不影响第一层判定，但**阻断归档** |

字段级 Schema（99 D08、99 D35 冻结）：

```yaml
schema: comet.verify.v1
change_id: <change>
result: READY_FOR_HUMAN_ACCEPTANCE | NEEDS_REVISION | BLOCKED
chain_check:                                   # 总体设计 §4.7 链条
  requirement_to_acceptance: complete | broken
  acceptance_to_design: complete | broken
  design_to_test_design: complete | broken
  test_design_to_build_plan: complete | broken
  build_plan_to_code: complete | broken
  code_to_test_result: complete | broken
  test_result_to_evidence: complete | broken
coverage:
  requirements:   {total: N, covered: N}
  acceptance:     {total: N, covered: N}
  acceptance_tests: {total: N, executed: N}
verification_level_review:                     # **派生视图**（非独立字段）：adequate = level_review.coverage.result，notes = answers.Q04 的 evidence
  adequate: true | false
  notes: []
level_review:                                  # 分册 01 §26.1 的九条核对项（权威清单），逐条必填
  coverage:              {result: PASS|FAIL,        evidence: [...]}   # 层级覆盖：每个行为声明的层级都有证据
  evidence_executable:   {result: PASS|FAIL|N/A,    evidence: [...]}   # 执行型证据：命令 / 环境 / 版本 / expected-actual
  evidence_inspection:   {result: PASS|FAIL|N/A,    evidence: [...]}   # INSPECTION：版本hash / 清单 / 逐条PASS|FAIL+依据 / 已持久化
  evidence_manual:       {result: PASS|FAIL|N/A,    evidence: [...]}   # MANUAL：步骤 / 观测值 / 执行人 / 时间
  no_level_downgrade:    {result: PASS|FAIL,        evidence: [...]}   # 声明的 HARDWARE 不得用 UNIT 结果替代
  regression_level_met:  {result: PASS|FAIL,        evidence: [...]}   # 每个 Build Task 的 required_regression_level 已执行
  failures_classified:   {result: PASS|FAIL,        evidence: [...]}   # 所有失败均有四分类结论（分册 01 §19）
  ac_full_coverage:      {result: PASS|FAIL,        evidence: [...]}   # 每个 AC 至少一条 AT 证据
  tc_full_coverage:      {result: PASS|FAIL,        evidence: [...]}   # 每条 TC 有已执行证据（或 deferred+批准）；被引用与否由 H03 判
level_review_outcome: NEEDS_REVISION | BLOCKED | NONE   # 九条汇总档位（映射见 §12.9.6）
answers:                                       # 12 问逐条回答
  Q01_requirement_coverage:   {answer: yes|no, evidence: […]}
  Q02_acceptance_coverage:    {answer: yes|no, evidence: […]}
  Q03_acceptance_tests_run:   {answer: yes|no, evidence: […]}
  Q04_verification_level:     {answer: yes|no, evidence: […]}
  Q05_level_selection:        {answer: yes|no, evidence: […]}
  Q06_test_result_trustworthy:{answer: yes|no, evidence: […]}
  Q07_code_matches_design:    {answer: yes|no, evidence: […]}
  Q08_code_matches_plan:      {answer: yes|no, evidence: […]}
  Q09_unapproved_scope:       {answer: none|found, evidence: […]}
  Q10_open_issues:            {answer: none|open, evidence: […]}
  Q11_evidence_complete:      {answer: yes|no, evidence: […]}
  Q12_archive_conditions_met: {answer: yes|no, evidence: […]}
regression:
  levels_run: [<回归等级：命名与映射引用分册 01 §10，本册不复述数值>]
  result: PASS | FAIL
traceability:
  complete: true | false
  broken_links: []
blocking_issues: []
non_blocking_issues: []
evidence_index: [EVD-001-01, …]
```
**三态输出语义**：

| 输出 | 含义 | 下一步 |
|---|---|---|
| `READY_FOR_HUMAN_ACCEPTANCE` | 全链验证通过，满足归档条件（除 Human Accepted） | Human 验收（总体设计 §10.2 `verify` Gate） |
| `NEEDS_REVISION` | 存在可修复的实现/契约问题 | `verify-fail` → `build`（总体设计 §2.2、§9.2） |
| `BLOCKED` | 缺输入 / 环境不可用 / 存在需 Human 决策的未决问题 | 停止，请求补齐或升级 Human |
**注意**：`READY_FOR_HUMAN_ACCEPTANCE` **不等于**归档；归档需 Human Accepted（总体设计 §4.8）。
## 12.7 Overall Workflow 总体流程

```text
Requirement → Acceptance → Design → Test Design → Build Plan → Code Change → Test Result → Evidence
```
验证过程：

```text
加载契约全集（含 Code Review）
  → 逐段检查追溯链是否完整
  → 统计 Requirement Coverage / Acceptance Coverage
  → 校验 AT 是否执行、Verification Level 是否合理
  → 校验 Test Result 是否可信（不是"测试通过即可信"）
  → 校验 Code 是否符合 Design / Build Plan
  → 检查是否有未批准 Scope Change / 未解决问题
  → 校验证 Evidence 是否完整、Traceability 是否闭合
  → 判定是否满足归档条件
  → 产出三态结论
```
## 12.8 Steps 步骤

| Step | 动作 | 对应 12 问 | 强制规则 |
|---|---|---|---|
| Step 1 — 加载契约全集 | 读 Requirement/AC/AT/Design/Test Design/Build Plan/Git Diff/Test·Regression Result/Code Review/Evidence | — | 缺契约类输入 → `BLOCKED` |
| Step 2 — Requirement Coverage | 统计被覆盖的 Requirement | Q01 | 未覆盖项必须列出 |
| Step 3 — Acceptance Coverage | 统计被覆盖的 AC 与已执行 AT | Q02、Q03 | 未执行的 AT 必须列出 |
| Step 4 — Verification Level 复核 | 判定 Verification Level 是否合理、层级选择是否正确 | Q04、Q05 | 参照 ④ 的 7 级枚举 |
| Step 5 — Test Result 可信性 | 校验测试是否真实执行、断言是否真实、是否被弱化 | Q06 | 测试被弱化 → `BLOCKED` / `NEEDS_REVISION` |
| Step 6 — Code ↔ Design | 校验代码是否符合已批准 Design | Q07 | 不符 → `NEEDS_REVISION` |
| Step 7 — Code ↔ Build Plan | 校验代码是否符合 Build Plan / Task 范围 | Q08 | 范围外变更 → Q09 |
| Step 8 — Scope Change | 检查是否存在未批准 Scope Change | Q09 | 存在 → `BLOCKED`（需 Human） |
| Step 9 — 遗留问题 | 检查是否存在未解决问题（含 Code Review blockers） | Q10 | 存在 blocker → 不得 `READY` |
| Step 10 — Evidence 完整性 | 校验证 Evidence 索引与引用完整 | Q11 | 不完整 → `NEEDS_REVISION` |
| Step 11 — Regression | 确认所需 Regression 等级已执行且结果可信 | Q06 | 未按计划执行 → `NEEDS_REVISION` |
| Step 12 — Traceability | 校验全链无断链 | Q11、Q12 | 断链 → 进入审查，不默认合理（总体设计 §5.2） |
| Step 13 — 归档条件预检 | 逐条检查 7 项归档条件 | Q12 | 任一不满足 → 不得 `READY` |
| Step 14 — 产出结论 | 写 `comet.verify.v1`，给出三态与证据 | — | 三态之一 |
| Step 15 — 路由 | `NEEDS_REVISION` → build；`BLOCKED` → Human | — | 见 §12.12 |
## 12.9 Key Enumerations & Matrices 关键枚举与矩阵
### 12.9.1 Verify 必答 12 问（逐条）
| # | 问题 | 判定输入 | 不通过的后果 |
|---|---|---|---|
| Q01 | 需求是否全覆盖 | Requirement 集 vs AC/AT/Test | `NEEDS_REVISION` |
| Q02 | AC 是否全覆盖 | AC 集 vs AT/Test | `NEEDS_REVISION` |
| Q03 | AT 是否执行 | AT 集 vs Test Result | `NEEDS_REVISION` |
| Q04 | Verification Level 是否合理 | `test-design.md` | `NEEDS_REVISION` / Human |
| Q05 | `UNIT` / `COMPONENT` / `INTEGRATION` / `SIMULATOR` / `HARDWARE` 是否选择正确 | `test-design.md` + 实际执行层级 | `NEEDS_REVISION` / Human |
| Q06 | Test Result 是否可信 | Test 执行记录 + 断言 + 是否被弱化 | `NEEDS_REVISION` / `BLOCKED` |
| Q07 | Code 是否符合 Design | Git Diff vs `design.md` | `NEEDS_REVISION` |
| Q08 | Code 是否符合 Build Plan | Git Diff vs `build-plan.md` / `tasks.md` | `NEEDS_REVISION` |
| Q09 | 是否存在未批准 Scope Change | Git Diff vs `scope.files` | `BLOCKED`（需 Human） |
| Q10 | 是否存在未解决问题 | Code Review blockers + Known Issues | 存在 blocker → 不得 `READY` |
| Q11 | Evidence 是否完整 | Evidence Index | `NEEDS_REVISION` |
| Q12 | 是否满足归档条件 | 归档 7 项 | 不得 `READY` |
### 12.9.2 归档条件（7 项，全部满足）

```text
Requirement Covered  ∧  Acceptance Covered  ∧  Verification Complete
∧  Code Review Complete  ∧  Evidence Complete  ∧  No Blocking Issue
∧  Human Accepted
```
| 条件 | 由谁判定 | `ufs-verification` 的职责 |
|---|---|---|
| Requirement Covered | ⑧ | 判定 |
| Acceptance Covered | ⑧ | 判定 |
| Verification Complete | ⑧ | 判定 |
| Code Review Complete | ⑦ | **消费 `comet.review.v1`** |
| Evidence Complete | ⑧ | 判定 |
| No Blocking Issue | ⑧ | 判定 |
| Human Accepted | Human | **不判定**，交由 Human（`archive` 节点） |
### 12.9.3 输出三态枚举（闭集）
`READY_FOR_HUMAN_ACCEPTANCE` / `NEEDS_REVISION` / `BLOCKED`。
### 12.9.4 失败四分类与路由（验证视角）

| 分类 | 含义 | 路由 |
|---|---|---|
| `TEST_PROBLEM` | 测试本身写错 / 断言不对 / 测试不可靠 | → ④ `ufs-test-design`（**不得改源码**） |
| `CODE_PROBLEM` | 实现与设计不符 | → ⑥ `ufs-coding` |
| `DESIGN_PROBLEM` | 设计无法满足 AC | → **停止 build，请求 Design Review** |
| `ENVIRONMENT_PROBLEM` | 工具链 / 环境 / 硬件不可用 | → Infrastructure / Environment |
### 12.9.5 验证层级复核表（沿用 ④ 的 7 级）
| Level | 验证者需确认 |
|---|---|
| `UNIT` | 是否用于行为，而非"为了有 UT 而 UT" |
| `COMPONENT` | 边界是否与 ④ 的 Unit Boundary 一致 |
| `INTEGRATION` | 是否覆盖依赖交互 |
| `SIMULATOR` | 是否覆盖中断/时序语义 |
| `HARDWARE` | 是否覆盖寄存器/PHY/功耗 |
| `INSPECTION` | 仅用于不可执行的静态约束；判定式见 SKR-6（99 D20、99 D21） |
| `MANUAL` | 是否有可复现的人工步骤记录 |

### 12.9.6 `level_review` 九条核对项与档位映射（分册 01 §26.1 的唯一落点）

**`01 §26.1` 是这九条的权威文本**；本节只做机器可读落点与档位映射，不改其语义。`H12` 逐条读取 `comet.verify.v1.level_review.<key>`，**九条缺一即 `BLOCKED`**（不是 `NEEDS_REVISION`）——缺字段属于"结构不可判定"，与"检查不通过"分属两档。

| # | `level_review` 键 | 分册 01 §26.1 核对项 | 通过条件 | 不通过档位 |
|---|---|---|---|---|
| 1 | `coverage` | 层级覆盖 | 每个行为声明的层级都有对应证据 | `NEEDS_REVISION` |
| 2 | `evidence_executable` | 证据可信 —— 执行型（`UNIT`/`COMPONENT`/`INTEGRATION`/`SIMULATOR`/`HARDWARE`） | 证据含**命令 / 环境 / 版本 / `expected`-`actual`** | `NEEDS_REVISION` |
| 3 | `evidence_inspection` | 证据可信 —— `INSPECTION` | 含**被检查对象版本（commit/hash）/ 检查项清单 / 逐条 `PASS`\|`FAIL` + 依据 / 已持久化** | `NEEDS_REVISION` |
| 4 | `evidence_manual` | 证据可信 —— `MANUAL` | 含**人执行的操作步骤 / 观测值 / 执行人 / 时间** | `NEEDS_REVISION` |
| 5 | `no_level_downgrade` | 层级不得降级 | 声明的 `HARDWARE` 不能用 `UNIT` 结果替代 | **`BLOCKED`** |
| 6 | `regression_level_met` | 回归等级达标 | 每个 Build Task 的 `required_regression_level` 已执行（分册 01 §10.3） | `NEEDS_REVISION` |
| 7 | `failures_classified` | 失败已分类关闭 | 所有失败均有四分类结论（分册 01 §19） | `NEEDS_REVISION` |
| 8 | `ac_full_coverage` | AC 全覆盖 | 每个 AC 至少一条 AT 证据 | **`BLOCKED`** |
| 9 | `tc_full_coverage` | TC 全覆盖（**证据期**） | 每条 `TC-*` **有对应的已执行证据**（或已标记 `deferred` + 批准）。**判“是否有证据”**；计划期“是否被引用”由 `03 H03` 第 8 项判 | `NEEDS_REVISION` |

**档位汇总规则**（`level_review_outcome`）：任一条为 `BLOCKED` 档 → `BLOCKED`；否则任一条为 `NEEDS_REVISION` 档 → `NEEDS_REVISION`；九条全 `PASS` → `NONE`（即不因此降档）。

**`N/A` 的合法条件**：`evidence_inspection` / `evidence_manual` 在本 change 中没有任何该层级证据时才可写 `N/A`，且必须同时满足"该层级不出现在 `verification_strategy` 中"；否则写 `N/A` 视为 `FAIL`。

**唯一判定点**：这九条的**唯一判定点是 `verify` 节点的 `H12`**；`plan` 节点的 H03 只检查 `plan` 阶段可判定的字段（`verification_level` / `required_regression_level` / 消费声明），不重复判定本节条目。
## 12.10 Hard Rules 硬规则

| # | 规则 | 可检查点 |
|---|---|---|
| V-1 | **Tests passing alone is insufficient** | 结论不能仅由 Test Result 支撑 |
| V-2 | 必须检查**整条链**，不得只跑一次测试 | `chain_check` 全字段 |
| V-3 | 必须回答全部 12 问 | `answers` 12 项齐全 |
| V-4 | 必须独立于 Build；不得"自己写代码 → 自己说正确" | 执行者 ≠ 实现者（SYS-7 精神） |
| V-5 | **不得修改代码 / 测试 / 契约** | diff 为空 |
| V-6 | 断链必须**进入审查**，不得默认合理 | `traceability.broken_links` 被处理 |
| V-7 | 存在 Blocking Issue 时不得给出 `READY_FOR_HUMAN_ACCEPTANCE` | `blocking_issues` 为空 |
| V-8 | 不得代替 Human 做验收决策 | 输出仅 `READY_FOR_HUMAN_ACCEPTANCE` |
| V-9 | 未按 Test Design 执行 Regression 时必须指出 | `regression.levels_run` vs 计划 |
| V-10 | 无 AC 对应的 UT 必须显式标注来源类型与理由（Design Constraint / Robustness） | 总体设计 §5.4 |
| V-11 | 验证层级可不同，但每个需求必须有验证意图（SYS-5） | Q04/Q05 |
| V-12 | 不得把覆盖率作为唯一完成判据 | 总体设计 N9 |
| V-13 | **必须逐条产出 `level_review` 九条核对项**（分册 01 §26.1），并按 §12.9.6 汇总为 `NEEDS_REVISION` / `BLOCKED` 两档 | `level_review` 九键齐全 + `level_review_outcome` 与映射一致 |
## 12.11 Forbidden Behaviours 禁止行为

```text
❌ 仅因测试通过就判定 READY_FOR_HUMAN_ACCEPTANCE   ❌ 带 Blocking Issue 进入 Human Acceptance   ❌ 自己写代码后自己宣布代码正确
❌ 修改代码 / 测试 / AC 以让验证通过   ❌ 只验证代码，不验证 Requirement 与 Acceptance 覆盖   ❌ 忽略 Traceability 断链   ❌ 忽略 Code Review 的 blockers
❌ 用 Line/Branch Coverage 代替验收   ❌ 把 INSPECTION 层级当作已验证（语义未定义）   ❌ 代替 Human 做最终验收
❌ 在缺 Code Review 时声明 Code Review Complete
```
## 12.12 Failure Contract 失败契约

| 失败情形 | 输出 | 路由 | 阻断 |
|---|---|---|---|
| 实现与 Design 不符 | `NEEDS_REVISION` | **`verify-fail` → `build`**（Comet 原生迁移），分类 `CODE_PROBLEM` | 阻断 Human Acceptance |
| 测试写错 / 断言不可信 | `NEEDS_REVISION` | `TEST_PROBLEM` → ④ `ufs-test-design` | 阻断 |
| 设计无法满足 AC | `BLOCKED` / `NEEDS_REVISION` | `DESIGN_PROBLEM` → **停止 build，请求 Design Review** | 阻断 |
| 环境不可用 | `BLOCKED` | `ENVIRONMENT_PROBLEM` → Infrastructure | 阻断 |
| 存在未批准 Scope Change | `BLOCKED` | Human 决策（Scope 变更） | 阻断 |
| 缺输入（含 Code Review） | `BLOCKED` | 补齐输入后重跑 | 阻断 |
| 存在 Code Review blocker | 不得 `READY` | 回流 ⑥ | 阻断 |
| 全链通过 | `READY_FOR_HUMAN_ACCEPTANCE` | Human 验收（`verify` Gate） | 不阻断 |
**硬规则**：`verify-fail` 的目标阶段是 **`build`**（总体设计 §2.2 原生迁移），不是 `design`；这是"不把问题偷偷推到错误阶段修复"的落地（I8）。
## 12.13 Agent Responsibilities Agent 职责

| Agent | 职责 |
|---|---|
| **`ufs-verification`** | 主执行：验证整条链、回答 12 问、产出 `comet.verify.v1`；`subagent / 0.0` |
| `ufs-verification` 的工具权限 | CodeGraph、OpenViking、Test、Git（**只读**） |
| `ufs-failure-analysis` | 按需：在纠正动作之前分析失败并分类（`verify` 节点的专家） |
| `ufs-code-review` | 提供 `comet.review.v1`（Code Review Complete 的判定依据） |
| `ufs-main` | 组装归档产物、触发 `verify` 节点、执行 `verify-fail` 回流 |
| Human | `verify` Gate 的验收决策（总体设计 §10.2） |
**独立性约束**（总体设计 §6.4）：`ufs-verification` 必须尽可能避免"自己写代码 → 自己说代码正确"。
## 12.14 Tool Usage 工具使用

| 工具 | 用途 | 约束 |
|---|---|---|
| CodeGraph | 保留 `查询 → 结果 → 仓库版本 → 证据` 作为可引用的证据链 | 只读；必须带 §12.6 `codegraph_evidence` 字段 |
| OpenViking | 历史验证、已知缺陷、过往验收 | 知识查询必须带 provenance（总体设计 §11.3） |
| Test Runner | 重放/复核测试（受控） | 只读执行；不得修改测试 |
| Git | 取 diff、commit、tag | **只读** |
| `edit` | 仅写审计副本 `comet-artifacts/evidence/<change>/verify/**` | 不得写源码 / 测试 / 契约 |
| Verify Hook | `pre-verify` 强制的承载者 | 总体设计 §12 第一版 Hook 清单 |
## 12.15 Human Gate 人工门禁

| Gate | 闸门对象 | 确认清单 |
|---|---|---|
| **验收**（`verify` 节点） | `READY_FOR_HUMAN_ACCEPTANCE` | Verification Report / 12 问结论 / Coverage / Traceability / 遗留问题 / 未批准变更 |
**规则**：只有 Human 验收通过，才允许 `verify-pass` → `archive`（总体设计 §2.2）。`READY_FOR_HUMAN_ACCEPTANCE` 是**建议**，不是验收本身。
## 12.16 Definition of Done 完成定义

```text
[ ] 契约全集已加载（含 Code Review）   [ ] chain_check 七个环节均判定   [ ] Requirement Coverage / Acceptance Coverage 已统计并列出未覆盖项
[ ] 12 问逐条回答且每条附证据引用   [ ] Verification Level 与层级选择已复核   [ ] Test Result 可信性已校验（含测试是否被弱化）
[ ] Code ↔ Design、Code ↔ Build Plan 已校验   [ ] 未批准 Scope Change 与未解决问题已列出   [ ] Regression 等级与结果符合 Build Plan
[ ] Evidence Index 完整；Traceability 无断链   [ ] `level_review` 九条逐条判定且 `level_review_outcome` 与 §12.9.6 映射一致
[ ] 归档 7 项条件逐条预检（Human Accepted 一项标注为不做判定）
[ ] 结论 ∈ {READY_FOR_HUMAN_ACCEPTANCE, NEEDS_REVISION, BLOCKED}   [ ] 已产出 `comet.verify.v1`（第一层 evidence）并写入审计副本 `comet-artifacts/evidence/<change>/verify/**`（99 D07）   [ ] 未修改任何代码 / 测试 / 契约
```
**兄弟 Skill DoD 的对接**（⑧ 的前置门槛）：

| 前置 DoD | 章节 | ⑧ 的校验点 |
|---|---|---|
| ③ `atdd-development` DoD | §7.16 | `REQ → AC → AT` 可追且 Human approval 已获得 |
| ④ `ufs-test-design` DoD | §8.16 | Verification Level / Traceability / Coverage criteria 存在 |
| ⑤ `ufs-writing-plans` DoD | §9.16 | Build Task 有 acceptance/test refs 与 verification |
| ⑥ `ufs-tdd` DoD + Build Exit Criteria | §10.16 | TDD evidence 齐、无未解决四类失败、回归完成 |
| ⑦ `ufs-code-review` DoD | §11.16 | `comet.review.v1` 合法且无 blocker |
## 12.17 Relationships with Other Skills 与其他 Skill 的关系

| 关系 | 内容 |
|---|---|
| 上游 | ③ ④ ⑤ ⑥ ⑦ 的全部产物 + Human 冻结的 Requirement/AC |
| 上游（关键） | **⑦ `ufs-code-review`**：`comet.review.v1` 是必读输入 |
| 下游 | `archive` 节点（`ufs-main` + Human）；`comet.archive.v1` 组装引用本 Skill 结论 |
| 回流 | `verify-fail` → `build`（⑥）；`DESIGN_PROBLEM` → Design Review |
| 专家 | `ufs-failure-analysis`（按需，`verify` 节点挂载） |
| 边界 | ⑧ = "怎么证明做对了？"；它**不**产生代码、不产生需求、不做最终决策 |
## 12.18 Final Principle 最终原则

> **验证不是"测试都 Pass 了，所以完成"，而是回答"需求是否已经有完整的验证证据"。**

```text
REQ → AC → AT → DESIGN → TEST DESIGN → BUILD TASK → CODE → TEST RESULT → EVIDENCE → ARCHIVE
```
**最终原则**：`verify` 是五阶段闭环的**最后一道门**；它把"测试通过"升级为"契约被证明"，其结论是 Human 验收的唯一合法输入，但**不是验收本身**。
# 13. 附录

## 13.1 本册裁定与外部依赖

本册裁定统一编号 **`SKR-1`…`SKR-15`（Skill Ruling）**；全局裁定一律引用 `99 D##`，本册不重复编号。

| 裁定 | 事项 | 结论 | 依据 |
|---|---|---|---|
| `SKR-1` | `comet.review.v1` 字段 | 采用 §11.6 字段集（`review_id` / `base_sha` / `head_sha` / `reviewed_scope` / `independence` / `verdict` / `findings[]` / `blockers[]` / `codegraph_evidence[]`）；字段只增不改 | 99 D08、99 D36 |
| `SKR-2` | `comet.verify.v1` 字段 | 采用 §12.6 字段集（三态结果 + `chain_check` + `level_review` 九条 + `level_review_outcome` + 12 问 `answers` + 证据索引） | 99 D08、99 D35 |
| `SKR-3` | `build-plan.md` 契约 | 采用 §9.6：**17 个章节**（含第 17 节 Minimal Validation Design）+ 每个 Build Task 的 §9.6.3 全字段（含 6 个 ★ 扩展与 2 个消费声明）+ 目录形状 | 99 D04 |
| `SKR-4` | `build-plan.md` 与 `plans/*.md` 边界 | `build-plan.md` 是唯一实施契约权威；`plans/*.md` 是派生视图，不得承载其未出现的 Task / 字段 / Regression 等级 | 99 D04 |
| `SKR-5` | ④⑤⑥ 的触发条件 | 由节点契约给出，见 §8.4、§9.4、§10.4 | 本册 |
| `SKR-6` | `INSPECTION` 的判定语义 | 只用于**不可执行**的静态约束。**四项判定式（逐字引用 `99 D20`，不得改写）**：① 被检查对象带**版本号或 commit hash**；② **检查项被逐条列出**（清单完整）；③ **每条给出 `PASS`/`FAIL` 与依据**（文件路径 / 表项名）；④ **结论已持久化**。**附加要求**：必须携带**明确审批方**（`approver`）与 `DEC-nnn`（`99 D20` 不计入四项）。不得用于任何可执行行为，也不得作"跳过测试"出口；结论形态为 `PASS`/`FAIL`，执行者为 `ufs-verification` 或 Human | 99 D20、99 D21 |
| `SKR-7` | P0/P1 分级 | **逐字引用 `99 D23`（全局唯一权威）**：`P0` = 缺失即无法验收、阻塞归档（数据丢失/损坏、不可恢复错误、安全或掉电一致性风险、量产阻塞）；`P1` = 不阻塞归档但缺失记为 **Known Issue**（用户可见功能不满足 AC，或性能/时序不达标且可通过重试/复位恢复）；`P2` = 内部质量（可维护性、日志、错误码、性能微调），不影响 AC 判定。三档互斥且穷尽；每条 AC 必须且只能有一个 `priority` 字段，无标注不得进入 Freeze；`P0` 必须有 `UNIT` 或更高层级的验证证据（不可执行的静态约束按 `INSPECTION`） | 99 D23、99 D25 |
| `SKR-8` | 覆盖率阈值 | **不设阈值**；覆盖率只作观测指标，不得作为门禁条件、归档必要条件或 Exit Criteria；DoD 改为行为↔证据对齐 | 99 D24 |
| `SKR-9` | Regression 默认策略 | **没有默认**；等级由 Build Task 显式声明 `required_regression_level`，禁止按 Verification Level 或改动大小自动推导；`ufs-coding` 不得降低等级；命名与语义引用分册 01 §10 | 99 D18、99 D19 |
| `SKR-10` | 废弃 ID 前缀治理 | 迁移期只读接受，新产物一律规范形式（§1.3） | 本册 |
| `SKR-11` | Challenge Finding 的关联 | `BLOCK-nnn` / `WARN-nnn` / `Q-nnn` 是报告内局部命名空间，永不进入主干；`Q-nnn` 关闭后必须升级为 `DEC-nnn` 或 `ASM-nnn` | 99 D12 |
| `SKR-12` | `tweak` 下的 Challenge 裁剪 | 只执行 Freeze Checklist 的两条追加项与"每条 AC 可判定"，不执行对抗式质询；`Verdict` 仅 `PASS` / `PASS_WITH_CONCERNS`；`hotfix` 不触发 | 99 D40 |
| `SKR-13` | 审查的"执行实例"标识 | `independence.same_execution_instance` 必须为 `false`，否则该次审查证据无效 | 99 D36 |
| `SKR-14` | 四个审查/验证职能的 findings 报告 | 不合并为统一大报告；四个职能各自产出独立报告，归档时另生成汇总索引 | 99 D44 |
| `SKR-15` | OMO Team Mode 的启用 | 仅 `design` 节点、`preset = full`、且存在 ≥2 个互不依赖的并行工作面；`verify` 不使用 | 99 D45 |

### 13.1.1 依赖外部条件

下列事项取决于 Comet Runtime 或上游实现，本册只声明依赖，不自行定义。外部依赖事项的**唯一登记处是主文档附录 C**（编号 `EXT-01`…`EXT-13`），下表用其编号引用：

| # | 依赖 | 影响 | 依据 |
|---|---|---|---|
| `EXT-07` | Comet 尚未持久化 node 身份 | Code Write Hook 对 `plan` / `execute` 的区分以 Node Projection（Plugin 判定 + Runtime 同事务落盘 + Hook 只读）落地为前提 | 99 D60 |
| `EXT-04` | `.comet/` 运行时的 Output Schema 扩展 | `test-design.md`、`exploration-report.md`、`build-plan.md`、审计副本等新增产物必须登记到 UFS Schema 扩展清单；L3 guard 未启用前不得声明"可机器校验" | 99 D01、99 D61 |
| `EXT-11` | Capability Token 未冻结 | 保留为提案，不进入 MVP，不作为强制依据；写路径白名单 + Hook 放行优先 | 99 D68 |
| — | CodeGraph / graphify 的调用优先级 | CodeGraph 优先；graphify 仅作跨文件关系聚合的补充查询，一次查询中不得同时调用 | 99 D64 |
| — | Test Result 可信判据 | 四项同时成立：① **命令与退出码 + stdout/stderr 摘要完整**；② **用例 ID 与 Case Matrix 一一对应**；③ **无 `skip`/`xfail` 掩盖 P0 行为**；④ **执行环境被记录**（仿真 / 真机标识、工具链版本、commit hash），且证据含 **`expected` / `actual`** | 99 D81 |

## 13.2 与总体设计的对应

| 总体设计裁决 | 本册落地 |
|---|---|
| 统一 18 节模板 | 第 2 章；每个 Skill 章 `## x.1`–`## x.18` |
| `ufs-verification` 契约补全 | 第 12 章 |
| `ufs-writing-plans` 补 Outputs | §9.6（目录形状、17 章节、Build Task 全字段、三方边界） |
| 统一补 Trigger | §5.4、§6.4、§8.4、§9.4、§10.4 |
| Verification Level 统一为七级全大写 | §0.4、§7.9.4、§8.9.1 |
| ID 前缀统一 | §1.3 |
| Agent 名册统一为 13 个 | §5.13、§6.13、§7.13、§8.13、§9.13、§10.13、§11.13、§12.13 |
| `Comet Stage` 命名与章节层级统一 | §0.5 |
| Characterization Test 单一定义 | §7.8、§8.8、§9.9.7、§10.9.8 引用同一语义 |
| 源稿取唯一版本 | §1.2 |
| 五个 Skill 取代为 8 个 | §1.1、§1.4 |
| "Build Plan 阶段" → `plan` 节点 | §9.3 |
| 归档统一称 `archive` | §0.4 |

**本册在总体设计之上新增的设计**：

| 新增设计 | 位置 |
|---|---|
| 18 节模板的逐槽位定义与"已填"判定 | 第 2 章 |
| SYS-1…SYS-7 体系级硬规则与 8 Skill 矩阵 | 第 3 章 |
| 结构化输出三条最低要求（O1–O3） | §4.3 |
| `comet.review.v1` / `comet.verify.v1` 字段契约 | §11.6、§12.6 |
| `level_review` 九条核对项与两档映射（方法论 §26.1 的机器可读落点） | §12.9.6 |
| `non_testable[]` 五字段契约 | §8.6 |
| `build-plan.md` 契约 | §9.6 |
| 固件审查清单 F1–F6 | §11.9.3 |

## 13.3 本册与分册 01 的分工

**本册不重复分册 01 的工程方法论**；两者通过章名对接：

| 分册 01 的方法论主题 | 本册契约化落点 |
|---|---|
| 核心设计原则 + `FR-1..FR-5` 五条正式规则 | 本册 §3.1（SYS-1…SYS-7）；§7.10（`SR-1..SR-7`）；分册 01 §28；各 Skill 的 Core Principle |
| ATDD 定义与五阶段位置 + Acceptance Test | §7.3；§7.9.7；§8.9.7；§8.10 TD-9 |
| Test Design 核心思想 + UT Design 方法论 | §8.2；§8.8 Steps；§8.9 枚举与矩阵 |
| Testability Design 与架构反馈 | §8.8（Testability）；§8.12 回流 |
| Verification Level Decision + AT ↔ UT 映射规则 | §7.9.4；§8.9.1；§8.9.2；§7.9.7；§8.9.7 |
| Build Plan 与 UT Design 的交互 | §9.9.7；§9.10 WP-13 |
| Build 阶段 TDD + Greenfield / Legacy 与 Characterization + Firmware 分层 | §10.1–§10.10；§10.9.6；§10.9.8 |
| Test Contract Protection + 失败四分类 + Traceability + Human Gate + 端到端链条 | SYS-2；§10.12；§12.9.4；§1.3；§9.6.5；§12.8；各 Skill §x.15；本册 §4.1 |

**分工判据**：分册 01 回答"**为什么这样设计测试**"；本册回答"**这个 Skill 必须输入什么、输出什么、禁止什么、什么时候停下来**"。同一主题两边出现时，分册 01 给方法，本册给契约；冲突时以总体设计为准，其次以本册契约槽位为准（因其可被判 True/False）。

---

**文档结束。**

配套分册：[00 总体设计](00-总体设计-V2.0.md) ·
[01 方法论](01-方法论-ATDD与测试设计.md) ·
[03 Comet 实现设计](03-Comet实现设计-节点特化·Plugin·Hook.md) ·
[04 Stage 0](04-Stage0-需求分解与Challenge.md)

