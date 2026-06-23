## Context

Per `add-print-num-io/proposal.md`: 新增 `FEMU_PRINT_NUM_IO = 12` admin flip 一次性查询 ACCT counters（`nr_tt_ios / nr_tt_late_ios`），不 reset 状态。**测试新 P0/P1/P2 防御**：
- `scripts/sync_change.sh` (P0-1) 第一次实战（已有 commit 5c3412f 的 test-sync-e2e e2e）
- `verify.sh [18/19] baseline no delta headers` (P0-1) 自动检测
- `verify.sh [19/19] review.md placeholder` (P2-2a, 升级为 FAIL per b9c42b5) 强制 ask user
- `openspec-archive-change §1.0 ask user` (P2-2b, per 861af72) hard-fail

本次 drill 是**第一次走完整新防御**的演练（前 3 个 drill 用旧 placeholder 已 retroactive 补签；refactor-bb-flip-table 是 P0/P1/P2 升级前做的）。

**Change scope**:
- `bbssd/ftl.h` enum: +1 行（`FEMU_PRINT_NUM_IO = 12,`）
- `bbssd/bb.c` handler: 3 行（`static void bb_flip_print_num_io(...) { femu_log(...); }`）
- `bbssd/bb.c` table entry: 1 行（`{FEMU_PRINT_NUM_IO, bb_flip_print_num_io, "FEMU_PRINT_NUM_IO"},`）
- **total**: 2 文件 +5 行

## Goals / Non-Goals

**Goals:**
- 新增 `FEMU_PRINT_NUM_IO = 12` enum value
- 新增 `bb_flip_print_num_io` handler（不 reset，只打印）
- 新增 table entry（per refactor-bb-flip-table pattern）
- Spec delta: 1 ADDED Requirement (`BB Print Num IO Flip`)
- 测试新 P0/P1/P2 防御 end-to-end

**Non-Goals:** (per proposal)

## Decisions

### D1. Enum value: append after `FEMU_PRINT_BB_CONFIG = 11`

- **Choice**: `FEMU_PRINT_NUM_IO = 12,` 接在 `FEMU_PRINT_BB_CONFIG = 11,` 之后
- **Rationale**: sequential numbering matches existing pattern; max existing = 11
- **Alternative considered**: starting a new group at 100 — rejected, breaks "max value = N" check

### D2. Output format: same as FEMU_RESET_ACCT, swap "Reset" → "Num"

- **Choice**: `femu_log("%s,Num tt_late_ios/tt_ios,%lu/%lu\n", n->devname, n->nr_tt_late_ios, n->nr_tt_ios);`
- **Rationale**: 
  - 同 `FEMU_RESET_ACCT` 格式 (line 57-58 of bb.c)，仅 "Reset" → "Num"
  - operator 可以 grep "tt_late_ios/tt_ios" 找到所有 ACCT 输出
  - `%lu` 格式 + `n->nr_tt_late_ios` / `n->nr_tt_ios` 字段同 FEMU_RESET_ACCT
- **Alternative considered**: JSON output — rejected, overkill for a status query

### D3. Handler signature: 复用 refactor-bb-flip-table pattern

- **Choice**: `static void bb_flip_print_num_io(FemuCtrl *n, struct ssd *ssd)`
- **Rationale**: per refactor-bb-flip-table D2; 11 existing handlers 全用同签名
- **Alternative considered**: 只传 `n` — rejected, 不一致 (且需要 `n->ssd` 转换)

### D4. Table entry: 1 行, 紧跟 FEMU_PRINT_BB_CONFIG

- **Choice**: `{FEMU_PRINT_NUM_IO, bb_flip_print_num_io, "FEMU_PRINT_NUM_IO"},` 追加到 `bb_flip_table[]` 末尾
- **Rationale**: per refactor-bb-flip-table D5, 顺序与 prior drill (add-bb-config-print) 一致
- **Alternative considered**: alphabetical order — rejected, 不必要重构

### D5. No new test framework (per prior trivial change precedent)

- **Choice**: 无单元测试, 手动 QEMU CLI 验证
- **Rationale**: per `add-bb-config-print` design D4 + refactor-bb-flip-table design D5 precedent; 1-call dispatch to femu_log, 无 logic 分支
- **Bug injection target (per M-2)**: enum value 12 是 literal, 无法 inject; handler 是 1-call to femu_log, 无 logic 分支; M-2 100% 满足通过 "0 public logic" 理由

## Risks / Trade-offs

- **R1: enum value collision** → Mitigation: max = 11 (line 57), 12 safe
- **R2: handler prints wrong field** → Mitigation: per `FEMU_RESET_ACCT` 引用 (line 55-56) 同 pattern, build 验证

## design-implementation drift

None expected for this trivial change. If implementation diverges, update this section per `memory/design_rules.md` §8 before commit (per M-6).

## Migration Plan

No migration. New flip is additive; existing behavior unchanged.

## Verification commands (per M-1)

```bash
# 1. tasks.md 勾选
grep -c '^- \[x\]' openspec/changes/add-print-num-io/tasks.md

# 2. compile
cd $FEMU_ROOT/build-femu && make libsystem.a.p/hw_femu_bbssd_bb.c.o

# 3. behavior equivalence (新 flip string present)
strings libsystem.a.p/hw_femu_bbssd_bb.c.o | grep "Num tt_late_ios"
# expect: [FEMU] Log: %s,Num tt_late_ios/tt_ios,%lu/%lu

# 4. spec (1 ADDED Requirement)
openspec validate --strict --changes  # 1/1 PASS
openspec validate --strict --specs    # 3/3 PASS

# 5. CodeGraph 闭包
nm libsystem.a.p/hw_femu_bbssd_bb.c.o | grep "bb_flip_print_num_io"  # t (static)
nm libsystem.a.p/hw_femu_bbssd_bb.c.o | grep "bb_flip_table"  # d (static const)

# 6. graphify
graphify diagnose multigraph
```

## New defense tests (this drill 的额外价值)

```bash
# 防御 1: verify.sh [19/19] 应 FAIL (review.md placeholder)
# 写完 review.md 后 (未签):
bash scripts/verify.sh  # expect: ✗ FAIL unsigned review.md placeholders found

# 防御 2: ask user 签字后
# 修改 review.md 签字栏为真实签字 (ZSF, ...)
bash scripts/verify.sh  # expect: ✓ PASS

# 防御 3: openspec-archive-change §1.0 hard-fail
# review.md 仍是 placeholder 时尝试 archive
bash /opsx:archive add-print-num-io  # expect: exit 1 + chat 提示

# 防御 4: verify.sh [18/19] 自动检测
# sync_change.sh 错误执行 (留 delta 头在 baseline) 时:
grep -cE "^## (ADDED|MODIFIED|REMOVED|RENAMED) Requirements" openspec/specs/ftl-mapping/spec.md
# expect: 0 (clean)
```
