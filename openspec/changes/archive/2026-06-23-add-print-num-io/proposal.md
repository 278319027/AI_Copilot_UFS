## Why

FEMU BB mode `FEMU_RESET_ACCT = 5` flips `nr_tt_ios` 和 `nr_tt_late_ios` 到 0 并打印 reset 后的值。但 operator 当前**无法在不 reset 的情况下查看当前计数**——要么 reset（破坏数据），要么 attach debugger 读字段。这个 change 新增 `FEMU_PRINT_NUM_IO = 12` flip：仅打印当前 `nr_tt_ios / nr_tt_late_ios`，不修改状态。

## What Changes

- 新增 `FEMU_PRINT_NUM_IO = 12` 到 `bbssd/ftl.h` 的 `FEMU_*` enum（接在 `FEMU_PRINT_BB_CONFIG = 11` 之后）
- 新增 `static void bb_flip_print_num_io(FemuCtrl *n, struct ssd *ssd)` handler 到 `bbssd/bb.c`（per `refactor-bb-flip-table` table-driven pattern）
- 新增 entry 到 `bb_flip_table[]`：`{FEMU_PRINT_NUM_IO, bb_flip_print_num_io, "FEMU_PRINT_NUM_IO"}`
- 不修改 `bb_flip` dispatcher（table-driven 之后添加新 flip 只需 1 table entry）
- Spec delta: 1 ADDED Requirement 到 `openspec/specs/ftl-mapping/spec.md`（`BB Print Num IO Flip`）

## Capabilities

### New Capabilities
- 无

### Modified Capabilities
- `ftl-mapping`: 新增 1 ADDED Requirement（`BB Print Num IO Flip`）— 打印 `nr_tt_ios / nr_tt_late_ios` 不 reset 状态

## Impact

- **Code**: 2 文件 modified
  - `bbssd/ftl.h` enum: +1 line（`FEMU_PRINT_NUM_IO = 12,`）
  - `bbssd/bb.c`: +7 lines（handler function 3 行 + table entry 1 行 + 装饰 3 行）
- **Spec**: 1 ADDED Requirement + 4 Scenarios 到 `openspec/specs/ftl-mapping/spec.md`
- **No new memory rules**, no QOM property, no test framework change
- **No external dependents**（per `refactor-bb-flip-table` 静态分析：`bb_flip_table` 是 `static const`，handler 是 `static`，0 global symbols）
- **Reuses existing `femu_log` helper** 和 `n->nr_tt_ios` / `n->nr_tt_late_ios` 字段

## Non-goals

- **Not** 替换或修改 `FEMU_RESET_ACCT`（companion 关系，互补）
- **Not** 暴露 ACCT stats 到 QOM property（admin flip only）
- **Not** 打印 channel/lun 级别的细分（per-`n` flip，仅全局 ACCT counter）
- **Not** 改 flip 语义（仅新增 flip，不动现有）

## Superpowers iron rules

- **test-coverage** — applies（per M-2: 新增 1 个 enum value 是公共 surface；bug-injection evidence 走"0 public logic"满足，per `refactor-bb-flip-table` precedent）
- **systematic-debugging** — N/A（no bug fix）
- **verification-before-completion** — applies（per M-1: verify-report.md 必填；per M-8: review.md 必填含真实签字）

## CodeGraph queries used in KNOW phase (per M-4)

> **状态** (2026-06-23): codegraph MCP DB 不在 zsf repo（user 删 `.codegraph/`；FEMU 端 DB 仍存在但未 query）。退化为静态分析 + refactor-bb-flip-table 结论。

- `grep "FEMU_PRINT_BB_CONFIG" bbssd/ftl.h` → max enum = 11（line 57），新 value 12 safe
- `grep "FEMU_RESET_ACCT" bbssd/bb.c` → handler 引用 `n->nr_tt_ios` / `n->nr_tt_late_ios`（line 55-56）
- `grep "bb_flip_table" bbssd/bb.c` → 已 table-driven（per `refactor-bb-flip-table` commit caf00dd），新增 entry 即可
- `grep "bb_flip_print_num_io"` → 不存在（确认新 handler name 无冲突）
- **0 external dependents**（per refactor-bb-flip-table 静态分析）
