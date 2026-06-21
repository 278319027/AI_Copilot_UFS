## 1. 瘦身 AGENTS.md（82 → ≤ 60 行）

- [ ] 1.1 删除 lines 3-9「superpowers 四条铁律」整段，替换为 1 行指针
- [ ] 1.2 删除 lines 75-81「7 superpowers 规则清单」整段，替换为 1 行指针
- [ ] 1.3 顶部加 1 行说明：「AI 完整工作流见 `sd-firmware-copilot/SKILL.md`」
- [ ] 1.4 验证 `wc -l AGENTS.md` ≤ 60 行

## 2. 瘦身 Methodology.md（286 → ≤ 130 行）

- [ ] 2.1 删除 §3 KNOW 阶段（lines 41-92，~52 行）→ 替换为 1 段指针
- [ ] 2.2 删除 §4 PLAN 阶段（lines 95-122，~28 行）→ 替换为 1 段指针
- [ ] 2.3 删除 §5 BUILD 阶段（lines 125-205，~81 行）→ 替换为 1 段指针
- [ ] 2.4 删除 §6 FEEDBACK 阶段（lines 208-223，~16 行）→ 替换为 1 段指针
- [ ] 2.5 §2 末尾加 1 段：「阶段详细流程见 `sd-firmware-copilot/SKILL.md` 与 `openspec-workflow/SKILL.md`」
- [ ] 2.6 验证 `wc -l SSD_Firmware_AI_Copilot_Methodology.md` ≤ 130 行

## 3. 扩展 verify.sh（12/12 → 13/13）

- [ ] 3.1 改 [12/12] → [12/12]（保持），在 summary 前加 [13/13] 检查 `.omo/` 目录非空
- [ ] 3.2 改 summary 文案：「Summary: %d/13 checks passed」
- [ ] 3.3 跑 `bash verify.sh` 验证 12/13（[10/12] FEMU_ROOT = 环境问题，其余通过）

## 4. 验证

- [ ] 4.1 跑 `bash verify.sh` 期望 12/13 通过（剩 FEMU_ROOT 环境）
- [ ] 4.2 跑 `OPENSPEC_TELEMETRY=0 openspec validate --strict --specs` 期望 5/5
- [ ] 4.3 `grep -rn "完成前.*遵循.*verification-before-completion\|写任何生产代码前.*test-driven-development" AGENTS.md` 期望无匹配（已删）

## 5. 提交 + 归档

- [ ] 5.1 跑 `git add AGENTS.md SSD_Firmware_AI_Copilot_Methodology.md verify.sh openspec/changes/cleanup-redundant-docs-and-omo-stale-tasks/`
- [ ] 5.2 跑 `git commit -m "docs(cleanup): slim AGENTS.md + Methodology.md by removing skill duplications, add .omo/ cleanliness check"`
- [ ] 5.3 跑 `mv openspec/changes/cleanup-redundant-docs-and-omo-stale-tasks/ openspec/changes/archive/2026-06-21-cleanup-redundant-docs-and-omo-stale-tasks/`
- [ ] 5.4 跑 `git add openspec/changes/ && git commit -m "chore(spec): archive cleanup-redundant-docs-and-omo-stale-tasks"`
