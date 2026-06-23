## Why

FEMU bbssd FTL 当前以 LPN→PPA 的 flat array (`ssd->maptbl[lpn]`) 维护映射表，每次 host I/O 都对 maptbl 做随机访问。对**连续 LPN 范围的写入**（典型块 I/O 工作负载），这种细粒度访问存在两个问题：

1. **热路径冗余**：连续 host write 把 LPN×PPA 关系一对一拍平写入 maptbl，但 maptbl 的随机访问与连续写入的局部性不匹配。
2. **后续连续读全表扫描**：连续 host read 命中一段最近写入的连续 LPN 时，仍然逐 LPN 查询 maptbl，无法利用"最近写过的连续段"这一可推断关系。

CRT (Compressed Range Table) 作为 maptbl 之上的**只读最近写入段缓存**，在 host write 时记录 `(start_lpn, start_ppa, n_lpns)` 形式的连续段；host read 先查 CRT，命中则直接通过"重放 WP 推进"得到目标 PPA，未命中回退 maptbl。GC 写页和 trim 删除与被修改 LPN 段 overlap 的 CRT 条目以维持一致性。

## What Changes

- 新增 `bbssd/crt.h` / `bbssd/crt.c`：CRT 哈希表实现（开地址 + 线性探测，FIFO 淘汰），提供 `crt_init` / `crt_destroy` / `crt_insert` / `crt_lookup` / `crt_invalidate_lpn` / `crt_invalidate_range` / `crt_clear` 接口与 hit/miss/insert/invalidate/evict 计数。
- 在 `bbssd/ftl.c` 钩入 CRT：
  - `ssd_write` 末尾：当 `n_lpns >= THRESHOLD` 时，先 invalidate 被覆盖 LPN 段、再 insert 新段。
  - `ssd_read` 入口：逐 LPN 先查 CRT、命中则跳过 `get_maptbl_ent`、未命中走原路径。
  - `gc_write_page` / `gc_write_page_fdp_style`：relocate 后 invalidate 该 LPN。
  - `ssd_trim` / `ssd_trim_fdp_style` / `nvme_do_write_fdp`（FDP 写循环）：相应位置 invalidate。
  - `ssd_trim_fdp_style` 末尾（`ssd_reset_maptbl` 之后）：`crt_clear`。
- 新增 `ssdparams` 字段：`enable_crt` (默认 true), `crt_threshold_lpns` (默认 8), `crt_capacity` (默认 1024)。
- `bb_flip` admin 命令新增 `FEMU_RESET_CRT_STATS` / `FEMU_PRINT_CRT_STATS` 暴露统计。
- 新增 `tests/unit/crt_test.c`：单元测试覆盖正常路径、边界条件、错误路径（hash 冲突、淘汰、invalidate overlap、clear）。
- **Non-breaking**：仅优化读路径，写入与映射语义不变（maptbl 仍是 source of truth）；`enable_crt=false` 时行为与现状一致。

## Capabilities

### New Capabilities
- 无（CRT 属于 FTL 映射层的内部优化，不引入新能力边界）

### Modified Capabilities
- `ftl-mapping`: 增加新的 Requirement **"Contiguous Range Cache (CRT)"**，定义 LPN 段缓存的插入、查找、失效、FIFO 淘汰、统计暴露与禁用行为。现有 `### Requirement: LBA to PBA Translation` 的语义不变（maptbl 仍是唯一权威），CRT 仅作为"性能优化层"叠加其上。

## Impact

- **新增文件**：`bbssd/crt.h`、`bbssd/crt.c`、`tests/unit/crt_test.c`。
- **修改文件**：`bbssd/ftl.c`（4 处钩入 + 1 处 clear）、`bbssd/ftl.h`（`ssd` 结构体加 `struct crt *crt` 字段）、`nvme.h`（`FemuCtrl` / `ssdparams` 加配置字段）。
- **并发**：所有 CRT 调用位于单 `ftl_thread()` 内，**无需加锁**（见 `ftl.c:2435`）。
- **CodeGraph 查询**：`codegraph where ssd_write` / `ssd_read` / `ssd_trim` / `gc_write_page` / `gc_write_page_fdp_style` / `nvme_do_write_fdp` —— 确认所有 maptbl 写入点都已覆盖。
- **适用 Superpowers 铁律**：
  - **test-coverage** —— 每个 CRT API 需单测；正常 / 边界 / 错误路径齐全。
  - **verification-before-completion** —— Review Gate 必须跑通 bug 注入验证（篡改一项 CRT 条目 PPA、读路径要么命中错误值要么回退 maptbl、行为可解释）。
  - **systematic-debugging** —— 任何一致性 bug 必须先重现、再读 maptbl vs CRT 状态、形成 hypothesis、最小修复。
- **暂不覆盖**：`csd` / `ocssd` / `zns` / `nossd` 其它 FTL；LRU 淘汰；持久化（重启清空）。
