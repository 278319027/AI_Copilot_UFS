# AI 辅助 UFS/SSD 固件开发平台 · 03 Comet 实现设计（节点特化 · Plugin · Hook）

**定位：平台实现层分册（Comet 节点特化 · Plugin · Hook）**
**对齐：Comet `0.4.0-beta.19`（`/home/zsf/comet-openspec-research`）**
**上游契约：[`00-总体设计-V2.0.md`](00-总体设计-V2.0.md)**

---

# 0. 文档说明

## 0.1 本册的地位与边界

本册是分册 03，回答**平台实现层**的问题：

```text
Comet 的八个节点在 UFS/SSD 固件场景下如何被特化？
节点靠什么被强制（Hook）？节点靠什么获得能力（Plugin）？
Agent 的权限如何落地为可机器检查的写路径？
产物落在哪里？运行时目录是什么？第一版做多少？
```

本册的边界：

| 属于本册 | 不属于本册（引用） |
|---|---|
| 八节点的 UFS 特化实现、Agent 挂载、guard、禁止项 | 方法论（ATDD / Challenge / TDD 语义）→ **分册 01** |
| Plugin 六类的能力面与约束 | 每个 Skill 的逐条输入输出契约 → **分册 02** |
| Hook 四层分类、13 个 Hook 的触发/检查/失败动作 | Stage 0 的分解与冻结流程 → **分册 04** |
| 权限模型落地（写路径白名单、Hook 放行、Capability Token 取舍） | Agent 的完整七段职责文案 → 分册 02 |
| 产物逻辑根、单写者、目录与运行时设计、MVP、实现顺序 | 平台六层架构、phase/node 双轨的**裁定** → **主文档 §2/§3** |

**硬约束**：本册**只做展开**，不重新裁定主文档已冻结的事项。发现冲突时先改主文档，再改本册。

## 0.2 上游契约与坐标系

本册全部内容建立在以下**不可改写**的上游契约之上：

| # | 上游契约 | 本册如何使用 |
|---|---|---|
| U1 | `PHASES = ['open','design','build','verify','archive']`（5 个真常量） | 只说"阶段"时只指这 5 个 |
| U2 | 八个 Workflow Node：`open/design/plan/execute/subagent-execute/review/verify/archive` | 节点特化的骨架，不新增、不改名 |
| U3 | 迁移表（`CLASSIC_TRANSITION_TABLE`）与 `verify-fail → build` 回流 | Hook 的 Stage 层判定依据 |
| U4 | 四种 preset：`full / hotfix / tweak / any` | 节点裁剪与补偿的依据 |
| U5 | 五个逻辑根：`openSpecRoot / changesRoot / archiveRoot / specsRoot / superpowersRoot` | 产物路径与写路径白名单的基准 |
| U6 | 决策点协议（阻塞式） | Human Gate 与 `request_human_gate()` 的语义 |
| U7 | 13 Agent 名册（1 编排 + 5 执行 + 3 审查 + 2 专家 + 2 前置） | 权限矩阵与节点挂载 |
| U8 | 唯一权威来源原则 | 单写者规则与 Evidence 归属 |

## 0.3 参考资料

- `00-总体设计-V2.0.md` —— 平台总体设计、判据、Agent 与 Skill 名册、产物权威
- Comet 源码：`domains/workflow-contract/builtins.ts`、`domains/comet-classic/classic-state.ts`、`classic-transitions.ts`、`classic-layout.ts`
- Comet Skill：`comet-open` / `comet-design` / `comet-build` / `comet-verify` / `comet-archive` / `comet-classic`（含 `classic-layout.md`、`file-structure.md`、`subagent-dispatch.md`）
- `.opencode/agents/prd-split.md` —— 权限模型范本

## 0.4 本册不覆盖但必须被遵守的硬规则

1. `Comet = WHEN`、`Agent = WHO`、`Skill = HOW`、`Plugin = CAPABILITY`、`Hook = ENFORCEMENT`、`Human = DECISION`。
2. **Plugin 可以提供能力，但不能绕过 Hook 的治理。**
3. 只有 `ufs-main` 持有生命周期状态；其余 Agent 不得自决下一阶段。
4. 代码修改只发生在 `build` 阶段的 `execute` / `subagent-execute` 节点。
5. Hook 用于强制执行，而不是只给 Agent 提示。

---

# 1. 术语与坐标

本册不重新定义主文档术语。以下只列本册高频使用、且容易在实现层被写错的坐标。

## 1.1 五阶段与八节点双轨

```text
phase（5，Comet 常量，不可改）    node（8，Comet 原生契约，可按 preset 裁剪）
─────────────────────────────    ──────────────────────────────────────────
open                 open
design                design
build     ────────────────────► plan
                   execute / subagent-execute
                   review
verify                verify
archive               archive
```

**节点身份的持久化缺口**：Comet 状态**没有 `node` 字段**，已有的持久化判别器只覆盖部分边界：

| 已持久化字段 | 枚举/取值 | 判别能力 | 判别盲区 |
|---|---|---|---|
| `phase`（`classic-state.ts` L7） | `open/design/build/verify/archive` | 只能定位到 `build` 这一整段 | 无法区分 `build` 内四个节点 |
| **`buildPause`**（`build_pause`） | `['plan-ready']` | 可区分"计划就绪待批"与"进入实施" | 只是 `plan` 的**出口暂停标志**，不表示已进入 `execute` |
| `buildMode`（`build_mode`） | `subagent-driven-development/executing-plans/direct` | 区分实施策略 | 不区分节点身份；且当前**无法可靠回读**（见 §13.3 G2） |
| `tddMode` / `reviewMode` / `verifyMode` | `tdd\|direct` / `off\|standard\|thorough` / `light\|full` | 区分纪律强度 | 与节点身份无关 |

即：`phase` + `build_pause=plan-ready` + `build_mode` 合起来只能区分 `plan` 与 `execute` 的**入口**，**无法区分 `subagent-execute`、`review`**，也无法在 `build` 内为 Code Write Hook 判定"写计划文件 vs 写源码"的节点身份。

**本册的决定**：引入 **Node Projection** —— 节点身份由 **Comet Plugin 判定**，经 **Comet Runtime 的状态写路径**与 `phase` **同事务**原子落盘到 `.comet/state/node.json`；guard 在每次判定前校验投影与 `phase` 一致，不一致即 `BLOCK`（裁定见 §14.1 IR-1，实现见 §4.9、§10.3 与 §10.5）。

## 1.2 十三个 Agent 名册（引用，不重复定义）

```text
编排 1  ufs-main
执行 5  ufs-exploration, ufs-design, ufs-test-design, ufs-build-plan, ufs-coding
审查 3  ufs-document-review, ufs-code-review, ufs-verification
专家 2  ufs-firmware-expert, ufs-failure-analysis
前置 2  ufs-requirements, ufs-challenge    （Stage 0，在 Comet phase 之外）
```

完整七段契约见主文档 §6.2 与分册 02；本册只定义它们的**挂载点、权限、Hook 交互**。

## 1.3 部件职责等式（实现层读法）

| 部件 | 一句话 | 实现层含义 |
|---|---|---|
| Comet | 什么时候做 | 节点路由、guard、preset、回流；**不自实现方法论** |
| Agent | 谁来做 | 具体执行实例；**没有生命周期写权限** |
| Skill | 应该怎么做 | 方法与流程；**不保存知识、不做强制** |
| Plugin | 提供什么能力 | 工具封装；**必须被 Hook 治理** |
| Hook | 什么情况下允许做 | 确定性判定；**不做复杂推理** |
| CodeGraph | 代码事实 | 只读；结果必须带 `repository/commit/timestamp` |
| OpenViking | 知识与历史 | 只读带 provenance；不与代码事实混用 |
| Human | 决策 | 决策点是阻塞点 |

## 1.4 本册新增术语

| 术语 | 定义 | 为什么需要 |
|---|---|---|
| **Node Projection** | 由 `phase` + Comet 运行时上下文推导出的当前 node，落在 `.comet/state/node.json` | Comet 只有 5 个 phase，Hook 需要 8 个 node 的粒度 |
| **`scope.files`** | 已批准 Build Task 声明的允许写入文件清单（精确路径 / 目录前缀 / glob） | 写路径白名单的物理载体，MVP 的 allow-list 边界 |
| **`waiver`** | 一次 Hook 放行的显式豁免记录（hook id + scope + 理由 + 有效期 + Human 授权） | 使"绕过"成为可审计事件，而非静默跳过 |
| **Review Evidence**（复用词：**`review evidence`**） | `comet.review.v1` 的 evidence 槽位 `review-summary` / `review-blockers`（**槽位 ≠ schema 字段**：分别对应分册 02 §11.6 的 `summary` 与 `blockers[]`） | `review` 节点的唯一产物形态；判定式 = §7.4.1（evidence-only：记录存在即通过，不要求文件） |
| **Node Guard Set**（复用词：**`node guardrail`**） | 某 node 的 guard 集合；`plan` 与 `execute` 共享 `comet-build` 但 guard 不同 | 解释单 Skill 跨节点拆分；判定式 = `Guard` 字段取值（§4.2 八节点表）；**已统一为 `node guardrail`，不再用 `Node Guard Set`** |
| **Enforcement Chain**（复用词：**`H04 判定链`**） | `code-write → Build Task → Scope → CodeGraph → Hook → Allow/Block` | 即 §7.3.4 的 7 级确定性链；**已统一为 `H04 判定链`** |

> **一次性术语的处置（G38）**：上表左列是本节内部命名，**不得跨节复用**；需要复用时一律用括号中的**复用词**。原“`evidence-only` 的升级版”表述已撤回——`evidence-only` 只有一种语义（§7.4.1），不存在升级版。

---

# 2. 平台实现层总体架构

## 2.1 本册在六层架构中的位置

```text
① Human / Developer       ← Human Gate、决策点（本册定义触发点）
② Comet Lifecycle        ← 节点特化的对象（本册第 3–5 章）
③ Agent Orchestration      ← 节点挂载 Agent（本册第 3、8 章）
④ Skills             ← 只引用（分册 02）
⑤ Capability / Knowledge Layer  ← Plugin 六类（本册第 6 章）
⑥ Enforcement / Automation    ← Hook 四层（本册第 7 章）
```

**澄清（对齐主文档 §3.1 注）**：平台整体是**六层**；"Hook 分成四层"是 **Hook 的内部子分类**，不是平台分层。本册第 7.1 节专门处理该区分。

## 2.2 运行时部件关系

```text
Human
  │
  ▼
Comet（② 生命周期：phase + node 路由 + guard）
  │  Stage / State（经 Comet Plugin 读取，禁止猜）
  ▼
ufs-main（③ 编排：分派、Human Gate、追溯维护）
  │
  ├──► Skills（④ 方法论；只引用，分册 02）
  │
  └──► OpenCode 宿主运行时
         ├── Agents（③ 执行主体，13 名册）
         ├── Plugins（⑤ 能力：CodeGraph / graphify / OpenViking / Test / Evidence …）
         └── Hooks（⑥ 强制：H01–H13）
                │
                ▼
        Firmware Repo（源码 + 测试代码；写入受 H04/H05 约束）
                │
                ▼
        Test / Build → Evidence（第一层由 Runtime 推导 + 第二层审计副本）→ verify → archive
  │
  └──► OMO Plugin（协作运行时；第二阶段启用，`99 D45`）
```

**说明（B78）**：原图是单线 ASCII 树，存在"两个父节点共用一个连接符"与"OMO 分支悬空"的断裂。本图改为缩进列表式，**每个分支有且只有一个父节点**；`OMO` 明确为 `ufs-main` 的第二阶段旁路，不是 `OpenCode` 的下级。

## 2.3 实现层不变量（J1–J10）

主文档 I1–I8 是架构级不变量；本册在其下补充 10 条**实现层**不变量，供 Hook 与权限模型直接编码。

| # | 不变量 | 机器可检查形式 |
|---|---|---|
| **J1** | 任何写入都必须匹配某 Agent 的写路径白名单 | `write.path ∈ whitelist(agent)` |
| **J2** | `phase: build` 中，只有 `execute` / `subagent-execute` node 允许写源码 | `node ∈ {execute, subagent-execute}` |
| **J3** | 任何源码写入都必须绑定一个已批准且未完成的 Build Task | `task_id ∈ tasks.md ∧ task.status == approved` |
| **J4** | 写入文件必须 ∈ 当前 Build Task 的 `scope.files`；**`derived_allow ≡ ∅`（恒为空集，不得有例外）** | `file ∈ scope.files ∧ derived_allow == ∅`（`99 D72`；超范围写入的唯一合法路径是 Human 批准并更新 `scope.files`） |
| **J5** | Test Contract 的变更必须有 Requirement / Design 变更依据 | `test_change.refs ⊇ {REQ\|DES\|DEC}` |
| **J6** | 每个节点完成前必须存在其 output schema 要求的 evidence | `evidence ⊇ schema.evidence.required` |
| **J7** | 每个产物只有一个合法写入者 | `artifact.writer == owners[artifact]` |
| **J8** | 没有实际执行的命令输出，不得声称 RED / GREEN / PASS | `evidence.command ≠ ∅ ∧ evidence.exit_code ≠ ∅` |
| **J9** | 归档需要 7 项条件同时成立，测试通过只是其中之一 | `close_criteria.all() == true` |
| **J10** | Hook 判定必须是确定性谓词；判定失败即 BLOCK | `hook.result ∈ {ALLOW, BLOCK}`，无 `UNSURE` |

## 2.4 一次节点执行的时序（Contract → Execution Context）

```text
Create Context → Load Contracts → Load Relevant Knowledge → Execute Skill
  → Call Tools / Plugins → Generate Artifact → Artifact Validation (Hook)
  → Review (Agent + Hook) → Human Gate if required → Commit State
```

统一执行上下文（避免 LLM "猜当前状态"）：

```yaml
project:  {id:, repository:, branch:}     change: {id:, title:, scope:}
comet:   {stage:, state:, node:}       # node 由本册 Node Projection 得出
contracts: {requirement_refs:, acceptance_refs:, design_refs:, test_refs:, build_refs:}
agent:   {role:, permissions:}        knowledge: {codegraph_refs:, openviking_refs:}
execution: {task_id:, attempt:, parent_agent:} artifacts: {input:, output:}
human:   {approvals:}
```

**硬规则**：`comet.stage/state/node` 必须来自 Comet Plugin，**不得来自文件名或目录推断**。

---

# 3. 节点特化总表

本章是八节点特化的索引。每一行的 `node id`、`kind`、`原生 Skill`、`Output Schema`、`Guard` 均来自 Comet 本体，**不得改写**；`UFS 执行 Agent`、`UFS 方法论 Skill`、`Human Gate`、`特化要点` 是本设计注入的部分。

## 3.1 八节点总表

| # | node id | kind | 原生 Skill | Output Schema | Guard（node guardrail） | UFS 执行 Agent | 方法论 Skill（原生 / UFS 特化） | Human Gate |
|---|---|---|---|---|---|---|---|---|
| N1 | `open` | control | `comet-open` | `comet.intake.v1` | `.comet.yaml exists`（state-transition） | `ufs-main`（门禁 `ufs-document-review`） | `atdd-development` | 需求确认 |
| N2 | `design` | producer | `comet-design` | `comet.design.v1` | design artifacts（artifact-structured） | `ufs-exploration`→`ufs-design`→`ufs-test-design` | `ufs-test-design` | 架构批准 + 验证策略批准 |
| N3 | `plan` | producer | `comet-build` | `comet.plan.v1` | plan artifacts（artifact-structured） | `ufs-build-plan` | `ufs-writing-plans` | Build Plan 批准 |
| N4 | `execute` | control | `comet-build` | `comet.execution-evidence.v1` | build evidence（semantic） | `ufs-coding` | `ufs-tdd` | 阶段内决策点 |
| N5 | `subagent-execute` | handoff | `subagent-driven-development` | `comet.handoff.v1` | handoff evidence（evidence-only） | OMO / Comet 实现子代理 | `subagent-driven-development` | —（主会话验收） |
| N6 | `review` | guardrail *(optional)* | `requesting-code-review` | `comet.review.v1` | review evidence（evidence-only） | `ufs-code-review` | **`ufs-code-review`（特化，取代 `requesting-code-review`）** | —（自动，Hook 保证证据） |
| N7 | `verify` | control | `comet-verify` | `comet.verify.v1` | verify result（evidence-only） | `ufs-verification` | `ufs-verification` | 验收 |
| N8 | `archive` | control | `comet-archive` | `comet.archive.v1` | archive state（state-transition） | `ufs-main` + Human | `comet-archive` | 最终决策（7 条件） |

## 3.2 Output Schema 与产物映射

**产物的物理根由 `pathBase` 冻结**；下表只列 schema ↔ evidence 的对应，路径解析以**主文档 §8.2** 为准。

```text
comet.intake.v1       artifact: comet-state(changes/*/.comet.yaml, classic-openspec-root)
              evidence: intake-summary
comet.design.v1       artifact: design-doc(specs/*.md, classic-superpowers-root)
                   + delta-spec(changes/*/specs/*/spec.md, classic-openspec-root)
              evidence: design-summary, user-confirmation
comet.plan.v1        artifact: implementation-plan(plans/*.md, classic-superpowers-root)
                   + openspec-tasks(changes/*/tasks.md, classic-openspec-root, 非必需)
              evidence: producer-summary
comet.execution-evidence.v1 artifact: task-state(changes/*/tasks.md, classic-openspec-root)
              evidence: implementation-summary, test-evidence
comet.handoff.v1      无 artifact                    evidence: handoff-request, handoff-result
comet.review.v1       无 artifact                    evidence: review-summary; review-blockers(非必需)
comet.verify.v1       无 artifact                    evidence: verification-commands, verification-result
comet.archive.v1      无 artifact                    evidence: archive-summary, archived-state
```

**实现层观察**：`review` / `verify` / `archive` 三个节点在 Comet 原生 schema 中**没有 artifact，只有 evidence**（`artifacts: []`）。因此 UFS 特化不得为它们发明新的 OpenSpec 目录文件，**也不存在** `.comet/evidence/<change>/*.json` 这类持久化文件——它们的产物形态是 **evidence 记录**，由 Runtime `collectClassicEvidence()` 从真实文件（`proposal` / `design` / `tasks` / delta spec / plan 等）**运行时推导**。设计早期曾按目录为它们安排 `verification.md` 一类文件，这与 Comet 原生 schema **不一致**；以主文档 §8.2 的权威表为准。

## 3.3 Guard 类型语义

| validation | 语义 | 失败即 |
|---|---|---|
| `state-transition` | 状态字段必须发生指定迁移（如 phase 改变、archive 确认） | BLOCK 节点完成 |
| `artifact-exists` | 声明的路径存在 | BLOCK |
| `artifact-structured` | 文件存在且具备必需结构（章节/字段），可被机器解析 | BLOCK |
| `semantic` | 语义级检查（如 build evidence 与已批准任务的对应） | BLOCK |
| `evidence-only` | 仅要求 evidence 记录存在，不要求文件产物 | BLOCK |

**Hook 挂载规则（G36：两个术语不得混用）**：**`guardrail`** 指 Comet Node 契约里的 `Guard` 字段（取值如 `archive state（state-transition）`、`review evidence（evidence-only）`）；**`artifact validation`** 指 `builtins.ts` 里的产物校验（`artifact-exists` / `artifact-structured`）——**`artifact-exists` 不是 guardrail**。
挂载映射：Stage Hook 实现 `state-transition`；Stage Gate Hook 实现 `artifact-exists` + `artifact-structured`（**artifact validation**，非 guardrail）；Build Gate Hook 实现 `semantic`；Verify / Close Hook 实现 `evidence-only` 的升级版（见 §7.3）。

