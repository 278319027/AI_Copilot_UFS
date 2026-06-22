# ADR 0002: 四阶段闭环（KNOW → PLAN → BUILD → FEEDBACK）

- **状态**：Accepted
- **日期**：2025-12-20
- **决策者**：zsf 项目维护者
- **适用范围**：所有 AI 辅助编程任务

## 背景

AI 辅助 SSD 固件开发需要一个标准化的工程流程。传统软件工程的瀑布模型（需求→设计→编码→测试→发布）过于线性，不适合 AI 迭代；纯敏捷（Sprint 节奏）又太轻量，无法保证 AI 产出的纪律。

## 考虑过的选项

### 选项 A：瀑布模型

线性流程，阶段间有明确门禁。

**优点**：每阶段产出明确，AI 易遵守。
**缺点**：每次小改动都要走完所有阶段；不适应 AI 快速迭代的特性。

### 选项 B：纯敏捷 Sprint

短周期迭代，AI 自组织。

**优点**：迭代快。
**缺点**：AI 没有自组织能力；缺乏铁律约束会产出不一致的代码。

### 选项 C：四阶段闭环（采用）

`KNOW → PLAN → BUILD → FEEDBACK`，强调循环而非线性：每次变更都从 KNOW 重新开始（理解当前状态），FEEDBACK 完成后产生新的 KNOW。

**优点**：
- 与 AI 的特性匹配：每次任务都从重新理解开始（context window 重置）
- 五级门禁（Proposal / Design / BUILD / Review / Archive）保证纪律
- KNOW 阶段用 CodeGraph + Graphify 工具支撑，AI 能真正"读懂"代码
- FEEDBACK 阶段用 OpenSpec + Graphify update 保持图谱新鲜

**缺点**：四阶段流程需 AI 理解并切换工作模式；初学者需学习。

## 决策

采用选项 C。

- **KNOW**：理解现有系统（Graphify + CodeGraph）
- **PLAN**：写 proposal / design / tasks（OpenSpec CLI）
- **BUILD**：实现 + 测试（Superpowers + sd-firmware-copilot 域规则）
- **FEEDBACK**：审查 + 归档（OpenSpec archive + Graphify update）

每个变更必须走完一圈，不允许跳过 KNOW 或 FEEDBACK。

## 后果

- AI 每次任务都按 4 阶段顺序执行
- 2 个已归档 OpenSpec 变更证明闭环可工作
- BUILD Gate（2026-06-22 新增）加强 AI 编码前纪律检查

## 验证

- `sd-firmware-copilot/SKILL.md` 顶部流程图
- `openspec-workflow/SKILL.md` Iron Rules
- 2 个已归档 OpenSpec 变更（`openspec/changes/archive/2026-06-22-*/`）
