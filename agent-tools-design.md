# UFS AI 多 Agent 工具使用规范

版本：2.0  
日期：2026-08-11  
状态：设计定稿  
适用范围：OpenCode Agent Runtime + Comet Classic Workflow

---

## 1. 前提与目标

### 1.1 前提

本文档假定以下工具已经完成部署、认证、索引和健康检查，可在目标 UFS Firmware 仓库中真实调用：

- CodeGraph：代码符号、调用关系、数据流和影响范围查询。
- OpenWiki：正式规范、架构说明和设计规则查询。
- OpenViking：ADR、历史故障、经验教训和评审模式查询与发布。
- Graphify：跨模块依赖和知识关系查询。
- Git：diff、history、blame 和 commit 定位。
- Compiler/Test：编译、静态检查、单元测试和集成测试。
- OpenCode 内置工具：read、write、edit、grep、glob、bash。
- Comet Classic：Open、Design、Build、Verify、Archive 五阶段、状态、Guard 和恢复机制。

所有工具必须通过启动健康检查。健康检查失败属于运行环境故障，不允许伪造 fixture 结果冒充 live evidence。

### 1.2 目标

本规范解决四个问题：

1. Agent 能发现正确工具，并按稳定组合完成任务。
2. Agent 权限最小化，读、写、执行和发布边界明确。
3. 工具调用高效，避免重复查询、无效全量检索和长时间阻塞。
4. 每个 AI 结论可追溯到 Agent、工具调用、原始证据和最终决策。

### 1.3 非目标

- 不重写 Comet Workflow Engine。
- 不增加 LLM 工具路由器。
- 不让 Agent 自由拼接 Provider CLI。
- 不把所有工具强行包装成相同领域语义。
- 不使用 Prompt 代替权限、Hook 或 Gate。

---

## 2. 核心原则

### 2.1 Comet 管流程，Agent 管判断，工具层管执行

```text
Comet
  决定当前阶段、输出要求、阻塞条件和阶段迁移

Agent Orchestrator
  决定任务交给 Main、Expert、Reviewer 或 Extractor

Agent
  理解问题、形成假设、请求能力、解释证据

Tool Runtime
  执行工具、控制权限、超时、缓存、审计和证据归一化
```

任何工具层实现不得绕过 Comet Gate，也不得自行推进 Workflow Phase。

### 2.2 执行式组合优先

高频、稳定、可确定的工具序列封装成组合工具：

```text
impact-analysis
  = CodeGraph 查询 + 关键源码读取 + Git 定位 + 影响排序

evidence-resolve
  = locator 解析 + 文件/符号/行号/commit/hash 校验

traceability-check
  = claim 提取 + evidence 解析 + decision linkage + Gate 判定

knowledge-query
  = OpenWiki/OpenViking/Graphify 查询 + 去重 + 来源保留

publish-knowledge
  = 知识产物校验 + 索引更新 + OpenViking 发布 + 回查
```

组合工具减少 LLM 决策次数，但不得隐藏原始来源和内部调用记录。

### 2.3 原生机制加薄共享执行层

复用 OpenCode 原生机制：

- plugin `tool()` 注册组合工具。
- Agent frontmatter 定义 `mode` 和 `permission`。
- MCP 或 CLI/SDK 连接基础工具。
- `tool.execute.before/after` 执行拦截、审计和自动检查。
- Comet Guard 执行硬 Gate。

增加薄共享执行库，不增加独立平台：

```text
.opencode/plugins/lib/tool-runtime.ts
.opencode/plugins/lib/evidence-envelope.ts
.opencode/plugins/lib/provider-adapters.ts
.opencode/plugins/lib/tool-audit.ts
```

共享执行层只负责公共技术能力：调用上下文、超时、缓存、结果归一化、脱敏、审计。领域行为仍由具体组合工具负责。

**薄共享执行层的边界约束（防实现漂移）**：

