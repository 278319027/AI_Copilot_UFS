# Docs 体系说明

本目录用于保存项目事实与设计信息，不保存 AI 规则。

## 目录约定

| 目录 | 用途 | 模板文件 |
|------|------|----------|
| `SAD/` | 软件架构设计 | `SAD_template.md` |
| `SDD/` | 模块设计文档（含 CodeGraph 影响分析章节） | `SDD_template.md` |
| `ICD/` | 接口控制文档 | `ICD_template.md` |
| `TEST/` | 测试设计文档 + 效果度量模板 | `TEST_template.md`, `metrics_template.md` |

## SDD 模板更新说明

SDD 模板已增加以下章节：

- **第 9 节 并发与安全**：新增 volatile 使用说明、DMA 缓冲区对齐要求、原子操作场景
- **第 10 节 CodeGraph 影响分析**：新增调用者、依赖、影响范围、CodeGraph 查询命令

## TEST 目录文件说明

| 文件 | 用途 |
|------|------|
| `TEST_template.md` | 测试设计文档模板 |
| `metrics_template.md` | AI 辅助编程效果度量模板（7 个维度 + 数据收集表） |

## 文档使用原则

- 建议所有文档均使用 Markdown，并绑定版本号与适用范围。
- 每次修改文档时更新版本号。
- SDD 中的 CodeGraph 影响分析章节应在模块首次设计时填写，后续修改时更新。