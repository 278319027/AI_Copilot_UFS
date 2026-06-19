## Context

BBSSD 模式在 `bbssd/ftl.c` 的 `ssd_init_params()` 中通过固定比例（20% / 10%）计算 GC 触发阈值。这一硬编码值无法满足不同研究场景对 GC 激进程度的实验需求。当前唯一调整方式是修改源码并重新编译 QEMU，实验迭代成本极高。

QEMU 的 QOM（QEMU Object Model）属性机制允许设备在实例化时通过命令行接收参数。`FemuCtrl` 已是 QOM 设备（`TYPE_FEMU`），具备扩展属性的条件。

## Goals / Non-Goals

**Goals:**
- 将 `gc_thres_lines` 与 `gc_thres_lines_high` 从硬编码改为可通过 QEMU `-device` 命令行参数配置
- 保持默认值与现有行为一致（向后兼容）
- 限制变更范围在 `femu.c`、`nvme.h`、`bbssd/ftl.c` 三文件内

**Non-Goals:**
- 运行时动态修改（热调整）
- 修改 GC 算法（victim 选择、迁移策略）
- 影响 OCSSD / ZNS / CSD / NoSSD 模式的 GC 行为
- 添加新的 NVMe Admin 命令暴露阈值

## Decisions

| # | 决策 | 选项 | 选择 | 理由 |
|---|------|------|------|------|
| 1 | 配置粒度 | 绝对行数 vs 百分比 | **绝对行数** | 百分比在实验报告中不直观，且不同 SSD 容量下同一百分比对应不同绝对值，增加结果复现难度 |
| 2 | 默认值策略 | 保持 20/10 vs 改为 0（禁用） | **保持 20/10** | 向后兼容；未指定参数时行为不变 |
| 3 | 属性命名 | `gc-thres-lines` vs `gc-threshold` | **`gc-thres-lines`** | 与代码中结构体字段名一致，降低心智负担 |
| 4 | 验证时机 | 只在 init 验证 vs 每次 GC 决策验证 | **只在 init 验证** | 阈值在初始化后不变，无需运行时检查开销 |

## Risks / Trade-offs

| 风险 | 缓解措施 |
|------|----------|
| 用户设置不合理的阈值（如 0 或超过总 line 数）导致 GC 永不触发或持续触发 | 在 `ssd_init_params()` 中对传入值做 clamp（下限 1，上限 total_lines - 1）并打印警告日志 |
| QOM 属性类型（uint32）与代码中 `int` 类型不一致导致隐式转换问题 | 显式在 `ssd_init_params()` 中用 `(int)` 转换，并添加 `static_assert` 或编译期检查确保 `uint32` 范围不溢出 `int` |
| 默认值变更后遗忘更新文档 | 在 `femu.c` 属性定义处添加注释，注明默认值的来源（`bbssd/ftl.c` 中原有比例） |

## Open Questions

1. 是否需要为 `gc_thres_lines_high` 提供独立验证（必须 < `gc_thres_lines`）？
   → **建议**：在 `ssd_init_params()` 中 assert `high <= normal`，否则调整 high = normal - 1。

2. 是否需要在 `NvmeIdCtrl` 或 SMART 日志中暴露当前阈值？
   → **本次不变更**：属于可观测性扩展，留作后续变更。
