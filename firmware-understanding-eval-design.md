# 固件代码理解度评估系统 — 详细设计文档

> 版本：v1.5 ｜ 适用环境：公司内网（全离线）｜ 被测对象：opencode 工具链系统（COMET+Superpowers+codegraph/graphify/openviking）
> 目标代码库：**UFS 固件仓库**（C 语言，Unity/Ceedling 单测基础设施）
> 设计依据：SWE-bench 机制、SWE-Explore 检索评估、RepoMirage 扰动诊断（详见附录 A 参考文献）

---

## 1. 背景与评估目标

### 1.1 为什么不能直接用通用基准

| 通用基准 | 不适用的原因 |
|---|---|
| HumanEval / MBPP / CodeMMLU | 评估"模型"，不是"agent+代码库"组合；C 覆盖率低；函数级碎片，无仓库上下文 |
| CRUXEval | 纯 Python；不涉及跨文件、寄存器、条件编译等固件特性 |
| 公共 SWE-bench | Python 仓库为主；**无法出内网提交评估**；无固件构建链 |
| 商业评测服务 | 数据必须留在内网，不可用 |

因此采用**自建数据集 + 本地执行判定**的路线：从你们自己的 git 历史构造任务，在 Docker 内用 Ceedling 跑真实测试判定，全程零外联。

### 1.2 "理解"的可操作化定义（v2.0 — 本系统理论核心）

> 设计原则：**理解是潜在构念（latent construct），不可直接观测**。任何"理解"得分都必须由"需要理解才能完成的行为任务"的证据推定，并经过对抗性对照检验——凡"不需要理解也能完成"的任务一律不得计入得分（CRUXEval 的核心教训：HumanEval 高分 ≠ 理解强）。

#### 1.2.1 构念定义

> **定义**：Agent 对代码库 C 的"理解度" = 它在**一组经判别有效性设计、理解需求强度达标（S2/S3）的行为任务**上的综合表现，由 **结果正确性 × 过程证据 × 扰动鲁棒性** 三通道证据共同推定。

推论（贯穿全系统的硬约束）：
1. 任务必须先证明"理解是完成它的必要条件"，否则不能测理解（§1.2.4）
2. 任何"理解"结论必须能被对抗性对照推翻——decoy/扰动下表现崩塌 ⇒ 此前高分是捷径而非理解（§1.2.6）

#### 1.2.2 双轴分解：认知操作 × 知识对象

原 D1-D6 的缺陷：把"做什么"（认知操作）与"理解什么"（知识对象）混在同一根轴上，且漏掉了固件关键的契约修改、资源安全、执行预测、状态诊断。改为**正交双轴**，任意"理解单元" = (操作, 对象) 交叉点：

**轴 A — 认知操作谱系 O**（按认知深度递进）：

| 编号 | 操作 | 定义 | 认知要求 |
|---|---|---|---|
| O1 | 定位 Locate | 找到相关代码区域 | 最浅；是其他操作的前提 |
| O2 | 追踪 Trace | 沿调用链/数据流/依赖链/配置展开 | 跨文件、多跳 |
| O3 | 预测 Predict | 预测执行结果/行为/副作用 | 执行语义理解 |
| O4 | 解释 Explain | 用自然语言表达行为与设计意图 | 要求可沟通的表征 |
| O5 | 诊断 Diagnose | 由症状反推根因 | 反向推理，需完整因果模型 |
| O6 | 修改 Modify | 做出正确且影响受限的修改 | 综合应用，最高理解证据 |

**轴 B — 知识对象谱系 K**（**已按 UFS 固件特化**，7 类）：

> 目标代码库为 UFS 固件，本轴由通用固件对象实例化为 **UFS 域对象**。所有"理解单元"均以 UFS 术语定义，保证任务构造可直接落到仓库代码（UPIU/CDB/L2P/GC/掉电保护等）。

| 编号 | 对象（UFS 特化） | UFS 固件问题示例 |
|---|---|---|
| K1 | 协议与命令契约 | UPIU 格式、CDB 解析、descriptor/attribute/flag 语义、sense 数据、任务管理命令、vendor 命令；pre/post 条件与错误码 |
| K2 | 结构与依赖 | 模块划分（host 接口/命令调度/FTL/GC/掉电保护/安全）、NAND 与 controller HAL 抽象层、头文件依赖链 |
| K3 | 控制流与状态机 | 命令队列状态机、电源模式转换（Active/Sleep/DeepSleep/PowerDown）、后台任务（GC/read reclaim）调度、中断→完成路径、看门狗复位路径 |
| K4 | 数据与状态 | L2P 映射表、坏块表、GC/wear-leveling 统计、WriteBooster/SLC 写缓冲状态、掉电恢复现场 |
| K5 | 构建与配置 | NAND 厂商/die 配置矩阵、容量 SKU、特性开关（WriteBooster/secure boot/低功耗）、F/W 分区链接脚本、启动序列 |
| K6 | 硬件与时序 | NAND 接口时序、ECC/read-retry、命令门铃寄存器、DMA 描述符、热节流、**性能敏感路径**（命令合并/批处理/预取） |
| K7 | 资源与生命周期 | 命令请求/缓冲所有权、DMA 缓冲生命周期、中断上下文安全、掉电保存/恢复顺序、GC 与读写并发下的缓冲所有权 |

#### 1.2.3 精选测量网格（每轮评估的固定单元集）

全网格 6×7=42 单元不可全测；按**固件高价值 × 可自动化**精选 11 个单元为默认网格（增删需进 changelog 以保历史可比）：

| 单元 | UFS 代表任务示例 | 主测量层 |
|---|---|---|
| (O1,K1) | "READ 命令从 UPIU 接收到完成响应的处理代码在哪" | L1 |
| (O1,K5) | "容量 SKU A 的坏块保留区配置在哪编译生效" | L1 |
| (O2,K2) | "修改 GC 触发策略会影响哪些上层调用方" | L1/L3 |
| (O2,K3) | "命令超时→错误恢复的完整调用链" | L1/L3 |
| (O3,K3) | "队列深度=32 时门铃处理后的命令状态是什么" | L3 |
| (O3,K6) | "该写命令对后台 GC 时序/性能路径的影响" | L3 专项 |
| (O4,K2) | "用自然语言解释 L2P 映射表更新流程的结构与职责" | L1 辅助（judge/人工抽样） |
| (O5,K3) | "症状：特定命令持续超时 → 定位根因" | L1/L2 |
| (O5,K4) | "症状：掉电恢复后 L2P 不一致 → 定位状态保存 bug" | L2 |
| (O6,K1) | "修复命令超时问题，不破坏 UPIU/响应契约" | L2 |
| (O6,K7) | "修复 DMA 缓冲越界，不引入中断上下文竞态" | L2 |

**组件主力映射**（v1.5，用于归因预期）：(O1,K1)→codegraph；(O1,K5)→codegraph+graphify；(O2,K2)→codegraph+graphify；(O2,K3)→codegraph；(O3,*)→模型推理（工具弱相关）；(O4,K2)→graphify；(O5,*)→codegraph+graphify；(O6,*)→codegraph（影响面）。§4.7 消融实测值将与这些预期对照——预期主力却无贡献 ⇒ 工具集成失效或 agent 不会用。

#### 1.2.4 理解需求强度（任务筛选与加权）

每个任务标注强度 S，决定其**能否计入理解得分**：

| 强度 | 含义 | 能否测理解 |
|---|---|---|
| S0 | 表面线索可直接解出（语义无关，如文件名即答案） | **不能** — 作"捷径检出对照" |
| S1 | 单跳引用（直接符号查找） | 基线对照，弱证据 |
| S2 | 多跳 / 跨文件整合 | ✅ 理解证据 |
| S3 | 抽象归纳（契约 / 设计意图 / 反事实推理） | ✅ 最强理解证据 |

- **理解得分 = 仅 S2/S3 任务的加权平均**（S3 权重更高）；S1 单独报告作基线；S0 汇总为"捷径依赖率"。
- 任务构造时显式对抗泄漏：描述中移除文件名/符号名（§3.3），S0 类任务刻意制造"表面像、答案不同"的陷阱。

#### 1.2.5 三通道证据（每单元的三个测量面）

| 通道 | 测什么 | 指标举例 |
|---|---|---|
| 结果正确性 | 任务是否做对 | 定位命中、%Resolved、预测正确率 |
| 过程证据 | 轨迹是否体现理解（先读对再改对） | 编辑前读文件命中率、FUH、工具调用顺序 |
| 扰动鲁棒性 | 语义保持扰动下是否仍对 | URI（§6.3） |

**判定原则**：单通道高分不足为凭；"结果对 + 过程对 + 扰动后仍对"三通道一致，才认定该单元理解成立。

#### 1.2.6 判别有效性设计（防"假理解"）

每个单元配套：
1. **Decoy 对照**：表面相似、语义不同的陷阱任务（如变量名相似但功能无关的两个函数）
2. **扰动对照**：语义保持扰动（§6.1）
3. **捷径依赖率** = Agent 在 S0/decoy 任务上的"成功"比例。该值 >30% 即警告：模型在靠记忆/检索捷径答题，主得分可信度须下调并在报告中标注

#### 1.2.7 效度验证程序（v1.4 去循环论证版，季度报告）

> v1.3 缺陷：判别效度"扰动差太小⇒任务强度不足"与被测 agent 表现耦合——agent 鲁棒就降级任务、脆弱就验证成立，**任何结果都通过，不可证伪**。v1.4 改为：**任务集有效性在入库时用固定参考对象预校准，与被测 agent 解耦**；被测 agent 的得分只是测量值。

| 效度 | 检验方法（v1.4） | 合格线 |
|---|---|---|
| 任务集判别效度（入库预校准） | 用**固定参考集**（BM25 + 固定参考模型，与 §3.2 难度预校准同一对象）在扰动前后各跑任务集一遍 | 参考集 URI ≥ 0.15 才入库（证明扰动确实制造理解困难）；不达标任务族改版或剔除 |
| 收敛效度 | 升级为**因果链实验**（§5.7）：L2 三条件 seed 对比 | seed 组 vs no-seed 组解析率提升经 McNemar 检验显著 |
| 判别效度（被测 agent） | 被测 agent 的 URI 仅作测量值，不回灌任务集有效性判定 | —（消除循环） |
| 预测效度 | 抽样 **≥30** 个未入库真实 issue，评估总分 vs 实际解析率 | Kendall τ ≥ 0.5 |

