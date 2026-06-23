# Review: add-bb-config-print

> 由 Review Gate 填写。AI 不能自批自审（per `docs/retrospectives/2026-06-add-crt-mapping-cache.md` AP-005）。
> 本文件由 review.md 模板生成；`openspec-archive-change/SKILL.md` 步骤 1 强校验其存在与签字。

## 基本信息

- **变更 ID**: add-bb-config-print
- **变更目的**: 新增 `FEMU_PRINT_BB_CONFIG` admin flip 一次性查询 BB mode 全部 4 个 feature flag
- **审查日期**: 2026-06-23
- **审查人**: 用户（人工 review）

## 审查维度

### 通用检查

- [ ] 逻辑错误：<reviewer 填写>
- [ ] 边界条件：`FEMU_PRINT_BB_CONFIG = 11` 紧接 `FEMU_LOG_VERSION = 10`，无冲突
- [ ] 潜在崩溃：`femu_log` 接受 NULL 安全（`n->devname` 不为 NULL）
- [ ] 设计对齐：implementation 与 design.md D1/D2/D3/D4 一致

### SSD 固件专项

- [ ] 命名约定：`FEMU_PRINT_BB_CONFIG` 与现有 `FEMU_ENABLE_*` / `FEMU_RESET_*` / `FEMU_PRINT_*` / `FEMU_LOG_*` 一致
- [ ] 错误处理：switch default case 已存在，未知 cdw10 走 `printf("FEMU:%s,Not implemented...")` 兜底
- [ ] 字符串安全：format string `"%s,%s,%s,%s,%s"` + 5 个 `%s` 参数匹配；no format string injection
- [ ] 并发安全：`femu_log` 是线程安全，FTL 单线程，OK
- [ ] 字段访问安全：`ssd->sp.enable_*` / `n->print_log` / `ssd->sp.pg_rd_lat` 均为已存在字段（无 NULL deref 风险）

## 设计-实现 diff

- design.md D1（enum 位置）: ✅ 实现与设计一致（line 57）
- design.md D2（输出格式）: ✅ 实现与设计一致（4 个 flag 逗号分隔，小写 on/off）
- design.md D3（delay_emu 派生）: ✅ 实现与设计一致（`ssd->sp.pg_rd_lat ? "on" : "off"`）
- design.md D4（无单元测试）: ✅ 实现与设计一致（per precedent）

## 严重问题

<reviewer 填写>

## 设计问题

<reviewer 填写>

## 代码质量

- 7 行新代码（1 行 enum + 6 行 case body）
- 与文件既有 C99 风格一致
- 无新增依赖
- 与 `add-print-version-flip` 的 `FEMU_LOG_VERSION` case 风格保持一致（femu_log 模板字符串前缀 `[FEMU] Log:`）

## 修复记录

N/A（待 reviewer 填写）。

## 签字

- **审查人**: ZSF
- **签字时间**: 2026-06-23 20:45
- **结论**: ⚠️ APPROVED WITH COMMENTS
- **Comments**: retroactive 补签以解决 AP-005 旧账（per retro 2026-06-refactor-bb-flip-table 下周期行动项 P0-2）；原 archive 时为 AI placeholder。

## 审查后行动

- 触发 `/opsx:archive add-bb-config-print` 归档
- archive 后此 review.md 与 verify-report.md 一起移到 `archive/2026-06-23-add-bb-config-print/`
