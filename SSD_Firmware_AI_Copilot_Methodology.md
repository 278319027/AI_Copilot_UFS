# SSD 固件 AI 辅助编程方法论

## 1. 目标

面向大型嵌入式固件项目，建立一套基于 `OpenCode Agent` 编排的四工具 AI 辅助编程体系，形成 **KNOW→PLAN→BUILD→FEEDBACK** 闭环：

| 阶段 | 主导工具 | 作用 |
|------|---------|------|
| **KNOW** | **Graphify**（知识图谱）+ **CodeGraph**（调用图） | 理解现有系统：需求 / 设计 / 代码结构 / 调用链 / 概念关系 |
| **PLAN** | **OpenSpec CLI** | 规格化变更：proposal / design / tasks / specs 增量 / 三级门禁 |
| **BUILD** | **Superpowers**（工程纪律引擎）+ `sd-firmware-copilot`（领域规则） | 严格实现：TDD / 根因调试 / 验证后才完成 / SSD 固件专项约束 |
| **FEEDBACK** | **OpenSpec CLI** + **Graphify** | 闭环反馈：specs 增量合并到 baseline / 知识图谱增量更新 / 可审计 |

其中 **Superpowers** 提供工程纪律底座（`.opencode/skills/superpowers/`，10 个子技能），`sd-firmware-copilot` 在其上层叠加 SSD 固件领域规则，两者正交合作。

- 理解模块设计
- 理解现有代码
- 生成实现方案
- 辅助编码
- 辅助 Review
- 辅助测试设计

最终目标是：

- 提升开发效率
- 提升代码一致性
- 降低 Review 成本
- 缩短新人上手周期
- 降低架构演化成本

## 2. 核心原则

### 2.1 代码优先

优先级顺序：

```text
Source Code
>
Design Docs
>
Memory
>
Prompt
```

含义是：

- 代码是真实实现
- 文档描述事实，但可能滞后
- Memory 保存团队规则，不替代设计
- Prompt 只是当前任务输入，不应成为长期知识源

### 2.2 CodeGraph 优先

AI 先理解系统结构，再生成代码。

必须优先建立：

- 调用关系
- 依赖关系
- 引用关系
- 模块关系

AI 不能从文本直觉直接生成大段代码，必须先建立代码图谱认知。

### 2.3 小任务原则

禁止让 AI 一次性实现整个模块。

推荐粒度：

- 一个接口
- 一个状态机
- 一个功能点
- 一个子模块
- 一个文件

任务规模分级：

- 微修改（5~50 行）：精确修改现有逻辑（如增加计数器、修改变量名、调整阈值）
- 标准任务（200~500 行）：新增功能模块或显著重构

复杂模块拆成多个迭代完成。

### 2.4 规则与设计分离


- `.opencode/memory/`：记录规则、风格、约束
- `.opencode/skills/`：记录工作流和流程能力

三者必须独立维护，不能混在一起。

### 2.5 AI 辅助，不替代人

AI 负责：

- 理解
- 分析
- 生成
- Review
- 测试建议

人负责：

- 架构决策
- 设计确认
- 代码确认
- 风险判断
- 最终责任

### 2.6 Superpowers 铁律（工程纪律底座）

**Superpowers**（`.opencode/skills/superpowers/`，10 个子技能）是工程纪律底座，跨越所有项目、贯穿 KNOW→PLAN→BUILD→FEEDBACK 全环，对所有 AI 输出强制三条铁律：

1. **NO COMPLETION CLAIMS WITHOUT FRESH VERIFICATION**（不验证不宣称完成）
   - 完成前必须用 `verification-before-completion` Skill 实际运行测试 / 编译 / 命令，确认结果匹配
   - 禁止"我运行了""我做了""应该工作"等不可验证的完成声明
   - 适用：BUILD 编码完成 / FEEDBACK 归档后 / Review 通过

2. **NO PRODUCTION CODE WITHOUT FAILING TEST FIRST**（无失败测试不写实现）
   - 必须先用 `test-driven-development` Skill 写出失败测试（红），再写实现让它通过（绿）
   - 禁止"先写代码再补测试"
   - 例外：纯文档 / 注释 / 知识库更新、build/CI 配置（需在 tasks.md 标注）

3. **NO FIXES WITHOUT ROOT CAUSE INVESTIGATION**（无根因调查不修 bug）
   - 任何 bug / 失败必须先用 `systematic-debugging` Skill 完成根因调查，证据可追溯
   - 禁止凭直觉打补丁；禁止"试一下"多次重试
   - 输出：根因 + 证据 + 修复方案 + 回归测试，全部进入 review.md（由 Review Skill 委派到 Superpowers requesting-code-review 产出）

附加铁律：

- `requesting-code-review` / `receiving-code-review`：Review 双向规范，跨人 / 跨 Agent 一致
- `subagent-driven-development` / `dispatching-parallel-agents`：并行 Agent 调度 + 隔离
- `executing-plans` / `finishing-a-development-branch`：计划执行与分支收尾

> Superpowers 是项目无关的通用工程纪律，`.opencode/skills/sd-firmware-copilot/` 在其上层叠加 SSD 固件领域规则（状态机 / Context / 并发安全 / ECC / NVMe 错误处理）。两者正交：Superpowers 负责"工程做法正确"，领域规则负责"固件语义正确"。

## 3. 总体架构

建议形成如下系统结构：

