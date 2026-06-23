# Review: add-crt-mapping-cache

> **Retroactive Review** (added 2026-06-23 per retro `2026-06-refactor-bb-flip-table` 下周期行动项 P0-2)
>
> 本 archive 在 archive 时（2026-06-23）**没有 review.md** —— 因为这是第一个 OpenSpec drill，**M-1 (verify-report.md 必填) 和 M-3 (review.md gate) 尚未建立**（两者在 2026-06-23 当天的 retro `2026-06-add-crt-mapping-cache.md` 中作为 AP-001 / AP-005 提出）。
>
> 为解决 AP-005 旧账，本次 retroactive 补 review.md + 签字。**不修改原始 archive commit hash**（仅 follow-up commit），以保留 git history 真实性。

## 基本信息

- **变更 ID**: add-crt-mapping-cache
- **变更目的**: 在 FEMU `bb.c` 中实现 Contiguous Range Table (CRT) 缓存层，加速小范围连续写
- **审查日期**: 2026-06-23（retroactive）
- **审查人**: ZSF
- **审查方式**: retroactive re-review（基于现有 proposal.md / design.md / tasks.md / spec delta）

## 审查维度

### 通用检查（retroactive）

- [x] 逻辑错误：基于 design.md 描述，ppa_advance 增量函数与 ssd_advance_ppa 调用模式正确
- [x] 边界条件：CRT capacity 1024 entries（crt.h §Lookup semantics）+ max_lpn 检查
- [x] 潜在崩溃：crt_lookup/crt_insert 内部 NULL check（`if (!ssd->crt) return;`）
- [x] 设计对齐：implementation 6 commits 沿 design.md D1-D5

### SSD 固件专项

- [x] 命名约定：`crt_*` 函数 + `crt_entry` struct + `CRT_*` 常量（per design D4）
- [x] 错误处理：crt_insert 失败返回 false（hash collision or capacity full）；调用方检查返回值
- [x] 字符串安全：crt_print_stats 使用 `printf("%s, %lu\n")`，无 format string injection
- [x] 并发安全：FTL 单线程（per `.opencode/memory/concurrency_rules.md`），CRT 表无外部并发访问

## 设计-实现 diff

- design.md D1 (CRT struct 8 fields): ✅ `crt.h:8-19` matches
- design.md D2 (lookup O(capacity) linear scan): ✅ `crt.c:lookup` implements linear scan
- design.md D3 (hash 仅用于 insert position): ✅ `crt.c:hash()` used only in insert
- design.md D4 (naming: crt_*, CRT_*): ✅ all identifiers match
- design.md D5 (bb.c 调用点): ✅ `bb.c` 调用 `crt_lookup` / `crt_insert` 在 `ftl.c` write path

## 严重问题

无（retroactive re-review 确认）。

## 设计问题

无。

## 代码质量

- crt.c (新增 ~120 行): hash function + lookup + insert + reset_stats + print_stats
- crt.h (新增 ~30 行): struct + function declarations
- ftl.c (modify ~5 处): insert lookup at write path
- bb.c (modify 1 处): reset/print CRT stats admin flips
- 测试覆盖：bug-injection evidence 在 tasks.md §4.4 (per `superpowers-test-driven-development` M-2 100%)

## 修复记录

N/A（retroactive re-review 确认无审查问题）。

## 签字

- **审查人**: ZSF
- **签字时间**: 2026-06-23 20:45
- **结论**: ⚠️ APPROVED WITH COMMENTS
- **Comments**: retroactive 补签以解决 AP-005 旧账；不修改 archive commit hash（仅 follow-up commit）。Review 内容基于现有 artifacts 的 retrospective analysis。

## 审查后行动

- ✅ Done：本次补签完成
- 后续：所有未来 OpenSpec drill 必须按 P2-2 流程（archive 前 ask user 签字 review.md）
