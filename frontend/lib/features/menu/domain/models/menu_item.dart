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
  static const List<MenuItem> menuList = [
    MenuItem(
      type: MenuType.dailyFortune,
      title: '오늘의 운세',
      subtitle: '오늘 하루 운세를 확인해보세요',
      icon: Icons.wb_sunny_outlined,
      color: Color(0xFFFF9800),
    ),
    MenuItem(
      type: MenuType.sajuAnalysis,
      title: '사주 분석',
      subtitle: '나의 사주팔자를 분석합니다',
      icon: Icons.auto_awesome,
      color: Color(0xFF9C27B0),
    ),
    MenuItem(
      type: MenuType.compatibility,
      title: '궁합 보기',
      subtitle: '상대방과의 궁합을 알아보세요',
      icon: Icons.favorite_outline,
      color: Color(0xFFE91E63),
    ),
    MenuItem(
      type: MenuType.history,
      title: '상담 내역',
      subtitle: '이전 상담 기록을 확인합니다',
      icon: Icons.history,
      color: Color(0xFF607D8B),
    ),
  ];
}
