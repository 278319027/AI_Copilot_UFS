# ATDD-Comet 讨论总结

**日期：** 2026-11-11　**状态：** 讨论纪要（不是已批准决策或运行规范）
**范围：** 本仓库 ATDD-Comet + PRD-Split 流程设计、Data GC 开发方式、AC 质量与辅助编程效果
**依据：** 仓库现有设计与运行工件（见文末索引）；其中 `09-Wave-Change-Mapping.md` 仍为 PROPOSAL，未实现。

---

## 0. 一页速查（TL;DR）

1. **ATDD 的价值不在流程完备，而在三个机制**：可判定且可证伪的 AC、独立于实现的 Oracle、绑定真实版本的证据；再配独立 Verify 与风险分级。
2. **当前流程的问题不是 ATDD 本身，而是装配过重**：Comet Classic + OpenSpec + Superpowers + PRD-Split STUDY + ATDD overlay 多套定义叠加，固定成本按 Story 数量线性增长。
3. **Change 的正确粒度是“可独立交付、独立签收、独立回滚的语义原子变更”**；默认 `Change = Wave 或 Wave 内的交付批次`，Story 是 Change 内部的验收分区；需要独立交付/审批/风险隔离/并行时才让 Story 成为 Change。
4. **一次 Change 每个阶段只有一次状态流转、一条 Build/Verify receipt**；Story 级证据放在工件与报告中，不放到 Comet 状态里。
5. **用了很久辅助编程仍写不出可控代码，根因是“元工作替代工程工作”**：没有可运行产品与快速反馈回路，流程再完整也无法产生质量。
6. **PRD+HLD 是 PRD-Split 的正确输入形态，但必须补齐 AB、manifest 与领域来源，并区分权威**：PRD 给需求、HLD 给约束、AB 未生效时不得进入规范分母、领域候选只能是 OBSERVATION。
7. **AC 必须独立于“解法设计”，但不能独立于“约束与观察边界”**：可观察接口由设计/架构提供，AC 绑定它，而不是绑定实现。
8. **AC 完整性靠“义务覆盖矩阵 + GC 场景矩阵 + 独立 Reviewer 重建”**；AC 正确性靠“来源忠实 + 权威签收 + 反例/Oracle + 实现无关 + 一致性 + 独立审阅”，并可用变异测试检验 AC 本身。
9. **Data GC 的 AC 主来源是 PRD 的 `FR-007/008/009/010/011/013/017/018/020/021` 与 `AC-008/009/010`**；HLD 的 `EXE-001/FLOW-002/FLOW-003/IF-004/IF-005/PERSIST-001` 与 `INV-*` 提供约束与场景。
10. **正确顺序是“先产品、后流程”**：先做出 DATA GC 的可运行垂直切片，再用最小流程约束它；用指标决定加多少流程。

---

## 1. ATDD 做得好不好，取决于什么

**判断标准不是流程文档数量，而是三件事：**

1. **AC 可判定、可证伪**：能写出让它失败的反例；模糊词换成阈值/判据。
2. **Oracle 独立于实现**：不拿被测实现算期望值；reference model、不变量、性质/变换关系、golden 数据。
3. **证据绑定真实版本**：命令、代码/环境版本、原始输出、适用限制；模型自述不算证据。

配套两个机制：**独立 Verify**（验证者 ≠ 构建者）与**风险分级 L1–L3**（只有 L3 才展开完整证据链）。

> 一句话：ATDD 的核心不是“先写测试”，而是“先对齐可观察行为与判定方式”。

---

## 2. 流程复杂度：问题不在 ATDD，在装配

当前仓库同时存在多套流程定义：

| 层 | 存在的东西 | 性质 |
|---|---|---|
| 阶段状态 | Comet Classic（Open→Design→Build→Verify→Archive）+ Guard/Wait | 必要，但必须唯一 |
| 需求 | PRD-Split STUDY（I3→D1–D4→Review→finish）→ 再经 Classic Open 确认 | 两次确认，重复 |
| 工件 | OpenSpec change + `docs/atdd` 四份 schema + templates + manifest | 大部分可按风险裁剪 |
| 执行 | Superpowers plan/report + `.worktrees/` + skills-lock + memory | 可选 |
| 校验 | ATDD validator + Rule + Runtime guard | 附加，应分级 |
| 报告 | ATDD JSON + Comet Markdown + Superpowers report | 三份说同一件事 |

