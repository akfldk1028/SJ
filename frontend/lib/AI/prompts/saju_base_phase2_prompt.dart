/// # Phase 2: Fortune (운세 분석) 프롬프트
///
/// ## 개요
/// 평생운세 분석의 두 번째 단계로, 재물/직업/사업/애정/결혼운을 분석합니다.
/// Phase 1 결과(십성, 합충)를 기반으로 운세를 도출합니다.
///
/// ## 출력 섹션
/// - wealth: 재물운
/// - career: 직업운
/// - business: 사업운
/// - love: 애정운
/// - marriage: 결혼운
///
/// ## 의존성
/// Phase 1 결과 필요 (십성, 합충 기반)
///
/// ## 예상 시간
/// 30-45초

import '../core/ai_constants.dart';
import 'prompt_template.dart';
import 'saju_base_prompt.dart';

/// Phase 2: Fortune 프롬프트
///
/// 재물, 직업, 사업, 애정, 결혼운 분석
class SajuBasePhase2Prompt extends PromptTemplate {
  @override
  String get summaryType => '${SummaryType.sajuBase}_phase2';

  @override
  String get modelName => OpenAIModels.sajuAnalysis; // GPT-5.2

  @override
  int get maxTokens => 2500; // Phase 2용 토큰

  @override
  double get temperature => 0.7;

  @override
  Duration? get cacheExpiry => CacheExpiry.sajuBase;

