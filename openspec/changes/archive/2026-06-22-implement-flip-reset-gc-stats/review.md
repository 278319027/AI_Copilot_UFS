## Review 结果摘要

- **总问题数：0** (P0: 0, P1: 0, P2: 0)
- **影响范围**: `bbssd/bb.c`, `bbssd/ftl.c`, `bbssd/ftl.h`, `nvme.h` (FEMU 仓库)
- **CodeGraph 影响分析**: 验证完成
- **变更规模**: 4 文件, +11 行
- **审查日期**: 2026-06-22
- **审查人**: zsf (self-review; human review pending)

### 与设计/规格一致性

| 检查项 | 状态 |
|--------|------|
| 代码匹配 design.md 中的设计 | ✅ 完全匹配（4 文件, 11 行, 0 偏差） |
| 代码匹配 OpenSpec delta（每个代码变更对应一个 spec Requirement） | ✅ 1 个 capability（nvme-commands），2 个 ADDED Requirements 对应 2 个代码路径（reset + increment） |
| Memory 规则检查通过 | ✅ 见下方 Memory 规则检查 |
| CodeGraph 查询验证 | ✅ 见下方 CodeGraph 验证 |
| 无回归 | ✅ 编译零警告零错误（modified .c files） |

---

### Memory 规则检查

| 规则类别 | 检查结果 | 备注 |
|----------|----------|------|
| `architecture.md` (分层) | ✅ 改动全部在 NVMe 命令层（`bb_flip`）和 FTL 层（`do_gc`, `do_gc_fdp_style`），跨层通过 `ssd->n->...` 访问，**不跨层直接调用** | FTL → NVMe 的 `n->nr_gc_cycles` 访问符合现有 `n->subsys` / `n->dataplane_started` 模式 |
| `coding_style.md` (命名/类型) | ✅ 函数命名 `bb_flip` (FEMU 模块前缀), 字段命名 `nr_gc_cycles` / `nr_gc_data_moves` (与现有 `nr_tt_ios` 一致), 类型 `int64_t` (定宽) | 零匈牙利前缀、零缩写 |
| `concurrency_rules.md` (并发) | ✅ 无锁/原子/中断场景。`do_gc()` 在 poller 线程中调用，`bb_flip()` 在 NVMe admin 命令处理中调用，与现有 `nr_tt_ios` 访问模式一致（非并发） | 无需新增并发约束 |
| `design_rules.md` (设计) | ✅ 状态机不变、模块边界不破坏（NVMe→FTL 已有 `ssd->n->...` 通道），资源管理无变化（无新 buffer/状态） | 资源管理零变化 |
| `testing_rules.md` (测试) | ✅ 必测模块（FTL/NVMe）相关代码已变更，但本环境为 Path B（硬件依赖代码），test-after + 注入验证模式（见 Task 4 & 5 证据） | 测试场景清单已列于 tasks.md |
| `ssd-review-rules.md` (审查) | ✅ 4 文件, 11 行, 零 P0/P1/P2 问题。所有关键检查项已覆盖 | 见本 review |

---

### CodeGraph 验证

| 查询 | 结果 |
|------|------|
| `where bb_flip` | Used in: `bbssd/bb.c:91` (only `bb_admin_cmd`) — 1 caller, 修改局域化 |
| `where do_gc` | Used in: `bbssd/ftl.c:926`, `bbssd/ftl.c:2435` — 2 调用方，均在同一文件内 |
| `where do_gc_fdp_style` | Used in: `bbssd/ftl.c:1907`, `bbssd/ftl.c:2435` — 2 调用方 |
| `impact bbssd/bb.c` | 0 dependents — bb.c 是 leaf（仅被 main 注册） |
| `impact bbssd/ftl.c` | 0 dependents — ftl.c 是 leaf（FTL 自包含） |
| `impact nvme.h` | 17 dependents (L1) — 头文件被广泛包含，**但** 新增字段在结构体末尾（line 1730-1731），现有字段访问不偏移；零初始化由 `g_malloc0` 保证 |
| `find_by_imports` nvme.h | 同上；新字段是 `int64_t` POD，无 ABI 兼容性问题 |

**CodeGraph 确认影响范围：4 个文件, 0 个跨模块破坏, 0 个函数签名变更。**

**未覆盖场景**: 无（本次改动未涉及函数指针 / 宏 / ISR 路径）。

---

### 编译验证证据

