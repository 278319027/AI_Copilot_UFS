# SSD Firmware AI Copilot 方法论精要

> 完整文档见项目根目录 `SSD_Firmware_AI_Copilot_Methodology.md`

## 核心原则

```
Source Code > Design Docs > Memory > Prompt
```

1. **代码优先**：代码是真实实现，文档可能滞后，Memory 保存规则，Prompt 只是当前输入
2. **小任务原则**：每次 200~500 行，不扩大需求
3. **AI 辅助不替代**：人负责架构决策、设计确认、风险判断、最终责任
4. **CodeGraph 先查再改**：修改前必须查询影响范围，确认不会遗漏受影响的调用者
5. **设计方案确认门禁**：AI 输出设计方案后，必须包含「待人工确认清单」，人工确认后才编码

## 分歧决策矩阵

| 场景 | CodeGraph | Graphify | Memory 规则 |
|------|-----------|----------|-------------|
| "谁调用了这个函数？" | ✅ callers | — | — |
| "改了 X 影响谁？" | ✅ impact | — | — |
| "为什么这样设计？" | — | ✅ query/explain | — |
| "SSD 固件并发约束" | — | — | ✅ concurrency_rules |
| "NAND 时序参数" | — | — | ✅ knowledge |
| "相关概念间的关系" | ✅ callees | ✅ path | — |

## 标准 7 步流程

```
需求/设计文档
  │
  ▼
Step 1: AI 理解需求（基于文档 + Memory 规则）
  │
  ▼
Step 2: CodeGraph 查询                     ← MCP 工具
  │  codegraph callers <symbol>           ← 谁调用了？
  │  codegraph callees <symbol>           ← 调用了谁？
  │  codegraph impact <symbol>            ← 影响范围？
  │  codegraph explore <query>            ← 区域探索
  │  cscope -L2/-L4 <ptr/macro>           ← 函数指针/宏（补充）
  │
  ▼
Step 3: 输出设计方案（基于 CodeGraph 数据）
  │  ⚠️ 必须包含「待人工确认清单」
  │
  ▼
Step 4: 小步编码（200~500 行/任务）
  │
  ▼
Step 5: Review（CodeGraph 验证影响范围 + Review Skill）
  │
  ▼
Step 6: 测试建议（基于提示词库 + 测试场景清单）
  │
  ▼
Step 7: 人工确认 + 提交
```

### Step 3 设计方案确认门禁

AI 输出设计方案后，**必须**包含：

1. **架构假设**：设计中做了哪些假设（如：假设 GC 只在 victim line 满时触发）
2. **CodeGraph 影响完整性**：已确认的影响范围 vs 可能遗漏的调用链
3. **更简方案**：是否有更简单的实现方式

**人工确认所有 3 项后，才开始编码。设计是门禁，不是建议。**

## Step 6 测试场景清单（强制）

每个代码变更**必须**输出测试场景表：

| 场景 | 验证方法 | 预期结果 |
|------|----------|----------|
| 正常路径 | 编译/log | 具体值 |
| 边界条件 | 编译/log | 具体值 |
| 错误路径 | 编译/log | 具体值 |

没有测试框架不是借口 — 编译验证 + 日志检查 + 边界输入是最低要求。

## Agent 配置与 Context 管理

### Agent 超时处理

大文件任务（500+ 行）应拆分为 ≤100 行子任务。如遇到 Agent 反复超时：
1. 拆分任务为更小单元
2. 调整 `.opencode/oh-my-openagent.json` 中的 `staleTimeoutMs`
3. 使用 `task(task_id="ses_...")` 继续失败任务，不创建新任务

### Context 膨胀控制

- 分阶段压缩已在对话中确认的内容
- 同时运行的后台 agent ≤ 5 个
- 当 context 使用超过 70% 时，主动压缩历史内容
- 工具兼容性调试：同一问题最多 2 轮，2 轮失败后停止