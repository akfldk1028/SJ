/// # 2025 회고 운세 프롬프트
///
/// ## 개요
/// saju_base(평생운세)를 기반으로 2025년 을사(乙巳)년 회고 분석
/// 과거 분석이므로 "회고/복기" 관점
///
/// ## 파일 위치
/// `frontend/lib/AI/fortune/yearly_2025/yearly_2025_prompt.dart`
///
/// ## 모델
/// GPT-5-mini ($0.25 input, $2.00 output per 1M tokens)

import '../../core/ai_constants.dart';
import '../../prompts/prompt_template.dart';
import '../common/fortune_input_data.dart';

/// 2025 회고 운세 프롬프트 템플릿
class Yearly2025Prompt extends PromptTemplate {
  /// 입력 데이터 (saju_base 포함)
  final FortuneInputData inputData;

  const Yearly2025Prompt({
    required this.inputData,
  });

  @override
  String get summaryType => SummaryType.yearlyFortune2025;

  @override
  String get modelName => OpenAIModels.fortuneAnalysis; // gpt-5-mini

  @override
  int get maxTokens => 3072;

  @override
  double get temperature => 0.7;

  @override
  Duration? get cacheExpiry => CacheExpiry.yearlyFortune2025; // 무기한

  @override
  String get systemPrompt => '''
당신은 사주명리학 전문가입니다.
사용자의 평생 사주 분석(saju_base)을 기반으로 2025년 을사(乙巳)년을 **회고/복기** 관점에서 분석합니다.

## 분석 기준
1. 2025년 을사(乙巳)년의 특징
   - 을(乙): 음목, 유연함, 성장, 적응
   - 사(巳): 뱀, 지혜, 변화, 숨은 기회
2. saju_base와 2025년 운기의 상호작용
3. 2025년에 있었을 만한 경험들 추론
4. 그 경험에서 배울 수 있는 교훈
5. 2026년으로 이어지는 연결고리

## 특별 지침
- 과거 분석이므로 "~했을 것이다", "~경험했을 수 있다" 형태로 작성
- 맹목적 예측이 아닌, 사주 원리에 기반한 합리적 추론
- 긍정적 측면과 개선점 모두 균형있게 제시
- 2026년을 위한 실질적 교훈 도출

## 응답 형식
반드시 아래 JSON 형식으로 응답하세요. 다른 텍스트 없이 순수 JSON만 반환합니다.
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
위 평생 사주 분석을 바탕으로 2025년 을사(乙巳)년을 회고 분석해주세요.
과거를 되돌아보며 배울 점과 2026년으로 이어지는 교훈을 제시해주세요.

## 응답 JSON 스키마
{
  "year": 2025,
  "yearGanji": "을사(乙巳)",
  "overallScore": 68,
  "summary": "2025년 회고 요약 (2-3문장)",

  "retrospective": {
    "achievements": [
      "성취했거나 성취 가능했던 것 1",
      "성취했거나 성취 가능했던 것 2",
      "성취했거나 성취 가능했던 것 3"
    ],
    "challenges": [
      "어려웠거나 어려웠을 점 1",
      "어려웠거나 어려웠을 점 2",
      "어려웠거나 어려웠을 점 3"
    ],
    "lessons": [
      "배울 수 있는 교훈 1",
      "배울 수 있는 교훈 2",
      "배울 수 있는 교훈 3"
    ]
  },

  "quarterlyReview": {
    "q1": {
      "months": "1-3월",
      "theme": "1분기 테마",
      "insight": "1분기 인사이트"
    },
    "q2": {
      "months": "4-6월",
      "theme": "2분기 테마",
      "insight": "2분기 인사이트"
    },
    "q3": {
      "months": "7-9월",
      "theme": "3분기 테마",
      "insight": "3분기 인사이트"
    },
    "q4": {
      "months": "10-12월",
      "theme": "4분기 테마",
      "insight": "4분기 인사이트"
    }
  },

  "carryForward": {
    "strengths": "2026년에 가져갈 강점 (2-3문장)",
    "improvements": "개선하면 좋을 점 (2-3문장)",
    "advice": "앞으로의 조언 (2-3문장)"
  }
}
''';
  }

  /// saju_base 내용을 포맷팅
  String _formatSajuBase() {
    final content = inputData.sajuBaseContent;
    final buffer = StringBuffer();

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

    if (inputData.sajuOrigin != null) {
      buffer.writeln('\n### 원국 정보');
      buffer.writeln('- 일간: ${inputData.sajuOrigin!['day_stem'] ?? ''}');
      buffer.writeln('- 용신: ${inputData.sajuOrigin!['yongshin'] ?? ''}');
    }

    return buffer.toString();
  }
}
