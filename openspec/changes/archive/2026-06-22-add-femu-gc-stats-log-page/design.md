## Context

The `implement-flip-reset-gc-stats` change added `nr_gc_cycles` and `nr_gc_data_moves` to `FemuCtrl` plus a FEMU_FLIP admin command (cdw10=8) to reset them. The counters accumulate during `do_gc()` and `do_gc_fdp_style()` execution. **The round-trip is half-complete**: an operator can reset the counters but cannot read them through the standard NVMe admin command interface. This change adds a vendor-specific log page so the host can query the counters via the standard `Get Log Page` admin command (opcode 0x02).

## Goals / Non-Goals

**Goals:**

- Expose `nr_gc_cycles` and `nr_gc_data_moves` via a vendor-specific NVMe log page (LID 0xC0)
- Round-trip the counter feature: increment → accumulate → **query** → reset
- Follow the existing simple log page pattern (e.g., `nvme_fw_log_info`) to minimize code complexity
- Add an ADDED Requirement to `nvme-commands` spec documenting the new log page

**Non-Goals:**

- No new admin command (reuses existing `Get Log Page` opcode 0x02)
- No standard NVMe log page conformance (this is a FEMU vendor extension; using LID 0xC0, well outside standard range 0x01-0x7F and FDP range 0x20-0x23)
- No thread-safe / atomic reads (matches existing `nr_tt_ios` read pattern)
- No FDP-spec-related changes
- No backward-incompatible changes to existing commands or log pages

## Decisions

### Decision 1: LID = 0xC0 (FEMU vendor-specific)

**Rationale**: NVMe standard LIDs 0x01-0x7F are reserved by spec; FDP uses 0x20-0x23. LID 0xC0 (192) sits in the vendor-specific range used by other FEMU custom opcodes (e.g., `NVME_ADM_CMD_FEMU_FLIP = 0xef` admin opcode, `FDP_EVT_* = 0x80-0xFF` event types).

**Alternatives considered**:
- `0x80`: rejected — collides conceptually with `FDP_EVT_MEDIA_REALLOC = 0x80` (different namespace, but confusing)
- `0x04-0x08`: rejected — NVMe reserved region; borrowing violates future spec compliance if NVMe 2.x defines these
- `0xC0` ✅: clean separation, room to grow (0xC0-0xFE = 31 vendor LIDs available)

### Decision 2: Implementation in `nvme_get_log` dispatch (not `ext_ops.get_log`)

**Rationale**: The `nvme_get_log` switch (nvme-admin.c:1219-1243) already handles 10+ log page IDs in a single switch. Adding one more case is minimal change. bbssd's `.get_log` callback is `NULL` (bb.c:117), so moving logic there would require registering the callback and would create two paths to maintain.

**Alternatives considered**:
- `ext_ops.get_log` callback: rejected — bbssd is a module that already plugs into FEMU; the NVMe log page is a NVMe-spec concept, not a bbssd-specific concept. Keeping it in the NVMe layer matches the pattern of other vendor-neutral log pages like `nvme_error_log_info`, `nvme_smart_info`, `nvme_fw_log_info`.
- **Adding to existing dispatch** ✅: consistent with all other log page implementations.

### Decision 3: Struct = 2 × `uint64_t` (16 bytes, naturally aligned)

**Rationale**: Counters are `int64_t` per existing pattern. The struct is 16 bytes, naturally 8-byte aligned on all supported platforms. No padding, no `QEMU_BUILD_BUG_ON` needed (unlike `NvmeFwSlotInfoLog` which is 512 bytes to match NVMe spec).

**Alternatives considered**:
- 2 × `int64_t` (current counters): ✅ matches existing field types, no conversion
- 2 × `uint64_t` (for unsigned counter semantics): rejected — would diverge from existing field types and require explicit cast in the handler
- 1 × struct with 16-byte padding for cache alignment: rejected — over-engineering, 16 bytes is naturally 8-byte aligned

### Decision 4: Single read handler, no offset/length parameters

