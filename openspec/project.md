# OpenSpec Project Conventions — zsf

> **What this file is**：项目级 OpenSpec 约定补充。与 `openspec/config.yaml` 互补：
> - `config.yaml` —— 结构化配置（schema, context, rules）
> - `project.md`（本文件）—— 自由形式的约定、背景、决策记录
>
> AI 写 OpenSpec artifacts 时**两者都该读**。

---

## 1. Project Identity

**zsf** 是面向 **SSD 固件团队**的 AI 辅助编程体系仓库，**不是 SSD 固件代码本身**。

- 目标代码库：通过 `FEMU_ROOT` 环境变量或 `opencode.json → project.femuRoot` 字段指定的 SSD 固件源码（默认 `/home/zsf/AI_Proj/femu/hw/femu`）
- zsf 仓库**只**承载方法论资产：skills / commands / memory / docs / OpenSpec 规格层 / 部署与验证脚本
- 代码修改**绝不**发生在 zsf 仓库内（除方法论资产本身）

**架构原则**：方法论层（zsf）与目标代码库（FEMU 等）**解耦**。换目标 SSD 固件代码库时**不需重新部署方法论层**。

---

## 2. Scope Rules

### 2.1 zsf 仓库**允许**的修改

- `.opencode/{commands,skills,memory,agents}/` —— 方法论资产
- `openspec/{specs,changes}/` —— OpenSpec 规格层（仅 zsf 自己的 OpenSpec）
- `docs/` —— 方法论文档 + ADR
- 根 `AGENTS.md` / `README.md` / `opencode.json` / `verify.sh` / `deploy_tools.sh` / `check_change.sh`
- `openspec/AGENTS.md` / `openspec/project.md`（本文件）—— OpenSpec 使用指南

### 2.2 zsf 仓库**禁止**的修改

- 任何 `*.c` / `*.h` / `*.cpp` / `*.py` SSD 固件源码
- `Makefile` / `CMakeLists.txt` 等构建文件（除非为方法论自身服务）
- 任何目标代码库的子目录（即使发现误生成的副本 → 立即删除）

### 2.3 OpenSpec 在 zsf 仓库的角色

zsf 仓库的 `openspec/` 不是描述 SSD 固件代码本身的规格（那应该在目标代码库），而是**方法论元规格**：

- `openspec/specs/` —— 当前可声明的**能力**（nvme-commands / ftl-mapping / nand-driver 是 **方法论承诺覆盖的 SSD 固件领域**，不是 zsf 仓库自身的能力）
- `openspec/changes/` —— 方法论层的变更历史（如 `add-femu-gc-stats-log-page` 是 zsf 为 SSD 固件日志能力增加 spec，不是 zsf 仓库自身代码变更）

> ⚠️ 当前 `openspec/specs/{nvme-commands,ftl-mapping,nand-driver}/spec.md` 写的是 SSD 固件行为而非 zsf 方法论——这是历史遗留的**概念借用**，方便 zsf 自身走 OpenSpec 流程测试。所有 spec 实际上是描述**目标代码库**（FEMU）的行为，而非 zsf 仓库本身。

---

## 3. Conventions

### 3.1 Change ID 命名

- kebab-case（小写 + 连字符）
- 动词开头：`add-` / `update-` / `remove-` / `refactor-` / `fix-`
- **场景相关**前缀：方法论层变更用 `add-zsf-...` 开头以区分目标代码库变更
- 例：
  - `add-zfs-superpowers-bootstrap-section` —— 在 zsf 仓库根 AGENTS.md 加 Bootstrap 段
  - `add-femu-gc-stats-log-page` —— 给目标代码库（FEMU）增加 GC stats log 规格
  - `refactor-opsx-command-style` —— 改造 zsf 的 opsx 命令格式

### 3.2 任务粒度

- **200-500 行/任务**（参考 `sd-firmware-copilot/SKILL.md §小任务原则`）
- 每个任务必须**可原子完成**（1-3 个工具调用）
- 任务粒度判断标准：能在一个 session 内独立完成 + 可独立测试 + 可独立 review

