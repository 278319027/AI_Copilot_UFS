---
name: opencode-c-workflow
description: "MANDATORY six-phase pipeline for any C code change touching 2+ files/functions. Graph-constrained spec-first workflow: SCOPE GROUND PLAN PATCH VERIFY REPORT. Combines OpenSpec (scope/tasks), CodeGraph+Graphify (code structure), Superpowers (execution discipline). Triggers: modify .c .h files, C bugfix, C feature, C refactor, C API change, MISRA, embedded C, firmware. Skip: single-line comments, typos, config-only. Hard stop if prerequisites missing."
---

# ⚠️ ACTIVATE IMMEDIATELY

## PREREQUISITE GATE — HARD STOP

Check ALL four. ANY failure → STOP and report missing tool. NO exceptions, NO degradation.

| Tool | Check |
|------|-------|
| OpenSpec | `openspec --version` succeeds |
| CodeGraph | `.codegraph/graph.db` exists |
| Graphify | `graphify-out/graph.json` exists |
| Superpowers | `skill(name="superpowers-using-superpowers")` succeeds |

## PHASE 1: SCOPE — Freeze before touching code

**DO:**
1. If requirements unclear → `skill(name="superpowers-brainstorming")`
2. Create change: `skill(name="openspec-propose")` OR `skill(name="openspec-explore")`
3. Extract scope: `openspec instructions proposal --change <name> --json`

**GATE → DO NOT ENTER PHASE 2 UNTIL:**
- [ ] scope.files, constraints, acceptance criteria, test plan ALL documented
- [ ] User explicitly approved scope (not assumed, not inferred)

## PHASE 2: GROUND — Graph before source (core differentiator)

**GRAPH-FIRST RULE**: Do NOT open source files. Query graphs. Source code only after graph analysis complete.

**DO (in order):**

=== Macro: Graphify ===
1. `graphify query "<task concept>" --budget 1500`
2. `graphify path "<A>" "<B>"` for each key relationship in scope
3. `graphify explain "<key concept>"`

=== Micro: CodeGraph ===
4. `codegraph_context("<func>")` for EACH function in scope
5. `codegraph_fn_impact("<func>", depth=3)` for EACH

=== Safety: CodeGraph ===
6. `codegraph_find_cycles()`
7. `codegraph_complexity(above_threshold=true)`
8. `codegraph_semantic_search("<domain concept>")`

**GATE → DO NOT ENTER PHASE 3 UNTIL:**
- [ ] Graph evidence does NOT contradict scope (if conflict → STOP, resolve with user)
- [ ] All affected files, key functions, callers, callees identified
- [ ] Cycle dependencies and complexity hotspots flagged
- [ ] Risk areas and design constraints documented

See: `references/codegraph-usage.md`, `references/graphify-usage.md`

## PHASE 3: PLAN — Design before code

**DO:**
1. Write `design.md` and `tasks.md` via OpenSpec artifacts
2. `codegraph_file_deps("<header>")` for each new/modified header
3. Estimate memory budget (stack/heap/static allocation)
4. `codegraph_diff_impact(staged=true)` — pre-flight check
5. `skill(name="superpowers-writing-plans")` — review tasks.md for completeness

**GATE → DO NOT ENTER PHASE 4 UNTIL:**
- [ ] design.md approved by user
- [ ] tasks.md lists every file change with verification command per task
- [ ] Plan does NOT exceed original scope (if exceeds → re-scope or reject)
- [ ] Header impact and memory budget analyzed

See: `references/openspec-usage.md`

## PHASE 4: PATCH — Test-first, one task at a time

**DO:**
1. `skill(name="superpowers-using-git-worktrees")` — isolate workspace
2. FOR EACH task in tasks.md, in order:
   - **RED**: Write failing test → confirm test FAILS
   - **GREEN**: Implement minimum code → confirm test PASSES
   - `codegraph_check(staged=true)` — CI gate after each task
   - **REFACTOR**: Improve code → keep tests GREEN
3. `codegraph_diff_impact(staged=true)` — verify all changes within scope

**GATE → DO NOT ENTER PHASE 5 UNTIL:**
- [ ] EVERY task has test written BEFORE implementation
- [ ] `codegraph_check(staged=true)` passes for all staged changes
- [ ] Diff does NOT touch files outside scope (if violation → REVERT and re-scope)

See: `references/superpowers-usage.md`

## PHASE 5: VERIFY — Evidence before claims

**DO:**
1. `make clean && make` — exit 0, ZERO warnings
2. `make test` — ALL pass (or project-equivalent test command)
3. `lsp_diagnostics(filePath="<each changed file>")` — ZERO new errors
4. `codegraph_diff_impact(staged=true)` — regression impact check
5. `graphify update .` — refresh knowledge graph
6. `skill(name="superpowers-verification-before-completion")` — final checklist

**GATE → DO NOT ENTER PHASE 6 UNTIL:**
- [ ] Build: exit 0, zero warnings
- [ ] Tests: all pass
- [ ] Diagnostics: zero new errors on changed files
- [ ] Diff impact: no unexpected caller breakage
- [ ] Graph updated

## PHASE 6: REPORT — Close, archive, clean

**DO:**
1. `skill(name="superpowers-requesting-code-review")`
2. `skill(name="openspec-archive-change")`
3. `skill(name="superpowers-finishing-a-development-branch")`

**GATE → PIPELINE COMPLETE WHEN:**
- [ ] Code review submitted and addressed
- [ ] Change archived to openspec/changes/archive/
- [ ] Branch merged or cleaned
- [ ] Worktree removed

## C RULES

See `references/c-rules.md`. Universal rules always enforced. Embedded-only rules (ISR, DMA, MISRA-checked types, no recursion, watchdog) activate when project has `.ld` linker script OR `-nostdlib` in build flags OR `embedded: true` in `.opencode/config`.

## FULL DETAILS

Each phase expanded with examples → `references/workflow.md`
Tool-specific agent instructions → `references/*-usage.md`
