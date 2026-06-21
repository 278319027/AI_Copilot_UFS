本文档是 OpenCode Agent 的运行时指令，描述 graphify/codegraph/openspec/superpowers 四工具的使用规则。

## superpowers 四条铁律

Superpowers 四条铁律适用于**所有** AI 输出、跨越全部四个阶段：
- **不验证不宣称完成** — 完成前必须实际运行测试/命令验证，遵循 `verification-before-completion/SKILL.md`
- **无验证不写实现** — 纯逻辑代码走 Path A（红→绿→重构），硬件依赖代码走 Path B（编译验证 + FEEDBACK 系统测试），均需遵循 `test-driven-development/SKILL.md`
- **无根因不修 bug** — 遵循 `systematic-debugging/SKILL.md`，禁止凭直觉打补丁
- **未审查不合并** — 遵循 `requesting-code-review/SKILL.md`，禁止绕过审查直接合入主干
## codegraph 与 FEMU_ROOT



CodeGraph MCP 服务用于查询目标代码库的调用图/影响分析，其目标路径通过 `opencode.json` 的 `mcp.codegraph.command` 数组配置，路径形式为 `${FEMU_ROOT:-/home/tcb/AI_Proj/femu}/hw/femu`。



| 项 | 值 |

|----|----|

| **环境变量名** | `FEMU_ROOT` |

| **默认值** | `/home/tcb/AI_Proj/femu` |

| **拼接路径** | `<FEMU_ROOT 或默认值>/hw/femu` |

| **用途** | CodeGraph MCP 服务的 `--path` 参数 (被 opencode.json ${VAR:-default} 展开) |

| **验证命令** | `bash verify.sh` 中的 `[10/12] FEMU_ROOT` 检查 (或直接 `test -d ${FEMU_ROOT:-/home/tcb/AI_Proj/femu}/hw/femu`) |



覆盖示例: `export FEMU_ROOT=/opt/ssd-firmware` — 则 CodeGraph 索引 `/opt/ssd-firmware/hw/femu`。



## graphify

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

## openspec

本项目使用 **OpenSpec CLI v1.4.1** 做规格驱动开发。活规格基线位于 `openspec/specs/`；活跃变更位于 `openspec/changes/{id}/`。

当用户输入 `/opsx:*` 时，调用对应的 `opsx-*` 命令（或直接调用 `openspec` CLI 作为后备）。

规则：
- **Spec 变更是「系统做什么」的权威来源。** 修改影响已文档化行为的代码前，必须先读 `openspec/specs/`。
- **每次变更必须经过门禁**：Proposal Gate → Design Gate → Review Gate → Archive。
- **永不删除 `openspec/changes/` 条目** — 它们构成审计追踪。
- **OpenSpec 流程**：`openspec-workflow/` 是概念层（Iron Rules + 跨切约束 + 5 phase 路由），执行具体 phase 请加载对应 `openspec-{propose,explore,apply,sync-specs,archive-change}/`。
- 规格层规则见 `.opencode/skills/sd-firmware-copilot/SKILL.md`（`## Spec 规则` 一节）。

- 可跳过 Proposal Gate 的场景：仅单文件 bugfix。文档/注释变更不需要 OpenSpec 工件。
- 归档提交格式：`chore(spec): archive {change-id}`。

## superpowers

本项目包含 **Superpowers** 技能框架（`.opencode/skills/superpowers/`，13 个子技能）作为项目无关的工程纪律层。Superpowers 位于 `sd-firmware-copilot`（SSD 固件领域规则）之下。

规则：
- **写任何生产代码前**，遵循 `test-driven-development/SKILL.md` — 纯逻辑走 Path A（先写失败测试），硬件依赖走 Path B（编译验证 + FEEDBACK 系统测试）。
- **修任何 bug 前**，遵循 `systematic-debugging/SKILL.md` — 完成根因调查、收集证据、再修。
- **宣称完成前**，遵循 `verification-before-completion/SKILL.md` — 实际运行测试/编译/命令并确认结果。
- **代码审查**，遵循 `requesting-code-review/SKILL.md`（发送审查）和 `receiving-code-review/SKILL.md`（接收反馈）。
- **多任务工作**，遵循 `subagent-driven-development/SKILL.md` 或 `dispatching-parallel-agents/SKILL.md` 保持上下文隔离。
- **执行 tasks.md 项**，遵循 `executing-plans/SKILL.md`。**分支清理**，遵循 `finishing-a-development-branch/SKILL.md`。
- 铁律在 KNOW/PLAN/BUILD/FEEDBACK 全四阶段不可协商。
- 完整铁律索引见 `.opencode/skills/superpowers/SKILL.md`。
