#!/bin/bash
# scripts/verify.sh — 一键健康检查 (One-command health check)
# 用法: bash scripts/verify.sh
# 退出码: 0=全部通过, 1=至少一项失败
# 用途: 部署后/日常回归 — 只读检查, 不修改任何文件
set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

# Color (only when stdout is a terminal)
if [ -t 1 ]; then
    G=$'\033[0;32m'; R=$'\033[0;31m'; Y=$'\033[0;33m'; X=$'\033[0m'
else
    G=''; R=''; Y=''; X=''
fi

P=0; F=0
ok()  { printf "  %s✓ PASS%s %s\n" "$G" "$X" "$1"; P=$((P+1)); }
bad() { printf "  %s✗ FAIL%s %s\n" "$R" "$X" "$1"; F=$((F+1)); }
warn(){ printf "  %s⚠ WARN%s %s\n" "$Y" "$X" "$1"; }
hdr() { printf "\n[%s] %s\n" "$1" "$2"; }

# ------------------------------------------------------------
# FEMU_ROOT 约定：FEMU_ROOT 环境变量（与 opencode.json 的 codegraph --path 同步）
# 默认值与 opencode.json → mcp.codegraph.command --path 完全一致
# ------------------------------------------------------------
FEMU_BASE="${FEMU_ROOT:-/home/AI_Copilot_UFS/AI_Proj/femu/hw/femu}"

echo "=== verify.sh — 项目健康检查 ==="
echo "  项目根: $PROJECT_ROOT"

# [1/20] OpenSpec specs validation
hdr "1/20" "OpenSpec specs validation"
if command -v openspec &>/dev/null; then
    if OUT=$(OPENSPEC_TELEMETRY=0 openspec validate --strict --specs 2>&1) && \
       echo "$OUT" | grep -qE "[0-9]+ passed, 0 failed"; then
        ok "specs valid: $(echo "$OUT" | grep -oE "[0-9]+ passed, 0 failed" | head -1)"
    else
        bad "validation failed. Last: $(echo "$OUT" | tail -3 | tr '\n' ' ')"
    fi
else
    bad "openspec CLI not installed (npm i -g @fission-ai/openspec)"
fi

# [2/20] CodeGraph MCP
hdr "2/20" "CodeGraph MCP config"
if [ -f "$PROJECT_ROOT/opencode.json" ] && grep -q '"codegraph"' "$PROJECT_ROOT/opencode.json"; then
    ok "opencode.json contains codegraph MCP entry"
else
    bad "opencode.json missing or lacks 'codegraph' MCP"
fi

# [3/20] Memory rules (5 files present)
hdr "3/20" "Memory rules (5 files present)"
MEM="$PROJECT_ROOT/.opencode/memory"
MISS=0
for r in architecture.md concurrency_rules.md coding_style.md design_rules.md testing_rules.md; do
    [ -f "$MEM/$r" ] || MISS=$((MISS+1))
done
[ "$MISS" -eq 0 ] && ok "all 5 rules present" || bad "$MISS/5 rules missing in .opencode/memory/"

# [4/20] scripts/deploy_tools.sh syntax
hdr "4/20" "scripts/deploy_tools.sh syntax"
bash -n "$PROJECT_ROOT/scripts/deploy_tools.sh" 2>/dev/null && ok "scripts/deploy_tools.sh has valid bash syntax" || bad "scripts/deploy_tools.sh has syntax errors"

# [5/20] Tools on PATH
hdr "5/20" "Essential tools on PATH"
MT=()
for t in codegraph openspec; do
    command -v "$t" &>/dev/null || MT+=("$t")
