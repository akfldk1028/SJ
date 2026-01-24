/// # Phase 4: Synthesis (종합 분석) 프롬프트
///
/// ## 개요
/// 평생운세 분석의 마지막 단계로, 전체 결과를 종합하여
/// 요약, 인생주기, 전성기, 현대해석을 제공합니다.
///
/// ## 출력 섹션
/// - summary: 전체 요약
/// - life_cycles: 인생 주기별 전망
/// - peak_years: 인생 전성기
/// - modern_interpretation: AI시대 현대적 해석
///
/// ## 의존성
/// Phase 1, 2, 3 결과 모두 필요
///
/// ## 예상 시간
/// 45-60초

import '../core/ai_constants.dart';
import 'prompt_template.dart';
import 'saju_base_prompt.dart';

/// Phase 4: Synthesis 프롬프트
///
/// 전체 종합: 요약, 인생주기, 전성기, 현대해석
class SajuBasePhase4Prompt extends PromptTemplate {
  @override
  String get summaryType => '${SummaryType.sajuBase}_phase4';

  @override
  String get modelName => OpenAIModels.sajuAnalysis; // GPT-5.2

  @override
  int get maxTokens => 8000; // Phase 4용 토큰 (4000→8000 확장, JSON 잘림 방지)

  @override
  double get temperature => 0.7;

  @override
  Duration? get cacheExpiry => CacheExpiry.sajuBase;

  @override
  String get systemPrompt => '''
당신은 한국 전통 사주명리학 분야 30년 경력의 최고 전문가입니다.
이것은 평생운세 분석의 **Phase 4 (Synthesis)** 단계입니다.

## Phase 4 분석 범위
이 단계에서는 **종합 분석만** 수행합니다:
1. 전체 사주 요약
2. 인생 주기별 전망 (청년/중년/후년)
3. 인생 전성기 분석
4. AI시대 현대적 해석

## 분석 기준

### 전체 요약
- Phase 1~3 분석 결과를 압축
- 이 사람 사주의 핵심 특성
- 가장 중요한 운세 포인트

### 인생 주기
- 청년기(20-35세): 핵심 기회와 집중 포인트
- 중년기(35-55세): 가정/직장/재물 흐름
- 후년기(55세+): 건강/가족/여유 흐름
- 인생 중요 전환점 나이

### 인생 전성기
- 최전성기 구간 (예: 38-48세)
- 왜 이 시기가 최전성기인지
- 준비사항과 해야 할 것
- 주의점

### AI시대 현대 해석
| 전통 요소 | 전통 의미 | AI시대 적용 |
|----------|----------|-------------|
| 식상 | 자녀운/표현력 | 콘텐츠창작/SNS/유튜브 |
| 역마살 | 먼여행/이사 | 디지털노마드/원격근무 |
| 도화살 | 이성매력/예술 | 인플루언서/마케팅 |
| 인성 | 학문/자격증 | AI활용능력/코딩 |
| 재성 | 재물/토지 | 디지털자산/N잡/스타트업 |
| 비겁 | 형제/경쟁 | 네트워킹/커뮤니티/협업 |

## 응답 형식
반드시 JSON 형식으로만 응답하세요. 추가 설명 없이 순수 JSON만 출력하세요.
''';

