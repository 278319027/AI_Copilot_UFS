# OpenSpec 自定义 Schema 详细设计与实施流程

**版本**：V1.0  
**整理日期**：2026-10-01  
**适用范围**：OpenSpec 当前主线实现；重点面向 OpenCode / 多 Agent / Comet / ATDD-TDD / UFS Firmware 开发平台的定制设计

---

## 1. 文档目的

本文档系统梳理 OpenSpec 自定义 Schema 的完整生命周期，并在深入理解 OpenSpec 当前 Skill、CLI、Artifact Graph、Project Config、Change Metadata 与 Apply 机制之后，给出一套可落地的定制流程。

重点回答以下问题：

1. OpenSpec Skill 到底如何消费 Schema；
2. Schema 到底控制什么，不能控制什么；
3. `schema.yaml` 的每一个字段如何影响 Agent；
4. `requires`、`generates`、`template`、`instruction`、`apply.requires`、`apply.tracks` 如何共同形成执行状态；
5. 如何从默认 `spec-driven` 安全演进到公司自定义 Schema；
6. 如何将自定义 Schema 与 Comet、ATDD、TDD、OMO Team Mode、OpenCode Hooks 解耦并正确组合；
7. 如何处理 Schema 的版本、验证、兼容性、团队共享和后续升级。

本文基于 OpenSpec 官方当前文档及其公开仓库主线实现进行整理。OpenSpec 当前把 Schema Commands 标记为 experimental，因此本文同时记录当前实现的边界和注意事项。

---

## 2. 先建立正确的整体认知

### 2.1 OpenSpec 不是“几个 Markdown 模板”

OpenSpec 的有效执行模型可以抽象成：

```text
                    Coding Agent
                         |
                         | 读取 Skill
                         v
                 OpenSpec Workflow Skill
                         |
                         | 调用 CLI 获取真实状态
                         v
                  OpenSpec CLI / Core
                         |
          +--------------+---------------+
          |              |               |
          v              v               v
       Schema       Project Config   Change Metadata
          |              |               |
          +--------------+---------------+
                         |
                         v
                 Artifact Dependency Graph
                         |
              +----------+----------+
              |          |         |
              v          v         v
           Template  Instruction  requires
              |          |         |
              +----------+----------+
                         v
                  Change Artifacts
                         |
                         v
                    Apply / Verify
                         |
                         v
                       Archive
```

因此需要把几个概念严格区分：

| 层 | 核心职责 | 典型内容 |
|---|---|---|
| Skill | 告诉 Agent “如何按 OpenSpec 工作” | Explore / Propose / Apply / Update / Verify / Archive |
| Schema | 定义“一个 Change 需要产生哪些规划产物，以及产物之间是什么依赖关系” | Artifact、requires、generates、template、instruction、apply |
| Config | 给现有 Workflow 加项目级上下文和规则 | context、rules、operations、默认 schema |
| Change Metadata | 固定某个 Change 的工作流身份和例外属性 | schema、goal、affected_areas、skip_specs |
| CLI/Core | 提供确定性的状态、路径、解析、校验和归档能力 | status、instructions、validate、schema which、archive |
| Artifact | 过程状态与工程知识的持久化载体 | proposal、spec、design、UT、tasks 等 |
| OMO/Workflow Engine | 决定哪个 Agent 在什么时候执行 | routing、并发、review gate、human gate |

**核心结论：Schema 是“工作产物与依赖协议”，Skill 是“Agent 执行协议”。**

官方 Schema 文档明确说明：Schema 定义 workflow 产生什么 artifacts、这些 artifacts 的格式/路径、创建顺序和 implementation handoff；默认 `spec-driven` 的 DAG 是 `proposal → specs/design → tasks → apply`。  
参考：<https://openspec.dev/docs/customize-schemas>、<https://openspec.dev/docs/schemas/schema-yaml>

---

## 3. 深入理解 OpenSpec Skill：为什么自定义 Schema 能真正驱动 Agent

### 3.1 Skill 不应该硬编码 proposal/spec/design/tasks

当前 OpenSpec Skill 的关键设计是 **schema-driven**。

以 `openspec-continue-change` 为例，Skill 会：

```text
1. 解析 Change
2. openspec status --change <name> --json
3. 从 status 获取 schemaName / artifacts / 状态 / 路径
4. 找到 ready artifact
5. openspec instructions <artifact-id> --change <name> --json
6. 使用返回的 template + instruction + dependencies + context + rules
7. 创建 artifact
8. 验证文件存在
9. 重新 status
10. 根据 DAG 继续或停止
```

这意味着 Skill 的正确行为不是：

```text
if artifact == proposal -> 写 proposal
if artifact == design   -> 写 design
if artifact == tasks    -> 写 tasks
```

而是：

```text
读取 schema
    ↓
读取 artifact graph
    ↓
读取真实 status
    ↓
读取该 artifact 的 instruction/template/dependencies
    ↓
按 schema 定义生成
```

官方当前 `openspec-propose`、`openspec-continue-change`、`openspec-update-change` 都明确要求 Agent 依据 CLI 返回的 artifact ID、路径、依赖和 instructions 工作，而不是假设固定 artifact 名称。  
参考：

- <https://github.com/Fission-AI/OpenSpec/blob/main/skills/openspec-propose/SKILL.md>
- <https://github.com/Fission-AI/OpenSpec/blob/main/skills/openspec-continue-change/SKILL.md>
- <https://github.com/Fission-AI/OpenSpec/blob/main/skills/openspec-update-change/SKILL.md>

### 3.2 Skill 与 Schema 的关系

可以把一次 Artifact 生成理解成：

```text
Schema
  |
  +-- artifact.id
  +-- artifact.generates
  +-- artifact.template
  +-- artifact.instruction
  +-- artifact.requires
  |
  v
OpenSpec instructions --json
  |
  +-- context
  +-- rules
  +-- template
  +-- instruction
  +-- dependencies
  +-- unlocks
  +-- resolvedOutputPath
  |
  v
Agent
  |
  v
Artifact file
```

尤其要注意：

- `template` 是输出结构；
- `instruction` 是如何生成该输出的专属指导；
- `context` / `rules` 是对 Agent 的约束，不应该原样写进 artifact；
- `dependencies` 告诉 Agent 需要先读哪些已完成 artifact；
- `resolvedOutputPath` 告诉 Agent 真正写入哪里；
- 对 glob artifact，真实已有文件需要从 `existingOutputPaths` 中读取，不能把 glob 字符串直接当成文件名。

这些行为已经进入当前 Skill 的显式 contract。  
参考：<https://github.com/Fission-AI/OpenSpec/blob/main/src/core/templates/workflows/propose.ts>、<https://github.com/Fission-AI/OpenSpec/blob/main/src/core/artifact-graph/instruction-loader.ts>

---

## 4. Schema 的真正核心：Artifact DAG

### 4.1 Schema 不是线性流程，而是有向无环图

最简单的 Schema：

```yaml
artifacts:
  - id: proposal
    requires: []

  - id: design
    requires:
      - proposal

  - id: tasks
    requires:
      - design
```

对应：

```text
proposal
   |
   v
 design
   |
   v
 tasks
```

而默认 `spec-driven`：

```text
                 proposal
                /        \
               v          v
            specs       design
               \          /
                \        /
                  v    v
                   tasks
                     |
                     v
                   apply
```

