import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

/// 커스텀 Bottom Navigation Bar - Curved 디자인
///
/// 위젯 트리 최적화:
/// - const 생성자 사용
/// - 작은 위젯으로 분리
/// - 테마 시스템 사용
class BottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const BottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _BottomNavItem(
                icon: Icons.home_rounded,
                label: 'menu.bottomHome'.tr(),
                isSelected: selectedIndex == 0,
                onTap: () => onTap(0),
                theme: theme,
              ),
              _BottomNavItem(
                icon: Icons.person_rounded,
                label: 'menu.bottomProfile'.tr(),
                isSelected: selectedIndex == 1,
                onTap: () => onTap(1),
                theme: theme,
              ),
              _BottomNavItem(
                icon: Icons.history_rounded,
                label: 'menu.bottomHistory'.tr(),
                isSelected: selectedIndex == 2,
                onTap: () => onTap(2),
                theme: theme,
              ),
              _BottomNavItem(
                icon: Icons.settings_rounded,
                label: 'menu.bottomSettings'.tr(),
                isSelected: selectedIndex == 3,
                onTap: () => onTap(3),
                theme: theme,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bottom Nav 아이템
class _BottomNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final AppThemeExtension theme;

  const _BottomNavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.fastOutSlowIn,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 16 : 12,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.primaryColor.withValues(alpha: 0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: isSelected
              ? Border.all(
                  color: theme.primaryColor.withValues(alpha: 0.5),
                  width: 1.5,
                )
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? theme.primaryColor
                  : theme.textMuted,
              size: 24,
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: theme.primaryColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
