---
name: openspec-sync-specs
description: Stage 4 of OpenSpec 5-phase lifecycle — merge delta specs (ADDED/MODIFIED/REMOVED/RENAMED) from changes/{id}/specs/ into openspec/specs/ baseline. Smart merge, not programmatic replacement. Use when user says /opsx:sync, "合并 spec", or "apply delta".
license: MIT
compatibility: Requires openspec CLI (v1.4.1+).
metadata:
  author: openspec
  version: "2.0"
  parent: openspec-workflow
---

# OpenSpec Sync Specs — Stage 4

将 `openspec/changes/<id>/specs/<capability>/spec.md` 中的 delta（## ADDED / MODIFIED / REMOVED / RENAMED Requirements）合并到 `openspec/specs/<capability>/spec.md` baseline。**智能合并**——不是程序化替换。

## When to Use

- 用户说 `/opsx:sync` 或 "合并 delta"
- `openspec/changes/<id>/` 已完成 apply（tasks.md 全勾选）
- 准备 review 前想先同步 baseline

## 关键步骤

### 1. 定位 delta 文件

```bash
ls openspec/changes/<id>/specs/
```

对每个 capability 子目录下的 `spec.md`，读 `## ADDED` / `## MODIFIED` / `## REMOVED` / `## RENAMED` 段。

### 2. 读 baseline

```bash
openspec show <capability>
```

或直接读 `openspec/specs/<capability>/spec.md`。

### 3. 智能合并（按段类型）

| Delta 段 | 操作 |
|----------|------|
| `## ADDED Requirements` | 在 baseline 末尾追加 `### Requirement: <name>` + `#### Scenario:` 块 |
| `## MODIFIED Requirements` | 找 baseline 中同名 `### Requirement:` 块，**整块替换**（含所有 Scenario）。头文本必须完全一致（不一致 = 归档丢失细节） |
| `## REMOVED Requirements` | 删 baseline 中对应 `### Requirement:` + 子 `#### Scenario:`。delta 必含 `**Reason:**` + `**Migration:**` |
| `## RENAMED Requirements` | 用 `FROM:` / `TO:` 对应 baseline 块重命名 |

### 4. 验证合并

```bash
openspec validate --strict --specs
```

应返回 `N passed, 0 failed`。

### 5. 保留未提及的 baseline 内容

**关键**：delta 仅声明意图，**不**全量替换 baseline。未提及的 `### Requirement:` 块**必须保留**。

## 关键约束

- **不程序化合并** —— 必须读两边再编辑，不能 `cp` delta 覆盖 baseline
- **保留未提及内容** —— delta 没说的 baseline 部分一律不动
- **MODIFIED 头文本必须完全一致** —— 否则合并后丢失原 Scenario
- **REMOVED 必须有 Reason + Migration** —— 否则 OpenSpec validate 失败
- **Scenario 强制 4 个 `#`** —— 3 个 `#` 静默失败（OpenSpec 标准）

## CLI 调用清单

```bash
openspec validate --strict --specs          # 验证 baseline
openspec show <capability>                  # 读 baseline
openspec validate --strict --changes        # 验证 delta 完整性
```

## 错误处理

| 错误 | 应对 |
|------|------|
| `openspec validate` 报 `MODIFIED header mismatch` | 比对 baseline 头文本，逐字符修齐 |
| `REMOVED` 缺 Reason/Migration | 补 `**Reason:**` + `**Migration:**` 段 |
| `## ADDED` 含 `### Requirement:` 但缺 `#### Scenario:` | 补 Scenario（强制 4 个 `#`） |
| 合并后 `validate --specs` 失败 | 检查 `#### Scenario` 数量、`SHALL`/`MUST` 规范词、4 个 `#` |
| 多个 delta 文件改同一 capability | 合并时按段顺序应用，记录合并顺序 |
