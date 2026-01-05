import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/constants/cheongan_jiji.dart';
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
    final ganHanja = cheonganHanja[pillar.gan] ?? '';
    final jiHanja = jijiHanja[pillar.ji] ?? '';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showLabel) ...[
          Text(
            label,
            style: TextStyle(
              color: theme.textMuted,
              fontSize: 10,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
        ],
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
              // 천간 (한자 + 한글)
              _buildCharWithHanja(
                context,
                theme,
                hangul: pillar.gan,
                hanja: ganHanja,
                oheng: pillar.ganOheng,
              ),
              const SizedBox(height: 4),
              // 구분선
              Container(
                width: 24,
                height: 1,
                color: theme.primaryColor.withOpacity(0.1),
              ),
              const SizedBox(height: 4),
              // 지지 (한자 + 한글)
              _buildCharWithHanja(
                context,
                theme,
                hangul: pillar.ji,
                hanja: jiHanja,
                oheng: pillar.jiOheng,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 한자와 한글을 함께 표시하는 위젯
  Widget _buildCharWithHanja(
    BuildContext context,
    AppThemeExtension theme, {
    required String hangul,
    required String hanja,
    required String oheng,
  }) {
    final color = _getOhengColor(theme, oheng);

    if (!showHanja || hanja.isEmpty) {
      // 한자 표시 안 함 - 한글만 표시
      return Text(
        hangul,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: size,
        ),
      );
    }

    // 한자 크기는 size를 기준으로, 한글은 그 절반 정도로
    final hanjaSize = size > 24 ? size : 22.0;
    final hangulSize = hanjaSize * 0.45;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 한자 (큰 글씨, 오행별 색상)
        Text(
          hanja,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w600,
            fontSize: hanjaSize,
          ),
        ),
        const SizedBox(height: 2),
        // 한글 (작은 글씨)
        Text(
          hangul,
          style: TextStyle(
            color: color.withOpacity(0.7),
            fontWeight: FontWeight.w500,
            fontSize: hangulSize,
          ),
        ),
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
        return theme.metalColor ?? const Color(0xFFE8E8E8);
      case '수':
        return theme.waterColor ?? const Color(0xFF7EB8DA);
      default:
        return theme.textPrimary;
    }
  }
}
