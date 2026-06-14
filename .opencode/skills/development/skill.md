# Development Skill

## 职责

- 读取设计文档
- 读取现有代码
- 查询 CodeGraph ← 通过 ops-codegraph MCP 工具（当前部署于 FEMU `../femu/hw/femu/`）
- 分析影响范围
- 输出修改方案
- 生成代码
- 生成测试建议

## 输入

- 模块设计文档
- 相关源文件
- 相关规则文件
- 相关调用关系 ← 通过 CodeGraph MCP 获取

## 输出

1. 需求理解摘要
2. 影响范围分析
3. 设计修改方案
4. 文件级修改计划
5. 代码实现
6. 测试建议

## 标准流程

1. 理解需求
2. **查询 CodeGraph** ← 新增步骤，在定位代码之前
3. 定位相关代码
4. 分析依赖关系
5. 输出设计方案
6. 生成代码
7. 生成测试建议

## CodeGraph 查询步骤

在步骤 2 中，必须使用以下 MCP 工具查询影响范围：

| 场景 | MCP 工具 | 补充工具 |
|------|---------|---------|
|| 谁调用了函数 X | `codegraph_callers` | cscope -L2 |
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

|- 修改任何函数签名前 → `codegraph_callers`
- 修改任何结构体前 → `symbol_search` + `find_by_imports`
- 修改任何头文件前 → `find_by_imports`
- 新增模块前 → `get_dependency_graph`

## 约束

- 一次只处理一个明确任务。
- 不扩大需求。
- 不改不相关逻辑。
- 不引入不必要重构。
- **修改前必须查询 CodeGraph，确认影响范围。**

