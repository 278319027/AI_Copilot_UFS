# Anti-Patterns

> 项目中真实发生过的错误模式。每个反模式 = 场景 + 后果 + 根因 + 修复 + 预防措施。
> 新增反模式时遵循此格式。

---

## AP-001: BUILD Gate 缺口 — 未加载验证 skill 直接编码

**场景**: `add-gc-stats-flip` 变更（2026-06-22）
**后果**: 代码正确但方法论遵循度仅 70%，无测试计划、无任务跟踪、无验证证据
**根因**: openspec-apply skill 未在编码前强制检查 skill 加载状态
**修复**: 新增 BUILD Gate（五级门禁之一），强制 AI 在编码前声明已加载的 skill
**预防**: openspec-apply SKILL.md 中增加"编码前必须输出已加载 skill 列表"的硬性要求

---

## AP-002: ~~FEMU_ROOT 硬编码分散~~ — 已 2026-06-23 修正

**原始问题**: opencode.json、verify.sh、AGENTS.md 三处均硬编码 `/home/zsf/AI_Proj/femu/hw/femu`
**原修复**（2026-06-22）：`scripts/get_femu_root.sh` 统一从 opencode.json 解析

**新问题发现**（2026-06-23）：
- `get_femu_root.sh` 的 1st tier priority（`project.femuRoot` 字段）在 `opencode.json` 中**根本不存在**——是 dead code
- 脚本实际等价于 `${FEMU_ROOT:-/home/zsf/AI_Proj/femu/hw/femu}` 1 行 shell 变量展开
- 70 行 python 解析器是**过度工程**

**修正**（2026-06-23）：
- 删除 `scripts/get_femu_root.sh`（70 行）
- 改用 `${FEMU_ROOT:-/home/zsf/AI_Proj/femu/hw/femu}` 约定，与 `opencode.json → mcp.codegraph.command --path` 同步
- 更新 `verify.sh`（删 `_get_femu_root()` 函数，2 处调用改 env var）、`scripts/verify_spec_symbols.sh`、`AGENTS.md`、`architecture.md`

**预防**:
- 不要写独立的 FEMU_ROOT 解析脚本——约定是 env var 默认值
- 修改默认路径时，**2 处需同步**：`opencode.json` 的 codegraph --path + 脚本中 `${FEMU_ROOT:-...}` 默认值
- verify.sh [8/17] 检查项验证 `opencode.json` 配置完整性

---

## AP-003: Graphify 安装污染系统 Python

**场景**: deploy_tools.sh 使用 `python3 -m pip install --break-system-packages graphifyy`
**后果**: 破坏系统 Python 环境，可能导致其他工具冲突
**根因**: 图省事直接使用 system pip，未考虑隔离
**修复**: 改为 venv 隔离安装：`python3 -m venv ~/.local/share/graphify-venv`
**预防**: deploy_tools.sh 中删除所有 `--break-system-packages` 用法

---

## AP-004: 步骤编号混乱 — 用户困惑

**场景**: deploy_tools.sh 输出 `[1/6]`, `[3a/4]`, `[3b/4]`, `Step 7` 混用
**后果**: 用户无法判断部署进度，误以为步骤缺失
**根因**: 脚本多次迭代后未统一编号体系
**修复**: 统一为 5 步连续编号 `[1/5]`→`[5/5]`
**预防**: 新增脚本语法检查（bash -n）+ 步骤编号正则校验

---

## AP-005: Spec 与代码符号漂移 — 重构后 spec 未更新

**场景**: （潜在风险）spec 中引用 `ftl_read` 等函数名，代码重构后函数名变更但 spec 未同步
**后果**: spec 成为错误的行为描述，AI 按过时 spec 生成错误代码
**根因**: 缺乏 spec → 代码符号的自动化同步机制
**修复**: 新增 `scripts/verify_spec_symbols.sh` 定期扫描验证
**预防**: CI 中集成 spec 符号存在性检查

---

## AP-006: 静默失败 — 工具错误不阻断流程

**场景**: codegraph build 失败、graphify 更新失败、社区检测失败均用 `|| echo "⚠ ..."` 静默忽略
**后果**: 用户以为部署成功，实际索引为空或图谱陈旧
**根因**: 过度容错设计，未区分"可恢复警告"和"必须阻断的错误"
**修复**: 关键步骤（索引构建、图谱构建、社区检测）失败时 `exit 1`
**预防**: deploy_tools.sh 中对每个关键步骤明确标注：⚠=警告（继续）/ ✗=错误（退出）

