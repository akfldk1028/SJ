import 'dart:math';
import 'package:flutter/material.dart';

/// 떠다니는 요소들 (별, 입자 등)
/// 배경에 은은하게 애니메이션되는 요소들
class FloatingElements extends StatefulWidget {
  final int particleCount;
  final Color? particleColor;
  final double maxSize;
  final Widget? child;

  const FloatingElements({
    super.key,
    this.particleCount = 20,
    this.particleColor,
    this.maxSize = 4,
    this.child,
  });

  @override
  State<FloatingElements> createState() => _FloatingElementsState();
}

class _FloatingElementsState extends State<FloatingElements>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<_Particle> _particles;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat();

    final random = Random();
    _particles = List.generate(widget.particleCount, (index) {
      return _Particle(
        x: random.nextDouble(),
        y: random.nextDouble(),
        size: 1 + random.nextDouble() * widget.maxSize,
        speed: 0.1 + random.nextDouble() * 0.3,
        opacity: 0.1 + random.nextDouble() * 0.5,
        phase: random.nextDouble() * 2 * pi,
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        if (widget.child != null) widget.child!,
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return CustomPaint(
                painter: _FloatingPainter(
                  particles: _particles,
                  progress: _controller.value,
                  color: widget.particleColor ?? Colors.white,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _Particle {
  final double x;
  final double y;
  final double size;
  final double speed;
  final double opacity;
  final double phase;

  _Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.opacity,
    required this.phase,
  });
}

class _FloatingPainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;
  final Color color;

  _FloatingPainter({
    required this.particles,
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in particles) {
      // 부드러운 상하 움직임
      final yOffset = sin(progress * 2 * pi * particle.speed + particle.phase) * 0.02;
      final xOffset = cos(progress * 2 * pi * particle.speed * 0.5 + particle.phase) * 0.01;

      final x = (particle.x + xOffset) * size.width;
      final y = ((particle.y + yOffset) % 1.0) * size.height;

      // 깜빡이는 효과
      final flicker = 0.5 + 0.5 * sin(progress * 4 * pi + particle.phase);
      final opacity = particle.opacity * flicker;

      final paint = Paint()
        ..color = color.withValues(alpha: opacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1);

      canvas.drawCircle(Offset(x, y), particle.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _FloatingPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

/// 떠다니는 한자/기호들
class FloatingSymbols extends StatefulWidget {
  final List<String> symbols;
  final double fontSize;
  final Color? color;
  final Widget? child;

  const FloatingSymbols({
    super.key,
    this.symbols = const ['木', '火', '土', '金', '水', '陽', '陰', '天', '地'],
    this.fontSize = 24,
    this.color,
    this.child,
  });

  @override
  State<FloatingSymbols> createState() => _FloatingSymbolsState();
}

class _FloatingSymbolsState extends State<FloatingSymbols>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<_SymbolData> _symbolData;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 15),
      vsync: this,
    )..repeat();

    final random = Random();
    _symbolData = List.generate(widget.symbols.length, (index) {
      return _SymbolData(
        symbol: widget.symbols[index],
        x: random.nextDouble(),
        y: random.nextDouble(),
        opacity: 0.05 + random.nextDouble() * 0.1,
        speed: 0.05 + random.nextDouble() * 0.1,
        phase: random.nextDouble() * 2 * pi,
        scale: 0.8 + random.nextDouble() * 0.4,
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        if (widget.child != null) widget.child!,
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Stack(
              children: _symbolData.map((data) {
                final yOffset = sin(_controller.value * 2 * pi * data.speed + data.phase) * 30;
                final rotation = sin(_controller.value * 2 * pi * data.speed * 0.5 + data.phase) * 0.1;
                final opacity = data.opacity * (0.7 + 0.3 * sin(_controller.value * 4 * pi + data.phase));

                return Positioned(
                  left: data.x * MediaQuery.of(context).size.width,
                  top: data.y * MediaQuery.of(context).size.height + yOffset,
                  child: Transform.rotate(
                    angle: rotation,
                    child: Transform.scale(
                      scale: data.scale,
                      child: Text(
                        data.symbol,
                        style: TextStyle(
                          fontSize: widget.fontSize,
                          color: (widget.color ?? Colors.white).withValues(alpha: opacity),
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}

class _SymbolData {
  final String symbol;
  final double x;
  final double y;
  final double opacity;
  final double speed;
  final double phase;
  final double scale;

  _SymbolData({
    required this.symbol,
    required this.x,
    required this.y,
    required this.opacity,
    required this.speed,
    required this.phase,
    required this.scale,
  });
}
