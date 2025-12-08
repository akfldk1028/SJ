import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

/// Fortune category grid - 테마 적용 (정통운세 그리드)
class FortuneCategoryList extends StatelessWidget {
  const FortuneCategoryList({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;

    final categories = [
      {'name': '정통사주', 'icon': Icons.menu_book_rounded},
      {'name': '정통궁합', 'icon': Icons.favorite_rounded},
      {'name': '삼풍이', 'icon': Icons.notifications_rounded},
      {'name': '취업운세', 'icon': Icons.work_rounded},
      {'name': '능력평가', 'icon': Icons.bar_chart_rounded},
      {'name': '연예인궁합', 'icon': Icons.star_rounded},
      {'name': '관상', 'icon': Icons.face_rounded},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: theme.isDark
                  ? Colors.black.withOpacity(0.3)
                  : Colors.black.withOpacity(0.06),
              offset: const Offset(0, 4),
              blurRadius: 16,
            ),
          ],
        ),
        child: Wrap(
          spacing: 16,
          runSpacing: 20,
          alignment: WrapAlignment.start,
          children: categories.map((category) => _buildCategoryItem(
            context,
            category['name'] as String,
            category['icon'] as IconData,
          )).toList(),
        ),
      ),
    );
  }

  Widget _buildCategoryItem(BuildContext context, String name, IconData icon) {
    final theme = context.appTheme;

    return SizedBox(
      width: 70,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: theme.isDark
                  ? theme.primaryColor.withOpacity(0.15)
                  : theme.backgroundColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icon,
              size: 28,
              color: theme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            name,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: theme.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
