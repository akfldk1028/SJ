import 'package:flutter/material.dart';
import 'app_fonts.dart';

/// 운세 앱 테마 종류 - 사용자가 선택 가능
enum AppThemeType {
  /// 가로등불 - 메인 테마 (어두운 배경 + 골드 포인트)
  streetLamp,

  /// 가로등불 라이트 - 밝은 배경 + 골드 포인트
  streetLampLight,

  /// 동양풍 다크 - 메인 테마 (어두운 배경 + 골드 포인트)
  orientalDark,

  /// 동양풍 라이트 - 밝은 배경 + 브라운/골드 포인트
  orientalLight,

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
      case AppThemeType.streetLamp:
        return '오로라 다크';
      case AppThemeType.streetLampLight:
        return '오로라 라이트';
      case AppThemeType.orientalDark:
        return '동양풍 다크';
      case AppThemeType.orientalLight:
        return '레드 라이트';
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
      case AppThemeType.streetLamp:
        return Icons.auto_awesome_rounded;
      case AppThemeType.streetLampLight:
        return Icons.auto_awesome_rounded;
      case AppThemeType.orientalDark:
        return Icons.nightlight_rounded;
      case AppThemeType.orientalLight:
        return Icons.wb_twilight_rounded;
      case AppThemeType.defaultLight:
        return Icons.brightness_high_rounded;
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
      case AppThemeType.streetLamp:
        return const Color(0xFFC4A962); // 골드
      case AppThemeType.streetLampLight:
        return const Color(0xFFC4A962); // 골드
      case AppThemeType.orientalDark:
        return const Color(0xFFB8965A); // 진한 골드
      case AppThemeType.orientalLight:
        return const Color(0xFF8B7355); // 브라운 골드
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
      // 커스텀 한글 폰트 적용
      textTheme: AppFonts.createTextTheme(isDark: ext.isDark),
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
      case AppThemeType.streetLamp:
        return _streetLampExtension;
      case AppThemeType.streetLampLight:
        return _streetLampLightExtension;
      case AppThemeType.orientalDark:
        return _orientalDarkExtension;
      case AppThemeType.orientalLight:
        return _orientalLightExtension;
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

  /// 가로등불 - 메인 테마 (다크 + 골드)
  /// 배경: #0A0A0F (딥 다크)
  /// 카드: #1A1A24 ~ #14141C (다크 그레이 그라데이션)
  /// 포인트: #C4A962 (골드)
  static const _streetLampExtension = AppThemeExtension(
    backgroundColor: Color(0xFF0A0A0F),
    cardColor: Color(0xFF1A1A24),
    primaryColor: Color(0xFFC4A962), // 골드
    textPrimary: Colors.white,
    textSecondary: Color(0xFFB0B0B0),
    textMuted: Color(0xFF71717A),
    isDark: true,
    accentColor: Color(0xFFE8D5A3), // 밝은 골드 (그라데이션용)
    // 오행 색상
    woodColor: Color(0xFF7EDA98),
    fireColor: Color(0xFFE87C7C),
    earthColor: Color(0xFFD4A574),
    metalColor: Color(0xFFC0C0C0),  // 은색 (다크 배경에서 잘 보임)
    waterColor: Color(0xFF7EB8DA),
  );

  /// 가로등불 라이트 - 밝고 깨끗한 버전
  /// 배경: #FAFAFA (깨끗한 화이트)
  /// 카드: #FFFFFF (흰색)
  /// 포인트: #5D4E37 (진한 브라운)
  /// 컨셉: 그라데이션 없이 플랫하고 모던한 느낌
  static const _streetLampLightExtension = AppThemeExtension(
    backgroundColor: Color(0xFFFAFAFA), // 깨끗한 화이트
    cardColor: Colors.white,
    primaryColor: Color(0xFF5D4E37), // 진한 브라운
    textPrimary: Color(0xFF1A1A1A),
    textSecondary: Color(0xFF4A4A4A),
    textMuted: Color(0xFF8E8E8E),
    isDark: false,
    accentColor: Color(0xFF8B7355), // 라이트 브라운
    // 오행 색상 (라이트 버전용 - 선명하게)
    woodColor: Color(0xFF4CAF50),
    fireColor: Color(0xFFE53935),
    earthColor: Color(0xFFFF9800),
    metalColor: Color(0xFF708090),  // 슬레이트 그레이 (라이트 배경에서 잘 보임)
    waterColor: Color(0xFF2196F3),
  );

