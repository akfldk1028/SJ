import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../ad/ad.dart';
import '../../../../router/routes.dart';

class MainScaffold extends StatelessWidget {
  final Widget child;

  const MainScaffold({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 배너 광고 (Web 제외)
          if (!kIsWeb) const BannerAdWidget(),
          // 하단 네비게이션 바
          BottomNavigationBar(
            currentIndex: _calculateSelectedIndex(context),
            onTap: (index) => _onTap(context, index),
            type: BottomNavigationBarType.fixed,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.auto_awesome_outlined),
                activeIcon: Icon(Icons.auto_awesome),
                label: '내 운세',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.people_outline),
                activeIcon: Icon(Icons.people),
                label: '인연',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.chat_bubble_outline),
                activeIcon: Icon(Icons.chat_bubble),
                label: '상담소',
              ),
            ],
          ),
        ],
      ),
    );
  }

  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.path;
    if (location.startsWith(Routes.relationshipList)) {
      return 1;
    }
    if (location.startsWith(Routes.sajuChat)) {
      return 2;
    }
    return 0; // Home
  }

  void _onTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go(Routes.home);
        break;
      case 1:
        context.go(Routes.relationshipList);
        break;
      case 2:
        context.go(Routes.sajuChat);
        break;
    }
  }
}
