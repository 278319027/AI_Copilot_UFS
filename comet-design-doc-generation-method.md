# Comet Design Doc 生成方法

版本：1.0  
日期：2026-08-14  
适用范围：Comet Classic Full Workflow 的 Design 阶段  
上游事实源：OpenSpec Open 阶段产物  
最终产物：Superpowers 深度技术 Design Doc

## 1. 核心定位

Comet Design 阶段不是继续生成或扩写 OpenSpec `design.md`，而是将 Open 阶段形成的行为合同、高层方案和任务边界，深化为可用于生成实施计划的技术 Design Doc。

```text
OpenSpec proposal.md
  Why、目标、范围、非目标

OpenSpec specs/*/spec.md
  可观察行为、约束、场景

OpenSpec design.md
  高层架构方向、初始方案和约束

OpenSpec tasks.md
  初始任务边界和验证范围

        ↓ deterministic handoff

Superpowers brainstorming
  代码探索、技术澄清、2-3方案、分段确认

        ↓ explicit user approval

Superpowers Design Doc
  深度架构、数据流、状态、错误、恢复、并发和验证设计
```

必须区分：

```text
OpenSpec design.md
!= Superpowers Design Doc

OpenSpec tasks.md
!= Superpowers implementation plan
```

## 2. Artifact 职责

| Artifact | 阶段 | 职责 |
|---|---|---|
| `proposal.md` | Open | Why、What、Capability、Impact |
| `specs/*/spec.md` | Open | SHALL/SHALL NOT行为和Scenario |
| OpenSpec `design.md` | Open | 高层方案框架和初始技术取舍 |
| OpenSpec `tasks.md` | Open | 实现边界和初始任务拆分 |
| Superpowers Design Doc | Design | 深度技术设计 |
| Superpowers implementation plan | Build | 文件级、步骤级实施计划 |

OpenSpec 是行为合同的 canonical spec。Superpowers Design Doc 必须深化该合同，不得替代或重写它。

## 3. Design 输入 Gate

进入 Design 前要求：

```yaml
design_input_gate:
  active_change_exists: true
  workflow: full
  phase: design
  proposal_complete: true
  delta_specs_complete: true
  openspec_design_complete: true
  openspec_tasks_complete: true
  requirements_testable: true
  blocking_product_questions: 0
  design_doc_not_recorded: true
```

输入不完整时停止，不写 Design Doc，不修改生产代码。

## 4. 解析 Classic 布局

每次进入或恢复 Design，先执行：

```bash
comet classic root show
```

只接受：

```yaml
schema: comet.classic-layout.v1
```

将返回值绑定为逻辑根：

- `<classic-open-spec-root>`
- `<classic-changes-root>`
- `<classic-archive-root>`
- `<classic-specs-root>`
- `<classic-superpowers-root>`
- `<classic-change-dir> = <classic-changes-root>/<change-name>`

规则：

- 不猜测物理目录。
- 不扫描或双写 legacy/docs 两套根。
- Comet-owned OpenSpec操作使用`comet classic openspec -- <args>`。
- 路径冲突或迁移未完成时停止，用`comet doctor`检查。

## 5. 入口和恢复验证

正常进入：

```bash
comet state select "<change-name>"
comet state check "<change-name>" design
```

恢复：

```bash
comet state check "<change-name>" design --recover
```

必须根据脚本输出的实际phase、状态和Recovery action继续，不能依赖对话记忆判断恢复位置。

Design操作必须幂等。如果`handoff_context`和`handoff_hash`已经存在，先检查其是否匹配当前OpenSpec产物。

## 6. 生成确定性交接包

执行：

```bash
comet handoff "<change-name>" design --write
```

默认生成：

```text
<classic-change-dir>/.comet/handoff/design-context.json
<classic-change-dir>/.comet/handoff/design-context.md
```

`context_compression: beta`时生成：

