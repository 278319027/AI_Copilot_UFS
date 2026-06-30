# Workflow Reference — Detailed Execution Guide

## Pre-Phase: Prerequisite Check

```
□ openspec --version                    → version printed
□ ls .codegraph/graph.db                → file exists
□ ls graphify-out/graph.json            → file exists
□ skill(name="superpowers-using-superpowers") → succeeds
```

ALL must pass. ANY failure → STOP. Report: "Missing <tool>. Run <fix-command>."

---

## Phase 1: SCOPE — Full Instructions

### 1.1 Clarify Intent
If user's request is vague ("improve performance", "fix the crash"):

```
skill(name="superpowers-brainstorming")
```

Must output: concrete scope boundaries, what's IN vs OUT, constraints, acceptance criteria.

### 1.2 Create OpenSpec Change
```
skill(name="openspec-propose")   # one-shot: proposal + design + tasks
```
OR
```
skill(name="openspec-explore")   # explore first, then create
```

### 1.3 Extract Scope
```bash
openspec instructions proposal --change <name> --json
```

Parse JSON fields:
- `artifactPaths.proposal.resolvedOutputPath` → where to write scope
- `context` → project constraints (do NOT write to file)
- `rules` → artifact-specific rules (do NOT write to file)

### 1.4 Freeze Scope
Write to `proposal.md`:
```markdown
## Scope
### In Scope
- file paths, function names, exact changes

### Out of Scope  
- explicitly excluded items

### Constraints
- memory, performance, compatibility limits

### Acceptance Criteria
- [ ] measurable pass/fail conditions
- [ ] each criterion tied to a test plan item
```

### Gate Check
- [ ] ALL four sections (In/Out/Constraints/Criteria) filled
- [ ] User replied "approved" / "ok" / "proceed" — not silence
- [ ] Scope does NOT contain "might also", "consider", "optionally"

---

## Phase 2: GROUND — Full Instructions

### Graph-First Principle
Graphs are pre-computed maps. Source code is raw terrain. Map first, terrain second.

### 2.1 Macro: Graphify Query
```bash
graphify query "<natural language description of the change>" --budget 1500
```
Parse output for: related files, concept nodes, community clusters.

### 2.2 Macro: Graphify Path
```bash
# For each key relationship identified in scope
graphify path "<concept A>" "<concept B>"
```
Use to trace existing data/control flow paths. Find insertion points.

### 2.3 Macro: Graphify Explain
```bash
graphify explain "<key concept or filename>"
```
Deep-dive on a concept. If concept not found, try synonyms or broader terms.

### 2.4 Micro: CodeGraph Context
```python
# For EACH function in scope.files
codegraph_context(name="<function_name>")
```
Returns: source code, callers list, callees list, header dependencies.

### 2.5 Micro: CodeGraph Impact
```python
# For EACH function in scope
codegraph_fn_impact(name="<function_name>", depth=3)
```
Returns: transitive callers. If more callers than expected → scope may be too narrow.

### 2.6 Safety: CodeGraph Cycles
```python
codegraph_find_cycles()
```
Returns: circular dependency chains. Any cycle involving scoped files → STOP.

### 2.7 Safety: CodeGraph Complexity
```python
codegraph_complexity(above_threshold=true)
```
Returns: functions exceeding complexity thresholds. If scoped functions are already complex → consider splitting in design.

### 2.8 Safety: Semantic Search
```python
codegraph_semantic_search("<domain concept>")
```
Find existing patterns, avoid reinventing wheels.

### Gate Check
- [ ] Graph evidence file list matches or encompasses scope.files
- [ ] If graph shows additional affected files NOT in scope → user must update scope OR explain why excluded
- [ ] No cycles touching scoped modules
- [ ] Complexity hotspots noted in design constraints

---

## Phase 3: PLAN — Full Instructions

### 3.1 design.md
Document:
- Data structures (with field explanations)
- Algorithm steps (numbered, clear)
- Interface changes (new/modified function signatures)
- ISR/hot path impact (if embedded)
- Error handling strategy

