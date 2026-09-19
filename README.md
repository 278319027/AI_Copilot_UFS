# 设计文档集：AI 辅助 UFS/SSD 固件开发平台

本目录是 `docs/` 下四份方法论讨论稿与 `V1.0` 文档的**融合分类、共识裁定后的设计成果**。

做法是三步：

> **融合分类 → 对不一致之处裁定共识 → 输出设计。**

参考资料之间的每一处分歧都已在设计中就地给出定论，不把裁决责任留给读者。**本套文档不设"待评审 / 待裁决"状态**；只有依赖本设计之外事实的事项列为"外部依赖"。

---

## 1. 文件清单

| 文件 | 内容 | 回答的问题 | 规模 |
|---|---|---|---|
| [`00-总体设计-V2.0.md`](00-总体设计-V2.0.md) | **主文档 · 设计基准** | 平台是什么、怎么分层、谁在什么节点做什么 | 1437 行 |
| [`01-方法论-ATDD与测试设计.md`](01-方法论-ATDD与测试设计.md) | 方法论层 | 行为怎么定义、怎么验证、怎么实现 | 2630 行 |
| [`02-Skill规范.md`](02-Skill规范.md) | Skill 契约层 | 每个 Skill 的输入输出与硬规则是什么 | 3040 行 |
| [`03-Comet实现设计-节点特化·Plugin·Hook.md`](03-Comet实现设计-节点特化·Plugin·Hook.md) | 平台实现层 | Comet 节点如何特化、能力与强制如何落地 | 1932 行 |
| [`04-Stage0-需求分解与Challenge.md`](04-Stage0-需求分解与Challenge.md) | 需求前端 | 需求如何被拆成可验收基线并冻结 | 951 行 |
| [`99-共识裁定表.md`](99-共识裁定表.md) | **裁定登记** | 参考资料冲突的完整裁定记录（86 条） | 437 行 |
| [`98-跨册缺陷总表.md`](98-跨册缺陷总表.md) | **缺陷总表（非设计正文）** | 修复前的跨册缺陷登记、批次划分与修复进度 | 884 行 |

**合计 11,311 行**：六册设计正文 10,427 行 + `98` 缺陷总表 884 行（不含本导读）。

---

## 2. 权威关系

```text
00 主文档  ←── 唯一设计基准
   │           后续所有 Agent / Skill / Hook / Plugin / 产物设计
   │           都必须从它向下分解
   │
   ├── 01 方法论      展开「怎么做工程」
   ├── 02 Skill 规范  展开「每个方法的契约」
   ├── 03 实现设计    展开「契约如何被强制」
   ├── 04 Stage 0     展开「需求如何进来」
   └── 99 共识裁定表  登记全部裁定；主文档附录 A 是其关键摘要
```

**规则**：分册只做展开，**不得与主文档冲突**。若分册发现主文档有误，先改主文档，再改分册。

---

## 3. 建议阅读路径

**第一次读**（理解全貌，约 1 小时）：

```text
00 主文档 §1 设计目标
   → §2 Comet 基线          ← 关键：phase=5 / node=8 双轨
   → §3 总体架构
   → §4 生命周期与节点挂载   ← 关键：每个节点谁做什么
   → §6 Agent 架构
   → §7 Skill 架构
```

**按角色读**：

| 角色 | 路径 |
|---|---|
| 架构 / 决策者 | 00 全篇 → 附录 A 关键裁定 → 附录 C 外部依赖 → 99 全量裁定 |
| 方法论负责人 | 00 §1–§5 → 01 全篇 |
| Skill 作者 | 00 §7 → 02 全篇（尤其统一 18 节模板） |
| 平台实现者 | 00 §2 §4 §6.5 §8 §12 → 03 全篇 |
| 需求 / 产品 | 00 §1 §4.1 §5 §10 → 04 全篇 |

---

## 4. 引用方式

**正文不逐节标注来源。** 设计陈述直接给出结论——读者不需要在每一节看到"这条出自哪份文档的哪一行"。

- **参考资料在文档级列出**，见主文档附录 B。
- **分歧与裁定**集中登记于主文档附录 A（关键裁定）与 [`99-共识裁定表.md`](99-共识裁定表.md)（全量 86 条，含各方说法与裁定理由）。
- 引用 Comet 本体时直接写文件名（如 `classic-state.ts`、`builtins.ts`）。

### 裁定编号命名空间（强制）

裁定编号跨册必须唯一，否则会重现"同号不同义"：

| 范围 | 前缀 | 示例 |
|---|---|---|
| **全局裁定**（`99-共识裁定表.md`） | `D01`…`D86` | `99 D14` |
| 分册 01 的本册裁定 | `MR-*` | `MR-3` |
| 分册 02 的本册裁定 | `SKR-*` | `SKR-2` |
| 分册 03 的本册裁定 | `IR-*` | `IR-1` |
| 分册 04 的本册裁定 | `S0R-*` | `S0R-5` |
| **外部依赖事项**（主文档附录 C，唯一登记处） | `EXT-01`…`EXT-13` | `EXT-04` |

规则：

- 五册正文引用**全局裁定**时一律写 **`99 D##`**；引用**本册裁定**时写本册前缀。
- 不得裸用 `D##` 指向本册裁定。
- **对象 ID 的前缀白名单由主文档 §5.1.1 的五张子表唯一持有**（表 N1 单段集 / 表 N2 两段集 / 表 N3 历史别名集 / 表 N4 规则与事项命名空间集 / 表 N5 局部命名空间排除集）。分册只引用，不得另立前缀。
- 规则编号是独立体系：`FR-*`（正式规则）/ `SYS-*`（体系级）/ `SR-*`（Skill 侧）/ `ACR-*`（AC 质量）/ `CR-*`（Code Review）/ `TCR-*`（Test Contract）等，见主文档 §5.1.1 表 N4 与 §5.1.2。
- 测试用例只有一个前缀 `TC-`；`UT-`/`IT-`/`CHAR-` 是历史别名（主文档 §5.1.1 表 N3）。审查记录用 `RVW-`、审查条目用 `REV-`。

