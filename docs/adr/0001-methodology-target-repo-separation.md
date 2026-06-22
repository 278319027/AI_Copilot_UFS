# ADR 0001: 分层架构方法论与目标代码库解耦

- **状态**：Accepted
- **日期**：2025-12-20（项目启动时）
- **决策者**：zsf 项目维护者
- **适用范围**：整个 zsf 项目

## 背景

zsf 项目的核心目标是为 SSD 固件团队提供 AI 辅助编程方法论与工具链。需要决定：方法论资产（skills、memory、specs）应该与目标固件代码库（femu）放在同一个仓库，还是分离？

## 考虑过的选项

### 选项 A：方法论层 + 目标代码库同仓

将 `.opencode/`、`openspec/` 等方法论资产与 femu 代码放在同一仓库。

**优点**：单一仓库，部署简单。
**缺点**：femu 是 QEMU fork，需要与上游 QEMU 同步；混入方法论资产会污染其 Git 历史与 PR 流程；换 SSD 固件代码库时必须重新部署方法论。

### 选项 B：方法论层独立仓库（采用）

zsf 作为独立的方法论仓库，femu 保持其纯净状态。`opencode.json` 通过 `FEMU_ROOT` 环境变量指向目标代码库。

**优点**：
- 不污染 femu 的 Git 历史
- 一套方法论可服务多个 SSD 固件代码库（不绑定 femu）
- 职责清晰：zsf 是"驾驶舱"（方法论+配置+变更追踪），femu 是"引擎"（源码+构建+运行）
- `graphify-out/` 等分析产物放在 femu 内部（与代码版本强绑定）

**缺点**：需要多仓库协作；`FEMU_ROOT` 路径需正确配置。

## 决策

采用选项 B。`verify.sh [9/15]` 验证 `FEMU_ROOT` 路径存在性；`verify.sh [13/15]` 检测 femu 子目录是否误生成 `.opencode/`，防止方法论层误落地。

## 后果

- zsf 仓库约 3800 行 MD 文档 + 19 个 skill + 6 个 memory + 5 个 command，方法论资产完整
- femu 仓库保持原状
- 切换目标代码库只需 `export FEMU_ROOT=/path/to/new/ssd_repo`

## 验证

- `bash verify.sh` 通过（9/15、13/15 检查）
- 2 个已归档 OpenSpec 变更（2026-06-22-add-femu-gc-stats-log-page、2026-06-22-implement-flip-reset-gc-stats）证明方法论可在 femu 上正常工作
