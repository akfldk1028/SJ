/// # Phase 3: Special (특수 분석) 프롬프트
///
/// ## 개요
/// 평생운세 분석의 세 번째 단계로, 신살/길성, 건강운, 대운 상세를 분석합니다.
/// Phase 1 결과를 기반으로 특수 분석을 수행합니다.
///
/// ## 출력 섹션
/// - sinsal_gilseong: 신살/길성 분석
/// - health: 건강운 분석
/// - daeun_detail: 대운 상세 분석
///
/// ## 의존성
/// Phase 1 결과 필요
///
/// ## 예상 시간
/// 30-45초
///
/// ## 병렬 실행
/// Phase 2와 병렬 실행 가능 (둘 다 Phase 1에만 의존)

import '../core/ai_constants.dart';
import 'prompt_template.dart';
import 'saju_base_prompt.dart';

/// Phase 3: Special 프롬프트
///
/// 신살/길성, 건강운, 대운 상세 분석
class SajuBasePhase3Prompt extends PromptTemplate {
  @override
  String get summaryType => '${SummaryType.sajuBase}_phase3';

  @override
  String get modelName => OpenAIModels.sajuAnalysis; // GPT-5.2

  @override
  int get maxTokens => 5000; // Phase 3용 토큰 (2500→5000 확장, daeun_detail.cycles 대응)

  @override
  double get temperature => 0.7;

  @override
  Duration? get cacheExpiry => CacheExpiry.sajuBase;

  @override
  String get systemPrompt => '''
당신은 한국 전통 사주명리학 분야 30년 경력의 최고 전문가입니다.
이것은 평생운세 분석의 **Phase 3 (Special)** 단계입니다.

## Phase 3 분석 범위
이 단계에서는 **특수 분석만** 수행합니다:
1. 신살/길성 종합 분석
2. 건강운 분석
3. 대운 상세 분석

## 분석 기준

### 신살/길성 분석
- 주요 길성의 의미와 활용법
- 주요 신살의 의미와 대처법
- 실생활에 미치는 영향

### 건강운 분석
- 오행 과다/부족에 따른 취약 장기
- 주의해야 할 건강 문제
- 정신/심리 건강 경향
- 생활 습관 조언

### 대운 상세 분석
- 현재 대운 심층 분석
- 다음 대운 전망
- 최고의 대운 시기
- 주의해야 할 대운 시기
- 각 대운별 기회와 시련

## 응답 형식
반드시 JSON 형식으로만 응답하세요. 추가 설명 없이 순수 JSON만 출력하세요.
''';

  /// Phase 1 결과를 포함한 User Prompt 생성
  String buildUserPromptWithPhase1(
    Map<String, dynamic> input,
    Map<String, dynamic> phase1Result,
  ) {
    final data = SajuInputData.fromJson(input);

    return '''
## 분석 대상
- 이름: ${data.profileName}
- 생년월일: ${_formatBirthDate(data.birthDate)}
- 성별: ${data.gender == 'male' ? '남성' : '여성'}

## 사주 팔자
${data.sajuString}

## 오행 분포
${data.ohengString}

## 일간
${data.dayMaster}

${_buildSinsalSection(data.sinsal)}
${_buildGilseongSection(data.gilseong)}
${_buildUnsungSection(data.twelveUnsung)}
${_buildDaeunSection(data.daeun)}

---

## Phase 1 분석 결과 (참고용)

### 원국 분석
- 오행 균형: ${phase1Result['wonGuk_analysis']?['oheng_balance'] ?? ''}
- 신강/신약: ${phase1Result['wonGuk_analysis']?['singang_singak'] ?? ''}

### 합충 분석
${phase1Result['hapchung_analysis']?['overall_impact'] ?? ''}

---

**Phase 3 (Special)**: 신살/길성, 건강, 대운상세만 분석해주세요.

반드시 아래 JSON 스키마를 정확히 따라주세요:

```json
{
  "sinsal_gilseong": {
    "major_gilseong": ["주요 길성과 그 의미"],
    "major_sinsal": ["주요 신살과 그 의미"],
    "practical_implications": "신살/길성이 실생활에 미치는 영향",
    "reading": "신살/길성 종합 해석 6문장. 주요 신살이 인생에 가져오는 복과 시련"
  },

  "health": {
    "vulnerable_organs": ["건강 취약 장기/부위 2-4개"],
    "potential_issues": ["주의해야 할 건강 문제 2-3개"],
    "mental_health": "정신/심리 건강 경향",
    "lifestyle_advice": ["건강 관리 생활 습관 조언 3-4개"],
    "caution_periods": "건강 주의 시기 (있는 경우)",
    "reading": "건강운 종합 해석 6문장. 오행 과다/부족 기반 취약 장기와 관리법"
  },

  "daeun_detail": {
    "intro": "대운 흐름 전체 개요 3문장",
    "cycles": [
      {
        "order": 1,
        "pillar": "현재 대운 간지",
        "age_range": "현재 대운 나이 구간",
        "main_theme": "현재 대운 핵심 주제",
        "fortune_level": "상/중상/중/중하/하",
        "reading": "현재 대운 5문장. 용신 관계, 해야 할 것, 주의사항",
        "opportunities": ["기회 2개"],
        "challenges": ["시련 2개"]
      },
      {
        "order": 2,
        "pillar": "다음 대운 간지",
        "age_range": "다음 대운 나이 구간",
        "main_theme": "다음 대운 핵심 주제",
        "fortune_level": "상/중상/중/중하/하",
        "reading": "다음 대운 5문장. 준비할 것, 기대 포인트",
        "opportunities": ["기회 2개"],
        "challenges": ["시련 2개"]
      },
      {
        "order": 3,
        "pillar": "최고 대운 간지 (best_daeun 시기)",
        "age_range": "최고 대운 나이 구간",
        "main_theme": "최고 대운 핵심 주제",
        "fortune_level": "상",
        "reading": "최고 대운 5문장. 왜 최고인지, 활용법",
        "opportunities": ["기회 2개"],
        "challenges": ["주의점 1개"]
      }
    ],
    "best_daeun": {
      "period": "가장 좋은 대운 시기",
      "why": "왜 이 대운이 가장 좋은지 3문장"
    },
    "worst_daeun": {
      "period": "가장 주의해야 할 대운 시기",
      "why": "왜 이 대운을 조심해야 하는지 3문장"
    }
  }
}
```
''';
  }

