import 'package:flutter/material.dart';
import 'package:graphview/GraphView.dart';

/// 90도 직각 Edge 렌더러
///
/// 수직-수평-수직 패턴으로 노드를 연결 (ㄱ자 모양)
class OrthogonalEdgeRenderer extends EdgeRenderer {
  final Color lineColor;
  final double strokeWidth;

  OrthogonalEdgeRenderer({
    this.lineColor = const Color(0xFFBDBDBD),
    this.strokeWidth = 1.5,
  });

  @override
  void render(Canvas canvas, Graph graph, Paint paint) {
    paint
      ..color = lineColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    for (final edge in graph.edges) {
      renderEdge(canvas, edge, paint);
    }
  }

  @override
  void renderEdge(Canvas canvas, Edge edge, Paint paint) {
    paint
      ..color = lineColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final source = edge.source;
    final destination = edge.destination;

    // LEFT_RIGHT 레이아웃: 소스 오른쪽 → 대상 왼쪽
    final sourceX = source.x + source.width;
    final sourceY = source.y + source.height / 2;

    final destX = destination.x;
    final destY = destination.y + destination.height / 2;

    // 90도 꺾이는 직선: 수평 → 수직 → 수평
    final midX = sourceX + (destX - sourceX) / 2;

    final path = Path()
      ..moveTo(sourceX, sourceY)
      ..lineTo(midX, sourceY)  // 수평선 (오른쪽으로)
      ..lineTo(midX, destY)    // 수직선 (위/아래로)
      ..lineTo(destX, destY);  // 수평선 (오른쪽으로)

    canvas.drawPath(path, paint);
  }
}
