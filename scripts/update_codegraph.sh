#!/bin/bash
# update_codegraph.sh — 增量更新 CodeGraph 索引
# 用法: bash scripts/update_codegraph.sh [--full]
#
# 不带参数: 只更新 ops-codegraph 增量索引（毫秒级）
# --full:   全量更新 ops-codegraph + ctags + cscope（秒级）

set -e

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_ROOT"

FULL_UPDATE=false
if [ "$1" = "--full" ]; then
    FULL_UPDATE=true
fi

echo "[CodeGraph] 开始更新..."

# ─────────────────────────────────────────────
# 始终更新: ops-codegraph 增量索引（毫秒级）
# ─────────────────────────────────────────────
if command -v codegraph &> /dev/null; then
    codegraph build
    echo "[CodeGraph] ops-codegraph 索引已更新"
else
    echo "[CodeGraph] 警告: codegraph 未安装，跳过 ops-codegraph 更新"
    echo "  安装: npm install -g @optave/codegraph"
fi

if [ "$FULL_UPDATE" = true ]; then
    # ─────────────────────────────────────────────
    # 全量更新: ctags + cscope（秒级）
    # ─────────────────────────────────────────────
    
    # 查找源码目录
    CODE_DIRS=""
    for dir in source/app source/service source/driver source/os source/common source/platform src; do
        if [ -d "$dir" ]; then
            CODE_DIRS="$CODE_DIRS $dir"
        fi
    done
    
    if [ -n "$CODE_DIRS" ]; then
        # 更新 ctags
        if command -v ctags &> /dev/null; then
            find $CODE_DIRS -name "*.c" -o -name "*.h" 2>/dev/null | \
                ctags -L- --fields=+neKSt --extras=+q --c-kinds=+psgutdefl -o tags 2>/dev/null
            echo "[CodeGraph] ctags 索引已更新"
        fi
        
        # 更新 ctags JSON
        if [ -d ".codegraph" ]; then
            find $CODE_DIRS -name "*.c" -o -name "*.h" 2>/dev/null | \
                ctags -L- --fields=+neKSt --extras=+q --c-kinds=+psgutdefl \
                    --output-format=json -o .codegraph/ctags_index.json 2>/dev/null
        fi
        
        # 更新 cscope
        if command -v cscope &> /dev/null && [ -d ".codegraph" ]; then
            find $CODE_DIRS -name "*.c" -o -name "*.h" 2>/dev/null > .codegraph/cscope.files
            cscope -b -q -k -i .codegraph/cscope.files
            echo "[CodeGraph] cscope 数据库已更新"
        fi
    else
        echo "[CodeGraph] 警告: 未找到源码目录，跳过 ctags/cscope 更新"
    fi
    
    echo "[CodeGraph] 全量更新完成"
else
    echo "[CodeGraph] 增量更新完成（仅 ops-codegraph）"
    echo "  如需全量更新，运行: bash scripts/update_codegraph.sh --full"
fi