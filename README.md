# SSD Firmware AI Copilot

本仓库用于沉淀一套面向 SSD 固件团队的 AI 辅助编程方法论、文档模板、规则体系和提示词库。

目标是让本地大模型 `Qwen 27B` 配合 `OpenCode Agent`，在固件工程中实现：

- 需求理解
- 设计理解
- 代码定位
- 实现方案生成
- 代码生成
- Review 辅助
- 测试建议生成

## 推荐阅读顺序

1. [方法论总文档](./SSD_Firmware_AI_Copilot_Methodology.md)
2. [Docs 体系说明](./docs/README.md)
3. [Memory 规则](./.opencode/memory/architecture.md)
4. [Development Skill](./.opencode/skills/development/skill.md)
5. [Review Skill](./.opencode/skills/review/skill.md)
6. [提示词库](./templates/prompt_library.md)

## 目录说明

### `docs/`

保存项目事实与设计信息，不保存 AI 规则。

- `SAD/`：软件架构设计
- `SDD/`：模块设计文档
- `ICD/`：接口控制文档
- `TEST/`：测试设计文档

### `.opencode/memory/`

保存项目规则、风格、设计约束和 Review/Test 约束。

### `.opencode/skills/`

保存可复用的工作流能力。

- `development/`：理解需求、分析依赖、生成实现方案、生成代码、生成测试建议
- `review/`：设计 Review、代码 Review、接口 Review、状态机 Review

### `templates/`

保存可直接复用的模板和提示词库。

## 标准使用流程

```text
需求 / 设计文档
-> AI 解析
-> 影响范围分析
-> 实现方案
-> 小步编码
-> Review
-> 测试建议
-> 回归验证
```

## 团队落地原则

- 以文档为输入，以代码为事实，以规则为约束。
- 每次只做一个明确任务，避免大范围改动。
- 所有 AI 输出都必须经过人工确认和工程验证。
- 设计、规则、代码三者必须分离维护。

## 典型提示词入口

- 需求理解：`templates/prompt_library.md`
- 设计方案：`templates/prompt_library.md`
- 代码生成：`templates/prompt_library.md`
- Review：`templates/prompt_library.md`
- 测试设计：`templates/prompt_library.md`

## 建议后续工作

1. 选一个真实 SSD 固件模块，按模板补齐 `SDD`
2. 用 `development skill` 跑一次"文档 -> 方案 -> 代码"闭环
3. 用 `review skill` 跑一次 diff 审查

## CodeGraph 快速入门

### 工具组成

| 工具 | 用途 | 安装 |
|------|------|------|
| **ops-codegraph** | 主工具：调用图/依赖图/影响分析，30+ MCP 工具 | `npm install -g @optave/codegraph` |
| **ctags + cscope** | 补充工具：函数指针/宏查询（tree-sitter 盲区） | `apt install universal-ctags cscope` |
| **Doxygen** | 可视化：交互式 HTML 文档+图（按需） | `apt install doxygen graphviz` |

### 一键安装

```bash
bash scripts/install_codegraph.sh
```

### 项目初始化

```bash
cd /path/to/ssd_firmware
bash scripts/init_codegraph.sh
```

### 常用查询

```bash
# ops-codegraph
codegraph find nand_read_page       # 搜索符号
codegraph callers nand_read_page    # 谁调用了
codegraph callees nand_read_page    # 调用了谁
codegraph impact source/driver/nand/nand_io.c  # 影响分析

# cscope（补充函数指针和宏）
cscope -d -L2 "func_ptr_name"      # 函数指针调用者
cscope -d -L4 "MACRO_NAME"         # 宏使用位置
```

详细教程见 [CodeGraph部署与使用教程.md](./CodeGraph部署与使用教程.md)

