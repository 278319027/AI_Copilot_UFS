# 内网 SSD 语料 DDD 流水线：方案 A / 方案 B 详细设计与正式产物规范

**版本**：v1.0-draft
**日期**：2026-11-22
**状态**：设计提案（供 A/B 选型；两者均非已确认决策、均未实施）
**上位依据**：[实施设计 v1.0-draft](内网SSD语料构建DDD领域模型-实施设计-v1.0-draft.md)（流水线 0–5 阶段、四源权威分级、失败模式、验证实验均继承自该文档，本文不重复）
**对齐合同**：[Firmware DM × ATDD–Comet 集成详细设计](../Firmware_Domain_Model_ATDD_Comet_Integration_v1.0.md)（DEP 数据合同、状态机、增量失效）；[动态领域上下文落地方案](../new/domain-context/动态领域上下文落地方案.md)（知识地图、来源绑定、分批实施）
**范围**：只决定**阶段 4 产物的落地形态**（如何进入内网 Comet 流程）与两方案下的**正式产物格式和内容**。流水线本身（阶段 0–5 的分工与纪律）不在本文改动范围。

> 标注约定（沿用上位草案）：与既有合同一致的内容标「**继承**」；超出既有合同、需工程验证的内容标「**扩展**」；关于 SSD 领域本身的设计推断标「**推断**」。

---

## 0. 决策背景与共同前提

- **目的**：流水线产出的术语、上下文边界、不变量，用于内网 ATDD Comet 流程辅助固件代码生成。
- **语料获取层**：OpenViking（资源登记、语义检索、原文读取）。上位草案待决问题 #1（内网 AI 工具形态）已按此回答。
- **共同前提**：四源权威分级、按模块分批提取、缺陷反例驱动不变量、"LLM 提取聚类 / 人工裁决边界与不变量 / 机器校验一致性"的分工，两方案完全相同。
- **唯一分叉**：阶段 4 的交付形态——产物如何进入内网 Comet 流程被消费。
  - **方案 A**：对齐既有机制（知识地图短文档 + 版本化领域模型基线 + Wave 级 DEP + 受控导入）。
  - **方案 B**：独立静态目录 `.ssd-domain/`，由内网流程新开一条消费通道直接读取。

**决定两方案取舍的条件**：内网 OpenCode 上"知识地图 + 受控导入（来源绑定）"机制（落地方案批次 2/3）是否已部署可用。仓库记录（2026-11-02）显示批次 2 为"需目标环境部署与验证"、批次 3 为"远端导入需核实/适配"，**当前内网现状待用户确认**（见第 5 节新问题 #7）。

---

## 1. 方案 A：对齐知识地图 + DEP

### 1.1 架构总览

```
内网语料（OpenViking：设计 / 代码 / 测试 / 缺陷）
   ↓ 阶段0
知识地图短文档（资源根、版本锚点、权威等级、来源状态）
   ↓ 阶段1（LLM 四源并行提取，按模块分批）
术语提取结果（中间产物，带冲突标记）
   ↓ 阶段2（LLM 聚类 + 人工裁决边界与歧义）
SSD 领域模型基线（上下文划分 + 术语表，版本化 SSD-FTL-DM@n）
   ↓ 阶段3（缺陷/测试/设计/代码 → 反例驱动不变量 + 人工裁决）
模型基线规则集（INV-*）+ 条款候选
   ↓ 阶段4（DEP 组装：规则适用性 + 条款批准 + story 绑定）
Wave 级 DEP 包（DC / DCC / SDB）+ 受控导入快照登记
   ↓ 消费
内网 Comet 各阶段（PRD-Split DA → Open 参考发现 → Design 义务推导 → Build → Verify）
   ↺ 阶段5：一致性巡检（跨 DEP revision 比对，只出报告不进 DEP）
```

### 1.2 阶段到正式产物的映射