- `provider-adapters.ts` 只做**协议适配**（连接、认证、签名转换、超时、重试、结果转归一化），**不做能力路由、不做统一 API 抽象、不合并 Provider 身份**。每个 Provider（CodeGraph / OpenWiki / OpenViking / Graphify）保持独立可识别，adapter 不改变其语义边界。
- `tool-runtime.ts` 提供调用上下文（invocation_id、run_id）与公共执行策略（超时/缓存/重试/脱敏），**不含任何领域知识**（不知道"什么是影响分析"）。
- `evidence-envelope.ts` 定义 Evidence 归一化格式（§4.3），**不做证据有效性判断**（那是 evidence-resolve 的职责）。
- `tool-audit.ts` 记录调用（§9.2），**不决定允许与否**（那是 permission / hook 拦截的职责）。
- 共享执行层**对 Agent 不可见**——Agent 只看到组合工具 schema，不感知 adapter/runtime 存在。
- 违反信号：如果共享层出现"根据输入选择调哪个 Provider"的逻辑、或组合工具需要向共享层描述自己的领域意图，即为越界，应立即回退。

### 2.4 证据事实与语义判断分离

确定性工具只回答事实：

- 文件是否存在。
- locator 是否可解析。
- 符号和行号是否匹配。
- commit/hash 是否一致。
- 工具调用是否成功。

Reviewer 或 Expert 回答语义问题：

- 证据是否支持 claim。
- 证据是否足以解释设计原因。
- 多个来源是否冲突。
- 风险是否已经关闭。

不得把模型判断伪装成确定性 `semantic_mismatch`。

---

## 3. 工具架构

```text
┌────────────────────────────────────────────────────────────┐
│ Agent                                                      │
│ Main Developer | Firmware Expert | Artifact Reviewer       │
│ Knowledge Extractor                                        │
└──────────────────────────────┬─────────────────────────────┘
                               │ capability request
┌──────────────────────────────▼─────────────────────────────┐
│ L1 组合工具                                                 │
│ impact-analysis | evidence-resolve | traceability-check    │
│ knowledge-query | publish-knowledge                        │
└──────────────────────────────┬─────────────────────────────┘
                               │ shared execution contract
┌──────────────────────────────▼─────────────────────────────┐
│ L2 薄共享执行层                                             │
│ permission | timeout | cache | retry | normalize | audit   │
└──────────────────────────────┬─────────────────────────────┘
                               │ adapter
┌──────────────────────────────▼─────────────────────────────┐
│ L3 基础工具                                                 │
│ CodeGraph | OpenWiki | OpenViking | Graphify | Git         │
│ Compiler/Test | read/write/edit/grep/bash                   │
└──────────────────────────────┬─────────────────────────────┘
                               │ evidence and events
┌──────────────────────────────▼─────────────────────────────┐
│ Traceability Plane                                         │
│ decision-log | evidence-index | tool-audit | review-report │
└────────────────────────────────────────────────────────────┘
```

---

## 4. 通用调用契约

### 4.1 ToolRequest

每次组合工具或基础 Provider 调用必须生成调用请求：

```yaml
invocation_id: INV-20260811-0001
run_id: RUN-20260811-001
session_id: session-id
task_id: TASK-001
parent_task_id: null
decision_id: DEC-001
agent: main-developer
phase: design
capability: impact-analysis
risk: high
input:
  symbol: gc_threshold
constraints:
  read_only: true
  timeout_ms: 30000
  max_results: 20
  allow_network: false
```

必填字段：`invocation_id`、`run_id`、`task_id`、`agent`、`phase`、`capability`、`input`。

涉及设计选择、风险结论或 Artifact claim 时，`decision_id` 必填。

### 4.2 ToolResult

```yaml
invocation_id: INV-20260811-0001
tool: impact-analysis
adapter_version: 2.0.0
status: ok
started_at: 2026-08-11T08:00:00Z
completed_at: 2026-08-11T08:00:02Z
duration_ms: 2000
cache_hit: false
evidence_ids: [EVD-001, EVD-002]
raw_output_ref: .comet/runs/RUN-20260811-001/raw/INV-20260811-0001.json
raw_output_hash: sha256:...
diagnostic: []
```

允许状态：

```text
ok | partial | empty | unavailable | timeout | denied | invalid_request | failed
```

`partial`、`empty`、`unavailable` 和 `timeout` 不得转换为成功结论。

### 4.3 EvidenceEnvelope

每条证据必须归一化为：

```yaml
evidence_id: EVD-001
invocation_id: INV-20260811-0001
provider: codegraph
source_type: code
uri: repo://src/gc.c#gc_threshold
path: src/gc.c
symbol: gc_threshold
line_range: 120-136
commit_hash: abc123
retrieved_at: 2026-08-11T08:00:02Z
content_hash: sha256:...
snippet: "..."
relevance: 0.95
confidence: 1.0
freshness:
  index_version: codegraph-index-id
  repository_commit: abc123
raw_output_ref: .comet/runs/RUN-20260811-001/raw/INV-20260811-0001.json
```