```text
<classic-change-dir>/.comet/handoff/spec-context.json
<classic-change-dir>/.comet/handoff/spec-context.md
```

交接包来源：

- `proposal.md`
- OpenSpec `design.md`
- `tasks.md`
- 所有`specs/*/spec.md`

交接包必须包含：

- source path
- source role
- line range或结构化投影
- SHA-256
- canonical spec标记
- context hash
- `[TRUNCATED]`标记和完整源文件路径

交接包必须由Comet脚本生成。禁止Agent手写summary替代。

需要全文时：

```bash
comet handoff "<change-name>" design --write --full
```

## 7. Open产物到Design Doc的映射

### 7.1 Proposal映射

| Proposal内容 | Design Doc用途 |
|---|---|
| Why | 背景引用，不重复详细论证 |
| What Changes | 确定设计必须支持的能力 |
| New Capability | 确定新增组件和机制边界 |
| Modified Capability | 确定兼容和迁移影响 |
| Impact | 确定要调查的模块、接口、配置和测试 |

### 7.2 Delta Specs映射

| Delta Spec内容 | Design Doc必须回答 |
|---|---|
| Requirement | 用什么技术机制满足 |
| GIVEN | 前置状态如何建立 |
| WHEN | 事件如何进入系统 |
| THEN | 哪个组件产生可观察结果 |
| SHALL NOT | 用什么机制保护禁止行为 |
| Error Scenario | 如何检测、传播、恢复和fallback |
| Recovery Scenario | 如何保证重启和断电恢复 |
| Compatibility Scenario | 如何迁移并保持旧行为 |
| Acceptance | 如何生成验证Evidence |

### 7.3 OpenSpec Design映射

OpenSpec `design.md`提供：

- 高层架构方向。
- 初始方案选择。
- 关键技术约束。
- 初步数据流。
- 风险和取舍。

Superpowers Design Doc需要深化：

- 组件和模块边界。
- 接口和数据结构。
- 完整数据流。
- 状态转换。
- task/callback/ISR上下文。
- 并发、共享状态和lock。
- 错误、recovery和power-loss路径。
- 持久化顺序和commit point。
- 兼容、迁移和rollback。
- 测试策略和观测点。

如果代码调查证明OpenSpec高层方向不可行，记录Design Finding并返回确认，不得静默改变方案。

### 7.4 OpenSpec Tasks映射

OpenSpec `tasks.md`提供：

- 必须完成的工作边界。
- Requirement和Acceptance关联。
- 初始依赖关系。
- 不应遗漏的验证工作。

Design Doc可以深化技术分解，但不能：

- 删除对应批准需求的任务边界。
- 加入未批准Feature。
- 把任务清单复制成技术设计。
- 把OpenSpec Tasks当作最终实施计划。

## 8. 建立设计问题矩阵

读取Open产物后，将每个合同项转成设计问题：

```yaml
design_questions:
  - question_id: DQ-GC-001
    requirement_id: REQ-GC-001
    question: workload信息从哪里采集并如何影响performance GC？
    source: delta-spec
    risk: medium
    status: investigating

  - question_id: DQ-GC-002
    constraint_id: CON-GC-001
    question: 如何保证emergency GC不受动态策略影响？
    source: delta-spec
    risk: high
    status: investigating

  - question_id: DQ-GC-003
    scenario_id: SCN-GC-RECOVERY-001
    question: recovery阶段如何选择安全默认策略？
    source: delta-spec
    risk: high
    status: investigating
```

覆盖要求：

```text
每个Requirement
-> 至少一个设计问题

每个Constraint
-> 至少一个保护机制问题

每个Scenario
-> 至少一个执行路径问题

每个Acceptance
-> 至少一个验证问题
```

## 9. 强制执行Brainstorming

Design阶段必须加载Superpowers `brainstorming` Skill。禁止使用普通对话替代。

传入上下文：