**裁定与修订的轨迹集中在 `99` 与主文档附录 A。** 各册不设"修订记录"章——过程记录不属于设计正文。

---

## 5. 与 V1.0 的关系

`../AI辅助UFS_SSD固件开发_ATDD_Comet_完整设计文档_V1.0.md` **原样保留**，降级为历史版本。

V2.0 相对 V1.0 的重大修正：

| # | V1.0 的表述 | V2.0 的修正 | 原因 |
|---|---|---|---|
| 1 | 「五阶段」（Open/Design/Build/Verify + Requirement） | **`phase=5` / `node=8` 双轨** | 草稿把 `plan` 节点当独立阶段、把 `archive` 叫 "Close"，混淆了 phase 与 node |
| 2 | Agent 名册：Main / Requirement / Challenge / Open / Design / Build / Build Review / Verify / Firmware Expert | **13 Agent**：1 编排 + 5 执行 + 3 审查 + 2 专家 + 2 前置 | 对齐 Comet 节点契约；横切审查者不计入阶段执行层 |
| 3 | 无代码审查归属 | **`ufs-code-review` + Comet `review` 节点** | Comet 原生已有 `review` 节点，V1.0 漏读 |
| 4 | 「冻结五个核心 Skill」 | **8 个 Skill** | 补 `ufs-challenge`、`ufs-code-review`；`ufs-verification` 的规范需补全 |
| 5 | 工程调查在 Open | **归入 `design` 节点 Step 0** | Comet 的 `open` 语义是 intake + 初始化，不承担影响分析 |

完整裁定见主文档 **附录 A** 与 [`99-共识裁定表.md`](99-共识裁定表.md)。

---

## 6. 当前状态

| 项 | 状态 |
|---|---|
| 设计目标（G1–G5 / N1–N9 / S1–S5） | ✅ 已定稿 |
| 总体架构（六层 / 职责等式 / 8 条不变量） | ✅ 已定稿 |
| Comet 对齐（phase=5 / node=8） | ✅ 已定稿 |
| Stage 0 定位（需求分解 + Challenge） | ✅ 已定稿 |
| Agent 名册（13） | ✅ 已定稿 |
| Skill 集（8） | ✅ 已定稿 |
| 参考资料分歧的裁定 | ✅ 已完成（86 条，C1–C20 全覆盖） |
| 跨册一致性 | ✅ 已审查并修订；**批次 1–6 全部完成**，逐批改动与验收见 [`98-跨册缺陷总表.md`](98-跨册缺陷总表.md) §0.5；独立全量逐行复核已执行，发现项已修复 |
| **依赖外部条件的事项** | ⬜ 13 项（`EXT-01`…`EXT-13`），见主文档附录 C（唯一登记处）：本仓库布局冲突、`comet` CLI 未安装、目标 Comet 版本、新产物 schema 扩展、UFS 领域清单、上游 `autonomous` 修复、Node Projection 写入钩子、External Validator 形态、Freeze Hook 挂载点、Stage 0 纳入 Runtime、Capability Token、不可测声明审批角色、`.gitignore` 可改性 |
| 与 Comet 具体版本的适配 | ⬜ 后续实施阶段 |
| `.opencode/` 与 `.comet/` 运行时落地 | ⬜ 后续实施阶段（见主文档 §13 Phase 5） |

---

## 7. 术语速查

```text
phase（5，Comet 常量，不可改）
  open → design → build → verify → archive

node（8，Comet 原生 Workflow Node，可按 preset 裁剪）
  open / design / plan / execute / subagent-execute
  / review / verify / archive
  ※ plan 与 execute 都在 build 阶段内；review 在 execute 与 verify 之间

职责等式
  Comet=WHEN  Agent=WHO  Skill=HOW  Plugin=CAPABILITY
  Hook=ENFORCEMENT  CodeGraph=CODE FACTS  OpenViking=KNOWLEDGE
  Human=DECISION

Stage 0（在 Comet phase 之外）
  Requirement Decomposition（ufs-requirements + prd-split）
  → Human Review
  → Challenge（ufs-challenge + grill-me）
  → Human Story Freeze
  ═══ Comet phase 边界（此时才创建 change）═══

13 Agent
  编排 1  ufs-main
  执行 5  ufs-exploration / ufs-design / ufs-test-design / ufs-build-plan / ufs-coding
  审查 3  ufs-document-review / ufs-code-review / ufs-verification
  专家 2  ufs-firmware-expert / ufs-failure-analysis
  前置 2  ufs-requirements / ufs-challenge

8 Skill
  前置  prd-split / ufs-challenge
  节点  atdd-development / ufs-test-design / ufs-writing-plans
        / ufs-tdd / ufs-code-review / ufs-verification

产物根（由 Comet 的 pathBase 决定）
  <openSpecRoot>      docs/openspec/  或 legacy openspec/
                      proposal · delta spec · tasks.md · .comet.yaml
  <superpowersRoot>   docs/superpowers/（恒此路径）
                      specs/  → Canonical Design Doc、test-design.md
                      plans/  → plans/*.md
                      reports/→ exploration-report.md
  comet-artifacts/    requirements/（Stage 0-a）· challenge/（Stage 0-b）
```
