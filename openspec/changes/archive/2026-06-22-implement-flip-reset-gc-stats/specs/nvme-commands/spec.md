## ADDED Requirements

### Requirement: FEMU_RESET_GC_STATS Implementation Location

The FEMU FLIP operation 8 (`FEMU_RESET_GC_STATS`) SHALL be implemented in the `bb_flip()` function in `bbssd/bb.c` and SHALL zero the `nr_gc_cycles` and `nr_gc_data_moves` fields on the `FemuCtrl` struct defined in `nvme.h`.

#### Scenario: Reset case is wired in bb_flip switch

- **WHEN** the host issues `NVME_ADM_CMD_FEMU_FLIP` with cdw10 = 8
- **THEN** the `case FEMU_RESET_GC_STATS:` branch SHALL execute
- **AND THEN** `n->nr_gc_cycles` SHALL be assigned 0
- **AND THEN** `n->nr_gc_data_moves` SHALL be assigned 0

### Requirement: GC Counter Increment Implementation

The `nr_gc_cycles` counter SHALL be incremented inside `do_gc()` in `bbssd/ftl.c` immediately before the function returns success (return 0). The `nr_gc_data_moves` counter SHALL be incremented inside `do_gc_fdp_style()` in `bbssd/ftl.c` immediately before the function returns success, by the value of `vpc_cnt`.

#### Scenario: do_gc success increments nr_gc_cycles

- **WHEN** `do_gc(ssd, force)` completes successfully (returns 0)
- **THEN** `ssd->n->nr_gc_cycles` SHALL be incremented by exactly 1

#### Scenario: do_gc_fdp_style success increments nr_gc_data_moves by vpc_cnt

- **WHEN** `do_gc_fdp_style(...)` completes successfully (returns 0)
- **THEN** `ssd->n->nr_gc_data_moves` SHALL be incremented by `vpc_cnt` (the number of valid pages migrated)
