# SSD 固件 AI 辅助编程方法论

## 1. 目标

面向大型嵌入式固件项目，建立一套基于本地大模型 `Qwen 27B` + `OpenCode Agent` 的 AI 辅助编程体系，用于提升以下能力：

- 理解模块设计
- 理解现有代码
- 生成实现方案
- 辅助编码
- 辅助 Review
- 辅助测试设计

最终目标是：

- 提升开发效率
- 提升代码一致性
- 降低 Review 成本
- 缩短新人上手周期
- 降低架构演化成本

## 2. 核心原则

### 2.1 代码优先

优先级顺序：

```text
Source Code
>
Design Docs
>
Memory
>
Prompt
```

含义是：

- 代码是真实实现
- 文档描述事实，但可能滞后
- Memory 保存团队规则，不替代设计
- Prompt 只是当前任务输入，不应成为长期知识源

### 2.2 CodeGraph 优先

AI 先理解系统结构，再生成代码。

必须优先建立：

- 调用关系
- 依赖关系
- 引用关系
- 模块关系

AI 不能从文本直觉直接生成大段代码，必须先建立代码图谱认知。

### 2.3 小任务原则

禁止让 AI 一次性实现整个模块。

推荐粒度：

- 一个接口
- 一个状态机
- 一个功能点
- 一个子模块
- 一个文件

任务规模建议控制在 `200~500 行` 以内，复杂模块拆成多个迭代完成。

### 2.4 规则与设计分离

- `docs/`：记录项目事实与设计
- `.opencode/memory/`：记录规则、风格、约束
- `.opencode/skills/`：记录工作流和流程能力

三者必须独立维护，不能混在一起。

### 2.5 AI 辅助，不替代人

AI 负责：

- 理解
- 分析
- 生成
- Review
- 测试建议

人负责：

- 架构决策
- 设计确认
- 代码确认
- 风险判断
- 最终责任

## 3. 总体架构

建议形成如下系统结构：

```text
Qwen3-27B
    -> OpenCode Agent
        -> CodeGraph
        -> Docs
        -> Memory
        -> Skills
        -> Source Code
```

其中：

- `CodeGraph` 是 AI 理解工程的基础设施
- `Docs` 是项目事实记录
- `Memory` 是项目规则与约束
- `Skills` 是可复用工作流
- `Source Code` 是最终真实实现

## 4. 四大核心组成

### 4.1 Source Code

代码库是最大的知识源。AI 必须能访问：

- 全部源代码
- 头文件
- 构建脚本
- 配置文件
- 平台相关定义

推荐目录示例：

```text
source/
  app/
  service/
  driver/
  os/
  common/
  platform/
```

要求：

- AI 在写代码之前，必须先定位相关文件
- 必须识别调用链
- 必须分析上下游依赖
- 必须确认修改影响范围

### 4.2 CodeGraph

#### 定位

CodeGraph 是整个系统的基础设施，优先级最高。

#### 目标

建立以下关系图：

- Call Graph
- Struct Graph
- Dependency Graph
- Module Graph

#### AI 必须具备的能力

AI 应能回答：

- 谁调用了这个函数
- 这个函数调用了谁
- 这个结构体在哪里使用
- 改这个接口会影响哪些模块
- 状态机入口在哪里

#### 工具实现

CodeGraph 通过以下工具组合实现：

| 工具 | 用途 | 覆盖场景 | 安装 |
|------|------|----------|------|
| **ops-codegraph** | 主工具：调用图/依赖图/影响分析，30+ MCP 工具 | ~80% | `npm install -g @optave/codegraph` |
| **ctags + cscope** | 补充工具：函数指针/宏查询（tree-sitter 盲区） | ~15% | `apt install universal-ctags cscope` |
| **Doxygen** | 可视化：交互式 HTML 文档+图（按需） | ~5% | `apt install doxygen graphviz` |

ops-codegraph 通过 MCP 协议与 OpenCode Agent 集成，AI 可直接调用 `get_callers`、`get_callees`、`impact` 等 30+ 工具。

C 语言特殊限制：tree-sitter 无法解析函数指针调用和宏展开，这些场景必须用 cscope 补充。

#### 建设顺序

1. Call Graph（ops-codegraph 自动构建）
2. Struct Graph（ctags 索引）
3. Dependency Graph（ops-codegraph 自动构建）

#### 安装与配置

详见 [CodeGraph 部署与使用教程](./CodeGraph_Setup.md)。

### 4.3 Docs 体系

Docs 记录项目事实，不是 AI 配置。

推荐目录：

```text
docs/
  SAD/
  SDD/
  ICD/
  TEST/
```

#### SAD

Software Architecture Design，记录：

- 模块划分
- 分层关系
- 模块职责

#### SDD

Software Design Document，记录：

- 接口
- 状态机
- 流程
- 约束

#### ICD

Interface Control Document，记录：

- API
- 消息
- 数据结构
- 模块边界

#### TEST

测试设计文档，记录：

- 测试策略
- 覆盖要求
- 验收标准

### 4.4 Memory 体系

