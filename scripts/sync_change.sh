#!/usr/bin/env bash
# scripts/sync_change.sh — Smart merge delta spec → baseline
# Usage: bash scripts/sync_change.sh <change-id>
#
# Per AGENTS.md §OpenSpec Specs §Sync 同步规则 (per AP-009 in retro 2026-06-add-bb-config-print)
# This script is the manual fallback when `openspec sync` CLI is unavailable
# (or when running outside OpenCode IDE where /opsx:sync slash command is not available).
#
# Currently supports: ## ADDED Requirements (most common case, used in 3/3 archived drills)
# Future: ## MODIFIED / REMOVED / RENAMED (will be added as needed)
#
# What it does:
# 1. For each openspec/changes/<id>/specs/<cap>/spec.md (delta file):
#    a. Read the delta content
#    b. Detect delta type (## ADDED Requirements in v1)
#    c. Strip the "## ADDED Requirements" header from baseline perspective
#    d. Insert the new Requirements + Scenarios into baseline's "## Requirements" section
#    e. Validate the baseline with `openspec validate --strict --specs`
# 2. Report success/failure per capability
# 3. Exit 0 on full success, 1 on partial failure, 2 on no-op / pre-conditions not met

set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

# Color (only when stdout is a terminal)
if [ -t 1 ]; then
    G=$'\033[0;32m'; R=$'\033[0;31m'; Y=$'\033[0;33m'; X=$'\033[0m'
else
    G=''; R=''; Y=''; X=''
fi

ok()  { printf "  %s✓ PASS%s %s\n" "$G" "$X" "$1"; }
bad() { printf "  %s✗ FAIL%s %s\n" "$R" "$X" "$1"; }
info(){ printf "  %sℹ INFO%s %s\n" "$Y" "$X" "$1"; }

# ----------------------------------------------------------------------------
# Pre-checks
# ----------------------------------------------------------------------------

CHANGE_NAME="${1:-}"
if [ -z "$CHANGE_NAME" ]; then
    cat <<EOF
Usage: bash $0 <change-id>

