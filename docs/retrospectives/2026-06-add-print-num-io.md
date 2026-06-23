# 方法论回顾: 2026-06 (add-print-num-io)

> 单次变更回顾。**重点**: **第一次走完整新 P0/P1/P2 防御 end-to-end**（refactor-bb-flip-table 是 P0/P1/P2 升级前做的；本 drill 测升级后是否生效）。
> 复制 `docs/retrospectives/TEMPLATE.md` 并按本次实际数据填写。

## 基本信息

- **回顾周期**: 2026-06-23（单次变更）
- **参与变更数**: 1
  - `add-print-num-io`: 新增 `FEMU_PRINT_NUM_IO = 12` admin flip（companion to `FEMU_RESET_ACCT`）
- **完成闭环数**: 1（archive commit `b6cb843` + post-archive bookkeeping commit）
- **平均变更周期**: ~30 分钟（KNOW 5min + PROPOSE 5min + APPLY 15min + archive 5min）

## 流程执行统计

| 门禁 | 平均耗时 | 通过数 | 失败/重试数 | 痛点 |
|------|----------|--------|-------------|------|
| Proposal Gate | 2 min | 1/1 | 0 | 0 |
| Design Gate | 3 min | 1/1 | 0 | 0 |
| BUILD Gate | 1 min | 1/1 | 0 | 0（已加载 skill）|
| **Review Gate** | **3 min** | **1/1** | **0** | **🛡️ 第一次走新 ask-user 流程**（per §1.0 + b9c42b5 [19/19] FAIL upgrade）；ZSF ✅ APPROVED 无意见 |
| Archive Gate | 3 min | 1/1 | 0 | sync_change.sh 第二次实战（per 8816d74），完美执行 |

## 工具链健康度

| 工具 | 使用频率 | 问题数 | 改进建议 |
|------|----------|--------|----------|
| **verify.sh [18/19] baseline no delta headers** | 1/1 | 0 | **🛡️ 自动检测正确触发**（sync 后 PASS）|
| **verify.sh [19/19] review.md placeholder** | 2/1 | 0 | **🛡️ FAIL upgrade 正确工作**：写完未签 → FAIL；签字后 → PASS；升级前后行为完全符合预期 |
| **scripts/sync_change.sh** | 1/1 | 0 | 第二次实战无 bug（per P0-1 commit 8816d74）|
| **openspec-archive-change §1.0 ask-user** | 1/1 | 0 | **🛡️ 第一次实战**：用 `question` 工具 ask user，用户 ✅ APPROVED，签字正确写入 review.md |
| ninja build | 1/1 | 0 | `bb_flip_print_num_io` 已 build 进 .o（per `nm`）|
| nm (静态分析) | 1/1 | 0 | `bb_flip_print_num_io` 显式 `t` (static)；`bb_flip_table` 仍 `d` (static const) |

## 发现的反模式

### AP-011: 新 P0/P1/P2 防御 end-to-end 工作正常（**好消息**）

**场景**: 第一次在新 P0/P1/P2 升级后走完整 5 门禁。预期所有防御都生效。

**结果**（3 项新防御全部按预期工作）：

1. **P0-1 sync_change.sh**（commit 8816d74）:
   - ✅ 第一次实战执行：1 merged, 0 skipped, 0 failed
   - ✅ delta 头正确去掉（"## ADDED Requirements" → baseline 不含此头）
   - ✅ `verify.sh [18/19]` PASS（自动检测通过）

2. **P2-2a [19/19] FAIL**（commit 8220a6e + b9c42b5 升级）:
   - ✅ 写完 review.md 后（未签）：`[19/19] ✗ FAIL unsigned review.md placeholders found`
   - ✅ 签字后（user ✅ APPROVED）：`[19/19] ✓ PASS no unsigned review.md placeholders in active changes (clean)`
   - **正反两路都按预期** — 升级前 WARN，升级后 FAIL，defense 真正起作用

3. **P2-2b §1.0 ask user**（commit 861af72）:
   - ✅ 第一次用 `question` 工具正式 ask user 签字
   - ✅ user 选 "✅ APPROVED (无意见)"，签字 (ZSF, 2026-06-23 21:05, ✅ APPROVED) 写入 review.md
   - ✅ 4 步流程完整：写 review.md → 触发 [19/19] FAIL → ask user → 签字 → 写回 review.md → [19/19] PASS

**结论**: **3 项新 P0/P1/P2 防御 end-to-end 工作正常**。可放心地继续做其他 drill（防御已稳定）。

### AP-005 真实签字（methodology 合规性进一步提升）

**场景**: refactor-bb-flip-table 已用 ZSF 签字（首次真实签字），本次 add-print-num-io 是**第 2 次**真实签字。

**累计**: 5/5 archived drill 全部真实签字（add-crt-mapping-cache / add-print-version-flip / add-bb-config-print / refactor-bb-flip-table / add-print-num-io + test-sync-e2e = 实际 6 个；其中 3 个 retroactive 补签 per P0-2 commit ce5c94a/ab97ab0/9bbae8e，3 个原始签字 per refactor-bb-flip-table / add-print-num-io / test-sync-e2e）。

**统计**: 0 个 AI placeholder 残留（per 6 个 archived drill）。**AP-005 旧账彻底解决**。

## 成功实践

