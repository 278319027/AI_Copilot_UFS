# Comet-ATDD 参考知识探索与 AC 驱动设计体系

**详细设计文档 V1.0（讨论基线）**  
**日期：2026-10-30**  
**适用范围：OpenCode + Comet；PRD-Split → Open → Design → Build → Verify**  
**状态：架构原则已讨论确认；实现参数、工具接口及部分 Schema 待验证**

---

## 0. 执行摘要

本方案在 Comet-Open 引入 **Reference Discovery Agent（参考资料探索 Agent）**，根据 PRD、HLD、Wave、Story 和 AC，搜索本地知识库、历史项目设计文档及必要的关联资料，产出可追溯的参考证据包；在 Comet-Design 采用 **AC-Driven, Reference-Guided, Evidence-Grounded, Review-Gated** 方法，先由 AC 推导设计义务，再分析参考设计的可复用性，形成设计、UT 设计和审查证据。

关键裁决：

1. 参考资料主要是**已有项目设计文档**，不自动等同于当前项目的设计基线。
2. 参考设计采用 **R0–R3/RX 内容分类 + E0–E3 证据等级 + A1–A4/AU 适用性结论** 三轴模型。
3. Open 负责**发现、定位、初评与缺口记录**；Design 负责**适用性最终判断、方案取舍、设计与测试**。
4. 探索策略采用 **Wave 级共享探索 + Story 级精确补充**，支持双向证据提升和依赖驱动的增量失效。
5. 检索以 **Knowledge Need（知识需求）** 为中心，而不是仅靠 Story 标题或向量相似度。
6. 不以检索不到历史资料作为普遍阻断条件；缺少不可替代的系统事实时才阻断。
7. 工程师确认关键冲突和高风险设计取舍；独立 Design Review 负责语义与技术审查。

本文件是**方案设计**，不声称已完成 OpenCode/Comet API 兼容性验证、历史文档检索基准测试或固件功能验证。

## 1. 背景与目标

### 1.1 现有工作流基线

- **PRD-Split**：输入 PRD + HLD，输出 Capability、Story、AC、Wave、共享契约及风险证据；采用受控 S0–S6 门禁，允许局部跨阶段推理。
- **Comet-Open**：理解需求、探索代码库/架构/依赖/风险；新增参考资料探索能力，不替代原有探索产物。
- **Comet-Design**：基于 AC 反推设计、接口契约与 UT 设计。
- **Comet-Build**：使用 UT 设计指导 Write Plan 与 TDD 实现。
- **Comet-Verify**：UT、集成测试和 AC 验收，保留可追溯证据。

### 1.2 要解决的问题

- 让 AI 直接从 Story 生成设计容易忽略成熟历史方案，也可能幻觉设计细节。
- 直接复制参考设计又可能继承不适用的执行模型、技术债或未验证假设。
- 多 Story 共享架构知识，重复检索浪费时间且容易产生相互矛盾的结论。
- 检索结果如果没有章节、版本、证据等级和适用前提，无法可靠审查。
- Design 阶段尚无函数实现，需要先形成行为契约级 UT 设计，不能强行绑定函数名。

### 1.3 设计目标与非目标

**目标**：需求驱动发现、可追溯证据、共享检索、适用性判断、AC 覆盖、设计/测试闭环、增量更新、工程师可审计。

**非目标**：Open 阶段自动选择最终算法；证明历史设计必然正确；仅凭静态文档证明数据安全；第一版搭建完整知识图谱；自动替代所有工程师决策。

## 2. 总体架构与职责

```text
PRD + HLD
    │
PRD-Split → Wave / Story / AC / Shared Contracts
    │
    ▼
Comet-Open ───────────────────────────────────────┐
  原有探索 Agent：Codebase / 架构 / 依赖 / 风险      │
  Reference Discovery Agent：                    │
    Wave 共享知识需求 → 共享检索 → 共享证据包        │
                         ↓                       │
    Story 知识需求 → 缺口补检 → Story 证据包         │
    证据验证 / 冲突 / 缺口 / 门禁                     │
    └────── Open Context Package ────────────────┘
    │
    ▼
Comet-Design
  AC → Design Obligations（DO）
  参考内容分级 + 适用性分析 + 方案比较
  Design / Interface / State / Error Handling
  UT Design / Integration & Acceptance Strategy
  Independent Design Review + Engineer Decisions
    │
    ▼
Comet-Build → Comet-Verify
```

