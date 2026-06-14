# NVMe 命令集知识模板

> 本文件定义 NVMe 规约中 SSD 固件开发最常用的命令集和数据结构。
> 填写时参考 NVMe Specification 2.0，将项目实际使用的字段值填入。
> 只包含 AI 无法从代码推断的隐性知识。

## 1. Admin 命令集

| Opcode | 命令名 | 功能 | 固件实现优先级 |
|--------|--------|------|----------------|
| 0x00 | Admin Delete I/O SQ | 删除 I/O 提交队列 | 必须 |
| 0x01 | Admin Create I/O SQ | 创建 I/O 提交队列 | 必须 |
| 0x02 | Admin Get Log Page | 获取日志页 | 必须 |
| 0x04 | Admin Delete I/O CQ | 删除 I/O 完成队列 | 必须 |
| 0x05 | Admin Create I/O CQ | 创建 I/O 完成队列 | 必须 |
| 0x06 | Admin Identify | 识别控制器/命名空间 | 必须 |
| 0x08 | Admin Abort | 中止命令 | 必须 |
| 0x09 | Admin Set Features | 设置特性 | 必须 |
| 0x0A | Admin Get Features | 获取特性 | 必须 |
| 0x0C | Admin Async Event Req | 异步事件请求 | 必须 |
| 0x0D | Admin NS Management | 命名空间管理 | 可选 |
| 0x0E | Admin FW Activate | 固件激活 | 必须（如支持固件更新） |
| 0x10 | Admin FW Image Download | 固件镜像下载 | 可选 |
| 0x15 | Admin Format NVM | 格式化 NVM | 可选 |
| 0x18 | Admin Security Send | 安全发送 | 可选 |
| 0x19 | Admin Security Receive | 安全接收 | 可选 |

## 2. I/O 命令集（NVM 命令集）

| Opcode | 命令名 | 功能 | 固件实现优先级 |
|--------|--------|------|----------------|
| 0x00 | NVM Write | 写入数据 | 必须 |
| 0x01 | NVM Read | 读取数据 | 必须 |
| 0x02 | NVM Write Uncorrectable | 写入不可纠正数据 | 可选 |
| 0x03 | NVM Write Zeroes | 写零 | 可选 |
| 0x04 | NVB Write | 带区间写入 | 可选 |
| 0x05 | NVM Dataset Management | 数据集管理（TRIM） | 必须 |
| 0x08 | NVM Flush | 刷新 | 可选 |
| 0x09 | NVM Reservation Register | 预留注册 | 可选 |
| 0x0A | NVM Reservation Report | 预留报告 | 可选 |
| 0x0B | NVM Reservation Acquire | 预留获取 | 可选 |
| 0x0C | NVM Reservation Release | 预留释放 | 可选 |

## 3. 关键数据结构

### 3.1 SQ Entry（提交队列条目）- 64 字节

| 双字偏移 | 位范围 | 字段 | 说明 |
|----------|--------|------|------|
| DW0 | 31:00 | CDW0.OPC | 命令操作码 |
| DW0 | 21:00 | CDW0.CID | 命令标识符 |
| DW1 | 31:00 | NSID | 命名空间 ID |
| DW2-3 | 63:00 | Reserved | 保留 |
| DW4-5 | 63:00 | PRP1 | PRP 条目 1 |
| DW6-7 | 63:00 | PRP2 | PRP 条目 2 |
| DW10-15 | 依赖命令 | CDW10-CDW15 | 命令特定字段 |

### 3.2 CQ Entry（完成队列条目）- 16 字节

| 双字偏移 | 位范围 | 字段 | 说明 |
|----------|--------|------|------|
| DW0 | 31:00 | CDW0 | 命令特定完成信息 |
| DW1-2 | 63:00 | Reserved | 保留 |
| DW3 | 31:16 | SQ HD | 提交队列头指针 |
| DW3 | 15:00 | SF.SC + SF.SCT | 状态码 + 状态码类型 |

### 3.3 Identify Controller 数据结构（CNS = 01h）

> 只列出 SSD 固件开发最关注的关键字段，完整定义见 NVMe Spec 2.0 Section 5.14。

| 偏移 | 长度 | 字段 | 固件关注点 |
|------|------|------|-----------|
| 00h | 4 | VID + SSVID | PCI 厂商/子厂商 ID |
| 04h | 8 | SN | 序列号（ASCII，20字符） |
| 14h | 8 | MN | 型号名（ASCII，40字符） |
| 24h | 4 | FR | 固件版本（8字符） |
| 27h | 1 | MDTS | 最大数据传输大小（2^n） |
| 29h | 1 | CNTLID | 控制器 ID |
| 2Ch | 4 | VER | NVMe 版本 |
| EC-1FFh | — | I/O Command Set | 支持的 I/O 命令集位图 |

## 4. PRP（Physical Region Page）约束

- PRP1 和 PRP2 描述数据缓冲区的物理地址。
- 数据在 PRP1 地址处开始，按页大小对齐。
- 如果数据跨页边界且不连续，PRP2 指向下一个物理页。
- 数据长度在 CDW12 中指定（以字节为单位）。
- PRP 地址必须是页大小对齐的（通常 4KB）。

## 5. 填写说明

1. 将 Opcode 表中**项目实际实现的命令**标记为必须，其余标记为可选。
2. 将数据结构中的偏移和长度与 NVMe Spec 版本对齐。
3. 如果项目使用 NVMe over Fabric 或 NVMe 2.0 新特性，在对应章节补充。
4. 只填写 AI 无法从代码推断的隐性知识（规约值、对齐要求、操作顺序）。