当前官方特别强调：

> `requires` 是 dependency/enabler，不是“必须按这个顺序唯一执行”的门闩。

因此，如果两个 artifact 都已经 ready，可以按 schema 中 `artifacts:` 声明顺序返回第一个 ready artifact，但另一个也可能同样合法地生成。

这对并行 Agent 非常重要。

### 4.2 `requires` 的真实含义

```yaml
requires:
  - acceptance
  - architecture
```

不是：

> “Agent 必须严格执行 acceptance → architecture → design 这个串行操作。”

而是：

> “只有 acceptance 与 architecture 都完成，这个 artifact 才进入 ready。”

因此：

```text
acceptance ─────┐
                ├──> design
architecture ───┘
```

可以让 acceptance 和 architecture 在满足各自前置依赖后并行准备。

官方 `status` 会返回 `done / skipped / ready / blocked` 等状态，并通过 `missingDeps` 表示阻塞原因。  
参考：<https://openspec.dev/docs/schemas/schema-yaml>

---

## 5. `schema.yaml` 完整字段模型

当前 Schema 顶层结构可以抽象成：

```yaml
name: <schema-name>
version: <positive integer>
description: <optional description>

artifacts:
  - id: <artifact-id>
    generates: <relative path or glob>
    description: <human/agent description>
    template: <relative template path>
    instruction: |
      <agent guidance>
    requires:
      - <artifact-id>

apply:
  requires:
    - <artifact-id>
  tracks: <relative markdown path or glob>
  instruction: |
    <apply guidance>
```

当前官方 `ArtifactSchema` / `SchemaYamlSchema` 对应字段包括：

- artifact：`id`、`generates`、`description`、`template`、`instruction`、`requires`
- schema：`name`、`version`、`description`、`artifacts`、`apply`
- apply：`requires`、`tracks`、`instruction`

参考源码：<https://github.com/Fission-AI/OpenSpec/blob/main/src/core/artifact-graph/types.ts>

---

## 6. 每个字段应该怎么设计

### 6.1 `name`

```yaml
name: comet-atdd
```

作用：Schema 的逻辑名称。

但一个容易忽略的实现细节是：

> **Schema 解析实际使用的是目录名，而不是 `name` 字段本身。**

例如：

```text
openspec/schemas/comet-atdd/schema.yaml
```

即使：

```yaml
name: xxx
```

OpenSpec 查找 `comet-atdd` 时仍以目录名为 lookup key。

因此团队规范必须规定：

```text
目录名 == schema 对外使用名称
```

避免人为制造混淆。

参考：<https://openspec.dev/docs/schemas/schema-yaml>

---

### 6.2 `version`

```yaml
version: 1
```

这是 Schema 的版本标识。

当前官方定义是正整数，但该字段本身**不会自动改变 OpenSpec 的执行行为**。

因此：

```text
version = metadata
```

而不是：

```text
version = automatic migration mechanism
```

对于公司平台，建议自己建立 Schema 版本治理：

```text
comet-atdd v1
comet-atdd v2
```

不要指望 OpenSpec 根据 `version` 自动迁移旧 Change。

参考：<https://openspec.dev/docs/schemas/schema-yaml>

---

### 6.3 `description`

```yaml
description: Comet ATDD workflow for UFS firmware feature development
```

主要用于 Schema 列表、选择与人类理解。

它不是 Agent 约束的核心位置。

真正的行为约束应该放到：

- artifact `instruction`
- project `context`
- project `rules`

---

## 7. `id`：Artifact 的“类型 ID”，不是文件名

例如：

```yaml
- id: acceptance
  generates: acceptance.md
```

这里：

```text
id          = acceptance
filename    = acceptance.md
```

是两个不同概念。

`id` 用于：

- `requires`
- `apply.requires`
- project config 的 `rules` key
- status 中的 artifact 标识
- instructions 返回中的依赖关系

所以建议：

```text
id 使用稳定的语义名
文件名允许独立演进
```

例如：

```text
id: ut-design
file: tests/unit-test-design.md
```

这对未来做文件重命名尤其重要。

---

## 8. `generates`：决定“产物写在哪里”以及“何时算完成”

### 8.1 单文件

```yaml
generates: design.md
```

对应：

```text
openspec/changes/<change>/design.md
```

完成条件：

```text
该文件存在
```

### 8.2 Glob

```yaml
generates: specs/**/*.md
```

对应：

```text
openspec/changes/<change>/specs/**/*.md
```

当前完成条件是：

```text
glob 至少匹配到一个文件
```

这是一个非常关键的坑。

例如：

```yaml
generates: stories/**/*.md
```

只产生一个 `stories/a.md`，OpenSpec 就可能认为该 Artifact 已完成。

因此如果你的语义实际上要求：

```text
必须生成全部 story 文件
```

不能仅靠 `generates` 表达“数量完整性”。需要在 `instruction`、模板、review/verify 机制或上层 workflow 中补充完整性规则。

### 8.3 Path 安全

当前 OpenSpec 拒绝：

- 绝对路径
- 包含 `..` 段的路径

这样可以避免 Schema 把 artifact 写到 Change 目录之外。

参考：<https://openspec.dev/docs/schemas/schema-yaml>

---

## 9. `template`：不是复制文件，而是给 Agent 的输出骨架

例如：

```yaml
template: design.md
```

真实位置：

```text
openspec/schemas/comet-atdd/templates/design.md
```

OpenSpec 会读取这个模板，并将其作为 Agent 生成 artifact 的结构输入。

它不会简单地执行：

```text
cp templates/design.md changes/xxx/design.md
```

正确理解应该是：

```text
template
   ↓
OpenSpec instructions
   ↓
Agent receives structure
   ↓
Agent fills content
   ↓
artifact
```

因此 Template 是“输出格式”，而不是“运行逻辑”。

运行逻辑应该放在 `instruction` / Skill / OMO。

参考：<https://openspec.dev/docs/schemas/schema-yaml>

---

## 10. `instruction`：Schema 定制最重要的 Agent 指导层

例如：

```yaml
instruction: |
  Create the architecture design derived from the approved acceptance criteria.
  For every acceptance criterion, identify:
  - affected behavior
  - state transitions
  - interfaces
  - data structures
  - error handling
  - unit-test implications
```

这里的意义不是：

> “把这几行文字写进 design.md”。

而是：

> “告诉生成该 artifact 的 Agent 应该采用什么思维方式和产出标准”。

### 10.1 Template 与 instruction 的职责

推荐严格分工：

```text
Template
  = 输出结构

Instruction
  = 生成方法 + 内容要求 + 判断准则
```

例如：

```text
Template:
# Design
## 1. Overview
## 2. Architecture
## 3. Interfaces
## 4. Data Structures
## 5. Error Handling
## 6. UT Design
```

Instruction：

```text
必须从 Acceptance Criteria 逐条反推设计。
每个 AC 必须至少映射到一个设计行为。
每个关键行为必须映射到实现接口和 UT。
```

两者结合以后，Agent 才能稳定产生你真正需要的设计文件。

---

## 11. `requires`：控制 planning dependency

例如：

```yaml
- id: design
  requires:
    - acceptance
    - spec
```

意味着：

```text
acceptance ──┐
             ├──> design
spec ────────┘
```

只有两个依赖都 complete，design 才是 ready。

