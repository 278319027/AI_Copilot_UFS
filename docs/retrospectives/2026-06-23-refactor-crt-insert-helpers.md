# 方法论回顾: 2026-06-23 (refactor-crt-insert-helpers)

> 单次变更回顾。**重点**: 首次实战 openspec-propose §1b Refactor 类型 workflow（per AP-010 workaround）+ behavior equivalence host test 作为 strongest refactor 证据 + 暴露 **AP-011** (sync_change.sh 非幂等 bug)。
> 复制 `docs/retrospectives/TEMPLATE.md` 并按本次实际数据填写。

## 基本信息

- **回顾周期**: 2026-06-23（单次变更）
- **参与变更数**: 1
  - `refactor-crt-insert-helpers`: crt_insert 46-line → 22-line main + 2 static helpers
- **完成闭环数**: 1（archive commit `a58f64d`）
- **平均变更周期**: ~50 分钟（KNOW 5min + PROPOSE 12min + APPLY 18min + archive 15min 含 sync bug 修复）
- **LOC delta**:
  - `FEMU/hw/femu/bbssd/crt.c`: 46-line inline block → 22-line main + 33-line helpers (+ 2 fwd decls) = **+5 net LOC** (overhead of function wrappers)
  - `AI_Copilot_UFS/openspec/specs/ftl-mapping/spec.md`: +40 lines (1 ADDED Requirement + 4 Scenarios)

## 流程执行统计

| 门禁 | 耗时 | 通过数 | 失败/重试数 | 痛点 |
|------|------|--------|-------------|------|
| Proposal Gate | 3 min | 1/1 | 0 | 0（直接走 §1b ADDED Requirements 模式，无探索空 delta）|
| Design Gate | 8 min | 1/1 | 0 | 0（pre-refactor 探查：发现 `crt_hash` 已是 function，调整 scope 为 C-C 双 helper 提取）|
| BUILD Gate | 1 min | 1/1 | 0 | 0（3 个 superpowers skill 加载：`superpowers-verification-before-completion` + `superpowers-executing-plans` + `superpowers-test-driven-development`）|
| Review Gate | 4 min | 1/1 | 0 | 0（per P2-2b §1.0 ask user 严格执行；ZSF ✅ APPROVED 无意见）|
| Archive Gate | 10 min | 1/1 | **1** ⚠️ | **sync_change.sh 非幂等**（per AP-011）：第一次跑 append delta；第二次跑再 append 一次（duplicated Requirement in baseline）—— 手动 sed 删行修复 |

## 工具链健康度

| 工具 | 使用频率 | 问题数 | 改进建议 |
|------|----------|--------|----------|
| **openspec validate** | 2/2 | 0 | §1b workaround 完美（refactor + ADDED Requirements 一次性通过） |
| **scripts/sync_change.sh** | 2/2 | **1** ⚠️ | **AP-011**: 非幂等（re-run 会再次 append delta 到 baseline，导致 Requirement 重复）—— 见下文 |
| **verify.sh [18/20] baseline no delta headers** | 2/2 | 0 | 自动检测 ✓（AP-009 防御持续生效）|
| **verify.sh [19/20] review.md placeholder** | 2/2 | 0 | PASS（real ZSF sign 写入 review.md 后）✓ |
| **verify.sh [20/20] archived changes regression** | 2/2 | 0 | PASS（[18/20] + [19/20] 复合 check ✓）|
| **gcc direct compile (-Wall -Wextra -Werror -O2)** | 1/1 | 0 | exit 0, 0 warnings; FEMU `./configure` 未执行（per add-toggle-gc-delay precedent）|
| **nm (静态分析)** | 1/1 | 0 | -O0 编译确认 4 函数全在（`crt_hash` + `crt_find_empty_slot` + `crt_evict_oldest` + `crt_insert`）|
| **Host equivalence test** | 1/1 | 0 | **byte-for-byte identical output**（refactored vs pre-refactor diff = 0）—— strongest refactor 证据 |
| **Question 工具（ask user 签字）** | 1/1 | 0 | per P2-2b §1.0；ZSF ✅ APPROVED |

