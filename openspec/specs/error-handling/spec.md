# Error Handling

## Purpose

Define the cross-cutting error handling behavior for the SSD firmware. This spec covers error propagation, recovery strategies for NAND ECC errors, DMA/IRQ error recovery, command-level error reporting, power-loss recovery, and degraded operation modes. Errors MUST NOT be silently swallowed and critical paths MUST have a defined fallback.

## Consumers

This layer is consumed by:

- **NVMe command layer** — uses error-to-status mapping interfaces
- **FTL mapping layer** — uses bad block update and error code conversion interfaces
- **NAND driver layer** — uses DMA timeout and IRQ loss recovery primitives

The error handling layer is cross-cutting; the precise consumer relationship is owned by each consuming layer's spec (e.g., the NAND driver spec's "Consumers" section). This section is a summary, not the authoritative list.


## Requirements

### Requirement: Error Propagation

Every error detected at any layer MUST be propagated to the upper layer as a structured error code. Errors MUST NOT be silently swallowed or replaced with success.

#### Scenario: NAND error propagates to FTL

- **GIVEN** `nand_read_page` returns an uncorrectable ECC error
- **WHEN** the FTL processes the error
- **THEN** it MUST convert the NAND error code into an FTL error code
- **AND THEN** it MUST return the FTL error code to the NVMe command layer
- **AND THEN** it MUST NOT return success

#### Scenario: FTL error propagates to NVMe

- **GIVEN** `ftl_read` returns an LBA-unmapped or unrecoverable error
- **WHEN** the NVMe command layer processes the error
- **THEN** it MUST convert the FTL error into an NVMe completion status code
- **AND THEN** it MUST post a completion entry with the non-zero status
- **AND THEN** it MUST NOT post a successful completion

### Requirement: NAND ECC Error Recovery

The error handling layer MUST implement a recovery strategy for ECC errors. Correctable errors MUST be fixed transparently. Uncorrectable errors MUST trigger retry, and persistent uncorrectable errors MUST cause the affected block to be retired.

#### Scenario: Correctable ECC error is fixed transparently

- **GIVEN** the NAND driver reports a correctable ECC error
- **WHEN** the error reaches the FTL
- **THEN** the FTL MUST treat the read as successful
- **AND THEN** it MUST increment a weak-page counter for the affected block

#### Scenario: Uncorrectable ECC error triggers retry

- **GIVEN** the NAND driver reports an uncorrectable ECC error on the first read attempt
- **WHEN** the FTL receives the error
- **THEN** it MUST retry the read up to the configured maximum retry count
- **AND THEN** if any retry succeeds, the FTL MUST return success

#### Scenario: Uncorrectable ECC persists after retries

- **GIVEN** the NAND driver reports an uncorrectable ECC error on every retry
- **WHEN** the FTL exhausts the retry budget
- **THEN** it MUST mark the affected block as bad in the bad block table
- **AND THEN** it MUST return an unrecoverable error to the upper layer

#### Scenario: Weak block retirement threshold

- **GIVEN** a block's weak-page counter has reached the configured threshold
- **WHEN** the FTL performs any operation on the block
- **THEN** it MUST copy any remaining valid data to a new block
- **AND THEN** it MUST mark the original block as bad
- **AND THEN** the block's PBA MUST be added to the stale page list for GC

### Requirement: DMA and IRQ Error Recovery

The error handling layer MUST handle DMA timeouts and lost interrupts with a defined retry and polling fallback.

#### Scenario: DMA timeout triggers retry

- **GIVEN** a DMA transfer has not completed within the configured timeout
- **WHEN** the watchdog fires
- **THEN** the driver MUST abort the DMA channel
- **AND THEN** it MUST retry the operation from the controller command issuance step
- **AND THEN** it MUST log the timeout with the channel ID and timestamp

#### Scenario: Interrupt loss triggers polling fallback

- **GIVEN** the expected completion interrupt has not arrived within the configured window
- **WHEN** the IRQ-loss watchdog fires
- **THEN** the driver MUST switch to polling mode for the current operation
- **AND THEN** it MUST log the IRQ loss event
- **AND THEN** the operation MUST still complete to a terminal state

### Requirement: Command-Level Error Reporting