### 11.1 不要把所有阶段强行串成链

错误示例：

```text
proposal
  ↓
requirements
  ↓
story
  ↓
acceptance
  ↓
spec
  ↓
design
  ↓
ut
  ↓
tasks
```

如果实际上：

```text
acceptance
      ↓
   ┌──┴───┐
   ↓      ↓
 design  test-analysis
   └──┬───┘
      ↓
    tasks
```

那么应该表达真实依赖，而不是为了“看起来像流程”而制造串行依赖。

### 11.2 为什么这一点对 OMO 很重要

`requires` 表达的是：

```text
Knowledge dependency
```

而 OMO 决定的是：

```text
Execution scheduling
```

两者不要混淆。

---

## 12. `apply.requires`：另一个完全不同的依赖层

这是 OpenSpec 自定义 Schema 中非常容易出错的地方。

### Artifact `requires`

控制：

```text
planning artifact 是否 ready
```

### `apply.requires`

控制：

```text
什么时候允许进入 implementation/apply
```

例如：

```yaml
apply:
  requires:
    - tasks
```

含义：

```text
tasks 不存在
  ↓
apply 不 ready
```

而不是：

```text
tasks 的上一个 artifact 必须立即执行
```

### 12.1 推荐的设计方式

如果你的最终实现前置条件是：

```text
acceptance
spec
architecture
ut-design
tasks
```

那么可以：

```yaml
apply:
  requires:
    - tasks
```

但是必须保证：

```text
tasks
 ↓
transitive dependencies
 ↓
acceptance/spec/architecture/ut-design...
```

都已经被纳入 tasks 的 `requires` 闭包。

因为当前 `propose/ff` 等流程会按“apply 所需 artifact 的传递依赖闭包”确保 implementation 所需的规划产物完整存在，而不仅仅查看 `apply.requires` 表面上的几个 ID。

参考：

- <https://github.com/Fission-AI/OpenSpec/blob/main/src/core/templates/workflows/propose.ts>
- <https://github.com/Fission-AI/OpenSpec/blob/main/src/core/templates/workflows/ff-change.ts>

---

## 13. `apply.tracks`：把 tasks 与 Apply 的进度状态连接起来

例如：

```yaml
apply:
  requires:
    - tasks
  tracks: tasks.md
```

这样：

```text
tasks.md
   |
   +-- [ ] task A
   +-- [x] task B
   +-- [ ] task C
   |
   v
Apply progress
```

当前 OpenSpec 根据 checkbox 解析任务状态。

支持多种 Markdown list marker，例如：

```text
- [ ] Task
- [x] Done
* [ ] Task
1. [ ] Task
2) [x] Done
```

### 13.1 多任务文件

也可以：

```yaml
apply:
  tracks: "**/tasks.md"
```

然后 OpenSpec 会合并匹配到的 task 文件。

### 13.2 一个非常重要的匹配要求

官方当前实现建议：

```text
apply.tracks == 某个 artifact 的 generates
```

字符串应该保持一致。

例如：

```yaml
artifact:
  generates: tasks/**/*.md

apply:
  tracks: tasks/**/*.md
```

比：

```yaml
artifact:
  generates: tasks/**/*.md

apply:
  tracks: tasks/main.md
```

更稳妥。

即便后者实际可以读文件，status/list 对“哪个 artifact 负责这个 tracked 文件”的归属判断也可能无法正确建立。

官方 schema 文档对此明确给出 warning 规则。  
参考：<https://openspec.dev/docs/schemas/schema-yaml>

---

## 14. `apply.instruction`：进入实现阶段后额外告诉 Agent 怎么做

例如：

```yaml
apply:
  requires:
    - tasks
  tracks: tasks.md
  instruction: |
    Implement tasks in dependency order.
    Run unit tests after each logical implementation group.
    Do not mark a task complete until code and tests pass.
```

它与 artifact instruction 不一样：

```text
artifact.instruction
    = 如何写规划 artifact

apply.instruction
    = 如何执行 implementation
```

因此对于你的 SSD Firmware 场景，非常适合在这里放：

```text
C / ARM coding constraints
unit-test expectations
build / static-analysis expectations
CodeGraph usage rules
firmware concurrency checks
```

但“详细领域方法论”仍建议通过独立 Domain Skill 提供，不要把所有内容塞进 apply instruction。

---

## 15. Schema Resolution：到底哪个 Schema 在生效？

这是团队协作环境最容易出问题的地方之一。

### 15.1 Schema 存放位置

OpenSpec 当前从三个层级解析 Schema：

```text
1. Project
   openspec/schemas/<name>/

2. User
   ~/.local/share/openspec/schemas/<name>/
   （Linux/macOS；XDG_DATA_HOME 可改变位置）

3. Package
   OpenSpec 内置 schema
```

先找到的优先。

因此：

```text
Project > User > Package
```

### 15.2 CLI / Metadata / Config 的优先级

当某个 Change 需要确定使用哪个 Schema 时，当前解析层次还包括：

```text
CLI --schema
   ↓
Change .openspec.yaml
   ↓
Project openspec/config.yaml
   ↓
Default spec-driven
```

一个特别重要的属性是：

> Change 创建时会把 schema 写入 `.openspec.yaml`，以后即使 `openspec/config.yaml` 改了，这个旧 Change 仍保持原来的 Schema。

这正是为了保证历史 Change 的 workflow 不漂移。

参考：

- <https://openspec.dev/docs/configuration/change-metadata>
- <https://openspec.dev/docs/customize-schemas>
- <https://openspec.dev/docs/configuration/config-yaml>

### 15.3 排查 Schema 是否生效

使用：

```bash
openspec schema which <schema-name>
openspec schema which --all
```

例如：

```text
Schema: comet-atdd
Source: project
Path: /repo/openspec/schemas/comet-atdd

Shadows:
  package: .../openspec/schemas/comet-atdd
```

推荐把这个命令加入 Schema 调试 checklist。

---

## 16. Project Config 与 Custom Schema 的边界

OpenSpec 官方把二者明确分成两级定制：

### 16.1 Config：轻量覆盖

```yaml
schema: spec-driven

context: |
  Project uses C on ARM Cortex-R.
  All design artifacts must cover concurrency.

rules:
  design:
    - Every major behavior must map to a UT case.
  tasks:
    - Every implementation group must include tests.

operations:
  apply:
    guidance:
      - Run unit tests before completing a task.
```

Config 能做：

- 增加 project context
- 增加 artifact-specific rules
- 增加 apply/archive guidance
- 设置默认 schema

### 16.2 Config 做不到的事情

Config 不能稳定表达：

```text
我要新增一个 artifact
我要删除 design
我要把 design 改成 ut-design
我要新增 acceptance → design 的强依赖
我要把 workflow 改成 requirements → acceptance → design → UT → tasks
```

这些属于 Schema 层。

因此判断标准非常简单：

```text
只想增加规则       → config.yaml
想改变工作产物/依赖 → custom schema
```

参考：<https://openspec.dev/docs/customize>

---

# 17. Custom Schema 完整生命周期流程

下面给出推荐的标准流程。

