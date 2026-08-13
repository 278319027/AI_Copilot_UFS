# OpenSpec Artifact 生成规范

版本：1.0  
日期：2026-08-13  
适用范围：UFS Firmware Feature 的 Requirement Baseline、Proposal、Delta Specs、Design、Tasks 生成与审查

## 1. 目标

本文规范定义如何将 Main Agent 澄清并经用户批准的需求，转换为 OpenSpec `spec-driven` 规划 Artifact：

```text
approved requirement baseline
-> proposal.md
-> specs/<capability>/spec.md
-> design.md
-> tasks.md
-> openspec validate
-> implementation approval
```

核心边界：

| Artifact | 回答的问题 | 禁止承载 |
|---|---|---|
| `proposal.md` | Why、What、Capability、Impact | 技术实现细节、任务拆分 |
| Delta `spec.md` | 系统必须表现怎样 | 算法选择、文件修改步骤 |
| `design.md` | 如何实现、为何选择、风险如何控制 | 重写需求、执行任务清单 |
| `tasks.md` | 按什么顺序实现和验证 | 新需求、新设计决策 |

## 2. 权威输入

OpenSpec 生成前必须存在经用户明确批准的需求基线，例如：

```text
verification/features/<feature-name>/requirements-baseline.v<N>.yaml
```

最低输入条件：

```yaml
baseline_input_gate:
  baseline_exists: true
  baseline_status: approved_baseline
  baseline_revision_current: true
  baseline_hash_valid: true
  repository_commit_known: true
  important_terms_mapped: true
  blocking_unknowns: 0
  unresolved_conflicts: 0
  unresolved_product_decisions: 0
  unapproved_risks: 0
```

任一条件失败时：

```text
停止生成 OpenSpec Artifact
-> 返回 Requirement Analysis
-> 创建 append-only Requirement revision
-> 解决 Gap/Conflict/Decision
-> 用户批准新 revision
```

OpenSpec 不得自行改变批准后的目标、约束、非目标和验收标准。

## 3. OpenSpec Rules 的作用

`docs/openspec/config.yaml` 中的 `rules` 是 Artifact 生成约束：

```text
rules
  约束 Agent 如何生成内容

schema/template
  约束 Artifact 结构

project Gate
  检查覆盖率和跨 Artifact 一致性

Reviewer
  检查语义正确性

Comet Gate
  决定是否允许进入下一阶段
```

重要限制：

```text
rules 存在 != rules 已被运行时硬强制
```

Agent 每次生成 Artifact 都必须读取：

- `instructions.context`
- `instructions.rules`
- `instructions.template`
- `instructions.dependencies`
- `instructions.resolvedOutputPath`

`context` 和 `rules` 仅作为生成约束，不得复制到 Artifact 正文。

## 4. 推荐完整 Rules

以下内容可合并到 `docs/openspec/config.yaml`：

