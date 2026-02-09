/// 운세 텍스트 포매터 유틸리티
///
/// 운세 페이지의 가독성을 개선하기 위한 텍스트 포맷 함수 제공
class FortuneTextFormatter {
  /// 온점 기준 줄바꿈 적용 (가독성 개선)
  ///
  /// - 숫자.숫자 패턴(예: 1.5, 3.0)은 줄바꿈하지 않음
  /// - 한글/영문 앞의 온점 뒤에 줄바꿈 추가
  /// - 짧은 텍스트(50자 미만)는 변환하지 않음
  ///
  /// 예시:
  /// ```
  /// "오늘은 좋은 날입니다. 열심히 하세요."
  /// → "오늘은 좋은 날입니다.\n열심히 하세요."
  /// ```
  static String formatParagraph(String text) {
    // 짧은 텍스트는 변환하지 않음 (한 문장 정도)
    if (text.length < 50) return text;

    // 1. 이미 줄바꿈이 있으면 그대로 반환 (이미 포맷됨)
    if (text.contains('\n')) return text;

    // 2. 숫자.숫자 패턴 임시 치환 (예: 1.5 → 1⌘5)
    final preserved = text.replaceAllMapped(
      RegExp(r'(\d)\.(\d)'),
      (m) => '${m.group(1)}⌘${m.group(2)}',
    );

    // 3. 온점 + 공백 + 한글/영문 시작 → 온점 + 줄바꿈
    final formatted = preserved.replaceAllMapped(
      RegExp(r'\.\s+(?=[가-힣A-Za-z])'),
      (m) => '.\n',
    );

    // 4. 임시 치환 복원
    return formatted.replaceAll('⌘', '.');
  }

  /// 불필요한 "..." 제거
  ///
  /// - 문장 끝의 "..."를 적절한 마침표로 변환
  /// - "..." 연속 사용 정리
  static String cleanEllipsis(String text) {
    return text
        // "..." + 공백 + 한글/영문 → ". " (문장 구분)
        .replaceAllMapped(
          RegExp(r'\.{3,}\s+(?=[가-힣A-Za-z])'),
          (m) => '. ',
        )
        // 문장 끝 "..." 유지 (의도적인 여운)
        .replaceAll(RegExp(r'\.{4,}'), '...')
        .trim();
  }

  /// 전체 포맷 적용 (줄바꿈 + 불필요한 부호 정리)
  static String format(String text) {
    final cleaned = cleanEllipsis(text);
    return formatParagraph(cleaned);
  }
}
