import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// 운세 키워드 배지 위젯
///
/// 동양풍 감성의 키워드를 태그/배지 형태로 시각적으로 표시
class FortuneKeywordBadge extends StatelessWidget {
  final String keyword;
  final BadgeStyle style;
  final Color? customColor;
  final double? fontSize;
  final IconData? icon;

  const FortuneKeywordBadge({
    super.key,
    required this.keyword,
    this.style = BadgeStyle.filled,
    this.customColor,
    this.fontSize,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;

    switch (style) {
      case BadgeStyle.filled:
        return _buildFilledBadge(theme);
      case BadgeStyle.outlined:
        return _buildOutlinedBadge(theme);
      case BadgeStyle.gradient:
        return _buildGradientBadge(theme);
      case BadgeStyle.glass:
        return _buildGlassBadge(theme);
      case BadgeStyle.minimal:
        return _buildMinimalBadge(theme);
    }
  }

  /// 채워진 배지 - 동양풍 우아한 스타일
  Widget _buildFilledBadge(AppThemeExtension theme) {
    final color = customColor ?? theme.primaryColor;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
          ],
          Text(
            keyword,
            style: TextStyle(
              fontSize: fontSize ?? 14,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  /// 테두리 배지 - 심플한 스타일
  Widget _buildOutlinedBadge(AppThemeExtension theme) {
    final color = customColor ?? theme.primaryColor;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
          ],
          Text(
            keyword,
            style: TextStyle(
              fontSize: fontSize ?? 14,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  /// 그라데이션 배지 - 은은한 동양풍 스타일
  Widget _buildGradientBadge(AppThemeExtension theme) {
    final color = customColor ?? theme.primaryColor;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.15),
            color.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 8),
          ],
          Text(
            keyword,
            style: TextStyle(
              fontSize: fontSize ?? 15,
              fontWeight: FontWeight.w700,
              color: theme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  /// 글래스 배지 - 차분한 스타일
  Widget _buildGlassBadge(AppThemeExtension theme) {
    final color = customColor ?? theme.primaryColor;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        color: theme.cardColor.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: theme.textMuted.withValues(alpha: 0.12),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: theme.isDark ? 0.2 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 8),
          ],
          Text(
            keyword,
            style: TextStyle(
              fontSize: fontSize ?? 14,
              fontWeight: FontWeight.w600,
              color: theme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  /// 미니멀 배지 - 깔끔한 스타일
  Widget _buildMinimalBadge(AppThemeExtension theme) {
    final color = customColor ?? theme.primaryColor;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          keyword,
          style: TextStyle(
            fontSize: fontSize ?? 14,
            fontWeight: FontWeight.w600,
            color: theme.textPrimary,
          ),
        ),
      ],
    );
  }
}

/// 배지 스타일
enum BadgeStyle {
  filled,    // 채워진 배지
  outlined,  // 테두리만
  gradient,  // 그라데이션
  glass,     // 글래스모피즘
  minimal,   // 미니멀
}

/// 키워드 + 점수 조합 배지 - 동양풍 스타일
class FortuneKeywordScoreBadge extends StatelessWidget {
  final String keyword;
  final int score;
  final bool showScore;

  const FortuneKeywordScoreBadge({
    super.key,
    required this.keyword,
    required this.score,
    this.showScore = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    final scoreColor = _getScoreColor(score, theme);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        color: theme.primaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.primaryColor.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 키워드
          Text(
            keyword,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: theme.textPrimary,
            ),
          ),
          if (showScore) ...[
            const SizedBox(width: 12),
            // 구분선
            Container(
              width: 1,
              height: 18,
              color: theme.textMuted.withValues(alpha: 0.2),
            ),
            const SizedBox(width: 12),
            // 점수
            Text(
              '$score점',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: scoreColor,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getScoreColor(int score, AppThemeExtension theme) {
    if (score >= 80) return const Color(0xFFB8860B); // 다크 골든로드
    if (score >= 60) return theme.primaryColor; // 테마 금색
    if (score >= 40) return const Color(0xFF8B7355); // 버우드
    return const Color(0xFF6B5344); // 다크 브라운
  }
}
