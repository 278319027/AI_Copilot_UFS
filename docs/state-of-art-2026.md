# AI 辅助编程方法论调研 — 2025 年底/2026 年现状

**日期**：2026-06-18
**范围**：外部方法论现状 vs. zsf 方法论（OpenSpec + Superpowers + CodeGraph + Graphify）
**方法**：11 个并行网络搜索，对照一手来源（Anthropic、OpenAI、Microsoft、Princeton/SWE-agent、Cognition/Devin、Vercel、GitHub Blog、InfoQ、agentskills.io、agents.md，外加六个新图谱/知识 MCP 工具）

> **TL;DR — zsf 站位良好。** 已落地 2026 年最佳实践的四大支柱（AGENTS.md、Skills、Spec-driven、图谱化 KNOW）。最大差距在 *context engineering*（无首类 compaction/clearing/memory 层）和 *agent 验证自动化*（三条铁律已文档化但无确定性 Stop-hook gate）。Microsoft Spec Kit 是唯一有可比端到端 SDD 流水线的同类竞品（112K★、165 次发布），其设计与 zsf 趋同——差异化在采用率，不在架构。

---

## 主题 1 — AGENTS.md 作为新标准

**状态：匹配/前沿**（你已经有 `AGENTS.md`；厂商原生支持已成默认）。

### 关键进展（2025 年底 → 2026）

