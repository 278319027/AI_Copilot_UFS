本文档是 OpenCode Agent 的运行时指令，描述 graphify/openspec/superpowers 三工具的使用规则。

## superpowers 三条铁律

Superpowers 三条铁律适用于**所有** AI 输出、跨越全部四个阶段：
- **不验证不宣称完成** — 完成前必须实际运行测试/命令验证，使用 `verification-before-completion` Skill
- **无失败测试不写实现** — TDD（红 → 绿 → 重构），使用 `test-driven-development` Skill
- **无根因不修 bug** — 使用 `systematic-debugging` Skill，禁止凭直觉打补丁

## graphify

本项目在 graphify-out/ 目录下有知识图谱，包含 god nodes、社区结构、跨文件关系。

当用户输入 `/graphify` 时，先调用 `skill(name="graphify")`。

规则：
- 对代码库问题，如果 graphify-out/graph.json 存在，优先运行 `graphify query "<问题>"`。使用 `graphify path "<A>" "<B>"` 查询关系，`graphify explain "<概念>"` 聚焦概念。
- graphify-out/ 的脏文件是正常的（hooks 或增量更新导致）；不要因为 graph 文件脏而跳过 graphify。
- 如果 graphify-out/wiki/index.md 存在，优先用它做广泛导航，而非直接浏览源码。
- 仅在 query/path/explain 不足时，才读取 graphify-out/GRAPH_REPORT.md（用于广泛架构审查）。
- 修改代码后，运行 `graphify update .` 保持图谱最新（AST-only，无 API 成本）。

## openspec

本项目使用 **OpenSpec CLI v1.4.1** 做规格驱动开发。活规格基线位于 `openspec/specs/`；活跃变更位于 `openspec/changes/{id}/`。

当用户输入 `/opsx:*` 时，调用对应的 `opsx-*` 命令（或直接调用 `openspec` CLI 作为后备）。

规则：
- **Spec 变更是「系统做什么」的权威来源。** 修改影响已文档化行为的代码前，必须先读 `openspec/specs/`。
- **每次变更必须经过门禁**：Proposal Gate → Design Gate → Review Gate → Archive。
- **永不删除 `openspec/changes/` 条目** — 它们构成审计追踪。
- 优先使用 `.opencode/skills/openspec-*/` 中的包装 Skill（它们处理 CLI 调用 + 工件生成）。
- 规格层规则见 `.opencode/skills/sd-firmware-copilot/rules/spec_rules.md`。
- 工件模板见 `.opencode/skills/sd-firmware-copilot/references/spec_workflow.md`。
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
