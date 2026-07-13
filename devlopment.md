# 开发流程总结：双核 IPC 队列利用率监控

**日期**: 2026-07-14
**Change**: `dual-core-debug`
**工作流**: `comet-enhanced`（五阶段 Comet 工作流 + CodeGraph/Graphify 增强）

---

## 阶段总览

```
Open → Design → Plan → Build → Verify
```

---

## 1. Open 阶段

**目标**: 需求澄清、方案确定、创建 change 骨架和产物

### 调用的 Skill

| Skill | 用途 |
|-------|------|
| `comet-enhanced-open` | 启动 Open 节点，控制执行顺序 |
| `openspec-explore` | 探索问题空间，澄清需求 |
| `grill-me` | 5 维度深度追问（目标/范围/边界/风险/验收） |

### 工具调用

| 工具 | 用途 |
|------|------|
| `codegraph query` | 分析 dual_core 相关 12 个函数及调用链 |
| `graphify query` | 识别模块社区结构和跨边界依赖（55 节点） |
| `openspec instructions` | 获取 proposal/design/specs/tasks 的模板指令 |
| `write` | 创建 proposal.md、design.md、spec、tasks.md |
| `openspec status` | 验证产物状态（isComplete=true） |
| `workflow-state.mjs record` | 记录 open 阶段 evidence |
| `workflow-guard.mjs exit` | 退出守卫验证（检查 @ref 引用数、evidence 完整性） |

### 关键产出

- **proposal.md**: 问题背景、目标、范围、Capabilities
- **design.md**: 高层架构决策、双层策略（调用层 + 队列底层）
- **specs/ipc-queue-monitor/spec.md**: 4 个需求 + 验收场景
- **tasks.md**: 4 组 8 个任务（grill-me 后补充至 9 个）
- **exploration-evidence.md**: CodeGraph/Graphify 发现交叉引用
- **grill-me-summary.md**: 追问结论

### grill-me 关键结论

1. queue.c 底层增加 total_enqueue/dequeue 计数器（原设计只覆盖调用层）
2. 计数器仅内部统计，不影响非 IPC 使用者
3. 性能开销在 SSD 模拟器场景下可忽略

---

## 2. Design 阶段

**目标**: 技术设计细化，Design Doc，架构验证

### 调用的 Skill

| Skill | 用途 |
|-------|------|
| `comet-enhanced-design` | 启动 Design 节点 |
| `comet-design` | 深度设计流程控制 |
| `brainstorming` | 技术细节讨论（IpcMonitor_t 结构、控制开关、计数器类型） |

### 工具调用

| 工具 | 用途 |
|------|------|
| `codegraph query` | 影响分析：受影响函数 9 个、文件 4 个 |
| `workflow-handoff.mjs` | 生成 workflow 协议定义 |

### 关键产出

- **docs/superpowers/specs/2026-07-14-ipc-queue-monitor-design.md**: 完整技术设计文档
- **brainstorm-summary.md**: 设计方案检查点
- **design-codegraph-raw.json**: CodeGraph 影响分析
- **design-graphify-raw.json**: Graphify 架构验证

### 技术决策

1. `IpcMonitor_t` 作为独立子结构嵌入 `DualCore_t`
2. 峰值更新不受 `enable_trace` 控制，始终更新
3. 计数器类型 uint32_t
4. 满事件不限频，每次均 LOG_WARN

---

## 3. Plan 阶段

**目标**: 创建实施计划

### 调用的 Skill

| Skill | 用途 |
|-------|------|
| `comet-enhanced-plan` | 启动 Plan 节点 |
| `comet-build` | Plan 阶段标准流程 |
| `writing-plans` | 创建实施计划文档 |

### 关键产出

- **docs/superpowers/plans/2026-07-14-ipc-queue-monitor.md**: 实施计划

### 执行方式选择

| 选项 | 选择 |
|------|------|
| 工作区隔离 | 分支 `feature/20260714/dual-core-debug` |
| 执行方式 | `executing-plans`（当前会话直接执行） |
| TDD 模式 | `direct`（直接实现） |
| 代码审查 | `off` |

---

## 4. Build 阶段

**目标**: 编码实现

### 使用工具

| 工具 | 用途 |
|------|------|
| `edit` | 修改 4 个源文件（queue.h, queue.c, dual_core.h, dual_core.c） |
| `make` | 编译验证 |
| `git` | 分支管理、提交 |

### 改动详情

| 文件 | 改动 |
|------|------|
| `src/common/queue.h` | `Queue_t` 新增 `total_enqueue_cnt` / `total_dequeue_cnt` |
| `src/common/queue.c` | `queue_init()` 归零，`enqueue/dequeue` 自增 |
| `src/core/dual_core.h` | 新增 `IpcMonitor_t` 结构体，`DualCore_t` 嵌入 `ipc_mon` |
| `src/core/dual_core.c` | 4 个队列操作函数 + `print_stats` 增强 |

### 实现要点

- `dual_core_submit_enqueue()`: 满事件 → `submit_full_count++` + `LOG_WARN`
- `dual_core_complete_enqueue()`: 满事件 → `complete_full_count++` + `LOG_WARN`
- `dual_core_submit_dequeue()`: dequeue 后 → LOG_DEBUG（enable_trace）+ 峰值更新
- `dual_core_complete_dequeue()`: dequeue 后 → LOG_DEBUG（enable_trace）+ 峰值更新
- `dual_core_print_stats()`: 8 个新监控字段输出

---

## 5. Verify 阶段

**目标**: 验证实现、生成报告、分支处理

### 调用的 Skill

| Skill | 用途 |
|-------|------|
| `comet-enhanced-verify` | 启动 Verify 节点 |
| `comet-verify` | 标准验证流程 |
| `verification-before-completion` | 验证守则（evidence before claims） |
| `finishing-a-development-branch` | 分支处理决策 |

### 工具调用

| 工具 | 用途 |
|------|------|
| `make clean && make` | 完整重编验证（0 warning） |
| `git diff --stat` | 验证改动范围 |
| `workflow-state.mjs` | 记录 evidence |

### 验证结果

| 检查项 | 结果 |
|--------|------|
| tasks.md 全部完成 | ✅ 9/9 |
| 改动文件与 tasks 一致 | ✅ 4 文件 |
| 编译通过 | ✅ exit 0, 0 warning |
| 安全问题 | ✅ 无 |
| Scope drift | ✅ 0% (设计预测 4 文件，实际 4 文件) |

### 分支处理

分支 `feature/20260714/dual-core-debug` → **保持分支**（main 差异过大无法自动合并）

---

## 统计

| 指标 | 数值 |
|------|------|
| 修改源文件 | 4 |
| 完成任务 | 9 |
| CodeGraph 查询 | 4 次 |
| Graphify 查询 | 2 次 |
| Skill 加载 | 12 次 |
| 提交次数 | 3 |
| 编译验证 | 2 次（增量 + clean） |
