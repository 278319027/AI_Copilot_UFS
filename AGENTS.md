本文档是 OpenCode Agent 的运行时指令，描述 graphify/codegraph/openspec/superpowers 四工具的使用规则。

> **AI 完整工作流**（4 阶段闭环、4 Iron Rules、Bootstrap 决策表、Skill map）见 `.opencode/skills/sd-firmware-copilot/SKILL.md` —— 本文档仅含项目特有的 OpenCode 启动配置（环境变量、插件规则、CLI 命令清单）。

## Session Start Checklist（**per M-5 closure, retro 2026-06-add-toggle-gc-delay**）

> **背景**（M-5 gap）：5 个项目级 memory 文件（architecture / design_rules / coding_style / concurrency_rules / testing_rules）原要求"session-start 必读"，但续会（continuation session）未显式重读。**修复**：强制 session-start checklist 文档化，确保每个新 drill session-start 都跑 4 步。

每个 **新 OpenSpec drill session-start** 必跑 4 步（5-10 min overhead）：

1. **5 个 memory 文件重读**（per `superpowers-using-superpowers/SKILL.md §PROJECT-SPECIFIC`）：
   - `.opencode/memory/architecture.md` — 架构分层
   - `.opencode/memory/design_rules.md` — 设计规则（含 §设计-实现一致性）
   - `.opencode/memory/coding_style.md` — 命名 / 注释 / 文件
   - `.opencode/memory/concurrency_rules.md` — 锁 / 中断 / 原子操作
   - `.opencode/memory/testing_rules.md` — 测试要求（含 §4.4 Bug Injection 强制）
2. **verify.sh baseline check**：`bash scripts/verify.sh`（应 19/20 或更新；验证工作树干净 + 4 P0/P1/P2 防御都就位）
3. **openspec-* 5 个 skill 重读**：
   - `openspec-workflow/SKILL.md`（5 phase 概念层）
   - `openspec-propose/SKILL.md`（propose 阶段 + §1a Delta 头规则 + §1b Refactor 类型 per AP-009/AP-010）
   - `openspec-sync-specs/SKILL.md`（sync 阶段 + §6 Delta Header Rule）
   - `openspec-archive-change/SKILL.md`（archive 阶段 + §1.0 ask user + §2.5 manual sync fallback）
   - `sd-firmware-copilot/SKILL.md`（项目级 pipeline + 五门禁 + Iron Rules）
4. **OpenSpec 状态检查**：`cd /home/AI_Copilot_UFS/AI_Proj/AI_Copilot_UFS && openspec list --json`（盘点活跃变更）

> **为什么**：这些规则在 PLAN/DESIGN/BUILD 阶段持续生效；不读会导致 DESIGN 违反 memory 规则（命名 / 风格 / 并发模型）而到 BUILD 阶段才发现。**AP-002 案例**：`add-crt-mapping-cache` 在 PLAN 阶段就违反 coding_style 的"英文命名 + 中文注释"约定，是 session 中段才纠正的。

## codegraph 与 FEMU_ROOT

CodeGraph MCP 服务用于查询目标代码库的调用图/影响分析，其目标路径通过 `opencode.json` 的 `mcp.codegraph.command` 数组配置。

**约定**：`FEMU_ROOT` 环境变量是 FEMU 路径的标准形式，与 `opencode.json` 的 `mcp.codegraph.command --path` 的 `${FEMU_ROOT:-/default}` 语法一致。所有 shell 脚本统一使用 `${FEMU_ROOT:-/home/AI_Copilot_UFS/AI_Proj/femu/hw/femu}` 约定，**与 `opencode.json` 默认值保持同步**（修改任一处需同步另一处）。

| 项 | 值 |
|----|----|
| **环境变量** | `FEMU_ROOT`（env var 优先于默认） |
| **默认路径** | `/home/AI_Copilot_UFS/AI_Proj/femu/hw/femu`（与 `opencode.json` 的 `codegraph.command --path` 默认值相同）|
| **验证命令** | `bash scripts/verify.sh` 中的 `[9/17] FEMU_ROOT` 检查 |