效度不合格的单元/任务族进入淘汰或改版队列——**定义随证据迭代，而非一成不变**。

> **评估结论** = Σ(单元得分)，单元得分 = g(结果正确性, 过程证据, 扰动鲁棒性)，仅由 S2/S3 任务计算，经判别有效性对照校准；最终呈现为"对象 × 操作 × 强度 × 通道"的能力画像。

### 1.3 被测系统定义（v1.5：单体 agent → 工具链系统）

> 原设计被测主体是"单体 opencode agent"。实际方案是**多组件工具链系统**，理解能力分布在组件中。评估必须回答的新问题：**每个组件对"理解"贡献了多少？**（组件归因 / 消融）

**被测系统结构**：

| 层 | 组件 | 角色 | 覆盖知识对象 | 主要操作 |
|---|---|---|---|---|
| 编排层 | COMET **Classic 全流程** | 五阶段状态机（open→design→build→verify→archive）+ 相位守关 | 需求/规格/设计/任务 | O4 解释、O6 修改（规划） |
| 方法论层 | Superpowers 技能 | brainstorming、TDD、subagent 分发、code review | 方法与流程合规 | — |
| 符号结构层 | **codegraph**（已接入，主力检索） | AST 知识图谱：调用链/影响面/跨文件跳转 | K1 契约、K2 依赖、K3 调用链 | O1 定位、O2 追踪 |
| 语义图谱层 | **graphify**（MCP serve 查代码图） | 语义图：实体/关系/社区/god nodes | K2 架构、K3 关系、K4 概念 | O1/O2、O4 解释 |
| 记忆层 | **openviking**（仅 MCP 手动） | viking:// 上下文文件系统 + 语义检索 + 记忆蒸馏 | 跨会话经验（各 K 的经验形态） | 经验复用 |

**对比轴**（报告必含）：`模型 × 工具链配置 × 工作流模式`。工作流模式固定为 Classic 全流程（避免又一个变量）；模型与工具链配置可变。

**默认消融分组矩阵**（评估配置，见 §4.7）：

| 组 | codegraph | graphify | openviking | 用途 |
|---|---|---|---|---|
| no-tool | ✗ | ✗ | ✗ | 基线（仅 grep/read） |
| cg | ✓ | ✗ | ✗ | codegraph 单独贡献 |
| gfy | ✗ | ✓ | ✗ | graphify 单独贡献 |
| ov | ✗ | ✗ | ✓ | openviking 单独贡献 |
| full | ✓ | ✓ | ✓ | 全工具链（生产配置） |

---

## 2. 系统架构总览

```
┌─────────────────────────────────────────────────────────────┐
│                     git 历史挖掘流水线                        │
│  mine_commits → filter → build_dataset → verify_baseline     │
└──────────────┬──────────────────────────────────────────────┘
               ▼
        ┌─────────────┐    ┌─────────────┐    ┌─────────────┐
        │  Layer 1    │    │  Layer 2    │    │  Layer 3    │
        │ 定位理解评估 │    │ 端到端修复评估│    │ 扰动诊断评估 │
        │  每周        │    │  每月        │    │  每季度      │
        └──────┬──────┘    └──────┬──────┘    └──────┬──────┘
               └─────────┬────────┴────────┬─────────┘
                         ▼                 ▼
                 ┌──────────────┐   ┌──────────────┐
                 │  评分模块     │   │  报告/看板    │
                 │ retrieval/   │   │ 能力矩阵+趋势 │
                 │ resolve/     │   │ +回归检测     │
                 │ robustness   │   │              │
                 └──────────────┘   └──────────────┘
```

**被测主体**：**工具链系统**（v1.5）= opencode(harness) + COMET-Classic(编排) + Superpowers(方法论) + codegraph/graphify/openviking(理解工具)。对比必须**同 harness、同 prompt、同预算、同工具链配置（含索引状态）**，否则数字不可比（附录 A 的 Scaffold Effect 研究证明 harness 可造成 40× token 差异）。

---

## 3. 数据层：git 历史挖掘流水线

所有层的任务都来自这里，**只用历史数据、永不外传**。

### 3.0 数据流与三层复用（先看这张图）

```
git 历史挖掘 → 任务库（问题描述 + gold 代码区域 + F2P/P2P 测试 + unit/demand 标注）
                    │
        ┌───────────┼───────────┐
        ▼           ▼           ▼
      L1 定位      L2 修复      L3 扰动诊断
   （只找不修）  （完整修复）   （扰动版复跑）
   测"知不知道  测"能不能    测"真理解还是
     在哪"       修对"         背答案"
      │           │            │
      └───────────┴────────────┘
              能力矩阵（§8 看板）
```

**同一个任务被三层复用，但各测一个维度：**

| 层 | 用同一任务做什么 | 回答的问题 | 证据通道（§1.2.5） |
|---|---|---|---|
| L1 | 只让 agent 定位相关代码（禁止编辑） | 它**知道 bug 在哪**吗 | 过程证据 |
| L2 | 让 agent 产出补丁，Ceedling 执行判定 | 它**能修对**吗（%Resolved） | 结果证据 |
| L3 | 对同一任务做语义保持扰动后复跑 | 它是**真懂**还是**记住了模式** | 判别证据 |

> **为什么不能只用"能修 bug"一个基准**："修得对"是理解的结果，但不是充分证据——agent 可能靠模式记忆/检索捷径"碰对"。三通道一致才认定理解成立（§1.2.1）。

### 3.1 候选 commit 筛选（`mine_commits.py`）

对目标仓库执行：

```
git log --all --reverse --format='%H|%s|%ad' --date=short
```

筛选规则（全部满足）：
1. **非 merge commit**，非空 diff，改动 ≤ 100 行（任务规模可控）
2. **bug-fix 信号**：message 匹配 `(?i)(fix|bug|resolve|correct|hotfix|修复|错误|bugfix)` 且**非**纯重构/格式化（排除 `refactor|format|style|rename|doc`）
3. **测试伴随**：同一 commit 或相邻 1-2 个 commit 内修改了 Unity 测试文件（`test/`、`tests/` 下 `*_test.c` 或 Ceedling 配置声明的 test 目录）
4. 仓库在该 commit 的父版本上 **Ceedling 可运行**（见 3.4 校验）
5. **子系统标注**：按 UFS 子系统打标签（`protocol / ftl / gc / power / security / perf / vendor`），用于 §5.4 分系统解析率与**任务库均衡**（防止 FTL/GC 类任务占比过高、协议/安全类过少）

**筛选参数**（`config/filter.yaml`，集中可调）：

| 参数 | 默认值 | 说明 |
|---|---|---|
| `min_diff_lines` | 3 | 改动少于该行数的 commit 剔除（无理解含量） |
| `max_diff_lines` | 100 | 超过剔除（任务规模不可控） |
| `max_files` | 10 | 触及文件数上限 |
| `test_adjacency` | 2 | 测试文件允许在 fix commit 后相邻的 commit 数 |
| `subsystem_ratio_max` | 0.35 | 单子系统任务占比上限（均衡约束） |

**正则规格**：
- `bugfix_regex = (?i)\b(fix|bug|bugfix|resolve|resolved|correct|hotfix|repair|crash|timeout|hang|corrupt|leak|race|overflow|修复|错误|崩溃|超时|泄漏)\b`
- `exclude_regex = (?i)\b(refactor|format|style|rename|cleanup|doc|comment|typo|license|merge)\b`
- 判定顺序：先过 `exclude`（剔除），再过 `bugfix`（保留）；两条正则均需同时满足测试伴随与规模约束。

**子系统标注规则**（`config/subsystems.yaml`，路径前缀匹配）：

| 子系统 | 典型路径模式（示例，按实际仓库调整） |
|---|---|
| protocol | `src/proto/`、`src/upiu/`、`*cdb*`、`*descriptor*` |
| ftl | `src/ftl/`、`*l2p*`、`*mapping*`、`*ftl*` |
| gc | `src/gc/`、`*wearlevel*`、`*garbage*` |
| power | `src/power/`、`*sleep*`、`*powerdown*`、`*powerloss*` |
| security | `src/security/`、`*rpmb*`、`*crypto*`、`*secure*` |
| perf | `*hotpath*`、`*fastpath*`、`*merge*`、`*perf*` |
| vendor | `src/vendor/`、`*vendor*` |
| misc | 兜底 |

标注算法：按 fix commit 触及文件中占比最高的子系统打主标签（并列时多标签）；人工抽检校正。

### 3.2 任务构造（`build_dataset.py`）

每个任务包含：

```jsonc
{
  "id": "FW-0001",
  "repo": "firmware_x",
  "base_commit": "a1b2c3d",            // bug 修复前状态（父 commit）
  "fix_commit": "e4f5a6b",             // 修复 commit
  "build_config": "sku_a_nand_micron", // 判定用构建目标（UFS 多配置，必填）
  "difficulty": "HARD",                // 难度档（固定参考模型预校准，§3.2）
  "problem_statement": "...",          // 问题描述（见 3.3）
  "unit": "O5,K3",                     // 所属理解单元（§1.2.3）
  "demand": "S2",                      // 理解需求强度（§1.2.4）；S0 为 decoy 对照任务
  "gold": {
    "files": ["src/driver/uart.c"],    // 修复触及的源文件
    "regions": [                       // base 版本中的行区间（gold standard）
      {"path": "src/driver/uart.c", "start": 120, "end": 145}
    ]
  },
  "tests": {
    "f2p": ["test/uart_test.c"],       // 修复新增/修改的测试 → base 上应红
    "p2p": ["test/uart_test.c", ...]   // 既有测试 → 应保持绿
  }
}
```

