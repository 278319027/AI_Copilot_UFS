#!/bin/bash
# verify.sh — 一键健康检查 (One-command health check)
# 用法: bash verify.sh
# 退出码: 0=全部通过, 1=至少一项失败
# 用途: 部署后/日常回归 — 只读检查, 不修改任何文件
set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$PROJECT_ROOT"

# Color (only when stdout is a terminal)
if [ -t 1 ]; then
    G=$'\033[0;32m'; R=$'\033[0;31m'; X=$'\033[0m'
else
    G=''; R=''; X=''
fi

P=0; F=0
ok()  { printf "  %s✓ PASS%s %s\n" "$G" "$X" "$1"; P=$((P+1)); }
bad() { printf "  %s✗ FAIL%s %s\n" "$R" "$X" "$1"; F=$((F+1)); }
hdr() { printf "\n[%s] %s\n" "$1" "$2"; }

echo "=== verify.sh — 项目健康检查 ==="
echo "  项目根: $PROJECT_ROOT"

# [1/12] OpenSpec specs validation
hdr "1/12" "OpenSpec specs validation"
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

# ---------------------------------------------------------------------------
# codegraph 安装说明（2026-06-22 验证）：
#   deploy_tools.sh 默认安装的 codegraph 可能是不支持 C 语言的旧版本（如 v3.3.1）。
#   若 `codegraph build` 报 "Found 0 files to parse"，升级到最新版本即可：
#
#       npm install -g @optave/codegraph@latest   # 或指定版本 @3.13.0
#       cd <FEMU_ROOT>/hw/femu && rm -rf .codegraph && codegraph build .
#
#   v3.13.0 支持 34 种语言（含 C/C++ .c/.h），build 后检查：
#       codegraph stats   # 预期：Nodes > 0，Edges > 0
# ---------------------------------------------------------------------------
# [2/12] CodeGraph MCP
hdr "2/12" "CodeGraph MCP config"
if [ -f "$PROJECT_ROOT/opencode.json" ] && grep -q '"codegraph"' "$PROJECT_ROOT/opencode.json"; then
    ok "opencode.json contains codegraph MCP entry"
else
    bad "opencode.json missing or lacks 'codegraph' MCP"
fi

# [3/12] Graphify plugin
hdr "3/12" "Graphify plugin"
PLUGIN="$PROJECT_ROOT/.opencode/plugins/graphify.js"
if [ -r "$PLUGIN" ]; then
    ok "graphify.js exists and is readable"
else
    bad "$PLUGIN missing or unreadable"
fi

# [4/12] Memory rules (6 files present)
hdr "4/12" "Memory rules (6 files present)"
MEM="$PROJECT_ROOT/.opencode/memory"
MISS=0
for r in architecture.md concurrency_rules.md coding_style.md design_rules.md review_rules.md testing_rules.md; do
    [ -f "$MEM/$r" ] || MISS=$((MISS+1))
done
[ "$MISS" -eq 0 ] && ok "all 6 rules present" || bad "$MISS/6 rules missing in .opencode/memory/"

# [5/12] deploy_tools.sh syntax
hdr "5/12" "deploy_tools.sh syntax"
bash -n "$PROJECT_ROOT/deploy_tools.sh" 2>/dev/null && ok "deploy_tools.sh has valid bash syntax" || bad "deploy_tools.sh has syntax errors"

# [6/12] Tools on PATH
hdr "6/12" "Essential tools on PATH"
MT=()
for t in codegraph openspec cscope; do
    command -v "$t" &>/dev/null || MT+=("$t")