---

# 4. 八节点特化详解

本章是**本册的骨干**。每个节点给出九项：`node id / kind / 原生 Skill / Output Schema / Guard / UFS 特化实现 / 执行 Agent / Human Gate / 禁止项`，并在末尾给出"相对原生 Skill 改了哪些"的差异清单。

## 4.1 节点 `open`

| 项 | 内容 |
|---|---|
| **node id** | `open` |
| **kind** | `control` |
| **原生 Skill** | `comet-open`（`implementation.operation: default`，`scope: main`） |
| **Output Schema** | `comet.intake.v1` |
| **Guard** | `.comet.yaml exists`（`state-transition`） |
| **执行 Agent** | `ufs-main`；门禁 `ufs-document-review`；专家 `ufs-firmware-expert`（按需） |
| **Human Gate** | 需求确认（Comet 原生）+ AC 批准（方法论层） |

**UFS 特化实现（相对原生 Skill 的差异）**：

| # | 原生 `comet-open` 行为 | UFS 特化 |
|---|---|---|
| O-1 | intake 用户自然语言请求 | intake **Stage 0 的 Frozen Story 清单**（`comet-artifacts/requirements/**`） |
| O-2 | `proposal.md` / `specs/**/spec.md` 是需求权威 | 二者降级为**镜像**；权威在 Stage 0 需求基线 |
| O-3 | 无 Stage 0 概念 | 校验 Frozen Story 存在性与 Freeze 记录，否则 BLOCK 回 Stage 0 |
| O-4 | change 形态由用户选择 | 形态选择必须同时确定 `workflow ∈ {full, hotfix, tweak}`，因为它决定 `open-complete` 去 `design` 还是 `build` |
| O-5 | 初始化 `.comet.yaml` | 同原生命令，**但必须经 Comet Plugin**（`ufs-main`），Agent 不得手写状态文件 |
| O-6 | 不产出任务 | **明确不产出 `tasks.md`**；任务权威归 `plan` 节点 |
| O-7 | 方法论由 `comet-open` 内置 | 节点内挂载 `atdd-development` 作为方法论 Skill，产出 intake summary 的方法依据 |

**禁止项**：
- 不重新定义需求；不写实现方案；不写函数签名 / 数据结构 / 算法；
- 不静默修改 Frozen Story 的 AC / Scope；
- 不绕过 Human 需求确认。

**回流**：`open` 发现需求冲突或 Frozen Story 不完整 → 回流 Stage 0 重新 Challenge。

## 4.2 节点 `design`

| 项 | 内容 |
|---|---|
| **node id** | `design` |
| **kind** | `producer` |
| **原生 Skill** | `comet-design`（default / main） |
| **Output Schema** | `comet.design.v1` |
| **Guard** | design artifacts（`artifact-structured`，作用于 `design-doc` + `delta-spec`） |
| **执行 Agent** | Step 0 `ufs-exploration` → Step 1 `ufs-design` → Step 2 `ufs-test-design` |
| **Human Gate** | 架构批准 + 验证策略批准 |

**UFS 特化实现**：

```text
Step 0 工程调查（Comet 原生 open 不承担，归入本节点）
    ufs-exploration → Exploration Report
    CodeGraph / graphify / OpenViking / Git 全部只读
Step 1 设计
    ufs-design → design.md（技术决策权威）
    必须读取 Requirement / AT / CodeGraph / OpenViking
Step 2 验证设计
    ufs-test-design → test-design.md（验证契约权威）
    判定 Verification Level、Unit Boundary、Mock 策略
```

| # | 原生 `comet-design` 行为 | UFS 特化 |
|---|---|---|
| NG-1 | 无强制探索步骤 | 新增 Step 0 Exploration，产物 `exploration-report.md` 作为 Step 1 的必要输入 |
| NG-2 | 输出 design-doc 与 delta-spec | 追加 `test-design.md` 作为**验证契约权威**，但该文件**不在 `comet.design.v1` 的 artifacts 中** |
| NG-3 | guard 只看 design artifacts | **UFS 追加 Stage Gate 检查**：`test-design.md` 存在 + Verification Level 字段非空；因为原生 guard 不覆盖它 |
| NG-4 | 不区分设计与验证承担者 | 两个 Agent 串行承担；`ufs-design` 不得替 `ufs-test-design` 决定验证层级 |
| NG-5 | 无 DESIGN_BLOCKER | 需求错误/不完整 → `STOP` + `DESIGN_BLOCKER`，不得静默重新解释 |
| NG-6 | 可挂 OMO Team | `Comet → design → OMO Team {Architecture, Firmware Expert, Test Design} → Team Result → Design Agent` |

**Human Gate 细化**：

| Gate | 闸门对象 | 阻塞后果 |
|---|---|---|
| 架构批准 | `design.md` / Design Doc | 未批准不得进入 `plan` |
| 验证策略批准 | `test-design.md`（Verification Level + 测试形态选择） | 未批准不得进入 `plan` |

**禁止项**：
- 不重定义用户可见行为；不自行改变 Acceptance Contract；
- 需求错误或不完整时不得静默重新解释（必须 `DESIGN_BLOCKER`）；
- `ufs-exploration` 不得修改源码 / 测试 / 需求 / AC / 已批准设计；
- `ufs-design` 不得产出可执行测试代码。

## 4.3 节点 `plan`

| 项 | 内容 |
|---|---|
| **node id** | `plan` |
| **kind** | `producer` |
| **原生 Skill** | `comet-build`（**与 `execute` 同一原生 Skill**） |
| **Output Schema** | `comet.plan.v1` |
| **Guard** | plan artifacts（`artifact-structured`，作用于 `plans/*.md`；`tasks.md` 非必需但 UFS 要求必需） |
| **执行 Agent** | `ufs-build-plan` |
| **Human Gate** | Build Plan 批准 |

**UFS 特化实现**：

| # | 原生 `comet-build`（Step 2：创建/恢复计划） | UFS 特化 |
|---|---|---|
| P-1 | 计划文件在 `plans/<date>-<change>.md` | 同原生；UFS 追加 `<!-- comet-task-authority: <tasks-ref> -->` 与 `<!-- comet-task-ref:<task-id> -->` 映射 |
| P-2 | Build Task 只要求"可独立验收的结果" | UFS 强制 **一个 Build Task = 一个工程实现步骤**，**不得把每个 UT case 直接转成一个 Build Task** |
| P-3 | 计划可简写 | UFS 强制核心字段超集（见下） |
| P-4 | 用 CodeGraph 辅助 | UFS 把 `codegraph_evidence` 列为**必填字段**（含 query/result/commit/timestamp） |
| P-5 | 无 Verification Level 判定 | hotfix / tweak 下 `design` 节点被跳过，**必须在本节点内以轻量形式补做 Verification Level 判定** |
| P-6 | `tasks.md` 完成状态由 Build 维护 | `tasks.md` 是**任务状态唯一权威**，由本节点产出，`execute` 只勾选不改结构 |

**核心输出契约字段**：

```yaml
task_id:      title:       purpose:
design_refs:    acceptance_refs:  test_refs:
scope:        # {files: [...], functions: [...]}
dependencies:  implementation_steps:  verification:
expected_result:   risks:   codegraph_evidence:
tdd:          testability_constraints:
verification_method:  verification_level:  required_regression_level:
state_machine_impact: data_structure_impact: concurrency_interrupt_impact:
verification_strategy_consumed:  non_testable_consumed:

# 以上仅为字段名速览；**Build Task 字段集的唯一定义处是分册 02 §9.6.3**（含 ★ 扩展与消费声明）。
```

**`scope.files` 的生成规则（实现层新增）**：

```yaml
build_task:
 task_id: IMP-001-02
 scope.files:      # ← 这就是 Hook 的 allow-list 来源（唯一权威：分册 02 §9.6.3）
  - src/host/flow_control.c
  - test/host/test_flow_control.c
 codegraph_impact:      # ← 影响面分析的来源；产出 potential_files，仅作 Human Review 材料，不构成放行集
  potential_files: [src/host/host_queue.c]
```

**禁止项**：不写实现；不预写完整代码（除必须提前评审的接口/高风险算法）；不改 AC / Design；不新增第二套 checkbox（`tasks.md` 是唯一权威）。

## 4.4 节点 `execute`

| 项 | 内容 |
|---|---|
| **node id** | `execute` |
| **kind** | `control` |
| **原生 Skill** | `comet-build`（**与 `plan` 同一原生 Skill**） |
| **Output Schema** | `comet.execution-evidence.v1` |
| **Guard** | build evidence（`semantic`，作用于 `changes/*/tasks.md`） |
| **执行 Agent** | `ufs-coding` |
| **Human Gate** | 阶段内决策点（Scope 变更 / Test Contract 变更 / preset 升级） |

**UFS 特化实现**：

| # | 原生 `comet-build`（Step 3：执行与验收） | UFS 特化 |
|---|---|---|
| E-1 | 按 `build_mode` 执行 | UFS 只承认 `tdd_mode: tdd` 的完整 RED→GREEN→REFACTOR；`direct` 仍须缺陷回归证据 |
| E-2 | 异常调试协议 | 测试失败**不得立即改代码**，先由 `ufs-failure-analysis` 分类四类并按类路由 |
| E-3 | 逐任务 RED/GREEN 由 Skill 约束 | UFS 增加 **RED/GREEN Evidence Hook** 自动记录，证据缺失即被 Verify 发现 |
| E-4 | 无 Legacy 显式路径 | UFS 原生支持 Legacy：`CodeGraph → Existing Behavior → Characterization Test → Baseline GREEN → New Behavioral Test → RED → Implementation` |
| E-5 | 无写前检查 | UFS 在每次写入前经过 **Code Write Hook**（本册最重要 Hook，见 §7.3） |
| E-6 | 无范围保护 | UFS 增加 Scope Control + CodeGraph Impact Check；超范围走 Human Review / BLOCK |
| E-7 | 无 node 区分 | UFS 用 Node Projection 保证写入只发生在 `execute` / `subagent-execute` |

**TDD 循环**：

```text
Build Task → Test Preparation → RED → Implementation → GREEN → REFACTOR → Regression → Evidence
```

**Legacy 路径**：

```text
CodeGraph → Existing Behavior → Characterization Test → Baseline GREEN
     → New Behavioral Test → RED → Implementation → GREEN → REFACTOR → Regression
```

**禁止项**：
- 为通过测试而修改 AC；为取得 GREEN 而修改预期行为；
- 静默修改已批准 Design；扩大 Scope；修无关缺陷；
- 自行修改 Test Contract；写 Requirement / AC。

## 4.5 节点 `subagent-execute`

| 项 | 内容 |
|---|---|
| **node id** | `subagent-execute` |
| **kind** | `handoff` |
| **原生 Skill** | `subagent-driven-development`（`scope: handoff`） |
| **Output Schema** | `comet.handoff.v1`（**无 artifact**） |
| **Guard** | handoff evidence（`evidence-only`） |
| **执行 Agent** | OMO / Comet 实现子代理（implementer） |
| **Human Gate** | —（主会话验收；阻塞情形见下） |

**UFS 特化实现**：

| # | 原生 handoff | UFS 特化 |
|---|---|---|
| H-1 | 交接请求 + 返回证据 | `handoff-request` 必须含 taskIds、允许修改范围、验收要求；`handoff-result` 必须逐 task ID 列出文件、提交、命令与真实结果 |
| H-2 | 无返回状态约定 | 实现子代理必须返回 `DONE / DONE_WITH_CONCERNS / BLOCKED / NEEDS_CONTEXT` |
| H-3 | 无独立性约束 | 审查子代理必须独立于实现子代理；**不能让实现者审查自己的代码** |
| H-4 | 无复查上限 | `review_mode` → 复查上限 `off: 0 / standard: 1 / thorough: 2`；达上限未解决 → `BLOCKED` |
| H-5 | 无协作记录 | 交接包落 `<classic-change-dir>/.comet/handoff/`；协调状态经 `comet state checkpoint` 保存 |
| H-6 | OMO 为唯一选项 | **MVP 用 Comet 子代理派发**（`build_mode: subagent-driven-development` + `subagent_dispatch: confirmed`）；OMO 第二阶段接入 |
| H-7 | 无裁定记录 | 范围内的实现决定写入 `<classic-change-dir>/.comet/rulings.md`，供审计与恢复 |

**handoff evidence 最小字段（实现层规定）**：

```yaml
handoff:
 change_id: host-write-flow-control
 task_ids: [IMP-001-02, IMP-001-03]
 dispatched_to: implementer
 reviewer: independent
 request: {scope: [...], acceptance: [...], checks: [...]}
 result:
  status: DONE | DONE_WITH_CONCERNS | BLOCKED | NEEDS_CONTEXT
  per_task:
   - {task_id:, files: [], commits: [], commands: [], results: [], gaps: [], risks: []}
```

**升级为 Human 的四种阻塞**：不可逆/破坏性操作；安全敏感动作；工作区之外的副作用（merge / push / publish）；计划已破碎到每条路径都是猜测。

**禁止项**：
- 主会话不得代替仍在工作的实现子代理编写代码；
- 实现子代理不得自我验收、不得勾选 `tasks.md`；
- 审查子代理不得与实现子代理为同一实例；
- 子代理不得向下继续派发任务；
- 不得无限新建会话反复审查（受 `review_mode` 复查上限约束）。

## 4.6 节点 `review`

| 项 | 内容 |
|---|---|
| **node id** | `review` |
| **kind** | `guardrail`，**`optional: true`** |
| **原生 Skill** | `requesting-code-review` |
| **Output Schema** | `comet.review.v1`（`review-summary` 必需、`review-blockers` 非必需） |
| **Guard** | review evidence（`evidence-only`） |
| **执行 Agent** | `ufs-code-review` |
| **Human Gate** | —（自动；由 Hook 保证证据） |

**UFS 特化实现：`ufs-code-review` 取代 `requesting-code-review`**

> `ufs-code-review` 是 `review` 节点的唯一承担者，Code Review 的结论是 Verify 与归档的必备输入。

| 维度 | 通用 `requesting-code-review` | UFS `ufs-code-review` |
|---|---|---|
| 触发 | 每个任务后 / 大特性后 / merge 前 | `review` 节点 + `review_mode` 决定粒度（见下） |
| 上下文 | 构造 `{DESCRIPTION}{PLAN}{BASE_SHA}{HEAD_SHA}` 交给 `general-purpose` 子代理 | 交给 `ufs-code-review` Agent；上下文含 Design / Build Plan / Test Contract / CodeGraph 事实 |
| 审查焦点 | 通用代码质量与需求符合度 | 追加 **UFS 固件维度**（见下） |
| 输出 | 自由文本 findings | 结构化 `comet.review.v1`（`review-summary` + `review-blockers`） |
| 独立性 | 建议独立 | **硬规则**：与被审代码的编写者不得是同一执行实例 |
| 后果 | 建议修复 | **severity ∈ `BLOCKER` / `MAJOR` / `MINOR` / `NOTE`**（分册 02 §11.9.2 冻结的闭集）：`BLOCKER` 未解决不得进入 `verify`；由 Verify Hook（H12）复查。（原 `CRITICAL/IMPORTANT` 写法已撤回，G05） |

**UFS 固件特有审查维度**：

| # | 维度 | 典型缺陷 |
|---|---|---|
| R1 | 中断上下文 | ISR 中调用阻塞函数、加锁、动态分配 |
| R2 | 寄存器 / 内存映射访问 | 缺 `volatile`、位域顺序假设、越权写保留位 |
| R3 | DMA 一致性 | cache 维护缺失、缓冲区对齐与生命周期 |
| R4 | 时序假设 | 未文档化的硬件时序依赖、忙等超时缺失 |
| R5 | 并发 / 可重入 | 共享状态无保护、重入路径缺失 |
| R6 | 错误与恢复 | 错误路径未覆盖、恢复不完整 |
| R7 | 资源约束 | 栈深、堆碎片、队列深度、功耗状态 |
| R8 | 契约符合度 | 代码与 `design.md` / Build Plan / Test Contract 不一致 |
| R9 | Scope 漂移 | 改动超出 `scope.files` 或含未批准重构 |

> **两套命名的关系（G37）**：本表 `R1`–`R9` 是**代码审查维度**（分册 02 **§11.8.1 五维审查矩阵**展开出的维度清单）；`F1`–`F6` 是**固件风险清单**（分册 02 **§11.9.3**）。二者**不是同一空间**：`R*` 是“看什么维度”，`F*` 是“固件特有风险项”。
> **映射（逐条，F 侧定义以分册 02 §11.9.3 为准）**：`R1`(中断上下文) → `F1`(中断上下文安全)；`R2`(寄存器/内存映射) → `F2`(寄存器访问)；`R3`(DMA 一致性) → `F3`(DMA 一致性)；`R4`(时序假设) → `F4`(时序假设)；`R7`(资源约束) → `F5`(资源所有权)；`R6`(错误与恢复) → `F6`(错误处理)。
> **无 `F*` 对应的维度**：`R5`(并发/可重入) 与 `R1` 同族但 `F1` 已覆盖其检查项；`R8`(契约符合度) / `R9`(Scope 漂移) **无对应 `F*`**（属契约与范围维度，不是固件风险项）。

**`review_mode` → review 节点参与度的映射**：

> 原生 `review_mode ∈ {off, standard, thorough}` 控制"任务级审查 + Verify 唯一最终集成审查"；本设计把它映射到 `review` 节点，避免出现两套审查语义。

| `review_mode` | Build 内任务级审查 | `review` 节点 | Verify 最终集成审查 |
|---|---|---|---|
| `off` | 不自动分配 | 若 `review` 节点被启用则执行一次 | 仍须完成一次（不能省） |
| `standard` | 仅高风险任务 | 执行一次（默认启用） | 执行唯一一次最终集成审查 |
| `thorough` | 每任务独立审查 | 执行，且按任务/分段逐项 | 执行唯一一次最终集成审查 |

**禁止项**：
- 不改被审代码，只返回结论 + findings；
- 不得与代码编写者同一执行实例；
- 不得用实现摘要代替对实际 diff 的审查；
- 不得预先要求审查者忽略某类问题。

## 4.7 节点 `verify`

| 项 | 内容 |
|---|---|
| **node id** | `verify` |
| **kind** | `control` |
| **原生 Skill** | `comet-verify` |
| **Output Schema** | `comet.verify.v1`（`verification-commands` + `verification-result`） |
| **Guard** | verify result（`evidence-only`） |
| **执行 Agent** | `ufs-verification`；专家 `ufs-failure-analysis`（按需） |
| **Human Gate** | 验收（`READY_FOR_HUMAN_ACCEPTANCE`） |

**UFS 特化实现**：

| # | 原生 `comet-verify` | UFS 特化 |
|---|---|---|
| V-1 | 规模评估 + 验证命令 + 结果 | 验证**整条链**：`Requirement → Acceptance → Design → Test Design → Build Plan → Code Change → Test Result → Evidence` |
| V-2 | 不消费 Code Review | **必须消费 `comet.review.v1`**；缺 review evidence 由 Verify Hook BLOCK |
| V-3 | 结果枚举 | `READY_FOR_HUMAN_ACCEPTANCE / NEEDS_REVISION / BLOCKED` + 明确证据 |
| V-4 | 失败回流 | `verify-fail` → **build**（Comet 原生迁移）；`verify_result=fail` 保留 verificationReport |
| V-5 | 无 12 问 | UFS 强制回答 12 问（需求/AC/AT 覆盖、Verification Level、测试形态、结果可信度、Design/Build Plan 符合度、未批准 Scope、未解决问题、Evidence 完整性、归档条件） |
| V-6 | 无追溯脊柱 | UFS 追加追溯完整性检查（`REQ→…→EVIDENCE`） |