任何 Artifact 不得只引用自然语言摘要，必须引用 `evidence_id` 或可由检查器解析的 `[E:type:locator]`。

---

## 5. 组合工具规范

### 5.1 impact-analysis

目的：完成代码影响分析，禁止使用单次 grep 结果代替调用关系分析。

输入：

```yaml
symbol: string | null
file_path: string | null
change_summary: string
depth: direct | transitive
include_history: boolean
```

内部执行：

1. CodeGraph 定位定义、引用、调用者、被调用者和数据流。
2. Node 文件 API 读取命中位置附近源码。
3. Git 查询相关文件当前 commit；`include_history=true` 时查询 blame/history。
4. 高风险或跨模块调用 Graphify 获取依赖关系。
5. 去重、排序并生成结构化影响清单。

输出必须包含：

- 直接影响符号。
- 传递影响符号。
- 受影响模块。
- 高风险路径：power、recovery、GC、NAND、error path。
- 未确认影响。
- Evidence IDs。
- 是否需要 Expert。

停止条件：

- CodeGraph 无法定位输入时返回 `empty`。
- 代码索引 commit 与仓库 commit 不一致时返回 `partial`，并要求重建索引。
- 不得退化为“grep 命中即影响成立”。

### 5.2 evidence-resolve

目的：确定性验证证据定位和版本一致性。

输入：

```yaml
locator: code:src/gc.c:125
expected_symbol: gc_threshold
expected_commit: abc123
expected_hash: sha256:...
```

检查：

- locator 格式。
- 文件存在。
- 行号有效。
- CodeGraph 符号存在且覆盖目标位置。
- commit/hash 一致。
- Wiki/Viking ID 可解析。

输出状态：

```text
valid
invalid_locator
file_missing
line_out_of_range
symbol_missing
symbol_location_mismatch
commit_mismatch
hash_mismatch
knowledge_id_missing
provider_unavailable
```

该工具不得输出“证据是否支持结论”的语义裁决。语义裁决属于 Expert/Reviewer。

### 5.3 traceability-check

目的：检查 Artifact 中 claim、decision、evidence 和 gap 的闭环。

检查：

1. 提取 Artifact 中可判定 claim。
2. 检查每个 claim 是否有 evidence 或 assumption 标记。
3. 调用 `evidence-resolve` 验证 locator。
4. 检查 `decision-log.yaml` 中存在对应 `decision_id`。
5. 检查 assumption 是否进入 `knowledge-gaps.yaml`。
6. 检查 blocking gap、未解决高风险和 Reviewer 状态。
7. 输出 machine-readable report 和人类可读报告。

输出：

```yaml
gate: pass | fail
coverage: 1.0
claims: 12
cited: 12
uncited: []
unresolved: []
linkage_errors: []
blocking_gaps: []
```

Artifact 写入后由 Hook 自动调用。Agent 可主动调用用于预检，但 Gate 不依赖 Agent 是否主动调用。

### 5.4 knowledge-query

目的：按问题类型查询正式规范、历史经验和依赖关系，同时保留来源差异。

输入：

```yaml
question: string
category: architecture | protocol | historical | risk | dependency
risk: low | medium | high
```

确定性路由：

| category | 默认工具 | 补充工具 |
|---|---|---|
| architecture | OpenWiki | CodeGraph |
| protocol | OpenWiki | CodeGraph |
| historical | OpenViking | Git history |
| risk | CodeGraph | OpenWiki、OpenViking、Graphify |
| dependency | Graphify、CodeGraph | OpenWiki |

规则：

- `risk=high` 时至少查询两个独立来源。
- 独立 Provider 可并行执行。
- 结果按 canonical URI 和 content hash 去重。
- 不同来源冲突时必须保留冲突，禁止自动合并成单一结论。
- Provider 超时返回明确状态，不阻塞其他 Provider 结果。
- 只有一个弱来源时，结论不得标为高置信度。

### 5.5 publish-knowledge

目的：让 Knowledge Extractor 在不获取任意写权限的前提下发布知识。

输入：

