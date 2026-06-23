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

### 1a. Delta 头规则（**统一措辞，per AP-009 retro 2026-06-add-bb-config-print**）

> 详见 `../openspec-sync-specs/SKILL.md §6`（规则定义 + 实施细节）和 `../openspec-archive-change/SKILL.md §2.5`（触发条件 + 手动 fallback）。本节只提醒 propose 阶段的约束。

**约束**：
- **绝不**在 `proposal.md` 的 "Modified Capabilities" 段列 refactor 类型的 change（refactor 不改 behavior）
- Refactor 类型的 change 必须在 `specs/<cap>/spec.md` 写至少 1 个 `## ADDED Requirements`，documenting **architecture choice**（如 dispatch pattern、extract pattern）
- 禁止把 `## ADDED Requirements` / `## MODIFIED Requirements` 头放进 `openspec/specs/<cap>/spec.md` baseline（这是 sync 阶段的职责，per `openspec-sync-specs §6`）

### 1b. Refactor 类型（**per AP-010 retro 2026-06-refactor-bb-flip-table**）

> **背景**（AP-010）：openspec validate 强制 `at least one delta`，refactor 类型 change 无 behavior change 时会被拒。当前 workaround：refactor 必含至少 1 个 ADDED Requirement documenting architecture。openspec upstream 待加 "Pure Refactor" change type（不可在本项目解决）。

**识别 refactor 类型 change**：
- 改 HOW（实现）不 改 WHAT（行为）
- 典型特征：switch → table、extract function、inline、rename、move code
- proposal.md Why 段说"refactor / 提取 / 重构"等
- 行为对比表（design.md D5 风格）："refactor 前 X → refactor 后 Y，行为 identical"

**specs/<cap>/spec.md 必含**（per AP-010 workaround）：
- 至少 1 个 `### Requirement: <architecture choice>`
- body 描述新采用的实现模式（如"dispatch MUST be table-driven"）
- 至少 1 个 `#### Scenario: behavior identical`（断言"refactor 后 behavior unchanged"）
- **不要**列其他"behavior change" Scenario（refactor 改的是 HOW 不是 WHAT）

**示例**（per `refactor-bb-flip-table`）：
```markdown
## ADDED Requirements

### Requirement: BB Flip Dispatch Architecture
The system SHALL implement the `bb_flip` admin flip dispatch as a **table-driven pattern**...

#### Scenario: All 11 existing admin flips remain behavior-identical after refactor
- **WHEN** operator issues any of FEMU_ENABLE_GC_DELAY...FEMU_PRINT_BB_CONFIG
- **THEN** system produces the same `femu_log` string and same state changes...
```

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