### 3.2 tasks.md
Each task format:
```markdown
- [ ] Task N: modify <file> — <what changes>
  - Verification: <exact command to run>
  - Depends on: <task N-1 or "none">
```

### 3.3 Header Impact
```python
codegraph_file_deps(file="<path/to/header.h>")
```
Must run for every new or modified public header.

### 3.4 Memory Budget (if embedded)
Estimate per allocation: stack, heap, static. Compare against available budget from `config.h` or `docs/`.

### 3.5 Pre-Flight
```python
codegraph_diff_impact(staged=true)
```
Ensure working tree is clean before starting. If staged changes exist → address first.

### 3.6 Plan Review
```
skill(name="superpowers-writing-plans")
```

### Gate Check
- [ ] design.md and tasks.md exist in OpenSpec change directory
- [ ] Every task has a verification command
- [ ] Task dependency chain is valid (no cycles)
- [ ] Memory budget within limits (if embedded)
- [ ] User approved design (explicit confirmation)

---

## Phase 4: PATCH — Full Instructions

### 4.1 Workspace Isolation
```
skill(name="superpowers-using-git-worktrees")
```
All changes in isolated worktree. Master/main untouched.

### 4.2 TDD Loop (per task)
```
For each task in tasks.md:
  RED:     Write test → compile → run → MUST FAIL
  GREEN:   Write minimal implementation → compile → run → MUST PASS
  CI:      codegraph_check(staged=true) → MUST PASS
  REFACTOR: Improve code structure → tests MUST STILL PASS
  COMMIT:  git add <changed files> && git commit -m "task N: <description>"
```

### 4.3 Scope Check
```python
codegraph_diff_impact(staged=true)
```
Verify: changed files ⊆ scope.files. If violation → `git reset --hard HEAD` and re-scope.

### Gate Check
- [ ] All tasks marked done in tasks.md
- [ ] Each task committed separately
- [ ] codegraph_check passes for cumulative diff
- [ ] Diff strictly within scope.files

---

## Phase 5: VERIFY — Full Instructions

### 5.1 Build
```bash
make clean && make
```
Exit code 0. ZERO warnings. Warnings count as failure.

### 5.2 Tests
```bash
make test        # or make test-all, or project-equivalent
```
ALL test targets must pass.

### 5.3 Diagnostics
```python
lsp_diagnostics(filePath="<each changed file>")
```
ZERO new errors. Pre-existing errors: note but do not block (unless you introduced them).

### 5.4 Regression
```python
codegraph_diff_impact(staged=true)
```
Compare against pre-patch impact. No new unexpected callers affected.

### 5.5 Refresh Graph
```bash
graphify update .
```

### 5.6 Final Verification
```
skill(name="superpowers-verification-before-completion")
```

### Gate Check
- [ ] Build: exit 0, zero warnings
- [ ] Tests: all pass
- [ ] Diagnostics: zero new errors
- [ ] Regression: no unexpected impact expansion
- [ ] Graph updated

---

## Phase 6: REPORT — Full Instructions

### 6.1 Code Review
```
skill(name="superpowers-requesting-code-review")
```

### 6.2 Archive
```
skill(name="openspec-archive-change")
```

### 6.3 Cleanup
```
skill(name="superpowers-finishing-a-development-branch")
```

---

## Quick Checklist (one-page summary)

```
□ PREREQ: openspec, codegraph, graphify, superpowers → all present
□ PHASE 1: scope frozen, user approved
□ PHASE 2: graphify query+path+explain done, codegraph context+impact+cycles done
□ PHASE 3: design.md + tasks.md written, header impact checked, plan reviewed
□ PHASE 4: worktree created, each task TDD'd, CI gate passed, diff within scope
□ PHASE 5: build clean, tests pass, diagnostics clean, graph updated
□ PHASE 6: code reviewed, change archived, branch cleaned
```
