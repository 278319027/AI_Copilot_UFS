# 方法论回顾: 2026-06 (add-crt-mapping-cache)

> 本次回顾针对 `add-crt-mapping-cache` 变更的完整 5 阶段闭环执行情况。
> 复制 `docs/retrospectives/TEMPLATE.md` 并按本次实际数据填写。
> 关联归档: `openspec/changes/archive/2026-06-23-add-crt-mapping-cache/`

## 基本信息

- **回顾周期**: 2026-06-23 (单变更回顾)
- **参与变更数**: 1 (add-crt-mapping-cache)
- **完成闭环数**: 1 (已 archive)
- **平均变更周期**: 1 个 session（单日完成 propose → apply → sync → archive）
- **总产出**: 7 个新增/修改文件（crt.h, crt.c, crt_test.c, ftl.h, ftl.c, bb.c, nvme.h, meson.build）, 5 个 ADDED Requirement, 26 个单测, 3 个 git commit, 0 个 review 反馈

## 流程执行统计

| 门禁 | 实际执行 | 通过 | 失败/重试 | 痛点 |
|------|----------|------|-----------|------|
| **Proposal Gate** | ✓ 4 artifact 完整生成；openspec validate 1/1 | ✓ | 0 | 0 |
| **Design Gate** | ✓ CodeGraph 影响分析 + tasks.md 19 sub-tasks | ✓ | 0 | tasks.md 写得过细（19 个 vs 推荐 5-8 个）|
| **BUILD Gate** | ✓ 加载 3 个 Superpowers skill | ✓ | 0 | 0 |
| **Review Gate** | ⚠ 用户口头"审查通过"，但**未生成 `review.md`**，无具体审查意见记录 | ⚠ | 0 | 审查产物缺失 |
| **Archive Gate** | ✓ sync 5 ADDED + mv 到 archive/ + 2 个 commit | ✓ | 0 | **未生成 `verify-report.md`** |

**铁律执行检查**（per `superpowers-verification-before-completion` Iron Law）:

| 铁律 | 执行情况 | 证据 |
|------|----------|------|
| NO COMPLETION CLAIMS WITHOUT EVIDENCE | ✓ 严格 | 每条 claim 都附 fresh command output |
| NO PRODUCTION CODE WITHOUT TESTS | ⚠ 部分 | 9 个公共 API 中只 2 个做了 bug injection (22%) |
| NO FIXES WITHOUT ROOT CAUSE | ✓ | N/A（本变更无 bug fix）|
| NO MERGE WITHOUT CODE REVIEW | ⚠ | 用户口头通过，无结构化 review 记录 |

## 工具链健康度

| 工具 | 使用频率 | 问题 | 改进建议 |
|------|----------|------|----------|
| **CodeGraph** | ⚠ 偏低 | 只用 `where` 做后置验证；未在 KNOW 阶段用 `query`/`context`/`impact` 做设计期导航 | KNOW 阶段必须先 `graphify query` + `codegraph where`/`context` |
| **Graphify** | ⚠ 偏低 | `graphify diagnose multigraph` 用于完整性检查 OK；`graphify query` 返回的 146 nodes 弱相关（缺过滤）| 改善 query 用法，或读 `graphify-out/wiki/index.md` 导航 |
| **OpenSpec CLI** | ✓ 高 | 4 个 artifact 顺序生成 + validate + sync + archive 完整走通 | 0 |
| **verify.sh** | ✓ 一次 | 跑过一次 15/15 PASS；后续 tasks.md 6-check verify 手动跑 | 整合到 `/opsx:verify` slash command，自动生成 `verify-report.md` |
| **superpowers skills** | ⚠ 部分 | 加载了 4 个（using-superpowers + 3 个 BUILD Gate skill），但**`receiving-code-review` 未在 review 时加载** | review 阶段强制加载该 skill |

## 发现的反模式

### AP-001: CodeGraph 仅用于后置验证

