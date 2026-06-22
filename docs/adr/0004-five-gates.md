# ADR 0004: 五级门禁（Proposal → Design → BUILD → Review → Archive）

- **状态**：Accepted
- **更新日期**：2026-06-22（新增 BUILD Gate）
- **决策者**：zsf 项目维护者
- **适用范围**：所有 OpenSpec 变更

## 背景

zsf 项目需要一套强制性的门禁体系以保证 AI 产出的纪律。最初设计是四级门禁：Proposal → Design → Review → Archive。2026-06-22 的 `add-gc-stats-flip` 变更暴露缺口：代码正确但纪律缺失，方法论遵循度仅 70%。AI 直接编码而未加载 Superpowers 验证 skill。

## 考虑过的选项

### 选项 A：保持四级门禁

AI 自觉按需加载 skill，无强制 BUILD 阶段检查。

**优点**：流程简单。
**缺点**：纪律松弛，AI 容易跳过关键 skill 加载。

### 选项 B：增加 BUILD Gate（采用）

在 Design 与 Review 之间新增 BUILD Gate，强制 AI 在编码前加载所有必需的 Superpowers 工程纪律 skill。

**优点**：
- 与 Proposal/Design/Review/Archive Gate 同级强制
- 防止"代码正确但纪律缺失"的失败模式
- 不增加工件负担（BUILD Gate 不产生新 spec 工件）

**缺点**：门禁总数从 4 增加到 5，认知负担略增。

### 选项 C：增加更细粒度门禁

例如：Review 阶段拆分为 Spec Review + Quality Review + Final Review。

**优点**：更细粒度。
**缺点**：过度设计；现有 Review 阶段已含 spec compliance + code quality。

## 决策

采用选项 B。BUILD Gate 强制 AI 加载 3 个 skill（verification-before-completion、executing-plans、test-driven-development），缺一不可编码。

```c
// BUILD Gate 强制加载清单
- [ ] superpowers-verification-before-completion
- [ ] superpowers-executing-plans
- [ ] superpowers-test-driven-development（或 test-after 路径）
- [ ] 测试计划已写入 tasks.md / design.md（不可仅口头确认）
```

## 后果

- 5 级门禁：Proposal → Design → **BUILD** → Review → Archive
- BUILD Gate 必须在 coding 前通过，否则禁止编码
- 人工审查点：AI 声明"BUILD Gate 通过"时必须列出已加载的 skill 名称

## 验证

- `sd-firmware-copilot/SKILL.md § BUILD Gate` 完整定义
- 2026-06-22 后所有 OpenSpec 变更应通过 5 级门禁
