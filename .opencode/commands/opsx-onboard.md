---
name: opsx:onboard
description: Onboarding — guided walkthrough of the full OpenSpec 5-phase lifecycle with a real example change. Use for new team members or first-time users. Loads openspec-workflow + superpowers-using-superpowers skills.
---

# /opsx:onboard

**新人引导**：以一个**真实的端到端示例**走完 OpenSpec 5 阶段（propose → explore → apply → sync → archive）+ 5 级门禁（Proposal → Design → BUILD → Review → Archive）。

**用法**：`/opsx:onboard`

- 无参数：使用内置示例（`add-read-latency-log`）走完整流程
- 适用对象：第一次接触本项目 OpenSpec 流程的工程师

**入口操作**：
1. `skill(name="superpowers-using-superpowers")` — 纪律约束第一
2. `skill(name="openspec-workflow")` — 5 phase 概念入口
3. `skill(name="sd-firmware-copilot")` — 项目级集成 skill
4. 按 skill 指引：演示示例 change 全流程 → 解释每个 artifact 的目的 → 让用户在自己仓库复刻

**完整流程（教学版）**：

**Phase 0：环境就绪**
```bash
bash scripts/verify.sh                                                       # 17/17 通过
OPENSPEC_TELEMETRY=0 openspec validate --strict --specs              # baseline 有效
```

**Phase 1：propose** — 创建变更
```text
/opsx:propose add-read-latency-log "在 NVMe Read 命令路径记录 LBA→PBA 的延迟"
```
- 看 AI 如何生成 `proposal.md` / `specs/<cap>/spec.md` (delta) / `design.md` / `tasks.md`
- 重点观察：proposal.md 的 Non-goals 段、specs 的 ADDED Requirement 格式、tasks.md 的 blockedBy 关系

**Phase 2：explore** — 调研
```text
/opsx:explore read-latency
```
- 看 AI 如何用 CodeGraph（`codegraph where` / `codegraph impact`）+ Graphify（`graphify query` / `graphify explain`）调研
- **强调**：explore 阶段**不写应用代码**，只更新 `design.md` 思考段

**Phase 3：apply** — 实施
```text
/opsx:apply add-read-latency-log
```
- 看 AI 如何按 `tasks.md` 顺序逐 task 实施并勾选
- **强调 BUILD Gate**：实施前必加载 `superpowers-verification-before-completion` + `superpowers-executing-plans` + `superpowers-test-driven-development`
- 看 AI 如何在 PR 中体现 spec → code 的对应关系

**Phase 4：sync** — 合并 delta
```text
/opsx:sync add-read-latency-log
```
- 看 AI 如何智能合并（ADDED 追加 / MODIFIED 替换 / REMOVED 删）
- **强调**：不程序化覆盖 baseline，保留未提及内容

**Phase 5：archive** — 归档
```text
/opsx:archive add-read-latency-log
```
- 看 AI 如何生成归档 commit：`chore(spec): archive add-read-latency-log`
- 验证 `openspec/specs/<cap>/spec.md` 已含新增 Requirement

**关键学习点**：

| 概念 | 关键文档 |
|------|----------|
| 5 阶段 + 5 门禁 | `sd-firmware-copilot/SKILL.md §五级门禁` |
| Iron Rules | `sd-firmware-copilot/SKILL.md §Superpowers 框架整合` |
| Delta 格式 | `openspec-workflow/SKILL.md §跨切约束` |
| Spec 写作规则 | `sd-firmware-copilot/SKILL.md §Spec 规则` |
| 内存规则 | `.opencode/memory/{architecture,concurrency_rules,coding_style,design_rules,testing_rules}.md` |

**Onboard 完成后建议**：

1. 阅读 `docs/navigation.md` — 完整文件地图
2. 阅读 `docs/adr/0004-five-gates.md` — 五门禁设计依据
3. 选一个**简单**的实际需求，跑一遍 5 阶段（建议从单文件 bugfix 开始，豁免 Proposal Gate）
4. 写第一份 `review.md` 时参考 `superpowers-requesting-code-review/ssd-review-rules.md`

**关键约束**：
- `/opsx:onboard` 是**教学命令**，不在生产流程中使用
- 完成后用户应能独立完成 5 阶段闭环
- 引导时 AI 不得**跳步**（即使示例简单）——目的是让用户**看到完整流程**才知全貌

**校验命令**：
```bash
openspec list --changes
openspec validate --strict --specs
ls openspec/changes/archive/  # 看到至少 1 个已归档变更
```