每个任务必须标注 `unit` 与 `demand`（§1.2.3/1.2.4）：`unit` 决定它计入哪一维理解得分；`demand` 决定它能否计入——**S0 任务专门用作 decoy 对照**（表面可解、语义不同），用于计算"捷径依赖率"（§1.2.6）。标注由挖掘流水线自动生成初值 + 人工抽检确认。

**任务 ID 方案**：`FW-<序号4位>-<子系统2位字母>-<S强度>`，如 `FW-0042-GC-S2`。序号全局递增不重用；ID 一经入库不可变更（历史可比性）。

**完整字段规格**（schema_version=1 语义）：

| 字段 | 类型 | 必填 | 说明 |
|---|---|---|---|
| `id` | string | ✅ | 见上 |
| `schema_version` | int | ✅ | 任务库 schema 版本，当前 `1` |
| `repo` | string | ✅ | 仓库标识 |
| `base_commit` | string(40) | ✅ | 修复前 commit SHA |
| `fix_commit` | string(40) | ✅ | 修复 commit SHA |
| `build_config` | string | ✅ | 判定用构建目标（NAND/SKU/特性开关组合），§5.2/§5.6 按此构建；UFS 多配置下必填 |
| `problem_statement` | string | ✅ | §3.3 生成 |
| `unit` | string | ✅ | 格式 `O<1-6>,K<1-7>` |
| `demand` | enum S0-S3 | ✅ | §1.2.4 |
| `difficulty` | enum EASY/HARD | ✅ | 预校准难度档：固定参考模型预跑，通过率 ≥50% 为 EASY |
| `subsystem` | string[] | ✅ | §3.1 子系统标签 |
| `bug_type` | enum | ✅ | 逻辑/边界/资源/时序/竞态/协议/性能 |
| `gold.files` | string[] | ✅ | 相对仓库根路径 |
| `gold.regions` | {path,start,end}[] | ✅ | 行区间（闭区间，1-based） |
| `tests.f2p` | string[] | ✅ | base 上必须红 |
| `tests.p2p` | string[] | ✅ | base 上必须绿 |
| `source` | enum | ✅ | `issue`/`commit`/`manual`/`decoy` |
| `notes` | string | ❌ | 人工备注 |

**任务类型配额**（入库约束）：≥70% 真实历史（`commit`/`issue`），≤20% 人工改写的 decoy（`decoy`），≤10% 手工专项（`manual`）。

**难度预校准**：任务入库时用固定参考模型（与 §1.2.7 任务集判别效度同一对象）预跑一次，按通过率标注 `difficulty`（≥50% 为 EASY）。跨单元/跨模型对比**必须按难度分层报告**，防止简单任务拉高整体分、掩盖"只改善简单任务"的模型。

**Gold region 提取**：对 `git diff -U0 base fix`，取每个 hunk 的**父版本侧**（pre-image）行区间——即"bug 实际存在的区域"，映射回 base 文件。文件级 gold = 触及文件集合。

### 3.3 问题描述生成（离线可用方案）

按优先级：
1. **已有 issue/PR 文本**（若仓库关联内网 GitLab/Gitea）：用原始标题+描述，信息最真实
2. **commit message + 测试断言反推**：`git show --stat` + 读测试文件中的断言名/注释，拼接成自然语言症状描述
3. **手工润色**（可选）：维护者把关键 commit 写成标准描述

禁止把 diff 内容直接放进描述（防泄漏，评估的是"从症状找代码"而非"从答案背答案"）。

**Prompt 防泄漏校验器（构建期强制）**：渲染 `prompt.md` 后断言不含：`unit` 值、`demand` 值、子系统标签、gold 文件名/符号名（含大小写/缩写变体）；违者构建失败。同时记录 `prompt.md` 的 sha256 进任务库（防实现者手滑，保历史可比）。

### 3.4 基线校验（`verify_baseline.py`，强制门禁）

每个候选任务入库前必须验证（在 Docker 内跑）：
- **F2P 红**：把 fix 版本新增的测试文件移植到 base 快照上执行 → 必须失败（否则该任务无区分度，剔除）
- **P2P 绿**：base 上原有全部相关测试 → 必须通过（确认环境健康）
- **可构建**：base 快照 `ceedling test:all` 或指定 test file 能编译运行

校验失败的任务自动剔除，并记录原因。

**F2P/P2P 校验的具体操作序列**（`verify_baseline.py` 内实现）：

```
1. 准备 base 快照：git worktree 检出 base_commit 到干净目录
2. 移植 F2P 测试：git show fix_commit -- <test文件> 取出测试文件内容，
   写入 base 快照对应路径（commit 前的既有测试集合保持不变）
   → 若测试文件依赖 base 版本不存在的新符号，编译失败也算"红"，
     但区分两类红记录原因：ASSERT_FAIL 与 COMPILE_FAIL
3. 跑 F2P：ceedling test:file=<f2p文件> → 断言失败或编译失败 = 红 ✅
4. 跑 P2P：ceedling test:file=<p2p文件>（逐一）→ 全部通过 = 绿 ✅
5. 全部通过才入库；任一步失败记录到 tasks/<id>/verify.log 并剔除

判定输出：{id, f2p_red: [{file, kind}], p2p_green: [...], buildable: bool}
```

红/绿判定解析规则见 §5.6（与 L2 判定共用同一解析函数，保证口径一致）。

### 3.5 防泄漏控制

- base 快照为**修复前**状态，gold 区间来自父版本 diff
- 候选 commit 需在**模型训练截止之后**（若内网模型可配置截止日期）或接受已知污染并仅在**相对**比较中使用
- 描述文本中移除文件名/符号名（必要时用占位符），避免"见名知答案"
- **任务轮换（防记忆/曝光累积）**：任务池规模 ≥ 2× 每轮用量，轮换子集；每季度注入 ≥20% 新任务；每轮记录任务子集 hash 进报告（§7.5）

### 3.6 Gold region 提取算法（`pipeline/extract_gold.py`）

输入：base_commit、fix_commit。输出：gold.files + gold.regions。

```
1. 计算 diff：git diff -U0 <base> <fix> -- src/ test/
   （排除 *.md、*.yml、*.json 等非代码文件）
2. 对每个 hunk：
   a. 取 pre-image（base 侧）行区间 [start_pre, end_pre]
   b. 纯注释/空行 hunk（有效代码行 < 3）可选降权
3. 行区间合并：同一文件内相邻区间（gap ≤ 10 行）合并
4. 区域保序：按文件、按 start 排序
5. 输出映射回 base 文件行号（diff 的 pre-image 行号即 base 行号，无需额外映射）
6. 过滤规则：
   - 剔除测试文件本身的 gold 区域（测试是"答案载体"，不产生 gold）
   - rename 检测：git diff --no-renames 对比，剔除整块搬移的文件
7. 生成**三档 gold**（v1.4，多粒度去噪）：
   - 文件档：`files`（修复触及文件）
   - **函数档**：`functions [{path, name}]`（AST 解析 diff 触及文件，提取 hunk 所在最内层函数；主评分档）
   - 行档：`regions [{path, start, end}]`（参考档）
```

要点：
- **gold = bug 实际所在的代码区域**（父版本侧 hunk），不是修复后的代码
- **函数档为主评分档**（§4.3）：行偏移容忍强于行级，规避"人工改的≠必须理解的"（band-aid 修复）带来的行级噪声
- 测试文件不产生 gold 区域，但产生 tests.f2p 条目
- 修复跨 5+ 文件时：gold.files 全保留，但 regions/functions 仅取核心 1-3 个（评分时核心区域权重更高）

### 3.7 任务库目录结构（`tasks/`）

```
tasks/
└── v1/                                  # schema_version=1
    ├── manifest.json                     # 版本元数据：schema_version、生成时间、
    │                                     # commit 范围、任务清单(id+unit+demand)、统计
    └── FW-0001/
        ├── task.json                     # 任务定义（§3.2 完整 schema）
        ├── prompt.md                     # 实际注入 agent 的问题描述（含统一评估说明头）
        ├── gold.json                     # 提取结果（同 task.json.gold）
        ├── base_snapshot.tar.gz          # base_commit 快照（含 commit 指针记录）
        ├── tests/                        # 移植后的 F2P/P2P 测试（基线校验产物）
        │   ├── f2p/
        │   └── p2p/
        ├── verify.log                    # §3.4 门禁记录
        └── status.json                   # {status: ready|deprecated|qa_failed, ...}
```

约束：
- `base_snapshot` 以 tar 归档存储，评估时解包到工作区，只读不写
- 任务一经发布（`status=ready`）即冻结；修订走新任务（新 ID），不覆盖旧任务
- 每季度按 §1.2.7 效度结果把不达标任务标记 `deprecated`

### 3.8 质量控制（人工抽检）

| 抽检项 | 比例 | 判据 |
|---|---|---|
| 问题描述质量 | 10% | 不含文件名/符号名；症状可独立复现；S 标注合理 |
| gold 准确性 | 10% | 对照 fix diff 人工核对，确实覆盖 bug 根因 |
| F2P 有效性 | 全部（门禁已做） | verify.log 红/绿记录完整 |
| unit/demand 标注 | 10% | 单元归属与强度判定一致 |
| decoy 质量 | 全部 | S0 任务确实"表面可解、语义不同"，未误标为真任务 |

抽检不合格率 > 15% 时：整批任务打回重做，记录批次 ID 供追溯。

---

## 4. Layer 1：定位/导航理解评估（轻量、高频）

**问题**：agent 知不知道"相关代码在哪"——这是理解最基础、量化最干净的维度。

### 4.1 任务形式

- 输入：问题描述（3.3 生成）
- 输出约定：opencode 返回**排序的 `文件:行区间` 列表**（最多 K=10 个区域）
- 工具约束：**只读模式**——仅允许 `grep`/`read`/`glob`/`lsp_*` 等检索工具，**禁用一切编辑/执行工具**（通过 opencode agent 权限配置实现）

### 4.2 opencode 集成

