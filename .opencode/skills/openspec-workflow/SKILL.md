---
name: openspec-workflow
description: Full OpenSpec workflow — propose, explore, apply, sync, archive. Covers the complete PLAN and FEEDBACK stages of the four-stage loop (KNOW → PLAN → BUILD → FEEDBACK).
license: MIT
compatibility: Requires openspec CLI (v1.4.1+).
metadata:
  author: openspec
  version: "1.0"
  generatedBy: "1.4.1"
---

# OpenSpec 工作流

OpenSpec CLI 把 SSD 固件的需求/设计/任务统一管理在 `openspec/specs/`（基线）和 `openspec/changes/{id}/`（增量）下。本 Skill 是 OpenSpec CLI 的**完整流程适配器**，覆盖从「提议变更」到「归档变更」的 5 个阶段，对应四阶段闭环中的 **PLAN**（propose/explore/sync）与 **FEEDBACK**（archive）。

## 5 个阶段全景

```
┌────────────────────────────────────────────────────────────────────┐
│                OpenSpec 增量变更生命周期（5 阶段）                  │
├────────────────────────────────────────────────────────────────────┤
│                                                                    │
│  ① propose        ② explore        ③ apply        ④ sync  ⑤ archive│
│  ─────────        ─────────        ─────────      ─────  ──────── │
│  创建变更          探索思考          实施任务       同步基线  归档变更│
│  生成 artifacts    （可选）         按 tasks.md   delta→main  移到│
│  proposal/design/  不写代码        TDD 推进      specs/      archive/│
│  specs/tasks                                                     │
│                                                                    │
│  关键命令：                                                        │
│  /opsx:propose    /opsx:explore    /opsx:apply   /opsx:sync /opsx:archive│
│  openspec new     （CLI 无命令）   openspec      openspec  openspec  │
│   change                            instructions  status    status    │
│                                    apply                      (then mv)│
│                                                                    │
│  状态：changes/{id}/    同左      tasks.md       specs/    archive/  │
│        新建空骨架      思考中      [x] 勾选        delta     YYYY-    │
│                                          完成      已合并    MM-DD-  │
│                                                                {id}/  │
└────────────────────────────────────────────────────────────────────┘
```

**何时跳过某阶段：**
- `explore` 是**可选的**思考阶段，可在 propose 之前/之后/之中自由使用
- `sync` 可在 `apply` 完成后、`archive` 之前执行（archive 也会自动检查 sync 状态）
- 单文件 bugfix 可跳过 propose，直接进入 apply（参见 `sd-firmware-copilot/rules/spec_rules.md`）

---

## 阶段 1：提议变更（propose）

**目的**：一次性创建 change 目录并生成全部必需 artifacts（proposal / design / specs / tasks）。

**触发命令**：`/opsx:propose`

**输入**：用户给 change 名（kebab-case）或需求描述。

### 关键步骤

1. **确认输入**：若用户没说清想做什么，用 AskUserQuestion 询问；从中派生 kebab-case 名称（如 "add user authentication" → `add-user-auth`）。
2. **创建目录**：`openspec new change "<name>"`，CLI 按 `.openspec.yaml` 的 `planningHome` 解析路径。
3. **取构建顺序**：`openspec status --change "<name>" --json`，解析得到：
   - `applyRequires`：实施前必须完成的 artifact 列表（如 `["tasks"]`）
   - `artifacts`：所有 artifact 的状态与依赖关系
   - `planningHome` / `changeRoot` / `artifactPaths` / `actionContext`：路径与作用域上下文（**不要假设 repo-local 路径**）
4. **按依赖顺序串行创建**：用 TodoWrite 跟踪进度，对每个 `ready` 状态 artifact：
   - `openspec instructions <artifact-id> --change "<name>" --json` 取得 `context` / `rules` / `template` / `instruction` / `resolvedOutputPath` / `dependencies`
   - 读取已完成的依赖 artifact 获取上下文
   - 按 `template` 结构写到 `resolvedOutputPath`
   - 显示进度「Created <artifact-id>」
5. **循环直到 apply-ready**：每写完一个 artifact 重新跑 `status --json`，直到 `applyRequires` 中所有 ID 状态为 `done`。
6. **最终展示**：`openspec status --change "<name>"`，输出变更位置、artifacts 列表、就绪提示。

### 关键约束

