## ADDED Requirements

### Requirement: Vendor-Specific GC Stats Log Page (LID 0xC0)

The NVMe command layer SHALL support a vendor-specific log page with Log Page Identifier (LID) 0xC0 named `NVME_LOG_FEMU_GC_STATS`. The log page SHALL expose the garbage collection statistics counters accumulated on the `FemuCtrl` struct.

The log page data structure SHALL be `NvmeFemuGcStatsLog`, defined as:

```c
typedef struct NvmeFemuGcStatsLog {
    uint64_t    nr_gc_cycles;
    uint64_t    nr_gc_data_moves;
} NvmeFemuGcStatsLog;
```

Total size: 16 bytes, 8-byte aligned.

#### Scenario: Host reads GC stats after some GC activity

- **GIVEN** the SSD has completed N GC cycles (`nr_gc_cycles = N`) and moved M pages during GC (`nr_gc_data_moves = M`)
- **WHEN** the host issues `NVME_ADM_CMD_GET_LOG_PAGE` with `lid = 0xC0`, `numdl = 3` (16 bytes)
- **THEN** the NVMe layer SHALL fill the `NvmeFemuGcStatsLog` struct with the current `n->nr_gc_cycles` and `n->nr_gc_data_moves` values
- **AND THEN** the NVMe layer SHALL DMA the 16-byte struct to the host's PRP1/PRP2 buffer
- **AND THEN** the command SHALL return `NVME_SUCCESS`

#### Scenario: Host reads GC stats before any GC activity

- **GIVEN** the SSD has not performed any GC since boot (or since the last `FEMU_RESET_GC_STATS`)
- **AND** `nr_gc_cycles = 0` and `nr_gc_data_moves = 0`
- **WHEN** the host issues `NVME_ADM_CMD_GET_LOG_PAGE` with `lid = 0xC0`
- **THEN** the response SHALL contain `nr_gc_cycles = 0` and `nr_gc_data_moves = 0`

#### Scenario: Read after FEMU_RESET_GC_STATS reflects zero

- **GIVEN** the SSD has completed N > 0 GC cycles
- **WHEN** the host issues `NVME_ADM_CMD_FEMU_FLIP` with cdw10 = 8 (FEMU_RESET_GC_STATS)
- **AND THEN** the host issues `NVME_ADM_CMD_GET_LOG_PAGE` with `lid = 0xC0`
- **THEN** the response SHALL contain `nr_gc_cycles = 0` and `nr_gc_data_moves = 0`

#### Scenario: Read with insufficient buffer length

- **GIVEN** the host issues `NVME_ADM_CMD_GET_LOG_PAGE` with `lid = 0xC0`
- **AND** the buffer length (`numdl + 1` × 4) is less than 16 bytes
- **WHEN** the NVMe layer processes the request
- **THEN** the response SHALL be truncated to the supplied buffer length
- **AND THEN** the command SHALL return `NVME_SUCCESS`

#### Scenario: Unknown LID 0xC0 with bbssd mode

- **GIVEN** the controller is in bbssd mode (the only mode FEMU currently supports for SSD emulation)
- **WHEN** the host issues `NVME_ADM_CMD_GET_LOG_PAGE` with `lid = 0xC0`
- **THEN** the dispatch in `nvme_get_log()` SHALL match the `case NVME_LOG_FEMU_GC_STATS:` branch
- **AND THEN** the handler `nvme_femu_gc_stats_info()` SHALL be invoked

## MODIFIED Requirements

None.

## REMOVED Requirements

None.
