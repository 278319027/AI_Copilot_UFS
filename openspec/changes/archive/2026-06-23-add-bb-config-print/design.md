## Context

Per `add-bb-config-print/proposal.md`: add a `FEMU_PRINT_BB_CONFIG = 11` admin flip to FEMU BB mode. The flip prints all current BB feature flags in a single line via `femu_log`, so operators can verify the running configuration without reading source or attaching a debugger. The change is a 1-case addition to `bb_flip` switch in `bbssd/bb.c` plus a 1-line enum append in `bbssd/ftl.h`.

KNOW phase identified 4 available flag fields:
- `ssd->sp.enable_gc_delay` (bool, default false)
- `ssd->sp.enable_crt` (bool, default false)
- `n->print_log` (bool, default false)
- `ssd->sp.pg_rd_lat` (uint32_t, default 0; non-zero ⇒ delay emulation enabled)

Prior drill `add-print-version-flip` (2026-06-23, archived) established the pattern for one-off status-query flips in the same file; this change is its natural follow-up (extending one-line status reporting from 1 flag to 4).

## Goals / Non-Goals

**Goals:**
- Add `FEMU_PRINT_BB_CONFIG = 11` enum value to `bbssd/ftl.h`.
- Add 1 case to `bb_flip` switch in `bbssd/bb.c` printing all 4 flags on a single line.
- Spec delta: 1 ADDED Requirement in `openspec/specs/ftl-mapping/spec.md`.

**Non-Goals:** (per proposal)

## Decisions

### D1. Enum value placement

- **Choice**: append `FEMU_PRINT_BB_CONFIG = 11` after `FEMU_LOG_VERSION = 10` in `bbssd/ftl.h`.
- **Rationale**: sequential numbering matches existing pattern; no need to renumber.
- **Alternative considered**: starting a new group at 100 — rejected, breaks "max value = N" check in future drills.

### D2. Output format

- **Choice**: single line with all 4 flags in fixed order, comma-separated, lowercase booleans:
  ```
  FEMU BB config: gc_delay=off, log=off, crt=off, delay_emu=off
  ```
- **Rationale**: matches `FEMU_LOG_VERSION` format style (one line, `femu_log`); grep-friendly; fixed order avoids per-call output variation.
- **Alternative considered**: JSON output — rejected, overkill for a status query, harder to grep in a tail of `femu_log` lines.

### D3. How to derive `delay_emu` from a non-bool field

- **Choice**: `delay_emu = (ssd->sp.pg_rd_lat != 0)`.
- **Rationale**: `pg_rd_lat` is set to `NAND_READ_LATENCY` in `FEMU_ENABLE_DELAY_EMU` and to 0 in `FEMU_DISABLE_DELAY_EMU` (bb.c:41-51). It's the canonical "is delay emulation on?" proxy; no separate flag exists.
- **Alternative considered**: introducing a new `enable_delay_emu` bool — rejected, duplicates state, risks drift.

### D4. No new memory rules / test framework

- **Choice**: no automated test; manual verification at QEMU CLI.
- **Rationale**: matches `add-print-version-flip` design D3 precedent. The flip is a 5-line `printf`; the "test" is "operator runs the flip and sees the expected string". The 1 new enum value is the only "public surface"; per M-2 100% coverage rule, satisfied with rationale "no logic to test".

## Risks / Trade-offs

- **R1: enum value collision** → Mitigation: max existing value = 10 (`FEMU_LOG_VERSION`); 11 is safe.
- **R2: format string typos** → Mitigation: visual review during compile; format string is `%s`/decimal/strings only.
- **R3: operator confusion if some flags are unset (all defaults = off)** → Mitigation: format string always shows all 4 flags, not just enabled ones (operator sees the full state).

## design-implementation drift

None expected. If implementation diverges from this design (e.g., adds a 5th flag, changes format), update this section per `memory/design_rules.md` §8 before commit (per M-6).

## Migration Plan

No migration. The flip is additive; existing behavior unchanged.

## Verification commands (per M-1)

```bash
# 1. tasks.md 勾选
grep -c '^- \[x\]' openspec/changes/add-bb-config-print/tasks.md

# 2. compile
cd $FEMU_ROOT && make -j$(nproc) 2>&1 | grep -E "error:|bbssd/bb.c"

# 3. test (no automated test for trivial change; per design D4)
N/A — manual QEMU CLI verification:
  qemu-system-x86_64 ... -device femu,... &
  # trigger flip via admin cmd (cdw10=11)
  # verify log line: "FEMU BB config: gc_delay=..., log=..., crt=..., delay_emu=..."

# 4. spec
openspec validate --strict --changes

# 5. CodeGraph 闭包
codegraph where FEMU_PRINT_BB_CONFIG  # not applicable (literal value)
# Manual: bb.c diff confirms enum + switch case present; ftl.h diff confirms new value

# 6. graphify
graphify diagnose multigraph
```