- **`context` 和 `rules` 是给你的约束，不是文件内容**——严禁把 `<context>` / `<rules>` / `<project_context>` 块复制进 artifact。
- 严格按 `instruction` 字段写每种 artifact；`template` 是结构骨架。
- 写完一个 artifact 后必须验证文件存在再继续。
- 同名 change 已存在时，询问用户「继续」还是「新建」。
- 上下文严重不清时询问用户，但优先做合理推断以保持节奏。

---

## 阶段 2：探索影响（explore）

**目的**：作为思考伙伴帮用户厘清想法、调查问题、明确需求。**不写实现代码**。

**触发命令**：`/opsx:explore`

**重要**：Explore 是「思考姿态」而非固定流程——没有强制步骤、强制顺序、强制输出。可以读文件、搜代码、调查仓库，但**绝对不能写实现代码**。如用户要实施，提醒其先退出 explore 并创建 proposal。**可以**应用户要求创建 OpenSpec artifacts（那也是思考的产物，不是实现）。

### 思考姿态

- **好奇，非刻板**——自然追问，不按脚本走
- **开放线索，非审问**——抛出多个有趣方向让用户选，不强制收口
- **可视化**——多用 ASCII 框图/状态机/数据流
- **自适应**——跟着有趣的线走，必要时转向
- **耐心**——别急着下结论，让问题形态自然浮现
- **接地气**——相关时探索真实代码库，不空想

### 典型动作

| 动作 | 具体做法 |
|------|----------|
| **探索问题空间** | 追问、挑战假设、重构问题、找类比 |
| **调查代码库** | 画现有架构、找集成点、识别既有模式、暴露隐藏复杂度 |
| **比较方案** | 头脑风暴多方案、建对比表、画权衡图、按需推荐 |
| **可视化** | 系统图、状态机、数据流、依赖图、对比表 |
| **暴露风险** | 找可能出错点、知识盲区、提议 spike 任务 |

### 与 OpenSpec 的协同

开局先 `openspec list --json` 了解当前活跃变更与上下文。

- **无活跃变更时**：自由思考；思路成熟时可提议「我帮你建个 proposal 吗？」——不强制。
- **有活跃变更时**：
  1. `openspec status --change "<name>" --json` 解析 `changeRoot` / `artifactPaths` / `actionContext`，从 `artifactPaths.<artifact>.existingOutputPaths` 读已有 artifacts
  2. 自然在对话中引用它们（如「你的 design 里说用 Redis，但我们刚发现 SQLite 更合适……」）
  3. 决策明确时提议归档到合适位置（**用户决定，不自动写**）：

     | 洞见类型 | 应归档到 |
     |----------|----------|
     | 新需求被发现 | `specs/<capability>/spec.md` |
     | 需求被修改 | `specs/<capability>/spec.md` |
     | 设计决策落地 | `design.md` |
     | 范围被改 | `proposal.md` |
     | 新工作浮现 | `tasks.md` |
     | 假设被推翻 | 相关 artifact |

### 入口场景速查

- **用户带模糊想法** → 画「问题光谱」让用户定位落点
- **用户带具体问题** → 读代码、画现状图、暴露 3 个症结、问哪个最痛
- **用户实现中卡壳** → 读 change artifacts、定位当前 task、追因、画方案、问是否更新 design
- **用户要对比方案** → 追问真实约束、画对比表、给出推荐 + 触发条件

### 关键约束

- **不实现**——可创建 OpenSpec artifacts，**绝不写应用代码**
- **不假装懂**——不清就继续挖
- **不催**——这是思考时间不是任务时间
- **不强制结构**——让模式自然浮现
- **不自动归档**——提议后让用户决定
- **要画图**——一张好图胜过千言
- **要探索代码**——把讨论落进现实
- **要质疑假设**——包括用户的和你自己的

---

## 阶段 3：实施变更（apply）

**目的**：按 `tasks.md` 推进实施，逐项勾选完成。

**触发命令**：`/opsx:apply`

**输入**：可选的 change 名。缺省时按对话上下文推断；仅 1 个活跃变更时自动选；多于一或模糊时**必须**用 AskUserQuestion 让用户选。

### 关键步骤

1. **选定变更**：`openspec list --json` 列出可选 → 选定 → 公告「Using change: <name>」并提示覆盖方法（`/opsx:apply <other>`）。
2. **查状态**：`openspec status --change "<name>" --json`，解析：
   - `schemaName`：所用工作流（如 `spec-driven`）
   - `planningHome` / `changeRoot` / `actionContext`
   - tasks 所在 artifact（spec-driven 是 `tasks`，其他 schema 看 status）
