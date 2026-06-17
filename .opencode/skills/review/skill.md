---
name: review
description: FEEDBACK 阶段：代码审查 + 领域专项检查，委托 Superpowers requesting-code-review
---

# 审查流程

本 Skill 是 FEEDBACK 阶段的**薄适配器**。通用审查纪律委托给 [Superpowers](../superpowers/SKILL.md)（`requesting-code-review` + `receiving-code-review`），SSD 领域专项检查在本文件定义，OpenSpec Delta Spec 核对按 `sd-firmware-copilot/rules/spec_rules.md` 执行。

## 职责

- **Pre-review（SSD 领域）：** 组装审查包（proposal + design + tasks + diff + specs 增量）。
- **Review（Superpowers 纪律）：** 调度审查子代理，强制 `receiving-code-review` 接收流程。
- **Post-review（SSD 领域）：** 产出 `review.md`，含查证式核对表 + 风险分级 + 偏差说明。

## 审查前

- 确认 `tasks.md` 所有 task 已标记 `[x]`
- 运行 `verify.sh`（编译 + 测试）确认通过
- 收集审查上下文：
  - `proposal.md` + `design.md` + `tasks.md`
  - `git diff BASE_SHA HEAD_SHA` 保存为文件
  - `openspec/changes/{id}/specs/` 增量（ADDED/MODIFIED/REMOVED）
  - `design.md` 中持久化的 CodeGraph 影响图

## 审查内容

1. **通用工程检查**（委托 Superpowers `requesting-code-review`）
   - 派发 reviewer 子代理，传入 DESCRIPTION / PLAN / BASE_SHA / HEAD_SHA
   - 子代理报告必须含测试命令 + 实际输出

2. **SSD 固件领域专项检查**（本 Skill 负责）
   - 并发安全：volatile 缺失、ISR/锁边界、原子性、DMA 一致性 → `.opencode/memory/concurrency_rules.md`
   - NVMe 错误处理：状态码完整、重试策略、断电恢复 → `openspec/specs/nvme-commands/`
   - FTL 不变量：LBA↔PBA 原子性、GC 互斥、磨损均衡 → `openspec/specs/ftl-mapping/`
   - NAND 操作：ECC、弱块标记、坏块替换 → `openspec/specs/nand-driver/`
   - 资源管理：锁顺序、context 生命周期、内存屏障 → `.opencode/memory/design_rules.md`

3. **OpenSpec Delta Spec 一致性检查**（本 Skill 负责）
   - `ADDED.md` 每个行为必须有代码实现
   - `MODIFIED.md` 每个修改必须有代码变更
   - `REMOVED.md` 每个移除必须有代码删除/替换
   - 代码变更超出 specs 增量 → 标记为「范围外变更」
   - specs 增量与代码不一致 → 标记为「偏差」

4. **查证式核对**（不重新查询 CodeGraph）
   - 对照 `design.md` 中已持久化的 impact / callers / find_by_imports 查证
   - 仅当查证发现偏差时，才用 CodeGraph 重新查询新增影响
   - 函数指针 / 宏 用 cscope 补充查证

## 接收反馈（Superpowers receiving-code-review）

子代理反馈返回后，按 6 步处理：

1. **READ** — 完整阅读反馈，不立即反应
2. **RESTATE** — 用自己的话复述要求
3. **VERIFY** — 对照代码 + CodeGraph 查证
4. **EVALUATE** — 评估对**本项目**是否技术合理
5. **RESPOND** — 技术性确认或反对（禁用「你说得对」式空话）
6. **IMPLEMENT** — 一次一个，逐项测试

## 审查后

- **通过：** 执行 `openspec archive` 合并 specs 增量到基线，commit 格式 `chore(spec): archive {change-id}`
- **不通过：** 修复后重新审查（回到「审查前」步骤）

## 关键约束

- **每条问题必须含文件位置 + 原因 + 可执行修复建议**
- **按风险分级**：Critical → Important → Minor，从高到低排序
- **每条「无问题」声明必须附** `verification-before-completion` 证据（grep / codegraph 命令实际输出）
- **每条 Review 必须注明 CodeGraph 查证结果**（对照 `design.md`，不重新查询）
- **必须输出 specs 增量核对表**（review.md 模板固定章节）
