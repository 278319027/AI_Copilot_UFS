# NAND Driver Layer

## Purpose

Define the behavior of the NAND driver layer. The driver issues page-level reads, page-level writes, and block-level erases to the underlying flash hardware. It MUST handle ECC encoding and decoding, bad block management, retry logic, and DMA/IRQ coordination while respecting the physical constraints of NAND flash.

## Requirements

### Requirement: Page Read Operation

The NAND driver MUST read a single page (data + spare) from the specified PBA, perform DMA transfer, and verify ECC. The function MUST be synchronous from the caller's perspective.

#### Scenario: Successful page read

- **GIVEN** block B and page P form a valid readable address
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

### Requirement: Dependency Direction

The NAND driver layer MUST depend only on the platform abstraction layer (registers, interrupts, DMA, clocks). It MUST NOT depend on the FTL or NVMe layers.

#### Scenario: No FTL or NVMe include in NAND driver

- **GIVEN** the NAND driver is being modified
- **WHEN** an AI agent inspects the include graph
- **THEN** there MUST be no `#include` of any FTL or NVMe layer header from the NAND driver
- **AND THEN** the driver functions MUST NOT take LBA, mapping table, or NVMe command structures as parameters
