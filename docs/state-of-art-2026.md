# State of AI-Assisted Programming — Late 2025 / 2026 Survey

**Date:** 2026-06-18
**Scope:** External state of the art vs. zsf methodology (OpenSpec + Superpowers + CodeGraph + Graphify)
**Method:** 11 parallel web searches against primary sources (Anthropic, OpenAI, Microsoft, Princeton/SWE-agent, Cognition/Devin, Vercel, GitHub Blog, InfoQ, agentskills.io, agents.md, plus six new graph/knowledge-MCP tools)

> **TL;DR — zsf is well-positioned.** It already implements the four pillars of 2026 best practice (AGENTS.md, skills, spec-driven, graph-based KNOW). The biggest gaps are around *context engineering* (no first-class compaction/clearing/memory layer) and *agent verification automation* (the three iron rules are documented but no deterministic Stop-hook gate). Microsoft's Spec Kit is the only mainstream competitor that has shipped a comparable end-to-end SDD pipeline (112K★, 165 releases), and its design converges on what zsf already does — adoption is the differentiator, not architecture.

---

## Topic 1 — AGENTS.md as emerging standard

**Status: matches / on the leading edge** (you already have an `AGENTS.md`; vendor support is now default).

### Key developments (late 2025 → 2026)

1. **Linux Foundation stewardship, Dec 9 2025.** OpenAI and Anthropic jointly donated AGENTS.md to the newly formed **Agentic AI Foundation (AAIF)**, alongside Anthropic's MCP and Block's Goose. Platinum members: OpenAI, Anthropic, Block. Supporting: Google, Microsoft, AWS, Bloomberg, Cloudflare. The standard is no longer a single-vendor artifact. Source: [tessl.io blog, 2025-12-09](https://tessl.io/blog/openai-anthropic-and-others-unite-behind-agentic-ai-foundation-for-open-standards/); [CIO Dive, 2025-12-10](https://www.ciodive.com/news/big-tech-develop-open-standards-agentic-ai/807608/).

2. **60,000+ repos, 22K★ reference repo, 837-point HN launch.** AGENTS.md went from 0 → 60K in ~8 months. Reference repo at [github.com/agentsmd/agents.md](https://github.com/agentsmd/agents.md) (22,184★ as of survey). The convention is "plain markdown, no custom syntax, vendor-neutral, automatic nearest-file discovery."

3. **Multi-vendor native support.** Codex, Cursor, GitHub Copilot, Gemini CLI, Google Jules, VS Code agent mode, Aider, Zed, Warp, RooCode, Devin, Amp (Sourcegraph), Junie, opencode, UiPath Autopilot, Factory CLI. **The only major holdout is Anthropic's Claude Code**, which still prioritizes `CLAUDE.md` (open issue #6235 is among the most-reacted). Source: [agents.md](https://agents.md/), [AgentMarketCap 2026-04-17](https://agentmarketcap.ai/blog/2026/04/17/agents-md-60k-adoption-aaif-donation-standards-floor).

4. **Vercel eval: AGENTS.md beats skills 33/33 vs 31/33** (Jan 29 2026). The first public, head-to-head measurement: always-in-context instructions outperform on-demand skill triggers for facts the agent will need. Source: [EarlyTerms, AGENTS.md conventions](https://earlyterms.com/term/agents-md); [Vercel blog, cited in EarlyTerms].

5. **GitHub 2,500-repo study (Nov 2025).** Empirical answer to "how to write a great AGENTS.md" — sections, length, and command blocks that actually correlate with agent success. Source: [github.blog, cited in EarlyTerms](https://github.blog/ai-and-ml/generative-ai/spec-driven-development-with-ai-get-started-with-a-new-open-source-toolkit/).

### Verdict: **leads**

zsf already ships an AGENTS.md that is in the standard format. Because the AAIF spec mandates "nearest file wins" semantics, you can drop subdirectory `AGENTS.md` files in `openspec/` and `docs/` to scope per-area instructions. **Concrete action:** the current 52-line `AGENTS.md` is good but doesn't yet use the consensus section ordering (Dev / Testing / PR instructions) — consider aligning to the `agentsmd/agents.md` example template.

---

## Topic 2 — Skills: Anthropic Skills vs. OpenCode Skills vs. plain markdown

**Status: matches the emerging open standard** (your `.opencode/skills/` is a SKILL.md-style skill set, but the project is not yet exposed via the open `agentskills.io` spec).

### Key developments

1. **Anthropic Agent Skills spec is now an open standard at [agentskills.io](https://agentskills.io/specification)** (released Oct 16 2025; spec hosted in [github.com/agentskills/agentskills](https://github.com/agentskills/agentskills), 20K★). A skill is a folder with `SKILL.md` (YAML frontmatter: `name`, `description`; optional `license`, `compatibility`, `metadata`, `allowed-tools`) plus optional `scripts/`, `references/`, `assets/`. The format is implementation-agnostic.

2. **Progressive disclosure is the dominant design pattern.** Three load levels: (1) metadata ≈100 tokens, always in context; (2) `SKILL.md` body < 5000 tokens, loaded on activation; (3) bundled resources, loaded as needed. **Anthropic's hard rule: `SKILL.md` < 500 lines**; split into referenced files. Source: [Anthropic engineering blog, 2025-10-16](https://www.anthropic.com/engineering/equipping-agents-for-the-real-world-with-agent-skills); [Anthropic Complete Guide PDF](https://resources.anthropic.com/hubfs/The-Complete-Guide-to-Building-Skill-for-Claude.pdf).

3. **OpenCode's `.opencode/skills/` uses the same pattern** but predates the public spec. Your project already has three skills (`openspec-workflow`, `sd-firmware-copilot`, `superpowers`), each as a directory under `.opencode/skills/` with a `SKILL.md`. They are functionally equivalent to `agentskills.io`-compliant skills, but their `SKILL.md` files don't carry the standard YAML frontmatter.

4. **Convergence across the industry.** Claude Code, the Claude Agent SDK, the Claude API (`container.skills[]` parameter), and third-party agent runtimes all read the same folder-of-SKILL.md pattern. The Claude API supports up to **8 skills per request** via the `container` parameter with a `beta: skills-2025-10-02` header. Source: [Claude API Skills guide](https://platform.claude.com/docs/en/build-with-claude/skills-guide).

5. **`description` is the primary trigger.** "What + when" must go in the YAML `description` field, not the body. Anthropic's authoring guide: ≤1024 chars, no XML tags, must include trigger phrases users would say.

### Verdict: **matches**

zsf's skill format is **convergent** with the industry but not yet **conformant** with the open spec. The only gap is YAML frontmatter on `SKILL.md` files.

**Concrete action:** Add `name` and `description` YAML frontmatter to the three `SKILL.md` files in `.opencode/skills/`. The skill names already follow kebab-case; descriptions need to be rewritten to follow Anthropic's "what + when" pattern. Audit `SKILL.md` body length: the `superpowers` skill body is likely > 500 lines and should be split into referenced sub-files.

---

## Topic 3 — Spec-driven development

**Status: matches; OpenSpec is one of multiple viable SDD frameworks; Microsoft Spec Kit is the dominant mainstream option.**

### Key developments

1. **Microsoft GitHub Spec Kit is the dominant 2026 SDD toolchain.** [github/spec-kit](https://github.com/github/spec-kit) reached **112,852★ / 9,961 forks / 165 releases**; v0.11.0 shipped 2026-06-16. Lifecycle: **Constitution → Specify → Clarify → Plan → Tasks → Implement → Validate**. Three slash commands (`/specify`, `/plan`, `/tasks`) drive the agent. Source: [github.com/github/spec-kit](https://github.com/github/spec-kit); [Microsoft for Developers, 2025-09-15](https://developer.microsoft.com/blog/spec-driven-development-spec-kit); [Microsoft for Developers, 2026-06-10](https://developer.microsoft.com/blog/spec-driven-development-ai-native-engineering).

2. **30+ agent integrations, 105 community extensions, 22 presets.** Spec Kit works with Copilot, Gemini CLI, Codex, Windsurf, Zed, Claude Code, Forge, Kiro, plus 23 more. Community has built completely different SDD processes (AIDE 7-step, Canon baseline-driven, Product Forge PM-oriented, FX→.NET migration, MAQA multi-agent QA). Source: [Spec Kit docs](https://github.github.com/spec-kit/).

3. **Constitution phase is the differentiator.** The "Constitution" (principles, standards, guardrails) is the most under-appreciated part of Spec Kit and is the closest analog to your "three iron rules" / "code priority chain" / "small task principle." Teams that skip Constitution drift fastest.

4. **OpenSpec CLI v1.4.1 (your choice) is a viable alternative.** OpenSpec's design is more lightweight and stays closer to a FOSS CLI workflow. Your project's `openspec/specs/` + `openspec/changes/{id}/` mapping is conceptually equivalent to Spec Kit's `spec.md` + `plan.md` + `tasks.md`, with the addition of explicit gate enforcement (Proposal → Design → Review → Archive).

5. **Other spec-driven tooling has not converged.**
   - **OpenAPI / AsyncAPI** are API contract specs, not full lifecycle SDD. They live at a different layer.
   - **Pydantic AI** is a framework for type-safe LLM agent construction; not a spec-driven methodology.
   - **AWS Kiro** is a closed-source agentic IDE that implements its own spec-driven flow.

   The closest open competitor to OpenSpec is **OpenSpec by Fission AI** (which is what zsf uses); [Spec Kit is the canonical reference]. The two share 80% of the conceptual model. The big difference: Spec Kit ships with slash commands; OpenSpec requires the user to write the workflow skill.

### Verdict: **matches** (architecturally), **lags on adoption surface** (Microsoft has 100× your ecosystem).

**Concrete actions:**
- Document your "Constitution" explicitly. The three iron rules + the code-priority chain + the small-task rule are exactly what Spec Kit calls `constitution.md`; promote them to a first-class artifact in `openspec/`.
- Consider writing a thin compatibility shim so a `spec-kit`-style `/specify` slash command works against OpenSpec's CLI. This would let teams adopt zsf who already know the Spec Kit ergonomics.

---

## Topic 4 — Agent verification patterns

**Status: matches on philosophy; lags on automated gating (no Stop-hook-style deterministic gate).**

### Key developments

1. **"Give Claude a way to verify its work" is the #1 Anthropic best practice.** From [code.claude.com/docs/en/best-practices](https://code.claude.com/docs/en/best-practices): "Give Claude something that produces a pass or fail, and the loop closes on its own." Four gate types: in-prompt, `/goal` condition, **deterministic Stop hook**, second-opinion subagent. The Stop hook blocks the turn from ending until the check passes; Claude overrides after 8 consecutive blocks.

2. **Vercel Engineering Playbook TDD pattern (May 2026).** Red-to-green cycle **must be < 2 minutes**. The "don't change the test" pin principle: without it, Claude will relax the assertion to match a wrong implementation. Tests must test the contract, not the call graph (`expect(fn).toHaveBeenCalledWith(...)` is a smell). Source: [engineering-playbook.vercel.app/claude-code/test-driven-development](https://engineering-playbook.vercel.app/claude-code/test-driven-development).

3. **Opus 4.7's `/go` skill is the canonical "verification-first" pattern.** Anthropic engineer Boris Cherny's workflow: a 30-line custom skill at `.claude/skills/ /SKILL.md` that chains "test end-to-end → run `/simplify` → open PR." `/simplify` spawns parallel review sub-agents to check changed code for reuse, quality, efficiency, and CLAUDE.md compliance. Source: [aitoolskit.io, 2026-04-16](https://www.aitoolskit.io/news/claude-opus-4-7-claude-code-workflow-boris-cherny-2026); [ai.georgeliu.com, 2026-04-17](https://ai.georgeliu.com/p/six-things-to-change-in-your-claude).

4. **Cognition Devin ships the most production-grade verification loop.** Devin Review (Jan 2026) is a code-review tool that doesn't just flag bugs — **it closes the loop by fixing each finding until the diff is clean.** Devin Test mode (2026) requires a **test plan grounded in source** before any test runs; this is a "pre-alignment" pattern that prevents the agent from "discovering something missing halfway through the test." Source: [cognition.ai/blog/testing-development](https://cognition.ai/blog/testing-development); [aidevsetup.com, 2026-03-19](https://aidevsetup.com/insider/devin-closes-the-feedback-loop-autonomous-code-review-integration).

5. **SWE-agent / mini-SWE-agent — the open-source SOTA on SWE-bench.** Mini-SWE-agent scores **>74% on SWE-bench Verified in ~100 lines of Python**; SWE-agent 1.0 + Claude 3.7 holds the open-weights SOTA on full SWE-bench. The key insight: a reliable verifier must "reward actual fixes while rejecting fabricated solutions, and it must be robust enough to handle variations in execution and potential infrastructure hiccups." Source: [princeton-nlp/SWE-agent](https://github.com/princeton-nlp/SWE-agent); [swebench.com](https://www.swebench.com/).

### Verdict: **matches on philosophy, lags on automation**

zsf's three iron rules (verification-before-completion, test-driven-development, systematic-debugging) **are exactly the same discipline** as the 2026 best practice. What zsf doesn't yet have is the *automation layer* — there is no Stop hook, no `/simplify`-style parallel reviewer, and no first-class "test plan grounded in source" requirement before BUILD starts.

**Concrete actions:**
- Add a **Stop hook** (OpenCode supports it via the plugin system, like your `graphify.js`) that runs a configured test command and blocks turn-end on failure. This is the single highest-leverage change.
- For SSD firmware, define a "BUILD completion gate" analogous to Devin's test plan: the agent must read the relevant source code, enumerate the test cases it will run, and get human approval before executing. This is critical for Path B (hardware-dependent) code where "looks done" is a misleading signal.
- Consider building a `/simplify` analog as a skill: a parallel-reviewer pattern that diffs the change against the spec and flags deviations.

---

## Topic 5 — Knowledge graph + AST for AI

**Status: leads the niche.** Graphify + CodeGraph covers the "god nodes / community structure" axis; the 2026 ecosystem is filling in the "real-time / MCP-served" axis.

### Key developments

1. **The space is exploding — almost every new tool uses the same stack.** Tree-sitter AST + knowledge graph + MCP server + hybrid (BM25 + vector) search + PageRank. The pattern is now obvious. Notable entries (all 2026):
   - [cortex-works/cortex-ast](https://github.com/cortex-works/cortex-ast) — Rust MCP server, 34 languages, AST time-travel, hot-reloadable WASM parsers
   - [ajankurjain/central-code-knowledge-graph](https://github.com/ajankurjain/central-code-knowledge-graph) — Neo4j + Tree-sitter + MCP, multi-repo, GraphQL + REST
   - [distillation-labs/contextro](https://github.com/distillation-labs/contextro) — local MCP, PageRank-weighted call graph, "graph consensus boosting"
   - [Charan-place/ASTra-MCP](https://github.com/Charan-place/ASTra-MCP) — 98.9% token reduction claim, NetworkX + Personalized PageRank
   - [optave/ops-codegraph-tool](https://github.com/optave/ops-codegraph-tool) — 30 MCP tools, 34 languages, dataflow + CFG + co-change analysis
   - [sdsrss/code-graph-mcp](https://github.com/sdsrss/code-graph-mcp) — semantic search, HTTP route tracing, impact analysis
   - [the-muses-ltd/GraphRepo](https://github.com/the-muses-ltd/GraphRepo) — Graphology in-memory + Louvain community detection + Transformers.js

2. **The new winning formula is "graph + MCP" not "graph + CLI."** Of the 6 new tools above, all 6 ship an MCP server. The MCP-server interface is what makes a code graph *consumable by agents* — agents query the graph instead of `grep`/`Read`/cycling. Source: the [MCP protocol](https://modelcontextprotocol.io) (Anthropic, donated to AAIF 2025-12-09).

3. **Semantic drift / temporal graphs are the new feature.** ASTra MCP's "Temporal Knowledge Graph" tracks how call relationships *change* over git history, enabling pre-edit risk scoring (`get_volatility`, `semantic_audit`). This is the next dimension beyond static graphs.

4. **Vercel is releasing a "programming language for agents"** — [ZeroLang](https://www.aitoolskit.io/news/claude-opus-4-7-claude-code-workflow-boris-cherny-2026) — which suggests the industry is also rethinking whether general-purpose languages are even the right unit of context for agents. Worth watching.

5. **Graphify is the only one in this list optimized for "graph of a whole monorepo, queryable as natural language."** Most competitors focus on a single repo and an MCP query interface. Graphify's `query` / `path` / `explain` CLI is its unique selling point.

### Verdict: **leads on concept, lags on interface**

Graphify's `query`/`path`/`explain` CLI is unique and complements the MCP-server pattern. The 2026 ecosystem is converging on "MCP server + tree-sitter" as the *interface*; Graphify is the *backend* with the best conceptual model (god nodes, communities, cross-file relationships).

**Concrete actions:**
- Add an MCP server interface to Graphify so agents can call `graphify.query` directly instead of shelling out to a CLI. Your `AGENTS.md` already nudges agents to "prefer scoped queries like `graphify query \" \"`" — an MCP interface would make this 10× faster.
- Add a "temporal graph" / "semantic drift" feature: track how the graph changes across git revisions. The 2026 ecosystem is moving from "static graph" to "graph that knows about history."
- Consider exposing the Louvain community-detection output as a first-class concept in the CLI (the GraphRepo approach), since god nodes and module boundaries are exactly what SSD firmware teams need to understand.

---

## Topic 6 — Context engineering

**Status: lags.** zsf has no first-class context-engineering layer.

### Key developments

1. **Anthropic's three primitives are now an industry standard.** From the [Claude Cookbook, 2026-03-20](https://platform.claude.com/cookbook/tool-use-context-engineering-context-engineering-tools) and [Anthropic engineering blog, 2025-09-29](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents):
   - **Compaction** = whole-transcript operation; summarize the window, reinit with summary. First-party API: `compact_20260112`.
   - **Tool-result clearing** = sub-transcript operation; replace stale `tool_result` blocks with placeholders, keep the `tool_use` record. First-party API: `clear_tool_uses`.
   - **Memory** = out-of-window persistence; agent writes NOTES.md, reads it back after reset.

   The mental model: "compaction compresses the whole window, clearing drops stale re-fetchable data inside the window, memory moves information out of the window so it survives across sessions."

2. **Claude Code auto-compacts at 95% of context window** with a default summary prompt; users can override with a custom `instructions` parameter on the `compact_20260112` API. Default threshold: 150K tokens, minimum 50K. Source: [Claude API compaction docs](https://platform.claude.com/docs/en/build-with-claude/compaction).

3. **"Larger context windows don't help."** Anthropic's explicit position: "for the foreseeable future, context windows of all sizes will be subject to context pollution and information relevance concerns." The 2026 consensus is that the *quality* of context matters more than the *quantity*. The Vercel research on AGENTS.md-vs-skills (33/33 vs 31/33) is the first published evidence.

4. **Subagents are the new "isolate" primitive.** LangChain's 4-bucket model (write, select, compress, isolate) is widely adopted. Anthropic's own positioning: "up to 15× more tokens than chat" for multi-agent — explicit trade-off warning. Source: [LangChain blog, 2025-07-02](https://www.langchain.com/blog/context-engineering-for-agents).

5. **Opus 4.7's adaptive thinking is a 2026 model-level context primitive.** [Claude Opus 4.7](https://www.anthropic.com/news/claude-opus-4-7) replaces `thinking.type.enabled` with `thinking.type.adaptive` — the model decides *per step* whether to think. This shifts the burden away from prompt-engineering the thinking budget.

### Verdict: **lags**

zsf has no documented context-engineering layer. Your methodology assumes a long single-thread conversation (Graphify query → CodeGraph explore → OpenSpec propose → Superpowers TDD); there is no documented compaction, clearing, or memory primitive.

**Concrete actions:**
- Add an explicit "context engineering" section to `SSD_Firmware_AI_Copilot_Methodology.md` that defines: when to use OpenSpec's NOTES.md-like scratchpad (analog of "memory"), when to suggest a manual `/clear` (analog of "clearing"), and when the agent should write a structured "session handoff" to `openspec/changes/{id}/.handoff.md` (analog of "compaction").
- Wire your `graphify.js` plugin to provide *select*-style context — when an agent asks a question, Graphify should return only the relevant subgraph, not the whole graph. This is the "select" primitive in LangChain's taxonomy.
- Document the Opus 4.7 adaptive thinking pattern: in long SSD firmware sessions, let the model decide when to think rather than tuning `thinking.type.enabled` manually.

---

## Cross-cutting recommendations

### Adopt (concrete, high-leverage)

1. **Promote the "Constitution" to a first-class artifact.** Move the three iron rules + the code-priority chain + the small-task rule to `openspec/constitution.md` (or equivalent). This is what Microsoft Spec Kit calls the most-skipped, most-important part of SDD, and your rules are already written.

2. **Add YAML frontmatter to your three `SKILL.md` files** (just `name` and `description`). This makes your skills compliant with the `agentskills.io` open spec, future-proofs them for Claude Code, and enables auto-trigger based on user prompt.

3. **Build a Stop-hook gate plugin** in `.opencode/plugins/` (alongside `graphify.js`) that runs a configured test command before turn-end. This is the single biggest gap between zsf's stated discipline and its automation. Without it, "verification before completion" is still a manual step.

### Avoid (concrete risks)

1. **Don't try to ship 30+ agent integrations like Spec Kit.** Spec Kit has 30+ integrations because it has no methodology of its own — it's a thin layer over slash commands. zsf's value is the four-tool methodology, not integration count.

2. **Don't replace OpenSpec CLI with Spec Kit.** OpenSpec is more lightweight, has explicit gate enforcement, and your team already has it deployed. Spec Kit's 112K★ star count is impressive but doesn't mean it's a better tool for SSD firmware — the user base is general web/enterprise, not embedded systems.

3. **Don't add more graph tools (CodeGraph, Graphify, contextro, ASTra) without consolidating.** The 2026 ecosystem is fragmented; choosing a single backend and exposing it via MCP is the winning play. Graphify + CodeGraph is already a strong backend. The next step is an MCP interface, not a third tool.

### Watchlist (3-6 months)

- **MCP adoption curve.** MCP is now a Linux Foundation project. Expect all graph/knowledge tools to converge on MCP as the standard interface.
- **Anthropic Skills cross-vendor adoption.** If `agentskills.io` is adopted by Codex, Cursor, Copilot, etc. (currently only Claude), zsf's `SKILL.md` skills become cross-platform portable.
- **Spec Kit's "constitution.md" pattern.** Microsoft is putting more weight on the Constitution phase in 2026 releases. Your zsf should align with this terminology.
- **ZeroLang / agent-native languages.** Vercel's release signals a possible shift away from general-purpose languages as the unit of agent context. If agent-native DSLs gain traction, the methodology (not the code) becomes the source of truth — which is what zsf already assumes.
- **SWE-rebench vs SWE-bench.** The [arXiv 2510.08996](https://arxiv.org/html/2510.08996v2) "Saving SWE-Bench" paper shows existing benchmarks overestimate agent capability by ~20%. Real-world evaluation is shifting toward "fresh, private, mutation-based" tasks. If you're benchmarking zsf, prefer SWE-rebench.

---

## Sources (full citation list)

### AGENTS.md
- [Linux Foundation / Agentic AI Foundation announcement (2025-12-09)](https://tessl.io/blog/openai-anthropic-and-others-unite-behind-agentic-ai-foundation-for-open-standards/)
- [CIO Dive on AAIF launch (2025-12-10)](https://www.ciodive.com/news/big-tech-develop-open-standards-agentic-ai/807608/)
- [agents.md official](https://agents.md/)
- [agentsmd/agents.md reference repo (22K★)](https://github.com/agentsmd/agents.md)
- [AgentMarketCap 60K adoption analysis (2026-04-17)](https://agentmarketcap.ai/blog/2026/04/17/agents-md-60k-adoption-aaif-donation-standards-floor)
- [EarlyTerms AGENTS.md conventions](https://earlyterms.com/term/agents-md)
- [Ry Walker research on AGENTS.md standard](https://rywalker.com/research/agents-md-standard)
- [Anthropic Claude Code AGENTS.md feature request #6235](https://github.com/anthropics/claude-code)

### Skills
- [Anthropic engineering blog, Agent Skills (2025-10-16)](https://www.anthropic.com/engineering/equipping-agents-for-the-real-world-with-agent-skills)
- [Anthropic Complete Guide to Building Skills (PDF)](https://resources.anthropic.com/hubfs/The-Complete-Guide-to-Building-Skill-for-Claude.pdf)
- [Anthropic Skills reference repo](https://github.com/anthropics/skills)
- [agentskills.io official spec](https://agentskills.io/specification)
- [agentskills/agentskills spec repo (20K★)](https://github.com/agentskills/agentskills)
- [Claude API Skills guide](https://platform.claude.com/docs/en/build-with-claude/skills-guide)
- [Claude Agent SDK Skills docs](https://code.claude.com/docs/en/agent-sdk/skills)

### Spec-driven dev
- [github/spec-kit (112K★)](https://github.com/github/spec-kit)
- [Microsoft for Developers, Spec Kit launch (2025-09-15)](https://developer.microsoft.com/blog/spec-driven-development-spec-kit)
- [Microsoft for Developers, SDD as AI-native engineering (2026-06-10)](https://developer.microsoft.com/blog/spec-driven-development-ai-native-engineering)
- [GitHub Blog, Spec Kit open source toolkit (2025-09-02)](https://github.blog/ai-and-ml/generative-ai/spec-driven-development-with-ai-get-started-with-a-new-open-source-toolkit/)
- [Spec Kit docs](https://github.github.com/spec-kit/)
- [Visual Studio Magazine, Spec Kit ecosystem expansion (2026-05-12)](https://visualstudiomagazine.1105cms01.com/articles/2026/05/12/github-spec-kit-takes-off-as-antidote-to-piecemeal-vibe-coding.aspx)

### Agent verification
- [Claude Code best practices](https://code.claude.com/docs/en/best-practices)
- [Vercel Claude Code TDD playbook (2026-05-17)](https://engineering-playbook.vercel.app/claude-code/test-driven-development)
- [Vercel Claude Code bug hunting](https://engineering-playbook.vercel.app/claude-code/bug-hunting)
- [Claude Opus 4.7 best practices (2026-04-16)](https://claude.com/blog/best-practices-for-using-claude-opus-4-7-with-claude-code)
- [Introducing Claude Opus 4.7 (2026-04-16)](https://www.anthropic.com/news/claude-opus-4-7)
- [Six Things to Change in Your Claude Code Workflow (2026-04-17)](https://ai.georgeliu.com/p/six-things-to-change-in-your-claude)
- [Boris Cherny / Anthropic engineering workflow](https://www.aitoolskit.io/news/claude-opus-4-7-claude-code-workflow-boris-cherny-2026)
- [Cognition / Devin: Testing at Scale](https://cognition.ai/blog/testing-development)
- [Cognition / Devin: Closing the agent loop (auto-fix review comments)](https://aidevsetup.com/insider/devin-closes-the-feedback-loop-autonomous-code-review-integration)
- [SWE-agent (Princeton, NeurIPS 2024)](https://github.com/princeton-nlp/SWE-agent)
- [mini-SWE-agent 74% on SWE-bench Verified](https://www.swebench.com/)
- [arXiv 2510.08996, Saving SWE-Bench (benchmark mutation)](https://arxiv.org/html/2510.08996v2)
- [Chris Dzombak: Getting Good Results from Claude Code](https://www.dzombak.com/blog/2025/08/getting-good-results-from-claude-code/)
- [SFEIR Claude Code debugging guide](https://institute.sfeir.com/en/claude-code/claude-code-advanced-best-practices/debugging/)
- [Claude Kit: TDD + systematic debugging + verification](https://duthaho.github.io/claudekit/workflows/testing-and-debugging/)
- [pytest-claude-agent-sdk](https://github.com/amyodov/pytest-claude-agent-sdk)
- [Claude Lab: Custom Autonomous Agent Loop](https://claudelab.net/en/articles/claude-code/claude-code-sdk-custom-autonomous-agent-loop-guide)

### Knowledge graph / AST
- [cortex-works/cortex-ast](https://github.com/cortex-works/cortex-ast)
- [ajankurjain/central-code-knowledge-graph](https://github.com/ajankurjain/central-code-knowledge-graph)
- [distillation-labs/contextro](https://github.com/distillation-labs/contextro)
- [Charan-place/ASTra-MCP](https://github.com/Charan-place/ASTra-MCP)
- [optave/ops-codegraph-tool](https://github.com/optave/ops-codegraph-tool)
- [sdsrss/code-graph-mcp](https://github.com/sdsrss/code-graph-mcp/)
- [the-muses-ltd/GraphRepo](https://github.com/the-muses-ltd/GraphRepo)
- [safishamsi/graphify](https://github.com/safishamsi/graphify/)

### Context engineering
- [Anthropic: Effective context engineering for AI agents (2025-09-29)](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents)
- [Anthropic: Writing effective tools for AI agents (2025-09-11)](https://www.anthropic.com/engineering/writing-tools-for-agents)
- [Claude Cookbook: memory, compaction, tool clearing (2026-03-20)](https://platform.claude.com/cookbook/tool-use-context-engineering-context-engineering-tools)
- [Claude API compaction docs](https://platform.claude.com/docs/en/build-with-claude/compaction)
- [Anthropic cookbook: automatic-context-compaction.ipynb](https://github.com/anthropics/claude-cookbooks/blob/main/tool_use/automatic-context-compaction.ipynb)
- [LangChain: context engineering for agents (2025-07-02)](https://www.langchain.com/blog/context-engineering-for-agents)
- [01.me: Claude's Context Engineering Secrets (2025-12-01)](https://01.me/en/2025/12/context-engineering-from-claude/)
- [Cohere North Mini Code (33.4 on Artificial Analysis Coding Index, 2026-06-11)](https://www.marktechpost.com/2026/06/11/meet-north-mini-code-coheres-30b-open-weight-mixture-of-experts-model-with-3b-active-parameters-for-agentic-coding/)
- [StartupHub.ai on SWE-rebench (2026-06-04)](https://www.startuphub.ai/ai-news/ai-research/2026/evaluating-coding-agents-lessons-from-swe-rebench)
- [Open-Source Coding Agents 2026 (DEV)](https://dev.to/jovan_chan_9500711396d4e6/open-source-coding-agents-2026-which-one-to-run-5g14)