```yaml
rules:
  proposal:
    - Read the approved requirement baseline before generating proposal.md.
    - Require the baseline status to be approved_baseline.
    - Record the baseline feature ID, revision, content hash, repository commit, and Build Context when available.
    - Treat the approved requirement baseline as immutable input.
    - Preserve approved goals, protected behavior, non-goals, and acceptance intent.
    - Do not add, remove, weaken, or reinterpret approved product requirements.
    - Explain why the change is needed and why it should be made now.
    - Describe externally observable changes at capability level.
    - Identify exactly one new capability unless existing normative capabilities genuinely change.
    - List modified capabilities only when their existing normative behavior changes.
    - Distinguish new capabilities from modified capabilities.
    - Identify affected modules, interfaces, configuration, tests, compatibility, persistence, recovery, and performance areas when known.
    - Preserve Requirement IDs, Constraint IDs, and Acceptance IDs when summarizing scope.
    - Separate evidenced current behavior from proposed behavior.
    - Expose assumptions, unknowns, conflicts, and unavailable Evidence sources.
    - Do not use simulated or fixture Evidence to claim current live repository behavior.
    - Do not include detailed design, algorithms, internal APIs, pseudocode, file-level implementation, or task breakdown.
    - Do not select a technical design unless the approved baseline mandates it.
    - Stop when blocking gaps, conflicts, Product Decisions, or Risk Acceptances remain unresolved.
    - Do not modify production code while generating proposal.md.

  specs:
    - Read the approved requirement baseline and proposal.md before generating delta specs.
    - Define observable and normative behavior using SHALL and SHALL NOT.
    - Preserve Requirement IDs, Constraint IDs, Scenario IDs, and Acceptance IDs.
    - Every normative Requirement must include at least one testable Scenario.
    - Cover normal, boundary, error, recovery, compatibility, concurrency, and performance behavior when applicable.
    - Define inputs, preconditions, triggers, outputs, rejection conditions, and protected behavior.
    - Distinguish ADDED, MODIFIED, and REMOVED Requirements correctly.
    - Use MODIFIED only when existing normative behavior changes, not merely because existing code files change.
    - Do not include algorithms, class/function design, file-level implementation, or task ordering.
    - Do not weaken approved acceptance criteria or omit protected constraints.
    - Stop when observable behavior remains ambiguous or unapproved.
    - Do not modify production code while generating specs.

  design:
    - Treat the approved requirement baseline revision as immutable input.
    - Read proposal.md and all completed delta specs before generating design.md.
    - Reference Requirement IDs, Scenario IDs, Constraint IDs, and Acceptance IDs.
    - Explain technical approach, architecture changes, data flow, interfaces, configuration, state transitions, and module impact.
    - Compare at least two viable options for non-trivial behavior and record rejected alternatives.
    - Separate evidenced current behavior, proposed behavior, assumptions, and unresolved unknowns.
    - Record repository commit, Build Context, configuration hash, and affected modules when available.
    - Analyze normal, boundary, error, recovery, compatibility, concurrency, persistence, and performance paths when relevant.
    - Identify protected invariants and explain how each is preserved.
    - Analyze persistent metadata format, commit points, rollback, and power-loss recovery when durable state is affected.
    - Analyze tasks, callbacks, interrupts, shared state, locks, and execution contexts when concurrency is relevant.
    - Link high-risk decisions to valid Evidence IDs and exact Decision revisions.
    - Do not use OpenViking summaries or Graphify relations as the only primary Evidence for current code behavior.
    - Record unavailable Providers and analysis limitations as unknowns; do not fabricate Evidence.
    - Include migration, backward compatibility, rollout, observability, failure handling, and rollback strategy.
    - Map every Acceptance ID to a verification strategy, but leave implementation ordering to tasks.md.
    - Stop on blocking requirement conflict, safety uncertainty, recovery uncertainty, or unresolved Product Decision.
    - Do not restate proposal motivation except by reference.
    - Do not implement production code while generating design.md.

  tasks:
    - Read proposal.md, all delta specs, design.md, Design Review, and the approved requirement baseline before generating tasks.md.
    - Preserve Requirement IDs, Scenario IDs, Constraint IDs, Acceptance IDs, and selected Design Decision IDs.
    - Generate tasks only for the selected and reviewed design.
    - Do not include work from rejected alternatives.
    - Order tasks by real dependencies: baseline, implementation foundation, integration, error/recovery handling, tests, verification, review, and archive.
    - Keep each task small enough to complete and verify in one focused session.
    - Give every task a stable Task ID.
    - Every implementation task must reference at least one Requirement ID or Constraint ID.
    - Every verification task must reference at least one Acceptance ID or Scenario ID.
    - Every task must define objective, dependencies, expected outputs, allowed scope, verification method, and completion Evidence.
    - Use explicit file or module scope where known; avoid unjustified repository-wide edits.
    - Separate production changes, test implementation, and verification execution.
    - Include baseline build and tests before behavior changes when a runnable baseline exists.
    - Include normal, boundary, error, recovery, compatibility, concurrency, and performance verification when required by specs.
    - Bind build and test results to repository commit, working-tree hash, Build Context, and configuration hash.
    - A task is not complete merely because code was written; required verification must pass and produce Evidence.
    - Add traceability-check after controlled Artifact or Decision changes.
    - Add independent Artifact Review before completion.
    - On Reviewer failure, require append-only revision, Artifact update, and re-review.
    - Add Archive publication only after Trace, Test, and Review Gates pass.
    - Do not create implementation tasks for unresolved requirements, blocking gaps, or unapproved scope.
    - Do not use vague tasks such as implement feature, fix issues, test everything, or update docs.
    - Do not modify production code while generating tasks.md.
```

