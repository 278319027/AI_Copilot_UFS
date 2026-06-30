# C Programming Constraints

## Layer 1: Universal (always enforced, all C projects)

### Type Safety
- **Explicit integer types preferred.** Use `uint32_t`, `int16_t`, etc. Bare `int`/`long` require justification.
- **All casts explicit.** No implicit signed/unsigned or width conversions.
- **`size_t` for sizes, `ptrdiff_t` for pointer differences.**

```c
// BAD
int    len   = get_size();
int    idx   = 0;
PAA_t  paa   = lut[idx];            // implicit narrowing risk

// GOOD
size_t len   = (size_t)get_size();
size_t idx   = 0;
PAA_t  paa   = (PAA_t)lut[idx];     // explicit cast
```

### Control Flow
- **All `switch` must have `default`.** Even `default: break;` — document reason if unreachable.
- **No `goto`** except cleanup-on-error (single label at function end).
- **Function length < 150 lines.** Cyclomatic complexity < 20. Use `codegraph_complexity()` to check.

```c
// BAD: missing default
switch (state) {
    case STATE_IDLE: ...; break;
    case STATE_BUSY: ...; break;
}

// GOOD
switch (state) {
    case STATE_IDLE: ...; break;
    case STATE_BUSY: ...; break;
    default:
        /* state validated by caller, unreachable here */
        break;
}
```

### Error Handling
- **Check ALL return values.** Use `__attribute__((warn_unused_result))` on critical functions.
- **Error path must clean up.** Resources allocated before error must be freed.
- **Return error codes, not errno.** Define `ErrCode_t` enum.

```c
// BAD: ignored return, leaked buffer
void *buf = pool_alloc(256);
write_nand(buf);              // return value ignored
if (failed) return;           // buf leaked

// GOOD
ErrCode_t write_page(void) {
    ErrCode_t rc = ERR_OK;
    void *buf = pool_alloc(256);
    if (buf == NULL) return ERR_NO_MEM;
    rc = write_nand(buf);
    if (rc != ERR_OK) goto cleanup;
cleanup:
    pool_free(buf);
    return rc;
}

__attribute__((warn_unused_result))
ErrCode_t write_nand(const void *buf);
```

### Headers & Includes
- **Header guard**: `#ifndef MODULE_NAME_H` / `#define MODULE_NAME_H`
- **`extern "C"` guard** for C++ compatibility.
- **Include what you use.** No transitive dependency assumptions.
- **No circular includes.** Use `codegraph_find_cycles()` to verify.
- **Public header changes → run `codegraph_file_deps(<header>)` first.**

### Testing
- **TDD mandatory.** Write test → see it fail → implement → see it pass.
- **Bug fix must include regression test.** Reproduce bug first, then fix.
- **Prefer host-side unit tests** where hardware not required.

---

## Layer 2: Embedded (activated by project signals)

*Activated when: `.ld` linker script exists OR `-nostdlib` in build OR `embedded: true` in `.opencode/config`*

### Memory Management
- **No `malloc`/`free` in production.** Static allocation, memory pools, or arena allocators.
- **DMA buffers cache-line aligned.** `__attribute__((aligned(64)))` or `ALIGN(64)`.
- **Document pointer ownership.** Caller or callee? Freed when?

```c
// BAD: DMA buffer unaligned
static uint8_t s_dma_buf[PAGE_SIZE];

// GOOD: cache-line aligned
static uint8_t s_dma_buf[PAGE_SIZE] __attribute__((aligned(64)));
```

### ISR (Interrupt Service Routine)
- **ISR minimal.** Set flags, increment counters, push to queue ONLY.
- **ISR: NO allocations, NO long loops, NO blocking calls, NO printf.**
- **Shared data protected.** Use `hal_enter_critical()` / `hal_exit_critical()`.

```c
// BAD: ISR does too much
void nand_done_isr(void) {
    process_page();            // too long, push to task context
    printf("done\n");          // forbidden
    free(req);                 // forbidden
}

// GOOD: only flags/queue
void nand_done_isr(void) {
    g_nand_done_flag = 1;
    queue_push(&g_done_q, req);
}
```

### Stack & Recursion
- **No recursion.** Stack bounded by hardware. Iterative solutions only.
- **Stack size budgeted per task.** Document maximum depth.
- **Watchdog aware.** Long operations must pet watchdog or be split.

### Integer Types (strict)
- **All integer types explicit.** `uint32_t`, `int16_t`, `uint8_t` — never bare `int`/`long`/`short`/`char` for data.
- **Sentinel values**: use `INVALID_*` macros, not `-1` or `0xFFFFFFFF` literals.
- **No floating point** unless hardware FPU confirmed.

### Production Constraints
- **No `printf`/`scanf` in production.** Use debug trace macros (`LOG_DEBUG`, `LOG_ERROR`).
- **C99 minimum, C11 preferred.** `-std=gnu11` for GCC extensions.

---

## CodeGraph-Enforceable Rules

| Rule | Check Command |
|------|--------------|
| Cyclomatic complexity threshold | `codegraph_complexity(above_threshold=true)` |
| No circular includes/calls | `codegraph_find_cycles()` |
| Blast radius acceptable | `codegraph_diff_impact(staged=true)` |
| No dead code | `codegraph_node_roles(role="dead")` |
| Header consumers tracked | `codegraph_file_deps("<header>")` |
| CI gate before commit | `codegraph_check(staged=true)` |
