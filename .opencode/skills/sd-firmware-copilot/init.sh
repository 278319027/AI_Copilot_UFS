#!/bin/bash
# sd-firmware-copilot init.sh — 一次性初始化脚本
# 验证规则文件、配置 CodeGraph MCP、检查工具链、初始化 OpenSpec
# 规则文件（architecture.md 等）已内置在 .opencode/memory/ 中，无需额外复制
#
# 用法:
#   bash init.sh                # 完整初始化 (默认)
#   bash init.sh --check-only   # 快速验证环境 (只读，不修改任何文件)
#
# 退出码:
#   0 = 全部检查通过
#   1 = 至少一项检查失败 (仅 --check-only 模式)
set -e

SKILL_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SKILL_DIR/../../.." && pwd)"
MEMORY_DIR="$PROJECT_ROOT/.opencode/memory"
KNOWLEDGE_DIR="$PROJECT_ROOT/.opencode/knowledge"

# ============================================================
# --check-only: 只读验证模式 (不创建/复制/修改任何文件)
#   验证项目根的三件事:
#     [1/3] .opencode/memory/ 6 个规则文件就位
#     [2/3] openspec/specs/ 5 个基线 spec 目录 + openspec validate 通过
#     [3/3] graphify-out/ 知识图谱已生成 (含 graph.json)
#   退出码: 0=全部通过, 1=至少一项失败
# ============================================================
if [ "${1:-}" = "--check-only" ]; then
    # 关闭 -e: 我们要捕获所有失败，不在第一处错误就退出
    set +e

    echo "=== SSD Firmware AI Copilot 环境验证 (--check-only) ==="
    echo "项目根目录: $PROJECT_ROOT"
    echo ""

    CHECK_FAILED=0

    # [1/3] 验证 .opencode/memory/ 6 个规则文件
    echo "--- [1/3] 验证 .opencode/memory/ 规则文件 ---"
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
        echo "  ⚠ $MISSING_RULES/6 个规则文件缺失"
        CHECK_FAILED=1
    else
        echo "  ✓ 6/6 规则文件就位"
    fi

    # [2/3] 验证 openspec/specs/ + openspec validate
    echo ""
    echo "--- [2/3] 验证 openspec/specs/ ---"
    OPENSPEC_SPECS_DIR="$PROJECT_ROOT/openspec/specs"
    if [ -d "$OPENSPEC_SPECS_DIR" ]; then
        SPEC_COUNT=0
        SPEC_MISSING=0
        for spec_cap in ssd-firmware-overview nvme-commands ftl-mapping nand-driver error-handling; do
            if [ -d "$OPENSPEC_SPECS_DIR/$spec_cap" ]; then
                echo "  ✓ $spec_cap/"
                SPEC_COUNT=$((SPEC_COUNT + 1))
            else
                echo "  ✗ $spec_cap/ 缺失"
                SPEC_MISSING=$((SPEC_MISSING + 1))
            fi
        done
        if [ $SPEC_MISSING -gt 0 ]; then
            echo "  ⚠ $SPEC_MISSING/5 个基线 spec 目录缺失 (当前共 $SPEC_COUNT/5)"
            CHECK_FAILED=1
        else
            echo "  ✓ 5/5 基线 spec 目录就位"
        fi

        # 运行 openspec validate --strict --specs (如有)
        if command -v openspec &>/dev/null; then
            echo ""
            echo "  → 校验: openspec validate --strict --specs"
            VALIDATE_OUT=$(cd "$PROJECT_ROOT" && OPENSPEC_TELEMETRY=0 openspec validate --strict --specs 2>&1)
            VALIDATE_RC=$?
            echo "$VALIDATE_OUT" | tail -10 | sed 's/^/    /'
            if [ $VALIDATE_RC -eq 0 ] && echo "$VALIDATE_OUT" | grep -qE "[0-9]+ passed, 0 failed"; then
                echo "  ✓ OpenSpec specs 校验通过"
            else
                echo "  ✗ OpenSpec specs 校验失败 (rc=$VALIDATE_RC)"
                CHECK_FAILED=1
            fi
        else
            echo "  ✗ openspec CLI 未安装，无法运行 validate"
            CHECK_FAILED=1
        fi
    else
        echo "  ✗ openspec/specs/ 目录不存在"
        CHECK_FAILED=1
    fi

    # [3/3] 验证 graphify-out/ 知识图谱
    echo ""
    echo "--- [3/3] 验证 graphify-out/ ---"
    GRAPHIFY_OUT="$PROJECT_ROOT/graphify-out"
    if [ -d "$GRAPHIFY_OUT" ] && [ -f "$GRAPHIFY_OUT/graph.json" ]; then
        GRAPH_FILES=$(find "$GRAPHIFY_OUT" -type f 2>/dev/null | wc -l)
        echo "  ✓ graphify-out/ 已生成 ($GRAPH_FILES 个文件，含 graph.json)"
    elif [ -d "$GRAPHIFY_OUT" ]; then
        echo "  ⚠ graphify-out/ 目录存在但 graph.json 缺失"
        CHECK_FAILED=1
    else
        echo "  ✗ graphify-out/ 不存在 (需运行 deploy_tools.sh 部署 graphify 工具链)"
        CHECK_FAILED=1
    fi

    # 最终判定
    echo ""
    echo "============================================"
    if [ $CHECK_FAILED -eq 0 ]; then
        echo "=== 环境验证通过 ✓ ==="
        echo "============================================"
        exit 0
    else
        echo "=== 环境验证失败 ✗ ==="
        echo "请运行: bash $0   (完整初始化)"
        echo "或运行: bash $PROJECT_ROOT/deploy_tools.sh <C源码路径>   (部署工具链)"
        echo "============================================"
        exit 1
    fi
fi

echo "=== SSD Firmware AI Copilot 初始化 ==="
echo "项目根目录: $PROJECT_ROOT"
echo ""

# 1. 确认规则文件就位
echo "--- [1/4] 确认规则文件 ---"
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

# 2. 硬件知识：芯片特定，本技能包不提供模板，需项目所有者填入
echo "--- [2/4] 硬件知识 ---"
if [ -d "$KNOWLEDGE_DIR" ]; then
    echo "  ✓ .opencode/knowledge/ 已存在 ($(find "$KNOWLEDGE_DIR" -name '*.md' | wc -l) 个文件)"
    echo "  → 如芯片型号或固件版本变更，请同步更新知识文件版本号"
else
    echo "  ⚠ .opencode/knowledge/ 不存在"
    echo "  → 请项目所有者创建该目录并填入芯片特定知识"
    echo "    推荐子目录: nand_controller/ nvme_spec/ platform/"
    echo "    本技能包不提供硬件知识模板（知识因芯片型号而异）"
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

# 4. 检查工具链（CodeGraph + cscope + OpenSpec）
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
echo "--- 初始化 OpenSpec ---"
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
echo "  4. 查看规范工作流: .opencode/skills/openspec-workflow/SKILL.md"
echo ""
echo "  规则文件位于: .opencode/memory/（可直接编辑）"