### 2.1 职责边界

| 事项 | PRD-Split | Open | Design | Build/Verify |
|---|---|---|---|---|
| Story/AC 定义 | 主责 | 消费 | 反馈缺口 | 验收依据 |
| 参考资料发现 | — | 主责 | 定向补检 | 按需引用 |
| 文档定位、版本、来源 | — | 主责 | 复核 | 保留追踪 |
| R/E 初评 | — | 主责 | 最终确认 | — |
| A 适用性判断 | — | 提示显著冲突 | 主责 | 集成验证 |
| AC → DO | — | 可提出检索问题 | 主责 | 使用 |
| 架构/接口/UT 设计 | — | 不决策 | 主责 | 实现/细化 |
| 独立技术审查 | 需求审查 | 证据质量审查 | 设计审查 | 代码/验收审查 |

**优先级规则**：当前已确认的 AC/PRD 目标与 HLD/系统约束、已批准决策共同构成有效基线；出现相互冲突时必须升级裁决，不能机械排序。历史参考文档与 AI 建议均不得覆盖已确认约束。

## 3. Reference Discovery Agent：运行模型

### 3.1 Agent 定位与输入

形式：OpenCode Custom Subagent（拟定实现）；由 Comet-Open 主 Agent 编排。可并行于原有 codebase 探索，避免职责重叠。

**必需输入**：Wave ID、Story/AC 集合、相关 PRD/HLD 版本与标识、检索范围/访问权限。**可选输入**：共享契约、原有 Open 探索结果、既有证据包、历史设计文档索引、检索预算。

### 3.2 七阶段工作机制

| 阶段 | 任务 | 主要产物 | 关键校验 |
|---|---|---|---|
| RD-0 输入理解 | 校验 Story/AC、PRD/HLD 及版本 | Input Baseline | 关键输入是否缺失/冲突 |
| RD-1 知识需求建模 | AC/约束 → 待回答设计问题 | Knowledge Needs | 关键行为与风险是否覆盖 |
| RD-2 检索计划 | 选择来源、策略、预算、优先级 | Search Plan | 查询可执行、预算有界 |
| RD-3 多策略检索 | 关键词、语义、元数据、关联扩展 | Candidates | 相关性与覆盖范围 |
| RD-4 证据提取 | 精读章节、记录事实与来源 | Evidence Items | 引用可定位、事实推断分离 |
| RD-5 覆盖与缺口 | 识别未覆盖、矛盾、版本风险 | Coverage & Gap Report | 是否需要再次检索 |
| RD-6 发布 | Wave/Story 证据包及门禁状态 | Open Evidence Package | 结构与语义检查 |

RD-1～RD-5 允许局部循环，达到覆盖目标、边际收益低、预算上限或关键资料不可访问时结束。禁止无限循环。

### 3.3 Knowledge Need（KN）定义

KN 是**当前设计需要研究的知识问题**，而不是预设方案。推荐字段：`kn_id`、`question`、`source_refs`、`category`、`scope`、`criticality`、`required_evidence`、`status`、`search_history`、`evidence_ids`。

通用分类：架构/职责、接口/契约、算法/数据结构、状态/生命周期、并发/时序、异常/恢复、性能/资源、测试/验证。

**KN 生成规则**：

1. 提取 AC 中的条件、动作、预期行为、异常、边界与可观察结果。
2. 关联 HLD 的执行模型、模块边界、资源与非功能约束。
3. 从行为推导需要了解的**设计问题**，而不是提前给出实现答案。
4. 通过反例审视失败、竞争、恢复和状态转换；仅在相关时生成对应 KN。
5. 合并同义 KN，保留所有来源 AC 的映射；跨 Story 的公共问题提升为 Wave KN。
6. 审查 KN 是否遗漏关键风险，是否过度泛化、超出 Story 范围或隐含特定实现。

**示例**：AC：GC 与 Host Write 并发时最新写入不可被旧迁移覆盖。可产生 KN：历史映射更新原子性如何保证？冲突如何处理？有效性如何判定？失败如何恢复？有哪些验证案例？不可直接生成“必须使用版本计数器”的设计结论。

### 3.4 检索计划与策略

每个 KN 的检索计划包含：目标、优先级、来源集合、查询变体、预期证据、最大轮次/读取量、停止条件。

采用混合策略：

