## Context

FEMU bbssd FTL 在 `bbssd/ftl.c` 维护 `ssd->maptbl[lpn]` flat array（LPN→PPA），所有 host I/O 路径在单 `ftl_thread()` (`ftl.c:2435`) 内串行访问该表。host write 路径逐 LPN 调用 `get_new_page()` + `set_maptbl_ent()`（`ftl.c:949-967`）；host read 逐 LPN 调用 `get_maptbl_ent()`（`ftl.c:906-921`）；GC 通过 `gc_write_page`/`gc_write_page_fdp_style` relocate 有效页并更新 maptbl；trim/DSM 通过 `ssd_trim` 清理 maptbl；FDP trim 走 `ssd_trim_fdp_style` 全表清零（`ftl.c:2353`）。

连续 LPN 范围的写入将 LPN→PPA 关系按 WP 顺序（ch→lun→pg→blk→pl）一拍一拍推进。**单次 host write 内的 N 个连续 LPN 获得的 N 个 PPA 是 N 次连续 `get_new_page()` 调用的返回值**，PPA 字段（bitfield）不形成线性计数器，但步进规则是确定的。

本变更引入 CRT（Compressed Range Table）作为 maptbl 之上的**只读最近写入段缓存**。CRT 用开地址 hash 表存 `(start_lpn, start_ppa, n_lpns)`，host read 命中则通过"重放 WP 推进 offset 次"得到目标 PPA，未命中回退 maptbl。

## Goals / Non-Goals

**Goals:**
- 在连续 host write 时把 `(slpn, start_ppa, n_lpns)` 写入 CRT；n_lpns ≥ 阈值（默认 8）才记录，避免零碎项污染 hash 表。
- 在 host read 时对每个 LPN 先查 CRT；命中则跳过 `get_maptbl_ent` 并通过 WP 重放得到 PPA；未命中走原路径。
- 在 GC relocate、trim、host write overwrite 时，正确 invalidate 与被修改 LPN 段 overlap 的 CRT 条目。
- 暴露 hit/miss/insert/invalidate/evict 计数与 reset 接口；可通过 `enable_crt=false` 完全禁用。
- 单元测试覆盖：插入、查找命中/未命中、overlap invalidate、hash 冲突、FIFO 淘汰、clear、并发安全（单线程假设）。
- 不改变 maptbl 语义或外部可见行为；现有所有场景在新代码下行为一致。

**Non-Goals:**
- csd / ocssd / zns / nossd 等其他 FTL 不在本次范围。
- 持久化：FEMU 重启后 CRT 为空（首次 host write 后才填充）。
- LRU 淘汰 / 引用计数：v1 用 FIFO 满载驱逐。
- CRT 项的版本号 / 单 LPN 多版本：v1 用 overlap invalidate 单调删除模型。
- 写路径性能优化：v1 仅优化读路径。

## Decisions

### D1. CRT 作为只读缓存（不写 maptbl）

- **选择**：CRT insert/invalidate 只动 `ssd->crt` 自己的表，不修改 `maptbl`。
- **理由**：maptbl 是 source of truth；CRT 是优化层，简化一致性模型——所有路径（write/GC/trim）改 maptbl 的同时必须显式 invalidate CRT 覆盖区段，反之 CRT 不影响 maptbl。
- **备选**：写 CRT 时也改 maptbl（双写）—— 增加不一致风险、调试难度，否决。

### D2. 重放 WP 推进（不存 PPAs 数组）

- **选择**：item 存 `(start_lpn, start_ppa, n_lpns)`，lookup 命中时调用 `ppa_advance(ppa, offset)` 重放 WP 推进规则 `ch → lun → pg → blk → pl`。
- **理由**：每项内存开销低（24 B vs 64 B @ 8 LPNs），hash 桶固定大小。
- **风险**：WP 推进规则需与 `ssd_advance_write_pointer()` (`ftl.c:260`) 严格一致；任何不匹配都会产生静默 PPA 计算错误。
- **缓解**：
  - 抽出 `ppa_advance(struct ssdparams *, struct ppa, int n)` 纯函数，单测覆盖：跨 ch 边界、跨 lun 边界、跨 pg 边界、跨 blk 边界、跨 pl 边界、n=0、n 超过当前 line 剩余容量。
  - bug 注入：故意把 `ppa_advance` 的 ch 步进顺序写反，跑已有 host write→read 测试，期望读出错误值或 fallback，验证能定位。
- **备选**：存 PPAs 数组——绝对正确但内存 8 B/LPN（@ 8 LPNs 多 64 B/项），否决。

### D3. 失效粒度：单 LPN invalidate

- **选择**：`crt_invalidate_lpn(ssd, lpn)` 与 `crt_invalidate_range(ssd, lpn_lo, lpn_hi)` 两接口；GC/trim 调用前者（GC 一次 relocate 一页，trim 调用前者循环或用 range），host write 末尾用 range。
- **理由**：trim/GC 各自一次只影响 1 个 LPN（GC relocate）/ 一段连续 LPN（trim range / write range）；range 接口只在 write 末尾调用一次，简化热路径。
- **实现**：单 LPN invalidate 退化为"找所有 `start_lpn ≤ lpn < start_lpn + n_lpns` 的桶"，linear probing 遍历一次 + 二次扫描到下一空桶。

