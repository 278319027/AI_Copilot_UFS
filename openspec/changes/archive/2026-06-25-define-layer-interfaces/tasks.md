## 1. 接口公共类型定义

- [x] 1.1 创建 `src/include/interface_types.h`：定义所有接口层共享的基础类型（`FeCmd_e`、状态码扩展、通用 callback 签名）
- [x] 1.2 创建 `src/include/fe_req_types.h`：定义 FE 请求类型（`FeReqHead_t`、`FeReadReq_t`、`FeWriteReq_t`、`FeTrimReq_t`、`FeFlushReq_t`）
- [x] 1.3 创建 `src/include/be_req_types.h`：定义 BE NAND 请求类型（`BeNandReq_t`、`BeNandReadReq_t`、`BeNandWriteReq_t`、`BeNandEraseReq_t`）

## 2. FE↔FTL 接口头文件

- [x] 2.1 创建 `src/include/fe_ftl_interface.h`：定义 `FeFtlInterface_t` 结构体（submit_read/write/trim/flush 函数指针 + ctx）
- [x] 2.2 添加 `FeFtlInterface_t` 的空值验证宏 `FE_FTL_IFACE_VALID(iface)` 和 getter/setter 辅助内联函数
- [x] 2.3 验证：`gcc -fsyntax-only -Isrc src/include/fe_ftl_interface.h` 通过

## 3. FTL↔BE 接口头文件

- [x] 3.1 创建 `src/include/ftl_be_interface.h`：定义 `FtlBeInterface_t` 结构体（submit_nand_read/write/erase 函数指针 + ctx）
- [x] 3.2 添加 `FtlBeInterface_t` 的空值验证宏和辅助内联函数
- [x] 3.3 验证：`gcc -fsyntax-only -Isrc src/include/ftl_be_interface.h` 通过

## 4. 地址翻译头文件

- [x] 4.1 创建 `src/include/address_translation.h`：声明 `paa_to_faa()` 和 `faa_to_paa()` 函数原型
- [x] 4.2 参考 `config.h` 中的 NAND 拓扑参数实现地址编码/解码逻辑
- [x] 4.3 添加 PAA 和 FAA 格式的位域注释说明
- [x] 4.4 验证：`gcc -fsyntax-only -Isrc src/include/address_translation.h` 通过

## 5. 接口完整性验证

- [x] 5.1 创建 `src/include/interface_spec_check.h`：编译时断言验证所有接口结构体大小和字段对齐符合预期
- [x] 5.2 验证所有头文件可独立包含（无隐式依赖）：gcc -fsyntax-only 全部通过
- [x] 5.3 验证所有头文件同时包含后无重复定义冲突：gcc -fsyntax-only 全部通过

## 6. 设计文档更新

- [x] 6.1 更新 `AI_SSD_SIM/docs/24_Global_Interface_Spec.md`：添加新接口契约章节，标注与旧接口的对应关系
- [x] 6.2 验证所有 spec Requirement 有对应头文件中的实现声明