- **关键词**：模块名、接口名、算法名、术语同义词；适合精确命中。
- **语义检索**：行为、约束、失败模式；适合术语不同的历史文档。
- **元数据过滤**：项目、模块、硬件、架构版本、发布日期、文档状态。
- **关联扩展**：章节引用、依赖文档、决策记录、相邻设计。
- **精读重排**：优先可追溯、与关键 KN 直接相关、前提明确的章节。

不强制所有后端均支持上述策略；工具能力不足时应记录降级模式。所有私有文档默认在用户授权的本地环境处理，不得未经允许上传外部检索服务。

### 3.5 覆盖状态与停止条件

KN 状态：`UNSEARCHED`、`PARTIAL`、`COVERED`、`CONFLICTED`、`NO_EVIDENCE`、`SOURCE_UNAVAILABLE`。

优先搜索 Critical 未覆盖与冲突 KN，其次 High，最后其他。`COVERED` 表示找到足以回答知识问题的文档证据，**不代表该设计可复用**。

Open 交接状态：

- `READY`：证据包可用，关键问题有明确覆盖或合理结论。
- `READY_WITH_GAPS`：参考资料缺失或冲突已透明记录，但 Design 可独立推导。
- `BLOCKED`：必需的系统事实、输入契约或授权资料不可获得，无法安全推进。

缺少历史参考案例本身**不是**普遍阻断条件。

## 4. Wave 共享探索 + Story 精确补充

### 4.1 Wave 层

首次进入 Wave 时，聚合全部 Story/AC 与共享契约，生成 Wave KN，优先搜索跨 Story 架构、数据模型、并发模型、共享接口、异常恢复、关键历史决策。生成 `wave-reference-package`，后续 Story 可复用。

### 4.2 Story 层

每个 Story 先加载 Wave 证据索引，执行 KN 匹配与覆盖检查；仅针对缺口做定向检索，输出 `story-reference-package`。Story 层不得因 Wave 层已有相似证据而忽略当前 AC 的异常或边界要求。

### 4.3 双向共享与冲突

Story 证据如涉及共享契约或明确关联多个 Story，可申请提升为 Wave 共享证据；提升前复核适用范围与版本。共享证据更新后，关联 Story 的证据状态需重新评估。冲突资料应并列保留，不以“最新”或“最相似”自动取胜。

### 4.4 增量失效

依赖图：`PRD/HLD/AC → KN → Evidence → Design Decision → UT/Acceptance Tests`。

| 变化 | 建议动作 |
|---|---|
| AC 语义改变 | 重建受影响 KN，重新检索与设计审查 |
| Story 仅措辞调整 | 比较语义与引用，不必默认全量检索 |
| HLD 执行模型改变 | 失效相关 Wave 证据适用性判断及设计 |
| 文档版本/内容哈希改变 | 标记相关 Evidence 为待复核 |
| 新增 Story | 复用 Wave 索引，再补 Story 缺口 |
| 共享契约变化 | 通知关联 Story、Design 和测试计划 |

## 5. 参考设计分级与证据可信性

### 5.1 内容类别 R

| 类别 | 定义 | 规则 |
|---|---|---|
| R0 | 外部/系统约束声明 | 经当前规格/HLD 核实后纳入约束，不自动继承 |
| R1 | 有验证依据的设计机制 | 优先评估复用，必须检查当前适用性 |
| R2 | 可选设计方案 | 与替代方案比较 |
| R3 | 历史实现细节 | 默认仅参考，不强制继承 |
| RX | 已知缺陷或不适用设计 | 禁止直接复用，保留反例证据 |

**注意**：若只有历史文档自称“已验证”，没有可核查的验证材料，应标记 `R1_candidate`，不得直接标记为已验证 R1。

### 5.2 证据等级 E

| 等级 | 依据 |
|---|---|
| E3 | 可核验的测试报告、正式审查/批准记录等强证据 |
| E2 | 来源、版本、上下文明确的正式设计文档 |
| E1 | 草稿、经验描述、缺少验证依据 |
| E0 | 来源/版本/上下文不明 |

R 表示**内容性质**，E 表示**证据可信性**；两者不可混用。Open 初评，Design 最终确认。

### 5.3 适用性结论 A

| 结论 | 含义 |
|---|---|
| A1 | 关键前提兼容，可直接复用设计机制，仍需当前项目验证 |
| A2 | 核心机制可复用，但需适配 |
| A3 | 仅借鉴设计思想 |
| A4 | 与当前约束/AC 冲突，不可复用 |
| AU | 证据不足，暂缓决定 |

