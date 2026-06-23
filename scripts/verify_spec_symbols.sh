#!/bin/bash
# verify_spec_symbols.sh — 验证 spec 中引用的 C 符号在目标代码库中存在
# 用法: bash scripts/verify_spec_symbols.sh
# 输出: 未找到符号列表 + 建议
# 依赖: codegraph（可选，用于符号存在性验证）

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# 获取 FEMU_ROOT（与 opencode.json codegraph --path 同步约定）
FEMU_ROOT="${FEMU_ROOT:-/home/zsf/AI_Proj/femu/hw/femu}"
if [ ! -d "$FEMU_ROOT" ]; then
    echo "Warning: FEMU_ROOT not found, skipping symbol existence check"
    exit 0
fi

echo "=== verify_spec_symbols.sh — Spec 符号存在性检查 ==="
echo "  FEMU_ROOT: $FEMU_ROOT"
echo ""

# 从所有 spec.md 提取 `code` 格式的符号
# 匹配模式: `word` 或 `word(...)`（Markdown 行内代码）
# 排除纯大写的宏/常量（如 NVME_STATUS_SUCCESS）和纯数字
SPECS_DIR="$PROJECT_ROOT/openspec/specs"
SPECS_CHANGES_DIR="$PROJECT_ROOT/openspec/changes"

TMP_SYMBOLS=$(mktemp)
trap "rm -f $TMP_SYMBOLS" EXIT

# 提取 spec.md 中的行内代码符号
for spec_file in $(find "$SPECS_DIR" "$SPECS_CHANGES_DIR" -name "spec.md" 2>/dev/null); do
    grep -oE '`[a-zA-Z_][a-zA-Z0-9_]*`' "$spec_file" 2>/dev/null | \
        sed "s/\`//g" | \
        grep -vE '^[A-Z_]+$' | \
        sort -u >> "$TMP_SYMBOLS"
done

TOTAL=$(sort -u "$TMP_SYMBOLS" | wc -l)
if [ "$TOTAL" -eq 0 ]; then
    echo "✓ 未在 spec 中发现 C 函数符号"
    exit 0
fi

echo "  发现 $TOTAL 个候选符号"
echo ""

# 尝试用 codegraph 验证（如果可用且已构建索引）
MISSING=0
if command -v codegraph &>/dev/null && [ -d "$FEMU_ROOT/.codegraph" ]; then
    echo "  使用 codegraph 验证符号存在性..."
    while IFS= read -r sym; do
        if ! codegraph symbol_search "$sym" --path "$FEMU_ROOT" >/dev/null 2>&1; then
            echo "    ✗ 未找到: $sym"
            MISSING=$((MISSING + 1))
        fi
    done < <(sort -u "$TMP_SYMBOLS")
else
    echo "  codegraph 不可用，输出候选符号列表供人工验证:"
    echo ""
    while IFS= read -r sym; do
        echo "    - $sym"
    done < <(sort -u "$TMP_SYMBOLS")
    echo ""
    echo "  验证方式:"
    echo "    1. cd $FEMU_ROOT && codegraph build"
    echo "    2. 对每个符号: codegraph symbol_search <symbol>"
    echo "    3. 或在代码中 grep -r \"<symbol>\" $FEMU_ROOT"
    exit 0
fi

if [ "$MISSING" -eq 0 ]; then
    echo ""
    echo "✓ 所有 spec 中的 C 符号在目标代码库中存在"
    exit 0
else
    echo ""
    echo "✗ $MISSING/$TOTAL 个符号未在目标代码库中找到"
    echo "  可能原因:"
    echo "    - 代码重构后函数名变更，spec 未同步"
    echo "    - 拼写错误"
    echo "    - codegraph 索引未更新（cd $FEMU_ROOT && codegraph build）"
    exit 1
fi