- 专用 locator agent 配置（`opencode.json` / `.opencode/agent/locator.md`）：
  - system prompt：「你是固件代码定位器。给定问题描述，使用检索工具在仓库中找到最相关的代码区域，只输出 JSON 格式的排序列表，不修改任何文件。」
  - permissions：read-only（无 `write`/`edit`/`bash`）
- 调用：`opencode run --agent locator --session-prompt "$TASK_PROMPT"`（cwd = base 快照目录）
- 预算：每任务上限 20 个工具调用或 5 分钟，超时即截断当前产出

**locator agent 配置（`.opencode/agent/locator.md`）**：

```markdown
---
description: 固件代码定位器（只读，用于理解度评估）
tools: Grep, Glob, Read, LspSymbols, LspGotoDefinition, LspFindReferences
permission: deny Write, Edit, Bash, Task, WebFetch, WebSearch
---
你是固件代码定位器。给定一个问题描述，在仓库中找到与问题最相关的代码区域。

规则：
1. 只使用检索类工具（grep/read/glob/符号跳转），禁止修改任何文件
2. 输出必须是严格的 JSON 数组，每个元素：
   {"file": "相对路径", "start": 行号, "end": 行号, "reason": "一句话理由"}
3. 按相关度从高到低排序，最多 10 个
4. 若无法判断，输出空数组 []，不要猜测
```

**权限配置（`opencode.json` 对应 agent 段）**：`write:false, edit:false, bash:false, webfetch:false, websearch:false, task:false`（禁止派生子 agent，保证行为可控可复现）。

**调用与预算参数**（`config/budget.yaml` 中 L1 段）：

| 参数 | 值 | 说明 |
|---|---|---|
| 最大工具调用（**主预算**） | 20 | **以次数为主预算**：不受并行资源争用影响，跨轮可比 |
| 超时（兜底） | 300s | 仅防死循环；受宿主争用影响，不作为跨轮判定依据 |
| 输出解析 | 取最后一段合法 JSON | 解析失败按 `[]` 处理并标记 `PARSE_FAIL` |

### 4.3 评分公式（`scoring/retrieval_metrics.py`）

设 gold 区域集合 `G`，预测区域集合 `P`（行区间相交判定命中）：

| 指标 | 公式 | 说明 |
|---|---|---|
| HitFile | `|files(P) ∩ files(G)| / |files(G)|` | 文件档，是否到达正确文件 |
| 函数级 Recall/F1 | 与 gold 函数行区间相交判定（主档） | **主评分档**：行偏移容忍强（§3.6 三档 gold） |
| 行级 Recall/Precision/F1 | `|lines(P) ∩ lines(G)| / |lines(G)|` 等 | 参考档 |
| BCY@B | 固定 token 预算 B 下 gold 覆盖率 | **主效率指标**（v1.4，替代 CE）：预算曲线 |
| REL-eff | `覆盖率_agent / 覆盖率_基线(同预算)` | 相对无脑检索的效率（§4.6 基线） |
| FUH | `1 / rank(first_hit)`（无命中=0） | 多久找到第一处对的地方 |
| nDCG@K | 按 rank 折损的累积增益 | 排序质量 |

按单元（O×K）及知识对象 K1-K7 汇总得分（§1.2.2）；仅 S2/S3 任务计入理解得分，S1 作基线对照、S0 计入"捷径依赖率"单独报告（§1.2.4）；对 gold 区域为空/描述含糊的任务标记为"无法判定"并从分母剔除。

**行区间相交判定（精确规则）**：

- 区间以 `[start, end]` 闭区间、1-based 行号表示
- 相交判定：`overlap(P,G) = max(0, min(P.end,G.end) − max(P.start,G.start) + 1)`
- 单区域命中：`overlap ≥ max(1, 0.2 × |G|)` 记为命中（容忍行号偏移，防"差 1-2 行"误判）
- 去重：先合并 P 内相互重叠的区域，再计行数
- 行计数：`|lines(S)| = Σ(合并后各区域长度)`

**归一化**：所有指标先按任务计算，再按单元取均值。**报告门槛（v1.4）**：单元级 n ≥ 20 才报分；n<20 聚合到粗粒度（O 轴或 K 轴）报告；n<5 仅列计数、不作任何比较。

**函数级指标（主档，v1.4）**：gold 三档见 §3.6。HitFile 用文件档；**Recall/F1 主档用函数档**（命中 = 预测区域与 gold 函数行区间相交，行偏移容忍天然更强）；行级档仅作参考。

**预算产出指标（主指标，v1.4 替代单一 CE）**：
- **BCY@B（预算上下文产出）**：固定 token 预算 B ∈ {1k, 2k, 4k, 8k} 下，按预测排序贪婪打包文件，度量 gold 覆盖率曲线（Agent Retrieval Bench 范式）。多预算点画曲线，跨任务/单元公平，取代拍脑袋的 log 归一化
- **相对效率 REL-eff**：`REL-eff(task) = 覆盖率_agent / 覆盖率_基线检索器(同预算)`，基线 = BM25/grep 关键词（§4.6）；>1 表示优于无脑检索，跨任务/单元可比

（旧 CE 公式废弃：`log2(1+emitted_lines)` 为任意压缩，`w(g)=1/区域数` 惩罚 gold 分散任务。SWE-Explore 的 r=0.95 需在本库复验后才可作主判据。）

**nDCG@K**：按预测区域 rank 计 relevance——命中 gold 区域 rel=1（首命中 rank 记 1，同文件重复命中折半），未命中 rel=0；`nDCG@10 = DCG@10 / IDCG@10`。

**FUH**：首个命中 gold 区域的预测区域在排序中的 rank（1-based）；`FUH_score = 1/rank`；无命中 = 0。按单元取均值。

**轨迹过程指标**（数据来自 §4.5 轨迹解析）：
- `read_before_output`：L1 输出前最后 5 次 read 命中 gold.files 的占比（衡量"输出是否有读支撑"）
- `first_gold_read_turn`：第一次读到 gold 文件发生在第几轮工具调用（越小 = 进入状态越快）

### 4.4 运行与产出

- 批次：20-30 任务/轮，全并行，成本 ≈ 数十分钟
- **基线对照（常驻）**：同跑 BM25/符号图排名/纯 grep（§4.6），报告"理解增益 = agent − 基线"
- 产出：`reports/l1_YYYYMMDD.md`，含总分表 + 每任务明细 + 失败案例（agent 实际轨迹截断 + 为什么没找到）
- 频率：每周（模型/上下文配置变更后必跑）

### 4.5 过程证据解析（`scoring/trajectory.py`）

**数据来源**：opencode session 的 transcript（`opencode session read --session <id>` 或运行日志 JSONL），提取工具调用时间线。

**解析出的轨迹事件**（每事件：ts, tool, params）：
- `read`/`grep`/`glob`/`lsp_*` → 记录目标文件路径
- `edit`/`write`/`bash` → 记录目标路径（L1 中不应出现；出现则标记违规但记录不剔除）
- 最终输出 → 记录的 JSON

**关键过程指标**：

| 指标 | 定义 |
|---|---|
| `read_before_output_hit` | 输出前最后 5 次 read 中命中 gold.files 的占比 |
| `first_gold_read_turn` | 第一次读到 gold 文件的工具调用序号（越小越好） |
| `exploration_ratio` | 非 gold 文件读取次数 / 总读取次数（越低越高效） |
| `pre_edit_read_hit` | L2 用：首次 edit 前的 read 序列中命中 gold.files 的占比 |

**L2 使用规则**：未读任何 gold 文件就发生首次编辑 → 该任务过程证据判负（即使最终修对，也只能算"结果碰对"）。

**统计口径**：过程指标按任务记录、按单元汇总；只作辅助通道，不单独决定结论（§1.2.5）。

### 4.6 基线检索器对照（常驻，给 agent 分提供锚点）

每次 L1 同跑 3 个**确定性基线**（零模型成本），为 agent 绝对分提供解释锚点：

| 基线 | 做法 |
|---|---|
| BM25 | 对问题描述做词法检索（rank 文件） |
| 符号图排名 | aider RepoMap 式：符号引用图 PageRank 排名（无向量、无模型） |
| 纯 grep 关键词 | 从描述提取关键词做正则检索 |

输出与 agent 相同格式（排序文件/区域），走同一评分函数（§4.3）。

**报告口径**：
- `理解增益 = agent分 − 基线分`（按单元）
- 增益 ≤ 0 的单元 → 任务过易或 agent 检索劣于无脑基线，触发任务调级或上下文工程
- REL-eff（§4.3）的基线与本节同一套

### 4.7 组件消融定位评估（v1.5：量化每个工具对"理解"的贡献）

**方法**：同一批 L1 任务（20-30 个）跑 §1.3 的 5 组配置，每组工具权限不同：

| 组 | 允许的工具 | 禁止 |
|---|---|---|
| no-tool | grep/read/glob | 全部 MCP |
| cg | + codegraph MCP（codegraph_explore 等） | graphify/openviking |
| gfy | + graphify MCP（query_graph/get_neighbors/最短路径） | codegraph/openviking |
| ov | + openviking MCP（find/search/read） | codegraph/graphify |
| full | 全部 | — |

**归因指标**（每单元、每任务）：
- **组件边际贡献**（主口径）= `full − 去掉该组件`（leave-one-out）
- **组件单独贡献**（补充口径）= `单组件组 − no-tool`
- 与 §1.2.3 组件主力映射对照：预期主力却实测无贡献 ⇒ 工具集成失效或 agent 不会用该工具

**统计**：5 组为配对数据（同任务），差异用配对检验（McNemar 对解析、配对 t/秩和对连续分）+ Holm 校正；组件贡献表进看板（§8）。

**产出与节奏**：`reports/l1_YYYYMMDD_ablation.md` + 组件贡献表。季度跑；模型变更时必跑（工具价值可能随模型变化）。

---

## 5. Layer 2：端到端修复理解评估（核心、低频）

**问题**：agent 是否真正"读懂并修对"——用真实测试判定，无任何 LLM judge。

### 5.1 评估协议（SWE-bench 机制 × COMET Classic 全流程，v1.5）

