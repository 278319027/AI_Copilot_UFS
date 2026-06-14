#!/bin/bash
# deploy_tools.sh — 一键部署 SSD 固件 CodeGraph 工具链
# 用法: bash deploy_tools.sh <C源码路径>
# 示例: bash deploy_tools.sh /home/tcb/AI_Proj/femu/hw/femu
#
# 部署四个工具:
#   1. codegraph  — 调用图/影响分析 (MCP 集成)
#   2. cscope     — 函数指针/宏查询 (CodeGraph 盲区补充)
#   3. doxygen    — HTML 架构文档 (按需生成)
#   4. graphviz   — doxygen 调用图渲染 (自动安装为 doxygen 依赖)

set -e

# ============================================================
# 参数解析
# ============================================================
SRC_DIR="${1:-}"
if [ -z "$SRC_DIR" ]; then
    echo "用法: bash $0 <C源码路径>"
    echo "示例: bash $0 /path/to/ssd_firmware/src"
    exit 1
fi

if [ ! -d "$SRC_DIR" ]; then
    echo "错误: 目录不存在 — $SRC_DIR"
    exit 1
fi

SRC_DIR="$(realpath "$SRC_DIR")"
PROJECT_ROOT="$(dirname "$SRC_DIR")"
HAS_NODE="false"
HAS_CODEGRAPH="false"

echo "=============================================="
echo " SSD 固件 CodeGraph 工具链一键部署"
echo "=============================================="
echo "  目标路径: $SRC_DIR"
echo "  项目根:   $PROJECT_ROOT"
echo "=============================================="
echo ""

# ============================================================
# Step 1: Node.js 22 (codegraph 依赖)
# ============================================================
echo "=== [1/4] Node.js 22 ==="

export NVM_DIR="${HOME}/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"

if command -v node &>/dev/null && [ "$(node -v | cut -d. -f1 | cut -dv -f2)" -ge 18 ]; then
    echo "  ✓ Node.js $(node -v) 已满足要求"
