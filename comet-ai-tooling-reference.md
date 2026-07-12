# Comet AI 辅助编程工具参考：OpenWiki / Graphify / CodeGraph

> 说明：本文是基于 `rpamis/comet` 的 `/comet-any` 流程做的参考映射。  
> 其中工具能力和命令来自各自官方仓库；“放进 Comet 哪一阶段用”是面向本项目的使用建议。

## 目标

在已有 UFS 固件代码仓库里，用 `comet-any` 组织 AI 辅助编程时，减少“盲搜文件、上下文漂移、局部修改误伤、验证范围不清”这几类问题。

核心思路：

1. `OpenWiki` 负责长期项目知识沉淀
2. `Graphify` 负责跨文件、跨文档、跨媒体的结构化知识图谱
3. `CodeGraph` 负责代码级、可自动同步的局部结构和影响面分析

## 快速结论

| 工具 | 最适合放在 Comet 哪一步 | 主要产出 | 主要价值 |
|---|---|---|---|
| OpenWiki | `open` / `design` 之前 | repo wiki、AGENTS/CLAUDE 指引 | 让 AI 先懂项目背景、术语、约定 |
| Graphify | `open` / `design` / 大改动 review 前 | `graph.html`、`GRAPH_REPORT.md`、`graph.json` | 让 AI 按结构理解全局依赖，而不是 grep |
| CodeGraph | `design` / `build` / `verify` | 本地代码图、自动同步索引、MCP 查询 | 让 AI 精准看调用链、路由、影响面 |

## 1. OpenWiki

### 它是什么

OpenWiki 是面向 agent 的仓库文档 CLI，会把代码仓库和本地知识源整理成可持续更新的 wiki。它还能在 repo 根目录维护 `AGENTS.md` 和 `CLAUDE.md` 的引导块。

### 什么时候用

- 新仓库接手
- Comet 进入 `open` 前
- `design` 前补项目背景
- 大 feature 完成后补知识沉淀
- 需要让后续子代理/人类快速接力时

### 怎么用

常用命令：

```bash
openwiki code --init
openwiki --update "Refresh the wiki from repo changes"
openwiki --help
```

可选连接器：

```bash
openwiki auth slack
openwiki auth gmail
openwiki auth x
openwiki auth notion
```

### 在 Comet 里怎么放

- `open` 阶段：先让 OpenWiki 生成 repo 级背景，补齐架构、模块职责、术语、约束
- `design` 阶段：把 wiki 里的架构摘要和业务词表作为设计输入
- `build` 阶段：把 wiki 中的编码规范、目录边界、历史决策当作实现约束
- `archive` 阶段：把新知识回写 wiki，避免下一轮重复探索

### 适合输出什么

- 仓库总览
- 模块职责说明
- 目录结构说明
- 领域术语表
- 编码约定
- 历史设计决策摘要

### 价值

- 降低第一次进仓库的理解成本
- 让 `comet-any` 生成方案时少猜结构
- 让后续 agent 继承稳定上下文

### 注意

- OpenWiki 更像“知识底座”，不是符号级搜索器
- 文档要定期更新，不然会把旧知识写成真相

## 2. Graphify

### 它是什么

Graphify 会把代码、文档、PDF、图片、视频等整理成可查询的知识图谱。官方强调它不是向量库，而是可遍历的 graph。代码部分走本地解析，文档/多媒体部分走语义提取。

### 什么时候用

- 仓库大、文件多、语言混杂
- 设计阶段要看模块关系
- 需要解释“这个改动会波及哪里”
- review 前要追踪架构路径

### 怎么用

常用命令：

```bash
uv tool install graphifyy
graphify install
graphify query "show the auth flow"
graphify hook install
graphify reflect --if-stale
```

在 AI assistant 里再运行：

```text
/graphify .
```

图谱产物：

- `graphify-out/graph.html`
- `graphify-out/GRAPH_REPORT.md`
- `graphify-out/graph.json`

### 在 Comet 里怎么放

- `open` 阶段：先跑一次全局图，确认仓库里有哪些核心社区和关键边
- `design` 阶段：用图谱找模块关系、调用链、依赖边
- `build` 阶段：用图谱看修改点周边的结构影响
- `verify` 阶段：用图谱对照测试覆盖面和回归风险

### 适合输出什么