**原则**：`Tests passing alone is insufficient`。

**禁止项**：
- 不做代码修改；不改契约；不改 Test；
- 不得"自己写代码 → 自己说代码正确"（与实现实例保持独立）；
- 不得以覆盖率作为完成的唯一判据。

## 4.8 节点 `archive`

| 项 | 内容 |
|---|---|
| **node id** | `archive` |
| **kind** | `control` |
| **原生 Skill** | `comet-archive` |
| **Output Schema** | `comet.archive.v1`（`archive-summary` + `archived-state`） |
| **Guard** | archive state（`state-transition`）；迁移层另有 `verify-result-pass` + `archive-confirmed` |
| **执行 Agent** | `ufs-main` 组装 + **Human 决策** |
| **Human Gate** | 最终决策（归档条件 7 项） |

**归档条件（全部满足，不是"测试通过"）**：

```text
Requirement Covered ∧ Acceptance Covered ∧ Verification Complete
∧ Code Review Complete ∧ Evidence Complete ∧ No Blocking Issue
∧ Human Accepted
```

**UFS 特化实现**：

| # | 原生 `comet-archive` | UFS 特化 |
|---|---|---|
| A-1 | 归档 OpenSpec change + 同步 delta | 同原生（经 `comet classic openspec` 适配器） |
| A-2 | 无 7 条件 | UFS 由 **Close Hook** 逐条机器检查 7 条件，任一不满足 `BLOCK ARCHIVE` |
| A-3 | 无证据包 | UFS 要求追溯索引与 Human 批准记录齐备；离线证据包按 `99 D79`（追溯索引）与 §14.1 IR-4（入库口径） |
| A-4 | 归档=commit？ | UFS 明确：**验证通过 ≠ 归档授权**；归档目录存在 ≠ 提交/push/PR 完成 |

**禁止项**：仅因测试通过就归档；带 Blocking Issue 归档；无 Human Acceptance 归档。

## 4.9 `plan` 与 `execute` 共用 `comet-build` 的拆分设计

**问题**：Comet 原生把 `plan`（producer）和 `execute`（control）**都**声明为 `implementation.skill: comet-build`。若照搬，`plan` 与 `execute` 没有实现层区分，Code Write Hook 无法判断"现在能不能写源码"。

**拆分设计**：按 Comet 原生已给出的三重差异切割，不修改 Skill 本身。

| 切分依据 | `plan` | `execute` |
|---|---|---|
| Comet `kind` | `producer`（只产出，不改代码） | `control`（可控制执行，含代码写入） |
| Comet `Output Schema` | `comet.plan.v1`（`plans/*.md` + `tasks.md`） | `comet.execution-evidence.v1`（`tasks.md` + evidence） |
| Comet `Guard` | `artifact-structured`（文件结构） | `semantic`（证据与任务对应） |
| `comet-build` 步骤 | **Step 1–2**（确认执行策略、创建/恢复计划） | **Step 3–4**（执行与验收、Spec 增量更新） |
| Agent | `ufs-build-plan` | `ufs-coding` |
| 写权限 | 仅 `plans/*.md`、`tasks.md` | 源码 + 测试代码（经 Hook 放行） |
| Hook 闸门 | Stage Gate（plan artifacts） | Build Gate + Code Write Hook + TDD Hook |

**Node Projection 规则（把 phase=build 拆成 4 个 node）**：

```text
phase == build 时：
 if 尚无 tasks.md 或计划未批准       → node = plan    （可由 build_pause=plan-ready 佐证，但仅表示待批）
 elif build_mode == subagent-driven-development 且有活跃 handoff → node = subagent-execute
 elif review_mode 要求且存在未审 diff    → node = review
 else                    → node = execute
```

**为什么必须补投影（精确版）**：Comet 已有的部分判别器只能覆盖 `plan` 与 `execute` 的**入口**——`build_pause=plan-ready` 标记的是 `plan` 的待批暂停，`build_mode` 只描述实施策略。二者**都无法给出 `subagent-execute` / `review` 的节点身份**，也无法在 `build` 内回答 Code Write Hook 的"当前是否处于允许写源码的节点"。更严重的是，`build_mode` 当前不可可靠回读（§13.3 G2），会连带使 `plan`/`execute` 的入口判别退化为"只看是否已有 tasks.md"。因此投影不是便利设施，而是 H04 的 ② 级判定的前置条件。

**投影权威与一致性**：Comet 0.4.0-beta.19 的状态对象**没有** `node` 字段；已有字段为 `phase`、`build_pause`、`build_mode`、`tdd_mode`、`review_mode`、`verify_mode`（`classic-state.ts` L16-L45）。本册决定（与主文档 §2.8、`99 D60`、§14.1 `IR-1` 同向）：**节点身份由 Plugin 判定**（`get_current_node()`），**经 Runtime 的状态写路径与 `phase` 同事务原子写入**；**Hook 只读**，不一致即 fail-closed。**唯一权威表述在主文档 §2.8**；本册只给实现位。原始表述“投影由 **Plugin 判定、经 Runtime 与 `phase` 同事务落盘**（唯一权威表述见主文档 §2.8；`99 D60`）”已按 A45 更正，不再出现。

---

# 5. preset 裁剪与补偿

## 5.1 节点裁剪矩阵

| node | `full` | `tweak` | `hotfix` |
|---|---|---|---|
| `open` | ✅ | ✅ | ✅ |
| `design` | ✅ 完整（Exploration + Design + Test Design） | ❌ **跳过** | ❌ **跳过** |
| `plan` | ✅ 完整计划 | ⚠️ **简化任务清单**（仍产出 `tasks.md` 权威） | ⚠️ **简化任务清单** |
| `execute` | ✅ RED→GREEN→REFACTOR | ✅ 可省 REFACTOR 证据 | ✅ + **根因消除检查** |
| `subagent-execute` | ✅（若选子代理策略） | ✅（若选） | ✅（若选） |
| `review` | ✅ | ✅ | ✅ |
| `verify` | ✅ | ✅ | ✅ |
| `archive` | ✅ | ✅ | ✅ |

**被跳过的节点只有 `design`**；`plan` 不是被跳过而是被降级。**任何 preset 都不跳过 `review` / `verify` / `archive`**，因此安全闭环不随 preset 变弱。

## 5.2 跳过 `design` 后的补偿（引用，不自行推导）

**方法论归属**：跳过 `design` 后如何在 `plan` 内补做 **Verification Level 判定**，属**方法论层**——其规范文本由 **分册 01 §4.8**（Verification Level 判定与补偿）与 **分册 02 §9.8**（`ufs-writing-plans` 的轻量补偿条款）持有。本册**只引用，不自行推导**，仅在实现层列出各缺口由哪个部件承担：

| 缺口 | 由谁承担（实现层挂载） | 规范出处 |
|---|---|---|
| Verification Level 判定缺失 | `plan` 节点内以轻量形式补做，写入 Build Task 的 `verification_level:` 字段 | **01 §4.8** / **02 §9.8** |
| 无 `test-design.md` | 计划内嵌测试形态与最小验证集合 | **01 §4.8** / **02 §9.8** |
| 无架构批准 Gate | 由 **Build Plan 批准 Gate** 合并承担 | 分册 01 §4.8.3（preset 裁剪与 design 缺口的实现层挂载） |
| 无 `ufs-test-design` 运行 | Test Contract Protection Hook 仍生效（H08） | 本册 §7.3 |
| 无探索报告 | CodeGraph Impact Check 在写入时补事实（H06） | 本册 §7.3 |
| 需求本身有缺陷 | `preset-escalate` 升级到 `full` | 本册 §5.4、主文档 §9.2 |

**硬约束**：`hotfix` / `tweak` 下 **`ufs-test-design` 不运行**，因此该 Agent 在此两 preset 下**不获得任何节点槽位**；任何"因为跳过 design 就不判验证层级"的实现都违反本设计。

## 5.3 hotfix 的根因消除检查

hotfix 的构建结束不是"改完即止"，而是：

```text
execute → 根因消除检查 → verify → archive
```

| 检查 | 内容 | 失败动作 |
|---|---|---|
| 根因是否消除 | 修复针对的是根因而非症状（对照 Failure Classification，**分册 01** 持有分类语义） | 回 `execute`（仍受 Code Write Hook 约束） |
| 是否触发升级判定 | 接口变更 / 架构调整 / 改动扩散超阈值 | 暂停并请 Human 选择"继续"或 `preset-escalate` |
| 回归是否执行 | 至少缺陷路径回归（**等级下限以分册 01 §10.3 为准**） | 不得进入 `verify` |

**补偿关系**：根因消除检查是**跳过 `design` 的等价物**——它把本应由设计阶段回答的"这是不是正确的修法"压缩成一个执行期的强制检查点。

## 5.4 `preset-escalate` 的实现语义

| 项 | 值 |
|---|---|
| 触发事件 | `preset-escalate` |
| from | `build` |
| guard | `preset-workflow`（仅 `hotfix` / `tweak` 可升级，否则抛错） |
| to | `full`（`workflow`→`full`、`classicProfile`→`full`、`phase`→`design`）。**术语**：状态字段是 **`workflow`**（取 `full`/`hotfix`/`tweak`）；`classicProfile` 是 Comet 的**兼容字段名**；事件名是 **`preset-escalate`**；三者指同一“preset 身份”，但**不得互换使用**（G39） |
| 副作用 | 清空 `designDoc / buildPause / buildMode / subagentDispatch / tddMode / reviewMode / isolation / boundBranch / verifyMode / directOverride` |
| 触发者 | `ufs-main` + Human 决策（决策点，阻塞） |

**实现层后果**：升级后 `design` 节点重新启用，此前在 `plan` 内补做的 Verification Level 判定必须**在 `design` 中被正式重做**（否则同一 change 存在两份不一致的验证契约）。

---

# 6. Plugin 层

Plugin 是**能力层**：它把外部系统（Comet Runtime / CodeGraph / OpenViking / OMO / 测试工具链 / 证据存储）封装成 Agent 可调用的稳定接口。Plugin **不做决定**、**不做强制**、**不持有生命周期**。

## 6.1 六类 Plugin 总表

| # | Plugin | 提供的能力 | 关联节点 | 第一版 |
|---|---|---|---|---|
| PL1 | **Comet Plugin** | 生命周期读写：stage / state / change context / build task / artifacts / human gate / transition | 全部八节点 | ✅ |
| PL2 | **CodeGraph Plugin** | 代码事实查询：symbol / reference / caller / callee / struct / variable / module / dependency / impact | `design`、`plan`、`execute`、Hook 层、`verify` | ✅ |
| PL3 | **Knowledge Plugin** | 企业知识与历史：search / get_document / get_decision / get_history / get_standard / store | `design`、`plan`、`execute`、专家 Agent | ✅（OpenViking 封装） |
| PL4 | **OMO Plugin** | Agent 协作：team / dispatch / parallel / collect / message / terminate | `design`、`subagent-execute` | ❌ 第二阶段 |
| PL5 | **Test Plugin** | 构建与测试执行：unit / component / integration / simulator / hardware / regression | `execute`、`verify` | ✅（Test Runner） |
| PL6 | **Evidence Plugin** | 证据与追溯：create / collect / record_* / build_traceability / generate_report | `execute`、`review`、`verify`、`archive` | ✅ |

**总原则**：

> **Plugin 可以提供能力，但不能绕过 Hook 的治理。**

## 6.2 Comet Plugin

| 项 | 内容 |
|---|---|
| **目的** | 使 OpenCode 侧能读取 Comet 的权威生命周期状态，并请求阶段迁移；消除"从文件名猜 stage" |
| **能力面** | `get_current_stage()`、`get_current_state()`、`get_change_context()`、`get_build_task()`、`get_artifacts()`、`request_human_gate()`、`approve_stage()`、`transition_stage()` |
| **返回示例** | `{stage: build, state: BUILD_TASK_RUNNING, change_id: host-write-flow-control, task_id: IMP-001-02}` |
| **约束** | ① 只有 `ufs-main` 可调用 `transition_stage()` / `approve_stage()`；② `request_human_gate()` 触发决策点，必须阻塞；③ 迁移必须走 Comet guard，Plugin 不得直接改 `phase`；④ 所有阶段判定必须来自本 Plugin，**禁止从文件名/目录推断** |
| **与节点关系** | 八节点的入口检查（`comet state check <name> <phase> --json`）与出口 guard 都经此 Plugin |

**实现层补充**：本 Plugin **判定**节点身份并提供 `get_current_node()`，因为 Hook 需要 node 粒度，而 Comet 已有的 `phase` + `build_pause` + `build_mode` 只能覆盖 `plan`/`execute` 的入口、无法区分 `subagent-execute` 与 `review`（见 §1.1、§4.9、§10.3）。投影的落盘与一致性校验按 §14 IR-1 执行——**经 Runtime 状态写路径与 `phase` 同事务**。

## 6.3 CodeGraph Plugin

| 项 | 内容 |
|---|---|
| **目的** | 代码事实查询接口；为影响分析、Scope 判定、Legacy 建模提供可追溯事实 |
| **能力面** | `find_symbol()`、`find_references()`、`find_callers()`、`find_callees()`、`find_struct()`、`find_variable()`、`find_module()`、`get_dependency()`、`get_impact()`、`get_file_symbols()` |
| **关键约束** | ① **不是 Requirement Source**，只提供 Implementation Evidence / Change Impact / Existing Behavior / Dependency Information；② 查询结果属**动态事实**，必须带 `source/query/result/repository/commit/timestamp`；③ 只读，禁止写入源码 |
| **与节点关系** | `design`（Step 0 事实）→ `plan`（Change Impact / File List / Function List）→ `execute`（Legacy 起点）→ Hook 层（Scope 漂移检测）→ `verify`（查询→结果→版本→证据） |

```yaml
# 任何进入 Evidence 的 CodeGraph 结果必须形如
source: codegraph
query: get_impact("EvaluateFlowControl")
result: [HostWriteHandler, RecoveryHandler, Scheduler, FlowControlTest]
repository: ufs_fw
commit: <sha>
timestamp: <iso8601>
```

## 6.4 Knowledge Plugin

| 项 | 内容 |
|---|---|
| **目的** | 统一封装 OpenViking / OpenWiki，避免 Agent 直接绑定底层知识系统 API |
| **能力面** | `search_knowledge()`、`get_document()`、`get_decision()`、`get_history()`、`get_standard()`、`store_knowledge()` |
| **关键约束** | ① 返回必须带 `source / document / section`；② 知识 ≠ 代码事实（与 CodeGraph 分离）；③ 只读为主，`store_knowledge()` 只接受可复用的稳定知识，不写任务摘要/测试结果 |
| **与节点关系** | `design` 的设计依据、`plan` 的既有约束、`ufs-firmware-expert` 的知识优先级、`ufs-failure-analysis` 的历史问题检索 |

```yaml
knowledge:
 - {source: internal_ufs_spec, document: ufs_error_handling.md, section: retry_policy, content: ...}
 - {source: design_history,  document: gc_flow_control_history.md, section: decision_2025_04, content: ...}
```

**输出纪律**：必须区分 `FACT / REFERENCE / ANALYSIS / ASSUMPTION`；绝不把假设当作事实呈现。

## 6.5 OMO Plugin

| 项 | 内容 |
|---|---|
| **目的** | 局部节点内的 Agent Collaboration Runtime；**不是生命周期管理器** |
| **能力面** | `create_team()`、`add_agent()`、`dispatch()`、`parallel_execute()`、`collect_results()`、`team_message()`、`terminate_team()` |
| **职责切分** | `Comet 负责：什么时候启动 Team / 什么时候结束 Team / Team 输出是什么`；`OMO 负责：Agent 如何协作 / 如何通信 / 如何并行` |
| **约束** | ① 不得推进 phase；② 不得绕过 Hook 使子代理获得额外写权限；③ 子代理不向下再派发；④ MVP 不接入 |
| **与节点关系** | 主要服务 `design`（Team Mode）；`subagent-execute` 在第二阶段由 OMO 承接（MVP 用 Comet 自身的子代理派发） |

## 6.6 Test Plugin

| 项 | 内容 |
|---|---|
| **目的** | 让 `ufs-tdd` Skill **不需要知道** `pytest / cmake / make / custom simulator / JTAG / hardware runner` 的具体实现 |
| **能力面** | `prepare_test()`、`run_unit_test()`、`run_component_test()`、`run_integration_test()`、`run_simulator_test()`、`run_hardware_test()`、`run_regression()`、`collect_test_result()` |
| **与节点关系** | `execute`（RED/GREEN/Regression）、`verify`（独立重跑）、Hook H07/H10/H12（读取结果） |

### 6.6.1 Test Contract ≠ Test Execution（关键规则）

```yaml
# Test Contract（来自 design/test-design，属契约，受 H08 保护）
test_id: TC-001-01
contract:
 given: {free_blocks: critical}
 when: host_write_requested
 then: {host_write: blocked}
```

```yaml
# Test Execution（来自 Test Plugin，属证据）
result:
 status: PASS
 started_at: <iso8601>
 finished_at: <iso8601>
 environment: {runner: simulator, build: <sha>}
 command: <实际执行的命令>
 stdout: <原样>
 stderr: <原样>
```

**术语冻结（G41）**：本册与全文档集只使用两个词——**`Test Contract`**（测试契约；首现可写“Test Contract（测试契约）”，此后一律写 `Test Contract`）与 **`Expected Behavior`**。**禁用**：裸用“契约”（必须带限定词）、`Design-Test Contract 批准`（撤回，应为“Design / Test Contract 批准”，两者是不同对象）、`Contract Protection` 等变体。

**结论**：**测试定义与测试执行证据不得混在一起**。实现层要求（`TCR-1`…`TCR-4` 是 Test Contract 的规则编号，属主文档 §5.1.1 表 N4，**不是**对象 ID）：

| 规则 | 约束 |
|---|---|
| TCR-1 | Test Contract 只能由 `design` 节点（`ufs-test-design`）产出，写入 `test-design.md` |
| TCR-2 | Test Execution 结果只能由 Test Plugin 产出；**Comet 原生下其 evidence 由 Runtime 推导**，不做独立落盘 |
| TCR-3 | Test Plugin **不得写入** `test-design.md` |
| TCR-4 | `ufs-coding` 可以写测试代码，但不得修改 `then` 断言的语义（H08 判定） |

## 6.7 Evidence Plugin 与审计副本（原“Evidence Package”已撤回，G44）

| 项 | 内容 |
|---|---|
| **目的** | 回答"为什么可以证明 Requirement 已满足"，并使该回答可被归档后重审 |
| **能力面** | `create_evidence()`、`collect_artifact()`、`record_test_result()`、`record_code_diff()`、`record_codegraph_query()`、`record_review()`、`record_human_approval()`、`build_traceability()`、`generate_report()` |
| **约束** | ① 每条 evidence 必须可定位到命令 / 查询 / diff / 批准记录；② 不得记录无来源的结论；③ Evidence ≠ 日志；④ **不得把 evidence 记录伪装成 Comet 产物文件** |

**两层必须分清**：

| 层 | 性质 | 位置 | 落地方式 |
|---|---|---|---|
| **第一层：运行时推导 evidence（Comet 原生，不可改）** | `collectClassicEvidence()` 从真实文件**推导**，检查 `proposal` / `design` / `tasks` / delta spec / `build.plan` 是否存在且合规 | 无独立文件 | 已存在，默认即用 |
| **第二层：审计副本（本设计新增）** | 为满足"归档后可离线复核"而落盘；含 review / verify 报告、测试与回归原始输出、CodeGraph 留痕、批准记录、追溯索引 | `comet-artifacts/evidence/<change>/` | 随 `comet-artifacts/` 默认入库；**副本缺失阻断归档**（H13，99 D07 / D44） |