done
[ ${#MT[@]} -eq 0 ] && ok "codegraph, openspec, cscope all on PATH" || bad "missing tools: ${MT[*]}"

# [7/12] Memory rules format (non-empty + has headers)
hdr "7/12" "Memory rules format (6 files)"
BAD=0
for r in architecture.md concurrency_rules.md coding_style.md design_rules.md review_rules.md testing_rules.md; do
    f="$MEM/$r"
    if [ -f "$f" ] && [ -s "$f" ] && grep -qE "^#" "$f"; then
        :   # ok
    else
        BAD=$((BAD+1))
    fi
done
[ "$BAD" -eq 0 ] && ok "all 6 rules non-empty with markdown headers" || bad "$BAD rules empty or malformed"

# [8/12] openspec/config.yaml non-empty
hdr "8/12" "openspec/config.yaml"
CONFIG="$PROJECT_ROOT/openspec/config.yaml"
if [ -f "$CONFIG" ] && [ -s "$CONFIG" ]; then
    ok "config.yaml exists and is non-empty"
else
    bad "config.yaml missing or empty"
fi

# [9/12] opencode.json JSON validity (用 python3 解析, 比 jq 更普适)
hdr "9/12" "opencode.json JSON validity"
if command -v python3 &>/dev/null; then
    if python3 -c "import json; json.load(open('$PROJECT_ROOT/opencode.json'))" 2>/dev/null; then
        ok "opencode.json is valid JSON"
    else
        bad "opencode.json is not valid JSON"
    fi
else
    bad "python3 not available, cannot validate opencode.json"
fi

# [10/12] FEMU_ROOT env var or default path
# MCP 路径形如 ${FEMU_ROOT:-/home/tcb/AI_Proj/femu}/hw/femu, 两者之一存在即可
hdr "10/12" "FEMU_ROOT (CodeGraph MCP target path)"
FEMU_BASE="${FEMU_ROOT:-/home/tcb/AI_Proj/femu}"
if [ -d "$FEMU_BASE/hw/femu" ]; then
    ok "FEMU hw/femu dir exists: $FEMU_BASE/hw/femu (FEMU_ROOT=${FEMU_ROOT:-<default>})"
else
    bad "FEMU hw/femu dir missing: $FEMU_BASE/hw/femu (export FEMU_ROOT=<path> to override default)"
fi

# [11/12] Spec files (5 capabilities) non-empty
hdr "11/12" "Spec files (5 capabilities, non-empty)"
EMPTY_SPECS=0
for s in ssd-firmware-overview nvme-commands ftl-mapping nand-driver error-handling; do
    f="$PROJECT_ROOT/openspec/specs/$s/spec.md"
    [ -f "$f" ] && [ -s "$f" ] || EMPTY_SPECS=$((EMPTY_SPECS+1))
done
[ "$EMPTY_SPECS" -eq 0 ] && ok "all 5 spec files exist and non-empty" || bad "$EMPTY_SPECS/5 spec files missing or empty"

# [12/12] Skill directories: 5 openspec-* + 1 openspec-workflow + 13 superpowers-* + 1 sd-firmware-copilot = 20
hdr "12/12" "Skill directories (20 expected: 5 openspec-* + 1 openspec-workflow + 13 superpowers-* + 1 sd-firmware-copilot)"
SKILL_BAD=0
SP_OS_PHASE_COUNT=0
for phase_dir in openspec-propose openspec-explore openspec-apply openspec-sync-specs openspec-archive-change; do
    [ -d "$PROJECT_ROOT/.opencode/skills/$phase_dir" ] && SP_OS_PHASE_COUNT=$((SP_OS_PHASE_COUNT+1))
done
[ "$SP_OS_PHASE_COUNT" -eq 5 ] || SKILL_BAD=$((SKILL_BAD+1))
[ -d "$PROJECT_ROOT/.opencode/skills/openspec-workflow" ] || SKILL_BAD=$((SKILL_BAD+1))
SP_POW_COUNT=$(ls -1d "$PROJECT_ROOT/.opencode/skills/superpowers-"*/ 2>/dev/null | wc -l)
[ "$SP_POW_COUNT" -eq 13 ] || SKILL_BAD=$((SKILL_BAD+1))
[ -d "$PROJECT_ROOT/.opencode/skills/sd-firmware-copilot" ] || SKILL_BAD=$((SKILL_BAD+1))
if [ "$SKILL_BAD" -eq 0 ]; then
    ok "all 20 skill dirs present (openspec-phase=$SP_OS_PHASE_COUNT, openspec-workflow=1, superpowers-*=$SP_POW_COUNT, sd-firmware-copilot=1)"
else
    bad "skill dir mismatch: openspec-phase=$SP_OS_PHASE_COUNT (expect 5), openspec-workflow=$([ -d "$PROJECT_ROOT/.opencode/skills/openspec-workflow" ] && echo 1 || echo 0), superpowers-*=$SP_POW_COUNT (expect 13), sd-firmware-copilot=$([ -d "$PROJECT_ROOT/.opencode/skills/sd-firmware-copilot" ] && echo 1 || echo 0)"
fi
CMD_COUNT=$(ls -1 "$PROJECT_ROOT/.opencode/commands/opsx-"*.md 2>/dev/null | wc -l)
[ "$CMD_COUNT" -eq 5 ] && ok "5 opsx-* slash commands present" || bad "$CMD_COUNT opsx-* commands found (expected 5)"

# [13/13] .omo/ cleanliness check (stale task files should not accumulate)
hdr "13/13" ".omo/ cleanliness (agent state should be empty or gitignored)"
OMO_FILES=$(find "$PROJECT_ROOT/.omo" -type f 2>/dev/null | grep -v '/archive/' | wc -l)
[ "$OMO_FILES" -eq 0 ] && ok ".omo/ clean (no stale task files)" || bad ".omo/ contains $OMO_FILES non-archived file(s) — clean up or move to .omo/archive/"

# Summary
printf "\n==============================================\n"
printf "  Summary: %d/13 checks passed\n" "$P"
printf "==============================================\n"
[ "$F" -eq 0 ] && exit 0 || exit 1
