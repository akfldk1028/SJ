/// AI 응답에서 후속 질문을 파싱하는 유틸리티
///
/// AI 응답 형식:
/// ```
/// [SUGGESTED_QUESTIONS]
/// 질문1|질문2|질문3
/// [/SUGGESTED_QUESTIONS]
/// ```
class SuggestedQuestionsParser {
  /// 태그 패턴 (정규식)
  static final _tagPattern = RegExp(
    r'\[SUGGESTED_QUESTIONS\]\s*(.*?)\s*\[/SUGGESTED_QUESTIONS\]',
    dotAll: true,
  );

  /// AI 응답에서 후속 질문 추출
  ///
  /// 반환: (정제된 응답 텍스트, 후속 질문 목록)
  static ParseResult parse(String response) {
    final match = _tagPattern.firstMatch(response);

    if (match == null) {
      // 태그가 없으면 원본 반환, 질문 없음
      return ParseResult(
        cleanedContent: response.trim(),
        suggestedQuestions: null,
      );
    }

    // 태그 내용 추출
    final questionsText = match.group(1)?.trim() ?? '';

    // 파이프(|)로 분리하여 질문 목록 생성
    final questions = questionsText
        .split('|')
        .map((q) => q.trim())
        .where((q) => q.isNotEmpty)
        .toList();

    // 태그 제거한 응답 텍스트
    final cleanedContent = response
        .replaceAll(_tagPattern, '')
        .trim();

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
