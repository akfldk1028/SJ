import 'dart:math';
import 'package:flutter/material.dart';
import 'zodiac_animal_avatar.dart';

/// 수호동물 공개 애니메이션
///
/// "잠깐, 너의 수호신을 불러올게..." → 파티클 + 색 전환 → 내 동물 등장!
/// Apple 리뷰어에게 WOW 모먼트를 줄 핵심 장면.
class ZodiacRevealAnimation extends StatefulWidget {
  /// 공개될 동물 이모지
  final String animalEmoji;

  /// 동물 이름 (예: "흰 호랑이")
  final String fullName;

  /// 간지 한자 (예: "庚寅")
  final String ganjiHanja;

  /// 동물 테마 색상
  final Color themeColor;

  /// 오행 이름 (배경 전환용)
  final String elementName;

  /// 이미지 URL (Supabase Storage)
  final String? imageUrl;

  /// 완료 콜백
  final VoidCallback? onComplete;

  const ZodiacRevealAnimation({
    super.key,
    required this.animalEmoji,
    required this.fullName,
    required this.ganjiHanja,
    required this.themeColor,
    this.elementName = '화',
    this.imageUrl,
    this.onComplete,
  });

  @override
  State<ZodiacRevealAnimation> createState() => _ZodiacRevealAnimationState();
}

class _ZodiacRevealAnimationState extends State<ZodiacRevealAnimation>
    with TickerProviderStateMixin {
  late AnimationController _sequenceController;
  late Animation<double> _fadeIn;
  late Animation<double> _scaleUp;
  late Animation<double> _particleFade;
  late Animation<double> _textFade;

  // 파티클 데이터
  final List<_Particle> _particles = [];
  final _random = Random();

  @override
  void initState() {
    super.initState();

    // 파티클 생성
    for (int i = 0; i < 30; i++) {
      _particles.add(_Particle(
        angle: _random.nextDouble() * 2 * pi,
        speed: 50 + _random.nextDouble() * 150,
        size: 3 + _random.nextDouble() * 5,
        delay: _random.nextDouble() * 0.3,
      ));
    }

    _sequenceController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );

    // 0.0~0.3: 파티클 폭발
    _particleFade = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _sequenceController,
        curve: const Interval(0.2, 0.6, curve: Curves.easeOut),
      ),
    );

    // 0.2~0.6: 동물 등장
    _fadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _sequenceController,
        curve: const Interval(0.25, 0.55, curve: Curves.easeOut),
      ),
    );

    _scaleUp = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(
        parent: _sequenceController,
        curve: const Interval(0.25, 0.6, curve: Curves.elasticOut),
      ),
    );

    // 0.6~0.9: 텍스트 등장
    _textFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _sequenceController,
        curve: const Interval(0.6, 0.85, curve: Curves.easeOut),
      ),
    );

    _sequenceController.forward().then((_) {
      Future.delayed(const Duration(milliseconds: 500), () {
        widget.onComplete?.call();
      });
    });
  }

  @override
  void dispose() {
    _sequenceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _sequenceController,
      builder: (context, _) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // 파티클 레이어
            ..._particles.map((p) {
              final t = (_sequenceController.value - p.delay).clamp(0.0, 1.0);
              final distance = p.speed * t;
              final dx = cos(p.angle) * distance;
              final dy = sin(p.angle) * distance;

              return Positioned(
                left: MediaQuery.of(context).size.width / 2 + dx - p.size / 2,
                top: MediaQuery.of(context).size.height / 2 + dy - p.size / 2 - 50,
                child: Opacity(
                  opacity: (_particleFade.value * (1 - t)).clamp(0.0, 1.0),
                  child: Container(
                    width: p.size,
                    height: p.size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.themeColor,
                      boxShadow: [
                        BoxShadow(
                          color: widget.themeColor.withAlpha(150),
                          blurRadius: p.size * 2,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),

            // 메인 콘텐츠 (동물 + 텍스트)
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 동물 아바타
                Opacity(
                  opacity: _fadeIn.value,
                  child: Transform.scale(
                    scale: _scaleUp.value,
                    child: ZodiacAnimalAvatar(
                      emoji: widget.animalEmoji,
                      imageUrl: widget.imageUrl,
                      size: 140,
                      glowColor: widget.themeColor,
                      animate: false,
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // 이름 텍스트
                Opacity(
                  opacity: _textFade.value,
                  child: Column(
                    children: [
                      Text(
                        widget.fullName,
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              color: widget.themeColor.withAlpha(150),
                              blurRadius: 20,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.ganjiHanja,
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white.withAlpha(150),
                          letterSpacing: 8,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _Particle {
  final double angle;
  final double speed;
  final double size;
  final double delay;

  const _Particle({
    required this.angle,
    required this.speed,
    required this.size,
    required this.delay,
  });
}
