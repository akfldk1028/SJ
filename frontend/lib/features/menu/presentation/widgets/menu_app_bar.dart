import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// 메뉴 화면 앱바 - 모던 디자인
///
/// 위젯 트리 최적화:
/// - const 생성자 사용
/// - 작은 위젯으로 분리
/// - 애니메이션 적용
class MenuAppBar extends StatelessWidget {
  final AnimationController animationController;

  const MenuAppBar({
    super.key,
    required this.animationController,
  });

  @override
  Widget build(BuildContext context) {
    final topBarAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: animationController,
        curve: const Interval(0, 0.2, curve: Curves.fastOutSlowIn),
      ),
    );

    return AnimatedBuilder(
      animation: topBarAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, -50 * (1.0 - topBarAnimation.value)),
          child: Opacity(
            opacity: topBarAnimation.value,
            child: child,
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // 로고 + 타이틀
            const _AppTitle(),
            // 설정 버튼
            IconButton(
              icon: const Icon(
                Icons.settings_outlined,
                color: Colors.white70,
                size: 24,
              ),
              onPressed: () {
                // TODO: 설정 화면으로 이동
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// 앱 타이틀 위젯
/// ⚡ 성능 최적화: withOpacity → const Color 캐싱
class _AppTitle extends StatelessWidget {
  // ⚡ 캐싱된 색상 상수
  static const _shadowColor = Color.fromRGBO(126, 87, 194, 0.4);

  const _AppTitle();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // 로고 아이콘
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFF7E57C2), // 딥 퍼플
                Color(0xFF5C6BC0), // 인디고
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(
                color: _shadowColor,
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(
            Icons.auto_awesome,
            color: Colors.white,
            size: 22,
          ),
        ),
        const SizedBox(width: 12),
        // 타이틀
        Text(
          'menu.appTitle'.tr(),
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }
}
