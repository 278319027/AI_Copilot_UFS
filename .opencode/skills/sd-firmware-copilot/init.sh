#!/bin/bash
# sd-firmware-copilot init.sh — 一次性初始化脚本
# 将知识模板部署到项目的 .opencode/ 目录，并初始化 OpenSpec
# 规则文件（architecture.md 等）已内置在 .opencode/memory/ 中，无需额外复制
set -e

SKILL_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SKILL_DIR/../../.." && pwd)"
MEMORY_DIR="$PROJECT_ROOT/.opencode/memory"
KNOWLEDGE_DIR="$PROJECT_ROOT/.opencode/knowledge"

echo "=== SSD Firmware AI Copilot 初始化 ==="
echo "项目根目录: $PROJECT_ROOT"
echo ""

# 1. 确认规则文件就位
echo "--- [1/5] 确认规则文件 ---"
MISSING_RULES=0
for rule in architecture.md concurrency_rules.md coding_style.md design_rules.md review_rules.md testing_rules.md; do
    if [ -f "$MEMORY_DIR/$rule" ]; then
        echo "  ✓ $rule"
    else
        echo "  ✗ $rule 缺失"
        MISSING_RULES=$((MISSING_RULES + 1))
    fi
done
if [ $MISSING_RULES -gt 0 ]; then
    echo "  ⚠ 有 $MISSING_RULES 个规则文件缺失，请检查"
fi

# 2. 复制知识模板到 knowledge/
echo "--- [2/5] 部署知识模板 ---"
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
echo "--- [3/5] 配置 CodeGraph MCP ---"
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

# 4. 检查工具链（CodeGraph + cscope + OpenSpec）
echo ""
echo "--- [4/5] 工具链检查 ---"
TOOLS_OK=true
if command -v codegraph &>/dev/null; then
    echo "  ✓ codegraph: $(codegraph --version 2>&1 | head -1)"
else
    echo "  ✗ codegraph: 未安装"
    echo "    安装: npm install -g @optave/codegraph"
    TOOLS_OK=false
fi

if command -v openspec &>/dev/null; then
    echo "  ✓ openspec: $(openspec --version 2>&1 | head -1)"
else
    echo "  ✗ openspec: 未安装"
    echo "    安装: npm install -g @fission-ai/openspec"
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
    echo "=== 工具链检查通过 ==="
    echo "下一步: 在项目源码目录运行 codegraph init <path> 构建索引"
else
    echo "=== 工具链检查完成（部分缺失） ==="
    echo "请安装缺失的工具后重新运行"
fi

# 5. 初始化 OpenSpec + 验证基线 specs
echo ""
echo "--- [5/5] 初始化 OpenSpec ---"
if command -v openspec &>/dev/null; then
    OPENSPEC_DIR="$PROJECT_ROOT/openspec"
    if [ -d "$OPENSPEC_DIR" ]; then
        echo "  ⚠ openspec/ 已存在，跳过"
    else
        echo "  → 运行 openspec init ..."
        if (cd "$PROJECT_ROOT" && OPENSPEC_TELEMETRY=0 openspec init --tools opencode --force 2>&1 | tail -20); then
            if [ -d "$OPENSPEC_DIR" ]; then
                echo "  ✓ openspec/ 已创建（specs/ + changes/ + OpenCode 集成）"
            else
                echo "  ✗ openspec init 失败"
            fi
        else
            echo "  ✗ openspec init 命令执行失败"
        fi
    fi
else
    echo "  ⚠ openspec CLI 未安装，跳过"
    echo "  安装: npm install -g @fission-ai/openspec"
    echo "  安装后重新运行本脚本"
fi

# 验证基线 specs
OPENSPEC_SPECS_DIR="$PROJECT_ROOT/openspec/specs"
if [ -d "$OPENSPEC_SPECS_DIR" ]; then
    SPEC_COUNT=0
    for spec_cap in ssd-firmware-overview nvme-commands ftl-mapping nand-driver error-handling; do
        if [ -d "$OPENSPEC_SPECS_DIR/$spec_cap" ]; then
            echo "  ✓ $spec_cap/"
            SPEC_COUNT=$((SPEC_COUNT + 1))
        else
            echo "  ⚠ $spec_cap/ 缺失，建议运行: openspec new spec $spec_cap"
        fi
    done
    echo ""
    echo "  当前共 $SPEC_COUNT/5 个基线 specs"
    if command -v openspec &>/dev/null; then
        echo "  → 校验基线: openspec validate --strict --specs"
        (cd "$PROJECT_ROOT" && OPENSPEC_TELEMETRY=0 openspec validate --strict --specs 2>&1 | tail -10) || true
    fi
fi

echo ""
echo "============================================"
echo "=== SSD Firmware AI Copilot 初始化完成 ==="
echo "============================================"
echo ""
echo "快速入门:"
echo "  1. 启动 OpenCode，在 IDE 中使用 /opsx:propose \"<你的想法>\""
echo "  2. 查看进行中的变更: openspec list"
echo "  3. 验证所有 spec: openspec validate --strict --all"
echo "  4. 查看规范工作流: .opencode/skills/sd-firmware-copilot/references/spec_workflow.md"
echo ""
echo "  规则文件位于: .opencode/memory/（可直接编辑）"
