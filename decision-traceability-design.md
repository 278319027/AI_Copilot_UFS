# AI 决策引用级追溯机制 - 可移植设计说明

版本：2.0  
日期：2026-08-11  
状态：设计定稿  
适用范围：使用 AI Agent 参与分析、设计、实现、评审和归档的工程系统

---

## 0. 文档定位

本文定义一套可移植的 AI 决策追溯机制。机制不依赖特定 Agent 框架，但要求运行环境具备：

- 文件系统和稳定的项目根目录。
- Git 或等价版本标识。
- 可执行的证据 Resolver。
- Workflow Hook 和阶段 Gate。
- Reviewer 或等价独立审查角色。

机制分为两部分：

```text
Portable Core
  Claim、Decision、Evidence、Invocation、Revision、Gate

Project Profile
  阶段、风险等级、Provider、Agent、高风险模块、ID namespace
```

UFS Firmware、OpenCode、Comet、CodeGraph、OpenWiki、OpenViking 和 Graphify 属于本文的 UFS Profile，不属于 Portable Core 的强制依赖。

---

## 1. 问题、威胁模型与保证边界

### 1.1 要解决的问题

AI Agent 在工程活动中会形成需求解释、方案选择、参数选择、风险判断和验证结论。主要风险：

| 风险 | 表现 | 后果 |
|---|---|---|
| 无来源结论 | 声称某参数是标准值，但没有依据 | 猜测被当成事实 |
| 假引用 | 引用格式正确，但目标不存在 | 幻觉伪装成证据 |
| 弱引用 | 引用目标存在，但内容与结论无关 | 无关证据掩护错误结论 |
| 陈旧引用 | 文件行号仍存在，但代码已经变化 | 旧事实支持新决策 |
| 静默猜测 | Agent 不说明证据不足 | 高风险未知项被隐藏 |
| 决策覆盖丢失 | Artifact 有结论，decision-log 无对应记录 | 无法回放决策过程 |
| 历史覆写 | assumption 被直接改成 decided | 原始判断和升级过程丢失 |
| 工具来源丢失 | 只保存摘要，不保存调用和原始输出 | 无法审计 AI 如何得到证据 |

### 1.2 核心思想

追溯链必须同时回答：

```text
说了什么？       Claim
为什么这样决定？ Decision
依据是什么？     Evidence
证据如何取得？   Invocation
谁验证过？       Review
后来如何变化？   Revision
```

标准链路：

```text
Artifact Claim
→ Decision Revision
→ Evidence Envelope
→ Tool Invocation
→ 原始来源、commit、hash 或知识 URI
→ Reviewer Verdict
```

### 1.3 保证边界

本机制分三层验证：

| 层级 | 验证内容 | 执行者 |
|---|---|---|
| L1 Locator Validity | 文件、符号、行号、知识 ID、测试运行是否存在 | 确定性 Resolver |
| L2 Provenance Validity | commit、content hash、index version、原始输出是否一致 | 确定性 Resolver |
| L3 Claim Support | 证据是否真正支持 Claim，来源是否冲突 | Reviewer/Expert |

本文保证：

- 每个受控 Claim 有明确 Decision 或 Gap。
- 每个 Evidence 可定位、可验证、可回放。
- 每次证据获取可追溯到 Tool Invocation。
- 未解决风险会阻断 Workflow，而不是静默消失。

本文不保证：

- 有效引用必然意味着结论正确。
- Reviewer 或 Expert 永远不会判断错误。
- 证据来源本身绝对真实。

因此，高风险决策必须同时通过 L1、L2 和 L3。

---

## 2. 核心数据模型

### 2.1 标识符与作用域

所有 ID 必须在 `project + feature + run` 作用域内唯一。禁止只依赖 `DEC-001` 在整个组织中全局唯一。

推荐 ID：

```text
RUN-20260811-0001
TASK-20260811-0001
CLM-20260811-0001
DEC-20260811-0001
EVD-20260811-0001
INV-20260811-0001
GAP-20260811-0001
RVW-20260811-0001
APR-20260811-0001
```

实现可以使用 UUID/ULID。短 ID 只用于展示，持久化对象必须包含完整 namespace：

