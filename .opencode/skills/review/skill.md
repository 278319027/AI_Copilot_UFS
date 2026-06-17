# Review Skill (Superpowers Adapter)

This skill is a **thin adapter** for the code-review workflow. It delegates the generic
review discipline to the [Superpowers](../superpowers/SKILL.md) skills framework
(`requesting-code-review` + `receiving-code-review`) and adds the SSD-firmware-specific
review checks on top.

## Architecture

```text
   ┌──────────────────────────────┐
   │  SSD domain review checks    │  ← THIS skill adds these
   │  - SSD concurrency rules     │
   │  - NVMe error handling       │
   │  - FTL/NAND invariants       │
   │  - specs/ delta vs baseline  │
   │  - CodeGraph查证式验证        │
   └─────────────┬────────────────┘
                 │ delegates to
   ┌─────────────▼────────────────┐
   │  Superpowers review          │  ← ../superpowers/{requesting,receiving}-code-review/
   │  - requesting-code-review    │
   │  - receiving-code-review     │
   │  - verification-before-completion │
   └──────────────────────────────┘
```

## 职责

- **Pre-review (SSD-specific):** assemble the review package from `proposal.md`,
  `design.md` (CodeGraph map), `tasks.md`, the diff, and the `specs/` increment.
- **Review (Superpowers):** invoke `requesting-code-review` to dispatch a fresh
  reviewer subagent with the precisely crafted context. Apply `receiving-code-review`
  when responding to feedback (no performative agreement, verify before implementing).
- **Post-review (SSD-specific):** produce `review.md` containing the
  `specs/` 增量核对表, the CodeGraph 查证式 findings, the SSD专项 check results
  (concurrency, NVMe, FTL/NAND), and the risk-graded issue list.

## 输入

- `proposal.md` ← 变更意图、范围、验收标准
- `specs/` 增量 ← `ADDED.md` / `MODIFIED.md` / `REMOVED.md`（行为变更声明）
- `design.md` ← CodeGraph 查询结果已持久化于此
- 变更 diff (`git diff BASE_SHA HEAD_SHA`)
- 相关源代码
- 规则文件（`.opencode/memory/`）

## 输出

1. `review.md` ← 审查阶段完整产出（含 `specs/` 增量核对表、SSD 专项检查、CodeGraph 查证）
2. 问题列表（按 Critical / Important / Minor 风险分级）
3. 风险等级
4. 影响范围（查证式，对照 `design.md`）
5. `specs/` 一致性结论（增量 vs 实际代码变更）
6. 修改建议
7. **Superpowers gate output** — `verification-before-completion` evidence for each
   claim of "no issue found".

## 标准流程

```text
1. 收集 Review 上下文 ─────────────────────────────────────┐
   │ proposal.md + design.md + tasks.md                    │
   │ git diff BASE_SHA HEAD_SHA → 保存为文件              │
   │ specs/ 增量（ADDED/MODIFIED/REMOVED）                 │
   │ CodeGraph 影响图（已在 design.md 中）                 │
   ↓                                                       │
2. 委托 Superpowers 调度审查 ──────────────────────────────┤
   │ Dispatch reviewer subagent via                        │
   │   .opencode/skills/superpowers/requesting-code-review/│
   │   → code-reviewer.md template                         │
   │ Pass: DESCRIPTION, PLAN_OR_REQUIREMENTS,              │
   │   BASE_SHA, HEAD_SHA                                  │
   │   + SSD domain constraints (concurrency, NVMe, FTL)   │
   │   + specs/ 增量核对任务                               │
   ↓                                                       │
3. 接收反馈 ──────────────────────────────────────────────┤
   │ Apply .opencode/skills/superpowers/receiving-code-review/
   │   1. READ complete feedback without reacting          │
   │   2. RESTATE requirement in own words                 │
   │   3. VERIFY against codebase reality + CodeGraph      │
   │   4. EVALUATE: technically sound for THIS codebase?   │
   │   5. RESPOND: technical acknowledgement or pushback  │
   │   6. IMPLEMENT one item at a time, test each          │
   │   (Never "You're absolutely right!" / "Great point!") │
   ↓                                                       │
4. 查证步骤（不再重新查询 CodeGraph，除非查证发现偏差）──┘
   ↓
5. 产出 review.md
   ↓
6. 偏差处理 / 修复循环
```

## 查证步骤（注：不再重新查询 CodeGraph）

> review.md 核心理念：对照 design.md 中已持久化的 CodeGraph 结果进行查证，而非重新查询。

1. 对照 `design.md`「CodeGraph 查询结果 → impact」查证变更文件的影响范围
2. 对照 `design.md`「CodeGraph 查询结果 → callers」查证修改的函数调用影响
3. 对照 `design.md`「CodeGraph 查询结果 → find_by_imports」查证头文件变更影响
4. 对照 `design.md`「CodeGraph 查询结果 → get_dependency_graph」查证模块边界
5. 对照 `specs/` 增量（ADDED/MODIFIED/REMOVED）查证代码变更是否覆盖所有行为声明
6. **仅当查证发现偏差时**，才必须用 CodeGraph 重新查询偏差涉及的新增影响
7. 函数指针和宏的查证用 cscope 补充（`codegraph_callers` 覆盖有限）

## SSD 专项检查（domain checks）

| 类别 | 检查项 | 规则文件 |
|------|--------|----------|
| **并发安全** | `volatile` 缺失、ISR/锁边界、原子性、DMA 一致性、多核可见性 | `memory/concurrency_rules.md` |
| **NVMe 错误处理** | 状态码完整、重试策略、断电恢复路径、`async` event 触发 | `knowledge/nvme_spec/error_handling.md` |
| **FTL 不变量** | LBA→PBA 映射原子性、GC 互斥、磨损均衡阈值、SLC Cache 状态 | `knowledge/nand_controller/` + `openspec/specs/ftl-mapping/spec.md` |
| **NAND 操作** | ECC 强度、弱块标记、坏块替换、Page/Block 操作原子性 | `openspec/specs/nand-driver/spec.md` |
| **资源管理** | 锁顺序、context 生命周期、内存屏障、错误路径回滚 | `memory/design_rules.md` |
| **API 接口** | 兼容性、错误码一致性、参数校验 | `memory/coding_style.md` |

## `specs/` 增量查证规则

- `ADDED.md` 中每个新增行为必须有对应代码实现
- `MODIFIED.md` 中每个修改行为必须有对应代码变更
- `REMOVED.md` 中每个移除行为必须有对应的代码删除或替换
- 若 `specs/` 增量与代码不一致 → 标记为偏差，写入 `review.md`「偏差说明」
- 若代码变更超出 `specs/` 增量范围 → 标记为范围外变更，提 issue

## 检查重点

- 空指针
- 数组越界
- 资源泄漏
- 竞态条件
- 死循环
- 模块边界违反 ← 用 `check` 命令验证
- 接口兼容性风险 ← 用 `codegraph_callers` 验证
- 函数指针调用遗漏 ← 用 cscope 补充验证
- **NVMe completion 错误码缺失**
- **FTL 映射表与 NAND 状态不一致**
- **ECC 校验失败后的恢复路径未覆盖**

## 输出格式

- 按风险从高到低排序（Critical → Important → Minor）。
- 每条问题必须包含文件位置与原因。
- 给出可执行的修复建议。
- **每条 Review 必须注明 CodeGraph 查证结果。**
- **必须输出 `specs/` 增量核对表（见 review.md 模板）。**
- **每条"无问题"声明必须附 Superpowers `verification-before-completion` 证据**——
  即对应 grep / codegraph 命令的实际输出（不是"应该没有"）。
