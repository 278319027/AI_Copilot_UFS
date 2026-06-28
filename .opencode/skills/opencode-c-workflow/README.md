# opencode-c-workflow 使用手册

> Graph-constrained spec-first C programming workflow.  
> 将 OpenSpec（规范）、CodeGraph/Graphify（结构分析）与 Superpowers（执行纪律）整合为一条安全的 C 代码改动流水线。

---

## 1. 简介

`opencode-c-workflow` 是一个**编排型 skill**。它本身不直接写代码，而是把一次 C 语言改动约束在六阶段流水线里：

```
SCOPE → GROUND → PLAN → PATCH → VERIFY → REPORT
```

**核心原则**：
- **规范先于代码**：动手前先冻结 scope。
- **结构先于源码**：先查依赖图，再读代码。
- **最小改动**：只改 scope 内文件，禁止顺手重构。
- **证据驱动**：声称“完成”前必须有 build/test/diagnostic 证据。

**适用场景**：
- C 代码的 bug 修复、功能新增、重构
- 触及 2 个及以上文件/函数的改动
- 接口/API 变更

**可跳过场景**：单行拼写/注释修改、纯配置文件改动。

---

## 2. 快速开始

```bash
# 1. 确保环境就绪
openspec init
graphify extract .
codegraph build .

# 2. 创建一个 change（在 AI 聊天中输入）
/opsx:propose ufs-write-buffering

# 3. 按六阶段执行：SCOPE → GROUND → PLAN → PATCH → VERIFY → REPORT
```

> **命令说明**：
> - `/opsx:*` 是用户在 AI 助手聊天中输入的 slash command。
> - AI 侧实际通过 `skill(name="openspec-propose")` 等工具调用对应 skill。
> - 任一必需工具缺失或故障，本 workflow **直接停止并报告缺项**，不降级执行。

---

## 3. 前置条件

- 仓库已初始化 OpenSpec：`openspec init`
- 仓库已构建 CodeGraph 数据库：`.codegraph/graph.db` 存在
- 仓库已构建 Graphify 知识图：`graphify-out/graph.json` 存在（可选但强烈建议）
- 已安装相关 skill：openspec-*、superpowers-*

### 工具缺失/故障时的处理

本 workflow **不降级执行**。任一必需工具缺失或故障，立即停止并报告：

| 工具 | 检查方式 | 缺失/故障时的报告 |
|---|---|---|
| OpenSpec | `openspec --version` | "OpenSpec CLI 缺失。请运行 `npm install -g @fission-ai/openspec` 并 `openspec init`。" |
| CodeGraph | `.codegraph/graph.db` 存在且 MCP 可连接 | "CodeGraph 数据库缺失或 MCP 连接失败。请运行 `codegraph build .`。" |
| Graphify | `graphify-out/graph.json` 存在 | "Graphify 知识图缺失。本 workflow 要求先构建图；请运行 `graphify extract .`。" |
| Superpowers skills | `.opencode/skills/superpowers-*/SKILL.md` 存在 | "Superpowers skill 缺失。请确认 .opencode/skills/superpowers-* 目录已安装。" |

---

## 4. 流程概览

| 阶段 | 目的 | 核心产出 |
|---|---|---|
| **SCOPE** | 冻结改动范围 | `scope.files`、约束、验收标准、测试计划 |
| **GROUND** | 理解代码结构 | 依赖图、调用链、影响面、风险函数 |
| **PLAN** | 设计变更方案 | `design.md`、`tasks.md`、内存预算、头文件影响清单 |
| **PATCH** | 安全实施改动 | 最小代码 diff、逐任务 TDD、CI gate |
| **VERIFY** | 证明正确性 | build 通过、测试通过、零新增诊断错误 |
| **REPORT** | 收尾归档 | code review、归档 change、清理工作区 |

---

## 5. 工具链对比与互补

`opencode-c-workflow` 同时依赖四个外部子系统：OpenSpec、Graphify、CodeGraph、Superpowers。它们不是替代品，而是同一流水线上不同层次的工具。

---

