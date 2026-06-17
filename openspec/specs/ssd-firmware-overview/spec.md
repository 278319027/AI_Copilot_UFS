# SSD Firmware Overview

## Purpose

Define the top-level system architecture, module layering, and cross-module contracts for the SSD firmware stack. This spec is the entry point for AI agents and engineers to understand how the NVMe command layer, FTL mapping layer, NAND driver layer, and error handling layer compose into a complete SSD firmware.

## Requirements

### Requirement: Layered Architecture

The firmware MUST organize code into four canonical layers, with strict downward dependencies and no upward or lateral coupling.

The layering order from top to bottom is:
- NVMe command layer (handles host commands)
- FTL mapping layer (translates LBA to PBA)
- NAND driver layer (issues physical flash operations)
- Error handling layer (cross-cutting concern, used by all layers)

#### Scenario: Dependency from NVMe layer to FTL layer

- **WHEN** the NVMe command layer processes a read or write command
- **THEN** it MUST call the FTL public interface (`ftl_read`, `ftl_write`, `ftl_trim`) to translate LBA to PBA
- **AND THEN** it MUST NOT directly access the NAND driver public interface

#### Scenario: Dependency from FTL layer to NAND layer

- **WHEN** the FTL layer performs a physical read or write
- **THEN** it MUST call the NAND driver public interface (`nand_read_page`, `nand_write_page`, `nand_erase_block`)
- **AND THEN** it MUST NOT bypass the NAND driver to touch hardware registers directly

#### Scenario: No lateral coupling between NVMe and NAND

- **WHEN** the NVMe command layer needs physical I/O
- **THEN** it MUST go through the FTL layer
- **AND THEN** there MUST be no direct include or call from the NVMe command layer to the NAND driver layer

### Requirement: Public Interface Boundaries

Each layer MUST expose a narrow, well-documented public interface. Internal helpers, context structures, and platform-specific code MUST remain private to the layer.

#### Scenario: NVMe public interface

- **WHEN** external code interacts with the NVMe command layer
- **THEN** it MUST only call the SQ/CQ submission and completion entry points
- **AND THEN** it MUST NOT touch internal Admin or I/O command dispatcher structures directly

#### Scenario: FTL public interface

- **WHEN** external code interacts with the FTL layer
- **THEN** it MUST only call `ftl_read`, `ftl_write`, and `ftl_trim`
- **AND THEN** the mapping table, block pool, and SLC cache structures MUST remain encapsulated inside the layer

#### Scenario: NAND public interface

- **WHEN** external code interacts with the NAND driver layer
- **THEN** it MUST only call `nand_read_page`, `nand_write_page`, and `nand_erase_block`
- **AND THEN** it MUST NOT access the controller registers, DMA descriptors, or ECC engine directly

### Requirement: Baseline Spec Coverage

The four domain specs (NVMe commands, FTL mapping, NAND driver, error handling) MUST collectively cover every public function and every externally observable behavior of the firmware.

#### Scenario: Spec completeness check

- **WHEN** a new public function is added to any layer
- **THEN** the corresponding baseline spec MUST be updated in the same change
- **AND THEN** `openspec validate --strict --specs` MUST pass

#### Scenario: Cross-references between specs

- **WHEN** the FTL spec describes a function that depends on NAND behavior
- **THEN** it MUST reference the NAND spec section that defines the contract
- **AND THEN** the NAND spec MUST list FTL as a consumer in its dependencies

### Requirement: CodeGraph and OpenSpec Query Order

When understanding a piece of firmware behavior, AI agents MUST follow this fixed query order: baseline spec first, CodeGraph second, source code last.

#### Scenario: Behavior understanding workflow

- **GIVEN** an AI agent needs to understand what a firmware module does
- **WHEN** the agent begins investigation
- **THEN** it MUST first read the relevant baseline spec from `openspec/specs/`
- **AND THEN** it MAY use CodeGraph to verify call relationships for ambiguous behavior
- **AND THEN** it MAY read the source code only if the spec and CodeGraph leave a question unanswered

#### Scenario: CodeGraph as supplement

- **WHEN** the baseline spec already describes the behavior precisely
- **THEN** the AI agent SHOULD NOT re-query CodeGraph for routine understanding
- **AND THEN** CodeGraph MUST only be invoked when validating impact of a proposed change
