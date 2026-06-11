# NVMe 错误处理与状态码模板

> 本文件定义 NVMe 错误处理的隐性知识。
> AI 无法从代码推断的错误恢复策略和状态码语义必须在此填写。

## 1. NVMe 状态码体系

### 1.1 通用状态码（Status Field）

| 位 | 字段 | 说明 |
|----|------|------|
| [2:0] | SCT (Status Code Type) | 状态码类型 |
| [7:3] | SC (Status Code) | 具体状态码 |
| [8] | MORE | 是否有更多错误信息 |
| [9] | DNR | Do Not Retry — 不建议重试 |
| [10] | CR | Command Retry — 可重试 |

### 1.2 状态码类型（SCT）

| SCT | 类型 | 说明 |
|-----|------|------|
| 0x0 | Generic | 通用状态码 |
| 0x1 | Specific | 命令特定状态码 |
| 0x2 | Media Error | 介质错误（读写失败等） |
| 0x3 | Path Related | 路径相关错误 |
| 0x7 | Vendor Specific | 厂商自定义 |

### 1.3 通用状态码（SCT=0x0）

| SC | 名称 | 含义 | 固件处理 |
|----|------|------|----------|
| 0x00 | Success | 成功 | 正常完成 |
| 0x01 | Invalid Command Opcode | 不支持的命令操作码 | 检查 Opcode 合法性 |
| 0x02 | Invalid Field in Command | 命令中有无效字段 | 检查所有字段范围 |
| 0x03 | Command ID Conflict | Command ID 冲突 | 重新分配 CID |
| 0x04 | Data Transfer Error | 数据传输错误 | 检查 PRP 和数据完整性 |
| 0x05 | Commands Aborted due to Power Loss | 因断电中止请求 | 执行断电保护流程 |
| 0x06 | Internal Error | 控制器内部错误 | 记录错误日志，可能需要重置 |
| 0x07 | Command Abort Requested | 主机请求中止命令 | 执行中止流程 |
| 0x08 | Submission Queue Deletion | SQ 被删除 | 清理 SQ 资源 |
| 0x09 | Fused Command Failure | 融合命令失败 | 清理融合命令资源 |
| 0x0A | Missing Fused Command | 缺少融合命令配对 | 检查融合命令序列 |
| 0x0B | Invalid Namespace or Format | 无效命名空间或格式 | 检查 NSID |
| 0x0C | Command Sequence Error | 命令序列错误 | 检查命令依赖顺序 |
| 0x0D | Invalid SGL Segment Descriptor | SGL 段描述符无效 | 检查 SGL 描述符 |
| 0x0E | Invalid Number of SGL Descriptors | SGL 描述符数量无效 | 检查 SGL 数量 |
| 0x10 | SGL Data Type Error | SGL 数据类型错误 | 检查 SGL 类型 |
| 0x12 | SGL Offset Error | SGL 偏移错误 | 检查偏移量 |
| 0x14 | Host Identifier Inconsistent | 主机标识不一致 | 检查 Host ID |
| 0x15 | Keep Alive Timer Expired | Keep Alive 超时 | 重置连接或中止 |
| 0x16 | Keep Alive Timeout Invalid | Keep Alive 超时值无效 | 拒绝并返回错误 |

### 1.4 介质错误状态码（SCT=0x2）

| SC | 名称 | 含义 | 固件处理 |
|----|------|------|----------|
| 0x80 | Write Failure | 写入失败 | 重试 → 标记坏块 → 报错 |
| 0x81 | Unrecovered Read Error | 不可纠正读错误 | 尝试其他读取策略 → 标记坏块 |
| 0x82 | End-to-end Guard Check Error | E2E 保护校验错误 | 检查 CRC/ Guard |
| 0x83 | End-to-end Application Tag Error | E2E 应用标签错误 | 检查应用标签 |
| 0x84 | End-to-end Reference Tag Error | E2E 参考标签错误 | 检查参考标签 |