**协议（任务走 COMET 全流程）**：

```
任务 = base 快照（含按快照重建的工具索引 §5.8）+ 问题描述 + F2P/P2P 测试集
流程 = /comet-open → /comet-design → /comet-build → /comet-verify → /comet-archive
判定 = verify 阶段必须执行 F2P/P2P（ceedling）：
        F2P 全绿 且 P2P 全绿 且 通过 verify 守关      →  Resolved
        中途卡死 / 跳过相位守关 / 未达 verify         →  Unresolved（记录失败指纹）
```

**评估环境的 decision-point 处理（关键工程细节）**：COMET Classic 有多处人工确认阻塞点（brainstorming 确认、workflow 选择、plan 确认）。评估环境无真人 → 配置为 `decision-point: auto-approve`（每个自动批准点写入会话记录，供事后人工复核）；若所用 COMET 版本不支持 auto，用预设脚本注入"确认"应答，保证流程自动走完。

**失败指纹扩展**（§5.4 原 6 类之上，v1.5）：
- `PHASE_STUCK`：卡在某一相位（守关不通过或死循环）
- `PHASE_SKIP`：跳过相位守关直接提交
- `NO_BRAINSTORM`：Classic 全流程未做 brainstorming
- `SPEC_DRIFT`：build 产物与 design/spec 明显偏离（产物比对）

**预算**：全流程单任务 ~60-90min；数据集首期 **20-30 任务**（原 50，成本约束，见 §7.2 成本表）。

### 5.1.1 UFS 固件的可测性边界（任务入库的硬约束）

UFS 固件高度依赖硬件，L2 的可执行判定只对**能在 host 端跑 Ceedling 的逻辑层**成立：

| 层 | 内容 | host 端可测性 |
|---|---|---|
| 纯逻辑层 | CDB/UPIU 解析、L2P 表操作、GC/wear-leveling 策略、命令调度、descriptor 读写、掉电现场保存/恢复序列 | ✅ 可直接单测 |
| 硬件依赖层 | NAND 接口、门铃寄存器、DMA 描述符、中断向量 | ⚠️ 需 mock（NAND 模拟器/host 接口桩/中断注入桩） |
| 时序/竞态类 bug | 特定时序下才复现的 race、中断抢占窗口 | ❌ host 端无法稳定复现 → **不入 L2 数据集**，改走 L1 定位 + L3 诊断 |

**推论**：①数据集构建阶段必须按此边界过滤，时序/竞态类修复 commit 不构造 L2 任务；②L2 覆盖率天然偏向逻辑层子系统，协议/安全类的时序缺陷理解主要靠 L1/L3 补；③若内网已有 **host 端 NAND/控制器模拟环境**（模拟 L2P 命中/掉电/坏块注入），L2 覆盖可大幅扩展——**待确认项**。

### 5.2 Docker 镜像设计（`Dockerfile.eval`）

**Dockerfile.eval（示例骨架，按内网基础镜像替换）**：

```dockerfile
FROM 内网registry/ubuntu:22.04-eval-base

# 交叉工具链（与生产 CI 完全一致）
RUN apt-get update && apt-get install -y \
    gcc-arm-none-eabi binutils-arm-none-eabi \
    gcc make cmake git python3 ruby \
    && rm -rf /var/lib/apt/lists/*

# Ceedling（内网离线 gem 包；若仓库 vendor/ 已带则跳过）
RUN gem install --local /opt/wheels/ceedling-*.gem

# 构建依赖（从内网 pip/gem 源安装）
COPY requirements.txt /opt/
RUN pip install --no-index --find-links=/opt/wheels -r /opt/requirements.txt

WORKDIR /workspace
ENTRYPOINT ["/opt/eval/run_test.sh"]   # 统一测试入口，见 §5.6
```

**镜像维护规则**：
- 版本标签：`eval-fw:2026-08-23-ceedling-3.x`；镜像内容变更必须换标签
- 每次 L2 运行记录镜像 digest 到报告（防"测试环境漂移"污染对比）
- 镜像只在内网 registry 拉取；构建产物入库内网 artifact 仓库

**测试入口脚本 `/opt/eval/run_test.sh`**：

```bash
#!/bin/bash
# 用法: run_test.sh <test_file...>  输出每文件 PASS/FAIL + 失败断言行号
for f in "$@"; do
  if ceedling test:file="$f" 2>&1; then echo "PASS $f"; else echo "FAIL $f"; fi
done
```

**每次运行流程**：起容器 → 解包 base_snapshot → 注入问题描述 → opencode 在**挂载的 workspace** 内工作 → 收集 patch → 恢复 tests/ 基线 → `run_test.sh` 判定（§5.6）。

### 5.3 opencode 集成（两种模式，推荐 B）

| 模式 | 做法 | 取舍 |
|---|---|---|
| A. 容器内嵌 | 在 Docker 里装 opencode，agent 全程在容器内 | 隔离彻底；镜像大、内网装 node 依赖麻烦 |
| **B. Host 运行（推荐）** | opencode 在宿主跑，cwd=挂载的 base 快照；完成后容器内跑 Ceedling 判定 | 复用现有 opencode 安装；判定仍隔离在容器 |

固定约束（跨任务不可变）：最大轮次（如 30）、最大工具调用（如 100）、超时（如 20 分钟）、system prompt 模板。**只允许任务描述变化。**

**repair runner 伪代码（`runners/layer2_repair.py`）**：

```
for task in selected_tasks:
    ws = prepare_workspace(task)             # 解包 base_snapshot，写入 prompt.md
    result = run_opencode(
        cwd=ws,
        session_prompt = PROMPT_HEAD_REPAIR + "\n\n## 任务\n" + task.problem_statement,
        max_turns=30, max_tool_calls=100, timeout=1200,
    )
    patch = extract_patch(ws)                # git diff 相对 base_snapshot
    if patch 为空: mark(NOOP/TIME); continue
    git checkout ws/tests/                   # 恢复 tests/ 基线（防篡改测试）
    verdict = judge_in_docker(task, patch)   # §5.6
    record(task.id, patch, verdict, trajectory_metrics(result))
```

**固定约束表（入 changelog）**：

| 参数 | 值 | 说明 |
|---|---|---|
| repair prompt 头 | 见附录 B.2 | 统一任务说明、输出要求 |
| max_turns | 30 | 超限终止（失败指纹 MAX_TURNS） |
| max_tool_calls（**主预算**） | 100 | **次数为主预算**，超限终止（TIME）；抗并行资源争用 |
| timeout（兜底） | 1200s | 仅防死循环；受争用影响，不作为跨轮对比依据 |
| 测试运行预算 | ≤ 10 次/任务 | 防 agent 无限试错 |
| 工具白名单 | grep/read/glob/edit/write/bash | L2 允许编辑与执行 |

**补丁提取规则**：取工作区相对 base_snapshot 的 `git diff`；**排除 tests/ 目录自身改动**（防改测试作弊），但允许新增非测试辅助文件；判定前强制恢复 tests/ 到移植后基线。

**COMET 集成（v1.5）**：工作区安装 COMET（`comet init --platform opencode`，Classic 模式）；runner 以 `/comet` 为入口注入问题描述；相位推进由 `comet-state`/`comet-guard` 脚本驱动；decision-point 配置 auto-approve（§5.1）；产物（proposal/design/tasks/verification report）落盘路径随任务归档，供工作流证据通道（§5.4）解析。

### 5.4 指标（`scoring/resolve_metrics.py`）

- **% Resolved** = 求解任务数 / 总任务数（主指标，附 Wilson 95% 置信区间）
- 分单元解析率：按 (O×K) 理解单元与知识对象 K1-K7（§1.2）、按 UFS 子系统（protocol/ftl/gc/power/security/perf/vendor）、按 bug 类型（逻辑/边界/资源/时序/竞态）；仅 S2/S3 任务计入主得分
- **按难度分档解析率**（EASY/HARD，§3.2 difficulty）：防"只改善简单任务"被平均分掩盖；回归检测同样按难度分层
- **工作流产物通道（v1.5 新增，COMET Classic 特有）**：
  - proposal/design doc 质量 → O4 解释理解（LLM-judge 或人工抽检 20%）
  - tasks.md 任务拆分合理性 → 任务分解理解
  - 相位守关通过率、TDD 红绿循环执行率 → 流程/方法合规
- **组件归因（v1.5）**：full 组 vs 消融组（§4.7 方法迁移到 L2）的解析率差 → 各工具对修复能力的边际贡献
- F2P/P2P 明细：部分通过情况（F2P 全过但 P2P 破坏 → "修对但引入回归"，单列）
- 成本效率：token/已解任务、耗时/任务、无动作轮次（推理空转比例）
- **失败指纹**：每任务按 6 类分类（REASON / VERIFY / TIME / MAX_TURNS / HANG / ERROR），识别系统性失败模式

### 5.5 数据集规模与统计

- 首期 50 任务起步（置信区间宽度可接受），逐步扩到 100-200
- 每任务 1 次运行；对解析率在 20%-80% 区间的任务可复跑 3 次取多数（成本可控时）

**Wilson 95% 置信区间**（仅用于**绝对分与目标值**对比）：

```
p̂ = x / n          # x=解析数，n=任务数
z  = 1.96
denom  = 1 + z²/n
center = (p̂ + z²/2n) / denom
half   = z·√(p̂(1−p̂)/n + z²/4n²) / denom
CI     = [center − half, center + half]
```

**配对对比（模型间/轮次间回归，v1.4 主方法）**——同任务集 = 配对数据，**禁止用"CI 区间不重叠"判定**（对配对数据功效仅≈1.7% 显著性水平，真实回归必被漏报）：

```
对同任务集在两配置下的结果构造 2×2 表：
          B 对  B 错
  A 对    n00    n01
  A 错    n10    n11
McNemar: χ² = (|n01 − n10| − 1)² / (n01 + n10)，df=1
n01+n10 < 10 时改用精确二项检验
显著 → 判定两配置差异显著
```

