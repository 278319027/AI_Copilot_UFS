# comet-any 工具链速查

> 主文档: [comet-any 主参考](/home/zsf/桌面/skills/docs/comet-any-master-reference.md)

## 先记 1 句

`comet-any` 负责造 workflow Skill；`OpenWiki` 养知识底座；`Graphify` 养全局结构；`CodeGraph` 养代码级真相。

## comet-any 做什么

- 读真实 Skill
- 把用户目标转成 workflow contract
- 绑定 node / skill / schema / guardrail / handoff
- 等用户确认
- 生成 bundle draft
- 跑 eval / review / readiness / preview

## comet-any 不做什么

- 不直接实现业务 feature
- 不替代 `/comet` 主流程
- 不在确认前写 draft
- 不在缺证据时强行 ready

## 三工具怎么放

| 工具 | 最适合放哪 | 主要作用 |
|---|---|---|
| OpenWiki | `reference` lane | 沉淀仓库背景、术语、约定、历史决策 |
| Graphify | `reference` + `skill-core` | 看模块/文档/媒体的全局关系 |
| CodeGraph | `script` + `skill-core` + `skill-review` | 看符号、调用链、影响面、测试范围 |

## UFS 固件仓库版

| 工具 | 先看什么 | 典型问题 |
|---|---|---|
| OpenWiki | 启动流程、模块边界、平台差异、构建约定 | 这块代码属于哪层，哪些目录不能乱动 |
| Graphify | 启动链路、配置链路、数据流、错误传播 | 这个 feature 会不会影响启动路径 |
| CodeGraph | 核心符号、调用链、条件编译、测试挂钩 | 改这个函数会影响哪条路径，哪些测试要补 |

## comet-any 产物

- `SKILL.md`
- internal node skills
- `reference/workflow-protocol.json`
- `reference/resolved-skills.json`
- `reference/authoring-lanes.json`
- `reference/skill-review.md`
- scripts / rules / hooks
- `comet/eval.yaml`

## 直接引用的短判断

- 先看 `OpenWiki`，再看 `Graphify`，最后用 `CodeGraph` 锁实现面
- `reference` 先收知识和结构证据
- `skill-core` 再把证据翻成节点职责
- `skill-review` 最后查影响面和证据链

## 给 comet-any 的短提示

```text
目标：为 UFS 固件仓库定制 comet-any 参考。
要求：
1. 说明 comet-any 的职责、输入、产物、边界。
2. 把 OpenWiki / Graphify / CodeGraph 映射到 comet-any 的 lane/node。
3. 面向固件仓库，强调启动链路、模块边界、条件编译、配置入口、测试回归。
4. 输出要能给人读，也能给 comet-any 作为 reference。
```
