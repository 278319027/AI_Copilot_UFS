# OpenViking 使用指南（内部分享版）

> 整理自 volcengine/OpenViking 官方仓库（v0.3.22，AGPLv3），2026-08。
> 官网: https://openviking.ai · 文档: https://docs.openviking.ai/zh · 在线体验(免安装): https://openviking.ai/studio

---

## 1. OpenViking 是什么

**一句话**：面向 AI Agent 的开源「上下文数据库」——把 Agent 的**记忆、知识（RAG 资源）、技能**统一存进 `viking://` 虚拟文件系统，Agent 像操作文件一样用 `ls / tree / find / grep` 确定性地定位上下文，而不是查一个黑盒向量库。

### 核心设计（4 个关键点）

| 设计 | 说明 | 好处 |
|------|------|------|
| `viking://` 虚拟文件系统 | 记忆/资源/技能各有 URI，目录结构保留 | 定位确定、可解释、可调试 |
| 三层内容模型 L0/L1/L2 | 写入时自动生成 `.abstract`(L0 ~100 tok) / `.overview`(L1 ~2k tok) / 原始文件(L2) | 按需加载，大幅省 token |
| 目录递归检索 | 向量检索先定位得分最高的目录，再逐层下探，连周边上下文一起返回 | 召回带上下文，不丢邻居信息 |
| 检索轨迹可观察 | 每次查询保留目录浏览轨迹 | 结果不对时能查它出自哪条路径 |

目录结构长这样：

```
viking://
├── resources/              # 资源：文档、代码库、网页
│   └── my_project/
│       ├── .abstract       # L0：~100 tokens，快速判断相关性
│       ├── .overview       # L1：~2k tokens，结构和要点
│       ├── docs/
│       │   └── api/auth.md # L2：完整内容，按需加载
│       └── src/
└── user/
    └── {user_id}/
        ├── memories/       # 长期记忆（偏好、习惯，会话沉淀而来）
        ├── skills/         # 技能（SKILL.md 形式）
        ├── resources/      # 私有资源
        └── peers/          # 交互对象画像
```

### 官方评测数据（0.3.22，为什么值得用）

| 基准 | 原生记忆 | +OpenViking | 附加收益 |
|------|---------|-------------|---------|
| LoCoMo 长对话记忆（OpenClaw） | 24.20% | **82.08%** | 输入 token -34%~-91%，查询时延 -58%~-66% |
| LoCoMo（Hermes） | 33.38% | **82.86%** | 同上 |
| LoCoMo（Claude Code） | 57.21% | **80.32%** | 同上 |
| tau2-bench 多轮任务（Retail） | 70.94% | **77.81%** (+6.87pp) | Agent 经验记忆 |
| tau2-bench（Airline） | 54.38% | **66.25%** (+11.87pp) | 同上 |

---

## 2. 安装

### 2.1 前置要求

- **Python ≥ 3.10**（Linux / macOS / Windows 均可）
- 两类模型能力：**Embedding 模型**（向量化检索）+ **VLM 模型**（语义理解，生成 L0/L1）。支持：火山引擎(豆包，推荐、有免费额度)、OpenAI、Codex OAuth、Kimi、GLM、**本地 Ollama**（选 Ollama 时向导会自动检测/安装运行时并按硬件拉模型）。

### 2.2 安装（三种方式，任选）

```bash
# 方式一：pip
pip install openviking --upgrade --force-reinstall

# 方式二：uv（官方推荐）
uv tool install openviking --upgrade

# 方式三：docker（推荐作为独立服务跑，生产环境首选）
docker run -d --name openviking -p 1933:1933 \
  -v ~/.openviking:/app/.openviking \
  ghcr.io/volcengine/openviking:latest
# 国内拉不动 ghcr 可用镜像加速器，或参考 deploy/ 目录
```

安装后得到两个命令：`ov`（客户端 CLI，Rust 写的，别名 `openviking`）和 `openviking-server`（服务端）。
Rust CLI 也可独立装：`npm i -g @openviking/cli` 或 `cargo install --git https://github.com/volcengine/OpenViking ov_cli`。

### 2.3 初始化 + 启动（4 条命令跑起来）

```bash
openviking-server init      # 交互式向导：选提供商、填 key，生成 ~/.openviking/ov.conf
openviking-server doctor    # 校验配置（Python 版本/提供商连通性/磁盘空间），不用先起服务
openviking-server           # 前台启动
# 或后台：
nohup openviking-server > /data/log/openviking.log 2>&1 &
```

### 2.4 配置（ov.conf 最小模板）

`~/.openviking/ov.conf`，JSON 格式。**推荐直接用 `init` 向导**，手写的话最小模板：

```json
{
  "storage": {
    "workspace": "./data",
    "vectordb": { "name": "context", "backend": "local" },
    "agfs": { "backend": "local" }
  },
  "embedding": {
    "dense": {
      "api_base": "<api-endpoint>",
      "api_key": "<your-api-key>",
      "provider": "<volcengine|openai|kimi|glm|openai-codex|ollama>",
      "dimension": 1024,
      "model": "<model-name>"
    }
  },
  "vlm": {
    "api_base": "<api-endpoint>",
    "api_key": "<your-api-key>",
    "provider": "<provider-type>",
    "model": "<model-name>"
  }
}
```

火山引擎示例（embedding 用 doubao-embedding-vision-251215 / VLM 用 doubao-seed 系列，`api_base=https://ark.cn-beijing.volces.com/api/v3`）。
生产/多租户部署把 `vectordb.backend` 换成 `volcengine`（VikingDB）、`agfs.backend` 换成 `s3`（TOS），完整模板见仓库 `examples/cloud/ov.conf.example`。
其他可配模块：`server`(host/port/root_api_key/cors)、`rerank`、`parser`、`grep`、`storage.transaction` 等。

### 2.5 冒烟测试

```bash
ov status                    # 服务状态
curl http://localhost:1933/health    # 预期 {"status": "ok"}
ov add-resource https://github.com/volcengine/OpenViking --wait
ov find "what is openviking"
```

---

## 2A. 内网（离线）部署专题 ⭐

内网用 OpenViking 完全可行——存储默认就是本地（`vectordb.backend=local` + `agfs.backend=local`，数据全在 workspace 一个目录），但**模型、依赖、镜像**三样东西默认都要联网拿，需要提前准备。

### 2A.1 哪些环节会碰外网（清单）

