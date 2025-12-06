import 'package:flutter/services.dart';

/// 프롬프트 MD 파일 로더
///
/// assets/prompts/ 폴더의 MD 파일을 로드하여 시스템 프롬프트로 사용
class PromptLoader {
  static final Map<String, String> _cache = {};

  /// 프롬프트 파일 로드
  ///
  /// [promptName]: 파일명 (확장자 제외)
  /// 예: 'saju_analysis' -> assets/prompts/saju_analysis.md
  static Future<String> load(String promptName) async {
    // 캐시에 있으면 반환
    if (_cache.containsKey(promptName)) {
      return _cache[promptName]!;
    }

    try {
      final content = await rootBundle.loadString(
        'assets/prompts/$promptName.md',
      );
      _cache[promptName] = content;
      return content;
    } catch (e) {
      // 파일이 없으면 기본 프롬프트 반환
      return _getDefaultPrompt(promptName);
    }
  }

  /// 캐시 초기화 (프롬프트 수정 시 사용)
  static void clearCache() {
    _cache.clear();
  }

  /// 특정 프롬프트 캐시 제거
  static void removeFromCache(String promptName) {
    _cache.remove(promptName);
  }

  /// 기본 프롬프트 (파일 로드 실패 시)
  static String _getDefaultPrompt(String promptName) {
    switch (promptName) {
      case 'saju_analysis':
        return '''당신은 전문 사주팔자 분석가입니다.
사용자의 생년월일시를 받아 사주팔자를 분석해 주세요.
한국어로 대답하고, 전문적이면서도 이해하기 쉽게 설명해 주세요.
음양오행, 천간지지 등의 개념을 활용해 주세요.''';

      case 'daily_fortune':
        return '''당신은 전문 사주 상담사입니다.
사용자의 오늘 운세에 대해 친절하고 긍정적으로 상담해 주세요.
한국어로 대답하고, 이모지를 적절히 사용해 주세요.
너무 부정적인 내용은 완화해서 전달해 주세요.''';

      case 'compatibility':
        return '''당신은 전문 궁합 상담사입니다.
두 사람의 생년월일을 받아 궁합을 분석해 주세요.
한국어로 대답하고, 긍정적인 관점에서 조언해 주세요.
부정적인 내용도 개선 방안과 함께 전달해 주세요.''';

      default:
        return '''당신은 친절한 사주 상담 AI입니다.
사용자의 질문에 성실하게 답변해 주세요.
한국어로 대답해 주세요.''';
    }
  }
}
