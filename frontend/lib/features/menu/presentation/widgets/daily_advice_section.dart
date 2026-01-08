import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

/// Daily advice section - 테마 적용 (테마별 운세)
/// ⚡ 성능 최적화: withOpacity → const Color 캐싱
class DailyAdviceSection extends StatelessWidget {
  const DailyAdviceSection({super.key});

  // ⚡ 캐싱된 색상 상수
  static const _shadowLight = Color.fromRGBO(0, 0, 0, 0.06);
  static const _shadowDark = Color.fromRGBO(0, 0, 0, 0.3);
  static const _iconBgLight = Color.fromRGBO(255, 255, 255, 0.5);
  static const _iconBgDark = Color.fromRGBO(255, 255, 255, 0.1);

  @override
  Widget build(BuildContext context) {
    final appTheme = context.appTheme;

    // 테마별 카드 색상 조정 (타로운세, 꿈해몽 비활성화)
    final themes = [
      {'title': '2025\n신년운세', 'color': appTheme.isDark ? const Color(0xFF4A3C2A) : const Color(0xFFFFE4C4)},
      {'title': '2025\n토정비결', 'color': appTheme.isDark ? const Color(0xFF3D3225) : const Color(0xFFE8D5B7)},
      // {'title': '타로\n운세', 'color': appTheme.isDark ? const Color(0xFF3A3A2D) : const Color(0xFFF5F5DC)},
      // {'title': '꿈해몽', 'color': appTheme.isDark ? const Color(0xFF2E2E3D) : const Color(0xFFE6E6FA)},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: themes.asMap().entries.map((entry) {
          final index = entry.key;
          final theme = entry.value;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: index < themes.length - 1 ? 12 : 0),
              child: _buildThemeCard(
                context,
                theme['title'] as String,
                theme['color'] as Color,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildThemeCard(BuildContext context, String title, Color bgColor) {
    final appTheme = context.appTheme;

    return Container(
      height: 140,
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
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: appTheme.isDark ? Colors.white : const Color(0xFF1A1A1A),
                    height: 1.4,
                  ),
                ),
                const Spacer(),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: appTheme.isDark ? _iconBgDark : _iconBgLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.auto_awesome,
                    size: 20,
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