**审计副本结构**：

```text
comet-artifacts/evidence/<change>/
├── index.md            # 归档汇总索引：四职能 / 结论 / 未关闭 BLOCKER 数（99 D44，四职能全入）
├── challenge/          # ufs-challenge 审计副本（challenge-report.md）
├── document-review/    # ufs-document-review 审计副本（findings）
├── review/             # ufs-code-review 审计副本（REV-*.md）
├── verify/             # ufs-verification 审计副本（verify.md）
├── test-results/      # Test Plugin 的原始执行输出
├── regression/
├── codegraph/         # 查询 → 结果 → repository/commit/timestamp
├── approvals/         # Human Gate 记录
└── (无 traceability 副本)  # 追溯关系统一落 comet-artifacts/traceability/traceability.yaml（99 D09），不入 evidence/
```

**四职能独立、不合并**：四个子树各自由对应职能的 Agent 写入，彼此不得改写；`index.md` 只做汇总（`99 D44`），不产生第二套结论。

**禁止**：创建 `review.json` / `verify.json` 这类"Comet 产物"；Comet 的 `comet.review.v1` / `comet.verify.v1` 仍是无文件的 evidence 记录。

**四类产物的区分（不得混淆）**：

```text
Agent Log = "AI 做了什么"
Test Log = "测试运行发生了什么"
Build Log = "构建发生了什么"
Evidence = "为什么可以证明 Requirement 已经满足"
```

**Evidence 最小结构**：

```yaml
evidence_id: EVD-001-01
requirement: [REQ-001]
acceptance: [AC-001-01]
tests:    [TC-001-01, AT-001-01]
code:    [src/host/flow_control.c]
result:   {status: PASS}
regression: {status: PASS}
review:   {status: APPROVED}
```

## 6.8 Plugin 硬原则与反例

**硬原则**：

> **Plugin 可以提供能力，但不能绕过 Hook 的治理。**

**具体反例（Test-Runner）**：

```text
允许：ufs-coding → Test Plugin.run_unit_test() → 返回 {status: PASS, command, stdout, exit_code}
   → Evidence Plugin.record_test_result() → 落盘

禁止：Test Plugin 内部判定 "所有测试 PASS" → 自行调用 Comet Plugin.transition_stage(verify)
禁止：Test Plugin 提供 approve_archive() / mark_complete() 之类接口
禁止：Test Plugin 直接写 tasks.md 的完成勾选
```

**能力与强制的边界表**：

| 动作 | Plugin | Hook | Agent | Human |
|---|---|---|---|---|
| 执行测试 | ✅ 提供能力 | — | 决定何时调用 | — |
| 记录测试结果 | ✅ 落盘 | — | — | — |
| 判定"测试通过 ⇒ 可归档" | ❌ | ⚠️ 只能判定"证据存在/命令 PASS" | ❌ | ✅ 最终决策 |
| 写入源码 | ❌ | ✅ 放行/阻断 | ✅ 执行 | 批准 Scope |
| 推进 phase | ❌（Plugin 只是通道） | ✅ 满足 guard 才放行 | ❌ | ✅ 关键 Gate |
| 修改 Test Contract | ❌ | ✅ H08 阻断 | ❌ | ✅ 唯一授权方 |

---

# 7. Hook / Enforcement 层

Hook 是平台的**强制层**。它把"应该做"变成"不做就不允许"。

## 7.1 四层 Hook 分类

| 层 | 保护对象 | 成员 | 判定风格 |
|---|---|---|---|
| **L-Stage（阶段）** | 阶段推进的合法性 | H01 Stage Hook、H02 Stage Gate Hook、H12 Verify Hook、H13 Close Hook | 迁移条件与阶段产物齐备性 |
| **L-Policy（策略）** | 权限、范围、契约 | H03 Build Gate Hook、H04 Code Write Hook、H05 Scope Control、H06 CodeGraph Impact Check、H08 Test Contract Protection Hook | allow-list + 显式扩展 |
| **L-Execution（执行）** | 执行纪律 | H09 TDD Hook、H10 Regression Hook、H11 Commit Hook | 前置条件是否具备 |
| **L-Evidence（证据）** | 证据采集与完整性 | H07 RED/GREEN Evidence Hook | 记录与完整性校验 |

> **H11 的层归属（M6）**：`H11 Commit Hook` **只归 L-Execution**；它在 L-Evidence 侧的「追溯引用留痕」是**副作用**，不构成第二个层归属。四层划分中任一 Hook **有且只有一个层**。

**与平台六层的关系**：平台的"Enforcement / Automation"是**第⑥层**；本节四层是第⑥层的内部结构。两者不是同一维度，不得互相取代。

**证据层的事件面**：`traceability Hook` / `evidence Hook` 以及 `pre-agent` / `post-agent`、`pre-tool` / `post-tool`、`pre-build` / `post-build`、`pre-test` / `post-test` 不单独立 Hook；其核心语义由 H07、H11、H12、H13 覆盖，其余作为后续扩展点（§14 IR-13）。

## 7.2 Hook 清单（13）

| # | Hook | 层 | 触发点 | 第一版 |
|---|---|---|---|---|
| H01 | Stage Hook | Stage | `pre-stage` / `post-stage` / `pre-transition` / `post-transition` | — |
| H02 | **Stage Gate Hook** | Stage | `pre-stage(<PHASE>)` | ✅ `stage-gate` |
| H03 | **Build Gate Hook** | Policy | 进入 `build` / `execute` 前 | ✅ `build-gate` |
| H04 | **Code Write Hook**（最重要） | Policy | `pre-code-write` | ✅ `code-write-scope` |
| H05 | **Scope Control**（唯一名称） | Policy | 文件写入判定（H04 链内第 ④ 步） | ✅（与 H04 合并为 Comet 原生 `code-write-scope`） |
| H06 | CodeGraph Impact Check | Policy | 随 Code Write | —（MVP 内联于 H04） |
| H07 | RED/GREEN Evidence Hook | Evidence | 每次 Build Task 的 RED→GREEN | — |
| H08 | **Test Contract Protection Hook** | Policy | `pre-test-contract-change` | ✅ `test-contract-protection` |
| H09 | TDD Hook | Execution | `pre-implementation` | — |
| H10 | Regression Hook | Execution | Build Task 完成前 | — |
| H11 | Commit Hook | Execution | `pre-commit` | — |
| H12 | **Verify Hook** | Stage | `pre-verify` | ✅ `pre-verify` |
| H13 | **Close Hook** | Stage | `pre-close`（最严格） | ✅ `pre-close` |

**MVP 6 个 Hook 与 13 个 Hook 的对应**：`stage-gate`=H02；`build-gate`=H03；`code-write-scope`=H04+H05（H06 内联）；`test-contract-protection`=H08；`pre-verify`=H12；`pre-close`=H13。未进 MVP 的具名 Hook 是 6 个：H01、H06、H07、H09、H10、H11（第二阶段，§14 IR-6）；`pre-agent` / `pre-tool` / `post-*` / traceability / evidence 事件面不单独立 Hook（§14 IR-13）。

## 7.3 逐 Hook 契约

统一字段：`触发点 / 输入 / 检查 / 失败动作 / 豁免（bypass）`。所有 Hook 的失败动作默认 `BLOCK`。

**豁免强度固定三档（G43）**，`豁免` 列只能取其中之一，**不得写“默认”限定**：
1. **`不可豁免`** —— 无任何绕过路径（本设计多数 Hook 属此档，如 H04/H13）；
2. **`须 waiver 记录`** —— 可绕过，但必须留下 `waiver_ref` 与理由（如 H11 的纯文档/配置提交）；
3. **`不适用`** —— 该 Hook 不产生豁免概念（如只输出 `WARN` 的检查）。

### 7.3.1 全量 Hook 契约对照表（13 个）

| # | Hook | 触发点 | 输入 | 检查 | 失败动作 | 豁免（bypass） |
|---|---|---|---|---|---|---|
| H01 | Stage Hook | `pre-stage`/`post-stage`/`pre-transition`/`post-transition` | 当前/目标 `phase`、`CLASSIC_TRANSITION_TABLE` 事件、`tasks.md` 完成态、测试执行记录、evidence 索引 | 例 `build→verify`：Build Complete？All Tasks Complete？Tests Executed？Evidence Generated？ | `BLOCK`（阶段不推进） | 仅 Human `waiver`（含理由 + 有效期）；阶段迁移类豁免必须记录 |
| H02 | **Stage Gate Hook** | `pre-stage(<PHASE>)` | 阶段必需产物清单、Open Review 结果、Human Approval、AC 文本、`design` artifacts、`verification_strategy` | 例 `design`：Requirement/AC/AT Exists？Open Review Passed？Human Approval？UFS 追加：`test-design.md` 存在且 Verification Level 非空、**AC 禁例词机械扫描**、**`design` 函数名模式检查**、**`verification_strategy` 每个 `BEH-*` 有层级且无空缺**、**AC 八类逐类记录（含 `N/A` 理由）**（见 §7.3.2） | 任一 false → `BLOCK` | 产物类不可豁免；Open Review 可 Human waiver（记录 finding 与接受理由） |
| H03 | **Build Gate Hook** | 进入 `build`（精确：`execute`/`subagent-execute`）前 | Requirement/Design 批准、Test Design 存在、Build Plan 批准、Build Task、Scope、`verification_strategy`、`non_testable[]` | **全部检查项为真**（基础项新增：`verification_level`/`required_regression_level` 非空、Build Plan 强制引用齐备（分册 01 §12.6）、`non_testable[]` 审批齐备、Build Plan 已消费 `verification_strategy`；另含第 7 项"验证层级不得降级"、第 8 项"UT 全覆盖"，见 §7.3.3）；hotfix/tweak 用 §5.2 补偿字段替代 Design/Test Design 项 | 任一不满足 → `BLOCK` | Build Task/Scope 不可豁免；批准类须 Human 记录 |
| H04 | **Code Write Hook**（最重要） | `pre-code-write`（每次写入，非每任务） | stage、node、Build Task、`scope.files`、Design/Test Contract 批准、CodeGraph impact、目标文件、Agent 身份 | 7 级确定性链（见 §7.3.4） | `BLOCK` + 归因（Agent/Scope/契约/环境） | **默认不可豁免**；唯一合法路径是 Human 批准 Scope 扩展并更新 `scope.files` |
| H05 | **Scope Control** | 文件写入判定（H04 链内第 ④ 步 `File Allow-list`） | 实际修改文件集、批准 `scope.files` | `modified_files ⊆ approved_scope.files`；例 `scheduler.c → NOT IN APPROVED SCOPE` | 直接 `BLOCK` | 无 waiver；只能更新 `scope.files`（Human 批准） |
| H06 | CodeGraph Impact Check | 随 H04（写入时） | `Approved Scope` + `get_impact()` + `potential_files` | 目标文件 ∈ `scope.files` → 交由 H04 继续判定；超出 → Human Review（**不产生任何自动放行**） | `Human Review` / `BLOCK` | 无（Human Review 即合法出口）；**`derived_allow ≡ ∅`，`potential_files` 仅作 Human Review 材料**（§14 IR-7） |
| H07 | RED/GREEN Evidence Hook | 每次 Build Task 的 RED→GREEN | Test Plugin 结果、命令、退出码、stdout/stderr、`task_id` | 记录 `tdd.task_id / red / green / refactor`；UFS：RED 必须是**可观察的行为失配**（编译/链接失败不算 RED） | 无证据即"缺失"；`verify` 时由 H12 升为 `BLOCK` | Legacy 下可用 `Characterization Test` + `Baseline GREEN` 替代（须标注） |
| H08 | **Test Contract Protection Hook** | `pre-test-contract-change` | 测试文件/断言变更、diff、REQ/DES 变更记录、变更分类、变更理由与评审记录 | 改 Expected Behavior → BLOCK + Human Decision；**四项必要条件齐备（`refs` + Reason + Review + Human）**；**REFACTOR 中可读性改写（断言不变）→ 允许**；Mock/fixture/test utility → 允许（判定表见 §7.3.5） | `BLOCK` + 要求 Human Decision | 唯一路径：四项必要条件齐备且 Human 批准（J5） |
| H09 | TDD Hook | `pre-implementation` | Build Task、测试文件存在性、Characterization 记录、`non-testable` 标记 | Greenfield：Test exists？；Legacy：Characterization exists **OR** non-testable | 未满足不允许实现 | Legacy `non-testable` 必须由 `design` 节点写入并经 Human Gate 批准，无审批方即无效（§14 IR-9） |
| H10 | Regression Hook | Build Task 完成前 | 要求的 Regression Level、Test Plugin 回归结果 | `Required Level → Execute → Collect Result`；等级 `L0…L5`，**命名与语义见分册 01 §10.2** | 未通过不完成 | 无默认豁免；等级由 Build Task 显式写入，未写入即 `BLOCK`，不得由 Verification Level 推导（§14 IR-12） |
| H11 | Commit Hook | `pre-commit` | 暂存内容、REQ/DES/Test/Build Task Ref、Test/Regression Result、**`rulings.md`** | 引用齐备；提交只含当前 change 的文件；**`rulings.md` 中最近一次 `Design ≠ Existing Code` 裁决已记录**（`99 D67`）⇒ 缺裁决记录输出 `WARN`（非 `BLOCK`） | 缺引用 → `BLOCK`（使 Commit 成为 Traceability 载体）；缺裁决记录 → `WARN` | 无（先补引用再提交）；纯文档/配置提交可 `waiver`（记录理由） |
| H12 | **Verify Hook** | `pre-verify` | 任务完成态、测试执行与 RED 证据、回归结果、`comet.review.v1`、Evidence、Traceability、失败分类记录、引用记录 | All Build Tasks complete？required tests executed？Regression complete？Code Review complete？Evidence collected？Traceability complete？**每个 Task 的 `required_regression_level` 已执行**、**RED 证据存在且 `expected`/`actual` 非空**、**所有失败有四分类结论且已关闭**、**`level_review` 九条逐条 PASS**（`coverage` / `evidence_executable` / `evidence_inspection` / `evidence_manual` / `no_level_downgrade` / `regression_level_met` / `failures_classified` / `ac_full_coverage` / `tc_full_coverage`；键缺一即 `BLOCKED`）、**`level_review_outcome` 与九条汇总一致**（`NEEDS_REVISION` / `BLOCKED` 两档，见 §7.3.6）、**REQ/DES/Test/Build Task 引用齐备** | 不满足不进入 `verify` | 无；**缺 Code Review 不可豁免** |
| H13 | **Close Hook**（最严格） | `pre-close` | 覆盖度、验证结果、回归、Code Review、Evidence 完整性、Traceability 完整性、Blocking Issues、Human Acceptance、**review / verify 审计副本与其汇总索引**、**ID 形态记录** | Requirement/Acceptance Coverage **已统计并列出未覆盖项**（**不设百分比阈值**，`99 D24`；未覆盖项为 0 是期望结果而非门禁的百分比条件）；Required Verification=PASS；Regression=PASS；Code Review=PASS；Evidence=COMPLETE；Traceability=COMPLETE；**审计副本存在**（`comet-artifacts/evidence/<change>/{challenge,document-review,review,verify}/**`，**四职能各自独立、不合并**）且**归档汇总索引** `comet-artifacts/evidence/<change>/index.md` 的未关闭 BLOCKER 数=0、四职能全部入索引（99 D07 / D44）；**ID 形态断言通过**（前缀 ∈ 主文档 §5.1.1 五张子表、段数与所在表一致、无域标签、非对象编号未进主干，见 §7.3.7）；Blocking Issues=0；Human Acceptance=APPROVED | `BLOCK ARCHIVE` | **完全不可豁免**；唯一合法路径是完成条件或 Human 撤回归档请求 |

### 7.3.2 H02 Stage Gate Hook（MVP，详细）

| 项 | 内容 |
|---|---|
| 触发点 | `pre-stage(<PHASE>)`（进入某阶段之前） |
| 输入 | 该阶段的必需产物清单、Open Review 结果、Human Approval 记录、AC 文本、`design` artifacts、`verification_strategy` |
| 检查（基础项） | 以 `design` 为例：Requirement Exists？AC Exists？AT Exists？Open Review Passed？Human Approval？；UFS 追加：`test-design.md` 存在且 Verification Level 非空（对齐 §4.2 NG-3） |
| 检查（AC 禁例词） | **AC 文本关键词机械扫描**：命中禁例词（`正常` / `正确` / `合适` / `尽快` / `尽可能` 等）⇒ `BLOCK`（方法论出处：分册 01 §5.4） |
| 检查（函数名模式） | **`design` artifacts 函数名模式检查**：命中 `[A-Z][A-Za-z]+_[A-Za-z]+\(` 形态的早期函数绑定 ⇒ `BLOCK`（方法论出处：分册 01 §5.2「AC 八类」与 §12.4 的 `FR-4`／`ML-1`；函数名禁令的成文处为分册 01 §12.4 与 `SR-3`） |
| 检查（验证层级无空缺） | **`verification_strategy` 每个 `BEH-*` 至少一个层级且无空缺** ⇒ 任一 `BEH-*` 缺层级即 `BLOCK`（方法论出处：分册 01 §9.2 硬规则 / §25.3 §3） |
| 检查（AC 八类记录） | **AC 八类逐类检查记录齐备**（含 `N/A` 的逐类理由）⇒ 缺类或缺理由即 `BLOCK`（方法论出处：分册 01 §5.2 / §6.1） |
| 失败动作 | 任一检查项为 false → `BLOCK` |
| 豁免 | 阶段产物类不可豁免；仅有 Open Review 结果可被 Human 显式 waiver（须记录 finding 与接受理由） |

### 7.3.3 H03 Build Gate Hook（MVP，详细）

| 项 | 内容 |
|---|---|
| 触发点 | 进入 `build`（更精确：进入 `execute` / `subagent-execute`）之前 |
| 输入 | Requirement 批准、Design 批准、Test Design 存在、Build Plan 批准、Build Task 存在、Scope 已定义 |
| 检查（基础项） | 上述基础检查项全部为真；hotfix/tweak 下以 §5.2 的补偿字段替代 Design/Test Design 项 |
| 检查（层级/回归非空） | 每个 Build Task 的 `verification_level` 与 `required_regression_level` **非空** ⇒ 任一缺失即 `BLOCK`（方法论出处：分册 01 §12.5 / `MR-6`（补偿位置）与 `MR-8`（回归等级显式声明）；字段契约见分册 02 §9.6.3） |
| 检查（引用齐备） | Build Plan 的**强制引用齐备** ⇒ 缺任一即 `BLOCK`（方法论出处：分册 01 §12.6） |
| 检查（`non_testable` 审批齐备） | `non_testable[]` 每条含**五字段** `item_id` / `reason` / `alternative_verification_level` / `approver` / `decision_ref`（契约见分册 02 §8.6）⇒ 缺任一即 `BLOCK`；键不存在（而非空数组）同样 `BLOCK`（方法论出处：分册 01 §8.4 与 §16.4 / `MR-9`；字段契约见分册 02 §8.6；`99 D22`） |
| 检查（已消费 `verification_strategy`） | Build Plan **已消费 `verification_strategy`**：每个 `BEH-*` 出现在某个 Task 的 `verification_strategy_consumed` 中，或有显式 `deferred` ⇒ 否则 `BLOCK`（字段载体见分册 02 §9.6.3；方法论出处：分册 01 §9.4） |
| 检查（第 7 项，**计划期**） | **验证层级不得降级（计划期判定）**：逐一比较某 Build Task 经 `test_refs` 引用的每个 UT 在 `test-design.md` 中声明的**最高层级**，与该 Build Task 的 `verification_level`；若 Build Task 的值**低于**任一被引用 UT 的最高层级 → `BLOCK`，并要求 Human 裁决。当一个 Build Task 引用多个不同层级的 UT 时，比较基准取**被引用 UT 的最高层级**（方法论出处：分册 01 §12.8 / MR-10，99 D33） |
| 检查（第 8 项，**计划期**） | **TC 被引用（计划完整性）**：`test-design.md` 中**每一条 `TC-*` 至少被一个 Build Task 的 `test_refs` 引用**；存在未被任何 Task 引用的 `TC-*` ⇒ `BLOCK`，除非该 `TC-*` 已显式标记 `deferred` 并记录理由与批准。**与 H12 的分工**：本条判“**是否被计划引用**”（计划期）；`H12` 的 `level_review.tc_full_coverage` 判“**是否有已执行证据**”（证据期）。两条**输入不同、缺一不可**，不是同一条检查的两个判定点 |
| 与 H12 的分工 | **第 7 项是计划期判定**（Task 声明的 `verification_level` 对 `test_refs` 引用的各 `TC-*` 的 `level`）；**H12 的 `level_review.no_level_downgrade` 是证据期判定**（实际证据的层级对声明层级）。二者输入不同、结论互不替代，**不是同一条检查的两个判定点** |
| 失败动作 | 任一项不满足 → `BLOCK` |
| 豁免 | Build Task 与 Scope 不可豁免；Requirement / Design 批准类豁免须 Human 显式记录 |

