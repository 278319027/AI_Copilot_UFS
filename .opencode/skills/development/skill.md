---
name: development
description: BUILD 阶段：AI 辅助编码实现，委托 Superpowers 工程纪律 + CodeGraph 影响分析
---

# 开发流程

本 Skill 是 BUILD 阶段的**薄适配器**。通用工程纪律委托给 [Superpowers](../superpowers/SKILL.md)，影响分析委托给 CodeGraph，本文件只定义本项目上下文中的「前后置」。

## 职责

- **Pre-execution（SSD 领域）：** CodeGraph 影响范围查询；对照 `openspec/specs/` 基线声明 `specs/` 增量。
- **Execution（Superpowers 纪律）：** 调度编码子任务，强制 TDD + 验证完成。
- **Post-execution（SSD 领域）：** 更新 CodeGraph 索引，保持图谱新鲜。

## 前置检查

- 确认 Design Gate 已通过（`design.md` 完整 + 待确认清单已逐项确认）
- 运行 CodeGraph 确认影响范围（见下表）
- 确认 `openspec/changes/{id}/specs/` 增量已声明

| 场景 | 工具 |
|------|------|
| 修改函数签名前 | `codegraph callers` |
| 修改结构体前 | `codegraph symbol_search` + `find_by_imports` |
| 修改头文件前 | `codegraph find_by_imports` |
| 新增模块前 | `codegraph dependency_graph` |
| 函数指针 / 宏 | `cscope -d` 补充 |

## 实现流程

1. 按 `tasks.md` 顺序执行，每完成一个 task 立即标记 `[x]`
2. 每个 task 严格 **TDD 红→绿→重构**（Superpowers `test-driven-development`）
3. 每个 task 完成后跑测试 + 编译（Superpowers `verification-before-completion`）
4. 全部 task 完成后：执行 `codegraph update` 更新调用图

子代理调度策略：

- 任务相互独立 → `superpowers:subagent-driven-development`
- 任务串行依赖 → `superpowers:executing-plans`
- 涉及 bug 修复 → `superpowers:systematic-debugging`
- 新功能首次实现 → `superpowers:brainstorming`

## 子代理调度契约

子代理 dispatch prompt 必须包含：

1. `proposal.md` + `specs/` 增量（明确「要实现什么」）
2. `design.md` 中的 CodeGraph 影响图（明确「改动爆炸半径」）
3. 本任务对应的 `tasks.md` 切片
4. SSD 领域约束（并发、NVMe 错误处理、FTL 不变量）参考 `.opencode/memory/`
5. 显式指令：每个完成声明必须附 `test-driven-development` + `verification-before-completion` 证据

子代理报告必须包含：测试命令、命令输出、diff。无测试证据 = 不接受，重派。

## 关键约束

- **不验证不宣称完成** — 每个 task 完成声明必须附测试命令的实际输出
- **无失败测试不写实现** — TDD 红→绿→重构，禁用「先写后补测试」
- **修改前必查 CodeGraph** — 任何函数签名 / 结构体 / 头文件变更前必查影响
- **小任务原则** — 每次实现 200~500 行，不扩大需求
- **不引入不必要重构** — 一个 task 只做一件事