- **多重比较校正**：多单元同时回归检测时，p 值按 **Holm 校正**（11 单元），防假阳性
- **难度分层**：配对对比按 `difficulty`（EASY/HARD）分层，防"只改善简单任务"被平均分掩盖
- **功效下限诚实声明**：n=50 时本系统只能检出 ≥15-20pp 的差异；报告必须附"本轮检出能力下限"；**单轮绝对分数只作趋势判断，不做精确排名**
- n < 20 时不报 CI，仅报原始计数 x/n

### 5.6 执行判定规则（`scoring/execute.py`，L2 与 §3.4 共用）

**判定流程**：

```
1. 应用补丁到 base 快照（git apply 或直接恢复 diff）
2. 恢复 tests/ 目录到基线（防 agent 篡改测试）
3. 对每个 f2p 文件跑 run_test.sh → 全部 PASS = F2P 绿
4. 对每个 p2p 文件跑 run_test.sh → 全部 PASS = P2P 绿
5. 判定：
   F2P 全绿 且 P2P 全绿   → resolved
   F2P 全绿 但 P2P 有红   → regression（修对但引入回归）
   否则                  → unresolved
```

**输出解析规则**：
- 依据 `run_test.sh` 的 `PASS <file>` / `FAIL <file>` 行判定
- `IGNORE`/`SKIP`（`UNITY_IGNORE`）的测试不算失败
- 编译失败（Ceedling 非 0 且无测试运行）→ `COMPILE_FAIL`，失败指纹归 ERROR 类
- 每文件超时 300s → 归 HANG 类

**判定确定性要求**：同一 (task, patch) 连续判定 2 次结果一致才写入；不一致标记 `FLAKY` 并人工复核。

### 5.7 L1→L2 因果链验证（上下文注入实验，季度）

**目标**：把 L1 定位与 L2 修复从"相关验证"升级为**因果链验证**——证明 L1 的定位输出确实携带修复所需信息（对应 §1.2.7 收敛效度的 v1.4 升级）。

**方法**（seed 来源 = 工具链组合，v1.5 升级）：

```
对同一任务子集（20-30 个，L2 已解+未解各半）跑四组：
  A. no-seed：原 L2 协议（COMET 全流程，无初始上下文）
  B. full-seed：注入全工具链 L1 输出（top-5 区域）作为初始上下文
  C. oracle-seed：注入 gold 区域（上界）
  D. 单组件-seed（可选）：注入 cg/gfy/ov 各自的 L1 输出 → 直接测
     每个工具对修复的因果贡献（组件级因果链）
比较四组 %Resolved。
```

**四象限诊断**（对每个任务）：

| L1 命中 | L2 修复 | 结论 |
|---|---|---|
| ✅ | ✅ | 真理解 |
| ✅ | ❌ | 修复能力缺陷（理解够、改不对） |
| ❌ | ✅ | **运气/猜测（重大红旗，需人工复核轨迹）** |
| ❌ | ❌ | 双重失败 |

**判定**：B 组 vs A 组解析率提升经 McNemar 检验显著（§5.5）⇒ "定位理解对修复存在因果贡献"成立；D 组单独显著 ⇒ 对应工具组件对修复存在因果贡献。成本：每任务 +2~3 次 L2 运行（并入成本预算表 §7.2）。

### 5.8 工具-索引同步（v1.5 新增，评估正确性的前提）

每个任务 base_snapshot 解包后，**必须按该快照重建工具索引**（禁止使用生产/最新分支索引——否则任务对 agent 泄露未来状态）：

| 工具 | 重建动作 | 绑定记录 |
|---|---|---|
| codegraph | 对快照目录 `codegraph index` | task.json `indexes.codegraph` |
| graphify | 快照内建图到 `.graphify/graph.json`，MCP serve 指向该图 | `indexes.graphify` |
| openviking | 快照作为资源 `add_resource`（或评估命名空间内引用） | 命名空间 `eval-<run_id>` |

**硬规则**：
- 索引内容只含 base 快照；扰动版本（L3）必须重建（或重建受影响子图）
- 每次重建记录耗时与成败 → 新指标 **索引重建成功率/耗时**（工具链健壮性）
- 重建失败 → 该任务标记 `INDEX_FAIL`，可降级为 no-tool 组重跑（不浪费任务）

### 5.9 openviking 记忆隔离（评估公平性的关键）

openviking 仅 MCP 手动调用（无自动 hooks），仍需严格隔离：

- **命名空间隔离**：评估专用 peer/account `eval-<run_id>`；生产记忆对评估 agent 不可见，反之亦然
- **轮次隔离**：每轮评估用新命名空间——上一轮任务结果不得被"记住"（防任务库记忆污染）
- **调用记录**：记录 agent 对 `openviking_*` 的每次调用（search/find/read/remember）→ 记忆复用证据（辅助通道）
- **复跑规则**：agent 主动 `remember` 不构成作弊（在隔离命名空间内），但会让同任务的后续对比轮受益 → 同一 (任务, 配置) 的复跑必须在同一命名空间内一次性完成，或复跑前清空命名空间

---

## 6. Layer 3：深层理解诊断（扰动/对抗、低频）

**问题**：高分是"真理解"还是"模式记忆"？——用**语义保持扰动**区分。

### 6.1 固件扰动算子（`pipeline/perturb.py`）

对 base 快照施加扰动，**保持语义不变**，任务与判定协议不变：

| 算子 | 做法 | 破坏的理解维度 |
|---|---|---|
| **符号混淆** | 批量重命名标识符/宏（`uart_init`→`a1b2c3`），保持 AST 语法有效 | (O1,K1) 符号依赖 / 模式记忆捷径 |
| **依赖遮蔽** | 把寄存器宏定义/常量定义移动到其他文件（同值同语义） | (O2,K2) 跨文件追踪 |
| **条件编译扰动** | 交换/复制 `#ifdef` 分支，或插入无语义变化的分支 | (O1,K5) 配置理解 |
| **抽象层打散** | 把 HAL 封装函数内联展开 / 拆分到新文件 | (O2,K2)/(O3,K6) 抽象与硬件语义 |
| **声明延迟** | 用前向声明替代类型定义（语义等价） | (O2,K2)/(O2,K3) 依赖与控制流 |

符号混淆需配合 `git mv` 级别的一致性处理，保证 `#include` 链与宏引用仍可编译（用编译器校验扰动后快照可构建）。

**算子实现规格（`pipeline/perturb.py`）**：

| 算子 | 实现方式 | 语义保持校验 |
|---|---|---|
| 符号混淆 | tree-sitter C grammar 提取标识符 → 按规则重命名（声明/引用一致性）；宏名同样处理；`#include` 文件名不改 | 编译通过 + 原 P2P 仍绿 + 原 F2P 仍红（§6.5） |
| 依赖遮蔽 | 目标宏/常量定义移至同目录另一文件，原处留 `#include` | 同上 |
| 条件编译扰动 | 在 `#ifdef` 块间插入同值分支（`#if 1` 包原内容）或交换等价分支，不改变最终生效路径 | 同上 |
| 抽象层打散 | HAL 封装函数体内联到调用点（原函数保留壳调用内联版） | 同上 |
| 声明延迟 | 类型定义改为前向声明 + 独立定义文件 | 同上 |

**统一约束**：
- 扰动只作用于 base 快照副本，绝不污染原任务
- 每次扰动记录 diff 统计（文件数/行数/重命名数）到 `perturb_manifest.json`，供 URI 按扰动规模分桶校正
- **扰动快照的工具索引必须重建**（§5.8）；重建失败该扰动样本作废（§6.5）——这同时测"工具链对代码变化的自适应能力"

### 6.2 评估流程

1. 取 Layer 2 已解/未解的任务子集（30-50 个）
2. 每个任务生成 1-2 个扰动版本
3. 同协议复跑（同 harness、同 prompt、同预算）
4. 对比解析率

**任务选择与统计口径**：
- 选择：L2 已解 ≥10 个 + 未解 ≥10 个（保证 URI 分母非零且可解释）
- 每任务生成 2 个扰动版本，算子随机分配（保证每种算子 ≥ 5 个样本）
- 复跑协议与 L2 完全一致（§5.3 固定约束表）
- URI 按任务平均；同时报告**每算子分桶 URI**（定位"哪种理解最脆弱"）
- 扰动样本 ≥ 20 个才报 URI 结论

### 6.3 指标：理解鲁棒性指数 URI

```
URI = 1 − (解析率_扰动版 / 解析率_原版)      # 0=完全鲁棒；1=完全脆弱
鲁棒性评级：
  URI < 0.10 → 真理解（语义层面）
  0.10–0.30 → 部分依赖模式
  URI > 0.30 → 主要靠模式记忆，理解脆弱
```

同时报告**扰动前后定位得分差**（Layer 1 任务同样适用）与每维度的脆弱点排名。

### 6.4 UFS 固件专项诊断任务（可选增强）

不依赖 git 历史的静态专项集（可人工编写 20 题，针对 UFS 域）：
- **命令队列状态机**：「QDepth 满且 GC 进行中时，新命令的门铃处理路径」→ gold = 队列状态机 → 门铃处理 → 调度链
- **掉电保护流程**：「掉电中断到 L2P 现场保存的完整路径」→ gold = 掉电 ISR → 保存序列 → 恢复验证链
- **L2P 一致性**：「异常掉电后如何发现并重建映射表」→ gold = 一致性检查 → 重建逻辑
- **GC 并发所有权**：「GC 与前台读写并发时的缓冲所有权规则」→ gold = 所有权转移点
- **性能敏感路径**：「哪些代码位于队列批处理/命令合并热路径上」→ gold = 热路径函数集合

### 6.5 扰动语义保持校验（扰动版入库门禁）

每个扰动版本发布前必须通过（全部本地执行，无外联）：
1. **可构建**：扰动快照 `ceedling test:all` 编译通过（或最小受影响 test file）
2. **P2P 保持绿**：原任务全部 p2p 测试在扰动快照上仍通过
3. **F2P 保持红**：原 f2p 测试在扰动快照上仍失败（若扰动意外"修好"bug，则该扰动无效）
4. **diff 规模记录**：文件数、行数、重命名数
5. **工具索引重建校验（v1.5）**：扰动快照的 codegraph/graphify 索引可成功重建；重建失败该扰动样本作废

