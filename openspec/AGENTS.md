# OpenSpec AGENTS.md — AI Agent 行为指南

> 本文件是 OpenSpec 框架约定在 **本项目**（`zsf` —— SSD 固件 AI 辅助编程）落地的 AI Agent 行为规范。
> 与仓库根 `AGENTS.md` 互补：根 `AGENTS.md` 描述项目级 OpenCode 启动配置；本文件描述 **OpenSpec 规格层** 的 AI 操作流程。
> 与 `sd-firmware-copilot/SKILL.md` 互补：那个 skill 描述 **项目级流水线**（KNOW→PLAN→BUILD→FEEDBACK）；本文件只关注 OpenSpec 本身的 AI 使用约定。

---

## 1. 启动时（每次 session / 新需求）— 必做

1. **读仓库根 `AGENTS.md`** —— 了解 `.opencode/` 归属规则、`FEMU_ROOT` 解析、MCP 配置、OpenSpec 流程规则。
2. **加载 Skill Bootstrap**（按 `AGENTS.md § Skill 自动触发` 表格）：
   - `superpowers-using-superpowers` —— 工程纪律总入口
   - `openspec-workflow` —— 5 phase 概念层
3. **检查环境**：
   ```bash
   bash scripts/verify.sh                                                       # 15/15 通过
   OPENSPEC_TELEMETRY=0 openspec validate --strict --specs              # baseline 有效
   ```

---

## 2. 接到需求时 — 决策流程

按以下顺序判断使用哪个 OpenSpec 命令：

```
新需求
  │
  ├─ 需求模糊，需要访谈澄清 ──→ /opsx:propose <name> "intent"
  │                                  （触发苏格拉底式访谈 + 生成 4 artifacts）
  │
  ├─ 需求清晰，跳过访谈 ──────→ /opsx:ff <name> "intent"
  │                                  （一次性建空骨架 + 生成 4 artifacts）
  │
  ├─ 我想自己填/分步生成 ─────→ /opsx:new <name>
  │                                  （仅建空骨架）→ /opsx:continue
  │
  ├─ 调研/对比方案（不写代码） → /opsx:explore [topic]
  │                                  （读 specs / CodeGraph / Graphify / 写 design.md 思考段）
  │
  └─ 实施已有 tasks.md ──────→ /opsx:apply [name]
                                     （按 tasks 顺序逐项实施 + 勾选 - [x]）
```

完成前：先 `/opsx:verify` → 再 `/opsx:archive`。
积压多个已完成变更：用 `/opsx:bulk-archive`。

---

## 3. 创建新变更（propose / new / ff）— 必须遵守

1. **搜索现有 work**（避免重复）：
   ```bash
   openspec list --json                              # 活跃变更
   openspec list --specs                             # baseline capabilities
   rg "lba|pba|nand|nvme" openspec/specs/ openspec/changes/  # 概念层全文
   ```
2. **决定 scope**：
   - **新建 capability**（之前无相关 spec）→ 在 `openspec/changes/<id>/specs/<new-cap>/spec.md` 写 ADDED
   - **修改现有 capability**（已有 spec）→ 在对应 `specs/<existing-cap>/spec.md` 写 ADDED / MODIFIED / REMOVED / RENAMED
3. **Pick 唯一 `change-id`**：
   - kebab-case（小写 + 连字符）
   - 动词开头：`add-` / `update-` / `remove-` / `refactor-` / `fix-`
   - 与 `openspec/changes/` 和 `openspec/changes/archive/` 不冲突
4. **Scaffold artifacts**：
   - `proposal.md` —— 必填（动机 / 范围 / Non-goals / 影响的能力）
   - `specs/<cap>/spec.md` —— 必填（delta: `## ADDED` / `MODIFIED` / `REMOVED` Requirements）
   - `design.md` —— 跨文件/架构变更必填；单文件 bugfix 可豁免
   - `tasks.md` —— 必填（200-500 行/任务，含 spec 引用 + 测试计划 + 验证命令）
   - `.openspec.yaml` —— 可选（变更元数据）
5. **Delta 格式硬约束**：
   - 标题三个 `###`（Requirement）/ 场景四个 `####`（Scenario）——**4 个 # 是硬要求，3 个 # 静默失败**
   - 规范词：`SHALL` / `MUST` / **WHEN** / **THEN**；避免 `should` / `may`
   - 每个 Requirement 至少 1 个 Scenario；每个 Scenario 是潜在测试用例
6. **校验**：
   ```bash
   openspec validate --strict --changes              # 必须在 archive 前通过
   bash scripts/check_change.sh <change-name>                # 项目级额外检查
   ```

---

## 4. 实施变更（apply）— 5 级门禁

每个变更必须经过 5 级门禁，**门禁不可跳级**（除豁免规则外）：

