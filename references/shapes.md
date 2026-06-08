# Shape Reference

## Basic Flowchart Shapes

| Shape | Purpose | style String |
|-------|---------|-------------|
| Rounded Rect (Start/End) | 开始、结束节点 | `rounded=1;whiteSpace=wrap;html=1;fillColor=#d5e8d4;strokeColor=#82b366;` |
| Rectangle (Process) | 处理步骤、操作 | `whiteSpace=wrap;html=1;fillColor=#dae8fc;strokeColor=#6c8ebf;` |
| Rhombus (Decision) | 条件判断、分支 | `rhombus;whiteSpace=wrap;html=1;fillColor=#fff2cc;strokeColor=#d6b656;` |
| Parallelogram (I/O) | 输入/输出数据 | `shape=parallelogram;perimeter=parallelogramPerimeter;whiteSpace=wrap;html=1;fixedSize=1;fillColor=#e1d5e7;strokeColor=#9673a6;` |
| Ellipse (Start/End-alt) | 开始/结束(椭圆) | `ellipse;whiteSpace=wrap;html=1;fillColor=#d5e8d4;strokeColor=#82b366;` |
| Rectangle (Error) | 错误/异常处理 | `whiteSpace=wrap;html=1;fillColor=#f8cecc;strokeColor=#b85450;` |

## Architecture Shapes

| Shape | Purpose | style String |
|-------|---------|-------------|
| Rounded Service | 微服务/后端服务 | `rounded=1;whiteSpace=wrap;html=1;fillColor=#dae8fc;strokeColor=#6c8ebf;arcSize=20;` |
| Client/Frontend | 前端/移动端/客户端 | `rounded=1;whiteSpace=wrap;html=1;fillColor=#ffe6cc;strokeColor=#d79b00;` |
| Hexagon (Gateway) | API 网关、入口 | `shape=hexagon;perimeter=hexagonPerimeter2;whiteSpace=wrap;html=1;fixedSize=1;fillColor=#d5e8d4;strokeColor=#82b366;` |
| Cylinder (DB) | 数据库 | `shape=cylinder3;whiteSpace=wrap;html=1;boundedLbl=1;backgroundOutline=1;size=15;fillColor=#f5f5f5;strokeColor=#666666;fontColor=#333333;` |
| Cylinder (Queue) | 消息队列 | `shape=cylinder3;whiteSpace=wrap;html=1;boundedLbl=1;size=10;fillColor=#f8cecc;strokeColor=#b85450;` |
| Cloud | 云服务/外部系统 | `shape=cloud;whiteSpace=wrap;html=1;fillColor=#f5f5f5;strokeColor=#666666;` |
| Actor | 用户/角色 | `shape=actor;whiteSpace=wrap;html=1;fillColor=#dae8fc;strokeColor=#6c8ebf;` |

## UML Shapes

| Shape | Purpose | style String |
|-------|---------|-------------|
| Lifeline | 时序图生命线 | `shape=umlLifeline;perimeter=lifelinePerimeter;whiteSpace=wrap;html=1;container=1;collapsible=0;recursiveResize=0;` |
| Activation | 时序图激活条 | `shape=umlActivation;whiteSpace=wrap;html=1;` |
| Class | UML 类图 | `swimlane;fontStyle=0;childLayout=stackLayout;horizontal=1;startSize=30;horizontalStack=0;resizeParent=1;resizeLast=0;collapsible=0;` |

## Container Shapes

| Shape | Purpose | style String |
|-------|---------|-------------|
| Swimlane | 泳道/分组 | `swimlane;startSize=30;fillColor=#dae8fc;strokeColor=#6c8ebf;` |
| Group Box | 逻辑分组框 | `group;fillColor=none;strokeColor=#999999;dashed=1;` |

## Edge Styles

| Style | style String |
|-------|-------------|
| Straight Arrow | `endArrow=classic;html=1;rounded=0;` |
| Orthogonal (recommended) | `edgeStyle=orthogonalEdgeStyle;rounded=0;orthogonalLoop=1;jettySize=auto;html=1;exitX=0.5;exitY=1;entryX=0.5;entryY=0;` |
| Curved | `endArrow=classic;html=1;curved=1;` |
| Dashed | `endArrow=classic;html=1;dashed=1;` |
| Bidirectional | `endArrow=classic;startArrow=classic;html=1;` |
| Labeled edge (add to base) | append `;labelBackgroundColor=#ffffff;` + set `value="label text"` |

### Direction Control (for orthogonal edges)

| Direction | exitX | exitY | entryX | entryY |
|-----------|-------|-------|--------|--------|
| Top → Bottom | 0.5 | 1 | 0.5 | 0 |
| Left → Right | 1 | 0.5 | 0 | 0.5 |
| Bottom → Top | 0.5 | 0 | 0.5 | 1 |
| Right → Left | 0 | 0.5 | 1 | 0.5 |
| Decision: Yes branch | 1 | 0.5 | — | — |
| Decision: No branch | 0.5 | 1 | — | — |