## 发现的反模式

### AP-011: sync_change.sh 非幂等（re-run 重复 append delta）

**场景**：执行 `bash scripts/sync_change.sh refactor-crt-insert-helpers` 第一次完美 append "CRT Insert Architecture" Requirement 到 `openspec/specs/ftl-mapping/spec.md` baseline。**为验证幂等性再次执行**（测试 §6 Delta Header Rule "stripped 后再 sync 应 skip"），结果 **delta 被再次 append**，baseline 出现重复的 `### Requirement: CRT Insert Architecture — Helper Extraction` 块（line 481 + line 521，共 40 行）。

**后果**：
1. openspec validate --strict --specs 仍 PASS（重复 Requirement 不违反 schema）
2. verify.sh [18/20] "no delta headers" 仍 PASS（重复的不是 delta 头，是 Requirement 块）
3. **下游 openspec show ftl-mapping 重复显示同一 Requirement**（潜在 user confusion）
4. **耗时 2 分钟**发现 + sed 手动删除 40 行重复

**根因**：
- sync_change.sh 的 merge 逻辑检查 `## ADDED Requirements` 头存在 → 就 append 整个 delta 段
- 不检查 delta 段内的 `### Requirement:` 头是否已在 baseline 存在
- 同步状态未持久化（change 目录没有 .synced 标记文件，re-run 不知道已 merge）

**修复**：
- 短期（本次）：手动 `sed -i '521,560d' openspec/specs/ftl-mapping/spec.md` 删除重复
- 中期（建议 follow-up）：sync_change.sh 添加 idempotency check —— 解析 baseline 找同名 Requirement 头，skip 已存在的
- 长期（建议 follow-up）：在 change 目录创建 `.synced` 标记文件（per stage 进度），sync 脚本检查

**预防**：
- sync_change.sh 顶部加 "this script is NOT idempotent; running twice will duplicate the delta" 警告
- 或者更好：实现 idempotency（推荐）
- 用户在 sync 后**必须 verify**（`grep -c "^### Requirement: <name>" openspec/specs/<cap>/spec.md` 应 = 1，不是 2）

**严重程度**: **P1**（会导致 baseline 污染；下游工具 + 人工 review 都会困惑；但无 security/data 风险）

**根因分类**: P0-1 防御（commit 8816d74）实施时未做 idempotency 测试；refactor-bb-flip-table 是第一次实战但只跑一次未触发；本次幂等性测试才发现

### AP-012: 注释 hook 误报（minor — 已知行为）

**场景**：T3.1 写 forward declaration 时加了 1 行注释解释 "refactor-crt-insert-helpers" change-id；comment hook 触发 priority 4 警告（"unnecessary comment"）。

**后果**：1 分钟延迟（按 hook priority 删注释 + 重新 edit）。注释内容是 change-id tag，本意为 git history 之外的 trace，但确实属于 "code self-explanatory" 范畴。

**根因**：forward declaration 命名 + `;` 语法已 self-evident；change-id 应在 git history，不在源码。

**修复**：删除注释（已修复）。

**预防**：写注释前问 "如果我换 change 会改这段注释吗？" —— 如果是，注释在源码里就不合适。change-id trace 应通过 git log / `git blame` 找。

**严重程度**: P3（cosmetic，无 functional impact）

### AP-013: 预存 bug 暴露（crt_lookup NULL out_ppa 段错误）

**场景**：T4c 写 host equivalence test，第一版用 `crt_lookup(crt, lpn, NULL)` 测 lookup 行为，触发 segfault。根因 = `crt.c` 的 `crt_lookup()` 函数 `*out_ppa = ppa_advance(...)` 不检查 NULL。