```text
Change: <change-name>
Language: <comet state get <change-name> language>
Canonical spec: OpenSpec
OpenSpec Context Pack: <handoff-md-path>
Machine handoff: <handoff-json-path>

任务：
基于OpenSpec行为合同生成深度技术设计。
不得重写批准需求。
必须先调查相关代码，再比较2-3个实现方案。
```

Brainstorming必须依次执行：

1. 探索项目上下文。
2. 逐个澄清技术问题。
3. 确认目的、约束和成功条件。
4. 提出2-3个方案。
5. 推荐一个方案并说明原因。
6. 分段展示架构、组件、数据流、错误处理和测试策略。
7. 获取用户反馈和确认。
8. 使用YAGNI控制范围。

即使OpenSpec文档完整，也不能跳过Brainstorming。

## 10. 定向探索代码

Design阶段不应全仓无界扫描。围绕Feature种子按顺序调查：

```text
Feature种子文件/符号
-> 对外接口
-> 数据结构
-> 初始化和配置
-> definitions/callers/readers/writers
-> 正常路径
-> 边界和错误路径
-> recovery和power-loss
-> callback/task/ISR
-> shared state和lock
-> persistent metadata和commit point
-> existing tests和observability
-> Git/ADR/规范/历史故障
```

现有工具职责：

| 工具 | Design用途 |
|---|---|
| `impact-analysis` | 符号、调用和影响范围 |
| `knowledge-query` | 架构、历史、协议和风险 |
| `evidence-resolve` | locator、commit和hash校验 |
| CodeGraph | 代码结构和直接关系 |
| Graphify | 跨模块关系辅助 |
| OpenViking | 历史Decision、故障和经验 |
| OpenWiki | 正式知识；不可用时记录Gap |

不得用名称猜测：

- 模块ownership。
- callback执行顺序。
- lock语义。
- 持久化保证。
- recovery行为。
- 协议要求。
- 历史设计原因。

## 11. 建立当前架构模型

```yaml
current_architecture:
  entry_points: []
  components: []
  interfaces: []
  data_flow: []
  state_transitions: []
  configuration: []
  shared_state: []
  execution_contexts: []
  locks: []
  persistence: []
  error_paths: []
  recovery_paths: []
  tests: []
  unknowns: []
```

重要当前事实必须关联Evidence。严格区分：

- 源码直接事实。
- 静态预测关系。
- 运行观察。
- 正式规范要求。
- 历史原因。
- Agent推断。

静态调用图不能描述为已观察运行路径。

## 12. Knowledge Gap处理

示例：

```yaml
gap_id: GAP-GC-DESIGN-001
question: recovery阶段是否读取performance threshold？
category: RECOVERY_BEHAVIOR
risk: high
blocking: true
owner: firmware-expert
status: open
```

路由：

| 问题 | 处理者 |
|---|---|
| 代码结构和调用 | 工具 |
| 当前行为 | 代码、测试、runtime trace |
| 设计历史 | Firmware Expert |
| 协议约束 | OpenWiki/正式规范 |
| 产品行为选择 | 用户 |
| 风险接受 | 用户/Approver |
| 设计正确性 | Reviewer |

高风险blocking Gap未关闭时不能定稿Design Doc。

OpenWiki或正式规范不可用且问题属于协议关键时，返回`insufficient_information`，不得使用模拟Evidence替代。

## 13. 候选方案设计

非平凡Feature至少生成两个可行方案，最多通常三个：

```yaml
option_id:
name:
description:
requirements_covered: []
architecture_changes: []
components: []
interfaces: []
data_flow: []
state_transitions: []
configuration: []
normal_behavior:
boundary_behavior:
error_handling:
recovery:
concurrency:
persistence:
compatibility:
observability:
verification:
migration:
rollback:
benefits: []
risks: []
unknowns: []
evidence_ids: []
```

方案比较至少覆盖：

