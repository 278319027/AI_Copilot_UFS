# SSD Firmware AI Copilot

SSD 固件开发的 AI 辅助技能包。提供 CodeGraph 优先的代码定位、影响分析、并发安全规则、OpenSpec 规格驱动 7 步标准开发流程。

## 架构：两层叠加（Superpowers × sd-firmware-copilot）

本技能包是 **上层（领域规则层）**。通用工程纪律由 [Superpowers](../superpowers/SKILL.md) 作为 **下层（执行引擎层）** 提供。两者叠加，缺一不可：

```text
┌──────────────────────────────────────────────────────────────────┐
│ 上层 — sd-firmware-copilot（本技能）                              │
│   决定 SSD 领域 "What"：CodeGraph 影响分析、OpenSpec 工件、       │
│   specs/ 增量、SSD 规则、openspec/specs/                          │
├──────────────────────────────────────────────────────────────────┤
│ 下层 — Superpowers（.opencode/skills/superpowers/）               │
│   决定通用工程 "How"：TDD、systematic-debugging、                  │
│   verification-before-completion、subagent-driven-development、   │
│   requesting-code-review、finishing-a-development-branch          │
└──────────────────────────────────────────────────────────────────┘
```

**下层铁律（由 Superpowers 强制，不可绕过）：**

- `NO COMPLETION CLAIMS WITHOUT FRESH VERIFICATION EVIDENCE`（见 `superpowers/verification-before-completion/`）
- `NO PRODUCTION CODE WITHOUT A FAILING TEST FIRST`（见 `superpowers/test-driven-development/`）
- `NO FIXES WITHOUT ROOT CAUSE INVESTIGATION FIRST`（见 `superpowers/systematic-debugging/`）

这些铁律适用于所有本技能包触发的开发/审查工作流。子代理必须先看 `superpowers/using-superpowers/SKILL.md` 的 bootstrap，再决定加载哪些子技能。


## 触发词

`SSD`, `FTL`, `NVMe`, `NAND`, `固件`, `WAF`, `GC`, `磨损均衡`, `坏块管理`, `FTL map`, `NAND controller`, `spec`, `baseline`, `proposal`, `design.md`, `tasks.md`, `review.md`, `specs`, `归档`, `增量`

## 适用场景

- SSD 固件代码开发（FTL、NAND 驱动、NVMe 命令处理）
- 固件代码审查（并发安全、资源管理、错误路径）
- 固件设计方案分析（状态机、DMA、中断处理）
- 固件测试场景生成（故障注入、边界条件、时序约束）
- 固件行为追溯（规格基线、增量变更、审计历史）

## 核心流程（OpenSpec 完整版）

```
需求 → proposal.md → specs/增量 → Design Gate → CodeGraph查询 → design.md → tasks.md
                                       ↓                                              ↓
                                  Proposal Gate                               Review Gate → review.md
                                                                                    ↓
                                                                              归档合并 → baseline
```

每一步的详细规则见 `../../SSD_Firmware_AI_Copilot_Methodology.md`。
规格层规则见 `rules/spec_rules.md`。

### 必须遵守

1. **CodeGraph 先查再改**：修改任何代码前，必须先用 CodeGraph 查询影响范围
2. **小任务原则**：每次 200~500 行，不扩大需求。任务清单写入 `tasks.md`
3. **方案确认门禁（三级）**：
   - Gate 1: Proposal Gate → 确认意图、范围、基线冲突（proposal.md）
   - Gate 2: Design Gate → 确认 design.md（CodeGraph 完整 + 待确认清单）后编码
   - Gate 3: Review Gate → 查证式 Review + specs/ 一致性验证后归档
   - 详情见 `rules/spec_rules.md` §5
4. **提案/审查/增量工件**：需求产出 proposal.md + specs/ 增量，审查产出 review.md（含查证 + 增量核对）
5. **归档合并**：Review Gate 通过后由 `/opsx:archive` 将 specs/ 增量合并到 `openspec/specs/`，commit 格式 `chore(spec): archive {change-id}`

### CodeGraph 查询（必须使用）

- `codegraph callees <symbol>` — 调用了谁
- `codegraph impact <symbol>` — 影响分析
- `codegraph explore <query>` — 区域探索
- `codegraph query <keyword>` — 符号搜索
- `codegraph status` — 索引统计

> 当前 CodeGraph 部署于 FEMU 项目 `../femu/hw/femu/`

### cscope 补充（函数指针/宏场景）

```bash
cscope -d -L2 "func_ptr"   # 函数指针调用者
cscope -d -L3 "func_ptr"   # 函数指针指向
cscope -d -L4 "MACRO"      # 宏使用位置
cscope -d -L8 "header.h"   # 头文件包含
```

## 引用技能（两层架构）

本技能包专注 SSD 固件领域规则和知识，**复用**而非**重复**下层 Superpowers 与项目适配器：

**下层 — Superpowers 通用纪律**（`.opencode/skills/superpowers/`）：

