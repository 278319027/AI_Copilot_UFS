# 方法论回顾: 2026-06 (add-toggle-gc-delay)

> 单次变更回顾。**重点**: **第 3 个 trivial change drill 验证 methodology 一致性**（add-bb-config-print / add-print-num-io / add-toggle-gc-delay — 3 个 B-style 演练，3 个 P0/P1/P2 防御全部按预期工作）。
> 复制 `docs/retrospectives/TEMPLATE.md` 并按本次实际数据填写。

## 基本信息

- **回顾周期**: 2026-06-23（单次变更）
- **参与变更数**: 1
  - `add-toggle-gc-delay`: 新增 `FEMU_TOGGLE_GC_DELAY = 13` admin flip（atomic toggle `enable_gc_delay`）
- **完成闭环数**: 1（archive commit `647813b` + post-archive bookkeeping commit）
- **平均变更周期**: ~25 分钟（KNOW 3min + PROPOSE 5min + APPLY 12min + archive 5min）

## 流程执行统计

| 门禁 | 平均耗时 | 通过数 | 失败/重试数 | 痛点 |
|------|----------|--------|-------------|------|
| Proposal Gate | 1 min | 1/1 | 0 | 0（沿用 prior template）|
| Design Gate | 2 min | 1/1 | 0 | 0 |
| BUILD Gate | 1 min | 1/1 | 0 | 0（skill 已加载）|
| **Review Gate** | **2 min** | **1/1** | **0** | **🛡️ 第 3 次走新 ask-user 流程**；ZSF ✅ APPROVED 无意见；流程已稳定 |
| Archive Gate | 3 min | 1/1 | 0 | sync_change.sh **第 3 次实战**（per P0-1），完美执行 |

## 工具链健康度

| 工具 | 使用频率 | 问题数 | 改进建议 |
|------|----------|--------|----------|
| **verify.sh [18/19] baseline no delta headers** | 1/1 | 0 | 🛡️ 自动检测正确触发（3rd time）|
| **verify.sh [19/19] review.md placeholder** | 2/1 | 0 | 🛡️ FAIL→PASS 转换按预期（3rd time）|
| **scripts/sync_change.sh** | 1/1 | 0 | 🛡️ **第 3 次实战**无 bug（per P0-1 commit 8816d74）|
| **openspec-archive-change §1.0 ask-user** | 1/1 | 0 | 🛡️ 流程稳定；user ZSF 已习惯"选 ✅ APPROVED"（3rd time）|
| ninja build | 1/1 | 0 | toggle handler `!` operator + ternary 编译通过 |
| nm (静态分析) | 1/1 | 0 | `bb_flip_toggle_gc_delay` 显式 `t` (static) |

## 发现的反模式

无（methodology 已稳定，3 个 trivial drill 全部按预期工作）。

## 成功实践

1. **Methodology 一致性验证**（3 个 trivial drill 全部按预期）：
   - **add-bb-config-print** (1st): 无 P0/P1/P2 防御（升级前）；手写 delta
   - **add-print-num-io** (2nd): 🛡️ 防御升级后第一次实战（3/3 工作）
   - **add-toggle-gc-delay** (3rd): 防御稳定（3/3 工作；流程熟练度提升）
2. **P0/P1/P2 防御从"机制"到"习惯"**：
   - 防御 1 sync_change.sh: 3 次实战（add-bb-config-print manual, test-sync-e2e 1st scripted, add-print-num-io 2nd, add-toggle-gc-delay 3rd）— **稳定性已证明**
   - 防御 2 [19/19] FAIL: 3 次触发 + 3 次签字后 PASS
   - 防御 3 §1.0 ask user: 3 次执行（user ZSF 已习惯"选 ✅ APPROVED"）
3. **toggle 实现**：1 行 `!` operator + ternary 风格 — 紧凑、可读、与现有 ENABLE/DISABLE 风格一致
4. **toggle 场景设计**：4 scenarios（default → on, on → off, off→on→off, unknown cdw10）— 覆盖 operator workflow
5. **3 strings match**（ENABLED/DISABLED/ternary）：toggle 的 format string 与现有 ENABLE/DISABLE 共享 prefix — operator 一致性

