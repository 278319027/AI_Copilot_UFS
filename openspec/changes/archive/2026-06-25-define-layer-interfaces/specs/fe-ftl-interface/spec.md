## ADDED Requirements

### Requirement: FE→FTL Request Submission Interface
The system SHALL provide a defined interface for the FE (Front-End) layer to submit read, write, trim, and flush requests to the FTL (Flash Translation Layer) core. The interface SHALL be defined as a structure of function pointers (`FeFtlInterface_t`) rather than direct function calls.

#### Scenario: FE submits read request via interface
- **WHEN** FE calls `fe_ftl_interface->submit_read(ctx, req)` with a valid `FeReadReq_t`
- **THEN** the FTL SHALL process the read asynchronously and invoke the callback specified in `FeReadReq_t` upon completion

#### Scenario: FE submits write request via interface
- **WHEN** FE calls `fe_ftl_interface->submit_write(ctx, req)` with a valid `FeWriteReq_t` containing `data_buf`
- **THEN** the FTL SHALL take ownership of the data buffer for the duration of the operation and invoke the callback upon completion

#### Scenario: FE submits trim request via interface
- **WHEN** FE calls `fe_ftl_interface->submit_trim(ctx, req)` with a valid `FeTrimReq_t`
- **THEN** the FTL SHALL mark the specified LBA range as trimmed and invoke callback upon completion

#### Scenario: FE submits flush request via interface
- **WHEN** FE calls `fe_ftl_interface->submit_flush(ctx, req)` with a valid `FeFlushReq_t`
- **THEN** the FTL SHALL ensure all previously submitted write data is persisted before invoking the callback

### Requirement: FE Request Types
The system SHALL define distinct request types for each FE operation, all inheriting from a common base `FeReqHead_t` containing command type, flags, callback, and context pointer.

#### Scenario: Request type discrimination
- **WHEN** FE submits a read request
- **THEN** the FTL SHALL distinguish it from write/trim/flush requests via the `cmd` field in `FeReqHead_t`

### Requirement: FTL→FE Completion Notification
The FTL SHALL notify the FE of request completion via the callback function pointer provided in the original `FeReq_t`. The callback SHALL include a status code indicating success or failure.

#### Scenario: Successful read completion
- **WHEN** the FTL completes a read request successfully
- **THEN** it SHALL invoke the callback with status `FTL_ERR_OK` and the read data SHALL be in the buffer provided in the original request

#### Scenario: Failed request notification
- **WHEN** the FTL encounters an error processing a request
- **THEN** it SHALL invoke the callback with the appropriate error status code (e.g., `FTL_ERR_FAIL`, `FTL_ERR_TIMEOUT`)

### Requirement: Data Buffer Ownership for FE→FTL Transfers
The FE SHALL allocate the data buffer and the FTL SHALL NOT free it. The FE MAY free the buffer after the completion callback returns.

#### Scenario: Buffer lifetime during write
- **WHEN** FE submits a write request with a `data_buf`
- **THEN** the FTL SHALL read from the buffer during processing, but SHALL NOT modify or free the buffer pointer

#### Scenario: Buffer lifetime during read
- **WHEN** FE submits a read request with a `data_buf`
- **THEN** the FTL SHALL write the read data into the buffer before invoking the callback, and the FE MAY read the buffer after callback returns