1. **Linux Foundation 接管，2025-12-09。** OpenAI 与 Anthropic 联合将 AGENTS.md 捐赠给新成立的 **Agentic AI Foundation (AAIF)**，连同 Anthropic 的 MCP 与 Block 的 Goose。Platinum 成员：OpenAI、Anthropic、Block。支持成员：Google、Microsoft、AWS、Bloomberg、Cloudflare。该标准不再是单一厂商产物。来源：[tessl.io 博客 2025-12-09](https://tessl.io/blog/openai-anthropic-and-others-unite-behind-agentic-ai-foundation-for-open-standards/)；[CIO Dive 2025-12-10](https://www.ciodive.com/news/big-tech-develop-open-standards-agentic-ai/807608/)。

2. **6 万+ 仓库，22K★ 参考仓库，HN 837 分上线。** AGENTS.md 8 个月内从 0 增至 6 万+。参考仓库 [github.com/agentsmd/agents.md](https://github.com/agentsmd/agents.md)（截至调研 22,184★）。约定："纯 Markdown，无自定义语法，厂商中立，最近文件自动发现。"

3. **多厂商原生支持。** Codex、Cursor、GitHub Copilot、Gemini CLI、Google Jules、VS Code agent 模式、Aider、Zed、Warp、RooCode、Devin、Amp (Sourcegraph)、Junie、opencode、UiPath Autopilot、Factory CLI。**唯一主流例外是 Anthropic Claude Code**，仍优先 `CLAUDE.md`（issue #6235 是最高反应数之一）。来源：[agents.md](https://agents.md/)、[AgentMarketCap 2026-04-17](https://agentmarketcap.ai/blog/2026/04/17/agents-md-60k-adoption-aaif-donation-standards-floor)。

4. **Vercel 评测：AGENTS.md 33/33 击败 skills 31/33**（2026-01-29）。首次公开头对头对比：永远在上下文里的指令，对"agent 必然会用到的事实"比按需触发的 skills 更优。来源：[EarlyTerms](https://earlyterms.com/term/agents-md)、[Vercel 博客，EarlyTerms 引用]。

5. **GitHub 2,500 仓库研究（2025-11）。** 经验性回答"如何写一份好的 AGENTS.md"——章节、长度、命令块对 agent 成功率的实际相关性。来源：[github.blog，EarlyTerms 引用](https://github.blog/ai-and-ml/generative-ai/spec-driven-development-with-ai-get-started-with-a-new-open-source-toolkit/)。

### 判定：**领跑**

zsf 已交付符合标准格式的 AGENTS.md。AAIF 规范强制"最近文件优先"语义，可在 `openspec/` 和 `docs/` 放置子目录 `AGENTS.md` 来限定单区域指令。**具体行动：** 当前 52 行 `AGENTS.md` 良好但未使用共识章节排序（Dev / Testing / PR instructions）——建议对齐 `agentsmd/agents.md` 示例模板。

---

## 主题 2 — Skills：Anthropic Skills vs OpenCode Skills vs 纯 Markdown

**状态：与新兴开放标准匹配**（你的 `.opencode/skills/` 是 SKILL.md 风格技能集，但项目尚未按开放 `agentskills.io` 规范对外暴露）。

### 关键进展

1. **Anthropic Agent Skills 规范现已是 [agentskills.io](https://agentskills.io/specification) 上的开放标准**（2025-10-16 发布；规范托管于 [github.com/agentskills/agentskills](https://github.com/agentskills/agentskills)，20K★）。一个 skill 是一个文件夹，内含 `SKILL.md`（YAML frontmatter：`name`、`description`；可选 `license`、`compatibility`、`metadata`、`allowed-tools`），外加可选的 `scripts/`、`references/`、`assets/`。格式与实现无关。

2. **渐进式披露是主流设计模式。** 三级加载：(1) metadata ≈100 tokens，永远在上下文；(2) `SKILL.md` 正文 < 5000 tokens，激活时加载；(3) 捆绑资源，按需加载。**Anthropic 硬性规则：`SKILL.md` < 500 行**；拆分为被引用的子文件。来源：[Anthropic 工程博客 2025-10-16](https://www.anthropic.com/engineering/equipping-agents-for-the-real-world-with-agent-skills)；[Anthropic 完整技能构建指南 PDF](https://resources.anthropic.com/hubfs/The-Complete-Guide-to-Building-Skill-for-Claude.pdf)。

3. **OpenCode 的 `.opencode/skills/` 用同样的模式**，但早于公开规范发布。你的项目已有三个 skill（`openspec-workflow`、`sd-firmware-copilot`、`superpowers`），每个作为 `.opencode/skills/` 下的子目录，含 `SKILL.md`。功能上等同于 `agentskills.io` 合规 skill，但 `SKILL.md` 文件本身没有标准 YAML frontmatter。

4. **行业大汇聚。** Claude Code、Claude Agent SDK、Claude API（`container.skills[]` 参数），以及第三方 agent 运行时都读取同样的 SKILL.md 文件夹模式。Claude API 单请求最多支持 **8 个 skill**（`container` 参数 + `beta: skills-2025-10-02` 头）。来源：[Claude API Skills 指南](https://platform.claude.com/docs/en/build-with-claude/skills-guide)。

5. **`description` 是首要触发器。** "是什么 + 何时用" 必须放进 YAML `description` 字段，不能在正文。Anthropic 编写指南：≤1024 字符，无 XML 标签，必须包含用户会说的触发短语。

### 判定：**匹配**

zsf 的 skill 格式与行业 **趋同** 但尚未与开放规范 **合规**。唯一差距是 `SKILL.md` 文件的 YAML frontmatter。

**具体行动：** 给 `.opencode/skills/` 下三个 `SKILL.md` 加 `name` 和 `description` YAML frontmatter。skill 名称已遵循 kebab-case；description 需重写以遵循 Anthropic 的"是什么 + 何时用"模式。审查 `SKILL.md` 正文长度：`superpowers` skill 正文可能 > 500 行，应拆分为被引用的子文件。

---

## 主题 3 — Spec-driven 开发

**状态：匹配；OpenSpec 是多种可行 SDD 框架之一；Microsoft Spec Kit 是主流首选。**

### 关键进展

1. **Microsoft GitHub Spec Kit 是 2026 年主流 SDD 工具链。** [github/spec-kit](https://github.com/github/spec-kit) 达到 **112,852★ / 9,961 fork / 165 次发布**；v0.11.0 于 2026-06-16 发布。生命周期：**Constitution → Specify → Clarify → Plan → Tasks → Implement → Validate**。三个斜杠命令（`/specify`、`/plan`、`/tasks`）驱动 agent。来源：[github.com/github/spec-kit](https://github.com/github/spec-kit)；[Microsoft for Developers 2025-09-15](https://developer.microsoft.com/blog/spec-driven-development-spec-kit)；[Microsoft for Developers 2026-06-10](https://developer.microsoft.com/blog/spec-driven-development-ai-native-engineering)。

2. **30+ agent 集成，105 社区扩展，22 预设。** Spec Kit 兼容 Copilot、Gemini CLI、Codex、Windsurf、Zed、Claude Code、Forge、Kiro 等。社区已构建完全不同的 SDD 流程（AIDE 7 步、Canon 基线驱动、Product Forge PM 导向、FX→.NET 迁移、MAQA 多 agent QA）。来源：[Spec Kit 文档](https://github.github.com/spec-kit/)。

3. **Constitution 阶段是差异化所在。** "Constitution"（原则、标准、护栏）是 Spec Kit 最被低估的部分，最接近你的"三条铁律"/"代码优先链"/"小任务原则"。跳过 Constitution 的团队漂移最快。

4. **OpenSpec CLI v1.4.1（你的选择）也是可行替代。** OpenSpec 设计更轻量，更贴近 FOSS CLI 工作流。你的项目 `openspec/specs/` + `openspec/changes/{id}/` 映射在概念上等同于 Spec Kit 的 `spec.md` + `plan.md` + `tasks.md`，外加显式门禁执行（Proposal → Design → Review → Archive）。

5. **其他 spec-driven 工具尚未汇聚。**
   - **OpenAPI / AsyncAPI** 是 API 契约规范，不是完整 SDD 生命周期。位于不同层。
   - **Pydantic AI** 是类型安全 LLM agent 构建框架，不是 spec-driven 方法论。
   - **AWS Kiro** 是闭源 agentic IDE，实现自有的 spec-driven 流程。

   OpenSpec 最近的开放竞品就是 **Fission AI 的 OpenSpec**（即 zsf 用的）；Spec Kit 是参考标杆。两者共享 80% 概念模型。最大差异：Spec Kit 自带斜杠命令，OpenSpec 需要用户编写工作流 skill。

### 判定：**架构匹配**，**采用面滞后**（Microsoft 生态 100× 于 zsf）。

**具体行动：**
- 显式文档化你的"Constitution"。三条铁律 + 代码优先链 + 小任务原则正是 Spec Kit 所说的 `constitution.md`；将它们升级为 `openspec/` 下的首类工件。
- 考虑写一个薄兼容垫片，让 `spec-kit` 风格的 `/specify` 斜杠命令能跑在 OpenSpec CLI 上。让已经熟悉 Spec Kit 操作习惯的团队可平滑迁移到 zsf。

---

## 主题 4 — Agent 验证模式

**状态：哲学匹配；自动化滞后（无 Stop-hook 风格确定性门禁）。**

### 关键进展

1. **"给 Claude 一种验证自己工作的方法"是 Anthropic 头号最佳实践。** 来自 [code.claude.com/docs/en/best-practices](https://code.claude.com/docs/en/best-practices)："给 Claude 一个产出通过或失败的东西，循环自然闭合。" 四种门禁类型：prompt 内、`/goal` 条件、**确定性 Stop hook**、第二意见 subagent。Stop hook 阻挡回合结束直到检查通过；连续 8 次阻挡后 Claude 强制覆写。

2. **Vercel 工程手册 TDD 模式（2026-05）。** 红到绿循环必须 < 2 分钟。"不要改测试" 的 pin 原则：没有它，Claude 会放松断言以匹配错误实现。测试必须测契约而非调用图（`expect(fn).toHaveBeenCalledWith(...)` 是一种异味）。来源：[engineering-playbook.vercel.app/claude-code/test-driven-development](https://engineering-playbook.vercel.app/claude-code/test-driven-development)。

3. **Opus 4.7 的 `/go` skill 是典范的"验证优先"模式。** Anthropic 工程师 Boris Cherny 的工作流：一个 30 行自定义 skill 放在 `.claude/skills/ /SKILL.md`，串起"端到端测试 → 跑 `/simplify` → 提 PR"。`/simplify` 派生并行审查 subagent 检查变更代码的复用、质量、效率、CLAUDE.md 合规性。来源：[aitoolskit.io 2026-04-16](https://www.aitoolskit.io/news/claude-opus-4-7-claude-code-workflow-boris-cherny-2026)；[ai.georgeliu.com 2026-04-17](https://ai.georgeliu.com/p/six-things-to-change-in-your-claude)。

4. **Cognition Devin 拥有最工业级的验证闭环。** Devin Review（2026-01）不只是标记 bug 的代码审查工具——**它通过逐项修复发现来闭合循环，直到 diff 干净为止。** Devin Test 模式（2026）要求在跑任何测试前先有**基于源码的测试计划**；这是"预对齐"模式，防止 agent 在测试中途"发现遗漏"。来源：[cognition.ai/blog/testing-development](https://cognition.ai/blog/testing-development)；[aidevsetup.com 2026-03-19](https://aidevsetup.com/insider/devin-closes-the-feedback-loop-autonomous-code-review-integration)。

5. **SWE-agent / mini-SWE-agent — SWE-bench 上的开源 SOTA。** Mini-SWE-agent 在 SWE-bench Verified 跑出 **>74%，代码量 ~100 行 Python**；SWE-agent 1.0 + Claude 3.7 在完整 SWE-bench 持有开源权重 SOTA。关键洞察：可靠的验证器必须"奖励真实修复而拒绝伪造方案，且足够健壮以应对执行中的变数和基础设施抖动。" 来源：[princeton-nlp/SWE-agent](https://github.com/princeton-nlp/SWE-agent)；[swebench.com](https://www.swebench.com/)。

### 判定：**哲学匹配，自动化滞后**

zsf 的三条铁律（verification-before-completion、test-driven-development、systematic-debugging）**正是** 2026 年最佳实践同样的纪律。zsf 还没有的是 *自动化层* —— 没有 Stop hook、没有 `/simplify` 风格并行审查器、BUILD 启动前没有首类"基于源码的测试计划"要求。

**具体行动：**
- 加一个 **Stop hook**（OpenCode 通过插件系统支持，像你的 `graphify.js` 一样），跑配置好的测试命令并在回合结束前阻止失败。这是单一最高杠杆改动。
- 对 SSD 固件，定义一个类比 Devin test plan 的 "BUILD 完成门禁"：agent 必须先读相关源码，枚举要跑的测试用例，在执行前获得人类批准。这对 Path B（硬件依赖）代码至关重要——"看起来完成"是误导信号。
- 考虑把 `/simplify` 类比写成一个 skill：并行审查模式，diff 变更与 spec 并标记偏差。

---

## 主题 5 — 知识图谱 + AST 应用于 AI

**状态：在小众赛道领跑。** Graphify + CodeGraph 覆盖"god nodes / 社区结构"轴；2026 生态在补"实时 / MCP 服务"轴。

### 关键进展

1. **赛道正在爆发 —— 几乎所有新工具都用同一套栈。** Tree-sitter AST + 知识图谱 + MCP server + 混合（BM25 + 向量）搜索 + PageRank。模式已经清楚。值得注意的新进入者（均为 2026）：
   - [cortex-works/cortex-ast](https://github.com/cortex-works/cortex-ast) — Rust MCP server，34 种语言，AST 时间旅行，可热重载 WASM 解析器
   - [ajankurjain/central-code-knowledge-graph](https://github.com/ajankurjain/central-code-knowledge-graph) — Neo4j + Tree-sitter + MCP，多仓库，GraphQL + REST
   - [distillation-labs/contextro](https://github.com/distillation-labs/contextro) — 本地 MCP，PageRank 加权调用图，"图谱共识增强"
   - [Charan-place/ASTra-MCP](https://github.com/Charan-place/ASTra-MCP) — 声称 98.9% token 削减，NetworkX + Personalized PageRank
   - [optave/ops-codegraph-tool](https://github.com/optave/ops-codegraph-tool) — 30 个 MCP 工具，34 种语言，数据流 + CFG + 协同变更分析
   - [sdsrss/code-graph-mcp](https://github.com/sdsrss/code-graph-mcp) — 语义搜索，HTTP 路由追踪，影响分析
   - [the-muses-ltd/GraphRepo](https://github.com/the-muses-ltd/GraphRepo) — Graphology 内存图谱 + Louvain 社区检测 + Transformers.js

2. **新赢家的公式是"图 + MCP"而非"图 + CLI"。** 上面 6 个新工具全部带 MCP server。MCP server 接口才是让代码图谱 *可被 agent 消费* 的关键——agent 查询图谱而不是 grep/Read/循环。来源：[MCP 协议](https://modelcontextprotocol.io)（Anthropic，2025-12-09 捐赠给 AAIF）。

3. **语义漂移 / 时序图谱是新功能。** ASTra MCP 的"时序知识图谱"追踪调用关系在 git 历史中的 *变化*，支持编辑前风险评分（`get_volatility`、`semantic_audit`）。这是继静态图谱之后的下一维度。

4. **Vercel 正在发布"agent 编程语言"** — [ZeroLang](https://www.aitoolskit.io/news/claude-opus-4-7-claude-code-workflow-boris-cherny-2026) — 暗示业界也在反思通用编程语言是否还是 agent 上下文的合适单位。值得观察。

5. **Graphify 是列表中唯一为"整 monorepo 图谱 + 自然语言可查询"优化的工具。** 大多数竞品聚焦单仓库 + MCP 查询接口。Graphify 的 `query` / `path` / `explain` CLI 是其独特定位。

### 判定：**概念领先，接口滞后**

Graphify 的 `query`/`path`/`explain` CLI 独一无二，与 MCP server 模式互补。2026 生态正向"MCP server + tree-sitter"作为 *接口* 收敛；Graphify 是 *后端*，概念模型最佳（god nodes、社区、跨文件关系）。

**具体行动：**
- 给 Graphify 加 MCP server 接口，让 agent 直接调 `graphify.query` 而非 shell CLI。你的 `AGENTS.md` 已经在引导 agent "优先用 `graphify query \" \"`"——MCP 接口会让这一步快 10×。
- 加"时序图谱"/"语义漂移"特性：追踪图谱在 git 版本间的变化。2026 生态正从"静态图谱"走向"了解历史的图谱"。
- 考虑把 Louvain 社区检测的输出作为 CLI 的首类概念暴露（GraphRepo 思路），因为 god nodes 和模块边界正是 SSD 固件团队需要理解的。

---

## 主题 6 — Context Engineering

**状态：滞后。** zsf 没有首类 context-engineering 层。

### 关键进展

1. **Anthropic 的三个原语已成行业标准。** 来自 [Claude Cookbook 2026-03-20](https://platform.claude.com/cookbook/tool-use-context-engineering-context-engineering-tools) 和 [Anthropic 工程博客 2025-09-29](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents)：
   - **Compaction** = 全会话操作；摘要窗口，用摘要重新初始化。一等 API：`compact_20260112`。
   - **Tool-result clearing** = 子会话操作；将过期的 `tool_result` 块替换为占位符，保留 `tool_use` 记录。一等 API：`clear_tool_uses`。
   - **Memory** = 跨窗口持久化；agent 写 NOTES.md，重置后读回。

   心智模型："compaction 压缩整窗口，clearing 丢弃窗口内可重取的过期数据，memory 把信息搬出窗口使其跨会话存活。"

2. **Claude Code 在 95% 上下文窗口时自动 compact**，使用默认摘要 prompt；用户可通过 `compact_20260112` API 的 `instructions` 参数覆盖。默认阈值：150K tokens，最小 50K。来源：[Claude API compaction 文档](https://platform.claude.com/docs/en/build-with-claude/compaction)。

3. **"更大的上下文窗口无用。"** Anthropic 的明确立场："可预见的未来，所有尺寸的上下文窗口都会受上下文污染和信息相关性影响。" 2026 年共识是上下文 *质量* 重要于 *数量*。Vercel 关于 AGENTS.md-vs-skills 的研究（33/33 vs 31/33）是首个公开证据。

4. **Subagent 是新"隔离"原语。** LangChain 的 4 桶模型（write、select、compress、isolate）被广泛采纳。Anthropic 自家定位："比 chat 多用 15× tokens" 用于多 agent —— 显式的权衡警告。来源：[LangChain 博客 2025-07-02](https://www.langchain.com/blog/context-engineering-for-agents)。

5. **Opus 4.7 的自适应思考是 2026 模型级上下文原语。** [Claude Opus 4.7](https://www.anthropic.com/news/claude-opus-4-7) 用 `thinking.type.adaptive` 取代 `thinking.type.enabled` —— 模型 *按步* 决定是否思考。这把负担从 prompt 工程思考预算上移开。

### 判定：**滞后**

zsf 没有文档化的 context-engineering 层。方法论假设一个长单线程会话（Graphify query → CodeGraph explore → OpenSpec propose → Superpowers TDD）；没有文档化的 compaction、clearing 或 memory 原语。

**具体行动：**
- 在 `SSD_Firmware_AI_Copilot_Methodology.md` 加显式"context engineering"章节，定义：何时用 OpenSpec 的 NOTES.md 类便笺（"memory"类比）、何时建议人工 `/clear`（"clearing"类比）、agent 应何时向 `openspec/changes/{id}/.handoff.md` 写结构化"会话交接"（"compaction"类比）。
- 让你的 `graphify.js` 插件提供 *select* 类上下文 —— agent 提问时，Graphify 应只返回相关子图，而非整图谱。这是 LangChain 分类法中的"select"原语。
- 文档化 Opus 4.7 自适应思考模式：在长 SSD 固件会话中，让模型决定何时思考，而非手工调 `thinking.type.enabled`。

---

## 跨主题建议

### 采用（具体、高杠杆）

1. **将"Constitution"升级为首类工件。** 把三条铁律 + 代码优先链 + 小任务原则移到 `openspec/constitution.md`（或同等位置）。这是 Microsoft Spec Kit 所说的"最常被跳过、最重要的部分"，而你的规则已经写好。

2. **给三个 `SKILL.md` 文件加 YAML frontmatter**（仅 `name` 和 `description`）。让 skill 符合 `agentskills.io` 开放规范，为 Claude Code 预先铺路，并启用基于用户 prompt 的自动触发。

3. **在 `.opencode/plugins/` 构建 Stop-hook gate 插件**（紧挨着 `graphify.js`），在回合结束前跑配置好的测试命令。这是 zsf 声明的纪律与自动化之间的最大差距。没有它，"完成前验证"仍只是手动步骤。

### 避免（具体风险）

1. **不要像 Spec Kit 那样交付 30+ agent 集成。** Spec Kit 之所以有 30+ 集成，因为它没有自己的方法论 —— 是斜杠命令上的薄层。zsf 的价值在四工具方法论，不在集成数。

2. **不要用 Spec Kit 替换 OpenSpec CLI。** OpenSpec 更轻量，有显式门禁执行，团队已部署。Spec Kit 112K★ 的星数虽亮，不代表它对 SSD 固件更优 —— 用户群是通用 Web/企业，不是嵌入式。

3. **不加更多图谱工具（CodeGraph、Graphify、contextro、ASTra）而不先整合。** 2026 生态碎片化；选一个后端用 MCP 暴露才是赢面。Graphify + CodeGraph 已经是强后端。下一步是 MCP 接口，不是第三个工具。

### 关注清单（3-6 个月）

- **MCP 采用曲线。** MCP 已是 Linux Foundation 项目。预计所有图谱/知识工具都会汇聚到 MCP 作为标准接口。
- **Anthropic Skills 跨厂商采用。** 若 `agentskills.io` 被 Codex、Cursor、Copilot 等采纳（目前仅 Claude），zsf 的 `SKILL.md` skills 将跨平台可移植。
- **Spec Kit 的 "constitution.md" 模式。** Microsoft 在 2026 版本给 Constitution 阶段加更多权重。zsf 应与该术语对齐。
- **ZeroLang / agent 原生语言。** Vercel 的发布是可能的信号转变——agent 原生 DSL 若流行，方法论（不是代码）成为真相来源——这正是 zsf 假设的。
- **SWE-rebench vs SWE-bench。** [arXiv 2510.08996](https://arxiv.org/html/2510.08996v2) "Saving SWE-Bench" 论文显示现有基准高估 agent 能力约 20%。现实评估正向"全新、专有、突变驱动"任务倾斜。若对 zsf 做基准测试，优先 SWE-rebench。

---

## 来源（完整引用列表）

### AGENTS.md

- [Linux Foundation / Agentic AI Foundation 发布（2025-12-09）](https://tessl.io/blog/openai-anthropic-and-others-unite-behind-agentic-ai-foundation-for-open-standards/)
- [CIO Dive 报道 AAIF 发布（2025-12-10）](https://www.ciodive.com/news/big-tech-develop-open-standards-agentic-ai/807608/)
- [agents.md 官方](https://agents.md/)
- [agentsmd/agents.md 参考仓库（22K★）](https://github.com/agentsmd/agents.md)
- [AgentMarketCap 6 万采用分析（2026-04-17）](https://agentmarketcap.ai/blog/2026/04/17/agents-md-60k-adoption-aaif-donation-standards-floor)
- [EarlyTerms AGENTS.md 约定](https://earlyterms.com/term/agents-md)
- [Ry Walker AGENTS.md 标准研究](https://rywalker.com/research/agents-md-standard)
- [Anthropic Claude Code AGENTS.md 特性请求 #6235](https://github.com/anthropics/claude-code)

### Skills

- [Anthropic 工程博客，Agent Skills（2025-10-16）](https://www.anthropic.com/engineering/equipping-agents-for-the-real-world-with-agent-skills)
- [Anthropic 完整技能构建指南（PDF）](https://resources.anthropic.com/hubfs/The-Complete-Guide-to-Building-Skill-for-Claude.pdf)
- [Anthropic Skills 参考仓库](https://github.com/anthropics/skills)
- [agentskills.io 官方规范](https://agentskills.io/specification)
- [agentskills/agentskills 规范仓库（20K★）](https://github.com/agentskills/agentskills)
- [Claude API Skills 指南](https://platform.claude.com/docs/en/build-with-claude/skills-guide)
- [Claude Agent SDK Skills 文档](https://code.claude.com/docs/en/agent-sdk/skills)

### Spec-driven 开发

- [github/spec-kit（112K★）](https://github.com/github/spec-kit)
- [Microsoft for Developers，Spec Kit 发布（2025-09-15）](https://developer.microsoft.com/blog/spec-driven-development-spec-kit)
- [Microsoft for Developers，SDD 作为 AI 原生工程（2026-06-10）](https://developer.microsoft.com/blog/spec-driven-development-ai-native-engineering)
- [GitHub Blog，Spec Kit 开源工具包（2025-09-02）](https://github.blog/ai-and-ml/generative-ai/spec-driven-development-with-ai-get-started-with-a-new-open-source-toolkit/)
- [Spec Kit 文档](https://github.github.com/spec-kit/)
- [Visual Studio Magazine，Spec Kit 生态扩张（2026-05-12）](https://visualstudiomagazine.1105cms01.com/articles/2026/05/12/github-spec-kit-takes-off-as-antidote-to-piecemeal-vibe-coding.aspx)

### Agent 验证

- [Claude Code 最佳实践](https://code.claude.com/docs/en/best-practices)
- [Vercel Claude Code TDD 手册（2026-05-17）](https://engineering-playbook.vercel.app/claude-code/test-driven-development)
- [Vercel Claude Code bug hunting](https://engineering-playbook.vercel.app/claude-code/bug-hunting)
- [Claude Opus 4.7 最佳实践（2026-04-16）](https://claude.com/blog/best-practices-for-using-claude-opus-4-7-with-claude-code)
- [Claude Opus 4.7 介绍（2026-04-16）](https://www.anthropic.com/news/claude-opus-4-7)
- [Six Things to Change in Your Claude Code Workflow（2026-04-17）](https://ai.georgeliu.com/p/six-things-to-change-in-your-claude)
- [Boris Cherny / Anthropic 工程师工作流](https://www.aitoolskit.io/news/claude-opus-4-7-claude-code-workflow-boris-cherny-2026)
- [Cognition / Devin：大规模测试](https://cognition.ai/blog/testing-development)
- [Cognition / Devin：闭合 agent 反馈循环（自动修复审查意见）](https://aidevsetup.com/insider/devin-closes-the-feedback-loop-autonomous-code-review-integration)
- [SWE-agent（Princeton，NeurIPS 2024）](https://github.com/princeton-nlp/SWE-agent)
- [mini-SWE-agent 74% on SWE-bench Verified](https://www.swebench.com/)
- [arXiv 2510.08996，Saving SWE-Bench（基准突变）](https://arxiv.org/html/2510.08996v2)
- [Chris Dzombak：从 Claude Code 拿好结果](https://www.dzombak.com/blog/2025/08/getting-good-results-from-claude-code/)
- [SFEIR Claude Code 调试指南](https://institute.sfeir.com/en/claude-code/claude-code-advanced-best-practices/debugging/)
- [Claude Kit：TDD + systematic debugging + verification](https://duthaho.github.io/claudekit/workflows/testing-and-debugging/)
- [pytest-claude-agent-sdk](https://github.com/amyodov/pytest-claude-agent-sdk)
- [Claude Lab：自定义自治 agent 循环](https://claudelab.net/en/articles/claude-code/claude-code-sdk-custom-autonomous-agent-loop-guide)

### 知识图谱 / AST

- [cortex-works/cortex-ast](https://github.com/cortex-works/cortex-ast)
- [ajankurjain/central-code-knowledge-graph](https://github.com/ajankurjain/central-code-knowledge-graph)
- [distillation-labs/contextro](https://github.com/distillation-labs/contextro)
- [Charan-place/ASTra-MCP](https://github.com/Charan-place/ASTra-MCP)
- [optave/ops-codegraph-tool](https://github.com/optave/ops-codegraph-tool)
- [sdsrss/code-graph-mcp](https://github.com/sdsrss/code-graph-mcp/)
- [the-muses-ltd/GraphRepo](https://github.com/the-muses-ltd/GraphRepo)
- [safishamsi/graphify](https://github.com/safishamsi/graphify/)

### Context Engineering

- [Anthropic：AI agent 的有效 context engineering（2025-09-29）](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents)
- [Anthropic：为 AI agent 编写有效工具（2025-09-11）](https://www.anthropic.com/engineering/writing-tools-for-agents)
- [Claude Cookbook：memory、compaction、tool clearing（2026-03-20）](https://platform.claude.com/cookbook/tool-use-context-engineering-context-engineering-tools)
- [Claude API compaction 文档](https://platform.claude.com/docs/en/build-with-claude/compaction)
- [Anthropic cookbook：automatic-context-compaction.ipynb](https://github.com/anthropics/claude-cookbooks/blob/main/tool_use/automatic-context-compaction.ipynb)
- [LangChain：agent 的 context engineering（2025-07-02）](https://www.langchain.com/blog/context-engineering-for-agents)
- [01.me：Claude 的 Context Engineering 秘密（2025-12-01）](https://01.me/en/2025/12/context-engineering-from-claude/)
- [Cohere North Mini Code（Artificial Analysis Coding Index 33.4 分，2026-06-11）](https://www.marktechpost.com/2026/06/11/meet-north-mini-code-coheres-30b-open-weight-mixture-of-experts-model-with-3b-active-parameters-for-agentic-coding/)
- [StartupHub.ai 关于 SWE-rebench（2026-06-04）](https://www.startuphub.ai/ai-news/ai-research/2026/evaluating-coding-agents-lessons-from-swe-rebench)
- [Open-Source Coding Agents 2026（DEV）](https://dev.to/jovan_chan_9500711396d4e6/open-source-coding-agents-2026-which-one-to-run-5g14)