  /// 동양풍 다크 테마 - 기존 메인 테마 (골드 포인트)
  /// 배경: #0A0A0F (딥 다크)
  /// 카드: #1A1A24 ~ #14141C (다크 그레이 그라데이션)
  /// 포인트: #C4A962 (골드)
  static const _orientalDarkExtension = AppThemeExtension(
    backgroundColor: Color(0xFF0A0A0F),
    cardColor: Color(0xFF1A1A24),
    primaryColor: Color(0xFFC4A962), // 골드
    textPrimary: Colors.white,
    textSecondary: Color(0xFFB0B0B0),
    textMuted: Color(0xFF71717A),
    isDark: true,
    accentColor: Color(0xFFE8D5A3), // 밝은 골드 (그라데이션용)
    // 오행 색상
    woodColor: Color(0xFF7EDA98),
    fireColor: Color(0xFFE87C7C),
    earthColor: Color(0xFFD4A574),
    metalColor: Color(0xFFC0C0C0),  // 은색 (다크 배경에서 잘 보임)
    waterColor: Color(0xFF7EB8DA),
  );

  /// 동양풍 라이트 테마 - 밝은 배경 버전
  static const _orientalLightExtension = AppThemeExtension(
    backgroundColor: Color(0xFFFAFAF8),
    cardColor: Colors.white,
    primaryColor: Color(0xFF8B7355), // 브라운 골드
    textPrimary: Color(0xFF333333),
    textSecondary: Color(0xFF666666),
    textMuted: Color(0xFF999999),
    isDark: false,
    accentColor: Color(0xFFA68B5B), // 밝은 골드
    // 오행 색상
    woodColor: Color(0xFF5AB878),
    fireColor: Color(0xFFC65D5D),
    earthColor: Color(0xFFA67C52),
    metalColor: Color(0xFF708090),  // 슬레이트 그레이 (라이트 배경에서 잘 보임)
    waterColor: Color(0xFF5A8DB8),
  );

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

  // 오행 색상 (사주 차트용)
  final Color? woodColor; // 목
  final Color? fireColor; // 화
  final Color? earthColor; // 토
  final Color? metalColor; // 금
  final Color? waterColor; // 수

  // 표면/테두리 색상 (사주 상세 화면용)
  final Color? surfaceColor; // 기본 표면
  final Color? surfaceElevatedColor; // 높은 표면
  final Color? surfaceHoverColor; // 호버 표면
  final Color? borderColor; // 테두리

  const AppThemeExtension({
    required this.backgroundColor,
    required this.cardColor,
    required this.primaryColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.isDark,
    this.accentColor,
    this.woodColor,
    this.fireColor,
    this.earthColor,
    this.metalColor,
    this.waterColor,
    this.surfaceColor,
    this.surfaceElevatedColor,
    this.surfaceHoverColor,
    this.borderColor,
  });

  // 편의 getter - surfaceColor가 없으면 isDark에 따라 기본값 제공
  Color get surface => surfaceColor ?? (isDark ? const Color(0xFF18181B) : const Color(0xFFF4F4F5));
  Color get surfaceElevated => surfaceElevatedColor ?? (isDark ? const Color(0xFF1F1F23) : Colors.white);
  Color get surfaceHover => surfaceHoverColor ?? (isDark ? const Color(0xFF27272A) : const Color(0xFFE4E4E7));
  Color get border => borderColor ?? (isDark ? const Color(0xFF27272A) : const Color(0xFFE4E4E7));

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
    Color? woodColor,
    Color? fireColor,
    Color? earthColor,
    Color? metalColor,
    Color? waterColor,
    Color? surfaceColor,
    Color? surfaceElevatedColor,
    Color? surfaceHoverColor,
    Color? borderColor,
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
      woodColor: woodColor ?? this.woodColor,
      fireColor: fireColor ?? this.fireColor,
      earthColor: earthColor ?? this.earthColor,
      metalColor: metalColor ?? this.metalColor,
      waterColor: waterColor ?? this.waterColor,
      surfaceColor: surfaceColor ?? this.surfaceColor,
      surfaceElevatedColor: surfaceElevatedColor ?? this.surfaceElevatedColor,
      surfaceHoverColor: surfaceHoverColor ?? this.surfaceHoverColor,
      borderColor: borderColor ?? this.borderColor,
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
      woodColor: Color.lerp(woodColor, other.woodColor, t),
      fireColor: Color.lerp(fireColor, other.fireColor, t),
      earthColor: Color.lerp(earthColor, other.earthColor, t),
      metalColor: Color.lerp(metalColor, other.metalColor, t),
      waterColor: Color.lerp(waterColor, other.waterColor, t),
      surfaceColor: Color.lerp(surfaceColor, other.surfaceColor, t),
      surfaceElevatedColor: Color.lerp(surfaceElevatedColor, other.surfaceElevatedColor, t),
      surfaceHoverColor: Color.lerp(surfaceHoverColor, other.surfaceHoverColor, t),
      borderColor: Color.lerp(borderColor, other.borderColor, t),
    );
  }
}

/// BuildContext 확장으로 쉽게 테마 접근
extension ThemeContextExtension on BuildContext {
  AppThemeExtension get appTheme =>
      Theme.of(this).extension<AppThemeExtension>() ??
      AppTheme.getExtension(AppThemeType.streetLamp);
}
