import 'dart:math';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../../../core/theme/app_theme.dart';

/// 오행(五行) 설명 바텀시트
/// 일반 사용자를 위한 쉬운 설명 제공
class OhengExplanationSheet extends StatelessWidget {
  const OhengExplanationSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 핸들바
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            decoration: BoxDecoration(
              color: theme.textMuted.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // 스크롤 가능한 컨텐츠
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 제목
                  _buildHeader(theme),
                  const SizedBox(height: 24),

                  // 오행이란?
                  _buildWhatIsOheng(theme),
                  const SizedBox(height: 24),

                  // 5가지 원소 카드
                  _buildElementCards(theme),
                  const SizedBox(height: 28),

                  // 상생 관계
                  _buildSangsaeng(theme),
                  const SizedBox(height: 28),

                  // 상극 관계
                  _buildSanggeuk(theme),
                  const SizedBox(height: 24),

                  // 균형의 중요성
                  _buildBalanceSection(theme),

                  // 안전 영역
                  SizedBox(height: MediaQuery.of(context).padding.bottom),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(AppThemeExtension theme) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.primaryColor.withValues(alpha: 0.2),
                theme.accentColor?.withValues(alpha: 0.1) ?? theme.primaryColor.withValues(alpha: 0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.auto_awesome,
            color: theme.primaryColor,
            size: 24,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'saju_chart.ohengExplanationTitle'.tr(),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: theme.textPrimary,
                ),
              ),
              Text(
                'saju_chart.ohengExplanationSubtitle'.tr(),
                style: TextStyle(
                  fontSize: 13,
                  color: theme.textMuted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWhatIsOheng(AppThemeExtension theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.isDark
            ? theme.primaryColor.withValues(alpha: 0.08)
            : theme.backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.primaryColor.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline,
                color: theme.primaryColor, size: 18),
              const SizedBox(width: 8),
              Text(
                'saju_chart.easyUnderstanding'.tr(),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: theme.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'saju_chart.ohengExplanationBody'.tr(),
            style: TextStyle(
              fontSize: 14,
              height: 1.7,
              color: theme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildElementCards(AppThemeExtension theme) {
    final elements = [
      {
        'name': 'saju_chart.elementWoodHanjaLabel'.tr(),
        'korean': 'saju_chart.elementWoodName'.tr(),
        'color': theme.woodColor ?? const Color(0xFF4CAF50),
        'emoji': '🌳',
        'meaning': 'saju_chart.elementWoodMeaning'.tr(),
      },
      {
        'name': 'saju_chart.elementFireHanjaLabel'.tr(),
        'korean': 'saju_chart.elementFireName'.tr(),
        'color': theme.fireColor ?? const Color(0xFFE53935),
        'emoji': '🔥',
        'meaning': 'saju_chart.elementFireMeaning'.tr(),
      },
      {
        'name': 'saju_chart.elementEarthHanjaLabel'.tr(),
        'korean': 'saju_chart.elementEarthName'.tr(),
        'color': theme.earthColor ?? const Color(0xFFD4A574),
        'emoji': '🏔️',
        'meaning': 'saju_chart.elementEarthMeaning'.tr(),
      },
      {
        'name': 'saju_chart.elementMetalHanjaLabel'.tr(),
        'korean': 'saju_chart.elementMetalName'.tr(),
        'color': theme.metalColor ?? const Color(0xFF9E9E9E),
        'emoji': '⚔️',
        'meaning': 'saju_chart.elementMetalMeaning'.tr(),
      },
      {
        'name': 'saju_chart.elementWaterHanjaLabel'.tr(),
        'korean': 'saju_chart.elementWaterName'.tr(),
        'color': theme.waterColor ?? const Color(0xFF2196F3),
        'emoji': '💧',
        'meaning': 'saju_chart.elementWaterMeaning'.tr(),
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'saju_chart.fiveElementsTitle'.tr(),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: theme.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: elements.map((e) => _buildElementChip(
            theme,
            e['name'] as String,
            e['korean'] as String,
            e['color'] as Color,
            e['emoji'] as String,
            e['meaning'] as String,
          )).toList(),
        ),
      ],
    );
  }

  Widget _buildElementChip(
    AppThemeExtension theme,
    String name,
    String korean,
    Color color,
    String emoji,
    String meaning,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              Text(
                meaning,
                style: TextStyle(
                  fontSize: 13,
                  color: theme.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSangsaeng(AppThemeExtension theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF4CAF50).withValues(alpha: 0.1),
            const Color(0xFF2196F3).withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.favorite,
                  color: Color(0xFF4CAF50),
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'saju_chart.sangsaengTitle'.tr(),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: theme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 상생 다이어그램
          Center(
            child: SizedBox(
              height: 200,
              width: 200,
              child: CustomPaint(
                painter: _SangsaengDiagramPainter(theme: theme),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 상생 설명
          _buildRelationItem(theme, 'saju_chart.sangsaeng_mokHwa'.tr(), 'saju_chart.sangsaeng_mokHwa_arrow'.tr(), 'saju_chart.sangsaeng_mokHwa_desc'.tr(), const Color(0xFF4CAF50)),
          _buildRelationItem(theme, 'saju_chart.sangsaeng_hwaTo'.tr(), 'saju_chart.sangsaeng_hwaTo_arrow'.tr(), 'saju_chart.sangsaeng_hwaTo_desc'.tr(), const Color(0xFFE53935)),
          _buildRelationItem(theme, 'saju_chart.sangsaeng_toGeum'.tr(), 'saju_chart.sangsaeng_toGeum_arrow'.tr(), 'saju_chart.sangsaeng_toGeum_desc'.tr(), const Color(0xFFD4A574)),
          _buildRelationItem(theme, 'saju_chart.sangsaeng_geumSu'.tr(), 'saju_chart.sangsaeng_geumSu_arrow'.tr(), 'saju_chart.sangsaeng_geumSu_desc'.tr(), const Color(0xFF9E9E9E)),
          _buildRelationItem(theme, 'saju_chart.sangsaeng_suMok'.tr(), 'saju_chart.sangsaeng_suMok_arrow'.tr(), 'saju_chart.sangsaeng_suMok_desc'.tr(), const Color(0xFF2196F3)),
        ],
      ),
    );
  }

  Widget _buildSanggeuk(AppThemeExtension theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFE53935).withValues(alpha: 0.1),
            const Color(0xFFFF9800).withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFE53935).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.flash_on,
                  color: Color(0xFFE53935),
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'saju_chart.sanggeukTitle'.tr(),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: theme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 상극 다이어그램
          Center(
            child: SizedBox(
              height: 200,
              width: 200,
              child: CustomPaint(
                painter: _SanggeukDiagramPainter(theme: theme),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 상극 설명
          _buildRelationItem(theme, 'saju_chart.sanggeuk_hwaGeum'.tr(), 'saju_chart.sanggeuk_hwaGeum_arrow'.tr(), 'saju_chart.sanggeuk_hwaGeum_desc'.tr(), const Color(0xFFE53935)),
          _buildRelationItem(theme, 'saju_chart.sanggeuk_geumMok'.tr(), 'saju_chart.sanggeuk_geumMok_arrow'.tr(), 'saju_chart.sanggeuk_geumMok_desc'.tr(), const Color(0xFF9E9E9E)),
          _buildRelationItem(theme, 'saju_chart.sanggeuk_mokTo'.tr(), 'saju_chart.sanggeuk_mokTo_arrow'.tr(), 'saju_chart.sanggeuk_mokTo_desc'.tr(), const Color(0xFF4CAF50)),
          _buildRelationItem(theme, 'saju_chart.sanggeuk_toSu'.tr(), 'saju_chart.sanggeuk_toSu_arrow'.tr(), 'saju_chart.sanggeuk_toSu_desc'.tr(), const Color(0xFFD4A574)),
          _buildRelationItem(theme, 'saju_chart.sanggeuk_suHwa'.tr(), 'saju_chart.sanggeuk_suHwa_arrow'.tr(), 'saju_chart.sanggeuk_suHwa_desc'.tr(), const Color(0xFF2196F3)),
        ],
      ),
    );
  }

  Widget _buildRelationItem(
    AppThemeExtension theme,
    String term,
    String arrow,
    String explanation,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(top: 6),
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: 13,
                  color: theme.textSecondary,
                  height: 1.5,
                ),
                children: [
                  TextSpan(
                    text: '$term ',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                  TextSpan(text: '($arrow): $explanation'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceSection(AppThemeExtension theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.isDark
            ? theme.primaryColor.withValues(alpha: 0.08)
            : theme.backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.primaryColor.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.balance, color: theme.primaryColor, size: 18),
              const SizedBox(width: 8),
              Text(
                'saju_chart.balanceImportant'.tr(),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: theme.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'saju_chart.balanceExplanation'.tr(),
            style: TextStyle(
              fontSize: 14,
              height: 1.7,
              color: theme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// 상생 순환 다이어그램 페인터
class _SangsaengDiagramPainter extends CustomPainter {
  final AppThemeExtension theme;

  _SangsaengDiagramPainter({required this.theme});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 30;

    final colors = [
      theme.woodColor ?? const Color(0xFF4CAF50),
      theme.fireColor ?? const Color(0xFFE53935),
      theme.earthColor ?? const Color(0xFFD4A574),
      theme.metalColor ?? const Color(0xFF9E9E9E),
      theme.waterColor ?? const Color(0xFF2196F3),
    ];
    final labels = ['木', '火', '土', '金', '水'];

    // 원소 위치 계산 (시계방향, 위에서 시작)
    final points = <Offset>[];
    for (int i = 0; i < 5; i++) {
      final angle = -pi / 2 + (2 * pi * i / 5);
      points.add(Offset(
        center.dx + radius * cos(angle),
        center.dy + radius * sin(angle),
      ));
    }

    // 상생 화살표 그리기 (순환)
    final arrowPaint = Paint()
      ..color = const Color(0xFF4CAF50).withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (int i = 0; i < 5; i++) {
      final start = points[i];
      final end = points[(i + 1) % 5];
      _drawArrow(canvas, start, end, arrowPaint, colors[i]);
    }

    // 원소 원 그리기
    for (int i = 0; i < 5; i++) {
      // 배경 원
      final bgPaint = Paint()
        ..color = colors[i].withValues(alpha: 0.2)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(points[i], 22, bgPaint);

      // 테두리
      final borderPaint = Paint()
        ..color = colors[i]
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawCircle(points[i], 22, borderPaint);

      // 라벨
      final textPainter = TextPainter(
        text: TextSpan(
          text: labels[i],
          style: TextStyle(
            color: colors[i],
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(points[i].dx - textPainter.width / 2,
               points[i].dy - textPainter.height / 2),
      );
    }
  }

  void _drawArrow(Canvas canvas, Offset start, Offset end, Paint paint, Color color) {
    // 시작점과 끝점 조정 (원 안쪽으로)
    final direction = (end - start).direction;
    final adjustedStart = Offset(
      start.dx + 26 * cos(direction),
      start.dy + 26 * sin(direction),
    );
    final adjustedEnd = Offset(
      end.dx - 26 * cos(direction),
      end.dy - 26 * sin(direction),
    );

    // 곡선 경로
    final path = Path();
    final controlPoint = Offset(
      (adjustedStart.dx + adjustedEnd.dx) / 2 + 15 * cos(direction + pi / 2),
      (adjustedStart.dy + adjustedEnd.dy) / 2 + 15 * sin(direction + pi / 2),
    );

    path.moveTo(adjustedStart.dx, adjustedStart.dy);
    path.quadraticBezierTo(
      controlPoint.dx, controlPoint.dy,
      adjustedEnd.dx, adjustedEnd.dy,
    );

    final arrowPaint = Paint()
      ..color = color.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawPath(path, arrowPaint);

    // 화살촉
    final arrowHeadSize = 8.0;
    final arrowAngle = atan2(adjustedEnd.dy - controlPoint.dy, adjustedEnd.dx - controlPoint.dx);

    final arrowPath = Path();
    arrowPath.moveTo(adjustedEnd.dx, adjustedEnd.dy);
    arrowPath.lineTo(
      adjustedEnd.dx - arrowHeadSize * cos(arrowAngle - pi / 6),
      adjustedEnd.dy - arrowHeadSize * sin(arrowAngle - pi / 6),
    );
    arrowPath.moveTo(adjustedEnd.dx, adjustedEnd.dy);
    arrowPath.lineTo(
      adjustedEnd.dx - arrowHeadSize * cos(arrowAngle + pi / 6),
      adjustedEnd.dy - arrowHeadSize * sin(arrowAngle + pi / 6),
    );

    final headPaint = Paint()
      ..color = color.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(arrowPath, headPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 상극 별 다이어그램 페인터
class _SanggeukDiagramPainter extends CustomPainter {
  final AppThemeExtension theme;

  _SanggeukDiagramPainter({required this.theme});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 30;

    final colors = [
      theme.woodColor ?? const Color(0xFF4CAF50),
      theme.fireColor ?? const Color(0xFFE53935),
      theme.earthColor ?? const Color(0xFFD4A574),
      theme.metalColor ?? const Color(0xFF9E9E9E),
      theme.waterColor ?? const Color(0xFF2196F3),
    ];
    final labels = ['木', '火', '土', '金', '水'];

    // 원소 위치 계산
    final points = <Offset>[];
    for (int i = 0; i < 5; i++) {
      final angle = -pi / 2 + (2 * pi * i / 5);
      points.add(Offset(
        center.dx + radius * cos(angle),
        center.dy + radius * sin(angle),
      ));
    }

    // 상극 화살표 그리기 (별 모양: 0→2→4→1→3→0)
    // 화→금, 금→목, 목→토, 토→수, 수→화
    final sanggeukOrder = [1, 3, 0, 2, 4]; // 화, 금, 목, 토, 수

    for (int i = 0; i < 5; i++) {
      final fromIdx = sanggeukOrder[i];
      final toIdx = sanggeukOrder[(i + 1) % 5];
      _drawArrow(canvas, points[fromIdx], points[toIdx], colors[fromIdx]);
    }

    // 원소 원 그리기
    for (int i = 0; i < 5; i++) {
      final bgPaint = Paint()
        ..color = colors[i].withValues(alpha: 0.2)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(points[i], 22, bgPaint);

      final borderPaint = Paint()
        ..color = colors[i]
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawCircle(points[i], 22, borderPaint);

      final textPainter = TextPainter(
        text: TextSpan(
          text: labels[i],
          style: TextStyle(
            color: colors[i],
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(points[i].dx - textPainter.width / 2,
               points[i].dy - textPainter.height / 2),
      );
    }
  }

  void _drawArrow(Canvas canvas, Offset start, Offset end, Color color) {
    final direction = (end - start).direction;
    final adjustedStart = Offset(
      start.dx + 26 * cos(direction),
      start.dy + 26 * sin(direction),
    );
    final adjustedEnd = Offset(
      end.dx - 26 * cos(direction),
      end.dy - 26 * sin(direction),
    );

    // 직선
    final linePaint = Paint()
      ..color = color.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawLine(adjustedStart, adjustedEnd, linePaint);

    // 화살촉
    final arrowHeadSize = 8.0;
    final arrowAngle = direction;

    final arrowPath = Path();
    arrowPath.moveTo(adjustedEnd.dx, adjustedEnd.dy);
    arrowPath.lineTo(
      adjustedEnd.dx - arrowHeadSize * cos(arrowAngle - pi / 6),
      adjustedEnd.dy - arrowHeadSize * sin(arrowAngle - pi / 6),
    );
    arrowPath.moveTo(adjustedEnd.dx, adjustedEnd.dy);
    arrowPath.lineTo(
      adjustedEnd.dx - arrowHeadSize * cos(arrowAngle + pi / 6),
      adjustedEnd.dy - arrowHeadSize * sin(arrowAngle + pi / 6),
    );

    final headPaint = Paint()
      ..color = color.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(arrowPath, headPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 바텀시트 표시 헬퍼 함수
void showOhengExplanation(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const OhengExplanationSheet(),
  );
}
