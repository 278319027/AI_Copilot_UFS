

已优化完成，以下是最终版职场汇报文档：

---

Comet 项目实践汇报

> AI 编码工作流探索：从"自由发挥"到"流程固化"

汇报人：xxx | 日期：2026年7月

---

一、背景：我们遇到了什么问题？

团队在使用 AI 辅助编码的过程中，积累了一些实践经验，但也遇到了明显的瓶颈：

问题	具体表现	影响	
需求确认环节薄弱	AI 容易在需求还没对齐时就开始写代码	方向跑偏，后期返工	
阶段切换依赖个人经验	每个人判断"该做什么"的标准不一致	流程不统一，质量波动大	
会话中断后难以续接	关闭 AI 工具后，上下文丢失	重复沟通，浪费时间和 Token	
知识难以沉淀	做完的需求没有归档，下次同类问题从零开始	经验无法复用，重复造轮子	

> 核心矛盾：我们掌握了 AI 编码的方法，但缺少一个能把方法固化成流程、把流程沉淀成资产的机制。

---

二、调研：业界如何解决？

在探索过程中，我们关注到两个开源项目：

2.1 OpenSpec —— 需求与规格管理

解决什么问题：让 AI 编码的"需求侧"有章可循

能力	价值	
提案管理	把模糊需求变成结构化提案，不再是一句话需求	
规格生命周期	需求从提出到归档全程追踪，文档与代码同步演进	
Delta Spec 同步	变更规格自动合并到主规格，避免"代码改了、文档还是旧的"	
归档闭环	变更完成后自动归档，形成可复用的知识资产	

一句话：OpenSpec 让"做什么"变得清晰、可追溯、可复用。

2.2 Superpowers —— 工程方法论

解决什么问题：让 AI 编码的"执行侧"有方法论支撑

能力	价值	
头脑风暴	苏格拉底式追问，输出带推荐的技术方案	
设计文档	生成 Design Doc，记录决策过程	
计划拆分	把任务细化到 2-5 分钟的原子步骤	
TDD 驱动	每个步骤先写测试、再写实现	
三角色审查	Implementer → Spec Reviewer → Quality Reviewer 流水线	

一句话：Superpowers 让"怎么做"有方法、有质量、有保障。

2.3 两者单独使用的局限

```
只用 OpenSpec：                    只用 Superpowers：
┌─────────────────┐              ┌─────────────────┐
│ 需求清晰了 ✓     │              │ 技术方案有了 ✓   │
│ 规格文档有了 ✓   │              │ 代码写出来了 ✓   │
│ 但怎么实现？❌   │              │ 但需求对吗？❌   │
│ 测试怎么做？❌   │              │ 归档了吗？❌     │
│ 质量谁把关？❌   │              │ 下次能复用吗？❌ │
└─────────────────┘              └─────────────────┘
```

> 调研结论：OpenSpec 和 Superpowers 各自很强，但中间存在断层——从"确定做什么"到"知道怎么做"之间，缺少一个自动衔接的编排层。

---

三、方案：引入 Comet 编排层

3.1 Comet 的定位

组件	职责	关注点	角色比喻	
OpenSpec	需求、提案、规格、归档	WHAT（做什么）	🧭 导航系统 —— 定目标	
Superpowers	设计、计划、编码、审查	HOW（怎么做）	⚡ 动力总成 —— 负责执行	
Comet	把二者编排成流水线	WHEN & NEXT（什么时候做什么）	☄️ 行车电脑 —— 自动衔接	

> 一句话：Comet 不是替代两者，而是让两者协同工作的编排层。

3.2 如何结合两者的优点

```
┌─────────────────────────────────────────────────────────────────────────┐
│                           Comet 编排层                                   │
│  ┌─────────────┐         ┌─────────────────┐         ┌─────────────┐   │
│  │  OpenSpec   │  ──→   │     Comet       │  ──→   │ Superpowers │   │
│  │   优点：     │  自动   │   阶段守卫 +      │  自动   │   优点：     │   │
│  │ • 需求清晰   │  衔接   │   状态机 +        │  衔接   │ • 方案深度   │   │
│  │ • 规格追踪   │         │   断点恢复 +      │         │ • 质量保障   │   │
│  │ • 归档复用   │         │   自动归档        │         │ • TDD 规范   │   │
│  │   缺点：     │         │                 │         │   缺点：     │   │
│  │ • 实现缺方法 │  ←────  │   弥补各自短板    │  ──→  │ • 缺需求闭环 │   │
│  │ • 质量缺把关 │         │                 │         │ • 缺知识沉淀 │   │
│  └─────────────┘         └─────────────────┘         └─────────────┘   │
└─────────────────────────────────────────────────────────────────────────┘
```

Comet 的衔接作用：

