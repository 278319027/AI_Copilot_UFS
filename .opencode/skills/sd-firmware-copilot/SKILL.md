# SSD Firmware AI Copilot

SSD 固件开发的 AI 辅助技能包。提供 CodeGraph 优先的代码定位、影响分析、并发安全规则、OpenSpec 规格驱动 7 步标准开发流程。

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

每一步的详细规则见 `references/methodology.md`。
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
5. **归档合并**：Review Gate 通过后将 specs/ 增量合并到 `specs/baseline/`，commit 格式 `chore(spec): merge {change-id} into baseline`

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

## 引用技能

本技能包专注 SSD 固件领域规则和知识。通用开发/审查流程由已有技能覆盖：

- **开发流程**：`.opencode/skills/development/skill.md` — 代码生成步骤、CodeGraph 查询集成、OpenSpec 工件产出
- **审查流程**：`.opencode/skills/review/skill.md` — Review 检查项、查证式验证、specs/ 增量核对

> 不要重复已有技能的内容，本技能包只提供 SSD 固件特定规则和知识。

## 参考文档

| 文档 | 路径 | 内容 |
|------|------|------|
| 方法论精要 | `references/methodology.md` | 核心原则、7步流程、分歧矩阵 |
| 提示词库 | `references/prompt_library.md` | 需求/设计/编码/Review/测试提示词模板 |
| 部署指南 | `references/deploy-guide.md` | CodeGraph + cscope + Graphify 部署步骤 |
| 规格工作流 | `references/spec_workflow.md` | proposal.md + specs/ + design.md + tasks.md + review.md + 归档模板与规范 |

## 规则文件

| 规则 | 路径 | 核心内容 |
|------|------|----------|
| 分层架构 | `rules/architecture.md` | 层级规则 + CodeGraph 查询规则 + Agent 配置 |
| 并发安全 | `rules/concurrency_rules.md` | volatile/ISR/锁/DMA/原子/多核 |
| 编码风格 | `rules/coding_style.md` | C 语言规范、命名、注释 |
| 设计规则 | `rules/design_rules.md` | 状态机/Context/资源管理/三级门禁体系 |
| 规格规则 | `rules/spec_rules.md` | 基线管理/增量格式/三级门禁/归档合并 |
| 规则审查 | `rules/review_rules.md` | Review 检查项 + SSD 专项 |
| 测试规则 | `rules/testing_rules.md` | 测试框架 + 测试场景清单（强制） |

## 知识模板

知识模板包含 SSD 固件核心领域的结构化知识框架，**芯片特定值需要填写**：

| 领域 | 路径 | 内容 |
|------|------|------|
| NAND 控制器 | `knowledge-templates/nand_controller/` | 寄存器、操作序列、时序约束、ECC |
| NVMe 规约 | `knowledge-templates/nvme_spec/` | Admin/I/O 命令、错误处理 |
| 平台 | `knowledge-templates/platform/` | 内存映射、电源状态 |

## 规格基线

规格基线为系统当前行为的权威描述。**初始为空，随变更积累**：

| 基线 | 路径 | 描述 |
|------|------|------|
| 基线索引 | `specs/baseline/README.md` | 基线文件列表与填充状态 |
| NVMe 命令 | `specs/baseline/nvme-commands.md` | 命令处理流程、SQ/CQ、PRP/SGL |
| FTL 映射 | `specs/baseline/ftl-mapping.md` | LBA→PBA、磨损均衡、GC、SLC Cache |
| NAND 驱动 | `specs/baseline/nand-driver.md` | Page/Block 操作、ECC、坏块管理 |
| 错误处理 | `specs/baseline/error-handling.md` | 错误传播、恢复策略、断电恢复 |

## 初始化

在新项目中首次使用本技能包时，运行：

```bash
bash .opencode/skills/sd-firmware-copilot/init.sh
```

init.sh 会：
1. 复制规则文件到 `.opencode/memory/`
2. 复制知识模板到 `.opencode/knowledge/`（保留已有项目特定值）
3. 配置 CodeGraph MCP（提示输入项目路径）
4. 提示安装 CodeGraph 工具链
5. 初始化 `.openspec/` 目录结构（specs/baseline/ + proposals/）
