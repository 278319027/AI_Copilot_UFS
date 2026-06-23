本文档是 OpenCode Agent 的运行时指令，描述 graphify/codegraph/openspec/superpowers 四工具的使用规则。

> **AI 完整工作流**（4 阶段闭环、4 Iron Rules、Bootstrap 决策表、Skill map）见 `.opencode/skills/sd-firmware-copilot/SKILL.md` —— 本文档仅含项目特有的 OpenCode 启动配置（环境变量、插件规则、CLI 命令清单）。

## codegraph 与 FEMU_ROOT

CodeGraph MCP 服务用于查询目标代码库的调用图/影响分析，其目标路径通过 `opencode.json` 的 `mcp.codegraph.command` 数组配置。

**约定**：`FEMU_ROOT` 环境变量是 FEMU 路径的标准形式，与 `opencode.json` 的 `mcp.codegraph.command --path` 的 `${FEMU_ROOT:-/default}` 语法一致。所有 shell 脚本统一使用 `${FEMU_ROOT:-/home/zsf/AI_Proj/femu/hw/femu}` 约定，**与 `opencode.json` 默认值保持同步**（修改任一处需同步另一处）。

| 项 | 值 |
|----|----|
| **环境变量** | `FEMU_ROOT`（env var 优先于默认） |
| **默认路径** | `/home/zsf/AI_Proj/femu/hw/femu`（与 `opencode.json` 的 `codegraph.command --path` 默认值相同）|
| **验证命令** | `bash scripts/verify.sh` 中的 `[9/15] FEMU_ROOT` 检查 |

覆盖示例:
- **临时覆盖**：`export FEMU_ROOT=/opt/ssd-firmware/hw/femu`
- **永久修改**：编辑 `opencode.json` 的 `mcp.codegraph.command --path`（同步脚本中的默认值）

## graphify

在目标代码库（非 zsf 自身）运行 `graphify update <子目录>` 后，会生成 `graphify-out/` 知识图谱（god nodes、社区结构、跨文件关系）。

当用户输入 `/graphify` 时，直接运行 graphify CLI 命令（graphify query/path/explain/update）。

规则：
- 对代码库问题，如果 graphify-out/graph.json 存在，优先运行 `graphify query "<问题>"`。使用 `graphify path "<A>" "<B>"` 查询关系，`graphify explain "<概念>"` 聚焦概念。
- graphify-out/ 的脏文件是正常的（hooks 或增量更新导致）；不要因为 graph 文件脏而跳过 graphify。
- 运行 graphify update . 后，如果 graphify-out/wiki/index.md 已生成，优先用它做广泛导航，而非直接浏览源码。
- 运行 graphify update . 后，如果 graphify-out/GRAPH_REPORT.md 已生成，则仅在 query/path/explain 不足时才读取它（用于广泛架构审查）。
- 修改代码后，运行 `graphify update .` 保持图谱最新（AST-only，无 API 成本）。
- **大项目**（15K+ 文件）：先在相关子目录运行 `graphify update <subdir>`，再 `graphify merge-graphs` 合并。中等项目（5K~15K）可先 `make clean` 清理构建产物再跑全量。全仓库直跑 `graphify update .` 会因遍历大量无关文件而超时（零进度反馈无法判断死/活）。

## .opencode 归属规则

**zsf 是 `.opencode/` 目录的唯一所有者**。`.opencode/{commands,memory,skills}/` 是项目级方法论资产，跟随 zsf 仓库版本控制。

OpenCode Agent 在不同工作目录运行时，**应向上查找**到 zsf 仓库根目录加载 `.opencode/`，**不应**在以下位置创建 `.opencode/`：

- ❌ `FEMU_ROOT/.opencode/`（SSD 固件代码子目录）— 实际发生过的误生成位置
- ❌ `<femu 仓库根>/.opencode/`（femu 仓库根，非 zsf）— 仅当 femu 是独立工作区时才允许
- ❌ 任何目标代码库子目录内的 `.opencode/`

如果发现误生成（`verify.sh [13/15]` 会自动检测），执行 `rm -rf <误生成路径>/.opencode/`，并通过在 zsf 仓库根启动 OpenCode Agent 来修复（保证向上查找找到 zsf 自己的 `.opencode/`）。

**为什么不允许**：方法论层（zsf）与目标代码库（femu）解耦是核心架构原则。在 femu 子目录创建 `.opencode/` 会让 femu 仓库的"运行环境"被方法论层锁死——换 SSD 固件代码库时必须重新部署。同时误生成的副本会与 zsf 自己的 `.opencode/` 不同步（出现 skill 名字不一致、规则过时等问题）。