```text
OpenCode Agent                       ← 统一编排 KNOW→PLAN→BUILD→FEEDBACK
    ├── KNOW:   Graphify + CodeGraph  ← 知识图谱 + 调用图
    ├── PLAN:   OpenSpec CLI          ← 规格驱动开发
    ├── BUILD:  Superpowers + Skills  ← 工程纪律 + 领域规则
    └── FEEDBACK: OpenSpec + Graphify ← 归档 + 知识图谱更新
    └── Docs / Memory / Source Code   ← 基础数据
```

其中：

- `Graphify` + `CodeGraph` 是 AI 理解工程的基础设施（KNOW 层）
- `OpenSpec CLI` 是规格驱动开发的核心（PLAN + FEEDBACK 层），提供 propose / apply / archive 命令
- `Superpowers` 是工程纪律底座（BUILD 层），提供 TDD / 根因调试 / 验证后完成 等铁律
- `sd-firmware-copilot` Skill 在 Superpowers 之上叠加 SSD 固件领域规则
- `Docs` 是项目事实记录
- `Memory` 是项目规则与约束
- `Skills` 是可复用工作流（含 Superpowers + development + review + sd-firmware-copilot）
- `Source Code` 是最终真实实现

## 4. 五大核心组成

### 4.1 Source Code

代码库是最大的知识源。AI 必须能访问：

- 全部源代码
- 头文件
- 构建脚本
- 配置文件
- 平台相关定义

推荐目录示例：

```text
source/
  app/
  service/
  driver/
  os/
  common/
  platform/
```

要求：

- AI 在写代码之前，必须先定位相关文件
- 必须识别调用链
- 必须分析上下游依赖
- 必须确认修改影响范围

### 4.2 CodeGraph

#### 定位

CodeGraph 是整个系统的基础设施，优先级最高。

#### 目标

建立以下关系图：

- Call Graph
- Struct Graph
- Dependency Graph
- Module Graph

#### AI 必须具备的能力

AI 应能回答：

- 谁调用了这个函数
- 这个函数调用了谁
- 这个结构体在哪里使用
- 改这个接口会影响哪些模块
- 状态机入口在哪里

#### 工具实现

CodeGraph 通过以下工具组合实现：

| 工具 | 用途 | 覆盖场景 | 安装 |
|------|------|----------|------|
| **ops-codegraph** | 主工具：调用图/依赖图/影响分析，30+ MCP 工具 | ~80% | `npm install -g @optave/codegraph` |
| **ctags + cscope** | 补充工具：函数指针/宏查询（tree-sitter 盲区） | ~15% | `apt install universal-ctags cscope` |
| **Doxygen** | 可视化：交互式 HTML 文档+图（按需） | ~5% | `apt install doxygen graphviz` |

ops-codegraph 通过 MCP 协议与 OpenCode Agent 集成，AI 可直接调用 `codegraph_callers`、`codegraph_callees`、`codegraph_explore` 等 30+ 工具（当前部署于 FEMU `../femu/hw/femu/`，zsf 仓库无代码）。

C 语言特殊限制：tree-sitter 无法解析函数指针调用和宏展开，这些场景必须用 cscope 补充。

#### 工具兼容性检查

引入新工具时，必须先验证核心依赖兼容性，避免在已知限制上反复尝试：

1. **LLM API 兼容性**：使用自定义 API（如 DeepSeek）的工具，先用最简命令测试。若工具内部硬编码 OpenAI SDK 且不支持 `OPENAI_BASE_URL` 覆盖，则 LLM 功能不可用，接受 AST-only 模式。
2. **构建范围**：CodeGraph 构建前确认索引范围。对大型项目（如 QEMU 78K 文件），用 `codegraph init <subdir>` 限定到目标模块（如 `hw/femu`），避免全项目索引超时。
3. **失败重试上限**：任何工具配置尝试超过 2 次仍失败，接受当前限制并记录到知识库，不继续尝试。

#### 建设顺序

1. Call Graph（ops-codegraph 自动构建）
2. Struct Graph（ctags 索引）
3. Dependency Graph（ops-codegraph 自动构建）

#### 安装与配置

详见 [CodeGraph 部署与使用教程](./.opencode/skills/sd-firmware-copilot/references/deploy-guide.md)。

#### 查询工具选择矩阵

| 我想知道... | 用 CodeGraph | 用 Graphify | 用 Memory 规则 |
|------------|-------------|------------|-------------|
| 谁调用了这个函数？ | `codegraph callers <func>` | — | — |
| 修改这个函数影响谁？ | `codegraph impact <func>` | — | — |
| 相关概念有哪些？ | — | `graphify query "<概念>"` | — |
| 这段代码为什么这样设计？ | — | `graphify explain "<概念>"` | 查看 design_rules.md |
| 这个模块的架构约束？ | `codegraph explore <module>` | `graphify path "<A>" "<B>"` | architecture.md |
| 并发安全性规则？ | — | — | concurrency_rules.md |
| 我应该用哪种编码风格？ | — | — | coding_style.md |

### 4.3 Docs 体系

Docs 记录项目事实，不是 AI 配置。

推荐目录：

```text

  SDD/
  ICD/
  TEST/
```

#### SAD

Software Architecture Design，记录：

- 模块划分
- 分层关系
- 模块职责

#### SDD

Software Design Document，记录：

- 接口
- 状态机
- 流程
- 约束

#### ICD

Interface Control Document，记录：

- API
- 消息
- 数据结构
- 模块边界

#### TEST

测试设计文档，记录：

- 测试策略
- 覆盖要求
- 验收标准

### 4.4 Memory 体系

Memory 保存项目规则，不保存项目设计本身。

推荐目录：

```text
.opencode/memory/
  architecture.md
  coding_style.md
  design_rules.md
  review_rules.md
  testing_rules.md
```

#### architecture.md

记录：

- 模块边界
- 分层规则
- 依赖规则

