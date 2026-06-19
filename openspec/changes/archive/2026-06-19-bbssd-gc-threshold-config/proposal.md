## Why

BBSSD 模式下的垃圾回收（GC）触发阈值（`gc_thres_lines` 与 `gc_thres_lines_high`）当前在 `bbssd/ftl.c` 中硬编码为固定比例（20% 与 10%）。研究者在进行 GC 策略实验时必须修改源码并重新编译，严重降低了实验迭代效率。将这些阈值暴露为 QEMU QOM 属性，可让研究者在不重新编译的情况下通过命令行参数直接调整 GC 行为。

## What Changes

- **新增 QOM 属性**：在 `femu.c` 的 `FemuCtrl` QOM 属性表中添加 `gc-thres-lines` 与 `gc-thres-lines-high` 两个整型属性，默认值为 20 与 10（保持向后兼容）。
- **传递参数**：在 `ssd_init_params()` 中将 `FemuCtrl` 中的新属性值写入 `struct ssdparams` 的 `gc_thres_lines` 与 `gc_thres_lines_high` 字段，替换当前硬编码值。
- **移除硬编码**：删除 `bbssd/ftl.c` 中 `ssd_init_params()` 内的固定比例计算逻辑。

## Non-goals

- **不改 GC 算法本身**：本变更仅涉及阈值配置化，不修改 `do_gc()`、`select_victim_line()` 等 GC 核心逻辑。
- **不引入运行时动态调整**：阈值仅在初始化时读取一次，运行期间不支持热修改。
- **不影响其他 SSD 模式**：OCSSD、ZNS、CSD 等模式的 GC 阈值保持不变。

## Capabilities

### New Capabilities

*(无新能力引入)*

### Modified Capabilities

- `ftl-mapping`: GC 触发条件由固定比例改为可配置参数，属于 FTL 映射层行为的可调性扩展。需要在 `ftl-mapping` 规格中新增关于 GC 阈值配置能力的 Requirement。

## Impact

| 文件 | 影响 |
|------|------|
| `femu.c` | 新增 `gc-thres-lines`、`gc-thres-lines-high` QOM 属性定义 |
| `nvme.h` | 在 `FemuCtrl` 结构中添加 `gc_thres_lines`、`gc_thres_lines_high` 字段（或复用现有 `ssdparams` 字段的初始化方式） |
| `bbssd/ftl.c` | 修改 `ssd_init_params()`，从 `FemuCtrl` 读取阈值而非硬编码 |

## Superpowers 铁律适用

- **TDD（Path A）**：纯逻辑代码变更，先写单元测试验证阈值传递的正确性，再写实现。
- **verification-before-completion**：变更完成后必须运行 `verify.sh` 并通过 12/12 检查，同时在 QEMU 命令行中实际测试属性设置是否生效。

## CodeGraph 查询

变更前已通过以下 CodeGraph MCP 查询确认影响范围：
- `codegraph impact "ssd_init_params"` — 确认参数初始化链路的调用者
- `codegraph impact "ftl_thread"` — 确认 GC 决策函数 `should_gc()` 的调用上下文
