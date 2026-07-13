# comet-enhanced 开发总结

## 一、目标

在 Comet 五阶段工作流（open/design/execute/verify/archive）上叠加硬性工具约束——grill-me 深度追问 + CodeGraph/Graphify 代码分析——替代纯 grep 搜索，提升固件项目的 AI 辅助编程效率和质量。

---

## 二、开发阶段

### 1. 需求分析与 Workflow Contract 设计

编写 `plan.json`，定义 `comet-five-phase-overlay` 的节点增强：open 节点加 grill-me Required Skill Call + 8 个自定义 output schema（codegraph-raw、graphify-raw、exploration-evidence、blast-radius 等），三层防线策略（CLI 安装检测 → raw JSON schema 验证 → @ref 交叉引用）。

### 2. comet-any 管线执行

`propose` → `init` → `authoring-record` ×3 lanes → `generate`。期间发现并修复 comet CLI 的两个 bug：`augmentations` 字段与 `normalizeBinding` 类型冲突导致 crash（将 schema 定义从 augmentations 移至 `outputSchemas`）；自定义 schema 缺少 `evidence`/`artifacts` 字段导致 generate 崩溃（按类型补全）。

### 3. Authoring 内容集成

提交 workflow-entry（Decision Core）、skill-core（节点 guidance）、skill-review 三个 lane 产出。发现 `isContentLeafPath()` 要求 `../` 前缀，修正路径格式。

### 4. Publish 流程打通

`eval-record` → `approve` → `publish run` → `distribute`。opencode 平台不支持 agents/hooks，修改 comet 安装包 `eval.js` 移除 `REQUIRED_FACTORY_CAPABILITIES` 中的这两个能力，bundle.yaml 中移至 optional。首次完整走通 `comet publish run --platform opencode`。

### 5. 工具定位重构

初版工具在决策之后运行（comet-open 完成 → grill-me → CodeGraph），只产出证据文件不参与决策。改为工具先行：open 阶段 CodeGraph/Graphify 探索代码 → openspec-explore 使用发现 → grill-me 引用发现追问。design 阶段 CodeGraph 影响分析 → brainstorming → Graphify 验证。execute 阶段 blast-radius 预检 → 超出预期暂停。verify 阶段交叉验证 → 对比设计预测。

### 6. 内容消费验证

标准 guard 只检查文件存在和 evidence 键名，不验证 agent 是否实际消费了工具发现。扩展 `workflow-guard.mjs`（+114 行），增加 `validateContentConsumption()` 函数：验证 exploration-evidence.md 的 @ref 引用数量、schemaEvidence 结构化值（非布尔）、自定义 completedChecks 检查点。guard 同时检查 Layer 1（文件存在）、Layer 2（evidence 键）、Layer 3（内容消费）。

### 7. 部署与测试

32 文件部署包，含 9 个 skills、6 个 scripts（544 行 guard）、8 个 reference、1 个 command、1 个 rule。one-click install.sh 脚本通过 base64 自解压，32/32 文件一致性校验通过。

---

## 三、最终功能

| 阶段 | 增强 | 工具角色 |
|------|------|----------|
| **open** | CodeGraph 先行探索代码结构 → openspec-explore 基于发现做需求澄清 → grill-me 引用 CodeGraph 发现追问 5 维度 | 决策输入 |
| **design** | CodeGraph 影响分析（预测波及文件/调用链）→ brainstorming 基于分析设计 → Graphify 验证架构一致性 | 决策输入 + 验证 |
| **execute** | 每个任务前 blast-radius 预检 → 超出预估范围则暂停报告 | 预检 |
| **verify** | CodeGraph 覆盖验证（对比设计预测 vs 实际变更）→ Graphify 检查文档同步 | 交叉验证 |

**三层防线**：文件存在 → evidence 结构化值验证 → 内容消费检测（@ref 引用数量、findingsExtracted 指标、consumed-* 检查点）。

**激活方式**：`/comet-enhanced` 创建新 change（写入增强状态），`/comet` 恢复时自动检测增强节点。

---

## 四、诚实局限

guard 验证的是"agent 记录了消费证据"，不是代码级强制执行。agent 仍可能运行工具后忽略发现——当前最强约束是 SKILL.md 中的显式操作指令和 guard 的结构化 evidence 检查。真正的闭环需要 guard 验证设计文档中是否引用了工具发现的具体内容。
