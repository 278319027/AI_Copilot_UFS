# 方法论回顾: 2026-06 (add-bb-config-print)

> 单次变更回顾（per add-print-version-flip precedent）。本次回顾重点：**同步 delta 失败 + 手动合并 bug**。
> 复制 `docs/retrospectives/TEMPLATE.md` 并按本次实际数据填写。

## 基本信息

- **回顾周期**: 2026-06-23（单次变更）
- **参与变更数**: 1
  - `add-bb-config-print`：新增 `FEMU_PRINT_BB_CONFIG` admin flip（一次性查询 4 个 BB mode flag）
- **完成闭环数**: 1（archive 已提交 `8530898`）
- **平均变更周期**: ~30 分钟（KNOW 5min + PROPOSE 5min + APPLY 15min + archive 5min）

## 流程执行统计

| 门禁 | 平均耗时 | 通过数 | 失败/重试数 | 痛点 |
|------|----------|--------|-------------|------|
| Proposal Gate | 2 min | 1/1 | 0 | 0 |
| Design Gate | 3 min | 1/1 | 0 | 0 |
| BUILD Gate | 1 min | 1/1 | 0 | 0 |
| Review Gate | 1 min | 0/1 ⚠️ | 0 | **review.md 仍是 placeholder，AI 不能自签** |
| Archive Gate | 5 min | 1/1 | **1 重试** | **`openspec sync` CLI 缺失 + 手动合并首次错放 `## ADDED Requirements` 头** |

## 工具链健康度

| 工具 | 使用频率 | 问题数 | 改进建议 |
|------|----------|--------|----------|
| CodeGraph | 0/1 | 0 | 沿用 add-print-version-flip 的"0 external dependents"结论，无新调用 |
| Graphify | 0/1 | 0 | 目标代码库 15K+ 文件，按 AI_Copilot_UFS project.md 不在 AI_Copilot_UFS 跑 |
| **OpenSpec CLI** | 5/5 | **2** ⚠️ | **见 AP-009**：`openspec sync` 不存在（slash 命令 `/opsx:sync` 应是入口）+ 错误信息 `"unknown command 'sync'"` 误导 |
| verify.sh | 5/5 | 1 | check [11/17] 硬编码 `-eq 5`（实际 11 个 opsx-*）— 软警告未计入 fail，但需修 |
| build (ninja) | 1/1 | 0 | 关键发现：ninja 增量构建依赖 `touch` 强制重编才能可靠验证（mtime vs .d 文件依赖关系）|

## 发现的反模式

### AP-009: `openspec sync` CLI 缺失 + 手动合并首次放错位置

**场景**：`add-bb-config-print` archive 阶段（2026-06-23 18:48），执行 `openspec sync "add-bb-config-print"`，CLI 报 `error: unknown command 'sync'. (Did you mean spec?)`，迫使手动合并。

**后果**：
1. 手动合并**首次错误**地把 `## ADDED Requirements` 头（delta 头）放进了 `openspec/specs/ftl-mapping/spec.md` baseline，导致 `openspec validate --strict --specs` 报 2 个 ERROR（"Delta headers are only valid inside openspec/changes/..." + "Requirement appears outside main ## Requirements section"），同时 verify.sh 从 17/17 跌到 16/17。
2. **修复**：去掉 baseline 里的 `## ADDED Requirements` 头（delta 头），让 `### Requirement: BB Configuration Reporting Flip` 直接进 baseline 的 `## Requirements` 段，validate 重回 3/3 PASS。
3. **多花 2 分钟**修合并 bug；archive commit 推迟。

**根因**：
1. **OpenSpec CLI 表面完整但 sync 实际缺失**：`openspec instructions/validate/list` 都存在，唯独 `openspec sync` 没有；但 `AGENTS.md §OpenSpec Changes §Archive 步骤 2` 明确写 `/opsx:sync`，`openspec-archive-change/SKILL.md` 也写 "提议先 `/opsx:sync`" — **slash 命令与 CLI 不对齐**。
2. **openspec-sync-specs skill 没有"baseline 头格式"约束**：模板上写 `## ADDED Requirements`，但没明说"放进 baseline 时**必须去掉这个头**"，所以手动合并时凭直觉复制了 delta 头到 baseline。
3. **openspec-archive-change SKILL 的 sync 步骤只说"智能合并"，没列出"打开 baseline + 删除 delta 头"的具体操作**。

