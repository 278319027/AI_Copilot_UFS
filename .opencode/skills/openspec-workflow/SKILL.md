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
- 单文件 bugfix 可跳过 propose，直接进入 apply（参见 `sd-firmware-copilot/SKILL.md`）

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
   - 若用户选同步：用 Task 工具（`subagent_type: "general-purpose"`）调 `openspec-workflow`（阶段 4 同步）。
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
- **要 sync 就走阶段 4 同步流程**（agent 驱动）
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
# （参考 sd-firmware-copilot/SKILL.md 中「单文件 bugfix 可跳过 Proposal Gate」）

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

- **Proposal Gate** → **Design Gate** → **Review Gate** → **Archive**：每变更必经（详见 `sd-firmware-copilot/SKILL.md`）
- **不删 `openspec/changes/` 条目**——它们是审计追踪
- **归档提交格式**：`chore(spec): archive {change-id}`

### 5. 与三铁律的协同

- **不验证不宣称完成**——apply 阶段勾选 task 前必跑测试
- **无失败测试不写实现**——apply 中遵循 TDD（参见 `superpowers/test-driven-development`）
- **无根因不修 bug**——explore 阶段用于追因（参见 `superpowers/systematic-debugging`）

### 6. 与其他 Skill 的协作

- **`sd-firmware-copilot`**：顶层入口 + 规格层规则（`.opencode/skills/sd-firmware-copilot/SKILL.md`）
- **`superpowers`**：TDD / 根因调试 / 验证完成（apply 阶段必走）
- **`sd-firmware-copilot/SKILL.md`**：BUILD/FEEDBACK 阶段的整合入口（superpowers 委托 + SSD 特定前后置步骤）
- **`graphify` / `codegraph`**：KNOW 阶段的知识图谱与调用图（FEEDBACK 后用 `graphify update .` 更新）

---

## 工件模板与门禁流程

阶段 1-5 描述「做什么、按什么顺序做」，本节提供「具体怎么写」——**zsf 域注入**、**模板示例**与**简化场景**。规则层面的权威定义（基线管理、增量格式、门禁清单的 checklist）见 `sd-firmware-copilot/SKILL.md`，避免重复。

### 1. OpenSpec 目录布局

```text
openspec/
├── AGENTS.md                       # OpenSpec 注入给 AI 的指令（自动生成）
├── config.yaml                     # schema: spec-driven + 项目上下文
├── specs/                          # 已通过归档合并的活基线
│   ├── ssd-firmware-overview/spec.md
│   ├── nvme-commands/spec.md
│   ├── ftl-mapping/spec.md
│   ├── nand-driver/spec.md
│   └── error-handling/spec.md
└── changes/                        # 进行中的变更（每个目录 = 一个 change）
    └── {change-id}/
        ├── .openspec.yaml          # 变更元数据
        ├── README.md               # 变更说明
        ├── proposal.md             # /opsx:propose 生成
        ├── specs/                  # /opsx:propose 生成（OpenSpec delta 格式）
        │   └── <capability>/spec.md  # 含 ## ADDED / ## MODIFIED / ## REMOVED Requirements
        ├── design.md               # /opsx:propose 生成（含 CodeGraph 查询结果）
        └── tasks.md                # /opsx:propose 生成（200-500 行/任务）
```

---

### 2. Proposal 域注入（zsf 域要求）

`/opsx:propose` 生成 `proposal.md` 时，AI 必须按以下 zsf 域要求填充：

| 字段 | zsf 域要求 |
|------|-----------|
| Why | 引用 `openspec/specs/<related-capability>/spec.md` 中的相关 Requirement 作为现状；说明本次变更的动机与对系统行为的改变 |
| What Changes | 列出新增 / 修改 / 移除的 capabilities；**破坏性变更必须标记 `**BREAKING**`** |
| Capabilities (New) | 命名规范：kebab-case（如 `ftl-slc-folding`、`nvme-sanitize`） |
| Capabilities (Modified) | 必须在 `openspec/specs/` 中存在；列出受影响的 Requirement ID |
| Impact | 列出潜在影响模块：NVMe / FTL / NAND / 错误处理；用 CodeGraph 预查（callers/impact）记录关键调用链 |
| 验收标准 | 每个验收点必须可在 review 阶段通过 `openspec validate --strict` + CodeGraph 查证 + 测试场景覆盖来核对 |

**简化场景**（与 `sd-firmware-copilot/SKILL.md` 一致）：

