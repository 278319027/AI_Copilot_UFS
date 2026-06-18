本文档是 OpenCode Agent 的运行时指令，描述 graphify/openspec/superpowers 三工具的使用规则。

## superpowers 三条铁律

Superpowers 三条铁律适用于**所有** AI 输出、跨越全部四个阶段：
- **不验证不宣称完成** — 完成前必须实际运行测试/命令验证，使用 `verification-before-completion` Skill
- **无失败测试不写实现** — TDD（红 → 绿 → 重构），使用 `test-driven-development` Skill
- **无根因不修 bug** — 使用 `systematic-debugging` Skill，禁止凭直觉打补丁

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
- **OpenSpec 流程**使用 `.opencode/skills/openspec-workflow/SKILL.md`（五阶段完整工作流：propose → explore → apply → sync → archive）。
- 规格层规则见 `.opencode/skills/sd-firmware-copilot/SKILL.md`（`## Spec 规则` 一节）。
- 工件模板与门禁流程见 `.opencode/skills/openspec-workflow/SKILL.md`（`## 工件模板与门禁流程` 一节）。
- 可跳过 Proposal Gate 的场景：仅单文件 bugfix。文档/注释变更不需要 OpenSpec 工件。
- 归档提交格式：`chore(spec): archive {change-id}`。

## superpowers

本项目包含 **Superpowers** 技能框架（`.opencode/skills/superpowers/`，10 个子技能）作为项目无关的工程纪律层。Superpowers 位于 `sd-firmware-copilot`（SSD 固件领域规则）之下。

规则：
- **写任何生产代码前**，调用 `test-driven-development` — 先写失败测试。
- **修任何 bug 前**，调用 `systematic-debugging` — 完成根因调查、收集证据、再修。
- **宣称完成前**，调用 `verification-before-completion` — 实际运行测试/编译/命令并确认结果。
- **代码审查**，使用 `requesting-code-review`（发送审查）和 `receiving-code-review`（接收反馈）。
- **多任务工作**，使用 `subagent-driven-development` 或 `dispatching-parallel-agents` 保持上下文隔离。
- **执行 tasks.md 项**，使用 `executing-plans`。**分支清理**，使用 `finishing-a-development-branch`。
- 铁律在 KNOW/PLAN/BUILD/FEEDBACK 全四阶段不可协商。
- 完整铁律索引见 `.opencode/skills/superpowers/SKILL.md`。
