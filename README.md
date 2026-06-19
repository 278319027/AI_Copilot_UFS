# SSD 固件 AI 辅助编程

面向 SSD 固件团队的 AI 辅助编程体系，基于四工具架构：**Graphify**（知识图谱）+ **CodeGraph**（调用图）+ **OpenSpec CLI**（规格驱动）+ **Superpowers**（工程纪律），由 `OpenCode Agent` 统一编排 **KNOW → PLAN → BUILD → FEEDBACK** 闭环。

> ⚠️ 第一次来？先看 [项目导航](docs/navigation.md)（完整文件地图 + 配置索引 + 按角色找入口）

## 快速上手（5 分钟）

```bash
bash deploy_tools.sh /path/to/c-source

# 2. 验证环境
bash verify.sh    # 确认 12/12 通过

# 3. 选一条路径开始（在 OpenCode IDE 中）
#    路径 A（有设计文档）→ /opsx:propose <change-name>
#    路径 B（无设计文档）→ codegraph explore <区域>  先生成设计文档
```

> **工具安装 vs 项目分发**：`deploy_tools.sh` 安装的是有可执行文件的外部工具（Node.js、codegraph、cscope、doxygen、graphify、openspec CLI）。Superpowers / openspec-workflow / sd-firmware-copilot 是项目级 Skill（`.opencode/skills/` 下的 Markdown 文件），随仓库分发，`git clone` 即可用，无需脚本安装。

## 两种使用路径

### 路径 A：设计文档驱动

已有设计文档（SAD/SDD/ICD），AI 直接理解设计并实现。

```
KNOW:     graphify query "<关键词>" && codegraph explore <区域>
PLAN:     /opsx:propose my-change "根据 SDD 第 X 章实现 Y 功能"
BUILD:    /opsx:apply my-change
FEEDBACK: /opsx:archive my-change && graphify update .
```

### 路径 B：代码驱动

无设计文档，AI 先分析代码自动生成设计文档，再按路径 A 执行。

```
KNOW:     codegraph explore <区域> && codegraph callers <核心函数>
          graphify explain "<概念>"
          → AI 自动生成设计文档
PLAN → BUILD → FEEDBACK: 同路径 A
```

## 四工具架构

| 阶段 | 工具 | 部署方式 |
|------|------|---------|
| **KNOW** | Graphify + CodeGraph | `bash deploy_tools.sh` |
| **PLAN** | OpenSpec CLI v1.4.1 | `npm install -g @fission-ai/openspec` |
| **BUILD** | Superpowers + sd-firmware-copilot | `.opencode/skills/superpowers/` |
| **FEEDBACK** | OpenSpec CLI + Graphify | 同 PLAN |

## 配置（opencode.json）

`opencode.json` 声明 MCP 服务器、插件和加载的 Skill。其中 `codegraph` MCP 的 `--path` 形参使用 `opencode.json` 不支持注释（JSON 标准不支持），但可用 shell 变量表达式指定目标 SSD 固件源码根：

```json
"command": ["codegraph", "serve", "--mcp", "--path", "${FEMU_ROOT:-/home/tcb/AI_Proj/femu}/hw/femu"]
```

| 环境变量 | 作用 | 默认值 | 必需 |
|---------|------|-------|------|
| `FEMU_ROOT` | CodeGraph MCP 服务的目标 SSD 固件源码根（指向含 `hw/femu/` 的仓库根） | `/home/tcb/AI_Proj/femu` | 否（未设则用默认） |

调整默认路径的方式：
- **临时覆盖**：`FEMU_ROOT=/path/to/your/ssd_repo opencode`（当前 shell 启动 Agent 时生效）
- **永久设置**：`echo 'export FEMU_ROOT=/path/to/your/ssd_repo' >> ~/.bashrc`

## 推荐阅读

| 序号 | 文档 | 内容 |
|------|------|------|
| 1 | [项目导航](docs/navigation.md) | 完整结构地图 + 按角色找文件 + 配置索引 + **zsf 与目标代码库关系** |
| 2 | [方法论](SSD_Firmware_AI_Copilot_Methodology.md) | 双路径、四阶段闭环、四条铁律 |
| 3 | [路线图](docs/roadmap.md) | 实施进度与规划 |
| 4 | [维护者指南](docs/maintainer.md) | 日常操作、FAQ、变更记录 |

## 核心原则

- **代码优先**：Source Code > Design Docs > Specs > Memory > Prompt
- **小任务原则**：每次 200-500 行，不扩大需求
- **修改前必查 CodeGraph**：确认影响范围
- **四级门禁**：Proposal Gate → Design Gate → Review Gate → Archive
- **四条铁律**：不验证不宣称完成 / 无验证不写实现 / 无根因不修 bug / 未审查不合并
- **AI 辅助不替代人**：人负责架构决策和风险判断
