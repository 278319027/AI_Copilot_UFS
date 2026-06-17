# Development Skill (Superpowers Adapter)

This skill is a **thin adapter** for the development workflow. It delegates the generic
engineering discipline to the [Superpowers](../superpowers/SKILL.md) skills framework
and adds the SSD-firmware-specific pre/post steps on top.

## Architecture

```text
   ┌──────────────────────────────┐
   │  SSD domain pre/post steps   │  ← THIS skill adds these
   │  - CodeGraph impact check    │
   │  - OpenSpec proposal gate    │
   │  - specs/ increment vs diff  │
   └─────────────┬────────────────┘
                 │ delegates to
   ┌─────────────▼────────────────┐
   │  Superpowers discipline      │  ← ../superpowers/*/SKILL.md
   │  - brainstorming             │
   │  - writing-plans             │
   │  - executing-plans           │
   │  - subagent-driven-development│
   │  - test-driven-development   │
   │  - verification-before-completion │
   │  - finishing-a-development-branch  │
   └──────────────────────────────┘
```

## 职责

- **Pre-execution (SSD-specific):** query CodeGraph for impact, run the OpenSpec
  Proposal Gate, declare a `proposal.md` and `specs/` increment.
- **Execution (Superpowers):** invoke the Superpowers workflow that matches the work
  type — `subagent-driven-development` for plans with independent tasks,
  `executing-plans` for sequential plans, `brainstorming` for new features, and
  `systematic-debugging` for any bug. Subagents must follow `test-driven-development`
  and `verification-before-completion`.
- **Post-execution (SSD-specific):** produce `design.md`, `tasks.md`, `review.md` (delegated to Superpowers `requesting-code-review`),
  verify that the code change matches the `specs/` increment (ADDED/MODIFIED/REMOVED).

## 输入

- 模块设计文档
- 相关源文件
- 相关规则文件（`.opencode/memory/`）
- 相关调用关系 ← through CodeGraph MCP
- `specs/baseline/` ← 当前行为基线（查询优先级：基线 → CodeGraph → 代码）

## 输出

0. `proposal.md` → 意图、范围、验收标准
1. `specs/` 增量 → `ADDED.md` / `MODIFIED.md` / `REMOVED.md`
2. 需求理解摘要
3. 影响范围分析（CodeGraph 持久化到 `design.md`）
4. `design.md` → 设计方案 + CodeGraph 查询结果 + 待确认清单
5. `tasks.md` → 编码清单（200–500 行/任务，与 Superpowers 粒度兼容）
6. 代码实现（由 `subagent-driven-development` 调度）
7. `review.md` → 查证式 Review + 增量核对表（由 Review Skill 委派到 Superpowers `requesting-code-review` 产出）

## 标准流程

```text
0. 理解需求 → 产出 proposal.md + specs/ 增量（OpenSpec Proposal Gate）
   ↓
1. 查询 CodeGraph ← proposal.md 作为范围参考（callers / callees / impact / find_by_imports）
   ↓
2. 输出设计方案 → design.md（CodeGraph 完整 + 待确认清单）
   ↓
3. Design Gate 确认 → 人工逐项确认 design.md 后进入编码
   ↓
4. 委托 Superpowers 引擎执行 ──────────────────────────────────────────┐
   │ If tasks mostly independent: invoke                              │
   │     .opencode/skills/superpowers/subagent-driven-development/    │
   │ Else if running in parallel session: invoke                     │
   │     .opencode/skills/superpowers/executing-plans/                │
   │ For each task: TDD (test-driven-development) + per-task review   │
   │ Before each completion claim: verification-before-completion     │
   │ All tasks done: finishing-a-development-branch                   │
   ↓                                                                   │
5. 查证式 Review ← 对照 design.md + specs/ 增量 ─────────────────────┘
   ↓
6. 产出 review.md（delegated to Superpowers `requesting-code-review`，含 specs/ 增量核对表）
   ↓
7. 归档 → specs/ 增量合并到 baseline，`chore(spec): archive {change-id}`
```

## CodeGraph 查询步骤（Pre-execution，强制）

| 场景 | MCP 工具 | 补充工具 |
|------|---------|---------|
| 谁调用了函数 X | `codegraph_callers` | cscope -L2 |
| 函数 X 调用了谁 | `get_callees` | cscope -L3 |
| 结构体 X 在哪里使用 | `symbol_search` + `find_by_imports` | cscope -L0 |
| 修改文件 X 的影响 | `impact` | cscope -L2 |
| 模块间依赖 | `get_dependency_graph` | — |
| #include 依赖 | `find_by_imports` | cscope -L8 |
| 搜索符号模式 | `find_by_pattern` | cscope -L6 |

**函数指针和宏的场景必须用 cscope 补充**：

```bash
cscope -d -L2 "func_ptr_name"     # 谁通过函数指针调用了
cscope -d -L3 "func_ptr_name"     # 函数指针指向哪些函数
cscope -d -L4 "MACRO_NAME"        # 宏在哪些地方被使用
cscope -d -L6 "pattern"           # 正则搜索模式
```

## Superpowers invocation contract

When delegating, the dispatch prompt must include:

1. The relevant SSD domain constraints (concurrency, NVMe error handling, FTL
   invariants) so the subagent does not violate them.
2. The `proposal.md` and `specs/` increment so the subagent knows what behaviour
   must be implemented.
3. The CodeGraph impact map so the subagent knows the blast radius.
4. The `tasks.md` slice owned by this subagent.
5. An explicit instruction to follow
   `superpowers:test-driven-development` and
   `superpowers:verification-before-completion` for every claim of completion.

The subagent's report file must contain the test command, the command output, and
the diff. A report without test evidence is not accepted — re-dispatch.

## 修改前必须查询

- 修改任何函数签名前 → `codegraph_callers`
- 修改任何结构体前 → `symbol_search` + `find_by_imports`
- 修改任何头文件前 → `find_by_imports`
- 新增模块前 → `get_dependency_graph`

## 约束

- 一次只处理一个明确任务。
- 不扩大需求。
- 不改不相关逻辑。
- 不引入不必要重构。
- **修改前必须查询 CodeGraph，确认影响范围。**
- **所有 OpenSpec 工件纳入 Git 版本管理。**
- **No completion claim without a fresh test run** (Superpowers
  `verification-before-completion` is mandatory before reporting a task done).
- **No production code without a failing test first** (Superpowers
  `test-driven-development` is mandatory for every task).