覆盖示例:
- **临时覆盖**：`export FEMU_ROOT=/opt/ssd-firmware/hw/femu`
- **永久修改**：编辑 `opencode.json` 的 `mcp.codegraph.command --path`（同步脚本中的默认值）

## graphify

在目标代码库（非 AI_Copilot_UFS 自身）运行 `graphify update <子目录>` 后，会生成 `graphify-out/` 知识图谱（god nodes、社区结构、跨文件关系）。

当用户输入 `/graphify` 时，直接运行 graphify CLI 命令（graphify query/path/explain/update）。

规则：
- 对代码库问题，如果 graphify-out/graph.json 存在，优先运行 `graphify query "<问题>"`。使用 `graphify path "<A>" "<B>"` 查询关系，`graphify explain "<概念>"` 聚焦概念。
- graphify-out/ 的脏文件是正常的（hooks 或增量更新导致）；不要因为 graph 文件脏而跳过 graphify。
- 运行 graphify update . 后，如果 graphify-out/wiki/index.md 已生成，优先用它做广泛导航，而非直接浏览源码。
- 运行 graphify update . 后，如果 graphify-out/GRAPH_REPORT.md 已生成，则仅在 query/path/explain 不足时才读取它（用于广泛架构审查）。
- 修改代码后，运行 `graphify update .` 保持图谱最新（AST-only，无 API 成本）。
- **大项目**（15K+ 文件）：先在相关子目录运行 `graphify update <subdir>`，再 `graphify merge-graphs` 合并。中等项目（5K~15K）可先 `make clean` 清理构建产物再跑全量。全仓库直跑 `graphify update .` 会因遍历大量无关文件而超时（零进度反馈无法判断死/活）。

## .opencode 归属规则

**AI_Copilot_UFS 是 `.opencode/` 目录的唯一所有者**。`.opencode/{commands,memory,skills}/` 是项目级方法论资产，跟随 AI_Copilot_UFS 仓库版本控制。

OpenCode Agent 在不同工作目录运行时，**应向上查找**到 AI_Copilot_UFS 仓库根目录加载 `.opencode/`，**不应**在以下位置创建 `.opencode/`：

- ❌ `FEMU_ROOT/.opencode/`（SSD 固件代码子目录）— 实际发生过的误生成位置
- ❌ `<femu 仓库根>/.opencode/`（femu 仓库根，非 AI_Copilot_UFS）— 仅当 femu 是独立工作区时才允许
- ❌ 任何目标代码库子目录内的 `.opencode/`

如果发现误生成（`verify.sh [13/17]` 会自动检测），执行 `rm -rf <误生成路径>/.opencode/`，并通过在 AI_Copilot_UFS 仓库根启动 OpenCode Agent 来修复（保证向上查找找到 AI_Copilot_UFS 自己的 `.opencode/`）。

**为什么不允许**：方法论层（AI_Copilot_UFS）与目标代码库（femu）解耦是核心架构原则。在 femu 子目录创建 `.opencode/` 会让 femu 仓库的"运行环境"被方法论层锁死——换 SSD 固件代码库时必须重新部署。同时误生成的副本会与 AI_Copilot_UFS 自己的 `.opencode/` 不同步（出现 skill 名字不一致、规则过时等问题）。

## openspec

本项目使用 **OpenSpec CLI v1.4.1** 做规格驱动开发。活规格基线位于 `openspec/specs/`；活跃变更位于 `openspec/changes/{id}/`。

当用户输入 `/opsx:*` 时，调用 `.opencode/commands/` 下对应 `opsx-{propose,explore,apply,sync,archive}.md`（或直接调用 `openspec` CLI 作为后备）。

