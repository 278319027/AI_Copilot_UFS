# FTL Mapping Layer

## Purpose

Define the behavior of the FTL (Flash Translation Layer) mapping module. The FTL translates host LBAs to NAND physical addresses (PBA), maintains the mapping table within DRAM limits, implements wear leveling, garbage collection, SLC cache management, and supports power-loss recovery of the mapping table.

## Consumers

This layer is consumed by:

- **NVMe command layer** — calls `ftl_read`, `ftl_write`, `ftl_trim` to translate host I/O into physical operations

This layer MUST NOT be consumed by the NAND driver layer (the NAND layer is strictly below the FTL layer).


## Requirements

### Requirement: LBA to PBA Translation

The FTL MUST translate every LBA to exactly one current PBA and MUST return a deterministic mapping for the same LBA until the host issues a new write or trim for that LBA.

#### Scenario: First-time read of a written LBA

- **GIVEN** the host previously wrote LBA X to some PBA Y
- **WHEN** the FTL processes `ftl_read(X)`
- **THEN** it MUST return the data previously stored at PBA Y
- **AND THEN** the mapping table entry for LBA X MUST point to PBA Y

#### Scenario: Read of an unwritten LBA

- **GIVEN** LBA X has never been written
- **WHEN** the FTL processes `ftl_read(X)`
- **THEN** it MUST return zeros for the requested sector count
- **AND THEN** it MUST NOT trigger any physical NAND read

#### Scenario: Overwrite invalidates the old mapping

- **GIVEN** LBA X was previously mapped to PBA Y
- **WHEN** the FTL processes `ftl_write(X)` to PBA Z
- **THEN** the mapping table entry for LBA X MUST be updated to PBA Z
- **AND THEN** PBA Y MUST be marked as stale and become eligible for garbage collection

### Requirement: Mapping Table DRAM Constraint

The mapping table MUST fit within the configured DRAM budget. When the budget is approached, the FTL MUST use indirect mapping or compression techniques to remain within the limit.

#### Scenario: Direct mapping within budget

- **GIVEN** the configured direct mapping table size is M entries
- **WHEN** the FTL is initialized
- **THEN** the direct mapping table MUST occupy no more than the configured DRAM budget
- **AND THEN** any LBA within the supported range MUST be reachable in O(1) lookups

#### Scenario: Indirect mapping fallback

- **GIVEN** the total LBA range exceeds the direct mapping table capacity
- **WHEN** the FTL detects capacity pressure
- **THEN** it MUST switch to indirect mapping mode for affected LBA ranges
- **AND THEN** lookups in indirect mode MUST still be correct and complete within the FTL latency budget

### Requirement: Wear Leveling

The FTL MUST track program/erase cycles per block and MUST distribute writes across blocks to prevent premature wear-out. The wear threshold and the cold-data movement policy MUST be configurable.

#### Scenario: Hot data placement

- **GIVEN** the host writes a frequently updated LBA X
- **WHEN** the FTL allocates a new PBA for LBA X
- **THEN** it MUST prefer blocks with the lowest program/erase count in the free pool
- **AND THEN** the new mapping MUST be persisted in the mapping table

#### Scenario: Wear threshold enforcement

- **GIVEN** a block has reached the configured maximum program/erase count
- **WHEN** the FTL selects a destination block for a new write
- **THEN** it MUST NOT select the worn-out block
- **AND THEN** the worn-out block MUST be marked read-only and excluded from the free pool

### Requirement: Garbage Collection

The FTL MUST reclaim blocks whose pages are all stale. GC MUST run in the background with bounded write amplification and MUST be triggerable when free block count falls below a configurable threshold.

#### Scenario: GC trigger on low free blocks

- **GIVEN** the free block count has fallen below the configured threshold
- **WHEN** the FTL completes any I/O operation
- **THEN** it MUST schedule a GC pass
- **AND THEN** the GC pass MUST run asynchronously without blocking the current I/O

#### Scenario: GC victim selection

- **GIVEN** multiple candidate blocks have differing numbers of valid pages
- **WHEN** the FTL selects a GC victim block
- **THEN** it MUST prefer the block with the fewest valid pages to minimize write amplification
- **AND THEN** the chosen block's valid pages MUST be migrated to a new block before the victim is erased

