import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// 앱 폰트 설정
///
/// 통일된 폰트 사용:
/// - 기본 UI: Noto Sans KR (깔끔, 가독성)
/// - 한자: 기본 시스템 폰트 또는 별도 지정
class AppFonts {
  AppFonts._();

  // ============================================
  // 폰트 패밀리 정의
  // ============================================

  /// 기본 UI 폰트 (Noto Sans KR)
  /// - 깔끔하고 현대적
  /// - 가독성 좋음
  static TextTheme get baseTextTheme {
    return GoogleFonts.notoSansKrTextTheme();
  }

  /// AI 채팅용 폰트 (Noto Sans KR)
  static TextStyle get chatStyle {
    return GoogleFonts.notoSansKr();
  }

  /// 운세/결과 표시용 폰트 (Noto Sans KR)
  static TextStyle get fortuneStyle {
    return GoogleFonts.notoSansKr();
  }

  /// 강조/제목용 폰트 (Noto Sans KR)
  static TextStyle get titleStyle {
    return GoogleFonts.notoSansKr(fontWeight: FontWeight.w600);
  }

  // ============================================
  // 텍스트 스타일 프리셋
  // ============================================

  /// AI 메시지 스타일
  static TextStyle aiMessage({
    Color? color,
    double fontSize = 15,
    FontWeight fontWeight = FontWeight.normal,
  }) {
    return GoogleFonts.notoSansKr(
      color: color,
      fontSize: fontSize,
      fontWeight: fontWeight,
      height: 1.6, // 줄간격 넉넉하게
    );
  }

  /// 사용자 메시지 스타일
  static TextStyle userMessage({
    Color? color,
    double fontSize = 15,
    FontWeight fontWeight = FontWeight.normal,
  }) {
    return GoogleFonts.notoSansKr(
      color: color,
      fontSize: fontSize,
      fontWeight: fontWeight,
      height: 1.5,
    );
  }

  /// 운세 결과 스타일
  static TextStyle fortuneResult({
    Color? color,
    double fontSize = 16,
    FontWeight fontWeight = FontWeight.normal,
  }) {
    return GoogleFonts.notoSansKr(
      color: color,
      fontSize: fontSize,
      fontWeight: fontWeight,
      height: 1.8, // 운세 텍스트는 여유있게
    );
  }

  /// 사주 용어 스타일 (강조)
  static TextStyle sajuTerm({
    Color? color,
    double fontSize = 14,
  }) {
    return GoogleFonts.notoSansKr(
      color: color,
      fontSize: fontSize,
      fontWeight: FontWeight.w600,
    );
  }

  /// 섹션 제목 스타일
  static TextStyle sectionTitle({
    Color? color,
    double fontSize = 18,
  }) {
    return GoogleFonts.notoSansKr(
      color: color,
      fontSize: fontSize,
      fontWeight: FontWeight.w600,
    );
  }

  /// 작은 캡션 스타일
  static TextStyle caption({
    Color? color,
    double fontSize = 12,
  }) {
    return GoogleFonts.notoSansKr(
      color: color,
      fontSize: fontSize,
      fontWeight: FontWeight.w400,
    );
  }

  // ============================================
  // 테마 통합
  // ============================================

  /// 테마에 적용할 전체 TextTheme 생성
  /// 모든 텍스트를 Noto Sans KR로 통일
  static TextTheme createTextTheme({bool isDark = false}) {
    final baseColor = isDark ? Colors.white : const Color(0xFF1A1A1A);

    return TextTheme(
      // Display
      displayLarge: GoogleFonts.notoSansKr(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: baseColor,
      ),
      displayMedium: GoogleFonts.notoSansKr(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: baseColor,
      ),
      displaySmall: GoogleFonts.notoSansKr(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: baseColor,
      ),

      // Headline
      headlineLarge: GoogleFonts.notoSansKr(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: baseColor,
      ),
      headlineMedium: GoogleFonts.notoSansKr(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: baseColor,
      ),
      headlineSmall: GoogleFonts.notoSansKr(
        fontSize: 18,
        fontWeight: FontWeight.w500,
        color: baseColor,
      ),

      // Title
      titleLarge: GoogleFonts.notoSansKr(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: baseColor,
      ),
      titleMedium: GoogleFonts.notoSansKr(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: baseColor,
      ),
      titleSmall: GoogleFonts.notoSansKr(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: baseColor,
      ),

      // Body
      bodyLarge: GoogleFonts.notoSansKr(
        fontSize: 16,
        fontWeight: FontWeight.normal,
        color: baseColor,
        height: 1.6,
      ),
      bodyMedium: GoogleFonts.notoSansKr(
        fontSize: 15,
        fontWeight: FontWeight.normal,
        color: baseColor,
        height: 1.6,
      ),
      bodySmall: GoogleFonts.notoSansKr(
        fontSize: 13,
        fontWeight: FontWeight.normal,
        color: baseColor,
      ),

      // Label
      labelLarge: GoogleFonts.notoSansKr(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: baseColor,
      ),
      labelMedium: GoogleFonts.notoSansKr(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: baseColor,
      ),
      labelSmall: GoogleFonts.notoSansKr(
        fontSize: 11,
        fontWeight: FontWeight.w400,
        color: baseColor,
      ),
    );
  }
}