规则：
- **Spec 变更是「系统做什么」的权威来源。** 修改影响已文档化行为的代码前，必须先读 `openspec/specs/`。
- **每次变更必须经过五级门禁**：Proposal Gate → Design Gate → BUILD Gate → Review Gate → Archive（BUILD Gate 强制编码前加载验证 skill，详见 sd-firmware-copilot SKILL）。
- **永不删除 `openspec/changes/` 条目** — 它们构成审计追踪。
- **OpenSpec 流程**：`openspec-workflow/` 是概念层（Iron Rules + 跨切约束 + 5 phase 路由），执行具体 phase 请加载对应 `openspec-{propose,explore,apply,sync-specs,archive-change}/`。
- 规格层规则见 `.opencode/skills/sd-firmware-copilot/SKILL.md`（`## Spec 规则` 一节）。

- 可跳过 Proposal Gate 的场景：仅单文件 bugfix。文档/注释变更不需要 OpenSpec 工件。
- 归档提交格式：`chore(spec): archive {change-id}`。

> 详细工作流分 3 节展开：**§OpenSpec Specs**（baseline + delta 格式）、**§OpenSpec Changes**（propose/apply/verify/archive 流程）、**§OpenSpec Tools**（CLI + `/opsx:*` 命令 + 启动 setup）。本节为索引。

## OpenSpec Specs

> Specs 位于 `openspec/specs/<cap>/spec.md`，是「系统做什么」的权威来源。**修改影响已文档化行为的代码前必读 specs。**

### Delta 格式硬约束

- 标题三个 `###`（Requirement）/ 场景四个 `####`（Scenario）——**4 个 # 是硬要求，3 个 # 静默失败**
- 规范词：`SHALL` / `MUST` / **WHEN** / **THEN**；避免 `should` / `may`
- 每个 Requirement 至少 1 个 Scenario；每个 Scenario 是潜在测试用例

### Spec 变更类型（写到 change 的 `specs/<cap>/spec.md`）

- **新建 capability**（之前无相关 spec）→ 写 `## ADDED Requirements`
- **修改现有 capability**（已有 spec）→ 写 `## ADDED` / `MODIFIED` / `REMOVED` / `RENAMED Requirements`
- `MODIFIED` 头文本必须完全一致
- `REMOVED` 必含 `**Reason:**` + `**Migration:**`

### Sync 同步规则（Archive 步骤 2 — `/opsx:sync` 智能合并）

- 读 `openspec/changes/<id>/specs/<cap>/spec.md` 找 `## ADDED|MODIFIED|REMOVED|RENAMED` 段
- 智能合并到 `openspec/specs/<cap>/spec.md`：
  - `ADDED` → 追加
  - `MODIFIED` → 替换同名 Requirement
  - `REMOVED` → 删除
  - `RENAMED` → 用 `FROM:` `TO:` 标记
- **绝不程序化覆盖 baseline**——智能匹配 Requirement 头
- 触发：`/opsx:archive` 自动流程会先调 `/opsx:sync`

### 校验命令

```bash
openspec validate --strict --specs              # baseline 校验
openspec validate --strict --changes            # 活跃变更校验
```

## OpenSpec Changes

> 活跃变更位于 `openspec/changes/<id>/`，归档后移至 `openspec/changes/archive/YYYY-MM-DD-<id>/`。**永不删除 changes/ 条目（审计追踪）**。

### 决策流程（接到需求时）

```
新需求
  │
  ├─ 需求模糊，需要访谈澄清 ──→ /opsx:propose <name> "intent"
  │                                  （触发苏格拉底式访谈 + 生成 4 artifacts）
  │
  ├─ 需求清晰，跳过访谈 ──────→ /opsx:ff <name> "intent"
  │                                  （一次性建空骨架 + 生成 4 artifacts）
  │
  ├─ 我想自己填/分步生成 ─────→ /opsx:new <name>
  │                                  （仅建空骨架）→ /opsx:continue
  │
  ├─ 调研/对比方案（不写代码） → /opsx:explore [topic]
  │                                  （读 specs / CodeGraph / Graphify / 写 design.md 思考段）
  │
  └─ 实施已有 tasks.md ──────→ /opsx:apply [name]
                                     （按 tasks 顺序逐项实施 + 勾选 - [x]）
```

