#!/bin/bash
# metrics_trend.sh — 度量趋势分析
# 用法: bash scripts/metrics_trend.sh
# 输出: Markdown 表格，展示历史度量趋势
# 依赖: metrics/ 目录下有历史报告文件（由 collect_metrics.sh 生成）

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
METRICS_DIR="$PROJECT_ROOT/metrics"

if [ ! -d "$METRICS_DIR" ] || [ -z "$(ls -A "$METRICS_DIR" 2>/dev/null)" ]; then
    echo "No metrics history found in $METRICS_DIR"
    echo "Run 'bash scripts/collect_metrics.sh' first to generate baseline."
    exit 1
fi

echo "# 度量趋势报告"
echo ""
echo "> 生成时间: $(date +%Y-%m-%d)"
echo "> 数据点: $(ls -1 "$METRICS_DIR"/*.md 2>/dev/null | wc -l)"
echo ""

# 提取所有日期的关键指标
# 格式: 2024-01-15.md

echo "## 活跃变更数趋势"
echo ""
echo "| 日期 | 活跃变更数 | 已归档数 | 总变更数 |"
echo "|------|-----------|----------|----------|"
for f in $(ls -1 "$METRICS_DIR"/*.md | sort); do
    date_str=$(basename "$f" .md)
    active=$(grep "活跃变更数" "$f" | awk -F'|' '{print $3}' | tr -d ' ')
    archived=$(grep "已归档变更数" "$f" | awk -F'|' '{print $3}' | tr -d ' ')
    total=$((active + archived))
    echo "| $date_str | $active | $archived | $total |"
done

echo ""
echo "## 完整闭环率趋势"
echo ""
echo "| 日期 | 闭环率 | 状态 |"
echo "|------|--------|------|"
for f in $(ls -1 "$METRICS_DIR"/*.md | sort); do
    date_str=$(basename "$f" .md)
    rate=$(grep "完整闭环率" "$f" | awk -F'|' '{print $3}' | tr -d ' ')
    status=$(grep "完整闭环率" "$f" | awk -F'|' '{print $5}' | tr -d ' ')
    echo "| $date_str | $rate | $status |"
done

echo ""
echo "## 平均 Task 数趋势"
echo ""
echo "| 日期 | 平均 task 数/变更 | 状态 |"
echo "|------|-------------------|------|"
for f in $(ls -1 "$METRICS_DIR"/*.md | sort); do
    date_str=$(basename "$f" .md)
    avg=$(grep "平均 task 数" "$f" | awk -F'|' '{print $3}' | tr -d ' ')
    status=$(grep "平均 task 数" "$f" | awk -F'|' '{print $5}' | tr -d ' ')
    echo "| $date_str | $avg | $status |"
done

echo ""
echo "## 基础设施健康度"
echo ""
echo "| 日期 | spec 基线数 | Memory 规则 | Skill 数量 |"
echo "|------|------------|-------------|-----------|"
for f in $(ls -1 "$METRICS_DIR"/*.md | sort); do
    date_str=$(basename "$f" .md)
    specs=$(grep "spec 基线数" "$f" | awk -F'|' '{print $3}' | tr -d ' ')
    mem=$(grep "Memory 规则文件数" "$f" | awk -F'|' '{print $3}' | tr -d ' ')
    skills=$(grep "Skill 数量" "$f" | awk -F'|' '{print $3}' | tr -d ' ')
    echo "| $date_str | $specs | $mem | $skills |"
done

echo ""
echo "---"
echo ""
echo "趋势解读:"
echo "- 活跃变更数 ≤ 3 为健康状态"
echo "- 闭环率应持续增长至 ≥ 80%"
echo "- 平均 task 数 3-5 为合理范围"
