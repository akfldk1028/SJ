import 'package:flutter/material.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../domain/models/ai_persona.dart';

/// MBTI 4축 좌표계 선택기
///
/// ```
///        N (직관)
///        │
///   NF   │   NT
/// (감성형) │ (분석형)
///        │
/// F ─────●───── T
///        │
///   SF   │   ST
/// (친근형) │ (현실형)
///        │
///        S (감각)
/// ```
///
/// 터치/드래그로 분면 선택
class MbtiAxisSelector extends StatefulWidget {
  final MbtiQuadrant? selectedQuadrant;
  final ValueChanged<MbtiQuadrant> onQuadrantSelected;
  final double size;

  const MbtiAxisSelector({
    super.key,
    this.selectedQuadrant,
    required this.onQuadrantSelected,
    this.size = 200,
  });

  @override
  State<MbtiAxisSelector> createState() => _MbtiAxisSelectorState();
}

class _MbtiAxisSelectorState extends State<MbtiAxisSelector> {
  /// 선택 포인트 위치 (중앙 기준 -1 ~ 1)
  Offset _position = Offset.zero;

  @override
  void initState() {
    super.initState();
    // 기존 선택된 분면이 있으면 해당 위치로 초기화
    if (widget.selectedQuadrant != null) {
      _position = _getPositionForQuadrant(widget.selectedQuadrant!);
    }
  }

  /// 분면에 해당하는 좌표 반환
  Offset _getPositionForQuadrant(MbtiQuadrant quadrant) {
    switch (quadrant) {
      case MbtiQuadrant.NF:
        return const Offset(-0.5, -0.5); // 좌상
      case MbtiQuadrant.NT:
        return const Offset(0.5, -0.5);  // 우상
      case MbtiQuadrant.SF:
        return const Offset(-0.5, 0.5);  // 좌하
      case MbtiQuadrant.ST:
        return const Offset(0.5, 0.5);   // 우하
    }
  }

  /// 좌표로부터 분면 계산
  MbtiQuadrant _getQuadrantFromPosition(Offset pos) {
    if (pos.dx < 0 && pos.dy < 0) return MbtiQuadrant.NF; // 좌상
    if (pos.dx >= 0 && pos.dy < 0) return MbtiQuadrant.NT; // 우상
    if (pos.dx < 0 && pos.dy >= 0) return MbtiQuadrant.SF; // 좌하
    return MbtiQuadrant.ST; // 우하
  }

  /// 화면 좌표를 정규화된 좌표로 변환 (-1 ~ 1)
  Offset _normalizePosition(Offset localPosition, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final dx = (localPosition.dx - center.dx) / (size.width / 2);
    final dy = (localPosition.dy - center.dy) / (size.height / 2);
    return Offset(
      dx.clamp(-1.0, 1.0),
      dy.clamp(-1.0, 1.0),
    );
  }

  void _handleTapOrDrag(Offset localPosition, Size size) {
    final normalized = _normalizePosition(localPosition, size);
    setState(() {
      _position = normalized;
    });
    final quadrant = _getQuadrantFromPosition(normalized);
    widget.onQuadrantSelected(quadrant);
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;

    return GestureDetector(
      onTapDown: (details) {
        _handleTapOrDrag(details.localPosition, Size(widget.size, widget.size));
      },
      onPanUpdate: (details) {
        _handleTapOrDrag(details.localPosition, Size(widget.size, widget.size));
      },
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: CustomPaint(
          painter: _MbtiAxisPainter(
            position: _position,
            selectedQuadrant: widget.selectedQuadrant,
            theme: theme,
          ),
        ),
      ),
    );
  }
}

/// MBTI 4축 좌표계 Painter
class _MbtiAxisPainter extends CustomPainter {
  final Offset position;
  final MbtiQuadrant? selectedQuadrant;
  final AppThemeExtension theme;

  _MbtiAxisPainter({
    required this.position,
    this.selectedQuadrant,
    required this.theme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 20;

    // 배경
    final bgPaint = Paint()
      ..color = theme.cardColor
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(12),
      ),
      bgPaint,
    );

