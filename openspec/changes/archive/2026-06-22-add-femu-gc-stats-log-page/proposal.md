## Why

The `implement-flip-reset-gc-stats` change (archived 2026-06-22) added `nr_gc_cycles` and `nr_gc_data_moves` fields to `FemuCtrl` plus the `FEMU_RESET_GC_STATS` admin command (cdw10=8) to zero them. The counters accumulate during GC but currently **no readback path exists** — an operator can only see them in femu_debug logs, and there's no way to query them via the standard NVMe admin command interface. Adding a vendor-specific log page exposes the counters through the standard `Get Log Page` admin command, completing the round-trip: increment → accumulate → query → reset.

## What Changes

- Add `NVME_LOG_FEMU_GC_STATS = 0xC0` enum value to `enum NvmeLogIdentifier` in `nvme.h` (vendor-specific LID, 0xC0 chosen to avoid collision with NVMe standard LIDs 0x01-0x23 and FDP range 0x20-0x23).
- Add `NvmeFemuGcStatsLog` struct in `nvme.h`: 2 × `uint64_t` fields (`nr_gc_cycles`, `nr_gc_data_moves`), 16 bytes total, naturally 8-byte aligned.
- Add `nvme_femu_gc_stats_info()` handler in `nvme-admin.c` that fills the struct from `n->nr_gc_cycles` and `n->nr_gc_data_moves`, mirrors the simple `nvme_fw_log_info()` pattern.
- Add `case NVME_LOG_FEMU_GC_STATS:` to the `nvme_get_log()` switch in `nvme-admin.c`.
- Update existing `nvme-commands` spec to document the new log page via an ADDED Requirement (no new capability).

## Non-goals

- No new admin command (opcode 0x02 `Get Log Page` already exists and is reused).
- No changes to existing log page IDs (0x01-0x23) or behavior.
- No FDP-spec-related changes (this is a FEMU vendor extension, not a T10/ NVMe-standard log page).
- No thread-safe / atomic reads of the counters (consistent with existing `nr_tt_ios` read pattern, no concurrent access).
- No backward-incompatible changes to the existing `FEMU_RESET_GC_STATS` command.

## Capabilities

### New Capabilities

_None._

### Modified Capabilities

- `nvme-commands`: ADDED Requirement describing `NVME_LOG_FEMU_GC_STATS` (LID 0xC0), including its 16-byte struct layout and read semantics. This is a new observable behavior (host can now read counters via standard NVMe Get Log Page), so the spec baseline must reflect it.

## Impact

- **Code touched** (FEMU):
  - `hw/femu/nvme.h` — 1 enum value + 1 struct typedef (~10 lines)
  - `hw/femu/nvme-admin.c` — 1 switch case + 1 handler function (~20 lines)
- **CodeGraph queries needed** (per upgraded methodology):
  - **Step 3a (Graphify concept discovery)**: `graphify query "log page"`, `graphify query "GC stats"` — confirm community归属 and that we're not creating a duplicate node
  - **Step 3b (CodeGraph structure)**: `codegraph where nvme_get_log` (1 caller `nvme_admin_cmd`), `codegraph context nvme_fw_log_info` (template reference), `codegraph where n->nr_gc_cycles` (if any other reads exist)
- **Tests**: Path B (hardware-dependent). Compile-clean is BUILD verification. Inject validation on the handler: comment out the `n->nr_gc_cycles` field read, confirm struct DMA returns zeros (verifying the read path is live, not just zero-init).
- **Build target**: FEMU's QEMU build (Linux x86).
- **Spec delta**: `specs/nvme-commands/spec.md` ADDED Requirement `Vendor-Specific GC Stats Log Page (LID 0xC0)`.

## Superpowers iron rules applying

- **test-coverage**: handler is Path B (hardware-dependent). Verify via compile + inject validation; document untestable runtime path in review.md.
- **systematic-debugging**: N/A (no bug, additive feature).
- **verification-before-completion**: capture `ninja` log and `openspec validate` output as evidence; do not claim "done" without these.

## Cross-methodology gates (per upgraded SKILL.md)

- **KNOW completed**: Step 3a (Graphify) + Step 3b (CodeGraph) both run; concept归属 confirmed (community 0 = NVMe admin, where `nvme_get_log` lives).
- **BUILD Gate will load**: `superpowers-verification-before-completion`, `superpowers-executing-plans`, test plan written to design.md.
- **FEEDBACK will include**: `graphify diagnose multigraph` (图谱完整性) + `graphify explain` on new symbol (社区归属验证).
