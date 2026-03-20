import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// 메뉴 아이템 타입
enum MenuType {
  dailyFortune,
  sajuAnalysis,
  compatibility,
  history,
}

/// 메뉴 아이템 모델
class MenuItem {
  final MenuType type;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String? imagePath;

  const MenuItem({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.imagePath,
  });

  /// 사주 앱 메뉴 목록
  static List<MenuItem> get menuList => [
    MenuItem(
      type: MenuType.dailyFortune,
      title: 'menu.menuDailyFortune'.tr(),
      subtitle: 'menu.menuDailyFortuneSubtitle'.tr(),
      icon: Icons.wb_sunny_outlined,
      color: const Color(0xFFFF9800),
    ),
    MenuItem(
      type: MenuType.sajuAnalysis,
      title: 'menu.menuSajuAnalysis'.tr(),
      subtitle: 'menu.menuSajuAnalysisSubtitle'.tr(),
      icon: Icons.auto_awesome,
      color: const Color(0xFF9C27B0),
    ),
    MenuItem(
      type: MenuType.compatibility,
      title: 'menu.menuCompatibility'.tr(),
      subtitle: 'menu.menuCompatibilitySubtitle'.tr(),
      icon: Icons.favorite_outline,
      color: const Color(0xFFE91E63),
    ),
    MenuItem(
      type: MenuType.history,
      title: 'menu.menuHistory'.tr(),
      subtitle: 'menu.menuHistorySubtitle'.tr(),
      icon: Icons.history,
      color: const Color(0xFF607D8B),
    ),
  ];
}
