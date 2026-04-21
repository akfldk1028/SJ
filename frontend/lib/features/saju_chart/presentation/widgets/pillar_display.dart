import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/constants/cheongan_jiji.dart';
import '../../data/constants/cheongan_jiji_i18n.dart';
import '../../domain/entities/pillar.dart';

/// 사주의 기둥 하나(천간+지지)를 표시하는 위젯
/// 한글과 한자를 함께 표시
class PillarDisplay extends StatelessWidget {
  final Pillar pillar;
  final String label;
  final bool showLabel;
  final double size;
  final bool showHanja; // 한자 표시 여부

  const PillarDisplay({
    super.key,
    required this.pillar,
    required this.label,
    this.showLabel = true,
    this.size = 24.0,
    this.showHanja = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    final locale = context.locale.languageCode;
    final ganHanja = cheonganHanja[pillar.gan] ?? '';
    final jiHanja = jijiHanja[pillar.ji] ?? '';
    // locale에 따라 한글 대신 로컬 표시명 사용 (en: Mu, ja: ぼ 등)
    final ganDisplay = SajuI18n.cheongan(pillar.gan, locale);
    final jiDisplay = SajuI18n.jiji(pillar.ji, locale);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showLabel) ...[
          Text(
            label,
            style: TextStyle(
              color: theme.textMuted,
              fontSize: 11,
              letterSpacing: 0.3,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
            maxLines: 5,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
        ],
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: size > 28 ? 30 : size > 24 ? 24 : 18,
            vertical: size > 28 ? 18 : size > 24 ? 14 : 12,
          ),
          decoration: BoxDecoration(
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
              color: theme.primaryColor.withOpacity(theme.isDark ? 0.1 : 0.15),
            ),
          ),
          child: Column(
            children: [
              // 천간
              _buildCharWithHanja(
                context,
                theme,
                displayName: ganDisplay,
                hanja: ganHanja,
                oheng: pillar.ganOheng,
                korean: pillar.gan,
              ),
              const SizedBox(height: 4),
              Container(
                width: 24,
                height: 1,
                color: theme.primaryColor.withOpacity(0.1),
              ),
              const SizedBox(height: 4),
              // 지지
              _buildCharWithHanja(
                context,
                theme,
                displayName: jiDisplay,
                hanja: jiHanja,
                oheng: pillar.jiOheng,
                korean: pillar.ji,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 큰 글씨 + 작은 글씨 표시
  /// CJK: 한자 큰 + 한글 작은, 나머지: 한글 큰 + locale명 작은
  Widget _buildCharWithHanja(
    BuildContext context,
    AppThemeExtension theme, {
    required String displayName, // locale별 이름 (Gap, Gye...)
    required String hanja,       // 한자 (甲, 癸...)
    required String oheng,
    required String korean,      // 원본 한글 (갑, 계...)
  }) {
    final color = _getOhengColor(theme, oheng);
    final locale = context.locale.languageCode;
    final isCjk = locale == 'ko' || locale == 'ja' || locale == 'zh';

    if (!showHanja || hanja.isEmpty) {
      return Text(
        displayName,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: size,
        ),
      );
    }

    final bigSize = size > 24 ? size : 22.0;
    final smallSize = bigSize * 0.45;
    final bigChar = isCjk ? hanja : korean;
    final smallChar = isCjk ? korean : displayName;
    final showSmall = bigChar != smallChar;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          bigChar,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w600,
            fontSize: bigSize,
          ),
        ),
        if (showSmall) ...[
          const SizedBox(height: 2),
          Text(
            smallChar,
            style: TextStyle(
              color: color.withOpacity(0.7),
              fontWeight: FontWeight.w500,
              fontSize: smallSize,
            ),
          ),
        ],
      ],
    );
  }

  Color _getOhengColor(AppThemeExtension theme, String oheng) {
    switch (oheng) {
      case '목':
        return theme.woodColor ?? const Color(0xFF7EDA98);
      case '화':
        return theme.fireColor ?? const Color(0xFFE87C7C);
      case '토':
        return theme.earthColor ?? const Color(0xFFD4A574);
      case '금':
        return theme.metalColor ?? const Color(0xFF708090);  // 슬레이트 그레이
      case '수':
        return theme.waterColor ?? const Color(0xFF7EB8DA);
      default:
        return theme.textPrimary;
    }
  }
}