  @override
  String buildUserPrompt([Map<String, dynamic>? input]) {
    throw UnimplementedError(
        'Phase 3는 buildUserPromptWithPhase1()을 사용하세요');
  }

  String _formatBirthDate(DateTime date) {
    return '${date.year}년 ${date.month}월 ${date.day}일';
  }

  String _buildSinsalSection(List<Map<String, dynamic>>? sinsal) {
    if (sinsal == null || sinsal.isEmpty) return '';

    final buffer = StringBuffer('\n## 신살 정보\n');

    for (final s in sinsal) {
      final name = s['name'] ?? '';
      final pillar = s['pillar'] ?? '';
      final meaning = s['meaning'] ?? '';
      buffer.writeln('- $name ($pillar): $meaning');
    }

    return buffer.toString();
  }

  String _buildGilseongSection(List<Map<String, dynamic>>? gilseong) {
    if (gilseong == null || gilseong.isEmpty) return '';

    final buffer = StringBuffer('\n## 길성 정보\n');

    for (final g in gilseong) {
      final name = g['name'] ?? '';
      final pillar = g['pillar'] ?? '';
      final meaning = g['meaning'] ?? '';
      buffer.writeln('- $name ($pillar): $meaning');
    }

    return buffer.toString();
  }

  String _buildUnsungSection(List<dynamic>? unsung) {
    if (unsung == null || unsung.isEmpty) return '';

    final buffer = StringBuffer('\n## 12운성\n');

    for (final item in unsung) {
      if (item is Map) {
        final pillar = item['pillar'] ?? '';
        final unsungName = item['unsung'] ?? '';
        final fortuneType = item['fortuneType'] ?? '';
        if (unsungName.toString().isNotEmpty) {
          buffer.writeln('- $pillar: $unsungName ($fortuneType)');
        }
      }
    }

    return buffer.toString();
  }

  String _buildDaeunSection(Map<String, dynamic>? daeun) {
    if (daeun == null || daeun.isEmpty) return '';

    final buffer = StringBuffer('\n## 대운 (大運) - 상세 정보\n');

    // 대운 시작 나이
    final startAge = daeun['start_age'];
    if (startAge != null) {
      buffer.writeln('- 대운 시작: $startAge세');
    }

    // 현재 대운
    final current = daeun['current'];
    if (current != null && current is Map) {
      final gan = current['gan'] ?? '';
      final ji = current['ji'] ?? '';
      final startYear = current['start_year'];
      final endYear = current['end_year'];

      buffer.write('- 현재 대운: $gan$ji');
      if (startYear != null && endYear != null) {
        buffer.writeln(' ($startYear~$endYear)');
      } else {
        buffer.writeln('');
      }
    }

    // 대운 전체 목록
    final list = daeun['list'];
    if (list != null && list is List && list.isNotEmpty) {
      buffer.writeln('\n### 대운 흐름 (전체)');
      for (int i = 0; i < list.length && i < 8; i++) {
        final d = list[i];
        if (d is Map) {
          final gan = d['gan'] ?? '';
          final ji = d['ji'] ?? '';
          final startYear = d['start_year'] ?? '';
          final endYear = d['end_year'] ?? '';
          buffer.writeln(
              '${i + 1}. $gan$ji (${startYear}~${endYear})');
        }
      }
    }

    return buffer.toString();
  }
}
