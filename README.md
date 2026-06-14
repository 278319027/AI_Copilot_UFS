# SSD Firmware AI Copilot

面向 SSD 固件团队的 AI 辅助编程体系，基于 `OpenCode Agent` + `CodeGraph`（调用图分析）+ `Graphify`（知识图谱）。

## 能力概览

| 能力 | 工具支撑 | 状态 |
|------|---------|------|
| 需求理解 | 提示词库 + Memory 规则 | ✅ 已建立 |
| 设计理解 | 提示词库 + Memory 规则 | ✅ 已建立 |
| 代码结构分析 | CodeGraph（调用图/影响分析/MCP） | ✅ 已部署（FEMU） |
| 知识图谱查询 | Graphify（社区检测/概念解释） | ✅ 已部署（FEMU） |
| 实现方案生成 | 提示词库 + Memory 规则 | ✅ 已建立 |
| 代码生成 | Development Skill + 小任务原则 | ✅ 已建立 |
| Review 辅助 | Review Skill + CodeGraph 验证 | ✅ 已建立 |
| 测试建议生成 | 提示词库 | ✅ 已建立 |

## 仓库结构

```text
zsf/
├── README.md                                # 本文件
├── opencode.json                            # MCP 配置（CodeGraph → FEMU）
│
├── docs/                        # 项目事实与设计信息
│   ├── SSD_Firmware_AI_Copilot_Methodology.md   # 方法论总文档
│   ├── research/                # 调研与部署文档
│   │   ├── explore_ai_coding.md   # AI 辅助编程可行性研究报告
│   │   └── CodeGraph_Setup.md     # CodeGraph 部署与使用教程
│   └── TEST/                    # 测试与度量
│       └── metrics_template.md  # 效果度量模板
│
├── .opencode/                   # OpenCode Agent 配置
│   ├── opencode.json             # OpenCode 插件配置（graphify）
│   ├── plugins/
│   │   └── graphify.js           # Graphify Git Hook 插件
│   ├── memory/                 # 项目规则与约束
│   │   ├── architecture.md      # 分层规则 + CodeGraph 查询规则
│   │   ├── coding_style.md      # 编码风格
│   │   ├── concurrency_rules.md # 并发安全规则
│   │   ├── design_rules.md    # 设计规则（状态机/Context/资源管理）
│   │   ├── review_rules.md    # Review 检查项
│   │   └── testing_rules.md   # 测试规则
│   ├── knowledge/              # 硬件知识库
│   │   ├── README.md           # 知识库说明和使用原则
│   │   ├── nand_controller/    # NAND 控制器知识
│   │   │   ├── registers.md    # 寄存器定义和配置顺序
│   │   │   ├── operations.md   # 操作序列和命令码
│   │   │   ├── constraints.md  # 时序约束和并发约束
│   │   │   └── ecc.md          # ECC 纠错与坏块管理
│   │   ├── nvme_spec/          # NVMe 规约知识
│   │   │   ├── admin_commands.md # Admin 命令集和数据结构
│   │   │   ├── io_commands.md   # I/O 命令集
│   │   │   └── error_handling.md # 错误处理与状态码
│   │   └── platform/           # 平台相关知识
│   │       ├── memory_map.md   # 内存映射、中断分配、时钟树
│   │       └── power_states.md # 电源状态转换与约束
│   └── skills/                 # 可复用工作流
│       ├── development/         # 开发 Skill（含 CodeGraph 查询步骤）
│       ├── review/              # Review Skill（含 CodeGraph 验证步骤）
│       ├── drawio-flowchart/   # 流程图生成 Skill
│       └── graphify/           # 知识图谱 Skill
│
├── templates/                  # 模板和提示词库
│   └── prompt_library.md       # 需求理解/设计/编码/Review/测试
│
└── .gitignore
```

## 推荐阅读顺序

| 序号 | 文档 | 内容 |
|------|------|------|
| 1 | [方法论总文档](./docs/SSD_Firmware_AI_Copilot_Methodology.md) | 核心原则、架构、工作流、路线图 |
| 2 | [可行性研究报告](./docs/research/explore_ai_coding.md) | 行业实证、场景可行性矩阵、优化建议 |
| 3 | [CodeGraph 教程](./docs/research/CodeGraph_Setup.md) | 工具选型、安装部署、MCP 集成、日常使用 |
| 4 | [Architecture 规则](./.opencode/memory/architecture.md) | 分层规则 + CodeGraph 查询规则 |
| 5 | [Concurrency 规则](./.opencode/memory/concurrency_rules.md) | 并发安全：volatile/ISR/锁/DMA/原子/多核 |
| 6 | [Design 规则](./.opencode/memory/design_rules.md) | 状态机/Context/资源管理/错误处理 |
| 7 | [Review 规则](./.opencode/memory/review_rules.md) | Review 检查项 + SSD 固件专项 |
| 8 | [NAND ECC 知识](./.opencode/knowledge/nand_controller/ecc.md) | ECC 纠错、弱块标记、坏块管理 |
| 9 | [NVMe 错误处理](./.opencode/knowledge/nvme_spec/error_handling.md) | NVMe 状态码、重试策略、断电恢复 |
| 10 | [Development Skill](./.opencode/skills/development/skill.md) | 开发流程 + CodeGraph 查询步骤 |
| 11 | [提示词库](./templates/prompt_library.md) | 需求理解/设计方案/编码/Review/测试 |

## 核心原则

```text
Source Code > Design Docs > Memory > Prompt
```

