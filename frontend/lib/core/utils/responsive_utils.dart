import 'package:flutter/material.dart';

/// 반응형 스케일링 유틸리티
/// 화면 해상도에 따라 폰트, 아이콘, 패딩 등을 자동 조절
class ResponsiveUtils {
  ResponsiveUtils._();

  /// 기준 화면 너비 (모바일 디자인 기준)
  static const double baseWidth = 400.0;
  static const double baseHeight = 800.0;

  /// 최소/최대 스케일 제한
  static const double minScale = 0.85;
  static const double maxScale = 1.3;

  /// 화면 크기 기준값
  static const double smallMobileBreakpoint = 360;
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;
  static const double desktopBreakpoint = 1200;

  /// 현재 화면 너비
  static double screenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  /// 현재 화면 높이
  static double screenHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

  /// 화면 너비 기반 스케일 팩터 계산
  static double getScaleFactor(BuildContext context) {
    final width = screenWidth(context);
    // 화면 크기에 따른 스케일 조정
    if (width < smallMobileBreakpoint) {
      return 0.85; // 작은 화면
    } else if (width < mobileBreakpoint) {
      return 1.0; // 일반 모바일
    } else if (width < tabletBreakpoint) {
      return 1.1; // 태블릿
    } else {
      return 1.2; // 데스크탑
    }
  }

  /// BoxConstraints 기반 스케일 팩터 (LayoutBuilder 내에서 사용)
  static double getScaleFromConstraints(BoxConstraints constraints) {
    final width = constraints.maxWidth;
    if (width < smallMobileBreakpoint) {
      return 0.85;
    } else if (width < mobileBreakpoint) {
      return 1.0;
    } else if (width < tabletBreakpoint) {
      return 1.1;
    } else {
      return 1.2;
    }
  }

  /// 현재 기기 타입 판별
  static DeviceType getDeviceType(BuildContext context) {
    final width = screenWidth(context);
    if (width < mobileBreakpoint) return DeviceType.mobile;
    if (width < tabletBreakpoint) return DeviceType.tablet;
    return DeviceType.desktop;
  }

  /// 모바일 여부
  static bool isMobile(BuildContext context) {
    return getDeviceType(context) == DeviceType.mobile;
  }

  /// 태블릿 여부
  static bool isTablet(BuildContext context) {
    return getDeviceType(context) == DeviceType.tablet;
  }

  /// 데스크탑 여부
  static bool isDesktop(BuildContext context) {
    return getDeviceType(context) == DeviceType.desktop;
  }

  /// 작은 모바일 여부 (360px 미만)
  static bool isSmallMobile(BuildContext context) {
    return screenWidth(context) < smallMobileBreakpoint;
  }

  /// 스케일된 폰트 크기
  static double scaledFontSize(BuildContext context, double baseSize) {
    final scale = getScaleFactor(context);
    return (baseSize * scale).clamp(baseSize * minScale, baseSize * maxScale);
  }

  /// 스케일된 아이콘 크기
  static double scaledIconSize(BuildContext context, double baseSize) {
    final scale = getScaleFactor(context);
    return (baseSize * scale).clamp(baseSize * minScale, baseSize * maxScale);
  }

  /// 스케일된 패딩/마진
  static double scaledPadding(BuildContext context, double basePadding) {
    final scale = getScaleFactor(context);
    return (basePadding * scale).clamp(basePadding * minScale, basePadding * 1.5);
  }

  /// 스케일된 위젯 크기
  static double scaledSize(BuildContext context, double baseSize) {
    final scale = getScaleFactor(context);
    return (baseSize * scale).clamp(baseSize * minScale, baseSize * maxScale);
  }

  /// 화면 너비에 따른 수평 패딩 계산
  static double horizontalPadding(BuildContext context) {
    final width = screenWidth(context);
    if (width < smallMobileBreakpoint) return 12;
    if (width < mobileBreakpoint) return 16;
    if (width < tabletBreakpoint) return 24;
    return 32;
  }

  /// 화면 너비에 따른 콘텐츠 최대 너비
  static double maxContentWidth(BuildContext context) {
    final width = screenWidth(context);
    if (width < mobileBreakpoint) return width;
    if (width < tabletBreakpoint) return 600;
    return 800;
  }

  /// 화면 너비에 따른 그리드 열 수
  static int gridColumns(BuildContext context, {
    int mobileColumns = 2,
    int tabletColumns = 3,
    int desktopColumns = 4,
  }) {
    final deviceType = getDeviceType(context);
    switch (deviceType) {
      case DeviceType.mobile:
        return mobileColumns;
      case DeviceType.tablet:
        return tabletColumns;
      case DeviceType.desktop:
        return desktopColumns;
    }
  }

  /// 화면 너비에 따른 카드 비율
  static double cardAspectRatio(BuildContext context, {
    double mobileRatio = 1.4,
    double tabletRatio = 1.3,
    double desktopRatio = 1.2,
  }) {
    final deviceType = getDeviceType(context);
    switch (deviceType) {
      case DeviceType.mobile:
        return mobileRatio;
      case DeviceType.tablet:
        return tabletRatio;
      case DeviceType.desktop:
        return desktopRatio;
    }
  }

  /// 상태바 높이
  static double statusBarHeight(BuildContext context) {
    return MediaQuery.of(context).padding.top;
  }

  /// 하단 안전영역 높이
  static double bottomSafeArea(BuildContext context) {
    return MediaQuery.of(context).padding.bottom;
  }

  /// 키보드 높이
  static double keyboardHeight(BuildContext context) {
    return MediaQuery.of(context).viewInsets.bottom;
  }