---

## AP-007: 运行产物误提交到 git

**场景**（历史，2026-06-22）：`collect_metrics.sh` 生成的 `metrics/2026-06-23.md` 被提交到 git
**后果**: 运行产物污染仓库历史，违反"代码优先"原则，commit 信息被噪音稀释
**根因**: 创建度量收集脚本时未同步更新 `.gitignore` 排除 `metrics/` 目录
**修复**: 删除已误提交的文件 + 在 `.gitignore` 追加 `metrics/`
**预防**: 新增任何"产生文件到新目录"的脚本/命令时，必须同步检查 `.gitignore` 是否覆盖该目录

---

## AP-008: 度量脚本统计模式错误 — checkbox ≠ task 标题

**场景**（历史，2026-06-22 首次实战暴露）：`collect_metrics.sh` 第 53 行用 `grep -cE '^\- \['` 统计 task 数
**后果**: "平均 task 数"指标失真（3 tasks × 3 checkboxes = 9 → 报告为 8，触发误报警 ⚠）
**根因**: 实现时混淆"checkbox（测试项）"和"task 标题（任务项）"两种概念，grep 模式 `^\- \[` 实际匹配 markdown 列表中的 checkbox 而非 `## Task` 标题
**修复**: 改用 `grep -cE '^## Task '` 严格匹配 task 标题（`## Task N: <标题>` 是 OpenSpec 通用 tasks.md 格式）
**预防**: 写度量/统计脚本时，必须先在小样本上手工核对 grep/awk 模式与期望的语义匹配，再部署到 CI

---

## 如何新增反模式

```markdown
## AP-00N: <标题>

**场景**: <简要描述>
**后果**: <影响>
**根因**: <为什么发生>
**修复**: <怎么解决的>
**预防**: <怎么防止再次发生>
```

---

## AP-014: KNOW 阶段未用 CodeGraph + Graphify（per retro 2026-06-23-refactor-crt-insert-helpers）

**场景**: `refactor-crt-insert-helpers` drill 的 KNOW 阶段用 `grep -nE "crt_insert\(" + nm` 替代 CodeGraph + Graphify 工具查询。

**后果**:
1. **错过 9 个 test callers**（per Graphify `explain crt_insert` 显示有 9 个 test 函数如 `test_insert_and_lookup_hit`、`test_evict_oldest_when_full` 调用 crt_insert）
2. **错过现有 14 个 test functions / 26 assertions** 的 `tests/unit/crt_test.c`（535 行）—— 写了 5 个 scenarios 的 `/tmp/crt_refactor_test.c` 是冗余的
3. **错过直接依赖图**（per CodeGraph `context crt_insert`：crt_hash + crt_find_empty_slot + crt_evict_oldest）—— grep 只能看到 `crt_hash` 一行
4. **错过复杂度指标**（per CodeGraph：Cognitive 3 / Cyclomatic 4 / MI 52.2）—— grep 完全无法获取

**根因**:
- 方法论已文档化（per `sd-firmware-copilot/SKILL.md` §KNOW 阶段 4 步 query 流程），但 drill session 实际执行时**未遵循**（无自动化检查强制）
- verify.sh 仅检查工具安装（[5/20] Tools on PATH），不检查工具索引是否构建 + 是否被使用
- "CodeGraph DB not in zsf repo" 的 fallback 路径被默认为合法（per AGENTS.md 旧描述），掩盖了 KNOW 阶段工具缺位的问题

**修复**:
- **verify.sh [21/21]**：新增检查 `${FEMU_BASE}/.codegraph/graph.db` 和 `${FEMU_BASE}/graphify-out/graph.json` 存在性（per commit 后续，2026-06-23）
- **verify.sh [5/20]**：扩展到 3 个工具（`codegraph graphify openspec`）
- **verify.sh FEMU_BASE**：自动补全 `/hw/femu` 后缀（修复 env `FEMU_ROOT=/home/zsf/AI_Proj/femu` 缺后缀导致 [21/21] 误报）
- **AGENTS.md M-5 Session Start Checklist**：4 步 → 5 步，新增 **Step 3 CodeGraph + Graphify 索引确认**（强制重建命令）
- **代码证据**：`tests/unit/crt_test.c` 14 test functions / 26 assertions / 535 lines / 全部 PASS refactored crt.c

