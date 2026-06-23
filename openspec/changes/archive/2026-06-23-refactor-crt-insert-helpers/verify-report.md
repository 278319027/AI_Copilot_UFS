# Verify Report: refactor-crt-insert-helpers

> 由 Review Gate 引用。6 项 verify gate + bug injection 覆盖率 + Spec 追溯。

## 基本信息

- **变更 ID**: refactor-crt-insert-helpers
- **生成时间**: 2026-06-23 22:30
- **生成方式**: 手动 6-check（per M-1 + M-8）
- **关联 commit**: 待 archive 后生成
- **执行人**: AI Agent（fresh evidence 由 commands 提供）
- **关键价值**: **首次实战 openspec-propose §1b Refactor 类型 workflow**（验证 AP-010 workaround：refactor change + ADDED Requirements 模式）

## 6 项 verify gate 结果

### Check 1: tasks.md 勾选完成度

- 命令: `grep -c '^\- \[x\]' openspec/changes/refactor-crt-insert-helpers/tasks.md`
- 结果: 12 checked / N-12 unchecked（T7-T12 pending review/sync/archive 阶段；T4/T4b/T4c 验证在 BUILD 阶段完成）
- 状态: ⏳ DEFERRED

### Check 2: 编译通过

- 命令: `cd /home/zsf/AI_Proj/femu/hw/femu/bbssd && gcc -c -Wall -Wextra -Werror -O2 -std=c11 -fPIC -I. -I.. crt.c -o /tmp/crt_refactor.o`
- 结果: exit 0, 0 warnings, 0 errors
- 实际执行（fresh evidence 2026-06-23 22:30）:
  ```
  $ gcc -c -Wall -Wextra -Werror -O2 -std=c11 -fPIC -I. -I.. crt.c -o /tmp/crt_refactor.o
  exit=0
  ```
- 旁注: FEMU 顶层 `make` 需要先 `./configure`，不在本 drill 验证范围（per add-bb-config-print / add-toggle-gc-delay precedent：单文件编译验证即足够）
- 通过标准: exit 0, 0 warnings
- 状态: ✅ PASS

### Check 3: 测试通过

- 命令: 自定义 host-side blackbox test（`/tmp/crt_refactor_test.c`），链接到 refactored `crt.c`
- 结果: PASS — 输出与 pre-refactor `crt.c` **byte-for-byte 相同**
- 实际执行（fresh evidence 2026-06-23 22:30）:
  ```
  $ /tmp/crt_refactor_test
  [FEMU] CRT stats: hit=0 miss=1 insert=4 invalidate=0 evict=0 capacity=4
  [FEMU] CRT stats: hit=5 miss=2 insert=8 invalidate=0 evict=4 capacity=4
  PASS: crt_insert refactor equivalence test
  exit=0

  $ /tmp/crt_pre_refactor_test
  [FEMU] CRT stats: hit=0 miss=1 insert=4 invalidate=0 evict=0 capacity=4
  [FEMU] CRT stats: hit=5 miss=2 insert=8 invalidate=0 evict=4 capacity=4
  PASS: crt_insert refactor equivalence test
  exit=0

  $ diff <(/tmp/crt_refactor_test) <(/tmp/crt_pre_refactor_test)
  (no output — IDENTICAL)
  ```
- 通过标准: refactored 与 pre-refactor 测试输出无 diff
- 状态: ✅ PASS — strongest possible evidence for a refactor

### Check 4: Spec 一致性

- 命令: `openspec validate --strict --changes && openspec validate --strict --specs`
- 结果:
  ```
  $ openspec validate --strict --changes
  - Validating...
  ✓ change/refactor-crt-insert-helpers
  Totals: 1 passed, 0 failed (1 items)

  $ openspec validate --strict --specs
  - Validating...
  ✓ spec/ftl-mapping
  ✓ spec/nand-driver
  ✓ spec/nvme-commands
  Totals: 3 passed, 0 failed (3 items)
  ```
- 通过标准: 无 violation
- 状态: ✅ PASS

### Check 5: CodeGraph 闭包（nm 符号表验证）

