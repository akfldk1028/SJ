import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import 'fortune_score_gauge.dart';
import 'fortune_keyword_badge.dart';

/// 운세 타이틀 헤더 위젯
///
/// 동양풍 감성의 페이지 상단 타이틀, 간지, 키워드, 점수 등을 통일된 스타일로 표시
class FortuneTitleHeader extends StatelessWidget {
  final String title;
  final String? subtitle; // 간지 (을사년 등)
  final String? keyword;
  final int? score;
  final HeaderStyle style;
  final Widget? decoration;

  const FortuneTitleHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.keyword,
    this.score,
    this.style = HeaderStyle.standard,
    this.decoration,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;

    switch (style) {
      case HeaderStyle.standard:
        return _buildStandardHeader(theme);
      case HeaderStyle.centered:
        return _buildCenteredHeader(theme);
      case HeaderStyle.hero:
        return _buildHeroHeader(theme);
      case HeaderStyle.compact:
        return _buildCompactHeader(theme);
    }
  }

  /// 표준 헤더 (좌측 정렬)
  Widget _buildStandardHeader(AppThemeExtension theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 타이틀
        Text(
          title,
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: theme.textPrimary,
            letterSpacing: -0.5,
            height: 1.3,
          ),
        ),

        // 서브타이틀 (간지)
        if (subtitle != null && subtitle!.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            subtitle!,
            style: TextStyle(
              fontSize: 14,
              color: theme.textSecondary,
              letterSpacing: 0.2,
            ),
          ),
        ],

        // 키워드 & 점수
        if (keyword != null || score != null) ...[
          const SizedBox(height: 18),
          Row(
            children: [
              if (keyword != null)
                FortuneKeywordBadge(
                  keyword: keyword!,
                  style: BadgeStyle.filled,
                ),
              if (keyword != null && score != null) const SizedBox(width: 12),
              if (score != null)
                FortuneScoreGauge(
                  score: score!,
                  size: 48,
                  style: GaugeStyle.compact,
                ),
            ],
          ),
        ],

        // 장식
        if (decoration != null) ...[
          const SizedBox(height: 18),
          decoration!,
        ],
      ],
    );
  }

  /// 중앙 정렬 헤더
  Widget _buildCenteredHeader(AppThemeExtension theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // 타이틀
        Text(
          title,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: theme.textPrimary,
            letterSpacing: -0.5,
            height: 1.3,
          ),
          textAlign: TextAlign.center,
        ),

        // 서브타이틀 (간지)
        if (subtitle != null && subtitle!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            subtitle!,
            style: TextStyle(
              fontSize: 15,
              color: theme.textSecondary,
              letterSpacing: 0.3,
            ),
            textAlign: TextAlign.center,
          ),
        ],

        // 키워드 & 점수
        if (keyword != null || score != null) ...[
          const SizedBox(height: 20),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            runSpacing: 10,
            children: [
              if (keyword != null)
                FortuneKeywordBadge(
                  keyword: keyword!,
                  style: BadgeStyle.filled,
                ),
              if (score != null)
                FortuneScoreGauge(
                  score: score!,
                  size: 48,
                  style: GaugeStyle.compact,
                ),
            ],
          ),
        ],

        // 장식
        if (decoration != null) ...[
          const SizedBox(height: 20),
          decoration!,
        ],
      ],
    );
  }

  /// 히어로 헤더 (동양풍 우아한 스타일)
  Widget _buildHeroHeader(AppThemeExtension theme) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: BoxDecoration(
        color: theme.primaryColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.primaryColor.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 점수 게이지 (크게)
          if (score != null) ...[
            FortuneScoreGauge(
              score: score!,
              size: 100,
              style: GaugeStyle.circular,
              label: '총운',
            ),
            const SizedBox(height: 24),
          ],

          // 타이틀
          Text(
            title,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: theme.textPrimary,
              letterSpacing: -0.5,
              height: 1.3,
            ),
            textAlign: TextAlign.center,
          ),

          // 서브타이틀 (간지) - 뱃지 스타일
          if (subtitle != null && subtitle!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: theme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.primaryColor.withValues(alpha: 0.15),
                  width: 1,
                ),
              ),
              child: Text(
                subtitle!,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: theme.primaryColor,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ],

          // 키워드
          if (keyword != null) ...[
            const SizedBox(height: 16),
            FortuneKeywordBadge(
              keyword: keyword!,
              style: BadgeStyle.glass,
              fontSize: 14,
            ),
          ],

          // 장식
          if (decoration != null) ...[
            const SizedBox(height: 20),
            decoration!,
          ],
        ],
      ),
    );
  }

  /// 컴팩트 헤더
  Widget _buildCompactHeader(AppThemeExtension theme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // 타이틀 & 서브타이틀
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: theme.textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
              if (subtitle != null && subtitle!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),

        // 점수 또는 키워드
        if (score != null)
          FortuneScoreGauge(
            score: score!,
            size: 56,
            style: GaugeStyle.circular,
          )
        else if (keyword != null)
          FortuneKeywordBadge(
            keyword: keyword!,
            style: BadgeStyle.filled,
          ),
      ],
    );
  }
}

/// 헤더 스타일
enum HeaderStyle {
  standard, // 표준 (좌측 정렬)
  centered, // 중앙 정렬
  hero,     // 히어로 (크고 화려함)
  compact,  // 컴팩트 (한 줄)
}

/// 섹션 타이틀 위젯 (섹션 내부용) - 동양풍 스타일
class FortuneSectionTitle extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final int? score;
  final Widget? trailing;
  final VoidCallback? onTap;

  const FortuneSectionTitle({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.score,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            // 아이콘
            if (icon != null) ...[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: theme.primaryColor),
              ),
              const SizedBox(width: 12),
            ],

            // 타이틀 & 서브타이틀
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: theme.textPrimary,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.textMuted,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // 점수
            if (score != null) ...[
              FortuneScoreGauge(
                score: score!,
                size: 38,
                style: GaugeStyle.compact,
                showLabel: false,
              ),
            ],

            // Trailing
            if (trailing != null) trailing!,

            // 화살표 (탭 가능한 경우)
            if (onTap != null) ...[
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, size: 20, color: theme.textMuted),
            ],
          ],
        ),
      ),
    );
  }
}