| 流水线阶段 | 中间产物 | 正式产物（A 形态） | 对齐的既有合同 |
|---|---|---|---|
| 阶段 0 语料盘点 | 语料清单 | **知识地图短文档** | 落地方案批次 2 知识地图：项目/仓库、允许资源根、各类资料位置、目标 commit/版本、同步信息与来源状态；短文档承载，不新增知识数据库 |
| 阶段 1 术语提取 | 四源术语提取结果（术语+定义+来源+位置+频次+冲突标记） | 中间产物，不单独交付，输入模型基线 | — |
| 阶段 2 上下文划分 + 歧义裁决 | 术语条目集（上下文归属+定义+已知多义+反例易混淆） | **SSD 领域模型基线**（上下文划分 + 术语表 + 规则集，版本化 `SSD-FTL-DM@n`） | 集成设计 `input_baselines.domain_model` 基线位置（扩展，见 1.3-②） |
| 阶段 3 不变量提炼 | 不变量候选 + 反例场景 + 验证方式 | 模型基线规则集 `INV-*`（含 preconditions / source_refs / status）→ 被 DEP 的 DC 条目引用 | 集成设计 §3 模型规则字段：`id / revision / statement / preconditions / applicability / source_refs / status / owner / validation_hints` |
| 阶段 4 交付 | — | **Wave 级 DEP 包**（DC / DCC / SDB）+ **受控导入登记** | 集成设计 §5 DEP 数据合同；落地方案批次 3 来源绑定 |
| 阶段 5 一致性巡检 | 分歧报告（术语偏离/文档漂移/未验证不变量） | 无正式产物：只出报告，不自动修改、不进 DEP | 实施设计草案阶段 5 纪律 |

### 1.3 正式产物及其格式

#### ① 知识地图（短文档）【继承】

载体：一份 markdown 短文档（复用落地方案"使用已有配置或短文档承载即可，不新增知识数据库"）。必填字段：

| 字段 | 内容 |
|---|---|
| 项目/仓库 | SSD 固件主控项目标识 |
| 允许资源根（OpenViking URI） | 设计根 / 代码根 / 测试根 / 缺陷根，逐条列出 |
| 各类资料位置 | 每类来源在资源根下的具体位置（如 GC 模块代码、HLD 文档目录） |
| 版本锚点 | 目标 commit（代码）+ 文档版本（HLD/PRD 版本）；同一分析固定单一版本 |
| 同步信息与来源状态 | 索引同步时间/滞后情况；每类来源的权威等级（批准规范 / 草案 / 代码事实 / 历史证据）与当前状态 |

示例：

```markdown
# SSD FTL 语料知识地图
- 项目/仓库：ssd-ftl（固件主控）
- 允许资源根：
  - viking://resources/ssd/design/   # 设计文档（HLD/详细设计）
  - viking://resources/ssd/ftl/      # 源代码
  - viking://resources/ssd/tests/    # 测试（UT/IT/仿真）
  - viking://resources/ssd/defects/  # 缺陷与现场日志
- 资料位置：HLD 在 design/hld/；GC 模块代码在 ftl/gc/；缺陷库在 defects/bugs/
- 版本锚点：代码 commit <sha>；HLD 版本 HLD-FTL@4
- 同步信息：OpenViking 索引同步于 <时间>；design 为批准规范，ftl 为代码事实，
  defects 为历史证据；tests 覆盖范围见 tests/coverage-notes.md
```

#### ② SSD 领域模型基线（版本化）【扩展】

既有合同没有"领域模型基线"的独立版本化形态（`SSD-FTL-DM@1` 在集成设计示例中只作为 `input_baselines` 的一个引用出现），其版本化与文件载体是本设计的**扩展**，需经工程验证。文件格式可沿用实施设计草案阶段 4 的目录布局作为载体：

```
ssd-ftl-dm/                 # 领域模型基线的文件载体（SSD-FTL-DM@n）
  vision.md                 # 高层：整体目的、模块关系、上下文索引
  contexts/
    mapping.md              # 上下文：映射与地址语义
    gc.md                   # 上下文：GC 与空间回收
    recovery.md             # 上下文：掉电恢复与日志
    nand.md                 # 上下文：NAND 介质与坏块
    ...
  invariants/
    <context>.md            # 各上下文不变量（INV-*）+ 反例
  glossary.md               # 全局术语索引（指向各上下文，不放全文）
```

该载体与草案的 `.ssd-domain/` 的区别在于四条硬要求（草案没有的）：

1. **版本化登记**：整个目录作为一个基线版本 `SSD-FTL-DM@n`，带 `content_digest`；修订必须生成新 revision，旧版保留可还原。
2. **source_refs 闭合**：每个术语条目、每条不变量的 `source_refs` 必须指向受控导入登记的快照 URI（见 ④），引用必须闭合——所有来源批准缺失时登记待决，不伪造绑定。
3. **权威等级与状态字段**：每个条目带权威等级（批准规范/草案/代码事实/历史证据）与状态（候选/已批准）；候选条目不得被下游当作已批准义务。
4. **适用边界显式化**：每条规则显式标注适用范围（NAND 类型/掉电保证/配置），"主控无关不是无条件适用于所有项目"。

