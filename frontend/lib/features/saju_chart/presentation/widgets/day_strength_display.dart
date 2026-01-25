import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/constants/sipsin_relations.dart';
import '../../domain/entities/day_strength.dart';
import '../../domain/entities/saju_analysis.dart';

/// 신강/신약 지수 및 용신 표시 위젯 (포스텔러 스타일)
class DayStrengthDisplay extends StatelessWidget {
  final SajuAnalysis analysis;

  const DayStrengthDisplay({super.key, required this.analysis});

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 신강/신약 지수 섹션
          _buildSectionTitle(context, '신강/신약지수', theme),
          const SizedBox(height: 12),
          _buildDayStrengthCard(context, theme),
          const SizedBox(height: 8),
          _buildDayStrengthChart(context, theme),
          const SizedBox(height: 24),

          // 용신 섹션
          _buildSectionTitle(context, '용신', theme),
          const SizedBox(height: 12),
          _buildYongsinCard(context, theme),
          const SizedBox(height: 24),

          // 득령/득지/득시/득세 분석
          _buildSectionTitle(context, '일간 강약 분석', theme),
          const SizedBox(height: 12),
          _buildStrengthFactorsCard(context, theme),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title, AppThemeExtension theme) {
    return Row(
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.textPrimary,
              ),
        ),
        const SizedBox(width: 8),
        Icon(Icons.help_outline, size: 16, color: theme.textMuted),
      ],
    );
  }

  /// 신강/신약 상태 카드
  Widget _buildDayStrengthCard(BuildContext context, AppThemeExtension theme) {
    final dayStrength = analysis.dayStrength;
    final level = dayStrength.level;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 득령/득지/득시/득세 표시 (실제 계산값 사용)
          Row(
            children: [
              _buildDeukBadge('득령', dayStrength.deukryeong, theme),
              const SizedBox(width: 8),
              _buildDeukBadge('득지', dayStrength.deukji, theme),
              const SizedBox(width: 8),
              _buildDeukBadge('득시', dayStrength.deuksi, theme),
              const SizedBox(width: 8),
              _buildDeukBadge('득세', dayStrength.deukse, theme),
            ],
          ),
          const SizedBox(height: 16),
          // 신강/신약 상태 문구
          RichText(
            text: TextSpan(
              style: TextStyle(
                color: theme.textPrimary,
                fontSize: 14,
              ),
              children: [
                TextSpan(
                  text: '${analysis.chart.dayPillar.gan}일간님은 ',
                ),
                TextSpan(
                  text: level.korean,
                  style: TextStyle(
                    color: _getStrengthColor(level),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const TextSpan(text: '한 사주입니다.'),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${_getPopulationPercentage(dayStrength.score)}%의 사람이 여기에 해당합니다.',
            style: TextStyle(
              color: _getStrengthColor(level),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeukBadge(String label, bool isActive, AppThemeExtension theme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            color: theme.textSecondary,
            fontSize: 12,
          ),
        ),
        const SizedBox(width: 4),
        Icon(
          isActive ? Icons.radio_button_checked : Icons.cancel,
          size: 14,
          color: isActive ? AppColors.success : AppColors.error,
        ),
      ],
    );
  }

  /// 신강/신약 그래프 (8단계)
  Widget _buildDayStrengthChart(BuildContext context, AppThemeExtension theme) {
    final dayStrength = analysis.dayStrength;
    final score = dayStrength.score;

    // 8단계 레벨
    const levels = ['극약', '태약', '신약', '중화\n신약', '중화\n신강', '신강', '태강', '극왕'];

    // level.index8 사용하여 현재 인덱스 가져오기
    final currentIndex = dayStrength.level.index8;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.border),
      ),
      child: Column(
        children: [
          // 막대 그래프
          SizedBox(
            height: 130,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(levels.length, (index) {
                // 정규분포 비슷한 높이 설정 (포스텔러 스타일)
                const heights = [20.0, 50.0, 80.0, 95.0, 100.0, 80.0, 50.0, 20.0];
                final height = heights[index];
                final isActive = index == currentIndex;

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // 포인터
                        if (isActive)
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppColors.accent,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.person,
                              size: 12,
                              color: Colors.white,
                            ),
                          ),
                        if (isActive) const SizedBox(height: 4),
                        // 막대
                        Container(
                          height: height,
                          decoration: BoxDecoration(
                            color: isActive
                                ? theme.primaryColor
                                : theme.surfaceHover,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 8),
          // 라벨
          Row(
            children: levels.map((label) {
              return Expanded(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: theme.textMuted,
                    fontSize: 9,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 4),
          // Y축 레이블
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '(만명)',
                style: TextStyle(color: theme.textMuted, fontSize: 10),
              ),
              Text(
                '점수: $score점',
                style: TextStyle(color: theme.textSecondary, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 용신 카드
  Widget _buildYongsinCard(BuildContext context, AppThemeExtension theme) {
    final yongsin = analysis.yongsin;

    // 조후용신 계산 (월지 기반)
    final johuYongsin = _calculateJohuYongsin();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 조후용신
          _buildYongsinBadge(
            label: '조후용신',
            oheng: johuYongsin,
          ),
          const SizedBox(width: 24),
          // 억부용신
          _buildYongsinBadge(
            label: '억부용신',
            oheng: yongsin.yongsin,
          ),
        ],
      ),
    );
  }

  Widget _buildYongsinBadge({
    required String label,
    required Oheng oheng,
    AppThemeExtension? theme,
  }) {
    final color = _getOhengColor(oheng);

    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: theme?.textMuted ?? AppColors.textMuted,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.5)),
          ),
          child: Text(
            oheng.korean,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  /// 일간 강약 분석 요소 카드
  Widget _buildStrengthFactorsCard(BuildContext context, AppThemeExtension theme) {
    final details = analysis.dayStrength.details;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.border),
      ),
      child: Column(
        children: [
          _buildFactorRow('월령', details.monthStatus.korean,
              details.monthStatus == MonthStatus.deukwol, theme),
          _buildFactorRow('비겁', '${details.bigeopCount}개',
              details.bigeopCount > 1, theme),
          _buildFactorRow('인성', '${details.inseongCount}개',
              details.inseongCount > 0, theme),
          _buildFactorRow('재성', '${details.jaeseongCount}개',
              details.jaeseongCount > 2, theme, isNegative: true),
          _buildFactorRow('관성', '${details.gwanseongCount}개',
              details.gwanseongCount > 1, theme, isNegative: true),
          _buildFactorRow('식상', '${details.siksangCount}개',
              details.siksangCount > 1, theme, isNegative: true),
        ],
      ),
    );
  }

  Widget _buildFactorRow(String label, String value, bool isActive, AppThemeExtension theme, {bool isNegative = false}) {
    final color = isActive
        ? (isNegative ? AppColors.error : AppColors.success)
        : theme.textMuted;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: theme.textSecondary,
              fontSize: 13,
            ),
          ),
          Row(
            children: [
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                isActive
                    ? (isNegative ? Icons.remove_circle : Icons.add_circle)
                    : Icons.circle_outlined,
                size: 16,
                color: color,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 조후용신 계산 (간단 버전 - 월지 기반)
  Oheng _calculateJohuYongsin() {
    final monthJi = analysis.chart.monthPillar.ji;

    // 월지에 따른 조후용신 (간단 버전)
    // 인묘진 (봄) → 수/금 필요
    // 사오미 (여름) → 수 필요
    // 신유술 (가을) → 화/목 필요
    // 해자축 (겨울) → 화 필요
    return switch (monthJi) {
      '인' || '묘' || '진' => Oheng.su,  // 봄 → 수
      '사' || '오' || '미' => Oheng.su,  // 여름 → 수
      '신' || '유' || '술' => Oheng.hwa, // 가을 → 화
      '해' || '자' || '축' => Oheng.hwa, // 겨울 → 화
      _ => analysis.yongsin.yongsin,
    };
  }

  Color _getStrengthColor(DayStrengthLevel level) {
    return switch (level) {
      DayStrengthLevel.geukwang => AppColors.fire,     // 극왕 - 빨강
      DayStrengthLevel.taegang => AppColors.fire,      // 태강 - 빨강
      DayStrengthLevel.singang => AppColors.earth,     // 신강 - 노랑
      DayStrengthLevel.junghwaSingang => AppColors.wood, // 중화신강 - 초록
      DayStrengthLevel.junghwaSinyak => AppColors.wood,  // 중화신약 - 초록
      DayStrengthLevel.sinyak => AppColors.water,      // 신약 - 파랑
      DayStrengthLevel.taeyak => AppColors.water,      // 태약 - 파랑
      DayStrengthLevel.geukyak => AppColors.metal,     // 극약 - 회색
    };
  }

  Color _getOhengColor(Oheng oheng) {
    return switch (oheng) {
      Oheng.mok => AppColors.wood,
      Oheng.hwa => AppColors.fire,
      Oheng.to => AppColors.earth,
      Oheng.geum => AppColors.metal,
      Oheng.su => AppColors.water,
    };
  }

  /// 점수에 따른 인구 비율 (8단계 정규분포 기반)
  double _getPopulationPercentage(int score) {
    // 8단계 정규분포 기반 (포스텔러 스타일)
    // 중화신강/중화신약이 가장 많음 (약 26%)
    if (score >= 88) return 2.5;   // 극왕
    if (score >= 75) return 6.5;   // 태강
    if (score >= 63) return 15.8;  // 신강
    if (score >= 50) return 26.31; // 중화신강
    if (score >= 38) return 26.31; // 중화신약
    if (score >= 26) return 15.8;  // 신약
    if (score >= 13) return 6.5;   // 태약
    return 2.5;                     // 극약
  }
}
