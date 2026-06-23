---
name: opsx:verify
description: Stage 3.5 of OpenSpec 5-phase lifecycle — verify implementation matches spec delta (Requirements + Scenarios) and tasks.md checkboxes. Runs BEFORE /opsx:archive. Loads superpowers-verification-before-completion skill.
---

# /opsx:verify

验证**实现**与**规范**的一致性。**强制产物**：`openspec/changes/<id>/verify-report.md`（按 `.opencode/templates/verify-report.md` 模板生成）。

**用法**：`/opsx:verify [change-name]`

- 无参数：取唯一活跃变更
- `[change-name]`：指定变更

## 入口操作（**强顺序**）

1. `skill(name="superpowers-verification-before-completion")` — **必加载**（这条 skill 的整个目的就是"完成前验证"）
2. `skill(name="superpowers-test-driven-development")` — **必加载**（检查测试覆盖 + bug injection 证据）
3. `skill(name="openspec-apply")` — 取 change 上下文（contextFiles）
4. 按 skill 指引：解析 status → 跑 6 项检查 → 输出 verify-report.md

## 完整流程

1. `openspec status --change "<name>" --json` 解析 `applyRequires` / `contextFiles`
2. **必读** `contextFiles`（不只是 tasks.md，含 proposal/design/specs）
3. 跑 6 项验证检查（见下表）
4. **生成 `openspec/changes/<id>/verify-report.md`**（按 `.opencode/templates/verify-report.md` 模板）
5. **生成 `openspec/changes/<id>/review.md`**（占位即可，Review Gate 时填充）
6. 提示用户：6 项中任何失败 → 回 BUILD 阶段修复；全部通过 → 进入 `/opsx:archive`

## 6 项验证检查

| # | 检查项 | 命令 / 验证方法 | 通过标准 |
|---|--------|----------------|----------|
| 1 | `tasks.md` 完成度 | `grep -c '^\- \[x\]' openspec/changes/<id>/tasks.md` | 所有任务已勾选 |
| 2 | 编译通过 | `make clean && make -j$(nproc)` | 退出码 0，无 warning（warning 也需说明） |
| 3 | 测试通过 | `make test` + bug-injection 循环证据 | 退出码 0，单元 + 集成 + bug injection |
| 4 | Spec 一致性 | `openspec validate --strict --changes` | 无 violation |
| 5 | CodeGraph 一致 | `codegraph impact <修改文件>` 对比 design.md | 影响范围与设计阶段一致 |
| 6 | Graphify 完整 | `graphify diagnose multigraph` | `missing_endpoint_edges = 0`，`dangling_endpoint_edges = 0` |

## 额外检查（**必做**）

- 每个 `### Requirement: <name>` 都有至少一个对应的代码实现
- 每个 `#### Scenario: <name>` 都有对应测试用例（`tests/unit/` 或集成测试）
- **每个 public API 都有 bug-injection 证据**（per `superpowers-test-driven-development` Iron Rule）—— 不可覆盖路径在 verify-report.md 的 "不可覆盖路径" 段标注
- 不可覆盖的硬件依赖代码已在 `review.md` 标注原因

## 产物清单（**强校验**）

`/opsx:verify` 完成时必须存在：

1. `openspec/changes/<id>/verify-report.md` —— 6 项 gate 结果 + bug injection 覆盖率
2. `openspec/changes/<id>/review.md` —— **占位文件**（含基本信息 + 待 review 项 + 签字位）；Review Gate 时填充

`/opsx:archive` 会**强校验**这两个文件存在且 verify-report.md 中 6/6 PASS，否则拒绝 archive。

## 关键约束

- `/opsx:verify` **不替代 Review Gate**——仅作自动检查；正式 Review 仍需人类
- 6 项中任何失败 → **禁止**进入 `/opsx:archive`
- 生成的 `verify-report.md` 和 `review.md` 会被 `/opsx:archive` 一起归档到 `changes/archive/`
- **`/opsx:verify` 不可跳过**——任何 archive 前的变更必须先 verify

## 校验命令

```bash
openspec validate --strict --changes
openspec validate --strict --specs
make clean && make -j$(nproc) && make test
bash check_change.sh <change-name>
ls -la openspec/changes/<id>/verify-report.md  # 必须存在
ls -la openspec/changes/<id>/review.md         # 必须存在（占位即可）
```