**Rationale**: The log page is 16 bytes total, smaller than MDTS (Memory Page Transfer Size). The host should always read all 16 bytes. Reject partial reads (offset > 0 or length < 16) as `NVME_INVALID_FIELD` to keep the contract simple. Mirrors the `nvme_fw_log_info` template (no offset handling, just `trans_len = MIN(sizeof, buf_len)`).

**Alternatives considered**:
- Support partial reads with offset: rejected — over-engineering for a 16-byte structure; spec doesn't require it
- Reject any partial read: ✅ simple, defensive

## Risks / Trade-offs

| Risk | Mitigation |
|------|------------|
| Host reads counters mid-GC, sees torn read (rare but possible) | Documented in spec: "values are read non-atomically; minor skew is possible if GC is in progress at the read time." Acceptable for diagnostic use case. |
| LID 0xC0 collides with a future NVMe spec assignment | LID 0xC0 is in vendor-specific range (0xC0-0xFF); extremely low risk. |
| Adding to `nvme_get_log` switch increases complexity (cyclomatic complexity) | New case is 1 line; switch goes from 10 cases to 11. Negligible complexity impact. |
| CodeGraph AST doesn't track field accesses via `ssd->n->...` indirect (known false-positive "dead-leaf" report) | Documented in review.md. Use grep as supplementary verification per `ssd-review-rules.md` §4.2. |

## Migration Plan

No migration needed:
- Additive change (new LID, new struct, new handler)
- No existing log page IDs modified
- No existing admin commands modified
- Backwards compatible: existing FEMU clients ignore LID 0xC0 and receive `NVME_INVALID_LOG_ID` if they happen to query it

## Open Questions

None.

## KNOW-phase evidence (per upgraded methodology)

### Step 3a: Graphify concept discovery

```
$ graphify query "GC stats"
Traversal: BFS depth=2 | Start: ['nvme_fdp_stats()'] | 58 nodes found
KEY DISCOVERY: nvme_get_log() in community 0 (NVMe admin), correct location
```

```
$ graphify explain "nvme_get_log"
Node: nvme_get_log()
  ID:        nvme_admin_nvme_get_log
  Source:    nvme-admin.c L1188
  Type:      code
  Community: 0   ← correct community for new code
  Degree:    14
  Connections: 1 caller (nvme_admin_cmd), 6 callees (fdp handlers, fw_log_info, etc.)
```

### Step 3b: CodeGraph structure analysis

```
$ codegraph where nvme_get_log
f nvme_get_log [utility]  nvme-admin.c:1188
  Used in: nvme-admin.c:1369  ← 1 caller only (nvme_admin_cmd)

$ codegraph context nvme_fw_log_info  (template reference)
  Cognitive: 0 | Cyclomatic: 1 | Max Nesting: 0
  Source: 15 lines, 1 direct dependency (dma_read_prp)
  Callers: nvme_get_log (line 1188)

$ codegraph where "nr_gc_cycles"
. nr_gc_cycles [dead-leaf]  nvme.h:1730
  No uses found  ← FALSE POSITIVE: indirect access via ssd->n-> not tracked
  Verified via grep: 4 use sites in bb.c (lines 69,70,72) and ftl.c (line 887)

$ codegraph impact nvme.h
Level 1: 17 files. New enum + struct additive, no ABI impact.
```

### Graphify 图谱完整性 baseline (pre-change)

```
$ graphify diagnose multigraph
nodes: 2142
missing_endpoint_edges: 0
dangling_endpoint_edges: 0
self_loop_edges: 5   ← pre-existing, unrelated
exact_duplicate_edges: 0
```

## Cross-methodology gates

- **KNOW**: ✅ Step 3a (Graphify) + Step 3b (CodeGraph) both run with evidence above
- **BUILD Gate will load**: `superpowers-verification-before-completion`, `superpowers-executing-plans`, test plan written here
- **FEEDBACK will run**:
  - `graphify diagnose multigraph` (compare against pre-change baseline: missing=0, dangling=0 unchanged)
  - `graphify explain "nvme_femu_gc_stats_info"` (verify community 0 = NVMe admin, matches `nvme_get_log`)
  - `codegraph where nvme_femu_gc_stats_info` (verify 1 caller, `nvme_get_log`)
  - `graphify query "GC stats"` (verify hit set expanded to include new handler)
