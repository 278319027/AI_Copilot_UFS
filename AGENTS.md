本文档是 OpenCode Agent 的运行时指令，描述 graphify/codegraph/openspec/superpowers 四工具的使用规则。

> **AI 完整工作流**（4 阶段闭环、4 Iron Rules、Bootstrap 决策表、Skill map）见 `.opencode/skills/sd-firmware-copilot/SKILL.md` —— 本文档仅含项目特有的 OpenCode 启动配置（环境变量、插件规则、CLI 命令清单）。

## codegraph 与 FEMU_ROOT

CodeGraph MCP 服务用于查询目标代码库的调用图/影响分析，其目标路径通过 `opencode.json` 的 `mcp.codegraph.command` 数组配置，路径形式为 `${FEMU_ROOT:-/home/zsf/AI_Proj/femu/hw/femu}`。

| 项 | 值 |
|----|----|
| **环境变量名** | `FEMU_ROOT` |
| **默认值** | `/home/zsf/AI_Proj/femu/hw/femu` |
| **直接路径** | `FEMU_ROOT` 即为目标 SSD 固件 `hw/femu` 源码目录（不拼接任何子路径） |
| **用途** | CodeGraph MCP 服务的 `--path` 参数 (被 opencode.json ${VAR:-default} 展开) |
| **验证命令** | `bash verify.sh` 中的 `[10/12] FEMU_ROOT` 检查 (或直接 `test -d ${FEMU_ROOT:-/home/zsf/AI_Proj/femu/hw/femu}`) |

覆盖示例: `export FEMU_ROOT=/opt/ssd-firmware/hw/femu` — 则 CodeGraph 索引 `/opt/ssd-firmware/hw/femu`。

## graphify

本项目配置了 Graphify 知识图谱插件（`.opencode/plugins/graphify.js`）。在目标代码库（非 zsf 自身）运行 `graphify update <子目录>` 后，会生成 `graphify-out/` 知识图谱（god nodes、社区结构、跨文件关系）。

当用户输入 `/graphify` 时，直接运行 graphify CLI 命令（graphify query/path/explain/update）。

规则：
- 对代码库问题，如果 graphify-out/graph.json 存在，优先运行 `graphify query "<问题>"`。使用 `graphify path "<A>" "<B>"` 查询关系，`graphify explain "<概念>"` 聚焦概念。
- graphify-out/ 的脏文件是正常的（hooks 或增量更新导致）；不要因为 graph 文件脏而跳过 graphify。
- 运行 graphify update . 后，如果 graphify-out/wiki/index.md 已生成，优先用它做广泛导航，而非直接浏览源码。
- 运行 graphify update . 后，如果 graphify-out/GRAPH_REPORT.md 已生成，则仅在 query/path/explain 不足时才读取它（用于广泛架构审查）。
- 修改代码后，运行 `graphify update .` 保持图谱最新（AST-only，无 API 成本）。
- **大项目**（15K+ 文件）：先在相关子目录运行 `graphify update <subdir>`，再 `graphify merge-graphs` 合并。中等项目（5K~15K）可先 `make clean` 清理构建产物再跑全量。全仓库直跑 `graphify update .` 会因遍历大量无关文件而超时（零进度反馈无法判断死/活）。

## .opencode 归属规则

**zsf 是 `.opencode/` 目录的唯一所有者**。`.opencode/{commands,memory,skills,plugins}/` 是项目级方法论资产，跟随 zsf 仓库版本控制。

OpenCode Agent 在不同工作目录运行时，**应向上查找**到 zsf 仓库根目录加载 `.opencode/`，**不应**在以下位置创建 `.opencode/`：

- ❌ `FEMU_ROOT/.opencode/`（SSD 固件代码子目录）— 实际发生过的误生成位置
- ❌ `<femu 仓库根>/.opencode/`（femu 仓库根，非 zsf）— 仅当 femu 是独立工作区时才允许
- ❌ 任何目标代码库子目录内的 `.opencode/`

如果发现误生成（`verify.sh [14/14]` 会自动检测），执行 `rm -rf <误生成路径>/.opencode/`，并通过在 zsf 仓库根启动 OpenCode Agent 来修复（保证向上查找找到 zsf 自己的 `.opencode/`）。

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

本项目包含 **Superpowers** 技能框架（12 个子技能，`.opencode/skills/superpowers-*/`）作为项目无关的工程纪律层。完整索引（4 Iron Rules + Bootstrap 决策表 + Skill map）整合至 `sd-firmware-copilot/SKILL.md §Superpowers 框架整合`。