Memory 保存项目规则，不保存项目设计本身。

推荐目录：

```text
.opencode/memory/
  architecture.md
  coding_style.md
  design_rules.md
  review_rules.md
  testing_rules.md
```

#### architecture.md

记录：

- 模块边界
- 分层规则
- 依赖规则

例如：

- 禁止跨层调用
- 禁止访问其他模块私有数据

#### coding_style.md

记录：

- 命名规范
- 文件规范
- 接口规范

#### design_rules.md

记录：

- 状态机设计规范
- Context 设计规范
- 资源管理规范

#### review_rules.md

记录：

- Review 检查项
- 风险等级定义

#### testing_rules.md

记录：

- 单元测试要求
- 覆盖率要求
- Mock 规范

## 4.5 硬件知识库

> 新增。来源：《固件AI辅助编程探索》第 7.1.2 节 P0 建议。

硬件知识库存储 AI 无法从代码推断的隐性知识，包括寄存器地址、配置顺序、时序约束等。

推荐目录：

```text
.opencode/knowledge/
  nand_controller/
    registers.md          # NAND 控制器寄存器定义和配置顺序
    operations.md         # NAND 操作序列和命令码
    constraints.md        # 时序约束、并发约束、错误恢复
  nvme_spec/
    admin_commands.md     # NVMe Admin 命令集和数据结构
    io_commands.md        # NVMe I/O 命令集
  platform/
    memory_map.md         # 系统内存映射、中断分配、时钟树
    power_states.md       # 电源状态转换
```

#### 知识库原则

1. **只包含隐性知识**：寄存器地址、配置顺序、时序参数 ✅；函数签名、数据结构定义 ❌
2. **每个文件不超过 2000 行**：控制 token 开销
3. **按 Skill 粒度拆分**：按需注入而非全量注入
4. **版本绑定**：知识文件必须标注适用的芯片型号和固件版本

#### 填写说明

每个模板文件包含填写说明和占位符，使用时需替换为实际芯片的值。
不同芯片型号有不同的填写文件。

## 5. Skills 体系

Skill 尽量少而精，只保留两个核心能力：

```text
skills/
  development/
  review/
```

### 5.1 development

职责：

- 读取设计文档
- 读取代码
- 查询 CodeGraph
- 分析影响范围
- 输出修改方案
- 生成代码
- 生成测试建议

标准流程：

```text
Step1 理解需求
Step2 定位相关代码
Step3 分析依赖关系
Step4 输出设计方案
Step5 生成代码
Step6 生成测试建议
```

### 5.2 review

职责：

- Review 设计
- Review 代码
- Review 接口
- Review 状态机

重点检查：

- 空指针
- 数组越界
- 资源泄漏
- 竞态条件
- 死循环
- 模块边界违反
- 接口兼容性风险

## 6. 标准工作流

### 6.1 需求理解

输入：

- 模块设计文档
- 相关现有代码
- 相关规则
- 相关 CodeGraph

输出：

- 需求摘要
- 关键接口
- 风险点
- 缺失信息

### 6.2 影响分析

AI 必须先分析：

- 谁会调用这个接口
- 这个接口依赖谁
- 这个结构体被谁引用
- 状态机入口在哪
- 修改会影响哪些文件

### 6.3 设计方案输出

输出内容建议包括：

- 修改文件列表
- 接口方案
- 数据结构方案
- 状态机方案
- 错误处理策略
- 风险项
- 测试建议

### 6.4 代码生成

原则：

- 一次只做一个明确任务
- 不改不相关逻辑
- 不扩大需求
- 不引入不必要重构

### 6.5 Review

Review 的重点不是语法，而是工程风险：

- 边界条件
- 并发问题
- 资源释放
- 兼容性
- 可维护性

### 6.6 测试建议

AI 需要给出：

- UT 建议
- 边界条件测试
- 异常路径测试
- 回归测试建议

## 7. Hooks 自动化

建议把 AI 流程和工程 hook 结合起来。

### build hook

- 自动编译
- 自动链接

### format hook

- `clang-format`

### static check hook

- `cppcheck`
- 静态分析工具

### test hook

- 单元测试
- 覆盖率统计

这样可以把 AI 的输出自动收敛到工程标准里。

## 8. 推荐目录结构

```text
Project/
  source/
  docs/
    SAD/
    SDD/
    ICD/
    TEST/
  templates/
  scripts/                     # 工具脚本
    install_codegraph.sh       # 一键安装 CodeGraph 工具链
    init_codegraph.sh          # 项目初始化（构建索引）
    install_git_hook.sh        # Git Hook 安装
    update_codegraph.sh        # 增量更新索引（--full 全量更新）
  .codegraph/                  # CodeGraph 配置
    config.json                # ops-codegraph 排除目录配置
    Doxyfile                   # Doxygen 配置
  .opencode/
    opencode.json                   # opencode MCP 配置（项目根目录）
    memory/
      architecture.md          # 分层规则 + CodeGraph 查询规则
      coding_style.md
      concurrency_rules.md     # 并发安全规则 ✨新增
      design_rules.md
      review_rules.md
      testing_rules.md
    knowledge/                 # 硬件知识库 ✨新增
      nand_controller/
        registers.md
        operations.md
        constraints.md
        ecc.md                # ECC 纠错与坏块管理
      nvme_spec/
        admin_commands.md
        io_commands.md        # I/O 命令集
        error_handling.md     # 错误处理与状态码体系
      platform/
        memory_map.md
        power_states.md       # 电源状态转换与约束
    skills/
      development/
      review/
      drawio-flowchart/
```

