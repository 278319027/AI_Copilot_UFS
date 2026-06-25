## ADDED Requirements

### Requirement: FTL→BE NAND Request Submission Interface
The system SHALL provide a defined interface for the FTL layer to submit NAND read, write, and erase requests to the BE (Back-End) execution layer. The interface SHALL be defined as a structure of function pointers (`FtlBeInterface_t`).

#### Scenario: FTL submits NAND read via interface
- **WHEN** FTL calls `ftl_be_interface->submit_nand_read(ctx, req)` with a valid `BeNandReadReq_t`
- **THEN** the BE SHALL execute the NAND page read operation via the FCL scheduler and notify completion via callback

#### Scenario: FTL submits NAND write via interface
- **WHEN** FTL calls `ftl_be_interface->submit_nand_write(ctx, req)` with a valid `BeNandWriteReq_t`
- **THEN** the BE SHALL execute the NAND page program operation and notify completion via callback

#### Scenario: FTL submits NAND erase via interface
- **WHEN** FTL calls `ftl_be_interface->submit_nand_erase(ctx, req)` with a valid `BeNandEraseReq_t`
- **THEN** the BE SHALL execute the NAND block erase operation and notify completion via callback

### Requirement: BeNandReq_t Structure
The BE NAND request SHALL use a unified request structure `BeNandReq_t` containing:
- `FAA_t faa`: the NAND physical address (FAA format, converted from PAA at the BE entry point)
- `NandOpCode_e op_code`: read / write / erase
- `void* data_buf`: data buffer (for read/write)
- `void* meta_buf`: metadata buffer (OOB data, for read/write)
- `void (*callback)(void* ctx, int status)`: completion callback
- `void* ctx`: FTL context pointer

#### Scenario: BE receives a NAND read request
- **WHEN** BE receives a `BeNandReq_t` with `op_code = NAND_OP_READ`
- **THEN** it SHALL read `faa` from NAND into `data_buf` and `meta_buf`, then invoke callback with status

### Requirement: PAA→FAA Translation at BE Boundary
The PAA (Physical Address Array, used by FTL) to FAA (Flash Address Array, used by BE) translation SHALL be performed at the BE entry point, not scattered across modules.

#### Scenario: FTL submits request in PAA, BE converts to FAA
- **WHEN** FTL submits a NAND request using PAA
- **THEN** the BE SHALL translate the PAA to FAA using the `paa_to_faa()` function at its entry before scheduling

### Requirement: BE→FTL Completion Notification
The BE SHALL notify the FTL of NAND operation completion via the callback function pointer provided in `BeNandReq_t`. The callback SHALL be invoked from the Core1 execution context.

#### Scenario: Successful NAND read completion
- **WHEN** the BE completes a NAND read operation
- **THEN** it SHALL invoke the callback with status 0 (success) and data placed in `data_buf`

#### Scenario: NAND operation failure
- **WHEN** the BE encounters an NAND I/O error (e.g., program fail, erase fail, ECC uncorrectable)
- **THEN** it SHALL invoke the callback with a non-zero error status

### Requirement: NAND Request Priority
The `BeNandReq_t` SHALL include a priority field (`ReqPriority_e` from `nand_req.h`) that the FCL scheduler SHALL use for dispatch ordering.

#### Scenario: High priority read preempts low priority write
- **WHEN** a high-priority NAND read request and a low-priority GC write request are both pending
- **THEN** the FCL scheduler SHALL dispatch the read request before the write request
