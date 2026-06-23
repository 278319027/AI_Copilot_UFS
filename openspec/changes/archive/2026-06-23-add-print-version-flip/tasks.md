## 1. Implement Version Reporting Flip

- [x] 1.1 Add `FEMU_LOG_VERSION = 10` to `bbssd/ftl.h` flip enum (after `FEMU_PRINT_CRT_STATS = 9`).
  - Spec: ftl-mapping#Version Reporting Admin Flip.
  - Test plan: visual review; `grep -n FEMU_LOG_VERSION bbssd/ftl.h` confirms presence.
  - Verification: `gcc -fsyntax-only` clean; QEMU build re-link.
- [x] 1.2 Add switch case in `bb_flip` (`bbssd/bb.c:26`): `case FEMU_LOG_VERSION: femu_log("FEMU BB: CRT=%s\n", ssd->sp.enable_crt ? "on" : "off"); break;`
  - Spec: ftl-mapping#Version Reporting Admin Flip; Scenarios "with CRT enabled" + "with CRT disabled".
  - Test plan: manual — issue flip at QEMU CLI, capture log, assert substring match.
  - Verification: `gcc -fsyntax-only` clean; QEMU build re-link.
- [x] 1.3 Compile + re-link QEMU; verify new binary runs (`--version`).
  - Verification: `cd build-femu && ninja qemu-system-x86_64 && ./qemu-system-x86_64 --version`.

## 2. Verify and Archive

- [x] 2.1 Run `/opsx:verify` per M-1 (must produce `verify-report.md`).
  - Verification: 6-check gate all pass; `verify-report.md` exists + "✅ READY" status; `review.md` exists.
- [ ] 2.2 Run `/opsx:archive` per M-3 (must validate review.md + verify-report.md).
  - Verification: archive refuses if either missing; sync + commit format correct.
