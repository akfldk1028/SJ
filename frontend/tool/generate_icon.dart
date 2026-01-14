import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// 달과 별 아이콘을 PNG로 생성하는 스크립트
void main() async {
  // Flutter 엔진 초기화
  WidgetsFlutterBinding.ensureInitialized();

  final sizes = [1024, 512, 192, 144, 96, 72, 48];

  for (final size in sizes) {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    _paintMoonStarsIcon(canvas, Size(size.toDouble(), size.toDouble()));

    final picture = recorder.endRecording();
    final image = await picture.toImage(size, size);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

    if (byteData != null) {
      final file = File('assets/icons/app_icon_${size}x$size.png');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(byteData.buffer.asUint8List());
      print('Generated: ${file.path}');
    }
  }

  print('Done!');
  exit(0);
}

void _paintMoonStarsIcon(Canvas canvas, Size size) {
  // 배경 그라데이션 (밤하늘)
  final bgPaint = Paint()
    ..shader = RadialGradient(
      center: const Alignment(0.3, -0.3),
      radius: 1.2,
      colors: [
        const Color(0xFF2C3E50),
        const Color(0xFF1A1A2E),
        const Color(0xFF0D0D14),
      ],
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
  canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

  final center = Offset(size.width / 2, size.height / 2);

  // 별들 그리기
  final random = Random(42);
  final starPaint = Paint()..color = Colors.white;
  for (int i = 0; i < 20; i++) {
    final x = random.nextDouble() * size.width;
    final y = random.nextDouble() * size.height;
    final starSize = (1 + random.nextDouble() * 2) * (size.width / 140);
    starPaint.color = Colors.white.withOpacity(0.3 + random.nextDouble() * 0.7);
    canvas.drawCircle(Offset(x, y), starSize, starPaint);
  }

  // 초승달
  final moonRadius = size.width * 0.32;
  final moonCenter = Offset(center.dx - 5 * (size.width / 140), center.dy);

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
    ..shader = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        const Color(0xFFF5E6CA),
        const Color(0xFFE8D5A3),
        const Color(0xFFC4A962),
      ],
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

  // 큰 별들 (5각 별)
  final scale = size.width / 140;
  _drawStar(canvas, Offset(center.dx + 35 * scale, center.dy - 25 * scale), 12 * scale, const Color(0xFFC4A962));
  _drawStar(canvas, Offset(center.dx + 20 * scale, center.dy + 30 * scale), 8 * scale, const Color(0xFFE8D5A3));
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
