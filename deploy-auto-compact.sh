#!/usr/bin/env bash
# deploy-auto-compact.sh — 一键部署 auto-compact 插件 + compact-trigger skill
#
# 本脚本是自包含部署包：文件内容内嵌在下方 heredoc 中，
# 不依赖 omo_comet 源码目录，可在任意目标项目目录直接执行。
#
# 用法:
#   # 在目标项目根目录直接执行（部署到当前目录）
#   ./deploy-auto-compact.sh
#   # 或指定目标项目根目录
#   ./deploy-auto-compact.sh /path/to/project
#
# 生成文件:
#   <target>/.opencode/plugins/auto-compact.ts
#   <target>/.opencode/skills/compact-trigger/SKILL.md
#   <target>/.opencode/skills/compact-trigger/phase-finale-prompt.md  （阶段收尾提示词模板）
#
# 生效条件: 重启 OpenCode（桌面版/TUI）加载新插件；在会话中加载
# compact-trigger skill 后立即结束回合，idle 时自动压缩上下文。
set -euo pipefail

# --- 目标目录 --------------------------------------------------------------
TARGET="${1:-$PWD}"
TARGET="$(cd "$TARGET" 2>/dev/null && pwd || { echo "ERROR: target not found: $1" >&2; exit 1; })"

echo "==> 部署 auto-compact 到: $TARGET"
mkdir -p "$TARGET/.opencode/plugins" "$TARGET/.opencode/skills/compact-trigger"

# --- 1. auto-compact 插件 ----------------------------------------------------
cat > "$TARGET/.opencode/plugins/auto-compact.ts" <<'__AUTO_COMPACT_PLUGIN_EOF__'
// auto-compact — OpenCode plugin
//
// 目标：当某个 skill（如 Comet/OMO 工作流 skill）执行完成后，自动触发 OpenCode
// 上下文压缩，释放 context token。
//
// 机制（社区已验证的 opencode-sessions 范式，见 .opencode/skills/comet/reference/context-recovery.md）：
//   1. "tool.execute.after"：监听 `skill` 工具执行完成 → 记录待压缩会话
//   2. event("session.status" type==="idle")：等当前回合真正结束（避免 mid-turn 竞态）
//   3. 调用 client.session.summarize()（等价 TUI 的 /compact，POST /session/{id}/summarize）
//   4. 压缩完成后 session.compacted 事件会自然触发（这里只做日志）
//
// 参考：官方文档 https://opencode.ai/docs/plugins/
//       https://github.com/coyc/opencode-agent-compaction
//       https://github.com/malhashemi/opencode-sessions

import type { Plugin } from "@opencode-ai/plugin"

export const AutoCompactPlugin: Plugin = async ({ client }) => {
  // 待压缩的 sessionID；仅当本回合内 skill 工具执行过才置位
  let pendingCompact: string | null = null

  return {
    "tool.execute.after": async (input) => {
      // 只认显式触发 skill（compact-trigger）才记下会话。
      // 白名单避免"任何 skill 都触发"的过宽语义：comet-open/design 等阶段 skill
      // 本身也是 skill 工具调用，若一并置位会在首个 idle（如决策点等待）误压缩。
      if (input.tool === "skill" && input.args?.name === "compact-trigger") {
        pendingCompact = input.sessionID
      }
    },

    event: async ({ event }) => {
      // 回合结束（idle）+ 本回合跑过 skill → 触发一次压缩
      if (event.type === "session.status" && event.properties.status?.type === "idle") {
        if (pendingCompact && pendingCompact === event.properties.sessionID) {
          pendingCompact = null
          try {
            // 从最后一条 user 消息取会话实际使用的模型（TUI /compact 同样传 providerID/modelID）
            // 缺模型时服务端会用 undefined model 建压缩任务，静默失败但不报错
            const messages = await client.session.messages({ path: { id: event.properties.sessionID }, throwOnError: true })
            const lastUser = [...messages.data].reverse().find((m) => m.info.role === "user")
            const body = lastUser && lastUser.info.role === "user" ? { providerID: lastUser.info.model.providerID, modelID: lastUser.info.model.modelID } : undefined
            await client.session.summarize({ path: { id: event.properties.sessionID }, body })
            await client.app.log({
              body: {
                service: "auto-compact",
                level: "info",
                message: `skill 完成后已触发上下文压缩: ${event.properties.sessionID} (model: ${body?.providerID}/${body?.modelID})`,
              },
            })
          } catch (err) {
            await client.app.log({
              body: {
                service: "auto-compact",
                level: "error",
                message: `触发压缩失败: ${String(err)}`,
              },
            })
          }
        }
      }
    },
  }
}

export default AutoCompactPlugin
__AUTO_COMPACT_PLUGIN_EOF__

# --- 2. compact-trigger skill --------------------------------------------------
cat > "$TARGET/.opencode/skills/compact-trigger/SKILL.md" <<'__COMPACT_TRIGGER_SKILL_EOF__'
---
name: compact-trigger
description: "显式触发 auto-compact 插件的专用 skill。加载后立即结束回合，由 .opencode/plugins/auto-compact.ts 的白名单机制在回合 idle 时自动压缩上下文。仅供 comet 阶段收尾或需要精确压缩点的场景调用，不用于普通 skill 测试。"
---

# compact-trigger — 显式压缩触发器

本 skill 是 auto-compact 插件的**白名单触发器**：插件只在 `skill` 工具参数 `name === "compact-trigger"` 时置位待压缩会话，其余 skill（含 comet-open/design 等阶段 skill）不会触发压缩。

## 机制

