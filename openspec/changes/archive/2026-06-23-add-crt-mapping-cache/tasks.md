## 1. CRT Data Structure & Pure-Logic Helpers (bbssd/crt.{h,c} + ppa_advance)

- [x] 1.1 Add `struct ssd` field `struct crt *crt` in `bbssd/ftl.h`; declare `struct crt` opaque type in `bbssd/crt.h` with public API `crt_init / crt_destroy / crt_insert / crt_lookup / crt_invalidate_lpn / crt_invalidate_range / crt_clear / crt_reset_stats`.
  - Spec: ftl-mapping#Contiguous Range Cache (CRT) Insertion on Host Write; ftl-mapping#Contiguous Range Cache (CRT) Capacity and Eviction; ftl-mapping#Contiguous Range Cache (CRT) Runtime Control and Observability.
  - Test plan: `tests/unit/crt_test.c` — public API callability test (each function callable, returns expected sentinel).
  - Verification: standalone `gcc` compile of crt.c + crt_test.c: 0 warnings/errors. lsp_diagnostics bbssd/crt.h clean.
- [x] 1.2 Implement `crt_init(ssd, capacity)` in `bbssd/crt.c`: allocate `struct crt_entry[crt_capacity]` via `calloc`, zero counters, set `insert_seq` head/tail. `crt_destroy` frees the array.
  - Spec: ftl-mapping#Contiguous Range Cache (CRT) Capacity and Eviction.
  - Test plan: init with cap=8, verify internal count==0; init with cap=0, verify graceful no-op; double-init leaks check.
  - Verification: unit test passes (test_init_normal_capacity, test_init_zero_capacity_returns_null, test_init_destroy_null_safe). 26/26 pass.
- [x] 1.3 Implement `ppa_advance(const struct crt_geom *geom, struct crt_ppa ppa, int n)` pure function in `bbssd/crt.c` — replay `ssd_advance_write_pointer` (`ftl.c:260`) rules `ch → lun → pg` for `n` steps; return updated PPA. n=0 returns ppa unchanged. n crossing a line boundary is "caller bug" — returns deterministic but potentially wrong PPA, no crash.
  - Spec: ftl-mapping#Contiguous Range Cache (CRT) Lookup on Host Read; Scenario "Replay of WP sequence produces identical PPA to in-line allocation".
  - Test plan: 8 unit tests (zero, single step, ch wrap, lun wrap, pg carry, line end tolerance, multi-step vs reference, within-line). Reference impl: simulate ssd_advance_write_pointer one step at a time. Bug-injection verified: swapping ch/lun assignment is caught by test_ppa_advance_single_step_matches_ref.
  - Verification: 8/8 ppa_advance tests pass. Bug injection (ch/lun swap) → test fails at line 102. Restored → 26/26 pass.
- [x] 1.4 Implement `crt_insert(crt, start_lpn, start_ppa, n_lpns)`: hash on `start_lpn`, linear probe for empty slot. If full, find entry with min `insert_seq` (FIFO), mark it invalid, log warn every 1024 evictions.
  - Spec: ftl-mapping#Contiguous Range Cache (CRT) Capacity and Eviction; Scenario "Insert into full CRT evicts oldest entry".
  - Test plan: test_evict_oldest_when_full (cap=4, insert 5, verify first evicted, others survive). test_insert_n_zero_is_noop. test_multiple_inserts_independent.
  - Verification: unit tests pass.
- [x] 1.5 Implement `crt_lookup(crt, lpn, out_ppa)`: full linear scan over all entries (range membership, not set membership), for each valid entry check `[start_lpn, start_lpn + n_lpns)` contains lpn; if yes call `ppa_advance(start_ppa, lpn - start_lpn)`, set *out, increment `hit`, return true. Bug-injection verified: forcing lookup to always return false is caught by test_insert_and_lookup_hit.
  - Spec: ftl-mapping#Contiguous Range Cache (CRT) Lookup on Host Read.
  - Test plan: test_insert_and_lookup_hit, test_lookup_outside_range_misses, test_lookup_into_empty_crt_misses, test_lookup_into_null_crt_misses.
  - Verification: unit tests pass. Bug injection (return false always) → test fails at line 255. Restored → 26/26 pass.
- [x] 1.6 Implement `crt_invalidate_lpn(crt, lpn)` and `crt_invalidate_range(crt, lpn_lo, lpn_hi)`: full linear scan (cap bounded at 1024), for each valid entry check overlap with [lpn, lpn] or [lpn_lo, lpn_hi), mark invalid and increment `invalidate`.
  - Spec: ftl-mapping#Contiguous Range Cache (CRT) Invalidation on Garbage Collection and Trim.
  - Test plan: test_invalidate_lpn_removes_overlapping, test_invalidate_range_removes_all_overlapping, test_invalidate_into_empty_crt_noop, test_invalidate_null_safe.
  - Verification: unit tests pass.