例如：

- 禁止跨层调用
- 禁止访问其他模块私有数据

#### coding_style.md

记录：

- 命名规范
- 文件规范
- 接口规范

#### design_rules.md

记录：

- 状态机设计规范
- Context 设计规范
- 资源管理规范

#### review_rules.md

记录：

- Review 检查项
- 风险等级定义

#### testing_rules.md

记录：

- 单元测试要求
- 覆盖率要求
- Mock 规范

## 4.5 硬件知识库

> 新增。来源：《固件AI辅助编程探索》第 7.1.2 节 P0 建议。

硬件知识库存储 AI 无法从代码推断的隐性知识，包括寄存器地址、配置顺序、时序约束等。

推荐目录：

```text
.opencode/knowledge/
  nand_controller/
    registers.md          # NAND 控制器寄存器定义和配置顺序
    operations.md         # NAND 操作序列和命令码
    constraints.md        # 时序约束、并发约束、错误恢复
  nvme_spec/
    admin_commands.md     # NVMe Admin 命令集和数据结构
    io_commands.md        # NVMe I/O 命令集
  platform/
    memory_map.md         # 系统内存映射、中断分配、时钟树
    power_states.md       # 电源状态转换
```

#### 知识库原则

1. **只包含隐性知识**：寄存器地址、配置顺序、时序参数 ✅；函数签名、数据结构定义 ❌
2. **每个文件不超过 2000 行**：控制 token 开销
3. **按 Skill 粒度拆分**：按需注入而非全量注入
4. **版本绑定**：知识文件必须标注适用的芯片型号和固件版本

#### 填写说明

每个模板文件包含填写说明和占位符，使用时需替换为实际芯片的值。
不同芯片型号有不同的填写文件。

### 4.6 OpenSpec 规格层（PLAN + FEEDBACK）

> Phase 1 完成：OpenSpec CLI v1.4.1 已部署（`npm install -g @fission-ai/openspec`），`openspec/` 目录已初始化。

OpenSpec 规格层是规格驱动开发在 zsf 中的落地点，独立于约束层（Memory）和基础设施层（CodeGraph），是「系统当前行为」的权威描述，也是 KNOW→PLAN→BUILD→FEEDBACK 闭环的 PLAN / FEEDBACK 阶段支撑。

**OpenSpec CLI 提供的命令**（Plan/Build/Feedback 全程调用）：

| 命令 | 对应阶段 | 作用 |
|------|---------|------|
| `/opsx:propose <id> "<意图>"` | PLAN | 一条命令创建变更目录 + 生成 proposal.md / design.md / tasks.md / specs/ 增量 |
| `/opsx:apply <id>` | BUILD | 按 tasks.md 顺序执行任务，同步状态 |
| `/opsx:archive <id>` | FEEDBACK | 合并 specs/ 增量到 baseline，产生可审计 commit |
| `/opsx:sync` | FEEDBACK | 与代码 diff 同步 baseline，反映未走 OpenSpec 流程的隐含变更 |
| `/opsx:explore` | KNOW | 创建探索性变更（不归档）以供调研 |

**Memory ≠ Spec**：

- Memory 是约束（「必须遵守什么」）——规则、风格、编码规范
- Spec 是行为（「系统当前做什么」）——模块行为、接口契约、状态转换
- 两者独立演进，不冲突

**推荐目录**（`openspec/`，已部署）：

```text
openspec/
├── config.yaml                ← OpenSpec CLI 配置
├── changes/                   ← 活跃变更
│   └── {change-id}/
│       ├── proposal.md         ← 为什么做、做什么
│       ├── design.md           ← 怎么做（含 CodeGraph 查询）
│       └── tasks.md            ← 实现清单
└── specs/                      ← 基线规格（每个 capability 一份 spec.md）
    ├── ssd-firmware-overview/
    │   └── spec.md
    ├── nvme-commands/
    │   └── spec.md
    ├── ftl-mapping/
    │   └── spec.md
    ├── nand-driver/
    │   └── spec.md
    └── error-handling/
        └── spec.md
```

> 增量格式：变更提案时在 `<capability>/spec.md` 内追加 `## ADDED Requirements` / `## MODIFIED Requirements` / `## REMOVED Requirements` 三个二级标题段，**不再使用独立 ADDED.md / MODIFIED.md / REMOVED.md 文件**。
#### 规格层价值

1. **当前行为权威描述**：基线文件描述系统实际行为，AI 查询优先级：基线 → CodeGraph → 代码
2. **行为变更追溯**：每次变更在 `specs/<capability>/spec.md` 内追加 ADDED/MODIFIED/REMOVED Requirements 段，持久化行为变化
3. **三级门禁联动**：Proposal Gate → Design Gate → Review Gate，每级有明确的输入和检查项
4. **审计历史保留**：`openspec/changes/` 目录不删除，每次归档产生 `chore(spec): archive` commit

#### OpenSpec Skill 适配器

OpenCode 已集成 5 个 OpenSpec 包装 Skill（位于 `.opencode/skills/openspec-*/`）：

- `openspec-propose` / `openspec-apply-change` / `openspec-archive-change`
- `openspec-sync-specs` / `openspec-explore`

#### 规则文件

规格层操作规则详见 `.opencode/skills/sd-firmware-copilot/rules/spec_rules.md`。

### 4.7 Superpowers 体系（工程纪律底座）

> Phase 2 完成：`.opencode/skills/superpowers/` 已部署（10 个子技能）。

Superpowers 是项目无关的通用工程纪律底座，对所有 AI 输出强制三条铁律（详见 §2.6）：

