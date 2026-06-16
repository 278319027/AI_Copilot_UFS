# Spec Baseline Index

SSD 固件系统当前行为的权威描述。每个文件描述一个模块的实际行为。

## 基线文件

| 文件 | 模块 | 最后更新 | 最后变更 |
|------|------|---------|---------|
| [nvme-commands.md](./nvme-commands.md) | NVMe 命令处理 | — | — |
| [ftl-mapping.md](./ftl-mapping.md) | FTL 映射层 | — | — |
| [nand-driver.md](./nand-driver.md) | NAND 驱动层 | — | — |
| [error-handling.md](./error-handling.md) | 错误处理 | — | — |

## 使用说明

- **查询优先**：AI 在理解系统行为时，先查此基线，再查 CodeGraph
- **增量更新**：每次变更通过 Review Gate 后，将 `proposals/{change-id}/specs/` 增量合并到此
- **版本管理**：所有基线文件纳入 Git，每次合并产生 `chore(spec): merge {change-id} into baseline` 提交

## 基线填充状态

初始基线为空。在 SSD 固件项目实际使用中逐步填充：
1. 首次从上到下浏览主要模块接口和流程
2. 记录核心数据结构、关键函数、状态转换
3. 后续每次变更追加/修改对应章节

## 参考

- 规格层规则：`rules/spec_rules.md`
- 规格工作流：`references/spec_workflow.md`