术语条目模板（阶段 2 输出，直接来自实施设计草案，字段即基线字段）：

```markdown
## <术语名>
- **上下文**：<所属限界上下文>
- **定义**：<在该上下文内唯一、严谨的含义>
- **权威来源**：<类型> <位置/OpenViking URI> <版本> <状态>
- **已知多义**：在其他上下文中的不同含义 + 映射关系
- **反例/易混淆**：<最常被误解成什么>
- **source_refs**：<受控导入快照 URI 列表，必须闭合>
```

不变量条目模板（阶段 3 输出，字段对齐集成设计模型规则要求）：

```markdown
## INV-<CONTEXT>-<NNN>
- **statement**：<不变量陈述>
- **上下文**：<所属限界上下文>
- **适用前提**：<NAND 类型/掉电保证/配置等前提；缺前提不得省略，写 UNKNOWN>
- **违反时的可观察后果**：<现象>
- **反例**：<来源缺陷编号/测试用例 + 快照 URI>
- **验证方式**：<Oracle 或断言，对应 validation_hints>
- **权威来源与状态**：<来源类型> <快照 URI> <候选/已批准>
```

#### ③ Wave 级 DEP 包【继承 Schema，SSD 填充为示例】

直接复用集成设计 §5.1 最小逻辑 Schema 与 §5.2 状态机，不新增字段；下例展示 SSD GC 场景的填充形态（`counterexample` 与 `preconditions` 的显式写出是 §3 模型规则字段要求在本场景的体现，非新 Schema 字段）：

```yaml
schema_version: "1.1"
package:
  id: DEP-WAVE-GC-SSD-001
  revision: 1
  lifecycle_status: draft          # DRAFT → SEALED → SUPERSEDED → ARCHIVED
  wave_id: WAVE-GC-SSD-001
  content_digest: "sha256:<待计算>"
  input_baselines:
    prd: PRD-SSD-001@1
    hld: HLD-FTL@4
    domain_model: SSD-FTL-DM@1     # ② 的基线版本
context_entries:
  - id: DC-GC-001
    revision: 1
    domain_rule_ref: INV-GC-001@1  # 指向 ② 基线中的不变量
    applicability:
      status: applicable           # APPLICABLE / CONDITIONAL / NOT_APPLICABLE / UNKNOWN / CONFLICTED
      scope: [STORY-GC-001]
      rationale: "有效数据迁移场景适用（任意 NAND 类型）"
    knowledge_status: verified     # UNVERIFIED / PARTIALLY_VERIFIED / VERIFIED
    evidence_refs: [EVD-DEFECT-001, EVD-TEST-001]
contract_clauses:
  - id: DCC-GC-001
    revision: 1
    type: invariant_obligation
    statement: "GC 迁移不得丢失数据保留合同覆盖的有效数据"
    scope:
      wave_id: WAVE-GC-SSD-001
      story_ids: [STORY-GC-001]
    source_context_refs: [DC-GC-001@1]
    acceptance_relation:
      type: supports_existing_ac   # SUPPORTS_EXISTING_AC / SHARED_CONSTRAINT / REQUIRES_AC_CHANGE / DESIGN_ONLY_CONSTRAINT
      ac_refs: [AC-GC-001@1]
    design_obligations: [preserve_valid_data]
    verification_obligations: [data_readback, power_fail_injection]
    risk: { inherent_level: high }
    preconditions:                 # 继承自模型规则字段，SSD 场景显式写出
      - "数据保留合同在相关 LBA 范围内有效"
    counterexample:                # 继承自模型规则的 source_refs，反例场景具名
      source: EVD-DEFECT-001       # BUG-2024-017：GC 期间掉电导致迁移数据丢失
story_bindings:
  - id: SDB-GC-001
    revision: 1
    story_ref: STORY-GC-001@1
    package_ref: DEP-WAVE-GC-SSD-001@1
    applicable_clauses: [DCC-GC-001@1]
    excluded_context: []
    open_issues: []
```