```yaml
scope:
  project: ufs-firmware
  feature: gc-policy-tuning
  run_id: RUN-20260811-0001
```

### 2.2 Claim Tag

Artifact 中需要追溯的句子必须显式标记 Claim、Decision 和 Evidence：

```markdown
将 gc_threshold 保持 75%，不提高。
[C:CLM-20260811-0001][D:DEC-20260811-0001][E:EVD-20260811-0001][E:EVD-20260811-0002]
```

标签语法：

```text
[C:<claim_id>]
[D:<decision_id>]
[E:<evidence_id>]
[G:<gap_id>]
[R:<review_id>]
```

规则：

- 每个受控 Claim 必须有一个 `C`。
- 决策 Claim 必须有一个 `D`。
- `status=decided` 的 Decision 必须引用至少一个 `E`。
- `status=assumption` 或 `insufficient_information` 必须引用一个 `G`。
- 高风险 Decision 必须引用 Reviewer Verdict `R`。
- 同一 Claim 不得关联多个互相冲突的当前 Decision；替代关系通过 Revision 表达。

旧格式 `[E:type:locator]` 仅作为迁移输入。进入 Gate 前必须归一化为 Evidence ID。

### 2.3 Claim Record

解析 Artifact 后生成 Claim Record：

```yaml
claim_id: CLM-20260811-0001
artifact: 03_design/design.md
artifact_hash: sha256:...
section: GC Policy
line_range: 42-43
claim_type: design_decision
text: 将 gc_threshold 保持 75%，不提高。
decision_id: DEC-20260811-0001
evidence_ids:
  - EVD-20260811-0001
  - EVD-20260811-0002
gap_id: null
review_id: RVW-20260811-0001
```

允许 `claim_type`：

```text
requirement
code_fact
design_decision
risk_conclusion
compatibility_conclusion
verification_conclusion
archive_knowledge
```

### 2.4 Decision Log

`decision-log.yaml` 使用 append-only revision。禁止覆盖历史 Revision。

```yaml
schema: decision-log.v2
scope:
  project: ufs-firmware
  feature: gc-policy-tuning
decisions:
  - decision_id: DEC-20260811-0001
    revision: 1
    supersedes: null
    created_at: 2026-08-11T08:00:00Z
    created_by: main-developer
    phase: design
    question: gc_threshold 是否提高到 85%？
    decision: 暂不提高，等待历史风险证据。
    status: assumption
    risk: high
    confidence: 0.35
    evidence_ids: []
    gap_ids: [GAP-20260811-0001]
    alternatives:
      - option: 提高到 85%
        disposition: not_selected
        reason: 风险未知

  - decision_id: DEC-20260811-0001
    revision: 2
    supersedes: 1
    created_at: 2026-08-11T09:00:00Z
    created_by: main-developer
    change_reason: EXP-20260811-0001 resolved GAP-20260811-0001
    phase: design
    question: gc_threshold 是否提高到 85%？
    decision: 保持 75%，不提高。
    status: decided
    risk: high
    confidence: 0.82
    evidence_ids:
      - EVD-20260811-0001
      - EVD-20260811-0002
    gap_ids: []
    expert_response_ids: [EXP-20260811-0001]
    review_ids: [RVW-20260811-0001]
```

`confidence` 是 Agent 自评，只用于展示和风险提示，不直接决定 Gate。

允许状态：

```text
proposed
assumption
decided
deferred
rejected
superseded
insufficient_information
```

### 2.5 Knowledge Gap

```yaml
schema: knowledge-gaps.v2
gaps:
  - gap_id: GAP-20260811-0001
    decision_id: DEC-20260811-0001
    decision_revision: 1
    question: Why is gc_threshold 75%?
    category: DESIGN_REASON
    risk: high
    blocking: true
    status: resolved
    created_at: 2026-08-11T08:00:00Z
    resolved_at: 2026-08-11T09:00:00Z
    resolution:
      expert_response_id: EXP-20260811-0001
      evidence_ids:
        - EVD-20260811-0001
        - EVD-20260811-0002
```

Gap 状态：

```text
open | routed | waiting_expert | waiting_human | resolved | deferred
```

