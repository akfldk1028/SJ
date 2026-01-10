import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/pillar.dart';
import '../providers/saju_chart_provider.dart';
import 'pillar_display.dart';
import 'personalized_oheng_widget.dart';

/// 메인 페이지의 사주 카드 - 만세력 + 오행분석 + 상세분석 버튼
class SajuMiniCard extends ConsumerWidget {
  const SajuMiniCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.appTheme;
    final sajuChartAsync = ref.watch(currentSajuChartProvider);
    final sajuAnalysisAsync = ref.watch(currentSajuAnalysisProvider);

    return sajuChartAsync.when(
      data: (sajuChart) {
        if (sajuChart == null) {
          return _buildEmptyCard(context, theme);
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: theme.isDark
                      ? const Color.fromRGBO(0, 0, 0, 0.3)
                      : const Color.fromRGBO(0, 0, 0, 0.06),
                  offset: const Offset(0, 4),
                  blurRadius: 16,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '내 사주',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: theme.textPrimary,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: theme.primaryColor.withValues(alpha:0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${sajuChart.isLunarCalendar ? '음력' : '양력'} ${sajuChart.birthDateTime.year}',
                          style: TextStyle(
                            fontSize: 11,
                            color: theme.primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // 만세력 (Four Pillars)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final screenWidth = constraints.maxWidth;
                      final pillarSize = screenWidth > 600 ? 32.0 :
                                         screenWidth > 450 ? 28.0 : 24.0;

                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          PillarDisplay(
                            label: '시주',
                            pillar: sajuChart.hourPillar ?? const Pillar(gan: '?', ji: '?'),
                            size: pillarSize,
                          ),
                          PillarDisplay(
                            label: '일주',
                            pillar: sajuChart.dayPillar,
                            size: pillarSize,
                          ),
                          PillarDisplay(
                            label: '월주',
                            pillar: sajuChart.monthPillar,
                            size: pillarSize,
                          ),
                          PillarDisplay(
                            label: '년주',
                            pillar: sajuChart.yearPillar,
                            size: pillarSize,
                          ),
                        ],
                      );
                    },
                  ),
                ),

                const SizedBox(height: 16),

                // 오행 분석 섹션 - 오각형 레이더 차트
                sajuAnalysisAsync.when(
                  data: (analysis) {
                    if (analysis == null) return const SizedBox.shrink();

                    final oheng = analysis.ohengDistribution;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.isDark
                              ? theme.primaryColor.withValues(alpha:0.05)
                              : theme.backgroundColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '오행 분포',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: theme.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              height: 260,
                              child: OhengRadarChart(
                                mok: oheng.mok,
                                hwa: oheng.hwa,
                                to: oheng.to,
                                geum: oheng.geum,
                                su: oheng.su,
                                theme: theme,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),

                const SizedBox(height: 12),

                // 개인화된 오행 관계 설명 (일간 기준)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: PersonalizedOhengWidget(
                    dayMaster: sajuChart.dayMaster,
                    theme: theme,
                  ),
                ),

                const SizedBox(height: 16),

                // 상세분석 보기 버튼
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: GestureDetector(
                    onTap: () => context.push('/saju/detail'),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            theme.primaryColor,
                            theme.accentColor ?? theme.primaryColor,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.analytics_outlined,
                            color: theme.isDark ? Colors.black : Colors.white,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '상세 분석 보기',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: theme.isDark ? Colors.black : Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => _buildLoadingCard(context, theme),
      error: (err, stack) => _buildErrorCard(context, theme, err.toString()),
    );
  }

  Widget _buildEmptyCard(BuildContext context, AppThemeExtension theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text(
            '프로필을 선택하여 만세력을 확인하세요',
            style: TextStyle(color: theme.textSecondary),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingCard(BuildContext context, AppThemeExtension theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: CircularProgressIndicator(color: theme.primaryColor),
        ),
      ),
    );
  }

  Widget _buildErrorCard(BuildContext context, AppThemeExtension theme, String error) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text(
            '오류가 발생했습니다: $error',
            style: TextStyle(color: theme.fireColor ?? Colors.red),
          ),
        ),
      ),
    );
  }
}

/// 오행 오각형 레이더 차트 위젯
class OhengRadarChart extends StatelessWidget {
  final int mok;
  final int hwa;
  final int to;
  final int geum;
  final int su;
  final AppThemeExtension theme;

