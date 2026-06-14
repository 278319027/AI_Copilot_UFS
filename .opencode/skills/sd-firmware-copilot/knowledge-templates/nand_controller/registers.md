# NAND 控制器知识模板

> 本文件是 SSD 固件项目中 NAND 控制器相关硬件知识的模板。
> 使用时，将具体芯片的寄存器地址、操作序列、时序参数填入。
> 每个文件不超过 2000 行，只包含 AI 无法从代码推断的隐性知识。

## 1. 寄存器定义

### 1.1 控制器基础寄存器

| 偏移地址 | 寄存器名 | 宽度 | 读/写 | 功能描述 |
|----------|----------|------|-------|----------|
| 0x0000 | NAND_CTRL | 32 | R/W | 控制器主控制寄存器 |
| 0x0004 | NAND_STATUS | 32 | R | 控制器状态寄存器 |
| 0x0008 | NAND_INT_STAT | 32 | R/W1C | 中断状态寄存器 |
| 0x000C | NAND_INT_EN | 32 | R/W | 中断使能寄存器 |
| 0x0010 | NAND_CMD | 32 | W | 命令寄存器 |
| 0x0014 | NAND_ADDR | 32 | W | 地址寄存器 |
| 0x0018 | NAND_DATA | 32 | R/W | 数据寄存器 |

### 1.2 配置顺序约束

> **关键：以下配置顺序不可打乱，否则控制器行为未定义。**

1. 使能控制器时钟（NAND_CTRL.CLK_EN = 1）
2. 等待时钟稳定（NAND_STATUS.CLK_RDY == 1）
3. 配置时序参数（NAND_TIM0, NAND_TIM1）
4. 配置 ECC 模式（NAND_ECC_CTRL）
5. 配置 DMA 地址（NAND_DMA_ADDR）
6. 使能中断（NAND_INT_EN）
7. 发起操作（NAND_CMD）

### 1.3 时序约束

| 操作 | 最小时间 | 最大时间 | 单位 |
|------|----------|----------|------|
| 命令到数据 | tADL | — | ns |
| 写入到状态就绪 | tWB | tPROG | µs |
| 擦除到状态就绪 | tWB | tBERS | ms |
| 数据保持 | tR | — | µs |

## 2. NAND 操作序列

### 2.1 页读取（Page Read）

```text
Step 1: NAND_CMD = CMD_READ_PAGE_START
Step 2: NAND_ADDR = row_addr (3 bytes: cycle1, cycle2, cycle3)
Step 3: NAND_CTRL.START = 1
Step 4: 等待 NAND_INT_STAT.RDY_INT == 1
Step 5: NAND_CMD = CMD_READ_PAGE_END
Step 6: 从 NAND_DATA 读取数据
```

> **注意**：Step 1 和 Step 2 之间不得插入其他操作。
> Step 4 必须使用中断或忙等检测，禁止无超时的忙等。

### 2.2 页写入（Page Program）

```text
Step 1: NAND_CMD = CMD_WRITE_START
Step 2: NAND_ADDR = row_addr
Step 3: 向 NAND_DATA 写入数据
Step 4: NAND_CMD = CMD_WRITE_END
Step 5: NAND_CTRL.START = 1
Step 6: 等待 NAND_INT_STAT.RDY_INT == 1
Step 7: 读取 NAND_STATUS 检查写入结果
```

### 2.3 块擦除（Block Erase）

```text
Step 1: NAND_CMD = CMD_ERASE_START
Step 2: NAND_ADDR = block_addr (只发 row 地址，忽略 column)
Step 3: NAND_CMD = CMD_ERASE_END
Step 4: NAND_CTRL.START = 1
Step 5: 等待 NAND_INT_STAT.RDY_INT == 1（可能需要数 ms）
Step 6: 读取 NAND_STATUS 检查擦除结果
```

## 3. 错误处理

| 错误类型 | 状态位 | 恢复策略 |
|----------|--------|----------|
| ECC 不可纠正 | NAND_STATUS.ECC_FAIL | 标记坏块，报告上层 |
| 写入失败 | NAND_STATUS.PROG_FAIL | 重试最多 3 次，仍失败则标记坏块 |
| 擦除失败 | NAND_STATUS.ERS_FAIL | 重试最多 3 次，仍失败则标记坏块 |
| 超时 | 无 RDY_INT | 软复位控制器，重试操作 |

## 4. 填写说明

1. 将上述模板中的寄存器地址、命令码、时序参数替换为**具体芯片的值**。
2. 每个芯片型号一个文件，命名格式：`registers_<chip_model>.md`。
3. 只填写 AI 无法从代码推断的隐性知识（具体地址值、操作顺序、时序参数）。
4. 不需要填写代码可推断的信息（函数签名、数据结构定义）。