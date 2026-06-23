# Anti-Patterns

> 项目中真实发生过的错误模式。每个反模式 = 场景 + 后果 + 根因 + 修复 + 预防措施。
> 新增反模式时遵循此格式。

---

## AP-001: BUILD Gate 缺口 — 未加载验证 skill 直接编码

**场景**: `add-gc-stats-flip` 变更（2026-06-22）
**后果**: 代码正确但方法论遵循度仅 70%，无测试计划、无任务跟踪、无验证证据
**根因**: openspec-apply skill 未在编码前强制检查 skill 加载状态
**修复**: 新增 BUILD Gate（五级门禁之一），强制 AI 在编码前声明已加载的 skill
**预防**: openspec-apply SKILL.md 中增加"编码前必须输出已加载 skill 列表"的硬性要求

---

## AP-002: ~~FEMU_ROOT 硬编码分散~~ — 已 2026-06-23 修正

**原始问题**: opencode.json、verify.sh、AGENTS.md 三处均硬编码 `/home/zsf/AI_Proj/femu/hw/femu`
**原修复**（2026-06-22）：`scripts/get_femu_root.sh` 统一从 opencode.json 解析

**新问题发现**（2026-06-23）：
- `get_femu_root.sh` 的 1st tier priority（`project.femuRoot` 字段）在 `opencode.json` 中**根本不存在**——是 dead code
- 脚本实际等价于 `${FEMU_ROOT:-/home/zsf/AI_Proj/femu/hw/femu}` 1 行 shell 变量展开
- 70 行 python 解析器是**过度工程**

**修正**（2026-06-23）：
- 删除 `scripts/get_femu_root.sh`（70 行）
- 改用 `${FEMU_ROOT:-/home/zsf/AI_Proj/femu/hw/femu}` 约定，与 `opencode.json → mcp.codegraph.command --path` 同步
- 更新 `verify.sh`（删 `_get_femu_root()` 函数，2 处调用改 env var）、`scripts/verify_spec_symbols.sh`、`AGENTS.md`、`architecture.md`

**预防**:
- 不要写独立的 FEMU_ROOT 解析脚本——约定是 env var 默认值
- 修改默认路径时，**2 处需同步**：`opencode.json` 的 codegraph --path + 脚本中 `${FEMU_ROOT:-...}` 默认值
- verify.sh [8/15] 检查项验证 `opencode.json` 配置完整性

---

## AP-003: Graphify 安装污染系统 Python

**场景**: deploy_tools.sh 使用 `python3 -m pip install --break-system-packages graphifyy`
**后果**: 破坏系统 Python 环境，可能导致其他工具冲突
**根因**: 图省事直接使用 system pip，未考虑隔离
**修复**: 改为 venv 隔离安装：`python3 -m venv ~/.local/share/graphify-venv`
**预防**: deploy_tools.sh 中删除所有 `--break-system-packages` 用法

---

## AP-004: 步骤编号混乱 — 用户困惑

**场景**: deploy_tools.sh 输出 `[1/6]`, `[3a/4]`, `[3b/4]`, `Step 7` 混用
**后果**: 用户无法判断部署进度，误以为步骤缺失
**根因**: 脚本多次迭代后未统一编号体系
**修复**: 统一为 5 步连续编号 `[1/5]`→`[5/5]`
**预防**: 新增脚本语法检查（bash -n）+ 步骤编号正则校验

---

## AP-005: Spec 与代码符号漂移 — 重构后 spec 未更新

**场景**: （潜在风险）spec 中引用 `ftl_read` 等函数名，代码重构后函数名变更但 spec 未同步
**后果**: spec 成为错误的行为描述，AI 按过时 spec 生成错误代码
**根因**: 缺乏 spec → 代码符号的自动化同步机制
**修复**: 新增 `scripts/verify_spec_symbols.sh` 定期扫描验证
**预防**: CI 中集成 spec 符号存在性检查

---

## AP-006: 静默失败 — 工具错误不阻断流程

**场景**: codegraph build 失败、graphify 更新失败、社区检测失败均用 `|| echo "⚠ ..."` 静默忽略
**后果**: 用户以为部署成功，实际索引为空或图谱陈旧
**根因**: 过度容错设计，未区分"可恢复警告"和"必须阻断的错误"
**修复**: 关键步骤（索引构建、图谱构建、社区检测）失败时 `exit 1`
**预防**: deploy_tools.sh 中对每个关键步骤明确标注：⚠=警告（继续）/ ✗=错误（退出）

---

## AP-007: 运行产物误提交到 git

**场景**: `collect_metrics.sh` 生成的 `metrics/2026-06-23.md` 被提交到 git（2026-06-23）
**后果**: 运行产物污染仓库历史，违反"代码优先"原则，commit 信息被噪音稀释
**根因**: 创建度量收集脚本时未同步更新 `.gitignore` 排除 `metrics/` 目录
**修复**: 删除已误提交的文件 + 在 `.gitignore` 追加 `metrics/`
**预防**: 新增任何"产生文件到新目录"的脚本/命令时，必须同步检查 `.gitignore` 是否覆盖该目录

---

## AP-008: 度量脚本统计模式错误 — checkbox ≠ task 标题

**场景**: `collect_metrics.sh` 第 53 行用 `grep -cE '^\- \['` 统计 task 数（2026-06-23 首次实战暴露）
**后果**: "平均 task 数"指标失真（3 tasks × 3 checkboxes = 9 → 报告为 8，触发误报警 ⚠）
**根因**: 实现时混淆"checkbox（测试项）"和"task 标题（任务项）"两种概念，grep 模式 `^\- \[` 实际匹配 markdown 列表中的 checkbox 而非 `## Task` 标题
**修复**: 改用 `grep -cE '^## Task '` 严格匹配 task 标题（`## Task N: <标题>` 是 OpenSpec 通用 tasks.md 格式）
**预防**: 写度量/统计脚本时，必须先在小样本上手工核对 grep/awk 模式与期望的语义匹配，再部署到 CI

---

## 如何新增反模式

```markdown
## AP-00N: <标题>

**场景**: <简要描述>
**后果**: <影响>
**根因**: <为什么发生>
**修复**: <怎么解决的>
**预防**: <怎么防止再次发生>
```