## 5. Proposal 生成规范

### 5.1 内容边界

`proposal.md` 只包含：

```text
Why
What Changes
Capabilities
Impact
```

需求基线映射：

| Baseline 内容 | Proposal 位置 |
|---|---|
| Problem、Motivation、Goal | `Why` |
| Desired Behavior 概要 | `What Changes` |
| Protected Behavior | `What Changes`、`Impact` |
| New Capability | `Capabilities/New` |
| Existing normative behavior change | `Capabilities/Modified` |
| Modules、Tests、Compatibility、Recovery影响 | `Impact` |
| Non-goals | `Impact` |
| Acceptance概要 | `What Changes`、`Impact` |

代码文件被修改不等于 Capability 被修改。只有已有规范性行为改变时，才列入 `Modified Capabilities`。

### 5.2 Proposal 禁区

不得包含：

- 算法选择。
- 内部 API 或函数设计。
- 伪代码。
- 文件逐项修改方案。
- 实施步骤和任务顺序。
- 未经批准的新目标。
- 为降低实现难度而弱化的验收条件。

### 5.3 Proposal Gate

```yaml
proposal_gate:
  approved_baseline_referenced: true
  baseline_revision_current: true
  baseline_hash_recorded: true
  user_problem_preserved: true
  user_goal_preserved: true
  protected_behavior_preserved: true
  non_goals_preserved: true
  requirement_ids_preserved: true
  capability_boundary_clear: true
  new_and_modified_capabilities_distinguished: true
  impact_scope_declared: true
  implementation_design_absent: true
  task_breakdown_absent: true
  blocking_unknowns: 0
  unresolved_conflicts: 0
```

## 6. Delta Specs 生成规范

### 6.1 内容边界

Delta Spec 定义可观察合同：

```markdown
## ADDED Requirements

### Requirement: Workload-aware performance GC policy

系统 SHALL 根据已批准的 host workload 定义调整 performance GC 策略。

Requirement ID: `REQ-GC-001`

#### Scenario: Sustained high workload

- **GIVEN** FTL 处于正常运行状态
- **WHEN** host workload 持续满足高负载条件
- **THEN** 系统 SHALL 调整 performance GC 策略
- **AND** emergency GC 机制 SHALL 保持有效

Scenario ID: `SCN-GC-001`
```

每项 Requirement 必须：

- 有稳定 ID。
- 使用 SHALL/SHALL NOT。
- 至少包含一个 Scenario。
- 有明确条件和可观察结果。
- 覆盖批准的保护约束。
- 能映射到验收方法。

### 6.2 Delta Specs 禁区

不得包含：

- 函数、类或文件设计。
- 算法内部步骤。
- 任务依赖顺序。
- 未批准的行为数值。
- 用实现描述代替可观察结果。

### 6.3 Specs Gate

```yaml
specs_gate:
  approved_requirements_covered: 1.0
  protected_constraints_covered: 1.0
  every_requirement_has_scenario: true
  requirement_ids_preserved: true
  scenario_ids_preserved: true
  observable_behavior_only: true
  rejection_conditions_defined: true
  ambiguous_behavior: 0
  implementation_details_absent: true
```

## 7. Design 生成规范

### 7.1 推荐结构

具体结构服从 `openspec instructions design --json` 返回的模板。允许扩展时建议：

```markdown
## Context
## Goals / Non-Goals
## Current Architecture
## Design Options
## Decision
## Detailed Design
### Interfaces
### Data Flow
### State Transitions
### Configuration
### Error Handling
### Concurrency
### Persistence and Recovery
### Compatibility
### Observability
## Invariants
## Verification Strategy
## Migration and Rollback
## Risks / Trade-offs
## Unknowns
## Open Questions
```

