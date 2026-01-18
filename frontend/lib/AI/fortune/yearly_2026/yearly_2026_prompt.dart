/// # 2026 신년운세 프롬프트
///
/// ## 개요
/// saju_base(평생운세)를 기반으로 2026년 신년운세 분석
///
/// ## 파일 위치
/// `frontend/lib/AI/fortune/yearly_2026/yearly_2026_prompt.dart`
///
/// ## 모델
/// GPT-5-mini ($0.25 input, $2.00 output per 1M tokens)

import '../../core/ai_constants.dart';
import '../../prompts/prompt_template.dart';
import '../common/fortune_input_data.dart';

/// 2026 신년운세 프롬프트 템플릿
class Yearly2026Prompt extends PromptTemplate {
  /// 입력 데이터 (saju_base 포함)
  final FortuneInputData inputData;

  const Yearly2026Prompt({
    required this.inputData,
  });

  @override
  String get summaryType => SummaryType.yearlyFortune2026;

  @override
  String get modelName => OpenAIModels.fortuneAnalysis; // gpt-5-mini

  @override
  int get maxTokens => 4096;

  @override
  double get temperature => 0.7;

  @override
  Duration? get cacheExpiry => CacheExpiry.yearlyFortune2026;

  @override
  String get systemPrompt => '''
당신은 사주명리학 전문가입니다.
사용자의 평생 사주 분석(saju_base)을 기반으로 2026년 병오(丙午)년 신년운세를 분석합니다.

## 분석 기준
1. saju_base의 성격/적성/재물운/건강운 등을 2026년 운기와 연결
2. 2026년 병오(丙午)년 천간지지 영향 분석
   - 병(丙): 태양의 불, 밝음, 열정, 에너지
   - 오(午): 말, 정오, 극양, 활동성
3. 용신/기신과 세운의 관계
4. 분기별 운기 변화
5. 사용자의 대운/세운 흐름 고려

## 응답 형식
반드시 아래 JSON 형식으로 응답하세요. 다른 텍스트 없이 순수 JSON만 반환합니다.

## 톤앤매너
- 긍정적이면서도 현실적인 조언
- 사주 전문용어는 쉽게 풀어서 설명
- 구체적이고 실천 가능한 조언 제시
''';

  @override
  String buildUserPrompt() {
    return '''
## 사용자 정보
- 이름: ${inputData.profileName}
- 생년월일: ${inputData.birthDate}
${inputData.birthTime != null ? '- 태어난 시간: ${inputData.birthTime}' : ''}
- 성별: ${inputData.genderKorean}

## 평생 사주 분석 (saju_base)
${_formatSajuBase()}

## 요청
위 평생 사주 분석을 바탕으로 2026년 병오(丙午)년 신년운세를 분석해주세요.

## 응답 JSON 스키마
{
  "year": 2026,
  "yearGanji": "병오(丙午)",
  "overallScore": 75,
  "summary": "2026년 전체 운세 요약 (2-3문장)",

  "quarterly": {
    "q1": {
      "months": "1-3월",
      "score": 70,
      "theme": "새로운 시작",
      "advice": "1분기 조언"
    },
    "q2": {
      "months": "4-6월",
      "score": 75,
      "theme": "성장과 발전",
      "advice": "2분기 조언"
    },
    "q3": {
      "months": "7-9월",
      "score": 80,
      "theme": "수확의 시기",
      "advice": "3분기 조언"
    },
    "q4": {
      "months": "10-12월",
      "score": 72,
      "theme": "마무리와 준비",
      "advice": "4분기 조언"
    }
  },

  "categories": {
    "career": { "score": 80, "analysis": "직업/사업운 분석" },
    "wealth": { "score": 70, "analysis": "재물운 분석" },
    "love": { "score": 75, "analysis": "애정운 분석" },
    "health": { "score": 85, "analysis": "건강운 분석" }
  },

  "luckyElements": {
    "color": "빨강",
    "number": 7,
    "direction": "남쪽"
  },

  "monthlyHighlights": {
    "best": { "month": 6, "reason": "가장 좋은 달 이유" },
    "caution": { "month": 10, "reason": "주의할 달 이유" }
  },

  "yearAdvice": "2026년 핵심 조언 (3-4문장)"
}
''';
  }

  /// saju_base 내용을 포맷팅
  String _formatSajuBase() {
    final content = inputData.sajuBaseContent;
    final buffer = StringBuffer();

    // 주요 섹션만 추출하여 포맷팅
    if (content['personality'] != null) {
      buffer.writeln('### 성격/적성');
      buffer.writeln(content['personality'].toString());
    }

    if (content['wealth'] != null) {
      buffer.writeln('\n### 재물운');
      buffer.writeln(content['wealth'].toString());
    }

    if (content['career'] != null) {
      buffer.writeln('\n### 직업운');
      buffer.writeln(content['career'].toString());
    }

    if (content['health'] != null) {
      buffer.writeln('\n### 건강운');
      buffer.writeln(content['health'].toString());
    }

    if (content['love'] != null) {
      buffer.writeln('\n### 애정운');
      buffer.writeln(content['love'].toString());
    }

    // 원국 정보가 있으면 추가
    if (inputData.sajuOrigin != null) {
      buffer.writeln('\n### 원국 정보');
      buffer.writeln('- 일간: ${inputData.sajuOrigin!['day_stem'] ?? ''}');
      buffer.writeln('- 용신: ${inputData.sajuOrigin!['yongshin'] ?? ''}');
    }

    return buffer.toString();
  }
}