| 维度 | Option A | Option B | Option C |
|---|---|---|---|
| Requirement覆盖 | | | |
| 实现复杂度 | | | |
| 状态复杂度 | | | |
| recovery风险 | | | |
| 并发风险 | | | |
| 兼容性 | | | |
| 可测试性 | | | |
| 性能可预测性 | | | |
| 回滚成本 | | | |

推荐方案必须解释选择理由。不能只因改动代码最少而选择。

## 14. 技术Decision

技术选择使用append-only Decision revision：

```yaml
decision_id: DEC-GC-001
revision: 1
supersedes: null
status: proposed
question: 采用哪种动态GC策略？
alternatives:
  - option_id: OPT-GC-A
  - option_id: OPT-GC-B
```

Evidence和Gap关闭后：

```yaml
decision_id: DEC-GC-001
revision: 2
supersedes: 1
status: decided
decision: 采用离散workload档位策略
change_reason: Evidence和风险分析完成
evidence_ids:
  - EVD-CODE-001
  - EVD-SPEC-001
remaining_unknowns: []
```

高风险Decision要求：

- 至少两个独立Evidence origin。
- 至少一个primary Evidence。
- Evidence resolver有效。
- blocking unknown为0。
- 后续Reviewer绑定精确Decision revision和Artifact hash。

## 15. 分段确认设计

Brainstorming应按部分展示：

1. 架构和组件。
2. 数据流和状态转换。
3. 错误、恢复和并发。
4. 配置、兼容和迁移。
5. 测试和观测。
6. 风险和取舍。
7. Spec Patch。

每部分根据复杂度展开并获取反馈。

最终确认是阻塞点，只展示必要摘要：

- 推荐技术方案。
- 关键取舍和风险。
- 测试策略。
- 需要回写的Spec Patch。

用户明确确认前禁止：

- 创建最终Design Doc。
- 写入`design_doc`状态。
- 运行Design Guard。
- 进入Build。
- 修改生产源码。

## 16. Brainstorm检查点

Brainstorming过程中增量更新：

```text
<classic-change-dir>/.comet/handoff/brainstorm-summary.md
```

建议结构：

```markdown
# Brainstorm Summary

- Change: <change-name>
- Date: <date>

## 已确认技术方案
## 候选方案
## 关键取舍与风险
## 测试策略
## Spec Patch
## 待确认项
```

未确认内容标记为“候选”或“待确认”。该文件是恢复检查点，不是最终Design Doc。

发生上下文压缩时，重新加载：

- `brainstorm-summary.md`
- `design-context.md`或`spec-context.md`
- `design-context.json`或`spec-context.json`

## 17. Spec Patch边界

Design发现OpenSpec合同存在小缺口时，可回写Delta Spec。

允许：

- 补充验收Scenario。
- 修正歧义描述。
- 增加边界条件。
- 明确错误和fallback行为。

禁止：

- 改Feature目标。
- 扩大或缩小批准范围。
- 改产品行为。
- 改已批准性能指标。
- 弱化安全约束。
- 在Design Doc创建第二份需求Spec。

重大变化必须返回Open/需求批准流程。

Delta Spec变化后必须重新执行：

```bash
comet handoff "<change-name>" design --write
```

否则`handoff_hash`过期，Design Guard必须失败。

## 18. 深度Design Doc结构

保存路径：

```text
docs/superpowers/specs/YYYY-MM-DD-<topic>-design.md
```

Frontmatter必须最小化：

```yaml
---
comet_change: <change-name>
role: technical-design
canonical_spec: openspec
---
```

推荐正文：

