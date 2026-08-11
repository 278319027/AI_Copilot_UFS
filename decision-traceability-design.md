# AI 决策引用级追溯机制 — 可移植设计说明

版本：1.0
日期：2026-08-11
适用范围：任何希望让 AI 编码助手的决策可验证、可审计、可复用的工程团队

---

## 0. 本文档定位

这是一份**自包含、与具体技术栈解耦**的设计说明。读者可以：

1. 理解"AI 决策可追溯"要解决什么问题（§1）
2. 照抄核心机制（§2-§7）——标注语法、解析、校验、门禁、决策登记
3. 按 §9 的最小实现清单在任意项目落地（约 1-2 人周）
4. 按 §10 渐进增强

不依赖特定框架（不绑定 OpenCode / LangGraph / CrewAI）。机制是通用的，任何 LLM 编码工具 + 文件系统 + Git 都能实现。

---

## 1. 问题与核心思想

### 1.1 问题

LLM 编码助手（Agent）在开发中会做出大量决策：选方案、定参数、设计接口。这些决策面临三个不可信问题：

| 问题 | 表现 | 后果 |
|---|---|---|
| 幻觉 | AI 声称"保持 75% 是行业标准"但无依据 | 错误决策看起来有依据 |
| 静默猜测 | AI 在猜但不说"我在猜" | 无证据的决策被当成事实 |
| 不可复用 | 这次踩的坑下次还踩 | 经验不沉淀 |

### 1.2 核心思想

> **把"AI 置信度自评"换成"引用可机器验证"。**

AI 说"confidence: 0.91"是不可信的（自评）。但如果 AI 说 `[E:code:gc.c:125]`，系统可以**实际去查文件**：文件存在吗？行号对应什么符号？——这是机器验证，可信。

机制三件套：

```
① 标注   — AI 在每个决策后写 [E:type:locator] 引用标签
② 验证   — 系统实际解析每个引用到具体来源，查不到就报错
③ 门禁   — 引用覆盖率不达标 / 有不可解析引用 → 阶段 gate 失败
```

### 1.3 设计目标

- **可验证**：每个决策都能追到具体证据来源（文件:行 / 文档章节 / 知识条目 / 专家答复 / 人工记录）
- **显式化**：无证据决策必须标记为 assumption 并登记为"知识缺口"，禁止静默猜测
- **可复用**：沉淀的知识条目可被后续决策引用，且引用本身可验证
- **低成本**：不依赖复杂基础设施，文件系统 + 正则即可实现

---

## 2. 核心概念

### 2.1 证据引用标签（Evidence Tag）

AI 在 Artifact（设计文档、分析文档等）中，每个**决策句**后必须挂内联标签：

```markdown
将 gc_threshold 保持 75%，不提高 [E:code:gc_policy.c:125][E:expert:EXP-001]。
```

**语法**：`[E:` + `type` + `:` + `locator` + `]`

- `type`：证据类型（§3）
- `locator`：该类型下的具体定位符

一条决策可以有多个标签（代码证据 + 专家证据 + 历史 bug 证据）。

### 2.2 决策日志（decision-log）

每个 Feature 根目录维护一份 `decision-log.yaml`，登记该 Feature 所有决策：

```yaml
feature: GC_POLICY_TUNING
decisions:
  - id: DEC-001
    agent: main            # 谁做的决策（main/expert/reviewer/human）
    phase: design          # 哪个阶段（open/design/build/verify/archive）
    question: "gc_threshold 是否提高到 85%？"
    decision: "保持 75%，不提高"
    status: decided        # decided | assumption | deferred | insufficient_information
    confidence: 0.91
    evidence:
      - type: code
        ref: "gc_policy.c:125"
      - type: expert
        ref: "EXP-001"
    alternatives:
      - option: "提高到 85%"
        rejected_reason: "risk=high，历史 bug 证据"
    risk: high
    reviewer_findings: [R001]
```

**核心规则**（由校验器强制）：

| status | evidence 要求 | confidence 要求 |
|---|---|---|
| decided | 至少 1 条 evidence | ≥ 0.6 |
| assumption | 允许为空（明确是猜测） | < 0.6 |
| insufficient_information | 允许为空（无法回答） | 任意 |
| deferred | 允许为空（暂缓） | 任意 |

**关键约束**：`status: assumption` 或 `confidence < 0.6` 的决策**必须**同时出现在 knowledge-gaps.yaml（§2.4），形成双向关联（`decision_ref`）。

### 2.3 知识缺口（knowledge-gaps）

