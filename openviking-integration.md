# OpenViking 部署与接入使用说明

版本：2.0
日期：2026-08-12
适用：任何需接入 OpenViking 作为 AI Agent 上下文知识库的工程系统
对应架构：2222.md §8.3（工程经验知识库）+ §35（Knowledge Plane）

> 本文档为**平台无关**部署指南——可在任意环境（新机器/容器/服务器）按本文部署 OpenViking 并接入 AI 工程系统。文中的命令、配置、数据结构均可直接复用，不依赖任何特定部署环境。

---

## 1. OpenViking 是什么

**AI Agent 上下文数据库**（火山引擎 volcengine/OpenViking，开源，~28k stars）。统一管理三类上下文，通过 `viking://` 虚拟文件系统 + L0/L1/L2 分层 + 向量检索，为 Agent 提供"记得住、找得到"的知识。

### 1.1 核心机制

```
viking:// 虚拟文件系统
  ├── resources/   # 客观知识库（ADR/Bug/Lesson/规范文档）
  ├── user/        # 用户私有
  └── agent/       # 全局能力/技能

L0 摘要（~100 tokens）→ L1 概览（~2k tokens）→ L2 完整内容
渐进加载：先摘要过滤 → 概览导航 → 按需读全文
```

### 1.2 五大功能块

| 功能块 | 作用 | 关键命令/工具 |
|---|---|---|
| 知识摄入（Ingest） | 把文件/URL/仓库/网站变成 viking:// 资源 | `ov add-resource`、`ov write`、`add_resource`（MCP） |
| 知识存储（Storage） | 三类上下文 + L0/L1/L2 分层组织 | `viking://` FS、`ls/tree/mkdir/rm/mv/stat` |
| 检索获取（Retrieval） | 语义 + 确定性两条检索路线 | `ov find`/`search`、`grep/glob/tree`、L0→L1→L2 渐进加载 |
| Agent 协作（Interaction） | Agent 读写上下文、会话管理 | `ov chat/session/compile/remember`、MCP 16 工具 |
| 系统管理（Admin） | 配置、索引、备份、账户、运维 | `ov config/reindex/export/backup/admin/observer` |

---

## 2. 部署准备

### 2.1 环境要求

| 项 | 最低 | 建议 | 说明 |
|---|---|---|---|
| Python | 3.10+ | 3.12 | openviking 是 Python 包，~60 个依赖（fastapi/uvicorn/tree-sitter×11 语言/llama-cpp-python/litellm 等） |
| CPU | 2 核 | 4 核 | embedding 本地推理 + tree-sitter 解析 |
| 内存 | 2G | 4-8G | embedding 模型（GGUF ~200M）+ 服务进程 |
| 磁盘 | 1G | 10G+ | 模型 + 向量库 + 解析缓存（随数据量增长） |
| 端口 | — | 1933 | REST API + MCP 端点 + Web 管理台三合一 |
| 网络 | — | 出网 | 首次下载 embedding 模型 + VLM API 调用 |

### 2.2 安装（三选一）

```bash
# A. Python 包（推荐，可控性最好）
python3 -m pip install --user openviking     # 或 uv tool install openviking

# B. Docker（推荐独立服务，生产）
mkdir -p ~/.openviking && touch ~/.openviking/ov.conf
docker run -d --name openviking \
  -p 1933:1933 \
  -v ~/.openviking:/app/.openviking \
  ghcr.io/volcengine/openviking:latest

# C. 云托管（火山引擎，免运维）
# 控制台开 API Key，端点 https://api.vikingdb.cn-beijing.volces.com/openviking
```

> ⚠️ llama-cpp-python 需要编译工具链（gcc/cmake）或预编译 wheel；建议用 `uv` 加速依赖安装。

### 2.3 模型准备（两块，必选其一）

**A. Embedding 模型（必选，检索依赖）**：

| 方案 | 模型 | 准备 |
|---|---|---|
| 本地离线（推荐） | `bge-small-zh-v1.5-f16.gguf`（~46M） | 首次启动自动下载到缓存目录；离线环境手动放置 |
| 云端 API | `text-embedding-3-small` 等 | 配置 api_base + api_key |