### 7.3.4 H04 Code Write Hook（最重要）

| 项 | 内容 |
|---|---|
| 触发点 | `pre-code-write`（**每一次**源码/测试代码写入，而非每次任务） |
| 输入 | 当前 stage、当前 node（投影）、当前 Build Task、`scope.files`、Design 批准记录、Test Contract 批准记录、CodeGraph impact 结果、目标文件路径、Agent 身份 |
| 检查 | 见下方链条，共 7 级确定性判定 |
| 失败动作 | `BLOCK` + 归因（Agent / Scope / 契约 / 环境四类之一） |
| 豁免 | **默认不可豁免**；超范围写入的唯一合法路径是 Human 批准 Scope 扩展并更新 `scope.files`（不是 waiver，是契约变更） |

**完整链条（本册最重要的实现契约）**：

```text
code-write → Build Task → Scope → CodeGraph → Hook → Allow / Block
```

展开为可编码的判定序列：

```text
Coding Agent → Write Request(target_file)
 ① Stage Check   : phase == build ?            else BLOCK
 ② Node Check    : node ∈ {execute, subagent-execute} ?   else BLOCK  ← UFS 新增
 ③ Task Check    : task_id 存在 ∧ 已批准 ∧ 未完成 ?     else BLOCK
 ④ File Allow-list : target_file ∈ scope.files ?       （精确/前缀/glob）
 ⑤ Contract Check  : Design Approved ∧ Test Contract Approved ? else BLOCK
 ⑥ CodeGraph Impact : target_file ∈ scope.files ?        （derived_allow ≡ ∅，仅用于影响面提示）
            ├─ 是 → 继续
            └─ 否 → 需要 Explicit Expansion（Human 批准） else BLOCK/Human Review
 ⑦ Decision     : ALLOW / BLOCK，并写入 enforcement 证据
```

**归因规则**：②③④⑤ 失败归因 Agent（越权/越范围）；⑥ 需扩展归因 Human（Scope 决策）；工具不可用导致无法判定归因 Environment（但**仍为 BLOCK**，见 §7.4）。

### 7.3.5 H08 Test Contract Protection Hook（MVP，详细）

| 项 | 内容 |
|---|---|
| 触发点 | `pre-test-contract-change` |
| 输入 | 变更的测试文件/断言、变更内容 diff、Requirement / Design 变更记录、变更分类（Expected Behavior vs Mock/fixture/test utility）、**变更理由（Reason）**、**评审记录（Review）** |
| 检查（基础项） | 检测 Acceptance Criteria / Acceptance Test / Expected Behavior / Behavioral Test 是否被修改；改 Expected Behavior → BLOCK 并要 Human Decision；仅 Mock / fixture / test utility → 允许 |
| 检查（四项必要条件） | **四项必要条件齐备**：`refs ⊇ {REQ\|DES\|DEC}` + **Reason**（变更理由）+ **Review**（评审记录）+ Human 批准；缺任一 ⇒ `BLOCK`（方法论出处：分册 01 §18.2） |
| 失败动作 | `BLOCK` + 要求 Human Decision |
| 豁免 | 唯一合法路径：四项必要条件齐备且 Human 批准（对应 J5） |

**判定表**：

| 变更对象 | 判定 | 依据 |
|---|---|---|
| `expected` / `then` 断言 | BLOCK（除非有需求/设计依据 + Human 批准） | J5 |
| Acceptance Criteria / AT | BLOCK（属于契约，不是测试） | 主文档 §9.4 |
| Mock / stub / fake / spy 策略 | Allow（记录） | 测试实现自由度 |
| **REFACTOR 中可读性改写（断言不变）** | **Allow（记录）** | 断言语义未变，不构成 Test Contract 变更（分册 01 §18.5） |
| fixture / 测试工具函数 | Allow（记录） | 同上 |
| 新增测试用例（不改既有断言） | Allow（须关联 AC 或显式标注来源类型） | 主文档 §5.4 |
| 删除测试用例 | BLOCK（除非 Human 批准并记录理由） | 契约保护 |

### 7.3.6 H12 Verify Hook（MVP，详细）

| 项 | 内容 |
|---|---|
| 触发点 | `pre-verify`（进入 `verify` 之前） |
| 输入 | 任务完成态、测试执行与 RED 证据、回归结果、`comet.review.v1`、Evidence 索引、Traceability 索引、失败分类记录、引用记录 |
| 检查（基础项） | All Build Tasks complete？required tests executed？Regression complete？Code Review complete？Evidence collected？Traceability complete？ |
| 检查（回归等级已执行） | **每个 Build Task 的 `required_regression_level` 已执行**（结果存在且 PASS）⇒ 任一未执行即 `BLOCK`（方法论出处：分册 01 §10.2 / `MR-8`） |
| 检查（RED 证据） | **RED 证据存在且 `expected` / `actual` 非空** ⇒ 缺失或为空即 `BLOCK`（方法论出处：分册 01 §13.4 / §13.5） |
| 检查（失败分类闭环） | **所有失败有四分类结论且已关闭**（`TEST_PROBLEM` / `CODE_PROBLEM` / `DESIGN_PROBLEM` / `ENVIRONMENT_PROBLEM`；关闭裁判按分册 01 §19.2）⇒ 存在未分类或未关闭失败即 `BLOCK` |
| 判定输入（唯一权威） | `comet.verify.v1.level_review` 的**九条核对项**（分册 02 §12.6 Schema、§12.9.6 映射表）；语义权威为**分册 01 §26.1**。本 Hook **不得**在自己一侧另立核对项清单 |
| 检查（`level_review` 九条） | 逐条读 `level_review.<key>`：`coverage` / `evidence_executable` / `evidence_inspection` / `evidence_manual` / `no_level_downgrade` / `regression_level_met` / `failures_classified` / `ac_full_coverage` / `tc_full_coverage`。**键缺一即 `BLOCKED`**（结构不可判定，与"检查不通过"分属两档） |
| 检查（档位一致性） | `level_review_outcome` 必须等于九条的汇总档位（`BLOCKED` ⊃ `NEEDS_REVISION` ⊃ `NONE`，映射表见分册 02 §12.9.6）；**不等于即 `BLOCK`**（说明结论被手工放行） |
| 检查（两项 `BLOCKED` 档） | `no_level_downgrade` = `FAIL` 或 `ac_full_coverage` = `FAIL` ⇒ 直接 `BLOCK`；其余七条 `FAIL` ⇒ `BLOCK` 并要求按 `NEEDS_REVISION` 回流（两侧动作相同，档位用于 `verify` 结论与路由区分） |
| 检查（引用齐备） | **REQ / DES / Test / Build Task 引用齐备**（该检查落在 H12，不由非 MVP 的 H11 承担）⇒ 缺任一即 `BLOCK`（方法论出处：分册 01 §27.3 V1/V2） |
| 失败动作 | 任一不满足 → 不进入 `verify`（`BLOCK`） |
| 豁免 | 无；**缺 Code Review 不可豁免** |

### 7.3.7 H13 Close Hook（MVP，详细）

| 项 | 内容 |
|---|---|
| 触发点 | `pre-close`（归档前最终确认） |
| 输入 | 覆盖度、验证结果、回归、Code Review、Evidence 完整性、Traceability 完整性、Blocking Issues、Human Acceptance、review / verify 审计副本与索引、ID 形态记录 |
| 检查（基础项） | Requirement/Acceptance Coverage **已统计并列出未覆盖项**（**不设百分比阈值**，`99 D24`；未覆盖项为 0 是期望结果而非门禁的百分比条件）；Required Verification=PASS；Regression=PASS；Code Review=PASS；Evidence=COMPLETE；Traceability=COMPLETE；审计副本存在（四职能子树齐备）且归档汇总索引 `comet-artifacts/evidence/<change>/index.md` 的未关闭 BLOCKER 数=0、四职能全部入索引（`99 D44`）；Blocking Issues=0；Human Acceptance=APPROVED |
| 检查（ID 形态断言） | **ID 形态断言通过**：前缀 ∈ 主文档 §5.1.1 的五张命名空间子表，且段数与该表一致（表 N1 单段、表 N2 两段）；ID 内无域标签；主线引用未使用表 N4/N5 的编号；表 N3 的历史别名形态只允许出现在历史产物只读路径 ⇒ 任一违规即 `BLOCK ARCHIVE` |
| 判定输入（唯一权威） | 主文档 **§5.1.1 命名空间总表**（表 N1 合法单段集 / 表 N2 合法两段集 / 表 N3 历史别名集 / 表 N4 规则与事项命名空间集 / 表 N5 局部命名空间排除集），以及该节末尾内联的四条判定规则。**本 Hook 不得在自己一侧另立前缀白名单**；主文档增删前缀时本 Hook 自动跟随 |
| 方法论出处 | 分册 01 §22.5（ID 约定镜像） |
| 失败动作 | `BLOCK ARCHIVE` |
| 豁免 | **完全不可豁免**；唯一合法路径是完成条件或 Human 撤回归档请求 |

### 7.3.8 Verification Level × Regression Level（引用，不自算）

**拼写冻结**（主文档 §5.1.3）：Verification Level 一律 `UNIT / COMPONENT / INTEGRATION / SIMULATOR / HARDWARE / INSPECTION / MANUAL`；**不得写作 `UT`**（`UT` 只是"单元测试"这一 Test Case 类型的简称）。Regression Level 一律 `L0 … L5`。

**映射归属**：两者的正交映射表**由分册 01 §10.3 唯一持有**；本册**只引用，不自算数值**。实现层按行读取：

| 本册实现位 | 引用 |
|---|---|
| Regression Hook（H10）的最小证据下限 | 分册 01 §10.3 **逐行**取值 |
| `UNIT` / `COMPONENT` / `INTEGRATION` / `SIMULATOR` / `HARDWARE` / `MANUAL` | 同上（各一行） |
| `INSPECTION` | 分册 01 §10.3；判定基线见 §14 IR-8 |

**两条硬规则**：

1. **该映射不是默认选取策略。** Regression Level **必须由 Build Task 显式写入**（`verification:` / 回归字段）；Build Plan 未写即视为缺失，不得由 Verification Level 自动推导出"默认等级"（§14 IR-12）。
2. 当 Verification Level 为 `INSPECTION` 时，Regression Hook **必须**要求 Human 显式指定等级，不得默认放行。

## 7.4 强制语义（fail-closed / 归属 / allow-list / 无推理）

### 7.4.1 Fail-closed

不满足条件时执行 `BLOCK`，**而不是**提醒 Agent"请注意……"。实现层加固：

| 情形 | 结果 |
|---|---|
| 检查为 false | `BLOCK` |
| 检查无法执行（输入缺失、工具不可用、超时） | `BLOCK`（不得默认放行） |
| Hook 自身抛异常/崩溃 | `BLOCK`（fail-closed；记录 hook id + stack） |
| 检查为 true 且有豁免记录 | `ALLOW` + 记录 waiver |
| Hook 未部署（MVP 外的 Hook） | ⚠️ 该 Hook 覆盖的风险**无强制**，必须在 `verify` 中以显式 gap 记录（见 §14） |

**禁止的"软强制"**：`Test GREEN 不是最终正确性的充分条件`；不得出现"建议不要修改 Expected"这类提示式 Hook。

### 7.4.2 归属（ownership attribution）

```text
Agent = Reasoning
Hook = Deterministic Enforcement
```

| 事件 | 归属 | 去向 |
|---|---|---|
| `ALLOW` | 执行动作的 Agent | Tool / Plugin 执行 |
| `BLOCK`（Agent 越权/越范围/伪造证据） | Agent | 修订（Revision），必要时 Human |
| `BLOCK`（Scope/契约/验收决策缺失） | Human | Human 决策点（阻塞） |
| `BLOCK`（工具链/环境不可用） | Environment | Infrastructure 处理；**不得改业务代码绕过** |
| `BLOCK`（Hook 缺陷） | Platform | 修 Hook；期间保持 fail-closed |

每次 `BLOCK` 必须记录：`hook_id / change_id / phase / node / agent / input_ref / failed_check / attribution / timestamp / waiver_ref`。

### 7.4.3 Allow-list 边界

| 匹配形式 | 语义 | 示例 |
|---|---|---|
| 精确路径 | 完全相等 | `src/host/flow_control.c` |
| 目录前缀 | 前缀匹配（`/**`） | `test/host/**` |
| glob | 标准 glob | `src/host/*_flow.c` |
| 影响面提示 `potential_files` | 由 CodeGraph impact 推导；**只作 Human Review 材料，不构成放行集**。`derived_allow` **恒为空集**，任何“影响范围内即放行”的通道都已撤回（`99 D72`） | `potential_files` |
| 其他 | **默认拒绝** | — |

**边界规则**：① allow-list 比较在**规范化相对仓库根路径**上进行（对齐 `classic-layout.md` 的相对仓库根引用要求）；② 符号链接、`..`、跨 change 路径一律视为越界；③ allow-list 只能由 `plan` 节点产出、经 Human 批准后生效；写入过程中修改 allow-list 视为 Scope 变更（决策点）。

### 7.4.4 Hook 不得做复杂推理

Hook 只做**确定性规则检查**：`Artifact exists? Approval exists? Reference valid? File allowed? Test executed? Result PASS?`；复杂判断交给 Agent。

| 允许 | 禁止 |
|---|---|
| 存在性、相等、集合包含、glob 匹配、正则结构校验 | LLM 调用、语义理解、"这段代码是否合理" |
| 读取状态文件与索引 | 需要跨多次推理才能判定的结论 |
| JSON Schema / YAML 字段校验 | 主观质量评分 |
| 命令退出码与 stdout 关键字段判定 | 自行决定"证据是否足够充分" |

**可度量边界**：单个 Hook 执行必须满足 `只读`、`无网络`、`有限时间（超时即 BLOCK）`、`不做写操作（除记录 enforcement 证据）`。

## 7.5 Agent + Hook 边界与"AI Coding Firewall"实例

```text
         Agent
          │
         Reasoning
          │
          ↓
         Action
          │
          ↓
         Hook
          │
       ┌──────┴──────┐
       ↓       ↓
      ALLOW     BLOCK
       │       │
       ↓       ↓
      Tool     Human/Revision
```

这比单纯 Prompt 可靠得多。

**AI Coding Firewall 完整实例**：

```text
需求：Host Write Flow Control
Build Task: task_id: IMP-001-02
      files: [src/host/flow_control.c]
      tests: [TC-001-01, TC-001-02]

Coding Agent 请求修改 src/host/flow_control.c
Hook 判定：BUILD? YES | Task? IMP-001-02 | File? ALLOWED | Design? APPROVED
      Test Design? EXISTS | Scope? VALID | CodeGraph? IMPACT REVIEWED
结果：ALLOW
随后：Test → RED → Code → GREEN → Regression → Evidence

若又修改 src/nand/nand_driver.c：
 Scope Check → Not Approved → CodeGraph Impact → No approved reason → BLOCK
```

**UFS 化增补**：在被 BLOCK 的第二种情形中，正确的输出不是"请确认"，而是：

```yaml
enforcement_block:
 hook_id: H04
 change_id: host-write-flow-control
 phase: build
 node: execute
 agent: ufs-coding
 target_file: src/nand/nand_driver.c
 failed_check: file_not_in_scope
 scope_ref: IMP-001-02
 attribution: agent
 next_action: revision_or_human_scope_approval
```

**结论**：这就是真正需要的 **AI Coding Firewall**。

## 7.6 方法论强制承诺 → Hook 落地对照表

分册 01 中**声称强制**的 23 条承诺，逐条给出承接方。原则：**不允许既声称强制又无 Hook**。

| 条 | 01 位置 | 强制方式 | 落地 | 状态 |
|---|---|---|---|---|
| B1 | §5.4 AC 模糊措辞禁例 | AC 文本禁例词机械扫描 | **H02**（AC 禁例词） | 已落地 |
| B2 | §5.5 反向判据 | 需要工程判断，无法机械判定 | **人工**（`ufs-document-review`） | 已降级人工 |
| B3 | §6.1 / `FR-4` / `ML-1` | `design` artifacts 函数名模式检查 | **H02**（函数名模式） | 已落地 |
| B4 | §9.2 硬规则 / §25.3 §3 | `verification_strategy` 每个 `BEH-*` 有层级且无空缺 | **H02**（验证层级无空缺） | 已落地 |
| B5 | §12.5 / `MR-6`、`MR-8` | `verification_level` 与 `required_regression_level` 非空 | **H03** 基础项（层级/回归非空） | 已落地 |
| B6 | §12.6 强制引用齐备 | Build Plan 强制引用齐备（分册 01 §12.6） | **H03** 基础项（引用齐备） | 已落地 |
| B7 | §12.8 层级降级 | Build Task 层级不低于被引用 UT 最高层级 | **H03** 第 7 项 | 已修 |
| B8 | §10.2 / `MR-8` | 每个 Build Task 的 `required_regression_level` 已执行 | **H12**（回归等级已执行） | 已落地 |
| B9 | §13.4 / §13.5 | RED 证据存在且 `expected`/`actual` 非空 | **H12**（RED 证据） | 已落地 |
| B10 | §16.4 / `MR-9` | `non_testable[]` 含 `approver` + `decision_ref` | **H03** 基础项（`non_testable` 审批齐备） | 已落地 |
| B11 | §18.2 四项必要条件 | `refs` + Reason + Review + Human 齐备 | **H08**（四项必要条件） | 已落地 |
| B12 | §18.5 | REFACTOR 可读性改写的判定行 | **H08**（判定表新增行） | 已落地 |
| B13 | §19 四分类 | 所有失败有四分类结论且已关闭 | **H12**（失败分类闭环） | 已落地 |
| B14 | §20.6 TDATA-1..8 | 数据规范内容完备性无法机械判定 | **人工**（`ufs-document-review`） | 已降级人工 |
| B15 | §22.5 / §22.6 | ID 形态断言（前缀 ∈ 主文档 §5.1.1 五张子表 / 段数一致 / 无域标签 / 非对象编号未进主干） | **H13**（ID 形态断言） | 已落地 |
| B16 | §25.3 16 节内容完备性 | 存在性可机器检查；内容完备性需人工 | **H02**（存在性）+ **人工**（内容完备性） | 已覆盖存在性 / 内容人工 |
| B17 | §26.1 verify 判据 | 层级覆盖 / 证据可信 / 层级不得降级 | **H12**（verify 判据补全） | 已落地 |
| B18 | §27.3 V1/V2 | 引用齐备检查（原误标 H11，H11 非 MVP） | **H12**（引用齐备） | 已落地 |
| B19 | §27.3 V3 | Test Contract 保护 | **H08** | 已覆盖 |
| B20 | §27.3 V4 | ID / 归档形态 | **H13** | 已覆盖 |
| B21 | `FR-1..5` | 规则层声明，不逐条绑定 Hook；可机器检查部分分别落地 | **H02/H03/H08/H12/H13** 分项 | 规则层 / 已分流 |
| B22 | §9.4 | Build Plan 已消费 `verification_strategy` | **H03** 基础项（已消费 `verification_strategy`） | 已落地 |
| B23 | §5.2 / §6.1 | AC 八类逐类检查记录（含 `N/A` 理由） | **H02**（AC 八类记录） | 已落地 |