**结论：** 单看每层合理，叠加后一个 Story 要过十几道卡、写三份报告、签两次确认。复杂度来源是**重复的流程定义与过细的粒度**，不是 ATDD 方法本身。

**简化方向：**
- 需求确认只做一次（STUDY 输出即 baseline candidate，Classic Open 一次确认）；
- 中间阶段（Open/Design）校验降级为警告，Verify/Archive 保持强制；
- 一个 Change 只留一份机器可读报告，人读版由它派生；
- L1/L2 走轻路径，L3 才重流程。

---

## 3. Change 粒度：什么应该对应一个 Change

### 3.1 定义

> **一个 Change = 一次可以独立交付、独立签收、独立回滚的语义原子变更。**

Comet Classic 的 Change 本来是**交付单位**，Story 是**验收单位**，两者不是同一维度。

### 3.2 决策规则

| 判据 | 问题 | 结论 |
|---|---|---|
| **Q1 原子性** | 拆开后出现不一致中间态，或 spec delta 无法单独成立？ | **禁止拆** |
| **Q2 交付性** | 需要独立发布/上线/回滚？ | 该部分独立 Change |
| **Q3 审批性** | 需要独立批准人/签收/审计轨迹？ | 独立 Change |
| **Q4 风险隔离** | 高风险项失败会污染其余部分？ | 独立 Change |
| **Q5 并行性** | 不同人/Agent 并行且共享状态互相阻塞？ | 独立 Change |
| **Q6 可审查性** | 超过一次评审规模（>7 Story / >10 task / proposal >2 页）？ | 拆 |

默认：`Change = Wave`；Wave 需要分批交付时，`Change = 交付批次`。
Story 默认是 Change 内的验收与证据单元；满足 Q2–Q5 之一才提升为独立 Change。

### 3.3 Story=Change 的成本（为什么过重）

一次 Story Change 的固定成本约：
- 4 份 OpenSpec 工件 + Open 逐字节快照集；
- ≥3 份 ATDD JSON（manifest、verify-report、acceptance）；
- 1 条 Build receipt + 1 条 Verify receipt + Comet Markdown 报告；
- 2 次用户 Wait（Open、Archive）；
- ≥5 个 Agent 回合。

5 Story 的 Wave ≈ 60–75 个文件、10 次确认、15 次 check run，其中大量内容重复。

### 3.4 必须回退 `Story=Change` 的条件

1. 逐 Story 独立归档/回滚/发布；
2. 逐 Story 独立 approval Wait 或独立审计；
3. 验证环境/周期差异过大（如需要故障注入环境）；
4. 无法在一条固定 Verify 命令内一起运行；
5. 多 Agent 并行且状态互不阻塞；
6. 预计 Story >7 或 task >10。

---

## 4. Wave=Change 时，Story 如何进入 Comet 流程

Comet 不认识 Story；映射由 Change 工件与 ATDD Runtime 共同承担。

### 4.1 六类载体

| 载体 | Story 的体现 |
|---|---|
| Baseline JSON（Wave 级） | `stories[]`，每 Story 带 AC、source、oracle |
| `proposal.md` | “What Changes”列出本批 Story 与范围、非范围 |
| `specs/<capability>/spec.md` | Requirement/Scenario 标注归属 Story（如 `[S1]`） |
| `design.md` | 每 Story 一节；Design Item 用 Story 前缀（`S1-D1`） |
| `tasks.md` | 每 Story 一组任务，带 Comet `comet-task` ID |
| `atdd/change.json` + `atdd/stories/<S>/manifest.json` | Change 级共享绑定 + Story 级 AC/设计/证据/验收映射 |

### 4.2 五阶段（每阶段一次流转、一条 receipt）

