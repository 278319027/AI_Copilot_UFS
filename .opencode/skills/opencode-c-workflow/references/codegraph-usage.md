# CodeGraph MCP Agent 使用指南

本文件面向 OpenCode agent，说明如何调用 CodeGraph MCP 工具进行代码结构分析。

---

## 前提

- `.codegraph/graph.db` 存在
- MCP server 已配置且可连接

任一条件不满足，**停止并报告**，不降级执行。

---

## 工具调用格式

所有 CodeGraph 工具通过 MCP 调用，OpenCode 中统一为：

```python
codegraph_<tool_name>(param1="value1", param2="value2")
```

参数使用 Python-style 关键字参数（工具实际接收 JSON）。

---

## 按 workflow 阶段推荐工具

### GROUND 阶段

| 工具 | 用途 | 示例 |
|---|---|---|
| `codegraph_context` | 函数完整上下文 + 调用链 + 源码 | `codegraph_context(name="submit_write")` |
| `codegraph_fn_impact` | 爆炸半径 | `codegraph_fn_impact(name="submit_write", depth=3)` |
| `codegraph_semantic_search` | 按语义找符号 | `codegraph_semantic_search(query="buffer allocation")` |
| `codegraph_where` | 定位定义与使用 | `codegraph_where(target="submit_write")` |

### PLAN 阶段

| 工具 | 用途 | 示例 |
|---|---|---|
| `codegraph_file_deps` | 头文件消费者 | `codegraph_file_deps(file="src/include/fe_ftl_interface.h")` |
| `codegraph_complexity` | 高风险函数 | `codegraph_complexity(above_threshold=true)` |
| `codegraph_triage` | 综合风险排序 | `codegraph_triage(limit=20)` |

### PATCH 阶段

| 工具 | 用途 | 示例 |
|---|---|---|
| `codegraph_check` | CI gate | `codegraph_check(staged=true)` |
| `codegraph_find_cycles` | 循环依赖 | `codegraph_find_cycles()` |
| `codegraph_diff_impact` | diff 影响 | `codegraph_diff_impact(staged=true)` |

### VERIFY 阶段

| 工具 | 用途 | 示例 |
|---|---|---|
| `codegraph_diff_impact` | 回归影响 | `codegraph_diff_impact(staged=true)` |
| `codegraph_find_cycles` | 最终循环依赖检查 | `codegraph_find_cycles()` |

---

## 核心工具详解

### `codegraph_context`

```python
codegraph_context(
    name="submit_write",
    depth=1,
    include_tests=False
)
```

**返回关键信息**：
- 函数源码
- 直接调用者（callers）
- 直接被调用者（callees）
- 依赖的头文件
- 函数签名

### `codegraph_fn_impact`

```python
codegraph_fn_impact(
    name="submit_write",
    depth=3
)
```

**用途**：列出修改该函数会影响的所有函数，depth 建议 3（接口改 5）。

### `codegraph_file_deps`

```python
codegraph_file_deps(
    file="src/include/write_buffer.h"
)
```

**用途**：列出包含该头文件的所有文件。修改公共头文件前必须调用。

### `codegraph_find_cycles`

```python
codegraph_find_cycles()
```

**用途**：检测 include/调用循环依赖。新增模块间依赖后必须调用。

### `codegraph_check`

```python
codegraph_check(
    staged=true,
    boundaries=true,
    cycles=true,
    signatures=true
)
```

**用途**：实施前/后的 CI gate，检查边界、循环、签名违规。

### `codegraph_diff_impact`

```python
codegraph_diff_impact(
    staged=true,
    depth=3
)
```

**用途**：分析当前 diff 的 transitive caller 影响。commit 前和验证阶段都要调用。

---

## 返回结构通用解读

CodeGraph 返回通常为 JSON：

```json
{
  "nodes": [...],
  "edges": [...],
  "source": "...",
  "metrics": {
    "cyclomatic": 12,
    "cognitive": 8,
    "lines": 87
  }
}
```

Agent 应关注：
- `nodes` / `edges` 中的调用关系
- `source` 中的源码片段
- `metrics` 中的复杂度和长度

---

## 与 Graphify 的协作

1. **先用 Graphify** 做宏观概念定位：`graphify query "UFS write buffering"`
2. **再用 CodeGraph** 精确分析：`codegraph_context(name="submit_write")`
3. **最后用 CodeGraph** 验证：`codegraph_fn_impact` + `codegraph_find_cycles`

---

## C 项目专属模式

### Header 影响分析

修改公共头文件前，追踪所有消费者：

```python
# 列出包含该头文件的所有文件
codegraph_file_deps(file="src/include/fe_ftl_interface.h")
```

### 接口变更安全

修改函数指针表时：

```python
# 查找所有实现
codegraph_implementations(name="FeFtlInterface_t")

# 追踪接口数据流
codegraph_dataflow(name="submit_read")
```

### 重构安全

提取函数前：

```python
# 原函数爆炸半径
codegraph_fn_impact(name="long_function", depth=5)

# 候选文件复杂度
codegraph_complexity(file="src/ftl/lut.c", above_threshold=true)

# 循环依赖检查
codegraph_find_cycles()
```

### 死代码清理

```python
# 查找死函数
codegraph_roles(role="dead")
```

> 发现死函数后，用 Graphify 交叉验证：`graphify query "is this function actually used anywhere" --budget 500`

---

## 错误处理

- MCP 连接失败 → 停止："CodeGraph MCP 无法连接。请检查 `.codegraph/graph.db` 与 MCP 配置。"
- 查询无结果 → 尝试 `codegraph_semantic_search` 或检查符号名拼写
- 数据库过期 → 停止："CodeGraph 数据可能过期，请运行 `codegraph build .` 后重试。"