衔接点	OpenSpec 输出	Comet 做了什么	Superpowers 输入	
Open → Design	proposal（需求提案）	自动触发 brainstorming，生成上下文包	Design Doc（技术方案）	
Design → Build	delta spec（变更规格）	自动同步到 plan，锁定隔离模式	Writing Plans（执行计划）	
Build → Verify	tasks（任务清单）	强制检查每个 task 是否完成	测试报告、审查结果	
Verify → Archive	verification（验证报告）	自动合并 delta spec → 主 spec	归档完成，知识沉淀	

> 效果：需求清晰 + 方案深度 + 自动衔接 = 从想法到归档，一条命令串到底，知识可复用。

---

四、五阶段工作流

```
┌─────────┐     ┌──────────┐     ┌─────────┐     ┌─────────┐     ┌──────────┐
│  1.Open │ --> │ 2.Design │ --> │ 3.Build │ --> │ 4.Verify│ --> │ 5.Archive│
│  开启   │     │  深度设计  │     │ 计划构建  │     │ 验证收尾  │     │  归档闭环  │
└─────────┘     └──────────┘     └─────────┘     └─────────┘     └──────────┘
  OpenSpec         Superpowers       Superpowers      两者协同         OpenSpec
  需求→提案         头脑风暴→设计     TDD编码→提交      强制检查         归档复用
```

> 开启 `auto_transition` 后，阶段自动衔接，无需手动判断"现在该做什么"。

---

五、核心价值与前后对比

5.1 引入 Comet 带来的变化

维度	引入前（自由发挥）	引入后（流程固化）	
需求确认	容易跳过，直接写代码	Guard 强制确认，未通过无法推进	
阶段切换	依赖个人经验，标准不一	自动检测当前阶段，一键推进	
会话中断	上下文丢失，需重新沟通	`.comet.yaml` 自动续接，无缝恢复	
测试验证	容易"差不多就行"，漏测	强制验证，不通过无法归档	
知识沉淀	手动归档，容易遗漏	自动归档，同类需求直接复用	
开发纪律	依赖个人习惯，质量波动	流程固化，"每次都能写得好"	

5.2 对团队的具体收益

收益	说明	
降低返工成本	需求确认前置，Guard 拦截"方向跑偏"	
减少重复沟通	断点恢复机制，会话中断后无需从头说明	
统一质量标准	三角色审查 + 强制验证，不因个人习惯而波动	
沉淀组织资产	归档后同类需求直接复用，经验不再随人走	

---

六、从 Comet 学到的 Skill 编排思想

6.1 核心洞察："组合大于创造"

> 市面上的 AI 工具/Skill 已经很多，但能够组合这些 Skill、创造适合自己团队工作流的能力，才是核心竞争力。

Comet 展示了一种可复用的 Skill 编排范式：

```
┌─────────────────────────────────────────────────────────────┐
│                    Skill 编排通用框架                        │
├─────────────────────────────────────────────────────────────┤
│  1. 识别底层能力（WHAT / HOW / 其他维度）                    │
│  2. 定义阶段边界（每个阶段的输入、输出、验收标准）            │
│  3. 设计守卫机制（防止跳步、漏步骤、条件未满足就推进）      │
│  4. 建立状态机（外部记忆，支持断点恢复）                      │
│  5. 脚本化硬逻辑（状态管理、校验、归档交给脚本）              │
│  6. 自动化流转（减少人工干预，降低认知负担）                  │
└─────────────────────────────────────────────────────────────┘
```

6.2 可迁移到其他场景

这套范式不仅适用于编码，也适用于：

场景	阶段划分	
文档写作	大纲 → 草稿 → 审校 → 发布 → 归档	
数据分析	需求 → 探索 → 建模 → 验证 → 交付	
测试流程	用例设计 → 执行 → 报告 → 归档	
任何多阶段、多工具协同的 AI 工作流	自定义阶段 + 守卫 + 状态机	

6.3 对团队的长远价值

层面	意义	
个人	掌握"组合 Skill"的能力，能根据需求定制工作流，不再依赖单一工具	
团队	流程固化后，新成员快速上手，减少"个人习惯差异"带来的质量波动	
组织	知识通过归档机制持续沉淀，形成可复用的组织资产	

---

七、下一步计划

阶段	事项	目标	
短期（1-2周）	在试点项目中试用 Comet，收集反馈	验证流程是否适配团队现状	
中期（1个月）	根据反馈调整阶段定义和守卫规则	形成适合团队的定制化工作流	
长期（3个月）	将沉淀的范式推广到文档、测试等场景	建立团队级的 AI 工作流标准	

---

八、总结

> Comet 让我们看到：Skill 的组合与编排，比单个 Skill 的能力更重要。

从"AI 能写代码"到"AI 能规范地写代码"再到"每次都能规范地写代码"，

关键不在于工具本身，而在于把工作流程固化成可复用的机制。

---