**B. VLM 模型（强烈建议，L0/L1 摘要生成用）**：
- 需要 LLM API Key（豆包/OpenAI/Ollama 任一）
- 无 VLM 也能跑，但 `add-resource` 时摘要生成会失败或跳过，检索质量下降

### 2.4 初始化配置

```bash
openviking-server init
# 交互式：选 embedding provider + VLM provider + 存储路径
# 生成 ov.conf（示例见下）
```

参考配置：

```json
{
  "embedding": {
    "dense": { "provider": "local", "model": "bge-small-zh-v1.5-f16", "dimension": 512 }
  },
  "vlm": { "provider": "openai", "model": "gpt-4o-mini" },
  "storage": { "workspace": "~/.openviking/data" },
  "server": { "host": "127.0.0.1", "port": 1933 }
}
```

### 2.5 启动与验证

```bash
# 启动（开发/生产）
openviking-server --host 127.0.0.1 --port 1933        # 前台
nohup openviking-server --host 0.0.0.0 --port 1933 &  # 后台（生产，需配认证）

# 验证
ov health    # 连接健康
ov status    # 组件健康表（queue/vikingdb/models/filesystem/retrieval）
```

> ⚠️ `--host 0.0.0.0` 对外暴露时必须配置 API Key 认证（开发模式默认无鉴权）。

---

## 3. Embedding 模型功能说明

### 3.1 核心机制：文档/查询双向量

**bge 类模型的关键设计**——文档和查询用不同向量模式：

```python
embed(content, is_query=False)   # 文档侧：直接编码
embed(text,  is_query=True)      # 查询侧：加指令前缀再编码

# bge-small-zh 的查询指令
DEFAULT_BGE_ZH_QUERY_INSTRUCTION = "为这个句子生成表示以用于检索相关文章："
```

**为什么重要**：bge 训练时查询侧加指令前缀能显著提升检索效果。**查询侧不加前缀 → 查询向量与文档向量不对齐 → 检索失败（零结果）**。这是 `find` 零结果的常见根因之一。

### 3.2 支持的 Provider（按需切换）

```
本地:  local（GGUF 离线，默认）/ litellm（多模型网关）
云端:  openai / gemini / cohere / jina / voyage / minimax
火山系: vikingdb / volcengine / dashscope（豆包）
```

切换只需改 `ov.conf` 的 `embedding.dense.provider`。

### 3.3 向量类型：Dense / Sparse / Hybrid

EmbedResult 支持三种向量：

```python
vector: List[float]              # dense 稠密向量（语义相似）
sparse_vector: Dict[str, float]  # sparse 稀疏向量（精确词匹配，如 BM25 风格）
# is_sparse() / is_hybrid()      # 可检测
```

- **Dense**：语义（"为什么 75%" ↔ "保护 host latency"）
- **Sparse**：精确词（"gc_threshold" ↔ 文档出现该词）
- **Hybrid**：融合，兼顾语义与关键词

> ⚠️ **sparse 默认关闭**（`sparse_weight=0.0`）。对代码仓库建议开启——符号名（`gc_power_off`）靠精确匹配更准。

### 3.4 模型选择

| 场景 | 推荐 | 备注 |
|---|---|---|
| 通用文档（中文） | bge-small-zh-v1.5（512 维） | 默认，离线免费 |
| 更高精度（混合语言） | bge-m3（1024 维） | 多语+长文本 |
| 云端统一 | text-embedding-3-small/large | 维度可裁剪 |
| **代码检索** | **见 §5.3 代码专用模型** | bge 系列对代码弱 |

---

## 4. CLI 快速上手（ov 命令）

### 4.1 配置与连接

```bash
ov language zh-CN
ov health                     # 连接健康检查
ov status                     # 系统状态
ov config list                # 配置列表
```

### 4.2 写入知识条目

```bash
# 导入本地文件/目录（推荐批量同步）
ov add-resource ./07_knowledge --parent viking://resources/<project> --wait

# 直接写内容（单条写入）
ov write viking://resources/<project>/adr/ADR-2026-001.md --content "..."

# 导入 URL/Git 仓库
ov add-resource https://example.com/spec.md --to viking://specs/api.md
```