```yaml
decision_id: DEC-001
artifact_paths:
  - 03_design/design.md
  - 05_review/review-feedback.md
  - 06_verify/verification.md
knowledge_outputs:
  - 07_knowledge/ADR.md
  - 07_knowledge/lesson.md
```

执行：

1. 验证 Comet 当前阶段为 Archive。
2. 验证 Verify 和 Reviewer Gate 已通过。
3. 验证所有知识 claim 的 Evidence IDs。
4. 仅允许写 `07_knowledge/` 和 `knowledge/index.yaml`。
5. 以 `decision_id + repository_commit` 作为幂等键。
6. 发布到 OpenViking。
7. 使用发布 ID 回查，确认知识可检索。
8. 记录 publish invocation、OpenViking URI 和 content hash。

任何验证失败时不得部分发布。

---

## 6. Agent 工具权限矩阵

| Agent | 默认组合工具 | 可用基础工具 | 写权限 | 禁止行为 |
|---|---|---|---|---|
| main-developer | impact-analysis、evidence-resolve、traceability-check、knowledge-query | CodeGraph、Graphify、Git、Compiler/Test、read/write/edit | 代码与当前 Feature Artifact | 任意知识库发布；绕过 Gate；无约束危险 bash |
| firmware-expert | knowledge-query、impact-analysis、evidence-resolve、traceability-check | CodeGraph、OpenWiki、OpenViking、Graphify、Git read-only | 无 | 修改代码、修改 Artifact、执行构建写操作 |
| artifact-reviewer | evidence-resolve、traceability-check、knowledge-query | CodeGraph、OpenWiki、OpenViking、Graphify、Git diff/read-only | 仅 Review 输出，或由专用 review 工具写入 | 修改被审 Artifact；仅信任 Agent 摘要 |
| knowledge-extractor | traceability-check、knowledge-query、publish-knowledge | OpenViking、Git read-only、CodeGraph | 仅通过 publish-knowledge | 任意 edit/bash 写入；修改代码或已审核 Artifact |

### 6.1 Main Developer

默认流程：

```text
impact-analysis
→ 必要时 knowledge-query 或 ExpertRequest
→ 修改代码/Artifact
→ Compiler/Test
→ Artifact write hook 自动 traceability-check
```

允许 grep：

- 查普通文本、错误字符串、配置键。
- CodeGraph 不支持的非符号内容。

禁止 grep：

- 用于替代符号定义、调用者、数据流或传递影响分析。

**禁止 grep 的强制实现（不只靠 prompt）**：

工具本身无法区分"查文本"与"替代 CodeGraph"，因此禁止规则按以下优先级落地：

1. **工具可见性（最强，已实测确认）**：opencode 原生支持 `permission: <tool>: deny` 将工具从 LLM 工具 schema **完全移除**（实测：`grep: deny` 后 LLM 报告 "grep 可见性：NO"，工具列表里不存在，非"可见但被拒"）。因此：
   - **`codegraph` 裸工具 → `deny`**（从 main-developer 工具列表移除）——影响分析只有 `impact-analysis` 一个入口，LLM 无其他路径。
   - **grep 保留 `allow`**——因为 grep 兼具"查文本/错误串/配置键"合法用途，`deny` 会连合法用途一起移除（实测副作用：grep 完全消失）。grep 的代码结构误用靠第 2 层拦截。
2. **hook 参数拦截（次强）**：`tool.execute.before` 检测 `grep` 调用参数，命中代码结构类模式（如参数匹配 `*.c` / `*.h`、疑似符号名的标识符）时拦截，返回引导信息"代码结构查询请用 impact-analysis 工具"。
3. **Gate 兜底（最后）**：Artifact 的 impact 分析段若引用缺失（未由 impact-analysis 产生 metadata），traceability-check 的 Gate 拦截。

**实测结论补充**：grep 无法做"用途级可见性"——permission deny 是二元的（全见或全不可见）。因此分工原则：**codegraph 类"单一用途可替代"工具用可见性级（deny + 组合工具替代），grep 类"多用途且部分合法"工具用拦截级（allow + hook 拦误用）**。三条并行：1 解决"看不见"，2 解决"用错被拦"，3 解决"产物不可信"。三者缺一，禁止规则就退化为 prompt 建议。

### 6.2 Firmware Expert

默认流程：

```text
读取 ExpertRequest
→ knowledge-query
→ impact-analysis
→ evidence-resolve
→ 交叉验证
→ answered 或 insufficient_information
```

