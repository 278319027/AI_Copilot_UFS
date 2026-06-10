# CodeGraph 配置说明

本目录存放 ops-codegraph 和 Doxygen 的配置文件。

## 文件说明

| 文件 | 用途 |
|------|------|
| `config.json` | ops-codegraph 排除目录配置 |
| `Doxyfile` | Doxygen 文档生成配置（含 SSD 固件宏预定义） |

## 不纳入版本控制的文件

以下文件由工具自动生成，已在 `.gitignore` 中排除：

- `graph.db` — ops-codegraph 数据库
- `graph.db-*` — ops-codegraph 增量索引
- `doxygen/` — Doxygen HTML/XML 输出
- `ctags_index.json` — ctags JSON 索引
- `cscope.files` — cscope 源文件列表

## 更新方式

- ops-codegraph 索引：运行 `codegraph build`（毫秒级增量）
- ctags 索引：运行 `bash scripts/init_codegraph.sh`
- Doxygen 文档：运行 `doxygen .codegraph/Doxyfile`

详见 [CodeGraph 部署与使用教程](../CodeGraph_Setup.md)