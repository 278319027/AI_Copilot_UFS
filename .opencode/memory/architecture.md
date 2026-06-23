# Architecture Rules

## 1. 分层规则

- 禁止跨层直接调用私有实现。
- 业务层不得直接访问底层硬件寄存器。
- 驱动层不得反向依赖上层业务逻辑。

## 2. 模块边界

- 每个模块必须有清晰的 API 边界。
- 模块私有数据不得被外部直接访问。
- 跨模块共享状态必须显式声明。

## 3. 依赖规则

- 依赖必须单向。
- 循环依赖必须在设计阶段消除。
- 新增依赖必须说明原因与影响范围。

## 4. CodeGraph 查询规则

### 4.1 AI 工作时必须先查询 CodeGraph

在生成代码或修改代码前，AI 必须先通过 CodeGraph 了解影响范围。

### 4.2 查询工具与使用规则

主工具: ops-codegraph（MCP 服务器，30+ 工具），部署于 FEMU 项目。

**详细工具列表、查询场景、使用规则、安装配置** → 见 `sd-firmware-copilot/SKILL.md §KNOW 阶段`。

本节仅保留**核心约束**（不可省略）：

- 修改任何接口前，必须先查询 `codegraph impact`
- 修改任何结构体前，必须先查询 `codegraph symbol_search` + `codegraph find_by_imports`
- 修改任何函数签名前，必须先查询 `codegraph where <symbol>` 列直接调用方
- 新增模块前，必须先了解 `codegraph dependency_graph`
- **函数指针相关查询：CodeGraph AST 不追踪间接调用，用 `symbol_search` 查注册点 + 手工读 dispatch 函数**

## 5. Graphify 查询规则

### 5.1 Graphify 与 CodeGraph 分工

- **CodeGraph**（ops-codegraph，当前部署于 FEMU `../femu/hw/femu/`）：代码结构查询——调用图、依赖图、影响分析
- **Graphify**：知识图谱查询——概念关系、社区结构、跨文件语义导航
- 原则：结构问题用 CodeGraph / cscope，概念问题用 Graphify

### 5.2 查询策略

对于代码库相关问题，当 graphify-out/graph.json 存在时：
- 优先使用 `graphify query "<问题>"` 获取归域子图
- 使用 `graphify path "<A>" "<B>"` 查询概念间关系路径
- 使用 `graphify explain "<概念>"` 获取聚焦解释
- graphify-out/wiki/index.md 存在时，用于概览导航
- 仅当 query/path/explain 信息不足时，才阅读 graphify-out/GRAPH_REPORT.md

### 5.3 更新规则

- 修改代码后更新图谱（仅 AST 更新，无 API 费用）：
  - 小项目（< 5K 文件）：`graphify update .`
  - 大项目（> 15K 文件）：子目录限定 + 合并（见方法论 §3.4）
- 图谱变陈旧时增量刷新（同上策略）
- 只有当任务目标就是修复图谱输出，或用户明确要求不用 graphify 时才跳过

### 5.4 自动更新机制（**已废弃**）

> **2026-06-23 移除**：原 `templates/git-hooks/{post-checkout, post-merge, post-commit}` + `scripts/install-graphify-hooks.sh` 已删除（commit 待提交）。原因：
> 1. **意图不匹配**：设计目标"git 操作后自动更新" ≠ 用户本意"AI session 开始时更新"
> 2. **M-5 强化后冗余**：`superpowers-using-superpowers/SKILL.md` PROJECT-SPECIFIC 段已强制 session 开头跑 4 步环境准备（含 `graphify update`），更准确更及时
> 3. **不完整**：只更新 graphify，不更新 codegraph
> 4. **从未被使用**：`.git/hooks/` 只有 `.sample`，作者也承认"大项目较慢"
>
> **替代方案**：session-start 由 M-5 的 4 步 CodeGraph 导航覆盖（见 `superpowers-using-superpowers/SKILL.md` §PROJECT-SPECIFIC）

## 6. Agent 配置与 Context 管理

### 6.1 opencode.json 配置规范

`opencode.json` 是 OpenCode Agent 的运行时配置单一文件，结构如下：

```json
{
  "$schema": "https://opencode.ai/config.json",
  "mcp": {
    "codegraph": {
      "type": "local",
      "command": ["codegraph", "serve", "--mcp", "--path", "${FEMU_ROOT:-/path/to/femu/hw/femu}"],
      "enabled": true,
      "env": {}
    }
  },
  "agent": {
    "timeout": 300,
    "maxConcurrentAgents": 5,
    "contextWindowThreshold": 0.7,
    "staleTaskTimeoutMs": 360000
  },
  "project": {
    "femuRoot": "${FEMU_ROOT:-/path/to/femu/hw/femu}",
    "graphifyUpdateStrategy": "subdirectory",
    "defaultBuildCommand": "make clean && make -j$(nproc)",
    "specCapabilities": ["nvme-commands", "ftl-mapping", "nand-driver"]
  }
}
```

| 配置节 | 用途 | 校验位置 |
|--------|------|----------|
| `mcp.codegraph` | CodeGraph MCP 服务配置 | verify.sh [2/15] |
| `agent` | Agent 行为参数（超时、并发、context 阈值） | verify.sh [8/15] |
| `project` | 项目特定设置（femuRoot、构建命令、graphify 策略） | verify.sh [8/15] |

**严禁**在脚本中直接硬编码 FEMU_ROOT 路径。统一通过 `scripts/get_femu_root.sh` 从 `opencode.json` 解析。

### 6.2 Agent 超时处理

大型文件修改任务（500+ 行文件）容易触发 agent 超时。对策：
- 拆分为更小的 sub-task（每个 task 修改不超过 100 行）
- 在 `opencode.json` 的 `agent.staleTaskTimeoutMs` 中调整（默认 360000ms = 6 分钟）

### 6.3 Context 膨胀控制

- 每个阶段结束后主动执行 context 压缩
- 单次并发 explore/librarian agent 不超过 `agent.maxConcurrentAgents` 个（默认 5）
- context 使用率超过 `agent.contextWindowThreshold`（默认 0.7 = 70%）时暂停新任务
- 工具调试不超过 2 轮

### 6.4 OpenSpec 规格基线查询优先级

AI 在理解系统行为时，按以下优先级查询（从快到慢）：
1. **openspec/specs/** → 获取当前行为全貌
2. **CodeGraph** 局部验证 → 补充调用关系和依赖细节
3. **代码** → 仅在基线与代码不一致或基线信息不足时

> 门禁与归档规则详见 `.opencode/skills/sd-firmware-copilot/SKILL.md`。
