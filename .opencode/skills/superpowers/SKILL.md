---
name: superpowers
description: Use when starting any engineering workflow - this is the entry point for the Superpowers skills framework that provides generic, agent-agnostic engineering discipline (TDD, systematic debugging, code review, subagent-driven execution). Acts as the lower layer beneath the SSD firmware domain rules.
---

# Superpowers — Engineering Discipline Layer

This is the local copy of the [Superpowers](https://github.com/obra/superpowers) skills
framework. The skills inside this directory are **generic, project-agnostic engineering
discipline** — they encode universal best practices (TDD, root-cause debugging,
verification, code review) and are designed to work on any codebase in any language.

They are intentionally separated from project-specific rules. In this project, Superpowers
is the **lower layer** in a two-layer architecture:

```text
┌─────────────────────────────────────────────────────────────┐
│  Upper layer — Domain rules (SDD-specific)                  │
│  skills/sd-firmware-copilot/SKILL.md                        │
│  + memory/ + openspec/specs/ + openspec/                   │
│  → "What" to build for an SSD controller                    │
├─────────────────────────────────────────────────────────────┤
│  Lower layer — Engineering discipline (project-agnostic)    │
│  skills/superpowers/  (this directory)                      │
│  → "How" to write correct code, test it, review it, ship it │
└─────────────────────────────────────────────────────────────┘
```

The two layers are **additive, not competing**:

- Superpowers decides *how* to brainstorm, plan, test, debug, and review.
- `sd-firmware-copilot` decides *what* the change means for FTL/NVMe/NAND/error-handling,
  and adds the SSD-specific evidence trail (CodeGraph queries, OpenSpec artifacts,
  specs/ increment vs baseline consistency).

When both layers apply, follow the upper layer's domain rules **on top of** the lower
layer's engineering discipline — never one at the expense of the other.

## Iron rules (non-negotiable)

These are the absolute rules from the Superpowers framework. Violating the letter is
violating the spirit.

- **NO COMPLETION CLAIMS WITHOUT FRESH VERIFICATION EVIDENCE** — never say "done" /
  "fixed" / "passes" / "works" without having just run the verifying command and read
  its output. See `verification-before-completion/SKILL.md`.
- **NO PRODUCTION CODE WITHOUT VERIFICATION** — For pure-logic code: write the test, watch it fail for the right reason, then write the minimum code to pass (see `test-driven-development/SKILL.md` Path A). For hardware-dependent code: compile cleanly first (BUILD), then run system tests at FEEDBACK (see `test-driven-development/SKILL.md` Path B).
- **NO FIXES WITHOUT ROOT CAUSE INVESTIGATION FIRST** — reproduce, read errors, check
  recent changes, form a hypothesis, test it minimally. See
  `systematic-debugging/SKILL.md`.
- **NO MERGE WITHOUT CODE REVIEW** — request review on every non-trivial change;
  receive review technically, never performatively. See
  `requesting-code-review/SKILL.md` and `receiving-code-review/SKILL.md`.

## Skill map

| Skill | When to invoke | Iron rule enforced |
|-------|----------------|--------------------|
| `using-superpowers/SKILL.md` | **Start of every conversation.** Bootstrap that decides which other skills apply. | Skill-aware behaviour |
| `systematic-debugging/SKILL.md` | Any bug, test failure, or unexpected behaviour — **before** proposing fixes. | Root cause first |
| `test-driven-development/SKILL.md` | Any new feature, bug fix, refactor, or behaviour change. | Path A (test first) or Path B (compile + FEEDBACK) |
| `verification-before-completion/SKILL.md` | **Before** any claim of completion, success, or "passing". | Evidence before assertion |
| `executing-plans/SKILL.md` | When you have a written plan and want to run it (sequential, with checkpoints). | Plan-execute-verify |
| `subagent-driven-development/SKILL.md` | When you have a plan with mostly independent tasks and want parallel subagent execution with per-task review. | Fresh subagent per task + review |
| `dispatching-parallel-agents/SKILL.md` | 2+ independent investigations or fixes that can run concurrently. | One domain per agent |
| `requesting-code-review/SKILL.md` | Before merging, after each task, when stuck. | Review before merge |
| `receiving-code-review/SKILL.md` | When receiving any code-review feedback. | Verify before implementing |
| `finishing-a-development-branch/SKILL.md` | All tasks complete, tests pass, ready to integrate. | Verify-then-present-options |

## Skill priority within this project

```text
1. Project skills (this directory, .opencode/skills/)        ← highest
2. Personal skills (~/.config/opencode/skills/)
3. Superpowers plugin (obra/superpowers, if installed)
```


## How to invoke

In an OpenCode session, use the platform's `skill` tool to load any of the sub-skills
by name. Example:

```
use skill tool to load superpowers:test-driven-development
```

The full SKILL.md content of that sub-skill is then injected into the conversation
and its rules are in force for the duration of the work.

## Adapters (delegating to Superpowers)

The sole integrating skill is `.opencode/skills/sd-firmware-copilot/SKILL.md`, which delegates to the relevant Superpowers sub-skills and adds SSD-specific pre/post steps.

## Origin and license

- Upstream: https://github.com/obra/superpowers
- License: MIT (see /tmp/superpowers/LICENSE)
- Local commit: pinned to the shallow clone performed at integration time.
- Plugin install (alternative): add `"plugin": ["superpowers@git+https://github.com/obra/superpowers.git"]`
  to `opencode.json`. Local copies take priority over the plugin and are preferred
  for offline / reproducible builds.
