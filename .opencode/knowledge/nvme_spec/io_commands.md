# NVMe I/O 命令集模板

> 本文件定义 NVMe I/O 命令集中 SSD 固件开发最常用的命令。
> 使用时参考 NVMe Specification 2.0，将项目实际实现标记填入。
> 只包含 AI 无法从代码推断的隐性知识。

## 1. NVM Write (Opcode 0x00)

### PRP/Data 结构

| 字段 | 字段名 | 位 | 说明 |
|------|--------|------|------|
| DWORD 10 | SLBA | 63:00 | 起始逻辑块地址 |
| DWORD 12 | NLB | 15:00 | 逻辑块数量（0-based，即 0 = 1 个块） |
| DWORD 13 | DATASET_MGMT | 31:00 | 数据集管理指示 |
| DWORD 14 | ILBRT | 31:00 | 逻辑块引用标签 |
| PRP1/2 | — | — | 数据缓冲区物理地址 |

### 关键约束

- NLB 为 0-based：写入 1 个块时 NLB = 0，写入 n 个块时 NLB = n-1。
- SLBA + NLB 不能超过命名空间的容量。
- PRP1 地址必须页对齐（通常 4KB）。
- 如果数据跨页边界且不连续，必须使用 PRP2。
- 写入方向：主机到控制器（Host to Controller）。

### 错误处理

| 状态码 | 含义 | 固件处理 |
|--------|------|----------|
| 0x00 | 成功 | 正常完成 |
| 0x01 | 无效命令操作码 | 不应发生，检查 Opcode |
| 0x02 | 无效字段 | 检查 SLBA/NLB/PRP |
| 0x80 | 数据传输错误 | 重试或报告 |
| 0x81 | 内部错误 | 标记故障块或报告 |

## 2. NVM Read (Opcode 0x01)

### PRP/Data 结构

与 NVM Write 相同（SLBA、NLB、PRP1/2），但数据方向相反。

### 关键约束

- 读取方向：控制器到主机（Controller to Host）。
- NLB 同样是 0-based。
- 如果 NLB 对应的块中有不可纠正的 ECC 错误，返回错误码 0x86（Unrecovered Read Error）。
- 可以利用 Dataset Management 的 Read Ahead 提示优化读取。

### 错误处理

| 状态码 | 含义 | 固件处理 |
|--------|------|----------|
| 0x00 | 成功 | 正常完成 |
| 0x86 | 不可纠正读错误 | 标记坏块，返回错误数据或全零 |

## 3. NVM Write Zeroes (Opcode 0x04)

### 关键约束

- 不传输数据，仅将指定范围内的逻辑块置零。
- SLBA 和 NLB 与 Write/Read 相同格式。
- 实现时可以选择实际写入零或标记为 TRIM（取决于 Deallocated 或 Written Zero State 配置）。

## 4. NVM Dataset Management (Opcode 0x05, TRIM/Deallocate)

### 关键结构

```c
typedef struct {
    uint8_t  dsm_range_count;  // DSM Range Count (0-based)
    uint8_t  attributes;       // Attributes (bit 0: Deallocate)
    uint16_t reserved;
    uint32_t context_attributes;
} NVME_DSM_CMD;

typedef struct {
    uint32_t starting_lba;     // 起始 LBA
    uint32_t length;            // 范围长度（0-based）
} NVME_DSM_RANGE;
```

### 关键约束

- 最多一次命令可指定 256 个范围。
- 每个 NVME_DSM_RANGE 为 8 字节：4 字节 SLBA + 4 字节 Length。
- Length 为 0-based：范围包含 Length+1 个逻辑块。
- Deallocate 属性（Attribute bit 0）= 1 时为 TRIM。

### 对 FTL 的影响

- 收到 TRIM 命令后，FTL 应标记对应逻辑块为已释放。
- TRIM 不保证立即回收，但应优化 GC 优先级。
- TRIM 范围内的逻辑块后续读取可返回零或全 F（取决于配置）。

## 5. NVM Flush (Opcode 0x08)

### 关键约束

- Flush 命令强制将所有未完成的写入提交到非易失性存储。
- Flush 不指定命名空间（NSID = 0xFFFFFFFF 时作用于所有命名空间）。
- 实现时必须确保 DRAM 中的脏数据全部写入 NAND。

### 对固件的影响

- Flush 触发 DRAM 缓冲区的刷写。
- 必须等待所有相关写入操作完成才能返回完成状态。
- Flush 是性能关键路径，应尽量减少对前台 I/O 的影响。

## 6. 填写说明

1. 将命令字段的具体位定义与 NVMe Spec 版本对齐。
2. 标记项目实际实现的命令为"必须"，其余为"可选"。
3. 错误处理部分填写项目特定的错误恢复策略。
4. 只填写 AI 无法从代码推断的隐性知识。