```yaml
gaps:
  - id: GAP-001
    question: "Why is gc_threshold 75%?"
    category: DESIGN_REASON   # STRUCTURE/SPECIFICATION/DESIGN_REASON/HISTORICAL/RISK/PERFORMANCE/PROTOCOL/HARDWARE/UNKNOWN
    confidence: 0.35
    risk: high
    blocking: true            # true = 必须解决才能继续
    decision_ref: DEC-002     # 回链来源决策
```

**用途**：无证据决策（assumption）自动产生知识缺口 → 触发专家咨询（§8.4）→ 专家答复后回填 decision-log（status 升级为 decided）。

### 2.4 追溯报告（traceability-report）

校验器每次运行生成报告：

```markdown
- Artifact: design.md
- Assertions: 6          # 决策句总数
- Cited: 4               # 有引用的
- Coverage: 66.7%        # Cited / Assertions
- Gate: FAIL             # PASS / FAIL

## Uncited claims       # 决策句但无引用
- "提高阈值后 FTL 卡顿"

## Unresolved references  # 有引用但解析不到
- `[E:viking:BUG-2023-017]` — id_not_found

## Gap linkage errors   # assumption 决策未登记到 gaps
- "DEC-002 is assumption but not linked to any gap"
```

---

## 3. 证据类型注册表

7 种证据类型，每种有 locator 格式 + 解析方式。**这是全机制的核心表**：

| type | 含义 | locator 格式 | 正则校验 | 解析方式（必须实际查询） |
|---|---|---|---|---|
| `code` | 代码事实 | `file:line` 或符号名 | `^[A-Za-z0-9_./-]+(:\d+)?$` | 文件存在（向上搜索）；有索引则查符号存在 |
| `wiki` | 正式规范 | `doc.md#section` | `^[A-Za-z0-9_./-]+(\.md)?(#[\w-]+)?$` | 知识索引中查文档 ID |
| `viking` | 工程经验 | `BUG-2023-017` | `^(BUG\|ADR\|LESSON)-\d{4}-\d{3}$` | 知识索引中查条目 ID |
| `expert` | 专家答复 | `EXP-001` | `^EXP-\d{3}$` | 读专家答复文件，提取其中 EXP id 匹配 |
| `test` | 测试证据 | `file:line` | 同 code | 文件存在 |
| `human` | 人工决策 | `REVIEW-2026-001` | `^(REVIEW\|APPROVAL)-\d{4}-\d{3}$` | decision-log 中查 ID |
| `assumption` | 显式假设 | `DEC-007` | `^DEC-\d{3}$` | decision-log 中查 DEC 条目 |

**关键设计**：

1. **locator 必须有格式约束**（正则），防 AI 写任意字符串充数
2. **解析必须"实际去查"**——不是检查格式，是查目标是否存在
3. **跨目录搜索**：Artifact 在 `03_design/`，引用的文件在 feature 根，解析器要向上逐级找
4. **错误要有原因分类**：`file_not_found` / `id_not_found` / `expert_id_not_found` / `invalid_locator`——方便 AI 修复

---

## 4. 解析器设计

### 4.1 标签提取（纯正则，无依赖）

```typescript
// 从 markdown 提取所有 [E:type:locator]
const TAG_RE = /\[E:(\w+):([^\]]+)\]/g;

interface EvidenceTag {
  type: string;      // code/wiki/viking/expert/test/human/assumption
  locator: string;   // 定位符
  raw: string;       // 原始文本 [E:...]
  malformed?: boolean; // 未知 type 时标记
}

function parseEvidenceTags(markdown: string): EvidenceTag[] {
  const tags: EvidenceTag[] = [];
  for (const match of markdown.matchAll(TAG_RE)) {
    tags.push({ type: match[1], locator: match[2], raw: match[0] });
  }
  return tags;
}
```

### 4.2 结论句检测（assertion 检测）

决策句 = 含结论性动词的句子。**动词表要按领域维护**：

```typescript
// 初始集合（按语言/领域扩展）
const CONCLUSION_VERBS = ["决定", "保持", "必须", "采用", "假设"];

// 增强（推荐）：正则粗筛 + 对"疑似结论但无标签"句子用 LLM 复核
function isConclusionSentence(sentence: string): boolean {
  return CONCLUSION_VERBS.some(v => sentence.includes(v));
}
```

**已知局限**（如实声明）：动词表是硬编码的，会漏掉"提高/增加/选择/优化"等动词；文档标题含动词会被误判。优化见 §10.1。

### 4.3 引用解析（resolver）

```typescript
function resolveTag(tag: EvidenceTag, ctx: ResolveContext): string | null {
  switch (tag.type) {
    case "code": case "test":
      return resolveFile(tag.locator, ctx.artifactDir);   // 向上搜索文件
    case "wiki": case "viking":
      return resolveFromIndex(tag.locator, ctx.index);    // 查知识索引
    case "expert":
      return resolveExpert(tag.locator, ctx.artifactDir); // 读专家答复文件
    case "human": case "assumption":
      return resolveFromDecisionLog(tag.locator, ctx.decisionLog); // 查 decision-log
    default:
      return null; // malformed
  }
}
```