3. **取 apply 指令**：`openspec instructions apply --change "<name>" --json`，得到 `contextFiles`（artifact ID → 文件路径表）、进度、任务列表、动态指令。
4. **处理状态分支**：
   - `state: "blocked"`（缺 artifacts）→ 提示用户用 `/opsx:continue-change`
   - `state: "all_done"` → 祝贺并建议 `/opsx:archive`
   - 其余 → 进入实施
5. **工作区护栏**：若 `actionContext.mode == "workspace-planning"` 且 `allowedEditRoots` 为空，**说明本切片不支持整工作区 apply**，把链接仓库/目录视为只读，**停下来**让用户走显式实施流程选作用域，**编辑前必须 STOP**。
6. **读上下文**：把 `contextFiles` 中列出的所有文件全部读完（spec-driven 一般是 proposal/specs/design/tasks）。
7. **展示进度**：schema 名、`N/M tasks complete`、剩余任务、动态指令。
8. **循环实施**：逐个 pending task：
   - 显示当前 task
   - 做最小聚焦的代码改动
   - 立即把 `- [ ]` 改为 `- [x]`
   - 进入下一个
   - **暂停条件**：任务不清→问；实现暴露 design 问题→建议更新 artifacts；错误/阻塞→报告等指令；用户打断。
9. **结束/暂停时**：展示本次完成项、整体进度、建议 archive（全部完成）或说明暂停原因等指令。

### 关键约束

- **持续推进**直到完成或阻塞
- **实施前必读 `contextFiles`**，不要假定具体文件名
- **任务不清就暂停问**——不猜
- **实现暴露问题就暂停**，建议更新 artifacts
- **改动保持最小**，不扩大范围
- **完成一个 task 立即勾选**——避免遗忘
- **错误/阻塞/不清必停**——不猜测
- **支持流式工作流**：可在所有 artifacts 完成前（只要 tasks 存在）调、能在部分实施后回到 apply、能与其他 action 交织

---

## 阶段 4：同步规格（sync）

**目的**：把 change 下的 delta specs 合并进主 specs（`openspec/specs/<capability>/spec.md`），**change 保持活跃**——这是 archive 前的可选准备动作。

**触发命令**：`/opsx:sync`

**重要**：这是**agent 驱动**的操作——你读 delta spec 然后直接编辑主 spec，支持**智能合并**（如只增一个 scenario 而不复制整个 requirement）。**不**走纯程序化合并。

### 关键步骤

1. **选定变更**：`openspec list --json` 列出**有 delta specs**（`specs/` 目录下）的变更，**必须**用 AskUserQuestion 让用户选——**禁止猜测/自动选**。
2. **解析上下文**：`openspec status --change "<name>" --json`。若 `actionContext.mode == "workspace-planning"`，**说明不支持工作区 sync 并 STOP**——不回退到 repo-local 路径，不编辑链接仓库。
3. **找 delta specs**：用 `artifactPaths.specs.existingOutputPaths` 的列表。识别以下章节：
   - `## ADDED Requirements`——新增
   - `## MODIFIED Requirements`——修改
   - `## REMOVED Requirements`——删除
   - `## RENAMED Requirements`——重命名（`FROM:` / `TO:` 格式）
   - **无 delta specs** → 告诉用户并停。
4. **逐 delta spec 应用变更**（仅对 repo-local capability delta spec）：
   - a. 读 delta spec
   - b. 读主 spec `openspec/specs/<capability>/spec.md`（可能不存在）
   - c. 智能应用：
     - **ADDED**：不存在则新增；已存在则当作隐式 MODIFIED 更新
     - **MODIFIED**：定位 requirement，可**只增新 scenario / 改 description / 改现有 scenario**——**保留 delta 未提及的 scenario**
     - **REMOVED**：删除整块 requirement
     - **RENAMED**：找 `FROM:` 改名为 `TO:`
   - d. 若 capability 不存在：新建 `openspec/specs/<capability>/spec.md`，加 Purpose（可简短标 TBD）+ Requirements（ADDED 内容）
5. **展示汇总**：更新了哪些 capability、做了哪些增/改/删/重命名。

### Delta Spec 格式参考

