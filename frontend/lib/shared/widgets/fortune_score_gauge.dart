import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../core/theme/app_theme.dart';

/// 운세 점수 게이지 위젯
///
/// 동양풍 감성의 원형 또는 반원형 게이지로 점수를 시각적으로 표시
class FortuneScoreGauge extends StatelessWidget {
  final int score;
  final double size;
  final bool showLabel;
  final String? label;
  final GaugeStyle style;

  const FortuneScoreGauge({
    super.key,
    required this.score,
    this.size = 80,
    this.showLabel = true,
    this.label,
    this.style = GaugeStyle.circular,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;

    switch (style) {
      case GaugeStyle.circular:
        return _buildCircularGauge(theme);
      case GaugeStyle.semicircle:
        return _buildSemicircleGauge(theme);
      case GaugeStyle.linear:
        return _buildLinearGauge(theme);
      case GaugeStyle.compact:
        return _buildCompactGauge(theme);
    }
  }

  /// 원형 게이지 - 동양풍 우아한 스타일
  Widget _buildCircularGauge(AppThemeExtension theme) {
    final scoreColor = _getScoreColor(score, theme);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          // 은은한 외부 그림자
          BoxShadow(
            color: Colors.black.withValues(alpha: theme.isDark ? 0.3 : 0.08),
            blurRadius: size * 0.12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 배경 원 (한지 느낌의 부드러운 텍스처)
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.cardColor,
              border: Border.all(
                color: theme.primaryColor.withValues(alpha: 0.15),
                width: 1,
              ),
            ),
          ),
          // 메인 게이지
          CustomPaint(
            size: Size(size, size),
            painter: _CircularGaugePainter(
              progress: score / 100,
              backgroundColor: theme.textMuted.withValues(alpha: 0.12),
              progressColor: scoreColor,
              strokeWidth: size * 0.08,
            ),
          ),
          // 중앙 원형 배경
          Container(
            width: size * 0.62,
            height: size * 0.62,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.cardColor,
              border: Border.all(
                color: theme.primaryColor.withValues(alpha: 0.1),
                width: 0.5,
              ),
            ),
          ),
          // 점수 텍스트
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$score',
                style: TextStyle(
                  fontSize: size * 0.28,
                  fontWeight: FontWeight.w700,
                  color: theme.textPrimary,
                  letterSpacing: -1,
                  height: 1,
                ),
              ),
              if (showLabel) ...[
                SizedBox(height: size * 0.02),
                Text(
                  label ?? '점',
                  style: TextStyle(
                    fontSize: size * 0.1,
                    fontWeight: FontWeight.w500,
                    color: theme.textSecondary,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  /// 반원형 게이지 - 동양풍 스타일
  Widget _buildSemicircleGauge(AppThemeExtension theme) {
    final scoreColor = _getScoreColor(score, theme);

    return SizedBox(
      width: size,
      height: size * 0.6,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          CustomPaint(
            size: Size(size, size * 0.55),
            painter: _SemicircleGaugePainter(
              progress: score / 100,
              backgroundColor: theme.textMuted.withValues(alpha: 0.12),
              progressColor: scoreColor,
              strokeWidth: size * 0.08,
            ),
          ),
          Positioned(
            bottom: 4,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$score',
                  style: TextStyle(
                    fontSize: size * 0.24,
                    fontWeight: FontWeight.w700,
                    color: theme.textPrimary,
                    letterSpacing: -0.5,
                    height: 1,
                  ),
                ),
                if (showLabel) ...[
                  const SizedBox(height: 2),
                  Text(
                    label ?? '점',
                    style: TextStyle(
                      fontSize: size * 0.1,
                      fontWeight: FontWeight.w500,
                      color: theme.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 선형 프로그레스 바 - 동양풍 스타일
  Widget _buildLinearGauge(AppThemeExtension theme) {
    final scoreColor = _getScoreColor(score, theme);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showLabel && label != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label!,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: theme.textSecondary,
                  ),
                ),
                Text(
                  '$score점',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: scoreColor,
                  ),
                ),
              ],
            ),
          ),
        Container(
          height: 8,
          decoration: BoxDecoration(
            color: theme.textMuted.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Stack(
            children: [
              FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: score / 100,
                child: Container(
                  decoration: BoxDecoration(
                    color: scoreColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 컴팩트 배지 스타일 - 동양풍 우아한 스타일
  Widget _buildCompactGauge(AppThemeExtension theme) {
    final scoreColor = _getScoreColor(score, theme);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.primaryColor.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: theme.isDark ? 0.2 : 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 작은 원형 인디케이터
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: scoreColor.withValues(alpha: 0.15),
              border: Border.all(
                color: scoreColor.withValues(alpha: 0.4),
                width: 2,
              ),
            ),
            child: Center(
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: scoreColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$score',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: theme.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          Text(
            '점',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: theme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  /// 점수별 색상 - 동양풍 색상 팔레트 (앱 테마 기반)
  Color _getScoreColor(int score, AppThemeExtension theme) {
    // 테마의 primaryColor(금색)를 기준으로 점수별 변화
    if (score >= 80) return const Color(0xFFB8860B); // 다크 골든로드 (상)
    if (score >= 60) return theme.primaryColor; // 기본 금색 (중상)
    if (score >= 40) return const Color(0xFF8B7355); // 버우드 (중)
    return const Color(0xFF6B5344); // 다크 브라운 (하)
  }
}

/// 게이지 스타일
enum GaugeStyle {
  circular,   // 전체 원형
  semicircle, // 반원형
  linear,     // 선형 바
  compact,    // 컴팩트 배지
}

/// 원형 게이지 페인터 - 동양풍 우아한 스타일
class _CircularGaugePainter extends CustomPainter {
  final double progress;
  final Color backgroundColor;
  final Color progressColor;
  final double strokeWidth;

  _CircularGaugePainter({
    required this.progress,
    required this.backgroundColor,
    required this.progressColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // 배경 원
    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    if (progress <= 0) return;

    final sweepAngle = 2 * math.pi * progress;

    // 진행 원
    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CircularGaugePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.progressColor != progressColor;
  }
}

/// 반원형 게이지 페인터
class _SemicircleGaugePainter extends CustomPainter {
  final double progress;
  final Color backgroundColor;
  final Color progressColor;
  final double strokeWidth;

  _SemicircleGaugePainter({
    required this.progress,
    required this.backgroundColor,
    required this.progressColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height);
    final radius = (size.width - strokeWidth) / 2;

    // 배경 반원
    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi,
      math.pi,
      false,
      bgPaint,
    );

    // 진행 반원
    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final sweepAngle = math.pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _SemicircleGaugePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.progressColor != progressColor;
  }
}
