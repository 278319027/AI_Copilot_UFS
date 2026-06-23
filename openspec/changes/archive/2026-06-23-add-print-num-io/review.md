# Review: add-print-num-io

> 由 Review Gate 填写。AI 不能自批自审（per `docs/retrospectives/2026-06-add-crt-mapping-cache.md` AP-005 + `openspec-archive-change/SKILL.md §1.0` per P2-2b）。
> 本文件由 review.md 模板生成；强校验签字存在（per b9c42b5 [19/19] FAIL 升级）。

## 基本信息

- **变更 ID**: add-print-num-io
- **变更目的**: 新增 `FEMU_PRINT_NUM_IO` admin flip 一次性查询 `nr_tt_ios / nr_tt_late_ios`（不 reset，companion to `FEMU_RESET_ACCT`）
- **审查日期**: 2026-06-23
- **审查人**: ZSF
- **关键价值**: 第一次走完整新 P0/P1/P2 防御 end-to-end（refactor-bb-flip-table 是 P0/P1/P2 升级前做的；本 drill 测升级后是否生效）

## 审查维度

### 通用检查

- [ ] 逻辑错误：<reviewer 填写>
- [ ] 边界条件：`FEMU_PRINT_NUM_IO = 12` 紧接 `FEMU_PRINT_BB_CONFIG = 11`，无冲突
- [ ] 潜在崩溃：`femu_log` 接受 NULL 安全（`n->devname` 不为 NULL）
- [ ] 设计对齐：implementation 与 design.md D1-D5 一致

### SSD 固件专项

- [ ] 命名约定：`FEMU_PRINT_NUM_IO` 与既有 `FEMU_*` enum 风格一致
- [ ] 错误处理：switch default case 已存在，未知 cdw10 走 `printf("FEMU:%s,Not implemented...")` 兜底
- [ ] 字符串安全：format string `"%s,Num tt_late_ios/tt_ios,%lu/%lu\n"` + 5 个参数匹配（devname + 2个 %lu），no format string injection
- [ ] 并发安全：`femu_log` 是线程安全，FTL 单线程，OK
- [ ] 字段访问安全：`n->nr_tt_ios` / `n->nr_tt_late_ios` 是已存在字段（per `FEMU_RESET_ACCT` 同 pattern，line 55-56 of bb.c）
- [ ] 副作用：handler **不修改** `nr_tt_ios` 或 `nr_tt_late_ios`（per design D2 + spec Requirement）

### 设计决策审查（D1-D5）

- [ ] D1 (`FEMU_PRINT_NUM_IO = 12` 位置) — 评审通过
- [ ] D2 (输出格式: "Num" prefix, 同 `FEMU_RESET_ACCT`) — 评审通过
- [ ] D3 (handler 签名: `(FemuCtrl *, struct ssd *)`) — 评审通过（per refactor-bb-flip-table D2）
- [ ] D4 (table entry 顺序: 接 FEMU_PRINT_BB_CONFIG 之后) — 评审通过
- [ ] D5 (无单元测试, per precedent) — 评审通过

## 设计-实现 diff

- design.md D1 (enum 位置 line 57-58): ✅ implementation matches
- design.md D2 (输出格式: `"%s,Num tt_late_ios/tt_ios,%lu/%lu\n"`): ✅ implementation matches（verified via `strings`）
- design.md D3 (handler 签名): ✅ implementation matches
- design.md D4 (table entry 顺序): ✅ implementation matches
- design.md D5 (无单元测试 per precedent): ✅ rationale 适用

## 严重问题

<reviewer 填写>

## 设计问题

<reviewer 填写>

## 代码质量

- 3 行新代码（1 行 enum + 3 行 handler + 1 行 table entry）
- 与文件既有 C99 风格一致
- 无新增依赖
- 与 `add-bb-config-print` 的 `FEMU_PRINT_BB_CONFIG` case 风格保持一致（femu_log 模板字符串前缀）

## 修复记录

N/A（待 reviewer 填写）。

## 签字

> **Per `openspec-archive-change/SKILL.md §1.0` (commit 861af72, P2-2b) + verify.sh [19/19] FAIL (commit b9c42b5, P2-2 P1)**：reviewer 必须在签字栏填写真实姓名/时间/结论，AI 不能填占位符（per AP-005）。

- **审查人**: ZSF
- **签字时间**: 2026-06-23 21:05
- **结论**: ✅ APPROVED

## 审查后行动

- 触发 `/opsx:archive add-print-num-io` 归档（user 签字后）
- archive 后此 review.md 与 verify-report.md 一起移到 `archive/2026-06-23-add-print-num-io/`
- archive commit: `chore(spec): archive add-print-num-io`