### 4.3 查询知识

```bash
# 语义检索
ov find "gc_threshold 为什么保持 75%" --uri viking://resources

# 确定性检索（不烧 token）
ov grep "threshold" --uri viking://resources
ov glob "**/ADR/*.md" --uri viking://resources
ov tree viking://resources -L 2
ov read viking://resources/<project>/adr/ADR-2026-001.md
```

### 4.4 维护

```bash
ov reindex viking://resources --mode vectors_only --wait true   # 只重建向量
ov reindex viking://resources --mode semantic_and_vectors       # 全量重建
ov status --verbose          # 组件健康表
ov observer models           # 模型调用情况
```

---

## 5. 代码仓库向量化指南（重点）

### 5.1 OpenViking 的代码处理机制（源码级）

对代码仓库（`is_code_repo=true`）OpenViking 的处理流程：

| 环节 | 实现 | 影响 |
|---|---|---|
| 分块 | **不 chunking**，文件级整体映射，L2 存完整文件 | 保留上下文，但大文件向量化截断 |
| L0/L1 摘要 | 代码文件走 **AST skeleton 提取**（tree-sitter），非 LLM | 摘要是符号列表（`def func_name()`） |
| 向量化文本 | `use_summary=true` → `summary_only` → 向量化符号列表而非代码 | 对通用模型语义稀疏 |
| 检索层级 | 全局向量搜索只查 **level=[0,1]**（摘要层），L2 靠目录递归 | L0/L1 向量缺失 = 永远到不了文件 |
| sparse | `sparse_weight=0.0` 默认关闭 | 符号精确匹配没开 |

**核心矛盾**：代码是英文符号（`gc_xxx`/`nand_xxx`），若用中文文本模型（bge-small-zh）向量化**纯符号列表** → 语义稀疏 → 中文查询对不上 → 零结果。这是代码仓库检索失败的结构性根因。

### 5.2 代码检索零结果排查顺序（P0）

| 检查 | 命令/动作 | 对应问题 |
|---|---|---|
| 1. 索引一致性 | `ov system consistency viking://resources/<repo> -o json` | 摘要层向量缺失 |
| 2. 阈值测试 | `ov find "<确切符号名>" -t 0`——t=0 有结果说明是阈值问题 | 阈值过严 |
| 3. 脏状态 | 重建 vectordb 上下文目录 | 索引与存储失配 |
| 4. 版本 | 确认含已知 bug 修复（损坏 JSON 静默空召回、维度自动重建） | 版本过旧 |
| 5. 全量重建 | `ov reindex --mode semantic_and_vectors --wait true` | 索引陈旧 |

### 5.3 模型选择：代码专用 vs 通用

**基准数据**（CoIR/CoREB 代码检索基准）：

| 模型 | 类型 | 代码检索能力 | 备注 |
|---|---|---|---|
| **jina-code-emb-0.5b/1.5b** | 代码专用（开源） | ✅ 0.585/0.600 | 可 GGUF 化本地跑，**首选** |
| **CodeSage-large-v2** | 代码专用（开源） | CoIR 64.18 | Meta，1k token 限制 |
| **Voyage-Code-3** | 代码专用（API） | 超 OpenAI-v3-large 13.8% | 商业最强 |
| CodeXEmbed-2B/7B | 代码专用（开源） | 67.41/70.46 | 2024 |
| BGE-M3 | 通用 | 39.31 | 中游，非代码专用 |
| **bge-small-zh-v1.5** | 通用中文文本 | 无代码专项能力 | 对英文代码符号弱 |

**结论**：
1. 代码专用模型在 code-to-code 检索约 2× 于通用模型
2. **短关键词查询（开发者真实搜索方式）把所有模型打到近零 nDCG@10**——语义检索不适合精确符号定位
3. **C 语言是薄弱点**：多数代码模型训练集以 Python/Java/JS 为主，嵌入式 C + 宏定义覆盖差