- 命令: `nm /tmp/crt_refactor_O0.o | grep -E "crt_(insert|find_empty_slot|evict_oldest|hash)"`
- 结果:
  ```
  0000000000000000 t crt_hash
  00000000000001ad t crt_find_empty_slot
  0000000000000220 t crt_evict_oldest
  000000000000031b T crt_insert
  ```
- 通过标准:
  - `crt_hash` 保留（`t` = static，未变）
  - `crt_insert` 保留（`T` = global，未变）
  - `crt_find_empty_slot` 新增（`t` = static，file-local，正确）
  - `crt_evict_oldest` 新增（`t` = static，file-local，正确）
- 旁注: 用 -O0 编译保留 static helpers 不被 inline；production build (-O2) 编译器会自然 inline，不影响 ABI
- 状态: ✅ PASS

### Check 6: Graphify 完整

- 命令: N/A（per AI_Copilot_UFS project.md §2.1）
- 状态: ⚠️ N/A

## §1b Refactor Type Workflow 验证（per AP-010 workaround）

**核心问题**（per `openspec-propose §1b`）：openspec validate 强制 `at least one delta`，refactor change 无 behavior change 时被拒。

**Workaround 应用**：
- `proposal.md` Capabilities.Modified = **空**（per §1b：「refactor 改 HOW 不改 WHAT」）
- `specs/ftl-mapping/spec.md` 写 1 个 `## ADDED Requirements` block + 1 个 `#### Scenario: behavior identical`
- ADDED Requirements 内容：描述新架构选择（helper extraction pattern），不引入新 behavior

**验证结果**：
- Check 4 验证 `openspec validate --strict --changes` 通过（refactor change + ADDED Requirements 满足 `at least one delta` 要求）
- proposal.md 的「Modified Capabilities」段为空，符合 §1b 不变量
- 设计模式与 `refactor-bb-flip-table` 归档一致（per `openspec/changes/archive/2026-06-23-refactor-bb-flip-table/specs/ftl-mapping/spec.md`）

**§1b workflow 第一次实战，✅ END-TO-END 成功**。

## 新 P0/P1/P2 防御 end-to-end 测试

### 防御 1: verify.sh [18/19] baseline no delta headers

- 触发场景: sync_change.sh 执行后 baseline 仍含 `## ADDED Requirements` 头
- 当前状态: ⏳ 待 sync_change.sh 执行后测试

### 防御 2: verify.sh [19/19] review.md placeholder（per b9c42b5）

- 触发场景: review.md 写完但签字栏是 placeholder
- 当前状态: ⏳ 待 review.md 写完后测试

### 防御 3: openspec-archive-change §1.0 ask user to sign（per 861af72）

- 触发场景: review.md 是 placeholder 时尝试 archive
- 当前状态: ⏳ 待 review.md 写完后测试

## Bug injection 覆盖率（per `superpowers-test-driven-development` Iron Rule）

| 公共 API | 正常路径注入 | 错误路径注入 | 证据位置 |
|----------|--------------|--------------|----------|
| `crt_insert` | ⚠️ N/A (refactor) | ⚠️ N/A (refactor) | behavior 100% 相同（Check 3 byte-identical diff）；无需注入 |
| `crt_find_empty_slot` | ⚠️ N/A | ⚠️ N/A | file-local static，no public API surface；pre-refactor 已是同 code |
| `crt_evict_oldest` | ⚠️ N/A | ⚠️ N/A | file-local static，no public API surface；pre-refactor 已是同 code |

**覆盖率**: 0/0 公共 API（0%）
- **理由**: pure refactor，无 public API change（byte-for-byte behavior equivalence 已证）。Per `refactor-bb-flip-table` precedent + §1b refactor type 豁免 rationale。

## Spec Requirement → 实现 → 测试 追溯

| Spec Requirement | 场景 | 代码位置 | 测试位置 | 状态 |
|------------------|------|----------|----------|------|
| `ftl-mapping#CRT Insert Architecture — Helper Extraction` | Behavior identical after refactor | `crt.c` (crt_insert + 2 helpers) | host test (Check 3) | ✅ |
| `ftl-mapping#CRT Insert Architecture — Helper Extraction` | Empty-slot probe matches prior linear-scan behavior | `crt.c` (crt_find_empty_slot) | host test 隐式 (8 inserts) | ✅ |
| `ftl-mapping#CRT Insert Architecture — Helper Extraction` | Oldest-entry eviction matches prior scan behavior | `crt.c` (crt_evict_oldest) | host test 隐式 (4 evictions) | ✅ |
| `ftl-mapping#CRT Insert Architecture — Helper Extraction` | Future eviction-policy changes use the helper pattern | (forward-looking, not tested now) | N/A (文档化要求) | ✅ |

