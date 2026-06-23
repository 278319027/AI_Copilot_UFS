## Context

Per `add-toggle-gc-delay/proposal.md`: 新增 `FEMU_TOGGLE_GC_DELAY = 13` admin flip 一次性翻转 `enable_gc_delay`（on↔off），不修改现有的 `FEMU_ENABLE/DISABLE_GC_DELAY = 1, 2` 对。

**Change scope** (与 add-print-num-io 类似 B-style small feature):
- `bbssd/ftl.h` enum: +1 行（`FEMU_TOGGLE_GC_DELAY = 13,`）
- `bbssd/bb.c` handler: 4 行（`bb_flip_toggle_gc_delay` + toggle + femu_log + ternary）
- `bbssd/bb.c` table entry: 1 行
- **total**: 2 文件 +6 行

**新增 vs 现有 flip 的关系**:
- `FEMU_ENABLE_GC_DELAY = 1` (idempotent set to true)
- `FEMU_DISABLE_GC_DELAY = 2` (idempotent set to false)
- `FEMU_TOGGLE_GC_DELAY = 13` (atomic flip, new)
- 3 个 flip 互不冲突；可任意组合使用

## Goals / Non-Goals

**Goals:**
- 新增 `FEMU_TOGGLE_GC_DELAY = 13` enum value
- 新增 `bb_flip_toggle_gc_delay` handler（翻转 `enable_gc_delay` + 打印新状态）
- 新增 table entry（per refactor-bb-flip-table pattern）
- Spec delta: 1 ADDED Requirement (`BB Toggle GC Delay Flip`)
- **测试**: 与 add-print-num-io 类似，但语义不同（toggle vs set）

**Non-Goals:** (per proposal)

## Decisions

### D1. Enum value: append after `FEMU_PRINT_NUM_IO = 12`

- **Choice**: `FEMU_TOGGLE_GC_DELAY = 13,` 接在 `FEMU_PRINT_NUM_IO = 12,` 之后
- **Rationale**: sequential numbering matches existing pattern; max existing = 12
- **Alternative considered**: 在 1 和 2 之间插 — rejected, 会打乱现有 enum 顺序

### D2. Toggle 实现: `ssd->sp.enable_gc_delay = !ssd->sp.enable_gc_delay;`

- **Choice**: 用 `!` 翻转 bool 字段
- **Rationale**: 
  - C 标准（任何 C99 都支持 `!` on bool）
  - 单行、无 race（FTL 单线程 per `memory/concurrency_rules.md`）
  - 与现有 ENABLE/DISABLE handler 的 `true`/`false` 赋值互不干扰
- **Alternative considered**: XOR — rejected, 与 ENABLE/DISABLE 风格不一致

### D3. Output format: "FEMU GC Delay Emulation [Enabled/Disabled]!"

- **Choice**: `femu_log("%s,FEMU GC Delay Emulation [%s]!\n", n->devname, ssd->sp.enable_gc_delay ? "Enabled" : "Disabled");`
- **Rationale**: 
  - 复用现有 ENABLE/DISABLE handler 的 prefix 格式（`"FEMU GC Delay Emulation [...]!"`）
  - 与 ENABLE 唯一区别是 "Enabled"/"Disabled" 状态字（operator 一致性）
  - 单行输出（per add-bb-config-print D2 + add-print-num-io D2 precedent）
- **Alternative considered**: JSON output — rejected, overkill
- **Alternative considered**: 改用 "Toggled to Enabled" — rejected, 输出太长

### D4. Handler signature: 复用 refactor-bb-flip-table pattern

- **Choice**: `static void bb_flip_toggle_gc_delay(FemuCtrl *n, struct ssd *ssd)`
- **Rationale**: per refactor-bb-flip-table D2; 12 existing handlers 全用同签名
- **Alternative considered**: 只传 `n` — rejected, 不一致

### D5. Table entry: 1 行, 紧跟 FEMU_PRINT_NUM_IO

- **Choice**: `{FEMU_TOGGLE_GC_DELAY, bb_flip_toggle_gc_delay, "FEMU_TOGGLE_GC_DELAY"},` 追加到 `bb_flip_table[]` 末尾
- **Rationale**: per refactor-bb-flip-table D5 + add-print-num-io D4
- **Alternative considered**: 在 ENABLE/DISABLE pair 之间插 — rejected, 打乱现有顺序

### D6. No new test framework (per prior trivial change precedent)

- **Choice**: 无单元测试, 手动 QEMU CLI 验证
- **Rationale**: per add-bb-config-print design D4 + add-print-num-io design D5 + refactor-bb-flip-table design D5 precedent
- **Bug injection target (per M-2)**: enum value 13 是 literal, 无法 inject; handler 是 `!` + 1-call to femu_log, 无 logic 分支可注入; M-2 100% 满足通过 "0 public logic" 理由

## Risks / Trade-offs

- **R1: enum value collision** → Mitigation: max = 12 (per add-print-num-io commit b6cb843), 13 safe
- **R2: `!` operator 行为** → Mitigation: C99 标准; bool 字段 `!false = true`, `!true = false`; 无 edge case
- **R3: 与 ENABLE/DISABLE 状态不一致** → Mitigation: 三者共用同一字段 `ssd->sp.enable_gc_delay`; 任何 flip 都会反映最新状态

## design-implementation drift

None expected. If implementation diverges, update this section per `memory/design_rules.md` §8 before commit (per M-6).

## Migration Plan

No migration. New flip is additive; existing ENABLE/DISABLE behavior unchanged.

## Verification commands (per M-1)

```bash
# 1. tasks.md 勾选
grep -c '^- \[x\]' openspec/changes/add-toggle-gc-delay/tasks.md

# 2. compile
cd $FEMU_ROOT/build-femu && make libsystem.a.p/hw_femu_bbssd_bb.c.o

# 3. behavior equivalence (新 flip string present)
strings libsystem.a.p/hw_femu_bbssd_bb.c.o | grep "FEMU GC Delay Emulation"
# expect: 已有 2 strings (Enabled/Disabled) + 1 新 (动态 ternary 输出)

# 4. spec
openspec validate --strict --changes  # 1/1 PASS
openspec validate --strict --specs    # 3/3 PASS

# 5. CodeGraph 闭包
nm libsystem.a.p/hw_femu_bbssd_bb.c.o | grep "bb_flip_toggle_gc_delay"  # t (static)
nm libsystem.a.p/hw_femu_bbssd_bb.c.o | grep "bb_flip_table "  # d (static const)

# 6. graphify
graphify diagnose multigraph
```

## New defense tests (3rd time, 验证一致性)

```bash
# 防御 1: verify.sh [19/19] 应 FAIL (review.md placeholder, per b9c42b5)
bash scripts/verify.sh  # expect: ✗ FAIL unsigned review.md placeholders found

# 防御 2: 签字后 [19/19] PASS
# 改 review.md 签字栏为真实签字
bash scripts/verify.sh  # expect: ✓ PASS

# 防御 3: sync_change.sh + [18/19]
bash scripts/sync_change.sh add-toggle-gc-delay
bash scripts/verify.sh  # expect: ✓ PASS baseline no delta headers
```
