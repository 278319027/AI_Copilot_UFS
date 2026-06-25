## ADDED Requirements

### Requirement: PAA (Physical Address Array) Definition
The PAA SHALL be the address type used by the FTL layer to reference NAND physical locations. PAA SHALL be a `U64` value with encoding that is opaque to the FTL.

#### Scenario: FTL uses PAA without decoding
- **WHEN** FTL stores or passes a PAA value
- **THEN** it SHALL treat PAA as an opaque identifier and SHALL NOT decode its bit fields

### Requirement: FAA (Flash Address Array) Definition
The FAA SHALL be the address type used by the BE/NAND layer, encoding the full NAND topology (Channel/CE/Die/Plane/Block/Page/DU) in a packed `U32` bit field.

#### Scenario: FAA bit field layout
- **WHEN** BE decodes an FAA value
- **THEN** it SHALL use the `NandAddr_t` union to access individual fields (du/plane/ch/ce/page/block) as defined in `config.h`

### Requirement: PAA to FAA Translation Function
The system SHALL provide a `paa_to_faa()` function that converts PAA to FAA. This function SHALL be callable from the BE entry point only.

#### Scenario: PAA to FAA conversion at BE boundary
- **WHEN** BE receives a NAND request with PAA
- **THEN** it SHALL call `paa_to_faa(paa)` to obtain the FAA for scheduling and HAL operations
- **AND** the conversion SHALL be deterministic: same PAA always produces same FAA

### Requirement: FAA to PAA Translation Function
The system SHALL provide an `faa_to_paa()` function for translating FAA back to PAA (used when BE needs to communicate physical location info back to FTL).

#### Scenario: FAA to PAA conversion for completion info
- **WHEN** BE reports NAND operation completion
- **THEN** if the response includes a physical address, it SHALL be translated from FAA to PAA before passing to FTL

### Requirement: Translation Responsibility Boundary
The FTL layer SHALL NOT perform PAA↔FAA translation. The BE layer SHALL be the sole owner of address translation logic.

#### Scenario: FTL queries address mapping
- **WHEN** FTL needs to query LAA→PAA mapping
- **THEN** it SHALL use the LUT/RLUT interface and SHALL receive PAA
- **AND** it SHALL NOT call `paa_to_faa()` or reference `NandAddr_t`

#### Scenario: BE schedules a NAND request
- **WHEN** BE schedules a NAND request
- **THEN** it SHALL work with FAA only, using `NandAddr_t` fields for Channel/Die/plane routing
