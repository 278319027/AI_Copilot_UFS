# NVMe Command Processing

## Purpose

Define how the NVMe command layer accepts host commands, parses and routes them, executes them through the FTL layer, and returns completion entries. The layer MUST complete command processing within microsecond-scale latency and MUST correctly handle Admin commands, I/O commands, and error conditions.

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

### Requirement: Dependency Direction

The NVMe command layer MUST depend only on the FTL public interface and the platform abstraction layer for interrupts and DMA. It MUST NOT depend directly on the NAND driver.

#### Scenario: No NAND driver include in NVMe layer

- **GIVEN** the NVMe command layer is being modified
- **WHEN** an AI agent inspects the include graph
- **THEN** there MUST be no `#include` of any NAND driver header from the NVMe layer
- **AND THEN** the only allowed dependency on flash operations MUST go through `ftl_*` calls