### 5.1 CodeGraph vs Graphify：两种“代码图”

两者都把代码变成可查询的图，但抽象层级、数据来源和最佳用途完全不同。

| 维度 | **CodeGraph** | **Graphify** |
|---|---|---|
| **核心抽象** | Code Property Graph（CPG，代码属性图） | Knowledge Graph（知识图） |
| **解析方式** | Tree-sitter 解析 AST + 调用关系，存入 SQLite/duckdb | Tree-sitter 提取 AST/调用图 + LLM 语义提取，生成 `graph.json` |
| **数据粒度** | **函数级** — 精确到每个函数、调用、参数、数据流 | **项目级** — 文件、模块、概念、文档、社区 |
| **强项** | 调用链精确追踪、爆炸半径、复杂度、循环依赖、安全污点分析 | 跨文件关系发现、社区检测、概念解释、文档与代码关联 |
| **典型问题** | “谁调用了 `submit_write`？”“修改它会影响谁？” | “UFS write buffering 涉及哪些文件/概念？” |
| **查询接口** | 149+ 个 MCP 工具：`codegraph_context`、`codegraph_fn_impact`、`codegraph_find_cycles` 等 | CLI：`graphify query`、`graphify path`、`graphify explain` |
| **更新成本** | `codegraph build` — 全量重建 | `graphify update .` — AST-only 增量，无 API 费用 |
| **何时先用** | 已经知道目标函数/文件，需要精确上下文 | 还不清楚从哪入手，需要宏观概念地图 |

**协作模式：Query → Pinpoint → Verify**

```
graphify query "UFS write buffering"          # 宏观：找到相关文件与概念
        ↓
codegraph_context("submit_write")             # 微观：拿到函数源码、调用链
        ↓
codegraph_fn_impact("submit_write", depth=3)  # 验证：确认爆炸半径
        ↓
codegraph_find_cycles()                       # 安全：确认无循环依赖
```

> 详细命令格式见 `references/codegraph-usage.md` 与 `references/graphify-usage.md`；C 项目专属模式已内置于这两个文件。

---

### 5.2 OpenSpec vs Superpowers：规范 vs 执行纪律

| 维度 | **OpenSpec** | **Superpowers** |
|---|---|---|
| **本质** | 规范驱动开发（Spec-Driven Development）框架 | 代理执行纪律与方法论框架 |
| **产出物** | `proposal.md`、`specs/`、`design.md`、`tasks.md`、`.openspec.yaml` | 一系列可组合 skill：TDD、debug、review、worktree、plan-writing 等 |
| **核心问题** | “我们要做什么？为什么做？做到什么标准？” | “如何高质量地把它做出来？” |
| **工作方式** | 通过 `/opsx:*` slash command 与 CLI 管理 change 生命周期 | 通过 `skill(name="...")` 加载具体 skill |
| **主要命令** | `/opsx:explore`、`/opsx:propose`、`/opsx:apply`、`/opsx:archive` | `skill(name="superpowers-test-driven-development")`、`skill(name="superpowers-systematic-debugging")` |
| **关注点** | scope、需求、设计、任务拆分、版本化归档 | TDD、子代理、工作区隔离、系统调试、代码审查 |
| **失败防护** | scope 冻结、验收标准、设计评审 | RED-GREEN-REFACTOR、两阶段 review、证据验证 |

**关键区别**：
- **OpenSpec 是“做什么”的容器**：它保存需求、设计、任务清单，确保代理不会偏离目标。
- **Superpowers 是“怎么做”的教练**：它约束执行过程，确保代理以正确的方式（TDD、子代理、worktree、review）完成任务。

---

### 5.3 四者在本项目中的互补关系

把一次 C 代码改动想象成盖房子：

| 工具 | 角色 | 在盖房子中的类比 |
|---|---|---|
| **OpenSpec** | 建筑师 + 合同 | 画蓝图、签范围合同、列验收清单 |
| **Graphify** | 地图 | 告诉你这块地在哪、周围有什么、交通如何 |
| **CodeGraph** | 地质勘探 + 结构计算 | 精确到每根钢筋、每颗螺丝的承重分析 |
| **Superpowers** | 施工队 + 监理 | 按规范施工、逐道工序验收、质量把关 |

