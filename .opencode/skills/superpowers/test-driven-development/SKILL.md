---
name: test-driven-development
description: Use when implementing any feature or bugfix, before writing implementation code
---

# Test-Driven Development (TDD)

## Overview

Write the test first. Watch it fail. Write minimal code to pass.

**Core principle**: If you didn't watch the test fail, you don't know if it tests the right thing.

**Embedded C adaptation**: Two paths below. Path A for pure-logic code (test first). Path B for hardware-dependent code (compile first, test at FEEDBACK).

## The Iron Law

```
NO PRODUCTION CODE WITHOUT VERIFICATION
```

**Path A** (pure logic — algorithms, data structures, parsers):
Write the test → watch it fail → write minimal code to pass.

**Path B** (hardware-dependent — MMIO, ISR, DMA, register access):
Compile cleanly → verify in BUILD → run system tests at FEEDBACK.

## When to Use

**Always**: new features, bug fixes, refactoring, behavior changes.

**Exceptions** (ask your human partner): throwaway prototypes, generated code, config files.

## Path A — Pure Logic (Red → Green → Refactor)

### RED — Write Failing Test

Write one minimal test. Clear name, real code, one behavior.

```c
/* test_ftl_address_translation.c */
void test_lba_to_pba_maps_to_correct_channel(void) {
    uint64_t lba = 0;
    uint64_t pba = ftl_lba_to_pba(&ftl, lba);
    assert(pba == EXPECTED_PBA);
}
```

### Verify RED — Watch It Fail

```bash
make test TEST=test_ftl_address_translation
```

Confirm: test FAILS (not errors), failure message is expected, fails because feature missing.

**Test passes?** You're testing existing behavior. Fix test.  
**Test errors?** Fix error, re-run until it fails correctly.

### GREEN — Minimal Code

Write simplest code to pass the test. No extras, no refactoring other code.

```c
uint64_t ftl_lba_to_pba(ftl_context_t *ftl, uint64_t lba) {
    return lba % ftl->pages_per_block; /* minimal — passes test */
}
```

### Verify GREEN

```bash
make test TEST=test_ftl_address_translation
make test            /* all tests still pass */
```

### REFACTOR — Clean Up

After green only: remove duplication, improve names, extract helpers. Keep tests green.

### Repeat

Next failing test for next feature.

## Path B — Hardware Dependent (Compile → Verify → FEEDBACK Test)

For code that touches hardware registers, DMA descriptors, ISR handlers, or MMIO — TDD test-first is impractical (no emulator, or emulator doesn't support NVMe Admin commands like FEMU QTest).

### BUILD — Compile and Verify

```bash
make clean && make -j$(nproc)    /* zero warnings */
```

Verify: compilation clean (`-Wall -Werror`), no new warnings, linker symbols resolved.

### FEEDBACK — System Tests

After BUILD, run tests based on change scale:

| Change size | Test strategy |
|-------------|---------------|
| ≤ 20 lines | Manual review + compile |
| 20–200 lines | Integration test or simulation run |
| 200+ lines | Unit tests + integration + simulation |
| Cross-module | Full regression suite |

```bash
make test           /* unit tests if available */
./run_femu.sh       /* simulation/integration */
```

## Good Tests

| Quality | Good | Bad |
|---------|------|-----|
| **Minimal** | One thing | `test('validates everything')` |
| **Clear** | Name describes behavior | `test1` |
| **Real** | Tests production code | Mocks-only test |

## Verification Checklist

Before marking work complete:

- [ ] Path A: watched each test fail before implementing
- [ ] Path A: each test failed for expected reason (feature missing, not typo)
- [ ] Path B: compilation clean with `-Wall -Werror`
- [ ] Wrote minimal code to pass each test
- [ ] All tests pass (Path A) or system test passes (Path B)
- [ ] Edge cases and errors covered

## When Stuck

| Problem | Solution |
|---------|----------|
| Don't know how to test | Write wished-for API first. Ask human partner. |
| Test too complicated | Design too complicated. Simplify interface. |
| Must mock everything | Code too coupled. Use dependency injection. |
