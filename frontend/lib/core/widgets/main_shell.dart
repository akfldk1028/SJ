import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'main_bottom_nav.dart';

/// 메인 쉘 - 네비게이션 바를 공유하는 레이아웃
class MainShell extends StatelessWidget {
  final Widget child;
  final int currentIndex;

  const MainShell({
    super.key,
    required this.child,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      body: child,
      bottomNavigationBar: MainBottomNav(currentIndex: currentIndex),
    );
  }
}