**换模型后必须全量重建索引**（向量空间变了，旧向量作废）。

### 5.4 分块策略（社区结论）

```
函数级 chunk（首选，覆盖 80% 查询）
类级（整块 + 方法子块带类签名前缀）
文件级（小文件/配置文件）

关键规则:
  - 永不切在函数中间
  - chunk 头比 chunk 本身重要: 前置 "文件路径 → 类 → 函数签名"
  - 大函数二次切分保留签名+docstring 作前缀
  - 重叠对代码有害（同一方法出现在两个 chunk = 噪音）
  - 稳定 ID 用全限定名（FQN）不用 UUID（重索引时覆盖而非残留）
```

**OpenViking 的"不 chunking"是优点**——保留完整文件上下文。问题不在分块，在向量化文本选了什么。

### 5.5 富化向量化文本（+15~25% 检索提升）

社区标准做法——代码嵌入前加自然语言锚点：

```python
def create_enriched_embedding_text(chunk):
    parts = []
    parts.append(f"File: {chunk.file_path}")              # 路径给项目结构上下文
    parts.append(f"{chunk.chunk_type}: {chunk.name}")      # 类型+名字
    if chunk.docstring:
        parts.append(f"Description: {chunk.docstring}")    # docstring 是金矿
    if chunk.signature:
        parts.append(f"Signature: {chunk.signature}")      # 签名 = 接口
    parts.append(f"Code:\n{chunk.content}")
    return "\n".join(parts)
```

**为什么有效**：docstring/路径/签名是"自然语言桥"——embedding 模型靠它理解代码意图。`gc_check_threshold` 对通用模型没意义，但 docstring "触发 GC 回收" 有意义。

### 5.6 混合检索（代码场景必须）

社区共识：**纯向量检索在代码上不够**，必须 hybrid：

```
dense（语义）:  "怎么处理重试逻辑" → 语义相近代码
sparse/BM25（精确）: "gc_threshold" → 精确符号名匹配
```

原因：代码查询分两类——语义查询（"处理支付失败重试"）→ dense 好；**标识符查询（"PaymentProcessor 类在哪"）→ 必须精确匹配**，向量相似度会给错误的相关函数。

**OpenViking 操作**：`vectordb.sparse_weight > 0`（默认 0）→ 符号查询立即改善。

### 5.7 Rerank：谨慎引入

- 社区基准（CoREB）实测：**通用 reranker 对代码可能反效果**（Jina Reranker v2 在 code-to-text 上 -22.4%）
- OpenViking 内置 rerank 适配器但只是锦上添花（失败自动 fallback 向量分）
- **先修底层检索质量，再考虑 rerank**；若引入用代码领域 reranker

### 5.8 增量索引（大仓库必须）

```
全量重建 = 灾难（10 万文件要几小时）
增量: git diff 变更文件 → 只重嵌变更部分（ov watch / 提交后触发）
```

### 5.9 并发控制（CPU 绑定场景的调优）

向量化存在两层并发，需区分对待：

**层 1：语义处理调度器（SemanticNodeScheduler）**
```python
# 控制同时向量化几个节点/文件
class SemanticNodeScheduler:
    def __init__(self, max_workers: int):
        self._max_workers = max(1, max_workers)
```
- 并发太高 → CPU 争抢 → 每个都慢 → 总吞吐反而降
- **本地 GGUF（CPU 绑定）场景：并发数 ≈ 物理核数最优**，超了纯开销

**层 2：llama-cpp 模型推理线程**
```python
# 本地 embedding 加载（当前实现未显式传线程参数，用 llama-cpp 默认 = 物理核数）
llama_cls(model_path=..., embedding=True, verbose=False)
# 如需限制：改源码传 n_threads / n_batch（谨慎，改核心）
```

**判断标准：看 embedding 是 CPU 密集型还是 IO 密集型**

| 场景 | 并发策略 |
|---|---|
| 本地 GGUF（bge 等，CPU 绑定） | **并发数 ≈ 物理核数**，限制有益 |
| 云端 API（openai 等，网络 IO） | 并发高更快（等待不占 CPU），**限制反而有害** |