`blocking=true` 且状态不是 `resolved` 时，相关阶段 Gate 必须失败。

---

## 3. Evidence Envelope

### 3.1 标准结构

Evidence 不是一段自由文本，而是可验证对象：

```yaml
schema: evidence-envelope.v2
evidence_id: EVD-20260811-0001
invocation_id: INV-20260811-0001
provider: codegraph
source_type: code
source_strength: primary
uri: repo://src/gc_policy.c#gc_threshold
path: src/gc_policy.c
symbol: gc_threshold
line_range: 120-136
repository_commit: abc123
provider_index_version: codegraph-index-20260811
retrieved_at: 2026-08-11T08:30:00Z
content_hash: sha256:...
snippet: "..."
raw_output_ref: .comet/runs/RUN-20260811-0001/raw/INV-20260811-0001.json
raw_output_hash: sha256:...
resolver:
  status: valid
  checked_at: 2026-08-11T08:31:00Z
  checks:
    locator: passed
    provenance: passed
```

### 3.2 Evidence 类型

| source_type | 含义 | Resolver 最低要求 |
|---|---|---|
| `code` | 代码事实 | repo 边界、文件、行号、符号、commit、hash |
| `spec` | 正式规范 | Provider URI、文档版本、section、content hash |
| `history` | 历史 bug/ADR/lesson | OpenViking URI、条目状态、版本、hash |
| `dependency` | 模块/关系证据 | Graph/index version、节点和边的来源 |
| `expert_answer` | Expert 结论 | response status、内部 Evidence、request linkage |
| `test_run` | 测试证据 | command、environment、exit code、result hash、commit |
| `human_approval` | 人工裁决 | approver、scope、artifact hash、timestamp、status |
| `tool_output` | 其他工具事实 | invocation、adapter version、raw output hash |
| `archive` | 已发布知识 | knowledge URI、发布 revision、来源 Decision |

### 3.3 Evidence 强度

```text
primary
  代码、正式规范、真实测试结果、签名人工批准

secondary
  ADR、历史经验、专家答复、结构化知识图

inference
  Agent/Reviewer 基于多个来源形成的推理
```

规则：

- `inference` 不能作为自身的唯一依据。
- 高风险 Decision 至少需要两个独立来源，其中至少一个为 `primary`。
- 同一原始来源被多个 Provider 索引，不算两个独立来源。
- ExpertResponse 只有在其内部 Evidence 通过 L1/L2 时才可作为 `secondary`。

### 3.4 独立来源判定

通过 `origin_id` 判断来源独立性：

```yaml
origin_id: repo:abc123:src/gc_policy.c
```

CodeGraph 和 Graphify 如果都来源于同一文件，只算一个来源。OpenWiki 文档如果只是复制该文件内容，也不得自动算独立来源。

---

## 4. Tool Invocation

每次证据获取必须产生 Tool Invocation：

```yaml
schema: tool-invocation.v2
invocation_id: INV-20260811-0001
run_id: RUN-20260811-0001
task_id: TASK-20260811-0001
decision_id: DEC-20260811-0001
agent: firmware-expert
phase: design
tool: knowledge-query
provider: openwiki
adapter_version: 2.0.0
args_hash: sha256:...
started_at: 2026-08-11T08:29:00Z
completed_at: 2026-08-11T08:30:00Z
duration_ms: 60000
status: ok
cache_hit: false
retry_count: 0
evidence_ids: [EVD-20260811-0001]
raw_output_ref: .comet/runs/RUN-20260811-0001/raw/INV-20260811-0001.json
raw_output_hash: sha256:...
```

允许状态：

```text
ok | partial | empty | unavailable | timeout | denied | invalid_request | failed
```

`partial`、`empty`、`unavailable`、`timeout` 和 `failed` 不得被转换为成功 Evidence。

---

## 5. Artifact 标注与解析

### 5.1 显式标注是硬 Gate 数据源

生产 Gate 只依赖显式 Claim Tag，不依赖自然语言动词猜测。

推荐模板：

