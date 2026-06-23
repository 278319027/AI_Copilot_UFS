# Verify Report: <change-id>

> 由 `/opsx:verify` 在 Stage 3.5 生成，是 Review Gate 的结构化输入。
> 任何一项 FAIL 都禁止进入 `/opsx:archive`。

## 基本信息

- **变更 ID**: <change-id>
- **生成时间**: <YYYY-MM-DD HH:MM>
- **生成方式**: `bash .opencode/scripts/verify_change.sh <change-id>`（自动化）或手动 6-check
- **关联 commit**: <commit-hash>
- **执行人**: <AI Agent / Human>

## 6 项 verify gate 结果

### Check 1: tasks.md 勾选完成度

- 命令: `grep -c '^\- \[x\]' openspec/changes/<id>/tasks.md`
- 结果: `<N> checked / <M> unchecked`
- 通过标准: unchecked == 0
- 状态: ✅ PASS / ❌ FAIL

### Check 2: 编译通过

- 命令: `cd build-femu && ninja libsystem.a.p/hw_femu_*.c.o`（或对应 build target）
- 结果: exit <code>, <N> warnings
- 通过标准: exit 0, 0 warnings（warning 需在 review.md 解释）
- 状态: ✅ PASS / ❌ FAIL

### Check 3: 测试通过

- 命令: `make test` 或对应 standalone test
- 结果: `<N>/<N> passed, 0 failed`
- 包含: 单元测试 + 集成测试 + bug-injection 循环
- 状态: ✅ PASS / ❌ FAIL

### Check 4: Spec 一致性

- 命令: `openspec validate --strict --changes`
- 结果: `<N> passed, 0 failed`
- 通过标准: 无 violation
- 状态: ✅ PASS / ❌ FAIL

### Check 5: CodeGraph 闭包

- 命令: `codegraph where <每个新公共符号>` + `codegraph impact <修改文件>`
- 结果: 新符号 call sites 数量 / design.md 预期匹配
- 通过标准: 与 design.md "Decisions" 段一致
- 状态: ✅ PASS / ❌ FAIL

### Check 6: Graphify 完整

- 命令: `graphify update . && graphify diagnose multigraph`
- 结果: `missing_endpoint_edges = 0, dangling_endpoint_edges = 0`
- 状态: ✅ PASS / ❌ FAIL

## Bug injection 覆盖率（per `superpowers-test-driven-development` Iron Rule）

> 每个公共 API 必须有 ≥1 正常路径 + ≥1 错误路径的 red-green 证据。不可覆盖路径必须在 "不可覆盖路径" 段标注。

| 公共 API | 正常路径注入 | 错误路径注入 | 证据位置 |
|----------|--------------|--------------|----------|
| `func_a` | ✅ | ✅ | tests/unit/foo.c:NNN |
| `func_b` | ✅ | ⚠️ 仅正常 | tests/unit/foo.c:MMM（错误路径 N/A，理由：<reason>）|
| ... | | | |

**覆盖率**: <X>/<Y> public APIs (Z%)

## Spec Requirement → 实现 → 测试 追溯

> 每个 `### Requirement` 必须有对应的代码 commit + 测试；每个 `#### Scenario` 必须有对应测试用例。

| Spec Requirement | 场景 | 代码位置 | 测试位置 | 状态 |
|------------------|------|----------|----------|------|
| `ftl-mapping#Requirement X` | Scenario A | bbssd/ftl.c:NNN | tests/unit/crt_test.c:MMM | ✅ |
| ... | | | | |

## 不可覆盖路径（如有）

| 路径 | 不可覆盖原因 | 替代验证方式 |
|------|--------------|--------------|
| `func_c` 错误分支 | 硬件依赖（MMIO）| code review 记录 + integration test 仿真 |

## 总体判定

- **6 项 gate**: <N>/6 PASS
- **Bug injection 覆盖率**: <Z>%
- **Review Gate 准入**: ✅ READY / ❌ NOT READY

如果 NOT READY：
- 哪个 check 失败？
- 修复路径（回 BUILD 阶段？design 阶段？）
- 重新 verify 的最小命令清单

## 附录: 命令输出证据

### Check 1 输出
```
<paste grep -c output>
```

### Check 2 输出
```
<paste ninja last 5 lines>
```

### Check 3 输出
```
<paste test runner last 10 lines>
```

### Check 4 输出
```
<paste openspec validate output>
```

### Check 5 输出
```
<paste codegraph where output for each new symbol>
```

### Check 6 输出
```
<paste graphify diagnose multigraph output>
```

### Bug injection 证据（每个 API 一段）

#### `ppa_advance` red-green
1. Original: `<test passes>`
2. Inject: `<sed -i 's|X|Y|' bbssd/crt.c>`
3. After inject: `<test FAILS at line N>`
4. Revert: `<sed -i 's|Y|X|' bbssd/crt.c>`
5. After revert: `<test passes>`

(repeat for each API with bug injection)