#### Scenario: GC interrupt and resume

- **GIVEN** a GC pass is migrating valid pages
- **WHEN** a power loss occurs
- **THEN** the FTL MUST NOT lose the source-to-destination mapping for any successfully migrated page
- **AND THEN** after recovery, the partially migrated block MUST be in a consistent state

### Requirement: SLC Cache Behavior

The FTL MUST support an SLC cache region for write absorption. Writes MUST preferentially target the SLC region. When the SLC region is full, writes MUST spill to TLC regions at a slower speed.

#### Scenario: SLC cache write

- **GIVEN** the SLC region has free blocks available
- **WHEN** the FTL processes a host write
- **THEN** it MUST allocate the new PBA from the SLC region
- **AND THEN** the host write MUST complete at SLC-class latency

#### Scenario: SLC cache full

- **GIVEN** the SLC region has no free blocks
- **WHEN** the FTL processes a host write
- **THEN** it MUST allocate the new PBA from the TLC region
- **AND THEN** the host write MUST complete at TLC-class latency
- **AND THEN** the FTL MUST schedule SLC-to-TLC folding to free SLC blocks

### Requirement: Trim Support

The FTL MUST process trim (deallocate) commands and MUST mark the affected LBAs as unmapped, releasing their PBAs as stale.

#### Scenario: Trim of an existing mapping

- **GIVEN** LBA X is currently mapped to PBA Y
- **WHEN** the FTL processes `ftl_trim(X, N)`
- **THEN** the mapping entries for LBA X through X+N-1 MUST be cleared
- **AND THEN** PBAs Y and other stale targets MUST be added to the stale page list for GC

### Requirement: Power-Loss Recovery

The FTL MUST persist the mapping table and MUST be able to recover to a consistent state after an unclean shutdown.

#### Scenario: Mapping table checkpoint

- **GIVEN** the FTL is in steady state
- **WHEN** the configured checkpoint interval elapses or a flush command is issued
- **THEN** the FTL MUST write the current mapping table snapshot to NAND
- **AND THEN** the snapshot MUST be tagged with a monotonic sequence number

#### Scenario: Recovery on boot

- **GIVEN** a power loss occurred during previous operation
- **WHEN** the FTL initializes at boot
- **THEN** it MUST locate the latest valid mapping table snapshot
- **AND THEN** it MUST replay any committed-but-uncheckpointed transactions from the write journal
- **AND THEN** the recovered state MUST equal the state as of the last successfully completed command

### Requirement: Write Amplification Bound

The FTL MUST bound steady-state write amplification (WA) so that the ratio of total physical NAND writes to host-requested writes does not exceed the configured upper limit. Write amplification is defined as `WA = (host_writes + gc_writes + wear_leveling_moves) / host_writes`. The bound MUST hold in steady state under the configured representative workload; transient WA during recovery is exempt for the first 60 seconds after boot.

The default steady-state WA bounds are:

| Workload pattern            | Maximum WA (default) |
|-----------------------------|----------------------|
| Sequential 128 KiB writes   | 1.1                  |
| Random 4 KiB writes         | 4.0                  |
| Mixed 70% read / 30% write  | 3.0                  |

The bounds are compile-time configurable; the configured values MUST be reported via the runtime health interface so that the test harness can assert against them.

#### Scenario: Sequential write stays near unity

- **GIVEN** the host issues 100 GiB of sequential 128 KiB writes
- **WHEN** the steady-state phase is reached (after at least 10 GiB of writes)
- **THEN** the measured WA MUST be less than or equal to the configured sequential bound
- **AND THEN** the FTL MUST log a warning if the bound is exceeded

#### Scenario: Random 4 KiB write bound is enforced

- **GIVEN** the host issues 100 GiB of random 4 KiB writes
- **WHEN** the steady-state phase is reached
- **THEN** the measured WA MUST be less than or equal to the configured random bound
- **AND THEN** if the bound is exceeded, the FTL MUST reduce GC aggressiveness (increase the free-block threshold) until the bound is met

#### Scenario: WA is exposed to the runtime health interface