| 环节 | 默认行为 | 内网对策 |
|------|---------|---------|
| pip 安装 openviking | 访问 PyPI | 离线 wheelhouse 或内网 PyPI 源 |
| Docker 镜像 | `ghcr.io/volcengine/openviking` | `docker save/load` 搬运 |
| **Embedding 模型** | 默认本地 GGUF `bge-small-zh-v1.5-f16`（512 维），从 HuggingFace 下载缓存 | 外网机预下载 GGUF 后拷贝，`model_path` 直指本地文件 |
| **VLM 模型** | 任意 OpenAI 兼容端点 | 内网 GPU 上用 Ollama / vLLM / llama.cpp 起 OpenAI 兼容服务 |
| query_planner（可选，意图分析） | 回退到 VLM；或推荐本地 Ollama 小模型 | `ollama pull` 后 `ollama save/load` 搬运 |
| 本地 embedding 的 `llama-cpp-python` 依赖 | 可选 extra，不在主包 | 离线 wheelhouse 里带上 |
| 遥测/用量上报 | **默认关闭**（`usage_reporter.enabled=false`） | 不用管，天然不出网 |
| 音视频理解 `vlm.media` | 上传文件到火山方舟 Files API | **内网千万别开** |

### 2A.2 依赖准备（在有网机器上执行一次）

```bash
# 1) 收集 wheel（Python 版本/平台要和内网机一致）
mkdir ov-wheels && cd ov-wheels
pip download "openviking[local-embed]" -d ./ --python-version 3.11 --platform manylinux2014_x86_64 --only-binary=:all:
# 内网机架构不同（aarch64 等）就换 --platform
tar czf ov-wheels.tar.gz ./

# 2) 内网机上安装（--no-index 确保不碰外网）
pip install --no-index --find-links ./ ov openviking[local-embed]
```

### 2A.3 Docker 镜像搬运

```bash
# 有网机
docker pull ghcr.io/volcengine/openviking:latest
docker save ghcr.io/volcengine/openviking:latest | gzip > openviking.tgz
# 内网机
gunzip -c openviking.tgz | docker load
```

### 2A.4 模型准备（内网方案核心）

**Embedding —— 两条路：**

路线 A：内置本地 GGUF（零服务，推荐单机）

```bash
# 有网机下载（约 130MB）
wget -O bge-small-zh-v1.5-f16.gguf \
  "https://huggingface.co/CompendiumLabs/bge-small-zh-v1.5-gguf/resolve/main/bge-small-zh-v1.5-f16.gguf?download=true"
# 拷贝到内网机，如 /data/models/bge-small-zh-v1.5-f16.gguf

# ov.conf：
{
  "embedding": {
    "dense": {
      "provider": "local",
      "model": "bge-small-zh-v1.5-f16",
      "model_path": "/data/models/bge-small-zh-v1.5-f16.gguf",
      "dimension": 512
    }
  }
}
```

- `model_path` 指向本地文件时**完全不会下载**（不配 model_path 才会去 HuggingFace 拉）。
- 需要装 `openviking[local-embed]`（llama-cpp-python，纯 CPU 就够，512 维小模型很快）。

路线 B：Ollama / llama.cpp 起 OpenAI 兼容 embedding 服务（多机共享、或想用 bge-m3 这类更大模型）

```json
{
  "embedding": {
    "dense": {
      "provider": "ollama",
      "api_base": "http://<gpu-node>:11434",
      "api_key": "ollama",
      "model": "bge-m3"
    }
  }
}
```

**VLM —— 内网 GPU 起 OpenAI 兼容服务：**

```bash
# 有网机先导出 tar，内网机 ollama load 导入
ollama pull qwen2.5:7b-instruct      # 或任何支持中文摘要的模型
ollama save qwen2.5:7b-instruct ./qwen2.5-7b.tar
```

```json
{
  "vlm": {
    "provider": "litellm",
    "model": "ollama/qwen2.5:7b-instruct",
    "api_base": "http://<gpu-node>:11434",
    "timeout": 120,
    "max_retries": 3
  }
}
```

**query_planner（可选但推荐）—— 检索意图分析小模型：**

```bash
# 有网机
ollama pull guoxuter/ov_intent_analysis_sft:v7_q8   # Qwen3.5-0.8B 微调，约 0.5GB
ollama save ov_intent_analysis_sft:v7_q8 ./ov_intent.tar
# 内网机 ollama load ./ov_intent.tar
```

```json
{
  "query_planner": {
    "provider": "litellm",
    "model": "ollama/guoxuter/ov_intent_analysis_sft:v7_q8",
    "api_base": "http://<gpu-node>:11434",
    "temperature": 0.0,
    "timeout": 60,
    "extra_request_body": { "think": false }
  }
}
```

作用：`search()` 前先做意图分析，闲聊/上下文已足够时拒绝检索，省 token 省延迟；对已知模型自动匹配内置 prompt，不用改 prompt 文件。不配则回退到 VLM 处理。

### 2A.5 内网 ov.conf 完整模板

```json
{
  "storage": {
    "workspace": "/data/openviking",
    "vectordb": { "name": "context", "backend": "local" },
    "agfs": { "backend": "local" }
  },
  "embedding": {
    "dense": {
      "provider": "local",
      "model": "bge-small-zh-v1.5-f16",
      "model_path": "/data/models/bge-small-zh-v1.5-f16.gguf",
      "dimension": 512
    }
  },
  "vlm": {
    "provider": "litellm",
    "model": "ollama/qwen2.5:7b-instruct",
    "api_base": "http://10.x.x.10:11434",
    "timeout": 120
  },
  "query_planner": {
    "provider": "litellm",
    "model": "ollama/guoxuter/ov_intent_analysis_sft:v7_q8",
    "api_base": "http://10.x.x.10:11434",
    "temperature": 0.0,
    "timeout": 60,
    "extra_request_body": { "think": false }
  }
}
```

### 2A.6 内网专属注意事项

