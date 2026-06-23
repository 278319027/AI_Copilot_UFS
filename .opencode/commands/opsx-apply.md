---
name: opsx:apply
description: Stage 3 of OpenSpec 5-phase lifecycle — implement tasks.md one task at a time. Read contextFiles first. Loads openspec-apply skill.
---

# /opsx:apply

按 `tasks.md` 逐项实施，每完成一个 task 勾选 `- [x]`。

**用法**：`/opsx:apply [change-name]`

- 无参数：取唯一活跃变更
- `[change-name]`：指定变更

**入口操作**：
1. `skill(name="openspec-apply")` — 加载 apply skill
2. `skill(name="superpowers-executing-plans")` — 加载执行计划 skill
3. `skill(name="superpowers-verification-before-completion")` — 加载验证 skill
4. `skill(name="superpowers-test-driven-development")` — 加载测试 skill
5. 按 skill 指引执行：读 contextFiles → 逐个 task → 编码 → 测试 → 验证

**完整流程**：
1. `openspec list --json` 选变更
2. `openspec status --change "<name>" --json` 解析状态
3. `openspec instructions apply --change "<name>" --json` 取 `contextFiles` + 任务列表
4. **必读 contextFiles**（不只是 `tasks.md`）
5. 逐个 pending task：最小改动 → 勾选 `- [x]` → 验证 → 下一个

**BUILD Gate 检查清单**（编码前必须完成）：
- [ ] 已加载 `superpowers-verification-before-completion`
- [ ] 已加载 `superpowers-executing-plans`
- [ ] 测试计划已定义（正常路径 / 边界条件 / 错误路径）
- [ ] CodeGraph 影响分析完成
- [ ] `tasks.md` blockedBy 无循环

**测试纪律**（test-after）：
- 实现代码后补充测试，覆盖正常路径、边界条件、错误路径
- 纯逻辑代码：单元测试验证
- 硬件依赖代码（MMIO/ISR/DMA）：通过 HAL 抽象使业务逻辑可测；不可测路径在 review.md 中标注
- 注入验证：每条测试路径至少做一次 bug 注入→测试失败→撤销→恢复通过的循环

**校验命令**：
```bash
make clean && make -j$(nproc)
make test
openspec validate --strict --changes
bash scripts/check_change.sh <change-name>
```