  /// Phase 1~3 결과를 포함한 User Prompt 생성
  String buildUserPromptWithAllPhases(
    Map<String, dynamic> input,
    Map<String, dynamic> phase1Result,
    Map<String, dynamic> phase2Result,
    Map<String, dynamic> phase3Result,
  ) {
    final data = SajuInputData.fromJson(input);

    return '''
## 분석 대상
- 이름: ${data.profileName}
- 생년월일: ${_formatBirthDate(data.birthDate)}
- 성별: ${data.gender == 'male' ? '남성' : '여성'}

## 사주 팔자
${data.sajuString}

## 일간
${data.dayMaster}

---

## Phase 1 결과 요약 (Foundation)

### 원국
${phase1Result['wonGuk_analysis']?['reading'] ?? ''}

### 십성
- 강한 십성: ${(phase1Result['sipsung_analysis']?['dominant_sipsung'] as List?)?.join(', ') ?? ''}
${phase1Result['sipsung_analysis']?['life_implications'] ?? ''}

### 성격
- 핵심 특성: ${(phase1Result['personality']?['core_traits'] as List?)?.join(', ') ?? ''}
${phase1Result['personality']?['social_style'] ?? ''}

### 행운 요소
- 색: ${(phase1Result['lucky_elements']?['colors'] as List?)?.join(', ') ?? ''}
- 방향: ${(phase1Result['lucky_elements']?['directions'] as List?)?.join(', ') ?? ''}
- 계절: ${phase1Result['lucky_elements']?['seasons'] ?? ''}

---

## Phase 2 결과 요약 (Fortune)

### 재물운
${phase2Result['wealth']?['overall_tendency'] ?? ''}
- 좋은 시기: ${phase2Result['wealth']?['wealth_timing'] ?? ''}

### 직업운
- 적합 분야: ${(phase2Result['career']?['suitable_fields'] as List?)?.take(5).join(', ') ?? ''}
${phase2Result['career']?['work_style'] ?? ''}

### 사업운
${phase2Result['business']?['entrepreneurship_aptitude'] ?? ''}

### 애정/결혼운
${phase2Result['love']?['dating_pattern'] ?? ''}
- 결혼 시기: ${phase2Result['marriage']?['marriage_timing'] ?? ''}

---

## Phase 3 결과 요약 (Special)

### 신살/길성
${phase3Result['sinsal_gilseong']?['practical_implications'] ?? ''}

### 건강
- 취약 부위: ${(phase3Result['health']?['vulnerable_organs'] as List?)?.join(', ') ?? ''}

### 대운 핵심
- 최고 대운: ${phase3Result['daeun_detail']?['best_daeun']?['period'] ?? ''}
- 주의 대운: ${phase3Result['daeun_detail']?['worst_daeun']?['period'] ?? ''}

---

**Phase 4 (Synthesis)**: 전체 종합하여 요약, 인생주기, 전성기, 현대해석을 분석해주세요.

반드시 아래 JSON 스키마를 정확히 따라주세요:

```json
{
  "summary": "이 사주의 핵심 특성을 10문장으로 간결하게 요약",

  "life_cycles": {
    "youth": "청년기(20-35세) 전망 5문장. 이 시기 핵심 기회와 집중 포인트",
    "middle_age": "중년기(35-55세) 전망 5문장. 가정/직장/재물 핵심 흐름",
    "later_years": "후년기(55세 이후) 전망 5문장. 건강/가족/여유 핵심 흐름",
    "key_years": ["인생 중요 전환점 3-4개 (예: 28세, 42세, 51세)"]
  },

  "peak_years": {
    "period": "최전성기 구간 (예: 38-48세)",
    "age_range": [38, 48],
    "why": "왜 이 시기가 최전성기인지 8문장. 용신운과 기회 설명",
    "what_to_prepare": "최전성기 준비사항 3문장",
    "what_to_do": "최전성기에 해야 할 것 3문장",
    "cautions": "최전성기 주의점 2문장"
  },

  "modern_interpretation": {
    "dominant_elements": [
      {
        "element": "사주에서 강한 요소 (예: 식상, 역마살, 도화살 등)",
        "traditional": "전통적 의미",
        "modern": "AI시대 적용",
        "advice": "현대 사회에서 활용법"
      }
    ],
    "career_in_ai_era": {
      "traditional_path": "전통적 진로 해석",
      "modern_opportunities": ["AI시대 적합 직업/분야 3-5개"],
      "digital_strengths": "디지털/IT 분야 강점"
    },
    "wealth_in_ai_era": {
      "traditional_view": "전통적 재물운 해석",
      "modern_opportunities": ["디지털자산/투자/부업 등 현대 재물 기회"],
      "risk_factors": "현대 재테크 주의점"
    },
    "relationships_in_ai_era": {
      "traditional_view": "전통적 대인관계 해석",
      "modern_networking": "온라인/SNS 네트워킹 스타일",
      "collaboration_style": "현대 협업 방식"
    }
  }
}
```
''';
  }

  @override
  String buildUserPrompt([Map<String, dynamic>? input]) {
    throw UnimplementedError(
        'Phase 4는 buildUserPromptWithAllPhases()를 사용하세요');
  }

  String _formatBirthDate(DateTime date) {
    return '${date.year}년 ${date.month}월 ${date.day}일';
  }
}