## 2. 固件错误处理策略

### 2.1 命令级错误处理

```text
命令处理主流程：
1. 验证命令字段（Opcode, NSID, SLBA, NLB, PRP 等）
2. 字段无效 → 返回 Invalid Field (0x02)
3. 命令不支持 → 返回 Invalid Opcode (0x01)
4. 执行命令逻辑
5. NAND 操作失败 → 根据失败类型选择恢复策略
6. 恢复成功 → 返回 Success
7. 恢复失败 → 返回对应错误码，设置 DNR/CR 位
```

### 2.2 重试策略

| 错误类型 | 重试次数 | 重试间隔 | 超限处理 |
|----------|----------|----------|----------|
| ECC 可纠正读取 | ___次 | ___µs | 标记弱块 |
| NAND 编程失败 | ___次 | 不等待 | 标记坏块，换块重写 |
| NAND 擦除失败 | ___次 | ___ms | 标记坏块 |
| DMA 传输错误 | ___次 | ___ms | 报告主机 |
| NVMe 命令超时 | ___次 | N/A | 中止命令 |

> **规则**：可重试的错误不设置 DNR 位；不建议重试的错误设置 DNR 位。
> **规则**：重试次数必须有上限，禁止无限重试。

### 2.3 错误恢复优先级

```text
恢复优先级（从高到低）：
1. 数据安全：确保用户数据不丢失
2. 一致性：确保映射表和块状态一致
3. 可用性：尽可能恢复服务
4. 性能：恢复后性能不显著下降
```

### 2.4 致命错误处理

| 致命错误 | 处理流程 |
|----------|----------|
| 控制器内部错误 | 记录错误日志 → 通知主机（报错/重置） |
| 映射表损坏 | 从备份恢复 → 校验数据完整性 |
| DRAM ECC 错误 | 记录日志 → 尝试恢复 → 必要时重置 |
| NAND 全局故障 | 进入安全模式 → 通知主机 |

## 3. 错误日志

### 3.1 错误日志结构

```c
typedef struct {
    uint64_t    error_count;         // 累计错误数
    uint64_t    sq_id;               // 提交队列 ID
    uint64_t    cmd_id;              // 命令 ID
    uint64_t    status_field;        // 状态码字段
    uint16_t    error_location;      // 错误位置（字节偏移）
    uint64_t    lba;                 // 相关 LBA
    uint32_t    nsid;                // 命名空间 ID
    uint8_t     vendor_specific[8];  // 厂商自定义信息
} NvmeErrorLog_t;
```

### 3.2 日志规则

- 错误日志必须持久化（掉电后可恢复）。
- 日志条目数量有上限（NVMe 规范定义）。
- 每个致命错误必须立即记录。
- 非致命错误可批量记录。
- 日志满后覆盖最旧的条目。

## 4. AER（异步事件通知）

### 4.1 固件必须上报的异步事件

| 事件类型 | 事件代码 | 触发条件 |
|----------|----------|----------|
| 介质健康状态变化 | 0x0B | 坏块数量超过阈值、可用预留空间低于阈值 |
| 预留空间不足 | 0x0B | 可用 Block 数低于配置阈值 |
| 温度超限 | 0x02 | 控制器温度超过警告/临界阈值 |
| 可靠性警告 | 0x01 | NAND 写入寿命接近上限 |
| 断电保护 | 0x06 | 检测到意外断电 |

### 4.2 AER 配置要求

- 温度警告阈值和临界阈值必须可配置。
- 预留空间阈值必须可配置。
- AER 必须在初始化时由主机启用（Set Features 命令）。

## 5. 填写说明

1. 将重试次数和间隔替换为实际产品配置。
2. 将致命错误处理流程替换为实际平台策略。
3. 将厂商自定义状态码添加到 SCT=0x7 部分。
4. 每个不同固件版本一个文件，命名格式：`error_handling_<version>.md`。