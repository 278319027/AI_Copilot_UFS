# FTL-BE Interface

## Purpose

Define the contractual interface between the FTL (Flash Translation Layer) core and the BE (Back-End / NAND Execution) layer. This interface governs how the FTL submits NAND read, write, and erase operations to the BE, and how the BE notifies completion. The BE also owns the PAA↔FAA address translation at its entry boundary.

## Consumers

This specification is consumed by:

- **FTL core** — calls the interface to submit NAND operations
- **BE layer** — implements the interface, schedules operations via FCL, and executes through NAND HAL

## Requirements

### Requirement: FTL→BE NAND Request Submission Interface

The system SHALL provide a defined interface for the FTL layer to submit NAND read, write, and erase requests to the BE execution layer. The interface SHALL be defined as a structure of function pointers (`FtlBeInterface_t`).

#### Scenario: FTL submits NAND read via interface

- **WHEN** FTL calls `ftl_be_interface->submit_nand_read(ctx, req)` with a valid `BeNandReq_t`
- **THEN** the BE SHALL execute the NAND page read operation via the FCL scheduler and notify completion via callback

#### Scenario: FTL submits NAND write via interface

- **WHEN** FTL calls `ftl_be_interface->submit_nand_write(ctx, req)` with a valid `BeNandReq_t`
- **THEN** the BE SHALL execute the NAND page program operation and notify completion via callback

#### Scenario: FTL submits NAND erase via interface

- **WHEN** FTL calls `ftl_be_interface->submit_nand_erase(ctx, req)` with a valid `BeNandReq_t`
- **THEN** the BE SHALL execute the NAND block erase operation and notify completion via callback

### Requirement: BeNandReq_t Structure

The BE NAND request SHALL use a unified structure `BeNandReq_t` containing the operation code, NAND physical address (PAA), data/metadata buffers, priority, and completion callback with context.

#### Scenario: BE receives a NAND read request

- **WHEN** BE receives a `BeNandReq_t` with `op_code = NAND_OP_READ`
- **THEN** it SHALL read from NAND into `data_buf` and `meta_buf`, then invoke the callback with status

#### Scenario: Request priority for dispatch ordering

- **WHEN** a high-priority read request and a low-priority GC write request are both pending in the FCL
- **THEN** the FCL scheduler SHALL dispatch the read request before the write request

### Requirement: BE→FTL Completion Notification

The BE SHALL notify the FTL of NAND operation completion via the callback function pointer provided in `BeNandReq_t`.

#### Scenario: Successful NAND read completion

- **WHEN** the BE completes a NAND read operation
- **THEN** it SHALL invoke the callback with status 0 (success) and data placed in `data_buf`

#### Scenario: NAND operation failure

- **WHEN** the BE encounters an NAND I/O error
- **THEN** it SHALL invoke the callback with a non-zero error status
