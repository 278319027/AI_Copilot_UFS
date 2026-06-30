#!/bin/bash
# opencode-c-workflow prerequisite checker
# Run before activating the skill to verify all tools are available.
# Exit 0 = all good. Exit 1 = something missing.

set -euo pipefail
MISSING=0

echo "=== opencode-c-workflow Prerequisite Check ==="
echo ""

# 1. OpenSpec CLI
echo -n "[1/4] OpenSpec CLI ... "
if command -v openspec &>/dev/null; then
    VERSION=$(openspec --version 2>&1 || echo "unknown")
    echo "OK (${VERSION})"
else
    echo "MISSING"
    echo "  → Install: npm install -g @fission-ai/openspec"
    echo "  → Then:    openspec init"
    MISSING=1
fi

# 2. CodeGraph database
echo -n "[2/4] CodeGraph DB ... "
if [ -f ".codegraph/graph.db" ]; then
    echo "OK (.codegraph/graph.db)"
else
    echo "MISSING"
    echo "  → Build: codegraph build ."
    MISSING=1
fi

# 3. Graphify knowledge graph
echo -n "[3/4] Graphify graph ... "
if [ -f "graphify-out/graph.json" ]; then
    echo "OK (graphify-out/graph.json)"
else
    echo "MISSING"
    echo "  → Build: graphify extract ."
    MISSING=1
fi

# 4. Superpowers skills
echo -n "[4/4] Superpowers skills ... "
SKILL_DIR=".opencode/skills"
SUPER_COUNT=$(find "${SKILL_DIR}" -maxdepth 2 -name "SKILL.md" -path "*/superpowers-*" 2>/dev/null | wc -l)
if [ "${SUPER_COUNT}" -gt 0 ]; then
    echo "OK (${SUPER_COUNT} superpowers skill(s) found)"
else
    echo "MISSING"
    echo "  → Install superpowers skills to ${SKILL_DIR}/superpowers-*/"
    MISSING=1
fi

echo ""
if [ "${MISSING}" -eq 0 ]; then
    echo "=== All prerequisites met. Workflow ready. ==="
else
    echo "=== PREREQUISITES NOT MET. Fix above before using opencode-c-workflow. ==="
fi

exit "${MISSING}"