完成前：先 `/opsx:verify` → 再 `/opsx:archive`。
积压多个已完成变更：用 `/opsx:bulk-archive`。

### 创建新变更（propose / new / ff）— 必须遵守

1. **搜索现有 work**（避免重复）：
   ```bash
   openspec list --json                              # 活跃变更
   openspec list --specs                             # baseline capabilities
   rg "lba|pba|nand|nvme" openspec/specs/ openspec/changes/  # 概念层全文
   ```
2. **决定 scope**（见 OpenSpec Specs §Spec 变更类型）
3. **Pick 唯一 `change-id`**：
   - kebab-case（小写 + 连字符）
   - 动词开头：`add-` / `update-` / `remove-` / `refactor-` / `fix-`
   - 与 `openspec/changes/` 和 `openspec/changes/archive/` 不冲突
4. **Scaffold artifacts**：
   - `proposal.md` —— 必填（动机 / 范围 / Non-goals / 影响的能力）
   - `specs/<cap>/spec.md` —— 必填（delta: `## ADDED` / `MODIFIED` / `REMOVED` Requirements）
   - `design.md` —— 跨文件/架构变更必填；单文件 bugfix 可豁免
   - `tasks.md` —— 必填（200-500 行/任务，含 spec 引用 + 测试计划 + 验证命令）
   - `.openspec.yaml` —— 可选（变更元数据）
5. **Delta 格式硬约束**（见 OpenSpec Specs §Delta 格式硬约束）
6. **校验**：
   ```bash
   openspec validate --strict --changes              # 必须在 archive 前通过
   bash scripts/check_change.sh <change-name>        # 项目级额外检查
   ```

### 实施变更（apply）— 5 级门禁

每个变更必须经过 5 级门禁，**门禁不可跳级**（除豁免规则外）：

| 门禁 | 输入工件 | 通过标准 | 校验命令 |
|------|----------|----------|----------|
| **Proposal Gate** | `proposal.md` | 动机 / 范围 / Non-goals / 影响 capability 明确 | `openspec status --change "<name>" --json` |
| **Design Gate** | `design.md` + `tasks.md` | CodeGraph 影响分析 / 模块边界 / 并发 / 错误路径 / 任务粒度 | 同上 |
| **BUILD Gate** | 加载 3 个 Superpowers skill | `superpowers-verification-before-completion` + `superpowers-executing-plans` + `superpowers-test-driven-development` 已 `skill()` 加载 | `skill()` 工具调用记录 |
| **Review Gate** | 编码完成 + `review.md` | 人类审查员签字（AI 不能自批） | `make clean && make && make test` |
| **Archive Gate** | 所有 artifact + `verify-report.md` | `tasks.md` 全勾选 / delta 已合并 / `openspec validate --strict` 通过 | `openspec validate --strict --specs` |

**简化豁免**（参考 `sd-firmware-copilot/SKILL.md §简化豁免规则`）：

- 单文件 bugfix：豁免 Proposal Gate 的人工访谈，但 Design Gate 简述影响范围仍需
- 文档/注释/配置变更：豁免 Proposal Gate + Design Gate
- 跨模块重构：**无豁免**——完整 5 级门禁

### 验证（verify）— Archive 前必做

`/opsx:verify` 跑 6 项自动检查，**不替代** Review Gate：

| # | 检查项 | 命令 | 通过标准 |
|---|--------|------|----------|
| 1 | `tasks.md` 全勾选 | `grep -c '^\- \[x\]' openspec/changes/<id>/tasks.md` | 所有任务已勾 |
| 2 | 编译通过 | `make clean && make -j$(nproc)` | 退出码 0 |
| 3 | 测试通过 | `make test` | 退出码 0 |
| 4 | Spec 一致 | `openspec validate --strict --changes` | 无 violation |
| 5 | CodeGraph 一致 | `codegraph impact <修改文件>` | 与 design.md 影响范围一致 |
| 6 | Graphify 完整 | `graphify diagnose multigraph` | `missing_endpoint_edges = 0` |

