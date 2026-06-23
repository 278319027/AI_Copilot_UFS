# Review: add-toggle-gc-delay

> 由 Review Gate 填写。AI 不能自批自审（per `docs/retrospectives/2026-06-add-crt-mapping-cache.md` AP-005 + `openspec-archive-change/SKILL.md §1.0` per P2-2b）。
> 本文件由 review.md 模板生成；强校验签字存在（per b9c42b5 [19/19] FAIL 升级）。

## 基本信息

- **变更 ID**: add-toggle-gc-delay
- **变更目的**: 新增 `FEMU_TOGGLE_GC_DELAY` admin flip 一次性翻转 `enable_gc_delay`（on↔off，companion to 现有 ENABLE/DISABLE pair）
- **审查日期**: 2026-06-23
- **审查人**: <用户填写 — 不能是 AI 自身>
- **关键价值**: **第 3 次走完整新 P0/P1/P2 防御 end-to-end**（验证 methodology 一致性）

## 审查维度

### 通用检查

- [ ] 逻辑错误：<reviewer 填写>
- [ ] 边界条件：`FEMU_TOGGLE_GC_DELAY = 13` 紧接 `FEMU_PRINT_NUM_IO = 12`，无冲突
- [ ] 潜在崩溃：`femu_log` 接受 NULL 安全（`n->devname` 不为 NULL）
- [ ] 设计对齐：implementation 与 design.md D1-D6 一致

### SSD 固件专项

- [ ] 命名约定：`FEMU_TOGGLE_GC_DELAY` 与既有 `FEMU_*` enum 风格一致
- [ ] 错误处理：switch default case 已存在，未知 cdw10 走 `printf("FEMU:%s,Not implemented...")` 兜底
- [ ] 字符串安全：format string `"%s,FEMU GC Delay Emulation [%s]!\n"` + 2 个参数匹配（devname + ternary），no format string injection
- [ ] 并发安全：`femu_log` 是线程安全，FTL 单线程（per `memory/concurrency_rules.md`），`!` 操作无 race
- [ ] 字段访问安全：`ssd->sp.enable_gc_delay` 是已存在字段（per `FEMU_ENABLE/DISABLE_GC_DELAY` handlers，line 33, 37 of bb.c）
- [ ] 副作用：handler 翻转 `enable_gc_delay`（per design D2 + spec Requirement）— 注意**与现有 ENABLE/DISABLE 共享同一字段**，operator 可任意组合

### 设计决策审查（D1-D6）

- [ ] D1 (`FEMU_TOGGLE_GC_DELAY = 13` 位置) — 评审通过
- [ ] D2 (toggle 实现: `!` operator) — 评审通过
- [ ] D3 (输出格式: 同 ENABLE/DISABLE prefix) — 评审通过
- [ ] D4 (handler 签名: `(FemuCtrl *, struct ssd *)`) — 评审通过
- [ ] D5 (table entry 顺序: 接 FEMU_PRINT_NUM_IO 之后) — 评审通过
- [ ] D6 (无单元测试 per precedent) — 评审通过

## 设计-实现 diff

- design.md D1 (enum 位置 line 58-59): ✅ implementation matches
- design.md D2 (toggle 实现: `!`): ✅ implementation matches
- design.md D3 (输出格式: `"%s,FEMU GC Delay Emulation [%s]!\n"`): ✅ implementation matches（verified via `strings` 第 3 个匹配）
- design.md D4 (handler 签名): ✅ implementation matches
- design.md D5 (table entry 顺序): ✅ implementation matches
- design.md D6 (无单元测试 per precedent): ✅ rationale 适用

## 严重问题

<reviewer 填写>

## 设计问题

<reviewer 填写>

## 代码质量

- 6 行新代码（1 行 enum + 5 行 handler + 1 行 table entry = 实际 7 行含装饰）
- 与文件既有 C99 风格一致
- 无新增依赖
- 与 `add-bb-config-print` / `add-print-num-io` 的 `FEMU_PRINT_*` case 风格保持一致
- toggle 语义清晰：`!` operator + ternary 输出（与现有 ENABLE/DISABLE 的 if-else 等效，但更紧凑）

## 修复记录

N/A（待 reviewer 填写）。

## 签字

> **Per `openspec-archive-change/SKILL.md §1.0` (commit 861af72, P2-2b) + verify.sh [19/19] FAIL (commit b9c42b5, P2-2 P1)**：reviewer 必须在签字栏填写真实姓名/时间/结论，AI 不能填占位符（per AP-005）。

- **审查人**: ZSF
- **签字时间**: 2026-06-23 21:20
- **结论**: ✅ APPROVED

## 审查后行动

- 触发 `/opsx:archive add-toggle-gc-delay` 归档（user 签字后）
- archive 后此 review.md 与 verify-report.md 一起移到 `archive/2026-06-23-add-toggle-gc-delay/`
- archive commit: `chore(spec): archive add-toggle-gc-delay`