- **代码优先**：代码是真实实现，文档可能滞后，Memory 保存规则，Prompt 只是当前输入
- **小任务原则**：每次 200~500 行，不扩大需求
- **AI 辅助不替代**：人负责架构决策、设计确认、风险判断、最终责任
- **CodeGraph 先查再改**：修改前必须查询影响范围（当前部署于 FEMU `../femu/hw/femu/`）

## 标准使用流程

```text
需求 / 设计文档
  │
  ▼
Step 1: AI 理解需求（基于文档 + Memory 规则）
  │
  ▼
Step 2: CodeGraph 查询                     ← MCP 工具（当前部署于 FEMU）
  │  codegraph callers <symbol>           ← 谁调用了？
  │  codegraph callees <symbol>           ← 调用了谁？
  │  codegraph impact <symbol>            ← 影响范围？
  │  codegraph explore <query>            ← 区域探索
  │  cscope -L2/-L4 <ptr/macro>           ← 函数指针/宏（补充）
  │
  ▼
Step 3: 输出设计方案（基于 CodeGraph 数据）
  │
  ▼
Step 4: 小步编码（200~500 行/任务）
  │
  ▼
Step 5: Review（CodeGraph 验证影响范围 + Review Skill）
  │
  ▼
Step 6: 测试建议（基于提示词库 + metrics 度量）
  │
  ▼
Step 7: 人工确认 + 提交
```

## CodeGraph 快速入门

### 工具组成

| 工具 | 用途 | 覆盖场景 | 安装 |
|------|------|----------|------|
| **ops-codegraph** | 调用图/依赖图/影响分析，30+ MCP 工具 | ~80% | `npm install -g @optave/codegraph` |
| **ctags + cscope** | 函数指针/宏查询（tree-sitter 盲区） | ~15% | `apt install universal-ctags cscope` |
| **Doxygen** | 交互式 HTML 文档+可视化图（按需） | ~5% | `apt install doxygen graphviz` |

### 安装部署

详细安装步骤见 [CodeGraph 部署与使用教程](./docs/research/CodeGraph_Setup.md)。

核心工具链：

| 工具 | 用途 | 安装 |
|------|------|------|
| **ops-codegraph** | 调用图/依赖图/影响分析 | `npm install -g @optave/codegraph` |
| **ctags + cscope** | 函数指针/宏查询（补充） | `apt install universal-ctags cscope` |
| **Doxygen + Graphviz** | 交互式文档（按需） | `apt install doxygen graphviz` |

### 常用查询

```bash
# ops-codegraph MCP（AI 直接调用）
codegraph query nand_read_page                  # 搜索符号
codegraph callers nand_read_page                # 谁调用了
codegraph callees nand_read_page                # 调用了谁
codegraph impact nand_read_page                 # 影响分析
codegraph explore "nand read write"             # 区域探索
codegraph status                                # 索引统计

# cscope（补充函数指针和宏）
cscope -d -L2 "func_ptr_name"    # 函数指针调用者
cscope -d -L3 "func_ptr_name"    # 函数指针指向
cscope -d -L4 "MACRO_NAME"       # 宏使用位置
cscope -d -L8 "nand_ctx.h"       # 谁包含了这个头文件
```

### MCP 集成（OpenCode Agent）

在项目根目录 `opencode.json` 中添加（使用 `opencode mcp add codegraph` 或手动编辑）：

```json
{
  "$schema": "https://opencode.ai/config.json",
  "mcp": {
    "codegraph": {
      "type": "local",
      "command": ["codegraph", "serve", "--mcp", "--path", "/home/tcb/AI_Proj/femu/hw/femu"],
      "enabled": true,
      "env": {}
    }
  }
}
```

> 注意：opencode 配置键是 `mcp` 而非 `mcpServers`，`command` 是数组而非字符串。修改后需重启 opencode。

> 详细教程见 [CodeGraph 部署与使用教程](./docs/research/CodeGraph_Setup.md)

## Graphify 知识图谱

Graphify 是项目级多模态知识图谱，与 CodeGraph 互补：

| 维度 | Graphify | CodeGraph |
|------|----------|-----------|
| 分析粒度 | 文件级 + 语义级 | 函数级（调用图） |
| 覆盖内容 | 代码 + Markdown + PDF | 纯代码结构 |
| 核心能力 | 社区检测、概念解释、路径查询 | 调用链、影响分析、CI 门禁 |
| 典型问题 | "为什么这样设计"、"相关概念有哪些" | "谁调用了这个函数"、"改了影响谁" |

### 常用命令

```bash
graphify query "<问题>"           # 知识图谱查询
graphify path "<A>" "<B>"         # 两个概念间的关系路径
graphify explain "<概念>"          # 概念聚焦解释
graphify update .                 # 代码变更后更新图谱（AST-only，无需 LLM）
graphify extract <path>           # 首次构建或论文/文档语义提取（需 LLM API key）
```

> Graphify 已部署于 FEMU 项目（`../femu/hw/femu/`），与 CodeGraph 配合提供代码结构 + 语义查询双通道。论文语义索引需 `DEEPSEEK_API_KEY` 或 `OPENAI_API_KEY`。

## 团队落地原则

- 以文档为输入，以代码为事实，以规则为约束。
- 每次只做一个明确任务，避免大范围改动。
- 所有 AI 输出都必须经过人工确认和工程验证。
- 设计、规则、代码三者必须分离维护。
- 修改前必须查询 CodeGraph（当前部署于 FEMU `../femu/hw/femu/`），确认影响范围不超出预期。

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

详见 [可行性研究报告](./docs/research/explore_ai_coding.md)