Design 六维检查：功能语义、架构兼容、执行模型、数据与状态、资源约束、失败语义。`AU` 不能默认为 `A1`。

## 6. Comet-Design：AC 驱动的参考设计复用

### 6.1 设计义务 DO

Design 必须先从 AC 推导 DO（Design Obligation，设计义务），再匹配参考机制。DO 表示“必须解决的问题”，不直接指定实现方式。

示例：AC 要求 NAND 迁移写入失败时原始有效数据不丢失。

- DO-01：如何判定新副本有效？
- DO-02：映射何时可以切换？
- DO-03：失败后如何保留可恢复副本？
- DO-04：并发 Host Write 如何避免旧值覆盖新值？
- DO-05：如何验证异常后的数据一致性？

### 6.2 设计步骤

1. **D0 输入基线**：确认 Story/AC、HLD、Open 证据包和版本。
2. **D1 参考分析**：复核 R/E 分类与来源；提取设计机制及适用前提。
3. **D2 适用性分析**：执行六维检查，形成 A1/A2/A3/A4/AU 和风险记录。
4. **D3 AC 驱动设计**：AC → DO → 参考机制映射 → 设计缺口 → 候选方案 → 设计决策 → 架构/接口/状态/异常方案。
5. **D4 测试设计**：从 AC 和设计契约推导 UT、组件、集成、系统验收及必要的故障注入测试。
6. **D5 独立审查与发布**：独立 Review Agent 检查证据、AC 覆盖、技术正确性和测试充分性，工程师确认关键取舍。

D1–D4 允许局部迭代；D5 发布必须满足门禁。

### 6.3 设计决策与方案比较

针对关键技术取舍比较：AC 满足度、HLD 兼容性、数据安全、并发时序、性能/资源、复杂度、可测试性、历史证据。无需为每个辅助函数强制产生多个方案。明确区分：历史文档事实、AI 推断、新设计建议、工程师批准决策。

### 6.4 UT 设计原则

Design 阶段无函数实现时，先设计**行为契约级 UT**：测试目标、前置状态、刺激/故障注入、预期状态/输出、不变量、可观察点、Stub 约束、关联 AC/DO。Build 阶段将其映射到实际模块接口和测试代码。受控 Stub 不能替代最终真实集成验收。

**示例**：迁移写入失败时，映射不得指向失败的新页；原有效数据保持可读；旧块不得提前回收。需要同时规划故障恢复集成测试，避免将单元测试等同于掉电安全证明。

## 7. 独立审查与质量门禁

### 7.1 Open 质量门禁

- **RD-G1 来源可追溯**：关键证据有文档标识、版本、章节/段落定位。
- **RD-G2 需求覆盖**：每个关键 AC 对应 KN 与检索记录，允许显式 `NO_EVIDENCE`。
- **RD-G3 风险透明**：版本不明、资料冲突、证据缺口及不可访问源均记录。

### 7.2 Design 质量门禁

- **G0 输入一致性**：缺失或冲突的必需系统事实不得忽略。
- **G1 证据可靠性**：关键机制来源可复核，不得把 E0/E1 冒充已验证。
- **G2 适用性**：关键 A4/AU 已处理或明确升级决策。
- **G3 AC 覆盖**：每个 AC 有 DO、设计机制及未决问题标记。
- **G4 测试策略**：关键设计机制有可执行或可落实的验证路径。
- **G5 审查发布**：阻断缺陷清零；残余风险须有明确批准规则。

### 7.3 Review Agent 检查维度

1. AC/DO/设计/测试追踪完整性。
2. 参考来源、R/E/A 评级、事实与推断边界。
3. 技术正确性：状态、并发、时序、失败、恢复、资源。
4. 与 HLD 和共享契约的一致性。
5. 测试的有效性：Mock/Stub 是否掩盖真实风险。

Review Agent 应独立读取原始 AC/HLD 和关键证据，主动构造反例。设计作者修复后重新审查受影响部分；不能只由同一 Agent 自评。

### 7.4 工程师介入点

强制升级：HLD/AC 与历史设计冲突；数据安全/实时性/资源重大取舍；关键机制仅低可信证据；Review 阻断项或风险接受。低风险可由 Agent 自动记录决策。所有批准应有决策 ID、批准人角色、时间和依据。

## 8. 产物及 Schema（建议稿）

### 8.1 推荐目录