状态机（继承，不重述）：Package `DRAFT→SEALED→SUPERSEDED→ARCHIVED`；Clause `PROPOSED→IN_REVIEW→APPROVED/REWORK_REQUIRED/REJECTED`（批准版本可 `SUPERSEDED/REVOKED`）；Binding `DRAFT→READY_FOR_REVIEW→ACCEPTED/REWORK_REQUIRED`。包级 SEALED 只表示内容固定，不代表条款批准或 Story Ready。**条款候选在人工批准前不是义务**——这是阶段 3 产物进入流程的唯一合法路径。

#### ④ 受控导入登记【继承】

复用落地方案批次 3 的来源绑定：被引用的原文（设计章节、缺陷记录、测试断言）通过受控导入固定为可还原快照。登记字段：

| 字段 | 内容 |
|---|---|
| source_id | 快照标识（如 EVD-DEFECT-001） |
| 来源 URI | OpenViking 资源 URI |
| 快照 digest | 内容哈希，可复核 |
| 导入时间与任务/Wave 关联 | 何时、为哪个 Wave/Story 导入 |
| 可还原性 | 源内容变化后旧依据仍可还原，新旧不混用 |

纪律（继承）：远端 URI 不能直接当本地路径用，必须经受控导入/映射后再登记；运行中发现新关键来源时创建含新增来源的新 run，保留前 run，不修改旧快照。

#### ⑤ 人工裁决工作区（工作区，非交付物）

草案的 `.ssd-domain/` 布局在此方案中**降级**为阶段 2/3 的人工裁决工作区：LLM 产出先落这里，裁决人（边界裁决 + 不变量裁决，全流程唯一不可外包环节）在此逐条裁决，裁决结果才进入 ② 基线（新 revision）和 ③ DEP（条款候选→批准）。工作区文件本身无权威、不直接被流程消费。

### 1.4 内网 Comet 各阶段的消费方式

对齐集成设计 §4 的职责边界表，标注本流水线每阶段的贡献：

| 内网 Comet 阶段 | 领域输入 | 本流水线的贡献 | 不越过的边界 |
|---|---|---|---|
| PRD-Split（Domain Analysis） | PRD、HLD、模型基线、知识地图 | DA-0 Knowledge Need：按任务从基线查所需术语与规则；DA-1 Applicability：选取适用上下文条目，排除与条件显式化 | 不自动批准新增 AC |
| Open（Reference Discovery） | 冻结 Story/AC、DEP 引用 | source_refs → OpenViking 拉原文（历史缺陷、参考实现）；初评适用性 | 不最终批准历史方案适用性 |
| Design | AC、已批准 DCC 条款、参考证据 | 条款 → 设计义务推导；不变量的 verification_obligations 落到 UT/IT/AT 设计 | 不改冻结需求 |
| Build | 批准设计、UT Design | 按义务写码与 UT | 不自行改变 Clause/Design |
| Verify | AC、已批准条款、测试义务 | 不变量反例 → 独立核验（从原始 AC 构造反例，缺证据不接受） | 不以代码存在替代验收 |

Agent 按**当前任务的上下文归属**消费该任务绑定的那份上下文（DC 适用条目 + 已批准条款 + 快照原文），而非全库语料——这是实施设计草案阶段 4 "align bounded contexts with the context window" 在既有机制内的落法。

### 1.5 版本化、增量失效与审计【继承】

- **Handoff Manifest**（继承 §11）：来源/目标阶段、Change Unit/Wave/Story、DEP ID@revision/digest、Binding ID@revision、有效 Clause 集合（Runtime 计算，不信任 Agent 手填）、PRD/HLD/AC 精确基线、Review/Gate 引用、Open Issues。
- **增量失效**（继承 §11）：Wave DEP 更新产生新不可变 revision，经 Rule→Clause→Binding→AC→Design→Test 依赖图定位候选影响对象，语义审查判定 `NO_IMPACT / REVALIDATION_REQUIRED / DESIGN_REWORK_REQUIRED / REQUIREMENT_CHANGE_REQUIRED / BLOCKED`；只重评实际受影响的 Story；旧 Gate/测试证据绑定旧版本，不自动沿用。
- **审计**（继承 §5.2）：审批/Review/Gate 记录追加存储，不作为被审内容哈希的一部分；`effective_status` 由 Runtime 计算。
- **引用闭合纪律**：所有 source_refs 和 scope 引用必须闭合；正式来源批准缺失时登记待决即可研究，真正业务未决到对应 stage 阻断相关 ready 但保留候选分析。

