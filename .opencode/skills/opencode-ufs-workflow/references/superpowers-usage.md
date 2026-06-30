# Superpowers Skill Agent 使用指南

本文件面向 OpenCode agent，说明何时、如何加载各个 Superpowers skill。

---

## 加载方式

所有 Superpowers skill 通过 OpenCode `skill` 工具加载：

```python
skill(name="superpowers-<skill-name>")
```

> 注意：用户在聊天中可能说“用 TDD 做”或“帮我 review 一下”，agent 应识别意图并主动加载对应 skill。

---

## 各 skill 触发条件与调用

### `superpowers-brainstorming`

**触发时机**：
- 需求模糊
- 用户只说“我想做 XXX”但没有具体方案
- 需要比较多个技术选项

**调用**：

```python
skill(name="superpowers-brainstorming")
```

**衔接**：澄清后通常进入 `openspec-propose`。

---

### `superpowers-writing-plans`

**触发时机**：
- tasks.md / design.md 写完后需要评审
- 不确定任务拆分是否充分

**调用**：

```python
skill(name="superpowers-writing-plans")
```

**衔接**：PLAN 阶段使用，输出应反馈回 OpenSpec artifacts。

---

### `superpowers-test-driven-development`

**触发时机**：
- 开始写实现代码前
- 每个 task 的实施阶段

**调用**：

```python
skill(name="superpowers-test-driven-development")
```

**核心循环**：

```
RED   → 写测试，看失败
GREEN → 写最小实现，看通过
REFACTOR → 重构，保持通过
```

**衔接**：被 `openspec-apply-change` 在每个 task 中调用。

---

### `superpowers-using-git-worktrees`

**触发时机**：
- 开始 PATCH 阶段前
- 需要隔离实验性改动

**调用**：

```python
skill(name="superpowers-using-git-worktrees")
```

---

### `superpowers-verification-before-completion`

**触发时机**：
- 声称“完成”前
- VERIFY 阶段最后一步

**调用**：

```python
skill(name="superpowers-verification-before-completion")
```

**检查清单**：
- [ ] 所有 tasks.md 任务已完成
- [ ] build 通过
- [ ] 测试通过
- [ ] 诊断干净
- [ ] 回归检查通过

---

### `superpowers-requesting-code-review`

**触发时机**：
- REPORT 阶段
- 归档前

**调用**：

```python
skill(name="superpowers-requesting-code-review")
```

---

### `superpowers-finishing-a-development-branch`

**触发时机**：
- 所有任务完成且 review 通过后
- 需要决定 merge/PR/cleanup

**调用**：

```python
skill(name="superpowers-finishing-a-development-branch")
```

---

### `superpowers-systematic-debugging`

**触发时机**：
- 测试失败且原因不明
- 遇到 bug 或异常行为

**调用**：

```python
skill(name="superpowers-systematic-debugging")
```

**衔接**：调试结果可能反馈回 `tasks.md` 或 `design.md`。

---

### `superpowers-dispatching-parallel-agents`

**触发时机**：
- 多个 task 无依赖
- 需要并行探索/验证

**调用**：

```python
skill(name="superpowers-dispatching-parallel-agents")
```

---

### `superpowers-subagent-driven-development`

**触发时机**：
- 有明确 plan 需要批量执行
- 当前会话内委派多个子 agent

**调用**：

```python
skill(name="superpowers-subagent-driven-development")
```

---

## 与 OpenSpec 的衔接

```
SCOPE   → superpowers-brainstorming（如需要）
            ↓
PLAN    → superpowers-writing-plans
            ↓
PATCH   → openspec-apply-change
        → 每个 task 内调用 superpowers-test-driven-development
        → superpowers-using-git-worktrees（可选）
            ↓
VERIFY  → superpowers-verification-before-completion
            ↓
REPORT  → superpowers-requesting-code-review
        → superpowers-finishing-a-development-branch
```

---

## 错误处理

- skill 缺失 → 停止："Superpowers skill `<name>` 未安装。请检查 .opencode/skills/superpowers-*/SKILL.md。"
- skill 加载后行为异常 → 停止并报告异常信息，不绕过
