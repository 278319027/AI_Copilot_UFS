# OpenSpec 默认几个文档的生成原理详细分析

## 一、核心模型

OpenSpec 默认的 proposal、specs、design、tasks 并不是由 CLI
直接生成，而是由以下组件共同驱动：

-   Schema：定义 Artifact、依赖关系和生成规则
-   Template：定义文档结构
-   Instruction：定义 Agent 生成要求
-   Skill：定义 Agent 工作流程
-   CLI：负责状态、校验和生命周期管理
-   LLM：生成具体内容

核心关系：

Schema 决定生成什么； Template 决定长什么样； Instruction 决定如何生成；
Skill 决定什么时候生成。

------------------------------------------------------------------------

## 二、默认 spec-driven Artifact DAG

默认关系：

    proposal
       |
       +------------+
       |            |
     specs       design
       |            |
       +------------+
              |
            tasks
              |
            apply

信息逐步收敛：

    用户需求
     ↓
    Proposal
     ↓
    系统行为约束
     ↓
    Spec
     ↓
    技术实现方案
     ↓
    Design
     ↓
    执行计划
     ↓
    Tasks
     ↓
    代码

------------------------------------------------------------------------

# 三、proposal.md 生成原理

Proposal 的目标：

-   说明为什么需要 Change
-   定义变化范围
-   确认影响能力

生成过程：

    用户需求
     ↓
    openspec skill
     ↓
    读取 schema
     ↓
    读取 template/instruction
     ↓
    分析已有 specs
     ↓
    确定 capability
     ↓
    生成 proposal.md

典型内容：

    Why
    What Changes
    Capabilities
    Impact

其中 Capability 是后续 Spec 生成的重要入口。

------------------------------------------------------------------------

# 四、specs 生成原理

Spec 描述：

> 系统应该表现成什么样。

关注：

-   行为
-   输入输出
-   约束
-   Scenario

不描述：

-   函数
-   类
-   实现算法

OpenSpec 使用 Delta Spec：

    ADDED
    MODIFIED
    REMOVED
    RENAMED

生成输入：

    Proposal
    +
    已有 Specs
    +
    项目上下文
    +
    代码知识

输出：

    change/specs/**/*.md

Scenario 是连接需求和测试的桥梁。

------------------------------------------------------------------------

# 五、design.md 生成原理

Design 描述：

> 如何实现 Spec 定义的行为。

关注：

-   架构
-   模块
-   接口
-   数据结构
-   状态机
-   技术决策
-   风险

输入：

    Proposal
    +
    Spec
    +
    代码库
    +
    架构知识

输出：

    design.md

典型结构：

    Context
    Goals / Non-Goals
    Architecture
    Decisions
    Risks
    Open Questions

Design 是条件 Artifact，并非所有 Change 必须存在。

------------------------------------------------------------------------

# 六、tasks.md 生成原理

Tasks 是：

    Spec + Design
            ↓
    Implementation Plan

它同时是 Agent 执行状态。

示例：

    - [ ] Add configuration
    - [ ] Implement logic
    - [ ] Add unit tests

完成后：

    [x]

供 apply/status 使用。

------------------------------------------------------------------------

# 七、四个核心组件关系

## Template

负责：

    文档结构

## Instruction

负责：

    生成规则和质量要求

## Skill

负责：

    Agent 工作流程

## Schema

负责：

    Artifact DAG 和生命周期

------------------------------------------------------------------------

# 八、完整生成流程

    User Request
          |
    OpenSpec Skill
          |
    Schema Resolution
          |
    Requires + Template + Instruction
          |
    Agent Context
          |
    Proposal / Spec / Design / Tasks
          |
    Status Validation
          |
    Next Artifact

------------------------------------------------------------------------

# 九、对 Comet + ATDD 的意义

OpenSpec 默认：

    proposal
     ↓
    spec
     ↓
    design
     ↓
    tasks

可以扩展为：

    PRD
     ↓
    Story
     ↓
    Acceptance Criteria
     ↓
    Spec
     ↓
    Design
     ↓
    UT Design
     ↓
    Tasks
     ↓
    Build
     ↓
    Verify

正确方式不是重新实现 OpenSpec，而是：

-   保留 OpenSpec Skill
-   保留 Artifact 生命周期
-   定制 Schema DAG
-   增加领域 Skill

------------------------------------------------------------------------

# 十、核心结论

OpenSpec 默认文档生成机制本质是：

    Artifact Graph Driven AI Development Workflow

不是 Markdown 模板系统。

其中：

-   Schema 决定流程
-   Template 决定结构
-   Instruction 决定生成规则
-   Skill 决定 Agent 行为
-   LLM 生成内容
-   CLI 管理生命周期

这也是 OpenSpec 支撑多 Agent、企业级 AI 软件开发流程的核心。