- **GIVEN** the FTL is in any operating state
- **WHEN** the runtime health interface is queried
- **THEN** the current WA estimate (last 60 s window) MUST be available
- **AND THEN** the configured WA bounds MUST be available for comparison

#### Scenario: Wear-leveling moves count toward WA

- **GIVEN** the FTL moves a cold block to a younger block to balance wear
- **WHEN** the move completes
- **THEN** the move's physical writes MUST be counted in the WA numerator
- **AND THEN** the WA estimate MUST reflect wear-leveling cost, not just GC cost

### Requirement: Dependency Direction


The FTL layer MUST depend only on the NAND driver public interface and the platform abstraction layer. It MUST NOT depend on the NVMe command layer.

#### Scenario: No NVMe include in FTL layer

- **GIVEN** the FTL layer is being modified
- **WHEN** an AI agent inspects the include graph
- **THEN** there MUST be no `#include` of any NVMe command layer header from the FTL layer
- **AND THEN** FTL functions MUST NOT take NVMe completion queue structures as parameters

### Requirement: GC Threshold Configuration via QOM Properties

The FTL MUST support configuring the garbage collection trigger thresholds via QEMU QOM properties at device instantiation time. The configuration MUST apply to BBSSD mode only and MUST NOT affect other SSD modes.

#### Scenario: Default thresholds preserve backward compatibility

- **GIVEN** the QEMU command line does not specify `gc-thres-lines` or `gc-thres-lines-high`
- **WHEN** the FEMU device is instantiated
- **THEN** the GC thresholds MUST default to 20% and 10% of total lines respectively
- **AND THEN** the GC behavior MUST be identical to the pre-change implementation

#### Scenario: Custom thresholds via command line

- **GIVEN** the QEMU command line includes `-device femu,gc-thres-lines=50,gc-thres-lines-high=30`
- **WHEN** the FEMU device initializes the BBSSD FTL layer
- **THEN** `ssd_init_params()` MUST read the configured values from `FemuCtrl`
- **AND THEN** `should_gc()` MUST use 50 as the normal threshold
- **AND THEN** `should_gc_high()` MUST use 30 as the high-priority threshold

#### Scenario: Threshold validation clamps out-of-range values

- **GIVEN** the QEMU command line includes `-device femu,gc-thres-lines=0`
- **WHEN** the FEMU device initializes the BBSSD FTL layer
- **THEN** `ssd_init_params()` MUST clamp the value to a minimum of 1 line
- **AND THEN** it MUST emit a warning log message indicating the clamp action

#### Scenario: High threshold must not exceed normal threshold

- **GIVEN** the QEMU command line includes `-device femu,gc-thres-lines=20,gc-thres-lines-high=25`
- **WHEN** the FEMU device initializes the BBSSD FTL layer
- **THEN** `ssd_init_params()` MUST detect the invalid configuration
- **AND THEN** it MUST automatically reduce `gc_thres_lines_high` to 19
- **AND THEN** it MUST emit a warning log message



### Requirement: Contiguous Range Cache (CRT) Insertion on Host Write

The bbssd FTL MUST maintain a Contiguous Range Table (CRT) in DRAM that caches recently-written contiguous LPN ranges, and MUST insert a new CRT entry when a host write creates a contiguous LPN segment whose length meets or exceeds the configured threshold `crt_threshold_lpns` (default 8 LPNs). Each CRT entry stores the start LPN, start PPA, and number of LPNs. Before inserting, the FTL MUST invalidate any existing CRT entries that overlap the new write range.

#### Scenario: Large contiguous write creates one CRT entry

- **GIVEN** a host write of 128 contiguous LBAs (16 LPNs) at slba=1024 with secs_per_pg=8
- **AND THEN** `crt_threshold_lpns` is 8
- **WHEN** the FTL completes `ssd_write` for that request
- **THEN** exactly one CRT entry MUST be inserted with `start_lpn=128, n_lpns=16`
- **AND THEN** the entry's `start_ppa` MUST equal the PPA assigned to LPN 128 by the WP increment sequence

#### Scenario: Small write below threshold is not cached

