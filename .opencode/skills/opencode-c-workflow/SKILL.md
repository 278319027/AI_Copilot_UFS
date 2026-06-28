---
name: opencode-c-workflow
description: Graph-constrained spec-first C programming workflow. Integrates OpenSpec (scoping), CodeGraph/Graphify (structure), and Superpowers (execution) for safe, efficient C code changes. Use for any C fix, feature, or refactor in graph-aware repos.
license: MIT
compatibility: Requires OpenSpec CLI, CodeGraph MCP server, Graphify CLI, and Superpowers skills.
metadata:
  author: opencode-c-workflow
  version: "1.1"
---

# Opencode C Workflow — 图约束的规范优先 C 编程工作流

## 概述

本 skill 是一个**编排器**，本身不直接写代码，而是把一次 C 语言改动约束在六阶段流水线中：

```
SCOPE → GROUND → PLAN → PATCH → VERIFY → REPORT
```

每个阶段都把具体工作委托给更专业的 skill 或工具：OpenSpec 负责规范，Graphify/CodeGraph 负责结构分析，Superpowers 负责执行纪律。

## 何时使用

**必须使用** 的场景：
- C 代码的 bug 修复、功能新增、重构
- 触及 2 个及以上文件/函数的改动
- 接口/API 变更

**可跳过** 的场景：
- 单行拼写/注释修改
- 纯配置文件改动

## 环境检查（Hard Stop）

进入 SCOPE 前，确认以下工具可用。任一缺失或故障，**立即停止并报告**缺项：

| 工具 | 检查命令 | 缺失/故障时的报告模板 |
|---|---|---|
| OpenSpec | `openspec --version` | "OpenSpec CLI 缺失或不可用，无法创建/管理 change。请运行 `npm install -g @fission-ai/openspec` 并 `openspec init`。" |
| CodeGraph | `.codegraph/graph.db` 存在且 MCP 可连接 | "CodeGraph 数据库缺失或 MCP 无法连接。请运行 `codegraph build <project>`。" |
| Graphify | `graphify-out/graph.json` 存在 | "Graphify 知识图缺失。当前workflow要求先构建图；请运行 `graphify extract .`。" |
| Superpowers skills | `skill(name="superpowers-using-superpowers")` | "必需的 Superpowers skill 未安装。请确认 .opencode/skills/superpowers-* 目录包含 SKILL.md。" |

> **原则**：不降级、不绕过。工具缺失就停止，明确告诉用户缺什么。

## Phase 1: SCOPE — 定义改什么

目标：在触碰代码前冻结 scope。

| 步骤 | 工具/Skill | 命令 |
|---|---|---|
| 1.1 | 需求澄清 | `skill(name="superpowers-brainstorming")`（需求模糊时） |
| 1.2 | 探索或立项 | `skill(name="openspec-explore")` 或 `skill(name="openspec-propose")` |
| 1.3 | 获取 enriched instructions | `openspec instructions <artifact> --change <name> --json` |
| 1.4 | 冻结 scope | 确认 `scope.files`、约束、验收标准、测试计划 |

**Hard stop**：OpenSpec 缺失或 scope 不清。禁止进入 GROUND。

## Phase 2: GROUND — 先图后码

目标：在读源码之前，先理解依赖结构。

**图优先原则**：只要 `graphify-out/graph.json` 存在，必须先查图再读源码。图是预计算的地图；只在图指出的地方读源码。

| 步骤 | 视图 | 工具/命令 |
|---|---|---|
| 2.1 | 宏观视图 | `graphify query "<task>" --budget 1500` |
| 2.2 | 关系检查 | `graphify path "<A>" "<B>"` |
| 2.3 | 节点深潜 | `graphify explain "<concept>"` |
| 2.4 | 微观视图 | `codegraph_context("<function>")` |
| 2.5 | 爆炸半径 | `codegraph_fn_impact("<function>", depth=3)` |
| 2.6 | 安全检查 | `codegraph_find_cycles()` |
| 2.7 | 复杂度检查 | `codegraph_complexity(above_threshold=true)` |
| 2.8 | 语义搜索 | `codegraph_semantic_search("<concept>")` |

**Hard stop**：
- 图的证据与 scope 矛盾 → 停止并解决差异。
- Graphify 数据存在但未先咨询 → 停止。
- CodeGraph/Graphify 故障 → 停止并报告。

## Phase 3: PLAN — 设计变更

目标：明确到具体文件、函数、验证命令。

