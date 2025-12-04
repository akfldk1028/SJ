import 'package:flutter/material.dart';

/// 운세 앱 테마 종류 - 사용자가 선택 가능
enum AppThemeType {
  /// 기본 라이트 - 따뜻한 크림색 배경
  defaultLight,

  /// 다크 모드 - 어두운 보라색 계열
  darkPurple,

  /// 동양 전통 - 붉은색 + 금색
  orientalRed,

  /// 자연 - 녹색 계열
  natureGreen,

  /// 밤하늘 - 진한 남색 + 별빛
  nightSky,

  /// 벚꽃 - 핑크 파스텔
  sakuraPink,
}

/// 앱 테마 정의 클래스
class AppTheme {
  /// 테마별 이름 (한국어)
  static String getThemeName(AppThemeType type) {
    switch (type) {
      case AppThemeType.defaultLight:
        return '기본 라이트';
      case AppThemeType.darkPurple:
        return '다크 퍼플';
      case AppThemeType.orientalRed:
        return '동양 전통';
      case AppThemeType.natureGreen:
        return '자연';
      case AppThemeType.nightSky:
        return '밤하늘';
      case AppThemeType.sakuraPink:
        return '벚꽃';
    }
  }

  /// 테마별 아이콘
  static IconData getThemeIcon(AppThemeType type) {
    switch (type) {
      case AppThemeType.defaultLight:
        return Icons.wb_sunny_rounded;
      case AppThemeType.darkPurple:
        return Icons.dark_mode_rounded;
      case AppThemeType.orientalRed:
        return Icons.temple_buddhist_rounded;
      case AppThemeType.natureGreen:
        return Icons.park_rounded;
      case AppThemeType.nightSky:
        return Icons.nights_stay_rounded;
      case AppThemeType.sakuraPink:
        return Icons.local_florist_rounded;
    }
  }

  /// 테마별 프리뷰 색상
  static Color getPreviewColor(AppThemeType type) {
    switch (type) {
      case AppThemeType.defaultLight:
        return const Color(0xFFE91E63);
      case AppThemeType.darkPurple:
        return const Color(0xFF6C63FF);
      case AppThemeType.orientalRed:
        return const Color(0xFFB71C1C);
      case AppThemeType.natureGreen:
        return const Color(0xFF2E7D32);
      case AppThemeType.nightSky:
        return const Color(0xFF1A237E);
      case AppThemeType.sakuraPink:
        return const Color(0xFFF48FB1);
    }
  }

  /// 테마 데이터 가져오기 (ThemeData + Extension)
  static ThemeData getTheme(AppThemeType type) {
    final ext = getExtension(type);

    return ThemeData(
      useMaterial3: true,
      brightness: ext.isDark ? Brightness.dark : Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: ext.primaryColor,
        brightness: ext.isDark ? Brightness.dark : Brightness.light,
      ).copyWith(
        surface: ext.backgroundColor,
        onSurface: ext.textPrimary,
      ),
      scaffoldBackgroundColor: ext.backgroundColor,
      cardColor: ext.cardColor,
      appBarTheme: AppBarTheme(
        backgroundColor: ext.backgroundColor,
        foregroundColor: ext.textPrimary,
        elevation: 0,
        centerTitle: true,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: ext.cardColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ext.primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      extensions: [ext],
    );
  }

  /// 커스텀 테마 확장 데이터 가져오기
  static AppThemeExtension getExtension(AppThemeType type) {
    switch (type) {
      case AppThemeType.defaultLight:
        return _defaultLightExtension;
      case AppThemeType.darkPurple:
        return _darkPurpleExtension;
      case AppThemeType.orientalRed:
        return _orientalRedExtension;
      case AppThemeType.natureGreen:
        return _natureGreenExtension;
      case AppThemeType.nightSky:
        return _nightSkyExtension;
      case AppThemeType.sakuraPink:
        return _sakuraPinkExtension;
    }
  }

  // 기존 호환성을 위한 getter
  static ThemeData get lightTheme => getTheme(AppThemeType.defaultLight);
  static ThemeData get darkTheme => getTheme(AppThemeType.darkPurple);

  // ============================================
  // 테마 확장 데이터 정의
  // ============================================

