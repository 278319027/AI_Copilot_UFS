#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  bash install-comet.sh [target-dir] [--global]

Behavior:
  1. Recreate the minimal Comet runtime package in target-dir
  2. Run npm install --omit=dev inside target-dir
  3. Optionally run npm install -g target-dir when --global is passed

Defaults:
  target-dir = ./comet-runtime

Examples:
  bash install-comet.sh
  bash install-comet.sh /tmp/comet-runtime
  bash install-comet.sh /tmp/comet-runtime --global
EOF
}

TARGET_DIR="./comet-runtime"
INSTALL_GLOBAL=0

while [ $# -gt 0 ]; do
  case "$1" in
    --global)
      INSTALL_GLOBAL=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      TARGET_DIR="$1"
      shift
      ;;
  esac
done

command -v node >/dev/null 2>&1 || { echo "ERROR: node not found" >&2; exit 1; }
command -v npm >/dev/null 2>&1 || { echo "ERROR: npm not found" >&2; exit 1; }

rm -rf "$TARGET_DIR"
mkdir -p "$TARGET_DIR"

mkdir -p "$TARGET_DIR/assets"
mkdir -p "$TARGET_DIR/assets/skills-zh/comet"
mkdir -p "$TARGET_DIR/assets/skills-zh/comet-archive"
mkdir -p "$TARGET_DIR/assets/skills-zh/comet-build"
mkdir -p "$TARGET_DIR/assets/skills-zh/comet-design"
mkdir -p "$TARGET_DIR/assets/skills-zh/comet-hotfix"
mkdir -p "$TARGET_DIR/assets/skills-zh/comet-open"
mkdir -p "$TARGET_DIR/assets/skills-zh/comet-tweak"
mkdir -p "$TARGET_DIR/assets/skills-zh/comet-verify"
mkdir -p "$TARGET_DIR/assets/skills-zh/comet/reference"
mkdir -p "$TARGET_DIR/assets/skills/comet/scripts"
mkdir -p "$TARGET_DIR/bin"
mkdir -p "$TARGET_DIR/dist/cli"
mkdir -p "$TARGET_DIR/dist/commands"
mkdir -p "$TARGET_DIR/dist/core"
mkdir -p "$TARGET_DIR/dist/utils"

cat > "$TARGET_DIR/package.json" <<'__COMET_PACKAGE_JSON__'
{
  "name": "@rpamis/comet",
  "version": "0.3.11",
  "description": "Agent Skill Harness Phase-Guarded Automation From Idea To Archive",
  "keywords": [
    "comet",
    "openspec",
    "superpowers",
    "skills",
    "workflow"
  ],
  "license": "MIT",
  "author": "benym",
  "type": "module",
  "bin": {
    "comet": "./bin/comet.js"
  },
  "engines": {
    "node": ">=20"
  },
  "dependencies": {
    "@inquirer/ansi": "^2.0.5",
    "@inquirer/core": "^11.1.10",
    "@inquirer/figures": "^2.0.5",
    "@inquirer/prompts": "^8.4.3",
    "@inquirer/type": "^4.0.5",
    "commander": "^14.0.0"
  }
}
__COMET_PACKAGE_JSON__

cat > "$TARGET_DIR/assets/manifest.json" <<'__COMET_ASSETS_MANIFEST_JSON__'
{
  "version": "0.3.11",
  "skills": [
    "comet/SKILL.md",
    "comet/reference/auto-transition.md",
    "comet/reference/comet-yaml-fields.md",
    "comet/reference/context-recovery.md",
    "comet/reference/debug-gate.md",
    "comet/reference/decision-point.md",
    "comet/reference/dirty-worktree.md",
    "comet/reference/file-structure.md",
    "comet/reference/subagent-dispatch.md",
    "comet/scripts/comet-env.sh",
    "comet/scripts/comet-guard.sh",
    "comet/scripts/comet-state.sh",
    "comet/scripts/comet-handoff.sh",
    "comet/scripts/comet-archive.sh",
    "comet/scripts/comet-yaml-validate.sh",
    "comet-open/SKILL.md",
    "comet-design/SKILL.md",
    "comet-build/SKILL.md",
    "comet-verify/SKILL.md",
    "comet-archive/SKILL.md",
    "comet-hotfix/SKILL.md",
    "comet-tweak/SKILL.md"
  ]
}
__COMET_ASSETS_MANIFEST_JSON__

cat > "$TARGET_DIR/assets/skills-zh/comet-archive/SKILL.md" <<'__COMET_ASSETS_SKILLS_ZH_COMET_ARCHIVE_SKILL_MD__'
---
name: comet-archive
description: "Comet 阶段 5：归档。用 /comet-archive 调用。按 OpenSpec delta 语义合并主 spec，归档 change。"
---

# Comet 阶段 5：归档（Archive）

## 前置条件

- 验证已通过（阶段 4 完成）
- 分支已处理
- `openspec/changes/<name>/.comet.yaml` 中 `verify_result: pass`

## 步骤

### 0. 输出语言约束

归档摘要和生命周期闭环说明必须使用触发本次工作流的用户请求语言。

### 0b. 入口状态验证（Entry Check）

执行入口验证：

```bash
COMET_ENV="${COMET_ENV:-$(find . "$HOME"/.*/skills "$HOME/.config" "$HOME/.gemini" -path '*/comet/scripts/comet-env.sh' -type f -print -quit 2>/dev/null)}"
if [ -z "$COMET_ENV" ]; then
  echo "ERROR: comet-env.sh not found. Ensure the comet skill is installed." >&2
  return 1
fi
. "$COMET_ENV"
"$COMET_BASH" "$COMET_STATE" check <name> archive
```

验证通过后继续 Step 1。验证失败时脚本会输出具体失败原因。

### 1. 归档前最终确认（阻塞点）

入口验证通过后，**必须按 `comet/reference/decision-point.md` 的协议暂停并等待用户确认是否立即归档**。不得在用户确认前运行 `"$COMET_BASH" "$COMET_ARCHIVE" "<change-name>"`。

确认前必须向用户展示简短摘要：
- change 名称
- 验证报告路径和结论
- 分支处理状态
- 本次归档将执行的不可逆动作：按 OpenSpec delta 语义合并主 spec、标注 design doc / plan、移动 change 到 archive 目录

用户确认问题必须以单选题形式呈现，包含以下选项：
- 「确认归档」— 立即执行归档脚本，完成 spec 合并和 change 移动
- 「需要调整或重新验证」— 不执行归档；运行 `"$COMET_BASH" "$COMET_STATE" transition <change-name> archive-reopen` 回到 `phase: verify`，再调用 `/comet-verify`。若验证阶段确认需要修复，再按 `/comet-verify` 的验证失败决策回到 `/comet-build`
- 「暂不归档」— 不执行归档，保留当前 `phase: archive` 状态，等待用户稍后再次调用 `/comet-archive`

只有用户选择「确认归档」后，才允许继续 Step 2。用户选择「需要调整或重新验证」后，必须先执行 `archive-reopen` 状态回退，不得手动编辑 `.comet.yaml`。

### 2. 执行归档

运行归档脚本，自动完成以下全部步骤：

```bash
"$COMET_BASH" "$COMET_ARCHIVE" "<change-name>"
```

脚本自动执行：
1. 入口状态验证（phase=archive, verify_result=pass, archived=false）
2. Design doc 前置元数据标注（archived-with, status）
3. Plan 前置元数据标注（archived-with）
4. 调用 OpenSpec archive 按 delta 语义合并主 spec 并移动 change 到归档目录
5. 校验主 spec 未残留 delta-only section 标题
6. 通过 `comet-state transition <archive-name> archived` 更新 `archived: true`

如脚本返回非零退出码，报告错误并停止。
如脚本返回零退出码，归档完成。
脚本摘要中的 `X/Y steps succeeded` 以真实执行步骤计数，不会因 delta spec 同步或文档标注重复累计。

脚本会调用 OpenSpec 归档能力按 `ADDED/MODIFIED/REMOVED/RENAMED` 语义合并主 spec，并在归档后校验主 spec 中没有残留 delta-only section 标题。

如需预览而不实际执行，使用 `--dry-run` 参数。

### 3. 生命周期闭环

Spec 生命周期在此完成：
```
brainstorming → delta spec → 实施 → 验证 → 主 spec 合并 → design doc 标注 → 归档
```

## 退出条件

- 归档脚本执行成功（退出码 0）
- 归档目录 `openspec/changes/archive/YYYY-MM-DD-<change-name>/` 存在
- 归档后的 `.comet.yaml` 中 `archived: true`

归档脚本会把 `openspec/changes/<name>/` 移动到 `openspec/changes/archive/YYYY-MM-DD-<name>/`。

> **WARNING**: 归档成功后**不要再对原 change 名运行** `"$COMET_BASH" "$COMET_GUARD" <change-name> archive`，因为原活跃目录已经不存在。误调会导致 guard 报错"change directory not found"。归档完整性以脚本退出码和归档目录状态为准。

## 完成

Comet 流程全部完成。如需开始新工作，调用 `/comet` 或 `/comet-open`。

## 上下文压缩恢复

按 `comet/reference/context-recovery.md` 执行，phase 参数为 `archive`。若 `archived: true` 且归档目录存在，归档已完成，无需再次执行归档操作。
__COMET_ASSETS_SKILLS_ZH_COMET_ARCHIVE_SKILL_MD__

cat > "$TARGET_DIR/assets/skills-zh/comet-build/SKILL.md" <<'__COMET_ASSETS_SKILLS_ZH_COMET_BUILD_SKILL_MD__'
---
name: comet-build
description: "Comet 阶段 3：计划与构建。用 /comet-build 调用。制定计划并选择执行方式（subagent 或直接执行）实施。"
---

# Comet 阶段 3：计划与构建（Build）

## 前置条件

- Design Doc 已创建（阶段 2 完成）
- 活跃 change 存在

## 步骤

### 0. 入口状态验证（Entry Check）

执行入口验证：

```bash
COMET_ENV="${COMET_ENV:-$(find . "$HOME"/.*/skills "$HOME/.config" "$HOME/.gemini" -path '*/comet/scripts/comet-env.sh' -type f -print -quit 2>/dev/null)}"
if [ -z "$COMET_ENV" ]; then
  echo "ERROR: comet-env.sh not found. Ensure the comet skill is installed." >&2
  return 1
fi
. "$COMET_ENV"
"$COMET_BASH" "$COMET_STATE" check <name> build
```

验证通过后继续 Step 1。验证失败时脚本会输出具体失败原因。

**幂等性**：build 阶段所有操作可安全重复执行。读取 `.comet.yaml` 的 `phase` 字段确认仍在 build 阶段，读取 plan 文件头的 `base-ref`，再用 `grep -n '\- \[ \]' tasks.md | head -1` 找到第一个未勾选任务继续执行。已提交的任务不得重复提交。

### 1. 制定计划（Subagent Offload）

通过 subagent 创建实施计划，避免 planning skill 占用主 session 上下文。计划文件和执行反馈必须使用触发本次工作流的用户请求语言。

**Subagent 指令**：

你是实施计划专家。基于以下输入创建实施计划：

1. **立即执行：** 使用 Skill 工具加载 Superpowers `writing-plans` 技能。禁止跳过此步骤。技能加载后，ARGUMENTS 必须包含：`Language: 使用触发本次工作流的用户请求语言输出`
2. 读取 Design Doc（`docs/superpowers/specs/` 下的技术设计文档）
3. 读取 `openspec/changes/<name>/tasks.md`（任务边界）
4. 按技能指引创建计划

计划要求：
- 保存至 `docs/superpowers/plans/YYYY-MM-DD-<feature>.md`
- 引用设计文档，拆分为可执行任务
- **Plan 文件头必须包含关联元数据**：

```yaml
---
change: <openspec-change-name>
design-doc: docs/superpowers/specs/YYYY-MM-DD-<topic>-design.md
base-ref: <git rev-parse HEAD before implementation>
---
```

`base-ref` 用于验证阶段跨提交统计改动规模。创建计划时先记录当前提交：

```bash
git rev-parse HEAD
```

将计划写入文件后，返回文件路径。

**执行 subagent**：使用当前平台的 subagent 调度机制派发上述任务。

Subagent 完成后：
- 若返回有效文件路径且文件存在，记录为 plan
- 若 subagent 失败或返回路径无效，在主 session 内联加载 Superpowers `writing-plans` 技能创建计划（降级回退）

### 2. 更新计划状态并提供 plan-ready 暂停点

先记录 plan 路径：

```bash
"$COMET_BASH" "$COMET_STATE" set <name> plan docs/superpowers/plans/YYYY-MM-DD-feature.md
```

无需手动更新 phase，阶段守卫（guard `--apply`）会在退出条件满足后推进 `phase` 字段。

计划写入后，立即提供一个新的用户决策点：

| 选项 | 行为 | 说明 |
|------|------|------|
| A | 继续执行 | 保持在当前模型中，进入 Step 3 选择工作区隔离和执行方式 |
| B | 暂停切换模型 | 记录 `build_pause: plan-ready`，本次 `/comet-build` 停止，用户稍后可从 `/comet` 或 `/comet-build` 恢复 |

这是用户决策点。**必须按 `comet/reference/decision-point.md` 的协议暂停并等待用户明确选择**，不得自动继续，也不得把暂停写入 `build_mode`。

用户选择继续时：

```bash
"$COMET_BASH" "$COMET_STATE" set <name> build_pause null
```

用户选择暂停时：

```bash
"$COMET_BASH" "$COMET_STATE" set <name> build_pause plan-ready
```

设置 `build_pause: plan-ready` 后，当前调用停止。不要选择 `isolation` 或 `build_mode`，不要加载执行技能。

### 3. 选择工作方式

如果恢复时检测到 `build_pause: plan-ready` 且 `plan` 文件存在，不要重新运行 `writing-plans`。先告知用户当前停在 plan-ready 暂停点；用户确认继续后，设置：

```bash
"$COMET_BASH" "$COMET_STATE" set <name> build_pause null
```

然后继续本步骤选择工作区隔离和执行方式。

计划已写入当前分支。在开始执行前，**一次性询问用户**选择工作区隔离方式、执行方式、TDD 模式和代码审查模式：

**工作区隔离**：

| 选项 | 方式 | 说明 |
|------|------|------|
| A | 创建分支 | 在当前仓库创建新分支，简单快速 |
| B | 创建 Worktree | 隔离工作区，完全独立，适合并行开发 |

**推荐规则**：
- 变更涉及 ≤ 3 个文件 → 推荐 A
- 需要并行开发、当前分支有未提交工作 → 推荐 B

**执行方式**：

| 选项 | 技能 | 适用场景 |
|------|------|---------|
| A | Superpowers `subagent-driven-development` | 任务独立、复杂度高、需要双阶段审查 |
| B | Superpowers `executing-plans` | 任务简单、无子agent环境、轻量快速 |

**执行方式推荐规则**：
- 任务数 ≥ 3 → 推荐 A
- 任务数 ≤ 2 且无跨模块依赖 → 推荐 B
- 来自 hotfix 路径 → 推荐 B

这是用户决策点。**必须按 `comet/reference/decision-point.md` 的协议暂停并等待用户明确选择隔离方式、执行方式、TDD 模式和代码审查模式**，不得根据推荐规则自行选择 `branch` 或 `worktree`，也不得根据推荐规则自行选择执行方式、TDD 模式或代码审查模式。推荐规则只能用于说明建议，不能替代用户确认。

用户选择后，更新 `isolation`、执行方式、TDD 模式和代码审查模式相关字段：

```bash
"$COMET_BASH" "$COMET_STATE" set <name> isolation <branch|worktree>
```

- 若用户选择 `executing-plans`：运行 `"$COMET_BASH" "$COMET_STATE" set <name> subagent_dispatch null`，再运行 `"$COMET_BASH" "$COMET_STATE" set <name> build_mode executing-plans`
- 若用户选择 `subagent-driven-development`：先确认当前平台存在可调用的真实后台 subagent / Task / multi-agent 调度能力；确认后先运行 `"$COMET_BASH" "$COMET_STATE" set <name> subagent_dispatch confirmed`，再运行 `"$COMET_BASH" "$COMET_STATE" set <name> build_mode subagent-driven-development`
- 若无法确认真实后台调度能力，不得写入 `build_mode: subagent-driven-development`；必须暂停等待用户改选 `executing-plans`

**TDD 模式**：

| 选项 | 含义 | 适用场景 |
|------|------|---------|
| `tdd` | 每个任务先写失败测试再写实现 | 推荐。变更涉及业务逻辑、新功能、API |
| `direct` | 直接实现，不强制 TDD 流程 | 变更不需要测试覆盖，或用户选择跳过测试直接写代码。hotfix/tweak preset 默认使用 `direct` |

运行 `"$COMET_BASH" "$COMET_STATE" set <name> tdd_mode <tdd|direct>`

**代码审查模式**：

| 选项 | 含义 | 适用场景 |
|------|------|---------|
| `off` | 不自动派发代码审查 | 文档、配置、文案、小范围低风险任务 |
| `standard` | 只在任务完成后运行一次最终轻量代码审查；若发现问题，最多自动修复一轮，然后交给用户决策 | 默认推荐，适合大多数普通改动 |
| `thorough` | 按批次或风险边界运行合并审查，最后再运行一次完整审查 | 高风险、多模块、架构或安全相关改动 |

运行 `"$COMET_BASH" "$COMET_STATE" set <name> review_mode <off|standard|thorough>`

`isolation` 是脚本级硬约束。full workflow 初始化时可以为 `null`，但只允许存在到本步骤之前。若保持 `null`，`build → verify` 的 guard 和 `comet-state transition build-complete` 都会失败。

`subagent_dispatch` 是脚本级硬约束。`build_mode: subagent-driven-development` 离开 build 阶段前必须同时满足 `subagent_dispatch: confirmed`，否则 `comet-guard.sh build --apply` 和 `comet-state transition build-complete` 都会失败。

`tdd_mode` 是脚本级硬约束。full workflow 离开 build 阶段前 `tdd_mode` 必须已选择为 `tdd` 或 `direct`，否则 `comet-guard.sh build --apply` 和 `comet-state transition build-complete` 都会失败。

`review_mode` 是脚本级硬约束。新建 full workflow 离开 build 阶段前 `review_mode` 必须已选择为 `off`、`standard` 或 `thorough`，否则 `comet-guard.sh build --apply` 和 `comet-state transition build-complete` 都会失败。旧状态文件若没有该字段，按兼容路径继续，但恢复时应补写该字段。

`build_mode` 默认仅 hotfix/tweak preset 使用 `direct`。full workflow 不得默认使用 `direct`。只有用户明确要求跳过计划执行技能，且你已记录显式 override 时，才允许：

```bash
"$COMET_BASH" "$COMET_STATE" set <name> direct_override true
"$COMET_BASH" "$COMET_STATE" set <name> build_mode direct
```

没有 `direct_override: true` 时，full workflow 的 `build_mode=direct` 会被 guard 和状态转换同时拦截。

**执行隔离**：

- **branch**：根据 workflow 类型和当前日期推荐分支名，然后让用户确认或输入自定义名称。这是用户决策点——**必须使用当前平台可用的用户输入/确认机制暂停并等待用户明确确认或覆盖分支名**，不得跳过此步骤直接创建分支。

  分支命名规范：
  - 读取 `.comet.yaml` 的 `workflow` 字段确定前缀
  - `workflow: full` → 推荐 `feature/YYYYMMDD/<change-name>`
  - `workflow: hotfix` → 推荐 `hotfix/YYYYMMDD/<change-name>`
  - `workflow: tweak` → 推荐 `tweak/YYYYMMDD/<change-name>`
  - 日期取运行时 `date +%Y%m%d` 的结果

  示例：如果 change 名称为 `fix-login-bug`，今天是 2026-06-09，则推荐 `feature/20260609/fix-login-bug`

  用户确认或提供自定义分支名后，执行 `git checkout -b <branch-name>`，后续工作在新分支上进行。

- **worktree**：必须使用 Skill 工具加载 Superpowers `using-git-worktrees` 技能创建隔离工作区。禁止用普通 shell 命令或原生工具绕过该技能；如该技能不可用，停止流程并提示安装或启用 Superpowers 技能。

创建隔离后，确认计划文件可访问（分支方式天然可访问；worktree 方式需确认计划已提交）。若 worktree 模式下计划文件尚未提交，先提交计划文件再创建 worktree：

```bash
git add docs/superpowers/plans/YYYY-MM-DD-feature.md
git commit -m "chore: add implementation plan"
```

**执行计划**：必须按 `build_mode` 的真实运行位置处理。

- `build_mode: executing-plans`：**立即执行：** 使用 Skill 工具加载 Superpowers `executing-plans` 技能。禁止跳过此步骤。若该技能不可用，停止流程并提示安装或启用对应技能，不要用普通对话替代该步骤。技能加载后，ARGUMENTS 必须包含与 Step 1 相同的 Language 约束：`Language: 使用触发本次工作流的用户请求语言输出`。按计划执行。
- `build_mode: subagent-driven-development`：主会话只负责协调，禁止直接编写实现代码。**立即执行：** 使用 Skill 工具加载 Superpowers `subagent-driven-development` 技能。技能加载后，读取 `comet/reference/subagent-dispatch.md` 获取 Comet 专属扩展（真实后台调度、任务隔离、勾选验证、TDD 约束、连续执行、上下文恢复），与技能工作流配合应用。若两者发生冲突，以更具体的 Comet 扩展为准。
- 如果当前平台没有真实后台 agent 调度能力，必须暂停并等待用户选择改用主窗口执行。用户选择改用主窗口执行后，必须先运行 `"$COMET_BASH" "$COMET_STATE" set <name> build_mode executing-plans`，再按 `build_mode: executing-plans` 分支加载 Superpowers `executing-plans` 技能。用户未明确选择前，不得继续执行任务。

**TDD 模式执行约束**：

若 `tdd_mode: tdd`：
- `build_mode: executing-plans`：加载执行技能后、执行第一个任务前，**立即执行：** 使用 Skill 工具加载 Superpowers `test-driven-development` 技能一次。禁止跳过此步骤。技能加载后，从第一个未勾选任务开始，对每个任务遵循已加载的 TDD Red-Green-Refactor 循环执行。不得跳过失败测试验证阶段。后续任务不再重新加载该技能，直接遵循已加载流程。若上下文压缩后恢复，重新运行本步骤加载 TDD 技能一次，然后从第一个未勾选任务继续。
- `build_mode: subagent-driven-development`：主会话不加载 TDD skill；TDD 约束和证据门槛已在 `comet/reference/subagent-dispatch.md` 中定义，每个后台 implementer 和修复 agent 必须自行使用 Skill 工具加载 Superpowers `test-driven-development` 技能，并遵循 Comet 注入的 TDD 硬约束。

若 `tdd_mode: direct`：按正常流程执行，不强制 TDD。

**`executing-plans` review gate**：

当 `build_mode` 为 `executing-plans` 且 `review_mode` 为 `standard` 或 `thorough` 时，在所有计划任务完成后、运行 build → verify 阶段守卫前，必须使用 Skill 工具加载 Superpowers `requesting-code-review` 技能并请求一次代码审查。`review_mode: off` 时跳过自动代码审查，不加载 `requesting-code-review`，并在验证报告草稿或 tasks.md 中记录跳过原因。

要求：
- `requesting-code-review` 技能必须在 `"$COMET_BASH" "$COMET_GUARD" <change-name> build --apply` 之前加载
- 若 `requesting-code-review` 技能不可用，跳过 review gate 但必须在 tasks.md 中记录 `<!-- review skipped: skill unavailable -->`，并继续 guard 流转
- CRITICAL review 发现（安全漏洞、数据丢失风险、构建/测试失败）必须先修复，不得带入 verify
- 非 CRITICAL review 发现如选择接受，必须在 tasks.md、commit body、验证报告草稿或其他持久产物中记录接受原因和影响范围

### 3b. 执行中异常调试（异常调试协议）

执行任务期间，只要运行程序、测试、构建或手动验证时出现崩溃、异常行为、测试失败或构建失败，必须使用 Skill 工具加载 Superpowers `systematic-debugging` 技能。在完成根因调查前，不得提出或实施源码修复。

具体调查、最小失败测试、修复验证和保持当前 change 验证闭环的要求，按 `comet/reference/debug-gate.md` 执行。

### 4. Spec 增量更新

实施过程中发现初版 spec 不完整时，按变更规模分级处理：

| 规模 | 触发条件 | 做法 |
|------|---------|------|
| 小 | 遗漏验收场景、边界条件 | 直接编辑 delta spec + design.md，追加 tasks.md 任务 |
| 中 | 接口变更、新增组件、数据流变化 | **使用当前平台可用的用户输入/确认机制暂停并等待用户确认后**，必须使用 Skill 工具加载 Superpowers `brainstorming` 更新 Design Doc + delta spec |
| 大 | 全新 capability 需求 | **必须使用当前平台可用的用户输入/确认机制暂停并等待用户确认拆分**；用户确认后，通过 `/comet-open` 创建独立 change |

**50% 阈值判定**：以 tasks.md 初始任务总数为基准，若新增任务数超过该总数的一半，视为超出原计划范围，**必须按 `comet/reference/decision-point.md` 的协议暂停并等待用户决定是否拆分为新 change**。

创建独立 change 时必须调用 `/comet-open`，不得直接调用 `/opsx:new`。`/comet-open` 会同时创建 OpenSpec 产物和 `.comet.yaml`，避免新 change 脱离 Comet 状态机。

**用户选择必须包含**：
- 「拆分为新 change」— 通过 `/comet-open` 创建独立 change
- 「继续在当前 change 内完成」— 记录范围扩展决策，更新 tasks.md 和 delta spec 后继续

**原则**：
- delta spec 是活文档，本阶段期间随时可修改
- 每次更新应提交，commit message 说明变更原因
- 不提前同步到 main spec，归档时统一同步
- 小规模增量直接改 delta spec 时，应在 commit message 中注明，便于归档时判断 design doc 漂移

### 5. 上下文管理

Build 是最长阶段，可能跨越大量任务。为支持上下文压缩后断点恢复：

- **每完成一个 task**：按当前执行分支和 `review_mode` 完成验收后再勾选对应任务并提交。`subagent-driven-development` 在 `standard` 或 `off` 时不做 per-task reviewer；在 `thorough` 时只按批次或风险边界做合并审查，不做每 task 双审查。所有模式都必须按任务唯一文本完成定向检查。可用 `grep -c '\- \[ \]' tasks.md` 检查剩余未勾选数，无需重新读取整个文件
- **上下文压缩后恢复**：按 `comet/reference/context-recovery.md` 执行，phase 参数为 `build`。
- **用户手动修改恢复**：按 `comet/reference/dirty-worktree.md` 协议处理未提交改动。该协议定义了检查步骤、归因分类和禁令。build 阶段的特殊处理：
  1. 归因后，若 diff 暗示计划或 spec 已变化，按 Step 4「Spec 增量更新」分级处理
- **长任务拆分**：单任务超过 200 行代码变更时，考虑拆分为多个子任务分别提交

## 退出条件

- tasks.md 全部勾选
- 代码已提交
- 已显式运行项目对应的构建/测试命令并通过（不要只依赖 guard 自动猜测）
- `isolation` 已写为 `branch` 或 `worktree`
- `build_mode` 已写为 `subagent-driven-development`、`executing-plans` 或带显式 override 的 `direct`；若为 `subagent-driven-development`，`subagent_dispatch` 必须为 `confirmed`
- `tdd_mode` 已写为 `tdd` 或 `direct`
- `review_mode` 已写为 `off`、`standard` 或 `thorough`
- 若 `review_mode` 为 `standard` 或 `thorough`，已按对应模式完成代码审查，且 CRITICAL review 发现已修复或非 CRITICAL review 发现已记录接受理由；若 `review_mode: off`，已在持久产物中记录跳过自动代码审查的原因
- **阶段守卫**：运行 `"$COMET_BASH" "$COMET_GUARD" <change-name> build --apply`，全部 PASS 后由守卫推进到 `phase: verify`（此步骤更新 `phase` 字段，与 `auto_transition` 无关）

Guard 会优先读取项目配置中的命令：

```yaml
build_command: <build command>
verify_command: <verify command>
```

配置位置可为 change 的 `.comet.yaml`，也可为仓库根目录的 `.comet.yaml` / `comet.yaml` / `.comet.yml` / `comet.yml`。
未配置时才回退到 `npm run build`、Maven 或 Cargo 的默认探测。构建失败时 guard 会打印失败命令输出，作为排查证据。

退出前运行阶段守卫推进 phase（此步骤与 `auto_transition` 无关）：

```bash
"$COMET_BASH" "$COMET_GUARD" <change-name> build --apply
```

状态文件自动更新为 `phase: verify`、`verify_result: pending`。

## 自动衔接下一阶段

按 `comet/reference/auto-transition.md` 执行。关键命令：

```bash
"$COMET_BASH" "$COMET_STATE" next <change-name>
```

- `NEXT: auto` → 调用 `SKILL` 指向的 skill 进入下一阶段
- `NEXT: manual` → 不要调用下一 skill，按 `HINT` 提示用户手动运行 `/<SKILL>`
- `NEXT: done` → 流程已完成，无需继续
__COMET_ASSETS_SKILLS_ZH_COMET_BUILD_SKILL_MD__

cat > "$TARGET_DIR/assets/skills-zh/comet-design/SKILL.md" <<'__COMET_ASSETS_SKILLS_ZH_COMET_DESIGN_SKILL_MD__'
---
name: comet-design
description: "Comet 阶段 2：深度设计。用 /comet-design 调用。通过 brainstorming 产出 Design Doc 和 delta spec。"
---

# Comet 阶段 2：深度设计（Design）

## 前置条件

- 活跃 change 已存在（proposal.md、design.md、tasks.md）
- 无 Design Doc（`docs/superpowers/specs/` 下无对应文件）

## 步骤

### 0. 入口状态验证（Entry Check）

执行入口验证：

```bash
COMET_ENV="${COMET_ENV:-$(find . "$HOME"/.*/skills "$HOME/.config" "$HOME/.gemini" -path '*/comet/scripts/comet-env.sh' -type f -print -quit 2>/dev/null)}"
if [ -z "$COMET_ENV" ]; then
  echo "ERROR: comet-env.sh not found. Ensure the comet skill is installed." >&2
  return 1
fi
. "$COMET_ENV"
"$COMET_BASH" "$COMET_STATE" check <name> design
```

验证通过后继续 Step 1。验证失败时脚本会输出具体失败原因。

**幂等性**：所有 design 阶段操作可以安全重试。如果 `handoff_context` 和 `handoff_hash` 已存在，先确认它们与当前产物一致再决定是否重新生成。

### 1a. 生成 OpenSpec → Superpowers 交接包

**必须由脚本生成，不允许 agent 临场手写 summary 代替。**

```bash
"$COMET_BASH" "$COMET_HANDOFF" <change-name> design --write
```

脚本会根据 change `.comet.yaml` 当前记录的 `context_compression` 值生成并记录交接包。新 change 初始化时，该值默认来自项目 `.comet/config.yaml`（或脚本默认值）；若后续显式修改 change 的 `.comet.yaml`，下次生成 handoff 时会按修改后的值生效。

默认 `context_compression: off` 时生成：

```text
openspec/changes/<name>/.comet/handoff/design-context.json
openspec/changes/<name>/.comet/handoff/design-context.md
```

启用 beta（即 change `.comet.yaml` 中 `context_compression: beta`）时生成：

```text
openspec/changes/<name>/.comet/handoff/spec-context.json
openspec/changes/<name>/.comet/handoff/spec-context.md
```

并在 `.comet.yaml` 写入：

```yaml
handoff_context: <根据模式写入 design-context.json 或 spec-context.json>
handoff_hash: <sha256>
```

默认交接包是 **compact 可追溯摘录**，不是 agent summary：
- `design-context.json`：机器索引，包含 change、phase、canonical spec、source paths、hash
- `design-context.md`：供 Superpowers 阅读的上下文，包含脚本标记、source path、line range、sha256、确定性摘录
- 超出摘录预算时标记 `[TRUNCATED]`，并保留 Full source 路径

beta 交接包是 **结构化 spec projection**，用于减少 OpenSpec 原文 token 占用但避免实现漂移：
- `spec-context.json`：机器索引，包含 change、phase、mode=beta、source paths、context_hash、files 角色
- `spec-context.md`：供 Superpowers 阅读的紧凑上下文，verbatim 投影 delta spec 文件并按 hash 引用支撑产物
- OpenSpec delta spec 仍是 canonical spec；projection 缺失或过期时必须重新生成或读取源 spec，不得用 agent summary 替代

如确实需要全文上下文，可显式运行：

```bash
"$COMET_BASH" "$COMET_HANDOFF" <change-name> design --write --full
```

交接包来源来自 OpenSpec open 阶段产物：
- `proposal.md`：目标、动机、范围、非目标
- `design.md`：高层架构决策、方案约束
- `tasks.md`：初始任务边界
- `specs/*/spec.md`：delta 能力规格

### 1b. 执行 Brainstorming（带上下文）

**立即执行：** 使用 Skill 工具加载 Superpowers `brainstorming` 技能。禁止跳过此步骤。

技能加载时，ARGUMENTS 必须包含：

```text
Language: 使用触发本次工作流的用户请求语言输出
```

技能加载后，按其指引使用以下上下文：

```text
Change: <change-name>
OpenSpec Context Pack: openspec/changes/<name>/.comet/handoff/design-context.md
Machine handoff: openspec/changes/<name>/.comet/handoff/design-context.json

如 context_compression: beta，则使用：
OpenSpec Context Pack: openspec/changes/<name>/.comet/handoff/spec-context.md
Machine handoff: openspec/changes/<name>/.comet/handoff/spec-context.json

OpenSpec 产物是上游事实源，但不得用“跳过重复上下文探索”削弱 Superpowers `brainstorming` 的澄清流程。
你的任务是基于交接包做深度技术设计：实现方案、技术风险、测试策略、边界条件。
如发现目标、范围、非目标、验收场景或关键约束仍不清楚，必须先继续提问并形成设计方案，不得只进行一轮问答就创建 Design Doc。
不要重写 proposal/spec；如发现 OpenSpec delta spec 缺少验收场景，只能提出 Spec Patch，并回写 OpenSpec delta spec；不要在 Design Doc 中创建第二份需求 spec。Spec Patch 仅限于补充验收场景、修正歧义描述或添加边界条件，不得大幅重写 delta spec 的结构或范围——如需大幅修改，应标记为设计发现并回到 brainstorming 确认。

Design Doc frontmatter 必须最小化，只包含：
---
comet_change: <change-name>
role: technical-design
canonical_spec: openspec
---

按 Superpowers `brainstorming` 技能原流程推进：澄清问题、2-3 个方案、分段确认设计。不得提前写入 Design Doc。
```

禁止在未加载该技能的情况下继续。

如 Superpowers `brainstorming` 技能不可用，停止流程并提示安装或启用 Superpowers 技能，不要用普通对话替代该步骤。

技能加载后，按其指引产出设计方案（以对话形式呈现）：
- 技术方案：架构、数据流、关键技术选型与风险
- 测试策略
- 需求/范围缺口与需回写的 Spec Patch
- 如需补充验收场景，标明将回写的 delta spec 变更

brainstorming 阶段不写入 Design Doc 文件，仅产出设计方案供 Step 1c 用户确认。确认后才创建 `docs/superpowers/specs/YYYY-MM-DD-<topic>-design.md` 并回写 delta spec。

但为了上下文压缩恢复，brainstorming 过程中必须增量更新 `brainstorm-summary.md`。每轮澄清或方案迭代后，只要产生新的已确认事实、关键约束、候选方案、取舍/风险、测试策略或 Spec Patch 候选，就更新该文件；未确认内容必须标注为“待确认”或“候选”。该文件是恢复检查点，不是 Design Doc，也不得替代 Step 1c 的用户确认。

### 1c. 用户确认设计方案（阻塞点）

brainstorming 产出设计方案后，**必须按 `comet/reference/decision-point.md` 的协议暂停并等待用户明确确认设计方案**。不得在用户确认前创建最终 Design Doc、写入 `design_doc`、运行 design guard，或进入 `/comet-build`。

暂停时只展示必要摘要：
- 采用的技术方案
- 关键取舍与风险
- 测试策略
- 如有 Spec Patch，列出将回写的 delta spec 变更

用户明确确认后，才继续 Step 2。若用户要求调整，继续 brainstorming 迭代，直到用户确认。


### 1d. Brainstorming 检查点定稿

用户确认设计方案后，在创建 Design Doc 前，创建或更新已增量维护的检查点文件，将其定稿为确认后的设计方案摘要：

```bash
mkdir -p openspec/changes/<name>/.comet/handoff
```

`openspec/changes/<name>/.comet/handoff/brainstorm-summary.md` 结构：

```markdown
# Brainstorm Summary

- Change: <change-name>
- Date: <YYYY-MM-DD>

## 确认的技术方案

<用户确认的方案摘要>

## 关键取舍与风险

<主要取舍和风险>

## 测试策略

<测试方法概述>

## Spec Patch

<将回写的 delta spec 变更，无则写"无">
```

**上下文压缩说明**：每次增量更新 `brainstorm-summary.md` 后，都是相对安全的压缩恢复点。Brainstorming 完成后，如上下文窗口紧张，应优先在此处进行压缩。压缩后重新加载以下文件继续 Step 2：
- `openspec/changes/<name>/.comet/handoff/brainstorm-summary.md`
- `openspec/changes/<name>/.comet/handoff/design-context.md`（或 beta 模式的 `spec-context.md`）
- `openspec/changes/<name>/.comet/handoff/design-context.json`（或 beta 模式的 `spec-context.json`）

### 1e. 主动式上下文压缩

完成 Step 1d 并确认 `brainstorm-summary.md` 已写入后，进入 Design Doc 创建前的主动式上下文压缩。此时 OpenSpec 交接包、brainstorming 决策和待确认项都已落盘，应主动释放前面读取 Spec 和 brainstorming 消耗的上下文，为 Step 2 及后续 Build 阶段保留窗口。

执行规则：
- 如果当前平台提供原生上下文压缩/清理机制（例如宿主 Agent 的 compact/compaction 命令、工具或 UI 操作），必须在这里触发一次主动压缩；不要尝试用 shell 脚本伪造压缩命令。
- 压缩恢复提示必须包含 change 名称、当前步骤（Design Step 2）、以及上方三类需重新加载的 handoff 文件。
- 如果当前平台无法由 agent 程序化触发压缩，必须暂停并提示用户在宿主平台执行手动压缩；用户确认无法压缩或要求继续时，才继续 Step 2。

### 2. 创建 Design Doc

基于 brainstorming 对话的完整上下文（仍在主 session 中），创建 Design Doc。

Design Doc frontmatter 必须最小化：

```yaml
---
comet_change: <change-name>
role: technical-design
canonical_spec: openspec
---
```

将 Design Doc 写入 `docs/superpowers/specs/YYYY-MM-DD-<topic>-design.md`。
如需回写 delta spec（Spec Patch），同时编辑对应的 `specs/*/spec.md`。

**上下文压缩恢复**：若上下文已被压缩，从 `brainstorm-summary.md` + handoff 上下文恢复。若用户尚未确认设计方案，回到 Step 1b/1c 继续 brainstorming；若用户已确认，继续创建 Design Doc。brainstorm-summary.md 是压缩恢复的落盘点，不是 Design Doc 的唯一输入——创建时应尽可能利用恢复后的完整上下文。

### 3. 更新 Comet 状态

先记录 design_doc 路径。如果 Spec Patch 回写了 delta spec（新增或修改了 `specs/*/spec.md`），必须重新生成 handoff 以更新 hash：

```bash
# 记录 design_doc 路径
"$COMET_BASH" "$COMET_STATE" set <name> design_doc docs/superpowers/specs/YYYY-MM-DD-topic-design.md

# 如有 delta spec 变更，重新生成 handoff（更新 hash）
"$COMET_BASH" "$COMET_HANDOFF" <change-name> design --write

# 阶段守卫推进 phase 到下一阶段
"$COMET_BASH" "$COMET_GUARD" <change-name> design --apply
```

如果没有 delta spec 变更，跳过 handoff 重新生成步骤。状态文件自动更新，无需手动编辑其他字段。

## 退出条件

- Design Doc 已创建并保存
- Design Doc frontmatter 包含 `comet_change`、`role: technical-design`、`canonical_spec: openspec`
- `handoff_context` 和 `handoff_hash` 已写入 `.comet.yaml`（由 guard 强制校验）
- `handoff_hash` 与当前 OpenSpec open 阶段产物一致（由 guard 强制校验）
- `design-context.md` 或 beta `spec-context.md` 必须是脚本生成，且包含 source path、mode、sha256 等可追溯标记（由 guard 强制校验）
- beta 模式下，`spec-context.json` 必须结构合法且引用当前源文件（由 guard 强制校验）
- 如有新能力或补充验收场景，OpenSpec delta spec 已创建/更新
- `design_doc` 已写入 `.comet.yaml`
- **阶段守卫**：运行 `"$COMET_BASH" "$COMET_GUARD" <change-name> design --apply`，全部 PASS 后由守卫推进到 `phase: build`（此步骤更新 `phase` 字段，与 `auto_transition` 无关）

退出前必须使用 `--apply`：

```bash
"$COMET_BASH" "$COMET_GUARD" <change-name> design --apply
```

## 上下文压缩恢复

按 `comet/reference/context-recovery.md` 执行，phase 参数为 `design`。

## 自动衔接下一阶段

按 `comet/reference/auto-transition.md` 执行。关键命令：

```bash
"$COMET_BASH" "$COMET_STATE" next <change-name>
```

- `NEXT: auto` → 调用 `SKILL` 指向的 skill 进入下一阶段
- `NEXT: manual` → 不要调用下一 skill，按 `HINT` 提示用户手动运行 `/<SKILL>`
- `NEXT: done` → 流程已完成，无需继续
__COMET_ASSETS_SKILLS_ZH_COMET_DESIGN_SKILL_MD__

cat > "$TARGET_DIR/assets/skills-zh/comet-hotfix/SKILL.md" <<'__COMET_ASSETS_SKILLS_ZH_COMET_HOTFIX_SKILL_MD__'
---
name: comet-hotfix
description: "Comet 预设路径：Bug fix / 热修复。跳过 brainstorming，直接 open → build → verify → archive。适用于行为修复、不涉及新 capability 设计的场景。"
---

# Comet 预设路径：Hotfix

快速 bug fix 工作流：open → build → verify → archive。跳过 brainstorming 和完整 plan，适用于行为修复、不涉及新 capability 设计的场景。

**适用条件**（必须全部满足）：
1. 修复已有功能的 bug，不新增 capability
2. 不涉及接口变更或架构调整
3. 改动范围可预估（通常 ≤ 2 个文件）

**不适用**：如修复过程发现需要架构调整，应升级为完整 `/comet` 流程。

---

## 流程（preset workflow，6 步）

### 0. 输出语言约束

精简版 OpenSpec 产物必须使用触发本次工作流的用户请求语言。

执行链路：open → build → verify → archive。Hotfix 为每个阶段提供默认决策：精简开启、直接构建、按规模验证、验证通过后进入归档前最终确认。

开始前先定位 Comet 脚本：

```bash
COMET_ENV="${COMET_ENV:-$(find . "$HOME"/.*/skills "$HOME/.config" "$HOME/.gemini" -path '*/comet/scripts/comet-env.sh' -type f -print -quit 2>/dev/null)}"
if [ -z "$COMET_ENV" ]; then
  echo "ERROR: comet-env.sh not found. Ensure the comet skill is installed." >&2
  return 1
fi
. "$COMET_ENV"
```

### 1. 快速开启（preset open）

复用 Comet open 能力创建 change，但使用 hotfix 默认值：不执行 `openspec-explore` 长探索，直接进入精简 change 创建。

**立即执行：** 使用 Skill 工具加载 `openspec-new-change` 技能。禁止跳过此步骤。

技能加载后，按其指引创建精简版产物：
  - `proposal.md` — 问题描述 + 根因分析 + 修复目标（无需方案对比）
  - `design.md` — 修复方案（1 个即可，无需多方案对比）
  - `tasks.md` — 修复任务清单
- **无需 delta spec**（除非修复改变了已有 spec 的验收场景）

初始化 Comet 状态文件：

```bash
"$COMET_BASH" "$COMET_STATE" init <name> hotfix
```

初始化后验证状态：

```bash
"$COMET_BASH" "$COMET_STATE" check <name> open
```

阶段守卫完成 open → build 过渡：

```bash
"$COMET_BASH" "$COMET_GUARD" <change-name> open --apply
```

检查 `auto_transition` 决定是否继续：

```bash
"$COMET_BASH" "$COMET_STATE" next <name>
```

- `NEXT: auto` → 继续 Step 2
- `NEXT: manual` → 暂停，按 `HINT` 提示用户手动运行 `/<SKILL>`

### 2. 直接构建（preset build）

使用 hotfix 默认值：`build_mode: direct`，默认 `review_mode: off`。跳过 Superpowers `brainstorming` 和 `writing-plans`（除非任务 > 3 个；若超过 3 个任务，转入 `/comet-build` 的计划与执行方式选择——注意这不触发 full workflow 升级，仅切换执行方式）。

继续或开始修改前，按 `comet/reference/dirty-worktree.md` 协议处理未提交改动。若归因后发现修复范围超出 hotfix，按本文件“升级条件”处理。

**立即执行：** 按 tasks.md 逐个执行任务：

1. 读取 `openspec/changes/<name>/tasks.md`，获取未完成任务列表
2. 对每个未完成任务：
   - 根据任务描述修改代码
   - 运行项目格式化命令（如 `mvn spotless:apply`、`npm run format` 等）
   - 运行相关测试确认通过
   - 将 tasks.md 中对应 `- [ ]` 勾选为 `- [x]`
   - 提交代码，commit message 格式：`fix: <简述修复>`
3. 全部任务完成后，显式运行项目相关测试和构建命令

执行 hotfix 期间，只要运行程序、测试、构建或手动验证时出现崩溃、异常行为、测试失败或构建失败，必须使用 Skill 工具加载 Superpowers `systematic-debugging` 技能。在完成根因调查前，不得提出或实施源码修复。

具体调查、最小失败测试、修复验证和保持当前 change 验证闭环的要求，按 `comet/reference/debug-gate.md` 执行。

**如修复影响已有 spec 验收场景**：
- 在 `openspec/changes/<name>/specs/<capability>/spec.md` 创建 delta spec
- 仅包含 `## MODIFIED Requirements` 部分

### 3. 根因消除检查

**在运行 build guard 之前执行**，确保修复确实消除了问题根因：

1. 读取 proposal.md 中的 bug 描述和根因
2. 搜索验证问题代码不再存在
3. 如根因未消除，回到 Step 2 继续修复（此时仍在 build 阶段，无需状态回退）

**升级条件**：
- 根因消除检查发现深层架构问题 → 停止 hotfix，按升级条件阻塞确认处理
- 修复需要额外接口变更 → 停止 hotfix，按升级条件阻塞确认处理

根因确认消除后，运行阶段守卫完成 build → verify 过渡：

```bash
"$COMET_BASH" "$COMET_GUARD" <change-name> build --apply
```

状态文件自动更新为 `phase: verify`、`verify_result: pending`，然后进入验证。

### 4. 验证（preset verify）

复用 `/comet-verify`，由 comet-verify 的规模评估决定轻量或完整验证。

**立即执行：** 使用 Skill 工具加载 `comet-verify` 技能。禁止跳过此步骤。

无 delta spec 的小范围 hotfix 通常满足轻量验证条件（≤ 3 tasks、≤ 2 files），comet-verify 的规模评估会选择轻量验证路径（6 项快速检查；默认 `review_mode: off` 时不自动派发代码审查）。若用户希望增加审查，可在验证前运行 `"$COMET_BASH" "$COMET_STATE" set <name> review_mode standard` 或 `thorough`。若 hotfix 创建了 delta spec，则根据 comet-verify 的规模评估规则进入完整验证路径。

验证通过后，按 `/comet-verify` 的规则将 `.comet.yaml` 的 `verify_result` 记录为 `pass`，归档前不得跳过该状态。验证通过后仍必须进入 `/comet-archive` 的归档前最终确认，不得自动运行归档脚本。

### 5. 归档（preset archive）

复用 `/comet-archive`。归档前必须满足 `.comet.yaml` 中 `verify_result: pass`，并等待 `/comet-archive` 的归档前最终确认。

**立即执行：** 使用 Skill 工具加载 `comet-archive` 技能进行归档。禁止跳过此步骤。
如有 delta spec，按 comet-archive 规则同步到 main spec，并处理关联 Design Doc 与 Plan 的归档标注。

---

## 连续执行模式

<IMPORTANT>
Hotfix 流程默认 **一次性连续执行**。调用 `/comet-hotfix` 后，agent 在 hotfix 自有步骤间自动推进，不主动停顿。**例外**：若 `auto_transition: false`，则在每个 phase 边界（build/verify/archive 之间）停下，由用户手动运行下一阶段命令——此时连续执行降级为逐阶段手动推进，详见下方「自动衔接下一阶段」。但无论 `auto_transition` 取何值，以下情况都必须暂停等待用户确认：

1. 遇到升级条件（见"升级条件"章节），**必须使用当前平台可用的用户输入/确认机制暂停并等待用户明确确认**升级为完整流程
2. 任务超过 3 个转入 `/comet-build` 时的工作区隔离和执行方式选择
3. 验证阶段（comet-verify）的验证失败决策和分支处理决策
4. 归档前最终确认（comet-archive 执行归档脚本前）

执行顺序：快速开启 → 直接构建 → 根因消除检查 → 验证 → 归档 → 完成

每个阶段完成后立即进入下一阶段。阶段内部仍必须按上文要求调用对应 Comet/OpenSpec/Superpowers skill，被调用的 skill 如有自己的用户决策点，按该 skill 规则执行。
</IMPORTANT>

---

## 升级条件

满足以下**任一**条件时，停止 hotfix 流程，升级为完整 `/comet`：

| 条件 | 说明 |
|------|------|
| 改动涉及 **3+ 文件** | 超出单点修复范围 |
| 架构变更 | 新模块、新接口、新依赖 |
| 数据库 schema 变更 | 结构性调整 |
| 引入新的 public API | 修复产生了新的对外接口 |
| 修复范围超出单一函数/模块 | 需要多处协调修改 |

满足升级条件时**必须按 `comet/reference/decision-point.md` 的协议暂停并等待用户明确确认**升级为完整 `/comet` 流程。不得直接进入 `/comet-design`，不得自动补充 Design Doc。

用户确认升级后，**必须先更新 workflow 和 phase 字段**再进入完整流程：

```bash
"$COMET_BASH" "$COMET_STATE" set <name> workflow full
"$COMET_BASH" "$COMET_STATE" set <name> phase design
```

然后在当前 change 基础上补充 Design Doc：**立即使用 Skill 工具加载 `comet-design` skill**，后续正常走完整流程。若用户不确认升级，停止 hotfix 并报告当前变更已超出 hotfix 适用范围。

---

## 退出条件

- Bug 已修复，测试通过
- change 已归档
- 如有 spec 变更，已同步到 main spec
- **阶段守卫**：build → verify 前运行 `"$COMET_BASH" "$COMET_GUARD" <change-name> build --apply`，verify → archive 前按 `/comet-verify` 规则运行 `"$COMET_BASH" "$COMET_GUARD" <change-name> verify --apply`

## 自动衔接下一阶段

按 `comet/reference/auto-transition.md` 执行。关键命令：

```bash
"$COMET_BASH" "$COMET_STATE" next <name>
```

- `NEXT: auto` → 调用 `SKILL` 指向的 skill 继续 hotfix 流程（`phase: build` 返回 `comet-hotfix`，`verify` 返回 `comet-verify`，`archive` 返回 `comet-archive`）
- `NEXT: manual` → 不要调用下一 skill，按 `HINT` 提示用户手动运行 `/<SKILL>`
- `NEXT: done` → 流程已完成，无需继续
__COMET_ASSETS_SKILLS_ZH_COMET_HOTFIX_SKILL_MD__

cat > "$TARGET_DIR/assets/skills-zh/comet-open/SKILL.md" <<'__COMET_ASSETS_SKILLS_ZH_COMET_OPEN_SKILL_MD__'
---
name: comet-open
description: "Comet 阶段 1：开启。用 /comet-open 调用。通过 OpenSpec 探索想法、确认需求澄清，再创建 change 结构（proposal + design + tasks）。"
---

# Comet 阶段 1：开启（Open）

## 前置条件

- 无活跃 change，或用户希望创建新 change

## 步骤

### 0. 输出语言约束

传递给 OpenSpec 的所有提问和产物要求都必须包含输出语言约束：使用触发本次工作流的用户请求语言。恢复已有 change 且产物已有明确主语言时，除非用户明确要求切换，否则保持该语言。

### 1. 探索想法与需求澄清

**立即执行：** 使用 Skill 工具加载 `openspec-explore` 技能。禁止跳过此步骤。

技能加载后，按其指引探索问题空间，但不得把一次问答视为足够澄清。必须围绕下列内容继续提问、对齐并形成澄清摘要：
- 目标：用户真正要解决的问题和期望结果
- 非目标：本次明确不做的内容
- 范围边界：涉及/不涉及的模块、用户、平台或数据
- 关键未知项：仍不确定的假设、风险或依赖
- 验收场景草案：至少覆盖核心成功场景和关键边界场景

澄清摘要必须包含：目标、非目标、范围边界、关键未知项、验收场景草案。

### 1a. PRD 拆分预检（阻塞点）

当用户输入是大型 PRD、路线图、完整产品方案，或澄清摘要显示包含多个独立能力、模块、用户路径或里程碑时，必须在创建 OpenSpec artifacts 前评估是否需要拆分为多个 change。

拆分预检必须基于已澄清的信息，输出候选拆分清单。每个候选拆分项必须包含：
- 建议 change 名称
- 目标与范围边界
- 明确非目标
- 依赖关系或推荐执行顺序
- 对应的核心验收场景

满足任一条件时，应推荐拆分：
- PRD 包含多个可独立设计、构建、验证、归档的 capability
- 涉及多个模块或用户路径，且其中一部分可独立交付
- 存在明显分阶段里程碑
- 预计会产生多个 delta spec 或超过 3 个大任务
- 任一部分失败或延期不应阻塞其他部分进入后续阶段

如推荐拆分，必须按 `comet/reference/decision-point.md` 的协议暂停并等待用户选择。

用户选择必须包含：
- 「创建多个 OpenSpec changes」— 按候选拆分逐个创建独立 change
- 「保持为一个 change」— 继续单 change 流程，并在 proposal/design/tasks 中记录不拆分原因
- 「调整拆分方案后继续」— 用户说明调整方向后，重新输出候选拆分清单并再次确认

每个被接受的拆分项都必须通过 `/comet-open` 创建独立 change，不得直接调用 `/opsx:new`。`/comet-open` 负责同时创建 OpenSpec artifacts 和 `.comet.yaml`，确保每个 change 都进入 Comet 状态机。

不得在用户完成 PRD 拆分选择前创建 proposal.md、design.md 或 tasks.md。若用户选择创建多个 change，当前 `/comet-open` 调用只负责完成拆分确认与调度，随后按用户确认的顺序分别进入每个拆分项的 `/comet-open`。

批量拆分模式下，进入每个拆分项的 `/comet-open` 时必须明确标注「已确认拆分项」并携带该拆分项的目标、范围、非目标和验收场景。已确认拆分项默认跳过 PRD 拆分预检，除非该拆分项本身仍明显包含多个独立 capability。

批量拆分模式下，单个拆分项完成 open 阶段后不得自动流转到 `/comet-design`。拆分完毕后必须暂停询问用户开始哪一个 change；用户选择后，只推进该 change 进入 `/comet-design`，其他 change 保持 active，稍后通过 `/comet` 恢复。

最小断点恢复规则：不新增专用批量状态文件。若批量拆分过程中断，恢复时先检查已创建的 active changes；已存在且包含 `.comet.yaml` 的拆分项不得重复创建，未创建的拆分项按用户已确认的拆分清单继续通过 `/comet-open` 创建。若对话中已确认的拆分清单不可恢复，必须重新向用户确认拆分清单后再继续。

### 1b. 需求澄清完成确认（阻塞点）

创建 OpenSpec artifacts 前，必须按 `comet/reference/decision-point.md` 的协议暂停并等待用户确认需求澄清完成。

暂停时必须展示澄清摘要：目标、非目标、范围边界、关键未知项、验收场景草案。

不得在用户确认需求澄清完成前创建 proposal.md、design.md 或 tasks.md，也不得使用 Skill 工具加载 `openspec-propose` 技能一次性生成全部 artifacts。

### 1c. Change 名称确认（阻塞点）

创建 change 目录（`openspec new change`）前，必须按 `comet/reference/decision-point.md` 的协议暂停，让用户决定 change 名称。不得自动生成或静默推断 change 名称。

OpenSpec change 名称必须是 **kebab-case 英文**（小写字母、数字、连字符；如 `refine-requirements-doc`）。中文或其他不合规名称无效。

暂停时必须展示：
- 基于已确认澄清摘要派生的 **2-3 个推荐 kebab-case 英文名**，每个附一行说明其隐含范围
- 一个让用户 **自行输入名称** 的明确选项
- 提示：**若用户输入中文（或任何非 kebab-case 文本），会被转换为合规的 kebab-case 英文名**，转换结果必须回显给用户确认后才能使用

决策选项必须包含：
- 选择某个推荐名称
- 「自行输入名称」——接收用户输入；若已是合规 kebab-case 英文则直接使用；若为中文或其他不合规形式，则转换为合规 kebab-case 英文并回显转换后的名称，确认后再继续

不得在用户确认最终 change 名称前运行 `openspec new change` 或创建 `.comet.yaml`。若选定/转换后的名称与已有 change 冲突，必须报告冲突并请用户另选名称。

### 2. 创建 Change 结构 + 初始化状态

**立即执行：** 使用 Skill 工具加载 `openspec-new-change` 技能。禁止跳过此步骤。

完整 `/comet` 流程默认不得使用 Skill 工具加载 `openspec-propose` 技能；只有用户明确要求一次性生成提案和 artifacts 时才允许加载。

技能加载后，按其指引创建 change 骨架，但当 Step 1b 的已确认澄清摘要已存在于对话上下文时，覆盖其"STOP and wait for user direction"行为。

如果用户已确认澄清摘要（Step 1b），直接使用该摘要填充产物内容。如果不存在澄清摘要（边缘情况），回退到技能的默认行为，询问用户。

change 骨架创建后，按以下标准产物循环逐个生成 `proposal`、`design`、`tasks`：

**标准产物循环**（对每个 `artifact-id`：`proposal` → `design` → `tasks`）：

1. 刷新状态：`openspec status --change "<name>" --json`
2. 获取产物指令：

   ```bash
   openspec instructions proposal --change "<name>" --json
   openspec instructions design --change "<name>" --json
   openspec instructions tasks --change "<name>" --json
   ```

3. 对返回的 JSON 指令载荷，必须：
   - 读取 `dependencies` 中列出的每个已完成依赖产物
   - 以 `template` 作为产物结构
   - 遵循 `instruction` 的指引
   - 将 `context` 和 `rules` 作为约束条件应用，**不得复制到 artifact 内容中**
   - 写入 `resolvedOutputPath`
   - 验证输出文件存在且非空
4. 每创建一个 artifact 后，重新运行 `openspec status --change "<name>" --json` 确认状态，然后继续下一个 artifact

**失败处理**：如果 `openspec instructions` 失败、返回无效 JSON、报告未满足的 `dependencies`、或未提供可用的 `resolvedOutputPath`，必须立即停止 artifact 创建并报告 OpenSpec 错误。不得回退为硬编码文档结构，因为那样会绕过项目规则。

**命名与范围守卫**：change name 必须使用 Step 1c 中用户确认的 kebab-case 英文名，不得自动生成、推断或使用非 kebab-case（如中文）名称。变更范围必须与用户描述一致，不得自行扩大或缩小。

确认以下产物已创建：

```
openspec/changes/<name>/
├── .openspec.yaml
├── .comet.yaml
├── proposal.md       # Why + What：问题、目标、范围
├── design.md         # How（高层）：架构决策、方案选型
└── tasks.md          # 任务清单（勾选框）
```

创建 `.comet.yaml` 状态文件：

```bash
COMET_ENV="${COMET_ENV:-$(find . "$HOME"/.*/skills "$HOME/.config" "$HOME/.gemini" -path '*/comet/scripts/comet-env.sh' -type f -print -quit 2>/dev/null)}"
if [ -z "$COMET_ENV" ]; then
  echo "ERROR: comet-env.sh not found. Ensure the comet skill is installed." >&2
  return 1
fi
. "$COMET_ENV"

if [ -z "$COMET_STATE" ] || [ -z "$COMET_GUARD" ]; then
  echo "ERROR: Comet scripts not found. Ensure the comet skill is installed." >&2
  return 1
fi

"$COMET_BASH" "$COMET_STATE" init <name> full
```

### 3. 入口状态验证

验证状态机已正确初始化：

```bash
"$COMET_BASH" "$COMET_STATE" check <name> open
```

验证通过后继续 Step 4。验证失败时脚本会输出具体失败原因。

**幂等性**：open 阶段所有操作可安全重复执行。如 `.comet.yaml` 已处于 `phase: open` 且三个产物文件均已存在，跳过已完成步骤，从第一个缺失步骤继续。

### 4. 内容完整性检查

确认三个文档内容完整：
- **proposal.md**：问题背景、目标、范围、非目标
- **design.md**：高层架构决策、方案选型、数据流
- **tasks.md**：任务列表，每个任务有明确描述

**文件存在性验证**：逐个确认三个文件路径存在且非空。任一文件缺失或为空时，不得进入 Step 5 或执行阶段守卫，必须回到创建步骤补充。

### 5. 用户审视确认（阻塞点）

三个文档创建完成且内容完整性检查通过后，**必须按 `comet/reference/decision-point.md` 的协议暂停并等待用户确认**。不得在用户确认前执行阶段守卫或自动流转。

用户确认问题必须以单选题形式呈现，包含以下摘要和选项：

**摘要内容**：
- **proposal.md**：问题背景、目标、范围
- **design.md**：高层架构决策、方案选型
- **tasks.md**：任务数量和关键任务描述

**选项**：
- 「确认，继续下一阶段」— 产物符合预期，执行阶段守卫流转
- 「需要调整」— 附带调整说明，修改后重新请求确认

用户选择「确认」后继续执行退出条件。用户选择「需要调整」时，按其说明修改对应文件，然后重新请求确认。

## 退出条件

- proposal.md、design.md、tasks.md 均已创建且内容完整
- **用户已确认** proposal、design、tasks 内容符合预期
- **阶段守卫**：运行 `"$COMET_BASH" "$COMET_GUARD" <change-name> open --apply`，全部 PASS 后由守卫推进到下一阶段（此步骤更新 `phase` 字段，与 `auto_transition` 无关）

退出前必须使用 `--apply`，否则 `.comet.yaml` 仍停留在 `phase: open`，下一阶段入口检查会失败。

```bash
"$COMET_BASH" "$COMET_GUARD" <change-name> open --apply
```

完整流程会自动更新为 `phase: design`；hotfix/tweak preset 会自动更新为 `phase: build`。

## 自动衔接下一阶段

按 `comet/reference/auto-transition.md` 执行。关键命令：

```bash
"$COMET_BASH" "$COMET_STATE" next <change-name>
```

- `NEXT: auto` → 调用 `SKILL` 指向的 skill 进入下一阶段
- `NEXT: manual` → 不要调用下一 skill，按 `HINT` 提示用户手动运行 `/<SKILL>`
- `NEXT: done` → 流程已完成，无需继续

hotfix/tweak preset 由对应 preset skill 控制后续流转（phase 直接进入 build），其 `next` 会返回对应 preset skill。
__COMET_ASSETS_SKILLS_ZH_COMET_OPEN_SKILL_MD__

cat > "$TARGET_DIR/assets/skills-zh/comet-tweak/SKILL.md" <<'__COMET_ASSETS_SKILLS_ZH_COMET_TWEAK_SKILL_MD__'
---
name: comet-tweak
description: "Comet 预设路径：非 bug 的小改动（tweak）。跳过 brainstorming 和完整 plan，直接 open → lightweight build → light verify → archive。适用于文案、配置、文档或 prompt 的局部优化。"
---

# Comet 预设路径：Tweak

Tweak 是 Comet 五阶段能力的预设工作流，不是独立的平行流程。它复用 open、build、verify、archive 能力，仅跳过 brainstorming 和完整 plan。

适用于非 bug 的小范围变更，例如文案调整、配置调整、文档或 prompt 的局部优化。

**适用条件**（必须全部满足）：
1. 不新增 capability
2. 不改变架构
3. 不涉及接口变化
4. 通常不超过 3 个 tasks（文件数约束见下方升级条件）

**不适用**：如变更过程中发现需要 capability、架构或接口调整，应升级为完整 `/comet` 流程。

---

## 流程（preset workflow，4 阶段）

### 0. 输出语言约束

精简版 OpenSpec 产物必须使用触发本次工作流的用户请求语言。

执行链路：open → lightweight build → light verify → archive。Tweak 为每个阶段提供默认决策：精简开启、轻量构建、轻量验证、验证通过后进入归档前最终确认。

开始前先定位 Comet 脚本：

```bash
COMET_ENV="${COMET_ENV:-$(find . "$HOME"/.*/skills "$HOME/.config" "$HOME/.gemini" -path '*/comet/scripts/comet-env.sh' -type f -print -quit 2>/dev/null)}"
if [ -z "$COMET_ENV" ]; then
  echo "ERROR: comet-env.sh not found. Ensure the comet skill is installed." >&2
  return 1
fi
. "$COMET_ENV"
```

### 1. 快速开启（preset open）

复用 Comet open 能力创建 change，但使用 tweak 默认值：不执行 `openspec-explore` 长探索，直接进入精简 change 创建。

**立即执行：** 使用 Skill 工具加载 `openspec-new-change` 技能。禁止跳过此步骤。

技能加载后，按其指引创建精简版产物：
  - `proposal.md` — 变更动机 + 目标 + 范围
  - `design.md` — 简短实现说明（无需方案对比）
  - `tasks.md` — 不超过 3 个任务
- **无需 delta spec**（除非变更改变了已有 spec 的验收场景；一旦需要 delta spec，升级为完整 `/comet`）

初始化 Comet 状态文件：

```bash
"$COMET_BASH" "$COMET_STATE" init <name> tweak
```

初始化后验证状态：

```bash
"$COMET_BASH" "$COMET_STATE" check <name> open
```

阶段守卫完成 open → build 过渡：

```bash
"$COMET_BASH" "$COMET_GUARD" <change-name> open --apply
```

### 2. 轻量构建（preset build）

使用 tweak 默认值：`build_mode: direct`。跳过 Superpowers `brainstorming` 和 `writing-plans`。

继续或开始修改前，按 `comet/reference/dirty-worktree.md` 协议处理未提交改动。若归因后发现范围超出 tweak，按本文件“升级条件”处理。

**立即执行：** 按 tasks.md 逐个执行任务：

1. 读取 `openspec/changes/<name>/tasks.md`，获取未完成任务列表
2. 对每个未完成任务：
   - 根据任务描述修改目标文件
   - 运行项目格式化命令（如 `mvn spotless:apply`、`npm run format` 等）
   - 运行相关测试确认通过
   - 将 tasks.md 中对应 `- [ ]` 勾选为 `- [x]`
   - 提交代码，commit message 格式：`tweak: <简述变更>`
3. 全部任务完成后，显式运行项目相关测试和构建命令
4. 运行阶段守卫完成 build → verify 过渡：

执行 tweak 期间，只要运行程序、测试、构建或手动验证时出现崩溃、异常行为、测试失败或构建失败，必须使用 Skill 工具加载 Superpowers `systematic-debugging` 技能。在完成根因调查前，不得提出或实施源码修复。

具体调查、最小失败测试、修复验证和保持当前 change 验证闭环的要求，按 `comet/reference/debug-gate.md` 执行。

```bash
"$COMET_BASH" "$COMET_GUARD" <change-name> build --apply
```

状态文件自动更新为 `phase: verify`、`verify_result: pending`，然后进入验证。

### 3. 轻量验证（preset verify）

复用 `/comet-verify`。Tweak 必须保持轻量验证条件：≤ 3 tasks、≤ 4 files、无 delta spec、无新 capability。

**立即执行：** 使用 Skill 工具加载 `comet-verify` 技能。禁止跳过此步骤。

如规模评估进入完整验证路径，停止 tweak，按升级条件阻塞确认处理。

验证通过后，按 `/comet-verify` 的规则将 `.comet.yaml` 的 `verify_result` 记录为 `pass`，归档前不得跳过该状态。验证通过后仍必须进入 `/comet-archive` 的归档前最终确认，不得自动运行归档脚本。

### 4. 归档（preset archive）

复用 `/comet-archive`。归档前必须满足 `.comet.yaml` 中 `verify_result: pass`，并等待 `/comet-archive` 的归档前最终确认。

**立即执行：** 使用 Skill 工具加载 `comet-archive` 技能进行归档。禁止跳过此步骤。

---

## 连续执行模式

<IMPORTANT>
Tweak 流程默认 **一次性连续执行**。调用 `/comet-tweak` 后，agent 在 tweak 自有步骤间自动推进，不主动停顿。**例外**：若 `auto_transition: false`，则在每个 phase 边界（build/verify/archive 之间）停下，由用户手动运行下一阶段命令——此时连续执行降级为逐阶段手动推进，详见下方「自动衔接下一阶段」。但无论 `auto_transition` 取何值，以下情况都必须暂停等待用户确认：

1. 遇到升级条件（见"升级条件"章节），**必须使用当前平台可用的用户输入/确认机制暂停并等待用户明确确认**升级为完整流程
2. 验证阶段（comet-verify）的验证失败决策和分支处理决策
3. 归档前最终确认（comet-archive 执行归档脚本前）

执行顺序：快速开启 → 轻量构建 → 轻量验证 → 归档 → 完成

每个阶段完成后立即进入下一阶段。阶段内部仍必须按上文要求调用对应 Comet/OpenSpec/Superpowers skill，被调用的 skill 如有自己的用户决策点，按该 skill 规则执行。
</IMPORTANT>

---

## 升级条件

满足以下**任一**条件时，停止 tweak 流程，升级为完整 `/comet`：

| 条件 | 说明 |
|------|------|
| 改动涉及 **5+ 文件** | 超出小改动范围 |
| 多模块协调修改 | 需要跨组件协调 |
| 需要新增测试用例 **5+** | 变更复杂度上升 |
| 配置项新增或删除 | 非值修改的配置变更 |
| 需要新增 capability | 超出局部优化 |
| 需要 delta spec | 影响了已有规格 |

满足升级条件时**必须按 `comet/reference/decision-point.md` 的协议暂停并等待用户明确确认**升级为完整 `/comet` 流程。不得直接进入 `/comet-design`，不得自动补充 Design Doc。

用户确认升级后，**必须先更新 workflow 和 phase 字段**再进入完整流程：

```bash
"$COMET_BASH" "$COMET_STATE" set <name> workflow full
"$COMET_BASH" "$COMET_STATE" set <name> phase design
```

然后在当前 change 基础上补充 Design Doc：**立即使用 Skill 工具加载 `comet-design` skill**，后续正常走完整流程。若用户不确认升级，停止 tweak 并报告当前变更已超出 tweak 适用范围。

---

## 退出条件

- 小改动已完成，测试通过
- change 已归档
- 未新增 capability、架构调整或接口变化
- **阶段守卫**：build → verify 前运行 `"$COMET_BASH" "$COMET_GUARD" <change-name> build --apply`，verify → archive 前按 `/comet-verify` 规则运行 `"$COMET_BASH" "$COMET_GUARD" <change-name> verify --apply`

## 自动衔接下一阶段

按 `comet/reference/auto-transition.md` 执行。关键命令：

```bash
"$COMET_BASH" "$COMET_STATE" next <name>
```

- `NEXT: auto` → 调用 `SKILL` 指向的 skill 继续 tweak 流程（`phase: build` 返回 `comet-tweak`，`verify` 返回 `comet-verify`，`archive` 返回 `comet-archive`）
- `NEXT: manual` → 不要调用下一 skill，按 `HINT` 提示用户手动运行 `/<SKILL>`
- `NEXT: done` → 流程已完成，无需继续
__COMET_ASSETS_SKILLS_ZH_COMET_TWEAK_SKILL_MD__

cat > "$TARGET_DIR/assets/skills-zh/comet-verify/SKILL.md" <<'__COMET_ASSETS_SKILLS_ZH_COMET_VERIFY_SKILL_MD__'
---
name: comet-verify
description: "Comet 阶段 4：验证与收尾。用 /comet-verify 调用。验证实现符合设计，处理开发分支。"
---

# Comet 阶段 4：验证与收尾（Verify）

## 前置条件

- 代码已提交（阶段 3 完成）
- tasks.md 全部任务已完成

## 步骤

### 0a. 输出语言约束

验证报告和分支处理说明必须使用触发本次工作流的用户请求语言。

### 0b. 入口状态验证（Entry Check）

执行入口验证：

```bash
COMET_ENV="${COMET_ENV:-$(find . "$HOME"/.*/skills "$HOME/.config" "$HOME/.gemini" -path '*/comet/scripts/comet-env.sh' -type f -print -quit 2>/dev/null)}"
if [ -z "$COMET_ENV" ]; then
  echo "ERROR: comet-env.sh not found. Ensure the comet skill is installed." >&2
  return 1
fi
. "$COMET_ENV"
"$COMET_BASH" "$COMET_STATE" check <change-name> verify
```

验证通过后继续 Step 1。验证失败时脚本会输出具体失败原因。

**幂等性**：verify 阶段所有检查可安全重复执行。如 `verify_result` 已为 `pass` 且 `branch_status` 已为 `handled`，说明验证已完成，直接执行 guard 流转。如 `verify_result` 为 `pending`，从头开始验证。

### 1. 改动规模评估

执行规模评估：

```bash
"$COMET_BASH" "$COMET_STATE" scale <change-name>
```

脚本自动统计任务数、增量规格数、变更文件数，判断使用 light 或 full 验证模式，并设置 verify_mode 字段。判定规则（满足任一即 full）：任务数 > 3、delta spec 能力数 > 1、变更文件数 > 4。

验证开始前，按 `comet/reference/dirty-worktree.md` 协议检查并处理未提交改动。verify 阶段的特殊处理：

1. 若 dirty diff 属于当前 change 且涉及实现、测试、tasks、delta spec 或 design doc 变更，不在 verify 阶段直接修复或提交；报告失败项并进入 Step 1b 的验证失败决策阻塞点
2. 若 dirty diff 只是 verify 本阶段产物（例如验证报告草稿、分支处理记录），可继续在 verify 阶段完成并记录状态
3. 若 dirty diff 已实现但 tasks.md 未勾选，视为 build 状态滞后；报告失败项并进入 Step 1b，由用户决定回退修复或接受偏差

用户选择修复后，才允许回退到 build 阶段：

```bash
# 仅在用户确认修复后执行
"$COMET_BASH" "$COMET_STATE" transition <change-name> verify-fail
```

注意：verify-fail 回退到 build 时 `branch_status` 不会被重置。如果首次 verify 已完成分支处理，修复后再次进入 verify 时跳过已完成的分支处理步骤，直接使用 `"$COMET_BASH" "$COMET_STATE" set <change-name> branch_status handled` 保留原有分支处理结果。

注意：如果 build 阶段每个任务都已提交，脚本基于工作区 diff 的文件数可能低估改动规模。此时必须读取 plan 文件头的 `base-ref` 并用提交区间复核：

```bash
PLAN=$("$COMET_BASH" "$COMET_STATE" get <change-name> plan)
BASE_REF=$(grep '^base-ref:' "$PLAN" 2>/dev/null | head -1 | sed 's/^base-ref: *//')
git diff --stat "$BASE_REF"...HEAD
```

若提交区间显示改动超过轻量阈值（> 4 个文件、跨模块协调、或 delta spec 超过 1 个 capability），手动设置为完整验证：

```bash
"$COMET_BASH" "$COMET_STATE" set <change-name> verify_mode full
```

**覆盖机制**：如 agent 或用户认为自动评估结果不合适，可随时通过 `"$COMET_BASH" "$COMET_STATE" set <change-name> verify_mode <light|full>` 手动覆盖。

### 1b. 验证失败决策（阻塞点）

验证不通过时**必须按 `comet/reference/decision-point.md` 的协议暂停并等待用户决定修复或接受偏差**。不得自动运行 `"$COMET_BASH" "$COMET_STATE" transition <change-name> verify-fail`，也不得自动调用 `/comet-build`。

暂停时必须列出：
- 失败项
- 是否属于 CRITICAL 或 IMPORTANT（构建失败、测试失败、安全问题、核心验收场景失败、简化代码审查发现的正确性/安全/边界问题）
- 推荐处理方式

**不确定性原则**：无法确定严重程度时，降级处理（SUGGESTION > WARNING > CRITICAL）。仅对构建失败、测试失败、安全问题使用 CRITICAL；模糊或不确定的问题标为 WARNING 或 SUGGESTION。

用户选择后按以下方式继续：
- **全部修复**：运行 `"$COMET_BASH" "$COMET_STATE" transition <change-name> verify-fail`，然后调用 `/comet-build` 修复
- **逐项处理**：CRITICAL 或 IMPORTANT 失败项必须修复；WARNING/SUGGESTION 失败项可选择接受偏差，但必须在验证报告中记录接受原因和影响范围。若存在任何 CRITICAL 或 IMPORTANT 失败项，不允许跳过修复直接全部接受

### 2. 产物上下文加载（Hash 按需读）

验证需要读取 OpenSpec 产物时，先检查产物是否自 design 阶段以来发生变化：

```bash
RECORDED_HASH=$("$COMET_BASH" "$COMET_STATE" get <change-name> handoff_hash)
CURRENT_HASH=$("$COMET_BASH" "$COMET_HANDOFF" <change-name> --hash-only 2>/dev/null || echo "")
```

- 若 `RECORDED_HASH` = `CURRENT_HASH` 且均非空且均非 `null`：OpenSpec 产物未变化，**tasks.md 无需重新读取全文**（用 `grep -c '\- \[ \]' tasks.md` 确认完成数即可）。proposal.md、design.md、delta spec 仍需读取用于对照检查。
- 若 `RECORDED_HASH` 为空、为 `null`、或与 `CURRENT_HASH` 不一致：产物已变化或 hash 未记录，正常读取所有所需文件全文。

此优化仅跳过 tasks.md 的重复全文读取。proposal.md 和 design.md 包含验证检查项所需的完整上下文，不得因 hash 匹配而跳过。

**立即执行：** 使用 Skill 工具加载 Superpowers `verification-before-completion` 技能。禁止跳过此步骤。

技能加载后，按 verify_mode 分支执行：

### 2a. 轻量验证（小改动）

按以下 6 项进行检查：

1. tasks.md 全部任务已完成 `[x]`
2. 改动文件与 tasks.md 描述一致（`git diff --stat` / `git diff --cached --stat` / `git diff --stat <base-ref>...HEAD` 对照 tasks 内容）
3. 编译通过（执行项目对应的构建命令，如 `npm run build`、`mvn compile`、`cargo build` 等）
4. 相关测试通过
5. 无明显安全问题（无硬编码密钥、无新增 unsafe 操作）
6. 代码审查策略：当 `review_mode: standard` 或 `thorough` 时，必须使用 Skill 工具加载 Superpowers `requesting-code-review` 技能，请求只检查正确性、安全、边界条件的轻量代码审查；当 `review_mode: off` 时跳过自动代码审查，并在验证报告中记录跳过原因

简化代码审查的输入应限定为本次改动 diff、tasks.md 和必要的测试结果；审查范围只覆盖实现正确性、安全风险和边界条件，不执行 spec 覆盖率、Design Doc 一致性或漂移检查。若审查发现 CRITICAL 或 IMPORTANT 问题，按验证失败处理并进入 Step 1b。`review_mode: off` 只跳过自动 code review，不跳过构建、测试、安全检查或异常调试协议。

**通过标准**：6 项全部 OK，无 CRITICAL 或 IMPORTANT 问题。

**不通过时**：报告失败项，进入 Step 1b 的验证失败决策阻塞点。用户选择修复后，才执行以下命令记录失败并回退到 build 阶段，然后调用 `/comet-build` 修复：

```bash
# 仅在用户确认修复后执行
"$COMET_BASH" "$COMET_STATE" transition <change-name> verify-fail
```

**报告格式**：简表列出 6 项检查结果 + PASS/FAIL。

**跳过项**（不在轻量验证中检查）：
- spec scenario 覆盖率
- design doc 一致性深度比对
- 不影响正确性、安全、边界条件的 code pattern consistency 建议
- delta spec 与 design doc 漂移检测

### 2b. 完整验证（大改动）

当规模评估结果为"大"时：

**立即执行：** 使用 Skill 工具加载 `openspec-verify-change` 技能。禁止跳过此步骤。

技能加载后，按其指引验证。检查项：
1. tasks.md 全部任务已完成（`[x]`）
2. 实现符合 `openspec/changes/<name>/design.md` 高层设计决策
3. 实现符合 Design Doc（`docs/superpowers/specs/` 下的技术设计文档）
4. 能力规格场景全部通过
5. proposal.md 目标已满足
6. delta spec 与 design doc 无矛盾（若 Build 阶段有增量修改 spec，检查 design doc 是否有对应记录）
7. `docs/superpowers/specs/` 关联的设计文档可定位（文件存在且与当前 change 相关）

验证不通过时：报告缺失项，进入 Step 1b 的验证失败决策阻塞点。用户选择修复后，才执行以下命令记录失败并回退到 build 阶段，然后调用 `/comet-build` 补充：

```bash
# 仅在用户确认修复后执行
"$COMET_BASH" "$COMET_STATE" transition <change-name> verify-fail
```

**Spec 漂移处理**（用户决策点）：
- 若检查项 6 发现矛盾（delta spec 有内容但 design doc 未体现），**必须使用当前平台可用的用户输入/确认机制以单选题形式暂停并等待用户选择处理方式**，不得自动选择。选项：
  - 选项 A：在 design doc 追加 "Implementation Divergence" 节记录偏差原因。选项 A 属于 verify 阶段允许产物；写入后不得因该 design doc 变更再次触发 Step 1b dirty-worktree 决策
  - 选项 B：用户选择 B 后，运行 `"$COMET_BASH" "$COMET_STATE" transition <change-name> verify-fail`，然后调用 `/comet-build`；由 `/comet-build` 的 Spec 增量更新规则加载 Superpowers `brainstorming` 更新 Design Doc + delta spec
  - 选项 C：确认偏差可接受，继续验证（归档时 design doc 将标记为 `superseded-by-main-spec`）

### 3. 收尾（Superpowers）

**立即执行：** 使用 Skill 工具加载 Superpowers `finishing-a-development-branch` 技能。禁止跳过此步骤。

如 Superpowers `finishing-a-development-branch` 技能不可用，停止流程并提示安装或启用 Superpowers 技能，不要用普通对话替代该步骤。

技能加载后，按其指引收尾。分支处理选项：
1. 本地合并到主分支
2. 推送并创建 PR
3. 保持分支（稍后处理）
4. 丢弃工作

这是用户决策点。**必须按 `comet/reference/decision-point.md` 的协议暂停并等待用户选择分支处理方式**，不得根据推荐、默认值或当前分支状态自行选择。只有在用户完成选择且对应操作完成后，才允许写入 `branch_status: handled`。

**确认项**：
- 全部测试通过
- 无硬编码密钥或安全问题

### 4. 记录验证证据

验证报告必须落盘，并在 `.comet.yaml` 中记录；分支处理完成后也必须写入状态字段。不要手动设置 `verify_result: pass`，由阶段守卫 `--apply` 推进。

```bash
mkdir -p docs/superpowers/reports
# 将本次验证结论写入报告文件，例如：
# docs/superpowers/reports/YYYY-MM-DD-<change-name>-verify.md

"$COMET_BASH" "$COMET_STATE" set <change-name> verification_report docs/superpowers/reports/YYYY-MM-DD-<change-name>-verify.md
"$COMET_BASH" "$COMET_STATE" set <change-name> branch_status handled
```

## 退出条件

- 验证报告通过
- 分支已处理
- `.comet.yaml` 中 `verification_report` 指向已存在的验证报告文件
- `.comet.yaml` 中 `branch_status: handled`
- **阶段守卫**：运行 `"$COMET_BASH" "$COMET_GUARD" <change-name> verify --apply`，全部 PASS 后由守卫通过 `comet-state transition verify-pass` 推进到 `phase: archive`（此步骤更新 `phase` 字段，与 `auto_transition` 无关）

验证和分支处理均完成后，运行阶段守卫推进 phase（此步骤与 `auto_transition` 无关）：

```bash
"$COMET_BASH" "$COMET_GUARD" <change-name> verify --apply
```

状态文件自动更新为 `phase: archive`、`verify_result: pass`、`verified_at: YYYY-MM-DD`。

## 上下文压缩恢复

按 `comet/reference/context-recovery.md` 执行，phase 参数为 `verify`。

## 自动衔接下一阶段

按 `comet/reference/auto-transition.md` 执行。关键命令：

```bash
"$COMET_BASH" "$COMET_STATE" next <change-name>
```

- `NEXT: auto` → 调用 `SKILL` 指向的 skill 进入下一阶段
- `NEXT: manual` → 不要调用下一 skill，按 `HINT` 提示用户手动运行 `/<SKILL>`
- `NEXT: done` → 流程已完成，无需继续

注意：无论 `NEXT` 为 `auto` 还是 `manual`，`comet-archive` 进入后必须先执行归档前最终确认阻塞点，等待用户明确选择「确认归档」后才允许运行归档脚本。不得因为验证已通过就自动归档。
__COMET_ASSETS_SKILLS_ZH_COMET_VERIFY_SKILL_MD__

cat > "$TARGET_DIR/assets/skills-zh/comet/SKILL.md" <<'__COMET_ASSETS_SKILLS_ZH_COMET_SKILL_MD__'
---
name: comet
description: "Comet — OpenSpec + Superpowers 双星开发流程。用 /comet 启动，自动检测阶段并分发到子命令。五阶段：开启 → 深度设计 → 计划与构建 → 验证与收尾 → 归档。"
---

# Comet — OpenSpec + Superpowers 双星开发流程

OpenSpec 与 Superpowers 如双星系统围绕同一目标运转。

```
OpenSpec 负责 WHAT  — 大纲、提案、spec 生命周期、归档
Superpowers 负责 HOW — 技术设计、计划、执行、收尾
```

**核心原则：brainstorming 必不可跳过。每次变更都必须经过深度设计（hotfix 和 tweak preset 除外）。**

---

## 决策核心（Decision Core）

agent 做决策只需读本节，参考附录按需查阅。

### 输出语言规则

以触发本次工作流的用户请求语言作为默认输出语言。恢复已有 change 时，如果现有产物有明确主语言，除非用户明确要求切换，否则保持该语言。

### 阶段自动检测

**Step 0: 活跃 Change 发现与意图判定**

1. 先做 Preset 检测；命中 hotfix/tweak 时直接调用对应 preset skill，不进入普通 open 分支
2. 未命中 preset 时，运行 `openspec list --json` 获取所有活跃 change

**Preset 检测优先级最高**：
- 用户明确描述为 bug fix / 热修复 + 满足 hotfix 条件 → 直接 `/comet-hotfix`
- 用户明确描述为文案/配置/文档/prompt 小调整 + 满足 tweak 条件 → 直接 `/comet-tweak`
- 未命中 preset → 按下表处理

| 活跃 change | 用户输入 | 行为 |
|-------------|---------|------|
| 无 | 非 preset 输入 | → 调用 `/comet-open` |
| 恰好 1 个 | `/comet <描述>` | → **询问**：继续该变更 or 创建新变更 |
| 多个 | `/comet <描述>` | → **询问**：继续现有变更 or 创建新变更；若选继续 → 列出清单让用户选择 |
| 恰好 1 个 | `/comet`（无描述） | → 自动选中，进入 Step 1 |
| 多个 | `/comet`（无描述） | → 列出清单让用户选择 |

<IMPORTANT>
当用户选择「创建新变更」时，**必须调用 `/comet-open`**（禁止直接调用 `/opsx:new`）。
`/comet-open` 负责完整双初始化：OpenSpec artifacts（由内部 `/opsx:new` 创建）+ `.comet.yaml` 状态文件。
直接调用 `/opsx:new` 会缺失 `.comet.yaml`，导致后续阶段判定失败。
</IMPORTANT>

**Step 1: 读取 `.comet.yaml` 状态元数据**

优先读取 `openspec/changes/<name>/.comet.yaml`。不存在时回退到 `openspec status --change "<name>" --json`、`tasks.md` 和 `docs/superpowers/` 文件检查。

**断点恢复规则**：
- 每次恢复上下文时，先重新执行 Step 0 和 Step 1，不依赖对话历史判断阶段
- 只要存在 active change 且工作区有未提交改动，必须按 `comet/reference/dirty-worktree.md` 协议处理。该协议定义了检查步骤、归因分类和禁令，本文件不重复
- 若 `phase: build`，先检查 `build_pause`、`plan`、`build_mode` 和 `isolation`（详见下方）：
  - 若 `build_pause: plan-ready` 但 `isolation` 和 `build_mode` 已经设置，则视为 stale pause：先输出 `[COMET] 检测到 stale pause（build_pause=plan-ready 但 isolation/build_mode 已设置），自动清除并继续`，再运行 `"$COMET_BASH" "$COMET_STATE" set <name> build_pause null`，然后读取 tasks.md 的下一个未勾选任务并按 `build_mode` 恢复执行
  - 若 `build_pause: plan-ready` 且 plan 文件存在，但 `isolation` 或 `build_mode` 尚未设置，回到 `/comet-build` 的 plan-ready 恢复点，提示用户继续选择隔离方式和执行方式，不重新生成 plan
  - 若 `build_pause: plan-ready` 但 plan 文件缺失，回到 `/comet-build` 处理状态损坏或重新生成 plan
  - 若 `build_mode`、`isolation` 或 `tdd_mode` 未设置，回到 `/comet-build` 对应步骤补充后再执行
  - 若均已设置，读取 tasks.md 的下一个未勾选任务，并按 `build_mode` 恢复执行：
    - 若 `build_mode: subagent-driven-development`，不得在主窗口直接执行任务；必须回到 `/comet-build` 的后台 subagent 调度规则，由主窗口只做协调
    - 其他执行方式按 `/comet-build` 的对应规则继续
- 若 `phase: verify` 且 `verify_result: fail`，进入验证失败决策阻塞点：暂停并询问用户修复或接受偏差；用户选择修复后才运行 `"$COMET_BASH" "$COMET_STATE" transition <name> verify-fail` 并调用 `/comet-build`
- 若 `phase: open` 但 proposal/design/tasks 已完整，先运行 `"$COMET_BASH" "$COMET_GUARD" <change-name> open --apply` 修正状态，再继续判定
- 若 `phase: archive`，只允许调用 `/comet-archive`；`/comet-archive` 必须先等待归档前最终确认，归档成功后 change 会移动到 archive 目录，不再对原活跃目录运行 guard

**Step 2: 阶段判定**（按顺序，命中即停）

1. `archived: true` 或 change 已移入 archive → 流程已完成
2. `verify_result: pass` 且 `archived` 不是 `true` → `/comet-archive`（先进行归档前最终确认）
3. `verify_result: fail` → 进入验证失败决策阻塞点（暂停询问修复或接受偏差；用户选择修复后才 `verify-fail` 并 `/comet-build`）
4. `phase: verify` 或 tasks.md 全部勾选 → `/comet-verify`
5. `phase: build` 或已有 Design Doc 但计划/执行未完成 → 优先按 workflow 路由：`hotfix` → `/comet-hotfix`，`tweak` → `/comet-tweak`，`full` → `/comet-build`
6. `phase: design` 或有 change 但无 Design Doc → `/comet-design`
7. `phase: open` 或有活跃 change 但 `.comet.yaml` 缺失 → `/comet-open`
8. 无活跃 change → `/comet-open`

如果元数据与文件状态冲突，以文件状态为准，修正 `.comet.yaml` 后继续。

### 预设升级条件

**hotfix → full**（满足任一即升级）：
- 改动涉及 **3+ 文件**
- 涉及架构变更（新模块、新接口、新依赖）
- 涉及数据库 schema 变更
- 修复引入新的 public API
- 修复范围超出单一函数/模块

**tweak → full**（满足任一即升级）：
- 改动涉及 **5+ 文件**
- 涉及多个模块的协调修改
- 需要新增测试用例 **5+**
- 涉及配置项的新增或删除（非值修改）
- 需要新增 capability
- 需要 delta spec（影响了已有规格）

### 错误处理速查

| 场景 | 处理方式 |
|------|---------|
| `openspec list --json` 失败 | 检查 openspec 是否已安装，提示 `openspec init` |
| 子 skill 不可用 | 停止流程，提示安装或启用对应 skill |
| `.comet.yaml` 格式异常或缺失 | 以文件状态为准，用 `"$COMET_BASH" "$COMET_STATE" set` 修正后继续 |
| 构建/测试失败 | 返回 build 阶段修复，不进入 verify |
| change 目录结构不完整 | 按 `comet-open` 产物要求补齐 |

### 阶段衔接

<IMPORTANT>
单次 `/comet` 调用从检测到的阶段开始，退出条件满足后进入下一阶段。

流转链：open → design → build → verify → archive

**连续执行要求**：从检测到的阶段开始，agent 自动推进后续阶段。但**自动推进仅适用于没有用户决策的衔接点**。遇到用户决策点时，**必须使用当前平台可用的用户输入/确认机制暂停并等待用户明确回复**，不得用推荐规则、默认值或历史偏好代替用户确认，也不得仅输出文字提示后继续执行。

**阶段推进与自动衔接的区分**：每个子 skill 退出前都会运行阶段守卫 `--apply` 推进 `.comet.yaml` 的 `phase` 字段——这一步**始终发生**，与 `auto_transition` 无关。之后子 skill 运行 `"$COMET_BASH" "$COMET_STATE" next <name>` 解析下一步：`auto_transition` 不为 `false` 时输出 `NEXT: auto`（自动调用下一 skill），为 `false` 时输出 `NEXT: manual`（不调用下一 skill，提示用户手动运行）。因此 `auto_transition` **只控制是否自动调用下一个 skill，不影响 phase 推进**。无论 `auto_transition` 取何值，下方的用户决策点都必须阻塞等待。

**决策点是阻塞点**：只要到达下列任一节点，当前 `/comet` 调用必须停住，并按 `comet/reference/decision-point.md` 的协议获取用户明确选择。用户明确选择后才能写入对应状态字段、执行对应操作，随后再继续自动流转。

需要用户参与的节点（仅在这些节点暂停）：
1. open 阶段 proposal/design/tasks 审视确认
2. brainstorming 确认设计方案
3. build 阶段 plan-ready 暂停选择，以及随后选择工作方式（隔离方式 + 执行方式）
4. verify 不通过时决定修复或接受偏差（含 Spec 漂移处理方式选择）
5. finishing-branch 选择分支处理方式
6. archive 阶段执行归档脚本前的最终确认
7. 遇到升级条件（hotfix/tweak → 完整流程）
8. build 阶段范围扩张需重新设计或拆分新 change
9. open 阶段大型 PRD 需确认拆分为多个 change

agent 不应跳过这些决策点；其他明确无歧义的阶段衔接必须自动继续推进，不得中途退出。到达决策点时，**禁止跳过用户确认或自动选择——必须通过当前平台可用的用户输入/确认机制明确获取用户选择后才能继续**。

**红旗清单** — 以下想法出现时立即停止并检查：

| Agent 心理 | 实际风险 |
|-----------|---------|
| "用户应该会同意这个方案" | 不能替用户决策，必须等待用户明确选择 |
| "这只是个小改动，不需要确认" | 决策点无大小之分，阻塞点必须等待 |
| "用户之前选过 A，这次也选 A" | 历史偏好不能替代当前确认 |
| "我已经解释了方案，用户没反对" | 没反对 ≠ 同意，必须用工具获取明确选择 |
| "流程走到这里应该没问题了" | 验证不通过 ≠ 通过，检查 verify_result |
</IMPORTANT>

---

## 子命令速查

| 命令 | 阶段 | 归属 | 产物 |
|------|------|------|------|
| `/comet-open` | 1. 开启 | OpenSpec | proposal.md、design.md、tasks.md |
| `/comet-design` | 2. 深度设计 | Superpowers | Design Doc、delta spec |
| `/comet-build` | 3. 计划与构建 | Superpowers | 实施计划、代码提交 |
| `/comet-verify` | 4. 验证与收尾 | Both | 验证报告、分支处理 |
| `/comet-archive` | 5. 归档 | OpenSpec | delta→main spec 同步、design doc 标注、归档 |
| `/comet-hotfix` | 预设路径 | Both | 快速修复（跳过 brainstorming） |
| `/comet-tweak` | 预设路径 | Both | 小改动（跳过 brainstorming 和完整 plan） |

```
/comet
  ↓ 自动检测
/comet-open ──→ /comet-design ──→ /comet-build ──→ /comet-verify ──→ /comet-archive
  (OpenSpec)      (Superpowers)     (Superpowers)     (Both)          (OpenSpec)

/comet-hotfix（预设路径，跳过 brainstorming）
  open ──→ build ──→ verify ──→ archive
    ↑ 如触发升级条件 → 阻塞确认升级 → 补充 Design Doc → 回到完整流程

/comet-tweak（预设路径，跳过 brainstorming 和完整 plan）
  open ──→ lightweight build ──→ light verify ──→ archive
    ↑ 如触发升级条件 → 阻塞确认升级 → 补充 Design Doc → 回到完整流程
```

---

## 参考附录（Reference Appendix）

> 字段说明、文件结构和自动衔接协议已提取为渐进式加载参考文档，按需查阅：
> - **`.comet.yaml` 完整字段表**：按 `comet/reference/comet-yaml-fields.md` 查阅（含必需字段、可选字段和完整示例）
> - **文件结构**：按 `comet/reference/file-structure.md` 查阅
> - **自动衔接协议**：按 `comet/reference/auto-transition.md` 查阅
> - **上下文压缩恢复**：按 `comet/reference/context-recovery.md` 查阅
> - **用户决策点协议**：按 `comet/reference/decision-point.md` 查阅
> - **异常调试协议**：按 `comet/reference/debug-gate.md` 查阅

### 状态机硬约束

- `build → verify` 前，`isolation` 必须是 `branch` 或 `worktree`
- `build → verify` 前，`build_mode` 必须已选择
- `build_mode: subagent-driven-development` 必须同时有 `subagent_dispatch: confirmed`
- full workflow 离开 build 阶段前 `tdd_mode` 必须已选择为 `tdd` 或 `direct`
- `build_mode: direct` 默认只允许 `hotfix` / `tweak`；full workflow 需要 `direct_override: true`
- `build_pause` 不是执行方式，不得写入 `build_mode`
- 这些约束同时存在于 `comet-guard.sh build --apply` 和 `comet-state.sh transition <name> build-complete`

### 脚本定位

Comet 脚本随 skill 包分发在 `comet/scripts/` 下。**不硬编码路径** — 定位一次，缓存到环境变量。此块为标准样板，在每个子 skill 中独立重复以确保可独立加载；修改时必须保持所有文件同步（样板版本: `v2`，变更时更新此版本号便于定位需要同步的文件）：

```bash
COMET_ENV="${COMET_ENV:-$(find . "$HOME"/.*/skills "$HOME/.config" "$HOME/.gemini" -path '*/comet/scripts/comet-env.sh' -type f -print -quit 2>/dev/null)}"
if [ -z "$COMET_ENV" ]; then
  echo "ERROR: comet-env.sh not found. Ensure the comet skill is installed." >&2
  return 1
fi
. "$COMET_ENV"

# 脚本定位失败时停止流程
if [ -z "$COMET_GUARD" ] || [ -z "$COMET_STATE" ] || [ -z "$COMET_HANDOFF" ] || [ -z "$COMET_ARCHIVE" ]; then
  echo "ERROR: Comet scripts not found. Ensure the comet skill is installed." >&2
  echo "Expected path pattern: */comet/scripts/comet-*.sh under project or platform skill directories" >&2
  return 1
fi
```

**自动状态更新**：guard 支持 `--apply` 参数，验证通过后自动更新 `.comet.yaml` 状态字段：

```bash
"$COMET_BASH" "$COMET_GUARD" <change-name> <phase> --apply
```

`--apply` 内部委托给 `comet-state transition`。需要直接表达状态事件时使用：

```bash
"$COMET_BASH" "$COMET_STATE" transition <change-name> open-complete
"$COMET_BASH" "$COMET_STATE" transition <change-name> design-complete
"$COMET_BASH" "$COMET_STATE" transition <change-name> build-complete
"$COMET_BASH" "$COMET_STATE" transition <change-name> verify-pass
"$COMET_BASH" "$COMET_STATE" transition <change-name> verify-fail
"$COMET_BASH" "$COMET_STATE" transition <archive-name> archived
```

**解析下一步**：阶段守卫推进 phase 后，用 `next` 子命令解析是否自动调用下一个 skill：

```bash
"$COMET_BASH" "$COMET_STATE" next <change-name>
```

输出 `NEXT: auto|manual|done` + `SKILL: <skill-name>`（`done` 时省略）+ `HINT`（仅 `manual` 时）。`auto_transition: false` 时输出 `manual`，只暂停下一 skill 调用，不影响已发生的 phase 推进。

**归档脚本**：一键完成归档全部步骤：

```bash
"$COMET_BASH" "$COMET_ARCHIVE" <change-name>
```

加载 comet 后，agent 应执行以上变量赋值一次，后续全程复用 `$COMET_GUARD`、`$COMET_STATE`、`$COMET_HANDOFF`、`$COMET_ARCHIVE`。

### 文件结构

按 `comet/reference/file-structure.md` 查阅完整目录结构。

### 最佳实践

1. **brainstorming 不可跳过** — 每次变更必须经过深度设计（hotfix 和 tweak 除外）
2. **delta spec 是活文档** — 阶段 3 期间可自由修改，归档时同步
3. **交接包由脚本生成** — OpenSpec → Superpowers 的上下文必须通过 `comet-handoff.sh` 生成 compact 可追溯摘录（需要全文时用 `--full`），并由 guard 校验 source/hash/mode
4. **保持 tasks.md 同步** — 完成一个勾一个
5. **频繁提交** — 每个任务一次提交，message 体现设计意图
6. **先验证再确认归档** — `/comet-verify` 通过后进入 `/comet-archive`，但运行归档脚本前必须等待用户最终确认
7. **增量更新分级** — 小编辑、中重 brainstorming、大新 change
8. **Plan 必须关联 change** — 文件头包含 `change:` 和 `design-doc:` 元数据
9. **归档闭环** — design doc 和 plan 必须标注 `archived-with` 状态
10. **修改已有功能** — 直接 open 新 change 即可
11. **Preset 有上限** — hotfix/tweak 满足升级条件时及时切换到完整流程
__COMET_ASSETS_SKILLS_ZH_COMET_SKILL_MD__

cat > "$TARGET_DIR/assets/skills-zh/comet/reference/auto-transition.md" <<'__COMET_ASSETS_SKILLS_ZH_COMET_REFERENCE_AUTO_TRANSITION_MD__'
# 自动衔接下一阶段协议

规范路径：`comet/reference/auto-transition.md`

本协议由所有 comet 子 skill 共享，定义阶段守卫推进后的自动衔接规则。

## 术语区分

「阶段守卫推进」由 guard `--apply` 完成，更新 `.comet.yaml` 的 `phase` 字段——这一步**始终发生**，与 `auto_transition` 无关。本协议的「自动衔接」只决定**是否自动调用下一个 skill**，由 `auto_transition` 控制。

## 执行方式

退出条件满足且阶段守卫推进 phase 后，运行：

```bash
"$COMET_BASH" "$COMET_STATE" next <change-name>
```

脚本根据 `phase`、`workflow`、`auto_transition` 输出确定性的下一步：

- `NEXT: auto` → 调用 `SKILL` 指向的 skill 进入下一阶段
- `NEXT: manual` → 不要调用下一 skill，按 `HINT` 提示用户手动运行 `/<SKILL>`
- `NEXT: done` → 流程已完成，无需继续

## preset 路由

`workflow: hotfix` 时，`phase: build` 返回 `comet-hotfix`；`workflow: tweak` 时返回 `comet-tweak`。其余 phase（`verify`、`archive`）按标准 skill 名称返回（`comet-verify`、`comet-archive`），不受 workflow 类型影响。

preset skill 内部的“连续执行模式”**不替代** `auto_transition`：

- `auto_transition: true` 时，preset 仍按 `NEXT: auto` 自动衔接下一 skill
- `auto_transition: false` 时，preset 仍按 `NEXT: manual` 在 phase 边界暂停
- preset 额外定义的只是自己的阻塞点和阶段内执行规则（如升级确认、验证失败决策、归档前确认），这些规则与 `auto_transition` 并行生效

详见对应 preset 的 `<IMPORTANT>` 块。
__COMET_ASSETS_SKILLS_ZH_COMET_REFERENCE_AUTO_TRANSITION_MD__

cat > "$TARGET_DIR/assets/skills-zh/comet/reference/comet-yaml-fields.md" <<'__COMET_ASSETS_SKILLS_ZH_COMET_REFERENCE_COMET_YAML_FIELDS_MD__'
# .comet.yaml 字段说明

规范路径：`comet/reference/comet-yaml-fields.md`

本文件是 `.comet.yaml` 状态文件的字段参考。按需查阅，不随 skill 一次性加载。

## 示例

```yaml
workflow: full
phase: build
design_doc: docs/superpowers/specs/YYYY-MM-DD-topic-design.md
plan: docs/superpowers/plans/YYYY-MM-DD-feature.md
base_ref: a1b2c3d4e5f6...
build_mode: subagent-driven-development
build_pause: null
subagent_dispatch: confirmed
tdd_mode: tdd
review_mode: standard
isolation: branch
verify_mode: light
verify_result: pending
verification_report: null
branch_status: pending
created_at: 2026-05-26
verified_at: null
archived: false
```

## 必需字段

| 字段 | 含义 |
|------|------|
| `workflow` | `full`、`hotfix` 或 `tweak` |
| `phase` | 当前阶段：`open`、`design`、`build`、`verify`、`archive`（init 统一设为 `open`，guard 负责过渡） |
| `design_doc` | 关联的 Superpowers Design Doc 路径，可为空 |
| `plan` | 关联的 Superpowers Plan 路径，可为空 |
| `base_ref` | init 时记录的 git commit SHA，用于 scale 评估。无 plan 时作为改动文件数统计基准 |
| `build_mode` | 已选择的执行方式，可为空 |
| `build_pause` | build 阶段内部暂停点。`null` 表示无暂停，`plan-ready` 表示 plan 已生成，用户选择切换模型后暂停 |
| `subagent_dispatch` | `null` 或 `confirmed`。仅当已确认当前平台存在真实后台 subagent / Task / multi-agent 调度能力时，`build_mode: subagent-driven-development` 才能写入并用于离开 build 阶段 |
| `tdd_mode` | `tdd` 或 `direct`。full workflow 离开 build 阶段前必须已选择。`tdd` 强制每个任务先写失败测试再实现；`direct` 不强制 TDD。hotfix/tweak 默认 `direct` |
| `review_mode` | `off`、`standard` 或 `thorough`。full workflow 离开 build 阶段前必须已选择；hotfix/tweak 默认 `off` |
| `isolation` | `branch` 或 `worktree`，工作区隔离方式。full 初始化可为 `null`，但只允许持续到 `/comet-build` Step 3 前；hotfix/tweak 默认 `branch` |
| `verify_mode` | `light` 或 `full`，可为空 |
| `auto_transition` | `true` 或 `false`。只控制阶段守卫推进 phase 后是否自动调用下一个 skill；`false` 时由 `comet-state next` 输出 `manual`，暂停下一 skill 调用，但不阻止 phase 字段更新 |
| `verify_result` | `pending`、`pass` 或 `fail` |
| `verification_report` | 验证报告文件路径，verify 通过前必须指向已存在文件 |
| `branch_status` | `pending` 或 `handled`，分支处理完成后设为 `handled` |
| `created_at` | change 创建日期（init 时自动写入），格式 `YYYY-MM-DD` |
| `verified_at` | 验证通过时间，可为空 |
| `archived` | change 是否已归档 |

## 可选字段

| 字段 | 含义 |
|------|------|
| `direct_override` | `true`/`false`。full workflow 如需使用 `build_mode: direct`，必须显式设为 `true` |
| `build_command` | 项目构建命令。guard 优先运行该命令，失败时打印命令输出 |
| `verify_command` | 项目验证命令。verify guard 优先运行该命令，未配置时回退到构建命令 |

## 状态机硬约束

- `build → verify` 前，`isolation` 必须是 `branch` 或 `worktree`
- `build → verify` 前，`build_mode` 必须已选择
- `build_mode: subagent-driven-development` 必须同时有 `subagent_dispatch: confirmed`
- full workflow 离开 build 阶段前 `tdd_mode` 必须已选择为 `tdd` 或 `direct`
- full workflow 离开 build 阶段前 `review_mode` 必须已选择为 `off`、`standard` 或 `thorough`
- `build_mode: direct` 默认只允许 `hotfix` / `tweak`；full workflow 需要 `direct_override: true`
- `build_pause` 不是执行方式，不得写入 `build_mode`
- 这些约束同时存在于 `comet-guard.sh build --apply` 和 `comet-state.sh transition <name> build-complete`
__COMET_ASSETS_SKILLS_ZH_COMET_REFERENCE_COMET_YAML_FIELDS_MD__

cat > "$TARGET_DIR/assets/skills-zh/comet/reference/context-recovery.md" <<'__COMET_ASSETS_SKILLS_ZH_COMET_REFERENCE_CONTEXT_RECOVERY_MD__'
# 上下文压缩恢复协议

规范路径：`comet/reference/context-recovery.md`

本协议由所有可能触发上下文压缩的 comet 子 skill 共享。当 agent 怀疑发生上下文压缩（之前对话被摘要、找不到之前讨论的内容）时，按本协议恢复。

## 恢复步骤

```bash
"$COMET_BASH" "$COMET_STATE" check <change-name> <phase> --recover
```

脚本输出结构化恢复上下文（phase、已完成字段、待完成字段、恢复动作）。按 **Recovery action** 决定下一步。

## build 阶段特殊恢复

若恢复脚本输出 `build_mode: subagent-driven-development`：

1. 使用 Skill 工具重新加载 Superpowers `subagent-driven-development` 技能
2. 重新阅读 `comet/reference/subagent-dispatch.md` 获取 Comet 专属扩展
3. 读取 `openspec/changes/<name>/.comet/subagent-progress.md`，恢复当前 task 或 final review、实现提交、RED/GREEN 证据、已通过审查、未解决反馈和审查-修复轮次
4. 禁止在主会话中直接执行 task
5. 按检查点记录的精确阶段恢复；检查点缺失或不匹配时才从第一个未勾选 task 的 implementer 派发开始
6. task 按 `review_mode` 完成验收并完成定向勾选验证后，立即继续下一个 task，不得总结或询问是否继续

## design 阶段特殊恢复

- 若用户尚未确认设计方案，回到 brainstorming 继续
- 若用户已确认，继续创建 Design Doc
- 恢复时重新加载 `brainstorm-summary.md` + handoff 上下文文件

## verify/archive 阶段恢复

- verify：脚本输出验证状态、分支状态和恢复动作
- archive：若 `archived: true` 且归档目录存在，归档已完成，无需再次执行
__COMET_ASSETS_SKILLS_ZH_COMET_REFERENCE_CONTEXT_RECOVERY_MD__

cat > "$TARGET_DIR/assets/skills-zh/comet/reference/debug-gate.md" <<'__COMET_ASSETS_SKILLS_ZH_COMET_REFERENCE_DEBUG_GATE_MD__'
# 异常调试协议

规范路径：`comet/reference/debug-gate.md`

本协议由 build、hotfix、tweak 等会直接修改代码的 comet 子 skill 共享。当运行程序、测试、构建或手动验证时出现崩溃、异常行为、测试失败或构建失败，必须进入异常调试协议。

## 核心规则

- 立即使用 Skill 工具加载 Superpowers `systematic-debugging` 技能
- 在完成根因调查前，不得提出或实施源码修复

## 四阶段流程

1. 先复现并定位根因，读取完整错误、检查近期变更、追踪数据流
2. 若根因指向源码 bug，先补充能复现该崩溃/异常的最小失败测试，再修改源码
3. 修复后运行该失败测试、相关测试和项目构建/验证命令，确认全部通过
4. 将测试、源码修复和 tasks.md 勾选保留在当前 change 内；不得通过另起一个“写测试用例”的 change 来替代当前 change 的验证闭环
__COMET_ASSETS_SKILLS_ZH_COMET_REFERENCE_DEBUG_GATE_MD__

cat > "$TARGET_DIR/assets/skills-zh/comet/reference/decision-point.md" <<'__COMET_ASSETS_SKILLS_ZH_COMET_REFERENCE_DECISION_POINT_MD__'
# 用户决策点协议

规范路径：`comet/reference/decision-point.md`

本协议由所有包含用户决策点的 comet 子 skill 共享。凡标注为“阻塞点”或“用户决策点”的步骤，都必须按本协议处理。

## 核心规则

- 决策点是阻塞点。到达决策点时必须暂停，等待用户明确选择后才能继续
- 必须使用当前平台可用的用户输入/确认机制获取选择
- 若当前平台没有结构化提问工具，则必须在对话中提出明确选项并停止流程，等待用户回复
- 不得用推荐规则、默认值、历史偏好或“用户应该会同意”的推断代替当前确认
- 用户明确选择前，不得写入对应状态字段、执行对应分支操作或自动继续下一阶段

## 最低呈现要求

- 说明当前决策点正在决定什么
- 给出清晰可选项；需要用户单选时，选项必须互斥且可执行
- 如有推荐，只能作为说明，不能替代用户确认
- 用户选择后，再执行对应命令或状态更新
__COMET_ASSETS_SKILLS_ZH_COMET_REFERENCE_DECISION_POINT_MD__

cat > "$TARGET_DIR/assets/skills-zh/comet/reference/dirty-worktree.md" <<'__COMET_ASSETS_SKILLS_ZH_COMET_REFERENCE_DIRTY_WORKTREE_MD__'
# Dirty Worktree 协议

规范路径：`comet/reference/dirty-worktree.md`

本协议由所有涉及代码修改的 comet 子 skill 共享。当 agent 恢复上下文或继续执行时，必须按本协议处理未提交的工作区改动。各子 skill 可在本协议基础上定义阶段特例（如 verify 阶段对实现改动的特殊处理），详见对应子 skill 文件。本文件不重复阶段特例。

## 1. 检查步骤

继续或开始修改前，必须先运行以下命令：

```bash
git status --short
git diff --stat
git diff --cached --stat
git ls-files --others --exclude-standard
```

必要时再查看 `git diff` / `git diff --cached` / 新建文件内容。

## 2. 核心规则

- 用户可能不会说明自己改了哪里。只要存在 dirty worktree（包括 Git 状态里显示为 `??` 的新建文件），就先假设改动可能来自用户或混合来源
- **构建产物排除**：`??` 文件若匹配 `.gitignore` 中的模式（如 `node_modules/`、`dist/`、`__pycache__/`、`*.o`、`target/`、`build/` 等），自动跳过归因，不视为用户改动
- dirty worktree 只代表代码事实，不会自动推进 `.comet.yaml` 的 `phase` 或勾选 `tasks.md`；只有完成归因、验证、同步必要文档，并通过对应阶段 guard 后，才允许推进 Comet 状态

## 3. 归因分类

将 dirty diff 分为三类：

1. **属于当前 change**：文件和内容能对应当前 change 的目标、tasks.md、plan 或 delta spec。将其纳入当前任务继续，不重复改同一处
2. **不属于当前 change**：文件或内容与当前目标无关。暂停并询问用户：并入当前 change、拆成新 change、保留不处理，或明确授权丢弃
3. **来源不确定**：无法从 diff 和文档判断归属。暂停并向用户汇报文件列表和判断依据，不继续推进阶段

## 4. 常见处理模式

### 已实现但 tasks.md 未勾选

先验证实现（运行构建和测试），通过后补勾任务。不要因为任务未勾选就重做一遍，也不要因为状态文件滞后而忽略代码事实。若当前子 skill 定义了阶段特例，以子 skill 为准。

### 暗示计划或范围已变化

按当前子 skill 的升级、增量更新或回退规则处理，本协议不重复阶段特例。

### 模糊恢复意图

用户说"继续""接着跑""我改了一点""刚才不满意""重新弄""代码动过""先按现在的来"等模糊恢复意图时，按本协议处理。不要要求用户先回忆具体改了哪里。

### open/design 阶段出现代码改动

若当前仍处于 `open` 或 `design`，但 dirty worktree 已经包含代码改动，先按本协议归因，不要直接推进阶段：

- 属于当前 change 的改动：作为需求或设计输入记录到 proposal/design/spec/design doc/tasks 中；进入 build 前仍需完成对应阶段 guard
- 不属于当前 change 或来源不确定：暂停询问用户是并入当前 change、拆成新 change、保留不处理，还是明确授权丢弃
- 禁止在 open/design 阶段直接把代码改动当作已完成实现并推进到 verify

## 5. 禁令

- 禁止在未理解 dirty diff 来源时覆盖、回滚、格式化重写或忽略用户改动
- 禁止在 dirty diff 未解释清楚时判定验证通过
__COMET_ASSETS_SKILLS_ZH_COMET_REFERENCE_DIRTY_WORKTREE_MD__

cat > "$TARGET_DIR/assets/skills-zh/comet/reference/file-structure.md" <<'__COMET_ASSETS_SKILLS_ZH_COMET_REFERENCE_FILE_STRUCTURE_MD__'
# 文件结构参考

规范路径：`comet/reference/file-structure.md`

本文件是 Comet 项目文件结构参考。按需查阅，不随 skill 一次性加载。

```text
openspec/                              # OpenSpec — WHAT
├── config.yaml
├── changes/
│   ├── <name>/                        # 活跃 change
│   │   ├── .openspec.yaml
│   │   ├── .comet.yaml
│   │   ├── proposal.md                # Why + What
│   │   ├── design.md                  # 高层架构决策
│   │   ├── specs/<capability>/spec.md # Delta 能力规格
│   │   ├── .comet/handoff/            # 脚本生成的阶段交接包
│   │   └── tasks.md                   # 任务清单
│   └── archive/YYYY-MM-DD-<name>/     # 已归档
└── specs/<capability>/spec.md         # 主 specs（归档时按 OpenSpec delta 语义合并）

docs/superpowers/                      # Superpowers — HOW
├── specs/YYYY-MM-DD-<topic>-design.md # 设计文档（技术 RFC，归档时标注状态）
└── plans/YYYY-MM-DD-<feature>.md      # 实施计划（文件头含 change 关联元数据）

.comet/
└── config.yaml                        # Comet 项目配置（context_compression 默认 off，可设 beta）
```
__COMET_ASSETS_SKILLS_ZH_COMET_REFERENCE_FILE_STRUCTURE_MD__

cat > "$TARGET_DIR/assets/skills-zh/comet/reference/subagent-dispatch.md" <<'__COMET_ASSETS_SKILLS_ZH_COMET_REFERENCE_SUBAGENT_DISPATCH_MD__'
# Subagent 驱动开发的 Comet 扩展

规范路径：`comet/reference/subagent-dispatch.md`

本文档提供在 Superpowers `subagent-driven-development` 技能**之上**应用的 Comet 专属扩展。该技能负责核心派发循环（每个 task 派发全新 implementer → spec compliance review → code quality review → 下一个 task）并强制连续执行。本文档添加 Comet 特有的真实后台调度、任务追踪、状态验证、代码审查模式和上下文恢复。若 Superpowers 技能与本文档发生冲突时，以本文档中更具体的 Comet 约束为准。

> **⚠️ 关键约束 — 任务之间禁止暂停**
>
> 当一个 task 按 `review_mode` 完成验收并被勾选后，**立即派发下一个 task**，不得停止、总结或询问用户是否继续。用户期望所有 task 按顺序自动执行，无需手动干预。任务之间暂停会中断工作流，导致用户每次都需要手动恢复。
>
> 仅在以下情况才停止并等待用户输入：
> - 任务处于 **BLOCKED** 状态（`review_mode: standard` 下一轮轻量复查仍未通过，或 `review_mode: thorough` 下批次/最终审查 2 轮审查-修复仍未通过）
> - 存在无法从仓库、计划或既有上下文消除的真实歧义
> - 当前环境没有真实后台 agent 调度能力，需要用户改选 `executing-plans`
> - 用户**明确**要求暂停
>
> 此规则适用于整个派发循环，而非单个任务。

## 开始前

1. 读取计划一次，按顺序提取所有未勾选 task 的完整文本。
2. 为每个 task 保存唯一标识：plan 中 checkbox 后的完整任务文本，以及它映射的 OpenSpec task 完整文本（若存在）。若文本不唯一，停止并先修正计划，禁止依赖"第一个匹配项"。
3. 尊重依赖关系；依赖尚未完成的 task 不得提前派发。

## 每个 Task 的 Comet 扩展

在每个 task 上应用这些扩展，叠加在 Superpowers 技能的派发循环之上：

### 0. 派发强制约束（关键）

主会话**仅负责协调**，禁止直接执行 task。主会话禁止修改源代码。协调者唯一允许的文件修改是 plan、OpenSpec task 和 subagent 进度检查点的持久化更新。不得把多个 task 打包给同一个 agent。每个 task 派发一个全新的后台 implementer agent；当 `review_mode` 需要审查或修复时，spec reviewer、code quality reviewer、修复 agent 和 final reviewer 也必须分别使用全新的后台 agent：

- **OpenCode**：对每个 implementer，以及 `review_mode` 要求的 spec reviewer、code quality reviewer、修复 agent 和 final reviewer，使用当前环境可用的后台 agent / Task 机制，并确保每个 task、每个角色都是全新隔离执行。
- **禁止**跨 task 或角色复用 implementer、reviewer 或修复 agent。每个 agent 拥有全新的隔离上下文，并且只接收当前角色所需的单个 task 上下文。
- 若当前环境无真实后台派发能力，不得继续；暂停并等待用户改选 `build_mode: executing-plans`。

### 1. 派发 Prompt 与回报契约

每个 implementer 或修复 agent prompt 必须包含：

- 当前单个 task 的完整文本、架构背景和依赖上下文
- `Language: 使用触发本次工作流的用户请求语言输出`
- 允许修改的文件范围和禁止修改的范围
- 必须执行的测试命令和提交要求
- 修复 agent 还必须收到对应 reviewer 的完整反馈

agent 回报状态必须为 `DONE | DONE_WITH_CONCERNS | BLOCKED | NEEDS_CONTEXT`，并包含实现内容、测试结果、提交哈希、变更文件和顾虑。进入审查前，主会话必须确认提交和文件在当前工作树可见；若当前环境使用隔离副本，先拉取或合并变更。

当 `review_mode` 需要 reviewer 时，每个 reviewer prompt 必须包含完整 task、实现提交或差异以及 RED/GREEN 证据（`tdd_mode: tdd` 时）。reviewer 不得只依据 implementer 的总结进行审查。

### 2. Implementer 范围限制

implementer 只负责实现、测试和提交代码。**implementer 不得勾选 plan 或 OpenSpec task**，也不得只更新内置 Todo 或对话 checklist。

### 3. TDD 硬约束

若 `tdd_mode: tdd`，每个 implementer 和修复 agent 必须先使用 Skill 工具加载 Superpowers `test-driven-development` 技能，并在 prompt 中同时注入：

```text
You MUST follow TDD: write a failing test first, watch it fail, then write minimal code to pass. No production code without a failing test first.
```

implementer 或修复 agent 回报必须提供 **RED 失败命令与失败摘要**、**GREEN 通过命令与通过摘要**；缺少任一证据不得进入审查。spec compliance reviewer 和 code quality reviewer 都必须核验 RED/GREEN 证据与测试覆盖。

### 4. 持久进度检查点

主会话必须维护 `openspec/changes/<name>/.comet/subagent-progress.md`，并在每次派发、agent 回报、审查结果、修复轮次变化和 task 勾选后立即更新。检查点至少记录：

- 当前 plan task 唯一文本及映射的 OpenSpec task 文本
- 当前阶段：`implementing | spec-review | quality-review | checkoff | done | blocked | final-review | final-fix`
- 实现提交哈希、变更文件和 RED/GREEN 证据
- 已选择的 `review_mode`
- 已通过的审查阶段及尚未解决的 reviewer 反馈
- 当前 task、批次或 final review 的审查-修复轮次（`standard` 最多 1 轮，`thorough` 最多 2 轮，`off` 为 0 轮）

该文件只保存恢复所需的协调状态，不替代 plan 或 OpenSpec checkbox。当前 task 完成后保留其最终记录，开始下一个 task 时用下一 task 的记录替换。

### 5. 代码审查模式与轮次限制

当 `review_mode: standard` 时，每个 task 不自动派发 per-task reviewer；implementer 必须自测、提交并回报证据，协调者完成定向勾选验证。所有 task 完成后只派发一次最终轻量 code reviewer，审查范围限定为正确性、安全和边界条件。若最终轻量审查发现 CRITICAL 或 IMPORTANT 问题，最多自动派发一轮修复 agent 并复查一次；复查仍未通过时标记 **BLOCKED**，暂停并把反馈交给用户。非 CRITICAL 发现可记录接受理由后继续。

当 `review_mode: thorough` 时，不执行每 task 双审查。协调者按批次或风险边界运行合并审查：每完成最多 3 个 task、或完成一个跨模块/高风险边界时，派发一个 reviewer 同时检查 spec compliance 与 code quality。若总 task 数不超过 3 且没有高风险边界，可跳过中途批次审查，只做最终完整审查。所有 task 完成后再派发一次最终完整 reviewer。批次和最终审查各最多 2 轮审查-修复；仍未通过则标记 **BLOCKED**，暂停并把累计反馈交给用户。

当 `review_mode: off` 时，不自动派发 spec reviewer、code quality reviewer、final reviewer 或审查修复 agent。任务完成依据 implementer 的测试/构建证据、当前工作树确认、任务唯一文本勾选验证和用户显式要求。若执行过程中出现测试失败、构建失败或异常行为，仍必须按异常调试协议处理，不得用 `off` 跳过真实问题。

### 6. Task 勾选与验证

**按 `review_mode` 完成验收后**，主会话：

1. 将 plan 中保存的唯一 task 文本从 `- [ ]` 改为 `- [x]`
2. 若存在映射，再同步勾选 OpenSpec task
3. 提交这次进度更新
4. 运行定向验证：

```bash
"$COMET_BASH" "$COMET_STATE" task-checkoff "$PLAN_FILE" "$PLAN_TASK_TEXT"
"$COMET_BASH" "$COMET_STATE" task-checkoff "openspec/changes/<name>/tasks.md" "$OPENSPEC_TASK_TEXT"
```

仅在对应映射存在时运行第二条。脚本会要求任务文本恰好出现一次且该项已勾选；验证失败时不得进入下一个 task。

## 收尾

- **自动继续**：按 `review_mode` 完成验收并勾选 task 后，立即派发下一个未勾选的 task。禁止总结、禁止询问用户是否继续、禁止在任务之间等待用户输入。这是不可协商的 —— Superpowers 技能强制连续执行，文档顶部的关键约束进一步强化此规则。
- 所有 task 完成后，若 `review_mode: standard`，将检查点切换为 `final-review`，只派发一次最终轻量 code reviewer。CRITICAL 或 IMPORTANT 问题最多自动修复和复查一轮；仍未通过则暂停交给用户。通过或接受非 CRITICAL 发现后继续返回 `comet-build`。
- 所有 task 完成后，若 `review_mode: thorough`，将检查点切换为 `final-review`，派发一次最终完整 reviewer。CRITICAL 或 IMPORTANT 问题最多自动修复和复查两轮；仍未通过则暂停交给用户。通过或接受非 CRITICAL 发现后继续返回 `comet-build`。
- 所有 task 完成后，若 `review_mode: off`，不进入 `final-review` 或 `final-fix`，但必须在持久产物中记录跳过自动代码审查的原因，然后返回 `comet-build`。
- final review 通过后，结束的只是 subagent 派发循环，不是 Comet workflow。不得加载 `finishing-a-development-branch`，不得停下来询问用户下一步；必须返回 `comet-build` 继续执行退出条件、阶段守卫和后续阶段衔接。

## 上下文恢复

重新加载 Superpowers `subagent-driven-development` 技能并重新阅读本文档。先读取 `openspec/changes/<name>/.comet/subagent-progress.md`，再与第一个未勾选 task 和当前工作树核对：

- 检查点与未勾选 task 匹配时，从记录的精确阶段恢复，保留实现提交、RED/GREEN 证据、`review_mode`、已通过的审查阶段、未解决反馈和当前审查-修复轮次；不得重置轮次或重复已经通过的阶段。
- 检查点缺失或与未勾选 task 不匹配时，为第一个未勾选 task 创建新检查点并从 implementer 派发开始。
- 检查点中的提交或文件在当前工作树不可见时，先拉取、合并或恢复对应变更；不得假定实现已存在。
- 所有 task 已勾选且检查点处于 `final-review` 或 `final-fix` 时，从最终审查的精确阶段恢复，并保留最终反馈和审查-修复轮次；不得重新进入已完成的 task。

已提交但未按 `review_mode` 完成验收的 task 保持未勾选，并按检查点重新进入对应的验证、审查或修复流程。
__COMET_ASSETS_SKILLS_ZH_COMET_REFERENCE_SUBAGENT_DISPATCH_MD__

cat > "$TARGET_DIR/assets/skills/comet/scripts/comet-archive.sh" <<'__COMET_ASSETS_SKILLS_COMET_SCRIPTS_COMET_ARCHIVE_SH__'
#!/bin/bash
# Comet Archive — automates the archive phase in one command
# Usage: comet-archive.sh <change-name> [--dry-run]
# Exit 0 = archive complete, exit 1 = fatal error

set -euo pipefail

COMET_BASH="${COMET_BASH:-${BASH:-bash}}"
COMET_OPENSPEC="${COMET_OPENSPEC:-openspec}"

red() { echo -e "\033[31m$1\033[0m" >&2; }
green() { echo -e "\033[32m$1\033[0m" >&2; }
yellow() { echo -e "\033[33m$1\033[0m" >&2; }

DRY_RUN=0
if [[ "${2:-}" == "--dry-run" ]]; then
  DRY_RUN=1
fi

# Input validation
validate_change_name() {
  local name="$1"
  if [ -z "$name" ]; then
    red "FATAL: Change name cannot be empty"
    exit 1
  fi
  if [[ ! "$name" =~ ^[a-zA-Z0-9_-]+$ ]]; then
    red "FATAL: Invalid change name: '$name'"
    red "Valid characters: a-z, A-Z, 0-9, -, _"
    exit 1
  fi
  if [[ "$name" =~ \.\. ]]; then
    red "FATAL: Change name cannot contain '..'"
    exit 1
  fi
}

CHANGE="$1"
validate_change_name "$CHANGE"

CHANGE_DIR="openspec/changes/$CHANGE"
YAML="$CHANGE_DIR/.comet.yaml"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd -P)"
STATE_SH="$SCRIPT_DIR/comet-state.sh"
TODAY=$(date -u +%Y-%m-%d)
ARCHIVE_NAME="${TODAY}-${CHANGE}"
ARCHIVE_DIR="openspec/changes/archive/${ARCHIVE_NAME}"

STEPS_OK=0
STEPS_TOTAL=0

step_ok() {
  green "  [OK] $1"
  STEPS_OK=$((STEPS_OK + 1))
  STEPS_TOTAL=$((STEPS_TOTAL + 1))
}

step_fail() {
  red "  [FAIL] $1"
  STEPS_TOTAL=$((STEPS_TOTAL + 1))
}

step_dry_run() {
  yellow "  [DRY-RUN] $1"
  STEPS_OK=$((STEPS_OK + 1))
  STEPS_TOTAL=$((STEPS_TOTAL + 1))
}

echo "=== Comet Archive: $CHANGE ===" >&2

# --- Step 1: Read .comet.yaml, extract paths ---

yaml_field() {
  local field="$1"
  if [ -f "$STATE_SH" ]; then
    "$COMET_BASH" "$STATE_SH" get "$CHANGE" "$field" 2>/dev/null
  else
    if [ -f "$YAML" ]; then
      local value
      value=$(grep "^${field}:" "$YAML" 2>/dev/null | sed "s/^${field}: *//" || true)
      value=$(strip_inline_comment "$value")
      strip_wrapping_quotes "$value"
    fi
  fi
}

strip_inline_comment() {
  local value="$1"
  printf '%s\n' "$value" | awk -v squote="'" '
    {
      out = ""
      quote = ""
      for (i = 1; i <= length($0); i++) {
        c = substr($0, i, 1)
        if (quote == "") {
          if (c == "\"" || c == squote) {
            quote = c
          } else if (c == "#" && (i == 1 || substr($0, i - 1, 1) ~ /[[:space:]]/)) {
            sub(/[[:space:]]+$/, "", out)
            print out
            next
          }
        } else if (c == quote) {
          quote = ""
        }
        out = out c
      }
      print out
    }
  '
}

strip_wrapping_quotes() {
  local value="$1"
  case "$value" in
    \"*\") printf '%s\n' "${value:1:${#value}-2}" ;;
    \'*\') printf '%s\n' "${value:1:${#value}-2}" ;;
    *) printf '%s\n' "$value" ;;
  esac
}

if [ ! -f "$YAML" ]; then
  red "FATAL: .comet.yaml not found in $CHANGE_DIR/"
  exit 1
fi

DESIGN_DOC=$(yaml_field "design_doc")
PLAN_PATH=$(yaml_field "plan")

# --- Step 2: Validate entry state ---

PHASE_VAL=$(yaml_field "phase")
VERIFY_VAL=$(yaml_field "verify_result")
ARCHIVED_VAL=$(yaml_field "archived")

if [ "$PHASE_VAL" != "archive" ]; then
  red "FATAL: phase is '$PHASE_VAL', expected 'archive'"
  exit 1
fi

if [ "$VERIFY_VAL" != "pass" ]; then
  red "FATAL: verify_result is '$VERIFY_VAL', expected 'pass'. Run comet-verify first."
  exit 1
fi

if [ "$ARCHIVED_VAL" = "true" ]; then
  red "FATAL: change already archived"
  exit 1
fi

step_ok "Entry state verified"

# --- Step 3: Check archive target ---

if [ -d "$ARCHIVE_DIR" ]; then
  red "FATAL: archive target already exists: $ARCHIVE_DIR"
  exit 1
fi

step_ok "Archive target available"

# --- Step 4: Prepare document frontmatter annotation ---

annotate_frontmatter() {
  local file="$1"
  local extra_fields="$2"

  if [ ! -f "$file" ]; then
    return 0
  fi

  if [ "$DRY_RUN" -eq 1 ]; then
    step_dry_run "Would annotate: $file"
    return 0
  fi

  if head -1 "$file" | grep -q '^---'; then
    local tmp_file
    tmp_file=$(mktemp)
    chmod 600 "$tmp_file"
    awk -v archive="$ARCHIVE_NAME" -v extra="$extra_fields" '
      /^archived-with:/ { next }
      NR==1 && /^---/ { print; next }
      /^---/ && NR>1 {
        print "archived-with: " archive
        if (extra != "") print extra
        print; next
      }
      { print }
    ' "$file" > "$tmp_file"
    mv "$tmp_file" "$file"
  else
    local tmp_file
    tmp_file=$(mktemp)
    chmod 600 "$tmp_file"
    {
      echo "---"
      echo "archived-with: $ARCHIVE_NAME"
      if [ -n "$extra_fields" ]; then
        echo "$extra_fields"
      fi
      echo "status: final"
      echo "---"
      cat "$file"
    } > "$tmp_file"
    mv "$tmp_file" "$file"
  fi

  step_ok "Annotated: $file"
}

# --- Step 5: Run OpenSpec archive for delta merge and move ---

verify_main_specs_clean() {
  if [ ! -d "openspec/specs" ]; then
    return 0
  fi

  local found=0
  local matches
  for spec_file in openspec/specs/*/spec.md; do
    [ -f "$spec_file" ] || continue
    matches=$(grep -nE '^## (ADDED|MODIFIED|REMOVED|RENAMED) Requirements$' "$spec_file" 2>/dev/null || true)
    if [ -n "$matches" ]; then
      red "FATAL: delta-only section heading leaked into main spec: $spec_file"
      printf '%s\n' "$matches" >&2
      found=1
    fi
  done

  if [ "$found" -ne 0 ]; then
    return 1
  fi
  return 0
}

resolve_archive_dir() {
  if [ -d "$ARCHIVE_DIR" ]; then
    return 0
  fi
  # Fallback: search for any directory matching *-$CHANGE in archive
  local found
  found=$(find "openspec/changes/archive" -maxdepth 1 -mindepth 1 -type d -name "*-$CHANGE" 2>/dev/null | head -1 || true)
  if [ -n "$found" ]; then
    ARCHIVE_DIR="$found"
    ARCHIVE_NAME=$(basename "$found")
    return 0
  fi
  return 1
}

if [ "$DRY_RUN" -eq 1 ]; then
  step_dry_run "Would run OpenSpec archive: $CHANGE"
else
  if ! command -v "$COMET_OPENSPEC" >/dev/null 2>&1; then
    red "FATAL: OpenSpec CLI not found: $COMET_OPENSPEC"
    red "Install OpenSpec or set COMET_OPENSPEC to the openspec executable."
    exit 1
  fi

  "$COMET_OPENSPEC" archive "$CHANGE" --yes >&2
  if ! resolve_archive_dir; then
    step_fail "OpenSpec archive output not found"
    exit 1
  else
    step_ok "OpenSpec archive completed: $ARCHIVE_DIR"
  fi

  verify_main_specs_clean
  step_ok "Main specs verified clean"
fi

# --- Step 6: Annotate design doc and plan frontmatter ---

if [ -n "$DESIGN_DOC" ] && [ "$DESIGN_DOC" != "null" ]; then
  annotate_frontmatter "$DESIGN_DOC" "status: final"
fi

if [ -n "$PLAN_PATH" ] && [ "$PLAN_PATH" != "null" ]; then
  annotate_frontmatter "$PLAN_PATH" ""
fi

# --- Step 7: Mark archived via comet-state transition ---

ARCHIVE_YAML="$ARCHIVE_DIR/.comet.yaml"

if [ "$DRY_RUN" -eq 1 ]; then
  step_dry_run "Would set archived: true in $ARCHIVE_YAML"
else
  if [ -f "$ARCHIVE_YAML" ]; then
    "$COMET_BASH" "$STATE_SH" transition "$ARCHIVE_NAME" archived >/dev/null
    step_ok "archived: true"
  else
    step_fail "archived: true (.comet.yaml not found after move)"
  fi
fi

# --- Step 8: Print summary ---

echo "" >&2
if [ "$DRY_RUN" -eq 1 ]; then
  yellow "Dry run complete. $STEPS_OK/$STEPS_TOTAL steps would succeed."
else
  green "Archive complete. $STEPS_OK/$STEPS_TOTAL steps succeeded."
fi

if [ "$STEPS_OK" -lt "$STEPS_TOTAL" ]; then
  exit 1
fi

exit 0
__COMET_ASSETS_SKILLS_COMET_SCRIPTS_COMET_ARCHIVE_SH__
chmod +x "$TARGET_DIR/assets/skills/comet/scripts/comet-archive.sh"

cat > "$TARGET_DIR/assets/skills/comet/scripts/comet-env.sh" <<'__COMET_ASSETS_SKILLS_COMET_SCRIPTS_COMET_ENV_SH__'
#!/bin/bash
# Comet script locator — source this file to export paths to bundled scripts.
#
# Usage:
#   . /path/to/comet/scripts/comet-env.sh
#
# This file is sourced by workflow snippets. Do not set global shell options here.

_comet_env_source="${BASH_SOURCE[0]:-$0}"
_comet_script_dir="$(cd "$(dirname "$_comet_env_source")" && pwd -P)"
_comet_env_sourced=0
(return 0 2>/dev/null) && _comet_env_sourced=1

export COMET_GUARD="${COMET_GUARD:-${_comet_script_dir}/comet-guard.sh}"
export COMET_STATE="${COMET_STATE:-${_comet_script_dir}/comet-state.sh}"
export COMET_HANDOFF="${COMET_HANDOFF:-${_comet_script_dir}/comet-handoff.sh}"
export COMET_ARCHIVE="${COMET_ARCHIVE:-${_comet_script_dir}/comet-archive.sh}"
export COMET_YAML_VALIDATE="${COMET_YAML_VALIDATE:-${_comet_script_dir}/comet-yaml-validate.sh}"

_comet_bash_is_usable() {
  local _comet_bash_candidate="$1"
  if [ -z "$_comet_bash_candidate" ]; then
    return 1
  fi
  case "$_comet_bash_candidate" in
    */Windows/System32/bash.exe|*/windows/system32/bash.exe|*\\Windows\\System32\\bash.exe|*\\windows\\system32\\bash.exe)
      return 1
      ;;
  esac
  "$_comet_bash_candidate" -lc 'printf comet-bash-ok' >/dev/null 2>&1
}

_comet_resolve_bash() {
  local _comet_bash_candidate

  if _comet_bash_is_usable "${COMET_BASH:-}"; then
    printf '%s\n' "$COMET_BASH"
    return 0
  fi

  if _comet_bash_is_usable "${BASH:-}"; then
    printf '%s\n' "$BASH"
    return 0
  fi

  _comet_bash_candidate="$(command -v sh 2>/dev/null | awk '{ sub(/\/sh(\.exe)?$/, "/bash.exe"); print }')"
  if _comet_bash_is_usable "$_comet_bash_candidate"; then
    printf '%s\n' "$_comet_bash_candidate"
    return 0
  fi

  _comet_bash_candidate="$(command -v bash 2>/dev/null || true)"
  if _comet_bash_is_usable "$_comet_bash_candidate"; then
    printf '%s\n' "$_comet_bash_candidate"
    return 0
  fi

  return 1
}

COMET_BASH="$(_comet_resolve_bash || true)"
export COMET_BASH

_comet_env_fail() {
  echo "ERROR: Comet scripts not found. Ensure the comet skill is installed completely." >&2
  echo "Expected path pattern: */comet/scripts/comet-*.sh under project or platform skill directories" >&2
}

_comet_bash_fail() {
  echo "ERROR: usable bash not found. Install Git Bash or set COMET_BASH to a working bash executable." >&2
  echo "Windows WSL launcher bash.exe is not supported for Comet scripts." >&2
}

_comet_env_abort() {
  local _comet_env_was_sourced="$_comet_env_sourced"
  unset _comet_env_source _comet_script_dir _comet_script _comet_env_missing _comet_env_sourced
  unset _comet_bash_candidate
  unset -f _comet_env_fail _comet_bash_fail _comet_bash_is_usable _comet_resolve_bash
  if [ "$_comet_env_was_sourced" -eq 1 ]; then
    unset -f _comet_env_abort
    return 1
  fi
  exit 1
}

_comet_env_missing=0
if [ -z "$COMET_BASH" ]; then
  _comet_bash_fail
  _comet_env_missing=1
fi
for _comet_script in \
  "$COMET_GUARD" \
  "$COMET_STATE" \
  "$COMET_HANDOFF" \
  "$COMET_ARCHIVE" \
  "$COMET_YAML_VALIDATE"; do
  if [ ! -f "$_comet_script" ]; then
    _comet_env_fail
    _comet_env_missing=1
    break
  fi
done

if [ "$_comet_env_missing" -ne 0 ]; then
  _comet_env_abort
else
  unset _comet_env_source _comet_script_dir _comet_script _comet_env_missing _comet_env_sourced
  unset _comet_bash_candidate
  unset -f _comet_env_fail _comet_bash_fail _comet_bash_is_usable _comet_resolve_bash _comet_env_abort
fi
__COMET_ASSETS_SKILLS_COMET_SCRIPTS_COMET_ENV_SH__
chmod +x "$TARGET_DIR/assets/skills/comet/scripts/comet-env.sh"

cat > "$TARGET_DIR/assets/skills/comet/scripts/comet-guard.sh" <<'__COMET_ASSETS_SKILLS_COMET_SCRIPTS_COMET_GUARD_SH__'
#!/bin/bash
# Comet Phase Guard — validates exit conditions before phase transitions
# Usage: comet-guard.sh <change-name> <current-phase> [--apply]
# Phases: open, design, build, verify, archive
# Exit 0 = all checks pass, exit 1 = blocked (reasons printed to stderr)
# shellcheck disable=SC2329  # Functions called indirectly via check() dispatch

set -euo pipefail

COMET_BASH="${COMET_BASH:-${BASH:-bash}}"

red() { echo -e "\033[31m$1\033[0m" >&2; }
green() { echo -e "\033[32m$1\033[0m" >&2; }
warn() { echo -e "\033[33m$1\033[0m" >&2; }

# Input validation - prevent path traversal
validate_change_name() {
  local name="$1"
  # Reject empty names
  if [ -z "$name" ]; then
    red "ERROR: Change name cannot be empty" >&2
    exit 1
  fi
  # Only allow alphanumeric, hyphens, and underscores
  if [[ ! "$name" =~ ^[a-zA-Z0-9_-]+$ ]]; then
    red "ERROR: Invalid change name: '$name'" >&2
    red "Valid characters: a-z, A-Z, 0-9, -, _" >&2
    exit 1
  fi
  # Reject path traversal attempts
  if [[ "$name" =~ \.\. ]]; then
    red "ERROR: Change name cannot contain '..' (path traversal not allowed)" >&2
    exit 1
  fi
}

if [ "${COMET_GUARD_SOURCE_ONLY:-0}" = "1" ]; then
  CHANGE="${CHANGE:-}"
  PHASE="${PHASE:-}"
  APPLY="${APPLY:-0}"
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd -P)"
  CHANGE_DIR="${CHANGE_DIR:-}"
else
  validate_change_name "$1"

  CHANGE="$1"
  PHASE="$2"
  APPLY=0
  SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd -P)"
  if [[ "${3:-}" == "--apply" ]]; then
    APPLY=1
  fi
  CHANGE_DIR="openspec/changes/$CHANGE"
  if [ "$PHASE" = "archive" ] && [ ! -d "$CHANGE_DIR" ] && [ -d "openspec/changes/archive/$CHANGE" ]; then
    CHANGE_DIR="openspec/changes/archive/$CHANGE"
  fi
fi

BLOCK=0
check() {
  local desc="$1"
  shift
  local output
  if output=$("$@" 2>&1); then
    green "  [PASS] $desc"
  else
    red "  [FAIL] $desc"
    if [ -n "$output" ]; then
      while IFS= read -r line; do
        red "    $line"
      done <<< "$output"
    fi
    BLOCK=1
  fi
}

# --- Helper functions ---

tasks_all_done() {
  local tasks="$CHANGE_DIR/tasks.md"
  if [ ! -f "$tasks" ]; then
    echo "tasks.md is missing at $tasks" >&2
    echo "Next: restore or create tasks.md for this change before leaving build." >&2
    return 1
  fi
  if ! grep -q '\- \[x\]' "$tasks"; then
    echo "tasks.md has no completed tasks." >&2
    echo "Next: complete implementation tasks and mark them with '- [x]'." >&2
    return 1
  fi
  if grep -q '\- \[ \]' "$tasks"; then
    echo "Unfinished tasks:" >&2
    grep -n '\- \[ \]' "$tasks" >&2 || true
    echo "Next: complete or explicitly remove unfinished tasks, then mark tasks.md with '- [x]'." >&2
    return 1
  fi
  return 0
}

tasks_has_any() {
  local tasks="$CHANGE_DIR/tasks.md"
  [ -f "$tasks" ] && grep -q '\- \[' "$tasks"
}

plan_tasks_all_done() {
  local plan
  plan=$(yaml_field_value "plan" 2>/dev/null || true)

  if [ -z "$plan" ] || [ "$plan" = "null" ]; then
    return 0
  fi
  if [ ! -f "$plan" ]; then
    echo "plan file is missing at $plan" >&2
    echo "Next: restore the Superpowers plan file or update .comet.yaml plan before leaving build." >&2
    return 1
  fi
  if grep -q '^[[:space:]]*- \[ \]' "$plan"; then
    echo "Unfinished Superpowers plan tasks:" >&2
    grep -n '^[[:space:]]*- \[ \]' "$plan" >&2 || true
    echo "Next: check off corresponding completed plan tasks, then commit the plan update." >&2
    return 1
  fi
  return 0
}

yaml_field_value() {
  local field="$1"
  local yaml="$CHANGE_DIR/.comet.yaml"
  if [ -f "$yaml" ]; then
    local value
    value=$(grep "^${field}:" "$yaml" 2>/dev/null | sed "s/^${field}: *//" || true)
    value=$(strip_inline_comment "$value")
    strip_wrapping_quotes "$value"
  fi
}

strip_inline_comment() {
  local value="$1"
  printf '%s\n' "$value" | awk -v squote="'" '
    {
      out = ""
      quote = ""
      for (i = 1; i <= length($0); i++) {
        c = substr($0, i, 1)
        if (quote == "") {
          if (c == "\"" || c == squote) {
            quote = c
          } else if (c == "#" && (i == 1 || substr($0, i - 1, 1) ~ /[[:space:]]/)) {
            sub(/[[:space:]]+$/, "", out)
            print out
            next
          }
        } else if (c == quote) {
          quote = ""
        }
        out = out c
      }
      print out
    }
  '
}

strip_wrapping_quotes() {
  local value="$1"
  case "$value" in
    \"*\")
      printf '%s\n' "${value:1:${#value}-2}"
      ;;
    \'*\')
      printf '%s\n' "${value:1:${#value}-2}"
      ;;
    *)
      printf '%s\n' "$value"
      ;;
  esac
}

project_config_value() {
  local field="$1"
  local value

  value=$(yaml_field_value "$field" 2>/dev/null || true)
  if [ -n "$value" ] && [ "$value" != "null" ]; then
    echo "$value"
    return 0
  fi

  for config in ".comet.yaml" "comet.yaml" ".comet.yml" "comet.yml"; do
    if [ -f "$config" ]; then
      value=$(grep "^${field}:" "$config" 2>/dev/null | sed "s/^${field}: *//" || true)
      value=$(strip_inline_comment "$value")
      value=$(strip_wrapping_quotes "$value")
      if [ -n "$value" ] && [ "$value" != "null" ]; then
        echo "$value"
        return 0
      fi
    fi
  done
}

file_nonempty() {
  [ -f "$1" ] && [ -s "$1" ]
}

is_windows_bash() {
  case "$(uname -s 2>/dev/null || true)" in
    MINGW*|MSYS*|CYGWIN*) return 0 ;;
    *) return 1 ;;
  esac
}

run_command_string() {
  local command="$1"
  if [ -z "$command" ]; then
    red "ERROR: build/verify command is empty" >&2
    return 1
  fi
  # Basic command injection guard: reject dangerous shell metacharacters
  # Quotes are allowed to support paths with spaces (e.g. Windows)
  if [[ "$command" =~ [\;\|\&\$\`] ]]; then
    red "ERROR: build/verify command contains shell metacharacters: $command" >&2
    red "Allowed: alphanumeric, spaces, hyphens, underscores, dots, colons, forward slashes, quotes" >&2
    return 1
  fi
  echo "+ $command" >&2
  "$COMET_BASH" -lc "$command"
}

hash_stream() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum | awk '{print $1}'
  elif command -v shasum >/dev/null 2>&1; then
    shasum -a 256 | awk '{print $1}'
  else
    echo "sha256sum or shasum is required" >&2
    return 1
  fi
}

hash_file() {
  local file="$1"
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$file" | awk '{print $1}'
  elif command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$file" | awk '{print $1}'
  else
    echo "sha256sum or shasum is required" >&2
    return 1
  fi
}

handoff_source_files() {
  printf '%s\n' "$CHANGE_DIR/proposal.md"
  printf '%s\n' "$CHANGE_DIR/design.md"
  printf '%s\n' "$CHANGE_DIR/tasks.md"
  if [ -d "$CHANGE_DIR/specs" ]; then
    find "$CHANGE_DIR/specs" -path '*/spec.md' -type f 2>/dev/null | sort
  fi
}

compute_handoff_hash() {
  local hash_input
  hash_input=$(handoff_source_files | while IFS= read -r file; do
    if [ -f "$file" ]; then
      printf 'path:%s\n' "$file"
      printf 'sha256:%s\n' "$(hash_file "$file")"
    fi
  done)
  printf '%s' "$hash_input" | hash_stream
}

preflight() {

  if [ ! -d "$CHANGE_DIR" ]; then
    red "FATAL: change directory not found: $CHANGE_DIR"
    exit 1
  fi
  if [ ! -f "$CHANGE_DIR/.comet.yaml" ]; then
    red "FATAL: .comet.yaml not found in $CHANGE_DIR"
    exit 1
  fi

  # Schema validation
  local validate_script
  validate_script="$SCRIPT_DIR/comet-yaml-validate.sh"
  if [ -f "$validate_script" ]; then
    if ! "$COMET_BASH" "$validate_script" "$CHANGE" 2>/dev/null; then
      "$COMET_BASH" "$validate_script" "$CHANGE" || true
      red "FATAL: .comet.yaml schema validation failed"
      exit 1
    fi
  fi
}

build_passes() {
  if [ "${COMET_SKIP_BUILD:-0}" = "1" ]; then
    return 0
  fi
  local configured_build
  configured_build=$(project_config_value "build_command" 2>/dev/null || true)
  if [ -n "$configured_build" ]; then
    run_command_string "$configured_build"
    return $?
  fi
  if [ -f "package.json" ] && grep -q '"build"' "package.json"; then
    npm run build
    return $?
  fi
  if [ -f "pom.xml" ]; then
    if [ -x "./mvnw" ]; then
      ./mvnw compile -q
    elif is_windows_bash && command -v mvn.cmd >/dev/null 2>&1; then
      mvn.cmd compile -q
    else
      mvn compile -q
    fi
    return $?
  fi
  if [ -f "Cargo.toml" ]; then
    cargo build
    return $?
  fi
  return 1
}

verification_command_passes() {
  if [ "${COMET_SKIP_BUILD:-0}" = "1" ]; then
    return 0
  fi
  local configured_verify
  configured_verify=$(project_config_value "verify_command" 2>/dev/null || true)
  if [ -n "$configured_verify" ]; then
    run_command_string "$configured_verify"
    return $?
  fi
  build_passes
}

isolation_selected() {
  local isolation
  isolation=$(yaml_field_value "isolation" 2>/dev/null || true)
  case "$isolation" in
    branch|worktree) return 0 ;;
    *)
      echo "isolation must be branch or worktree, got '${isolation:-null}'" >&2
      echo "Next: ask the user to choose branch or worktree, create the chosen isolation, then run:" >&2
      echo "  \"\$COMET_BASH\" \"\$COMET_STATE\" set $CHANGE isolation <branch|worktree>" >&2
      return 1
      ;;
  esac
}

build_mode_selected() {
  local build_mode
  build_mode=$(yaml_field_value "build_mode" 2>/dev/null || true)
  case "$build_mode" in
    subagent-driven-development|executing-plans|direct) return 0 ;;
    *)
      echo "build_mode must be selected before leaving build, got '${build_mode:-null}'" >&2
      echo "Next: ask the user to choose an execution mode, then run:" >&2
      echo "  \"\$COMET_BASH\" \"\$COMET_STATE\" set $CHANGE build_mode <subagent-driven-development|executing-plans>" >&2
      return 1
      ;;
  esac
}

build_mode_allowed_for_workflow() {
  local workflow build_mode direct_override
  workflow=$(yaml_field_value "workflow" 2>/dev/null || true)
  build_mode=$(yaml_field_value "build_mode" 2>/dev/null || true)
  direct_override=$(yaml_field_value "direct_override" 2>/dev/null || true)

  if [ "$build_mode" != "direct" ]; then
    return 0
  fi
  case "$workflow" in
    hotfix|tweak) return 0 ;;
    *)
      if [ "$direct_override" = "true" ]; then
        return 0
      fi
      echo "build_mode=direct is only allowed for hotfix/tweak unless direct_override: true is recorded" >&2
      echo "Next: choose executing-plans or subagent-driven-development, or stop and ask the user for an explicit direct override." >&2
      return 1
      ;;
  esac
}

subagent_dispatch_confirmed() {
  local build_mode subagent_dispatch
  build_mode=$(yaml_field_value "build_mode" 2>/dev/null || true)
  subagent_dispatch=$(yaml_field_value "subagent_dispatch" 2>/dev/null || true)

  if [ "$build_mode" != "subagent-driven-development" ]; then
    return 0
  fi

  if [ "$subagent_dispatch" = "confirmed" ]; then
    return 0
  fi

  echo "subagent_dispatch must be confirmed before using build_mode=subagent-driven-development" >&2
  echo "Next: confirm the current platform has a real background subagent/Task/multi-agent dispatcher, then run:" >&2
  echo "  \"\$COMET_BASH\" \"\$COMET_STATE\" set $CHANGE subagent_dispatch confirmed" >&2
  echo "Or ask the user to switch to executing-plans and run:" >&2
  echo "  \"\$COMET_BASH\" \"\$COMET_STATE\" set $CHANGE build_mode executing-plans" >&2
  return 1
}

tdd_mode_selected() {
  local workflow tdd_mode
  workflow=$(yaml_field_value "workflow" 2>/dev/null || true)
  tdd_mode=$(yaml_field_value "tdd_mode" 2>/dev/null || true)

  case "$workflow" in
    hotfix|tweak) return 0 ;;
  esac

  case "$tdd_mode" in
    tdd|direct) return 0 ;;
    *)
      echo "tdd_mode must be tdd or direct for full workflow, got '${tdd_mode:-null}'" >&2
      echo "Next: ask the user to choose TDD enforcement level, then run:" >&2
      echo "  \"\$COMET_BASH\" \"\$COMET_STATE\" set $CHANGE tdd_mode <tdd|direct>" >&2
      return 1
      ;;
  esac
}

review_mode_selected() {
  local workflow review_mode
  workflow=$(yaml_field_value "workflow" 2>/dev/null || true)
  review_mode=$(yaml_field_value "review_mode" 2>/dev/null || true)

  case "$workflow" in
    hotfix|tweak) return 0 ;;
  esac

  case "$review_mode" in
    off|standard|thorough) return 0 ;;
    *)
      echo "review_mode must be off, standard, or thorough before leaving build, got '${review_mode:-null}'" >&2
      echo "Next: ask the user to choose code review mode, then run:" >&2
      echo "  \"\$COMET_BASH\" \"\$COMET_STATE\" set $CHANGE review_mode <off|standard|thorough>" >&2
      return 1
      ;;
  esac
}

verify_result_is_pass() {
  local result
  result=$(yaml_field_value "verify_result" 2>/dev/null || true)
  [ "$result" = "pass" ]
}

verification_report_exists() {
  local report
  report=$(yaml_field_value "verification_report" 2>/dev/null || true)
  [ -n "$report" ] && [ "$report" != "null" ] && [ -f "$report" ]
}

branch_status_handled() {
  local status
  status=$(yaml_field_value "branch_status" 2>/dev/null || true)
  [ "$status" = "handled" ]
}

design_handoff_context_valid() {
  local context recorded_hash actual_hash markdown
  context=$(yaml_field_value "handoff_context" 2>/dev/null || true)
  recorded_hash=$(yaml_field_value "handoff_hash" 2>/dev/null || true)

  if [ -z "$context" ] || [ "$context" = "null" ]; then
    echo "handoff_context is missing from .comet.yaml" >&2
    echo "Next: run \"\$COMET_BASH\" \"\$COMET_HANDOFF\" $CHANGE design --write before invoking Superpowers." >&2
    return 1
  fi
  if [ ! -s "$context" ]; then
    echo "handoff_context does not point to a non-empty file: $context" >&2
    echo "Next: regenerate the design handoff with comet-handoff.sh." >&2
    return 1
  fi
  if [[ ! "$recorded_hash" =~ ^[a-f0-9]{64}$ ]]; then
    echo "handoff_hash is missing or invalid: ${recorded_hash:-null}" >&2
    echo "Next: regenerate the design handoff with comet-handoff.sh." >&2
    return 1
  fi

  actual_hash=$(compute_handoff_hash)
  if [ "$actual_hash" != "$recorded_hash" ]; then
    echo "OpenSpec artifacts changed after handoff was generated." >&2
    echo "Expected handoff_hash: $recorded_hash" >&2
    echo "Actual handoff_hash:   $actual_hash" >&2
    echo "Next: rerun comet-handoff.sh so Superpowers receives the current OpenSpec context." >&2
    return 1
  fi

  markdown="${context%.json}.md"
  if [ ! -s "$markdown" ]; then
    echo "design handoff markdown is missing or empty: $markdown" >&2
    echo "Next: regenerate the design handoff with comet-handoff.sh." >&2
    return 1
  fi
}

design_handoff_markdown_traceable() {
  local context markdown missing=0
  context=$(yaml_field_value "handoff_context" 2>/dev/null || true)
  if [ -z "$context" ] || [ "$context" = "null" ]; then
    echo "handoff_context is missing from .comet.yaml" >&2
    return 1
  fi
  markdown="${context%.json}.md"
  if [ ! -s "$markdown" ]; then
    echo "design handoff markdown is missing or empty: $markdown" >&2
    return 1
  fi
  grep -q '^Generated-by: comet-handoff\.sh$' "$markdown" || {
    echo "handoff markdown is missing Generated-by marker" >&2
    missing=1
  }
  grep -Eq '^- Mode: (compact|full|beta)$' "$markdown" || {
    echo "handoff markdown is missing Mode marker" >&2
    missing=1
  }
  handoff_source_files | while IFS= read -r file; do
    [ -f "$file" ] || continue
    if ! grep -q "^- Source: $file$" "$markdown"; then
      echo "handoff markdown is missing source reference: $file" >&2
      exit 2
    fi
    if ! grep -q "^- SHA256: $(hash_file "$file")$" "$markdown"; then
      echo "handoff markdown is missing current sha256 for: $file" >&2
      exit 2
    fi
  done || missing=1

  [ "$missing" -eq 0 ]
}

context_compression_mode() {
  local mode
  mode=$(yaml_field_value "context_compression" 2>/dev/null || true)
  printf '%s\n' "${mode:-off}"
}

handoff_context_matches_mode() {
  local context mode expected_json expected_md markdown
  context=$(yaml_field_value "handoff_context" 2>/dev/null || true)
  mode=$(context_compression_mode)

  if [ -z "$context" ] || [ "$context" = "null" ]; then
    echo "handoff_context is missing from .comet.yaml" >&2
    return 1
  fi

  case "$mode" in
    beta)
      expected_json="spec-context.json"
      expected_md="spec-context.md"
      ;;
    off)
      expected_json="design-context.json"
      expected_md="design-context.md"
      ;;
    *)
      echo "invalid context_compression mode: $mode" >&2
      return 1
      ;;
  esac

  if [ "$(basename "$context")" != "$expected_json" ]; then
    echo "handoff_context does not match context_compression=$mode: expected $expected_json, got $(basename "$context")" >&2
    echo "Next: rerun comet-handoff.sh so the handoff package matches the current compression mode." >&2
    return 1
  fi

  markdown="${context%.json}.md"
  if [ "$(basename "$markdown")" != "$expected_md" ]; then
    echo "handoff markdown does not match context_compression=$mode: expected $expected_md, got $(basename "$markdown")" >&2
    echo "Next: rerun comet-handoff.sh so the handoff package matches the current compression mode." >&2
    return 1
  fi
}

beta_spec_json_structurally_valid() {
  local context missing=0
  if [ "$(context_compression_mode)" != "beta" ]; then
    return 0
  fi

  context=$(yaml_field_value "handoff_context" 2>/dev/null || true)
  if [ -z "$context" ] || [ "$context" = "null" ]; then
    echo "handoff_context is missing from .comet.yaml" >&2
    return 1
  fi
  if [ ! -s "$context" ]; then
    echo "spec-context.json is missing or empty: $context" >&2
    return 1
  fi

  # Validate required JSON fields
  grep -q '"change"' "$context" || { echo "spec-context.json missing 'change' field" >&2; return 1; }
  grep -q '"phase"' "$context" || { echo "spec-context.json missing 'phase' field" >&2; return 1; }
  grep -q '"mode": "beta"' "$context" || { echo "spec-context.json mode is not beta" >&2; return 1; }
  grep -q '"files"' "$context" || { echo "spec-context.json missing 'files' field" >&2; return 1; }
  grep -q '"context_hash"' "$context" || { echo "spec-context.json missing 'context_hash' field" >&2; return 1; }

  # Verify all source files are referenced in the JSON
  handoff_source_files | while IFS= read -r file; do
    [ -f "$file" ] || continue
    if ! grep -qF "$file" "$context"; then
      echo "spec-context.json missing source file reference: $file" >&2
      exit 2
    fi
  done || missing=1

  [ "$missing" -eq 0 ]
}

design_doc_frontmatter_has() {
  local design_doc="$1"
  local field="$2"
  local expected="$3"
  awk '
    {
      line = $0
      sub(/^\357\273\277/, "", line)
    }
    !in_fm && line == "---" { in_fm = 1; next }
    in_fm && line == "---" { exit }
    in_fm { print line }
  ' "$design_doc" | grep -Eq "^${field}: ['\"]?${expected}['\"]?[[:space:]]*$"
}

design_doc_links_current_change() {
  local design_doc
  design_doc=$(yaml_field_value "design_doc" 2>/dev/null || true)
  if [ -z "$design_doc" ] || [ "$design_doc" = "null" ] || [ ! -s "$design_doc" ]; then
    echo "design_doc must point to an existing Superpowers Design Doc before leaving design." >&2
    return 1
  fi
  design_doc_frontmatter_has "$design_doc" "comet_change" "$CHANGE"
}

design_doc_declares_technical_role() {
  local design_doc
  design_doc=$(yaml_field_value "design_doc" 2>/dev/null || true)
  [ -n "$design_doc" ] && [ "$design_doc" != "null" ] && [ -s "$design_doc" ] &&
    design_doc_frontmatter_has "$design_doc" "role" "technical-design"
}

design_doc_declares_canonical_spec() {
  local design_doc
  design_doc=$(yaml_field_value "design_doc" 2>/dev/null || true)
  [ -n "$design_doc" ] && [ "$design_doc" != "null" ] && [ -s "$design_doc" ] &&
    design_doc_frontmatter_has "$design_doc" "canonical_spec" "openspec"
}

archived_is_true() {
  local val
  val=$(yaml_field_value "archived" 2>/dev/null || true)
  [ "$val" = "true" ]
}

# --- Phase-specific checks ---

guard_open() {
  echo "=== Guard: open → next ===" >&2

  local workflow
  workflow=$(yaml_field_value "workflow" 2>/dev/null || true)

  check "proposal.md exists and non-empty" file_nonempty "$CHANGE_DIR/proposal.md"
  if [ "$workflow" = "full" ]; then
    check "design.md exists and non-empty" file_nonempty "$CHANGE_DIR/design.md"
  fi
  check "tasks.md exists and non-empty" file_nonempty "$CHANGE_DIR/tasks.md"
  check "tasks.md has at least one task" tasks_has_any
}

guard_design() {
  echo "=== Guard: design → build ===" >&2

  local design_doc workflow
  design_doc=$(yaml_field_value "design_doc" 2>/dev/null || true)
  workflow=$(yaml_field_value "workflow" 2>/dev/null || true)

  check "proposal.md exists" file_nonempty "$CHANGE_DIR/proposal.md"
  check "design.md exists" file_nonempty "$CHANGE_DIR/design.md"
  check "tasks.md exists" file_nonempty "$CHANGE_DIR/tasks.md"
  check "design handoff context exists" design_handoff_context_valid
  check "design handoff matches compression mode" handoff_context_matches_mode
  check "design handoff markdown is traceable" design_handoff_markdown_traceable
  if [ "$(context_compression_mode)" = "beta" ]; then
    check "beta spec-context.json is structurally valid" beta_spec_json_structurally_valid
  fi

  if [ "$workflow" = "full" ]; then
    # Full workflow: design_doc is REQUIRED
    check "design_doc is recorded for full workflow" design_doc_recorded
  fi

  if [ -n "$design_doc" ] && [ "$design_doc" != "null" ]; then
    check "Design Doc ($design_doc) exists" file_nonempty "$design_doc"
    check "Design Doc frontmatter links current change" design_doc_links_current_change
    check "Design Doc declares technical design role" design_doc_declares_technical_role
    check "Design Doc declares OpenSpec as canonical spec" design_doc_declares_canonical_spec
  elif [ "$workflow" != "full" ]; then
    warn "  [WARN] No design_doc recorded in .comet.yaml (optional for hotfix/tweak)"
  fi
}

design_doc_recorded() {
  local design_doc
  design_doc=$(yaml_field_value "design_doc" 2>/dev/null || true)
  if [ -n "$design_doc" ] && [ "$design_doc" != "null" ] && [ -f "$design_doc" ]; then
    return 0
  fi
  echo "design_doc must point to an existing Superpowers Design Doc for full workflow before leaving design." >&2
  echo "Next: create the Design Doc and run: \"\$COMET_BASH\" \"\$COMET_STATE\" set $CHANGE design_doc <path>" >&2
  return 1
}

guard_build() {
  echo "=== Guard: build → verify ===" >&2

  check "isolation selected" isolation_selected
  check "build_mode selected" build_mode_selected
  check "build_mode allowed for workflow" build_mode_allowed_for_workflow
  check "subagent dispatch confirmed" subagent_dispatch_confirmed
  check "tdd_mode selected" tdd_mode_selected
  check "review_mode selected" review_mode_selected
  check "tasks.md all tasks checked" tasks_all_done
  check "Superpowers plan all tasks checked" plan_tasks_all_done
  check "proposal.md exists" file_nonempty "$CHANGE_DIR/proposal.md"
  check "Build passes" build_passes
}

guard_verify() {
  echo "=== Guard: verify → archive ===" >&2

  check "tasks.md all tasks checked" tasks_all_done
  check "Build passes" verification_command_passes
  check "verification_report exists" verification_report_exists
  check "branch_status=handled" branch_status_handled
}

guard_archive() {
  echo "=== Guard: archive completeness ===" >&2

  check "archived is true" archived_is_true
  check "proposal.md exists" file_nonempty "$CHANGE_DIR/proposal.md"
  check "design.md exists" file_nonempty "$CHANGE_DIR/design.md"
  check "tasks.md all tasks checked" tasks_all_done
}

apply_state_update() {
  local state_sh="$SCRIPT_DIR/comet-state.sh"
  local p="$1"

  if [ -f "$state_sh" ]; then
    case "$p" in
      open)   "$COMET_BASH" "$state_sh" transition "$CHANGE" open-complete ;;
      design) "$COMET_BASH" "$state_sh" transition "$CHANGE" design-complete ;;
      build)  "$COMET_BASH" "$state_sh" transition "$CHANGE" build-complete ;;
      verify) "$COMET_BASH" "$state_sh" transition "$CHANGE" verify-pass ;;
    esac
  else
    red "FATAL: comet-state.sh not found; cannot apply state transition"
    exit 1
  fi
}

# --- Main ---

if [ "${COMET_GUARD_SOURCE_ONLY:-0}" = "1" ]; then
  return 0 2>/dev/null
  # shellcheck disable=SC2317  # unreachable if sourced; fallback for direct execution
  red "ERROR: COMET_GUARD_SOURCE_ONLY=1 is only for sourcing, not direct execution" >&2
  # shellcheck disable=SC2317
  exit 1
fi

case "$PHASE" in
  open)     preflight ; guard_open ;;
  design)   preflight ; guard_design ;;
  build)    preflight ; guard_build ;;
  verify)   preflight ; guard_verify ;;
  archive)  preflight ; guard_archive ;;
  *)
    red "Unknown phase: $PHASE"
    echo "Valid phases: open, design, build, verify, archive" >&2
    exit 1
    ;;
esac

if [ "$BLOCK" -eq 1 ]; then
  echo "" >&2
  red "BLOCKED — fix failing checks before proceeding to next phase"
  exit 1
else
  echo "" >&2
  green "ALL CHECKS PASSED — ready for next phase"
  if [ "$APPLY" -eq 1 ]; then
    apply_state_update "$PHASE"
    case "$PHASE" in
      open)
        new_phase=$(yaml_field_value "phase")
        green "  [APPLY] .comet.yaml updated: phase=$new_phase"
        ;;
      design) green "  [APPLY] .comet.yaml updated: phase=build" ;;
      build)  green "  [APPLY] .comet.yaml updated: phase=verify, verify_result=pending" ;;
      verify) green "  [APPLY] .comet.yaml updated: phase=archive, verify_result=pass" ;;
    esac
  fi
  exit 0
fi
__COMET_ASSETS_SKILLS_COMET_SCRIPTS_COMET_GUARD_SH__
chmod +x "$TARGET_DIR/assets/skills/comet/scripts/comet-guard.sh"

cat > "$TARGET_DIR/assets/skills/comet/scripts/comet-handoff.sh" <<'__COMET_ASSETS_SKILLS_COMET_SCRIPTS_COMET_HANDOFF_SH__'
#!/bin/bash
# Comet Handoff — creates machine-owned context packages between phases
# Usage: comet-handoff.sh <change-name> design --write [--full]
#        comet-handoff.sh <change-name> --hash-only

set -euo pipefail

COMET_BASH="${COMET_BASH:-${BASH:-bash}}"

red() { echo -e "\033[31m$1\033[0m" >&2; }
green() { echo -e "\033[32m$1\033[0m" >&2; }
warn() { echo -e "\033[33m$1\033[0m" >&2; }

validate_change_name() {
  local name="$1"
  if [ -z "$name" ]; then
    red "ERROR: Change name cannot be empty"
    exit 1
  fi
  if [[ ! "$name" =~ ^[a-zA-Z0-9_-]+$ ]]; then
    red "ERROR: Invalid change name: '$name'"
    red "Valid characters: a-z, A-Z, 0-9, -, _"
    exit 1
  fi
  if [[ "$name" =~ \.\. ]]; then
    red "ERROR: Change name cannot contain '..' (path traversal not allowed)"
    exit 1
  fi
}

strip_wrapping_quotes() {
  local value="$1"
  case "$value" in
    \"*\") printf '%s\n' "${value:1:${#value}-2}" ;;
    \'*\') printf '%s\n' "${value:1:${#value}-2}" ;;
    *) printf '%s\n' "$value" ;;
  esac
}

strip_inline_comment() {
  local value="$1"
  printf '%s\n' "$value" | awk -v squote="'" '
    {
      out = ""
      quote = ""
      for (i = 1; i <= length($0); i++) {
        c = substr($0, i, 1)
        if (quote == "") {
          if (c == "\"" || c == squote) {
            quote = c
          } else if (c == "#" && (i == 1 || substr($0, i - 1, 1) ~ /[[:space:]]/)) {
            sub(/[[:space:]]+$/, "", out)
            print out
            next
          }
        } else if (c == quote) {
          quote = ""
        }
        out = out c
      }
      print out
    }
  '
}

yaml_field_value() {
  local field="$1"
  local yaml="$CHANGE_DIR/.comet.yaml"
  local value
  value=$(grep "^${field}:" "$yaml" 2>/dev/null | sed "s/^${field}: *//" || true)
  value=$(strip_inline_comment "$value")
  strip_wrapping_quotes "$value"
}

hash_stream() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum | awk '{print $1}'
  elif command -v shasum >/dev/null 2>&1; then
    shasum -a 256 | awk '{print $1}'
  else
    red "ERROR: sha256sum or shasum is required"
    exit 1
  fi
}

hash_file() {
  local file="$1"
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$file" | awk '{print $1}'
  elif command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$file" | awk '{print $1}'
  else
    red "ERROR: sha256sum or shasum is required"
    exit 1
  fi
}

source_files() {
  printf '%s\n' "$CHANGE_DIR/proposal.md"
  printf '%s\n' "$CHANGE_DIR/design.md"
  printf '%s\n' "$CHANGE_DIR/tasks.md"
  if [ -d "$CHANGE_DIR/specs" ]; then
    find "$CHANGE_DIR/specs" -path '*/spec.md' -type f 2>/dev/null | sort
  fi
}

compute_context_hash() {
  local hash_input
  hash_input=$(source_files | while IFS= read -r file; do
    if [ -f "$file" ]; then
      printf 'path:%s\n' "$file"
      printf 'sha256:%s\n' "$(hash_file "$file")"
    fi
  done)
  printf '%s' "$hash_input" | hash_stream
}

json_escape() {
  printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'
}

file_line_count() {
  local file="$1"
  wc -l < "$file" | tr -d ' '
}

write_file_excerpt() {
  local file="$1"
  local max_lines="$2"
  local total_lines
  total_lines=$(file_line_count "$file")

  echo "## $file"
  echo ""
  echo "- Source: $file"
  echo "- Lines: 1-$total_lines"
  echo "- SHA256: $(hash_file "$file")"
  echo ""

  if [ "$HANDOFF_MODE" = "full" ] || [ "$total_lines" -le "$max_lines" ]; then
    echo '```md'
    cat "$file"
    echo '```'
  else
    echo "[TRUNCATED]"
    echo ""
    echo '```md'
    sed -n "1,${max_lines}p" "$file"
    echo '```'
    echo ""
    echo "Full source: $file"
  fi
  echo ""
}

write_markdown_context() {
  local output="$1"
  {
    echo "# Comet Design Handoff"
    echo ""
    echo "- Change: $CHANGE"
    echo "- Phase: design"
    echo "- Mode: $HANDOFF_MODE"
    echo "- Context hash: $CONTEXT_HASH"
    echo ""
    echo "Generated-by: comet-handoff.sh"
    echo ""
    echo "OpenSpec remains the canonical capability spec. This handoff is a deterministic, source-traceable context pack, not an agent-authored summary."
    echo ""
    source_files | while IFS= read -r file; do
      [ -f "$file" ] || continue
      write_file_excerpt "$file" 80
    done
  } > "$output"
}

write_json_context() {
  local output="$1"
  {
    echo "{"
    echo "  \"change\": \"$(json_escape "$CHANGE")\","
    echo "  \"phase\": \"design\","
    echo "  \"mode\": \"$HANDOFF_MODE\","
    echo "  \"canonical_spec\": \"openspec\","
    echo "  \"generated_by\": \"comet-handoff.sh\","
    echo "  \"context_hash\": \"$CONTEXT_HASH\","
    echo "  \"files\": ["
    local first=1
    while IFS= read -r file; do
      [ -f "$file" ] || continue
      if [ "$first" -eq 0 ]; then
        echo ","
      fi
      first=0
      printf '    { "path": "%s", "sha256": "%s" }' "$(json_escape "$file")" "$(hash_file "$file")"
    done < <(source_files)
    echo ""
    echo "  ]"
    echo "}"
  } > "$output"
}

write_spec_projection_for_file() {
  local file="$1"
  echo "## $file"
  echo ""
  echo "- Source: $file"
  echo "- Lines: 1-$(file_line_count "$file")"
  echo "- SHA256: $(hash_file "$file")"
  echo ""
  echo '```md'
  cat "$file"
  echo '```'
  echo ""
}

write_spec_markdown_context() {
  local output="$1"
  {
    echo "# Comet Spec Context"
    echo ""
    echo "- Change: $CHANGE"
    echo "- Phase: design"
    echo "- Mode: beta"
    echo "- Context hash: $CONTEXT_HASH"
    echo ""
    echo "Generated-by: comet-handoff.sh"
    echo ""
    echo "OpenSpec remains the canonical capability spec. This beta context pack verbatim-projects spec files and references supporting artifacts by hash, not an agent-authored summary."
    echo ""
    echo "## Source References"
    echo ""
    source_files | while IFS= read -r file; do
      [ -f "$file" ] || continue
      echo "- Source: $file"
      echo "- SHA256: $(hash_file "$file")"
    done
    echo ""
    echo "## Acceptance Projection"
    echo ""
    if [ -d "$CHANGE_DIR/specs" ]; then
      find "$CHANGE_DIR/specs" -path '*/spec.md' -type f 2>/dev/null | sort | while IFS= read -r file; do
        write_spec_projection_for_file "$file"
      done
    else
      echo "No delta spec files found."
      echo ""
    fi
    echo "Full source files remain canonical. If a required heading or scenario is missing here, regenerate the handoff or read the source spec directly. Supporting files (proposal, design, tasks) are referenced by hash only."
  } > "$output"
}

write_spec_json_context() {
  local output="$1"
  {
    echo "{"
    echo "  \"change\": \"$(json_escape "$CHANGE")\","
    echo "  \"phase\": \"design\","
    echo "  \"mode\": \"beta\","
    echo "  \"canonical_spec\": \"openspec\","
    echo "  \"generated_by\": \"comet-handoff.sh\","
    echo "  \"context_hash\": \"$CONTEXT_HASH\","
    echo "  \"files\": ["
    local first_file=1
    while IFS= read -r file; do
      [ -f "$file" ] || continue
      local role="supporting"
      case "$file" in
        */specs/*/spec.md) role="spec" ;;
      esac
      if [ "$first_file" -eq 0 ]; then
        echo ","
      fi
      first_file=0
      printf '    { "path": "%s", "sha256": "%s", "role": "%s" }' "$(json_escape "$file")" "$(hash_file "$file")" "$role"
    done < <(source_files)
    echo ""
    echo "  ]"
    echo "}"
  } > "$output"
}

CHANGE="${1:-}"
PHASE="${2:-}"
MODE="${3:-}"
FULL_FLAG="${4:-}"

validate_change_name "$CHANGE"

# --hash-only: compute and output context hash without generating handoff files
if [ "${PHASE:-}" = "--hash-only" ]; then
  CHANGE_DIR="openspec/changes/$CHANGE"
  if [ ! -d "$CHANGE_DIR" ]; then
    red "ERROR: change directory not found: $CHANGE_DIR"
    exit 1
  fi
  for required in proposal.md design.md tasks.md; do
    if [ ! -s "$CHANGE_DIR/$required" ]; then
      red "ERROR: required file missing or empty: $CHANGE_DIR/$required"
      exit 1
    fi
  done
  CONTEXT_HASH="$(compute_context_hash)"
  printf '%s
' "$CONTEXT_HASH"
  exit 0
fi

if [ "$PHASE" != "design" ] || [ "$MODE" != "--write" ]; then
  red "Usage: comet-handoff.sh <change-name> design --write [--full]"
  exit 1
fi
case "$FULL_FLAG" in
  "") HANDOFF_MODE="compact" ;;
  --full) HANDOFF_MODE="full" ;;
  *)
    red "Usage: comet-handoff.sh <change-name> design --write [--full]"
    exit 1
    ;;
esac

CHANGE_DIR="openspec/changes/$CHANGE"
YAML="$CHANGE_DIR/.comet.yaml"
SCRIPT_DIR="$(dirname "$(readlink -f "$0" 2>/dev/null || echo "$0")" 2>/dev/null || dirname "$0")"
STATE_SH="$SCRIPT_DIR/comet-state.sh"

if [ ! -d "$CHANGE_DIR" ]; then
  red "ERROR: change directory not found: $CHANGE_DIR"
  exit 1
fi
if [ ! -f "$YAML" ]; then
  red "ERROR: .comet.yaml not found at $YAML"
  exit 1
fi
if [ "$(yaml_field_value phase)" != "design" ]; then
  red "ERROR: design handoff requires phase: design"
  exit 1
fi

for required in proposal.md design.md tasks.md; do
  if [ ! -s "$CHANGE_DIR/$required" ]; then
    red "ERROR: required OpenSpec artifact missing or empty: $CHANGE_DIR/$required"
    exit 1
  fi
done

HANDOFF_DIR="$CHANGE_DIR/.comet/handoff"
CONTEXT_COMPRESSION="$(yaml_field_value context_compression 2>/dev/null || true)"
CONTEXT_COMPRESSION="${CONTEXT_COMPRESSION:-off}"
case "$CONTEXT_COMPRESSION" in
  off)
    CONTEXT_JSON="$HANDOFF_DIR/design-context.json"
    CONTEXT_MD="$HANDOFF_DIR/design-context.md"
    ;;
  beta)
    if [ "$HANDOFF_MODE" = "full" ]; then
      warn "[HANDOFF] --full is ignored in beta mode; spec files are projected verbatim"
    fi
    HANDOFF_MODE="beta"
    CONTEXT_JSON="$HANDOFF_DIR/spec-context.json"
    CONTEXT_MD="$HANDOFF_DIR/spec-context.md"
    ;;
  *)
    red "ERROR: invalid context_compression: $CONTEXT_COMPRESSION"
    red "Valid values: off, beta"
    exit 1
    ;;
esac
mkdir -p "$HANDOFF_DIR"

CONTEXT_HASH="$(compute_context_hash)"
if [ "$CONTEXT_COMPRESSION" = "beta" ]; then
  write_spec_markdown_context "$CONTEXT_MD"
  write_spec_json_context "$CONTEXT_JSON"
else
  write_markdown_context "$CONTEXT_MD"
  write_json_context "$CONTEXT_JSON"
fi

if [ -x "$STATE_SH" ] || [ -f "$STATE_SH" ]; then
  "$COMET_BASH" "$STATE_SH" set "$CHANGE" handoff_context "$CONTEXT_JSON" >/dev/null
  "$COMET_BASH" "$STATE_SH" set "$CHANGE" handoff_hash "$CONTEXT_HASH" >/dev/null
else
  red "ERROR: comet-state.sh not found; cannot record handoff fields"
  exit 1
fi

green "[HANDOFF] wrote $CONTEXT_JSON"
green "[HANDOFF] wrote $CONTEXT_MD"
green "[HANDOFF] handoff_hash=$CONTEXT_HASH"
__COMET_ASSETS_SKILLS_COMET_SCRIPTS_COMET_HANDOFF_SH__
chmod +x "$TARGET_DIR/assets/skills/comet/scripts/comet-handoff.sh"

cat > "$TARGET_DIR/assets/skills/comet/scripts/comet-hook-guard.sh" <<'__COMET_ASSETS_SKILLS_COMET_SCRIPTS_COMET_HOOK_GUARD_SH__'
#!/bin/bash
# comet-hook-guard.sh — PreToolUse hook for Comet phase enforcement
#
# Blocks file writes (Write/Edit) when the active Comet change is in
# a phase that does not allow source code modifications (open/design/archive).
#
# Usage (called by harness, not directly):
#   PreToolUse matcher "Write|Edit" → this script
#   Stdin:  JSON  {"tool_name":"Write|Edit","tool_input":{"file_path":"..."}}
#   Exit 0  = allow
#   Exit 2  = blocked (stderr message shown to user)
#
# Cross-platform: macOS / Linux / Windows Git Bash
# shellcheck disable=SC2329

set -euo pipefail

TARGET=""

if [ -n "${FILE_PATH:-}" ]; then
  TARGET="$FILE_PATH"
fi

if [ -z "$TARGET" ]; then
  INPUT=""
  if [ ! -t 0 ]; then
    INPUT=$(cat 2>/dev/null || true)
  fi
  if [ -n "$INPUT" ]; then
    TARGET=$(printf '%s' "$INPUT" \
      | grep -oE '"file_path"[[:space:]]*:[[:space:]]*"[^"]*"' 2>/dev/null \
      | head -1 \
      | sed 's/^"file_path"[[:space:]]*:[[:space:]]*"//' \
      | sed 's/"$//' \
      || true)
  fi
fi

if [ -z "$TARGET" ]; then
  echo "[COMET-HOOK] allowed: no file path in tool input" >&2
  exit 0
fi

TARGET=$(printf '%s' "$TARGET" | sed 's|\\|/|g' | sed 's|///*|/|g')

norm() { printf '%s' "$1" | sed 's|\\|/|g'; }

RELPATH=$(norm "$TARGET")

case "$RELPATH" in
  /*|[A-Za-z]:/*)
    CWD_UNIX=$(norm "$(pwd)")
    CWD_PHYS=$(norm "$(pwd -P 2>/dev/null || pwd)")

    if [ "${RELPATH#"$CWD_UNIX"/}" != "$RELPATH" ]; then
      RELPATH="${RELPATH#"$CWD_UNIX"/}"
    elif [ "${RELPATH#"$CWD_PHYS"/}" != "$RELPATH" ]; then
      RELPATH="${RELPATH#"$CWD_PHYS"/}"
    else
      _PDIR=$(cd "$(dirname "$TARGET")" 2>/dev/null && pwd -P 2>/dev/null || true)
      if [ -n "$_PDIR" ]; then
        _TRESOLVED=$(norm "${_PDIR}/$(basename "$TARGET")")
        if [ "${_TRESOLVED#"$CWD_UNIX"/}" != "$_TRESOLVED" ]; then
          RELPATH="${_TRESOLVED#"$CWD_UNIX"/}"
        elif [ "${_TRESOLVED#"$CWD_PHYS"/}" != "$_TRESOLVED" ]; then
          RELPATH="${_TRESOLVED#"$CWD_PHYS"/}"
        fi
      fi
    fi
    ;;
esac

is_archived() {
  grep "^archived:" "$1" 2>/dev/null \
    | awk '{print $2}' | tr -d '[:space:][:cntrl:]' || true
}

read_phase() {
  grep "^phase:" "$1" 2>/dev/null \
    | awk '{print $2}' | tr -d '[:space:][:cntrl:]' || true
}

read_field() {
  grep "^$1:" "$2" 2>/dev/null \
    | head -1 | awk '{print $2}' | tr -d '[:space:][:cntrl:]' || true
}

PHASE=""
GOV_YAML=""

case "$RELPATH" in
  openspec/changes/*/*)
    _rest="${RELPATH#openspec/changes/}"
    _own_change="${_rest%%/*}"
    if [ -n "$_own_change" ] && [ "$_own_change" != "archive" ]; then
      _own_yaml="openspec/changes/${_own_change}/.comet.yaml"
      if [ -f "$_own_yaml" ]; then
        if [ "$(is_archived "$_own_yaml")" = "true" ]; then
          echo "[COMET-HOOK] allowed: $RELPATH (own change archived)" >&2
          exit 0
        fi
        PHASE=$(read_phase "$_own_yaml")
        GOV_YAML="$_own_yaml"
      else
        PHASE="open"
      fi
    fi
    ;;
esac

if [ -z "$PHASE" ]; then
  YAML_FILE=""
  if [ -d "openspec/changes" ]; then
    for dir in openspec/changes/*/; do
      [ -d "$dir" ] || continue
      case "$dir" in
        */archive/*) continue ;;
      esac
      if [ -f "${dir}.comet.yaml" ]; then
        if [ "$(is_archived "${dir}.comet.yaml")" = "true" ]; then
          continue
        fi
        YAML_FILE="${dir}.comet.yaml"
        break
      fi
    done
  fi

  if [ -z "$YAML_FILE" ]; then
    echo "[COMET-HOOK] allowed: no active comet change" >&2
    exit 0
  fi

  PHASE=$(read_phase "$YAML_FILE")
  GOV_YAML="$YAML_FILE"
fi

if [ -z "$PHASE" ]; then
  echo "[COMET-HOOK] allowed: no phase in .comet.yaml" >&2
  exit 0
fi

case "$RELPATH" in
  openspec/*)
    case "$PHASE" in
      open)
        case "$RELPATH" in
          */proposal.md|*/design.md|*/tasks.md|*/.openspec.yaml|*/.comet.yaml|*/.comet/*|*/specs/*)
            echo "[COMET-HOOK] allowed: $RELPATH (phase: open, openspec artifacts)" >&2
            exit 0
            ;;
        esac
        ;;
      design)
        case "$RELPATH" in
          */proposal.md|*/design.md|*/tasks.md|*/.comet/*|*/specs/*|*/.comet.yaml|*/.openspec.yaml)
            echo "[COMET-HOOK] allowed: $RELPATH (phase: design, handoff/spec)" >&2
            exit 0
            ;;
        esac
        ;;
      build)
        case "$RELPATH" in
          */specs/*|*/tasks.md|*/.comet.yaml|*/.openspec.yaml)
            echo "[COMET-HOOK] allowed: $RELPATH (phase: build, spec/tasks)" >&2
            exit 0
            ;;
        esac
        ;;
      verify)
        case "$RELPATH" in
          */tasks.md|*/.comet.yaml|*/.openspec.yaml)
            echo "[COMET-HOOK] allowed: $RELPATH (phase: verify, tasks/state)" >&2
            exit 0
            ;;
        esac
        ;;
      archive)
        case "$RELPATH" in
          */.comet.yaml|*/.openspec.yaml)
            echo "[COMET-HOOK] allowed: $RELPATH (phase: archive, state)" >&2
            exit 0
            ;;
        esac
        ;;
    esac
    ;;
  docs/superpowers/*)
    case "$PHASE" in
      design|build|verify)
        echo "[COMET-HOOK] allowed: $RELPATH (phase: $PHASE, superpowers)" >&2
        exit 0
        ;;
    esac
    ;;
  .comet/*|*/.comet/*)
    echo "[COMET-HOOK] allowed: $RELPATH (whitelist: comet config)" >&2
    exit 0
    ;;
  .claude/*)
    echo "[COMET-HOOK] allowed: $RELPATH (whitelist: claude config)" >&2
    exit 0
    ;;
  CLAUDE.md|CHANGELOG.md|README.md|*.md)
    case "$RELPATH" in
      */*) ;;
      *)
        echo "[COMET-HOOK] allowed: $RELPATH (whitelist: root markdown)" >&2
        exit 0
        ;;
    esac
    ;;
  .comet.yaml|comet.yaml|.comet.yml|comet.yml)
    echo "[COMET-HOOK] allowed: $RELPATH (whitelist: comet config)" >&2
    exit 0
    ;;
esac

case "$PHASE" in
  build|verify)
    if [ -n "$GOV_YAML" ]; then
      _wf=$(read_field "workflow" "$GOV_YAML")
      _dd=$(read_field "design_doc" "$GOV_YAML")
      if [ "$_wf" = "full" ] && { [ -z "$_dd" ] || [ "$_dd" = "null" ]; }; then
        echo "" >&2
        echo "╔══════════════════════════════════════════╗" >&2
        echo "║     COMET PHASE GUARD — WRITE BLOCKED    ║" >&2
        echo "╚══════════════════════════════════════════╝" >&2
        echo "" >&2
        echo "  Current phase: $PHASE (workflow: full), but design_doc is empty" >&2
        echo "  Target file: $RELPATH" >&2
        echo "" >&2
        echo "  ❌ Illegal phase jump detected: full workflow entered $PHASE without a Design Doc" >&2
        echo "  ✅ Correct flow: create the Design Doc in design phase, then run comet-guard design --apply" >&2
        echo "  💡 Run /comet-design to fill the missing design; for repair, set design_doc with comet-state" >&2
        echo "" >&2
        exit 2
      fi
    fi
    echo "[COMET-HOOK] allowed: $RELPATH (phase: $PHASE)" >&2
    exit 0
    ;;
  open|design|archive)
    echo "" >&2
    echo "╔══════════════════════════════════════════╗" >&2
    echo "║     COMET PHASE GUARD — WRITE BLOCKED    ║" >&2
    echo "╚══════════════════════════════════════════╝" >&2
    echo "" >&2
    echo "  Current phase: $PHASE" >&2
    echo "  Target file: $RELPATH" >&2
    echo "" >&2
    case "$PHASE" in
      open)
        echo "  ❌ open phase does not allow source code writes" >&2
        echo "  ✅ Allowed: create proposal/design/tasks and run guard" >&2
        echo "  💡 After clarification and artifact creation, run guard --apply" >&2
        ;;
      design)
        echo "  ❌ design phase does not allow source code writes" >&2
        echo "  ✅ Allowed: brainstorming, create the Design Doc, and run guard" >&2
        echo "  💡 After the Design Doc is ready, run comet-guard design --apply to enter build" >&2
        ;;
      archive)
        echo "  ❌ archive phase does not allow source code writes" >&2
        echo "  ✅ Allowed: confirm archive intent and run the archive script" >&2
        ;;
    esac
    echo "" >&2
    exit 2
    ;;
esac

echo "[COMET-HOOK] allowed: $RELPATH (phase: $PHASE)" >&2
exit 0
__COMET_ASSETS_SKILLS_COMET_SCRIPTS_COMET_HOOK_GUARD_SH__
chmod +x "$TARGET_DIR/assets/skills/comet/scripts/comet-hook-guard.sh"

cat > "$TARGET_DIR/assets/skills/comet/scripts/comet-state.sh" <<'__COMET_ASSETS_SKILLS_COMET_SCRIPTS_COMET_STATE_SH__'
#!/bin/bash
# Comet State — unified interface for .comet.yaml state management
# Usage: comet-state.sh <subcommand> <change-name> [args...]
#
# Subcommands:
#   init <change-name> <workflow>  — Initialize .comet.yaml with workflow defaults
#   get <change-name> <field>       — Read a field value from .comet.yaml
#   set <change-name> <field> <val> — Update a field value
#   transition <change-name> <event> — Apply a validated state transition
#   check <change-name> <phase>    — Verify entry requirements for a phase
#   check <change-name> <phase> --recover — Output structured recovery context for compaction resume
#   scale <change-name>             — Assess and set verification mode based on metrics
#   task-checkoff <file> <task-text> — Verify one unique task is checked
#
# Workflows: full, hotfix, tweak
# Phases for check: open, design, build, verify, archive

set -euo pipefail

# --- Color output helpers ---

red() { echo -e "\033[31m$1\033[0m" >&2; }
green() { echo -e "\033[32m$1\033[0m" >&2; }
yellow() { echo -e "\033[33m$1\033[0m" >&2; }

# --- Script location ---

# shellcheck disable=SC2034
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# --- Input validation ---

validate_change_name() {
  local name="$1"
  # Reject empty names
  if [ -z "$name" ]; then
    red "ERROR: Change name cannot be empty" >&2
    exit 1
  fi
  # Only allow alphanumeric, hyphens, and underscores
  if [[ ! "$name" =~ ^[a-zA-Z0-9_-]+$ ]]; then
    red "ERROR: Invalid change name: '$name'" >&2
    red "Valid characters: a-z, A-Z, 0-9, -, _" >&2
    exit 1
  fi
  # Reject path traversal attempts
  if [[ "$name" =~ \.\. ]]; then
    red "ERROR: Change name cannot contain '..' (path traversal not allowed)" >&2
    exit 1
  fi
}

validate_enum() {
  local value="$1"
  shift
  local valid_values=("$@")

  for valid in "${valid_values[@]}"; do
    if [ "$value" = "$valid" ]; then
      return 0
    fi
  done

  red "ERROR: Invalid value: '$value'" >&2
  red "Valid values: ${valid_values[*]}" >&2
  exit 1
}

validate_path_field() {
  local value="$1"
  local field="$2"
  # null and empty are acceptable (means "not set")
  if [ -z "$value" ] || [ "$value" = "null" ]; then
    return 0
  fi
  # Reject absolute paths and home-directory references
  case "$value" in
    /*|~*|[A-Za-z]:*|\\*)
      red "ERROR: $field must be a relative path within the repo: '$value'" >&2
      exit 1
      ;;
  esac
  if [[ "$value" =~ \.\. ]]; then
    red "ERROR: $field cannot contain '..' (path traversal not allowed): '$value'" >&2
    exit 1
  fi
}

# --- Helper functions ---

yaml_field() {
  local field="$1"
  local yaml_file="$2"
  if [ -f "$yaml_file" ]; then
    local value
    value=$(grep "^${field}:" "$yaml_file" 2>/dev/null | sed "s/^${field}: *//" || true)
    value=$(strip_inline_comment "$value")
    strip_wrapping_quotes "$value"
  fi
}

strip_inline_comment() {
  local value="$1"
  printf '%s\n' "$value" | awk -v squote="'" '
    {
      out = ""
      quote = ""
      for (i = 1; i <= length($0); i++) {
        c = substr($0, i, 1)
        if (quote == "") {
          if (c == "\"" || c == squote) {
            quote = c
          } else if (c == "#" && (i == 1 || substr($0, i - 1, 1) ~ /[[:space:]]/)) {
            sub(/[[:space:]]+$/, "", out)
            print out
            next
          }
        } else if (c == quote) {
          quote = ""
        }
        out = out c
      }
      print out
    }
  '
}

strip_wrapping_quotes() {
  local value="$1"
  case "$value" in
    \"*\")
      printf '%s\n' "${value:1:${#value}-2}"
      ;;
    \'*\')
      printf '%s\n' "${value:1:${#value}-2}"
      ;;
    *)
      printf '%s\n' "$value"
      ;;
  esac
}

replace_yaml_field() {
  local yaml_file="$1"
  local field="$2"
  local value="$3"
  local tmp_file

  tmp_file=$(mktemp)
  chmod 600 "$tmp_file"
  # Replace the target field, then deduplicate all fields keeping only the
  # last occurrence of each key. Prevents stale earlier values from
  # persisting when a field is set multiple times.
  awk -v field="$field" -v value="$value" '
    index($0, field ":") == 1 { $0 = field ": " value }
    { buf[NR] = $0; keys[NR] = $0; sub(/:.*$/, "", keys[NR]); n = NR }
    END {
      for (i = 1; i <= n; i++) last[keys[i]] = i
      for (i = 1; i <= n; i++) if (last[keys[i]] == i) print buf[i]
    }
  ' "$yaml_file" > "$tmp_file"
  mv "$tmp_file" "$yaml_file"
}

file_nonempty() {
  [ -f "$1" ] && [ -s "$1" ]
}

change_dir_for() {
  local change_name="$1"
  if [ -d "openspec/changes/$change_name" ]; then
    echo "openspec/changes/$change_name"
  elif [ -d "openspec/changes/archive/$change_name" ]; then
    echo "openspec/changes/archive/$change_name"
  else
    echo "openspec/changes/$change_name"
  fi
}

yaml_file_for() {
  local change_name="$1"
  local change_dir
  change_dir=$(change_dir_for "$change_name")
  echo "$change_dir/.comet.yaml"
}

project_context_compression() {
  local value="off"
  local source="default"
  if [ -n "${COMET_CONTEXT_COMPRESSION:-}" ]; then
    value="$COMET_CONTEXT_COMPRESSION"
    source="COMET_CONTEXT_COMPRESSION"
  elif [ -f ".comet/config.yaml" ]; then
    value=$(yaml_field "context_compression" ".comet/config.yaml")
    value="${value:-off}"
    source=".comet/config.yaml"
  fi

  case "$value" in
    off|beta)
      printf '%s\n' "$value"
      ;;
    *)
      red "ERROR: Invalid context_compression from ${source}: '$value'" >&2
      red "Valid values: off, beta" >&2
      exit 1
      ;;
  esac
}

project_auto_transition_default() {
  local value="true"
  local source="default"
  if [ -n "${COMET_AUTO_TRANSITION:-}" ]; then
    value="$COMET_AUTO_TRANSITION"
    source="COMET_AUTO_TRANSITION"
  elif [ -f ".comet/config.yaml" ]; then
    local raw
    raw=$(yaml_field "auto_transition" ".comet/config.yaml" 2>/dev/null || true)
    if [ -n "$raw" ]; then
      value="$raw"
      source=".comet/config.yaml"
    fi
  fi

  case "$value" in
    true|false)
      printf '%s\n' "$value"
      ;;
    *)
      red "ERROR: Invalid auto_transition from ${source}: '$value'" >&2
      red "Valid values: true, false" >&2
      exit 1
      ;;
  esac
}

project_review_mode_default() {
  local value="null"
  local source="default"
  if [ -n "${COMET_REVIEW_MODE:-}" ]; then
    value="$COMET_REVIEW_MODE"
    source="COMET_REVIEW_MODE"
  elif [ -f ".comet/config.yaml" ]; then
    local raw
    raw=$(yaml_field "review_mode" ".comet/config.yaml" 2>/dev/null || true)
    if [ -n "$raw" ]; then
      value="$raw"
      source=".comet/config.yaml"
    fi
  fi

  case "$value" in
    null|off|standard|thorough)
      printf '%s\n' "$value"
      ;;
    *)
      red "ERROR: Invalid review_mode from ${source}: '$value'" >&2
      red "Valid values: off, standard, thorough" >&2
      exit 1
      ;;
  esac
}

# --- Subcommands ---

cmd_init() {
  local change_name="$1"
  local workflow="$2"

  validate_change_name "$change_name"
  validate_enum "$workflow" "full" "hotfix" "tweak"

  local change_dir yaml_file
  change_dir=$(change_dir_for "$change_name")
  yaml_file=$(yaml_file_for "$change_name")

  # Check if .comet.yaml already exists
  if [ -f "$yaml_file" ]; then
    red "ERROR: .comet.yaml already exists at $yaml_file"
    exit 1
  fi

  # Create change directory if it doesn't exist
  mkdir -p "$change_dir"

  # Set workflow-appropriate defaults
  local phase build_mode isolation verify_mode context_compression auto_transition review_mode
  phase="open"
  context_compression=$(project_context_compression)
  auto_transition="$(project_auto_transition_default)"

  case "$workflow" in
    full)
      build_mode="null"
      tdd_mode="null"
      review_mode="$(project_review_mode_default)"
      isolation="null"
      verify_mode="null"
      ;;
    hotfix|tweak)
      build_mode="direct"
      tdd_mode="direct"
      review_mode="off"
      isolation="branch"
      verify_mode="light"
      ;;
  esac

  # Write .comet.yaml
  # Record current HEAD as base_ref for scale assessment fallback
  local base_ref="null"
  if git rev-parse --verify HEAD >/dev/null 2>&1; then
    base_ref=$(git rev-parse HEAD 2>/dev/null || echo "null")
  fi

  cat > "$yaml_file" <<EOF
workflow: $workflow
phase: $phase
context_compression: $context_compression
build_mode: $build_mode
build_pause: null
subagent_dispatch: null
tdd_mode: $tdd_mode
review_mode: $review_mode
isolation: $isolation
verify_mode: $verify_mode
auto_transition: $auto_transition
base_ref: $base_ref
design_doc: null
plan: null
verify_result: pending
verification_report: null
branch_status: pending
created_at: $(date -u +%Y-%m-%d)
verified_at: null
archived: false
EOF

  green "Initialized: $yaml_file (workflow=$workflow)"
}

cmd_get() {
  local change_name="$1"
  local field="$2"

  validate_change_name "$change_name"

  local yaml_file
  yaml_file=$(yaml_file_for "$change_name")

  # Check if .comet.yaml exists
  if [ ! -f "$yaml_file" ]; then
    red "ERROR: .comet.yaml not found at $yaml_file"
    exit 1
  fi

  # Read and output the field value
  local value
  value=$(yaml_field "$field" "$yaml_file")
  if [ "$field" = "auto_transition" ] && { [ -z "$value" ] || [ "$value" = "null" ]; }; then
    value="$(project_auto_transition_default)"
  fi
  echo "${value:-}"
}

cmd_set() {
  local change_name="$1"
  local field="$2"
  local value="$3"

  validate_change_name "$change_name"

  local yaml_file
  yaml_file=$(yaml_file_for "$change_name")

  # Check if .comet.yaml exists
  if [ ! -f "$yaml_file" ]; then
    red "ERROR: .comet.yaml not found at $yaml_file"
    exit 1
  fi

  # Validate field name
  case "$field" in
    phase)
      # Direct phase writes bypass state-machine evidence checks (open artifacts,
      # design_doc, build decisions, verification evidence). Block them unless the
      # call originates from cmd_transition (dynamic-scope flag) or the operator
      # explicitly opts into the repair escape hatch.
      if [ "${_COMET_IN_TRANSITION:-}" != "1" ] && [ "${COMET_FORCE_PHASE:-}" != "1" ]; then
        red "ERROR: Setting 'phase' directly is not allowed; it bypasses state machine evidence checks." >&2
        red "  Use: comet-state.sh transition <change-name> <event>" >&2
        red "  Repair-only escape hatch: COMET_FORCE_PHASE=1 comet-state.sh set <change-name> phase <value>" >&2
        exit 1
      fi
      validate_enum "$value" "open" "design" "build" "verify" "archive"
      ;;
    workflow|context_compression|build_mode|build_pause|subagent_dispatch|tdd_mode|review_mode|isolation|verify_mode|auto_transition|verify_result|verification_report|branch_status|archived|design_doc|plan|verified_at|created_at|direct_override|build_command|verify_command|handoff_context|handoff_hash|base_ref)
      # Valid field
      ;;
    *)
      red "ERROR: Unknown field: '$field'" >&2
      red "Valid fields:" >&2
      red "  workflow, phase, context_compression, design_doc, plan, build_mode, build_pause, subagent_dispatch, tdd_mode, review_mode, isolation," >&2
      red "  verify_mode, auto_transition, verify_result, verification_report, branch_status," >&2
      red "  verified_at, created_at, archived, base_ref, direct_override," >&2
      red "  build_command, verify_command, handoff_context, handoff_hash" >&2
      exit 1
      ;;
  esac

  # Validate enum values
  case "$field" in
    workflow)
      validate_enum "$value" "full" "hotfix" "tweak"
      ;;
    context_compression)
      validate_enum "$value" "off" "beta"
      ;;
    phase)
      validate_enum "$value" "open" "design" "build" "verify" "archive"
      ;;
    build_mode)
      validate_enum "$value" "subagent-driven-development" "executing-plans" "direct"
      ;;
    build_pause)
      validate_enum "$value" "null" "plan-ready"
      ;;
    subagent_dispatch)
      validate_enum "$value" "null" "confirmed"
      ;;
    tdd_mode)
      validate_enum "$value" "tdd" "direct"
      ;;
    review_mode)
      validate_enum "$value" "off" "standard" "thorough"
      ;;
    isolation)
      validate_enum "$value" "branch" "worktree"
      ;;
    verify_mode)
      validate_enum "$value" "light" "full"
      ;;
    auto_transition)
      validate_enum "$value" "true" "false"
      ;;
    verify_result)
      validate_enum "$value" "pending" "pass" "fail"
      ;;
    branch_status)
      validate_enum "$value" "pending" "handled"
      ;;
    archived)
      validate_enum "$value" "true" "false"
      ;;
    direct_override)
      validate_enum "$value" "true" "false"
      ;;
    design_doc|plan|verification_report|handoff_context|handoff_hash)
      validate_path_field "$value" "$field"
      ;;
    verified_at|created_at|build_command|verify_command)
      # No validation for date fields or project command strings
      ;;
  esac

  # Write or update the field
  if grep -q "^${field}:" "$yaml_file"; then
    replace_yaml_field "$yaml_file" "$field" "$value"
  else
    # Field doesn't exist, append it
    echo "${field}: ${value}" >> "$yaml_file"
  fi

  green "[SET] ${field}=${value}"
}

require_phase() {
  local change_name="$1"
  local expected="$2"
  local actual
  actual=$(cmd_get "$change_name" "phase")
  if [ "$actual" != "$expected" ]; then
    red "ERROR: Cannot transition '$change_name': expected phase ${expected}, got ${actual}" >&2
    exit 1
  fi
}

require_open_artifacts() {
  local change_name="$1"
  local change_dir workflow f
  change_dir=$(change_dir_for "$change_name")
  workflow=$(cmd_get "$change_name" "workflow")
  for f in proposal.md tasks.md; do
    if [ ! -s "$change_dir/$f" ]; then
      red "ERROR: Cannot transition '$change_name': $f must exist and be non-empty before leaving open" >&2
      exit 1
    fi
  done
  if [ "$workflow" = "full" ] && [ ! -s "$change_dir/design.md" ]; then
    red "ERROR: Cannot transition '$change_name': design.md must exist and be non-empty before leaving open" >&2
    exit 1
  fi
}

require_design_evidence() {
  local change_name="$1"
  local design_doc
  design_doc=$(cmd_get "$change_name" "design_doc")
  if [ -z "$design_doc" ] || [ "$design_doc" = "null" ] || [ ! -s "$design_doc" ]; then
    red "ERROR: Cannot transition '$change_name': design_doc must point to an existing Design Doc before leaving design" >&2
    exit 1
  fi
}

require_verification_evidence() {
  local change_name="$1"
  local report branch_status
  report=$(cmd_get "$change_name" "verification_report")
  branch_status=$(cmd_get "$change_name" "branch_status")

  if [ -z "$report" ] || [ "$report" = "null" ] || [ ! -f "$report" ]; then
    red "ERROR: Cannot transition '$change_name': verification_report must point to an existing report file" >&2
    exit 1
  fi

  if [ "$branch_status" != "handled" ]; then
    red "ERROR: Cannot transition '$change_name': branch_status must be handled" >&2
    exit 1
  fi
}

require_build_decisions() {
  local change_name="$1"
  local workflow build_mode isolation direct_override subagent_dispatch tdd_mode review_mode
  workflow=$(cmd_get "$change_name" "workflow")
  build_mode=$(cmd_get "$change_name" "build_mode")
  isolation=$(cmd_get "$change_name" "isolation")
  direct_override=$(cmd_get "$change_name" "direct_override" 2>/dev/null || true)
  subagent_dispatch=$(cmd_get "$change_name" "subagent_dispatch" 2>/dev/null || true)
  tdd_mode=$(cmd_get "$change_name" "tdd_mode" 2>/dev/null || true)
  review_mode=$(cmd_get "$change_name" "review_mode" 2>/dev/null || true)

  case "$isolation" in
    branch|worktree) ;;
    *)
      red "ERROR: Cannot transition '$change_name': isolation must be branch or worktree, got '${isolation:-null}'" >&2
      exit 1
      ;;
  esac

  case "$build_mode" in
    subagent-driven-development|executing-plans|direct) ;;
    *)
      red "ERROR: Cannot transition '$change_name': build_mode must be selected before leaving build, got '${build_mode:-null}'" >&2
      exit 1
      ;;
  esac

  if [ "$build_mode" = "direct" ] && [ "$workflow" != "hotfix" ] && [ "$workflow" != "tweak" ] && [ "$direct_override" != "true" ]; then
    red "ERROR: Cannot transition '$change_name': build_mode=direct is only allowed for hotfix/tweak unless direct_override=true" >&2
    exit 1
  fi

  if [ "$build_mode" = "subagent-driven-development" ] && [ "$subagent_dispatch" != "confirmed" ]; then
    red "ERROR: Cannot transition '$change_name': subagent_dispatch must be confirmed before using build_mode=subagent-driven-development" >&2
    exit 1
  fi

  if [ "$workflow" = "full" ] && { [ "$tdd_mode" = "null" ] || [ -z "$tdd_mode" ]; }; then
    red "ERROR: Cannot transition '$change_name': tdd_mode must be selected before leaving build (full workflow)" >&2
    exit 1
  fi

  if [ "$workflow" = "full" ]; then
    case "$review_mode" in
      off|standard|thorough) ;;
      *)
        red "ERROR: Cannot transition '$change_name': review_mode must be selected before leaving build (full workflow); review_mode must be off, standard, or thorough, got '${review_mode:-null}'" >&2
        exit 1
        ;;
    esac
  fi
}

cmd_transition() {
  local change_name="$1"
  local event="$2"
  # Dynamic-scope flag: authorizes the internal cmd_set phase writes below while
  # still blocking direct `set <name> phase` from the CLI.
  local _COMET_IN_TRANSITION=1

  validate_change_name "$change_name"
  validate_enum "$event" "open-complete" "design-complete" "build-complete" "verify-pass" "verify-fail" "archive-reopen" "archived"

  case "$event" in
    open-complete)
      require_phase "$change_name" "open"
      require_open_artifacts "$change_name"
      local workflow
      workflow=$(cmd_get "$change_name" "workflow")
      if [ "$workflow" = "full" ]; then
        cmd_set "$change_name" phase design
      else
        cmd_set "$change_name" phase build
      fi
      ;;
    design-complete)
      require_phase "$change_name" "design"
      require_design_evidence "$change_name"
      cmd_set "$change_name" phase build
      ;;
    build-complete)
      require_phase "$change_name" "build"
      require_build_decisions "$change_name"
      local current_verify_result
      current_verify_result=$(cmd_get "$change_name" "verify_result")
      cmd_set "$change_name" phase verify
      cmd_set "$change_name" verify_result pending
      # Preserve verification evidence on re-verify (verify-fail → build → build-complete)
      # so the fix can reference the original failure report
      if [ "$current_verify_result" != "fail" ]; then
        cmd_set "$change_name" verification_report null
        cmd_set "$change_name" branch_status pending
      fi
      ;;
    verify-pass)
      require_phase "$change_name" "verify"
      require_verification_evidence "$change_name"
      cmd_set "$change_name" verify_result pass
      cmd_set "$change_name" phase archive
      cmd_set "$change_name" verified_at "$(date -u +%Y-%m-%d)"
      ;;
    verify-fail)
      require_phase "$change_name" "verify"
      cmd_set "$change_name" verify_result fail
      cmd_set "$change_name" phase build
      # Preserve branch_status so re-verify doesn't require re-handling branches
      ;;
    archive-reopen)
      require_phase "$change_name" "archive"
      local archived
      archived=$(cmd_get "$change_name" "archived")
      if [ "$archived" = "true" ]; then
        red "ERROR: Cannot transition '$change_name': already archived" >&2
        exit 1
      fi
      cmd_set "$change_name" verify_result pending
      cmd_set "$change_name" phase verify
      cmd_set "$change_name" verified_at null
      ;;
    archived)
      require_phase "$change_name" "archive"
      local archived_verify_result
      archived_verify_result=$(cmd_get "$change_name" "verify_result")
      if [ "$archived_verify_result" != "pass" ]; then
        red "ERROR: Cannot transition '$change_name': verify_result must be pass before archiving" >&2
        exit 1
      fi
      cmd_set "$change_name" archived true
      ;;
  esac

  green "[TRANSITION] ${event}"
}

# --- Check helpers for entry verification ---

CHECK_BLOCK=0

check_pass() {
  local msg="$1"
  echo "  $(green "[PASS]") $msg"
}

check_fail() {
  local msg="$1"
  echo "  $(red "[FAIL]") $msg"
  CHECK_BLOCK=1
}

check_nonempty() {
  local desc="$1"
  local path="$2"
  if file_nonempty "$path"; then
    check_pass "$desc non-empty"
  else
    check_fail "$desc missing or empty"
  fi
}

check_yaml_is() {
  local field="$1"
  local expected="$2"
  local change_name="$3"
  local actual
  actual=$(cmd_get "$change_name" "$field")
  if [ "$actual" = "$expected" ]; then
    check_pass "${field}=${actual} (expected: ${expected})"
  else
    check_fail "${field}=${actual} (expected: ${expected})"
  fi
}

check_yaml_empty() {
  local field="$1"
  local change_name="$2"
  local value
  value=$(cmd_get "$change_name" "$field")
  if [ -z "$value" ] || [ "$value" = "null" ]; then
    check_pass "${field} is empty/null"
  else
    check_fail "${field}=${value} (expected: empty/null)"
  fi
}

check_file_not_exists() {
  local desc="$1"
  local path="$2"
  if [ ! -f "$path" ]; then
    check_pass "$desc does not exist"
  else
    check_fail "$desc exists (should not exist)"
  fi
}

cmd_check() {
  local change_name="$1"
  local phase="$2"

  validate_change_name "$change_name"
  validate_enum "$phase" "open" "design" "build" "verify" "archive"

  local change_dir="openspec/changes/$change_name"
  local yaml_file="$change_dir/.comet.yaml"
  local proposal_file="$change_dir/proposal.md"
  local design_file="$change_dir/design.md"
  local tasks_file="$change_dir/tasks.md"

  echo "=== Entry Check: comet-${phase} ==="

  # .comet.yaml must exist for all phases (state machine core)
  if [ ! -f "$yaml_file" ]; then
    red "ERROR: .comet.yaml not found at $yaml_file"
    exit 1
  fi

  # Phase-specific checks
  case "$phase" in
    open)
      check_pass ".comet.yaml exists"
      check_yaml_is "phase" "open" "$change_name"
      ;;
    design)
      check_pass ".comet.yaml exists"
      check_yaml_is "phase" "design" "$change_name"
      check_yaml_is "workflow" "full" "$change_name"
      check_yaml_empty "design_doc" "$change_name"
      check_nonempty "proposal.md" "$proposal_file"
      check_nonempty "design.md" "$design_file"
      check_nonempty "tasks.md" "$tasks_file"
      ;;
    build)
      check_pass ".comet.yaml exists"
      check_yaml_is "phase" "build" "$change_name"
      # design_doc required for full workflow only
      local workflow
      workflow=$(cmd_get "$change_name" "workflow")
      if [ "$workflow" = "full" ]; then
        local design_doc
        design_doc=$(cmd_get "$change_name" "design_doc")
        if [ -n "$design_doc" ] && [ "$design_doc" != "null" ] && [ -f "$design_doc" ]; then
          check_pass "design_doc=${design_doc} (file exists)"
        else
          check_fail "design_doc=${design_doc} (expected: non-null and file exists)"
        fi
      else
        check_pass "workflow=${workflow} (design_doc not required)"
      fi
      check_nonempty "proposal.md" "$proposal_file"
      check_nonempty "tasks.md" "$tasks_file"
      ;;
    verify)
      check_pass ".comet.yaml exists"
      check_yaml_is "phase" "verify" "$change_name"
      # Check verify_result is pending or null
      local verify_result
      verify_result=$(cmd_get "$change_name" "verify_result")
      if [ "$verify_result" = "pending" ] || [ -z "$verify_result" ] || [ "$verify_result" = "null" ]; then
        check_pass "verify_result=${verify_result} (expected: pending or null)"
      else
        check_fail "verify_result=${verify_result} (expected: pending or null)"
      fi
      ;;
    archive)
      check_pass ".comet.yaml exists"
      check_yaml_is "phase" "archive" "$change_name"
      check_yaml_is "verify_result" "pass" "$change_name"
      # Check archived is NOT true
      local archived
      archived=$(cmd_get "$change_name" "archived")
      if [ "$archived" != "true" ]; then
        check_pass "archived=${archived} (expected: not true)"
      else
        check_fail "archived=${archived} (expected: not true)"
      fi
      ;;
    *)
      red "ERROR: Unknown phase for check: $phase"
      exit 1
      ;;
  esac

  echo ""
  if [ "$CHECK_BLOCK" -eq 1 ]; then
    red "BLOCKED — fix failing checks before proceeding"
    exit 1
  else
    green "ALL CHECKS PASSED — ready to proceed"
    exit 0
  fi
}

# --- Recovery context for compaction resume ---

field_status() {
  # Args: field_name value [file_path]
  # Prints: "field_name: DONE (value)" or "field_name: PENDING"
  local field="$1"
  local value="$2"
  local file_path="${3:-}"

  if [ -z "$value" ] || [ "$value" = "null" ]; then
    echo "  - ${field}: PENDING"
  elif [ -n "$file_path" ] && [ ! -f "$file_path" ]; then
    echo "  - ${field}: BROKEN (path ${value} does not exist)"
  else
    echo "  - ${field}: DONE (${value})"
  fi
}

cmd_recover() {
  local change_name="$1"

  validate_change_name "$change_name"

  local change_dir="openspec/changes/$change_name"
  local yaml_file="$change_dir/.comet.yaml"

  if [ ! -f "$yaml_file" ]; then
    red "ERROR: .comet.yaml not found at $yaml_file"
    exit 1
  fi

  local phase workflow
  phase=$(cmd_get "$change_name" "phase")
  workflow=$(cmd_get "$change_name" "workflow")

  echo "=== Recovery Context: ${change_name} ==="
  echo "Phase: ${phase}"
  echo "Workflow: ${workflow}"
  echo ""

  # Read all relevant fields
  local design_doc plan verify_result verify_mode verification_report
  local branch_status handoff_context handoff_hash isolation build_mode build_pause subagent_dispatch tdd_mode review_mode direct_override
  design_doc=$(cmd_get "$change_name" "design_doc")
  plan=$(cmd_get "$change_name" "plan")
  verify_result=$(cmd_get "$change_name" "verify_result")
  verify_mode=$(cmd_get "$change_name" "verify_mode")
  verification_report=$(cmd_get "$change_name" "verification_report")
  branch_status=$(cmd_get "$change_name" "branch_status")
  handoff_context=$(cmd_get "$change_name" "handoff_context")
  handoff_hash=$(cmd_get "$change_name" "handoff_hash")
  isolation=$(cmd_get "$change_name" "isolation")
  build_mode=$(cmd_get "$change_name" "build_mode")
  build_pause=$(cmd_get "$change_name" "build_pause" 2>/dev/null || true)
  subagent_dispatch=$(cmd_get "$change_name" "subagent_dispatch" 2>/dev/null || true)
  tdd_mode=$(cmd_get "$change_name" "tdd_mode" 2>/dev/null || true)
  review_mode=$(cmd_get "$change_name" "review_mode" 2>/dev/null || true)
  direct_override=$(cmd_get "$change_name" "direct_override" 2>/dev/null || true)

  echo "State fields:"

  # Phase-specific field reporting
  case "$phase" in
    open)
      echo "  Artifacts:"
      local artifacts_done=0
      for f in proposal.md design.md tasks.md; do
        if file_nonempty "$change_dir/$f"; then
          echo "  - ${f}: DONE"
          artifacts_done=$((artifacts_done + 1))
        else
          echo "  - ${f}: PENDING"
        fi
      done
      echo ""
      if [ "$artifacts_done" -eq 3 ]; then
        echo "Recovery action: All artifacts complete. Run /comet-open user confirmation, then guard to transition."
      elif [ "$artifacts_done" -eq 0 ]; then
        echo "Recovery action: No artifacts created yet. Start from /comet-open Step 1 (explore and clarify)."
      else
        echo "Recovery action: Some artifacts incomplete. Resume /comet-open from the first missing artifact."
      fi
      ;;
    design)
      echo "  Artifacts:"
      for f in proposal.md design.md tasks.md; do
        if file_nonempty "$change_dir/$f"; then
          echo "  - ${f}: DONE"
        else
          echo "  - ${f}: MISSING (unexpected in design phase)"
        fi
      done
      echo ""
      echo "  Design progress:"
      field_status "handoff_context" "$handoff_context" "$handoff_context"
      field_status "handoff_hash" "$handoff_hash"
      field_status "design_doc" "$design_doc" "$design_doc"
      echo ""
      if [ -n "$design_doc" ] && [ "$design_doc" != "null" ] && [ -f "$design_doc" ]; then
        echo "Recovery action: Design Doc already created and linked. Run guard to transition to build."
      elif [ -n "$handoff_context" ] && [ "$handoff_context" != "null" ] && [ -f "$handoff_context" ]; then
        echo "Recovery action: Handoff generated but Design Doc not yet created. Resume from brainstorming confirmation (Step 1c)."
      else
        echo "Recovery action: No handoff generated yet. Start from Step 1a (generate handoff package)."
      fi
      ;;
    build)
      echo "  Build decisions:"
      field_status "isolation" "$isolation"
      field_status "build_mode" "$build_mode"
      field_status "build_pause" "$build_pause"
      field_status "tdd_mode" "$tdd_mode"
      field_status "review_mode" "$review_mode"
      if [ "$build_mode" = "subagent-driven-development" ] || { [ -n "$subagent_dispatch" ] && [ "$subagent_dispatch" != "null" ]; }; then
        field_status "subagent_dispatch" "$subagent_dispatch"
      fi
      if [ "$build_mode" = "direct" ] && [ "$workflow" != "hotfix" ] && [ "$workflow" != "tweak" ]; then
        field_status "direct_override" "$direct_override"
      fi
      echo ""
      echo "  Plan:"
      field_status "plan" "$plan" "$plan"
      echo ""
      # Count completed vs pending tasks
      local tasks_file="$change_dir/tasks.md"
      local total=0 done=0 pending=0
      local plan_total=0 plan_done=0 plan_pending=0
      if [ -f "$tasks_file" ]; then
        total=$(grep -c '^[[:space:]]*- \[' "$tasks_file" 2>/dev/null || true)
        done=$(grep -c '^[[:space:]]*- \[x\]' "$tasks_file" 2>/dev/null || true)
        total="${total:-0}"
        done="${done:-0}"
        pending=$((total - done))
        echo "  Tasks: ${done}/${total} done, ${pending} pending"
      else
        echo "  Tasks: tasks.md MISSING"
      fi
      if [ -n "$plan" ] && [ "$plan" != "null" ] && [ -f "$plan" ]; then
        plan_total=$(grep -c '^[[:space:]]*- \[' "$plan" 2>/dev/null || true)
        plan_done=$(grep -c '^[[:space:]]*- \[x\]' "$plan" 2>/dev/null || true)
        plan_total="${plan_total:-0}"
        plan_done="${plan_done:-0}"
        plan_pending=$((plan_total - plan_done))
        if [ "$plan_total" -gt 0 ]; then
          echo "  Plan tasks: ${plan_done}/${plan_total} done, ${plan_pending} pending"
        fi
      fi
      echo ""
      if [ "$build_pause" = "plan-ready" ] && [ -n "$plan" ] && [ "$plan" != "null" ] && [ -f "$plan" ] && { [ "$isolation" = "null" ] || [ -z "$isolation" ] || [ "$build_mode" = "null" ] || [ -z "$build_mode" ]; }; then
        echo "Recovery action: Plan-ready pause detected. Ask the user whether to continue, then choose isolation and build mode without regenerating the plan."
      elif [ "$build_pause" = "plan-ready" ] && { [ -z "$plan" ] || [ "$plan" = "null" ] || [ ! -f "$plan" ]; }; then
        echo "Recovery action: Plan-ready pause is recorded, but the plan file is missing. Restore the plan file or rerun writing-plans before choosing execution."
      elif [ "$build_pause" = "plan-ready" ]; then
        if [ "$build_mode" = "subagent-driven-development" ] && { [ "$pending" -gt 0 ] || [ "$plan_pending" -gt 0 ]; }; then
          if [ "$subagent_dispatch" = "confirmed" ]; then
            echo "Recovery action: Plan-ready pause is stale because build decisions are already selected. Clear build_pause to null, then inspect the first unchecked task (OpenSpec or plan additions) against recent git history/diff. If implemented, check it off; otherwise dispatch a real background subagent. Do not execute the pending task directly in the main window."
          else
            echo "Recovery action: Plan-ready pause is stale and subagent dispatch is not confirmed. Confirm a real background subagent/Task/multi-agent dispatcher and set subagent_dispatch to confirmed, or set build_mode to executing-plans before continuing."
          fi
        elif [ "$pending" -gt 0 ] || [ "$plan_pending" -gt 0 ]; then
          echo "Recovery action: Plan-ready pause is stale because build decisions are already selected. Clear build_pause to null, then continue from the first unchecked task."
        else
          echo "Recovery action: Plan-ready pause is stale and all tasks are done. Clear build_pause to null, then run guard to transition to verify."
        fi
      elif [ "$isolation" = "null" ] || [ -z "$isolation" ]; then
        echo "Recovery action: Isolation not selected. Use the current platform's user confirmation mechanism to ask user for branch/worktree choice."
      elif [ "$build_mode" = "null" ] || [ -z "$build_mode" ]; then
        echo "Recovery action: Build mode not selected. Use the current platform's user confirmation mechanism to ask user for execution method."
      elif [ -z "$tdd_mode" ] || [ "$tdd_mode" = "null" ]; then
        echo "Recovery action: TDD mode not selected. Use the current platform's user confirmation mechanism to ask user for tdd or direct."
      elif [ ! -f "$tasks_file" ]; then
        echo "Recovery action: tasks.md missing. Verify change directory integrity."
      elif [ "$pending" -gt 0 ]; then
        if [ "$build_mode" = "subagent-driven-development" ]; then
          if [ "$subagent_dispatch" = "confirmed" ]; then
            echo "Recovery action: Read tasks.md and the Superpowers plan (which may include additions beyond OpenSpec), then inspect the first unchecked task against recent git history/diff. If implemented, check it off; otherwise dispatch a real background subagent. Do not execute the pending task directly in the main window."
          else
            echo "Recovery action: Subagent dispatch is not confirmed. Confirm a real background subagent/Task/multi-agent dispatcher and set subagent_dispatch to confirmed, or set build_mode to executing-plans before continuing."
          fi
        else
          echo "Recovery action: Read tasks.md and continue from first unchecked task."
        fi
      elif [ "$plan_pending" -gt 0 ]; then
        if [ "$build_mode" = "subagent-driven-development" ]; then
          if [ "$subagent_dispatch" = "confirmed" ]; then
            echo "Recovery action: Read the Superpowers plan, then inspect the first unchecked Superpowers plan task against recent git history/diff. If implemented, check it off; otherwise dispatch a real background subagent. Do not execute the pending task directly in the main window."
          else
            echo "Recovery action: Subagent dispatch is not confirmed. Confirm a real background subagent/Task/multi-agent dispatcher and set subagent_dispatch to confirmed, or set build_mode to executing-plans before continuing."
          fi
        else
          echo "Recovery action: Read the Superpowers plan and continue from the first unchecked plan task."
        fi
      else
        echo "Recovery action: All tasks done. Run guard to transition to verify."
      fi
      ;;
    verify)
      echo "  Verification:"
      field_status "verify_result" "$verify_result"
      field_status "verify_mode" "$verify_mode"
      field_status "verification_report" "$verification_report" "$verification_report"
      field_status "branch_status" "$branch_status"
      echo ""
      if [ "$verify_result" = "pass" ] && [ "$branch_status" = "handled" ]; then
        echo "Recovery action: Verification complete. Run guard to transition to archive."
      elif [ "$verify_result" = "pass" ]; then
        echo "Recovery action: Verification passed but branch not yet handled. Complete branch handling and set branch_status to handled."
      elif [ "$verify_result" = "fail" ]; then
        echo "Recovery action: Verification failed and rolled back to build. Resume from /comet-build."
      else
        echo "Recovery action: Verification not yet started or in progress. Run scale assessment then verify."
      fi
      ;;
    archive)
      echo "  Archive:"
      field_status "verify_result" "$verify_result"
      field_status "archived" "$(cmd_get "$change_name" "archived")"
      echo ""
      echo "Recovery action: Run /comet-archive to complete archiving."
      ;;
    *)
      red "ERROR: Unknown phase: $phase"
      exit 1
      ;;
  esac

  echo ""
  echo "=== End Recovery Context ==="
}

cmd_scale() {
  local change_name="$1"

  validate_change_name "$change_name"

  local change_dir="openspec/changes/$change_name"
  local yaml_file="$change_dir/.comet.yaml"

  # Verify .comet.yaml exists
  if [ ! -f "$yaml_file" ]; then
    red "ERROR: .comet.yaml not found at $yaml_file"
    exit 1
  fi

  # Read metrics
  # 1. Task count: count lines matching `- [` in tasks.md
  local tasks_file="$change_dir/tasks.md"
  local task_count=0
  if [ -f "$tasks_file" ]; then
    task_count=$(grep -c '^\- \[' "$tasks_file" 2>/dev/null || echo "0")
  fi

  # 2. Delta spec count: count files named spec.md under specs/*/spec.md
  local delta_spec_count=0
  if [ -d "$change_dir/specs" ]; then
    delta_spec_count=$(find "$change_dir/specs" -name "spec.md" -type f 2>/dev/null | wc -l | tr -d ' ')
  fi

  # 3. Changed files: prefer plan base-ref, then .comet.yaml base_ref, fall back to worktree diff
  local changed_files=0
  if git rev-parse --git-dir > /dev/null 2>&1; then
    local plan_file base_ref=""
    plan_file=$(cmd_get "$change_name" "plan" 2>/dev/null || true)
    if [ -n "$plan_file" ] && [ "$plan_file" != "null" ] && [ -f "$plan_file" ]; then
      base_ref=$(grep '^base-ref:' "$plan_file" 2>/dev/null | head -1 | sed 's/^base-ref: *//' || true)
    fi
    # Fallback to base_ref stored in .comet.yaml (set during init)
    if [ -z "$base_ref" ] || [ "$base_ref" = "null" ]; then
      base_ref=$(cmd_get "$change_name" "base_ref" 2>/dev/null || true)
    fi

    if [ -n "${base_ref:-}" ] && [ "$base_ref" != "null" ] && git rev-parse --verify "$base_ref" >/dev/null 2>&1; then
      changed_files=$(git diff --name-only "$base_ref"...HEAD 2>/dev/null | wc -l | tr -d ' ')
    else
      changed_files=$(git diff --name-only HEAD 2>/dev/null | wc -l | tr -d ' ')
    fi
  fi

  # Decision rules
  local result="light"
  if [ "$task_count" -gt 3 ] || [ "$delta_spec_count" -gt 1 ] || [ "$changed_files" -gt 4 ]; then
    result="full"
  fi

  # Output assessment to stderr
  echo "=== Scale Assessment: $change_name ===" >&2
  echo "  Tasks: $task_count (threshold: 3)" >&2
  echo "  Delta specs: $delta_spec_count capabilities (threshold: 1)" >&2
  echo "  Changed files: $changed_files (threshold: 4)" >&2
  echo "  → Result: $result" >&2

  # Update verify_mode in .comet.yaml
  replace_yaml_field "$yaml_file" "verify_mode" "$result"

  green "[SCALE] verify_mode=$result"
}

cmd_task_checkoff() {
  local task_file="$1"
  local task_text="$2"

  validate_path_field "$task_file" "task file"

  if [ -z "$task_text" ]; then
    red "ERROR: Task text cannot be empty" >&2
    exit 1
  fi

  if [ ! -f "$task_file" ]; then
    red "ERROR: Task file not found: $task_file" >&2
    exit 1
  fi

  local counts
  counts=$(TASK_TEXT="$task_text" awk '
    BEGIN {
      task = ENVIRON["TASK_TEXT"]
    }
    {
      sub(/\r$/, "")
      if ($0 == "- [ ] " task || $0 == "- [x] " task || $0 == "- [X] " task) {
        total++
      }
      if ($0 == "- [x] " task || $0 == "- [X] " task) {
        checked++
      }
    }
    END {
      printf "%d %d\n", total + 0, checked + 0
    }
  ' "$task_file")

  local total="${counts%% *}"
  local checked="${counts##* }"

  if [ "$total" -ne 1 ]; then
    red "ERROR: task text must appear exactly once in $task_file (found $total): $task_text" >&2
    exit 1
  fi

  if [ "$checked" -ne 1 ]; then
    red "ERROR: task is not checked in $task_file: $task_text" >&2
    exit 1
  fi

  echo "TASK_CHECKOFF: PASS"
  echo "FILE: $task_file"
  echo "TASK: $task_text"
}

# Resolve the next workflow step after a guard --apply phase advance.
# Reads the (already advanced) phase, workflow, and auto_transition, then emits
# a deterministic next-step contract so skills don't hardcode the next skill name.
#
# Output contract (stdout):
#   NEXT: auto|manual|done
#   SKILL: <skill-name>      (omitted when NEXT=done)
#   HINT: <message>          (only when NEXT=manual)
cmd_next() {
  local change_name="$1"
  validate_change_name "$change_name"

  local change_dir="openspec/changes/$change_name"
  local yaml_file="$change_dir/.comet.yaml"
  if [ ! -f "$yaml_file" ]; then
    red "ERROR: .comet.yaml not found at $yaml_file" >&2
    exit 1
  fi

  local phase workflow auto_transition archived
  phase=$(cmd_get "$change_name" "phase" 2>/dev/null || true)
  workflow=$(cmd_get "$change_name" "workflow" 2>/dev/null || true)
  auto_transition=$(cmd_get "$change_name" "auto_transition" 2>/dev/null || true)
  archived=$(cmd_get "$change_name" "archived" 2>/dev/null || true)

  # Change-level auto_transition overrides project-level; fall back to project default
  if [ -z "$auto_transition" ] || [ "$auto_transition" = "null" ]; then
    auto_transition="$(project_auto_transition_default)"
  fi

  case "$auto_transition" in
    true|false)
      ;;
    *)
      red "ERROR: Invalid auto_transition for '$change_name': '${auto_transition:-null}'" >&2
      red "Valid values: true, false" >&2
      exit 1
      ;;
  esac

  # Terminal state: archived change has no next step.
  if [ "$archived" = "true" ]; then
    echo "NEXT: done"
    return 0
  fi

  # Map the current (post-advance) phase to the skill that owns it.
  local skill=""
  case "$phase" in
    open)
      skill="comet-open"
      ;;
    design)
      skill="comet-design"
      ;;
    build)
      case "$workflow" in
        hotfix) skill="comet-hotfix" ;;
        tweak)  skill="comet-tweak" ;;
        *)      skill="comet-build" ;;
      esac
      ;;
    verify)
      skill="comet-verify"
      ;;
    archive)
      skill="comet-archive"
      ;;
    *)
      red "ERROR: Cannot resolve next step for '$change_name': unknown phase '${phase:-null}'" >&2
      exit 1
      ;;
  esac

  # auto_transition=false pauses the next skill invocation only; phase is already advanced.
  if [ "$auto_transition" = "false" ]; then
    echo "NEXT: manual"
    echo "SKILL: $skill"
    echo "HINT: phase is '$phase'; run /$skill manually to continue"
  else
    echo "NEXT: auto"
    echo "SKILL: $skill"
  fi
}

# --- Main ---

SUBCOMMAND="${1:-}"
shift || true

case "$SUBCOMMAND" in
  init)
    if [ $# -lt 2 ]; then
      red "Usage: comet-state.sh init <change-name> <workflow>" >&2
      red "Workflows: full, hotfix, tweak" >&2
      exit 1
    fi
    cmd_init "$@"
    ;;
  get)
    if [ $# -lt 2 ]; then
      red "Usage: comet-state.sh get <change-name> <field>" >&2
      exit 1
    fi
    cmd_get "$@"
    ;;
  set)
    if [ $# -lt 3 ]; then
      red "Usage: comet-state.sh set <change-name> <field> <value>" >&2
      exit 1
    fi
    cmd_set "$@"
    ;;
  transition)
    if [ $# -lt 2 ]; then
      red "Usage: comet-state.sh transition <change-name> <event>" >&2
      red "Events: open-complete, design-complete, build-complete, verify-pass, verify-fail, archive-reopen, archived" >&2
      exit 1
    fi
    cmd_transition "$@"
    ;;
  check)
    if [ $# -lt 2 ]; then
      red "Usage: comet-state.sh check <change-name> <phase> [--recover]" >&2
      red "Phases: open, design, build, verify, archive" >&2
      exit 1
    fi
    # Detect --recover flag (3rd argument)
    if [ "${3:-}" = "--recover" ]; then
      cmd_recover "$1"
    else
      cmd_check "$@"
    fi
    ;;
  scale)
    if [ $# -lt 1 ]; then
      red "Usage: comet-state.sh scale <change-name>" >&2
      exit 1
    fi
    cmd_scale "$@"
    ;;
  task-checkoff)
    if [ $# -lt 2 ]; then
      red "Usage: comet-state.sh task-checkoff <file> <task-text>" >&2
      exit 1
    fi
    cmd_task_checkoff "$@"
    ;;
  next)
    if [ $# -lt 1 ]; then
      red "Usage: comet-state.sh next <change-name>" >&2
      exit 1
    fi
    cmd_next "$@"
    ;;
  *)
    red "Unknown subcommand: $SUBCOMMAND" >&2
    echo "" >&2
    echo "Usage: comet-state.sh <subcommand> <change-name> [args...]" >&2
    echo "" >&2
    echo "Subcommands:" >&2
    echo "  init <change-name> <workflow>  — Initialize .comet.yaml with workflow defaults" >&2
    echo "  get <change-name> <field>       — Read a field value from .comet.yaml" >&2
    echo "  set <change-name> <field> <val> — Update a field value in .comet.yaml" >&2
    echo "  transition <change-name> <event> — Apply a validated state transition" >&2
    echo "  check <change-name> <phase>    — Verify entry requirements for a phase" >&2
    echo "  scale <change-name>             — Assess and set verification mode based on metrics" >&2
    echo "  task-checkoff <file> <task-text> — Verify one unique task is checked" >&2
    echo "  next <change-name>              — Resolve the next workflow step (auto/manual/done)" >&2
    echo "" >&2
    echo "Workflows: full, hotfix, tweak" >&2
    echo "Phases for check: open, design, build, verify, archive" >&2
    exit 1
    ;;
esac
__COMET_ASSETS_SKILLS_COMET_SCRIPTS_COMET_STATE_SH__
chmod +x "$TARGET_DIR/assets/skills/comet/scripts/comet-state.sh"

cat > "$TARGET_DIR/assets/skills/comet/scripts/comet-yaml-validate.sh" <<'__COMET_ASSETS_SKILLS_COMET_SCRIPTS_COMET_YAML_VALIDATE_SH__'
#!/bin/bash
# Comet YAML Schema Validator — validates .comet.yaml structure
# Usage: comet-yaml-validate.sh <change-name>
# Exit 0 = valid, exit 1 = errors found (printed to stderr)

set -euo pipefail

red()   { echo -e "\033[31m$1\033[0m" >&2; }
green() { echo -e "\033[32m$1\033[0m" >&2; }
warn()  { echo -e "\033[33m$1\033[0m" >&2; }

# Input validation - prevent path traversal
validate_change_name() {
  local name="$1"
  # Reject empty names
  if [ -z "$name" ]; then
    red "ERROR: Change name cannot be empty" >&2
    exit 1
  fi
  # Only allow alphanumeric, hyphens, and underscores
  if [[ ! "$name" =~ ^[a-zA-Z0-9_-]+$ ]]; then
    red "ERROR: Invalid change name: '$name'" >&2
    red "Valid characters: a-z, A-Z, 0-9, -, _" >&2
    exit 1
  fi
  # Reject path traversal attempts
  if [[ "$name" =~ \.\. ]]; then
    red "ERROR: Change name cannot contain '..' (path traversal not allowed)" >&2
    exit 1
  fi
}

validate_change_name "$1"

CHANGE="$1"
CHANGE_DIR="openspec/changes/$CHANGE"
if [ ! -d "$CHANGE_DIR" ] && [ -d "openspec/changes/archive/$CHANGE" ]; then
  CHANGE_DIR="openspec/changes/archive/$CHANGE"
fi
YAML="$CHANGE_DIR/.comet.yaml"

ERRORS=0
WARNINGS=0

# Helper: get value of a top-level field (handles null, empty, quoted)
field_value() {
  local value
  value=$(grep "^${1}:" "$YAML" 2>/dev/null | sed "s/^${1}: *//" || true)
  value=$(strip_inline_comment "$value")
  strip_wrapping_quotes "$value"
}

strip_inline_comment() {
  local value="$1"
  printf '%s\n' "$value" | awk -v squote="'" '
    {
      out = ""
      quote = ""
      for (i = 1; i <= length($0); i++) {
        c = substr($0, i, 1)
        if (quote == "") {
          if (c == "\"" || c == squote) {
            quote = c
          } else if (c == "#" && (i == 1 || substr($0, i - 1, 1) ~ /[[:space:]]/)) {
            sub(/[[:space:]]+$/, "", out)
            print out
            next
          }
        } else if (c == quote) {
          quote = ""
        }
        out = out c
      }
      print out
    }
  '
}

strip_wrapping_quotes() {
  local value="$1"
  case "$value" in
    \"*\")
      printf '%s\n' "${value:1:${#value}-2}"
      ;;
    \'*\')
      printf '%s\n' "${value:1:${#value}-2}"
      ;;
    *)
      printf '%s\n' "$value"
      ;;
  esac
}

fail()  { red "  FAIL: $1"; ERRORS=$((ERRORS + 1)); }
warn_msg() { warn "  WARN: $1"; WARNINGS=$((WARNINGS + 1)); }

echo "[VALIDATE] $YAML" >&2

# --- Required fields ---
REQUIRED_FIELDS="workflow phase design_doc plan build_mode isolation verify_mode verify_result verified_at archived"
for field in $REQUIRED_FIELDS; do
  if ! grep -q "^${field}:" "$YAML" 2>/dev/null; then
    fail "missing required field '$field'"
  fi
done

# --- Enum validation ---
validate_enum() {
  local field="$1" value="$2"
  shift 2
  local valid_values="$*"

  # null or empty is always acceptable
  if [ -z "$value" ] || [ "$value" = "null" ]; then
    return 0
  fi

  for v in $valid_values; do
    if [ "$value" = "$v" ]; then
      return 0
    fi
  done
  fail "$field='$value' is not valid. Expected: $valid_values"
}

validate_required_enum() {
  local field="$1" value="$2"
  shift 2
  local valid_values="$*"

  if [ -z "$value" ] || [ "$value" = "null" ]; then
    fail "$field='${value:-}' is not valid. Expected: $valid_values"
    return 0
  fi

  validate_enum "$field" "$value" "$@"
}

workflow=$(field_value "workflow")
phase=$(field_value "phase")
context_compression=$(field_value "context_compression")
build_mode=$(field_value "build_mode")
build_pause=$(field_value "build_pause")
subagent_dispatch=$(field_value "subagent_dispatch")
tdd_mode=$(field_value "tdd_mode")
review_mode=$(field_value "review_mode")
isolation=$(field_value "isolation")
verify_mode=$(field_value "verify_mode")
auto_transition=$(field_value "auto_transition")
verify_result=$(field_value "verify_result")
branch_status=$(field_value "branch_status")
archived=$(field_value "archived")
direct_override=$(field_value "direct_override")
design_doc=$(field_value "design_doc")
plan=$(field_value "plan")
handoff_context=$(field_value "handoff_context")
handoff_hash=$(field_value "handoff_hash")

validate_enum "workflow"      "$workflow"      "full hotfix tweak"
validate_enum "phase"         "$phase"          "open design build verify archive"
validate_enum "context_compression" "$context_compression" "off beta"
validate_enum "build_mode"    "$build_mode"     "subagent-driven-development executing-plans direct"
validate_enum "build_pause"   "$build_pause"     "null plan-ready"
validate_enum "subagent_dispatch" "$subagent_dispatch" "null confirmed"
validate_enum "tdd_mode"      "$tdd_mode"       "tdd direct null"
validate_enum "review_mode"   "$review_mode"    "off standard thorough"
validate_enum "isolation"     "$isolation"      "branch worktree"
validate_enum "verify_mode"   "$verify_mode"    "light full"
if grep -q "^auto_transition:" "$YAML" 2>/dev/null; then
  validate_required_enum "auto_transition" "$auto_transition" "true false"
fi
validate_enum "verify_result" "$verify_result"  "pending pass fail"
validate_enum "branch_status" "$branch_status"  "pending handled"
validate_enum "archived"      "$archived"       "true false"
validate_enum "direct_override" "$direct_override" "true false"

# --- Path validation ---

if [ -n "$design_doc" ] && [ "$design_doc" != "null" ]; then
  if [ ! -f "$design_doc" ]; then
    fail "design_doc='$design_doc' does not exist on disk"
  fi
fi

if [ -n "$plan" ] && [ "$plan" != "null" ]; then
  if [ ! -f "$plan" ]; then
    fail "plan='$plan' does not exist on disk"
  fi
fi

if [ -n "$handoff_context" ] && [ "$handoff_context" != "null" ]; then
  if [ ! -f "$handoff_context" ]; then
    fail "handoff_context='$handoff_context' does not exist on disk"
  fi
fi

if [ -n "$handoff_hash" ] && [ "$handoff_hash" != "null" ]; then
  if [[ ! "$handoff_hash" =~ ^[a-f0-9]{64}$ ]]; then
    fail "handoff_hash='$handoff_hash' is not a sha256 hex digest"
  fi
fi

# --- Unknown keys check ---
KNOWN_KEYS="workflow phase context_compression design_doc plan build_mode build_pause subagent_dispatch tdd_mode review_mode isolation verify_mode auto_transition verify_result verification_report branch_status verified_at created_at archived direct_override build_command verify_command handoff_context handoff_hash base_ref"
while IFS=: read -r key _; do
  key="${key// /}"
  [ -z "$key" ] && continue
  found=0
  for known in $KNOWN_KEYS; do
    [ "$key" = "$known" ] && found=1 && break
  done
  if [ "$found" -eq 0 ]; then
    warn_msg "unknown field '$key' found"
  fi
done < "$YAML"

# --- Summary ---
echo "" >&2
if [ "$ERRORS" -gt 0 ]; then
  red "$ERRORS error(s), $WARNINGS warning(s) — validation FAILED"
  exit 1
else
  green "0 errors, $WARNINGS warning(s) — validation PASSED"
  exit 0
fi
__COMET_ASSETS_SKILLS_COMET_SCRIPTS_COMET_YAML_VALIDATE_SH__
chmod +x "$TARGET_DIR/assets/skills/comet/scripts/comet-yaml-validate.sh"

cat > "$TARGET_DIR/bin/comet.js" <<'__COMET_BIN_COMET_JS__'
#!/usr/bin/env node

import '../dist/cli/index.js';
__COMET_BIN_COMET_JS__
chmod +x "$TARGET_DIR/bin/comet.js"

cat > "$TARGET_DIR/dist/cli/index.js" <<'__COMET_DIST_CLI_INDEX_JS__'
import { Command, Option } from 'commander';
import { createRequire } from 'module';
import { initCommand } from '../commands/init.js';
import { statusCommand } from '../commands/status.js';
import { doctorCommand } from '../commands/doctor.js';
import { updateCommand } from '../commands/update.js';
import { uninstallCommand } from '../commands/uninstall.js';
const require = createRequire(import.meta.url);
const { version } = require('../../package.json');
const program = new Command();
program
    .name('comet')
    .description('Agent Skill Harness Phase-Guarded Automation From Idea To Archive')
    .version(version);
program
    .command('init [path]')
    .description('Initialize Comet workflow in your project')
    .option('--yes', 'Auto-install missing components, skip existing')
    .option('--skip-existing', 'Never overwrite existing components')
    .option('--overwrite', 'Overwrite manifest-managed files')
    .option('--json', 'Output as JSON')
    .addOption(new Option('--scope <scope>', 'Install scope').choices(['global', 'project']))
    .action(async (targetPath = '.', options) => {
    try {
        await initCommand(targetPath, options);
    }
    catch (error) {
        if (error instanceof Error && error.name === 'ExitPromptError') {
            console.log('\n  Cancelled.\n');
            process.exit(0);
        }
        throw error;
    }
});
program
    .command('status [path]')
    .description('Show active changes and workflow status')
    .option('--json', 'Output as JSON')
    .action(async (targetPath = '.', options) => {
    await statusCommand(targetPath, options);
});
program
    .command('doctor [path]')
    .description('Diagnose Comet installation health')
    .option('--json', 'Output as JSON')
    .addOption(new Option('--scope <scope>', 'Install scope to diagnose').choices([
    'auto',
    'global',
    'project',
]))
    .action(async (targetPath = '.', options) => {
    await doctorCommand(targetPath, options);
});
program
    .command('update [path]')
    .description('Update comet skill files to latest version')
    .option('--json', 'Output as JSON')
    .addOption(new Option('--scope <scope>', 'Install scope').choices(['global', 'project']))
    .addOption(new Option('--skip-npm', 'Skip npm package self-update').hideHelp())
    .action(async (targetPath = '.', options) => {
    await updateCommand(targetPath, options);
});
program
    .command('uninstall [path]')
    .description('Remove Comet skills from your project or global scope')
    .option('--json', 'Output as JSON')
    .addOption(new Option('--scope <scope>', 'Uninstall scope').choices(['global', 'project']))
    .option('--force', 'Skip confirmation prompts')
    .action(async (targetPath = '.', options) => {
    try {
        await uninstallCommand(targetPath, options);
    }
    catch (error) {
        if (error instanceof Error && error.name === 'ExitPromptError') {
            console.log('\n  Cancelled.\n');
            process.exit(0);
        }
        throw error;
    }
});
program.parse();
//# sourceMappingURL=index.js.map
__COMET_DIST_CLI_INDEX_JS__

cat > "$TARGET_DIR/dist/commands/doctor.js" <<'__COMET_DIST_COMMANDS_DOCTOR_JS__'
import path from 'path';
import os from 'os';
import { execSync } from 'child_process';
import { promises as fs } from 'fs';
import { fileExists, readDir } from '../utils/file-system.js';
import { isCommandAvailable } from '../core/openspec.js';
import { hasCodegraphProjectIndex, resolveCodegraphCommand } from '../core/codegraph.js';
import { readManifest, getAssetsDir } from '../core/skills.js';
import { PLATFORMS, getPlatformSkillsDirs } from '../core/platforms.js';
const VALID_YAML_FIELDS = new Set([
    'workflow',
    'phase',
    'build_mode',
    'isolation',
    'verify_mode',
    'verify_result',
    'design_doc',
    'plan',
    'verification_report',
    'branch_status',
    'archived',
    'verified_at',
]);
function collectTopLevelYamlKeys(yamlContent) {
    const topLevelKeys = [];
    for (const line of yamlContent.split(/\r?\n/u)) {
        const trimmedLine = line.trim();
        if (!trimmedLine || trimmedLine.startsWith('#'))
            continue;
        if (/^\s/u.test(line))
            continue;
        if (trimmedLine.startsWith('- '))
            continue;
        const keyMatch = line.match(/^['"]?([A-Za-z0-9_-]+)['"]?\s*:/u);
        if (keyMatch) {
            topLevelKeys.push(keyMatch[1]);
        }
    }
    return topLevelKeys;
}
async function checkOpenSpecCli() {
    if (!isCommandAvailable('openspec')) {
        return {
            check: 'openspec CLI',
            status: 'warn',
            message: 'not installed — install with: npm install -g @fission-ai/openspec@latest',
        };
    }
    try {
        const version = execSync('openspec --version', { stdio: 'pipe', timeout: 10_000 })
            .toString()
            .trim();
        return { check: 'openspec CLI', status: 'pass', message: `installed (${version})` };
    }
    catch {
        return { check: 'openspec CLI', status: 'pass', message: 'installed' };
    }
}
async function checkWorkingDirs(projectPath) {
    const specsDir = path.join(projectPath, 'docs', 'superpowers', 'specs');
    const plansDir = path.join(projectPath, 'docs', 'superpowers', 'plans');
    const specsExist = await fileExists(specsDir);
    const plansExist = await fileExists(plansDir);
    if (specsExist && plansExist) {
        return { check: 'working directories', status: 'pass', message: 'present' };
    }
    if (!specsExist && !plansExist) {
        return { check: 'working directories', status: 'fail', message: 'missing — run: comet init' };
    }
    const missing = [];
    if (!specsExist)
        missing.push('specs');
    if (!plansExist)
        missing.push('plans');
    return {
        check: 'working directories',
        status: 'warn',
        message: `partial (missing: ${missing.join(', ')})`,
    };
}
function getScopeBases(projectPath, scope) {
    if (scope === 'project')
        return [{ scope, baseDir: projectPath }];
    if (scope === 'global')
        return [{ scope, baseDir: os.homedir() }];
    const bases = [
        { scope: 'project', baseDir: projectPath },
    ];
    if (path.resolve(projectPath) !== path.resolve(os.homedir())) {
        bases.push({ scope: 'global', baseDir: os.homedir() });
    }
    return bases;
}
async function checkSkillCompleteness(projectPath, scope) {
    const results = [];
    const manifest = await readManifest();
    let anyPlatform = false;
    for (const base of getScopeBases(projectPath, scope)) {
        for (const platform of PLATFORMS) {
            const detectedSkillsDir = (await Promise.all(getPlatformSkillsDirs(platform, base.scope).map(async (skillsDir) => ({
                skillsDir,
                exists: await fileExists(path.join(base.baseDir, skillsDir, 'skills')),
            })))).find((candidate) => candidate.exists)?.skillsDir;
            if (!detectedSkillsDir)
                continue;
            const skillsDir = path.join(base.baseDir, detectedSkillsDir, 'skills');
            if (!(await fileExists(skillsDir)))
                continue;
            anyPlatform = true;
            const missing = [];
            for (const relPath of manifest.skills) {
                const fullPath = path.join(base.baseDir, detectedSkillsDir, 'skills', relPath);
                if (!(await fileExists(fullPath))) {
                    missing.push(relPath);
                }
            }
            results.push(missing.length === 0
                ? {
                    check: `skills: ${platform.name} (${base.scope})`,
                    status: 'pass',
                    message: `complete (${manifest.skills.length} files)`,
                }
                : {
                    check: `skills: ${platform.name} (${base.scope})`,
                    status: 'warn',
                    message: `missing ${missing.length}: ${missing.join(', ')}`,
                });
        }
    }
    if (!anyPlatform) {
        results.push({
            check: 'skills',
            status: 'warn',
            message: scope === 'auto'
                ? 'no platforms detected in project or global scope — run comet init'
                : `no platforms detected in ${scope} scope — run comet init`,
        });
    }
    return results;
}
async function checkScriptsPresent() {
    const assetsDir = getAssetsDir();
    const scriptsDir = path.join(assetsDir, 'skills', 'comet', 'scripts');
    if (!(await fileExists(scriptsDir))) {
        return { check: 'scripts present', status: 'warn', message: 'scripts directory not found' };
    }
    const entries = await readDir(scriptsDir);
    const shFiles = entries.filter((e) => e.endsWith('.sh'));
    return {
        check: 'scripts executable',
        status: 'pass',
        message: `OK (${shFiles.length} scripts)`,
    };
}
async function checkCometYamlValidity(projectPath) {
    const changesDir = path.join(projectPath, 'openspec', 'changes');
    if (!(await fileExists(changesDir)))
        return [];
    const entries = await readDir(changesDir);
    const results = [];
    for (const entry of entries) {
        const yamlPath = path.join(changesDir, entry, '.comet.yaml');
        if (!(await fileExists(yamlPath)))
            continue;
        const raw = await fs.readFile(yamlPath, 'utf-8');
        const unknownFields = collectTopLevelYamlKeys(raw).filter((key) => !VALID_YAML_FIELDS.has(key));
        results.push(unknownFields.length === 0
            ? { check: `.comet.yaml: ${entry}`, status: 'pass', message: 'valid' }
            : {
                check: `.comet.yaml: ${entry}`,
                status: 'fail',
                message: `unknown field(s): ${unknownFields.join(', ')}`,
            });
    }
    return results;
}
async function checkCodegraph(projectPath, scope) {
    if (scope !== 'global' && hasCodegraphProjectIndex(projectPath)) {
        return { check: 'CodeGraph', status: 'pass', message: 'initialized (.codegraph/ present)' };
    }
    if (!resolveCodegraphCommand()) {
        return {
            check: 'CodeGraph CLI',
            status: 'warn',
            message: 'not installed — install with: npm install -g @colbymchenry/codegraph',
        };
    }
    if (scope === 'global') {
        return { check: 'CodeGraph CLI', status: 'pass', message: 'installed' };
    }
    const codegraphDir = path.join(projectPath, '.codegraph');
    if (!(await fileExists(codegraphDir))) {
        return {
            check: 'CodeGraph',
            status: 'warn',
            message: 'CLI installed but project not initialized — run: codegraph init -i',
        };
    }
    return { check: 'CodeGraph', status: 'pass', message: 'initialized (.codegraph/ present)' };
}
async function collectResults(projectPath, scope) {
    const results = [];
    results.push(await checkOpenSpecCli());
    if (scope !== 'global') {
        results.push(await checkWorkingDirs(projectPath));
    }
    results.push(...(await checkSkillCompleteness(projectPath, scope)));
    results.push(await checkScriptsPresent());
    results.push(await checkCodegraph(projectPath, scope));
    results.push(...(await checkCometYamlValidity(projectPath)));
    return results;
}
function icon(status) {
    if (status === 'pass')
        return '✓';
    if (status === 'warn')
        return '⚠';
    return '✗';
}
export async function doctorCommand(targetPath, options = {}) {
    const projectPath = path.resolve(targetPath);
    const scope = options.scope ?? 'auto';
    const results = await collectResults(projectPath, scope);
    if (options.json) {
        console.log(JSON.stringify({ scope, results }, null, 2));
        return;
    }
    console.log(`Comet Doctor (scope: ${scope})\n`);
    for (const r of results) {
        console.log(`  ${icon(r.status)} ${r.check}: ${r.message}`);
    }
    console.log();
}
//# sourceMappingURL=doctor.js.map
__COMET_DIST_COMMANDS_DOCTOR_JS__

cat > "$TARGET_DIR/dist/commands/i18n.js" <<'__COMET_DIST_COMMANDS_I18N_JS__'
const TRANSLATIONS = {
    settingUp: '正在设置 Comet：',
    installScope: '安装范围：',
    scopeProject: '项目（当前目录）',
    scopeGlobal: '全局（主目录）',
    noPlatforms: '未选择可安装目标。',
    overwriteChoice: '如何处理？',
    overwrite: '覆盖',
    skip: '跳过',
    bulkOverwrite: '已安装',
    overwriteAll: '覆盖所有已有组件',
    skipAll: '跳过所有已有组件',
    choosePer: '逐个选择',
    installingOS: '正在安装 OpenSpec：',
    osSkippedNoCli: '未安装 OpenSpec CLI，跳过 OpenSpec 配置',
    allSkipped: '全部跳过',
    installingSP: '正在安装 Superpowers：',
    spSkippedByUser: '用户跳过 Superpowers 安装',
    alreadyExists: '已存在',
    installCodegraph: '是否安装 CodeGraph（语义代码智能）？',
    codegraphYes: '是（推荐 — 节省约 16% 成本，减少约 58% 工具调用）',
    codegraphNo: '否',
    installingCG: '正在安装 CodeGraph...',
    cgSkippedByUser: '用户跳过 CodeGraph 安装',
    setupComplete: 'Comet 设置完成！',
    installed: '已安装：',
    skippedLabel: '已跳过：',
    failedLabel: '失败：',
    failedStatus: '失败',
    workingDirs: '工作目录：docs/superpowers/specs/, docs/superpowers/plans/',
    getStarted: '开始使用：',
    getStartedComet: '/comet "你的想法"  — 启动完整工作流',
    getStartedHotfix: '/comet-hotfix       — 快速修复（跳过 brainstorming）',
    getStartedTweak: '/comet-tweak        — 小改动（跳过 brainstorming 和完整 plan）',
    selectNpmDeps: '选择要安装/升级的 npm 依赖：',
    npmDepOpenSpec: 'OpenSpec CLI (@fission-ai/openspec@latest)',
    npmDepOpenSpecInstalled: 'OpenSpec CLI（已安装 — 升级到最新版本）',
    npmDepSuperpowers: 'Superpowers (npx skills add obra/superpowers)',
    npmDepSuperpowersInstalled: 'Superpowers（已安装 — 重新运行安装）',
    npmDepSuperpowersHint: '推荐 v6.0.0+ — 速度快约 2 倍，节省约 50% token',
    npmDepCodegraph: 'CodeGraph CLI (@colbymchenry/codegraph)',
    npmDepCodegraphInstalled: 'CodeGraph CLI（已安装 — 升级到最新版本）',
    npmDepNotInstalled: '未安装',
    updateTitle: 'Comet 更新',
    updatingNpmPackage: '正在更新 npm 包',
    npmLaunchFailed: 'npm 包：启动 npm 失败',
    npmUpdateFailed: 'npm 包：更新失败（退出码',
    npmNetworkHint: '请检查网络连接或防火墙设置后重试。',
    npmPackageUpdated: 'npm 包：已更新到最新版本',
    npmPackageFailed: 'npm 包：更新失败，继续使用已打包的 skills',
    noInstallsFound: '未检测到已安装 comet skills 的平台。请先运行 `comet init`。',
    updatingSkillsOnTargets: '正在更新 comet skills，覆盖',
    copyingSkillsFiles: '正在复制',
    skillsCopiedSkipped: '已复制，',
    summary: '摘要：',
    summaryNpm: 'npm：',
    summarySkills: 'skills：',
    summaryCodegraph: 'codegraph：',
    summaryScope: '范围：',
    summaryLanguage: '语言：',
    updateComplete: '更新完成。',
    cancelled: '已取消。',
};
export function t(_lang, key) {
    return TRANSLATIONS[key];
}
//# sourceMappingURL=i18n.js.map
__COMET_DIST_COMMANDS_I18N_JS__

cat > "$TARGET_DIR/dist/commands/init.js" <<'__COMET_DIST_COMMANDS_INIT_JS__'
import path from 'path';
import os from 'os';
import { checkbox, select } from '@inquirer/prompts';
import { PLATFORMS, getPlatformSkillsDir } from '../core/platforms.js';
import { hasSkills, getBaseDir } from '../core/detect.js';
import { copyCometSkillsForPlatform, createWorkingDirs, } from '../core/skills.js';
import { installOpenSpec, isCommandAvailable } from '../core/openspec.js';
import { installSuperpowersForPlatforms } from '../core/superpowers.js';
import { hasCodegraphProjectIndex, installCodegraph, resolveCodegraphCommand, } from '../core/codegraph.js';
import { printVersionInfo } from '../core/version.js';
import { t } from './i18n.js';
const LANGUAGES = [
    { id: 'zh', name: '中文', skillsDir: 'skills-zh' },
];
const COMET_BANNER = [
    `   ██████╗ ██████╗ ███╗   ███╗███████╗████████╗`,
    `  ██╔════╝██╔═══██╗████╗ ████║██╔════╝╚══██╔══╝`,
    `  ██║     ██║   ██║██╔████╔██║█████╗     ██║   `,
    `  ██║     ██║   ██║██║╚██╔╝██║██╔══╝     ██║   `,
    `  ╚██████╗╚██████╔╝██║ ╚═╝ ██║███████╗   ██║   `,
    `   ╚═════╝ ╚═════╝ ╚═╝     ╚═╝╚══════╝   ╚═╝   `,
    `       Agent Skill Harness Phase-Guarded Automation`,
    `               From Idea To Archive                `,
].join('\n');
async function selectScope(options, lang) {
    if (options.scope)
        return options.scope;
    if (options.yes)
        return 'project';
    return select({
        message: t(lang, 'installScope'),
        choices: [
            { name: t(lang, 'scopeProject'), value: 'project' },
            { name: t(lang, 'scopeGlobal'), value: 'global' },
        ],
    });
}
async function selectLanguage(options) {
    return LANGUAGES[0];
}
async function selectPlatforms(options) {
    if (options.yes) {
        return ['opencode'];
    }
    return ['opencode'];
}
async function promptOverwriteChoice(componentName, platformName, lang) {
    return select({
        message: `${componentName} ${t(lang, 'alreadyExists')} ${platformName}. ${t(lang, 'overwriteChoice')}`,
        choices: [
            { name: t(lang, 'overwrite'), value: 'overwrite' },
            { name: t(lang, 'skip'), value: 'skip' },
        ],
    });
}
async function promptBulkOverwriteChoice(platformName, components, lang) {
    return select({
        message: `${platformName} ${t(lang, 'bulkOverwrite')} ${components.join(', ')}. ${t(lang, 'overwriteChoice')}`,
        choices: [
            { name: t(lang, 'overwriteAll'), value: 'overwrite-all' },
            { name: t(lang, 'skipAll'), value: 'skip-all' },
            { name: t(lang, 'choosePer'), value: 'choose' },
        ],
    });
}
function applyBulkOverwriteChoice(plan, choice, hasExisting) {
    const action = choice === 'overwrite-all' ? 'overwrite' : 'skip';
    const shouldApply = (actionState, exists) => actionState === 'install' && (hasExisting === undefined || exists === true);
    return {
        ...plan,
        osAction: shouldApply(plan.osAction, hasExisting?.os) ? action : plan.osAction,
        spAction: shouldApply(plan.spAction, hasExisting?.sp) ? action : plan.spAction,
        cmAction: shouldApply(plan.cmAction, hasExisting?.cm) ? action : plan.cmAction,
    };
}
function resolveAction(hasExisting, options) {
    if (!hasExisting)
        return 'install';
    if (options.overwrite)
        return 'overwrite';
    if (options.skipExisting)
        return 'skip';
    if (options.yes)
        return 'skip';
    return 'install';
}
async function selectNpmDeps(projectPath, spPlatformIds, options, lang) {
    const openSpecInstalled = isCommandAvailable('openspec');
    const codegraphInstalled = hasCodegraphProjectIndex(projectPath) || resolveCodegraphCommand() !== null;
    const superpowersInstalled = spPlatformIds.length === 0 ? true : undefined;
    const states = [
        { id: 'openspec', installed: openSpecInstalled },
        { id: 'superpowers', installed: Boolean(superpowersInstalled) },
        { id: 'codegraph', installed: codegraphInstalled },
    ];
    const depLabel = {
        openspec: (installed) => installed ? t(lang, 'npmDepOpenSpecInstalled') : t(lang, 'npmDepOpenSpec'),
        superpowers: (installed) => installed ? t(lang, 'npmDepSuperpowersInstalled') : t(lang, 'npmDepSuperpowers'),
        codegraph: (installed) => installed ? t(lang, 'npmDepCodegraphInstalled') : t(lang, 'npmDepCodegraph'),
    };
    const depHint = {
        superpowers: t(lang, 'npmDepSuperpowersHint'),
    };
    const choices = states.map(({ id, installed }) => {
        const choice = {
            name: depLabel[id](installed),
            value: id,
            checked: !installed,
        };
        if (depHint[id]) {
            choice.description = depHint[id];
        }
        return choice;
    });
    if (options.yes) {
        return new Set(states.filter((s) => !s.installed).map((s) => s.id));
    }
    const selected = await checkbox({
        message: t(lang, 'selectNpmDeps'),
        choices,
    });
    return new Set(selected);
}
function displaySummary(results, scope, lang) {
    const scopeLabel = scope === 'global' ? os.homedir() : 'project';
    const componentStatuses = [
        ['openspec', 'OpenSpec'],
        ['superpowers', 'Superpowers'],
        ['comet', 'Comet'],
        ['codegraph', 'CodeGraph'],
    ];
    const hasFailure = (result) => componentStatuses.some(([key]) => result[key] === 'failed');
    const hasInstall = (result) => componentStatuses.some(([key]) => result[key] === 'installed');
    const failedDetails = (result) => componentStatuses
        .filter(([key]) => result[key] === 'failed')
        .map(([, label]) => `${label} ${t(lang, 'failedStatus')}`)
        .join(', ');
    console.log(`\n  ${t(lang, 'setupComplete')} (scope: ${scopeLabel})\n`);
    const failed = results.filter(hasFailure);
    const installed = results.filter((r) => !hasFailure(r) && hasInstall(r));
    const skipped = results.filter((r) => componentStatuses.every(([key]) => r[key] === 'skipped'));
    if (installed.length > 0) {
        console.log(`  ${t(lang, 'installed')}`);
        for (const r of installed) {
            console.log(`    ${r.platform.name} -> ${getPlatformSkillsDir(r.platform, scope)}/skills/`);
        }
    }
    if (skipped.length > 0) {
        console.log(`  ${t(lang, 'skippedLabel')} ${skipped.map((r) => r.platform.name).join(', ')}`);
    }
    if (failed.length > 0) {
        console.log(`  ${t(lang, 'failedLabel')}`);
        for (const r of failed) {
            console.log(`    ${r.platform.name} (${failedDetails(r)})`);
        }
    }
    if (scope === 'project') {
        console.log(`\n  ${t(lang, 'workingDirs')}`);
    }
    console.log(`\n  ${t(lang, 'getStarted')}`);
    console.log(`    ${t(lang, 'getStartedComet')}`);
    console.log(`    ${t(lang, 'getStartedHotfix')}`);
    console.log(`    ${t(lang, 'getStartedTweak')}\n`);
}
export async function initCommand(targetPath, options = {}) {
    const projectPath = path.resolve(targetPath);
    const log = options.json ? () => undefined : console.log;
    log(`\n${COMET_BANNER}\n`);
    if (!options.json) {
        await printVersionInfo(log);
    }
    const language = await selectLanguage(options);
    const lang = language.id;
    log(`  ${t(lang, 'settingUp')} ${projectPath}\n`);
    const scope = await selectScope(options, lang);
    const selectedPlatformIds = await selectPlatforms(options);
    if (selectedPlatformIds.length === 0) {
        if (options.json) {
            console.log(JSON.stringify({
                projectPath,
                scope,
                language: language.id,
                selectedPlatforms: [],
                results: [],
            }, null, 2));
            return;
        }
        log(`\n  ${t(lang, 'noPlatforms')}\n`);
        return;
    }
    const selectedPlatforms = PLATFORMS.filter((p) => selectedPlatformIds.includes(p.id));
    const baseDir = getBaseDir(scope, projectPath);
    const plans = [];
    for (const platform of selectedPlatforms) {
        const hasOS = await hasSkills(baseDir, platform, 'openspec', selectedPlatforms, scope);
        const hasSP = await hasSkills(baseDir, platform, 'superpowers', selectedPlatforms, scope);
        const hasCM = await hasSkills(baseDir, platform, 'comet', selectedPlatforms, scope);
        let osAction = resolveAction(hasOS, options);
        let spAction = resolveAction(hasSP, options);
        let cmAction = resolveAction(hasCM, options);
        if (!options.yes) {
            const existingComponents = [
                hasOS && osAction === 'install' ? 'OpenSpec' : null,
                hasSP && spAction === 'install' ? 'Superpowers' : null,
                hasCM && cmAction === 'install' ? 'Comet' : null,
            ].filter((component) => Boolean(component));
            if (existingComponents.length > 1) {
                const bulkChoice = await promptBulkOverwriteChoice(platform.name, existingComponents, lang);
                if (bulkChoice !== 'choose') {
                    ({ osAction, spAction, cmAction } = applyBulkOverwriteChoice({ osAction, spAction, cmAction }, bulkChoice, { os: hasOS, sp: hasSP, cm: hasCM }));
                }
            }
            if (osAction === 'install' && hasOS) {
                osAction = await promptOverwriteChoice('OpenSpec', platform.name, lang);
            }
            if (spAction === 'install' && hasSP) {
                spAction = await promptOverwriteChoice('Superpowers', platform.name, lang);
            }
            if (cmAction === 'install' && hasCM) {
                cmAction = await promptOverwriteChoice('Comet', platform.name, lang);
            }
        }
        plans.push({ platform, osAction, spAction, cmAction, hasOS, hasSP, hasCM });
    }
    const osToolIds = Array.from(new Set(plans.filter((p) => p.osAction !== 'skip').map((p) => p.platform.openspecToolId)));
    const spPlatformIds = plans.filter((p) => p.spAction !== 'skip').map((p) => p.platform.id);
    const selectedNpmDeps = await selectNpmDeps(projectPath, spPlatformIds, options, lang);
    const shouldInstallOpenSpecCli = selectedNpmDeps.has('openspec');
    const shouldInstallSuperpowers = selectedNpmDeps.has('superpowers');
    const shouldInstallCodegraphCli = selectedNpmDeps.has('codegraph');
    let osGlobalStatus = 'skipped';
    if (osToolIds.length > 0) {
        log(`\n  ${t(lang, 'installingOS')} ${osToolIds.join(', ')}`);
        osGlobalStatus = await installOpenSpec(projectPath, osToolIds, scope, shouldInstallOpenSpecCli);
        if (osGlobalStatus === 'skipped' && !shouldInstallOpenSpecCli) {
            log(`  OpenSpec: ${t(lang, 'osSkippedNoCli')}`);
        }
        else {
            log(`  OpenSpec: ${osGlobalStatus}`);
        }
    }
    else {
        log(`\n  OpenSpec: ${t(lang, 'allSkipped')}`);
    }
    let spGlobalStatus = 'skipped';
    if (spPlatformIds.length > 0) {
        if (!shouldInstallSuperpowers) {
            log(`\n  Superpowers: ${t(lang, 'spSkippedByUser')}`);
        }
        else {
            log(`\n  ${t(lang, 'installingSP')} ${spPlatformIds.join(', ')}`);
            spGlobalStatus = await installSuperpowersForPlatforms(projectPath, scope, spPlatformIds, true);
            log(`  Superpowers: ${spGlobalStatus}`);
        }
    }
    else {
        log(`\n  Superpowers: ${t(lang, 'allSkipped')}`);
    }
    const results = [];
    for (const plan of plans) {
        const { platform, cmAction } = plan;
        const platformSkillsDir = getPlatformSkillsDir(platform, scope);
        const skillsPath = `${scope === 'global' ? '~/' : ''}${platformSkillsDir}/skills/`;
        let cmStatus = 'skipped';
        if (cmAction !== 'skip') {
            const { copied } = await copyCometSkillsForPlatform(baseDir, platform, cmAction === 'overwrite', language.skillsDir, scope);
            cmStatus = copied > 0 ? 'installed' : 'skipped';
            log(`  Comet -> ${platform.name}: ${cmStatus} (${copied} files) -> ${skillsPath}`);
        }
        else {
            log(`  Comet -> ${platform.name}: skipped (${t(lang, 'alreadyExists')})`);
        }
        results.push({
            platform,
            openspec: osToolIds.includes(platform.openspecToolId) ? osGlobalStatus : 'skipped',
            superpowers: plan.spAction !== 'skip' ? spGlobalStatus : 'skipped',
            comet: cmStatus,
            codegraph: 'skipped',
        });
    }
    const codegraphAlreadyIndexed = hasCodegraphProjectIndex(projectPath);
    // JSON mode never installs CodeGraph interactively (matches pre-i18n behavior).
    // If the project already has a .codegraph/ index, skip.
    // Otherwise, only install when the user selected codegraph in the npm-deps prompt.
    const shouldInstallCodegraph = !options.json && !codegraphAlreadyIndexed && shouldInstallCodegraphCli;
    if (shouldInstallCodegraph) {
        log(`\n  ${t(lang, 'installingCG')}`);
        const cgGlobalStatus = await installCodegraph(projectPath, scope, true);
        log(`  CodeGraph: ${cgGlobalStatus}`);
        for (const r of results) {
            r.codegraph = cgGlobalStatus;
        }
    }
    else if (!options.json && codegraphAlreadyIndexed) {
        log('\n  CodeGraph: skipped (existing .codegraph index detected)');
    }
    else if (!options.json) {
        log(`\n  CodeGraph: ${t(lang, 'cgSkippedByUser')}`);
    }
    if (scope === 'project') {
        await createWorkingDirs(projectPath);
    }
    if (options.json) {
        console.log(JSON.stringify({
            projectPath,
            scope,
            language: language.id,
            selectedPlatforms: selectedPlatformIds,
            results: results.map((result) => ({
                platform: result.platform.id,
                platformName: result.platform.name,
                openspec: result.openspec,
                superpowers: result.superpowers,
                comet: result.comet,
                codegraph: result.codegraph,
            })),
            workingDirsCreated: scope === 'project',
        }, null, 2));
        return;
    }
    displaySummary(results, scope, lang);
}
export { applyBulkOverwriteChoice };
//# sourceMappingURL=init.js.map
__COMET_DIST_COMMANDS_INIT_JS__

cat > "$TARGET_DIR/dist/commands/status.js" <<'__COMET_DIST_COMMANDS_STATUS_JS__'
import path from 'path';
import { fileExists, readDir } from '../utils/file-system.js';
import { promises as fs } from 'fs';
function getNextCommand(phase) {
    switch (phase) {
        case 'open':
            return '/comet-open';
        case 'design':
            return '/comet-design';
        case 'build':
            return '/comet-build';
        case 'verify':
            return '/comet-verify';
        case 'archive':
            return '/comet-archive';
        default:
            return null;
    }
}
async function countTasks(tasksPath) {
    if (!(await fileExists(tasksPath)))
        return { done: 0, total: 0 };
    const content = await fs.readFile(tasksPath, 'utf-8');
    const lines = content.split('\n');
    const total = lines.filter((l) => /^\s*- \[[ x]\]/.test(l)).length;
    const done = lines.filter((l) => /^\s*- \[x\]/i.test(l)).length;
    return { done, total };
}
async function readCometState(changesDir, changeName) {
    const yamlPath = path.join(changesDir, changeName, '.comet.yaml');
    if (!(await fileExists(yamlPath)))
        return null;
    const raw = await fs.readFile(yamlPath, 'utf-8');
    const state = {};
    for (const line of raw.split('\n')) {
        const stripped = line.replace(/\s+#.*$/, '');
        const match = stripped.match(/^(\w[\w_]*):\s*(.*)/);
        if (match)
            state[match[1]] = match[2].trim();
    }
    return state;
}
async function getActiveChanges(projectPath) {
    const changesDir = path.join(projectPath, 'openspec', 'changes');
    if (!(await fileExists(changesDir)))
        return [];
    const entries = await readDir(changesDir);
    const changes = [];
    for (const entry of entries) {
        const changeDir = path.join(changesDir, entry);
        const stat = await fs.stat(changeDir);
        if (!stat.isDirectory())
            continue;
        const state = await readCometState(changesDir, entry);
        if (!state)
            continue;
        if (state.archived === 'true')
            continue;
        const { done, total } = await countTasks(path.join(changeDir, 'tasks.md'));
        changes.push({
            name: entry,
            workflow: state.workflow ?? 'full',
            phase: state.phase ?? 'unknown',
            buildMode: state.build_mode ?? 'null',
            isolation: state.isolation ?? 'null',
            verifyMode: state.verify_mode ?? 'null',
            verifyResult: state.verify_result ?? 'pending',
            designDoc: state.design_doc === 'null' ? null : (state.design_doc ?? null),
            plan: state.plan === 'null' ? null : (state.plan ?? null),
            tasksCompleted: done,
            tasksTotal: total,
            nextCommand: getNextCommand(state.phase ?? 'unknown'),
        });
    }
    return changes;
}
function displayStatus(changes) {
    if (changes.length === 0) {
        console.log('No active changes.\n');
        return;
    }
    console.log('Active Changes:\n');
    for (let i = 0; i < changes.length; i++) {
        const c = changes[i];
        const taskStr = c.tasksTotal > 0 ? ` [${c.tasksCompleted}/${c.tasksTotal} tasks]` : '';
        console.log(`  ${i + 1}. ${c.name} [phase: ${c.phase}${taskStr}]`);
        console.log(`     workflow: ${c.workflow} | build_mode: ${c.buildMode}`);
        if (c.designDoc)
            console.log(`     design: ${c.designDoc}`);
        if (c.plan)
            console.log(`     plan:   ${c.plan}`);
        if (c.phase === 'verify')
            console.log(`     verify_result: ${c.verifyResult}`);
        if (c.nextCommand)
            console.log(`     next: ${c.nextCommand}`);
        console.log();
    }
}
export async function statusCommand(targetPath, options = {}) {
    const projectPath = path.resolve(targetPath);
    const changes = await getActiveChanges(projectPath);
    if (options.json) {
        console.log(JSON.stringify({ changes }, null, 2));
        return;
    }
    displayStatus(changes);
}
//# sourceMappingURL=status.js.map
__COMET_DIST_COMMANDS_STATUS_JS__

cat > "$TARGET_DIR/dist/commands/uninstall.js" <<'__COMET_DIST_COMMANDS_UNINSTALL_JS__'
import path from 'path';
import { checkbox, select } from '@inquirer/prompts';
import { getBaseDir } from '../core/detect.js';
import { getPlatformSkillsDir } from '../core/platforms.js';
import { removeCometSkillsForPlatform, removeWorkingDirs, } from '../core/uninstall.js';
import { detectInstalledCometTargets } from './update.js';
export async function uninstallCommand(targetPath, options = {}) {
    const projectPath = path.resolve(targetPath);
    const log = options.json ? () => undefined : console.log;
    log(`\n  Comet Uninstall\n`);
    // 1. Detect installed targets
    const targets = await detectInstalledCometTargets(projectPath, {
        scopes: options.scope ? [options.scope] : undefined,
    });
    if (targets.length === 0) {
        if (options.json) {
            console.log(JSON.stringify({ targets: [], results: [] }, null, 2));
            return;
        }
        log('  No Comet installations found. Nothing to uninstall.\n');
        return;
    }
    // 2. Preview what will be removed
    const scopeLabel = (scope) => scope === 'global' ? 'global' : `project (${projectPath})`;
    log('  Found Comet installations on the following targets:\n');
    for (const target of targets) {
        const skillsDir = getPlatformSkillsDir(target.platform, target.scope);
        const prefix = target.scope === 'global' ? '~/' : '';
        log(`    ${target.platform.name} (${scopeLabel(target.scope)})`);
        log(`      Path: ${prefix}${skillsDir}/skills/`);
    }
    // 3. Let user select which targets to uninstall (unless --force)
    let selectedTargets = targets;
    if (!options.force && !options.json) {
        if (targets.length === 1) {
            const confirmed = await select({
                message: `Uninstall Comet from ${targets[0].platform.name} (${targets[0].scope})?`,
                choices: [
                    { name: 'Yes, uninstall', value: true },
                    { name: 'No, cancel', value: false },
                ],
            });
            if (!confirmed) {
                log('\n  Cancelled.\n');
                return;
            }
        }
        else {
            const selected = await checkbox({
                message: 'Select targets to uninstall:',
                choices: targets.map((t) => ({
                    name: `${t.platform.name} (${t.scope})`,
                    value: `${t.platform.id}:${t.scope}`,
                    checked: true,
                })),
                required: true,
            });
            selectedTargets = targets.filter((t) => selected.includes(`${t.platform.id}:${t.scope}`));
            if (selectedTargets.length === 0) {
                log('\n  No targets selected. Cancelled.\n');
                return;
            }
        }
    }
    // 4. Execute removal for each selected target
    log('');
    const results = [];
    let totalSkills = 0;
    for (const target of selectedTargets) {
        const baseDir = getBaseDir(target.scope, projectPath);
        const skillsResult = await removeCometSkillsForPlatform(baseDir, target.platform, target.scope);
        totalSkills += skillsResult.removed;
        log(`  ${target.platform.name} (${target.scope}): ${skillsResult.removed} skills removed`);
        results.push({
            scope: target.scope,
            platform: target.platform.id,
            platformName: target.platform.name,
            skillsRemoved: skillsResult.removed,
            workingDirsRemoved: 0,
        });
    }
    // 5. Working directories (project scope only)
    let workingDirsRemoved = 0;
    const hasProjectScope = selectedTargets.some((t) => t.scope === 'project');
    if (hasProjectScope) {
        const dirsResult = await removeWorkingDirs(projectPath);
        workingDirsRemoved = dirsResult.removed;
        if (workingDirsRemoved > 0) {
            log(`  Working directories: ${workingDirsRemoved} removed`);
        }
    }
    // 6. Summary
    if (options.json) {
        console.log(JSON.stringify({
            targets: results.map((r) => ({
                scope: r.scope,
                platform: r.platform,
                platformName: r.platformName,
                skillsRemoved: r.skillsRemoved,
            })),
            workingDirsRemoved,
            summary: {
                targetsProcessed: results.length,
                totalSkillsRemoved: totalSkills,
            },
        }, null, 2));
        return;
    }
    log(`\n  Summary:`);
    log(`    Targets: ${results.length}`);
    log(`    Skills removed: ${totalSkills}`);
    log(`\n  Uninstall complete.\n`);
}
//# sourceMappingURL=uninstall.js.map
__COMET_DIST_COMMANDS_UNINSTALL_JS__

cat > "$TARGET_DIR/dist/commands/update.js" <<'__COMET_DIST_COMMANDS_UPDATE_JS__'
import path from 'path';
import os from 'os';
import { promises as fs } from 'fs';
import { fileURLToPath } from 'url';
import { spawn } from 'child_process';
import { select } from '@inquirer/prompts';
import { fileExists, readDir, readJson } from '../utils/file-system.js';
import { getBaseDir } from '../core/detect.js';
import { copyCometSkillsForPlatform, getManifestSkills, } from '../core/skills.js';
import { PLATFORMS, getPlatformSkillsDir } from '../core/platforms.js';
import { hasCodegraphProjectIndex, installCodegraph } from '../core/codegraph.js';
import { printVersionInfo } from '../core/version.js';
import { t } from './i18n.js';
const PACKAGE_NAME = '@rpamis/comet';
const OFFICIAL_REGISTRY = 'https://registry.npmjs.org';
function languageToSkillsDir(_language, _fallback) {
    return 'skills-zh';
}
function getScopedBaseDir(scope, projectPath, globalBaseDir = os.homedir()) {
    return scope === 'global' ? globalBaseDir : projectPath;
}
function getInstalledCometSkillsDirs(baseDir, platform, scope = 'project') {
    return [path.join(baseDir, getPlatformSkillsDir(platform, scope), 'skills')];
}
async function hasLocalCometSkills(baseDir, platform, scope) {
    for (const skillsDir of getInstalledCometSkillsDirs(baseDir, platform, scope)) {
        if (!(await fileExists(skillsDir)))
            continue;
        const entries = await readDir(skillsDir);
        if (entries.some((entry) => entry.startsWith('comet')))
            return true;
    }
    return false;
}
async function detectInstalledCometLanguage(baseDir, platform, scope = 'project') {
    for (const skillsDir of getInstalledCometSkillsDirs(baseDir, platform, scope)) {
        if (!(await fileExists(skillsDir)))
            continue;
        const entries = (await readDir(skillsDir)).filter((entry) => entry.startsWith('comet'));
        for (const entry of entries) {
            const skillPath = path.join(skillsDir, entry, 'SKILL.md');
            if (!(await fileExists(skillPath)))
                continue;
            try {
                const content = await fs.readFile(skillPath, 'utf-8');
                if (/[㐀-鿿]/u.test(content))
                    return 'zh';
            }
            catch {
                // Ignore unreadable files and keep the default zh fallback.
            }
        }
    }
    return 'zh';
}
async function detectInstalledCometTargets(projectPath, options = {}) {
    const scopes = options.scopes ?? ['project', 'global'];
    const targets = [];
    for (const scope of scopes) {
        const baseDir = getScopedBaseDir(scope, projectPath, options.globalBaseDir);
        for (const platform of PLATFORMS) {
            if (!(await hasLocalCometSkills(baseDir, platform, scope)))
                continue;
            targets.push({
                scope,
                platform,
                language: await detectInstalledCometLanguage(baseDir, platform, scope),
            });
        }
    }
    return targets;
}
function isSameOrInside(childPath, parentPath) {
    const relative = path.relative(path.resolve(parentPath), path.resolve(childPath));
    return relative === '' || (!relative.startsWith('..') && !path.isAbsolute(relative));
}
async function detectCometPackageScope(projectPath, packageRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..', '..')) {
    const localPackageRoot = path.join(projectPath, 'node_modules', '@rpamis', 'comet');
    if (isSameOrInside(packageRoot, localPackageRoot))
        return 'project';
    const packageJsonPath = path.join(projectPath, 'package.json');
    if (await fileExists(packageJsonPath)) {
        const pkg = await readJson(packageJsonPath);
        if (pkg.dependencies?.[PACKAGE_NAME] ||
            pkg.devDependencies?.[PACKAGE_NAME] ||
            pkg.optionalDependencies?.[PACKAGE_NAME]) {
            return 'project';
        }
    }
    return 'global';
}
function buildNpmUpdateArgs(scope) {
    return scope === 'global'
        ? ['install', '-g', `${PACKAGE_NAME}@latest`, '--registry', OFFICIAL_REGISTRY]
        : ['install', `${PACKAGE_NAME}@latest`, '--registry', OFFICIAL_REGISTRY];
}
function formatNpmUpdateCommand(scope) {
    return ['npm', ...buildNpmUpdateArgs(scope)].join(' ');
}
function formatSkillUpdateCommand(scope, platform, languageSkillsDir) {
    const destPrefix = scope === 'global' ? '~/' : '';
    return `copy assets/${languageSkillsDir} -> ${destPrefix}${getPlatformSkillsDir(platform, scope)}/skills/ (${scope})`;
}
function getNpmExecutable() {
    return process.platform === 'win32' ? 'npm.cmd' : 'npm';
}
async function updateCometNpmPackage(scope, projectPath, log, jsonMode = false) {
    const args = buildNpmUpdateArgs(scope);
    const cwd = scope === 'global' ? process.cwd() : projectPath;
    return new Promise((resolve) => {
        // In JSON mode, discard npm's stdout/stderr so it cannot corrupt the JSON
        // document emitted on stdout. 'ignore' avoids the pipe backpressure a
        // verbose npm install could otherwise cause.
        const child = spawn(getNpmExecutable(), args, {
            cwd,
            stdio: jsonMode ? 'ignore' : 'inherit',
            shell: true,
        });
        child.on('error', (err) => {
            log(`  npm package: failed to launch npm — ${err.message}`);
            resolve(false);
        });
        child.on('exit', (code) => {
            if (code !== 0) {
                log(`  npm package: update failed (exit code ${code}). Unable to reach the official npm registry at ${OFFICIAL_REGISTRY}.`);
                log(`  Check your network connection or firewall settings and try again.`);
            }
            resolve(code === 0);
        });
    });
}
async function promptCodegraphInstall(lang) {
    return select({
        message: t(lang, 'installCodegraph'),
        choices: [
            { name: t(lang, 'codegraphYes'), value: true },
            { name: t(lang, 'codegraphNo'), value: false },
        ],
    });
}
export async function updateCommand(targetPath, options = {}) {
    const projectPath = path.resolve(targetPath);
    const log = options.json ? () => undefined : console.log;
    const lang = 'zh';
    log(`\n  ${t(lang, 'updateTitle')}`);
    if (!options.json) {
        await printVersionInfo(log);
    }
    log('');
    const packageScope = options.scope ?? (await detectCometPackageScope(projectPath));
    let npmStatus = 'skipped';
    if (!options.skipNpm) {
        log(`  ${t(lang, 'updatingNpmPackage')} (${packageScope} scope)...`);
        log(`    $ ${formatNpmUpdateCommand(packageScope)}`);
        const npmUpdated = await updateCometNpmPackage(packageScope, projectPath, log, options.json === true);
        if (npmUpdated) {
            npmStatus = 'updated';
            log(`  ${t(lang, 'npmPackageUpdated')} ${PACKAGE_NAME}`);
        }
        else {
            npmStatus = 'failed';
            log(`  ${t(lang, 'npmPackageFailed')}`);
        }
    }
    const targets = await detectInstalledCometTargets(projectPath, {
        scopes: options.scope ? [options.scope] : undefined,
    });
    if (targets.length === 0) {
        if (options.json) {
            console.log(JSON.stringify({
                npm: {
                    scope: options.skipNpm ? 'skipped' : packageScope,
                    status: npmStatus,
                    command: options.skipNpm ? null : formatNpmUpdateCommand(packageScope),
                },
                skills: { totalCopied: 0, targets: [] },
                codegraph: 'skipped',
            }, null, 2));
            return;
        }
        log(`\n  ${t(lang, 'noInstallsFound')}\n`);
        return;
    }
    log(`\n  ${t(lang, 'updatingSkillsOnTargets')} ${targets.length} target(s):`);
    for (const target of targets) {
        const language = target.language;
        const scopeLabel = target.scope === 'global' ? 'global' : `project (${projectPath})`;
        const languageSkillsDir = languageToSkillsDir(undefined, target.language);
        log(`    - ${target.platform.name} (${scopeLabel}, ${language})`);
        log(`      $ ${formatSkillUpdateCommand(target.scope, target.platform, languageSkillsDir)}`);
    }
    log(`\n  ${t(lang, 'copyingSkillsFiles')} ${(await getManifestSkills()).length} skill files...\n`);
    let totalCopied = 0;
    const targetResults = [];
    for (const target of targets) {
        const baseDir = getBaseDir(target.scope, projectPath);
        const languageSkillsDir = languageToSkillsDir(undefined, target.language);
        const { copied, skipped } = await copyCometSkillsForPlatform(baseDir, target.platform, true, languageSkillsDir, target.scope);
        totalCopied += copied;
        targetResults.push({
            scope: target.scope,
            platform: target.platform.id,
            platformName: target.platform.name,
            language: target.language,
            source: languageSkillsDir,
            copied,
            skipped,
            command: formatSkillUpdateCommand(target.scope, target.platform, languageSkillsDir),
        });
        log(`  ${target.platform.name} (${target.scope}, ${languageSkillsDir}): ${copied} ${t(lang, 'skillsCopiedSkipped')} ${skipped} skipped`);
    }
    let codegraphStatus = 'skipped';
    const primaryScope = targets[0]?.scope ?? 'project';
    const codegraphAlreadyIndexed = hasCodegraphProjectIndex(projectPath);
    if (options.json) {
        codegraphStatus = 'skipped';
    }
    else if (codegraphAlreadyIndexed) {
        log('\n  CodeGraph: skipped (existing .codegraph index detected)');
    }
    else {
        const shouldInstallCodegraph = options.skipNpm ? false : await promptCodegraphInstall(lang);
        if (shouldInstallCodegraph) {
            log(`\n  ${t(lang, 'installingCG')}`);
            codegraphStatus = await installCodegraph(projectPath, primaryScope, true);
            log(`  CodeGraph: ${codegraphStatus}`);
        }
        else {
            log(`\n  CodeGraph: ${t(lang, 'cgSkippedByUser')}`);
        }
    }
    if (options.json) {
        console.log(JSON.stringify({
            npm: {
                scope: options.skipNpm ? 'skipped' : packageScope,
                status: npmStatus,
                command: options.skipNpm ? null : formatNpmUpdateCommand(packageScope),
            },
            skills: {
                totalCopied,
                targets: targetResults,
            },
            codegraph: codegraphStatus,
        }, null, 2));
        return;
    }
    const languages = [...new Set(targetResults.map((target) => target.language))].join(', ');
    const scopes = [...new Set(targetResults.map((target) => target.scope))].join(', ');
    log(`\n  ${t(lang, 'summary')}`);
    log(`    ${t(lang, 'summaryNpm')} ${npmStatus}${options.skipNpm ? '' : ` (${packageScope})`}`);
    log(`    ${t(lang, 'summarySkills')} ${targets.length} target(s), ${totalCopied} files updated`);
    log(`    ${t(lang, 'summaryCodegraph')} ${codegraphStatus}`);
    log(`    ${t(lang, 'summaryScope')} ${scopes}`);
    log(`    ${t(lang, 'summaryLanguage')} ${languages}`);
    log(`\n  ${t(lang, 'updateComplete')}\n`);
}
export { buildNpmUpdateArgs, detectCometPackageScope, detectInstalledCometLanguage, detectInstalledCometTargets, formatNpmUpdateCommand, formatSkillUpdateCommand, };
//# sourceMappingURL=update.js.map
__COMET_DIST_COMMANDS_UPDATE_JS__

cat > "$TARGET_DIR/dist/core/codegraph.js" <<'__COMET_DIST_CORE_CODEGRAPH_JS__'
import { execFileSync } from 'child_process';
import fs from 'fs';
import path from 'path';
import { isCommandAvailable, getNpmExecutable } from './openspec.js';
import { printCommandErrorDetails } from './command-error.js';
function getPnpmExecutable(platform = process.platform) {
    return platform === 'win32' ? 'pnpm.cmd' : 'pnpm';
}
function hasCodegraphProjectIndex(projectPath) {
    const codegraphDir = path.join(projectPath, '.codegraph');
    try {
        if (!fs.statSync(codegraphDir).isDirectory())
            return false;
        return fs.readdirSync(codegraphDir).some((entry) => entry !== '.gitignore');
    }
    catch {
        return false;
    }
}
function resolvePnpmGlobalCommand(command) {
    try {
        const binDir = execFileSync(getPnpmExecutable(), ['bin', '-g'], {
            encoding: 'utf-8',
            stdio: ['ignore', 'pipe', 'ignore'],
            timeout: 10_000,
            shell: process.platform === 'win32',
        }).trim();
        if (!binDir)
            return null;
        const candidates = process.platform === 'win32'
            ? [`${command}.cmd`, `${command}.exe`, `${command}.ps1`, command]
            : [command];
        for (const candidate of candidates) {
            const candidatePath = path.join(binDir, candidate);
            if (fs.existsSync(candidatePath))
                return candidatePath;
        }
    }
    catch {
        // pnpm may not be installed or may not have a global bin configured.
    }
    return null;
}
function resolveCodegraphCommand() {
    if (isCommandAvailable('codegraph'))
        return 'codegraph';
    return resolvePnpmGlobalCommand('codegraph');
}
async function ensureCodegraphCli(projectPath, shouldInstall = true) {
    const existingCommand = resolveCodegraphCommand();
    if (existingCommand)
        return existingCommand;
    if (!shouldInstall)
        return null;
    console.log('    Installing CodeGraph CLI...');
    try {
        execFileSync(getNpmExecutable(), ['install', '-g', '@colbymchenry/codegraph'], {
            cwd: projectPath,
            stdio: 'inherit',
            timeout: 180_000,
            shell: process.platform === 'win32',
        });
        return resolveCodegraphCommand();
    }
    catch (error) {
        console.error(`    Failed to install CodeGraph CLI: ${error.message}`);
        printCommandErrorDetails(error);
        return null;
    }
}
async function installCodegraph(projectPath, scope, shouldInstallCli = true) {
    if (hasCodegraphProjectIndex(projectPath)) {
        console.log('    CodeGraph: existing .codegraph index detected');
        return 'skipped';
    }
    const codegraphCommand = await ensureCodegraphCli(projectPath, shouldInstallCli);
    if (!codegraphCommand) {
        if (!shouldInstallCli) {
            console.log('    CodeGraph CLI not installed, skipping setup');
            return 'skipped';
        }
        console.error('    CodeGraph CLI not available. Install manually: npm install -g @colbymchenry/codegraph');
        return 'failed';
    }
    try {
        console.log('    Running: codegraph install --yes');
        execFileSync(codegraphCommand, ['install', '--yes'], {
            cwd: projectPath,
            stdio: 'inherit',
            timeout: 120_000,
            shell: process.platform === 'win32',
        });
    }
    catch (error) {
        console.error(`    CodeGraph install failed: ${error.message}`);
        printCommandErrorDetails(error);
        return 'failed';
    }
    if (scope === 'project') {
        try {
            console.log('    Running: codegraph init -i');
            execFileSync(codegraphCommand, ['init', '-i'], {
                cwd: projectPath,
                stdio: 'inherit',
                timeout: 300_000,
                shell: process.platform === 'win32',
            });
        }
        catch (error) {
            console.error(`    CodeGraph init failed: ${error.message}`);
            printCommandErrorDetails(error);
            return 'failed';
        }
    }
    return 'installed';
}
export { installCodegraph, hasCodegraphProjectIndex, resolveCodegraphCommand };
//# sourceMappingURL=codegraph.js.map
__COMET_DIST_CORE_CODEGRAPH_JS__

cat > "$TARGET_DIR/dist/core/command-error.js" <<'__COMET_DIST_CORE_COMMAND_ERROR_JS__'
const ESC = String.fromCharCode(27);
const ANSI_ESCAPE_PATTERN = new RegExp(`${ESC}\\[[0-9;?]*[a-zA-Z]`, 'g');
const LOOSE_ESCAPE_PATTERN = new RegExp(`${ESC}\\[[^a-zA-Z\\r\\n]*`, 'g');
function streamToText(stream) {
    if (!stream)
        return '';
    return Buffer.isBuffer(stream) ? stream.toString() : stream;
}
function cleanCommandOutput(output) {
    return output
        .replace(ANSI_ESCAPE_PATTERN, '')
        .replace(LOOSE_ESCAPE_PATTERN, '')
        .split('\n')
        .map((line) => line.trimEnd())
        .filter((line) => line.trim() && !/^(│|├|╮|╯|●|◇|◒|◐|◓|◑|■)/.test(line.trim()))
        .join('\n')
        .trim();
}
function formatCommandErrorDetails(error) {
    const details = [];
    if (!error || typeof error !== 'object') {
        details.push('Unknown error occurred');
        return details;
    }
    const commandError = error;
    for (const [label, stream] of [
        ['stderr', commandError.stderr],
        ['stdout', commandError.stdout],
    ]) {
        const cleaned = cleanCommandOutput(streamToText(stream));
        if (cleaned) {
            details.push(`${label}:\n${cleaned}`);
        }
    }
    if (details.length === 0) {
        const reason = commandError.killed
            ? 'Process was killed (likely timed out)'
            : commandError.code === 'ETIMEDOUT'
                ? 'Process timed out'
                : commandError.code === 'ENOENT'
                    ? 'Command not found — check that the required CLI is installed and on PATH'
                    : 'No error output captured';
        details.push(reason);
    }
    return details;
}
function printCommandErrorDetails(error, indent = '    ') {
    for (const detail of formatCommandErrorDetails(error)) {
        console.error(`${indent}${detail.split('\n').join(`\n${indent}`)}`);
    }
}
export { printCommandErrorDetails, formatCommandErrorDetails };
//# sourceMappingURL=command-error.js.map
__COMET_DIST_CORE_COMMAND_ERROR_JS__

cat > "$TARGET_DIR/dist/core/detect.js" <<'__COMET_DIST_CORE_DETECT_JS__'
import path from 'path';
import os from 'os';
import { fileExists, readDir, readJson } from '../utils/file-system.js';
import { PLATFORMS, getPlatformSkillsDirs } from './platforms.js';
const SUPERPOWERS_SKILLS = [
    'brainstorming',
    'using-superpowers',
    'writing-plans',
    'test-driven-development',
    'subagent-driven-development',
];
function getBaseDir(scope, projectPath) {
    return scope === 'global' ? os.homedir() : projectPath;
}
async function hasOpenCodePluginSuperpowers() {
    const opencodeDir = process.env.OPENCODE_CONFIG_DIR || path.join(os.homedir(), '.config', 'opencode');
    // Check plugin source directory: ~/.config/opencode/superpowers/skills/
    const pluginSkillsDir = path.join(opencodeDir, 'superpowers', 'skills');
    if (await fileExists(pluginSkillsDir)) {
        const skills = await readDir(pluginSkillsDir);
        if (SUPERPOWERS_SKILLS.some((name) => skills.includes(name))) {
            return true;
        }
    }
    // Check opencode.json config for superpowers plugin entry
    const configPath = path.join(opencodeDir, 'opencode.json');
    if (await fileExists(configPath)) {
        try {
            const config = (await readJson(configPath));
            const plugins = config.plugin;
            if (Array.isArray(plugins)) {
                if (plugins.some((entry) => typeof entry === 'string' && entry.includes('superpowers'))) {
                    return true;
                }
            }
        }
        catch {
            // Invalid JSON or unreadable — skip
        }
    }
    return false;
}
async function hasOpenCodeCometCommands(baseDir, skillsDir, entries) {
    const cometEntries = entries.filter((entry) => entry.startsWith('comet'));
    if (cometEntries.length === 0)
        return false;
    const commandsDir = path.join(baseDir, skillsDir, 'commands');
    const commandEntries = await readDir(commandsDir);
    return cometEntries.every((entry) => commandEntries.includes(`${entry}.md`));
}
async function detectPlatforms(projectPath) {
    const detected = new Set();
    const platform = PLATFORMS[0];
    for (const skillsDir of getPlatformSkillsDirs(platform, 'project')) {
        const dirPath = path.join(projectPath, skillsDir);
        if (await fileExists(dirPath)) {
            detected.add(platform.id);
            break;
        }
    }
    return detected;
}
async function hasSkills(baseDir, platform, component, _selectedPlatforms = [], scope = 'project') {
    const skillDirEntries = await Promise.all(getPlatformSkillsDirs(platform, scope).map(async (skillsDir) => {
        const fullPath = path.join(baseDir, skillsDir, 'skills');
        return {
            skillsDir,
            entries: (await fileExists(fullPath)) ? await readDir(fullPath) : [],
        };
    }));
    const entries = skillDirEntries.flatMap((dir) => dir.entries);
    switch (component) {
        case 'openspec':
            if (entries.some((e) => e.startsWith('openspec-')))
                return true;
            break;
        case 'superpowers':
            if (SUPERPOWERS_SKILLS.some((name) => entries.includes(name)))
                return true;
            break;
        case 'comet':
            if (platform.id === 'opencode') {
                for (const dir of skillDirEntries) {
                    if (await hasOpenCodeCometCommands(baseDir, dir.skillsDir, dir.entries))
                        return true;
                }
                break;
            }
            if (entries.some((e) => e.startsWith('comet')))
                return true;
            break;
    }
    if (scope === 'project' && baseDir !== os.homedir()) {
        const globalSkillDirEntries = await Promise.all(getPlatformSkillsDirs(platform, 'global').map(async (skillsDir) => {
            const fullPath = path.join(os.homedir(), skillsDir, 'skills');
            return {
                skillsDir,
                entries: (await fileExists(fullPath)) ? await readDir(fullPath) : [],
            };
        }));
        const globalEntries = globalSkillDirEntries.flatMap((dir) => dir.entries);
        switch (component) {
            case 'openspec':
                if (globalEntries.some((e) => e.startsWith('openspec-')))
                    return true;
                break;
            case 'superpowers':
                if (SUPERPOWERS_SKILLS.some((name) => globalEntries.includes(name)))
                    return true;
                break;
            case 'comet':
                if (platform.id === 'opencode') {
                    for (const dir of globalSkillDirEntries) {
                        if (await hasOpenCodeCometCommands(os.homedir(), dir.skillsDir, dir.entries)) {
                            return true;
                        }
                    }
                    break;
                }
                if (globalEntries.some((e) => e.startsWith('comet')))
                    return true;
                break;
        }
    }
    // Check OpenCode plugin system for plugin-installed superpowers
    if (component === 'superpowers' && platform.id === 'opencode') {
        if (await hasOpenCodePluginSuperpowers())
            return true;
    }
    return false;
}
export { detectPlatforms, hasSkills, hasOpenCodePluginSuperpowers, getBaseDir, };
//# sourceMappingURL=detect.js.map
__COMET_DIST_CORE_DETECT_JS__

cat > "$TARGET_DIR/dist/core/openspec.js" <<'__COMET_DIST_CORE_OPENSPEC_JS__'
import { execFileSync } from 'child_process';
import fs from 'fs';
import os from 'os';
import path from 'path';
import { PLATFORMS } from './platforms.js';
import { printCommandErrorDetails } from './command-error.js';
const VALID_TOOL_IDS = new Set(PLATFORMS.map((p) => p.openspecToolId));
const ALL_OPENSPEC_WORKFLOWS = [
    'propose',
    'explore',
    'new',
    'continue',
    'apply',
    'ff',
    'sync',
    'archive',
    'bulk-archive',
    'verify',
    'onboard',
];
function getNpmExecutable(platform = process.platform) {
    return platform === 'win32' ? 'npm.cmd' : 'npm';
}
function buildOpenSpecInitInvocation(projectPath, toolIds, scope, homeDir = os.homedir(), includeProfileFlag = true) {
    const targetPath = scope === 'global' ? homeDir : projectPath;
    const args = ['init', targetPath, '--tools', toolIds.join(',')];
    if (includeProfileFlag) {
        args.push('--profile', 'custom');
    }
    return { command: 'openspec', args };
}
const ALL_WORKFLOWS_CONFIG = JSON.stringify({
    featureFlags: {},
    profile: 'custom',
    delivery: 'both',
    workflows: [...ALL_OPENSPEC_WORKFLOWS],
}, null, 2) + '\n';
function getOpenSpecDefaultConfigDir() {
    const platform = os.platform();
    if (platform === 'win32') {
        const appData = process.env.APPDATA;
        if (appData) {
            return path.join(appData, 'openspec');
        }
        return path.join(os.homedir(), 'AppData', 'Roaming', 'openspec');
    }
    const xdgConfig = process.env.XDG_CONFIG_HOME;
    if (xdgConfig) {
        return path.join(xdgConfig, 'openspec');
    }
    return path.join(os.homedir(), '.config', 'openspec');
}
function getOpenSpecDefaultConfigPath() {
    return path.join(getOpenSpecDefaultConfigDir(), 'config.json');
}
function createOpenSpecAllWorkflowsEnv() {
    const configHome = fs.mkdtempSync(path.join(os.tmpdir(), 'comet-openspec-profile-'));
    try {
        const openspecConfigDir = path.join(configHome, 'openspec');
        fs.mkdirSync(openspecConfigDir, { recursive: true });
        fs.writeFileSync(path.join(openspecConfigDir, 'config.json'), ALL_WORKFLOWS_CONFIG, 'utf-8');
        return {
            configHome,
            env: {
                ...process.env,
                XDG_CONFIG_HOME: configHome,
            },
        };
    }
    catch (error) {
        fs.rmSync(configHome, { recursive: true, force: true });
        throw error;
    }
}
function writeAllWorkflowsToDefaultConfig() {
    const configPath = getOpenSpecDefaultConfigPath();
    const backupPath = configPath + '.comet-backup';
    let hadExisting = false;
    try {
        hadExisting = fs.existsSync(configPath);
        if (hadExisting) {
            fs.copyFileSync(configPath, backupPath);
        }
        const configDir = path.dirname(configPath);
        if (!fs.existsSync(configDir)) {
            fs.mkdirSync(configDir, { recursive: true });
        }
        fs.writeFileSync(configPath, ALL_WORKFLOWS_CONFIG, 'utf-8');
        return { configPath, backupPath, hadExisting };
    }
    catch {
        if (hadExisting) {
            try {
                fs.unlinkSync(backupPath);
            }
            catch {
                // Best-effort cleanup
            }
        }
        return null;
    }
}
function restoreDefaultConfig(backup) {
    if (!backup)
        return;
    try {
        if (backup.hadExisting) {
            fs.copyFileSync(backup.backupPath, backup.configPath);
            fs.unlinkSync(backup.backupPath);
        }
        else {
            if (fs.existsSync(backup.configPath)) {
                fs.unlinkSync(backup.configPath);
            }
        }
    }
    catch {
        // Best-effort restore
    }
}
function isCommandAvailable(command) {
    try {
        const checker = process.platform === 'win32' ? 'where' : 'which';
        execFileSync(checker, [command], { stdio: 'ignore', timeout: 10_000 });
        return true;
    }
    catch {
        return false;
    }
}
async function ensureOpenSpecCli(scope, projectPath, shouldInstall = true) {
    const alreadyInstalled = isCommandAvailable('openspec');
    if (!shouldInstall) {
        return alreadyInstalled ? 'ready' : 'missing';
    }
    const label = alreadyInstalled ? 'Upgrading' : 'Installing';
    console.warn(`    ${label} OpenSpec CLI...`);
    try {
        const npmArgs = scope === 'global'
            ? ['install', '-g', '@fission-ai/openspec@latest']
            : ['install', '@fission-ai/openspec@latest'];
        execFileSync(getNpmExecutable(), npmArgs, {
            cwd: projectPath,
            stdio: 'inherit',
            timeout: 120_000,
            shell: process.platform === 'win32',
        });
        return isCommandAvailable('openspec') ? 'ready' : 'failed';
    }
    catch (error) {
        if (alreadyInstalled) {
            console.warn(`    OpenSpec upgrade failed, using existing version: ${error.message}`);
            return 'ready';
        }
        console.error(`    Failed to install OpenSpec CLI: ${error.message}`);
        printCommandErrorDetails(error);
        return 'failed';
    }
}
function migrateOpenCodeOpenSpecPaths(homeDir) {
    const opencodePlatform = PLATFORMS.find((p) => p.id === 'opencode');
    if (!opencodePlatform?.globalSkillsDir)
        return;
    // OpenSpec hardcodes skillsDir as '.opencode' in its AI_TOOLS, so it writes
    // to ~/.opencode/ even for global installs. OpenCode actually reads from
    // ~/.config/opencode/ (Comet's globalSkillsDir). Move the files over.
    const wrongDir = path.join(homeDir, opencodePlatform.skillsDir);
    const correctDir = path.join(homeDir, opencodePlatform.globalSkillsDir);
    const migrations = [
        [path.join(wrongDir, 'skills'), path.join(correctDir, 'skills'), 'skills'],
        [path.join(wrongDir, 'commands'), path.join(correctDir, 'commands'), 'commands'],
    ];
    for (const [srcDir, destDir, label] of migrations) {
        if (srcDir === destDir)
            continue;
        if (!fs.existsSync(srcDir))
            continue;
        try {
            const entries = fs.readdirSync(srcDir);
            if (entries.length === 0)
                continue;
            fs.mkdirSync(destDir, { recursive: true });
            for (const entry of entries) {
                const srcPath = path.join(srcDir, entry);
                const destPath = path.join(destDir, entry);
                fs.cpSync(srcPath, destPath, { recursive: true, force: true });
            }
            fs.rmSync(srcDir, { recursive: true, force: true });
        }
        catch (error) {
            console.error(`    Warning: failed to migrate OpenSpec ${label} from ${srcDir} to ${destDir}: ${error.message}`);
        }
    }
    // Remove wrong parent directory if both skills and commands have been migrated
    if (fs.existsSync(wrongDir)) {
        try {
            const remaining = fs.readdirSync(wrongDir);
            if (remaining.length === 0) {
                fs.rmdirSync(wrongDir);
            }
        }
        catch {
            // Best-effort cleanup
        }
    }
}
async function installOpenSpec(projectPath, toolIds, scope, shouldInstallCli = true) {
    const cliStatus = await ensureOpenSpecCli(scope, projectPath, shouldInstallCli);
    if (cliStatus === 'failed') {
        console.error(`    OpenSpec CLI not available. Install manually: npm install -g @fission-ai/openspec@latest`);
        return 'failed';
    }
    if (cliStatus === 'missing') {
        return 'skipped';
    }
    const unknownIds = toolIds.filter((id) => !VALID_TOOL_IDS.has(id));
    if (unknownIds.length > 0) {
        throw new Error(`Unknown tool IDs: ${unknownIds.join(', ')}`);
    }
    let configHome;
    let configBackup = null;
    try {
        const openspecEnv = createOpenSpecAllWorkflowsEnv();
        configHome = openspecEnv.configHome;
        configBackup = writeAllWorkflowsToDefaultConfig();
        const invocation = buildOpenSpecInitInvocation(projectPath, toolIds, scope);
        try {
            execFileSync(invocation.command, invocation.args, {
                cwd: projectPath,
                env: openspecEnv.env,
                stdio: ['inherit', 'inherit', 'pipe'],
                timeout: 120_000,
                shell: process.platform === 'win32',
            });
        }
        catch (firstError) {
            const stderrText = firstError.stderr?.toString() ?? '';
            if (stderrText.includes('unknown option') && stderrText.includes('--profile')) {
                console.warn('    OpenSpec does not support --profile flag, retrying without it...');
                const fallbackInvocation = buildOpenSpecInitInvocation(projectPath, toolIds, scope, os.homedir(), false);
                execFileSync(fallbackInvocation.command, fallbackInvocation.args, {
                    cwd: projectPath,
                    env: openspecEnv.env,
                    stdio: 'inherit',
                    timeout: 120_000,
                    shell: process.platform === 'win32',
                });
            }
            else {
                throw firstError;
            }
        }
        if (scope === 'global' && toolIds.includes('opencode')) {
            migrateOpenCodeOpenSpecPaths(os.homedir());
        }
        return 'installed';
    }
    catch (error) {
        console.error(`    OpenSpec init failed: ${error.message}`);
        printCommandErrorDetails(error);
        return 'failed';
    }
    finally {
        restoreDefaultConfig(configBackup);
        if (configHome) {
            fs.rmSync(configHome, { recursive: true, force: true });
        }
    }
}
export { installOpenSpec, isCommandAvailable, buildOpenSpecInitInvocation, getNpmExecutable, migrateOpenCodeOpenSpecPaths, };
//# sourceMappingURL=openspec.js.map
__COMET_DIST_CORE_OPENSPEC_JS__

cat > "$TARGET_DIR/dist/core/platforms.js" <<'__COMET_DIST_CORE_PLATFORMS_JS__'
/**
 * Platform Definitions
 *
 * Supported AI coding platforms, mirroring OpenSpec's AI_TOOLS config.
 * Reference: OpenSpec/src/core/config.ts
 */
export function getPlatformSkillsDir(platform, scope) {
    if (scope === 'global' && platform.globalSkillsDir) {
        return platform.globalSkillsDir;
    }
    return platform.skillsDir;
}
export function getPlatformSkillsDirs(platform, scope) {
    return [getPlatformSkillsDir(platform, scope)];
}
export const PLATFORMS = [
    {
        id: 'opencode',
        name: 'OpenCode',
        skillsDir: '.opencode',
        globalSkillsDir: '.config/opencode',
        openspecToolId: 'opencode',
    },
];
//# sourceMappingURL=platforms.js.map
__COMET_DIST_CORE_PLATFORMS_JS__

cat > "$TARGET_DIR/dist/core/skills.js" <<'__COMET_DIST_CORE_SKILLS_JS__'
import path from 'path';
import { readFile, writeFile } from 'fs/promises';
import { fileURLToPath } from 'url';
import { fileExists, readJson, copyFile, ensureDir } from '../utils/file-system.js';
import { getPlatformSkillsDir } from './platforms.js';
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const OPENCODE_COMMAND_HEADER = `---
description: Run the {skillName} Comet workflow
---
`;
function getAssetsDir() {
    return path.resolve(__dirname, '..', '..', 'assets');
}
function stripFrontmatter(content) {
    if (!content.startsWith('---\n') && !content.startsWith('---\r\n')) {
        return content.trimStart();
    }
    const normalized = content.replace(/\r\n/g, '\n');
    const end = normalized.indexOf('\n---\n', 4);
    if (end === -1)
        return content.trimStart();
    return normalized.slice(end + '\n---\n'.length).trimStart();
}
async function createOpenCodeCommands(baseDir, platform, skillPaths, overwrite, scope, languageSkillsDir) {
    let copied = 0;
    let skipped = 0;
    const assetsDir = getAssetsDir();
    const commandsDir = path.join(baseDir, getPlatformSkillsDir(platform, scope), 'commands');
    for (const skillPath of skillPaths) {
        const parts = skillPath.split('/');
        if (parts.length !== 2 || parts[1] !== 'SKILL.md')
            continue;
        const skillName = parts[0];
        const dest = path.join(commandsDir, `${skillName}.md`);
        if (!overwrite && (await fileExists(dest))) {
            skipped++;
            continue;
        }
        await ensureDir(path.dirname(dest));
        let skillSourcePath = path.join(assetsDir, languageSkillsDir, skillPath);
        if (!(await fileExists(skillSourcePath))) {
            skillSourcePath = path.join(assetsDir, 'skills', skillPath);
        }
        const skillBody = stripFrontmatter(await readFile(skillSourcePath, 'utf-8'));
        const content = `${OPENCODE_COMMAND_HEADER.replace('{skillName}', skillName)}
Equivalent Comet skill: \`${skillName}\`
Command name: \`/${skillName}\`

Use the invocation arguments below as the user input for this workflow:

\`\`\`text
$ARGUMENTS
\`\`\`

${skillBody}
`;
        await writeFile(dest, content, 'utf-8');
        copied++;
    }
    return { copied, skipped };
}
async function copyCometSkillsForPlatform(baseDir, platform, overwrite, languageSkillsDir = 'skills', scope = 'project') {
    const assetsDir = getAssetsDir();
    const manifestPath = path.join(assetsDir, 'manifest.json');
    if (!(await fileExists(manifestPath))) {
        throw new Error(`Manifest not found at ${manifestPath}`);
    }
    const manifest = await readJson(manifestPath);
    if (!manifest || !Array.isArray(manifest.skills)) {
        throw new Error(`Invalid manifest at ${manifestPath}: "skills" must be an array`);
    }
    let copied = 0;
    let skippedCount = 0;
    for (const skillRelPath of manifest.skills) {
        const isScript = skillRelPath.includes('/scripts/');
        const sourceDir = isScript ? 'skills' : languageSkillsDir;
        const src = path.join(assetsDir, sourceDir, skillRelPath);
        const dest = path.join(baseDir, getPlatformSkillsDir(platform, scope), 'skills', skillRelPath);
        if (!overwrite && (await fileExists(dest))) {
            skippedCount++;
            continue;
        }
        try {
            await copyFile(src, dest);
            copied++;
        }
        catch (err) {
            console.error(`    Failed to copy ${skillRelPath}: ${err.message}`);
        }
    }
    const commandResult = await createOpenCodeCommands(baseDir, platform, manifest.skills, overwrite, scope, languageSkillsDir);
    copied += commandResult.copied;
    skippedCount += commandResult.skipped;
    return { copied, skipped: skippedCount };
}
async function readManifest() {
    const assetsDir = getAssetsDir();
    const manifestPath = path.join(assetsDir, 'manifest.json');
    return readJson(manifestPath);
}
async function getManifestSkills() {
    const manifest = await readManifest();
    return manifest.skills;
}
async function createWorkingDirs(projectPath) {
    const dirs = [
        path.join(projectPath, 'docs', 'superpowers', 'specs'),
        path.join(projectPath, 'docs', 'superpowers', 'plans'),
        path.join(projectPath, '.comet'),
    ];
    for (const dir of dirs) {
        await ensureDir(dir);
    }
    const configPath = path.join(projectPath, '.comet', 'config.yaml');
    if (!(await fileExists(configPath))) {
        await writeFile(configPath, [
            '# context_compression: off | beta',
            'context_compression: off',
            '# review_mode: off | standard | thorough',
            'review_mode: off',
            '# auto_transition: true | false',
            'auto_transition: true',
            '',
        ].join('\n'), 'utf-8');
    }
}
export { copyCometSkillsForPlatform, readManifest, getManifestSkills, createWorkingDirs, getAssetsDir };
//# sourceMappingURL=skills.js.map
__COMET_DIST_CORE_SKILLS_JS__

cat > "$TARGET_DIR/dist/core/superpowers.js" <<'__COMET_DIST_CORE_SUPERPOWERS_JS__'
import { execFileSync } from 'child_process';
import os from 'os';
import path from 'path';
import { cp, mkdir, readdir } from 'fs/promises';
import { printCommandErrorDetails } from './command-error.js';
import { getPlatformSkillsDir, PLATFORMS } from './platforms.js';
const SKILLS_AGENT_MAP = {
    opencode: 'opencode',
};
const VALID_PLATFORM_IDS = new Set(Object.keys(SKILLS_AGENT_MAP));
const SUPERPOWERS_INSTALL_TIMEOUT_MS = 300_000;
const SUPERPOWERS_SKILL_NAMES = [
    'brainstorming',
    'dispatching-parallel-agents',
    'executing-plans',
    'finishing-a-development-branch',
    'receiving-code-review',
    'requesting-code-review',
    'subagent-driven-development',
    'systematic-debugging',
    'test-driven-development',
    'using-git-worktrees',
    'using-superpowers',
    'verification-before-completion',
    'writing-plans',
    'writing-skills',
];
function buildSuperpowersInstallCommand(_projectPath, scope, platformIds) {
    const unknownIds = platformIds.filter((id) => !VALID_PLATFORM_IDS.has(id));
    if (unknownIds.length > 0) {
        throw new Error(`Unknown platform IDs: ${unknownIds.join(', ')}`);
    }
    const agentNames = [
        ...new Set(platformIds.map((id) => SKILLS_AGENT_MAP[id]).filter((name) => Boolean(name))),
    ];
    if (agentNames.length === 0) {
        throw new Error(`No skills CLI agent names resolved for platforms: ${platformIds.join(', ')}`);
    }
    const args = ['skills', 'add', 'obra/superpowers', '-y'];
    if (scope === 'global') {
        args.push('-g');
    }
    for (const name of agentNames) {
        args.push('--agent', name);
    }
    return { command: getNpxExecutable(), args };
}
function getNpxExecutable(platform = process.platform) {
    return platform === 'win32' ? 'npx.cmd' : 'npx';
}
async function ensureOpenCodeSuperpowersPlacement(projectPath, scope) {
    const opencodePlatform = PLATFORMS.find((platform) => platform.id === 'opencode');
    if (!opencodePlatform)
        return;
    const baseDir = scope === 'global' ? os.homedir() : projectPath;
    const targetSkillsDir = path.join(baseDir, getPlatformSkillsDir(opencodePlatform, scope), 'skills');
    const sourceSkillsDirs = [
        targetSkillsDir,
        path.join(baseDir, '.agents', 'skills'),
    ];
    await mkdir(targetSkillsDir, { recursive: true });
    for (const sourceSkillsDir of sourceSkillsDirs) {
        let entries = [];
        try {
            entries = await readdir(sourceSkillsDir);
        }
        catch {
            continue;
        }
        for (const skillName of SUPERPOWERS_SKILL_NAMES) {
            if (!entries.includes(skillName))
                continue;
            const src = path.join(sourceSkillsDir, skillName);
            const dest = path.join(targetSkillsDir, skillName);
            if (src === dest)
                continue;
            await cp(src, dest, {
                recursive: true,
                force: true,
                dereference: true,
            });
        }
    }
}
async function installSuperpowersForPlatforms(projectPath, scope, platformIds, shouldInstall = true) {
    if (!shouldInstall) {
        return 'skipped';
    }
    const unknownIds = platformIds.filter((id) => !VALID_PLATFORM_IDS.has(id));
    if (unknownIds.length > 0) {
        throw new Error(`Unknown platform IDs: ${unknownIds.join(', ')}`);
    }
    const skillsCliPlatformIds = platformIds.filter((id) => SKILLS_AGENT_MAP[id]);
    let failed = false;
    if (skillsCliPlatformIds.length > 0) {
        const command = buildSuperpowersInstallCommand(projectPath, scope, skillsCliPlatformIds);
        try {
            execFileSync(command.command, command.args, {
                cwd: projectPath,
                stdio: 'inherit',
                timeout: SUPERPOWERS_INSTALL_TIMEOUT_MS,
                shell: process.platform === 'win32',
            });
        }
        catch (error) {
            console.error(`    Superpowers install failed: ${error.message}`);
            printCommandErrorDetails(error);
            failed = true;
        }
        if (!failed && skillsCliPlatformIds.includes('opencode')) {
            try {
                await ensureOpenCodeSuperpowersPlacement(projectPath, scope);
            }
            catch (error) {
                console.error(`    Superpowers placement fix failed: ${error.message}`);
                failed = true;
            }
        }
    }
    return failed ? 'failed' : 'installed';
}
export { installSuperpowersForPlatforms, buildSuperpowersInstallCommand, SKILLS_AGENT_MAP, };
//# sourceMappingURL=superpowers.js.map
__COMET_DIST_CORE_SUPERPOWERS_JS__

cat > "$TARGET_DIR/dist/core/types.js" <<'__COMET_DIST_CORE_TYPES_JS__'
export {};
//# sourceMappingURL=types.js.map
__COMET_DIST_CORE_TYPES_JS__

cat > "$TARGET_DIR/dist/core/uninstall.js" <<'__COMET_DIST_CORE_UNINSTALL_JS__'
import path from 'path';
import { removeFile, removeDir, isDirEmpty } from '../utils/file-system.js';
import { getPlatformSkillsDir } from './platforms.js';
import { readManifest } from './skills.js';
async function removeCometSkillsForPlatform(baseDir, platform, scope = 'project') {
    const manifest = await readManifest();
    const skillsDir = getPlatformSkillsDir(platform, scope);
    let removed = 0;
    for (const skillRelPath of manifest.skills) {
        const dest = path.join(baseDir, skillsDir, 'skills', skillRelPath);
        if (await removeFile(dest)) {
            removed++;
        }
    }
    const commandsDir = path.join(baseDir, skillsDir, 'commands');
    for (const skillRelPath of manifest.skills) {
        const parts = skillRelPath.split('/');
        if (parts.length !== 2 || parts[1] !== 'SKILL.md')
            continue;
        const commandFile = path.join(commandsDir, `${parts[0]}.md`);
        if (await removeFile(commandFile)) {
            removed++;
        }
    }
    const parentDirs = new Set();
    for (const skillRelPath of manifest.skills) {
        const parts = skillRelPath.split('/');
        if (!parts[0].startsWith('comet'))
            continue;
        let current = path.join(baseDir, skillsDir, 'skills', parts[0]);
        parentDirs.add(current);
        for (let i = 1; i < parts.length - 1; i++) {
            current = path.join(current, parts[i]);
            parentDirs.add(current);
        }
    }
    const sortedDirs = [...parentDirs].sort((a, b) => b.split(path.sep).length - a.split(path.sep).length);
    for (const dir of sortedDirs) {
        if (await isDirEmpty(dir)) {
            await removeDir(dir);
        }
    }
    if (await isDirEmpty(commandsDir)) {
        await removeDir(commandsDir);
    }
    return { removed, failed: 0 };
}
async function removeWorkingDirs(projectPath) {
    const dirs = [
        path.join(projectPath, 'docs', 'superpowers', 'specs'),
        path.join(projectPath, 'docs', 'superpowers', 'plans'),
    ];
    let removed = 0;
    for (const dir of dirs) {
        if (await isDirEmpty(dir)) {
            await removeDir(dir);
            removed++;
        }
    }
    return { removed, failed: 0 };
}
export { removeCometSkillsForPlatform, removeWorkingDirs };
//# sourceMappingURL=uninstall.js.map
__COMET_DIST_CORE_UNINSTALL_JS__

cat > "$TARGET_DIR/dist/core/version.js" <<'__COMET_DIST_CORE_VERSION_JS__'
import { createRequire } from 'module';
import https from 'https';
const require = createRequire(import.meta.url);
const { version: CURRENT_VERSION } = require('../../package.json');
const PACKAGE_NAME = '@rpamis/comet';
const REGISTRY_URL = `https://registry.npmjs.org/${PACKAGE_NAME}/latest`;
/**
 * Compare two semver version strings.
 * Returns a positive number if a > b, negative if a < b, 0 if equal.
 */
export function compareVersions(a, b) {
    const parseParts = (v) => v
        .replace(/^v/, '')
        .split('.')
        .map((part) => {
        const numeric = parseInt(part, 10);
        return Number.isNaN(numeric) ? 0 : numeric;
    });
    const partsA = parseParts(a);
    const partsB = parseParts(b);
    const len = Math.max(partsA.length, partsB.length);
    for (let i = 0; i < len; i++) {
        const numA = partsA[i] ?? 0;
        const numB = partsB[i] ?? 0;
        if (numA !== numB) {
            return numA - numB;
        }
    }
    return 0;
}
/**
 * Get the current installed Comet version from package.json.
 */
export function getCurrentVersion() {
    return CURRENT_VERSION;
}
/**
 * Fetch the latest version from the npm registry.
 * Returns null if the registry is unreachable or the request fails.
 */
export function getLatestVersion() {
    return new Promise((resolve) => {
        const request = https.get(REGISTRY_URL, { timeout: 5000 }, (res) => {
            if (res.statusCode !== 200) {
                res.resume();
                resolve(null);
                return;
            }
            let data = '';
            res.on('data', (chunk) => {
                data += chunk;
            });
            res.on('end', () => {
                try {
                    const parsed = JSON.parse(data);
                    resolve(typeof parsed.version === 'string' ? parsed.version : null);
                }
                catch {
                    resolve(null);
                }
            });
        });
        request.on('error', () => resolve(null));
        request.on('timeout', () => {
            request.destroy();
            resolve(null);
        });
    });
}
/**
 * Check for available updates.
 * Silently returns a "not checked" result if the registry is unreachable.
 */
export async function checkForUpdate() {
    const currentVersion = getCurrentVersion();
    const latestVersion = await getLatestVersion();
    if (latestVersion === null) {
        return {
            currentVersion,
            latestVersion: null,
            hasUpdate: false,
            checked: false,
        };
    }
    return {
        currentVersion,
        latestVersion,
        hasUpdate: compareVersions(latestVersion, currentVersion) > 0,
        checked: true,
    };
}
/**
 * Format and print version info to the console.
 * Used by `comet init` and `comet update` at the start of command output.
 */
export async function printVersionInfo(log) {
    const result = await checkForUpdate();
    log(`  Comet v${result.currentVersion}`);
    if (!result.checked) {
        // Registry unreachable — skip silently per requirement #6
        return result;
    }
    if (result.hasUpdate) {
        log(`  New version v${result.latestVersion} available. Run 'npm update -g ${PACKAGE_NAME}' to upgrade.`);
    }
    else {
        log(`  You are on the latest version.`);
    }
    return result;
}
//# sourceMappingURL=version.js.map
__COMET_DIST_CORE_VERSION_JS__

cat > "$TARGET_DIR/dist/utils/file-system.js" <<'__COMET_DIST_UTILS_FILE_SYSTEM_JS__'
import { promises as fs } from 'fs';
import path from 'path';
/**
 * Resolve symlinks in a path, handling broken symlinks by following their
 * readlink target. Falls back to the original path if resolution fails.
 */
async function resolveSymlinkPath(filePath) {
    try {
        return await fs.realpath(filePath);
    }
    catch {
        // Path doesn't fully exist — walk up to find the deepest existing ancestor
        const dir = path.dirname(filePath);
        if (dir === filePath)
            return filePath; // filesystem root
        const resolvedDir = await resolveSymlinkPath(dir);
        const base = path.basename(filePath);
        // Check if this segment is a broken symlink and follow its target
        try {
            const stat = await fs.lstat(path.join(resolvedDir, base));
            if (stat.isSymbolicLink()) {
                const target = await fs.readlink(path.join(resolvedDir, base));
                return path.resolve(resolvedDir, target);
            }
        }
        catch {
            // Segment doesn't exist — return as-is
        }
        return path.join(resolvedDir, base);
    }
}
/**
 * Ensure a directory exists, creating it recursively if needed.
 * Resolves symlinks so that broken symlink targets are created correctly.
 */
export async function ensureDir(dir) {
    const resolved = await resolveSymlinkPath(dir);
    await fs.mkdir(resolved, { recursive: true });
}
/**
 * Copy a file from src to dest, creating parent directories if needed.
 * Resolves symlinks in the destination path so files are written to the
 * actual target location when dest contains symlinks (e.g., skill dirs
 * symlinked from ~/.claude/skills/ to ~/.agents/skills/).
 */
export async function copyFile(src, dest) {
    const resolvedDest = await resolveSymlinkPath(dest);
    await ensureDir(path.dirname(resolvedDest));
    await fs.copyFile(src, resolvedDest);
}
/**
 * Check if a file or directory exists.
 */
export async function fileExists(filePath) {
    try {
        await fs.access(filePath);
        return true;
    }
    catch {
        return false;
    }
}
/**
 * Read and parse a JSON file.
 */
export async function readJson(filePath) {
    const content = await fs.readFile(filePath, 'utf-8');
    return JSON.parse(content);
}
/**
 * Write content to a file, creating parent directories if needed.
 * Resolves symlinks so files are written to the actual target location.
 */
export async function writeFile(filePath, content) {
    const resolved = await resolveSymlinkPath(filePath);
    await ensureDir(path.dirname(resolved));
    await fs.writeFile(resolved, content, 'utf-8');
}
/**
 * List entries in a directory. Returns empty array if directory doesn't exist.
 */
export async function readDir(dirPath) {
    try {
        return await fs.readdir(dirPath);
    }
    catch (error) {
        const code = error?.code;
        if (code === 'ENOENT' || code === 'ENOTDIR') {
            return [];
        }
        throw error;
    }
}
/**
 * Returns true when an error means the path was simply not found. ENOENT is
 * the only non-fatal outcome for the removal helpers below; all other errors
 * (permissions, IO) are reported as failures instead of being masked as
 * "already gone".
 */
function isNotFoundError(error) {
    return error?.code === 'ENOENT';
}
/**
 * Remove a file. Returns true if the file existed and was removed.
 * Operates on the path directly so a symlink entry is removed rather than its
 * resolved target (avoids deleting files the symlink merely points at).
 */
export async function removeFile(filePath) {
    try {
        await fs.unlink(filePath);
        return true;
    }
    catch {
        // Not found or failed (permissions/IO): nothing was removed.
        return false;
    }
}
/**
 * Remove a directory recursively. Returns true if the directory existed and was removed.
 * Symlinked directories are unlinked directly rather than recursed into, so the
 * directory a symlink points at is never deleted.
 */
export async function removeDir(dirPath) {
    try {
        // lstat does not follow symlinks; unlink a symlinked dir instead of rm-ing its target.
        const stat = await fs.lstat(dirPath);
        if (stat.isSymbolicLink()) {
            await fs.unlink(dirPath);
            return true;
        }
        await fs.rm(dirPath, { recursive: true, force: true });
        return true;
    }
    catch (error) {
        return isNotFoundError(error);
    }
}
/**
 * Check if a directory is empty. A missing directory is treated as empty;
 * unreadable directories (permissions/IO) return false so callers never delete
 * a directory they could not inspect.
 */
export async function isDirEmpty(dirPath) {
    try {
        const entries = await fs.readdir(dirPath);
        return entries.length === 0;
    }
    catch (error) {
        return isNotFoundError(error);
    }
}
//# sourceMappingURL=file-system.js.map
__COMET_DIST_UTILS_FILE_SYSTEM_JS__

cd "$TARGET_DIR"
npm install --omit=dev

if [ "$INSTALL_GLOBAL" -eq 1 ]; then
  npm install -g .
fi

echo "Comet runtime written to: $TARGET_DIR"
if [ "$INSTALL_GLOBAL" -eq 1 ]; then
  echo "Global install complete."
else
  echo "Run with --global to register the comet CLI globally."
fi