```text
                +--------------------+
                | 1. 明确工作流目标  |
                +---------+----------+
                          |
                          v
                +--------------------+
                | 2. 判断 Config 是否|
                |    已足够           |
                +---------+----------+
                          |
                    不足  |
                          v
                +--------------------+
                | 3. 选择 Fork / Init |
                +---------+----------+
                          |
                          v
                +--------------------+
                | 4. 建立 artifact DAG|
                +---------+----------+
                          |
                          v
                +--------------------+
                | 5. 设计模板         |
                +---------+----------+
                          |
                          v
                +--------------------+
                | 6. 编写 instruction  |
                +---------+----------+
                          |
                          v
                +--------------------+
                | 7. 配置 apply       |
                +---------+----------+
                          |
                          v
                +--------------------+
                | 8. Schema Validate   |
                +---------+----------+
                          |
                          v
                +--------------------+
                | 9. 指定为默认 Schema |
                +---------+----------+
                          |
                          v
                +--------------------+
                | 10. 创建试验 Change  |
                +---------+----------+
                          |
                          v
                +--------------------+
                | 11. 运行/观察状态    |
                +---------+----------+
                          |
                          v
                +--------------------+
                | 12. Review / Verify  |
                +---------+----------+
                          |
                          v
                +--------------------+
                | 13. 形成团队版本基线 |
                +--------------------+
```

下面逐步展开。

---

# 18. Step 1：定义为什么需要 Custom Schema

先不要直接执行：

```bash
openspec schema fork ...
```

先回答：

```text
默认 spec-driven 为什么不够？
```

建议以差异表方式判断：

| 要求 | 默认 Schema | Config 能解决吗 | 是否需要 Custom Schema |
|---|---|---:|---:|
| tasks 必须包含 UT | 可以补规则 | ✅ | ❌ |
| 所有设计写中文 | 可以补 context | ✅ | ❌ |
| 增加 Acceptance artifact | 无 | ❌ | ✅ |
| 增加 UT Design artifact | 无 | ❌ | ✅ |
| 删除 proposal | 不支持仅靠 config | ❌ | ✅ |
| 改变依赖 DAG | 无法 | ❌ | ✅ |
| 改变 artifact 文件结构 | 无法 | ❌ | ✅ |
| 调整 apply 入口 | 有限 | 部分 | 视情况 |

**原则：不要为了“看起来高级”而创建 Custom Schema。**

Schema 是 workflow contract，过度定制会提高维护成本。

---

# 19. Step 2：选择 Fork 还是 Init

OpenSpec 当前提供：

```bash
openspec schema fork <source> <name>
```

和：

```bash
openspec schema init <name>
```

## 19.1 推荐优先 Fork

如果你的工作流和 `spec-driven` 仍然有明显共性：

```bash
openspec schema fork spec-driven comet-atdd
```

它会复制：

```text
schema.yaml
templates/proposal.md
templates/spec.md
templates/design.md
templates/tasks.md
```

然后你在自己的副本上改。

优点：

- 保留成熟的 artifact 定义
- 保留成熟的 prompts/instructions
- 保留任务追踪
- 更容易从默认行为演进

官方也把 Fork 定义为最推荐的起点：已有 schema 足够接近时，从现成 schema 复制比从零更安全。  
参考：<https://openspec.dev/docs/customize-schemas>

## 19.2 什么时候 Init

当目标 workflow 从根本上不同，例如：

```text
research → benchmark → recommendation → decision
```

而不是：

```text
proposal → specs → design → tasks
```

此时：

```bash
openspec schema init research-first
```

更干净。

但当前 `schema init` 的 CLI scaffold 只从内置四个 artifact ID 的选择中生成初始骨架，而且生成的模板本身很“裸”，没有完整领域 instruction。因此真正做企业级 Schema 时，通常仍需要手工完善 `schema.yaml` 和模板。  
参考：<https://openspec.dev/docs/customize-schemas>

---

# 20. Step 3：Fork Default Schema

推荐命令：

```bash
cd <project-root>
openspec schema fork spec-driven comet-atdd
```

得到：

```text
openspec/
└── schemas/
    └── comet-atdd/
        ├── schema.yaml
        └── templates/
            ├── proposal.md
            ├── spec.md
            ├── design.md
            └── tasks.md
```

先不要直接大改。

第一步应当是：

```bash
openspec schema validate comet-atdd
```

确保基线副本本身是健康的。

---

# 21. Step 4：设计 Artifact DAG

这是整个 Custom Schema 最重要的设计工作。

### 21.1 先定义“工程语义”，再定义文件

不要先问：

```text
我要几个 md？
```

应该先问：

```text
一个变更从需求到代码，需要哪些不可缺失的知识节点？
```

例如 UFS Firmware ATDD：

```text
Requirement
     |
     v
Acceptance
     |
     +----------------+
     |                |
     v                v
   Spec           Architecture
     |                |
     +-------+--------+
             v
         Design Review
             |
             v
          UT Design
             |
             v
           Tasks
             |
             v
           Apply
```

### 21.2 再压缩成真正需要持久化的 Artifact

不是每个思考过程都应该成为 artifact。

例如：

```text
brainstorming discussion
```

可能只是 OMO/Explore 的 transient state。

而：

```text
acceptance criteria
architecture decision
unit-test plan
implementation tasks
```

属于需要复用、审查、恢复的持久知识。

因此建议：

```text
Transient reasoning → Agent/OMO
Durable engineering state → OpenSpec Artifact
```

---

# 22. Step 5：设计 Artifact 的 `requires`

建立依赖矩阵：

| Artifact | depends on | 是否允许并行 |
|---|---|---:|
| requirement | — | — |
| acceptance | requirement | 否 |
| spec | acceptance | 否 |
| architecture | acceptance | 可与 spec 并行 |
| design | spec + architecture | 否 |
| ut-design | design | 否 |
| tasks | design + ut-design | 否 |
| apply | tasks 闭包 | 否 |

然后写成：

```yaml
artifacts:
  - id: requirement
    requires: []

  - id: acceptance
    requires:
      - requirement

  - id: spec
    requires:
      - acceptance

  - id: architecture
    requires:
      - acceptance

  - id: design
    requires:
      - spec
      - architecture

  - id: ut-design
    requires:
      - design

  - id: tasks
    requires:
      - design
      - ut-design
```

这已经不是“文档列表”，而是一张**工程知识依赖图**。

---

# 23. Step 6：设计每个 Artifact 的 `generates`

推荐：

```yaml
requirement:
  generates: requirement.md

acceptance:
  generates: acceptance.md

spec:
  generates: specs/**/*.md

architecture:
  generates: architecture.md

design:
  generates: design.md

ut-design:
  generates: test/unit-test-design.md

tasks:
  generates: tasks.md
```

原则：

### 能单文件就单文件

因为状态判断最清晰。

### 一个语义单元天然多文件时再使用 glob

比如：

```text
一个 capability 一个 spec 文件
```

才适合：

```yaml
generates: specs/**/*.md
```

不要为了未来可能扩展，就把所有东西都设计成 glob。

---

# 24. Step 7：设计 Template

推荐每个 Template 只负责：

```text
章节结构
必要表格
必要字段
占位说明
```

例如 `ut-design.md`：

```markdown
# Unit Test Design

## 1. Test Scope

## 2. Test Matrix

| AC | Behavior | Test ID | Setup | Stimulus | Expected Result |
|---|---|---|---|---|---|

## 3. Boundary Cases

## 4. Error Cases

## 5. State Transition Cases

## 6. Concurrency Cases

## 7. Mock / Stub Strategy

## 8. Coverage Gaps

## 9. Traceability
```

