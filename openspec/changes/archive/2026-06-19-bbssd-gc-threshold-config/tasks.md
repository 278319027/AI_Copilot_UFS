## 1. TDD — 编写失败测试

- [ ] 1.1 在 `tests/unit/`（或合适位置）添加测试：验证 `ssd_init_params()` 在未配置属性时使用默认值 20/10
- [ ] 1.2 添加测试：验证 `ssd_init_params()` 正确读取并应用自定义阈值（如 50/30）
- [ ] 1.3 添加测试：验证 `gc_thres_lines=0` 时被 clamp 到 1 并触发警告
- [ ] 1.4 添加测试：验证 `gc_thres_lines_high > gc_thres_lines` 时自动调整并触发警告

## 2. QOM 属性定义（femu.c）

- [x] 2.1 在 `femu.c` 的 `FemuCtrl` 属性表中添加 `gc-thres-lines`（`uint32`，默认 0 表示未设置）
- [x] 2.2 添加 `gc-thres-lines-high`（`uint32`，默认 0 表示未设置）
- [x] 2.3 在属性定义注释中注明默认值来源（20% / 10% of total lines）

## 3. 数据结构准备（nvme.h）

- [x] 3.1 在 `struct FemuCtrl` 中添加 `uint32_t gc_thres_lines` 和 `uint32_t gc_thres_lines_high` 字段（或复用现有机制）
- [x] 3.2 确认字段初始化位置（`femu_realize()` 或设备 reset）

## 4. FTL 初始化修改（bbssd/ftl.c）

- [x] 4.1 修改 `ssd_init_params()`：从 `FemuCtrl` 读取阈值字段
- [x] 4.2 实现默认值回退逻辑：若属性值为 0，则按原有比例（20% / 10%）计算
- [x] 4.3 实现 clamp 验证：下限 1，上限 `spp->tt_lines - 1`
- [x] 4.4 实现 high <= normal 检查：若违反则调整 high = normal - 1
- [x] 4.5 在所有验证失败路径打印 `warn_report()` 或 `qemu_log()` 警告
- [x] 4.6 移除原有硬编码比例计算代码

## 5. 验证与清理

- [x] 5.1 编译 femu 项目，确认无编译警告/错误
- [x] 5.2 运行 `bash verify.sh`，确认 12/12 通过
- [x] 5.3 在 QEMU 命令行中实测：`-device femu,gc-thres-lines=50,gc-thres-lines-high=30`
- [x] 5.4 运行 `graphify update .` 更新知识图谱
- [x] 5.5 在 `tasks.md` 中勾选所有完成的任务

## 6. 代码审查与修复

### 审查结果（FEEDBACK 阶段）
- [x] 6.1 代码审查完成
- [x] 6.2 修复 `printf()` → `warn_report()`（5 处）
- [x] 6.3 修复边界条件：`gc_thres_lines <= 2` 时显式处理
- [x] 6.4 修复 `spp->gc_thres_pcent` 在绝对值路径下的未初始化问题
- [x] 6.5 添加 `qemu/error-report.h` include
- [x] 6.6 重新编译验证通过（0 警告/错误）

### 审查发现的问题
| 严重度 | 问题 | 修复方式 |
|--------|------|----------|
| Important | 使用 `printf()` 而非 QEMU 日志系统 | 替换为 `warn_report()` |
| Important | `gc_thres_lines=1` 时 high 阈值会与 normal 相等 | 添加 `<=2` 显式分支 |
| Important | 绝对值路径下 `gc_thres_pcent` 未初始化 | 在赋值时同步计算 |
| Minor | `int` vs `int32_t` 类型语义 | 保持与现有代码一致，未修改 |

### 提交记录
- femu: `d902ef160` — `fix(bbssd): address code review feedback for GC threshold config`
