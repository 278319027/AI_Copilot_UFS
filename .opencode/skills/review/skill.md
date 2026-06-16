# Review Skill

## 职责

- Review 设计
- Review 代码
- Review 接口
- Review 状态机

- 产出 review.md ← 审查阶段持久化产出（模板见 spec_workflow.md §4）
## 输入

- proposal.md ← 变更意图、范围、验收标准
- design.md ← CodeGraph 查询结果已持久化于此
- 变更 diff
- 相关源代码
- 规则文件
## 输出

1. review.md ← 审查阶段完整产出（模板见 spec_workflow.md §4）
2. 问题列表
3. 风险等级
4. 影响范围（查证式，对照 design.md）
5. 修改建议
## 查证步骤（注：不再重新查询 CodeGraph）

> review.md 核心理念：对照 design.md 中已持久化的 CodeGraph 结果进行查证，而非重新查询。

1. 对照 design.md「CodeGraph 查询结果 → impact」查证变更文件的影响范围
2. 对照 design.md「CodeGraph 查询结果 → callers」查证修改的函数调用影响
3. 对照 design.md「CodeGraph 查询结果 → find_by_imports」查证头文件变更影响
4. 对照 design.md「CodeGraph 查询结果 → get_dependency_graph」查证模块边界
5. 仅当查证发现偏差时，才必须用 CodeGraph 重新查询偏差涉及的新增影响
6. 函数指针和宏的查证用 cscope 补充（codegraph_callers 覆盖有限）
## 检查重点

- 空指针
- 数组越界
- 资源泄漏
- 竞态条件
- 死循环
- 模块边界违反 ← 用 `check` 命令验证
|- 接口兼容性风险 ← 用 `codegraph_callers` 验证
- 函数指针调用遗漏 ← 用 cscope 补充验证

## 输出格式

- 按风险从高到低排序。
- 每条问题必须包含文件位置与原因。
- 给出可执行的修复建议。
- **每条 Review 必须注明 CodeGraph 验证结果。**