- **GIVEN** a host write of 32 LBAs (4 LPNs) at slba=2048
- **AND THEN** `crt_threshold_lpns` is 8
- **WHEN** the FTL completes `ssd_write` for that request
- **THEN** the FTL MUST NOT insert any CRT entry
- **AND THEN** the FTL MUST invalidate any existing CRT entries whose range overlaps `[LPN 256, LPN 260)`

#### Scenario: New write invalidates overlapping existing entries

- **GIVEN** an existing CRT entry covers `start_lpn=100, n_lpns=20` (LPN 100..119)
- **WHEN** a new host write covers LPN 110..130
- **THEN** the FTL MUST remove the existing entry during the new write
- **AND THEN** the new write MUST insert a fresh CRT entry (if its length meets the threshold)

#### Scenario: FDP write path also inserts CRT entry

- **GIVEN** FDP is enabled (`ssd->fdp_enabled == true`)
- **AND THEN** a host write of 64 LBAs (8 LPNs) targets the FDP write path
- **WHEN** `nvme_do_write_fdp` completes
- **THEN** the FTL MUST insert a CRT entry for the written LPN range
- **AND THEN** the entry's `start_ppa` MUST equal the PPA from `fdp_get_new_page` for the first LPN

### Requirement: Contiguous Range Cache (CRT) Lookup on Host Read

The bbssd FTL MUST consult the CRT before consulting the page-level mapping table on a host read. When the LPN being translated falls within a valid CRT entry, the FTL MUST compute the target PPA by replaying the write-pointer increment sequence on the entry's start PPA `offset` times, where `offset = lpn - start_lpn`. When the LPN misses in the CRT, the FTL MUST fall through to `get_maptbl_ent` without observable behavior change.

#### Scenario: Read hits CRT entry, skips maptbl

- **GIVEN** an existing CRT entry covers `start_lpn=100, n_lpns=20` with `start_ppa=P0`
- **WHEN** the FTL processes a host read of LPN 105
- **THEN** the FTL MUST compute the target PPA by advancing the WP sequence from `P0` 5 times
- **AND THEN** the FTL MUST NOT call `get_maptbl_ent` for LPN 105 (CRT hit is the sole source)
- **AND THEN** the hit counter MUST increment by 1

#### Scenario: Read misses CRT, falls through to maptbl

- **GIVEN** no CRT entry covers LPN 500
- **WHEN** the FTL processes a host read of LPN 500
- **THEN** the FTL MUST call `get_maptbl_ent` for LPN 500
- **AND THEN** the returned PPA MUST equal the value stored in `maptbl[500]`
- **AND THEN** the miss counter MUST increment by 1

#### Scenario: Replay of WP sequence produces identical PPA to in-line allocation

- **GIVEN** a single host write inserts a CRT entry covering LPNs `[S, S+N)`
- **WHEN** the FTL replays the WP increment from `start_ppa` `offset` times for any `offset ∈ [0, N)`
- **THEN** the resulting PPA MUST equal the PPA that the original write loop assigned to LPN `S + offset`

### Requirement: Contiguous Range Cache (CRT) Invalidation on Garbage Collection and Trim

The bbssd FTL MUST invalidate CRT entries that overlap any LPN whose mapping changes. Specifically, after every call to `set_maptbl_ent` triggered by `gc_write_page`, `gc_write_page_fdp_style`, `ssd_trim` (per LPN within each trim range), or `ssd_trim_fdp_style` (entire table), the FTL MUST remove every CRT entry whose `[start_lpn, start_lpn + n_lpns)` range contains the changed LPN.

#### Scenario: GC relocation invalidates overlapping CRT entry

- **GIVEN** an existing CRT entry covers LPNs `[200, 220)`
- **WHEN** `gc_write_page` relocates LPN 210 to a new PPA
- **THEN** the FTL MUST remove the CRT entry covering LPNs `[200, 220)` after the maptbl update
- **AND THEN** a subsequent read of LPN 215 MUST hit the maptbl (CRT miss) and return the new PPA

#### Scenario: Trim range removes all overlapping CRT entries

- **GIVEN** two CRT entries exist: `[100, 120)` and `[150, 170)`
- **WHEN** a DSM trim command covers LPNs 110..160
- **THEN** both entries MUST be removed
- **AND THEN** the invalidate counter MUST increment by 2

#### Scenario: FDP trim wipe clears entire CRT

