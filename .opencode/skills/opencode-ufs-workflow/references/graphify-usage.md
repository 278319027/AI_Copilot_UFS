# Graphify CLI Agent 使用指南

本文件面向 OpenCode agent，说明如何调用 Graphify CLI 进行项目级知识图查询。

---

## 前提

- `graphify-out/graph.json` 存在
- 如不存在，**停止并报告**，不降级执行（本 workflow 要求 graph-first）

---

## 核心命令

所有命令在终端执行：

```bash
graphify query "<natural-language question>" [options]
graphify path "<concept-A>" "<concept-B>"
graphify explain "<concept>"
graphify update <path>
```

---

## query：概念搜索

```bash
graphify query "UFS write buffering SRAM cache block" --budget 1500
```

### 常用选项

| 选项 | 说明 |
|---|---|
| `--budget N` | 限制返回 token 数 |
| `--dfs` | 深度优先，追踪特定路径 |
| `--bfs` | 广度优先，默认 |

### 何时使用

- 不知道从哪里入手
- 需要跨文件/跨文档的概念关联
- 想发现社区结构（哪些文件/模块聚类）

### Agent 应如何解析输出

输出通常包含：
- 相关文件列表
- 相关概念节点
- 社区/聚类信息
- 引用来源（`source_location`）

Agent 应提取文件路径，然后转用 CodeGraph 做函数级分析。

---

## path：两点路径

```bash
graphify path "Host Write" "NAND Program"
```

### 何时使用

- 已知起点和终点，想知道数据/控制流如何连接
- 确认两个概念之间的最短依赖链

### Agent 应如何解析输出

输出为节点链：

```
Host Write → submit_write → ftl_write → nand_program
```

提取关键函数名，转 `codegraph_context` 深潜。

---

## explain：节点深潜

```bash
graphify explain "RLUT"
graphify explain "Write Buffer"
```

### 何时使用

- 需要对某个概念/模块做快速综述
- 检查该概念是否与文档、代码、图中的其他节点关联

### 处理节点不存在

如果查询的概念不存在，尝试相近概念：

```bash
graphify explain "SRAM"
graphify explain "Block Flush"
graphify query "write buffer cache" --budget 500
```

---

## update：刷新知识图

```bash
graphify update .
```

### 特点

- AST-only，**无 API 费用**
- 代码修改后应在 VERIFY 阶段调用
- 可在 git hook 中自动触发

---

## extract：首次构建（不推荐 agent  routinely 调用）

```bash
graphify extract /path/to/project
```

### 说明

- 首次构建或需要完整重建时使用
- 可能消耗 LLM API token（如启用语义提取）
- agent 发现 graph 缺失时应**停止并报告**，而不是自动 extract

---

## 与 CodeGraph 的协作

```
Step 1: Graphify 缩小范围
  graphify query "UFS write buffering" --budget 1000
  → 得到相关文件：host_write.c, host_read.c, meta_flush.c

Step 2: CodeGraph 精确分析
  codegraph_context(name="submit_write")
  codegraph_fn_impact(name="submit_write", depth=3)

Step 3: CodeGraph 验证
  codegraph_find_cycles()
  codegraph_diff_impact(staged=true)
```

---

## 输出中的边类型

Graphify 边可能标记为：

| 类型 | 含义 |
|---|---|
| EXTRACTED | 直接从 AST/文本提取 |
| INFERRED | 由 LLM 推断 |
| AMBIGUOUS | 不确定，需人工/进一步验证 |

Agent 应优先采信 EXTRACTED，对 AMBIGUOUS 保持怀疑并转 CodeGraph 验证。

---

## C 项目交叉验证模式

### 死代码交叉验证

CodeGraph 发现死函数后，用 Graphify 二次确认：

```bash
graphify query "is <function_name> actually used anywhere" --budget 500
```

### Header 社区定位

修改公共头文件前，用 Graphify 定位其所属社区：

```bash
graphify explain "fe_ftl_interface.h"
```

拿到社区文件列表后，再用 CodeGraph 精确列出所有 importer：

```python
codegraph_file_deps(file="src/include/fe_ftl_interface.h")
```

---

## 错误处理

- `graphify-out/graph.json` 不存在 → 停止："Graphify 知识图缺失。请先运行 `graphify extract .`。"
- `graphify query` 返回空 → 尝试更泛化的概念，或确认 graph 是否过期
- `graphify explain` 节点不存在 → 尝试 `graphify query` 找相近概念
