# Architecture Decision Records (ADR)

本目录记录 zsf 项目的关键架构决策。每条 ADR 解释背景、考虑过的选项、决策理由与后果。

## 索引

| # | 标题 | 状态 | 日期 |
|---|------|------|------|
| [0001](0001-methodology-target-repo-separation.md) | 分层架构方法论与目标代码库解耦 | Accepted | 2025-12-20 |
| [0002](0002-four-stage-loop.md) | 四阶段闭环（KNOW → PLAN → BUILD → FEEDBACK） | Accepted | 2025-12-20 |
| [0003](0003-tdd-to-test-after.md) | TDD → test-after + 注入验证 | Accepted | 2026-06-22 |
| [0004](0004-five-gates.md) | 五级门禁（Proposal → Design → BUILD → Review → Archive） | Accepted | 2026-06-22 |

## 新增 ADR 模板

新增 ADR 时复制以下骨架，编号递增：

```markdown
# ADR XXXX: <简短标题>

- **状态**：Proposed | Accepted | Deprecated | Superseded by ADR-YYYY
- **日期**：YYYY-MM-DD
- **决策者**：<谁做的决策>
- **适用范围**：<影响范围>

## 背景

<什么场景下要决策？>

## 考虑过的选项

### 选项 A：<选项名>

<做法>

**优点**：...
**缺点**：...

### 选项 B：<选项名>（采用）

...

## 决策

采用选项 B。<一句话理由>

## 后果

- <决策带来的变化>
- ...

## 验证

- <如何确认决策落地>
```

## ADR 状态机

```
Proposed ──→ Accepted ──→ Deprecated
                │
                └─→ Superseded by ADR-XXXX
```

- **Proposed**：草案，待讨论
- **Accepted**：已采用，正在生效
- **Deprecated**：已弃用，但保留历史
- **Superseded**：被新 ADR 取代，参考编号
