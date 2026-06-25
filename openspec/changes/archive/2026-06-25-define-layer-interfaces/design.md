## Context

AI_SSD_SIM 是 DRAM-less SSD 模拟器，代码 21K+ 行，现有三层架构：

```
FE (trace_reader/main) → FTL (ftl/* + core/core0_ftl) → BE (core1_nand + nand/* + Scheduler/*)
```

当前接口问题：
1. **FE↔FTL**：`FtlReq_t` 承载所有请求类型（读/写/Trim），但无正式接口定义。FE 直接调用 `ftl_gen_ftl_write_req()` / `ftl_read_req_submit()` 等函数
2. **FTL↔BE**：`NandReq_t` 通过 `dual_core_submit_enqueue()` 以 `void*` 提交。完成回调通过 `pNandReqCallBack` 函数指针，上下文使用 `void* ctx`
3. **地址体系**：FTL 使用 `Paa_t` (U64)，BE 使用 `FAA_t` (U32) 加 `NandAddr_t` 位域结构。转换在 `nand_req.h` 中通过 `FAA_to_PAA` / `PAA_to_FAA` 宏完成，调用点散落各处
4. **缓冲区所有权**：无明确的分配/释放边界

本设计定义三层接口契约，所有接口以纯头文件形式产出，不修改任何 `.c` 文件。

## Goals / Non-Goals

**Goals:**
- 定义 FE↔FTL 接口：请求提交、完成通知、错误传播的正式 API
- 定义 FTL↔BE 接口：NAND 操作（读/写/擦除）的提交和完成 API
- 定义地址翻译边界：PAA↔FAA 转换的单一职责点
- 定义缓冲区所有权规则：每层谁分配、谁释放、何时转移
- 所有接口以 C 头文件表达，纯语法可验证（`gcc -fsyntax-only`）

**Non-Goals:**
- 不实现任何功能逻辑
- 不修改任何 `.c` 文件
- 不涉及配置/构建系统变更
- 不定义硬件寄存器级接口（属于 NAND HAL 内部）
- 不定义文件 I/O 接口（属于 NAND Hal 持久化内部）

## Decisions

### D1: 接口风格 — 纯 C 结构体 + 函数指针表，而非直接函数调用

**选择**：每个接口层定义为一个 `_interface_t` 结构体，包含该层所有操作函数指针 + 上下文指针。

```c
// FE→FTL 接口（FTL 实现的虚函数表）
typedef struct {
    FtlErr_e (*submit_read)(void* ctx, const FeReadReq_t* req);
    FtlErr_e (*submit_write)(void* ctx, const FeWriteReq_t* req);
    FtlErr_e (*submit_trim)(void* ctx, const FeTrimReq_t* req);
    FtlErr_e (*submit_flush)(void* ctx, const FeFlushReq_t* req);
    void*    ctx;  // FTL 内部上下文
} FeFtlInterface_t;
```

**理由**：
- 与现有 `LogicalUnit_t` 的虚函数表风格一致（项目已有此模式）
- 支持双核场景下接口跨线程传递（接口指针可序列化）
- 方便 UT Mock：测试时替换接口表即可
- 解耦编译依赖：FE 只需包含接口头文件，不需要包含 FTL 内部头文件

**备选方案**：
- 直接函数调用（如现有方式）：耦合度高，UT Mock 困难
- 消息队列 + 消息 ID 分发：增加了序列化/反序列化开销，不适合模拟器场景

### D2: 缓冲区所有权规则 — 提交方分配，接收方使用后通知释放

```
FE → FTL: FE 分配 data_buf，FTL 在 callback 中通知 FE 可释放
FTL → BE: FTL 分配 NandReq 和 data_buf，BE 在 callback 中通知 FTL 可回收
```

**理由**：
- 避免在双核环境中跨线程分配/释放
- 与现有 `NandReqPool_t` 的对象池模式一致
- 每层自管自己的 pool，简化内存生命周期

### D3: PAA↔FAA 翻译 — BE 层入口处单一转换点

**选择**：地址翻译由 BE 层在接收 NAND 请求时统一完成。FTL 只使用 `PAA_t`，BE 入口处将 PAA 转为 FAA 供调度和 HAL 使用。

```c
// BE 接口定义
typedef struct {
    FAA_t  faa;          // BE 层使用 FAA
    U8     is_slc_mode;  // SLC/TLC 模式
    // ... 
} BeNandReq_t;

// BE 入口处转换
static inline FAA_t paa_to_faa(PAA_t paa) {
    // 从 PAA 解码出 ch/ce/plane/block/page/du
}
```

**理由**：
- FTL 不需要理解 NAND 几何拓扑（Channel/CE/Die/Plane）
- BE 层内部转换，降低 FTL 对 NAND 配置的依赖
- `config.h` 中的 NAND 拓扑配置仅 BE 层关注

