import 'dart:math';
import 'package:flutter/material.dart';

/// 오행 기반 그라데이션 배경
///
/// 동물의 천간 오행에 따라 색상이 변하는 신비로운 배경.
/// 떠다니는 파티클과 그라데이션으로 시각적 임팩트.
class ZodiacElementBackground extends StatefulWidget {
  final Widget child;

  /// 오행 이름 (목/화/토/금/수)
  final String elementName;

  /// 전환 애니메이션 시간
  final Duration transitionDuration;

  const ZodiacElementBackground({
    super.key,
    required this.child,
    this.elementName = '화',
    this.transitionDuration = const Duration(milliseconds: 800),
  });

  @override
  State<ZodiacElementBackground> createState() =>
      _ZodiacElementBackgroundState();
}

class _ZodiacElementBackgroundState extends State<ZodiacElementBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _particleController;

  @override
  void initState() {
    super.initState();
    _particleController = AnimationController(
      duration: const Duration(seconds: 6),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = _getElementColors(widget.elementName);

    return AnimatedContainer(
      duration: widget.transitionDuration,
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
      ),
      child: Stack(
        children: [
          // 떠다니는 빛 파티클
          ...List.generate(5, (i) => _FloatingOrb(
            controller: _particleController,
            index: i,
            color: colors[1].withAlpha(40),
          )),
          // 메인 콘텐츠
          widget.child,
        ],
      ),
    );
  }

  List<Color> _getElementColors(String element) {
    switch (element) {
      case '목':
        return const [Color(0xFF0D1B0E), Color(0xFF1B5E20), Color(0xFF2E7D32), Color(0xFF0D1B0E)];
      case '화':
        return const [Color(0xFF1A0A0A), Color(0xFFB71C1C), Color(0xFFE65100), Color(0xFF1A0A0A)];
      case '토':
        return const [Color(0xFF1A1400), Color(0xFFE65100), Color(0xFFF9A825), Color(0xFF1A1400)];
      case '금':
        return const [Color(0xFF0A0A12), Color(0xFF37474F), Color(0xFF78909C), Color(0xFF0A0A12)];
      case '수':
        return const [Color(0xFF000A12), Color(0xFF0D47A1), Color(0xFF1565C0), Color(0xFF000A12)];
      default:
        return const [Color(0xFF0F0F1A), Color(0xFF1A1A2E), Color(0xFF16213E), Color(0xFF0F0F1A)];
    }
  }
}

/// 떠다니는 빛 파티클
class _FloatingOrb extends StatelessWidget {
  final AnimationController controller;
  final int index;
  final Color color;

  const _FloatingOrb({
    required this.controller,
    required this.index,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final random = Random(index * 42);
    final size = 80.0 + random.nextDouble() * 120;
    final startX = random.nextDouble();
    final startY = random.nextDouble();

    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final t = (controller.value + index * 0.2) % 1.0;
        final dx = sin(t * 2 * pi) * 30;
        final dy = cos(t * 2 * pi * 0.7) * 20;

        return Positioned(
          left: MediaQuery.of(context).size.width * startX + dx,
          top: MediaQuery.of(context).size.height * startY + dy,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [color, color.withAlpha(0)],
              ),
            ),
          ),
        );
      },
    );
  }
}
