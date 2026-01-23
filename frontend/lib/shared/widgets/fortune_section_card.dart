import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import 'fortune_score_gauge.dart';

/// 운세 섹션 카드 위젯
///
/// 동양풍 감성의 섹션 제목, 내용, 점수 등을 통일된 스타일로 표시
class FortuneSectionCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? child;
  final String? content;
  final int? score;
  final IconData? icon;
  final CardStyle style;
  final VoidCallback? onTap;
  final bool showDivider;
  final List<Widget>? actions;

  const FortuneSectionCard({
    super.key,
    required this.title,
    this.subtitle,
    this.child,
    this.content,
    this.score,
    this.icon,
    this.style = CardStyle.elevated,
    this.onTap,
    this.showDivider = false,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;

    Widget cardContent = _buildCardContent(theme);

    if (onTap != null) {
      cardContent = InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: cardContent,
      );
    }

    switch (style) {
      case CardStyle.elevated:
        return _buildElevatedCard(theme, cardContent);
      case CardStyle.outlined:
        return _buildOutlinedCard(theme, cardContent);
      case CardStyle.filled:
        return _buildFilledCard(theme, cardContent);
      case CardStyle.gradient:
        return _buildGradientCard(theme, cardContent);
      case CardStyle.transparent:
        return cardContent;
    }
  }

  Widget _buildCardContent(AppThemeExtension theme) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더
          _buildHeader(theme),

          // 구분선
          if (showDivider) ...[
            const SizedBox(height: 16),
            Container(
              height: 1,
              color: theme.textMuted.withValues(alpha: 0.1),
            ),
            const SizedBox(height: 16),
          ] else ...[
            const SizedBox(height: 14),
          ],

          // 내용
          if (content != null)
            Text(
              content!,
              style: TextStyle(
                fontSize: 15,
                color: theme.textSecondary,
                height: 1.8,
                letterSpacing: 0.1,
              ),
            ),

          if (child != null) child!,

          // 액션 버튼
          if (actions != null && actions!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: actions!,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader(AppThemeExtension theme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // 아이콘 (동양풍 우아한 스타일)
        if (icon != null) ...[
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.primaryColor.withValues(alpha: 0.15),
                width: 1,
              ),
            ),
            child: Icon(
              icon,
              size: 20,
              color: theme.primaryColor,
            ),
          ),
          const SizedBox(width: 14),
        ],

        // 제목 & 부제목
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
                  letterSpacing: -0.3,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: theme.textMuted,
                  ),
                ),
              ],
            ],
          ),
        ),

        // 점수
        if (score != null) ...[
          const SizedBox(width: 12),
          FortuneScoreGauge(
            score: score!,
            size: 52,
            style: GaugeStyle.circular,
          ),
        ],
      ],
    );
  }

  Widget _buildElevatedCard(AppThemeExtension theme, Widget content) {
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.primaryColor.withValues(alpha: 0.08),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: theme.isDark ? 0.3 : 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: content,
    );
  }

  Widget _buildOutlinedCard(AppThemeExtension theme, Widget content) {
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.textMuted.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: content,
    );
  }

  Widget _buildFilledCard(AppThemeExtension theme, Widget content) {
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: content,
    );
  }

  Widget _buildGradientCard(AppThemeExtension theme, Widget content) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.cardColor,
            theme.primaryColor.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.primaryColor.withValues(alpha: 0.12),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: theme.isDark ? 0.25 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: content,
    );
  }
}

/// 카드 스타일
enum CardStyle {
  elevated,    // 그림자 있는 카드
  outlined,    // 테두리 카드
  filled,      // 배경만 있는 카드
  gradient,    // 그라데이션 카드
  transparent, // 투명 (패딩만)
}

/// 운세 리스트 아이템 카드
class FortuneListItemCard extends StatelessWidget {
  final String title;
  final String? description;
  final int? score;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool showArrow;

  const FortuneListItemCard({
    super.key,
    required this.title,
    this.description,
    this.score,
    this.leading,
    this.trailing,
    this.onTap,
    this.showArrow = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.textMuted.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Leading
            if (leading != null) ...[
              leading!,
              const SizedBox(width: 14),
            ],

            // Title & Description
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: theme.textPrimary,
                    ),
                  ),
                  if (description != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      description!,
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.textSecondary,
                        height: 1.5,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),

            // Score
            if (score != null) ...[
              const SizedBox(width: 12),
              FortuneScoreGauge(
                score: score!,
                size: 40,
                style: GaugeStyle.compact,
                showLabel: false,
              ),
            ],

            // Trailing
            if (trailing != null) ...[
              const SizedBox(width: 8),
              trailing!,
            ],

            // Arrow
            if (showArrow && onTap != null) ...[
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right,
                size: 20,
                color: theme.textMuted,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 운세 하이라이트 박스 - 동양풍 우아한 스타일
class FortuneHighlightBox extends StatelessWidget {
  final String label;
  final String content;
  final HighlightType type;
  final IconData? icon;

  const FortuneHighlightBox({
    super.key,
    required this.label,
    required this.content,
    this.type = HighlightType.info,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    final color = _getTypeColor(type, theme);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: color.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 아이콘 또는 세로 바
          if (icon != null) ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(width: 14),
          ] else ...[
            Container(
              width: 4,
              height: 44,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 14),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  content,
                  style: TextStyle(
                    fontSize: 15,
                    color: theme.textSecondary,
                    height: 1.7,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getTypeColor(HighlightType type, AppThemeExtension theme) {
    switch (type) {
      case HighlightType.success:
        return const Color(0xFF2D8659); // 차분한 녹색
      case HighlightType.warning:
        return const Color(0xFFB8860B); // 다크 골든로드
      case HighlightType.error:
        return const Color(0xFF9B2C2C); // 차분한 적색
      case HighlightType.info:
        return const Color(0xFF4A6FA5); // 차분한 청색
      case HighlightType.primary:
        return theme.primaryColor; // 테마 금색
    }
  }
}

/// 하이라이트 타입
enum HighlightType {
  success,
  warning,
  error,
  info,
  primary,
}
