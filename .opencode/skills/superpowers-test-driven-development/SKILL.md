---
name: superpowers-test-driven-development
description: Test-after development for embedded firmware. Production code first, then write tests covering normal paths, edge cases, and error paths. Hardware-dependent code uses integration tests or simulation.
metadata:
  author: AI_Copilot_UFS
  version: "2.0"
---

# Test-Driven Development (test-after)

## Overview

Write production code first, then write tests to verify it.

**Core principle:** Every line of production code must be covered by a test that has been run and confirmed passing, before claiming the work is complete.

> **SSD Firmware Adaptation**: Pure logic code (algorithms, state machines, data structures) → unit tests on host compiler. Hardware-dependent code (MMIO, ISR, DMA, registers) → integration tests or simulation at FEEDBACK phase, with untestable paths documented in review.md.

## When to Use

**Always when writing production code:**
- New features
- Bug fixes
- Refactoring
- Behavior changes

**Exceptions (ask your human partner):**
- Throwaway prototypes
- Generated code
- Configuration files

## The Iron Law

```
NO PRODUCTION CODE WITHOUT TESTS
```

Every new function, every modified behavior, every error path must have a corresponding test case that has been executed and confirmed passing.

## Test-after Flow

```
Implement → Compile → Write Tests → Verify Test Validity → Verify → Review
```

### 1. Implement

Write production code per `tasks.md`. Follow coding style, design rules, and concurrency rules from `.opencode/memory/`.

### 2. Compile Verify

```bash
make clean && make -j$(nproc)
```

Confirm:
- Zero errors
- Zero warnings (`-Wall -Werror`)
- All linker symbols resolved

### 3. Write Tests

Cover three categories:

| Category | Requirement |
|----------|-------------|
| **Normal path** | At least one positive case per function |
| **Boundary conditions** | Index 0, max, empty, alignment edges |
| **Error paths** | Each error code has at least one negative case |

Test naming: `test_<module>_<function>_<scenario>_<expected>`

```c
// test_ftl_address_translation.c
void test_ftl_map_lba_to_pba_normal_path_returns_pba(void) {
    uint64_t pba = ftl_lba_to_pba(&ftl, 0);
    assert(pba == EXPECTED_PBA);
}

void test_ftl_map_lba_invalid_range_returns_error(void) {
    int rc = ftl_read(&ftl, MAX_LBA + 1, 1, buf);
    assert(rc == -EINVAL);
}
```

### 4. Verify Test Validity（测试有效性验证）

**这是 test-after 中最关键的步骤。** 因为测试写于代码之后，你从未见到它失败——所以你不知道它是否真的能抓住一个错误。

#### 4.1 对每条测试路径，做一次"注入验证"

For each test scenario (at minimum: one normal path + one error path per function), do a validate-inject cycle:

```
1. 在代码中刻意引入一个该测试应能捕获的 bug
   - 正常路径测试：改返回值、改条件判断、注释掉关键行
   - 错误路径测试：移除错误检查、注释掉错误返回
2. 运行该测试，确认它因注入的 bug 而失败
3. 观察失败信息：断言信息是否准确指出错误位置和原因
4. 撤销注入的 bug
5. 重新运行测试，确认恢复通过
```

```c
// 示例：验证 test_ftl_map_lba_invalid_range_returns_error 的有效性
//
// Step 1: 在 ftl_read() 中注释掉范围检查
// int ftl_read(ftl_context_t *ftl, uint64_t lba, uint32_t count, void *buf) {
//     // if (count == 0 || lba > MAX_LBA) return -EINVAL;  ← 注释掉
//     ...
// }
//
// Step 2: 运行测试，确认失败
// $ make test TEST=test_ftl_map_lba_invalid_range_returns_error
// FAIL: expected -EINVAL, got 0
//
// Step 3: 失败信息明确指出了 -EINVAL 未返回 → 有效
//
// Step 4: 撤销注入
// Step 5: 确认通过
```

#### 4.2 注入验证规则

- **每条测试路径至少做一次注入验证**（正常路径选一条、错误路径选一条、边界条件选一条）
- 硬件依赖代码（HAL 实现层）：注入验证在 mock HAL 上做，真实 HAL 路径在 review.md 中标注
- 注入的 bug 必须**最小化**（一行改动即可触发失败），不得引入大规模修改
- 注入验证的日志/失败信息必须截图或记录到 task 完成证据中

**未做注入验证的测试，在 Review 中标记为"测试有效性未确认"。**

### 5. Verify

```bash
make test
```

Confirm:
- All tests pass
- Output pristine (no errors, warnings)
- All existing tests still pass
- 注入验证的 bug 已全部撤销，代码恢复原状

**Test fails?** Fix the production code, not the test.

**Existing tests fail?** Fix regression immediately.

### 6. Review

Submit to Review Gate. Reviewer checks:
- Tests cover all scenarios declared in `design.md`
- Tests match spec Requirements
- No critical paths left untested (or documented rationale in review.md)
- 注入验证记录可查（哪些测试做了注入验证、结果如何）

## Hardware-Dependent Code Strategy

For code that touches hardware registers, DMA descriptors, ISR handlers, or MMIO:

1. **Abstract first**: Refactor to isolate hardware operations behind a HAL interface. The business logic above HAL can then be unit-tested on host compiler with a mock HAL.

2. **HAL implementation layer**: Keep as thin as possible (< 50 lines per module). Verify via:
   - Compilation (zero warnings)
   - Integration test / simulation at FEEDBACK phase
   - Manual code review (register values, DMA descriptor chains, ISR safety)

3. **Untestable paths**: Document in `review.md`:
   - Why the path cannot be unit-tested
   - What alternative verification was done (code review, formal analysis, hardware-in-loop)

```
┌──────────────────────────────────┐
│  Business logic (host-compiled)   │ ← Unit-tested with mock HAL
│  Unit test: yes                   │
├──────────────────────────────────┤
│  HAL interface (host + cross)     │ ← Contract tested (signature match)
│  Unit test: contract test         │
├──────────────────────────────────┤
│  HAL implementation (cross only)  │ ← Keep minimal, review thoroughly
│  Unit test: no (hardware dep)     │
└──────────────────────────────────┘
```

## Verification Checklist

Before marking work complete:

- [ ] Every new function has at least one test
- [ ] Normal path covered
- [ ] Boundary conditions covered (0, max, empty)
- [ ] Error paths covered (each error code)
- [ ] Inject validation done: at least one normal + one error path validated per function
- [ ] Inject bugs fully reverted, code restored to original
- [ ] All tests pass
- [ ] Compilation clean (zero warnings)
- [ ] Tests use real code (mocks only for HAL abstraction)
- [ ] Untestable paths documented in review.md

Can't check all boxes? Tests are incomplete.

## When Stuck

| Problem | Solution |
|---------|----------|
| Don't know how to test a function | Check `memory/testing_rules.md` for test patterns. Ask your human partner. |
| Test too complicated | Design too complicated. Simplify interface. |
| Must mock everything | Code too coupled. Use HAL abstraction. |
| Hardware dependency blocking tests | Abstract behind HAL interface. Document HAL impl as untestable. |

## Debugging Integration

Bug found? Write a test reproducing it. Test proves fix and prevents regression. The test must cover the exact scenario that triggered the bug.

Never fix bugs without a corresponding test.