Manual fallback for \`openspec sync\` (per AP-009 in retro 2026-06-add-bb-config-print).
Smart-merges delta spec files into baseline, strips delta headers, validates.

Available active changes:
EOF
    for d in openspec/changes/*/; do
        [ -d "$d" ] && [ "$(basename "$d")" != "archive" ] && echo "  - $(basename "$d")"
    done
    exit 2
fi

CHANGE_DIR="openspec/changes/$CHANGE_NAME"
if [ ! -d "$CHANGE_DIR" ]; then
    bad "Change not found: $CHANGE_DIR"
    exit 2
fi

# Check this is not the archive directory
if [ "$CHANGE_DIR" = "openspec/changes/archive" ] || [[ "$CHANGE_DIR" == */archive ]]; then
    bad "Cannot sync from archive directory; run on active changes only"
    exit 2
fi

DELTA_FILES=$(find "$CHANGE_DIR/specs" -name "spec.md" 2>/dev/null)
if [ -z "$DELTA_FILES" ]; then
    info "No delta spec files in $CHANGE_DIR/specs/ (no-op)"
    exit 0
fi

# ----------------------------------------------------------------------------
# Main loop: merge each delta file
# ----------------------------------------------------------------------------

info "Syncing $CHANGE_NAME → baseline"
echo ""

MERGED=0
SKIPPED=0
FAILED=0

for DELTA in $DELTA_FILES; do
    # Extract capability name (parent dir of spec.md)
    CAP=$(basename "$(dirname "$DELTA")")
    BASELINE="openspec/specs/$CAP/spec.md"

    if [ ! -f "$BASELINE" ]; then
        bad "$CAP: baseline not found at $BASELINE"
        FAILED=$((FAILED+1))
        continue
    fi

    # Detect delta type (v1: only ADDED)
    if grep -q "^## ADDED Requirements" "$DELTA"; then
        DELTA_TYPE="ADDED"
    elif grep -q "^## MODIFIED Requirements" "$DELTA"; then
        bad "$CAP: MODIFIED not yet supported (use openspec instructions manually)"
        SKIPPED=$((SKIPPED+1))
        continue
    elif grep -q "^## REMOVED Requirements" "$DELTA"; then
        bad "$CAP: REMOVED not yet supported"
        SKIPPED=$((SKIPPED+1))
        continue
    elif grep -q "^## RENAMED Requirements" "$DELTA"; then
        bad "$CAP: RENAMED not yet supported"
        SKIPPED=$((SKIPPED+1))
        continue
    else
        bad "$CAP: no delta header (## ADDED/MODIFIED/REMOVED/RENAMED Requirements) in $DELTA"
        SKIPPED=$((SKIPPED+1))
        continue
    fi

    info "$CAP: detected ## $DELTA_TYPE Requirements, merging..."

    # Backup baseline
    cp "$BASELINE" "$BASELINE.sync_change.bak"

    # Smart merge via Python (regex on ## Requirements section)
    SYNC_RESULT=$(python3 <<PYEOF
import re, sys

delta_file = "$DELTA"
baseline_file = "$BASELINE"

with open(delta_file) as f:
    delta = f.read()
with open(baseline_file) as f:
    baseline = f.read()

# Extract content after '## ADDED Requirements' header (skip header line + blank line)
m = re.search(r'^## ADDED Requirements\s*\n\s*\n(.*)', delta, re.DOTALL | re.MULTILINE)
if not m:
    print("ERROR: no content after ## ADDED Requirements", file=sys.stderr)
    sys.exit(1)
new_content = m.group(1)
# Strip trailing whitespace
new_content = new_content.rstrip() + "\n"

# Find the ## Requirements section in baseline
# Pattern: starts at '## Requirements\n', ends at next '## ' (level 2) or EOF
# Use lookahead: capture content until we see another ## header at start of line
m = re.search(
    r'(^## Requirements[^\n]*\n)'  # header line (group 1)
    r'(.*?)'                       # content (group 2)
    r'(?=^## |\Z)',                 # lookahead for next ## section or EOF
    baseline,
    re.DOTALL | re.MULTILINE
)
if not m:
    print("ERROR: no ## Requirements section in baseline", file=sys.stderr)
    sys.exit(1)

header_line = m.group(1)
section_content = m.group(2)
# Position to insert: right before the lookahead (i.e., end of section content)
# We need to be careful: the lookahead may be at start of file or after content
# We use the end of m.start(2) + m.end(2) - m.start(2) = m.end(2) to get insert point
insert_pos = m.end(2)

# Insert new content at end of ## Requirements section
new_baseline = baseline[:insert_pos] + new_content + baseline[insert_pos:]

# Write back
with open(baseline_file, 'w') as f:
    f.write(new_baseline)
print("OK")
PYEOF
)
    SYNC_EXIT=$?

    if [ $SYNC_EXIT -ne 0 ]; then
        bad "$CAP: Python merge failed (exit $SYNC_EXIT): $SYNC_RESULT"
        mv "$BASELINE.sync_change.bak" "$BASELINE" 2>/dev/null || true
        FAILED=$((FAILED+1))
        continue
    fi

    # Validate baseline
    if openspec validate --strict --specs > /tmp/sync_validate.log 2>&1; then
        ok "$CAP: ## $DELTA_TYPE Requirements merged into baseline (delta header stripped)"
        rm -f "$BASELINE.sync_change.bak"
        MERGED=$((MERGED+1))
    else
        bad "$CAP: validation failed after merge — restored from .bak"
        mv "$BASELINE.sync_change.bak" "$BASELINE" 2>/dev/null || true
        echo ""
        cat /tmp/sync_validate.log
        echo ""
        FAILED=$((FAILED+1))
    fi
done

# ----------------------------------------------------------------------------
# Summary
# ----------------------------------------------------------------------------

echo ""
info "Summary: $MERGED merged, $SKIPPED skipped, $FAILED failed"

if [ "$FAILED" -gt 0 ]; then
    bad "Sync had failures; review above"
    exit 1
elif [ "$MERGED" -eq 0 ]; then
    info "No-op (no ADDED Requirements to merge)"
    exit 0
else
    echo ""
    ok "Sync complete. Next steps:"
    echo "  1. openspec validate --strict --specs         # confirm baseline valid"
    echo "  2. /opsx:archive $CHANGE_NAME                # move to archive/ + commit"
    echo ""
    echo "  Or manually:"
    echo "  1. mv openspec/changes/$CHANGE_NAME/ openspec/changes/archive/\$(date +%Y-%m-%d)-$CHANGE_NAME/"
    echo "  2. git add openspec/changes/ openspec/specs/"
    echo "  3. git commit -m 'chore(spec): archive $CHANGE_NAME'"
    exit 0
fi