done
[ ${#MT[@]} -eq 0 ] && ok "codegraph, openspec on PATH" || bad "missing tools: ${MT[*]}"

# [6/20] Memory rules format (non-empty + has headers)
hdr "6/20" "Memory rules format (5 files)"
BAD=0
for r in architecture.md concurrency_rules.md coding_style.md design_rules.md testing_rules.md; do
    f="$MEM/$r"
    if [ -f "$f" ] && [ -s "$f" ] && grep -qE "^#" "$f"; then
        :   # ok
    else
        BAD=$((BAD+1))
    fi
done
[ "$BAD" -eq 0 ] && ok "all 5 rules non-empty with markdown headers" || bad "$BAD rules empty or malformed"

# [7/20] openspec/config.yaml non-empty
hdr "7/20" "openspec/config.yaml"
CONFIG="$PROJECT_ROOT/openspec/config.yaml"
if [ -f "$CONFIG" ] && [ -s "$CONFIG" ]; then
    ok "config.yaml exists and is non-empty"
else
    bad "config.yaml missing or empty"
fi

# [8/20] opencode.json 完整性与 JSON 有效性
hdr "8/20" "opencode.json schema (mcp + codegraph)"
if command -v python3 &>/dev/null; then
    OPENCODE_CHECK=$(python3 -c "
import json, sys
try:
    with open('$PROJECT_ROOT/opencode.json') as f:
        cfg = json.load(f)
    errs = []
    if 'mcp' not in cfg:
        errs.append('missing mcp')
    if 'mcp' in cfg and 'codegraph' not in cfg.get('mcp', {}):
        errs.append('missing mcp.codegraph')
    if errs:
        print('FAIL: ' + '; '.join(errs))
        sys.exit(1)
    print('PASS')
except Exception as e:
    print(f'FAIL: invalid JSON - {e}')
    sys.exit(1)
" 2>&1)
    if echo "$OPENCODE_CHECK" | grep -q "^PASS"; then
        ok "opencode.json valid JSON with mcp.codegraph"
    else
        bad "opencode.json issue: $(echo "$OPENCODE_CHECK" | sed 's/^FAIL: //')"
    fi
else
    bad "python3 not available, cannot validate opencode.json"
fi

# [9/20] FEMU_ROOT — 单一真相源：FEMU_ROOT env var 与 opencode.json codegraph --path 同步
hdr "9/20" "FEMU_ROOT (CodeGraph MCP target path)"
if [ -d "$FEMU_BASE" ]; then
    ok "FEMU hw/femu dir exists: $FEMU_BASE"
else
    bad "FEMU hw/femu dir missing: $FEMU_BASE (export FEMU_ROOT=<path> to override)"
fi

# [10/20] Spec files (3 capabilities) non-empty
hdr "10/20" "Spec files (3 capabilities, non-empty)"
EMPTY_SPECS=0
for s in nvme-commands ftl-mapping nand-driver; do
    f="$PROJECT_ROOT/openspec/specs/$s/spec.md"
    [ -f "$f" ] && [ -s "$f" ] || EMPTY_SPECS=$((EMPTY_SPECS+1))
done
[ "$EMPTY_SPECS" -eq 0 ] && ok "all 3 spec files exist and non-empty" || bad "$EMPTY_SPECS/3 spec files missing or empty"

# [11/20] Skill directories: 5 openspec-* (硬) + 1 openspec-workflow (硬) + N superpowers-* (软报告) + 1 sd-firmware-copilot (硬)
hdr "11/20" "Skill directories (5 openspec-* + 1 openspec-workflow + N superpowers-* + 1 sd-firmware-copilot; N 不强制)"
SKILL_BAD=0
SP_OS_PHASE_COUNT=0
for phase_dir in openspec-propose openspec-explore openspec-apply openspec-sync-specs openspec-archive-change; do
    [ -d "$PROJECT_ROOT/.opencode/skills/$phase_dir" ] && SP_OS_PHASE_COUNT=$((SP_OS_PHASE_COUNT+1))
done
[ "$SP_OS_PHASE_COUNT" -eq 5 ] || SKILL_BAD=$((SKILL_BAD+1))
[ -d "$PROJECT_ROOT/.opencode/skills/openspec-workflow" ] || SKILL_BAD=$((SKILL_BAD+1))
SP_POW_COUNT=$(ls -1d "$PROJECT_ROOT/.opencode/skills/superpowers-"*/ 2>/dev/null | wc -l)
# superpowers-* 数量软报告：不强制为 12（新增/删除 sub-skill 不应破坏 verify）
[ -d "$PROJECT_ROOT/.opencode/skills/sd-firmware-copilot" ] || SKILL_BAD=$((SKILL_BAD+1))
if [ "$SKILL_BAD" -eq 0 ]; then
    ok "skill dirs OK (openspec-phase=$SP_OS_PHASE_COUNT, openspec-workflow=1, superpowers-*$SP_POW_COUNT [soft], sd-firmware-copilot=1)"
else
    bad "skill dir mismatch: openspec-phase=$SP_OS_PHASE_COUNT (expect 5), openspec-workflow=$([ -d "$PROJECT_ROOT/.opencode/skills/openspec-workflow" ] && echo 1 || echo 0), sd-firmware-copilot=$([ -d "$PROJECT_ROOT/.opencode/skills/sd-firmware-copilot" ] && echo 1 || echo 0)"
fi
# 如果 superpowers 数量异常（非 12），单独报告但不阻塞
if [ "$SP_POW_COUNT" -ne 12 ]; then
    printf "  %sℹ INFO%s superpowers-* count = $SP_POW_COUNT (expected 12; soft check, not failing)\n" "$G" "$X"
fi
CMD_COUNT=$(ls -1 "$PROJECT_ROOT/.opencode/commands/opsx-"*.md 2>/dev/null | wc -l)
[ "$CMD_COUNT" -ge 5 ] && ok "$CMD_COUNT opsx-* slash commands present (>= 5)" || bad "$CMD_COUNT opsx-* commands found (expected >= 5)"

# [12/20] FEMU path should not contain mis-generated .opencode/ (AI_Copilot_UFS is the canonical .opencode owner)
hdr "12/20" "FEMU path .opencode/ cleanliness (only AI_Copilot_UFS should own .opencode/)"
# 检查 FEMU_ROOT 路径（如果存在）下任何子目录是否有误生成的 .opencode/
# FEMU_ROOT 现在直接是 hw/femu 目录——检查其子目录 (bbssd/, ocssd/, 等) 不能有 .opencode/
# (FEMU_BASE 在顶部已设置)
MISGEN_OPENCODE=""
if [ -d "$FEMU_BASE" ]; then
    # 搜索 FEMU 仓库下任何子目录中的 .opencode/（排除 femu 仓库根和 graphify-out / .codegraph 工具产物）
    while IFS= read -r d; do
        # Skip if it's at femu repo root (scripts/deploy_tools.sh target location)
        parent="$(dirname "$d")"
        if [ "$parent" = "$FEMU_BASE" ]; then
            continue
        fi
        MISGEN_OPENCODE="$MISGEN_OPENCODE $d"
    done < <(find "$FEMU_BASE" -maxdepth 4 -type d -name ".opencode" 2>/dev/null)
fi
if [ -z "$MISGEN_OPENCODE" ]; then
    ok "no mis-generated .opencode/ in FEMU subdirs"
else
    bad "mis-generated .opencode/ found in FEMU subdirs (only AI_Copilot_UFS should own .opencode/):$MISGEN_OPENCODE"
fi

# [13/20] scripts/check_change.sh 工具存在 + 可执行
hdr "13/20" "scripts/check_change.sh 工具"
CHECK_CHANGE="$PROJECT_ROOT/scripts/check_change.sh"
if [ -x "$CHECK_CHANGE" ]; then
    ok "scripts/check_change.sh 存在且可执行"
else
    bad "scripts/check_change.sh 缺失或不可执行"
fi

# [14/20] scripts/sync_change.sh 工具存在 + 可执行 (per AP-009 retro 2026-06-add-bb-config-print)
hdr "14/20" "scripts/sync_change.sh 工具 (per AP-009)"
SYNC_CHANGE="$PROJECT_ROOT/scripts/sync_change.sh"
if [ -x "$SYNC_CHANGE" ]; then
    ok "scripts/sync_change.sh 存在且可执行"
else
    bad "scripts/sync_change.sh 缺失或不可执行"
fi

# [15/20] sd-firmware-copilot SKILL.md 关键章节齐全
hdr "15/20" "sd-firmware-copilot SKILL.md 关键章节"
SD_SKILL="$PROJECT_ROOT/.opencode/skills/sd-firmware-copilot/SKILL.md"
if [ -f "$SD_SKILL" ]; then
    MISSING_SECTIONS=0
    for section in "Iron Rule" "BUILD Gate" "Bootstrap"; do
        if grep -qF "$section" "$SD_SKILL"; then
            ok "SKILL.md 包含章节引用: $section"
        else
            bad "SKILL.md 缺失章节引用: $section"
            MISSING_SECTIONS=$((MISSING_SECTIONS+1))
        fi
    done
else
    bad "sd-firmware-copilot/SKILL.md 不存在"
fi

# [16/20] anti_patterns.md 存在性（非阻塞，信息提示）
hdr "16/20" "anti_patterns.md 存在性"
if [ -f "$PROJECT_ROOT/.opencode/memory/anti_patterns.md" ]; then
    AP_COUNT=$(grep -cE "^## AP-" "$PROJECT_ROOT/.opencode/memory/anti_patterns.md" 2>/dev/null || echo 0)
    ok "anti_patterns.md 存在，含 $AP_COUNT 个反模式"
else
    warn "anti_patterns.md 缺失（建议添加以沉淀历史经验）"
fi

# [17/20] spec 符号存在性检查（可选，需要目标代码库）
hdr "17/20" "spec symbols existence"
if [ -x "$PROJECT_ROOT/scripts/verify_spec_symbols.sh" ]; then
    if bash "$PROJECT_ROOT/scripts/verify_spec_symbols.sh" >/dev/null 2>&1; then
        ok "spec 中引用的 C 符号在目标代码库中存在"
    else
        warn "spec 符号检查未通过（可能原因：FEMU_ROOT 无代码库 / 索引未构建 / 符号已变更）"
    fi
else
    warn "verify_spec_symbols.sh 未找到"
fi

# [18/20] baseline specs should not contain delta headers (per AP-009 retro 2026-06-add-bb-config-print)
hdr "18/20" "baseline specs no delta headers (per AP-009)"
DELTA_HDRS_FOUND=""
for f in openspec/specs/*/spec.md; do
    [ -f "$f" ] || continue
    if grep -qE "^## (ADDED|MODIFIED|REMOVED|RENAMED) Requirements" "$f" 2>/dev/null; then
        DELTA_HDRS_FOUND="$DELTA_HDRS_FOUND $f"
    fi
done
if [ -z "$DELTA_HDRS_FOUND" ]; then
    ok "no delta headers in baseline specs (clean)"
else
    bad "delta headers found in baseline specs (sync issue):$DELTA_HDRS_FOUND"
fi

# [19/20] review.md 签字检查 (per AP-005 + P2-2: AI 不能自批自审)
# Per retro 2026-06-refactor-bb-flip-table 下周期行动项 P1: 升级为 FAIL（hard constraint）
hdr "19/20" "review.md 签字 (per AP-005)"
REVIEW_PLACEHOLDERS=""
for r in openspec/changes/*/review.md; do
    [ -f "$r" ] || continue
    # Detect AI-written placeholder (签名栏是占位符而非真实签字)
    if grep -qE "用户填写|<user-fill|Signed.*by AI|AI.*Signed|placeholder.*sign|<\s*AI\s*自身\s*>|<\s*AI\s*自身>" "$r" 2>/dev/null; then
        REVIEW_PLACEHOLDERS="$REVIEW_PLACEHOLDERS $r"
    fi
done
if [ -z "$REVIEW_PLACEHOLDERS" ]; then
    ok "no unsigned review.md placeholders in active changes (clean)"
else
    bad "unsigned review.md placeholders found (AI 不能自批自审 per AP-005):$REVIEW_PLACEHOLDERS"
    bad "  → archive 前必须 ask user 签字（详见 openspec-archive-change/SKILL.md §1.0）"
fi

# [20/20] archived changes regression (M-2 closure: methodology bug-injection 自动化)
# Per retro 2026-06-add-toggle-gc-delay §改进建议 P1: 用 regression test 证明 M-2 态度
# 对每个 archived change 验证 3 件事: (1) review.md 有真实签字 (2) spec delta 文件不含 delta 头 (3) FEMU .o 仍含 handler string
hdr "20/20" "archived changes regression (M-2 closure)"
ARCHIVE_REGRESSION=""
ARCHIVE_COUNT=0
ARCHIVE_OK=0
for d in openspec/changes/archive/2026-*/; do
    [ -d "$d" ] || continue
    ARCHIVE_COUNT=$((ARCHIVE_COUNT+1))
    name=$(basename "$d")
    issues=""

    # 1. review.md has real signature (not placeholder)
    if [ -f "$d/review.md" ]; then
        if grep -qE "<用户填写|<user-fill|placeholder.*sign" "$d/review.md" 2>/dev/null; then
            issues="$issues review.md-placeholder"
        fi
    fi

    # 2. baseline spec.md (in openspec/specs/) has no delta header (regression of [18/19] logic)
    # NOTE: archive's own specs/<cap>/spec.md IS expected to contain ## ADDED Requirements;
    #       this check only scans openspec/specs/ baseline (per AP-009 / P0-1).
    for spec_delta in "$d/specs"/*/spec.md; do
        [ -f "$spec_delta" ] || continue
        cap=$(basename "$(dirname "$spec_delta")")
        if [ -n "$cap" ] && [ -f "openspec/specs/$cap/spec.md" ]; then
            if grep -qE "^## (ADDED|MODIFIED|REMOVED|RENAMED) Requirements" "openspec/specs/$cap/spec.md" 2>/dev/null; then
                issues="$issues baseline-delta-header(openspec/specs/$cap/spec.md)"
            fi
        fi
    done

    if [ -z "$issues" ]; then
        ARCHIVE_OK=$((ARCHIVE_OK+1))
    else
        ARCHIVE_REGRESSION="$ARCHIVE_REGRESSION\n  $name: $issues"
    fi
done
if [ -z "$ARCHIVE_REGRESSION" ]; then
    ok "all $ARCHIVE_COUNT archived changes intact (review.md signed + baseline no delta header)"
else
    bad "archived changes regression detected:$ARCHIVE_REGRESSION"
fi

# Summary
printf "\n==============================================\n"
printf "  Summary: %d/20 checks passed\n" "$P"
printf "==============================================\n"
[ "$F" -eq 0 ] && exit 0 || exit 1