模板本身不要塞大量“怎么思考”的长段落。

长规则应该放到：

```text
instruction
```

或：

```text
project config rules
```

否则模板很快变成一份难维护的巨型 Prompt。

---

# 25. Step 8：设计 `instruction`

建议把 Instruction 分成五类：

```text
A. 输入依赖
B. 思考方法
C. 输出内容
D. 完整性要求
E. 禁止行为
```

例如：

```yaml
instruction: |
  Input dependencies:
  - Read all completed dependency artifacts before drafting.

  Method:
  - Derive the design from approved acceptance criteria.
  - Do not invent behavior not supported by requirements.
  - For each AC, identify the affected behavior and implementation responsibility.

  Required content:
  - module boundaries
  - interfaces
  - data structures
  - state transitions
  - error handling
  - concurrency assumptions
  - unit-test implications

  Completeness:
  - Every acceptance criterion must map to one or more design decisions.
  - Every externally observable behavior must map to at least one verification path.

  Prohibited:
  - Do not edit implementation code.
  - Do not silently weaken acceptance criteria.
```

这类 Instruction 才真正体现公司的工程方法论。

---

# 26. Step 9：设计 Apply Contract

推荐：

```yaml
apply:
  requires:
    - tasks
  tracks: tasks.md
  instruction: |
    Implement only the approved tasks.
    Before marking a task complete:
    - compile the affected target
    - run the relevant unit tests
    - verify no acceptance criterion is regressed
    - record any deviation in the change artifacts
```

这里建议重点关注：

```text
任务完成标准
测试完成标准
偏差处理标准
```

而不是重复定义整个设计流程。

---

# 27. Step 10：运行 Schema Validate

任何 Schema 手工修改后都必须执行：

```bash
openspec schema validate comet-atdd
```

更详细：

```bash
openspec schema validate comet-atdd --verbose
```

需要重点检查：

1. `schema.yaml` YAML 是否正确；
2. artifact ID 是否唯一；
3. `requires` 引用是否全部存在；
4. 是否存在 dependency cycle；
5. `apply.requires` 引用是否存在；
6. template 文件是否全部存在；
7. 路径是否违反相对路径规则；
8. `apply.tracks` 是否与 artifact `generates` 对齐。

当前官方 CLI 对 `apply.tracks` 的不匹配会给 warning 而不是直接失败，因此这个问题仍需要在团队 review checklist 中显式检查。  
参考：<https://openspec.dev/docs/cli>、<https://openspec.dev/docs/schemas/schema-yaml>

---

# 28. Step 11：将 Schema 设置为项目默认

在：

```text
openspec/config.yaml
```

写：

```yaml
schema: comet-atdd
```

或者创建 Schema 时：

```bash
openspec schema init comet-atdd --default
```

对于 Fork，官方流程不会自动修改现有 `config.yaml`，因此通常需要手工指向新 Schema。  
参考：<https://openspec.dev/docs/customize-schemas>

---

# 29. Step 12：验证“新 Change 会使用新 Schema”

不要认为改完 config 就万事大吉。

执行：

```bash
openspec schemas
openspec schema which comet-atdd
```

然后创建测试 Change：

```bash
openspec new change demo-comet-schema
```

查看：

```bash
openspec status --change demo-comet-schema --json
```

确认：

```json
{
  "schemaName": "comet-atdd"
}
```

然后再：

```bash
openspec instructions <first-artifact-id> --change demo-comet-schema --json
```

确认返回的：

- `template`
- `instruction`
- `context`
- `rules`
- `resolvedOutputPath`
- `dependencies`

全部符合预期。

这一层是验证“Agent 看到的真实 contract”，比只打开 schema.yaml 看一眼更可靠。

---

# 30. Step 13：验证 Artifact State Machine

建议用一个最小实验 Change 完整跑一遍：

```text
初始
  ↓
artifact A = ready
artifact B = blocked
artifact C = blocked
```

生成 A 后：

```text
A = done
B = ready
C = blocked
```

生成 B 后：

```text
A = done
B = done
C = ready
```

这样可以证明 DAG 与你的理解一致。

推荐命令：

```bash
openspec status --change demo-comet-schema --json
```

尤其检查：

```text
artifacts[].status
artifacts[].requires
artifacts[].missingDeps
artifactPaths
applyRequires
```

官方当前 Agent Contract 已经把这些字段定义为机器可消费接口。  
参考：<https://github.com/Fission-AI/OpenSpec/blob/main/docs/agent-contract.md>

---

# 31. Step 14：验证 Skill 与 Custom Schema 的兼容性

这是企业场景必须做的一轮测试。

需要至少测试：

```text
/opsx:explore
/opsx:propose
/opsx:continue
/opsx:update
/opsx:apply
/opsx:verify
/opsx:sync
/opsx:archive
```

尤其关注：

### Propose

必须：

```text
按 schema 生成全部 implementation 所需 artifact
```

而不是固定生成 proposal/spec/design/tasks。

### Continue

必须：

```text
每次只创建一个 ready artifact
```

### Update

必须：

```text
基于 status 返回的 artifact id/path
修改已有 artifact
而不是硬编码 design.md/tasks.md
```

### Apply

必须：

```text
识别 schema.apply.requires
读取 schema 产生的真实规划文档
使用 tracks 文件推进任务状态
```

### Verify

必须：

```text
验证 implementation 与自定义 artifact 的要求是否一致
```

当前官方 Skill 明确要求 custom schemas 不应依赖固定 artifact 名称。  
参考：

- <https://github.com/Fission-AI/OpenSpec/blob/main/skills/openspec-propose/SKILL.md>
- <https://github.com/Fission-AI/OpenSpec/blob/main/skills/openspec-continue-change/SKILL.md>
- <https://github.com/Fission-AI/OpenSpec/blob/main/skills/openspec-update-change/SKILL.md>
- <https://github.com/Fission-AI/OpenSpec/blob/main/skills/openspec-apply-change/SKILL.md>
- <https://github.com/Fission-AI/OpenSpec/blob/main/skills/openspec-verify-change/SKILL.md>

---

# 32. Step 15：建立 Change 的 Schema 固化机制

一个项目切换默认 Schema 后：

```text
新 Change
  → 使用新默认 Schema
```

但：

```text
旧 Change
  → 保留创建时的 Schema
```

这是由 Change Metadata 的：

```yaml
schema: comet-atdd
```

实现的。

因此：

```text
config.yaml
```

是：

```text
default for new changes
```

而：

```text
.openspec.yaml
```

是：

```text
per-change workflow identity
```

这也是企业级升级时非常重要的隔离机制。

---

# 33. Step 16：把 Schema 纳入 Git 版本管理

推荐目录：

```text
repo/
├── openspec/
│   ├── config.yaml
│   ├── schemas/
│   │   └── comet-atdd/
│   │       ├── schema.yaml
│   │       └── templates/
│   │           ├── requirement.md
│   │           ├── acceptance.md
│   │           ├── spec.md
│   │           ├── architecture.md
│   │           ├── design.md
│   │           ├── ut-design.md
│   │           └── tasks.md
│   ├── specs/
│   └── changes/
```

项目级 Schema 被官方明确推荐，因为它可以与代码一起版本化，团队成员拿到仓库后使用同一份 workflow。  
参考：<https://openspec.dev/docs/customize-schemas>

