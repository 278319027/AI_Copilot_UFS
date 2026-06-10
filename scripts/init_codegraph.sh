#!/bin/bash
# init_codegraph.sh — 在 SSD 固件项目中初始化 CodeGraph 索引
# 用法: cd /path/to/ssd_firmware && bash scripts/init_codegraph.sh
#
# 前置条件: 已运行 scripts/install_codegraph.sh

set -e

# 检测项目根目录
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "========================================="
echo " CodeGraph 项目初始化"
echo " 项目根目录: $PROJECT_ROOT"
echo "========================================="
echo ""

cd "$PROJECT_ROOT"

# ─────────────────────────────────────────────
# Step 1: ops-codegraph 索引
# ─────────────────────────────────────────────
echo "=== Step 1: 构建 ops-codegraph 索引 ==="

if ! command -v codegraph &> /dev/null; then
    echo "错误: codegraph 未安装"
    echo "请先运行: bash scripts/install_codegraph.sh"
    exit 1
fi

# 检查是否已有索引，提示是否重建
if [ -d ".codegraph" ] && [ -f ".codegraph/graph.db" ]; then
    echo "检测到已有 ops-codegraph 索引"
    echo "是否重建？(y/N)"
    read -r REBUILD
    if [ "$REBUILD" = "y" ] || [ "$REBUILD" = "Y" ]; then
        codegraph build
    else
        echo "跳过 ops-codegraph 索引构建"
    fi
else
    codegraph build
fi

echo ""
echo "ops-codegraph 索引统计:"
codegraph stats 2>/dev/null || echo "(统计信息不可用，索引可能为空)"
echo ""

# ─────────────────────────────────────────────
# Step 2: ctags 索引
# ─────────────────────────────────────────────
echo "=== Step 2: 构建 ctags 索引 ==="

mkdir -p .codegraph

# 查找源码目录
CODE_DIRS=""
for dir in source/app source/service source/driver source/os source/common source/platform src; do
    if [ -d "$dir" ]; then
        CODE_DIRS="$CODE_DIRS $dir"
    fi
done

if [ -z "$CODE_DIRS" ]; then
    echo "警告: 未找到标准源码目录 (source/ 或 src/)"
    echo "将扫描项目根目录下的所有 .c/.h 文件"
    CODE_DIRS="."
fi

echo "扫描目录:$CODE_DIRS"

# 生成 tags 文件（编辑器使用）
find $CODE_DIRS -name "*.c" -o -name "*.h" 2>/dev/null | \
    ctags -L- --fields=+neKSt --extras=+q --c-kinds=+psgutdefl -o tags 2>/dev/null || \
    echo "ctags 生成失败（可能没有 .c/.h 文件）"

# 生成 JSON 索引（OpenCode Agent 使用）
find $CODE_DIRS -name "*.c" -o -name "*.h" 2>/dev/null | \
    ctags -L- --fields=+neKSt --extras=+q --c-kinds=+psgutdefl \
        --output-format=json -o .codegraph/ctags_index.json 2>/dev/null || \
    echo "ctags JSON 生成失败"

if [ -f "tags" ]; then
    TAG_COUNT=$(grep -c '' tags 2>/dev/null || echo "0")
    echo "ctags 索引: $TAG_COUNT 个标签"
else
    echo "ctags 索引: 未生成（可能没有 .c/.h 文件）"
fi
echo ""

# ─────────────────────────────────────────────
# Step 3: cscope 数据库
# ─────────────────────────────────────────────
echo "=== Step 3: 构建 cscope 数据库 ==="

find $CODE_DIRS -name "*.c" -o -name "*.h" 2>/dev/null > .codegraph/cscope.files

CSCOPE_COUNT=$(wc -l < .codegraph/cscope.files 2>/dev/null || echo "0")

if [ "$CSCOPE_COUNT" -gt 0 ]; then
    cscope -b -q -k -i .codegraph/cscope.files
    echo "cscope 数据库: $CSCOPE_COUNT 个文件"
else
    echo "cscope 数据库: 跳过（没有 .c/.h 文件）"
    echo "  将在源码加入后运行: cscope -b -q -k -i .codegraph/cscope.files"
fi
echo ""

# ─────────────────────────────────────────────
# Step 4: 验证配置文件
# ─────────────────────────────────────────────
echo "=== Step 4: 验证配置文件 ==="

if [ ! -f ".codegraph/config.json" ]; then
    echo "创建默认 .codegraph/config.json..."
    cat > .codegraph/config.json << 'JSONEOF'
{
  "exclude": [
    "third_party/**",
    "vendor/**",
    "test/**",
    "tests/**",
    "_build/**",
    "out/**",
    "build/**"
  ]
}
JSONEOF
    echo ".codegraph/config.json 已创建"
else
    echo ".codegraph/config.json 已存在"
fi

if [ ! -f "Doxyfile" ] && [ ! -f ".codegraph/Doxyfile" ]; then
    echo "提示: Doxyfile 尚未创建"
    echo "  运行以下命令生成: doxygen -g .codegraph/Doxyfile"
    echo "  然后参考教程修改配置项"
else
    echo "Doxyfile 已存在"
fi
echo ""

# ─────────────────────────────────────────────
# Step 5: 验证 MCP 服务器
# ─────────────────────────────────────────────
echo "=== Step 5: 验证 ops-codegraph MCP 服务器 ==="

echo "测试 codegraph mcp 命令..."
timeout 5 codegraph mcp --help 2>/dev/null || echo "(MCP 命令验证跳过，非错误)"
echo ""

# ─────────────────────────────────────────────
# 完成
# ─────────────────────────────────────────────
echo "========================================="
echo " CodeGraph 初始化完成！"
echo "========================================="
echo ""
echo " 索引文件:"
echo "   ops-codegraph: .codegraph/graph.db"
echo "   ctags:         tags + .codegraph/ctags_index.json"
echo "   cscope:        cscope.out + cscope.in.out + cscope.po.out"
echo ""
echo " 常用命令:"
echo "   codegraph find <symbol>      搜索符号"
echo "   codegraph callers <func>     查询谁调用了函数"
echo "   codegraph callees <func>     查询函数调用了谁"
echo "   codegraph impact <file>      影响分析"
echo "   codegraph deps <dir>         模块依赖"
echo "   codegraph stats              查看索引统计"
echo "   cscope -d -L2 <func>        补充函数指针查询"
echo ""
echo " Git Hook 安装（可选）:"
echo "   bash scripts/install_git_hook.sh"
echo ""
echo " Doxygen 构建（可选）:"
echo "   cd /path/to/ssd_firmware && doxygen Doxyfile"