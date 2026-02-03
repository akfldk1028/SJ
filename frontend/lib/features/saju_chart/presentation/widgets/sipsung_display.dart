import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/constants/sipsin_relations.dart';

/// 십성(十星) 표시 위젯
/// 일간 기준 천간/지지의 십성을 표시
class SipSungDisplay extends StatelessWidget {
  /// 십성
  final SipSin sipsin;

  /// 크기 (small, medium, large)
  final SipSungSize size;

  /// 배경 표시 여부
  final bool showBackground;

  /// 한자 표시 여부
  final bool showHanja;

  const SipSungDisplay({
    super.key,
    required this.sipsin,
    this.size = SipSungSize.medium,
    this.showBackground = true,
    this.showHanja = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = _getSipSinColor(sipsin);
    final fontSize = _getFontSize();
    final padding = _getPadding();

    if (!showBackground) {
      return Text(
        showHanja ? sipsin.hanja : sipsin.korean,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
        ),
      );
    }

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Text(
        showHanja ? sipsin.hanja : sipsin.korean,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  double _getFontSize() {
    return switch (size) {
      SipSungSize.small => 12.0,
      SipSungSize.medium => 13.0,
      SipSungSize.large => 14.0,
    };
  }

  EdgeInsets _getPadding() {
    return switch (size) {
      SipSungSize.small => const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      SipSungSize.medium => const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      SipSungSize.large => const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    };
  }

  /// 십성별 색상 (카테고리 기반)
  Color _getSipSinColor(SipSin sipsin) {
    final category = sipsinToCategory[sipsin];
    return switch (category) {
      SipSinCategory.bigeop => AppColors.water,    // 비겁: 파랑
      SipSinCategory.siksang => AppColors.wood,    // 식상: 초록
      SipSinCategory.jaeseong => AppColors.earth,  // 재성: 노랑
      SipSinCategory.gwanseong => AppColors.fire,  // 관성: 빨강
      SipSinCategory.inseong => AppColors.metal,   // 인성: 회색
      _ => AppColors.textSecondary,
    };
  }
}

/// 십성 크기 옵션
enum SipSungSize { small, medium, large }

/// 십성 행 (천간 또는 지지 한 줄)
/// 4주 모두의 십성을 한 줄로 표시
class SipSungRow extends StatelessWidget {
  /// 십성 목록 [시주, 일주, 월주, 년주] 순서
  final List<SipSin?> sipsins;

  /// 라벨 (예: "천간 십성", "지지 십성")
  final String? label;

  const SipSungRow({
    super.key,
    required this.sipsins,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    return Row(
      children: [
        if (label != null) ...[
          SizedBox(
            width: 60,
            child: Text(
              label!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: theme.textMuted,
                    fontSize: 13,
                  ),
            ),
          ),
        ],
        ...sipsins.map((sipsin) => Expanded(
              child: Center(
                child: sipsin != null
                    ? SipSungDisplay(
                        sipsin: sipsin,
                        size: SipSungSize.small,
                      )
                    : Text(
                        '-',
                        style: TextStyle(
                          color: theme.textMuted,
                          fontSize: 13,
                        ),
                      ),
              ),
            )),
      ],
    );
  }
}

/// 십성 분포 차트 (막대 그래프)
class SipSungDistributionChart extends StatelessWidget {
  /// 십성별 개수 맵
  final Map<SipSin, int> distribution;

  /// 최대 높이
  final double maxHeight;

  const SipSungDistributionChart({
    super.key,
    required this.distribution,
    this.maxHeight = 100,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    final maxCount = distribution.values.fold<int>(0, (a, b) => a > b ? a : b);
    if (maxCount == 0) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 막대 그래프
        SizedBox(
          height: maxHeight,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: SipSin.values.map((sipsin) {
              final count = distribution[sipsin] ?? 0;
              final height = count > 0 ? (count / maxCount) * maxHeight : 0.0;
              final color = _getSipSinColor(sipsin);

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (count > 0)
                        Text(
                          '$count',
                          style: TextStyle(
                            color: color,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      const SizedBox(height: 2),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        height: height,
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.7),
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 8),
        // 라벨
        Row(
          children: SipSin.values.map((sipsin) {
            return Expanded(
              child: Center(
                child: Text(
                  sipsin.korean.substring(0, 1), // 첫 글자만
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: theme.textMuted,
                        fontSize: 13,
                      ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Color _getSipSinColor(SipSin sipsin) {
    final category = sipsinToCategory[sipsin];
    return switch (category) {
      SipSinCategory.bigeop => AppColors.water,
      SipSinCategory.siksang => AppColors.wood,
      SipSinCategory.jaeseong => AppColors.earth,
      SipSinCategory.gwanseong => AppColors.fire,
      SipSinCategory.inseong => AppColors.metal,
      _ => AppColors.textSecondary,
    };
  }
}

/// 십성 카테고리별 분포 (비겁/식상/재성/관성/인성)
/// 개선된 디자인: 오각형 레이더 차트 + 카드 리스트
class SipSungCategoryChart extends StatelessWidget {
  /// 카테고리별 개수 맵
  final Map<SipSinCategory, int> distribution;

  const SipSungCategoryChart({
    super.key,
    required this.distribution,
  });

  // 카테고리별 색상 정의
  static const _categoryColors = {
    SipSinCategory.bigeop: Color(0xFF2196F3),    // 비겁 - 파랑
    SipSinCategory.siksang: Color(0xFF4CAF50),   // 식상 - 녹색
    SipSinCategory.jaeseong: Color(0xFFFF9800),  // 재성 - 주황
    SipSinCategory.gwanseong: Color(0xFFE53935), // 관성 - 빨강
    SipSinCategory.inseong: Color(0xFF9C27B0),   // 인성 - 보라
  };

  // 카테고리별 아이콘 정의
  static const _categoryIcons = {
    SipSinCategory.bigeop: Icons.people_rounded,         // 비겁 - 사람들
    SipSinCategory.siksang: Icons.restaurant_rounded,    // 식상 - 음식/표현
    SipSinCategory.jaeseong: Icons.attach_money_rounded, // 재성 - 돈
    SipSinCategory.gwanseong: Icons.gavel_rounded,       // 관성 - 권력
    SipSinCategory.inseong: Icons.school_rounded,        // 인성 - 학문
  };

  // 카테고리별 설명
  static const _categoryDescriptions = {
    SipSinCategory.bigeop: '자아, 형제, 경쟁',
    SipSinCategory.siksang: '표현, 재능, 자녀',
    SipSinCategory.jaeseong: '재물, 아버지, 여자',
    SipSinCategory.gwanseong: '명예, 직장, 남자',
    SipSinCategory.inseong: '학문, 어머니, 문서',
  };

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    final total = distribution.values.fold<int>(0, (a, b) => a + b);
    if (total == 0) {
      return const SizedBox.shrink();
    }

    final maxCount = distribution.values.fold<int>(0, (a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.border),
      ),
      child: Column(
        children: [
          // 오각형 레이더 차트
          SizedBox(
            height: 220,
            child: _SipSungRadarChart(
              distribution: distribution,
              maxValue: maxCount > 0 ? maxCount.toDouble() : 4.0,
              colors: _categoryColors,
              theme: theme,
            ),
          ),
          const SizedBox(height: 20),
          // 구분선
          Container(
            height: 1,
            color: theme.border,
          ),
          const SizedBox(height: 16),
          // 카테고리 카드 리스트
          ...SipSinCategory.values.map((category) {
            final count = distribution[category] ?? 0;
            final color = _categoryColors[category]!;
            final icon = _categoryIcons[category]!;
            final description = _categoryDescriptions[category]!;
            final ratio = total > 0 ? count / total : 0.0;

            return _buildCategoryCard(
              context,
              theme: theme,
              category: category,
              count: count,
              ratio: ratio,
              color: color,
              icon: icon,
              description: description,
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(
    BuildContext context, {
    required AppThemeExtension theme,
    required SipSinCategory category,
    required int count,
    required double ratio,
    required Color color,
    required IconData icon,
    required String description,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          // 아이콘
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          // 이름과 설명
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category.korean,
                  style: TextStyle(
                    color: color,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    color: theme.textMuted,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          // 개수와 비율
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$count개',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${(ratio * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                  color: theme.textMuted,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 십성 오각형 레이더 차트
class _SipSungRadarChart extends StatelessWidget {
  final Map<SipSinCategory, int> distribution;
  final double maxValue;
  final Map<SipSinCategory, Color> colors;
  final AppThemeExtension theme;

  const _SipSungRadarChart({
    required this.distribution,
    required this.maxValue,
    required this.colors,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(double.infinity, 220),
      painter: _SipSungRadarPainter(
        values: SipSinCategory.values
            .map((c) => (distribution[c] ?? 0).toDouble())
            .toList(),
        maxValue: maxValue,
        colors: colors,
        textMuted: theme.textMuted,
        textPrimary: theme.textPrimary,
        accentColor: theme.primaryColor,
      ),
    );
  }
}

class _SipSungRadarPainter extends CustomPainter {
  final List<double> values;
  final double maxValue;
  final Map<SipSinCategory, Color> colors;
  final Color textMuted;
  final Color textPrimary;
  final Color accentColor;

  static const labels = ['비겁', '식상', '재성', '관성', '인성'];

  _SipSungRadarPainter({
    required this.values,
    required this.maxValue,
    required this.colors,
    required this.textMuted,
    required this.textPrimary,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.height / 2) - 35;

    final categoryColors = [
      colors[SipSinCategory.bigeop]!,
      colors[SipSinCategory.siksang]!,
      colors[SipSinCategory.jaeseong]!,
      colors[SipSinCategory.gwanseong]!,
      colors[SipSinCategory.inseong]!,
    ];

    // 배경 오각형 (4단계)
    for (int level = 1; level <= 4; level++) {
      final levelRadius = radius * (level / 4);
      final bgPaint = Paint()
        ..color = textMuted.withOpacity(level == 4 ? 0.2 : 0.08)
        ..style = PaintingStyle.stroke
        ..strokeWidth = level == 4 ? 1.5 : 1;
      _drawPentagon(canvas, center, levelRadius, bgPaint);
    }

    // 축선
    final axisPaint = Paint()
      ..color = textMuted.withOpacity(0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (int i = 0; i < 5; i++) {
      final angle = _getAngle(i);
      final endPoint = Offset(
        center.dx + radius * cos(angle),
        center.dy + radius * sin(angle),
      );
      canvas.drawLine(center, endPoint, axisPaint);
    }

    // 데이터 오각형 (그라데이션 효과)
    final dataPath = Path();
    final dataFillPaint = Paint()
      ..color = accentColor.withOpacity(0.2)
      ..style = PaintingStyle.fill;
    final dataStrokePaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    for (int i = 0; i < 5; i++) {
      final angle = _getAngle(i);
      final value = maxValue > 0 ? (values[i] / maxValue).clamp(0.0, 1.0) : 0.0;
      final point = Offset(
        center.dx + radius * value * cos(angle),
        center.dy + radius * value * sin(angle),
      );

      if (i == 0) {
        dataPath.moveTo(point.dx, point.dy);
      } else {
        dataPath.lineTo(point.dx, point.dy);
      }
    }
    dataPath.close();

    canvas.drawPath(dataPath, dataFillPaint);
    canvas.drawPath(dataPath, dataStrokePaint);

    // 포인트와 라벨
    for (int i = 0; i < 5; i++) {
      final angle = _getAngle(i);
      final value = maxValue > 0 ? (values[i] / maxValue).clamp(0.0, 1.0) : 0.0;
      final point = Offset(
        center.dx + radius * value * cos(angle),
        center.dy + radius * value * sin(angle),
      );

      // 포인트 (각 카테고리 색상)
      final pointBgPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      canvas.drawCircle(point, 6, pointBgPaint);

      final pointPaint = Paint()
        ..color = categoryColors[i]
        ..style = PaintingStyle.fill;
      canvas.drawCircle(point, 4, pointPaint);

      // 라벨 위치
      final labelOffset = Offset(
        center.dx + (radius + 25) * cos(angle),
        center.dy + (radius + 25) * sin(angle),
      );

      // 라벨 텍스트
      final labelSpan = TextSpan(
        text: labels[i],
        style: TextStyle(
          color: categoryColors[i],
          fontSize: 13,
          fontWeight: FontWeight.bold,
        ),
      );
      final labelPainter = TextPainter(
        text: labelSpan,
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      );
      labelPainter.layout();

      // 값 텍스트
      final valueSpan = TextSpan(
        text: '${values[i].toInt()}',
        style: TextStyle(
          color: textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w800,
        ),
      );
      final valuePainter = TextPainter(
        text: valueSpan,
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      );
      valuePainter.layout();

      // 라벨 위치 조정
      final labelTextOffset = Offset(
        labelOffset.dx - labelPainter.width / 2,
        labelOffset.dy - labelPainter.height - 2,
      );
      labelPainter.paint(canvas, labelTextOffset);

      final valueTextOffset = Offset(
        labelOffset.dx - valuePainter.width / 2,
        labelOffset.dy + 2,
      );
      valuePainter.paint(canvas, valueTextOffset);
    }
  }

  double _getAngle(int index) {
    return -pi / 2 + (2 * pi * index / 5);
  }

  void _drawPentagon(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    for (int i = 0; i < 5; i++) {
      final angle = _getAngle(i);
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
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SipSungRadarPainter oldDelegate) {
    return oldDelegate.values != values || oldDelegate.maxValue != maxValue;
  }
}