---

# 34. Schema 的“版本升级”应该怎么做

当前 `version` 字段只是元数据，因此公司层面建议把 Schema 升级设计成两种情况。

## 34.1 非破坏性修改

例如：

```text
增加 design template 一节
增强 instruction
修订术语
```

可以继续使用：

```text
comet-atdd
version: 1 → 1
```

或者更新 metadata 到：

```yaml
version: 2
```

但需要确认旧 Change 是否仍可正常继续。

## 34.2 破坏性修改

例如：

```text
删除 acceptance
新增 approval
改变 dependency DAG
改变 apply tracks
改变 artifact meaning
```

推荐新建：

```text
comet-atdd-v2
```

然后：

```text
新 Change → v2
旧 Change → v1
```

不要直接把一个正在进行的旧 Change“热切换”到全新的 DAG。

这是因为旧 Change 的 `.openspec.yaml` 固定了原 Schema，且 artifact 文件结构本身可能已经与旧 Schema 绑定。

---

# 35. Fork 是 Snapshot，不是 Upstream Tracking

这是官方当前文档特别提醒的一个点。

执行：

```bash
openspec schema fork spec-driven comet-atdd
```

只是复制当前版本。

以后：

```bash
openspec update
```

不会自动更新你的：

```text
openspec/schemas/comet-atdd/
```

所以你的 Schema 会天然形成一个 snapshot。

这意味着 OpenSpec 官方 schema 后续增加能力时，你不会自动得到。

升级方式不是：

```text
自动 merge
```

而应该：

```text
发现 upstream 新版
      ↓
重新 fork / 比较
      ↓
提取 upstream 改动
      ↓
迁移公司定制
      ↓
重新 validate
      ↓
回归测试
```

这是公司级平台需要单独建立的 Schema Maintenance 流程。

参考：<https://openspec.dev/docs/customize-schemas>

---

# 36. 推荐建立 Schema Regression Test

不要只测：

```bash
openspec schema validate
```

还应该建立自动化回归测试。

例如：

```text
schema-regression/
├── cases/
│   ├── minimal-change/
│   ├── multi-capability-change/
│   ├── skip-spec-change/
│   └── parallel-ready-change/
└── expected/
```

每次 Schema 修改后执行：

```text
1. 创建临时 Change
2. status --json
3. instructions --json
4. 生成 artifact
5. status --json
6. apply instructions
7. verify
```

重点检查：

```text
Artifact 数量
Artifact IDs
DAG
Ready/blocked 状态
Output paths
Templates
Instructions
Apply gate
Task tracking
```

这样 Schema 才真正成为：

```text
可测试的软件工程基础设施
```

而不是一套人工维护的 Markdown。

---

# 37. `skip_specs` 与 Custom Schema 的关系

当前 OpenSpec 的 Change Metadata 支持：

```yaml
skip_specs: true
```

语义是：

> 该 Change 不产生 spec-level delta，例如纯 refactor / tooling / docs change。

当自定义 Schema 中某个 artifact 的 `generates` 落在 `specs/` 下时，`skip_specs` 会导致相关 artifact 被标记为 `skipped` 而非要求创建文件。

这一点对于公司 Schema 很重要：

如果你有：

```text
spec
```

作为一个正式 artifact，则需要确认你的 Schema instruction 能正确处理：

```text
skip_specs
```

否则容易出现：

```text
Metadata 说不要 spec
Agent 却收到“创建 spec”指令
```

当前 OpenSpec 已对这种状态做了专门处理，但企业自定义 Schema 仍应在回归测试中覆盖。

参考：<https://openspec.dev/docs/configuration/change-metadata>、<https://github.com/Fission-AI/OpenSpec/blob/main/src/core/artifact-graph/instruction-loader.ts>

---

# 38. 一个适合 Comet + ATDD 的 Custom Schema 示例

下面给出一个“示意设计”，用于说明如何将本文原则落地。

```yaml
name: comet-atdd
version: 1
description: Comet ATDD workflow for UFS firmware feature development

artifacts:
  - id: requirement
    generates: requirement.md
    description: Clarified and bounded requirement for the change
    template: requirement.md
    instruction: |
      Capture the concrete requirement scope, assumptions, constraints,
      non-goals, dependencies, and externally observable behavior.
      Do not design implementation details here.
    requires: []

  - id: acceptance
    generates: acceptance.md
    description: Acceptance criteria and executable scenarios
    template: acceptance.md
    instruction: |
      Derive acceptance criteria from the requirement.
      Every criterion must be observable and testable.
      Use explicit scenarios with trigger, condition, expected behavior,
      error behavior, and boundary conditions.
    requires:
      - requirement

  - id: spec
    generates: specs/**/*.md
    description: Behavioral delta specifications derived from acceptance criteria
    template: spec.md
    instruction: |
      Translate approved acceptance criteria into OpenSpec behavioral deltas.
      Do not introduce implementation-specific constraints unless required
      by externally observable behavior.
    requires:
      - acceptance

  - id: architecture
    generates: architecture.md
    description: High-level architecture derived from accepted behavior
    template: architecture.md
    instruction: |
      Reverse-infer architecture from acceptance criteria and behavioral specs.
      Identify modules, ownership, interfaces, state transitions,
      data flow, timing, concurrency, and error boundaries.
    requires:
      - acceptance

  - id: design
    generates: design.md
    description: Detailed technical design
    template: design.md
    instruction: |
      Produce detailed implementation design from completed specs and architecture.
      Every acceptance criterion must map to one or more design decisions.
      Cover module boundaries, APIs, data structures, state machines,
      concurrency, error handling, and integration behavior.
      Do not edit source code.
    requires:
      - spec
      - architecture

  - id: ut-design
    generates: test/unit-test-design.md
    description: Unit test design and traceability
    template: ut-design.md
    instruction: |
      Design unit tests from acceptance criteria and detailed design.
      Build explicit AC -> behavior -> test-case traceability.
      Cover normal, boundary, error, state-transition, and concurrency cases.
      Identify mock/stub requirements and coverage gaps.
    requires:
      - design

  - id: tasks
    generates: tasks.md
    description: Implementation tasks derived from approved design and UT design
    template: tasks.md
    instruction: |
      Break the approved design into implementation tasks.
      Every task must identify affected modules and required tests.
      Tasks must be small enough for one coding agent iteration.
      Do not invent work that is not justified by prior artifacts.
    requires:
      - design
      - ut-design

apply:
  requires:
    - tasks
  tracks: tasks.md
  instruction: |
    Implement only the approved tasks.
    Use project coding conventions and available code knowledge tools.
    Before marking a task complete, run the relevant build and test checks.
    Record deviations in the change artifacts instead of silently changing scope.
```

这个 Schema 最关键的地方不是 artifact 名称，而是：

```text
Requirement
   ↓
Acceptance
   ↓
Spec + Architecture
   ↓
Design
   ↓
UT Design
   ↓
Tasks
   ↓
Apply
```

它把之前讨论的“AC → Design 逆推 → UT → Build Task”真正固化到了 Artifact DAG 中。

---

# 39. 但上面这个 Schema 还不能单独完成企业级方法论

这里必须划清边界。

### Schema 适合表达

