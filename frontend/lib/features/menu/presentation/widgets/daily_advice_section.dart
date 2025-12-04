import 'package:flutter/material.dart';
import '../../data/mock/mock_fortune_data.dart';
import '../../../../core/theme/app_theme.dart';

/// Daily advice section - 테마 적용 (테마별 운세)
class DailyAdviceSection extends StatelessWidget {
  const DailyAdviceSection({super.key});

  @override
  Widget build(BuildContext context) {
    final appTheme = context.appTheme;

    // 테마별 카드 색상 조정
    final themes = [
      {'title': '2025\n신년운세', 'color': appTheme.isDark ? const Color(0xFF4A3C2A) : const Color(0xFFFFE4C4)},
      {'title': '2025\n토정비결', 'color': appTheme.isDark ? const Color(0xFF3D3225) : const Color(0xFFE8D5B7)},
      {'title': '타로\n운세', 'color': appTheme.isDark ? const Color(0xFF3A3A2D) : const Color(0xFFF5F5DC)},
      {'title': '꿈해몽', 'color': appTheme.isDark ? const Color(0xFF2E2E3D) : const Color(0xFFE6E6FA)},
    ];

    return SizedBox(
      height: 140,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: themes.length,
        itemBuilder: (context, index) {
          final theme = themes[index];
          return _buildThemeCard(
            context,
            theme['title'] as String,
            theme['color'] as Color,
            isLast: index == themes.length - 1,
          );
        },
      ),
    );
  }

  Widget _buildThemeCard(BuildContext context, String title, Color bgColor, {required bool isLast}) {
    final appTheme = context.appTheme;

    return Padding(
      padding: EdgeInsets.only(right: isLast ? 0 : 12),
      child: Container(
        width: 110,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: appTheme.isDark
                  ? Colors.black.withOpacity(0.3)
                  : Colors.black.withOpacity(0.06),
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
                      color: appTheme.isDark
                          ? Colors.white.withOpacity(0.1)
                          : Colors.white.withOpacity(0.5),
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
      ),
    );
  }
}
