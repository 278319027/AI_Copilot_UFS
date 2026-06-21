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

## Bootstrap 决策表（强制）

**会话开始时必读**。本表告诉 AI Agent 何时加载哪个子 skill。**没有加载 = 不掌握该 skill 的纪律**，铁律退化为了手动清单。

### 场景 → Skill 映射

| 触发场景 | 必加载 skill | 缺失后果 |
|----------|-------------|----------|
| 会话开始 / 收到新需求 | `superpowers-using-superpowers` | 上下文无纪律约束 |
| 涉及 bug、test failure、异常行为 | `superpowers-systematic-debugging` | 凭直觉打补丁 |
| 写生产代码（Path A 纯逻辑） | `superpowers-test-driven-development` | 无失败测试、无回归保护 |
| 写生产代码（Path B 硬件依赖） | `superpowers-test-driven-development` | BUILD 编译通过 ≠ 系统正确 |
| 进入 BUILD 阶段 | `superpowers-executing-plans` + `superpowers-verification-before-completion` | 跳过任务、跳过验证 |
| 复杂任务（多文件、多模块） | `superpowers-subagent-driven-development` | 上下文爆炸、需求漂移 |
| 2+ 独立可并行任务 | `superpowers-dispatching-parallel-agents` | 串行浪费 |
| 合并前 / 用户说「review my work」 | `superpowers-requesting-code-review` | AI 自批自审 |
| 收到审查反馈 | `superpowers-receiving-code-review` | 表演性认同 / 盲目实现 |
| 所有任务完成，准备合并 | `superpowers-finishing-a-development-branch` | 直接合并不清理 |
| 宣称「完成 / 修复 / 通过」 | `superpowers-verification-before-completion` | 无证据断言 |

### 阶段转换触发器

| 阶段转换 | 应读取并遵循 |
|----------|----------|
| KNOW → PLAN | `openspec-workflow`（顶级 skill，可通过 `skill()` 加载） |
| PLAN → BUILD | `skill(name="superpowers-test-driven-development")` + `skill(name="superpowers-executing-plans")` + `skill(name="superpowers-verification-before-completion")` |
| BUILD → FEEDBACK | `skill(name="superpowers-requesting-code-review")` |
| FEEDBACK → Archive | `skill(name="superpowers-finishing-a-development-branch")` |

### 红线自检（每次动作前问自己）

- [ ] 我即将「声称完成」吗？→ 使用 `skill(name="superpowers-verification-before-completion")` 并实际跑命令
- [ ] 我即将「修 bug」吗？→ 使用 `skill(name="superpowers-systematic-debugging")` 并完成根因调查
- [ ] 我即将「写生产代码」吗？→ 使用 `skill(name="superpowers-test-driven-development")` 并按 Path A/B 走
- [ ] 我即将「合并」吗？→ 使用 `skill(name="superpowers-requesting-code-review")` 并完成 Review Gate

## Iron rules (non-negotiable)

These are the absolute rules from the Superpowers framework. Violating the letter is
violating the spirit.

- **NO COMPLETION CLAIMS WITHOUT FRESH VERIFICATION EVIDENCE** — never say "done" /
  "fixed" / "passes" / "works" without having just run the verifying command and read
  its output. See `superpowers-verification-before-completion/SKILL.md`.
- **NO PRODUCTION CODE WITHOUT VERIFICATION** — For pure-logic code: write the test, watch it fail for the right reason, then write the minimum code to pass (see `superpowers-test-driven-development/SKILL.md` Path A). For hardware-dependent code: compile cleanly first (BUILD), then run system tests at FEEDBACK (see `superpowers-test-driven-development/SKILL.md` Path B).
- **NO FIXES WITHOUT ROOT CAUSE INVESTIGATION FIRST** — reproduce, read errors, check
  recent changes, form a hypothesis, test it minimally. See
  `superpowers-systematic-debugging/SKILL.md`.
- **NO MERGE WITHOUT CODE REVIEW** — request review on every non-trivial change;
  receive review technically, never performatively. See
  `superpowers-requesting-code-review/SKILL.md` and `superpowers-receiving-code-review/SKILL.md`.

## Skill map

| Skill | When to invoke | Iron rule enforced |
|-------|----------------|--------------------|
| `superpowers-using-superpowers/SKILL.md` | **Start of every conversation.** Bootstrap that decides which other skills apply. | Skill-aware behaviour |
| `superpowers-systematic-debugging/SKILL.md` | Any bug, test failure, or unexpected behaviour — **before** proposing fixes. | Root cause first |
| `superpowers-test-driven-development/SKILL.md` | Any new feature, bug fix, refactor, or behaviour change. | Path A (test first) or Path B (compile + FEEDBACK) |
| `superpowers-verification-before-completion/SKILL.md` | **Before** any claim of completion, success, or "passing". | Evidence before assertion |
| `superpowers-executing-plans/SKILL.md` | When you have a written plan and want to run it (sequential, with checkpoints). | Plan-execute-verify |
| `superpowers-subagent-driven-development/SKILL.md` | When you have a plan with mostly independent tasks and want parallel subagent execution with per-task review. | Fresh subagent per task + review |
| `superpowers-dispatching-parallel-agents/SKILL.md` | 2+ independent investigations or fixes that can run concurrently. | One domain per agent |
| `superpowers-requesting-code-review/SKILL.md` | Before merging, after each task, when stuck. | Review before merge |
| `superpowers-receiving-code-review/SKILL.md` | When receiving any code-review feedback. | Verify before implementing |
| `superpowers-finishing-a-development-branch/SKILL.md` | All tasks complete, tests pass, ready to integrate. | Verify-then-present-options |

## Skill priority within this project

```text
1. Project skills (this directory, .opencode/skills/)        ← highest
2. Personal skills (~/.config/opencode/skills/)
3. Superpowers plugin (obra/superpowers, if installed)
```


## How to invoke

In an OpenCode session, use the native `skill` tool to load each skill explicitly. Each sub-skill is a standalone skill file in `.opencode/skills/`. Example:

```
skill(name="superpowers")    // loads main framework
skill(name="superpowers-test-driven-development")  // loads a sub-skill
```

The full SKILL.md content of that sub-skill is then injected into the context
and its rules are in force for the duration of the work.

## Adapters (delegating to Superpowers)

The sole integrating skill is `.opencode/skills/sd-firmware-copilot/SKILL.md`, which delegates to the relevant Superpowers sub-skills and adds SSD-specific pre/post steps.

## Origin and license

- Upstream: https://github.com/obra/superpowers
- License: MIT (see https://github.com/obra/superpowers/blob/main/LICENSE)
- Local commit: see `git log --follow .opencode/skills/superpowers/SKILL.md` to find the integration commit
- Plugin install (alternative): add `"plugin": ["superpowers@git+https://github.com/obra/superpowers.git"]`
  to `opencode.json`. Local copies take priority over the plugin and are preferred
  for offline / reproducible builds.