- **GIVEN** the CRT contains 50 entries
- **WHEN** the FTL processes an FDP-style DSM trim (full reset path)
- **THEN** the FTL MUST clear the CRT entirely (`crt_clear`)
- **AND THEN** the CRT MUST contain 0 entries

### Requirement: Contiguous Range Cache (CRT) Capacity and Eviction

The CRT MUST be bounded by a configured capacity `crt_capacity` (default 1024 entries). When the CRT is full and a new entry is to be inserted, the FTL MUST evict the oldest entry (FIFO order by insertion time) and MUST increment the `evict` counter. The FTL MUST emit a warning log message when an eviction occurs, with rate limited to once per 1024 evictions to avoid log spam.

#### Scenario: Insert into non-full CRT succeeds without eviction

- **GIVEN** the CRT has 100 entries and capacity is 1024
- **WHEN** a new write inserts one entry
- **THEN** the CRT MUST contain 101 entries
- **AND THEN** the `evict` counter MUST NOT increment

#### Scenario: Insert into full CRT evicts oldest entry

- **GIVEN** the CRT has 1024 entries and capacity is 1024
- **AND THEN** the oldest entry covers LPNs `[10, 20)`
- **WHEN** a new write inserts one entry
- **THEN** the CRT MUST still contain 1024 entries
- **AND THEN** the entry covering `[10, 20)` MUST be removed
- **AND THEN** the new entry MUST be present
- **AND THEN** the `evict` counter MUST increment by 1

### Requirement: Contiguous Range Cache (CRT) Runtime Control and Observability

The bbssd FTL MUST allow operators to disable CRT entirely via a runtime configuration `enable_crt` (default `true`). When disabled, every read MUST use `get_maptbl_ent` and no CRT entry MUST be inserted. The FTL MUST expose CRT statistics (hit, miss, insert, invalidate, evict counts) via a FEMU admin flip command. The FTL MUST also allow resetting those counters via a separate admin command.

#### Scenario: Disabled CRT bypasses cache entirely

- **GIVEN** `enable_crt` is `false`
- **AND THEN** a host write of 128 contiguous LBAs occurs
- **WHEN** a subsequent host read targets the same LPN range
- **THEN** the FTL MUST call `get_maptbl_ent` for each LPN
- **AND THEN** the CRT MUST contain 0 entries
- **AND THEN** the miss counter MUST increment but the hit counter MUST NOT

#### Scenario: Admin flip prints current CRT statistics

- **GIVEN** CRT has accumulated 1000 hits, 200 misses, 50 inserts, 10 invalidates, 3 evicts
- **WHEN** operator issues the `FEMU_PRINT_CRT_STATS` admin flip command
- **THEN** the FTL MUST log the current values of all five counters
- **AND THEN** the CRT entries and counters MUST be unchanged

#### Scenario: Admin flip resets CRT counters

- **GIVEN** CRT counters hold non-zero values
- **WHEN** operator issues the `FEMU_RESET_CRT_STATS` admin flip command
- **THEN** all five counters MUST be set to 0
- **AND THEN** the CRT entries MUST be preserved (reset is counter-only)



### Requirement: Version Reporting Admin Flip

The bbssd FTL MUST provide a `FEMU_LOG_VERSION` admin flip command that, when issued, prints a one-line version banner including the FEMU BB mode identifier and the current state of the CRT (Compressed Range Table) feature. The output MUST be emitted via `femu_log` so it is captured in the standard FEMU log.

#### Scenario: Operator queries version with CRT enabled

- **GIVEN** FEMU BB mode is running with `enable_crt = true`
- **WHEN** the operator issues the `FEMU_LOG_VERSION` admin flip
- **THEN** the FTL MUST log a line containing the substring "FEMU BB" and "CRT=on"
- **AND THEN** the flip MUST return `NVME_SUCCESS`

#### Scenario: Operator queries version with CRT disabled

- **GIVEN** FEMU BB mode is running with `enable_crt = false`
- **WHEN** the operator issues the `FEMU_LOG_VERSION` admin flip
- **THEN** the FTL MUST log a line containing the substring "FEMU BB" and "CRT=off"
- **AND THEN** the flip MUST return `NVME_SUCCESS`

