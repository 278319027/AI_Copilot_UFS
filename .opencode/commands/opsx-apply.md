---
name: opsx:apply
description: Stage 3 of OpenSpec 5-phase lifecycle — implement tasks.md one task at a time. Read contextFiles first. Loads openspec-apply skill.
---

# /opsx:apply

按 `tasks.md` 逐项实施，每完成一个 task 勾选 `- [x]`。

**用法**：`/opsx:apply [change-name]`

- 无参数：取唯一活跃变更
- `[change-name]`：指定变更

**加载 skill**：[openspec-apply](../skills/openspec-apply/SKILL.md)

**完整流程**：
1. `openspec list --json` 选变更
2. `openspec status --change "<name>" --json` 解析状态
3. `openspec instructions apply --change "<name>" --json` 取 `contextFiles` + 任务列表
4. **必读 contextFiles**（不只是 `tasks.md`）
5. 逐个 pending task：最小改动 → 勾选 `- [x]` → 验证 → 下一个

**TDD 双路径**（嵌入 C）：
- **Path A**（纯逻辑）：红→绿→重构
- **Path B**（硬件依赖）：BUILD 编译即验证，FEEDBACK 阶段测
