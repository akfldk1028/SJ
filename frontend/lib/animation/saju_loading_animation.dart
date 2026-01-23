import 'dart:math' as math;
import 'package:flutter/material.dart';

/// 사주팔자 8글자 로딩 애니메이션 (v2 - 역동적 + 모던)
/// - 8글자가 순차적으로 펄스하며 등장 (로딩 중에만 표시)
/// - Phase 완료 시 이 애니메이션은 사라지고 실제 내용 표시
/// - 오행 색상 + 글로우 + 파티클 효과
/// - 중앙 원형 배치 + 회전
class SajuLoadingAnimation extends StatefulWidget {
  final String? yearGan;
  final String? yearJi;
  final String? monthGan;
  final String? monthJi;
  final String? dayGan;
  final String? dayJi;
  final String? hourGan;
  final String? hourJi;
  final int currentPhase;
  final int totalPhases;
  final String? statusMessage;

  const SajuLoadingAnimation({
    super.key,
    this.yearGan,
    this.yearJi,
    this.monthGan,
    this.monthJi,
    this.dayGan,
    this.dayJi,
    this.hourGan,
    this.hourJi,
    this.currentPhase = 1,
    this.totalPhases = 4,
    this.statusMessage,
  });

  @override
  State<SajuLoadingAnimation> createState() => _SajuLoadingAnimationState();
}