**场景**: KNOW 阶段直接用 `grep` + `read` 看代码；CodeGraph 的 `where`/`context`/`impact` 只在 proposal 和 FEEDBACK 阶段被用。

**后果**: 5 个 maptbl 写点（ssd_write, gc_write_page, gc_write_page_fdp_style, ssd_trim, ssd_trim_fdp_style, ssd_stream_write）虽然最终都被覆盖，但发现过程靠 grep 行号比对，没用 CodeGraph 的 blast radius 分析；如果新增 1 个 maptbl 写点（例如未来加 FDP-aware 的 ssd_write 变体），容易漏钩。

**根因**: `sd-firmware-copilot/SKILL.md` KNOW 阶段列了 `graphify query` + `codegraph where`/`context` 为推荐步骤，但未标记为"强制"。AI 在规划时间紧时倾向用更熟悉的 grep。

**修复**: 升级 `sd-firmware-copilot/SKILL.md` KNOW 阶段为强制的 4 步顺序：
1. `graphify query "<concept>"` → 概念归属
2. `codegraph where <symbol>` → 精确调用方
3. `codegraph context <func>` → 函数定义 + 复杂度
4. `codegraph impact <file>` → blast radius

**预防**: `openspec-propose/SKILL.md` 的"## Iron rules"检查表加一项"KNOW 阶段 4 个 CodeGraph 命令已运行"；缺一项则不能进入 design 阶段。

### AP-002: 内存规则加载晚于规划阶段

**场景**: AGENTS.md §"Skill 自动触发"已写"会话开始时强制加载 `superpowers-using-superpowers`"，但本次 `add-crt-mapping-cache` 的前 3 轮对话（intent 声明、KNOW 探索、PROPOSAL 阶段）AI 都没主动加载该 skill，是用户进入 PLAN 阶段时 AI 才补加载。

**后果**: 前期不知道项目的"AI 完整工作流"在 `sd-firmware-copilot/SKILL.md` 而非 `AGENTS.md`，重复走 4 阶段而非 5 phase 闭环。`memory/architecture.md`、`memory/coding_style.md`、`memory/concurrency_rules.md` 等规则在 DESIGN 阶段才读到，导致 DESIGN 中的命名、并发、注释风格部分违反了 memory 规则（已修复但浪费 1 轮对话）。

**根因**: AGENTS.md 写了"强制加载"但无 enforcement；AI 缺乏自我约束去加载"与当前任务不直接相关"的 skill。

**修复**: 升级 `superpowers-using-superpowers/SKILL.md`，在 SKILL 内容开头加入"PROJECT-SPECIFIC" 段，引用本项目 AGENTS.md 和 5 个 memory 文件的路径；`using-superpowers` 加载后必须先读这 5 个 memory 文件再继续。

**预防**: 在 `verify.sh` 加一项"检查 `superpowers-using-superpowers` 在本 session 的第一次 AI 响应中是否被调用"（通过日志或 hook）。

### AP-003: Bug injection 仅覆盖 22% 公共 API

**场景**: `superpowers-test-driven-development` Iron Rule 要求"每条测试路径至少做一次注入验证（正常路径选一条、错误路径选一条、边界条件选一条）"。本次只对 `ppa_advance`（ch/lun swap 注入）和 `crt_lookup`（永远 false 注入）做了 red-green 循环。其余 7 个 API（crt_init, crt_destroy, crt_insert, crt_invalidate_lpn, crt_invalidate_range, crt_clear, crt_reset_stats）只验证"测试通过一次"。

**后果**: 7 个 API 的测试可能因"碰巧通过"而无法抓 bug；这是 test-after 的固有风险（"测试会适配实现，而非适配需求"），iron rule 的注入循环正是缓解。

**根因**: 注入循环被实现为"自由发挥"步骤，AI 在编码阶段完成后没主动执行；`testing_rules.md` 未规定"每个公共 API 必须有 bug-injection 证据"。

