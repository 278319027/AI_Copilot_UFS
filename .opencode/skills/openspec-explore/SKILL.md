---
name: openspec-explore
description: Stage 2 of OpenSpec 5-phase lifecycle — think with user, investigate codebase, compare options, draw diagrams. Do NOT write implementation code. Use when user says /opsx:explore, "探索", "调研", or "理解现有实现".
license: MIT
compatibility: Requires openspec CLI (v1.4.1+).
metadata:
  author: openspec
  version: "2.0"
  parent: openspec-workflow
---

# OpenSpec Explore — Stage 2

与用户一起思考/调研。**绝不写实现代码**。可创建或更新 OpenSpec artifacts（如 design.md 探索段），但**绝不**写应用代码或修改 `openspec/specs/`。

## When to Use

- 用户说 `/opsx:explore` 或 "先调研一下"
- 复杂需求需要先理解现有代码/设计
- 多个备选方案需对比权衡
- 无活跃 OpenSpec 变更时也可自由探索

## 关键步骤

### 1. 开局盘点

```bash
openspec list --json
```

判断状态：
- **无活跃变更** → 自由思考；可提议"建议建一个 proposal 跟踪此次发现"
- **有活跃变更** → 读 `status --change <name> --json` + `artifactPaths.<id>.existingOutputPaths`

### 2. 调研手段（按需选用）

- **CodeGraph**：`codegraph explore <area>` / `codegraph callers <func>` / `codegraph impact <symbol>` —— 调用图/影响分析
- **Graphify**：`graphify query "<问题>"` / `graphify explain "<概念>"` —— 知识图谱/概念关系
- **cscope**（CodeGraph 盲区补充）：`cscope -d -L2 <func>`（调用者）/ `-L4 <MACRO>`（宏）
- **读 specs**：`openspec show <capability>` —— 行为基线优先于代码
- **读代码**：仅当 specs + CodeGraph 都不足时
- **画图**：ASCII / mermaid 表达架构或流程

### 3. 输出形式

可选项（**不强制全部**）：

- 设计文档片段到 `openspec/changes/<id>/design.md`（如属当前变更）
- 决策记录（ADR 风格）到 `design.md` 末尾的 `## Open Questions` 段
- 对比表格 / mermaid 流程图（在 chat 中输出）

### 4. 提议但不决定

发现重要 insight 后：
- 提议："建议建一个 proposal 跟踪 X"
- 提议："design.md 应包含 Y 决策"
- 提议："现有 spec.md 缺失 Z Requirement"

**让用户决定**，不自动建变更。

## 关键约束

- **绝不写应用代码** —— 探索阶段不修改 `*.c` / `*.h` / 任何目标代码
- **可更新 artifacts** —— 当用户明确要求时，可写/改 `openspec/changes/<id>/` 下的 `design.md` / `proposal.md` 等
- **不清就继续挖** —— 不假装懂，不编造调用关系
- **不自动归档** —— 决策明确时提议，但让用户触发

## CLI 调用清单

```bash
openspec list --json                          # 盘点活跃变更
openspec status --change "<name>" --json      # 读指定变更的 artifact paths
openspec show <capability>                    # 读 baseline spec
```

## 错误处理

| 错误 | 应对 |
|------|------|
| CodeGraph MCP 不可用 | 回退到 grep + cscope + 读代码 |
| Graphify 图谱陈旧或缺失 | 提示运行 `graphify update <subdir>` 或优雅降级到 grep |
| 用户中途想进入实现 | 提示"先 `/opsx:propose <name>` 创建变更，再 `/opsx:apply`" |
