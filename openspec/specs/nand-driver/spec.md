# NAND Driver Layer

## Purpose

Define the behavior of the NAND driver layer. The driver issues page-level reads, page-level writes, and block-level erases to the underlying flash hardware. It MUST handle ECC encoding and decoding, bad block management, retry logic, multi-plane operations, and DMA/IRQ coordination while respecting the physical constraints of NAND flash.

## Consumers

This layer is consumed by:

- **FTL mapping layer** — uses `nand_read_page`, `nand_write_page`, `nand_erase_block` for physical I/O
- **Error handling layer** — uses bad block table update and ECC error reporting interfaces

This layer MUST NOT be consumed by the NVMe command layer (the NVMe layer reaches flash only via the FTL layer).

## Geometry Constraints

The driver MUST operate within the following flash geometry boundaries. The exact values are compile-time configurable; the contract below is the structural contract that the FTL and error handling layers rely on.

| Parameter           | Contract                                                          |
|---------------------|-------------------------------------------------------------------|
| Page size (data)    | Power-of-two multiple of 512 bytes, between 4 KiB and 16 KiB     |
| Spare area size     | At least 64 bytes per page, large enough for ECC parity + metadata |
| Pages per block     | Power-of-two between 64 and 512                                   |
| Blocks per plane    | At least 1024                                                     |
| Planes per LUN      | Power-of-two between 1 and 8                                      |
| LUNs per target     | Configurable, at least 1                                          |
| Page program order  | Within-block sequential, no out-of-order page writes              |
| Block erase unit    | Entire block only (no partial block erase)                        |

The page address passed to `nand_read_page(B, P, ...)` and `nand_write_page(B, P, ...)` MUST be expressed in (block, page) coordinates, with `B` ranging over the block space and `P` ranging over the pages within a block.

## Requirements

### Requirement: Page Read Operation

The NAND driver MUST read a single page (data + spare) from the specified PBA, perform DMA transfer, and verify ECC. The function MUST be synchronous from the caller's perspective.

#### Scenario: Successful page read

- **GIVEN** block B and page P form a valid readable address within the geometry
- **WHEN** the caller invokes `nand_read_page(B, P, buffer)`
- **THEN** the driver MUST issue a Read command to the controller with the correct row address
- **AND THEN** it MUST DMA the page data (including spare area) into the caller buffer
- **AND THEN** it MUST run ECC decoding on the transferred data
- **AND THEN** it MUST return success when all bit errors are within the correctable range

#### Scenario: Page read with correctable ECC errors

- **GIVEN** the page read completes but the raw bit error count is within the ECC capability
- **WHEN** ECC decoding finishes
- **THEN** the driver MUST correct the errors transparently
- **AND THEN** it MUST return success
- **AND THEN** it MUST log a warning with the bit error count

#### Scenario: Page read with uncorrectable ECC errors

- **GIVEN** the page read completes but the raw bit error count exceeds the ECC capability
- **WHEN** ECC decoding finishes
- **THEN** the driver MUST return an uncorrectable error code
- **AND THEN** it MUST NOT modify the caller buffer beyond what DMA already transferred
- **AND THEN** it MUST record the page and block for upper-layer recovery

### Requirement: Page Write Operation

The NAND driver MUST program a single page with caller-supplied data, perform ECC encoding, and confirm the program operation completed successfully.

#### Scenario: Successful page write

- **GIVEN** block B and page P are in a state that allows writing (erased, not bad)
- **WHEN** the caller invokes `nand_write_page(B, P, buffer)`
- **THEN** the driver MUST verify the block is not in the bad block table
- **AND THEN** it MUST run ECC encoding over the data
- **AND THEN** it MUST issue a Program command and DMA the data to the controller
- **AND THEN** it MUST poll the controller status register until program completion
- **AND THEN** it MUST return success on confirmed program completion

#### Scenario: Page write to a non-erased page

- **GIVEN** page P of block B is not in the erased state
- **WHEN** the caller invokes `nand_write_page(B, P, buffer)`
- **THEN** the driver MUST return a precondition violation error
- **AND THEN** it MUST NOT issue any Program command to the controller
- **AND THEN** the caller buffer MUST remain unchanged

#### Scenario: Program operation failure

- **GIVEN** the controller reports a program failure status
- **WHEN** the driver polls the status register
- **THEN** it MUST return a program failure error
- **AND THEN** it MUST NOT mark the block as bad automatically; the upper layer decides

### Requirement: Block Erase Operation

The NAND driver MUST erase an entire block. A successful erase MUST set all bytes in the block to 0xFF.

#### Scenario: Successful block erase

- **GIVEN** block B is in the live block table (not bad)
- **WHEN** the caller invokes `nand_erase_block(B)`
- **THEN** the driver MUST issue an Erase command with the correct row address
- **AND THEN** it MUST poll the status register until erase completion
- **AND THEN** it MUST return success on confirmed erase completion

#### Scenario: Block erase failure

- **GIVEN** the controller reports an erase failure status
- **WHEN** the driver polls the status register
- **THEN** it MUST return an erase failure error
- **AND THEN** the upper layer MUST decide whether to mark the block as bad

### Requirement: Multi-Plane Operations

The NAND driver MUST support multi-plane page reads and page writes when the underlying target exposes multiple planes per LUN. A multi-plane operation MUST target the same page offset across all selected planes in a single issued command sequence.

