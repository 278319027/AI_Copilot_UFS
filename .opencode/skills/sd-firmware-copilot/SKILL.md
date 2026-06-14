# SSD Firmware AI Copilot

SSD 固件开发的 AI 辅助技能包。提供 CodeGraph 优先的代码定位、影响分析、并发安全规则、7 步标准开发流程。

## 触发词

`SSD`, `FTL`, `NVMe`, `NAND`, `固件`, `WAF`, `GC`, `磨损均衡`, `坏块管理`, `FTL map`, `NAND controller`

## 适用场景

- SSD 固件代码开发（FTL、NAND 驱动、NVMe 命令处理）
- 固件代码审查（并发安全、资源管理、错误路径）
- 固件设计方案分析（状态机、DMA、中断处理）
- 固件测试场景生成（故障注入、边界条件、时序约束）

## 核心 7 步流程

```
需求/设计文档 → AI 理解 → CodeGraph 查询 → 设计方案 → 小步编码 → Review → 测试建议
```

每一步的详细规则见 `references/methodology.md`。

### 必须遵守

1. **CodeGraph 先查再改**：修改任何代码前，必须先用 CodeGraph 查询影响范围
2. **小任务原则**：每次 200~500 行，不扩大需求
3. **设计方案确认门禁**：AI 输出设计方案后，必须包含「待人工确认清单」（架构假设、CodeGraph 影响完整性、更简方案），人工确认后才开始编码

### CodeGraph 查询（必须使用）

- `codegraph callers <symbol>` — 谁调用了
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

- **开发流程**：`.opencode/skills/development/skill.md` — 代码生成步骤、CodeGraph 查询集成
- **审查流程**：`.opencode/skills/review/skill.md` — Review 检查项、CodeGraph 验证

> 不要重复已有技能的内容，本技能包只提供 SSD 固件特定规则和知识。

## 参考文档

| 文档 | 路径 | 内容 |
|------|------|------|
| 方法论精要 | `references/methodology.md` | 核心原则、7步流程、分歧矩阵 |
| 提示词库 | `references/prompt_library.md` | 需求/设计/编码/Review/测试提示词模板 |
| 部署指南 | `references/deploy-guide.md` | CodeGraph + cscope + Graphify 部署步骤 |

## 规则文件

| 规则 | 路径 | 核心内容 |
|------|------|----------|
| 分层架构 | `rules/architecture.md` | 层级规则 + CodeGraph 查询规则 + Agent 配置 |
| 并发安全 | `rules/concurrency_rules.md` | volatile/ISR/锁/DMA/原子/多核 |
| 编码风格 | `rules/coding_style.md` | C 语言规范、命名、注释 |
| 设计规则 | `rules/design_rules.md` | 状态机/Context/资源管理/设计方案确认门禁 |
| 规则审查 | `rules/review_rules.md` | Review 检查项 + SSD 专项 |
| 测试规则 | `rules/testing_rules.md` | 测试框架 + 测试场景清单（强制） |

## 知识模板

知识模板包含 SSD 固件核心领域的结构化知识框架，**芯片特定值需要填写**：

| 领域 | 路径 | 内容 |
|------|------|------|
| NAND 控制器 | `knowledge-templates/nand_controller/` | 寄存器、操作序列、时序约束、ECC |
| NVMe 规约 | `knowledge-templates/nvme_spec/` | Admin/I/O 命令、错误处理 |
| 平台 | `knowledge-templates/platform/` | 内存映射、电源状态 |

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