| 子技能 | 铁律 | 使用阶段 |
|--------|------|---------|
| `test-driven-development` | 无失败测试不写实现 | BUILD |
| `systematic-debugging` | 无根因不修 bug | BUILD（纠错） |
| `verification-before-completion` | 不验证不宣称完成 | BUILD / FEEDBACK |
| `requesting-code-review` | 评审请求规范 | BUILD（Review） |
| `receiving-code-review` | 接收反馈规范 | BUILD（Review） |
| `subagent-driven-development` | 并行子 Agent 驱动 | BUILD（多任务） |
| `dispatching-parallel-agents` | 并行 Agent 调度 | BUILD（多任务） |
| `executing-plans` | 计划执行 | BUILD |
| `finishing-a-development-branch` | 分支收尾 | FEEDBACK |
| `SKILL.md` | 入口 + 完整铁律索引 | 任意 |

#### 与领域规则的关系

```
┌────────────────────────────┐
│  Superpowers (项目无关)     │ ← 工程做法正确
├────────────────────────────┤
│  sd-firmware-copilot (领域) │ ← 固件语义正确
├────────────────────────────┤
│  OpenSpec CLI (规格驱动)    │ ← 变更可追溯
└────────────────────────────┘
```

- **Superpowers** 负责"工程做法正确"（TDD / 调试 / 验证 / 评审协议）
- **sd-firmware-copilot** 负责"固件语义正确"（状态机 / Context / 并发 / ECC / NVMe）
- **OpenSpec CLI** 负责"变更可追溯"（proposal / design / tasks / archive）

三者正交合作，缺一不可。

## 5. Skills 体系

Phase 2 后，Skill 体系扩展为 3 层 10+ 项：

```text
.opencode/skills/
├── 工程纪律层（项目无关）
│   └── superpowers/                       ← 10 个子技能（TDD / debugging / verification / ...）
│
├── OpenSpec 适配层（包装 CLI）
│   ├── openspec-propose/
│   ├── openspec-apply-change/
│   ├── openspec-archive-change/
│   ├── openspec-sync-specs/
│   └── openspec-explore/
│
└── 领域规则层（SSD 固件）
    ├── development/                       ← 开发流程（KNOW → PLAN → BUILD 编排）
    ├── review/                            ← Review 流程（verification-before-completion）
    └── sd-firmware-copilot/               ← 可分发包（init.sh + rules + references + 知识模板）

### 5.1 development

职责：

- 读取设计文档
- 读取代码
- 查询 CodeGraph + Graphify（KNOW）
- 调度 OpenSpec CLI（PLAN：/opsx:propose）
- 分析影响范围
- 调度 Superpowers `test-driven-development`（BUILD 编码）
- 调度 Superpowers `systematic-debugging`（BUILD 纠错）
- 输出修改方案 + 任务分解
- 生成代码 + 测试建议
- 调度 OpenSpec CLI（FEEDBACK：/opsx:apply → /opsx:archive）

标准流程（KNOW→PLAN→BUILD→FEEDBACK）：

```text
Step 1  理解需求   [KNOW]   graphify query / codegraph explore
Step 2  定位代码   [KNOW]   codegraph callers/callees/impact
Step 3  分析依赖   [KNOW]   design.md 中持久化 CodeGraph 结果
Step 4  规格化     [PLAN]   /opsx:propose → proposal.md + specs/ 增量
Step 5  设计方案   [PLAN]   /opsx:propose 生成 design.md + tasks.md
                          → Design Gate：人工确认
Step 6  TDD 编码   [BUILD]  /opsx:apply 按 tasks.md 执行
                          Superpowers: test-driven-development
Step 7  测试建议   [BUILD]  Superpowers: TDD 给出 UT / 边界 / 异常
Step 8  Review     [BUILD]  Superpowers: verification-before-completion
Step 9  归档       [FEED]   /opsx:archive + graphify update .
```

> **AI 必须在设计方案结尾显式列出「待人工确认清单」，包含：架构假设是否正确、影响范围是否完整、是否有更简单的替代方案。人工逐项确认通过后，方可进入编码。**
> **Superpowers 铁律**：Step 6 必须 TDD（先写失败测试），Step 8 必须实际运行测试 / 编译验证后才宣称完成。

### 5.2 review

职责：

- Review 设计
- Review 代码
- Review 接口
- Review 状态机
- 调度 Superpowers `verification-before-completion`（不验证不完成）
- 调度 Superpowers `requesting-code-review` / `receiving-code-review`

重点检查：

- 空指针
- 数组越界
- 资源泄漏
- 竞态条件
- 死循环
- 模块边界违反
- 接口兼容性风险
- **CodeGraph 影响范围 vs design.md 声明一致性**（查证式）
- **specs/ 增量 vs 实际代码行为一致性**（查证式）
- **测试覆盖：UT / 边界 / 异常 / 回归**

## 6. 标准工作流

### 6.0 四工具闭环标准工作流

本工作流现集成 **四工具架构**（OpenSpec CLI + Superpowers + Graphify + CodeGraph）作为阶段支撑：

```text
需求 / 设计文档
  │
  ▼
[KNOW] Step 0: 理解系统
  │  graphify query / explain / path
  │  codegraph explore
  │
  ▼
[PLAN] Step 1: /opsx:propose "<change-id>" "<意图>"
  │  生成 proposal.md + design.md + tasks.md + specs/ 增量
  │  → Proposal Gate：人工确认动机清晰、范围正确
  │
  ▼
[PLAN] Step 2: 影响分析（持久化到 design.md）
  │  codegraph callers / callees / impact
  │  cscope -L2/-L4（函数指针 / 宏补充）
  │  → Design Gate：人工确认架构假设、影响范围、替代方案
  │
  ▼