### Requirement: BB Configuration Reporting Flip
The system SHALL provide an admin flip `FEMU_PRINT_BB_CONFIG` that prints a single line containing the current state of all BB mode feature flags. The output MUST be emitted via the existing `femu_log` helper and MUST list, in a fixed order, the following four flags: `enable_gc_delay`, `print_log`, `enable_crt`, and the delay-emulation state (derived as `pg_rd_lat != 0`). Each flag MUST be rendered as `name=on` or `name=off`.

#### Scenario: Operator queries config with all flags at default
- **WHEN** operator issues the `FEMU_PRINT_BB_CONFIG` flip and no prior enable flips have been issued
- **THEN** system prints a single line of the form `FEMU BB config: gc_delay=off, log=off, crt=off, delay_emu=off`

#### Scenario: Operator queries config after enabling GC delay
- **WHEN** operator issues `FEMU_ENABLE_GC_DELAY` followed by `FEMU_PRINT_BB_CONFIG`
- **THEN** system prints a single line with `gc_delay=on` and the other three flags reflecting their current state

#### Scenario: Operator queries config after enabling delay emulation
- **WHEN** operator issues `FEMU_ENABLE_DELAY_EMU` followed by `FEMU_PRINT_BB_CONFIG`
- **THEN** system prints a single line with `delay_emu=on` (derived from `pg_rd_lat != 0`) and the other three flags reflecting their current state

#### Scenario: Flip id not recognized
- **WHEN** operator issues any flip with a `cdw10` value that is not a defined `FEMU_*` enum value
- **THEN** system falls through to the existing default branch (per `add-print-version-flip` precedent) and prints the existing not-implemented message
### Requirement: Sync Script E2E Test
The system SHALL provide a manual sync fallback script (per AP-009 retro 2026-06-add-bb-config-print) that smart-merges delta spec files into baseline when the OpenSpec CLI sync subcommand is unavailable.

#### Scenario: Operator runs sync with an ADDED delta
- **WHEN** operator runs `bash scripts/sync_change.sh <change-id>` and the change contains a delta file with `## ADDED Requirements`
- **THEN** system merges the new Requirements into `openspec/specs/<cap>/spec.md` and strips the delta header

#### Scenario: Operator runs sync with no delta files
- **WHEN** operator runs `bash scripts/sync_change.sh <change-id>` and the change has no `specs/` directory
- **THEN** system exits 0 with an info message and no baseline mutation
### Requirement: BB Flip Dispatch Architecture
The system SHALL implement the `bb_flip` admin flip dispatch as a **table-driven pattern**: a `static const` array of `{cmd, handler, name}` entries indexed by `cdw10`, with a linear `for` loop over the array to find the matching handler. Each FEMU_* enum value MUST be mapped to a static handler function via the table (not via `switch`/`case`).

This requirement documents the implementation architecture chosen in the `refactor-bb-flip-table` change (2026-06-23) and applies to **future implementations**: any new admin flip MUST be added to the table, not as a new `case` block in `bb_flip`. This requirement does NOT change the observable behavior of any existing flip — all 11 admin flip commands (FEMU_ENABLE_GC_DELAY through FEMU_PRINT_BB_CONFIG) MUST produce identical `femu_log` output and identical side effects as the prior switch-based implementation.

#### Scenario: All 11 existing admin flips remain behavior-identical after refactor
- **WHEN** operator issues any of FEMU_ENABLE_GC_DELAY, FEMU_DISABLE_GC_DELAY, FEMU_ENABLE_DELAY_EMU, FEMU_DISABLE_DELAY_EMU, FEMU_RESET_ACCT, FEMU_ENABLE_LOG, FEMU_DISABLE_LOG, FEMU_RESET_CRT_STATS, FEMU_PRINT_CRT_STATS, FEMU_LOG_VERSION, or FEMU_PRINT_BB_CONFIG
- **THEN** system produces the same `femu_log` string and same state changes as documented in their respective requirements
- **AND THEN** the dispatch mechanism SHALL be the `bb_flip_table[]` array (verified via `nm`: `bb_flip_table` is `static const`; `bb_flip` calls handler via function pointer from the table)

