# 维护者指南

> 本文档面向**接手本项目的维护者**。读完应知道：项目做什么、怎么搭环境、日常怎么操作、出问题怎么排查。

## 项目概述

本项目不是 SSD 固件本身，而是 **AI 辅助 SSD 固件开发的方法论与工具链**（代号 "zsf"）。

核心是一个**四阶段闭环**：
- **KNOW** —— 理解代码与设计（Graphify + CodeGraph）
- **PLAN** —— 规划变更（OpenSpec CLI，产出 proposal / design / tasks）
- **BUILD** —— TDD 编码与调试（Superpowers 工程纪律）
- **FEEDBACK** —— 审查与归档（OpenSpec archive + Graphify update）

每个变更必须走完一圈，不允许跳过 KNOW 或 FEEDBACK。

## OpenSpec 5 阶段生命周期

```
┌────────────────────────────────────────────────────────────────────┐
│                OpenSpec 增量变更生命周期（5 阶段）                  │
├────────────────────────────────────────────────────────────────────┤
│                                                                    │
│  ① propose        ② explore        ③ apply        ④ sync  ⑤ archive│
│  ─────────        ─────────        ─────────      ─────  ──────── │
│  创建变更          探索思考          实施任务       同步基线  归档变更│
│  生成 artifacts    （可选）         按 tasks.md   delta→main  移到│
│  proposal/design/  不写代码        TDD 推进      specs/      archive/│
│  specs/tasks                                                     │
│                                                                    │
│  关键命令：                                                        │
│  /opsx:propose    /opsx:explore    /opsx:apply   /opsx:sync /opsx:archive│
│  openspec new     （CLI 无命令）   openspec      openspec  openspec  │
│   change                            instructions  status    status    │
│                                    apply                      (then mv)│
│                                                                    │
│  状态：changes/{id}/    同左      tasks.md       specs/    archive/  │
│        新建空骨架      思考中      [x] 勾选        delta     YYYY-    │
│                                          完成      已合并    MM-DD-  │
│                                                                {id}/  │
└────────────────────────────────────────────────────────────────────┘
```

**何时跳过某阶段**：`explore` 可选（propose 前/后/中自由使用）；`sync` 可在 apply 后 archive 前执行；单文件 bugfix 可跳过 propose 直接 apply。

## 快速上手

```bash
# 1. 一键安装工具链（Node.js 22、codegraph、cscope、doxygen、graphify、openspec）
bash deploy_tools.sh /path/to/your/c/source

# 2. 一键健康检查
bash verify.sh

# 3. 确认 12/12 通过
#   [1/12] OpenSpec specs validation
#   [2/12] CodeGraph MCP config
#   [3/12] Graphify plugin
#   [4/12] Memory rules (6 files present)
#   [5/12] deploy_tools.sh syntax
#   [6/12] Essential tools on PATH
#   [7/12] Memory rules format (6 files)
#   [8/12] openspec/config.yaml
```

## 日常操作

### 添加新规格（OpenSpec）

```bash
# 创建变更
/opsx:propose my-change "实现 Trim 命令超时处理"

# AI 会自动生成 openspec/changes/my-change/ 下的 proposal.md + design.md + tasks.md
# 开发完成后归档
/opsx:archive my-change
```

规格基线在 `openspec/specs/`（5 个领域），活跃变更在 `openspec/changes/{id}/`。归档后变更会合并到 `specs/`。

### 添加新 Skill

Skill 是 `.opencode/skills/` 下的目录，标准结构：

```
.opencode/skills/your-skill/
├── SKILL.md          # 入口：description + 触发条件 + 工作流
└── rules/            # 领域规则（可选）
```

添加后无需安装，OpenCode Agent 会自动识别 `SKILL.md` 中的 `name` 和 `description`。

### 更新知识图谱

```bash
# 代码变更后更新图谱（AST-only，无 API 成本）
graphify update .
```

**⚠️ 大项目（15K+ 文件）限定子目录**：`graphify update .` 遍历所有文件，即使 `make clean` 清理 `.o`/`.d` 后仍有大量无关文件（FEMU: 清理后仍有 118K）。子目录限定为首选。中等项目（5K~15K）可先 `make clean && graphify update .`。

```bash
# 正确做法：子目录分构建 + 合并
graphify update hw/femu/      # 仅 FEMU SSD 代码（< 100 文件，秒级）
graphify update hw/nvme/      # 仅 NVMe 层（< 50 文件，秒级）
graphify merge-graphs hw/femu/graphify-out/graph.json \
                      hw/nvme/graphify-out/graph.json \
                      --out graph.json
```