```markdown
### CLM-20260811-0001 GC threshold 决策

将 gc_threshold 保持 75%，不提高。

[C:CLM-20260811-0001]
[D:DEC-20260811-0001]
[E:EVD-20260811-0001]
[E:EVD-20260811-0002]
[R:RVW-20260811-0001]
```

### 5.2 自然语言检测只做辅助

结论动词、正则或 LLM 可以检测“疑似未标注 Claim”，但结果只产生 warning 或修复建议：

```text
explicit Claim parser
  → 硬 Gate

heuristic/LLM claim detector
  → completeness warning
```

不得让非确定性 LLM 分类直接决定 Workflow Gate。

### 5.2a 受控 Claim 集合的界定（防漏标绕过）

Gate 的 `decision_coverage` 分母是"全部受控 Claim"。必须明确界定**哪些句子算受控 Claim**，否则存在绕过路径：

- 若只算显式标注的 Claim → Agent 漏标的关键决策不在分子也不在分母 → **coverage 恒 1.0，漏标零惩罚**。
- 若由自然语言检测器界定 → 又回到启发式依赖，与 §5.2 矛盾。

**界定规则（必须选择其一并在 Project Profile 声明）**：

```text
方案 A（推荐）: 受控 Claim = 显式标注 ∪ 检测器确认
  检测器识别出的"疑似 Claim"句必须显式标注，或被显式标记为 non-claim。
  未处置的疑似 Claim 计入分母但无 Decision 关联 → decision_coverage < 1.0 → Gate FAIL。
  效果: 漏标不可绕过——Agent 要么标注，要么显式声明"这不是决策句"。

方案 B: 受控 Claim = 显式标注，防漏标由 Reviewer 兜底
  Gate 不检测漏标（coverage 只算显式标注）。
  Reviewer 检查清单强制含"是否存在未标注的决策句"，发现漏标 → Review failed。
  效果: Gate 保持简单，防漏标责任转移到 Reviewer 的语义检查。
```

选择依据：

- 需要**确定性防漏标**（无人工审查介入的自动化流水线）→ 方案 A。
- 已有**可靠 Reviewer 环节**且希望 Gate 保持简单 → 方案 B。
- 混合：Gate 用方案 B，Reviewer 阶段用方案 A 的检测器复核——推荐生产环境采用。

无论选哪个，都必须防止"Agent 少标注即通过"：方案 A 靠分母包含疑似 Claim，方案 B 靠 Reviewer 明确检查。两者都不能只统计显式标注。

### 5.3 Markdown 解析要求

解析器应使用 Markdown AST 或等价结构化解析，默认排除：

- fenced code block
- inline code
- 引用模板
- 示例章节
- HTML comment 中的说明文本

标签必须位于 Claim block 内。孤立 Evidence Tag 不计入 coverage。

### 5.4 Claim 与 Decision 一致性

校验器必须确认：

- Claim 中 `decision_id` 存在。
- Decision 当前 Revision 的决策文本与 Claim 不冲突。
- Claim Evidence 是 Decision Evidence 的子集或相同集合。
- Claim Artifact hash 与 Review scope 一致。
- Decision 已 superseded 时，旧 Claim 不得作为当前结论继续发布。

---

## 6. Resolver 设计

### 6.1 通用 Resolver 返回值

```yaml
status: valid | invalid | stale | ambiguous | unavailable
reason: null
canonical_uri: repo://src/gc_policy.c#gc_threshold
content_hash: sha256:...
checked_at: 2026-08-11T08:31:00Z
diagnostic: []
```

错误原因至少包括：

```text
invalid_locator
path_outside_repository
ambiguous_locator
file_not_found
line_out_of_range
symbol_missing
symbol_location_mismatch
commit_mismatch
content_hash_mismatch
index_version_mismatch
section_missing
knowledge_id_missing
expert_not_answered
expert_evidence_invalid
test_not_executed
test_failed
approval_missing
approval_scope_mismatch
provider_unavailable
```

### 6.2 Code Resolver

必须验证：

1. 路径归一化后的 `realpath` 位于 repository root。
2. 使用 repository-relative path，禁止 `../` 和未限定绝对路径。
3. 文件存在且 commit 匹配。
4. 行号有效。
5. 期望符号存在并覆盖目标行。
6. snippet content hash 匹配。
7. CodeGraph index version 对应当前 commit。