**预防**:
- 续会 session 必跑 M-5 5 步（特别是 Step 3 检查索引）
- `[21/21]` 是 mandatory check：任何 drill 前必须看到 PASS
- 未来如再发生 KNOW 阶段工具缺位，**retro 必须有 AP-NNN 记录** + 立即补 verify check
- **强信号**：本类问题表现为"drill 写的 host test 是冗余的"（已有项目内 test 未发现）= KNOW 阶段 4 步 query 流程未跑

**严重程度**: **P0**（方法论闭环完整性；与 AP-005 签字缺失同等级，影响 drill 验证质量）

---

## AP-013: 预存 bug 暴露（crt_lookup NULL out_ppa 段错误，per retro 2026-06-23-refactor-crt-insert-helpers）

**场景**: refactor-crt-insert-helpers drill 写 host test 时，第一版用 `crt_lookup(crt, lpn, NULL)` 触发 segfault。

**后果**:
1. Test segfault 一次（无 functional damage — test 在 /tmp，未进 commit）
2. 暴露 `crt.c` 有**预存 lat bug**（不是 refactor 引入的）—— `crt_lookup` 不检查 `out_ppa == NULL` 就 `*out_ppa = ppa_advance(...)`

**根因**:
- `crt_lookup` 假设 caller 永远传 valid `out_ppa`；FTL 真实 caller（`ftl.c`）永远传 stack/heap 变量，所以未触发
- 但这是 contract violation（函数应 accept NULL 表达 "don't care" 语义，或 assert）

**修复**:
- 本次 refactor **不修**此 bug（per `superpowers-systematic-debugging` "Fix minimally. NEVER refactor while fixing"）
- 后续开新 change `fix-crt-lookup-null-out-ppa`：3 行 fix（NULL check + early return）
- 在 review.md 的 "不可覆盖路径 / 已知遗留" 段已记录

**预防**:
- 未来 refactor drill 遇到预存 bug：**记入 review.md "已知遗留" 段**，开新 change 处理
- 不要在 refactor commit 里夹带 fix（违反 1 commit = 1 concern 原则）

**严重程度**: P3（latent，不在 production 触发路径上；但 FDP API 允许 caller 传 NULL 时会暴露）

---

## AP-011: sync_change.sh 非幂等（per retro 2026-06-23-refactor-crt-insert-helpers）

**场景**: 执行 `bash scripts/sync_change.sh <change-id>` 第一次完美 append delta 到 baseline；为验证幂等性再次执行，**delta 被再次 append**，baseline 出现重复的 `### Requirement:` 块。

**后果**:
1. openspec validate --strict --specs 仍 PASS（重复 Requirement 不违反 schema）
2. verify.sh [18/20] "no delta headers" 仍 PASS（重复的不是 delta 头）
3. **下游 openspec show ftl-mapping 重复显示同一 Requirement**（user confusion）
4. 耗时 2 分钟发现 + sed 手动删除 40 行重复

**根因**:
- sync_change.sh 的 merge 逻辑检查 `## ADDED Requirements` 头存在 → 就 append 整个 delta 段
- 不检查 delta 段内的 `### Requirement:` 头是否已在 baseline 存在
- 同步状态未持久化

**修复**:
- 短期：手动 sed 删除重复
- 中期：sync_change.sh 添加 idempotency check（baseline 已含同名 Requirement 头则 skip）
- 长期：在 change 目录创建 `.synced` 标记文件

**预防**:
- sync 后**必须 verify**（`grep -c "^### Requirement: <name>" openspec/specs/<cap>/spec.md` 应 = 1）
- sync_change.sh 顶部加 "WARNING: not idempotent" 提示
- 实现 idempotency（推荐）

**严重程度**: **P1**（会导致 baseline 污染；下游工具 + 人工 review 都会困惑；无 security risk）

---

## AP-012: 注释 hook 误报（per retro 2026-06-23-refactor-crt-insert-helpers）

**场景**: T3.1 写 forward declaration 时加了 1 行注释解释 change-id；comment hook 触发 priority 4 警告（"unnecessary comment"）。

**后果**: 1 分钟延迟（按 hook priority 删注释 + 重新 edit）。

**根因**: forward declaration 命名 + `;` 语法已 self-evident；change-id 应在 git history，不在源码。

**修复**: 删除注释（已修复）。

**预防**: 写注释前问 "如果我换 change 会改这段注释吗？" —— 如果是，注释在源码里就不合适。change-id trace 应通过 git log / `git blame` 找。

**严重程度**: P3（cosmetic，无 functional impact）

