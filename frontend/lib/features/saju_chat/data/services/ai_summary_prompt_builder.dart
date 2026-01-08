import '../../../../core/services/ai_summary_service.dart';

/// AI Summary 프롬프트 빌더 (v3.0 비활성화 상태)
///
/// GPT-5.2 분석 결과를 시스템 프롬프트에 추가하는 클래스
///
/// v3.0 토큰 최적화로 현재 비활성화됨
/// - Gemini 시스템 프롬프트 토큰 절약 (~2000 토큰 감소)
/// - sajuOrigin (원본 사주 데이터)만으로 충분한 맥락 제공
///
/// 필요 시 SystemPromptBuilder.build()에서 호출하여 활성화:
/// ```dart
/// if (aiSummary != null) {
///   AiSummaryPromptBuilder.addToBuffer(_buffer, aiSummary);
/// }
/// ```
class AiSummaryPromptBuilder {
  /// AI Summary를 버퍼에 추가
  static void addToBuffer(StringBuffer buffer, AiSummary aiSummary) {
    buffer.writeln();
    buffer.writeln('---');
    buffer.writeln();
    buffer.writeln('## AI 분석 요약 (GPT-5.2)');
    buffer.writeln();

    // 한 문장 요약
    if (aiSummary.summary != null) {
      buffer.writeln('### 요약');
      buffer.writeln(aiSummary.summary);
      buffer.writeln();
    }

    buffer.writeln('### 성격');
    buffer.writeln('- **핵심**: ${aiSummary.personality.core}');
    buffer.writeln('- **특성**: ${aiSummary.personality.traits.join(', ')}');
    buffer.writeln();
    buffer.writeln('### 강점');
    buffer.writeln(aiSummary.strengths.map((s) => '- $s').join('\n'));
    buffer.writeln();
    buffer.writeln('### 약점');
    buffer.writeln(aiSummary.weaknesses.map((w) => '- $w').join('\n'));
    buffer.writeln();

    // 재물운
    if (aiSummary.wealth != null) {
      buffer.writeln('### 재물운');
      if (aiSummary.wealth!.overallTendency != null) {
        buffer.writeln('- **성향**: ${aiSummary.wealth!.overallTendency}');
      }
      if (aiSummary.wealth!.advice != null) {
        buffer.writeln('- **조언**: ${aiSummary.wealth!.advice}');
      }
      buffer.writeln();
    }

    // 연애운
    if (aiSummary.love != null) {
      buffer.writeln('### 연애운');
      if (aiSummary.love!.attractionStyle != null) {
        buffer.writeln('- **매력 스타일**: ${aiSummary.love!.attractionStyle}');
      }
      if (aiSummary.love!.advice != null) {
        buffer.writeln('- **조언**: ${aiSummary.love!.advice}');
      }
      buffer.writeln();
    }

    // 결혼운
    if (aiSummary.marriage != null) {
      buffer.writeln('### 결혼운');
      if (aiSummary.marriage!.marriageTiming != null) {
        buffer.writeln('- **시기**: ${aiSummary.marriage!.marriageTiming}');
      }
      if (aiSummary.marriage!.advice != null) {
        buffer.writeln('- **조언**: ${aiSummary.marriage!.advice}');
      }
      buffer.writeln();
    }

    buffer.writeln('### 진로/직장운');
    buffer.writeln('- **적합 분야**: ${aiSummary.career.aptitude.join(', ')}');
    buffer.writeln('- **조언**: ${aiSummary.career.advice}');
    buffer.writeln();

    // 사업운
    if (aiSummary.business != null) {
      buffer.writeln('### 사업운');
      if (aiSummary.business!.entrepreneurshipAptitude != null) {
        buffer.writeln('- **적성**: ${aiSummary.business!.entrepreneurshipAptitude}');
      }
      if (aiSummary.business!.advice != null) {
        buffer.writeln('- **조언**: ${aiSummary.business!.advice}');
      }
      buffer.writeln();
    }

    // 건강운
    if (aiSummary.health != null) {
      buffer.writeln('### 건강운');
      if (aiSummary.health!.vulnerableOrgans.isNotEmpty) {
        buffer.writeln('- **취약 장기**: ${aiSummary.health!.vulnerableOrgans.join(', ')}');
      }
      if (aiSummary.health!.lifestyleAdvice.isNotEmpty) {
        buffer.writeln('- **생활 조언**: ${aiSummary.health!.lifestyleAdvice.join(', ')}');
      }
      buffer.writeln();
    }

    buffer.writeln('### 대인관계');
    buffer.writeln('- **스타일**: ${aiSummary.relationships.style}');
    buffer.writeln('- **팁**: ${aiSummary.relationships.tips}');
    buffer.writeln();

    // 행운 요소 (luckyElements 우선, 없으면 fortuneTips)
    if (aiSummary.luckyElements != null) {
      buffer.writeln('### 행운 요소');
      buffer.writeln('- **행운의 색상**: ${aiSummary.luckyElements!.colors.join(', ')}');
      buffer.writeln('- **행운의 방향**: ${aiSummary.luckyElements!.directions.join(', ')}');
      if (aiSummary.luckyElements!.numbers.isNotEmpty) {
        buffer.writeln('- **행운의 숫자**: ${aiSummary.luckyElements!.numbers.join(', ')}');
      }
    } else {
      buffer.writeln('### 개운법');
      buffer.writeln('- **행운의 색상**: ${aiSummary.fortuneTips.colors.join(', ')}');
      buffer.writeln('- **행운의 방향**: ${aiSummary.fortuneTips.directions.join(', ')}');
      buffer.writeln('- **추천 활동**: ${aiSummary.fortuneTips.activities.join(', ')}');
    }

    // 종합 조언
    if (aiSummary.overallAdvice != null) {
      buffer.writeln();
      buffer.writeln('### 종합 조언');
      buffer.writeln(aiSummary.overallAdvice);
    }
  }
}