  /// 1. 기본 라이트 테마
  static const _defaultLightExtension = AppThemeExtension(
    backgroundColor: Color(0xFFF8F6F3),
    cardColor: Colors.white,
    primaryColor: Color(0xFFE91E63),
    textPrimary: Color(0xFF1A1A1A),
    textSecondary: Color(0xFF666666),
    textMuted: Color(0xFF999999),
    isDark: false,
  );

  /// 2. 다크 퍼플 테마
  static const _darkPurpleExtension = AppThemeExtension(
    backgroundColor: Color(0xFF0D0D14),
    cardColor: Color(0xFF1E1E2E),
    primaryColor: Color(0xFF6C63FF),
    textPrimary: Colors.white,
    textSecondary: Color(0xFFB0B0B0),
    textMuted: Color(0xFF71717A),
    isDark: true,
  );

  /// 3. 동양 전통 테마 (붉은색 + 금색)
  static const _orientalRedExtension = AppThemeExtension(
    backgroundColor: Color(0xFFFFF8E7),
    cardColor: Color(0xFFFFFDF5),
    primaryColor: Color(0xFFB71C1C),
    textPrimary: Color(0xFF3E2723),
    textSecondary: Color(0xFF5D4037),
    textMuted: Color(0xFF8D6E63),
    isDark: false,
    accentColor: Color(0xFFFFD700),
  );

  /// 4. 자연 녹색 테마
  static const _natureGreenExtension = AppThemeExtension(
    backgroundColor: Color(0xFFF1F8E9),
    cardColor: Colors.white,
    primaryColor: Color(0xFF2E7D32),
    textPrimary: Color(0xFF1B5E20),
    textSecondary: Color(0xFF33691E),
    textMuted: Color(0xFF689F38),
    isDark: false,
  );

  /// 5. 밤하늘 테마 (진한 남색)
  static const _nightSkyExtension = AppThemeExtension(
    backgroundColor: Color(0xFF0A0E21),
    cardColor: Color(0xFF1D1E33),
    primaryColor: Color(0xFF536DFE),
    textPrimary: Colors.white,
    textSecondary: Color(0xFFB0BEC5),
    textMuted: Color(0xFF607D8B),
    isDark: true,
    accentColor: Color(0xFFFFD54F),
  );

  /// 6. 벚꽃 핑크 테마
  static const _sakuraPinkExtension = AppThemeExtension(
    backgroundColor: Color(0xFFFFF0F5),
    cardColor: Colors.white,
    primaryColor: Color(0xFFE91E63),
    textPrimary: Color(0xFF4A4A4A),
    textSecondary: Color(0xFF757575),
    textMuted: Color(0xFF9E9E9E),
    isDark: false,
  );
}

/// 앱 전용 테마 확장 - Theme.of(context).extension<AppThemeExtension>()으로 접근
class AppThemeExtension extends ThemeExtension<AppThemeExtension> {
  final Color backgroundColor;
  final Color cardColor;
  final Color primaryColor;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final bool isDark;
  final Color? accentColor;

  const AppThemeExtension({
    required this.backgroundColor,
    required this.cardColor,
    required this.primaryColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.isDark,
    this.accentColor,
  });

  @override
  AppThemeExtension copyWith({
    Color? backgroundColor,
    Color? cardColor,
    Color? primaryColor,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    bool? isDark,
    Color? accentColor,
  }) {
    return AppThemeExtension(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      cardColor: cardColor ?? this.cardColor,
      primaryColor: primaryColor ?? this.primaryColor,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      isDark: isDark ?? this.isDark,
      accentColor: accentColor ?? this.accentColor,
    );
  }

  @override
  AppThemeExtension lerp(ThemeExtension<AppThemeExtension>? other, double t) {
    if (other is! AppThemeExtension) return this;
    return AppThemeExtension(
      backgroundColor: Color.lerp(backgroundColor, other.backgroundColor, t)!,
      cardColor: Color.lerp(cardColor, other.cardColor, t)!,
      primaryColor: Color.lerp(primaryColor, other.primaryColor, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      isDark: t < 0.5 ? isDark : other.isDark,
      accentColor: Color.lerp(accentColor, other.accentColor, t),
    );
  }
}

/// BuildContext 확장으로 쉽게 테마 접근
extension ThemeContextExtension on BuildContext {
  AppThemeExtension get appTheme =>
      Theme.of(this).extension<AppThemeExtension>() ??
      AppTheme.getExtension(AppThemeType.defaultLight);
}
