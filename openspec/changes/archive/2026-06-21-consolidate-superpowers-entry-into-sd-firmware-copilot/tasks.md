## 1. 在 sd-firmware-copilot/SKILL.md 追加「Superpowers 框架整合」段

- [ ] 1.1 读当前 `sd-firmware-copilot/SKILL.md`（350 行）确认插入点（"## 初始化" 之前，约 line 343）
- [ ] 1.2 编辑追加 `## Superpowers 框架整合` 顶级标题 + 5 个子段：Iron Rules / Bootstrap 决策表 / 阶段转换触发器 / Red-line 自检 / Skill map 速查
- [ ] 1.3 验证追加后行数 ≤ 430 行（350 + 80）

## 2. 删除 superpowers/SKILL.md

- [ ] 2.1 跑 `git rm .opencode/skills/superpowers/SKILL.md` 删除文件
- [ ] 2.2 验证 `.opencode/skills/superpowers/` 目录已不存在

## 3. 更新 verify.sh [12/12] 检查

- [ ] 3.1 编辑 verify.sh line 141：去掉 `[ -d "$PROJECT_ROOT/.opencode/skills/superpowers" ]` 检查
- [ ] 3.2 编辑 verify.sh line 130：把 "21 expected" 改为 "20 expected"
- [ ] 3.3 编辑 verify.sh line 144 / 146 ok/bad 文案：去掉 superpowers=1 字段

## 4. 更新 8+ 处 markdown 引用

- [ ] 4.1 改 `sd-firmware-copilot/SKILL.md:86` 内链：`../superpowers/SKILL.md` → `§Superpowers 框架整合` (同文件)
- [ ] 4.2 改 `AGENTS.md:72, 82` 入口描述：`完整铁律索引见 .opencode/skills/superpowers/SKILL.md` → `... sd-firmware-copilot/SKILL.md §Superpowers 框架整合`
- [ ] 4.3 改 `README.md:52` 工具表：`.opencode/skills/superpowers/` → `.opencode/skills/sd-firmware-copilot/`
- [ ] 4.4 改 `SSD_Firmware_AI_Copilot_Methodology.md:284`：`.opencode/skills/superpowers/SKILL.md` → `sd-firmware-copilot/SKILL.md §Superpowers 框架整合`
- [ ] 4.5 改 `docs/roadmap.md:66`：`部署 Superpowers（13 子技能） | ✅ | .opencode/skills/superpowers/` → 加注解「入口合并至 sd-firmware-copilot」
- [ ] 4.6 改 `docs/maintainer.md:126`：`superpowers/` 行 → 「工程纪律层（13 子技能），入口在 `sd-firmware-copilot/SKILL.md §Superpowers 框架整合`」

## 5. 更新 deploy_tools.sh 8 处引用

- [ ] 5.1 改 line 14-15 注释：`.opencode/skills/superpowers/SKILL.md` → `sd-firmware-copilot/SKILL.md §Superpowers 框架整合`
- [ ] 5.2 改 line 309-315 目录检查：检查 `superpowers-*/` 数量（仍是 13）+ 文案提示指向新位置
- [ ] 5.3 改 line 336 + 362 其他引用

## 6. 验证

- [ ] 6.1 跑 `bash verify.sh` 期望 11/12（[10/12] FEMU_ROOT = 环境问题）
- [ ] 6.2 跑 `OPENSPEC_TELEMETRY=0 openspec validate --strict --specs` 期望 5/5 通过
- [ ] 6.3 `grep -rn "superpowers/SKILL\.md" /home/zsf/AI_Proj/zsf/ --include="*.md" --include="*.sh" --include="*.json"` 期望无匹配（除本 change artifacts 与 git log）
- [ ] 6.4 `ls /home/zsf/AI_Proj/zsf/.opencode/skills/superpowers/ 2>&1` 期望 "No such file or directory"

## 7. 提交 + 归档

- [ ] 7.1 跑 `git add -A` + `git status --short` 检查
- [ ] 7.2 跑 `git commit -m "refactor(skills): consolidate superpowers framework entry into sd-firmware-copilot"`
- [ ] 7.3 跑 `mv openspec/changes/consolidate-superpowers-entry-into-sd-firmware-copilot/ openspec/changes/archive/2026-06-21-consolidate-superpowers-entry-into-sd-firmware-copilot/`
- [ ] 7.4 跑 `git add openspec/changes/ && git commit -m "chore(spec): archive consolidate-superpowers-entry-into-sd-firmware-copilot"`
