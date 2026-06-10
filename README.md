# SSD Firmware AI Copilot

面向 SSD 固件团队的 AI 辅助编程体系，基于 `Qwen 27B` + `OpenCode Agent` + `CodeGraph`。

## 能力概览

| 能力 | 工具支撑 | 状态 |
|------|---------|------|
| 需求理解 | 提示词库 | ✅ 已建立 |
| 设计理解 | 提示词库 | ✅ 已建立 |
| 代码定位 | ops-codegraph + cscope | ✅ 已建立 |
| 影响分析 | ops-codegraph MCP | ✅ 已建立 |
| 实现方案生成 | 提示词库 + Memory 规则 | ✅ 已建立 |
| 代码生成 | Development Skill + 小任务原则 | ✅ 已建立 |
| Review 辅助 | Review Skill + CodeGraph 验证 | ✅ 已建立 |
| 测试建议生成 | 提示词库 | ✅ 已建立 |

## 仓库结构

```text
zsf/
├── SSD_Firmware_AI_Copilot_Methodology.md   # 方法论总文档
├── explore_ai_coding.md                     # AI 辅助编程可行性研究报告
├── CodeGraph_Setup.md                       # CodeGraph 部署与使用教程
├── README.md                                # 本文件
│
├── docs/                        # 项目事实与设计信息（不保存 AI 规则）
│   ├── README.md
│   ├── SAD/                    # 软件架构设计
│   ├── SDD/                    # 模块设计文档
│   ├── ICD/                    # 接口控制文档
│   └── TEST/                   # 测试设计文档
│
├── .opencode/                   # OpenCode Agent 配置
│   ├── memory/                 # 项目规则与约束
│   │   ├── architecture.md     # 分层规则 + CodeGraph 查询规则
│   │   ├── coding_style.md     # 编码风格
│   │   ├── design_rules.md    # 设计规则（状态机/Context/资源管理）
│   │   ├── review_rules.md    # Review 检查项
│   │   └── testing_rules.md   # 测试规则
│   └── skills/                 # 可复用工作流
│       ├── development/        # 开发 Skill（含 CodeGraph 查询步骤）
│       ├── review/             # Review Skill（含 CodeGraph 验证步骤）
│       └── drawio-flowchart/  # 流程图生成 Skill
│
├── .codegraph/                 # CodeGraph 配置（纳入版本控制）
│   ├── config.json             # ops-codegraph 排除目录配置
│   └── Doxyfile                # Doxygen 配置（含 SSD 固件宏预定义）
│
├── scripts/                    # 工具脚本
│   ├── install_codegraph.sh    # 一键安装 CodeGraph 工具链
│   ├── init_codegraph.sh       # 项目初始化（构建索引）
│   └── install_git_hook.sh     # Git Hook 安装（提交后自动更新索引）
│
└── templates/                  # 模板和提示词库
    ├── README.md
    └── prompt_library.md
```

## 推荐阅读顺序

| 序号 | 文档 | 内容 |
|------|------|------|
| 1 | [方法论总文档](./SSD_Firmware_AI_Copilot_Methodology.md) | 核心原则、架构、工作流、路线图 |
| 2 | [可行性研究报告](./explore_ai_coding.md) | 行业实证、场景可行性矩阵、优化建议 |
| 3 | [CodeGraph 教程](./CodeGraph_Setup.md) | 工具选型、安装部署、MCP 集成、日常使用 |
| 4 | [Architecture 规则](./.opencode/memory/architecture.md) | 分层规则 + CodeGraph 查询规则 |
| 5 | [Development Skill](./.opencode/skills/development/skill.md) | 开发流程 + CodeGraph 查询步骤 |
| 6 | [Review Skill](./.opencode/skills/review/skill.md) | Review 流程 + CodeGraph 验证步骤 |
| 7 | [提示词库](./templates/prompt_library.md) | 需求理解/设计方案/编码/Review/测试 |

## 核心原则

```text
Source Code > Design Docs > Memory > Prompt
```

- **代码优先**：代码是真实实现，文档可能滞后，Memory 保存规则，Prompt 只是当前输入
- **小任务原则**：每次 200~500 行，不扩大需求
- **AI 辅助不替代**：人负责架构决策、设计确认、风险判断、最终责任
- **CodeGraph 先查再改**：修改前必须查询影响范围，确认不会遗漏受影响的调用者

## 标准使用流程

