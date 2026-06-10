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

| 场景 | MCP 工具 | 补充工具 |
|------|---------|---------|
| 谁调用了函数 X | `get_callers` | `cscope -d -L2` |
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
- 修改任何函数签名前，必须先查询 `get_callers`
- 新增模块前，必须先了解 `get_dependency_graph`
- **函数指针相关查询，必须用 cscope 补充**

### 4.4 ops-codegraph 安装与配置

- 安装: `npm install -g @optave/codegraph`
- 构建索引: `codegraph build`
- 查询统计: `codegraph stats`
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