参考：GitHub [rpamis/comet](https://github.com/rpamis/comet) | npm: `@rpamis/comet`

---

📎 下载文件：[comet_introduction_final.md](sandbox:///mnt/agents/output/comet_introduction_final.md)

---

优化要点总结：

维度	优化前	优化后	
视角	技术文档/产品介绍	职场汇报/实践探索	
口吻	"Comet 是什么"	"我们遇到了什么问题、怎么解决"	
结构	功能介绍为主	背景→调研→方案→价值→计划	
新增	—	下一步计划（短期/中期/长期）	
语言	偏技术术语	更贴近业务场景，领导易理解	
目标	介绍工具	推动落地、争取资源支持

# SSD 固件 AI 辅助编程

面向 SSD 固件团队的 AI 辅助编程体系，基于四工具架构：**Graphify**（知识图谱）+ **CodeGraph**（调用图）+ **OpenSpec CLI**（规格驱动）+ **Superpowers**（工程纪律），由 `OpenCode Agent` 统一编排 **KNOW → PLAN → BUILD → FEEDBACK** 闭环。

> ⚠️ 第一次来？先看 [项目导航](docs/navigation.md)（完整文件地图 + 配置索引 + 按角色找入口）

## 快速上手（5 分钟）

```bash
bash scripts/deploy_tools.sh /path/to/c-source

# 2. 验证环境
bash scripts/verify.sh    # 确认 17/17 通过

# 3. 选一条路径开始（在 OpenCode IDE 中）
#    路径 A（有设计文档）→ /opsx:propose <change-name>
#    路径 B（无设计文档）→ codegraph explore <区域>  先生成设计文档
```

> **工具安装 vs 项目分发**：`deploy_tools.sh` 安装的是有可执行文件的外部工具（Node.js、codegraph、graphify、openspec CLI）。Superpowers / openspec-workflow / sd-firmware-copilot 是项目级 Skill（`.opencode/skills/` 下的 Markdown 文件），随仓库分发，`git clone` 即可用，无需脚本安装。

## 两种使用路径

### 路径 A：设计文档驱动

已有设计文档（SAD/SDD/ICD），AI 直接理解设计并实现。

```
KNOW:     graphify query "<关键词>" && codegraph explore <区域>
PLAN:     /opsx:propose my-change "根据 SDD 第 X 章实现 Y 功能"
BUILD:    /opsx:apply my-change
FEEDBACK: /opsx:archive my-change && graphify update .
```

### 路径 B：代码驱动

无设计文档，AI 先分析代码自动生成设计文档，再按路径 A 执行。

```
KNOW:     codegraph explore <区域> && codegraph where <核心函数>
          graphify explain "<概念>"
          → AI 自动生成设计文档
PLAN → BUILD → FEEDBACK: 同路径 A
```

## 四工具架构

| 阶段 | 工具 | 部署方式 |
|------|------|---------|
| **KNOW** | Graphify + CodeGraph | `bash scripts/deploy_tools.sh` |
| **PLAN** | OpenSpec CLI v1.4.1 | `npm install -g @fission-ai/openspec` |
| **BUILD** | Superpowers + sd-firmware-copilot（测试验证） | `.opencode/skills/sd-firmware-copilot/` |
| **FEEDBACK** | OpenSpec CLI + Graphify | 同 PLAN |

## 配置（opencode.json）

`opencode.json` 声明 MCP 服务器、插件和加载的 Skill。其中 `codegraph` MCP 的 `--path` 形参使用 `opencode.json` 不支持注释（JSON 标准不支持），但可用 shell 变量表达式指定目标 SSD 固件源码根：

```json
"command": ["codegraph", "serve", "--mcp", "--path", "${FEMU_ROOT:-/home/zsf/AI_Proj/AI_SSD_SIM}"]
```

| 环境变量 | 作用 | 默认值 | 必需 |
|---------|------|-------|------|
| `FEMU_ROOT` | CodeGraph MCP 服务的目标 SSD 固件源码目录（直接指向，不拼接子路径） | `/home/zsf/AI_Proj/AI_SSD_SIM` | 否（未设则用默认） |

调整默认路径的方式：
- **临时覆盖**：`FEMU_ROOT=/path/to/your/ssd_femu_hw_femu_dir opencode`（当前 shell 启动 Agent 时生效）
- **永久设置**：`echo 'export FEMU_ROOT=/path/to/your/ssd_femu_hw_femu_dir' >> ~/.bashrc`

## 推荐阅读

| 序号 | 文档 | 内容 |
|------|------|------|
| 1 | [项目导航](docs/navigation.md) | 完整结构地图 + 按角色找文件 + 配置索引 + **AI_Copilot_UFS 与目标代码库关系** |
| 2 | [方法论概览](AGENTS.md#方法论概览) | 双路径、四阶段闭环、五级门禁、四条铁律 |
| 3 | [路线图](docs/roadmap.md) | 实施进度与规划 |
| 4 | [维护者指南](docs/maintainer.md) | 日常操作、FAQ、变更记录 |

## 核心原则

- **代码优先**：Source Code > Design Docs > Specs > Memory > Prompt
- **AI 辅助不替代人**：人负责架构决策和风险判断

> 完整原则（小任务原则、CodeGraph 检查、五级门禁、四条铁律）见 [docs/navigation.md §几条重要约定](docs/navigation.md#几条重要约定)。