### 7.2 Design 必须回答

- 当前架构和证据是什么？
- 至少两个候选方案是什么？
- 为什么选择当前方案？
- 哪些方案被拒绝，原因是什么？
- 数据、状态和接口如何变化？
- 正常、边界和错误路径如何工作？
- recovery、power-loss和持久化如何保持正确？
- 并发、callback、task和lock如何处理？
- 如何保持兼容性和受保护不变量？
- 如何观测、迁移和回滚？
- 每个 Acceptance ID 如何验证？
- 哪些事实仍未知？

### 7.3 Design Gate

```yaml
design_gate:
  baseline_revision_current: true
  requirement_ids_covered: true
  protected_constraints_covered: true
  alternatives_compared: true
  selected_option_recorded: true
  rejected_options_recorded: true
  error_path_analyzed: true
  recovery_path_analyzed: true
  concurrency_analyzed_or_not_applicable: true
  persistence_analyzed_or_not_applicable: true
  compatibility_analyzed: true
  invariants_preserved: true
  acceptance_mapping_complete: true
  blocking_unknowns: 0
  reviewer_status: passed
```

Design Gate 和独立 Reviewer 均通过后，才允许生成可执行 Build Tasks。

## 8. Tasks 生成规范

### 8.1 推荐任务结构

```markdown
- [ ] TASK-GC-003 Add workload policy state
  - Requirements: REQ-GC-001
  - Constraints: CON-GC-001
  - Decision: DEC-GC-001 revision 2
  - Depends on: TASK-GC-001, TASK-GC-002
  - Allowed scope: FTL GC policy and approved configuration files
  - Forbidden scope: persistent metadata layout, NAND driver
  - Expected output: Workload policy state with safe defaults
  - Verify: Build affected target and run policy unit tests
  - Evidence: test_run
```

每个 Task 必须包含：

- 稳定 Task ID。
- 关联 Requirement、Constraint、Scenario、Acceptance或Decision ID。
- 真实依赖。
- 目标和预期输出。
- 允许范围和禁止范围。
- 验证方法。
- 预期 Evidence 类型。
- 可判定完成条件。

### 8.2 推荐任务顺序

```text
Baseline
-> Module/Behavior Evidence
-> Implementation foundation
-> Behavior integration
-> Error/Recovery/Compatibility
-> Tests
-> Runtime verification
-> Trace Gate
-> Independent Review
-> Revision/Re-review when failed
-> Archive publication
```

### 8.3 Tasks 禁区

不得出现：

- `实现 Feature`。
- `修复相关问题`。
- `测试所有内容`。
- `更新文档`。
- 没有验证方式的编码任务。
- 没有Requirement关联的实现任务。
- 没有Acceptance关联的验证任务。
- rejected design中的工作。
- blocking Gap 尚未关闭的实施任务。

### 8.4 Tasks Gate

```yaml
tasks_gate:
  selected_design_only: true
  requirement_coverage: 1.0
  acceptance_coverage: 1.0
  dependency_graph_valid: true
  task_ids_unique: true
  implementation_scope_defined: true
  verification_per_task_defined: true
  expected_evidence_per_task_defined: true
  recovery_tasks_present_or_not_applicable: true
  compatibility_tasks_present_or_not_applicable: true
  performance_tasks_present_or_not_applicable: true
  trace_task_present: true
  reviewer_task_present: true
  archive_after_review: true
  blocking_gaps: 0
```

## 9. 标准生成流程

### 9.1 创建 Change

```bash
openspec new change "<change-name>"
openspec status --change "<change-name>" --json
```

使用 `status --json` 返回的：

- `planningHome`
- `changeRoot`
- `artifactPaths`
- `applyRequires`
- Artifact `requires`

不要猜测目录。

### 9.2 逐 Artifact 生成

```bash
openspec instructions proposal --change "<change-name>" --json
openspec instructions specs --change "<change-name>" --json
openspec instructions design --change "<change-name>" --json
openspec instructions tasks --change "<change-name>" --json
```

每次执行：