Every error that reaches the NVMe command layer MUST be reported to the host via an appropriate NVMe completion status code.

#### Scenario: Read command returns LBA out of range

- **GIVEN** the host issues a Read command with start LBA beyond the namespace capacity
- **WHEN** the NVMe layer processes the command
- **THEN** it MUST return status code 0x2 (Invalid Field in Command) in the completion entry

#### Scenario: Write command reports internal device error

- **GIVEN** the FTL returns an unrecoverable error for a Write command
- **WHEN** the NVMe layer processes the error
- **THEN** it MUST return status code 0x6 (Internal Device Error) or 0x4 (Data Transfer Error) in the completion entry
- **AND THEN** it MUST log the failure with the command ID and the underlying FTL error code

### Requirement: Power-Loss Recovery

The error handling layer MUST ensure that the firmware can recover to a consistent state after a power loss at any point during operation.

#### Scenario: Mapping table recovery

- **GIVEN** a power loss occurred during a write operation
- **WHEN** the firmware reboots
- **THEN** the FTL MUST locate the latest valid mapping table checkpoint
- **AND THEN** it MUST replay or roll back any in-flight writes based on the journal entries
- **AND THEN** the recovered state MUST be internally consistent

#### Scenario: GC interruption recovery

- **GIVEN** a power loss occurred while GC was migrating valid pages
- **WHEN** the firmware reboots
- **THEN** the FTL MUST detect the partially migrated block
- **AND THEN** it MUST either complete the migration or roll back the affected pages
- **AND THEN** no mapping table entry MUST NOT reference a partially written page

#### Scenario: Spare area integrity check

- **GIVEN** the firmware has just recovered from a power loss
- **WHEN** the recovery sequence runs
- **THEN** the FTL MUST verify the integrity of the recovered mapping table against the spare area checksums
- **AND THEN** if the verification fails, the FTL MUST fall back to the previous checkpoint and report the recovery to the host log

### Requirement: Degraded Operation Mode

When the firmware detects conditions that exceed normal operating margins (e.g., bad block rate exceeds threshold, ECC capability degraded), it MUST enter a degraded operation mode with reduced performance but continued correct behavior.

#### Scenario: High bad block rate triggers degraded mode

- **GIVEN** the bad block rate has exceeded the configured threshold
- **WHEN** the FTL evaluates system health
- **THEN** it MUST switch to degraded operation mode
- **AND THEN** it MUST reduce concurrent GC aggressiveness to limit further wear
- **AND THEN** it MUST continue to accept and process all valid host commands correctly

#### Scenario: Reduced ECC capability

- **GIVEN** the ECC engine reports degraded correction capability
- **WHEN** the NAND driver reads a page
- **THEN** it MUST increase the read retry count
- **AND THEN** it MUST report the degraded state to the FTL
- **AND THEN** the FTL MUST schedule an early refresh of blocks with high bit error counts

### Requirement: No Silent Failure

The error handling layer MUST guarantee that no error condition is ever silently discarded. Every error MUST be either logged, returned to the caller, or both.

#### Scenario: Error logging requirement

- **GIVEN** any non-recoverable error occurs at any layer
- **WHEN** the error is detected
- **THEN** the layer MUST log the error with at least the timestamp, layer, error code, and a contextual message
- **AND THEN** the layer MUST return the error to its caller

#### Scenario: Critical path fallback

- **GIVEN** the firmware is on a critical I/O path (read, write, flush)
- **WHEN** the primary recovery strategy fails
- **THEN** the layer MUST execute a defined fallback (e.g., retry with reduced parameters, mark block bad, switch to degraded mode)
- **AND THEN** it MUST NOT return success without a completed and verified result

### Requirement: Dependency Direction

The error handling layer MUST depend only on the platform abstraction layer and the NAND driver's error reporting interface. It MUST NOT depend on FTL or NVMe command layer structures for its core error detection and recovery primitives.

#### Scenario: No FTL or NVMe include in error handling core

- **GIVEN** the error handling layer is being modified
- **WHEN** an AI agent inspects the include graph
- **THEN** there MUST be no `#include` of any FTL or NVMe layer header from the error handling core modules
- **AND THEN** error handling functions MUST NOT take LBA, mapping table entries, or NVMe command structures as parameters for error detection primitives
