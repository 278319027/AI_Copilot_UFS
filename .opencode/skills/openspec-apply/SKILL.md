---
name: openspec-apply
description: Stage 3 of OpenSpec 5-phase lifecycle — implement tasks.md one task at a time, mark - [ ] as - [x] after each. Read contextFiles first. Use when user says /opsx:apply, "实施", or "按 tasks 编码".
license: MIT
compatibility: Requires openspec CLI (v1.4.1+).
metadata:
  author: openspec
  version: "2.0"
  parent: openspec-workflow
---

# OpenSpec Apply — Stage 3

按 `openspec/changes/<id>/tasks.md` 逐项实施。每完成一个 task 勾选 `- [x]`，触发 Review Gate。共享概念（Iron Rules、跨切约束）见 `../openspec-workflow/SKILL.md`。

## When to Use

- 用户说 `/opsx:apply [name]` 或 "开始实现"
- `tasks.md` 已生成且所有前置 artifact（proposal / design / specs）done
- 准备写生产代码

## 关键步骤

### 1. 选定变更

```bash
openspec list --json
```

- 单一活跃变更 → 直接用
- 多个活跃变更 → 公告 `Using change: <name>`，让用户确认
- 无活跃变更 → 提示先 `/opsx:propose`

### 2. 解析状态

```bash
openspec status --change "<name>" --json
```

读出：
- `schemaName` — 当前 schema
- `actionContext.mode` — `repo-local` / `workspace-planning`
- `actionContext.allowedEditRoots` — 允许编辑的根

### 3. 读取 contextFiles

```bash
openspec instructions apply --change "<name>" --json
```

读 `contextFiles` —— **不只是 `tasks.md`**，通常含 `proposal.md` / `design.md` / 相关 baseline specs。

按顺序读完整 context，再开始改代码。

### 4. 处理状态分支

| status 状态 | 行动 |
|------------|------|
| `blocked`（缺 artifacts） | 提示补前置 artifact，再回 `/opsx:propose` |
| `in_progress` | 继续当前 task |
| `all_done`（全勾选） | 提示用户进入 `/opsx:archive` |

### 5. 逐个 pending task 实施

```
对每个 `- [ ] N.M` task：
  1. 读 task 描述 + 关联 spec Requirement
  2. 最小改动（不扩大需求）
  3. 改完勾选 `- [x] N.M`
  4. 跑相关验证（编译/测试）
  5. 下一个 task
```

## 关键约束

- **实施前必读 `contextFiles`** —— proposal / design / 相关 baseline spec 必看
- **最小改动** —— 不在 apply 阶段加未在 tasks.md 中的功能
- **每个 task 完跑验证** —— 不批量勾选
- **TDD 双路径**（嵌入 C）：
  - **Path A**（纯逻辑）：红→绿→重构，先写失败测试
  - **Path B**（硬件依赖/MMIO/ISR/DMA）：BUILD 编译即验证，FEEDBACK 阶段再测
- **工作区护栏**：`actionContext.mode == "workspace-planning"` 且 `allowedEditRoots` 空 → 停下让用户选作用域

## Workspace Guard（必检）

```bash
# 在每次重大编辑前检查
openspec status --change "<name>" --json | jq '.actionContext.mode'
```

- `"repo-local"` → 正常编辑
- `"workspace-planning"` 且 `allowedEditRoots` 为空 → **停下**问用户：
  - 选项 A：选作用域（`openspec workspace`）
  - 选项 B：切到 repo-local 模式
- 切勿在 workspace-planning 下编辑未授权路径

## CLI 调用清单

```bash
openspec list --json                                 # 选变更
openspec status --change "<name>" --json             # 解析状态
openspec instructions apply --change "<name>" --json # 取 contextFiles + 任务列表
```

## 错误处理

| 错误 | 应对 |
|------|------|
| status 报 `blocked` | 回 `/opsx:propose` 补 artifacts |
| task 描述不清 | 暂停问用户，**不猜** |
| task 实现暴露 design 问题 | 暂停回 `/opsx:explore` 或 `/opsx:propose`，**不强行改** |
| 编译/测试失败 | 启用 `superpowers-systematic-debugging`：先复现、读错误、查变更、形成假设、最小验证 |
| `actionContext.mode == "workspace-planning"` | 停下问作用域 |