多个同名文件命中时返回 `ambiguous_locator`，不得采用第一个命中。

### 6.3 Spec Resolver

必须通过真实 Provider 查询并验证：

- canonical document URI。
- 文档版本。
- section/anchor 存在。
- content hash。
- retrieved_at。

本地索引存在只能证明索引条目存在，不能替代 Provider 可访问性验证。

### 6.4 History Resolver

必须验证 OpenViking/知识系统中的：

- canonical URI。
- 条目状态不是 deleted/revoked。
- revision 和 content hash。
- 来源 Decision 或原始事件。

### 6.5 Expert Resolver

必须验证：

- ExpertRequest 与 ExpertResponse ID 匹配。
- `status=answered`。
- ExpertResponse 内部 Evidence 非空。
- 内部 Evidence 通过 L1/L2。
- `remaining_unknowns` 与 Decision 风险策略兼容。

只在文件里找到 EXP ID 不算有效 Expert Evidence。

### 6.6 Test Resolver

必须验证真实测试运行，不验证“测试文件存在”：

```yaml
command:
environment:
repository_commit:
started_at:
completed_at:
exit_code:
result_summary:
raw_output_hash:
```

`exit_code != 0` 时不能作为通过性 Evidence。

### 6.7 Human Approval Resolver

Human Approval 使用独立 `approval-log.yaml`，不复用 Decision ID：

```yaml
approval_id: APR-20260811-0001
approver: user-or-team-id
scope:
  decision_id: DEC-20260811-0001
  artifact: 03_design/design.md
  artifact_hash: sha256:...
status: approved
reason: 接受剩余硬件验证风险
approved_at: 2026-08-11T10:00:00Z
```

批准只对记录中的 Decision Revision 和 Artifact hash 生效。Artifact 变化后批准自动失效。

---

## 7. Reviewer 语义验证

### 7.1 Reviewer 输入

- Claim Record。
- 当前 Decision Revision。
- Evidence Envelope。
- Tool Invocation。
- 原始 Artifact 和 hash。
- 风险策略。

### 7.2 Reviewer 输出

```yaml
schema: review-verdict.v2
review_id: RVW-20260811-0001
claim_id: CLM-20260811-0001
decision_id: DEC-20260811-0001
decision_revision: 2
artifact_hash: sha256:...
reviewer: artifact-reviewer
status: passed
support:
  locator_validity: passed
  provenance_validity: passed
  claim_support: passed
  source_independence: passed
findings: []
reviewed_at: 2026-08-11T09:10:00Z
```

### 7.3 Reviewer 判定规则

Reviewer 必须独立回答：

- Evidence 是否与 Claim 属于同一行为、版本和作用域。
- Claim 是否超出 Evidence 能支持的范围。
- 多个来源是否相互独立。
- 来源是否冲突。
- alternatives 和 rejected reason 是否有依据。
- risk、compatibility、error、power/recovery 和 test path 是否覆盖。

高风险 Claim 必须有 `status=passed` 的 Review Verdict。Reviewer 不能只信任 Main 或 Expert 摘要，必要时应重新查询原始来源。

---

## 8. Gate 设计

### 8.1 基础指标

```text
decision_coverage
  = 有有效 Decision 关联的受控 Claim / 全部受控 Claim

**分母定义（与 §5.2a 一致）**：`decision_coverage` 的分母"全部受控 Claim"必须按 §5.2a 选定的方案界定——方案 A 下包含"显式标注 ∪ 检测器确认的疑似 Claim"（未处置的疑似 Claim 计入分母且无 Decision → coverage < 1.0 → FAIL）；方案 B 下只含显式标注，防漏标由 Reviewer 兜底。**禁止在实现时把分母悄悄改为"仅显式标注"**——否则漏标绕过，coverage 恒 1.0。

evidence_coverage
  = 满足 Evidence 策略的 decided Claim / 全部 decided Claim

resolver_validity
  = valid Evidence / 全部被引用 Evidence
```

生产 Gate 要求：

