import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// 앱 전체 텍스트 스타일 시스템
///
/// 뎁스(계층) 기준 통일 스타일.
/// 하드코딩 fontSize 대신 이 클래스를 사용할 것.
///
/// 사용법 A — TextStyle만 가져오기:
///   Text('제목', style: AppTextStyles.heading1)
///   Text('본문', style: AppTextStyles.body.copyWith(color: Colors.grey))
///
/// 사용법 B — AppText 위젯 사용 (overflow 자동 처리):
///   AppText('카드 제목', style: AppTextStyles.title)
///
/// 계층 구조:
///   display  (32) → 스플래시, 히어로
///   heading1 (24) → 페이지 제목
///   heading2 (20) → 섹션 제목
///   heading3 (18) → 서브섹션 제목
///   title    (16) → 카드/리스트 아이템 제목
///   body     (15) → 일반 본문 (기본)
///   label    (14) → 라벨, 부제목
///   caption  (13) → 보조 설명
///   small    (12) → 배지, 태그
///   tiny     (11) → 최소 단위
class AppTextStyles {
  AppTextStyles._();

  // ============================================================
  // 폰트 사이즈 상수 (한 곳에서만 관리)
  // ============================================================
  static const double sizeDisplay  = 32;
  static const double sizeH1       = 24;
  static const double sizeH2       = 20;
  static const double sizeH3       = 18;
  static const double sizeTitle    = 16;
  static const double sizeBody     = 15;
  static const double sizeLabel    = 14;
  static const double sizeCaption  = 13;
  static const double sizeSmall    = 12;
  static const double sizeTiny     = 11;

  // ============================================================
  // 내부 팩토리
  // ============================================================
  static TextStyle _sans({
    required double size,
    FontWeight weight = FontWeight.w400,
    double height = 1.5,
    Color? color,
  }) =>
      GoogleFonts.notoSansKr(fontSize: size, fontWeight: weight, height: height, color: color);

  static TextStyle _serif({
    required double size,
    FontWeight weight = FontWeight.w400,
    double height = 1.7,
    Color? color,
  }) =>
      GoogleFonts.notoSerifKr(fontSize: size, fontWeight: weight, height: height, color: color);

  // ============================================================
  // 공개 스타일
  // ============================================================

  /// 32px bold — 스플래시, 히어로 타이틀
  static TextStyle get display    => _sans(size: sizeDisplay, weight: FontWeight.bold, height: 1.2);

  /// 24px w600 — 페이지 제목
  static TextStyle get heading1   => _sans(size: sizeH1, weight: FontWeight.w600, height: 1.3);

  /// 20px w600 — 섹션 제목
  static TextStyle get heading2   => _sans(size: sizeH2, weight: FontWeight.w600, height: 1.4);

  /// 18px w500 — 서브섹션 제목
  static TextStyle get heading3   => _sans(size: sizeH3, weight: FontWeight.w500, height: 1.4);

  /// 16px w600 — 카드/리스트 아이템 제목
  static TextStyle get title      => _sans(size: sizeTitle, weight: FontWeight.w600, height: 1.5);

  /// 16px w400 — 넓은 영역 본문
  static TextStyle get bodyLarge  => _sans(size: sizeTitle, height: 1.6);

  /// 15px w400 — 기본 본문 (가장 많이 쓰는 크기)
  static TextStyle get body       => _sans(size: sizeBody, height: 1.6);

  /// 14px w500 — 라벨, 강조 부제목
  static TextStyle get label      => _sans(size: sizeLabel, weight: FontWeight.w500);

  /// 14px w400 — 일반 부제목
  static TextStyle get bodySmall  => _sans(size: sizeLabel);

  /// 13px w400 — 보조 설명, 날짜/시간
  static TextStyle get caption    => _sans(size: sizeCaption, height: 1.4);

  /// 13px w500 — 강조 캡션
  static TextStyle get captionBold => _sans(size: sizeCaption, weight: FontWeight.w500, height: 1.4);

  /// 12px w400 — 배지, 태그, 칩 텍스트
  static TextStyle get small      => _sans(size: sizeSmall, height: 1.4);

  /// 12px w500 — 강조 태그
  static TextStyle get smallBold  => _sans(size: sizeSmall, weight: FontWeight.w500, height: 1.4);

  /// 11px w400 — 최소 단위 (상태, 메타 정보)
  static TextStyle get tiny       => _sans(size: sizeTiny, height: 1.3);

  // ── 운세 전용 (명조체) ──────────────────────────────────────

  /// 운세 본문 — 18px 명조체
  static TextStyle get fortuneBody    => _serif(size: sizeH3, height: 1.8);

  /// 운세 카드 제목 — 16px 명조체 w600
  static TextStyle get fortuneTitle   => _serif(size: sizeTitle, weight: FontWeight.w600, height: 1.5);

  /// 운세 설명 — 14px 명조체
  static TextStyle get fortuneCaption => _serif(size: sizeLabel, height: 1.7);

  /// 사주 용어 — 14px 명조체 w600
  static TextStyle get sajuTerm       => _serif(size: sizeLabel, weight: FontWeight.w600);

  // ── AI 채팅 전용 ────────────────────────────────────────────

  /// AI 메시지 — 15px, 줄간격 1.6
  static TextStyle get aiMessage   => _sans(size: sizeBody, height: 1.6);

  /// 유저 메시지 — 15px, 줄간격 1.5
  static TextStyle get userMessage => _sans(size: sizeBody, height: 1.5);
}

/// overflow/maxLines를 기본 처리하는 Text 래퍼
///
/// [overflow] 기본: ellipsis (생략 부호)
/// [maxLines] 기본: null (무제한) — 제목류 사용시 명시적으로 1 지정
///
/// 예시:
///   AppText('카드 제목', style: AppTextStyles.title, maxLines: 1)
///   AppText('긴 설명 텍스트...', style: AppTextStyles.body, maxLines: 3)
class AppText extends StatelessWidget {
  const AppText(
    this.data, {
    super.key,
    required this.style,
    this.maxLines,
    this.overflow = TextOverflow.ellipsis,
    this.textAlign,
    this.softWrap = true,
  });

  final String data;
  final TextStyle style;
  final int? maxLines;
  final TextOverflow overflow;
  final TextAlign? textAlign;
  final bool softWrap;

  @override
  Widget build(BuildContext context) {
    return Text(
      data,
      style: style,
      maxLines: maxLines,
      overflow: overflow,
      textAlign: textAlign,
      softWrap: softWrap,
    );
  }
}