#### Scenario: Unknown flip id falls through to default case
- **WHEN** operator issues a flip with a `cdw10` value that is not a defined `FEMU_*` enum value
- **THEN** system prints `"FEMU:%s,Not implemented flip cmd (%lu)\n"` (same default behavior as the prior switch implementation)

#### Scenario: New admin flip added in a future change
- **WHEN** a future change introduces a new FEMU_* admin flip
- **THEN** the new flip MUST be added to `bb_flip_table[]` (not as a new `case` in `bb_flip`)
- **AND THEN** a corresponding ADDED Requirement SHALL be added to this spec documenting the new flip's behavior
### Requirement: BB Print Num IO Flip
The system SHALL provide an admin flip `FEMU_PRINT_NUM_IO` that prints the current value of `nr_tt_ios` and `nr_tt_late_ios` to `femu_log` **without resetting** them. The output MUST be emitted via the existing `femu_log` helper in the same format as `FEMU_RESET_ACCT` (per "Reset tt_late_ios/tt_ios,%lu/%lu" pattern), with the leading "Reset" replaced by "Num" (i.e., `"%s,Num tt_late_ios/tt_ios,%lu/%lu\n"`). The system MUST NOT modify `nr_tt_ios` or `nr_tt_late_ios` as a side effect of this flip.

#### Scenario: Operator queries ACCT counters at default (no IOs yet)
- **WHEN** operator issues `FEMU_PRINT_NUM_IO` flip and no IOs have been issued
- **THEN** system prints `"<devname>,Num tt_late_ios/tt_ios,0/0\n"` and `nr_tt_ios` and `nr_tt_late_ios` remain 0

#### Scenario: Operator queries ACCT counters after some IOs
- **WHEN** operator issues `N` IOs (some early, some late) and then issues `FEMU_PRINT_NUM_IO` flip
- **THEN** system prints `"<devname>,Num tt_late_ios/tt_ios,<late_count>/<N>\n"` with non-zero counts and `nr_tt_ios` and `nr_tt_late_ios` remain unchanged after the query

#### Scenario: Operator queries after FEMU_RESET_ACCT (counters should be 0)
- **WHEN** operator issues `FEMU_RESET_ACCT` followed by `FEMU_PRINT_NUM_IO`
- **THEN** system prints `"<devname>,Num tt_late_ios/tt_ios,0/0\n"` (the new flip does NOT reset; it only reads current values which are now 0)

#### Scenario: Flip id not recognized (default case)
- **WHEN** operator issues any flip with a `cdw10` value that is not a defined `FEMU_*` enum value
- **THEN** system falls through to the existing default branch (per `add-print-version-flip` / `refactor-bb-flip-table` precedent) and prints the existing not-implemented message
### Requirement: BB Toggle GC Delay Flip
The system SHALL provide an admin flip `FEMU_TOGGLE_GC_DELAY` that **atomically toggles** the `enable_gc_delay` field: each invocation inverts the current value (`true` becomes `false`, `false` becomes `true`). The output MUST be emitted via the existing `femu_log` helper in the format `"<devname>,FEMU GC Delay Emulation [<Enabled|Disabled>]!\n"` (same prefix as `FEMU_ENABLE_GC_DELAY` / `FEMU_DISABLE_GC_DELAY`, with `Enabled` or `Disabled` reflecting the **new** state after toggle).

This flip is independent of and complementary to the existing `FEMU_ENABLE_GC_DELAY` / `FEMU_DISABLE_GC_DELAY` pair: all three flips operate on the same `ssd->sp.enable_gc_delay` field, and any combination is valid (e.g., ENABLE then TOGGLE then DISABLE).

#### Scenario: Operator toggles from default (off) to on
- **WHEN** operator issues `FEMU_TOGGLE_GC_DELAY` flip and `enable_gc_delay` is currently `false` (default)
- **THEN** system sets `enable_gc_delay = true` and prints `"<devname>,FEMU GC Delay Emulation [Enabled]!\n"`

#### Scenario: Operator toggles from on to off
- **WHEN** operator issues `FEMU_TOGGLE_GC_DELAY` flip and `enable_gc_delay` is currently `true` (e.g., after `FEMU_ENABLE_GC_DELAY`)
- **THEN** system sets `enable_gc_delay = false` and prints `"<devname>,FEMU GC Delay Emulation [Disabled]!\n"`

