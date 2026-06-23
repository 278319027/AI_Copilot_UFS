## Context

Per `refactor-bb-flip-table/proposal.md`: refactor FEMU `bb_flip` from a 60-line `switch (cdw10)` with 11 `case` blocks into a **table-driven dispatch** (struct array + for loop). The refactor is structural only — behavior must be 100% identical (same `femu_log` strings, same side effects, same default case). The change exercises the methodology's new P0/P1/P2 defenses:
- `verify.sh [18/19]` baseline no delta headers (won't fire — refactor has no spec change)
- `verify.sh [19/19]` review.md placeholder check (will fire if I forget to ask user to sign)
- `openspec-archive-change/SKILL.md §1.0` ask user to sign flow (HARD constraint; must execute)

KNOW phase confirmed 0 external dependents (per `add-print-version-flip` and `add-bb-config-print` prior drill impact analysis). `bb.c` is a leaf module; refactor is blast-radius-isolated.

## Goals / Non-Goals

**Goals:**
- Replace `switch` in `bb_flip` with table-driven `for` loop dispatch
- Extract each of 11 case bodies into a static function `bb_flip_<action>(FemuCtrl *n, struct ssd *ssd)`
- Build `static const struct bb_flip_table_entry bb_flip_table[]` with `{cmd, handler, name}`
- Behavior 100% identical: same `femu_log` strings, same side effects, same default case
- Pure refactor: no spec change (no ADDED/MODIFIED/REMOVED Requirements)

**Non-Goals:** (per proposal)

## Decisions

### D1. Function naming: `bb_flip_<action>`

- **Choice**: Each handler named `bb_flip_<action>` (e.g., `bb_flip_enable_gc_delay`, `bb_flip_disable_gc_delay`).
- **Rationale**: Consistent with `bb.c` existing pattern (`bb_init`, `bb_flip`, `bb_nvme_rw`, `bb_io_cmd`, `bb_admin_cmd`). The `bb_flip_` prefix makes them greppable as "flip handlers".
- **Alternative considered**: `handler_FEMU_ENABLE_GC_DELAY` (matches enum name) — rejected, less greppable, longer names.
- **Alternative considered**: `flip_enable_gc_delay` (no `bb_` prefix) — rejected, breaks `bb_*` static convention.

### D2. Handler signature: `static void handler(FemuCtrl *n, struct ssd *ssd)`

- **Choice**: Pass `struct ssd *ssd` as second argument (avoids `n->ssd` in every handler).
- **Rationale**: Most handlers (9 of 11) access `ssd->sp.*` or `ssd->crt`; only `FEMU_RESET_ACCT` and `FEMU_ENABLE/DISABLE_LOG` access `n->*` (without `ssd`). Passing both makes handlers uniform.
- **Alternative considered**: `static void handler(FemuCtrl *n)` (only pass `n`) — rejected, requires `struct ssd *ssd = n->ssd;` in every handler (duplication).
- **Alternative considered**: `static void handler(struct ssd *ssd, FemuCtrl *n)` — rejected, `FemuCtrl` is the primary context per existing `bb_flip` signature.

### D3. Table entry struct: 3 fields (cmd, handler, name)

- **Choice**: `struct bb_flip_table_entry { int64_t cmd; void (*handler)(FemuCtrl *, struct ssd *); const char *name; };`
- **Rationale**: 
  - `cmd` for matching against `cdw10`
  - `handler` for the function pointer
  - `name` for debugging (the enum name as a string, used in future error messages; **not** used in this refactor)
- **Alternative considered**: 2-field struct (no `name`) — rejected, loses debuggability for negligible cost (4 bytes/entry).
- **Alternative considered**: Use `FemuFlip` enum instead of `int64_t cmd` — rejected, would require a new enum; existing pattern uses raw `int64_t` (matches `cdw10`).

### D4. Dispatch: linear `for` loop, not sorted/binary

- **Choice**: `for (size_t i = 0; i < ARRAY_SIZE(bb_flip_table); i++)` linear scan.
- **Rationale**: 11 entries; linear is O(11) which is O(1) in practice. Sorted + binary adds complexity for no measurable gain.
- **Alternative considered**: Compile-time hashed dispatch — rejected, overkill for 11 entries.
- **Alternative considered**: Keep `switch` but refactor case bodies to call helpers — rejected, doesn't address the structural problem (still a `switch` in `bb.c`).

### D5. Behavior compatibility: 100% identical

- **Choice**: Every `femu_log` call's exact string + arguments preserved; every side effect order preserved.
- **Rationale**: Refactor must not introduce regressions. Verification: `ninja bb.c.o` + `strings | grep "FEMU,"` must show all 11 distinct strings present.
- **Alternative considered**: Reorder handlers (alphabetical by enum name) — rejected, would change handler order in compiled binary (irrelevant functionally but harder to verify).
- **Alternative considered**: Change `femu_log` calls to use `__func__` (function name) — rejected, changes output strings, breaks "behavior identical".

### D6. `ARRAY_SIZE` macro: define locally if not present

- **Choice**: If `ARRAY_SIZE` not available in headers used by `bb.c`, define locally as `sizeof(x)/sizeof((x)[0])`.
- **Rationale**: Standard idiom, no header dependency.
- **Verification**: Check `bb.c` includes; QEMU tree usually has `ARRAY_SIZE` in `<linux/kernel.h>` (not used in `bb.c`); define locally as fallback.

### D7. No spec change: empty delta file

- **Choice**: `specs/ftl-mapping/spec.md` is empty (0 bytes).
- **Rationale**: Pure refactor — no Requirement changes. Per `openspec-propose/SKILL.md`: "Modified Capabilities: ... Only include if spec-level behavior changes (not just implementation details)."
- **Verification**: `openspec validate --strict --changes` should pass with empty delta.

## Risks / Trade-offs

- **R1: 11 separate functions add some line count** → Mitigation: net change is +~30 lines (handlers + table) vs -60 lines (switch), so total is shorter or comparable.
- **R2: New public surface (`bb_flip_table` is `static const`, not exposed) → Mitigation: 0 external dependents confirmed; `static` keyword prevents symbol leakage.
- **R3: Off-by-one in ARRAY_SIZE** → Mitigation: well-known idiom; build + behavior test catches errors.
- **R4: Function ordering changes binary layout** → Mitigation: irrelevant functionally; verified via `strings` output equivalence.

## design-implementation drift

None expected. If implementation diverges (e.g., different struct layout, different function name pattern), update this section per `memory/design_rules.md` §8 before commit (per M-6).

## Migration Plan

No migration. Refactor is in-place; no ABI change; no API change; existing QEMU instances behavior unchanged.

## Open Questions

None.

## Verification commands (per M-1)

```bash
# 1. tasks.md 勾选
grep -c '^- \[x\]' openspec/changes/refactor-bb-flip-table/tasks.md

# 2. compile
cd /home/zsf/AI_Proj/femu/build-femu && make libsystem.a.p/hw_femu_bbssd_bb.c.o

# 3. behavior equivalence (核心验证)
strings libsystem.a.p/hw_femu_bbssd_bb.c.o | grep "FEMU," > /tmp/before.txt
# 对比：prior drill add-bb-config-print 已记录 12 个 "FEMU," strings（11 case + 1 default）
# refactor 后必须仍是 12 个 strings（无新增/丢失/变更）

# 4. spec (refactor 无 spec change)
openspec validate --strict --changes  # 应该过（空 delta）

# 5. CodeGraph 闭包（per M-4 退化为静态分析）
# Manual: bb_flip_table 应是 static const（无外部依赖）
nm libsystem.a.p/hw_femu_bbssd_bb.c.o | grep -i bb_flip  # expect 0 global symbols

# 6. graphify
graphify diagnose multigraph
```

## Behavior Equivalence Checklist (额外验证)

refactor 后，`femu_log` 调用字符串必须**完全不变**：
- "FEMU GC Delay Emulation [Enabled]!"
- "FEMU GC Delay Emulation [Disabled]!"
- "FEMU Delay Emulation [Enabled]!"
- "FEMU Delay Emulation [Disabled]!"
- "Reset tt_late_ios/tt_ios,%lu/%lu"
- "Log print [Enabled]!"
- "Log print [Disabled]!"
- "CRT stats [Reset]!"
- (no femu_log in `crt_print_stats` — that's crt.c, not bb.c)
- "FEMU BB mode: CRT=%s"
- "FEMU BB config: gc_delay=%s, log=%s, crt=%s, delay_emu=%s"
- (default) "FEMU:%s,Not implemented flip cmd (%lu)"

任何 missing/wrong string = refactor regression → 必须 revert 重做。
