# Design Rules

SSD 固件设计规则。AI 生成设计或代码方案时必须遵守。

## 1. 状态机设计

### 1.1 基本规则

- 状态数量保持最小，优先使用事件驱动。
- 每个状态必须定义：进入条件、退出条件、超时处理、错误处理。
- 状态必须可枚举，禁止使用整数作为状态值。
- 状态转换必须通过函数调用，禁止在多处直接修改状态变量。

### 1.2 状态机编码模式

```c
typedef enum {
    NAND_ST_IDLE,
    NAND_ST_READ,
    NAND_ST_PROGRAM,
    NAND_ST_ERASE,
    NAND_ST_ERROR,
} NandState_e;

typedef struct {
    NandState_e state;
    NandState_e prev_state;
    uint8_t      retry_cnt;
    uint8_t      error_code;
} NandCtx_t;
```

- 状态枚举必须有 `_ST_` 或类似中间标记。
- `prev_state` 用于错误恢复时回退。
- 状态转换函数只做转换和日志，不做业务逻辑。

### 1.3 禁止模式

- 禁止"上帝状态"：一个状态处理所有逻辑。
- 禁止隐式状态：用 flag 组合替代状态机。
- 禁止不可恢复状态：每个非终态必须有恢复路径。

## 2. 模块边界设计

### 2.1 分层架构

```
┌─────────────────────────────┐
│   NVMe 命令处理层            │  ← 接收主机命令，返回响应
├─────────────────────────────┤
│   FTL 层                    │  ← 逻辑映射、磨损均衡、GC
├─────────────────────────────┤
│   NAND 驱动层               │  ← 按 Page 读/写，按 Block 擦除
├─────────────────────────────┤
│   平台抽象层                │  ← 寄存器、中断、DMA、时钟
└─────────────────────────────┘
```

- 上层只依赖下层的接口，禁止反向依赖。
- 禁止跨层调用：NVMe 层不得直接调用 NAND 驱动。
- 每层对外暴露的接口必须通过头文件定义，内部实现不得暴露。

### 2.2 模块职责

| 模块 | 职责 | 禁止 |
|------|------|------|
| NVMe 层 | 命令解析、SQ/CQ 管理、PRP 处理 | 不得直接操作 NAND |
| FTL 层 | LBA→PBA 映射、磨损均衡、GC、SLC Cache | 不得直接操作寄存器 |
| NAND 层 | Page 级读写、Block 级擦除、ECC、坏块管理 | 不得反向调用 FTL |
| Platform 层 | 寄存器访问、中断、DMA、时钟、DRAM | 只被调用，不主动发起业务 |

## 3. Context 设计

### 3.1 原则

- Context 只保存必要状态，禁止把业务逻辑塞进 Context。
- Context 生命周期必须明确：谁创建、谁销毁、谁持有。
- Context 的初始化和清理必须成对。
- 多核共享的 Context 必须标注访问模式和锁保护。

### 3.2 Context 模板

```c
typedef struct {
    // 标识
    uint32_t        magic;          // 必须有 magic 校验

    // 状态
    NandState_e     state;

    // 配置（初始化后只读）
    uint32_t        block_count;
    uint32_t        page_per_block;

    // 运行时数据
    uint8_t        *dma_buf;
    uint32_t        dma_buf_len;

    // 同步
    SpinLock_t      lock;           // 中断安全

    // 统计
    uint32_t        retry_cnt;
    uint32_t        error_cnt;
} NandCtx_t;
```

- `magic` 字段用于运行时校验 Context 是否被破坏。
- 配置数据和运行时数据分开存放。
- 锁的类型必须标注（自旋锁 vs 互斥锁）。

## 4. 资源管理

### 4.1 基本规则

- 禁止隐式资源泄漏：每个资源申请必须有对应释放路径。
- 错误路径必须可回收：`goto cleanup` 模式统一释放。
- 生命周期必须可追踪：谁分配、谁释放、何时释放。

### 4.2 Buffer 管理

- DMA Buffer 必须从预分配池分配，禁止动态分配。
- Buffer 分配必须有超时机制，防止死等。
- Buffer 必须有类型标记（数据方向、用途），防止误用。
- 释放 Buffer 前必须确认 DMA 传输完成。

### 4.3 NAND 资源

- 每个物理 Block 有明确的用途标记（数据/GC/Spare）。
- 写入前必须检查 Block 状态（Good/Bad）。
- 擦除次数必须追踪（磨损均衡基础）。
- 禁止对同一 Page 写入两次（NAND 限制）。

## 5. 错误处理设计

### 5.1 错误传播

- 底层错误必须向上传播，禁止静默吞掉。
- 错误码必须包含模块前缀，便于定位。
- 关键路径必须有 fallback（重试/降级/报错）。

### 5.2 错误恢复

- NAND ECC 可纠正错误：重试读取、ECC 纠正、标记弱块。
- NAND ECC 不可纠正错误：标记坏块、重映射数据。
- NVMe 命令错误：返回对应状态码，记录错误日志。
- DMA 传输错误：重试、超时后报错。
- 中断丢失：超时检测 + 轮询 fallback。

### 5.3 断电恢复

- 必须有映射表的断电保护机制（CRC + 版本号 + 双备份）。
- 断电恢复流程必须可验证（校验数据完整性）。
- GC 过程中的断电必须可恢复（原子性操作或日志）。

## 6. 性能设计

### 6.1 时序关键路径

- NVMe SQ/CQ 处理必须在 µs 级别完成。
- NAND 操作等待期间 CPU 应释放去做其他工作。
- DMA 传输与 CPU 计算应重叠（双缓冲）。

### 6.2 内存使用

- 预分配所有运行时内存（禁止 malloc）。
- 内存池按模块划分，避免全局竞争。
- 映射表设计考虑 DRAM 限制（部分加载策略）。

### 6.3 禁止模式

- 禁止在热路径中做不必要的计算。
- 禁止在 ISR 中做复杂处理（推迟到 tasklet/worker）。
- 禁止在锁内做 I/O 操作。

## 7. 设计方案确认门禁（四级）

四级门禁（Proposal Gate → Design Gate → Review Gate → Archive Gate）的权威定义、校验命令、checklist 和简化豁免规则统一在 `.opencode/skills/sd-firmware-copilot/SKILL.md`。本节仅给出一句话流程摘要，详细规则请跳转。

**流程摘要**：

- **Proposal Gate**（动机 OK）：`/opsx:propose` 完成后 → `openspec validate --strict --changes` 通过 + 5 项人工 checklist
- **Design Gate**（架构 OK）：design.md + tasks.md 完成后 → 校验同上 + 7 项人工确认清单（参见 `openspec-workflow/SKILL.md` §4.3「待人工确认清单」）
- **Review Gate**（代码匹配 spec）：编码 + Review 后 → 校验同上 + 11 项 Review 检查（参见 `openspec-workflow/SKILL.md` §6「Review 检查项」）
- **Archive Gate**（归档提交）：Review 通过后 → `chore(spec): archive <id>` 提交（合并 specs/ 与 changes/）

**简化豁免**：单文件 bugfix / 文档变更 / 配置变更 / 跨模块变更的处理见 `.opencode/skills/sd-firmware-copilot/SKILL.md`。