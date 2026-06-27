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

## 7. 设计方案确认门禁（五级）

五级门禁的权威定义、校验命令、checklist 和简化豁免规则统一在 `.opencode/skills/sd-firmware-copilot/SKILL.md`。

**流程摘要**：

- **Proposal Gate**（动机 OK）：`/opsx:propose` 完成后 → `openspec validate --strict --changes` 通过 + 人工确认
- **Design Gate**（架构 OK）：design.md + tasks.md 完成后 → 量化指标通过 + 人工确认
- **BUILD Gate**（纪律 OK）：编码前加载 Superpowers skill + 测试计划定义（详见 openspec-apply SKILL.md §BUILD Gate 强制检查）
- **Review Gate**（代码匹配 spec）：编码 + Review 后 → 人工确认
- **Archive Gate**（归档提交）：Review 通过后 → `chore(spec): archive <id>`

### Design Gate 量化指标（硬性要求）

design.md + tasks.md 必须满足以下指标，方可进入 BUILD Gate：

| 指标 | 要求 | 验证方式 |
|------|------|----------|
| CodeGraph 影响分析 | 包含 `codegraph impact` 或 `codegraph where` 结果 | check_change.sh 扫描关键词 |
| 任务粒度 | tasks.md 中 task 数量 3-5 个 | check_change.sh 计数 |
| 任务大小 | 每个 task 预估 ≤ 500 行 | tasks.md 中声明 |
| 测试计划 | 每个 task 明确列出正常/边界/错误路径测试 | tasks.md 中检查 |
| 风险识别 | design.md 包含 `## Risks` 章节 | check_change.sh 检查 |
| blockedBy 无循环 | tasks.md 中 blockedBy 关系无循环依赖 | 人工检查 |

## 8. 设计-实现一致性（**强制**，per `docs/retrospectives/2026-06-add-crt-mapping-cache.md` AP-008）

> 背景：实施过程中可能发现 design.md 的设计假设与实现约束冲突（如性能 / 复杂度 / 已有约束）。如果**先 commit 代码再补 design.md**，会导致审计追踪的 design 与实际实现脱节，未来 reader 据 design 优化时得到错误预期。

### 强制规则

实现过程中如果出现以下任一情况，**必须**先更新 `design.md` 再继续编码：

1. **性能特性变更**：design.md 写 O(1)，实现改为 O(N) → 必须更新
2. **接口签名变更**：design.md 写 `(int, struct ssd *)`，实现改为 `(struct ssd *, int)` → 必须更新
3. **数据布局变更**：design.md 写 hash table，实现改为 B-tree → 必须更新
4. **并发模型变更**：design.md 写 "需要 mutex"，实现发现"单线程" → 必须更新
5. **依赖关系变更**：design.md 假设调用方 A，实现发现 A 不存在 → 必须更新

### 操作步骤

1. **暂停编码**
2. 在 design.md 的对应"Decisions"或"Risks"段添加变更记录：
   ```markdown
   ### Implementation Drift: <title>
   - **原设计**: <what design.md said>
   - **实际实现**: <what code does>
   - **原因**: <why drift happened>
   - **影响**: <what needs to change in spec or downstream>
   ```
3. 同步更新 `specs/<cap>/spec.md`（如有 spec 级别影响）
4. 重新跑 `openspec validate --strict --changes`
5. 继续编码

### 检查清单（每个 task 完成时）

- [ ] design.md "Decisions" 段与当前实现一致？
- [ ] design.md "Risks" 段未忽略新发现的风险？
- [ ] 设计-实现 diff 记录在 `verify-report.md` 的 "设计-实现 diff" 段？

### 反例（AP-008 案例）

`add-crt-mapping-cache/design.md` 描述 CRT lookup 为 O(1) hash table；实现时发现 CRT 是**范围查找**（LPN K 需匹配任意 [start_lpn, start_lpn + n_lpns) 区间），开地址 hash 的"空 slot 终止"语义不适用。实现改为 O(capacity) 全表 scan。**design.md 未更新**留下文档不一致。

正确做法：实施中发现 O(1) 不适用 → 立即更新 design.md "Decisions" 段记录 Implementation Drift，告知 user 性能特性变化 → 继续编码。


**简化豁免**：单文件 bugfix / 文档变更 / 配置变更 / 跨模块变更的处理见 `.opencode/skills/sd-firmware-copilot/SKILL.md`。

---

## §BUILD Gate — 强制编码前纪律检查

本段为硬性约束，不因 session 上下文而豁免。

### 触发条件

**每次编辑任何 `.c` / `.h` 文件前**，AI 必须依次执行以下 3 步：

#### Step 1 — 加载纪律 Skill

```c
skill(name="superpowers-verification-before-completion")   // 完成前必须验证
skill(name="superpowers-executing-plans")                   // 按 tasks.md 顺序执行
skill(name="superpowers-test-driven-development")           // 测试覆盖
```

**缺一不可**。任一缺失 = 流程违规。AI 应在加载完成后声明 "BUILD Gate 通过"。

#### Step 2 — 确认测试计划

在 tasks.md 或 design.md 中确认以下三项之一：

- **正常路径**: 该函数的典型调用场景已定义预期行为
- **边界条件**: 数组边界/空值/最大最小值场景已覆盖
- **错误路径**: 参数错误/资源耗尽/状态异常场景已覆盖

硬件依赖代码（寄存器/DMA/ISR）在 `review.md` 中标注不可测原因，不要求强制测试。

#### Step 3 — 确认 CodeGraph 影响范围

- 修改结构体前：`codegraph symbol_search` + `codegraph find_by_imports`
- 修改函数签名前：`codegraph where <symbol>`
- 新增模块前：`codegraph dependency_graph`

### 违规处理

AI 检测到未过 BUILD Gate 就编码时，应：
1. 立即暂停当前编辑
2. 加载缺失 skill
3. 补充测试计划
4. 恢复编码

---

## §Completion Self-Checklist

在标记任何 task 为 **`- [x]`** 前，AI 必须逐条自查：

- [ ] 本次变更是否涉及 `.c` / `.h` 文件？
  - 是 → BUILD Gate 的 3 个 skill 是否已加载？
  - 否 → 跳过后三项
- [ ] 新增/修改的每个公共函数是否有对应的测试？
  - 硬件依赖路径在 `review.md` 标注了原因？
- [ ] 编译验证: `make clean && make -j$(nproc)` exit 0？
- [ ] 知识图谱: `graphify update` 已执行？
- [ ] bugfix: commit message 或 `review.md` 记录了根因？
- [ ] 跨模块变更: OpenSpec change 的 `proposal.md` + `tasks.md` 已创建？

---

## §OpenSpec Change 门槛

| 场景 | 必须创建 OpenSpec change | 可豁免 |
|------|------------------------|--------|
| 跨模块修改（2+ 个 `.c` 文件） | ✅ | — |
| 新增公共 API / 结构体 | ✅ | — |
| 修改现有接口签名 | ✅ | — |
| 任何重构 | ✅ | — |
| 单文件 bugfix（仅改 1 个 `.c`） | — | ✅ 但 commit 需写根因 |
| 注释/文档/配置变更 | — | ✅ |

豁免时仍需走 BUILD Gate 和 Completion Self-Checklist。