1. 读取 `status`。
2. 获取当前 Artifact instructions。
3. 重新读取 `dependencies` 文件。
4. 重新读取 approved baseline。
5. 使用 `template` 组织内容。
6. 将 `context` 和 `rules` 作为约束。
7. 写入 `resolvedOutputPath`。
8. 检查文件存在。
9. 重新运行 `status`。
10. 最后运行 `validate`。

### 9.3 最终验证

```bash
openspec status --change "<change-name>"
openspec validate "<change-name>"
```

OpenSpec `status` 主要反映 Artifact存在性，不等于项目 Gate通过。仍需运行 Proposal、Specs、Design、Tasks Gate和Reviewer。

## 10. 可直接使用的总指令

```text
基于以下批准需求基线，为OpenSpec change `<change-name>`生成完整规划Artifact：

Baseline:
<requirements-baseline-path>

执行要求：
1. 验证baseline存在、status=approved_baseline、revision/hash有效。
2. blocking unknown、conflict、Product Decision或Risk Acceptance未解决时停止。
3. 使用当前项目默认spec-driven schema。
4. 运行openspec status --change `<change-name>` --json。
5. 按Artifact依赖顺序生成proposal、delta specs、design和tasks。
6. 每个Artifact生成前运行对应openspec instructions ... --json。
7. 使用resolvedOutputPath，不猜测目录。
8. 重新读取instructions.dependencies和approved baseline。
9. 使用instructions.template；context和rules只作为约束，不复制到正文。
10. 保留Feature、Requirement、Constraint、Scenario、Acceptance和Decision ID。
11. proposal只写Why、What、Capabilities和Impact。
12. specs只写可观察SHALL/SHALL NOT行为及Scenario。
13. design写技术方案、替代方案、取舍、安全、恢复和验证策略。
14. tasks只为选定且已评审Design生成依赖有序、可验证任务。
15. 不修改UFS固件生产代码。
16. 完成后运行openspec validate并报告Artifact状态和Gate结果。
```

## 11. 跨 Artifact 覆盖检查

生成完成后必须验证：

```text
每个用户目标
-> 至少一个 Requirement

每个 Requirement
-> 至少一个 Scenario

每个 protected behavior
-> SHALL NOT 或保持型 Requirement

每个 Requirement/Constraint
-> Design处理策略

每个 Acceptance
-> 至少一个 Verification Task

每个 Implementation Task
-> Requirement/Constraint/Decision

每个 Verification Task
-> Scenario/Acceptance + Evidence类型

Trace/Review通过
-> Archive Task
```

建议汇总指标：

```yaml
artifact_coverage:
  goal_to_requirement: 1.0
  requirement_to_scenario: 1.0
  constraint_to_design: 1.0
  acceptance_to_task: 1.0
  task_to_verification: 1.0
```

## 12. 审查清单

### Proposal

- 用户问题、目标和非目标是否保持？
- protected behavior是否遗漏？
- 新/修改Capability是否区分正确？
- 是否偷偷加入技术方案或范围？

### Specs

- 所有规范行为是否可观察、可测试？
- 每项Requirement是否有Scenario？
- SHALL/SHALL NOT是否明确？
- error、recovery和compatibility是否覆盖？

### Design

- 是否只实现批准范围？
- 是否比较了可行替代方案？
- 是否覆盖并发、持久化、恢复和回滚？
- 高风险决策是否有Evidence和Review？
- Acceptance是否都有验证策略？

### Tasks

- 是否只包含选定Design？
- 依赖顺序是否真实？
- 每项任务是否范围明确、可验证？
- Requirement和Acceptance覆盖是否100%？
- Trace、Review、失败修订和Archive顺序是否正确？

## 13. 最终原则

```text
Requirement Baseline
  是用户批准需求的事实来源。

Proposal
  固定立项理由和Capability边界。

Delta Specs
  固定可观察行为合同。

Design
  固定技术选择、替代方案和风险控制。

Tasks
  固定依赖有序、范围受控、可验证的执行计划。
```

任何后续 Artifact 发现上游需求存在实质问题时，都应返回上游创建新 revision，而不是在下游偷偷修正。