```text
需要哪些产物
哪些产物依赖哪些产物
产物写在哪里
每种产物采用什么模板
Agent 创建该产物时必须遵守什么方法
什么时候允许 Apply
Apply 跟踪哪个任务文件
```

### Schema 不适合承担

```text
如何从 CodeGraph 调代码图
如何调用 OpenViking
如何选择 OMO Agent
何时并行执行 Agent
人工审批如何交互
Hook 如何触发
如何重试失败 Agent
如何对多个 Story 做 Wave 调度
如何做公司级知识检索
```

这些分别属于：

```text
Domain Skills
Tool / MCP
OMO / Workflow Engine
OpenCode Hooks
Human-in-the-loop
```

因此不应该把所有东西塞进 Schema 的 `instruction`。

---

# 40. Schema、Skill、OMO、Hook 的最终边界

建议最终采用：

```text
                        Comet
                         |
        +----------------+----------------+
        |                                 |
        v                                 v
   OMO / Workflow Engine             OpenCode Hooks
        |                                 |
        | 决定谁执行、何时执行             | 自动触发、守护与检查
        |                                 |
        +----------------+----------------+
                         |
                         v
                   OpenSpec Skill
                         |
                         | 按真实 schema contract 工作
                         v
                    Custom Schema
                         |
          +--------------+--------------+
          |              |              |
          v              v              v
       Template      Instruction      DAG
          |              |              |
          +--------------+--------------+
                         |
                         v
                   Durable Artifacts
                         |
                         v
                   Build / Verify
```

一句话：

> **OMO 决定“谁、何时做”；OpenSpec Skill 决定“Agent 如何按 OpenSpec 工作”；Schema 决定“需要产生哪些工程知识”；Template 决定“长什么样”；Instruction 决定“应该怎么写”；Hook 负责“自动触发/守护”；Domain Skill 负责“专业能力”。**

---

# 41. 对你的 Comet 平台，建议不要直接把整个 Comet 五阶段塞进一个 Schema

更合理的方式是：

```text
Comet
 |
 +-- PRD / Requirement Decomposition
 |
 +-- Wave / Story Scheduling
 |
 +-- OpenSpec Custom Schema
 |      |
 |      +-- Requirement
 |      +-- Acceptance
 |      +-- Spec
 |      +-- Design
 |      +-- UT Design
 |      +-- Tasks
 |      +-- Apply
 |
 +-- Verify / Review
 |
 +-- Archive / Knowledge update
```

原因是：

```text
Comet = product/workflow orchestration
OpenSpec = change/artifact protocol
```

如果把两者完全融合：

```text
Schema 会变成巨型 workflow engine
```

后续会很难维护。

---

# 42. OMO Team Mode 与 Custom Schema 的推荐协作方式

推荐采用：

```text
                 OMO Coordinator
                        |
            +-----------+-----------+
            |           |           |
            v           v           v
       Explore Agent  Review Agent  Domain Agent
            |           |           |
            +-----------+-----------+
                        |
                        v
                 Approved Input
                        |
                        v
                  OpenSpec Artifact
```

并遵循一个非常重要的原则：

> **并行 reasoning，串行 artifact write。**

例如：

```text
3 个 Agent 并行研究 Design
        ↓
Coordinator 汇总
        ↓
Design Agent 唯一写 design.md
        ↓
Review Agent 审查
```

不要让：

```text
Agent A/B/C 同时编辑同一个 design.md
```

否则 Schema 的 Artifact 状态虽然是确定性的，文件写入本身仍然会发生竞争。

---

# 43. Review 应该放在哪里？Schema 能否表达？

可以部分表达，但不建议全部依靠 Schema。

例如：

```text
Design
   ↓
Design Review
   ↓
UT Design
```

你可以把：

```text
design-review.md
```

做成一个 Artifact：

```yaml
- id: design-review
  generates: design-review.md
  requires:
    - design
```

但是 Schema 只能表达：

```text
review artifact 依赖 design
```

它不能天然表达：

```text
“只有 Review Agent 通过并且 status=approved，Coordinator 才能继续”
```

这属于：

```text
Agent orchestration / external gate
```

因此推荐：

```text
Schema = review artifact dependency
OMO = review decision gate
```

---

# 44. 人工审批同样不要硬塞进 Schema

例如：

```text
Design 完成
   ↓
Human Review
   ↓
approved?
   ├── yes → UT Design
   └── no  → Update Design
```

OpenSpec 可以保存：

```text
design.md
review.md
```

但是：

```text
Human approval state
```

最好交给：

```text
OMO / Workflow Engine
```

否则 Schema 很快就会变成一种半成品的状态机，而 OMO 又会重复实现同一套状态机。

---

# 45. Custom Schema 开发完成后的验收清单

## Schema 本身

- [ ] `schema.yaml` 能通过 validate
- [ ] 所有 template 存在
- [ ] 所有 `requires` 引用存在
- [ ] 无 cycle
- [ ] `apply.requires` 合法
- [ ] `apply.tracks` 与 task artifact 对齐
- [ ] 所有路径都是相对路径
- [ ] schema directory 名称与 lookup name 一致

## Agent Contract

- [ ] status 能正确识别 artifact 状态
- [ ] ready/blocked 与预期一致
- [ ] instructions --json 返回正确 template
- [ ] instructions --json 返回正确 instruction
- [ ] dependencies 正确
- [ ] resolvedOutputPath 正确
- [ ] glob artifact 能正确解析

## Skill

- [ ] propose 支持 Custom Schema
- [ ] continue 支持 Custom Schema
- [ ] update 不依赖硬编码 artifact 名
- [ ] apply 支持 Custom Schema
- [ ] verify 支持 Custom Schema
- [ ] archive/sync 行为与 Schema 预期一致

## 团队工程

- [ ] Schema 提交 Git
- [ ] 有版本号/演进策略
- [ ] 有 regression test
- [ ] 有 review checklist
- [ ] 有 upstream OpenSpec 更新同步策略
- [ ] 有旧 Change 的兼容策略

---

# 46. 常见错误与对应修正

### 错误 1：直接修改 `spec-driven` 内置 Schema

不要这样做。

应该：

```bash
openspec schema fork spec-driven comet-atdd
```

因为内置 Schema 属于 OpenSpec package。

---

### 错误 2：以为 `version: 2` 会自动迁移

不会。

当前 `version` 主要是 metadata。

---

### 错误 3：把 Template 当 Prompt

Template 负责结构，Instruction 负责生成行为。

---

### 错误 4：把所有工程规则写进 instruction

应该分层：

```text
通用项目事实 → context
artifact-specific rules → config.rules
Schema-specific workflow semantics → schema instruction
Domain reasoning → Domain Skill
Orchestration → OMO
```

---

### 错误 5：使用 Glob 后以为 OpenSpec 会检查“所有文件都齐了”

默认完成条件是：glob 至少匹配到文件。

完整性必须由更高层规则/Review/Verify 解决。

---

### 错误 6：把 `apply.requires` 当成 planning DAG

它只是 implementation readiness gate。

真正的 planning DAG 在：

```yaml
artifacts[].requires
```

---

### 错误 7：`apply.tracks` 和 `generates` 不一致

可能导致 OpenSpec 无法把任务进度正确归属给相应 Artifact。

---

### 错误 8：Schema 改完没有创建真实 Change 验证

`validate` 只能证明 Schema 结构有效。

