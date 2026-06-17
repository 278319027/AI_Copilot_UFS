#!/bin/bash
# deploy_tools.sh — 一键部署 SSD 固件 CodeGraph 工具链
# 用法: bash deploy_tools.sh <C源码路径>
# 示例: bash deploy_tools.sh /home/tcb/AI_Proj/femu/hw/femu
#
# 部署六个工具 (KNOW→PLAN→BUILD→FEEDBACK 四工具架构 + 基础设施):
#   1. codegraph  — KNOW 层：调用图/影响分析 (MCP 集成)
#   2. cscope     — KNOW 层：函数指针/宏查询 (CodeGraph 盲区补充)
#   3. doxygen    — KNOW 层：HTML 架构文档 (按需生成)
#   4. graphviz   — KNOW 层：doxygen 调用图渲染 (自动安装为 doxygen 依赖)
#   5. graphify   — KNOW/FEEDBACK 层：知识图谱
#   6. openspec   — PLAN/FEEDBACK 层：规格驱动开发 (Phase 1 新增)
#
# 注：Superpowers 是项目级 Skill 集（.opencode/skills/superpowers/），
#     随 zsf 仓库分发，不需本脚本安装。详见 .opencode/skills/superpowers/SKILL.md。
# ------------------------------------------------------------
# 工具链分工 / C 语言限制（合并自原 references/deploy-guide.md）
# ------------------------------------------------------------
# 前置要求: Linux/macOS, sudo 权限 (apt-get), 网络可达 npm/crates.io
# 覆盖模型: codegraph 80% (函数级调用图) + cscope 15% (函数指针/宏) + doxygen 5% (可视化)
# 工具分工: codegraph=调用图/影响 | cscope=函数指针/宏 | graphify=知识图谱 | doxygen=HTML 架构
# C 语言静态解析盲区 (tree-sitter):
#   函数指针调用 → cscope -d -L2/-L3 | 宏使用 → cscope -d -L4 | #ifdef → Doxyfile PREDEFINED
# MCP 集成: opencode.json 键为 `mcp` (非 mcpServers)，`command` 必须是数组
# ------------------------------------------------------------

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
echo "=== [1/6] Node.js 22 ==="

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
echo "=== [2/6] codegraph (调用图/影响分析) ==="

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
echo "=== [3/6] cscope (函数指针/宏查询) ==="

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
echo "=== [4/6] doxygen + graphviz (架构文档) ==="

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
echo "=== [5/6] graphify (知识图谱) ==="

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
# Step 6: OpenSpec CLI (规格驱动开发)
# ============================================================
echo ""
echo "=== [6/6] openspec (规格驱动开发) ==="

if command -v openspec &>/dev/null; then
    echo "  ✓ openspec $(openspec --version 2>&1 | head -1 | awk '{print $NF}') 已安装"
else
    echo "  → npm install -g @fission-ai/openspec ..."
    npm install -g @fission-ai/openspec
    echo "  ✓ openspec $(openspec --version 2>&1 | head -1 | awk '{print $NF}') 安装完成"
fi

# 在项目根初始化 openspec/ 目录（如未初始化）
OPENSPEC_DIR="$PROJECT_ROOT/openspec"
if [ -d "$OPENSPEC_DIR" ] && [ -f "$OPENSPEC_DIR/config.yaml" ]; then
    echo "  ✓ openspec/ 目录已初始化（config.yaml 存在）"
else
    echo "  → 初始化 openspec/ 目录..."
    cd "$PROJECT_ROOT" && openspec init 2>/dev/null || echo "  ⚠ openspec init 失败，可手动: cd $PROJECT_ROOT && openspec init"
    echo "  ✓ openspec/ 目录已创建"
fi

# 验证 OpenSpec 适配 Skill（随 zsf 仓库分发）
# 验证 OpenSpec 适配 Skill（随 zsf 仓库分发）
if [ -f ".opencode/skills/openspec-workflow/SKILL.md" ]; then
    echo "  ✓ openspec-workflow Skill 已就位 (propose/explore/apply/sync/archive 五合一)"
else
    echo "  ⚠ openspec-workflow Skill 未找到"
    echo "    请检查 .opencode/skills/openspec-workflow/ 目录是否完整克隆 zsf 仓库"
fi