| 阶段 | 多 Story 处理 | Gate 重点 |
|---|---|---|
| **Open** | proposal 列全 Story；spec delta 写全；tasks 按 Story 分组；`ATDD_BASELINE` 标记；一次 `full.open.confirm` | baseline FROZEN、Story 集合一致、来源/Oracle 可解析 |
| **Design** | 一份 design.md 按 Story 分节；每 AC 有 Design Item + 验证意图；一次确认 | 每 AC 覆盖、共享输入 digest、未决项处置 |
| **Build** | 按 Story 执行 tasks；全部完成 `complete-build`；一条固定 Build check 覆盖全部 AC | 任务全完成、每 Story 实现引用、证据绑定 |
| **Verify** | 独立 verifier；一条固定 Verify 命令跑整批；每 Story 一份 JSON 报告 | 每 AC 结论、verifier ≠ build owner、receipt 有效 |
| **Archive** | 每 Story 一份 acceptance，共同引用一次 Archive Wait | 全部 Story 已接受、报告 digest 一致 |

### 4.3 Comet 的三个硬约束

1. **每阶段只有一个 receipt**：Build/Verify 各一条 check，Story 级证据是 receipt 内子结果 + JSON 报告。
2. **任务粒度**由 `state tasks / task-complete` 承担，Story → 任务组。
3. **验收只有一个 `full.archive.confirm` Wait**：可逐 Story 记录 acceptance，但不能逐 Story 独立归档。

### 4.4 工件/Schema 增量（v2）

- 新增 `atdd/change.json`：baseline、Open 快照、shared inputs、check plans、evidence、stories 索引、archive inventory；
- Story manifest v2：只保留 Story 专属字段（AC、design_items、implementation_refs、evidence_refs、verify_report、acceptance_decision）；
- validate 从“单 Story”改为“聚合”：Story 集合相等、AC 全局唯一且全覆盖、共享 receipt 一致；
- `ATDD_ACCEPTANCE` 标记改为多 Story 列表；
- v1（单 Story）保持兼容。

### 4.5 失败与部分交付

- Build 内某 Story 失败：只修该 Story，重跑 Build check；
- Verify 某 Story 失败：`verify-fail` 回 Build，修复后重跑 Build + Verify；
- 某 Story 不交付：回 Open 修订 baseline（新 revision）或拆新 Change；
- 部分已接受、部分失败：**整批不能归档**；若必须部分交付，说明该批不该是一个 Change。

---

## 5. 为什么用了很久辅助编程仍写不出可控高质量代码

**根因不是 AI 能力，而是投入结构：**

1. **造工具而非造产品**：仓库 146 个文档 vs 44 个代码文件，200 个测试测工作流，52 篇 FTL 设计没有实现。
2. **没有反馈回路**：没有可运行产品/快速测试，AI 无法自纠，人也无法验收。
3. **元工作替代工程**：设计流程、schema、validator 有即时成就感，真正写代码会暴露不确定性，于是不断做前者。
4. **练习的是流程设计，不是编程**：流程设计能力提升，编程能力原地踏步。
5. **工具链成了产品**：流程层数越多，越没时间写代码。

**建议：** 冻结流程 → 选 1–3 天垂直切片 → 先测试后实现 → 每天可运行增量 → 用指标（time-to-green、假绿灯率、返工、review 时间）决策。

---

## 6. ATDD-Comet 对辅助编程的真实好处与边界

**好处（机制性）：**

| 机制 | 解决的 AI 问题 |
|---|---|
| 需求 → 可判定 AC | 模型不知道“做到什么算对” |
| 独立 Oracle + 证据绑定 | 假绿灯、自证测试、编造结果 |
| 阶段状态 + 冻结基线 | 上下文漂移、需求反复变化 |
| 独立 Verify | AI 自评自过 |
| 风险分级 | 小改动被重流程拖死 |

**边界：**
- 只对“已知要做什么”的问题有效；探索性工作会被拖慢；
- 依赖可执行验证（测试、Oracle、故障注入），否则退化为文档仪式；
- 不替代工程判断（数据结构、并发模型、事务协议）；
- 粒度/比例错配会反噬。

**公式：** `价值 =（独立 Oracle × 证据可信度 × 风险伸缩）/ 流程开销`。

---

## 7. PRD+HLD 作为 PRD-Split 输入：形式与用法

**形式正确**：接口规范定义输入包 = `prd.md`（必须）+ `hld.md`（条件必须）+ `architecture-baseline.md`（条件必须）+ `manifest.yaml` + 可选附件。SSD 案例的稳定 ID 结构符合要求。

