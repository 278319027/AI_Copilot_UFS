#!/bin/bash
# verify_spec_symbols.sh — 验证 spec 中引用的 C 符号在目标代码库中存在
# 用法: bash scripts/verify_spec_symbols.sh
# 输出: 未找到符号列表 + 建议
# 依赖: codegraph（可选，用于符号存在性验证）

set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FEMU_ROOT="${FEMU_ROOT:-/home/zsf/AI_Proj/femu/hw/femu}"
[ ! -d "$FEMU_ROOT" ] && { echo "Warning: FEMU_ROOT not found, skipping"; exit 0; }

echo "=== Spec 符号存在性检查 (FEMU_ROOT=$FEMU_ROOT) ==="

# 从所有 spec.md 提取 `code` 格式的符号，排除纯大写宏/常量
SYMBOLS=$(find "$PROJECT_ROOT/openspec/specs" "$PROJECT_ROOT/openspec/changes" -name "spec.md" 2>/dev/null | \
    xargs grep -ohE '`[a-zA-Z_][a-zA-Z0-9_]*`' 2>/dev/null | \
    sed 's/`//g' | grep -vE '^[A-Z_]+$' | sort -u)
TOTAL=$(echo "$SYMBOLS" | grep -c .)
[ "$TOTAL" -eq 0 ] && { echo "✓ 未发现 C 函数符号"; exit 0; }

# 验证：codegraph 可用则用之，否则输出候选列表供人工验证
if command -v codegraph &>/dev/null && [ -d "$FEMU_ROOT/.codegraph" ]; then
    MISSING=0
    while IFS= read -r sym; do
        codegraph symbol_search "$sym" --path "$FEMU_ROOT" >/dev/null 2>&1 || \
            { echo "    ✗ 未找到: $sym"; MISSING=$((MISSING + 1)); }
    done <<< "$SYMBOLS"

    if [ "$MISSING" -eq 0 ]; then
        echo "✓ 所有 $TOTAL 个 spec 符号在目标代码库中存在"
    else
        echo "✗ $MISSING/$TOTAL 个符号缺失"
        echo "  排查: 代码重构后函数名变更 / 拼写错误 / codegraph 索引过期（cd $FEMU_ROOT && codegraph build）"
        exit 1
    fi
else
    echo "codegraph 不可用，候选符号列表（人工验证用）:"
    echo "$SYMBOLS" | sed 's/^/    - /'
    echo ""
    echo "  验证: cd $FEMU_ROOT && codegraph build, 然后 codegraph symbol_search <sym>"
fi