```markdown
## ADDED Requirements

### Requirement: New Feature
The system SHALL do something new.

#### Scenario: Basic case
- **WHEN** user does X
- **THEN** system does Y

## MODIFIED Requirements

### Requirement: Existing Feature
#### Scenario: New scenario to add
- **WHEN** user does A
- **THEN** system does B

## REMOVED Requirements

### Requirement: Deprecated Feature

## RENAMED Requirements

- FROM: `### Requirement: Old Name`
- TO: `### Requirement: New Name`
```

### 关键约束

- **编辑前必读 delta 和主 spec 两者**
- **保留 delta 未提及的内容**——delta 代表意图而非全量替换
- **改时同步展示**——让用户看到变化
- **不清晰就问**
- **操作应幂等**——跑两次结果一致
- **使用判断**做智能合并（agent 驱动是核心优势）

---

## 阶段 5：归档变更（archive）

**目的**：在实施完成后最终化变更——把 `openspec/changes/{id}/` 移到 `openspec/changes/archive/YYYY-MM-DD-{id}/`，并可选择同步 delta specs。

**触发命令**：`/opsx:archive`

**输入**：可选的 change 名。模糊/缺省时**必须**用 AskUserQuestion 让用户选——**禁止猜测/自动选**。

### 关键步骤

1. **选定变更**：`openspec list --json` 列出**活跃**（未归档）变更，可附 schema，**必让用户选**。
2. **检查 artifact 完成度**：`openspec status --change "<name>" --json`，解析 `schemaName` / `planningHome` / `changeRoot` / `artifactPaths` / `actionContext` / `artifacts` 状态。若 `actionContext.mode == "workspace-planning"`，**说明不支持工作区 archive 并 STOP**——不把工作区变更移到 repo-local archive，不编辑链接仓库。
   - **若 artifact 非 `done`**：列出警告项，用 AskUserQuestion 确认仍要继续。
3. **检查 task 完成度**：读 `tasks.md`，数 `- [ ]`（未完成）vs `- [x]`（完成）。**无 tasks 文件**则跳过 task 警告。
   - **若存在未完成 task**：显示数量警告，AskUserQuestion 确认仍要继续。
4. **评估 delta spec 同步状态**：用 `artifactPaths.specs.existingOutputPaths` 检查。
   - **无 delta specs** → 直接进入归档。
   - **有 delta specs** → 与 `openspec/specs/<capability>/spec.md` 对比，决定将应用的变更（增/改/删/重命名），**先展示合并汇总再提示**：
     - 待变更：选项「立即同步（推荐）」「不同步直接归档」
     - 已同步：选项「立即归档」「再同步一次」「取消」
   - 若用户选同步：用 Task 工具（`subagent_type: "general-purpose"`）调 `openspec-sync-specs`。
5. **执行归档**：
   - 建 `mkdir -p "<planningHome.changesDir>/archive"`
   - 目标名 `YYYY-MM-DD-<change-name>`（用当前日期）
   - **若目标已存在** → 报错并提示改名或换日期
   - `mv "<changeRoot>" "<planningHome.changesDir>/archive/YYYY-MM-DD-<name>"`
6. **展示汇总**：change 名、所用 schema、归档位置、是否同步 specs、警告（不完 artifacts/tasks）。

### 关键约束

- **缺省名必问**用户选
- **用 artifact 图**（`openspec status --json`）判定完成度
- **警告不阻塞**——只提示确认
- **`.openspec.yaml` 跟着目录一起 move**——不要单独处理
- **展示清晰汇总**
- **要 sync 就走 openspec-sync-specs 方式**（agent 驱动）
- **有 delta specs 必先评估+汇总再提示**

---

## 完整流程示例

### 路径 A：设计文档驱动（标准 5 阶段）

```bash
# 阶段 0：KNOW（其他工具，不在本 Skill）
graphify query "<设计关键词>" && codegraph explore <代码区域>

# 阶段 1：PLAN - 提议（一次生成全部 artifacts）
/opsx:propose add-user-auth "根据 SDD 第 5 章实现用户认证"

# 阶段 2：PLAN - 探索（可选：实现前/中遇到设计问题）
/opsx:explore add-user-auth
# → 读 artifacts，质疑方案，更新 design.md / tasks.md

# 阶段 3：BUILD - 实施（按 tasks 推进）
/opsx:apply add-user-auth
# → 逐 task 实施，勾选 [x]

# 阶段 4：PLAN - 同步（把 delta 合并到主 specs）
/opsx:sync add-user-auth
# → ADDED / MODIFIED / REMOVED / RENAMED → openspec/specs/

# 阶段 5：FEEDBACK - 归档
/opsx:archive add-user-auth
# → 检查完成度 → 同步提示 → 移到 archive/2026-06-18-add-user-auth/

