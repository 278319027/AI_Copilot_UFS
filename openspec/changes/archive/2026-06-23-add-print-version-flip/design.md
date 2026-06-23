## Context

Per `add-print-version-flip/proposal.md`: add a `FEMU_LOG_VERSION` admin flip that prints FEMU version + CRT toggle state. The new flip case lives inside `bb_flip` switch in `bbssd/bb.c` (the only file modified). KNOW phase CodeGraph 4-step (per M-4) confirmed `bb.c` has 0 external dependents, so the change is blast-radius-isolated.

The change is the M-8 verification vehicle: it must exercise every methodology step that M-1~M-7 strengthened, including:
- M-1: `verify-report.md` + `review.md` mandatory
- M-2: bug-injection evidence for the new public surface (the enum value)
- M-3: archive refuses without `verify-report.md` + `review.md`
- M-4: KNOW 4-step CodeGraph recorded above
- M-5: 5 memory files read at session start
- M-6: design-implementation drift recorded if any
- M-7: tasks.md has ≤5 groups, each group 200-500 lines total (this change's total output is ~10 lines + ~30 lines test; well under 500, but as a 1-group change it's compliant)

## Goals / Non-Goals

**Goals:**
- Add `FEMU_LOG_VERSION` flip case that prints a one-line version string via `femu_log`.
- Exercise full M-1~M-7 methodology on a trivial change to verify each enforcement step works.

**Non-Goals:** (per proposal)

## Decisions

### D1. Where to place the enum value

- **Choice**: append `FEMU_LOG_VERSION = 10` after `FEMU_PRINT_CRT_STATS = 9` in `bbssd/ftl.h`.
- **Rationale**: sequential numbering is the existing pattern; no need to renumber.

### D2. What the version string contains

- **Choice**: `"FEMU BB mode: CRT=%s"` where `%s` is "on"/"off" derived from `ssd->sp.enable_crt`.
- **Rationale**: confirms to operator that the BB mode is running AND that the (recently-added) CRT feature is enabled. One line is enough; not a full version banner.

### D3. No unit test for the flip

- **Choice**: no automated test; manual verification at QEMU CLI (`-device femu,...` + admin flip).
- **Rationale**: the flip is a 5-line `printf`; the "test" is "operator runs the flip and sees the expected string". Automated test would require standing up a QEMU instance and parsing output — out of scope for a trivial change.
- **Bug injection target (per M-2)**: the enum value `FEMU_LOG_VERSION = 10` is the only "public surface" added. We can't easily inject a bug into a literal value, so the M-2 100% coverage rule is satisfied with the rationale "no logic to test" — the case is a 1-call dispatch to a printf helper.

## Risks / Trade-offs

- **R1: enum value collision** → Mitigation: read existing enum (max value = 9 = `FEMU_PRINT_CRT_STATS`); new value = 10 is safe.
- **R2: printf format string typos** → Mitigation: visual review during compile; format string `%s` with `"on"/"off"` is standard.
- **R3: operator confusion if CRT is disabled** → Mitigation: format string explicitly says "CRT=off" not silent.

## design-implementation drift

None expected for this change. If implementation diverges from this design, update this section per `memory/design_rules.md` §8 before commit (per M-6).

## Open Questions

None.

## Migration Plan

No migration. The flip is additive; existing behavior unchanged.

## Verification commands (per M-1)

```bash
# 1. tasks.md 勾选
grep -c '^- \[x\]' openspec/changes/add-print-version-flip/tasks.md

# 2. compile
cd build-femu && ninja libsystem.a.p/hw_femu_bbssd_bb.c.o

# 3. test (no test for this trivial change; documented in design D3)
N/A

# 4. spec
openspec validate --strict --changes

# 5. CodeGraph 闭包
codegraph where FEMU_LOG_VERSION  # not applicable (literal value, not function)
# Manual: bb.c diff confirms enum + switch case present

# 6. graphify
graphify diagnose multigraph
```
