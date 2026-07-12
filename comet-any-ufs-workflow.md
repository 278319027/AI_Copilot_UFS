# UFS 固件仓库的 comet-any 用法

> 目标：把 `comet-any` 作为流程编排器，用 `OpenWiki / Graphify / CodeGraph` 提升 AI 辅助编程质量。

## 结论

- `comet-any` 负责定义 workflow contract
- `OpenWiki` 负责项目知识底座
- `Graphify` 负责全局结构关系
- `CodeGraph` 负责代码级真相

## 流程

### 1. open

目标：
- 读真实 Skill
- 读项目偏好
- 建立仓库背景

工具：
- `OpenWiki`
- `Graphify`

输出：
- 仓库背景
- 术语表
- 模块边界
- 结构图

### 2. design

目标：
- 把用户需求翻成 workflow contract
- 定义 node / binding / schema / guardrail / handoff

工具：
- `OpenWiki`
- `Graphify`
- `CodeGraph`

输出：
- 节点职责
- 依赖关系
- 影响面
- 设计证据

### 3. build

目标：
- 生成 bundle draft
- 写 internal node skills
- 固定脚本和恢复语义

工具：
- `CodeGraph`
- `Graphify`

输出：
- node skill 草稿
- 脚本契约
- 恢复点
- 证据链

### 4. verify

目标：
- 检查 draft hash
- 检查 eval / review / readiness
- 验证变更影响面

工具：
- `CodeGraph`
- `Graphify`

输出：
- 通过/失败
- 影响面摘要
- 回归范围

### 5. archive

目标：
- 把新知识回写成 reference
- 留下后续可复用证据

工具：
- `OpenWiki`

输出：
- 项目知识更新
- 约定更新
- 历史决策记录

## 推荐落点

| 工具 | 主落点 | 辅助落点 |
|---|---|---|
| OpenWiki | `reference` | `archive` |
| Graphify | `reference` | `design` / `verify` |
| CodeGraph | `design` / `build` / `verify` | `script` |

## UFS 场景重点

- 启动链路
- 模块边界
- 平台差异
- 条件编译
- 配置入口
- 测试回归
- 失败路径

## 最短使用法

1. 先用 `OpenWiki` 读懂仓库
2. 再用 `Graphify` 看全局结构
3. 再用 `CodeGraph` 锁实现面
4. 让 `comet-any` 把结果编成 workflow contract
5. 让生成结果通过 eval / review / preview

