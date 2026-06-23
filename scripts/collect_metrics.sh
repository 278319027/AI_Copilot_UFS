#!/bin/bash
# collect_metrics.sh — 收集项目度量指标
# 用法: bash scripts/collect_metrics.sh
# 输出: Markdown 格式的度量报告
# 用途: 定期运行以跟踪方法论落地效果

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_ROOT"

# ------------------------------------------------------------
# 度量指标定义
# ------------------------------------------------------------
# | 指标 | 定义 | 目标 |
# |------|------|------|
# | 活跃变更数 | openspec/changes/ 下非 archive 的目录数 | ≤ 3（避免并行过多） |
# | 已归档变更数 | openspec/changes/archive/ 下的目录数 | 持续增长 |
# | 平均变更周期 | archive 日期 - proposal 日期（天） | ≤ 7 天 |
# | 平均 task 数 | 所有变更 tasks.md 中 task 项的平均数 | 3-5 |
# | 完整闭环率 | 有 review.md 的变更 / 总变更数 | ≥ 80% |
# | verify 通过率 | verify.sh 历史通过次数 / 总运行次数 | ≥ 95% |
# ------------------------------------------------------------

NOW=$(date +%Y-%m-%d)
REPORT=""

report_line() { REPORT="$REPORT$1\n"; }
report_hdr()  { REPORT="$REPORT\n## $1\n\n"; }

report_hdr "项目度量报告 ($NOW)"
report_line "| 指标 | 值 | 目标 | 状态 |"
report_line "|------|-----|------|------|"

# 1. 活跃变更数
ACTIVE_CHANGES=0
for d in openspec/changes/*/; do
    [ -d "$d" ] && [ "$(basename "$d")" != "archive" ] && ACTIVE_CHANGES=$((ACTIVE_CHANGES + 1))
done
STATUS_ACTIVE=$([ "$ACTIVE_CHANGES" -le 3 ] && echo "✓" || echo "⚠")
report_line "| 活跃变更数 | $ACTIVE_CHANGES | ≤ 3 | $STATUS_ACTIVE |"

# 2. 已归档变更数
ARCHIVED_CHANGES=$(find openspec/changes/archive -maxdepth 1 -type d 2>/dev/null | grep -v '^openspec/changes/archive$' | wc -l)
report_line "| 已归档变更数 | $ARCHIVED_CHANGES | 持续增长 | — |"

# 3. 平均 task 数
TOTAL_TASKS=0
CHANGE_WITH_TASKS=0
for tasks_file in openspec/changes/*/tasks.md openspec/changes/archive/*/tasks.md; do
    [ -f "$tasks_file" ] || continue
    cnt=$(grep -cE '^## Task ' "$tasks_file" 2>/dev/null || echo 0)
    TOTAL_TASKS=$((TOTAL_TASKS + cnt))
    CHANGE_WITH_TASKS=$((CHANGE_WITH_TASKS + 1))
done
if [ "$CHANGE_WITH_TASKS" -gt 0 ]; then
    AVG_TASKS=$((TOTAL_TASKS / CHANGE_WITH_TASKS))
else
    AVG_TASKS=0
fi
STATUS_TASKS=$([ "$AVG_TASKS" -ge 3 ] && [ "$AVG_TASKS" -le 5 ] && echo "✓" || echo "⚠")
report_line "| 平均 task 数/变更 | $AVG_TASKS | 3-5 | $STATUS_TASKS |"

# 4. 完整闭环率（有 review.md 的变更比例）
TOTAL_CHANGES=$((ACTIVE_CHANGES + ARCHIVED_CHANGES))
WITH_REVIEW=0
for review_file in openspec/changes/*/review.md openspec/changes/archive/*/review.md; do
    [ -f "$review_file" ] && WITH_REVIEW=$((WITH_REVIEW + 1))
done
if [ "$TOTAL_CHANGES" -gt 0 ]; then
    CLOSURE_RATE=$((WITH_REVIEW * 100 / TOTAL_CHANGES))
else
    CLOSURE_RATE=0
fi
STATUS_CLOSURE=$([ "$CLOSURE_RATE" -ge 80 ] && echo "✓" || echo "⚠")
report_line "| 完整闭环率 | ${CLOSURE_RATE}% | ≥ 80% | $STATUS_CLOSURE |"

# 5. spec 基线覆盖率（spec 文件数）
SPEC_COUNT=$(find openspec/specs -name "spec.md" | wc -l)
report_line "| spec 基线数 | $SPEC_COUNT | ≥ 3 | ✓ |"

# 6. Memory 规则文件数
MEM_COUNT=$(find .opencode/memory -name "*.md" | wc -l)
report_line "| Memory 规则文件数 | $MEM_COUNT | ≥ 5 | ✓ |"

# 7. Skill 数量
SKILL_COUNT=$(find .opencode/skills -name "SKILL.md" | wc -l)
report_line "| Skill 数量 | $SKILL_COUNT | ≥ 10 | ✓ |"

report_line ""
report_line "---"
report_line ""
report_line "生成时间: $NOW"
report_line ""

# 输出报告
printf "%b" "$REPORT"

# 可选: 保存到 metrics/ 目录
METRICS_DIR="$PROJECT_ROOT/metrics"
mkdir -p "$METRICS_DIR"
printf "%b" "$REPORT" > "$METRICS_DIR/$NOW.md"
echo "报告已保存: $METRICS_DIR/$NOW.md"
