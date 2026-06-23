---
name: openspec-archive-change
description: Stage 5 of OpenSpec 5-phase lifecycle — finalize change by moving changes/{id}/ to changes/archive/YYYY-MM-DD-{id}/. Check artifact completion and task checkboxes first. Use when user says /opsx:archive, "归档", or "提交变更".
license: MIT
compatibility: Requires openspec CLI (v1.4.1+).
metadata:
  author: openspec
  version: "2.0"
  parent: openspec-workflow
---

# OpenSpec Archive Change — Stage 5

完成 OpenSpec 变更的最后一步：把 `openspec/changes/<id>/` 移动到 `openspec/changes/archive/YYYY-MM-DD-{id}/`，触发 Archive Gate。共享概念（Iron Rules、跨切约束）见 `../openspec-workflow/SKILL.md`。

## When to Use

- 用户说 `/opsx:archive [name]` 或 "归档"
- `tasks.md` 全勾选
- 准备合并到主分支并发布

## 关键步骤

### 1. 检查 artifact 完成 + 任务勾选 + **强制 review/verify 产物**（**强校验**）

```bash
openspec status --change "<name>" --json
```

读出：
- `applyRequires` 全部 `done`
- `tasks.md` 中 `- [x]` 数量 ≥ `- [ ]` 数量

**额外强制校验**（不通过则**禁止**进入步骤 2）：

```bash
# verify-report.md 必须存在且 6/6 PASS
test -f openspec/changes/<id>/verify-report.md || { echo "ERROR: verify-report.md missing — run /opsx:verify first"; exit 1; }

# review.md 必须存在（占位即可，Review Gate 时填充）
test -f openspec/changes/<id>/review.md || { echo "ERROR: review.md missing — create placeholder"; exit 1; }

# verify-report.md 必含 "总体判定: READY"
grep -q "总体判定.*READY\|READY FOR ARCHIVE\|✅ READY" openspec/changes/<id>/verify-report.md || { echo "ERROR: verify-report.md not READY"; exit 1; }

# review.md 必含审查人签字
grep -qE "签字|Signed|Reviewer|审查人" openspec/changes/<id>/review.md || { echo "ERROR: review.md missing reviewer signature"; exit 1; }
```

> **设计意图**（per `docs/retrospectives/2026-06-add-crt-mapping-cache.md` AP-005）：review.md 是审计追踪的强制产物；AI 不能自批自审，必须有人工审查记录。

### 1.5 检查 delta 是否已 sync 到 baseline（**新增，per M-8 验证发现**）

> **背景**（M-8 verification 发现）：AI 在 archive 时可能跳过 sync 步骤，导致 spec delta 留在 archive 但不在 baseline，造成审计追踪的 spec 与实际系统行为不一致。

```bash
# 如果 change 有 spec delta，必须先 sync
if [ -d openspec/changes/<id>/specs/ ]; then
  # 对比 baseline 与 delta 的 Requirements 数量
  BASELINE_REQS=$(grep -c "^### Requirement:" openspec/specs/ftl-mapping/spec.md 2>/dev/null || echo 0)
  DELTA_REQS=$(grep -c "^### Requirement:" openspec/changes/<id>/specs/*/spec.md 2>/dev/null | awk -F: '{s+=$2} END {print s}')

  # 检查 baseline 是否已包含 delta 的所有 Requirement
  for req in $(grep "^### Requirement:" openspec/changes/<id>/specs/*/spec.md | sed 's/^### Requirement: //'); do
    if ! grep -q "### Requirement: $req" openspec/specs/*/spec.md 2>/dev/null; then
      echo "ERROR: Requirement '$req' not yet synced to baseline"
      echo "Run: openspec sync --change <id> first"
      exit 1
    fi
  done
fi
```

> **强制**：`/opsx:archive` 在 sync 之前调用 → 拒绝执行。

### 2. 评估 delta 是否先 sync

判断：
- 若 `openspec/changes/<id>/specs/<capability>/spec.md` 含 `## ADDED` / `## MODIFIED` 等 delta → 提议先 `/opsx:sync`
- 若无 delta（纯 skill/command 重构）→ 可直接 archive

**让用户决定**：
- 选项 A：先 sync 再 archive（保留变更意图在 baseline）
- 选项 B：archive without sync（baseline 不动）

### 2.5 Manual sync fallback（**新增，per AP-009 in retro 2026-06-add-bb-config-print**）