**结论**：23 条全部有承接——16 条落到 MVP Hook（H02/H03/H08/H12/H13），4 条明确降级为人工（B2/B14/B16 内容完备性/B21），2 条已由既有 Hook 覆盖（B19 → H08、B20 → H13），1 条此前已修（B7 → H03 第 7 项）。**没有任何一条既声称强制又无承接。**

---

# 8. 权限模型

权限模型的**范本**是 `prd-split` 已经实现的正确形态：**默认全拒 + 单写路径白名单**。

```yaml
permissions:
 - {action: "*",  resource: "*",               effect: deny}
 - {action: read, resource: "*",               effect: allow}
 - {action: glob, resource: "*",               effect: allow}
 - {action: grep, resource: "*",               effect: allow}
 - {action: edit, resource: "comet-artifacts/requirements/**", effect: allow}
 - {action: skill, resource: "prd-split",           effect: allow}
```

**实现层要点**：所有 Agent 定义文件必须**以 `deny *` 开头**；没有 `deny` 起手的能力清单等于无权限模型。本册的 13 个 Agent 一律沿用该模式。

## 8.1 13 行权限矩阵（复现主文档 §6.5）

> **写路径的粒度权威是 §8.4（Agent × 具体 glob 表）**，本节的主文档复现只给“写路径形态”。两处不一致时**以 §8.4 为准**——尤其 `ufs-code-review` / `ufs-verification` 的写目标是**审计副本 glob**，不是 `comet.review.v1` / `comet.verify.v1`（后两者是 **evidence 记录，不是文件**，由 Runtime 推导，任何 Agent 都不写）。

| Agent | 读 | **写（唯一允许路径，形态）** | 执行 | Skill |
|---|---|---|---|---|
| `ufs-requirements` | 全仓 | `comet-artifacts/requirements/**` | — | `prd-split` |
| `ufs-challenge` | 全仓 | `comet-artifacts/challenge/**` | — | `ufs-challenge` |
| `ufs-main` | 全仓 | `<openSpecRoot>/changes/<change>/.comet.yaml`（经 CLI）、`<archiveRoot>/**`、`comet-artifacts/evidence/<change>/index.md`（汇总） | Comet CLI | 全部 |
| `ufs-exploration` | 全仓 | `<superpowersRoot>/reports/exploration-report.md` | CodeGraph / graphify / OpenViking 查询 | — |
| `ufs-design` | 全仓 | `<superpowersRoot>/specs/*.md`（Canonical Design Doc） | — | — |
| `ufs-test-design` | 全仓 | `<superpowersRoot>/specs/test-design.md` | — | `ufs-test-design` |
| `ufs-build-plan` | 全仓 | `<superpowersRoot>/plans/build-plan.md`（+ `plans/*.md` 派生）、`<openSpecRoot>/changes/<change>/tasks.md` | CodeGraph | `ufs-writing-plans` |
| **`ufs-coding`** | 限当前 Build Task 范围 | **源码 + 测试代码** | Test / Build | `ufs-tdd` |
| `ufs-code-review` | 全仓 | `comet-artifacts/evidence/<change>/review/**`（审计副本；**不写** `comet.review.v1`） | — | `ufs-code-review` |
| `ufs-verification` | 全仓 | `comet-artifacts/evidence/<change>/verify/**`（审计副本；**不写** `comet.verify.v1`） | Test（Git 只读） | `ufs-verification` |
| `ufs-document-review` | 全仓 | findings | — | — |
| `ufs-firmware-expert` | 全仓 | 分析结论 | 知识查询 | — |
| `ufs-failure-analysis` | 失败上下文 | 分类结论 | — | — |

**矩阵的机器化要求**：每一行的"写"列必须能翻译为一条 `edit` allow 规则；"执行"列必须能翻译为 `bash`/`tool` allow 规则；"Skill"列必须翻译为 `skill` allow 规则。无法翻译的行视为未落地的权限声明。

## 8.2 三重已生效保护 + 一项提案（深化）

> **唯一权威 = 主文档 §6.5**（成员表与状态）。本节只给实现载体与可绕过性分析；**不得**把 P4 的提案计入“防线”。

```text
Prompt Rule + Tool Permission + OpenCode Hook + Comet State
```

```text
Can Write Code?
   ├── Prompt       → YES  （Agent 定义里的角色描述）
   ├── Agent Permission  → YES  （写路径白名单）
   ├── Current Stage == build     → ?  （Comet State）
   ├── Current Node ∈ {execute, subagent-execute} → ?  （Node Projection）
   ├── Approved Task   → ?  （tasks.md 权威）
   ├── Target File Allowed→ ?  （scope.files）
   └── Hook        → ALLOW / BLOCK  （H04）
```

**三重已生效保护 + 一项提案，逐层实现**：

| 层 | 保护 | 实现载体 | 可绕过性 |
|---|---|---|---|
| P1 | **写入路径白名单** | Agent 定义 `permissions` | 不可绕过（OpenCode 层拒绝） |
| P2 | **任务范围绑定** | `ufs-coding` 读范围限当前 Build Task；`scope.files` 限写范围 | 不可绕过（Hook 强制） |
| P3 | **Hook 放行** | H04 Code Write Hook（每次写入） | **不可绕过**（默认无豁免） |
| P4（提案） | **执行上下文绑定（Capability Token 形态）** | 一次 Build Task 的执行上下文（阶段 + 节点 + 任务 + 写路径）由 Comet Plugin 发放 | **不引入**为独立强制层；P1–P3 已覆盖同等语义（§8.5） |

**P1 与 P3 的关系**：P1 是**静态**白名单（Agent 一辈子只能写哪些路径形态），P3 是**动态**白名单（这一次任务只能写哪些具体文件）。二者必须同时成立；P1 通过不代表 P3 通过。

## 8.3 `ufs-coding` 的特殊限制

```text
READ : CodeGraph / OpenViking / Design / Test Design / Build Plan / 当前 Build Task 范围
WRITE : Source / Test / Build Artifacts
```

**不能写**（除非通过 Human Gate）：

```text
WRITE Requirement
WRITE Acceptance Criteria
WRITE Approved Design
WRITE Test Contract
```

**完整禁写清单**：

| 目标 | 是否可写 | 闸门 |
|---|---|---|
| `comet-artifacts/requirements/**` | ❌ | P1 直接拒绝 |
| `comet-artifacts/challenge/**` | ❌ | P1 直接拒绝 |
| `design.md` / Design Doc | ❌ | P1 直接拒绝 |
| `test-design.md` | ❌ | P1 直接拒绝 |
| `plans/*.md`、`tasks.md` 结构 | ❌（只允许勾选完成状态，经 Comet CLI） | P1 + Comet Plugin |
| `.comet.yaml` | ❌ | P1 直接拒绝 |
| 其他 change 的任何文件 | ❌ | P1 + H05 |
| `scope.files` 之外的源码 | ❌ | H04 ④⑥ |
| **测试断言语义** | ⚠️ 仅在有 REQ/DES 依据 + Human 批准时 | H08 |

**测试代码的写权限细化**：`ufs-coding` 可以新增/扩展测试代码（RED 需要），但不得修改既有断言的 Expected 语义。两类动作在 Hook 层可区分：新增文件 / 新增用例 → Allow；修改既有 `then`/`expected` 行 → H08 判定。

## 8.4 写路径白名单表（Agent × 具体 glob）

下表是 P1 的**可直接编码形式**。逻辑根与产物位置一律**引用主文档 §8.2/§8.3**，本表不另立权威。

| Agent | allow `edit` glob | 说明 | Hook 闸门 |
|---|---|---|---|
| `ufs-requirements` | `comet-artifacts/requirements/**` | Stage 0 需求基线（主文档 §8.3） | —（Stage 0 之外） |
| `ufs-challenge` | `comet-artifacts/challenge/**` | Stage 0-b 挑战报告（主文档 §8.3） | — |
| `ufs-main` | `changes/*/.comet.yaml`（经 Comet CLI） | 状态初始化/迁移 | H02/H12/H13 |
| `ufs-main` | `<archiveRoot>/**` | 归档产物 | H13 |
| `ufs-exploration` | `<superpowersRoot>/reports/*` | 探索报告（§14 IR-10） | H02（design 产物门禁） |
| `ufs-design` | `<superpowersRoot>/specs/*.md` | `design-doc`（`pathBase: classic-superpowers-root`） | H02 |
| `ufs-test-design` | `<superpowersRoot>/specs/*test-design*` | 验证契约（§14 IR-10） | H02 |
| `ufs-build-plan` | `<superpowersRoot>/plans/*.md`、`<openSpecRoot>/changes/*/tasks.md` | `implementation-plan` + `openspec-tasks` | H03 |
| `ufs-coding` | `scope.files`（运行期集合） | 源码 + 测试代码 | **H04 + H05 + H08** |
| `ufs-code-review` | `comet-artifacts/evidence/*/review/**` | review 审计副本（Comet 原生 `comet.review.v1` 无产物文件） | H12 |
| `ufs-verification` | `comet-artifacts/evidence/*/verify/**` | verify 审计副本（Comet 原生 `comet.verify.v1` 无产物文件） | H13 |
| `ufs-document-review` | `.comet/artifacts/*/findings/*.md`（**本设计路径**） | findings | H02 |
| `ufs-firmware-expert` | `.comet/artifacts/*/analysis/*.md`（**本设计路径**） | 分析结论 | — |
| `ufs-challenge` | `comet-artifacts/evidence/<change>/challenge/**` | 归档用 challenge 审计副本（四职能之一；与 `comet-artifacts/challenge/**` 同一份内容，归档期复制） | H13 |
| `ufs-document-review` | `comet-artifacts/evidence/<change>/document-review/**` | 归档用 document-review 审计副本（四职能之一） | H13 |
| `ufs-failure-analysis` | `.comet/artifacts/*/failures/*.md`（**本设计路径**） | 分类结论 | — |

**实现层注记**：

1. `design-doc` → `<superpowersRoot>/specs/*.md`、`implementation-plan` → `<superpowersRoot>/plans/*.md` 是 **Comet 原生 `pathBase`**，不是本设计的选择（主文档 §8.2）。
2. `exploration-report.md`、`test-design.md`、`.comet/artifacts/**`、以及 review/verify 的**审计副本**在 Comet schema 中均无槽位；`<superpowersRoot>/reports/` 与 `<superpowersRoot>/specs/` 是按主文档 §8.3 确定的位置（§14 IR-10），审计副本按 99 D07 落 `comet-artifacts/evidence/<change>/{review,verify}/**`。在 Output Schema 扩展完成前，这些产物由 Stage Gate / 审计钩子以路径存在性检查承接，不走 `artifact-structured`。
3. **审计副本是两层语义的第二层**：`ufs-code-review` / `ufs-verification` 各自只写自己的审计副本目录（`comet-artifacts/evidence/<change>/review/**`、`.../verify/**`），**不能**创建 `review.json` / `verify.json` 这类"Comet 产物"；第一层（`comet.review.v1` / `comet.verify.v1` 的 Runtime evidence 记录）保持不变（99 D07）。

## 8.5 执行上下文绑定（不采用 Capability Token）

权限实现**不引入 Capability Token 作为独立强制层**：P1 写路径白名单 + P2 任务范围绑定 + P3 Hook 放行已覆盖同等语义。作为替代，Comet Plugin 在节点进入 `execute` 时发放一个**执行上下文**，绑定本次 Build Task 的阶段、节点、任务与写路径，H04 的 ③④⑤ 级直接校验该上下文：

```yaml
execution_context:
  project: ufs_fw
  change_id: host-write-flow-control
  stage: build
  node: execute
  task_id: IMP-001-02
  permissions: {code_read: true, code_write: true, test_execute: true, git_write: false}
  scope:
    files:
      - src/host/flow_control.c
      - test/host/test_flow_control.c
  contracts:
    requirement_refs: [REQ-001]
    design_refs: [DES-001-02]
    test_refs: [TC-001-01, TC-001-02]
```

**决定**：执行上下文的生命周期为**一个 Build Task**（任务完成即失效）；它不具备独立授权能力，任何授权判断最终仍由 P1 白名单与 H04 的确定性判定给出。因此它不构成第四道独立防线，而是 P2/P3 的数据载体。

---

# 9. 产物与追溯实现

本章只写**实现层**内容（逻辑根如何使用、每个节点写什么文件、单写者如何强制）。产物权威归属表见主文档 §8.2，**不在此重述**。

## 9.1 逻辑根模型（引用主文档 §2.5 / §8.2，不另立表）

**路径必须使用逻辑根，不得写死目录。** 只接受 `schema: comet.classic-layout.v1`。

逻辑根定义与**每个产物的 `pathBase` 权威表**均由主文档持有，本册**只引用、不另立一张**：

| 本册需要的事实 | 唯一出处 |
|---|---|
| 五个逻辑根的含义与默认物理位置 | **主文档 §2.5** |
| 每个 schema 产物的 `paths` 与 `pathBase` | **主文档 §8.2**（权威表） |
| Canonical Design Doc 与 OpenSpec `design.md` 的区别 | **主文档 §8.4** |
| 本设计新增产物（无 schema 槽位）的位置 | **主文档 §8.3**；本册裁定见 §14 IR-10 |

**两条必须记住的实现层事实**（直接决定写路径白名单，见 §8.4）：

1. `design-doc`（`specs/*.md`）与 `implementation-plan`（`plans/*.md`）的 `pathBase` 是 **`classic-superpowers-root`**，落 `<superpowersRoot>`；**不是** `<openSpecRoot>`。
2. **`superpowersRoot` 恒为 `docs/superpowers/`**，**不随 `classic.artifact_layout` 变化**；只有 `openSpecRoot` 在 `docs/openspec/`（docs）与 `openspec/`（legacy）之间切换。

**本仓库当前状态**：本仓库 `classic.artifact_layout: docs`，但 `docs/openspec/` 已不存在、产物在根 `openspec/`，构成 legacy/docs 冲突态，阻塞 Phase 1 落地。本册一律使用逻辑根，故设计本身不受影响；落地前必须先 `comet doctor` → `comet classic root move docs --apply`（或把配置改回 `legacy`，见 §14.2 `EXT-01`）。

**Native 工作流**另有 `native-root` pathBase（`changes/*/brief.md`、`verification.md`、`archive/*`）。本设计**只特化 five-phase Classic**；Native 不在本册范围。

**实现层规则**：

1. 进入阶段时用本轮 `comet state check <change> <phase> --json` 返回的 layout，不单独查询。
2. `data.artifactRefs` 提供相对仓库根路径（`change`、`tasks`、`designDoc`、`plan`、`plansRoot`、`handoffContext`）。
3. 状态字段与计划中的 `comet-task-authority` **必须使用相对仓库根路径**，不传绝对路径。
4. 绝对路径只用于文件读写；自定义路径必须以项目根为基准，不含 `..`、跨项目链接或指向另一 change 的任务清单。
5. 两套根冲突/配置无效/迁移未完成 → 停止写入，运行只读 `comet doctor`；不得扫描两处后猜测（当前仓库正处于该状态，按 §14.2 `EXT-01` 处理）。

## 9.2 节点 × 写入文件（按节点归口）

| 节点 | 写入 | `pathBase` / 路径（权威表见主文档 §8.2） | 权威属性 | 写入者（唯一） |
|---|---|---|---|---|
| `open` | `proposal.md`、`specs/**/spec.md`、`.comet.yaml` | `classic-openspec-root`：`changes/*/…` | 镜像 / Comet Runtime | `ufs-main` |
| `design` (Step 0) | `exploration-report.md` | **无 schema 槽位**；`<superpowersRoot>/reports/`（§14 IR-10） | 过程事实 | `ufs-exploration` |
| `design` (Step 1) | `design-doc` | **`classic-superpowers-root`**：`specs/*.md` | **技术决策权威** | `ufs-design` |
| `design` (Step 2) | `test-design.md` | **无 schema 槽位**；`<superpowersRoot>/specs/`（§14 IR-10） | **验证契约权威** | `ufs-test-design` |
| `design` | `delta-spec` | `classic-openspec-root`：`changes/*/specs/*/spec.md` | 镜像（权威在需求基线） | `ufs-design` |
| `plan` | `implementation-plan` | **`classic-superpowers-root`**：`plans/*.md` | **实施契约** | `ufs-build-plan` |
| `plan` | `openspec-tasks`（`tasks.md`） | `classic-openspec-root`：`changes/*/tasks.md` | **任务状态唯一权威**（内容） | `ufs-build-plan` |
| `execute` | 源码 + 测试代码 | 仓库（`scope.files` 限定） | **实现权威** | `ufs-coding` |
| `execute` | `task-state`（`tasks.md` 勾选） | `classic-openspec-root`：`changes/*/tasks.md` | **内容由 `ufs-build-plan` 写；完成勾选经 Comet CLI，授权主体是 `ufs-main`**，不构成本产物写入者变更 | `ufs-build-plan`（内容） / `ufs-main`（勾选授权） |
| `subagent-execute` | handoff 包、`rulings.md`、checkpoint | `<changesRoot>/<change>/.comet/handoff/`、`.comet/rulings.md` | 协作记录 | 主会话 / implementer |
| `review` | `comet.review.v1` = evidence 记录（无产物文件）；**审计副本** `comet-artifacts/evidence/<change>/review/**` | 第一层由 Runtime `collectClassicEvidence()` 推导；第二层为审计副本 | review evidence + 审计副本 | `ufs-code-review` |
| `verify` | `comet.verify.v1` = evidence 记录（无产物文件）；**审计副本** `comet-artifacts/evidence/<change>/verify/**` | 同上 | verify evidence + 审计副本 | `ufs-verification` |
| `archive` | 归档目录、`archive-summary` | `classic-openspec-root`：`archive/*` | 归档权威 | `ufs-main` |

**三条注**：

1. `review` / `verify` / `archive` 在 Comet 原生 schema 中 **`artifacts: []`**，**没有产物文件**；**不存在** `.comet/evidence/<change>/*.json`。审计副本的落盘按 §14 IR-14 与 99 D07 处理：第一层（Runtime evidence 记录）不变，第二层为 `comet-artifacts/evidence/<change>/{review,verify}/**` 的审计副本，副本缺失**阻断归档**（H13）。
2. `exploration-report.md` 与 `test-design.md` **在 Comet schema 中无槽位**，表中路径按 §14 IR-10 确定；在 schema 扩展完成前，二者的存在性由 Stage Gate 直接检查路径，不走 `artifact-structured`。
3. `tasks.md` 的**内容权威**始终是 `ufs-build-plan`；`execute` 只做完成勾选，且经 Comet CLI、由 `ufs-main` 授权，不改变写入者。

## 9.3 单写者规则（per-artifact single-writer）

