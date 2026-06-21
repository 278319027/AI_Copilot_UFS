---
name: openspec-propose
description: Stage 1 of OpenSpec 5-phase lifecycle — create a new change and generate 4 artifacts (proposal, design, specs, tasks) in dependency order. Use when user says /opsx:propose, "创建变更", or "提案".
license: MIT
compatibility: Requires openspec CLI (v1.4.1+).
metadata:
  author: openspec
  version: "2.0"
  parent: openspec-workflow
---

# OpenSpec Propose — Stage 1

创建新 OpenSpec 变更，依次生成 4 个 artifacts（proposal / design / specs / tasks），触发 Proposal Gate + Design Gate。共享概念（Iron Rules、跨切约束）见 `../openspec-workflow/SKILL.md`。

## When to Use

- 用户说 `/opsx:propose <change-name>` 或 "创建变更"
- 已有清晰的动机（Why）但还未结构化为 OpenSpec 制品
- 变更将影响 `openspec/specs/` 中一个或多个 capability

## 关键步骤

### 1. 确认输入

- 名称必须 **kebab-case**（`add-user-auth` / `refactor-ftl-mapping` 风格）
- 简短意图描述（"为什么做"），≥ 1 句话
- 询问 name 时**不替用户决定**（除非上下文明确唯一）

### 2. 创建空骨架

```bash
openspec new change "<name>"
```

- 在 `openspec/changes/<name>/` 下生成 `.openspec.yaml`
- 不创建任何 artifact 文件

### 3. 解析当前状态

```bash
openspec status --change "<name>" --json
```

读出 3 个关键结构：
- `applyRequires` — 哪些 artifact 必须完成才能进入 apply 阶段（通常是 `tasks`）
- `artifactPaths` — 各 artifact 的 `outputPath` / `resolvedOutputPath`
- `actionContext` — `mode` / `allowedEditRoots` / `requiresAffectedAreaSelection`

### 4. 逐个生成 artifact（按依赖链）

```
proposal → design + specs → tasks
```

对每个 ready 的 artifact：

```bash
openspec instructions <id> --change "<name>" --json
```

读出 `instruction` + `template` + `context` + `rules` + `resolvedOutputPath`，然后：

1. 按 `template` 结构写
2. 遵守 `instruction` 字段的 section 要求
3. **不复制** `<context>` / `<rules>` / `<project_context>` 原文到 artifact（仅作约束来源）
4. 写完立即验证 `resolvedOutputPath` 文件存在

### 5. 循环 status 直到全 ready

```bash
openspec status --change "<name>" --json
```

当 `applyRequires` 中所有项 `done` 时，进入 Stage 3（apply）由用户触发 `/opsx:apply`。

## 关键约束

- **不写应用代码** —— 本 phase 只生成 4 artifacts
- **不归档** —— 即便全 ready 也不自动 `/opsx:archive`，等用户决策
- **不复制 context 块** —— context 内的项目背景信息只能作为约束，不能粘贴到 artifact
- **kebab-case 名称** —— 不接受 snake_case / camelCase

## CLI 调用清单

```bash
openspec new change "<name>"                              # 建空骨架
openspec status --change "<name>" --json                  # 解析状态
openspec instructions <id> --change "<name>" --json       # 取 artifact instructions
openspec validate --strict --changes                      # 验证完整性（可选）
```

## 错误处理

| 错误 | 应对 |
|------|------|
| `openspec new change` 报 name 冲突 | `openspec list --json` 检查活跃变更，改名后重试 |
| `instructions <id>` 报 missingDeps | 补前置 artifact 后重试 |
| `validate` 报 template 不匹配 | 严格按 `template` 字段结构（YAML/标题层级）写 |
| `actionContext.mode == "workspace-planning"` | 停下问用户选作用域或切到 repo-local |
