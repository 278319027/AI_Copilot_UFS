---
name: opsx:propose
description: Stage 1 of OpenSpec 5-phase lifecycle — create a new change and generate 4 artifacts. Loads openspec-propose skill.
---

# /opsx:propose

创建新的 OpenSpec 变更（proposal / design / specs / tasks）。

**用法**：`/opsx:propose <change-name> [intent-description]`

- `<change-name>`：kebab-case 名称（必填）
- `[intent-description]`：1-2 句话的意图（可选）

**加载 skill**：[openspec-propose](../skills/openspec-propose/SKILL.md)

**完整流程**：
1. `openspec new change "<name>"` 建空骨架
2. `openspec status --change "<name>" --json` 解析 `applyRequires` / `artifactPaths`
3. 对每个 ready artifact：`openspec instructions <id> --change --json` → 写 `resolvedOutputPath`
4. 循环 status 直到全 ready
