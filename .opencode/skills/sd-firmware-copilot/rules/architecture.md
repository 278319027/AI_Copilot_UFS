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

### 4.2 查询工具

主工具: ops-codegraph（MCP 服务器，30+ 工具）
> 当前部署于 FEMU 项目 `../femu/hw/femu/`

| 场景 | MCP 工具 | 补充工具 |
|------|---------|---------|
|| 谁调用了函数 X | `codegraph_callers` | `cscope -d -L2` |
| 函数 X 调用了谁 | `get_callees` | `cscope -d -L3` |
| 结构体在哪里被使用 | `symbol_search` + `find_by_imports` | `cscope -d -L0` |
| 修改文件的影响范围 | `impact` | `cscope -d -L2` |
| 模块间依赖 | `get_dependency_graph` | — |
| #include 依赖 | `find_by_imports` | `cscope -d -L8` |
| 宏使用 | `find_by_pattern` | `cscope -d -L4/6` |
| 函数指针调用 | ⚠️ 有限 | **必须用 cscope** |

补充工具: ctags + cscope（命令行）

### 4.3 查询结果使用规则

- 修改任何接口前，必须先查询 `impact`
- 修改任何结构体前，必须先查询 `symbol_search` + `find_by_imports`
|- 修改任何函数签名前，必须先查询 `codegraph_callers`
- 新增模块前，必须先了解 `get_dependency_graph`
- **函数指针相关查询，必须用 cscope 补充**

### 4.4 ops-codegraph 安装与配置

> 当前部署于 FEMU 项目 `../femu/hw/femu/`
- 安装: `npm install -g @optave/codegraph`
- 构建索引: `codegraph build`
|- 查询统计: `codegraph status`
- MCP 服务器: `codegraph mcp`

### 4.5 cscope 查询模式

| 模式 | 查询类型 | 示例问题 |
|------|----------|----------|
| 0 | 查找 C 符号 | 哪里定义/使用了 `NandCtx` |
| 1 | 查找全局定义 | 函数 `nand_read_page` 在哪里定义 |
| 2 | 查找调用者 | 谁调用了 `nand_read_page` |
| 3 | 查找被调用函数 | `nand_read_page` 调用了哪些函数 |
| 4 | 查找文本字符串 | 代码中哪里出现了 "NAND_ERR_TIMEOUT" |
| 6 | 查找 egrep 模式 | 用正则搜索模式 |
| 7 | 查找文件 | 哪些文件名包含 "nand" |
| 8 | 查找包含文件的文件 | 谁 include 了 "nand_ctx.h" |

### 4.6 OpenSpec 查询规则

OpenSpec 四个阶段对 CodeGraph 有不同要求：

| 阶段 | CodeGraph 要求 | 说明 |
|------|--------------|------|
| **Proposal** | 可选 | 提案关注「要做什么」，影响模块用常识判断。仅当需求涉及跨模块影响时才用 `impact` 做初步查询 |
| **Design** | 强制（见 §4.3） | design.md 必须包含完整的 CodeGraph 查询结果（impact、callers、find_by_imports、dependency graph） |
| **Review** | 查证式 | 不重新查询 CodeGraph。对照 design.md 中已持久化的 CodeGraph 结果查证代码变更是否在预期范围内。仅查证发现偏差时重新查询 |
| **Archive** | 可选 | 归档阶段无需 CodeGraph 查询 |

> 查证式 Review 的核心理念：design.md 已持久化了 CodeGraph 结果，Review 时直接对照查证，避免重新查询——既节省时间，又确保一致性。

#### 4.6.1 Baseline spec 查询优先级

当 spec baseline 和 CodeGraph 之间有差异时：
1. **spec baseline 优先**作为「系统应该如何表现」的权威源
2. **CodeGraph 优先**作为「系统实际上如何表现」的权威源
3. 两者有差异 → 标注为偏差，在 proposal.md 中列入变更范围
## 6. Graphify 查询规则

### 6.1 Graphify 与 CodeGraph 分工

|- **CodeGraph**（ops-codegraph，当前部署于 FEMU `../femu/hw/femu/`）：代码结构查询——调用图、依赖图、影响分析
- **Graphify**：知识图谱查询——概念关系、社区结构、跨文件语义导航
- 原则：结构问题用 CodeGraph / cscope，概念问题用 Graphify

### 6.2 查询策略

对于代码库相关问题，当 graphify-out/graph.json 存在时：
- 优先使用 `graphify query "<问题>"` 获取归域子图
- 使用 `graphify path "<A>" "<B>"` 查询概念间关系路径
- 使用 `graphify explain "<概念>"` 获取聚焦解释
- graphify-out/wiki/index.md 存在时，用于概览导航
- 仅当 query/path/explain 信息不足时，才阅读 graphify-out/GRAPH_REPORT.md

### 6.3 OpenSpec 规格基线查询优先级

AI 在理解系统行为时，按以下优先级查询（从快到慢）：
1. **specs/baseline/** → 获取当前行为全貌
2. **CodeGraph** 局部验证 → 补充调用关系和依赖细节
3. **代码** → 仅在基线与代码不一致或基线信息不足时

> 门禁与归档规则详见 `rules/spec_rules.md`。

## 7. Agent 配置与 Context 管理

### 7.1 Agent 超时处理

大型文件修改任务（500+ 行文件）容易触发 agent 超时（默认 4-6 分钟 staleness）。对策：
- 拆分为更小的 sub-task（每个 task 修改不超过 100 行）
- 在 `.opencode/oh-my-openagent.json` 中调整 `background_task.staleTimeoutMs`（按需）

### 7.2 Context 膨胀控制

- 每个阶段结束后主动执行 context 压缩
- 单次并发 explore/librarian agent 不超过 5 个
- context 使用率超过 70% 时暂停新任务
- 工具调试不超过 2 轮
