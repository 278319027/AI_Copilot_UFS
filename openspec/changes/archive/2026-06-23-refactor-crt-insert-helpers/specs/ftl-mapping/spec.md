## ADDED Requirements

### Requirement: CRT Insert Architecture — Helper Extraction

The system SHALL implement the slot-allocation and eviction sub-logic of `crt_insert()` in `bbssd/crt.c` as **two named file-local helpers**, decoupled from the main insert path. The two helpers are:

1. `static uint32_t crt_find_empty_slot(const struct crt *crt, uint32_t h)` — performs a linear probe from `h` modulo `cap`, returning the first slot index where `entries[slot].valid == false`, or `(uint32_t)-1` if all slots are valid.
2. `static uint32_t crt_evict_oldest(struct crt *crt)` — finds the entry with the smallest `insert_seq`, increments `crt->stat_evict`, and (when `crt->stat_evict % crt->evict_warn_modulo == 0`) emits the `[FEMU] CRT: eviction #N (capacity=K full)` warning to stderr. Returns the chosen slot index.

`crt_insert()` SHALL call both helpers and SHALL NOT contain the slot-probe loop or the eviction-scan loop inline. The helpers SHALL be declared as forward declarations near the top of `crt.c` (after the existing `crt_hash` declaration) and defined below the helpers' first call site.

This requirement documents the implementation architecture chosen in the `refactor-crt-insert-helpers` change (2026-06-23) and applies to **future implementations**: any new insert-path sub-logic (e.g., weighted eviction, LRU-K, or hint-aware eviction) MUST be added as a helper function rather than re-inlined into `crt_insert()`.

#### Scenario: Behavior identical after refactor

- **GIVEN** a CRT with `capacity = N` and `evict_warn_modulo = 1024`
- **WHEN** `crt_insert()` is called with the same `start_lpn` / `start_ppa` / `n_lpns` sequence as before the refactor
- **THEN** the same slot index SHALL be chosen for each call
- **AND THEN** `crt->stat_evict` SHALL be incremented by the same count
- **AND THEN** the same `[FEMU] CRT: eviction #N (capacity=K full)` warning messages SHALL be emitted to stderr at the same `stat_evict` milestones
- **AND THEN** `crt->stat_insert` SHALL be incremented by the same count

#### Scenario: Empty-slot probe matches prior linear-scan behavior

- **GIVEN** a CRT with at least one empty slot
- **WHEN** `crt_find_empty_slot(crt, h)` is called
- **THEN** it SHALL return the smallest `i` in `[0, cap)` such that `entries[(h + i) % cap].valid == false`
- **AND THEN** when no slot is empty, it SHALL return `(uint32_t)-1`

#### Scenario: Oldest-entry eviction matches prior scan behavior

- **GIVEN** a CRT where all slots are valid
- **WHEN** `crt_evict_oldest(crt)` is called
- **THEN** it SHALL return the index of the entry with the smallest `insert_seq` (ties broken by lowest index)
- **AND THEN** `crt->stat_evict` SHALL be incremented by exactly 1
- **AND THEN** if the new `crt->stat_evict` is a multiple of `crt->evict_warn_modulo`, it SHALL emit exactly one `[FEMU] CRT: eviction #N (capacity=K full)` line to stderr

#### Scenario: Future eviction-policy changes use the helper pattern

- **WHEN** a future change introduces a new eviction strategy (e.g., LRU, hint-aware, segment-aware)
- **THEN** the new strategy SHALL be implemented as a helper function in `crt.c` (e.g., `crt_evict_lru()`)
- **AND THEN** `crt_insert()` SHALL call the new helper instead of inlining the eviction logic