**跨目录向上搜索**（重要——Artifact 常引用上级目录文件）：

```typescript
function findUpward(filename: string, startDir: string, stopDir: string): string | null {
  let dir = startDir;
  while (true) {
    const candidate = path.join(dir, filename);
    if (existsSync(candidate)) return candidate;
    if (dir === stopDir || path.dirname(dir) === dir) return null;
    dir = path.dirname(dir);
  }
}
```

---

## 5. 门禁（Gate）判定

### 5.1 公式

```
coverage = cited / assertions
gate = (coverage >= 0.8) && (unresolved 无高危模块引用)
```

### 5.2 规则明细

| 规则 | 条件 | 结果 |
|---|---|---|
| 覆盖率不足 | coverage < 0.8 | FAIL |
| 高危引用不可解析 | unresolved 引用属于高危模块文件（按项目定义，如 `gc.c`/`power.c`） | FAIL |
| 假设未登记 | assumption 决策未关联 knowledge-gaps.yaml | 报 linkage error（进报告） |
| 空文档 | assertions == 0 | 视为 FAIL（防"没写任何决策"空真通过） |

### 5.3 高危模块

按领域定义。固件示例：

```yaml
high_risk_modules:
  - gc.c
  - power.c
  - recovery.c
  - nand.c
```

设计意图：普通模块引用解析失败只扣覆盖率；高危模块引用解析失败**直接 FAIL**——因为高危模块的决策必须有确凿依据。

---

## 6. 决策日志校验器

独立的 `validateDecisionLog(yaml)` 校验器，规则（§2.2 表）：

```typescript
function validateDecisionLog(yaml: string): { valid: boolean; errors: string[] } {
  // 1. 结构校验：feature/decisions 必填，decisions 非空
  // 2. 字段枚举：agent ∈ {main,expert,reviewer,extractor,human}
  //             phase ∈ {open,design,build,verify,archive}
  //             status ∈ {decided,assumption,deferred,insufficient_information}
  // 3. confidence ∈ [0,1]
  // 4. id 匹配 ^DEC-\d{3}$
  // 5. 核心规则：
  //    - decided 必须有 ≥1 evidence 且 confidence ≥ 0.6
  //    - assumption/insufficient_information 允许空 evidence
  // 6. 交叉校验：assumption 条目必须关联 knowledge-gaps.yaml（linkDecisionToGap）
}
```

---

## 7. 端到端流程

```
AI 编写 design.md（决策句带 [E:type:locator] 标签）
    │
    ▼
运行校验器 check.ts
    │
    ├─ 提取标签 → 解析每个引用（实际查文件/索引/专家答复）
    ├─ 检测未引用决策句（uncited claims）
    ├─ 校验 decision-log.yaml（结构 + 规则）
    ├─ 校验 assumption ↔ knowledge-gaps 关联
    │
    ▼
生成 traceability-report.md（coverage / gate / uncited / unresolved / linkage）
    │
    ▼
gate = PASS ? 进入下一阶段 : 修复（补引用 / 补证据 / 登记 gap）
    │
    ▼
修复后重跑 → 直到 PASS（或人工裁决）
```

---

## 8. 工程集成（关键——光有校验器不够）

### 8.1 决策纪律写入 Agent 指令

在 Agent 的 system prompt / skill 文档中强制：

```
每个设计决策必须：
1. 登记 decision-log.yaml（DEC-xxx + evidence + confidence + status）
2. 在 Artifact 结论句后写 [E:type:locator] 引用
3. 无证据 → status: assumption + confidence < 0.6 + 进 knowledge-gaps.yaml
4. 完成 Artifact 后运行校验器，gate PASS 才能继续
```

**纪律不是可选的**——它决定了整个系统是否有数据。光有校验器没有纪律 = 空壳。

### 8.2 阶段门禁

把校验器接入开发流程的阶段出口：

```
Open 阶段产出 → 校验 → PASS → Design 阶段
Design 阶段产出 → 校验 → PASS → Build 阶段
...
```

### 8.3 知识缺口自动触发（可选增强）

Hook 监听 knowledge-gaps.yaml 写入 → 检测 `blocking: true` 的缺口 → 自动路由到领域专家：

```
知识缺口 → 专家路由（规则表：关键字→专家） → 专家答复（带自己的证据链）
         → 回填 decision-log（status: assumption → decided）→ 重跑校验器 → PASS
```