**在 `opencode-c-workflow` 中的阶段分工**：

```
SCOPE   → OpenSpec（定义 change、scope、验收标准）
            ↓
GROUND  → Graphify（宏观找相关概念/文件）
            ↓
          CodeGraph（微观分析函数调用链与风险）
            ↓
PLAN    → OpenSpec（产出 design.md / tasks.md）
        + Superpowers-writing-plans（评审计划）
        + CodeGraph（头文件影响、复杂度检查）
            ↓
PATCH   → Superpowers-TDD（RED-GREEN-REFACTOR）
        + Superpowers-worktrees（隔离工作区）
        + OpenSpec /opsx:apply（按任务清单实施）
        + CodeGraph check（CI gate）
            ↓
VERIFY  → make / make test
        + lsp_diagnostics
        + CodeGraph diff-impact
        + Superpowers-verification-before-completion
        + Graphify update（刷新知识图）
            ↓
REPORT  → Superpowers-requesting-code-review
        + OpenSpec /opsx:archive
        + Superpowers-finishing-a-development-branch
```

**为什么要四者缺一不可？**

1. **仅有 OpenSpec，没有图工具**：代理会按规范做，但可能读错文件、漏看调用者，导致接口破坏。
2. **仅有 Graphify/CodeGraph，没有 OpenSpec**：代理知道代码结构，但不知道“要做什么”，容易顺手重构或做偏。
3. **仅有 Superpowers，没有 OpenSpec/图**：有执行纪律，但缺少范围约束和结构指引，容易在错误的道路上走得很快。
4. **四者结合**：规范定方向、图工具指结构、Superpowers 保执行质量，形成闭环。

---

## 6. 全流程教程：新增 UFS Write Buffering 功能

以下以**“为 UFS 控制器新增 Write Buffering（写缓冲）功能”**为例，演示如何走完六阶段。

> 背景：UFS 控制器当前每次 host write 直接落盘，性能差。需要引入一个 SRAM 写缓冲区，凑够一个 block 再下发 NAND program。

---

### Phase 1: SCOPE — 定义改什么

**目标**：冻结 scope，明确“做”与“不做”。

#### 步骤 1.1：澄清意图

如果需求模糊，先调用 brainstorming：

```
skill(name="superpowers-brainstorming")
用户：我想给 UFS 加个写缓冲，提升写性能。
```

**关键澄清问题**：
- 缓冲多大？（SRAM 只有 3MB，不能全吃掉）
- 缓冲策略？（write-back vs write-through）
- 掉电保护？（缓冲数据是否需 SPOR 恢复）
- 是否影响现有 read path？（read 命中缓冲怎么处理）

**澄清后 scope**：
- 在 Core0 FTL 层增加 256KB SRAM 写缓冲
- 策略：write-back，满 block 刷盘
- 掉电：缓冲数据随 meta_flush 持久化到 NAND
- read path：先查缓冲，miss 再走 LUT

#### 步骤 1.2：创建 Change

```bash
openspec new change "ufs-write-buffering"
```

或直接用 propose：

```
/opsx:propose ufs-write-buffering
```

#### 步骤 1.3：获取 enriched instructions

```bash
openspec instructions proposal --change "ufs-write-buffering" --json
openspec instructions tasks --change "ufs-write-buffering" --json
```

#### 步骤 1.4：冻结 scope

在 `proposal.md` 中明确：

