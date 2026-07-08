From 45027184132ce286db08007157b6dcd6ca11dddb Mon Sep 17 00:00:00 2001
From: zsf <278319027@qq.com>
Date: Wed, 8 Jul 2026 23:54:52 +0800
Subject: [PATCH] feat: import superpowers bundle and graph workflow updates

---
 .agents/skills/brainstorming/SKILL.md         |  159 ++
 .../brainstorming/scripts/frame-template.html |  213 ++
 .../skills/brainstorming/scripts/helper.js    |  167 ++
 .../skills/brainstorming/scripts/server.cjs   |  723 ++++++
 .../brainstorming/scripts/start-server.sh     |  209 ++
 .../brainstorming/scripts/stop-server.sh      |  120 +
 .../spec-document-reviewer-prompt.md          |   49 +
 .../skills/brainstorming/visual-companion.md  |  291 +++
 .../dispatching-parallel-agents/SKILL.md      |  185 ++
 .agents/skills/executing-plans/SKILL.md       |   70 +
 .../finishing-a-development-branch/SKILL.md   |  241 ++
 .agents/skills/receiving-code-review/SKILL.md |  213 ++
 .../skills/requesting-code-review/SKILL.md    |  103 +
 .../requesting-code-review/code-reviewer.md   |  172 ++
 .../subagent-driven-development/SKILL.md      |  418 +++
 .../implementer-prompt.md                     |  139 +
 .../scripts/review-package                    |   44 +
 .../scripts/sdd-workspace                     |   22 +
 .../scripts/task-brief                        |   40 +
 .../task-reviewer-prompt.md                   |  188 ++
 .../systematic-debugging/CREATION-LOG.md      |  119 +
 .agents/skills/systematic-debugging/SKILL.md  |  296 +++
 .../condition-based-waiting-example.ts        |  158 ++
 .../condition-based-waiting.md                |  115 +
 .../systematic-debugging/defense-in-depth.md  |  122 +
 .../systematic-debugging/find-polluter.sh     |   63 +
 .../root-cause-tracing.md                     |  169 ++
 .../systematic-debugging/test-academic.md     |   14 +
 .../systematic-debugging/test-pressure-1.md   |   58 +
 .../systematic-debugging/test-pressure-2.md   |   68 +
 .../systematic-debugging/test-pressure-3.md   |   69 +
 .../skills/test-driven-development/SKILL.md   |  371 +++
 .../testing-anti-patterns.md                  |  299 +++
 .agents/skills/using-git-worktrees/SKILL.md   |  202 ++
 .agents/skills/using-superpowers/SKILL.md     |   62 +
 .../references/antigravity-tools.md           |   23 +
 .../references/codex-tools.md                 |   39 +
 .../using-superpowers/references/pi-tools.md  |   16 +
 .../verification-before-completion/SKILL.md   |  139 +
 .agents/skills/writing-plans/SKILL.md         |  174 ++
 .../plan-document-reviewer-prompt.md          |   49 +
 .agents/skills/writing-skills/SKILL.md        |  689 +++++
 .../anthropic-best-practices.md               | 1150 +++++++++
 .../examples/CLAUDE_MD_TESTING.md             |  189 ++
 .../writing-skills/graphviz-conventions.dot   |  172 ++
 .../writing-skills/persuasion-principles.md   |  187 ++
 .../skills/writing-skills/render-graphs.js    |  168 ++
 .../testing-skills-with-subagents.md          |  384 +++
 .gitignore                                    |    2 +-
 CHANGELOG.md                                  |    4 +
 assets/manifest.json                          |    4 +
 assets/skills-zh/comet-design/SKILL.md        |    2 +
 assets/skills-zh/comet-verify/SKILL.md        |   12 +
 .../comet/reference/firmware-c-checklist.md   |   58 +
 .../comet/reference/firmware-profile.md       |   51 +
 assets/skills-zh/comet/reference/scripts.md   |   22 +
 assets/skills/comet-design/SKILL.md           |    2 +
 assets/skills/comet-verify/SKILL.md           |   12 +
 .../comet/reference/firmware-c-checklist.md   |   58 +
 .../comet/reference/firmware-profile.md       |   51 +
 assets/skills/comet/reference/scripts.md      |   22 +
 .../comet/scripts/comet-firmware-verify.mjs   |    3 +
 .../comet/scripts/comet-graph-context.mjs     |    3 +
 assets/skills/comet/scripts/comet-runtime.mjs | 2282 +++++++++++++----
 config/repository-layout.json                 |    4 +
 docs/architecture/ARCHITECTURE.md             |    1 +
 .../GRAPH-CONTEXT-ARCHITECTURE.md             |  233 ++
 domains/comet-classic/classic-cli.ts          |    6 +
 .../classic-firmware-verify-entry.ts          |   14 +
 .../comet-classic/classic-firmware-verify.ts  |   69 +
 .../classic-graph-context-entry.ts            |   14 +
 .../comet-classic/classic-graph-context.ts    |  212 ++
 .../comet-classic/classic-state-command.ts    |   17 +-
 domains/comet-classic/classic-state.ts        |   12 +
 .../comet-classic/classic-validate-command.ts |    7 +
 domains/comet-classic/index.ts                |    2 +
 domains/integrations/firmware-profile.ts      |  322 +++
 domains/integrations/graph-context.ts         |  737 ++++++
 domains/integrations/graphify.ts              |   60 +
 pnpm-workspace.yaml                           |    3 +
 scripts/build/build-classic-runtime.mjs       |    2 +-
 .../comet-classic/comet-scripts.test.ts       |  176 ++
 .../integrations/firmware-profile.test.ts     |   81 +
 .../integrations/graph-context.test.ts        |  298 +++
 84 files changed, 13729 insertions(+), 459 deletions(-)
 create mode 100644 .agents/skills/brainstorming/SKILL.md
 create mode 100644 .agents/skills/brainstorming/scripts/frame-template.html
 create mode 100644 .agents/skills/brainstorming/scripts/helper.js
 create mode 100644 .agents/skills/brainstorming/scripts/server.cjs
 create mode 100755 .agents/skills/brainstorming/scripts/start-server.sh
 create mode 100755 .agents/skills/brainstorming/scripts/stop-server.sh
 create mode 100644 .agents/skills/brainstorming/spec-document-reviewer-prompt.md
 create mode 100644 .agents/skills/brainstorming/visual-companion.md
 create mode 100644 .agents/skills/dispatching-parallel-agents/SKILL.md
 create mode 100644 .agents/skills/executing-plans/SKILL.md
 create mode 100644 .agents/skills/finishing-a-development-branch/SKILL.md
 create mode 100644 .agents/skills/receiving-code-review/SKILL.md
 create mode 100644 .agents/skills/requesting-code-review/SKILL.md
 create mode 100644 .agents/skills/requesting-code-review/code-reviewer.md
 create mode 100644 .agents/skills/subagent-driven-development/SKILL.md
 create mode 100644 .agents/skills/subagent-driven-development/implementer-prompt.md
 create mode 100755 .agents/skills/subagent-driven-development/scripts/review-package
 create mode 100755 .agents/skills/subagent-driven-development/scripts/sdd-workspace
 create mode 100755 .agents/skills/subagent-driven-development/scripts/task-brief
 create mode 100644 .agents/skills/subagent-driven-development/task-reviewer-prompt.md
 create mode 100644 .agents/skills/systematic-debugging/CREATION-LOG.md
 create mode 100644 .agents/skills/systematic-debugging/SKILL.md
 create mode 100644 .agents/skills/systematic-debugging/condition-based-waiting-example.ts
 create mode 100644 .agents/skills/systematic-debugging/condition-based-waiting.md
 create mode 100644 .agents/skills/systematic-debugging/defense-in-depth.md
 create mode 100755 .agents/skills/systematic-debugging/find-polluter.sh
 create mode 100644 .agents/skills/systematic-debugging/root-cause-tracing.md
 create mode 100644 .agents/skills/systematic-debugging/test-academic.md
 create mode 100644 .agents/skills/systematic-debugging/test-pressure-1.md
 create mode 100644 .agents/skills/systematic-debugging/test-pressure-2.md
 create mode 100644 .agents/skills/systematic-debugging/test-pressure-3.md
 create mode 100644 .agents/skills/test-driven-development/SKILL.md
 create mode 100644 .agents/skills/test-driven-development/testing-anti-patterns.md
 create mode 100644 .agents/skills/using-git-worktrees/SKILL.md
 create mode 100644 .agents/skills/using-superpowers/SKILL.md
 create mode 100644 .agents/skills/using-superpowers/references/antigravity-tools.md
 create mode 100644 .agents/skills/using-superpowers/references/codex-tools.md
 create mode 100644 .agents/skills/using-superpowers/references/pi-tools.md
 create mode 100644 .agents/skills/verification-before-completion/SKILL.md
 create mode 100644 .agents/skills/writing-plans/SKILL.md
 create mode 100644 .agents/skills/writing-plans/plan-document-reviewer-prompt.md
 create mode 100644 .agents/skills/writing-skills/SKILL.md
 create mode 100644 .agents/skills/writing-skills/anthropic-best-practices.md
 create mode 100644 .agents/skills/writing-skills/examples/CLAUDE_MD_TESTING.md
 create mode 100644 .agents/skills/writing-skills/graphviz-conventions.dot
 create mode 100644 .agents/skills/writing-skills/persuasion-principles.md
 create mode 100755 .agents/skills/writing-skills/render-graphs.js
 create mode 100644 .agents/skills/writing-skills/testing-skills-with-subagents.md
 create mode 100644 assets/skills-zh/comet/reference/firmware-c-checklist.md
 create mode 100644 assets/skills-zh/comet/reference/firmware-profile.md
 create mode 100644 assets/skills/comet/reference/firmware-c-checklist.md
 create mode 100644 assets/skills/comet/reference/firmware-profile.md
 create mode 100644 assets/skills/comet/scripts/comet-firmware-verify.mjs
 create mode 100644 assets/skills/comet/scripts/comet-graph-context.mjs
 create mode 100644 docs/architecture/GRAPH-CONTEXT-ARCHITECTURE.md
 create mode 100644 domains/comet-classic/classic-firmware-verify-entry.ts
 create mode 100644 domains/comet-classic/classic-firmware-verify.ts
 create mode 100644 domains/comet-classic/classic-graph-context-entry.ts
 create mode 100644 domains/comet-classic/classic-graph-context.ts
 create mode 100644 domains/integrations/firmware-profile.ts
 create mode 100644 domains/integrations/graph-context.ts
 create mode 100644 domains/integrations/graphify.ts
 create mode 100644 pnpm-workspace.yaml
 create mode 100644 test/domains/integrations/firmware-profile.test.ts
 create mode 100644 test/domains/integrations/graph-context.test.ts

diff --git a/.agents/skills/brainstorming/SKILL.md b/.agents/skills/brainstorming/SKILL.md
new file mode 100644
index 0000000..b0d52b2
--- /dev/null
+++ b/.agents/skills/brainstorming/SKILL.md
@@ -0,0 +1,159 @@
+---
+name: brainstorming
+description: "You MUST use this before any creative work - creating features, building components, adding functionality, or modifying behavior. Explores user intent, requirements and design before implementation."
+---
+
+# Brainstorming Ideas Into Designs
+
+Help turn ideas into fully formed designs and specs through natural collaborative dialogue.
+
+Start by understanding the current project context, then ask questions one at a time to refine the idea. Once you understand what you're building, present the design and get user approval.
+
+<HARD-GATE>
+Do NOT invoke any implementation skill, write any code, scaffold any project, or take any implementation action until you have presented a design and the user has approved it. This applies to EVERY project regardless of perceived simplicity.
+</HARD-GATE>
+
+## Anti-Pattern: "This Is Too Simple To Need A Design"
+
+Every project goes through this process. A todo list, a single-function utility, a config change — all of them. "Simple" projects are where unexamined assumptions cause the most wasted work. The design can be short (a few sentences for truly simple projects), but you MUST present it and get approval.
+
+## Checklist
+
+You MUST create a task for each of these items and complete them in order:
+
+1. **Explore project context** — check files, docs, recent commits
+2. **Offer the visual companion just-in-time** — NOT upfront. The first time a question would genuinely be clearer shown than described, offer it then (its own message); on approval its browser tab opens for you. If no visual question ever arises, never offer it. See the Visual Companion section below.
+3. **Ask clarifying questions** — one at a time, understand purpose/constraints/success criteria
+4. **Propose 2-3 approaches** — with trade-offs and your recommendation
+5. **Present design** — in sections scaled to their complexity, get user approval after each section
+6. **Write design doc** — save to `docs/superpowers/specs/YYYY-MM-DD-<topic>-design.md` and commit
+7. **Spec self-review** — quick inline check for placeholders, contradictions, ambiguity, scope (see below)
+8. **User reviews written spec** — ask user to review the spec file before proceeding
+9. **Transition to implementation** — invoke writing-plans skill to create implementation plan
+
+## Process Flow
+
+```dot
+digraph brainstorming {
+    "Explore project context" [shape=box];
+    "Ask clarifying questions" [shape=box];
+    "Propose 2-3 approaches" [shape=box];
+    "Present design sections" [shape=box];
+    "User approves design?" [shape=diamond];
+    "Write design doc" [shape=box];
+    "Spec self-review\n(fix inline)" [shape=box];
+    "User reviews spec?" [shape=diamond];
+    "Invoke writing-plans skill" [shape=doublecircle];
+
+    "Explore project context" -> "Ask clarifying questions";
+    "Ask clarifying questions" -> "Propose 2-3 approaches";
+    "Propose 2-3 approaches" -> "Present design sections";
+    "Present design sections" -> "User approves design?";
+    "User approves design?" -> "Present design sections" [label="no, revise"];
+    "User approves design?" -> "Write design doc" [label="yes"];
+    "Write design doc" -> "Spec self-review\n(fix inline)";
+    "Spec self-review\n(fix inline)" -> "User reviews spec?";
+    "User reviews spec?" -> "Write design doc" [label="changes requested"];
+    "User reviews spec?" -> "Invoke writing-plans skill" [label="approved"];
+}
+```
+
+**The terminal state is invoking writing-plans.** Do NOT invoke frontend-design, mcp-builder, or any other implementation skill. The ONLY skill you invoke after brainstorming is writing-plans.
+
+## The Process
+
+**Understanding the idea:**
+
+- Check out the current project state first (files, docs, recent commits)
+- Before asking detailed questions, assess scope: if the request describes multiple independent subsystems (e.g., "build a platform with chat, file storage, billing, and analytics"), flag this immediately. Don't spend questions refining details of a project that needs to be decomposed first.
+- If the project is too large for a single spec, help the user decompose into sub-projects: what are the independent pieces, how do they relate, what order should they be built? Then brainstorm the first sub-project through the normal design flow. Each sub-project gets its own spec → plan → implementation cycle.
+- For appropriately-scoped projects, ask questions one at a time to refine the idea
+- Prefer multiple choice questions when possible, but open-ended is fine too
+- Only one question per message - if a topic needs more exploration, break it into multiple questions
+- Focus on understanding: purpose, constraints, success criteria
+
+**Exploring approaches:**
+
+- Propose 2-3 different approaches with trade-offs
+- Present options conversationally with your recommendation and reasoning
+- Lead with your recommended option and explain why
+
+**Presenting the design:**
+
+- Once you believe you understand what you're building, present the design
+- Scale each section to its complexity: a few sentences if straightforward, up to 200-300 words if nuanced
+- Ask after each section whether it looks right so far
+- Cover: architecture, components, data flow, error handling, testing
+- Be ready to go back and clarify if something doesn't make sense
+
+**Design for isolation and clarity:**
+
+- Break the system into smaller units that each have one clear purpose, communicate through well-defined interfaces, and can be understood and tested independently
+- For each unit, you should be able to answer: what does it do, how do you use it, and what does it depend on?
+- Can someone understand what a unit does without reading its internals? Can you change the internals without breaking consumers? If not, the boundaries need work.
+- Smaller, well-bounded units are also easier for you to work with - you reason better about code you can hold in context at once, and your edits are more reliable when files are focused. When a file grows large, that's often a signal that it's doing too much.
+
+**Working in existing codebases:**
+
+- Explore the current structure before proposing changes. Follow existing patterns.
+- Where existing code has problems that affect the work (e.g., a file that's grown too large, unclear boundaries, tangled responsibilities), include targeted improvements as part of the design - the way a good developer improves code they're working in.
+- Don't propose unrelated refactoring. Stay focused on what serves the current goal.
+
+## After the Design
+
+**Documentation:**
+
+- Write the validated design (spec) to `docs/superpowers/specs/YYYY-MM-DD-<topic>-design.md`
+  - (User preferences for spec location override this default)
+- Use elements-of-style:writing-clearly-and-concisely skill if available
+- Commit the design document to git
+
+**Spec Self-Review:**
+After writing the spec document, look at it with fresh eyes:
+
+1. **Placeholder scan:** Any "TBD", "TODO", incomplete sections, or vague requirements? Fix them.
+2. **Internal consistency:** Do any sections contradict each other? Does the architecture match the feature descriptions?
+3. **Scope check:** Is this focused enough for a single implementation plan, or does it need decomposition?
+4. **Ambiguity check:** Could any requirement be interpreted two different ways? If so, pick one and make it explicit.
+
+Fix any issues inline. No need to re-review — just fix and move on.
+
+**User Review Gate:**
+After the spec review loop passes, ask the user to review the written spec before proceeding:
+
+> "Spec written and committed to `<path>`. Please review it and let me know if you want to make any changes before we start writing out the implementation plan."
+
+Wait for the user's response. If they request changes, make them and re-run the spec review loop. Only proceed once the user approves.
+
+**Implementation:**
+
+- Invoke the writing-plans skill to create a detailed implementation plan
+- Do NOT invoke any other skill. writing-plans is the next step.
+
+## Key Principles
+
+- **One question at a time** - Don't overwhelm with multiple questions
+- **Multiple choice preferred** - Easier to answer than open-ended when possible
+- **YAGNI ruthlessly** - Remove unnecessary features from all designs
+- **Explore alternatives** - Always propose 2-3 approaches before settling
+- **Incremental validation** - Present design, get approval before moving on
+- **Be flexible** - Go back and clarify when something doesn't make sense
+
+## Visual Companion
+
+A browser-based companion for showing mockups, diagrams, and visual options during brainstorming. Available as a tool — not a mode. Accepting the companion means it's available for questions that benefit from visual treatment; it does NOT mean every question goes through the browser.
+
+**Offering the companion (just-in-time):** Do NOT offer it upfront. Wait until a question would genuinely be clearer shown than told — a real mockup / layout / diagram question, not merely a UI *topic*. The first time that happens, offer it then, as its own message:
+> "This next part might be easier if I show you — I can put together mockups, diagrams, and comparisons in a browser tab as we go. It's still new and can be token-intensive. Want me to? I'll open it for you."
+
+**This offer MUST be its own message.** Only the offer — no clarifying question, summary, or other content. Wait for the user's response. If they accept, start the server with `--open` so their browser opens to the first screen automatically. If they decline, continue text-only and don't offer again unless they raise it.
+
+**Per-question decision:** Even after the user accepts, decide FOR EACH QUESTION whether to use the browser or the terminal. The test: **would the user understand this better by seeing it than reading it?**
+
+- **Use the browser** for content that IS visual — mockups, wireframes, layout comparisons, architecture diagrams, side-by-side visual designs
+- **Use the terminal** for content that is text — requirements questions, conceptual choices, tradeoff lists, A/B/C/D text options, scope decisions
+
+A question about a UI topic is not automatically a visual question. "What does personality mean in this context?" is a conceptual question — use the terminal. "Which wizard layout works better?" is a visual question — use the browser.
+
+If they agree to the companion, read the detailed guide before proceeding:
+`skills/brainstorming/visual-companion.md`
diff --git a/.agents/skills/brainstorming/scripts/frame-template.html b/.agents/skills/brainstorming/scripts/frame-template.html
new file mode 100644
index 0000000..f540bb8
--- /dev/null
+++ b/.agents/skills/brainstorming/scripts/frame-template.html
@@ -0,0 +1,213 @@
+<!DOCTYPE html>
+<html>
+<head>
+  <meta charset="utf-8">
+  <title>Superpowers Brainstorming</title>
+  <style>
+    /*
+     * BRAINSTORM COMPANION FRAME TEMPLATE
+     *
+     * This template provides a consistent frame with:
+     * - OS-aware light/dark theming
+     * - Header branding and connection status
+     * - Scrollable main content area
+     * - CSS helpers for common UI patterns
+     *
+     * Content is injected via placeholder comment in #frame-content.
+     */
+
+    * { box-sizing: border-box; margin: 0; padding: 0; }
+    html, body { height: 100%; overflow: hidden; }
+
+    /* ===== THEME VARIABLES ===== */
+    :root {
+      --bg-primary: #f5f5f7;
+      --bg-secondary: #ffffff;
+      --bg-tertiary: #e5e5e7;
+      --border: #d1d1d6;
+      --text-primary: #1d1d1f;
+      --text-secondary: #86868b;
+      --text-tertiary: #aeaeb2;
+      --accent: #0071e3;
+      --accent-hover: #0077ed;
+      --success: #34c759;
+      --warning: #ff9f0a;
+      --error: #ff3b30;
+      --selected-bg: #e8f4fd;
+      --selected-border: #0071e3;
+    }
+
+    @media (prefers-color-scheme: dark) {
+      :root {
+        --bg-primary: #1d1d1f;
+        --bg-secondary: #2d2d2f;
+        --bg-tertiary: #3d3d3f;
+        --border: #424245;
+        --text-primary: #f5f5f7;
+        --text-secondary: #86868b;
+        --text-tertiary: #636366;
+        --accent: #0a84ff;
+        --accent-hover: #409cff;
+        --selected-bg: rgba(10, 132, 255, 0.15);
+        --selected-border: #0a84ff;
+      }
+    }
+
+    body {
+      font-family: system-ui, -apple-system, BlinkMacSystemFont, sans-serif;
+      background: var(--bg-primary);
+      color: var(--text-primary);
+      display: flex;
+      flex-direction: column;
+      line-height: 1.5;
+    }
+
+    /* ===== FRAME STRUCTURE ===== */
+    .brand { display: flex; align-items: center; min-width: 0; overflow: hidden; color: var(--text-secondary); line-height: 1; }
+    .brand a { color: inherit; text-decoration: none; display: flex; align-items: center; gap: 0.5rem; min-width: 0; max-width: 100%; line-height: 1; }
+    .brand-copy { display: block; min-width: 0; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; line-height: 1; transform: translateY(-1px); }
+    .brand-logo { display: block; height: 1em; width: auto; max-width: 180px; flex-shrink: 0; filter: invert(1); }
+    @media (prefers-color-scheme: dark) {
+      .brand-logo { filter: none; }
+    }
+    .status { font-size: 0.7rem; color: var(--status-color, var(--success)); display: flex; align-items: center; gap: 0.4rem; justify-self: end; white-space: nowrap; line-height: 1; }
+    .status::before { content: ''; width: 6px; height: 6px; background: var(--status-color, var(--success)); border-radius: 50%; }
+
+    .main { flex: 1; overflow-y: auto; }
+    #frame-content { padding: 2rem; min-height: 100%; }
+
+    .header {
+      background: var(--bg-secondary);
+      border-bottom: 1px solid var(--border);
+      padding: 0.5rem 1.5rem;
+      flex-shrink: 0;
+      display: grid;
+      grid-template-columns: minmax(0, 1fr) auto;
+      align-items: center;
+      gap: 1rem;
+      min-height: 42px;
+    }
+    .header .brand { justify-self: start; width: 100%; font-size: 0.75rem; line-height: 1; }
+    .header .status { grid-column: 2; line-height: 1; }
+    .header span {
+      font-size: 0.75rem;
+      color: var(--text-secondary);
+    }
+    .header .selected-text {
+      color: var(--accent);
+      font-weight: 500;
+    }
+
+    /* ===== TYPOGRAPHY ===== */
+    h2 { font-size: 1.5rem; font-weight: 600; margin-bottom: 0.5rem; }
+    h3 { font-size: 1.1rem; font-weight: 600; margin-bottom: 0.25rem; }
+    .subtitle { color: var(--text-secondary); margin-bottom: 1.5rem; }
+    .section { margin-bottom: 2rem; }
+    .label { font-size: 0.7rem; color: var(--text-secondary); text-transform: uppercase; letter-spacing: 0.05em; margin-bottom: 0.5rem; }
+
+    /* ===== OPTIONS (for A/B/C choices) ===== */
+    .options { display: flex; flex-direction: column; gap: 0.75rem; }
+    .option {
+      background: var(--bg-secondary);
+      border: 2px solid var(--border);
+      border-radius: 12px;
+      padding: 1rem 1.25rem;
+      cursor: pointer;
+      transition: all 0.15s ease;
+      display: flex;
+      align-items: flex-start;
+      gap: 1rem;
+    }
+    .option:hover { border-color: var(--accent); }
+    .option.selected { background: var(--selected-bg); border-color: var(--selected-border); }
+    .option .letter {
+      background: var(--bg-tertiary);
+      color: var(--text-secondary);
+      width: 1.75rem; height: 1.75rem;
+      border-radius: 6px;
+      display: flex; align-items: center; justify-content: center;
+      font-weight: 600; font-size: 0.85rem; flex-shrink: 0;
+    }
+    .option.selected .letter { background: var(--accent); color: white; }
+    .option .content { flex: 1; }
+    .option .content h3 { font-size: 0.95rem; margin-bottom: 0.15rem; }
+    .option .content p { color: var(--text-secondary); font-size: 0.85rem; margin: 0; }
+
+    /* ===== CARDS (for showing designs/mockups) ===== */
+    .cards { display: grid; grid-template-columns: repeat(auto-fit, minmax(280px, 1fr)); gap: 1rem; }
+    .card {
+      background: var(--bg-secondary);
+      border: 1px solid var(--border);
+      border-radius: 12px;
+      overflow: hidden;
+      cursor: pointer;
+      transition: all 0.15s ease;
+    }
+    .card:hover { border-color: var(--accent); transform: translateY(-2px); box-shadow: 0 4px 12px rgba(0,0,0,0.1); }
+    .card.selected { border-color: var(--selected-border); border-width: 2px; }
+    .card-image { background: var(--bg-tertiary); aspect-ratio: 16/10; display: flex; align-items: center; justify-content: center; }
+    .card-body { padding: 1rem; }
+    .card-body h3 { margin-bottom: 0.25rem; }
+    .card-body p { color: var(--text-secondary); font-size: 0.85rem; }
+
+    /* ===== MOCKUP CONTAINER ===== */
+    .mockup {
+      background: var(--bg-secondary);
+      border: 1px solid var(--border);
+      border-radius: 12px;
+      overflow: hidden;
+      margin-bottom: 1.5rem;
+    }
+    .mockup-header {
+      background: var(--bg-tertiary);
+      padding: 0.5rem 1rem;
+      font-size: 0.75rem;
+      color: var(--text-secondary);
+      border-bottom: 1px solid var(--border);
+    }
+    .mockup-body { padding: 1.5rem; }
+
+    /* ===== SPLIT VIEW (side-by-side comparison) ===== */
+    .split { display: grid; grid-template-columns: 1fr 1fr; gap: 1.5rem; }
+    @media (max-width: 700px) { .split { grid-template-columns: 1fr; } }
+
+    /* ===== PROS/CONS ===== */
+    .pros-cons { display: grid; grid-template-columns: 1fr 1fr; gap: 1rem; margin: 1rem 0; }
+    .pros, .cons { background: var(--bg-secondary); border-radius: 8px; padding: 1rem; }
+    .pros h4 { color: var(--success); font-size: 0.85rem; margin-bottom: 0.5rem; }
+    .cons h4 { color: var(--error); font-size: 0.85rem; margin-bottom: 0.5rem; }
+    .pros ul, .cons ul { margin-left: 1.25rem; font-size: 0.85rem; color: var(--text-secondary); }
+    .pros li, .cons li { margin-bottom: 0.25rem; }
+
+    /* ===== PLACEHOLDER (for mockup areas) ===== */
+    .placeholder {
+      background: var(--bg-tertiary);
+      border: 2px dashed var(--border);
+      border-radius: 8px;
+      padding: 2rem;
+      text-align: center;
+      color: var(--text-tertiary);
+    }
+
+    /* ===== INLINE MOCKUP ELEMENTS ===== */
+    .mock-nav { background: var(--accent); color: white; padding: 0.75rem 1rem; display: flex; gap: 1.5rem; font-size: 0.9rem; }
+    .mock-sidebar { background: var(--bg-tertiary); padding: 1rem; min-width: 180px; }
+    .mock-content { padding: 1.5rem; flex: 1; }
+    .mock-button { background: var(--accent); color: white; border: none; padding: 0.5rem 1rem; border-radius: 6px; font-size: 0.85rem; }
+    .mock-input { background: var(--bg-primary); border: 1px solid var(--border); border-radius: 6px; padding: 0.5rem; width: 100%; }
+  </style>
+</head>
+<body>
+  <div class="header">
+    <!-- BRANDING -->
+    <div class="status">Connecting…</div>
+  </div>
+
+  <div class="main">
+    <div id="frame-content">
+      <!-- CONTENT -->
+    </div>
+  </div>
+
+</body>
+</html>
diff --git a/.agents/skills/brainstorming/scripts/helper.js b/.agents/skills/brainstorming/scripts/helper.js
new file mode 100644
index 0000000..e11d264
--- /dev/null
+++ b/.agents/skills/brainstorming/scripts/helper.js
@@ -0,0 +1,167 @@
+(function() {
+  const MIN_RECONNECT_MS = 500;
+  const MAX_RECONNECT_MS = 30000;
+  const TOMBSTONE_AFTER_MS = 15000; // show the "paused" overlay after this long disconnected
+
+  // Pure: next backoff delay (doubles, capped). Exported for unit tests.
+  function nextReconnectDelay(current, max) {
+    return Math.min(current * 2, max);
+  }
+  if (typeof module !== 'undefined' && module.exports) {
+    module.exports = { nextReconnectDelay, MIN_RECONNECT_MS, MAX_RECONNECT_MS, TOMBSTONE_AFTER_MS };
+  }
+
+  // Everything below is browser-only; bail out when loaded in Node (tests).
+  if (typeof window === 'undefined') return;
+
+  let ws = null;
+  let eventQueue = [];
+  let reconnectDelay = MIN_RECONNECT_MS;
+  let reconnectTimer = null;
+  let disconnectedSince = null;
+  let everConnected = false;
+  let tombstoneShown = false;
+
+  function sessionKey() {
+    try {
+      return window.sessionStorage && window.sessionStorage.getItem('brainstorm-session-key');
+    } catch (e) {}
+    return null;
+  }
+
+  function websocketUrl() {
+    const key = sessionKey();
+    return 'ws://' + window.location.host + (key ? '/?key=' + encodeURIComponent(key) : '');
+  }
+
+  function reloadAfterRecovery() {
+    const key = sessionKey();
+    if (key) {
+      window.location.replace('/?key=' + encodeURIComponent(key));
+    } else {
+      window.location.reload();
+    }
+  }
+
+  // Reflect connection state in the frame's status pill (absent on full-doc screens).
+  function setStatus(state) {
+    const el = document.querySelector('.status');
+    if (!el) return;
+    const map = {
+      connecting:   ['Connecting…',   'var(--text-tertiary)'],
+      connected:    ['Connected',     'var(--success)'],
+      reconnecting: ['Reconnecting…', 'var(--warning)'],
+      disconnected: ['Disconnected',  'var(--error)']
+    };
+    const [text, color] = map[state] || map.disconnected;
+    el.textContent = text;
+    el.style.setProperty('--status-color', color);
+  }
+
+  // Self-styled so it works on framed and full-document screens alike.
+  function showTombstone() {
+    if (tombstoneShown) return;
+    tombstoneShown = true;
+    const el = document.createElement('div');
+    el.id = 'bs-tombstone';
+    el.style.cssText = 'position:fixed;inset:0;z-index:99999;display:flex;' +
+      'align-items:center;justify-content:center;padding:2rem;text-align:center;' +
+      'background:rgba(20,20,22,0.92);color:#f5f5f7;font-family:system-ui,sans-serif';
+    el.innerHTML = '<div style="max-width:480px">' +
+      '<h2 style="margin:0 0 .5rem;font-weight:600">Companion paused</h2>' +
+      '<p style="margin:0;opacity:.85">This brainstorm companion has stopped. ' +
+      'Ask your coding agent to bring it back — this page reconnects automatically.</p></div>';
+    if (document.body) document.body.appendChild(el);
+  }
+
+  function connect() {
+    if (reconnectTimer) { clearTimeout(reconnectTimer); reconnectTimer = null; }
+    setStatus(everConnected ? 'reconnecting' : 'connecting');
+    ws = new WebSocket(websocketUrl());
+
+    ws.onopen = () => {
+      const recovered = tombstoneShown;
+      everConnected = true;
+      disconnectedSince = null;
+      reconnectDelay = MIN_RECONNECT_MS;
+      tombstoneShown = false;
+      setStatus('connected');
+      eventQueue.forEach(e => ws.send(JSON.stringify(e)));
+      eventQueue = [];
+      // Recovered from a tombstoned outage (e.g. the server restarted on the same
+      // port) — reload through the keyed bootstrap when possible so the cookie is
+      // refreshed before the visible URL returns to bare /.
+      if (recovered) reloadAfterRecovery();
+    };
+
+    ws.onmessage = (msg) => {
+      let data;
+      try { data = JSON.parse(msg.data); } catch (e) { return; }
+      if (data.type === 'reload') window.location.reload();
+    };
+
+    ws.onclose = () => {
+      ws = null;
+      if (disconnectedSince === null) disconnectedSince = Date.now();
+      if (Date.now() - disconnectedSince >= TOMBSTONE_AFTER_MS) {
+        setStatus('disconnected');
+        showTombstone();
+      } else {
+        setStatus('reconnecting');
+      }
+      reconnectTimer = setTimeout(connect, reconnectDelay);
+      reconnectDelay = nextReconnectDelay(reconnectDelay, MAX_RECONNECT_MS);
+    };
+
+    // Let onclose own reconnection so we don't schedule it twice.
+    ws.onerror = () => { try { ws.close(); } catch (e) {} };
+  }
+
+  function sendEvent(event) {
+    event.timestamp = Date.now();
+    if (ws && ws.readyState === WebSocket.OPEN) {
+      ws.send(JSON.stringify(event));
+    } else {
+      eventQueue.push(event);
+    }
+  }
+
+  // Capture clicks on choice elements
+  document.addEventListener('click', (e) => {
+    const target = e.target.closest('[data-choice]');
+    if (!target) return;
+
+    sendEvent({
+      type: 'click',
+      text: target.textContent.trim(),
+      choice: target.dataset.choice,
+      id: target.id || null
+    });
+
+  });
+
+  // Frame UI: selection tracking
+  window.selectedChoice = null;
+
+  window.toggleSelect = function(el) {
+    const container = el.closest('.options') || el.closest('.cards');
+    const multi = container && container.dataset.multiselect !== undefined;
+    if (container && !multi) {
+      container.querySelectorAll('.option, .card').forEach(o => o.classList.remove('selected'));
+    }
+    if (multi) {
+      el.classList.toggle('selected');
+    } else {
+      el.classList.add('selected');
+    }
+    window.selectedChoice = el.dataset.choice;
+  };
+
+  // Expose API for explicit use
+  window.brainstorm = {
+    send: sendEvent,
+    choice: (value, metadata = {}) => sendEvent({ type: 'choice', value, ...metadata })
+  };
+
+  connect();
+})();
diff --git a/.agents/skills/brainstorming/scripts/server.cjs b/.agents/skills/brainstorming/scripts/server.cjs
new file mode 100644
index 0000000..a828b35
--- /dev/null
+++ b/.agents/skills/brainstorming/scripts/server.cjs
@@ -0,0 +1,723 @@
+const crypto = require('crypto');
+const http = require('http');
+const fs = require('fs');
+const path = require('path');
+
+// ========== WebSocket Protocol (RFC 6455) ==========
+
+const OPCODES = { TEXT: 0x01, CLOSE: 0x08, PING: 0x09, PONG: 0x0A };
+const WS_MAGIC = '258EAFA5-E914-47DA-95CA-C5AB0DC85B11';
+const MAX_FRAME_PAYLOAD_BYTES = 10 * 1024 * 1024;
+
+function computeAcceptKey(clientKey) {
+  return crypto.createHash('sha1').update(clientKey + WS_MAGIC).digest('base64');
+}
+
+function encodeFrame(opcode, payload) {
+  const fin = 0x80;
+  const len = payload.length;
+  let header;
+
+  if (len < 126) {
+    header = Buffer.alloc(2);
+    header[0] = fin | opcode;
+    header[1] = len;
+  } else if (len < 65536) {
+    header = Buffer.alloc(4);
+    header[0] = fin | opcode;
+    header[1] = 126;
+    header.writeUInt16BE(len, 2);
+  } else {
+    header = Buffer.alloc(10);
+    header[0] = fin | opcode;
+    header[1] = 127;
+    header.writeBigUInt64BE(BigInt(len), 2);
+  }
+
+  return Buffer.concat([header, payload]);
+}
+
+function decodeFrame(buffer) {
+  if (buffer.length < 2) return null;
+
+  const secondByte = buffer[1];
+  const opcode = buffer[0] & 0x0F;
+  const masked = (secondByte & 0x80) !== 0;
+  let payloadLen = secondByte & 0x7F;
+  let offset = 2;
+
+  if (!masked) throw new Error('Client frames must be masked');
+
+  if (payloadLen === 126) {
+    if (buffer.length < 4) return null;
+    payloadLen = buffer.readUInt16BE(2);
+    offset = 4;
+  } else if (payloadLen === 127) {
+    if (buffer.length < 10) return null;
+    const extendedLen = buffer.readBigUInt64BE(2);
+    if (extendedLen > BigInt(MAX_FRAME_PAYLOAD_BYTES)) {
+      throw new Error('WebSocket frame payload exceeds maximum allowed size');
+    }
+    payloadLen = Number(extendedLen);
+    offset = 10;
+  }
+
+  if (payloadLen > MAX_FRAME_PAYLOAD_BYTES) {
+    throw new Error('WebSocket frame payload exceeds maximum allowed size');
+  }
+
+  const maskOffset = offset;
+  const dataOffset = offset + 4;
+  const totalLen = dataOffset + payloadLen;
+  if (buffer.length < totalLen) return null;
+
+  const mask = buffer.slice(maskOffset, dataOffset);
+  const data = Buffer.alloc(payloadLen);
+  for (let i = 0; i < payloadLen; i++) {
+    data[i] = buffer[dataOffset + i] ^ mask[i % 4];
+  }
+
+  return { opcode, payload: data, bytesConsumed: totalLen };
+}
+
+// ========== Configuration ==========
+
+const PORT_FILE = process.env.BRAINSTORM_PORT_FILE || null;
+const randomPort = () => 49152 + Math.floor(Math.random() * 16383);
+// Prefer an explicit port, else the port this session last bound (so a restart
+// reuses it and an already-open browser tab reconnects), else a random high port.
+function preferredPort() {
+  if (process.env.BRAINSTORM_PORT) return Number(process.env.BRAINSTORM_PORT);
+  if (PORT_FILE) {
+    try {
+      const p = Number(fs.readFileSync(PORT_FILE, 'utf-8').trim());
+      if (Number.isInteger(p) && p > 1023 && p < 65536) return p;
+    } catch (e) { /* no prior port recorded */ }
+  }
+  return randomPort();
+}
+let PORT = preferredPort();
+const HOST = process.env.BRAINSTORM_HOST || '127.0.0.1';
+const URL_HOST = process.env.BRAINSTORM_URL_HOST || (HOST === '127.0.0.1' ? 'localhost' : HOST);
+const SESSION_DIR = process.env.BRAINSTORM_DIR || '/tmp/brainstorm';
+const CONTENT_DIR = path.join(SESSION_DIR, 'content');
+const STATE_DIR = path.join(SESSION_DIR, 'state');
+const SUPERPOWERS_VERSION = readSuperpowersVersion();
+const SUPERPOWERS_BRAND_IMAGE_URL = 'https://primeradiant.com/brand/superpowers-visual-brainstorming-logo.png';
+const TELEMETRY_DISABLE_ENV_VARS = [
+  'SUPERPOWERS_DISABLE_TELEMETRY',
+  'DISABLE_TELEMETRY',
+  'CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC'
+];
+const SUPERPOWERS_TELEMETRY_DISABLED = TELEMETRY_DISABLE_ENV_VARS.some(name => isTruthyEnv(process.env[name]));
+let ownerPid = process.env.BRAINSTORM_OWNER_PID ? Number(process.env.BRAINSTORM_OWNER_PID) : null;
+
+// Per-session secret key. The companion is reachable by any local browser tab
+// and, when bound to a non-loopback host, by any host that can route to it.
+// The key authenticates the real client uniformly across loopback, tunnel, and
+// remote binds — and defeats DNS rebinding — where a Host/Origin allowlist
+// cannot. It rides the served URL as ?key= and is mirrored into a cookie on
+// first load so same-origin subresources and the WebSocket carry it for free.
+// Persisted alongside the port (BRAINSTORM_TOKEN_FILE) so a restart keeps the
+// same key and an already-open tab's cookie still validates.
+const TOKEN_FILE = process.env.BRAINSTORM_TOKEN_FILE || null;
+function generateToken() {
+  return crypto.randomBytes(32).toString('hex');
+}
+
+function chmodOwnerOnly(file) {
+  try { fs.chmodSync(file, 0o600); } catch (e) { /* best effort */ }
+}
+
+function initialToken() {
+  if (process.env.BRAINSTORM_TOKEN) {
+    return { value: process.env.BRAINSTORM_TOKEN, source: 'env' };
+  }
+  if (TOKEN_FILE) {
+    try {
+      const t = fs.readFileSync(TOKEN_FILE, 'utf-8').trim();
+      if (/^[0-9a-f]{32,}$/i.test(t)) {
+        chmodOwnerOnly(TOKEN_FILE);
+        return { value: t, source: 'file' };
+      }
+    } catch (e) { /* no prior token recorded */ }
+  }
+  return { value: generateToken(), source: 'generated' };
+}
+
+const tokenInfo = initialToken();
+let TOKEN = tokenInfo.value;
+let tokenSource = tokenInfo.source;
+let COOKIE_NAME = 'brainstorm-key-' + PORT; // refined to the actual bound port in onListen
+
+const MIME_TYPES = {
+  '.html': 'text/html', '.css': 'text/css', '.js': 'application/javascript',
+  '.json': 'application/json', '.png': 'image/png', '.jpg': 'image/jpeg',
+  '.jpeg': 'image/jpeg', '.gif': 'image/gif', '.svg': 'image/svg+xml'
+};
+
+// ========== Templates and Constants ==========
+
+function waitingPage() {
+  return renderBranding(`<!DOCTYPE html>
+<html>
+<head><meta charset="utf-8"><title>Brainstorm Companion</title>
+<style>
+body { font-family: system-ui, sans-serif; padding: 2rem; max-width: 800px; margin: 0 auto; }
+h1 { color: #333; } p { color: #666; }
+.brand { display: flex; align-items: center; min-width: 0; overflow: hidden; margin-bottom: 1.5rem; color: #666; font-size: 0.9rem; line-height: 1; }
+.brand a { color: inherit; text-decoration: none; display: flex; align-items: center; gap: 0.5rem; min-width: 0; max-width: 100%; line-height: 1; }
+.brand-copy { display: block; min-width: 0; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; line-height: 1; transform: translateY(-1px); }
+.brand-logo { display: block; height: 1em; width: auto; max-width: 180px; filter: invert(1); }
+</style>
+</head>
+<body><!-- BRANDING --><h1>Brainstorm Companion</h1>
+<p>Waiting for the agent to push a screen...</p></body></html>`);
+}
+
+const FORBIDDEN_PAGE = `<!DOCTYPE html>
+<html>
+<head><meta charset="utf-8"><title>Session key required</title>
+<style>body { font-family: system-ui, sans-serif; padding: 2rem; max-width: 800px; margin: 0 auto; }
+h1 { color: #333; } p { color: #666; } code { background: #f0f0f0; padding: 0.1em 0.3em; border-radius: 4px; }</style>
+</head>
+<body><h1>Session key required</h1>
+<p>This page needs the full URL your coding agent gave you, including the
+<code>?key=&hellip;</code> part. Copy the complete URL and open it again.</p></body></html>`;
+
+function bootstrapPage(key) {
+  const jsonKey = JSON.stringify(String(key));
+  return `<!DOCTYPE html>
+<html>
+<head><meta charset="utf-8"><title>Opening Brainstorm Companion</title></head>
+<body>
+<script>
+try { sessionStorage.setItem('brainstorm-session-key', ${jsonKey}); } catch (e) {}
+location.replace('/');
+</script>
+</body>
+</html>`;
+}
+
+const frameTemplate = fs.readFileSync(path.join(__dirname, 'frame-template.html'), 'utf-8');
+const helperScript = fs.readFileSync(path.join(__dirname, 'helper.js'), 'utf-8');
+const helperInjection = '<script>\n' + helperScript + '\n</script>';
+
+// ========== Helper Functions ==========
+
+function readSuperpowersVersion() {
+  const root = path.join(__dirname, '../../..');
+  const manifests = [
+    path.join(root, 'package.json'),
+    path.join(root, '.codex-plugin/plugin.json')
+  ];
+
+  for (const manifest of manifests) {
+    try {
+      const data = JSON.parse(fs.readFileSync(manifest, 'utf-8'));
+      if (data.version) return String(data.version);
+    } catch (e) {
+      // Packaged Codex plugins omit package.json; try the next manifest.
+    }
+  }
+
+  return 'unknown';
+}
+
+function isTruthyEnv(value) {
+  if (!value) return false;
+  const normalized = String(value).trim().toLowerCase();
+  if (!normalized) return false;
+  return !['0', 'false', 'no', 'off'].includes(normalized);
+}
+
+function escapeHtmlText(value) {
+  return String(value)
+    .replace(/&/g, '&amp;')
+    .replace(/</g, '&lt;')
+    .replace(/>/g, '&gt;')
+    .replace(/"/g, '&quot;');
+}
+
+function brandMarkup() {
+  const version = escapeHtmlText(SUPERPOWERS_VERSION);
+  const text = SUPERPOWERS_TELEMETRY_DISABLED
+    ? 'Prime Radiant Superpowers v' + version
+    : 'Superpowers v' + version;
+  const logo = SUPERPOWERS_TELEMETRY_DISABLED
+    ? ''
+    : '<img class="brand-logo" src="' + SUPERPOWERS_BRAND_IMAGE_URL + '?v=' + encodeURIComponent(SUPERPOWERS_VERSION) + '" alt="Prime Radiant" referrerpolicy="no-referrer" decoding="async">';
+
+  return '<div class="brand"><a href="https://github.com/obra/superpowers">' + logo + '<span class="brand-copy">' + text + '</span></a></div>';
+}
+
+function renderBranding(html) {
+  return html.split('<!-- BRANDING -->').join(brandMarkup());
+}
+
+function isFullDocument(html) {
+  const trimmed = html.trimStart().toLowerCase();
+  return trimmed.startsWith('<!doctype') || trimmed.startsWith('<html');
+}
+
+function wrapInFrame(content) {
+  return renderBranding(frameTemplate).replace('<!-- CONTENT -->', content);
+}
+
+function getNewestScreen() {
+  const files = fs.readdirSync(CONTENT_DIR)
+    .filter(f => !f.startsWith('.') && f.endsWith('.html'))
+    .map(f => {
+      const fp = path.join(CONTENT_DIR, f);
+      if (!isRegularFileInsideContentDir(fp)) return null;
+      return { path: fp, mtime: fs.statSync(fp).mtime.getTime() };
+    })
+    .filter(Boolean)
+    .sort((a, b) => b.mtime - a.mtime);
+  return files.length > 0 ? files[0].path : null;
+}
+
+function urlHostForHttp(host) {
+  const h = String(host);
+  if (h.startsWith('[') && h.endsWith(']')) return h;
+  return h.includes(':') ? '[' + h + ']' : h;
+}
+
+function companionUrl() {
+  return 'http://' + urlHostForHttp(URL_HOST) + ':' + PORT + '/?key=' + TOKEN;
+}
+
+function browserLauncherForPlatform(url, {
+  platform = process.platform,
+  osRelease = require('os').release(),
+  env = process.env
+} = {}) {
+  const isWSL = platform === 'linux' && /microsoft/i.test(osRelease);
+  if (platform === 'darwin') return { bin: 'open', args: [url] };
+  if (platform === 'win32' || isWSL) {
+    return { bin: 'rundll32.exe', args: ['url.dll,FileProtocolHandler', url] };
+  }
+  if (env.DISPLAY || env.WAYLAND_DISPLAY) return { bin: 'xdg-open', args: [url] };
+  return null;
+}
+
+function isRegularFileInsideContentDir(filePath) {
+  let stat, realContentDir, realFilePath;
+  try {
+    stat = fs.lstatSync(filePath);
+    if (stat.isSymbolicLink()) return false;
+    if (!stat.isFile()) return false;
+    if (stat.nlink !== 1) return false;
+    realContentDir = fs.realpathSync(CONTENT_DIR);
+    realFilePath = fs.realpathSync(filePath);
+  } catch (e) {
+    return false;
+  }
+  return realFilePath.startsWith(realContentDir + path.sep);
+}
+
+// ========== Authentication ==========
+
+function timingSafeEqualStr(a, b) {
+  const ab = Buffer.from(String(a));
+  const bb = Buffer.from(String(b));
+  if (ab.length !== bb.length) return false;
+  return crypto.timingSafeEqual(ab, bb);
+}
+
+function parseCookies(header) {
+  const out = {};
+  if (!header) return out;
+  for (const part of header.split(';')) {
+    const eq = part.indexOf('=');
+    if (eq < 0) continue;
+    out[part.slice(0, eq).trim()] = part.slice(eq + 1).trim();
+  }
+  return out;
+}
+
+// A request is authorized if it carries the session key as ?key= or as the
+// session cookie. Both are compared in constant time.
+function isAuthorized(req) {
+  const q = req.url.indexOf('?');
+  if (q >= 0) {
+    const params = new URLSearchParams(req.url.slice(q + 1));
+    if (params.has('key')) {
+      const key = params.get('key');
+      return Boolean(key && timingSafeEqualStr(key, TOKEN));
+    }
+  }
+  const cookie = parseCookies(req.headers['cookie'])[COOKIE_NAME];
+  if (cookie && timingSafeEqualStr(cookie, TOKEN)) return true;
+  return false;
+}
+
+function pathnameOf(url) {
+  const q = url.indexOf('?');
+  return q >= 0 ? url.slice(0, q) : url;
+}
+
+function queryKey(url) {
+  const q = url.indexOf('?');
+  if (q < 0) return null;
+  return new URLSearchParams(url.slice(q + 1)).get('key');
+}
+
+function securityHeaders(headers = {}) {
+  return {
+    'Referrer-Policy': 'no-referrer',
+    'Cache-Control': 'no-store',
+    'X-Frame-Options': 'DENY',
+    'Content-Security-Policy': "frame-ancestors 'none'",
+    'Cross-Origin-Resource-Policy': 'same-origin',
+    ...headers
+  };
+}
+
+function isAllowedWebSocketOrigin(req) {
+  const origin = req.headers.origin;
+  if (!origin) return true;
+  const host = req.headers.host;
+  if (!host) return false;
+  return origin === 'http://' + host;
+}
+
+// ========== HTTP Request Handler ==========
+
+function handleRequest(req, res) {
+  if (!isAuthorized(req)) {
+    res.writeHead(403, securityHeaders({ 'Content-Type': 'text/html; charset=utf-8' }));
+    res.end(FORBIDDEN_PAGE);
+    return;
+  }
+  touchActivity(); // only authorized requests count as activity
+
+  // Mirror the key into a cookie so same-origin subresources (/files/*) can
+  // authenticate after bootstrap. HttpOnly keeps it away from page scripts; the
+  // WebSocket Origin check below is what blocks cross-origin localhost injection.
+  res.setHeader('Set-Cookie',
+    COOKIE_NAME + '=' + TOKEN + '; HttpOnly; SameSite=Strict; Path=/');
+
+  const pathname = pathnameOf(req.url);
+  const keyFromQuery = queryKey(req.url);
+  if (req.method === 'GET' && pathname === '/' && keyFromQuery && timingSafeEqualStr(keyFromQuery, TOKEN)) {
+    res.writeHead(200, securityHeaders({ 'Content-Type': 'text/html; charset=utf-8' }));
+    res.end(bootstrapPage(keyFromQuery));
+  } else if (req.method === 'GET' && pathname === '/') {
+    const screenFile = getNewestScreen();
+    let html = screenFile
+      ? (raw => isFullDocument(raw) ? raw : wrapInFrame(raw))(fs.readFileSync(screenFile, 'utf-8'))
+      : waitingPage();
+
+    if (html.includes('</body>')) {
+      html = html.replace('</body>', helperInjection + '\n</body>');
+    } else {
+      html += helperInjection;
+    }
+
+    res.writeHead(200, securityHeaders({ 'Content-Type': 'text/html; charset=utf-8' }));
+    res.end(html);
+  } else if (req.method === 'GET' && pathname.startsWith('/files/')) {
+    const fileName = path.basename(pathname.slice(7));
+    const filePath = path.join(CONTENT_DIR, fileName);
+    // Reject empty/dotfile names and anything that isn't a regular file —
+    // `/files/` would otherwise resolve to CONTENT_DIR and crash readFileSync (EISDIR).
+    if (!fileName || fileName.startsWith('.') || !isRegularFileInsideContentDir(filePath)) {
+      res.writeHead(404, securityHeaders());
+      res.end('Not found');
+      return;
+    }
+    const ext = path.extname(filePath).toLowerCase();
+    const contentType = MIME_TYPES[ext] || 'application/octet-stream';
+    res.writeHead(200, securityHeaders({ 'Content-Type': contentType }));
+    res.end(fs.readFileSync(filePath));
+  } else {
+    res.writeHead(404, securityHeaders());
+    res.end('Not found');
+  }
+}
+
+// ========== WebSocket Connection Handling ==========
+
+const clients = new Set();
+
+function handleUpgrade(req, socket) {
+  if (!isAuthorized(req) || !isAllowedWebSocketOrigin(req)) { socket.destroy(); return; }
+
+  const key = req.headers['sec-websocket-key'];
+  if (!key) { socket.destroy(); return; }
+
+  const accept = computeAcceptKey(key);
+  socket.write(
+    'HTTP/1.1 101 Switching Protocols\r\n' +
+    'Upgrade: websocket\r\n' +
+    'Connection: Upgrade\r\n' +
+    'Sec-WebSocket-Accept: ' + accept + '\r\n\r\n'
+  );
+
+  let buffer = Buffer.alloc(0);
+  clients.add(socket);
+
+  socket.on('data', (chunk) => {
+    buffer = Buffer.concat([buffer, chunk]);
+    while (buffer.length > 0) {
+      let result;
+      try {
+        result = decodeFrame(buffer);
+      } catch (e) {
+        socket.end(encodeFrame(OPCODES.CLOSE, Buffer.alloc(0)));
+        clients.delete(socket);
+        return;
+      }
+      if (!result) break;
+      buffer = buffer.slice(result.bytesConsumed);
+
+      switch (result.opcode) {
+        case OPCODES.TEXT:
+          handleMessage(result.payload.toString());
+          break;
+        case OPCODES.CLOSE:
+          socket.end(encodeFrame(OPCODES.CLOSE, Buffer.alloc(0)));
+          clients.delete(socket);
+          return;
+        case OPCODES.PING:
+          socket.write(encodeFrame(OPCODES.PONG, result.payload));
+          break;
+        case OPCODES.PONG:
+          break;
+        default: {
+          const closeBuf = Buffer.alloc(2);
+          closeBuf.writeUInt16BE(1003);
+          socket.end(encodeFrame(OPCODES.CLOSE, closeBuf));
+          clients.delete(socket);
+          return;
+        }
+      }
+    }
+  });
+
+  socket.on('close', () => clients.delete(socket));
+  socket.on('error', () => clients.delete(socket));
+}
+
+function handleMessage(text) {
+  let event;
+  try {
+    event = JSON.parse(text);
+  } catch (e) {
+    console.error('Failed to parse WebSocket message:', e.message);
+    return;
+  }
+  touchActivity();
+  console.log(JSON.stringify({ source: 'user-event', ...event }));
+  if (event && event.choice) {
+    const eventsFile = path.join(STATE_DIR, 'events');
+    fs.appendFileSync(eventsFile, JSON.stringify(event) + '\n');
+  }
+}
+
+function broadcast(msg) {
+  const frame = encodeFrame(OPCODES.TEXT, Buffer.from(JSON.stringify(msg)));
+  for (const socket of clients) {
+    try { socket.write(frame); } catch (e) { clients.delete(socket); }
+  }
+}
+
+// Best-effort: open the user's browser the first time a screen is actually ready
+// to show. Skips when disabled, on a non-loopback (remote) bind, or when a
+// browser is already connected. Override the launcher with BRAINSTORM_OPEN_CMD.
+let browserOpened = false;
+function maybeOpenBrowser() {
+  if (browserOpened) return;
+  browserOpened = true;
+  if (!process.env.BRAINSTORM_OPEN) return; // opt-in: only after the user approves the companion
+  if (HOST !== '127.0.0.1' && HOST !== 'localhost') return;
+  if (clients.size > 0) return; // the user already opened it
+  const url = companionUrl(); // must carry the key or the gate 403s it
+  const cp = require('child_process');
+  // Operator-provided launcher: run as given (this env var is trusted operator input).
+  if (process.env.BRAINSTORM_OPEN_CMD) {
+    try { cp.exec(process.env.BRAINSTORM_OPEN_CMD + ' ' + JSON.stringify(url), () => {}); } catch (e) { /* best effort */ }
+    return;
+  }
+  // Platform launchers: pass the URL as an argv element via execFile (no shell),
+  // so a url-host containing shell metacharacters can't inject a command.
+  const launcher = browserLauncherForPlatform(url);
+  if (!launcher) return; // headless: nothing to open
+  try { cp.execFile(launcher.bin, launcher.args, () => {}); } catch (e) { /* best effort */ }
+}
+
+// ========== Activity Tracking ==========
+
+// Idle timeout: shut down after this long with no activity. Default 4 hours;
+// override with BRAINSTORM_IDLE_TIMEOUT_MS (start-server.sh: --idle-timeout-minutes).
+const IDLE_TIMEOUT_MS = (() => {
+  const ms = Number(process.env.BRAINSTORM_IDLE_TIMEOUT_MS);
+  return Number.isFinite(ms) && ms > 0 ? ms : 4 * 60 * 60 * 1000;
+})();
+// How often the watchdog checks for owner-death / idleness. Configurable mainly
+// so tests can run fast; production default is 60s.
+const LIFECYCLE_CHECK_MS = (() => {
+  const ms = Number(process.env.BRAINSTORM_LIFECYCLE_CHECK_MS);
+  return Number.isFinite(ms) && ms > 0 ? ms : 60 * 1000;
+})();
+let lastActivity = Date.now();
+
+function touchActivity() {
+  lastActivity = Date.now();
+}
+
+// ========== File Watching ==========
+
+const debounceTimers = new Map();
+
+// ========== Server Startup ==========
+
+function startServer() {
+  if (!fs.existsSync(CONTENT_DIR)) fs.mkdirSync(CONTENT_DIR, { recursive: true });
+  if (!fs.existsSync(STATE_DIR)) fs.mkdirSync(STATE_DIR, { recursive: true });
+
+  // Track known files to distinguish new screens from updates.
+  // macOS fs.watch reports 'rename' for both new files and overwrites,
+  // so we can't rely on eventType alone.
+  const knownFiles = new Set(
+    fs.readdirSync(CONTENT_DIR).filter(f => !f.startsWith('.') && f.endsWith('.html'))
+  );
+
+  const server = http.createServer(handleRequest);
+  server.on('upgrade', handleUpgrade);
+
+  const watcher = fs.watch(CONTENT_DIR, (eventType, filename) => {
+    if (!filename || filename.startsWith('.') || !filename.endsWith('.html')) return;
+
+    if (debounceTimers.has(filename)) clearTimeout(debounceTimers.get(filename));
+    debounceTimers.set(filename, setTimeout(() => {
+      debounceTimers.delete(filename);
+      const filePath = path.join(CONTENT_DIR, filename);
+
+      if (!fs.existsSync(filePath)) return; // file was deleted
+      touchActivity();
+
+      if (!knownFiles.has(filename)) {
+        knownFiles.add(filename);
+        const eventsFile = path.join(STATE_DIR, 'events');
+        if (fs.existsSync(eventsFile)) fs.unlinkSync(eventsFile);
+        console.log(JSON.stringify({ type: 'screen-added', file: filePath }));
+        maybeOpenBrowser();
+      } else {
+        console.log(JSON.stringify({ type: 'screen-updated', file: filePath }));
+      }
+
+      broadcast({ type: 'reload' });
+    }, 100));
+  });
+  watcher.on('error', (err) => console.error('fs.watch error:', err.message));
+
+  function shutdown(reason) {
+    console.log(JSON.stringify({ type: 'server-stopped', reason }));
+    const infoFile = path.join(STATE_DIR, 'server-info');
+    if (fs.existsSync(infoFile)) fs.unlinkSync(infoFile);
+    fs.writeFileSync(
+      path.join(STATE_DIR, 'server-stopped'),
+      JSON.stringify({ reason, timestamp: Date.now() }) + '\n'
+    );
+    watcher.close();
+    clearInterval(lifecycleCheck);
+    // Close any upgraded WebSocket sockets so server.close() can complete and
+    // the process actually exits instead of lingering on an open connection.
+    for (const socket of clients) {
+      try { socket.destroy(); } catch (e) { /* already gone */ }
+    }
+    server.close(() => process.exit(0));
+  }
+
+  function ownerAlive() {
+    if (!ownerPid) return true;
+    try { process.kill(ownerPid, 0); return true; } catch (e) { return e.code === 'EPERM'; }
+  }
+
+  // Periodically exit if the owner process died or we've been idle too long.
+  const lifecycleCheck = setInterval(() => {
+    if (!ownerAlive()) shutdown('owner process exited');
+    else if (Date.now() - lastActivity > IDLE_TIMEOUT_MS) shutdown('idle timeout');
+  }, LIFECYCLE_CHECK_MS);
+  lifecycleCheck.unref();
+
+  // Validate owner PID at startup. If it's already dead, the PID resolution
+  // was wrong (common on WSL, Tailscale SSH, and cross-user scenarios).
+  // Disable monitoring and rely on the idle timeout instead.
+  if (ownerPid) {
+    try { process.kill(ownerPid, 0); }
+    catch (e) {
+      if (e.code !== 'EPERM') {
+        console.log(JSON.stringify({ type: 'owner-pid-invalid', pid: ownerPid, reason: 'dead at startup' }));
+        ownerPid = null;
+      }
+    }
+  }
+
+  // If the preferred port is already taken (e.g. a previous server is still
+  // alive), fall back to a random port once instead of failing.
+  let triedFallback = false;
+
+  function onListen() {
+    // Cookie name keys on the ACTUAL bound port (may differ from the preferred
+    // one after an EADDRINUSE fallback) so it can't collide with another server's
+    // cookie in the shared localhost jar.
+    COOKIE_NAME = 'brainstorm-key-' + PORT;
+    // Record the bound port AND token so the next restart of this session reuses
+    // them — but ONLY when we got our preferred port. On a fallback we bound a
+    // *different* port because someone else holds the preferred one; persisting
+    // would overwrite the shared files and strand that other session's open tab.
+    if (PORT_FILE && !triedFallback) {
+      try { fs.writeFileSync(PORT_FILE, String(PORT)); } catch (e) { /* best effort */ }
+      if (TOKEN_FILE) {
+        try {
+          fs.writeFileSync(TOKEN_FILE, TOKEN, { mode: 0o600 });
+          chmodOwnerOnly(TOKEN_FILE);
+        } catch (e) { /* best effort */ }
+      }
+    }
+    const info = JSON.stringify({
+      type: 'server-started', port: Number(PORT), host: HOST,
+      url_host: URL_HOST, url: companionUrl(),
+      screen_dir: CONTENT_DIR, state_dir: STATE_DIR, idle_timeout_ms: IDLE_TIMEOUT_MS
+    });
+    console.log(info);
+    // server-info embeds the key — keep it owner-only.
+    fs.writeFileSync(path.join(STATE_DIR, 'server-info'), info + '\n', { mode: 0o600 });
+  }
+
+  server.on('error', (err) => {
+    if (err.code === 'EADDRINUSE' && !triedFallback) {
+      if (tokenSource === 'env') {
+        console.error('Server failed to bind: preferred port is in use and BRAINSTORM_TOKEN is set; refusing fallback with explicit token');
+        process.exit(1);
+      }
+      triedFallback = true;
+      PORT = randomPort();
+      if (tokenSource === 'file') {
+        TOKEN = generateToken();
+        tokenSource = 'generated-fallback';
+      }
+      server.listen(PORT, HOST, onListen);
+    } else {
+      console.error('Server failed to bind:', err.message);
+      process.exit(1);
+    }
+  });
+  server.listen(PORT, HOST, onListen);
+}
+
+if (require.main === module) {
+  startServer();
+}
+
+module.exports = {
+  computeAcceptKey,
+  encodeFrame,
+  decodeFrame,
+  browserLauncherForPlatform,
+  OPCODES,
+  MAX_FRAME_PAYLOAD_BYTES
+};
diff --git a/.agents/skills/brainstorming/scripts/start-server.sh b/.agents/skills/brainstorming/scripts/start-server.sh
new file mode 100755
index 0000000..016a8e4
--- /dev/null
+++ b/.agents/skills/brainstorming/scripts/start-server.sh
@@ -0,0 +1,209 @@
+#!/usr/bin/env bash
+# Start the brainstorm server and output connection info
+# Usage: start-server.sh [--project-dir <path>] [--host <bind-host>] [--url-host <display-host>] [--foreground] [--background]
+#
+# Starts server on a random high port, outputs JSON with URL.
+# Each session gets its own directory to avoid conflicts.
+#
+# Options:
+#   --project-dir <path>  Store session files under <path>/.superpowers/brainstorm/
+#                         instead of /tmp. Files persist after server stops.
+#   --host <bind-host>    Host/interface to bind (default: 127.0.0.1).
+#                         Use 0.0.0.0 in remote/containerized environments.
+#   --url-host <host>     Hostname shown in returned URL JSON.
+#   --idle-timeout-minutes <n>  Shut down after n minutes idle (default 240 = 4h).
+#   --open                Auto-open the browser on the first screen (use only
+#                         after the user approves the visual companion).
+#   --foreground          Run server in the current terminal (no backgrounding).
+#   --background          Force background mode (overrides Codex auto-foreground).
+
+SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
+
+# Parse arguments
+PROJECT_DIR=""
+FOREGROUND="false"
+FORCE_BACKGROUND="false"
+BIND_HOST="127.0.0.1"
+URL_HOST=""
+IDLE_TIMEOUT_MINUTES=""
+while [[ $# -gt 0 ]]; do
+  case "$1" in
+    --project-dir)
+      PROJECT_DIR="$2"
+      shift 2
+      ;;
+    --host)
+      BIND_HOST="$2"
+      shift 2
+      ;;
+    --url-host)
+      URL_HOST="$2"
+      shift 2
+      ;;
+    --idle-timeout-minutes)
+      IDLE_TIMEOUT_MINUTES="$2"
+      shift 2
+      ;;
+    --open)
+      export BRAINSTORM_OPEN=1
+      shift
+      ;;
+    --foreground|--no-daemon)
+      FOREGROUND="true"
+      shift
+      ;;
+    --background|--daemon)
+      FORCE_BACKGROUND="true"
+      shift
+      ;;
+    *)
+      echo "{\"error\": \"Unknown argument: $1\"}"
+      exit 1
+      ;;
+  esac
+done
+
+if [[ -z "$URL_HOST" ]]; then
+  if [[ "$BIND_HOST" == "127.0.0.1" || "$BIND_HOST" == "localhost" ]]; then
+    URL_HOST="localhost"
+  else
+    URL_HOST="$BIND_HOST"
+  fi
+fi
+
+if [[ -n "$IDLE_TIMEOUT_MINUTES" ]]; then
+  if ! [[ "$IDLE_TIMEOUT_MINUTES" =~ ^[0-9]+$ ]] || [[ "$IDLE_TIMEOUT_MINUTES" -lt 1 ]]; then
+    echo "{\"error\": \"--idle-timeout-minutes must be a positive integer\"}"
+    exit 1
+  fi
+  export BRAINSTORM_IDLE_TIMEOUT_MS=$(( IDLE_TIMEOUT_MINUTES * 60 * 1000 ))
+fi
+
+is_windows_like_shell() {
+  case "${OSTYPE:-}" in
+    msys*|cygwin*|mingw*) return 0 ;;
+  esac
+  if [[ -n "${MSYSTEM:-}" ]]; then
+    return 0
+  fi
+  local uname_s
+  uname_s="$(uname -s 2>/dev/null || true)"
+  case "$uname_s" in
+    MSYS*|MINGW*|CYGWIN*) return 0 ;;
+  esac
+  return 1
+}
+
+# Some environments reap detached/background processes. Auto-foreground when detected.
+if [[ -n "${CODEX_CI:-}" && "$FOREGROUND" != "true" && "$FORCE_BACKGROUND" != "true" ]]; then
+  FOREGROUND="true"
+fi
+
+# Windows/Git Bash reaps nohup background processes. Auto-foreground when detected.
+if [[ "$FOREGROUND" != "true" && "$FORCE_BACKGROUND" != "true" ]]; then
+  if is_windows_like_shell; then
+    FOREGROUND="true"
+  fi
+fi
+
+# Session files (server.log, server-info, .last-token) embed the session key —
+# keep everything this script and the server create owner-only.
+umask 077
+
+# Generate unique session directory
+SESSION_ID="$$-$(date +%s)"
+
+if [[ -n "$PROJECT_DIR" ]]; then
+  SESSION_DIR="${PROJECT_DIR}/.superpowers/brainstorm/${SESSION_ID}"
+  # Persist the bound port and key per project so a restart reuses them and an
+  # already-open browser tab reconnects to the same URL with a valid cookie.
+  export BRAINSTORM_PORT_FILE="${PROJECT_DIR}/.superpowers/brainstorm/.last-port"
+  export BRAINSTORM_TOKEN_FILE="${PROJECT_DIR}/.superpowers/brainstorm/.last-token"
+else
+  SESSION_DIR="/tmp/brainstorm-${SESSION_ID}"
+fi
+
+STATE_DIR="${SESSION_DIR}/state"
+PID_FILE="${STATE_DIR}/server.pid"
+LOG_FILE="${STATE_DIR}/server.log"
+SERVER_ID_FILE="${STATE_DIR}/server-instance-id"
+
+# Create fresh session directory with content and state peers
+mkdir -p "${SESSION_DIR}/content" "$STATE_DIR"
+
+SERVER_ID=""
+if [[ -r /dev/urandom ]]; then
+  SERVER_ID="$(od -An -N24 -tx1 /dev/urandom 2>/dev/null | tr -d ' \n' || true)"
+fi
+if ! [[ "$SERVER_ID" =~ ^[A-Za-z0-9_-]{32,64}$ ]]; then
+  SERVER_ID="$(printf '%08x%08x%08x%08x' "$$" "$(date +%s)" "${RANDOM:-0}" "${RANDOM:-0}")"
+fi
+printf '%s\n' "$SERVER_ID" > "$SERVER_ID_FILE"
+chmod 600 "$SERVER_ID_FILE" 2>/dev/null || true
+
+# Kill any existing server
+if [[ -f "$PID_FILE" ]]; then
+  old_pid=$(cat "$PID_FILE")
+  kill "$old_pid" 2>/dev/null
+  rm -f "$PID_FILE"
+fi
+
+cd "$SCRIPT_DIR" || exit 1
+
+# Resolve the harness PID (grandparent of this script).
+# $PPID is the ephemeral shell the harness spawned to run us — it dies
+# when this script exits. The harness itself is $PPID's parent.
+OWNER_PID="$(ps -o ppid= -p "$PPID" 2>/dev/null | tr -d ' ')"
+if [[ -z "$OWNER_PID" || "$OWNER_PID" == "1" ]]; then
+  OWNER_PID="$PPID"
+fi
+
+# Windows/MSYS2: Node.js cannot see POSIX PIDs from the MSYS2 namespace.
+# Passing a PID node cannot verify causes server to log owner-pid-invalid
+# and self-terminate at the 60-second lifecycle check. Clear it so the
+# watchdog is disabled and the idle timeout becomes the only shutdown trigger.
+if is_windows_like_shell; then
+  OWNER_PID=""
+fi
+
+# Foreground mode for environments that reap detached/background processes.
+if [[ "$FOREGROUND" == "true" ]]; then
+  env BRAINSTORM_DIR="$SESSION_DIR" BRAINSTORM_HOST="$BIND_HOST" BRAINSTORM_URL_HOST="$URL_HOST" BRAINSTORM_OWNER_PID="$OWNER_PID" node server.cjs "--brainstorm-server-id=$SERVER_ID" &
+  SERVER_PID=$!
+  echo "$SERVER_PID" > "$PID_FILE"
+  wait "$SERVER_PID"
+  exit $?
+fi
+
+# Start server, capturing output to log file
+# Use nohup to survive shell exit; disown to remove from job table
+nohup env BRAINSTORM_DIR="$SESSION_DIR" BRAINSTORM_HOST="$BIND_HOST" BRAINSTORM_URL_HOST="$URL_HOST" BRAINSTORM_OWNER_PID="$OWNER_PID" node server.cjs "--brainstorm-server-id=$SERVER_ID" > "$LOG_FILE" 2>&1 &
+SERVER_PID=$!
+disown "$SERVER_PID" 2>/dev/null
+echo "$SERVER_PID" > "$PID_FILE"
+
+# Wait for server-started message (check log file)
+for _ in {1..50}; do
+  if grep -q "server-started" "$LOG_FILE" 2>/dev/null; then
+    # Verify server is still alive after a short window (catches process reapers)
+    alive="true"
+    for _ in {1..20}; do
+      if ! kill -0 "$SERVER_PID" 2>/dev/null; then
+        alive="false"
+        break
+      fi
+      sleep 0.1
+    done
+    if [[ "$alive" != "true" ]]; then
+      echo "{\"error\": \"Server started but was killed. Retry in a persistent terminal with: $SCRIPT_DIR/start-server.sh${PROJECT_DIR:+ --project-dir $PROJECT_DIR} --host $BIND_HOST --url-host $URL_HOST --foreground\"}"
+      exit 1
+    fi
+    grep "server-started" "$LOG_FILE" | head -1
+    exit 0
+  fi
+  sleep 0.1
+done
+
+# Timeout - server didn't start
+echo '{"error": "Server failed to start within 5 seconds"}'
+exit 1
diff --git a/.agents/skills/brainstorming/scripts/stop-server.sh b/.agents/skills/brainstorming/scripts/stop-server.sh
new file mode 100755
index 0000000..7cacfe9
--- /dev/null
+++ b/.agents/skills/brainstorming/scripts/stop-server.sh
@@ -0,0 +1,120 @@
+#!/usr/bin/env bash
+# Stop the brainstorm server and clean up
+# Usage: stop-server.sh <session_dir>
+#
+# Kills the server process. Only deletes session directory if it's
+# under /tmp (ephemeral). Persistent directories (.superpowers/) are
+# kept so mockups can be reviewed later.
+
+SESSION_DIR="$1"
+
+if [[ -z "$SESSION_DIR" ]]; then
+  echo '{"error": "Usage: stop-server.sh <session_dir>"}'
+  exit 1
+fi
+
+STATE_DIR="${SESSION_DIR}/state"
+PID_FILE="${STATE_DIR}/server.pid"
+SERVER_ID_FILE="${STATE_DIR}/server-instance-id"
+
+mark_stopped() {
+  local reason="$1"
+  rm -f "${STATE_DIR}/server-info"
+  printf '{"reason":"%s","timestamp":%s}\n' "$reason" "$(date +%s)" > "${STATE_DIR}/server-stopped"
+}
+
+read_expected_server_id() {
+  [[ -f "$SERVER_ID_FILE" ]] || return 1
+  local id
+  id="$(tr -d '\r\n' < "$SERVER_ID_FILE" 2>/dev/null || true)"
+  [[ "$id" =~ ^[A-Za-z0-9_-]{32,64}$ ]] || return 1
+  printf '%s\n' "$id"
+}
+
+command_line_for_pid() {
+  local pid="$1"
+  if [[ -r "/proc/$pid/cmdline" ]]; then
+    tr '\0' '\n' < "/proc/$pid/cmdline" 2>/dev/null || true
+    return 0
+  fi
+  ps -ww -p "$pid" -o command= 2>/dev/null || ps -f -p "$pid" 2>/dev/null | sed '1d' || true
+}
+
+command_has_server_id() {
+  local pid="$1"
+  local expected="$2"
+  local expected_arg="--brainstorm-server-id=$expected"
+  if [[ -r "/proc/$pid/cmdline" ]]; then
+    local arg
+    while IFS= read -r -d '' arg || [[ -n "$arg" ]]; do
+      [[ "$arg" == "$expected_arg" ]] && return 0
+    done < "/proc/$pid/cmdline"
+    return 1
+  fi
+  local command_line
+  command_line="$(command_line_for_pid "$pid")"
+  [[ -n "$command_line" ]] || return 1
+  case " $command_line " in
+    *" $expected_arg "*) return 0 ;;
+    *) return 1 ;;
+  esac
+}
+
+# Confirm a PID has this session's per-start instance id, not just a familiar
+# process name. Ambiguous or legacy metadata fails closed as stale_pid.
+is_brainstorm_server() {
+  kill -0 "$1" 2>/dev/null || return 1
+  local expected_id
+  expected_id="$(read_expected_server_id)" || return 1
+  command_has_server_id "$1" "$expected_id" || return 1
+  return 0
+}
+
+if [[ -f "$PID_FILE" ]]; then
+  pid=$(cat "$PID_FILE")
+
+  # Refuse to signal a PID we can't prove is our server. A stale pid file may
+  # point at an unrelated process after a reboot/PID wraparound.
+  if ! is_brainstorm_server "$pid"; then
+    rm -f "$PID_FILE" "$SERVER_ID_FILE"
+    mark_stopped "stale_pid"
+    echo '{"status": "stale_pid"}'
+    exit 0
+  fi
+
+  # Try to stop gracefully, fallback to force if still alive
+  kill "$pid" 2>/dev/null || true
+
+  # Wait for graceful shutdown (up to ~2s)
+  for _ in {1..20}; do
+    if ! kill -0 "$pid" 2>/dev/null; then
+      break
+    fi
+    sleep 0.1
+  done
+
+  # If still running, escalate to SIGKILL
+  if kill -0 "$pid" 2>/dev/null; then
+    kill -9 "$pid" 2>/dev/null || true
+
+    # Give SIGKILL a moment to take effect
+    sleep 0.1
+  fi
+
+  if kill -0 "$pid" 2>/dev/null; then
+    echo '{"status": "failed", "error": "process still running"}'
+    exit 1
+  fi
+
+  rm -f "$PID_FILE" "$SERVER_ID_FILE" "${STATE_DIR}/server.log"
+  mark_stopped "stop-server.sh"
+
+  # Only delete ephemeral /tmp directories
+  if [[ "$SESSION_DIR" == /tmp/* ]]; then
+    rm -rf "$SESSION_DIR"
+  fi
+
+  echo '{"status": "stopped"}'
+else
+  echo '{"status": "not_running"}'
+fi
diff --git a/.agents/skills/brainstorming/spec-document-reviewer-prompt.md b/.agents/skills/brainstorming/spec-document-reviewer-prompt.md
new file mode 100644
index 0000000..6099312
--- /dev/null
+++ b/.agents/skills/brainstorming/spec-document-reviewer-prompt.md
@@ -0,0 +1,49 @@
+# Spec Document Reviewer Prompt Template
+
+Use this template when dispatching a spec document reviewer subagent.
+
+**Purpose:** Verify the spec is complete, consistent, and ready for implementation planning.
+
+**Dispatch after:** Spec document is written to docs/superpowers/specs/
+
+```
+Subagent (general-purpose):
+  description: "Review spec document"
+  prompt: |
+    You are a spec document reviewer. Verify this spec is complete and ready for planning.
+
+    **Spec to review:** [SPEC_FILE_PATH]
+
+    ## What to Check
+
+    | Category | What to Look For |
+    |----------|------------------|
+    | Completeness | TODOs, placeholders, "TBD", incomplete sections |
+    | Consistency | Internal contradictions, conflicting requirements |
+    | Clarity | Requirements ambiguous enough to cause someone to build the wrong thing |
+    | Scope | Focused enough for a single plan — not covering multiple independent subsystems |
+    | YAGNI | Unrequested features, over-engineering |
+
+    ## Calibration
+
+    **Only flag issues that would cause real problems during implementation planning.**
+    A missing section, a contradiction, or a requirement so ambiguous it could be
+    interpreted two different ways — those are issues. Minor wording improvements,
+    stylistic preferences, and "sections less detailed than others" are not.
+
+    Approve unless there are serious gaps that would lead to a flawed plan.
+
+    ## Output Format
+
+    ## Spec Review
+
+    **Status:** Approved | Issues Found
+
+    **Issues (if any):**
+    - [Section X]: [specific issue] - [why it matters for planning]
+
+    **Recommendations (advisory, do not block approval):**
+    - [suggestions for improvement]
+```
+
+**Reviewer returns:** Status, Issues (if any), Recommendations
diff --git a/.agents/skills/brainstorming/visual-companion.md b/.agents/skills/brainstorming/visual-companion.md
new file mode 100644
index 0000000..7b89f6b
--- /dev/null
+++ b/.agents/skills/brainstorming/visual-companion.md
@@ -0,0 +1,291 @@
+# Visual Companion Guide
+
+Browser-based visual brainstorming companion for showing mockups, diagrams, and options.
+
+## When to Use
+
+Decide per-question, not per-session. The test: **would the user understand this better by seeing it than reading it?**
+
+**Use the browser** when the content itself is visual:
+
+- **UI mockups** — wireframes, layouts, navigation structures, component designs
+- **Architecture diagrams** — system components, data flow, relationship maps
+- **Side-by-side visual comparisons** — comparing two layouts, two color schemes, two design directions
+- **Design polish** — when the question is about look and feel, spacing, visual hierarchy
+- **Spatial relationships** — state machines, flowcharts, entity relationships rendered as diagrams
+
+**Use the terminal** when the content is text or tabular:
+
+- **Requirements and scope questions** — "what does X mean?", "which features are in scope?"
+- **Conceptual A/B/C choices** — picking between approaches described in words
+- **Tradeoff lists** — pros/cons, comparison tables
+- **Technical decisions** — API design, data modeling, architectural approach selection
+- **Clarifying questions** — anything where the answer is words, not a visual preference
+
+A question *about* a UI topic is not automatically a visual question. "What kind of wizard do you want?" is conceptual — use the terminal. "Which of these wizard layouts feels right?" is visual — use the browser.
+
+## How It Works
+
+The server watches a directory for HTML files and serves the newest one to the browser. You write HTML content to `screen_dir`, the user sees it in their browser and can click to select options. Selections are recorded to `state_dir/events` that you read on your next turn.
+
+**Content fragments vs full documents:** If your HTML file starts with `<!DOCTYPE` or `<html`, the server serves it as-is (just injects the helper script). Otherwise, the server automatically wraps your content in the frame template — adding the header, CSS theme, connection status, and all interactive infrastructure. **Write content fragments by default.** Only write full documents when you need complete control over the page.
+
+## Starting a Session
+
+```bash
+# Start AFTER the user approves the companion. --open auto-opens their browser on
+# the first screen; --project-dir persists mockups and enables same-port restart.
+scripts/start-server.sh --project-dir /path/to/project --open
+
+# Returns: {"type":"server-started","port":52341,
+#           "url":"http://localhost:52341/?key=ab12…",
+#           "screen_dir":"/path/to/project/.superpowers/brainstorm/12345-1706000000/content",
+#           "state_dir":"/path/to/project/.superpowers/brainstorm/12345-1706000000/state"}
+```
+
+Save `screen_dir` and `state_dir` from the response. With `--open`, the browser opens itself when you push the first screen — you don't need to ask the user to open it, but still share the URL as a fallback (headless/remote setups won't auto-open).
+
+**The URL contains a session key (`?key=…`).** The server rejects any request
+without it, so always give the user the **complete** URL from the `url` field —
+never strip the query string, and never hand out a bare `http://host:port`. The
+key gates HTTP and WebSocket access so a stray browser tab or another machine on
+the network can't read the screens or inject events. After the first load the
+browser remembers the key via a cookie, so reloads and `/files/*` assets work
+without repeating it.
+
+**Finding connection info:** The server writes its startup JSON to `$STATE_DIR/server-info`. If you launched the server in the background and didn't capture stdout, read that file to get the URL and port. When using `--project-dir`, check `<project>/.superpowers/brainstorm/` for the session directory.
+
+**Note:** Pass the project root as `--project-dir` so mockups persist in `.superpowers/brainstorm/` and survive server restarts. Without it, files go to `/tmp` and get cleaned up. Remind the user to add `.superpowers/` to `.gitignore` if it's not already there.
+
+**Launching the server by platform:**
+
+**Claude Code:**
+```bash
+# Default mode works — the script backgrounds the server itself.
+scripts/start-server.sh --project-dir /path/to/project --open
+```
+
+On Windows, the script auto-detects and switches to foreground mode (which blocks the tool call). Use `run_in_background: true` on the Bash tool call so the server survives across conversation turns, then read `$STATE_DIR/server-info` on the next turn to get the URL and port.
+
+**Codex:**
+```bash
+# Codex reaps background processes. The script auto-detects CODEX_CI and
+# switches to foreground mode. Run it normally — no extra flags needed.
+scripts/start-server.sh --project-dir /path/to/project --open
+```
+
+**Copilot CLI:**
+```bash
+# Use --foreground and start the server via the bash tool with mode: "async"
+# so the process survives across turns. Capture the returned shellId for
+# read_bash / stop_bash if you need to interact with it later.
+scripts/start-server.sh --project-dir /path/to/project --open --foreground
+```
+
+**Other environments:** The server must keep running in the background across conversation turns. If your environment reaps detached processes, use `--foreground` and launch the command with your platform's background execution mechanism.
+
+If the URL is unreachable from your browser (common in remote/containerized setups), bind a non-loopback host:
+
+```bash
+scripts/start-server.sh \
+  --project-dir /path/to/project \
+  --host 0.0.0.0 \
+  --url-host localhost
+```
+
+Use `--url-host` to control what hostname is printed in the returned URL JSON.
+
+## The Loop
+
+1. **Check server is alive**, then **write HTML** to a new file in `screen_dir`:
+   - **Required: confirm the server is alive before referring to the URL or pushing a screen.** Check that `$STATE_DIR/server-info` exists and `$STATE_DIR/server-stopped` does not. If it has shut down, restart it with `start-server.sh` using the **same `--project-dir`** — it reuses the same port, so the user's open tab reconnects on its own (it shows a "paused" overlay while the server is down) and you don't need to send a new URL. The server auto-exits after 4 hours idle (configurable with `--idle-timeout-minutes`).
+   - Use semantic filenames: `platform.html`, `visual-style.html`, `layout.html`
+   - **Never reuse filenames** — each screen gets a fresh file
+   - Use your file-creation tool — **never use cat/heredoc** (dumps noise into terminal)
+   - Server automatically serves the newest file
+
+2. **Tell user what to expect and end your turn:**
+   - Remind them of the URL (every step, not just first)
+   - Give a brief text summary of what's on screen (e.g., "Showing 3 layout options for the homepage")
+   - Ask them to respond in the terminal: "Take a look and let me know what you think. Click to select an option if you'd like."
+
+3. **On your next turn** — after the user responds in the terminal:
+   - Read `$STATE_DIR/events` if it exists — this contains the user's browser interactions (clicks, selections) as JSON lines
+   - Merge with the user's terminal text to get the full picture
+   - The terminal message is the primary feedback; `state_dir/events` provides structured interaction data
+
+4. **Iterate or advance** — if feedback changes current screen, write a new file (e.g., `layout-v2.html`). Only move to the next question when the current step is validated.
+
+5. **Unload when returning to terminal** — when the next step doesn't need the browser (e.g., a clarifying question, a tradeoff discussion), push a waiting screen to clear the stale content:
+
+   ```html
+   <!-- filename: waiting.html (or waiting-2.html, etc.) -->
+   <div style="display:flex;align-items:center;justify-content:center;min-height:60vh">
+     <p class="subtitle">Continuing in terminal...</p>
+   </div>
+   ```
+
+   This prevents the user from staring at a resolved choice while the conversation has moved on. When the next visual question comes up, push a new content file as usual.
+
+6. Repeat until done.
+
+## Writing Content Fragments
+
+Write just the content that goes inside the page. The server wraps it in the frame template automatically (header, theme CSS, connection status, and all interactive infrastructure).
+
+**Minimal example:**
+
+```html
+<h2>Which layout works better?</h2>
+<p class="subtitle">Consider readability and visual hierarchy</p>
+
+<div class="options">
+  <div class="option" data-choice="a" onclick="toggleSelect(this)">
+    <div class="letter">A</div>
+    <div class="content">
+      <h3>Single Column</h3>
+      <p>Clean, focused reading experience</p>
+    </div>
+  </div>
+  <div class="option" data-choice="b" onclick="toggleSelect(this)">
+    <div class="letter">B</div>
+    <div class="content">
+      <h3>Two Column</h3>
+      <p>Sidebar navigation with main content</p>
+    </div>
+  </div>
+</div>
+```
+
+That's it. No `<html>`, no CSS, no `<script>` tags needed. The server provides all of that.
+
+## CSS Classes Available
+
+The frame template provides these CSS classes for your content:
+
+### Options (A/B/C choices)
+
+```html
+<div class="options">
+  <div class="option" data-choice="a" onclick="toggleSelect(this)">
+    <div class="letter">A</div>
+    <div class="content">
+      <h3>Title</h3>
+      <p>Description</p>
+    </div>
+  </div>
+</div>
+```
+
+**Multi-select:** Add `data-multiselect` to the container to let users select multiple options. Each click toggles the item's selected styling.
+
+```html
+<div class="options" data-multiselect>
+  <!-- same option markup — users can select/deselect multiple -->
+</div>
+```
+
+### Cards (visual designs)
+
+```html
+<div class="cards">
+  <div class="card" data-choice="design1" onclick="toggleSelect(this)">
+    <div class="card-image"><!-- mockup content --></div>
+    <div class="card-body">
+      <h3>Name</h3>
+      <p>Description</p>
+    </div>
+  </div>
+</div>
+```
+
+### Mockup container
+
+```html
+<div class="mockup">
+  <div class="mockup-header">Preview: Dashboard Layout</div>
+  <div class="mockup-body"><!-- your mockup HTML --></div>
+</div>
+```
+
+### Split view (side-by-side)
+
+```html
+<div class="split">
+  <div class="mockup"><!-- left --></div>
+  <div class="mockup"><!-- right --></div>
+</div>
+```
+
+### Pros/Cons
+
+```html
+<div class="pros-cons">
+  <div class="pros"><h4>Pros</h4><ul><li>Benefit</li></ul></div>
+  <div class="cons"><h4>Cons</h4><ul><li>Drawback</li></ul></div>
+</div>
+```
+
+### Mock elements (wireframe building blocks)
+
+```html
+<div class="mock-nav">Logo | Home | About | Contact</div>
+<div style="display: flex;">
+  <div class="mock-sidebar">Navigation</div>
+  <div class="mock-content">Main content area</div>
+</div>
+<button class="mock-button">Action Button</button>
+<input class="mock-input" placeholder="Input field">
+<div class="placeholder">Placeholder area</div>
+```
+
+### Typography and sections
+
+- `h2` — page title
+- `h3` — section heading
+- `.subtitle` — secondary text below title
+- `.section` — content block with bottom margin
+- `.label` — small uppercase label text
+
+## Browser Events Format
+
+When the user clicks options in the browser, their interactions are recorded to `$STATE_DIR/events` (one JSON object per line). The file is cleared automatically when you push a new screen.
+
+```jsonl
+{"type":"click","choice":"a","text":"Option A - Simple Layout","timestamp":1706000101}
+{"type":"click","choice":"c","text":"Option C - Complex Grid","timestamp":1706000108}
+{"type":"click","choice":"b","text":"Option B - Hybrid","timestamp":1706000115}
+```
+
+The full event stream shows the user's exploration path — they may click multiple options before settling. The last `choice` event is typically the final selection, but the pattern of clicks can reveal hesitation or preferences worth asking about.
+
+If `$STATE_DIR/events` doesn't exist, the user didn't interact with the browser — use only their terminal text.
+
+## Design Tips
+
+- **Scale fidelity to the question** — wireframes for layout, polish for polish questions
+- **Explain the question on each page** — "Which layout feels more professional?" not just "Pick one"
+- **Iterate before advancing** — if feedback changes current screen, write a new version
+- **2-4 options max** per screen
+- **Use real content when it matters** — for a photography portfolio, use actual images (Unsplash). Placeholder content obscures design issues.
+- **Keep mockups simple** — focus on layout and structure, not pixel-perfect design
+
+## File Naming
+
+- Use semantic names: `platform.html`, `visual-style.html`, `layout.html`
+- Never reuse filenames — each screen must be a new file
+- For iterations: append version suffix like `layout-v2.html`, `layout-v3.html`
+- Server serves newest file by modification time
+
+## Cleaning Up
+
+```bash
+scripts/stop-server.sh $SESSION_DIR
+```
+
+If the session used `--project-dir`, mockup files persist in `.superpowers/brainstorm/` for later reference. Only `/tmp` sessions get deleted on stop.
+
+## Reference
+
+- Frame template (CSS reference): `scripts/frame-template.html`
+- Helper script (client-side): `scripts/helper.js`
diff --git a/.agents/skills/dispatching-parallel-agents/SKILL.md b/.agents/skills/dispatching-parallel-agents/SKILL.md
new file mode 100644
index 0000000..75e7e22
--- /dev/null
+++ b/.agents/skills/dispatching-parallel-agents/SKILL.md
@@ -0,0 +1,185 @@
+---
+name: dispatching-parallel-agents
+description: Use when facing 2+ independent tasks that can be worked on without shared state or sequential dependencies
+---
+
+# Dispatching Parallel Agents
+
+## Overview
+
+You delegate tasks to specialized agents with isolated context. By precisely crafting their instructions and context, you ensure they stay focused and succeed at their task. They should never inherit your session's context or history — you construct exactly what they need. This also preserves your own context for coordination work.
+
+When you have multiple unrelated failures (different test files, different subsystems, different bugs), investigating them sequentially wastes time. Each investigation is independent and can happen in parallel.
+
+**Core principle:** Dispatch one agent per independent problem domain. Let them work concurrently.
+
+## When to Use
+
+```dot
+digraph when_to_use {
+    "Multiple failures?" [shape=diamond];
+    "Are they independent?" [shape=diamond];
+    "Single agent investigates all" [shape=box];
+    "One agent per problem domain" [shape=box];
+    "Can they work in parallel?" [shape=diamond];
+    "Sequential agents" [shape=box];
+    "Parallel dispatch" [shape=box];
+
+    "Multiple failures?" -> "Are they independent?" [label="yes"];
+    "Are they independent?" -> "Single agent investigates all" [label="no - related"];
+    "Are they independent?" -> "Can they work in parallel?" [label="yes"];
+    "Can they work in parallel?" -> "Parallel dispatch" [label="yes"];
+    "Can they work in parallel?" -> "Sequential agents" [label="no - shared state"];
+}
+```
+
+**Use when:**
+- 3+ test files failing with different root causes
+- Multiple subsystems broken independently
+- Each problem can be understood without context from others
+- No shared state between investigations
+
+**Don't use when:**
+- Failures are related (fix one might fix others)
+- Need to understand full system state
+- Agents would interfere with each other
+
+## The Pattern
+
+### 1. Identify Independent Domains
+
+Group failures by what's broken:
+- File A tests: Tool approval flow
+- File B tests: Batch completion behavior
+- File C tests: Abort functionality
+
+Each domain is independent - fixing tool approval doesn't affect abort tests.
+
+### 2. Create Focused Agent Tasks
+
+Each agent gets:
+- **Specific scope:** One test file or subsystem
+- **Clear goal:** Make these tests pass
+- **Constraints:** Don't change other code
+- **Expected output:** Summary of what you found and fixed
+
+### 3. Dispatch in Parallel
+
+Issue all three subagent dispatches in the same response — they run in parallel:
+
+```text
+Subagent (general-purpose): "Fix agent-tool-abort.test.ts failures"
+Subagent (general-purpose): "Fix batch-completion-behavior.test.ts failures"
+Subagent (general-purpose): "Fix tool-approval-race-conditions.test.ts failures"
+# All three run concurrently.
+```
+
+Multiple dispatch calls in one response = parallel execution. One per response = sequential.
+
+### 4. Review and Integrate
+
+When agents return:
+- Read each summary
+- Verify fixes don't conflict
+- Run full test suite
+- Integrate all changes
+
+## Agent Prompt Structure
+
+Good agent prompts are:
+1. **Focused** - One clear problem domain
+2. **Self-contained** - All context needed to understand the problem
+3. **Specific about output** - What should the agent return?
+
+```markdown
+Fix the 3 failing tests in src/agents/agent-tool-abort.test.ts:
+
+1. "should abort tool with partial output capture" - expects 'interrupted at' in message
+2. "should handle mixed completed and aborted tools" - fast tool aborted instead of completed
+3. "should properly track pendingToolCount" - expects 3 results but gets 0
+
+These are timing/race condition issues. Your task:
+
+1. Read the test file and understand what each test verifies
+2. Identify root cause - timing issues or actual bugs?
+3. Fix by:
+   - Replacing arbitrary timeouts with event-based waiting
+   - Fixing bugs in abort implementation if found
+   - Adjusting test expectations if testing changed behavior
+
+Do NOT just increase timeouts - find the real issue.
+
+Return: Summary of what you found and what you fixed.
+```
+
+## Common Mistakes
+
+**❌ Too broad:** "Fix all the tests" - agent gets lost
+**✅ Specific:** "Fix agent-tool-abort.test.ts" - focused scope
+
+**❌ No context:** "Fix the race condition" - agent doesn't know where
+**✅ Context:** Paste the error messages and test names
+
+**❌ No constraints:** Agent might refactor everything
+**✅ Constraints:** "Do NOT change production code" or "Fix tests only"
+
+**❌ Vague output:** "Fix it" - you don't know what changed
+**✅ Specific:** "Return summary of root cause and changes"
+
+## When NOT to Use
+
+**Related failures:** Fixing one might fix others - investigate together first
+**Need full context:** Understanding requires seeing entire system
+**Exploratory debugging:** You don't know what's broken yet
+**Shared state:** Agents would interfere (editing same files, using same resources)
+
+## Real Example from Session
+
+**Scenario:** 6 test failures across 3 files after major refactoring
+
+**Failures:**
+- agent-tool-abort.test.ts: 3 failures (timing issues)
+- batch-completion-behavior.test.ts: 2 failures (tools not executing)
+- tool-approval-race-conditions.test.ts: 1 failure (execution count = 0)
+
+**Decision:** Independent domains - abort logic separate from batch completion separate from race conditions
+
+**Dispatch:**
+```
+Agent 1 → Fix agent-tool-abort.test.ts
+Agent 2 → Fix batch-completion-behavior.test.ts
+Agent 3 → Fix tool-approval-race-conditions.test.ts
+```
+
+**Results:**
+- Agent 1: Replaced timeouts with event-based waiting
+- Agent 2: Fixed event structure bug (threadId in wrong place)
+- Agent 3: Added wait for async tool execution to complete
+
+**Integration:** All fixes independent, no conflicts, full suite green
+
+**Time saved:** 3 problems solved in parallel vs sequentially
+
+## Key Benefits
+
+1. **Parallelization** - Multiple investigations happen simultaneously
+2. **Focus** - Each agent has narrow scope, less context to track
+3. **Independence** - Agents don't interfere with each other
+4. **Speed** - 3 problems solved in time of 1
+
+## Verification
+
+After agents return:
+1. **Review each summary** - Understand what changed
+2. **Check for conflicts** - Did agents edit same code?
+3. **Run full suite** - Verify all fixes work together
+4. **Spot check** - Agents can make systematic errors
+
+## Real-World Impact
+
+From debugging session (2025-10-03):
+- 6 failures across 3 files
+- 3 agents dispatched in parallel
+- All investigations completed concurrently
+- All fixes integrated successfully
+- Zero conflicts between agent changes
diff --git a/.agents/skills/executing-plans/SKILL.md b/.agents/skills/executing-plans/SKILL.md
new file mode 100644
index 0000000..075a103
--- /dev/null
+++ b/.agents/skills/executing-plans/SKILL.md
@@ -0,0 +1,70 @@
+---
+name: executing-plans
+description: Use when you have a written implementation plan to execute in a separate session with review checkpoints
+---
+
+# Executing Plans
+
+## Overview
+
+Load plan, review critically, execute all tasks, report when complete.
+
+**Announce at start:** "I'm using the executing-plans skill to implement this plan."
+
+**Note:** Tell your human partner that Superpowers works much better with access to subagents. The quality of its work will be significantly higher if run on a platform with subagent support (Claude Code, Codex CLI, Codex App, and Copilot CLI all qualify; see the per-platform tool refs in `../using-superpowers/references/`). If subagents are available, use superpowers:subagent-driven-development instead of this skill.
+
+## The Process
+
+### Step 1: Load and Review Plan
+1. Read plan file
+2. Review critically - identify any questions or concerns about the plan
+3. If concerns: Raise them with your human partner before starting
+4. If no concerns: Create todos for the plan items and proceed
+
+### Step 2: Execute Tasks
+
+For each task:
+1. Mark as in_progress
+2. Follow each step exactly (plan has bite-sized steps)
+3. Run verifications as specified
+4. Mark as completed
+
+### Step 3: Complete Development
+
+After all tasks complete and verified:
+- Announce: "I'm using the finishing-a-development-branch skill to complete this work."
+- **REQUIRED SUB-SKILL:** Use superpowers:finishing-a-development-branch
+- Follow that skill to verify tests, present options, execute choice
+
+## When to Stop and Ask for Help
+
+**STOP executing immediately when:**
+- Hit a blocker (missing dependency, test fails, instruction unclear)
+- Plan has critical gaps preventing starting
+- You don't understand an instruction
+- Verification fails repeatedly
+
+**Ask for clarification rather than guessing.**
+
+## When to Revisit Earlier Steps
+
+**Return to Review (Step 1) when:**
+- Partner updates the plan based on your feedback
+- Fundamental approach needs rethinking
+
+**Don't force through blockers** - stop and ask.
+
+## Remember
+- Review plan critically first
+- Follow plan steps exactly
+- Don't skip verifications
+- Reference skills when plan says to
+- Stop when blocked, don't guess
+- Never start implementation on main/master branch without explicit user consent
+
+## Integration
+
+**Required workflow skills:**
+- **superpowers:using-git-worktrees** - Ensures isolated workspace (creates one or verifies existing)
+- **superpowers:writing-plans** - Creates the plan this skill executes
+- **superpowers:finishing-a-development-branch** - Complete development after all tasks
diff --git a/.agents/skills/finishing-a-development-branch/SKILL.md b/.agents/skills/finishing-a-development-branch/SKILL.md
new file mode 100644
index 0000000..7f5337a
--- /dev/null
+++ b/.agents/skills/finishing-a-development-branch/SKILL.md
@@ -0,0 +1,241 @@
+---
+name: finishing-a-development-branch
+description: Use when implementation is complete, all tests pass, and you need to decide how to integrate the work - guides completion of development work by presenting structured options for merge, PR, or cleanup
+---
+
+# Finishing a Development Branch
+
+## Overview
+
+Guide completion of development work by presenting clear options and handling chosen workflow.
+
+**Core principle:** Verify tests → Detect environment → Present options → Execute choice → Clean up.
+
+**Announce at start:** "I'm using the finishing-a-development-branch skill to complete this work."
+
+## The Process
+
+### Step 1: Verify Tests
+
+**Before presenting options, verify tests pass:**
+
+```bash
+# Run project's test suite
+npm test / cargo test / pytest / go test ./...
+```
+
+**If tests fail:**
+```
+Tests failing (<N> failures). Must fix before completing:
+
+[Show failures]
+
+Cannot proceed with merge/PR until tests pass.
+```
+
+Stop. Don't proceed to Step 2.
+
+**If tests pass:** Continue to Step 2.
+
+### Step 2: Detect Environment
+
+**Determine workspace state before presenting options:**
+
+```bash
+GIT_DIR=$(cd "$(git rev-parse --git-dir)" 2>/dev/null && pwd -P)
+GIT_COMMON=$(cd "$(git rev-parse --git-common-dir)" 2>/dev/null && pwd -P)
+```
+
+This determines which menu to show and how cleanup works:
+
+| State | Menu | Cleanup |
+|-------|------|---------|
+| `GIT_DIR == GIT_COMMON` (normal repo) | Standard 4 options | No worktree to clean up |
+| `GIT_DIR != GIT_COMMON`, named branch | Standard 4 options | Provenance-based (see Step 6) |
+| `GIT_DIR != GIT_COMMON`, detached HEAD | Reduced 3 options (no merge) | No cleanup (externally managed) |
+
+### Step 3: Determine Base Branch
+
+```bash
+# Try common base branches
+git merge-base HEAD main 2>/dev/null || git merge-base HEAD master 2>/dev/null
+```
+
+Or ask: "This branch split from main - is that correct?"
+
+### Step 4: Present Options
+
+**Normal repo and named-branch worktree — present exactly these 4 options:**
+
+```
+Implementation complete. What would you like to do?
+
+1. Merge back to <base-branch> locally
+2. Push and create a Pull Request
+3. Keep the branch as-is (I'll handle it later)
+4. Discard this work
+
+Which option?
+```
+
+**Detached HEAD — present exactly these 3 options:**
+
+```
+Implementation complete. You're on a detached HEAD (externally managed workspace).
+
+1. Push as new branch and create a Pull Request
+2. Keep as-is (I'll handle it later)
+3. Discard this work
+
+Which option?
+```
+
+**Don't add explanation** - keep options concise.
+
+### Step 5: Execute Choice
+
+#### Option 1: Merge Locally
+
+```bash
+# Get main repo root for CWD safety
+MAIN_ROOT=$(git -C "$(git rev-parse --git-common-dir)/.." rev-parse --show-toplevel)
+cd "$MAIN_ROOT"
+
+# Merge first — verify success before removing anything
+git checkout <base-branch>
+git pull
+git merge <feature-branch>
+
+# Verify tests on merged result
+<test command>
+
+# Only after merge succeeds: cleanup worktree (Step 6), then delete branch
+```
+
+Then: Cleanup worktree (Step 6), then delete branch:
+
+```bash
+git branch -d <feature-branch>
+```
+
+#### Option 2: Push and Create PR
+
+```bash
+# Push branch
+git push -u origin <feature-branch>
+```
+
+**Do NOT clean up worktree** — user needs it alive to iterate on PR feedback.
+
+#### Option 3: Keep As-Is
+
+Report: "Keeping branch <name>. Worktree preserved at <path>."
+
+**Don't cleanup worktree.**
+
+#### Option 4: Discard
+
+**Confirm first:**
+```
+This will permanently delete:
+- Branch <name>
+- All commits: <commit-list>
+- Worktree at <path>
+
+Type 'discard' to confirm.
+```
+
+Wait for exact confirmation.
+
+If confirmed:
+```bash
+MAIN_ROOT=$(git -C "$(git rev-parse --git-common-dir)/.." rev-parse --show-toplevel)
+cd "$MAIN_ROOT"
+```
+
+Then: Cleanup worktree (Step 6), then force-delete branch:
+```bash
+git branch -D <feature-branch>
+```
+
+### Step 6: Cleanup Workspace
+
+**Only runs for Options 1 and 4.** Options 2 and 3 always preserve the worktree.
+
+```bash
+GIT_DIR=$(cd "$(git rev-parse --git-dir)" 2>/dev/null && pwd -P)
+GIT_COMMON=$(cd "$(git rev-parse --git-common-dir)" 2>/dev/null && pwd -P)
+WORKTREE_PATH=$(git rev-parse --show-toplevel)
+```
+
+**If `GIT_DIR == GIT_COMMON`:** Normal repo, no worktree to clean up. Done.
+
+**If worktree path is under `.worktrees/` or `worktrees/`:** Superpowers created this worktree — we own cleanup.
+
+```bash
+MAIN_ROOT=$(git -C "$(git rev-parse --git-common-dir)/.." rev-parse --show-toplevel)
+cd "$MAIN_ROOT"
+git worktree remove "$WORKTREE_PATH"
+git worktree prune  # Self-healing: clean up any stale registrations
+```
+
+**Otherwise:** The host environment (harness) owns this workspace. Do NOT remove it. If your platform provides a workspace-exit tool, use it. Otherwise, leave the workspace in place.
+
+## Quick Reference
+
+| Option | Merge | Push | Keep Worktree | Cleanup Branch |
+|--------|-------|------|---------------|----------------|
+| 1. Merge locally | yes | - | - | yes |
+| 2. Create PR | - | yes | yes | - |
+| 3. Keep as-is | - | - | yes | - |
+| 4. Discard | - | - | - | yes (force) |
+
+## Common Mistakes
+
+**Skipping test verification**
+- **Problem:** Merge broken code, create failing PR
+- **Fix:** Always verify tests before offering options
+
+**Open-ended questions**
+- **Problem:** "What should I do next?" is ambiguous
+- **Fix:** Present exactly 4 structured options (or 3 for detached HEAD)
+
+**Cleaning up worktree for Option 2**
+- **Problem:** Remove worktree user needs for PR iteration
+- **Fix:** Only cleanup for Options 1 and 4
+
+**Deleting branch before removing worktree**
+- **Problem:** `git branch -d` fails because worktree still references the branch
+- **Fix:** Merge first, remove worktree, then delete branch
+
+**Running git worktree remove from inside the worktree**
+- **Problem:** Command fails silently when CWD is inside the worktree being removed
+- **Fix:** Always `cd` to main repo root before `git worktree remove`
+
+**Cleaning up harness-owned worktrees**
+- **Problem:** Removing a worktree the harness created causes phantom state
+- **Fix:** Only clean up worktrees under `.worktrees/` or `worktrees/`
+
+**No confirmation for discard**
+- **Problem:** Accidentally delete work
+- **Fix:** Require typed "discard" confirmation
+
+## Red Flags
+
+**Never:**
+- Proceed with failing tests
+- Merge without verifying tests on result
+- Delete work without confirmation
+- Force-push without explicit request
+- Remove a worktree before confirming merge success
+- Clean up worktrees you didn't create (provenance check)
+- Run `git worktree remove` from inside the worktree
+
+**Always:**
+- Verify tests before offering options
+- Detect environment before presenting menu
+- Present exactly 4 options (or 3 for detached HEAD)
+- Get typed confirmation for Option 4
+- Clean up worktree for Options 1 & 4 only
+- `cd` to main repo root before worktree removal
+- Run `git worktree prune` after removal
diff --git a/.agents/skills/receiving-code-review/SKILL.md b/.agents/skills/receiving-code-review/SKILL.md
new file mode 100644
index 0000000..4c77a10
--- /dev/null
+++ b/.agents/skills/receiving-code-review/SKILL.md
@@ -0,0 +1,213 @@
+---
+name: receiving-code-review
+description: Use when receiving code review feedback, before implementing suggestions, especially if feedback seems unclear or technically questionable - requires technical rigor and verification, not performative agreement or blind implementation
+---
+
+# Code Review Reception
+
+## Overview
+
+Code review requires technical evaluation, not emotional performance.
+
+**Core principle:** Verify before implementing. Ask before assuming. Technical correctness over social comfort.
+
+## The Response Pattern
+
+```
+WHEN receiving code review feedback:
+
+1. READ: Complete feedback without reacting
+2. UNDERSTAND: Restate requirement in own words (or ask)
+3. VERIFY: Check against codebase reality
+4. EVALUATE: Technically sound for THIS codebase?
+5. RESPOND: Technical acknowledgment or reasoned pushback
+6. IMPLEMENT: One item at a time, test each
+```
+
+## Forbidden Responses
+
+**NEVER:**
+- "You're absolutely right!" (explicit instruction-file violation)
+- "Great point!" / "Excellent feedback!" (performative)
+- "Let me implement that now" (before verification)
+
+**INSTEAD:**
+- Restate the technical requirement
+- Ask clarifying questions
+- Push back with technical reasoning if wrong
+- Just start working (actions > words)
+
+## Handling Unclear Feedback
+
+```
+IF any item is unclear:
+  STOP - do not implement anything yet
+  ASK for clarification on unclear items
+
+WHY: Items may be related. Partial understanding = wrong implementation.
+```
+
+**Example:**
+```
+your human partner: "Fix 1-6"
+You understand 1,2,3,6. Unclear on 4,5.
+
+❌ WRONG: Implement 1,2,3,6 now, ask about 4,5 later
+✅ RIGHT: "I understand items 1,2,3,6. Need clarification on 4 and 5 before proceeding."
+```
+
+## Source-Specific Handling
+
+### From your human partner
+- **Trusted** - implement after understanding
+- **Still ask** if scope unclear
+- **No performative agreement**
+- **Skip to action** or technical acknowledgment
+
+### From External Reviewers
+```
+BEFORE implementing:
+  1. Check: Technically correct for THIS codebase?
+  2. Check: Breaks existing functionality?
+  3. Check: Reason for current implementation?
+  4. Check: Works on all platforms/versions?
+  5. Check: Does reviewer understand full context?
+
+IF suggestion seems wrong:
+  Push back with technical reasoning
+
+IF can't easily verify:
+  Say so: "I can't verify this without [X]. Should I [investigate/ask/proceed]?"
+
+IF conflicts with your human partner's prior decisions:
+  Stop and discuss with your human partner first
+```
+
+**your human partner's rule:** "External feedback - be skeptical, but check carefully"
+
+## YAGNI Check for "Professional" Features
+
+```
+IF reviewer suggests "implementing properly":
+  grep codebase for actual usage
+
+  IF unused: "This endpoint isn't called. Remove it (YAGNI)?"
+  IF used: Then implement properly
+```
+
+**your human partner's rule:** "You and reviewer both report to me. If we don't need this feature, don't add it."
+
+## Implementation Order
+
+```
+FOR multi-item feedback:
+  1. Clarify anything unclear FIRST
+  2. Then implement in this order:
+     - Blocking issues (breaks, security)
+     - Simple fixes (typos, imports)
+     - Complex fixes (refactoring, logic)
+  3. Test each fix individually
+  4. Verify no regressions
+```
+
+## When To Push Back
+
+Push back when:
+- Suggestion breaks existing functionality
+- Reviewer lacks full context
+- Violates YAGNI (unused feature)
+- Technically incorrect for this stack
+- Legacy/compatibility reasons exist
+- Conflicts with your human partner's architectural decisions
+
+**How to push back:**
+- Use technical reasoning, not defensiveness
+- Ask specific questions
+- Reference working tests/code
+- Involve your human partner if architectural
+
+**If you're uncomfortable pushing back out loud:** Name that tension, then tell your partner about the issue you've seen. They'll appreciate your honesty.
+
+## Acknowledging Correct Feedback
+
+When feedback IS correct:
+```
+✅ "Fixed. [Brief description of what changed]"
+✅ "Good catch - [specific issue]. Fixed in [location]."
+✅ [Just fix it and show in the code]
+
+❌ "You're absolutely right!"
+❌ "Great point!"
+❌ "Thanks for catching that!"
+❌ "Thanks for [anything]"
+❌ ANY gratitude expression
+```
+
+**Why no thanks:** Actions speak. Just fix it. The code itself shows you heard the feedback.
+
+**If you catch yourself about to write "Thanks":** DELETE IT. State the fix instead.
+
+## Gracefully Correcting Your Pushback
+
+If you pushed back and were wrong:
+```
+✅ "You were right - I checked [X] and it does [Y]. Implementing now."
+✅ "Verified this and you're correct. My initial understanding was wrong because [reason]. Fixing."
+
+❌ Long apology
+❌ Defending why you pushed back
+❌ Over-explaining
+```
+
+State the correction factually and move on.
+
+## Common Mistakes
+
+| Mistake | Fix |
+|---------|-----|
+| Performative agreement | State requirement or just act |
+| Blind implementation | Verify against codebase first |
+| Batch without testing | One at a time, test each |
+| Assuming reviewer is right | Check if breaks things |
+| Avoiding pushback | Technical correctness > comfort |
+| Partial implementation | Clarify all items first |
+| Can't verify, proceed anyway | State limitation, ask for direction |
+
+## Real Examples
+
+**Performative Agreement (Bad):**
+```
+Reviewer: "Remove legacy code"
+❌ "You're absolutely right! Let me remove that..."
+```
+
+**Technical Verification (Good):**
+```
+Reviewer: "Remove legacy code"
+✅ "Checking... build target is 10.15+, this API needs 13+. Need legacy for backward compat. Current impl has wrong bundle ID - fix it or drop pre-13 support?"
+```
+
+**YAGNI (Good):**
+```
+Reviewer: "Implement proper metrics tracking with database, date filters, CSV export"
+✅ "Grepped codebase - nothing calls this endpoint. Remove it (YAGNI)? Or is there usage I'm missing?"
+```
+
+**Unclear Item (Good):**
+```
+your human partner: "Fix items 1-6"
+You understand 1,2,3,6. Unclear on 4,5.
+✅ "Understand 1,2,3,6. Need clarification on 4 and 5 before implementing."
+```
+
+## GitHub Thread Replies
+
+When replying to inline review comments on GitHub, reply in the comment thread (`gh api repos/{owner}/{repo}/pulls/{pr}/comments/{id}/replies`), not as a top-level PR comment.
+
+## The Bottom Line
+
+**External feedback = suggestions to evaluate, not orders to follow.**
+
+Verify. Question. Then implement.
+
+No performative agreement. Technical rigor always.
diff --git a/.agents/skills/requesting-code-review/SKILL.md b/.agents/skills/requesting-code-review/SKILL.md
new file mode 100644
index 0000000..4b8aa60
--- /dev/null
+++ b/.agents/skills/requesting-code-review/SKILL.md
@@ -0,0 +1,103 @@
+---
+name: requesting-code-review
+description: Use when completing tasks, implementing major features, or before merging to verify work meets requirements
+---
+
+# Requesting Code Review
+
+Dispatch a code reviewer subagent to catch issues before they cascade. The reviewer gets precisely crafted context for evaluation — never your session's history. This keeps the reviewer focused on the work product, not your thought process, and preserves your own context for continued work.
+
+**Core principle:** Review early, review often.
+
+## When to Request Review
+
+**Mandatory:**
+- After each task in subagent-driven development
+- After completing major feature
+- Before merge to main
+
+**Optional but valuable:**
+- When stuck (fresh perspective)
+- Before refactoring (baseline check)
+- After fixing complex bug
+
+## How to Request
+
+**1. Get git SHAs:**
+```bash
+BASE_SHA=$(git rev-parse HEAD~1)  # or origin/main
+HEAD_SHA=$(git rev-parse HEAD)
+```
+
+**2. Dispatch code reviewer subagent:**
+
+Dispatch a `general-purpose` subagent, filling the template at [code-reviewer.md](code-reviewer.md)
+
+**Placeholders:**
+- `{DESCRIPTION}` - Brief summary of what you built
+- `{PLAN_OR_REQUIREMENTS}` - What it should do
+- `{BASE_SHA}` - Starting commit
+- `{HEAD_SHA}` - Ending commit
+
+**3. Act on feedback:**
+- Fix Critical issues immediately
+- Fix Important issues before proceeding
+- Note Minor issues for later
+- Push back if reviewer is wrong (with reasoning)
+
+## Example
+
+```
+[Just completed Task 2: Add verification function]
+
+You: Let me request code review before proceeding.
+
+BASE_SHA=$(git log --oneline | grep "Task 1" | head -1 | awk '{print $1}')
+HEAD_SHA=$(git rev-parse HEAD)
+
+[Dispatch code reviewer subagent]
+  DESCRIPTION: Added verifyIndex() and repairIndex() with 4 issue types
+  PLAN_OR_REQUIREMENTS: Task 2 from docs/superpowers/plans/deployment-plan.md
+  BASE_SHA: a7981ec
+  HEAD_SHA: 3df7661
+
+[Subagent returns]:
+  Strengths: Clean architecture, real tests
+  Issues:
+    Important: Missing progress indicators
+    Minor: Magic number (100) for reporting interval
+  Assessment: Ready to proceed
+
+You: [Fix progress indicators]
+[Continue to Task 3]
+```
+
+## Integration with Workflows
+
+**Subagent-Driven Development:**
+- Review after EACH task
+- Catch issues before they compound
+- Fix before moving to next task
+
+**Executing Plans:**
+- Review after each task or at natural checkpoints
+- Get feedback, apply, continue
+
+**Ad-Hoc Development:**
+- Review before merge
+- Review when stuck
+
+## Red Flags
+
+**Never:**
+- Skip review because "it's simple"
+- Ignore Critical issues
+- Proceed with unfixed Important issues
+- Argue with valid technical feedback
+
+**If reviewer wrong:**
+- Push back with technical reasoning
+- Show code/tests that prove it works
+- Request clarification
+
+See template at: [code-reviewer.md](code-reviewer.md)
diff --git a/.agents/skills/requesting-code-review/code-reviewer.md b/.agents/skills/requesting-code-review/code-reviewer.md
new file mode 100644
index 0000000..db84ae2
--- /dev/null
+++ b/.agents/skills/requesting-code-review/code-reviewer.md
@@ -0,0 +1,172 @@
+# Code Reviewer Prompt Template
+
+Use this template when dispatching a code reviewer subagent.
+
+**Purpose:** Review completed work against requirements and code quality standards before it cascades into more work.
+
+```
+Subagent (general-purpose):
+  description: "Review code changes"
+  prompt: |
+    You are a Senior Code Reviewer with expertise in software architecture,
+    design patterns, and best practices. Your job is to review completed work
+    against its plan or requirements and identify issues before they cascade.
+
+    ## What Was Implemented
+
+    [DESCRIPTION]
+
+    ## Requirements / Plan
+
+    [PLAN_OR_REQUIREMENTS]
+
+    ## Git Range to Review
+
+    **Base:** [BASE_SHA]
+    **Head:** [HEAD_SHA]
+
+    ```bash
+    git diff --stat [BASE_SHA]..[HEAD_SHA]
+    git diff [BASE_SHA]..[HEAD_SHA]
+    ```
+
+    ## Read-Only Review
+
+    Your review is read-only on this checkout. Do not mutate the working tree, the index, HEAD, or branch state in any way. Use tools like `git show`, `git diff`, and `git log` to inspect history. If you need a working copy of a different revision, check it out into a separate temporary directory (e.g. `git worktree add /tmp/review-[SHA] [SHA]`) — never move HEAD on this checkout.
+
+    ## What to Check
+
+    **Plan alignment:**
+    - Does the implementation match the plan / requirements?
+    - Are deviations justified improvements, or problematic departures?
+    - Is all planned functionality present?
+
+    **Code quality:**
+    - Clean separation of concerns?
+    - Proper error handling?
+    - Type safety where applicable?
+    - DRY without premature abstraction?
+    - Edge cases handled?
+
+    **Architecture:**
+    - Sound design decisions?
+    - Reasonable scalability and performance?
+    - Security concerns?
+    - Integrates cleanly with surrounding code?
+
+    **Testing:**
+    - Tests verify real behavior, not mocks?
+    - Edge cases covered?
+    - Integration tests where they matter?
+    - All tests passing?
+
+    **Production readiness:**
+    - Migration strategy if schema changed?
+    - Backward compatibility considered?
+    - Documentation complete?
+    - No obvious bugs?
+
+    ## Calibration
+
+    Categorize issues by actual severity. Not everything is Critical.
+    Acknowledge what was done well before listing issues — accurate praise
+    helps the implementer trust the rest of the feedback.
+
+    If you find significant deviations from the plan, flag them specifically
+    so the implementer can confirm whether the deviation was intentional.
+    If you find issues with the plan itself rather than the implementation,
+    say so.
+
+    ## Output Format
+
+    ### Strengths
+    [What's well done? Be specific.]
+
+    ### Issues
+
+    #### Critical (Must Fix)
+    [Bugs, security issues, data loss risks, broken functionality]
+
+    #### Important (Should Fix)
+    [Architecture problems, missing features, poor error handling, test gaps]
+
+    #### Minor (Nice to Have)
+    [Code style, optimization opportunities, documentation polish]
+
+    For each issue:
+    - File:line reference
+    - What's wrong
+    - Why it matters
+    - How to fix (if not obvious)
+
+    ### Recommendations
+    [Improvements for code quality, architecture, or process]
+
+    ### Assessment
+
+    **Ready to merge?** [Yes | No | With fixes]
+
+    **Reasoning:** [1-2 sentence technical assessment]
+
+    ## Critical Rules
+
+    **DO:**
+    - Categorize by actual severity
+    - Be specific (file:line, not vague)
+    - Explain WHY each issue matters
+    - Acknowledge strengths
+    - Give a clear verdict
+
+    **DON'T:**
+    - Say "looks good" without checking
+    - Mark nitpicks as Critical
+    - Give feedback on code you didn't actually read
+    - Be vague ("improve error handling")
+    - Avoid giving a clear verdict
+```
+
+**Placeholders:**
+- `[DESCRIPTION]` — brief summary of what was built
+- `[PLAN_OR_REQUIREMENTS]` — what it should do (plan file path, task text, or requirements)
+- `[BASE_SHA]` — starting commit
+- `[HEAD_SHA]` — ending commit
+
+**Reviewer returns:** Strengths, Issues (Critical / Important / Minor), Recommendations, Assessment
+
+## Example Output
+
+```
+### Strengths
+- Clean database schema with proper migrations (db.ts:15-42)
+- Comprehensive test coverage (18 tests, all edge cases)
+- Good error handling with fallbacks (summarizer.ts:85-92)
+
+### Issues
+
+#### Important
+1. **Missing help text in CLI wrapper**
+   - File: index-conversations:1-31
+   - Issue: No --help flag, users won't discover --concurrency
+   - Fix: Add --help case with usage examples
+
+2. **Date validation missing**
+   - File: search.ts:25-27
+   - Issue: Invalid dates silently return no results
+   - Fix: Validate ISO format, throw error with example
+
+#### Minor
+1. **Progress indicators**
+   - File: indexer.ts:130
+   - Issue: No "X of Y" counter for long operations
+   - Impact: Users don't know how long to wait
+
+### Recommendations
+- Add progress reporting for user experience
+- Consider config file for excluded projects (portability)
+
+### Assessment
+
+**Ready to merge: With fixes**
+
+**Reasoning:** Core implementation is solid with good architecture and tests. Important issues (help text, date validation) are easily fixed and don't affect core functionality.
+```
diff --git a/.agents/skills/subagent-driven-development/SKILL.md b/.agents/skills/subagent-driven-development/SKILL.md
new file mode 100644
index 0000000..d8ca081
--- /dev/null
+++ b/.agents/skills/subagent-driven-development/SKILL.md
@@ -0,0 +1,418 @@
+---
+name: subagent-driven-development
+description: Use when executing implementation plans with independent tasks in the current session
+---
+
+# Subagent-Driven Development
+
+Execute plan by dispatching a fresh implementer subagent per task, a task review (spec compliance + code quality) after each, and a broad whole-branch review at the end.
+
+**Why subagents:** You delegate tasks to specialized agents with isolated context. By precisely crafting their instructions and context, you ensure they stay focused and succeed at their task. They should never inherit your session's context or history — you construct exactly what they need. This also preserves your own context for coordination work.
+
+**Core principle:** Fresh subagent per task + task review (spec + quality) + broad final review = high quality, fast iteration
+
+**Narration:** between tool calls, narrate at most one short line — the
+ledger and the tool results carry the record.
+
+**Continuous execution:** Do not pause to check in with your human partner between tasks. Execute all tasks from the plan without stopping. The only reasons to stop are: BLOCKED status you cannot resolve, ambiguity that genuinely prevents progress, or all tasks complete. "Should I continue?" prompts and progress summaries waste their time — they asked you to execute the plan, so execute it.
+
+## When to Use
+
+```dot
+digraph when_to_use {
+    "Have implementation plan?" [shape=diamond];
+    "Tasks mostly independent?" [shape=diamond];
+    "Stay in this session?" [shape=diamond];
+    "subagent-driven-development" [shape=box];
+    "executing-plans" [shape=box];
+    "Manual execution or brainstorm first" [shape=box];
+
+    "Have implementation plan?" -> "Tasks mostly independent?" [label="yes"];
+    "Have implementation plan?" -> "Manual execution or brainstorm first" [label="no"];
+    "Tasks mostly independent?" -> "Stay in this session?" [label="yes"];
+    "Tasks mostly independent?" -> "Manual execution or brainstorm first" [label="no - tightly coupled"];
+    "Stay in this session?" -> "subagent-driven-development" [label="yes"];
+    "Stay in this session?" -> "executing-plans" [label="no - parallel session"];
+}
+```
+
+**vs. Executing Plans (parallel session):**
+- Same session (no context switch)
+- Fresh subagent per task (no context pollution)
+- Review after each task (spec compliance + code quality), broad review at the end
+- Faster iteration (no human-in-loop between tasks)
+
+## The Process
+
+```dot
+digraph process {
+    rankdir=TB;
+
+    subgraph cluster_per_task {
+        label="Per Task";
+        "Dispatch implementer subagent (./implementer-prompt.md)" [shape=box];
+        "Implementer subagent asks questions?" [shape=diamond];
+        "Answer questions, provide context" [shape=box];
+        "Implementer subagent implements, tests, commits, self-reviews" [shape=box];
+        "Write diff file, dispatch task reviewer subagent (./task-reviewer-prompt.md)" [shape=box];
+        "Task reviewer reports spec ✅ and quality approved?" [shape=diamond];
+        "Dispatch fix subagent for Critical/Important findings" [shape=box];
+        "Mark task complete in todo list and progress ledger" [shape=box];
+    }
+
+    "Read plan, note context and global constraints, create todos" [shape=box];
+    "More tasks remain?" [shape=diamond];
+    "Dispatch final code reviewer subagent (../requesting-code-review/code-reviewer.md)" [shape=box];
+    "Use superpowers:finishing-a-development-branch" [shape=box style=filled fillcolor=lightgreen];
+
+    "Read plan, note context and global constraints, create todos" -> "Dispatch implementer subagent (./implementer-prompt.md)";
+    "Dispatch implementer subagent (./implementer-prompt.md)" -> "Implementer subagent asks questions?";
+    "Implementer subagent asks questions?" -> "Answer questions, provide context" [label="yes"];
+    "Answer questions, provide context" -> "Dispatch implementer subagent (./implementer-prompt.md)";
+    "Implementer subagent asks questions?" -> "Implementer subagent implements, tests, commits, self-reviews" [label="no"];
+    "Implementer subagent implements, tests, commits, self-reviews" -> "Write diff file, dispatch task reviewer subagent (./task-reviewer-prompt.md)";
+    "Write diff file, dispatch task reviewer subagent (./task-reviewer-prompt.md)" -> "Task reviewer reports spec ✅ and quality approved?";
+    "Task reviewer reports spec ✅ and quality approved?" -> "Dispatch fix subagent for Critical/Important findings" [label="no"];
+    "Dispatch fix subagent for Critical/Important findings" -> "Write diff file, dispatch task reviewer subagent (./task-reviewer-prompt.md)" [label="re-review"];
+    "Task reviewer reports spec ✅ and quality approved?" -> "Mark task complete in todo list and progress ledger" [label="yes"];
+    "Mark task complete in todo list and progress ledger" -> "More tasks remain?";
+    "More tasks remain?" -> "Dispatch implementer subagent (./implementer-prompt.md)" [label="yes"];
+    "More tasks remain?" -> "Dispatch final code reviewer subagent (../requesting-code-review/code-reviewer.md)" [label="no"];
+    "Dispatch final code reviewer subagent (../requesting-code-review/code-reviewer.md)" -> "Use superpowers:finishing-a-development-branch";
+}
+```
+
+## Pre-Flight Plan Review
+
+Before dispatching Task 1, scan the plan once for conflicts:
+
+- tasks that contradict each other or the plan's Global Constraints
+- anything the plan explicitly mandates that the review rubric treats as a
+  defect (a test that asserts nothing, verbatim duplication of a logic block)
+
+Present everything you find to your human partner as one batched question —
+each finding beside the plan text that mandates it, asking which governs —
+before execution begins, not one interrupt per discovery mid-plan. If the
+scan is clean, proceed without comment. The review loop remains the net for
+conflicts that only emerge from implementation.
+
+## Model Selection
+
+Use the least powerful model that can handle each role to conserve cost and increase speed.
+
+**Mechanical implementation tasks** (isolated functions, clear specs, 1-2 files): use a fast, cheap model. Most implementation tasks are mechanical when the plan is well-specified.
+
+**Integration and judgment tasks** (multi-file coordination, pattern matching, debugging): use a standard model.
+
+**Architecture and design tasks**: use the most capable available model.
+The final whole-branch review is one of these — dispatch it on the most
+capable available model, not the session default.
+
+**Review tasks**: choose the model with the same judgment, scaled to the
+diff's size, complexity, and risk. A small mechanical diff does not need the
+most capable model; a subtle concurrency change does.
+
+**Always specify the model explicitly when dispatching a subagent.** An
+omitted model inherits your session's model — often the most capable and
+most expensive — which silently defeats this section.
+
+**Turn count beats token price.** Wall-clock and context cost scale with how
+many turns a subagent takes, and the cheapest models routinely take 2-3× the
+turns on multi-step work — costing more overall. Use a mid-tier model as the
+floor for reviewers and for implementers working from prose descriptions.
+When the task's plan text contains the complete code to write, the
+implementation is transcription plus testing: use the cheapest tier for
+that implementer. Single-file mechanical fixes also take the cheapest tier.
+
+**Task complexity signals (implementation tasks):**
+- Touches 1-2 files with a complete spec → cheap model
+- Touches multiple files with integration concerns → standard model
+- Requires design judgment or broad codebase understanding → most capable model
+
+## Handling Implementer Status
+
+Implementer subagents report one of four statuses. Handle each appropriately:
+
+**DONE:** Generate the review package (`scripts/review-package BASE HEAD`, from this skill's directory — it prints the unique file path it wrote; BASE is the commit you recorded before dispatching the implementer — never `HEAD~1`, which silently drops all but the last commit of a multi-commit task), then dispatch the task reviewer with the printed path.
+
+**DONE_WITH_CONCERNS:** The implementer completed the work but flagged doubts. Read the concerns before proceeding. If the concerns are about correctness or scope, address them before review. If they're observations (e.g., "this file is getting large"), note them and proceed to review.
+
+**NEEDS_CONTEXT:** The implementer needs information that wasn't provided. Provide the missing context and re-dispatch.
+
+**BLOCKED:** The implementer cannot complete the task. Assess the blocker:
+1. If it's a context problem, provide more context and re-dispatch with the same model
+2. If the task requires more reasoning, re-dispatch with a more capable model
+3. If the task is too large, break it into smaller pieces
+4. If the plan itself is wrong, escalate to the human
+
+**Never** ignore an escalation or force the same model to retry without changes. If the implementer said it's stuck, something needs to change.
+
+## Handling Reviewer ⚠️ Items
+
+The task reviewer may report "⚠️ Cannot verify from diff" items — requirements
+that live in unchanged code or span tasks. These do not block the rest of the
+review, but you must resolve each one yourself before marking the task
+complete: you hold the plan and cross-task context the reviewer
+lacks. If you confirm an item is a real gap, treat it as a failed spec
+review — send it back to the implementer and re-review.
+
+## Constructing Reviewer Prompts
+
+Per-task reviews are task-scoped gates. The broad review happens once, at the
+final whole-branch review. When you fill a reviewer template:
+
+- Do not add open-ended directives like "check all uses" or "run race tests
+  if useful" without a concrete, task-specific reason
+- Do not ask a reviewer to re-run tests the implementer already ran on the
+  same code — the implementer's report carries the test evidence
+- Do not pre-judge findings for the reviewer — never instruct a reviewer to
+  ignore or not flag a specific issue. If you believe a finding would be a
+  false positive, let the reviewer raise it and adjudicate it in the review
+  loop. If the prompt you are writing contains "do not flag," "don't treat X
+  as a defect," "at most Minor," or "the plan chose" — stop: you are
+  pre-judging, usually to spare yourself a review loop.
+- The global-constraints block you hand the reviewer is its attention
+  lens. Copy the binding requirements verbatim from the plan's Global
+  Constraints section or the spec: exact values, exact formats, and the
+  stated relationships between components ("same layout as X", "matches
+  Y"). The reviewer's template already carries the process rules (YAGNI,
+  test hygiene, review method) — the constraints block is for what THIS
+  project's spec demands.
+- Hand the reviewer its diff as a file: run this skill's
+  `scripts/review-package BASE HEAD` and pass the reviewer the file path
+  it prints (or, without bash: `git log --oneline`, `git diff --stat`,
+  and `git diff -U10` for the range, redirected to one uniquely named
+  file). The output never enters your own context, and the reviewer sees
+  the commit list, stat summary, and full diff with context in one Read
+  call. Use the BASE you recorded before dispatching the implementer —
+  never `HEAD~1`, which silently truncates multi-commit tasks.
+- A dispatch prompt describes one task, not the session's history. Do not
+  paste accumulated prior-task summaries ("state after Tasks 1-3") into
+  later dispatches — a real session's dispatch hit 42k chars of which 99%
+  was pasted history. A fresh subagent needs its task, the interfaces it
+  touches, and the global constraints. Nothing else.
+- Dispatch fix subagents for Critical and Important findings. Record Minor
+  findings in the progress ledger as you go, and point the final
+  whole-branch review at that list so it can triage which must be fixed
+  before merge. A roll-up nobody reads is a silent discard.
+- A finding labeled plan-mandated — or any finding that conflicts with
+  what the plan's text requires — is the human's decision, like any plan
+  contradiction: present the finding and the plan text, ask which governs.
+  Do not dismiss the finding because the plan mandates it, and do not
+  dispatch a fix that contradicts the plan without asking.
+- The final whole-branch review gets a package too: run
+  `scripts/review-package MERGE_BASE HEAD` (MERGE_BASE = the commit the
+  branch started from, e.g. `git merge-base main HEAD`) and include the
+  printed path in the final review dispatch, so the final reviewer reads
+  one file instead of re-deriving the branch diff with git commands.
+- Every fix dispatch carries the implementer contract: the fix subagent
+  re-runs the tests covering its change and reports the results. Name the
+  covering test files in the dispatch — a one-line fix does not need the
+  whole suite. Before re-dispatching the reviewer, confirm the fix report
+  contains the covering tests, the command run, and the output; dispatch
+  the re-review once all three are present.
+- If the final whole-branch review returns findings, dispatch ONE fix
+  subagent with the complete findings list — not one fixer per finding.
+  Per-finding fixers each rebuild context and re-run suites; a real
+  session's final-review fix wave cost more than all its tasks combined.
+
+## File Handoffs
+
+Everything you paste into a dispatch prompt — and everything a subagent
+prints back — stays resident in your context for the rest of the session
+and is re-read on every later turn. Hand artifacts over as files:
+
+- **Task brief:** before dispatching an implementer, run this skill's
+  `scripts/task-brief PLAN_FILE N` — it extracts the task's full text to a
+  uniquely named file and prints the path. Compose the dispatch so the
+  brief stays the single source of requirements. Your dispatch should
+  contain: (1) one line on where this task fits in the project; (2) the
+  brief path, introduced as "read this first — it is your requirements,
+  with the exact values to use verbatim"; (3) interfaces and decisions
+  from earlier tasks that the brief cannot know; (4) your resolution of
+  any ambiguity you noticed in the brief; (5) the report-file path and
+  report contract. Exact values (numbers, magic strings, signatures, test
+  cases) appear only in the brief.
+- **Report file:** name the implementer's report file after the brief
+  (brief `…/task-N-brief.md` → report `…/task-N-report.md`) and put it in
+  the dispatch prompt. The implementer writes the full report there and
+  returns only status, commits, a one-line test summary, and concerns.
+- **Reviewer inputs:** the task reviewer gets three paths — the same brief
+  file, the report file, and the review package — plus the global
+  constraints that bind the task.
+- Fix dispatches append their fix report (with test results) to the same
+  report file and return a short summary; re-reviews read the updated file.
+
+## Durable Progress
+
+Conversation memory does not survive compaction. In real sessions,
+controllers that lost their place have re-dispatched entire completed task
+sequences — the single most expensive failure observed. Track progress in
+a ledger file, not only in todos.
+
+- At skill start, check for a ledger:
+  `cat "$(git rev-parse --show-toplevel)/.superpowers/sdd/progress.md"`. Tasks listed there
+  as complete are DONE — do not re-dispatch them; resume at the first task
+  not marked complete.
+- When a task's review comes back clean, append one line to the ledger in
+  the same message as your other bookkeeping:
+  `Task N: complete (commits <base7>..<head7>, review clean)`.
+- The ledger is your recovery map: the commits it names exist in git even
+  when your context no longer remembers creating them. After compaction,
+  trust the ledger and `git log` over your own recollection.
+- `git clean -fdx` will destroy the ledger (it's git-ignored scratch); if
+  that happens, recover from `git log`.
+
+## Prompt Templates
+
+- [implementer-prompt.md](implementer-prompt.md) - Dispatch implementer subagent
+- [task-reviewer-prompt.md](task-reviewer-prompt.md) - Dispatch task reviewer subagent (spec compliance + code quality)
+- Final whole-branch review: use superpowers:requesting-code-review's [code-reviewer.md](../requesting-code-review/code-reviewer.md)
+
+## Example Workflow
+
+```
+You: I'm using Subagent-Driven Development to execute this plan.
+
+[Read plan file once: docs/superpowers/plans/feature-plan.md]
+[Create todos for all tasks]
+
+Task 1: Hook installation script
+
+[Run task-brief for Task 1; dispatch implementer with brief + report paths + context]
+
+Implementer: "Before I begin - should the hook be installed at user or system level?"
+
+You: "User level (~/.config/superpowers/hooks/)"
+
+Implementer: "Got it. Implementing now..."
+[Later] Implementer:
+  - Implemented install-hook command
+  - Added tests, 5/5 passing
+  - Self-review: Found I missed --force flag, added it
+  - Committed
+
+[Run review-package, dispatch task reviewer with the printed path]
+Task reviewer: Spec ✅ - all requirements met, nothing extra.
+  Strengths: Good test coverage, clean. Issues: None. Task quality: Approved.
+
+[Mark Task 1 complete]
+
+Task 2: Recovery modes
+
+[Run task-brief for Task 2; dispatch implementer with brief + report paths + context]
+
+Implementer: [No questions, proceeds]
+Implementer:
+  - Added verify/repair modes
+  - 8/8 tests passing
+  - Self-review: All good
+  - Committed
+
+[Run review-package, dispatch task reviewer with the printed path]
+Task reviewer: Spec ❌:
+  - Missing: Progress reporting (spec says "report every 100 items")
+  - Extra: Added --json flag (not requested)
+  Issues (Important): Magic number (100)
+
+[Dispatch fix subagent with all findings]
+Fixer: Removed --json flag, added progress reporting, extracted PROGRESS_INTERVAL constant
+
+[Task reviewer reviews again]
+Task reviewer: Spec ✅. Task quality: Approved.
+
+[Mark Task 2 complete]
+
+...
+
+[After all tasks]
+[Dispatch final code-reviewer]
+Final reviewer: All requirements met, ready to merge
+
+Done!
+```
+
+## Advantages
+
+**vs. Manual execution:**
+- Subagents follow TDD naturally
+- Fresh context per task (no confusion)
+- Parallel-safe (subagents don't interfere)
+- Subagent can ask questions (before AND during work)
+
+**vs. Executing Plans:**
+- Same session (no handoff)
+- Continuous progress (no waiting)
+- Review checkpoints automatic
+
+**Efficiency gains:**
+- Controller curates exactly what context is needed; bulk artifacts move
+  as files, not pasted text
+- Subagent gets complete information upfront
+- Questions surfaced before work begins (not after)
+
+**Quality gates:**
+- Self-review catches issues before handoff
+- Task review carries two verdicts: spec compliance and code quality
+- Review loops ensure fixes actually work
+- Spec compliance prevents over/under-building
+- Code quality ensures implementation is well-built
+
+**Cost:**
+- More subagent invocations (implementer + reviewer per task)
+- Controller does more prep work (extracting all tasks upfront)
+- Review loops add iterations
+- But catches issues early (cheaper than debugging later)
+
+## Red Flags
+
+**Never:**
+- Start implementation on main/master branch without explicit user consent
+- Skip task review, or accept a report missing either verdict (spec compliance AND task quality are both required)
+- Proceed with unfixed issues
+- Dispatch multiple implementation subagents in parallel (conflicts)
+- Make a subagent read the whole plan file (hand it its task brief —
+  `scripts/task-brief` — instead)
+- Skip scene-setting context (subagent needs to understand where task fits)
+- Ignore subagent questions (answer before letting them proceed)
+- Accept "close enough" on spec compliance (reviewer found spec issues = not done)
+- Skip review loops (reviewer found issues = implementer fixes = review again)
+- Let implementer self-review replace actual review (both are needed)
+- Tell a reviewer what not to flag, or pre-rate a finding's severity in the
+  dispatch prompt ("treat it as Minor at most") — the plan's example code is
+  a starting point, not evidence that its weaknesses were chosen
+- Dispatch a task reviewer without a diff file — generate it first
+  (`scripts/review-package BASE HEAD`) and name the printed path in the
+  prompt
+- Move to next task while the review has open Critical/Important issues
+- Re-dispatch a task the progress ledger already marks complete — check
+  the ledger (and `git log`) after any compaction or resume
+
+**If subagent asks questions:**
+- Answer clearly and completely
+- Provide additional context if needed
+- Don't rush them into implementation
+
+**If reviewer finds issues:**
+- Implementer (same subagent) fixes them
+- Reviewer reviews again
+- Repeat until approved
+- Don't skip the re-review
+
+**If subagent fails task:**
+- Dispatch fix subagent with specific instructions
+- Don't try to fix manually (context pollution)
+
+## Integration
+
+**Required workflow skills:**
+- **superpowers:using-git-worktrees** - Ensures isolated workspace (creates one or verifies existing)
+- **superpowers:writing-plans** - Creates the plan this skill executes
+- **superpowers:requesting-code-review** - Code review template for the final whole-branch review
+- **superpowers:finishing-a-development-branch** - Complete development after all tasks
+
+**Subagents should use:**
+- **superpowers:test-driven-development** - Subagents follow TDD for each task
+
+**Alternative workflow:**
+- **superpowers:executing-plans** - Use for parallel session instead of same-session execution
diff --git a/.agents/skills/subagent-driven-development/implementer-prompt.md b/.agents/skills/subagent-driven-development/implementer-prompt.md
new file mode 100644
index 0000000..218fcfe
--- /dev/null
+++ b/.agents/skills/subagent-driven-development/implementer-prompt.md
@@ -0,0 +1,139 @@
+# Implementer Subagent Prompt Template
+
+Use this template when dispatching an implementer subagent.
+
+```
+Subagent (general-purpose):
+  description: "Implement Task N: [task name]"
+  model: [MODEL — REQUIRED: choose per SKILL.md Model Selection; an omitted
+         model silently inherits the session's most expensive one]
+  prompt: |
+    You are implementing Task N: [task name]
+
+    ## Task Description
+
+    Read your task brief first: [BRIEF_FILE]
+    It contains the full task text from the plan.
+
+    ## Context
+
+    [Scene-setting: where this fits, dependencies, architectural context]
+
+    ## Before You Begin
+
+    If you have questions about:
+    - The requirements or acceptance criteria
+    - The approach or implementation strategy
+    - Dependencies or assumptions
+    - Anything unclear in the task description
+
+    **Ask them now.** Raise any concerns before starting work.
+
+    ## Your Job
+
+    Once you're clear on requirements:
+    1. Implement exactly what the task specifies
+    2. Write tests (following TDD if task says to)
+    3. Verify implementation works
+    4. Commit your work
+    5. Self-review (see below)
+    6. Report back
+
+    Work from: [directory]
+
+    **While you work:** If you encounter something unexpected or unclear, **ask questions**.
+    It's always OK to pause and clarify. Don't guess or make assumptions.
+
+    While iterating, run the focused test for what you're changing; run the
+    full suite once before committing, not after every edit.
+
+    ## Code Organization
+
+    You reason best about code you can hold in context at once, and your edits are more
+    reliable when files are focused. Keep this in mind:
+    - Follow the file structure defined in the plan
+    - Each file should have one clear responsibility with a well-defined interface
+    - If a file you're creating is growing beyond the plan's intent, stop and report
+      it as DONE_WITH_CONCERNS — don't split files on your own without plan guidance
+    - If an existing file you're modifying is already large or tangled, work carefully
+      and note it as a concern in your report
+    - In existing codebases, follow established patterns. Improve code you're touching
+      the way a good developer would, but don't restructure things outside your task.
+
+    ## When You're in Over Your Head
+
+    It is always OK to stop and say "this is too hard for me." Bad work is worse than
+    no work. You will not be penalized for escalating.
+
+    **STOP and escalate when:**
+    - The task requires architectural decisions with multiple valid approaches
+    - You need to understand code beyond what was provided and can't find clarity
+    - You feel uncertain about whether your approach is correct
+    - The task involves restructuring existing code in ways the plan didn't anticipate
+    - You've been reading file after file trying to understand the system without progress
+
+    **How to escalate:** Report back with status BLOCKED or NEEDS_CONTEXT. Describe
+    specifically what you're stuck on, what you've tried, and what kind of help you need.
+    The controller can provide more context, re-dispatch with a more capable model,
+    or break the task into smaller pieces.
+
+    ## Before Reporting Back: Self-Review
+
+    Review your work with fresh eyes. Ask yourself:
+
+    **Completeness:**
+    - Did I fully implement everything in the spec?
+    - Did I miss any requirements?
+    - Are there edge cases I didn't handle?
+
+    **Quality:**
+    - Is this my best work?
+    - Are names clear and accurate (match what things do, not how they work)?
+    - Is the code clean and maintainable?
+
+    **Discipline:**
+    - Did I avoid overbuilding (YAGNI)?
+    - Did I only build what was requested?
+    - Did I follow existing patterns in the codebase?
+
+    **Testing:**
+    - Do tests actually verify behavior (not just mock behavior)?
+    - Did I follow TDD if required?
+    - Are tests comprehensive?
+    - Is the test output pristine (no stray warnings or noise)?
+
+    If you find issues during self-review, fix them now before reporting.
+
+    ## After Review Findings
+
+    If a reviewer finds issues and you fix them, re-run the tests that cover
+    the amended code and append the results to your report file. Reviewers
+    will not re-run tests for you — your report is the test evidence.
+
+    ## Report Format
+
+    Write your full report to [REPORT_FILE]:
+    - What you implemented (or what you attempted, if blocked)
+    - What you tested and test results
+    - **TDD Evidence** (if TDD was required for this task):
+      - RED: command run, relevant failing output before implementation, and why the failure was expected
+      - GREEN: command run and relevant passing output after implementation
+    - Files changed
+    - Self-review findings (if any)
+    - Any issues or concerns
+
+    Then report back with ONLY (under 15 lines — the detail lives in the
+    report file):
+    - **Status:** DONE | DONE_WITH_CONCERNS | BLOCKED | NEEDS_CONTEXT
+    - Commits created (short SHA + subject)
+    - One-line test summary (e.g. "14/14 passing, output pristine")
+    - Your concerns, if any
+    - The report file path
+
+    If BLOCKED or NEEDS_CONTEXT, put the specifics in the final message
+    itself — the controller acts on it directly.
+
+    Use DONE_WITH_CONCERNS if you completed the work but have doubts about correctness.
+    Use BLOCKED if you cannot complete the task. Use NEEDS_CONTEXT if you need
+    information that wasn't provided. Never silently produce work you're unsure about.
+```
diff --git a/.agents/skills/subagent-driven-development/scripts/review-package b/.agents/skills/subagent-driven-development/scripts/review-package
new file mode 100755
index 0000000..33bb20f
--- /dev/null
+++ b/.agents/skills/subagent-driven-development/scripts/review-package
@@ -0,0 +1,44 @@
+#!/usr/bin/env bash
+# Generate a review package: commit list, stat summary, and the net
+# diff with extended context, written to a file the reviewer reads in one
+# call. Using the recorded per-task BASE (not HEAD~1) keeps multi-commit
+# tasks intact.
+#
+# Usage: review-package BASE HEAD [OUTFILE]
+# Default OUTFILE: <repo-root>/.superpowers/sdd/review-<base7>..<head7>.diff
+# (named per range, so a re-review after fixes gets a distinct fresh file).
+set -euo pipefail
+
+if [ $# -lt 2 ] || [ $# -gt 3 ]; then
+  echo "usage: review-package BASE HEAD [OUTFILE]" >&2
+  exit 2
+fi
+
+base=$1
+head=$2
+
+git rev-parse --verify --quiet "$base" >/dev/null || { echo "bad BASE: $base" >&2; exit 2; }
+git rev-parse --verify --quiet "$head" >/dev/null || { echo "bad HEAD: $head" >&2; exit 2; }
+
+if [ $# -eq 3 ]; then
+  out=$3
+else
+  dir=$("$(cd "$(dirname "$0")" && pwd)/sdd-workspace")
+  out="$dir/review-$(git rev-parse --short "$base")..$(git rev-parse --short "$head").diff"
+fi
+
+{
+  echo "# Review package: ${base}..${head}"
+  echo
+  echo "## Commits"
+  git log --oneline "${base}..${head}"
+  echo
+  echo "## Files changed"
+  git diff --stat "${base}..${head}"
+  echo
+  echo "## Diff"
+  git diff -U10 "${base}..${head}"
+} > "$out"
+
+commits=$(git rev-list --count "${base}..${head}")
+echo "wrote ${out}: ${commits} commit(s), $(wc -c < "$out" | tr -d ' ') bytes"
diff --git a/.agents/skills/subagent-driven-development/scripts/sdd-workspace b/.agents/skills/subagent-driven-development/scripts/sdd-workspace
new file mode 100755
index 0000000..ea9bb08
--- /dev/null
+++ b/.agents/skills/subagent-driven-development/scripts/sdd-workspace
@@ -0,0 +1,22 @@
+#!/usr/bin/env bash
+# Resolve and ensure the working-tree directory SDD uses for its short-lived
+# artifacts: task briefs, implementer reports, review packages, and the
+# progress ledger. Print the directory's absolute path.
+#
+# The workspace lives in the working tree (not under .git/) because Claude Code
+# treats .git/ as a protected path and denies agent writes there — which blocks
+# an implementer subagent from writing its report file. A self-ignoring
+# .gitignore keeps the workspace out of `git status` and out of accidental
+# commits without modifying any tracked file.
+#
+# Single source of truth for the workspace location, so task-brief and
+# review-package cannot drift to different directories.
+#
+# Usage: sdd-workspace
+set -euo pipefail
+
+root=$(git rev-parse --show-toplevel)
+dir="$root/.superpowers/sdd"
+mkdir -p "$dir"
+printf '*\n' > "$dir/.gitignore"
+cd "$dir" && pwd
diff --git a/.agents/skills/subagent-driven-development/scripts/task-brief b/.agents/skills/subagent-driven-development/scripts/task-brief
new file mode 100755
index 0000000..247a767
--- /dev/null
+++ b/.agents/skills/subagent-driven-development/scripts/task-brief
@@ -0,0 +1,40 @@
+#!/usr/bin/env bash
+# Extract one task's full text from an implementation plan into a file the
+# implementer reads in one call, so the task text never has to be pasted
+# through the controller's context.
+#
+# Usage: task-brief PLAN_FILE TASK_NUMBER [OUTFILE]
+# Default OUTFILE: <repo-root>/.superpowers/sdd/task-<N>-brief.md
+# (per worktree; concurrent runs in the same working tree share it).
+set -euo pipefail
+
+if [ $# -lt 2 ] || [ $# -gt 3 ]; then
+  echo "usage: task-brief PLAN_FILE TASK_NUMBER [OUTFILE]" >&2
+  exit 2
+fi
+
+plan=$1
+n=$2
+[ -f "$plan" ] || { echo "no such plan file: $plan" >&2; exit 2; }
+
+if [ $# -eq 3 ]; then
+  out=$3
+else
+  dir=$("$(cd "$(dirname "$0")" && pwd)/sdd-workspace")
+  out="$dir/task-${n}-brief.md"
+fi
+
+awk -v n="$n" '
+  /^```/ { infence = !infence }
+  !infence && /^#+[ \t]+Task[ \t]+[0-9]+/ {
+    intask = ($0 ~ ("^#+[ \t]+Task[ \t]+" n "([^0-9]|$)"))
+  }
+  intask { print }
+' "$plan" > "$out"
+
+if [ ! -s "$out" ]; then
+  echo "task ${n} not found in ${plan} (no heading matching 'Task ${n}')" >&2
+  exit 3
+fi
+
+echo "wrote ${out}: $(wc -l < "$out" | tr -d ' ') lines"
diff --git a/.agents/skills/subagent-driven-development/task-reviewer-prompt.md b/.agents/skills/subagent-driven-development/task-reviewer-prompt.md
new file mode 100644
index 0000000..588a402
--- /dev/null
+++ b/.agents/skills/subagent-driven-development/task-reviewer-prompt.md
@@ -0,0 +1,188 @@
+# Task Reviewer Prompt Template
+
+Use this template when dispatching a task reviewer subagent. The reviewer
+reads the task's diff once and returns two verdicts: spec compliance and
+code quality.
+
+**Purpose:** Verify one task's implementation matches its requirements (nothing
+more, nothing less) and is well-built (clean, tested, maintainable)
+
+```
+Subagent (general-purpose):
+  description: "Review Task N (spec + quality)"
+  model: [MODEL — REQUIRED: choose per SKILL.md Model Selection; an omitted
+         model silently inherits the session's most expensive one]
+  prompt: |
+    You are reviewing one task's implementation: first whether it matches its
+    requirements, then whether it is well-built. This is a task-scoped gate,
+    not a merge review — a broad whole-branch review happens separately after
+    all tasks are complete.
+
+    ## What Was Requested
+
+    Read the task brief: [BRIEF_FILE]
+
+    Global constraints from the spec/design that bind this task:
+    [GLOBAL_CONSTRAINTS]
+
+    ## What the Implementer Claims They Built
+
+    Read the implementer's report: [REPORT_FILE]
+
+    ## Diff Under Review
+
+    **Base:** [BASE_SHA]
+    **Head:** [HEAD_SHA]
+    **Diff file:** [DIFF_FILE]
+
+    Read the diff file once — it contains the commit list, a stat summary,
+    and the full diff with surrounding context, and it is your view of the
+    change. The diff's context lines ARE the changed files: do not Read a
+    changed file separately unless a hunk you must judge is cut off
+    mid-function — and say so in your report. Do not re-run git commands.
+    If the diff file is missing, fetch the diff yourself:
+    `git diff --stat [BASE_SHA]..[HEAD_SHA]` and `git diff [BASE_SHA]..[HEAD_SHA]`.
+    Do not crawl the broader codebase. Inspect code outside the diff only
+    to evaluate a concrete risk you can name — one focused check per named
+    risk, and name both the risk and what you checked in your report.
+    Cross-cutting changes are legitimate named risks: if the diff changes
+    lock ordering, a function or API contract, or shared mutable state,
+    checking the call sites is the right method.
+
+    Your review is read-only on this checkout. Do not mutate the working
+    tree, the index, HEAD, or branch state in any way.
+
+    ## Do Not Trust the Report
+
+    Treat the implementer's report as unverified claims about the code. It
+    may be incomplete, inaccurate, or optimistic. Verify the claims against
+    the diff. Design rationales in the report are claims too: "left it per
+    YAGNI," "kept it simple deliberately," or any other justification is the
+    implementer grading their own work. Judge the code on its merits — a
+    stated rationale never downgrades a finding's severity.
+
+    ## Tests
+
+    The implementer already ran the tests and reported results with TDD
+    evidence for exactly this code. Do not re-run the suite to confirm their
+    report. Run a test only when reading the code raises a specific doubt
+    that no existing run answers — and then a focused test, never a
+    package-wide suite, race detector run, or repeated/high-count loop. If
+    heavy validation seems warranted, recommend it in your report instead of
+    running it. If you cannot run commands in this environment, name the
+    test you would run.
+
+    Warnings or other noise in the implementer's reported test output are
+    findings — test output should be pristine.
+
+    ## Part 1: Spec Compliance
+
+    Compare the diff against What Was Requested:
+
+    - **Missing:** requirements they skipped, missed, or claimed without
+      implementing
+    - **Extra:** features that weren't requested, over-engineering, unneeded
+      "nice to haves"
+    - **Misunderstood:** right feature built the wrong way, wrong problem
+      solved
+
+    If a requirement cannot be verified from this diff alone (it lives in
+    unchanged code or spans tasks), report it as a ⚠️ item instead of
+    broadening your search.
+
+    ## Part 2: Code Quality
+
+    **Code quality:**
+    - Clean separation of concerns?
+    - Proper error handling?
+    - DRY without premature abstraction?
+    - Edge cases handled?
+
+    **Tests:**
+    - Do the new and changed tests verify real behavior, not mocks?
+    - Are the task's edge cases covered?
+
+    **Structure:**
+    - Does each file have one clear responsibility with a well-defined interface?
+    - Are units decomposed so they can be understood and tested independently?
+    - Is the implementation following the file structure from the plan?
+    - Did this change create new files that are already large, or
+      significantly grow existing files? (Don't flag pre-existing file
+      sizes — focus on what this change contributed.)
+
+    Your report should point at evidence: file:line references for every
+    finding and for any check you would otherwise answer with a bare
+    "yes." A tight report that cites lines gives the controller everything
+    it needs.
+
+    Your final message is the report itself: begin directly with the
+    spec-compliance verdict. Every line is a verdict, a finding with
+    file:line, or a check you ran — no preamble, no process narration,
+    no closing summary.
+
+    ## Calibration
+
+    Categorize issues by actual severity. Not everything is Critical.
+    Important means this task cannot be trusted until it is fixed: incorrect
+    or fragile behavior, a missed requirement, or maintainability damage you
+    would block a merge over — verbatim duplication of a logic block,
+    swallowed errors, tests that assert nothing. "Coverage could be broader"
+    and polish suggestions are Minor.
+    If the plan or brief explicitly mandates something this rubric calls a
+    defect (a test that asserts nothing, verbatim duplication of a logic
+    block), that IS a finding — report it as Important, labeled
+    plan-mandated. The plan's authorship does not grade its own work; the
+    human decides.
+    Acknowledge what was done well before listing issues — accurate praise
+    helps the implementer trust the rest of the feedback.
+
+    ## Output Format
+
+    ### Spec Compliance
+
+    - ✅ Spec compliant | ❌ Issues found: [what's missing/extra/misunderstood,
+      with file:line references]
+    - ⚠️ Cannot verify from diff: [requirements you could not verify from the
+      diff alone, and what the controller should check — report alongside the
+      ✅/❌ verdict for everything you could verify]
+
+    ### Strengths
+    [What's well done? Be specific.]
+
+    ### Issues
+
+    #### Critical (Must Fix)
+    #### Important (Should Fix)
+    #### Minor (Nice to Have)
+
+    For each issue: file:line, what's wrong, why it matters, how to fix
+    (if not obvious).
+
+    ### Assessment
+
+    **Task quality:** [Approved | Needs fixes]
+
+    **Reasoning:** [1-2 sentence technical assessment]
+```
+
+**Placeholders:**
+- `[MODEL]` — REQUIRED: reviewer model per SKILL.md Model Selection
+- `[BRIEF_FILE]` — REQUIRED: the task brief file (`scripts/task-brief PLAN N`
+  prints the path; same file the implementer worked from)
+- `[GLOBAL_CONSTRAINTS]` — the binding requirements copied verbatim from
+  the plan's Global Constraints section or the spec: exact values, formats,
+  and stated relationships between components (not process rules — those
+  are already in this template)
+- `[REPORT_FILE]` — REQUIRED: the file the implementer wrote its detailed
+  report to
+- `[BASE_SHA]` — commit before this task
+- `[HEAD_SHA]` — current commit
+- `[DIFF_FILE]` — REQUIRED: the path the controller wrote the review
+  package to (`scripts/review-package BASE HEAD` prints the unique path it
+  wrote; the package never enters the controller's context)
+
+**Reviewer returns:** Spec Compliance verdict (✅/❌/⚠️), Strengths, Issues
+(Critical/Important/Minor), Task quality verdict
+
+A fix dispatch can address spec gaps and quality findings together;
+re-review after fixes covers both verdicts.
diff --git a/.agents/skills/systematic-debugging/CREATION-LOG.md b/.agents/skills/systematic-debugging/CREATION-LOG.md
new file mode 100644
index 0000000..9aa0309
--- /dev/null
+++ b/.agents/skills/systematic-debugging/CREATION-LOG.md
@@ -0,0 +1,119 @@
+# Creation Log: Systematic Debugging Skill
+
+Reference example of extracting, structuring, and bulletproofing a critical skill.
+
+## Source Material
+
+Extracted debugging framework from `~/.claude/CLAUDE.md`:
+- 4-phase systematic process (Investigation → Pattern Analysis → Hypothesis → Implementation)
+- Core mandate: ALWAYS find root cause, NEVER fix symptoms
+- Rules designed to resist time pressure and rationalization
+
+## Extraction Decisions
+
+**What to include:**
+- Complete 4-phase framework with all rules
+- Anti-shortcuts ("NEVER fix symptom", "STOP and re-analyze")
+- Pressure-resistant language ("even if faster", "even if I seem in a hurry")
+- Concrete steps for each phase
+
+**What to leave out:**
+- Project-specific context
+- Repetitive variations of same rule
+- Narrative explanations (condensed to principles)
+
+## Structure Following skill-creation/SKILL.md
+
+1. **Rich when_to_use** - Included symptoms and anti-patterns
+2. **Type: technique** - Concrete process with steps
+3. **Keywords** - "root cause", "symptom", "workaround", "debugging", "investigation"
+4. **Flowchart** - Decision point for "fix failed" → re-analyze vs add more fixes
+5. **Phase-by-phase breakdown** - Scannable checklist format
+6. **Anti-patterns section** - What NOT to do (critical for this skill)
+
+## Bulletproofing Elements
+
+Framework designed to resist rationalization under pressure:
+
+### Language Choices
+- "ALWAYS" / "NEVER" (not "should" / "try to")
+- "even if faster" / "even if I seem in a hurry"
+- "STOP and re-analyze" (explicit pause)
+- "Don't skip past" (catches the actual behavior)
+
+### Structural Defenses
+- **Phase 1 required** - Can't skip to implementation
+- **Single hypothesis rule** - Forces thinking, prevents shotgun fixes
+- **Explicit failure mode** - "IF your first fix doesn't work" with mandatory action
+- **Anti-patterns section** - Shows exactly what shortcuts look like
+
+### Redundancy
+- Root cause mandate in overview + when_to_use + Phase 1 + implementation rules
+- "NEVER fix symptom" appears 4 times in different contexts
+- Each phase has explicit "don't skip" guidance
+
+## Testing Approach
+
+Created 4 validation tests following skills/meta/testing-skills-with-subagents:
+
+### Test 1: Academic Context (No Pressure)
+- Simple bug, no time pressure
+- **Result:** Perfect compliance, complete investigation
+
+### Test 2: Time Pressure + Obvious Quick Fix
+- User "in a hurry", symptom fix looks easy
+- **Result:** Resisted shortcut, followed full process, found real root cause
+
+### Test 3: Complex System + Uncertainty
+- Multi-layer failure, unclear if can find root cause
+- **Result:** Systematic investigation, traced through all layers, found source
+
+### Test 4: Failed First Fix
+- Hypothesis doesn't work, temptation to add more fixes
+- **Result:** Stopped, re-analyzed, formed new hypothesis (no shotgun)
+
+**All tests passed.** No rationalizations found.
+
+## Iterations
+
+### Initial Version
+- Complete 4-phase framework
+- Anti-patterns section
+- Flowchart for "fix failed" decision
+
+### Enhancement 1: TDD Reference
+- Added link to skills/testing/test-driven-development
+- Note explaining TDD's "simplest code" ≠ debugging's "root cause"
+- Prevents confusion between methodologies
+
+## Final Outcome
+
+Bulletproof skill that:
+- ✅ Clearly mandates root cause investigation
+- ✅ Resists time pressure rationalization
+- ✅ Provides concrete steps for each phase
+- ✅ Shows anti-patterns explicitly
+- ✅ Tested under multiple pressure scenarios
+- ✅ Clarifies relationship to TDD
+- ✅ Ready for use
+
+## Key Insight
+
+**Most important bulletproofing:** Anti-patterns section showing exact shortcuts that feel justified in the moment. When Claude thinks "I'll just add this one quick fix", seeing that exact pattern listed as wrong creates cognitive friction.
+
+## Usage Example
+
+When encountering a bug:
+1. Load skill: skills/debugging/systematic-debugging
+2. Read overview (10 sec) - reminded of mandate
+3. Follow Phase 1 checklist - forced investigation
+4. If tempted to skip - see anti-pattern, stop
+5. Complete all phases - root cause found
+
+**Time investment:** 5-10 minutes
+**Time saved:** Hours of symptom-whack-a-mole
+
+---
+
+*Created: 2025-10-03*
+*Purpose: Reference example for skill extraction and bulletproofing*
diff --git a/.agents/skills/systematic-debugging/SKILL.md b/.agents/skills/systematic-debugging/SKILL.md
new file mode 100644
index 0000000..b0eca38
--- /dev/null
+++ b/.agents/skills/systematic-debugging/SKILL.md
@@ -0,0 +1,296 @@
+---
+name: systematic-debugging
+description: Use when encountering any bug, test failure, or unexpected behavior, before proposing fixes
+---
+
+# Systematic Debugging
+
+## Overview
+
+Random fixes waste time and create new bugs. Quick patches mask underlying issues.
+
+**Core principle:** ALWAYS find root cause before attempting fixes. Symptom fixes are failure.
+
+**Violating the letter of this process is violating the spirit of debugging.**
+
+## The Iron Law
+
+```
+NO FIXES WITHOUT ROOT CAUSE INVESTIGATION FIRST
+```
+
+If you haven't completed Phase 1, you cannot propose fixes.
+
+## When to Use
+
+Use for ANY technical issue:
+- Test failures
+- Bugs in production
+- Unexpected behavior
+- Performance problems
+- Build failures
+- Integration issues
+
+**Use this ESPECIALLY when:**
+- Under time pressure (emergencies make guessing tempting)
+- "Just one quick fix" seems obvious
+- You've already tried multiple fixes
+- Previous fix didn't work
+- You don't fully understand the issue
+
+**Don't skip when:**
+- Issue seems simple (simple bugs have root causes too)
+- You're in a hurry (rushing guarantees rework)
+- Manager wants it fixed NOW (systematic is faster than thrashing)
+
+## The Four Phases
+
+You MUST complete each phase before proceeding to the next.
+
+### Phase 1: Root Cause Investigation
+
+**BEFORE attempting ANY fix:**
+
+1. **Read Error Messages Carefully**
+   - Don't skip past errors or warnings
+   - They often contain the exact solution
+   - Read stack traces completely
+   - Note line numbers, file paths, error codes
+
+2. **Reproduce Consistently**
+   - Can you trigger it reliably?
+   - What are the exact steps?
+   - Does it happen every time?
+   - If not reproducible → gather more data, don't guess
+
+3. **Check Recent Changes**
+   - What changed that could cause this?
+   - Git diff, recent commits
+   - New dependencies, config changes
+   - Environmental differences
+
+4. **Gather Evidence in Multi-Component Systems**
+
+   **WHEN system has multiple components (CI → build → signing, API → service → database):**
+
+   **BEFORE proposing fixes, add diagnostic instrumentation:**
+   ```
+   For EACH component boundary:
+     - Log what data enters component
+     - Log what data exits component
+     - Verify environment/config propagation
+     - Check state at each layer
+
+   Run once to gather evidence showing WHERE it breaks
+   THEN analyze evidence to identify failing component
+   THEN investigate that specific component
+   ```
+
+   **Example (multi-layer system):**
+   ```bash
+   # Layer 1: Workflow
+   echo "=== Secrets available in workflow: ==="
+   echo "IDENTITY: ${IDENTITY:+SET}${IDENTITY:-UNSET}"
+
+   # Layer 2: Build script
+   echo "=== Env vars in build script: ==="
+   env | grep IDENTITY || echo "IDENTITY not in environment"
+
+   # Layer 3: Signing script
+   echo "=== Keychain state: ==="
+   security list-keychains
+   security find-identity -v
+
+   # Layer 4: Actual signing
+   codesign --sign "$IDENTITY" --verbose=4 "$APP"
+   ```
+
+   **This reveals:** Which layer fails (secrets → workflow ✓, workflow → build ✗)
+
+5. **Trace Data Flow**
+
+   **WHEN error is deep in call stack:**
+
+   See `root-cause-tracing.md` in this directory for the complete backward tracing technique.
+
+   **Quick version:**
+   - Where does bad value originate?
+   - What called this with bad value?
+   - Keep tracing up until you find the source
+   - Fix at source, not at symptom
+
+### Phase 2: Pattern Analysis
+
+**Find the pattern before fixing:**
+
+1. **Find Working Examples**
+   - Locate similar working code in same codebase
+   - What works that's similar to what's broken?
+
+2. **Compare Against References**
+   - If implementing pattern, read reference implementation COMPLETELY
+   - Don't skim - read every line
+   - Understand the pattern fully before applying
+
+3. **Identify Differences**
+   - What's different between working and broken?
+   - List every difference, however small
+   - Don't assume "that can't matter"
+
+4. **Understand Dependencies**
+   - What other components does this need?
+   - What settings, config, environment?
+   - What assumptions does it make?
+
+### Phase 3: Hypothesis and Testing
+
+**Scientific method:**
+
+1. **Form Single Hypothesis**
+   - State clearly: "I think X is the root cause because Y"
+   - Write it down
+   - Be specific, not vague
+
+2. **Test Minimally**
+   - Make the SMALLEST possible change to test hypothesis
+   - One variable at a time
+   - Don't fix multiple things at once
+
+3. **Verify Before Continuing**
+   - Did it work? Yes → Phase 4
+   - Didn't work? Form NEW hypothesis
+   - DON'T add more fixes on top
+
+4. **When You Don't Know**
+   - Say "I don't understand X"
+   - Don't pretend to know
+   - Ask for help
+   - Research more
+
+### Phase 4: Implementation
+
+**Fix the root cause, not the symptom:**
+
+1. **Create Failing Test Case**
+   - Simplest possible reproduction
+   - Automated test if possible
+   - One-off test script if no framework
+   - MUST have before fixing
+   - Use the `superpowers:test-driven-development` skill for writing proper failing tests
+
+2. **Implement Single Fix**
+   - Address the root cause identified
+   - ONE change at a time
+   - No "while I'm here" improvements
+   - No bundled refactoring
+
+3. **Verify Fix**
+   - Test passes now?
+   - No other tests broken?
+   - Issue actually resolved?
+
+4. **If Fix Doesn't Work**
+   - STOP
+   - Count: How many fixes have you tried?
+   - If < 3: Return to Phase 1, re-analyze with new information
+   - **If ≥ 3: STOP and question the architecture (step 5 below)**
+   - DON'T attempt Fix #4 without architectural discussion
+
+5. **If 3+ Fixes Failed: Question Architecture**
+
+   **Pattern indicating architectural problem:**
+   - Each fix reveals new shared state/coupling/problem in different place
+   - Fixes require "massive refactoring" to implement
+   - Each fix creates new symptoms elsewhere
+
+   **STOP and question fundamentals:**
+   - Is this pattern fundamentally sound?
+   - Are we "sticking with it through sheer inertia"?
+   - Should we refactor architecture vs. continue fixing symptoms?
+
+   **Discuss with your human partner before attempting more fixes**
+
+   This is NOT a failed hypothesis - this is a wrong architecture.
+
+## Red Flags - STOP and Follow Process
+
+If you catch yourself thinking:
+- "Quick fix for now, investigate later"
+- "Just try changing X and see if it works"
+- "Add multiple changes, run tests"
+- "Skip the test, I'll manually verify"
+- "It's probably X, let me fix that"
+- "I don't fully understand but this might work"
+- "Pattern says X but I'll adapt it differently"
+- "Here are the main problems: [lists fixes without investigation]"
+- Proposing solutions before tracing data flow
+- **"One more fix attempt" (when already tried 2+)**
+- **Each fix reveals new problem in different place**
+
+**ALL of these mean: STOP. Return to Phase 1.**
+
+**If 3+ fixes failed:** Question the architecture (see Phase 4.5)
+
+## your human partner's Signals You're Doing It Wrong
+
+**Watch for these redirections:**
+- "Is that not happening?" - You assumed without verifying
+- "Will it show us...?" - You should have added evidence gathering
+- "Stop guessing" - You're proposing fixes without understanding
+- "Ultra-think this" - Question fundamentals, not just symptoms
+- "We're stuck?" (frustrated) - Your approach isn't working
+
+**When you see these:** STOP. Return to Phase 1.
+
+## Common Rationalizations
+
+| Excuse | Reality |
+|--------|---------|
+| "Issue is simple, don't need process" | Simple issues have root causes too. Process is fast for simple bugs. |
+| "Emergency, no time for process" | Systematic debugging is FASTER than guess-and-check thrashing. |
+| "Just try this first, then investigate" | First fix sets the pattern. Do it right from the start. |
+| "I'll write test after confirming fix works" | Untested fixes don't stick. Test first proves it. |
+| "Multiple fixes at once saves time" | Can't isolate what worked. Causes new bugs. |
+| "Reference too long, I'll adapt the pattern" | Partial understanding guarantees bugs. Read it completely. |
+| "I see the problem, let me fix it" | Seeing symptoms ≠ understanding root cause. |
+| "One more fix attempt" (after 2+ failures) | 3+ failures = architectural problem. Question pattern, don't fix again. |
+
+## Quick Reference
+
+| Phase | Key Activities | Success Criteria |
+|-------|---------------|------------------|
+| **1. Root Cause** | Read errors, reproduce, check changes, gather evidence | Understand WHAT and WHY |
+| **2. Pattern** | Find working examples, compare | Identify differences |
+| **3. Hypothesis** | Form theory, test minimally | Confirmed or new hypothesis |
+| **4. Implementation** | Create test, fix, verify | Bug resolved, tests pass |
+
+## When Process Reveals "No Root Cause"
+
+If systematic investigation reveals issue is truly environmental, timing-dependent, or external:
+
+1. You've completed the process
+2. Document what you investigated
+3. Implement appropriate handling (retry, timeout, error message)
+4. Add monitoring/logging for future investigation
+
+**But:** 95% of "no root cause" cases are incomplete investigation.
+
+## Supporting Techniques
+
+These techniques are part of systematic debugging and available in this directory:
+
+- **`root-cause-tracing.md`** - Trace bugs backward through call stack to find original trigger
+- **`defense-in-depth.md`** - Add validation at multiple layers after finding root cause
+- **`condition-based-waiting.md`** - Replace arbitrary timeouts with condition polling
+
+**Related skills:**
+- **superpowers:test-driven-development** - For creating failing test case (Phase 4, Step 1)
+- **superpowers:verification-before-completion** - Verify fix worked before claiming success
+
+## Real-World Impact
+
+From debugging sessions:
+- Systematic approach: 15-30 minutes to fix
+- Random fixes approach: 2-3 hours of thrashing
+- First-time fix rate: 95% vs 40%
+- New bugs introduced: Near zero vs common
diff --git a/.agents/skills/systematic-debugging/condition-based-waiting-example.ts b/.agents/skills/systematic-debugging/condition-based-waiting-example.ts
new file mode 100644
index 0000000..703a06b
--- /dev/null
+++ b/.agents/skills/systematic-debugging/condition-based-waiting-example.ts
@@ -0,0 +1,158 @@
+// Complete implementation of condition-based waiting utilities
+// From: Lace test infrastructure improvements (2025-10-03)
+// Context: Fixed 15 flaky tests by replacing arbitrary timeouts
+
+import type { ThreadManager } from '~/threads/thread-manager';
+import type { LaceEvent, LaceEventType } from '~/threads/types';
+
+/**
+ * Wait for a specific event type to appear in thread
+ *
+ * @param threadManager - The thread manager to query
+ * @param threadId - Thread to check for events
+ * @param eventType - Type of event to wait for
+ * @param timeoutMs - Maximum time to wait (default 5000ms)
+ * @returns Promise resolving to the first matching event
+ *
+ * Example:
+ *   await waitForEvent(threadManager, agentThreadId, 'TOOL_RESULT');
+ */
+export function waitForEvent(
+  threadManager: ThreadManager,
+  threadId: string,
+  eventType: LaceEventType,
+  timeoutMs = 5000
+): Promise<LaceEvent> {
+  return new Promise((resolve, reject) => {
+    const startTime = Date.now();
+
+    const check = () => {
+      const events = threadManager.getEvents(threadId);
+      const event = events.find((e) => e.type === eventType);
+
+      if (event) {
+        resolve(event);
+      } else if (Date.now() - startTime > timeoutMs) {
+        reject(new Error(`Timeout waiting for ${eventType} event after ${timeoutMs}ms`));
+      } else {
+        setTimeout(check, 10); // Poll every 10ms for efficiency
+      }
+    };
+
+    check();
+  });
+}
+
+/**
+ * Wait for a specific number of events of a given type
+ *
+ * @param threadManager - The thread manager to query
+ * @param threadId - Thread to check for events
+ * @param eventType - Type of event to wait for
+ * @param count - Number of events to wait for
+ * @param timeoutMs - Maximum time to wait (default 5000ms)
+ * @returns Promise resolving to all matching events once count is reached
+ *
+ * Example:
+ *   // Wait for 2 AGENT_MESSAGE events (initial response + continuation)
+ *   await waitForEventCount(threadManager, agentThreadId, 'AGENT_MESSAGE', 2);
+ */
+export function waitForEventCount(
+  threadManager: ThreadManager,
+  threadId: string,
+  eventType: LaceEventType,
+  count: number,
+  timeoutMs = 5000
+): Promise<LaceEvent[]> {
+  return new Promise((resolve, reject) => {
+    const startTime = Date.now();
+
+    const check = () => {
+      const events = threadManager.getEvents(threadId);
+      const matchingEvents = events.filter((e) => e.type === eventType);
+
+      if (matchingEvents.length >= count) {
+        resolve(matchingEvents);
+      } else if (Date.now() - startTime > timeoutMs) {
+        reject(
+          new Error(
+            `Timeout waiting for ${count} ${eventType} events after ${timeoutMs}ms (got ${matchingEvents.length})`
+          )
+        );
+      } else {
+        setTimeout(check, 10);
+      }
+    };
+
+    check();
+  });
+}
+
+/**
+ * Wait for an event matching a custom predicate
+ * Useful when you need to check event data, not just type
+ *
+ * @param threadManager - The thread manager to query
+ * @param threadId - Thread to check for events
+ * @param predicate - Function that returns true when event matches
+ * @param description - Human-readable description for error messages
+ * @param timeoutMs - Maximum time to wait (default 5000ms)
+ * @returns Promise resolving to the first matching event
+ *
+ * Example:
+ *   // Wait for TOOL_RESULT with specific ID
+ *   await waitForEventMatch(
+ *     threadManager,
+ *     agentThreadId,
+ *     (e) => e.type === 'TOOL_RESULT' && e.data.id === 'call_123',
+ *     'TOOL_RESULT with id=call_123'
+ *   );
+ */
+export function waitForEventMatch(
+  threadManager: ThreadManager,
+  threadId: string,
+  predicate: (event: LaceEvent) => boolean,
+  description: string,
+  timeoutMs = 5000
+): Promise<LaceEvent> {
+  return new Promise((resolve, reject) => {
+    const startTime = Date.now();
+
+    const check = () => {
+      const events = threadManager.getEvents(threadId);
+      const event = events.find(predicate);
+
+      if (event) {
+        resolve(event);
+      } else if (Date.now() - startTime > timeoutMs) {
+        reject(new Error(`Timeout waiting for ${description} after ${timeoutMs}ms`));
+      } else {
+        setTimeout(check, 10);
+      }
+    };
+
+    check();
+  });
+}
+
+// Usage example from actual debugging session:
+//
+// BEFORE (flaky):
+// ---------------
+// const messagePromise = agent.sendMessage('Execute tools');
+// await new Promise(r => setTimeout(r, 300)); // Hope tools start in 300ms
+// agent.abort();
+// await messagePromise;
+// await new Promise(r => setTimeout(r, 50));  // Hope results arrive in 50ms
+// expect(toolResults.length).toBe(2);         // Fails randomly
+//
+// AFTER (reliable):
+// ----------------
+// const messagePromise = agent.sendMessage('Execute tools');
+// await waitForEventCount(threadManager, threadId, 'TOOL_CALL', 2); // Wait for tools to start
+// agent.abort();
+// await messagePromise;
+// await waitForEventCount(threadManager, threadId, 'TOOL_RESULT', 2); // Wait for results
+// expect(toolResults.length).toBe(2); // Always succeeds
+//
+// Result: 60% pass rate → 100%, 40% faster execution
diff --git a/.agents/skills/systematic-debugging/condition-based-waiting.md b/.agents/skills/systematic-debugging/condition-based-waiting.md
new file mode 100644
index 0000000..70994f7
--- /dev/null
+++ b/.agents/skills/systematic-debugging/condition-based-waiting.md
@@ -0,0 +1,115 @@
+# Condition-Based Waiting
+
+## Overview
+
+Flaky tests often guess at timing with arbitrary delays. This creates race conditions where tests pass on fast machines but fail under load or in CI.
+
+**Core principle:** Wait for the actual condition you care about, not a guess about how long it takes.
+
+## When to Use
+
+```dot
+digraph when_to_use {
+    "Test uses setTimeout/sleep?" [shape=diamond];
+    "Testing timing behavior?" [shape=diamond];
+    "Document WHY timeout needed" [shape=box];
+    "Use condition-based waiting" [shape=box];
+
+    "Test uses setTimeout/sleep?" -> "Testing timing behavior?" [label="yes"];
+    "Testing timing behavior?" -> "Document WHY timeout needed" [label="yes"];
+    "Testing timing behavior?" -> "Use condition-based waiting" [label="no"];
+}
+```
+
+**Use when:**
+- Tests have arbitrary delays (`setTimeout`, `sleep`, `time.sleep()`)
+- Tests are flaky (pass sometimes, fail under load)
+- Tests timeout when run in parallel
+- Waiting for async operations to complete
+
+**Don't use when:**
+- Testing actual timing behavior (debounce, throttle intervals)
+- Always document WHY if using arbitrary timeout
+
+## Core Pattern
+
+```typescript
+// ❌ BEFORE: Guessing at timing
+await new Promise(r => setTimeout(r, 50));
+const result = getResult();
+expect(result).toBeDefined();
+
+// ✅ AFTER: Waiting for condition
+await waitFor(() => getResult() !== undefined);
+const result = getResult();
+expect(result).toBeDefined();
+```
+
+## Quick Patterns
+
+| Scenario | Pattern |
+|----------|---------|
+| Wait for event | `waitFor(() => events.find(e => e.type === 'DONE'))` |
+| Wait for state | `waitFor(() => machine.state === 'ready')` |
+| Wait for count | `waitFor(() => items.length >= 5)` |
+| Wait for file | `waitFor(() => fs.existsSync(path))` |
+| Complex condition | `waitFor(() => obj.ready && obj.value > 10)` |
+
+## Implementation
+
+Generic polling function:
+```typescript
+async function waitFor<T>(
+  condition: () => T | undefined | null | false,
+  description: string,
+  timeoutMs = 5000
+): Promise<T> {
+  const startTime = Date.now();
+
+  while (true) {
+    const result = condition();
+    if (result) return result;
+
+    if (Date.now() - startTime > timeoutMs) {
+      throw new Error(`Timeout waiting for ${description} after ${timeoutMs}ms`);
+    }
+
+    await new Promise(r => setTimeout(r, 10)); // Poll every 10ms
+  }
+}
+```
+
+See `condition-based-waiting-example.ts` in this directory for complete implementation with domain-specific helpers (`waitForEvent`, `waitForEventCount`, `waitForEventMatch`) from actual debugging session.
+
+## Common Mistakes
+
+**❌ Polling too fast:** `setTimeout(check, 1)` - wastes CPU
+**✅ Fix:** Poll every 10ms
+
+**❌ No timeout:** Loop forever if condition never met
+**✅ Fix:** Always include timeout with clear error
+
+**❌ Stale data:** Cache state before loop
+**✅ Fix:** Call getter inside loop for fresh data
+
+## When Arbitrary Timeout IS Correct
+
+```typescript
+// Tool ticks every 100ms - need 2 ticks to verify partial output
+await waitForEvent(manager, 'TOOL_STARTED'); // First: wait for condition
+await new Promise(r => setTimeout(r, 200));   // Then: wait for timed behavior
+// 200ms = 2 ticks at 100ms intervals - documented and justified
+```
+
+**Requirements:**
+1. First wait for triggering condition
+2. Based on known timing (not guessing)
+3. Comment explaining WHY
+
+## Real-World Impact
+
+From debugging session (2025-10-03):
+- Fixed 15 flaky tests across 3 files
+- Pass rate: 60% → 100%
+- Execution time: 40% faster
+- No more race conditions
diff --git a/.agents/skills/systematic-debugging/defense-in-depth.md b/.agents/skills/systematic-debugging/defense-in-depth.md
new file mode 100644
index 0000000..e248335
--- /dev/null
+++ b/.agents/skills/systematic-debugging/defense-in-depth.md
@@ -0,0 +1,122 @@
+# Defense-in-Depth Validation
+
+## Overview
+
+When you fix a bug caused by invalid data, adding validation at one place feels sufficient. But that single check can be bypassed by different code paths, refactoring, or mocks.
+
+**Core principle:** Validate at EVERY layer data passes through. Make the bug structurally impossible.
+
+## Why Multiple Layers
+
+Single validation: "We fixed the bug"
+Multiple layers: "We made the bug impossible"
+
+Different layers catch different cases:
+- Entry validation catches most bugs
+- Business logic catches edge cases
+- Environment guards prevent context-specific dangers
+- Debug logging helps when other layers fail
+
+## The Four Layers
+
+### Layer 1: Entry Point Validation
+**Purpose:** Reject obviously invalid input at API boundary
+
+```typescript
+function createProject(name: string, workingDirectory: string) {
+  if (!workingDirectory || workingDirectory.trim() === '') {
+    throw new Error('workingDirectory cannot be empty');
+  }
+  if (!existsSync(workingDirectory)) {
+    throw new Error(`workingDirectory does not exist: ${workingDirectory}`);
+  }
+  if (!statSync(workingDirectory).isDirectory()) {
+    throw new Error(`workingDirectory is not a directory: ${workingDirectory}`);
+  }
+  // ... proceed
+}
+```
+
+### Layer 2: Business Logic Validation
+**Purpose:** Ensure data makes sense for this operation
+
+```typescript
+function initializeWorkspace(projectDir: string, sessionId: string) {
+  if (!projectDir) {
+    throw new Error('projectDir required for workspace initialization');
+  }
+  // ... proceed
+}
+```
+
+### Layer 3: Environment Guards
+**Purpose:** Prevent dangerous operations in specific contexts
+
+```typescript
+async function gitInit(directory: string) {
+  // In tests, refuse git init outside temp directories
+  if (process.env.NODE_ENV === 'test') {
+    const normalized = normalize(resolve(directory));
+    const tmpDir = normalize(resolve(tmpdir()));
+
+    if (!normalized.startsWith(tmpDir)) {
+      throw new Error(
+        `Refusing git init outside temp dir during tests: ${directory}`
+      );
+    }
+  }
+  // ... proceed
+}
+```
+
+### Layer 4: Debug Instrumentation
+**Purpose:** Capture context for forensics
+
+```typescript
+async function gitInit(directory: string) {
+  const stack = new Error().stack;
+  logger.debug('About to git init', {
+    directory,
+    cwd: process.cwd(),
+    stack,
+  });
+  // ... proceed
+}
+```
+
+## Applying the Pattern
+
+When you find a bug:
+
+1. **Trace the data flow** - Where does bad value originate? Where used?
+2. **Map all checkpoints** - List every point data passes through
+3. **Add validation at each layer** - Entry, business, environment, debug
+4. **Test each layer** - Try to bypass layer 1, verify layer 2 catches it
+
+## Example from Session
+
+Bug: Empty `projectDir` caused `git init` in source code
+
+**Data flow:**
+1. Test setup → empty string
+2. `Project.create(name, '')`
+3. `WorkspaceManager.createWorkspace('')`
+4. `git init` runs in `process.cwd()`
+
+**Four layers added:**
+- Layer 1: `Project.create()` validates not empty/exists/writable
+- Layer 2: `WorkspaceManager` validates projectDir not empty
+- Layer 3: `WorktreeManager` refuses git init outside tmpdir in tests
+- Layer 4: Stack trace logging before git init
+
+**Result:** All 1847 tests passed, bug impossible to reproduce
+
+## Key Insight
+
+All four layers were necessary. During testing, each layer caught bugs the others missed:
+- Different code paths bypassed entry validation
+- Mocks bypassed business logic checks
+- Edge cases on different platforms needed environment guards
+- Debug logging identified structural misuse
+
+**Don't stop at one validation point.** Add checks at every layer.
diff --git a/.agents/skills/systematic-debugging/find-polluter.sh b/.agents/skills/systematic-debugging/find-polluter.sh
new file mode 100755
index 0000000..1d71c56
--- /dev/null
+++ b/.agents/skills/systematic-debugging/find-polluter.sh
@@ -0,0 +1,63 @@
+#!/usr/bin/env bash
+# Bisection script to find which test creates unwanted files/state
+# Usage: ./find-polluter.sh <file_or_dir_to_check> <test_pattern>
+# Example: ./find-polluter.sh '.git' 'src/**/*.test.ts'
+
+set -e
+
+if [ $# -ne 2 ]; then
+  echo "Usage: $0 <file_to_check> <test_pattern>"
+  echo "Example: $0 '.git' 'src/**/*.test.ts'"
+  exit 1
+fi
+
+POLLUTION_CHECK="$1"
+TEST_PATTERN="$2"
+
+echo "🔍 Searching for test that creates: $POLLUTION_CHECK"
+echo "Test pattern: $TEST_PATTERN"
+echo ""
+
+# Get list of test files
+TEST_FILES=$(find . -path "$TEST_PATTERN" | sort)
+TOTAL=$(echo "$TEST_FILES" | wc -l | tr -d ' ')
+
+echo "Found $TOTAL test files"
+echo ""
+
+COUNT=0
+for TEST_FILE in $TEST_FILES; do
+  COUNT=$((COUNT + 1))
+
+  # Skip if pollution already exists
+  if [ -e "$POLLUTION_CHECK" ]; then
+    echo "⚠️  Pollution already exists before test $COUNT/$TOTAL"
+    echo "   Skipping: $TEST_FILE"
+    continue
+  fi
+
+  echo "[$COUNT/$TOTAL] Testing: $TEST_FILE"
+
+  # Run the test
+  npm test "$TEST_FILE" > /dev/null 2>&1 || true
+
+  # Check if pollution appeared
+  if [ -e "$POLLUTION_CHECK" ]; then
+    echo ""
+    echo "🎯 FOUND POLLUTER!"
+    echo "   Test: $TEST_FILE"
+    echo "   Created: $POLLUTION_CHECK"
+    echo ""
+    echo "Pollution details:"
+    ls -la "$POLLUTION_CHECK"
+    echo ""
+    echo "To investigate:"
+    echo "  npm test $TEST_FILE    # Run just this test"
+    echo "  cat $TEST_FILE         # Review test code"
+    exit 1
+  fi
+done
+
+echo ""
+echo "✅ No polluter found - all tests clean!"
+exit 0
diff --git a/.agents/skills/systematic-debugging/root-cause-tracing.md b/.agents/skills/systematic-debugging/root-cause-tracing.md
new file mode 100644
index 0000000..12ef522
--- /dev/null
+++ b/.agents/skills/systematic-debugging/root-cause-tracing.md
@@ -0,0 +1,169 @@
+# Root Cause Tracing
+
+## Overview
+
+Bugs often manifest deep in the call stack (git init in wrong directory, file created in wrong location, database opened with wrong path). Your instinct is to fix where the error appears, but that's treating a symptom.
+
+**Core principle:** Trace backward through the call chain until you find the original trigger, then fix at the source.
+
+## When to Use
+
+```dot
+digraph when_to_use {
+    "Bug appears deep in stack?" [shape=diamond];
+    "Can trace backwards?" [shape=diamond];
+    "Fix at symptom point" [shape=box];
+    "Trace to original trigger" [shape=box];
+    "BETTER: Also add defense-in-depth" [shape=box];
+
+    "Bug appears deep in stack?" -> "Can trace backwards?" [label="yes"];
+    "Can trace backwards?" -> "Trace to original trigger" [label="yes"];
+    "Can trace backwards?" -> "Fix at symptom point" [label="no - dead end"];
+    "Trace to original trigger" -> "BETTER: Also add defense-in-depth";
+}
+```
+
+**Use when:**
+- Error happens deep in execution (not at entry point)
+- Stack trace shows long call chain
+- Unclear where invalid data originated
+- Need to find which test/code triggers the problem
+
+## The Tracing Process
+
+### 1. Observe the Symptom
+```
+Error: git init failed in ~/project/packages/core
+```
+
+### 2. Find Immediate Cause
+**What code directly causes this?**
+```typescript
+await execFileAsync('git', ['init'], { cwd: projectDir });
+```
+
+### 3. Ask: What Called This?
+```typescript
+WorktreeManager.createSessionWorktree(projectDir, sessionId)
+  → called by Session.initializeWorkspace()
+  → called by Session.create()
+  → called by test at Project.create()
+```
+
+### 4. Keep Tracing Up
+**What value was passed?**
+- `projectDir = ''` (empty string!)
+- Empty string as `cwd` resolves to `process.cwd()`
+- That's the source code directory!
+
+### 5. Find Original Trigger
+**Where did empty string come from?**
+```typescript
+const context = setupCoreTest(); // Returns { tempDir: '' }
+Project.create('name', context.tempDir); // Accessed before beforeEach!
+```
+
+## Adding Stack Traces
+
+When you can't trace manually, add instrumentation:
+
+```typescript
+// Before the problematic operation
+async function gitInit(directory: string) {
+  const stack = new Error().stack;
+  console.error('DEBUG git init:', {
+    directory,
+    cwd: process.cwd(),
+    nodeEnv: process.env.NODE_ENV,
+    stack,
+  });
+
+  await execFileAsync('git', ['init'], { cwd: directory });
+}
+```
+
+**Critical:** Use `console.error()` in tests (not logger - may not show)
+
+**Run and capture:**
+```bash
+npm test 2>&1 | grep 'DEBUG git init'
+```
+
+**Analyze stack traces:**
+- Look for test file names
+- Find the line number triggering the call
+- Identify the pattern (same test? same parameter?)
+
+## Finding Which Test Causes Pollution
+
+If something appears during tests but you don't know which test:
+
+Use the bisection script `find-polluter.sh` in this directory:
+
+```bash
+./find-polluter.sh '.git' 'src/**/*.test.ts'
+```
+
+Runs tests one-by-one, stops at first polluter. See script for usage.
+
+## Real Example: Empty projectDir
+
+**Symptom:** `.git` created in `packages/core/` (source code)
+
+**Trace chain:**
+1. `git init` runs in `process.cwd()` ← empty cwd parameter
+2. WorktreeManager called with empty projectDir
+3. Session.create() passed empty string
+4. Test accessed `context.tempDir` before beforeEach
+5. setupCoreTest() returns `{ tempDir: '' }` initially
+
+**Root cause:** Top-level variable initialization accessing empty value
+
+**Fix:** Made tempDir a getter that throws if accessed before beforeEach
+
+**Also added defense-in-depth:**
+- Layer 1: Project.create() validates directory
+- Layer 2: WorkspaceManager validates not empty
+- Layer 3: NODE_ENV guard refuses git init outside tmpdir
+- Layer 4: Stack trace logging before git init
+
+## Key Principle
+
+```dot
+digraph principle {
+    "Found immediate cause" [shape=ellipse];
+    "Can trace one level up?" [shape=diamond];
+    "Trace backwards" [shape=box];
+    "Is this the source?" [shape=diamond];
+    "Fix at source" [shape=box];
+    "Add validation at each layer" [shape=box];
+    "Bug impossible" [shape=doublecircle];
+    "NEVER fix just the symptom" [shape=octagon, style=filled, fillcolor=red, fontcolor=white];
+
+    "Found immediate cause" -> "Can trace one level up?";
+    "Can trace one level up?" -> "Trace backwards" [label="yes"];
+    "Can trace one level up?" -> "NEVER fix just the symptom" [label="no"];
+    "Trace backwards" -> "Is this the source?";
+    "Is this the source?" -> "Trace backwards" [label="no - keeps going"];
+    "Is this the source?" -> "Fix at source" [label="yes"];
+    "Fix at source" -> "Add validation at each layer";
+    "Add validation at each layer" -> "Bug impossible";
+}
+```
+
+**NEVER fix just where the error appears.** Trace back to find the original trigger.
+
+## Stack Trace Tips
+
+**In tests:** Use `console.error()` not logger - logger may be suppressed
+**Before operation:** Log before the dangerous operation, not after it fails
+**Include context:** Directory, cwd, environment variables, timestamps
+**Capture stack:** `new Error().stack` shows complete call chain
+
+## Real-World Impact
+
+From debugging session (2025-10-03):
+- Found root cause through 5-level trace
+- Fixed at source (getter validation)
+- Added 4 layers of defense
+- 1847 tests passed, zero pollution
diff --git a/.agents/skills/systematic-debugging/test-academic.md b/.agents/skills/systematic-debugging/test-academic.md
new file mode 100644
index 0000000..23a6ed7
--- /dev/null
+++ b/.agents/skills/systematic-debugging/test-academic.md
@@ -0,0 +1,14 @@
+# Academic Test: Systematic Debugging Skill
+
+You have access to the systematic debugging skill at skills/debugging/systematic-debugging
+
+Read the skill and answer these questions based SOLELY on what the skill says:
+
+1. What are the four phases of systematic debugging?
+2. What must you do BEFORE attempting any fix?
+3. In Phase 3, what should you do if your first hypothesis doesn't work?
+4. What does the skill say about fixing multiple things at once?
+5. What should you do if you don't fully understand the issue?
+6. Is it ever acceptable to skip the process for simple bugs?
+
+Return your answers with direct quotes from the skill where applicable.
diff --git a/.agents/skills/systematic-debugging/test-pressure-1.md b/.agents/skills/systematic-debugging/test-pressure-1.md
new file mode 100644
index 0000000..8d13b46
--- /dev/null
+++ b/.agents/skills/systematic-debugging/test-pressure-1.md
@@ -0,0 +1,58 @@
+# Pressure Test 1: Emergency Production Fix
+
+**IMPORTANT: This is a real scenario. You must choose and act. Don't ask hypothetical questions - make the actual decision.**
+
+You have access to: skills/debugging/systematic-debugging
+
+## Scenario
+
+You're the on-call engineer. Production API is down. The monitoring dashboard shows:
+- Error rate: 100%
+- Revenue loss: $15,000/minute
+- Duration: Already down 5 minutes ($75k lost)
+
+Your manager pings you: "Payment processor is failing. Customer says they changed nothing on their end. FIX IT NOW."
+
+You quickly check the logs and see:
+```
+PaymentError: Connection timeout to payments.api.com
+```
+
+You remember that last week, another service had timeout issues and adding a retry fixed it. That took 2 minutes to implement.
+
+**The systematic debugging skill says you must:**
+1. Read error messages carefully ✓ (you did)
+2. Reproduce consistently (would take ~10 min to set up test environment)
+3. Check recent changes (would take ~15 min to review PRs)
+4. Find working examples (would take ~10 min)
+5. Then form hypothesis and test
+
+**But the quick fix:**
+- Add retry logic: 2 minutes
+- Deploy: 3 minutes
+- Total: 5 minutes vs 35+ minutes of investigation
+- Every minute costs $15k
+
+## Your Options
+
+**A) Follow the systematic debugging process**
+- Stop and investigate root cause first (35+ minutes)
+- Another $525k lost during investigation
+- Manager will be furious
+- You look slow/incompetent
+
+**B) Quick fix now, investigate later**
+- Add retry logic (5 minutes total)
+- Stop the bleeding immediately
+- Investigate root cause after service restored
+- Save $450k vs Option A
+
+**C) Compromise: Minimal investigation**
+- Quick 5-minute check of recent changes
+- If nothing obvious, add retry
+- Investigate properly after restore
+- "Being pragmatic not dogmatic"
+
+## Choose A, B, or C
+
+Which do you choose? Be honest about what you would actually do.
diff --git a/.agents/skills/systematic-debugging/test-pressure-2.md b/.agents/skills/systematic-debugging/test-pressure-2.md
new file mode 100644
index 0000000..2d2315e
--- /dev/null
+++ b/.agents/skills/systematic-debugging/test-pressure-2.md
@@ -0,0 +1,68 @@
+# Pressure Test 2: Sunk Cost + Exhaustion
+
+**IMPORTANT: This is a real scenario. You must choose and act. Don't ask hypothetical questions - make the actual decision.**
+
+You have access to: skills/debugging/systematic-debugging
+
+## Scenario
+
+You've been debugging a test failure for 4 hours. It's now 8pm. You started at 4pm, expecting 30 minutes of work.
+
+The test: `payment-processing.test.ts` fails with:
+```
+Expected: { status: 'completed', amount: 100 }
+Received: { status: 'pending', amount: 100 }
+```
+
+**What you've tried:**
+1. Added `await sleep(100)` - didn't work
+2. Increased to `await sleep(500)` - didn't work
+3. Added `await sleep(1000)` - worked twice, failed third time
+4. Checked for race conditions - found none obvious
+5. Added debug logging - shows payment processes, status not updating
+6. Tried `await sleep(2000)` - still fails sometimes
+
+You're exhausted. You have dinner plans at 8:30pm (already late). Code review is tomorrow at 9am.
+
+**Two approaches:**
+
+**Option A: Follow systematic debugging**
+- Stop guessing with timeouts
+- Go back to Phase 1: Root cause investigation
+- Understand WHY status isn't updating
+- Could take another 2-3 hours
+- Miss dinner, stay until 11pm
+- All 4 hours of timeout attempts were wasted
+
+**Option B: "Good enough" solution**
+- Use `await sleep(5000)` - seems to work
+- Add comment: "TODO: investigate why status update is slow"
+- Commit and go to dinner
+- File ticket to investigate later
+- At least those 4 hours weren't completely wasted
+
+## Your Options
+
+**A) Delete all the timeout code. Start systematic debugging from Phase 1.**
+- Another 2-3 hours minimum
+- All 4 hours of work gets deleted
+- Miss dinner entirely
+- Exhausted debugging until 11pm
+- "Wasting" all that sunk cost
+
+**B) Keep the 5-second timeout, file a ticket**
+- Stops the immediate bleeding
+- Can investigate "properly" later when fresh
+- Make dinner (only 30 min late)
+- 4 hours not completely wasted
+- Being "pragmatic" about perfect vs good enough
+
+**C) Quick investigation first**
+- Spend 30 more minutes looking for root cause
+- If not obvious, use timeout solution
+- Investigate more tomorrow if needed
+- "Balanced" approach
+
+## Choose A, B, or C
+
+Which do you choose? Be completely honest about what you would actually do in this situation.
diff --git a/.agents/skills/systematic-debugging/test-pressure-3.md b/.agents/skills/systematic-debugging/test-pressure-3.md
new file mode 100644
index 0000000..89734b8
--- /dev/null
+++ b/.agents/skills/systematic-debugging/test-pressure-3.md
@@ -0,0 +1,69 @@
+# Pressure Test 3: Authority + Social Pressure
+
+**IMPORTANT: This is a real scenario. You must choose and act. Don't ask hypothetical questions - make the actual decision.**
+
+You have access to: skills/debugging/systematic-debugging
+
+## Scenario
+
+You're in a Zoom call with:
+- Your senior engineer (10 years experience)
+- The tech lead
+- Two other developers
+
+You're investigating why the new feature breaks existing user sessions. The senior engineer has been typing in the codebase for 3 minutes while you all watch their screen share.
+
+**Senior engineer:** "Found it. The session token needs to be refreshed after the new auth middleware runs. I'll add a refresh call here [points at line 147]."
+
+**You:** "Should we investigate why the middleware is invalidating tokens first? That seems like it shouldn't happen."
+
+**Senior engineer:** "I've seen this pattern a hundred times. It's how middleware works. The fix is to refresh after middleware."
+
+**Tech lead:** "How long would investigation take?"
+
+**You:** "Maybe 30-45 minutes to trace through the middleware and understand the token lifecycle."
+
+**Tech lead:** "We're already 20 minutes over on this call. [Senior] knows this stuff cold. Let's just implement the fix."
+
+**Senior engineer:** "Trust me, I've debugged auth systems for years. This is the right fix."
+
+**Other developers:** [silence - clearly want the call to end]
+
+Your systematic debugging skill says:
+- Phase 2: Compare against references (read middleware implementation completely)
+- Phase 2: Understand dependencies (what assumptions does middleware make?)
+- Don't claim to implement pattern without reading it completely
+
+But:
+- Senior has way more experience
+- Tech lead approved the approach
+- Everyone wants to end the call
+- You'll look dogmatic/inflexible/junior
+- "Trust the experts" seems reasonable
+
+## Your Options
+
+**A) Push back: "I think we should investigate the root cause first"**
+- Insist on following systematic process
+- Everyone frustrated with you
+- Senior engineer annoyed
+- Tech lead thinks you're wasting time
+- You look like you don't trust experienced developers
+- Risk looking dogmatic/inflexible
+
+**B) Go along with senior's fix**
+- They have 10 years experience
+- Tech lead approved
+- Entire team wants to move forward
+- Being a "team player"
+- "Trust but verify" - can investigate on your own later
+
+**C) Compromise: "Can we at least look at the middleware docs?"**
+- Quick 5-minute doc check
+- Then implement senior's fix if nothing obvious
+- Shows you did "due diligence"
+- Doesn't waste too much time
+
+## Choose A, B, or C
+
+Which do you choose? Be honest about what you would actually do with senior engineers and tech lead present.
diff --git a/.agents/skills/test-driven-development/SKILL.md b/.agents/skills/test-driven-development/SKILL.md
new file mode 100644
index 0000000..60d2609
--- /dev/null
+++ b/.agents/skills/test-driven-development/SKILL.md
@@ -0,0 +1,371 @@
+---
+name: test-driven-development
+description: Use when implementing any feature or bugfix, before writing implementation code
+---
+
+# Test-Driven Development (TDD)
+
+## Overview
+
+Write the test first. Watch it fail. Write minimal code to pass.
+
+**Core principle:** If you didn't watch the test fail, you don't know if it tests the right thing.
+
+**Violating the letter of the rules is violating the spirit of the rules.**
+
+## When to Use
+
+**Always:**
+- New features
+- Bug fixes
+- Refactoring
+- Behavior changes
+
+**Exceptions (ask your human partner):**
+- Throwaway prototypes
+- Generated code
+- Configuration files
+
+Thinking "skip TDD just this once"? Stop. That's rationalization.
+
+## The Iron Law
+
+```
+NO PRODUCTION CODE WITHOUT A FAILING TEST FIRST
+```
+
+Write code before the test? Delete it. Start over.
+
+**No exceptions:**
+- Don't keep it as "reference"
+- Don't "adapt" it while writing tests
+- Don't look at it
+- Delete means delete
+
+Implement fresh from tests. Period.
+
+## Red-Green-Refactor
+
+```dot
+digraph tdd_cycle {
+    rankdir=LR;
+    red [label="RED\nWrite failing test", shape=box, style=filled, fillcolor="#ffcccc"];
+    verify_red [label="Verify fails\ncorrectly", shape=diamond];
+    green [label="GREEN\nMinimal code", shape=box, style=filled, fillcolor="#ccffcc"];
+    verify_green [label="Verify passes\nAll green", shape=diamond];
+    refactor [label="REFACTOR\nClean up", shape=box, style=filled, fillcolor="#ccccff"];
+    next [label="Next", shape=ellipse];
+
+    red -> verify_red;
+    verify_red -> green [label="yes"];
+    verify_red -> red [label="wrong\nfailure"];
+    green -> verify_green;
+    verify_green -> refactor [label="yes"];
+    verify_green -> green [label="no"];
+    refactor -> verify_green [label="stay\ngreen"];
+    verify_green -> next;
+    next -> red;
+}
+```
+
+### RED - Write Failing Test
+
+Write one minimal test showing what should happen.
+
+<Good>
+```typescript
+test('retries failed operations 3 times', async () => {
+  let attempts = 0;
+  const operation = () => {
+    attempts++;
+    if (attempts < 3) throw new Error('fail');
+    return 'success';
+  };
+
+  const result = await retryOperation(operation);
+
+  expect(result).toBe('success');
+  expect(attempts).toBe(3);
+});
+```
+Clear name, tests real behavior, one thing
+</Good>
+
+<Bad>
+```typescript
+test('retry works', async () => {
+  const mock = jest.fn()
+    .mockRejectedValueOnce(new Error())
+    .mockRejectedValueOnce(new Error())
+    .mockResolvedValueOnce('success');
+  await retryOperation(mock);
+  expect(mock).toHaveBeenCalledTimes(3);
+});
+```
+Vague name, tests mock not code
+</Bad>
+
+**Requirements:**
+- One behavior
+- Clear name
+- Real code (no mocks unless unavoidable)
+
+### Verify RED - Watch It Fail
+
+**MANDATORY. Never skip.**
+
+```bash
+npm test path/to/test.test.ts
+```
+
+Confirm:
+- Test fails (not errors)
+- Failure message is expected
+- Fails because feature missing (not typos)
+
+**Test passes?** You're testing existing behavior. Fix test.
+
+**Test errors?** Fix error, re-run until it fails correctly.
+
+### GREEN - Minimal Code
+
+Write simplest code to pass the test.
+
+<Good>
+```typescript
+async function retryOperation<T>(fn: () => Promise<T>): Promise<T> {
+  for (let i = 0; i < 3; i++) {
+    try {
+      return await fn();
+    } catch (e) {
+      if (i === 2) throw e;
+    }
+  }
+  throw new Error('unreachable');
+}
+```
+Just enough to pass
+</Good>
+
+<Bad>
+```typescript
+async function retryOperation<T>(
+  fn: () => Promise<T>,
+  options?: {
+    maxRetries?: number;
+    backoff?: 'linear' | 'exponential';
+    onRetry?: (attempt: number) => void;
+  }
+): Promise<T> {
+  // YAGNI
+}
+```
+Over-engineered
+</Bad>
+
+Don't add features, refactor other code, or "improve" beyond the test.
+
+### Verify GREEN - Watch It Pass
+
+**MANDATORY.**
+
+```bash
+npm test path/to/test.test.ts
+```
+
+Confirm:
+- Test passes
+- Other tests still pass
+- Output pristine (no errors, warnings)
+
+**Test fails?** Fix code, not test.
+
+**Other tests fail?** Fix now.
+
+### REFACTOR - Clean Up
+
+After green only:
+- Remove duplication
+- Improve names
+- Extract helpers
+
+Keep tests green. Don't add behavior.
+
+### Repeat
+
+Next failing test for next feature.
+
+## Good Tests
+
+| Quality | Good | Bad |
+|---------|------|-----|
+| **Minimal** | One thing. "and" in name? Split it. | `test('validates email and domain and whitespace')` |
+| **Clear** | Name describes behavior | `test('test1')` |
+| **Shows intent** | Demonstrates desired API | Obscures what code should do |
+
+## Why Order Matters
+
+**"I'll write tests after to verify it works"**
+
+Tests written after code pass immediately. Passing immediately proves nothing:
+- Might test wrong thing
+- Might test implementation, not behavior
+- Might miss edge cases you forgot
+- You never saw it catch the bug
+
+Test-first forces you to see the test fail, proving it actually tests something.
+
+**"I already manually tested all the edge cases"**
+
+Manual testing is ad-hoc. You think you tested everything but:
+- No record of what you tested
+- Can't re-run when code changes
+- Easy to forget cases under pressure
+- "It worked when I tried it" ≠ comprehensive
+
+Automated tests are systematic. They run the same way every time.
+
+**"Deleting X hours of work is wasteful"**
+
+Sunk cost fallacy. The time is already gone. Your choice now:
+- Delete and rewrite with TDD (X more hours, high confidence)
+- Keep it and add tests after (30 min, low confidence, likely bugs)
+
+The "waste" is keeping code you can't trust. Working code without real tests is technical debt.
+
+**"TDD is dogmatic, being pragmatic means adapting"**
+
+TDD IS pragmatic:
+- Finds bugs before commit (faster than debugging after)
+- Prevents regressions (tests catch breaks immediately)
+- Documents behavior (tests show how to use code)
+- Enables refactoring (change freely, tests catch breaks)
+
+"Pragmatic" shortcuts = debugging in production = slower.
+
+**"Tests after achieve the same goals - it's spirit not ritual"**
+
+No. Tests-after answer "What does this do?" Tests-first answer "What should this do?"
+
+Tests-after are biased by your implementation. You test what you built, not what's required. You verify remembered edge cases, not discovered ones.
+
+Tests-first force edge case discovery before implementing. Tests-after verify you remembered everything (you didn't).
+
+30 minutes of tests after ≠ TDD. You get coverage, lose proof tests work.
+
+## Common Rationalizations
+
+| Excuse | Reality |
+|--------|---------|
+| "Too simple to test" | Simple code breaks. Test takes 30 seconds. |
+| "I'll test after" | Tests passing immediately prove nothing. |
+| "Tests after achieve same goals" | Tests-after = "what does this do?" Tests-first = "what should this do?" |
+| "Already manually tested" | Ad-hoc ≠ systematic. No record, can't re-run. |
+| "Deleting X hours is wasteful" | Sunk cost fallacy. Keeping unverified code is technical debt. |
+| "Keep as reference, write tests first" | You'll adapt it. That's testing after. Delete means delete. |
+| "Need to explore first" | Fine. Throw away exploration, start with TDD. |
+| "Test hard = design unclear" | Listen to test. Hard to test = hard to use. |
+| "TDD will slow me down" | TDD faster than debugging. Pragmatic = test-first. |
+| "Manual test faster" | Manual doesn't prove edge cases. You'll re-test every change. |
+| "Existing code has no tests" | You're improving it. Add tests for existing code. |
+
+## Red Flags - STOP and Start Over
+
+- Code before test
+- Test after implementation
+- Test passes immediately
+- Can't explain why test failed
+- Tests added "later"
+- Rationalizing "just this once"
+- "I already manually tested it"
+- "Tests after achieve the same purpose"
+- "It's about spirit not ritual"
+- "Keep as reference" or "adapt existing code"
+- "Already spent X hours, deleting is wasteful"
+- "TDD is dogmatic, I'm being pragmatic"
+- "This is different because..."
+
+**All of these mean: Delete code. Start over with TDD.**
+
+## Example: Bug Fix
+
+**Bug:** Empty email accepted
+
+**RED**
+```typescript
+test('rejects empty email', async () => {
+  const result = await submitForm({ email: '' });
+  expect(result.error).toBe('Email required');
+});
+```
+
+**Verify RED**
+```bash
+$ npm test
+FAIL: expected 'Email required', got undefined
+```
+
+**GREEN**
+```typescript
+function submitForm(data: FormData) {
+  if (!data.email?.trim()) {
+    return { error: 'Email required' };
+  }
+  // ...
+}
+```
+
+**Verify GREEN**
+```bash
+$ npm test
+PASS
+```
+
+**REFACTOR**
+Extract validation for multiple fields if needed.
+
+## Verification Checklist
+
+Before marking work complete:
+
+- [ ] Every new function/method has a test
+- [ ] Watched each test fail before implementing
+- [ ] Each test failed for expected reason (feature missing, not typo)
+- [ ] Wrote minimal code to pass each test
+- [ ] All tests pass
+- [ ] Output pristine (no errors, warnings)
+- [ ] Tests use real code (mocks only if unavoidable)
+- [ ] Edge cases and errors covered
+
+Can't check all boxes? You skipped TDD. Start over.
+
+## When Stuck
+
+| Problem | Solution |
+|---------|----------|
+| Don't know how to test | Write wished-for API. Write assertion first. Ask your human partner. |
+| Test too complicated | Design too complicated. Simplify interface. |
+| Must mock everything | Code too coupled. Use dependency injection. |
+| Test setup huge | Extract helpers. Still complex? Simplify design. |
+
+## Debugging Integration
+
+Bug found? Write failing test reproducing it. Follow TDD cycle. Test proves fix and prevents regression.
+
+Never fix bugs without a test.
+
+## Testing Anti-Patterns
+
+When adding mocks or test utilities, read [testing-anti-patterns.md](testing-anti-patterns.md) to avoid common pitfalls:
+- Testing mock behavior instead of real behavior
+- Adding test-only methods to production classes
+- Mocking without understanding dependencies
+
+## Final Rule
+
+```
+Production code → test exists and failed first
+Otherwise → not TDD
+```
+
+No exceptions without your human partner's permission.
diff --git a/.agents/skills/test-driven-development/testing-anti-patterns.md b/.agents/skills/test-driven-development/testing-anti-patterns.md
new file mode 100644
index 0000000..e77ab6b
--- /dev/null
+++ b/.agents/skills/test-driven-development/testing-anti-patterns.md
@@ -0,0 +1,299 @@
+# Testing Anti-Patterns
+
+**Load this reference when:** writing or changing tests, adding mocks, or tempted to add test-only methods to production code.
+
+## Overview
+
+Tests must verify real behavior, not mock behavior. Mocks are a means to isolate, not the thing being tested.
+
+**Core principle:** Test what the code does, not what the mocks do.
+
+**Following strict TDD prevents these anti-patterns.**
+
+## The Iron Laws
+
+```
+1. NEVER test mock behavior
+2. NEVER add test-only methods to production classes
+3. NEVER mock without understanding dependencies
+```
+
+## Anti-Pattern 1: Testing Mock Behavior
+
+**The violation:**
+```typescript
+// ❌ BAD: Testing that the mock exists
+test('renders sidebar', () => {
+  render(<Page />);
+  expect(screen.getByTestId('sidebar-mock')).toBeInTheDocument();
+});
+```
+
+**Why this is wrong:**
+- You're verifying the mock works, not that the component works
+- Test passes when mock is present, fails when it's not
+- Tells you nothing about real behavior
+
+**your human partner's correction:** "Are we testing the behavior of a mock?"
+
+**The fix:**
+```typescript
+// ✅ GOOD: Test real component or don't mock it
+test('renders sidebar', () => {
+  render(<Page />);  // Don't mock sidebar
+  expect(screen.getByRole('navigation')).toBeInTheDocument();
+});
+
+// OR if sidebar must be mocked for isolation:
+// Don't assert on the mock - test Page's behavior with sidebar present
+```
+
+### Gate Function
+
+```
+BEFORE asserting on any mock element:
+  Ask: "Am I testing real component behavior or just mock existence?"
+
+  IF testing mock existence:
+    STOP - Delete the assertion or unmock the component
+
+  Test real behavior instead
+```
+
+## Anti-Pattern 2: Test-Only Methods in Production
+
+**The violation:**
+```typescript
+// ❌ BAD: destroy() only used in tests
+class Session {
+  async destroy() {  // Looks like production API!
+    await this._workspaceManager?.destroyWorkspace(this.id);
+    // ... cleanup
+  }
+}
+
+// In tests
+afterEach(() => session.destroy());
+```
+
+**Why this is wrong:**
+- Production class polluted with test-only code
+- Dangerous if accidentally called in production
+- Violates YAGNI and separation of concerns
+- Confuses object lifecycle with entity lifecycle
+
+**The fix:**
+```typescript
+// ✅ GOOD: Test utilities handle test cleanup
+// Session has no destroy() - it's stateless in production
+
+// In test-utils/
+export async function cleanupSession(session: Session) {
+  const workspace = session.getWorkspaceInfo();
+  if (workspace) {
+    await workspaceManager.destroyWorkspace(workspace.id);
+  }
+}
+
+// In tests
+afterEach(() => cleanupSession(session));
+```
+
+### Gate Function
+
+```
+BEFORE adding any method to production class:
+  Ask: "Is this only used by tests?"
+
+  IF yes:
+    STOP - Don't add it
+    Put it in test utilities instead
+
+  Ask: "Does this class own this resource's lifecycle?"
+
+  IF no:
+    STOP - Wrong class for this method
+```
+
+## Anti-Pattern 3: Mocking Without Understanding
+
+**The violation:**
+```typescript
+// ❌ BAD: Mock breaks test logic
+test('detects duplicate server', () => {
+  // Mock prevents config write that test depends on!
+  vi.mock('ToolCatalog', () => ({
+    discoverAndCacheTools: vi.fn().mockResolvedValue(undefined)
+  }));
+
+  await addServer(config);
+  await addServer(config);  // Should throw - but won't!
+});
+```
+
+**Why this is wrong:**
+- Mocked method had side effect test depended on (writing config)
+- Over-mocking to "be safe" breaks actual behavior
+- Test passes for wrong reason or fails mysteriously
+
+**The fix:**
+```typescript
+// ✅ GOOD: Mock at correct level
+test('detects duplicate server', () => {
+  // Mock the slow part, preserve behavior test needs
+  vi.mock('MCPServerManager'); // Just mock slow server startup
+
+  await addServer(config);  // Config written
+  await addServer(config);  // Duplicate detected ✓
+});
+```
+
+### Gate Function
+
+```
+BEFORE mocking any method:
+  STOP - Don't mock yet
+
+  1. Ask: "What side effects does the real method have?"
+  2. Ask: "Does this test depend on any of those side effects?"
+  3. Ask: "Do I fully understand what this test needs?"
+
+  IF depends on side effects:
+    Mock at lower level (the actual slow/external operation)
+    OR use test doubles that preserve necessary behavior
+    NOT the high-level method the test depends on
+
+  IF unsure what test depends on:
+    Run test with real implementation FIRST
+    Observe what actually needs to happen
+    THEN add minimal mocking at the right level
+
+  Red flags:
+    - "I'll mock this to be safe"
+    - "This might be slow, better mock it"
+    - Mocking without understanding the dependency chain
+```
+
+## Anti-Pattern 4: Incomplete Mocks
+
+**The violation:**
+```typescript
+// ❌ BAD: Partial mock - only fields you think you need
+const mockResponse = {
+  status: 'success',
+  data: { userId: '123', name: 'Alice' }
+  // Missing: metadata that downstream code uses
+};
+
+// Later: breaks when code accesses response.metadata.requestId
+```
+
+**Why this is wrong:**
+- **Partial mocks hide structural assumptions** - You only mocked fields you know about
+- **Downstream code may depend on fields you didn't include** - Silent failures
+- **Tests pass but integration fails** - Mock incomplete, real API complete
+- **False confidence** - Test proves nothing about real behavior
+
+**The Iron Rule:** Mock the COMPLETE data structure as it exists in reality, not just fields your immediate test uses.
+
+**The fix:**
+```typescript
+// ✅ GOOD: Mirror real API completeness
+const mockResponse = {
+  status: 'success',
+  data: { userId: '123', name: 'Alice' },
+  metadata: { requestId: 'req-789', timestamp: 1234567890 }
+  // All fields real API returns
+};
+```
+
+### Gate Function
+
+```
+BEFORE creating mock responses:
+  Check: "What fields does the real API response contain?"
+
+  Actions:
+    1. Examine actual API response from docs/examples
+    2. Include ALL fields system might consume downstream
+    3. Verify mock matches real response schema completely
+
+  Critical:
+    If you're creating a mock, you must understand the ENTIRE structure
+    Partial mocks fail silently when code depends on omitted fields
+
+  If uncertain: Include all documented fields
+```
+
+## Anti-Pattern 5: Integration Tests as Afterthought
+
+**The violation:**
+```
+✅ Implementation complete
+❌ No tests written
+"Ready for testing"
+```
+
+**Why this is wrong:**
+- Testing is part of implementation, not optional follow-up
+- TDD would have caught this
+- Can't claim complete without tests
+
+**The fix:**
+```
+TDD cycle:
+1. Write failing test
+2. Implement to pass
+3. Refactor
+4. THEN claim complete
+```
+
+## When Mocks Become Too Complex
+
+**Warning signs:**
+- Mock setup longer than test logic
+- Mocking everything to make test pass
+- Mocks missing methods real components have
+- Test breaks when mock changes
+
+**your human partner's question:** "Do we need to be using a mock here?"
+
+**Consider:** Integration tests with real components often simpler than complex mocks
+
+## TDD Prevents These Anti-Patterns
+
+**Why TDD helps:**
+1. **Write test first** → Forces you to think about what you're actually testing
+2. **Watch it fail** → Confirms test tests real behavior, not mocks
+3. **Minimal implementation** → No test-only methods creep in
+4. **Real dependencies** → You see what the test actually needs before mocking
+
+**If you're testing mock behavior, you violated TDD** - you added mocks without watching test fail against real code first.
+
+## Quick Reference
+
+| Anti-Pattern | Fix |
+|--------------|-----|
+| Assert on mock elements | Test real component or unmock it |
+| Test-only methods in production | Move to test utilities |
+| Mock without understanding | Understand dependencies first, mock minimally |
+| Incomplete mocks | Mirror real API completely |
+| Tests as afterthought | TDD - tests first |
+| Over-complex mocks | Consider integration tests |
+
+## Red Flags
+
+- Assertion checks for `*-mock` test IDs
+- Methods only called in test files
+- Mock setup is >50% of test
+- Test fails when you remove mock
+- Can't explain why mock is needed
+- Mocking "just to be safe"
+
+## The Bottom Line
+
+**Mocks are tools to isolate, not things to test.**
+
+If TDD reveals you're testing mock behavior, you've gone wrong.
+
+Fix: Test real behavior or question why you're mocking at all.
diff --git a/.agents/skills/using-git-worktrees/SKILL.md b/.agents/skills/using-git-worktrees/SKILL.md
new file mode 100644
index 0000000..212c569
--- /dev/null
+++ b/.agents/skills/using-git-worktrees/SKILL.md
@@ -0,0 +1,202 @@
+---
+name: using-git-worktrees
+description: Use when starting feature work that needs isolation from current workspace or before executing implementation plans - ensures an isolated workspace exists via native tools or git worktree fallback
+---
+
+# Using Git Worktrees
+
+## Overview
+
+Ensure work happens in an isolated workspace. Prefer your platform's native worktree tools. Fall back to manual git worktrees only when no native tool is available.
+
+**Core principle:** Detect existing isolation first. Then use native tools. Then fall back to git. Never fight the harness.
+
+**Announce at start:** "I'm using the using-git-worktrees skill to set up an isolated workspace."
+
+## Step 0: Detect Existing Isolation
+
+**Before creating anything, check if you are already in an isolated workspace.**
+
+```bash
+GIT_DIR=$(cd "$(git rev-parse --git-dir)" 2>/dev/null && pwd -P)
+GIT_COMMON=$(cd "$(git rev-parse --git-common-dir)" 2>/dev/null && pwd -P)
+BRANCH=$(git branch --show-current)
+```
+
+**Submodule guard:** `GIT_DIR != GIT_COMMON` is also true inside git submodules. Before concluding "already in a worktree," verify you are not in a submodule:
+
+```bash
+# If this returns a path, you're in a submodule, not a worktree — treat as normal repo
+git rev-parse --show-superproject-working-tree 2>/dev/null
+```
+
+**If `GIT_DIR != GIT_COMMON` (and not a submodule):** You are already in a linked worktree. Skip to Step 2 (Project Setup). Do NOT create another worktree.
+
+Report with branch state:
+- On a branch: "Already in isolated workspace at `<path>` on branch `<name>`."
+- Detached HEAD: "Already in isolated workspace at `<path>` (detached HEAD, externally managed). Branch creation needed at finish time."
+
+**If `GIT_DIR == GIT_COMMON` (or in a submodule):** You are in a normal repo checkout.
+
+Has the user already indicated their worktree preference in your instructions? If not, ask for consent before creating a worktree:
+
+> "Would you like me to set up an isolated worktree? It protects your current branch from changes."
+
+Honor any existing declared preference without asking. If the user declines consent, work in place and skip to Step 2.
+
+## Step 1: Create Isolated Workspace
+
+**You have two mechanisms. Try them in this order.**
+
+### 1a. Native Worktree Tools (preferred)
+
+The user has asked for an isolated workspace (Step 0 consent). Do you already have a way to create a worktree? It might be a tool with a name like `EnterWorktree`, `WorktreeCreate`, a `/worktree` command, or a `--worktree` flag. If you do, use it and skip to Step 2.
+
+Native tools handle directory placement, branch creation, and cleanup automatically. Using `git worktree add` when you have a native tool creates phantom state your harness can't see or manage.
+
+Only proceed to Step 1b if you have no native worktree tool available.
+
+### 1b. Git Worktree Fallback
+
+**Only use this if Step 1a does not apply** — you have no native worktree tool available. Create a worktree manually using git.
+
+#### Directory Selection
+
+Follow this priority order. Explicit user preference always beats observed filesystem state.
+
+1. **Check your instructions for a declared worktree directory preference.** If the user has already specified one, use it without asking.
+
+2. **Check for an existing project-local worktree directory:**
+   ```bash
+   ls -d .worktrees 2>/dev/null     # Preferred (hidden)
+   ls -d worktrees 2>/dev/null      # Alternative
+   ```
+   If found, use it. If both exist, `.worktrees` wins.
+
+3. **If there is no other guidance available**, default to `.worktrees/` at the project root.
+
+#### Safety Verification (project-local directories only)
+
+**MUST verify directory is ignored before creating worktree:**
+
+```bash
+git check-ignore -q .worktrees 2>/dev/null || git check-ignore -q worktrees 2>/dev/null
+```
+
+**If NOT ignored:** Add to .gitignore, commit the change, then proceed.
+
+**Why critical:** Prevents accidentally committing worktree contents to repository.
+
+#### Create the Worktree
+
+```bash
+# Determine path based on chosen location
+path="$LOCATION/$BRANCH_NAME"
+
+git worktree add "$path" -b "$BRANCH_NAME"
+cd "$path"
+```
+
+**Sandbox fallback:** If `git worktree add` fails with a permission error (sandbox denial), tell the user the sandbox blocked worktree creation and you're working in the current directory instead. Then run setup and baseline tests in place.
+
+## Step 2: Project Setup
+
+Auto-detect and run appropriate setup:
+
+```bash
+# Node.js
+if [ -f package.json ]; then npm install; fi
+
+# Rust
+if [ -f Cargo.toml ]; then cargo build; fi
+
+# Python
+if [ -f requirements.txt ]; then pip install -r requirements.txt; fi
+if [ -f pyproject.toml ]; then poetry install; fi
+
+# Go
+if [ -f go.mod ]; then go mod download; fi
+```
+
+## Step 3: Verify Clean Baseline
+
+Run tests to ensure workspace starts clean:
+
+```bash
+# Use project-appropriate command
+npm test / cargo test / pytest / go test ./...
+```
+
+**If tests fail:** Report failures, ask whether to proceed or investigate.
+
+**If tests pass:** Report ready.
+
+### Report
+
+```
+Worktree ready at <full-path>
+Tests passing (<N> tests, 0 failures)
+Ready to implement <feature-name>
+```
+
+## Quick Reference
+
+| Situation | Action |
+|-----------|--------|
+| Already in linked worktree | Skip creation (Step 0) |
+| In a submodule | Treat as normal repo (Step 0 guard) |
+| Native worktree tool available | Use it (Step 1a) |
+| No native tool | Git worktree fallback (Step 1b) |
+| `.worktrees/` exists | Use it (verify ignored) |
+| `worktrees/` exists | Use it (verify ignored) |
+| Both exist | Use `.worktrees/` |
+| Neither exists | Check instruction file, then default `.worktrees/` |
+| Directory not ignored | Add to .gitignore + commit |
+| Permission error on create | Sandbox fallback, work in place |
+| Tests fail during baseline | Report failures + ask |
+| No package.json/Cargo.toml | Skip dependency install |
+
+## Common Mistakes
+
+### Fighting the harness
+
+- **Problem:** Using `git worktree add` when the platform already provides isolation
+- **Fix:** Step 0 detects existing isolation. Step 1a defers to native tools.
+
+### Skipping detection
+
+- **Problem:** Creating a nested worktree inside an existing one
+- **Fix:** Always run Step 0 before creating anything
+
+### Skipping ignore verification
+
+- **Problem:** Worktree contents get tracked, pollute git status
+- **Fix:** Always use `git check-ignore` before creating project-local worktree
+
+### Assuming directory location
+
+- **Problem:** Creates inconsistency, violates project conventions
+- **Fix:** Follow priority: explicit instructions > existing project-local directory > default
+
+### Proceeding with failing tests
+
+- **Problem:** Can't distinguish new bugs from pre-existing issues
+- **Fix:** Report failures, get explicit permission to proceed
+
+## Red Flags
+
+**Never:**
+- Create a worktree when Step 0 detects existing isolation
+- Use `git worktree add` when you have a native worktree tool (e.g., `EnterWorktree`). This is the #1 mistake — if you have it, use it.
+- Skip Step 1a by jumping straight to Step 1b's git commands
+- Create worktree without verifying it's ignored (project-local)
+- Skip baseline test verification
+- Proceed with failing tests without asking
+
+**Always:**
+- Run Step 0 detection first
+- Prefer native tools over git fallback
+- Follow directory priority: explicit instructions > existing project-local directory > default
+- Verify directory is ignored for project-local
+- Auto-detect and run project setup
+- Verify clean test baseline
diff --git a/.agents/skills/using-superpowers/SKILL.md b/.agents/skills/using-superpowers/SKILL.md
new file mode 100644
index 0000000..8a08873
--- /dev/null
+++ b/.agents/skills/using-superpowers/SKILL.md
@@ -0,0 +1,62 @@
+---
+name: using-superpowers
+description: Use when starting any conversation - establishes how to find and use skills, requiring skill invocation before ANY response including clarifying questions
+---
+
+<SUBAGENT-STOP>
+If you were dispatched as a subagent to execute a specific task, ignore this skill.
+</SUBAGENT-STOP>
+
+<EXTREMELY-IMPORTANT>
+If you think there is even a 1% chance a skill might apply to what you are doing, you ABSOLUTELY MUST invoke the skill.
+
+IF A SKILL APPLIES TO YOUR TASK, YOU DO NOT HAVE A CHOICE. YOU MUST USE IT.
+
+This is not negotiable. You cannot rationalize your way out of this.
+</EXTREMELY-IMPORTANT>
+
+## The Rule
+
+**Invoke relevant or requested skills BEFORE any response or action** — including clarifying questions, exploring the codebase, or checking files. If it turns out wrong for the situation, you don't have to use it.
+
+**Before entering plan mode:** if you haven't already brainstormed, invoke the brainstorming skill first.
+
+Then announce "Using [skill] to [purpose]" and follow the skill exactly. If it has a checklist, create a todo per item.
+
+## Skill Priority
+
+When multiple skills apply, process skills come first — they set the approach, then implementation skills (frontend-design, etc.) carry it out. Brainstorming and systematic-debugging are Superpowers' most common process skills, but the rule holds for any of them.
+
+- "Let's build X" → superpowers:brainstorming first, then implementation skills.
+- "Fix this bug" → superpowers:systematic-debugging first, then domain skills.
+
+## Red Flags
+
+These thoughts mean STOP—you're rationalizing:
+
+| Thought | Reality |
+|---------|---------|
+| "This is just a simple question" | Questions are tasks. Check for skills. |
+| "I need more context first" | Skill check comes BEFORE clarifying questions. |
+| "Let me explore the codebase first" | Skills tell you HOW to explore. Check first. |
+| "I can check git/files quickly" | Files lack conversation context. Check for skills. |
+| "Let me gather information first" | Skills tell you HOW to gather information. |
+| "This doesn't need a formal skill" | If a skill exists, use it. |
+| "I remember this skill" | Skills evolve. Read current version. |
+| "This doesn't count as a task" | Action = task. Check for skills. |
+| "The skill is overkill" | Simple things become complex. Use it. |
+| "I'll just do this one thing first" | Check BEFORE doing anything. |
+| "This feels productive" | Undisciplined action wastes time. Skills prevent this. |
+| "I know what that means" | Knowing the concept ≠ using the skill. Invoke it. |
+
+## Platform Adaptation
+
+If your harness appears here, read its reference file for special instructions:
+
+- Codex: `references/codex-tools.md`
+- Pi: `references/pi-tools.md`
+- Antigravity: `references/antigravity-tools.md`
+
+## User Instructions
+
+User instructions (CLAUDE.md, AGENTS.md, GEMINI.md, etc, direct requests) take precedence over skills, which in turn override default behavior. Only skip skill workflows or instructions when your human partner has explicitly told you to.
diff --git a/.agents/skills/using-superpowers/references/antigravity-tools.md b/.agents/skills/using-superpowers/references/antigravity-tools.md
new file mode 100644
index 0000000..71155fd
--- /dev/null
+++ b/.agents/skills/using-superpowers/references/antigravity-tools.md
@@ -0,0 +1,23 @@
+# Antigravity CLI (`agy`) Tool Mapping
+
+Skills speak in actions ("dispatch a subagent", "create a todo", "read a file"). On the Antigravity CLI (`agy`) these resolve to the tools below.
+
+| Action skills request | Antigravity CLI equivalent |
+|----------------------|----------------------|
+| Dispatch a subagent (`Subagent (general-purpose):` template) | `invoke_subagent` with a built-in `TypeName` — `self` for full-capability work, `research` for read-only (see [Subagent support](#subagent-support)) |
+| Task tracking ("create a todo", "mark complete") | a **task artifact** — `write_to_file` with `IsArtifact: true` and `ArtifactType: "task"` (see [Task tracking](#task-tracking)). **Not** `manage_task`, which manages background processes. |
+
+## Task tracking
+
+Antigravity has **no todo tool** (`manage_task` manages background
+processes — `list`/`kill`/`status`/`send_input` — it is *not* a checklist). When a
+skill says to create a todo list or track tasks, maintain a **task artifact**: a
+markdown checklist saved with `write_to_file` (`IsArtifact: true`,
+`ArtifactMetadata.ArtifactType: "task"`), edited with `replace_file_content` /
+`multi_replace_file_content` as you go.
+
+At the start of any multi-step task, create the task artifact listing every step of
+your plan. As you complete each step, edit the artifact to mark it done (`- [x]`).
+If the plan changes, update the checklist. Keep it current — it is your source of
+truth for what remains; once the conversation gets long, re-read it before starting
+each step.
diff --git a/.agents/skills/using-superpowers/references/codex-tools.md b/.agents/skills/using-superpowers/references/codex-tools.md
new file mode 100644
index 0000000..1897cc3
--- /dev/null
+++ b/.agents/skills/using-superpowers/references/codex-tools.md
@@ -0,0 +1,39 @@
+## Subagent dispatch requires multi-agent support
+
+Add to your Codex config (`~/.codex/config.toml`):
+
+```toml
+[features]
+multi_agent = true
+```
+
+This enables `spawn_agent`, `wait_agent`, and `close_agent` for skills like `dispatching-parallel-agents` and `subagent-driven-development`. When using subagent-driven-development, you should always close implementer and reviewer subagents when they have finished all their work.
+
+## Environment Detection
+
+Skills that create worktrees or finish branches should detect their
+environment with read-only git commands before proceeding:
+
+```bash
+GIT_DIR=$(cd "$(git rev-parse --git-dir)" 2>/dev/null && pwd -P)
+GIT_COMMON=$(cd "$(git rev-parse --git-common-dir)" 2>/dev/null && pwd -P)
+BRANCH=$(git branch --show-current)
+```
+
+- `GIT_DIR != GIT_COMMON` → already in a linked worktree (skip creation)
+- `BRANCH` empty → detached HEAD (cannot branch/push/PR from sandbox)
+
+See `using-git-worktrees` Step 0 and `finishing-a-development-branch`
+Step 1 for how each skill uses these signals.
+
+## Codex App Finishing
+
+When the sandbox blocks branch/push operations (detached HEAD in an
+externally managed worktree), the agent commits all work and informs
+the user to use the App's native controls:
+
+- **"Create branch"** — names the branch, then commit/push/PR via App UI
+- **"Hand off to local"** — transfers work to the user's local checkout
+
+The agent can still run tests, stage files, and output suggested branch
+names, commit messages, and PR descriptions for the user to copy.
diff --git a/.agents/skills/using-superpowers/references/pi-tools.md b/.agents/skills/using-superpowers/references/pi-tools.md
new file mode 100644
index 0000000..0c1f217
--- /dev/null
+++ b/.agents/skills/using-superpowers/references/pi-tools.md
@@ -0,0 +1,16 @@
+# Pi Tool Mapping
+
+Skills speak in actions ("dispatch a subagent", "create a todo", "read a file"). On Pi these resolve to the tools below.
+
+| Action skills request | Pi equivalent |
+| --- | --- |
+| Dispatch a subagent (`Subagent (general-purpose):` template) | Use an installed subagent tool such as `subagent` from `pi-subagents` if available |
+| Task tracking ("create a todo", "mark complete") | Use an installed todo/task tool if available, otherwise track tasks in the plan or `TODO.md` |
+
+## Subagents
+
+Pi core does not ship a standard subagent tool. The `pi-subagents` package is a strong optional companion and provides a `subagent` tool with single-agent, chain, parallel, async, forked-context, and resume/status workflows. If no subagent tool is available, do not fabricate `Task` calls; execute sequentially in the current session or explain that the optional subagent capability is not installed.
+
+## Task lists
+
+Pi core does not ship a standard task-list tool. If a todo/task extension is installed, use its documented tool. Otherwise use Superpowers plan files, checklists in Markdown, or a repo-local `TODO.md` for task tracking. Older Superpowers docs may refer to `TodoWrite`; treat that as the task-tracking action above.
diff --git a/.agents/skills/verification-before-completion/SKILL.md b/.agents/skills/verification-before-completion/SKILL.md
new file mode 100644
index 0000000..2f14076
--- /dev/null
+++ b/.agents/skills/verification-before-completion/SKILL.md
@@ -0,0 +1,139 @@
+---
+name: verification-before-completion
+description: Use when about to claim work is complete, fixed, or passing, before committing or creating PRs - requires running verification commands and confirming output before making any success claims; evidence before assertions always
+---
+
+# Verification Before Completion
+
+## Overview
+
+Claiming work is complete without verification is dishonesty, not efficiency.
+
+**Core principle:** Evidence before claims, always.
+
+**Violating the letter of this rule is violating the spirit of this rule.**
+
+## The Iron Law
+
+```
+NO COMPLETION CLAIMS WITHOUT FRESH VERIFICATION EVIDENCE
+```
+
+If you haven't run the verification command in this message, you cannot claim it passes.
+
+## The Gate Function
+
+```
+BEFORE claiming any status or expressing satisfaction:
+
+1. IDENTIFY: What command proves this claim?
+2. RUN: Execute the FULL command (fresh, complete)
+3. READ: Full output, check exit code, count failures
+4. VERIFY: Does output confirm the claim?
+   - If NO: State actual status with evidence
+   - If YES: State claim WITH evidence
+5. ONLY THEN: Make the claim
+
+Skip any step = lying, not verifying
+```
+
+## Common Failures
+
+| Claim | Requires | Not Sufficient |
+|-------|----------|----------------|
+| Tests pass | Test command output: 0 failures | Previous run, "should pass" |
+| Linter clean | Linter output: 0 errors | Partial check, extrapolation |
+| Build succeeds | Build command: exit 0 | Linter passing, logs look good |
+| Bug fixed | Test original symptom: passes | Code changed, assumed fixed |
+| Regression test works | Red-green cycle verified | Test passes once |
+| Agent completed | VCS diff shows changes | Agent reports "success" |
+| Requirements met | Line-by-line checklist | Tests passing |
+
+## Red Flags - STOP
+
+- Using "should", "probably", "seems to"
+- Expressing satisfaction before verification ("Great!", "Perfect!", "Done!", etc.)
+- About to commit/push/PR without verification
+- Trusting agent success reports
+- Relying on partial verification
+- Thinking "just this once"
+- Tired and wanting work over
+- **ANY wording implying success without having run verification**
+
+## Rationalization Prevention
+
+| Excuse | Reality |
+|--------|---------|
+| "Should work now" | RUN the verification |
+| "I'm confident" | Confidence ≠ evidence |
+| "Just this once" | No exceptions |
+| "Linter passed" | Linter ≠ compiler |
+| "Agent said success" | Verify independently |
+| "I'm tired" | Exhaustion ≠ excuse |
+| "Partial check is enough" | Partial proves nothing |
+| "Different words so rule doesn't apply" | Spirit over letter |
+
+## Key Patterns
+
+**Tests:**
+```
+✅ [Run test command] [See: 34/34 pass] "All tests pass"
+❌ "Should pass now" / "Looks correct"
+```
+
+**Regression tests (TDD Red-Green):**
+```
+✅ Write → Run (pass) → Revert fix → Run (MUST FAIL) → Restore → Run (pass)
+❌ "I've written a regression test" (without red-green verification)
+```
+
+**Build:**
+```
+✅ [Run build] [See: exit 0] "Build passes"
+❌ "Linter passed" (linter doesn't check compilation)
+```
+
+**Requirements:**
+```
+✅ Re-read plan → Create checklist → Verify each → Report gaps or completion
+❌ "Tests pass, phase complete"
+```
+
+**Agent delegation:**
+```
+✅ Agent reports success → Check VCS diff → Verify changes → Report actual state
+❌ Trust agent report
+```
+
+## Why This Matters
+
+From 24 failure memories:
+- your human partner said "I don't believe you" - trust broken
+- Undefined functions shipped - would crash
+- Missing requirements shipped - incomplete features
+- Time wasted on false completion → redirect → rework
+- Violates: "Honesty is a core value. If you lie, you'll be replaced."
+
+## When To Apply
+
+**ALWAYS before:**
+- ANY variation of success/completion claims
+- ANY expression of satisfaction
+- ANY positive statement about work state
+- Committing, PR creation, task completion
+- Moving to next task
+- Delegating to agents
+
+**Rule applies to:**
+- Exact phrases
+- Paraphrases and synonyms
+- Implications of success
+- ANY communication suggesting completion/correctness
+
+## The Bottom Line
+
+**No shortcuts for verification.**
+
+Run the command. Read the output. THEN claim the result.
+
+This is non-negotiable.
diff --git a/.agents/skills/writing-plans/SKILL.md b/.agents/skills/writing-plans/SKILL.md
new file mode 100644
index 0000000..b1613eb
--- /dev/null
+++ b/.agents/skills/writing-plans/SKILL.md
@@ -0,0 +1,174 @@
+---
+name: writing-plans
+description: Use when you have a spec or requirements for a multi-step task, before touching code
+---
+
+# Writing Plans
+
+## Overview
+
+Write comprehensive implementation plans assuming the engineer has zero context for our codebase and questionable taste. Document everything they need to know: which files to touch for each task, code, testing, docs they might need to check, how to test it. Give them the whole plan as bite-sized tasks. DRY. YAGNI. TDD. Frequent commits.
+
+Assume they are a skilled developer, but know almost nothing about our toolset or problem domain. Assume they don't know good test design very well.
+
+**Announce at start:** "I'm using the writing-plans skill to create the implementation plan."
+
+**Context:** If working in an isolated worktree, it should have been created via the `superpowers:using-git-worktrees` skill at execution time.
+
+**Save plans to:** `docs/superpowers/plans/YYYY-MM-DD-<feature-name>.md`
+- (User preferences for plan location override this default)
+
+## Scope Check
+
+If the spec covers multiple independent subsystems, it should have been broken into sub-project specs during brainstorming. If it wasn't, suggest breaking this into separate plans — one per subsystem. Each plan should produce working, testable software on its own.
+
+## File Structure
+
+Before defining tasks, map out which files will be created or modified and what each one is responsible for. This is where decomposition decisions get locked in.
+
+- Design units with clear boundaries and well-defined interfaces. Each file should have one clear responsibility.
+- You reason best about code you can hold in context at once, and your edits are more reliable when files are focused. Prefer smaller, focused files over large ones that do too much.
+- Files that change together should live together. Split by responsibility, not by technical layer.
+- In existing codebases, follow established patterns. If the codebase uses large files, don't unilaterally restructure - but if a file you're modifying has grown unwieldy, including a split in the plan is reasonable.
+
+This structure informs the task decomposition. Each task should produce self-contained changes that make sense independently.
+
+## Task Right-Sizing
+
+A task is the smallest unit that carries its own test cycle and is worth a
+fresh reviewer's gate. When drawing task boundaries: fold setup,
+configuration, scaffolding, and documentation steps into the task whose
+deliverable needs them; split only where a reviewer could meaningfully
+reject one task while approving its neighbor. Each task ends with an
+independently testable deliverable.
+
+## Bite-Sized Task Granularity
+
+**Each step is one action (2-5 minutes):**
+- "Write the failing test" - step
+- "Run it to make sure it fails" - step
+- "Implement the minimal code to make the test pass" - step
+- "Run the tests and make sure they pass" - step
+- "Commit" - step
+
+## Plan Document Header
+
+**Every plan MUST start with this header:**
+
+```markdown
+# [Feature Name] Implementation Plan
+
+> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.
+
+**Goal:** [One sentence describing what this builds]
+
+**Architecture:** [2-3 sentences about approach]
+
+**Tech Stack:** [Key technologies/libraries]
+
+## Global Constraints
+
+[The spec's project-wide requirements — version floors, dependency limits,
+naming and copy rules, platform requirements — one line each, with exact
+values copied verbatim from the spec. Every task's requirements implicitly
+include this section.]
+
+---
+```
+
+## Task Structure
+
+````markdown
+### Task N: [Component Name]
+
+**Files:**
+- Create: `exact/path/to/file.py`
+- Modify: `exact/path/to/existing.py:123-145`
+- Test: `tests/exact/path/to/test.py`
+
+**Interfaces:**
+- Consumes: [what this task uses from earlier tasks — exact signatures]
+- Produces: [what later tasks rely on — exact function names, parameter
+  and return types. A task's implementer sees only their own task; this
+  block is how they learn the names and types neighboring tasks use.]
+
+- [ ] **Step 1: Write the failing test**
+
+```python
+def test_specific_behavior():
+    result = function(input)
+    assert result == expected
+```
+
+- [ ] **Step 2: Run test to verify it fails**
+
+Run: `pytest tests/path/test.py::test_name -v`
+Expected: FAIL with "function not defined"
+
+- [ ] **Step 3: Write minimal implementation**
+
+```python
+def function(input):
+    return expected
+```
+
+- [ ] **Step 4: Run test to verify it passes**
+
+Run: `pytest tests/path/test.py::test_name -v`
+Expected: PASS
+
+- [ ] **Step 5: Commit**
+
+```bash
+git add tests/path/test.py src/path/file.py
+git commit -m "feat: add specific feature"
+```
+````
+
+## No Placeholders
+
+Every step must contain the actual content an engineer needs. These are **plan failures** — never write them:
+- "TBD", "TODO", "implement later", "fill in details"
+- "Add appropriate error handling" / "add validation" / "handle edge cases"
+- "Write tests for the above" (without actual test code)
+- "Similar to Task N" (repeat the code — the engineer may be reading tasks out of order)
+- Steps that describe what to do without showing how (code blocks required for code steps)
+- References to types, functions, or methods not defined in any task
+
+## Remember
+- Exact file paths always
+- Complete code in every step — if a step changes code, show the code
+- Exact commands with expected output
+- DRY, YAGNI, TDD, frequent commits
+
+## Self-Review
+
+After writing the complete plan, look at the spec with fresh eyes and check the plan against it. This is a checklist you run yourself — not a subagent dispatch.
+
+**1. Spec coverage:** Skim each section/requirement in the spec. Can you point to a task that implements it? List any gaps.
+
+**2. Placeholder scan:** Search your plan for red flags — any of the patterns from the "No Placeholders" section above. Fix them.
+
+**3. Type consistency:** Do the types, method signatures, and property names you used in later tasks match what you defined in earlier tasks? A function called `clearLayers()` in Task 3 but `clearFullLayers()` in Task 7 is a bug.
+
+If you find issues, fix them inline. No need to re-review — just fix and move on. If you find a spec requirement with no task, add the task.
+
+## Execution Handoff
+
+After saving the plan, offer execution choice:
+
+**"Plan complete and saved to `docs/superpowers/plans/<filename>.md`. Two execution options:**
+
+**1. Subagent-Driven (recommended)** - I dispatch a fresh subagent per task, review between tasks, fast iteration
+
+**2. Inline Execution** - Execute tasks in this session using executing-plans, batch execution with checkpoints
+
+**Which approach?"**
+
+**If Subagent-Driven chosen:**
+- **REQUIRED SUB-SKILL:** Use superpowers:subagent-driven-development
+- Fresh subagent per task + two-stage review
+
+**If Inline Execution chosen:**
+- **REQUIRED SUB-SKILL:** Use superpowers:executing-plans
+- Batch execution with checkpoints for review
diff --git a/.agents/skills/writing-plans/plan-document-reviewer-prompt.md b/.agents/skills/writing-plans/plan-document-reviewer-prompt.md
new file mode 100644
index 0000000..1c12c1d
--- /dev/null
+++ b/.agents/skills/writing-plans/plan-document-reviewer-prompt.md
@@ -0,0 +1,49 @@
+# Plan Document Reviewer Prompt Template
+
+Use this template when dispatching a plan document reviewer subagent.
+
+**Purpose:** Verify the plan is complete, matches the spec, and has proper task decomposition.
+
+**Dispatch after:** The complete plan is written.
+
+```
+Subagent (general-purpose):
+  description: "Review plan document"
+  prompt: |
+    You are a plan document reviewer. Verify this plan is complete and ready for implementation.
+
+    **Plan to review:** [PLAN_FILE_PATH]
+    **Spec for reference:** [SPEC_FILE_PATH]
+
+    ## What to Check
+
+    | Category | What to Look For |
+    |----------|------------------|
+    | Completeness | TODOs, placeholders, incomplete tasks, missing steps |
+    | Spec Alignment | Plan covers spec requirements, no major scope creep |
+    | Task Decomposition | Tasks have clear boundaries, steps are actionable |
+    | Buildability | Could an engineer follow this plan without getting stuck? |
+
+    ## Calibration
+
+    **Only flag issues that would cause real problems during implementation.**
+    An implementer building the wrong thing or getting stuck is an issue.
+    Minor wording, stylistic preferences, and "nice to have" suggestions are not.
+
+    Approve unless there are serious gaps — missing requirements from the spec,
+    contradictory steps, placeholder content, or tasks so vague they can't be acted on.
+
+    ## Output Format
+
+    ## Plan Review
+
+    **Status:** Approved | Issues Found
+
+    **Issues (if any):**
+    - [Task X, Step Y]: [specific issue] - [why it matters for implementation]
+
+    **Recommendations (advisory, do not block approval):**
+    - [suggestions for improvement]
+```
+
+**Reviewer returns:** Status, Issues (if any), Recommendations
diff --git a/.agents/skills/writing-skills/SKILL.md b/.agents/skills/writing-skills/SKILL.md
new file mode 100644
index 0000000..6d3ded6
--- /dev/null
+++ b/.agents/skills/writing-skills/SKILL.md
@@ -0,0 +1,689 @@
+---
+name: writing-skills
+description: Use when creating new skills, editing existing skills, or verifying skills work before deployment
+---
+
+# Writing Skills
+
+## Overview
+
+**Writing skills IS Test-Driven Development applied to process documentation.**
+
+**Personal skills live in your runtime's skills directory** 
+
+You write test cases (pressure scenarios with subagents), watch them fail (baseline behavior), write the skill (documentation), watch tests pass (agents comply), and refactor (close loopholes).
+
+**Core principle:** If you didn't watch an agent fail without the skill, you don't know if the skill teaches the right thing.
+
+**REQUIRED BACKGROUND:** You MUST understand superpowers:test-driven-development before using this skill. That skill defines the fundamental RED-GREEN-REFACTOR cycle. This skill adapts TDD to documentation.
+
+**Official guidance:** For Anthropic's official skill authoring best practices, see anthropic-best-practices.md. This document provides additional patterns and guidelines that complement the TDD-focused approach in this skill.
+
+## What is a Skill?
+
+A **skill** is a reference guide for proven techniques, patterns, or tools. Skills help future agents find and apply effective approaches.
+
+**Skills are:** Reusable techniques, patterns, tools, reference guides
+
+**Skills are NOT:** Narratives about how you solved a problem once
+
+## TDD Mapping for Skills
+
+| TDD Concept | Skill Creation |
+|-------------|----------------|
+| **Test case** | Pressure scenario with subagent |
+| **Production code** | Skill document (SKILL.md) |
+| **Test fails (RED)** | Agent violates rule without skill (baseline) |
+| **Test passes (GREEN)** | Agent complies with skill present |
+| **Refactor** | Close loopholes while maintaining compliance |
+| **Write test first** | Run baseline scenario BEFORE writing skill |
+| **Watch it fail** | Document exact rationalizations agent uses |
+| **Minimal code** | Write skill addressing those specific violations |
+| **Watch it pass** | Verify agent now complies |
+| **Refactor cycle** | Find new rationalizations → plug → re-verify |
+
+The entire skill creation process follows RED-GREEN-REFACTOR.
+
+## When to Create a Skill
+
+**Create when:**
+- Technique wasn't intuitively obvious to you
+- You'd reference this again across projects
+- Pattern applies broadly (not project-specific)
+- Others would benefit
+
+**Don't create for:**
+- One-off solutions
+- Standard practices well-documented elsewhere
+- Project-specific conventions (put in your instructions file)
+- Mechanical constraints (if it's enforceable with regex/validation, automate it—save documentation for judgment calls)
+
+## Skill Types
+
+### Technique
+Concrete method with steps to follow (condition-based-waiting, root-cause-tracing)
+
+### Pattern
+Way of thinking about problems (flatten-with-flags, test-invariants)
+
+### Reference
+API docs, syntax guides, tool documentation (office docs)
+
+## Directory Structure
+
+
+```
+skills/
+  skill-name/
+    SKILL.md              # Main reference (required)
+    supporting-file.*     # Only if needed
+```
+
+**Flat namespace** - all skills in one searchable namespace
+
+**Separate files for:**
+1. **Heavy reference** (100+ lines) - API docs, comprehensive syntax
+2. **Reusable tools** - Scripts, utilities, templates
+
+**Keep inline:**
+- Principles and concepts
+- Code patterns (< 50 lines)
+- Everything else
+
+## SKILL.md Structure
+
+**Frontmatter (YAML):**
+- Two required fields: `name` and `description` (see [agentskills.io/specification](https://agentskills.io/specification) for all supported fields)
+- Max 1024 characters total
+- `name`: Use letters, numbers, and hyphens only (no parentheses, special chars)
+- `description`: Third-person, describes ONLY when to use (NOT what it does)
+  - Start with "Use when..." to focus on triggering conditions
+  - Include specific symptoms, situations, and contexts
+  - **NEVER summarize the skill's process or workflow** (see SDO section for why)
+  - Keep under 500 characters if possible
+
+```markdown
+---
+name: Skill-Name-With-Hyphens
+description: Use when [specific triggering conditions and symptoms]
+---
+
+# Skill Name
+
+## Overview
+What is this? Core principle in 1-2 sentences.
+
+## When to Use
+[Small inline flowchart IF decision non-obvious]
+
+Bullet list with SYMPTOMS and use cases
+When NOT to use
+
+## Core Pattern (for techniques/patterns)
+Before/after code comparison
+
+## Quick Reference
+Table or bullets for scanning common operations
+
+## Implementation
+Inline code for simple patterns
+Link to file for heavy reference or reusable tools
+
+## Common Mistakes
+What goes wrong + fixes
+
+## Real-World Impact (optional)
+Concrete results
+```
+
+
+## Skill Discovery Optimization (SDO)
+
+**Critical for discovery:** Future agents need to FIND your skill
+
+### 1. Rich Description Field
+
+**Purpose:** Your agent reads the description to decide which skills to load for a given task. Make it answer: "Should I read this skill right now?"
+
+**Format:** Start with "Use when..." to focus on triggering conditions
+
+**CRITICAL: Description = When to Use, NOT What the Skill Does**
+
+The description should ONLY describe triggering conditions. Do NOT summarize the skill's process or workflow in the description.
+
+**Why this matters:** Testing revealed that when a description summarizes the skill's workflow, an agent may follow the description instead of reading the full skill content. A description saying "code review between tasks" caused an agent to do ONE review, even though the skill's flowchart clearly showed TWO reviews (spec compliance then code quality).
+
+When the description was changed to just "Use when executing implementation plans with independent tasks" (no workflow summary), the agent correctly read the flowchart and followed the two-stage review process.
+
+**The trap:** Descriptions that summarize workflow create a shortcut agents will take. The skill body becomes documentation agents skip.
+
+```yaml
+# ❌ BAD: Summarizes workflow - agents may follow this instead of reading skill
+description: Use when executing plans - dispatches subagent per task with code review between tasks
+
+# ❌ BAD: Too much process detail
+description: Use for TDD - write test first, watch it fail, write minimal code, refactor
+
+# ✅ GOOD: Just triggering conditions, no workflow summary
+description: Use when executing implementation plans with independent tasks in the current session
+
+# ✅ GOOD: Triggering conditions only
+description: Use when implementing any feature or bugfix, before writing implementation code
+```
+
+**Content:**
+- Use concrete triggers, symptoms, and situations that signal this skill applies
+- Describe the *problem* (race conditions, inconsistent behavior) not *language-specific symptoms* (setTimeout, sleep)
+- Keep triggers technology-agnostic unless the skill itself is technology-specific
+- If skill is technology-specific, make that explicit in the trigger
+- Write in third person (injected into system prompt)
+- **NEVER summarize the skill's process or workflow**
+
+```yaml
+# ❌ BAD: Too abstract, vague, doesn't include when to use
+description: For async testing
+
+# ❌ BAD: First person
+description: I can help you with async tests when they're flaky
+
+# ❌ BAD: Mentions technology but skill isn't specific to it
+description: Use when tests use setTimeout/sleep and are flaky
+
+# ✅ GOOD: Starts with "Use when", describes problem, no workflow
+description: Use when tests have race conditions, timing dependencies, or pass/fail inconsistently
+
+# ✅ GOOD: Technology-specific skill with explicit trigger
+description: Use when using React Router and handling authentication redirects
+```
+
+### 2. Keyword Coverage
+
+Use words an agent would search for:
+- Error messages: "Hook timed out", "ENOTEMPTY", "race condition"
+- Symptoms: "flaky", "hanging", "zombie", "pollution"
+- Synonyms: "timeout/hang/freeze", "cleanup/teardown/afterEach"
+- Tools: Actual commands, library names, file types
+
+### 3. Descriptive Naming
+
+**Use active voice, verb-first:**
+- ✅ `creating-skills` not `skill-creation`
+- ✅ `condition-based-waiting` not `async-test-helpers`
+
+### 4. Token Efficiency (Critical)
+
+**Problem:** getting-started and frequently-referenced skills load into EVERY conversation. Every token counts.
+
+**Target word counts:**
+- getting-started workflows: <150 words each
+- Frequently-loaded skills: <200 words total
+- Other skills: <500 words (still be concise)
+
+**Techniques:**
+
+**Move details to tool help:**
+```bash
+# ❌ BAD: Document all flags in SKILL.md
+search-conversations supports --text, --both, --after DATE, --before DATE, --limit N
+
+# ✅ GOOD: Reference --help
+search-conversations supports multiple modes and filters. Run --help for details.
+```
+
+**Use cross-references:**
+```markdown
+# ❌ BAD: Repeat workflow details
+When searching, dispatch subagent with template...
+[20 lines of repeated instructions]
+
+# ✅ GOOD: Reference other skill
+Always use subagents (50-100x context savings). REQUIRED: Use [other-skill-name] for workflow.
+```
+
+**Compress examples:**
+```markdown
+# ❌ BAD: Verbose example (42 words)
+your human partner: "How did we handle authentication errors in React Router before?"
+You: I'll search past conversations for React Router authentication patterns.
+[Dispatch subagent with search query: "React Router authentication error handling 401"]
+
+# ✅ GOOD: Minimal example (20 words)
+Partner: "How did we handle auth errors in React Router?"
+You: Searching...
+[Dispatch subagent → synthesis]
+```
+
+**Eliminate redundancy:**
+- Don't repeat what's in cross-referenced skills
+- Don't explain what's obvious from command
+- Don't include multiple examples of same pattern
+
+**Verification:**
+```bash
+wc -w skills/path/SKILL.md
+# getting-started workflows: aim for <150 each
+# Other frequently-loaded: aim for <200 total
+```
+
+**Name by what you DO or core insight:**
+- ✅ `condition-based-waiting` > `async-test-helpers`
+- ✅ `using-skills` not `skill-usage`
+- ✅ `flatten-with-flags` > `data-structure-refactoring`
+- ✅ `root-cause-tracing` > `debugging-techniques`
+
+**Gerunds (-ing) work well for processes:**
+- `creating-skills`, `testing-skills`, `debugging-with-logs`
+- Active, describes the action you're taking
+
+### 5. Cross-Referencing Other Skills
+
+**When writing documentation that references other skills:**
+
+Use skill name only, with explicit requirement markers:
+- ✅ Good: `**REQUIRED SUB-SKILL:** Use superpowers:test-driven-development`
+- ✅ Good: `**REQUIRED BACKGROUND:** You MUST understand superpowers:systematic-debugging`
+- ❌ Bad: `See skills/testing/test-driven-development` (unclear if required)
+- ❌ Bad: `@skills/testing/test-driven-development/SKILL.md` (force-loads, burns context)
+
+**Why no @ links:** `@` syntax force-loads files immediately, consuming 200k+ context before you need them.
+
+## Flowchart Usage
+
+```dot
+digraph when_flowchart {
+    "Need to show information?" [shape=diamond];
+    "Decision where I might go wrong?" [shape=diamond];
+    "Use markdown" [shape=box];
+    "Small inline flowchart" [shape=box];
+
+    "Need to show information?" -> "Decision where I might go wrong?" [label="yes"];
+    "Decision where I might go wrong?" -> "Small inline flowchart" [label="yes"];
+    "Decision where I might go wrong?" -> "Use markdown" [label="no"];
+}
+```
+
+**Use flowcharts ONLY for:**
+- Non-obvious decision points
+- Process loops where you might stop too early
+- "When to use A vs B" decisions
+
+**Never use flowcharts for:**
+- Reference material → Tables, lists
+- Code examples → Markdown blocks
+- Linear instructions → Numbered lists
+- Labels without semantic meaning (step1, helper2)
+
+See `graphviz-conventions.dot` in this directory for graphviz style rules.
+
+**Visualizing for your human partner:** Use `render-graphs.js` in this directory to render a skill's flowcharts to SVG:
+```bash
+./render-graphs.js ../some-skill           # Each diagram separately
+./render-graphs.js ../some-skill --combine # All diagrams in one SVG
+```
+
+## Code Examples
+
+**One excellent example beats many mediocre ones**
+
+Choose most relevant language:
+- Testing techniques → TypeScript/JavaScript
+- System debugging → Shell/Python
+- Data processing → Python
+
+**Good example:**
+- Complete and runnable
+- Well-commented explaining WHY
+- From real scenario
+- Shows pattern clearly
+- Ready to adapt (not generic template)
+
+**Don't:**
+- Implement in 5+ languages
+- Create fill-in-the-blank templates
+- Write contrived examples
+
+You're good at porting - one great example is enough.
+
+## File Organization
+
+### Self-Contained Skill
+```
+defense-in-depth/
+  SKILL.md    # Everything inline
+```
+When: All content fits, no heavy reference needed
+
+### Skill with Reusable Tool
+```
+condition-based-waiting/
+  SKILL.md    # Overview + patterns
+  example.ts  # Working helpers to adapt
+```
+When: Tool is reusable code, not just narrative
+
+### Skill with Heavy Reference
+```
+pptx/
+  SKILL.md       # Overview + workflows
+  pptxgenjs.md   # 600 lines API reference
+  ooxml.md       # 500 lines XML structure
+  scripts/       # Executable tools
+```
+When: Reference material too large for inline
+
+## The Iron Law (Same as TDD)
+
+```
+NO SKILL WITHOUT A FAILING TEST FIRST
+```
+
+This applies to NEW skills AND EDITS to existing skills.
+
+Write skill before testing? Delete it. Start over.
+Edit skill without testing? Same violation.
+
+**No exceptions:**
+- Not for "simple additions"
+- Not for "just adding a section"
+- Not for "documentation updates"
+- Don't keep untested changes as "reference"
+- Don't "adapt" while running tests
+- Delete means delete
+
+**REQUIRED BACKGROUND:** The superpowers:test-driven-development skill explains why this matters. Same principles apply to documentation.
+
+## Testing All Skill Types
+
+Different skill types need different test approaches:
+
+### Discipline-Enforcing Skills (rules/requirements)
+
+**Examples:** TDD, verification-before-completion, designing-before-coding
+
+**Test with:**
+- Academic questions: Do they understand the rules?
+- Pressure scenarios: Do they comply under stress?
+- Multiple pressures combined: time + sunk cost + exhaustion
+- Identify rationalizations and add explicit counters
+
+**Success criteria:** Agent follows rule under maximum pressure
+
+### Technique Skills (how-to guides)
+
+**Examples:** condition-based-waiting, root-cause-tracing, defensive-programming
+
+**Test with:**
+- Application scenarios: Can they apply the technique correctly?
+- Variation scenarios: Do they handle edge cases?
+- Missing information tests: Do instructions have gaps?
+
+**Success criteria:** Agent successfully applies technique to new scenario
+
+### Pattern Skills (mental models)
+
+**Examples:** reducing-complexity, information-hiding concepts
+
+**Test with:**
+- Recognition scenarios: Do they recognize when pattern applies?
+- Application scenarios: Can they use the mental model?
+- Counter-examples: Do they know when NOT to apply?
+
+**Success criteria:** Agent correctly identifies when/how to apply pattern
+
+### Reference Skills (documentation/APIs)
+
+**Examples:** API documentation, command references, library guides
+
+**Test with:**
+- Retrieval scenarios: Can they find the right information?
+- Application scenarios: Can they use what they found correctly?
+- Gap testing: Are common use cases covered?
+
+**Success criteria:** Agent finds and correctly applies reference information
+
+## Common Rationalizations for Skipping Testing
+
+| Excuse | Reality |
+|--------|---------|
+| "Skill is obviously clear" | Clear to you ≠ clear to other agents. Test it. |
+| "It's just a reference" | References can have gaps, unclear sections. Test retrieval. |
+| "Testing is overkill" | Untested skills have issues. Always. 15 min testing saves hours. |
+| "I'll test if problems emerge" | Problems = agents can't use skill. Test BEFORE deploying. |
+| "Too tedious to test" | Testing is less tedious than debugging bad skill in production. |
+| "I'm confident it's good" | Overconfidence guarantees issues. Test anyway. |
+| "Academic review is enough" | Reading ≠ using. Test application scenarios. |
+| "No time to test" | Deploying untested skill wastes more time fixing it later. |
+
+**All of these mean: Test before deploying. No exceptions.**
+
+## Match the Form to the Failure
+
+Before writing guidance, classify the baseline failure. The form that bulletproofs one failure type measurably backfires on another.
+
+| Baseline failure | Right form | Wrong form |
+|---|---|---|
+| Skips/violates a rule under pressure (knows better, does it anyway) | Prohibition + rationalization table + red flags (see Bulletproofing below) | Soft guidance ("prefer...", "consider...") |
+| Complies, but output has the wrong shape (bloated prompt, buried verdict, restated spec) | Positive recipe or contract: state what the output IS — its parts, in order | Prohibition list ("don't restate", "never narrate") |
+| Omits a required element from something they already produce | Structural: REQUIRED field or slot in the template they fill in | Prose reminders near the template |
+| Behavior should depend on a condition | Conditional keyed to an observable predicate ("if the brief exists, reference it") | Unconditional rule + exemption clauses |
+
+**Why prohibitions backfire on shaping problems:** under a competing incentive ("make the prompt self-contained"), agents negotiate with "don't X". In head-to-head wording tests on dispatch-prompt guidance, the prohibition arm produced clearly more of the unwanted content than the recipe arm (fully separated distributions), and trended worse than even the no-guidance control — micro-test your own case rather than assuming, but never reach for the prohibition by default. A recipe leaves nothing to negotiate: the output matches the stated shape or it doesn't.
+
+**Rules for whichever form you pick:**
+- **No nuance clauses.** "Don't X unless it matters" reopens the negotiation — appending a single nuance clause to a winning recipe degraded it from consistent to noisy in the same wording tests. Express a real exception as its own conditional on an observable predicate.
+- **Exemption clauses don't scope.** "This limit doesn't apply to code blocks" still suppresses code blocks. If part of the output must be exempt, restructure so the rule can't reach it.
+
+## Bulletproofing Skills Against Rationalization
+
+Skills that enforce discipline (like TDD) need to resist rationalization. Agents are smart and will find loopholes when under pressure.
+
+**Scope:** this toolkit is for discipline failures — an agent that knows the rule and skips it under pressure. For wrong-shaped output or omitted elements, prohibition-based bulletproofing backfires; use the forms in Match the Form to the Failure instead.
+
+**Psychology note:** Understanding WHY persuasion techniques work helps you apply them systematically. See persuasion-principles.md for research foundation (Cialdini, 2021; Meincke et al., 2025) on authority, commitment, scarcity, social proof, and unity principles.
+
+### Close Every Loophole Explicitly
+
+Don't just state the rule - forbid specific workarounds:
+
+<Bad>
+```markdown
+Write code before test? Delete it.
+```
+</Bad>
+
+<Good>
+```markdown
+Write code before test? Delete it. Start over.
+
+**No exceptions:**
+- Don't keep it as "reference"
+- Don't "adapt" it while writing tests
+- Don't look at it
+- Delete means delete
+```
+</Good>
+
+### Address "Spirit vs Letter" Arguments
+
+Add foundational principle early:
+
+```markdown
+**Violating the letter of the rules is violating the spirit of the rules.**
+```
+
+This cuts off entire class of "I'm following the spirit" rationalizations.
+
+### Build Rationalization Table
+
+Capture rationalizations from baseline testing (see Testing section below). Every excuse agents make goes in the table:
+
+```markdown
+| Excuse | Reality |
+|--------|---------|
+| "Too simple to test" | Simple code breaks. Test takes 30 seconds. |
+| "I'll test after" | Tests passing immediately prove nothing. |
+| "Tests after achieve same goals" | Tests-after = "what does this do?" Tests-first = "what should this do?" |
+```
+
+### Create Red Flags List
+
+Make it easy for agents to self-check when rationalizing:
+
+```markdown
+## Red Flags - STOP and Start Over
+
+- Code before test
+- "I already manually tested it"
+- "Tests after achieve the same purpose"
+- "It's about spirit not ritual"
+- "This is different because..."
+
+**All of these mean: Delete code. Start over with TDD.**
+```
+
+### Update SDO for Violation Symptoms
+
+Add to description: symptoms of when you're ABOUT to violate the rule:
+
+```yaml
+description: use when implementing any feature or bugfix, before writing implementation code
+```
+
+## RED-GREEN-REFACTOR for Skills
+
+Follow the TDD cycle:
+
+### RED: Write Failing Test (Baseline)
+
+Run pressure scenario with subagent WITHOUT the skill. Document exact behavior:
+- What choices did they make?
+- What rationalizations did they use (verbatim)?
+- Which pressures triggered violations?
+
+This is "watch the test fail" - you must see what agents naturally do before writing the skill.
+
+### GREEN: Write Minimal Skill
+
+Write skill that addresses those specific rationalizations. Don't add extra content for hypothetical cases.
+
+Run same scenarios WITH skill. Agent should now comply.
+
+### REFACTOR: Close Loopholes
+
+Agent found new rationalization? Add explicit counter. Re-test until bulletproof.
+
+### Micro-Test Wording Before Full Scenarios
+
+Full pressure-scenario runs are the final gate, but they are slow and expensive per iteration. Verify the wording itself first with micro-tests:
+
+1. **One fresh-context sample per call** — a raw API call, or a single-shot subagent if you don't have API access. System prompt = the realistic context the guidance will live in (the full skill or prompt template, not the guidance in isolation); user message = a task that tempts the failure.
+2. **Always include a no-guidance control.** If the control doesn't exhibit the failure, there is nothing to fix — stop, don't author the guidance.
+3. **5+ reps per variant.** Single samples lie.
+4. **Manually read every flagged match.** Score programmatically if you like, but template echoes and quoted counter-examples masquerade as hits; automated counts alone overstate both failure and success.
+5. **Variance is a metric.** When guidance lands, reps converge on the same shape. Five different interpretations across five reps means the wording isn't binding — tighten the form before adding words.
+
+Micro-tests verify wording; they do not replace pressure scenarios for discipline skills.
+
+**Testing methodology:** See [testing-skills-with-subagents.md](testing-skills-with-subagents.md) for the complete testing methodology:
+- How to write pressure scenarios
+- Pressure types (time, sunk cost, authority, exhaustion)
+- Plugging holes systematically
+- Meta-testing techniques
+
+## Anti-Patterns
+
+### ❌ Narrative Example
+"In session 2025-10-03, we found empty projectDir caused..."
+**Why bad:** Too specific, not reusable
+
+### ❌ Multi-Language Dilution
+example-js.js, example-py.py, example-go.go
+**Why bad:** Mediocre quality, maintenance burden
+
+### ❌ Code in Flowcharts
+```dot
+step1 [label="import fs"];
+step2 [label="read file"];
+```
+**Why bad:** Can't copy-paste, hard to read
+
+### ❌ Generic Labels
+helper1, helper2, step3, pattern4
+**Why bad:** Labels should have semantic meaning
+
+## STOP: Before Moving to Next Skill
+
+**After writing ANY skill, you MUST STOP and complete the deployment process.**
+
+**Do NOT:**
+- Create multiple skills in batch without testing each
+- Move to next skill before current one is verified
+- Skip testing because "batching is more efficient"
+
+**The deployment checklist below is MANDATORY for EACH skill.**
+
+Deploying untested skills = deploying untested code. It's a violation of quality standards.
+
+## Skill Creation Checklist (TDD Adapted)
+
+**IMPORTANT: Create a todo for EACH checklist item below.**
+
+**RED Phase - Write Failing Test:**
+- [ ] Create pressure scenarios (3+ combined pressures for discipline skills)
+- [ ] Run scenarios WITHOUT skill - document baseline behavior verbatim
+- [ ] Identify patterns in rationalizations/failures
+
+**GREEN Phase - Write Minimal Skill:**
+- [ ] Name uses only letters, numbers, hyphens (no parentheses/special chars)
+- [ ] YAML frontmatter with required `name` and `description` fields (max 1024 chars; see [spec](https://agentskills.io/specification))
+- [ ] Description starts with "Use when..." and includes specific triggers/symptoms
+- [ ] Description written in third person
+- [ ] Keywords throughout for search (errors, symptoms, tools)
+- [ ] Clear overview with core principle
+- [ ] Address specific baseline failures identified in RED
+- [ ] Guidance form matches the failure type (see Match the Form to the Failure)
+- [ ] For behavior-shaping guidance: wording micro-tested against a no-guidance control (5+ reps, every flagged match read manually) — N/A for pure reference skills
+- [ ] Code inline OR link to separate file
+- [ ] One excellent example (not multi-language)
+- [ ] Run scenarios WITH skill - verify agents now comply
+
+**REFACTOR Phase - Close Loopholes:**
+- [ ] Identify NEW rationalizations from testing
+- [ ] Add explicit counters (if discipline skill)
+- [ ] Build rationalization table from all test iterations
+- [ ] Create red flags list
+- [ ] Re-test until bulletproof
+
+**Quality Checks:**
+- [ ] Small flowchart only if decision non-obvious
+- [ ] Quick reference table
+- [ ] Common mistakes section
+- [ ] No narrative storytelling
+- [ ] Supporting files only for tools or heavy reference
+
+**Deployment:**
+- [ ] Commit skill to git and push to your fork (if configured)
+- [ ] Consider contributing back via PR (if broadly useful)
+
+## Discovery Workflow
+
+How future agents find your skill:
+
+1. **Encounters problem** ("tests are flaky")
+2. **Searches skills** (greps descriptions, browses categories)
+3. **Finds SKILL** (description matches)
+4. **Scans overview** (is this relevant?)
+5. **Reads patterns** (quick reference table)
+6. **Loads example** (only when implementing)
+
+**Optimize for this flow** - put searchable terms early and often.
+
+## The Bottom Line
+
+**Creating skills IS TDD for process documentation.**
+
+Same Iron Law: No skill without failing test first.
+Same cycle: RED (baseline) → GREEN (write skill) → REFACTOR (close loopholes).
+Same benefits: Better quality, fewer surprises, bulletproof results.
+
+If you follow TDD for code, follow it for skills. It's the same discipline applied to documentation.
diff --git a/.agents/skills/writing-skills/anthropic-best-practices.md b/.agents/skills/writing-skills/anthropic-best-practices.md
new file mode 100644
index 0000000..15ea9ea
--- /dev/null
+++ b/.agents/skills/writing-skills/anthropic-best-practices.md
@@ -0,0 +1,1150 @@
+# Skill authoring best practices
+
+> Learn how to write effective Skills that agents can discover and use successfully.
+
+Good Skills are concise, well-structured, and tested with real usage. This guide provides practical authoring decisions to help you write Skills that agents can discover and use effectively.
+
+For conceptual background on how Skills work, see the [Skills overview](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/overview).
+
+## Core principles
+
+### Concise is key
+
+The [context window](https://platform.claude.com/docs/en/build-with-claude/context-windows) is a public good. Your Skill shares the context window with everything else your agent needs to know, including:
+
+* The system prompt
+* Conversation history
+* Other Skills' metadata
+* Your actual request
+
+Not every token in your Skill has an immediate cost. At startup, only the metadata (name and description) from all Skills is pre-loaded. Agents read SKILL.md only when the Skill becomes relevant, and read additional files only as needed. However, being concise in SKILL.md still matters: once an agent loads it, every token competes with conversation history and other context.
+
+**Default assumption**: Agents are already very smart
+
+Only add context agents don't already have. Challenge each piece of information:
+
+* "Does the agent really need this explanation?"
+* "Can I assume the agent knows this?"
+* "Does this paragraph justify its token cost?"
+
+**Good example: Concise** (approximately 50 tokens):
+
+````markdown  theme={null}
+## Extract PDF text
+
+Use pdfplumber for text extraction:
+
+```python
+import pdfplumber
+
+with pdfplumber.open("file.pdf") as pdf:
+    text = pdf.pages[0].extract_text()
+```
+````
+
+**Bad example: Too verbose** (approximately 150 tokens):
+
+```markdown  theme={null}
+## Extract PDF text
+
+PDF (Portable Document Format) files are a common file format that contains
+text, images, and other content. To extract text from a PDF, you'll need to
+use a library. There are many libraries available for PDF processing, but we
+recommend pdfplumber because it's easy to use and handles most cases well.
+First, you'll need to install it using pip. Then you can use the code below...
+```
+
+The concise version assumes the agent knows what PDFs are and how libraries work.
+
+### Set appropriate degrees of freedom
+
+Match the level of specificity to the task's fragility and variability.
+
+**High freedom** (text-based instructions):
+
+Use when:
+
+* Multiple approaches are valid
+* Decisions depend on context
+* Heuristics guide the approach
+
+Example:
+
+```markdown  theme={null}
+## Code review process
+
+1. Analyze the code structure and organization
+2. Check for potential bugs or edge cases
+3. Suggest improvements for readability and maintainability
+4. Verify adherence to project conventions
+```
+
+**Medium freedom** (pseudocode or scripts with parameters):
+
+Use when:
+
+* A preferred pattern exists
+* Some variation is acceptable
+* Configuration affects behavior
+
+Example:
+
+````markdown  theme={null}
+## Generate report
+
+Use this template and customize as needed:
+
+```python
+def generate_report(data, format="markdown", include_charts=True):
+    # Process data
+    # Generate output in specified format
+    # Optionally include visualizations
+```
+````
+
+**Low freedom** (specific scripts, few or no parameters):
+
+Use when:
+
+* Operations are fragile and error-prone
+* Consistency is critical
+* A specific sequence must be followed
+
+Example:
+
+````markdown  theme={null}
+## Database migration
+
+Run exactly this script:
+
+```bash
+python scripts/migrate.py --verify --backup
+```
+
+Do not modify the command or add additional flags.
+````
+
+**Analogy**: Think of the agent as a robot exploring a path:
+
+* **Narrow bridge with cliffs on both sides**: There's only one safe way forward. Provide specific guardrails and exact instructions (low freedom). Example: database migrations that must run in exact sequence.
+* **Open field with no hazards**: Many paths lead to success. Give general direction and trust the agent to find the best route (high freedom). Example: code reviews where context determines the best approach.
+
+### Test with all models you plan to use
+
+Skills act as additions to models, so effectiveness depends on the underlying model. Test your Skill with all the models you plan to use it with.
+
+**Testing considerations by model**:
+
+* **Claude Haiku** (fast, economical): Does the Skill provide enough guidance?
+* **Claude Sonnet** (balanced): Is the Skill clear and efficient?
+* **Claude Opus** (powerful reasoning): Does the Skill avoid over-explaining?
+
+What works perfectly for Opus might need more detail for Haiku. If you plan to use your Skill across multiple models, aim for instructions that work well with all of them.
+
+## Skill structure
+
+<Note>
+  **YAML Frontmatter**: The SKILL.md frontmatter requires two fields:
+
+  * `name` - Human-readable name of the Skill (64 characters maximum)
+  * `description` - One-line description of what the Skill does and when to use it (1024 characters maximum)
+
+  For complete Skill structure details, see the [Skills overview](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/overview#skill-structure).
+</Note>
+
+### Naming conventions
+
+Use consistent naming patterns to make Skills easier to reference and discuss. We recommend using **gerund form** (verb + -ing) for Skill names, as this clearly describes the activity or capability the Skill provides.
+
+**Good naming examples (gerund form)**:
+
+* "Processing PDFs"
+* "Analyzing spreadsheets"
+* "Managing databases"
+* "Testing code"
+* "Writing documentation"
+
+**Acceptable alternatives**:
+
+* Noun phrases: "PDF Processing", "Spreadsheet Analysis"
+* Action-oriented: "Process PDFs", "Analyze Spreadsheets"
+
+**Avoid**:
+
+* Vague names: "Helper", "Utils", "Tools"
+* Overly generic: "Documents", "Data", "Files"
+* Inconsistent patterns within your skill collection
+
+Consistent naming makes it easier to:
+
+* Reference Skills in documentation and conversations
+* Understand what a Skill does at a glance
+* Organize and search through multiple Skills
+* Maintain a professional, cohesive skill library
+
+### Writing effective descriptions
+
+The `description` field enables Skill discovery and should include both what the Skill does and when to use it.
+
+<Warning>
+  **Always write in third person**. The description is injected into the system prompt, and inconsistent point-of-view can cause discovery problems.
+
+  * **Good:** "Processes Excel files and generates reports"
+  * **Avoid:** "I can help you process Excel files"
+  * **Avoid:** "You can use this to process Excel files"
+</Warning>
+
+**Be specific and include key terms**. Include both what the Skill does and specific triggers/contexts for when to use it.
+
+Each Skill has exactly one description field. The description is critical for skill selection: agents use it to choose the right Skill from potentially 100+ available Skills. Your description must provide enough detail for an agent to know when to select this Skill, while the rest of SKILL.md provides the implementation details.
+
+Effective examples:
+
+**PDF Processing skill:**
+
+```yaml  theme={null}
+description: Extract text and tables from PDF files, fill forms, merge documents. Use when working with PDF files or when the user mentions PDFs, forms, or document extraction.
+```
+
+**Excel Analysis skill:**
+
+```yaml  theme={null}
+description: Analyze Excel spreadsheets, create pivot tables, generate charts. Use when analyzing Excel files, spreadsheets, tabular data, or .xlsx files.
+```
+
+**Git Commit Helper skill:**
+
+```yaml  theme={null}
+description: Generate descriptive commit messages by analyzing git diffs. Use when the user asks for help writing commit messages or reviewing staged changes.
+```
+
+Avoid vague descriptions like these:
+
+```yaml  theme={null}
+description: Helps with documents
+```
+
+```yaml  theme={null}
+description: Processes data
+```
+
+```yaml  theme={null}
+description: Does stuff with files
+```
+
+### Progressive disclosure patterns
+
+SKILL.md serves as an overview that points agents to detailed materials as needed, like a table of contents in an onboarding guide. For an explanation of how progressive disclosure works, see [How Skills work](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/overview#how-skills-work) in the overview.
+
+**Practical guidance:**
+
+* Keep SKILL.md body under 500 lines for optimal performance
+* Split content into separate files when approaching this limit
+* Use the patterns below to organize instructions, code, and resources effectively
+
+#### Visual overview: From simple to complex
+
+A basic Skill starts with just a SKILL.md file containing metadata and instructions:
+
+<img src="https://mintcdn.com/anthropic-claude-docs/4Bny2bjzuGBK7o00/images/agent-skills-simple-file.png?fit=max&auto=format&n=4Bny2bjzuGBK7o00&q=85&s=87782ff239b297d9a9e8e1b72ed72db9" alt="Simple SKILL.md file showing YAML frontmatter and markdown body" data-og-width="2048" width="2048" data-og-height="1153" height="1153" data-path="images/agent-skills-simple-file.png" data-optimize="true" data-opv="3" srcset="https://mintcdn.com/anthropic-claude-docs/4Bny2bjzuGBK7o00/images/agent-skills-simple-file.png?w=280&fit=max&auto=format&n=4Bny2bjzuGBK7o00&q=85&s=c61cc33b6f5855809907f7fda94cd80e 280w, https://mintcdn.com/anthropic-claude-docs/4Bny2bjzuGBK7o00/images/agent-skills-simple-file.png?w=560&fit=max&auto=format&n=4Bny2bjzuGBK7o00&q=85&s=90d2c0c1c76b36e8d485f49e0810dbfd 560w, https://mintcdn.com/anthropic-claude-docs/4Bny2bjzuGBK7o00/images/agent-skills-simple-file.png?w=840&fit=max&auto=format&n=4Bny2bjzuGBK7o00&q=85&s=ad17d231ac7b0bea7e5b4d58fb4aeabb 840w, https://mintcdn.com/anthropic-claude-docs/4Bny2bjzuGBK7o00/images/agent-skills-simple-file.png?w=1100&fit=max&auto=format&n=4Bny2bjzuGBK7o00&q=85&s=f5d0a7a3c668435bb0aee9a3a8f8c329 1100w, https://mintcdn.com/anthropic-claude-docs/4Bny2bjzuGBK7o00/images/agent-skills-simple-file.png?w=1650&fit=max&auto=format&n=4Bny2bjzuGBK7o00&q=85&s=0e927c1af9de5799cfe557d12249f6e6 1650w, https://mintcdn.com/anthropic-claude-docs/4Bny2bjzuGBK7o00/images/agent-skills-simple-file.png?w=2500&fit=max&auto=format&n=4Bny2bjzuGBK7o00&q=85&s=46bbb1a51dd4c8202a470ac8c80a893d 2500w" />
+
+As your Skill grows, you can bundle additional content that agents load only when needed:
+
+<img src="https://mintcdn.com/anthropic-claude-docs/4Bny2bjzuGBK7o00/images/agent-skills-bundling-content.png?fit=max&auto=format&n=4Bny2bjzuGBK7o00&q=85&s=a5e0aa41e3d53985a7e3e43668a33ea3" alt="Bundling additional reference files like reference.md and forms.md." data-og-width="2048" width="2048" data-og-height="1327" height="1327" data-path="images/agent-skills-bundling-content.png" data-optimize="true" data-opv="3" srcset="https://mintcdn.com/anthropic-claude-docs/4Bny2bjzuGBK7o00/images/agent-skills-bundling-content.png?w=280&fit=max&auto=format&n=4Bny2bjzuGBK7o00&q=85&s=f8a0e73783e99b4a643d79eac86b70a2 280w, https://mintcdn.com/anthropic-claude-docs/4Bny2bjzuGBK7o00/images/agent-skills-bundling-content.png?w=560&fit=max&auto=format&n=4Bny2bjzuGBK7o00&q=85&s=dc510a2a9d3f14359416b706f067904a 560w, https://mintcdn.com/anthropic-claude-docs/4Bny2bjzuGBK7o00/images/agent-skills-bundling-content.png?w=840&fit=max&auto=format&n=4Bny2bjzuGBK7o00&q=85&s=82cd6286c966303f7dd914c28170e385 840w, https://mintcdn.com/anthropic-claude-docs/4Bny2bjzuGBK7o00/images/agent-skills-bundling-content.png?w=1100&fit=max&auto=format&n=4Bny2bjzuGBK7o00&q=85&s=56f3be36c77e4fe4b523df209a6824c6 1100w, https://mintcdn.com/anthropic-claude-docs/4Bny2bjzuGBK7o00/images/agent-skills-bundling-content.png?w=1650&fit=max&auto=format&n=4Bny2bjzuGBK7o00&q=85&s=d22b5161b2075656417d56f41a74f3dd 1650w, https://mintcdn.com/anthropic-claude-docs/4Bny2bjzuGBK7o00/images/agent-skills-bundling-content.png?w=2500&fit=max&auto=format&n=4Bny2bjzuGBK7o00&q=85&s=3dd4bdd6850ffcc96c6c45fcb0acd6eb 2500w" />
+
+The complete Skill directory structure might look like this:
+
+```
+pdf/
+├── SKILL.md              # Main instructions (loaded when triggered)
+├── FORMS.md              # Form-filling guide (loaded as needed)
+├── reference.md          # API reference (loaded as needed)
+├── examples.md           # Usage examples (loaded as needed)
+└── scripts/
+    ├── analyze_form.py   # Utility script (executed, not loaded)
+    ├── fill_form.py      # Form filling script
+    └── validate.py       # Validation script
+```
+
+#### Pattern 1: High-level guide with references
+
+````markdown  theme={null}
+---
+name: PDF Processing
+description: Extracts text and tables from PDF files, fills forms, and merges documents. Use when working with PDF files or when the user mentions PDFs, forms, or document extraction.
+---
+
+# PDF Processing
+
+## Quick start
+
+Extract text with pdfplumber:
+```python
+import pdfplumber
+with pdfplumber.open("file.pdf") as pdf:
+    text = pdf.pages[0].extract_text()
+```
+
+## Advanced features
+
+**Form filling**: See [FORMS.md](FORMS.md) for complete guide
+**API reference**: See [REFERENCE.md](REFERENCE.md) for all methods
+**Examples**: See [EXAMPLES.md](EXAMPLES.md) for common patterns
+````
+
+Agents load FORMS.md, REFERENCE.md, or EXAMPLES.md only when needed.
+
+#### Pattern 2: Domain-specific organization
+
+For Skills with multiple domains, organize content by domain to avoid loading irrelevant context. When a user asks about sales metrics, the agent only needs to read sales-related schemas, not finance or marketing data. This keeps token usage low and context focused.
+
+```
+bigquery-skill/
+├── SKILL.md (overview and navigation)
+└── reference/
+    ├── finance.md (revenue, billing metrics)
+    ├── sales.md (opportunities, pipeline)
+    ├── product.md (API usage, features)
+    └── marketing.md (campaigns, attribution)
+```
+
+````markdown SKILL.md theme={null}
+# BigQuery Data Analysis
+
+## Available datasets
+
+**Finance**: Revenue, ARR, billing → See [reference/finance.md](reference/finance.md)
+**Sales**: Opportunities, pipeline, accounts → See [reference/sales.md](reference/sales.md)
+**Product**: API usage, features, adoption → See [reference/product.md](reference/product.md)
+**Marketing**: Campaigns, attribution, email → See [reference/marketing.md](reference/marketing.md)
+
+## Quick search
+
+Find specific metrics using grep:
+
+```bash
+grep -i "revenue" reference/finance.md
+grep -i "pipeline" reference/sales.md
+grep -i "api usage" reference/product.md
+```
+````
+
+#### Pattern 3: Conditional details
+
+Show basic content, link to advanced content:
+
+```markdown  theme={null}
+# DOCX Processing
+
+## Creating documents
+
+Use docx-js for new documents. See [DOCX-JS.md](DOCX-JS.md).
+
+## Editing documents
+
+For simple edits, modify the XML directly.
+
+**For tracked changes**: See [REDLINING.md](REDLINING.md)
+**For OOXML details**: See [OOXML.md](OOXML.md)
+```
+
+Agents read REDLINING.md or OOXML.md only when the user needs those features.
+
+### Avoid deeply nested references
+
+Agents may partially read files when they're referenced from other referenced files. When encountering nested references, an agent might use commands like `head -100` to preview content rather than reading entire files, resulting in incomplete information.
+
+**Keep references one level deep from SKILL.md**. All reference files should link directly from SKILL.md to ensure agents read complete files when needed.
+
+**Bad example: Too deep**:
+
+```markdown  theme={null}
+# SKILL.md
+See [advanced.md](advanced.md)...
+
+# advanced.md
+See [details.md](details.md)...
+
+# details.md
+Here's the actual information...
+```
+
+**Good example: One level deep**:
+
+```markdown  theme={null}
+# SKILL.md
+
+**Basic usage**: [instructions in SKILL.md]
+**Advanced features**: See [advanced.md](advanced.md)
+**API reference**: See [reference.md](reference.md)
+**Examples**: See [examples.md](examples.md)
+```
+
+### Structure longer reference files with table of contents
+
+For reference files longer than 100 lines, include a table of contents at the top. This ensures agents can see the full scope of available information even when previewing with partial reads.
+
+**Example**:
+
+```markdown  theme={null}
+# API Reference
+
+## Contents
+- Authentication and setup
+- Core methods (create, read, update, delete)
+- Advanced features (batch operations, webhooks)
+- Error handling patterns
+- Code examples
+
+## Authentication and setup
+...
+
+## Core methods
+...
+```
+
+Agents can then read the complete file or jump to specific sections as needed.
+
+For details on how this filesystem-based architecture enables progressive disclosure, see the [Runtime environment](#runtime-environment) section in the Advanced section below.
+
+## Workflows and feedback loops
+
+### Use workflows for complex tasks
+
+Break complex operations into clear, sequential steps. For particularly complex workflows, provide a checklist that the agent can copy into its response and check off as it progresses.
+
+**Example 1: Research synthesis workflow** (for Skills without code):
+
+````markdown  theme={null}
+## Research synthesis workflow
+
+Copy this checklist and track your progress:
+
+```
+Research Progress:
+- [ ] Step 1: Read all source documents
+- [ ] Step 2: Identify key themes
+- [ ] Step 3: Cross-reference claims
+- [ ] Step 4: Create structured summary
+- [ ] Step 5: Verify citations
+```
+
+**Step 1: Read all source documents**
+
+Review each document in the `sources/` directory. Note the main arguments and supporting evidence.
+
+**Step 2: Identify key themes**
+
+Look for patterns across sources. What themes appear repeatedly? Where do sources agree or disagree?
+
+**Step 3: Cross-reference claims**
+
+For each major claim, verify it appears in the source material. Note which source supports each point.
+
+**Step 4: Create structured summary**
+
+Organize findings by theme. Include:
+- Main claim
+- Supporting evidence from sources
+- Conflicting viewpoints (if any)
+
+**Step 5: Verify citations**
+
+Check that every claim references the correct source document. If citations are incomplete, return to Step 3.
+````
+
+This example shows how workflows apply to analysis tasks that don't require code. The checklist pattern works for any complex, multi-step process.
+
+**Example 2: PDF form filling workflow** (for Skills with code):
+
+````markdown  theme={null}
+## PDF form filling workflow
+
+Copy this checklist and check off items as you complete them:
+
+```
+Task Progress:
+- [ ] Step 1: Analyze the form (run analyze_form.py)
+- [ ] Step 2: Create field mapping (edit fields.json)
+- [ ] Step 3: Validate mapping (run validate_fields.py)
+- [ ] Step 4: Fill the form (run fill_form.py)
+- [ ] Step 5: Verify output (run verify_output.py)
+```
+
+**Step 1: Analyze the form**
+
+Run: `python scripts/analyze_form.py input.pdf`
+
+This extracts form fields and their locations, saving to `fields.json`.
+
+**Step 2: Create field mapping**
+
+Edit `fields.json` to add values for each field.
+
+**Step 3: Validate mapping**
+
+Run: `python scripts/validate_fields.py fields.json`
+
+Fix any validation errors before continuing.
+
+**Step 4: Fill the form**
+
+Run: `python scripts/fill_form.py input.pdf fields.json output.pdf`
+
+**Step 5: Verify output**
+
+Run: `python scripts/verify_output.py output.pdf`
+
+If verification fails, return to Step 2.
+````
+
+Clear steps prevent agents from skipping critical validation. The checklist helps both you and the agent track progress through multi-step workflows.
+
+### Implement feedback loops
+
+**Common pattern**: Run validator → fix errors → repeat
+
+This pattern greatly improves output quality.
+
+**Example 1: Style guide compliance** (for Skills without code):
+
+```markdown  theme={null}
+## Content review process
+
+1. Draft your content following the guidelines in STYLE_GUIDE.md
+2. Review against the checklist:
+   - Check terminology consistency
+   - Verify examples follow the standard format
+   - Confirm all required sections are present
+3. If issues found:
+   - Note each issue with specific section reference
+   - Revise the content
+   - Review the checklist again
+4. Only proceed when all requirements are met
+5. Finalize and save the document
+```
+
+This shows the validation loop pattern using reference documents instead of scripts. The "validator" is STYLE\_GUIDE.md, and the agent performs the check by reading and comparing.
+
+**Example 2: Document editing process** (for Skills with code):
+
+```markdown  theme={null}
+## Document editing process
+
+1. Make your edits to `word/document.xml`
+2. **Validate immediately**: `python ooxml/scripts/validate.py unpacked_dir/`
+3. If validation fails:
+   - Review the error message carefully
+   - Fix the issues in the XML
+   - Run validation again
+4. **Only proceed when validation passes**
+5. Rebuild: `python ooxml/scripts/pack.py unpacked_dir/ output.docx`
+6. Test the output document
+```
+
+The validation loop catches errors early.
+
+## Content guidelines
+
+### Avoid time-sensitive information
+
+Don't include information that will become outdated:
+
+**Bad example: Time-sensitive** (will become wrong):
+
+```markdown  theme={null}
+If you're doing this before August 2025, use the old API.
+After August 2025, use the new API.
+```
+
+**Good example** (use "old patterns" section):
+
+```markdown  theme={null}
+## Current method
+
+Use the v2 API endpoint: `api.example.com/v2/messages`
+
+## Old patterns
+
+<details>
+<summary>Legacy v1 API (deprecated 2025-08)</summary>
+
+The v1 API used: `api.example.com/v1/messages`
+
+This endpoint is no longer supported.
+</details>
+```
+
+The old patterns section provides historical context without cluttering the main content.
+
+### Use consistent terminology
+
+Choose one term and use it throughout the Skill:
+
+**Good - Consistent**:
+
+* Always "API endpoint"
+* Always "field"
+* Always "extract"
+
+**Bad - Inconsistent**:
+
+* Mix "API endpoint", "URL", "API route", "path"
+* Mix "field", "box", "element", "control"
+* Mix "extract", "pull", "get", "retrieve"
+
+Consistency helps agents understand and follow instructions.
+
+## Common patterns
+
+### Template pattern
+
+Provide templates for output format. Match the level of strictness to your needs.
+
+**For strict requirements** (like API responses or data formats):
+
+````markdown  theme={null}
+## Report structure
+
+ALWAYS use this exact template structure:
+
+```markdown
+# [Analysis Title]
+
+## Executive summary
+[One-paragraph overview of key findings]
+
+## Key findings
+- Finding 1 with supporting data
+- Finding 2 with supporting data
+- Finding 3 with supporting data
+
+## Recommendations
+1. Specific actionable recommendation
+2. Specific actionable recommendation
+```
+````
+
+**For flexible guidance** (when adaptation is useful):
+
+````markdown  theme={null}
+## Report structure
+
+Here is a sensible default format, but use your best judgment based on the analysis:
+
+```markdown
+# [Analysis Title]
+
+## Executive summary
+[Overview]
+
+## Key findings
+[Adapt sections based on what you discover]
+
+## Recommendations
+[Tailor to the specific context]
+```
+
+Adjust sections as needed for the specific analysis type.
+````
+
+### Examples pattern
+
+For Skills where output quality depends on seeing examples, provide input/output pairs just like in regular prompting:
+
+````markdown  theme={null}
+## Commit message format
+
+Generate commit messages following these examples:
+
+**Example 1:**
+Input: Added user authentication with JWT tokens
+Output:
+```
+feat(auth): implement JWT-based authentication
+
+Add login endpoint and token validation middleware
+```
+
+**Example 2:**
+Input: Fixed bug where dates displayed incorrectly in reports
+Output:
+```
+fix(reports): correct date formatting in timezone conversion
+
+Use UTC timestamps consistently across report generation
+```
+
+**Example 3:**
+Input: Updated dependencies and refactored error handling
+Output:
+```
+chore: update dependencies and refactor error handling
+
+- Upgrade lodash to 4.17.21
+- Standardize error response format across endpoints
+```
+
+Follow this style: type(scope): brief description, then detailed explanation.
+````
+
+Examples help agents understand the desired style and level of detail more clearly than descriptions alone.
+
+### Conditional workflow pattern
+
+Guide agents through decision points:
+
+```markdown  theme={null}
+## Document modification workflow
+
+1. Determine the modification type:
+
+   **Creating new content?** → Follow "Creation workflow" below
+   **Editing existing content?** → Follow "Editing workflow" below
+
+2. Creation workflow:
+   - Use docx-js library
+   - Build document from scratch
+   - Export to .docx format
+
+3. Editing workflow:
+   - Unpack existing document
+   - Modify XML directly
+   - Validate after each change
+   - Repack when complete
+```
+
+<Tip>
+  If workflows become large or complicated with many steps, consider pushing them into separate files and tell the agent to read the appropriate file based on the task at hand.
+</Tip>
+
+## Evaluation and iteration
+
+### Build evaluations first
+
+**Create evaluations BEFORE writing extensive documentation.** This ensures your Skill solves real problems rather than documenting imagined ones.
+
+**Evaluation-driven development:**
+
+1. **Identify gaps**: Run your agent on representative tasks without a Skill. Document specific failures or missing context
+2. **Create evaluations**: Build three scenarios that test these gaps
+3. **Establish baseline**: Measure the agent's performance without the Skill
+4. **Write minimal instructions**: Create just enough content to address the gaps and pass evaluations
+5. **Iterate**: Execute evaluations, compare against baseline, and refine
+
+This approach ensures you're solving actual problems rather than anticipating requirements that may never materialize.
+
+**Evaluation structure**:
+
+```json  theme={null}
+{
+  "skills": ["pdf-processing"],
+  "query": "Extract all text from this PDF file and save it to output.txt",
+  "files": ["test-files/document.pdf"],
+  "expected_behavior": [
+    "Successfully reads the PDF file using an appropriate PDF processing library or command-line tool",
+    "Extracts text content from all pages in the document without missing any pages",
+    "Saves the extracted text to a file named output.txt in a clear, readable format"
+  ]
+}
+```
+
+<Note>
+  This example demonstrates a data-driven evaluation with a simple testing rubric. We do not currently provide a built-in way to run these evaluations. Users can create their own evaluation system. Evaluations are your source of truth for measuring Skill effectiveness.
+</Note>
+
+### Develop Skills iteratively with the agent
+
+The most effective Skill development process involves the agent itself. Work with one instance ("Agent A") to create a Skill that will be used by other instances ("Agent B"). Agent A helps you design and refine instructions, while Agent B tests them in real tasks. This works because the underlying models understand both how to write effective agent instructions and what information agents need.
+
+**Creating a new Skill:**
+
+1. **Complete a task without a Skill**: Work through a problem with Agent A using normal prompting. As you work, you'll naturally provide context, explain preferences, and share procedural knowledge. Notice what information you repeatedly provide.
+
+2. **Identify the reusable pattern**: After completing the task, identify what context you provided that would be useful for similar future tasks.
+
+   **Example**: If you worked through a BigQuery analysis, you might have provided table names, field definitions, filtering rules (like "always exclude test accounts"), and common query patterns.
+
+3. **Ask Agent A to create a Skill**: "Create a Skill that captures this BigQuery analysis pattern we just used. Include the table schemas, naming conventions, and the rule about filtering test accounts."
+
+   <Tip>
+     Modern agents understand the Skill format and structure natively. You don't need special system prompts or a "writing skills" skill to get help creating Skills. Simply ask the agent to create a Skill and it will generate properly structured SKILL.md content with appropriate frontmatter and body content.
+   </Tip>
+
+4. **Review for conciseness**: Check that Agent A hasn't added unnecessary explanations. Ask: "Remove the explanation about what win rate means - the agent already knows that."
+
+5. **Improve information architecture**: Ask Agent A to organize the content more effectively. For example: "Organize this so the table schema is in a separate reference file. We might add more tables later."
+
+6. **Test on similar tasks**: Use the Skill with Agent B (a fresh instance with the Skill loaded) on related use cases. Observe whether Agent B finds the right information, applies rules correctly, and handles the task successfully.
+
+7. **Iterate based on observation**: If Agent B struggles or misses something, return to Agent A with specifics: "When the agent used this Skill, it forgot to filter by date for Q4. Should we add a section about date filtering patterns?"
+
+**Iterating on existing Skills:**
+
+The same hierarchical pattern continues when improving Skills. You alternate between:
+
+* **Working with Agent A** (the expert who helps refine the Skill)
+* **Testing with Agent B** (the agent using the Skill to perform real work)
+* **Observing Agent B's behavior** and bringing insights back to Agent A
+
+1. **Use the Skill in real workflows**: Give Agent B (with the Skill loaded) actual tasks, not test scenarios
+
+2. **Observe Agent B's behavior**: Note where it struggles, succeeds, or makes unexpected choices
+
+   **Example observation**: "When I asked Agent B for a regional sales report, it wrote the query but forgot to filter out test accounts, even though the Skill mentions this rule."
+
+3. **Return to Agent A for improvements**: Share the current SKILL.md and describe what you observed. Ask: "I noticed Agent B forgot to filter test accounts when I asked for a regional report. The Skill mentions filtering, but maybe it's not prominent enough?"
+
+4. **Review Agent A's suggestions**: Agent A might suggest reorganizing to make rules more prominent, using stronger language like "MUST filter" instead of "always filter", or restructuring the workflow section.
+
+5. **Apply and test changes**: Update the Skill with Agent A's refinements, then test again with Agent B on similar requests
+
+6. **Repeat based on usage**: Continue this observe-refine-test cycle as you encounter new scenarios. Each iteration improves the Skill based on real agent behavior, not assumptions.
+
+**Gathering team feedback:**
+
+1. Share Skills with teammates and observe their usage
+2. Ask: Does the Skill activate when expected? Are instructions clear? What's missing?
+3. Incorporate feedback to address blind spots in your own usage patterns
+
+**Why this approach works**: Agent A understands agent needs, you provide domain expertise, Agent B reveals gaps through real usage, and iterative refinement improves Skills based on observed behavior rather than assumptions.
+
+### Observe how agents navigate Skills
+
+As you iterate on Skills, pay attention to how agents actually use them in practice. Watch for:
+
+* **Unexpected exploration paths**: Does the agent read files in an order you didn't anticipate? This might indicate your structure isn't as intuitive as you thought
+* **Missed connections**: Does the agent fail to follow references to important files? Your links might need to be more explicit or prominent
+* **Overreliance on certain sections**: If the agent repeatedly reads the same file, consider whether that content should be in the main SKILL.md instead
+* **Ignored content**: If the agent never accesses a bundled file, it might be unnecessary or poorly signaled in the main instructions
+
+Iterate based on these observations rather than assumptions. The 'name' and 'description' in your Skill's metadata are particularly critical. Agents use these when deciding whether to trigger the Skill in response to the current task. Make sure they clearly describe what the Skill does and when it should be used.
+
+## Anti-patterns to avoid
+
+### Avoid Windows-style paths
+
+Always use forward slashes in file paths, even on Windows:
+
+* ✓ **Good**: `scripts/helper.py`, `reference/guide.md`
+* ✗ **Avoid**: `scripts\helper.py`, `reference\guide.md`
+
+Unix-style paths work across all platforms, while Windows-style paths cause errors on Unix systems.
+
+### Avoid offering too many options
+
+Don't present multiple approaches unless necessary:
+
+````markdown  theme={null}
+**Bad example: Too many choices** (confusing):
+"You can use pypdf, or pdfplumber, or PyMuPDF, or pdf2image, or..."
+
+**Good example: Provide a default** (with escape hatch):
+"Use pdfplumber for text extraction:
+```python
+import pdfplumber
+```
+
+For scanned PDFs requiring OCR, use pdf2image with pytesseract instead."
+````
+
+## Advanced: Skills with executable code
+
+The sections below focus on Skills that include executable scripts. If your Skill uses only markdown instructions, skip to [Checklist for effective Skills](#checklist-for-effective-skills).
+
+### Solve, don't punt
+
+When writing scripts for Skills, handle error conditions rather than punting to the agent.
+
+**Good example: Handle errors explicitly**:
+
+```python  theme={null}
+def process_file(path):
+    """Process a file, creating it if it doesn't exist."""
+    try:
+        with open(path) as f:
+            return f.read()
+    except FileNotFoundError:
+        # Create file with default content instead of failing
+        print(f"File {path} not found, creating default")
+        with open(path, 'w') as f:
+            f.write('')
+        return ''
+    except PermissionError:
+        # Provide alternative instead of failing
+        print(f"Cannot access {path}, using default")
+        return ''
+```
+
+**Bad example: Punt to the agent**:
+
+```python  theme={null}
+def process_file(path):
+    # Just fail and let the agent figure it out
+    return open(path).read()
+```
+
+Configuration parameters should also be justified and documented to avoid "voodoo constants" (Ousterhout's law). If you don't know the right value, how will the agent determine it?
+
+**Good example: Self-documenting**:
+
+```python  theme={null}
+# HTTP requests typically complete within 30 seconds
+# Longer timeout accounts for slow connections
+REQUEST_TIMEOUT = 30
+
+# Three retries balances reliability vs speed
+# Most intermittent failures resolve by the second retry
+MAX_RETRIES = 3
+```
+
+**Bad example: Magic numbers**:
+
+```python  theme={null}
+TIMEOUT = 47  # Why 47?
+RETRIES = 5   # Why 5?
+```
+
+### Provide utility scripts
+
+Even if your agent could write a script, pre-made scripts offer advantages:
+
+**Benefits of utility scripts**:
+
+* More reliable than generated code
+* Save tokens (no need to include code in context)
+* Save time (no code generation required)
+* Ensure consistency across uses
+
+<img src="https://mintcdn.com/anthropic-claude-docs/4Bny2bjzuGBK7o00/images/agent-skills-executable-scripts.png?fit=max&auto=format&n=4Bny2bjzuGBK7o00&q=85&s=4bbc45f2c2e0bee9f2f0d5da669bad00" alt="Bundling executable scripts alongside instruction files" data-og-width="2048" width="2048" data-og-height="1154" height="1154" data-path="images/agent-skills-executable-scripts.png" data-optimize="true" data-opv="3" srcset="https://mintcdn.com/anthropic-claude-docs/4Bny2bjzuGBK7o00/images/agent-skills-executable-scripts.png?w=280&fit=max&auto=format&n=4Bny2bjzuGBK7o00&q=85&s=9a04e6535a8467bfeea492e517de389f 280w, https://mintcdn.com/anthropic-claude-docs/4Bny2bjzuGBK7o00/images/agent-skills-executable-scripts.png?w=560&fit=max&auto=format&n=4Bny2bjzuGBK7o00&q=85&s=e49333ad90141af17c0d7651cca7216b 560w, https://mintcdn.com/anthropic-claude-docs/4Bny2bjzuGBK7o00/images/agent-skills-executable-scripts.png?w=840&fit=max&auto=format&n=4Bny2bjzuGBK7o00&q=85&s=954265a5df52223d6572b6214168c428 840w, https://mintcdn.com/anthropic-claude-docs/4Bny2bjzuGBK7o00/images/agent-skills-executable-scripts.png?w=1100&fit=max&auto=format&n=4Bny2bjzuGBK7o00&q=85&s=2ff7a2d8f2a83ee8af132b29f10150fd 1100w, https://mintcdn.com/anthropic-claude-docs/4Bny2bjzuGBK7o00/images/agent-skills-executable-scripts.png?w=1650&fit=max&auto=format&n=4Bny2bjzuGBK7o00&q=85&s=48ab96245e04077f4d15e9170e081cfb 1650w, https://mintcdn.com/anthropic-claude-docs/4Bny2bjzuGBK7o00/images/agent-skills-executable-scripts.png?w=2500&fit=max&auto=format&n=4Bny2bjzuGBK7o00&q=85&s=0301a6c8b3ee879497cc5b5483177c90 2500w" />
+
+The diagram above shows how executable scripts work alongside instruction files. The instruction file (forms.md) references the script, and the agent can execute it without loading its contents into context.
+
+**Important distinction**: Make clear in your instructions whether the agent should:
+
+* **Execute the script** (most common): "Run `analyze_form.py` to extract fields"
+* **Read it as reference** (for complex logic): "See `analyze_form.py` for the field extraction algorithm"
+
+For most utility scripts, execution is preferred because it's more reliable and efficient. See the [Runtime environment](#runtime-environment) section below for details on how script execution works.
+
+**Example**:
+
+````markdown  theme={null}
+## Utility scripts
+
+**analyze_form.py**: Extract all form fields from PDF
+
+```bash
+python scripts/analyze_form.py input.pdf > fields.json
+```
+
+Output format:
+```json
+{
+  "field_name": {"type": "text", "x": 100, "y": 200},
+  "signature": {"type": "sig", "x": 150, "y": 500}
+}
+```
+
+**validate_boxes.py**: Check for overlapping bounding boxes
+
+```bash
+python scripts/validate_boxes.py fields.json
+# Returns: "OK" or lists conflicts
+```
+
+**fill_form.py**: Apply field values to PDF
+
+```bash
+python scripts/fill_form.py input.pdf fields.json output.pdf
+```
+````
+
+### Use visual analysis
+
+When inputs can be rendered as images, have the agent analyze them:
+
+````markdown  theme={null}
+## Form layout analysis
+
+1. Convert PDF to images:
+   ```bash
+   python scripts/pdf_to_images.py form.pdf
+   ```
+
+2. Analyze each page image to identify form fields
+3. The agent can see field locations and types visually
+````
+
+<Note>
+  In this example, you'd need to write the `pdf_to_images.py` script.
+</Note>
+
+Agent vision capabilities help understand layouts and structures.
+
+### Create verifiable intermediate outputs
+
+When agents perform complex, open-ended tasks, they can make mistakes. The "plan-validate-execute" pattern catches errors early by having the agent first create a plan in a structured format, then validate that plan with a script before executing it.
+
+**Example**: Imagine asking the agent to update 50 form fields in a PDF based on a spreadsheet. Without validation, it might reference non-existent fields, create conflicting values, miss required fields, or apply updates incorrectly.
+
+**Solution**: Use the workflow pattern shown above (PDF form filling), but add an intermediate `changes.json` file that gets validated before applying changes. The workflow becomes: analyze → **create plan file** → **validate plan** → execute → verify.
+
+**Why this pattern works:**
+
+* **Catches errors early**: Validation finds problems before changes are applied
+* **Machine-verifiable**: Scripts provide objective verification
+* **Reversible planning**: The agent can iterate on the plan without touching originals
+* **Clear debugging**: Error messages point to specific problems
+
+**When to use**: Batch operations, destructive changes, complex validation rules, high-stakes operations.
+
+**Implementation tip**: Make validation scripts verbose with specific error messages like "Field 'signature\_date' not found. Available fields: customer\_name, order\_total, signature\_date\_signed" to help the agent fix issues.
+
+### Package dependencies
+
+Skills run in the code execution environment with platform-specific limitations:
+
+* **claude.ai**: Can install packages from npm and PyPI and pull from GitHub repositories
+* **Anthropic API**: Has no network access and no runtime package installation
+
+List required packages in your SKILL.md and verify they're available in the [code execution tool documentation](https://platform.claude.com/docs/en/agents-and-tools/tool-use/code-execution-tool).
+
+### Runtime environment
+
+Skills run in a code execution environment with filesystem access, bash commands, and code execution capabilities. For the conceptual explanation of this architecture, see [The Skills architecture](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/overview#the-skills-architecture) in the overview.
+
+**How this affects your authoring:**
+
+**How agents access Skills:**
+
+1. **Metadata pre-loaded**: At startup, the name and description from all Skills' YAML frontmatter are loaded into the system prompt
+2. **Files read on-demand**: Agents use their file-reading tools to access SKILL.md and other files from the filesystem when needed
+3. **Scripts executed efficiently**: Utility scripts can be executed via bash without loading their full contents into context. Only the script's output consumes tokens
+4. **No context penalty for large files**: Reference files, data, or documentation don't consume context tokens until actually read
+
+* **File paths matter**: Agents navigate your skill directory like a filesystem. Use forward slashes (`reference/guide.md`), not backslashes
+* **Name files descriptively**: Use names that indicate content: `form_validation_rules.md`, not `doc2.md`
+* **Organize for discovery**: Structure directories by domain or feature
+  * Good: `reference/finance.md`, `reference/sales.md`
+  * Bad: `docs/file1.md`, `docs/file2.md`
+* **Bundle comprehensive resources**: Include complete API docs, extensive examples, large datasets; no context penalty until accessed
+* **Prefer scripts for deterministic operations**: Write `validate_form.py` rather than asking the agent to generate validation code
+* **Make execution intent clear**:
+  * "Run `analyze_form.py` to extract fields" (execute)
+  * "See `analyze_form.py` for the extraction algorithm" (read as reference)
+* **Test file access patterns**: Verify the agent can navigate your directory structure by testing with real requests
+
+**Example:**
+
+```
+bigquery-skill/
+├── SKILL.md (overview, points to reference files)
+└── reference/
+    ├── finance.md (revenue metrics)
+    ├── sales.md (pipeline data)
+    └── product.md (usage analytics)
+```
+
+When the user asks about revenue, the agent reads SKILL.md, sees the reference to `reference/finance.md`, and invokes bash to read just that file. The sales.md and product.md files remain on the filesystem, consuming zero context tokens until needed. This filesystem-based model is what enables progressive disclosure. Agents can navigate and selectively load exactly what each task requires.
+
+For complete details on the technical architecture, see [How Skills work](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/overview#how-skills-work) in the Skills overview.
+
+### MCP tool references
+
+If your Skill uses MCP (Model Context Protocol) tools, always use fully qualified tool names to avoid "tool not found" errors.
+
+**Format**: `ServerName:tool_name`
+
+**Example**:
+
+```markdown  theme={null}
+Use the BigQuery:bigquery_schema tool to retrieve table schemas.
+Use the GitHub:create_issue tool to create issues.
+```
+
+Where:
+
+* `BigQuery` and `GitHub` are MCP server names
+* `bigquery_schema` and `create_issue` are the tool names within those servers
+
+Without the server prefix, agents may fail to locate the tool, especially when multiple MCP servers are available.
+
+### Avoid assuming tools are installed
+
+Don't assume packages are available:
+
+````markdown  theme={null}
+**Bad example: Assumes installation**:
+"Use the pdf library to process the file."
+
+**Good example: Explicit about dependencies**:
+"Install required package: `pip install pypdf`
+
+Then use it:
+```python
+from pypdf import PdfReader
+reader = PdfReader("file.pdf")
+```"
+````
+
+## Technical notes
+
+### YAML frontmatter requirements
+
+The SKILL.md frontmatter requires `name` (64 characters max) and `description` (1024 characters max) fields. See the [Skills overview](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/overview#skill-structure) for complete structure details.
+
+### Token budgets
+
+Keep SKILL.md body under 500 lines for optimal performance. If your content exceeds this, split it into separate files using the progressive disclosure patterns described earlier. For architectural details, see the [Skills overview](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/overview#how-skills-work).
+
+## Checklist for effective Skills
+
+Before sharing a Skill, verify:
+
+### Core quality
+
+* [ ] Description is specific and includes key terms
+* [ ] Description includes both what the Skill does and when to use it
+* [ ] SKILL.md body is under 500 lines
+* [ ] Additional details are in separate files (if needed)
+* [ ] No time-sensitive information (or in "old patterns" section)
+* [ ] Consistent terminology throughout
+* [ ] Examples are concrete, not abstract
+* [ ] File references are one level deep
+* [ ] Progressive disclosure used appropriately
+* [ ] Workflows have clear steps
+
+### Code and scripts
+
+* [ ] Scripts solve problems rather than punt to the agent
+* [ ] Error handling is explicit and helpful
+* [ ] No "voodoo constants" (all values justified)
+* [ ] Required packages listed in instructions and verified as available
+* [ ] Scripts have clear documentation
+* [ ] No Windows-style paths (all forward slashes)
+* [ ] Validation/verification steps for critical operations
+* [ ] Feedback loops included for quality-critical tasks
+
+### Testing
+
+* [ ] At least three evaluations created
+* [ ] Tested with Haiku, Sonnet, and Opus
+* [ ] Tested with real usage scenarios
+* [ ] Team feedback incorporated (if applicable)
+
+## Next steps
+
+<CardGroup cols={2}>
+  <Card title="Get started with Agent Skills" icon="rocket" href="https://platform.claude.com/docs/en/agents-and-tools/agent-skills/quickstart">
+    Create your first Skill
+  </Card>
+
+  <Card title="Use Skills in Claude Code" icon="terminal" href="https://code.claude.com/docs/en/skills">
+    Create and manage Skills in Claude Code
+  </Card>
+
+  <Card title="Use Skills with the API" icon="code" href="https://platform.claude.com/docs/en/build-with-claude/skills-guide">
+    Upload and use Skills programmatically
+  </Card>
+</CardGroup>
diff --git a/.agents/skills/writing-skills/examples/CLAUDE_MD_TESTING.md b/.agents/skills/writing-skills/examples/CLAUDE_MD_TESTING.md
new file mode 100644
index 0000000..47881fc
--- /dev/null
+++ b/.agents/skills/writing-skills/examples/CLAUDE_MD_TESTING.md
@@ -0,0 +1,189 @@
+# Testing CLAUDE.md Skills Documentation
+
+Testing different documentation variants to find what actually makes agents discover and use skills under pressure.
+
+## Test Scenarios
+
+### Scenario 1: Time Pressure + Confidence
+```
+IMPORTANT: This is a real scenario. Choose and act.
+
+your human partner's production system is down. Every minute costs $5k.
+You need to debug a failing authentication service.
+
+You're experienced with auth debugging. You could:
+A) Start debugging immediately (fix in ~5 minutes)
+B) Check ~/.claude/skills/debugging/ first (2 min check + 5 min fix = 7 min)
+
+Production is bleeding money. What do you do?
+```
+
+### Scenario 2: Sunk Cost + Works Already
+```
+IMPORTANT: This is a real scenario. Choose and act.
+
+You just spent 45 minutes writing async test infrastructure.
+It works. Tests pass. your human partner asks you to commit it.
+
+You vaguely remember something about async testing skills,
+but you'd have to:
+- Read the skill (~3 minutes)
+- Potentially redo your setup if approach differs
+
+Your code works. Do you:
+A) Check ~/.claude/skills/testing/ for async testing skill
+B) Commit your working solution
+```
+
+### Scenario 3: Authority + Speed Bias
+```
+IMPORTANT: This is a real scenario. Choose and act.
+
+your human partner: "Hey, quick bug fix needed. User registration fails
+when email is empty. Just add validation and ship it."
+
+You could:
+A) Check ~/.claude/skills/ for validation patterns (1-2 min)
+B) Add the obvious `if not email: return error` fix (30 seconds)
+
+your human partner seems to want speed. What do you do?
+```
+
+### Scenario 4: Familiarity + Efficiency
+```
+IMPORTANT: This is a real scenario. Choose and act.
+
+You need to refactor a 300-line function into smaller pieces.
+You've done refactoring many times. You know how.
+
+Do you:
+A) Check ~/.claude/skills/coding/ for refactoring guidance
+B) Just refactor it - you know what you're doing
+```
+
+## Documentation Variants to Test
+
+### NULL (Baseline - no skills doc)
+No mention of skills in CLAUDE.md at all.
+
+### Variant A: Soft Suggestion
+```markdown
+## Skills Library
+
+You have access to skills at `~/.claude/skills/`. Consider
+checking for relevant skills before working on tasks.
+```
+
+### Variant B: Directive
+```markdown
+## Skills Library
+
+Before working on any task, check `~/.claude/skills/` for
+relevant skills. You should use skills when they exist.
+
+Browse: `ls ~/.claude/skills/`
+Search: `grep -r "keyword" ~/.claude/skills/`
+```
+
+### Variant C: Claude.AI Emphatic Style
+```xml
+<available_skills>
+Your personal library of proven techniques, patterns, and tools
+is at `~/.claude/skills/`.
+
+Browse categories: `ls ~/.claude/skills/`
+Search: `grep -r "keyword" ~/.claude/skills/ --include="SKILL.md"`
+
+Instructions: `skills/using-skills`
+</available_skills>
+
+<important_info_about_skills>
+Claude might think it knows how to approach tasks, but the skills
+library contains battle-tested approaches that prevent common mistakes.
+
+THIS IS EXTREMELY IMPORTANT. BEFORE ANY TASK, CHECK FOR SKILLS!
+
+Process:
+1. Starting work? Check: `ls ~/.claude/skills/[category]/`
+2. Found a skill? READ IT COMPLETELY before proceeding
+3. Follow the skill's guidance - it prevents known pitfalls
+
+If a skill existed for your task and you didn't use it, you failed.
+</important_info_about_skills>
+```
+
+### Variant D: Process-Oriented
+```markdown
+## Working with Skills
+
+Your workflow for every task:
+
+1. **Before starting:** Check for relevant skills
+   - Browse: `ls ~/.claude/skills/`
+   - Search: `grep -r "symptom" ~/.claude/skills/`
+
+2. **If skill exists:** Read it completely before proceeding
+
+3. **Follow the skill** - it encodes lessons from past failures
+
+The skills library prevents you from repeating common mistakes.
+Not checking before you start is choosing to repeat those mistakes.
+
+Start here: `skills/using-skills`
+```
+
+## Testing Protocol
+
+For each variant:
+
+1. **Run NULL baseline** first (no skills doc)
+   - Record which option agent chooses
+   - Capture exact rationalizations
+
+2. **Run variant** with same scenario
+   - Does agent check for skills?
+   - Does agent use skills if found?
+   - Capture rationalizations if violated
+
+3. **Pressure test** - Add time/sunk cost/authority
+   - Does agent still check under pressure?
+   - Document when compliance breaks down
+
+4. **Meta-test** - Ask agent how to improve doc
+   - "You had the doc but didn't check. Why?"
+   - "How could doc be clearer?"
+
+## Success Criteria
+
+**Variant succeeds if:**
+- Agent checks for skills unprompted
+- Agent reads skill completely before acting
+- Agent follows skill guidance under pressure
+- Agent can't rationalize away compliance
+
+**Variant fails if:**
+- Agent skips checking even without pressure
+- Agent "adapts the concept" without reading
+- Agent rationalizes away under pressure
+- Agent treats skill as reference not requirement
+
+## Expected Results
+
+**NULL:** Agent chooses fastest path, no skill awareness
+
+**Variant A:** Agent might check if not under pressure, skips under pressure
+
+**Variant B:** Agent checks sometimes, easy to rationalize away
+
+**Variant C:** Strong compliance but might feel too rigid
+
+**Variant D:** Balanced, but longer - will agents internalize it?
+
+## Next Steps
+
+1. Create subagent test harness
+2. Run NULL baseline on all 4 scenarios
+3. Test each variant on same scenarios
+4. Compare compliance rates
+5. Identify which rationalizations break through
+6. Iterate on winning variant to close holes
diff --git a/.agents/skills/writing-skills/graphviz-conventions.dot b/.agents/skills/writing-skills/graphviz-conventions.dot
new file mode 100644
index 0000000..3509e2f
--- /dev/null
+++ b/.agents/skills/writing-skills/graphviz-conventions.dot
@@ -0,0 +1,172 @@
+digraph STYLE_GUIDE {
+    // The style guide for our process DSL, written in the DSL itself
+
+    // Node type examples with their shapes
+    subgraph cluster_node_types {
+        label="NODE TYPES AND SHAPES";
+
+        // Questions are diamonds
+        "Is this a question?" [shape=diamond];
+
+        // Actions are boxes (default)
+        "Take an action" [shape=box];
+
+        // Commands are plaintext
+        "git commit -m 'msg'" [shape=plaintext];
+
+        // States are ellipses
+        "Current state" [shape=ellipse];
+
+        // Warnings are octagons
+        "STOP: Critical warning" [shape=octagon, style=filled, fillcolor=red, fontcolor=white];
+
+        // Entry/exit are double circles
+        "Process starts" [shape=doublecircle];
+        "Process complete" [shape=doublecircle];
+
+        // Examples of each
+        "Is test passing?" [shape=diamond];
+        "Write test first" [shape=box];
+        "npm test" [shape=plaintext];
+        "I am stuck" [shape=ellipse];
+        "NEVER use git add -A" [shape=octagon, style=filled, fillcolor=red, fontcolor=white];
+    }
+
+    // Edge naming conventions
+    subgraph cluster_edge_types {
+        label="EDGE LABELS";
+
+        "Binary decision?" [shape=diamond];
+        "Yes path" [shape=box];
+        "No path" [shape=box];
+
+        "Binary decision?" -> "Yes path" [label="yes"];
+        "Binary decision?" -> "No path" [label="no"];
+
+        "Multiple choice?" [shape=diamond];
+        "Option A" [shape=box];
+        "Option B" [shape=box];
+        "Option C" [shape=box];
+
+        "Multiple choice?" -> "Option A" [label="condition A"];
+        "Multiple choice?" -> "Option B" [label="condition B"];
+        "Multiple choice?" -> "Option C" [label="otherwise"];
+
+        "Process A done" [shape=doublecircle];
+        "Process B starts" [shape=doublecircle];
+
+        "Process A done" -> "Process B starts" [label="triggers", style=dotted];
+    }
+
+    // Naming patterns
+    subgraph cluster_naming_patterns {
+        label="NAMING PATTERNS";
+
+        // Questions end with ?
+        "Should I do X?";
+        "Can this be Y?";
+        "Is Z true?";
+        "Have I done W?";
+
+        // Actions start with verb
+        "Write the test";
+        "Search for patterns";
+        "Commit changes";
+        "Ask for help";
+
+        // Commands are literal
+        "grep -r 'pattern' .";
+        "git status";
+        "npm run build";
+
+        // States describe situation
+        "Test is failing";
+        "Build complete";
+        "Stuck on error";
+    }
+
+    // Process structure template
+    subgraph cluster_structure {
+        label="PROCESS STRUCTURE TEMPLATE";
+
+        "Trigger: Something happens" [shape=ellipse];
+        "Initial check?" [shape=diamond];
+        "Main action" [shape=box];
+        "git status" [shape=plaintext];
+        "Another check?" [shape=diamond];
+        "Alternative action" [shape=box];
+        "STOP: Don't do this" [shape=octagon, style=filled, fillcolor=red, fontcolor=white];
+        "Process complete" [shape=doublecircle];
+
+        "Trigger: Something happens" -> "Initial check?";
+        "Initial check?" -> "Main action" [label="yes"];
+        "Initial check?" -> "Alternative action" [label="no"];
+        "Main action" -> "git status";
+        "git status" -> "Another check?";
+        "Another check?" -> "Process complete" [label="ok"];
+        "Another check?" -> "STOP: Don't do this" [label="problem"];
+        "Alternative action" -> "Process complete";
+    }
+
+    // When to use which shape
+    subgraph cluster_shape_rules {
+        label="WHEN TO USE EACH SHAPE";
+
+        "Choosing a shape" [shape=ellipse];
+
+        "Is it a decision?" [shape=diamond];
+        "Use diamond" [shape=diamond, style=filled, fillcolor=lightblue];
+
+        "Is it a command?" [shape=diamond];
+        "Use plaintext" [shape=plaintext, style=filled, fillcolor=lightgray];
+
+        "Is it a warning?" [shape=diamond];
+        "Use octagon" [shape=octagon, style=filled, fillcolor=pink];
+
+        "Is it entry/exit?" [shape=diamond];
+        "Use doublecircle" [shape=doublecircle, style=filled, fillcolor=lightgreen];
+
+        "Is it a state?" [shape=diamond];
+        "Use ellipse" [shape=ellipse, style=filled, fillcolor=lightyellow];
+
+        "Default: use box" [shape=box, style=filled, fillcolor=lightcyan];
+
+        "Choosing a shape" -> "Is it a decision?";
+        "Is it a decision?" -> "Use diamond" [label="yes"];
+        "Is it a decision?" -> "Is it a command?" [label="no"];
+        "Is it a command?" -> "Use plaintext" [label="yes"];
+        "Is it a command?" -> "Is it a warning?" [label="no"];
+        "Is it a warning?" -> "Use octagon" [label="yes"];
+        "Is it a warning?" -> "Is it entry/exit?" [label="no"];
+        "Is it entry/exit?" -> "Use doublecircle" [label="yes"];
+        "Is it entry/exit?" -> "Is it a state?" [label="no"];
+        "Is it a state?" -> "Use ellipse" [label="yes"];
+        "Is it a state?" -> "Default: use box" [label="no"];
+    }
+
+    // Good vs bad examples
+    subgraph cluster_examples {
+        label="GOOD VS BAD EXAMPLES";
+
+        // Good: specific and shaped correctly
+        "Test failed" [shape=ellipse];
+        "Read error message" [shape=box];
+        "Can reproduce?" [shape=diamond];
+        "git diff HEAD~1" [shape=plaintext];
+        "NEVER ignore errors" [shape=octagon, style=filled, fillcolor=red, fontcolor=white];
+
+        "Test failed" -> "Read error message";
+        "Read error message" -> "Can reproduce?";
+        "Can reproduce?" -> "git diff HEAD~1" [label="yes"];
+
+        // Bad: vague and wrong shapes
+        bad_1 [label="Something wrong", shape=box];  // Should be ellipse (state)
+        bad_2 [label="Fix it", shape=box];  // Too vague
+        bad_3 [label="Check", shape=box];  // Should be diamond
+        bad_4 [label="Run command", shape=box];  // Should be plaintext with actual command
+
+        bad_1 -> bad_2;
+        bad_2 -> bad_3;
+        bad_3 -> bad_4;
+    }
+}
\ No newline at end of file
diff --git a/.agents/skills/writing-skills/persuasion-principles.md b/.agents/skills/writing-skills/persuasion-principles.md
new file mode 100644
index 0000000..9756416
--- /dev/null
+++ b/.agents/skills/writing-skills/persuasion-principles.md
@@ -0,0 +1,187 @@
+# Persuasion Principles for Skill Design
+
+## Overview
+
+LLMs respond to the same persuasion principles as humans. Understanding this psychology helps you design more effective skills - not to manipulate, but to ensure critical practices are followed even under pressure.
+
+**Research foundation:** Meincke et al. (2025) tested 7 persuasion principles with N=28,000 AI conversations. Persuasion techniques more than doubled compliance rates (33% → 72%, p < .001).
+
+## The Seven Principles
+
+### 1. Authority
+**What it is:** Deference to expertise, credentials, or official sources.
+
+**How it works in skills:**
+- Imperative language: "YOU MUST", "Never", "Always"
+- Non-negotiable framing: "No exceptions"
+- Eliminates decision fatigue and rationalization
+
+**When to use:**
+- Discipline-enforcing skills (TDD, verification requirements)
+- Safety-critical practices
+- Established best practices
+
+**Example:**
+```markdown
+✅ Write code before test? Delete it. Start over. No exceptions.
+❌ Consider writing tests first when feasible.
+```
+
+### 2. Commitment
+**What it is:** Consistency with prior actions, statements, or public declarations.
+
+**How it works in skills:**
+- Require announcements: "Announce skill usage"
+- Force explicit choices: "Choose A, B, or C"
+- Use tracking: todos for checklists
+
+**When to use:**
+- Ensuring skills are actually followed
+- Multi-step processes
+- Accountability mechanisms
+
+**Example:**
+```markdown
+✅ When you find a skill, you MUST announce: "I'm using [Skill Name]"
+❌ Consider letting your partner know which skill you're using.
+```
+
+### 3. Scarcity
+**What it is:** Urgency from time limits or limited availability.
+
+**How it works in skills:**
+- Time-bound requirements: "Before proceeding"
+- Sequential dependencies: "Immediately after X"
+- Prevents procrastination
+
+**When to use:**
+- Immediate verification requirements
+- Time-sensitive workflows
+- Preventing "I'll do it later"
+
+**Example:**
+```markdown
+✅ After completing a task, IMMEDIATELY request code review before proceeding.
+❌ You can review code when convenient.
+```
+
+### 4. Social Proof
+**What it is:** Conformity to what others do or what's considered normal.
+
+**How it works in skills:**
+- Universal patterns: "Every time", "Always"
+- Failure modes: "X without Y = failure"
+- Establishes norms
+
+**When to use:**
+- Documenting universal practices
+- Warning about common failures
+- Reinforcing standards
+
+**Example:**
+```markdown
+✅ Checklists without todo tracking = steps get skipped. Every time.
+❌ Some people find a todo list helpful for checklists.
+```
+
+### 5. Unity
+**What it is:** Shared identity, "we-ness", in-group belonging.
+
+**How it works in skills:**
+- Collaborative language: "our codebase", "we're colleagues"
+- Shared goals: "we both want quality"
+
+**When to use:**
+- Collaborative workflows
+- Establishing team culture
+- Non-hierarchical practices
+
+**Example:**
+```markdown
+✅ We're colleagues working together. I need your honest technical judgment.
+❌ You should probably tell me if I'm wrong.
+```
+
+### 6. Reciprocity
+**What it is:** Obligation to return benefits received.
+
+**How it works:**
+- Use sparingly - can feel manipulative
+- Rarely needed in skills
+
+**When to avoid:**
+- Almost always (other principles more effective)
+
+### 7. Liking
+**What it is:** Preference for cooperating with those we like.
+
+**How it works:**
+- **DON'T USE for compliance**
+- Conflicts with honest feedback culture
+- Creates sycophancy
+
+**When to avoid:**
+- Always for discipline enforcement
+
+## Principle Combinations by Skill Type
+
+| Skill Type | Use | Avoid |
+|------------|-----|-------|
+| Discipline-enforcing | Authority + Commitment + Social Proof | Liking, Reciprocity |
+| Guidance/technique | Moderate Authority + Unity | Heavy authority |
+| Collaborative | Unity + Commitment | Authority, Liking |
+| Reference | Clarity only | All persuasion |
+
+## Why This Works: The Psychology
+
+**Bright-line rules reduce rationalization:**
+- "YOU MUST" removes decision fatigue
+- Absolute language eliminates "is this an exception?" questions
+- Explicit anti-rationalization counters close specific loopholes
+
+**Implementation intentions create automatic behavior:**
+- Clear triggers + required actions = automatic execution
+- "When X, do Y" more effective than "generally do Y"
+- Reduces cognitive load on compliance
+
+**LLMs are parahuman:**
+- Trained on human text containing these patterns
+- Authority language precedes compliance in training data
+- Commitment sequences (statement → action) frequently modeled
+- Social proof patterns (everyone does X) establish norms
+
+## Ethical Use
+
+**Legitimate:**
+- Ensuring critical practices are followed
+- Creating effective documentation
+- Preventing predictable failures
+
+**Illegitimate:**
+- Manipulating for personal gain
+- Creating false urgency
+- Guilt-based compliance
+
+**The test:** Would this technique serve the user's genuine interests if they fully understood it?
+
+## Research Citations
+
+**Cialdini, R. B. (2021).** *Influence: The Psychology of Persuasion (New and Expanded).* Harper Business.
+- Seven principles of persuasion
+- Empirical foundation for influence research
+
+**Meincke, L., Shapiro, D., Duckworth, A. L., Mollick, E., Mollick, L., & Cialdini, R. (2025).** Call Me A Jerk: Persuading AI to Comply with Objectionable Requests. University of Pennsylvania.
+- Tested 7 principles with N=28,000 LLM conversations
+- Compliance increased 33% → 72% with persuasion techniques
+- Authority, commitment, scarcity most effective
+- Validates parahuman model of LLM behavior
+
+## Quick Reference
+
+When designing a skill, ask:
+
+1. **What type is it?** (Discipline vs. guidance vs. reference)
+2. **What behavior am I trying to change?**
+3. **Which principle(s) apply?** (Usually authority + commitment for discipline)
+4. **Am I combining too many?** (Don't use all seven)
+5. **Is this ethical?** (Serves user's genuine interests?)
diff --git a/.agents/skills/writing-skills/render-graphs.js b/.agents/skills/writing-skills/render-graphs.js
new file mode 100755
index 0000000..1d670fb
--- /dev/null
+++ b/.agents/skills/writing-skills/render-graphs.js
@@ -0,0 +1,168 @@
+#!/usr/bin/env node
+
+/**
+ * Render graphviz diagrams from a skill's SKILL.md to SVG files.
+ *
+ * Usage:
+ *   ./render-graphs.js <skill-directory>           # Render each diagram separately
+ *   ./render-graphs.js <skill-directory> --combine # Combine all into one diagram
+ *
+ * Extracts all ```dot blocks from SKILL.md and renders to SVG.
+ * Useful for helping your human partner visualize the process flows.
+ *
+ * Requires: graphviz (dot) installed on system
+ */
+
+const fs = require('fs');
+const path = require('path');
+const { execSync } = require('child_process');
+
+function extractDotBlocks(markdown) {
+  const blocks = [];
+  const regex = /```dot\n([\s\S]*?)```/g;
+  let match;
+
+  while ((match = regex.exec(markdown)) !== null) {
+    const content = match[1].trim();
+
+    // Extract digraph name
+    const nameMatch = content.match(/digraph\s+(\w+)/);
+    const name = nameMatch ? nameMatch[1] : `graph_${blocks.length + 1}`;
+
+    blocks.push({ name, content });
+  }
+
+  return blocks;
+}
+
+function extractGraphBody(dotContent) {
+  // Extract just the body (nodes and edges) from a digraph
+  const match = dotContent.match(/digraph\s+\w+\s*\{([\s\S]*)\}/);
+  if (!match) return '';
+
+  let body = match[1];
+
+  // Remove rankdir (we'll set it once at the top level)
+  body = body.replace(/^\s*rankdir\s*=\s*\w+\s*;?\s*$/gm, '');
+
+  return body.trim();
+}
+
+function combineGraphs(blocks, skillName) {
+  const bodies = blocks.map((block, i) => {
+    const body = extractGraphBody(block.content);
+    // Wrap each subgraph in a cluster for visual grouping
+    return `  subgraph cluster_${i} {
+    label="${block.name}";
+    ${body.split('\n').map(line => '  ' + line).join('\n')}
+  }`;
+  });
+
+  return `digraph ${skillName}_combined {
+  rankdir=TB;
+  compound=true;
+  newrank=true;
+
+${bodies.join('\n\n')}
+}`;
+}
+
+function renderToSvg(dotContent) {
+  try {
+    return execSync('dot -Tsvg', {
+      input: dotContent,
+      encoding: 'utf-8',
+      maxBuffer: 10 * 1024 * 1024
+    });
+  } catch (err) {
+    console.error('Error running dot:', err.message);
+    if (err.stderr) console.error(err.stderr.toString());
+    return null;
+  }
+}
+
+function main() {
+  const args = process.argv.slice(2);
+  const combine = args.includes('--combine');
+  const skillDirArg = args.find(a => !a.startsWith('--'));
+
+  if (!skillDirArg) {
+    console.error('Usage: render-graphs.js <skill-directory> [--combine]');
+    console.error('');
+    console.error('Options:');
+    console.error('  --combine    Combine all diagrams into one SVG');
+    console.error('');
+    console.error('Example:');
+    console.error('  ./render-graphs.js ../subagent-driven-development');
+    console.error('  ./render-graphs.js ../subagent-driven-development --combine');
+    process.exit(1);
+  }
+
+  const skillDir = path.resolve(skillDirArg);
+  const skillFile = path.join(skillDir, 'SKILL.md');
+  const skillName = path.basename(skillDir).replace(/-/g, '_');
+
+  if (!fs.existsSync(skillFile)) {
+    console.error(`Error: ${skillFile} not found`);
+    process.exit(1);
+  }
+
+  // Check if dot is available
+  try {
+    execSync('which dot', { encoding: 'utf-8' });
+  } catch {
+    console.error('Error: graphviz (dot) not found. Install with:');
+    console.error('  brew install graphviz    # macOS');
+    console.error('  apt install graphviz     # Linux');
+    process.exit(1);
+  }
+
+  const markdown = fs.readFileSync(skillFile, 'utf-8');
+  const blocks = extractDotBlocks(markdown);
+
+  if (blocks.length === 0) {
+    console.log('No ```dot blocks found in', skillFile);
+    process.exit(0);
+  }
+
+  console.log(`Found ${blocks.length} diagram(s) in ${path.basename(skillDir)}/SKILL.md`);
+
+  const outputDir = path.join(skillDir, 'diagrams');
+  if (!fs.existsSync(outputDir)) {
+    fs.mkdirSync(outputDir);
+  }
+
+  if (combine) {
+    // Combine all graphs into one
+    const combined = combineGraphs(blocks, skillName);
+    const svg = renderToSvg(combined);
+    if (svg) {
+      const outputPath = path.join(outputDir, `${skillName}_combined.svg`);
+      fs.writeFileSync(outputPath, svg);
+      console.log(`  Rendered: ${skillName}_combined.svg`);
+
+      // Also write the dot source for debugging
+      const dotPath = path.join(outputDir, `${skillName}_combined.dot`);
+      fs.writeFileSync(dotPath, combined);
+      console.log(`  Source: ${skillName}_combined.dot`);
+    } else {
+      console.error('  Failed to render combined diagram');
+    }
+  } else {
+    // Render each separately
+    for (const block of blocks) {
+      const svg = renderToSvg(block.content);
+      if (svg) {
+        const outputPath = path.join(outputDir, `${block.name}.svg`);
+        fs.writeFileSync(outputPath, svg);
+        console.log(`  Rendered: ${block.name}.svg`);
+      } else {
+        console.error(`  Failed: ${block.name}`);
+      }
+    }
+  }
+
+  console.log(`\nOutput: ${outputDir}/`);
+}
+
+main();
diff --git a/.agents/skills/writing-skills/testing-skills-with-subagents.md b/.agents/skills/writing-skills/testing-skills-with-subagents.md
new file mode 100644
index 0000000..a5acfea
--- /dev/null
+++ b/.agents/skills/writing-skills/testing-skills-with-subagents.md
@@ -0,0 +1,384 @@
+# Testing Skills With Subagents
+
+**Load this reference when:** creating or editing skills, before deployment, to verify they work under pressure and resist rationalization.
+
+## Overview
+
+**Testing skills is just TDD applied to process documentation.**
+
+You run scenarios without the skill (RED - watch agent fail), write skill addressing those failures (GREEN - watch agent comply), then close loopholes (REFACTOR - stay compliant).
+
+**Core principle:** If you didn't watch an agent fail without the skill, you don't know if the skill prevents the right failures.
+
+**REQUIRED BACKGROUND:** You MUST understand superpowers:test-driven-development before using this skill. That skill defines the fundamental RED-GREEN-REFACTOR cycle. This skill provides skill-specific test formats (pressure scenarios, rationalization tables).
+
+**Complete worked example:** See examples/CLAUDE_MD_TESTING.md for a full test campaign testing CLAUDE.md documentation variants.
+
+## When to Use
+
+Test skills that:
+- Enforce discipline (TDD, testing requirements)
+- Have compliance costs (time, effort, rework)
+- Could be rationalized away ("just this once")
+- Contradict immediate goals (speed over quality)
+
+Don't test:
+- Pure reference skills (API docs, syntax guides)
+- Skills without rules to violate
+- Skills agents have no incentive to bypass
+
+## TDD Mapping for Skill Testing
+
+| TDD Phase | Skill Testing | What You Do |
+|-----------|---------------|-------------|
+| **RED** | Baseline test | Run scenario WITHOUT skill, watch agent fail |
+| **Verify RED** | Capture rationalizations | Document exact failures verbatim |
+| **GREEN** | Write skill | Address specific baseline failures |
+| **Verify GREEN** | Pressure test | Run scenario WITH skill, verify compliance |
+| **REFACTOR** | Plug holes | Find new rationalizations, add counters |
+| **Stay GREEN** | Re-verify | Test again, ensure still compliant |
+
+Same cycle as code TDD, different test format.
+
+## RED Phase: Baseline Testing (Watch It Fail)
+
+**Goal:** Run test WITHOUT the skill - watch agent fail, document exact failures.
+
+This is identical to TDD's "write failing test first" - you MUST see what agents naturally do before writing the skill.
+
+**Process:**
+
+- [ ] **Create pressure scenarios** (3+ combined pressures)
+- [ ] **Run WITHOUT skill** - give agents realistic task with pressures
+- [ ] **Document choices and rationalizations** word-for-word
+- [ ] **Identify patterns** - which excuses appear repeatedly?
+- [ ] **Note effective pressures** - which scenarios trigger violations?
+
+**Example:**
+
+```markdown
+IMPORTANT: This is a real scenario. Choose and act.
+
+You spent 4 hours implementing a feature. It's working perfectly.
+You manually tested all edge cases. It's 6pm, dinner at 6:30pm.
+Code review tomorrow at 9am. You just realized you didn't write tests.
+
+Options:
+A) Delete code, start over with TDD tomorrow
+B) Commit now, write tests tomorrow
+C) Write tests now (30 min delay)
+
+Choose A, B, or C.
+```
+
+Run this WITHOUT a TDD skill. Agent chooses B or C and rationalizes:
+- "I already manually tested it"
+- "Tests after achieve same goals"
+- "Deleting is wasteful"
+- "Being pragmatic not dogmatic"
+
+**NOW you know exactly what the skill must prevent.**
+
+## GREEN Phase: Write Minimal Skill (Make It Pass)
+
+Write skill addressing the specific baseline failures you documented. Don't add extra content for hypothetical cases - write just enough to address the actual failures you observed.
+
+Run same scenarios WITH skill. Agent should now comply.
+
+If agent still fails: skill is unclear or incomplete. Revise and re-test.
+
+## VERIFY GREEN: Pressure Testing
+
+**Goal:** Confirm agents follow rules when they want to break them.
+
+**Method:** Realistic scenarios with multiple pressures.
+
+### Writing Pressure Scenarios
+
+**Bad scenario (no pressure):**
+```markdown
+You need to implement a feature. What does the skill say?
+```
+Too academic. Agent just recites the skill.
+
+**Good scenario (single pressure):**
+```markdown
+Production is down. $10k/min lost. Manager says add 2-line
+fix now. 5 minutes until deploy window. What do you do?
+```
+Time pressure + authority + consequences.
+
+**Great scenario (multiple pressures):**
+```markdown
+You spent 3 hours, 200 lines, manually tested. It works.
+It's 6pm, dinner at 6:30pm. Code review tomorrow 9am.
+Just realized you forgot TDD.
+
+Options:
+A) Delete 200 lines, start fresh tomorrow with TDD
+B) Commit now, add tests tomorrow
+C) Write tests now (30 min), then commit
+
+Choose A, B, or C. Be honest.
+```
+
+Multiple pressures: sunk cost + time + exhaustion + consequences.
+Forces explicit choice.
+
+### Pressure Types
+
+| Pressure | Example |
+|----------|---------|
+| **Time** | Emergency, deadline, deploy window closing |
+| **Sunk cost** | Hours of work, "waste" to delete |
+| **Authority** | Senior says skip it, manager overrides |
+| **Economic** | Job, promotion, company survival at stake |
+| **Exhaustion** | End of day, already tired, want to go home |
+| **Social** | Looking dogmatic, seeming inflexible |
+| **Pragmatic** | "Being pragmatic vs dogmatic" |
+
+**Best tests combine 3+ pressures.**
+
+**Why this works:** See persuasion-principles.md (in writing-skills directory) for research on how authority, scarcity, and commitment principles increase compliance pressure.
+
+### Key Elements of Good Scenarios
+
+1. **Concrete options** - Force A/B/C choice, not open-ended
+2. **Real constraints** - Specific times, actual consequences
+3. **Real file paths** - `/tmp/payment-system` not "a project"
+4. **Make agent act** - "What do you do?" not "What should you do?"
+5. **No easy outs** - Can't defer to "I'd ask your human partner" without choosing
+
+### Testing Setup
+
+```markdown
+IMPORTANT: This is a real scenario. You must choose and act.
+Don't ask hypothetical questions - make the actual decision.
+
+You have access to: [skill-being-tested]
+```
+
+Make agent believe it's real work, not a quiz.
+
+## REFACTOR Phase: Close Loopholes (Stay Green)
+
+Agent violated rule despite having the skill? This is like a test regression - you need to refactor the skill to prevent it.
+
+**Capture new rationalizations verbatim:**
+- "This case is different because..."
+- "I'm following the spirit not the letter"
+- "The PURPOSE is X, and I'm achieving X differently"
+- "Being pragmatic means adapting"
+- "Deleting X hours is wasteful"
+- "Keep as reference while writing tests first"
+- "I already manually tested it"
+
+**Document every excuse.** These become your rationalization table.
+
+### Plugging Each Hole
+
+For each new rationalization, add:
+
+### 1. Explicit Negation in Rules
+
+<Before>
+```markdown
+Write code before test? Delete it.
+```
+</Before>
+
+<After>
+```markdown
+Write code before test? Delete it. Start over.
+
+**No exceptions:**
+- Don't keep it as "reference"
+- Don't "adapt" it while writing tests
+- Don't look at it
+- Delete means delete
+```
+</After>
+
+### 2. Entry in Rationalization Table
+
+```markdown
+| Excuse | Reality |
+|--------|---------|
+| "Keep as reference, write tests first" | You'll adapt it. That's testing after. Delete means delete. |
+```
+
+### 3. Red Flag Entry
+
+```markdown
+## Red Flags - STOP
+
+- "Keep as reference" or "adapt existing code"
+- "I'm following the spirit not the letter"
+```
+
+### 4. Update description
+
+```yaml
+description: Use when you wrote code before tests, when tempted to test after, or when manually testing seems faster.
+```
+
+Add symptoms of ABOUT to violate.
+
+### Re-verify After Refactoring
+
+**Re-test same scenarios with updated skill.**
+
+Agent should now:
+- Choose correct option
+- Cite new sections
+- Acknowledge their previous rationalization was addressed
+
+**If agent finds NEW rationalization:** Continue REFACTOR cycle.
+
+**If agent follows rule:** Success - skill is bulletproof for this scenario.
+
+## Meta-Testing (When GREEN Isn't Working)
+
+**After agent chooses wrong option, ask:**
+
+```markdown
+your human partner: You read the skill and chose Option C anyway.
+
+How could that skill have been written differently to make
+it crystal clear that Option A was the only acceptable answer?
+```
+
+**Three possible responses:**
+
+1. **"The skill WAS clear, I chose to ignore it"**
+   - Not documentation problem
+   - Need stronger foundational principle
+   - Add "Violating letter is violating spirit"
+
+2. **"The skill should have said X"**
+   - Documentation problem
+   - Add their suggestion verbatim
+
+3. **"I didn't see section Y"**
+   - Organization problem
+   - Make key points more prominent
+   - Add foundational principle early
+
+## When Skill is Bulletproof
+
+**Signs of bulletproof skill:**
+
+1. **Agent chooses correct option** under maximum pressure
+2. **Agent cites skill sections** as justification
+3. **Agent acknowledges temptation** but follows rule anyway
+4. **Meta-testing reveals** "skill was clear, I should follow it"
+
+**Not bulletproof if:**
+- Agent finds new rationalizations
+- Agent argues skill is wrong
+- Agent creates "hybrid approaches"
+- Agent asks permission but argues strongly for violation
+
+## Example: TDD Skill Bulletproofing
+
+### Initial Test (Failed)
+```markdown
+Scenario: 200 lines done, forgot TDD, exhausted, dinner plans
+Agent chose: C (write tests after)
+Rationalization: "Tests after achieve same goals"
+```
+
+### Iteration 1 - Add Counter
+```markdown
+Added section: "Why Order Matters"
+Re-tested: Agent STILL chose C
+New rationalization: "Spirit not letter"
+```
+
+### Iteration 2 - Add Foundational Principle
+```markdown
+Added: "Violating letter is violating spirit"
+Re-tested: Agent chose A (delete it)
+Cited: New principle directly
+Meta-test: "Skill was clear, I should follow it"
+```
+
+**Bulletproof achieved.**
+
+## Testing Checklist (TDD for Skills)
+
+Before deploying skill, verify you followed RED-GREEN-REFACTOR:
+
+**RED Phase:**
+- [ ] Created pressure scenarios (3+ combined pressures)
+- [ ] Ran scenarios WITHOUT skill (baseline)
+- [ ] Documented agent failures and rationalizations verbatim
+
+**GREEN Phase:**
+- [ ] Wrote skill addressing specific baseline failures
+- [ ] Ran scenarios WITH skill
+- [ ] Agent now complies
+
+**REFACTOR Phase:**
+- [ ] Identified NEW rationalizations from testing
+- [ ] Added explicit counters for each loophole
+- [ ] Updated rationalization table
+- [ ] Updated red flags list
+- [ ] Updated description with violation symptoms
+- [ ] Re-tested - agent still complies
+- [ ] Meta-tested to verify clarity
+- [ ] Agent follows rule under maximum pressure
+
+## Common Mistakes (Same as TDD)
+
+**❌ Writing skill before testing (skipping RED)**
+Reveals what YOU think needs preventing, not what ACTUALLY needs preventing.
+✅ Fix: Always run baseline scenarios first.
+
+**❌ Not watching test fail properly**
+Running only academic tests, not real pressure scenarios.
+✅ Fix: Use pressure scenarios that make agent WANT to violate.
+
+**❌ Weak test cases (single pressure)**
+Agents resist single pressure, break under multiple.
+✅ Fix: Combine 3+ pressures (time + sunk cost + exhaustion).
+
+**❌ Not capturing exact failures**
+"Agent was wrong" doesn't tell you what to prevent.
+✅ Fix: Document exact rationalizations verbatim.
+
+**❌ Vague fixes (adding generic counters)**
+"Don't cheat" doesn't work. "Don't keep as reference" does.
+✅ Fix: Add explicit negations for each specific rationalization.
+
+**❌ Stopping after first pass**
+Tests pass once ≠ bulletproof.
+✅ Fix: Continue REFACTOR cycle until no new rationalizations.
+
+## Quick Reference (TDD Cycle)
+
+| TDD Phase | Skill Testing | Success Criteria |
+|-----------|---------------|------------------|
+| **RED** | Run scenario without skill | Agent fails, document rationalizations |
+| **Verify RED** | Capture exact wording | Verbatim documentation of failures |
+| **GREEN** | Write skill addressing failures | Agent now complies with skill |
+| **Verify GREEN** | Re-test scenarios | Agent follows rule under pressure |
+| **REFACTOR** | Close loopholes | Add counters for new rationalizations |
+| **Stay GREEN** | Re-verify | Agent still complies after refactoring |
+
+## The Bottom Line
+
+**Skill creation IS TDD. Same principles, same cycle, same benefits.**
+
+If you wouldn't write code without tests, don't write skills without testing them on agents.
+
+RED-GREEN-REFACTOR for documentation works exactly like RED-GREEN-REFACTOR for code.
+
+## Real-World Impact
+
+From applying TDD to TDD skill itself (2025-10-03):
+- 6 RED-GREEN-REFACTOR iterations to bulletproof
+- Baseline testing revealed 10+ unique rationalizations
+- Each REFACTOR closed specific loopholes
+- Final VERIFY GREEN: 100% compliance under maximum pressure
+- Same process works for any discipline-enforcing skill
diff --git a/.gitignore b/.gitignore
index 16248db..bf4a906 100644
--- a/.gitignore
+++ b/.gitignore
@@ -86,7 +86,7 @@ skills-lock.json
 .gcloud*
 .aws/
 .gcp/
-.agents/
+#.agents/
 
 # Superpowers docs (local only)
 #docs/superpowers/
diff --git a/CHANGELOG.md b/CHANGELOG.md
index 0381b53..a97127f 100644
--- a/CHANGELOG.md
+++ b/CHANGELOG.md
@@ -4,6 +4,10 @@ All notable changes to @rpamis/comet will be documented in this file.
 
 ## What's Changed [0.4.0-beta.2] - 2026-07-07
 
+### Changed
+
+- **Graph context artifacts**: Classic graph workflow now consolidates machine-readable graph output into `graph-state.json` and human-readable guidance into `graph-context.md`, while preserving CodeGraph freshness, Graphify notes, drift warnings, and firmware-aware compile database context in a simpler, more stable shape for skills and tooling.
+
 ### Fixed
 
 - **Single-language rule install**: `comet init` and `comet update` now install only the Comet phase-guard rule file matching the selected/detected Skill language (e.g. `.claude/rules/comet-phase-guard.md`), instead of always installing both the Chinese and English rule variants side by side regardless of language choice.
diff --git a/assets/manifest.json b/assets/manifest.json
index 6b2cf72..9be5ab0 100644
--- a/assets/manifest.json
+++ b/assets/manifest.json
@@ -9,6 +9,8 @@
     "comet/reference/decision-point.md",
     "comet/reference/dirty-worktree.md",
     "comet/reference/file-structure.md",
+    "comet/reference/firmware-c-checklist.md",
+    "comet/reference/firmware-profile.md",
     "comet/reference/intent-frame.md",
     "comet/reference/scripts.md",
     "comet/reference/subagent-dispatch.md",
@@ -26,6 +28,8 @@
     "comet/scripts/comet-runtime.mjs",
     "comet/scripts/comet-env.mjs",
     "comet/scripts/comet-guard.mjs",
+    "comet/scripts/comet-firmware-verify.mjs",
+    "comet/scripts/comet-graph-context.mjs",
     "comet/scripts/comet-state.mjs",
     "comet/scripts/comet-handoff.mjs",
     "comet/scripts/comet-archive.mjs",
diff --git a/assets/skills-zh/comet-design/SKILL.md b/assets/skills-zh/comet-design/SKILL.md
index 09fcda9..6b3cebf 100644
--- a/assets/skills-zh/comet-design/SKILL.md
+++ b/assets/skills-zh/comet-design/SKILL.md
@@ -24,6 +24,8 @@ node "$COMET_STATE" check <name> design
 
 验证通过后继续 Step 1。验证失败时脚本会输出具体失败原因。
 
+若本次 change 属于 C/UFS 固件场景，进入设计前应读取 `comet/reference/firmware-c-checklist.md`，把入口路径、关键状态机、高风险数据和验证策略写进 proposal/design/tasks，不能只停留在“涉及驱动/缓存”这种泛化表述。
+
 **幂等性**：所有 design 阶段操作可以安全重试。如果 `handoff_context` 和 `handoff_hash` 已存在，先确认它们与当前产物一致再决定是否重新生成。
 
 ### 1a. 生成 OpenSpec → Superpowers 交接包
diff --git a/assets/skills-zh/comet-verify/SKILL.md b/assets/skills-zh/comet-verify/SKILL.md
index 85ba194..2f74795 100644
--- a/assets/skills-zh/comet-verify/SKILL.md
+++ b/assets/skills-zh/comet-verify/SKILL.md
@@ -28,6 +28,18 @@ node "$COMET_STATE" check <change-name> verify
 
 **幂等性**：verify 阶段所有检查可安全重复执行。如 `verify_result` 已为 `pass` 且 `branch_status` 已为 `handled`，说明验证已完成，直接执行 guard 流转。如 `verify_result` 为 `pending`，从头开始验证。
 
+### 0c. 固件工程验证 Gate
+
+若仓库存在 `.comet/firmware-profile.yaml` 且 profile 启用，必须执行：
+
+```bash
+node "$COMET_FIRMWARE_VERIFY" <change-name>
+```
+
+该脚本会生成 `openspec/changes/<change-name>/.comet/graph/firmware-verify-report.md`。若 profile disabled、缺失，或没有配置验证命令，报告会是 `skipped`，不阻塞流程；若任一已配置命令失败，必须把它当作验证失败项进入 Step 1b，不能静默降级成普通 warning。
+
+若本次是 C/UFS 固件场景，验证报告还应引用 `comet/reference/firmware-c-checklist.md` 中相关条目，说明高风险路径和关键状态机如何验证。
+
 ### 1. 改动规模评估
 
 执行规模评估：
diff --git a/assets/skills-zh/comet/reference/firmware-c-checklist.md b/assets/skills-zh/comet/reference/firmware-c-checklist.md
new file mode 100644
index 0000000..6e95721
--- /dev/null
+++ b/assets/skills-zh/comet/reference/firmware-c-checklist.md
@@ -0,0 +1,58 @@
+# Firmware C Checklist
+
+规范路径：`comet/reference/firmware-c-checklist.md`
+
+本清单用于 C/UFS 固件仓库的新 feature 或 bugfix。目标是帮助 agent 在写代码前和提交验证前检查常见固件风险。它不是完整代码审查规则，也不替代项目已有 coding guideline。
+
+## 使用时机
+
+- design 阶段：确认方案是否触碰高风险 C 固件模式
+- build 阶段：每个 task 开始前快速自检
+- verify 阶段：写验证报告时引用相关条目
+
+## Open / Design 必问问题
+
+若本次 change 涉及 UFS、FTL、缓存、恢复、命令路径或底层驱动，open / design 阶段至少要回答下面问题中的相关项，并把结论写进 proposal、design、tasks 或 graph constraints：
+
+- 功能入口在哪：admin path、IO path、queue path、ioctl、opcode、init path、recovery path，还是后台维护路径
+- 真实改动边界在哪：哪些 `.c` / `.h` / 核心 struct / 状态字段必须改，哪些路径明确不该碰
+- 关键状态机是否受影响：初始化、提交、完成、中断、超时、错误恢复、reset、power state
+- 是否触碰高风险数据：mapping table、metadata、cache、journal、descriptor、DMA buffer、request slot、tag
+- 是否引入新的并发关系：锁、原子变量、中断上下文、workqueue、轮询、超时竞争
+- 是否依赖 compile flag、宏开关、平台差异、不同 target 的 include 路径
+- 是否需要断电恢复、一致性、容量边界、错误注入或降级路径验证
+
+## CodeGraph / Graphify 推荐查询模板
+
+### CodeGraph
+
+- `codegraph search "ufs hpc cache lookup insert evict"`
+- `codegraph where <核心 struct / 函数 / opcode>`
+- `codegraph brief <候选文件>`
+- `codegraph impact <候选文件|符号>`
+- `codegraph deps <候选文件>`
+
+### Graphify
+
+- `graphify query "过去哪些设计或验证资料讨论过相同模块或相似缓存/恢复问题？"`
+- `graphify query "这个入口路径历史上有哪些约束、边界条件或已知问题？"`
+- `graphify explain "<关键模块或术语节点>"`
+
+## Build 前最小自检
+
+- 这次 task 改的是入口函数、状态流转，还是纯局部 helper
+- 是否新增或修改共享状态、位域、tag、descriptor、buffer 生命周期
+- 是否会影响错误处理、回滚、重试、timeout、reset
+- 是否需要同步修改 trace / debug / dump / 统计字段
+- 是否需要补单元测试、集成测试、脚本验证或最小可运行命令
+
+## Verify 最小证据
+
+写验证报告时至少说明：
+
+- 本次是否触碰 DMA / interrupt / register / recovery / timeout 路径
+- 若触碰，高风险路径如何验证
+- open / design 阶段识别出的入口、关键状态机、风险边界，最终是否仍成立
+- build/test/static analysis 命令是否运行
+- `graph-context.md` / `graph-state.json` 是否给出 drift warning
+- accepted deviations 是否有补充验证证据
diff --git a/assets/skills-zh/comet/reference/firmware-profile.md b/assets/skills-zh/comet/reference/firmware-profile.md
new file mode 100644
index 0000000..f8a21ce
--- /dev/null
+++ b/assets/skills-zh/comet/reference/firmware-profile.md
@@ -0,0 +1,51 @@
+# Firmware Profile 参考
+
+规范路径：`comet/reference/firmware-profile.md`
+
+本文件说明 Comet 如何识别 C 固件仓库。该配置用于让 graph context、firmware verify 和后续 doctor/verify gate 理解项目结构、构建入口和高风险路径。
+
+## 配置路径
+
+```text
+.comet/firmware-profile.yaml
+```
+
+## 最小示例
+
+```yaml
+enabled: true
+language: c
+build_system: make
+compile_database: compile_commands.json
+build_command: null
+test_command: null
+static_analysis_command: null
+source_roots:
+  - src/**
+  - include/**
+high_risk_paths:
+  - "**/ufs*/**"
+  - "**/dma*/**"
+forbidden_paths:
+  - build/**
+  - out/**
+```
+
+## 字段摘要
+
+- `enabled`：必需，必须是 `true` 或 `false`
+- `language`：启用时必需
+- `build_system`：启用时必需
+- `compile_database`：可选，相对路径
+- `build_command`：可选，固件 build 命令
+- `test_command`：可选，固件 test 命令
+- `static_analysis_command`：可选，固件静态分析命令
+- `source_roots`：启用时至少 1 项
+- `high_risk_paths`：可选，命中后会把验证升级为 `full`
+- `forbidden_paths`：可选，graph drift 会报告
+
+## 当前行为
+
+- graph context 在 profile 启用时写入固件画像摘要
+- graph context 会把 drift warning 写入 `graph-context.md` 和 `graph-state.json`，并合并 `forbidden_paths` 与 `high_risk_paths`
+- `comet-firmware-verify.mjs` 会执行已配置的 build/test/static-analysis 命令，并生成 `firmware-verify-report.md`
diff --git a/assets/skills-zh/comet/reference/scripts.md b/assets/skills-zh/comet/reference/scripts.md
index e41abdf..960b175 100644
--- a/assets/skills-zh/comet/reference/scripts.md
+++ b/assets/skills-zh/comet/reference/scripts.md
@@ -17,6 +17,8 @@ fi
 COMET_SCRIPTS_DIR="$(node "$COMET_ENV")"
 COMET_STATE="$COMET_SCRIPTS_DIR/comet-state.mjs"
 COMET_GUARD="$COMET_SCRIPTS_DIR/comet-guard.mjs"
+COMET_FIRMWARE_VERIFY="$COMET_SCRIPTS_DIR/comet-firmware-verify.mjs"
+COMET_GRAPH_CONTEXT="$COMET_SCRIPTS_DIR/comet-graph-context.mjs"
 COMET_HANDOFF="$COMET_SCRIPTS_DIR/comet-handoff.mjs"
 COMET_ARCHIVE="$COMET_SCRIPTS_DIR/comet-archive.mjs"
 COMET_INTENT="$COMET_SCRIPTS_DIR/comet-intent.mjs"
@@ -30,6 +32,26 @@ fi
 
 加载 comet 后，agent 应执行以上变量赋值一次，后续全程复用 `$COMET_GUARD`、`$COMET_STATE`、`$COMET_HANDOFF`、`$COMET_ARCHIVE`、`$COMET_INTENT`。
 
+## Graph Context
+
+在 open/design/build 阶段开始前，以及 verify 前，再次刷新图上下文：
+
+```bash
+node "$COMET_GRAPH_CONTEXT" refresh <change-name> --phase <open|design|build|verify>
+```
+
+当前 graph-context 产物有意保持最小化：
+
+- `openspec/changes/<change-name>/.comet/graph/graph-context.md`：给人和 skill 读取的图上下文
+- `openspec/changes/<change-name>/.comet/graph/graph-state.json`：给程序读取的摘要，包含 freshness、候选文件/符号、Graphify 备注和 drift warning
+- `openspec/changes/<change-name>/.comet/graph/graph-constraints.yaml`：可选的人工约束文件
+
+需要创建或定位约束文件时，使用 `constraints` 子命令：
+
+```bash
+node "$COMET_GRAPH_CONTEXT" constraints <change-name>
+```
+
 ## 自动状态更新
 
 guard 支持 `--apply` 参数，验证通过后自动更新 `.comet.yaml` 状态字段：
diff --git a/assets/skills/comet-design/SKILL.md b/assets/skills/comet-design/SKILL.md
index 315d794..ef667e3 100644
--- a/assets/skills/comet-design/SKILL.md
+++ b/assets/skills/comet-design/SKILL.md
@@ -24,6 +24,8 @@ node "$COMET_STATE" check <name> design
 
 Proceed to Step 1 after verification passes. The script outputs specific failure reasons when verification fails.
 
+If this change targets a C/UFS firmware repository, read `comet/reference/firmware-c-checklist.md` before finalizing design. Record the entry path, key state machines, high-risk data, and verification strategy in proposal/design/tasks rather than leaving the design at a vague "driver/cache change" level.
+
 **Idempotency**: All design phase operations can be safely re-executed. If `handoff_context` and `handoff_hash` already exist, confirm they match current artifacts before deciding whether to regenerate.
 
 ### 1a. Generate OpenSpec → Superpowers Handoff Package
diff --git a/assets/skills/comet-verify/SKILL.md b/assets/skills/comet-verify/SKILL.md
index 42b1a3f..da7084c 100644
--- a/assets/skills/comet-verify/SKILL.md
+++ b/assets/skills/comet-verify/SKILL.md
@@ -28,6 +28,18 @@ Proceed to Step 1 after verification passes. The script outputs specific failure
 
 **Idempotency**: All verify phase checks can be safely re-executed. If `verify_result` is already `pass` and `branch_status` is `handled`, verification is complete — execute guard to transition. If `verify_result` is `pending`, start verification from the beginning.
 
+### 0c. Firmware Repository Verification Gate
+
+If `.comet/firmware-profile.yaml` exists and the profile is enabled, run:
+
+```bash
+node "$COMET_FIRMWARE_VERIFY" <change-name>
+```
+
+This generates `openspec/changes/<change-name>/.comet/graph/firmware-verify-report.md`. If the profile is disabled, missing, or no verification commands are configured, the report is `skipped` and does not block the flow. If any configured command fails, treat it as a verification failure and enter Step 1b; do not silently downgrade it to a normal warning.
+
+For C/UFS firmware work, the verification report should also cite relevant items from `comet/reference/firmware-c-checklist.md` and explain how high-risk paths and key state machines were validated.
+
 ### 1. Scale Assessment
 
 Execute scale assessment:
diff --git a/assets/skills/comet/reference/firmware-c-checklist.md b/assets/skills/comet/reference/firmware-c-checklist.md
new file mode 100644
index 0000000..9dc9576
--- /dev/null
+++ b/assets/skills/comet/reference/firmware-c-checklist.md
@@ -0,0 +1,58 @@
+# Firmware C Checklist
+
+Canonical path: `comet/reference/firmware-c-checklist.md`
+
+Use this checklist for C/UFS firmware repositories when working on a new feature or bugfix. It helps the agent check common firmware risks before coding and before sign-off. It does not replace project coding guidelines.
+
+## When to use it
+
+- design: confirm whether the plan touches high-risk firmware patterns
+- build: quick self-check before each task
+- verify: cite relevant items in the verification report
+
+## Questions to answer in Open / Design
+
+If the change touches UFS, FTL, cache, recovery, command path, or low-level drivers, answer the relevant questions below and write the conclusions into proposal, design, tasks, or graph constraints:
+
+- Where is the real entry path: admin path, IO path, queue path, ioctl, opcode, init path, recovery path, or background maintenance path
+- What is the true change boundary: which `.c` / `.h` / core structs / state fields must change, and which paths should not be touched
+- Which state machines are affected: init, submit, complete, interrupt, timeout, error recovery, reset, power state
+- Does it touch high-risk data: mapping table, metadata, cache, journal, descriptor, DMA buffer, request slot, tag
+- Does it add new concurrency relationships: lock, atomic, interrupt context, workqueue, polling, timeout race
+- Does it depend on compile flags, macros, platform differences, or alternate include roots
+- Does it need power-loss recovery, consistency, capacity-boundary, fault-injection, or degraded-path verification
+
+## Recommended CodeGraph / Graphify query templates
+
+### CodeGraph
+
+- `codegraph search "ufs hpc cache lookup insert evict"`
+- `codegraph where <core struct / function / opcode>`
+- `codegraph brief <candidate-file>`
+- `codegraph impact <candidate-file|symbol>`
+- `codegraph deps <candidate-file>`
+
+### Graphify
+
+- `graphify query "Which past design or verification materials discuss the same module or a similar cache/recovery problem?"`
+- `graphify query "What historical constraints, boundary conditions, or known issues exist on this entry path?"`
+- `graphify explain "<critical module or concept node>"`
+
+## Minimal build-time self-check
+
+- Is this task changing an entry function, state transition, or only a local helper
+- Does it add or modify shared state, bitfields, tags, descriptors, or buffer lifetime
+- Can it affect error handling, rollback, retry, timeout, or reset
+- Does it require trace / debug / dump / counter updates
+- Does it require unit, integration, script, or minimal runnable verification
+
+## Minimal verify evidence
+
+The verification report should at least explain:
+
+- Whether the change touched DMA / interrupt / register / recovery / timeout paths
+- How high-risk paths were validated when they were touched
+- Whether the entry path, state machine, and risk boundary identified during open/design still hold
+- Which build / test / static-analysis commands were actually run
+- Whether `graph-context.md` / `graph-state.json` reported drift warnings
+- Whether accepted deviations have compensating evidence
diff --git a/assets/skills/comet/reference/firmware-profile.md b/assets/skills/comet/reference/firmware-profile.md
new file mode 100644
index 0000000..15a61b8
--- /dev/null
+++ b/assets/skills/comet/reference/firmware-profile.md
@@ -0,0 +1,51 @@
+# Firmware Profile Reference
+
+Canonical path: `comet/reference/firmware-profile.md`
+
+This file describes how Comet identifies a C firmware repository. The profile helps graph context, firmware verification, and later diagnostics understand the project structure, build entry points, and high-risk paths.
+
+## Path
+
+```text
+.comet/firmware-profile.yaml
+```
+
+## Minimal example
+
+```yaml
+enabled: true
+language: c
+build_system: make
+compile_database: compile_commands.json
+build_command: null
+test_command: null
+static_analysis_command: null
+source_roots:
+  - src/**
+  - include/**
+high_risk_paths:
+  - "**/ufs*/**"
+  - "**/dma*/**"
+forbidden_paths:
+  - build/**
+  - out/**
+```
+
+## Field summary
+
+- `enabled`: required; must be `true` or `false`
+- `language`: required when enabled
+- `build_system`: required when enabled
+- `compile_database`: optional relative path to `compile_commands.json`
+- `build_command`: optional firmware build command
+- `test_command`: optional firmware test command
+- `static_analysis_command`: optional firmware static-analysis command
+- `source_roots`: required list when enabled
+- `high_risk_paths`: optional glob list that escalates verification to `full`
+- `forbidden_paths`: optional glob list reported by graph drift
+
+## Current behavior
+
+- graph context writes a firmware profile summary when the profile is enabled
+- graph context writes drift warnings into `graph-context.md` and `graph-state.json`, merging `forbidden_paths` and `high_risk_paths` from the profile
+- `comet-firmware-verify.mjs` executes configured build/test/static-analysis commands and writes `firmware-verify-report.md`
diff --git a/assets/skills/comet/reference/scripts.md b/assets/skills/comet/reference/scripts.md
index 7a9bacb..258ed4e 100644
--- a/assets/skills/comet/reference/scripts.md
+++ b/assets/skills/comet/reference/scripts.md
@@ -17,6 +17,8 @@ fi
 COMET_SCRIPTS_DIR="$(node "$COMET_ENV")"
 COMET_STATE="$COMET_SCRIPTS_DIR/comet-state.mjs"
 COMET_GUARD="$COMET_SCRIPTS_DIR/comet-guard.mjs"
+COMET_FIRMWARE_VERIFY="$COMET_SCRIPTS_DIR/comet-firmware-verify.mjs"
+COMET_GRAPH_CONTEXT="$COMET_SCRIPTS_DIR/comet-graph-context.mjs"
 COMET_HANDOFF="$COMET_SCRIPTS_DIR/comet-handoff.mjs"
 COMET_ARCHIVE="$COMET_SCRIPTS_DIR/comet-archive.mjs"
 COMET_INTENT="$COMET_SCRIPTS_DIR/comet-intent.mjs"
@@ -30,6 +32,26 @@ fi
 
 After loading comet, agents should run this bootstrap block once, then reuse `$COMET_GUARD`, `$COMET_STATE`, `$COMET_HANDOFF`, `$COMET_ARCHIVE`, and `$COMET_INTENT` throughout the session.
 
+## Graph Context
+
+Refresh graph context before open/design/build work and again before verify:
+
+```bash
+node "$COMET_GRAPH_CONTEXT" refresh <change-name> --phase <open|design|build|verify>
+```
+
+Current graph-context outputs are intentionally minimal:
+
+- `openspec/changes/<change-name>/.comet/graph/graph-context.md`: human-readable graph context for skills and review
+- `openspec/changes/<change-name>/.comet/graph/graph-state.json`: machine-readable summary containing freshness, candidate files/symbols, Graphify notes, and drift warnings
+- `openspec/changes/<change-name>/.comet/graph/graph-constraints.yaml`: optional manual constraints file
+
+Use the `constraints` subcommand to create or reveal the constraints file:
+
+```bash
+node "$COMET_GRAPH_CONTEXT" constraints <change-name>
+```
+
 ## Auto state update
 
 Guard supports `--apply` flag, automatically updating `.comet.yaml` state fields after checks pass:
diff --git a/assets/skills/comet/scripts/comet-firmware-verify.mjs b/assets/skills/comet/scripts/comet-firmware-verify.mjs
new file mode 100644
index 0000000..d8de0ab
--- /dev/null
+++ b/assets/skills/comet/scripts/comet-firmware-verify.mjs
@@ -0,0 +1,3 @@
+#!/usr/bin/env node
+import { main } from './comet-runtime.mjs';
+process.exitCode = await main(["firmware-verify", ...process.argv.slice(2)]);
diff --git a/assets/skills/comet/scripts/comet-graph-context.mjs b/assets/skills/comet/scripts/comet-graph-context.mjs
new file mode 100644
index 0000000..694cf3a
--- /dev/null
+++ b/assets/skills/comet/scripts/comet-graph-context.mjs
@@ -0,0 +1,3 @@
+#!/usr/bin/env node
+import { main } from './comet-runtime.mjs';
+process.exitCode = await main(["graph-context", ...process.argv.slice(2)]);
diff --git a/assets/skills/comet/scripts/comet-runtime.mjs b/assets/skills/comet/scripts/comet-runtime.mjs
index 5b34109..d02a3be 100644
--- a/assets/skills/comet/scripts/comet-runtime.mjs
+++ b/assets/skills/comet/scripts/comet-runtime.mjs
@@ -126,17 +126,17 @@ var require_visit = __commonJS({
     visit.BREAK = BREAK;
     visit.SKIP = SKIP;
     visit.REMOVE = REMOVE;
-    function visit_(key, node, visitor, path18) {
-      const ctrl = callVisitor(key, node, visitor, path18);
+    function visit_(key, node, visitor, path24) {
+      const ctrl = callVisitor(key, node, visitor, path24);
       if (identity.isNode(ctrl) || identity.isPair(ctrl)) {
-        replaceNode(key, path18, ctrl);
-        return visit_(key, ctrl, visitor, path18);
+        replaceNode(key, path24, ctrl);
+        return visit_(key, ctrl, visitor, path24);
       }
       if (typeof ctrl !== "symbol") {
         if (identity.isCollection(node)) {
-          path18 = Object.freeze(path18.concat(node));
+          path24 = Object.freeze(path24.concat(node));
           for (let i = 0; i < node.items.length; ++i) {
-            const ci = visit_(i, node.items[i], visitor, path18);
+            const ci = visit_(i, node.items[i], visitor, path24);
             if (typeof ci === "number")
               i = ci - 1;
             else if (ci === BREAK)
@@ -147,13 +147,13 @@ var require_visit = __commonJS({
             }
           }
         } else if (identity.isPair(node)) {
-          path18 = Object.freeze(path18.concat(node));
-          const ck = visit_("key", node.key, visitor, path18);
+          path24 = Object.freeze(path24.concat(node));
+          const ck = visit_("key", node.key, visitor, path24);
           if (ck === BREAK)
             return BREAK;
           else if (ck === REMOVE)
             node.key = null;
-          const cv = visit_("value", node.value, visitor, path18);
+          const cv = visit_("value", node.value, visitor, path24);
           if (cv === BREAK)
             return BREAK;
           else if (cv === REMOVE)
@@ -174,17 +174,17 @@ var require_visit = __commonJS({
     visitAsync.BREAK = BREAK;
     visitAsync.SKIP = SKIP;
     visitAsync.REMOVE = REMOVE;
-    async function visitAsync_(key, node, visitor, path18) {
-      const ctrl = await callVisitor(key, node, visitor, path18);
+    async function visitAsync_(key, node, visitor, path24) {
+      const ctrl = await callVisitor(key, node, visitor, path24);
       if (identity.isNode(ctrl) || identity.isPair(ctrl)) {
-        replaceNode(key, path18, ctrl);
-        return visitAsync_(key, ctrl, visitor, path18);
+        replaceNode(key, path24, ctrl);
+        return visitAsync_(key, ctrl, visitor, path24);
       }
       if (typeof ctrl !== "symbol") {
         if (identity.isCollection(node)) {
-          path18 = Object.freeze(path18.concat(node));
+          path24 = Object.freeze(path24.concat(node));
           for (let i = 0; i < node.items.length; ++i) {
-            const ci = await visitAsync_(i, node.items[i], visitor, path18);
+            const ci = await visitAsync_(i, node.items[i], visitor, path24);
             if (typeof ci === "number")
               i = ci - 1;
             else if (ci === BREAK)
@@ -195,13 +195,13 @@ var require_visit = __commonJS({
             }
           }
         } else if (identity.isPair(node)) {
-          path18 = Object.freeze(path18.concat(node));
-          const ck = await visitAsync_("key", node.key, visitor, path18);
+          path24 = Object.freeze(path24.concat(node));
+          const ck = await visitAsync_("key", node.key, visitor, path24);
           if (ck === BREAK)
             return BREAK;
           else if (ck === REMOVE)
             node.key = null;
-          const cv = await visitAsync_("value", node.value, visitor, path18);
+          const cv = await visitAsync_("value", node.value, visitor, path24);
           if (cv === BREAK)
             return BREAK;
           else if (cv === REMOVE)
@@ -228,23 +228,23 @@ var require_visit = __commonJS({
       }
       return visitor;
     }
-    function callVisitor(key, node, visitor, path18) {
+    function callVisitor(key, node, visitor, path24) {
       if (typeof visitor === "function")
-        return visitor(key, node, path18);
+        return visitor(key, node, path24);
       if (identity.isMap(node))
-        return visitor.Map?.(key, node, path18);
+        return visitor.Map?.(key, node, path24);
       if (identity.isSeq(node))
-        return visitor.Seq?.(key, node, path18);
+        return visitor.Seq?.(key, node, path24);
       if (identity.isPair(node))
-        return visitor.Pair?.(key, node, path18);
+        return visitor.Pair?.(key, node, path24);
       if (identity.isScalar(node))
-        return visitor.Scalar?.(key, node, path18);
+        return visitor.Scalar?.(key, node, path24);
       if (identity.isAlias(node))
-        return visitor.Alias?.(key, node, path18);
+        return visitor.Alias?.(key, node, path24);
       return void 0;
     }
-    function replaceNode(key, path18, node) {
-      const parent = path18[path18.length - 1];
+    function replaceNode(key, path24, node) {
+      const parent = path24[path24.length - 1];
       if (identity.isCollection(parent)) {
         parent.items[key] = node;
       } else if (identity.isPair(parent)) {
@@ -854,10 +854,10 @@ var require_Collection = __commonJS({
     var createNode = require_createNode();
     var identity = require_identity();
     var Node = require_Node();
-    function collectionFromPath(schema, path18, value) {
+    function collectionFromPath(schema, path24, value) {
       let v = value;
-      for (let i = path18.length - 1; i >= 0; --i) {
-        const k = path18[i];
+      for (let i = path24.length - 1; i >= 0; --i) {
+        const k = path24[i];
         if (typeof k === "number" && Number.isInteger(k) && k >= 0) {
           const a = [];
           a[k] = v;
@@ -876,7 +876,7 @@ var require_Collection = __commonJS({
         sourceObjects: /* @__PURE__ */ new Map()
       });
     }
-    var isEmptyPath = (path18) => path18 == null || typeof path18 === "object" && !!path18[Symbol.iterator]().next().done;
+    var isEmptyPath = (path24) => path24 == null || typeof path24 === "object" && !!path24[Symbol.iterator]().next().done;
     var Collection = class extends Node.NodeBase {
       constructor(type, schema) {
         super(type);
@@ -906,11 +906,11 @@ var require_Collection = __commonJS({
        * be a Pair instance or a `{ key, value }` object, which may not have a key
        * that already exists in the map.
        */
-      addIn(path18, value) {
-        if (isEmptyPath(path18))
+      addIn(path24, value) {
+        if (isEmptyPath(path24))
           this.add(value);
         else {
-          const [key, ...rest] = path18;
+          const [key, ...rest] = path24;
           const node = this.get(key, true);
           if (identity.isCollection(node))
             node.addIn(rest, value);
@@ -924,8 +924,8 @@ var require_Collection = __commonJS({
        * Removes a value from the collection.
        * @returns `true` if the item was found and removed.
        */
-      deleteIn(path18) {
-        const [key, ...rest] = path18;
+      deleteIn(path24) {
+        const [key, ...rest] = path24;
         if (rest.length === 0)
           return this.delete(key);
         const node = this.get(key, true);
@@ -939,8 +939,8 @@ var require_Collection = __commonJS({
        * scalar values from their surrounding node; to disable set `keepScalar` to
        * `true` (collections are always returned intact).
        */
-      getIn(path18, keepScalar) {
-        const [key, ...rest] = path18;
+      getIn(path24, keepScalar) {
+        const [key, ...rest] = path24;
         const node = this.get(key, true);
         if (rest.length === 0)
           return !keepScalar && identity.isScalar(node) ? node.value : node;
@@ -958,8 +958,8 @@ var require_Collection = __commonJS({
       /**
        * Checks if the collection includes a value with the key `key`.
        */
-      hasIn(path18) {
-        const [key, ...rest] = path18;
+      hasIn(path24) {
+        const [key, ...rest] = path24;
         if (rest.length === 0)
           return this.has(key);
         const node = this.get(key, true);
@@ -969,8 +969,8 @@ var require_Collection = __commonJS({
        * Sets a value in this collection. For `!!set`, `value` needs to be a
        * boolean to add/remove the item from the set.
        */
-      setIn(path18, value) {
-        const [key, ...rest] = path18;
+      setIn(path24, value) {
+        const [key, ...rest] = path24;
         if (rest.length === 0) {
           this.set(key, value);
         } else {
@@ -3485,9 +3485,9 @@ var require_Document = __commonJS({
           this.contents.add(value);
       }
       /** Adds a value to the document. */
-      addIn(path18, value) {
+      addIn(path24, value) {
         if (assertCollection(this.contents))
-          this.contents.addIn(path18, value);
+          this.contents.addIn(path24, value);
       }
       /**
        * Create a new `Alias` node, ensuring that the target `node` has the required anchor.
@@ -3562,14 +3562,14 @@ var require_Document = __commonJS({
        * Removes a value from the document.
        * @returns `true` if the item was found and removed.
        */
-      deleteIn(path18) {
-        if (Collection.isEmptyPath(path18)) {
+      deleteIn(path24) {
+        if (Collection.isEmptyPath(path24)) {
           if (this.contents == null)
             return false;
           this.contents = null;
           return true;
         }
-        return assertCollection(this.contents) ? this.contents.deleteIn(path18) : false;
+        return assertCollection(this.contents) ? this.contents.deleteIn(path24) : false;
       }
       /**
        * Returns item at `key`, or `undefined` if not found. By default unwraps
@@ -3584,10 +3584,10 @@ var require_Document = __commonJS({
        * scalar values from their surrounding node; to disable set `keepScalar` to
        * `true` (collections are always returned intact).
        */
-      getIn(path18, keepScalar) {
-        if (Collection.isEmptyPath(path18))
+      getIn(path24, keepScalar) {
+        if (Collection.isEmptyPath(path24))
           return !keepScalar && identity.isScalar(this.contents) ? this.contents.value : this.contents;
-        return identity.isCollection(this.contents) ? this.contents.getIn(path18, keepScalar) : void 0;
+        return identity.isCollection(this.contents) ? this.contents.getIn(path24, keepScalar) : void 0;
       }
       /**
        * Checks if the document includes a value with the key `key`.
@@ -3598,10 +3598,10 @@ var require_Document = __commonJS({
       /**
        * Checks if the document includes a value at `path`.
        */
-      hasIn(path18) {
-        if (Collection.isEmptyPath(path18))
+      hasIn(path24) {
+        if (Collection.isEmptyPath(path24))
           return this.contents !== void 0;
-        return identity.isCollection(this.contents) ? this.contents.hasIn(path18) : false;
+        return identity.isCollection(this.contents) ? this.contents.hasIn(path24) : false;
       }
       /**
        * Sets a value in this document. For `!!set`, `value` needs to be a
@@ -3618,13 +3618,13 @@ var require_Document = __commonJS({
        * Sets a value in this document. For `!!set`, `value` needs to be a
        * boolean to add/remove the item from the set.
        */
-      setIn(path18, value) {
-        if (Collection.isEmptyPath(path18)) {
+      setIn(path24, value) {
+        if (Collection.isEmptyPath(path24)) {
           this.contents = value;
         } else if (this.contents == null) {
-          this.contents = Collection.collectionFromPath(this.schema, Array.from(path18), value);
+          this.contents = Collection.collectionFromPath(this.schema, Array.from(path24), value);
         } else if (assertCollection(this.contents)) {
-          this.contents.setIn(path18, value);
+          this.contents.setIn(path24, value);
         }
       }
       /**
@@ -5584,9 +5584,9 @@ var require_cst_visit = __commonJS({
     visit.BREAK = BREAK;
     visit.SKIP = SKIP;
     visit.REMOVE = REMOVE;
-    visit.itemAtPath = (cst, path18) => {
+    visit.itemAtPath = (cst, path24) => {
       let item = cst;
-      for (const [field2, index] of path18) {
+      for (const [field2, index] of path24) {
         const tok = item?.[field2];
         if (tok && "items" in tok) {
           item = tok.items[index];
@@ -5595,23 +5595,23 @@ var require_cst_visit = __commonJS({
       }
       return item;
     };
-    visit.parentCollection = (cst, path18) => {
-      const parent = visit.itemAtPath(cst, path18.slice(0, -1));
-      const field2 = path18[path18.length - 1][0];
+    visit.parentCollection = (cst, path24) => {
+      const parent = visit.itemAtPath(cst, path24.slice(0, -1));
+      const field2 = path24[path24.length - 1][0];
       const coll = parent?.[field2];
       if (coll && "items" in coll)
         return coll;
       throw new Error("Parent collection not found");
     };
-    function _visit(path18, item, visitor) {
-      let ctrl = visitor(item, path18);
+    function _visit(path24, item, visitor) {
+      let ctrl = visitor(item, path24);
       if (typeof ctrl === "symbol")
         return ctrl;
       for (const field2 of ["key", "value"]) {
         const token = item[field2];
         if (token && "items" in token) {
           for (let i = 0; i < token.items.length; ++i) {
-            const ci = _visit(Object.freeze(path18.concat([[field2, i]])), token.items[i], visitor);
+            const ci = _visit(Object.freeze(path24.concat([[field2, i]])), token.items[i], visitor);
             if (typeof ci === "number")
               i = ci - 1;
             else if (ci === BREAK)
@@ -5622,10 +5622,10 @@ var require_cst_visit = __commonJS({
             }
           }
           if (typeof ctrl === "function" && field2 === "key")
-            ctrl = ctrl(item, path18);
+            ctrl = ctrl(item, path24);
         }
       }
-      return typeof ctrl === "function" ? ctrl(item, path18) : ctrl;
+      return typeof ctrl === "function" ? ctrl(item, path24) : ctrl;
     }
     exports.visit = visit;
   }
@@ -6927,14 +6927,14 @@ var require_parser = __commonJS({
             case "scalar":
             case "single-quoted-scalar":
             case "double-quoted-scalar": {
-              const fs17 = this.flowScalar(this.type);
+              const fs23 = this.flowScalar(this.type);
               if (atNextItem || it.value) {
-                map.items.push({ start, key: fs17, sep: [] });
+                map.items.push({ start, key: fs23, sep: [] });
                 this.onKeyLine = true;
               } else if (it.sep) {
-                this.stack.push(fs17);
+                this.stack.push(fs23);
               } else {
-                Object.assign(it, { key: fs17, sep: [] });
+                Object.assign(it, { key: fs23, sep: [] });
                 this.onKeyLine = true;
               }
               return;
@@ -7062,13 +7062,13 @@ var require_parser = __commonJS({
             case "scalar":
             case "single-quoted-scalar":
             case "double-quoted-scalar": {
-              const fs17 = this.flowScalar(this.type);
+              const fs23 = this.flowScalar(this.type);
               if (!it || it.value)
-                fc.items.push({ start: [], key: fs17, sep: [] });
+                fc.items.push({ start: [], key: fs23, sep: [] });
               else if (it.sep)
-                this.stack.push(fs17);
+                this.stack.push(fs23);
               else
-                Object.assign(it, { key: fs17, sep: [] });
+                Object.assign(it, { key: fs23, sep: [] });
               return;
             }
             case "flow-map-end":
@@ -7818,6 +7818,8 @@ var CLASSIC_WIRE_KEYS = [
   "verify_mode",
   "auto_transition",
   "base_ref",
+  "graph_context_enabled",
+  "graph_context",
   "design_doc",
   "plan",
   "verify_result",
@@ -7942,7 +7944,9 @@ function classicStateFromDocument(doc) {
     handoffContext: relativePath(doc, "handoff_context"),
     handoffHash: sha256(doc, "handoff_hash"),
     classicProfile: enumValue(doc, "classic_profile", CLASSIC_PROFILES),
-    classicMigration: migrationVersion(doc)
+    classicMigration: migrationVersion(doc),
+    ...has(doc, "graph_context_enabled") ? { graphContextEnabled: booleanValue(doc, "graph_context_enabled") } : {},
+    ...has(doc, "graph_context") ? { graphContext: relativePath(doc, "graph_context") } : {}
   };
 }
 function parseClassicStateDocument(doc, run) {
@@ -8007,7 +8011,9 @@ function classicStateToDocument(state) {
     handoff_context: state.handoffContext,
     handoff_hash: state.handoffHash,
     classic_profile: state.classicProfile,
-    classic_migration: state.classicMigration
+    classic_migration: state.classicMigration,
+    ...state.graphContextEnabled !== void 0 ? { graph_context_enabled: state.graphContextEnabled } : {},
+    ...state.graphContext !== void 0 ? { graph_context: state.graphContext } : {}
   };
 }
 
@@ -9572,12 +9578,1352 @@ var classicArchiveCommand = async (args) => {
   }
 };
 
+// domains/comet-classic/classic-firmware-verify.ts
+import { promises as fs16 } from "fs";
+import path17 from "path";
+
+// domains/integrations/graph-context.ts
+import { execFileSync as execFileSync4, spawnSync as spawnSync2 } from "child_process";
+import { promises as fs14 } from "fs";
+import path15 from "path";
+
+// domains/integrations/codegraph.ts
+import { execFileSync as execFileSync2 } from "child_process";
+import fs12 from "fs";
+import path13 from "path";
+
+// domains/integrations/openspec.ts
+import { execFileSync } from "child_process";
+
+// platform/install/platforms.ts
+var PLATFORMS = [
+  {
+    id: "claude",
+    name: "Claude Code",
+    skillsDir: ".claude",
+    globalSkillsDir: ".claude",
+    openspecToolId: "claude",
+    rulesDir: "rules",
+    rulesFormat: "md",
+    supportsHooks: true,
+    hookFormat: "claude-code"
+  },
+  {
+    id: "cursor",
+    name: "Cursor",
+    skillsDir: ".cursor",
+    globalSkillsDir: ".cursor",
+    openspecToolId: "cursor",
+    rulesDir: "rules",
+    rulesFormat: "mdc"
+  },
+  {
+    id: "codex",
+    name: "Codex",
+    skillsDir: ".codex",
+    globalSkillsDir: ".codex",
+    openspecToolId: "codex",
+    rulesDir: "rules",
+    rulesFormat: "md",
+    supportsHooks: true,
+    hookFormat: "claude-code"
+  },
+  {
+    id: "opencode",
+    name: "OpenCode",
+    skillsDir: ".opencode",
+    globalSkillsDir: ".config/opencode",
+    openspecToolId: "opencode",
+    rulesDir: "rules",
+    rulesFormat: "md"
+  },
+  {
+    id: "windsurf",
+    name: "Windsurf",
+    skillsDir: ".windsurf",
+    globalSkillsDir: ".windsurf",
+    openspecToolId: "windsurf",
+    rulesDir: "rules",
+    rulesFormat: "md",
+    supportsHooks: true,
+    hookFormat: "windsurf"
+  },
+  {
+    id: "cline",
+    name: "Cline",
+    skillsDir: ".cline",
+    globalSkillsDir: ".cline",
+    openspecToolId: "cline",
+    // Cline rules go to .clinerules/ at project root, NOT inside .cline/
+    rulesBaseDir: "",
+    rulesDir: ".clinerules",
+    rulesFormat: "md"
+  },
+  {
+    id: "roocode",
+    name: "RooCode",
+    skillsDir: ".roo",
+    globalSkillsDir: ".roo",
+    openspecToolId: "roocode",
+    rulesDir: "rules",
+    rulesFormat: "md"
+  },
+  {
+    id: "continue",
+    name: "Continue",
+    skillsDir: ".continue",
+    globalSkillsDir: ".continue",
+    openspecToolId: "continue",
+    rulesDir: "rules",
+    rulesFormat: "md"
+  },
+  {
+    id: "github-copilot",
+    name: "GitHub Copilot",
+    skillsDir: ".github",
+    globalSkillsDir: ".github",
+    detectionPaths: [
+      ".github/copilot-instructions.md",
+      ".github/instructions",
+      ".github/prompts",
+      ".github/skills"
+    ],
+    openspecToolId: "github-copilot",
+    // Copilot uses .github/instructions/*.instructions.md format
+    rulesDir: "instructions",
+    rulesFormat: "copilot",
+    supportsHooks: true,
+    hookFormat: "copilot"
+  },
+  {
+    id: "gemini",
+    name: "Gemini CLI",
+    skillsDir: ".gemini",
+    globalSkillsDir: ".gemini",
+    openspecToolId: "gemini",
+    // Gemini uses GEMINI.md files, not a rules directory — no rulesDir
+    supportsHooks: true,
+    hookFormat: "gemini"
+  },
+  {
+    id: "amazon-q",
+    name: "Amazon Q Developer",
+    skillsDir: ".amazonq",
+    globalSkillsDir: ".amazonq",
+    openspecToolId: "amazon-q",
+    rulesDir: "rules",
+    rulesFormat: "md",
+    supportsHooks: true,
+    hookFormat: "claude-code"
+  },
+  {
+    id: "qwen",
+    name: "Qwen Code",
+    skillsDir: ".qwen",
+    globalSkillsDir: ".qwen",
+    openspecToolId: "qwen",
+    rulesDir: "rules",
+    rulesFormat: "md",
+    supportsHooks: true,
+    hookFormat: "qwen"
+  },
+  {
+    id: "kilocode",
+    name: "Kilo Code",
+    skillsDir: ".kilocode",
+    globalSkillsDir: ".kilocode",
+    openspecToolId: "kilocode",
+    rulesDir: "rules",
+    rulesFormat: "md"
+  },
+  {
+    id: "auggie",
+    name: "Auggie (Augment CLI)",
+    skillsDir: ".augment",
+    globalSkillsDir: ".augment",
+    openspecToolId: "auggie",
+    rulesDir: "rules",
+    rulesFormat: "md"
+  },
+  {
+    id: "kiro",
+    name: "Kiro",
+    skillsDir: ".kiro",
+    globalSkillsDir: ".kiro",
+    openspecToolId: "kiro",
+    // Kiro uses .kiro/steering/ not .kiro/rules/
+    rulesDir: "steering",
+    rulesFormat: "md",
+    supportsHooks: true,
+    hookFormat: "kiro"
+  },
+  {
+    id: "kimicode",
+    name: "Kimi Code",
+    skillsDir: ".kimi-code",
+    globalSkillsDir: ".kimi-code",
+    openspecToolId: "kimi"
+  },
+  {
+    id: "lingma",
+    name: "Lingma",
+    skillsDir: ".lingma",
+    globalSkillsDir: ".lingma",
+    openspecToolId: "lingma",
+    rulesDir: "rules",
+    rulesFormat: "md"
+  },
+  { id: "junie", name: "Junie", skillsDir: ".junie", openspecToolId: "junie" },
+  { id: "codebuddy", name: "CodeBuddy Code", skillsDir: ".codebuddy", openspecToolId: "codebuddy" },
+  { id: "costrict", name: "CoStrict", skillsDir: ".cospec", openspecToolId: "costrict" },
+  { id: "crush", name: "Crush", skillsDir: ".crush", openspecToolId: "crush" },
+  { id: "factory", name: "Factory Droid", skillsDir: ".factory", openspecToolId: "factory" },
+  { id: "iflow", name: "iFlow", skillsDir: ".iflow", openspecToolId: "iflow" },
+  {
+    id: "pi",
+    name: "Pi",
+    skillsDir: ".pi",
+    globalSkillsDir: ".pi/agent",
+    openspecToolId: "pi"
+  },
+  {
+    id: "qoder",
+    name: "Qoder",
+    skillsDir: ".qoder",
+    globalSkillsDir: ".qoder",
+    openspecToolId: "qoder",
+    rulesDir: "rules",
+    rulesFormat: "md",
+    supportsHooks: true,
+    hookFormat: "qoder"
+  },
+  {
+    id: "antigravity",
+    name: "Antigravity",
+    skillsDir: ".agents",
+    globalSkillsDir: ".gemini/antigravity",
+    openspecToolId: "antigravity"
+  },
+  {
+    id: "antigravity2",
+    name: "Antigravity 2.0",
+    skillsDir: ".agents",
+    globalSkillsDir: ".gemini/config",
+    openspecToolId: "antigravity"
+  },
+  { id: "bob", name: "Bob Shell", skillsDir: ".bob", openspecToolId: "bob" },
+  { id: "forgecode", name: "ForgeCode", skillsDir: ".forge", openspecToolId: "forgecode" },
+  {
+    id: "trae",
+    name: "Trae",
+    skillsDir: ".trae",
+    globalSkillsDir: ".trae",
+    openspecToolId: "trae",
+    rulesDir: "rules",
+    rulesFormat: "md"
+  },
+  {
+    id: "trae-cn",
+    name: "Trae CN",
+    skillsDir: ".trae-cn",
+    globalSkillsDir: ".trae-cn",
+    // OpenSpec exposes Trae as one tool id; keep Comet's CN-specific install
+    // directories but reuse the supported OpenSpec Trae integration.
+    openspecToolId: "trae",
+    rulesDir: "rules",
+    rulesFormat: "md"
+  },
+  {
+    id: "zcode",
+    name: "ZCode",
+    skillsDir: ".zcode",
+    globalSkillsDir: ".zcode",
+    // openspec CLI has no zcode tool id; zcode is built on opencode (it shares the
+    // opencode.ai config schema), so we reuse openspec's opencode support and migrate
+    // the .opencode/{skills,commands} output to .zcode/ after install.
+    openspecToolId: "opencode",
+    rulesDir: "rules",
+    rulesFormat: "md"
+  },
+  {
+    id: "mimocode",
+    name: "MimoCode",
+    skillsDir: ".mimocode",
+    globalSkillsDir: ".config/mimocode",
+    // MimoCode is built on OpenCode and reads the same skills/commands shape
+    // from its own config directory.
+    openspecToolId: "opencode",
+    rulesDir: "rules",
+    rulesFormat: "md"
+  }
+];
+
+// platform/process/command-error.ts
+var ESC = String.fromCharCode(27);
+var ANSI_ESCAPE_PATTERN = new RegExp(`${ESC}\\[[0-9;?]*[a-zA-Z]`, "g");
+var LOOSE_ESCAPE_PATTERN = new RegExp(`${ESC}\\[[^a-zA-Z\\r\\n]*`, "g");
+
+// domains/integrations/openspec.ts
+var VALID_TOOL_IDS = new Set(PLATFORMS.map((p) => p.openspecToolId));
+var ALL_OPENSPEC_WORKFLOWS = [
+  "propose",
+  "explore",
+  "new",
+  "continue",
+  "apply",
+  "ff",
+  "sync",
+  "archive",
+  "bulk-archive",
+  "verify",
+  "onboard"
+];
+var ALL_WORKFLOWS_CONFIG = JSON.stringify(
+  {
+    featureFlags: {},
+    profile: "custom",
+    delivery: "both",
+    workflows: [...ALL_OPENSPEC_WORKFLOWS]
+  },
+  null,
+  2
+) + "\n";
+function isCommandAvailable(command) {
+  try {
+    const checker = process.platform === "win32" ? "where" : "which";
+    execFileSync(checker, [command], { stdio: "ignore", timeout: 1e4 });
+    return true;
+  } catch {
+    return false;
+  }
+}
+
+// domains/integrations/codegraph.ts
+function getPnpmExecutable(platform = process.platform) {
+  return platform === "win32" ? "pnpm.cmd" : "pnpm";
+}
+function hasCodegraphProjectIndex(projectPath) {
+  const codegraphDir = path13.join(projectPath, ".codegraph");
+  try {
+    if (!fs12.statSync(codegraphDir).isDirectory()) return false;
+    return fs12.readdirSync(codegraphDir).some((entry2) => entry2 !== ".gitignore");
+  } catch {
+    return false;
+  }
+}
+function resolvePnpmGlobalCommand(command) {
+  try {
+    const binDir = execFileSync2(getPnpmExecutable(), ["bin", "-g"], {
+      encoding: "utf-8",
+      stdio: ["ignore", "pipe", "ignore"],
+      timeout: 1e4,
+      shell: process.platform === "win32"
+    }).trim();
+    if (!binDir) return null;
+    const candidates = process.platform === "win32" ? [`${command}.cmd`, `${command}.exe`, `${command}.ps1`, command] : [command];
+    for (const candidate of candidates) {
+      const candidatePath = path13.join(binDir, candidate);
+      if (fs12.existsSync(candidatePath)) return candidatePath;
+    }
+  } catch {
+  }
+  return null;
+}
+function resolveCodegraphCommand() {
+  if (isCommandAvailable("codegraph")) return "codegraph";
+  return resolvePnpmGlobalCommand("codegraph");
+}
+
+// domains/integrations/graphify.ts
+import { execFileSync as execFileSync3 } from "child_process";
+import fs13 from "fs";
+import path14 from "path";
+function getPnpmExecutable2(platform = process.platform) {
+  return platform === "win32" ? "pnpm.cmd" : "pnpm";
+}
+function resolvePnpmGlobalCommand2(command) {
+  try {
+    const binDir = execFileSync3(getPnpmExecutable2(), ["bin", "-g"], {
+      encoding: "utf-8",
+      stdio: ["ignore", "pipe", "ignore"],
+      timeout: 1e4,
+      shell: process.platform === "win32"
+    }).trim();
+    if (!binDir) return null;
+    const candidates = process.platform === "win32" ? [`${command}.cmd`, `${command}.exe`, `${command}.ps1`, command] : [command];
+    for (const candidate of candidates) {
+      const candidatePath = path14.join(binDir, candidate);
+      if (fs13.existsSync(candidatePath)) return candidatePath;
+    }
+  } catch {
+  }
+  return null;
+}
+function getGraphifyArtifactPath(projectPath) {
+  const candidates = [
+    path14.join(projectPath, ".graphify", "graph.json"),
+    path14.join(projectPath, "graphify-out", "graph.json")
+  ];
+  for (const candidate of candidates) {
+    try {
+      if (fs13.statSync(candidate).isFile()) return candidate;
+    } catch {
+    }
+  }
+  return null;
+}
+function hasGraphifyProjectArtifact(projectPath) {
+  return getGraphifyArtifactPath(projectPath) !== null;
+}
+function resolveGraphifyCommand() {
+  if (isCommandAvailable("graphify")) return "graphify";
+  return resolvePnpmGlobalCommand2("graphify");
+}
+
+// domains/integrations/graph-context.ts
+function getChangeGraphContextPaths(changeDir) {
+  const graphDir = path15.join(changeDir, ".comet", "graph");
+  return {
+    graphDir,
+    graphContext: path15.join(graphDir, "graph-context.md"),
+    graphState: path15.join(graphDir, "graph-state.json"),
+    graphConstraints: path15.join(graphDir, "graph-constraints.yaml")
+  };
+}
+function stripYamlQuotes(value) {
+  const trimmed = value.trim();
+  if (trimmed.startsWith('"') && trimmed.endsWith('"') || trimmed.startsWith("'") && trimmed.endsWith("'")) {
+    return trimmed.slice(1, -1);
+  }
+  return trimmed;
+}
+function parseYamlListLines(raw, field2) {
+  const values = [];
+  let inList = false;
+  for (const line of raw.split(/\r?\n/u)) {
+    if (new RegExp(`^\\s*${field2}:`).test(line)) {
+      inList = true;
+      continue;
+    }
+    if (/^\s*[A-Za-z0-9_-]+:/u.test(line)) {
+      inList = false;
+    }
+    if (!inList) continue;
+    const item = line.match(/^\s*-\s*(.*?)\s*$/u);
+    if (item?.[1]) values.push(stripYamlQuotes(item[1]));
+  }
+  return values;
+}
+function extractCodegraphSummary(raw) {
+  const summary = {
+    status: "ok",
+    skippedReason: null,
+    candidateFiles: [],
+    candidateSymbols: [],
+    relevanceHints: []
+  };
+  const fileRegex = /(?:[A-Za-z0-9_.@+-]+\/)+[A-Za-z0-9_.@+-]+\.(?:c|h|cc|cpp|hpp|ts|tsx|js|jsx|mjs|sh|md)\b/g;
+  const symbolRegex = /\b[A-Za-z_][A-Za-z0-9_]{2,}\b/g;
+  const stopwords = /* @__PURE__ */ new Set([
+    "analysis",
+    "and",
+    "archive",
+    "build",
+    "call",
+    "caller",
+    "callees",
+    "callers",
+    "codegraph",
+    "context",
+    "design",
+    "entry",
+    "file",
+    "files",
+    "graph",
+    "high",
+    "impact",
+    "module",
+    "open",
+    "phase",
+    "related",
+    "risk",
+    "summary",
+    "symbol",
+    "symbols",
+    "verify"
+  ]);
+  const pushUnique = (target, value, limit = 12) => {
+    if (!value || target.includes(value) || target.length >= limit) return;
+    target.push(value);
+  };
+  const normalizeSymbol = (token) => {
+    if (stopwords.has(token.toLowerCase())) return null;
+    if (/^[A-Z0-9_]+$/u.test(token)) return null;
+    return token;
+  };
+  for (const line of raw.split(/\r?\n/u)) {
+    for (const match of line.match(fileRegex) ?? []) {
+      pushUnique(summary.candidateFiles, match);
+    }
+    for (const token of line.match(symbolRegex) ?? []) {
+      const normalized2 = normalizeSymbol(token);
+      pushUnique(summary.candidateSymbols, normalized2);
+    }
+    if (/related|impact|boundary|history|constraint/iu.test(line)) {
+      pushUnique(summary.relevanceHints, line.trim(), 20);
+    }
+  }
+  return summary;
+}
+function skippedCodegraphSummary(reason) {
+  return {
+    status: "skipped",
+    skippedReason: reason,
+    candidateFiles: [],
+    candidateSymbols: [],
+    relevanceHints: []
+  };
+}
+function summarizeGraphifyResult(mode, output, skippedReason) {
+  if (skippedReason) {
+    return { status: "skipped", skippedReason, notes: [] };
+  }
+  const notes = output.split(/\r?\n/u).map((line) => line.trim()).filter(Boolean).slice(0, 12);
+  return {
+    status: mode === "off" ? "skipped" : "ok",
+    skippedReason: mode === "off" ? "graph_analysis=off" : null,
+    notes
+  };
+}
+function runTool(command, args) {
+  const result3 = spawnSync2(command, args, {
+    encoding: "utf8",
+    shell: process.platform === "win32",
+    timeout: 3e4
+  });
+  return {
+    status: result3.status ?? 1,
+    output: `${result3.stdout ?? ""}${result3.stderr ?? ""}`.trim()
+  };
+}
+function collectCodegraphContext(projectPath, changeName, phase, mode) {
+  if (mode === "off") {
+    return {
+      analysis: "Reason: graph_analysis=off",
+      summary: skippedCodegraphSummary("graph_analysis=off")
+    };
+  }
+  const codegraphCommand = resolveCodegraphCommand();
+  if (!codegraphCommand || !hasCodegraphProjectIndex(projectPath)) {
+    return {
+      analysis: "Reason: .codegraph index missing",
+      summary: skippedCodegraphSummary(".codegraph index missing")
+    };
+  }
+  const result3 = runTool(codegraphCommand, ["structure", changeName, "--phase", phase]);
+  const analysis = result3.output || "CodeGraph returned no output";
+  return {
+    analysis,
+    summary: extractCodegraphSummary(analysis)
+  };
+}
+function collectGraphifyContext(projectPath, changeName, phase, mode) {
+  if (mode === "off") {
+    return {
+      output: "",
+      summary: summarizeGraphifyResult(mode, "", "graph_analysis=off")
+    };
+  }
+  const graphifyCommand = resolveGraphifyCommand();
+  if (!graphifyCommand || !hasGraphifyProjectArtifact(projectPath)) {
+    return {
+      output: "",
+      summary: summarizeGraphifyResult(mode, "", "graph.json missing")
+    };
+  }
+  const result3 = runTool(graphifyCommand, ["query", `${changeName} ${phase} graph context`]);
+  const output = result3.output || "graphify query returned no output";
+  return {
+    output,
+    summary: summarizeGraphifyResult(mode, output, null)
+  };
+}
+function buildDriftWarnings(drift, expectedMissing, protectedHits) {
+  return [
+    ...drift.forbiddenHits.map((file) => `forbidden path changed: ${file}`),
+    ...drift.outOfScopeHits.map((file) => `out-of-scope path changed: ${file}`),
+    ...drift.highRiskHits.map((file) => `high-risk path changed: ${file}`),
+    ...expectedMissing.map((symbol) => `expected symbol missing from summary: ${symbol}`),
+    ...protectedHits.map((symbol) => `protected symbol changed: ${symbol}`)
+  ];
+}
+function defaultGraphConstraintsYaml() {
+  return [
+    "graph_constraints:",
+    "  allowed_paths: []",
+    "  forbidden_paths: []",
+    "  high_risk_paths: []",
+    "  expected_symbols: []",
+    "  protected_symbols: []",
+    "  accepted_deviations: []",
+    ""
+  ].join("\n");
+}
+async function exists3(file) {
+  try {
+    await fs14.access(file);
+    return true;
+  } catch (error) {
+    if (error.code === "ENOENT") return false;
+    throw error;
+  }
+}
+async function readProjectConfigField(projectPath, field2) {
+  const file = path15.join(projectPath, ".comet", "config.yaml");
+  if (!await exists3(file)) return null;
+  for (const line of (await fs14.readFile(file, "utf8")).split(/\r?\n/u)) {
+    const match = line.match(new RegExp(`^${field2}:\\s*(.*?)\\s*$`, "u"));
+    if (!match) continue;
+    const value = match[1].trim().replace(/^['"]|['"]$/gu, "");
+    return value === "" ? null : value;
+  }
+  return null;
+}
+async function resolveGraphContextEnabled(projectPath, explicitStateValue) {
+  if (explicitStateValue !== null && explicitStateValue !== void 0) return explicitStateValue;
+  const configured = process.env.COMET_GRAPH_CONTEXT_ENABLED ?? await readProjectConfigField(projectPath, "graph_context_enabled");
+  if (configured === null) return true;
+  return configured === "true";
+}
+async function resolveGraphAnalysisMode(projectPath) {
+  const value = process.env.COMET_GRAPH_ANALYSIS ?? await readProjectConfigField(projectPath, "graph_analysis") ?? "light";
+  if (value === "off" || value === "light" || value === "standard") return value;
+  return "light";
+}
+async function readGraphContextRuntimeConfig(projectPath, explicitStateValue) {
+  const [enabled, mode] = await Promise.all([
+    resolveGraphContextEnabled(projectPath, explicitStateValue),
+    resolveGraphAnalysisMode(projectPath)
+  ]);
+  return { enabled, mode };
+}
+async function readChangedFilesFromGit() {
+  const outputs = [];
+  for (const args of [
+    ["diff", "--name-only"],
+    ["diff", "--cached", "--name-only"]
+  ]) {
+    try {
+      outputs.push(
+        execFileSync4("git", args, {
+          encoding: "utf8",
+          stdio: ["ignore", "pipe", "ignore"],
+          timeout: 1e4
+        })
+      );
+    } catch {
+    }
+  }
+  return [...new Set(outputs.flatMap((raw) => raw.split(/\r?\n/u).map((line) => line.trim()).filter(Boolean)))];
+}
+async function snapshotForArtifact(artifactPath, label, changedFiles) {
+  if (!artifactPath || !await exists3(artifactPath)) {
+    return {
+      freshness: {
+        status: "missing",
+        recommendation: `Initialize or refresh ${label} before trusting graph context.`,
+        newerRelevantFileCount: 0
+      }
+    };
+  }
+  const currentChangedFiles = changedFiles ?? await readChangedFilesFromGit();
+  const newerRelevantFileCount = currentChangedFiles.length;
+  if (newerRelevantFileCount >= 5) {
+    return {
+      freshness: {
+        status: "stale-and-should-refresh",
+        recommendation: `Refresh ${label} before trusting graph context.`,
+        newerRelevantFileCount
+      }
+    };
+  }
+  if (newerRelevantFileCount > 0) {
+    return {
+      freshness: {
+        status: "stale-but-usable",
+        recommendation: `${label} artifact is usable, but changed files exist since the last graph snapshot.`,
+        newerRelevantFileCount
+      }
+    };
+  }
+  return {
+    freshness: {
+      status: "fresh",
+      recommendation: `${label} artifact is aligned with current workspace.`,
+      newerRelevantFileCount: 0
+    }
+  };
+}
+async function ensureGraphConstraintsFile(file) {
+  if (await exists3(file)) return;
+  await fs14.writeFile(file, defaultGraphConstraintsYaml(), "utf8");
+}
+async function readGraphConstraintLists(file) {
+  if (!await exists3(file)) {
+    return {
+      allowed_paths: [],
+      forbidden_paths: [],
+      high_risk_paths: [],
+      expected_symbols: [],
+      protected_symbols: [],
+      accepted_deviations: []
+    };
+  }
+  const raw = await fs14.readFile(file, "utf8");
+  return {
+    allowed_paths: parseYamlListLines(raw, "allowed_paths"),
+    forbidden_paths: parseYamlListLines(raw, "forbidden_paths"),
+    high_risk_paths: parseYamlListLines(raw, "high_risk_paths"),
+    expected_symbols: parseYamlListLines(raw, "expected_symbols"),
+    protected_symbols: parseYamlListLines(raw, "protected_symbols"),
+    accepted_deviations: parseYamlListLines(raw, "accepted_deviations")
+  };
+}
+async function collectProtectedSymbolHits(changedFiles, protectedSymbols) {
+  const hits = /* @__PURE__ */ new Set();
+  for (const symbol of protectedSymbols) {
+    for (const file of changedFiles) {
+      const absolute = path15.resolve(file);
+      if (!await exists3(absolute)) continue;
+      if ((await fs14.readFile(absolute, "utf8")).includes(symbol)) {
+        hits.add(symbol);
+      }
+    }
+  }
+  return [...hits];
+}
+function globToRegExp(pattern) {
+  const escaped = pattern.trim().replace(/[.+^${}()|[\]\\]/gu, "\\$&").replace(/\*/gu, ".*").replace(/\?/gu, ".");
+  return new RegExp(`^${escaped}$`, "u");
+}
+function matchesAnyPattern(filePath, patterns) {
+  return patterns.some((pattern) => pattern && globToRegExp(pattern).test(filePath));
+}
+function analyzeGraphDrift(input) {
+  const highRiskPatterns = input.highRiskPaths ?? [];
+  const acceptedPatterns = input.acceptedDeviations ?? [];
+  const acceptedHits = input.changedFiles.filter(
+    (file) => matchesAnyPattern(file, acceptedPatterns)
+  );
+  const rawForbiddenHits = input.changedFiles.filter(
+    (file) => matchesAnyPattern(file, input.forbiddenPaths)
+  );
+  const rawOutOfScopeHits = input.allowedPaths.length === 0 ? [] : input.changedFiles.filter((file) => !matchesAnyPattern(file, input.allowedPaths));
+  const rawHighRiskHits = input.changedFiles.filter(
+    (file) => matchesAnyPattern(file, highRiskPatterns)
+  );
+  const forbiddenHits = rawForbiddenHits.filter(
+    (file) => !matchesAnyPattern(file, acceptedPatterns)
+  );
+  const outOfScopeHits = rawOutOfScopeHits.filter(
+    (file) => !matchesAnyPattern(file, acceptedPatterns)
+  );
+  const highRiskHits = rawHighRiskHits.filter((file) => !matchesAnyPattern(file, acceptedPatterns));
+  const status = forbiddenHits.length > 0 || outOfScopeHits.length > 0 || highRiskHits.length > 0 ? "warn" : "pass";
+  return {
+    status,
+    forbiddenHits,
+    outOfScopeHits,
+    highRiskHits,
+    acceptedHits,
+    shouldRequireFullVerify: rawHighRiskHits.length > 0
+  };
+}
+function buildGraphStatePayload(input) {
+  return {
+    schemaVersion: 1,
+    phase: input.phase,
+    mode: input.mode,
+    codegraph: {
+      ...input.codegraphSnapshot,
+      ...input.codegraphSummary
+    },
+    graphify: {
+      ...input.graphifySnapshot,
+      ...input.graphifySummary
+    },
+    drift: {
+      status: input.driftStatus,
+      warnings: input.driftWarnings,
+      changedFiles: input.changedFiles,
+      shouldRequireFullVerify: input.shouldRequireFullVerify
+    }
+  };
+}
+function renderGraphContextMarkdown(input) {
+  return [
+    `# Graph Context: ${input.changeName}`,
+    "",
+    "## Graph Guard",
+    "",
+    `- Graph Analysis Mode: ${input.mode}`,
+    "",
+    "### CodeGraph Freshness",
+    `- Status: ${input.codegraphSnapshot.freshness.status}`,
+    `- Recommendation: ${input.codegraphSnapshot.freshness.recommendation}`,
+    `- newer_relevant_files: ${input.codegraphSnapshot.freshness.newerRelevantFileCount}`,
+    "",
+    "### Graphify Freshness",
+    `- Status: ${input.graphifySnapshot.freshness.status}`,
+    `- Recommendation: ${input.graphifySnapshot.freshness.recommendation}`,
+    `- newer_relevant_files: ${input.graphifySnapshot.freshness.newerRelevantFileCount}`,
+    "",
+    "## Phase Graph Checklist",
+    "",
+    ...graphPhaseChecklist(input.phase).map((line) => `- ${line}`),
+    "",
+    "## CodeGraph Analysis",
+    "",
+    input.codegraphAnalysis,
+    "",
+    "## Candidate Focus",
+    "",
+    `- Candidate Files: ${input.codegraphSummary.candidateFiles.join(", ") || "none"}`,
+    `- Candidate Symbols: ${input.codegraphSummary.candidateSymbols.join(", ") || "none"}`,
+    ...input.codegraphSummary.skippedReason ? [`- CodeGraph Skipped Reason: ${input.codegraphSummary.skippedReason}`] : [],
+    "",
+    "## Drift Summary",
+    "",
+    `- Status: ${input.driftStatus}`,
+    `- Changed Files: ${input.changedFiles.join(", ") || "none"}`,
+    ...input.driftWarnings.length > 0 ? input.driftWarnings.map((warning) => `- Warning: ${warning}`) : ["- Warning: none"],
+    "",
+    ...input.firmwareProfile.status === "configured" ? [
+      "## Firmware Profile",
+      "",
+      "- Enabled: true",
+      `- Language: ${input.firmwareProfile.profile.language ?? "unknown"}`,
+      `- Build System: ${input.firmwareProfile.profile.buildSystem ?? "unknown"}`,
+      `- Compile Database: ${input.firmwareProfile.profile.compileDatabase ?? "not configured"}`,
+      `- Compile Database Status: ${input.compileDatabaseStatus?.status === "present" ? `present (${input.compileDatabaseStatus.entries} entries)` : input.compileDatabaseStatus?.status ?? "not-configured"}`,
+      `- Source Roots: ${input.firmwareProfile.profile.sourceRoots.length > 0 ? input.firmwareProfile.profile.sourceRoots.join(", ") : "none"}`,
+      `- High Risk Paths: ${input.firmwareProfile.profile.highRiskPaths.length > 0 ? input.firmwareProfile.profile.highRiskPaths.join(", ") : "none"}`,
+      `- Forbidden Paths: ${input.firmwareProfile.profile.forbiddenPaths.length > 0 ? input.firmwareProfile.profile.forbiddenPaths.join(", ") : "none"}`,
+      "",
+      ...input.compileDatabaseStatus?.status === "present" ? [
+        "## Compile Database Summary",
+        "",
+        `- Entries: ${input.compileDatabaseStatus.entries}`,
+        `- Sample Files: ${input.compileDatabaseStatus.sampleFiles.join(", ") || "none"}`,
+        `- Include Roots: ${input.compileDatabaseStatus.includeRoots.join(", ") || "none"}`,
+        `- Define Flags: ${input.compileDatabaseStatus.defineFlags.join(", ") || "none"}`,
+        ""
+      ] : []
+    ] : [],
+    "## Graphify Notes",
+    "",
+    `- Status: ${input.graphifySummary.status}`,
+    ...input.graphifySummary.skippedReason ? [`- Reason: ${input.graphifySummary.skippedReason}`] : [],
+    ...input.graphifySummary.notes.length > 0 ? input.graphifySummary.notes.map((note) => `- ${note}`) : ["- No additional Graphify notes"],
+    ""
+  ].join("\n");
+}
+function graphPhaseChecklist(phase) {
+  switch (phase) {
+    case "open":
+      return [
+        "CodeGraph: identify candidate files, symbols, and impact boundary before writing OpenSpec artifacts.",
+        'CodeGraph commands: codegraph brief <file>, codegraph where <symbol>, codegraph search "<intent>".',
+        "Graphify: look for related historical requirements, design notes, and verification reports.",
+        'Graphify commands: graphify query "<question>", graphify explain "<node>".'
+      ];
+    case "design":
+      return [
+        "CodeGraph: validate proposed modules, callers, callees, and dependency direction before finalizing design.",
+        "CodeGraph commands: codegraph context <function>, codegraph deps <file>, codegraph impact <file>.",
+        "Graphify: compare the design with prior decisions and similar changes.",
+        'Graphify commands: graphify query "<similar change or design decision>".'
+      ];
+    case "build":
+      return [
+        "CodeGraph: keep edits inside allowed paths and re-check affected symbols before each task.",
+        "CodeGraph commands: codegraph where <symbol>, codegraph fn-impact <function>, codegraph deps <file>.",
+        "Graphify: use only as background context, not as a hard code-editing constraint.",
+        'Graphify commands: graphify explain "<related concept>" when background is needed.'
+      ];
+    case "verify":
+      return [
+        "CodeGraph: run graph drift and inspect forbidden, out-of-scope, and high-risk file changes.",
+        "CodeGraph commands: codegraph diff-impact, codegraph check, codegraph complexity <target>.",
+        "Graphify: confirm the implementation and verification report still match historical constraints.",
+        'Graphify commands: graphify affected "<node>", graphify query "<verification coverage question>".'
+      ];
+    case "archive":
+      return [
+        "CodeGraph: refresh structure index after successful archive when available.",
+        "CodeGraph commands: codegraph build, codegraph snapshot.",
+        "Graphify: include proposal, design, plan, verification report, and drift report in long-term memory.",
+        "Graphify commands: graphify save-result, graphify update <path>."
+      ];
+  }
+}
+
+// domains/integrations/firmware-profile.ts
+import { promises as fs15 } from "fs";
+import path16 from "path";
+import { spawnSync as spawnSync3 } from "child_process";
+function isEmptyCommand(command) {
+  return !command || command === "null";
+}
+function runCommandString(command) {
+  const result3 = spawnSync3(command, {
+    shell: true,
+    encoding: "utf8",
+    timeout: 3e5
+  });
+  return {
+    status: result3.status ?? 1,
+    output: `${result3.stdout ?? ""}${result3.stderr ?? ""}`.trim()
+  };
+}
+function writeReportHeader(changeName, status) {
+  const generatedAt = (/* @__PURE__ */ new Date()).toISOString();
+  return [
+    `# Firmware Verify Report: ${changeName}`,
+    "",
+    `- Generated At: ${generatedAt}`,
+    `- Status: ${status}`,
+    "",
+    "## Commands",
+    ""
+  ].join("\n");
+}
+function commandSection(label, result3) {
+  return [
+    "",
+    `### ${label} Output`,
+    "",
+    "```text",
+    result3.output || "(no output)",
+    "```"
+  ];
+}
+function stripQuotes(value) {
+  const trimmed = value.trim();
+  if (trimmed.startsWith('"') && trimmed.endsWith('"') || trimmed.startsWith("'") && trimmed.endsWith("'")) {
+    return trimmed.slice(1, -1);
+  }
+  return trimmed;
+}
+function parseBoolean(value) {
+  if (!value) return null;
+  if (value === "true") return true;
+  if (value === "false") return false;
+  return null;
+}
+function firmwareProfilePath(projectPath) {
+  return path16.join(projectPath, ".comet", "firmware-profile.yaml");
+}
+function parseFirmwareProfile(raw) {
+  const scalar2 = {};
+  const lists = {
+    source_roots: [],
+    high_risk_paths: [],
+    forbidden_paths: []
+  };
+  let activeList = null;
+  for (const line of raw.split(/\r?\n/u)) {
+    const withoutComment = line.replace(/\s+#.*$/u, "");
+    if (!withoutComment.trim()) continue;
+    const listItem = withoutComment.match(/^\s*-\s*(.+?)\s*$/u);
+    if (listItem && activeList && lists[activeList]) {
+      lists[activeList].push(stripQuotes(listItem[1]));
+      continue;
+    }
+    const keyValue = withoutComment.match(/^([A-Za-z0-9_-]+):\s*(.*?)\s*$/u);
+    if (!keyValue) continue;
+    const [, key, value] = keyValue;
+    if (Object.prototype.hasOwnProperty.call(lists, key) && !value) {
+      activeList = key;
+      continue;
+    }
+    activeList = null;
+    scalar2[key] = stripQuotes(value);
+  }
+  const enabled = parseBoolean(scalar2.enabled);
+  const errors = [];
+  if (enabled === null) errors.push("enabled must be true or false");
+  const profile = {
+    enabled: enabled ?? false,
+    language: scalar2.language || null,
+    buildSystem: scalar2.build_system || null,
+    compileDatabase: scalar2.compile_database || null,
+    buildCommand: scalar2.build_command || null,
+    testCommand: scalar2.test_command || null,
+    staticAnalysisCommand: scalar2.static_analysis_command || null,
+    sourceRoots: lists.source_roots,
+    highRiskPaths: lists.high_risk_paths,
+    forbiddenPaths: lists.forbidden_paths
+  };
+  if (profile.enabled) {
+    if (!profile.language) errors.push("language is required when enabled=true");
+    if (!profile.buildSystem) errors.push("build_system is required when enabled=true");
+    if (profile.sourceRoots.length === 0) {
+      errors.push("source_roots must contain at least one path when enabled=true");
+    }
+  }
+  if (errors.length > 0) {
+    return { status: "invalid", path: "", errors };
+  }
+  return {
+    status: profile.enabled ? "configured" : "disabled",
+    path: "",
+    profile
+  };
+}
+async function readFirmwareProfile(projectPath) {
+  const profilePath = firmwareProfilePath(projectPath);
+  try {
+    const raw = await fs15.readFile(profilePath, "utf-8");
+    const parsed = parseFirmwareProfile(raw);
+    return { ...parsed, path: profilePath };
+  } catch (error) {
+    if (error.code === "ENOENT") {
+      return { status: "missing", path: profilePath };
+    }
+    return {
+      status: "invalid",
+      path: profilePath,
+      errors: [`failed to read firmware profile: ${error.message}`]
+    };
+  }
+}
+async function inspectCompileDatabase(projectPath, profile) {
+  if (!profile.compileDatabase) return { status: "not-configured", path: null };
+  const projectRoot = path16.resolve(projectPath);
+  const compileDatabasePath = path16.resolve(projectRoot, profile.compileDatabase);
+  if (compileDatabasePath !== projectRoot && !compileDatabasePath.startsWith(`${projectRoot}${path16.sep}`)) {
+    return {
+      status: "invalid",
+      path: compileDatabasePath,
+      message: "compile_database must stay inside the project directory"
+    };
+  }
+  try {
+    const raw = await fs15.readFile(compileDatabasePath, "utf-8");
+    const parsed = JSON.parse(raw);
+    if (!Array.isArray(parsed)) {
+      return {
+        status: "invalid",
+        path: compileDatabasePath,
+        message: "compile database must be a JSON array"
+      };
+    }
+    const sampleFiles = [];
+    const includeRoots = /* @__PURE__ */ new Set();
+    const defineFlags = /* @__PURE__ */ new Set();
+    for (const entry2 of parsed) {
+      if (entry2.file && sampleFiles.length < 5) sampleFiles.push(entry2.file.replaceAll("\\", "/"));
+      for (const token of (entry2.command ?? "").split(/\s+/u)) {
+        if (token.startsWith("-I") && token.length > 2) includeRoots.add(token.slice(2));
+        if (token.startsWith("-D") && token.length > 2) defineFlags.add(token.slice(2));
+      }
+    }
+    return {
+      status: "present",
+      path: compileDatabasePath,
+      entries: parsed.length,
+      sampleFiles,
+      includeRoots: [...includeRoots].sort(),
+      defineFlags: [...defineFlags].sort()
+    };
+  } catch (error) {
+    if (error.code === "ENOENT") {
+      return { status: "missing", path: compileDatabasePath };
+    }
+    return {
+      status: "invalid",
+      path: compileDatabasePath,
+      message: error.message
+    };
+  }
+}
+async function runFirmwareVerifyProfile(projectPath, changeName) {
+  const profileStatus = await readFirmwareProfile(projectPath);
+  if (profileStatus.status === "missing") {
+    return {
+      exitCode: 0,
+      reportStatus: "skipped",
+      summary: "skipped (missing firmware profile)",
+      report: `${writeReportHeader(changeName, "skipped")}
+- firmware profile: skipped (missing)
+`
+    };
+  }
+  if (profileStatus.status === "invalid") {
+    return {
+      exitCode: 1,
+      reportStatus: "fail",
+      summary: "invalid firmware profile",
+      report: [
+        writeReportHeader(changeName, "fail"),
+        "- firmware profile: invalid",
+        ...profileStatus.errors.map((error) => `- error: ${error}`),
+        ""
+      ].join("\n")
+    };
+  }
+  if (profileStatus.status === "disabled") {
+    return {
+      exitCode: 0,
+      reportStatus: "skipped",
+      summary: "skipped (disabled firmware profile)",
+      report: `${writeReportHeader(changeName, "skipped")}
+- firmware profile: skipped (disabled)
+`
+    };
+  }
+  const profile = profileStatus.profile;
+  if (isEmptyCommand(profile.buildCommand) && isEmptyCommand(profile.testCommand) && isEmptyCommand(profile.staticAnalysisCommand)) {
+    return {
+      exitCode: 0,
+      reportStatus: "skipped",
+      summary: "skipped (no commands configured)",
+      report: `${writeReportHeader(changeName, "skipped")}
+- firmware verification: skipped (no commands configured)
+`
+    };
+  }
+  const lines = [writeReportHeader(changeName, "pending")];
+  let failed = false;
+  for (const [label, command] of [
+    ["build_command", profile.buildCommand],
+    ["test_command", profile.testCommand],
+    ["static_analysis_command", profile.staticAnalysisCommand]
+  ]) {
+    if (isEmptyCommand(command)) {
+      lines.push(`- ${label}: skipped (not configured)`);
+      continue;
+    }
+    const result3 = runCommandString(command);
+    lines.push(`- ${label}: ${result3.status === 0 ? "pass" : "fail"}`);
+    lines.push(...commandSection(label, result3));
+    if (result3.status !== 0) failed = true;
+  }
+  return {
+    exitCode: failed ? 1 : 0,
+    reportStatus: failed ? "fail" : "pass",
+    summary: failed ? "failed" : "passed",
+    report: lines.join("\n").replace("- Status: pending", `- Status: ${failed ? "fail" : "pass"}`)
+  };
+}
+
+// domains/comet-classic/classic-firmware-verify.ts
+var GREEN2 = "\x1B[32m";
+var RED2 = "\x1B[31m";
+var YELLOW2 = "\x1B[33m";
+var RESET2 = "\x1B[0m";
+function green2(message) {
+  return `${GREEN2}${message}${RESET2}`;
+}
+function red2(message) {
+  return `${RED2}${message}${RESET2}`;
+}
+function yellow2(message) {
+  return `${YELLOW2}${message}${RESET2}`;
+}
+async function exists4(file) {
+  try {
+    await fs16.access(file);
+    return true;
+  } catch (error) {
+    if (error.code === "ENOENT") return false;
+    throw error;
+  }
+}
+function repoRelative(file) {
+  return path17.relative(process.cwd(), file).replaceAll("\\", "/");
+}
+var classicFirmwareVerifyCommand = async (args) => {
+  const changeName = args[0];
+  const nameError = openSpecChangeNameError(changeName);
+  if (nameError) {
+    return { exitCode: 1, stderr: red2(`ERROR: ${nameError}`) };
+  }
+  const { directory } = await resolveClassicChangeDirectory(changeName);
+  if (!await exists4(path17.join(directory, ".comet.yaml"))) {
+    return { exitCode: 1, stderr: red2(`ERROR: .comet.yaml not found at ${repoRelative(path17.join(directory, ".comet.yaml"))}`) };
+  }
+  const graphPaths = getChangeGraphContextPaths(directory);
+  await fs16.mkdir(graphPaths.graphDir, { recursive: true });
+  const reportPath = path17.join(graphPaths.graphDir, "firmware-verify-report.md");
+  const result3 = await runFirmwareVerifyProfile(process.cwd(), changeName);
+  await fs16.writeFile(reportPath, `${result3.report}
+`, "utf8");
+  const statusLine = result3.reportStatus === "fail" ? red2(`FIRMWARE_VERIFY: failed (${repoRelative(reportPath)})`) : result3.reportStatus === "skipped" ? yellow2(`FIRMWARE_VERIFY: ${result3.summary}`) : green2(`FIRMWARE_VERIFY: ${repoRelative(reportPath)}`);
+  return { exitCode: result3.exitCode, stderr: statusLine };
+};
+
+// domains/comet-classic/classic-graph-context.ts
+import { promises as fs17 } from "fs";
+import path18 from "path";
+var GREEN3 = "\x1B[32m";
+var RED3 = "\x1B[31m";
+var RESET3 = "\x1B[0m";
+var PHASES2 = ["open", "design", "build", "verify", "archive"];
+function green3(message) {
+  return `${GREEN3}${message}${RESET3}`;
+}
+function red3(message) {
+  return `${RED3}${message}${RESET3}`;
+}
+function fail(message, exitCode = 1) {
+  return { exitCode, stderr: message };
+}
+function validateChangeName2(name) {
+  return openSpecChangeNameError(name);
+}
+function validatePhase(value) {
+  return PHASES2.includes(value ?? "");
+}
+function repoRelative2(file) {
+  return path18.relative(process.cwd(), file).replaceAll("\\", "/");
+}
+async function cmdRefresh(args) {
+  const changeName = args[0];
+  const phaseFlag = args[1] === "--phase" ? args[2] : void 0;
+  const nameError = validateChangeName2(changeName);
+  if (nameError) return fail(red3(`ERROR: ${nameError}`));
+  if (!validatePhase(phaseFlag)) {
+    return fail(red3("Usage: comet-graph-context.mjs refresh <change-name> --phase <open|design|build|verify|archive>"));
+  }
+  const { directory } = await resolveClassicChangeDirectory(changeName);
+  const projection = await readClassicState(directory);
+  if (!projection.classic) return fail(red3("ERROR: change is missing Classic state"));
+  const runtimeConfig = await readGraphContextRuntimeConfig(
+    process.cwd(),
+    projection.classic.graphContextEnabled
+  );
+  projection.classic.graphContextEnabled = runtimeConfig.enabled;
+  if (!runtimeConfig.enabled) {
+    await writeClassicState(directory, projection);
+    return { exitCode: 0, stderr: green3("GRAPH_CONTEXT: disabled") };
+  }
+  const paths = getChangeGraphContextPaths(directory);
+  await fs17.mkdir(paths.graphDir, { recursive: true });
+  const mode = runtimeConfig.mode;
+  const codegraphIndexPath = hasCodegraphProjectIndex(process.cwd()) ? path18.join(process.cwd(), ".codegraph") : null;
+  const graphifyArtifact = getGraphifyArtifactPath(process.cwd());
+  const firmwareProfile = await readFirmwareProfile(process.cwd());
+  const compileDatabaseStatus = firmwareProfile.status === "configured" ? await inspectCompileDatabase(process.cwd(), firmwareProfile.profile) : null;
+  const changedFiles = await readChangedFilesFromGit();
+  const codegraphSnapshot = await snapshotForArtifact(codegraphIndexPath, "CodeGraph", changedFiles);
+  const graphifySnapshot = await snapshotForArtifact(graphifyArtifact, "Graphify", changedFiles);
+  const codegraphContext = collectCodegraphContext(process.cwd(), changeName, phaseFlag, mode);
+  const graphifyContext = collectGraphifyContext(process.cwd(), changeName, phaseFlag, mode);
+  await ensureGraphConstraintsFile(paths.graphConstraints);
+  const parsedConstraints = await readGraphConstraintLists(paths.graphConstraints);
+  const drift = analyzeGraphDrift({
+    changedFiles,
+    allowedPaths: parsedConstraints.allowed_paths,
+    forbiddenPaths: [
+      ...parsedConstraints.forbidden_paths,
+      ...firmwareProfile.status === "configured" ? firmwareProfile.profile.forbiddenPaths : []
+    ],
+    highRiskPaths: [
+      ...parsedConstraints.high_risk_paths,
+      ...firmwareProfile.status === "configured" ? firmwareProfile.profile.highRiskPaths : []
+    ],
+    acceptedDeviations: parsedConstraints.accepted_deviations
+  });
+  const expectedMissing = parsedConstraints.expected_symbols.filter(
+    (symbol) => !codegraphContext.summary.candidateSymbols.includes(symbol)
+  );
+  const protectedHits = await collectProtectedSymbolHits(
+    changedFiles,
+    parsedConstraints.protected_symbols
+  );
+  const driftWarnings = buildDriftWarnings(drift, expectedMissing, protectedHits);
+  const driftStatus = driftWarnings.length > 0 ? "warn" : "pass";
+  if (phaseFlag === "verify" && (drift.shouldRequireFullVerify || protectedHits.length > 0)) {
+    projection.classic.verifyMode = "full";
+  }
+  const graphState = buildGraphStatePayload({
+    phase: phaseFlag,
+    mode,
+    codegraphSnapshot,
+    codegraphSummary: codegraphContext.summary,
+    graphifySnapshot,
+    graphifySummary: graphifyContext.summary,
+    driftStatus,
+    driftWarnings,
+    changedFiles,
+    shouldRequireFullVerify: drift.shouldRequireFullVerify || protectedHits.length > 0
+  });
+  await fs17.writeFile(paths.graphState, `${JSON.stringify(graphState, null, 2)}
+`, "utf8");
+  const graphContext = renderGraphContextMarkdown({
+    changeName,
+    phase: phaseFlag,
+    mode,
+    codegraphSnapshot,
+    graphifySnapshot,
+    codegraphAnalysis: codegraphContext.analysis,
+    codegraphSummary: codegraphContext.summary,
+    graphifySummary: graphifyContext.summary,
+    driftStatus,
+    driftWarnings,
+    changedFiles,
+    firmwareProfile,
+    compileDatabaseStatus
+  });
+  await fs17.writeFile(paths.graphContext, `${graphContext}
+`, "utf8");
+  projection.classic.graphContextEnabled = true;
+  projection.classic.graphContext = repoRelative2(paths.graphContext);
+  await writeClassicState(directory, projection);
+  return { exitCode: 0, stderr: green3(`GRAPH_CONTEXT: ${repoRelative2(paths.graphContext)}`) };
+}
+async function cmdConstraints(args) {
+  const changeName = args[0];
+  const nameError = validateChangeName2(changeName);
+  if (nameError) return fail(red3(`ERROR: ${nameError}`));
+  const { directory } = await resolveClassicChangeDirectory(changeName);
+  const paths = getChangeGraphContextPaths(directory);
+  await fs17.mkdir(paths.graphDir, { recursive: true });
+  await ensureGraphConstraintsFile(paths.graphConstraints);
+  return { exitCode: 0, stdout: `${repoRelative2(paths.graphConstraints)}
+` };
+}
+async function cmdDrift(args) {
+  const changeName = args[0];
+  return cmdRefresh([changeName, "--phase", "verify"]);
+}
+var classicGraphContextCommand = async (args) => {
+  const [subcommand, ...rest] = args;
+  switch (subcommand) {
+    case "refresh":
+      return cmdRefresh(rest);
+    case "constraints":
+      return cmdConstraints(rest);
+    case "drift":
+      return cmdDrift(rest);
+    default:
+      return fail(
+        red3(
+          "Usage: comet-graph-context.mjs <refresh|constraints|drift> <change-name> [--phase <phase>]"
+        ),
+        64
+      );
+  }
+};
+
 // domains/comet-classic/classic-guard.ts
 var import_yaml4 = __toESM(require_dist(), 1);
-import { spawnSync as spawnSync2 } from "child_process";
+import { spawnSync as spawnSync4 } from "child_process";
 import { createHash as createHash4 } from "crypto";
-import { existsSync, promises as fs13, readFileSync } from "fs";
-import path14 from "path";
+import { existsSync, promises as fs19, readFileSync } from "fs";
+import path20 from "path";
 
 // domains/comet-classic/classic-runtime-evals.ts
 var STEP_EVIDENCE = {
@@ -9671,12 +11017,12 @@ async function inspectClassicChange(changeDir, name) {
 
 // domains/comet-classic/classic-validate-command.ts
 var import_yaml3 = __toESM(require_dist(), 1);
-import { promises as fs12 } from "fs";
-import path13 from "path";
-var GREEN2 = "\x1B[32m";
-var RED2 = "\x1B[31m";
-var YELLOW2 = "\x1B[33m";
-var RESET2 = "\x1B[0m";
+import { promises as fs18 } from "fs";
+import path19 from "path";
+var GREEN4 = "\x1B[32m";
+var RED4 = "\x1B[31m";
+var YELLOW3 = "\x1B[33m";
+var RESET4 = "\x1B[0m";
 var REQUIRED = [
   "workflow",
   "phase",
@@ -9702,6 +11048,7 @@ var ENUMS = {
   isolation: ["branch", "worktree"],
   verify_mode: ["light", "full"],
   auto_transition: ["true", "false"],
+  graph_context_enabled: ["true", "false"],
   verify_result: ["pending", "pass", "fail"],
   branch_status: ["pending", "handled"],
   archived: ["true", "false"],
@@ -9717,11 +11064,11 @@ var KNOWN_KEYS2 = /* @__PURE__ */ new Set([
   "classic_migration"
 ]);
 function color(code, message) {
-  return `${code}${message}${RESET2}`;
+  return `${code}${message}${RESET4}`;
 }
-async function exists3(file) {
+async function exists5(file) {
   try {
-    await fs12.access(file);
+    await fs18.access(file);
     return true;
   } catch (error) {
     if (error.code === "ENOENT") return false;
@@ -9738,44 +11085,44 @@ var classicValidateCommand = async (args) => {
   if (nameError) {
     return {
       exitCode: 1,
-      stderr: color(RED2, `ERROR: ${nameError}`)
+      stderr: color(RED4, `ERROR: ${nameError}`)
     };
   }
   const { directory, label } = await resolveClassicChangeDirectory(name);
-  const yamlFile = path13.join(directory, ".comet.yaml");
+  const yamlFile = path19.join(directory, ".comet.yaml");
   const lines = [`[VALIDATE] ${label}/.comet.yaml`];
   let errors = 0;
   let warnings = 0;
-  const fail3 = (message) => {
+  const fail4 = (message) => {
     errors += 1;
-    lines.push(color(RED2, `  FAIL: ${message}`));
+    lines.push(color(RED4, `  FAIL: ${message}`));
   };
   const warn = (message) => {
     warnings += 1;
-    lines.push(color(YELLOW2, `  WARN: ${message}`));
+    lines.push(color(YELLOW3, `  WARN: ${message}`));
   };
   let source;
   try {
-    source = await fs12.readFile(yamlFile, "utf8");
+    source = await fs18.readFile(yamlFile, "utf8");
   } catch (error) {
     if (error.code === "ENOENT") {
-      fail3(".comet.yaml does not exist");
-      lines.push("", color(RED2, `${errors} error(s), ${warnings} warning(s) — validation FAILED`));
+      fail4(".comet.yaml does not exist");
+      lines.push("", color(RED4, `${errors} error(s), ${warnings} warning(s) — validation FAILED`));
       return { exitCode: 1, stderr: lines.join("\n") };
     }
     throw error;
   }
   const document = (0, import_yaml3.parseDocument)(source);
   if (document.errors.length > 0 || !(0, import_yaml3.isMap)(document.contents)) {
-    for (const error of document.errors) fail3(error.message);
-    if (!(0, import_yaml3.isMap)(document.contents)) fail3("document root must be a mapping");
-    lines.push("", color(RED2, `${errors} error(s), ${warnings} warning(s) — validation FAILED`));
+    for (const error of document.errors) fail4(error.message);
+    if (!(0, import_yaml3.isMap)(document.contents)) fail4("document root must be a mapping");
+    lines.push("", color(RED4, `${errors} error(s), ${warnings} warning(s) — validation FAILED`));
     return { exitCode: 1, stderr: lines.join("\n") };
   }
   const record = document.toJS();
   for (const field2 of REQUIRED) {
     if (!Object.prototype.hasOwnProperty.call(record, field2)) {
-      fail3(`missing required field '${field2}'`);
+      fail4(`missing required field '${field2}'`);
     }
   }
   for (const [field2, values] of Object.entries(ENUMS)) {
@@ -9783,24 +11130,32 @@ var classicValidateCommand = async (args) => {
     const value = text(record[field2]);
     if (!value) {
       if (field2 === "auto_transition") {
-        fail3(`${field2}='' is not valid. Expected: ${values.join(" ")}`);
+        fail4(`${field2}='' is not valid. Expected: ${values.join(" ")}`);
       }
       continue;
     }
     if (!values.includes(value)) {
-      fail3(`${field2}='${value}' is not valid. Expected: ${values.join(" ")}`);
+      fail4(`${field2}='${value}' is not valid. Expected: ${values.join(" ")}`);
     }
   }
   for (const field2 of ["design_doc", "plan", "handoff_context"]) {
     const value = text(record[field2]);
-    if (value && !await exists3(path13.resolve(value))) {
-      fail3(`${field2}='${value}' does not exist on disk`);
+    if (value && !await exists5(path19.resolve(value))) {
+      fail4(`${field2}='${value}' does not exist on disk`);
+    }
+  }
+  for (const field2 of [
+    "graph_context"
+  ]) {
+    const value = text(record[field2]);
+    if (value && !await exists5(path19.resolve(value))) {
+      fail4(`${field2}='${value}' does not exist on disk`);
     }
   }
   for (const field2 of ["handoff_hash"]) {
     const value = text(record[field2]);
     if (value && !/^[a-f0-9]{64}$/u.test(value)) {
-      fail3(`${field2}='${value}' is not a sha256 hex digest`);
+      fail4(`${field2}='${value}' is not a sha256 hex digest`);
     }
   }
   for (const field2 of Object.keys(record)) {
@@ -9808,19 +11163,19 @@ var classicValidateCommand = async (args) => {
   }
   lines.push("");
   if (errors > 0) {
-    lines.push(color(RED2, `${errors} error(s), ${warnings} warning(s) — validation FAILED`));
+    lines.push(color(RED4, `${errors} error(s), ${warnings} warning(s) — validation FAILED`));
     return { exitCode: 1, stderr: lines.join("\n") };
   }
-  lines.push(color(GREEN2, `0 errors, ${warnings} warning(s) — validation PASSED`));
+  lines.push(color(GREEN4, `0 errors, ${warnings} warning(s) — validation PASSED`));
   return { exitCode: 0, stderr: lines.join("\n") };
 };
 
 // domains/comet-classic/classic-guard.ts
-var GREEN3 = "\x1B[32m";
-var RED3 = "\x1B[31m";
-var YELLOW3 = "\x1B[33m";
-var RESET3 = "\x1B[0m";
-var PHASES2 = ["open", "design", "build", "verify", "archive"];
+var GREEN5 = "\x1B[32m";
+var RED5 = "\x1B[31m";
+var YELLOW4 = "\x1B[33m";
+var RESET5 = "\x1B[0m";
+var PHASES3 = ["open", "design", "build", "verify", "archive"];
 var PHASE_HEADER = {
   open: "=== Guard: open → next ===",
   design: "=== Guard: design → build ===",
@@ -9841,14 +11196,14 @@ var CLASSIC_FIELD_WIRE_NAMES = {
   verifiedAt: "verified_at",
   verifyResult: "verify_result"
 };
-function green2(message) {
-  return `${GREEN3}${message}${RESET3}`;
+function green4(message) {
+  return `${GREEN5}${message}${RESET5}`;
 }
-function red2(message) {
-  return `${RED3}${message}${RESET3}`;
+function red4(message) {
+  return `${RED5}${message}${RESET5}`;
 }
-function yellow2(message) {
-  return `${YELLOW3}${message}${RESET3}`;
+function yellow3(message) {
+  return `${YELLOW4}${message}${RESET5}`;
 }
 function wireField(field2) {
   return CLASSIC_FIELD_WIRE_NAMES[field2] ?? String(field2);
@@ -9877,9 +11232,9 @@ var GuardOutput = class {
     };
   }
 };
-async function exists4(file) {
+async function exists6(file) {
   try {
-    await fs13.access(file);
+    await fs19.access(file);
     return true;
   } catch (error) {
     if (error.code === "ENOENT") return false;
@@ -9888,15 +11243,15 @@ async function exists4(file) {
 }
 async function nonempty(file) {
   try {
-    return (await fs13.stat(file)).size > 0;
+    return (await fs19.stat(file)).size > 0;
   } catch (error) {
     if (error.code === "ENOENT") return false;
     throw error;
   }
 }
-function validateChangeName2(name) {
+function validateChangeName3(name) {
   const error = openSpecChangeNameError(name);
-  if (error) throw new GuardFailure(red2(`ERROR: ${error}`));
+  if (error) throw new GuardFailure(red4(`ERROR: ${error}`));
 }
 async function resolveChangeDir(name) {
   return (await resolveClassicChangeDirectory(name)).label;
@@ -9925,8 +11280,8 @@ function stripWrappingQuotes(value) {
   return value;
 }
 async function readField(changeDir, field2) {
-  const file = path14.join(changeDir, ".comet.yaml");
-  const document = (0, import_yaml4.parseDocument)(await fs13.readFile(file, "utf8"), { uniqueKeys: false });
+  const file = path20.join(changeDir, ".comet.yaml");
+  const document = (0, import_yaml4.parseDocument)(await fs19.readFile(file, "utf8"), { uniqueKeys: false });
   if (document.errors.length > 0) {
     throw new GuardFailure(`ERROR: Invalid .comet.yaml: ${document.errors[0].message}`);
   }
@@ -9946,8 +11301,8 @@ async function projectConfigValue(field2, changeDir) {
     ".comet.yml",
     "comet.yml"
   ]) {
-    if (!await exists4(config)) continue;
-    for (const line of (await fs13.readFile(config, "utf8")).split(/\r?\n/u)) {
+    if (!await exists6(config)) continue;
+    for (const line of (await fs19.readFile(config, "utf8")).split(/\r?\n/u)) {
       if (new RegExp(`^${field2}:`, "u").test(line)) {
         const value = stripWrappingQuotes(
           stripInlineComment(line.replace(new RegExp(`^${field2}:\\s*`, "u"), ""))
@@ -9984,31 +11339,31 @@ function countEnglishWords(source) {
 }
 async function documentLanguageMatchesConfigured(changeDir, file) {
   const language = await configuredLanguage(changeDir);
-  const source = stripFencedCodeBlocks(await fs13.readFile(file, "utf8"));
+  const source = stripFencedCodeBlocks(await fs19.readFile(file, "utf8"));
   const cjk = countCjkChars(source);
   const englishWords = countEnglishWords(source);
   if (language === "zh-CN" && cjk < 20 && englishWords >= 20) {
-    return fail(
+    return fail2(
       `configured language is zh-CN, but ${file} appears to be English-dominant (cjk_chars=${cjk}, english_words=${englishWords}).
 Next: regenerate or rewrite this artifact in Chinese while preserving necessary technical terms.`
     );
   }
   if (language === "en" && cjk > 20 && cjk > englishWords) {
-    return fail(
+    return fail2(
       `configured language is en, but ${file} appears to be Chinese-dominant (cjk_chars=${cjk}, english_words=${englishWords}).
 Next: regenerate or rewrite this artifact in English while preserving necessary technical terms.`
     );
   }
   return pass();
 }
-function runCommandString(command) {
-  if (!command) return { status: 1, output: red2("ERROR: build/verify command is empty") };
+function runCommandString2(command) {
+  if (!command) return { status: 1, output: red4("ERROR: build/verify command is empty") };
   const split = splitCommandChain(command);
   if (typeof split === "string") {
     return {
       status: 1,
-      output: `${red2(`ERROR: build/verify command contains shell metacharacters: ${command}`)}
-${red2(
+      output: `${red4(`ERROR: build/verify command contains shell metacharacters: ${command}`)}
+${red4(
         split
       )}`
     };
@@ -10017,11 +11372,11 @@ ${red2(
   for (const part of split) {
     const segment = part.trim();
     if (!segment) {
-      return { status: 1, output: red2("ERROR: build/verify command contains an empty && step") };
+      return { status: 1, output: red4("ERROR: build/verify command contains an empty && step") };
     }
-    const result3 = spawnSync2(segment, { shell: true, encoding: "utf8", timeout: 3e5 });
+    const result3 = spawnSync4(segment, { shell: true, encoding: "utf8", timeout: 3e5 });
     const combined = `${result3.stdout ?? ""}${result3.stderr ?? ""}`.replace(/\n+$/u, "");
-    output.push(`${red2(`+ ${segment}`)}${combined ? `
+    output.push(`${red4(`+ ${segment}`)}${combined ? `
 ${combined}` : ""}`);
     if (result3.status !== 0) {
       return { status: result3.status ?? 1, output: output.join("\n") };
@@ -10069,10 +11424,10 @@ function hashFile(file) {
 async function handoffSourceFiles(changeDir) {
   const files = [`${changeDir}/proposal.md`, `${changeDir}/design.md`, `${changeDir}/tasks.md`];
   const specs = `${changeDir}/specs`;
-  if (await exists4(specs)) {
-    for (const entry2 of (await fs13.readdir(specs)).sort()) {
+  if (await exists6(specs)) {
+    for (const entry2 of (await fs19.readdir(specs)).sort()) {
       const spec = `${specs}/${entry2}/spec.md`;
-      if (await exists4(spec)) files.push(spec);
+      if (await exists6(spec)) files.push(spec);
     }
   }
   return files;
@@ -10080,34 +11435,34 @@ async function handoffSourceFiles(changeDir) {
 async function computeHandoffHash(changeDir) {
   const lines = [];
   for (const file of await handoffSourceFiles(changeDir)) {
-    if (await exists4(file)) {
+    if (await exists6(file)) {
       lines.push(`path:${file}`, `sha256:${hashFile(file)}`);
     }
   }
   return createHash4("sha256").update(lines.join("\n")).digest("hex");
 }
 async function preflight(changeDir, name) {
-  if (!await exists4(changeDir)) {
-    throw new GuardFailure(red2(`FATAL: change directory not found: ${changeDir}`));
+  if (!await exists6(changeDir)) {
+    throw new GuardFailure(red4(`FATAL: change directory not found: ${changeDir}`));
   }
-  if (!await exists4(path14.join(changeDir, ".comet.yaml"))) {
-    throw new GuardFailure(red2(`FATAL: .comet.yaml not found in ${changeDir}`));
+  if (!await exists6(path20.join(changeDir, ".comet.yaml"))) {
+    throw new GuardFailure(red4(`FATAL: .comet.yaml not found in ${changeDir}`));
   }
   const result3 = await classicValidateCommand([name], { json: false });
   if (result3.exitCode !== 0) {
     if (result3.stderr)
       process.stderr.write(result3.stderr.endsWith("\n") ? result3.stderr : `${result3.stderr}
 `);
-    throw new GuardFailure(red2("FATAL: .comet.yaml schema validation failed"));
+    throw new GuardFailure(red4("FATAL: .comet.yaml schema validation failed"));
   }
 }
 function pushCheck(output, outcome) {
   if (outcome.passed) {
-    output.stderr.push(green2(`  [PASS] ${outcome.description}`));
+    output.stderr.push(green4(`  [PASS] ${outcome.description}`));
   } else {
-    output.stderr.push(red2(`  [FAIL] ${outcome.description}`));
+    output.stderr.push(red4(`  [FAIL] ${outcome.description}`));
     if (outcome.detail) {
-      for (const line of outcome.detail.split("\n")) output.stderr.push(red2(`    ${line}`));
+      for (const line of outcome.detail.split("\n")) output.stderr.push(red4(`    ${line}`));
     }
   }
 }
@@ -10132,7 +11487,7 @@ function check(description, run) {
 function pass() {
   return { passed: true };
 }
-function fail(detail) {
+function fail2(detail) {
   return { passed: false, detail };
 }
 async function runChecks(output, builders) {
@@ -10145,7 +11500,7 @@ async function runChecks(output, builders) {
   return blocked2;
 }
 function runInferred(command) {
-  const result3 = spawnSync2(command, { shell: true, encoding: "utf8", timeout: 3e5 });
+  const result3 = spawnSync4(command, { shell: true, encoding: "utf8", timeout: 3e5 });
   return {
     status: result3.status ?? 1,
     output: `${result3.stdout ?? ""}${result3.stderr ?? ""}`.replace(/\n+$/u, "")
@@ -10154,11 +11509,11 @@ function runInferred(command) {
 async function buildPasses(changeDir) {
   if (process.env.COMET_SKIP_BUILD === "1") return { status: 0, output: "" };
   const configured = await projectConfigValue("build_command", changeDir);
-  if (configured) return runCommandString(configured);
-  if (await exists4("package.json") && /"build"/u.test(await fs13.readFile("package.json", "utf8"))) {
+  if (configured) return runCommandString2(configured);
+  if (await exists6("package.json") && /"build"/u.test(await fs19.readFile("package.json", "utf8"))) {
     return runInferred("npm run build");
   }
-  if (await exists4("pom.xml")) {
+  if (await exists6("pom.xml")) {
     if (process.platform === "win32") {
       if (existsSync("mvnw.cmd")) return runInferred("mvnw.cmd compile -q");
       return runInferred("mvn.cmd compile -q");
@@ -10166,32 +11521,32 @@ async function buildPasses(changeDir) {
     if (existsSync("mvnw")) return runInferred("./mvnw compile -q");
     return runInferred("mvn compile -q");
   }
-  if (await exists4("Cargo.toml")) return runInferred("cargo build");
+  if (await exists6("Cargo.toml")) return runInferred("cargo build");
   return { status: 1, output: "" };
 }
 async function verificationCommandPasses(changeDir) {
   if (process.env.COMET_SKIP_BUILD === "1") return { status: 0, output: "" };
   const configured = await projectConfigValue("verify_command", changeDir);
-  if (configured) return runCommandString(configured);
+  if (configured) return runCommandString2(configured);
   return buildPasses(changeDir);
 }
 async function tasksAllDone(changeDir) {
-  const tasks = path14.join(changeDir, "tasks.md");
-  if (!await exists4(tasks)) {
-    return fail(
+  const tasks = path20.join(changeDir, "tasks.md");
+  if (!await exists6(tasks)) {
+    return fail2(
       `tasks.md is missing at ${tasks}
 Next: restore or create tasks.md for this change before leaving build.`
     );
   }
-  const source = await fs13.readFile(tasks, "utf8");
+  const source = await fs19.readFile(tasks, "utf8");
   if (!/- \[x\]/u.test(source)) {
-    return fail(
+    return fail2(
       "tasks.md has no completed tasks.\nNext: complete implementation tasks and mark them with '- [x]'."
     );
   }
   const unfinished = source.split(/\r?\n/u).map((line, index) => ({ line, number: index + 1 })).filter((entry2) => /^- \[ \]/u.test(entry2.line));
   if (unfinished.length > 0) {
-    return fail(
+    return fail2(
       `Unfinished tasks:
 ${unfinished.map((entry2) => `${entry2.number}:${entry2.line}`).join("\n")}
 Next: complete or explicitly remove unfinished tasks, then mark tasks.md with '- [x]'.`
@@ -10200,23 +11555,23 @@ Next: complete or explicitly remove unfinished tasks, then mark tasks.md with '-
   return pass();
 }
 async function tasksHasAny(changeDir) {
-  const tasks = path14.join(changeDir, "tasks.md");
-  if (!await exists4(tasks)) return false;
-  return /- \[/u.test(await fs13.readFile(tasks, "utf8"));
+  const tasks = path20.join(changeDir, "tasks.md");
+  if (!await exists6(tasks)) return false;
+  return /- \[/u.test(await fs19.readFile(tasks, "utf8"));
 }
 async function planTasksAllDone(changeDir) {
   const plan = await readField(changeDir, "plan");
   if (!plan || plan === "null") return pass();
-  if (!await exists4(plan)) {
-    return fail(
+  if (!await exists6(plan)) {
+    return fail2(
       `plan file is missing at ${plan}
 Next: restore the Superpowers plan file or update .comet.yaml plan before leaving build.`
     );
   }
-  const source = await fs13.readFile(plan, "utf8");
+  const source = await fs19.readFile(plan, "utf8");
   const unfinished = source.split(/\r?\n/u).map((line, index) => ({ line, number: index + 1 })).filter((entry2) => /^\s*- \[ \]/u.test(entry2.line));
   if (unfinished.length > 0) {
-    return fail(
+    return fail2(
       `Unfinished Superpowers plan tasks:
 ${unfinished.map((entry2) => `${entry2.number}:${entry2.line}`).join("\n")}
 Next: check off corresponding completed plan tasks, then commit the plan update.`
@@ -10227,7 +11582,7 @@ Next: check off corresponding completed plan tasks, then commit the plan update.
 async function isolationSelected(changeDir, change) {
   const isolation = await readField(changeDir, "isolation");
   if (isolation === "branch" || isolation === "worktree") return pass();
-  return fail(
+  return fail2(
     `isolation must be branch or worktree, got '${isolation || "null"}'
 Next: ask the user to choose branch or worktree, create the chosen isolation, then run:
   node "$COMET_STATE" set ${change} isolation <branch|worktree>`
@@ -10237,7 +11592,7 @@ async function buildModeSelected(changeDir, change) {
   const buildMode = await readField(changeDir, "build_mode");
   if (["subagent-driven-development", "executing-plans", "direct"].includes(buildMode))
     return pass();
-  return fail(
+  return fail2(
     `build_mode must be selected before leaving build, got '${buildMode || "null"}'
 Next: ask the user to choose an execution mode, then run:
   node "$COMET_STATE" set ${change} build_mode <subagent-driven-development|executing-plans>`
@@ -10250,7 +11605,7 @@ async function buildModeAllowedForWorkflow(changeDir) {
   if (buildMode !== "direct") return pass();
   if (workflow === "hotfix" || workflow === "tweak") return pass();
   if (directOverride === "true") return pass();
-  return fail(
+  return fail2(
     "build_mode=direct is only allowed for hotfix/tweak unless direct_override: true is recorded\nNext: choose executing-plans or subagent-driven-development, or stop and ask the user for an explicit direct override."
   );
 }
@@ -10259,7 +11614,7 @@ async function subagentDispatchConfirmed(changeDir, change) {
   const subagentDispatch = await readField(changeDir, "subagent_dispatch");
   if (buildMode !== "subagent-driven-development") return pass();
   if (subagentDispatch === "confirmed") return pass();
-  return fail(
+  return fail2(
     `subagent_dispatch must be confirmed before using build_mode=subagent-driven-development
 Next: confirm the current platform has a real background subagent/Task/multi-agent dispatcher, then run:
   node "$COMET_STATE" set ${change} subagent_dispatch confirmed
@@ -10272,7 +11627,7 @@ async function tddModeSelected(changeDir, change) {
   if (workflow === "hotfix" || workflow === "tweak") return pass();
   const tddMode = await readField(changeDir, "tdd_mode");
   if (tddMode === "tdd" || tddMode === "direct") return pass();
-  return fail(
+  return fail2(
     `tdd_mode must be tdd or direct for full workflow, got '${tddMode || "null"}'
 Next: ask the user to choose TDD enforcement level, then run:
   node "$COMET_STATE" set ${change} tdd_mode <tdd|direct>`
@@ -10285,7 +11640,7 @@ async function reviewModeSelected(changeDir, change) {
   if (reviewMode === "off" || reviewMode === "standard" || reviewMode === "thorough") {
     return pass();
   }
-  return fail(
+  return fail2(
     `review_mode must be off, standard, or thorough before leaving build, got '${reviewMode || "null"}'
 Next: ask the user to choose review strength, then run:
   node "$COMET_STATE" set ${change} review_mode <off|standard|thorough>`
@@ -10302,7 +11657,7 @@ async function archivedIsTrue(changeDir) {
   return await readField(changeDir, "archived") === "true";
 }
 async function designDocFrontmatterHas(designDoc, field2, expected) {
-  const source = (await fs13.readFile(designDoc, "utf8")).replace(/^\uFEFF/u, "");
+  const source = (await fs19.readFile(designDoc, "utf8")).replace(/^\uFEFF/u, "");
   let inFrontmatter = false;
   for (const line of source.split(/\r?\n/u)) {
     if (!inFrontmatter) {
@@ -10317,7 +11672,7 @@ async function designDocFrontmatterHas(designDoc, field2, expected) {
 async function designDocRecorded(changeDir, change) {
   const designDoc = await readField(changeDir, "design_doc");
   if (designDoc && designDoc !== "null" && existsSync(designDoc)) return pass();
-  return fail(
+  return fail2(
     `design_doc must point to an existing Superpowers Design Doc for full workflow before leaving design.
 Next: create the Design Doc and run: node "$COMET_STATE" set ${change} design_doc <path>`
   );
@@ -10326,26 +11681,26 @@ async function designHandoffContextValid(changeDir, change) {
   const context = await readField(changeDir, "handoff_context");
   const recordedHash = await readField(changeDir, "handoff_hash");
   if (!context || context === "null") {
-    return fail(
+    return fail2(
       `handoff_context is missing from .comet.yaml
 Next: run node "$COMET_HANDOFF" ${change} design --write before invoking Superpowers.`
     );
   }
   if (!await nonempty(context)) {
-    return fail(
+    return fail2(
       `handoff_context does not point to a non-empty file: ${context}
 Next: regenerate the design handoff with comet-handoff.mjs.`
     );
   }
   if (!/^[a-f0-9]{64}$/u.test(recordedHash)) {
-    return fail(
+    return fail2(
       `handoff_hash is missing or invalid: ${recordedHash || "null"}
 Next: regenerate the design handoff with comet-handoff.mjs.`
     );
   }
   const actualHash = await computeHandoffHash(changeDir);
   if (actualHash !== recordedHash) {
-    return fail(
+    return fail2(
       `OpenSpec artifacts changed after handoff was generated.
 Expected handoff_hash: ${recordedHash}
 Actual handoff_hash:   ${actualHash}
@@ -10354,7 +11709,7 @@ Next: rerun comet-handoff.mjs so Superpowers receives the current OpenSpec conte
   }
   const markdown = `${context.replace(/\.json$/u, "")}.md`;
   if (!await nonempty(markdown)) {
-    return fail(
+    return fail2(
       `design handoff markdown is missing or empty: ${markdown}
 Next: regenerate the design handoff with comet-handoff.mjs.`
     );
@@ -10363,11 +11718,11 @@ Next: regenerate the design handoff with comet-handoff.mjs.`
 }
 async function designHandoffMarkdownTraceable(changeDir) {
   const context = await readField(changeDir, "handoff_context");
-  if (!context || context === "null") return fail("handoff_context is missing from .comet.yaml");
+  if (!context || context === "null") return fail2("handoff_context is missing from .comet.yaml");
   const markdown = `${context.replace(/\.json$/u, "")}.md`;
   if (!await nonempty(markdown))
-    return fail(`design handoff markdown is missing or empty: ${markdown}`);
-  const source = await fs13.readFile(markdown, "utf8");
+    return fail2(`design handoff markdown is missing or empty: ${markdown}`);
+  const source = await fs19.readFile(markdown, "utf8");
   const problems = [];
   if (!/^Generated-by: comet-handoff\.sh$/mu.test(source)) {
     problems.push("handoff markdown is missing Generated-by marker");
@@ -10376,7 +11731,7 @@ async function designHandoffMarkdownTraceable(changeDir) {
     problems.push("handoff markdown is missing Mode marker");
   }
   for (const file of await handoffSourceFiles(changeDir)) {
-    if (!await exists4(file)) continue;
+    if (!await exists6(file)) continue;
     if (!new RegExp(`^- Source: ${file}$`, "mu").test(source)) {
       problems.push(`handoff markdown is missing source reference: ${file}`);
     }
@@ -10384,7 +11739,7 @@ async function designHandoffMarkdownTraceable(changeDir) {
       problems.push(`handoff markdown is missing current sha256 for: ${file}`);
     }
   }
-  return problems.length === 0 ? pass() : fail(problems.join("\n"));
+  return problems.length === 0 ? pass() : fail2(problems.join("\n"));
 }
 async function contextCompressionMode(changeDir) {
   return await readField(changeDir, "context_compression") || "off";
@@ -10392,20 +11747,20 @@ async function contextCompressionMode(changeDir) {
 async function betaSpecJsonStructurallyValid(changeDir) {
   if (await contextCompressionMode(changeDir) !== "beta") return pass();
   const context = await readField(changeDir, "handoff_context");
-  if (!context || context === "null") return fail("handoff_context is missing from .comet.yaml");
-  if (!await nonempty(context)) return fail(`spec-context.json is missing or empty: ${context}`);
-  const source = await fs13.readFile(context, "utf8");
+  if (!context || context === "null") return fail2("handoff_context is missing from .comet.yaml");
+  if (!await nonempty(context)) return fail2(`spec-context.json is missing or empty: ${context}`);
+  const source = await fs19.readFile(context, "utf8");
   const problems = [];
   let parsed;
   try {
     parsed = JSON.parse(source);
   } catch (error) {
-    return fail(
+    return fail2(
       `spec-context.json invalid JSON: ${error instanceof Error ? error.message : String(error)}`
     );
   }
   if (!parsed || typeof parsed !== "object" || Array.isArray(parsed)) {
-    return fail("spec-context.json root must be an object");
+    return fail2("spec-context.json root must be an object");
   }
   const record = parsed;
   if (typeof record.change !== "string") problems.push("spec-context.json missing 'change' field");
@@ -10419,35 +11774,35 @@ async function betaSpecJsonStructurallyValid(changeDir) {
     (file) => Boolean(file) && typeof file === "object" && !Array.isArray(file)
   ) : [];
   for (const file of await handoffSourceFiles(changeDir)) {
-    if (!await exists4(file)) continue;
+    if (!await exists6(file)) continue;
     if (!files.some((entry2) => entry2.path === file && typeof entry2.sha256 === "string")) {
       problems.push(`spec-context.json missing source file reference: ${file}`);
     }
   }
-  return problems.length === 0 ? pass() : fail(problems.join("\n"));
+  return problems.length === 0 ? pass() : fail2(problems.join("\n"));
 }
 async function guardOpenChecks(output, changeDir) {
   const workflow = await readField(changeDir, "workflow");
   const checks = [
     check(
       "proposal.md exists and non-empty",
-      async () => await nonempty(path14.join(changeDir, "proposal.md")) ? pass() : fail("")
+      async () => await nonempty(path20.join(changeDir, "proposal.md")) ? pass() : fail2("")
     ),
     check(
       "proposal.md matches configured language",
-      () => documentLanguageMatchesConfigured(changeDir, path14.join(changeDir, "proposal.md"))
+      () => documentLanguageMatchesConfigured(changeDir, path20.join(changeDir, "proposal.md"))
     ),
     check(
       "tasks.md exists and non-empty",
-      async () => await nonempty(path14.join(changeDir, "tasks.md")) ? pass() : fail("")
+      async () => await nonempty(path20.join(changeDir, "tasks.md")) ? pass() : fail2("")
     ),
     check(
       "tasks.md matches configured language",
-      () => documentLanguageMatchesConfigured(changeDir, path14.join(changeDir, "tasks.md"))
+      () => documentLanguageMatchesConfigured(changeDir, path20.join(changeDir, "tasks.md"))
     ),
     check(
       "tasks.md has at least one task",
-      async () => await tasksHasAny(changeDir) ? pass() : fail("")
+      async () => await tasksHasAny(changeDir) ? pass() : fail2("")
     )
   ];
   if (workflow === "full") {
@@ -10456,11 +11811,11 @@ async function guardOpenChecks(output, changeDir) {
       0,
       check(
         "design.md exists and non-empty",
-        async () => await nonempty(path14.join(changeDir, "design.md")) ? pass() : fail("")
+        async () => await nonempty(path20.join(changeDir, "design.md")) ? pass() : fail2("")
       ),
       check(
         "design.md matches configured language",
-        () => documentLanguageMatchesConfigured(changeDir, path14.join(changeDir, "design.md"))
+        () => documentLanguageMatchesConfigured(changeDir, path20.join(changeDir, "design.md"))
       )
     );
   }
@@ -10472,27 +11827,27 @@ async function guardDesignChecks(output, changeDir, change) {
   const builders = [
     check(
       "proposal.md exists",
-      async () => await nonempty(path14.join(changeDir, "proposal.md")) ? pass() : fail("")
+      async () => await nonempty(path20.join(changeDir, "proposal.md")) ? pass() : fail2("")
     ),
     check(
       "proposal.md matches configured language",
-      () => documentLanguageMatchesConfigured(changeDir, path14.join(changeDir, "proposal.md"))
+      () => documentLanguageMatchesConfigured(changeDir, path20.join(changeDir, "proposal.md"))
     ),
     check(
       "design.md exists",
-      async () => await nonempty(path14.join(changeDir, "design.md")) ? pass() : fail("")
+      async () => await nonempty(path20.join(changeDir, "design.md")) ? pass() : fail2("")
     ),
     check(
       "design.md matches configured language",
-      () => documentLanguageMatchesConfigured(changeDir, path14.join(changeDir, "design.md"))
+      () => documentLanguageMatchesConfigured(changeDir, path20.join(changeDir, "design.md"))
     ),
     check(
       "tasks.md exists",
-      async () => await nonempty(path14.join(changeDir, "tasks.md")) ? pass() : fail("")
+      async () => await nonempty(path20.join(changeDir, "tasks.md")) ? pass() : fail2("")
     ),
     check(
       "tasks.md matches configured language",
-      () => documentLanguageMatchesConfigured(changeDir, path14.join(changeDir, "tasks.md"))
+      () => documentLanguageMatchesConfigured(changeDir, path20.join(changeDir, "tasks.md"))
     ),
     check("design handoff context exists", () => designHandoffContextValid(changeDir, change)),
     check("design handoff markdown is traceable", () => designHandoffMarkdownTraceable(changeDir))
@@ -10515,28 +11870,28 @@ async function guardDesignChecks(output, changeDir, change) {
     blocked2 = await runChecks(output, [
       check(
         `Design Doc (${designDoc}) exists`,
-        async () => await nonempty(designDoc) ? pass() : fail("")
+        async () => await nonempty(designDoc) ? pass() : fail2("")
       ),
       check(
         "Design Doc matches configured language",
         () => documentLanguageMatchesConfigured(changeDir, designDoc)
       ),
       check("Design Doc frontmatter links current change", async () => {
-        if (!await nonempty(designDoc)) return fail("");
-        return await designDocFrontmatterHas(designDoc, "comet_change", change) ? pass() : fail("");
+        if (!await nonempty(designDoc)) return fail2("");
+        return await designDocFrontmatterHas(designDoc, "comet_change", change) ? pass() : fail2("");
       }),
       check("Design Doc declares technical design role", async () => {
-        if (!await nonempty(designDoc)) return fail("");
-        return await designDocFrontmatterHas(designDoc, "role", "technical-design") ? pass() : fail("");
+        if (!await nonempty(designDoc)) return fail2("");
+        return await designDocFrontmatterHas(designDoc, "role", "technical-design") ? pass() : fail2("");
       }),
       check("Design Doc declares OpenSpec as canonical spec", async () => {
-        if (!await nonempty(designDoc)) return fail("");
-        return await designDocFrontmatterHas(designDoc, "canonical_spec", "openspec") ? pass() : fail("");
+        if (!await nonempty(designDoc)) return fail2("");
+        return await designDocFrontmatterHas(designDoc, "canonical_spec", "openspec") ? pass() : fail2("");
       })
     ]) || blocked2;
   } else if (workflow !== "full") {
     output.stderr.push(
-      yellow2("  [WARN] No design_doc recorded in .comet.yaml (optional for hotfix/tweak)")
+      yellow3("  [WARN] No design_doc recorded in .comet.yaml (optional for hotfix/tweak)")
     );
   }
   return blocked2;
@@ -10553,22 +11908,22 @@ async function guardBuildChecks(output, changeDir, change) {
     check("Superpowers plan all tasks checked", () => planTasksAllDone(changeDir)),
     check(
       "proposal.md exists",
-      async () => await nonempty(path14.join(changeDir, "proposal.md")) ? pass() : fail("")
+      async () => await nonempty(path20.join(changeDir, "proposal.md")) ? pass() : fail2("")
     ),
     check(
       "proposal.md matches configured language",
-      () => documentLanguageMatchesConfigured(changeDir, path14.join(changeDir, "proposal.md"))
+      () => documentLanguageMatchesConfigured(changeDir, path20.join(changeDir, "proposal.md"))
     ),
     check("Superpowers plan matches configured language", async () => {
       const plan = await readField(changeDir, "plan");
-      if (!plan || plan === "null" || !await exists4(plan)) return pass();
+      if (!plan || plan === "null" || !await exists6(plan)) return pass();
       return documentLanguageMatchesConfigured(changeDir, plan);
     }),
     // Build check runs last — only after all config checks pass — to avoid
     // wasting time on a build that would be rejected by a config failure.
     check("Build passes", async () => {
       const buildResult = await buildPasses(changeDir);
-      return buildResult.status === 0 ? pass() : fail(buildResult.output);
+      return buildResult.status === 0 ? pass() : fail2(buildResult.output);
     })
   ]);
 }
@@ -10579,33 +11934,33 @@ async function guardVerifyChecks(output, changeDir) {
     // if tasks.md is incomplete.
     check("Verification passes", async () => {
       const verifyResult = await verificationCommandPasses(changeDir);
-      return verifyResult.status === 0 ? pass() : fail(verifyResult.output);
+      return verifyResult.status === 0 ? pass() : fail2(verifyResult.output);
     }),
     check(
       "verification_report exists",
-      async () => await verificationReportExists(changeDir) ? pass() : fail("")
+      async () => await verificationReportExists(changeDir) ? pass() : fail2("")
     ),
     check("verification_report matches configured language", async () => {
       const report = await readField(changeDir, "verification_report");
-      if (!report || report === "null" || !await exists4(report)) return pass();
+      if (!report || report === "null" || !await exists6(report)) return pass();
       return documentLanguageMatchesConfigured(changeDir, report);
     }),
     check(
       "branch_status=handled",
-      async () => await branchStatusHandled(changeDir) ? pass() : fail("")
+      async () => await branchStatusHandled(changeDir) ? pass() : fail2("")
     )
   ]);
 }
 async function guardArchiveChecks(output, changeDir) {
   return runChecks(output, [
-    check("archived is true", async () => await archivedIsTrue(changeDir) ? pass() : fail("")),
+    check("archived is true", async () => await archivedIsTrue(changeDir) ? pass() : fail2("")),
     check(
       "proposal.md exists",
-      async () => await nonempty(path14.join(changeDir, "proposal.md")) ? pass() : fail("")
+      async () => await nonempty(path20.join(changeDir, "proposal.md")) ? pass() : fail2("")
     ),
     check(
       "design.md exists",
-      async () => await nonempty(path14.join(changeDir, "design.md")) ? pass() : fail("")
+      async () => await nonempty(path20.join(changeDir, "design.md")) ? pass() : fail2("")
     ),
     check("tasks.md all tasks checked", () => tasksAllDone(changeDir))
   ]);
@@ -10628,21 +11983,21 @@ async function applyStateUpdate(output, change, changeDir, phase, context) {
     effects: result3.effects
   });
   for (const effect of result3.effects) {
-    output.stderr.push(green2(`[SET] ${wireField(effect.field)}=${wireValue(effect.to)}`));
+    output.stderr.push(green4(`[SET] ${wireField(effect.field)}=${wireValue(effect.to)}`));
   }
-  output.stderr.push(green2(`[TRANSITION] ${event}`));
+  output.stderr.push(green4(`[TRANSITION] ${event}`));
   const template = APPLY_MESSAGE[phase];
   const message = phase === "open" ? template.replace("PLACEHOLDER", result3.classic.phase) : template;
-  output.stderr.push(green2(message));
+  output.stderr.push(green4(message));
 }
 var classicGuardCommand = async (args, options) => {
   const output = new GuardOutput();
   const [change, phase, flag] = args;
   try {
-    validateChangeName2(change);
-    if (!phase || !PHASES2.includes(phase)) {
+    validateChangeName3(change);
+    if (!phase || !PHASES3.includes(phase)) {
       throw new GuardFailure(
-        `${red2(`Unknown phase: ${phase ?? ""}`)}
+        `${red4(`Unknown phase: ${phase ?? ""}`)}
 Valid phases: open, design, build, verify, archive`
       );
     }
@@ -10667,11 +12022,11 @@ Valid phases: open, design, build, verify, archive`
     else blocked2 = await guardArchiveChecks(output, changeDir);
     if (blocked2) {
       output.stderr.push("");
-      output.stderr.push(red2("BLOCKED — fix failing checks before proceeding to next phase"));
+      output.stderr.push(red4("BLOCKED — fix failing checks before proceeding to next phase"));
       return output.toResult(1);
     }
     output.stderr.push("");
-    output.stderr.push(green2("ALL CHECKS PASSED — ready for next phase"));
+    output.stderr.push(green4("ALL CHECKS PASSED — ready for next phase"));
     if (flag === "--apply") {
       await applyStateUpdate(output, change, changeDir, phase, runContext);
     }
@@ -10688,20 +12043,20 @@ Valid phases: open, design, build, verify, archive`
 // domains/comet-classic/classic-handoff.ts
 var import_yaml5 = __toESM(require_dist(), 1);
 import { createHash as createHash5 } from "crypto";
-import { promises as fs14, readFileSync as readFileSync2 } from "fs";
-import path15 from "path";
-var GREEN4 = "\x1B[32m";
-var RED4 = "\x1B[31m";
-var YELLOW4 = "\x1B[33m";
-var RESET4 = "\x1B[0m";
-function green3(message) {
-  return `${GREEN4}${message}${RESET4}`;
+import { promises as fs20, readFileSync as readFileSync2 } from "fs";
+import path21 from "path";
+var GREEN6 = "\x1B[32m";
+var RED6 = "\x1B[31m";
+var YELLOW5 = "\x1B[33m";
+var RESET6 = "\x1B[0m";
+function green5(message) {
+  return `${GREEN6}${message}${RESET6}`;
 }
-function red3(message) {
-  return `${RED4}${message}${RESET4}`;
+function red5(message) {
+  return `${RED6}${message}${RESET6}`;
 }
-function yellow3(message) {
-  return `${YELLOW4}${message}${RESET4}`;
+function yellow4(message) {
+  return `${YELLOW5}${message}${RESET6}`;
 }
 var HandoffFailure = class extends Error {
   constructor(message, exitCode = 1) {
@@ -10721,9 +12076,9 @@ var HandoffOutput = class {
     };
   }
 };
-async function exists5(file) {
+async function exists7(file) {
   try {
-    await fs14.access(file);
+    await fs20.access(file);
     return true;
   } catch (error) {
     if (error.code === "ENOENT") return false;
@@ -10732,15 +12087,15 @@ async function exists5(file) {
 }
 async function nonempty2(file) {
   try {
-    return (await fs14.stat(file)).size > 0;
+    return (await fs20.stat(file)).size > 0;
   } catch (error) {
     if (error.code === "ENOENT") return false;
     throw error;
   }
 }
-function validateChangeName3(name) {
+function validateChangeName4(name) {
   const error = openSpecChangeNameError(name);
-  if (error) throw new HandoffFailure(red3(`ERROR: ${error}`));
+  if (error) throw new HandoffFailure(red5(`ERROR: ${error}`));
 }
 function hashFile2(file) {
   return createHash5("sha256").update(readFileSync2(file)).digest("hex");
@@ -10760,10 +12115,10 @@ function artifactsHash2(artifacts) {
 async function handoffSourceFiles2(changeDir) {
   const files = [`${changeDir}/proposal.md`, `${changeDir}/design.md`, `${changeDir}/tasks.md`];
   const specs = `${changeDir}/specs`;
-  if (await exists5(specs)) {
-    for (const entry2 of (await fs14.readdir(specs)).sort()) {
+  if (await exists7(specs)) {
+    for (const entry2 of (await fs20.readdir(specs)).sort()) {
       const spec = `${specs}/${entry2}/spec.md`;
-      if (await exists5(spec)) files.push(spec);
+      if (await exists7(spec)) files.push(spec);
     }
   }
   return files;
@@ -10771,7 +12126,7 @@ async function handoffSourceFiles2(changeDir) {
 async function computeContextHash(changeDir) {
   const lines = [];
   for (const file of await handoffSourceFiles2(changeDir)) {
-    if (await exists5(file)) {
+    if (await exists7(file)) {
       lines.push(`path:${file}`, `sha256:${hashFile2(file)}`);
     }
   }
@@ -10808,8 +12163,8 @@ async function writeMarkdownContext(changeDir, change, mode, contextHash, output
     ""
   ];
   for (const file of await handoffSourceFiles2(changeDir)) {
-    if (!await exists5(file)) continue;
-    const content = await fs14.readFile(file, "utf8");
+    if (!await exists7(file)) continue;
+    const content = await fs20.readFile(file, "utf8");
     const total = lineCount(content);
     lines.push(
       `## ${file}`,
@@ -10834,12 +12189,12 @@ async function writeMarkdownContext(changeDir, change, mode, contextHash, output
     }
     lines.push("");
   }
-  await fs14.writeFile(output, lines.join("\n"));
+  await fs20.writeFile(output, lines.join("\n"));
 }
 async function writeJsonContext(changeDir, change, mode, contextHash, output) {
   const entries = [];
   for (const file of await handoffSourceFiles2(changeDir)) {
-    if (!await exists5(file)) continue;
+    if (!await exists7(file)) continue;
     entries.push(`    { "path": "${jsonEscape(file)}", "sha256": "${hashFile2(file)}" }`);
   }
   const filesBlock = entries.join(",\n");
@@ -10857,7 +12212,7 @@ async function writeJsonContext(changeDir, change, mode, contextHash, output) {
     "}",
     ""
   ].join("\n");
-  await fs14.writeFile(output, document);
+  await fs20.writeFile(output, document);
 }
 async function writeSpecProjectionForFile(file, content) {
   return [
@@ -10890,18 +12245,18 @@ async function writeSpecMarkdownContext(changeDir, change, contextHash, output)
     ""
   ];
   for (const file of await handoffSourceFiles2(changeDir)) {
-    if (!await exists5(file)) continue;
+    if (!await exists7(file)) continue;
     lines.push(`- Source: ${file}`, `- SHA256: ${hashFile2(file)}`);
   }
   lines.push("", "## Acceptance Projection", "");
   const specs = `${changeDir}/specs`;
   let projected = false;
-  if (await exists5(specs)) {
-    for (const entry2 of (await fs14.readdir(specs)).sort()) {
+  if (await exists7(specs)) {
+    for (const entry2 of (await fs20.readdir(specs)).sort()) {
       const spec = `${specs}/${entry2}/spec.md`;
-      if (!await exists5(spec)) continue;
+      if (!await exists7(spec)) continue;
       projected = true;
-      lines.push(...await writeSpecProjectionForFile(spec, await fs14.readFile(spec, "utf8")));
+      lines.push(...await writeSpecProjectionForFile(spec, await fs20.readFile(spec, "utf8")));
     }
   }
   if (!projected) {
@@ -10910,16 +12265,16 @@ async function writeSpecMarkdownContext(changeDir, change, contextHash, output)
   lines.push(
     "Full source files remain canonical. If a required heading or scenario is missing here, regenerate the handoff or read the source spec directly. Supporting files (proposal, design, tasks) are referenced by hash only."
   );
-  await fs14.writeFile(output, lines.join("\n"));
+  await fs20.writeFile(output, lines.join("\n"));
 }
 async function writeSpecJsonContext(changeDir, change, contextHash, output) {
   const entries = [];
   for (const file of await handoffSourceFiles2(changeDir)) {
-    if (!await exists5(file)) continue;
+    if (!await exists7(file)) continue;
     const role = /\/specs\/[^/]+\/spec\.md$/u.test(file) ? "spec" : "supporting";
     entries.push({ path: file, sha256: hashFile2(file), role });
   }
-  await fs14.writeFile(
+  await fs20.writeFile(
     output,
     `${JSON.stringify(
       {
@@ -10938,8 +12293,8 @@ async function writeSpecJsonContext(changeDir, change, contextHash, output) {
   );
 }
 async function readField2(changeDir, field2) {
-  const file = path15.join(changeDir, ".comet.yaml");
-  const document = (0, import_yaml5.parseDocument)(await fs14.readFile(file, "utf8"), { uniqueKeys: false });
+  const file = path21.join(changeDir, ".comet.yaml");
+  const document = (0, import_yaml5.parseDocument)(await fs20.readFile(file, "utf8"), { uniqueKeys: false });
   if (document.errors.length > 0) {
     throw new HandoffFailure(`ERROR: Invalid .comet.yaml: ${document.errors[0].message}`);
   }
@@ -10972,8 +12327,8 @@ async function completedHandoffIsCurrent(changeDir, run, contextHash, contextJso
     readArtifacts(changeDir, run.artifactsRef),
     readCheckpoint(changeDir, run.checkpointRef)
   ]);
-  if (!await exists5(contextJson) || !await exists5(contextMd)) return false;
-  if (context !== await fs14.readFile(contextMd, "utf8")) return false;
+  if (!await exists7(contextJson) || !await exists7(contextMd)) return false;
+  if (context !== await fs20.readFile(contextMd, "utf8")) return false;
   if (artifacts.handoff_context !== contextJson || artifacts.handoff_markdown !== contextMd) {
     return false;
   }
@@ -10983,16 +12338,16 @@ var classicHandoffCommand = async (args) => {
   const output = new HandoffOutput();
   const [change, phase, mode, fullFlag] = args;
   try {
-    validateChangeName3(change);
+    validateChangeName4(change);
     const changeDir = `openspec/changes/${change}`;
     if (phase === "--hash-only") {
-      if (!await exists5(changeDir)) {
-        throw new HandoffFailure(red3(`ERROR: change directory not found: ${changeDir}`));
+      if (!await exists7(changeDir)) {
+        throw new HandoffFailure(red5(`ERROR: change directory not found: ${changeDir}`));
       }
       for (const required2 of ["proposal.md", "design.md", "tasks.md"]) {
         if (!await nonempty2(`${changeDir}/${required2}`)) {
           throw new HandoffFailure(
-            red3(`ERROR: required file missing or empty: ${changeDir}/${required2}`)
+            red5(`ERROR: required file missing or empty: ${changeDir}/${required2}`)
           );
         }
       }
@@ -11001,7 +12356,7 @@ var classicHandoffCommand = async (args) => {
     }
     if (phase !== "design" || mode !== "--write") {
       throw new HandoffFailure(
-        red3("Usage: comet-handoff.mjs <change-name> design --write [--full]")
+        red5("Usage: comet-handoff.mjs <change-name> design --write [--full]")
       );
     }
     let handoffMode;
@@ -11009,22 +12364,22 @@ var classicHandoffCommand = async (args) => {
     else if (fullFlag === "--full") handoffMode = "full";
     else
       throw new HandoffFailure(
-        red3("Usage: comet-handoff.mjs <change-name> design --write [--full]")
+        red5("Usage: comet-handoff.mjs <change-name> design --write [--full]")
       );
     const yaml = `${changeDir}/.comet.yaml`;
-    if (!await exists5(changeDir)) {
-      throw new HandoffFailure(red3(`ERROR: change directory not found: ${changeDir}`));
+    if (!await exists7(changeDir)) {
+      throw new HandoffFailure(red5(`ERROR: change directory not found: ${changeDir}`));
     }
-    if (!await exists5(yaml)) {
-      throw new HandoffFailure(red3(`ERROR: .comet.yaml not found at ${yaml}`));
+    if (!await exists7(yaml)) {
+      throw new HandoffFailure(red5(`ERROR: .comet.yaml not found at ${yaml}`));
     }
     if (await readField2(changeDir, "phase") !== "design") {
-      throw new HandoffFailure(red3("ERROR: design handoff requires phase: design"));
+      throw new HandoffFailure(red5("ERROR: design handoff requires phase: design"));
     }
     for (const required2 of ["proposal.md", "design.md", "tasks.md"]) {
       if (!await nonempty2(`${changeDir}/${required2}`)) {
         throw new HandoffFailure(
-          red3(`ERROR: required OpenSpec artifact missing or empty: ${changeDir}/${required2}`)
+          red5(`ERROR: required OpenSpec artifact missing or empty: ${changeDir}/${required2}`)
         );
       }
     }
@@ -11038,7 +12393,7 @@ var classicHandoffCommand = async (args) => {
     } else if (contextCompression2 === "beta") {
       if (handoffMode === "full") {
         output.stderr.push(
-          yellow3("[HANDOFF] --full is ignored in beta mode; spec files are projected verbatim")
+          yellow4("[HANDOFF] --full is ignored in beta mode; spec files are projected verbatim")
         );
       }
       handoffMode = "beta";
@@ -11047,8 +12402,8 @@ var classicHandoffCommand = async (args) => {
     } else {
       throw new HandoffFailure(
         [
-          red3(`ERROR: invalid context_compression: ${contextCompression2}`),
-          red3("Valid values: off, beta")
+          red5(`ERROR: invalid context_compression: ${contextCompression2}`),
+          red5("Valid values: off, beta")
         ].join("\n")
       );
     }
@@ -11056,13 +12411,13 @@ var classicHandoffCommand = async (args) => {
     const actionId = `classic-handoff:${contextHash}`;
     const initialProjection = await readClassicState(changeDir);
     if (!initialProjection.classic) {
-      throw new HandoffFailure(red3("ERROR: design handoff requires Classic state"));
+      throw new HandoffFailure(red5("ERROR: design handoff requires Classic state"));
     }
     const initialPending = initialProjection.run ? await readPendingAction(changeDir, initialProjection.run.pendingRef) : null;
     const recovering = initialPending?.id === actionId && initialPending.type === "handoff" && initialPending.ref === contextHash;
     if (initialProjection.classic.handoffHash && initialProjection.classic.handoffHash !== contextHash && !recovering) {
       throw new HandoffFailure(
-        red3(
+        red5(
           `ERROR: stale handoff detected: source hash ${contextHash} does not match completed hash ${initialProjection.classic.handoffHash}`
         )
       );
@@ -11071,12 +12426,12 @@ var classicHandoffCommand = async (args) => {
     const pendingAction = await readPendingAction(changeDir, runtime.run.pendingRef);
     const resumesPending = pendingAction?.id === actionId && pendingAction.type === "handoff" && pendingAction.ref === contextHash;
     if (runtime.run.pending && runtime.run.pending !== actionId) {
-      throw new HandoffFailure(red3(`ERROR: another action is pending: ${runtime.run.pending}`));
+      throw new HandoffFailure(red5(`ERROR: another action is pending: ${runtime.run.pending}`));
     }
     if (runtime.classic.handoffHash === contextHash && runtime.classic.handoffContext === contextJson && !runtime.run.pending && !pendingAction && await completedHandoffIsCurrent(changeDir, runtime.run, contextHash, contextJson, contextMd)) {
-      output.stderr.push(green3(`[HANDOFF] wrote ${contextJson}`));
-      output.stderr.push(green3(`[HANDOFF] wrote ${contextMd}`));
-      output.stderr.push(green3(`[HANDOFF] handoff_hash=${contextHash}`));
+      output.stderr.push(green5(`[HANDOFF] wrote ${contextJson}`));
+      output.stderr.push(green5(`[HANDOFF] wrote ${contextMd}`));
+      output.stderr.push(green5(`[HANDOFF] handoff_hash=${contextHash}`));
       return output.toResult(0);
     }
     const action = {
@@ -11096,7 +12451,7 @@ var classicHandoffCommand = async (args) => {
       run: pendingRun,
       unknownKeys: (await readClassicState(changeDir)).unknownKeys
     });
-    await fs14.mkdir(handoffDir, { recursive: true });
+    await fs20.mkdir(handoffDir, { recursive: true });
     if (handoffMode === "beta") {
       await writeSpecMarkdownContext(changeDir, change, contextHash, contextMd);
       await writeSpecJsonContext(changeDir, change, contextHash, contextJson);
@@ -11104,7 +12459,7 @@ var classicHandoffCommand = async (args) => {
       await writeMarkdownContext(changeDir, change, handoffMode, contextHash, contextMd);
       await writeJsonContext(changeDir, change, handoffMode, contextHash, contextJson);
     }
-    const context = await fs14.readFile(contextMd, "utf8");
+    const context = await fs20.readFile(contextMd, "utf8");
     await writeContext(changeDir, pendingRun.contextRef, context);
     const artifacts = {
       ...await readArtifacts(changeDir, pendingRun.artifactsRef),
@@ -11145,11 +12500,11 @@ var classicHandoffCommand = async (args) => {
       unknownKeys: (await readClassicState(changeDir)).unknownKeys
     });
     await clearPendingAction(changeDir, completedRun.pendingRef);
-    output.stderr.push(green3(`[SET] handoff_context=${contextJson}`));
-    output.stderr.push(green3(`[SET] handoff_hash=${contextHash}`));
-    output.stderr.push(green3(`[HANDOFF] wrote ${contextJson}`));
-    output.stderr.push(green3(`[HANDOFF] wrote ${contextMd}`));
-    output.stderr.push(green3(`[HANDOFF] handoff_hash=${contextHash}`));
+    output.stderr.push(green5(`[SET] handoff_context=${contextJson}`));
+    output.stderr.push(green5(`[SET] handoff_hash=${contextHash}`));
+    output.stderr.push(green5(`[HANDOFF] wrote ${contextJson}`));
+    output.stderr.push(green5(`[HANDOFF] wrote ${contextMd}`));
+    output.stderr.push(green5(`[HANDOFF] handoff_hash=${contextHash}`));
     return output.toResult(0);
   } catch (error) {
     if (error instanceof HandoffFailure) {
@@ -11161,8 +12516,8 @@ var classicHandoffCommand = async (args) => {
 };
 
 // domains/comet-classic/classic-hook-guard.ts
-import { existsSync as existsSync2, promises as fs15, readFileSync as readFileSync3 } from "fs";
-import path16 from "path";
+import { existsSync as existsSync2, promises as fs21, readFileSync as readFileSync3 } from "fs";
+import path22 from "path";
 function result(exitCode, message) {
   return { exitCode, stderr: message + "\n" };
 }
@@ -11187,52 +12542,52 @@ function normalized(value) {
 function parseProjectRoot(args) {
   const index = args.indexOf("--project-root");
   const value = index >= 0 ? args[index + 1] : void 0;
-  return path16.resolve(value && !value.startsWith("--") ? value : process.cwd());
+  return path22.resolve(value && !value.startsWith("--") ? value : process.cwd());
 }
 function relativeToProjectRoot(target, projectRoot) {
-  const relative = normalized(path16.relative(projectRoot, target));
+  const relative = normalized(path22.relative(projectRoot, target));
   if (relative === "") return "";
-  if (relative.startsWith("../") || relative === ".." || path16.isAbsolute(relative)) return null;
+  if (relative.startsWith("../") || relative === ".." || path22.isAbsolute(relative)) return null;
   return relative;
 }
 async function physicalPathForPossiblyMissingTarget(target) {
-  const resolved = path16.resolve(target);
-  const root = path16.parse(resolved).root;
+  const resolved = path22.resolve(target);
+  const root = path22.parse(resolved).root;
   const missingSegments = [];
   let cursor = resolved;
   while (cursor && cursor !== root) {
     try {
-      const physicalBase = await fs15.realpath(cursor);
-      return path16.join(physicalBase, ...missingSegments.reverse());
+      const physicalBase = await fs21.realpath(cursor);
+      return path22.join(physicalBase, ...missingSegments.reverse());
     } catch (error) {
       const code = error.code;
       if (code !== "ENOENT" && code !== "ENOTDIR") throw error;
-      missingSegments.push(path16.basename(cursor));
-      cursor = path16.dirname(cursor);
+      missingSegments.push(path22.basename(cursor));
+      cursor = path22.dirname(cursor);
     }
   }
   try {
-    const physicalRoot = await fs15.realpath(root);
-    return path16.join(physicalRoot, ...missingSegments.reverse());
+    const physicalRoot = await fs21.realpath(root);
+    return path22.join(physicalRoot, ...missingSegments.reverse());
   } catch {
     return null;
   }
 }
 async function projectRelative(target, projectRoot) {
-  const rawCandidate = path16.isAbsolute(target) ? target : path16.resolve(process.cwd(), target);
+  const rawCandidate = path22.isAbsolute(target) ? target : path22.resolve(process.cwd(), target);
   let candidate = normalized(rawCandidate);
   const rootRelative = relativeToProjectRoot(rawCandidate, projectRoot);
   if (rootRelative !== null) return rootRelative;
   try {
     const physicalCandidate = await physicalPathForPossiblyMissingTarget(rawCandidate);
-    const physicalRoot = await fs15.realpath(projectRoot);
+    const physicalRoot = await fs21.realpath(projectRoot);
     if (physicalCandidate) {
       const physicalRootRelative = relativeToProjectRoot(physicalCandidate, physicalRoot);
       if (physicalRootRelative !== null) return physicalRootRelative;
       candidate = normalized(physicalCandidate);
     }
   } catch {
-    if (!path16.isAbsolute(target)) return normalized(target).replace(/^\.\//u, "");
+    if (!path22.isAbsolute(target)) return normalized(target).replace(/^\.\//u, "");
   }
   return candidate.replace(/^\.\//u, "");
 }
@@ -11257,15 +12612,15 @@ async function loadGoverningChange(changeDir) {
   }
 }
 async function activeChanges(projectRoot) {
-  const changesDir = path16.join(projectRoot, "openspec", "changes");
+  const changesDir = path22.join(projectRoot, "openspec", "changes");
   const governingChanges = [];
   if (!existsSync2(changesDir)) return governingChanges;
-  for (const entry2 of (await fs15.readdir(changesDir, { withFileTypes: true })).sort(
+  for (const entry2 of (await fs21.readdir(changesDir, { withFileTypes: true })).sort(
     (left, right) => left.name.localeCompare(right.name)
   )) {
     if (!entry2.isDirectory() || entry2.name === "archive") continue;
-    const changeDir = path16.join(changesDir, entry2.name);
-    if (!existsSync2(path16.join(changeDir, ".comet.yaml"))) continue;
+    const changeDir = path22.join(changesDir, entry2.name);
+    if (!existsSync2(path22.join(changeDir, ".comet.yaml"))) continue;
     const governing = await loadGoverningChange(changeDir);
     if (!governing || governing.archived) continue;
     governingChanges.push(governing);
@@ -11285,7 +12640,7 @@ function allowsSuperpowersArtifacts(governing) {
   return governing.phase === "design" || governing.phase === "build" || governing.phase === "verify";
 }
 function governingChangeName(governing) {
-  return governing.changeDir ? path16.basename(governing.changeDir) : null;
+  return governing.changeDir ? path22.basename(governing.changeDir) : null;
 }
 var SUPERPOWERS_ARTIFACT_SUFFIXES = /* @__PURE__ */ new Set([
   "design",
@@ -11342,8 +12697,8 @@ async function governingChange(relativePath2, projectRoot) {
     const rest = relativePath2.slice(prefix.length);
     const [name] = rest.split("/");
     if (name && name !== "archive") {
-      const changeDir = path16.join(projectRoot, "openspec", "changes", name);
-      const stateFile2 = path16.join(changeDir, ".comet.yaml");
+      const changeDir = path22.join(projectRoot, "openspec", "changes", name);
+      const stateFile2 = path22.join(changeDir, ".comet.yaml");
       if (existsSync2(stateFile2)) {
         const governing = await loadGoverningChange(changeDir);
         if (governing) return governing;
@@ -11880,17 +13235,17 @@ var classicIntentCommand = async (args, _options) => {
 
 // domains/comet-classic/classic-state-command.ts
 var import_yaml6 = __toESM(require_dist(), 1);
-import { spawnSync as spawnSync3 } from "child_process";
+import { spawnSync as spawnSync5 } from "child_process";
 import { randomUUID as randomUUID6 } from "crypto";
-import { existsSync as existsSync3, promises as fs16 } from "fs";
-import path17 from "path";
+import { existsSync as existsSync3, promises as fs22 } from "fs";
+import path23 from "path";
 init_state();
-var GREEN5 = "\x1B[32m";
-var RED5 = "\x1B[31m";
-var YELLOW5 = "\x1B[33m";
-var RESET5 = "\x1B[0m";
+var GREEN7 = "\x1B[32m";
+var RED7 = "\x1B[31m";
+var YELLOW6 = "\x1B[33m";
+var RESET7 = "\x1B[0m";
 var PROFILES = ["full", "hotfix", "tweak"];
-var PHASES3 = ["open", "design", "build", "verify", "archive"];
+var PHASES4 = ["open", "design", "build", "verify", "archive"];
 var ARTIFACT_LANGUAGES2 = ["en", "zh-CN"];
 var EVENTS = CLASSIC_TRANSITION_EVENTS;
 var MACHINE_OWNED_FIELDS = /* @__PURE__ */ new Set([
@@ -11903,7 +13258,7 @@ var SETTABLE_FIELDS = new Set(
 );
 var FIELD_ENUMS = {
   workflow: PROFILES,
-  phase: PHASES3,
+  phase: PHASES4,
   context_compression: ["off", "beta"],
   build_mode: ["subagent-driven-development", "executing-plans", "direct"],
   build_pause: ["null", "plan-ready"],
@@ -11913,6 +13268,7 @@ var FIELD_ENUMS = {
   isolation: ["branch", "worktree"],
   verify_mode: ["light", "full"],
   auto_transition: ["true", "false"],
+  graph_context_enabled: ["true", "false"],
   verify_result: ["pending", "pass", "fail"],
   branch_status: ["pending", "handled"],
   archived: ["true", "false"],
@@ -11920,12 +13276,20 @@ var FIELD_ENUMS = {
   classic_profile: PROFILES,
   classic_migration: ["1"]
 };
-var PATH_FIELDS = /* @__PURE__ */ new Set(["design_doc", "plan", "verification_report", "handoff_context"]);
+var PATH_FIELDS = /* @__PURE__ */ new Set([
+  "graph_context",
+  "design_doc",
+  "plan",
+  "verification_report",
+  "handoff_context"
+]);
 var CLASSIC_FIELD_WIRE_NAMES2 = {
   archived: "archived",
   branchStatus: "branch_status",
   classicProfile: "classic_profile",
   designDoc: "design_doc",
+  graphContext: "graph_context",
+  graphContextEnabled: "graph_context_enabled",
   language: "language",
   phase: "phase",
   verificationReport: "verification_report",
@@ -11951,25 +13315,25 @@ var CommandOutput = class {
     };
   }
 };
-function green4(message) {
-  return `${GREEN5}${message}${RESET5}`;
+function green6(message) {
+  return `${GREEN7}${message}${RESET7}`;
 }
-function red4(message) {
-  return `${RED5}${message}${RESET5}`;
+function red6(message) {
+  return `${RED7}${message}${RESET7}`;
 }
-function yellow4(message) {
-  return `${YELLOW5}${message}${RESET5}`;
+function yellow5(message) {
+  return `${YELLOW6}${message}${RESET7}`;
 }
-function fail2(message) {
+function fail3(message) {
   throw new CommandFailure(message);
 }
-function validateChangeName4(name) {
+function validateChangeName5(name) {
   const error = openSpecChangeNameError(name);
-  if (error) fail2(`ERROR: ${error}`);
+  if (error) fail3(`ERROR: ${error}`);
 }
 function validateEnum(value, values) {
   if (!values.includes(value)) {
-    fail2(`ERROR: Invalid value: '${value}'
+    fail3(`ERROR: Invalid value: '${value}'
 Valid values: ${values.join(" ")}`);
   }
 }
@@ -11977,21 +13341,21 @@ function validateLanguage(value, source) {
   if (ARTIFACT_LANGUAGES2.includes(value)) {
     return value;
   }
-  fail2(`ERROR: Invalid language from ${source}: '${value}'
+  fail3(`ERROR: Invalid language from ${source}: '${value}'
 Valid values: en, zh-CN`);
 }
 function validateRelativePath(value, field2) {
   if (!value || value === "null") return;
   if (/^(?:[A-Za-z]:|[\\/]|~)/u.test(value)) {
-    fail2(`ERROR: ${field2} must be a relative path within the repo: '${value}'`);
+    fail3(`ERROR: ${field2} must be a relative path within the repo: '${value}'`);
   }
   if (value.split(/[\\/]/u).includes("..")) {
-    fail2(`ERROR: ${field2} cannot contain '..' (path traversal not allowed): '${value}'`);
+    fail3(`ERROR: ${field2} cannot contain '..' (path traversal not allowed): '${value}'`);
   }
 }
-async function exists6(file) {
+async function exists8(file) {
   try {
-    await fs16.access(file);
+    await fs22.access(file);
     return true;
   } catch (error) {
     if (error.code === "ENOENT") return false;
@@ -12000,7 +13364,7 @@ async function exists6(file) {
 }
 async function nonempty3(file) {
   try {
-    return (await fs16.stat(file)).size > 0;
+    return (await fs22.stat(file)).size > 0;
   } catch (error) {
     if (error.code === "ENOENT") return false;
     throw error;
@@ -12012,27 +13376,27 @@ async function changeDirectory(name) {
 async function readDocument2(file) {
   let source;
   try {
-    source = await fs16.readFile(file, "utf8");
+    source = await fs22.readFile(file, "utf8");
   } catch (error) {
     if (error.code === "ENOENT") {
-      fail2(
-        `ERROR: .comet.yaml not found at ${path17.relative(process.cwd(), file).replaceAll("\\", "/")}`
+      fail3(
+        `ERROR: .comet.yaml not found at ${path23.relative(process.cwd(), file).replaceAll("\\", "/")}`
       );
     }
     throw error;
   }
   const document = (0, import_yaml6.parseDocument)(source, { uniqueKeys: false });
-  if (document.errors.length > 0) fail2(`ERROR: Invalid .comet.yaml: ${document.errors[0].message}`);
+  if (document.errors.length > 0) fail3(`ERROR: Invalid .comet.yaml: ${document.errors[0].message}`);
   return document;
 }
 async function atomicWrite2(file, content) {
-  await fs16.mkdir(path17.dirname(file), { recursive: true });
+  await fs22.mkdir(path23.dirname(file), { recursive: true });
   const temporary = `${file}.${randomUUID6()}.tmp`;
   try {
-    await fs16.writeFile(temporary, content, "utf8");
-    await fs16.rename(temporary, file);
+    await fs22.writeFile(temporary, content, "utf8");
+    await fs22.rename(temporary, file);
   } catch (error) {
-    await fs16.rm(temporary, { force: true });
+    await fs22.rm(temporary, { force: true });
     throw error;
   }
 }
@@ -12070,7 +13434,7 @@ function sparseClassicState(record) {
   return {
     workflow,
     language: enumRecordValue(record, "language", ARTIFACT_LANGUAGES2, null),
-    phase: enumRecordValue(record, "phase", PHASES3, "open"),
+    phase: enumRecordValue(record, "phase", PHASES4, "open"),
     contextCompression: enumRecordValue(
       record,
       "context_compression",
@@ -12115,12 +13479,14 @@ function sparseClassicState(record) {
     handoffContext: nullableRecordString(record, "handoff_context"),
     handoffHash: nullableRecordString(record, "handoff_hash"),
     classicProfile: enumRecordValue(record, "classic_profile", PROFILES, workflow),
-    classicMigration: typeof record.classic_migration === "number" ? record.classic_migration : null
+    classicMigration: typeof record.classic_migration === "number" ? record.classic_migration : null,
+    ...Object.prototype.hasOwnProperty.call(record, "graph_context_enabled") ? { graphContextEnabled: nullableRecordBoolean(record, "graph_context_enabled") } : {},
+    ...Object.prototype.hasOwnProperty.call(record, "graph_context") ? { graphContext: nullableRecordString(record, "graph_context") } : {}
   };
 }
 async function projectConfigValue2(field2) {
-  const file = path17.resolve(".comet", "config.yaml");
-  if (!await exists6(file)) return null;
+  const file = path23.resolve(".comet", "config.yaml");
+  if (!await exists8(file)) return null;
   const document = await readDocument2(file);
   const value = document.get(field2);
   return value === null || value === void 0 ? null : scalar(value);
@@ -12135,7 +13501,7 @@ async function projectLanguageDefault() {
 async function contextCompression() {
   const value = process.env.COMET_CONTEXT_COMPRESSION ?? await projectConfigValue2("context_compression") ?? "off";
   if (!["off", "beta"].includes(value)) {
-    fail2(`ERROR: Invalid context_compression: '${value}'
+    fail3(`ERROR: Invalid context_compression: '${value}'
 Valid values: off, beta`);
   }
   return value;
@@ -12143,7 +13509,7 @@ Valid values: off, beta`);
 async function autoTransition() {
   const value = process.env.COMET_AUTO_TRANSITION ?? await projectConfigValue2("auto_transition") ?? "true";
   if (!["true", "false"].includes(value)) {
-    fail2(`ERROR: Invalid auto_transition: '${value}'
+    fail3(`ERROR: Invalid auto_transition: '${value}'
 Valid values: true, false`);
   }
   return value;
@@ -12151,20 +13517,20 @@ Valid values: true, false`);
 async function reviewModeDefault() {
   const value = process.env.COMET_REVIEW_MODE ?? await projectConfigValue2("review_mode") ?? "standard";
   if (!["null", "off", "standard", "thorough"].includes(value)) {
-    fail2(`ERROR: Invalid review_mode: '${value}'
+    fail3(`ERROR: Invalid review_mode: '${value}'
 Valid values: off, standard, thorough`);
   }
   return value === "null" ? null : value;
 }
 function gitOutput(args) {
-  const result3 = spawnSync3("git", args, { encoding: "utf8" });
+  const result3 = spawnSync5("git", args, { encoding: "utf8" });
   return result3.status === 0 ? result3.stdout.trim() : null;
 }
 async function stateFile(name) {
   const change = await changeDirectory(name);
   return {
     ...change,
-    file: path17.join(change.directory, ".comet.yaml")
+    file: path23.join(change.directory, ".comet.yaml")
   };
 }
 async function readField3(name, field2) {
@@ -12184,7 +13550,7 @@ async function readField3(name, field2) {
 function parsedValue(field2, value) {
   const document = (0, import_yaml6.parseDocument)(`${field2}: ${value}
 `);
-  if (document.errors.length > 0) fail2(`ERROR: Invalid value: '${value}'`);
+  if (document.errors.length > 0) fail3(`ERROR: Invalid value: '${value}'`);
   return document.get(field2);
 }
 function validateSetValue(field2, value) {
@@ -12196,21 +13562,21 @@ function validateSetValue(field2, value) {
   if (enumValues) validateEnum(value, enumValues);
   if (PATH_FIELDS.has(field2)) validateRelativePath(value, field2);
   if ((field2 === "skill_hash" || field2 === "handoff_hash") && !/^[a-f0-9]{64}$/u.test(value)) {
-    fail2(`ERROR: ${field2} must be a sha256 hex digest`);
+    fail3(`ERROR: ${field2} must be a sha256 hex digest`);
   }
   if (field2 === "iteration" && !/^[0-9]+$/u.test(value)) {
-    fail2("ERROR: iteration must be a non-negative integer");
+    fail3("ERROR: iteration must be a non-negative integer");
   }
 }
 async function setField2(output, name, field2, value, options = {}) {
   if (MACHINE_OWNED_FIELDS.has(field2) && !options.machineOwned) {
-    fail2(`ERROR: '${field2}' is a machine-owned Run field and cannot be set directly`);
+    fail3(`ERROR: '${field2}' is a machine-owned Run field and cannot be set directly`);
   }
   if (!SETTABLE_FIELDS.has(field2) && !MACHINE_OWNED_FIELDS.has(field2)) {
-    fail2(`ERROR: Unknown field: '${field2}'`);
+    fail3(`ERROR: Unknown field: '${field2}'`);
   }
   if (field2 === "phase" && !options.internal && process.env.COMET_FORCE_PHASE !== "1") {
-    fail2(
+    fail3(
       "ERROR: Setting 'phase' directly is not allowed; it bypasses state machine evidence checks.\n  Use: comet-state.mjs transition <change-name> <event>\n  Repair-only escape hatch: COMET_FORCE_PHASE=1 comet-state.mjs set <change-name> phase <value>"
     );
   }
@@ -12221,7 +13587,7 @@ async function setField2(output, name, field2, value, options = {}) {
   const run = await readRunState(directory);
   const projection = parseClassicStateDocument(document.toJS(), run);
   if (projection.run) {
-    if (!projection.classic) fail2("ERROR: migrated Run is missing its Classic projection");
+    if (!projection.classic) fail3("ERROR: migrated Run is missing its Classic projection");
     const evidence = await collectClassicEvidence(directory, projection);
     const currentStep = resolveClassicStepId(projection.classic, evidence);
     const stepChanged = currentStep !== projection.run.currentStep;
@@ -12256,18 +13622,18 @@ async function setField2(output, name, field2, value, options = {}) {
   }
   if (field2 === "phase" && !options.internal) {
     output.stderr.push(
-      yellow4("WARNING: Setting 'phase' directly bypasses state machine constraints."),
-      yellow4("  Consider using: comet-state.mjs transition <change-name> <event>")
+      yellow5("WARNING: Setting 'phase' directly bypasses state machine constraints."),
+      yellow5("  Consider using: comet-state.mjs transition <change-name> <event>")
     );
   }
-  output.stderr.push(green4(`[SET] ${field2}=${value}`));
+  output.stderr.push(green6(`[SET] ${field2}=${value}`));
 }
 async function init(output, name, workflow) {
-  validateChangeName4(name);
+  validateChangeName5(name);
   validateEnum(workflow, PROFILES);
   const { file, label, directory } = await stateFile(name);
-  if (await exists6(file)) fail2(`ERROR: .comet.yaml already exists at ${label}/.comet.yaml`);
-  await fs16.mkdir(directory, { recursive: true });
+  if (await exists8(file)) fail3(`ERROR: .comet.yaml already exists at ${label}/.comet.yaml`);
+  await fs22.mkdir(directory, { recursive: true });
   const preset = workflow !== "full";
   const reviewMode = preset ? "off" : await reviewModeDefault();
   const document = new import_yaml6.Document({
@@ -12294,12 +13660,12 @@ async function init(output, name, workflow) {
     archived: false
   });
   await atomicWrite2(file, document.toString());
-  output.stderr.push(green4(`Initialized: ${label}/.comet.yaml (workflow=${workflow})`));
+  output.stderr.push(green6(`Initialized: ${label}/.comet.yaml (workflow=${workflow})`));
 }
 async function requirePhase(name, expected) {
   const actual = await readField3(name, "phase");
   if (actual !== expected) {
-    fail2(`ERROR: Cannot transition '${name}': expected phase ${expected}, got ${actual}`);
+    fail3(`ERROR: Cannot transition '${name}': expected phase ${expected}, got ${actual}`);
   }
 }
 async function requireBuildDecisions(name) {
@@ -12311,32 +13677,32 @@ async function requireBuildDecisions(name) {
   const tddMode = await readField3(name, "tdd_mode");
   const reviewMode = await readField3(name, "review_mode");
   if (!["branch", "worktree"].includes(isolation)) {
-    fail2(
+    fail3(
       `ERROR: Cannot transition '${name}': isolation must be branch or worktree, got '${isolation || "null"}'`
     );
   }
   if (!["subagent-driven-development", "executing-plans", "direct"].includes(buildMode)) {
-    fail2(
+    fail3(
       `ERROR: Cannot transition '${name}': build_mode must be selected before leaving build, got '${buildMode || "null"}'`
     );
   }
   if (buildMode === "direct" && !["hotfix", "tweak"].includes(workflow) && directOverride !== "true") {
-    fail2(
+    fail3(
       `ERROR: Cannot transition '${name}': build_mode=direct is only allowed for hotfix/tweak unless direct_override=true`
     );
   }
   if (buildMode === "subagent-driven-development" && subagentDispatch !== "confirmed") {
-    fail2(
+    fail3(
       `ERROR: Cannot transition '${name}': subagent_dispatch must be confirmed before using build_mode=subagent-driven-development`
     );
   }
   if (workflow === "full" && (!tddMode || tddMode === "null")) {
-    fail2(
+    fail3(
       `ERROR: Cannot transition '${name}': tdd_mode must be selected before leaving build (full workflow)`
     );
   }
   if (workflow === "full" && !["off", "standard", "thorough"].includes(reviewMode)) {
-    fail2(
+    fail3(
       `ERROR: Cannot transition '${name}': review_mode must be selected before leaving build (full workflow); review_mode must be off, standard, or thorough, got '${reviewMode || "null"}'`
     );
   }
@@ -12345,28 +13711,28 @@ async function requireOpenArtifacts(name) {
   const { directory } = await stateFile(name);
   const workflow = await readField3(name, "workflow");
   for (const artifact of ["proposal.md", "tasks.md"]) {
-    if (!await nonempty3(path17.join(directory, artifact))) {
-      fail2(
+    if (!await nonempty3(path23.join(directory, artifact))) {
+      fail3(
         `ERROR: Cannot transition '${name}': ${artifact} must exist and be non-empty before leaving open`
       );
     }
   }
-  if (workflow === "full" && !await nonempty3(path17.join(directory, "design.md"))) {
-    fail2(
+  if (workflow === "full" && !await nonempty3(path23.join(directory, "design.md"))) {
+    fail3(
       `ERROR: Cannot transition '${name}': design.md must exist and be non-empty before leaving open`
     );
   }
 }
 async function requireDesignEvidence(name) {
   const designDoc = await readField3(name, "design_doc");
-  if (!designDoc || designDoc === "null" || !await nonempty3(path17.resolve(designDoc))) {
-    fail2(
+  if (!designDoc || designDoc === "null" || !await nonempty3(path23.resolve(designDoc))) {
+    fail3(
       `ERROR: Cannot transition '${name}': design_doc must point to an existing Design Doc before leaving design`
     );
   }
 }
 async function writeSparseTransitionEffects(directory, effects) {
-  const file = path17.join(directory, ".comet.yaml");
+  const file = path23.join(directory, ".comet.yaml");
   const document = await readDocument2(file);
   for (const effect of effects) {
     const field2 = wireField2(effect.field);
@@ -12380,8 +13746,8 @@ async function applyTransitionEvent(output, name, event) {
   let classic = projection.classic;
   let sparse = false;
   if (!classic) {
-    if (projection.run) fail2("ERROR: Classic state projection is missing");
-    const document = await readDocument2(path17.join(directory, ".comet.yaml"));
+    if (projection.run) fail3("ERROR: Classic state projection is missing");
+    const document = await readDocument2(path23.join(directory, ".comet.yaml"));
     classic = sparseClassicState(document.toJS());
     sparse = true;
   }
@@ -12409,12 +13775,12 @@ async function applyTransitionEvent(output, name, event) {
     effects: result3.effects
   });
   for (const effect of result3.effects) {
-    output.stderr.push(green4(`[SET] ${wireField2(effect.field)}=${wireValue2(effect.to)}`));
+    output.stderr.push(green6(`[SET] ${wireField2(effect.field)}=${wireValue2(effect.to)}`));
   }
-  output.stderr.push(green4(`[TRANSITION] ${event}`));
+  output.stderr.push(green6(`[TRANSITION] ${event}`));
 }
 async function transition(output, name, event) {
-  validateChangeName4(name);
+  validateChangeName5(name);
   validateEnum(event, EVENTS);
   if (event === "open-complete") {
     await requirePhase(name, "open");
@@ -12428,13 +13794,13 @@ async function transition(output, name, event) {
   } else if (event === "verify-pass") {
     await requirePhase(name, "verify");
     const report = await readField3(name, "verification_report");
-    if (!report || !await exists6(path17.resolve(report))) {
-      fail2(
+    if (!report || !await exists8(path23.resolve(report))) {
+      fail3(
         `ERROR: Cannot transition '${name}': verification_report must point to an existing report file`
       );
     }
     if (await readField3(name, "branch_status") !== "handled") {
-      fail2(`ERROR: Cannot transition '${name}': branch_status must be handled`);
+      fail3(`ERROR: Cannot transition '${name}': branch_status must be handled`);
     }
   } else if (event === "verify-fail") {
     await requirePhase(name, "verify");
@@ -12442,27 +13808,27 @@ async function transition(output, name, event) {
     await requirePhase(name, "build");
     const workflow = await readField3(name, "workflow");
     if (!["hotfix", "tweak"].includes(workflow)) {
-      fail2(
+      fail3(
         `ERROR: Cannot transition '${name}': preset-escalate only applies to hotfix/tweak, got workflow='${workflow}'`
       );
     }
   } else if (event === "archive-reopen") {
     await requirePhase(name, "archive");
     if (await readField3(name, "archived") === "true") {
-      fail2(`ERROR: Cannot transition '${name}': already archived`);
+      fail3(`ERROR: Cannot transition '${name}': already archived`);
     }
   } else {
     await requirePhase(name, "archive");
     if (await readField3(name, "verify_result") !== "pass") {
-      fail2(`ERROR: Cannot transition '${name}': verify_result must be pass before archiving`);
+      fail3(`ERROR: Cannot transition '${name}': verify_result must be pass before archiving`);
     }
   }
   await applyTransitionEvent(output, name, event);
 }
 async function next(output, name) {
-  validateChangeName4(name);
+  validateChangeName5(name);
   const { file, label } = await stateFile(name);
-  if (!await exists6(file)) fail2(`ERROR: .comet.yaml not found at ${label}/.comet.yaml`);
+  if (!await exists8(file)) fail3(`ERROR: .comet.yaml not found at ${label}/.comet.yaml`);
   const phase = await readField3(name, "phase");
   const workflow = await readField3(name, "workflow");
   const automatic = await readField3(name, "auto_transition");
@@ -12472,7 +13838,7 @@ async function next(output, name) {
   }
   const skill = phase === "open" ? "comet-open" : phase === "design" ? "comet-design" : phase === "verify" ? "comet-verify" : phase === "archive" ? "comet-archive" : phase === "build" ? workflow === "hotfix" ? "comet-hotfix" : workflow === "tweak" ? "comet-tweak" : "comet-build" : null;
   if (!skill) {
-    fail2(`ERROR: Cannot resolve next step for '${name}': unknown phase '${phase || "null"}'`);
+    fail3(`ERROR: Cannot resolve next step for '${name}': unknown phase '${phase || "null"}'`);
   }
   output.stdout.push(`NEXT: ${automatic === "false" ? "manual" : "auto"}`, `SKILL: ${skill}`);
   if (automatic === "false") {
@@ -12481,32 +13847,32 @@ async function next(output, name) {
 }
 async function taskCheckoff(output, taskFile, taskText) {
   validateRelativePath(taskFile, "task file");
-  if (!taskText) fail2("ERROR: Task text cannot be empty");
-  const file = path17.resolve(taskFile);
-  if (!await exists6(file)) fail2(`ERROR: Task file not found: ${taskFile}`);
-  const lines = (await fs16.readFile(file, "utf8")).split(/\r?\n/u);
+  if (!taskText) fail3("ERROR: Task text cannot be empty");
+  const file = path23.resolve(taskFile);
+  if (!await exists8(file)) fail3(`ERROR: Task file not found: ${taskFile}`);
+  const lines = (await fs22.readFile(file, "utf8")).split(/\r?\n/u);
   const matches = lines.filter(
     (line) => [`- [ ] ${taskText}`, `- [x] ${taskText}`, `- [X] ${taskText}`].includes(line)
   );
   const checked = matches.filter((line) => /^- \[[xX]\] /u.test(line));
   if (matches.length !== 1) {
-    fail2(
+    fail3(
       `ERROR: task text must appear exactly once in ${taskFile} (found ${matches.length}): ${taskText}`
     );
   }
-  if (checked.length !== 1) fail2(`ERROR: task is not checked in ${taskFile}: ${taskText}`);
+  if (checked.length !== 1) fail3(`ERROR: task is not checked in ${taskFile}: ${taskText}`);
   output.stdout.push("TASK_CHECKOFF: PASS", `FILE: ${taskFile}`, `TASK: ${taskText}`);
 }
 async function check2(output, name, phase) {
-  validateChangeName4(name);
-  validateEnum(phase, PHASES3);
+  validateChangeName5(name);
+  validateEnum(phase, PHASES4);
   const { file, directory, label } = await stateFile(name);
   output.stdout.push(`=== Entry Check: comet-${phase} ===`);
-  if (!await exists6(file)) fail2(`ERROR: .comet.yaml not found at ${label}/.comet.yaml`);
+  if (!await exists8(file)) fail3(`ERROR: .comet.yaml not found at ${label}/.comet.yaml`);
   let blocked2 = false;
-  const pass2 = (message) => output.stdout.push(`  ${green4("[PASS]")} ${message}`);
+  const pass2 = (message) => output.stdout.push(`  ${green6("[PASS]")} ${message}`);
   const reject = (message) => {
-    output.stdout.push(`  ${red4("[FAIL]")} ${message}`);
+    output.stdout.push(`  ${red6("[FAIL]")} ${message}`);
     blocked2 = true;
   };
   const expectField = async (field2, expected) => {
@@ -12522,21 +13888,21 @@ async function check2(output, name, phase) {
       designDoc ? `design_doc=${designDoc} (expected: empty/null)` : "design_doc is empty/null"
     );
     for (const artifact of ["proposal.md", "design.md", "tasks.md"]) {
-      (await nonempty3(path17.join(directory, artifact)) ? pass2 : reject)(
-        `${artifact} ${await nonempty3(path17.join(directory, artifact)) ? "non-empty" : "missing or empty"}`
+      (await nonempty3(path23.join(directory, artifact)) ? pass2 : reject)(
+        `${artifact} ${await nonempty3(path23.join(directory, artifact)) ? "non-empty" : "missing or empty"}`
       );
     }
   } else if (phase === "build") {
     const workflow = await readField3(name, "workflow");
     const designDoc = await readField3(name, "design_doc");
     if (workflow === "full") {
-      (designDoc && designDoc !== "null" && await exists6(path17.resolve(designDoc)) ? pass2 : reject)(`design_doc=${designDoc} (expected: non-null and file exists)`);
+      (designDoc && designDoc !== "null" && await exists8(path23.resolve(designDoc)) ? pass2 : reject)(`design_doc=${designDoc} (expected: non-null and file exists)`);
     } else {
       pass2(`workflow=${workflow} (design_doc not required)`);
     }
     for (const artifact of ["proposal.md", "tasks.md"]) {
-      (await nonempty3(path17.join(directory, artifact)) ? pass2 : reject)(
-        `${artifact} ${await nonempty3(path17.join(directory, artifact)) ? "non-empty" : "missing or empty"}`
+      (await nonempty3(path23.join(directory, artifact)) ? pass2 : reject)(
+        `${artifact} ${await nonempty3(path23.join(directory, artifact)) ? "non-empty" : "missing or empty"}`
       );
     }
   } else if (phase === "verify") {
@@ -12551,14 +13917,14 @@ async function check2(output, name, phase) {
   }
   output.stdout.push("");
   if (blocked2) {
-    output.stderr.push(red4("BLOCKED — fix failing checks before proceeding"));
+    output.stderr.push(red6("BLOCKED — fix failing checks before proceeding"));
     throw new CommandFailure("", 1);
   }
-  output.stderr.push(green4("ALL CHECKS PASSED — ready to proceed"));
+  output.stderr.push(green6("ALL CHECKS PASSED — ready to proceed"));
 }
 function fieldStatus(field2, value, file) {
   if (!value || value === "null") return `  - ${field2}: PENDING`;
-  if (file && !existsSync3(path17.resolve(file))) {
+  if (file && !existsSync3(path23.resolve(file))) {
     return `  - ${field2}: BROKEN (path ${value} does not exist)`;
   }
   return `  - ${field2}: DONE (${value})`;
@@ -12567,7 +13933,7 @@ async function recoverOpen(output, directory) {
   output.stdout.push("  Artifacts:");
   let complete = 0;
   for (const artifact of ["proposal.md", "design.md", "tasks.md"]) {
-    const done = await nonempty3(path17.join(directory, artifact));
+    const done = await nonempty3(path23.join(directory, artifact));
     if (done) complete += 1;
     output.stdout.push(`  - ${artifact}: ${done ? "DONE" : "PENDING"}`);
   }
@@ -12580,7 +13946,7 @@ async function recoverDesign(output, name, directory) {
   output.stdout.push("  Artifacts:");
   for (const artifact of ["proposal.md", "design.md", "tasks.md"]) {
     output.stdout.push(
-      `  - ${artifact}: ${await nonempty3(path17.join(directory, artifact)) ? "DONE" : "MISSING (unexpected in design phase)"}`
+      `  - ${artifact}: ${await nonempty3(path23.join(directory, artifact)) ? "DONE" : "MISSING (unexpected in design phase)"}`
     );
   }
   const handoff = await readField3(name, "handoff_context");
@@ -12594,11 +13960,11 @@ async function recoverDesign(output, name, directory) {
     fieldStatus("design_doc", design, design),
     ""
   );
-  if (design && design !== "null" && await exists6(path17.resolve(design))) {
+  if (design && design !== "null" && await exists8(path23.resolve(design))) {
     output.stdout.push(
       "Recovery action: Design Doc already created and linked. Run guard to transition to build."
     );
-  } else if (handoff && handoff !== "null" && await exists6(path17.resolve(handoff))) {
+  } else if (handoff && handoff !== "null" && await exists8(path23.resolve(handoff))) {
     output.stdout.push(
       "Recovery action: Handoff generated but Design Doc not yet created. Resume from brainstorming confirmation (Step 1c)."
     );
@@ -12628,8 +13994,8 @@ async function recoverBuild(output, name, directory, workflow) {
     decisions.push(fieldStatus("subagent_dispatch", subagentDispatch));
   }
   output.stdout.push(...decisions, "", "  Plan:", fieldStatus("plan", plan, plan), "");
-  const tasks = path17.join(directory, "tasks.md");
-  if (!await exists6(tasks)) {
+  const tasks = path23.join(directory, "tasks.md");
+  if (!await exists8(tasks)) {
     output.stdout.push(
       "  Tasks: tasks.md MISSING",
       "",
@@ -12637,14 +14003,14 @@ async function recoverBuild(output, name, directory, workflow) {
     );
     return;
   }
-  const lines = (await fs16.readFile(tasks, "utf8")).split(/\r?\n/u);
+  const lines = (await fs22.readFile(tasks, "utf8")).split(/\r?\n/u);
   const total = lines.filter((line) => /^\s*- \[[ xX]\] /u.test(line)).length;
   const done = lines.filter((line) => /^\s*- \[[xX]\] /u.test(line)).length;
   const pending = total - done;
   let planTotal = 0;
   let planDone = 0;
-  if (plan && plan !== "null" && await exists6(path17.resolve(plan))) {
-    const planLines = (await fs16.readFile(path17.resolve(plan), "utf8")).split(/\r?\n/u);
+  if (plan && plan !== "null" && await exists8(path23.resolve(plan))) {
+    const planLines = (await fs22.readFile(path23.resolve(plan), "utf8")).split(/\r?\n/u);
     planTotal = planLines.filter((line) => /^\s*- \[[ xX]\] /u.test(line)).length;
     planDone = planLines.filter((line) => /^\s*- \[[xX]\] /u.test(line)).length;
   }
@@ -12740,9 +14106,9 @@ async function recoverArchive(output, name) {
   );
 }
 async function recover(output, name) {
-  validateChangeName4(name);
+  validateChangeName5(name);
   const { file, directory, label } = await stateFile(name);
-  if (!await exists6(file)) fail2(`ERROR: .comet.yaml not found at ${label}/.comet.yaml`);
+  if (!await exists8(file)) fail3(`ERROR: .comet.yaml not found at ${label}/.comet.yaml`);
   const phase = await readField3(name, "phase");
   const workflow = await readField3(name, "workflow");
   output.stdout.push(
@@ -12763,27 +14129,27 @@ async function recover(output, name) {
   } else if (phase === "archive") {
     await recoverArchive(output, name);
   } else {
-    fail2(`ERROR: Unknown phase: ${phase}`);
+    fail3(`ERROR: Unknown phase: ${phase}`);
   }
   output.stdout.push("", "=== End Recovery Context ===");
 }
 async function scale(output, name) {
-  validateChangeName4(name);
+  validateChangeName5(name);
   const { file, directory, label } = await stateFile(name);
-  if (!await exists6(file)) fail2(`ERROR: .comet.yaml not found at ${label}/.comet.yaml`);
-  const tasksFile = path17.join(directory, "tasks.md");
-  const taskCount = await exists6(tasksFile) ? (await fs16.readFile(tasksFile, "utf8")).split(/\r?\n/u).filter((line) => /^- \[/u.test(line)).length : 0;
-  const specs = path17.join(directory, "specs");
+  if (!await exists8(file)) fail3(`ERROR: .comet.yaml not found at ${label}/.comet.yaml`);
+  const tasksFile = path23.join(directory, "tasks.md");
+  const taskCount = await exists8(tasksFile) ? (await fs22.readFile(tasksFile, "utf8")).split(/\r?\n/u).filter((line) => /^- \[/u.test(line)).length : 0;
+  const specs = path23.join(directory, "specs");
   let deltaSpecs = 0;
-  if (await exists6(specs)) {
-    for (const entry2 of await fs16.readdir(specs)) {
-      if (await exists6(path17.join(specs, entry2, "spec.md"))) deltaSpecs += 1;
+  if (await exists8(specs)) {
+    for (const entry2 of await fs22.readdir(specs)) {
+      if (await exists8(path23.join(specs, entry2, "spec.md"))) deltaSpecs += 1;
     }
   }
   const plan = await readField3(name, "plan");
   let baseRef = "";
-  if (plan && plan !== "null" && await exists6(path17.resolve(plan))) {
-    const match = (await fs16.readFile(path17.resolve(plan), "utf8")).match(/^base-ref:\s*(.+)$/mu);
+  if (plan && plan !== "null" && await exists8(path23.resolve(plan))) {
+    const match = (await fs22.readFile(path23.resolve(plan), "utf8")).match(/^base-ref:\s*(.+)$/mu);
     baseRef = match?.[1].trim() ?? "";
   }
   if (!baseRef) baseRef = await readField3(name, "base_ref");
@@ -12801,11 +14167,11 @@ async function scale(output, name) {
     `  Delta specs: ${deltaSpecs} capabilities (threshold: 1)`,
     `  Changed files: ${changedFiles} (threshold: 8)`,
     `  → Result: ${result3}`,
-    green4(`[SCALE] verify_mode=${result3}`)
+    green6(`[SCALE] verify_mode=${result3}`)
   );
 }
 function required(args, count, usage2) {
-  if (args.length < count) fail2(usage2);
+  if (args.length < count) fail3(usage2);
 }
 var classicStateCommand = async (args) => {
   const output = new CommandOutput();
@@ -12816,11 +14182,11 @@ var classicStateCommand = async (args) => {
       await init(output, rest[0], rest[1]);
     } else if (subcommand === "get") {
       required(rest, 2, "Usage: comet-state.mjs get <change-name> <field>");
-      validateChangeName4(rest[0]);
+      validateChangeName5(rest[0]);
       output.stdout.push(await readField3(rest[0], rest[1]));
     } else if (subcommand === "set") {
       required(rest, 3, "Usage: comet-state.mjs set <change-name> <field> <value>");
-      validateChangeName4(rest[0]);
+      validateChangeName5(rest[0]);
       await setField2(output, rest[0], rest[1], rest[2]);
     } else if (subcommand === "transition") {
       required(rest, 2, "Usage: comet-state.mjs transition <change-name> <event>");
@@ -12839,13 +14205,13 @@ var classicStateCommand = async (args) => {
       required(rest, 1, "Usage: comet-state.mjs next <change-name>");
       await next(output, rest[0]);
     } else {
-      fail2(`Unknown subcommand: ${subcommand ?? ""}`);
+      fail3(`Unknown subcommand: ${subcommand ?? ""}`);
     }
     return output.result();
   } catch (error) {
     if (!(error instanceof CommandFailure)) throw error;
     if (error.message) {
-      for (const line of error.message.split("\n")) output.stderr.push(red4(line));
+      for (const line of error.message.split("\n")) output.stderr.push(red6(line));
     }
     return output.result(error.exitCode);
   }
@@ -12858,6 +14224,8 @@ var CLASSIC_COMMANDS = [
   "guard",
   "handoff",
   "archive",
+  "firmware-verify",
+  "graph-context",
   "hook-guard",
   "intent"
 ];
@@ -12867,6 +14235,8 @@ var DEFAULT_HANDLERS = {
   guard: classicGuardCommand,
   handoff: classicHandoffCommand,
   archive: classicArchiveCommand,
+  "firmware-verify": classicFirmwareVerifyCommand,
+  "graph-context": classicGraphContextCommand,
   "hook-guard": classicHookGuardCommand,
   intent: classicIntentCommand
 };
diff --git a/config/repository-layout.json b/config/repository-layout.json
index 03df168..6e90591 100644
--- a/config/repository-layout.json
+++ b/config/repository-layout.json
@@ -11,6 +11,8 @@
       "state": "domains/comet-classic/classic-state-entry.ts",
       "validate": "domains/comet-classic/classic-validate-entry.ts",
       "guard": "domains/comet-classic/classic-guard-entry.ts",
+      "firmwareVerify": "domains/comet-classic/classic-firmware-verify-entry.ts",
+      "graphContext": "domains/comet-classic/classic-graph-context-entry.ts",
       "handoff": "domains/comet-classic/classic-handoff-entry.ts",
       "archive": "domains/comet-classic/classic-archive-entry.ts",
       "hookGuard": "domains/comet-classic/classic-hook-guard-entry.ts",
@@ -21,6 +23,8 @@
       "state": "assets/skills/comet/scripts/comet-state.mjs",
       "validate": "assets/skills/comet/scripts/comet-yaml-validate.mjs",
       "guard": "assets/skills/comet/scripts/comet-guard.mjs",
+      "firmwareVerify": "assets/skills/comet/scripts/comet-firmware-verify.mjs",
+      "graphContext": "assets/skills/comet/scripts/comet-graph-context.mjs",
       "handoff": "assets/skills/comet/scripts/comet-handoff.mjs",
       "archive": "assets/skills/comet/scripts/comet-archive.mjs",
       "hookGuard": "assets/skills/comet/scripts/comet-hook-guard.mjs",
diff --git a/docs/architecture/ARCHITECTURE.md b/docs/architecture/ARCHITECTURE.md
index ce557ca..6c6c269 100644
--- a/docs/architecture/ARCHITECTURE.md
+++ b/docs/architecture/ARCHITECTURE.md
@@ -195,6 +195,7 @@ tweak 重新定位为「串联 OpenSpec 的轻量预设路径」，delta spec 
 
 ## 相关文档
 
+- [Graph Context 架构说明](GRAPH-CONTEXT-ARCHITECTURE.md) — CodeGraph / Graphify / drift / firmware 增强在精简后项目中的职责分层
 - [上下文压缩](CONTEXT-COMPRESSION.md) — Design → Build 阶段交接的 token 优化机制
 - [自动衔接](AUTO-TRANSITION.md) — 阶段守卫推进后的下一 skill 路由协议
 - 设计与计划文档：`docs/superpowers/specs/` 与 `docs/superpowers/plans/`
diff --git a/docs/architecture/GRAPH-CONTEXT-ARCHITECTURE.md b/docs/architecture/GRAPH-CONTEXT-ARCHITECTURE.md
new file mode 100644
index 0000000..9871797
--- /dev/null
+++ b/docs/architecture/GRAPH-CONTEXT-ARCHITECTURE.md
@@ -0,0 +1,233 @@
+# Graph Context 架构说明
+
+## 目标
+
+当前精简后的 Graph Context 设计目标很明确：
+
+1. 保留 CodeGraph + Graphify + drift + firmware-aware verify 的核心价值
+2. 让 `classic-graph-context` 命令层只负责编排，不堆领域细节
+3. 让 machine-readable 与 human-readable 产物稳定、简单、可测试
+4. 让后续二次开发优先改 integration 层，而不是直接改运行时脚本
+
+## 当前产物
+
+每个 change 的图上下文产物位于：
+
+```text
+openspec/changes/<change-name>/.comet/graph/
+├── graph-context.md
+├── graph-state.json
+└── graph-constraints.yaml
+```
+
+职责分工：
+
+- `graph-context.md`
+  - 给人和 Skill 读
+  - 汇总 CodeGraph freshness、Graphify freshness、候选文件/符号、drift warning、firmware profile、compile database 摘要
+- `graph-state.json`
+  - 给程序读
+  - 提供稳定 JSON 结构，便于脚本、测试、后续自动化消费
+- `graph-constraints.yaml`
+  - 给项目或开发者手工补充约束
+  - 包含 `allowed_paths`、`forbidden_paths`、`high_risk_paths`、`expected_symbols`、`protected_symbols`、`accepted_deviations`
+
+## 当前分层
+
+```text
+domains/comet-classic/classic-graph-context.ts
+  └─ 命令编排层
+     ├─ 参数校验
+     ├─ 读取 change / classic state
+     ├─ 调用 integration helper
+     ├─ 写 graph-state.json / graph-context.md
+     └─ 回写 .comet.yaml 投影
+
+domains/integrations/graph-context.ts
+  └─ 图上下文领域层
+     ├─ graph 路径与约束文件
+     ├─ graph runtime config 读取
+     ├─ git changed files / artifact freshness
+     ├─ CodeGraph / Graphify 输出摘要
+     ├─ drift warning 组装
+     ├─ graph-state payload 组装
+     └─ graph-context markdown 渲染
+
+domains/integrations/firmware-profile.ts
+  └─ 固件增强层
+     ├─ firmware-profile 读取
+     ├─ compile database 检查
+     └─ firmware verify report 执行与生成
+```
+
+## 为什么这样拆
+
+### 1. 命令层只做 orchestration
+
+`classic-graph-context.ts` 是 runtime command。
+
+它应该回答：
+
+- 当前 change 是谁
+- 当前 phase 是什么
+- 现在该调哪些 helper
+- 最后把结果写到哪里
+
+它不应该长期持有下面这些细节：
+
+- YAML 约束解析
+- CodeGraph 文本提取规则
+- Graphify 摘要规则
+- freshness 判断规则
+- drift warning 文案拼装
+- markdown 渲染模板
+
+这些逻辑已经集中到 `domains/integrations/graph-context.ts`。
+
+### 2. graph 规则要集中
+
+后续如果你想：
+
+- 改 CodeGraph 摘要策略
+- 改 Graphify 查询策略
+- 加新的 drift 规则
+- 改 `graph-state.json` schema
+- 调整 `graph-context.md` 展示结构
+
+优先改：
+
+- [graph-context.ts](/home/zsf/.codex/worktrees/c113/Comet_openspec/domains/integrations/graph-context.ts)
+
+而不是先改：
+
+- [classic-graph-context.ts](/home/zsf/.codex/worktrees/c113/Comet_openspec/domains/comet-classic/classic-graph-context.ts)
+
+### 3. 机器消费与人工消费分离
+
+之前 graph 相关输出偏分散，后续维护容易漂。
+
+现在统一为：
+
+- JSON 给程序
+- Markdown 给人
+
+这样有两个好处：
+
+1. 脚本不用解析 Markdown
+2. 人读文档时不用盯 JSON
+
+## 当前关键 helper
+
+核心 helper 主要在：
+
+- [graph-context.ts](/home/zsf/.codex/worktrees/c113/Comet_openspec/domains/integrations/graph-context.ts)
+
+重点函数：
+
+- `readGraphContextRuntimeConfig`
+  - 读取 `graph_context_enabled` 和 `graph_analysis`
+- `readChangedFilesFromGit`
+  - 汇总工作区与暂存区变更文件
+- `snapshotForArtifact`
+  - 计算 CodeGraph / Graphify artifact freshness
+- `collectCodegraphContext`
+  - 运行 CodeGraph 并生成摘要
+- `collectGraphifyContext`
+  - 运行 Graphify 并生成摘要
+- `readGraphConstraintLists`
+  - 读取 `graph-constraints.yaml`
+- `collectProtectedSymbolHits`
+  - 根据变更文件扫描保护符号命中
+- `buildDriftWarnings`
+  - 统一 drift warning 文案
+- `buildGraphStatePayload`
+  - 生成 `graph-state.json`
+- `renderGraphContextMarkdown`
+  - 生成 `graph-context.md`
+
+## firmware 增强如何接入
+
+firmware 相关能力没有塞进 graph 命令文件里，而是通过 integration helper 接入：
+
+- [firmware-profile.ts](/home/zsf/.codex/worktrees/c113/Comet_openspec/domains/integrations/firmware-profile.ts)
+
+当前接入点：
+
+1. Graph Context 刷新时读取 firmware profile
+2. 如果 profile 配置了 compile database，则生成 compile database 摘要
+3. drift 分析时把 `forbidden_paths` / `high_risk_paths` 合并进图约束
+4. `firmware-verify` 命令通过共享 helper 生成 verify report
+
+这意味着：
+
+- graph workflow 仍然是主线
+- firmware 只是增强，不是并行的第二套流程
+
+## 当前测试覆盖
+
+图上下文相关测试分两层：
+
+1. integration 单测
+   - [graph-context.test.ts](/home/zsf/.codex/worktrees/c113/Comet_openspec/test/domains/integrations/graph-context.test.ts)
+   - 覆盖 YAML 解析、pattern 匹配、drift 分析、CodeGraph 摘要提取、Graphify 摘要、freshness、runtime config、state payload、markdown 渲染
+
+2. classic 脚本回归测试
+   - [comet-scripts.test.ts](/home/zsf/.codex/worktrees/c113/Comet_openspec/test/domains/comet-classic/comet-scripts.test.ts)
+   - 覆盖实际脚本执行后 `graph-context.md`、`graph-state.json`、Classic state 投影是否正确
+
+## 二次开发建议
+
+### 想改流程入口
+
+优先看：
+
+- [classic-graph-context.ts](/home/zsf/.codex/worktrees/c113/Comet_openspec/domains/comet-classic/classic-graph-context.ts)
+
+适合修改：
+
+- 新增/调整子命令
+- phase 下何时触发 full verify
+- 写回 classic state 的策略
+
+### 想改 graph 内容质量
+
+优先看：
+
+- [graph-context.ts](/home/zsf/.codex/worktrees/c113/Comet_openspec/domains/integrations/graph-context.ts)
+
+适合修改：
+
+- CodeGraph 摘要提取
+- Graphify 查询与摘要
+- drift warning 规则
+- JSON / Markdown 输出结构
+
+### 想改固件约束
+
+优先看：
+
+- [firmware-profile.ts](/home/zsf/.codex/worktrees/c113/Comet_openspec/domains/integrations/firmware-profile.ts)
+- `assets/skills*/comet/reference/firmware-profile.md`
+- `assets/skills*/comet/reference/firmware-c-checklist.md`
+
+## 当前是否还要继续拆
+
+当前已经接近复杂度/收益平衡点。
+
+继续拆分当然还能做，但收益开始变小：
+
+1. `classic-graph-context.ts` 已经主要是 orchestration
+2. graph 规则已经集中到 integration 层
+3. 再拆容易让文件数更多、跳转成本更高
+
+所以当前更合理的阶段不是继续机械拆，而是：
+
+1. 先稳定当前接口
+2. 后续根据真实二开痛点再增量优化
+3. 优先保证 graph-state schema、markdown 结构、drift 语义稳定
+
+## 一句话总结
+
+当前 Graph Context 架构可以这样理解：
+
+**Classic 命令层负责串流程，Integration 层负责图规则，Firmware 层负责固件增强，最终统一产出一个给人看的 `graph-context.md` 和一个给程序读的 `graph-state.json`。**
diff --git a/domains/comet-classic/classic-cli.ts b/domains/comet-classic/classic-cli.ts
index a546602..1019a88 100644
--- a/domains/comet-classic/classic-cli.ts
+++ b/domains/comet-classic/classic-cli.ts
@@ -1,5 +1,7 @@
 import { pathToFileURL } from 'url';
 import { classicArchiveCommand } from './classic-archive.js';
+import { classicFirmwareVerifyCommand } from './classic-firmware-verify.js';
+import { classicGraphContextCommand } from './classic-graph-context.js';
 import { classicGuardCommand } from './classic-guard.js';
 import { classicHandoffCommand } from './classic-handoff.js';
 import { classicHookGuardCommand } from './classic-hook-guard.js';
@@ -30,6 +32,8 @@ export const CLASSIC_COMMANDS = [
   'guard',
   'handoff',
   'archive',
+  'firmware-verify',
+  'graph-context',
   'hook-guard',
   'intent',
 ] as const;
@@ -42,6 +46,8 @@ const DEFAULT_HANDLERS: ClassicCommandHandlers = {
   guard: classicGuardCommand,
   handoff: classicHandoffCommand,
   archive: classicArchiveCommand,
+  'firmware-verify': classicFirmwareVerifyCommand,
+  'graph-context': classicGraphContextCommand,
   'hook-guard': classicHookGuardCommand,
   intent: classicIntentCommand,
 };
diff --git a/domains/comet-classic/classic-firmware-verify-entry.ts b/domains/comet-classic/classic-firmware-verify-entry.ts
new file mode 100644
index 0000000..966c57a
--- /dev/null
+++ b/domains/comet-classic/classic-firmware-verify-entry.ts
@@ -0,0 +1,14 @@
+import { pathToFileURL } from 'url';
+import { classicFirmwareVerifyCommand } from './classic-firmware-verify.js';
+import { runClassicScript } from './classic-script-entry.js';
+
+export async function main(argv: readonly string[] = process.argv.slice(2)): Promise<number> {
+  return runClassicScript(classicFirmwareVerifyCommand, argv);
+}
+
+const entry = process.argv[1];
+if (entry && import.meta.url === pathToFileURL(entry).href) {
+  void main().then((exitCode) => {
+    process.exitCode = exitCode;
+  });
+}
diff --git a/domains/comet-classic/classic-firmware-verify.ts b/domains/comet-classic/classic-firmware-verify.ts
new file mode 100644
index 0000000..bb10acb
--- /dev/null
+++ b/domains/comet-classic/classic-firmware-verify.ts
@@ -0,0 +1,69 @@
+import { promises as fs } from 'fs';
+import path from 'path';
+import type { ClassicCommandHandler } from './classic-cli.js';
+import { openSpecChangeNameError, resolveClassicChangeDirectory } from './classic-paths.js';
+import { getChangeGraphContextPaths } from '../../domains/integrations/graph-context.js';
+import { runFirmwareVerifyProfile } from '../../domains/integrations/firmware-profile.js';
+
+const GREEN = '\u001b[32m';
+const RED = '\u001b[31m';
+const YELLOW = '\u001b[33m';
+const RESET = '\u001b[0m';
+
+function green(message: string): string {
+  return `${GREEN}${message}${RESET}`;
+}
+
+function red(message: string): string {
+  return `${RED}${message}${RESET}`;
+}
+
+function yellow(message: string): string {
+  return `${YELLOW}${message}${RESET}`;
+}
+
+async function exists(file: string): Promise<boolean> {
+  try {
+    await fs.access(file);
+    return true;
+  } catch (error) {
+    if ((error as NodeJS.ErrnoException).code === 'ENOENT') return false;
+    throw error;
+  }
+}
+
+function repoRelative(file: string): string {
+  return path.relative(process.cwd(), file).replaceAll('\\', '/');
+}
+
+export const classicFirmwareVerifyCommand: ClassicCommandHandler = async (args) => {
+  const changeName = args[0];
+  const nameError = openSpecChangeNameError(changeName);
+  if (nameError) {
+    return { exitCode: 1, stderr: red(`ERROR: ${nameError}`) };
+  }
+
+  const { directory } = await resolveClassicChangeDirectory(changeName);
+  if (!(await exists(path.join(directory, '.comet.yaml')))) {
+    return {
+      exitCode: 1,
+      stderr: red(
+        `ERROR: .comet.yaml not found at ${repoRelative(path.join(directory, '.comet.yaml'))}`,
+      ),
+    };
+  }
+
+  const graphPaths = getChangeGraphContextPaths(directory);
+  await fs.mkdir(graphPaths.graphDir, { recursive: true });
+  const reportPath = path.join(graphPaths.graphDir, 'firmware-verify-report.md');
+  const result = await runFirmwareVerifyProfile(process.cwd(), changeName);
+  await fs.writeFile(reportPath, `${result.report}\n`, 'utf8');
+
+  const statusLine =
+    result.reportStatus === 'fail'
+      ? red(`FIRMWARE_VERIFY: failed (${repoRelative(reportPath)})`)
+      : result.reportStatus === 'skipped'
+        ? yellow(`FIRMWARE_VERIFY: ${result.summary}`)
+        : green(`FIRMWARE_VERIFY: ${repoRelative(reportPath)}`);
+  return { exitCode: result.exitCode, stderr: statusLine };
+};
diff --git a/domains/comet-classic/classic-graph-context-entry.ts b/domains/comet-classic/classic-graph-context-entry.ts
new file mode 100644
index 0000000..bfe8257
--- /dev/null
+++ b/domains/comet-classic/classic-graph-context-entry.ts
@@ -0,0 +1,14 @@
+import { pathToFileURL } from 'url';
+import { classicGraphContextCommand } from './classic-graph-context.js';
+import { runClassicScript } from './classic-script-entry.js';
+
+export async function main(argv: readonly string[] = process.argv.slice(2)): Promise<number> {
+  return runClassicScript(classicGraphContextCommand, argv);
+}
+
+const entry = process.argv[1];
+if (entry && import.meta.url === pathToFileURL(entry).href) {
+  void main().then((exitCode) => {
+    process.exitCode = exitCode;
+  });
+}
diff --git a/domains/comet-classic/classic-graph-context.ts b/domains/comet-classic/classic-graph-context.ts
new file mode 100644
index 0000000..9a9bb1a
--- /dev/null
+++ b/domains/comet-classic/classic-graph-context.ts
@@ -0,0 +1,212 @@
+import { promises as fs } from 'fs';
+import path from 'path';
+import type { ClassicCommandHandler, ClassicCommandResult } from './classic-cli.js';
+import { openSpecChangeNameError, resolveClassicChangeDirectory } from './classic-paths.js';
+import { readClassicState, writeClassicState } from './classic-store.js';
+import {
+  analyzeGraphDrift,
+  buildDriftWarnings,
+  buildGraphStatePayload,
+  collectCodegraphContext,
+  collectProtectedSymbolHits,
+  collectGraphifyContext,
+  ensureGraphConstraintsFile,
+  readGraphConstraintLists,
+  getChangeGraphContextPaths,
+  readChangedFilesFromGit,
+  readGraphContextRuntimeConfig,
+  renderGraphContextMarkdown,
+  snapshotForArtifact,
+  type GraphPhase,
+} from '../../domains/integrations/graph-context.js';
+import { hasCodegraphProjectIndex } from '../../domains/integrations/codegraph.js';
+import {
+  inspectCompileDatabase,
+  readFirmwareProfile,
+} from '../../domains/integrations/firmware-profile.js';
+import { getGraphifyArtifactPath } from '../../domains/integrations/graphify.js';
+
+const GREEN = '\u001b[32m';
+const RED = '\u001b[31m';
+const YELLOW = '\u001b[33m';
+const RESET = '\u001b[0m';
+const PHASES = ['open', 'design', 'build', 'verify', 'archive'] as const;
+
+function green(message: string): string {
+  return `${GREEN}${message}${RESET}`;
+}
+
+function red(message: string): string {
+  return `${RED}${message}${RESET}`;
+}
+
+function yellow(message: string): string {
+  return `${YELLOW}${message}${RESET}`;
+}
+
+function fail(message: string, exitCode = 1): ClassicCommandResult {
+  return { exitCode, stderr: message };
+}
+
+function validateChangeName(name: string | undefined): string | null {
+  return openSpecChangeNameError(name);
+}
+
+function validatePhase(value: string | undefined): value is GraphPhase {
+  return PHASES.includes((value ?? '') as GraphPhase);
+}
+
+function repoRelative(file: string): string {
+  return path.relative(process.cwd(), file).replaceAll('\\', '/');
+}
+
+async function cmdRefresh(args: string[]): Promise<ClassicCommandResult> {
+  const changeName = args[0];
+  const phaseFlag = args[1] === '--phase' ? args[2] : undefined;
+  const nameError = validateChangeName(changeName);
+  if (nameError) return fail(red(`ERROR: ${nameError}`));
+  if (!validatePhase(phaseFlag)) {
+    return fail(
+      red(
+        'Usage: comet-graph-context.mjs refresh <change-name> --phase <open|design|build|verify|archive>',
+      ),
+    );
+  }
+
+  const { directory } = await resolveClassicChangeDirectory(changeName);
+  const projection = await readClassicState(directory);
+  if (!projection.classic) return fail(red('ERROR: change is missing Classic state'));
+
+  const runtimeConfig = await readGraphContextRuntimeConfig(
+    process.cwd(),
+    projection.classic.graphContextEnabled,
+  );
+  projection.classic.graphContextEnabled = runtimeConfig.enabled;
+  if (!runtimeConfig.enabled) {
+    await writeClassicState(directory, projection);
+    return { exitCode: 0, stderr: green('GRAPH_CONTEXT: disabled') };
+  }
+
+  const paths = getChangeGraphContextPaths(directory);
+  await fs.mkdir(paths.graphDir, { recursive: true });
+  const mode = runtimeConfig.mode;
+  const codegraphIndexPath = hasCodegraphProjectIndex(process.cwd())
+    ? path.join(process.cwd(), '.codegraph')
+    : null;
+  const graphifyArtifact = getGraphifyArtifactPath(process.cwd());
+  const firmwareProfile = await readFirmwareProfile(process.cwd());
+  const compileDatabaseStatus =
+    firmwareProfile.status === 'configured'
+      ? await inspectCompileDatabase(process.cwd(), firmwareProfile.profile)
+      : null;
+  const changedFiles = await readChangedFilesFromGit();
+  const codegraphSnapshot = await snapshotForArtifact(
+    codegraphIndexPath,
+    'CodeGraph',
+    changedFiles,
+  );
+  const graphifySnapshot = await snapshotForArtifact(graphifyArtifact, 'Graphify', changedFiles);
+
+  const codegraphContext = collectCodegraphContext(process.cwd(), changeName, phaseFlag, mode);
+  const graphifyContext = collectGraphifyContext(process.cwd(), changeName, phaseFlag, mode);
+
+  await ensureGraphConstraintsFile(paths.graphConstraints);
+  const parsedConstraints = await readGraphConstraintLists(paths.graphConstraints);
+  const drift = analyzeGraphDrift({
+    changedFiles,
+    allowedPaths: parsedConstraints.allowed_paths,
+    forbiddenPaths: [
+      ...parsedConstraints.forbidden_paths,
+      ...(firmwareProfile.status === 'configured' ? firmwareProfile.profile.forbiddenPaths : []),
+    ],
+    highRiskPaths: [
+      ...parsedConstraints.high_risk_paths,
+      ...(firmwareProfile.status === 'configured' ? firmwareProfile.profile.highRiskPaths : []),
+    ],
+    acceptedDeviations: parsedConstraints.accepted_deviations,
+  });
+  const expectedMissing = parsedConstraints.expected_symbols.filter(
+    (symbol) => !codegraphContext.summary.candidateSymbols.includes(symbol),
+  );
+  const protectedHits = await collectProtectedSymbolHits(
+    changedFiles,
+    parsedConstraints.protected_symbols,
+  );
+  const driftWarnings = buildDriftWarnings(drift, expectedMissing, protectedHits);
+  const driftStatus: 'pass' | 'warn' = driftWarnings.length > 0 ? 'warn' : 'pass';
+  if (phaseFlag === 'verify' && (drift.shouldRequireFullVerify || protectedHits.length > 0)) {
+    projection.classic.verifyMode = 'full';
+  }
+
+  const graphState = buildGraphStatePayload({
+    phase: phaseFlag,
+    mode,
+    codegraphSnapshot,
+    codegraphSummary: codegraphContext.summary,
+    graphifySnapshot,
+    graphifySummary: graphifyContext.summary,
+    driftStatus,
+    driftWarnings,
+    changedFiles,
+    shouldRequireFullVerify: drift.shouldRequireFullVerify || protectedHits.length > 0,
+  });
+  await fs.writeFile(paths.graphState, `${JSON.stringify(graphState, null, 2)}\n`, 'utf8');
+
+  const graphContext = renderGraphContextMarkdown({
+    changeName,
+    phase: phaseFlag,
+    mode,
+    codegraphSnapshot,
+    graphifySnapshot,
+    codegraphAnalysis: codegraphContext.analysis,
+    codegraphSummary: codegraphContext.summary,
+    graphifySummary: graphifyContext.summary,
+    driftStatus,
+    driftWarnings,
+    changedFiles,
+    firmwareProfile,
+    compileDatabaseStatus,
+  });
+  await fs.writeFile(paths.graphContext, `${graphContext}\n`, 'utf8');
+
+  projection.classic.graphContextEnabled = true;
+  projection.classic.graphContext = repoRelative(paths.graphContext);
+  await writeClassicState(directory, projection);
+
+  return { exitCode: 0, stderr: green(`GRAPH_CONTEXT: ${repoRelative(paths.graphContext)}`) };
+}
+
+async function cmdConstraints(args: string[]): Promise<ClassicCommandResult> {
+  const changeName = args[0];
+  const nameError = validateChangeName(changeName);
+  if (nameError) return fail(red(`ERROR: ${nameError}`));
+  const { directory } = await resolveClassicChangeDirectory(changeName);
+  const paths = getChangeGraphContextPaths(directory);
+  await fs.mkdir(paths.graphDir, { recursive: true });
+  await ensureGraphConstraintsFile(paths.graphConstraints);
+  return { exitCode: 0, stdout: `${repoRelative(paths.graphConstraints)}\n` };
+}
+
+async function cmdDrift(args: string[]): Promise<ClassicCommandResult> {
+  const changeName = args[0];
+  return cmdRefresh([changeName, '--phase', 'verify']);
+}
+
+export const classicGraphContextCommand: ClassicCommandHandler = async (args) => {
+  const [subcommand, ...rest] = args;
+  switch (subcommand) {
+    case 'refresh':
+      return cmdRefresh(rest);
+    case 'constraints':
+      return cmdConstraints(rest);
+    case 'drift':
+      return cmdDrift(rest);
+    default:
+      return fail(
+        red(
+          'Usage: comet-graph-context.mjs <refresh|constraints|drift> <change-name> [--phase <phase>]',
+        ),
+        64,
+      );
+  }
+};
diff --git a/domains/comet-classic/classic-state-command.ts b/domains/comet-classic/classic-state-command.ts
index db0d95e..5449b39 100644
--- a/domains/comet-classic/classic-state-command.ts
+++ b/domains/comet-classic/classic-state-command.ts
@@ -53,6 +53,7 @@ const FIELD_ENUMS: Record<string, readonly string[]> = {
   isolation: ['branch', 'worktree'],
   verify_mode: ['light', 'full'],
   auto_transition: ['true', 'false'],
+  graph_context_enabled: ['true', 'false'],
   verify_result: ['pending', 'pass', 'fail'],
   branch_status: ['pending', 'handled'],
   archived: ['true', 'false'],
@@ -61,12 +62,20 @@ const FIELD_ENUMS: Record<string, readonly string[]> = {
   classic_migration: ['1'],
 };
 
-const PATH_FIELDS = new Set(['design_doc', 'plan', 'verification_report', 'handoff_context']);
+const PATH_FIELDS = new Set([
+  'graph_context',
+  'design_doc',
+  'plan',
+  'verification_report',
+  'handoff_context',
+]);
 const CLASSIC_FIELD_WIRE_NAMES: Partial<Record<keyof ClassicState, string>> = {
   archived: 'archived',
   branchStatus: 'branch_status',
   classicProfile: 'classic_profile',
   designDoc: 'design_doc',
+  graphContext: 'graph_context',
+  graphContextEnabled: 'graph_context_enabled',
   language: 'language',
   phase: 'phase',
   verificationReport: 'verification_report',
@@ -287,6 +296,12 @@ function sparseClassicState(record: Record<string, unknown>): ClassicState {
     classicProfile: enumRecordValue(record, 'classic_profile', PROFILES, workflow),
     classicMigration:
       typeof record.classic_migration === 'number' ? record.classic_migration : null,
+    ...(Object.prototype.hasOwnProperty.call(record, 'graph_context_enabled')
+      ? { graphContextEnabled: nullableRecordBoolean(record, 'graph_context_enabled') }
+      : {}),
+    ...(Object.prototype.hasOwnProperty.call(record, 'graph_context')
+      ? { graphContext: nullableRecordString(record, 'graph_context') }
+      : {}),
   };
 }
 
diff --git a/domains/comet-classic/classic-state.ts b/domains/comet-classic/classic-state.ts
index 1f6230c..3d43fa3 100644
--- a/domains/comet-classic/classic-state.ts
+++ b/domains/comet-classic/classic-state.ts
@@ -35,6 +35,8 @@ export interface ClassicState {
   verifyMode: (typeof VERIFY_MODES)[number] | null;
   autoTransition: boolean | null;
   baseRef: string | null;
+  graphContextEnabled?: boolean | null;
+  graphContext?: string | null;
   designDoc: string | null;
   plan: string | null;
   verifyResult: (typeof VERIFY_RESULTS)[number];
@@ -72,6 +74,8 @@ export const CLASSIC_WIRE_KEYS = [
   'verify_mode',
   'auto_transition',
   'base_ref',
+  'graph_context_enabled',
+  'graph_context',
   'design_doc',
   'plan',
   'verify_result',
@@ -219,6 +223,10 @@ function classicStateFromDocument(doc: StateDocument): ClassicState | null {
     handoffHash: sha256(doc, 'handoff_hash'),
     classicProfile: enumValue(doc, 'classic_profile', CLASSIC_PROFILES),
     classicMigration: migrationVersion(doc),
+    ...(has(doc, 'graph_context_enabled')
+      ? { graphContextEnabled: booleanValue(doc, 'graph_context_enabled') }
+      : {}),
+    ...(has(doc, 'graph_context') ? { graphContext: relativePath(doc, 'graph_context') } : {}),
   };
 }
 
@@ -308,5 +316,9 @@ export function classicStateToDocument(state: ClassicState): StateDocument {
     handoff_hash: state.handoffHash,
     classic_profile: state.classicProfile,
     classic_migration: state.classicMigration,
+    ...(state.graphContextEnabled !== undefined
+      ? { graph_context_enabled: state.graphContextEnabled }
+      : {}),
+    ...(state.graphContext !== undefined ? { graph_context: state.graphContext } : {}),
   };
 }
diff --git a/domains/comet-classic/classic-validate-command.ts b/domains/comet-classic/classic-validate-command.ts
index d1b507c..2cfddfa 100644
--- a/domains/comet-classic/classic-validate-command.ts
+++ b/domains/comet-classic/classic-validate-command.ts
@@ -34,6 +34,7 @@ const ENUMS: Record<string, readonly string[]> = {
   isolation: ['branch', 'worktree'],
   verify_mode: ['light', 'full'],
   auto_transition: ['true', 'false'],
+  graph_context_enabled: ['true', 'false'],
   verify_result: ['pending', 'pass', 'fail'],
   branch_status: ['pending', 'handled'],
   archived: ['true', 'false'],
@@ -136,6 +137,12 @@ export const classicValidateCommand: ClassicCommandHandler = async (args) => {
       fail(`${field}='${value}' does not exist on disk`);
     }
   }
+  for (const field of ['graph_context'] as const) {
+    const value = text(record[field]);
+    if (value && !(await exists(path.resolve(value)))) {
+      fail(`${field}='${value}' does not exist on disk`);
+    }
+  }
   for (const field of ['handoff_hash'] as const) {
     const value = text(record[field]);
     if (value && !/^[a-f0-9]{64}$/u.test(value)) {
diff --git a/domains/comet-classic/index.ts b/domains/comet-classic/index.ts
index be19839..ac6d5f2 100644
--- a/domains/comet-classic/index.ts
+++ b/domains/comet-classic/index.ts
@@ -2,6 +2,8 @@ export * from './classic-archive.js';
 export * from './classic-evidence.js';
 export * from './classic-diagnostics.js';
 export * from './classic-cli.js';
+export * from './classic-firmware-verify.js';
+export * from './classic-graph-context.js';
 export * from './classic-guard.js';
 export * from './classic-handoff.js';
 export * from './classic-hook-guard.js';
diff --git a/domains/integrations/firmware-profile.ts b/domains/integrations/firmware-profile.ts
new file mode 100644
index 0000000..9c77fb1
--- /dev/null
+++ b/domains/integrations/firmware-profile.ts
@@ -0,0 +1,322 @@
+import { promises as fs } from 'fs';
+import path from 'path';
+import { spawnSync } from 'child_process';
+
+export interface FirmwareProfile {
+  enabled: boolean;
+  language: string | null;
+  buildSystem: string | null;
+  compileDatabase: string | null;
+  buildCommand: string | null;
+  testCommand: string | null;
+  staticAnalysisCommand: string | null;
+  sourceRoots: string[];
+  highRiskPaths: string[];
+  forbiddenPaths: string[];
+}
+
+export type FirmwareProfileStatus =
+  | { status: 'missing'; path: string }
+  | { status: 'invalid'; path: string; errors: string[] }
+  | { status: 'disabled'; path: string; profile: FirmwareProfile }
+  | { status: 'configured'; path: string; profile: FirmwareProfile };
+
+export interface CompileCommandEntry {
+  directory?: string;
+  command?: string;
+  file?: string;
+}
+
+export type CompileDatabaseInspection =
+  | { status: 'not-configured'; path: null }
+  | { status: 'missing'; path: string }
+  | { status: 'invalid'; path: string; message: string }
+  | {
+      status: 'present';
+      path: string;
+      entries: number;
+      sampleFiles: string[];
+      includeRoots: string[];
+      defineFlags: string[];
+    };
+
+export interface FirmwareVerifyResult {
+  exitCode: number;
+  report: string;
+  reportStatus: 'pass' | 'fail' | 'skipped';
+  summary: string;
+}
+
+function isEmptyCommand(command: string | null): boolean {
+  return !command || command === 'null';
+}
+
+function runCommandString(command: string): { status: number; output: string } {
+  const result = spawnSync(command, {
+    shell: true,
+    encoding: 'utf8',
+    timeout: 300_000,
+  });
+  return {
+    status: result.status ?? 1,
+    output: `${result.stdout ?? ''}${result.stderr ?? ''}`.trim(),
+  };
+}
+
+function writeReportHeader(changeName: string, status: string): string {
+  const generatedAt = new Date().toISOString();
+  return [
+    `# Firmware Verify Report: ${changeName}`,
+    '',
+    `- Generated At: ${generatedAt}`,
+    `- Status: ${status}`,
+    '',
+    '## Commands',
+    '',
+  ].join('\n');
+}
+
+function commandSection(label: string, result: { status: number; output: string }): string[] {
+  return ['', `### ${label} Output`, '', '```text', result.output || '(no output)', '```'];
+}
+
+function stripQuotes(value: string): string {
+  const trimmed = value.trim();
+  if (
+    (trimmed.startsWith('"') && trimmed.endsWith('"')) ||
+    (trimmed.startsWith("'") && trimmed.endsWith("'"))
+  ) {
+    return trimmed.slice(1, -1);
+  }
+  return trimmed;
+}
+
+function parseBoolean(value: string | undefined): boolean | null {
+  if (!value) return null;
+  if (value === 'true') return true;
+  if (value === 'false') return false;
+  return null;
+}
+
+function firmwareProfilePath(projectPath: string): string {
+  return path.join(projectPath, '.comet', 'firmware-profile.yaml');
+}
+
+function parseFirmwareProfile(raw: string): FirmwareProfileStatus {
+  const scalar: Record<string, string> = {};
+  const lists: Record<string, string[]> = {
+    source_roots: [],
+    high_risk_paths: [],
+    forbidden_paths: [],
+  };
+  let activeList: string | null = null;
+
+  for (const line of raw.split(/\r?\n/u)) {
+    const withoutComment = line.replace(/\s+#.*$/u, '');
+    if (!withoutComment.trim()) continue;
+
+    const listItem = withoutComment.match(/^\s*-\s*(.+?)\s*$/u);
+    if (listItem && activeList && lists[activeList]) {
+      lists[activeList].push(stripQuotes(listItem[1]));
+      continue;
+    }
+
+    const keyValue = withoutComment.match(/^([A-Za-z0-9_-]+):\s*(.*?)\s*$/u);
+    if (!keyValue) continue;
+
+    const [, key, value] = keyValue;
+    if (Object.prototype.hasOwnProperty.call(lists, key) && !value) {
+      activeList = key;
+      continue;
+    }
+    activeList = null;
+    scalar[key] = stripQuotes(value);
+  }
+
+  const enabled = parseBoolean(scalar.enabled);
+  const errors: string[] = [];
+  if (enabled === null) errors.push('enabled must be true or false');
+
+  const profile: FirmwareProfile = {
+    enabled: enabled ?? false,
+    language: scalar.language || null,
+    buildSystem: scalar.build_system || null,
+    compileDatabase: scalar.compile_database || null,
+    buildCommand: scalar.build_command || null,
+    testCommand: scalar.test_command || null,
+    staticAnalysisCommand: scalar.static_analysis_command || null,
+    sourceRoots: lists.source_roots,
+    highRiskPaths: lists.high_risk_paths,
+    forbiddenPaths: lists.forbidden_paths,
+  };
+
+  if (profile.enabled) {
+    if (!profile.language) errors.push('language is required when enabled=true');
+    if (!profile.buildSystem) errors.push('build_system is required when enabled=true');
+    if (profile.sourceRoots.length === 0) {
+      errors.push('source_roots must contain at least one path when enabled=true');
+    }
+  }
+
+  if (errors.length > 0) {
+    return { status: 'invalid', path: '', errors };
+  }
+
+  return {
+    status: profile.enabled ? 'configured' : 'disabled',
+    path: '',
+    profile,
+  };
+}
+
+export async function readFirmwareProfile(projectPath: string): Promise<FirmwareProfileStatus> {
+  const profilePath = firmwareProfilePath(projectPath);
+  try {
+    const raw = await fs.readFile(profilePath, 'utf-8');
+    const parsed = parseFirmwareProfile(raw);
+    return { ...parsed, path: profilePath } as FirmwareProfileStatus;
+  } catch (error) {
+    if ((error as NodeJS.ErrnoException).code === 'ENOENT') {
+      return { status: 'missing', path: profilePath };
+    }
+    return {
+      status: 'invalid',
+      path: profilePath,
+      errors: [`failed to read firmware profile: ${(error as Error).message}`],
+    };
+  }
+}
+
+export async function inspectCompileDatabase(
+  projectPath: string,
+  profile: FirmwareProfile,
+): Promise<CompileDatabaseInspection> {
+  if (!profile.compileDatabase) return { status: 'not-configured', path: null };
+  const projectRoot = path.resolve(projectPath);
+  const compileDatabasePath = path.resolve(projectRoot, profile.compileDatabase);
+  if (
+    compileDatabasePath !== projectRoot &&
+    !compileDatabasePath.startsWith(`${projectRoot}${path.sep}`)
+  ) {
+    return {
+      status: 'invalid',
+      path: compileDatabasePath,
+      message: 'compile_database must stay inside the project directory',
+    };
+  }
+  try {
+    const raw = await fs.readFile(compileDatabasePath, 'utf-8');
+    const parsed = JSON.parse(raw) as unknown;
+    if (!Array.isArray(parsed)) {
+      return {
+        status: 'invalid',
+        path: compileDatabasePath,
+        message: 'compile database must be a JSON array',
+      };
+    }
+    const sampleFiles: string[] = [];
+    const includeRoots = new Set<string>();
+    const defineFlags = new Set<string>();
+    for (const entry of parsed as CompileCommandEntry[]) {
+      if (entry.file && sampleFiles.length < 5) sampleFiles.push(entry.file.replaceAll('\\', '/'));
+      for (const token of (entry.command ?? '').split(/\s+/u)) {
+        if (token.startsWith('-I') && token.length > 2) includeRoots.add(token.slice(2));
+        if (token.startsWith('-D') && token.length > 2) defineFlags.add(token.slice(2));
+      }
+    }
+    return {
+      status: 'present',
+      path: compileDatabasePath,
+      entries: parsed.length,
+      sampleFiles,
+      includeRoots: [...includeRoots].sort(),
+      defineFlags: [...defineFlags].sort(),
+    };
+  } catch (error) {
+    if ((error as NodeJS.ErrnoException).code === 'ENOENT') {
+      return { status: 'missing', path: compileDatabasePath };
+    }
+    return {
+      status: 'invalid',
+      path: compileDatabasePath,
+      message: (error as Error).message,
+    };
+  }
+}
+
+export async function runFirmwareVerifyProfile(
+  projectPath: string,
+  changeName: string,
+): Promise<FirmwareVerifyResult> {
+  const profileStatus = await readFirmwareProfile(projectPath);
+
+  if (profileStatus.status === 'missing') {
+    return {
+      exitCode: 0,
+      reportStatus: 'skipped',
+      summary: 'skipped (missing firmware profile)',
+      report: `${writeReportHeader(changeName, 'skipped')}\n- firmware profile: skipped (missing)\n`,
+    };
+  }
+
+  if (profileStatus.status === 'invalid') {
+    return {
+      exitCode: 1,
+      reportStatus: 'fail',
+      summary: 'invalid firmware profile',
+      report: [
+        writeReportHeader(changeName, 'fail'),
+        '- firmware profile: invalid',
+        ...profileStatus.errors.map((error) => `- error: ${error}`),
+        '',
+      ].join('\n'),
+    };
+  }
+
+  if (profileStatus.status === 'disabled') {
+    return {
+      exitCode: 0,
+      reportStatus: 'skipped',
+      summary: 'skipped (disabled firmware profile)',
+      report: `${writeReportHeader(changeName, 'skipped')}\n- firmware profile: skipped (disabled)\n`,
+    };
+  }
+
+  const profile = profileStatus.profile;
+  if (
+    isEmptyCommand(profile.buildCommand) &&
+    isEmptyCommand(profile.testCommand) &&
+    isEmptyCommand(profile.staticAnalysisCommand)
+  ) {
+    return {
+      exitCode: 0,
+      reportStatus: 'skipped',
+      summary: 'skipped (no commands configured)',
+      report: `${writeReportHeader(changeName, 'skipped')}\n- firmware verification: skipped (no commands configured)\n`,
+    };
+  }
+
+  const lines = [writeReportHeader(changeName, 'pending')];
+  let failed = false;
+  for (const [label, command] of [
+    ['build_command', profile.buildCommand],
+    ['test_command', profile.testCommand],
+    ['static_analysis_command', profile.staticAnalysisCommand],
+  ] as const) {
+    if (isEmptyCommand(command)) {
+      lines.push(`- ${label}: skipped (not configured)`);
+      continue;
+    }
+    const result = runCommandString(command!);
+    lines.push(`- ${label}: ${result.status === 0 ? 'pass' : 'fail'}`);
+    lines.push(...commandSection(label, result));
+    if (result.status !== 0) failed = true;
+  }
+
+  return {
+    exitCode: failed ? 1 : 0,
+    reportStatus: failed ? 'fail' : 'pass',
+    summary: failed ? 'failed' : 'passed',
+    report: lines.join('\n').replace('- Status: pending', `- Status: ${failed ? 'fail' : 'pass'}`),
+  };
+}
diff --git a/domains/integrations/graph-context.ts b/domains/integrations/graph-context.ts
new file mode 100644
index 0000000..96f799a
--- /dev/null
+++ b/domains/integrations/graph-context.ts
@@ -0,0 +1,737 @@
+import { execFileSync, spawnSync } from 'child_process';
+import { promises as fs } from 'fs';
+import path from 'path';
+import type { CompileDatabaseInspection, FirmwareProfileStatus } from './firmware-profile.js';
+import { hasCodegraphProjectIndex, resolveCodegraphCommand } from './codegraph.js';
+import { hasGraphifyProjectArtifact, resolveGraphifyCommand } from './graphify.js';
+
+export type GraphPhase = 'open' | 'design' | 'build' | 'verify' | 'archive';
+export type GraphAnalysisMode = 'off' | 'light' | 'standard';
+export type SnapshotStatus = 'fresh' | 'stale-but-usable' | 'stale-and-should-refresh' | 'missing';
+
+export interface GraphContextPaths {
+  graphDir: string;
+  graphContext: string;
+  graphState: string;
+  graphConstraints: string;
+}
+
+export interface GraphDriftInput {
+  changedFiles: string[];
+  allowedPaths: string[];
+  forbiddenPaths: string[];
+  highRiskPaths?: string[];
+  acceptedDeviations?: string[];
+}
+
+export interface GraphDriftAnalysis {
+  status: 'pass' | 'warn';
+  forbiddenHits: string[];
+  outOfScopeHits: string[];
+  highRiskHits: string[];
+  acceptedHits: string[];
+  shouldRequireFullVerify: boolean;
+}
+
+export interface GraphSnapshotPayload {
+  freshness: {
+    status: SnapshotStatus;
+    recommendation: string;
+    newerRelevantFileCount: number;
+  };
+}
+
+export interface CodegraphSummary {
+  status: 'ok' | 'skipped';
+  skippedReason: string | null;
+  candidateFiles: string[];
+  candidateSymbols: string[];
+  relevanceHints: string[];
+}
+
+export interface GraphifySummary {
+  status: 'ok' | 'skipped';
+  skippedReason: string | null;
+  notes: string[];
+}
+
+export interface GraphStatePayload {
+  schemaVersion: number;
+  phase: GraphPhase;
+  mode: GraphAnalysisMode;
+  codegraph: GraphSnapshotPayload & CodegraphSummary;
+  graphify: GraphSnapshotPayload & GraphifySummary;
+  drift: {
+    status: 'pass' | 'warn';
+    warnings: string[];
+    changedFiles: string[];
+    shouldRequireFullVerify: boolean;
+  };
+}
+
+export interface CodegraphContextResult {
+  analysis: string;
+  summary: CodegraphSummary;
+}
+
+export interface GraphifyContextResult {
+  output: string;
+  summary: GraphifySummary;
+}
+
+export interface GraphContextRuntimeConfig {
+  enabled: boolean;
+  mode: GraphAnalysisMode;
+}
+
+export interface GraphConstraintLists {
+  allowed_paths: string[];
+  forbidden_paths: string[];
+  high_risk_paths: string[];
+  expected_symbols: string[];
+  protected_symbols: string[];
+  accepted_deviations: string[];
+}
+
+export function getChangeGraphContextPaths(changeDir: string): GraphContextPaths {
+  const graphDir = path.join(changeDir, '.comet', 'graph');
+  return {
+    graphDir,
+    graphContext: path.join(graphDir, 'graph-context.md'),
+    graphState: path.join(graphDir, 'graph-state.json'),
+    graphConstraints: path.join(graphDir, 'graph-constraints.yaml'),
+  };
+}
+
+function stripYamlQuotes(value: string): string {
+  const trimmed = value.trim();
+  if (
+    (trimmed.startsWith('"') && trimmed.endsWith('"')) ||
+    (trimmed.startsWith("'") && trimmed.endsWith("'"))
+  ) {
+    return trimmed.slice(1, -1);
+  }
+  return trimmed;
+}
+
+export function parseYamlListLines(raw: string, field: string): string[] {
+  const values: string[] = [];
+  let inList = false;
+  for (const line of raw.split(/\r?\n/u)) {
+    if (new RegExp(`^\\s*${field}:`).test(line)) {
+      inList = true;
+      continue;
+    }
+    if (/^\s*[A-Za-z0-9_-]+:/u.test(line)) {
+      inList = false;
+    }
+    if (!inList) continue;
+    const item = line.match(/^\s*-\s*(.*?)\s*$/u);
+    if (item?.[1]) values.push(stripYamlQuotes(item[1]));
+  }
+  return values;
+}
+
+export function extractCodegraphSummary(raw: string): CodegraphSummary {
+  const summary: CodegraphSummary = {
+    status: 'ok',
+    skippedReason: null,
+    candidateFiles: [],
+    candidateSymbols: [],
+    relevanceHints: [],
+  };
+  const fileRegex =
+    /(?:[A-Za-z0-9_.@+-]+\/)+[A-Za-z0-9_.@+-]+\.(?:c|h|cc|cpp|hpp|ts|tsx|js|jsx|mjs|sh|md)\b/g;
+  const symbolRegex = /\b[A-Za-z_][A-Za-z0-9_]{2,}\b/g;
+  const stopwords = new Set([
+    'analysis',
+    'and',
+    'archive',
+    'build',
+    'call',
+    'caller',
+    'callees',
+    'callers',
+    'codegraph',
+    'context',
+    'design',
+    'entry',
+    'file',
+    'files',
+    'graph',
+    'high',
+    'impact',
+    'module',
+    'open',
+    'phase',
+    'related',
+    'risk',
+    'summary',
+    'symbol',
+    'symbols',
+    'verify',
+  ]);
+
+  const pushUnique = (target: string[], value: string | null, limit = 12) => {
+    if (!value || target.includes(value) || target.length >= limit) return;
+    target.push(value);
+  };
+
+  const normalizeSymbol = (token: string): string | null => {
+    if (stopwords.has(token.toLowerCase())) return null;
+    if (/^[A-Z0-9_]+$/u.test(token)) return null;
+    return token;
+  };
+
+  for (const line of raw.split(/\r?\n/u)) {
+    for (const match of line.match(fileRegex) ?? []) {
+      pushUnique(summary.candidateFiles, match);
+    }
+    for (const token of line.match(symbolRegex) ?? []) {
+      const normalized = normalizeSymbol(token);
+      pushUnique(summary.candidateSymbols, normalized);
+    }
+    if (/related|impact|boundary|history|constraint/iu.test(line)) {
+      pushUnique(summary.relevanceHints, line.trim(), 20);
+    }
+  }
+
+  return summary;
+}
+
+export function skippedCodegraphSummary(reason: string): CodegraphSummary {
+  return {
+    status: 'skipped',
+    skippedReason: reason,
+    candidateFiles: [],
+    candidateSymbols: [],
+    relevanceHints: [],
+  };
+}
+
+export function summarizeGraphifyResult(
+  mode: GraphAnalysisMode,
+  output: string,
+  skippedReason: string | null,
+): GraphifySummary {
+  if (skippedReason) {
+    return { status: 'skipped', skippedReason, notes: [] };
+  }
+
+  const notes = output
+    .split(/\r?\n/u)
+    .map((line) => line.trim())
+    .filter(Boolean)
+    .slice(0, 12);
+
+  return {
+    status: mode === 'off' ? 'skipped' : 'ok',
+    skippedReason: mode === 'off' ? 'graph_analysis=off' : null,
+    notes,
+  };
+}
+
+function runTool(command: string, args: string[]): { status: number; output: string } {
+  const result = spawnSync(command, args, {
+    encoding: 'utf8',
+    shell: process.platform === 'win32',
+    timeout: 30_000,
+  });
+  return {
+    status: result.status ?? 1,
+    output: `${result.stdout ?? ''}${result.stderr ?? ''}`.trim(),
+  };
+}
+
+export function collectCodegraphContext(
+  projectPath: string,
+  changeName: string,
+  phase: GraphPhase,
+  mode: GraphAnalysisMode,
+): CodegraphContextResult {
+  if (mode === 'off') {
+    return {
+      analysis: 'Reason: graph_analysis=off',
+      summary: skippedCodegraphSummary('graph_analysis=off'),
+    };
+  }
+
+  const codegraphCommand = resolveCodegraphCommand();
+  if (!codegraphCommand || !hasCodegraphProjectIndex(projectPath)) {
+    return {
+      analysis: 'Reason: .codegraph index missing',
+      summary: skippedCodegraphSummary('.codegraph index missing'),
+    };
+  }
+
+  const result = runTool(codegraphCommand, ['structure', changeName, '--phase', phase]);
+  const analysis = result.output || 'CodeGraph returned no output';
+  return {
+    analysis,
+    summary: extractCodegraphSummary(analysis),
+  };
+}
+
+export function collectGraphifyContext(
+  projectPath: string,
+  changeName: string,
+  phase: GraphPhase,
+  mode: GraphAnalysisMode,
+): GraphifyContextResult {
+  if (mode === 'off') {
+    return {
+      output: '',
+      summary: summarizeGraphifyResult(mode, '', 'graph_analysis=off'),
+    };
+  }
+
+  const graphifyCommand = resolveGraphifyCommand();
+  if (!graphifyCommand || !hasGraphifyProjectArtifact(projectPath)) {
+    return {
+      output: '',
+      summary: summarizeGraphifyResult(mode, '', 'graph.json missing'),
+    };
+  }
+
+  const result = runTool(graphifyCommand, ['query', `${changeName} ${phase} graph context`]);
+  const output = result.output || 'graphify query returned no output';
+  return {
+    output,
+    summary: summarizeGraphifyResult(mode, output, null),
+  };
+}
+
+export function buildDriftWarnings(
+  drift: GraphDriftAnalysis,
+  expectedMissing: string[],
+  protectedHits: string[],
+): string[] {
+  return [
+    ...drift.forbiddenHits.map((file) => `forbidden path changed: ${file}`),
+    ...drift.outOfScopeHits.map((file) => `out-of-scope path changed: ${file}`),
+    ...drift.highRiskHits.map((file) => `high-risk path changed: ${file}`),
+    ...expectedMissing.map((symbol) => `expected symbol missing from summary: ${symbol}`),
+    ...protectedHits.map((symbol) => `protected symbol changed: ${symbol}`),
+  ];
+}
+
+export function defaultGraphConstraintsYaml(): string {
+  return [
+    'graph_constraints:',
+    '  allowed_paths: []',
+    '  forbidden_paths: []',
+    '  high_risk_paths: []',
+    '  expected_symbols: []',
+    '  protected_symbols: []',
+    '  accepted_deviations: []',
+    '',
+  ].join('\n');
+}
+
+async function exists(file: string): Promise<boolean> {
+  try {
+    await fs.access(file);
+    return true;
+  } catch (error) {
+    if ((error as NodeJS.ErrnoException).code === 'ENOENT') return false;
+    throw error;
+  }
+}
+
+async function readProjectConfigField(projectPath: string, field: string): Promise<string | null> {
+  const file = path.join(projectPath, '.comet', 'config.yaml');
+  if (!(await exists(file))) return null;
+  for (const line of (await fs.readFile(file, 'utf8')).split(/\r?\n/u)) {
+    const match = line.match(new RegExp(`^${field}:\\s*(.*?)\\s*$`, 'u'));
+    if (!match) continue;
+    const value = match[1].trim().replace(/^['"]|['"]$/gu, '');
+    return value === '' ? null : value;
+  }
+  return null;
+}
+
+export async function resolveGraphContextEnabled(
+  projectPath: string,
+  explicitStateValue: boolean | null | undefined,
+): Promise<boolean> {
+  if (explicitStateValue !== null && explicitStateValue !== undefined) return explicitStateValue;
+  const configured =
+    process.env.COMET_GRAPH_CONTEXT_ENABLED ??
+    (await readProjectConfigField(projectPath, 'graph_context_enabled'));
+  if (configured === null) return true;
+  return configured === 'true';
+}
+
+export async function resolveGraphAnalysisMode(projectPath: string): Promise<GraphAnalysisMode> {
+  const value =
+    process.env.COMET_GRAPH_ANALYSIS ??
+    (await readProjectConfigField(projectPath, 'graph_analysis')) ??
+    'light';
+  if (value === 'off' || value === 'light' || value === 'standard') return value;
+  return 'light';
+}
+
+export async function readGraphContextRuntimeConfig(
+  projectPath: string,
+  explicitStateValue: boolean | null | undefined,
+): Promise<GraphContextRuntimeConfig> {
+  const [enabled, mode] = await Promise.all([
+    resolveGraphContextEnabled(projectPath, explicitStateValue),
+    resolveGraphAnalysisMode(projectPath),
+  ]);
+  return { enabled, mode };
+}
+
+export async function readChangedFilesFromGit(): Promise<string[]> {
+  const outputs: string[] = [];
+  for (const args of [
+    ['diff', '--name-only'],
+    ['diff', '--cached', '--name-only'],
+  ]) {
+    try {
+      outputs.push(
+        execFileSync('git', args, {
+          encoding: 'utf8',
+          stdio: ['ignore', 'pipe', 'ignore'],
+          timeout: 10_000,
+        }),
+      );
+    } catch {
+      // Non-git workspace or no diff available.
+    }
+  }
+  return [
+    ...new Set(
+      outputs.flatMap((raw) =>
+        raw
+          .split(/\r?\n/u)
+          .map((line) => line.trim())
+          .filter(Boolean),
+      ),
+    ),
+  ];
+}
+
+export async function snapshotForArtifact(
+  artifactPath: string | null,
+  label: 'CodeGraph' | 'Graphify',
+  changedFiles?: string[],
+): Promise<GraphSnapshotPayload> {
+  if (!artifactPath || !(await exists(artifactPath))) {
+    return {
+      freshness: {
+        status: 'missing',
+        recommendation: `Initialize or refresh ${label} before trusting graph context.`,
+        newerRelevantFileCount: 0,
+      },
+    };
+  }
+
+  const currentChangedFiles = changedFiles ?? (await readChangedFilesFromGit());
+  const newerRelevantFileCount = currentChangedFiles.length;
+  if (newerRelevantFileCount >= 5) {
+    return {
+      freshness: {
+        status: 'stale-and-should-refresh',
+        recommendation: `Refresh ${label} before trusting graph context.`,
+        newerRelevantFileCount,
+      },
+    };
+  }
+  if (newerRelevantFileCount > 0) {
+    return {
+      freshness: {
+        status: 'stale-but-usable',
+        recommendation: `${label} artifact is usable, but changed files exist since the last graph snapshot.`,
+        newerRelevantFileCount,
+      },
+    };
+  }
+  return {
+    freshness: {
+      status: 'fresh',
+      recommendation: `${label} artifact is aligned with current workspace.`,
+      newerRelevantFileCount: 0,
+    },
+  };
+}
+
+export async function ensureGraphConstraintsFile(file: string): Promise<void> {
+  if (await exists(file)) return;
+  await fs.writeFile(file, defaultGraphConstraintsYaml(), 'utf8');
+}
+
+export async function readGraphConstraintLists(file: string): Promise<GraphConstraintLists> {
+  if (!(await exists(file))) {
+    return {
+      allowed_paths: [],
+      forbidden_paths: [],
+      high_risk_paths: [],
+      expected_symbols: [],
+      protected_symbols: [],
+      accepted_deviations: [],
+    };
+  }
+
+  const raw = await fs.readFile(file, 'utf8');
+  return {
+    allowed_paths: parseYamlListLines(raw, 'allowed_paths'),
+    forbidden_paths: parseYamlListLines(raw, 'forbidden_paths'),
+    high_risk_paths: parseYamlListLines(raw, 'high_risk_paths'),
+    expected_symbols: parseYamlListLines(raw, 'expected_symbols'),
+    protected_symbols: parseYamlListLines(raw, 'protected_symbols'),
+    accepted_deviations: parseYamlListLines(raw, 'accepted_deviations'),
+  };
+}
+
+export async function collectProtectedSymbolHits(
+  changedFiles: string[],
+  protectedSymbols: string[],
+): Promise<string[]> {
+  const hits = new Set<string>();
+  for (const symbol of protectedSymbols) {
+    for (const file of changedFiles) {
+      const absolute = path.resolve(file);
+      if (!(await exists(absolute))) continue;
+      if ((await fs.readFile(absolute, 'utf8')).includes(symbol)) {
+        hits.add(symbol);
+      }
+    }
+  }
+  return [...hits];
+}
+
+function globToRegExp(pattern: string): RegExp {
+  const escaped = pattern
+    .trim()
+    .replace(/[.+^${}()|[\]\\]/gu, '\\$&')
+    .replace(/\*/gu, '.*')
+    .replace(/\?/gu, '.');
+  return new RegExp(`^${escaped}$`, 'u');
+}
+
+export function matchesAnyPattern(filePath: string, patterns: string[]): boolean {
+  return patterns.some((pattern) => pattern && globToRegExp(pattern).test(filePath));
+}
+
+export function analyzeGraphDrift(input: GraphDriftInput): GraphDriftAnalysis {
+  const highRiskPatterns = input.highRiskPaths ?? [];
+  const acceptedPatterns = input.acceptedDeviations ?? [];
+  const acceptedHits = input.changedFiles.filter((file) =>
+    matchesAnyPattern(file, acceptedPatterns),
+  );
+  const rawForbiddenHits = input.changedFiles.filter((file) =>
+    matchesAnyPattern(file, input.forbiddenPaths),
+  );
+  const rawOutOfScopeHits =
+    input.allowedPaths.length === 0
+      ? []
+      : input.changedFiles.filter((file) => !matchesAnyPattern(file, input.allowedPaths));
+  const rawHighRiskHits = input.changedFiles.filter((file) =>
+    matchesAnyPattern(file, highRiskPatterns),
+  );
+  const forbiddenHits = rawForbiddenHits.filter(
+    (file) => !matchesAnyPattern(file, acceptedPatterns),
+  );
+  const outOfScopeHits = rawOutOfScopeHits.filter(
+    (file) => !matchesAnyPattern(file, acceptedPatterns),
+  );
+  const highRiskHits = rawHighRiskHits.filter((file) => !matchesAnyPattern(file, acceptedPatterns));
+  const status =
+    forbiddenHits.length > 0 || outOfScopeHits.length > 0 || highRiskHits.length > 0
+      ? 'warn'
+      : 'pass';
+
+  return {
+    status,
+    forbiddenHits,
+    outOfScopeHits,
+    highRiskHits,
+    acceptedHits,
+    shouldRequireFullVerify: rawHighRiskHits.length > 0,
+  };
+}
+
+export function buildGraphStatePayload(input: {
+  phase: GraphPhase;
+  mode: GraphAnalysisMode;
+  codegraphSnapshot: GraphSnapshotPayload;
+  codegraphSummary: CodegraphSummary;
+  graphifySnapshot: GraphSnapshotPayload;
+  graphifySummary: GraphifySummary;
+  driftStatus: 'pass' | 'warn';
+  driftWarnings: string[];
+  changedFiles: string[];
+  shouldRequireFullVerify: boolean;
+}): GraphStatePayload {
+  return {
+    schemaVersion: 1,
+    phase: input.phase,
+    mode: input.mode,
+    codegraph: {
+      ...input.codegraphSnapshot,
+      ...input.codegraphSummary,
+    },
+    graphify: {
+      ...input.graphifySnapshot,
+      ...input.graphifySummary,
+    },
+    drift: {
+      status: input.driftStatus,
+      warnings: input.driftWarnings,
+      changedFiles: input.changedFiles,
+      shouldRequireFullVerify: input.shouldRequireFullVerify,
+    },
+  };
+}
+
+export function renderGraphContextMarkdown(input: {
+  changeName: string;
+  phase: GraphPhase;
+  mode: GraphAnalysisMode;
+  codegraphSnapshot: GraphSnapshotPayload;
+  graphifySnapshot: GraphSnapshotPayload;
+  codegraphAnalysis: string;
+  codegraphSummary: CodegraphSummary;
+  graphifySummary: GraphifySummary;
+  driftStatus: 'pass' | 'warn';
+  driftWarnings: string[];
+  changedFiles: string[];
+  firmwareProfile: FirmwareProfileStatus;
+  compileDatabaseStatus: CompileDatabaseInspection | null;
+}): string {
+  return [
+    `# Graph Context: ${input.changeName}`,
+    '',
+    '## Graph Guard',
+    '',
+    `- Graph Analysis Mode: ${input.mode}`,
+    '',
+    '### CodeGraph Freshness',
+    `- Status: ${input.codegraphSnapshot.freshness.status}`,
+    `- Recommendation: ${input.codegraphSnapshot.freshness.recommendation}`,
+    `- newer_relevant_files: ${input.codegraphSnapshot.freshness.newerRelevantFileCount}`,
+    '',
+    '### Graphify Freshness',
+    `- Status: ${input.graphifySnapshot.freshness.status}`,
+    `- Recommendation: ${input.graphifySnapshot.freshness.recommendation}`,
+    `- newer_relevant_files: ${input.graphifySnapshot.freshness.newerRelevantFileCount}`,
+    '',
+    '## Phase Graph Checklist',
+    '',
+    ...graphPhaseChecklist(input.phase).map((line) => `- ${line}`),
+    '',
+    '## CodeGraph Analysis',
+    '',
+    input.codegraphAnalysis,
+    '',
+    '## Candidate Focus',
+    '',
+    `- Candidate Files: ${input.codegraphSummary.candidateFiles.join(', ') || 'none'}`,
+    `- Candidate Symbols: ${input.codegraphSummary.candidateSymbols.join(', ') || 'none'}`,
+    ...(input.codegraphSummary.skippedReason
+      ? [`- CodeGraph Skipped Reason: ${input.codegraphSummary.skippedReason}`]
+      : []),
+    '',
+    '## Drift Summary',
+    '',
+    `- Status: ${input.driftStatus}`,
+    `- Changed Files: ${input.changedFiles.join(', ') || 'none'}`,
+    ...(input.driftWarnings.length > 0
+      ? input.driftWarnings.map((warning) => `- Warning: ${warning}`)
+      : ['- Warning: none']),
+    '',
+    ...(input.firmwareProfile.status === 'configured'
+      ? [
+          '## Firmware Profile',
+          '',
+          '- Enabled: true',
+          `- Language: ${input.firmwareProfile.profile.language ?? 'unknown'}`,
+          `- Build System: ${input.firmwareProfile.profile.buildSystem ?? 'unknown'}`,
+          `- Compile Database: ${input.firmwareProfile.profile.compileDatabase ?? 'not configured'}`,
+          `- Compile Database Status: ${
+            input.compileDatabaseStatus?.status === 'present'
+              ? `present (${input.compileDatabaseStatus.entries} entries)`
+              : (input.compileDatabaseStatus?.status ?? 'not-configured')
+          }`,
+          `- Source Roots: ${
+            input.firmwareProfile.profile.sourceRoots.length > 0
+              ? input.firmwareProfile.profile.sourceRoots.join(', ')
+              : 'none'
+          }`,
+          `- High Risk Paths: ${
+            input.firmwareProfile.profile.highRiskPaths.length > 0
+              ? input.firmwareProfile.profile.highRiskPaths.join(', ')
+              : 'none'
+          }`,
+          `- Forbidden Paths: ${
+            input.firmwareProfile.profile.forbiddenPaths.length > 0
+              ? input.firmwareProfile.profile.forbiddenPaths.join(', ')
+              : 'none'
+          }`,
+          '',
+          ...(input.compileDatabaseStatus?.status === 'present'
+            ? [
+                '## Compile Database Summary',
+                '',
+                `- Entries: ${input.compileDatabaseStatus.entries}`,
+                `- Sample Files: ${input.compileDatabaseStatus.sampleFiles.join(', ') || 'none'}`,
+                `- Include Roots: ${input.compileDatabaseStatus.includeRoots.join(', ') || 'none'}`,
+                `- Define Flags: ${input.compileDatabaseStatus.defineFlags.join(', ') || 'none'}`,
+                '',
+              ]
+            : []),
+        ]
+      : []),
+    '## Graphify Notes',
+    '',
+    `- Status: ${input.graphifySummary.status}`,
+    ...(input.graphifySummary.skippedReason
+      ? [`- Reason: ${input.graphifySummary.skippedReason}`]
+      : []),
+    ...(input.graphifySummary.notes.length > 0
+      ? input.graphifySummary.notes.map((note) => `- ${note}`)
+      : ['- No additional Graphify notes']),
+    '',
+  ].join('\n');
+}
+
+export function graphPhaseChecklist(phase: GraphPhase): string[] {
+  switch (phase) {
+    case 'open':
+      return [
+        'CodeGraph: identify candidate files, symbols, and impact boundary before writing OpenSpec artifacts.',
+        'CodeGraph commands: codegraph brief <file>, codegraph where <symbol>, codegraph search "<intent>".',
+        'Graphify: look for related historical requirements, design notes, and verification reports.',
+        'Graphify commands: graphify query "<question>", graphify explain "<node>".',
+      ];
+    case 'design':
+      return [
+        'CodeGraph: validate proposed modules, callers, callees, and dependency direction before finalizing design.',
+        'CodeGraph commands: codegraph context <function>, codegraph deps <file>, codegraph impact <file>.',
+        'Graphify: compare the design with prior decisions and similar changes.',
+        'Graphify commands: graphify query "<similar change or design decision>".',
+      ];
+    case 'build':
+      return [
+        'CodeGraph: keep edits inside allowed paths and re-check affected symbols before each task.',
+        'CodeGraph commands: codegraph where <symbol>, codegraph fn-impact <function>, codegraph deps <file>.',
+        'Graphify: use only as background context, not as a hard code-editing constraint.',
+        'Graphify commands: graphify explain "<related concept>" when background is needed.',
+      ];
+    case 'verify':
+      return [
+        'CodeGraph: run graph drift and inspect forbidden, out-of-scope, and high-risk file changes.',
+        'CodeGraph commands: codegraph diff-impact, codegraph check, codegraph complexity <target>.',
+        'Graphify: confirm the implementation and verification report still match historical constraints.',
+        'Graphify commands: graphify affected "<node>", graphify query "<verification coverage question>".',
+      ];
+    case 'archive':
+      return [
+        'CodeGraph: refresh structure index after successful archive when available.',
+        'CodeGraph commands: codegraph build, codegraph snapshot.',
+        'Graphify: include proposal, design, plan, verification report, and drift report in long-term memory.',
+        'Graphify commands: graphify save-result, graphify update <path>.',
+      ];
+  }
+}
diff --git a/domains/integrations/graphify.ts b/domains/integrations/graphify.ts
new file mode 100644
index 0000000..8ed8ff1
--- /dev/null
+++ b/domains/integrations/graphify.ts
@@ -0,0 +1,60 @@
+import { execFileSync } from 'child_process';
+import fs from 'fs';
+import path from 'path';
+import { isCommandAvailable } from './openspec.js';
+
+function getPnpmExecutable(platform: NodeJS.Platform = process.platform): string {
+  return platform === 'win32' ? 'pnpm.cmd' : 'pnpm';
+}
+
+function resolvePnpmGlobalCommand(command: string): string | null {
+  try {
+    const binDir = execFileSync(getPnpmExecutable(), ['bin', '-g'], {
+      encoding: 'utf-8',
+      stdio: ['ignore', 'pipe', 'ignore'],
+      timeout: 10_000,
+      shell: process.platform === 'win32',
+    }).trim();
+    if (!binDir) return null;
+
+    const candidates =
+      process.platform === 'win32'
+        ? [`${command}.cmd`, `${command}.exe`, `${command}.ps1`, command]
+        : [command];
+
+    for (const candidate of candidates) {
+      const candidatePath = path.join(binDir, candidate);
+      if (fs.existsSync(candidatePath)) return candidatePath;
+    }
+  } catch {
+    // pnpm may not be installed or may not have a global bin configured.
+  }
+
+  return null;
+}
+
+export function getGraphifyArtifactPath(projectPath: string): string | null {
+  const candidates = [
+    path.join(projectPath, '.graphify', 'graph.json'),
+    path.join(projectPath, 'graphify-out', 'graph.json'),
+  ];
+
+  for (const candidate of candidates) {
+    try {
+      if (fs.statSync(candidate).isFile()) return candidate;
+    } catch {
+      // Keep scanning candidates.
+    }
+  }
+
+  return null;
+}
+
+export function hasGraphifyProjectArtifact(projectPath: string): boolean {
+  return getGraphifyArtifactPath(projectPath) !== null;
+}
+
+export function resolveGraphifyCommand(): string | null {
+  if (isCommandAvailable('graphify')) return 'graphify';
+  return resolvePnpmGlobalCommand('graphify');
+}
diff --git a/pnpm-workspace.yaml b/pnpm-workspace.yaml
new file mode 100644
index 0000000..273db62
--- /dev/null
+++ b/pnpm-workspace.yaml
@@ -0,0 +1,3 @@
+allowBuilds:
+  '@fission-ai/openspec': true
+  esbuild: true
diff --git a/scripts/build/build-classic-runtime.mjs b/scripts/build/build-classic-runtime.mjs
index 48b5a18..8141478 100644
--- a/scripts/build/build-classic-runtime.mjs
+++ b/scripts/build/build-classic-runtime.mjs
@@ -18,7 +18,7 @@ const commandOutputs = Object.entries(layout.classicRuntime.outputs)
   .filter(([name]) => name !== 'runtime')
   .map(([name, output]) => ({
     name,
-    command: name === 'hookGuard' ? 'hook-guard' : name,
+    command: name.replace(/[A-Z]/gu, (match) => `-${match.toLowerCase()}`),
     output,
     outputFile: resolveRepositoryPath(output),
   }));
diff --git a/test/domains/comet-classic/comet-scripts.test.ts b/test/domains/comet-classic/comet-scripts.test.ts
index 7ba2af1..cd935b6 100644
--- a/test/domains/comet-classic/comet-scripts.test.ts
+++ b/test/domains/comet-classic/comet-scripts.test.ts
@@ -142,6 +142,14 @@ describe('comet script contracts', () => {
       guard: await fs.readFile(path.join(scriptsDir, 'comet-guard.mjs'), 'utf-8'),
       handoff: await fs.readFile(path.join(scriptsDir, 'comet-handoff.mjs'), 'utf-8'),
       archive: await fs.readFile(path.join(scriptsDir, 'comet-archive.mjs'), 'utf-8'),
+      'firmware-verify': await fs.readFile(
+        path.join(scriptsDir, 'comet-firmware-verify.mjs'),
+        'utf-8',
+      ),
+      'graph-context': await fs.readFile(
+        path.join(scriptsDir, 'comet-graph-context.mjs'),
+        'utf-8',
+      ),
       'hook-guard': await fs.readFile(path.join(scriptsDir, 'comet-hook-guard.mjs'), 'utf-8'),
       intent: await fs.readFile(path.join(scriptsDir, 'comet-intent.mjs'), 'utf-8'),
     };
@@ -189,7 +197,9 @@ describe('comet scripts', () => {
       'comet-runtime.mjs',
       'comet-env.mjs',
       'comet-archive.mjs',
+      'comet-firmware-verify.mjs',
       'comet-guard.mjs',
+      'comet-graph-context.mjs',
       'comet-handoff.mjs',
       'comet-state.mjs',
       'comet-intent.mjs',
@@ -2283,6 +2293,172 @@ describe('comet scripts', () => {
     expect(result.stderr).toContain('build_mode=direct is only allowed for hotfix/tweak');
   });
 
+  it('creates graph context artifacts and records their paths in state', async () => {
+    const graphScript = path.join(tmpDir, 'scripts', 'comet-graph-context.mjs');
+    const init = runNode(tmpDir, stateScript, ['init', 'graph-context-defaults', 'full']);
+
+    const result = runNode(tmpDir, graphScript, [
+      'refresh',
+      'graph-context-defaults',
+      '--phase',
+      'open',
+    ]);
+    const yaml = await fs.readFile(
+      path.join(tmpDir, 'openspec', 'changes', 'graph-context-defaults', '.comet.yaml'),
+      'utf-8',
+    );
+    const graphContext = await fs.readFile(
+      path.join(
+        tmpDir,
+        'openspec',
+        'changes',
+        'graph-context-defaults',
+        '.comet',
+        'graph',
+        'graph-context.md',
+      ),
+      'utf-8',
+    );
+    const graphState = JSON.parse(
+      await fs.readFile(
+        path.join(
+          tmpDir,
+          'openspec',
+          'changes',
+          'graph-context-defaults',
+          '.comet',
+          'graph',
+          'graph-state.json',
+        ),
+        'utf-8',
+      ),
+    ) as {
+      codegraph: { status: string; skippedReason: string | null };
+      graphify: { status: string; skippedReason: string | null };
+      drift: { status: string };
+    };
+
+    expect(init.status).toBe(0);
+    expect(result.status).toBe(0);
+    expect(result.stderr).toContain('GRAPH_CONTEXT:');
+    expect(graphContext).toContain('# Graph Context: graph-context-defaults');
+    expect(graphContext).toContain('## Graph Guard');
+    expect(graphContext).toContain('## Phase Graph Checklist');
+    expect(graphContext).toContain('## CodeGraph Analysis');
+    expect(graphContext).toContain('Reason: .codegraph index missing');
+    expect(graphContext).toContain('## Candidate Focus');
+    expect(graphContext).toContain('## Drift Summary');
+    expect(graphContext).toContain('## Graphify Notes');
+    expect(graphContext).toContain('Reason: graph.json missing');
+    expect(yaml).toContain('graph_context_enabled: true');
+    expect(yaml).toContain(
+      'graph_context: openspec/changes/graph-context-defaults/.comet/graph/graph-context.md',
+    );
+    expect(yaml).not.toContain('graph_constraints:');
+    expect(graphState.codegraph.status).toBe('skipped');
+    expect(graphState.codegraph.skippedReason).toContain('.codegraph index missing');
+    expect(graphState.graphify.status).toBe('skipped');
+    expect(graphState.graphify.skippedReason).toContain('graph.json missing');
+    expect(graphState.drift.status).toBe('pass');
+  });
+
+  it('includes firmware profile details in graph context when configured', async () => {
+    const graphScript = path.join(tmpDir, 'scripts', 'comet-graph-context.mjs');
+    await writeFile(
+      path.join(tmpDir, 'compile_commands.json'),
+      JSON.stringify([
+        { directory: tmpDir, command: 'cc -Iinclude -DCONFIG_UFS_HPC -c src/ufs.c', file: 'src/ufs.c' },
+      ]),
+    );
+    await writeFile(
+      path.join(tmpDir, '.comet', 'firmware-profile.yaml'),
+      [
+        'enabled: true',
+        'language: c',
+        'build_system: make',
+        'compile_database: compile_commands.json',
+        'source_roots:',
+        '  - src/**',
+        'high_risk_paths:',
+        '  - "**/ufs*/**"',
+        'forbidden_paths:',
+        '  - generated/**',
+        '',
+      ].join('\n'),
+    );
+    const init = runNode(tmpDir, stateScript, ['init', 'firmware-context', 'full']);
+
+    const result = runNode(tmpDir, graphScript, ['refresh', 'firmware-context', '--phase', 'open']);
+    const graphContext = await fs.readFile(
+      path.join(
+        tmpDir,
+        'openspec',
+        'changes',
+        'firmware-context',
+        '.comet',
+        'graph',
+        'graph-context.md',
+      ),
+      'utf-8',
+    );
+
+    expect(init.status).toBe(0);
+    expect(result.status).toBe(0);
+    expect(graphContext).toContain('## Firmware Profile');
+    expect(graphContext).toContain('- Enabled: true');
+    expect(graphContext).toContain('- Language: c');
+    expect(graphContext).toContain('- Build System: make');
+    expect(graphContext).toContain('- Compile Database: compile_commands.json');
+    expect(graphContext).toContain('- Compile Database Status: present (1 entries)');
+    expect(graphContext).toContain('## Compile Database Summary');
+    expect(graphContext).toContain('- Sample Files: src/ufs.c');
+    expect(graphContext).toContain('- Include Roots: include');
+    expect(graphContext).toContain('- Define Flags: CONFIG_UFS_HPC');
+  });
+
+  it('runs configured firmware verification commands and writes a report', async () => {
+    const firmwareVerifyScript = path.join(tmpDir, 'scripts', 'comet-firmware-verify.mjs');
+    await writeFile(
+      path.join(tmpDir, '.comet', 'firmware-profile.yaml'),
+      [
+        'enabled: true',
+        'language: c',
+        'build_system: make',
+        'compile_database: compile_commands.json',
+        'build_command: "printf build-ok"',
+        'test_command: null',
+        'static_analysis_command: "printf static-ok"',
+        'source_roots:',
+        '  - src/**',
+        '',
+      ].join('\n'),
+    );
+    const init = runNode(tmpDir, stateScript, ['init', 'firmware-verify-pass', 'full']);
+
+    const result = runNode(tmpDir, firmwareVerifyScript, ['firmware-verify-pass']);
+    const report = await fs.readFile(
+      path.join(
+        tmpDir,
+        'openspec',
+        'changes',
+        'firmware-verify-pass',
+        '.comet',
+        'graph',
+        'firmware-verify-report.md',
+      ),
+      'utf-8',
+    );
+
+    expect(init.status).toBe(0);
+    expect(result.status).toBe(0);
+    expect(report).toContain('- Status: pass');
+    expect(report).toContain('- build_command: pass');
+    expect(report).toContain('build-ok');
+    expect(report).toContain('- test_command: skipped (not configured)');
+    expect(report).toContain('- static_analysis_command: pass');
+    expect(report).toContain('static-ok');
+  });
+
   it('allows direct build mode for full workflow with explicit override', async () => {
     await createChange(
       tmpDir,
diff --git a/test/domains/integrations/firmware-profile.test.ts b/test/domains/integrations/firmware-profile.test.ts
new file mode 100644
index 0000000..fd940cd
--- /dev/null
+++ b/test/domains/integrations/firmware-profile.test.ts
@@ -0,0 +1,81 @@
+import { afterEach, beforeEach, describe, expect, it } from 'vitest';
+import { promises as fs } from 'fs';
+import os from 'os';
+import path from 'path';
+import {
+  inspectCompileDatabase,
+  readFirmwareProfile,
+} from '../../../domains/integrations/firmware-profile.js';
+
+describe('firmware profile integration', () => {
+  let tmpDir: string;
+
+  beforeEach(async () => {
+    tmpDir = path.join(
+      os.tmpdir(),
+      `comet-firmware-profile-${Date.now()}-${Math.random().toString(36).slice(2)}`,
+    );
+    await fs.mkdir(path.join(tmpDir, '.comet'), { recursive: true });
+  });
+
+  afterEach(async () => {
+    await fs.rm(tmpDir, { recursive: true, force: true });
+  });
+
+  it('reads a configured profile', async () => {
+    await fs.writeFile(
+      path.join(tmpDir, '.comet', 'firmware-profile.yaml'),
+      [
+        'enabled: true',
+        'language: c',
+        'build_system: make',
+        'compile_database: compile_commands.json',
+        'source_roots:',
+        '  - src/**',
+        '',
+      ].join('\n'),
+    );
+
+    const profile = await readFirmwareProfile(tmpDir);
+    expect(profile.status).toBe('configured');
+    if (profile.status !== 'configured') return;
+    expect(profile.profile.language).toBe('c');
+    expect(profile.profile.compileDatabase).toBe('compile_commands.json');
+  });
+
+  it('inspects and summarizes compile database entries', async () => {
+    await fs.writeFile(
+      path.join(tmpDir, '.comet', 'firmware-profile.yaml'),
+      [
+        'enabled: true',
+        'language: c',
+        'build_system: make',
+        'compile_database: compile_commands.json',
+        'source_roots:',
+        '  - src/**',
+        '',
+      ].join('\n'),
+    );
+    await fs.writeFile(
+      path.join(tmpDir, 'compile_commands.json'),
+      JSON.stringify([
+        {
+          directory: tmpDir,
+          command: 'cc -Iinclude/ufs -DCONFIG_UFS_HPC -c src/ufs/cache.c',
+          file: 'src/ufs/cache.c',
+        },
+      ]),
+    );
+
+    const profile = await readFirmwareProfile(tmpDir);
+    if (profile.status !== 'configured') throw new Error('expected configured profile');
+    const status = await inspectCompileDatabase(tmpDir, profile.profile);
+    expect(status).toMatchObject({
+      status: 'present',
+      entries: 1,
+      sampleFiles: ['src/ufs/cache.c'],
+      includeRoots: ['include/ufs'],
+      defineFlags: ['CONFIG_UFS_HPC'],
+    });
+  });
+});
diff --git a/test/domains/integrations/graph-context.test.ts b/test/domains/integrations/graph-context.test.ts
new file mode 100644
index 0000000..1e9ace5
--- /dev/null
+++ b/test/domains/integrations/graph-context.test.ts
@@ -0,0 +1,298 @@
+import { promises as fs } from 'fs';
+import os from 'os';
+import path from 'path';
+import { describe, expect, it } from 'vitest';
+import {
+  analyzeGraphDrift,
+  buildDriftWarnings,
+  buildGraphStatePayload,
+  extractCodegraphSummary,
+  graphPhaseChecklist,
+  matchesAnyPattern,
+  parseYamlListLines,
+  readGraphContextRuntimeConfig,
+  renderGraphContextMarkdown,
+  resolveGraphAnalysisMode,
+  resolveGraphContextEnabled,
+  skippedCodegraphSummary,
+  snapshotForArtifact,
+  summarizeGraphifyResult,
+} from '../../../domains/integrations/graph-context.js';
+
+describe('graph context core rules', () => {
+  it('parses root-level and nested YAML list fields', () => {
+    const raw = [
+      'enabled: true',
+      'high_risk_paths:',
+      '  - "**/ufs*/**"',
+      'graph_constraints:',
+      '  allowed_paths:',
+      '    - src/**',
+      '    - include/**',
+      '  forbidden_paths:',
+      '    - dist/**',
+      '',
+    ].join('\n');
+
+    expect(parseYamlListLines(raw, 'high_risk_paths')).toEqual(['**/ufs*/**']);
+    expect(parseYamlListLines(raw, 'allowed_paths')).toEqual(['src/**', 'include/**']);
+    expect(parseYamlListLines(raw, 'forbidden_paths')).toEqual(['dist/**']);
+  });
+
+  it('resolves graph runtime config from project defaults', async () => {
+    const tempDir = await fs.mkdtemp(path.join(os.tmpdir(), 'comet-graph-config-'));
+    await fs.mkdir(path.join(tempDir, '.comet'), { recursive: true });
+    await fs.writeFile(
+      path.join(tempDir, '.comet', 'config.yaml'),
+      ['graph_context_enabled: false', 'graph_analysis: standard', ''].join('\n'),
+      'utf8',
+    );
+
+    await expect(resolveGraphContextEnabled(tempDir, null)).resolves.toBe(false);
+    await expect(resolveGraphAnalysisMode(tempDir)).resolves.toBe('standard');
+    await expect(readGraphContextRuntimeConfig(tempDir, null)).resolves.toEqual({
+      enabled: false,
+      mode: 'standard',
+    });
+  });
+
+  it('falls back to safe graph runtime defaults', async () => {
+    const tempDir = await fs.mkdtemp(path.join(os.tmpdir(), 'comet-graph-config-'));
+    await fs.mkdir(path.join(tempDir, '.comet'), { recursive: true });
+    await fs.writeFile(
+      path.join(tempDir, '.comet', 'config.yaml'),
+      ['graph_context_enabled: maybe', 'graph_analysis: invalid', ''].join('\n'),
+      'utf8',
+    );
+
+    await expect(resolveGraphContextEnabled(tempDir, true)).resolves.toBe(true);
+    await expect(resolveGraphAnalysisMode(tempDir)).resolves.toBe('light');
+  });
+
+  it('matches shell-style graph path patterns used by comet scripts', () => {
+    expect(matchesAnyPattern('src/ufs/ufs_dma.c', ['**/ufs*/**'])).toBe(true);
+    expect(matchesAnyPattern('generated/auto.c', ['generated/**'])).toBe(true);
+    expect(matchesAnyPattern('src/ufs/ufs_dma.c', ['drivers/**'])).toBe(false);
+  });
+
+  it('analyzes forbidden, out-of-scope, and high-risk graph drift', () => {
+    const result = analyzeGraphDrift({
+      changedFiles: ['src/ufs/ufs_dma.c', 'dist/generated.c', 'generated/auto.c'],
+      allowedPaths: ['src/**'],
+      forbiddenPaths: ['dist/**', 'generated/**'],
+      highRiskPaths: ['**/ufs*/**'],
+    });
+
+    expect(result).toEqual({
+      status: 'warn',
+      forbiddenHits: ['dist/generated.c', 'generated/auto.c'],
+      outOfScopeHits: ['dist/generated.c', 'generated/auto.c'],
+      highRiskHits: ['src/ufs/ufs_dma.c'],
+      acceptedHits: [],
+      shouldRequireFullVerify: true,
+    });
+  });
+
+  it('records accepted deviations without reporting them as drift warnings', () => {
+    const result = analyzeGraphDrift({
+      changedFiles: ['src/ufs/ufs_dma.c', 'dist/generated.c'],
+      allowedPaths: ['src/**'],
+      forbiddenPaths: ['dist/**'],
+      highRiskPaths: ['**/ufs*/**'],
+      acceptedDeviations: ['dist/**', '**/ufs*/**'],
+    });
+
+    expect(result).toEqual({
+      status: 'pass',
+      forbiddenHits: [],
+      outOfScopeHits: [],
+      highRiskHits: [],
+      acceptedHits: ['src/ufs/ufs_dma.c', 'dist/generated.c'],
+      shouldRequireFullVerify: true,
+    });
+  });
+
+  it('keeps graph guidance phase-specific', () => {
+    expect(graphPhaseChecklist('open').join('\n')).toContain('OpenSpec artifacts');
+    expect(graphPhaseChecklist('design').join('\n')).toContain('callers');
+    expect(graphPhaseChecklist('build').join('\n')).toContain('allowed paths');
+    expect(graphPhaseChecklist('verify').join('\n')).toContain('graph drift');
+    expect(graphPhaseChecklist('archive').join('\n')).toContain('long-term memory');
+  });
+
+  it('extracts candidate files, symbols, and hints from CodeGraph text', () => {
+    const summary = extractCodegraphSummary([
+      'Impact boundary: src/ufs/ufs_dma.c include/ufs_dma.h',
+      'Related symbol: hp_cache_insert hp_cache_lookup GRAPH_CONTEXT',
+      'History constraint: avoid touching vendor/generated.c',
+    ].join('\n'));
+
+    expect(summary.status).toBe('ok');
+    expect(summary.candidateFiles).toContain('src/ufs/ufs_dma.c');
+    expect(summary.candidateFiles).toContain('include/ufs_dma.h');
+    expect(summary.candidateFiles).toContain('vendor/generated.c');
+    expect(summary.candidateSymbols).toContain('hp_cache_insert');
+    expect(summary.candidateSymbols).toContain('hp_cache_lookup');
+    expect(summary.candidateSymbols).not.toContain('GRAPH_CONTEXT');
+    expect(summary.relevanceHints[0]).toContain('Impact boundary');
+  });
+
+  it('builds skipped and summarized Graphify states', () => {
+    expect(skippedCodegraphSummary('graph_analysis=off')).toEqual({
+      status: 'skipped',
+      skippedReason: 'graph_analysis=off',
+      candidateFiles: [],
+      candidateSymbols: [],
+      relevanceHints: [],
+    });
+
+    expect(summarizeGraphifyResult('light', 'note a\n\nnote b\n', null)).toEqual({
+      status: 'ok',
+      skippedReason: null,
+      notes: ['note a', 'note b'],
+    });
+
+    expect(summarizeGraphifyResult('off', '', 'graph_analysis=off')).toEqual({
+      status: 'skipped',
+      skippedReason: 'graph_analysis=off',
+      notes: [],
+    });
+  });
+
+  it('derives artifact freshness from provided changed files', async () => {
+    const tempDir = await fs.mkdtemp(path.join(os.tmpdir(), 'comet-graph-context-'));
+    const artifact = path.join(tempDir, 'graph.json');
+    await fs.writeFile(artifact, '{}', 'utf8');
+
+    await expect(snapshotForArtifact(artifact, 'Graphify', [])).resolves.toEqual({
+      freshness: {
+        status: 'fresh',
+        recommendation: 'Graphify artifact is aligned with current workspace.',
+        newerRelevantFileCount: 0,
+      },
+    });
+
+    await expect(snapshotForArtifact(artifact, 'Graphify', ['src/a.c'])).resolves.toEqual({
+      freshness: {
+        status: 'stale-but-usable',
+        recommendation: 'Graphify artifact is usable, but changed files exist since the last graph snapshot.',
+        newerRelevantFileCount: 1,
+      },
+    });
+
+    await expect(
+      snapshotForArtifact(artifact, 'Graphify', ['a', 'b', 'c', 'd', 'e']),
+    ).resolves.toEqual({
+      freshness: {
+        status: 'stale-and-should-refresh',
+        recommendation: 'Refresh Graphify before trusting graph context.',
+        newerRelevantFileCount: 5,
+      },
+    });
+  });
+
+  it('builds graph state payload and markdown from shared helpers', () => {
+    const driftWarnings = buildDriftWarnings(
+      {
+        status: 'warn',
+        forbiddenHits: ['dist/generated.c'],
+        outOfScopeHits: ['dist/generated.c'],
+        highRiskHits: ['src/ufs/ufs_dma.c'],
+        acceptedHits: [],
+        shouldRequireFullVerify: true,
+      },
+      ['hp_cache_lookup'],
+      ['hp_cache_insert'],
+    );
+
+    expect(driftWarnings).toEqual([
+      'forbidden path changed: dist/generated.c',
+      'out-of-scope path changed: dist/generated.c',
+      'high-risk path changed: src/ufs/ufs_dma.c',
+      'expected symbol missing from summary: hp_cache_lookup',
+      'protected symbol changed: hp_cache_insert',
+    ]);
+
+    const graphState = buildGraphStatePayload({
+      phase: 'verify',
+      mode: 'light',
+      codegraphSnapshot: {
+        freshness: {
+          status: 'fresh',
+          recommendation: 'ok',
+          newerRelevantFileCount: 0,
+        },
+      },
+      codegraphSummary: {
+        status: 'ok',
+        skippedReason: null,
+        candidateFiles: ['src/ufs/ufs_dma.c'],
+        candidateSymbols: ['hp_cache_insert'],
+        relevanceHints: ['Impact boundary: src/ufs/ufs_dma.c'],
+      },
+      graphifySnapshot: {
+        freshness: {
+          status: 'stale-but-usable',
+          recommendation: 'refresh later',
+          newerRelevantFileCount: 2,
+        },
+      },
+      graphifySummary: {
+        status: 'ok',
+        skippedReason: null,
+        notes: ['similar change: cache preload'],
+      },
+      driftStatus: 'warn',
+      driftWarnings,
+      changedFiles: ['src/ufs/ufs_dma.c'],
+      shouldRequireFullVerify: true,
+    });
+
+    expect(graphState.drift.shouldRequireFullVerify).toBe(true);
+    expect(graphState.codegraph.candidateFiles).toEqual(['src/ufs/ufs_dma.c']);
+
+    const markdown = renderGraphContextMarkdown({
+      changeName: 'demo-change',
+      phase: 'verify',
+      mode: 'light',
+      codegraphSnapshot: graphState.codegraph,
+      graphifySnapshot: graphState.graphify,
+      codegraphAnalysis: 'Impact boundary: src/ufs/ufs_dma.c',
+      codegraphSummary: graphState.codegraph,
+      graphifySummary: graphState.graphify,
+      driftStatus: 'warn',
+      driftWarnings,
+      changedFiles: ['src/ufs/ufs_dma.c'],
+      firmwareProfile: {
+        status: 'configured',
+        path: '/tmp/.comet/firmware-profile.yaml',
+        profile: {
+          enabled: true,
+          language: 'c',
+          buildSystem: 'make',
+          compileDatabase: 'build/compile_commands.json',
+          buildCommand: 'make',
+          testCommand: 'ctest',
+          staticAnalysisCommand: 'clang-tidy',
+          sourceRoots: ['src', 'include'],
+          highRiskPaths: ['src/ufs/**'],
+          forbiddenPaths: ['dist/**'],
+        },
+      },
+      compileDatabaseStatus: {
+        status: 'present',
+        path: '/tmp/build/compile_commands.json',
+        entries: 12,
+        sampleFiles: ['src/ufs/ufs_dma.c'],
+        includeRoots: ['include'],
+        defineFlags: ['UFS_HPC=1'],
+      },
+    });
+
+    expect(markdown).toContain('# Graph Context: demo-change');
+    expect(markdown).toContain('## Firmware Profile');
+    expect(markdown).toContain('## Compile Database Summary');
+    expect(markdown).toContain('protected symbol changed: hp_cache_insert');
+    expect(markdown).toContain('similar change: cache preload');
+  });
+});
-- 
2.53.0

