# Full Examples

## Example 1: Simple Login Flowchart (8 nodes)

User login flow: Input → Validate → Decision → Query DB → Decision → Generate Token → Success

```xml
<?xml version="1.0" encoding="UTF-8"?>
<mxfile host="app.diagrams.net" agent="OpenCode Draw.io Skill" version="21.0.0">
  <diagram id="diagram-1" name="用户登录流程">
    <mxGraphModel dx="1422" dy="900" grid="1" gridSize="10" guides="1" tooltips="1" connect="1" arrows="1" fold="1" page="1" pageScale="1" pageWidth="1169" pageHeight="827" math="0" shadow="0">
      <root>
        <mxCell id="0" />
        <mxCell id="1" parent="0" />
        
        <!-- Start -->
        <mxCell id="2" value="开始" style="ellipse;whiteSpace=wrap;html=1;fillColor=#d5e8d4;strokeColor=#82b366;" vertex="1" parent="1">
          <mxGeometry x="380" y="20" width="120" height="60" as="geometry"/>
        </mxCell>
        
        <!-- Input credentials -->
        <mxCell id="3" value="用户输入凭证" style="shape=parallelogram;perimeter=parallelogramPerimeter;whiteSpace=wrap;html=1;fixedSize=1;fillColor=#e1d5e7;strokeColor=#9673a6;" vertex="1" parent="1">
          <mxGeometry x="360" y="110" width="160" height="60" as="geometry"/>
        </mxCell>
        
        <!-- Validate format -->
        <mxCell id="4" value="验证输入格式" style="whiteSpace=wrap;html=1;fillColor=#dae8fc;strokeColor=#6c8ebf;" vertex="1" parent="1">
          <mxGeometry x="360" y="210" width="160" height="60" as="geometry"/>
        </mxCell>
        
        <!-- Format OK? -->
        <mxCell id="5" value="格式正确?" style="rhombus;whiteSpace=wrap;html=1;fillColor=#fff2cc;strokeColor=#d6b656;" vertex="1" parent="1">
          <mxGeometry x="370" y="310" width="140" height="80" as="geometry"/>
        </mxCell>
        
        <!-- Format error -->
        <mxCell id="6" value="提示格式错误" style="whiteSpace=wrap;html=1;fillColor=#f8cecc;strokeColor=#b85450;" vertex="1" parent="1">
          <mxGeometry x="580" y="320" width="120" height="60" as="geometry"/>
        </mxCell>
        
        <!-- Query DB -->
        <mxCell id="7" value="查询用户数据库" style="shape=cylinder3;whiteSpace=wrap;html=1;boundedLbl=1;backgroundOutline=1;size=15;fillColor=#f5f5f5;strokeColor=#666666;" vertex="1" parent="1">
          <mxGeometry x="355" y="440" width="170" height="70" as="geometry"/>
        </mxCell>
        
        <!-- User exists? -->
        <mxCell id="8" value="用户存在?" style="rhombus;whiteSpace=wrap;html=1;fillColor=#fff2cc;strokeColor=#d6b656;" vertex="1" parent="1">
          <mxGeometry x="370" y="550" width="140" height="80" as="geometry"/>
        </mxCell>
        
        <!-- Generate Token -->
        <mxCell id="9" value="生成 JWT Token" style="whiteSpace=wrap;html=1;fillColor=#dae8fc;strokeColor=#6c8ebf;" vertex="1" parent="1">
          <mxGeometry x="360" y="670" width="160" height="60" as="geometry"/>
        </mxCell>
        
        <!-- Success -->
        <mxCell id="10" value="登录成功" style="ellipse;whiteSpace=wrap;html=1;fillColor=#d5e8d4;strokeColor=#82b366;" vertex="1" parent="1">
          <mxGeometry x="380" y="770" width="120" height="60" as="geometry"/>
        </mxCell>

        <!-- Edges -->
        <mxCell id="101" value="" style="edgeStyle=orthogonalEdgeStyle;rounded=0;orthogonalLoop=1;jettySize=auto;html=1;exitX=0.5;exitY=1;entryX=0.5;entryY=0;" edge="1" parent="1" source="2" target="3"><mxGeometry relative="1" as="geometry"/></mxCell>
        <mxCell id="102" value="" style="edgeStyle=orthogonalEdgeStyle;rounded=0;orthogonalLoop=1;jettySize=auto;html=1;exitX=0.5;exitY=1;entryX=0.5;entryY=0;" edge="1" parent="1" source="3" target="4"><mxGeometry relative="1" as="geometry"/></mxCell>
        <mxCell id="103" value="" style="edgeStyle=orthogonalEdgeStyle;rounded=0;orthogonalLoop=1;jettySize=auto;html=1;exitX=0.5;exitY=1;entryX=0.5;entryY=0;" edge="1" parent="1" source="4" target="5"><mxGeometry relative="1" as="geometry"/></mxCell>
        <mxCell id="104" value="是" style="edgeStyle=orthogonalEdgeStyle;rounded=0;orthogonalLoop=1;jettySize=auto;html=1;exitX=0.5;exitY=1;entryX=0.5;entryY=0;labelBackgroundColor=#ffffff;" edge="1" parent="1" source="5" target="7"><mxGeometry relative="1" as="geometry"/></mxCell>
        <mxCell id="105" value="否" style="edgeStyle=orthogonalEdgeStyle;rounded=0;orthogonalLoop=1;jettySize=auto;html=1;exitX=1;exitY=0.5;entryX=0;entryY=0.5;labelBackgroundColor=#ffffff;" edge="1" parent="1" source="5" target="6"><mxGeometry relative="1" as="geometry"/></mxCell>
        <mxCell id="106" value="" style="edgeStyle=orthogonalEdgeStyle;rounded=0;orthogonalLoop=1;jettySize=auto;html=1;exitX=0.5;exitY=1;entryX=0.5;entryY=0;" edge="1" parent="1" source="7" target="8"><mxGeometry relative="1" as="geometry"/></mxCell>
        <mxCell id="107" value="是" style="edgeStyle=orthogonalEdgeStyle;rounded=0;orthogonalLoop=1;jettySize=auto;html=1;exitX=0.5;exitY=1;entryX=0.5;entryY=0;labelBackgroundColor=#ffffff;" edge="1" parent="1" source="8" target="9"><mxGeometry relative="1" as="geometry"/></mxCell>
        <mxCell id="108" value="" style="edgeStyle=orthogonalEdgeStyle;rounded=0;orthogonalLoop=1;jettySize=auto;html=1;exitX=0.5;exitY=1;entryX=0.5;entryY=0;" edge="1" parent="1" source="9" target="10"><mxGeometry relative="1" as="geometry"/></mxCell>
      </root>
    </mxGraphModel>
  </diagram>
</mxfile>
```

