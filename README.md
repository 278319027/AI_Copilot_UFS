好的。下面输出完整的 agent总结.md 内容。你可以直接复制保存为文件。
# UFS Firmware AI Assisted Development Platform - Agent总结

版本：V1.0

---

# 1. 项目目标

目标不是简单使用 AI 自动生成代码，而是构建一个面向 **UFS Firmware Feature 开发** 的 AI 增强软件工程体系。

核心思想：

> 通过 Workflow Governance + Multi-Agent + Knowledge Plane，让 AI 按照资深固件团队的方法完成需求分析、架构设计、编码、验证和知识沉淀。

最终目标：

构建一个：

> AI 增强的 UFS Firmware Engineering Team

而不是：

> 一个自动写代码的 AI 工具。

---

# 2. 总体架构理念

核心组件：

|组件|职责|
|-|-|
|Comet Classic|Workflow Governance|
|OpenCode|Agent Runtime|
|Main Agent|主开发工程师|
|Artifact Review Agent|流程产物审查|
|Firmware Expert Agent|固件专家咨询|
|OpenSpec|需求和变更规范|
|Superpowers|设计方法和工程流程|
|MCP|工具连接层|
|CodeGraph|代码知识图谱|
|Graphify|工程关系图|
|OpenViking|长期知识记忆|
|OpenWiki|结构化工程知识|

总体关系：
Human Engineer

                   |
                   |

          Comet Classic Workflow

                   |
                   |

             OpenCode Runtime

                   |
   -----------------------------------

   |                 |               |

   v                 v               v
Main Agent       Artifact Review   Firmware Expert Developer            Agent             Agent
|
   |
   +-------------------------------+

                   |

             Knowledge Plane

                   |

   -----------------------------------

   |              |              |
CodeGraph      Graphify     OpenViking    OpenWiki
|

                   |

         UFS Firmware Repository

---

# 3. Comet 与 OpenCode 的关系

## Comet Classic

职责：

- Workflow 状态管理
- 阶段转换
- Artifact 管理
- Quality Gate
- 人工审批节点


## OpenCode

职责：

- Agent 推理
- Tool 调用
- 代码理解
- 代码修改
- 测试执行


关系：
Comet = 项目经理
OpenCode = 开发工程师

Comet 决定：

> 当前应该做什么。


OpenCode 决定：

> 如何完成当前任务。

---

# 4. 三类核心 Agent

---

# 4.1 Main Agent

角色：

> AI Firmware Developer


职责：

- 理解 Feature 需求
- 分析 UFS 固件代码
- 使用知识工具
- 生成 Proposal
- 生成 Design
- 修改代码
- 执行验证


权限：
Read Code
Modify Code
Build
Test
Knowledge Query

---

# 4.2 Artifact Review Agent

角色：

> Workflow Artifact Reviewer


注意：

它不是 Code Review Agent。

它审查的是：
proposal.md
design.md
task.md
verification plan

检查：

## 完整性

例如：

- 是否描述问题背景
- 是否说明影响范围
- 是否定义验收标准


## 一致性

例如：

- Design 是否符合当前架构
- 修改范围是否合理


## 流程要求

例如：

Design 阶段必须包含：
Architecture
Data Flow
API Change
Memory Impact
Performance Impact
Risk
Test Plan

输出：
PASS
或者
FAIL

Feedback

---

# 4.3 Firmware Expert Agent

角色：

> Senior UFS Firmware Architect


用途：

解决 Main Agent 无法解决的领域问题。


典型问题：
为什么这里必须这样设计？
这个状态切换有什么硬件限制？
这个接口为什么不能直接修改？
历史上为什么这样实现？

知识范围：

- UFS Protocol
- FTL
- NAND
- Power Management
- Firmware Architecture
- Historical Bugs


权限：

允许：
Knowledge Search
Code Analysis
Architecture Analysis

禁止：
Code Modify
Git Commit

定位：

> Consultant，而不是 Developer。

---

# 5. Main Agent 如何发现自己不知道？

不能依赖 LLM 自觉。

需要机制。

---

# 5.1 Self Assessment

每阶段 Artifact 强制输出：
Confidence
Unknowns
Risks
Assumptions

例如：