#### Scenario: Operator toggles twice (idempotent cycle: off→on→off)
- **WHEN** operator issues `FEMU_TOGGLE_GC_DELAY` twice in a row
- **THEN** system prints `"[Enabled]!"` followed by `"[Disabled]!"`, and `enable_gc_delay` returns to its original value

#### Scenario: Flip id not recognized (default case)
- **WHEN** operator issues any flip with a `cdw10` value that is not a defined `FEMU_*` enum value
- **THEN** system falls through to the existing default branch (per `add-print-version-flip` / `refactor-bb-flip-table` / `add-print-num-io` precedent) and prints the existing not-implemented message
### Requirement: CRT Insert Architecture — Helper Extraction

The system SHALL implement the slot-allocation and eviction sub-logic of `crt_insert()` in `bbssd/crt.c` as **two named file-local helpers**, decoupled from the main insert path. The two helpers are:

1. `static uint32_t crt_find_empty_slot(const struct crt *crt, uint32_t h)` — performs a linear probe from `h` modulo `cap`, returning the first slot index where `entries[slot].valid == false`, or `(uint32_t)-1` if all slots are valid.
2. `static uint32_t crt_evict_oldest(struct crt *crt)` — finds the entry with the smallest `insert_seq`, increments `crt->stat_evict`, and (when `crt->stat_evict % crt->evict_warn_modulo == 0`) emits the `[FEMU] CRT: eviction #N (capacity=K full)` warning to stderr. Returns the chosen slot index.

`crt_insert()` SHALL call both helpers and SHALL NOT contain the slot-probe loop or the eviction-scan loop inline. The helpers SHALL be declared as forward declarations near the top of `crt.c` (after the existing `crt_hash` declaration) and defined below the helpers' first call site.

This requirement documents the implementation architecture chosen in the `refactor-crt-insert-helpers` change (2026-06-23) and applies to **future implementations**: any new insert-path sub-logic (e.g., weighted eviction, LRU-K, or hint-aware eviction) MUST be added as a helper function rather than re-inlined into `crt_insert()`.

#### Scenario: Behavior identical after refactor

- **GIVEN** a CRT with `capacity = N` and `evict_warn_modulo = 1024`
- **WHEN** `crt_insert()` is called with the same `start_lpn` / `start_ppa` / `n_lpns` sequence as before the refactor
- **THEN** the same slot index SHALL be chosen for each call
- **AND THEN** `crt->stat_evict` SHALL be incremented by the same count
- **AND THEN** the same `[FEMU] CRT: eviction #N (capacity=K full)` warning messages SHALL be emitted to stderr at the same `stat_evict` milestones
- **AND THEN** `crt->stat_insert` SHALL be incremented by the same count

#### Scenario: Empty-slot probe matches prior linear-scan behavior

- **GIVEN** a CRT with at least one empty slot
- **WHEN** `crt_find_empty_slot(crt, h)` is called
- **THEN** it SHALL return the smallest `i` in `[0, cap)` such that `entries[(h + i) % cap].valid == false`
- **AND THEN** when no slot is empty, it SHALL return `(uint32_t)-1`

#### Scenario: Oldest-entry eviction matches prior scan behavior

- **GIVEN** a CRT where all slots are valid
- **WHEN** `crt_evict_oldest(crt)` is called
- **THEN** it SHALL return the index of the entry with the smallest `insert_seq` (ties broken by lowest index)
- **AND THEN** `crt->stat_evict` SHALL be incremented by exactly 1
- **AND THEN** if the new `crt->stat_evict` is a multiple of `crt->evict_warn_modulo`, it SHALL emit exactly one `[FEMU] CRT: eviction #N (capacity=K full)` line to stderr

#### Scenario: Future eviction-policy changes use the helper pattern

- **WHEN** a future change introduces a new eviction strategy (e.g., LRU, hint-aware, segment-aware)
- **THEN** the new strategy SHALL be implemented as a helper function in `crt.c` (e.g., `crt_evict_lru()`)
- **AND THEN** `crt_insert()` SHALL call the new helper instead of inlining the eviction logic