1. **`init` 向导会联网**（选 Ollama 时会检测/安装运行时、拉模型）——内网机**跳过 `init`，直接手写 `ov.conf`**，只跑 `openviking-server doctor` 验证（doctor 只查配置、提供商连通性和磁盘，不装东西）。
2. **默认无外联**：usage reporter 默认 `enabled=false`，且开启后也只有 `file_log`/custom sink 两种本地/自管目标；OTLP trace 是按需写本地 JSONL 文件。不配就不会出网。
3. **不要开 `vlm.media`**（音视频理解会上传文件到火山方舟 API）。
4. **飞书/Lark 导入同理**——走云端解析，内网环境用不到；文档直接用本地路径或内网 URL `add-resource`。
5. **`add-resource` 的 URL 资源**：只能加内网可达的 URL（内网 wiki、git 服务器、HTTP 文件服务），外网 URL 会超时挂起。本地路径不受限。
6. **多机部署拓扑**：一台 GPU 节点跑 Ollama（VLM + query_planner + 可选 embedding），另一台跑 OpenViking server，`api_base` 填内网 IP。Ollama 默认只听 127.0.0.1，跨机用要设 `OLLAMA_HOST=0.0.0.0`。
7. **换 embedding 模型 = 全量重建向量**：换模型/维度后必须 `ov reindex <uri> --mode semantic_and_vectors` 全库重建。内网离线环境提前定好模型选型，别反复换。
8. **数据备份**：全部状态在 `storage.workspace` 一个目录（含向量索引），目录级备份 + `ov export .ovpack` 双保险。
9. **AGPL 合规**：纯内网自用无问题；如果做成服务给公司外部用，AGPLv3 有开源义务，提前和法务确认。
10. **MCP 接入不受影响**：内网 Agent（Claude Code/Codex/OpenCode/Hermes）配 `http://<ov-server>:1933/mcp` 即可，鉴权用内网 API key，无公网依赖。

### 2A.7 内网最小验证流程（照抄）

```bash
# 0) 前置：wheel 装好、GGUF 拷好、Ollama 起好（ollama list 能看到模型）
# 1) 手写 ov.conf（2A.5 模板），然后：
openviking-server doctor     # 全绿再启动
openviking-server            # 启动
# 2) 冒烟
ov health
ov add-resource /path/to/内网文档目录 --wait
ov find "你们的业务关键词"
ov grep "某错误码" --uri viking://resources/xxx
# 3) 接 Agent：MCP 配置指向 http://<ov-server>:1933/mcp
```

---

## 3. 核心功能

| 功能 | 说明 |
|------|------|
| **资源管理** | `add-resource` 支持本地文件/目录、URL、git 仓库，入库时自动切分并生成 L0/L1 语义产物 + 向量 |
| **长期记忆** | 会话提交（commit）后**异步**抽取用户偏好、Agent 经验写入 `viking://user/{id}/memories/`；也支持 `add-memory` 一键写入 |
| **技能库** | `skill add/list/find/show/validate`，技能以 SKILL.md 形式入库，可被检索召回 |
| **语义检索** | `find`（快速无上下文）/ `search`（带 session 上下文 + 意图分析），返回带 URI、摘要、score 的排序结果 |
| **精确检索** | `grep`（正则内容搜索，支持多 pattern 并发）、`glob`（文件名匹配） |
| **watch 自动刷新** | `add-resource --watch-interval 60`（分钟）订阅远程 URL，定时自动重新拉取入库；`ov task watch` 管理 |
| **快照版本控制** | `snapshot commit/restore/show/log/diff`，workspace 有 git 式提交历史 |
| **备份迁移** | `export/import`（`.ovpack` 格式，可带向量快照），`backup/restore` |
| **多租户** | `admin` 子命令管理 account/user/角色/API key；MCP 端点支持 OAuth 2.1（Claude.ai/Desktop 直连） |
| **观测** | `status` / `health` / `observer`（组件状态、队列、检索质量指标、文件系统指标） |
| **VikingBot** | 官方 Agent 框架：`pip install "openviking[bot]"` + `openviking-server --with-bot`，`ov tui` 聊天（Docker 镜像默认自带） |
| **Studio** | Web 控制台 + 在线 playground（`/studio` 路径，容器默认启动） |
| **加密/隐私** | 字段级加密（`crypto` 子命令管 key）、`privacy` 分类别隐私配置 |

### 检索四件套怎么选（重要）

| 工具 | 适用场景 |
|------|---------|
| `find` | 语义模糊检索，"什么是 X"、"哪块代码负责 Y" |
| `search` | 深度语义检索，带会话上下文 + 意图分析，多轮对话中用 |
| `grep` | 已知确切字符串/错误码/寄存器名，正则精确匹配 |
| `glob` | 按文件名模式找（`**/*.md`、`*.py`） |

---

## 4. 使用方式

### 4.1 CLI 基本工作流

```bash
# —— 写入 ——
ov add-resource /path/to/local/dir            # 本地目录
ov add-resource https://github.com/xxx/yyy --wait
ov add-resource https://some-blog.com --watch-interval 60   # 订阅，每 60 分钟自动刷新
ov add-skill ./my-skill-dir --wait            # 技能（目录/SKILL.md/裸文本都行）
ov write viking://user/me/notes/todo.md "内容" # 写文件（--append 追加）
ov mkdir viking://resources/new_proj --description "描述"

# —— 浏览（Agent 的"文件系统操作"）——
ov ls viking://resources/
ov tree viking://resources/volcengine -L 2     # 目录树，-L 控制深度
ov abstract viking://resources/xxx             # 读 L0 摘要
ov overview viking://resources/xxx             # 读 L1 概览
ov read viking://resources/xxx/doc.md          # 读 L2 全文
ov stat / ov attrs <uri>                       # 元数据 / 扩展属性（tags 等）

# —— 检索 ——
ov find "openviking 的检索机制"
ov grep "openviking" --uri viking://resources/volcengine/OpenViking/docs/zh
ov glob "**/*.md" --uri viking://resources/

# —— 标签（收窄检索范围）——
ov attrs set-tags <uri> --tags env=prod,team=ufs --mode append
```

### 4.2 会话与记忆

```bash
ov session new                          # 建会话
ov session add-message <sid> --role user "我们决定用 Q4_K_M 量化"
ov session commit <sid>                 # 提交：归档消息 + 异步抽取记忆
ov session list / get <sid>             # 查看
ov add-memory "用户偏好 Q4_K_M"          # 实验性：一步写入（建会话+加消息+提交）
```

会话提交后记忆是**异步抽取**的，不会立刻可见——这是设计行为，不是 bug。

### 4.3 接入 Agent（最关键的部分）

**方式 A：MCP 端点（通用，任何 MCP 客户端）**

服务自带 `/mcp` 端点（与 REST 同进程同端口 `http://<server>:1933/mcp`），**不需要额外进程**。暴露 16 个工具：