else
    echo "  → 安装 nvm + Node.js 22..."
    curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
    [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
    nvm install 22
    nvm use 22
    echo "  ✓ Node.js $(node -v) 安装完成"
fi
HAS_NODE="true"

# ============================================================
# Step 2: codegraph
# ============================================================
echo ""
echo "=== [2/4] codegraph (调用图/影响分析) ==="

if command -v codegraph &>/dev/null; then
    echo "  ✓ codegraph $(codegraph --version) 已安装"
else
    echo "  → npm install -g @optave/codegraph ..."
    npm install -g @optave/codegraph
    echo "  ✓ codegraph $(codegraph --version) 安装完成"
fi
HAS_CODEGRAPH="true"

# 构建/更新 codegraph 索引
CODEGRAPH_DIR="$SRC_DIR/.codegraph"
if [ -f "$CODEGRAPH_DIR/graph.db" ]; then
    echo "  → codegraph 索引已存在，增量更新..."
    cd "$PROJECT_ROOT" && codegraph init "$(basename "$SRC_DIR")" 2>/dev/null || \
        (cd "$SRC_DIR" && codegraph build 2>/dev/null) || true
    echo "  ✓ codegraph 索引已更新"
else
    echo "  → 首次构建 codegraph 索引 (仅扫描 $SRC_DIR)..."
    cd "$PROJECT_ROOT" && codegraph init "$(basename "$SRC_DIR")" 2>/dev/null || \
        (cd "$SRC_DIR" && codegraph build 2>/dev/null) || \
        echo "  ⚠ codegraph 索引构建需手动执行: cd $PROJECT_ROOT && codegraph init $(basename "$SRC_DIR")"
fi

# ============================================================
# Step 3: cscope (函数指针/宏)
# ============================================================
echo ""
echo "=== [3/4] cscope (函数指针/宏查询) ==="

if command -v cscope &>/dev/null; then
    echo "  ✓ cscope $(cscope --version 2>&1 | head -1 | awk '{print $NF}') 已安装"
else
    echo "  → apt install cscope ..."
    sudo apt-get install -y cscope
    echo "  ✓ cscope 安装完成"
fi

# 构建 cscope 数据库
CSCOPE_DIR="$SRC_DIR/.codegraph"
mkdir -p "$CSCOPE_DIR"

C_FILE_COUNT=$(find "$SRC_DIR" -name "*.c" -o -name "*.h" 2>/dev/null | wc -l)
if [ "$C_FILE_COUNT" -eq 0 ]; then
    echo "  ⚠ 未找到 .c/.h 文件，跳过 cscope 索引构建"
else
    echo "  → 扫描 $C_FILE_COUNT 个 C/H 文件..."
    find "$SRC_DIR" -name "*.c" -o -name "*.h" > "$CSCOPE_DIR/cscope.files"
    cscope -b -q -k -i "$CSCOPE_DIR/cscope.files" 2>/dev/null
    echo "  ✓ cscope 数据库已构建 ($CSCOPE_DIR/cscope.out)"
fi

# ============================================================
# Step 4: doxygen + graphviz (架构文档可视化)
# ============================================================
echo ""
echo "=== [4/4] doxygen + graphviz (架构文档) ==="

DOXY_INSTALLED="false"
if command -v doxygen &>/dev/null; then
    echo "  ✓ doxygen $(doxygen --version) 已安装"
    DOXY_INSTALLED="true"
else
    echo "  → apt install doxygen graphviz ..."
    sudo apt-get install -y doxygen graphviz
    echo "  ✓ doxygen $(doxygen --version) 安装完成"
    DOXY_INSTALLED="true"
fi

if command -v dot &>/dev/null; then
    echo "  ✓ graphviz $(dot -V 2>&1 | head -1 | awk '{print $NF}') 已安装"
fi

# 生成 Doxyfile（如不存在）
DOXYFILE="$PROJECT_ROOT/Doxyfile"
if [ ! -f "$DOXYFILE" ]; then
    echo "  → 生成 Doxyfile ..."
    doxygen -g "$DOXYFILE" 2>/dev/null
    # 最小化配置
    cat > "$DOXYFILE" << DOXYEOF
# 最小化 Doxygen 配置 — 由 deploy_tools.sh 生成
PROJECT_NAME           = "SSD Firmware"
OUTPUT_DIRECTORY       = .codegraph/doxygen
INPUT                  = $(basename "$SRC_DIR")
FILE_PATTERNS          = *.c *.h
RECURSIVE              = YES
EXTRACT_ALL            = YES
EXTRACT_PRIVATE        = YES
EXTRACT_STATIC         = YES
HAVE_DOT               = YES
CALL_GRAPH             = YES
CALLER_GRAPH           = YES
DOT_IMAGE_FORMAT       = svg
INTERACTIVE_SVG        = YES
GENERATE_HTML          = YES
GENERATE_LATEX         = NO
SOURCE_BROWSER         = YES
OPTIMIZE_OUTPUT_FOR_C  = YES
QUIET                  = YES
WARN_IF_UNDOCUMENTED   = NO
DOXYEOF
    echo "  ✓ Doxyfile 已生成"
else
    echo "  ✓ Doxyfile 已存在"
fi

# ============================================================
# Step 5: graphify (知识图谱)
# ============================================================
echo ""
echo "=== [5/5] graphify (知识图谱) ==="

if command -v graphify &>/dev/null; then
    echo "  ✓ graphify $(graphify --version 2>&1 | head -1 | awk '{print $NF}')"
else
    echo "  → uv tool install graphify[all] ..."
    if ! command -v uv &>/dev/null; then
        curl -LsSf https://astral.sh/uv/install.sh | sh
        export PATH="$HOME/.cargo/bin:$PATH"
    fi
    uv tool install 'graphify[all]'
    echo "  ✓ graphify 安装完成"
fi

# 注册 OpenCode Skill + Git Hook
GRAPHIFY_SKILL_DIR=".opencode/skills/graphify"
if [ -d "$GRAPHIFY_SKILL_DIR" ]; then
    echo "  ✓ graphify Skill 已注册"
else
    echo "  → graphify opencode install ..."
    graphify opencode install 2>/dev/null || echo "  ⚠ Skill 注册失败，可手动: graphify opencode install"
fi

# 构建知识图谱（code-only，无需 LLM API key）
if [ -d "$SRC_DIR/graphify-out" ] && [ -f "$SRC_DIR/graphify-out/graph.json" ]; then
    echo "  → 知识图谱已存在，增量更新..."
    cd "$PROJECT_ROOT" && graphify extract "$(basename "$SRC_DIR")" --no-cluster 2>/dev/null || true
    echo "  ✓ 知识图谱已更新"
else
    echo "  → 首次构建知识图谱 (AST-only)..."
    cd "$PROJECT_ROOT" && graphify extract "$(basename "$SRC_DIR")" --no-cluster 2>/dev/null
fi

# 社区检测
cd "$PROJECT_ROOT" && graphify cluster-only "$(basename "$SRC_DIR")" --no-label 2>/dev/null || true
echo "  ✓ 社区检测完成"

echo "  → 论文语义提取需配置 DEEPSEEK_API_KEY (当前仅 code-only)"


# ============================================================
# 完成
# ============================================================
echo ""
echo "=============================================="
echo "  部署完成"
echo "=============================================="
echo ""
echo "  已安装工具:"
echo "    codegraph  — $(codegraph --version 2>/dev/null || echo '需手动安装')"
echo "    cscope     — $(cscope --version 2>&1 | head -1 || echo 'N/A')"
echo "    doxygen    — $(doxygen --version 2>/dev/null || echo 'N/A')"
echo "    graphviz   — $(dot -V 2>&1 | head -1 || echo 'N/A')"
echo "    graphify     — $(graphify --version 2>&1 | head -1 | awk '{print $NF}' || echo 'N/A')"
echo "    graph-out/   — 知识图谱 (graph.json + graph.html)"
echo ""
echo "  索引位置: $CODEGRAPH_DIR/"
echo "    graph.db        — codegraph SQLite 数据库"
echo "    cscope.out      — cscope 交叉引用数据库"
echo ""
echo "  后续操作:"
echo "    # AI 查询调用图"
echo "    codegraph callers <函数名>"
echo "    codegraph explore <关键词>"
echo "    # 知识图谱查询"
echo "    graphify query '<问题>'"
echo "    graphify explain '<概念>'"
echo ""
echo "    # 补充函数指针查询"
echo "    cscope -d -L2 '<函数指针名>'"
echo ""
echo "    # 生成架构文档（按需）"
echo "    cd $PROJECT_ROOT && doxygen Doxyfile"
echo ""
echo "  当前 codegraph MCP 配置路径:"
echo "    ${SRC_DIR}"
echo ""
echo "=============================================="