  const OhengRadarChart({
    super.key,
    required this.mok,
    required this.hwa,
    required this.to,
    required this.geum,
    required this.su,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(double.infinity, 260),
      painter: _OhengRadarPainter(
        values: [mok.toDouble(), hwa.toDouble(), to.toDouble(), geum.toDouble(), su.toDouble()],
        maxValue: 4.0, // 최대값 4 기준
        theme: theme,
      ),
    );
  }
}

class _OhengRadarPainter extends CustomPainter {
  final List<double> values;
  final double maxValue;
  final AppThemeExtension theme;

  // 오행 라벨과 색상
  static const labels = ['목(木)', '화(火)', '토(土)', '금(金)', '수(水)'];

  _OhengRadarPainter({
    required this.values,
    required this.maxValue,
    required this.theme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.height / 2) - 40; // 라벨 공간 확보

    // 오행 색상 (더 선명하게)
    final colors = [
      theme.woodColor ?? const Color(0xFF4CAF50), // 목 - 선명한 녹색
      theme.fireColor ?? const Color(0xFFE53935), // 화 - 선명한 빨강
      theme.earthColor ?? const Color(0xFFD4A574), // 토 - 황토색
      theme.metalColor ?? const Color(0xFF9E9E9E), // 금 - 진한 회색
      theme.waterColor ?? const Color(0xFF2196F3), // 수 - 선명한 파랑
    ];

    // 배경 오각형 그리기 (4단계로 더 상세하게)
    for (int level = 1; level <= 4; level++) {
      final levelRadius = radius * (level / 4);
      final bgPaint = Paint()
        ..color = theme.textMuted.withValues(alpha:level == 4 ? 0.2 : 0.08)
        ..style = PaintingStyle.stroke
        ..strokeWidth = level == 4 ? 1.5 : 1;
      _drawPentagon(canvas, center, levelRadius, bgPaint);
    }

    // 축선 그리기
    final axisPaint = Paint()
      ..color = theme.textMuted.withValues(alpha:0.15)
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

    // 데이터 오각형 그리기
    final dataPath = Path();
    final dataFillPaint = Paint()
      ..color = theme.primaryColor.withValues(alpha:0.25)
      ..style = PaintingStyle.fill;
    final dataStrokePaint = Paint()
      ..color = theme.primaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    for (int i = 0; i < 5; i++) {
      final angle = _getAngle(i);
      final value = (values[i] / maxValue).clamp(0.0, 1.0);
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

    // 데이터 포인트와 라벨 그리기
    for (int i = 0; i < 5; i++) {
      final angle = _getAngle(i);
      final value = (values[i] / maxValue).clamp(0.0, 1.0);
      final point = Offset(
        center.dx + radius * value * cos(angle),
        center.dy + radius * value * sin(angle),
      );

      // 데이터 포인트 (적절한 크기)
      final pointBgPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      canvas.drawCircle(point, 5, pointBgPaint);

      final pointPaint = Paint()
        ..color = colors[i]
        ..style = PaintingStyle.fill;
      canvas.drawCircle(point, 3.5, pointPaint);

      // 라벨 위치 (오각형 바깥쪽)
      final labelOffset = Offset(
        center.dx + (radius + 30) * cos(angle),
        center.dy + (radius + 30) * sin(angle),
      );

      // 라벨 텍스트 (개선된 스타일)
      final labelTextSpan = TextSpan(
        text: labels[i],
        style: TextStyle(
          color: colors[i],
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      );
      final labelPainter = TextPainter(
        text: labelTextSpan,
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      );
      labelPainter.layout();

      // 숫자 텍스트
      final countTextSpan = TextSpan(
        text: '${values[i].toInt()}',
        style: TextStyle(
          color: theme.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w800,
        ),
      );
      final countPainter = TextPainter(
        text: countTextSpan,
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      );
      countPainter.layout();

      // 라벨 위치 조정
      final labelTextOffset = Offset(
        labelOffset.dx - labelPainter.width / 2,
        labelOffset.dy - labelPainter.height - 2,
      );
      labelPainter.paint(canvas, labelTextOffset);

      final countTextOffset = Offset(
        labelOffset.dx - countPainter.width / 2,
        labelOffset.dy + 2,
      );
      countPainter.paint(canvas, countTextOffset);
    }
  }

  // 오각형 각도 계산 (위쪽부터 시작, 시계방향)
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
  bool shouldRepaint(covariant _OhengRadarPainter oldDelegate) {
    return oldDelegate.values != values || oldDelegate.maxValue != maxValue;
  }
}