任何失败 → 回 BUILD 阶段修复；全部通过 → 进入 `/opsx:archive`。

### 归档（archive）— 不可逆

1. **预检**（用 `/opsx:verify` 已通过的）：
   - `tasks.md` 所有任务 `- [x]`
   - `review.md` 存在 + 人类审查签字
   - `verify-report.md` 存在 + 6 项全过
2. **同步 delta**（见 OpenSpec Specs §Sync 同步规则）——`/opsx:archive` 自动流程会先调 `/opsx:sync`
3. **移动**：
   ```bash
   mv openspec/changes/<id>/ openspec/changes/archive/$(date +%Y-%m-%d)-<id>/
   ```
   保留 `.openspec.yaml` 在移动后目录内。
4. **Commit**（格式固定）：
   ```bash
   git add openspec/changes/
   git commit -m "chore(spec): archive <change-id>"
   ```
5. **最终校验**：
   ```bash
   openspec validate --strict --specs
   ```

**关键约束**：
- 永不删除 `openspec/changes/` 条目（审计追踪）
- 永不 `rm -rf` —— 用 `mv` 到 `archive/`
- 永不程序化合并 baseline —— 智能匹配 Requirement 头
- Archive 后 `openspec/specs/<cap>/spec.md` 是新基线，下次搜索从这里开始

### 一句话流程

> 接到需求 → 加载 `superpowers-using-superpowers` + `openspec-workflow` → 选 opsx 命令 → 5 phase 5 gate → 验证 → 归档 → 更新 baseline。

## OpenSpec Tools

> OpenSpec 工具包含 **CLI**（`openspec` 命令）和**原生 slash 命令**（`.opencode/commands/opsx-*.md`）。前者是底层，后者是 AI 友好入口。

### 启动时（每次 session / 新需求）— 必做

1. **读仓库根 `AGENTS.md`** —— 了解 `.opencode/` 归属规则、`FEMU_ROOT` 解析、MCP 配置、OpenSpec 流程规则。
2. **加载 Skill Bootstrap**（按 `§superpowers` 表格）：
   - `superpowers-using-superpowers` —— 工程纪律总入口
   - `openspec-workflow` —— 5 phase 概念层
3. **检查环境**：
   ```bash
   bash scripts/verify.sh                                  # 17/17 通过
   OPENSPEC_TELEMETRY=0 openspec validate --strict --specs  # baseline 有效
   ```

### `/opsx:*` slash 命令

| 命令 | 用途 | 对应 CLI |
|------|------|----------|
| `/opsx:onboard` | 新成员引导（5 phase 走一遍） | — |
| `/opsx:propose <name> "intent"` | 苏格拉底式访谈 + 生成 4 artifacts | `openspec new change` + `openspec instructions` |
| `/opsx:ff <name> "intent"` | 一次性建空骨架 + 生成 4 artifacts | 同上（无访谈） |
| `/opsx:new <name>` | 仅建空骨架 | `openspec new change` |
| `/opsx:continue` | 创建下一个 pending artifact | — |
| `/opsx:explore [topic]` | 调研/对比方案（不写代码） | — |
| `/opsx:apply [name]` | 按 tasks 顺序逐项实施 + 勾选 | `openspec instructions apply` |
| `/opsx:verify` | 跑 6 项 archive 前检查 | — |
| `/opsx:sync` | 智能合并 delta 到 baseline | — |
| `/opsx:archive <name>` | 同步 + 移动 + commit | `openspec status` (then `mv`) |
| `/opsx:bulk-archive` | 批量归档多个已完成变更 | — |

### openspec CLI 常用命令

