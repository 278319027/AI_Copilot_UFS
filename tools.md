---
description: UFS firmware code comprehension workflow
globs: ["**/*.c", "**/*.h"]
alwaysApply: false
---

# 固件代码理解

首次使用或无 graphify-out/ 时先执行：`graphify . && codegraph build .`

## 0. 阶段准备

- **Open 阶段开始**：`graphify . && codegraph build .` 构建图谱 → 读 `docs/ufs-domain-guide.md`
- **Design/Build 开始**：读 `docs/ufs-coding-guide.md`（编码规范 + 审查清单）
- **Build 每个 review subagent**：重新读 `docs/ufs-coding-guide.md`，按审查项逐项检查 diff
- **openwiki 不存在或为空**：`openwiki --init && graphify update .`。后续 Comet archive 前 `openwiki --update`
- **测试**：参考 `docs/ufs-domain-guide.md` 或已有测试文件的命名和断言模式

## 1. 判断深度

| 改动类型 | 执行 |
|---------|------|
| 跨模块、新功能、数据结构、中断/寄存器/状态机 | §2-§5 |
| 单函数内修改、加校验、修边界 | §3-§4（跳 §2） |
| 注释/格式/缩进 | 跳过。常量宏和 `#define` 走单函数流程 |
| 不确定 | 按完整执行 |

## 2. 架构认知

从 `docs/ufs-domain-guide.md` 提取需求相关的领域术语（架构层名、协议概念、模块名），用作 graphify 查询词：

```bash
graphify explain "<术语>"    # 模块边界 + god nodes + @ref
graphify query "<需求描述>"   # subgraph + 文档节点
```

不读源码。结果为空 → 用同义词或上层概念重试（如 "UTP" 换 "transport"、"HCI" 换 "host controller"）。返回节点过多（>15）→ 加限定词缩小范围。仍不收敛 → `graphify explain` 返回的 god nodes 逐个检查。

写入 exploration-evidence.md：
- 模块分层边界（协议/设备抽象/平台/寄存器时序/测试仿真）
- 关键入口函数名
- Domain Path 受影响项（init、read-write、command queue、interrupt、power mode、error recovery、descriptor、UPIU、doorbell、timeout）
- 涉及的状态机和流程

## 3. 关键路径

入口/出口明确时用 `graphify path "入口" "出口"` 追踪。不确定出口时用 `codegraph context "<入口>"` 看下游。codegraph 不可用时先 `codegraph build .`。

对路径上每个节点确认：角色（生产/辅助）、同步/异步、运行上下文（中断/进程/工作队列）。graphify 与 codegraph 矛盾 → 信 codegraph。

UFS 专项（遇到对应类型逐项确认）：
- 状态机函数：entry/exit 完整、切换时持锁/关中断、中间态不接收命令
- 中断函数：top-half 仅置标志读寄存器、bottom-half 做实际处理、中断内无睡眠函数
- 寄存器访问：用 REG_* 宏、读改写关中断、Reserved 位写 0

## 4. 影响范围

`codegraph fn-impact` + `graphify affected --depth 3` 双向比对：
- 都返回 → 高置信
- 只有一个返回 → 读源码确认
- 意外影响 → 回 §3

UFS 专项：
- 共享数据结构：所有访问点有锁、中断与进程无并发
- 命令路径：submission→processing→completion 完整、超时路径存在、错误回收全覆盖

## 5. 设计约束

`graphify query "<函数>"` 搜源码注释和 openwiki。若无 openwiki 文档，按 §0 初始化。确认：函数约束（持锁/参数生命周期）、踩坑记录、已知 TODO。

全部完成后在 exploration-evidence.md 自检，缺失回对应步骤：

```
□ 已从领域指南确认需求涉及的模块术语
□ 架构分层和 Domain Path 清楚
□ 调用路径入口→出口完整，每个节点角色和上下文确认
□ 影响范围双向验证一致，无意外波及
□ 已知 ≥3 条约束
□ 能回答"为什么这样实现""为什么选此方案""哪些路径不可改及原因"
□ 验证计划覆盖 boot/枚举/读写/异常恢复/性能/兼容性
```

## 6. 边缘与禁止

工具矛盾按 `codegraph context > codegraph fn-impact > graphify EXTRACTED > graphify INFERRED` 裁决，`AMBIGUOUS` 必读源码。

函数指针/回调：`codegraph context` 看结构体字段 → `graphify query` 搜赋值点 → 逐个读。不全则标记 Unknown。

宏：`codegraph context` 找定义，展开后重评估前面步骤。条件编译：注意 codegraph 行号跳变，搜配置宏，每条路径覆盖。

禁止：猜功能、一个链当全部、不查 fn-impact、结论无工具证据、跳过 §4/§5、矛盾时选顺眼、不确定就写。

以下情况暂停，写入 Unknown：
```
- 未知项：<描述>  |  影响：<后果>  |  假设：<暂用>  |  确认：<来源>
```

> 跨模块 hardware/timing/side effect 风险和已有测试/仿真入口，通过 `graphify query` 在 openwiki 查找。

## 图谱更新

graphify 已安装 post-commit hook，每次 `git commit` 自动增量更新。

codegraph：`codegraph watch .` 开发期间后台监听增量更新。无 git hook，删文件后留孤儿节点需全量重建。

- 开发期间：`codegraph watch .` 后台运行
- Comet verify 入口：`graphify update . --force && codegraph build . --no-incremental`
- 手动删源码后：`codegraph build . --no-incremental`
