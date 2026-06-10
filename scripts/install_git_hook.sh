#!/bin/bash
# install_git_hook.sh — 安装 Git post-commit Hook 自动更新 CodeGraph 索引
# 用法: bash scripts/install_git_hook.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "=== 安装 Git post-commit Hook ==="

cd "$PROJECT_ROOT"

# 检查是否在 Git 仓库中
if [ ! -d ".git" ]; then
    echo "错误: 当前目录不是 Git 仓库根目录"
    exit 1
fi

HOOK_FILE=".git/hooks/post-commit"

# 检查是否已有 post-commit hook
if [ -f "$HOOK_FILE" ]; then
    echo "检测到已有 post-commit hook"
    echo "是否覆盖？(y/N)"
    read -r OVERWRITE
    if [ "$OVERWRITE" != "y" ] && [ "$OVERWRITE" != "Y" ]; then
        echo "跳过安装"
        exit 0
    fi
fi

# 创建 hook
cat > "$HOOK_FILE" << 'HOOKEOF'
#!/bin/bash
# Git post-commit hook: 自动更新 CodeGraph 索引
# 仅在有 C/H 文件变更时触发更新

PROJECT_ROOT="$(git rev-parse --show-toplevel)"
cd "$PROJECT_ROOT"

CHANGED_C_FILES=$(git diff-tree --no-commit-id --name-only -r HEAD | \
    grep -E '\.(c|h)$' | wc -l)

if [ "$CHANGED_C_FILES" -gt 0 ]; then
    echo "[CodeGraph] 检测到 C/H 文件变更，更新索引..."

    # ops-codegraph 增量更新
    if command -v codegraph &> /dev/null; then
        codegraph build 2>/dev/null &
    fi

    # ctags 更新
    if command -v ctags &> /dev/null; then
        CODE_DIRS=""
        for dir in source/app source/service source/driver source/os source/common source/platform src; do
            if [ -d "$dir" ]; then
                CODE_DIRS="$CODE_DIRS $dir"
            fi
        done
        if [ -n "$CODE_DIRS" ]; then
            find $CODE_DIRS -name "*.c" -o -name "*.h" 2>/dev/null | \
                ctags -L- --fields=+neKSt --extras=+q --c-kinds=+psgutdefl \
                    -o tags 2>/dev/null &
        fi
    fi

    # 不更新 cscope（耗时较长，用 init_codegraph.sh 手动更新）
    
    wait
    echo "[CodeGraph] 索引已更新"
fi
HOOKEOF

chmod +x "$HOOK_FILE"

echo "Git post-commit Hook 已安装到: $HOOK_FILE"
echo ""
echo "每次提交涉及 .c/.h 文件的变更后，将自动更新:"
echo "  - ops-codegraph 索引（增量，毫秒级）"
echo "  - ctags 索引（增量，秒级）"
echo ""
echo "注意: cscope 索引不会自动更新（耗时较长）"
echo "  需要手动更新时运行: bash scripts/init_codegraph.sh"