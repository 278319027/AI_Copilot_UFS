# comet-enhanced 快速安装

## 1. 拷贝到项目

```bash
cp -r comet-enhanced-deploy/* /path/to/project/
cp -r comet-enhanced-deploy/.opencode /path/to/project/
```

## 2. 安装依赖工具

```bash
npm install -g codegraph && uv tool install graphifyy
```

## 3. 追加 AGENTS.md

将 AGENTS-entry.md 内容追加到项目 AGENTS.md 末尾。

## ⚠️ 为什么需要项目根 comet-enhanced/

每个节点 SKILL.md 中的脚本命令使用相对路径 `node comet-enhanced/scripts/...`。
部署包已包含此 symlink：`comet-enhanced → .opencode/skills/comet-enhanced/`。
拷贝后自动生效，无需手动创建。