Expert 必须只读。证据不足时返回：

```yaml
status: insufficient_information
recommended_action: human_confirmation
```

### 6.3 Artifact Reviewer

默认流程：

```text
读取 Artifact 和 decision-log
→ traceability-check
→ evidence-resolve
→ 必要时独立 knowledge-query/CodeGraph 查询
→ passed 或 failed
```

Reviewer 必须独立验证关键证据。Main/Expert 输出只能作为待验证输入，不能作为唯一事实来源。

### 6.4 Knowledge Extractor

默认流程：

```text
读取已通过产物
→ traceability-check
→ 生成 ADR/Lesson 草稿
→ publish-knowledge
→ OpenViking 回查
```

Extractor 不获取通用 edit 或 bash 写权限。

---

## 7. Comet 各阶段工具规范

### 7.1 Open

Main 必须：

- 使用 `impact-analysis` 获取初始影响范围。
- 使用 `knowledge-query` 查询明确规范约束。
- 将未知设计原因记录为 knowledge gap。
- 产出 proposal、analysis、impact 和 decision-log。

进入 Design 前 Gate：

- Artifact traceability pass。
- 所有高风险未知项已登记。
- blocking gap 已派发 Expert 或明确等待人工确认。

### 7.2 Design

Main 与 Expert 必须：

- Expert 使用至少两个来源处理高风险设计问题。
- Main 只采用带 Evidence IDs 的 Expert 结论。
- Reviewer 独立验证 Design。
- Reviewer failed 时生成 RevisionRequest。

循环：

```text
Reviewer failed
→ Main revise
→ 自动 traceability-check
→ Reviewer re-review
```

默认最多三轮。三轮后仍失败，Workflow 阻塞并升级人工处理。

### 7.3 Build

Main 必须：

- 只实现已通过审核的 Design。
- 使用 Git diff 关联代码变更和 `decision_id`。
- 对高风险模块重新运行 `impact-analysis`。
- 执行 Compiler/Test。
- 记录测试命令、环境、结果和输出 hash。

禁止：

- 在 Build 阶段静默改变设计。
- 使用未经审核的新 Expert 推断直接修改代码。

发生设计变化时必须回退 Design 阶段。

### 7.4 Verify

Main 和 Reviewer 必须：

- 执行完整 Compiler/Test 计划。
- 验证 error、power、recovery 和 backward compatibility 路径。
- 对关键代码 Evidence 重新执行 `evidence-resolve`。
- Reviewer 审核 verification Artifact 和未关闭风险。

进入 Archive 前 Gate：

- 测试通过。
- Reviewer passed。
- blocking gap 为零。
- 高风险 remaining unknowns 为零，或具备明确人工豁免记录。

### 7.5 Archive

Extractor 必须：

- 只消费最终通过的 Artifact、diff 和 Test Evidence。
- 使用 `publish-knowledge` 写 ADR、Lesson 和知识索引。
- OpenViking 发布后执行回查。
- 记录知识 URI、commit 和 decision linkage。

回查失败时 Archive Gate 必须失败。

---

## 8. 权限与安全规范

### 8.1 权限必须由 Runtime 强制

Agent Prompt 中的“禁止”只用于说明。实际约束必须由以下机制实现：

- Agent 工具可见性（最强：错误工具不在工具列表，LLM 无法发起调用）。
- Agent permission（次强：工具可见但调用被拒）。
- 组合工具输入校验。
- `tool.execute.before` 拦截。
- 允许路径检查。
- Comet Guard。

**强度说明**：工具可见性 > permission > hook 拦截 > prompt 说明。设计目标是对"结构分析必须用 impact-analysis"这类关键约束启用**可见性级**强制（不可见即不可用）；对"grep 只允许查文本"这类用途约束启用**hook 拦截级**强制（工具保留但误用被拦）。prompt 说明仅作最后补充，不作为约束依据。

**可见性级已实测确认**：opencode 的 `permission: {<tool>: "deny"}` 会将工具从该 agent 的 LLM 工具 schema 完全移除（实测：deny grep 后，LLM 报告工具列表中无 grep，本地匹配只剩 glob + read）。等价于 deprecated `tools` 字段的 `false`（`{"*": "deny"}` permission）。`permission.task` 的 deny 同样将 subagent 从 Task 工具描述移除（官方文档确认）——因此 subagent 可见性也可按此控制（main-developer 只能派发给白名单内 agent）。

