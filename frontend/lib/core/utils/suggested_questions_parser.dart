/// AI 응답에서 후속 질문을 파싱하는 유틸리티
///
/// AI 응답 형식:
/// ```
/// [SUGGESTED_QUESTIONS]
/// 질문1|질문2|질문3
/// [/SUGGESTED_QUESTIONS]
/// ```
///
/// 닫힘 태그가 없어도 파싱 가능 (AI가 가끔 닫힘 태그를 생략함)
class SuggestedQuestionsParser {
  /// 태그 패턴 (정규식) - 닫힘 태그 포함
  static final _tagPatternWithClose = RegExp(
    r'\[SUGGESTED_QUESTIONS\]\s*(.*?)\s*\[/SUGGESTED_QUESTIONS\]',
    dotAll: true,
  );

  /// 열림 태그만 있는 경우 (닫힘 태그 없음)
  static final _tagPatternOpenOnly = RegExp(
    r'\[SUGGESTED_QUESTIONS\]\s*(.*)$',
    dotAll: true,
  );

  /// AI 응답에서 후속 질문 추출
  ///
  /// 반환: (정제된 응답 텍스트, 후속 질문 목록)
  static ParseResult parse(String response) {
    // 1. 먼저 닫힘 태그가 있는 완전한 패턴 시도
    var match = _tagPatternWithClose.firstMatch(response);

    // 2. 닫힘 태그가 없으면 열림 태그만 있는 패턴 시도
    if (match == null) {
      match = _tagPatternOpenOnly.firstMatch(response);
    }

    if (match == null) {
      // 태그가 없으면 원본 반환, 질문 없음
      return ParseResult(
        cleanedContent: response.trim(),
        suggestedQuestions: null,
      );
    }

    // 태그 내용 추출
    String questionsText = match.group(1)?.trim() ?? '';

    // 닫힘 태그가 텍스트에 포함되어 있으면 제거
    questionsText = questionsText.replaceAll('[/SUGGESTED_QUESTIONS]', '').trim();

    // 파이프(|)로 분리하여 질문 목록 생성
    final questions = questionsText
        .split('|')
        .map((q) => q.trim())
        .where((q) => q.isNotEmpty)
        .toList();

    // 태그 제거한 응답 텍스트
    // [SUGGESTED_QUESTIONS] 태그 시작 위치 이전까지만 유지
    final tagStartIndex = response.indexOf('[SUGGESTED_QUESTIONS]');
    final cleanedContent = tagStartIndex != -1
        ? response.substring(0, tagStartIndex).trim()
        : response.trim();

    return ParseResult(
      cleanedContent: cleanedContent,
      suggestedQuestions: questions.isNotEmpty ? questions : null,
    );
  }
}

/// 파싱 결과
class ParseResult {
  /// 태그가 제거된 정제된 응답 텍스트
  final String cleanedContent;

  /// 추출된 후속 질문 목록 (없으면 null)
  final List<String>? suggestedQuestions;

  const ParseResult({
    required this.cleanedContent,
    this.suggestedQuestions,
  });
}
