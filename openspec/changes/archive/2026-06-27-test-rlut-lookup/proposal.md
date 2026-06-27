## Why

Phase E 修复了 RLUT 在 PAA 不连续时 lookup 返回错误地址的 bug（`candidate = start_paa + i` 算出错误值）。但该修复没有对应的回归测试。本次变更为 RLUT 模块添加单元测试，覆盖正常路径、边界条件和 bug 场景，防止回归。

## What Changes

- 新建 `UT/test_rlut.c`：RLUT 模块独立单元测试
- 测试覆盖：连续 PAA lookup、不连续 PAA lookup、空 RLUT lookup、entry 满时分配新 entry
- 使用最小 mock（仅替换 malloc/free），不依赖 NAND/BE 层

## Capabilities

### New Capabilities
- **test-rlut**: RLUT 单元测试，覆盖正常路径 + 边界 + bug 场景

## Impact

- 新文件 `UT/test_rlut.c`
- 不修改现有 `.c` / `.h`

## Non-goals

- 不修改 RLUT 实现代码
- 不创建完整的测试框架（仅 standalone 单文件测试）