通过即写 `perturb_manifest.json`；任一失败 → 丢弃该扰动样本并记录原因。

---

## 7. 运行编排

### 7.1 节奏与触发

| 层 | 频率 | 触发条件 |
|---|---|---|
| L1 | 每周 | 模型/上下文配置/工具链变更后必跑；否则周度例行 |
| L2 | 每月 | 版本发布前；模型升级前（回归检测门禁） |
| L3 | 每季度 | 深度体检 |

### 7.2 内网部署

- **调度**：GitLab CI pipeline 或内网 cron + runner（无需外网）
- **镜像**：全部镜像走内网 registry；依赖（ceedling/gcc）用内网镜像源
- **存储**：任务库 + 报告存内网 Git 仓库（`eval-fw/`，见 7.3）
- **并发**：L1 全并行；L2 建议 2-4 并发（每任务独立容器）；**预算以工具调用次数为主**（§4.2/§5.3），并发争用不影响跨轮对比

**成本预算参考**（单轮，排期用；v1.5 已按 COMET Classic 全流程调整）：

| 层 | 任务数 | 单任务耗时 | 串行总时 | 建议并发 | 实际排期 | 人时（评审/分析） |
|---|---|---|---|---|---|---|
| L1 消融 | 30×5 组 | ~5min/组 | ~12.5h | 全并行 | ~1-2h | 4h |
| L2（COMET 全流程） | 25 | ~75min | ~31h | 4 容器 | ~8-10h | 6h |
| L2+因果 seed（§5.7） | 20×3~4 组 | ~75min | ~75h | 4 容器 | ~19h | 3h |
| L3 | 25×2 | ~75min | ~63h | 4 容器 | ~16h | 4h |

**工具 token 分账**（v1.5 必报）：graphify 建图/语义提取、openviking 记忆蒸馏、codegraph 索引为工具自身消耗，须与模型推理 tokens 分开核算（graphify 建图成本可跨任务摊销——同一 base 快照的 L1/L2/L3 复用一份图）。

### 7.3 代码仓库布局（建议）

```
eval-fw/
├── pipeline/
│   ├── mine_commits.py        # git 历史挖掘 → 候选
│   ├── filter_candidates.py   # 可测性过滤（§3.1 参数）
│   ├── extract_gold.py        # gold region 提取（§3.6）
│   ├── build_dataset.py       # 任务 JSONL（含 unit/demand 标注）
│   ├── verify_baseline.py     # F2P 红 / P2P 绿 门禁（§3.4）
│   └── perturb.py             # 扰动算子（§6.1/§6.5）
├── tasks/v1/                  # 版本化任务库（§3.7 目录规范）
├── runners/
│   ├── layer1_locator.py      # 定位评估 runner（read-only）
│   ├── layer2_repair.py       # 修复评估 runner + Docker 判定
│   └── layer3_perturb.py      # 扰动生成 + 复跑
├── scoring/
│   ├── retrieval_metrics.py   # HitFile/R/F1/CE/FUH/nDCG（§4.3）
│   ├── trajectory.py          # 轨迹过程证据（§4.5）
│   ├── execute.py             # Ceedling 判定（§5.6）
│   ├── resolve_metrics.py     # %Resolved/失败指纹/成本/Wilson CI（§5.4/5.5）
│   └── robustness.py          # URI 计算（§6.3）
├── config/                    # 集中配置（§7.4）
│   ├── filter.yaml
│   ├── subsystems.yaml
│   ├── budget.yaml
│   ├── units.yaml
│   ├── thresholds.yaml
│   ├── Dockerfile.eval
│   └── prompts/               # locator/repair prompt 模板（附录 B）
└── reports/                   # 每轮报告（JSON + Markdown，§7.5）
```

### 7.4 集中配置清单（`config/`，版本化）

| 文件 | 内容 | 归属模块 |
|---|---|---|
| `filter.yaml` | §3.1 筛选参数 | pipeline |
| `subsystems.yaml` | §3.1 子系统路径规则 | pipeline |
| `budget.yaml` | §4.2/§5.3 预算（超时/轮次/工具调用/测试次数） | runners |
| `prompts/` | locator/repair prompt 模板（附录 B） | runners |
| `units.yaml` | §1.2.3 测量网格定义（单元 ↔ 层映射） | scoring |
| `thresholds.yaml` | 捷径依赖率 30%、效度合格线 r≥0.5、URI 分档 | scoring/report |

**变更规则**：任何配置变更 → bump `config_version` 写进报告头；同版本配置下的分数才可直接横向对比。

### 7.5 报告格式（`reports/<layer>_<YYYYMMDD>.json` + Markdown 渲染）

```jsonc
{
  "run_id": "L2-2026-08-23",
  "config_version": 7,
  "harness": {"agent": "opencode", "opencode_version": "x.y.z",
              "model": "...", "model_fingerprint": "calib-5task-hash",
              "tools_config": "hash", "lsp_version": "...",
              "toolchain": {"codegraph": true, "graphify": true,
                            "openviking": "mcp-only", "comet_mode": "classic-full",
                            "indexes_rebuilt": true, "ov_namespace": "eval-<run_id>"},
              "prompt_version": 3, "budget_version": 2,
              "task_subset_hash": "..."},
  "image_digest": "sha256:...",              // L2 必填
  "tasks": [{"id": "FW-0001", "unit": "O5,K3", "demand": "S2",
             "difficulty": "HARD", "build_config": "sku_a_nand_micron",
             "verdict": "resolved", "f2p": {}, "p2p": {},
             "workflow": {"phases_reached": ["open","design","build","verify","archive"],
                          "guard_failures": [], "tdd_cycles": 5, "auto_approved_points": 3},
             "trajectory": {}, "tokens": 12345, "failure_fingerprint": "REASON"}],
  "metrics": {"resolved": 0.24, "wilson_ci": [0.15, 0.35],
              "by_unit": {}, "by_subsystem": {}, "by_difficulty": {"EASY": {}, "HARD": {}},
              "shortcut_rate": 0.28, "bcy": {"1k": {}, "2k": {}, "4k": {}, "8k": {}},
              "rel_eff": {}, "fuh": 0.6,
              "component_attribution": {"codegraph": {"hitfile_gain": 0.35, "resolve_gain": 0.08},
                                        "graphify": {"hitfile_gain": 0.15, "resolve_gain": 0.03},
                                        "openviking": {"hitfile_gain": 0.05, "resolve_gain": 0.01}},
              "index_rebuild": {"success_rate": 1.0, "avg_sec": 120},
              "tool_tokens": {"graphify": 0, "openviking": 0, "codegraph": 0}},
  "regression_check": {"vs_run": "L2-2026-07-25", "method": "mcnemar+holm",
                       "significant_drops": ["(O1,K5)"],
                       "detectable_min_delta": "≥15pp @ n=50"}
}
```

Markdown 渲染版即 §8 看板 + 明细附录。**JSON 为事实来源**，长期归档（`reports/archive/`）。

---

## 8. 能力矩阵看板（最终输出形态）

每轮评估生成统一看板：

| 单元 | L1 定位 (HitFile/CE) | L2 修复 (%Resolved) | L3 鲁棒性 (URI) | 趋势 |
|---|---|---|---|---|
| (O1,K1) 命令/协议定位 | 0.82 / 0.51 | 34% | 0.08 | ↑ |
| (O1,K5) 配置定位（SKU/特性） | 0.58 / 0.24 | 15% | 0.41 | ↓ |
| (O2,K2) 模块依赖追踪 | 0.71 / 0.38 | 22% | 0.21 | → |
| (O2,K3) 命令链/中断路径 | 0.65 / 0.30 | 18% | 0.34 | ↓ |
| (O5,K3) 超时/复位诊断 | 0.75 / 0.41 | 28% | 0.15 | ↑ |
| (O6,K1) 契约保持修改 | — | 26% | 0.19 | → |
| **汇总**（S2/S3 加权） | **0.70 / 0.36** | **24%** | **0.23** | — |

附注：本季"捷径依赖率"（S0/decoy 任务）28% —— 略低于告警阈值 30%，但已进入监控；若下季 >30%，汇总得分可信度须下调标注。**趋势箭头仅在配对检验（McNemar+Holm，§5.5）显著时显示**，否则显示 "—"。本季检出能力下限：n=50 时 ≥15pp（单轮绝对分数只作趋势判断，不做精确排名）。

**组件贡献**（本季消融，§4.7）：

| 组件 | L1 HitFile 增益 | L2 解析率增益 | 与主力映射预期（§1.2.3） |
|---|---|---|---|
| codegraph | +0.35 | +8pp | ✅ 符合（(O1,K1)/(O2,K3) 主力） |
| graphify | +0.15 | +3pp | ⚠️ (O4,K2) 上未达预期，待查集成 |
| openviking | +0.05 | +1pp | — 记忆层本季贡献有限 |

**看板用途**：①模型/配置升级回归检测（McNemar 显著 + 按难度分层，§5.5）；②**组件级决策**：哪个工具值得继续投入/需要修集成（§4.7 归因）；③定位团队最该补的上下文工程（如 (O1,K5) 配置定位弱 → 把 NAND/SKU 配置矩阵与特性开关注入 agent 上下文）；④向管理层汇报"理解能力"的量化依据（附功效下限声明）。

---

## 9. 里程碑与工作量

