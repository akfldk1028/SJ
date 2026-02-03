import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/pillar.dart';
import '../providers/saju_chart_provider.dart';
import 'pillar_display.dart';
import 'saju_detail_tabs.dart';

/// 사주 상세 시트 - 동양풍 다크 테마
class SajuDetailSheet extends ConsumerWidget {
  const SajuDetailSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.appTheme;
    final sajuAnalysisAsync = ref.watch(currentSajuAnalysisProvider);

    return Container(
      constraints: const BoxConstraints(maxHeight: 650),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: theme.isDark
              ? [
                  const Color(0xFF1A1A24),
                  theme.backgroundColor,
                ]
              : [
                  const Color(0xFFFFFFFF), // 순백
                  const Color(0xFFF8F9FA), // 연한 그레이
                ],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(
          color: theme.primaryColor.withOpacity(0.15),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.primaryColor.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShaderMask(
                      shaderCallback: (bounds) => LinearGradient(
                        colors: [
                          theme.primaryColor,
                          theme.accentColor ?? theme.primaryColor,
                        ],
                      ).createShader(bounds),
                      child: const Text(
                        '나의 사주팔자',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '만세력과 오행 분포를 확인합니다.',
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.textMuted,
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: theme.primaryColor.withOpacity(0.15),
                      ),
                    ),
                    child: Icon(
                      Icons.close_rounded,
                      color: theme.textSecondary,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(color: theme.primaryColor.withOpacity(0.1), height: 1),
          // Content
          Expanded(
            child: sajuAnalysisAsync.when(
              data: (analysis) {
                if (analysis == null) {
                  return Center(
                    child: Text(
                      '분석 정보를 불러올 수 없습니다.',
                      style: TextStyle(color: theme.textSecondary),
                    ),
                  );
                }

                final chart = analysis.chart;
                final oheng = analysis.ohengDistribution;

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. 만세력 차트 (Reference Chart)
                      _buildSectionTitle(context, theme, '만세력 (Four Pillars)'),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.isDark ? null : Colors.white,
                          gradient: theme.isDark
                              ? LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    const Color(0xFF252530),
                                    const Color(0xFF1E1E28),
                                  ],
                                )
                              : null,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: theme.primaryColor.withOpacity(theme.isDark ? 0.15 : 0.2),
                          ),
                          boxShadow: theme.isDark
                              ? null
                              : [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            PillarDisplay(
                              label: '시주',
                              pillar: chart.hourPillar ??
                                  const Pillar(gan: '?', ji: '?'),
                              size: 32,
                            ),
                            PillarDisplay(
                              label: '일주 (나)',
                              pillar: chart.dayPillar,
                              size: 32,
                            ),
                            PillarDisplay(
                              label: '월주',
                              pillar: chart.monthPillar,
                              size: 32,
                            ),
                            PillarDisplay(
                              label: '년주',
                              pillar: chart.yearPillar,
                              size: 32,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // 2. 오행 분포 (Five Elements)
                      _buildSectionTitle(context, theme, '오행 분석'),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.isDark ? null : Colors.white,
                          gradient: theme.isDark
                              ? LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    const Color(0xFF252530),
                                    const Color(0xFF1E1E28),
                                  ],
                                )
                              : null,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: theme.primaryColor.withOpacity(theme.isDark ? 0.15 : 0.2),
                          ),
                          boxShadow: theme.isDark
                              ? null
                              : [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                        ),
                        child: Column(
                          children: [
                            _buildOhengBar(context, theme, '목(木)', oheng.mok,
                                theme.woodColor ?? const Color(0xFF7EDA98)),
                            _buildOhengBar(context, theme, '화(火)', oheng.hwa,
                                theme.fireColor ?? const Color(0xFFE87C7C)),
                            _buildOhengBar(context, theme, '토(土)', oheng.to,
                                theme.earthColor ?? const Color(0xFFD4A574)),
                            _buildOhengBar(context, theme, '금(金)', oheng.geum,
                                theme.metalColor ?? const Color(0xFF708090)),
                            _buildOhengBar(context, theme, '수(水)', oheng.su,
                                theme.waterColor ?? const Color(0xFF7EB8DA)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // 3. 상세 분석 버튼
                      GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (_) => const SajuDetailTabs(),
                          );
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                theme.primaryColor,
                                theme.accentColor ?? theme.primaryColor,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: theme.primaryColor.withOpacity(0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.analytics_outlined,
                                color: theme.isDark ? const Color(0xFF0A0A0F) : Colors.white,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '상세 분석 보기',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: theme.isDark ? const Color(0xFF0A0A0F) : Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                );
              },
              loading: () => Center(
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: CircularProgressIndicator(
                    color: theme.primaryColor,
                  ),
                ),
              ),
              error: (err, stack) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    '오류가 발생했습니다:\n$err',
                    style: TextStyle(color: theme.fireColor ?? Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, AppThemeExtension theme, String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: theme.primaryColor,
      ),
    );
  }

  Widget _buildOhengBar(BuildContext context, AppThemeExtension theme, String label, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 50,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: theme.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Container(
              height: 24,
              decoration: BoxDecoration(
                color: theme.backgroundColor.withOpacity(0.5),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Stack(
                children: [
                  if (count > 0)
                    FractionallySizedBox(
                      widthFactor: (count / 8).clamp(0.0, 1.0),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              color,
                              color.withOpacity(0.7),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 24,
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
