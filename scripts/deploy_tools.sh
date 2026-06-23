#!/bin/bash
# scripts/deploy_tools.sh — 一键部署 SSD 固件 CodeGraph 工具链
# 用法: bash scripts/deploy_tools.sh <C源码路径>
# 示例: bash scripts/deploy_tools.sh /home/tcb/AI_Proj/femu/hw/femu
#
# 部署四个工具 (KNOW→PLAN→BUILD→FEEDBACK 四工具架构 + 基础设施):
#   1. codegraph  — KNOW 层：调用图/影响分析 (MCP 集成)
#   2. graphify   — KNOW/FEEDBACK 层：知识图谱
#   3. openspec   — PLAN/FEEDBACK 层：规格驱动开发 (Phase 1 新增)
#
# 注：Superpowers 是项目级 Skill 集（.opencode/skills/superpowers-*/），
#     随 zsf 仓库分发，不需本脚本安装。入口整合至 sd-firmware-copilot/SKILL.md §Superpowers 框架整合。
# ------------------------------------------------------------
# 工具链分工 / C 语言限制（合并自原 references/deploy-guide.md）
# ------------------------------------------------------------
# 前置要求: Linux/macOS, sudo 权限 (apt-get), 网络可达 npm/crates.io
# 工具分工: codegraph=调用图/影响 | graphify=知识图谱
# C 语言静态解析盲区 (tree-sitter): 无（CodeGraph 基于 AST，不追踪函数指针调用）

# CodeGraph 基于 AST，不追踪函数指针调用；请用 symbol_search + 手工读取 dispatch 函数验证
# MCP 集成: opencode.json 键为 `mcp` (非 mcpServers)，`command` 必须是数组
# ------------------------------------------------------------

set -e

# ============================================================
# 参数解析
# ============================================================
DRY_RUN=0
SRC_DIR=""

for arg in "$@"; do
    case "$arg" in
        --dry-run)
            DRY_RUN=1
            echo "=== DRY RUN 模式 ==="
            echo "  只检查依赖和输出操作计划，不实际安装或构建"
            echo ""
            ;;
        -*)
            echo "未知选项: $arg"
            echo "用法: bash $0 [--dry-run] <C源码路径>"
            exit 1
            ;;
        *)
            SRC_DIR="$arg"
            ;;
    esac
done

if [ -z "$SRC_DIR" ]; then
    echo "用法: bash $0 [--dry-run] <C源码路径>"
    echo "示例: bash $0 /path/to/ssd_firmware/src"
    echo "       bash $0 --dry-run /path/to/ssd_firmware/src"
    exit 1
fi

if [ ! -d "$SRC_DIR" ]; then
    echo "错误: 目录不存在 — $SRC_DIR"
    exit 1
fi

# realpath 可移植性: 用 cd/pwd 替代 (realpath 在 coreutils/macOS 行为不同, 部分镜像不可用)

SRC_DIR="$(cd "$SRC_DIR" && pwd)"

PROJECT_ROOT="$(dirname "$SRC_DIR")"
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
echo "=== [1/5] Node.js 22 ==="

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

# ============================================================
# Step 2: codegraph
# ============================================================
echo ""
echo "=== [2/5] codegraph (调用图/影响分析) ==="

if command -v codegraph &>/dev/null; then
    echo "  ✓ codegraph $(codegraph --version) 已安装"
else
    echo "  → npm install -g @optave/codegraph@latest ..."
    npm install -g @optave/codegraph@latest
    echo "  ✓ codegraph $(codegraph --version) 安装完成"
fi

# 构建/更新 codegraph 索引
CODEGRAPH_DIR="$SRC_DIR/.codegraph"
_CODEGRAPH_BUILD_OK=0
if [ -f "$CODEGRAPH_DIR/graph.db" ]; then
    echo "  → codegraph 索引已存在，增量更新..."
    if cd "$PROJECT_ROOT" && codegraph init "$(basename "$SRC_DIR")" 2>/dev/null || \
       (cd "$SRC_DIR" && codegraph build 2>/dev/null); then
        _CODEGRAPH_BUILD_OK=1
        echo "  ✓ codegraph 索引已更新"
    else
        echo "  ✗ codegraph 增量更新失败"
        exit 1
    fi