```text
需求 / 设计文档
  │
  ▼
Step 1: AI 理解需求
  │
  ▼
Step 2: 查询 CodeGraph                ← ops-codegraph MCP + cscope
  │  get_callers(函数)                ← 谁调用了？
  │  get_callees(函数)                ← 调用了谁？
  │  impact(文件)                     ← 影响范围？
  │  symbol_search(结构体)           ← 在哪里使用？
  │  find_by_imports(头文件)          ← 包含依赖？
  │  get_dependency_graph(模块)       ← 模块依赖？
  │  cscope -L2/-L4(函数指针/宏)      ← 补充查询
  │
  ▼
Step 3: 输出设计方案（基于 CodeGraph 数据）
  │
  ▼
Step 4: 小步编码（200~500 行）
  │
  ▼
Step 5: Review（CodeGraph 验证影响范围）
  │
  ▼
Step 6: 测试建议
  │
  ▼
Step 7: 人工确认 + 提交 → Git Hook 自动更新索引
```

## CodeGraph 快速入门

### 工具组成

| 工具 | 用途 | 覆盖场景 | 安装 |
|------|------|----------|------|
| **ops-codegraph** | 调用图/依赖图/影响分析，30+ MCP 工具 | ~80% | `npm install -g @optave/codegraph` |
| **ctags + cscope** | 函数指针/宏查询（tree-sitter 盲区） | ~15% | `apt install universal-ctags cscope` |
| **Doxygen** | 交互式 HTML 文档+可视化图（按需） | ~5% | `apt install doxygen graphviz` |

### 一键安装

```bash
bash scripts/install_codegraph.sh    # 安装 Node.js + ops-codegraph + ctags + cscope + doxygen
bash scripts/init_codegraph.sh      # 项目初始化（构建索引）
bash scripts/install_git_hook.sh    # 安装 Git Hook（提交后自动更新索引）
```

### 常用查询

```bash
# ops-codegraph MCP（AI 直接调用）
codegraph find nand_read_page                    # 搜索符号
codegraph callers nand_read_page                 # 谁调用了
codegraph callees nand_read_page                 # 调用了谁
codegraph impact source/driver/nand/nand_io.c    # 影响分析
codegraph deps source/driver/nand                 # 模块依赖
codegraph stats                                   # 索引统计

# cscope（补充函数指针和宏）
cscope -d -L2 "func_ptr_name"    # 函数指针调用者
cscope -d -L3 "func_ptr_name"    # 函数指针指向
cscope -d -L4 "MACRO_NAME"       # 宏使用位置
cscope -d -L8 "nand_ctx.h"       # 谁包含了这个头文件
```

### MCP 集成（OpenCode Agent）

在 `.opencode/opencode.json` 中添加：

```json
{
  "mcpServers": {
    "codegraph": {
      "command": "codegraph",
      "args": ["mcp"],
      "env": {}
    }
  }
}
```

> 详细教程见 [CodeGraph 部署与使用教程](./CodeGraph_Setup.md)

## 团队落地原则

- 以文档为输入，以代码为事实，以规则为约束。
- 每次只做一个明确任务，避免大范围改动。
- 所有 AI 输出都必须经过人工确认和工程验证。
- 设计、规则、代码三者必须分离维护。
- 修改前必须查询 CodeGraph，确认影响范围不超出预期。

## 可行性结论

> 基于 13 项学术研究（EmbedEval、AutoEmbed、RespCode、NOKHAB Lab 等）和产业案例（Solidigm、Promwad、Claude Code Zephyr）的综合评估。

| 场景 | 可行性 | 前提 |
|------|--------|------|
| 需求理解 & 文档解析 | ★★★★★ | 设计文档质量要高 |
| 代码定位 & CodeGraph | ★★★★★ | 需建设索引 |
| 影响范围分析 | ★★★★ | 依赖 CodeGraph 完整性 |
| 接口层代码生成 | ★★★★ | 需注入接口规约 |
| Review 辅助 | ★★★★ | 内存安全类成熟，并发安全需增强 |
| 测试用例生成 | ★★★★ | 正常路径好，故障注入需领域知识 |
| 方案生成（模块内） | ★★★ | 需完整文档 + 约束规则 |
| FTL 核心算法生成 | ★ | 不可行，纯人工 |
| NAND 物理层驱动 | ★ | 不可行，纯人工 |

详见 [可行性研究报告](./explore_ai_coding.md)