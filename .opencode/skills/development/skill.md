# Development Skill

## 职责

- 读取设计文档
- 读取现有代码
- 查询 CodeGraph ← 通过 ops-codegraph MCP 工具（当前部署于 FEMU `../femu/hw/femu/`）
- 分析影响范围
- 输出修改方案
- 生成代码
- 生成测试建议
- 产出 OpenSpec 工件 ← proposal.md、specs/ 增量、design.md、tasks.md（模板见 spec_workflow.md）

## 输入

- 模块设计文档
- 相关源文件
- 相关规则文件
- 相关调用关系 ← 通过 CodeGraph MCP 获取
- specs/baseline/ ← 当前行为基线（查询优先级：基线 → CodeGraph → 代码）

## 输出

0. proposal.md → 意图、范围、验收标准（模板见 spec_workflow.md §3）
1. specs/ 增量 → ADDED.md、MODIFIED.md、REMOVED.md（模板见 spec_workflow.md §5）
2. 需求理解摘要
3. 影响范围分析
4. 设计方案 → 输出 `design.md`（含 CodeGraph 查询结果，模板见 spec_workflow.md §1）
5. 编码清单 → 输出 `tasks.md`（模板见 spec_workflow.md §2）
6. 代码实现
7. 测试建议

## 标准流程

0. 理解需求 → 产出 proposal.md + specs/ 增量（声明意图、范围、行为变更）
1. **查询 CodeGraph** ← proposal.md 作为范围参考，深度照旧
2. 定位相关代码
3. 分析依赖关系
4. 输出设计方案 → 产出 `design.md`（含 CodeGraph 查询结果、待确认清单）
5. Design Gate 确认 → 人工逐项确认 design.md 后进入编码
6. 生成代码 → 按 `tasks.md` 粒度（200-500 行/任务）执行
7. 生成测试建议

## CodeGraph 查询步骤

在步骤 1 中，必须使用以下 MCP 工具查询影响范围：

| 场景 | MCP 工具 | 补充工具 |
|------|---------|---------|
| 谁调用了函数 X | `codegraph_callers` | cscope -L2 |
| 函数 X 调用了谁 | `get_callees` | cscope -L3 |
| 结构体 X 在哪里使用 | `symbol_search` + `find_by_imports` | cscope -L0 |
| 修改文件 X 的影响 | `impact` | cscope -L2 |
| 模块间依赖 | `get_dependency_graph` | — |
| #include 依赖 | `find_by_imports` | cscope -L8 |
| 搜索符号模式 | `find_by_pattern` | cscope -L6 |

**函数指针和宏的场景必须用 cscope 补充**：
```bash
cscope -d -L2 "func_ptr_name"     # 谁通过函数指针调用了
cscope -d -L3 "func_ptr_name"     # 函数指针指向哪些函数
cscope -d -L4 "MACRO_NAME"        # 宏在哪些地方被使用
cscope -d -L6 "pattern"           # 正则搜索模式
```

## 修改前必须查询

- 修改任何函数签名前 → `codegraph_callers`
- 修改任何结构体前 → `symbol_search` + `find_by_imports`
- 修改任何头文件前 → `find_by_imports`
- 新增模块前 → `get_dependency_graph`

## 约束

- 一次只处理一个明确任务。
- 不扩大需求。
- 不改不相关逻辑。
- 不引入不必要重构。
- **修改前必须查询 CodeGraph，确认影响范围。**
- **所有 OpenSpec 工件纳入 Git 版本管理。**
