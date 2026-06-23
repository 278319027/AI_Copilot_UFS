---
name: opsx:explore
description: Stage 2 of OpenSpec 5-phase lifecycle — think with user, investigate, compare options. Do NOT write implementation code. Loads openspec-explore skill.
---

# /opsx:explore

与用户一起思考/调研。**绝不写实现代码**。

**用法**：`/opsx:explore [topic]`

- 无参数：盘点活跃变更（`openspec list --json`）+ 提议建立新 proposal
- `[topic]`：聚焦调研某主题

**入口操作**：
1. `skill(name="openspec-explore")` — 加载 explore skill
2. 按 skill 指引执行：调研 → 对比选项 → 产出 design.md 思考段

**调研手段**（按需选用）：
- **CodeGraph**：`codegraph explore <area>` / `codegraph where <func>`
- **Graphify**：`graphify query "<问题>"` / `graphify explain "<概念>"`
- **cscope**：函数指针/宏补充
- **读 specs**：`openspec show <capability>` —— 行为基线优先

**约束**：
- 绝不写应用代码（`*.c` / `*.h`）
- 可更新 `openspec/changes/<id>/design.md` 探索段
- 不自动建变更或归档