```yaml

unknowns:

  - Write Booster disable timing

confidence:

  0.4


need_expert:

  true
5.2 Knowledge Failure Detection
Main Agent 查询：
CodeGraph

OpenWiki

OpenViking

Graphify
如果：
没找到结果
信息不足
信息冲突
触发：
Firmware Expert Agent
5.3 Review Agent Trigger
Review Agent 如果发现：
例如：
设计依赖 Power Management

但是没有分析 Power State
输出：
FAIL

Need Firmware Expert Consultation
6. Firmware Expert Agent 能力定义
不能只靠：
You are UFS expert
需要四部分。
6.1 Role Prompt
定义：
Senior UFS Firmware Architect
6.2 Knowledge Scope
例如：
UFS Specification

Firmware Architecture Docs

FTL Design

NAND Behavior

Historical Bug Database

Performance Reports
6.3 Tool Permission
允许：
CodeGraph Search

OpenViking Query

OpenWiki Search

Graphify Query
禁止：
Code Modify

Git Operation
6.4 Workflow Role
定义：
Consultant
不能：
Executor
7. Knowledge Plane 设计
Knowledge Plane 是整个系统核心。
7.1 CodeGraph
职责：
代码结构理解。
提供：
Function Call Graph

Dependency

Impact Analysis
回答：
哪里需要修改？
7.2 Graphify
职责：
工程关系分析。
建立：
Feature

 |

Module

 |

Function

 |

Test

 |

Issue
回答：
修改影响什么？
7.3 OpenViking
职责：
长期工程记忆。
保存：
历史 Bug

设计讨论

调试经验

Review记录
回答：
为什么这样设计？
7.4 OpenWiki
职责：
结构化知识。
保存：
架构文档

模块说明

设计规范

流程文档
回答：
当前系统知识是什么？
8. Comet Classic 中 Agent 协作流程
典型流程：
Feature Request

        |

        v

Proposal Stage


        |

        v

Main Agent

        |

        v

proposal.md


        |

        v

Artifact Review Agent


        |

     PASS

        |

        v


Design Stage


        |

        v

Main Agent


        |

发现未知问题？

        |

        +------ YES

                  |

                  v

          Firmware Expert Agent


                  |

                  v

             Design完成


        |

        v

Artifact Review


        |

        v

Build


        |

        v

Verify
9. 人机协作变化
传统模式：
工程师:

需求分析

查资料

设计

编码

Review

测试
AI增强模式：
AI:

代码分析

知识查询

设计初稿

代码实现

自动验证


Human:

架构决策

风险确认

最终批准
人工从：
过程参与者
转变为：
关键决策者
10. 当前主要风险
10.1 Agent 无限循环
问题：
Review FAIL

↓

修改

↓

Review FAIL

↓

循环
解决：
增加：
Max Retry

Escalation Human
10.2 Knowledge 工具职责混乱
解决：
建立 Knowledge Gateway：
CodeGraph

负责代码


Graphify

负责关系


OpenViking

负责经验


OpenWiki

负责知识
10.3 Expert Agent 退化成普通聊天机器人
解决：
必须定义：
Role

Knowledge Scope

Tools

Output Format

Workflow Role
11. 后续重点设计问题
下一阶段继续研究：
1.
OpenCode 中：
Agent 定义方式
Agent 调用方式
Agent 生命周期
2.
Comet Classic：
Workflow 配置
State 管理
Artifact 管理
3.
OpenSpec / Superpowers：
如何接入流程
如何生成标准 Artifact
4.
Agent 通信协议：
定义：
Main Agent

↓

Expert Agent

↓

Review Agent
之间的数据格式。
5.
Knowledge Plane：
设计：
数据来源
索引方式
更新机制
权限控制
总结
最终架构：
                 Human

                   |

              Comet Classic

                   |

               OpenCode

                   |

     ---------------------------------

     |              |                |

 Main Agent   Review Agent   Expert Agent


                   |

             Knowledge Plane


                   |

 CodeGraph + Graphify + OpenViking + OpenWiki


                   |

            UFS Firmware Repo
核心理念：
用 AI 模拟一个高级 UFS 固件团队，而不是让 AI 单纯替代程序员写代码。
角色映射：
AI组件
对应角色
Comet
项目流程管理
Main Agent
固件开发工程师
Artifact Review Agent
技术评审
Firmware Expert Agent
资深架构专家
Knowledge Plane
团队知识库
Human
架构负责人

后续我们可以基于这份 `agent总结.md` 继续扩展，例如进入 **V1实施设计文档**：  
`UFS_Firmware_AI_Agent_Platform_Design_V1.md`，重点设计 OpenCode + Comet Classic + MCP + Agent 配置落地方案。