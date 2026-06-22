# ADR 0003: TDD → test-after + 注入验证

- **状态**：Accepted
- **日期**：2026-06-22
- **决策者**：zsf 项目维护者
- **适用范围**：BUILD 阶段的代码验证

## 背景

经典 TDD（Red → Green → Refactor）要求"先写失败测试再写实现"。在纯软件层（Web/Node.js/通用算法）完全可行，但嵌入式固件开发有特殊挑战：

- **硬件依赖代码不可单测**：MMIO 寄存器读写、ISR 处理、DMA 描述符操作等直接操作硬件，无法在 Linux 主机上跑测试
- **QEMU 限制**：FEMU 的 QTest 不支持 NVMe Admin 命令提交，无法自动化测试
- **传统 Path B"编译即验证"**：把 `make clean && make` 当作验证是"语法正确性"，不等同于"行为正确性"

## 考虑过的选项

### 选项 A：保持经典 TDD

继续强制"先失败测试再写实现"。

**优点**：测试有效性最强（看到红→绿）。
**缺点**：
- 嵌入式固件开发者拒绝采纳
- Path B 的"编译即验证"实际是空头支票
- 70% 的方法论遵循度（2026-06-22 `add-gc-stats-flip` 变更验证）

### 选项 B：完全放弃测试纪律

实现代码，不要求测试。

**优点**：无脑快。
**缺点**：失去测试保护，回归风险高；违反 Superpowers 铁律。

### 选项 C：test-after + 注入验证（采用）

实现代码后补测试（test-after），但每个测试必须经过"注入验证"（bug 注入 → 测试失败 → 撤销 → 恢复通过）证明测试能抓住错误。

**优点**：
- 符合嵌入式开发者自然工作流
- 注入验证弥补了"从未看到测试失败"的可信度损失
- 通过 HAL 抽象（Business logic / Interface / Implementation 三层）最大化可测范围
- 保留 test-after 的低门槛

**缺点**：
- 注入验证增加工作量（每条测试路径一次）
- 仍有纪律风险（Deadline 压力下可能被跳过）

## 决策

采用选项 C。

```c
// 改进后的 BUILD 阶段流程
Implement → Compile → Write Tests → Verify Test Validity (注入验证) → Verify → Review
```

每条测试路径（至少：每个函数一条正常路径 + 一条错误路径）做一次注入验证。HAL 实现层（寄存器操作）不可注入，在 review.md 中标注原因。

## 后果

- 4 条 Iron Rule 中 "NO PRODUCTION CODE WITHOUT TESTS" 替代原 TDD 表述
- BUILD Gate 强制 AI 加载 test-after skill（带注入验证）
- 文档与 SKILL.md 全部统一为 test-after 措辞
- 硬件依赖代码用 HAL 分层策略处理

## 验证

- `superpowers-test-driven-development/SKILL.md` 完整重写
- `memory/testing_rules.md §6` 新增 test-after 规则
- `sd-firmware-copilot/SKILL.md` Iron Rule #2、Bootstrap 决策表、BUILD Gate checklist 全部更新