| 变更类型 | 是否可跳过 proposal 人工评审 | 必需工件 |
|---------|--------------------------|---------|
| 单文件 bugfix（影响范围明确） | ✅ 跳过 | 仍建议走 `/opsx:propose` 全部 4 个工件 |
| 文档 / 注释更新 | ✅ 跳过全部门禁 | 无需 OpenSpec 工件 |
| 配置变更（无逻辑影响） | ✅ 跳过 Proposal Gate 人工评审 | tasks.md 即可 |
| 新功能 / 重构 / 接口变更 | ❌ 必须完整流程 | 全部 4 个工件 + 三级门禁 |
| 跨模块变更 | ❌ 必须完整流程 + 额外 Review | 全部 4 个工件 + 双人 Review |

---

### 3. Specs Delta 格式与示例

OpenSpec 增量以 `## ADDED Requirements` / `## MODIFIED Requirements` / `## REMOVED Requirements` 三个 `##` 级 header 标识：

- `### Requirement: <name>`（3 个 `#`）
- 描述文本使用 SHALL / MUST（避免 should / may）
- `#### Scenario: <name>`（4 个 `#`）—— **必须使用 4 个 `#`，3 个 `#` 或列表会导致静默失败**
- Scenario 用 `**WHEN**` / `**THEN**` 描述
- delta 描述「系统做什么」，不描述「代码怎么写」

**完整示例**：

```markdown
## ADDED Requirements

### Requirement: FTL MUST fold SLC blocks when full
The FTL SHALL migrate data from SLC blocks to TLC blocks when SLC free block count falls below the configured threshold.

#### Scenario: SLC threshold reached
- **WHEN** SLC free block count < threshold
- **THEN** the FTL MUST pick a victim SLC block
- **AND THEN** it MUST copy valid pages to a free TLC block
- **AND THEN** it MUST erase the victim SLC block and return it to the free pool

## MODIFIED Requirements

### Requirement: FTL write path
The FTL MUST allocate a new PBA from the SLC region when possible, or from TLC when SLC is exhausted.

#### Scenario: SLC has free blocks
- **WHEN** the FTL processes a host write
- **THEN** it MUST allocate the new PBA from the SLC region

#### Scenario: SLC exhausted
- **WHEN** the FTL processes a host write and SLC has no free blocks
- **THEN** it MUST allocate the new PBA from the TLC region
- **AND THEN** it MUST schedule an SLC-to-TLC folding pass

## REMOVED Requirements

### Requirement: Legacy pblock allocation
**Reason**: Replaced by SLC-aware allocation policy
**Migration**: All write paths use the new SLC allocation logic
```

> **MODIFIED 备份原则**：复制整个 Requirement 块（含所有 Scenario），只写部分内容会导致归档时丢失细节。如新增关注点不改变现有行为，使用 ADDED 而非 MODIFIED。

---

### 4. Design 域注入（CodeGraph 强制）

`design.md` 由 `/opsx:propose` 生成，AI 在 OpenSpec 引导下填充内容。zsf 域要求 `design.md` 必须包含 **CodeGraph 查询结果** 与 **待人工确认清单**——这是 Design Gate 的强制输入。

#### 4.1 CodeGraph 查询（强制 4 项）

修改任何代码前，必须先执行以下查询并把结果粘贴到 design.md 的对应章节：

```bash
codegraph callers <symbol>           # 影响范围（函数 / 结构体 / 宏）
codegraph callers <symbol>           # 谁调用了
codegraph explore <header>           # 头文件 include 影响
codegraph explore                    # 模块边界 / 循环依赖
```

#### 4.2 cscope 补充（函数指针 / 宏场景）

```bash
cscope -d -L2 "<func_ptr>"           # 函数指针调用者
cscope -d -L3 "<func_ptr>"           # 函数指针指向
cscope -d -L4 "<MACRO>"              # 宏使用位置
cscope -d -L8 "<header.h>"           # 谁包含了这个头文件
```

> CodeGraph 在函数指针 / 宏场景有盲区，cscope 是强制补充。

#### 4.3 待人工确认清单（Design Gate 输入，7 项）

人工逐条确认才能进入 Coding 阶段：

1. 架构假设是否正确？
2. CodeGraph 查询是否完整？（是否覆盖所有调用者和依赖？）
3. 是否有更简单的替代方案？
4. tasks.md 粒度是否合适（200-500 行/任务）？
5. 并发 / 资源 / 错误路径是否已考虑？（参见 `memory/concurrency_rules.md`）
6. 模块边界是否违反？（参见 `memory/architecture.md`）
7. specs/ delta 是否覆盖所有变更？（参见 `openspec/changes/<id>/specs/`）

**简化场景**：单文件 bugfix 的 design.md 可精简为仅含「架构假设」和「CodeGraph 查询结果」两个字段。

---

### 5. Tasks 域注入