**实操**：
```bash
nproc    # 确定物理核数（假设 8 核）→ 语义处理并发设 4-8，别超
```

**重要提醒**：并发调优是最后手段。真正的大头是：
1. **模型大小**：bge-small（46M）vs bge-m3（~2G）——推理速度差几十倍
2. **量化**：GGUF f16 vs q8/q4——量化后 CPU 快 2-4 倍（质量略降，代码检索影响小）
3. **增量索引**：只嵌变更文件，比任何并发调优都有效
4. **嵌入文本长度**：文本越短越快（skeleton 摘要比全文快）

### 5.10 输入截断处理（大文本向量化）

**截断机制（源码确认）**：

```
embedding_utils.truncate_embedding_input:
  - 用 CJK 估算器估算 token（CJK 字符=1 token，其他每 4 字符=1）
  - 超过 max_input_tokens → 二分截断 + 加截断后缀标记

max_input_tokens 来源:
  - embedder config 的 embedding.dense.max_input_tokens
  - 未配置则用默认（4096）

⚠️ 关键矛盾:
  bge-small-zh-v1.5 模型真实上下文 = 512 tokens（模型本身限制）
  但默认 max_input_tokens = 4096
  → 文本截到 4096，llama.cpp 实际只处理前 512 → 更早截断
```

**后果**：大文件被截断且只保留**开头** 512 tokens（可能是 imports/注释，不是核心逻辑）——信息丢失且丢得不是地方。

**四种处理方案（按优先级）**：

**方案 A：分块后嵌入（根本解法）**
```yaml
大文件先切块再向量化，每块 < 模型上下文:
  代码: 按函数/类切块（AST 感知），每块 ≤ 512 tokens
  文档: 按 section 切块，每块独立条目
优点: 不截断 + 检索更准（函数级/节级命中）
注意: OpenViking 代码仓库默认不 chunking（文件级整体）→
      大文件会被截断；需预处理拆分后再 add-resource
```

**方案 B：调 max_input_tokens（配置层）**
```json
{
  "embedding": {
    "dense": {
      "provider": "local",
      "model": "bge-small-zh-v1.5-f16",
      "dimension": 512,
      "max_input_tokens": 512
    }
  }
}
```
注意：值应与模型上下文匹配（bge-small-zh=512）。**调大无效**——模型本身只处理 512，调大只会让截断发生在 llama.cpp 内部（静默）而非 OpenViking 显式层（有后缀提示）。

**方案 C：换长上下文模型（处理大块）**

| 模型 | 上下文窗口 | 适合 |
|---|---|---|
| bge-small-zh-v1.5 | 512 tokens | 小块文本 |
| bge-m3 | 8192 tokens | 长文档 |
| jina-code-emb-1.5b | 8192 | 代码长块 |
| voyage-code-3 | 32k tokens | 超长代码 |

长文档知识（ADR/规范）场景：512 是硬瓶颈——换 bge-m3 或长上下文代码模型是正解。

**方案 D：嵌入"摘要/富化文本"而非全文**
```
代码: skeleton 摘要（短，天然不截断）→ 但语义稀疏（§5.3 模型问题）
     富化摘要（路径+签名+docstring，短）→ 最佳平衡（§5.5）
文档: 全文截断（丢结尾）→ 分块 或 换长上下文模型
```

**场景速查**：

| 场景 | 问题 | 解法 |
|---|---|---|
| 代码仓库大 .c 文件 | 被当全文嵌入 → 截断到开头 imports | 走代码仓库路径（skeleton 摘要）或函数级切块 |
| 长文档（ADR/规范） | 512 装不下 | 换 bge-m3（8192）或分块 |
| 混合（代码+文档） | 一个模型难兼顾 | 配两个 embedder（短摘要模型 + 长上下文模型） |

---

## 6. MCP 接入（agent 获得工具能力）

服务器内置 MCP 端点 `<server-url>/mcp`，同端口同进程。

### 6.1 OpenCode 配置

