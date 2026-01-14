import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive_utils.dart';

/// Daily advice section - 테마 적용 (테마별 운세)
class DailyAdviceSection extends StatelessWidget {
  const DailyAdviceSection({super.key});

  static const _shadowLight = Color.fromRGBO(0, 0, 0, 0.06);
  static const _shadowDark = Color.fromRGBO(0, 0, 0, 0.3);
  static const _iconBgLight = Color.fromRGBO(255, 255, 255, 0.5);
  static const _iconBgDark = Color.fromRGBO(255, 255, 255, 0.1);

  @override
  Widget build(BuildContext context) {
    final appTheme = context.appTheme;
    final scale = context.scaleFactor;

    final themes = [
      {
        'title': '2025\n신년운세',
        'color': appTheme.isDark ? const Color(0xFF4A3C2A) : const Color(0xFFFFE4C4),
        'route': '/fortune/new-year',
      },
      {
        'title': '2025\n토정비결',
        'color': appTheme.isDark ? const Color(0xFF3D3225) : const Color(0xFFE8D5B7),
        'route': '/fortune/traditional-saju',
      },
    ];

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: context.scaledPadding(20)),
      child: Row(
        children: themes.asMap().entries.map((entry) {
          final index = entry.key;
          final theme = entry.value;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: index < themes.length - 1 ? context.scaledPadding(12) : 0),
              child: _buildThemeCard(
                context,
                theme['title'] as String,
                theme['color'] as Color,
                theme['route'] as String,
                scale,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildThemeCard(BuildContext context, String title, Color bgColor, String route, double scale) {
    final appTheme = context.appTheme;
    final cardHeight = (140 * scale).clamp(120.0, 180.0);
    final fontSize = context.scaledFont(14);
    final iconBoxSize = (40 * scale).clamp(36.0, 52.0);
    final iconSize = context.scaledIcon(20);

    return Container(
      height: cardHeight,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: appTheme.isDark ? _shadowDark : _shadowLight,
            offset: const Offset(0, 4),
            blurRadius: 12,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => context.push(route),
          child: Padding(
            padding: EdgeInsets.all(context.scaledPadding(16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.w600,
                    color: appTheme.isDark ? Colors.white : const Color(0xFF1A1A1A),
                    height: 1.4,
                  ),
                ),
                const Spacer(),
                Container(
                  width: iconBoxSize,
                  height: iconBoxSize,
                  decoration: BoxDecoration(
                    color: appTheme.isDark ? _iconBgDark : _iconBgLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.auto_awesome,
                    size: iconSize,
                    color: appTheme.primaryColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
