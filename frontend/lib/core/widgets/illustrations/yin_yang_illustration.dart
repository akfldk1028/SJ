import 'dart:math';
import 'package:flutter/material.dart';

/// 음양(태극) 심볼 일러스트레이션
/// 정확한 태극 문양
class YinYangIllustration extends StatelessWidget {
  final double size;
  final Color? yinColor;
  final Color? yangColor;
  final bool showTrigrams;
  final bool showGlow;
  final double rotation;

  const YinYangIllustration({
    super.key,
    this.size = 200,
    this.yinColor,
    this.yangColor,
    this.showTrigrams = true,
    this.showGlow = true,
    this.rotation = 0,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Transform.rotate(
        angle: rotation,
        child: CustomPaint(
          painter: _YinYangPainter(
            yinColor: yinColor ?? const Color(0xFF2D2D2D),
            yangColor: yangColor ?? Colors.white,
            showTrigrams: showTrigrams,
            showGlow: showGlow,
          ),
        ),
      ),
    );
  }
}

class _YinYangPainter extends CustomPainter {
  final Color yinColor;
  final Color yangColor;
  final bool showTrigrams;
  final bool showGlow;

  _YinYangPainter({
    required this.yinColor,
    required this.yangColor,
    required this.showTrigrams,
    required this.showGlow,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.4;

    // 글로우 효과
    if (showGlow) {
      final glowPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.white.withValues(alpha: 0.15),
            Colors.transparent,
          ],
        ).createShader(Rect.fromCircle(center: center, radius: radius * 1.3));
      canvas.drawCircle(center, radius * 1.3, glowPaint);
    }

    final yangPaint = Paint()..color = yangColor.withValues(alpha: 0.9);
    final yinPaint = Paint()..color = yinColor.withValues(alpha: 0.9);
    final smallRadius = radius / 2;

    // 1. 전체 원을 양(흰색)으로 채우기
    canvas.drawCircle(center, radius, yangPaint);

    // 2. Path 기반으로 음(검정) 영역 그리기
    final yinPath = Path();

    // 왼쪽 큰 반원 (닫힌 반원 Path)
    yinPath.moveTo(center.dx, center.dy - radius);
    yinPath.arcToPoint(
      Offset(center.dx, center.dy + radius),
      radius: Radius.circular(radius),
      clockwise: false,
    );
    // 하단 작은 반원 (오른쪽으로 볼록 - 음 영역 추가)
    yinPath.arcToPoint(
      Offset(center.dx, center.dy),
      radius: Radius.circular(smallRadius),
      clockwise: false,
    );
    // 상단 작은 반원 (오른쪽으로 볼록 - 양 영역 빼기)
    yinPath.arcToPoint(
      Offset(center.dx, center.dy - radius),
      radius: Radius.circular(smallRadius),
      clockwise: true,
    );
    yinPath.close();
    canvas.drawPath(yinPath, yinPaint);

    // 3. 음 점 (순수 검정) - 상단 양 영역 안
    final dotRadius = radius * 0.15;
    final yinDotPaint = Paint()..color = const Color(0xFF000000);
    canvas.drawCircle(
      Offset(center.dx, center.dy - smallRadius),
      dotRadius,
      yinDotPaint,
    );

    // 4. 양 점 (순수 흰색) - 하단 음 영역 안
    final yangDotPaint = Paint()..color = const Color(0xFFFFFFFF);
    canvas.drawCircle(
      Offset(center.dx, center.dy + smallRadius),
      dotRadius,
      yangDotPaint,
    );

    // 외곽선 (선택적)
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = Colors.white.withValues(alpha: 0.3);
    canvas.drawCircle(center, radius, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 애니메이션이 있는 음양 일러스트레이션
class AnimatedYinYangIllustration extends StatefulWidget {
  final double size;
  final Color? yinColor;
  final Color? yangColor;
  final bool showTrigrams;
  final bool showGlow;
  final Duration duration;

  const AnimatedYinYangIllustration({
    super.key,
    this.size = 200,
    this.yinColor,
    this.yangColor,
    this.showTrigrams = true,
    this.showGlow = true,
    this.duration = const Duration(seconds: 20),
  });

  @override
  State<AnimatedYinYangIllustration> createState() => _AnimatedYinYangIllustrationState();
}

class _AnimatedYinYangIllustrationState extends State<AnimatedYinYangIllustration>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return YinYangIllustration(
          size: widget.size,
          yinColor: widget.yinColor,
          yangColor: widget.yangColor,
          showTrigrams: widget.showTrigrams,
          showGlow: widget.showGlow,
          rotation: _controller.value * 2 * pi,
        );
      },
    );
  }
}