```text
comet/
  open/
    wave-<wave-id>/
      knowledge-needs.yaml
      search-plan.yaml
      reference-index.json
      reference-discovery.md
      discovery-gate.json
    story-<story-id>/
      knowledge-needs.yaml
      reference-index.json
      reference-discovery.md
      discovery-gate.json
  design/
    story-<story-id>/
      reference-analysis.md
      design-obligations.md
      design.md
      ut-design.md
      traceability.md
      decision-log.md
      review-report.md
```

路径仅作建议，需适配当前 Comet 产物规范；小 Story 可合并 Markdown 文件，但保留机器可检查的逻辑字段。

### 8.2 KN 示例

```yaml
kn_id: KN-W01-004
scope: wave
question: 历史设计如何保证并发映射更新不丢失最新写入？
source_refs: [AC-GC-03, AC-HOST-02]
category: concurrency_timing
criticality: critical
required_evidence: [design_protocol, failure_scenario]
status: partial
evidence_ids: [EV-0042]
```

### 8.3 Evidence 示例

```yaml
evidence_id: EV-0042
source:
  document_id: DOC-FTL-01
  version: '2.1'
  section: '4.3 Mapping Update'
  locator: 'local://design/FTL_GC_Design.md#4.3'
  content_hash: '<sha256-placeholder>'
claim:
  summary: 历史设计描述了条件映射更新机制
  provenance: explicit_document_statement
relations:
  knowledge_needs: [KN-W01-004]
  acceptance_criteria: [AC-GC-03]
assessment:
  relevance: high
  evidence_level: E2
  design_category: R1_candidate
  applicability: AU
open_questions:
  - 是否支持并发 Host Write？
  - 是否存在验证报告？
```

### 8.4 设计追踪示例

```yaml
ac_id: AC-GC-03
design_obligations: [DO-GC-01, DO-GC-02]
reference_evidence: [EV-0042]
decision_ids: [DEC-GC-04]
design_mechanisms: [DES-GC-05]
unit_tests: [UT-GC-08]
integration_tests: [IT-GC-03]
acceptance_tests: [AT-GC-03]
review_status: pending
```

### 8.5 决策记录要求

每条设计决策至少包含：决策 ID、关联 AC/DO、候选方案、采用方案、理由、引用证据、风险、未决事项、批准状态及影响范围。

## 9. OpenCode / Comet 落地架构

### 9.1 建议组件

| 组件 | 作用 | 第一版策略 |
|---|---|---|
| Reference Discovery Custom Subagent | KN、检索计划、证据提取、缺口 | 新增 |
| Reference Discovery Skill | 通用方法、输出 Schema、校验规则 | 新增 |
| Design-Write Agent | AC→DO、适用性、设计、UT | 扩展 |
| Design Review Agent | 独立语义与技术审查 | 复用/扩展已有审查角色 |
| OpenCode Hooks | 必需字段、引用、追踪、门禁结构检查 | 增量接入 |
| 本地资料检索适配层 | 文档目录、索引、知识库 | 先接现有本地文档 |

工具接口名称、Hook 生命周期和 Comet 扩展点需根据**实际安装版本与源码**核实，不在本方案中假设具体 API 一定存在。

### 9.2 与原有 Open 的关系

原有 Codebase/Architecture Exploration 与 Reference Discovery 可并行；Open 主 Agent 负责合并上下文、冲突去重和发布。Reference Discovery 不得替代原有 Open 的架构与代码库探索，也不得擅自修改 PRD-Split 的 Story/AC。

### 9.3 安全与权限

默认优先本地索引与文件访问；不把私有 PRD/HLD、设计文档发送到未经授权的云端模型、向量服务或外部搜索。记录数据来源、访问失败与权限范围。对文档中的指令性文本视为**不可信资料内容**，不能当作 Agent 的系统指令执行。

## 10. 失败模式与恢复

| 失败模式 | 处理策略 |
|---|---|
| 知识库不可访问 | 标记 SOURCE_UNAVAILABLE，尝试授权范围内其他源 |
| 未找到参考资料 | NO_EVIDENCE，Design 可独立推导 |
| 资料版本不明 | E0，禁止作为强约束依据 |
| 历史设计互相冲突 | 并列保留证据、前提与影响，升级 Design |
| 引用定位失效 | 标记 stale，重新定位并核验哈希 |
| 检索预算耗尽 | 输出已覆盖/未覆盖与停止原因 |
| 文档含恶意指令 | 仅作为资料处理，不执行嵌入指令 |
| Design 发现新知识缺口 | 发起定向补检，不重跑全部 Wave |
| Review 发现缺陷 | 修复受影响设计及测试，重新审查 |