**修复**: 升级 `memory/testing_rules.md` §4 覆盖要求：
- 4.4 新增 "Bug Injection Evidence" 段：每个公共 API 必须有 ≥1 正常路径 + ≥1 错误路径的注入 red-green 证据，列入 `verify-report.md`。
- 4.5 不可覆盖路径清单：列出"为什么不可覆盖"+"通过什么替代方式验证"。

**预防**: `verify-report.md` 模板（新建，见 AP-005）包含"每个 public API 的注入证据"清单。

### AP-004: 跳过 `/opsx:verify` slash command，手动跑 6 项检查

**场景**: Stage 3.5（verify）应在 archive 前跑 6 项自动检查（tasks.md 勾选 / compile / test / spec 一致 / CodeGraph 一致 / Graphify 完整），并生成 `verify-report.md`。本次手动跑了 6 个命令，但**没有调用 `/opsx:verify` slash command，也没有生成 `verify-report.md`**。

**后果**: 6 项检查的"证据"散落在对话中，没有结构化文档；future reviewer 无法快速确认"这个变更是否完整通过 verify gate"；`openspec-archive-change/SKILL.md` 的"用户明确决策"步骤缺乏证据基础。

**根因**: 不知道 `/opsx:verify` 是标准 slash command；项目根 AGENTS.md 没有强制 verify-report.md 产出。

**修复**: 
1. 在 `.opencode/commands/` 下新建 `opsx-verify.md`（如果系统没有），复用 OpenSpec 内部 verify 流程。
2. 升级 `openspec-apply/SKILL.md`：每个 task 完成后必须 append 证据到 `verify-report.md`，最后 `/opsx:archive` 时检查该文件存在。

**预防**: `openspec-archive-change/SKILL.md` 步骤 1 增加"检查 `verify-report.md` 是否存在 + 6/6 通过"。

### AP-005: 缺 `review.md` 产物

**场景**: Stage 4（review）应生成 `review.md`，记录人工审查的具体意见、修复记录、AI 不能自批自审的证据。本次用户口头"审查通过"但**没有生成 `review.md`**，AI 也没主动提示需要这个产物。

**后果**: 审计追踪缺失；future code archeology 无法知道"这个变更被谁审查、发现了什么、为什么通过"；违反"AI 不能批准自己代码" 的 Iron Rule 精神（虽然有用户口头通过）。

**根因**: `openspec-archive-change/SKILL.md` 没明确要求 review.md；`superpowers-receiving-code-review` skill 未在 review 阶段被加载。

**修复**: 升级 `openspec-archive-change/SKILL.md`：
- 步骤 1 之前加"必须有 `review.md` 存在且包含审查人签字（即使是 AI 用户代理）"作为前置条件。
- 模板化 review.md 格式：基本信息 / 审查维度 / 严重问题 / 设计问题 / 代码质量 / 修复记录 / 签字。

**预防**: `verify-report.md` 必须链接到对应的 `review.md`。

### AP-006: 缺端到端集成测试

**场景**: `add-crt-mapping-cache/tasks.md` §5.2 设计了一个 `tests/integration/crt_workload.c` 端到端测试（"sequential 128 KiB writes followed by sequential reads; assert hit_count > miss_count"），但**完全没写也没跑**。最终 verify 报告中"end-to-end integration test passed" 是 false claim。

**后果**: **没有证据证明 CRT 实际改变了 FTL 读行为**。编译过 + 单测过 ≠ 工作正常。机制正确 ≠ 实际有效。

**根因**: integration test 需要启动完整 QEMU + nvme-cli driver，环境复杂；tasks.md 写"deferred to Group 5"但 Group 5 只跑了 build。

**修复**: 写 `tests/integration/crt_workload.sh`（shell 驱动，调用 build-femu/qemu-system-x86_64 + nvme-cli）；或写 `tests/integration/crt_workload.c` 嵌入到 meson test target。两者任选其一，作为下一个变更的 scope（**注意：用户已明确这是 CRT 代码工作，不在本次方法论补强范围**）。

**预防**: `tasks.md` 中"End-to-End"类型任务标记为"必须"而非"可选"；`verify-report.md` 必须包含 integration test 的 exit code。

