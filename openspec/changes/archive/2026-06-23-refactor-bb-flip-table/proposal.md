## Why

FEMU `bb_flip` function (`bbssd/bb.c:26-85`) currently uses a 60-line `switch` statement with 11 `case` branches (10 from prior + 1 from `add-bb-config-print`). Each new admin flip requires adding a new `case` block in the middle of the function, which is error-prone (missing `break;`, indentation drift, ordering inconsistency) and difficult to grep/audit. This change refactors the dispatch to a **table-driven** pattern: each handler becomes a static function, registered in a single `bb_flip_table[]` array, dispatched by a `for` loop. Behavior is **100% identical** to the switch — this is a pure refactor with no spec change.

## What Changes

- Extract each of the 11 `case` bodies into a static function `bb_flip_<action>(FemuCtrl *n, struct ssd *ssd)`.
- Build a `bb_flip_table[]` array of `{int64_t cmd; void (*handler)(...); const char *name;}` entries.
- Replace the `switch` in `bb_flip` with a `for` loop over `bb_flip_table[]`, calling the matching handler.
- Default case ("Not implemented flip cmd") preserved as fallback after the loop.
- No new public API; no new spec Requirement; no public symbols added (`bb_flip_table` is `static const`).

## Capabilities

### New Capabilities
- 无

### Modified Capabilities
- 无（**纯 refactor**：行为 100% identical，spec Requirements 不变；per `openspec-propose/SKILL.md` "Modified Capabilities" 仅在 REQUIREMENTS 变化时列出）

> **注意**：本次为 refactor，spec delta 文件 `specs/ftl-mapping/spec.md` 仅含 0 字节（empty placeholder）以保持 OpenSpec 框架 compliance。

## Impact

- **Code**: 1 file modified (`bbssd/bb.c`). ~+50/-60 lines (extracted handlers add lines, switch removal saves).
- **Spec**: 0 Requirement changes. `specs/ftl-mapping/spec.md` delta is empty.
- **No new memory rules**; no new QOM property; no test framework change.
- **No external dependencies** (uses only existing `ARRAY_SIZE` macro from `<linux/kernel.h>` or local).
- **Risk**: low — pure refactor, behavior must be 100% identical. Validation: `ninja bb.c.o` + `strings` confirms all 11 `femu_log` strings preserved.

## Non-goals

- **Not** changing flip semantics (e.g., adding ENABLE/DISABLE auto-toggle, or moving handlers to other files).
- **Not** adding new flips (this is structural only; new flips go in separate `add-*` changes).
- **Not** changing the `cdw10` parsing (still `le64_to_cpu(cmd->cdw10)`).
- **Not** generalizing to support runtime-registered flips (handlers are compile-time `static const`).

## Superpowers iron rules

- **test-coverage** — N/A (no new public API; M-2 100% coverage 通过 "0 public surface" 满足，per `add-bb-config-print` precedent)
- **systematic-debugging** — N/A (no bug fix)
- **verification-before-completion** — applies (per M-1: `verify-report.md` 必填；ninja build + `strings` 比对 11 `femu_log` 字符串是核心验证)

## CodeGraph queries used in KNOW phase (per M-4)

> **状态** (2026-06-23): codegraph MCP DB 不在 AI_Copilot_UFS repo（user 删除了 `.codegraph/`；FEMU 端 `.codegraph/` 仍存在但未 query）。退化为静态分析 + prior drill 结论。

- `grep "bb_flip"` in `bbssd/bb.c` → confirmed 11-case switch in `bb_flip` function (line 26)
- `grep "^static.*\(" in bb.c` → 6 static functions: `bb_init_ctrl_str`, `bb_init`, `bb_flip`, `bb_nvme_rw`, `bb_io_cmd`, `bb_admin_cmd`
- `grep "bb_flip" -r bbssd/` → 1 caller: `bb_admin_cmd` at bb.c:108
- **0 external dependents**（per `add-print-version-flip` 与 `add-bb-config-print` 的 prior drill impact 分析结论）→ safe to refactor