  @override
  String get systemPrompt => '''
당신은 한국 전통 사주명리학 분야 30년 경력의 최고 전문가입니다.
이것은 평생운세 분석의 **Phase 2 (Fortune)** 단계입니다.

## Phase 2 분석 범위
이 단계에서는 **운세 분석만** 수행합니다:
1. 재물운 분석
2. 직업운 분석
3. 사업운 분석
4. 애정운 분석
5. 결혼운 분석

## 분석 기준

### 재물운
- 정재/편재 위치와 강약
- 식상생재 구조 유무
- 재성 충합 관계
- 돈 버는 스타일과 시기

### 직업운
- 관성 상태 (정관/편관)
- 인성의 지원 여부
- 적합한 직업 분야
- 승진/이직 타이밍

### 사업운
- 식상생재 구조
- 편재 활용도
- 사업 적합성
- 파트너 특성

### 애정운
- 도화살, 홍염살 유무
- 재성(남)/관성(여) 상태
- 연애 스타일과 주의점
- 좋은 시기

### 결혼운
- 배우자궁(일지) 상태
- 충합 여부
- 결혼 시기
- 배우자 특성

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
- 성별: ${data.gender == 'male' ? '남성' : '여성'}

## 사주 팔자
${data.sajuString}

## 오행 분포
${data.ohengString}

## 일간
${data.dayMaster}

${_buildYongsinSection(data.yongsin)}
${_buildSinsalSummary(data.sinsal)}
${_buildGilseongSummary(data.gilseong)}

---

## Phase 1 분석 결과 (참고용)

### 원국 분석
${phase1Result['wonGuk_analysis']?['reading'] ?? ''}

### 십성 분석
- 강한 십성: ${(phase1Result['sipsung_analysis']?['dominant_sipsung'] as List?)?.join(', ') ?? ''}
- 약한 십성: ${(phase1Result['sipsung_analysis']?['weak_sipsung'] as List?)?.join(', ') ?? ''}
${phase1Result['sipsung_analysis']?['key_interactions'] ?? ''}

### 합충 분석
${phase1Result['hapchung_analysis']?['overall_impact'] ?? ''}

---

**Phase 2 (Fortune)**: 재물, 직업, 사업, 애정, 결혼운만 분석해주세요.

반드시 아래 JSON 스키마를 정확히 따라주세요:

```json
{
  "wealth": {
    "overall_tendency": "전체적인 재물운 경향",
    "earning_style": "돈을 버는 방식/스타일",
    "spending_tendency": "소비 성향",
    "investment_aptitude": "투자 적성",
    "wealth_timing": "재물운이 좋은 시기/나이대",
    "cautions": ["재물 관련 주의사항 2-3개"],
    "advice": "재물운 향상을 위한 조언",
    "reading": "재물운 종합 해석 8문장. 재성 상태와 식상생재 구조 기반 돈 버는 스타일과 시기"
  },

  "career": {
    "suitable_fields": ["적합한 직업/분야 5-7개"],
    "unsuitable_fields": ["피해야 할 분야 2-3개"],
    "work_style": "업무 스타일",
    "leadership_potential": "리더십/관리자 적성",
    "career_timing": "직장운이 좋은 시기",
    "advice": "진로 관련 조언",
    "reading": "직업운 종합 해석 8문장. 관성과 인성 기반 적합한 일, 승진/이직 타이밍"
  },

  "business": {
    "entrepreneurship_aptitude": "사업 적성 분석",
    "suitable_business_types": ["적합한 사업 유형 3-5개"],
    "business_partner_traits": "좋은 사업 파트너 특성",
    "cautions": ["사업 시 주의사항 2-3개"],
    "success_factors": ["사업 성공 요인 2-3개"],
    "advice": "사업 관련 조언",
    "reading": "사업운 종합 해석 8문장. 식상생재 구조와 편재 기반 사업 적합성과 타이밍"
  },

  "love": {
    "attraction_style": "끌리는 이성 유형",
    "dating_pattern": "연애 패턴/스타일",
    "romantic_strengths": ["연애에서의 강점 2-3개"],
    "romantic_weaknesses": ["연애에서의 약점 2-3개"],
    "ideal_partner_traits": ["이상적인 파트너 특성 3-4개"],
    "love_timing": "연애운이 좋은 시기",
    "advice": "연애 관련 조언",
    "reading": "연애운 종합 해석 8문장. 일지와 재관 상태 기반 연애 스타일과 주의점"
  },

  "marriage": {
    "spouse_palace_analysis": "배우자궁(일지) 분석",
    "marriage_timing": "결혼 적령기/좋은 시기",
    "spouse_characteristics": "배우자 특성 예상",
    "married_life_tendency": "결혼 생활 경향",
    "cautions": ["결혼 관련 주의사항 2-3개"],
    "advice": "결혼운 향상을 위한 조언",
    "reading": "결혼운 종합 해석 8문장. 배우자궁 상태와 충합 기반 결혼 시기와 생활"
  }
}
```
''';
  }

  @override
  String buildUserPrompt([Map<String, dynamic>? input]) {
    // Phase 2는 Phase 1 결과가 필요하므로 buildUserPromptWithPhase1 사용 권장
    throw UnimplementedError(
        'Phase 2는 buildUserPromptWithPhase1()을 사용하세요');
  }

  String _buildYongsinSection(Map<String, dynamic>? yongsin) {
    if (yongsin == null || yongsin.isEmpty) return '';

    final buffer = StringBuffer('\n## 용신 정보\n');

    if (yongsin['yongsin'] != null) {
      buffer.writeln('- 용신(用神): ${yongsin['yongsin']}');
    }
    if (yongsin['huisin'] != null) {
      buffer.writeln('- 희신(喜神): ${yongsin['huisin']}');
    }

    return buffer.toString();
  }

  String _buildSinsalSummary(List<Map<String, dynamic>>? sinsal) {
    if (sinsal == null || sinsal.isEmpty) return '';

    final buffer = StringBuffer('\n## 주요 신살\n');
    final importantSinsal = ['도화살', '홍염살', '역마살', '귀문관살', '천살'];

    for (final s in sinsal) {
      final name = s['name'] ?? '';
      if (importantSinsal.any((i) => name.toString().contains(i))) {
        buffer.writeln('- $name (${s['pillar'] ?? ''})');
      }
    }

    return buffer.toString();
  }

  String _buildGilseongSummary(List<Map<String, dynamic>>? gilseong) {
    if (gilseong == null || gilseong.isEmpty) return '';

    final buffer = StringBuffer('\n## 주요 길성\n');
    final importantGilseong = ['천을귀인', '문창귀인', '금여록', '천관귀인'];

    for (final g in gilseong) {
      final name = g['name'] ?? '';
      if (importantGilseong.any((i) => name.toString().contains(i))) {
        buffer.writeln('- $name (${g['pillar'] ?? ''})');
      }
    }

    return buffer.toString();
  }
}