    // 분면 하이라이트
    if (selectedQuadrant != null) {
      final highlightPaint = Paint()
        ..color = theme.primaryColor.withValues(alpha: 0.3)
        ..style = PaintingStyle.fill;

      Rect quadrantRect;
      switch (selectedQuadrant!) {
        case MbtiQuadrant.NF:
          quadrantRect = Rect.fromLTRB(0, 0, center.dx, center.dy);
          break;
        case MbtiQuadrant.NT:
          quadrantRect = Rect.fromLTRB(center.dx, 0, size.width, center.dy);
          break;
        case MbtiQuadrant.SF:
          quadrantRect = Rect.fromLTRB(0, center.dy, center.dx, size.height);
          break;
        case MbtiQuadrant.ST:
          quadrantRect = Rect.fromLTRB(center.dx, center.dy, size.width, size.height);
          break;
      }
      canvas.drawRect(quadrantRect, highlightPaint);
    }

    // 축 선
    final axisPaint = Paint()
      ..color = theme.primaryColor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // 세로축 (N-S)
    canvas.drawLine(
      Offset(center.dx, 20),
      Offset(center.dx, size.height - 20),
      axisPaint,
    );

    // 가로축 (F-T)
    canvas.drawLine(
      Offset(20, center.dy),
      Offset(size.width - 20, center.dy),
      axisPaint,
    );

    // 화살표
    _drawArrow(canvas, Offset(center.dx, 20), true, axisPaint);  // N
    _drawArrow(canvas, Offset(center.dx, size.height - 20), false, axisPaint); // S
    _drawArrow(canvas, Offset(20, center.dy), true, axisPaint, horizontal: true);  // F
    _drawArrow(canvas, Offset(size.width - 20, center.dy), false, axisPaint, horizontal: true); // T

    // 축 레이블
    final labelColor = theme.accentColor ?? theme.primaryColor;
    _drawLabel(canvas, 'N', Offset(center.dx, 8), labelColor);
    _drawLabel(canvas, 'S', Offset(center.dx, size.height - 8), labelColor);
    _drawLabel(canvas, 'F', Offset(8, center.dy), labelColor);
    _drawLabel(canvas, 'T', Offset(size.width - 8, center.dy), labelColor);

    // 선택 포인트
    final pointX = center.dx + position.dx * radius * 0.7;
    final pointY = center.dy + position.dy * radius * 0.7;

    final pointPaint = Paint()
      ..color = theme.primaryColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(pointX, pointY), 12, pointPaint);

    final pointBorderPaint = Paint()
      ..color = theme.textPrimary
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(Offset(pointX, pointY), 12, pointBorderPaint);
  }

  void _drawArrow(Canvas canvas, Offset tip, bool isStart, Paint paint, {bool horizontal = false}) {
    final path = Path();
    const arrowSize = 8.0;

    if (horizontal) {
      if (isStart) {
        // 왼쪽 화살표 (F)
        path.moveTo(tip.dx, tip.dy);
        path.lineTo(tip.dx + arrowSize, tip.dy - arrowSize / 2);
        path.lineTo(tip.dx + arrowSize, tip.dy + arrowSize / 2);
      } else {
        // 오른쪽 화살표 (T)
        path.moveTo(tip.dx, tip.dy);
        path.lineTo(tip.dx - arrowSize, tip.dy - arrowSize / 2);
        path.lineTo(tip.dx - arrowSize, tip.dy + arrowSize / 2);
      }
    } else {
      if (isStart) {
        // 위쪽 화살표 (N)
        path.moveTo(tip.dx, tip.dy);
        path.lineTo(tip.dx - arrowSize / 2, tip.dy + arrowSize);
        path.lineTo(tip.dx + arrowSize / 2, tip.dy + arrowSize);
      } else {
        // 아래쪽 화살표 (S)
        path.moveTo(tip.dx, tip.dy);
        path.lineTo(tip.dx - arrowSize / 2, tip.dy - arrowSize);
        path.lineTo(tip.dx + arrowSize / 2, tip.dy - arrowSize);
      }
    }
    path.close();

    final fillPaint = Paint()
      ..color = paint.color
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fillPaint);
  }

  void _drawLabel(Canvas canvas, String text, Offset position, Color color) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        position.dx - textPainter.width / 2,
        position.dy - textPainter.height / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant _MbtiAxisPainter oldDelegate) {
    return position != oldDelegate.position ||
        selectedQuadrant != oldDelegate.selectedQuadrant ||
        theme != oldDelegate.theme;
  }
}