**六个注意点：**

1. 只给 PRD+HLD 不完整：缺 AB、manifest、领域来源；
2. **HLD 不是需求源**：其机制（如“同 LUN 页事务互斥”）不得直接写成 AC；
3. **AB Effective=0**：不得进入规范分母，必须登记 Decision；
4. 草案不能直接 FROZEN：冻结需人工确认；
5. 详细设计（52 篇 FTL）不是 HLD：属于 Design 输入；
6. 变更场景需提供前一版本 + 变更请求 + 影响分析。

**权威分层：**

| 来源 | 用途 | 限制 |
|---|---|---|
| PRD | 产品行为 → AC | 草案需确认 |
| HLD | 约束、场景、不变量 | 不直接成为 AC |
| AB | 架构约束候选 | Effective=0 时不生效 |
| 领域候选 | 发现风险/反例 | 只能 OBSERVATION |
| 代码/测试 | 工程事实 | 实现存在 ≠ 需求 |

---

## 8. AC 与设计的关系

**AC 独立于“解法设计”，但不独立于“约束与观察边界”。**

| 设计类型 | 例子 | 关系 |
|---|---|---|
| 解法设计 | 模块结构、类/函数、数据结构、算法、锁策略 | **必须独立**（重构不改变 AC） |
| 约束设计 | 已批准外部接口、Host 语义、持久化契约、领域不变量、架构约束 | **必须绑定**（作为观察边界） |

**三条判据：** 实现无关、外部可观察、可判定（独立 Oracle）。

**流程顺序：** AC 在 Design 前冻结；Design 只补“如何验证”，不能改“什么算对”；发现 AC 歧义/缺观察点 → 回 PRD-Split 修订 baseline。

**归属划分：** 行为与观察点属于 AC；Oracle 的**要求**属于 AC，Oracle 的**实现**与测试层级/环境属于 Design/Verify。

---

## 9. 如何确保 AC 提炼完全（以 Data GC 为例）

### 9.1 AC 来源（按权威）

| 来源 | 具体条款 | 能产出什么 |
|---|---|---|
| PRD | `FR-007/008/009/010/011/012/013/014/017/018/020/021`、`AC-008/009/010`、`SEM-001`、`SCOPE/CFG` | AC 主来源 |
| HLD | `EXE-001`、`FLOW-002/003`、`IF-004/005`、`PERSIST-001`、§8 `INV-001–016` | 约束、场景、不变量 |
| AB | Effective=0 | ❌ 不能作为来源 |
| 领域候选 | `SSD-GC领域候选`（PROPOSED） | 只能产生问题/反例 |
| Decision | `DEC-001–004` 等 | 确认后可新增/修改 AC |
| 代码/测试 | 工程事实 | 不得写成 AC |

### 9.2 完整性的两层

| 层 | 内容 | 保证方式 |
|---|---|---|
| **机械完整** | 已登记义务都有归属（AC / N/A 排除决定 / PARTIAL+gap） | `coverage_scope ↔ coverage` 一一对应，`COV-001` 可校验 |
| **语义完整** | 来源里的义务是否都拆出来了 | 方法 + 独立审阅，无法机器保证 |

### 9.3 六个动作

1. **来源条款逐条走查**：每个稳定 ID 标记“有义务 / 纯描述 / 不可判定（Decision）”；
2. **义务 → AC 覆盖矩阵**：有义务没 AC 也没 N/A → 漏覆盖；有 AC 没来源 → 无来源 AC；
3. **GC 场景矩阵**：GC 阶段 × Host 操作 × 故障点，逐格标 `AC / N/A / OPEN`；
4. **否定性判据**：旧值不复活、不双写、不越界擦除、不无限自旋、不饿死 Host；
5. **独立 Reviewer 重建**：从原始来源重新推导义务/AC，与结果做差异；
6. **版本差异覆盖**：来源升版时对照新增/修改/删除条款。

### 9.4 完成判据（DoD）

- [ ] PRD 强制义务 100% 有归属（AC 或有效 N/A 决定）；
- [ ] 适用 HLD 约束/不变量 100% 被评估；
- [ ] 每条 AC 有 `source_ref` + `oracle_ref` + 失败反例；
- [ ] 场景矩阵无未登记“未知”；
- [ ] `coverage` 对 scope 每义务恰好一条（COV-001 通过）；
- [ ] 独立 Reviewer 无未登记缺口；
- [ ] 人工确认后冻结 baseline。