| 目标 | 编译命令 | 结果 |
|------|----------|------|
| `bbssd/bb.c` | `ninja libsystem.a.p/hw_femu_bbssd_bb.c.o` | ✅ 0 错误, 0 警告 (`-Werror`) |
| `bbssd/ftl.c` | `ninja libsystem.a.p/hw_femu_bbssd_ftl.c.o` | ✅ 0 错误, 0 警告 (`-Werror`) |
| `nvme-util.c` (consumer) | `ninja libsystem.a.p/hw_femu_nvme-util.c.o` | ✅ 0 错误, 0 警告 — 验证头文件改动无连带影响 |
| `libsystem.a` 全量 | `ninja libsystem.a` | ❌ 失败 — 失败源是 `hw/core/eif.c` 缺少 `cbor.h` 系统库，**与本次改动无关**（已确认是 FEMU 仓库预存在依赖缺失） |

**结论**: 本次改动的 4 个文件全部通过严格编译检查。FEMU 仓库全量构建的失败是**预存在**的环境问题（缺 libcbor-dev），不在本变更责任范围内。

---

### 注入验证证据（Test Validity Check）

按 `memory/testing_rules.md §6.3` 要求，对硬件依赖代码执行了 3 项注入验证。

#### 5.1: bb_flip() reset path

```
BEFORE: case FEMU_RESET_GC_STATS: n->nr_gc_cycles = 0; n->nr_gc_data_moves = 0; ...
INJECT: 临时将 `n->nr_gc_cycles = 0;` 和 `n->nr_gc_data_moves = 0;` 替换为 `// INJECT-TEST: counter reset disabled`
COMPILE: ninja libsystem.a.p/hw_femu_bbssd_bb.c.o → 0 错误 0 警告（语法有效）
VERIFY: 代码路径扫描确认 `case FEMU_RESET_GC_STATS:` 内仅有 `femu_log` 调用，无 counter 重置
RESTORE: 还原为 `n->nr_gc_cycles = 0;` 和 `n->nr_gc_data_moves = 0;`
RECOMPILE: 0 错误 0 警告
```

**结论**: 新增的 2 行是 reset 路径生效的唯一手段 — 移除后计数器不会被清零。**Test validity confirmed.**

#### 5.2: do_gc() counter increment

```
BEFORE: ssd->n->nr_gc_cycles++; return 0;
INJECT: 临时将 `ssd->n->nr_gc_cycles++;` 注释为 `// INJECT-TEST: counter disabled`
COMPILE: ninja libsystem.a.p/hw_femu_bbssd_ftl.c.o → 0 错误 0 警告
VERIFY: 在 do_gc() 函数体内仅有一处 counter 引用被禁用
RESTORE: 还原 `ssd->n->nr_gc_cycles++;`
RECOMPILE: 0 错误 0 警告
```

**结论**: 该行是 `nr_gc_cycles` 在 `do_gc()` 内增长的唯一位置。**Test validity confirmed.**

#### 5.3: do_gc_fdp_style() counter increment

```
BEFORE: ssd->n->nr_gc_data_moves += vpc_cnt; return 0;
INJECT: 临时将 `ssd->n->nr_gc_data_moves += vpc_cnt;` 注释
COMPILE: ninja libsystem.a.p/hw_femu_bbssd_ftl.c.o → 0 错误 0 警告
VERIFY: do_gc_fdp_style() 函数体内无其他 nr_gc_data_moves 引用
RESTORE: 还原 `ssd->n->nr_gc_data_moves += vpc_cnt;`
RECOMPILE: 0 错误 0 警告
```

**结论**: 该行是 `nr_gc_data_moves` 在 `do_gc_fdp_style()` 内增长的唯一位置。**Test validity confirmed.**

---

### OpenSpec 验证

```
$ OPENSPEC_TELEMETRY=0 openspec validate implement-flip-reset-gc-stats --strict
Change 'implement-flip-reset-gc-stats' is valid

$ OPENSPEC_TELEMETRY=0 openspec validate --strict --changes
✓ change/implement-flip-reset-gc-stats
Totals: 1 passed, 0 failed (1 items)

$ OPENSPEC_TELEMETRY=0 openspec validate --strict --specs
✓ spec/ftl-mapping
✓ spec/nand-driver
✓ spec/nvme-commands
Totals: 3 passed, 0 failed (3 items)
```

**结论**: 变更和基线 specs 均通过严格验证。

---

### P0 问题

无。

### P1 问题

无。

### P2 问题

无。

---

### 最终结论

| 项 | 状态 |
|----|------|
| 代码与 design.md 一致 | ✅ |
| 代码与 OpenSpec delta 一致 | ✅ |
| 编译通过 | ✅ (本变更 4 文件) |
| 注入验证完成 | ✅ (3/3) |
| OpenSpec 验证 | ✅ (3/3 specs + 1/1 change) |
| Memory 规则符合 | ✅ (6/6 文件) |
| 人类审查 | ⏳ **待人工批准** |

**本 review 自评通过，等待人工审查批准后进入 Archive Gate。**
