# FTL Mapping Layer

## Purpose

Define the behavior of the FTL (Flash Translation Layer) mapping module. The FTL translates host LBAs to NAND physical addresses (PBA), maintains the mapping table within DRAM limits, implements wear leveling, garbage collection, SLC cache management, and supports power-loss recovery of the mapping table.

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

### Requirement: Dependency Direction

The FTL layer MUST depend only on the NAND driver public interface and the platform abstraction layer. It MUST NOT depend on the NVMe command layer.

#### Scenario: No NVMe include in FTL layer

- **GIVEN** the FTL layer is being modified
- **WHEN** an AI agent inspects the include graph
- **THEN** there MUST be no `#include` of any NVMe command layer header from the FTL layer
- **AND THEN** FTL functions MUST NOT take NVMe completion queue structures as parameters
