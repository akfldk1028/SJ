import 'dart:math';
import 'package:flutter/material.dart';

/// 연꽃 일러스트레이션
/// 동양적인 느낌의 연꽃과 물결 표현
class LotusIllustration extends StatelessWidget {
  final double size;
  final Color? primaryColor;
  final bool showWater;
  final bool showGlow;

  const LotusIllustration({
    super.key,
    this.size = 200,
    this.primaryColor,
    this.showWater = true,
    this.showGlow = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _LotusPainter(
          primaryColor: primaryColor ?? const Color(0xFFEC4899),
          showWater: showWater,
          showGlow: showGlow,
        ),
      ),
    );
  }
}

class _LotusPainter extends CustomPainter {
  final Color primaryColor;
  final bool showWater;
  final bool showGlow;

  _LotusPainter({
    required this.primaryColor,
    required this.showWater,
    required this.showGlow,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.55);

    // 배경 글로우
    if (showGlow) {
      final glowPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            primaryColor.withValues(alpha: 0.2),
            primaryColor.withValues(alpha: 0.05),
            Colors.transparent,
          ],
          stops: const [0.0, 0.5, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: size.width * 0.5));
      canvas.drawCircle(center, size.width * 0.5, glowPaint);
    }

    // 물결 효과
    if (showWater) {
      _drawWater(canvas, size);
    }

    // 연꽃 그리기
    _drawLotus(canvas, size, center);

    // 연꽃 중심 (꽃술)
    _drawCenter(canvas, center);
  }

  void _drawWater(Canvas canvas, Size size) {
    final waterPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = Colors.white.withValues(alpha: 0.15);

    // 동심원 물결
    for (int i = 0; i < 4; i++) {
      final radius = size.width * (0.35 + i * 0.1);
      final rect = Rect.fromCenter(
        center: Offset(size.width / 2, size.height * 0.7),
        width: radius * 2,
        height: radius * 0.4,
      );
      canvas.drawOval(rect, waterPaint);
    }
  }

  void _drawLotus(Canvas canvas, Size size, Offset center) {
    const petalCount = 8;
    final petalLength = size.width * 0.28;
    final petalWidth = size.width * 0.12;

    // 뒤쪽 꽃잎 (연한 색)
    for (int i = 0; i < petalCount; i++) {
      final angle = (i * 2 * pi / petalCount) - pi / 2 + pi / petalCount;
      _drawPetal(
        canvas,
        center,
        angle,
        petalLength * 0.9,
        petalWidth * 0.9,
        primaryColor.withValues(alpha: 0.4),
        primaryColor.withValues(alpha: 0.2),
      );
    }

    // 앞쪽 꽃잎 (진한 색)
    for (int i = 0; i < petalCount; i++) {
      final angle = (i * 2 * pi / petalCount) - pi / 2;
      _drawPetal(
        canvas,
        center,
        angle,
        petalLength,
        petalWidth,
        primaryColor.withValues(alpha: 0.9),
        primaryColor.withValues(alpha: 0.6),
      );
    }
  }

  void _drawPetal(
    Canvas canvas,
    Offset center,
    double angle,
    double length,
    double width,
    Color startColor,
    Color endColor,
  ) {
    final path = Path();

    // 꽃잎 시작점
    path.moveTo(center.dx, center.dy);

    // 꽃잎 왼쪽 곡선
    final leftControlX = center.dx + (length * 0.3) * cos(angle) - width * cos(angle + pi / 2);
    final leftControlY = center.dy + (length * 0.3) * sin(angle) - width * sin(angle + pi / 2);
    final tipX = center.dx + length * cos(angle);
    final tipY = center.dy + length * sin(angle);

    path.quadraticBezierTo(leftControlX, leftControlY, tipX, tipY);

    // 꽃잎 오른쪽 곡선
    final rightControlX = center.dx + (length * 0.3) * cos(angle) + width * cos(angle + pi / 2);
    final rightControlY = center.dy + (length * 0.3) * sin(angle) + width * sin(angle + pi / 2);

    path.quadraticBezierTo(rightControlX, rightControlY, center.dx, center.dy);

    // 그라데이션 페인트
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [startColor, endColor],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromCenter(center: center, width: length * 2, height: length * 2));

    canvas.drawPath(path, paint);

    // 꽃잎 테두리
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5
      ..color = Colors.white.withValues(alpha: 0.3);
    canvas.drawPath(path, borderPaint);
  }

  void _drawCenter(Canvas canvas, Offset center) {
    // 꽃 중심 (노란색)
    final centerPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFFD700),
          const Color(0xFFFFA500),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: 15));

    canvas.drawCircle(center, 12, centerPaint);

    // 중심 점들 (꽃술)
    final dotPaint = Paint()..color = const Color(0xFFCC8800);
    final random = Random(42);
    for (int i = 0; i < 8; i++) {
      final angle = i * pi / 4;
      final distance = 5 + random.nextDouble() * 3;
      final pos = Offset(
        center.dx + distance * cos(angle),
        center.dy + distance * sin(angle),
      );
      canvas.drawCircle(pos, 1.5, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