不能证明：

```text
Agent 实际拿到的 instructions
```

是正确的。

一定要实际跑：

```bash
status --json
instructions --json
```

---

# 47. 推荐的企业级 Custom Schema 工作流程

最终推荐把整个 Schema 管理做成：

```text
需求
 ↓
判断是否 Config 足够
 ↓
不足
 ↓
Fork / Init
 ↓
定义 Artifact Semantic Model
 ↓
定义 DAG
 ↓
定义 generates
 ↓
定义 templates
 ↓
定义 instructions
 ↓
定义 apply contract
 ↓
Schema validate
 ↓
真实 Change 演练
 ↓
status / instructions 检验
 ↓
OMO / Agent 回归
 ↓
Code + Test 回归
 ↓
Git Review
 ↓
发布 Schema Baseline
```

发布后：

```text
Schema Baseline
      |
      +-- Project config
      +-- Templates
      +-- Instructions
      +-- Regression cases
      +-- Changelog
      +-- Compatibility policy
```

这样 Schema 才能真正成为公司的 AI Engineering Infrastructure。

---

# 48. 对当前 UFS Firmware 平台的最终建议

结合 Comet + OpenCode + OMO + ATDD + TDD + CodeGraph + OpenViking 的整体设计，推荐第一版不要一次做到极端复杂。

建议分两步。

## Phase 1：最小企业可用 Schema

```text
requirement
    ↓
acceptance
    ↓
spec
    ↓
design
    ↓
ut-design
    ↓
tasks
    ↓
apply
```

额外由 OMO 管：

```text
Explore
Review
Human Gate
Wave
Agent Dispatch
```

这已经可以把：

```text
ATDD AC
   ↓
Design Reverse Inference
   ↓
UT Design
   ↓
Build Task
```

真正固化下来。

## Phase 2：增加企业级治理

再增加：

```text
architecture-review
risk-analysis
implementation-review
verification-report
traceability
```

但这些应该根据 Phase 1 实际运行数据决定，不建议一开始就全部塞进 Schema。

---

# 49. 最终结论

OpenSpec Custom Schema 的真正价值不是“多写几个 Markdown 文件”，而是把 AI 软件开发过程中的隐性知识依赖变成显式、持久、可检查的 Artifact Graph：

```text
                   Engineering Intent
                          |
                          v
                       Artifact
                          |
                 +--------+--------+
                 |                 |
              Template         Instruction
                 |                 |
                 +--------+--------+
                          |
                          v
                     Agent Output
                          |
                          v
                    Artifact State
                          |
                          v
                     Dependency DAG
                          |
                          v
                     Apply Readiness
```

因此，在你的平台中最推荐的职责划分是：

```text
Comet
  = 总体研发流程

OMO
  = 多 Agent 编排与 Human-in-the-loop

OpenCode Hooks
  = 自动触发、守护、状态联动

OpenSpec Skill
  = Agent 的 OpenSpec 执行协议

Custom Schema
  = 研发产物模型 + 依赖 DAG + Agent artifact instructions

ATDD/TDD Skills
  = 方法论与工程推理能力

CodeGraph/OpenViking
  = 代码与知识上下文

Build/Verify
  = 实施和最终验证
```

其中最关键的一条原则是：

> **不要把 OpenSpec Custom Schema 当成第二个 Workflow Engine。**

Schema 应该尽可能只负责：

```text
“这个 Change 必须形成哪些工程事实，
这些事实之间有什么依赖，
Agent 生成这些事实时遵守什么规则，
以及什么时候具备进入实现阶段的条件。”
```

而：

```text
“哪个 Agent 来做、几个 Agent 并行、什么时候 Review、什么时候停下来等人、失败怎么重试”
```

应继续由 Comet / OMO / OpenCode Hooks 负责。

这条边界一旦建立，OpenSpec 就会成为 Comet 的一个稳定“Change Protocol”，而不是另起一个与 Comet 竞争的流程系统。

---

# 50. 官方参考资料

以下链接是本文主要依据，建议在实际实施前重新检查对应版本：

1. OpenSpec Customization 总览  
   <https://openspec.dev/docs/customize>

2. OpenSpec Schemas  
   <https://openspec.dev/docs/customize-schemas>

3. `schema.yaml` 字段参考  
   <https://openspec.dev/docs/schemas/schema-yaml>

4. Project `config.yaml`  
   <https://openspec.dev/docs/configuration/config-yaml>

5. Change `.openspec.yaml` Metadata  
   <https://openspec.dev/docs/configuration/change-metadata>

6. OpenSpec CLI  
   <https://openspec.dev/docs/cli>

7. OpenSpec Profiles  
   <https://openspec.dev/docs/profiles>

8. OpenSpec Skills  
   <https://openspec.dev/docs/skills>

9. `openspec-propose` Skill  
   <https://github.com/Fission-AI/OpenSpec/blob/main/skills/openspec-propose/SKILL.md>

10. `openspec-continue-change` Skill  
    <https://github.com/Fission-AI/OpenSpec/blob/main/skills/openspec-continue-change/SKILL.md>

11. `openspec-update-change` Skill  
    <https://github.com/Fission-AI/OpenSpec/blob/main/skills/openspec-update-change/SKILL.md>

12. `openspec-apply-change` Skill  
    <https://github.com/Fission-AI/OpenSpec/blob/main/skills/openspec-apply-change/SKILL.md>

13. `openspec-verify-change` Skill  
    <https://github.com/Fission-AI/OpenSpec/blob/main/skills/openspec-verify-change/SKILL.md>

14. Artifact Graph instruction loader  
    <https://github.com/Fission-AI/OpenSpec/blob/main/src/core/artifact-graph/instruction-loader.ts>

15. Artifact Graph types  
    <https://github.com/Fission-AI/OpenSpec/blob/main/src/core/artifact-graph/types.ts>

---

## 附录 A：推荐的实际操作命令序列

### A.1 Fork 默认 Schema

```bash
openspec schema fork spec-driven comet-atdd
```

### A.2 编辑 Schema

```text
openspec/schemas/comet-atdd/schema.yaml
openspec/schemas/comet-atdd/templates/*
```

### A.3 验证

```bash
openspec schema validate comet-atdd --verbose
```

### A.4 查看解析来源

```bash
openspec schema which comet-atdd
```

### A.5 设置项目默认 Schema

```yaml
# openspec/config.yaml
schema: comet-atdd
```

### A.6 创建测试 Change

```bash
openspec new change demo-comet-schema
```

### A.7 查看真实状态

```bash
openspec status --change demo-comet-schema --json
```

### A.8 获取真实 Artifact Contract

```bash
openspec instructions <artifact-id> --change demo-comet-schema --json
```

### A.9 检查最终状态

```bash
openspec status --change demo-comet-schema --json
```

### A.10 验证实现

```text
/opsx:verify
```

### A.11 完成后同步/归档

```text
/opsx:sync
/opsx:archive
```

---

## 附录 B：一句话速记

```text
Config 解决“规则”
Schema 解决“产物 + DAG”
Template 解决“格式”
Instruction 解决“生成方法”
Status 解决“当前状态”
Apply.requires 解决“何时能实现”
Tracks 解决“任务进度”
Skill 解决“Agent 如何执行”
OMO 解决“谁来做、何时做”
Hook 解决“何时自动触发”
```
