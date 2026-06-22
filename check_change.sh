#!/bin/bash
# check_change.sh — 检查 OpenSpec 变更健康度
# 用法: bash check_change.sh <change-name>
# 退出码: 0=所有项通过, 1=有项未通过, 2=变更不存在
# 用途: review 前 / archive 前 / 阶段性自查 — 只读检查, 不修改任何文件

set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$PROJECT_ROOT"

# Color (only when stdout is a terminal)
if [ -t 1 ]; then
    G=$'\033[0;32m'; R=$'\033[0;31m'; Y=$'\033[0;33m'; X=$'\033[0m'
else
    G=''; R=''; Y=''; X=''
fi

P=0; F=0; W=0
ok()  { printf "  %s✓ PASS%s %s\n" "$G" "$X" "$1"; P=$((P+1)); }
bad() { printf "  %s✗ FAIL%s %s\n" "$R" "$X" "$1"; F=$((F+1)); }
warn(){ printf "  %s⚠ WARN%s %s\n" "$Y" "$X" "$1"; W=$((W+1)); }
hdr() { printf "\n[%s] %s\n" "$1" "$2"; }

# 参数解析
CHANGE_NAME="${1:-}"
if [ -z "$CHANGE_NAME" ]; then
    echo "用法: bash $0 <change-name>"
    echo "示例: bash $0 add-flip-reset-gc-stats"
    echo ""
    echo "可用的活跃变更:"
    for d in openspec/changes/*/; do
        [ -d "$d" ] && [ "$(basename "$d")" != "archive" ] && echo "  - $(basename "$d")"
    done
    exit 1
fi

CHANGE_DIR="$PROJECT_ROOT/openspec/changes/$CHANGE_NAME"
if [ ! -d "$CHANGE_DIR" ]; then
    # 也可能在 archive/ 下
    CHANGE_DIR=$(find "$PROJECT_ROOT/openspec/changes/archive" -maxdepth 1 -type d -name "*$CHANGE_NAME*" 2>/dev/null | head -1)
    if [ -z "$CHANGE_DIR" ] || [ ! -d "$CHANGE_DIR" ]; then
        echo "✗ 变更不存在: openspec/changes/$CHANGE_NAME"
        echo "  也不在 archive/ 下找到匹配项"
        exit 2
    fi
    echo "  (从 archive/ 找到: $CHANGE_DIR)"
fi

echo "=== check_change.sh — OpenSpec 变更健康度检查 ==="
echo "  变更: $CHANGE_NAME"
echo "  路径: $CHANGE_DIR"

# [1/8] 目录结构
hdr "1/8" "目录结构"
[ -f "$CHANGE_DIR/.openspec.yaml" ] && ok ".openspec.yaml 存在" || bad ".openspec.yaml 缺失"
[ -f "$CHANGE_DIR/proposal.md" ] && ok "proposal.md 存在" || bad "proposal.md 缺失"
[ -f "$CHANGE_DIR/design.md" ] && ok "design.md 存在" || bad "design.md 缺失"
[ -f "$CHANGE_DIR/tasks.md" ] && ok "tasks.md 存在" || bad "tasks.md 缺失"

# [2/8] proposal.md 必填章节
hdr "2/8" "proposal.md 必填章节"
PROPOSAL="$CHANGE_DIR/proposal.md"
if [ -f "$PROPOSAL" ]; then
    for section in "## Why" "## What Changes" "## Impact" "## Non-Goals"; do
        if grep -qF "$section" "$PROPOSAL"; then
            ok "包含章节: $section"
        else
            bad "缺失章节: $section"
        fi
    done
else
    bad "proposal.md 不存在，无法检查章节"
fi

# [3/8] design.md 必填章节
hdr "3/8" "design.md 必填章节"
DESIGN="$CHANGE_DIR/design.md"
if [ -f "$DESIGN" ]; then
    for section in "## Context" "## Goals" "## Non-Goals" "## Decisions" "## Risks"; do
        if grep -qF "$section" "$DESIGN"; then
            ok "包含章节: $section"
        else
            bad "缺失章节: $section"
        fi
    done
    # 检查 CodeGraph 影响分析（不强求章节名，但要求有调用图相关关键词）
    if grep -qiE "codegraph|impact|callee|caller|调用图|影响分析" "$DESIGN"; then
        ok "包含 CodeGraph 影响分析内容"
    else
        warn "未发现 CodeGraph 影响分析关键词（callers/callees/impact/codegraph）"
    fi
else
    bad "design.md 不存在，无法检查章节"
fi

# [4/8] tasks.md 状态
hdr "4/8" "tasks.md 状态"
TASKS="$CHANGE_DIR/tasks.md"
if [ -f "$TASKS" ]; then
    TOTAL=$(grep -cE "^\- \[" "$TASKS" 2>/dev/null || echo 0)
    DONE=$(grep -cE "^\- \[x\]" "$TASKS" 2>/dev/null || echo 0)
    TODO=$((TOTAL - DONE))
    if [ "$TOTAL" -eq 0 ]; then
        bad "tasks.md 无任何 task 项"
    else
        ok "tasks.md 含 $TOTAL 个 task（$DONE 已完成 / $TODO 未完成）"
        if [ "$TODO" -eq 0 ] && [ "$DONE" -gt 0 ]; then
            ok "所有 task 已完成"
        elif [ "$TODO" -gt 0 ]; then
            warn "$TODO 个 task 未完成（archive 前需全部勾选）"
        fi
    fi
    # 检查 task 粒度
    if [ "$TOTAL" -gt 0 ]; then
        if [ "$TOTAL" -le 5 ]; then
            ok "task 粒度合理（≤ 5 个，符合小任务原则）"
        else
            warn "task 数量 $TOTAL > 5（建议拆分）"
        fi
    fi
else
    bad "tasks.md 不存在"
fi

# [5/8] spec delta 完整性
hdr "5/8" "spec delta 完整性"
SPECS_DIR="$CHANGE_DIR/specs"
if [ -d "$SPECS_DIR" ]; then
    DELTA_COUNT=$(find "$SPECS_DIR" -name "spec.md" | wc -l)
    if [ "$DELTA_COUNT" -gt 0 ]; then
        ok "specs/ 目录含 $DELTA_COUNT 个 delta"
        # 检查 delta 章节格式
        for spec_file in $(find "$SPECS_DIR" -name "spec.md"); do
            if grep -qE "^## (ADDED|MODIFIED|REMOVED|RENAMED) Requirements" "$spec_file"; then
                ok "$(basename $(dirname $spec_file))/spec.md 包含标准 delta header"
            else
                bad "$(basename $(dirname $spec_file))/spec.md 缺少 ## ADDED/MODIFIED/REMOVED Requirements 章节"
            fi
        done
    else
        warn "specs/ 目录无 spec.md（可能无需修改基线 spec）"
    fi
else
    warn "specs/ 目录不存在（可能无需修改基线 spec）"
fi

# [6/8] review.md（如果有）
hdr "6/8" "review.md（如已 review）"
REVIEW="$CHANGE_DIR/review.md"
if [ -f "$REVIEW" ]; then
    ok "review.md 存在"
    for section in "## Summary" "## P0" "## P1"; do
        if grep -qF "$section" "$REVIEW"; then
            ok "review.md 包含章节: $section"
        else
            warn "review.md 缺失章节: $section"
        fi
    done
    # 检查 P0 问题修复
    P0_UNRESOLVED=$(awk '/^## P0/,/^## P1/' "$REVIEW" | grep -cE "^\| [0-9]+ \||^### " || true)
    if [ "$P0_UNRESOLVED" -gt 0 ]; then
        warn "P0 区域有 $P0_UNRESOLVED 行未确认（archive 前需 P0 全部解决）"
    fi
else
    warn "review.md 不存在（review 阶段未开始或未完成）"
fi

# [7/8] ARCHIVE 阶段：归档目录是否存在
hdr "7/8" "归档状态"
ARCHIVE_DIR="$PROJECT_ROOT/openspec/changes/archive/$(date +%Y-%m-%d)-$CHANGE_NAME"
if [ -d "$ARCHIVE_DIR" ]; then
    ok "已归档: $ARCHIVE_DIR"
else
    if [ "$TODO" -eq 0 ] && [ "$DONE" -gt 0 ]; then
        ok "task 全部完成，可执行 /opsx:archive"
    else
        warn "task 未全部完成，不可 archive"
    fi
fi

# [8/8] 命名规范
hdr "8/8" "命名规范"
if echo "$CHANGE_NAME" | grep -qE "^[a-z][a-z0-9-]*[a-z0-9]$"; then
    ok "change-name 符合 kebab-case"
else
    bad "change-name 不符合 kebab-case（仅小写字母+数字+连字符，不以连字符开头/结尾）"
fi

# Summary
printf "\n==============================================\n"
printf "  Summary: %d passed, %d failed, %d warnings\n" "$P" "$F" "$W"
printf "==============================================\n"
[ "$F" -eq 0 ] && exit 0 || exit 1