#### Scenario: Multi-plane page write

- **GIVEN** the target exposes N planes per LUN and a multi-plane write is requested
- **WHEN** the caller invokes `nand_write_page_multi(block, page, buffers[N])`
- **THEN** the driver MUST issue a multi-plane Program command sequence addressing the same (block, page) on every selected plane
- **AND THEN** it MUST run ECC encoding on each plane's data independently
- **AND THEN** it MUST return success only when all planes confirm program completion
- **AND THEN** on a partial-plane failure, it MUST report which plane(s) failed

#### Scenario: Single-plane target

- **GIVEN** the target exposes exactly one plane per LUN
- **WHEN** the caller invokes a multi-plane API
- **THEN** the driver MUST behave as a single-plane operation and MUST NOT issue multi-plane command sequences

### Requirement: ECC Encoding and Decoding

The NAND driver MUST use the configured ECC engine (BCH, LDPC, or hardware ECC) for all data transfers. ECC parity MUST be stored in the spare area.

#### Scenario: ECC capability within margin

- **GIVEN** the bit error rate of a page is below the configured threshold
- **WHEN** the driver reads the page
- **THEN** ECC MUST correct all errors and the read MUST succeed

#### Scenario: ECC capability exceeded

- **GIVEN** the bit error rate of a page exceeds the configured threshold
- **WHEN** the driver reads the page
- **THEN** ECC MUST report uncorrectable errors
- **AND THEN** the driver MUST return an uncorrectable error to the caller

### Requirement: Bad Block Management

The NAND driver MUST scan the factory-marked bad blocks at init time and MUST update the bad block table when a block becomes bad at runtime.

#### Scenario: Initial bad block scan

- **GIVEN** the driver initializes for the first time
- **WHEN** the scan phase runs
- **THEN** it MUST read the first page spare area of every block
- **AND THEN** it MUST add any block whose factory bad block marker is non-0xFF to the bad block table
- **AND THEN** it MUST NOT attempt to read or write any block in the bad block table

#### Scenario: Runtime bad block detection

- **GIVEN** a program or erase operation fails consistently after retry
- **WHEN** the upper layer marks the block as bad
- **THEN** the driver MUST add the block to the runtime bad block table
- **AND THEN** it MUST reserve a spare block from the spare block pool and report its address to the caller

#### Scenario: Spare block exhaustion

- **GIVEN** the spare block pool has no remaining blocks
- **WHEN** a runtime bad block is reported
- **THEN** the driver MUST return a no-spare-block error
- **AND THEN** the upper layer MUST trigger a degraded operation mode

### Requirement: DMA and IRQ Coordination

The NAND driver MUST use DMA for all data transfers larger than the configured threshold and MUST coordinate completion via interrupts. Polling MUST be used as a fallback.

#### Scenario: DMA-driven transfer

- **GIVEN** a read or write operation has been initiated
- **WHEN** the controller raises a transfer-complete interrupt
- **THEN** the driver's IRQ handler MUST acknowledge the interrupt
- **AND THEN** it MUST update the relevant request status to complete
- **AND THEN** it MUST wake up or signal the waiting caller

#### Scenario: IRQ loss fallback to polling

- **GIVEN** the configured IRQ timeout has elapsed without an interrupt
- **WHEN** the driver's timeout watchdog fires
- **THEN** the driver MUST switch to polling mode for the current operation
- **AND THEN** it MUST log the IRQ loss event for diagnostics
- **AND THEN** the operation MUST still complete to a success or failure terminal state

### Requirement: ONFI / Toggle Interface Conformance

The NAND driver MUST communicate with the target through a standard NAND interface. The driver implementation MAY support either ONFI (Open NAND Flash Interface) or Toggle (legacy/toggle-mode DDR) targets; the choice is compile-time. The driver MUST detect the interface mode at init and MUST reject targets whose identification response does not match the configured mode.

#### Scenario: ONFI target detected

- **GIVEN** the driver is configured for ONFI mode
- **WHEN** the driver issues the ONFI Read ID command
- **THEN** the target MUST respond with the ONFI signature "ONFI"
- **AND THEN** the driver MUST read ONFI parameter page for geometry and timing

#### Scenario: Toggle target detected

- **GIVEN** the driver is configured for Toggle mode
- **WHEN** the driver issues the Toggle Read ID sequence
- **THEN** the target MUST respond with a Toggle-compatible JEDEC ID
- **AND THEN** the driver MUST NOT issue ONFI-specific commands

#### Scenario: Mismatched target rejected

- **GIVEN** the driver is configured for ONFI mode
- **WHEN** the target responds with a non-ONFI signature
- **THEN** the driver MUST refuse to initialize the target
- **AND THEN** it MUST return a target-detection error to the upper layer

### Requirement: Dependency Direction

The NAND driver layer MUST depend only on the platform abstraction layer (registers, interrupts, DMA, clocks). It MUST NOT depend on the FTL or NVMe layers.

#### Scenario: No FTL or NVMe include in NAND driver

- **GIVEN** the NAND driver is being modified
- **WHEN** an AI agent inspects the include graph
- **THEN** there MUST be no `#include` of any FTL or NVMe layer header from the NAND driver
- **AND THEN** the driver functions MUST NOT take LBA, mapping table, or NVMe command structures as parameters
