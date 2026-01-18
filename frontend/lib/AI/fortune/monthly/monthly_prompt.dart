/// # 이번달 운세 프롬프트
///
/// ## 개요
/// saju_base(평생운세)를 기반으로 이번달 운세 분석
///
/// ## 파일 위치
/// `frontend/lib/AI/fortune/monthly/monthly_prompt.dart`
///
/// ## 모델
/// GPT-5-mini ($0.25 input, $2.00 output per 1M tokens)

import '../../core/ai_constants.dart';
import '../../prompts/prompt_template.dart';
import '../common/fortune_input_data.dart';

/// 이번달 운세 프롬프트 템플릿
class MonthlyPrompt extends PromptTemplate {
  /// 입력 데이터 (saju_base 포함)
  final FortuneInputData inputData;

  /// 대상 연도
  final int targetYear;

  /// 대상 월
  final int targetMonth;

  const MonthlyPrompt({
    required this.inputData,
    required this.targetYear,
    required this.targetMonth,
  });

  @override
  String get summaryType => SummaryType.monthlyFortune;

  @override
  String get modelName => OpenAIModels.fortuneAnalysis; // gpt-5-mini

  @override
  int get maxTokens => 2048;

  @override
  double get temperature => 0.7;

  @override
  Duration? get cacheExpiry => CacheExpiry.monthlyFortune;

  /// 월별 간지 (2026년 기준)
  String get _monthGanji {
    // 2026년 월별 간지 (병오년)
    const ganjiByMonth = {
      1: '경인(庚寅)',
      2: '신묘(辛卯)',
      3: '임진(壬辰)',
      4: '계사(癸巳)',
      5: '갑오(甲午)',
      6: '을미(乙未)',
      7: '병신(丙申)',
      8: '정유(丁酉)',
      9: '무술(戊戌)',
      10: '기해(己亥)',
      11: '경자(庚子)',
      12: '신축(辛丑)',
    };
    return ganjiByMonth[targetMonth] ?? '';
  }

  @override
  String get systemPrompt => '''
당신은 사주명리학 전문가입니다.
사용자의 평생 사주 분석(saju_base)을 기반으로 ${targetYear}년 ${targetMonth}월 운세를 분석합니다.

## 분석 기준
1. saju_base의 성격/적성/재물운 등을 이번달 운기와 연결
2. ${targetYear}년 ${targetMonth}월 $_monthGanji 월의 영향 분석
3. 주간별 운기 변화
4. 길일/흉일 도출
5. 실생활에 적용 가능한 구체적 조언

## 응답 형식
반드시 아래 JSON 형식으로 응답하세요. 다른 텍스트 없이 순수 JSON만 반환합니다.

## 톤앤매너
- 긍정적이면서도 현실적인 조언
- 구체적인 날짜와 함께 실천 가능한 팁
- 친근하고 이해하기 쉬운 설명
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
위 평생 사주 분석을 바탕으로 ${targetYear}년 ${targetMonth}월 운세를 분석해주세요.

## 응답 JSON 스키마
{
  "year": $targetYear,
  "month": $targetMonth,
  "monthGanji": "$_monthGanji",
  "overallScore": 72,
  "summary": "이번달 운세 요약 (2-3문장)",

  "weekly": {
    "week1": {
      "dates": "1-7일",
      "score": 70,
      "focus": "첫째 주 핵심 포인트"
    },
    "week2": {
      "dates": "8-14일",
      "score": 75,
      "focus": "둘째 주 핵심 포인트"
    },
    "week3": {
      "dates": "15-21일",
      "score": 68,
      "focus": "셋째 주 핵심 포인트"
    },
    "week4": {
      "dates": "22-말일",
      "score": 80,
      "focus": "넷째 주 핵심 포인트"
    }
  },

  "categories": {
    "career": { "score": 75, "tip": "직업/사업 팁" },
    "wealth": { "score": 70, "tip": "재물 팁" },
    "love": { "score": 72, "tip": "애정 팁" },
    "health": { "score": 80, "tip": "건강 팁" }
  },

  "luckyDays": [3, 12, 21],
  "cautionDays": [7, 16],

  "monthAdvice": "이번달 핵심 조언 (2-3문장)"
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

    if (inputData.sajuOrigin != null) {
      buffer.writeln('\n### 원국 정보');
      buffer.writeln('- 일간: ${inputData.sajuOrigin!['day_stem'] ?? ''}');
    }

    return buffer.toString();
  }
}