else
    echo "  → 首次构建 codegraph 索引 (仅扫描 $SRC_DIR)..."
    if cd "$PROJECT_ROOT" && codegraph init "$(basename "$SRC_DIR")" 2>/dev/null || \
       (cd "$SRC_DIR" && codegraph build 2>/dev/null); then
        _CODEGRAPH_BUILD_OK=1
        echo "  ✓ codegraph 索引构建完成"
    else
        echo "  ✗ codegraph 索引构建失败"
        exit 1
    fi
fi

# codegraph 索引有效性验证
if [ "$_CODEGRAPH_BUILD_OK" -eq 1 ] && command -v codegraph &>/dev/null; then
    echo "  → 验证 codegraph 索引有效性..."
    _CG_STATS=$(cd "$SRC_DIR" && codegraph stats 2>/dev/null || echo "")
    _CG_NODES=$(echo "$_CG_STATS" | grep -oE "Nodes: [0-9]+" | awk '{print $2}')
    _CG_EDGES=$(echo "$_CG_STATS" | grep -oE "Edges: [0-9]+" | awk '{print $2}')
    if [ -n "$_CG_NODES" ] && [ "$_CG_NODES" -gt 0 ] && [ -n "$_CG_EDGES" ] && [ "$_CG_EDGES" -gt 0 ]; then
        echo "  ✓ codegraph 索引有效 (Nodes=$_CG_NODES, Edges=$_CG_EDGES)"
    else
        echo "  ✗ codegraph 索引无效 (Nodes=${_CG_NODES:-0}, Edges=${_CG_EDGES:-0})"
        echo "    可能原因: codegraph 版本不支持 C 语言提取器"
        echo "    修复: npm install -g @optave/codegraph@latest && rm -rf .codegraph && codegraph build"
        exit 1
    fi
fi

# ============================================================
# Step 3: graphify (知识图谱)
# ============================================================

echo ""
echo "=== [3/5] python3-pip + graphify (知识图谱) ==="

if python3 -m pip --version &>/dev/null; then
    echo "  ✓ pip $(python3 -m pip --version | awk '{print $2}') 已安装"
else
    if [ "$DRY_RUN" -eq 1 ]; then
        echo "  [DRY-RUN] 将执行: sudo apt-get install -y python3-pip"
    else
        echo "  → apt install python3-pip ..."
        sudo apt-get install -y python3-pip
        echo "  ✓ python3-pip 安装完成"
    fi
fi

GRAPHIFY_VENV="$HOME/.local/share/graphify-venv"
GRAPHIFY_PKG="graphifyy==0.4.2"
if command -v graphify &>/dev/null; then
    echo "  ✓ graphify $(graphify --version 2>&1 | head -1 | awk '{print $NF}') 已安装"
elif [ "$DRY_RUN" -eq 1 ]; then
    echo "  [DRY-RUN] graphify 未安装，将创建 venv 并安装 $GRAPHIFY_PKG"
else
    if [ "$DRY_RUN" -eq 1 ]; then
        echo "  [DRY-RUN] 将执行: python3 -m venv $GRAPHIFY_VENV"
        echo "  [DRY-RUN] 将执行: pip install $GRAPHIFY_PKG"
    else
        echo "  → 创建隔离 venv 并安装 $GRAPHIFY_PKG ..."
        python3 -m venv "$GRAPHIFY_VENV"
        "$GRAPHIFY_VENV/bin/pip" install --upgrade pip
        if ! "$GRAPHIFY_VENV/bin/pip" install "$GRAPHIFY_PKG"; then
            echo "  ✗ graphify 安装失败 (包名: $GRAPHIFY_PKG)"
            echo "    请检查网络连接和 PyPI 可达性"
            exit 1
        fi
        mkdir -p "$HOME/.local/bin"
        ln -sf "$GRAPHIFY_VENV/bin/graphify" "$HOME/.local/bin/graphify"
        export PATH="$HOME/.local/bin:$PATH"
        echo "  ✓ graphify $(graphify --version 2>&1 | head -1 | awk '{print $NF}') 安装完成 (venv: $GRAPHIFY_VENV)"
    fi
fi

GRAPHIFY_SKILL_DIR=".opencode/skills/graphify"
if [ -d "$GRAPHIFY_SKILL_DIR" ]; then
    echo "  ✓ graphify Skill 已注册"
else
    echo "  → graphify opencode install ..."
    graphify opencode install 2>/dev/null || echo "  ⚠ Skill 注册失败，可手动: graphify opencode install"
