## ADDED Requirements

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

## MODIFIED Requirements

### Requirement: Garbage Collection

The FTL MUST reclaim blocks whose pages are all stale. GC MUST run in the background with bounded write amplification and MUST be triggerable when free block count falls below a configurable threshold.

#### Scenario: GC trigger on low free blocks

- **GIVEN** the free block count has fallen below the configured threshold
- **WHEN** the FTL completes any I/O operation
- **THEN** it MUST schedule a GC pass
- **AND THEN** the GC pass MUST run asynchronously without blocking the current I/O
