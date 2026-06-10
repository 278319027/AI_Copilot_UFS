#!/bin/bash
# install_codegraph.sh — 在 Ubuntu 上安装 CodeGraph 工具链
# 用法: bash scripts/install_codegraph.sh

set -e

echo "========================================="
echo " CodeGraph 工具链安装脚本"
echo " 适用环境: Ubuntu 20.04+ / 22.04 LTS"
echo "========================================="
echo ""

# ─────────────────────────────────────────────
# Step 1: Node.js 22+
# ─────────────────────────────────────────────
echo "=== Step 1: 检查 Node.js ==="

if command -v node &> /dev/null; then
    NODE_MAJOR=$(node -v | cut -d. -f1 | cut -dv -f2)
    if [ "$NODE_MAJOR" -ge 18 ]; then
        echo "Node.js $(node -v) 已安装，满足要求"
    else
        echo "Node.js $(node -v) 版本过低（需要 18+），正在升级..."
        curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
        sudo apt-get install -y nodejs
    fi
else
    echo "Node.js 未安装，正在安装..."
    curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
    sudo apt-get install -y nodejs
fi

echo "Node.js: $(node -v)"
echo "npm: $(npm -v)"
echo ""

# ─────────────────────────────────────────────
# Step 2: ops-codegraph
# ─────────────────────────────────────────────
echo "=== Step 2: 安装 ops-codegraph ==="

if command -v codegraph &> /dev/null; then
    echo "ops-codegraph 已安装: $(codegraph --version 2>&1 || echo 'version check failed')"
    echo "如需更新: npm update -g @optave/codegraph"
else
    echo "正在安装 ops-codegraph..."
    npm install -g @optave/codegraph
    
    if ! command -v codegraph &> /dev/null; then
        echo "警告: codegraph 命令未在 PATH 中找到"
        echo "尝试添加 npm 全局路径到 PATH..."
        NPM_PREFIX=$(npm config get prefix 2>/dev/null || echo "/usr/local")
        export PATH="$NPM_PREFIX/bin:$PATH"
        echo "已临时添加 $NPM_PREFIX/bin 到 PATH"
        echo "请将以下内容添加到 ~/.bashrc 以永久生效:"
        echo '  export PATH="'$"NPM_PREFIX"'/bin:$PATH"'
    fi
fi

echo ""
echo "验证 ops-codegraph:"
codegraph --version 2>&1 || echo "验证失败，请检查安装"
echo ""

# ─────────────────────────────────────────────
# Step 3: ctags + cscope
# ─────────────────────────────────────────────
echo "=== Step 3: 安装 ctags + cscope ==="

sudo apt-get update -qq
sudo apt-get install -y universal-ctags cscope

echo "ctags: $(ctags --version 2>&1 | head -1)"
echo "cscope: $(cscope -V 2>&1 | head -1)"
echo ""

# ─────────────────────────────────────────────
# Step 4: Doxygen + Graphviz
# ─────────────────────────────────────────────
echo "=== Step 4: 安装 Doxygen + Graphviz ==="

sudo apt-get install -y doxygen graphviz

echo "doxygen: $(doxygen --version)"
echo "graphviz: $(dot -V 2>&1)"
echo ""

# ─────────────────────────────────────────────
# Step 5: ARM 交叉编译工具链（可选）
# ─────────────────────────────────────────────
echo "=== Step 5: 检查 ARM 交叉编译工具链 ==="

if command -v arm-none-eabi-gcc &> /dev/null; then
    echo "ARM 工具链已安装: $(arm-none-eabi-gcc --version | head -1)"
else
    echo "ARM 交叉编译工具链未安装"
    echo "是否安装？(y/N)"
    read -r INSTALL_ARM
    if [ "$INSTALL_ARM" = "y" ] || [ "$INSTALL_ARM" = "Y" ]; then
        sudo apt-get install -y gcc-arm-none-eabi libnewlib-arm-none-eabi
        echo "ARM 工具链安装完成: $(arm-none-eabi-gcc --version | head -1)"
    else
        echo "跳过 ARM 工具链安装（后续可手动安装）"
    fi
fi

echo ""
echo "========================================="
echo " 安装完成！"
echo "========================================="
echo ""
echo " 已安装工具:"
echo "   ops-codegraph: $(command -v codegraph 2>/dev/null || echo '未找到')"
echo "   ctags:         $(command -v ctags 2>/dev/null || echo '未找到')"
echo "   cscope:        $(command -v cscope 2>/dev/null || echo '未找到')"
echo "   doxygen:       $(command -v doxygen 2>/dev/null || echo '未找到')"
echo "   dot:           $(command -v dot 2>/dev/null || echo '未找到')"
echo ""
echo " 下一步:"
echo "   cd /path/to/ssd_firmware"
echo "   bash scripts/init_codegraph.sh"