> **背景**（AP-009 发现）：`openspec sync` CLI 缺失（`error: unknown command 'sync'`），slash 命令 `/opsx:sync` 仅在 OpenCode IDE 内可用。在 shell / CI / 无 IDE 环境下，需要 manual fallback。

**触发条件**：
- `openspec sync <change-id>` 返回 `unknown command 'sync'` 或类似错误
- 或在 OpenCode IDE 外的 shell / CI 环境中执行
- 或 baseline 未含 delta 的 Requirement（步骤 1.5 报"not yet synced"）

**操作**：

```bash
bash scripts/sync_change.sh <change-id>
```

脚本行为（per `scripts/sync_change.sh`）：
1. 读 `openspec/changes/<id>/specs/<cap>/spec.md`（delta）
2. 检测 delta 类型（v1 仅支持 `## ADDED Requirements`；其他类型显式错误）
3. **去掉 delta 头**（`## ADDED Requirements`）—— 关键！绝不能复制到 baseline（否则 validate 报"Delta headers are only valid inside openspec/changes/..."）
4. 把 Requirement + Scenarios 插入 baseline `openspec/specs/<cap>/spec.md` 的 `## Requirements` 段末尾
5. 自动运行 `openspec validate --strict --specs`；失败则回滚（从 `.sync_change.bak` 恢复）
6. 退出码：0=成功, 1=失败, 2=no-op

**关键约束**（避免 AP-009 重演）：
- **绝不**把 `## ADDED Requirements` / `## MODIFIED Requirements` 等 delta 头复制到 baseline
- **绝不**程序化覆盖 baseline —— 智能匹配 `## Requirements` 段
- 失败时自动回滚（基于 `.sync_change.bak` 备份）
- v1 仅支持 `## ADDED`；MODIFIED/REMOVED/RENAMED 需手动执行

**验证**（sync 后必做）：
```bash
openspec validate --strict --specs          # 必须 3/3 PASS
git diff openspec/specs/                    # 检查只有 Requirement 进了 baseline，无 delta 头
```

### 3. 移动目录

```bash
TODAY=$(date +%Y-%m-%d)
mv openspec/changes/<id>/ openspec/changes/archive/${TODAY}-<id>/
```

**保留 `.openspec.yaml`** 在移动后的目录内（不要 `-r` 删除隐藏文件）。

### 4. 提交（git）

```bash
git add openspec/changes/
git commit -m "chore(spec): archive <id>"
```

**commit 格式必须**：`chore(spec): archive {change-id}`（与 `superpowers-verification-before-completion` 一致）。

### 5. 验证归档

```bash
openspec list --json
```

- 活跃变更列表中应不再有 `<id>`
- `openspec/changes/archive/YYYY-MM-DD-<id>/` 应存在并含 `proposal.md` / `design.md` / `tasks.md`（如有）+ `.openspec.yaml`

## 关键约束

- **不自动 archive** —— 即便 tasks 全勾选，也必须用户明确决策
- **不删 `openspec/changes/` 条目** —— 永远用 `mv` 到 `archive/`，禁止 `rm -rf`
- **commit 格式固定** —— `chore(spec): archive {change-id}`
- **保留 `.openspec.yaml`** —— OpenSpec 用它反查 artifact schema
- **Workspace guard**：`actionContext.mode == "workspace-planning"` → 跳过

## CLI 调用清单

```bash
openspec list --json                              # 盘点活跃变更
openspec status --change "<name>" --json          # 解析 artifact 状态
openspec validate --strict --specs                # baseline 校验（若 sync 过）
mv openspec/changes/<id>/ openspec/changes/archive/YYYY-MM-DD-<id>/
git add openspec/changes/ && git commit -m "chore(spec): archive <id>"
```

## 错误处理

| 错误 | 应对 |
|------|------|
| 仍有 `- [ ]` 未勾选 | 警告用户，**不归档**。让用户决定：(a) 继续完成 (b) 强制 archive（不推荐） |
| `applyRequires` 含非 done 项 | 警告并阻止 archive |
| delta 存在但未 sync | 提示先 `/opsx:sync` 或让用户显式确认 archive-without-sync |
| `openspec sync` CLI 缺失（`unknown command 'sync'`）| 用 `bash scripts/sync_change.sh <change-id>` fallback（见 §2.5）|
| 目标目录 `archive/YYYY-MM-DD-<id>/` 已存在（重复 archive） | 改名追加 `-v2` 或检查是否已 archive 过 |
| `actionContext.mode == "workspace-planning"` | 跳过 archive，让用户选作用域 |