*回退：项目根图谱为空时，代码内联分析仍可用。`graphify query` 会优雅降级。*

### 健康检查

```bash
bash verify.sh    # 只读检查，不修改任何文件
```

## 目录结构速查

| 路径 | 一句话说明 |
|------|-----------|
| `deploy_tools.sh` | 一键部署六件套工具链 |
| `verify.sh` | 一键健康检查（12 项） |
| `openspec/` | 规格层：基线 `specs/` + 活跃变更 `changes/` |
| `.opencode/skills/superpowers/` | 工程纪律层（13 子技能），入口见 `SKILL.md` |
| `.opencode/skills/openspec-workflow/` | OpenSpec 概念层（Iron Rules + 5 phase 路由），5 phase skill 见 `openspec-{phase}/` |
| `.opencode/commands/opsx-*.md` | 5 个原生 slash 命令（propose/explore/apply/sync/archive） |
| `.opencode/skills/sd-firmware-copilot/` | SSD 领域规则 + 规格管理 |
| `.opencode/memory/` | 6 个编码规则文件（架构/并发/编码/设计/审查/测试） |
| `docs/` | 人类文档：navigation.md、roadmap.md、本文档 |
| `AGENTS.md` | AI 运行时指令（graphify / openspec / superpowers 规则） |

## 常见问题

### verify.sh 某项失败怎么办？

- **OpenSpec 失败** → 检查 `openspec validate --strict --specs` 输出，修复 YAML 语法或缺失字段
- **CodeGraph MCP 失败** → 确认 `opencode.json` 包含 `"codegraph"` MCP 条目
- **Graphify plugin 失败** → 确认 `.opencode/plugins/graphify.js` 存在且可读
- **Memory rules 失败** → 检查 `.opencode/memory/` 下 6 个 `.md` 是否齐全
- **Tools on PATH 失败** → 运行 `bash deploy_tools.sh` 重新安装缺失工具

### deploy_tools.sh 安装失败怎么办？

- 确认有 `sudo` 权限（需 `apt-get`）
- 确认网络可达 `npm` 和 `crates.io`
- Node.js 部分失败可手动：`nvm install 22 && npm install -g @optave/codegraph @fission-ai/openspec`
- graphify 依赖 `uv`，脚本会自动安装；如失败可手动：`curl -LsSf https://astral.sh/uv/install.sh | sh && uv tool install 'graphify[all]'`

### OpenSpec validate 失败怎么办？

```bash
# 查看详细错误
OPENSPEC_TELEMETRY=0 openspec validate --strict --specs

# 常见原因：
# 1. changes/{id}/proposal.md 缺少必填字段（intent / scope / affected-specs）
# 2. specs/ 下的 YAML 缩进错误
# 3. config.yaml 缺失或格式错误
```

### 如何添加新的 memory/ 规则？

在 `.opencode/memory/` 新建 `.md` 文件即可，Agent 会自动加载。建议遵循现有 6 文件的分类（architecture / design / coding / concurrency / review / testing），如需新增类别，同步更新 `verify.sh` 的检查列表。

## 变更记录

| 时间 | 变更 | 影响 |
|------|------|------|
| Phase 6 | 5 个 OpenSpec 适配 Skill 合并为 1 个 `openspec-workflow`（五合一） | 减少技能碎片，统一入口 `/opsx:*` |
| Phase 6 | `openspec/` 目录初始化：新增 `changes/` + `specs/` + `config.yaml` | 规格与代码分离，支持增量变更 |
| Phase 7 | 引入 Superpowers（13 子技能）作为工程纪律层 | 强制 TDD / 根因调试 / 验证完成 |
| Phase 7 | 升级为四工具架构（Graphify + CodeGraph + OpenSpec + Superpowers） | 文档与 AGENTS.md 同步更新 |
| 近期 | `spec_workflow.md` 合并入 `openspec-workflow/SKILL.md` | 消除重复，维护单一真相源 |
| 近期 | `openspec-workflow` 拆分为 1 概念层 + 5 phase skill + 5 原生 slash 命令 | 触发精准、token 按需加载、对齐 `agentskills.io` progressive disclosure |

---

> 更详细的架构说明见 [README.md](../README.md)，实施进度见 [roadmap.md](roadmap.md)，AI 运行时指令见 [AGENTS.md](../AGENTS.md)。
