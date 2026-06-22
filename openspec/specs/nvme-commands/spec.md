# NVMe Command Processing

## Purpose

Define how the NVMe command layer accepts host commands, parses and routes them, executes them through the FTL layer, and returns completion entries. The layer MUST complete command processing within microsecond-scale latency and MUST correctly handle Admin commands, I/O commands, SGL data buffers, namespace management, and error conditions.

## Consumers

This layer is consumed by:

- **Host** (the NVMe initiator) — submits Admin and I/O commands via the Submission Queues

This layer MUST NOT be consumed by the FTL, NAND driver, or error handling core layers.
## Requirements
### Requirement: Command Reception and Routing

The NVMe command layer MUST accept Submission Queue (SQ) entries, identify the command type, and route it to the appropriate handler (Admin or I/O).

#### Scenario: Admin command routing

- **GIVEN** a Create I/O Submission Queue command (opcode 0x01) is placed on the Admin SQ
- **WHEN** the controller doorbell is rung
- **THEN** the NVMe layer MUST identify it as an Admin command
- **AND THEN** it MUST dispatch the command to the Admin command handler
- **AND THEN** it MUST NOT route it to the I/O command dispatcher

#### Scenario: I/O command routing

- **GIVEN** a Read command (opcode 0x02) is placed on an I/O SQ
- **WHEN** the controller doorbell is rung
- **THEN** the NVMe layer MUST identify it as an I/O command
- **AND THEN** it MUST dispatch the command to the I/O command handler
- **AND THEN** it MUST NOT route it to the Admin command dispatcher

### Requirement: Admin Command Processing

The NVMe layer MUST implement the mandatory Admin commands: Identify, Set Features, Get Features, Create I/O CQ, Create I/O SQ, Delete I/O CQ, and Delete I/O SQ.

#### Scenario: Identify command response

- **GIVEN** the host issues an Identify command for the controller
- **WHEN** the NVMe layer processes the command
- **THEN** it MUST populate the Identify Controller data structure at the PRP address
- **AND THEN** it MUST post a successful completion entry with status code 0x0
- **AND THEN** the completion MUST be generated within the command timeout window

#### Scenario: Create I/O Completion Queue

- **GIVEN** the host issues Create I/O CQ with valid PRPs and a non-zero queue size
- **WHEN** the NVMe layer processes the command
- **THEN** it MUST allocate a CQ data structure in DRAM
- **AND THEN** it MUST program the controller CQ registers
- **AND THEN** it MUST return success in the completion entry

#### Scenario: Create I/O CQ with invalid queue size

- **GIVEN** the host issues Create I/O CQ with queue size zero or non-power-of-two
- **WHEN** the NVMe layer processes the command
- **THEN** it MUST return an Invalid Queue Size status (0x9) in the completion entry
- **AND THEN** it MUST NOT allocate any CQ structure

### Requirement: I/O Command Processing

The NVMe layer MUST implement Read (0x02), Write (0x01), Flush (0x00), and Compare (0x05) I/O commands. Each command MUST be translated into the corresponding FTL call and tracked until completion.

#### Scenario: Read command execution

- **GIVEN** the host issues a Read command for N LBAs starting at LBA X
- **WHEN** the NVMe layer processes the command
- **THEN** it MUST extract the start LBA, length, and PRP list
- **AND THEN** it MUST call `ftl_read(X, N, prp_list)`
- **AND THEN** it MUST post a completion entry reflecting the FTL return status

#### Scenario: Write command execution

- **GIVEN** the host issues a Write command for N LBAs starting at LBA X
- **WHEN** the NVMe layer processes the command
- **THEN** it MUST extract the start LBA, length, and PRP list
- **AND THEN** it MUST call `ftl_write(X, N, prp_list)`
- **AND THEN** it MUST post a completion entry reflecting the FTL return status

#### Scenario: Flush command

- **GIVEN** the host issues a Flush command
- **WHEN** the NVMe layer processes the command
- **THEN** it MUST ensure all prior writes have been committed to NAND
- **AND THEN** it MUST post a successful completion only after persistence is confirmed