---

## 10. 如何确保 AC 的正确性

**正确 ≠ 完整，也不等于“测试通过”。** 测试只能证明“实现符合 AC”，不能证明“AC 是对的”。

### 10.1 六个维度

| 维度 | 检查问题 | 方法 |
|---|---|---|
| 来源忠实 | 是否准确反映原文？ | 精确引用/锚点；Reviewer 对照原文 |
| 语义正确 | 是否真是产品想要的？ | 工程师/领域责任人确认并记录；例子走查 |
| 可判定 | 两人会得同一结论吗？ | 必须能写出失败反例 |
| 实现无关 | 换实现是否仍满足？ | 检查有无模块/函数/表/算法；重构不变 |
| 一致性 | 与其它 AC/不变量矛盾吗？ | 与 `INV-001..016`、其它 AC、PRD/HLD 交叉检查 |
| 可验收 | 当前环境能验证吗？ | 定义观察点/Oracle/证据/环境；不能执行标 NOT_EXECUTED |

### 10.2 八个机制

1. 来源锚定，禁止转述漂移；派生 AC 标 `DERIVED/PROPOSED`；
2. 例子化（具体输入/条件/结果/禁止结果）；
3. 强制反例（写不出反例的 AC 不冻结）；
4. Oracle 独立性检查（错实现能否通过？对实现会否误判？）；
5. 三向独立审阅（产品/领域、工程师、独立 Reviewer）；
6. 有权威的人签收并记录范围/版本；
7. 冻结后修改走 baseline 新 revision + 影响分析；
8. 用 Verify 发现的 AC 缺陷反哺修订。

### 10.3 变异测试（检验 AC 本身）

给实现注入典型错误（跳过重核对、旧值复活、带引用擦除、无限自旋、错误发布 MOVE），跑对应 AC 的测试：
**注入 bug 后测试仍绿 → AC/Oracle 不合格。**

### 10.4 GC 正/反例

| ❌ 不合格 | 问题 | ✅ 合格 |
|---|---|---|
| “GC 应高效回收空间” | 不可判定 | 块 A 有效页 V>0 且无并发更新，GC 后有效页=0、进入 free list、任意 LBA 读回最后写入值 |
| “调用 relocate() 后映射更新” | 耦合实现 | 搬迁成功后逻辑地址读到新数据；旧 PPA 不再被当前映射引用 |
| “搬迁失败后系统正常” | 模糊 | Program/日志失败不发布 MOVE，原映射仍可读，源块不被擦除 |
| “GC 不能死循环” | 判据不清 | 无净收益返回 GC_NO_PROGRESS，且在 B 个 victim 尝试内结束 |
| “掉电恢复正确” | 不可判定 | 在 `GC_AFTER_MOVE_COMMIT` 掉电重启后，读结果等于合法提交前缀（独立 Oracle） |

### 10.5 完成判据（DoD）

- [ ] 每条 AC 有精确来源、观察点、独立 Oracle、失败反例；
- [ ] 无实现细节；
- [ ] 与不变量及其它 AC 无未登记矛盾；
- [ ] 关键 AC 通过变异测试；
- [ ] 语义由有权工程师确认；
- [ ] 独立 Reviewer 无未登记的“不可判定/来源不符/实现耦合”发现。

---

## 11. Data GC 的端到端开发路径（ATDD-Comet + PRD-Split）

### 11.1 阶段

1. **输入登记（I3）**：PRD/HLD/AB/detailed design/领域候选；区分权威与草案状态；AB Effective=0 记 Decision。
2. **PRD-Split STUDY**：I3 义务 → D1 能力/合同 → D2 Story → D3 AC/VO/TC → D4 Wave/依赖/阻断 → 独立 Review → finish（candidate）。
3. **人工确认 → baseline FROZEN**。
4. **Comet Open**：一个 Change（W1），proposal/spec delta/tasks/atdd 映射；一次 Open confirm。
5. **Design**：每 AC 的 Design Item、验证意图、Oracle 机制；高风险决定交工程师。
6. **Build**：按 Story 切片，先 characterization tests，再测试先行实现；一条固定 check 留证据。
7. **Verify**：独立 verifier 重建 AC 分母，逐 AC 判定；L3 项未执行必须标 NOT_EXECUTED。
8. **Archive**：每 Story acceptance + 一次 Wait；知识候选入 OpenViking 前需审查。