## Example 2: Microservice Architecture (6 services)

Client → Gateway → Services → Queue → DB

```xml
<?xml version="1.0" encoding="UTF-8"?>
<mxfile host="app.diagrams.net" agent="OpenCode Draw.io Skill" version="21.0.0">
  <diagram id="diagram-1" name="微服务架构">
    <mxGraphModel dx="1422" dy="900" grid="1" gridSize="10" guides="1" tooltips="1" connect="1" arrows="1" fold="1" page="1" pageScale="1" pageWidth="1169" pageHeight="827" math="0" shadow="0">
      <root>
        <mxCell id="0" />
        <mxCell id="1" parent="0" />

        <!-- Client Layer -->
        <mxCell id="2" value="Web 前端 (React)" style="rounded=1;whiteSpace=wrap;html=1;fillColor=#ffe6cc;strokeColor=#d79b00;" vertex="1" parent="1">
          <mxGeometry x="40" y="200" width="140" height="70" as="geometry"/>
        </mxCell>
        <mxCell id="3" value="移动端 (RN)" style="rounded=1;whiteSpace=wrap;html=1;fillColor=#ffe6cc;strokeColor=#d79b00;" vertex="1" parent="1">
          <mxGeometry x="40" y="320" width="140" height="70" as="geometry"/>
        </mxCell>

        <!-- Gateway -->
        <mxCell id="4" value="API Gateway" style="shape=hexagon;perimeter=hexagonPerimeter2;whiteSpace=wrap;html=1;fixedSize=1;fillColor=#d5e8d4;strokeColor=#82b366;" vertex="1" parent="1">
          <mxGeometry x="280" y="255" width="140" height="80" as="geometry"/>
        </mxCell>

        <!-- Services -->
        <mxCell id="5" value="用户服务&#xa;Port 3001" style="rounded=1;whiteSpace=wrap;html=1;fillColor=#dae8fc;strokeColor=#6c8ebf;arcSize=20;" vertex="1" parent="1">
          <mxGeometry x="530" y="120" width="140" height="70" as="geometry"/>
        </mxCell>
        <mxCell id="6" value="订单服务&#xa;Port 3002" style="rounded=1;whiteSpace=wrap;html=1;fillColor=#dae8fc;strokeColor=#6c8ebf;arcSize=20;" vertex="1" parent="1">
          <mxGeometry x="530" y="250" width="140" height="70" as="geometry"/>
        </mxCell>
        <mxCell id="7" value="通知服务&#xa;Port 3003" style="rounded=1;whiteSpace=wrap;html=1;fillColor=#dae8fc;strokeColor=#6c8ebf;arcSize=20;" vertex="1" parent="1">
          <mxGeometry x="530" y="380" width="140" height="70" as="geometry"/>
        </mxCell>

        <!-- Message Queue -->
        <mxCell id="8" value="RabbitMQ" style="shape=cylinder3;whiteSpace=wrap;html=1;boundedLbl=1;size=10;fillColor=#f8cecc;strokeColor=#b85450;" vertex="1" parent="1">
          <mxGeometry x="770" y="245" width="120" height="80" as="geometry"/>
        </mxCell>

        <!-- Databases -->
        <mxCell id="9" value="PostgreSQL" style="shape=cylinder3;whiteSpace=wrap;html=1;boundedLbl=1;backgroundOutline=1;size=15;fillColor=#f5f5f5;strokeColor=#666666;" vertex="1" parent="1">
          <mxGeometry x="530" y="520" width="140" height="80" as="geometry"/>
        </mxCell>

        <!-- Edges - Client to Gateway -->
        <mxCell id="101" value="" style="edgeStyle=orthogonalEdgeStyle;rounded=0;orthogonalLoop=1;jettySize=auto;html=1;exitX=1;exitY=0.5;entryX=0;entryY=0.3;" edge="1" parent="1" source="2" target="4"><mxGeometry relative="1" as="geometry"/></mxCell>
        <mxCell id="102" value="" style="edgeStyle=orthogonalEdgeStyle;rounded=0;orthogonalLoop=1;jettySize=auto;html=1;exitX=1;exitY=0.5;entryX=0;entryY=0.7;" edge="1" parent="1" source="3" target="4"><mxGeometry relative="1" as="geometry"/></mxCell>

        <!-- Gateway to Services -->
        <mxCell id="103" value="" style="edgeStyle=orthogonalEdgeStyle;rounded=0;orthogonalLoop=1;jettySize=auto;html=1;exitX=1;exitY=0.25;entryX=0;entryY=0.5;" edge="1" parent="1" source="4" target="5"><mxGeometry relative="1" as="geometry"/></mxCell>
        <mxCell id="104" value="" style="edgeStyle=orthogonalEdgeStyle;rounded=0;orthogonalLoop=1;jettySize=auto;html=1;exitX=1;exitY=0.5;entryX=0;entryY=0.5;" edge="1" parent="1" source="4" target="6"><mxGeometry relative="1" as="geometry"/></mxCell>
        <mxCell id="105" value="" style="edgeStyle=orthogonalEdgeStyle;rounded=0;orthogonalLoop=1;jettySize=auto;html=1;exitX=1;exitY=0.75;entryX=0;entryY=0.5;" edge="1" parent="1" source="4" target="7"><mxGeometry relative="1" as="geometry"/></mxCell>

        <!-- Service to Queue -->
        <mxCell id="106" value="发布事件" style="edgeStyle=orthogonalEdgeStyle;rounded=0;orthogonalLoop=1;jettySize=auto;html=1;exitX=1;exitY=0.5;entryX=0;entryY=0.5;labelBackgroundColor=#ffffff;" edge="1" parent="1" source="6" target="8"><mxGeometry relative="1" as="geometry"/></mxCell>

        <!-- Service to DB -->
        <mxCell id="107" value="" style="edgeStyle=orthogonalEdgeStyle;rounded=0;orthogonalLoop=1;jettySize=auto;html=1;exitX=0.5;exitY=1;entryX=0.5;entryY=0;endArrow=classic;startArrow=classic;" edge="1" parent="1" source="6" target="9"><mxGeometry relative="1" as="geometry"/></mxCell>
      </root>
    </mxGraphModel>
  </diagram>
</mxfile>
```

