import 'package:flutter/material.dart';
import '../../domain/models/menu_item.dart';

/// 메뉴 카드 위젯 - 글래스모피즘 효과
///
/// 위젯 트리 최적화:
/// - const 생성자 사용
/// - 100줄 이하 유지
/// - 애니메이션은 별도 처리
class MenuCard extends StatelessWidget {
  final MenuItem menuItem;
  final VoidCallback onTap;
  final Animation<double> animation;

  const MenuCard({
    super.key,
    required this.menuItem,
    required this.onTap,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return FadeTransition(
          opacity: animation,
          child: Transform.translate(
            offset: Offset(0, 50 * (1.0 - animation.value)),
            child: Transform.scale(
              scale: 0.8 + (0.2 * animation.value),
              child: child,
            ),
          ),
        );
      },
      child: _MenuCardContent(
        menuItem: menuItem,
        onTap: onTap,
      ),
    );
  }
}

/// 메뉴 카드 내용 - 글래스모피즘 디자인
class _MenuCardContent extends StatefulWidget {
  final MenuItem menuItem;
  final VoidCallback onTap;

  const _MenuCardContent({
    required this.menuItem,
    required this.onTap,
  });

  @override
  State<_MenuCardContent> createState() => _MenuCardContentState();
}

class _MenuCardContentState extends State<_MenuCardContent> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                widget.menuItem.color.withOpacity(0.3),
                widget.menuItem.color.withOpacity(0.1),
              ],
            ),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.menuItem.color.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 아이콘
                _MenuIcon(
                  icon: widget.menuItem.icon,
                  color: widget.menuItem.color,
                ),
                const SizedBox(height: 16),
                // 타이틀
                Text(
                  widget.menuItem.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: -0.3,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                // 서브타이틀
                Text(
                  widget.menuItem.subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.8),
                    height: 1.3,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 메뉴 아이콘 위젯
class _MenuIcon extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _MenuIcon({
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.8),
            color.withOpacity(0.5),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.4),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Icon(
        icon,
        size: 32,
        color: Colors.white,
      ),
    );
  }
}