`tasks.md` 由 `/opsx:propose` 自动生成，AI 在 OpenSpec 引导下填充任务清单。zsf 的 **200-500 行/任务** 小任务原则在 tasks.md 中以「预期行数」字段强制表达：

| 字段 | 约束 |
|------|------|
| 任务粒度 | 每个任务 200-500 行（与 zsf 小任务原则一致） |
| 依赖 | 任务间依赖关系显式标注（前序任务 ID） |
| 可独立验证 | 每个任务必须有自己的测试场景（参见 `memory/testing_rules.md`） |
| 不扩大需求 | 任务清单严格对应 proposal.md 中的 What Changes；不接受范围蔓延 |
| 与 spec 增量对应 | 每个任务项至少对应一条 `specs/` delta 中的 Scenario |

---

### 6. Review 域注入（查证式验证）

Review 阶段是**查证式验证**（不重新查询 CodeGraph），对照 design.md 中记录的 CodeGraph 结果验证代码变更是否在预期范围内。检查项按风险等级排列：

| 检查项 | 验证方法 | 风险等级 |
|--------|---------|---------|
| 空指针 | 查 review 报告 + 静态分析 | 高 |
| 数组越界 | 查 review 报告 + 静态分析 | 高 |
| 资源泄漏 | valgrind / asan | 高 |
| 竞态条件 | 对照 `memory/concurrency_rules.md` + 重新阅读并发代码 | 高 |
| 死循环 | 静态分析 + 状态机审查 | 中 |
| 模块边界违反 | CodeGraph import 关系 | 中 |
| 接口兼容性 | 对照 baseline spec | 中 |
| 函数指针调用遗漏 | cscope -L2 / -L3 | 中 |
| **CodeGraph 影响范围查证** | 对照 design.md vs 实际 diff | 高 |
| **specs/ delta 覆盖** | 对照 tasks.md vs openspec/changes/<id>/specs/ | 高 |
| **`openspec validate --strict` 通过** | CI / 命令行 | 强制 |

**Review 工具**：

```bash
# 校验 OpenSpec 工件
openspec validate --strict --changes

# 查证 CodeGraph 影响（仅在 design.md 查证发现偏差时）
codegraph callers <symbol>

# 函数指针 / 宏补充
cscope -d -L2 "<func_ptr>"

# 基线对比
openspec show <capability>
```

**Review 输出模式**（不再使用手刻 `review.md`）：

1. 在 PR / Change 中以评审评论形式记录（人工 + AI）
2. 关键问题记录到 `openspec/changes/<id>/design.md` 的「Review Notes」追加段落（由 AI 在 `/opsx:apply` 完成后追加）
3. **绝不** 重新写手刻 review.md 模板

---

### 7. 三级门禁衔接点（OpenSpec CLI）

openSpec CLI 命令在门禁流程中的衔接点（与 `sd-firmware-copilot/SKILL.md` 互补，具体人工 checklist 见 `.opencode/skills/sd-firmware-copilot/SKILL.md`）：

| 阶段 | OpenSpec 命令 | 触发点 | 通过后 |
|------|--------------|--------|--------|
| Proposal Gate | `openspec validate --strict --changes` | `/opsx:propose` 完成后 | → Design 阶段 |
| Design Gate | `openspec validate --strict --changes` | design.md + tasks.md 完成后 | → `/opsx:apply` |
| Review Gate | `openspec validate --strict --changes` | 编码 + Review 后 | → `openspec archive <change-id>` |

---

### 8. 版本兼容说明

- **Step 1**（已完成）：引入 design.md + tasks.md 两个手刻工件。
- **Step 2**（已完成）：引入 proposal.md + review.md + specs/ 增量手刻工件。
- **Step 3**（当前）：迁移到 OpenSpec CLI——手刻工件模板移除，全部由 `/opsx:propose` / `/opsx:apply` / `/opsx:archive` 生成；旧 `.openspec/proposals/` 与 `.openspec/specs/baseline/` 目录已清理。
- **Step 4**（已完成）：5 个 baseline specs（ssd-firmware-overview / nvme-commands / ftl-mapping / nand-driver / error-handling）从 `.opencode/skills/sd-firmware-copilot/specs/baseline/` 迁移到 `openspec/specs/<capability>/spec.md`，全部通过 `openspec validate --strict`。
- **向后兼容**：未使用 OpenSpec CLI 的旧手刻变更仍可走 `.openspec/proposals/` 流程；所有新变更**必须**走 OpenSpec CLI。
- **渐进采用**：简单 bugfix 可使用 `/opsx:propose` 一次性生成 4 个工件；跨模块变更必须按 Proposal / Design / Review 三级门禁逐项校验。

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
