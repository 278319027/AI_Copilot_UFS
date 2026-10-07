---
name: stop-slop-zh
description: >-
  Remove AI writing patterns from Chinese prose (also covers common English AI
  tells). Use when drafting, editing, or reviewing Chinese text: documents,
  design docs, PR descriptions, emails, blog posts. Catches filler openers,
  business buzzwords (赋能/抓手/闭环/拉齐), three-part scaffolding,
  metronomic bullets, and vague adjectives. Scores text on 5 dimensions
  (1-10 each); total below 35/50 triggers a rewrite with re-scoring.
license: MIT
metadata:
  trigger: Writing Chinese prose, editing drafts, reviewing text for AI patterns
  author: team-adapted from hardikpandya/stop-slop
---

# Stop Slop (中文版)

Eliminate predictable AI writing patterns from prose.
中文散文为主；英文段落按"英文高频痕迹"一节处理。
This skill polishes the surface. It does not change technical content,
numbers, or decisions. 只改文字，不改事实。

## Core Rules

1. **Cut filler phrases.** 删清嗓开场、强调拐杖、商业黑话、含糊断言、元评论。
   清单见 [references/phrases.md](references/phrases.md)。

2. **Break formulaic structures.** 打破三段式、排比轰炸、修辞铺垫、自问自答、
   "综上所述"收尾。清单见 [references/structures.md](references/structures.md)。

3. **Vary rhythm.** 长短句混排。连续 bullet 长度一致是 AI 味——重要的写全句，
   次要的写短行。段落结尾别总用金句。

4. **Trust readers.** 结论先行。对同行读者不铺垫、不对冲、不手把手解释。
   "为了解决 X" 直接写成解法。

5. **Be specific.** 形容词必须带数字或机制，否则删。
   "健壮" → 给出容错机制或 MTBF；"高效" → 给出实测数据。

6. **Cut quotables.** 读起来像公司口号的句子重写。
   "赋能业务"、"打造极致体验" 这类一律落地成动作或删。

7. **Preserve technical precision.** 以下内容本 skill 不碰：
   代码块、命令、表格、mermaid/图表、API 与寄存器定义、章节编号、
   图/表引用、数值与单位。

## 设计文档豁免条款

以下情形**不是**套路，禁止按套路删除：
- ADR / alternatives 章节里 "方案 A vs 方案 B" 和 "为什么不选 X" 的对比
- 每个文档至多 2 句凝练的设计原则陈述
- 边界条件、失败模式、回滚方案的枚举
- 评审结论（"选 A，判断依据：……"）

## Quick Checks（交付前自检）

- 三个连续句子或 bullet 长度一致？打断一个
- 段落首句是套话？直接写内容
- "值得注意的是 / 不难发现 / 显而易见"？删掉，内容直接说
- "随着……的发展" 开头？从主题本身开头
- 出现 赋能/抓手/闭环/拉齐/对齐/沉淀？换具体名词动词或删
- 形容词没有数字或机制支撑？补数字或删
- 结尾是 "综上所述"？删，让最后一个事实收尾
- 三句以上 bullet 全是 "提供……/实现……/确保……" 开头？换动词或改写

## Scoring（五维打分）

按每维 1-10 分给分：

| Dimension | Question |
|-----------|----------|
| Directness 直接性 | 是陈述还是宣告式废话？ |
| Rhythm 节奏 | 有变化还是节拍器式？ |
| Trust 信任 | 尊重读者智力吗？ |
| Authenticity 真实感 | 听起来像人写的吗？ |
| Density 密度 | 还有能砍的吗？ |

**Total below 35/50: rewrite.** 重写后重新打分，输出前后对比。

## Workflow

1. Read the text. 逐条标记违规，引用原文片段，用本文件中的类别名
   （如 "填充套话"、"排比轰炸"）——便于搜索和复核。
2. Rewrite. 只改文字，不改事实、数字、结论。设计文档先套用豁免条款。
3. Re-score. 输出：违规清单 → 重写文本 → 五维分数（前后各一次）。

## 英文高频痕迹（段落为英文时）

throat-clearing openers（"It's worth noting", "It's important to"）、
全部副词、em-dash 揭示句式、Wh- 开头、被动语态、"seamless/robust/leverage/
delve/comprehensive"、"In conclusion"。详细清单可装原版
hardikpandya/stop-slop 的 references。