| 子技能 | 何时调用 | 铁律 |
|--------|----------|------|
| `using-superpowers/` | 每段对话开始 | Skill-aware behaviour |
| `systematic-debugging/` | 任何 bug / 测试失败 | 根因先于修复 |
| `test-driven-development/` | 新功能 / 修复 / 重构 | 先失败测试后生产代码 |
| `verification-before-completion/` | 任何"完成"声明前 | 证据先于断言 |
| `subagent-driven-development/` | 计划中任务互相独立 | 新子代理 + 任务级 Review |
| `executing-plans/` | 顺序执行计划 | 计划 → 执行 → 验证 |
| `dispatching-parallel-agents/` | 2+ 独立调查并行 | 单一领域 / 代理 |
| `requesting-code-review/` | 合并前 / 每任务后 | 审查先于合并 |
| `receiving-code-review/` | 收到审查反馈 | 验证先于实现 |
| `finishing-a-development-branch/` | 全部任务完成 | 验证 → 选项 → 收尾 |

**项目适配器（薄壳，委托到 Superpowers + 加 SSD 域前后置）：**

- **开发流程**：`.opencode/skills/development/skill.md` — CodeGraph/OpenSpec 前后置 + 委托 `executing-plans` / `subagent-driven-development` + TDD + verification-before-completion
- **审查流程**：`.opencode/skills/review/skill.md` — SSD 专项检查 + 委托 `requesting-code-review` / `receiving-code-review` + specs/ 增量核对

> 不要重复已有技能的内容，本技能包只提供 SSD 固件特定规则和知识。

## 参考文档

| 文档 | 路径 | 内容 |
|------|------|------|
| 方法论精要 | `../../SSD_Firmware_AI_Copilot_Methodology.md` | 核心原则、7步流程、分歧矩阵 |
| 规格工作流 | `references/spec_workflow.md` | proposal.md + specs/ + design.md + tasks.md + review.md + 归档模板与规范 |

## 规则文件

| 规则 | 路径 | 核心内容 |
|------|------|----------|
| 分层架构 | `.opencode/memory/architecture.md` | 层级规则 + CodeGraph 查询规则 + Agent 配置 |
| 并发安全 | `.opencode/memory/concurrency_rules.md` | volatile/ISR/锁/DMA/原子/多核 |
| 编码风格 | `.opencode/memory/coding_style.md` | C 语言规范、命名、注释 |
| 设计规则 | `.opencode/memory/design_rules.md` | 状态机/Context/资源管理/三级门禁体系 |
| 规格规则 | `rules/spec_rules.md` | 基线管理/增量格式/三级门禁/归档合并 |
| 规则审查 | `.opencode/memory/review_rules.md` | Review 检查项 + SSD 专项 |
| 测试规则 | `.opencode/memory/testing_rules.md` | 测试框架 + 测试场景清单（强制） |

## 硬件知识

本技能包**不**捆绑硬件知识模板。寄存器/时序/中断等芯片特定信息因芯片型号而异，应在项目初始化时由硬件团队提供。

建议做法：
- 由项目所有者将芯片手册、寄存器表、时序约束等结构化放入 `.opencode/knowledge/`（按 `nand_controller/`、`nvme_spec/`、`platform/` 等子目录组织）。
- 本技能包按需注入相关子目录（如处理 NAND 驱动时注入 `nand_controller/`），而非全量加载。
- 每个知识文件需标注适用芯片型号与固件版本，修改时同步更新版本号。

## 规格基线

规格基线为系统当前行为的权威描述。**初始为空，随变更积累**：

| 基线 | 路径 | 描述 |
|------|------|------|
| 基线索引 | `openspec/specs/` | 5 个 capability 的 spec.md 总入口（`ssd-firmware-overview` / `nvme-commands` / `ftl-mapping` / `nand-driver` / `error-handling`） |
| NVMe 命令 | `openspec/specs/nvme-commands/spec.md` | 命令处理流程、SQ/CQ、PRP/SGL |
| FTL 映射 | `openspec/specs/ftl-mapping/spec.md` | LBA→PBA、磨损均衡、GC、SLC Cache |
| NAND 驱动 | `openspec/specs/nand-driver/spec.md` | Page/Block 操作、ECC、坏块管理 |
| 错误处理 | `openspec/specs/error-handling/spec.md` | 错误传播、恢复策略、断电恢复 |

## 初始化

在新项目中首次使用本技能包时，运行：

```bash
bash .opencode/skills/sd-firmware-copilot/init.sh
```

init.sh 会：
1. 确认 `.opencode/memory/` 规则文件就位（6 个规则文件）
2. 配置 CodeGraph MCP（提示输入项目路径）
3. 提示安装 CodeGraph 工具链
4. 初始化 `openspec/` 目录结构（`openspec/specs/` + `openspec/changes/`）

> 硬件知识（寄存器/时序/平台）**不**由本技能包提供，芯片特定值需项目初始化时由硬件团队填入 `.opencode/knowledge/`。