## openspec

本项目使用 **OpenSpec CLI v1.4.1** 做规格驱动开发。活规格基线位于 `openspec/specs/`；活跃变更位于 `openspec/changes/{id}/`。

当用户输入 `/opsx:*` 时，调用 `.opencode/commands/` 下对应 `opsx-{propose,explore,apply,sync,archive}.md`（或直接调用 `openspec` CLI 作为后备）。

规则：
- **Spec 变更是「系统做什么」的权威来源。** 修改影响已文档化行为的代码前，必须先读 `openspec/specs/`。
- **每次变更必须经过五级门禁**：Proposal Gate → Design Gate → BUILD Gate → Review Gate → Archive（BUILD Gate 强制编码前加载验证 skill，详见 sd-firmware-copilot SKILL）。
- **永不删除 `openspec/changes/` 条目** — 它们构成审计追踪。
- **OpenSpec 流程**：`openspec-workflow/` 是概念层（Iron Rules + 跨切约束 + 5 phase 路由），执行具体 phase 请加载对应 `openspec-{propose,explore,apply,sync-specs,archive-change}/`。
- 规格层规则见 `.opencode/skills/sd-firmware-copilot/SKILL.md`（`## Spec 规则` 一节）。

- 可跳过 Proposal Gate 的场景：仅单文件 bugfix。文档/注释变更不需要 OpenSpec 工件。
- 归档提交格式：`chore(spec): archive {change-id}`。

## superpowers

本项目包含 **Superpowers** 技能框架（8 个子技能，`.opencode/skills/superpowers-*/`）作为项目无关的工程纪律层。完整索引（4 Iron Rules + Bootstrap 决策表 + Skill map）整合至 `sd-firmware-copilot/SKILL.md §Superpowers 框架整合`。

### Skill 自动触发（Bootstrap）— 替代全局 `experimental.chat.system.transform` 钩子

> **为什么需要这一节**：本项目通过把 Superpowers 13 个 skill **逐个复制到 `.opencode/skills/`** 实现项目自包含分发（不依赖 `~/.config/opencode/superpowers/` 全局安装）。代价是**没有官方引导插件**自动注入 `using-superpowers` 内容到系统提示——必须由本节作为**项目级 bootstrap**，把全局钩子的"1% 规则"显式化。

**会话开始时强制加载**（每次新 session / 新需求的第一动作）：

```text
skill(name="superpowers-using-superpowers")
```

**按场景自动加载规则**（"1% 规则"——只要 1% 概率匹配，立即加载）：

| 触发场景 | 必加载 skill | 缺失后果 |
|----------|-------------|----------|
| 会话开始 / 收到新需求 | `superpowers-using-superpowers` | 上下文无纪律约束 |
| 涉及 bug、test failure、异常行为 | `superpowers-systematic-debugging` | 凭直觉打补丁 |
| 写生产代码（含 C/H 文件编辑） | `superpowers-verification-before-completion` | 无测试证据，代码不可信 |
| 进入 BUILD 阶段（`/opsx:apply`） | `superpowers-executing-plans` + `superpowers-verification-before-completion` | 跳过任务、跳过验证 |
| 合并前 / 用户说「review my work」 | `superpowers-requesting-code-review` | AI 自批自审 |
| 收到审查反馈 | `superpowers-receiving-code-review` | 表演性认同 / 盲目实现 |
| 所有任务完成，准备合并 | `superpowers-finishing-a-development-branch` | 直接合并不清理 |
| 即将「声明完成 / 修复 / 通过」 | `superpowers-verification-before-completion` | 无证据断言 |

**4 Iron Rules（不可妥协）**：

- **NO COMPLETION CLAIMS WITHOUT FRESH VERIFICATION EVIDENCE** — 完成前必须实际运行测试/编译/命令并验证结果，禁止「应该没问题」。
- **NO PRODUCTION CODE WITHOUT TESTS** — 每段生产代码必须有对应的测试覆盖。纯逻辑代码用单元测试验证；硬件依赖代码（MMIO/ISR/DMA）用集成测试或仿真验证，或在 `review.md` 标注不可覆盖原因。
- **NO FIXES WITHOUT ROOT CAUSE INVESTIGATION FIRST** — 复现、读错误、查变更、形成假设、最小验证，禁止凭直觉打补丁。
- **NO MERGE WITHOUT CODE REVIEW** — 每个非平凡变更必须经正式审查，接收反馈以技术为准不表演性认同。

> 详细决策表 + Skill map → `sd-firmware-copilot/SKILL.md §Superpowers 框架整合`。
