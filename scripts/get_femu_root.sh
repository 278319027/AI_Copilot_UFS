#!/bin/bash
# get_femu_root.sh — 从 opencode.json 解析 FEMU_ROOT（单一真相源）
# 用法: bash scripts/get_femu_root.sh
# 输出: 解析后的绝对路径（已展开环境变量和 ${VAR:-default} 语法）
# 退出码: 0=成功, 1=解析失败
#
# 解析优先级:
#   1. opencode.json project.femuRoot
#   2. opencode.json mcp.codegraph.command 中的 --path 参数
#   3. 硬编码默认值 /home/zsf/AI_Proj/femu/hw/femu
#
# 环境变量覆盖:
#   FEMU_ROOT 环境变量始终优先于配置文件中的默认值。

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# 使用 python3 解析 JSON（verify.sh 已要求 python3 存在）
python3 -c "
import json, os, re, sys

def fail(msg):
    print(msg, file=sys.stderr)
    sys.exit(1)

try:
    with open('$PROJECT_ROOT/opencode.json', 'r') as f:
        cfg = json.load(f)
except Exception as e:
    fail(f'Error: cannot parse opencode.json: {e}')

raw = ''

# 1. 优先从 project.femuRoot 读取
if 'project' in cfg and isinstance(cfg['project'], dict):
    raw = cfg['project'].get('femuRoot', '')

# 2. 回退到 mcp.codegraph.command 中的 --path 参数
if not raw:
    mcp = cfg.get('mcp', {})
    cg = mcp.get('codegraph', {}) if isinstance(mcp, dict) else {}
    cmd = cg.get('command', []) if isinstance(cg, dict) else []
    for i, arg in enumerate(cmd):
        if arg == '--path' and i + 1 < len(cmd):
            raw = cmd[i + 1]
            break

# 3. 最终回退默认值
if not raw:
    raw = '\${FEMU_ROOT:-/home/zsf/AI_Proj/femu/hw/femu}'

# 解析 ${VAR:-default} 语法
# 使用 [$] 字符类避免 bash 双引号中对 \$ 的转义问题
m = re.match(r'^[$][{](\w+)[:][-](.*)[}]$', raw)
if m:
    var_name, default_val = m.groups()
    # 环境变量始终优先
    result = os.environ.get(var_name, default_val)
else:
    # 无变量插值，直接输出
    result = raw

# 如果结果是相对路径，转为绝对路径（相对于项目根）
if result and not result.startswith('/'):
    result = os.path.join('$PROJECT_ROOT', result)

print(result)
" 2>/dev/null
