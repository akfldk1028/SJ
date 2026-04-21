import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// 십이지신 동물 아바타 위젯
///
/// Supabase Storage 이미지 → 로컬 에셋 → 이모지 순서로 렌더.
/// 4중 애니메이션으로 살아있는 느낌:
///   - 등장: scale 0→1 (elasticOut) + fade
///   - 호흡: scale 1.0↔1.06 (2s)
///   - 떠다님: translateY ±3% (3s) — 둥둥 떠있는 느낌
///   - 흔들림: rotation ±1.5° (4s) — 미세한 기울임
///
/// 주기가 다르므로 합치면 유기적·비기계적 움직임.
class ZodiacAnimalAvatar extends StatefulWidget {
  /// 동물 이모지 (fallback)
  final String emoji;

  /// Supabase Storage 이미지 URL (우선)
  final String? imageUrl;

  /// 로컬 에셋 경로 (오프라인 fallback)
  final String? localAsset;

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
    this.imageUrl,
    this.localAsset,
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
  // ── 등장 ──
  late AnimationController _entranceController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  // ── idle: 호흡 (2s) ──
  late AnimationController _breathController;
  late Animation<double> _breathAnimation;

  // ── idle: 떠다님 (3s) ──
  late AnimationController _floatController;
  late Animation<double> _floatAnimation;

  // ── idle: 흔들림 (4s) ──
  late AnimationController _tiltController;
  late Animation<double> _tiltAnimation;

  @override
  void initState() {
    super.initState();

    // 등장: scale 0→1 + fade
    _entranceController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entranceController, curve: Curves.elasticOut),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    // 호흡: scale 1.0↔1.06 (2s)
    _breathController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _breathAnimation = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _breathController, curve: Curves.easeInOut),
    );

    // 떠다님: Y축 ±3% of size (3s)
    final floatPx = widget.size * 0.03;
    _floatController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );
    _floatAnimation = Tween<double>(begin: -floatPx, end: floatPx).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    // 흔들림: ±0.025 rad ≈ ±1.4° (4s)
    _tiltController = AnimationController(
      duration: const Duration(milliseconds: 4000),
      vsync: this,
    );
    _tiltAnimation = Tween<double>(begin: -0.025, end: 0.025).animate(
      CurvedAnimation(parent: _tiltController, curve: Curves.easeInOut),
    );

    if (widget.animate) {
      _entranceController.forward().then((_) {
        if (widget.breathing && mounted) _startIdle();
      });
    } else {
      _entranceController.value = 1.0;
      if (widget.breathing) _startIdle();
    }
  }

  /// idle 애니메이션 시작 — 위상 엇갈리게 시작
  void _startIdle() {
    _breathController.repeat(reverse: true);
    // 위상 오프셋: 각 컨트롤러가 다른 지점에서 시작 → 유기적 움직임
    _floatController
      ..value = 0.25
      ..repeat(reverse: true);
    _tiltController
      ..value = 0.5
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _breathController.dispose();
    _floatController.dispose();
    _tiltController.dispose();
    super.dispose();
  }

  Widget _buildContent() {
    final imgSize = widget.size * 0.75;
    if (widget.imageUrl != null && widget.imageUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: widget.imageUrl!,
        width: imgSize, height: imgSize,
        fit: BoxFit.contain,
        placeholder: (_, __) => SizedBox(
          width: imgSize, height: imgSize,
          child: Center(
            child: SizedBox(
              width: imgSize * 0.3, height: imgSize * 0.3,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: widget.glowColor.withAlpha(100),
              ),
            ),
          ),
        ),
        errorWidget: (_, __, ___) => _buildLocalOrEmoji(),
      );
    }
    return _buildLocalOrEmoji();
  }

  Widget _buildLocalOrEmoji() {
    if (widget.localAsset != null) {
      return Image.asset(
        widget.localAsset!,
        width: widget.size * 0.75, height: widget.size * 0.75,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => _buildEmoji(),
      );
    }
    return _buildEmoji();
  }

  Widget _buildEmoji() =>
      Text(widget.emoji, style: TextStyle(fontSize: widget.size * 0.6));

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _entranceController, _breathController,
        _floatController, _tiltController,
      ]),
      builder: (context, child) {
        final breathScale = widget.breathing ? _breathAnimation.value : 1.0;
        final floatY = widget.breathing ? _floatAnimation.value : 0.0;
        final tilt = widget.breathing ? _tiltAnimation.value : 0.0;

        return Opacity(
          opacity: _fadeAnimation.value,
          child: Transform.translate(
            offset: Offset(0, floatY),
            child: Transform.rotate(
              angle: tilt,
              child: Transform.scale(
                scale: _scaleAnimation.value * breathScale,
                child: child,
              ),
            ),
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
        clipBehavior: Clip.antiAlias,
        child: Center(child: _buildContent()),
      ),
    );
  }
}

/// 채팅 버블용 작은 아바타
class ZodiacSmallAvatar extends StatelessWidget {
  final String emoji;
  final String? imageUrl;
  final Color glowColor;
  final double size;

  const ZodiacSmallAvatar({
    super.key,
    required this.emoji,
    this.imageUrl,
    this.glowColor = Colors.orange,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: glowColor.withAlpha(30),
        border: Border.all(
          color: glowColor.withAlpha(80),
          width: 1.5,
        ),
      ),
      child: Center(child: _buildContent()),
    );
  }

  Widget _buildContent() {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: imageUrl!,
        width: size * 0.7, height: size * 0.7,
        fit: BoxFit.contain,
        placeholder: (_, __) => Text(emoji, style: TextStyle(fontSize: size * 0.55)),
        errorWidget: (_, __, ___) => Text(emoji, style: TextStyle(fontSize: size * 0.55)),
      );
    }
    return Text(emoji, style: TextStyle(fontSize: size * 0.55));
  }
}