| 工具 | 用途 |
|------|------|
| `find` / `search` | 语义检索（search 带 session 上下文 + 意图分析） |
| `recall` | 按记忆类别配额召回，服务端组装成带 URI 的 token 预算化 `<memory>` 块 |
| `read` / `list` / `tree` / `glob` / `grep` | 文件系统式浏览 |
| `remember` | 存长期记忆（触发抽取） |
| `write` / `edit` | 写/局部改 `viking://` 文件（edit 是精确字符串替换，找不到或多处匹配会失败且不改文件） |
| `add_resource` | 入库资源（本地文件走一次性 token 上传流，沙箱客户端也能用） |
| `list_watches` / `cancel_watch` | 管理自动刷新订阅 |
| `forget` | 删除 URI（**不可逆**） |
| `health` | 健康检查 |

各客户端配置片段：

```jsonc
// 通用 mcpServers（Trae / Manus / Cursor 等）
{ "mcpServers": { "openviking": {
    "url": "http://your-server:1933/mcp",
    "headers": { "Authorization": "Bearer <api-key>" } } } }

// Claude Code 需要 type: http（或 CLI）
claude mcp add --transport http openviking http://your-server:1933/mcp \
  --header "Authorization: Bearer <api-key>"   // 加 --scope user 全局生效

// OpenCode（~/.config/opencode/opencode.json）
{ "mcp": { "openviking": { "type": "remote",
    "url": "http://your-server:1933/mcp", "enabled": true, "oauth": false,
    "headers": { "Authorization": "Bearer <api-key>" } } } }
```

鉴权：`X-Api-Key` 或 `Authorization: Bearer`；本地绑定 localhost 时免认证。
Claude.ai / Claude Desktop 只认 OAuth 2.1，OpenViking 已原生实现（DCR + PKCE），配好 HTTPS 直连即可。

**方式 B：官方集成（推荐，自动注入 + 自动沉淀会话）**

官方已适配：Claude Code、Codex、OpenClaw、**Hermes**、Cursor、Trae、OpenCode、pi、LangChain/LangGraph、Agent Plugins 1.0、MCP 客户端。
集成版比裸 MCP 多做两件事：**把召回自动注入 Agent 上下文** + **自动提交会话记忆**（不用 Agent 自己记得调 remember）。

Hermes 集成（内置 memory provider，无需装插件）：

```bash
hermes memory setup     # 向导：填 OpenViking URL(默认 http://127.0.0.1:1933) + API key
hermes memory status    # 验证
```

配完后自动注入上下文、预取相关记忆、会话后同步抽取；暴露 `viking_search / viking_read / viking_browse / viking_remember / viking_forget / viking_add_resource` 工具。
⚠️ 注意：OpenViking 要放在**独立 Python 环境/容器**里跑，不要在 Hermes 的 venv 里 `--force-reinstall` 装 OpenViking（依赖版本可能打架）。

OpenCode 有官方插件 `@openviking/opencode-plugin`（npm）：系统提示注入已索引仓库 + 记忆会话映射 + 自动召回注入，且会拦截 Agent 误用本地文件读 `viking://` URI 的行为。

**方式 C：Python SDK（自己写应用）**

```python
from openviking_sdk import SyncHTTPClient
client = SyncHTTPClient(url="http://localhost:1933")
client.initialize()

res = client.add_resource(path="https://.../README.md", wait=True)
root = res["root_uri"]
client.ls(root)                                    # 浏览
client.glob(pattern="**/*.md", uri=root)           # 找文件
client.read(uri)                                   # L2
client.abstract(root); client.overview(root)       # L0/L1
results = client.find("what is openviking", target_uri=root)  # 语义检索
```

完整示例：仓库 `examples/quick_start.py`。

### 4.4 运维命令

```bash
ov status / ov health / ov observer        # 组件状态 / 健康 / 详细观测
ov reindex <uri> --mode vectors_only       # 只重建向量
ov reindex <uri> --mode semantic_and_vectors  # 重新生成 .abstract/.overview 再建向量
ov reindex <uri> --mode prune_orphans --dry-run  # 预览清理孤儿向量
ov task list / cancel <task_id>            # 异步任务跟踪
ov snapshot commit / log / diff / restore  # 快照版本控制
ov export <uri> -o backup.ovpack           # 备份（可含向量快照）
ov import backup.ovpack --to <uri>
ov config / ov config switch <name>        # 多服务器配置切换
ov language zh-CN                          # CLI 显示语言
```

---

## 5. 使用技巧（实战经验）

### 性能 / 成本

1. **入库一定带 `--wait`**（或 SDK `wait=True`）：语义处理是异步的，不加等待马上 `find` 会查不到东西。
2. **按层级取内容，别上来就读 L2**：先看 `abstract`（~100 tok）判断相关性 → 再看 `overview`（~2k tok）规划 → 需要时才 `read` 全文。这是省 token 的核心机制，官方评测里 token 降 34%~91% 主要来自这里。
3. **大批量重建只刷向量**：`reindex --mode vectors_only` 跳过 VLM 语义理解，快且便宜；只有源内容结构变化才需要 `semantic_and_vectors`。
4. **用 tags 收窄检索**：`set-tags env=prod,team=ufs`，检索时按标签过滤，避免跨项目串味。

### 检索

5. **`find` 和 `search` 分工**：单轮快速查用 `find`；多轮对话里用 `search`（带 session 上下文 + 意图分析，能理解"它""上面那个"这类指代）。
6. **查确切串（错误码、函数名、寄存器）用 `grep` 不用 `find`**——向量检索对精确字符串不敏感。
7. **结果不对时看轨迹**：检索保留目录浏览轨迹，能看出它从哪个目录进去、在哪条路径上丢了，比黑盒向量库好调得多。
8. **`min_score` 阈值别设太低**：低分召回是噪声，宁可少召回 + 二次下探。

### 记忆

9. **记忆是异步抽取的**：`session commit` 后不要立刻验证记忆可见，等一会儿或查 task 状态。
10. **用户偏好要主动沉淀**：Agent 集成会自动提交会话，但"以后都用 XX 风格"这类显式偏好，直接 `remember`/`add-memory` 一条比等异步抽取更可靠。
11. **`forget` 不可逆**：删 `viking://` URI 没有回收站，删目录要 `recursive=true`，删前先 `search` 确认范围。

### 部署 / 运维

