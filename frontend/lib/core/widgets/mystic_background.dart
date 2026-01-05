import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// 미스틱 배경 위젯 - 블러 처리된 원들로 신비로운 분위기 연출
class MysticBackground extends StatelessWidget {
  final Widget child;
  final bool showOrbs;

  const MysticBackground({
    super.key,
    required this.child,
    this.showOrbs = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;

    // 라이트 테마 - 흰색 기반 + 눈에 띄는 그라데이션
    if (!theme.isDark) {
      return Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFFFFFF), // 순백
              Color(0xFFF5F7FA), // 연한 그레이
              Color(0xFFE8EDF5), // 연한 블루
              Color(0xFFF0F4F8), // 밝은 블루그레이
            ],
            stops: [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // 눈에 띄는 그라데이션 포인트
            if (showOrbs) ..._buildLightTexture(theme),
            // 메인 콘텐츠
            child,
          ],
        ),
      );
    }

    // 다크 테마 - 기존 블러 원들
    if (!showOrbs) {
      return Container(
        color: theme.backgroundColor,
        child: child,
      );
    }

    return Container(
      color: theme.backgroundColor,
      child: Stack(
        children: [
          // 블러 원들
          ..._buildOrbs(theme),
          // 메인 콘텐츠
          child,
        ],
      ),
    );
  }

  /// 라이트 테마용 텍스처 (블러 적게, 색상 더 진하게)
  List<Widget> _buildLightTexture(AppThemeExtension theme) {
    return [
      // 왼쪽 상단 - primary color 강하게
      Positioned(
        top: -80,
        left: -60,
        child: _BlurredOrb(
          size: 350,
          color: theme.primaryColor.withOpacity(0.25),
          blurAmount: 60,
        ),
      ),
      // 오른쪽 상단 - 블루 포인트
      Positioned(
        top: 80,
        right: -80,
        child: _BlurredOrb(
          size: 400,
          color: const Color(0xFF6B8DD6).withOpacity(0.18),
          blurAmount: 70,
        ),
      ),
      // 중앙 좌측 - 연한 퍼플
      Positioned(
        top: 320,
        left: -100,
        child: _BlurredOrb(
          size: 320,
          color: const Color(0xFF9B8BD6).withOpacity(0.15),
          blurAmount: 55,
        ),
      ),
      // 중앙 우측 - primary color
      Positioned(
        top: 480,
        right: -60,
        child: _BlurredOrb(
          size: 300,
          color: theme.primaryColor.withOpacity(0.20),
          blurAmount: 50,
        ),
      ),
      // 하단 - 블루그레이
      Positioned(
        bottom: -60,
        left: 80,
        child: _BlurredOrb(
          size: 380,
          color: const Color(0xFF8BA5C7).withOpacity(0.20),
          blurAmount: 65,
        ),
      ),
    ];
  }

  // 틸/청록 색상 정의
  static const _tealColor = Color(0xFF4ECDC4);
  static const _deepTealColor = Color(0xFF2D8A8A);

  List<Widget> _buildOrbs(AppThemeExtension theme) {
    return [
      // 왼쪽 상단 - 골드 원 (강한 효과)
      Positioned(
        top: -80,
        left: -60,
        child: _BlurredOrb(
          size: 320,
          color: theme.primaryColor.withOpacity(0.25),
          blurAmount: 90,
        ),
      ),
      // 오른쪽 상단 - 틸 그라데이션 포인트 (강조)
      Positioned(
        top: 40,
        right: -60,
        child: _BlurredOrb(
          size: 360,
          color: _tealColor.withOpacity(0.2),
          blurAmount: 110,
        ),
      ),
      // 중앙 오른쪽 - 틸 원 (포인트)
      Positioned(
        top: 280,
        right: -40,
        child: _BlurredOrb(
          size: 240,
          color: _deepTealColor.withOpacity(0.18),
          blurAmount: 70,
        ),
      ),
      // 중앙 왼쪽 - 골드 원
      Positioned(
        top: 380,
        left: -100,
        child: _BlurredOrb(
          size: 300,
          color: theme.primaryColor.withOpacity(0.18),
          blurAmount: 90,
        ),
      ),
      // 하단 왼쪽 - 틸 그라데이션
      Positioned(
        bottom: 80,
        left: -80,
        child: _BlurredOrb(
          size: 320,
          color: _tealColor.withOpacity(0.15),
          blurAmount: 100,
        ),
      ),
      // 하단 오른쪽 - 골드 원
      Positioned(
        bottom: -30,
        right: -20,
        child: _BlurredOrb(
          size: 260,
          color: theme.primaryColor.withOpacity(0.2),
          blurAmount: 80,
        ),
      ),
      // 중앙 하단 - 틸 원
      Positioned(
        bottom: 180,
        left: 100,
        child: _BlurredOrb(
          size: 180,
          color: _deepTealColor.withOpacity(0.12),
          blurAmount: 55,
        ),
      ),
    ];
  }
}

/// 블러 처리된 원 위젯
class _BlurredOrb extends StatelessWidget {
  final double size;
  final Color color;
  final double blurAmount;

  const _BlurredOrb({
    required this.size,
    required this.color,
    required this.blurAmount,
  });

  @override
  Widget build(BuildContext context) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(
        sigmaX: blurAmount,
        sigmaY: blurAmount,
        tileMode: TileMode.decal,
      ),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
        ),
      ),
    );
  }
}

/// 카드용 그라데이션 배경 위젯
class GradientCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final bool isPrimary;

  const GradientCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = 20,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isPrimary
              ? [
                  theme.primaryColor.withOpacity(0.3),
                  theme.primaryColor.withOpacity(0.1),
                ]
              : [
                  theme.cardColor,
                  theme.cardColor.withOpacity(0.8),
                ],
        ),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: isPrimary
              ? theme.primaryColor.withOpacity(0.3)
              : theme.primaryColor.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(16),
        child: child,
      ),
    );
  }
}

/// 틸 그라데이션 카드 (피그마 디자인의 메인 카드)
class TealGradientCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final VoidCallback? onTap;

  const TealGradientCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = 20,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: margin,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF1A3A3A),
              const Color(0xFF2D5A5A),
            ],
          ),
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: [
            BoxShadow(
              color: theme.primaryColor.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: padding ?? const EdgeInsets.all(20),
          child: child,
        ),
      ),
    );
  }
}

/// 다크 카드 (피그마 디자인의 히스토리 아이템)
class DarkCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final VoidCallback? onTap;

  const DarkCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = 16,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: margin,
        decoration: BoxDecoration(
          color: const Color(0xFF1A1F24),
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(
            color: theme.primaryColor.withOpacity(0.05),
            width: 1,
          ),
        ),
        child: Padding(
          padding: padding ?? const EdgeInsets.all(16),
          child: child,
        ),
      ),
    );
  }
}
