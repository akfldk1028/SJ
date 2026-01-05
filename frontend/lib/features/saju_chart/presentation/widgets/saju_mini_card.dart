import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/pillar.dart';
import '../providers/saju_chart_provider.dart';
import 'pillar_display.dart';
import 'saju_detail_sheet.dart';

class SajuMiniCard extends ConsumerWidget {
  const SajuMiniCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.appTheme;
    final sajuChartAsync = ref.watch(currentSajuChartProvider);

    // 사주 분석도 watch하여 자동으로 Supabase에 저장되도록 함
    ref.watch(currentSajuAnalysisProvider);

    return sajuChartAsync.when(
      data: (sajuChart) {
        if (sajuChart == null) {
          return _buildEmptyCard(theme);
        }

        return _buildSajuCard(context, ref, sajuChart, theme);
      },
      loading: () => _buildLoadingCard(theme),
      error: (err, stack) => _buildErrorCard(theme, err),
    );
  }

  Widget _buildEmptyCard(AppThemeExtension theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: theme.primaryColor.withOpacity(0.1),
          ),
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

  Widget _buildLoadingCard(AppThemeExtension theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: theme.primaryColor.withOpacity(0.1),
          ),
        ),
        child: Center(
          child: CircularProgressIndicator(
            color: theme.primaryColor,
          ),
        ),
      ),
    );
  }

  Widget _buildErrorCard(AppThemeExtension theme, Object err) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.red.withOpacity(0.3),
          ),
        ),
        child: Center(
          child: Text(
            '오류가 발생했습니다',
            style: TextStyle(color: theme.textSecondary),
          ),
        ),
      ),
    );
  }

  // 한글 -> 한자 변환 맵 (천간)
  static const _ganHanjaMap = {
    '갑': '甲', '을': '乙', '병': '丙', '정': '丁', '무': '戊',
    '기': '己', '경': '庚', '신': '辛', '임': '壬', '계': '癸',
  };

  // 한글 -> 한자 변환 맵 (지지)
  static const _jiHanjaMap = {
    '자': '子', '축': '丑', '인': '寅', '묘': '卯', '진': '辰', '사': '巳',
    '오': '午', '미': '未', '신': '申', '유': '酉', '술': '戌', '해': '亥',
  };

  String _toHanja(String korean, {bool isGan = true}) {
    if (isGan) {
      return _ganHanjaMap[korean] ?? _jiHanjaMap[korean] ?? korean;
    }
    return _jiHanjaMap[korean] ?? _ganHanjaMap[korean] ?? korean;
  }

  Widget _buildPillarChar(AppThemeExtension theme, String char, String oheng, {bool isGan = true}) {
    Color charColor;
    switch (oheng) {
      case '목':
        charColor = theme.woodColor ?? const Color(0xFF7EDA98);
        break;
      case '화':
        charColor = theme.fireColor ?? const Color(0xFFE87C7C);
        break;
      case '토':
        charColor = theme.earthColor ?? const Color(0xFFD4A574);
        break;
      case '금':
        charColor = theme.metalColor ?? const Color(0xFFE8E8E8);
        break;
      case '수':
        charColor = theme.waterColor ?? const Color(0xFF7EB8DA);
        break;
      default:
        charColor = theme.primaryColor;
    }

    final hanjaChar = _toHanja(char, isGan: isGan);

    return Expanded(
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          // 라이트 테마: 연한 그레이 배경, 다크 테마: 그라데이션
          color: theme.isDark ? null : const Color(0xFFF5F7FA),
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
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.isDark
                ? theme.primaryColor.withOpacity(0.1)
                : theme.primaryColor.withOpacity(0.2),
          ),
        ),
        child: Center(
          child: Text(
            hanjaChar,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: charColor,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSajuCard(BuildContext context, WidgetRef ref, dynamic sajuChart, AppThemeExtension theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: theme.primaryColor.withOpacity(theme.isDark ? 0.15 : 0.12),
          ),
          boxShadow: theme.isDark
              ? [
                  BoxShadow(
                    color: theme.primaryColor.withOpacity(0.05),
                    blurRadius: 20,
                    spreadRadius: -5,
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header - 와이어프레임 스타일
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '나의 사주팔자',
                    style: TextStyle(
                      fontSize: 14,
                      color: theme.textSecondary,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      final container = ProviderScope.containerOf(context);
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (sheetContext) => UncontrolledProviderScope(
                          container: container,
                          child: const SajuDetailSheet(),
                        ),
                      );
                    },
                    child: Text(
                      '자세히 →',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Pillar Labels (시주, 일주, 월주, 연주)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Center(
                      child: Text(
                        '시주',
                        style: TextStyle(
                          fontSize: 10,
                          color: theme.textMuted,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        '일주',
                        style: TextStyle(
                          fontSize: 10,
                          color: theme.textMuted,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        '월주',
                        style: TextStyle(
                          fontSize: 10,
                          color: theme.textMuted,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        '연주',
                        style: TextStyle(
                          fontSize: 10,
                          color: theme.textMuted,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Pillars - 천간 (상단)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  _buildPillarChar(theme, sajuChart.hourPillar?.gan ?? '?', sajuChart.hourPillar?.ganOheng ?? ''),
                  const SizedBox(width: 12),
                  _buildPillarChar(theme, sajuChart.dayPillar.gan, sajuChart.dayPillar.ganOheng ?? ''),
                  const SizedBox(width: 12),
                  _buildPillarChar(theme, sajuChart.monthPillar.gan, sajuChart.monthPillar.ganOheng ?? ''),
                  const SizedBox(width: 12),
                  _buildPillarChar(theme, sajuChart.yearPillar.gan, sajuChart.yearPillar.ganOheng ?? ''),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Pillars - 지지 (하단)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Row(
                children: [
                  _buildPillarChar(theme, sajuChart.hourPillar?.ji ?? '?', sajuChart.hourPillar?.jiOheng ?? '', isGan: false),
                  const SizedBox(width: 12),
                  _buildPillarChar(theme, sajuChart.dayPillar.ji, sajuChart.dayPillar.jiOheng ?? '', isGan: false),
                  const SizedBox(width: 12),
                  _buildPillarChar(theme, sajuChart.monthPillar.ji, sajuChart.monthPillar.jiOheng ?? '', isGan: false),
                  const SizedBox(width: 12),
                  _buildPillarChar(theme, sajuChart.yearPillar.ji, sajuChart.yearPillar.jiOheng ?? '', isGan: false),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
