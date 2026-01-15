import 'dart:math';
import 'package:flutter/material.dart';

/// 신비로운 달과 별 일러스트레이션
/// 동양적인 느낌의 밤하늘 표현
class MysticMoonIllustration extends StatelessWidget {
  final double size;
  final Color? primaryColor;
  final bool showStars;
  final bool showClouds;

  const MysticMoonIllustration({
    super.key,
    this.size = 200,
    this.primaryColor,
    this.showStars = true,
    this.showClouds = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _MysticMoonPainter(
          primaryColor: primaryColor ?? const Color(0xFF6B48FF),
          showStars: showStars,
          showClouds: showClouds,
        ),
      ),
    );
  }
}

class _MysticMoonPainter extends CustomPainter {
  final Color primaryColor;
  final bool showStars;
  final bool showClouds;

  _MysticMoonPainter({
    required this.primaryColor,
    required this.showStars,
    required this.showClouds,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final moonRadius = size.width * 0.25;

    // 배경 그라데이션 원
    final bgPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          primaryColor.withValues(alpha: 0.15),
          primaryColor.withValues(alpha: 0.05),
          Colors.transparent,
        ],
        stops: const [0.0, 0.6, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: size.width * 0.5));
    canvas.drawCircle(center, size.width * 0.5, bgPaint);

    // 별 그리기
    if (showStars) {
      _drawStars(canvas, size, center, moonRadius);
    }

    // 구름 효과
    if (showClouds) {
      _drawClouds(canvas, size);
    }

    // 달 그림자 (은은한 글로우)
    final moonGlowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withValues(alpha: 0.3),
          Colors.white.withValues(alpha: 0.1),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: moonRadius * 1.5));
    canvas.drawCircle(center, moonRadius * 1.5, moonGlowPaint);

    // 달 (초승달 모양) - 두 원의 차이로 깔끔하게 그리기
    final moonPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.white.withValues(alpha: 0.95),
          const Color(0xFFE8E8D0).withValues(alpha: 0.9),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromCircle(center: center, radius: moonRadius));

    // 바깥 원 (달 전체)
    final outerPath = Path()
      ..addOval(Rect.fromCircle(center: center, radius: moonRadius));

    // 안쪽 원 (잘라낼 부분) - 오른쪽 위로 살짝 이동
    final innerCenter = Offset(center.dx + moonRadius * 0.5, center.dy);
    final innerPath = Path()
      ..addOval(Rect.fromCircle(center: innerCenter, radius: moonRadius * 0.85));

    // 바깥 원에서 안쪽 원을 빼서 초승달 모양 만들기
    final crescentPath = Path.combine(PathOperation.difference, outerPath, innerPath);

    canvas.drawPath(crescentPath, moonPaint);

    // 달 테두리 글로우
    final moonBorderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = Colors.white.withValues(alpha: 0.4);
    canvas.drawPath(crescentPath, moonBorderPaint);
  }

  void _drawStars(Canvas canvas, Size size, Offset center, double moonRadius) {
    final random = Random(42); // 고정 시드로 일관된 별 위치
    final starPaint = Paint()..color = Colors.white;

    // 큰 별들
    final bigStars = [
      Offset(size.width * 0.15, size.height * 0.2),
      Offset(size.width * 0.8, size.height * 0.15),
      Offset(size.width * 0.75, size.height * 0.7),
      Offset(size.width * 0.2, size.height * 0.75),
      Offset(size.width * 0.9, size.height * 0.45),
    ];

    for (final pos in bigStars) {
      _drawStar(canvas, pos, 3 + random.nextDouble() * 2, starPaint);
    }

    // 작은 별들 (랜덤)
    for (int i = 0; i < 15; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final pos = Offset(x, y);

      // 달과 너무 가까우면 건너뛰기
      if ((pos - center).distance < moonRadius * 1.5) continue;

      final starSize = 1 + random.nextDouble() * 1.5;
      starPaint.color = Colors.white.withValues(alpha: 0.3 + random.nextDouble() * 0.7);
      canvas.drawCircle(pos, starSize, starPaint);
    }
  }

  void _drawStar(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path();
    const points = 4;
    const innerRadius = 0.4;

    for (int i = 0; i < points * 2; i++) {
      final radius = i.isEven ? size : size * innerRadius;
      final angle = (i * pi / points) - pi / 2;
      final point = Offset(
        center.dx + radius * cos(angle),
        center.dy + radius * sin(angle),
      );
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();

    // 별 글로우
    final glowPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, paint);
  }

  void _drawClouds(Canvas canvas, Size size) {
    final cloudPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08);

    // 하단 구름
    final cloudPath = Path();
    cloudPath.moveTo(0, size.height * 0.85);
    cloudPath.quadraticBezierTo(
      size.width * 0.2, size.height * 0.75,
      size.width * 0.4, size.height * 0.82,
    );
    cloudPath.quadraticBezierTo(
      size.width * 0.6, size.height * 0.9,
      size.width * 0.8, size.height * 0.8,
    );
    cloudPath.quadraticBezierTo(
      size.width * 0.95, size.height * 0.75,
      size.width, size.height * 0.85,
    );
    cloudPath.lineTo(size.width, size.height);
    cloudPath.lineTo(0, size.height);
    cloudPath.close();

    canvas.drawPath(cloudPath, cloudPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