**规则**：每个产物只有一个合法写入者。违反即 Hook `BLOCK`，不进入"事后 Review"。

| 产物 | 唯一写入者 | 强制方式 |
|---|---|---|
| Story / AC / Scenario | `ufs-requirements` | P1 白名单 |
| Challenge 报告 | `ufs-challenge` | P1 白名单 |
| Design Doc | `ufs-design` | P1 + H02 |
| `test-design.md` | `ufs-test-design` | P1 + H02 |
| `plans/*.md`、`tasks.md` | `ufs-build-plan` | P1 + H03 |
| 源码 / 测试代码 | `ufs-coding` | P1 + H04 |
| `comet.review.v1`（evidence 记录，**非文件**） | Comet Runtime | Runtime evidence 判定 |
| `comet-artifacts/evidence/<change>/review/**`（审计副本） | `ufs-code-review` | P1 + H12 |
| `comet-artifacts/evidence/<change>/index.md`（**归档汇总索引**：职能 / 结论 / 未关闭 BLOCKER 数，四职能全入） | `ufs-main`（由四职能的独立报告汇总，不改写其结论） | 99 D44 + H13 |
| `comet-artifacts/evidence/<change>/{challenge,document-review,review,verify}/**`（四职能独立审计副本，**不合并**） | ④ 各自职能的 Agent | 99 D07 / D44 + H13 |
| `comet.verify.v1`（evidence 记录，**非文件**） | Comet Runtime | Runtime evidence 判定 |
| `comet-artifacts/evidence/<change>/verify/**`（审计副本） | `ufs-verification` | P1 + H13 |
| 归档产物 | `ufs-main` | P1 + H13 |
| `.comet.yaml` | Comet Runtime（`ufs-main` 经 CLI） | Comet guard |

**冲突处理**：任何"两个 Agent 都想写同一产物"的情形，必须在设计期消除，而不是在运行时仲裁。若 Hook 发现第二个写入者 → `BLOCK` + 记录 `attribution: platform`（设计缺陷）。

## 9.4 追溯载体实现

```text
REQ → Capability → Story → AC → Scenario → Engineering Boundary
  → Design → Implementation → Test → Evidence → Archive
```

| 载体 | 实现 | 由谁写 | 状态 |
|---|---|---|---|
| `tasks.md` 任务 ID 映射 | `<!-- comet-task-authority: <tasks-ref> -->` + `<!-- comet-task-ref:<task-id> -->` | `ufs-build-plan` | Comet 原生 |
| Git commit | Requirement/Design/Test/Build Task Ref 写入提交 | H11 Commit Hook | 本设计 |
| 追溯索引（运行时） | 由 Runtime 从真实文件推导的 evidence 记录 | Comet Runtime | Comet 原生 |
| `comet-artifacts/traceability/traceability.yaml`（追溯权威，离线复核） | Evidence Plugin `build_traceability()` | Evidence Plugin | **唯一追溯序列化载体**（`99 D09`）；格式固定 `yaml`，路径固定 `comet-artifacts/traceability/`，**不得**写作 `traceability.json`、也不得放进 `.comet/`；入库口径按 §14.1 IR-4 |
| `codegraph/` 查询留痕 | `source/query/result/repository/commit/timestamp` | CodeGraph Plugin | 本设计 |

**最低追溯要求**：

```text
Code Change → STORY → AC → DES
Test    → AC
Evidence  → TEST → AC
```

**实现层硬规则**：`H12 Verify Hook` 必须机器校验 `Code Change 悬空引用数 == 0`；`H13 Close Hook` 必须校验追溯索引中每条 Evidence 都能回到至少一个 AC。无 AC 对应的 `TC-*` 必须带来源类型标注（`Design Constraint` / `Robustness` 等），否则计入悬空。**追溯载体为 `comet-artifacts/traceability/traceability.yaml`**（`99 D09`）；该文件缺失时，H13 退回校验运行时推导的 evidence（§14.1 IR-14）。

**ID 规范**：

1. 对象 ID 采用**单段或两段**：单段 `<前缀>-<序号>`（表 N1）、两段 `<前缀>-<Story 号>-<序号>`（表 N2）；域标签（`FC`/`ST`）只允许出现在名称中，不出现在 ID 中——因为 ID 必须可被 Hook 机器解析。**前缀白名单与段数规则见主文档 §5.1.1 五张子表**。Implement Item 用 `IMP-`；`BUILD-` / `CHG-` 前缀作废（变更以 change 名标识）。
2. 废弃形式表见主文档 §5.1；本册示例已全部改用规范形式（`IMP-001-02`、`TC-001-01`）。
3. **编号消歧**（主文档 §5.1.2）：规则编号必须带前缀——`FR-1..FR-5`（分册 01 §28 五条正式规则）/ `SR-1..SR-7`（分册 02 各 Skill 硬规则）/ `SYS-1..SYS-7`（分册 02 §3）。**禁止裸用 "Rule N"**。
4. **规则冲突消解顺序**：`FR-*` → `SYS-*` → `SR-*` → Skill Steps，**上位优先**；仅同层内"更具体者优先"。任何"下位覆盖上位"的表述无效。
5. **拼写冻结**（主文档 §5.1.3）：Verification Level 为 `UNIT / COMPONENT / INTEGRATION / SIMULATOR / HARDWARE / INSPECTION / MANUAL`；`UT` 只是 Test Case 类型简称。

## 9.5 产物目录裁决

源材料中存在两套目录：按阶段划分的 `artifacts/**` 布局，以及 `.comet/{state,artifacts,approvals,evidence,traceability}` + `.opencode/**` + `project/**` 的实施层布局。

**本册裁决（不新建重叠目录）**：

| 原 `artifacts/` 子目录 | 裁决去向 |
|---|---|
| `artifacts/requirement/` | 保留在 `comet-artifacts/requirements/`（Stage 0 的合法产物目录，由 `prd-split` 白名单硬绑定） |
| `artifacts/open/` | 归 `<openSpecRoot>`（proposal / delta spec）；探索报告按 §14 IR-10 归 `<superpowersRoot>/reports/` |
| `artifacts/design/`、`artifacts/test-design/` | Design Doc 归 **`<superpowersRoot>/specs/`**；`test-design.md` 按 §14 IR-10 同根 |
| `artifacts/build/` | 计划归 **`<superpowersRoot>/plans/`**；`tasks.md` 归 `<openSpecRoot>/changes/<change>/` |
| `artifacts/test/**` | 测试代码在仓库内；测试执行原始输出由 Test Plugin 产出，evidence 由 Runtime 推导 |
| `artifacts/verify/**`、`artifacts/close/**` | **无对应产物文件**；`comet.verify.v1` / `comet.archive.v1` 仅 evidence 记录 |

**包含关系**：`.comet/` 是**运行时层**，`<openSpecRoot>` / `<superpowersRoot>` 是**产物层**，`comet-artifacts/` 是**Stage 0 层**。三者不重叠。

**持久化决定**：Comet 的 evidence 默认**运行时推导**（第一层）。审计副本（第二层）统一落 `comet-artifacts/evidence/<change>/`，该路径位于 `comet-artifacts/` 之下，**默认入库**，不受 `.comet/**` 忽略规则影响；`ufs-code-review` / `ufs-verification` 分别只被授予 `.../review/**`、`.../verify/**` 写路径（§14 IR-14、IR-4，99 D07）。

---

# 10. 目录与运行时设计

本章定义目录骨架与各层内部关系，是平台可落地的最小运行时结构。

## 10.1 顶层目录

```text
<repo-root>/
├── .opencode/    # 平台定义层：Agent / Skill / Plugin / Hook / Config
├── .comet/      # Comet 运行时层：状态 / 审批 / 证据 / 追溯 / 工作产物
├── comet-artifacts/ # Stage 0 需求基线（change 之外，prd-split 白名单绑定）
├── docs/openspec/  # <openSpecRoot>（docs 布局；legacy 布局为根 openspec/）
├── docs/superpowers/ # <superpowersRoot>：恒为该路径，含 specs/ plans/ reports/
└── project/     # 固件工程本体：源码 / 测试 / 构建 / 模拟器 / 硬件脚本
```

**两条重要说明**：

1. `<superpowersRoot>` **恒为 `docs/superpowers/`**，不随 `classic.artifact_layout` 变化（主文档 §2.5/§8.2）；只有 `<openSpecRoot>` 会在 `docs/openspec/` 与 `openspec/` 之间切换。运行时仍必须以 `comet classic root show` / `comet state check` 返回的 layout 为准（§9.1）。
2. 本仓库当前处于 legacy/docs 冲突态（§14.2 `EXT-01`）：`.comet/config.yaml` 声明 `docs`，但 `docs/openspec/` 已不存在、产物落在根 `openspec/`。Phase 1 落地前必须先解决；本册一律使用逻辑根，故上述目录树仅为示意，不构成对物理路径的断言。

## 10.2 `.opencode/` —— 平台定义层

```text
.opencode/
├── agents/           # 13 个 Agent 定义（默认全拒 + 白名单）
│  ├── ufs-main.md
│  ├── ufs-exploration.md
│  ├── ufs-design.md
│  ├── ufs-test-design.md
│  ├── ufs-build-plan.md
│  ├── ufs-coding.md
│  ├── ufs-code-review.md
│  ├── ufs-verification.md
│  ├── ufs-document-review.md
│  ├── ufs-firmware-expert.md
│  ├── ufs-failure-analysis.md
│  ├── prd-split.md      # ← 已存在，ufs-requirements 的实装
│  └── ufs-challenge.md
├── skills/           # Comet 原生 Skill + UFS 特化 Skill
│  ├── comet-*/        # ← 已存在的 Comet 原生 Skill（不改）
│  ├── prd-split/       # ← 已存在
│  ├── ufs-challenge/
│  ├── ufs-test-design/
│  ├── ufs-writing-plans/
│  ├── ufs-tdd/
│  ├── ufs-code-review/    # ← 取代 requesting-code-review
│  └── ufs-verification/
├── plugins/          # Plugin 实现（PL1–PL6）
│  ├── comet/
│  ├── codegraph/
│  ├── knowledge/
│  ├── omo/          # ← 第二阶段
│  ├── test/
│  └── evidence/
├── hooks/           # Hook 实现（H01–H13）
│  ├── stage-gate/
│  ├── build-gate/
│  ├── code-write-scope/    # ← H04 + H05（最重要）
│  ├── test-contract-protection/
│  ├── pre-verify/
│  ├── pre-close/
│  └── (其余 7 个 Hook 待建)
├── rules/           # 项目级规则（现有：comet-workflow-guard.md）
├── commands/          # 斜杠命令入口（现有 comet-* / opsx-*）
└── config.{yaml,json}     # 平台配置：Hook 开关、Plugin 端点、allow-list 策略
```

**实测基线**：当前仓库 `.opencode/` 已含 `agents/prd-split.md`、`skills/{comet-*,prd-split,requesting-code-review,subagent-driven-development,test-driven-development,…}`、`rules/comet-workflow-guard.md`、`commands/*`。本设计的 `plugins/`、`hooks/`、`ufs-*` Agent 与 Skill 均为**待建**。

## 10.3 `.comet/` —— 运行时层

```text
.comet/
├── config.yaml     # ← 已存在，Comet 项目配置（context_compression / classic.language 等）
├── state/        # 运行时状态（Node Projection、Hook 判定缓存）
│  ├── node.json    # ← 本设计新增：node 投影
│  └── current-change.json
├── artifacts/      # 过程产物（findings / analysis / failures）
│  ├── findings/
│  ├── analysis/
│  └── failures/
├── approvals/      # Human Gate 记录（阻塞式决策点；可选迁至审计副本层）
│  ├── AC-approval.yaml
│  ├── design-approval.yaml
│  ├── plan-approval.yaml
│  ├── scope-approval.yaml
│  └── acceptance.yaml
└── enforcement/     # ← 本设计新增：Hook 判定留痕（BLOCK/ALLOW/waiver）
```

审计副本层不在 `.comet/` 下，而在产物层：

```text
comet-artifacts/evidence/<change>/
├── index.md            # 归档汇总索引（四职能 / 结论 / 未关闭 BLOCKER 数）
├── challenge/          # ufs-challenge 审计副本
├── document-review/    # ufs-document-review 审计副本
├── review/             # review 审计副本
├── verify/             # verify 审计副本
├── test-results/      # Test Plugin 原始输出
├── regression/
├── codegraph/
├── approvals/         # Human Gate 记录（如启用）
└── (无 traceability 副本)  # 见 99 D09：唯一载体是 comet-artifacts/traceability/traceability.yaml
```

**`.gitignore` 与持久化的冲突（已核验）**：

```gitignore
!/.comet/
/.comet/*
!/.comet/config.yaml
```

**事实**：**除 `config.yaml` 外，`.comet/**` 全部被排除**；`comet-artifacts/**` 不在忽略范围。

**决定（§14.1 IR-4）**：

| 目录 | 性质 | 处理 |
|---|---|---|
| `.comet/state/`、`.comet/enforcement/`（判定缓存） | 可重建的运行态 | 保持忽略 |
| `comet-artifacts/evidence/**`（审计副本层） | **审计依据**（归档后须可重审） | 默认入库，无需改 `.gitignore` |
| `.comet/approvals/`（若保留在该位置） | **审计依据** | 迁至 `comet-artifacts/evidence/<change>/approvals/`，或为 `.comet/approvals/**` 增加白名单 |

**实现层硬规则**：在任何 change 被归档之前，审计副本层的入库状态必须已生效；否则归档产物在本地工作区之外不可审计，G3 无法成立。

## 10.4 `project/` —— 固件工程本体

```text
project/
├── firmware/      # 固件源码（scope.files 的实际目标）
│  ├── src/
│  ├── inc/
│  └── config/
├── tests/        # 测试代码
│  ├── unit/
│  ├── component/
│  ├── integration/
│  └── characterization/  # ← Legacy 模式基线
├── build/        # 构建系统（cmake / make）
├── simulator/      # 模拟器与 L4 验证入口
├── hardware/      # L5 硬件在环脚本（JTAG / 板卡）
└── tools/        # 工具链封装
```

**与 Test Plugin 的对应**：`run_unit_test` → `tests/unit`；`run_component_test` → `tests/component`；`run_integration_test` → `tests/integration`；`run_simulator_test` → `simulator/`；`run_hardware_test` → `hardware/`；`run_regression` 按 Regression Level 选择入口。

## 10.5 运行链

```text
User Request → Comet State → Main Agent → Skill → Sub Agent
       → Plugin → Hook → Artifact → Next Node
```

展开为一次 `execute` 写入的完整运行时序：

```text
1. User Request
2. Comet Plugin.get_current_stage()/get_current_node()    ← 禁止猜状态
3. ufs-main 分派 ufs-coding（携带 Build Task）
4. Skill 加载 ufs-tdd；Plugin 准备 CodeGraph / Knowledge 事实
5. ufs-coding 请求写入 target_file
6. H04 Code Write Hook：Stage→Node→Task→File→Contract→Impact→Decision
7. ALLOW → 写入；BLOCK → 归因 + enforcement 记录 + 结束
8. Test Plugin 执行 → Evidence Plugin 记录 → Artifact/Evidence 落盘
9. Guard 校验（semantic）→ 节点完成 → Comet 计算下一 node
```

**运行时序各环节的裁定**（详见 §14）：

- Hook 与 Plugin 的进程边界与调用协议 —— 同进程只读函数调用（§14 IR-5）；
- `.opencode/hooks/` 的加载顺序与优先级 —— 固定顺序 + 全部执行、任一 BLOCK 即阻断（§14 IR-2）；
- `.comet/enforcement/` 的记录 schema —— 十字段固定记录（§14 IR-3）；
- `pre-agent / pre-tool / post-*` 事件面 —— 本册不新增 Hook，由现有 H07/H11/H12/H13 覆盖核心语义（§14 IR-13）；
- Node Projection 的权威计算方 —— Plugin 判定节点身份 + Runtime 同事务落盘 + guard 一致性校验（§14.1 IR-1、§14.2 `EXT-07`）。

---

# 11. 第一版实现范围（MVP）

## 11.1 MVP 的 6 个 Hook

```text
1. stage-gate         → H02 Stage Gate Hook
2. build-gate         → H03 Build Gate Hook
3. code-write-scope      → H04 Code Write Hook + H05 Scope Control
4. test-contract-protection  → H08 Test Contract Protection Hook
5. pre-verify         → H12 Verify Hook
6. pre-close          → H13 Close Hook
```

这 6 个已形成基本安全闭环；实现时**不追求数量**，尤其要详细设计：

```text
code-write → Build Task → Scope → CodeGraph → Hook → Allow / Block
```

**MVP 覆盖的风险 / 未覆盖的风险**：已覆盖 H02（阶段产物）、H03（契约批准）、H04（越权写入）、H08（改 Expected）、H12（无 Review/证据）、H13（条件未满足即归档）；未覆盖（第二阶段）H01、H06、H07、H09、H10、H11，由 §14 IR-6 规定其留痕方式。

## 11.2 MVP 的 5 个 Plugin

```text
1. Comet    2. CodeGraph    3. OpenViking（Knowledge）
4. Test Runner 5. Evidence
```

**OMO 作为第二阶段接入。**

**MVP 的 Agent 子集**：`ufs-main`、`ufs-exploration`、`ufs-design`、`ufs-test-design`、`ufs-build-plan`、`ufs-coding`、`ufs-code-review`、`ufs-verification`、`ufs-document-review`、`ufs-failure-analysis`、`ufs-requirements`（=`prd-split`）、`ufs-challenge`。`ufs-firmware-expert` 可作为按需专家延后。

## 11.3 MVP 实际运行链

```text
User → Comet → Main Agent → ATDD Skill → Open Review → Human
→ Design Agent → Test Design → Review → Human
→ Build Plan → Human → Coding Agent → code-write Hook → CodeGraph → ALLOW
→ TDD → Test Runner → Evidence → Verify Agent → pre-verify Hook
→ Human Acceptance → pre-close Hook → ARCHIVE
```

这已经是一个可以在真实 UFS Firmware 项目上做 Pilot 的最小闭环。

**术语对齐**：上述链中的旧称（工程调查式 "Open Review" 与原 "Close" 阶段名）按主文档裁定改写为 `ufs-document-review` 门禁与 `archive` 阶段；`Design Agent` 与 `Test Design` 同属 `design` 节点。

---

# 12. 实现顺序与验收标准

实现顺序的原则：**先建可机器检查的边界，再建能力**。每个步骤给出可客观判定的验收标准（acceptance criteria），避免"看起来能跑"。

## 12.1 八步实现序列与验收标准