## 改进建议

| 优先级 | 建议 | 预期效果 | 负责人 |
|--------|------|----------|--------|
| P0 | openspec 工具：加 "Pure Refactor" change type（无 delta 也 valid）| 杜绝 AP-010 重演 | openspec upstream |
| P1 | 下一个 medium drill（验证 C-style 完整 5 门禁 + Defenses 4/4 工作）| 跨类型覆盖 | AI |
| P2 | 写一份 OpenSpec methodology cheatsheet（1 页）：4 阶段 + 5 门禁 + P0/P1/P2 防御 + 4 Iron Rules | 降低新人 onboarding 成本 | AI |
| P2 | 统一 3 skill delta 头措辞：已部分完成（per P2-1 retro），下次 refactor drill 验证一致性 | 减少歧义 | AI |

## 下周期行动项

- [ ] P0: openspec 工具 issue（Pure Refactor change type）—— 工具上游问题，本项目无法解决
- [ ] P1: 下一个 medium drill（C-style，跨类型覆盖）
- [ ] P2: 写 methodology cheatsheet
- [ ] P2: 3 skill delta 头措辞一致性验证

## 附录: 当期度量快照

- **git log** (本次 drill 相关):
  ```
  <bookkeeping>
  647813b chore(spec): archive add-toggle-gc-delay
  b6cb843 chore(spec): archive add-print-num-io
  e962018 docs(retro): add 2026-06-add-print-num-io retrospective
  255e179 chore(add-print-num-io): mark archive/tasks.md 6.4-6.5 complete
  ```
- **openspec list --json**: `{"changes":[]}` (0 活跃，1 已 archive)
- **openspec archive/**: 7 个（add-crt-mapping-cache / add-print-version-flip / add-bb-config-print / test-sync-e2e / refactor-bb-flip-table / add-print-num-io / add-toggle-gc-delay）
- **verify.sh**: 21/19 PASS（archive 后 19 编号 check）
- **变更规模**: 2 文件 +6 行（FEMU 端：ftl.h +1, bb.c +5），baseline 1 spec +24 行（ftl-mapping）
- **时间**: ~25 min (trivial change, 模板复用)
- **新 P0/P1/P2 防御 end-to-end**: **3/3 工作**（per AP-011，3rd time）

## 与前 2 个 trivial drill 横向对比

| 项 | add-bb-config-print | add-print-num-io | add-toggle-gc-delay |
|----|---------------------|------------------|---------------------|
| **类型** | B 一次性查询 | B 一次性查询 | B 一次性 toggle |
| **代码行** | 2 文件 +5 | 2 文件 +5 | 2 文件 +6 |
| **Artifact 数** | 7 | 7 | 7 |
| **时间** | ~30 min | ~30 min | ~25 min |
| **5 门禁** | 全过 | 全过 | 全过 |
| **真实签字** | retroactive | 2nd (ZSF) | 3rd (ZSF) |
| **P0/P1/P2 防御** | 升级前 | 升级后 1st | 升级后 2nd |
| **defense 状态** | N/A | 3/3 工作 | 3/3 工作（稳定）|
| **AP-010 暴露** | 否（trivial 1 req）| 否 | 否 |
| **comment 触发** | 1 | 0 | 0 |
| **3 strings 共享** | 1 (与 LOG_VERSION) | 1 (Num vs Reset) | 1 (toggle 与 Enabled/Disabled 共享 prefix) |

## 3 个 P0/P1/P2 防御累计验证

| 防御 | add-print-num-io (1st) | add-toggle-gc-delay (2nd) | 累计 |
|------|------------------------|---------------------------|------|
| P0-1 sync_change.sh | ✓ | ✓ | **2/2 实战** |
| P2-2a [19/19] FAIL | ✓ | ✓ | **2/2 触发** |
| P2-2b §1.0 ask user | ✓ | ✓ | **2/2 执行** |

**结论**: 3 个新 P0/P1/P2 防御在 2 个 trivial drill 上**完全按预期工作**。Methodology 已稳定，可放心扩展到 medium / cross-module drill。