## 9. 实施路线图

### Phase 1：建立理解能力 + CodeGraph + 硬件知识库（1-2 周） ✅ 已完成

| 任务 | 状态 | 产出 |
|------|------|------|
| 部署 CodeGraph | ✅ 完成 | ops-codegraph + ctags + cscope + Doxygen |
| 建立 Call Graph | ✅ 完成 | `codegraph build` 自动构建 |
| 建立 Struct Graph | ✅ 完成 | ctags 自动索引 |
| 建立 Dependency Graph | ✅ 完成 | ops-codegraph 自动构建 |
| ✅ 接入交叉编译 Hook | 🔲 待做 | 见《可行性报告》P0 建议 |
| ✅ 建立硬件知识库 | ✅ 完成 | NAND/NVMe/Platform 知识模板 |
| ✅ 增强并发安全规则 | ✅ 完成 | concurrency_rules.md |
| 让 OpenCode 能访问源码 | ✅ 完成 | MCP 服务器配置 |

### Phase 2：建立规则体系 + 度量体系（3-4 周）

| 任务 | 状态 | 产出 |
|------|------|------|
| ✅ 编写 Memory V1 | ✅ 完成 | coding_style + design_rules + review_rules + testing_rules + concurrency_rules |
| 拆分领域 Skill | 🔲 待做 | NAND_driver/NVMe_cmd/buffer_management 等 |
| ✅ 建立效果度量 | 🔲 待做 | 度量指标定义和收集 |
| 模型对比测试 | 🔲 待做 | Qwen 27B vs 更大模型对比 |

### Phase 3：建设 Skills + RAG（5-6 周）

| 任务 | 状态 | 产出 |
|------|------|------|
| development Skill V1 | ✅ 完成 | 含 CodeGraph 查询步骤 |
| review Skill V1 | ✅ 完成 | 含 CodeGraph 验证步骤 |
| ✅ RAG 知识库建设 | 🔲 待做 | 文档+代码向量化检索 |
| 编译-修复闭环 | 🔲 待做 | 自动编译→错误反馈→AI 修复 |

### Phase 4：试点实战（7-10 周）

| 任务 | 状态 | 产出 |
|------|------|------|
| 选择 3-5 个真实需求 | 🔲 待做 | 优先选择接口层/命令处理类需求 |
| ✅ 模拟器验证集成 | 🔲 待做 | QEMU NVMe 模拟或 Test Harness |
| 完整闭环跑通 | 🔲 待做 | CodeGraph + Development + Review + 编译闭环 + 模拟验证 |
| 收集度量数据 | 🔲 待做 | 开发时间、Review 时间、问题数量 |

### Phase 5：持续优化（长期）

| 任务 | 状态 | 产出 |
|------|------|------|
| 模板库积累 | 🔲 待做 | 常见模式的模板和范例 |
| ✅ Hooks 自动化增强 | 🔲 待做 | clang-format + cppcheck + 编译 + 测试 |
| ✅ 规则迭代 | 🔲 待做 | 根据实战结果更新 Memory 和 Skill |
| QLoRA 微调评估 | 🔲 待做 | 在内部数据上评估微调可行性 |

## 10. 成功指标

建议用以下指标衡量效果：

- 需求开发时间
- Review 时间
- UT 覆盖率
- 新人熟悉时间
- 缺陷率

目标可以设为：

- 开发效率提升 `20%`
- Review 时间下降 `30%`
- UT 覆盖率提升 `20%`
- 新人熟悉周期下降 `30%`

## 11. 最终形态

AI 系统只关注三类信息：

```text
设计
-> docs/

规则
-> memory/

代码
-> source/
+ CodeGraph
```

通过两个核心 Skill 完成辅助开发：

- `development`
- `review`

最终实现流程：

```text
需求
-> 设计理解
-> 代码定位
-> 方案生成
-> 代码生成
-> Review
-> 测试建议
```

形成稳定、可维护、可推广的 AI 辅助编程体系。

## 12. 建议补强项

为了更像企业级方案，建议再补 4 个关键点：

1. 增加文档版本绑定
   - 每次 AI 生成代码都要绑定文档版本号，避免文档和代码漂移。
2. 增加变更粒度约束
   - 一次只允许一个功能点，避免 AI 改动过大。
3. 增加验收标准模板
   - 每个需求必须有输入、输出、异常、边界、回归五类验收项。
4. 增加失败回退机制
   - 如果 AI 输出不通过，必须回退到文档层重新澄清，而不是盲目重试生成。