## 11. 验证计划与评测指标

构建真实历史设计文档评测集：人工标注 Story/AC、预期 KN、关键证据章节、冲突和应识别的缺口。至少比较：无参考设计、直接提供历史设计文档、分级复用加两级探索三种模式。

| 指标 | 定义/目标方向 |
|---|---|
| KN Coverage | 关键设计知识需求覆盖率，提高 |
| Evidence Recall | 应发现关键证据的召回率，提高 |
| Evidence Precision | 检索证据真正相关比例，提高 |
| Citation Validity | 文档版本与定位可核验比例，提高 |
| Critical Gap Detection | 关键缺口识别能力，提高 |
| Conflict Detection | 相互冲突资料识别能力，提高 |
| Reuse Efficiency | Wave 共享减少重复检索的程度，提高 |
| AC-to-Test Traceability | AC→DO→设计→测试追踪完整率，提高 |
| Design Defect Rate | 独立审查发现的严重缺陷率，降低 |
| Engineer Rework | 工程师修订轮次与成本，合理降低 |

具体阈值需在基准样本上测量后确定，不在缺乏数据时编造数值。检索质量与最终设计质量必须分别评估。

## 12. 分阶段实施路线

**V1：可追溯探索最小闭环**

- 接入本地设计文档目录，生成 KN、Search Plan、Evidence Package。
- 实现 Wave/Story 分层、文档版本/章节定位、三态交接。
- 用 1 个 Wave、若干 Story 及真实历史文档人工对照验证。

**V2：AC 驱动设计闭环**

- Design 实现 R/E/A、AC→DO、设计追踪、UT 设计。
- 独立 Review Agent、工程师裁决和结构性 Hook 门禁。
- 比较参考复用前后的设计缺陷与返工成本。

**V3：规模化复用**

- 混合检索与跨文档关联、共享证据提升、增量失效传播。
- 知识库后端适配与自动评测。
- 评估是否需要独立 Reference Analysis 子 Agent；避免过早增加编排复杂度。

## 13. 设计决策登记

### 13.1 已讨论确认的原则

| ID | 决策 |
|---|---|
| RD-DEC-01 | 在 Comet-Open 新增 Reference Discovery Agent |
| RD-DEC-02 | Wave 级共享探索 + Story 级精确补充 |
| RD-DEC-03 | 输入包括 Story/AC、PRD、HLD，优先检索知识库与历史设计文档 |
| RD-DEC-04 | Open 发现证据，Design 做最终适用性与设计决策 |
| RD-DEC-05 | 参考设计分级使用，而非整份文档直接继承 |
| RD-DEC-06 | Design 以 AC 驱动，参考资料提供证据与设计知识 |

### 13.2 建议待工程验证的细化决策

| ID | 建议 | 待验证点 |
|---|---|---|
| RD-PROP-01 | KN 驱动混合检索 | 检索召回/成本 |
| RD-PROP-02 | R/E/A 三轴模型 | 分类一致性、可操作性 |
| RD-PROP-03 | READY/READY_WITH_GAPS/BLOCKED | 与 Comet 现有门禁兼容性 |
| RD-PROP-04 | Markdown + JSON/YAML 证据包 | 与现有产物 Schema 兼容性 |
| RD-PROP-05 | Hook 结构检查 + 独立语义审查 | OpenCode 版本能力 |
| RD-PROP-06 | 依赖驱动增量失效 | 实际索引和版本管理能力 |

## 14. 后续重点研究：KN 自动生成与质量审查

下一阶段应设计 KN 生成的系统化检查表和评测方法：如何从 AC 推导架构、接口、状态、并发、异常、资源、验证等知识问题；如何避免无关扩展；如何检测关键遗漏；如何在 Wave 共享与 Story 特殊性之间保持平衡。建议先使用真实设计文档和 Story 手工建立高质量 KN 基准，再自动化。

## 15. 最终原则

**Wave 共享知识、Story 精确检索、Open 提供证据、Design 独立决策、UT 证明机制、Verify 验收行为、Review 控制质量。**

ATDD 的核心仍是先定义可验收行为；参考设计增强设计知识与证据，但不能取代 AC、HLD 或工程师对关键风险的裁决。