```markdown
## Scope

### In Scope
- `src/ftl/write_buffer.c` — 新文件，缓冲管理核心
- `src/ftl/host_write.c` — 修改，host write 先查缓冲
- `src/ftl/host_read.c` — 修改，read 先查缓冲
- `src/ftl/meta_flush.c` — 修改，flush 时刷缓冲到 NAND
- `src/include/write_buffer.h` — 新头文件，公共 API

### Out of Scope
- GC 策略修改（缓冲满导致的额外 GC 在 Phase 2 评估）
- SPOR 完整重建逻辑（假设 meta_flush 已覆盖）
- 性能基准测试（后续独立 change）

### Constraints
- 缓冲大小 ≤ 256KB（SRAM 预算）
- 不对现有 LUT/RLUT 数据结构做 breaking change
- 所有新增代码遵循 C99 + MISRA

### Acceptance Criteria
- [ ] `make` 编译通过，零 warning
- [ ] `make test` 全部通过
- [ ] 单线程顺序写性能提升 ≥ 20%
- [ ] 掉电后数据不丢失（SPOR 验证）
```

**Hard stop**：如果此时 scope 仍模糊，禁止进入 Phase 2。

---

### Phase 2: GROUND — 先图后码

**目标**：通过图工具理解依赖结构，再读源码。

**Graph-first rule**：只要 `graphify-out/graph.json` 存在，必须先查图再读源码。

#### 步骤 2.1：宏观视图（Graphify）

```bash
graphify query "UFS write buffering SRAM cache block" --budget 1500
```

**预期输出**：
- 相关文件：`host_write.c`、`host_read.c`、`meta_flush.c`
- 相关概念：SRAM 分配、block 对齐、flush 策略
- 社区检测：这些文件属于哪个模块集群

#### 步骤 2.2：关系检查（Graphify）

```bash
graphify path "Host Write" "NAND Program"
```

**目的**：确认 host write 到 NAND program 的现有路径，找到插入缓冲的最佳位置。

#### 步骤 2.3：节点深潜（Graphify）

```bash
graphify explain "Write Buffer"
```

如果概念不存在，检查相近概念：

```bash
graphify explain "SRAM"
graphify explain "Block Flush"
```

#### 步骤 2.4：微观视图（CodeGraph）

```bash
codegraph_context("submit_write")
```

**预期输出**：
- `submit_write` 的完整源码
- 调用者列表（谁调用了 `submit_write`）
- 被调用者列表（`submit_write` 调用了谁）
- 依赖的头文件

#### 步骤 2.5：爆炸半径（CodeGraph）

```bash
codegraph_fn_impact("submit_write", depth=3)
```

**目的**：确认修改 `submit_write` 会影响多少函数。如果影响面超出 scope，停止并重新定界。

#### 步骤 2.6：安全检查（CodeGraph）

```bash
codegraph_find_cycles()
```

**目的**：检查 `host_write.c` 与 `meta_flush.c` 之间是否会因新增缓冲管理引入循环依赖。

#### 步骤 2.7：复杂度检查（CodeGraph）

```bash
codegraph_complexity(above_threshold=true)
```

**目的**：识别当前复杂度最高的函数。如果 `host_write.c` 中已有函数接近 100 行/复杂度 15，考虑拆分。

#### 步骤 2.8：语义搜索（CodeGraph）

```bash
codegraph_semantic_search("buffer allocation SRAM")
```

**目的**：查找项目中是否已有类似的缓冲区分配模式，避免重复造轮子。

**Ground 阶段产出**：
- 受影响文件清单（与 scope 对比，确认无遗漏）
- 关键函数清单：`submit_write`、`submit_read`、`meta_flush`、`gc_collect`
- 风险点：SRAM 预算紧张、flush 路径可能变长
- 设计约束：不能破坏现有 LUT/RLUT 一致性

**Hard stop**：
- 图的证据与 scope 矛盾 → 停止并解决。
- 有 Graphify 数据但未使用 → 停止。

---

### Phase 3: PLAN — 设计变更

**目标**：明确到具体文件、函数、验证命令。

#### 步骤 3.1：编写 design.md

在 change 目录下创建 `design.md`：