`.opencode/plugins/auto-compact.ts` 监听 `tool.execute.after`：

1. `skill` 工具执行完成且 `args.name === "compact-trigger"` → 插件记下 sessionID（`pendingCompact`）
2. 本回合结束、session 进入 idle → 插件调用 `client.session.summarize()` 压缩上下文

因此本 skill 不需要、也不应该调用任何压缩 API。只需被加载、然后**立即收尾**，回合结束即触发。

## 步骤

1. 打印标记文本（供压缩前后对照）：

   ```
   COMPACT-TRIGGER-MARKER
   ```

2. **立即结束回合**：
   - 不做任何实际工作
   - 不调用其他工具
   - 不提出后续问题
   - 等待 session 进入 idle → 插件自动压缩

3. 回合结束即完成，无需等待确认。

## 验证

- 成功：日志出现 `skill 完成后已触发上下文压缩: <session-id>`（service: auto-compact, level: info）
- 失败：日志出现 `触发压缩失败: <error>`（level: error）
- 压缩后效果：会话早期消息被 summarize 摘要替换，`COMPACT-TRIGGER-MARKER` 之前内容不再完整保留

## 注意

- 压缩会摘要**整个会话**（含本触发回合之前的内容）。只在可接受丢失细节的会话中测试。
- 本 skill 是白名单触发的最小样例。若要在 Comet 工作流中复用此模式，把「阶段收尾 → 加载 compact-trigger → 立即结束回合 → 触发压缩」接入实际阶段末尾即可，插件逻辑无需改动。
- 误加载本 skill 会立即触发压缩，且不可撤销——只在确认需要压缩的收尾点调用。
__COMPACT_TRIGGER_SKILL_EOF__

# --- 3. 阶段收尾提示词模板 ----------------------------------------------------
cat > "$TARGET/.opencode/skills/compact-trigger/phase-finale-prompt.md" <<'__PHASE_FINALE_PROMPT_EOF__'
# 阶段收尾提示词模板（触发 auto-compact 压缩）

用途：把下面的段落拼进传给 agent 的 prompt 末尾（如编排器启动下一阶段 skill 时的收尾指令），命令 agent 在阶段守卫推进成功后触发上下文压缩。

> 机制：auto-compact 插件**不读提示词文本**，只认 `skill` 工具的 `name === "compact-trigger"` 事件。因此提示词必须命令 agent 真实调用 Skill 工具，不能只写文字描述。

## 模板段落

```markdown
## 阶段收尾（必须执行）

<阶段名> 阶段守卫 `--apply` 推进成功后，执行压缩收尾：

1. 调用 **Skill 工具**，name 参数填 `compact-trigger`，不要附带任何 user_message。
   （此动作触发 auto-compact 插件置位 pendingCompact）
2. 加载成功后**立即结束回合**：
   - 不调用任何其他工具
   - 不继续下一阶段（NEXT: auto 的衔接推迟到压缩恢复后）
   - 不提问、不输出额外确认
   - 只输出一行收尾说明，如「<阶段名> 阶段完成，上下文压缩中」
3. 等待 session idle → 插件自动压缩 → checkpoint 恢复后继续。
```

## 不可变三要素

| 要素 | 为什么 | 写错后果 |
|---|---|---|
| 必须调 Skill 工具，name=`compact-trigger` | 插件只挂 `tool.execute.after` 的 skill 事件 | 只写文字不调工具 → 不触发 |
| 不带 user_message | skill 加载即触发 | 无影响但污染摘要 |
| 加载后立即结束回合 | idle 时压缩；拖到后续工作后再 idle，压缩点滞后 | 上下文继续膨胀 |

## 压缩恢复后的继续行为

压缩完成 → checkpoint 恢复 → agent 重新唤起（链路可靠，实测验证）。但「继续下一步」**不是无条件自动**，二选一驱动：

1. **todo continuation**：收尾时仍有未完成任务（如 OMO todo 钩子注入 `OMO_INTERNAL_INITIATOR`）→ 系统恢复后自动催继续。
2. **NEXT 判定**：压缩前已跑 `comet state next` 拿到 `NEXT: auto/manual/done` → 恢复后 agent 需自己读取摘要上下文中的 NEXT 判定继续。

风险：压缩会摘要整个会话，「下一步是什么」可能丢失 → 恢复后 agent 停在收尾说明。对策：**压缩前把下一步意图显式写进摘要可保留的位置**（如阶段完成说明里写明「下一步：调用 design skill」），恢复后重新确认，或由用户手动调用 `/<下一阶段 skill>`。

## 常见坑

- ❌ 提示词写"输出 `COMPACT-TRIGGER-MARKER` 并停止"——这是 skill 内容本身，不是触发动作。agent 只输出文本不调工具 → 不触发。
- ❌ 提示词写"加载 compact-trigger 然后继续 design 阶段"——触发是触发了，但压缩发生在设计工作之后的 idle，收尾点错位。
- ✅ 提示词措辞用祈使句"调用 Skill 工具"而非描述句——agent 对工具调用的指令解析更可靠。
__PHASE_FINALE_PROMPT_EOF__

# --- 完成 ---------------------------------------------------------------------
echo "==> 已生成:"
echo "    $TARGET/.opencode/plugins/auto-compact.ts"
echo "    $TARGET/.opencode/skills/compact-trigger/SKILL.md"
echo "    $TARGET/.opencode/skills/compact-trigger/phase-finale-prompt.md"
echo "==> 下一步: 重启 OpenCode 加载插件；会话中加载 compact-trigger skill 并立即结束回合即触发压缩。"
