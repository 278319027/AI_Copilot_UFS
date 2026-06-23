## Why

FEMU BB mode 当前用 `FEMU_ENABLE_GC_DELAY = 1` 和 `FEMU_DISABLE_GC_DELAY = 2` 两个**独立** flip 来 set/unset `enable_gc_delay`。这两个命令是**幂等**的（重复 ENABLE 不变 / 重复 DISABLE 不变），但**operator 无法原子地 toggle**（必须先看当前状态，再选对应命令）。这个 change 新增 `FEMU_TOGGLE_GC_DELAY = 13` flip：**单次调用翻转** `enable_gc_delay` 状态（on↔off），独立于现有的 ENABLE/DISABLE 对。

## What Changes

- 新增 `FEMU_TOGGLE_GC_DELAY = 13` 到 `bbssd/ftl.h` 的 `FEMU_*` enum（接在 `FEMU_PRINT_NUM_IO = 12` 之后）
- 新增 `static void bb_flip_toggle_gc_delay(FemuCtrl *n, struct ssd *ssd)` handler 到 `bbssd/bb.c`（per refactor-bb-flip-table table-driven pattern）
  - 实现: `ssd->sp.enable_gc_delay = !ssd->sp.enable_gc_delay;` + 1-line `femu_log` 打印新状态
- 新增 entry 到 `bb_flip_table[]`: `{FEMU_TOGGLE_GC_DELAY, bb_flip_toggle_gc_delay, "FEMU_TOGGLE_GC_DELAY"}`
- 不修改 `bb_flip` dispatcher, 不修改 `FEMU_ENABLE/DISABLE_GC_DELAY` handlers（向后兼容）
- Spec delta: 1 ADDED Requirement 到 `openspec/specs/ftl-mapping/spec.md`（`BB Toggle GC Delay Flip`）

## Capabilities

### New Capabilities
- 无

### Modified Capabilities
- `ftl-mapping`: 新增 1 ADDED Requirement（`BB Toggle GC Delay Flip`）— toggle `enable_gc_delay` 状态

## Impact

- **Code**: 2 文件 modified
  - `bbssd/ftl.h` enum: +1 line（`FEMU_TOGGLE_GC_DELAY = 13,`）
  - `bbssd/bb.c`: +6 lines（handler 4 行 + table entry 1 行 + 装饰 1 行）
- **Spec**: 1 ADDED Requirement + 4 Scenarios 到 `openspec/specs/ftl-mapping/spec.md`
- **No new memory rules**, no QOM property, no test framework change
- **No external dependents**（per refactor-bb-flip-table 静态分析：handler `static`，0 global symbols）
- **Reuses existing pattern**: ENABLE/DISABLE handler 的 `femu_log` 格式 + `ssd->sp.enable_gc_delay` 字段
- **向后兼容**: `FEMU_ENABLE/DISABLE_GC_DELAY`（值 1, 2）**不变**；新 flip 是额外的

## Non-goals

- **Not** 替换或 deprecate `FEMU_ENABLE/DISABLE_GC_DELAY`（保持独立，互不干扰）
- **Not** toggle 多个 flag（如 DELAY_EMU、CCT 开关）— 仅 GC_DELAY
- **Not** 暴露 toggle state 到 QOM property
- **Not** 改其他 ENABLE/DISABLE 对（LOG、CRT、DELAY_EMU）

## Superpowers iron rules

- **test-coverage** — applies（per M-2: 新增 1 enum value 是公共 surface；bug-injection evidence 走"0 public logic"满足，per add-bb-config-print + refactor-bb-flip-table precedent）
- **systematic-debugging** — N/A（no bug fix）
- **verification-before-completion** — applies（per M-1 + M-8）

## CodeGraph queries used in KNOW phase (per M-4)

> **状态** (2026-06-23): codegraph MCP DB 不在 AI_Copilot_UFS repo（user 删 `.codegraph/`；FEMU 端 DB 仍存在但未 query）。退化为静态分析 + refactor-bb-flip-table / add-print-num-io 结论。

- `grep "FEMU_PRINT_NUM_IO" bbssd/ftl.h` → max enum = 12（line 57-58），新 value 13 safe
- `grep "FEMU_ENABLE_GC_DELAY" bbssd/bb.c` → handler 引用 `ssd->sp.enable_gc_delay` (line 33, 37)
- `grep "FEMU_TOGGLE_GC_DELAY" bbssd/` → 不存在（确认新 name 无冲突）
- **0 external dependents**（per refactor-bb-flip-table 静态分析：bb_flip_table 是 `static const` + handlers 是 `static`）