```markdown
# <Feature> Technical Design

## 1. OpenSpec Contract
引用Change、Capability、Requirement、Constraint和Scenario，不复制完整需求。

## 2. Current Architecture
当前模块、接口、执行路径、数据、状态和Evidence。

## 3. Design Goals And Non-Goals
引用OpenSpec，不自行增加。

## 4. Design Options
两个至三个方案及比较。

## 5. Selected Design
选中方案、Decision revision、Evidence和理由。

## 6. Architecture
组件职责和边界。

## 7. Interfaces And Data Model
接口、结构、ownership、生命周期、单位和范围。

## 8. Data Flow
输入、转换、输出和side effect。

## 9. State And Execution Flow
状态机、task、callback和触发条件。

## 10. Error Handling
检测、传播、重试、fallback和失败状态。

## 11. Concurrency
执行上下文、共享状态、lock和顺序。

## 12. Persistence And Recovery
持久化顺序、commit point、断电窗口和恢复。

## 13. Compatibility And Migration
默认行为、旧配置、格式兼容和升级。

## 14. Observability
日志、trace、metrics和diagnostic。

## 15. Verification Strategy
Requirement/Scenario/Acceptance到测试方法的映射。

## 16. Rollback
代码、配置和数据回滚。

## 17. Risks And Unknowns
风险、缓解措施和非阻塞未知项。

## 18. Traceability
Requirement、Decision和Evidence映射。
```

Design Doc不得：

- 改写批准需求。
- 弱化验收标准。
- 偷偷新增产品行为。
- 把未知项写成事实。
- 复制OpenSpec Tasks作为正文。
- 执行生产代码实现。

## 19. 覆盖矩阵

Design Doc必须建立：

| OpenSpec ID | Design机制 | 风险 | 验证 |
|---|---|---|---|
| `REQ-GC-001` | workload policy组件 | 策略振荡 | boundary test |
| `CON-GC-001` | emergency路径旁路 | 安全回退失效 | emergency test |
| `CON-GC-003` | recovery默认策略 | 恢复不一致 | recovery test |
| `AC-GC-002` | telemetry和基线对比 | 指标噪声 | performance run |

覆盖要求：

```yaml
design_coverage:
  requirement_to_mechanism: 1.0
  constraint_to_preservation: 1.0
  scenario_to_execution_path: 1.0
  acceptance_to_verification: 1.0
```

## 20. Design Doc自审

写入后检查：

1. 无`TODO`、`TBD`和占位符。
2. 章节之间无矛盾。
3. 架构与OpenSpec行为一致。
4. 范围适合单一实施计划，或已明确拆分。
5. 不存在两种解释的关键歧义。
6. 没有无关重构。
7. 每个组件职责、接口和依赖明确。
8. Error/recovery/concurrency/persistence适用性明确。
9. 每个Acceptance有验证方法。
10. blocking Gap为0。

发现问题后内联修正并重新自审。

## 21. 用户复审

推荐组合流程：

```text
方案分段确认
-> 写Design Doc
-> Design Doc自审
-> 用户复审最终Design Doc
-> 用户明确确认
```

用户要求修改时：

```text
修改Design Doc
-> 重新自审
-> 必要时更新Decision revision
-> 必要时回写Spec Patch并重建handoff
-> 再次请求用户确认
```

不得把用户对候选方案的早期反馈自动视为最终文档批准。

## 22. 记录Comet状态

用户确认后：

```bash
comet state set "<change-name>" design_doc \
  "docs/superpowers/specs/YYYY-MM-DD-<topic>-design.md"
```

不得手工修改phase或其他machine-owned字段。

若Spec Patch改变Delta Spec，先重新生成handoff：

```bash
comet handoff "<change-name>" design --write
```

## 23. Design Guard

执行：

```bash
comet guard "<change-name>" design --apply
```

Guard应确认：

- Design Doc存在。
- `design_doc`路径已记录。
- Frontmatter合法。
- `handoff_context`存在。
- `handoff_hash`存在并有效。
- Handoff由脚本生成。
- Handoff hash匹配当前OpenSpec源产物。
- Beta projection结构和源引用有效。
- 必要Spec Patch已回写。
- 当前状态允许`design-complete`。