fi

GRAPHIFY_OK=0
if [ -d "$SRC_DIR/graphify-out" ] && [ -f "$SRC_DIR/graphify-out/graph.json" ]; then
    echo "  → 知识图谱已存在，增量更新..."
    if cd "$PROJECT_ROOT" && graphify update "$(basename "$SRC_DIR")" --no-cluster 2>/dev/null; then
        echo "  ✓ 知识图谱已更新"
        GRAPHIFY_OK=1
    else
        echo "  ✗ graphify 增量更新失败"
        exit 1
    fi
else
    echo "  → 首次构建知识图谱 (AST-only, 无需 LLM key)..."
    if cd "$PROJECT_ROOT" && graphify update "$(basename "$SRC_DIR")" --no-cluster 2>/dev/null; then
        echo "  ✓ 知识图谱构建完成"
        GRAPHIFY_OK=1
    else
        echo "  ✗ graphify 首次构建失败"
        exit 1
    fi
fi

if [ "$GRAPHIFY_OK" -eq 1 ]; then
    echo "  → 社区检测 (Louvain)..."
    if cd "$PROJECT_ROOT" && graphify cluster-only "$(basename "$SRC_DIR")" --no-label 2>/dev/null; then
        echo "  ✓ 社区检测完成"
    else
        echo "  ✗ graphify 社区检测失败"
        exit 1
    fi
fi
echo "  → 语义提取需配置 DEEPSEEK_API_KEY (当前仅 code-only)"
# ============================================================

# Step 4: OpenSpec CLI (规格驱动开发)
# ============================================================
echo ""
echo "=== [4/5] openspec (规格驱动开发) ==="

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

    # --tools opencode 跳过交互式工具选择, 适配 CI/脚本场景

    cd "$PROJECT_ROOT" && openspec init --tools opencode 2>/dev/null || echo "  ⚠ openspec init 失败，可手动: cd $PROJECT_ROOT && openspec init --tools opencode"

    # 显式验证 init 成功 (config.yaml 是 openspec CLI 写入的标记文件)

    if [ -f "$OPENSPEC_DIR/config.yaml" ]; then

        echo "  ✓ openspec/ 目录已创建 (config.yaml 存在)"

    else

        echo "  ⚠ openspec init 未生成 config.yaml, 请检查 openspec CLI 版本 (需 v1.4.1+)"

    fi

fi

# 验证 OpenSpec 适配 Skill（随 zsf 仓库分发）
if [ -f ".opencode/skills/openspec-workflow/SKILL.md" ]; then
    echo "  ✓ openspec-workflow Skill 已就位 (propose/explore/apply/sync/archive 五合一)"
else
    echo "  ⚠ openspec-workflow Skill 未找到"
    echo "    请检查 .opencode/skills/openspec-workflow/ 目录是否完整克隆 zsf 仓库"
fi

# Superpowers 提示（项目级 Skill，不需本脚本安装）
if compgen -G ".opencode/skills/superpowers-*" >/dev/null; then
    SP_COUNT=$(ls -1d .opencode/skills/superpowers-*/ 2>/dev/null | wc -l)
    echo "  ✓ Superpowers 项目级 Skill 已就位 (${SP_COUNT} 个子技能)"
    echo "    入口: sd-firmware-copilot/SKILL.md §Superpowers 框架整合"
else
    echo "  ⚠ Superpowers 项目级 Skill 未找到"
    echo "    请检查 .opencode/skills/superpowers-*/ 目录是否完整克隆 zsf 仓库"
fi

# 完成
# ============================================================
echo ""
echo "=============================================="
echo "  部署完成"
echo "=============================================="
echo ""
echo "  已安装工具:"
echo "    codegraph  $(codegraph --version 2>/dev/null || echo '需手动安装')"
echo "    graphify   $(graphify --version 2>&1 | head -1 | awk '{print $NF}' || echo 'N/A')"
echo "    openspec   $(openspec --version 2>&1 | head -1 | awk '{print $NF}' || echo '需手动安装')"
echo ""
echo "  后续操作见 docs/quickref.md（AI session 开始时必跑的 M-5 步骤、命令清单）"
echo "  完整环境验证请跑: bash scripts/verify.sh"
echo ""
echo "  ${SRC_DIR}"