| 门禁 | 输入工件 | 通过标准 | 校验命令 |
|------|----------|----------|----------|
| **Proposal Gate** | `proposal.md` | 动机 / 范围 / Non-goals / 影响 capability 明确 | `openspec status --change "<name>" --json` |
| **Design Gate** | `design.md` + `tasks.md` | CodeGraph 影响分析 / 模块边界 / 并发 / 错误路径 / 任务粒度 | 同上 |
| **BUILD Gate** | 加载 3 个 Superpowers skill | `superpowers-verification-before-completion` + `superpowers-executing-plans` + `superpowers-test-driven-development` 已 `skill()` 加载 | `skill()` 工具调用记录 |
| **Review Gate** | 编码完成 + `review.md` | 人类审查员签字（AI 不能自批） | `make clean && make && make test` |
| **Archive Gate** | 所有 artifact + `verify-report.md` | `tasks.md` 全勾选 / delta 已合并 / `openspec validate --strict` 通过 | `openspec validate --strict --specs` |

**简化豁免**（参考 `sd-firmware-copilot/SKILL.md §简化豁免规则`）：

- 单文件 bugfix：豁免 Proposal Gate 的人工访谈，但 Design Gate 简述影响范围仍需
- 文档/注释/配置变更：豁免 Proposal Gate + Design Gate
- 跨模块重构：**无豁免**——完整 5 级门禁

---

## 5. 验证（verify）— Archive 前必做

`/opsx:verify` 跑 6 项自动检查，**不替代** Review Gate：

| # | 检查项 | 命令 | 通过标准 |
|---|--------|------|----------|
| 1 | `tasks.md` 全勾选 | `grep -c '^\- \[x\]' openspec/changes/<id>/tasks.md` | 所有任务已勾 |
| 2 | 编译通过 | `make clean && make -j$(nproc)` | 退出码 0 |
| 3 | 测试通过 | `make test` | 退出码 0 |
| 4 | Spec 一致 | `openspec validate --strict --changes` | 无 violation |
| 5 | CodeGraph 一致 | `codegraph impact <修改文件>` | 与 design.md 影响范围一致 |
| 6 | Graphify 完整 | `graphify diagnose multigraph` | `missing_endpoint_edges = 0` |

任何失败 → 回 BUILD 阶段修复；全部通过 → 进入 `/opsx:archive`。

---

## 6. 归档（archive）— 不可逆

1. **预检**（用 `/opsx:verify` 已通过的）：
   - `tasks.md` 所有任务 `- [x]`
   - `review.md` 存在 + 人类审查签字
   - `verify-report.md` 存在 + 6 项全过
2. **同步 delta**（如果用 `/opsx:archive` 自动流程，会先调 `/opsx:sync`）：
   - 读 `openspec/changes/<id>/specs/<cap>/spec.md` 找 `## ADDED|MODIFIED|REMOVED|RENAMED` 段
   - 智能合并到 `openspec/specs/<cap>/spec.md`（ADDED 追加 / MODIFIED 替换同名 / REMOVED 删 / RENAMED 用 `FROM:` `TO:`）
   - **绝不程序化覆盖 baseline**
3. **移动**：
   ```bash
   mv openspec/changes/<id>/ openspec/changes/archive/$(date +%Y-%m-%d)-<id>/
   ```
   保留 `.openspec.yaml` 在移动后目录内。
4. **Commit**（格式固定）：
   ```bash
   git add openspec/changes/
   git commit -m "chore(spec): archive <change-id>"
   ```
5. **最终校验**：
   ```bash
   openspec validate --strict --specs
   ```

**关键约束**：
- 永不删除 `openspec/changes/` 条目（审计追踪）
- 永不 `rm -rf` —— 用 `mv` 到 `archive/`
- 永不程序化合并 baseline —— 智能匹配 Requirement 头
- Archive 后 `openspec/specs/<cap>/spec.md` 是新基线，下次搜索从这里开始

---

## 7. 关键参考

| 资源 | 内容 |
|------|------|
| `../AGENTS.md` | 项目级 OpenCode 配置 + Skill Bootstrap |
| `sd-firmware-copilot/SKILL.md` | 项目流水线 + 五门禁 + Iron Rules |
| `openspec-workflow/SKILL.md` | OpenSpec 5 phase 概念层 |
| `.opencode/memory/architecture.md` | SSD 固件架构分层规则 |
| `.opencode/memory/design_rules.md` | 错误处理横切规则 |
| `.opencode/memory/{concurrency_rules,coding_style,testing_rules}.md` | 编码约束 |
| `openspec/config.yaml` | OpenSpec 项目配置（context + rules） |
| `docs/adr/` | 方法论选择依据（ADR 格式） |

---

## 8. 一句话流程

> 接到需求 → 加载 `superpowers-using-superpowers` + `openspec-workflow` → 选 opsx 命令 → 5 phase 5 gate → 验证 → 归档 → 更新 baseline。
