---
name: opsx:sync
description: Stage 4 of OpenSpec 5-phase lifecycle — merge delta specs (ADDED/MODIFIED/REMOVED/RENAMED) from changes/{id}/specs/ into openspec/specs/ baseline. Smart merge, not programmatic replacement. Loads openspec-sync-specs skill.
---

# /opsx:sync

合并 delta spec 到 baseline。

**用法**：`/opsx:sync [change-name]`

- 无参数：取唯一活跃变更
- `[change-name]`：指定变更

**加载 skill**：[openspec-sync-specs](../skills/openspec-sync-specs/SKILL.md)

**完整流程**：
1. 读 `openspec/changes/<id>/specs/<cap>/spec.md` 找 delta 段（`## ADDED` / `MODIFIED` / `REMOVED` / `RENAMED`）
2. 读 baseline `openspec/specs/<cap>/spec.md`
3. 智能合并：ADDED 追加 / MODIFIED 替换同名 Requirement / REMOVED 删 / RENAMED 用 `FROM:` `TO:`
4. 跑 `openspec validate --strict --specs` 验证

**关键约束**：
- 绝不程序化合并（`cp` 覆盖 baseline）
- 保留 delta 未提及的 baseline 内容
- MODIFIED 头文本必须完全一致
- REMOVED 必含 `**Reason:**` + `**Migration:**`
- Scenario 强制 4 个 `#`
