# CodeGraph 部署指南（精要版）

> 完整教程见 `docs/research/CodeGraph_Setup.md`

## 一键部署

```bash
bash deploy_tools.sh <C源码路径>
```

或手动部署各工具：

## CodeGraph（主工具）

```bash
# 安装
npm install -g @optave/codegraph

# 构建 C 项目索引
cd <project-root>
codegraph init <source-path>    # 如 codegraph init hw/femu — 限定索引范围

# 验证
codegraph status                # 查看索引统计
codegraph query <symbol>       # 搜索符号
codegraph callers <symbol>     # 谁调用了
codegraph callees <symbol>     # 调用了谁
codegraph impact <symbol>      # 影响分析
codegraph explore <query>       # 区域探索
```

### MCP 集成（OpenCode Agent）

`opencode.json` 配置：

```json
{
  "$schema": "https://opencode.ai/config.json",
  "mcp": {
    "codegraph": {
      "type": "local",
      "command": ["codegraph", "serve", "--mcp", "--path", "<项目路径>"],
      "enabled": true,
      "env": {}
    }
  }
}
```

> 注意：配置键是 `mcp`（不是 `mcpServers`），`command` 是数组。

## ctags + cscope（辅助工具）

```bash
# 安装
sudo apt install -y universal-ctags cscope

# 构建索引
cd <project-root>
find <source-path> -name "*.c" -o -name "*.h" > .codegraph/cscope.files
ctags -L- --fields=+neKSt --extras=+q --c-kinds=+psgutdefl -o tags < .codegraph/cscope.files
cscope -b -q -k -i .codegraph/cscope.files

# 查询（补充 CodeGraph 函数指针/宏盲区）
cscope -d -L2 "func_ptr"   # 函数指针调用者
cscope -d -L3 "func_ptr"   # 函数指针指向
cscope -d -L4 "MACRO"      # 宏使用位置
cscope -d -L8 "header.h"   # 头文件包含
```

## Graphify（知识图谱，可选）

```bash
# 安装
uv pip install graphify --with chinese --with pdf --with mcp

# 构建（代码级，无需 LLM）
graphify extract <source-path> --no-cluster

# 社区检测（无需 LLM）
graphify cluster-only <source-path> --no-label

# 语义索引（需要 LLM API key）
DEEPSEEK_API_KEY=xxx graphify extract <source-path>   # 需 LLM

# 查询
graphify query "FTL garbage collection"
graphify path "NAND controller" "write buffer"
graphify explain "wear leveling"
```

### Graphify vs CodeGraph 分工

| 维度 | Graphify | CodeGraph |
|------|----------|-----------|
| 分析粒度 | 文件级 + 语义级 | 函数级（调用图） |
| 覆盖内容 | 代码 + Markdown + PDF | 纯代码结构 |
| 核心能力 | 社区检测、概念解释、路径查询 | 调用链、影响分析、CI 门禁 |
| 典型问题 | "为什么这样设计" | "谁调用了这个函数" |

## C 语言已知限制

| 限制 | 原因 | 补充方案 |
|------|------|----------|
| 函数指针调用 | tree-sitter 无法静态解析 | cscope 模式 2/3 |
| 宏展开 | #define 不展开 | cscope 模式 4 |
| 条件编译 | #ifdef 分支不全部解析 | Doxygen 配置预定义宏 |

> CodeGraph 覆盖 ~80%，cscope 补充 ~15%（函数指针+宏），Doxygen 补充 ~5%（可视化）