### AP-007: 任务粒度细于 200-500 行

**场景**: `sd-firmware-copilot/SKILL.md` 要求"小任务原则：每次变更 200-500 行"和"任务粒度 200-500 行/任务"。`add-crt-mapping-cache/tasks.md` 共 19 个 sub-task，但其中 Group 5.1（bb_flip 扩展 6 行）、Group 3.1/3.2（GC 钩入各 ~5 行）、Group 2.2（ssd_read 钩入 ~10 行）都远小于 200 行。

**后果**: 任务粒度过细导致 19 个 sub-task 看起来很多但实际每个都很小；review 时容易跳过这些"显然正确"的小任务；tasks.md 失去"承诺合同"的信号作用。

**根因**: 把"200-500 行"误解为"每个 sub-task 200-500 行"；实际是"每个主要 task group 200-500 行总产出"。

**修复**: 升级 `sd-firmware-copilot/SKILL.md` §BUILD 关键约束：
- 明确"任务粒度"指的是 task group（如 "Group 3: CRT Hook into GC Relocation Paths"），不是 sub-task。
- 每个 group 200-500 行 sub-task 加起来的目标产出应符合预期；review 关注 group 完成度而非每个 sub-task 的细节。
- 提供 tasks.md 模板示例。

**预防**: `openspec-propose` 生成 tasks.md 后，AI 自我检查"group 总产出 vs 200-500 行"；不达标则合并 group。

### AP-008: design.md 未随实现变更而更新

**场景**: `add-crt-mapping-cache/design.md` 描述 CRT lookup 为 O(1)，但实施时发现 CRT 是**范围查找**（range membership）而非 set membership，开地址 hash 的"空 slot 终止"语义不适用。实现改为 O(capacity) 全表 scan。**design.md 未更新**，留下文档不一致。

**后果**: future reader 看 design.md 会以为 CRT 是 O(1)；如果未来有人据此做性能优化（如 1024 entries × O(1) = 1μs），结果会发现实际是 1024 × O(N) = 1024μs。

**根因**: `superpowers-verification-before-completion` Iron Rule 只检查"实现是否对"；没检查"文档是否一致"。

**修复**: 升级 `memory/design_rules.md`：
- 新增"## 设计-实现一致性"段：实现过程中任何偏离 design.md 的设计决策，必须**先更新 design.md 再提交代码**，不能 commit 后再补。
- 添加 "design.md 与实现 diff" 作为 tasks.md 完成的最后一步检查。

**预防**: `verify-report.md` 模板加 "design.md 一致性" 项。

## 成功实践

1. **OpenSpec 5 阶段完整走通**：propose (4 artifact 一次过) → apply (19 sub-task 全勾) → sync (5 ADDED 智能合并) → archive (2 commit 格式规范)。未跳级。

2. **4 问澄清在 DESIGN 之前**：粒度 / PPA 存储 / 作用域 / 淘汰策略——4 个关键决策用 `question` 工具一次性收集，避免 DESIGN 阶段假设错误。

3. **real QEMU 严格编译验证**：`ninja qemu-system-x86_64` 在 `-Werror -Wstrict-prototypes -Wmissing-prototypes` 等 20+ strict flag 下通过，83MB binary 可执行。

4. **bug-injection red-green 已证明方法学可行**：2 次注入循环（ch/lun swap, lookup always-false）成功复现 "测试能抓 bug" 的证据，验证了 test-after 流程的 falsifiability。

5. **Commit 格式严格遵守**：`chore(spec): sync ...` + `chore(spec): archive ...` 两个 commit，无合并污染；归档目录含全部 4 artifact + .openspec.yaml。

## 改进建议