[BUILD] Step 3: /opsx:apply "<change-id>"
  │  Superpowers: test-driven-development（先写失败测试）
  │  200~500 行/任务，按 tasks.md 执行
  │  遇到 bug → Superpowers: systematic-debugging（无根因不修）
  │
  ▼
[BUILD] Step 4: Review
  │  Superpowers: verification-before-completion（不验证不完成）
  │  Superpowers: requesting-code-review
  │  → Review Gate：影响范围、增量一致、测试覆盖
  │
  ▼
[FEEDBACK] Step 5: /opsx:archive "<change-id>"
  │  specs/ 增量合并到 openspec/specs/
  │  graphify update .（AST-only）
  │  commit: chore(spec): archive
  │
  ▼
[FEEDBACK] Step 6: 人工确认 + 提交
```

#### OpenSpec CLI 调度矩阵

| 阶段 | OpenSpec 命令 | 产物 | 门禁 |
|------|---------------|------|------|
| PLAN | `/opsx:propose` | `openspec/changes/{id}/{proposal,design,tasks}.md` + 受影响 `specs/<capability>/spec.md` 的 ADDED/MODIFIED/REMOVED Requirements 段 | Proposal Gate + Design Gate |
| BUILD | `/opsx:apply` | 代码 + 测试 | 任务 checklist 逐项完成 |
| FEEDBACK | `/opsx:archive` | `openspec/specs/` 更新 + `chore(spec): archive` commit | Review Gate |
| KNOW（探索） | `/opsx:explore` | 探索性变更（不归档） | — |
| FEEDBACK（同步） | `/opsx:sync` | 未走 OpenSpec 流程的隐含变更同步到 baseline | — |

> 所有 OpenSpec 变更均通过 `openspec/` 目录跟踪，模板见 `references/spec_workflow.md`。

#### Superpowers 铁律检查点

| 阶段 | 铁律 | 强制 Skill | 失败后果 |
|------|------|-----------|---------|
| BUILD 编码 | 无失败测试不写实现 | `test-driven-development` | 禁止合并 |
| BUILD 纠错 | 无根因不修 bug | `systematic-debugging` | 禁止补丁式修复 |
| BUILD 完成 | 不验证不宣称完成 | `verification-before-completion` | 禁止"应该工作了" |
| Review 阶段 | 评审请求规范 | `requesting-code-review` | 防止单方面放行 |
| 多任务并行 | 并行 Agent 隔离 | `subagent-driven-development` / `dispatching-parallel-agents` | 防止上下文污染 |

### 6.1 需求理解

输入：

- 模块设计文档
- 相关现有代码
- 相关规则
- CodeGraph（调用图）+ Graphify（知识图谱）

命令：

- `graphify query "<需求关键词>"`
- `graphify explain "<概念>"`
- `codegraph explore <区域>`

输出：

- 需求摘要
- 关键接口
- 风险点
- 缺失信息

### 6.2 影响分析

AI 必须先分析（结果持久化到 `openspec/changes/{id}/design.md`）：

- 谁会调用这个接口：`codegraph callers <symbol>`
- 这个接口依赖谁：`codegraph callees <symbol>`
- 这个结构体被谁引用：`codegraph impact <symbol>`
- 状态机入口在哪：`codegraph explore <query>`
- 函数指针 / 宏的调用关系：`cscope -L2/-L4`
- 修改会影响哪些文件（合并 callers + impact 推断）

### 6.3 设计方案输出

> **AI 设计方案必须附带「待人工确认清单」，至少包含：架构假设是否正确？/ 影响范围是否完整？/ 是否有更简单的替代方案？人工逐项确认通过后方可开始编码。**

命令：`/opsx:propose` 阶段生成 `design.md`，由 `openspec-apply-change` Skill 调度。

输出内容建议包括：

- 修改文件列表
- 接口方案
- 数据结构方案
- 状态机方案
- 错误处理策略
- 风险项
- **CodeGraph 影响范围证据**（callers / callees / impact 命令的原始输出）
- **待人工确认清单**（强制）：架构假设、CodeGraph 影响范围、替代方案
- 测试建议

### 6.4 代码生成

命令：`/opsx:apply "<change-id>"`，由 `openspec-apply-change` Skill 调度，按 `tasks.md` 顺序执行。

Superpowers 铁律（强制）：

- **test-driven-development**：先写失败测试（红），再写实现（绿）
- **systematic-debugging**：调试 bug 时禁止"试一下"，必须先完成根因调查
- **executing-plans**：按 tasks.md 顺序，禁止跳跃

原则：

- 一次只做一个明确任务
- 不改不相关逻辑
- 不扩大需求
- 不引入不必要重构

### 6.5 Review

命令：人工 + Superpowers + Review Skill 协同，产出 `review.md`（不再手写，由 Review Skill 作为薄适配层委派到 Superpowers `requesting-code-review` 产出）。

Superpowers 铁律（强制）：

- **verification-before-completion**：完成前必须实际运行测试 / 编译 / 命令并验证结果
- **`requesting-code-review` / `receiving-code-review`**：评审请求与反馈规范

Review 的重点不是语法，而是工程风险：

- 边界条件
- 并发问题
- 资源释放
- 兼容性
- 可维护性
- **CodeGraph 影响范围 vs design.md 声明一致性**（查证式）
- **specs/ 增量 vs 实际代码行为一致性**（查证式）
- **测试覆盖：UT / 边界 / 异常 / 回归**

### 6.6 测试建议

> **即使项目无自动化测试框架，AI 也必须输出「测试场景清单」：列出每个修改点的验证方法（编译检查 / 运行时日志 / 边界输入），不可跳过此步骤。**

AI 需要给出（Superpowers TDD 框架）：

- UT 建议（先写失败测试再写实现）
- 边界条件测试
- 异常路径测试
- 回归测试建议

## 7. Hooks 自动化

建议把 AI 流程和工程 hook 结合起来。

### build hook

- 自动编译
- 自动链接

### format hook

- `clang-format`

### static check hook

- `cppcheck`
- 静态分析工具

### test hook

- 单元测试
- 覆盖率统计

这样可以把 AI 的输出自动收敛到工程标准里。

## 8. 推荐目录结构

```text
Project/
  source/

    SDD/
    ICD/
    TEST/

  scripts/                     # 工具脚本（可选：可改用 deploy_tools.sh 一键部署）
  .codegraph/                  # CodeGraph 配置
    config.json                # ops-codegraph 排除目录配置
    Doxyfile                   # Doxygen 配置
  .opencode/
    opencode.json                   # opencode MCP 配置（项目根目录）
    memory/
      architecture.md          # 分层规则 + CodeGraph 查询规则
      coding_style.md
      concurrency_rules.md     # 并发安全规则 ✨新增
      design_rules.md
      review_rules.md
      testing_rules.md
    knowledge/                 # 硬件知识库 ✨新增
      nand_controller/
        registers.md
        operations.md
        constraints.md
        ecc.md                # ECC 纠错与坏块管理
      nvme_spec/
        admin_commands.md
        io_commands.md        # I/O 命令集
        error_handling.md     # 错误处理与状态码体系
      platform/
        memory_map.md
        power_states.md       # 电源状态转换与约束
    skills/
      development/
      review/
      drawio-flowchart/