  /// 키보드 표시 여부
  static bool isKeyboardVisible(BuildContext context) {
    return keyboardHeight(context) > 0;
  }

  /// 반응형 값 선택
  static T selectValue<T>(BuildContext context, {
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    final deviceType = getDeviceType(context);
    switch (deviceType) {
      case DeviceType.mobile:
        return mobile;
      case DeviceType.tablet:
        return tablet ?? mobile;
      case DeviceType.desktop:
        return desktop ?? tablet ?? mobile;
    }
  }
}

/// 기기 타입
enum DeviceType {
  mobile,
  tablet,
  desktop,
}

/// BuildContext 확장으로 쉽게 접근
extension ResponsiveContextExtension on BuildContext {
  /// 스케일 팩터
  double get scaleFactor => ResponsiveUtils.getScaleFactor(this);

  /// 화면 너비
  double get screenWidth => ResponsiveUtils.screenWidth(this);

  /// 화면 높이
  double get screenHeight => ResponsiveUtils.screenHeight(this);

  /// 기기 타입
  DeviceType get deviceType => ResponsiveUtils.getDeviceType(this);

  /// 모바일 여부
  bool get isMobile => ResponsiveUtils.isMobile(this);

  /// 태블릿 여부
  bool get isTablet => ResponsiveUtils.isTablet(this);

  /// 데스크탑 여부
  bool get isDesktop => ResponsiveUtils.isDesktop(this);

  /// 작은 모바일 여부
  bool get isSmallMobile => ResponsiveUtils.isSmallMobile(this);

  /// 스케일된 폰트
  double scaledFont(double baseSize) => ResponsiveUtils.scaledFontSize(this, baseSize);

  /// 스케일된 아이콘
  double scaledIcon(double baseSize) => ResponsiveUtils.scaledIconSize(this, baseSize);

  /// 스케일된 패딩
  double scaledPadding(double basePadding) => ResponsiveUtils.scaledPadding(this, basePadding);

  /// 스케일된 크기
  double scaledSize(double baseSize) => ResponsiveUtils.scaledSize(this, baseSize);

  /// 반응형 수평 패딩
  double get horizontalPadding => ResponsiveUtils.horizontalPadding(this);

  /// 반응형 최대 콘텐츠 너비
  double get maxContentWidth => ResponsiveUtils.maxContentWidth(this);

  /// 상태바 높이
  double get statusBarHeight => ResponsiveUtils.statusBarHeight(this);

  /// 하단 안전영역
  double get bottomSafeArea => ResponsiveUtils.bottomSafeArea(this);

  /// 키보드 표시 여부
  bool get isKeyboardVisible => ResponsiveUtils.isKeyboardVisible(this);

  /// 반응형 값 선택
  T responsive<T>({required T mobile, T? tablet, T? desktop}) {
    return ResponsiveUtils.selectValue(this, mobile: mobile, tablet: tablet, desktop: desktop);
  }
}

/// 반응형 빌더 위젯
class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, DeviceType deviceType, double screenWidth) builder;

  const ResponsiveBuilder({
    super.key,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        DeviceType deviceType;
        if (width < ResponsiveUtils.mobileBreakpoint) {
          deviceType = DeviceType.mobile;
        } else if (width < ResponsiveUtils.tabletBreakpoint) {
          deviceType = DeviceType.tablet;
        } else {
          deviceType = DeviceType.desktop;
        }
        return builder(context, deviceType, width);
      },
    );
  }
}

/// 반응형 컨테이너 위젯
/// 콘텐츠를 중앙에 배치하고 최대 너비를 제한
class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final double? maxWidth;
  final EdgeInsetsGeometry? padding;
  final bool center;

  const ResponsiveContainer({
    super.key,
    required this.child,
    this.maxWidth,
    this.padding,
    this.center = true,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveMaxWidth = maxWidth ?? context.maxContentWidth;
    final effectivePadding = padding ?? EdgeInsets.symmetric(horizontal: context.horizontalPadding);

    Widget content = Container(
      constraints: BoxConstraints(maxWidth: effectiveMaxWidth),
      padding: effectivePadding,
      child: child,
    );

    if (center) {
      content = Center(child: content);
    }

    return content;
  }
}

/// 반응형 그리드 위젯
class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final int mobileColumns;
  final int tabletColumns;
  final int desktopColumns;
  final double spacing;
  final double runSpacing;
  final double? childAspectRatio;

  const ResponsiveGrid({
    super.key,
    required this.children,
    this.mobileColumns = 2,
    this.tabletColumns = 3,
    this.desktopColumns = 4,
    this.spacing = 12,
    this.runSpacing = 12,
    this.childAspectRatio,
  });

  @override
  Widget build(BuildContext context) {
    final columns = ResponsiveUtils.gridColumns(
      context,
      mobileColumns: mobileColumns,
      tabletColumns: tabletColumns,
      desktopColumns: desktopColumns,
    );

    return GridView.count(
      crossAxisCount: columns,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: runSpacing,
      crossAxisSpacing: spacing,
      childAspectRatio: childAspectRatio ?? ResponsiveUtils.cardAspectRatio(context),
      children: children,
    );
  }
}

/// 반응형 패딩 위젯
class ResponsivePadding extends StatelessWidget {
  final Widget child;
  final double? horizontal;
  final double? vertical;

  const ResponsivePadding({
    super.key,
    required this.child,
    this.horizontal,
    this.vertical,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: horizontal ?? context.horizontalPadding,
        vertical: vertical ?? 0,
      ),
      child: child,
    );
  }
}
