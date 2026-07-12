#!/usr/bin/env bash
# scripts/test_tooling.sh — smoke tests for project tooling scripts
# 用法: bash scripts/test_tooling.sh
# 目的: 验证关键门禁脚本不会悄悄放行 unsupported delta / path mismatch

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="$(mktemp -d)"
BIN_DIR="$TMP_DIR/bin"
SKEL_CHANGE="test-skeleton-$$"
SYNC_CHANGE="test-sync-$$"
SYNC_CAP="foo-$$"
cleanup() {
  rm -rf "$TMP_DIR" \
         "$PROJECT_ROOT/openspec/changes/$SKEL_CHANGE" \
         "$PROJECT_ROOT/openspec/changes/$SYNC_CHANGE" \
         "$PROJECT_ROOT/openspec/specs/$SYNC_CAP"
}
trap cleanup EXIT

mkdir -p "$BIN_DIR"

cat >"$BIN_DIR/openspec" <<'EOF'
#!/usr/bin/env bash
case "${1:-}" in
  --version) echo "openspec 1.4.1" ;;
  validate) echo "1 passed, 0 failed" ;;
  *) echo "openspec stub" ;;
esac
EOF

cat >"$BIN_DIR/codegraph" <<'EOF'
#!/usr/bin/env bash
case "${1:-}" in
  --version) echo "codegraph 0.0.0" ;;
  symbol_search) exit 0 ;;
  *) exit 0 ;;
esac
EOF

cat >"$BIN_DIR/graphify" <<'EOF'
#!/usr/bin/env bash
case "${1:-}" in
  --version) echo "graphify 0.0.0" ;;
  *) exit 0 ;;
esac
EOF

chmod +x "$BIN_DIR/openspec" "$BIN_DIR/codegraph" "$BIN_DIR/graphify"

mkdir -p "$TMP_DIR/femu/.codegraph" "$TMP_DIR/femu/graphify-out"
printf 'db' > "$TMP_DIR/femu/.codegraph/graph.db"
printf '{}' > "$TMP_DIR/femu/graphify-out/graph.json"

mkdir -p "$PROJECT_ROOT/openspec/changes/$SKEL_CHANGE"
cat >"$PROJECT_ROOT/openspec/changes/$SKEL_CHANGE/.openspec.yaml" <<'EOF'
schema: spec-driven
created: 2026-06-28
EOF

mkdir -p "$PROJECT_ROOT/openspec/changes/$SYNC_CHANGE/specs/$SYNC_CAP"
mkdir -p "$PROJECT_ROOT/openspec/specs/$SYNC_CAP"
cat >"$PROJECT_ROOT/openspec/changes/$SYNC_CHANGE/specs/$SYNC_CAP/spec.md" <<'EOF'
## MODIFIED Requirements

### Requirement: dummy
#### Scenario: dummy
EOF
cat >"$PROJECT_ROOT/openspec/specs/$SYNC_CAP/spec.md" <<'EOF'
# Foo

## Requirements
EOF

PATH="$BIN_DIR:$PATH" FEMU_ROOT="$TMP_DIR/femu" bash "$PROJECT_ROOT/scripts/check_change.sh" "$SKEL_CHANGE" >/dev/null
rm -rf "$PROJECT_ROOT/openspec/changes/$SKEL_CHANGE"

if PATH="$BIN_DIR:$PATH" FEMU_ROOT="$TMP_DIR/femu" bash "$PROJECT_ROOT/scripts/sync_change.sh" "$SYNC_CHANGE" >/tmp/test_tooling_sync.log 2>&1; then
  echo "sync_change.sh unexpectedly passed unsupported delta"
  cat /tmp/test_tooling_sync.log
  exit 1
fi
rm -rf "$PROJECT_ROOT/openspec/changes/$SYNC_CHANGE" "$PROJECT_ROOT/openspec/specs/$SYNC_CAP"

if ! PATH="$BIN_DIR:$PATH" FEMU_ROOT="$TMP_DIR/femu" bash "$PROJECT_ROOT/scripts/verify.sh" >/tmp/test_tooling_verify.log 2>&1; then
  echo "verify.sh failed"
  cat /tmp/test_tooling_verify.log
  exit 1
fi

grep -q "FEMU hw/femu dir exists: $TMP_DIR/femu" /tmp/test_tooling_verify.log

echo "tooling smoke tests passed"