```

## Context 管理规则

AI Agent 的上下文窗口有限，必须主动管理：

1. **阶段清理**：每个工作阶段（如项目清理、文档同步、代码实施）结束后，主动执行一次 context 压缩，沉淀关键发现。
2. **阈值触发**：当 context 使用率超过 70% 时，暂停新任务，优先压缩已完成的阶段。
3. **避免探索膨胀**：一次并发调用不超过 5 个 explore/librarian agent。超过 3 个同类探索仍未找到答案，改为直接询问人工。
4. **工具调试上限**：遇到工具兼容性问题，尝试不超过 2 轮即接受限制并记录。不在同一方向上持续尝试。
5. **Agent 超时处理**：大型文件（500+ 行）修改任务拆分为更小的 sub-task（每个 ≤100 行），避免触发 staleness 超时（默认 4-6 分钟）。按需调整 `.opencode/oh-my-openagent.json` 的 `staleTimeoutMs`。

> 详见 `.opencode/memory/architecture.md` 第 6 节：Agent 配置与 Context 管理。

## 9. 实施路线图

> 路线图已更新：Phase 1-3 为能力建设期（已完成），Phase 4-5 为实战优化期（部分进行中），Phase 6-7 为规格 + 工程纪律升级期（已完成）。

### Phase 1：建立理解能力 + CodeGraph + 硬件知识库（1-2 周） ✅ 已完成

| 任务 | 状态 | 产出 |
|------|------|------|
| 部署 CodeGraph | ✅ 完成 | ops-codegraph + ctags + cscope + Doxygen |
| 建立 Call Graph | ✅ 完成 | `codegraph build` 自动构建 |
| 建立 Struct Graph | ✅ 完成 | ctags 自动索引 |
| 建立 Dependency Graph | ✅ 完成 | ops-codegraph 自动构建 |
| 接入交叉编译 Hook | 🔲 待做 | 见《可行性报告》P0 建议 |
| 建立硬件知识库 | ✅ 完成 | NAND/NVMe/Platform 知识模板 |
| 增强并发安全规则 | ✅ 完成 | concurrency_rules.md |
| 让 OpenCode 能访问源码 | ✅ 完成 | MCP 服务器配置 |

### Phase 2：建立规则体系 + 度量体系（3-4 周） ✅ 大部分完成

| 任务 | 状态 | 产出 |
|------|------|------|
| 编写 Memory V1 | ✅ 完成 | coding_style + design_rules + review_rules + testing_rules + concurrency_rules |
| 拆分领域 Skill | 🔲 待做 | NAND_driver/NVMe_cmd/buffer_management 等 |
| 建立效果度量 | 🔲 待做 | 度量指标定义和收集 |
| 模型对比测试 | 🔲 待做 | 不同规模模型对比 |

### Phase 3：建设 Skills + RAG（5-6 周） ✅ 部分完成

| 任务 | 状态 | 产出 |
|------|------|------|
| development Skill V1 | ✅ 完成 | 含 CodeGraph 查询步骤 |
| review Skill V1 | ✅ 完成 | 含 CodeGraph 验证步骤 |
| RAG 知识库建设 | 🔲 待做 | 文档+代码向量化检索 |
| 编译-修复闭环 | 🔲 待做 | 自动编译→错误反馈→AI 修复 |

### Phase 4：试点实战（7-10 周） 🔲 待做

| 任务 | 状态 | 产出 |
|------|------|------|
| 选择 3-5 个真实需求 | 🔲 待做 | 优先选择接口层/命令处理类需求 |
| 模拟器验证集成 | 🔲 待做 | QEMU NVMe 模拟或 Test Harness |
| 完整闭环跑通 | 🔲 待做 | CodeGraph + Development + Review + 编译闭环 + 模拟验证 |
| 收集度量数据 | 🔲 待做 | 开发时间、Review 时间、问题数量 |

### Phase 5：持续优化（长期） 🔲 待做

| 任务 | 状态 | 产出 |
|------|------|------|
| 模板库积累 | 🔲 待做 | 常见模式的模板和范例 |
| Hooks 自动化增强 | 🔲 待做 | clang-format + cppcheck + 编译 + 测试 |
| 规则迭代 | 🔲 待做 | 根据实战结果更新 Memory 和 Skill |
| QLoRA 微调评估 | 🔲 待做 | 在内部数据上评估微调可行性 |

### Phase 6：OpenSpec 规格驱动升级（升级期） ✅ 已完成

| 任务 | 状态 | 产出 |
|------|------|------|
| 引入 design.md + tasks.md | ✅ 完成 | Step 1 |
| 引入 proposal.md + review.md（查证式，由 Review Skill 委派到 Superpowers requesting-code-review） | ✅ 完成 | Step 2 |
| 引入 specs/ 增量 + baseline + 归档 | ✅ 完成 | Step 3 |
| 部署 OpenSpec CLI v1.4.1 | ✅ 完成 | `npm install -g @fission-ai/openspec` |
| 5 个 OpenSpec 适配 Skill | ✅ 完成 | `.opencode/skills/openspec-*/` |
| openspec/ 目录初始化与迁移 | ✅ 完成 | `openspec/{changes,specs,config.yaml}` |
| 5 个迁移 specs（nvme/ftl/nand/error） | ✅ 完成 | `openspec/specs/` |

### Phase 7：Superpowers + 四工具架构升级（升级期） ✅ 已完成

| 任务 | 状态 | 产出 |
|------|------|------|
| 部署 Superpowers（10 子技能） | ✅ 完成 | `.opencode/skills/superpowers/` |
| TDD 铁律 | ✅ 完成 | `test-driven-development` Skill |
| 根因调查铁律 | ✅ 完成 | `systematic-debugging` Skill |
| 验证后完成铁律 | ✅ 完成 | `verification-before-completion` Skill |
| 评审双向规范 | ✅ 完成 | `requesting-code-review` / `receiving-code-review` |
| 并行 Agent 调度 | ✅ 完成 | `subagent-driven-development` / `dispatching-parallel-agents` |
| 四工具闭环（KNOW→PLAN→BUILD→FEEDBACK） | ✅ 完成 | 文档同步更新 |

### Phase 8：四工具架构试点（建议） 🔲 待做

| 任务 | 状态 | 产出 |
|------|------|------|
| 用 `/opsx:propose` 试点 1 个真实需求 | 🔲 待做 | 验证 propose→apply→archive 闭环 |
| 强制 TDD（红→绿→重构） | 🔲 待做 | 验证 test-driven-development 铁律 |
| 强制 verification-before-completion | 🔲 待做 | 验证"不验证不完成"纪律 |
| 收集 Superpowers 拦截数据 | 🔲 待做 | TDD 覆盖率、verification 失败次数、debug 根因率 |

## 10. 成功指标

建议用以下指标衡量效果：

- 需求开发时间
- Review 时间
- UT 覆盖率
- 新人熟悉时间
- 缺陷率

目标可以设为：

- 开发效率提升 `20%`
- Review 时间下降 `30%`
- UT 覆盖率提升 `20%`
- 新人熟悉周期下降 `30%`

## 11. 最终形态

AI 系统关注五类信息 + 四件套工具：

```text
规格 (PLAN/FEEDBACK)
-> openspec/specs/   (系统当前行为的权威描述)
-> openspec/changes/{id}/     (行为变更增量 + 工件)

