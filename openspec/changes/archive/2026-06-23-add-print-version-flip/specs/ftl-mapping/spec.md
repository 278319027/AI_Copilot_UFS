## ADDED Requirements

### Requirement: Version Reporting Admin Flip

The bbssd FTL MUST provide a `FEMU_LOG_VERSION` admin flip command that, when issued, prints a one-line version banner including the FEMU BB mode identifier and the current state of the CRT (Compressed Range Table) feature. The output MUST be emitted via `femu_log` so it is captured in the standard FEMU log.

#### Scenario: Operator queries version with CRT enabled

- **GIVEN** FEMU BB mode is running with `enable_crt = true`
- **WHEN** the operator issues the `FEMU_LOG_VERSION` admin flip
- **THEN** the FTL MUST log a line containing the substring "FEMU BB" and "CRT=on"
- **AND THEN** the flip MUST return `NVME_SUCCESS`

#### Scenario: Operator queries version with CRT disabled

- **GIVEN** FEMU BB mode is running with `enable_crt = false`
- **WHEN** the operator issues the `FEMU_LOG_VERSION` admin flip
- **THEN** the FTL MUST log a line containing the substring "FEMU BB" and "CRT=off"
- **AND THEN** the flip MUST return `NVME_SUCCESS`