# Superpowers 提示（项目级 Skill，不需本脚本安装）
if [ -d ".opencode/skills/superpowers" ]; then
    SP_COUNT=$(ls -1 .opencode/skills/superpowers/ 2>/dev/null | grep -v '^SKILL.md$' | wc -l)
    echo "  ✓ Superpowers 项目级 Skill 已就位 (${SP_COUNT} 个子技能 + SKILL.md)"
    echo "    入口: .opencode/skills/superpowers/SKILL.md"
else
    echo "  ⚠ Superpowers 项目级 Skill 未找到"
    echo "    请检查 .opencode/skills/superpowers/ 目录是否完整克隆 zsf 仓库"
fi

# 完成
# ============================================================
echo ""
echo "=============================================="
echo "  部署完成"
echo "=============================================="
echo ""
echo "  已安装工具 (六件套):"
echo "    codegraph  — $(codegraph --version 2>/dev/null || echo '需手动安装')  [KNOW]"
echo "    cscope     — $(cscope --version 2>&1 | head -1 || echo 'N/A')  [KNOW]"
echo "    doxygen    — $(doxygen --version 2>/dev/null || echo 'N/A')  [KNOW]"
echo "    graphviz   — $(dot -V 2>&1 | head -1 || echo 'N/A')  [KNOW]"
echo "    graphify   — $(graphify --version 2>&1 | head -1 | awk '{print $NF}' || echo 'N/A')  [KNOW/FEEDBACK]"
echo "    graphify-out/   — 知识图谱 (graph.json + graph.html)"
echo "    openspec   — $(openspec --version 2>&1 | head -1 | awk '{print $NF}' || echo '需手动安装')  [PLAN/FEEDBACK]"
echo "    openspec/  — 规格仓库 (config.yaml + changes/ + specs/)"
echo ""
echo "  项目级 Skill（随 zsf 仓库分发，无需部署）:"
SP_COUNT=$(ls -1 .opencode/skills/superpowers/ 2>/dev/null | grep -v '^SKILL.md$' | wc -l)
echo "    openspec-workflow/  — OpenSpec 完整工作流 Skill (propose/explore/apply/sync/archive 五合一)  [PLAN/FEEDBACK]"
echo "    superpowers/        — ${SP_COUNT} 个子技能（test-driven-development / systematic-debugging / verification-before-completion / ...）  [BUILD]"
echo "    sd-firmware-copilot/ — SSD 固件领域规则 + 规格管理 [ALL]"
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
echo "    # OpenSpec 规格驱动（PLAN/FEEDBACK）"
echo "    openspec list                                # 列出所有变更"
echo "    openspec --help                              # 查看全部命令"
echo "    # 在 OpenCode Agent 中使用:"
echo "    /opsx:propose '<change-id>' '<意图>'         # 创建变更 + 生成所有工件"
echo "    /opsx:apply '<change-id>'                    # 按 tasks.md 执行"
echo "    /opsx:archive '<change-id>'                  # 合并到 baseline"
echo ""
echo "    # Superpowers 铁律（BUILD）— 详见 .opencode/skills/superpowers/SKILL.md"
echo "    test-driven-development                       # 先写失败测试"
echo "    systematic-debugging                          # 无根因不修"
echo "    verification-before-completion                # 不验证不宣称完成"
echo ""
echo "    ${SRC_DIR}"
echo ""
echo "=============================================="


# ============================================================
# Step 7: 自动环境验证 (init.sh --check-only)
#   部署工具链后，调用 init.sh 的只读验证模式检查项目根状态
#   注意: 此步骤是信息性的，验证失败不会中断 deploy_tools.sh
# ============================================================
INIT_SCRIPT="$(cd "$(dirname "$0")" && pwd)/.opencode/skills/sd-firmware-copilot/init.sh"
if [ ! -f "$INIT_SCRIPT" ]; then
    echo ""
    echo "=== 环境验证 (init.sh --check-only) ==="
    echo "  ⚠ init.sh 未找到: $INIT_SCRIPT"
    echo "  跳过环境验证"
else
    echo ""
    echo "=== 环境验证 (init.sh --check-only) ==="
    # 临时关闭 set -e: init.sh --check-only 失败不应中断 deploy_tools.sh
    set +e
    bash "$INIT_SCRIPT" --check-only
    INIT_RC=$?
    set -e
    if [ $INIT_RC -eq 0 ]; then
        echo "✓ 环境验证通过"
    else
        echo "⚠ 环境验证发现问题，请运行: bash .opencode/skills/sd-firmware-copilot/init.sh"
    fi
fi
