import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:io';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/mystic_background.dart';

/// 앱 아이콘 생성기 화면
class IconGeneratorScreen extends StatefulWidget {
  const IconGeneratorScreen({super.key});

  @override
  State<IconGeneratorScreen> createState() => _IconGeneratorScreenState();
}

class _IconGeneratorScreenState extends State<IconGeneratorScreen> {
  final List<GlobalKey> _iconKeys = List.generate(4, (_) => GlobalKey());

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('앱 아이콘 선택', style: TextStyle(color: theme.textPrimary)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: MysticBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Text(
                  '앱 아이콘 디자인 선택',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: theme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '원하는 디자인을 탭하여 저장하세요',
                  style: TextStyle(fontSize: 14, color: theme.textMuted),
                ),
                const SizedBox(height: 32),

                // 2x2 그리드
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 24,
                  crossAxisSpacing: 24,
                  childAspectRatio: 0.8,
                  children: [
                    _buildIconOption(
                      context,
                      key: _iconKeys[0],
                      title: '태극 문양',
                      subtitle: '현대적 음양 디자인',
                      child: const TaegeukIcon(),
                    ),
                    _buildIconOption(
                      context,
                      key: _iconKeys[1],
                      title: '달과 별',
                      subtitle: '신비로운 운세 느낌',
                      child: const MoonStarsIcon(),
                    ),
                    _buildIconOption(
                      context,
                      key: _iconKeys[2],
                      title: '한자 운(運)',
                      subtitle: '동양풍 문자 디자인',
                      child: const HanjaIcon(),
                    ),
                    _buildIconOption(
                      context,
                      key: _iconKeys[3],
                      title: '연꽃',
                      subtitle: '평화로운 느낌',
                      child: const LotusIcon(),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIconOption(
    BuildContext context, {
    required GlobalKey key,
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    final theme = context.appTheme;

    return GestureDetector(
      onTap: () => _saveIcon(key, title),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: theme.primaryColor.withValues(alpha: 0.2),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: RepaintBoundary(
              key: key,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: SizedBox(
                  width: 140,
                  height: 140,
                  child: child,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: theme.textPrimary,
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: theme.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveIcon(GlobalKey key, String name) async {
    final theme = context.appTheme;

    try {
      final boundary = key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 8.0); // 1024px for high quality
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/app_icon_$name.png';
      final file = File(filePath);
      await file.writeAsBytes(byteData.buffer.asUint8List());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('아이콘 저장됨: $filePath'),
            backgroundColor: theme.primaryColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('저장 실패: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

/// 1. 태극 문양 아이콘
class TaegeukIcon extends StatelessWidget {
  const TaegeukIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _TaegeukPainter(),
      size: const Size(140, 140),
    );
  }
}

class _TaegeukPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.42;

    // 배경 그라데이션
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // 외곽 원 (골드 테두리)
    final borderPaint = Paint()
      ..color = const Color(0xFFC4A962)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(center, radius + 6, borderPaint);

    // 태극 - 빨간 부분 (상단)
    final redPath = Path();
    redPath.addArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      pi,
    );
    redPath.addArc(
      Rect.fromCircle(center: Offset(center.dx, center.dy - radius / 2), radius: radius / 2),
      pi / 2,
      pi,
    );
    redPath.addArc(
      Rect.fromCircle(center: Offset(center.dx, center.dy + radius / 2), radius: radius / 2),
      -pi / 2,
      pi,
    );

    final redPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFE74C3C), Color(0xFFC0392B)],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawPath(redPath, redPaint);

    // 태극 - 파란 부분 (하단)
    final bluePath = Path();
    bluePath.addArc(
      Rect.fromCircle(center: center, radius: radius),
      pi / 2,
      pi,
    );
    bluePath.addArc(
      Rect.fromCircle(center: Offset(center.dx, center.dy + radius / 2), radius: radius / 2),
      -pi / 2,
      -pi,
    );
    bluePath.addArc(
      Rect.fromCircle(center: Offset(center.dx, center.dy - radius / 2), radius: radius / 2),
      pi / 2,
      -pi,
    );

    final bluePaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF3498DB), Color(0xFF2980B9)],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawPath(bluePath, bluePaint);

    // 작은 점 (음양)
    canvas.drawCircle(
      Offset(center.dx, center.dy - radius / 2),
      radius * 0.12,
      Paint()..color = const Color(0xFF2980B9),
    );
    canvas.drawCircle(
      Offset(center.dx, center.dy + radius / 2),
      radius * 0.12,
      Paint()..color = const Color(0xFFC0392B),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 2. 달과 별 아이콘
class MoonStarsIcon extends StatelessWidget {
  const MoonStarsIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _MoonStarsPainter(),
      size: const Size(140, 140),
    );
  }
}

class _MoonStarsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // 배경 그라데이션 (밤하늘)
    final bgPaint = Paint()
      ..shader = const RadialGradient(
        center: Alignment(0.3, -0.3),
        radius: 1.2,
        colors: [Color(0xFF2C3E50), Color(0xFF1A1A2E), Color(0xFF0D0D14)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    final center = Offset(size.width / 2, size.height / 2);

    // 별들 그리기
    final random = Random(42);
    final starPaint = Paint()..color = Colors.white;
    for (int i = 0; i < 20; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final starSize = 1 + random.nextDouble() * 2;
      starPaint.color = Colors.white.withOpacity(0.3 + random.nextDouble() * 0.7);
      canvas.drawCircle(Offset(x, y), starSize, starPaint);
    }

    // 초승달
    final moonRadius = size.width * 0.32;
    final moonCenter = Offset(center.dx - 5, center.dy);

    final outerMoon = Path()
      ..addOval(Rect.fromCircle(center: moonCenter, radius: moonRadius));
    final innerMoon = Path()
      ..addOval(Rect.fromCircle(
        center: Offset(moonCenter.dx + moonRadius * 0.5, moonCenter.dy),
        radius: moonRadius * 0.85,
      ));
    final crescentPath = Path.combine(PathOperation.difference, outerMoon, innerMoon);

    // 달 그라데이션
    final moonPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFF5E6CA), Color(0xFFE8D5A3), Color(0xFFC4A962)],
      ).createShader(Rect.fromCircle(center: moonCenter, radius: moonRadius));
    canvas.drawPath(crescentPath, moonPaint);

    // 달 글로우
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFC4A962).withOpacity(0.3),
          const Color(0xFFC4A962).withOpacity(0),
        ],
      ).createShader(Rect.fromCircle(center: moonCenter, radius: moonRadius * 1.5));
    canvas.drawCircle(moonCenter, moonRadius * 1.3, glowPaint);

    // 큰 별 하나 (5각 별)
    _drawStar(canvas, Offset(center.dx + 35, center.dy - 25), 12, const Color(0xFFC4A962));
    _drawStar(canvas, Offset(center.dx + 20, center.dy + 30), 8, const Color(0xFFE8D5A3));
  }

  void _drawStar(Canvas canvas, Offset center, double size, Color color) {
    final path = Path();
    for (int i = 0; i < 5; i++) {
      final angle = (i * 4 * pi / 5) - pi / 2;
      final point = Offset(
        center.dx + size * cos(angle),
        center.dy + size * sin(angle),
      );
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();

    canvas.drawPath(path, Paint()..color = color);

    // 글로우
    canvas.drawPath(
      path,
      Paint()
        ..color = color.withOpacity(0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 3. 한자 운(運) 아이콘
class HanjaIcon extends StatelessWidget {
  const HanjaIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _HanjaPainter(),
      size: const Size(140, 140),
    );
  }
}

class _HanjaPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // 배경 그라데이션
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF2D1F1F), Color(0xFF1A1212)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    final center = Offset(size.width / 2, size.height / 2);

    // 원형 테두리
    final borderPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFD4A574), Color(0xFFC4A962), Color(0xFFB8860B)],
      ).createShader(Rect.fromCircle(center: center, radius: size.width * 0.45))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    canvas.drawCircle(center, size.width * 0.42, borderPaint);

    // 배경 원
    final circleBg = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFC4A962).withOpacity(0.15),
          const Color(0xFFC4A962).withOpacity(0.05),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: size.width * 0.4));
    canvas.drawCircle(center, size.width * 0.38, circleBg);

    // 한자 "運" 그리기
    final textPainter = TextPainter(
      text: const TextSpan(
        text: '運',
        style: TextStyle(
          fontSize: 70,
          fontWeight: FontWeight.w400,
          color: Color(0xFFC4A962),
          fontFamily: 'NotoSerifKR',
          shadows: [
            Shadow(
              color: Color(0x80C4A962),
              blurRadius: 8,
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        center.dx - textPainter.width / 2,
        center.dy - textPainter.height / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 4. 연꽃 아이콘
class LotusIcon extends StatelessWidget {
  const LotusIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _LotusPainter(),
      size: const Size(140, 140),
    );
  }
}

class _LotusPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // 배경 그라데이션
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF1A2634), Color(0xFF0D141C)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    final center = Offset(size.width / 2, size.height / 2 + 5);

    // 글로우 효과
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFE8B4B8).withOpacity(0.3),
          const Color(0xFFE8B4B8).withOpacity(0),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: size.width * 0.5));
    canvas.drawCircle(center, size.width * 0.45, glowPaint);

    // 연꽃잎 그리기
    _drawPetals(canvas, center, size.width * 0.35);

    // 중앙 원 (꽃술)
    final centerPaint = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0xFFFFD700), Color(0xFFC4A962)],
      ).createShader(Rect.fromCircle(center: center, radius: 12));
    canvas.drawCircle(center, 10, centerPaint);
  }

  void _drawPetals(Canvas canvas, Offset center, double petalLength) {
    // 뒤쪽 꽃잎 (연한 색)
    for (int i = 0; i < 8; i++) {
      final angle = (i * pi / 4) + pi / 8;
      _drawPetal(
        canvas,
        center,
        angle,
        petalLength * 0.9,
        const Color(0xFFD4A5A8),
        0.6,
      );
    }

    // 앞쪽 꽃잎 (진한 색)
    for (int i = 0; i < 8; i++) {
      final angle = i * pi / 4;
      _drawPetal(
        canvas,
        center,
        angle,
        petalLength,
        const Color(0xFFE8B4B8),
        0.8,
      );
    }
  }

  void _drawPetal(Canvas canvas, Offset center, double angle, double length, Color color, double opacity) {
    final path = Path();
    final tipX = center.dx + length * cos(angle - pi / 2);
    final tipY = center.dy + length * sin(angle - pi / 2);

    final controlDist = length * 0.6;
    final width = length * 0.4;

    path.moveTo(center.dx, center.dy);
    path.quadraticBezierTo(
      center.dx + controlDist * cos(angle - pi / 2 - 0.3),
      center.dy + controlDist * sin(angle - pi / 2 - 0.3),
      tipX,
      tipY,
    );
    path.quadraticBezierTo(
      center.dx + controlDist * cos(angle - pi / 2 + 0.3),
      center.dy + controlDist * sin(angle - pi / 2 + 0.3),
      center.dx,
      center.dy,
    );

    final petalPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          color.withOpacity(opacity),
          color.withOpacity(opacity * 0.7),
        ],
      ).createShader(Rect.fromCenter(center: center, width: length * 2, height: length * 2));
    canvas.drawPath(path, petalPaint);

    // 테두리
    canvas.drawPath(
      path,
      Paint()
        ..color = color.withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
