#!/bin/bash
# sd-firmware-copilot init.sh — 一次性初始化脚本
# 将规则、知识模板部署到项目的 .opencode/ 目录
set -e

SKILL_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SKILL_DIR/../../.." && pwd)"
MEMORY_DIR="$PROJECT_ROOT/.opencode/memory"
KNOWLEDGE_DIR="$PROJECT_ROOT/.opencode/knowledge"

echo "=== SSD Firmware AI Copilot 初始化 ==="
echo "项目根目录: $PROJECT_ROOT"
echo ""

# 1. 复制规则文件到 memory/
echo "--- [1/4] 部署规则文件 ---"
mkdir -p "$MEMORY_DIR"
for rule in architecture.md concurrency_rules.md coding_style.md design_rules.md review_rules.md testing_rules.md; do
    if [ -f "$SKILL_DIR/rules/$rule" ]; then
        if [ -f "$MEMORY_DIR/$rule" ]; then
            echo "  ⚠ $rule 已存在，跳过（如需覆盖，使用 --update-rules）"
        else
            cp "$SKILL_DIR/rules/$rule" "$MEMORY_DIR/$rule"
            echo "  ✓ $rule"
        fi
    fi
done

# 2. 复制知识模板到 knowledge/
echo ""
echo "--- [2/4] 部署知识模板 ---"
echo "（芯片特定值需要手动填写，模板中标记为 TBD）"
mkdir -p "$KNOWLEDGE_DIR"
for dir in nand_controller nvme_spec platform; do
    if [ -d "$SKILL_DIR/knowledge-templates/$dir" ]; then
        target="$KNOWLEDGE_DIR/$dir"
        if [ -d "$target" ]; then
            echo "  ⚠ $dir/ 已存在，跳过"
        else
            mkdir -p "$target"
            cp "$SKILL_DIR/knowledge-templates/$dir/"*.md "$target/"
            echo "  ✓ $dir/ ($(ls "$SKILL_DIR/knowledge-templates/$dir/"*.md | wc -l) 个文件)"
        fi
    fi
done

# 复制知识库 README
if [ -f "$SKILL_DIR/knowledge-templates/README.md" ]; then
    if [ ! -f "$KNOWLEDGE_DIR/README.md" ]; then
        cp "$SKILL_DIR/knowledge-templates/README.md" "$KNOWLEDGE_DIR/README.md"
        echo "  ✓ knowledge/README.md"
    else
        echo "  ⚠ knowledge/README.md 已存在，跳过"
    fi
fi

# 3. 配置 CodeGraph MCP
echo ""
echo "--- [3/4] 配置 CodeGraph MCP ---"
OPENCODE_JSON="$PROJECT_ROOT/opencode.json"
if [ -f "$OPENCODE_JSON" ]; then
    echo "  opencode.json 已存在"
    if grep -q '"codegraph"' "$OPENCODE_JSON" 2>/dev/null; then
        echo "  ✓ CodeGraph MCP 已配置"
    else
        echo "  ⚠ CodeGraph MCP 未配置"
        echo "  请手动添加 CodeGraph MCP 配置，或运行："
        echo "    opencode mcp add codegraph"
    fi
else
    echo "  ⚠ opencode.json 不存在"
    echo "  请先在项目根目录创建 opencode.json 并配置 CodeGraph MCP"
fi

# 4. 检查工具链
echo ""
echo "--- [4/4] 工具链检查 ---"
TOOLS_OK=true
if command -v codegraph &>/dev/null; then
    echo "  ✓ codegraph: $(codegraph --version 2>&1 | head -1)"
else
    echo "  ✗ codegraph: 未安装"
    echo "    安装: npm install -g @optave/codegraph"
    TOOLS_OK=false
fi

if command -v cscope &>/dev/null; then
    echo "  ✓ cscope: $(cscope -V 2>&1 | head -1)"
else
    echo "  ✗ cscope: 未安装"
    echo "    安装: sudo apt install cscope"
    TOOLS_OK=false
fi

echo ""
if [ "$TOOLS_OK" = true ]; then
    echo "=== 初始化完成 ==="
    echo "下一步: 在项目源码目录运行 codegraph init <path> 构建索引"
else
    echo "=== 初始化完成（工具链不完整） ==="
    echo "请安装缺失的工具后重新运行"
fi

# --update-rules 选项处理
if [ "${1:-}" = "--update-rules" ]; then
    echo ""
    echo "--- 强制更新规则文件 ---"
    for rule in architecture.md concurrency_rules.md coding_style.md design_rules.md review_rules.md testing_rules.md; do
        if [ -f "$SKILL_DIR/rules/$rule" ]; then
            cp "$SKILL_DIR/rules/$rule" "$MEMORY_DIR/$rule"
            echo "  ✓ $rule (已覆盖)"
        fi
    done
    echo "规则文件已更新。知识模板和配置未覆盖（可能包含项目特定值）。"
fi