### Requirement: Completion Queue Delivery

Every command MUST eventually result in a Completion Queue (CQ) entry. The CQ entry MUST contain the correct command ID, status code, and any phase tag bit transition required by the NVMe spec.

#### Scenario: Successful completion

- **GIVEN** a command has been processed successfully
- **WHEN** the NVMe layer posts the completion entry
- **THEN** the entry MUST contain the original command ID
- **AND THEN** the status field MUST be 0x0 (Successful Completion)
- **AND THEN** the phase tag MUST be toggled if required by the queue's current phase

#### Scenario: Error completion

- **GIVEN** a command has failed (FTL or NAND returned an error)
- **WHEN** the NVMe layer posts the completion entry
- **THEN** the entry MUST contain the original command ID
- **AND THEN** the status field MUST be a non-zero NVMe status code reflecting the failure

### Requirement: Command Timeout and Recovery

The NVMe layer MUST enforce command timeouts and MUST transition the controller to a recoverable error state if a command does not complete within the timeout window.

#### Scenario: Command timeout detection

- **GIVEN** an I/O command has not completed within the configured timeout
- **WHEN** the timeout watchdog fires
- **THEN** the NVMe layer MUST abort the command
- **AND THEN** it MUST post a completion with status code 0x4 (Internal Device Error) or 0x6 (Command Aborted)
- **AND THEN** it MUST log the timeout with the command ID and submission timestamp

### Requirement: SGL Data Buffer Support

The NVMe layer MUST support both PRP and SGL data buffer descriptions for all I/O commands. When the command's PSDT field indicates SGL, the layer MUST parse the SGL segment chain, follow last-segment / linked-segment descriptors, and DMA the data from the scatter-gather regions into the FTL-supplied buffer.

#### Scenario: SGL with single data block

- **GIVEN** a Read command is issued with PSDT = SGL and a single SGL data block descriptor
- **WHEN** the NVMe layer processes the command
- **THEN** it MUST locate the SGL segment in the queue page
- **AND THEN** it MUST read the data from the SGL-described physical address into the FTL buffer
- **AND THEN** it MUST honor the byte count from the SGL descriptor

#### Scenario: SGL with linked segments

- **GIVEN** a Write command is issued with PSDT = SGL and a linked-list of SGL segments
- **WHEN** the NVMe layer walks the SGL chain
- **THEN** it MUST follow linked-segment descriptors until the last-segment bit is set
- **AND THEN** it MUST DMA the cumulative data into the FTL buffer
- **AND THEN** it MUST reject the command with status 0x2 (Invalid Field) if the chain contains a cycle (a segment reachable twice) or exceeds the maximum supported segment count

#### Scenario: SGL bit-bucket descriptor

- **GIVEN** a Write command includes an SGL bit-bucket descriptor (zero-fill region)
- **WHEN** the NVMe layer processes the bit-bucket region
- **THEN** it MUST NOT DMA any host data for that region
- **AND THEN** it MUST treat the corresponding FTL buffer range as zero-filled

### Requirement: Namespace Management

The NVMe layer MUST support namespace management Admin commands and MUST maintain a namespace table that maps NSID to FTL logical block range. The mandatory namespace management commands are Identify Namespace, Create Namespace, Delete Namespace, Attach Namespace, and Detach Namespace.

#### Scenario: Create Namespace

- **GIVEN** the host issues Create Namespace with a non-zero namespace size
- **WHEN** the NVMe layer processes the command
- **THEN** it MUST allocate a new NSID
- **AND THEN** it MUST reserve the requested LBA range from the FTL
- **AND THEN** it MUST persist the namespace descriptor to non-volatile storage
- **AND THEN** it MUST return the new NSID in the completion entry

#### Scenario: Delete Namespace

- **GIVEN** the host issues Delete Namespace for an existing NSID
- **WHEN** the NVMe layer processes the command
- **THEN** it MUST release the LBA range back to the FTL free pool
- **AND THEN** it MUST mark the NSID as deleted and unavailable for new commands
- **AND THEN** it MUST return success only after the FTL has confirmed release