通过后Guard自动推进：

```text
phase: design
-> phase: build
```

不得用`comet state set phase build`替代Guard。

## 24. Design退出Gate

```yaml
design_exit_gate:
  design_doc_exists: true
  frontmatter_valid: true
  canonical_spec: openspec
  proposal_current: true
  delta_specs_current: true
  openspec_design_current: true
  openspec_tasks_current: true
  handoff_generated_by_runtime: true
  handoff_hash_current: true
  requirement_to_mechanism: 1.0
  constraint_to_preservation: 1.0
  scenario_to_execution_path: 1.0
  acceptance_to_verification: 1.0
  alternatives_compared: true
  selected_decision_current: true
  blocking_gaps: 0
  user_design_approval: true
  comet_design_guard: pass
```

说明：当前Comet Runtime硬校验重点是状态、Design Doc和handoff完整性。覆盖率、Evidence和独立Reviewer等语义Gate需由项目扩展实现，不能仅因Guard通过就声称语义设计完整。

## 25. 自动衔接Build

Design Guard通过后：

```bash
comet state next "<change-name>"
```

处理：

- `NEXT: auto`：加载返回的Build Skill。
- `NEXT: manual`：按HINT交还用户，不再创建确认点。
- `NEXT: done`：流程结束。

`auto_transition`只控制是否自动调用下一Skill，不影响Guard已完成的phase推进。

## 26. 与Build阶段交接

进入`comet-build`后，计划Agent读取：

```text
Superpowers Design Doc
+ OpenSpec tasks.md
+ current Git base ref
```

然后生成：

```text
docs/superpowers/plans/YYYY-MM-DD-<feature>.md
```

因此完整链路：

```text
OpenSpec Open Artifacts
  行为、范围、高层方向、初始任务边界

Comet Design Doc
  深度技术设计

Comet Build Plan
  文件级、步骤级、测试级实施计划
```

Design阶段禁止提前加载`writing-plans`并生成最终实施计划。该职责属于`comet-build`。

## 27. Design阶段禁止行为

- 修改生产源码。
- 生成或执行最终实施计划。
- 直接执行OpenSpec `tasks.md`。
- 用聊天摘要替代Comet handoff。
- 把OpenSpec `design.md`当深度Design Doc。
- 在Design Doc中重写行为合同。
- 跳过Superpowers Brainstorming。
- 跳过用户方案确认。
- 在Spec改变后复用旧handoff hash。
- 手工修改phase。
- 将静态关系描述成已观察运行事实。
- 使用模拟Evidence替代真实Provider失败。
- blocking Gap尚未关闭时进入Build。

## 28. 端到端命令顺序

```bash
comet classic root show
comet state select "<change-name>"
comet state check "<change-name>" design
comet handoff "<change-name>" design --write
comet state get "<change-name>" language

# 加载并执行Superpowers brainstorming
# 代码调查、Knowledge Gap、2-3方案、分段用户确认
# 增量更新brainstorm-summary.md
# 用户明确确认设计方案
# 创建并自审Superpowers Design Doc
# 用户复审最终Design Doc

comet state set "<change-name>" design_doc \
  "docs/superpowers/specs/YYYY-MM-DD-<topic>-design.md"

# 仅在Delta Spec改变时重新执行
comet handoff "<change-name>" design --write

comet guard "<change-name>" design --apply
comet state next "<change-name>"
```

## 29. 最终原则

根据Comet Open产物生成Design Doc，不是做内容扩写，而是：

```text
把OpenSpec行为合同
转换成经过代码调查、Knowledge Gap关闭、2-3方案比较、用户确认，
并覆盖架构、接口、数据流、状态、错误、恢复、并发、持久化、兼容和验证的深度技术设计。
```

下游发现上游行为合同存在实质问题时，返回Open阶段创建新revision；不得在Design Doc中静默修正canonical spec。
