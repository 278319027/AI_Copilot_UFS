---
name: opsx:continue
description: Stage 1b of OpenSpec 5-phase lifecycle — create the next pending artifact in the change's dependency graph. Use after /opsx:new or after manually editing one artifact. Loads openspec-workflow skill.
---

# /opsx:continue

按依赖图（DAG）生成**下一个待完成**的 artifact。适用于"我手动写了一个，想让 AI 接着写下一个"或"先用 `/opsx:new` 建空壳，现在逐个生成"的场景。

**用法**：`/opsx:continue [change-name]`

- 无参数：取唯一活跃变更
- `[change-name]`：指定变更

**入口操作**：
1. `skill(name="superpowers-using-superpowers")` — 加载纪律约束
2. `skill(name="openspec-workflow")` — 加载概念层（含依赖图规则）
3. `skill(name="openspec-propose")` 或对应 phase skill — 生成该 artifact 的具体指引
4. 按 skill 指引：解析 `openspec status --change --json` → 找下一个 `ready` artifact → 生成

**完整流程**：
1. `openspec status --change "<name>" --json` 解析当前状态
2. 找 `applyRequires` 中 `status == "ready"` 的 artifact
3. 校验前置依赖（`requires: [...]`）都已 done
4. `openspec instructions <artifact-id> --change --json` 取 `resolvedOutputPath`
5. 写入 artifact 内容（遵循对应 phase skill 的规则）
6. 跑 `openspec validate --strict --changes` 验证

**生成顺序**（按 OpenSpec `spec-driven` schema 的依赖图）：

```
proposal ──→ specs ──→ design ──→ tasks
   ▲           │          │         │
   └───────────┴──────────┴─────────┘
            (任一可回溯更新)
```

**关键约束**：
- 必须先有 `proposal.md` 才能生成 `specs/` delta
- 必须先有 `proposal.md` 才能生成 `design.md`
- 必须先有 `specs/` 和 `design.md` 才能生成 `tasks.md`
- 任何 artifact 都可以被更新（OpenSpec 是 fluid 工作流，不是瀑布）

**校验命令**：
```bash
openspec status --change "<name>" --json
openspec validate --strict --changes
```

**与 `/opsx:ff` 的差异**：

| 命令 | 行为 | 适用场景 |
|------|------|----------|
| `/opsx:continue` | 一次生成 1 个 artifact | 想分步审阅 / 手动调整 |
| `/opsx:ff` | 一次生成所有 artifacts | 已知方案，想快 |
