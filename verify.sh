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

# [1/8] OpenSpec specs validation
hdr "1/8" "OpenSpec specs validation"
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

# [2/8] CodeGraph MCP
hdr "2/8" "CodeGraph MCP config"
if [ -f "$PROJECT_ROOT/opencode.json" ] && grep -q '"codegraph"' "$PROJECT_ROOT/opencode.json"; then
    ok "opencode.json contains codegraph MCP entry"
else
    bad "opencode.json missing or lacks 'codegraph' MCP"
fi

# [3/8] Graphify plugin
hdr "3/8" "Graphify plugin"
PLUGIN="$PROJECT_ROOT/.opencode/plugins/graphify.js"
if [ -r "$PLUGIN" ]; then
    ok "graphify.js exists and is readable"
else
    bad "$PLUGIN missing or unreadable"
fi

# [4/8] Memory rules (6 files present)
hdr "4/8" "Memory rules (6 files present)"
MEM="$PROJECT_ROOT/.opencode/memory"
MISS=0
for r in architecture.md concurrency_rules.md coding_style.md design_rules.md review_rules.md testing_rules.md; do
    [ -f "$MEM/$r" ] || MISS=$((MISS+1))
done
[ "$MISS" -eq 0 ] && ok "all 6 rules present" || bad "$MISS/6 rules missing in .opencode/memory/"

# [5/8] deploy_tools.sh syntax
hdr "5/8" "deploy_tools.sh syntax"
bash -n "$PROJECT_ROOT/deploy_tools.sh" 2>/dev/null && ok "deploy_tools.sh has valid bash syntax" || bad "deploy_tools.sh has syntax errors"

# [6/8] Tools on PATH
hdr "6/8" "Essential tools on PATH"
MT=()
for t in codegraph openspec cscope; do
    command -v "$t" &>/dev/null || MT+=("$t")
done
[ ${#MT[@]} -eq 0 ] && ok "codegraph, openspec, cscope all on PATH" || bad "missing tools: ${MT[*]}"

# [7/8] Memory rules format (non-empty + has headers)
hdr "7/8" "Memory rules format (6 files)"
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

# [8/8] openspec/config.yaml non-empty
hdr "8/8" "openspec/config.yaml"
CONFIG="$PROJECT_ROOT/openspec/config.yaml"
if [ -f "$CONFIG" ] && [ -s "$CONFIG" ]; then
    ok "config.yaml exists and is non-empty"
else
    bad "config.yaml missing or empty"
fi

# Summary
printf "\n==============================================\n"
printf "  Summary: %d/8 checks passed\n" "$P"
printf "==============================================\n"
[ "$F" -eq 0 ] && exit 0 || exit 1
