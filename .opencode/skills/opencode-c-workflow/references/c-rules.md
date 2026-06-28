# C Programming Constraints for Graph-Constrained Workflow

## Language Standard

- **C99 minimum, C11 preferred.** `-std=gnu11` for GCC extensions when needed.
- **No C++ features.** Pure C. No `//` comments in MISRA-targeted code.

## Type Safety

### Explicitness
- **All integer types explicit.** Use `uint32_t`, `int16_t`, `uint8_t`, etc. Never bare `int`, `long`, `short`, `char` for data.
- **All casts explicit.** No implicit conversions between signed/unsigned or different widths.
- **`size_t` for sizes, `ptrdiff_t` for pointer differences.** Never `int` for indexing.

```c
// 错误
int          len;
int          idx = 0;
long         offset;
int          result = get_size();
PAA_t        paa = lut[idx];          // 隐式窄化/符号转换风险

// 正确
uint32_t     len;
size_t       idx = 0;
ptrdiff_t    offset;
ErrCode_t    result = get_size();
PAA_t        paa = (PAA_t)lut[idx];   // 显式 cast
```

### Sentinel Values

- Use `INVALID_*` macros, not `-1` or `0xFFFFFFFF` literals.
- Example: `#define INVALID_PAA 0xFFFFFFFFU`

```c
// 错误
if (paa == 0xFFFFFFFFU) { ... }
if (lba == -1) { ... }

// 正确
if (paa == INVALID_PAA) { ... }
if (lba == INVALID_LBA) { ... }
```
## Memory Management
### Allocation

- **No `malloc`/`free` in production code.** Use static allocation, memory pools, or arena allocators.
- **ISR context: zero allocation.** Pre-allocated buffers only.
- **DMA buffers: cache-line aligned.** Minimum 64-byte alignment. Use `__attribute__((aligned(64)))` or `ALIGN(64)` macro.

```c
// 错误：运行时分配 + ISR 内分配
void isr_handler(void) {
    uint8_t *buf = malloc(256);   // 禁止
    ...
}

// 正确：静态/预分配
static uint8_t s_isr_buf[256];
void isr_handler(void) {
    uint8_t *buf = s_isr_buf;     // 预分配
    ...
}

// 正确：DMA 缓冲区对齐
static uint8_t s_dma_buf[PAGE_SIZE] __attribute__((aligned(64)));
```

### Ownership
- **Document who owns each pointer.** Caller or callee? Freed when?
- **Async callbacks: ctx lifetime must outlive callback.**
- **No use-after-free.** Code review must trace every free to every use.

## Concurrency & ISR
### ISR Rules

- **ISR minimal.** Set flags, increment counters, push to queue. NO: allocations, long loops, blocking calls, printf.
- **No recursion.** Stack bounded by hardware. ISR nesting depth must be documented.
- **Shared data: critical section protected.** Use test-mockable lock interface (`hal_enter_critical()` / `hal_exit_critical()`).

```c
// 错误：ISR 内做太多事
void nand_done_isr(void) {
    process_page();           // 太长，应推到 task 上下文
    printf("done\n");          // 禁止 printf
    free(req);                // 禁止分配/释放
}

// 正确：只设标志/推队列
void nand_done_isr(void) {
    g_nand_done_flag = 1;
    queue_push(&g_done_q, req);
}
```

### Async Patterns
- **Callback-based APIs: document ctx ownership.**
- **Completion callback invoked ONCE only.**
- **Error path must still invoke callback.** No leaked requests.

## Control Flow
### MISRA Required

- **All `switch` must have `default`.** Even if `default: break;` — document why it's unreachable.
- **No `goto`** except for cleanup-on-error pattern (single label at function end).
- **No recursion.** Iterative solutions only.

```c
// 错误：缺少 default
switch (state) {
    case STATE_IDLE: ...; break;
    case STATE_BUSY: ...; break;
}

// 正确
switch (state) {
    case STATE_IDLE: ...; break;
    case STATE_BUSY: ...; break;
    default:
        /* state 由上层验证，此处不可达 */
        break;
}

// 正确：cleanup-on-error 模式中的单一 goto
ErrCode_t do_work(void) {
    ErrCode_t rc = ERR_OK;
    void *buf = pool_alloc(256);
    if (buf == NULL) {
        rc = ERR_NO_MEM;
        goto cleanup;
    }
    rc = step1(buf);
    if (rc != ERR_OK) goto cleanup;
    rc = step2(buf);

cleanup:
    if (buf != NULL) pool_free(buf);
    return rc;
}
```

### Function Constraints
- **Length < 100 lines.** Hard cap; extract helper if exceeded.
- **Cyclomatic complexity < 15.** Use `codegraph_complexity()` to check.
- **Parameters ≤ 6.** Use struct for larger argument sets.

## Error Handling

- **Return error codes, never errno.** Define `ErrCode_t` enum.
- **Check ALL return values.** Use `__attribute__((warn_unused_result))` on functions where ignoring the return is a bug.
- **Error path must clean up.** Resources allocated before error must be freed.

```c
// 错误：忽略返回值 + 错误路径未释放
void *buf = pool_alloc(256);
write_nand(buf);             // 返回值被忽略
if (failed) return;          // buf 泄漏

// 正确
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

## Headers & Includes
### Public Headers

- **`extern "C"` guard** for C++ compatibility.
- **Header guard**: `#ifndef MODULE_NAME_H` / `#define MODULE_NAME_H`
- **Doxygen on all public API**: `@brief`, `@param`, `@return`, `@note` for side effects.

```c
#ifndef WRITE_BUFFER_H
#define WRITE_BUFFER_H

#ifdef __cplusplus
extern "C" {
#endif

#include <stdint.h>

/**
 * @brief 初始化写缓冲区
 * @return ERR_OK 成功，否则返回错误码
 * @note 必须在任何 host write 之前调用一次
 */
ErrCode_t wbuf_init(void);

#ifdef __cplusplus
}
#endif

#endif /* WRITE_BUFFER_H */
```

### Include Discipline
- **No circular includes.** Use `codegraph_find_cycles()` to detect.
- **Include what you use.** No transitive dependency assumptions.
- **Forward-declare when possible.** Avoid pulling large headers unnecessarily.

## CodeGraph-Enforceable Rules

These rules have corresponding CodeGraph checks:

| Rule | Check Command |
|------|--------------|
| Cyclomatic complexity < 15 | `codegraph_complexity(above_threshold=true)` |
| No circular includes | `codegraph_find_cycles()` |
| Blast radius acceptable | `codegraph_diff_impact(staged=true)` |
| No dead code | `codegraph_roles(role="dead")` |
| Header consumers tracked | `codegraph_file_deps(<header>)` |

## Testing

- **TDD for all new code.** Write test → watch it fail → implement → watch it pass.
- **Unit tests for logic.** Host-side (gcc), no hardware dependency.
- **Integration tests for data paths.** Sim or target hardware.
- **Link-time mock for HAL.** Replace `hal_*.c` with `hal_stubs.c` in test build. See AI_SSD_SIM's `UT/` for example.
- **Regression test per bug fix.** Reproduce the bug first, then fix.

## Embedded-Specific

- **No `printf`/`scanf` in production.** Use debug trace macros (`LOG_DEBUG`, `LOG_ERROR`).
- **No floating point** unless target has hardware FPU.
- **Stack size budgeted per task.** Document maximum stack depth.
- **Watchdog aware.** Long operations must pet the watchdog or be split.