### D4. 哈希表：开地址 + 线性探测，固定桶数组

- **选择**：`struct crt_entry { uint64_t start_lpn; struct ppa start_ppa; uint32_t n_lpns; uint32_t valid; }`，桶数 = `crt_capacity`（默认 1024），hash 函数 = `start_lpn * 0x9E3779B97F4A7C15ULL >> (64 - log2(cap))`。
- **理由**：实现简单、cache-friendly、避免链表分配；线性探测在 cap=1024、装载率 < 0.7 时性能足够。
- **满载驱逐**：insert 时若表满，调用 `crt_evict_oldest()`（FIFO 顺序），统计 `evict_count` +1 + 一次性 warn log。

### D5. 阈值与默认配置

- `enable_crt = true`：FEMU_BB 默认 `true`（FEMU_BB_PARAMS_DEF_SP5 默认行为保持）。
- `crt_threshold_lpns = 8`（= 64 LBAs @ secs_per_pg=8）。
- `crt_capacity = 1024`。
- 通过 `n->bb_params.crt_*` 字段在 `ssd_init_params()` (`ftl.c:340`) 读入 `ssd->sp`。

### D6. 钩入点（CodeGraph 验证的 6 个 set_maptbl_ent 调用点）

| 调用点 | 文件:行 | 钩入动作 |
|---|---|---|
| `ssd_write` 写循环 | `ftl.c:960` | 循环结束**前** invalidate range；循环结束**后** insert |
| `ssd_read` 读循环 | `ftl.c:907` | 入口先 `crt_lookup`，命中直接用 |
| `gc_write_page` | `ftl.c:759` | `set_maptbl_ent` 之后 `crt_invalidate_lpn(lpn)` |
| `gc_write_page_fdp_style` | `ftl.c:1622` | 同上 |
| `ssd_trim` 范围循环 | `ftl.c:1040` | 之后 `crt_invalidate_lpn` |
| `nvme_do_write_fdp` 写循环 | `ftl.c:2030` | 同 ssd_write |
| `ssd_trim_fdp_style` 末尾 | `ftl.c:2426` 附近 | `crt_clear`（maptbl 全清零后） |

### D7. 统计与暴露

- `struct crt` 含 `uint64_t hit, miss, insert, invalidate, evict`。
- `bb_flip` admin 命令新增：`FEMU_RESET_CRT_STATS` (cdw10) 复位、`FEMU_PRINT_CRT_STATS` 打印当前值。
- 不通过 `get_log` 路径，避免与现有 NVMe GetLog 解析逻辑耦合。

### D8. 并发：单线程无锁

- 所有 CRT 调用栈均位于 `ftl_thread()` 内（read/write/trim/GC 都在 `ftl_thread` 串行执行）。
- **不需要 mutex**——违反直觉但正确：FTL 是 actor 模型。
- 单测不模拟多线程，但需在 commit msg 写明"无锁假设 = FTL 单线程"。

## Risks / Trade-offs

- **R1: PPA 推进重放错位** → 缓解：D2 已述。Code review 时必须逐字段对照 `ssd_advance_write_pointer` (`ftl.c:260-310`)。
- **R2: 阈值太小导致 hash 抖动** → 缓解：默认 8 LPNs，LOAD factor < 0.7；如果实测命中率 < 30%，文档化建议调高阈值。
- **R3: trim 范围大时 invalidate 性能差** → 缓解：trim range 仍要逐 LPN invalidate（trim 本身就要逐 LPN `set_maptbl_ent`，故 invalidate 与其等成本）；不引入段级 split。
- **R4: GC 时 CRT 项中包含正在 relocate 的 LPN，会被错误地"加速"读** → 缓解：`gc_write_page` 强制 invalidate 该 LPN（顺序保证：maptbl 写完才 invalidate CRT，不会读到旧值；即使读到旧值，下一次 host read 也会再次查 CRT 命中已被新写入覆盖的项——但已 invalidate，所以 fallback maptbl）。
- **R5: FDP trim 之后 CRT 残留** → 缓解：`ssd_trim_fdp_style` 末尾 `crt_clear()`。
- **R6: 并发误用** → 缓解：design.md + crt.h 注释明确"FTL thread only"；`ppa_advance` 是纯函数可在任意线程调用。
- **R7: 内存泄漏** → 缓解：`ssd_exit` 路径（`femu.c` 已有清理钩子）调 `crt_destroy(ssd)`，free 桶数组。
- **R8: 单元测试不能覆盖真实 NAND 时序** → 缓解：硬件依赖代码（`ssd_advance_status` 等）通过 `lsp_diagnostics` 静态扫描 + 编译验证；纯逻辑（`crt_*`、`ppa_advance`）单测覆盖。
- **R9: `ssd->sp` 在 `ssd_init_params` 之后才有效** → 缓解：`ssd_init` 调用顺序保证 `ssd_init_params` → `ssd_init_maptbl` → `ssd_init_crt`（新增），CRT init 读 `crt_capacity` 已安全。