```bash
openspec list --json                  # 活跃变更（JSON）
openspec list --specs                 # baseline capabilities
openspec status --change "<name>"     # 变更状态
openspec validate --strict --specs    # baseline 校验
openspec validate --strict --changes  # 活跃变更校验
OPENSPEC_TELEMETRY=0 <上述命令>        # 关闭遥测
```

### 关键参考

| 资源 | 内容 |
|------|------|
| `sd-firmware-copilot/SKILL.md` | 项目流水线 + 五门禁 + Iron Rules |
| `openspec-workflow/SKILL.md` | OpenSpec 5 phase 概念层 |
| `.opencode/memory/architecture.md` | SSD 固件架构分层规则 |
| `.opencode/memory/design_rules.md` | 错误处理横切规则 |
| `.opencode/memory/{concurrency_rules,coding_style,testing_rules}.md` | 编码约束 |
| `openspec/config.yaml` | OpenSpec 项目配置（context + rules） |
| `docs/adr/` | 方法论选择依据（ADR 格式） |

## superpowers

本项目包含 **Superpowers** 技能框架（8 个子技能，`.opencode/skills/superpowers-*/`）作为项目无关的工程纪律层。完整索引（4 Iron Rules + Bootstrap 决策表 + Skill map）整合至 `sd-firmware-copilot/SKILL.md §Superpowers 框架整合`。

### Skill 自动触发（Bootstrap）— 替代全局 `experimental.chat.system.transform` 钩子

> **为什么需要这一节**：本项目通过把 Superpowers 13 个 skill **逐个复制到 `.opencode/skills/`** 实现项目自包含分发（不依赖 `~/.config/opencode/superpowers/` 全局安装）。代价是**没有官方引导插件**自动注入 `using-superpowers` 内容到系统提示——必须由本节作为**项目级 bootstrap**，把全局钩子的"1% 规则"显式化。

**会话开始时强制加载**（每次新 session / 新需求的第一动作）：

```text
skill(name="superpowers-using-superpowers")
```

**按场景自动加载规则**（"1% 规则"——只要 1% 概率匹配，立即加载）：

| 触发场景 | 必加载 skill | 缺失后果 |
|----------|-------------|----------|
| 会话开始 / 收到新需求 | `superpowers-using-superpowers` | 上下文无纪律约束 |
| 涉及 bug、test failure、异常行为 | `superpowers-systematic-debugging` | 凭直觉打补丁 |
| 写生产代码（含 C/H 文件编辑） | `superpowers-verification-before-completion` | 无测试证据，代码不可信 |
| 进入 BUILD 阶段（`/opsx:apply`） | `superpowers-executing-plans` + `superpowers-verification-before-completion` | 跳过任务、跳过验证 |
| 合并前 / 用户说「review my work」 | `superpowers-requesting-code-review` | AI 自批自审 |
| 收到审查反馈 | `superpowers-receiving-code-review` | 表演性认同 / 盲目实现 |
| 所有任务完成，准备合并 | `superpowers-finishing-a-development-branch` | 直接合并不清理 |
| 即将「声明完成 / 修复 / 通过」 | `superpowers-verification-before-completion` | 无证据断言 |

**4 Iron Rules（不可妥协）**：

- **NO COMPLETION CLAIMS WITHOUT FRESH VERIFICATION EVIDENCE** — 完成前必须实际运行测试/编译/命令并验证结果，禁止「应该没问题」。
- **NO PRODUCTION CODE WITHOUT TESTS** — 每段生产代码必须有对应的测试覆盖。纯逻辑代码用单元测试验证；硬件依赖代码（MMIO/ISR/DMA）用集成测试或仿真验证，或在 `review.md` 标注不可覆盖原因。
- **NO FIXES WITHOUT ROOT CAUSE INVESTIGATION FIRST** — 复现、读错误、查变更、形成假设、最小验证，禁止凭直觉打补丁。
- **NO MERGE WITHOUT CODE REVIEW** — 每个非平凡变更必须经正式审查，接收反馈以技术为准不表演性认同。