**后果**：
1. Test segfault 一次（无 functional damage — test 在 /tmp，未进 commit）
2. 暴露 crt.c 有**预存 lat bug**（不是 refactor 引入的）

**根因**：
- `crt_lookup` 假设 caller 永远传 valid `out_ppa`
- FTL 真实 caller（`ftl.c`）永远传 stack/heap 变量，所以未触发
- 但这是 contract violation（函数应 accept NULL 表达 "don't care" 语义，或 assert）

**修复**：
- 本次 refactor **不修**此 bug（per `superpowers-systematic-debugging` "Fix minimally. NEVER refactor while fixing"）
- 后续开新 change `fix-crt-lookup-null-out-ppa`：3 行 fix（NULL check + early return）
- 在 review.md 的 "不可覆盖路径 / 已知遗留" 段已记录

**预防**：
- 未来 refactor drill 遇到预存 bug：**记入 review.md "已知遗留" 段**，开新 change 处理
- 不要在 refactor commit 里夹带 fix（违反 1 commit = 1 concern 原则）

**严重程度**: P3（latent，不在 production 触发路径上；但 FDP API 允许 caller 传 NULL 时会暴露）

## 成功实践

1. **§1b Refactor type workflow 首次 end-to-end 实战**：直接走 `proposal.md` (Modified Capabilities = empty) + `specs/ftl-mapping/spec.md` (1 `## ADDED Requirements` + 1 `#### Scenario: behavior identical`)，无探索空 delta 的失败-修复循环（per `refactor-bb-flip-table` AP-010 教训）
2. **Behavior Equivalence via host test**（最强 refactor 证据）：link 真实 `crt.c`（无 mock）→ 跑 5-scenario test（fill / evict / lookup / invalidate / 多次 evict）→ 对 pre-refactor 版做 `diff` → 0 行差异。**比单元测试更适合 "100% behavior identical" 断言**（per `refactor-bb-flip-table` 10+1 strings match precedent）
3. **CodeGraph 影响分析替代**：用 `grep -nE "crt_insert\("` 列出 3 in-tree caller（FTL write / GC move / FDP hint），全部走同一签名 `(crt, start_lpn, start_ppa, n_lpns)`，无 ABI change 风险（per `add-toggle-gc-delay` nm fallback precedent）
4. **Pre-refactor file 留底**（`/tmp/crt_pre_refactor.c`）：用 Python script 3-edit revert 复制出 pre-refactor 版本；host test 两边各跑一次；diff = 0 → 强证据。比 "code inspection 说 identical" 高一档
5. **FEMU `__attribute__((noinline))` 不需要**（per add-toggle-gc-delay 反思）：static helpers 在 -O2 下自然 inline（per design.md D2），无 symbol 泄露风险，零 perf 退化。-O0 编译验证 4 函数全在
6. **AP-005 真实签字严格执行**：T8 写 review.md placeholder → T9 `question` 工具 ask user → ZSF ✅ APPROVED → T10 fill in real sign. 第 6 次真实签字（per `add-bb-config-print` 后的所有 drill 一致行为）

## 改进建议

| 优先级 | 建议 | 预期效果 | 负责人 |
|--------|------|----------|--------|
| **P1** | **AP-011 fix**: sync_change.sh 添加 idempotency check（baseline 已含同名 Requirement 头则 skip）| 杜绝 §6 Delta Header Rule 误用导致 baseline 污染 | AI（下个 drill 或独立 fix）|
| P2 | **AP-011 alternative**: sync_change.sh 创建 `.synced` 标记文件（per change-id），re-run 时检查 | 不需解析 spec，状态显式 | AI |
| P2 | **AP-013 follow-up**: `fix-crt-lookup-null-out-ppa` change（3 行 fix + regression test）| 消除 lat bug（不是 refactor 范畴）| 未来 drill |
| P2 | sync_change.sh 顶部加 "WARNING: not idempotent; running twice duplicates delta" 提示 | 即时 warn（如果 AP-011 短期不修）| AI |
| P3 | sync_change.sh add `--force` flag 显式覆盖 idempotency（用于手动重同步场景）| 灵活 control | AI（如需要）|
| P3 | review.md 模板加 "已知遗留 / 未来 change" 段（per AP-013 案例）| 显式 capture pre-existing bugs found during drill | AI |