```json
{
  "mcp": {
    "openviking": {
      "type": "remote",
      "url": "http://<server-host>:1933/mcp",
      "enabled": true,
      "headers": { "Authorization": "Bearer <api-key>" }   // 无鉴权本地可省略
    }
  }
}
```

### 6.2 MCP 暴露的工具（16 个）

| 类别 | 工具 | 用途 |
|---|---|---|
| 检索 | `find` / `search` / `recall` | 语义检索 |
| 文件系统 | `read` / `list` / `tree` / `grep` / `glob` | 确定性定位 |
| 写入 | `write` / `edit` / `remember` / `add_resource` / `forget` | 发布知识 |
| 管理 | `list_watches` / `cancel_watch` / `health` | 运维 |

### 6.3 与组合工具对接

```
knowledge-query（组合工具）内部:
  find 语义检索 → grep/glob 确定性定位 → read 渐进加载
publish-knowledge（组合工具）内部:
  add_resource 导入 ADR/lesson → reindex → 回查确认可检索
```

---

## 7. 目录规范建议（工程经验知识库）

```yaml
# 固定目录规范（所有 ADR/bug/lesson 统一落点）
viking://resources/<project>/
  ├── adr/ADR-YYYY-NNN.md
  ├── bugs/BUG-YYYY-NNN.md
  ├── lessons/LESSON-YYYY-NNN.md
  └── reviews/
```

与决策追溯机制的 locator 对应：`[E:viking:ADR-2026-001]` 对应 `viking://` URI 语义，天然吻合。

---

## 8. UFS 固件仓库 + Comet 工作流使用技巧

本节针对**嵌入式 UFS 固件仓库**（C 代码、gc/power/recovery/nand 高危模块、长生命周期、经验强依赖）在 **Comet 五阶段工作流**（Open → Design → Build → Verify → Archive）中的 OpenViking 使用方式。

### 8.1 核心心智模型

OpenViking 在 Comet 流程中的定位：**Archive 阶段沉淀经验，后续 Feature 的 Open/Design 阶段检索复用**——形成经验闭环：

```
Feature A Archive → 经验入库（ADR/Bug/Lesson）
                      ↓
Feature B Open/Design → 检索 Feature A 经验（为什么/有没有坑）
                      ↓
Feature B Archive → 新经验入库
                      ↓
                    循环强化
```

**关键原则**：OpenViking 是"读多写少"的检索库——**写入集中在 Archive 阶段（受控沉淀），读取分散在 Open/Design/Build（按需查询）**。不要在开发中途随意写入，避免知识库污染。

### 8.2 Comet 各阶段使用矩阵

| 阶段 | OpenViking 用法 | 典型命令/工具 | 注意事项 |
|---|---|---|---|
| **Open** | 检索历史经验辅助影响预判（"以前改过这个模块吗？有什么坑？"） | `knowledge-query`（find + grep + read） | 高危模块（gc/power/recovery/nand）先查历史 bug |
| **Design** | Expert 查设计原因（"为什么 75%？以前为什么不能改？"） | find 语义检索 + read 读 ADR 全文 | 专家结论的 knowledge evidence 必须引用 OpenViking ID |
| **Build** | 检索同模块历史实现/workaround | grep 符号名 + read | 不写入；发现新坑记录到 gap 待 Archive 沉淀 |
| **Verify** | 检索历史测试模式/已知失败路径 | find "recovery 测试" | 对照历史 bug 验证回归 |
| **Archive** | **集中写入**：Extractor 沉淀 ADR/Bug/Lesson | `publish-knowledge`（add_resource + reindex + 回查） | 只沉淀通过 Review 的最终决策；幂等键防重复 |

### 8.3 UFS 固件特有的知识类型与写入技巧

UFS 固件的经验沉淀应按类型分目录，且**每条必须带决策可追溯的 evidence 链**：

```yaml
viking://resources/ufs-firmware/
  ├── adr/ADR-2026-001.md      # 架构决策（为什么这么设计）
  ├── bugs/BUG-2023-017.md     # 历史 bug（症状 + 根因 + workaround）
  ├── lessons/LESSON-2026-003.md  # 经验教训（可复用的"不要这样做"）
  ├── workarounds/             # 针对特定芯片/协议版本的 workaround
  └── reviews/                 # 审查模式（同类问题审查要点）
```

