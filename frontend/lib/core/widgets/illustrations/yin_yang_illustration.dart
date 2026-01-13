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

    // 1. 전체 원을 양(흰색)으로 채우기
    final yangPaint = Paint()..color = yangColor.withValues(alpha: 0.9);
    canvas.drawCircle(center, radius, yangPaint);

    // 2. 왼쪽 반원을 음(검정)으로 채우기
    final yinPaint = Paint()..color = yinColor.withValues(alpha: 0.9);
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(
      center.dx - radius,
      center.dy - radius,
      radius,
      radius * 2,
    ));
    canvas.drawCircle(center, radius, yinPaint);
    canvas.restore();

    // 3. 상단에 작은 양(흰색) 반원
    final smallRadius = radius / 2;
    canvas.drawCircle(
      Offset(center.dx, center.dy - smallRadius),
      smallRadius,
      yangPaint,
    );

    // 4. 하단에 작은 음(검정) 반원
    canvas.drawCircle(
      Offset(center.dx, center.dy + smallRadius),
      smallRadius,
      yinPaint,
    );

    // 5. 상단 양 영역 안에 작은 음 점
    final dotRadius = radius * 0.1;
    canvas.drawCircle(
      Offset(center.dx, center.dy - smallRadius),
      dotRadius,
      yinPaint,
    );

    // 6. 하단 음 영역 안에 작은 양 점
    canvas.drawCircle(
      Offset(center.dx, center.dy + smallRadius),
      dotRadius,
      yangPaint,
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
