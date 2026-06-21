## Context

`openspec-workflow/SKILL.md` 当前 132 行，覆盖 OpenSpec 五阶段（propose / explore / apply / sync / archive）+ 跨切规则 + CLI cheatsheet。YAML frontmatter 已有 `name: openspec-workflow` 与 `description` 描述「Full OpenSpec workflow」。

**问题**：
1. **description 触发精度低**：「Full OpenSpec workflow」+「propose, explore, apply, sync, archive」混在一个 description 中，AI 在用户说「先 explore 一下当前实现」时容易误匹配到 propose 或 apply
2. **Token 占用不合理**：用户问 sync 阶段时，132 行全 in-context，其中 propose/explore/apply 全部 80% 无关
3. **agentskills.io 规范压力**：Anthropic 推荐 SKILL.md < 500 行 + 单一职责（progressive disclosure 三层加载）

**约束**：
- 5 个 baseline spec（ssd-firmware-overview / nvme-commands / ftl-mapping / nand-driver / error-handling）行为不变
- OpenSpec CLI 调用方式（`openspec new change` / `status --change` / `instructions` / `archive`）保持
- `.opencode/memory/` 6 个规则文件、`.opencode/plugins/graphify.js` 不动
- `verify.sh` 12 项检查的语义保持

**Stakeholders**：项目维护者（zsf 自己）、AI Agent 使用者

## Goals / Non-Goals

**Goals**:
- 拆分 `openspec-workflow` 为 1（概念层）+ 5（phase skill），每个 SKILL.md ≤ 80 行
- 落地 5 个 `.opencode/commands/opsx-*.md` 原生 slash 命令
- 保持 OpenSpec CLI 调用流程与 4-gate 门禁不变
- 更新 `verify.sh` / 文档反映新结构

**Non-Goals**:
- 不改 OpenSpec CLI 行为或 flag
- 不改 `openspec/specs/` 5 个 baseline capability
- 不改 `sd-firmware-copilot/SKILL.md`
- 不改 Superpowers 14 个子 skill
- 不重写 `openspec-workflow` 的 iron rules 或跨切约束（仅重定位到新位置）

## Decisions

### 决策 1：保留 `openspec-workflow` 作为「概念层」（用户已确认）

**选择**：保留 `openspec-workflow/SKILL.md`，瘦身至 ≤ 50 行，仅含：
- 3 条 Iron Rules（spec 是真相源 / 4-gate / 不删 changes）
- 跨切约束（kebab-case、JSON paths、workspace guard、sync 智能合并、audit trail）
- 路由表：「5 phase skill 在哪 + 何时用哪个」

**理由**：
- 5 个 phase 共享的「OpenSpec 是什么」「Delta 格式」「4-gate 门禁」等概念在 1 处定义，避免 5 份 SKILL.md 重复
- 保留入口 skill 让 5 phase skill 通过 `metadata.requires` 或 description 指针互引

**备选**：
- 完全删除 `openspec-workflow` → 共享概念重复 5 次（拒绝）
- 保留并全文复制到 5 phase → 严重冗余（拒绝）

### 决策 2：5 个 phase skill 命名（与提案对齐）

| Phase | Skill 名 | 触发词 |
|-------|---------|--------|
| Stage 1: propose | `openspec-propose` | /opsx:propose, 创建变更, 提案 |
| Stage 2: explore | `openspec-explore` | /opsx:explore, 探索, 调研 |
| Stage 3: apply | `openspec-apply` | /opsx:apply, 实施, 编码 |
| Stage 4: sync | `openspec-sync-specs` | /opsx:sync, 合并 spec |
| Stage 5: archive | `openspec-archive-change` | /opsx:archive, 归档 |

**理由**：
- 与 `archive` 路径 `archive/YYYY-MM-DD-{id}/` 一致
- 避免与 `openspec-workflow`（顶层）命名冲突
- 描述触发词短而准

### 决策 3：5 个 commands/opsx-*.md 落地

**选择**：在 `.opencode/commands/` 下创建 5 个 `opsx-{phase}.md`，每个含 frontmatter `name` + 简短描述 + 指针到对应 phase skill。

**理由**：
- OpenCode 原生支持 `commands/` 作为 slash 命令入口（与 skill dispatch 平行）
- 命令文件 ≤ 30 行，description 单行匹配 phase skill

**备选**：
- 不落地 commands/，继续靠 skill dispatch → 失去 native slash 体验（拒绝）

### 决策 4：verify.sh 期望从 13 改为 20

**选择**：5（openspec-*）+ 1（openspec-workflow）+ 14（superpowers-*）= 20 个子目录

**理由**：
- `sd-firmware-copilot` 不在 verify.sh 检查范围（保留原样）
- `superpowers` 顶层目录也未检查（保留原样）
- 实际期望 5 + 14 = 19，加上 `openspec-workflow` = 20

**备选**：
- 改用正则匹配（如 `superpowers-*` glob）→ 失去精确性（拒绝）

## Risks / Trade-offs

| Risk | Mitigation |
|------|------------|
| 旧 description「Full OpenSpec workflow」已被 AI 习惯，拆分后新 description 触发变少 | 在 `openspec-workflow` 描述中显式声明「这是 5 phase 的入口，请用 openspec-{phase}/ 执行」 |
| 5 份 SKILL.md 维护成本高（description 漂移） | 5 个 phase skill description 用一致格式：「Stage N of OpenSpec 5-stage lifecycle: <动词>」 |
| `commands/` 目录命名被 OpenCode 解释为「OpenCode 项目级命令」而非 zsf 专属 | 路径在 `.opencode/commands/`，已是 OpenCode 命名空间，OK |
| 用户脚本/工具硬编码 `/opsx:propose` 等 slash 名 | 5 个 slash 名保持完全一致，只是入口从 skill dispatch 改为 commands/ + skill 组合 |
| 删除 `openspec-workflow` 顶层 description「Full OpenSpec workflow」→ 影响现有 prompt 缓存 | description 改为「OpenSpec 概念层：Iron Rules + 跨切约束，5 phase 入口索引」 |

## Migration Plan

无运行时 migration。`git mv` 重命名 + 新建即可，回滚用 `git revert`。

**部署顺序**：
1. 先新建 5 个 phase skill + 5 个 commands（不破坏现状）
2. 再瘦身 `openspec-workflow`（最后一步）
3. 更新 verify.sh + docs
4. 跑 `bash verify.sh` 确认 12/12
5. 试运行 `/opsx:propose` 端到端（无 change 时仅验证 slash 命令路由到正确 skill）

**回滚**：`git revert <commit>`，所有文件恢复。

## Open Questions

无 —— 拆分粒度（1+5）、命名（`openspec-{phase}`）、保留 `openspec-workflow` 概念层均已与用户对齐。