**写入模板要点（固件特有）**：

```markdown
# BUG-2023-017: GC 阈值提高后 FTL 卡顿

## 现象
提高 gc_threshold 到 85% 后，批量写场景出现 host 侧 FTL 卡顿。

## 根因
[E:code:gc_policy.c:125] —— 阈值提高导致 GC 触发滞后，
空闲节点耗尽后强制 GC 阻塞 host 路径。

## 影响模块
gc / ftl / host-latency（高危）

## Workaround
保持 75% 不提高；如需提高需先做 latency 回归。

## 涉及决策
DEC-20260811-0001（decision-log.yaml 回链）
```

**关键技巧——固件 bug 条目必须包含**：
1. **芯片/协议版本**（`chip: UFS3.1, protocol: HS-G4`）——固件 bug 与硬件版本强绑定
2. **触发条件**（复现路径）——没有触发条件的历史 bug 无法复用
3. **影响的高危模块**（gc/power/recovery/nand）——检索时按高危模块过滤
4. **evidence 链**（代码行 + 决策 + 测试）——满足决策可追溯横切要求

### 8.4 UFS 场景检索技巧

**技巧 1：符号名优先用 grep（确定性），语义问题用 find（模糊）**

```bash
# 精确符号（固件函数名高度特定）→ grep 命中即准
ov grep "gc_check_threshold" --uri viking://resources/ufs-firmware

# 语义问题（"为什么保留 barrier"）→ find 语义检索
ov find "为什么 recovery path 必须保留 barrier" --uri viking://resources/ufs-firmware
```

**技巧 2：按高危模块预置检索过滤器**

```bash
# 只查 gc 相关历史（避免其他模块噪音）
ov find "GC 触发条件" --uri viking://resources/ufs-firmware/adr --uri viking://resources/ufs-firmware/bugs
# 或依赖目录结构隔离（§7 目录规范），查询按子目录收窄
```

**技巧 3：Query 混合中英文**

固件代码是英文符号、知识条目可能中英混合：
- 符号查询：英文（`gc_threshold`）→ grep 精确
- 语义查询：中文问（"垃圾回收阈值为什么 75%"）→ find（bge 中文模型）
- **混合检索**（dense+sparse 同开）对固件最有效：中文语义 + 英文符号各取所长

**技巧 4：检索结果渐进加载省 token**

```bash
ov find "GC 阈值" -L 0          # 先拿 L0 摘要（~100 tokens）筛选
ov read <命中 URI>              # 确认相关再读全文
# 不要一上来就 read 全部候选
```

### 8.5 与决策追溯机制的衔接（横切要求）

OpenViking 条目是决策追溯链的**经验证据层**：

```
design.md claim
  → decision-log.yaml DEC-xxx
  → evidence: [E:viking:BUG-2023-017]     ← OpenViking 条目
  → resolve: 查 viking://resources/ufs-firmware/bugs/BUG-2023-017.md
  → 验证: 条目存在 + 未 revoked + 版本匹配
```

**使用纪律**：
1. **引用必须可解析**——`[E:viking:XXX]` 引用的条目必须真实存在（evidence-resolve 校验），禁止引用不存在的知识 ID
2. **变更必须显式**——知识条目更新/废弃时，引用它的旧决策要重新过 Gate（§5.2 一致性检查）
3. **Archive 沉淀必须幂等**——同一决策不重复入库（幂等键：decision_id + revision + commit）

### 8.6 Comet 流程中的实际调用序列

**典型 Design 阶段 Expert 咨询序列**：

```text
1. 读取 ExpertRequest（GAP-001: 为什么 gc_threshold 是 75%）
2. knowledge-query:
   a. ov find "gc_threshold 75%" --uri viking://resources/ufs-firmware
   b. ov grep "gc_threshold" --uri viking://resources/ufs-firmware/bugs   # 精确查历史 bug
   c. ov read <命中 ADR/bug 全文>
3. impact-analysis（查当前代码影响）
4. evidence-resolve（验证引用可解析）
5. 交叉验证（历史经验 vs 当前代码）
6. answered 或 insufficient_information
```

