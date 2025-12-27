/// 토큰 카운터 유틸리티
///
/// Gemini API의 토큰 수를 추정하여 컨텍스트 윈도우 관리에 사용
/// 정확한 토큰 수는 API에서만 알 수 있지만, 추정치로 충분히 관리 가능
class TokenCounter {
  /// 평균 한글 문자당 토큰 수 (Gemini 기준 약 0.5~1.5)
  static const double _koreanTokenRatio = 1.2;

  /// 평균 영문 단어당 토큰 수
  static const double _englishTokenRatio = 1.3;

  /// 특수문자/공백 토큰 비율
  static const double _specialCharRatio = 0.5;

  /// Gemini 모델별 최대 컨텍스트 토큰
  static const Map<String, int> modelContextLimits = {
    'gemini-2.0-flash': 1048576,
    'gemini-1.5-pro': 1048576,
    'gemini-1.5-flash': 1048576,
    'gemini-3-pro-preview': 1048576, // Gemini 3.0
  };

  /// 안전 마진 (출력 토큰 + 버퍼)
  /// maxOutputTokens(8192) + 여유분
  static const int safetyMargin = 10000;

  /// 기본 최대 입력 토큰 (안전 마진 적용)
  static const int defaultMaxInputTokens = 100000; // 실용적인 제한

  /// 텍스트의 토큰 수 추정
  ///
  /// Gemini의 SentencePiece 토큰화를 근사적으로 추정
  static int estimateTokens(String text) {
    if (text.isEmpty) return 0;

    int tokens = 0;

    // 한글 문자 수
    final koreanChars = RegExp(r'[\uAC00-\uD7AF\u1100-\u11FF\u3130-\u318F]')
        .allMatches(text)
        .length;

    // 영문 단어 수 (공백으로 분리)
    final englishWords = RegExp(r'[a-zA-Z]+').allMatches(text).length;

    // 숫자
    final numbers = RegExp(r'\d+').allMatches(text).length;

    // 특수문자/공백
    final specialChars = text.length - koreanChars -
        RegExp(r'[a-zA-Z\d]').allMatches(text).length;

    tokens += (koreanChars * _koreanTokenRatio).ceil();
    tokens += (englishWords * _englishTokenRatio).ceil();
    tokens += numbers; // 숫자는 보통 1토큰
    tokens += (specialChars * _specialCharRatio).ceil();

    // 최소 1토큰
    return tokens < 1 ? 1 : tokens;
  }

  /// 메시지 리스트의 총 토큰 수 추정
  static int estimateMessagesTokens(List<Map<String, dynamic>> messages) {
    int total = 0;

    for (final message in messages) {
      // role 오버헤드 (약 4토큰)
      total += 4;

      final parts = message['parts'] as List?;
      if (parts != null) {
        for (final part in parts) {
          if (part is Map && part['text'] != null) {
            total += estimateTokens(part['text'] as String);
          }
        }
      }
    }

    return total;
  }

  /// 시스템 프롬프트 토큰 추정
  static int estimateSystemPromptTokens(String? systemPrompt) {
    if (systemPrompt == null || systemPrompt.isEmpty) return 0;
    // 시스템 프롬프트는 첫 메시지에 포함되므로 추가 오버헤드 없음
    return estimateTokens(systemPrompt);
  }

  /// 남은 토큰 수 계산
  static int getRemainingTokens({
    required int usedTokens,
    int maxTokens = defaultMaxInputTokens,
  }) {
    return maxTokens - usedTokens - safetyMargin;
  }

  /// 토큰 제한 초과 여부 확인
  static bool isOverLimit({
    required int usedTokens,
    int maxTokens = defaultMaxInputTokens,
  }) {
    return usedTokens + safetyMargin > maxTokens;
  }
}