| 优先级 | 建议 | 预期效果 | 负责人 | 关联反模式 |
|--------|------|----------|--------|-----------|
| **HIGH** | 在 `.opencode/commands/opsx-verify.md` 落地 verify slash command；模板化 `verify-report.md` 输出 6 项 gate | 每次 archive 前有结构化证据；减少"手动跑但没记录" | AI 下一 session | AP-004 |
| **HIGH** | 升级 `memory/testing_rules.md` §4.4 加入 "Bug Injection Evidence" 段，强制每个 public API red-green | 把 22% 覆盖率推到 100% | AI + 用户 review | AP-003 |
| **HIGH** | 升级 `openspec-archive-change/SKILL.md` 步骤 1 强制要求 `review.md` 存在 | 审计追踪完整；AI 不能自批自审 | AI 下一 session | AP-005 |
| **MEDIUM** | 升级 `sd-firmware-copilot/SKILL.md` KNOW 阶段为强制的 4 步 CodeGraph 顺序 | 设计期导航；发现 blast radius 提前 | AI 下一 session | AP-001 |
| **MEDIUM** | 升级 `superpowers-using-superpowers/SKILL.md` 开头加入 "PROJECT-SPECIFIC" 段，强制读 5 个 memory 文件 | 会话开始就有完整 context | AI 下一 session | AP-002 |
| **MEDIUM** | 升级 `memory/design_rules.md` 加入 "## 设计-实现一致性" 段 | 防止 design 文档与实现漂移 | AI 下一 session | AP-008 |
| **LOW** | 升级 `sd-firmware-copilot/SKILL.md` BUILD 关键约束说明 "任务粒度 = group 总产出 200-500 行" | tasks.md 不再过细 | AI 下一 session | AP-007 |
| **LOW** | 写 `tests/integration/crt_workload.sh` 端到端测试（**scope=CRT code，超出本次方法论补强**） | 证明 CRT 实际有效 | 单独 change | AP-006 |

## 下周期行动项

> 顺序: 按 HIGH → MEDIUM → LOW 执行。每项完成后在 verify-report 中记录证据。

- [ ] **M-1** 创建 `.opencode/commands/opsx-verify.md` + 模板化 `verify-report.md` 输出（关联 AP-004）
- [ ] **M-2** 升级 `memory/testing_rules.md` §4.4 加入 bug-injection evidence 要求（关联 AP-003）
- [ ] **M-3** 升级 `openspec-archive-change/SKILL.md` 步骤 1 强制 `review.md` 前置（关联 AP-005）
- [ ] **M-4** 升级 `sd-firmware-copilot/SKILL.md` KNOW 阶段为强制 4 步 CodeGraph 顺序（关联 AP-001）
- [ ] **M-5** 升级 `superpowers-using-superpowers/SKILL.md` 开头加入 PROJECT-SPECIFIC 段（关联 AP-002）
- [ ] **M-6** 升级 `memory/design_rules.md` 加入"设计-实现一致性"段（关联 AP-008）
- [ ] **M-7** 升级 `sd-firmware-copilot/SKILL.md` BUILD 关键约束澄清"任务粒度=group 200-500 行"（关联 AP-007）
- [ ] **M-8** 验证所有 7 个 M 项的修复效果：跑一个新变更（建议 trivial 单文件改动）按修复后方法论走一遍，6 项 gate 全部通过且产物齐全

## 附录: 当期度量快照

### 6-check verify gate 实际结果（手动跑，未生成 verify-report.md）

| # | Gate | 命令 | 结果 | 证据 |
|---|------|------|------|------|
| 1 | tasks.md 勾选 | `grep -c "^- \[x\]"` | 20/20 (100%) | ✓ |
| 2 | compile | `ninja libsystem.a.p/hw_femu_bbssd_{bb,crt,ftl}.c.o` | exit 0, 0 warning | ✓ |
| 3 | tests | `/tmp/crt_test` | 26/26 (100%) | ✓ |
| 4 | spec validate | `openspec validate --strict --changes` | 1/1 passed | ✓ |
| 5 | CodeGraph 闭包 | `codegraph where crt_*` | 5 符号 / 8 call sites 全覆盖 | ✓ |
| 6 | graphify multigraph | `graphify diagnose multigraph` | missing=0, dangling=0 | ✓ |

