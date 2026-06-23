# AI Agent 速查卡

> 一页纸掌握 zsf 方法论核心。详细规则见 `AGENTS.md` 和 `sd-firmware-copilot/SKILL.md`。

## 四阶段闭环

```
KNOW → PLAN → BUILD → FEEDBACK
  ↓       ↓        ↓          ↓
读代码  写提案   实现+测试   归档+更新图谱
```

**禁止跳过 KNOW 或 FEEDBACK。**

## 五级门禁

| 门禁 | 触发 | 产出 |
|------|------|------|
| Proposal | `/opsx:propose <name>` | `proposal.md` |
| Design | 人工确认 proposal 后 | `design.md` + `tasks.md` |
| BUILD | 编码前加载 3 个 skill | 代码 + 测试 |
| Review | 编码完成后 | `review.md` |
| Archive | `/opsx:archive <name>` | `archive/` + 基线更新 |

## 四条铁律（Red-line）

- [ ] **声称完成前** → 运行验证命令，捕获证据
- [ ] **写生产代码前** → 测试计划已定义（正常/边界/错误路径）
- [ ] **修 bug 前** → 根因调查（复现→读错误→查变更→最小验证）
- [ ] **合并前** → 正式代码审查（AI 不自批）

## Bootstrap 决策表

| 场景 | 必加载 skill |
|------|-------------|
| 会话开始 | `superpowers-using-superpowers` |
| 进入 BUILD | `superpowers-executing-plans` + `verification-before-completion` |
| 写代码 | `superpowers-test-driven-development` |
| 修 bug | `superpowers-systematic-debugging` |
| 合并前 | `superpowers-requesting-code-review` |
| 收到反馈 | `superpowers-receiving-code-review` |

## 查询优先级

```
1. openspec/specs/<cap>/spec.md   ← 行为基线
2. codegraph where/impact/context ← 结构验证
3. graphify query/explain         ← 概念发现
4. 代码                            ← 最后手段
```

## 常用命令

```bash
# 健康检查
bash scripts/verify.sh

# 创建变更
/opsx:propose my-change "实现 X 功能"

# 执行变更
/opsx:apply my-change

# 归档变更
/opsx:archive my-change

# 查询调用图
codegraph where <symbol>
codegraph impact <file>

# 知识图谱
graphify query "<概念>"
graphify explain "<symbol>"

# 规格验证
openspec validate --strict --specs
openspec validate --strict --changes

# Spec 一致性
bash scripts/verify_spec_symbols.sh    # 验证 spec 中 C 符号存在性

# 工具部署
bash scripts/deploy_tools.sh /path/to/femu     # 部署工具链
bash scripts/deploy_tools.sh --dry-run /path   # 仅检查依赖，不安装
# 注意: 知识图谱更新由 M-5 PROJECT-SPECIFIC 在 AI session 开头自动执行，
#       不再需要 git hooks（templates/git-hooks/ 已于 2026-06-23 移除）
```

## 文件地图

```
zsf/
├── opencode.json          ← 配置（femuRoot / agent / project）
├── openspec/specs/        ← 3 个基线 spec（nvme / ftl / nand）
├── openspec/changes/      ← 活跃变更
├── .opencode/memory/      ← 6 个规则文件（含 anti_patterns.md）
├── .opencode/skills/      ← 15 个 skill（按需加载）
├── .opencode/commands/    ← 8 个 slash 命令（/opsx:*）
├── .opencode/templates/  ← verify-report 模板（M-1 强化产物，2026-06-23 新增）
└── scripts/               ← verify.sh / verify_spec_symbols.sh

> **注意**：`templates/` 顶层目录于 2026-06-23 移除（与 `openspec instructions` CLI 输出重复，且 test_makefile_example.mk 与项目 meson 不兼容）。OpenSpec artifact 模板从 CLI 取（`openspec instructions <id> --change --json`）。
```

## 关键约束

- **单次变更 200-500 行**
- **修改前必查 CodeGraph**（`impact` / `where`）
- **test-after**：代码后补测试，做注入验证
- **变量英文，注释中文**
- **禁止**：`as any`、`@ts-ignore`、空 catch、递归、malloc