```markdown
# Design: UFS Write Buffering

## Data Structures

```c
typedef struct {
    uint8_t  data[WRBUF_SIZE];   // 256KB
    uint32_t lpaa[WRBUF_PAGES];  // 每页对应的 LPAA
    uint16_t valid_bitmap;       // 哪些槽位有效
    uint8_t  dirty;              // 是否有脏数据
} WriteBuffer_t;
```

## Algorithm

1. Host write → 查 LUT 得 LPAA → 查 WriteBuffer
2. Buffer hit → 直接写入 buffer，标记 dirty
3. Buffer miss & buffer 未满 → 写入 buffer 空闲槽位
4. Buffer miss & buffer 满 → flush buffer 到 NAND → 写入新数据
5. Read → 先查 buffer，miss 再走 LUT

## Interface Changes

- `fe_ftl_interface.h`: 无变化（对外接口不变）
- 新增 `write_buffer.h`:
  - `wbuf_init()`
  - `wbuf_write(lpaa, data)`
  - `wbuf_read(lpaa, data)`
  - `wbuf_flush()`

## ISR / Hot Path Impact

- `wbuf_write()` 在 Core0 FTL 上下文调用，非 ISR
- `wbuf_flush()` 可能延长 meta_flush 时间，需 watchdog 意识
```

#### 步骤 3.2：编写 tasks.md

```markdown
# Tasks: UFS Write Buffering

- [ ] Task 1: 创建 `src/include/write_buffer.h` — 定义 WriteBuffer_t 和 API
  - Verification: `gcc -fsyntax-only src/include/write_buffer.h`

- [ ] Task 2: 创建 `src/ftl/write_buffer.c` — 实现 wbuf_init/write/read/flush
  - Verification: 单元测试 `UT/test_write_buffer.c` 通过

- [ ] Task 3: 修改 `src/ftl/host_write.c` — submit_write 先查 wbuf
  - Verification: `make test_superblock_write` 通过

- [ ] Task 4: 修改 `src/ftl/host_read.c` — submit_read 先查 wbuf
  - Verification: read hit buffer 时数据正确

- [ ] Task 5: 修改 `src/ftl/meta_flush.c` — flush 时调用 wbuf_flush
  - Verification: SPOR 后数据不丢失

- [ ] Task 6: 集成测试 — 顺序写/随机写/混合读写
  - Verification: `make run-test-dual` 通过，性能提升 ≥ 20%
```

#### 步骤 3.3：头文件影响分析

```bash
codegraph_file_deps("src/include/write_buffer.h")
```

**预期**：确认只有 `host_write.c`、`host_read.c`、`meta_flush.c`、`write_buffer.c` 包含此头文件。

#### 步骤 3.4：内存预算

- WriteBuffer_t：256KB data + ~2KB metadata = **258KB**
- 当前 SRAM 使用：从 `docs/` 或 `config.h` 查询
- 剩余 SRAM 预算：确认 ≥ 258KB，否则缩小缓冲

#### 步骤 3.5：预飞检查

```bash
codegraph_diff_impact(staged=true)
```

此时 staged 为空，检查当前工作区状态是否干净。

#### 步骤 3.6：计划评审

```
skill(name="superpowers-writing-plans")
评审 tasks.md：任务是否可并行？验证项是否充分？
```

**Hard stop**：计划范围超出原始 scope → 重新定界或拒绝。

---

### Phase 4: PATCH — 安全实施

**目标**：最小改动、逐任务验证。

#### 步骤 4.1：隔离工作区

```
skill(name="superpowers-using-git-worktrees")
```

或手动：

```bash
git worktree add ../ufs-write-buffering-wip
```

#### 步骤 4.2：应用任务

```
/opsx:apply ufs-write-buffering
```

或逐任务手动执行。

#### 步骤 4.3：逐任务 TDD

以 **Task 2**（实现 write_buffer.c）为例：

```c
// UT/test_write_buffer.c
#include "write_buffer.h"
#include <assert.h>

void test_wbuf_write_read(void) {
    wbuf_init();
    uint8_t data[PAGE_SIZE] = {0xAB};
    wbuf_write(42, data);
    
    uint8_t out[PAGE_SIZE] = {0};
    int rc = wbuf_read(42, out);
    assert(rc == 0);
    assert(out[0] == 0xAB);
}

int main(void) {
    test_wbuf_write_read();
    printf("PASS\n");
    return 0;
}
```

编译运行：

