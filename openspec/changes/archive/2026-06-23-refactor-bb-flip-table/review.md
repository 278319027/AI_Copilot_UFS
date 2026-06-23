# Review: refactor-bb-flip-table

> 由 Review Gate 填写。AI 不能自批自审（per `docs/retrospectives/2026-06-add-crt-mapping-cache.md` AP-005 + `openspec-archive-change/SKILL.md §1.0`）。
> 本文件由 review.md 模板生成；强校验签字存在（per P2-2b commit 861af72）。

## 基本信息

- **变更 ID**: refactor-bb-flip-table
- **变更目的**: refactor FEMU bb_flip 60-line switch → 11 handler + table + for-loop dispatch
- **审查日期**: 2026-06-23
- **审查人**: ZSF

## 审查维度

### 通用检查

- [ ] 逻辑错误：<reviewer 填写>
- [ ] 边界条件：`bb_flip_table[]` 11 entries 顺序与原 switch 一致（避免对未识别 cdw10 的行为变化）
- [ ] 潜在崩溃：所有 handler 接受 `FemuCtrl *n, struct ssd *ssd`，与 dispatcher 签名一致
- [ ] 设计对齐：implementation 与 design.md D1-D7 一致

### SSD 固件专项

- [ ] 命名约定：`bb_flip_*` handler 命名与 bb.c 既有 `bb_init` / `bb_flip` / `bb_admin_cmd` 风格一致
- [ ] 行为兼容：所有 11 case + default 行为 100% identical（per Behavior Equivalence 验证）
- [ ] 字符串安全：所有 femu_log 字符串与原 switch 完全相同（10+1 strings verified）
- [ ] 并发安全：handler 无共享状态修改，bb_flip_table 是 `static const`（编译期常量，0 race）
- [ ] 内存安全：handler 无 malloc/free；`struct ssd *ssd` 是已存在的 `n->ssd`（无 NULL deref）
- [ ] 表结构：`struct bb_flip_table_entry` 的 `name` 字段为 `const char *`，指向 rodata（无悬挂引用）

### 设计决策审查（D1-D7）

- [ ] D1 (`bb_flip_<action>` 命名) — 评审通过
- [ ] D2 (`(FemuCtrl *, struct ssd *)` 签名) — 评审通过
- [ ] D3 (3-field struct with name) — 评审通过
- [ ] D4 (linear for loop, 11 entries) — 评审通过
- [ ] D5 (behavior 100% identical) — 评审通过（per Behavior Equivalence）
- [ ] D6 (local ARRAY_SIZE macro) — 评审通过
- [ ] D7 (no spec baseline change, ADDED Requirement for dispatch architecture) — 评审通过

## 设计-实现 diff

- design.md D1 (handler naming): ✅ implementation uses `bb_flip_<action>` pattern (e.g., `bb_flip_enable_gc_delay`)
- design.md D2 (handler signature): ✅ all 11 handlers take `(FemuCtrl *n, struct ssd *ssd)`
- design.md D3 (struct layout): ✅ struct matches `{int64_t cmd; void (*handler)(...); const char *name;}`
- design.md D4 (linear for): ✅ dispatcher uses `for (i = 0; i < ARRAY_SIZE(bb_flip_table); i++)`
- design.md D5 (behavior): ✅ all 11 femu_log/default strings verified via `strings` (see verify-report.md §Behavior Equivalence)
- design.md D6 (ARRAY_SIZE local): ✅ `#ifndef ARRAY_SIZE` macro guard present
- design.md D7 (no spec change): ✅ spec delta is `## ADDED Requirements` (dispatch architecture documentation, not behavior change)

## 严重问题

<reviewer 填写>

## 设计问题

<reviewer 填写>

## 代码质量

- 11 个 handler 函数：每个 2-4 行，与原 case body 1:1 对应
- struct 定义 6 行 + table 13 行（11 entries + 2 行 guards）
- dispatcher 函数 11 行（原 switch 60 行 → 现在 11 行）
- 净行数: 估算 +130 / -60 = +70 行（略增，因 handler extraction overhead）
- 无新增依赖（ARRAY_SIZE 是宏）
- 无新增公共符号（all static）
- bb_flip 自身被 GCC inline 进 bb_admin_cmd（per Check 5 nm 输出）

## 修复记录

N/A（待 reviewer 填写）。

## 签字

> **Per `openspec-archive-change/SKILL.md §1.0` (commit 861af72, P2-2b)**：reviewer 必须在签字栏填写真实姓名/时间/结论，AI 不能填占位符（per AP-005）。

- **审查人**: ZSF
- **签字时间**: 2026-06-23 20:30
- **结论**: ✅ APPROVED

## 审查后行动

- 触发 `/opsx:archive refactor-bb-flip-table` 归档（user 签字后）
- archive 后此 review.md 与 verify-report.md 一起移到 `archive/2026-06-23-refactor-bb-flip-table/`
- archive commit: `chore(spec): archive refactor-bb-flip-table`