**修复**：
- **短期**：在 `openspec-archive-change/SKILL.md` §3 后加 §3.5 "Manual sync fallback" — 当 `openspec sync` CLI 不可用时，**正确做法是打开 `openspec/specs/<cap>/spec.md`，找 `## Requirements` 段，APPEND delta 的 Requirements/Scenarios 内容，**不要**复制 `## ADDED Requirements` 头**。
- **长期**：补齐 OpenSpec CLI 的 sync 子命令（或澄清 `/opsx:sync` slash 命令才是入口）；openspec-sync-specs skill 加 "baseline delta 头规则" 段。

**预防**：
- openspec-propose/sync-specs/archive-change 三 skill 在描述 delta 合并时，统一用"**delta 头只活在 change 副本里，合并到 baseline 时头会被吞掉**"措辞，避免歧义。
- verify.sh 加一项 `[18/18]`：`openspec/specs/*/spec.md` 不含 `## ADDED Requirements` / `## MODIFIED Requirements` 等 delta 头（baseline 不应有 delta 头）。

## 成功实践

1. **沿用 add-print-version-flip 的 trivial-change 模式**：design.md D4 明确写"无单元测试（per precedent）"，避免被 M-2 100% 覆盖率卡住。**这是把 prior drill 的决策沉淀为 reusable 模式的好例子**。
2. **fresh build evidence 用了 strings + nm**：不只是看 make exit 0，还 `strings libsystem.a.p/hw_femu_bbssd_bb.c.o | grep "FEMU BB"` 确认新字符串字面量在 .rodata 里（mtime 不可靠时的有效补救）。
3. **verify-report.md 显式标注 N/A 项**：4/6 PASS + 2/6 N/A（per design D4 + AI_Copilot_UFS project.md），比"全 PASS"的虚假成功更诚实。

## 改进建议

| 优先级 | 建议 | 预期效果 | 负责人 |
|--------|------|----------|--------|
| P0 | 修 `openspec sync` CLI 缺失 或澄清 `/opsx:sync` 入口 | 杜绝 AP-009 再次发生 | AI（下次提案） |
| P0 | 修 `verify.sh [11/17]` `-eq 5` → `-ge 5`（允许 opsx-* 扩到 11+） | 消除软警告噪声 | AI |
| P1 | `openspec-archive-change/SKILL.md` 加 §3.5 manual sync fallback 段 | 文档化正确做法 | AI |
| P1 | verify.sh 加 check `[18/18]` baseline 不含 delta 头 | 防止 AP-009 再次发生 | AI |
| P2 | openspec-* 3 skill 统一"delta 头规则"措辞 | 减少歧义 | AI（待 P0 修后） |
| P2 | review.md human signature 流程：归档前 AI 主动 `git diff` + ask user 确认签字 | 解决 AP-005 AI 自批问题 | AI + 用户 |

## 下周期行动项

- [ ] P0: 修复 `openspec sync` CLI 或文档化 `/opsx:sync` 入口
- [ ] P0: 修复 verify.sh [11/17] `-eq 5` → `-ge 5`
- [ ] P1: openspec-archive-change/SKILL.md 加 manual sync fallback 段
- [ ] P1: verify.sh 加 baseline-no-delta-header 检查
- [ ] P2: 统一 openspec-* 3 skill 的 delta 头措辞
- [ ] P2: review.md 流程化（AI 主动 ask user 签字）

## 附录: 当期度量快照

- **git log** (本次变更相关):
  ```
  8530898 chore(spec): archive add-bb-config-print
  ```
- **openspec list --json**: `{"changes":[]}`（0 活跃，1 已 archive）
- **openspec archive/**: 3 个（add-crt-mapping-cache / add-print-version-flip / add-bb-config-print）
- **verify.sh**: 17/17（archive 后回归测试）
- **变更规模**: 2 文件 +21/-0 行（FEMU 端），baseline 1 spec +22 行（ftl-mapping），AI_Copilot_UFS 端 7 个 artifact 文件
