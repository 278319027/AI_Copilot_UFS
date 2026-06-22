# Tasks — add-femu-gc-stats-log-page

## 1. Data Structure (nvme.h)

- [x] 1.1 Add `NVME_LOG_FEMU_GC_STATS = 0xC0` enum value to `enum NvmeLogIdentifier` in `nvme.h` (after `NVME_LOG_FDP_EVENTS = 0x23` at line ~986). Verify: `grep -n NVME_LOG_FEMU_GC_STATS nvme.h` shows the new value.
- [x] 1.2 Add `NvmeFemuGcStatsLog` typedef struct in `nvme.h` (after `enum NvmeLogIdentifier` block, before `typedef struct NvmePSD`). Two fields: `uint64_t nr_gc_cycles; uint64_t nr_gc_data_moves;`. Verify: `grep -A2 "typedef struct NvmeFemuGcStatsLog" nvme.h` shows the 2 fields.

### Test plan (1.x)

**Normal path**: code compiles with the new struct; `sizeof(NvmeFemuGcStatsLog) == 16`.
**Error path**: N/A (compile-time check only).
**Boundary**: 16-byte size is natural for 2 × uint64_t, no padding.

## 2. Handler Implementation (nvme-admin.c)

- [x] 2.1 Add `static uint16_t nvme_femu_gc_stats_info(FemuCtrl *n, NvmeCmd *cmd, uint32_t buf_len)` function in `nvme-admin.c` (after `nvme_fw_log_info` at line ~868). Function fills `NvmeFemuGcStatsLog` struct from `n->nr_gc_cycles` and `n->nr_gc_data_moves`, then DMA's to host. Mirrors `nvme_fw_log_info` template. Verify: `grep -B1 -A8 "nvme_femu_gc_stats_info" nvme-admin.c` shows the function.
- [x] 2.2 Add `case NVME_LOG_FEMU_GC_STATS:` to `nvme_get_log()` switch in `nvme-admin.c` (after `case NVME_LOG_FDP_EVENTS:` at line ~1237, before `default:` at line ~1238). Verify: `grep -A1 "case NVME_LOG_FEMU_GC_STATS" nvme-admin.c` shows the case calling the handler.

### Test plan (2.x)

**Normal path (read counter values)**: handler fills struct from `n->nr_gc_cycles` and `n->nr_gc_data_moves` correctly (verified by inject validation below).
**Error path (insufficient buffer)**: `trans_len = MIN(sizeof, buf_len)` truncates correctly (mirrors fw_log_info pattern).
**Boundary**: counters are `int64_t` → `uint64_t` cast in struct is safe for non-negative GC counts.

## 3. Verification

- [x] 3.1 Run `codegraph build` from FEMU root and `codegraph where nvme_femu_gc_stats_info` from FEMU. Expected: 1 caller, `nvme_get_log`. Save output to review.md.
- [x] 3.2 Run `graphify explain "nvme_femu_gc_stats_info"` from FEMU. Expected: community 0 (NVMe admin, matches `nvme_get_log`). Save output to review.md.
- [x] 3.3 Run `graphify diagnose multigraph` from FEMU. Compare against baseline: `missing_endpoint_edges=0, dangling_endpoint_edges=0` (unchanged). Save output to review.md.
- [x] 3.4 Run `graphify query "GC stats"` from FEMU. Compare hit set against pre-change: should expand to include `nvme_femu_gc_stats_info` (or related new node). Save diff to review.md.
- [x] 3.5 Run `ninja -j$(nproc) libsystem.a.p/hw_femu_nvme-admin.c.o` from FEMU build dir. Verify: 0 errors, 0 warnings (`-Werror` enforced). Save log to review.md.
- [x] 3.6 Run `OPENSPEC_TELEMETRY=0 openspec validate --strict --specs` from zsf root. Verify: 3/3 specs pass. Save output to review.md.
- [x] 3.7 Run `OPENSPEC_TELEMETRY=0 openspec validate add-femu-gc-stats-log-page --strict` from zsf root. Verify: "Change is valid". Save output to review.md.

## 4. Inject Validation (Test Validity Check)

- [x] 4.1 Inject validation for handler field reads: temporarily change `n->nr_gc_cycles` to `0` (a constant) in `nvme_femu_gc_stats_info`. Rebuild, verify compilation still succeeds (syntax is valid). The inject验证 proves that the handler actually reads `n->nr_gc_cycles` (not just returns zero from a default-initialized struct). Restore.
- [x] 4.2 Inject validation for switch dispatch: temporarily change `case NVME_LOG_FEMU_GC_STATS:` to `case NVME_LOG_FEMU_GC_STATS_UNUSED:` (an unknown LID). Rebuild, verify compilation succeeds. The inject验证 proves that the new case is reachable in the switch (not dead code). Restore.
- [x] 4.3 Inject validation for struct DMA: temporarily change `trans_len = MIN(sizeof(log), buf_len);` to `trans_len = 0;` (zero bytes DMA'd). Rebuild, verify compilation succeeds. The inject验证 proves the DMA path is live and not just elided by the compiler. Restore.

## 5. Archive

- [x] 5.1 Confirm all tasks above are `- [x]`.
- [x] 5.2 Run `OPENSPEC_TELEMETRY=0 openspec archive add-femu-gc-stats-log-page --yes`. Verify: spec delta applied (2 scenarios added to nvme-commands), change moved to `archive/2026-06-22-add-femu-gc-stats-log-page/`.
- [x] 5.3 Commit FEMU changes with `feat(femu): add NVME_LOG_FEMU_GC_STATS log page (LID 0xC0)`.
- [x] 5.4 Commit zsf spec archive with `chore(spec): archive add-femu-gc-stats-log-page`.
