# Workflow Reference

## Inputs

- OpenSpec: goal, scope.files, constraints, acceptance, test_plan
- Graphify: task subgraph, if repo has graph data
- CodeGraph: callers, callees, impact, dependency shape
- Superpowers: patch generation/application
- Source tree: only when graph data is absent or incomplete

## Execution Order

1. Restate task.
2. Freeze scope.
3. If graph data exists, load Graphify first.
4. Load source only for scoped files.
5. Reduce context.
6. Use Superpowers to patch.
7. Build and test.
8. Refresh Graphify if available.
9. Report result.

## Hard Stops

以下任一情况发生，**立即停止当前工作，不降级执行**，并向用户清晰报告问题：

| 触发条件 | 停止原因 | 报告内容 |
|---|---|---|
| OpenSpec 缺失或 scope 不清 | 无法冻结范围 | "OpenSpec 未初始化或当前 change 的 scope 未明确。请先 `openspec init` 并创建/确认 change。" |
| Graphify 数据存在但未使用 | 违反 graph-first 原则 | "Graphify 数据已存在，但未在读取源码前查询。请先执行 `graphify query`。" |
| 图证据与 scope 矛盾 | 结构事实与规范冲突 | "CodeGraph/Graphify 输出与当前 scope 矛盾：`<具体矛盾>`。请重新定界或澄清需求。" |
| patch 会扩展架构 | 超出 scope | "当前 patch 将引入新架构或修改 scope 外文件。请回到 Phase 1/3 重新定界。" |
| 测试失败且语义不匹配 | 实现可能错误 | "测试失败，失败用例 `<case>` 表明实现与 design/spec 不一致。请停止并排查。" |
| 必需工具缺失或故障 | 无法保证质量 | "`<tool>` 缺失/故障：`<具体错误>`。本 workflow 不降级执行，请先修复工具。" |

## Tool Availability Checks

进入 SCOPE 前确认：

- `openspec --version` 返回版本号
- `.codegraph/graph.db` 存在且 MCP 可连接
- `graphify-out/graph.json` 存在（若 workflow 要求 graph-first）
- `.opencode/skills/superpowers-*/SKILL.md` 已安装

任一检查失败，停止并报告缺项。

## Quick Checklist

进入任何 patch 前快速核对：

### Preflight

- [ ] 用一句话重述任务
- [ ] 确定目标仓库和可能涉及的模块
- [ ] 确认 OpenSpec 或从 docs 推导范围
- [ ] 检查 graph 数据是否存在

### Graph First

- [ ] 如 graph 数据存在，先加载 Graphify
- [ ] 只拉取相关的 callers、callees、impact 和相邻节点
- [ ] 广泛浏览源码前先查图
- [ ] 如 graph 与 spec 矛盾，停止

### Scope Lock

- [ ] 冻结 `scope.files`
- [ ] 明确要修改的函数或模块
- [ ] 拒绝仅做清理的范围扩张
- [ ] 拒绝架构变更

### Patch Gate

- [ ] 计划完成后再使用 Superpowers
- [ ] 只修改 scope 内文件
- [ ] patch 后 build 并测试
- [ ] 如 Graphify 可用，刷新它