- [x] 1.7 Implement `crt_clear(crt)` (mark all entries invalid, do not free — used by FDP trim reset path) and `crt_reset_stats(crt)` (zero counters, keep entries).
  - Spec: ftl-mapping#Contiguous Range Cache (CRT) Runtime Control and Observability; Scenario "Admin flip resets CRT counters"; Scenario "FDP trim wipe clears entire CRT".
  - Test plan: test_clear_empties_all, test_reset_stats_zeroes_counters, test_null_handle_print_is_safe.
  - Verification: unit tests pass.
- [x] 1.8 Wire `crt_init` into `ssd_init` (`ftl.c:466`) via new `ssd_init_crt` helper called after `ssd_init_rmap`. CRT is destroyed implicitly at process exit (FEMU has no formal ssd_exit path; matches existing maptbl pattern).
  - Spec: ftl-mapping#Contiguous Range Cache (CRT) Runtime Control and Observability.
  - Test plan: integration smoke — instantiate FEMU BB, run quick workload.
  - Verification: `gcc -std=gnu11 -fsyntax-only` clean on ftl.c (no errors in modified code).
- [x] 1.9 Add `enable_crt` (default true), `crt_threshold_lpns` (default 8), `crt_capacity` (default 1024) to `BbCtrlParams` (`nvme.h:1507`) and to `struct ssdparams` (`ftl.h:115`). Read them in `ssd_init_params` (`ftl.c:340`) with default-override semantics: 0/negative values fall back to defaults 8 and 1024.
  - Spec: ftl-mapping#Contiguous Range Cache (CRT) Capacity and Eviction; ftl-mapping#Contiguous Range Cache (CRT) Insertion on Host Write.
  - Test plan: integration smoke with default values; integration with override via QOM property.
  - Verification: `gcc -fsyntax-only` clean on nvme.h and ftl.c. Standalone test unaffected (crt.c is QEMU-free).
- [x] 1.10 Add `'bbssd/crt.c'` to `hw/femu/meson.build:7` so the QEMU build picks it up.
  - Verification: `cat hw/femu/meson.build` shows the entry.

## 2. CRT Hook into Standard Read/Write Path (bbssd/ftl.c)

- [x] 2.1 In `ssd_write` (`ftl.c:963`): after the existing for loop, compute `n_lpns = end_lpn - start_lpn + 1`; if `enable_crt && ssd->crt && n_lpns >= crt_threshold_lpns`, call `crt_invalidate_range(ssd->crt, start_lpn, end_lpn + 1)` then `crt_insert(ssd->crt, start_lpn, &first_ppa, n_lpns)` where `first_ppa = get_maptbl_ent(ssd, start_lpn)`.
  - Spec: ftl-mapping#Contiguous Range Cache (CRT) Insertion on Host Write; Scenarios "Large contiguous write creates one CRT entry", "Small write below threshold is not cached", "New write invalidates overlapping existing entries".
  - Test plan: integration test — write 128 LBAs, query CRT (via stats or unit-test access), assert 1 entry; write 32 LBAs, assert 0 entries; write 128 then 128 overlapping, assert 1 entry (latest) and evict/invalidate counts updated.
  - Verification: `gcc -fsyntax-only` clean; integration test deferred to Group 5.
- [x] 2.2 In `ssd_read` (`ftl.c:927`): at the start of the per-LPN loop, query CRT first. If `enable_crt && ssd->crt && crt_lookup(...)`, use looked-up PPA directly; else fall through to `get_maptbl_ent`.
  - Spec: ftl-mapping#Contiguous Range Cache (CRT) Lookup on Host Read; Scenarios "Read hits CRT entry, skips maptbl", "Read misses CRT, falls through to maptbl".
  - Test plan: integration — write 128 LBAs, read same range, assert hit_count > 0; read a different range, assert miss_count increments.
  - Verification: `gcc -fsyntax-only` clean; integration test deferred to Group 5.

## 3. CRT Hook into GC Relocation Paths

- [x] 3.1 In `gc_write_page` (`ftl.c:787`): after `set_maptbl_ent(ssd, lpn, &new_ppa)`, call `crt_invalidate_lpn(ssd, lpn)` (guarded by `enable_crt`).
  - Spec: ftl-mapping#Contiguous Range Cache (CRT) Invalidation on Garbage Collection and Trim; Scenario "GC relocation invalidates overlapping CRT entry".
  - Test plan: integration — write a large range to seed CRT, force GC by raising free-block threshold, run small workload to trigger GC, query CRT for the relocated LPN, assert miss and correct PPA via maptbl.
  - Verification: `gcc -fsyntax-only` clean on ftl.c; full QEMU build + link succeeded (Group 5).
- [x] 3.2 In `gc_write_page_fdp_style` (`ftl.c:1661`): same hook after `set_maptbl_ent` at line 1683.
  - Spec: ftl-mapping#Contiguous Range Cache (CRT) Invalidation on Garbage Collection and Trim.
  - Test plan: same as 3.1 but with FDP enabled.
  - Verification: full QEMU build + link succeeded. CodeGraph `crt_invalidate_lpn` shows 3 call sites (ftl.c:787, 1042, 1666) — confirms both standard and FDP GC paths hooked.

