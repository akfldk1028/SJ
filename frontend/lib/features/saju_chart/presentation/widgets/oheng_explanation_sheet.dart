import 'dart:math';
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
                '오행(五行)이란?',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: theme.textPrimary,
                ),
              ),
              Text(
                '사주의 기본 원리를 쉽게 알아보세요',
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
                '쉽게 이해하기',
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
            '오행(五行)은 우주 만물의 변화를 다섯 가지 기운으로 설명하는 동양 철학입니다.\n\n'
            '나무(木), 불(火), 흙(土), 쇠(金), 물(水) - 이 다섯 가지가 서로 '
            '도와주기도 하고(상생), 억제하기도 하면서(상극) 자연의 균형을 이룹니다.',
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
        'name': '목(木)',
        'korean': '나무',
        'color': theme.woodColor ?? const Color(0xFF4CAF50),
        'emoji': '🌳',
        'meaning': '성장, 발전, 인자함',
      },
      {
        'name': '화(火)',
        'korean': '불',
        'color': theme.fireColor ?? const Color(0xFFE53935),
        'emoji': '🔥',
        'meaning': '열정, 예의, 따뜻함',
      },
      {
        'name': '토(土)',
        'korean': '흙',
        'color': theme.earthColor ?? const Color(0xFFD4A574),
        'emoji': '🏔️',
        'meaning': '중심, 신뢰, 포용력',
      },
      {
        'name': '금(金)',
        'korean': '쇠',
        'color': theme.metalColor ?? const Color(0xFF9E9E9E),
        'emoji': '⚔️',
        'meaning': '결단력, 의리, 정의',
      },
      {
        'name': '수(水)',
        'korean': '물',
        'color': theme.waterColor ?? const Color(0xFF2196F3),
        'emoji': '💧',
        'meaning': '지혜, 유연함, 소통',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '다섯 가지 원소',
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
                  fontSize: 10,
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
                '상생(相生) - 서로 도와주는 관계',
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
          _buildRelationItem(theme, '목생화', '나무 → 불', '나무가 타서 불을 일으킨다', const Color(0xFF4CAF50)),
          _buildRelationItem(theme, '화생토', '불 → 흙', '불이 타고 나면 재(흙)가 된다', const Color(0xFFE53935)),
          _buildRelationItem(theme, '토생금', '흙 → 쇠', '흙 속에서 광물(쇠)이 나온다', const Color(0xFFD4A574)),
          _buildRelationItem(theme, '금생수', '쇠 → 물', '쇠가 차가워지면 이슬(물)이 맺힌다', const Color(0xFF9E9E9E)),
          _buildRelationItem(theme, '수생목', '물 → 나무', '물이 나무를 자라게 한다', const Color(0xFF2196F3)),
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
                '상극(相剋) - 서로 억제하는 관계',
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
          _buildRelationItem(theme, '화극금', '불 → 쇠', '불의 열기가 쇠를 녹인다', const Color(0xFFE53935)),
          _buildRelationItem(theme, '금극목', '쇠 → 나무', '쇠(도끼)가 나무를 베어낸다', const Color(0xFF9E9E9E)),
          _buildRelationItem(theme, '목극토', '나무 → 흙', '나무가 흙의 기운을 빼앗는다', const Color(0xFF4CAF50)),
          _buildRelationItem(theme, '토극수', '흙 → 물', '흙이 물을 막고 흡수한다', const Color(0xFFD4A574)),
          _buildRelationItem(theme, '수극화', '물 → 불', '물이 불을 꺼버린다', const Color(0xFF2196F3)),
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
                '균형이 중요해요!',
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
            '상생과 상극은 좋고 나쁨이 아니에요. 오행이 서로 도와주고 '
            '억제하며 균형을 이룰 때 가장 이상적입니다.\n\n'
            '내 사주에 어떤 오행이 많고 적은지 파악하면, '
            '보완할 부분을 알 수 있어요.',
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
