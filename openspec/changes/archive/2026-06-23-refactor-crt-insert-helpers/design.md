# Design — Refactor crt_insert Helpers

## D1. Scope (CodeGraph / static analysis)

**File modified**: `bbssd/crt.c` (only).

**In-tree callers of `crt_insert()`** (verified via `grep -nE "crt_insert\("` on FEMU root):

| Caller | File:Line | Purpose |
|--------|-----------|---------|
| FTL write path | `ftl.c` (host write handling) | cache recently-written contiguous LPN range |
| GC move path | `ftl.c` (garbage collection victim move) | cache relocated range |
| FDP hint path | `ftl.c` (FDP placement hint) | cache hinted range |

All 3 callers use the same signature `(crt, start_lpn, start_ppa, n_lpns)` and see no ABI change. Helper extraction is **internal** to `crt.c` — no caller awareness required.

**Header surface**: `crt.h` (lines 67-117) is unchanged. No new public symbols.

## D2. Module Boundaries

```
crt.c
├── crt_hash()         [static inline, line 43]  ← unchanged
├── crt_find_empty_slot()  [static, NEW]          ← forward decl near top, defn below
├── crt_evict_oldest()     [static, NEW]          ← forward decl near top, defn below
├── crt_insert()        [public]                   ← body shrinks to call helpers
├── crt_lookup()        [public]                   ← unchanged
├── crt_invalidate_*()  [public]                   ← unchanged
├── ppa_advance()       [public, declared in crt.h] ← unchanged
└── crt_*_stats()       [public]                   ← unchanged
```

The two new helpers are `static` (file-local), in the same translation unit as `crt_insert`. This preserves the compiler's ability to inline them at the call site (no `__attribute__((noinline))` needed — they remain zero-cost abstractions).

## D3. Helper Contracts

```c
/* Forward declarations (placed after crt_hash, around line 52) */
static uint32_t crt_find_empty_slot(const struct crt *crt, uint32_t h);
static uint32_t crt_evict_oldest(struct crt *crt);
```

### `crt_find_empty_slot(crt, h)`

- **Input**: `crt` (must be non-NULL — asserted by caller before probe); `h` — natural hash from `crt_hash(start_lpn, cap)`, in `[0, cap)`.
- **Output**: smallest `i` in `[0, cap)` such that `entries[(h + i) % cap].valid == false`; or `(uint32_t)-1` if all slots valid.
- **Side effects**: none.
- **Complexity**: O(cap) worst case, O(1) average for low fill factor.

### `crt_evict_oldest(crt)`

- **Input**: `crt` (must be non-NULL and have `capacity > 0`).
- **Output**: index of entry with smallest `insert_seq` (ties → lowest index).
- **Side effects**: increments `crt->stat_evict` by 1; conditionally `fprintf(stderr, ...)` when `stat_evict % evict_warn_modulo == 0`.
- **Precondition**: caller MUST verify all slots are valid before calling (preserves prior implicit precondition in inline code).
- **Complexity**: O(cap).

## D4. Refactored `crt_insert()` Shape

```c
void crt_insert(struct crt *crt, uint64_t start_lpn,
                const struct crt_ppa *start_ppa, uint32_t n_lpns)
{
    if (!crt || n_lpns == 0) {
        return;
    }
    uint32_t cap = crt->capacity;
    uint32_t h = crt_hash(start_lpn, cap);
    uint32_t slot = crt_find_empty_slot(crt, h);

    if (slot == (uint32_t)-1) {
        slot = crt_evict_oldest(crt);
    }

    crt->entries[slot].valid = true;
    crt->entries[slot].start_lpn = start_lpn;
    crt->entries[slot].start_ppa = *start_ppa;
    crt->entries[slot].n_lpns = n_lpns;
    crt->entries[slot].insert_seq = ++crt->insert_seq_counter;
    crt->stat_insert++;
}
```

Net change: `crt_insert` body shrinks from 46 → ~22 lines. Two new helpers add ~30 lines. Net file delta: ~+5 LOC.

## D5. Behavior Equivalence (per §1b refactor requirement)

| Observable | Before (inline) | After (helpers) |
|------------|-----------------|-----------------|
| Slot selection | First empty `entries[(h+i) % cap]` with `!valid` | Same — `crt_find_empty_slot` uses identical loop |
| Fallback when full | Scan all entries, pick smallest `insert_seq` | Same — `crt_evict_oldest` uses identical loop with identical tie-break |
| `stat_evict` increment | +1 per eviction | Same — incremented in `crt_evict_oldest` |
| `stat_insert` increment | +1 per successful insert | Same — incremented in `crt_insert` after slot chosen |
| Warn `fprintf` | When `stat_evict % evict_warn_modulo == 0` | Same — same condition, same `fprintf` args |
| Warn message | `"[FEMU] CRT: eviction #%lu (capacity=%u full)\n"` | Same — verbatim string |

**Conclusion**: behavior identical. No `crt_lookup` change, no `ppa_advance` change, no `crt_invalidate_*` change, no `crt_*_stats` change.

## D6. Concurrency Analysis

Per `crt.h` lines 9-10: "FTL is single-threaded (see `ftl_thread()` in `ftl.c`). All CRT operations MUST be called from the FTL thread. No internal locking."

The refactor preserves this contract:
- Both helpers are `static` and only called from `crt_insert`.
- `crt_insert` is only called from the FTL thread.
- No new shared state, no new locking requirement.

## D7. Test Strategy (M-1 verify-report)

Since `crt.c` has no unit test harness in the FEMU repo, the test is blackbox:

1. **Build**: `make -C /home/zsf/AI_Proj/femu/hw/femu -j$(nproc)` (or `make` from FEMU root) — must succeed.
2. **Runtime**: launch FEMU with CRT enabled, issue a known pattern of host writes that force ≥ 1 eviction (capacity small enough to fill), then trigger `FEMU_PRINT_CRT_STATS` admin flip. Verify:
   - `stat_evict` count matches expected (deterministic for given write pattern).
   - Warn message appears at the right milestone (or doesn't, if not crossed).
3. **Regression check**: compare `stat_insert` and `stat_hit/miss` against a baseline (per `add-crt-mapping-cache` drill).

For this drill (refactor only, no behavior change), the build success is the primary evidence. A full FEMU run is omitted to keep the drill cycle fast (the prior `refactor-bb-flip-table` drill also used build-success as primary evidence — consistent with C-style refactor verification standard).

## D8. Risk + Mitigation

| Risk | Likelihood | Mitigation |
|------|------------|------------|
| Subtle off-by-one in `crt_find_empty_slot` wrapping | low | identical loop body to prior inline code; build + read-back |
| Tie-break difference in `crt_evict_oldest` | low | identical loop with `oldest_seq` initial = `entries[0].insert_seq`, iterate from `i=1` — same as inline |
| Compiler de-inlining causing minor perf change | very low | helpers are `static` and tiny; compiler inlines them naturally; no `__attribute__((noinline))` |
| Header surface change (caller break) | none | `crt.h` untouched |