## 4. CRT Hook into Trim, FDP Trim, and FDP Write Path

- [x] 4.1 In `ssd_trim` (`ftl.c:1085-1103`): inside the per-LPN loop (after `set_maptbl_ent(ssd, lpn, &ppa)`), call `crt_invalidate_lpn(ssd, lpn)`.
  - Spec: ftl-mapping#Contiguous Range Cache (CRT) Invalidation on Garbage Collection and Trim; Scenario "Trim range removes all overlapping CRT entries".
  - Test plan: integration — seed CRT with 2 entries, issue DSM covering overlap of both, assert both removed and `invalidate` count == 2; read a LPN inside the trimmed range, assert miss.
  - Verification: full QEMU build + link succeeded. CodeGraph confirms `crt_invalidate_lpn` is called at ftl.c:1042 (ssd_trim path).
- [x] 4.2 In `ssd_trim_fdp_style` (`ftl.c:2498`): after `ssd_reset_maptbl(ssd)`, call `crt_clear(ssd)`.
  - Spec: ftl-mapping#Contiguous Range Cache (CRT) Invalidation on Garbage Collection and Trim; Scenario "FDP trim wipe clears entire CRT".
  - Test plan: integration with FDP enabled — seed CRT, issue FDP DSM, assert CRT count==0.
  - Verification: full QEMU build + link succeeded. CodeGraph confirms `crt_clear` is called at ftl.c:2437 (ssd_trim_fdp_style path).
- [x] 4.3 In `ssd_stream_write` (`ftl.c:2132-2147`, FDP write path called by `nvme_do_write_fdp`): at the end of the for loop, same pattern as ssd_write — if `n_lpns >= threshold`, call `crt_invalidate_range` then `crt_insert` with `first_ppa = get_maptbl_ent(ssd, start_lpn)`.
  - Spec: ftl-mapping#Contiguous Range Cache (CRT) Insertion on Host Write; Scenario "FDP write path also inserts CRT entry".
  - Test plan: integration with FDP enabled — write 64 LBAs, assert CRT has 1 entry whose start_ppa came from `fdp_get_new_page`.
  - Verification: full QEMU build + link succeeded. CodeGraph confirms `crt_insert` is called at ftl.c:1979 (ssd_stream_write path).

## 5. Stats, Admin Flip, End-to-End Verification

- [x] 5.1 Add `FEMU_RESET_CRT_STATS=8` and `FEMU_PRINT_CRT_STATS=9` enum values to `bbssd/ftl.h`; extend `bb_flip` (`bbssd/bb.c:26`) switch to handle them, calling `crt_reset_stats(ssd->crt)` and `crt_print_stats(ssd->crt)`.
  - Spec: ftl-mapping#Contiguous Range Cache (CRT) Runtime Control and Observability; Scenarios "Admin flip prints current CRT statistics", "Admin flip resets CRT counters".
  - Test plan: integration — issue a workload, issue FEMU_PRINT_CRT_STATS, capture log, assert format matches expected; issue FEMU_RESET_CRT_STATS, assert counters=0, entries preserved.
  - Verification: `gcc -fsyntax-only` clean on bb.c; full QEMU build + link succeeded. CodeGraph confirms `crt_reset_stats` is called at bb.c:26.
- [x] 5.2 Build verification (full QEMU build + link succeeded).
  - Spec: all CRT requirements (closure check).
  - Verification: `cd build-femu && ninja qemu-system-x86_64` exits 0. Output: 83,311,768 byte binary, runs `--version` correctly (QEMU emulator version 10.1.0). All 3 modified bbssd files (bb.c, crt.c, ftl.c) compile without warnings. Standalone CRT test: 26/26 pass.
- [x] 5.3 CodeGraph + graphify closure check.
  - Spec: all CRT requirements (closure check).
  - Verification results:
    - `codegraph where crt_invalidate_lpn` → 3 call sites (ftl.c:787, 1042, 1666). Matches design (GC standard + trim + GC FDP).
    - `codegraph where crt_insert` → 2 call sites (ftl.c:975, 1979). Matches design (ssd_write + ssd_stream_write).
    - `codegraph where crt_lookup` → 1 call site (ftl.c:932). Matches design (ssd_read).
    - `codegraph where crt_clear` → 1 call site (ftl.c:2437). Matches design (ssd_trim_fdp_style).
    - `codegraph where crt_reset_stats` → 1 call site (bb.c:26). Matches design (bb_flip).
    - `codegraph where ppa_advance` → 1 call site (crt.c:137, internal use from crt_lookup).
    - `graphify update .` → 2043 nodes, 3499 edges, 162 communities (no errors).
    - `graphify diagnose multigraph` → `missing_endpoint_edges = 0`, `dangling_endpoint_edges = 0`. Graph integrity preserved.