# 阶段 5 后：FEEDBACK（其他工具）
graphify update .   # 知识图谱更新
```

### 路径 B：代码驱动

```bash
# KNOW：分析代码 + 生成设计文档（其他工具）
codegraph explore <区域> && codegraph callers <核心函数>
graphify explain "<概念>"

# 之后同路径 A：propose → explore? → apply → sync → archive
```

### 路径 C：单文件 bugfix（精简）

```bash
# 跳过 propose，直接修复
# （参考 sd-firmware-copilot/rules/spec_rules.md 中「单文件 bugfix 可跳过 Proposal Gate」）

# 如需走 OpenSpec：propose + tasks 阶段
/opsx:propose fix-ftl-race "修复 FTL mapping 阶段的竞态条件"
/opsx:apply fix-ftl-race
/opsx:archive fix-ftl-race
```

---

## 约束与规则（跨阶段通用）

### 1. CLI 命令约定

| 阶段 | 入口命令 | 底层 CLI |
|------|----------|----------|
| propose | `/opsx:propose` | `openspec new change` / `openspec status --change --json` / `openspec instructions <artifact> --change --json` |
| explore | `/opsx:explore` | （无固定 CLI；按需 `openspec list --json` / `openspec status --change --json`） |
| apply | `/opsx:apply` | `openspec status --change --json` / `openspec instructions apply --change --json` |
| sync | `/opsx:sync` | `openspec list --json` / `openspec status --change --json` |
| archive | `/opsx:archive` | `openspec status --change --json` + `mv` 到 `archive/YYYY-MM-DD-<name>/` |

所有 `--change "<name>"` 必须存在；缺省名时**必问**用户（禁止猜测/自动选，apply 阶段除外可按上下文推断）。

### 2. JSON 路径解析规则

`openspec status --change "<name>" --json` 返回：

- `planningHome`：规划根（`changesDir` 等）
- `changeRoot`：当前 change 目录
- `artifactPaths`：artifact ID → 输出路径（`existingOutputPaths` 读已有文件）
- `actionContext`：`mode` 可能是 `repo-planning`（正常）或 `workspace-planning`（**部分操作不支持**）
- `applyRequires`：apply 前必完成的 artifact 列表
- `artifacts`：所有 artifact 的 `status`（`done` / 其他）

**禁止**假设 repo-local 路径，必须从 JSON 取。

### 3. 工作区护栏

若 `actionContext.mode == "workspace-planning"`：
- `apply`：禁止编辑文件，把链接仓库/目录视为只读，**编辑前 STOP** 让用户选作用域
- `sync` / `archive`：**直接 STOP** 并说明本切片不支持

### 4. 跨阶段门禁

- **Proposal Gate** → **Design Gate** → **Review Gate** → **Archive**：每变更必经（详见 `sd-firmware-copilot/rules/spec_rules.md`）
- **不删 `openspec/changes/` 条目**——它们是审计追踪
- **归档提交格式**：`chore(spec): archive {change-id}`

### 5. 与三铁律的协同

- **不验证不宣称完成**——apply 阶段勾选 task 前必跑测试
- **无失败测试不写实现**——apply 中遵循 TDD（参见 `superpowers/test-driven-development`）
- **无根因不修 bug**——explore 阶段用于追因（参见 `superpowers/systematic-debugging`）

### 6. 与其他 Skill 的协作

- **`sd-firmware-copilot`**：顶层入口 + 规格层规则（`rules/spec_rules.md`）
- **`superpowers`**：TDD / 根因调试 / 验证完成（apply 阶段必走）
- **`development/skill`**：BUILD 薄适配器（可委托 superpowers）
- **`review/skill`**：FEEDBACK 薄适配器（archive 前的代码审查）
- **`graphify` / `codegraph`**：KNOW 阶段的知识图谱与调用图（FEEDBACK 后用 `graphify update .` 更新）

---

## 速查卡片

```
┌──────────────────────────────────────────────────────────┐
│  我现在要……                       →  用这个命令           │
├──────────────────────────────────────────────────────────┤
│  描述需求、生成全部 artifacts      →  /opsx:propose       │
│  思考/质疑/调查（不写代码）        →  /opsx:explore       │
│  按 tasks.md 实施代码              →  /opsx:apply         │
│  合并 delta specs 到主 specs       →  /opsx:sync          │
│  最终化变更，移到 archive          →  /opsx:archive       │
│  跨状态查询当前活跃变更            →  openspec list --json│
│  查某 change 的 artifact 状态      →  openspec status     │
│                                           --change --json │
└──────────────────────────────────────────────────────────┘
```
