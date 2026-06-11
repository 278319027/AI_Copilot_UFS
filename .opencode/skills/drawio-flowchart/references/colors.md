# Color Schemes

## Standard Color Palette

| Name | Usage | fillColor | strokeColor |
|------|-------|-----------|--------------|
| Green | 开始节点、成功状态、API 网关 | `#d5e8d4` | `#82b366` |
| Blue | 处理步骤、后端服务 | `#dae8fc` | `#6c8ebf` |
| Yellow | 判断/条件/分支 | `#fff2cc` | `#d6b656` |
| Purple | 数据输入/输出 | `#e1d5e7` | `#9673a6` |
| Red | 错误处理、结束(异常)、消息队列 | `#f8cecc` | `#b85450` |
| Orange | 前端/客户端/用户界面 | `#ffe6cc` | `#d79b00` |
| Gray | 数据库、外部系统、云服务 | `#f5f5f5` | `#666666` |

## Role-to-Color Mapping Rules

```
开始/结束节点     → Green (#d5e8d4 / #82b366)
处理步骤         → Blue  (#dae8fc / #6c8ebf)
判断分支         → Yellow (#fff2cc / #d6b656)
数据I/O          → Purple (#e1d5e7 / #9673a6)
错误/异常        → Red (#f8cecc / #b85450)
前端/客户端      → Orange (#ffe6cc / #d79b00)
数据库/存储      → Gray (#f5f5f5 / #666666)
```

## Diagram Type Color Schemes

### Flowchart
- Start: Green ellipse/rounded
- Process: Blue rectangle
- Decision: Yellow rhombus
- I/O: Purple parallelogram
- Error: Red rectangle
- End: Green ellipse/rounded

### Architecture Diagram
- Client/Frontend: Orange rounded
- Gateway: Green hexagon
- Services: Blue rounded (arcSize=20)
- Message Queue: Red cylinder
- Database: Gray cylinder
- Cache: Gray cylinder (dashed border)
- External API: Gray cloud

### Sequence Diagram
- Lifelines: Default (no fill)
- Activation bars: Light gray
- Messages: Black arrows
- Return messages: Dashed arrows

### ER Diagram
- Entities: Gray rectangle (header row colored)
- Primary keys: Bold or underlined in entity
- Foreign keys: Normal font in entity
- Relationships: Lines with cardinality labels (1, N, 0..1)

## Edge Colors

Use `strokeColor=#xxxxxx;` in edge style strings to override. Default: `#000000` (black).
For light/dark backgrounds, ensure contrast. Recommended edge colors:
- Default: `#000000` (black)
- Optional/async: `#999999` (gray) + `dashed=1`
- Error paths: `#b85450` (red)
- Primary flow: `#6c8ebf` (blue)