> 详细决策表 + Skill map → `sd-firmware-copilot/SKILL.md §Superpowers 框架整合`。

## 方法论概览

> 本节从 `docs/navigation.md` 迁入（2026-06-23）—— AI / 人共用同一份方法论入口。4 Iron Rules 见上文 §superpowers。

### 两种驱动路径

**路径 A：设计文档驱动**（已有 SAD/SDD/ICD）

```
设计文档 → [KNOW] 理解设计 + 定位代码 → [PLAN] 规格化变更 → [BUILD] 实现 + 测试 → [FEEDBACK] 归档
```

**路径 B：代码驱动**（无设计文档，AI 先分析代码生成设计文档）

```
现有代码 → [KNOW] 分析代码 + 生成设计文档 → [PLAN] 规格化变更 → [BUILD] 实现 + 测试 → [FEEDBACK] 归档
```

两种路径仅 KNOW 阶段不同；从 PLAN 开始完全一致。

### 核心闭环：KNOW → PLAN → BUILD → FEEDBACK

| 阶段 | 工具 | 职责 |
|------|------|------|
| **KNOW** | Graphify + CodeGraph | 理解现有系统结构 |
| **PLAN** | OpenSpec CLI v1.4.1 | 创建 proposal / design / tasks / specs 增量 |
| **BUILD** | Superpowers + sd-firmware-copilot | 代码实现 + 测试验证 + 根因调试 + 验证完成。须通过 BUILD Gate |
| **FEEDBACK** | OpenSpec archive + Graphify | 规格归档 + 知识图谱增量更新 |

由 OpenCode Agent 统一编排四阶段。

### 五级门禁

```
Proposal Gate → Design Gate → BUILD Gate → Review Gate → Archive Gate
```

BUILD Gate 是 2026-06-22 新增，强制 AI 在编码前加载验证 skill。单文件 bugfix 可跳过 Proposal Gate。

### 核心原则

| 原则 | 说明 |
|------|------|
| **代码优先** | `Source Code > Design Docs > Specs > Memory > Prompt` |
| **小任务原则** | 每次 200-500 行，不扩大需求 |
| **修改前必查 CodeGraph** | 修改函数签名/结构体/头文件前必须查影响范围 |
| **AI 辅助不替代** | 人负责架构决策、风险判断、最终责任 |
| **五级门禁不跳过** | 5 道门禁强制纪律；单文件 bugfix 豁免 Proposal Gate |
| **规格优先于记忆** | Specs 是基线；查询优先级 specs → CodeGraph → 代码 |
| **全部工件版本化** | proposal / design / tasks / review / specs 纳入 Git |

### 快速上手（5 分钟）

```bash
# 1. 一键部署工具链
bash scripts/deploy_tools.sh /path/to/c-source

# 2. 验证环境
bash scripts/verify.sh    # 确认 17/17 通过

# 3. 选一条路径开始
# 路径 A（有设计文档）→ /opsx:propose <change-name>
# 路径 B（无设计文档）→ codegraph explore <区域> 先生成设计文档
```

### 完整流程（路径 A 为例）

```bash
# ─── KNOW：理解设计 ───
graphify query "<设计关键词>"
graphify explain "<核心概念>"
codegraph explore <代码区域>

# ─── PLAN：创建变更 ───
/opsx:propose my-change "根据 SDD 第 X 章实现 Y 功能"
# → Design Gate：人工确认 → BUILD Gate：AI 加载验证 skill

# ─── BUILD：实现 + 测试验证 ───
/opsx:apply my-change
# → 按 tasks.md 实现 → 编写测试覆盖正常/边界/错误路径
# → 注入验证：每条测试路径 bug 注入→失败→撤销→通过

# ─── FEEDBACK：Review + 归档 ───
# → Review Skill 产出 review.md
/opsx:archive my-change
graphify update <子目录>   # 大项目避免全仓库扫描
```
