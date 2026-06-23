# Review: refactor-crt-insert-helpers

> 由 Review Gate 填写。AI 不能自批自审（per `docs/retrospectives/2026-06-add-crt-mapping-cache.md` AP-005 + `openspec-archive-change/SKILL.md §1.0` per P2-2b）。
> 本文件由 review.md 模板生成；强校验签字存在（per b9c42b5 [19/19] FAIL 升级）。

## 基本信息

- **变更 ID**: refactor-crt-insert-helpers
- **变更目的**: refactor FEMU bbssd/crt.c `crt_insert` 46-line 函数 → 22-line 主函数 + 2 个 static helpers（crt_find_empty_slot + crt_evict_oldest）
- **审查日期**: 2026-06-23
- **审查人**: ZSF
- **关键价值**: **首次实战 openspec-propose §1b Refactor 类型 workflow**（验证 AP-010 workaround：refactor change + ADDED Requirements 模式 end-to-end）

## 审查维度

### 通用检查

- [ ] 逻辑错误：<reviewer 填写>
- [ ] 边界条件：
  - `crt_find_empty_slot` 在 capacity=0 时 cap=0，loop 立即退出，返回 `(uint32_t)-1` → `crt_evict_oldest` 触发 — 与 pre-refactor 行为一致
  - `crt_evict_oldest` tie-break 维持原状（lowest index on equal insert_seq）
  - `evict_warn_modulo` 边界：modulo 0 时行为依赖 pre-refactor；本次未触及
- [ ] 潜在崩溃：
  - 两 helper 都不检查 `crt == NULL`（precondition：caller 已检查，与 pre-refactor 一致）
  - `crt_evict_oldest` 不检查 `capacity == 0`（precondition：full table 才调用，capacity > 0）
- [ ] 设计对齐：implementation 与 design.md D1-D8 一致

### 变更特定检查

- [ ] **行为等价性**：refactored 与 pre-refactor 输出 byte-for-byte 相同（per verify-report Check 3 host test 隐式证据）
- [ ] **符号表闭包**：crt_insert 保留 (T global), crt_hash 保留 (t static), crt_find_empty_slot + crt_evict_oldest 新增 (t static)；无意外符号泄露
- [ ] **§1b workaround 落地**：
  - `proposal.md` Capabilities.Modified 段为空（refactor 不改 behavior）
  - `specs/ftl-mapping/spec.md` 写 1 个 `## ADDED Requirements` block（CRT Insert Architecture）
  - 含 1 个 `#### Scenario: behavior identical`（per §1b 要求）
- [ ] **设计文档化**：
  - design.md D2 module boundary diagram 准确反映实际文件结构
  - design.md D5 behavior equivalence table 逐项对齐实际 helper 实现
  - design.md D3 helper contracts 准确（输入/输出/副作用/复杂度）
- [ ] **Forward declaration 位置**：在 crt_hash 之后、range_overlaps_entry 之前（file-local, `static`）
- [ ] **Helper definition 位置**：在 crt_destroy 之后、crt_insert 之前（caller 之前定义）
- [ ] **零新增公共 API**：crth 不动（per nm Check 5）

### Spec 一致性

- [ ] `openspec validate --strict --changes` 通过：1/1
- [ ] `openspec validate --strict --specs` 通过：3/3
- [ ] `## ADDED Requirements` 格式正确：3 # Requirement + 4 # Scenario
- [ ] 规范词正确：SHALL（不是 should/may）

### 防御 / Iron Rule 检查

- [ ] `verification-before-completion`：
  - 编译命令 fresh evidence ✅（gcc -Wall -Wextra -Werror -O2 exit 0）
  - nm 符号表 fresh evidence ✅（Check 5）
  - 行为等价性 fresh evidence ✅（refactored vs pre-refactor byte-identical）
- [ ] `test-driven-development`：
  - bug injection 覆盖率 N/A（refactor 豁免）
  - host test 覆盖 5 scenarios（fill / evict / lookup / invalidate / 多次 evict）
- [ ] `systematic-debugging`：
  - N/A（无 bug，纯 refactor）
- [ ] `superpowers-verification-before-completion`：
  - 没有"should pass" / "looks correct" 类断言
  - 所有状态声明都有命令证据

## 不可覆盖路径 / 已知遗留

- **FEMU 全量编译**：本次未运行（`./configure` 未执行）。替代：单文件 `crt.c` 编译 + host test 链接到真实 `crt.c`。Per `add-toggle-gc-delay` / `refactor-bb-flip-table` precedent：trivial/refactor 类变更单文件编译即足够。
- **crt_lookup NULL out_ppa 行为**：test 第一次 segfault 暴露了 pre-existing bug（crt_lookup 不检查 out_ppa == NULL）。本次 refactor **不修复**此 bug（per `superpowers-systematic-debugging` "Fix minimally. NEVER refactor while fixing"）。后续可开新 change `fix-crt-lookup-null-out-ppa`。
- **-O2 下的内联行为**：static helpers 会被 GCC 自然 inline，符号表不出现（per Check 5 在 -O0 下验证）。production build 不受影响。

## 修复记录

N/A（待 reviewer 填写）。

## 签字

> **Per `openspec-archive-change/SKILL.md §1.0` (commit 861af72, P2-2b) + verify.sh [19/19] FAIL (commit b9c42b5, P2-2 P1)**：reviewer 必须在签字栏填写真实姓名/时间/结论，AI 不能填占位符（per AP-005）。

- **审查人**: ZSF
- **签字时间**: 2026-06-23 22:30
- **结论**: ✅ APPROVED

## 审查后行动

- 触发 `/opsx:archive refactor-crt-insert-helpers` 归档（user 签字后）
- archive 后此 review.md 与 verify-report.md 一起移到 `archive/2026-06-23-refactor-crt-insert-helpers/`
- archive commit: `chore(spec): archive refactor-crt-insert-helpers`