```text
decision_coverage == 1.0
evidence_coverage == 1.0
resolver_validity == 1.0
```

### 8.2 Gate 条件

Gate PASS 必须同时满足：

1. Artifact 存在至少一个受控 Claim；声明无决策的 Artifact 必须匹配允许空决策的 Artifact 类型。
2. 所有 Claim Tag 格式有效且 ID 唯一。
3. 所有决策 Claim 关联有效 Decision 当前 Revision。
4. 所有 `status=decided` Decision 满足 Evidence 策略。
5. 所有 Evidence L1/L2 状态为 `valid`。
6. 所有 assumption/insufficient Decision 关联 Knowledge Gap。
7. 所有 blocking Gap 已 resolved。
8. 所有高风险 Claim 有通过的 Reviewer Verdict。
9. 无未接受的 Evidence conflict。
10. Artifact、Review 和 Approval hash 一致。

任一条件不满足，Gate FAIL。

### 8.3 风险策略

| risk | Evidence 要求 | Review 要求 |
|---|---|---|
| low | 至少一个有效来源 | 可由阶段 Reviewer 批量审核 |
| medium | 至少一个 primary 或两个 independent secondary | Reviewer passed |
| high | 至少两个独立来源，至少一个 primary | 独立 Reviewer passed；remaining unknowns 必须为空或有 Human Approval |

高风险判定基于 Decision/Claim 的 `risk` 字段，不基于引用字符串是否含 `gc.c` 等文件名。

### 8.4 空 Artifact

`claims.length == 0` 时默认 FAIL，避免空真通过。

少数允许无决策的 Artifact 必须在 Project Profile 中显式声明：

```yaml
artifact_policy:
  changelog.md:
    allow_zero_claims: true
```

### 8.5 人工裁决

人工裁决不能使用自由文本绕过 Gate。必须生成 Human Approval，并限定：

- Decision Revision。
- Artifact hash。
- 被豁免规则。
- 接受风险。
- 有效期或失效条件。

安全、硬件破坏性操作或合规规则不得由普通 Approval 豁免。

---

## 9. Decision 生命周期

```text
proposed
  ├─ 有充分 Evidence → decided
  ├─ Evidence 不足 → assumption → Gap
  ├─ 无法回答 → insufficient_information → Gap/Human
  ├─ 暂缓 → deferred
  └─ 被否决 → rejected

assumption/GAP resolved
  → 新 Revision decided

新设计替代旧设计
  → 旧 Revision superseded
  → 新 Decision/Revision 生效
```

每次状态变化必须：

- 创建新 Revision。
- 记录 `supersedes`。
- 记录 actor、timestamp 和 change reason。
- 保留旧 Evidence 和 Review。
- 重新计算受影响 Artifact hash 和 Gate。

---

## 10. Workflow 与 Agent 集成

### 10.1 Agent 指令

Agent Prompt/Skill 只负责说明行为：

```text
每个受控 Claim 必须登记 Claim ID 和 Decision ID。
有依据时引用 Evidence ID。
无依据时创建 Gap，禁止猜测。
```

真正强制依赖：

- Runtime permission。
- Artifact write Hook。
- Resolver。
- Reviewer。
- Workflow Gate。

### 10.2 Artifact 写入 Hook

```text
write/edit Artifact
→ 计算 Artifact hash
→ 解析 Claim Tags
→ 归一化旧 Evidence locator
→ 运行 Resolver
→ 校验 Decision/Gap linkage
→ 生成 traceability report
→ 生成 ReviewRequest
```

Agent 可主动预检，但 Gate 不依赖 Agent 是否记得运行检查器。

### 10.3 Expert 闭环

```text
Main 创建 blocking Gap
→ Hook 路由 ExpertRequest
→ Expert 查询 Evidence
→ ExpertResponse answered/insufficient_information
→ Main 创建新 Decision Revision
→ Artifact 更新
→ Resolver + Reviewer
→ Gate 重算
```

### 10.4 Reviewer 修订闭环

```text
Reviewer failed
→ RevisionRequest
→ Main revise
→ 新 Artifact hash
→ 原 Review 自动失效
→ Resolver 重跑
→ Reviewer re-review
```

