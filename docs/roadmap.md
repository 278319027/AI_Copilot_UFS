# 实施路线图与指标

> 从方法论主文档移出的附录内容，记录项目进展与规划。

## 路线图

### Phase 1：建立理解能力 + CodeGraph + 硬件知识库 ✅ 已完成

| 任务 | 状态 | 产出 |
|------|------|------|
| 部署 CodeGraph | ✅ | ops-codegraph + ctags + cscope + Doxygen |
| 建立 Call / Struct / Dependency Graph | ✅ | 自动构建 |
| 建立硬件知识库 | ✅ | NAND/NVMe/Platform 知识模板 |
| 增强并发安全规则 | ✅ | concurrency_rules.md |
| 接入交叉编译 Hook | 🔲 | 待做 |

### Phase 2：建立规则体系 + 度量体系 ✅ 大部分完成

| 任务 | 状态 | 产出 |
|------|------|------|
| 编写 Memory V1 | ✅ | 6 个规则文件 |
| 拆分领域 Skill | 🔲 | NAND_driver/NVMe_cmd 等 |
| 建立效果度量 | 🔲 | 度量指标定义和收集 |
| 模型对比测试 | 🔲 | 不同规模模型对比 |

### Phase 3：建设 Skills + RAG ✅ 部分完成

| 任务 | 状态 | 产出 |
|------|------|------|
| sd-firmware-copilot Skill | ✅ | 含 CodeGraph + OpenSpec 流程（development 已合并入 sd-firmware-copilot） |
| review Skill | 🔲 | 含查证式验证（已合并入 sd-firmware-copilot） |
| RAG 知识库建设 | 🔲 | 文档+代码向量化检索 |
| 编译-修复闭环 | 🔲 | 自动编译→错误反馈→AI 修复 |

### Phase 4：试点实战 🔲 待做

| 任务 | 状态 | 产出 |
|------|------|------|
| 选择 3-5 个真实需求 | 🔲 | 接口层/命令处理类需求优先 |
| 模拟器验证集成 | 🔲 | QEMU NVMe 模拟或 Test Harness |
| 完整闭环跑通 | 🔲 | CodeGraph + sd-firmware-copilot + 编译 + 模拟 |
| 收集度量数据 | 🔲 | 开发时间、Review 时间、问题数量 |

### Phase 5：持续优化 🔲 待做

| 任务 | 状态 | 产出 |
|------|------|------|
| 模板库积累 | 🔲 | 常见模式模板和范例 |
| Hooks 自动化增强 | 🔲 | clang-format + cppcheck + 编译 + 测试 |
| 规则迭代 | 🔲 | 根据实战结果更新 Memory 和 Skill |
| QLoRA 微调评估 | 🔲 | 内部数据微调可行性评估 |

### Phase 6：OpenSpec 规格驱动升级 ✅ 已完成

| 任务 | 状态 | 产出 |
|------|------|------|
| 部署 OpenSpec CLI v1.4.1 | ✅ | `npm install -g @fission-ai/openspec` |
| OpenSpec 工作流 Skill | ✅ | `.opencode/skills/openspec-workflow/` |
| openspec/ 目录初始化与迁移 | ✅ | `openspec/{changes,specs,config.yaml}` |
| 5 个迁移 specs | ✅ | nvme-commands / ftl-mapping / nand-driver / error-handling / overview |

### Phase 7：Superpowers + 四工具架构升级 ✅ 已完成

| 任务 | 状态 | 产出 |
|------|------|------|
| 部署 Superpowers（10 子技能） | ✅ | `.opencode/skills/superpowers/` |
| TDD / 根因调查 / 验证后完成 铁律 | ✅ | 3 条强制铁律 |
| 评审双向规范 | ✅ | requesting / receiving code review |
| 并行 Agent 调度 | ✅ | subagent-driven / dispatching-parallel |
| KNOW→PLAN→BUILD→FEEDBACK 闭环 | ✅ | 文档同步更新 |

### Phase 8：四工具架构试点 🔲 待做

| 任务 | 状态 | 产出 |
|------|------|------|
| `/opsx:propose` 试点真实需求 | 🔲 | 验证 propose→apply→archive 闭环 |
| 强制 TDD（红→绿→重构） | 🔲 | 验证 test-driven-development |
| 强制 verification-before-completion | 🔲 | 验证完成纪律 |
| 收集 Superpowers 拦截数据 | 🔲 | TDD 覆盖率、verification 失败次数等 |

---

## 成功指标

| 指标 | 目标 |
|------|------|
| 开发效率 | 提升 20% |
| Review 时间 | 下降 30% |
| UT 覆盖率 | 提升 20% |
| 新人熟悉周期 | 下降 30% |

---

## 实施进度总览

| 步骤 / Phase | 内容 | 状态 |
|--------------|------|------|
| Step 1 | 引入 design.md + tasks.md | ✅ |
| Step 2 | 引入 proposal.md + review.md（查证式） | ✅ |
| Step 3 | 引入 specs/ 增量 + baseline + 归档 | ✅ |
| Phase 1 | 部署 OpenSpec CLI + 适配 Skill + openspec/ 迁移 | ✅ |
| Phase 2 | 部署 Superpowers + 升级为四工具架构 | ✅（当前） |
