import 'package:flutter/material.dart';
import 'package:graphview/GraphView.dart';

/// 직선 Edge 렌더러
///
/// TreeEdgeRenderer 대신 사용하여 직선으로 노드를 연결
class StraightEdgeRenderer extends EdgeRenderer {
  final BuchheimWalkerConfiguration configuration;
  final Color lineColor;
  final double strokeWidth;

  StraightEdgeRenderer(
    this.configuration, {
    this.lineColor = const Color(0xFFBDBDBD),
    this.strokeWidth = 2.0,
  });

  @override
  void render(Canvas canvas, Graph graph, Paint paint) {
    paint
      ..color = lineColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    for (final edge in graph.edges) {
      renderEdge(canvas, edge, paint);
    }
  }

  @override
  void renderEdge(Canvas canvas, Edge edge, Paint paint) {
    paint
      ..color = lineColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final source = edge.source;
    final destination = edge.destination;

    final sourceX = source.x + source.width / 2;
    final sourceY = source.y + source.height;
    final destX = destination.x + destination.width / 2;
    final destY = destination.y;

    // 직선으로 연결 (수직선 + 수평선 + 수직선 패턴)
    final midY = sourceY + (destY - sourceY) / 2;

    final path = Path()
      ..moveTo(sourceX, sourceY)
      ..lineTo(sourceX, midY)
      ..lineTo(destX, midY)
      ..lineTo(destX, destY);

    canvas.drawPath(path, paint);
  }
}

/// 직선 Edge 렌더러 (단순 버전 - 완전 직선)
class SimpleLineEdgeRenderer extends EdgeRenderer {
  final Color lineColor;
  final double strokeWidth;

  SimpleLineEdgeRenderer({
    this.lineColor = const Color(0xFFBDBDBD),
    this.strokeWidth = 1.5,
  });

  @override
  void render(Canvas canvas, Graph graph, Paint paint) {
    paint
      ..color = lineColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

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
      ..strokeCap = StrokeCap.round;

    final source = edge.source;
    final destination = edge.destination;

    // 소스 노드 하단 중앙
    final sourceX = source.x + source.width / 2;
    final sourceY = source.y + source.height;

    // 대상 노드 상단 중앙
    final destX = destination.x + destination.width / 2;
    final destY = destination.y;

    // 직선으로 연결
    canvas.drawLine(
      Offset(sourceX, sourceY),
      Offset(destX, destY),
      paint,
    );
  }
}
