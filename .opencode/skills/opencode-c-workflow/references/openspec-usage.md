# OpenSpec Agent 使用指南

本文件面向 OpenCode agent，说明如何调用 OpenSpec CLI 与 slash command 来驱动 change 生命周期。

---

## 用户命令 vs Agent 工具

| 用户聊天输入 | Agent 侧等价调用 | 说明 |
|---|---|---|
| `/opsx:explore` | `skill(name="openspec-explore")` | 探索模式，先思考再立项 |
| `/opsx:propose <name>` | `skill(name="openspec-propose")` | 一键生成 proposal + design + tasks |
| `/opsx:apply <name>` | `skill(name="openspec-apply-change")` | 按 tasks.md 实施 |
| `/opsx:archive <name>` | `skill(name="openspec-archive-change")` | 归档并同步 specs |
| `/opsx:sync <name>` | `skill(name="openspec-sync-specs")` | 同步 delta specs 到主 specs |

> 在 AI 聊天中用户可直接输入 `/opsx:*`；agent 执行时应通过 `skill(name="openspec-*")` 加载对应 skill。

---

## 初始化

```bash
openspec init
```

进入任何 change 工作前，先确认项目已初始化。如未初始化，**停止并报告**。

---

## 创建 change

### 方式 1：先探索再立项

```bash
# 或让用户在聊天中输入 /opsx:explore
skill(name="openspec-explore")
```

### 方式 2：直接 propose

```bash
# 用户输入
/opsx:propose <change-name>

# Agent 加载
skill(name="openspec-propose")
```

### 方式 3：CLI 创建

```bash
openspec new change "<change-name>"
```

---

## 获取 change 状态（核心）

```bash
openspec status --change "<change-name>" --json
```

### 关键 JSON 字段

| 字段 | 类型 | 含义 |
|---|---|---|
| `schemaName` | string | 当前 workflow schema，如 `"spec-driven"` |
| `planningHome` | object | 规划根目录，含 `changesDir` |
| `changeRoot` | string | 当前 change 目录绝对路径 |
| `actionContext` | object | 编辑上下文，含 `mode`、`allowedEditRoots` |
| `artifactPaths` | object | 各 artifact 的 `existingOutputPaths` |
| `applyRequires` | array | 实施前必须完成的 artifact ID 列表 |
| `artifacts` | array | 所有 artifact 及其 `status` (`done`/`pending`) |

**Agent 必须解析这些字段**，不要假设固定路径如 `openspec/changes/<name>/`。

---

## 获取 artifact 指令

```bash
openspec instructions <artifact-id> --change "<change-name>" --json
```

`<artifact-id>` 通常为：`proposal`、`specs`、`design`、`tasks` 等，具体以 `applyRequires` 为准。

### 返回字段

| 字段 | 含义 |
|---|---|
| `context` | 项目背景约束（给 agent 看，**不写进文件**） |
| `rules` | artifact 特定规则（给 agent 看，**不写进文件**） |
| `template` | 文件结构模板 |
| `instruction` | schema 对该 artifact 的写作指导 |
| `resolvedOutputPath` | 应写入的绝对路径 |
| `dependencies` | 依赖的已完成 artifact ID |

**原则**：`context` 和 `rules` 是约束，不是文件内容；输出文件只使用 `template` + `instruction` 的信息。

---

## 典型调用链

```
SCOPE:
  openspec new change "<name>"
  openspec status --change "<name>" --json
  openspec instructions proposal --change "<name>" --json
  → 写 proposal.md

PLAN:
  openspec status --change "<name>" --json
  openspec instructions design --change "<name>" --json
  → 写 design.md
  openspec instructions tasks --change "<name>" --json
  → 写 tasks.md

PATCH:
  skill(name="openspec-apply-change")
  → 读取 tasks.md，逐任务实施并勾选

VERIFY/REPORT:
  skill(name="openspec-archive-change")
  → 归档并同步 specs
```

---

## 常用 CLI 命令速查

| 命令 | 用途 |
|---|---|
| `openspec list --json` | 列出所有 active changes |
| `openspec show --change "<name>"` | 查看 change 摘要 |
| `openspec validate --change "<name>"` | 验证 change 完整性 |
| `openspec archive --change "<name>"` | 归档 change（agent 也可通过 skill 调用） |

---

## 错误处理

- OpenSpec CLI 缺失 → 停止："OpenSpec CLI 缺失，请运行 `npm install -g @fission-ai/openspec` 并 `openspec init`。"
- `openspec status` 返回非 0 → 停止并输出 stderr
- `resolvedOutputPath` 为空 → 停止："artifact 输出路径未解析，请检查 status JSON。"