| 里程碑 | 内容 | 预计工期 | 验收标准 |
|---|---|---|---|
| **M1** | Layer 1 PoC：挖掘 30 候选 → 过门禁 20 任务 → 跑通定位评估（先 no-tool 与 full 两组建基线） | 1 周 | 产出首份 L1 报告，按 (O×K) 单元与需求强度标注可读 |
| **M2** | 数据流水线定型：筛选规则调优 + 任务库（L1 50+ / L2 首批 25）+ 工具索引重建（§5.8）接入 | 3 周 | verify_baseline 门禁全绿，索引重建成功率 100%，难度预校准完成 |
| **M3** | Layer 2：Docker 镜像（含 COMET-Classic）+ 全流程 runner + 判定闭环 | 3 周 | 25 任务 %Resolved 出数，工作流失败指纹（PHASE_*）可分类 |
| **M4** | Layer 3 扰动 + 组件消融（§4.7）：扰动算子 + URI + 5 组消融 + 因果 seed | 2-3 周 | URI 与组件贡献表出数，能区分真理解/模式记忆，组件归因可用 |
| **M5** | 看板 + CI 编排 + 回归检测固化（McNemar+Holm） | 1 周 | 变更自动触发，看板含组件贡献与功效下限声明 |

总计约 **2.5 个月**铺满三层（Classic 全流程比原估算重，M2/M3 各 +1 周）；M1 两周内可拿到首个定位基线。

---

## 10. 风险与局限

| 风险 | 缓解 |
|---|---|
| **数据污染**：模型见过这些历史 commit | 优先训练截止后的 commit；结果只做相对比较；必要时用 3.3 的描述改写 |
| **测试质量问题**：F2P 测试写得弱 → 区分度低 | verify_baseline 强制红/绿；人工抽检 10% 任务 |
| **硬件相关 bug 无法 host 端验证** | 过滤需真机验证的 commit；Ceedling mock 能覆盖的优先 |
| **harness×模型混杂** | 固定 opencode + 固定 prompt + 固定预算；报告必须带 token 成本 |
| **样本量不足** | 50 任务给 Wilson 区间；关键结论看趋势不看单点 |
| **内网镜像/依赖缺失** | 提前备份 Docker 镜像与 gem/npm 内网源；镜像用内网 registry |
| **扰动快照编译失败** | 每个扰动版本过"可构建"校验，失败即丢弃该扰动样本 |
| **工具索引与快照不同步**（v1.5 评估正确性） | §5.8 强制按 base 快照重建；`INDEX_FAIL` 降级为 no-tool 组重跑 |
| **openviking 记忆污染任务库**（v1.5） | §5.9 命名空间隔离 + 轮次隔离 + 复跑一次性规则 |
| **COMET 全流程无法自动化**（decision-point 阻塞） | auto-approve 配置 + PHASE_STUCK 指纹 + 人工复核自动批准点 |
| **工具自身 token 成本被忽略** | 成本表含 graphify 建图/蒸馏 tokens；报告附工具 token 分账（§7.2） |
| **工具价值随模型变化** | 组件消融（§4.7）模型变更时必跑，防"工具失效仍按旧结论投入" |

---

## 附录 A：机制依据（设计来源）

- **SWE-bench**（ICLR 2024）：F2P/P2P 双重执行判定、%Resolved、数据集构造流水线
- **SWE-PolyBench**（Amazon）：CST 节点级检索指标（文件/节点 retrieval Precision/Recall），把"导航理解"量化
- **SWE-Explore**：轨迹蒸馏 line-level ground truth；Context Efficiency（r=0.95 相关修复）等指标
- **CORE-Bench / Agent Retrieval Bench**：需求驱动的仓库检索评估；BCY（预算上下文产出）
- **RepoMirage**：语义保持扰动诊断"真理解 vs 表面成功"；解析率 66.8%→25.3% 实证
- **The Scaffold Effect in Coding Agents**（2026）：harness 为隐藏变量，40× token 差异 → 强制固定 harness
- **DeepSWE**：pass@1/pass@4、人工功能验证器、分歧率审计（判据可靠性）

---

## 附录 B：Agent Prompt 模板

> prompt 头为**固定版本**，任何修改必须进 changelog；评估时 prompt = 固定头 + 任务描述。

### B.1 Locator（L1 用，与 §4.2 配置一致）

```
你是固件代码定位器。给定一个问题描述，在仓库中找到与问题最相关的代码区域。

规则：
1. 只使用检索类工具（grep/read/glob/符号跳转），禁止修改任何文件
2. 输出必须是严格的 JSON 数组，每个元素：
   {"file": "相对路径", "start": 行号, "end": 行号, "reason": "一句话理由"}
3. 按相关度从高到低排序，最多 10 个
4. 若无法判断，输出空数组 []
```

### B.2 Repair（L2 用，固定头）

```
你是固件代码修复工程师。给定问题描述与仓库，修复问题。

规则：
1. 可自由使用检索与编辑工具，可运行构建/测试命令验证
2. 只修改与问题直接相关的代码，不重构无关代码
3. 禁止修改 test/ 目录下的任何测试文件
4. 完成后确认修改能通过相关测试
```

调用约定：`session_prompt = 固定头 + "\n\n## 任务\n" + problem_statement`。

---

*本设计为 v1.5，随 M1 PoC 结果迭代。所有指标口径、prompt 模板、任务库版本变更需记录 changelog，保证历史分数可比。*

---

## Changelog

| 版本 | 日期 | 变更 |
|---|---|---|
| v1.0 | — | 初版：D1-D6 单轴维度定义 |
| v1.1 | 2026-08-23 | **重设计 §1.2（核心）**：D1-D6 单轴 → 双轴正交框架（认知操作 O1-O6 × 知识对象 K1-K7）；新增理解需求强度 S0-S3（仅 S2/S3 计入得分）、三通道证据（结果/过程/鲁棒性）、判别有效性设计（decoy + 捷径依赖率）、效度验证程序（收敛/判别/预测）；测量网格定为 11 个 (O×K) 单元；任务 JSON 新增 `unit`/`demand` 字段；§4.3/§5.4/§6.1/§8 同步改用单元引用 |
| v1.2 | 2026-08-23 | **目标代码库特化为 UFS 固件**：知识对象轴 K1-K7 实例化为 UFS 域对象（UPIU/CDB 契约、L2P/GC/掉电现场、SKU/NAND 配置、门铃/DMA/性能路径、缓冲所有权）；测量网格 11 单元全部换为 UFS 代表任务；新增 §5.1.1 UFS 可测性边界（时序/竞态类 bug 不入 L2）；挖掘流水线新增 UFS 子系统标签与任务库均衡；§6.4 诊断任务改为 UFS 专项（命令队列状态机/掉电保护/L2P 一致性/GC 并发/性能热路径） |
| v1.2.1 | 2026-08-23 | §3.0 新增"数据流与三层复用"关系图（git 历史 → 任务库 → L1/L2/L3 → 能力矩阵），并标注各层对应证据通道（过程/结果/判别） |
| v1.3 | 2026-08-23 | **补齐到"照此可实现"粒度**：§3.1 筛选参数表+正则规格+子系统路径规则；§3.2 任务 ID 方案+完整字段规格表+类型配额；§3.4 基线校验操作序列；新增 §3.6 gold 提取算法、§3.7 任务库目录规范、§3.8 人工抽检规则；§4.2 locator agent 配置与权限示例；§4.3 行区间判定/归一化/CE/nDCG 精确公式；新增 §4.5 轨迹过程证据解析；§5.2 完整 Dockerfile+镜像维护规则；§5.3 repair runner 伪代码+固定约束表+补丁提取规则；§5.5 Wilson CI 公式；新增 §5.6 执行判定规则（与门禁共用）；§6.1 扰动算子实现规格；§6.2 扰动任务选择与统计；新增 §6.5 扰动语义保持校验门禁；§7.3 仓库布局补全；新增 §7.4 集中配置清单、§7.5 报告 JSON schema；新增附录 B prompt 模板 |
| v1.4 | 2026-08-23 | **双源评审（自审+Oracle）后全面修订**：①配对统计——§5.5 新增 McNemar+Holm 替代 CI 不重叠（配对功效说明）、功效下限诚实声明、难度分层；②效度去循环——§1.2.7 改为固定参考集预校准+被测 agent 解耦、预测效度 n≥30（Kendall τ）；③§5.7 新增 L1→L2 因果链 seed 实验（三条件+四象限诊断）；④`build_config`/`difficulty` 入任务 JSON（UFS 多配置正确性+难度预校准）；⑤§4.3 CE 废弃→BCY@B 预算曲线+REL-eff 相对效率；⑥§3.6 gold 三档（file/function/line，函数档为主）；⑦§4.6 新增基线检索器对照（BM25/符号图/grep，理解增益口径）；⑧§3.5 任务轮换+季度 20% 新任务；⑨§4.2/§5.3 工具调用次数为主预算（抗资源争用）；⑩§3.3 prompt 防泄漏校验器；⑪§7.2 成本预算表；⑫§7.5 报告 schema 补全指纹/难度/BCY；⑬§8 趋势箭头仅显著时显示 |
| v1.5 | 2026-08-23 | **按实际辅助编程方案定制（工具链系统）**：①新增 §1.3 被测系统定义（单体 agent → 工具链系统：COMET-Classic 全流程 + Superpowers + codegraph/graphify/openviking），对比轴改为"模型×工具链配置×工作流"，5 组消融矩阵；②§1.2.3 增组件主力映射；③新增 §4.7 组件消融定位评估（边际贡献/单独贡献双口径，配对检验+Holm）；④§5.1 评估协议改为 COMET Classic 全流程（open→design→build→verify→archive），decision-point auto-approve、失败指纹扩展（PHASE_STUCK/PHASE_SKIP/NO_BRAINSTORM/SPEC_DRIFT）、数据集降至 20-30 任务；⑤§5.3 增 COMET 集成说明；⑥§5.4 增工作流产物通道（proposal/design/tasks/守关/TDD）+组件归因；⑦§5.7 因果链 seed 升级为工具链组合（含单组件-seed 组件级因果）；⑧新增 §5.8 工具-索引同步（codegraph/graphify/openviking 按快照重建+INDEX_FAIL 降级）、§5.9 openviking 记忆隔离（命名空间/轮次/复跑规则）；⑨§6.1/§6.5 扰动须重建工具索引（测工具链自适应）；⑩§7.2 成本表按 Classic 全流程重算+工具 token 分账；⑪§7.5 报告 schema 增 toolchain/workflow/component_attribution/index_rebuild；⑫§8 看板增组件贡献行；⑬§10 风险表增工具链 5 项 |