### 8.4 专家答复协议

专家（可以是另一类 Agent 或人工）必须遵守：

```yaml
# expert-answer.md
request_id: EXP-001
status: answered              # answered | insufficient_information
conclusion: "75% threshold protects host latency"
evidence:                     # 必须逐条对应证据
  code: [{ref: "gc_policy.c:125"}]
  knowledge: [{ref: "BUG-2023-017"}]
confidence: 0.91
risk: high
recommendation: "Do not increase threshold directly."
remaining_unknowns: []
```

**证据不足时禁止猜测**：`status: insufficient_information` + reason + recommended_action（可含 human_confirmation）。

---

## 9. 最小实现清单（1-2 人周）

按顺序实现，每步可独立验证：

| 步骤 | 交付物 | 验证 |
|---|---|---|
| 1. 标签解析器 | `parse.ts`：TAG_RE + parseEvidenceTags | 单测：提取/非法标签 |
| 2. 证据类型表 | `evidence-types.yaml`：7 类型 + 正则 + resolver | 单测：格式校验 |
| 3. decision-log 校验器 | `decision-log.ts`：validateDecisionLog + linkDecisionToGap | 单测：规则拒绝/放行 |
| 4. 主校验器 | `check.ts`：resolveTag + gate + 报告生成 | 单测：coverage/gate；CLI 手工验证 |
| 5. 纪律文档 | skill / prompt 写入决策纪律 | 人工：AI 产出带标签文档 |
| 6. 阶段门禁 | 流程接入校验器 | 端到端：走完一个阶段 |
| 7. 测试套件 | 全部模块单测 | 全绿 |

**技术栈建议**：TypeScript + 正则 + YAML 解析库 + vitest（或任意语言等价物）。**不需要**向量库 / LLM 框架 / 数据库。

---

## 10. 已知局限与增强路径

### 10.1 动词表智能化（低成本高价值）

硬编码动词会漏句。增强：正则粗筛 + LLM 复核"疑似结论句"。

### 10.2 语义级验证（高价值）

现状验证"引用存在且格式对"，不验证"内容正确"。增强：

- 接代码索引（CodeGraph 类工具）查符号存在性
- 对高危决策，让 LLM 复核"这行代码是否真的支持结论"

### 10.3 标签自动注入辅助（降低纪律成本）

AI 写 Artifact 时挂标签是额外负担（易漏、易格式错）。增强：

- **候选引用建议**：写完 design.md 后，解析器输出"哪些结论句缺标签 + 建议补什么"。code 类引用可由代码索引自动建议（决策提到 `gc_threshold` → 建议 `[E:code:gc_policy.c:NNN]`）。
- **引导式补全**：从"AI 自觉挂"升级为"系统提示挂"——未引用决策句在报告中列出，AI 修复时按提示补。
- **模板化**：skill / prompt 中给决策句标准模板，降低格式错误率。

### 10.4 提交级门禁（强制化）

从"流程内自觉运行"升级为"git pre-commit hook / CI 检查"——任何包含未登记决策的提交被拦截。

### 10.5 引用数据库化

维护 decision → evidence → source 关系图（json/DB），增量检查 + 跨 Feature 追溯。

### 10.6 动态验证（远期）

把"决策依据可追溯"扩展为"决策效果可验证"——决策声称"保护 latency"，verify 阶段真去测 latency。

---

## 11. 常见陷阱（实战踩过）

| 陷阱 | 症状 | 对策 |
|---|---|---|
| 空真通过 | 文档无决策句 → coverage=1 → gate PASS | assertions==0 视为 FAIL |
| 假证据 | 引用格式对但目标不存在 | 解析必须"实际去查"非"检查格式" |
| 幂等失效 | 重复运行生成重复 EXP/review | 按 gap_id/content_hash 判重 |
| 跨目录断链 | Artifact 引用上级文件解析不到 | findUpward 向上搜索到仓库根 |
| 纪律失效 | AI 不挂标签 → 系统空转 | gate 兜底 + 提交级门禁 |
| 标题误判 | "## 假设"标题被当决策句 | 动词检测限句子级，排除标题 |

---

## 12. 价值总结

这套机制把"AI 辅助开发"从**信任问题**变成**验证问题**：

- 幻觉 → 过不了 gate（引用不可解析即失败）
- 静默猜测 → 系统强制登记 assumption + 知识缺口
- 决策审计 → 每个结论可追溯到具体证据来源
- 经验复用 → 知识条目可被引用且引用可验证

**它不是银弹**：保证"引用存在且格式对"，不保证"引用内容正确"；依赖 AI 挂标签的纪律（gate 是兜底）。它解决的是**可验证性**问题，不是**正确性**问题。
