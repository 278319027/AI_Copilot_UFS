#!/bin/bash
# sd-firmware-copilot init.sh — 一次性初始化脚本
# 将规则、知识模板部署到项目的 .opencode/ 目录，并初始化 OpenSpec
set -e

SKILL_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SKILL_DIR/../../.." && pwd)"
MEMORY_DIR="$PROJECT_ROOT/.opencode/memory"
KNOWLEDGE_DIR="$PROJECT_ROOT/.opencode/knowledge"

echo "=== SSD Firmware AI Copilot 初始化 ==="
echo "项目根目录: $PROJECT_ROOT"
echo ""

# 1. 复制规则文件到 memory/
echo "--- [1/6] 部署规则文件 ---"
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
echo "--- [2/6] 部署知识模板 ---"
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
echo "--- [3/6] 配置 CodeGraph MCP ---"
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
echo "--- [4/6] 工具链检查 ---"
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

# 5. 初始化 OpenSpec（openspec/ 目录 + OpenCode 集成）
echo ""
echo "--- [5/6] 初始化 OpenSpec 目录 ---"
if command -v openspec &>/dev/null; then
    OPENSPEC_DIR="$PROJECT_ROOT/openspec"
    if [ -d "$OPENSPEC_DIR" ]; then
        echo "  ⚠ openspec/ 已存在，跳过"
        echo "  提示: 重新初始化: cd $PROJECT_ROOT && openspec init --tools opencode --force"
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

# 6. 复制基线 specs 到 openspec/specs/（如不存在）
echo ""
echo "--- [6/6] 验证基线 specs ---"
OPENSPEC_SPECS_DIR="$PROJECT_ROOT/openspec/specs"
if [ -d "$OPENSPEC_SPECS_DIR" ]; then
    SPEC_COUNT=0
    for spec_cap in ssd-firmware-overview nvme-commands ftl-mapping nand-driver error-handling; do
        if [ -d "$OPENSPEC_SPECS_DIR/$spec_cap" ]; then
            echo "  ✓ $spec_cap/"
            SPEC_COUNT=$((SPEC_COUNT + 1))
        else
            echo "  ⚠ $spec_cap/ 缺失，建议运行:"
            echo "      openspec new spec $spec_cap"
        fi
    done
    echo ""
    echo "  当前共 $SPEC_COUNT/5 个基线 specs"
    if command -v openspec &>/dev/null; then
        echo "  → 校验基线: openspec validate --strict --specs"
        if (cd "$PROJECT_ROOT" && OPENSPEC_TELEMETRY=0 openspec validate --strict --specs 2>&1 | tail -10); then
            :
        fi
    fi
else
    echo "  ⚠ openspec/specs/ 不存在，请先执行 [5/6] 步"
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
echo "  4. 查看规范工作流: references/spec_workflow.md"


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