| 步 | 交付 | 依赖 | 验收标准（可客观判定） | 主要风险 |
|---|---|---|---|---|
| **S1** | `.opencode/{plugins,hooks}/`、`.comet/{state,enforcement}/ + .comet/approvals/（`evidence` / `traceability` **不得**放 `.comet/`，见主文档 §13 与 §14.1 IR-4）`；Comet Plugin 只读接口（`get_current_stage/state/change_context/build_task/artifacts`） | — | ① 任一 change 上能读到 `phase/workflow/change_id`；② 无文件名推断路径；③ `comet classic root show` 与 Plugin 返回的逻辑根一致 | 逻辑根解析错误 → 全部 Hook 路径错 |
| **S2** | 13 个 Agent 定义文件（`deny *` 起手 + §8.4 白名单） | S1 | ① 抽 3 个 Agent，`edit` allow 集合与 §8.4 一致；② `ufs-coding` 无 `edit` 到 `test-design.md`/`design.md`/`requirements/**`；③ 无 Agent 使用 `*` allow | 白名单过宽 → H04 沦为唯一防线 |
| **S3** | `.comet/state/node.json` 投影器；`stage-gate`（H02）、`build-gate`（H03） | S1、S2 | ① `phase: build` 下能区分 `plan` 与 `execute`；② `design` 产物缺失 → BLOCK；③ 契约未批准 → BLOCK；④ 每次判定写入 `.comet/enforcement/`；⑤ Build Task 的 `verification_level` 低于被引用 UT 的最高层级 → BLOCK（§7.3.3 第 7 项）；⑥ 存在未被任何 Build Task 引用的 UT → BLOCK（§7.3.3 第 8 项） | Projection 误判 → H04 的 ② 失效 |
| **S4** | `ufs-build-plan`（产出 `scope.files`）、`ufs-coding`、`code-write-scope`（H04+H05） | S3 | ① `scope.files` 内写入 → ALLOW；② 范围外写入 → BLOCK 且归因 `agent`；③ `phase=plan` 时源码写入 → BLOCK；④ 未批准 Build Task 写入 → BLOCK；⑤ 判定含 `hook_id/agent/input_ref/failed_check/attribution` | **平台的成败点**；不得先做能力后做闸门 |
| **S5** | `test-contract-protection`（H08）；`test-design.md` 契约形态；Test Plugin 的 `run_unit_test`/`collect_test_result` | S4 | ① 改 `then` 断言且无 REQ/DES 依据 → BLOCK；② 改 fixture/mock → ALLOW；③ 每次 RED/GREEN 有真实命令与退出码（J8）；④ 无证据的 PASS 不被接受 | 判定过严阻断合法重构 → 用 §7.3 H08 判定表 |
| **S6** | Evidence Plugin（`record_*`、`build_traceability`）；`pre-verify`（H12）；`ufs-verification` | S5 | ① 追溯索引可覆盖每条 Evidence → AC；② 缺 `comet.review.v1` 的 evidence 记录 → BLOCK；③ Runtime 推导的 evidence 与真实文件一致；④ `Tests passing alone` 不通过 verify | Evidence 与 Log 混淆 → 用 §6.7 四类产物区分；离线证据包按 `99 D79`（追溯索引）与 §14.1 IR-4（入库口径） |
| **S7** | `pre-close`（H13）；归档条件 7 项检查；`comet.archive.v1` evidence；四职能审计副本与归档汇总索引 `comet-artifacts/evidence/<change>/index.md` | S6 | ① 7 项任一为 false → `BLOCK ARCHIVE`；② 无 Human Acceptance → BLOCK；③ `comet-artifacts/evidence/<change>/{review,verify}/**` 审计副本存在且索引 BLOCKER 数=0；④ 归档后 Evidence 可被独立重审 | "归档=commit" 混淆 → 明确"验证通过 ≠ 归档授权" |
| **S8** | H01、H06、H07、H09、H10、H11（MVP 外的 6 个）；未覆盖事件面的扩展 Hook | S7 | ① `derived_allow` **恒为空集**（§14 IR-7；`99 D72`）；② H10 按 §14 IR-12 要求 Build Task 显式写等级；③ H09 按 §14 IR-9 校验审批方；④ H06 按 §14 IR-8 处理 `INSPECTION` | 不得在缺少裁定的情况下启用自动放行 |

## 12.2 顺序的硬约束

1. **S4 之前不得把平台给真实项目用**：没有 H04 的能力层等于无防火墙。
2. **不得为通过验收而降低 Hook 严格度**：Hook 的验收标准是"能 BLOCK"，不是"能放行"。
3. **不得并行建设 OMO**：OMO 是第二阶段，MVP 用 Comet 子代理派发。
4. **权限实现固定为 P1–P3**：不引入 Capability Token 作为强制依据（§8.5）。

---

# 13. Comet 版本适配

## 13.1 适配目标

| 项 | 值 |
|---|---|
| 目标版本 | **Comet `0.4.0-beta.19`** |
| 检出位置 | `/home/zsf/comet-openspec-research` |
| 适配性质 | 本设计**不修改 Comet Runtime**（对齐主文档 §13 Phase 1 兼容式落地） |
| 适配边界 | 本设计为叠加层；版本映射到 `0.4.0-beta.19` / 最新版本的对应关系按 §14.2 `EXT-03` 推进 |

## 13.2 适配面清单

| # | 适配面 | Comet 0.4.0-beta.19 事实 | 本设计如何使用 | 是否需要改造 Comet |
|---|---|---|---|---|
| A1 | 阶段常量 | `PHASES = ['open','design','build','verify','archive']` | 直接对齐，不改 | 否 |
| A2 | 节点契约 | `COMET_FIVE_PHASE_NODES`（8 节点，含 kind/skill/schema/guardrail/optional） | 直接对齐；**不新增节点 id** | 否 |
| A3 | Output Schema | `comet.intake/design/plan/execution-evidence/handoff/review/verify/archive.v1` | 直接对齐；`review/verify/archive` **无 artifact** | 否 |
| A4 | guardrail validation | `state-transition` / `artifact-structured` / `semantic` / `evidence-only` | 作为 Hook 的实现分类（§3.3） | 否 |
| A5 | 迁移表 | `CLASSIC_TRANSITION_TABLE`（9 事件）+ `applyClassicTransition` | H01/H02/H12/H13 的判定依据 | 否 |
| A6 | preset | `full / hotfix / tweak`（`CLASSIC_PROFILES`） | §5 裁剪与补偿 | 否 |
| A7 | 逻辑根 | `openSpecRoot/changesRoot/archiveRoot/specsRoot/superpowersRoot` | §9.1 路径基准 | 否 |
| A8 | 状态字段 | `phase`、`workflow`、`designDoc`、`plan`、`buildMode`、`reviewMode`、`verifyMode`、`handoffContext` 等 | Comet Plugin 读取 | 否 |
| A9 | 产物引用 | `data.artifactRefs`（`change/tasks/designDoc/plan/plansRoot/handoffContext`） | §9.2 相对路径 | 否 |
| A10 | handoff 目录 | `<classic-change-dir>/.comet/handoff/` | §4.5 交接包 | 否 |
| A11 | CLI | `comet state/guard/handoff/archive/task/classic` + `comet classic openspec --` 适配器 | 全部 Hook 与 Agent 的调用面 | 否 |
| A12 | Hook Guard 入口 | `classic-hook-guard.ts` / `classic-hook-guard-entry.ts`（检出中存在） | Hook 层可复用的既有入口 | 需评估 |

## 13.3 适配缺口与处置

| # | 缺口 | 现象 | 影响 |
|---|---|---|---|
| G1 | **无 `node` 字段** | `ClassicState` 无 `node`；已有部分判别器仅 `phase` + `build_pause`（`['plan-ready']`）+ `build_mode`，只能区分 `plan`/`execute` 入口，**无法区分 `subagent-execute` 与 `review`** | H04 的 ② 无法在 Comet 内判定 → 依赖本地 Node Projection（§1.1、§4.9） |
| G2 | **`build_mode` 不可回读（MVP 阻塞缺陷）** | 分歧来源是**本仓库 `.opencode/skills/comet-build/SKILL.md` 的本地副本与权威副本漂移**：本地副本（208 行）含 `autonomous` **11 处**，而仓库权威副本 `assets/skills/comet-build/SKILL.md`（293 行）**0 处**；同时 `classic-state.ts` 的 `BUILD_MODES = ['subagent-driven-development','executing-plans','direct']` **不含 `autonomous`**，`enumValue(doc,'build_mode',BUILD_MODES)` 解析 ⇒ 写入 `autonomous` **回读为 `null`** | **处置分两层**：① **规范层**——D59 结论不变，本设计**禁止写入 `build_mode: autonomous`**，`plan`/`execute` 入口一律用 `tasks.md` 存在性 + `build_pause` + Node Projection 判定；② **副本层**——执行 `comet update` 用权威 `assets/` 副本覆写本地 `.opencode/` 副本即可消除该漂移（**不是 Comet 上游缺陷，也不是需要扩 `BUILD_MODES`**） |
| G3 | `review` 为 `optional: true` | 迁移表不强制 review evidence | UFS 用 H12 把"Code Review complete"升为硬条件 |
| G4 | `test-design.md` 不在 schema 内 | `comet.design.v1` 只有 design-doc + delta-spec | UFS 追加 Stage Gate 检查（§4.2 NG-3） |
| G5 | `plan.v1` 的 `tasks.md` 非必需 | `openspec-tasks.required: false` | UFS 显式要求 `tasks.md`（任务权威） |
| G6 | Rulings / checkpoint 与 Hook 的关系 | `rulings.md`、`comet state checkpoint` 由 Skill 侧维护 | **`H11`（Commit Hook）读取 `rulings.md`** 并校验“最近一次 `Design ≠ Existing Code` 裁决已记录”，缺记录时输出 `WARN`（非 `BLOCK`）；**其余 Hook 不读取 `rulings.md`**，也**不读取 `checkpoint`**（checkpoint 属 Runtime 侧，Hook 只读 `phase`/`node`）。裁定见 `99 D67`（本册以 §13.3 G6 承接）：**只在一个 Hook 读取一个文件**的最小耦合（避免双份权威） |
| G7 | `<superpowersRoot>` 物理路径 | 由 root show 决定，非固定 | 所有写路径白名单必须运行期解析 |
| G8 | `BUILD_MODES` 与本地 `comet-build/SKILL.md` 的 `autonomous` 不一致 | 本地副本漂移（见 G2），**权威 `assets/` 副本无此问题**，本设计不修改 Comet Runtime | 兼容处置见 §14.2 `EXT-06`；**以 Runtime 常量为准**，本地副本用 `comet update` 重装即可，**不扩 `BUILD_MODES`** |

### 13.3.1 适配处置

```text
build_mode 枚举（BUILD_MODES vs SKILL.md autonomous）
    → 兼容期内按 §14.2 `EXT-06` 处置：以 tasks.md 存在性 + build_pause=plan-ready 判定 plan/execute 入口；
      build_mode 回读为 null 时按"策略未定" BLOCK，不静默降级
node 投影权威计算方
    → §14 IR-1：Runtime 在状态迁移时原子写入 .comet/state/node.json，guard 校验与 phase 一致
```

**适配顺序硬约束**：在 `build_mode` 的 Comet 侧问题解决前，`plan`/`execute` 的节点判定依据 `tasks.md` 存在性 + `build_pause`，该降级路径本身即 Node Projection 的输入之一，因此 S3/S4 不受阻塞。

## 13.4 适配方式

```text
Comet Runtime（0.4.0-beta.19，不改）
    │ comet CLI / state / guard / handoff
    ▼
Comet Plugin（PL1） ← 只读优先；transition 仅 ufs-main
    │
    ▼
UFS Hook 层（H01–H13） ← 本地强制，不改 Comet
    │
    ▼
UFS Skill / Agent 层
```

**判定**：本设计是**叠加式适配（overlay）**，不是 fork。除 A12 需评估外，其余适配面均可在不改 Comet 的前提下落地。其中 `node` 投影（G1）与 `build_mode` 枚举（G2/G8）的处置固定为 §14.1 IR-1 与 §14.2 `EXT-06`。

---

# 14. 设计裁定与外部依赖

本章给出本册在平台实现层范围内的**设计裁定**，以及本册无法单方面解决、**依赖外部条件**的条目。

**编号命名空间**：本册裁定用 **`IR-1 … IR-14`**（Implementation Ruling），与 `99-共识裁定表.md` 的全局裁定 `D01 … D86` **分属不同命名空间**，不得同号互指。引用全局裁定一律写 `99 D##`；外部依赖用主文档附录 C 的 `EXT-01 … EXT-13`。

## 14.1 设计裁定

| # | 事项 | 决定 | 理由 |
|---|---|---|---|
| IR-1 | Node Projection 的权威计算方 | **节点身份由 Comet Plugin 判定**（只有它知道当前执行的是哪个 Skill / 节点），**但投影必须经 Comet Runtime 的状态写路径、与 `phase` 在同一次事务中落盘**（投影携带 `tx_id`，校验：`source=plugin`、`tx_id` 一致、`phase` 相等）；**Hook 只读投影、不计算**；投影缺失或任一校验失败即 `BLOCK` | Plugin 解决"Runtime 不知道节点"，Runtime 解决"投影与 `phase` 可能分叉"——二者缺一不可。若由 Agent 自报节点，Code Write Hook 的放行依据会退化为被审查方的声明 |
| IR-2 | Hook 加载顺序与优先级 | 固定顺序 `H02 → H03 → H04 → H08 → H12 → H13`；同一次动作上命中多个 Hook 时**全部执行**，任一 `BLOCK` 即阻断，不做短路放行 | 强制层必须 fail-closed；允许严格策略 Hook 被阶段 Hook 短路即等于留出绕过通道 |
| IR-3 | `.comet/enforcement/` 记录 schema | 每条判定固定字段 `hook_id / change_id / phase / node / agent / input_ref / failed_check / attribution / waiver_ref / timestamp`，按 `<change>/<hook_id>/<timestamp>.json` 落盘 | 归属与豁免必须可回溯；固定字段才能被离线核对与统计 |
| IR-4 | 审计副本与 `.gitignore` 的关系 | 审计副本统一落 `comet-artifacts/evidence/<change>/`（默认入库，不受 `.comet/**` 忽略规则影响）；`.comet/state/`、`.comet/enforcement/` 保持忽略；`.comet/approvals/` 若保留在该位置，须迁至审计副本层或加白名单 | 归档后必须可离线重审（G3）；运行态可重建，不应入库（99 D07） |
| IR-5 | Hook 与 Plugin 的进程边界 | Hook 与 Plugin **同进程、只读函数调用**；Hook 不得发起网络或写操作（`enforcement` 记录除外），跨进程调用一律 `BLOCK` | 同进程保证判定不被 Plugin 状态污染，并可限时 fail-closed |
| IR-6 | MVP 未覆盖的 Hook（H01/H06/H07/H09/H10/H11） | 第二阶段实现；在此之前，其覆盖的风险由 `verify` 节点的显式 gap 记录与 H12/H13 兜底检查承担 | 6 个 MVP Hook 已形成安全闭环；未部署的 Hook 必须留痕，不得默认"无风险" |
| IR-7 | 自动放行通道（H06） | **不设任何自动放行通道**：`derived_allow` **恒为空集（`≡ ∅`）**，不得以“影响范围内”“文件数 ≤5”“改动很小”为理由放行；CodeGraph 推导的 `potential_files` 只作为 Human Review 的建议材料 | 阈值未量化前，自动放行等于把范围决策交给工具 |
| IR-8 | `INSPECTION` 验证层级语义 | **四项判定式（逐字引用 `99 D20`，不得改写）**：① 被检查对象带**版本号或 commit hash**；② **检查项被逐条列出**；③ **每条给出 `PASS`/`FAIL` 与依据**（文件路径 / 表项名）；④ **结论已持久化**。**附加要求**：必须携带**明确审批方**（`approver`）与 `DEC-nnn`（不计入四项）。Regression Hook 遇 `INSPECTION` 时强制 Human 指定回归等级，不得默认放行 | 语义空白不得成为默认放行的通道；权威见 `99 D20`、分册 01 `MR-4`、分册 02 `SKR-6` |
| IR-9 | Legacy `non-testable` 标记机制 | 标记必须由 `design` 节点写入、**Human Gate 批准**，并在计划中显式列出；无审批方的标记视为无效 | 否则该豁免会退化为跳过测试的借口 |
| IR-10 | `exploration-report.md` 与 `test-design.md` 的位置 | 采用主文档给出的建议位置：`<superpowersRoot>/reports/`、`<superpowersRoot>/specs/`；在其 Output Schema 扩展完成前，由 Stage Gate 以路径存在性检查承接 | 产物必须有确定位置，才能被写路径白名单与单写者规则约束 |
| IR-11 | graphify 与 CodeGraph 的调用优先级 | `design` Step 0 的快速结构探索用 graphify；需要可追溯事实与影响分析时用 CodeGraph；**进入 Evidence 的必须是 CodeGraph 结果** | 两者定位不同（快速探索 vs 结构化事实）；双轨保留但限定证据来源 |
| IR-12 | 单条 Build Task 的回归等级 | 等级由 Build Task 显式写入；未写入即视为缺失并 `BLOCK`，不由 Verification Level 自动推导 | 缺少默认策略时，自动推导会产生系统性低估 |
| IR-13 | Hook 事件面（traceability / evidence / pre-agent / pre-tool / post-*） | 本册**不新增** Hook；其核心语义由 H07/H11/H12/H13 的现有检查覆盖，其余作为后续扩展点 | 强制层未闭合前引入更多判定点，只会扩大未定义面 |
| IR-14 | review / verify 的报告落盘（两层语义） | **第一层（Comet 原生事实）**：`comet.review.v1` / `comet.verify.v1` **没有产物文件**，判定依据是 Runtime 推导的 evidence。**第二层（本设计新增）**：审计副本按**四个审查/验证职能各自独立**落盘到 `comet-artifacts/evidence/<change>/{challenge,document-review,review,verify}/**`（**不合并为统一大报告**），并生成**归档汇总索引** `comet-artifacts/evidence/<change>/index.md`（职能 / 结论 / 未关闭 BLOCKER 数，四职能全部入索引）；**副本或其索引缺失阻断归档**（H13）。禁止创建 `review.json` / `verify.json` 这类"Comet 产物" | 归档后须可离线重审（G3），同时不得触碰 Comet 的 schema 事实（99 D07 / D44） |

## 14.2 依赖外部条件

外部依赖事项的**唯一登记处是主文档附录 C**（编号 `EXT-01`…`EXT-13`）；本表是分册视图，用其编号引用，不另立编号空间。

| # | 事项 | 外部条件 | 本设计的处理 |
|---|---|---|---|
| `EXT-01` / `EXT-02` | 本仓库 Comet 布局处于 legacy / docs 冲突态、`comet` CLI 不在 `PATH` | 需先解决布局冲突（`comet doctor` → `comet classic root move docs --apply`，或把配置改回 `legacy`）；当前 `comet` CLI 不在 `PATH`，需先安装 | 本册一律使用逻辑根，设计本身不受影响；Phase 1 落地前必须先解决 |
| `EXT-03` | Comet 版本适配映射 | 需在本架构冻结后映射到 `0.4.0-beta.19` / 最新版本 | 适配面与缺口清单见 §13；本设计为**叠加式适配（overlay）**，不修改 Comet Runtime |
| `EXT-06` | 本地 `comet-build/SKILL.md` 副本与权威 `assets/` 副本漂移（本地 208 行含 `autonomous` 11 处；权威 293 行 0 处） | 执行 `comet update` 重装本地 `.opencode/` 副本；**不需要扩 `BUILD_MODES`，也不需要改 Comet 上游**（`BUILD_MODES` 本身不含 `autonomous` 是正确事实） | 按 **99 D59**：**禁止写入 `build_mode autonomous`**，已写入的历史状态按 `null` 处理；`plan` / `execute` 入口一律用 `tasks.md` 存在性 + `build_pause` + Node Projection 三者判定，不依赖 `build_mode` |
| `EXT-07` | Node Projection 的事务写入钩子 | 需 Comet Runtime 在状态迁移点开放写入钩子，供 Plugin 经该路径与 `phase` 同事务落盘 | 钩子可用前，由 §10.5 运行链中的本地写入 + guard 一致性校验承担（保证 `BLOCK` 语义不失效，但事务原子性降级，需在归档前复核） |

**文档结束。**

配套分册：[00 总体设计](00-总体设计-V2.0.md) ·
[01 方法论](01-方法论-ATDD与测试设计.md) ·
[02 Skill 规范](02-Skill规范.md) ·
[04 Stage 0](04-Stage0-需求分解与Challenge.md)

