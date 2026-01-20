import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// Fortune 페이지용 Shimmer 로딩 위젯
///
/// 모던한 스켈레톤 로딩 효과를 제공합니다.
/// 각 운세 페이지에서 데이터 로딩 시 사용합니다.
class FortuneShimmerLoading extends StatefulWidget {
  const FortuneShimmerLoading({super.key});

  @override
  State<FortuneShimmerLoading> createState() => _FortuneShimmerLoadingState();
}

class _FortuneShimmerLoadingState extends State<FortuneShimmerLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    _animation = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ListView(
          padding: const EdgeInsets.all(20),
          physics: const NeverScrollableScrollPhysics(),
          children: [
            // 헤더 배너 스켈레톤
            _buildShimmerContainer(
              theme: theme,
              height: 180,
              borderRadius: 24,
            ),
            const SizedBox(height: 20),
            // 설명 카드 스켈레톤
            _buildShimmerContainer(
              theme: theme,
              height: 140,
              borderRadius: 20,
            ),
            const SizedBox(height: 20),
            // 섹션 타이틀
            _buildShimmerContainer(
              theme: theme,
              height: 24,
              width: 120,
              borderRadius: 8,
            ),
            const SizedBox(height: 14),
            // 그리드 아이템들
            Row(
              children: [
                Expanded(
                  child: _buildShimmerContainer(
                    theme: theme,
                    height: 100,
                    borderRadius: 16,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildShimmerContainer(
                    theme: theme,
                    height: 100,
                    borderRadius: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildShimmerContainer(
                    theme: theme,
                    height: 100,
                    borderRadius: 16,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildShimmerContainer(
                    theme: theme,
                    height: 100,
                    borderRadius: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // 리스트 아이템들
            ...List.generate(
              4,
              (index) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildShimmerContainer(
                  theme: theme,
                  height: 72,
                  borderRadius: 16,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildShimmerContainer({
    required AppThemeExtension theme,
    required double height,
    double? width,
    required double borderRadius,
  }) {
    final baseColor = theme.isDark
        ? Colors.grey.shade800
        : Colors.grey.shade200;
    final highlightColor = theme.isDark
        ? Colors.grey.shade700
        : Colors.grey.shade100;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: LinearGradient(
          begin: Alignment(_animation.value - 1, 0),
          end: Alignment(_animation.value + 1, 0),
          colors: [
            baseColor,
            highlightColor,
            baseColor,
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
    );
  }
}

/// 간단한 라인 shimmer (텍스트 대체용)
class ShimmerLine extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerLine({
    super.key,
    this.width = double.infinity,
    this.height = 16,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    final baseColor = theme.isDark
        ? Colors.grey.shade800
        : Colors.grey.shade200;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: baseColor,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

/// 운세 데이터 로딩 중 표시할 상태 위젯
class FortuneLoadingState extends StatelessWidget {
  final String? message;
  final Color? accentColor;

  const FortuneLoadingState({
    super.key,
    this.message,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    final color = accentColor ?? const Color(0xFF6B48FF);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 로딩 애니메이션
            _LoadingRing(color: color),
            const SizedBox(height: 24),
            // 메시지
            Text(
              message ?? '운세를 불러오는 중...',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: theme.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '잠시만 기다려주세요',
              style: TextStyle(
                fontSize: 13,
                color: theme.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingRing extends StatefulWidget {
  final Color color;

  const _LoadingRing({required this.color});

  @override
  State<_LoadingRing> createState() => _LoadingRingState();
}

class _LoadingRingState extends State<_LoadingRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: widget.color.withOpacity(0.2),
              width: 4,
            ),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: Transform.rotate(
                  angle: _controller.value * 2 * 3.14159,
                  child: CustomPaint(
                    painter: _ArcPainter(color: widget.color),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ArcPainter extends CustomPainter {
  final Color color;

  _ArcPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromCircle(
      center: Offset(size.width / 2, size.height / 2),
      radius: (size.width - 4) / 2,
    );

    canvas.drawArc(rect, -1.57, 1.57, false, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 운세 에러 상태 위젯
class FortuneErrorState extends StatelessWidget {
  final String? message;
  final VoidCallback? onRetry;
  final Color? accentColor;

  const FortuneErrorState({
    super.key,
    this.message,
    this.onRetry,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    final color = accentColor ?? const Color(0xFFEF4444);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.cloud_off_rounded,
                color: color,
                size: 36,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              message ?? '운세를 불러오지 못했어요',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: theme.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              '네트워크 연결을 확인하고 다시 시도해주세요',
              style: TextStyle(
                fontSize: 13,
                color: theme.textMuted,
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              GestureDetector(
                onTap: onRetry,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.refresh_rounded, color: Colors.white, size: 18),
                      SizedBox(width: 8),
                      Text(
                        '다시 시도',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