设计
-> docs/

规则
-> memory/
-> knowledge/

代码
-> source/
+ CodeGraph      (调用图 / 影响分析)
+ Graphify       (知识图谱 / 社区检测)
```

通过分层 Skills 完成辅助开发：

- **工程纪律层**（项目无关）：`superpowers/`
  - TDD / systematic-debugging / verification-before-completion / ...
- **OpenSpec 适配层**（包装 CLI）：`openspec-propose` / `openspec-apply-change` / `openspec-archive-change` / `openspec-sync-specs` / `openspec-explore`
- **领域规则层**（SSD 固件）：
  - `development`（编排 KNOW→PLAN→BUILD）
  - `review`（verification-before-completion 查证式验证）
  - `sd-firmware-copilot`（可分发包：规则 + 知识模板 + 规格工件）

最终实现流程（四工具架构 KNOW→PLAN→BUILD→FEEDBACK 闭环）：

```text
需求
  ↓ [KNOW]   Graphify query/explain + CodeGraph explore
  ↓ [PLAN]   /opsx:propose ─► proposal.md + design.md + tasks.md + specs/ 增量
  ↓          → Proposal Gate + Design Gate（人工确认）
  ↓ [BUILD]  /opsx:apply ─► 按 tasks.md 执行
  ↓          Superpowers TDD / systematic-debugging / executing-plans
  ↓          → 代码 + 测试
  ↓ [BUILD]  Superpowers verification-before-completion + requesting-code-review
  ↓          → review.md（查证式，via Superpowers requesting-code-review）
  ↓          → Review Gate
  ↓ [FEEDBACK] /opsx:archive ─► specs/ 增量合并到 openspec/specs/
  ↓          graphify update .（AST-only）
  ↓          commit: chore(spec): archive
  ↓ [FEEDBACK] 人工确认 + 提交
  → 回到 KNOW（带着更新后的 baseline）
