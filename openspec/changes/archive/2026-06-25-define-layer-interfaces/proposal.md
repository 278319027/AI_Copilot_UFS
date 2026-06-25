## Why

当前 AI_SSD_SIM 项目中 FE（前端）、FTL（闪存转换层）、BE（后端/NAND 执行）三层之间没有清晰的接口契约。各模块直接引用对方内部结构体，地址体系存在 PAA/FAA 两套且转换边界模糊，双核通信队列使用 `void*` 无类型安全。这导致后续模块重构时必然出现接口不匹配问题。本次变更定义三层间的正式接口契约，作为后续所有实现变更的架构基线。

## What Changes

- **FE ↔ FTL 接口**：定义 `FeFtlInterface_t`，明确 FE 如何提交读/写/Trim/Flush 请求给 FTL，以及 FTL 如何回调通知完成
- **FTL ↔ BE 接口**：定义 `FtlBeInterface_t`，明确 FTL 如何提交 NAND 操作请求给 BE，以及 BE 如何回调完成通知
- **地址翻译边界**：明确 PAA ↔ FAA 转换的责任归属和调用点
- **数据所有权规则**：每层接口处谁分配缓冲区、谁释放、所有权何时转移
- **接口头文件**：产出正式的头文件（`.h`），包含结构体定义、函数签名、错误码枚举

**BREAKING**: 当前代码的跨层直接结构体引用将被替换为正式的接口调用。现有实现需要适配新接口。

## Capabilities

### New Capabilities
- `fe-ftl-interface`: FE 层与 FTL 层之间的请求/响应接口规范。覆盖 Host Read/Write/Trim/Flush/Admin 命令的提交方式和完成通知机制
- `ftl-be-interface`: FTL 层与 BE 层之间的 NAND 操作接口规范。覆盖 NAND Read/Write/Erase 请求的提交、调度和完成回调
- `address-translation`: PAA（FTL 层物理地址）与 FAA（BE 层 NAND 地址）之间的转换规范，以及地址编码/解码的责任边界

### Modified Capabilities
<!-- 本次变更是架构基线定义，不修改现有 capability 的行为 -->

## Impact

- **新增 3 个头文件**：`fe_ftl_interface.h`、`ftl_be_interface.h`、`address_translation.h`
- **影响 AI_SSD_SIM 项目** `/home/zsf/AI_Proj/AI_SSD_SIM/src/` 下的核心模块
- 此变更只产出接口头文件和设计文档，不修改任何 `.c` 实现代码
- 后续所有 Phase 实施（双核通信、BE 层、FTL 模块）都将以此为接口约束

## Non-goals

- 不实现任何功能代码
- 不修改现有 `.c` 文件
- 不涉及 OpenSpec CLI 配置变更
- 不涉及 CI/CD 或构建系统变更

## Superpowers Iron Rules

- **verification-before-completion**: 产出头文件需确保语法正确（`gcc -fsyntax-only` 验证）
- **review-work**: 接口设计完成后需正式 Review（本次由 AI 自主完成）

## CodeGraph Queries Needed

- `codegraph explore ftl/` — 了解当前 FTL 层对外暴露的所有符号
- `codegraph explore core/` — 了解双核通信层的数据流
- `codegraph explore nand/` — 了解 NAND HAL 接口