默认最多三轮。超过上限后阻塞并升级人工处理，禁止自动放行。

### 10.5 Archive 闭环

```text
Verify passed
→ Extractor 读取最终 Decision Revision/Evidence/Review/Test
→ 生成 ADR/Lesson
→ traceability-check
→ publish-knowledge
→ OpenViking 回查
→ Archive Gate
```

Archive Knowledge 必须回链到原始 Decision、Evidence 和 repository commit。

---

## 11. UFS Firmware Project Profile

Portable Core 在 UFS 项目中的实例：

```yaml
schema: traceability-profile.v2
project: ufs-firmware
phases: [open, design, build, verify, archive]
agents:
  - main-developer
  - firmware-expert
  - artifact-reviewer
  - knowledge-extractor
providers:
  code: codegraph
  spec: openwiki
  history: openviking
  dependency: graphify
high_risk_areas:
  - gc
  - power
  - recovery
  - nand
  - hibern8
required_paths:
  - error
  - power
  - recovery
  - backward_compatibility
```

高风险区域用于风险分类和 Reviewer checklist，不用于通过字符串匹配决定 Resolver 是否失败。

---

## 12. 安全与完整性

### 12.1 路径安全

- 所有路径先做 `realpath`。
- 目标必须位于允许的 repository/workspace root。
- 禁止 `..`、未授权绝对路径和符号链接越界。
- 同名多候选返回 ambiguous，不自动取第一个。

### 12.2 防篡改

- Artifact、Evidence、Review、Approval 和 raw output 均记录 SHA-256。
- Gate 每次运行重新计算 hash。
- hash 不一致时相关 Review/Approval 自动失效。
- Audit log 采用 append-only；生产环境可增加签名或 WORM 存储。

### 12.3 凭据保护

Tool Invocation 只记录参数摘要和 hash。禁止记录：

- API key
- access/refresh token
- Authorization header
- 私密用户凭据

### 12.4 失效与撤销

知识条目、Human Approval 和 ExpertResponse 必须支持 revoked 状态。被撤销来源引用的所有 Decision 应重新进入 Gate 评估。

---

## 13. 并发、幂等与恢复

### 13.1 并发 ID

使用 ULID/UUID 或中心化 allocator，禁止多个 Agent 通过扫描最大 `DEC-xxx` 后自增，避免并发冲突。

### 13.2 幂等键

```text
Claim
  artifact_path + artifact_hash + claim_id

Evidence
  provider + canonical_uri + content_hash + repository/index version

Review
  claim_id + decision_revision + artifact_hash + reviewer

Knowledge publish
  decision_id + decision_revision + repository_commit
```

### 13.3 恢复

Workflow 恢复时只信任持久化状态和文件 hash，不信任对话历史。恢复顺序：

```text
读取 Workflow state
→ 校验 Artifact hash
→ 加载当前 Decision Revision
→ 重验 Evidence freshness
→ 检查 Review/Approval scope
→ 重算 Gate
```

---

## 14. Traceability Report

Machine-readable 报告：

```yaml
schema: traceability-report.v2
run_id: RUN-20260811-0001
artifact: 03_design/design.md
artifact_hash: sha256:...
claims: 6
decision_coverage: 1.0
evidence_coverage: 1.0
resolver_validity: 1.0
unlinked_claims: []
unresolved_evidence: []
stale_evidence: []
linkage_errors: []
conflicts: []
blocking_gaps: []
missing_reviews: []
invalid_approvals: []
gate: pass
generated_at: 2026-08-11T09:20:00Z
```

人类可读报告必须同时列出：

- Claim → Decision → Evidence 映射。
- Resolver 结果和失败原因。
- Reviewer Findings。
- Gap 和 remaining unknowns。
- Gate 规则逐项结果。

---

## 15. 实施与迁移

### 15.1 最小生产实现