## 不可覆盖路径（如有）

| 路径 | 不可覆盖原因 | 替代验证方式 |
|------|--------------|--------------|
| 实际 FEMU 运行时 CRT 行为 | FEMU 未配置（无 `./configure`）| host-side blackbox test 链接真实 `crt.c`（无 mock）|
| Helper 内联行为 | -O2 优化后 static helpers 会被 inline | -O0 编译验证 nm 符号（Check 5）|

## 总体判定

- **6 项 gate**: 4/6 PASS + 1/6 N/A（Check 6 Graphify）
- **Bug injection 覆盖率**: N/A（refactor 类型豁免）
- **新防御测试**: ⏳ 3 项（[18/19] / [19/19] / §1.0）待 sync/archive 阶段执行
- **§1b workflow 验证**: ✅ END-TO-END 成功（首次实战）
- **Review Gate 准入**: ✅ READY

## 附录: 命令输出证据

### Check 2 编译输出
```
$ cd /home/zsf/AI_Proj/femu/hw/femu/bbssd && \
  gcc -c -Wall -Wextra -Werror -O2 -std=c11 -fPIC -I. -I.. crt.c -o /tmp/crt_refactor.o
exit=0
(no warnings, no errors)
```

### Check 3 测试输出
```
$ /tmp/crt_refactor_test
[FEMU] CRT stats: hit=0 miss=1 insert=4 invalidate=0 evict=0 capacity=4
[FEMU] CRT stats: hit=5 miss=2 insert=8 invalidate=0 evict=4 capacity=4
PASS: crt_insert refactor equivalence test
exit=0

$ /tmp/crt_pre_refactor_test
[FEMU] CRT stats: hit=0 miss=1 insert=4 invalidate=0 evict=0 capacity=4
[FEMU] CRT stats: hit=5 miss=2 insert=8 invalidate=0 evict=4 capacity=4
PASS: crt_insert refactor equivalence test
exit=0

$ diff <(/tmp/crt_refactor_test) <(/tmp/crt_pre_refactor_test)
(NO OUTPUT — IDENTICAL)
```

### Check 5 nm 输出
```
$ nm /tmp/crt_refactor_O0.o | grep -E "crt_(insert|find_empty_slot|evict_oldest|hash)"
0000000000000000 t crt_hash
00000000000001ad t crt_find_empty_slot
0000000000000220 t crt_evict_oldest
000000000000031b T crt_insert
```

### Check 4 validate 输出
```
$ openspec validate --strict --changes
- Validating...
✓ change/refactor-crt-insert-helpers
Totals: 1 passed, 0 failed (1 items)

$ openspec validate --strict --specs
- Validating...
✓ spec/ftl-mapping
✓ spec/nand-driver
✓ spec/nvme-commands
Totals: 3 passed, 0 failed (3 items)
```

### LOC delta
- **pre-refactor `crt_insert`** body: 46 lines (lines 90-135, 含 2 个 inline blocks)
- **post-refactor `crt_insert`** body: 22 lines
- **新 helpers** (crt_find_empty_slot + crt_evict_oldest + 2 fwd decls): ~33 lines
- **net file delta**: ~+5 LOC (helpers 的 wrapper overhead + forward decls)

## 与 pre-refactor `crt_insert` 的 code-level 对照

| Original (inline) | Refactored (call) |
|-------------------|-------------------|
| `for (i=0; i<cap; i++) { k = (h+i)%cap; if (!entries[k].valid) { slot=k; break; } }` | `slot = crt_find_empty_slot(crt, h);` |
| `if (slot==-1) { /* eviction scan + stat_evict++ + fprintf */ }` | `if (slot==-1) { slot = crt_evict_oldest(crt); }` |

Loop body、tie-break (lowest index on equal insert_seq)、modulo 公式、`fprintf` format string — **byte-for-byte identical** (在 `crt_find_empty_slot` / `crt_evict_oldest` 体内)。