## Example 3: Entity-Relationship Diagram (3 tables)

Users → Orders → Products

```xml
<?xml version="1.0" encoding="UTF-8"?>
<mxfile host="app.diagrams.net" agent="OpenCode Draw.io Skill" version="21.0.0">
  <diagram id="diagram-1" name="ER图">
    <mxGraphModel dx="1422" dy="762" grid="1" gridSize="10" guides="1" tooltips="1" connect="1" arrows="1" fold="1" page="1" pageScale="1" pageWidth="1169" pageHeight="827" math="0" shadow="0">
      <root>
        <mxCell id="0" />
        <mxCell id="1" parent="0" />

        <!-- Users table -->
        <mxCell id="2" value="Users" style="swimlane;fontStyle=1;align=center;verticalAlign=top;childLayout=stackLayout;horizontal=1;startSize=26;horizontalStack=0;resizeParent=1;resizeParentMax=0;resizeLast=0;collapsible=1;marginBottom=0;fillColor=#dae8fc;strokeColor=#6c8ebf;" vertex="1" parent="1">
          <mxGeometry x="40" y="100" width="200" height="146" as="geometry"/>
        </mxCell>
        <mxCell id="3" value="PK  id: INT" style="text;strokeColor=none;fillColor=none;align=left;verticalAlign=top;spacingLeft=4;spacingRight=4;overflow=hidden;rotatable=0;points=[[0,0.5],[1,0.5]];portConstraint=eastwest;" vertex="1" parent="2">
          <mxGeometry y="26" width="200" height="26" as="geometry"/>
        </mxCell>
        <mxCell id="4" value="name: VARCHAR(100)" style="text;strokeColor=none;fillColor=none;align=left;verticalAlign=top;spacingLeft=4;spacingRight=4;overflow=hidden;rotatable=0;points=[[0,0.5],[1,0.5]];portConstraint=eastwest;" vertex="1" parent="2">
          <mxGeometry y="52" width="200" height="26" as="geometry"/>
        </mxCell>
        <mxCell id="5" value="email: VARCHAR(255)" style="text;strokeColor=none;fillColor=none;align=left;verticalAlign=top;spacingLeft=4;spacingRight=4;overflow=hidden;rotatable=0;points=[[0,0.5],[1,0.5]];portConstraint=eastwest;" vertex="1" parent="2">
          <mxGeometry y="78" width="200" height="26" as="geometry"/>
        </mxCell>
        <mxCell id="6" value="created_at: TIMESTAMP" style="text;strokeColor=none;fillColor=none;align=left;verticalAlign=top;spacingLeft=4;spacingRight=4;overflow=hidden;rotatable=0;points=[[0,0.5],[1,0.5]];portConstraint=eastwest;" vertex="1" parent="2">
          <mxGeometry y="104" width="200" height="26" as="geometry"/>
        </mxCell>

        <!-- Orders table -->
        <mxCell id="7" value="Orders" style="swimlane;fontStyle=1;align=center;verticalAlign=top;childLayout=stackLayout;horizontal=1;startSize=26;horizontalStack=0;resizeParent=1;resizeParentMax=0;resizeLast=0;collapsible=1;marginBottom=0;fillColor=#fff2cc;strokeColor=#d6b656;" vertex="1" parent="1">
          <mxGeometry x="350" y="100" width="200" height="172" as="geometry"/>
        </mxCell>
        <mxCell id="8" value="PK  id: INT" style="text;strokeColor=none;fillColor=none;align=left;verticalAlign=top;spacingLeft=4;spacingRight=4;overflow=hidden;rotatable=0;points=[[0,0.5],[1,0.5]];portConstraint=eastwest;" vertex="1" parent="7">
          <mxGeometry y="26" width="200" height="26" as="geometry"/>
        </mxCell>
        <mxCell id="9" value="FK  user_id: INT" style="text;strokeColor=none;fillColor=none;align=left;verticalAlign=top;spacingLeft=4;spacingRight=4;overflow=hidden;rotatable=0;points=[[0,0.5],[1,0.5]];portConstraint=eastwest;" vertex="1" parent="7">
          <mxGeometry y="52" width="200" height="26" as="geometry"/>
        </mxCell>
        <mxCell id="10" value="total: DECIMAL(10,2)" style="text;strokeColor=none;fillColor=none;align=left;verticalAlign=top;spacingLeft=4;spacingRight=4;overflow=hidden;rotatable=0;points=[[0,0.5],[1,0.5]];portConstraint=eastwest;" vertex="1" parent="7">
          <mxGeometry y="78" width="200" height="26" as="geometry"/>
        </mxCell>
        <mxCell id="11" value="status: VARCHAR(50)" style="text;strokeColor=none;fillColor=none;align=left;verticalAlign=top;spacingLeft=4;spacingRight=4;overflow=hidden;rotatable=0;points=[[0,0.5],[1,0.5]];portConstraint=eastwest;" vertex="1" parent="7">
          <mxGeometry y="104" width="200" height="26" as="geometry"/>
        </mxCell>
        <mxCell id="12" value="created_at: TIMESTAMP" style="text;strokeColor=none;fillColor=none;align=left;verticalAlign=top;spacingLeft=4;spacingRight=4;overflow=hidden;rotatable=0;points=[[0,0.5],[1,0.5]];portConstraint=eastwest;" vertex="1" parent="7">
          <mxGeometry y="130" width="200" height="26" as="geometry"/>
        </mxCell>

        <!-- Relation edges -->
        <mxCell id="101" value="1" style="edgeStyle=orthogonalEdgeStyle;rounded=0;orthogonalLoop=1;jettySize=auto;html=1;exitX=1;exitY=0.5;entryX=0;entryY=0.5;endArrow=none;startArrow=none;" edge="1" parent="1" source="3" target="9">
          <mxGeometry relative="1" as="geometry"/>
        </mxCell>
        <mxCell id="102" value="N" style="edgeStyle=orthogonalEdgeStyle;rounded=0;orthogonalLoop=1;jettySize=auto;html=1;exitX=0;exitY=0.5;entryX=1;entryY=0.5;endArrow=none;startArrow=none;" edge="1" parent="1" source="9" target="3">
          <mxGeometry relative="1" as="geometry"/>
        </mxCell>
      </root>
    </mxGraphModel>
  </diagram>
</mxfile>
```