**典型 Archive 阶段 Extractor 沉淀序列**：

```text
1. 读取已通过 Review 的最终产物（design/decision-log/expert-answer/test report）
2. 生成 ADR.md / lesson.md（带 [E:type:locator] 来源链）
3. publish-knowledge:
   a. ov add-resource 07_knowledge/ --parent viking://resources/ufs-firmware --wait
   b. ov reindex --mode vectors_only（新增向量）
   c. ov find "ADR 标题关键词" 回查确认可检索
4. knowledge/index.yaml 登记新 ID（[E:viking:ADR-2026-001]）
```

### 8.7 固件仓库特有风险与对策

| 风险 | 对策 |
|---|---|
| 固件代码与硬件版本强绑定，通用 embedding 难区分 | 条目 metadata 强制带 chip/protocol 版本字段 |
| 大量宏定义/寄存器操作，代码专用模型也覆盖差 | 依赖富化（§5.5）+ sparse 符号匹配兜底 |
| 高危模块误判（blk-power.c 命中 power.c） | 用目录/命名空间隔离（§7），不用子串匹配 |
| 历史 bug 大量且相似，检索噪音 | 按模块目录隔离 + metadata 过滤（chip/version/severity） |
| 知识条目长期不更新变陈旧 | Archive 时校验 freshness（§5.2 一致性检查）+ 定期 reindex |

---

## 9. ADR 条目模板（写入格式）

```markdown
# ADR-2026-001: gc_threshold 保持 75%

## Context
阈值类决策必须可追溯、可回放。

## Decision
保持 75%，不提高 [E:expert:EXP-001][E:code:gc_policy.c:125]。

## Alternatives
- 提高到 85%：风险未知，证据不足（rejected）

## Evidence
- 03_design/design.md（decision-log: DEC-20260811-0001）
- 02_expert/expert-answer.md（EXP-001）
- verification report

## Risk
High。阈值影响 recovery 与 latency。
```

---

## 10. 部署后验证清单

| 验证项 | 命令 | 通过标准 |
|---|---|---|
| 服务健康 | `ov health` | ok |
| 组件状态 | `ov status` | retrieval 组件健康（非零结果率过高） |
| 语义检索 | `ov find "gc threshold"` | 有结果 |
| 符号检索（代码） | `ov find "<确切符号名>" -t 0` | 有结果（验证符号可定位） |
| 模式检索 | `ov grep "threshold"` | 有结果 |
| 写入回读 | `ov write` 后 `ov read` | 内容一致 |
| MCP 工具 | 客户端列出 openviking 工具 | find/search/read/write 可见 |
| 端到端 | 发布 ADR → `ov find "ADR 标题关键词"` | 可检索到 |

---

## 11. 已知限制与风险

1. **语义检索可能零结果**：常见于 L0/L1 摘要层向量缺失、模型与查询不匹配、sparse 未开启——按 §5.2 排查
2. **代码检索对通用文本模型弱**：bge 系列对英文代码符号语义稀疏，代码仓库建议换代码专用模型（§5.3）
3. **LLM 调用成本**：每条/每目录写入触发摘要生成（L0/L1），大量入库成本高
4. **L0/L1 摘要质量**依赖所选 VLM
5. **License**：主项目 AGPLv3（ov_cli/examples Apache 2.0）——商业分发需合规评估
6. **云端后端 filter 限制**：Volcengine VikingDB 云端不支持 PathScope filter，带 target_uri 查询可能返回 0——本地 vikingdb 后端可避免

---

## 12. 参考

- 官方文档：https://docs.openviking.ai/zh/getting-started/01-introduction
- MCP 集成：https://docs.openviking.ai/zh/guides/06-mcp-integration
- GitHub：https://github.com/volcengine/OpenViking
- 代码检索基准：CoIR（https://archersama.github.io/coir/）、CoREB（https://hq-bench.github.io/coreb-page/）
- 本地：`ov --help` / `ov <cmd> --help`