class _SajuLoadingAnimationState extends State<SajuLoadingAnimation>
    with TickerProviderStateMixin {
  late AnimationController _sequenceController;
  late AnimationController _glowController;
  late AnimationController _rotateController;
  late AnimationController _pulseController;
  late AnimationController _particleController;

  final List<Animation<double>> _fadeAnimations = [];
  final List<Animation<double>> _scaleAnimations = [];

  @override
  void initState() {
    super.initState();

    // 순차 등장 애니메이션 (3초)
    _sequenceController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );

    // 글로우 효과 (반복)
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    // 전체 회전 효과 (느리게)
    _rotateController = AnimationController(
      duration: const Duration(seconds: 30),
      vsync: this,
    )..repeat();

    // 펄스 효과 (한자 강조)
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);

    // 파티클 애니메이션
    _particleController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat();

    // 8글자 각각의 fade/scale 애니메이션 생성
    for (int i = 0; i < 8; i++) {
      final start = i / 10;
      final end = (i + 2) / 10;

      _fadeAnimations.add(
        Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: _sequenceController,
            curve: Interval(start, end.clamp(0.0, 1.0), curve: Curves.easeOutBack),
          ),
        ),
      );

      _scaleAnimations.add(
        Tween<double>(begin: 0.3, end: 1.0).animate(
          CurvedAnimation(
            parent: _sequenceController,
            curve: Interval(start, end.clamp(0.0, 1.0), curve: Curves.elasticOut),
          ),
        ),
      );
    }

    _sequenceController.forward();
  }

  @override
  void dispose() {
    _sequenceController.dispose();
    _glowController.dispose();
    _rotateController.dispose();
    _pulseController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  /// 한자만 추출 (예: "갑(甲)" → "甲")
  String _extractHanja(String? text) {
    if (text == null || text.isEmpty) return '?';
    final match = RegExp(r'\(([^)]+)\)').firstMatch(text);
    return match?.group(1) ?? text.substring(0, 1);
  }

  /// 오행에 따른 색상 반환 (더 선명하게)
  Color _getOhengColor(String hanja) {
    const woodGan = ['甲', '乙'];
    const fireGan = ['丙', '丁'];
    const earthGan = ['戊', '己'];
    const metalGan = ['庚', '辛'];
    const waterGan = ['壬', '癸'];
    const woodJi = ['寅', '卯'];
    const fireJi = ['巳', '午'];
    const earthJi = ['辰', '戌', '丑', '未'];
    const metalJi = ['申', '酉'];
    const waterJi = ['亥', '子'];

    if (woodGan.contains(hanja) || woodJi.contains(hanja)) {
      return const Color(0xFF00E676); // 밝은 초록 - 木
    } else if (fireGan.contains(hanja) || fireJi.contains(hanja)) {
      return const Color(0xFFFF5252); // 밝은 빨강 - 火
    } else if (earthGan.contains(hanja) || earthJi.contains(hanja)) {
      return const Color(0xFFFFD740); // 밝은 노랑 - 土
    } else if (metalGan.contains(hanja) || metalJi.contains(hanja)) {
      return const Color(0xFFFFFFFF); // 흰색/금색 - 金
    } else if (waterGan.contains(hanja) || waterJi.contains(hanja)) {
      return const Color(0xFF40C4FF); // 밝은 파랑 - 水
    }
    return Colors.white70;
  }

  @override
  Widget build(BuildContext context) {
    final characters = [
      widget.yearGan, widget.monthGan, widget.dayGan, widget.hourGan,
      widget.yearJi, widget.monthJi, widget.dayJi, widget.hourJi,
    ];

    return Stack(
      children: [
        // 배경 파티클 효과
        _buildParticles(),

        // 메인 콘텐츠
        SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 상단 타이틀
              _buildTitle(),
              const SizedBox(height: 50),

              // 8글자 원형 배치
              _buildCircularCharacters(characters),

              const SizedBox(height: 50),

              // 진행 상황
              _buildProgressSection(),

              const SizedBox(height: 24),

              // 상태 메시지
              _buildStatusMessage(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTitle() {
    return AnimatedBuilder(
      animation: _glowController,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [
              Colors.white.withOpacity(0.6 + _glowController.value * 0.4),
              const Color(0xFFFFD740).withOpacity(0.6 + _glowController.value * 0.4),
              Colors.white.withOpacity(0.6 + _glowController.value * 0.4),
            ],
          ).createShader(bounds),
          child: const Text(
            '당신의 사주팔자',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w300,
              color: Colors.white,
              letterSpacing: 8,
            ),
          ),
        );
      },
    );
  }

  Widget _buildCircularCharacters(List<String?> characters) {
    return SizedBox(
      width: 320,
      height: 320,
      child: AnimatedBuilder(
        animation: _rotateController,
        builder: (context, child) {
          return Transform.rotate(
            angle: _rotateController.value * 2 * math.pi * 0.05,
            child: child,
          );
        },
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 중앙 원 (글로우)
            AnimatedBuilder(
              animation: _glowController,
              builder: (context, child) {
                return Container(
                  width: 120 + _glowController.value * 10,
                  height: 120 + _glowController.value * 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFFFFD740).withOpacity(0.3),
                        const Color(0xFFFFD740).withOpacity(0.1),
                        Colors.transparent,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFFD740).withOpacity(0.3 + _glowController.value * 0.2),
                        blurRadius: 30 + _glowController.value * 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      '命',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.white.withOpacity(0.8 + _glowController.value * 0.2),
                        shadows: [
                          Shadow(
                            color: const Color(0xFFFFD740).withOpacity(0.8),
                            blurRadius: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),

            // 8글자 원형 배치
            for (int i = 0; i < 8; i++)
              _buildCharacterOnCircle(characters[i], i),
          ],
        ),
      ),
    );
  }

  Widget _buildCharacterOnCircle(String? character, int index) {
    final hanja = _extractHanja(character);
    final color = _getOhengColor(hanja);

    // 원형 배치 각도 계산
    final angle = (index * 2 * math.pi / 8) - math.pi / 2;
    final radius = 130.0;
    final x = radius * math.cos(angle);
    final y = radius * math.sin(angle);

    return AnimatedBuilder(
      animation: Listenable.merge([_fadeAnimations[index], _scaleAnimations[index], _pulseController]),
      builder: (context, child) {
        final pulse = 1.0 + math.sin(_pulseController.value * 2 * math.pi + index * 0.5) * 0.08;

        return Transform.translate(
          offset: Offset(x, y),
          child: Opacity(
            opacity: _fadeAnimations[index].value.clamp(0.0, 1.0),
            child: Transform.scale(
              scale: _scaleAnimations[index].value * pulse,
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withOpacity(0.6),
                  border: Border.all(
                    color: color.withOpacity(0.8),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.5),
                      blurRadius: 15,
                      spreadRadius: 2,
                    ),
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    hanja,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: color,
                      shadows: [
                        Shadow(color: color, blurRadius: 10),
                        Shadow(color: color.withOpacity(0.5), blurRadius: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildParticles() {
    return AnimatedBuilder(
      animation: _particleController,
      builder: (context, child) {
        return CustomPaint(
          painter: _ParticlePainter(
            progress: _particleController.value,
            colors: [
              const Color(0xFF00E676), // 木
              const Color(0xFFFF5252), // 火
              const Color(0xFFFFD740), // 土
              const Color(0xFFFFFFFF), // 金
              const Color(0xFF40C4FF), // 水
            ],
          ),
          size: Size.infinite,
        );
      },
    );
  }

  Widget _buildProgressSection() {
    final progress = widget.currentPhase / widget.totalPhases;

    return Column(
      children: [
        // 진행률 바
        Container(
          width: 200,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(2),
          ),
          child: AnimatedBuilder(
            animation: _glowController,
            builder: (context, child) {
              return FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: progress,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF00E676),
                        const Color(0xFFFFD740),
                        const Color(0xFFFF5252),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(2),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFFD740).withOpacity(0.5),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),

        // Phase 표시
        Text(
          'PHASE ${widget.currentPhase} / ${widget.totalPhases}',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.white.withOpacity(0.5),
            letterSpacing: 4,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusMessage() {
    if (widget.statusMessage == null) return const SizedBox.shrink();

    return AnimatedBuilder(
      animation: _glowController,
      builder: (context, child) {
        return Text(
          widget.statusMessage!,
          style: TextStyle(
            fontSize: 14,
            color: Colors.white.withOpacity(0.4 + _glowController.value * 0.3),
            letterSpacing: 1,
          ),
          textAlign: TextAlign.center,
        );
      },
    );
  }
}

/// 파티클 페인터 (배경 효과)
class _ParticlePainter extends CustomPainter {
  final double progress;
  final List<Color> colors;
  final int particleCount = 20;

  _ParticlePainter({required this.progress, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(42); // 고정 시드로 일관된 패턴

    for (int i = 0; i < particleCount; i++) {
      final baseX = random.nextDouble() * size.width;
      final baseY = random.nextDouble() * size.height;
      final speed = 0.3 + random.nextDouble() * 0.7;
      final radius = 1.5 + random.nextDouble() * 2.5;
      final colorIndex = i % colors.length;

      // 위로 올라가는 애니메이션
      final y = (baseY - (progress * speed * size.height)) % size.height;
      final opacity = 0.1 + math.sin((progress + i * 0.1) * math.pi * 2) * 0.15;

      final paint = Paint()
        ..color = colors[colorIndex].withOpacity(opacity.clamp(0.0, 0.3))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

      canvas.drawCircle(Offset(baseX, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