### 3.3 Spec 语言

- **bilingual**（zh-CN + en）where helpful
- `Requirements` 和 `Scenarios` **必须**使用英文 `SHALL` / `MUST` / `**WHEN**` / `**THEN**` 关键词（OpenSpec 工具链 lint 要求）
- `Purpose` / `Consumers` / 自由格式说明可用中文
- 注释、commit message、PR description 可用中文

### 3.4 五级门禁（5 Gates）

| Gate | 简述 | 强制？ |
|------|------|--------|
| Proposal Gate | 动机 / 范围 / Non-goals 明确 | 必（除单文件 bugfix） |
| Design Gate | 架构 / 任务分解 | 必（除文档/注释） |
| BUILD Gate | 加载 3 个 Superpowers skill | 必 |
| Review Gate | 人类审查 | 必（AI 不能自批） |
| Archive Gate | 验证 + 归档 | 必 |

**豁免规则**：

- 单文件 bugfix → 豁免 Proposal Gate 访谈，Design Gate 简述
- 文档/注释/配置变更 → 豁免 Proposal + Design，Review 仍需
- 跨模块重构 → 无豁免，完整 5 gate

---

## 4. Required References（AI 必读清单）

### 4.1 启动时（每个 session）

- 仓库根 `AGENTS.md`（含 Skill Bootstrap 表）
- `openspec/AGENTS.md`（OpenSpec 操作流程）
- 本文件 `openspec/project.md`（项目约定）

### 4.2 进入 BUILD 前

- `.opencode/skills/sd-firmware-copilot/SKILL.md`（项目流水线 + 五门禁 + Iron Rules）
- `.opencode/skills/openspec-workflow/SKILL.md`（5 phase 概念层）

### 4.3 写代码前

- `.opencode/memory/architecture.md` —— SSD 固件分层规则
- `.opencode/memory/concurrency_rules.md` —— 并发安全
- `.opencode/memory/coding_style.md` —— 命名 / 注释 / 格式
- `.opencode/memory/design_rules.md` —— 错误处理横切规则
- `.opencode/memory/testing_rules.md` —— test-after 规则

### 4.4 实施 OpenSpec 变更前

- `openspec/specs/<cap>/spec.md` —— baseline 行为
- `openspec/changes/<id>/design.md` —— 本变更设计
- `openspec/changes/<id>/tasks.md` —— 任务清单
- `openspec/config.yaml` 的 `rules:` 段 —— 强制规则

### 4.5 审查前

- `.opencode/skills/superpowers-requesting-code-review/ssd-review-rules.md`（按需加载）
- `.opencode/skills/superpowers-receiving-code-review/SKILL.md`

---

## 5. Decision Records

方法论层关键决策见 `../docs/adr/`：

- `0001-methodology-target-repo-separation.md` —— 为什么要把方法论层（zsf）和目标代码库（FEMU）分离
- `0002-four-stage-loop.md` —— 为什么要四阶段闭环（KNOW→PLAN→BUILD→FEEDBACK）
- `0003-tdd-to-test-after.md` —— 为什么从 TDD 改为 test-after
- `0004-five-gates.md` —— 为什么加第五个门禁（BUILD Gate）

AI 接到"为什么这样做"类问题时，**优先读 ADR 再回答**。

---

## 6. Boundary with `openspec/config.yaml`

| 内容 | 位置 |
|------|------|
| schema 类型（`spec-driven` / 自定义） | `config.yaml → schema` |
| artifact 注入 context（tech stack / domain） | `config.yaml → context` |
| 按 artifact 的硬规则 | `config.yaml → rules.{proposal,tasks,design}` |
| 项目身份 / 范围 / 解耦原则 | **本文件 §1-§2** |
| change-id 命名约定 | **本文件 §3.1** |
| 任务粒度 | **本文件 §3.2** |
| Spec 语言 | **本文件 §3.3** |
| 五门禁豁免规则 | **本文件 §3.4** |
| AI 必读清单 | **本文件 §4** |
| 决策依据 | **本文件 §5**（链到 ADR） |

**互不重复，互补加载**。