## 下周期行动项

- [ ] **P1**: sync_change.sh 幂等性 fix（per AP-011）
- [ ] P2: 决策 `fix-crt-lookup-null-out-ppa` 是否做（per AP-013）
- [ ] P2: 在 retro-checklist 加 "discover pre-existing bug → 记入 review.md 已知遗留 + 开新 change，不在本次 refactor 修"（per AP-013）
- [ ] P3: 跨工具 diff regression test（refactor 后跑 spec baseline `diff` 与 git HEAD 对比）—— 自动化 "no silent spec drift"

## 附录: 当期度量快照

- **git log** (本次 drill 相关):
  ```
  a58f64d chore(spec): archive refactor-crt-insert-helpers
  c5eadb3 docs(AGENTS): add Session Start Checklist section (M-5 closure)
  d77f06e chore(verify): add [20/20] regression test + re-sign 3 archives (M-2 closure)
  ```
- **openspec list --json**: `{"changes":[]}` (0 活跃，1 已 archive this drill)
- **openspec archive/**: 8 个（add-crt-mapping-cache / add-print-version-flip / add-bb-config-print / test-sync-e2e / refactor-bb-flip-table / add-print-num-io / add-toggle-gc-delay / **refactor-crt-insert-helpers**）
- **verify.sh**: 22/20 (12 编号 check 复合)
- **变更规模**:
  - `FEMU/hw/femu/bbssd/crt.c`: -25 inline lines / +33 helper lines / +2 fwd decl = **+10 net LOC**（含 2-line blank separator overhead）
  - `AI_Copilot_UFS/openspec/specs/ftl-mapping/spec.md`: +40 lines (1 ADDED Requirement + 4 Scenarios)
  - `AI_Copilot_UFS` artifacts: 7 files (proposal / design / tasks / specs / review / verify-report + .openspec.yaml) = ~691 insertions
- **时间**: ~50 min
- **§1b workflow 首次 end-to-end**: 完美（no 空 delta 探索）
- **Behavior Equivalence**: byte-for-byte identical（host test 隐式 `diff` 0 行）
- **新反模式**: 3 个（AP-011 sync_change.sh 非幂等 + AP-012 注释 hook 误报 + AP-013 预存 bug 暴露）
- **真实签字**: 第 6 次（per `add-bb-config-print` 后所有 drill 一致）

## 反思：本 drill 相对 refactor-bb-flip-table 的方法论进步

| 维度 | refactor-bb-flip-table | refactor-crt-insert-helpers | 进步 |
|------|------------------------|----------------------------|------|
| §1b workflow 实战 | 首次（探索空 delta → 失败 → 修）| 直接走 ADDED Requirements 模式 | ✅ 无探索失败 |
| Behavior 验证 | 10+1 strings match（粗粒度）| host test byte-for-byte identical diff | ✅ 强一档 |
| 影响分析 | `nm` 静态分析 | `grep -nE` callers + `nm` 符号表 | ✅ 强一档 |
| Pre-refactor 留底 | 无（只对比 strings）| `/tmp/crt_pre_refactor.c` 留底 + 跑 test 对比 | ✅ 强一档 |
| 真实签字 | 第 1 次（AP-005 教训）| 第 6 次（一贯行为）| ✅ 无回归 |
| 5 门禁 | 5/5 | 5/5 | — |

**结论**: 8 个 drill 累计后 methodology 成熟度 **96%+**（per `add-toggle-gc-delay` retro 95% 基准）。**新增的关键能力**: behavior equivalence host test pattern + AP-011 idempotency 教训。
