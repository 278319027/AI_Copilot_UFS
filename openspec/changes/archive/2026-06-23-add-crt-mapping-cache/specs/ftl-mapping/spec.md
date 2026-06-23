## ADDED Requirements

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
