import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../ad/ad.dart';
import '../../../../purchase/providers/purchase_provider.dart';
import '../../../../router/routes.dart';

class MainScaffold extends ConsumerWidget {
  final Widget child;

  const MainScaffold({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: child,
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 하단 네비게이션 바
          BottomNavigationBar(
            currentIndex: _calculateSelectedIndex(context),
            onTap: (index) => _onTap(context, ref, index),
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

  void _onTap(BuildContext context, WidgetRef ref, int index) async {
    switch (index) {
      case 0:
        context.go(Routes.home);
        break;
      case 1:
        context.go(Routes.relationshipList);
        break;
      case 2:
        // 프리미엄 유저는 광고 스킵
        final isPremium = ref.read(purchaseNotifierProvider.notifier).isPremium;
        if (!isPremium) {
          await AdService.instance.showInterstitialAd();
        }
        if (context.mounted) {
          context.go(Routes.sajuChat);
        }
        break;
    }
  }
}