12. **反向代理后面必须显式配 `OPENVIKING_PUBLIC_BASE_URL`**（或 `server.public_base_url`）：MCP 的本地文件上传流返回的上传 URL 靠它解析；不配且 server 监听 0.0.0.0 时 fallback 会给出 `http://0.0.0.0:1933/...`，Agent 连不上。
13. **Mac + Docker 的 Connection reset**：OpenViking 默认只监听 127.0.0.1，宿主机 `localhost:1933` 会不通。官方解法：容器内 `socat` 转发（把宿主机 1933 映射到容器 1934，容器内 socat 1934→127.0.0.1:1933），不用改配置。
14. **watch 订阅用 `--watch-interval`（分钟）**：远程文档/博客/代码库自动保持最新；MCP 里只能 list/cancel，pause/resume/改周期要走 `ov task watch` CLI 或 REST `/api/v1/watches/*`。
15. **多服务器用 `ov config switch`**，客户端配置独立于服务端（`~/.openviking/` 下客户端 conf）。
16. **生产环境独立 HTTP 服务 + root_api_key**；多租户用 `admin` 管账号，`--sudo` 用 root key 执行管理命令。
17. **快照当版本控制用**：重要改动前 `snapshot commit`，出问题 `snapshot restore`，还能 `diff` 对比两个 commit——这在别的 RAG 工具里没有。
18. **迁移/交接用 `.ovpack`**：`export` 带向量快照，`import` 到新环境，不用重新算 embedding。

### 选型建议

- **个人本地**：pip 装 + Ollama 本地模型，零成本。
- **团队共享**：Docker 跑一个 server，全员 MCP 接入，`admin` 开多租户。
- **已有 Hermes**：直接 `hermes memory setup`，零插件。
- **合规要求数据不出域**：开源版 AGPLv3 完整开源不锁功能，自建即可；官方另有私有化部署版（离线/在线）和火山引擎 SaaS。

---

## 6. 常见问题速查

| 问题 | 解法 |
|------|------|
| `find` 查不到刚加的内容 | 语义处理没完成：`ov task list` 看进度，或下次加 `--wait` |
| MCP 连接被拒 | `curl http://localhost:1933/health`，确认 server 在跑、端口对 |
| MCP 认证错误 | 客户端 API key 和 server `root_api_key`/用户 key 不一致 |
| 上传 URL 是 `0.0.0.0` | 配 `OPENVIKING_PUBLIC_BASE_URL` |
| 配置检查 | `openviking-server doctor`（不依赖服务启动） |
| 重建索引后语义产物丢了 | 用了 `vectors_only` 是预期行为；需要 `semantic_and_vectors` |
| 飞书/Lark 文档导入 | `add_resource` 传 `args={"feishu_access_token":"u-..."}`（一次性导入）或加 `feishu_refresh_token`（watch），服务端需配同一飞书应用凭证 |

---

## 7. 资源链接

- GitHub: https://github.com/volcengine/OpenViking
- 文档（中文）: https://docs.openviking.ai/zh
- 在线体验: https://openviking.ai/studio
- 设计博客: https://blog.openviking.ai/post/openviking-context-database/
- 评测报告: https://blog.openviking.ai/post/openviking-benchmark-results/
- 论文: VikingMem (VLDB 2026, arXiv:2605.29640)
- 许可证: 主项目 AGPLv3 / CLI Apache 2.0（内部自用无问题，注意 AGPL 对二次分发 SaaS 的影响）
- 社区: 飞书群 / 微信群 / Discord（见文档 about 页）

---

## 8. 适用场景详解（什么时候该用 OpenViking）

> **一句话判断**：当你觉得"节省 Token"比"省事"更重要的时候。OpenViking 的 L0/L1/L2 三层加载 + 目录递归检索，本质上是一个 **Token 优化引擎**，这是其他记忆工具（opencode-mem 等）没有的能力。
>
> 其他工具解决的是"AI 能不能记住上次说了什么"（答案：是/否）；OpenViking 解决的是"AI 能不能在大规模上下文里精准找到需要的信息，同时不让 Token 爆炸"（答案：省多少 Token）。

### 8.1 场景一：大规模知识库 + Token 成本敏感 ⭐⭐⭐⭐⭐

**适配度最高的场景。** 当 Agent 需要在数千份文档里检索时，最大的敌人不是"找不到"，而是"找到了但装不下"——把整个知识库塞进 prompt 既不现实（上下文窗口频繁打满）也烧钱（Embedding/VLM API 按量计费，每省 1% 都是钱）。

**为什么能省 Token：三层加载 + 目录递归检索**

```
用户提问
   │
   ▼
目录级向量检索（Embedding 成本，千篇级库毫秒~秒级完成）
   │  先定位得分最高的目录，而不是逐篇硬比
   ▼
L0 摘要过滤（~100 tok/篇，只读 Top N）
   │  快速判断相关性，扔掉无关文档
   ▼
L1 概览阅读（~2k tok/篇，读选中的几篇）
   │  看结构和要点，规划怎么用
   ▼
L2 全文精读（按需，只读最终确定的 1-2 篇）
```

对照传统做法：候选 100 篇全文 × 平均 6k tok = **60 万 token 灌进上下文**；OpenViking 走完 L0→L1→L2 后实际注入只有几万 token（100 篇摘要约 1 万 + 几篇概览约 1 万 + 1-2 篇全文约 1 万）。**省 83-91% Token 就是这么来的**（官方实测范围，视知识库结构而定）。

**目录递归检索**是另一半功劳：向量检索先定位得分最高的**目录**，再逐层下探，**连周边上下文一起返回**——召回不丢邻居信息，避免"搜到一篇孤立的文档却不知道它在哪个项目里"。

**实测数据（官方评测 0.3.22）**

| 指标 | 数值 |
|------|------|
| Token 节省 | 输入 token 降 34%~91%（LoCoMo 基准）；典型场景实测 83-91% |
| 查询时延 | -58%~-66% |
| 长对话记忆准确率 | 24.20% → 82.08%（OpenClaw，+57.88pp） |

**典型用户**：企业级 RAG 系统、大规模文档问答、知识库 Agent、合规文档检索。Token 费用真金白银在烧、上下文窗口频繁打满的团队。

**落地姿势**（与第 5 节技巧 2 呼应）：

```bash
ov add-resource /data/knowledge_base --wait    # 入库，自动生成 L0/L1 + 向量
ov abstract viking://resources/knowledge_base  # 先扫 L0，快速过滤
ov overview <候选 URI>                         # 再读 L1，确定要哪几篇
ov read <最终 URI>                             # 最后才 L2 全文
```

