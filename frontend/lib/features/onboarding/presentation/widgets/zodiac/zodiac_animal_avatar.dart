import 'package:flutter/material.dart';

/// 십이지신 동물 아바타 위젯
///
/// 큰 이모지 + 색상 글로우 + 호흡 애니메이션으로
/// 살아있는 느낌의 동물 캐릭터를 표현합니다.
///
/// 나중에 Lottie/Rive 에셋으로 교체 가능하도록 설계.
class ZodiacAnimalAvatar extends StatefulWidget {
  /// 동물 이모지 (🐴, 🐭 등)
  final String emoji;

  /// 아바타 크기
  final double size;

  /// 글로우 색상 (오행 색)
  final Color glowColor;

  /// 등장 애니메이션 여부
  final bool animate;

  /// 호흡(idle) 애니메이션 여부
  final bool breathing;

  const ZodiacAnimalAvatar({
    super.key,
    required this.emoji,
    this.size = 120,
    this.glowColor = Colors.orange,
    this.animate = true,
    this.breathing = true,
  });

  @override
  State<ZodiacAnimalAvatar> createState() => _ZodiacAnimalAvatarState();
}

class _ZodiacAnimalAvatarState extends State<ZodiacAnimalAvatar>
    with TickerProviderStateMixin {
  late AnimationController _entranceController;
  late AnimationController _breathController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _breathAnimation;

  @override
  void initState() {
    super.initState();

    // 등장 애니메이션
    _entranceController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: Curves.elasticOut,
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    // 호흡 애니메이션
    _breathController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _breathAnimation = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(
        parent: _breathController,
        curve: Curves.easeInOut,
      ),
    );

    if (widget.animate) {
      _entranceController.forward().then((_) {
        if (widget.breathing && mounted) {
          _breathController.repeat(reverse: true);
        }
      });
    } else {
      _entranceController.value = 1.0;
      if (widget.breathing) {
        _breathController.repeat(reverse: true);
      }
    }
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _breathController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_entranceController, _breathController]),
      builder: (context, child) {
        final breathScale = widget.breathing ? _breathAnimation.value : 1.0;

        return Opacity(
          opacity: _fadeAnimation.value,
          child: Transform.scale(
            scale: _scaleAnimation.value * breathScale,
            child: child,
          ),
        );
      },
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: widget.glowColor.withAlpha(60),
              blurRadius: widget.size * 0.4,
              spreadRadius: widget.size * 0.1,
            ),
            BoxShadow(
              color: widget.glowColor.withAlpha(30),
              blurRadius: widget.size * 0.8,
              spreadRadius: widget.size * 0.2,
            ),
          ],
        ),
        child: Center(
          child: Text(
            widget.emoji,
            style: TextStyle(fontSize: widget.size * 0.6),
          ),
        ),
      ),
    );
  }
}

/// 채팅 버블용 작은 아바타
class ZodiacSmallAvatar extends StatelessWidget {
  final String emoji;
  final Color glowColor;
  final double size;

  const ZodiacSmallAvatar({
    super.key,
    required this.emoji,
    this.glowColor = Colors.orange,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: glowColor.withAlpha(30),
        border: Border.all(
          color: glowColor.withAlpha(80),
          width: 1.5,
        ),
      ),
      child: Center(
        child: Text(emoji, style: TextStyle(fontSize: size * 0.55)),
      ),
    );
  }
}