| 阶段 | 交付物 | 验证 |
|---|---|---|
| 1 | v2 Schema：Claim、Decision Revision、Evidence、Invocation、Review、Approval | Schema tests |
| 2 | Markdown AST Claim parser | code block/模板/孤立标签测试 |
| 3 | Code/Spec/History/Expert/Test/Human Resolver | live + negative tests |
| 4 | Gate Engine | 全规则 truth table |
| 5 | Artifact write Hook | 写入后自动报告 |
| 6 | Reviewer fail/revise/re-review | 集成测试 |
| 7 | Archive publish/back-query | OpenViking live 测试 |
| 8 | Comet phase integration | 五阶段 E2E |

### 15.2 v1 迁移

```text
[E:code:gc_policy.c:125]
→ evidence-resolve
→ 生成 EVD ID 和 EvidenceEnvelope
→ Artifact 替换为 [E:EVD-...]

DEC-001 可保留为 display_id
→ 增加 scoped canonical decision_id

原地 assumption → decided
→ 拆成 revision 1 和 revision 2
```

迁移过程中允许读取 v1，所有新写入必须使用 v2。Gate 只对归一化后的 v2 数据判定。

---

## 16. 测试与验收

### 16.1 Parser

- 合法 Claim block。
- 未知标签。
- 重复 ID。
- code fence、inline code、模板中的标签不计入。
- Claim 缺 Decision/Evidence/Gap。

### 16.2 Resolver

- 文件不存在。
- 行号越界。
- 符号位置不匹配。
- commit/hash/index version 陈旧。
- `../` 和 symlink 越界。
- 同名文件歧义。
- Wiki section 不存在。
- Viking entry revoked。
- Expert 未 answered 或内部 Evidence 无效。
- Test 未执行、失败或 commit 不匹配。
- Approval scope/hash 不匹配。

### 16.3 Gate

- 100% Decision/Evidence coverage 才通过。
- 任一 unresolved、stale、linkage error 必须失败。
- 零 Claim 默认失败。
- blocking Gap 阻断。
- 高风险单一来源阻断。
- 高风险缺 Reviewer 阻断。
- Artifact 修改后旧 Review/Approval 失效。

### 16.4 Lifecycle

- assumption → resolved → decided 保留完整 Revision。
- superseded Decision 不再作为当前结论。
- Reviewer failed → revise → re-review。
- Provider source revoked 后重新阻断相关 Decision。

### 16.5 E2E

真实 Runtime 完成：

```text
Open
→ Design
→ Main/Expert
→ Reviewer fail
→ Main revise
→ Reviewer passed
→ Build
→ Verify
→ Archive/Extractor
→ Knowledge publish/back-query
```

通过标准：

- 任取最终 Claim，可回放至原始 Tool Invocation 和来源。
- 所有 Gate 真实执行。
- 无敏感凭据进入 Audit。
- Workflow 最终 archived。
- Live report 最终 passed。

---

## 17. 常见陷阱

| 陷阱 | 错误做法 | 正确做法 |
|---|---|---|
| 80% 覆盖即可 | 允许关键决策漏引用 | 受控 Claim 100% 覆盖 |
| 引用存在等于正确 | 只验证文件存在 | L1 + L2 + Reviewer L3 |
| 行号永久稳定 | 只保存 `file:line` | commit + symbol + hash |
| Agent confidence 决定 Gate | `confidence >= 0.6` 放行 | Evidence/Review 策略决定 Gate |
| assumption 原地升级 | 覆盖旧状态 | append-only Revision |
| Human 引用复用 DEC | REVIEW ID 去 Decision Log 查 | 独立 Approval Log |
| Test 文件存在即通过 | resolver 只查文件 | 验证真实 Test Run |
| 正则决定全部 Claim | 动词表作为硬 Gate | 显式 Claim Tag；启发式只 warning |
| 找到第一个同名文件 | findUpward 后直接通过 | canonical path + ambiguous failure |
| Tool 摘要就是证据 | 不存原始输出 | Invocation + raw hash + EvidenceEnvelope |

---

## 18. 价值总结

V2 将“AI 决策可追溯”拆成可验证链路：

```text
Claim 明确
Decision 有版本
Evidence 有来源
Invocation 可回放
Reviewer 验语义
Gate 强制执行
Archive 保留历史
```

该机制不承诺 AI 永不犯错。它承诺错误更难隐藏、未知项不会静默消失、决策可以回放、审查和修订有完整证据链。
