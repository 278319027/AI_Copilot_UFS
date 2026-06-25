# Address Translation

## Purpose

Define the contractual boundary for physical address translation between the FTL layer (which uses PAA — Physical Address Array) and the BE layer (which uses FAA — Flash Address Array). The translation SHALL be owned exclusively by the BE layer; the FTL SHALL treat PAA as an opaque identifier.

## Consumers

This specification is consumed by:

- **BE layer** — calls `paa_to_faa()` and `faa_to_paa()` at the BE entry/exit boundary
- **FTL core** — MUST NOT call address translation functions directly

## Requirements

### Requirement: PAA (Physical Address Array) Definition

PAA SHALL be the address type used by the FTL layer. PAA SHALL be a `U32` value whose internal encoding is opaque to the FTL.

#### Scenario: FTL uses PAA as opaque identifier

- **WHEN** FTL stores or passes a PAA value
- **THEN** it SHALL treat PAA as an opaque identifier and SHALL NOT decode its bit fields

### Requirement: FAA (Flash Address Array) Definition

FAA SHALL be the address type used by the BE layer, encoding the full NAND topology (Channel, CE, Die, Plane, Block, Page, DU) in a packed `U32` bit field as defined in `config.h`.

#### Scenario: BE decodes FAA bit fields

- **WHEN** BE processes an FAA value for scheduling
- **THEN** it SHALL use the `NandAddr_t` union or FAA field extraction macros (`FAA_GET_CHANNEL`, `FAA_GET_PLANE`, etc.) to access individual topology fields

### Requirement: PAA to FAA Translation

The system SHALL provide a `paa_to_faa()` function that converts PAA to FAA, callable from the BE entry point only.

#### Scenario: PAA to FAA conversion at BE boundary

- **WHEN** BE receives a NAND request with PAA
- **THEN** it SHALL call `paa_to_faa(paa)` to obtain the FAA for scheduling and HAL operations
- **AND** the conversion SHALL be deterministic: same PAA always produces same FAA

### Requirement: FAA to PAA Translation

The system SHALL provide an `faa_to_paa()` function for translating FAA back to PAA when the BE needs to communicate physical location information back to the FTL.

#### Scenario: FAA to PAA for completion info

- **WHEN** BE reports NAND operation completion
- **THEN** if the response includes a physical address, it SHALL be translated from FAA to PAA before passing to FTL

### Requirement: Translation Responsibility Boundary

The FTL layer SHALL NOT perform PAA↔FAA translation. The BE layer SHALL be the sole owner of address translation logic.

#### Scenario: FTL uses only PAA for mapping

- **WHEN** FTL queries LAA→PAA mapping from LUT/RLUT
- **THEN** it SHALL receive PAA and SHALL NOT call `paa_to_faa()` or reference `NandAddr_t`

#### Scenario: BE schedules using only FAA

- **WHEN** BE dispatches a NAND request to the FCL scheduler
- **THEN** it SHALL work with FAA only, using `NandAddr_t` fields for Channel/Die/Plane routing