⚠️ **代价**：入库时生成 L0/L1 摘要要调 VLM，写入有延迟和费用——所以"写入频繁、追求毫秒级写入"的场景（见 8.6）不适合它。本场景的成立前提是**读多写少**：一次性入库、长期反复检索。

### 8.2 场景二：多类型上下文统一管理

**其他工具只管理"记忆"一个维度；OpenViking 把三类上下文统一进同一个 `viking://` 文件系统。**

| 类型 | 路径 | 内容示例 |
|------|------|---------|
| 资源 Resource | `viking://resources/` | 代码库、PDF、网页、内部 wiki |
| 记忆 Memory | `viking://user/{id}/memories/` | 用户偏好、习惯、会话沉淀 |
| 技能 Skill | `viking://user/{id}/skills/` | Agent 能力（SKILL.md 形式） |
| 画像 Peer | `viking://user/{id}/peers/` | 交互对象画像 |

**为什么统一有意义**：

- **一套操作覆盖全部类型**：`ls / tree / read / find / grep` 对资源、记忆、技能一视同仁——Agent 不用为"文档库"和"用户画像"维护两套检索逻辑。
- **URI 即地址**：任何一条上下文都有确定路径，可精确引用、精确写入、精确删除（`forget`）。
- **跨类型检索**：一次 `find` 可同时在 resources + memories + skills 里召回，按 score 排序，由 Agent 判断用哪条。
- **tag 收窄范围**：`set-tags env=prod,team=ufs` 把检索锁在指定维度，避免跨项目串味（第 5 节技巧 4）。

**典型用户**：需要同时管理"文档库 + 用户画像 + Agent 技能"的复合场景——客服系统（知识库 + 每个用户的偏好 + 客服话术技能）、开发助手（代码库 + 架构决策记忆 + 代码生成技能）、研究助手（论文库 + 个人兴趣画像 + 综述撰写技能）。

**边界**：如果只需要"记忆"一个维度，opencode-mem 这类更轻的工具就够；要管理多类型且希望它们在一个命名空间里统一寻址、统一检索，OpenViking 是唯一的选择。

### 8.3 场景三：检索可观测性要求高

**每次检索的轨迹完整保留、可回放**：先查了哪个目录、进了哪个子目录、最终定位到哪个文件——每一步都有记录。

**和黑盒向量库的本质区别**：传统 RAG 只返回相似度分数，你不知道它"为什么"返回这些结果；OpenViking 返回的是**一条可追溯的路径**——结果不对时，能看出它从哪个目录进去、在哪条路径上丢了，比黑盒好调得多（第 5 节技巧 7）。

**典型用户**：

| 场景 | 诉求 |
|------|------|
| 合规审计 | 为什么 Agent 做出了这个决策？它当时看到了哪些上下文？——需要完整留痕 |
| 调试优化 | 检索质量不好时，能定位是哪个环节出了问题（意图分析？目录定位？召回阈值？） |
| 企业级部署 | 检索链路必须可追溯，出问题能回放复现 |

**配套能力**：`ov observer`（组件状态、队列、检索质量指标）、`search` 的 session 上下文 + 意图分析轨迹、`min_score` 阈值可调（第 5 节技巧 8：别设太低，低分召回是噪声，宁可少召回 + 二次下探）。整个检索链路**可解释、可观测、可调参**，而不是"往向量库一扔，结果靠缘分"。

### 8.4 场景四：CLife 场景——Agent 长期运行、越用越聪明

**核心机制：自动记忆迭代。**

```
Agent 干活 → session commit（会话归档）
              → 异步抽取用户偏好 / Agent 经验
              → 写入 viking://user/{id}/memories/
下次会话 → recall / search 自动召回 → Agent 用得更准
              → 再 commit → 继续沉淀
```

**两个关键点**：

- **异步抽取**：提交后记忆由服务端异步生成（第 5 节技巧 9），Agent 不需要自己记得调 `remember`——官方集成版（Claude Code / Codex / Hermes / OpenCode 插件）会自动提交会话。
- **显式偏好主动沉淀**："以后都用 XX 风格"这类显式偏好，直接 `remember` / `add-memory` 一条，比等异步抽取更可靠（第 5 节技巧 10）。

**典型用户**：

| 场景 | 越用越聪明体现在哪 |
|------|-------------------|
| 客服机器人 | 积累每个用户的历史问题和偏好，复购/投诉处理越来越准 |
| 开发助手 | 记住项目架构决策、常见 Bug 模式，新任务少走弯路 |
| 研究助手 | 跨会话引用已读论文，写综述不用重新读一遍 |

**证据（官方评测 0.3.22）**：LoCoMo 长对话记忆 24.20% → 82.08%（OpenClaw）；tau2-bench 多轮任务 Retail **+6.87pp**、Airline **+11.87pp**——收益全部来自"经验记忆"的跨会话累积。

⚠️ **注意**：这是**长期主义收益**，短期跑一两次看不出差别。适合 Agent 连续运行数周/数月的场景；一次性任务、跑完就散的场景不适用。

### 8.5 场景五：团队协作 + 多 Agent 共享

**`viking://` URI 提供统一命名空间，多个 Agent 可通过路径引用彼此的记忆和资源，实现协作。**

- **共享资源**：团队共用一个 server，知识库/代码库/内部文档入库一次，全员 MCP 接入即查即用（第 4.3 节方式 A）。
- **私有记忆**：每个用户/Agent 有自己的 `viking://user/{id}/` 空间，偏好和画像互不串味。
- **多租户**：`admin` 子命令管理 account/user/角色/API key；MCP 端点支持 OAuth 2.1（Claude.ai / Claude Desktop 直连）。
- **协作示例**：Agent A 把调研结论 `remember` 进共享资源；Agent B 在另一会话 `find` 到它并直接引用——不需要 A、B 共享上下文窗口。

**落地拓扑**（对应第 5 节选型建议）：Docker 跑一个 server → 全员 MCP 接入 → `admin` 开多租户 → 各人 `ov config switch` 管理服务器配置。**团队越多人共享一个知识底座，边际成本越低**——这正是"部署重"的代价换来的回报。

### 8.6 小结：一个表格判断你该不该用