### 1.6 前置条件与成本

**前置条件**（不满足则 A 落不了地）：
1. 内网 OpenCode 完成落地方案批次 2（只读检索/读取/精确定位能力注册、Owner/Reviewer 权限配置、资源根与基线映射）与批次 3（受控导入/快照能力）。仓库记录显示两者截至 2026-11-02 均为待部署/待核实，**现状待确认**。
2. 集成设计 §14 的工程验证完成：最小逻辑 Schema → 完整 JSON Schema 与语义校验规则、状态转换表与错误码测试。

**成本**：
- 阶段 1–3 产出格式需按 1.2 映射表对齐基线字段与 DEP Schema（一次性格式设计成本）。
- 裁决人需要能读 DEP 条目与条款（对裁决人的理解成本高于 B 的纯 markdown）。
- 每个 Wave 的 DEP 组装需要 Runtime 支持（版本、CAS、Gate），不能由 Agent 手填。

---

## 2. 方案 B：独立 `.ssd-domain/` 静态树

### 2.1 架构总览

```
内网语料（OpenViking）
   ↓ 阶段0–3（与方案 A 完全相同）
术语条目集 + 上下文划分 + 不变量条目（人工裁决后）
   ↓ 阶段4
生成静态目录 .ssd-domain/（vision + contexts + invariants + glossary）
  + manifest.md（语料版本锚点 + 生成信息）
   ↓ 消费（新通道）
内网 Comet 新增消费入口（新 Skill / 阶段入口）：
  按任务上下文归属读取对应 contexts/*.md + invariants/*.md，
  对照 manifest.md 核验语料版本（约定级）
   ↺ 阶段5：一致性巡检（同样只出报告）
```

阶段 0–3 的提取、裁决、纪律与 A 完全一致；差异全部集中在阶段 4 的交付形态与消费通道。

### 2.2 目录结构与文件格式

```
.ssd-domain/
  manifest.md               # B 新增：版本锚点与生成信息（A 由基线 digest 承担）
  vision.md                 # 高层：整体目的、模块关系、上下文索引
  contexts/
    mapping.md              # 上下文：映射与地址语义
    gc.md                   # 上下文：GC 与空间回收
    recovery.md             # 上下文：掉电恢复与日志
    nand.md                 # 上下文：NAND 介质与坏块
    ...
  invariants/
    <context>.md            # 各上下文不变量 + 反例
  glossary.md               # 全局术语索引（指向各上下文，不放全文）
```

**manifest.md**（B 必须新增的版本锚点文件）：

```markdown
# SSD 领域上下文清单
- 生成时间：<时间>
- 语料版本锚点：代码 commit <sha>；文档版本 HLD-FTL@4
- 提取范围：<OpenViking URI 列表，逐条>
- 流水线版本：ssd-ddd-pipeline@<版本>
- 内容摘要：sha256:<对全部生成文件计算的摘要>
- 已裁决条目数 / 候选未裁决条目数：<n> / <m>
```

**vision.md**：整体目的（一段）、模块关系（文字图或简表）、上下文索引表（上下文名 → 文件 → 一句话边界）。少量，不放全文。

**contexts/<context>.md**：上下文概述 + 边界描述（该上下文负责什么、不负责什么、与相邻上下文的关系/映射）+ 术语条目集。术语条目模板与 A 的 ② 相同（草案阶段 2 输出形态，字段：上下文/定义/权威来源/已知多义/反例易混淆）。B 的差别：**没有 source_refs 闭合要求**，来源在"权威来源"字段里以文字记录（类型 + 位置 + 版本），无快照、无 digest、更新后不可还原。

**invariants/<context>.md**：不变量条目模板与 A 的 ② 相同（statement/上下文/适用前提/违反后果/反例/验证方式）。B 的差别：**没有状态字段**，候选与已批准的区分靠章节标题或人工约定，无 Gate 检查。

**glossary.md**：术语 → 所属上下文 + 文件锚点的索引表，不放定义全文。

