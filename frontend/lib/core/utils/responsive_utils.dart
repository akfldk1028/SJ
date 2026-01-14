import 'package:flutter/material.dart';

/// 반응형 스케일링 유틸리티
/// 화면 해상도에 따라 폰트, 아이콘, 패딩 등을 자동 조절
class ResponsiveUtils {
  /// 기준 화면 너비 (모바일 디자인 기준)
  static const double baseWidth = 400.0;

  /// 최소/최대 스케일 제한
  static const double minScale = 0.85;
  static const double maxScale = 2.5;

  /// 화면 너비 기반 스케일 팩터 계산
  static double getScaleFactor(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return (screenWidth / baseWidth).clamp(minScale, maxScale);
  }

  /// BoxConstraints 기반 스케일 팩터 (LayoutBuilder 내에서 사용)
  static double getScaleFromConstraints(BoxConstraints constraints) {
    return (constraints.maxWidth / baseWidth).clamp(minScale, maxScale);
  }

  /// 스케일된 폰트 크기
  static double scaledFontSize(BuildContext context, double baseSize) {
    final scale = getScaleFactor(context);
    return (baseSize * scale).clamp(baseSize * 0.85, baseSize * 2.5);
  }

  /// 스케일된 아이콘 크기
  static double scaledIconSize(BuildContext context, double baseSize) {
    final scale = getScaleFactor(context);
    return (baseSize * scale).clamp(baseSize * 0.85, baseSize * 2.5);
  }

  /// 스케일된 패딩/마진
  static double scaledPadding(BuildContext context, double basePadding) {
    final scale = getScaleFactor(context);
    return (basePadding * scale).clamp(basePadding * 0.85, basePadding * 2.0);
  }

  /// 스케일된 위젯 크기
  static double scaledSize(BuildContext context, double baseSize) {
    final scale = getScaleFactor(context);
    return (baseSize * scale).clamp(baseSize * 0.85, baseSize * 2.5);
  }
}

/// BuildContext 확장으로 쉽게 접근
extension ResponsiveContextExtension on BuildContext {
  double get scaleFactor => ResponsiveUtils.getScaleFactor(this);

  double scaledFont(double baseSize) => ResponsiveUtils.scaledFontSize(this, baseSize);
  double scaledIcon(double baseSize) => ResponsiveUtils.scaledIconSize(this, baseSize);
  double scaledPadding(double basePadding) => ResponsiveUtils.scaledPadding(this, basePadding);
  double scaledSize(double baseSize) => ResponsiveUtils.scaledSize(this, baseSize);
}