```bash
gcc -o ut_wbuf UT/test_write_buffer.c src/ftl/write_buffer.c src/common/*.c -I src/ -DUNIT_TEST
./ut_wbuf
```

**RED → GREEN → REFACTOR**：
1. 先写测试（此时 `write_buffer.c` 为空或 stub，测试应 fail）
2. 实现最小代码使测试 pass
3. 重构（如有需要），保持测试 pass

#### 步骤 4.4：CI Gate

每完成一个任务：

```bash
codegraph_check(staged=true)
```

检查：
- 无循环依赖引入
- 复杂度未超标
- 无未使用符号

#### 步骤 4.5：爆炸半径复核

```bash
codegraph_diff_impact(staged=true)
```

确认 diff 只触及 scope 内文件。

**Hard stop**：patch 触及 scope 外文件 → revert 并重新定界。

---

### Phase 5: VERIFY — 证明正确性

**目标**：没有证据就不能声称完成。

#### 步骤 5.1：构建

```bash
make clean && make
```

**预期**：零 error，零 warning。

#### 步骤 5.2：运行测试

```bash
make test-all
make run-test-dual
```

**预期**：全部通过。

#### 步骤 5.3：诊断

```bash
lsp_diagnostics(src/ftl/write_buffer.c)
lsp_diagnostics(src/ftl/host_write.c)
lsp_diagnostics(src/ftl/host_read.c)
lsp_diagnostics(src/ftl/meta_flush.c)
```

**预期**：零新增 error/warning。

#### 步骤 5.4：回归检查

```bash
codegraph_diff_impact(staged=true)
```

确认：
- 无新增调用者被破坏
- 无意外耦合引入

#### 步骤 5.5：刷新图

```bash
graphify update .
```

更新知识图，使后续改动基于最新结构。

#### 步骤 5.6：完成验证

```
skill(name="superpowers-verification-before-completion")
```

确认：
- [ ] 所有 tasks.md 任务已完成
- [ ] build 通过
- [ ] 测试通过
- [ ] 诊断干净
- [ ] 回归检查通过

---

### Phase 6: REPORT — 收尾归档

#### 步骤 6.1：Code Review

```
skill(name="superpowers-requesting-code-review")
```

生成 review package，包括：
- diff 摘要
- 设计决策说明
- 测试覆盖报告

#### 步骤 6.2：归档

```
/opsx:archive ufs-write-buffering
```

将 change 目录移动到 `openspec/changes/archive/YYYY-MM-DD-ufs-write-buffering/`。

#### 步骤 6.3：清理

```
skill(name="superpowers-finishing-a-development-branch")
```

- 合并到主分支
- 删除 worktree
- 更新 CHANGELOG

---

## 7. 硬规则（Hard Rules）

### 架构纪律
- **不投机性重构**：只改 scope 要求的内容。
- **不发明新架构**：遵循现有模式。
- **不编辑 scope 边界外文件**：scope 冻结后具有约束力。
- **所有类型转换显式**：禁止隐式转换。

### 图纪律
- **Graphify 存在则先用**：禁止在查图前浏览源码。
- **CodeGraph 可用则 pre-flight**：每次 commit 前检查循环依赖 + 爆炸半径。
- **图与规范冲突时停止**：解决后方可继续。

### C 语言纪律
- **ISR 内零分配**：静态分配或内存池。
- **禁止递归**：栈深度受硬件限制。
- **所有 `switch` 必须有 `default`**：MISRA 要求。
- **整数类型显式**：使用 `uint32_t`、`int16_t` 等，禁止裸 `int`/`long`。
- **ISR 最小化**：仅设标志/推队列，禁止分配/长循环/阻塞/printf。
- **DMA 缓冲区 cache-line 对齐**：`__attribute__((aligned(64)))`。
- **公共头文件变更需头文件影响评审**：列出所有消费者。

### 测试纪律
- **强制 TDD**：先写测试，看失败，再实现。
- **每个 bug 修复附带回归测试**：先复现 bug，再修复。
- **优先 host-side 模拟**：上硬件前先跑通。

---

