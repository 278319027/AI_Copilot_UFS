# Review Skill

## 职责

- Review 设计
- Review 代码
- Review 接口
- Review 状态机

## 输入

- 设计文档
- 变更 diff
- 相关源代码
- 规则文件
- CodeGraph 查询结果 ← 新增：用于验证影响范围

## 输出

1. 问题列表
2. 风险等级
3. 影响范围 ← 通过 CodeGraph 验证
4. 修改建议

## CodeGraph 验证步骤

在 Review 前，必须用 CodeGraph 验证影响范围：

1. 用 `impact` 查询变更文件的影响范围
2. 用 `get_callers` 验证修改的函数是否影响其他模块
3. 用 `find_by_imports` 验证修改的头文件影响范围
4. 用 `get_dependency_graph` 验证是否违反模块边界

如果影响范围超出预期，必须在 Review 输出中标注。

## 检查重点

- 空指针
- 数组越界
- 资源泄漏
- 竞态条件
- 死循环
- 模块边界违反 ← 用 `check` 命令验证
- 接口兼容性风险 ← 用 `get_callers` 验证
- 函数指针调用遗漏 ← 用 cscope 补充验证

## 输出格式

- 按风险从高到低排序。
- 每条问题必须包含文件位置与原因。
- 给出可执行的修复建议。
- **每条 Review 必须注明 CodeGraph 验证结果。**