```

形成稳定、可维护、可推广、可审计的 AI 辅助编程体系。

## 12. 建议补强项

为了更像企业级方案，建议再补 4 个关键点：

1. 增加文档版本绑定
   - 每次 AI 生成代码都要绑定文档版本号，避免文档和代码漂移。
2. 增加变更粒度约束
   - 一次只允许一个功能点，避免 AI 改动过大。
3. 增加验收标准模板
   - 每个需求必须有输入、输出、异常、边界、回归五类验收项。
4. 增加失败回退机制
   - 如果 AI 输出不通过，必须回退到文档层重新澄清，而不是盲目重试生成。

### 12.1 OpenSpec 工件吸收

以上四个强化项已被 OpenSpec 规格工件体系吸收，不再需要独立维护：

| 强化项 | 吸收到 | 说明 |
|--------|--------|------|
| 文档版本绑定 | `design.md` | CodeGraph 查询结果 + 设计假设随 design.md Git 版本化 |
| 变更粒度约束 | `tasks.md` | 200-500 行/任务的粒度约束固化在 tasks.md 模板中 |
| 验收标准模板 | `design.md` | 「待人工确认清单」字段即为验收标准 |
| 失败回退 | `review.md`（via Superpowers requesting-code-review） | 归档合并建议含回滚点（Step 2 引入 review.md） |

> 详见 `.opencode/skills/sd-firmware-copilot/references/spec_workflow.md`

---

## 13. OpenSpec 集成

### 13.1 动机

zsf 原有 4 大核心组成（Source Code、CodeGraph、Docs、Memory）缺乏「规格层」——一种将「系统当前应该做什么」从代码/规则中独立出来的机制。OpenSpec 填补了此空缺。

集成后架构变为 5 层：

```
┌─────────────────────────────────────────┐
│  规格层 (OpenSpec)   — 当前行为的权威描述   │  ← 新增
├─────────────────────────────────────────┤
│  约束层 (Memory)    — 规则、风格、知识     │
├─────────────────────────────────────────┤
│  基础设施层 (CodeGraph/cscope/Graphify)  │
├─────────────────────────────────────────┤
│  流程层 (Skills)      — 开发/审查流程     │
└─────────────────────────────────────────┘
```

### 13.2 核心机制

| 机制 | 说明 | zsf 落地点 |
|------|------|----------|
| Living spec baseline | 系统当前行为的权威描述 | `openspec/specs/<capability>/spec.md` |
| Delta spec tracking | 每次变更的行为增量 | `openspec/changes/{id}/{capability}/spec.md` 内 ADDED/MODIFIED/REMOVED Requirements 段 |
| Staged review gates | 三级门禁（Proposal/Design/Review） | design_rules.md §7 + spec_rules.md §5 |
| Persistent change artifacts | 所有变更工件 Git 版本化 | `openspec/` 全部文件 |
| Archive & spec merging | Review 通过后增量合并到基线 | `chore(spec): archive` commit |

### 13.3 工具依赖（Phase 1 升级后）

Phase 1 完成后，zsf 的 OpenSpec 集成升级为 **方法论 + CLI 工具 + Skill 适配器** 三层：

| 层 | 形态 | 说明 |
|----|------|------|
| **方法论层** | 规格层规则 | `.opencode/skills/sd-firmware-copilot/rules/spec_rules.md`（基线管理、增量格式、三级门禁、归档） |
| **CLI 工具层** | `npm install -g @fission-ai/openspec`（v1.4.1 已部署） | 提供 `propose` / `apply` / `archive` / `sync` / `explore` 命令，保证工件一致性与可机检 |
| **Skill 适配层** | `.opencode/skills/openspec-*/`（5 个） | 包装 CLI 命令为 OpenCode 可调度 Skill，供 Agent 直接调用 |

CLI 工具层与 CLI 适配层提供**可机检一致性**（proposal 校验 / task 状态同步 / 归档生成），而方法论层是**人为门禁的语义规则**（动机 / 范围 / 替代方案 / 影响范围）。两者分工不重叠。

> 注：项目原采用 `.openspec/` 路径已迁移到 `openspec/`（OpenSpec CLI 1.4.x 默认布局）。
### 13.4 实施进度

分 3 步渐进式引入 + 2 个 Phase 升级：

| 步骤 / Phase | 内容 | 状态 |
|--------------|------|------|
| Step 1 | 引入 design.md + tasks.md | ✅ 完成 |
| Step 2 | 引入 proposal.md + review.md（查证式，via Superpowers requesting-code-review） | ✅ 完成 |
| Step 3 | 引入 specs/ 增量 + baseline + 归档 | ✅ 完成 |
| **Phase 1** | **部署 OpenSpec CLI v1.4.1 + 5 个适配 Skill + openspec/ 迁移** | ✅ 完成 |
| **Phase 2** | **部署 Superpowers（10 子技能）+ 升级为四工具架构** | ✅ 完成（当前） |

### 13.5 与现有流程的关系

- **CodeGraph 保持不动**：Design 阶段强制查询，Review 阶段改为查证式验证
- **Memory 规则保持不动**：约束与规格是正交维度
- **Skills 保持不动**：流程框架不变，融入 OpenSpec 工件作为阶段产出
- **替代而非新增**：OpenSpec 直接替代了执行中的 8 处重复劳动（§6.0 替代关系表 + specs/ 增量吸收了行为追溯需求）

### 13.6 相关文档

| 文档 | 内容 |
|------|------|
| `rules/spec_rules.md` | 规格层规则（基线管理、增量格式、三级门禁、归档） |
| `references/spec_workflow.md` | 全部工件模板与使用规范（proposal/specs/design/tasks/review/archive） |
| `openspec/specs/` | 基线索引与填充状态（按 capability 子目录组织） |
| `.omo/plans/openspec-integration-plan.md` | 完整集成方案与设计决策 |