| 你的需求 | 用 OpenViking？ | 为什么 |
|---------|----------------|--------|
| 大规模知识库检索，Token 成本敏感 | ✅ 首选 | L0/L1/L2 省 83-91% token |
| 文档库 + 用户画像 + 技能多类型管理 | ✅ 唯一选择 | `viking://` 统一命名空间 |
| 检索链路要可审计、可回放 | ✅ 强适配 | 目录检索轨迹完整保留 |
| Agent 长期运行、要跨会话变聪明 | ✅ 推荐 | 自动记忆迭代 |
| 团队多 Agent 共享知识底座 | ✅ 推荐 | 多租户 + URI 共享 |
| 个人开发 / 快速原型 / 简单文档问答 | ❌ 杀鸡用牛刀 | 部署重、VLM 写入成本高、学习曲线陡 |
| 写入频繁、追求毫秒级写入 | ❌ 不合适 | 每次写入都要 VLM 生成摘要，延迟高、费用高 |
| 预算有限 / 追求极简可靠 | ❌ 不合适 | 422 open issues，Alpha 阶段，API 快速变动 |
| 商业闭源产品 | ❌ 许可证限制 | AGPL-3.0，需选 MIT/Apache 协议工具 |

**核心取舍**：OpenViking 在"Token 节省能力"维度最强（高省 Token / 重部署的右上角），代价是部署最重（Rust CLI + Python 服务 + Embedding/VLM 依赖）。如果你的场景省 Token 需求不迫切，轻量工具（opencode-mem 一行 plugin）配合现有代码理解工具（如 CodeGraph）已经足够；一旦知识库规模上来、Token 费用开始真金白银地烧，OpenViking 的投入就值得了。

---

## 9. 多 Agent 协作实践（OpenCode subagent 接入指南）

> 面向"辅助编程流程"场景：各流程定义不同 subagent（agent 名 + prompt + 工具集），用 OpenViking 让它们共享上下文。本章是 8.5（团队协作）在 OpenCode 下的落地展开。

### 9.1 核心 MCP 工具速查（16 个工具里常用的 8 个）

MCP 接入后暴露为 `mcp__openviking__<tool>`，常用工具的作用：

| 工具 | 作用 | 类比 |
|------|------|------|
| `find` | **语义检索**：向量搜索，"什么是 X""哪块代码负责 Y"这类模糊提问，返回带 URI、摘要、score 的排序结果 | 搜索引擎 |
| `search` | 深度语义检索：带 session 上下文 + 意图分析，能理解"它""上面那个"这类指代，多轮对话中用 | 带语境的搜索 |
| `recall` | **记忆召回**：按记忆类别配额拉取 `<memory>` 块，服务端组装成**带 token 预算**的上下文直接注入，专用于长期记忆 | 翻备忘录 |
| `grep` | **精确检索**：正则匹配已知字符串（错误码、函数名、寄存器名） | Ctrl+F |
| `read` | 读 L2 **全文**（按需加载，最贵） | 打开文件 |
| `tree` | 浏览目录结构（`-L` 控制深度） | ls -R |
| `glob` | 按文件名模式找（`**/*.md`） | 文件名搜索 |
| `remember` | **写长期记忆**：一步写入用户偏好/决策，触发异步抽取 | 记笔记 |

选型口径与第 5 节"检索四件套"一致：模糊语义用 `find`，多轮对话用 `search`，确切字符串用 `grep`，按文件名用 `glob`。

### 9.2 Subagent 权限矩阵：按流程区分工具

**为什么区分**：每个 agent 只开它完成本职任务**必需**的工具——开用不到的工具会在工具选择时引入噪声和误用风险。本质上是区分"谁能写共享记忆"（写权限影响所有下游 agent 的 `find`/`recall` 结果，是共享空间里最需要管控的）。

| 流程 agent | 工具组合 | 各工具在该流程的用途 |
|-----------|---------|---------------------|
| 调研/规划（读多写少） | `find` `recall` `read` `tree` + 关键时 `remember` | 搜既有知识 → 拉历史决策 → 摸目录结构 → 精读选定文档 → 结论 `remember` 沉淀给下游 |
| 实现（读多写少） | `find` `recall` `grep` `read` | 定位"上次定的方案" → 拿架构决策 → 精确找错误码/函数名 → 读具体实现。**默认不开 `remember`**：实现过程是高频消息流，写了堆 VLM 费用且污染共享决策空间；只在发现"影响他人"的坑时写 |
| 审查/QA（纯读） | `find` `recall` | 只需对齐上下文（决策依据、历史结论），不生产新知识也不写 |
| 纯代码检查（无需上下文） | 不开 | 任务纯属静态分析，检索是多余一步，开了只拖慢 |

**两个易混点**：
- `remember` 是"写"侧工具，其余大多是"读"侧工具——权限矩阵的核心就是管控写权限。
- `recall` 只针对 `viking://user/{id}/memories/`（记忆），返回服务端组装好、带 token 预算的 `<memory>` 块，专为注入对话设计；`find` 是全空间语义搜索（资源+记忆+技能），返回原始排序结果让 agent 自己判断。**决策对齐用 `recall`，知识查找用 `find`**。

### 9.3 OpenViking 共享上下文 vs Handoff 文档

**一句话本质区别**：handoff 文档是**交接快照**（一次性、人可读、靠 Agent 自己找）；OpenViking 是**共享上下文池**（持续增量、机器可检索、按需注入）。

| 维度 | Handoff 文档 | OpenViking 共享上下文 |
|------|-------------|---------------------|
| 本质 | 时间点的上下文快照，写进一个 md 文件 | 持续维护的 `viking://` 命名空间，读写分离 |
| 传递方式 | Agent A 生成 → Agent B **整个读入**上下文 | Agent B `find`/`recall` **按需检索**注入 |
| 更新 | 每次交接重新生成，内容重复率高 | 增量写入，`remember` 一条是一条 |
| 检索 | 靠文件名/目录结构猜，多了靠 Agent 自己翻 | 语义搜索 + `grep` 精确匹配 + 轨迹可回放 |
| Token 消耗 | 全文灌入（除非手动摘录） | L0/L1/L2 按需加载，省 83-91% |
| 时效性 | 快照滞后：A 半小时前的新结论，不重新 handoff 就没有 | 实时可查：A `remember` 后 B 立即可 `find` |
| 并行协作 | 单写者，多 agent 并行写会互相覆盖 | 多 agent 可同时读写各自空间 |
| 人工可读性 | ✅ 人可直接打开看、审查、修改 | ❌ 记忆是摘要，人看需 `read` 展开 |
| 依赖 | 零依赖，一个文件 | server + Embedding/VLM，部署重 |
| 成本 | 只有写文档的时间 | VLM 摘要按量计费 + 异步延迟 |