- 关键概念图
- 模块间依赖链
- 路径/调用链
- 多模态资料里的关联点
- 一次性阅读报告

### 价值

- 把“grep 一堆文件”变成“沿 graph 走路径”
- 对大仓库更稳
- 对代码 + 文档 + 图示并存的仓库很有用

### 注意

- 初次图谱构建成本高于局部搜索
- 更适合“先建地图，再查问题”
- 生成结果最好提交或长期保留，不然每次都要重建

## 3. CodeGraph

### 它是什么

CodeGraph 是本地、自动同步的代码知识图谱。它强调 AST/符号/调用关系/路由等代码结构信息，支持 MCP 和 CLI 查询。

### 什么时候用

- 改一个 feature 前先看 blast radius
- build 中要确认调用链、路由、测试入口
- verify 中要确认受影响模块
- 长时间任务中频繁增量编辑

### 怎么用

常用命令：

```bash
codegraph install
codegraph init
codegraph status
codegraph sync
```

典型习惯：

- 先 `codegraph install`，让 agent 接上
- 每个项目跑一次 `codegraph init`
- 平时依赖自动同步
- 只有 watcher 失效、沙箱环境、脚本化场景才手工 `codegraph sync`

### 在 Comet 里怎么放

- `design` 阶段：查符号关系、调用链、路由、接口边界
- `build` 阶段：改代码前先问受影响面
- `verify` 阶段：确认测试应该打到哪一层
- `comet-any` 生成 Skill 时：把它作为“结构真相来源”

### 适合输出什么

- 符号位置
- 调用者 / 被调用者
- 路由到 handler 的映射
- 影响面
- 最近变更后的同步状态

### 价值

- 适合日常增量开发
- 自动同步，减少人工维护成本
- 比纯 grep 更适合代码级定位

### 注意

- 如果项目没初始化，查询会失败或退化
- 适合代码结构，不适合替代长期知识文档

## Comet 流程中的推荐组合

### 1. 新 feature 进入前

1. 先 `OpenWiki` 读懂仓库
2. 再 `Graphify` 看全局结构
3. 再 `CodeGraph` 锁定本次改动的局部影响面

### 2. 设计阶段

- `OpenWiki` 提供背景和约定
- `Graphify` 提供跨文件/跨媒体结构
- `CodeGraph` 提供代码级依赖真相

### 3. 实现阶段

- `CodeGraph` 优先
- 需要全局回看时再补 `Graphify`
- 需要确认项目约定时回看 `OpenWiki`

### 4. 验证阶段

- `CodeGraph` 用来缩小测试范围
- `Graphify` 用来检查文档/图示是否也受影响
- `OpenWiki` 用来确认是否违背 repo 约定

### 5. 归档阶段

- 把新决策写回 `OpenWiki`
- 必要时刷新 `Graphify`
- 保持 `CodeGraph` 索引和当前分支同步

## 推荐的 comet-any 绑定思路

如果后面要把这份 reference 喂给 `comet-any`，建议按下面思路映射：

- `OpenWiki` = `advisory` 或 `evidence-only`
- `Graphify` = `guarded` 的结构分析证据
- `CodeGraph` = `guarded` 的实现/验证证据

也就是说：

- `OpenWiki` 帮 AI 少走弯路
- `Graphify` 帮 AI 看到全局
- `CodeGraph` 帮 AI 改对局部

## 速查表

| 问题 | 优先工具 | 原因 |
|---|---|---|
| 这个仓库是做什么的 | OpenWiki | 先拿业务和架构背景 |
| 这个 feature 会碰哪些模块 | CodeGraph | 直接看调用链和符号关系 |
| 这次改动会不会牵一片 | CodeGraph + Graphify | 一个看代码，一个看全局结构 |
| 文档/图/PDF 也要一起理解 | Graphify | 支持多模态图谱 |
| 以后别再重复解释仓库约定 | OpenWiki | 持久 wiki 最合适 |

## 参考链接

- [Comet 仓库](https://github.com/rpamis/comet)
- [Comet: `comet-any` 说明](https://github.com/rpamis/comet/blob/master/docs/operations/EVAL-USAGE.md)
- [OpenWiki 仓库](https://github.com/langchain-ai/openwiki)
- [Graphify 仓库](https://github.com/Graphify-Labs/graphify)
- [CodeGraph 仓库](https://github.com/colbymchenry/codegraph)