**消费入口行为**（新 Skill，示意）：
1. 按当前任务的上下文归属确定要加载的 contexts/*.md 与 invariants/*.md；
2. 读 manifest.md，把语料版本锚点与任务固定的目标版本对照，不一致则提示（约定级检查，非机制强制）;
3. 只加载对应文件，不加载全库。

### 2.3 B 必须自补的机制（与 A 的差距表）

A 免费继承、B 必须自建且只能做到约定级的部分：

| 关切点 | A 形态 | B 形态 |
|---|---|---|
| 版本控制 | DEP revision + digest + 状态机 + Runtime CAS | manifest.md 约定；无 revision 状态机，无 CAS，重生成即覆盖 |
| 来源可追溯 | source_refs → 受控导入快照，源更新后旧依据可还原 | 文件内文字记录来源；语料更新后无法还原旧依据 |
| 权威设防 | DC/DCC status 字段 + Gate 机械检查 | 权威等级写进文件头靠自觉；"草案被当批准规范"无设防 |
| 裁决回流 | DCC 条款批准流（PROPOSED→IN_REVIEW→APPROVED）+ 审批记录追加存储 | markdown 评审，结论如何回流到流程无合同 |
| 失效检测 | Rule→Clause→Binding→AC→Design→Test 依赖图 + 语义审查 | 无；仅靠阶段 5 巡检报告人工跟进 |
| 消费入口 | 既有（知识地图 + DEP + OpenViking） | 新 Skill / 阶段入口接线，属机制外通道 |
| 引用闭合 | 机制强制（UNRESOLVED_REFERENCE 错误码） | 无检查 |

### 2.4 成本与风险

1. **新通道**：内网 Comet 要加一条知识地图 + DEP 之外的消费入口，与既有"Comet 继续是唯一流程状态权威"并存时需要额外约定两者冲突时的优先级。
2. **版本债**：语料更新后 .ssd-domain/ 是否失效、谁发现、谁重生成，全靠约定；每个消费它的任务都在用"可能过期"的上下文。
3. **双通道维护**：若 A 机制后续部署，要么整体迁移（付一次迁移成本），要么双轨长期存在——后者正是实施设计草案第 4 节自列的失败模式"元工作替代工程"：产出大量建模文档但主线流程没人用。
4. **决策冲突**：B 作为正式交付形态与落地方案"不新增知识数据库"的明确方向相反；若 B 转正，需要修订该决策并说明理由。

**B 的独有收益**（对照 2.3，诚实列出）：
- 启动快：阶段 0–3 完成后直接写文件，第一周即可产出可用术语表与上下文文档，不等 DEP Schema 工程化。
- 人类可读：vision + contexts 目录对裁决人、评审人直观，全景一眼可见。
- 无通道锁定：非 Comet 的内网工具也能直接读。

---

## 3. 对比与推荐

### 3.1 八维对比（汇总）

| 维度 | A：知识地图 + DEP | B：独立 .ssd-domain/ 树 |
|---|---|---|
| 接入成本 | 零新接线，产出直接进既有消费路径 | 新开消费通道（新 Skill / 入口接线） |
| 版本/来源可靠性 | revision + digest + 快照还原，机制保证 | manifest 约定，无快照，不可还原 |
| 权威分级设防 | status 字段 + Gate 机械检查 | 文件头约定，无检查 |
| 人工裁决落点 | DCC 条款批准流，裁决有正式落点 | markdown 评审，回流无合同 |
| 人类可读性 | 弱（面向机器的包结构） | 强（目录文件一目了然） |
| 通道锁定 | 产物只在 Comet 流程内消费 | 任何工具可读，无锁定 |
| 试点启动速度 | 慢（需 DEP Schema 工程化 + 机制部署） | 快（第一周产出可用文档） |
| 长期维护 | 一条主线，符合既有决策 | 双通道风险，与"不新增知识数据库"决策冲突 |

### 3.2 核心权衡

**B 买的是启动速度，A 买的是消费可靠性。** 目标是辅助固件代码生成时，瓶颈不是"产出一张术语表"，而是"Agent 每次消费到的是正确版本、来源闭合、权威正确的上下文"。这一侧的收益是复利的：A 下每个后续代码生成任务消费同一套有保障的上下文；B 下版本与来源的债每跑一次任务付一次利息。

### 3.3 决策条件与推荐路径

**条件**：内网 OpenCode 上知识地图 + 受控导入（来源绑定）是否已部署可用（见第 5 节问题 #7）。

- **已部署** → **纯 A**。B 只剩纯额外成本，无收益成立的理由。
- **未部署** → **A 为目标形态，B 形态作试点期过渡载体**（混合形态）：
  - 试点 P0/P1 的产出用 B 形态的 markdown 文件（启动快、可读性好）；
  - **但文件字段按 A 的映射要求写**（1.2 映射表）：术语条目字段对齐 ② 基线字段（含 source_refs 占位与权威等级/状态字段），不变量字段对齐 DCC 字段（含 preconditions、反例、验证方式）；
  - 这样机制部署后的迁移是**机械格式转换 + 登记**（受控导入 + 基线版本化 + DEP 组装），不是重写；
  - 过渡期产出的 manifest.md 在迁移后并入基线 digest，知识地图短文档从 manifest 字段直接生成。

**推荐**：无论内网现状如何，实施设计文档的目标形态按 A 写；试点执行单按内网现状决定是否加过渡载体。这是本提案的立场，供用户裁决。

---

## 4. 试点执行单（两方案共同部分 + 差异标注）

**P0：选一个子系统走完阶段 0–2**（推断：建议 GC 或映射，边界清晰、缺陷历史通常丰富；待用户确认，见问题 #5）

| 任务 | 内容 | 交付物（A 形态 / B 形态） |
|---|---|---|
| 0.1 语料盘点 | OpenViking 资源登记核对 + 知识地图 | 知识地图短文档 / manifest.md |
| 0.2 术语提取 | 四源并行提取（OpenViking search/read），强制按模块分批，提示一组化 | 术语提取结果（带冲突标记，中间产物） |
| 0.3 上下文划分 + 歧义裁决 | LLM 聚类建议 → 人工裁决边界与每条冲突（真多义/不一致缺陷/命名错误） | 1 份上下文文档 + 术语表（DC 条目集入基线 / contexts/*.md）+ 裁决记录 |

**P1：阶段 4 首版交付 + 真实任务对照**

- A：首版 Wave DEP（DC/DCC/SDB）+ 受控导入登记；条款走批准流。
- B（或混合形态过渡期）：完整 .ssd-domain/ + 消费入口；字段按 A 映射要求写。
- 对照实验 E1（继承实施设计草案第 6 节）：同一真实固件任务，Agent 有无上下文包各跑一次；观测量：术语误用次数、跨模块误改、人工返工量、成本（token + 人工修正时间）。

**完成标志**：一个子系统的模型基线（A）或可消费上下文包（B）+ 第一批经人工裁决的条款（A）+ 一轮 E1 对照记录。达到即闭环，不提前铺满整个 SSD 领域。

---

## 5. 待决问题（继承实施设计草案第 7 节，已更新）

| # | 问题 | 状态 |
|---|---|---|
| 1 | 内网 AI 工具的具体形态 | **已答：OpenViking**（资源登记/检索/原文读取） |
| 2 | 语料规模数量级 | **已收窄**：资料丰富，按模块分批提取的策略已定；精确文件数盘点在任务 0.1 完成 |
| 3 | 缺陷历史是否可获取 | **待确认**：是阶段 3 最高价值来源；不可得则不变量只能靠设计文档+测试，P2 收益显著下降 |
| 4 | 是否有既有术语表/glossary 可复用 | 待盘点（任务 0.1 附带核对） |
| 5 | 第一个试点子系统选哪个 | **待确认**（推断建议 GC 或映射） |
| 6 | 谁担任"边界与不变量裁决"的工程师角色 | **待确认**（全流程唯一不可外包环节） |
| 7 | （新增）内网知识地图 + 受控导入现状 | **待确认**：决定纯 A 还是 A 目标 + B 过渡（3.3） |

---

## 附：关键依据

- [内网 SSD 语料构建 DDD 领域模型——实施设计 v1.0-draft](内网SSD语料构建DDD领域模型-实施设计-v1.0-draft.md)（流水线、四源权威分级、失败模式、验证实验的上位依据）
- [Firmware Domain Model × ATDD–Comet 集成详细设计](../Firmware_Domain_Model_ATDD_Comet_Integration_v1.0.md)（DEP 数据合同 §5、状态机 §5.2、跨阶段交接与增量失效 §11、模型规则字段 §3）
- [动态领域上下文落地方案](../new/domain-context/动态领域上下文落地方案.md)（知识地图与来源绑定、批次 2/3 状态、"不新增知识数据库"决策）
- 外部一手资料（Evans 2024/2025/2026、Brandolini 2026、arXiv:2603.26244）沿用实施设计草案附录，不重复列出。