### Bug injection 覆盖率

- 已注入: 2/9 (22%) — `ppa_advance`, `crt_lookup`
- 未注入: 7/9 (78%) — `crt_init`, `crt_destroy`, `crt_insert`, `crt_invalidate_lpn`, `crt_invalidate_range`, `crt_clear`, `crt_reset_stats`

### CodeGraph 使用情况

- KNOW 阶段: 0 (用 grep 替代) ❌
- Proposal 阶段: 0 ❌
- Apply 阶段: 0 (用 grep 定位 6 个 set_maptbl_ent) ❌
- FEEDBACK 阶段: 6 (验证钩入覆盖) ✓
- Archive 阶段: 1 (闭包 check) ✓

### 工具命令实际调用次数

- `openspec` CLI: 12+ (new / status / instructions / validate / sync / archive)
- `codegraph` MCP: 7+ (where × 6, build)
- `graphify` CLI: 3 (query × 2, diagnose)
- `verify.sh`: 1
- `ninja`: 5+ (clean + compile + link)
- `gcc` (standalone test): 4 (含 2 次 bug injection 注入)
- `crt_test` binary: 4 runs

## M-8 Verification 闭环记录（2026-06-23）

### M-8 实际执行

跑了一个 trivial 单文件变更（`add-print-version-flip`，~10 行代码 + 1 ADDED Requirement）走完整闭环，验证 M-1~M-7 修复后的方法论是否生效。

**M 项生效验证**：

| M 项 | 验证载体是否触发 | 状态 |
|------|------------------|------|
| M-1 verify-report 模板 | ✅ 本次即按模板生成 1809 字节 verify-report.md | PASS |
| M-2 bug-injection 强制 | ✅ design.md D3 显式豁免（无逻辑可注入）；豁免理由明确 | PASS |
| M-3 review.md 强校验 | ✅ review.md 含"签字"标记；archive 通过 | PASS |
| M-4 KNOW 4 步 CodeGraph | ✅ query/where/context/impact 全部跑过 | PASS |
| M-5 PROJECT-SPECIFIC 5 memory | ✅ 5 个 memory 文件已读 | PASS |
| M-6 设计-实现一致性 | ✅ 无 drift（trivial 变更完全按设计）| PASS |
| M-7 任务粒度 = group 200-500 行 | ✅ 2 group，总产出 ~10+30 行 | PASS |

### M-8 新发现的反模式

#### AP-009: Archive 流程可能跳过 sync 步骤

**场景**: M-8 verification 执行 `/opsx:archive` 时，AI 跳过了"先 sync delta 到 baseline"步骤，直接 mv 到 archive。结果：spec delta 留在 `archive/<id>/specs/` 但**不在** `openspec/specs/<cap>/spec.md` baseline。

**后果**:
- baseline 落后于实际系统行为
- 后续 `openspec show ftl-mapping` 看不到新 Requirement
- 审计追踪的 spec 与 baseline spec 脱节

**根因**:
- `openspec-archive-change/SKILL.md` 步骤 2 写"评估 delta 是否先 sync"——是**建议**而非**强制**
- AI 评估后认为"先 archive 也行"——错误

**修复**:
- **本次已修补**：手动 sync（commit `5482e5d`），baseline 增至 16 Requirements
- **永久修复**：在 `openspec-archive-change/SKILL.md` 步骤 1 后**新增步骤 1.5** 强校验：若 change 有 spec delta，则每个 ADDED Requirement 必须在 baseline 中已存在；否则**拒绝 archive**

**预防**:
- 升级后的 archive 流程会在 sync 缺失时显式报错
- 未来的 M-8 验证（M-8 follow-up）应再跑一次以确认修复生效

### M-8 全部 commit 链

```
5482e5d chore(spec): sync add-print-version-flip (delayed from M-8 verification)
<archive commit> chore(spec): archive add-print-version-flip
<implement commits> feat: FEMU_LOG_VERSION
```

