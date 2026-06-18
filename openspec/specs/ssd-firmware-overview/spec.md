# SSD Firmware Overview

## Purpose

Define the top-level system architecture, module layering, cross-module contracts, and consumer relationships for the SSD firmware stack. This spec is the authoritative entry point for understanding how the NVMe command layer, FTL mapping layer, NAND driver layer, and error handling layer compose into a complete SSD firmware.

## Non-Goals

This spec does NOT cover:

- Layer-internal implementation details (e.g., specific LBA-to-PBA hash function in FTL, ECC algorithm choice in NAND) — those are owned by the corresponding domain spec
- Hardware-specific controller register definitions, DMA descriptor layouts, or ONFI/Toggle timing — owned by the NAND driver spec and the platform abstraction
- Quantitative performance targets (IOPS, latency budgets, throughput ceilings) — those belong in project requirements documents, not behavioral specs
- AI agent workflows or tooling instructions (CodeGraph/OpenSpec query order, etc.) — those are owned by the skills and memory layers
- Boot sequence, firmware update, or secure download flows — those are separate capabilities to be specified elsewhere

## Requirements

### Requirement: Layered Architecture

The firmware MUST organize code into four canonical layers, with strict downward dependencies and no upward or lateral coupling.

The layering order from top to bottom is:

- NVMe command layer (handles host commands)
- FTL mapping layer (translates LBA to PBA)
- NAND driver layer (issues physical flash operations)
- Error handling layer (cross-cutting concern, used by all layers)

#### Scenario: Dependency from NVMe layer to FTL layer

- **GIVEN** the NVMe command layer receives a read or write command from the host
- **WHEN** the layer processes the command
- **THEN** it MUST call the FTL public interface (`ftl_read`, `ftl_write`, `ftl_trim`) to translate LBA to PBA
- **AND THEN** it MUST NOT directly access the NAND driver public interface

#### Scenario: Dependency from FTL layer to NAND layer

- **GIVEN** the FTL layer has resolved an LBA to a PBA and needs physical I/O
- **WHEN** the FTL layer performs a physical read or write
- **THEN** it MUST call the NAND driver public interface (`nand_read_page`, `nand_write_page`, `nand_erase_block`)
- **AND THEN** it MUST NOT bypass the NAND driver to touch hardware registers directly

#### Scenario: No lateral coupling between NVMe and NAND

- **GIVEN** the NVMe command layer needs physical I/O
- **WHEN** the NVMe layer routes the request
- **THEN** it MUST go through the FTL layer
- **AND THEN** there MUST be no direct include or call from the NVMe command layer to the NAND driver layer

### Requirement: Public Interface Boundaries

Each layer MUST expose a narrow, well-documented public interface. Internal helpers, context structures, and platform-specific code MUST remain private to the layer.

#### Scenario: NVMe public interface

- **GIVEN** external code needs to interact with the NVMe command layer
- **WHEN** a caller submits a Submission Queue entry
- **THEN** it MUST only call the SQ/CQ submission and completion entry points
- **AND THEN** it MUST NOT touch internal Admin or I/O command dispatcher structures directly

#### Scenario: FTL public interface

- **GIVEN** external code needs to interact with the FTL layer
- **WHEN** a caller performs logical I/O
- **THEN** it MUST only call `ftl_read`, `ftl_write`, and `ftl_trim`
- **AND THEN** the mapping table, block pool, and SLC cache structures MUST remain encapsulated inside the layer

#### Scenario: NAND public interface

- **GIVEN** external code needs to interact with the NAND driver layer
- **WHEN** a caller performs physical I/O
- **THEN** it MUST only call `nand_read_page`, `nand_write_page`, and `nand_erase_block`
- **AND THEN** it MUST NOT access the controller registers, DMA descriptors, or ECC engine directly

### Requirement: Baseline Spec Coverage

The four domain specs (NVMe commands, FTL mapping, NAND driver, error handling) MUST collectively cover every public function and every externally observable behavior of the firmware.

#### Scenario: Spec completeness check

- **GIVEN** a new public function is added to any layer
- **WHEN** the change is proposed
- **THEN** the corresponding baseline spec MUST be updated in the same change
- **AND THEN** `openspec validate --strict --specs` MUST pass after the change

#### Scenario: Cross-references between specs

- **GIVEN** a domain spec describes a function whose behavior depends on another layer
- **WHEN** the spec is written or modified
- **THEN** it MUST reference the dependent spec section that defines the contract
- **AND THEN** the dependent spec MUST list the calling layer as an explicit consumer

### Requirement: Layer Consumer Matrix

Each layer MUST declare which other layers are authorized to consume its public interface. The consumer relationship MUST be unidirectional: a consumer calls the layer's public functions, but the layer MUST NOT call back into the consumer.

The consumer matrix is:

| Layer             | Consumers (downstream callers) | May NOT be called by |
|-------------------|--------------------------------|----------------------|
| NVMe command      | (top layer)                    | FTL, NAND, error handling core |
| FTL mapping       | NVMe command                   | NVMe internals, NAND, error handling core |
| NAND driver       | FTL mapping, error handling    | NVMe command |
| Error handling    | All layers (cross-cutting)     | NVMe command, FTL internals |

#### Scenario: Unauthorized consumer is rejected at code review

- **GIVEN** a domain spec lists a set of authorized consumers
- **WHEN** a code change adds a new call from a non-listed layer to the spec's public interface
- **THEN** the change MUST be rejected unless the spec's consumer list is updated in the same change

#### Scenario: Upward call from lower layer is rejected

- **GIVEN** layer L_low is below layer L_high in the layering order
- **WHEN** code in L_low adds a call to any symbol declared in L_high's headers
- **THEN** the call MUST be rejected
- **AND THEN** the build's include-graph check (when present) MUST flag the violation

### Requirement: Cross-Spec Dependency Direction

The four domain specs MUST each declare their upstream consumers in an explicit list, and the overview spec MUST maintain the same matrix in sync. When a domain spec adds or removes a consumer, the overview spec MUST be updated in the same change.

#### Scenario: Adding a consumer to a domain spec

- **GIVEN** a domain spec currently lists consumers {A, B}
- **WHEN** layer C gains a legitimate need to call into the domain spec's public interface
- **THEN** the domain spec MUST be updated to list {A, B, C}
- **AND THEN** the overview spec's layer consumer matrix MUST be updated in the same change

#### Scenario: Removing a consumer

- **GIVEN** a domain spec currently lists consumers {A, B, C}
- **WHEN** layer C is refactored to no longer call into the domain spec
- **THEN** the domain spec MUST drop C from its consumer list
- **AND THEN** the overview spec's layer consumer matrix MUST be updated in the same change
- **AND THEN** no include from layer C to the domain spec's headers MUST remain in the source tree
