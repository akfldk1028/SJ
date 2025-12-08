import 'package:flutter/material.dart';
import '../../domain/models/menu_item.dart';
import 'menu_card.dart';

/// 메뉴 그리드 위젯
///
/// 위젯 트리 최적화:
/// - GridView.builder 사용 (Lazy Loading)
/// - 애니메이션 컨트롤러는 상위에서 관리
class MenuGrid extends StatelessWidget {
  final AnimationController animationController;
  final void Function(MenuItem menuItem) onMenuTap;

  const MenuGrid({
    super.key,
    required this.animationController,
    required this.onMenuTap,
  });

  @override
  Widget build(BuildContext context) {
    const menuList = MenuItem.menuList;

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      physics: const BouncingScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 20,
        crossAxisSpacing: 20,
        childAspectRatio: 0.95,
      ),
      itemCount: menuList.length,
      itemBuilder: (context, index) {
        final menuItem = menuList[index];
        final animation = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: animationController,
            curve: Interval(
              0.2 + (0.1 * index),
              0.4 + (0.1 * index),
              curve: Curves.fastOutSlowIn,
            ),
          ),
        );

        return MenuCard(
          key: ValueKey(menuItem.type),
          menuItem: menuItem,
          animation: animation,
          onTap: () => onMenuTap(menuItem),
        );
      },
    );
  }
}
