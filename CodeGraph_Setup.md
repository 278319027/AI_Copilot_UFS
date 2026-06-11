# CodeGraph 部署与使用教程

> 适用环境：Ubuntu 20.04+ / 22.04 LTS  
> 目标代码库：C 语言 SSD 固件项目（10万行+）  
> 集成对象：OpenCode Agent + Qwen 27B  
> 核心原则：**尽量使用现有工具，减少自建脚本**

---

## 目录

1. [方案总览与选型](#一方案总览与选型)
2. [主工具：ops-codegraph](#二主工具ops-codegraph)
3. [辅助工具：ctags + cscope](#三辅助工具ctags--cscope)
4. [补充工具：Doxygen](#四补充工具doxygen)
5. [OpenCode Agent 集成](#五opencode-agent-集成)
6. [C 语言特殊问题与对策](#六c-语言特殊问题与对策)
7. [日常使用流程](#七日常使用流程)
8. [从零搭建：步骤清单](#八从零搭建步骤清单)

---

## 一、方案总览与选型

### 1.1 核心思路

不用自建脚本，直接用成熟工具组合：

```text
┌─────────────────────────────────────────────────────────────┐
│ OpenCode Agent                                              │
│   │                                                         │
│   ├── ops-codegraph (MCP) ── 调用图、依赖图、影响分析        │
│   │   └── 30+ MCP 工具，AI 直接查询，无需手动脚本           │
│   │                                                         │
│   ├── ctags + cscope ────── 符号索引、交叉引用               │
│   │   └── 补充 C 语言函数指针/宏等 tree-sitter 无法解析的   │
│   │                                                         │
│   └── Doxygen ───────────── 交互式文档 + 可视化图（按需）    │
│       └── 人工浏览架构关系、新人学习时使用                   │
└─────────────────────────────────────────────────────────────┘
```

### 1.2 为什么选 ops-codegraph

调研了 3 个主流 CodeGraph 工具，对比如下：

| 能力 | ops-codegraph | codegraph-ai | sdsrss/code-graph-mcp |
|------|--------------|-------------|----------------------|
| **C 语言支持** | ✅ 函数/导入/导出 | ✅ 函数/类/导入/调用 | ⚠️ 函数/导入（有限） |
| **C 函数指针解析** | ❌ tree-sitter 限制 | ❌ 同左 | ❌ 同左 |
| **MCP 工具数** | 30 | 45 | ~15 |
| **安装方式** | `npm install -g` | `npm install -g` | `npm install -g` |
| **构建方式** | `codegraph build` 一步 | 自动索引 | 自动索引 |
| **增量索引** | ✅ FNV-1a 哈希检测变更 | ✅ 文件哈希 | ✅ |
| **数据库** | SQLite（本地） | RocksDB（本地） | SQLite + sqlite-vec |
| **语义搜索** | ✅ BM25 + 可选嵌入 | ✅ 本地嵌入 | ✅ FTS5 + 向量 |
| **无需 API Key** | ✅ | ✅ | ✅ |
| **无需 Docker** | ✅ | ✅ | ✅ |
| **与 OpenCode 兼容** | ✅ MCP stdio | ✅ MCP stdio | ✅ MCP stdio |
| **成熟度** | v3.9+，活跃维护 | v2.0+，活跃维护 | v0.7，较新 |
| **影响分析** | ✅ `impact` 命令 | ✅ many tools | ⚠️ 有限 |

**选择 ops-codegraph 的理由**：
1. C 语言支持最完整（函数、导入、导出、调用点）
2. 30+ MCP 工具覆盖 SSD 固件需要的所有查询
3. 零配置 — `codegraph build` 一条命令即可
4. 增量更新 — 毫秒级，适合 git hook 集成
5. 纯本地运行 — 无需网络、无需 API Key、无需 Docker

### 1.3 C 语言已知限制

所有基于 tree-sitter 的工具（包括 ops-codegraph）对 C 语言有共同限制：

| 限制 | 原因 | 补充方案 |
|------|------|---------|
| **函数指针调用** | tree-sitter 无法静态解析 `(*func_ptr)()` | cscope 模式 2/3 补充 |
| **宏展开** | `#define` 不展开 | cscope 模式 4/6 补充 |
| **条件编译** | `#ifdef` 分支不全部解析 | Doxygen 配置预定义宏 |
| **C 继承** | C 无类继承 | 不适用（C 没有 class） |
| **C 调用点** | ops-codegraph 标注 ❌ | 函数调用本身 ✅，但 `obj.func()` 风格缺失 |

**对策**：ops-codegraph 解决 80% 的查询需求，剩余 20%（函数指针、宏）用 cscope 补充。

---

## 二、主工具：ops-codegraph

### 2.1 安装

```bash
#!/bin/bash
# install_codegraph.sh — 安装 ops-codegraph

# 需要 Node.js 18+
# Ubuntu 22.04 默认 Node.js 可能较旧，建议用 nvm 安装最新版
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
source ~/.bashrc
nvm install 22
nvm use 22

# 安装 ops-codegraph
npm install -g @optave/codegraph

# 验证
codegraph --version
```

### 2.2 构建索引

```bash
# 在 SSD 固件项目根目录中执行
cd /path/to/ssd_firmware

# 一条命令构建索引 — 自动扫描所有语言
codegraph build

# 输出示例：
# ✅ Indexed 847 files (1.2s)
# ✅ .codegraph/graph.db created (3.4 MB)
```

**就这么简单。** 不需要配置文件、不需要 compile_commands.json、不需要 Docker。

### 2.3 核心功能验证

```bash
# 查看索引统计
codegraph stats

# 查找函数
codegraph find nand_read_page

# 谁调用了 nand_read_page（调用者）
codegraph callers nand_read_page

# nand_read_page 调用了谁（被调用者）
codegraph callees nand_read_page

# 影响分析 — 修改 nand_read_page 会影响哪些文件
codegraph impact source/driver/nand/nand_io.c

# 依赖图
codegraph deps source/driver/nand

# 检查架构边界违规
codegraph check
```

### 2.4 可用的 MCP 工具列表

ops-codegraph 提供 30 个 MCP 工具，以下是对 SSD 固件开发最重要的：

| 类别 | MCP 工具 | 用途 | 对应 CodeGraph 问题 |
|------|----------|------|---------------------|
| **符号查找** | `symbol_search` | 按名称/自然语言搜索符号 | 这是什么函数？ |
| **调用关系** | `get_callers` | 谁调用了 X | who_calls |
| **调用关系** | `get_callees` | X 调用了谁 | callees |
| **调用关系** | `get_call_graph` | 完整调用链（含深度） | 调用链分析 |
| **依赖关系** | `get_dependency_graph` | 文件/模块依赖 | module_deps |
| **依赖关系** | `find_by_imports` | 谁包含了这个头文件 | include 分析 |
| **符号详情** | `get_detailed_symbol` | 函数签名、复杂度、源码 | 符号完整信息 |
| **符号详情** | `get_symbol_info` | 快速元数据（签名、可见性） | 快速查询 |
| **影响分析** | `impact` | 修改某文件的影响范围 | impact |
| **入口点** | `find_entry_points` | main 函数、ISR 等 | 程序入口 |
| **架构** | `check` | 架构边界违规检查 | 模块边界验证 |
| **架构** | `manifesto` | 生成/检查架构规则 | 强制模块边界 |
| **搜索** | `find_by_pattern` | 正则搜索函数体 | 模式匹配 |
| **搜索** | `find_by_signature` | 按参数数量/返回类型搜索 | 接口查找 |
| **搜索** | `traverse_graph` | 自定义图遍历 | 复杂查询 |
| **未使用代码** | `find_dead_code` | 未被引用的导出 | 死代码检测 |

### 2.5 增量更新

```bash
# 增量索引 — 只处理变更文件，毫秒级
codegraph build

# 也可以通过 git hook 自动触发（见第八节）
```

### 2.6 配置排除项

如果项目中有不需要索引的目录，创建 `.codegraph/config.json`：

```json
{
  "exclude": [
    "third_party/**",
    "vendor/**",
    "test/**",
    "tests/**",
    "_build/**",
    "out/**"
  ]
}
```

---

## 三、辅助工具：ctags + cscope

ops-codegraph 用 tree-sitter 解析 C 代码，但**无法解析函数指针和宏**。ctags + cscope 作为补充。

### 3.1 安装

```bash
sudo apt-get install -y universal-ctags cscope
```

### 3.2 构建 ctags 索引

```bash
cd /path/to/ssd_firmware

# 生成 tags 文件（供编辑器和人工查询使用）
find source -name "*.c" -o -name "*.h" | \
    ctags -L- --fields=+neKSt --extras=+q --c-kinds=+psgutdefl -o tags

# 生成 JSON 格式（供 OpenCode Agent 使用）
find source -name "*.c" -o -name "*.h" | \
    ctags -L- --fields=+neKSt --extras=+q --c-kinds=+psgutdefl \
        --output-format=json -o .codegraph/ctags_index.json
```

### 3.3 构建 cscope 数据库

```bash
cd /path/to/ssd_firmware
mkdir -p .codegraph

# 生成文件列表
find source -name "*.c" -o -name "*.h" > .codegraph/cscope.files

# 构建数据库
cscope -b -q -k -i .codegraph/cscope.files
```

### 3.4 cscope 查询模式（补充 ops-codegraph 的盲区）

| 模式 | 查询 | ops-codegraph 覆盖？ | 何时用 cscope |
|------|------|---------------------|--------------|
| 0 | 查找 C 符号 | ✅ symbol_search | 一般不需要 |
| 1 | 查找全局定义 | ✅ find 函数/变量 | 一般不需要 |
| **2** | **查找调用者** | ⚠️ 函数指针 | **SSD 固件常用** |
| **3** | **查找被调用函数** | ⚠️ 函数指针 | **SSD 固件常用** |
| **4** | **查找文本字符串** | ❌ | **宏名/错误码搜索** |
| 6 | 正则搜索 | ⚠️ find_by_pattern | 复杂正则时 |
| 7 | 查找文件 | ✅ | 一般不需要 |
| **8** | **查找 #include** | ⚠️ find_by_imports | **头文件依赖** |

加粗的模式是 ops-codegraph **可能遗漏**的场景，需要 cscope 补充。

### 3.5 Git Hook 自动更新

```bash
# .git/hooks/post-commit
#!/bin/bash
PROJECT_ROOT="$(git rev-parse --show-toplevel)"
CHANGED_C=$(git diff-tree --no-commit-id --name-only -r HEAD | grep -cE '\.(c|h)$')

if [ "$CHANGED_C" -gt 0 ]; then
    echo "[CodeGraph] 检测到 C 文件变更，更新索引..."
    cd "$PROJECT_ROOT"
    
    # ops-codegraph 增量更新（毫秒级）
    codegraph build &
    
    # ctags 更新
    find source -name "*.c" -o -name "*.h" | \
        ctags -L- --fields=+neKSt --extras=+q --c-kinds=+psgutdefl -o tags &
    
    # cscope 更新
    cscope -b -q -k -i .codegraph/cscope.files &
    
    wait
    echo "[CodeGraph] 索引已更新"
fi
```

---

## 四、补充工具：Doxygen

Doxygen 生成交互式 HTML 文档和可视化图，适合**人工浏览**和**新人学习**。ops-codegraph 也能回答查询，但可视化图 Doxygen 更直观。

### 4.1 安装

```bash
sudo apt-get install -y doxygen graphviz
```

### 4.2 最简配置

在项目根目录创建 `Doxyfile`：

```ini
# 最小化 Doxygen 配置 — 适合 SSD 固件项目

PROJECT_NAME           = "SSD Firmware"
OUTPUT_DIRECTORY       = .codegraph/doxygen
INPUT                  = source
FILE_PATTERNS          = *.c *.h
RECURSIVE              = YES
EXTRACT_ALL            = YES
EXTRACT_PRIVATE        = YES
EXTRACT_STATIC         = YES
HAVE_DOT               = YES
CALL_GRAPH             = YES
CALLER_GRAPH           = YES
INCLUDE_GRAPH           = YES
INCLUDED_BY_GRAPH       = YES
COLLABORATION_GRAPH     = YES
DOT_GRAPH_MAX_NODES    = 50
DOT_IMAGE_FORMAT       = svg
INTERACTIVE_SVG        = YES
GENERATE_HTML          = YES
GENERATE_LATEX         = NO
SOURCE_BROWSER         = YES
OPTIMIZE_OUTPUT_FOR_C  = YES
QUIET                  = YES
WARN_IF_UNDOCUMENTED   = NO

# SSD 固件常见宏预定义
PREDEFINED             = ARM_MATH_CM4 \
                         __STATIC_INLINE=static inline \
                         __ALIGNED(x)= \
                         __PACKED_STRUCT=struct __attribute__((packed))
```

### 4.3 构建

```bash
# 一条命令
doxygen Doxyfile

# 浏览
firefox .codegraph/doxygen/html/index.html
```

### 4.4 更新频率

Doxygen 构建耗时较长，**不需要每次提交都更新**：

| 场景 | 频率 |
|------|------|
| 日常开发 | 不需要 |
| 新人入职 | 一次性构建 |
| 版本发布前 | 构建一次 |
| 架构理解需要 | 按需构建 |

```bash
# 添加到 crontab（可选）
# 每天凌晨 2:00 更新
0 2 * * * cd /path/to/ssd_firmware && doxygen Doxyfile > /dev/null 2>&1
```

---

## 五、OpenCode Agent 集成

### 5.1 MCP 服务器配置

编辑项目根目录 `opencode.json`，或在 `~/.config/opencode/opencode.json` 中全局配置，添加 ops-codegraph MCP 服务器：

> 也可以使用命令：`opencode mcp add codegraph`

```json
{
  "$schema": "https://opencode.ai/config.json",
  "mcp": {
    "codegraph": {
      "type": "local",
      "command": ["codegraph", "mcp"],
      "enabled": true,
      "env": {}
    }
  }
}
```

> **重要**：opencode 的配置键是 `mcp`（不是 `mcpServers`），`command` 是字符串数组（不是 `command`+`args`）。修改后需重启 opencode。
```

**就这样。** 不需要额外配置，`codegraph mcp` 会自动：
- 在当前项目目录中查找 `.codegraph/graph.db`
- 如果没有索引，自动构建
- 提供 30 个 MCP 工具给 OpenCode Agent

### 5.2 在 Skill 中使用 CodeGraph

更新 `.opencode/skills/development/skill.md`：

```markdown
# Development Skill

## 职责
- 读取设计文档
- 读取现有代码
- 查询 CodeGraph         ← 新增
- 分析影响范围
- 输出修改方案
- 生成代码
- 生成测试建议

## 输入
- 模块设计文档
- 相关源文件
- 相关规则文件
- 相关调用关系          ← 新增：通过 CodeGraph MCP 获取

## 标准流程
1. 理解需求
2. **查询 CodeGraph**    ← 新增：先查影响范围
   - 使用 `get_callers` 查询谁调用了目标函数
   - 使用 `get_callees` 查询目标函数调用了谁
   - 使用 `impact` 查询修改影响范围
   - 使用 `find_by_imports` 查询头文件依赖
   - 使用 `get_dependency_graph` 查询模块依赖
3. 定位相关代码
4. 分析依赖关系
5. 输出设计方案
6. 生成代码
7. 生成测试建议

## CodeGraph 查询规则

### 修改前必须查询
- 修改任何函数签名前 → `get_callers`
- 修改任何结构体前 → `symbol_search` + `find_by_imports`
- 修改任何头文件前 → `find_by_imports`
- 新增模块前 → `get_dependency_graph`

### 函数指针场景需用 cscope 补充
ops-codegraph 无法解析函数指针调用，以下场景需用 cscope：
```bash
cscope -d -L2 "func_ptr_name"   # 谁通过函数指针调用了
cscope -d -L3 "func_ptr_name"   # 函数指针指向哪些函数
```

### 宏展开场景需用 cscope 补充
```bash
cscope -d -L4 "MACRO_NAME"      # 宏在哪些地方被使用
cscope -d -L6 "pattern"         # 正则搜索模式
```
```

### 5.3 在 Memory 中记录 CodeGraph 使用规则

在 `.opencode/memory/architecture.md` 中追加：

```markdown
## 4. CodeGraph 查询规则

### 4.1 AI 工作时必须先查询 CodeGraph

在生成代码前，AI 必须先通过 CodeGraph 了解影响范围。

### 4.2 查询工具

| 场景 | MCP 工具 | 补充工具 |
|------|---------|---------|
| 谁调用了函数 X | `get_callers` | cscope -L2 |
| 函数 X 调用了谁 | `get_callees` | cscope -L3 |
| 结构体在哪里使用 | `symbol_search` + `find_by_imports` | cscope -L0 |
| 修改接口的影响 | `impact` | cscope -L2 |
| 模块间依赖 | `get_dependency_graph` | — |
| #include 依赖 | `find_by_imports` | cscope -L8 |
| 宏使用 | `find_by_pattern` | cscope -L4/6 |
| 函数指针调用 | ⚠️ 有限 | **必须用 cscope** |

### 4.3 查询结果使用规则

- 修改任何接口前，必须先查询 `impact`
- 修改任何结构体前，必须先查询 `symbol_search` + `find_by_imports`
- 修改任何函数签名前，必须先查询 `get_callers`
- 新增模块前，必须先了解 `get_dependency_graph`
- 函数指针相关查询，**必须用 cscope 补充**
```

---

## 六、C 语言特殊问题与对策

### 6.1 函数指针（最关键的限制）

**问题**：SSD 固件大量使用函数指针（状态机、回调、驱动接口表），tree-sitter 无法静态解析。

```c
// 典型 SSD 固件函数指针模式
typedef struct {
    int (*init)(void);
    int (*read_page)(uint32_t block, uint32_t page, uint8_t *buf);
    int (*write_page)(uint32_t block, uint32_t page, const uint8_t *buf);
    int (*erase_block)(uint32_t block);
} NandDriverOps;

// ops-codegraph 能解析：
//   - NandDriverOps 结构体定义 ✅
//   - init/read_page/write_page/erase_block 字段名 ✅
// 无法解析：
//   - ops->read_page(block, page, buf) 实际调用了哪个函数 ❌
```

**对策**：用 cscope 补充。

```bash
# 查找所有对 nand_ops.read_page 的调用
cscope -d -L6 "nand_ops\.read_page" 

# 查找所有对函数指针类型 NandDriverOps 的赋值
cscope -d -L6 "read_page\s*="
```

### 6.2 宏展开

**问题**：SSD 固件使用大量宏（寄存器操作、位操作、断言），tree-sitter 不展开宏。

```c
// 典型 SSD 固件宏
#define REG_WRITE(base, offset, val)  (*((volatile uint32_t*)((base) + (offset))) = (val))
#define NAND_CTRL_BASE                0x50000000

// ops-codegraph 能看到：
//   - REG_WRITE 宏定义 ✅
// 无法知道：
//   - REG_WRITE(NAND_CTRL_BASE, CTRL_OFFSET, val) 展开后的调用关系 ❌
```

**对策**：Doxygen 配置 `PREDEFINED` 和 `MACRO_EXPANSION`，cscope 搜索宏使用。

### 6.3 条件编译

**问题**：`#ifdef` / `#ifndef` 导致不同编译配置下代码不同。

**对策**：ops-codegraph 基于 tree-sitter 会解析所有条件分支；Doxygen 配置 `PREDEFINED` 只展开指定配置。

### 6.4 对策总结

```text
┌─────────────────────────────────────────────────────────┐
│ 场景                    │ 主工具           │ 补充工具     │
├─────────────────────────┼──────────────────┼───────────┤
│ 函数调用关系（直接调用）│ ops-codegraph ✅ │ —          │
│ 函数指针调用            │ ⚠️ 有限          │ cscope ✅  │
│ 结构体定义和引用        │ ops-codegraph ✅ │ ctags ✅   │
│ #include 依赖           │ ops-codegraph ✅ │ cscope ✅  │
│ 宏定义和使用            │ ⚠️ 有限          │ cscope ✅  │
│ 模块间依赖              │ ops-codegraph ✅ │ —          │
│ 影响分析                │ ops-codegraph ✅ │ cscope ✅  │
│ 可视化浏览              │ Doxygen ✅       │ —          │
│ AI 直接查询             │ ops-codegraph ✅ │ —          │
│ 增量更新                │ ops-codegraph ✅ │ ctags ✅   │
└─────────────────────────┴──────────────────┴───────────┘

ops-codegraph 覆盖 ~80% 场景，cscope 补充 ~15%（函数指针+宏），Doxygen 补充 ~5%（可视化）
```

---

## 七、日常使用流程

### 7.1 AI 辅助开发流程

```text
需求 / 设计文档
      │
      ▼
Step 1: AI 理解需求
      │
      ▼
Step 2: AI 查询 CodeGraph                ◄── ops-codegraph MCP 工具
  │  get_callers(函数)                    ◄── cscope 补充（函数指针）
  │  get_callees(函数)                    ◄── cscope 补充（函数指针）
  │  impact(文件)                         ◄── 影响范围
  │  symbol_search(结构体)                ◄── 引用查找
  │  find_by_imports(头文件)               ◄── include 依赖
  │  get_dependency_graph(模块)            ◄── 模块依赖
      │
      ▼
Step 3: AI 输出设计方案（基于 CodeGraph 数据）
      │
      ▼
Step 4: AI 生成代码
      │
      ▼
Step 5: AI Review（使用 CodeGraph 验证影响范围）
      │
      ▼
Step 6: 人工确认 + 提交
      │
      ▼
Step 7: Git Hook 自动更新 CodeGraph      ◄── codegraph build + ctags + cscope
```

### 7.2 常用查询速查表

```bash
# ===== ops-codegraph CLI =====

# 构建索引（首次或增量）
codegraph build

# 查看统计
codegraph stats

# 查找函数
codegraph find nand_read_page

# 谁调用了 nand_read_page
codegraph callers nand_read_page

# nand_read_page 调用了谁
codegraph callees nand_read_page

# 修改影响分析
codegraph impact source/driver/nand/nand_io.c

# 模块依赖
codegraph deps source/driver/nand

# ===== cscope（补充函数指针和宏）=====

# 谁调用了 nand_read_page（含函数指针）
cscope -d -L2 "nand_read_page"

# nand_read_page 调用了谁
cscope -d -L3 "nand_read_page"

# 搜索宏使用
cscope -d -L4 "NAND_CTRL_BASE"

# 正则搜索模式
cscope -d -L6 "nand_ops\.read_page"

# ===== Doxygen（可视化浏览）=====

# 构建 HTML 文档+图（按需）
doxygen Doxyfile

# 浏览
firefox .codegraph/doxygen/html/index.html
```

### 7.3 新人快速上手

```bash
# 1. 安装工具（一次性）
bash scripts/install_all.sh

# 2. 构建索引
cd /path/to/ssd_firmware
codegraph build

# 3. 浏览架构
codegraph deps source/

# 4. 查看特定模块调用关系
codegraph find ftl_read

# 5. 浏览可视化文档（可选）
doxygen Doxyfile
firefox .codegraph/doxygen/html/index.html
```

---

## 八、从零搭建：步骤清单

### 8.1 一键安装脚本

```bash
#!/bin/bash
# scripts/install_all.sh — 一键安装所有 CodeGraph 工具
set -e

echo "=== Step 1: 安装 Node.js 22 ==="
if ! command -v node &> /dev/null || [[ "$(node -v | cut -d. -f1 | cut -dv -f2)" -lt 18 ]]; then
    echo "需要 Node.js 18+，正在安装..."
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
    source ~/.bashrc
    nvm install 22
    nvm use 22
fi
echo "Node.js: $(node -v)"

echo "=== Step 2: 安装 ops-codegraph ==="
npm install -g @optave/codegraph
echo "ops-codegraph: $(codegraph --version)"

echo "=== Step 3: 安装 ctags + cscope ==="
sudo apt-get update
sudo apt-get install -y universal-ctags cscope
echo "ctags: $(ctags --version | head -1)"
echo "cscope: $(cscope -V 2>&1 | head -1)"

echo "=== Step 4: 安装 Doxygen + Graphviz ==="
sudo apt-get install -y doxygen graphviz
echo "doxygen: $(doxygen --version)"
echo "graphviz: $(dot -V 2>&1)"

echo ""
echo "=== 安装完成 ==="
echo "下一步: cd /path/to/ssd_firmware && codegraph build"
```

### 8.2 项目初始化

```bash
#!/bin/bash
# scripts/init_codegraph.sh — 项目初始化

PROJECT_ROOT="${1:-.}"
cd "$PROJECT_ROOT"

echo "=== 构建 ops-codegraph 索引 ==="
codegraph build

echo "=== 构建 ctags 索引 ==="
mkdir -p .codegraph
find source -name "*.c" -o -name "*.h" | \
    ctags -L- --fields=+neKSt --extras=+q --c-kinds=+psgutdefl -o tags
echo "ctags 索引构建完成"

echo "=== 构建 cscope 数据库 ==="
find source -name "*.c" -o -name "*.h" > .codegraph/cscope.files
cscope -b -q -k -i .codegraph/cscope.files
echo "cscope 数据库构建完成"

echo ""
echo "=== 初始化完成 ==="
echo "codegraph stats 查看索引信息"
echo "codegraph find <symbol> 搜索符号"
echo "codegraph callers <func> 查询调用者"
echo "codegraph impact <file> 查询影响范围"
```

### 8.3 配置 .gitignore

```gitignore
# CodeGraph 生成文件
.codegraph/graph.db
.codegraph/graph.db-*
.codegraph/doxygen/
.codegraph/cscope.files
cscope.out
cscope.in.out
cscope.po.out

# 保留配置和脚本
!.codegraph/config.json
!.codegraph/Doxyfile
```

### 8.4 配置 Git Hook

```bash
# .git/hooks/post-commit
#!/bin/bash
PROJECT_ROOT="$(git rev-parse --show-toplevel)"
CHANGED_C=$(git diff-tree --no-commit-id --name-only -r HEAD | grep -cE '\.(c|h)$')

if [ "$CHANGED_C" -gt 0 ]; then
    cd "$PROJECT_ROOT"
    # ops-codegraph 增量更新（毫秒级）
    codegraph build
    # ctags 更新（秒级）
    find source -name "*.c" -o -name "*.h" | \
        ctags -L- --fields=+neKSt --extras=+q --c-kinds=+psgutdefl -o tags
fi
```

### 8.5 完整搭建清单

```text
┌──────────────────────────────────────────────────────────────────┐
│ CodeGraph 完整搭建清单                                            │
├──────────────────────────────────────────────────────────────────┤
│                                                                   │
│ □ 1. 环境安装                                                     │
│   □ 1.1 Node.js 22+                                              │
│   □ 1.2 ops-codegraph (`npm install -g @optave/codegraph`)       │
│   □ 1.3 ctags + cscope (`apt install universal-ctags cscope`)   │
│   □ 1.4 Doxygen + Graphviz (`apt install doxygen graphviz`)     │
│   □ 1.5 验证所有工具版本                                          │
│                                                                   │
│ □ 2. 项目初始化                                                   │
│   □ 2.1 `codegraph build`（构建主索引）                          │
│   □ 2.2 ctags 构建（符号索引）                                    │
│   □ 2.3 cscope 构建（交叉引用）                                   │
│   □ 2.4 配置 Doxyfile（按需）                                    │
│                                                                   │
│ □ 3. OpenCode 集成                                                │
│   □ 3.1 配置项目根目录 opencode.json（mcp 服务器，type: local）   │
│   □ 3.2 更新 .opencode/skills/development/skill.md              │
│   □ 3.3 更新 .opencode/skills/review/skill.md                   │
│   □ 3.4 更新 .opencode/memory/architecture.md                    │
│                                                                   │
│ □ 4. Git Hook 配置                                                │
│   □ 4.1 post-commit hook（自动更新索引）                         │
│   □ 4.2 .gitignore（排除生成文件）                                │
│                                                                   │
│ □ 5. 验证                                                         │
│   □ 5.1 `codegraph stats` 确认索引正常                           │
│   □ 5.2 `codegraph find <func>` 确认查询工作                    │
│   □ 5.3 `codegraph callers <func>` 确认调用图工作              │
│   □ 5.4 在 OpenCode Agent 中测试 MCP 查询                        │
│   □ 5.5 提交一个 C 文件变更，确认 Hook 触发更新                  │
│                                                                   │
│ □ 6. 可选                                                         │
│   □ 6.1 配置 .codegraph/config.json 排除目录                    │
│   □ 6.2 配置 Doxyfile 预定义宏                                   │
│   □ 6.3 设置 cron job 定期更新 Doxygen                           │
│                                                                   │
└──────────────────────────────────────────────────────────────────┘
```

---

## 附录：工具对比与选型依据

### A.1 ops-codegraph vs 自建脚本 vs 其他工具

| 维度 | ops-codegraph | 自建脚本（原教程） | codegraph-ai | sdsrss |
|------|--------------|-------------------|-------------|--------|
| **安装复杂度** | `npm install -g` | 多个脚本+配置 | `npm install -g` | `npm install -g` |
| **构建索引** | `codegraph build` | 多条命令 | 自动 | 自动 |
| **MCP工具数** | 30 | 0（bash查询） | 45 | ~15 |
| **C 函数调用** | ✅ | ✅（cscope） | ✅ | ⚠️ 有限 |
| **C 函数指针** | ❌ | ❌ | ❌ | ❌ |
| **C 宏** | ⚠️ 定义可见 | ✅（cscope） | ⚠️ | ⚠️ |
| **增量更新** | ✅ FNV-1a | 需手动 | ✅ | ✅ |
| **语义搜索** | ✅ BM25 | ❌ | ✅ 嵌入 | ✅ |
| **影响分析** | ✅ `impact` | 需自建 | ✅ | ⚠️ |
| **架构检查** | ✅ `check` | ❌ | ✅ | ❌ |
| **维护成本** | 极低 | 高 | 低 | 低 |
| **与OpenCode集成** | ✅ MCP | 需自建 | ✅ MCP | ✅ MCP |

### A.2 推荐组合

```text
主工具:  ops-codegraph  — 解决 80% 的 CodeGraph 需求
辅助工具: ctags + cscope  — 补充函数指针和宏（15%）
补充工具: Doxygen        — 可视化浏览（5%）
```

这是**最小化自建工作**的组合：
- ops-codegraph：零自建，npm install 一步到位
- ctags + cscope：2 条命令构建，零自建脚本
- Doxygen：1 个配置文件，1 条命令构建
- OpenCode 集成：只需配置 MCP 服务器

**总自建代码量**：约 30 行（git hook + 安装脚本），对比原教程的数百行脚本。