## 1. 概念层瘦身

- [ ] 1.1 读取当前 `openspec-workflow/SKILL.md` 132 行原文，提取 3 条 Iron Rules + 跨切约束（Lines 17-21, 125-131）作为新概念层骨架
- [ ] 1.2 重写 `openspec-workflow/SKILL.md` ≤ 50 行：YAML frontmatter + 3 Iron Rules + 跨切约束 + 5 phase skill 路由表

## 2. 5 个 phase skill 创建

- [ ] 2.1 创建 `openspec-propose/SKILL.md`：Stage 1 完整流程（`openspec new change` + `status --change --json` + `instructions <id>` 循环）
- [ ] 2.2 创建 `openspec-explore/SKILL.md`：Stage 2 完整流程（`openspec list` + 不写实现）
- [ ] 2.3 创建 `openspec-apply/SKILL.md`：Stage 3 完整流程（contextFiles 必读 + workspace guard + 逐 task 勾选）
- [ ] 2.4 创建 `openspec-sync-specs/SKILL.md`：Stage 4 完整流程（ADDED/MODIFIED/REMOVED/RENAMED 智能合并）
- [ ] 2.5 创建 `openspec-archive-change/SKILL.md`：Stage 5 完整流程（status 检查 + 评估 delta + `mv` 归档）

## 3. 5 个 slash 命令落地

- [ ] 3.1 创建 `.opencode/commands/opsx-propose.md`：YAML frontmatter `name: opsx:propose` + 指针到 `openspec-propose` skill
- [ ] 3.2 创建 `.opencode/commands/opsx-explore.md`：指针到 `openspec-explore` skill
- [ ] 3.3 创建 `.opencode/commands/opsx-apply.md`：指针到 `openspec-apply` skill
- [ ] 3.4 创建 `.opencode/commands/opsx-sync.md`：指针到 `openspec-sync-specs` skill
- [ ] 3.5 创建 `.opencode/commands/opsx-archive.md`：指针到 `openspec-archive-change` skill

## 4. verify.sh 更新

- [ ] 4.1 修改 [12/12] 检查脚本：期望从 13 改为 20（5 openspec-* + 1 openspec-workflow + 14 superpowers-*）
- [ ] 4.2 跑 `bash verify.sh` 期望 12/12 通过

## 5. 文档同步

- [ ] 5.1 更新 `docs/navigation.md`：「10 子技能」改为「1 sd-firmware-copilot + 1 openspec-workflow + 5 openspec-* + 14 superpowers-* = 21」
- [ ] 5.2 更新 `SSD_Firmware_AI_Copilot_Methodology.md` §8 目录结构：`skills/` 下拆分为 4 个子组
- [ ] 5.3 更新 `AGENTS.md` 中「openspec-workflow 五合一」描述 → 改为「openspec-workflow 概念层 + 5 phase skill」

## 6. 端到端验证

- [ ] 6.1 跑 `bash verify.sh` 期望 12/12 通过
- [ ] 6.2 跑 `OPENSPEC_TELEMETRY=0 openspec validate --strict --specs` 期望通过（baseline specs 未变）
- [ ] 6.3 跑 `OPENSPEC_TELEMETRY=0 openspec validate --strict --changes` 期望通过（本 change artifacts 完整）
- [ ] 6.4 grep 5 个 opsx-*.md 与 5 个 openspec-{phase}/SKILL.md 的引用关系双向一致

## 7. 归档

- [ ] 7.1 跑 `git add openspec/changes/split-openspec-workflow-skill/ .opencode/skills/ .opencode/commands/ verify.sh docs/ SSD_Firmware_AI_Copilot_Methodology.md AGENTS.md`
- [ ] 7.2 跑 `git commit -m "refactor(skills): split openspec-workflow into 1 concept + 5 phase skills with native slash commands"`
- [ ] 7.3 跑 `mv openspec/changes/split-openspec-workflow-skill/ openspec/changes/archive/2026-06-21-split-openspec-workflow-skill/`
- [ ] 7.4 跑 `git add openspec/changes/` && `git commit -m "chore(spec): archive split-openspec-workflow-skill"`
