# NVMe 命令处理 — 行为基线

> **最后更新**：—
> **最后变更**：—

## 模块概述

- **职责**：接收主机 NVMe 命令，解析、路由、执行、返回响应
- **对外接口**：Submission Queue (SQ) 处理、Completion Queue (CQ) 投递
- **约束**：命令处理必须在 µs 级延时内完成

## 核心数据结构

<!-- TODO: 填充 SQ/CQ 管理结构、PRP/SGL 描述符等 -->

## 行为描述

### Admin 命令处理流程

<!-- TODO: 填充 Identify、Set Features、Create I/O CQ/SQ 等流程 -->

### I/O 命令处理流程

<!-- TODO: 填充 Read、Write、Flush、Compare 等流程 -->

### 错误处理

<!-- TODO: 填充命令超时、PRP 错误、设备错误等路径 -->

## 接口契约

<!-- TODO: 填充公开函数签名、前置/后置条件 -->

## 依赖关系

- 依赖模块：FTL 层（LBA→PBA 映射）、平台抽象层（中断/DMA）
- 被依赖模块：无（最上层）

## 已知限制

<!-- TODO: 填充 QD 限制、队列深度、并发约束等 -->
