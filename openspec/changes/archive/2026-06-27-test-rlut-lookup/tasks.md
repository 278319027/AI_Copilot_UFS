## 1. 测试环境搭建

- [x] 1.1 创建 `UT/` 目录，准备独立编译的测试框架
- [x] 1.2 确认 `rlut_core.h` 类型定义可作为 standalone 头文件编译

## 2. 测试用例编写

- [x] 2.1 正常路径：连续 PAA 写入后 lookup 返回正确值
- [x] 2.2 bug 场景：不连续 PAA 写入后 lookup 返回正确值（回归 Phase E bug）
- [x] 2.3 边界条件：空 RLUT lookup 返回 false
- [x] 2.4 边界条件：entry 填满后分配新 entry 仍可 lookup
- [x] 2.5 错误路径：NULL 参数返回 ERR_PARAM

## 3. 注入验证

- [x] 3.1 对 2.2 做注入验证：移除不连续检测代码 → `expected 256 got 1` → 恢复 → 通过

## 4. 编译与验证

- [x] 4.1 `gcc -Isrc -o /tmp/test_rlut ...` exit 0
- [x] 4.2 运行测试 5/5 PASS