### 8.2 Bash 策略

默认：

```yaml
bash:
  "*": deny
```

按 Agent 添加精确白名单。不得给只读 Agent `bash: allow`。

Main 的危险命令必须阻断或请求人工确认，包括但不限于：

- `git reset --hard`
- 递归删除
- 固件烧录
- 真实硬件操作
- 修改 Git 历史
- 越过工作区写文件

### 8.3 路径约束

- Main 仅写当前仓库和当前 Feature Artifact。
- Reviewer 仅写 Review 输出目录。
- Extractor 仅能通过 `publish-knowledge` 写知识目录。
- 任何工具调用必须解析并校验绝对路径，禁止目录穿越。

### 8.4 日志脱敏

以下内容不得写入 audit/raw output：

- access token
- refresh token
- API key
- Authorization header
- 用户私密凭据

日志记录参数摘要和 hash，不记录敏感原值。

---

## 9. 自动 Hook 与硬 Gate

### 9.1 Artifact 写入 Hook

```text
write/edit Artifact
→ 计算 content hash
→ 自动 traceability-check
→ 生成 traceability-report
→ 生成或更新 ReviewRequest
→ 写 AuditEvent
```

不得使用“未来三次工具调用内必须检查”这类软时序规则。

### 9.2 Tool Audit Hook

每次调用记录：

```yaml
run_id:
session_id:
phase:
agent:
task_id:
decision_id:
invocation_id:
tool:
capability:
args_hash:
started_at:
completed_at:
duration_ms:
status:
cache_hit:
retry_count:
evidence_ids:
raw_output_ref:
raw_output_hash:
fallback_reason:
```

### 9.3 Comet Gate

以下条件必须阻断阶段迁移：

- traceability report 缺失或 `gate=fail`。
- blocking knowledge gap 未解决。
- Reviewer `status=failed`。
- Evidence locator 无法解析。
- 高风险结论只有单一弱来源。
- Verify 未通过。
- Archive 发布或回查失败。

Hook 负责生成事实，Comet Guard 负责决定是否允许迁移。

---

## 10. 效率与可靠性规范

### 10.1 查询顺序

按最小充分证据原则：

```text
代码事实
→ CodeGraph

正式规范
→ OpenWiki

历史原因
→ OpenViking + Git history

跨模块依赖
→ Graphify + CodeGraph

高风险结论
→ 至少两个独立来源
```

禁止每个问题无条件查询全部 Provider。

### 10.2 并发

- 相互独立的 Provider 查询并行执行。
- 依赖前一步定位结果的源码读取串行执行。
- 每个 Agent 默认最多三个并行 Provider 调用。
- Compiler/Test 并发遵循仓库资源限制。

### 10.3 缓存

缓存键至少包含：

```text
tool + normalized input + repository commit + provider index version
```

以下情况缓存失效：

- Git commit 改变。
- CodeGraph/Graphify index version 改变。
- Artifact content hash 改变。
- OpenWiki/OpenViking 数据版本改变。

### 10.4 超时与降级

建议默认值：

| 工具 | timeout | retry |
|---|---:|---:|
| CodeGraph | 15s | 1 |
| Graphify | 20s | 1 |
| OpenWiki | 30s | 1 |
| OpenViking | 30s | 1 |
| Git read-only | 10s | 0 |
| Compiler/Test | 按项目配置 | 0 |

连续三次 timeout/unavailable 后进入 circuit breaker。冷却期间返回明确 `unavailable`，不重复等待。

降级规则：

- Provider 故障不得伪造成功证据。
- 非阻塞问题可返回 `partial` 并保留 unknowns。
- 高风险问题缺少必要来源时必须 `insufficient_information`。
- Compiler/Test 失败不可由文档证据替代。

### 10.5 上下文控制

- 原始工具输出落盘，不整段注入 Agent 上下文。
- Agent 默认接收结构化摘要、Evidence IDs 和关键 snippet。
- 需要细节时按 Evidence ID 二次读取。
- 相同 task 内避免重复查询相同输入。

---

## 11. Agent 通信规范

Agent 间不依赖自由聊天传递关键状态，必须使用结构化 Artifact：

```text
AgentTask
ExpertRequest
ExpertResponse
ReviewRequest
ReviewReport
RevisionRequest
KnowledgeRecord
```

