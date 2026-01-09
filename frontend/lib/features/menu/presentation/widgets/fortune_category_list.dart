import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';

/// Fortune category grid - 테마 적용 (정통운세 그리드)
/// ⚡ 성능 최적화: withOpacity → const Color 캐싱
class FortuneCategoryList extends StatelessWidget {
  const FortuneCategoryList({super.key});

  // ⚡ 캐싱된 색상 상수
  static const _shadowLight = Color.fromRGBO(0, 0, 0, 0.06);
  static const _shadowDark = Color.fromRGBO(0, 0, 0, 0.3);

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;

    final categories = [
      {'name': '정통사주', 'icon': Icons.menu_book_rounded, 'route': '/fortune/traditional-saju'},
      {'name': '정통궁합', 'icon': Icons.favorite_rounded, 'route': '/fortune/compatibility'},
      {'name': '신년운세', 'icon': Icons.auto_awesome_rounded, 'route': '/fortune/new-year'},
      {'name': '오늘운세', 'icon': Icons.wb_sunny_rounded, 'route': '/fortune/daily'},
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
              color: theme.isDark ? _shadowDark : _shadowLight,
              offset: const Offset(0, 4),
              blurRadius: 16,
            ),
          ],
        ),
        child: Row(
          children: categories.map((category) {
            return Expanded(
              child: _buildCategoryItem(
                context,
                category['name'] as String,
                category['icon'] as IconData,
                category['route'] as String,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildCategoryItem(BuildContext context, String name, IconData icon, String route) {
    final theme = context.appTheme;

    return GestureDetector(
      onTap: () => context.push(route),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: theme.isDark
                  ? theme.primaryColor.withValues(alpha: 0.15)
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