#### Scenario: Attach Namespace to controller

- **GIVEN** the host issues Attach Namespace for an existing NSID and a target controller ID
- **WHEN** the NVMe layer processes the command
- **THEN** it MUST add the NSID to the controller's private namespace list
- **AND THEN** commands addressed to that NSID on the attached controller MUST be accepted
- **AND THEN** commands on non-attached controllers MUST be rejected with status 0x2

#### Scenario: Identify Namespace returns current geometry

- **GIVEN** the host issues Identify Namespace for NSID N
- **WHEN** the NVMe layer processes the command
- **THEN** it MUST populate the Identify Namespace data structure with NSID N's current size, capacity, format, and protection information
- **AND THEN** it MUST post a successful completion within the command timeout window

### Requirement: Dependency Direction

The NVMe command layer MUST depend only on the FTL public interface and the platform abstraction layer for interrupts and DMA. It MUST NOT depend directly on the NAND driver.

#### Scenario: No NAND driver include in NVMe layer

- **GIVEN** the NVMe command layer is being modified
- **WHEN** an AI agent inspects the include graph
- **THEN** there MUST be no `#include` of any NAND driver header from the NVMe layer
- **AND THEN** the only allowed dependency on flash operations MUST go through `ftl_*` calls

### Requirement: FEMU FLIP Admin Command Dispatch

The NVMe command layer SHALL support `NVME_ADM_CMD_FEMU_FLIP` (opcode 0xef) to dynamically toggle FEMU runtime behaviors. The command SHALL interpret cdw10 as the FLIP operation selector.

The supported cdw10 operation codes SHALL be:

| cdw10 Value | Operation | Behavior |
|-------------|-----------|----------|
| 1 | FEMU_ENABLE_GC_DELAY | Enable GC delay emulation |
| 2 | FEMU_DISABLE_GC_DELAY | Disable GC delay emulation |
| 3 | FEMU_ENABLE_DELAY_EMU | Enable NAND latency emulation |
| 4 | FEMU_DISABLE_DELAY_EMU | Disable NAND latency emulation |
| 5 | FEMU_RESET_ACCT | Reset IO accounting counters (nr_tt_ios, nr_tt_late_ios) |
| 6 | FEMU_ENABLE_LOG | Enable detailed logging |
| 7 | FEMU_DISABLE_LOG | Disable detailed logging |
| 8 | FEMU_RESET_GC_STATS | Reset GC statistics counters (nr_gc_cycles, nr_gc_data_moves) |

#### Scenario: FEMU_RESET_GC_STATS resets GC counters to zero

- **GIVEN** the SSD has completed N GC cycles and moved M pages during GC
- **AND** `nr_gc_cycles > 0` and `nr_gc_data_moves > 0`
- **WHEN** the host issues `NVME_ADM_CMD_FEMU_FLIP` with cdw10 = 8 (FEMU_RESET_GC_STATS)
- **THEN** `nr_gc_cycles` SHALL be set to 0
- **AND THEN** `nr_gc_data_moves` SHALL be set to 0
- **AND THEN** the command SHALL return `NVME_SUCCESS`

#### Scenario: GC counters increment after each GC cycle

- **GIVEN** the FTL module invokes `do_gc()` or `do_gc_fdp_style()`
- **WHEN** a GC cycle completes successfully (return 0)
- **THEN** `nr_gc_cycles` SHALL be incremented by 1
- **AND THEN** for `do_gc_fdp_style()`, `nr_gc_data_moves` SHALL be incremented by the number of valid pages migrated (`vpc_cnt`)

#### Scenario: Unknown FLIP cdw10 is rejected with log

- **GIVEN** the host issues `NVME_ADM_CMD_FEMU_FLIP` with a cdw10 value not in {1..8}
- **WHEN** `bb_flip()` processes the command
- **THEN** the `default:` branch SHALL execute
- **AND THEN** a diagnostic message SHALL be printed indicating the unimplemented cdw10 value

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