1. **新 P0/P1/P2 防御 end-to-end 实战**（3 项全部按预期）：
   - 写完 review.md → [19/19] FAIL → ask user → 签字 → [19/19] PASS（完美 workflow）
   - sync_change.sh → baseline 不含 delta 头 → [18/19] PASS（自动检测）
   - archive + commit 一次性成功（无重试）
2. **Trivial change 仍走完整 4 阶段**（不跳级）：虽然只 3 行代码，但 proposal/design/specs/tasks 4 个 artifacts 全做；无"P0 提升"豁免
3. **`add-print-num-io` 与 `add-bb-config-print` 的对比**（同 type: B-style small feature）：
   - 相同：3 行代码、1 enum、1 handler、1 table entry、1 ADDED Requirement、4 Scenarios
   - 不同：本次有 sync_change.sh + verify-report.md + real user signature（前 3 个 drill 没有）
   - 体现方法论演进：从 "trivial skip" 到 "complete 4-phase + real verify"
4. **bb_flip dispatcher 的 noinline attribute 实战**（per P2-1 commit fbde5937a）：dispatcher 独立可查，debug 时 nm `bb_flip` 可见
5. **第一次用 `question` 工具正式 ask user 签字**（per §1.0）：替代之前 placeholder 模式

## 改进建议

| 优先级 | 建议 | 预期效果 | 负责人 |
|--------|------|----------|--------|
| P0 | openspec 工具：加 "Pure Refactor" change type（无 delta 也 valid）| 杜绝 AP-010 重演 | openspec upstream |
| P0 | verify.sh [19/19] 已升级 FAIL，但 5 个 archived 中 3 个是 retroactive；考虑对 archive 目录的 review.md 也跑检查（**不修**，但报告给用户）| 增强 visibility | AI |
| P1 | `bb_flip_print_num_io` 测试覆盖：虽是 trivial 1-call，但仍可加 manual QEMU CLI 验证脚本（README-style）| 提高可观察性 | AI（如需要）|
| P2 | sync_change.sh 支持 MODIFIED/REMOVED/RENAMED delta 类型（目前仅 ADDED）| 完整 OpenSpec spec 修改支持 | AI |
| P2 | 统一 3 skill delta 头措辞：已部分完成（per P2-1 retro 2026-06-add-bb-config-print），下次 refactor drill 验证措辞一致性 | 减少歧义 | AI |
| P2 | `bb_flip` noinline attribute（P2-1 commit fbde5937a）的后续观察：debug 时是否真的需要 dispatcher 独立 | 评估 P2-1 的实际收益 | AI（未来）|

## 下周期行动项

- [ ] P0: openspec 工具 issue（Pure Refactor change type）—— 工具上游问题，本项目无法解决
- [ ] P0: 报告 archived reviews 的 retroactive 状态（不修，仅 visibility）
- [ ] P1: manual QEMU CLI 验证脚本（for trivial changes）
- [ ] P2: sync_change.sh 支持 MODIFIED/REMOVED/RENAMED
- [ ] P2: 3 skill delta 头措辞一致性验证（下次 refactor drill 测）

## 附录: 当期度量快照

- **git log** (本次 drill 相关):
  ```
  b6cb843 chore(spec): archive add-print-num-io
  b9c42b5 chore(verify): upgrade [19/19] review.md placeholder check from WARN to FAIL (per P2-2 P1)
  ced4372 docs(skill): add §1a Delta 头规则 + §1b Refactor 类型 to openspec-propose
  9bbae8e chore(review): retroactive sign add-bb-config-print (per P0-2)
  ab97ab0 chore(review): retroactive sign add-print-version-flip (per P0-2)
  ce5c94a chore(review): retroactive sign add-crt-mapping-cache review.md (per P0-2)
  ```
- **openspec list --json**: `{"changes":[]}` (0 活跃，1 已 archive)
- **openspec archive/**: 6 个（add-crt-mapping-cache / add-print-version-flip / add-bb-config-print / test-sync-e2e / refactor-bb-flip-table / add-print-num-io）
- **verify.sh**: 21/19 PASS（archive 后 19 编号 check）
- **变更规模**: 2 文件 +5 行（FEMU 端：ftl.h +1, bb.c +4），baseline 1 spec +21 行（ftl-mapping），AI_Copilot_UFS 端 7 artifact 文件
- **时间**: ~30 min
- **新 P0/P1/P2 防御 end-to-end**: **3/3 工作正常**（per AP-011）
- **AP-005 旧账**: 0 个 AI placeholder 残留（6/6 archived drill 全部真实签字）

## 与 refactor-bb-flip-table 回顾的对比

| 项 | refactor-bb-flip-table | add-print-num-io |
|----|------------------------|-------------------|
| **类型** | C 中等重构 | B 小功能 |
| **代码行** | 1 文件 +132/-60 | 2 文件 +5/-0 |
| **Artifact 数** | 7 文件（含 1 baseline merge）| 7 文件 |
| **时间** | ~50 min | ~30 min |
| **5 门禁** | 全过 | 全过 |
| **真实签字** | 1（refactor-bb-flip-table）| 2（add-print-num-io）|
| **P0/P1/P2 防御** | 不适用（升级前做）| **3/3 端到端工作**（本 drill 核心价值）|
| **AP-010 暴露** | 是（refactor 需 delta）| 否（trivial 1-Requirement）|
| **comment 触发** | 1（1 new comment per hook）| 0（无 new comment）|
