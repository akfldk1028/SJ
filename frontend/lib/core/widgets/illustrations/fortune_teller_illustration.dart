import 'dart:math';
import 'package:flutter/material.dart';

/// 점술가/신비로운 인물 실루엣 일러스트레이션
/// 동양적인 느낌의 명상하는 인물과 빛
class FortuneTellerIllustration extends StatelessWidget {
  final double size;
  final Color? primaryColor;
  final bool showAura;
  final bool showSymbols;

  const FortuneTellerIllustration({
    super.key,
    this.size = 200,
    this.primaryColor,
    this.showAura = true,
    this.showSymbols = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _FortuneTellerPainter(
          primaryColor: primaryColor ?? const Color(0xFF6B48FF),
          showAura: showAura,
          showSymbols: showSymbols,
        ),
      ),
    );
  }
}

class _FortuneTellerPainter extends CustomPainter {
  final Color primaryColor;
  final bool showAura;
  final bool showSymbols;

  _FortuneTellerPainter({
    required this.primaryColor,
    required this.showAura,
    required this.showSymbols,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.5);

    // 배경 오라
    if (showAura) {
      _drawAura(canvas, size, center);
    }

    // 명상하는 인물 실루엣
    _drawFigure(canvas, size);

    // 주변 심볼들
    if (showSymbols) {
      _drawSymbols(canvas, size);
    }

    // 손 위의 빛나는 구슬
    _drawCrystalBall(canvas, size);
  }

  void _drawAura(Canvas canvas, Size size, Offset center) {
    // 외부 오라
    for (int i = 3; i >= 0; i--) {
      final radius = size.width * (0.25 + i * 0.08);
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [
            primaryColor.withValues(alpha: 0.1 - i * 0.02),
            Colors.transparent,
          ],
        ).createShader(Rect.fromCircle(center: center, radius: radius));
      canvas.drawCircle(center, radius, paint);
    }
  }

  void _drawFigure(Canvas canvas, Size size) {
    final figurePath = Path();
    final baseY = size.height * 0.85;
    final centerX = size.width / 2;

    // 몸체 (간단한 실루엣)
    figurePath.moveTo(centerX - size.width * 0.25, baseY);

    // 왼쪽 어깨
    figurePath.quadraticBezierTo(
      centerX - size.width * 0.2,
      size.height * 0.5,
      centerX - size.width * 0.08,
      size.height * 0.4,
    );

    // 머리
    figurePath.quadraticBezierTo(
      centerX - size.width * 0.05,
      size.height * 0.25,
      centerX,
      size.height * 0.22,
    );
    figurePath.quadraticBezierTo(
      centerX + size.width * 0.05,
      size.height * 0.25,
      centerX + size.width * 0.08,
      size.height * 0.4,
    );

    // 오른쪽 어깨
    figurePath.quadraticBezierTo(
      centerX + size.width * 0.2,
      size.height * 0.5,
      centerX + size.width * 0.25,
      baseY,
    );

    figurePath.close();

    // 실루엣 그라데이션
    final figurePaint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.white.withValues(alpha: 0.15),
          Colors.white.withValues(alpha: 0.05),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(figurePath, figurePaint);

    // 테두리 글로우
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = Colors.white.withValues(alpha: 0.2);
    canvas.drawPath(figurePath, borderPaint);
  }

  void _drawSymbols(Canvas canvas, Size size) {
    final symbolPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // 팔괘 심볼 위치들
    final positions = [
      Offset(size.width * 0.1, size.height * 0.2),
      Offset(size.width * 0.9, size.height * 0.25),
      Offset(size.width * 0.08, size.height * 0.6),
      Offset(size.width * 0.92, size.height * 0.55),
    ];

    for (int i = 0; i < positions.length; i++) {
      _drawTrigramSymbol(canvas, positions[i], 12, symbolPaint, i);
    }

    // 작은 별들
    final starPaint = Paint()..color = Colors.white.withValues(alpha: 0.4);
    final random = Random(42);
    for (int i = 0; i < 8; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height * 0.5;
      if (x > size.width * 0.3 && x < size.width * 0.7) continue; // 중앙 피하기
      canvas.drawCircle(Offset(x, y), 1 + random.nextDouble(), starPaint);
    }
  }

  void _drawTrigramSymbol(Canvas canvas, Offset center, double size, Paint paint, int type) {
    // 간단한 팔괘 (3줄 패턴)
    final patterns = [
      [true, true, true],      // 건 (하늘)
      [false, false, false],   // 곤 (땅)
      [true, false, true],     // 감 (물)
      [false, true, false],    // 리 (불)
    ];

    final pattern = patterns[type % patterns.length];
    final lineSpacing = size * 0.4;

    for (int i = 0; i < 3; i++) {
      final y = center.dy - lineSpacing + i * lineSpacing;
      if (pattern[i]) {
        // 양효 (실선)
        canvas.drawLine(
          Offset(center.dx - size, y),
          Offset(center.dx + size, y),
          paint,
        );
      } else {
        // 음효 (끊어진 선)
        canvas.drawLine(
          Offset(center.dx - size, y),
          Offset(center.dx - size * 0.2, y),
          paint,
        );
        canvas.drawLine(
          Offset(center.dx + size * 0.2, y),
          Offset(center.dx + size, y),
          paint,
        );
      }
    }
  }

  void _drawCrystalBall(Canvas canvas, Size size) {
    final ballCenter = Offset(size.width / 2, size.height * 0.55);
    final ballRadius = size.width * 0.08;

    // 구슬 글로우
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          primaryColor.withValues(alpha: 0.6),
          primaryColor.withValues(alpha: 0.2),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: ballCenter, radius: ballRadius * 2));
    canvas.drawCircle(ballCenter, ballRadius * 2, glowPaint);

    // 구슬 본체
    final ballPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withValues(alpha: 0.9),
          primaryColor.withValues(alpha: 0.5),
        ],
        center: const Alignment(-0.3, -0.3),
      ).createShader(Rect.fromCircle(center: ballCenter, radius: ballRadius));
    canvas.drawCircle(ballCenter, ballRadius, ballPaint);

    // 하이라이트
    final highlightPaint = Paint()..color = Colors.white.withValues(alpha: 0.8);
    canvas.drawCircle(
      Offset(ballCenter.dx - ballRadius * 0.3, ballCenter.dy - ballRadius * 0.3),
      ballRadius * 0.2,
      highlightPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