## 8. 工具速查表

> 每个工具的详细调用格式、参数说明、返回解读见 `references/*-usage.md`。

### OpenSpec

| 命令 | 用途 |
|---|---|
| `openspec new change "<name>"` | 创建新 change |
| `openspec status --change "<name>" --json` | 查看 change 状态 |
| `openspec instructions <artifact> --change "<name>" --json` | 获取 artifact 指令 |
| `/opsx:explore` | 进入探索模式 |
| `/opsx:propose <name>` | 一键生成 proposal + design + tasks |
| `/opsx:apply <name>` | 按 tasks.md 实施 |
| `/opsx:archive <name>` | 归档 change |

### Graphify

| 命令 | 用途 |
|---|---|
| `graphify query "<concept>" --budget 1500` | 概念搜索 |
| `graphify path "<A>" "<B>"` | 两点最短路径 |
| `graphify explain "<concept>"` | 节点深潜 |
| `graphify update .` | 增量更新（AST-only，免费） |

### CodeGraph MCP

| 命令 | 用途 | 阶段 |
|---|---|---|
| `codegraph_context("<func>")` | 函数上下文（源码+调用链） | GROUND |
| `codegraph_fn_impact("<func>", depth=3)` | 爆炸半径 | GROUND / PLAN |
| `codegraph_find_cycles()` | 循环依赖检测 | GROUND / PATCH |
| `codegraph_complexity(above_threshold=true)` | 高风险函数 | GROUND / PLAN |
| `codegraph_check(staged=true)` | CI gate | PATCH |
| `codegraph_diff_impact(staged=true)` | diff 影响分析 | PLAN / VERIFY |
| `codegraph_semantic_search("<concept>")` | 语义搜索 | GROUND |
| `codegraph_file_deps("<header>")` | 头文件消费者 | PLAN |

### Superpowers

| Skill | 用途 | 阶段 |
|---|---|---|
| `superpowers-brainstorming` | 需求澄清 | SCOPE |
| `superpowers-writing-plans` | 计划评审 | PLAN |
| `superpowers-test-driven-development` | TDD 执行 | PATCH |
| `superpowers-using-git-worktrees` | 工作区隔离 | PATCH |
| `superpowers-verification-before-completion` | 完成验证 | VERIFY |
| `superpowers-requesting-code-review` | 代码审查 | REPORT |
| `superpowers-finishing-a-development-branch` | 分支收尾 | REPORT |

---

## 9. 常见问题

### Q1: 没有 Graphify 数据怎么办？

先构建：

```bash
graphify extract /path/to/project
```

如果项目很大，可以先用 CodeGraph 做函数级分析，Graphify 后续补充。

### Q2: CodeGraph 数据库过时了怎么办？

```bash
codegraph build /path/to/project
```

或增量更新（如果支持）。

### Q3: OpenSpec 没有初始化怎么办？

```bash
openspec init
```

### Q4: 某个任务太大，怎么拆分？

在 `tasks.md` 中将大任务拆为多个子任务，每个子任务有独立验证项。如果拆分后超出原始 scope，需回到 Phase 1 重新定界。

### Q5: patch 阶段发现设计有问题怎么办？

停止实施，回到 Phase 3 更新 `design.md` 和 `tasks.md`。禁止边改边想。

### Q6: 如何并行执行多个独立任务？

```
skill(name="superpowers-dispatching-parallel-agents")
```

把无依赖的任务分配给多个子 agent 并行执行。

---

## 10. 文件结构

```
opencode-c-workflow/
├── SKILL.md                          # 主 skill 定义
├── README.md                         # 使用手册
└── references/
    ├── workflow.md                   # 执行顺序、硬停止条件与 Quick Checklist
    ├── openspec-usage.md             # OpenSpec 调用指南
    ├── codegraph-usage.md            # CodeGraph MCP 调用指南
    ├── graphify-usage.md             # Graphify CLI 调用指南
    ├── superpowers-usage.md          # Superpowers skill 调用指南
    └── c-rules.md                    # C 语言约束（MISRA、内存、ISR）
```