所有交接必须包含：

```yaml
task_id:
parent_task_id:
source_agent:
target_agent:
phase:
decision_ids:
input_artifacts:
input_hashes:
expected_outputs:
blocking:
```

ExpertResponse 必须包含：

- `answered` 或 `insufficient_information`。
- conclusion。
- Evidence IDs。
- confidence。
- risk。
- remaining unknowns。

ReviewReport 必须包含：

- `passed` 或 `failed`。
- findings。
- missing sources。
- unsupported inferences。
- test、compatibility 和 recovery gaps。
- required actions。

---

## 12. 决策追溯规范

目标链路：

```text
最终 Artifact claim
→ decision_id
→ evidence_id
→ invocation_id
→ Agent + Tool + Query
→ raw output hash
→ 文件/符号/行号/commit 或知识 URI
```

最低要求：

- 每个设计决策进入 `decision-log.yaml`。
- 每个结论有 Evidence ID 或 assumption。
- 每个 assumption 进入 `knowledge-gaps.yaml`。
- 每个工具结果保留 invocation ID 和 raw output hash。
- Reviewer 可从 claim 回放到原始证据。
- Extractor 只沉淀已通过 Review 的最终决策。

---

## 13. 端到端标准流程

```text
User Request
  → Comet Open
  → Main impact-analysis
  → knowledge-query
  → knowledge gap
  → ExpertRequest
  → Expert knowledge-query + evidence-resolve
  → ExpertResponse
  → Main Design
  → 自动 traceability-check
  → Reviewer
      ├─ failed → RevisionRequest → Main revise → re-review
      └─ passed
  → Comet Build
  → Main code change + Compiler/Test
  → Comet Verify
  → Reviewer verification review
  → Comet Archive
  → Extractor publish-knowledge
  → OpenViking 回查
  → Workflow archived
```

---

## 14. 验收标准

### 14.1 工具可发现性

- Main 分析代码符号时使用 `impact-analysis`，不以 grep 替代 CodeGraph。
- Expert 能使用 `knowledge-query` 获取规范和历史证据。
- Reviewer 能独立执行 `evidence-resolve`。
- Extractor 只能通过 `publish-knowledge` 发布知识。

### 14.2 权限隔离

- Expert 无法修改代码和 Artifact。
- Reviewer 无法修改被审 Artifact。
- Extractor 无法任意 bash/edit 写入。
- Main 执行危险命令时被阻断或请求人工确认。

### 14.3 Gate

- Artifact 写入后自动生成 traceability report。
- 未运行检查或检查失败时无法进入下一阶段。
- Reviewer failed 能触发 Main revise 和 re-review。
- blocking gap、测试失败和知识回查失败均能阻断 Workflow。

### 14.4 追溯

- 任取一个最终结论，可追溯至 decision、evidence、tool invocation 和原始来源。
- Audit 中无敏感凭据。
- Evidence 中包含 commit/index version，能识别陈旧结果。

### 14.5 效率与故障

- 相同 query/commit 不重复调用 Provider。
- 独立知识查询并行执行。
- Provider timeout 不拖死整个 Workflow。
- 高风险证据不足时返回 `insufficient_information`，不猜测。

### 14.6 全链路

必须使用真实 OpenCode runtime 完成一次：

```text
Open → Design → Build → Verify → Archive
```

通过标准：

- Main → Expert 成功。
- Main → Reviewer → Main revise → re-review 成功。
- Archive → Extractor → OpenViking 发布和回查成功。
- 所有 Comet Gate 真实执行。
- Workflow 最终状态为 `archived`。
- Live report 最终状态为 `passed`。

---

## 15. 最终约束摘要

1. Agent 请求能力，不直接拼 Provider CLI。
2. 高频确定序列封装为组合工具。
3. 工具事实验证与 Agent 语义判断分离。
4. Prompt 只说明规则，Permission、Hook 和 Gate 强制规则。
5. 每次工具调用产生可审计 invocation 和 Evidence IDs。
6. 高风险结论至少两个独立来源。
7. Reviewer 必须独立验证，不只信任上游摘要。
8. Extractor 仅通过受控工具发布知识。
9. Provider 故障明确降级，禁止伪造证据。
10. 完成标准是完整 Comet live workflow 通过，不是单个工具可调用。