### 11.2 Wave/Change 划分建议

| Wave | Story | Change 粒度 | 前置条件 |
|---|---|---|---|
| W1 | S1 空间账本与触发、S2 victim 选择与搬迁、S3 回收与擦除 | 1 个 Change | 可运行实现 + reference model + 不变量检查器 |
| W2 | S4 掉电恢复（L3） | 独立 Change | 故障注入能力 |
| W3 | S5 主机交错与让步（L3） | 独立 Change | 确定性回放/交错调度 |

### 11.3 五个坑

1. AB Effective=0 被当成有效约束；
2. 领域候选被写成规范义务；
3. 无故障注入能力就冻结 L3 AC；
4. 用实现当 Oracle；
5. 把 W2/W3 塞进 W1。

---

## 12. 行动建议（2 周实验）

1. **冻结流程扩展**（至少两周）：不再增加阶段/工件/校验。
2. 选 **DATA GC 的一个垂直切片**（S1 或 S1+S2），建 reference model + 不变量检查器。
3. 用**最小流程**：AC + Oracle + 证据 + 独立复核；L1/L2 不建全量 Change 工件。
4. 每周记录：time-to-green、返工次数、Verify 抓到的真问题、验收后才发现的问题、流程时间占比。
5. 判定：
   - 验收后问题下降且 time-to-green 不明显恶化 → 保留并扩展；
   - 验收后问题没变 → 修 Oracle/测试，不要再改流程；
   - 流程时间占比上升而质量没升 → 砍流程。

---

## 13. 未决事项

1. `09-Wave-Change-Mapping.md` 仍为 PROPOSAL：默认 Wave=Change 需批准后才改 Rule/validator/schema。
2. 批签语义：一次 Archive Wait 内多 Story acceptance 是否满足组织签收要求，待确认。
3. 两个 firmware 辅助 Skill 不恢复；comet 阶段 Skill 仅作为设计材料。
4. Comet CLI 在本机不可用（npx 缓存软链失效），`resume-probe` 无法执行。
5. 当前活跃 Change `atdd-classic-runtime-clean-redelivery`（单 Story 技术变更）可按 v1 继续，不强行迁移。

---

## 附：关键文件索引

- [ATDD-Comet V2 架构](docs/new/ATDD-Comet-V2-Workflow-Architecture.md)
- [阶段设计索引](docs/new/comet-stages/README.md)｜[PRD-Split](docs/new/comet-stages/01-PRD-Split.md)｜[Open](docs/new/comet-stages/02-Open.md)｜[Design](docs/new/comet-stages/03-Design.md)｜[Build](docs/new/comet-stages/04-Build.md)｜[Verify](docs/new/comet-stages/05-Verify.md)｜[Archive](docs/new/comet-stages/06-Archive.md)
- [Classic ATDD 接入设计（08）](docs/new/comet-stages/08-Classic-ATDD-Runtime-Adaptation.md)｜[Wave=Change 映射设计（09）](docs/new/comet-stages/09-Wave-Change-Mapping.md)
- [Classic ATDD 工件合同](docs/atdd/README.md)｜[模板](docs/atdd/templates.md)｜[schemas](docs/atdd/schemas/)
- [SSD Simulator 输入案例](docs/input-cases/ssd-simulator/README.md)｜[PRD](docs/input-cases/ssd-simulator/PRD.md)｜[HLD](docs/input-cases/ssd-simulator/HLD.md)｜[AB](docs/input-cases/ssd-simulator/AB.md)
- [FTL 详细设计](docs/ftl-design/ssd-simulator-v0.2.0/README.md)｜[GC 领域候选](docs/new/domain-context/SSD-GC领域候选.md)
- [PRD-Split 输入接口规范](docs/input-templates/PRD-Split-输入文档接口规范-v1.0.md)
- [项目笔记 NOTES](NOTES.md)｜[领域词汇表 GLOSSARY](GLOSSARY.md)
