import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../ad/ad_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive_utils.dart';

/// Fortune category grid - 테마 적용 (정통운세 그리드)
class FortuneCategoryList extends StatelessWidget {
  const FortuneCategoryList({super.key});

  static const _shadowLight = Color.fromRGBO(0, 0, 0, 0.06);
  static const _shadowDark = Color.fromRGBO(0, 0, 0, 0.3);

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    final scale = context.scaleFactor;

    final categories = [
      {'name': '평생운세', 'icon': Icons.menu_book_rounded, 'route': '/fortune/traditional-saju'},
      {'name': '2025운세', 'icon': Icons.history_rounded, 'route': '/fortune/yearly-2025'},  // 회고/돌아보기
      {'name': '2026운세', 'icon': Icons.flare_rounded, 'route': '/fortune/new-year'},  // 신년/새빛
      {'name': '한달운세', 'icon': Icons.calendar_month_rounded, 'route': '/fortune/monthly'},
    ];

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: context.scaledPadding(20)),
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: context.scaledPadding(20),
          horizontal: context.scaledPadding(16),
        ),
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
                scale,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildCategoryItem(BuildContext context, String name, IconData icon, String route, double scale) {
    final theme = context.appTheme;
    final boxSize = (56 * scale).clamp(48.0, 72.0);
    final iconSize = context.scaledIcon(28);
    final fontSize = context.scaledFont(12);

    return GestureDetector(
      onTap: () async {
        // 전면광고 표시 후 페이지 이동
        await AdService.instance.showInterstitialAd();
        if (context.mounted) {
          context.push(route);
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: boxSize,
            height: boxSize,
            decoration: BoxDecoration(
              color: theme.isDark
                  ? theme.primaryColor.withValues(alpha: 0.15)
                  : theme.backgroundColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icon,
              size: iconSize,
              color: theme.textSecondary,
            ),
          ),
          SizedBox(height: context.scaledPadding(8)),
          Text(
            name,
            style: TextStyle(
              fontSize: fontSize,
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
