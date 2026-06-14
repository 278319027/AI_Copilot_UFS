# Coding Style Rules

SSD 固件项目的编码风格规则。AI 生成代码时必须遵守。

## 1. 命名规范

### 1.1 前缀约定

| 模块 | 类型前缀 | 示例 |
|------|----------|------|
| NVMe 命令处理 | `nvme_` | `nvme_process_admin_cmd` |
| FTL 层 | `ftl_` | `ftl_map_lba_to_pba` |
| NAND 驱动 | `nand_` | `nand_read_page` |
| Buffer 管理 | `buf_` | `buf_alloc_dma` |
| 中断处理 | `isr_` | `isr_nand_complete` |
| 平台抽象 | `plat_` | `plat_delay_us` |

### 1.2 命名规则

- 函数名：`模块_动词_名词`，如 `nand_read_page`、`ftl_update_map`
- 结构体类型：`模块+名词+_t`，如 `NandCtx_t`、`NvmeCmd_t`
- 枚举：`模块+名词+_e`，如 `NandStatus_e`、`NvmeOpcode_e`
- 宏/常量：全大写+下划线，如 `NAND_MAX_RETRIES`、`NVME_STATUS_SUCCESS`
- 私有函数：`模块+_internal_+动词` 或 加 `static` + 短名
- 全局变量：`g_模块_名词`，如 `g_ftl_map_table`
- 文件作用域变量：`s_模块_名词`

### 1.3 禁止命名

- 禁止单字母变量（循环变量 i/j/k 除外）
- 禁止匈牙利记号前缀（p/u/dw 等类型前缀）
- 禁止缩写除非已在项目术语表中定义

## 2. 文件规范

### 2.1 文件组织

- 每个 `.c` 文件对应一个清晰职责，不超过 500 行（不含注释）
- 每个 `.h` 文件与 `.c` 文件一一对应
- 头文件保护宏格式：`__模块_文件名_H__`，如 `__NAND_DRIVER_H__`

### 2.2 头文件规则

- `.h` 文件只暴露必要接口，私有函数声明放在 `.c` 文件顶部
- 头文件必须可独立包含（不依赖其他头文件的包含顺序）
- 对外头文件不得暴露内部数据结构细节
- 类型定义放在头文件，变量声明使用 `extern`

### 2.3 include 顺序

```c
// 1. 对应头文件（如果 .c 文件有对应 .h）
#include "module_name.h"
// 2. 项目头文件
#include "project_config.h"
#include "platform.h"
// 3. 子模块头文件
#include "ftl.h"
#include "nand.h"
// 4. 标准库头文件
#include <string.h>
#include <stdint.h>
```

## 3. 接口规范

### 3.1 函数接口

- API 必须有明确的输入、输出和错误码
- 参数顺序：输入参数在前，输出参数在后
- 输出参数使用指针，且必须用 `p_` 前缀标注方向：
  - `p_result`：输出参数
  - `p_buf`：输入输出参数
- 参数必须校验（断言或错误返回）
- 返回值必须定义清楚：0=成功，负数=错误码

### 3.2 错误码设计

- 定义模块级错误码枚举
- 错误码必须可区分：不同模块不同前缀
- 错误码必须可追溯：包含足够上下文信息
- 禁止在错误路径中静默吞掉错误

```c
typedef enum {
    NAND_OK              = 0,
    NAND_ERR_TIMEOUT     = -1,
    NAND_ERR_ECC         = -2,
    NAND_ERR_BAD_BLOCK   = -3,
    NAND_ERR_PROGRAM     = -4,
    NAND_ERR_ERASE       = -5,
    NAND_ERR_PARAM       = -6,
} NandStatus_e;
```

## 4. 类型安全

- 禁止隐式类型转换，必须显式 cast 并加注释说明原因
- 禁止使用裸 `int`，必须使用 `int32_t`/`uint32_t` 等定宽类型
- 指针和整数之间禁止直接运算，必须通过 `uintptr_t` 中转
- 有符号/无符号混合运算必须显式处理

## 5. 内存安全

- 禁止动态内存分配（`malloc`/`free`），除非文档明确允许
- 数组访问必须有边界检查
- 结构体提供 `init` 和 `deinit` 函数
- DMA 缓冲区必须按 cache line 对齐（32 或 64 字节）
- 结构体大小必须是 4 字节对齐（NAND 页对齐要求更高）

## 6. 注释规范

- 函数头注释：职责、参数说明、返回值说明、注意事项
- 关键分支注释：说明为什么这样判断，而非做什么
- TODO 注释格式：`// TODO(owner): 描述`，如 `// TODO(zhang): 需要增加 ECC 校验`
- 禁止无信息量注释（如 `i++; // i 加 1`）

## 7. 编码禁令

- 禁止 `goto` 跳进循环或跳过初始化
- 禁止未初始化的局部变量
- 禁止忽略函数返回值（必须检查或显式 `(void)` 忽略）
- 禁止递归（栈深度不可控）
- 禁止浮点运算（除非有明确 FPU 且文档允许）
- 禁止 `sizeof(void)` 或零长度数组（柔性数组用 `data[]`）
- 禁止在 ISR 中使用浮点