### D4: 回调模型 — 单回调函数指针，异步完成通知

**选择**：所有接口使用 `void (*callback)(void* ctx, int status)` 风格，不引入事件循环或信号量。

**理由**：
- 与项目现有 `CallBack_t` / `pNandReqCallBack` 风格一致
- 双核场景下 Core1→Core0 的完成通知已经通过 `complete_queue` 传递
- 不引入额外同步原语，保持模拟器的简单性

### D5: FtlReq_t 拆分 — FE 请求与 FTL 内部处理分离

FTL 当前使用 `FtlReq_t` 同时作为 FE 传来请求和 FTL 内部处理载体。**新设计拆分为两层**：

```
FeReq_t (FE→FTL 请求，上层视角)
  ├── cmd: FE_CMD_READ / WRITE / TRIM / FLUSH
  ├── start_laa / laa_cnt
  ├── data_buf (FE 分配)
  └── callback (FTL 完成时调用)

FtlInternalReq_t (FTL 内部处理)
  ├── fe_req: 来源 FeReq_t 引用
  ├── lu_id / mapping info / rlut_entries
  ├── nand_reqs[]: 下分给 BE 的 NAND 请求
  └── state: 处理状态机
```

**理由**：
- 明确请求生命周期：FE 创建 → FTL 分解 → BE 执行 → FTL 聚合 → FE 完成
- 避免当前实现中 `FtlReq_t` 被各模块混杂填充的架构问题

## Layer Interface Diagram

```
┌────────────────────────────────────────────────────────┐
│  FE (Host/Trace)                                        │
│  FeFtlInterface_t.submit_read/write/trim/flush()        │
└────────────────────────┬───────────────────────────────┘
                         │ FeReq_t (含 callback)
                         ▼
┌────────────────────────────────────────────────────────┐
│  FTL Core                                              │
│  - LU 分发 (user/middle/system/boot LU)                │
│  - LUT/RLUT 映射查询                                    │
│  - FtlInternalReq_t 状态机                             │
│  FtlBeInterface_t.submit_nand_read/write/erase()       │
└────────────────────────┬───────────────────────────────┘
                         │ BeNandReq_t (含 PAA → FAA 转换)
                         ▼
┌────────────────────────────────────────────────────────┐
│  BE (Core1 + NAND HAL + FCL)                          │
│  - PAA→FAA 转换（单一入口点）                           │
│  - FCL 调度（Channel/Die 排队）                         │
│  - NAND HAL 执行（读/写/擦除）                           │
│  - callback → FTL 完成通知                             │
└────────────────────────────────────────────────────────┘

数据流方向:
  FE → FTL: 请求下发 (异步)
  FTL → FE: 完成回调 (异步)
  FTL → BE: NAND 操作提交 (异步)
  BE → FTL: 操作完成回调 (异步)
```

## Data Ownership Rules

| 阶段 | 谁分配 data_buf | 谁释放 data_buf | 同步点 |
|------|----------------|----------------|--------|
| FE→FTL Read | FE 分配 | FE 在 callback 后释放 | callback 返回 |
| FE→FTL Write | FE 分配 | FE 在 callback 后释放 | callback 返回 |
| FTL→BE Read | FTL 分配 data_buf | FTL 在 callback 后回收 pool | callback 返回 |
| FTL→BE Write | FTL 指定 data_buf 来源（来自 FE 或内部） | 所有权随 callback 返还 | callback 返回 |
| FTL→BE Erase | 无 data_buf | N/A | callback 返回 |

## Risks / Trade-offs

| Risk | Mitigation |
|------|-----------|
| 虚函数表引入间接调用开销，模拟精度受影响 | 模拟器场景不关心 CPU 指令级性能；IO 延迟（us 级）远大于间接调用（ns 级） |
| 接口拆分后现有代码需大量适配 | Phase A 不修改 `.c`，后续 Phase 逐个模块适配，确保每一步都可验证 |
| `FeReq_t` / `FtlInternalReq_t` 拆分可能导致结构膨胀 | 保持最小化设计，只放入必要字段；后续可根据需要扩展现有结构而非新建 |
| `void* ctx` 类型不安全 | 每接口定义专用上下文类型（`FeReadCtx_t`/`FeWriteCtx_t`），不使用裸 `void*` |

## Open Questions

1. FE 层是否需要支持 FUA (Force Unit Access) 和 Atomic Write？→ 先在接口中保留 flags 位，后续 Phase 实现
2. BE 是否需要暴露超时/重试机制给 FTL？→ 初版在 callback 中通过 status 码传播，后续 Phase 细化
3. 双核模式下接口函数指针如何跨 Core 传递？→ 通过 `dual_core.h` 共享的 `DualCore_t` 结构体承载