| 步骤 | 产出/动作 | 工具 |
|---|---|---|
| 3.1 | 编写 `design.md` | OpenSpec |
| 3.2 | 编写 `tasks.md` | OpenSpec |
| 3.3 | 头文件影响分析 | `codegraph_file_deps("<header>")` |
| 3.4 | 内存预算 | 人工估算（栈/堆/ISR 影响） |
| 3.5 | 预飞检查 | `codegraph_diff_impact(staged=true)` |
| 3.6 | 计划评审 | `skill(name="superpowers-writing-plans")` |

**Hard stop**：计划范围超出原始 scope → 重新定界或拒绝。

## Phase 4: PATCH — 安全实施

目标：最小改动、逐任务验证。

| 步骤 | 工具/Skill | 命令 |
|---|---|---|
| 4.1 | 隔离工作区 | `skill(name="superpowers-using-git-worktrees")` |
| 4.2 | 应用任务 | `skill(name="openspec-apply-change")` |
| 4.3 | 逐任务 TDD | `skill(name="superpowers-test-driven-development")` |
| 4.4 | CI gate | `codegraph_check(staged=true)` |
| 4.5 | 爆炸半径复核 | `codegraph_diff_impact(staged=true)` |

C 固件 TDD 约定：
- **Test** = 编译 + 运行 sim/单元测试 + 断言不变量
- **Mock** = stub 硬件依赖（寄存器、DMA、ISR 标志）
- **Refactor** = 重命名/提取；无新测试不得改变行为

**Hard stop**：patch 触及 scope 外文件 → revert 并重新定界。

## Phase 5: VERIFY — 证明正确性

目标：没有证据就不能声称完成。

| 步骤 | 动作 | 命令 |
|---|---|---|
| 5.1 | 构建 | `make clean && make` |
| 5.2 | 运行测试 | `make test` 或项目指定测试命令 |
| 5.3 | 诊断 | `lsp_diagnostics(filePath="<changed_file>")` |
| 5.4 | 回归检查 | `codegraph_diff_impact(staged=true)` |
| 5.5 | 刷新图 | `graphify update .` |
| 5.6 | 完成验证 | `skill(name="superpowers-verification-before-completion")` |

## Phase 6: REPORT — 收尾归档

| 步骤 | 工具/Skill | 命令 |
|---|---|---|
| 6.1 | Code review | `skill(name="superpowers-requesting-code-review")` |
| 6.2 | 归档 | `skill(name="openspec-archive-change")` |
| 6.3 | 清理 | `skill(name="superpowers-finishing-a-development-branch")` |

## 硬规则（不可协商）

### 架构纪律
- **不投机性重构**：只改 scope 要求的内容。
- **不发明新架构**：遵循现有模式。
- **不编辑 scope 边界外文件**：scope 冻结后具有约束力。
- **无隐式类型转换**：所有 cast 必须显式。

### 图纪律
- **Graphify 存在则先用**：禁止在查图前浏览源码。
- **CodeGraph 可用则 pre-flight**：每次 commit 前检查循环依赖 + 爆炸半径。
- **图与规范冲突时停止**：解决后方可继续。

### C 语言纪律（详见 `references/c-rules.md`）
- ISR 内零分配；静态分配或内存池。
- 禁止递归。
- 所有 `switch` 必须有 `default`。
- 整数类型显式：`uint32_t`、`int16_t` 等；禁止裸 `int`/`long`。
- ISR 最小化：仅设标志/推队列。
- DMA 缓冲区 cache-line 对齐。
- 公共头文件变更需头文件影响评审。

### 测试纪律
- 强制 TDD：先写测试，看失败，再实现。
- 每个 bug 修复附带回归测试。
- 优先 host-side 模拟。

## 参考文件

- `references/workflow.md` — 执行顺序、硬停止条件与 Quick Checklist
- `references/openspec-usage.md` — OpenSpec CLI / slash command 调用指南
- `references/codegraph-usage.md` — CodeGraph MCP 工具调用指南
- `references/graphify-usage.md` — Graphify CLI 调用指南（含 C 项目交叉验证模式）
- `references/superpowers-usage.md` — Superpowers skill 调用指南
- `references/c-rules.md` — C 语言约束（含正/反示例）

## Skill 委托映射

| 职责 | 委托对象 |
|---|---|
| 规范管理 | `openspec-propose`, `openspec-explore`, `openspec-apply-change`, `openspec-archive-change` |
| 代码结构 | `graphify` CLI, `codegraph_*` MCP tools |
| 执行纪律 | `superpowers-test-driven-development`, `superpowers-using-git-worktrees` |
| 质量保证 | `superpowers-requesting-code-review`, `superpowers-verification-before-completion` |
| 调试 | `superpowers-systematic-debugging` |
| 并行工作 | `superpowers-dispatching-parallel-agents`, `superpowers-subagent-driven-development` |
| 计划 | `superpowers-writing-plans`, `superpowers-brainstorming` |