**Handoff 文档优缺点**：
- ✅ 简单直接、零部署、完全可控、可 git 版本管理、人可审阅（合规友好）
- ❌ 无检索能力（文档一多就不知道哪份最新、读哪份）、全文灌入费 token、快照会过时、靠人记得写（不会自动沉淀）、并行协作难

**OpenViking 优缺点**：
- ✅ 自动沉淀（会话 commit 异步抽取，不打断工作流）、语义检索定位快、增量更新不过时、多 agent 并行、省 token、可观测（决策依据可回放）
- ❌ 部署重、写入要调 VLM（延迟+费用）、异步抽取不即时、Alpha 阶段（422 open issues）、数据绑定 AGFS+外部 VLM 迁移麻烦

**选择判断**：

| 情况 | 推荐 |
|------|------|
| 大阶段交接：调研 → 实现 → 审查，人参与验收 | **Handoff 为主**——交接点清晰、人可审阅、git 可追踪（opencode 自带 `/handoff` 命令） |
| 流程内实时协作：多 agent 并行、A 的结论 B 马上要用 | **OpenViking 为主**——handoff 跟不上节奏，每次重新生成就是上下文爆炸 |
| 跨会话长期沉淀：架构决策、踩坑记录反复复用 | **OpenViking**——handoff 文档越积越多就是一堆没人读的死文档 |

**务实建议：混合，不是二选一**——阶段边界（人参与）用 `/handoff` 文档当"人机界面"：给人看、给人审、留档审计；流程内（机器协作）用 OpenViking 当"机器间通道"：agent 之间即时检索共享。各取所长。

### 9.4 场景详解：流程内实时协作（多 agent 并行、A 结论 B 马上要用）

**成立条件**（三个同时满足）：
1. **逐步形成**：A 的结论是边探索边修正积累的，不是一次性产出；
2. **多消费者**：结论不止 B 要，C、D 也要，且各自需要的部分不同；
3. **即时性**：B 等不了"等 A 全部干完再生成交接文档"。

**三个典型例子**：

```
例1 架构决策 → 并行模块实现（最典型）
Agent A（架构拆解）
  │ · 模块划分：X 归 B、Y 归 C（决策1）
  │ · 中途修正：接口约定改了，X 要多传一个参数（决策2，推翻决策1一部分）
  │ · 发现坑：库 Z 的 v2 API 用法与文档不一致（经验）
  ▼
Agent B（模块X）─┐ Agent C（模块Y）─┼─ 并行启动，各自需要完整且最新的决策
Agent D（联调）─┘

例2 探索/调研 → 实现（零散发现难成文）
Agent A（explore）："入口在 src/main.c:142" / "编译要 -DCUSTOM_FLAG"（对话中逐步挖出）
  ▼
Agent B（实现）：马上要用发现1写代码、发现2配参数

例3 调试闭环
Agent A（定位根因："寄存器访问竞态，需加锁"）
  ▼
Agent B（修复）+ Agent C（测试，也要知道根因验证点）
```

**落地流程**：

```
Agent A（调研/架构）
  │  ov remember "模块划分：X 归 B、Y 归 C，接口约定见 viking://resources/interface.md"
  │  ov remember "修正：X 模块多传参数，旧约定作废"
  │  ov remember "坑：库 Z v2 API 与文档不一致，正确写法是..."
  ▼
viking:// 共享空间（viking://user/{team}/memories/）
  ├── Agent B：ov recall（启动即拿到 token 预算化的 <memory> 块，最新修正已含）
  ├── Agent C：ov recall（同上，各自空间独立）+ ov find（随时语义检索）
  └── 全程无需等 A 结束、无需共享同一份文档
```

**工具分工**：A 侧 `remember`（即时写入，不等异步）+ `session commit`（兜底沉淀过程经验）；B/C/D 侧 `recall`（启动拉记忆）+ `find`（随时检索）。

**为什么 handoff 在这里系统性失效**：

| handoff 的缺陷 | 实时协作里的具体表现 |
|---------------|---------------------|
| 时延 | B 在 A 完成一半时就需要结论，handoff 必须等 A 结束 |
| 修正传播 | 决策中途修正后，已生成/已读走的文档是旧版；重新生成要等人触发 |
| 多消费者重复成本 | B/C/D 各读一遍同一份全文 → 3 倍 token，且各自只需其中一段 |
| 人工触发 | 没人记得生成文档 = 没有传递；OpenViking 集成版自动提交会话 |

**使用纪律（最容易踩的坑）**：
1. **只沉淀"影响他人的结论"**：接口约定、架构修正、踩坑——写；"今天改了 3 个文件"这类过程消息——不写，否则共享空间被噪音淹没，`recall` 召回质量下降。
2. **即时结论用 `remember`，别依赖异步抽取**：`session commit` 的抽取是异步的，B 马上要用时可能还没生成；即时性要求高的结论一步 `remember` 写掉。
3. **实现 agent 留一个写口**：B 发现的新坑 C 可能也要用；有 `remember` 权限但纪律上只写"影响他人"的发现。
4. **结论要带上下文**：`remember "X 模块归 B"` 是裸结论，消费端搜到也看不懂为什么；写成 `"模块划分：X 归 B（Y 依赖其接口、职责内聚），旧方案作废"`——检索相关性更高，消费端也更省 token。

**落地到 subagent 配置**：

```markdown
# 架构/调研 agent（写 + 读）
tools: ..., mcp__openviking__remember, mcp__openviking__find,
       mcp__openviking__recall, mcp__openviking__read

# 实现 agent（读为主 + 关键发现可写）
tools: ..., mcp__openviking__find, mcp__openviking__recall,
       mcp__openviking__grep, mcp__openviking__read,
       mcp__openviking__remember   # 纪律：只写影响他人的发现

# 审查/QA agent（只读）
tools: ..., mcp__openviking__find, mcp__openviking__recall
```

共享空间用 team 级 `viking://user/{team}/memories/`，各 agent 私有偏好放自己 `{id}` 空间——实现"团队共享决策 + 个人私有画像"两层隔离。此场景是 8.4/8.5 的交叉点，也是最依赖**写入纪律**的场景：工具链全对但记忆写得又乱又碎，`recall` 召回质量照样崩。
