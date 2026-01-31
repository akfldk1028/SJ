/// # 기본 사주 분석 프롬프트 (GPT-5.2용)
///
/// ## 개요
/// 프로필 저장 시 1회 실행되는 평생 사주 분석 프롬프트입니다.
/// GPT-5.2 모델을 사용하여 가장 정확한 분석을 제공합니다.
///
/// ## 파일 위치
/// `frontend/lib/AI/fortune/lifetime/lifetime_prompt.dart`
///
/// ## 분석 내용
/// - 타고난 성격과 기질
/// - 적성과 재능
/// - 대인관계 특성
/// - 건강 취약점
/// - 재물운 경향
/// - 직업/진로 적합성
/// - 연애/결혼운 특성
///
/// ## 입력 데이터 (SajuInputData)
/// ```dart
/// {
///   'profile_id': 'uuid',
///   'profile_name': '이름',
///   'birth_date': '1990-01-15',
///   'gender': 'male',
///   'saju': {'year_gan': '경', ...},
///   'oheng': {'wood': 2, 'fire': 1, ...},
///   'yongsin': {'yongsin': '금(金)', ...},
///   'day_strength': {'is_singang': true, 'score': 65},
///   'sinsal': [...],
///   'gilseong': [...],
/// }
/// ```
///
/// ## 출력 형식 (JSON)
/// ```json
/// {
///   "summary": "한 문장 요약",
///   "personality": {...},
///   "career": {...},
///   "relationships": {...},
///   "wealth": {...},
///   "health": {...},
///   "overall_advice": "...",
///   "lucky_elements": {...}
/// }
/// ```
///
/// ## 호출 흐름
/// ```
/// profile_provider.dart
///   → _triggerAiAnalysis()
///     → SajuAnalysisService.analyzeOnProfileSave()
///       → _runSajuBaseAnalysis()
///         → SajuBasePrompt.buildMessages()
///           → AiApiService.callOpenAI()
///             → Edge Function (ai-openai)
///               → OpenAI API (GPT-5.2)
/// ```
///
/// ## 캐시 정책
/// - 만료 기간: 무기한 (null)
/// - 프로필이 변경되지 않는 한 재생성 불필요
/// - upsert로 동일 profile_id에 대해 덮어쓰기
///
/// ## 비용 참고 (2025-12 기준)
/// - GPT-5.2: 입력 $1.75/1M, 출력 $14.00/1M, 캐시 90% 할인
/// - 평균 분석 1회: 약 $0.02~0.05

import '../../core/ai_constants.dart';
import '../common/prompt_template.dart';

/// 기본 사주 분석 프롬프트
///
/// ## 사용 예시
/// ```dart
/// final prompt = SajuBasePrompt();
/// final messages = prompt.buildMessages(sajuInputData.toJson());
///
/// final response = await aiApiService.callOpenAI(
///   messages: messages,
///   model: prompt.modelName,          // gpt-5.2
///   maxTokens: prompt.maxTokens,      // 4096
///   temperature: prompt.temperature,  // 0.7
/// );
/// ```
///
/// ## 프롬프트 구조
/// 1. **System Prompt**: 사주명리학 전문가 역할 정의
/// 2. **User Prompt**: 사주 데이터 + JSON 출력 스키마
///
/// ## JSON 출력 필드
/// | 필드 | 설명 |
/// |------|------|
/// | summary | 사주 특성 한 문장 요약 |
/// | personality | 성격 분석 (traits, strengths, weaknesses) |
/// | career | 진로 적합성 (suitable_fields, work_style) |
/// | relationships | 대인관계 (social_style, compatibility_tips) |
/// | wealth | 재물운 (tendency, advice) |
/// | health | 건강 (vulnerable_areas, advice) |
/// | overall_advice | 종합 인생 조언 |
/// | lucky_elements | 행운 요소 (colors, directions, numbers) |
class SajuBasePrompt extends PromptTemplate {
  @override
  String get summaryType => SummaryType.sajuBase;

  @override
  String get modelName => OpenAIModels.sajuAnalysis; // GPT-5.2

  @override
  int get maxTokens => TokenLimits.sajuBaseMaxTokens;

  @override
  double get temperature => 0.7;

  @override
  Duration? get cacheExpiry => CacheExpiry.sajuBase;

  @override
  String get systemPrompt => '''
당신은 한국 전통 사주명리학 분야 30년 경력의 최고 전문가입니다.
전통사주를  분석하되 현대시대에 어울리는 해석을 명쾌하게 해주세요.
원국(原局)을 철저히 분석하여 정확하고 깊이 있는 사주 해석을 제공합니다.

## 분석 방법론 (반드시 순서대로)

### 1단계: 원국 구조 분석

### 2단계: 십성(十星) 분석


### 3단계: 신살(神殺) & 길성(吉星) 해석

### 4단계: 합충형파해(合沖刑破害) 분석


**합(合) 결속력 순서**
- 방합(최강/고정적) > 삼합(유연) > 반합(불완전) > 육합(부드러움)
- 방합 있으면 해당 오행 매우 강력! 삼합보다 방합 먼저 확인

**⚠️ 3글자 완성 조건 (매우 중요!)**
- 삼합: 3글자 모두 있어야 완성 (木局:亥卯未 / 火局:寅午戌 / 金局:巳酉丑 / 水局:申子辰)
- 방합: 3글자 모두 있어야 완성 (水局:亥子丑 / 木局:寅卯辰 / 火局:巳午未 / 金局:申酉戌)
- 반합: 왕지(子午卯酉) 포함 2글자만 있을 때 → 삼합보다 약함
- 왕지 없이 2글자만 있으면 반합 성립 안 됨!

**충(沖) 파괴력 순서**
- 왕지충(묘유/자오, 원수충) > 생지충(인신/사해, 역마) > 고지충(진술/축미)
- 충 영향력: 일지 > 월지 > 연지 > 시지

**형(刑) 흉의 강도 순서**
- 삼형(인사신/축술미 5 관재/배신) > 상형(2자3) > 자묘형(2 무례) > 자형(1)
- 3자 모두 있으면 흉 최강! 2자만 있으면 감소

### 5단계: 12운성 분석


### 6단계: 종합 해 석 (아래 영역별로 상세 분석)
1. **재물운**: 정재/편재 위치, 강약, 충합 관계
2. **연애운**: 도화살, 홍염살, 재성/관성 상태
3. **결혼운**: 배우자궁(일지) 상태, 충합 여부
4. **사업운**: 식상생재 구조, 편재 활용도
5. **직장운**: 관성 상태, 인성의 지원 여부
6. **건강운**: 오행 편중, 충형 위치

### 7단계: 전통 vs AI시대 해석 비교
> 각 요소의 전통적 의미와 현대(AI시대) 적용을 함께 제시

| 요소 | 전통 의미 | AI시대 적용 |
|------|----------|-------------|
| 식상(食傷) | 자녀운/표현력/재능 | 콘텐츠창작/SNS/유튜브/블로그 |
| 역마살 | 먼여행/이사/변동 | 디지털노마드/해외근무/원격근무 |
| 도화살 | 이성매력/예술성 | 인플루언서/대중인기/연예/마케팅 |
| 인성(印星) | 학문/스승/자격증 | AI활용능력/온라인학습/코딩/자기계발 |
| 재성(財星) | 재물/토지/안정 | 디지털자산/투자/N잡/부업/스타트업 |
| 관성(官星) | 직장/명예/규율 | 대기업/공무원/프리랜서플랫폼 |
| 비겁(比劫) | 형제/경쟁/협력 | 네트워킹/커뮤니티/협업/팀워크 |
| 화개살 | 종교/예술/고독 | IT개발/연구직/1인창업/재택근무 |
| 문창귀인 | 학문성취/문서운 | 블로그/작가/교육콘텐츠/자격증 |

## 분석 원칙
- **원국 우선**: 대운/세운보다 원국의 구조를 먼저 파악
- **육친 중심**: 십성을 통해 인간관계와 운세 해석
- **상호작용**: 글자 간 합충형파해를 놓치지 않음
- **균형 해석**: 좋은 점과 주의할 점을 함께 제시

## 응답 형식
반드시 JSON 형식으로만 응답하세요. 추가 설명 없이 순수 JSON만 출력하세요.
''';

  @override
  String buildUserPrompt([Map<String, dynamic>? input]) {
    final data = SajuInputData.fromJson(input!);

    return '''
## 분석 대상
- 이름: ${data.profileName}
- 생년월일: ${_formatBirthDate(data.birthDate)}
- 성별: ${data.gender == 'male' ? '남성' : '여성'}
- 태어난 시간: ${data.birthTime ?? '미상'}

## 사주 팔자
${data.sajuString}

## 오행 분포
${data.ohengString}

## 일간 (나를 대표하는 오행)
${data.dayMaster}

${_buildYongsinSection(data.yongsin)}
${_buildDayStrengthSection(data.dayStrength)}
${_buildGyeokgukSection(data.gyeokguk)}
${_buildSipsinSection(data.sipsinInfo)}
${_buildJijangganSection(data.jijangganInfo)}
${_buildSinsalSection(data.sinsal)}
${_buildGilseongSection(data.gilseong)}
${_buildUnsungSection(data.twelveUnsung)}
${_buildTwelveSinsalSection(data.twelveSinsal)}
${_buildDaeunSection(data.daeun)}
${_buildHapchungSection(data.hapchung)}

---

위 사주 정보를 바탕으로 종합적인 사주 분석을 JSON 형식으로 제공해주세요.

반드시 아래 JSON 스키마를 정확히 따라주세요. 모든 필드를 빠짐없이 채워주세요:

```json
{

  "mySajuIntro": {
    "title": "나의 사주, 나는 누구인가요?",
    "ilju": "일주(日柱) 설명: 일간+일지 조합의 의미 (예: '갑자일주는 큰 나무가 깊은 물을 만난 형상으로...')",
    "reading": "일주를 기반으로 '나'라는 사람에 대한 핵심 설명 6-8문장. 타고난 기질, 성향, 인생의 방향성을 일주 중심으로 설명. 사주 초보자도 쉽게 이해할 수 있게 작성."
  },

  "summary": "이 사주의 핵심 특성을 10~20문장으로 사주에대해 모르는사람들이 이해할수있게 객관적으로 요약",

  "my_saju_characters": {
    "description": "사주팔자 8글자 각각의 의미를 초보자도 이해할 수 있게 설명",
    "year_gan": {
      "character": "연간 한자 (예: 甲)",
      "reading": "연간 읽는 법 (예: 갑)",
      "oheng": "오행 (목/화/토/금/수)",
      "yin_yang": "음양 (양/음)",
      "meaning": "이 글자가 뜻하는 의미를 쉽게 설명 (예: 갑목은 큰 나무처럼 꿋꿋하고 곧은 성질)"
    },
    "year_ji": {
      "character": "연지 한자 (예: 子)",
      "reading": "연지 읽는 법 (예: 자)",
      "animal": "띠 동물 (예: 쥐)",
      "oheng": "오행",
      "yin_yang": "음양",
      "meaning": "이 글자가 뜻하는 의미를 쉽게 설명"
    },
    "month_gan": {
      "character": "월간 한자",
      "reading": "월간 읽는 법",
      "oheng": "오행",
      "yin_yang": "음양",
      "meaning": "월간의 의미 쉽게 설명"
    },
    "month_ji": {
      "character": "월지 한자",
      "reading": "월지 읽는 법",
      "season": "계절 (봄/여름/환절기/가을/겨울)",
      "oheng": "오행",
      "yin_yang": "음양",
      "meaning": "월지의 의미 쉽게 설명"
    },
    "day_gan": {
      "character": "일간 한자 (나를 대표하는 글자!)",
      "reading": "일간 읽는 법",
      "oheng": "오행",
      "yin_yang": "음양",
      "meaning": "일간은 '나 자신'을 뜻합니다. 이 글자의 특성이 곧 내 성격과 기질입니다. 쉽게 설명"
    },
    "day_ji": {
      "character": "일지 한자 (배우자궁)",
      "reading": "일지 읽는 법",
      "animal": "띠 동물",
      "oheng": "오행",
      "yin_yang": "음양",
      "meaning": "일지는 배우자궁으로 결혼운과 관련됩니다. 쉽게 설명"
    },
    "hour_gan": {
      "character": "시간 한자",
      "reading": "시간 읽는 법",
      "oheng": "오행",
      "yin_yang": "음양",
      "meaning": "시간의 의미 쉽게 설명"
    },
    "hour_ji": {
      "character": "시지 한자 (자녀궁)",
      "reading": "시지 읽는 법",
      "animal": "띠 동물",
      "oheng": "오행",
      "yin_yang": "음양",
      "meaning": "시지는 자녀궁으로 자녀운과 말년운에 관련됩니다. 쉽게 설명"
    },
    "overall_reading": "8글자 조합이 만들어내는 전체적인 기운과 특성을 초보자도 이해할 수 있게 3-4문장으로 설명"
  },

  "wonGuk_analysis": {
    "day_master": "일간 분석 (예: 甲木일간으로 성장과 진취성을 상징)",
    "oheng_balance": "오행 균형 분석 (과다/부족 오행과 그 영향)",
    "singang_singak": "신강/신약 판정 근거와 의미",
    "gyeokguk": "격국 분석 (해당되는 경우)",
    "reading": "원국 종합 해석 8문장. 일간 본성, 오행 균형, 신강/신약이 삶에 미치는 핵심 영향"
  },

  "sipsung_analysis": {
    "dominant_sipsung": ["사주에서 강한 십성 1-3개"],
    "weak_sipsung": ["사주에서 약한 십성 1-2개"],
    "key_interactions": "십성 간 주요 상호작용 분석",
    "life_implications": "십성 구조가 인생에 미치는 영향",
    "reading": "십성 종합 해석 8문장. 비겁/식상/재성/관성/인성 분포가 성격, 재물, 직업에 미치는 핵심 영향"
  },

  "hapchung_analysis": {
    "major_haps": ["주요 합의 의미와 영향"],
    "major_chungs": ["주요 충의 의미와 영향"],
    "other_interactions": "형/파/해/원진 영향 (있는 경우)",
    "overall_impact": "합충 구조가 인생에 미치는 종합 영향",
    "reading": "합충 종합 해석 8문장. 천간합, 지지합, 충, 형, 파, 해가 변화와 기회에 미치는 핵심 영향"
  },

  "personality": {
    "core_traits": ["핵심 성격 특성 4-6개"],
    "strengths": ["장점 4-6개"],
    "weaknesses": ["약점/주의점 3-4개"],
    "social_style": "대인관계 스타일",
    "reading": "성격 종합 해석 10문장. 일간과 십성 구조 기반으로 성격, 행동 패턴, 대인관계 핵심"
  },

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

  "health": {
    "vulnerable_organs": ["건강 취약 장기/부위 2-4개"],
    "potential_issues": ["주의해야 할 건강 문제 2-3개"],
    "mental_health": "정신/심리 건강 경향",
    "lifestyle_advice": ["건강 관리 생활 습관 조언 3-4개"],
    "caution_periods": "건강 주의 시기 (있는 경우)",
    "reading": "건강운 종합 해석 6문장. 오행 과다/부족 기반 취약 장기와 관리법"
  },

  "sinsal_gilseong": {
    "major_gilseong": ["주요 길성과 그 의미"],
    "major_sinsal": ["주요 신살과 그 의미"],
    "practical_implications": "신살/길성이 실생활에 미치는 영향",
    "reading": "신살/길성 종합 해석 6문장. 주요 신살이 인생에 가져오는 복과 시련"
  },

  "life_cycles": {
    "youth": "청년기(20-35세) 전망 5문장. 이 시기 핵심 기회와 집중 포인트",
    "middle_age": "중년기(35-55세) 전망 5문장. 가정/직장/재물 핵심 흐름",
    "later_years": "후년기(55세 이후) 전망 5문장. 건강/가족/여유 핵심 흐름",
    "key_years": ["인생 중요 전환점 3-4개 (예: 28세, 42세, 51세)"]
  },

  "lucky_elements": {
    "colors": ["행운의 색 2-3개"],
    "directions": ["좋은 방향 1-2개"],
    "numbers": [1, 6],
    "seasons": "유리한 계절",
    "partner_elements": ["궁합이 좋은 띠 2-3개"]
  },


  "peak_years": {
    "period": "최전성기 구간 (예: 38-48세)",
    "age_range": [38, 48],
    "why": "왜 이 시기가 최전성기인지 8문장. 용신운과 기회 설명",
    "what_to_prepare": "최전성기 준비사항 3문장",
    "what_to_do": "최전성기에 해야 할 것 3문장",
    "cautions": "최전성기 주의점 2문장"
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

  String _formatBirthDate(DateTime date) {
    return '${date.year}년 ${date.month}월 ${date.day}일';
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
    if (yongsin['gisin'] != null) {
      buffer.writeln('- 기신(忌神): ${yongsin['gisin']}');
    }
    if (yongsin['gusin'] != null) {
      buffer.writeln('- 구신(仇神): ${yongsin['gusin']}');
    }

    return buffer.toString();
  }

  String _buildDayStrengthSection(Map<String, dynamic>? dayStrength) {
    if (dayStrength == null || dayStrength.isEmpty) return '';

    final buffer = StringBuffer('\n## 신강/신약 (8단계 판정) - ⚠️ 중요 ⚠️\n');

    final score = dayStrength['score'] as int? ?? 50;
    final level = dayStrength['level'] as String? ?? _determineLevelFromScore(score);
    final isSingang = score >= 50;

    buffer.writeln('');
    buffer.writeln('┌─────────────────────────────────────────────────┐');
    buffer.writeln('│ [중요] 이 값을 그대로 사용하세요 (재계산 금지)     │');
    buffer.writeln('├─────────────────────────────────────────────────┤');
    buffer.writeln('│ 점수: $score점                                   │');
    buffer.writeln('│ 등급: $level                                     │');
    buffer.writeln('│ is_singang: $isSingang                           │');
    buffer.writeln('└─────────────────────────────────────────────────┘');
    buffer.writeln('');
    buffer.writeln('**8단계 기준표** (점수 → 등급 매핑):');
    buffer.writeln('| 점수 범위 | 등급 | is_singang |');
    buffer.writeln('|-----------|------|------------|');
    buffer.writeln('| 88-100 | 극왕 | true |');
    buffer.writeln('| 75-87 | 태강 | true |');
    buffer.writeln('| 63-74 | 신강 | true |');
    buffer.writeln('| 50-62 | 중화신강 | true |');
    buffer.writeln('| 38-49 | 중화신약 | false |');
    buffer.writeln('| 26-37 | 신약 | false |');
    buffer.writeln('| 13-25 | 태약 | false |');
    buffer.writeln('| 0-12 | 극약 | false |');
    buffer.writeln('');
    buffer.writeln('> **경고**: 점수 $score은 "$level"입니다. 응답에서 이 등급을 그대로 사용하세요.');

    return buffer.toString();
  }

  /// 점수로부터 8단계 등급 결정 (Flutter day_strength_service.dart와 동일)
  String _determineLevelFromScore(int score) {
    if (score >= 88) return '극왕';
    if (score >= 75) return '태강';
    if (score >= 63) return '신강';
    if (score >= 50) return '중화신강';
    if (score >= 38) return '중화신약';
    if (score >= 26) return '신약';
    if (score >= 13) return '태약';
    return '극약';
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

  /// 격국 섹션 빌드
  String _buildGyeokgukSection(Map<String, dynamic>? gyeokguk) {
    if (gyeokguk == null || gyeokguk.isEmpty) return '';

    final buffer = StringBuffer('\n## 격국\n');

    final name = gyeokguk['name'] ?? gyeokguk['type'] ?? '';
    final description = gyeokguk['description'] ?? '';

    if (name.toString().isNotEmpty) {
      buffer.writeln('- 격국: $name');
    }
    if (description.toString().isNotEmpty) {
      buffer.writeln('- 설명: $description');
    }

    return buffer.toString();
  }

  /// 십신 섹션 빌드
  String _buildSipsinSection(Map<String, dynamic>? sipsin) {
    if (sipsin == null || sipsin.isEmpty) return '';

    final buffer = StringBuffer('\n## 십신 (十神)\n');

    final pillars = ['year', 'month', 'day', 'hour'];
    final pillarNames = {'year': '년주', 'month': '월주', 'day': '일주', 'hour': '시주'};

    for (final pillar in pillars) {
      final data = sipsin[pillar];
      if (data != null && data is Map) {
        final gan = data['gan'] ?? '';
        final ji = data['ji'] ?? '';
        if (gan.toString().isNotEmpty || ji.toString().isNotEmpty) {
          buffer.writeln('- ${pillarNames[pillar]}: 천간=$gan, 지지=$ji');
        }
      }
    }

    return buffer.toString();
  }

  /// 지장간 섹션 빌드
  String _buildJijangganSection(Map<String, dynamic>? jijanggan) {
    if (jijanggan == null || jijanggan.isEmpty) return '';

    final buffer = StringBuffer('\n## 지장간 (地藏干)\n');

    final pillars = ['year', 'month', 'day', 'hour'];
    final pillarNames = {'year': '년지', 'month': '월지', 'day': '일지', 'hour': '시지'};

    for (final pillar in pillars) {
      final data = jijanggan[pillar];
      if (data != null) {
        if (data is List) {
          buffer.writeln('- ${pillarNames[pillar]}: ${data.join(', ')}');
        } else {
          buffer.writeln('- ${pillarNames[pillar]}: $data');
        }
      }
    }

    return buffer.toString();
  }

  /// 12신살 섹션 빌드
  String _buildTwelveSinsalSection(List<dynamic>? twelveSinsal) {
    if (twelveSinsal == null || twelveSinsal.isEmpty) return '';

    final buffer = StringBuffer('\n## 12신살 (十二神殺)\n');

    for (final item in twelveSinsal) {
      if (item is Map) {
        final pillar = item['pillar'] ?? '';
        final sinsal = item['sinsal'] ?? '';
        final fortuneType = item['fortuneType'] ?? '';
        if (sinsal.toString().isNotEmpty) {
          buffer.writeln('- $pillar: $sinsal ($fortuneType)');
        }
      }
    }

    return buffer.toString();
  }

  /// 대운 섹션 빌드
  ///
  /// DB 형식 (camelCase)과 legacy 형식 (snake_case) 모두 지원
  /// - DB: { startAge, isForward, list: [{ order, pillar, startAge, endAge }] }
  /// - Legacy: { start_age, current: { gan, ji }, list: [...] }
  String _buildDaeunSection(Map<String, dynamic>? daeun) {
    if (daeun == null || daeun.isEmpty) return '';

    final buffer = StringBuffer('\n## 대운 (大運)\n');

    // 대운 시작 나이 (snake_case 또는 camelCase)
    final startAge = daeun['start_age'] ?? daeun['startAge'];
    if (startAge != null) {
      buffer.writeln('- 대운 시작: $startAge세');
    }

    // 순행/역행
    final isForward = daeun['isForward'] ?? daeun['is_forward'];
    if (isForward != null) {
      buffer.writeln('- 운행: ${isForward == true ? '순행' : '역행'}');
    }

    // 대운 목록
    final list = daeun['list'];
    if (list != null && list is List && list.isNotEmpty) {
      buffer.writeln('');
      buffer.writeln('### 대운 목록 (10년 단위)');
      buffer.writeln('| 순서 | 대운 | 시작나이 | 종료나이 |');
      buffer.writeln('|------|------|----------|----------|');

      for (final d in list) {
        if (d is Map) {
          final order = d['order'] ?? '';
          // pillar: "임(壬)신(申)" 형식 또는 gan/ji 분리 형식
          String pillarStr = '';
          if (d['pillar'] != null) {
            pillarStr = _extractDaeunPillar(d['pillar'].toString());
          } else if (d['gan'] != null && d['ji'] != null) {
            pillarStr = '${d['gan']}${d['ji']}';
          }
          final sAge = d['startAge'] ?? d['start_age'] ?? '';
          final eAge = d['endAge'] ?? d['end_age'] ?? '';
          buffer.writeln('| $order | $pillarStr | ${sAge}세 | ${eAge}세 |');
        }
      }
      buffer.writeln('');

      // 대운 흐름 요약
      final flowList = list.take(10).map((d) {
        if (d is Map) {
          if (d['pillar'] != null) {
            return _extractDaeunPillar(d['pillar'].toString());
          } else if (d['gan'] != null && d['ji'] != null) {
            return '${d['gan']}${d['ji']}';
          }
        }
        return '';
      }).where((s) => s.isNotEmpty);
      buffer.writeln('- 대운 흐름: ${flowList.join(' → ')}');
    }

    return buffer.toString();
  }

  /// 대운 간지 추출 (한자 포함 형식에서 한글만)
  /// "임(壬)신(申)" → "임신"
  String _extractDaeunPillar(String pillar) {
    final hangulOnly = pillar.replaceAll(RegExp(r'\([^)]*\)'), '');
    return hangulOnly;
  }

  /// 합충형파해 섹션 빌드
  ///
  /// 천간/지지 간의 합충형파해 관계를 프롬프트에 포함합니다.
  /// - 합: 천간합, 지지육합, 삼합, 방합 (길한 관계)
  /// - 충: 천간충, 지지충 (충돌 관계)
  /// - 형: 지지형 (갈등 관계)
  /// - 파: 지지파 (손상 관계)
  /// - 해: 지지해 (방해 관계)
  /// - 원진: 미움 관계
  String _buildHapchungSection(Map<String, dynamic>? hapchung) {
    if (hapchung == null) return '';

    final hasRelations = hapchung['has_relations'] as bool? ?? false;
    if (!hasRelations) return '';

    final buffer = StringBuffer('\n## 합충형파해 (合沖刑破害)\n');

    // 집계 정보
    final totalHaps = hapchung['total_haps'] as int? ?? 0;
    final totalChungs = hapchung['total_chungs'] as int? ?? 0;
    final totalNegatives = hapchung['total_negatives'] as int? ?? 0;

    buffer.writeln('> 합 ${totalHaps}개, 충 ${totalChungs}개, 형/파/해/원진 ${totalNegatives}개');
    buffer.writeln('');

    // 천간합 (합화 시 더 강력)
    final cheonganHaps = hapchung['cheongan_haps'] as List? ?? [];
    if (cheonganHaps.isNotEmpty) {
      buffer.writeln('### 천간합 (天干合) [중간 강도]');
      for (final h in cheonganHaps) {
        final desc = h['description'] ?? '${h['gan1']}${h['gan2']}합';
        buffer.writeln('- ${h['pillar1']}주-${h['pillar2']}주: $desc');
      }
      buffer.writeln('');
    }

    // 천간충
    final cheonganChungs = hapchung['cheongan_chungs'] as List? ?? [];
    if (cheonganChungs.isNotEmpty) {
      buffer.writeln('### 천간충 (天干沖)');
      for (final c in cheonganChungs) {
        buffer.writeln('- ${c['pillar1']}주-${c['pillar2']}주: ${c['gan1']}${c['gan2']}충');
      }
      buffer.writeln('');
    }

    // 지지육합 (가장 부드러운 결합)
    final jijiYukhaps = hapchung['jiji_yukhaps'] as List? ?? [];
    if (jijiYukhaps.isNotEmpty) {
      buffer.writeln('### 지지육합 (地支六合) [부드러운 결합]');
      for (final y in jijiYukhaps) {
        final desc = y['description'] ?? '${y['ji1']}${y['ji2']}합';
        buffer.writeln('- ${y['pillar1']}주-${y['pillar2']}주: $desc');
      }
      buffer.writeln('');
    }

    // 삼합 (완성 / 반합)
    final jijiSamhaps = hapchung['jiji_samhaps'] as List? ?? [];
    if (jijiSamhaps.isNotEmpty) {
      buffer.writeln('### 삼합 (三合) [강하고 유연함]');
      for (final s in jijiSamhaps) {
        final jijis = (s['jijis'] as List?)?.join('') ?? '';
        final pillars = (s['pillars'] as List?)?.join(',') ?? '';
        final isFull = s['is_full'] as bool? ?? true;
        final label = isFull ? '삼합(완성)' : '반합(불완전)';
        buffer.writeln('- ${pillars}주: $jijis $label (${s['result_oheng']}국)');
      }
      buffer.writeln('');
    }

    // 방합 (가장 강력!)
    final jijiBanghaps = hapchung['jiji_banghaps'] as List? ?? [];
    if (jijiBanghaps.isNotEmpty) {
      buffer.writeln('### 방합 (方合) [가장 강력! 고정적]');
      for (final b in jijiBanghaps) {
        final jijis = (b['jijis'] as List?)?.join('') ?? '';
        final pillars = (b['pillars'] as List?)?.join(',') ?? '';
        buffer.writeln('- ${pillars}주: $jijis 방합(최강) (${b['season']}, ${b['direction']}방)');
      }
      buffer.writeln('');
    }

    // 지지충 (강도별: 왕지충 > 생지충 > 고지충)
    final jijiChungs = hapchung['jiji_chungs'] as List? ?? [];
    if (jijiChungs.isNotEmpty) {
      buffer.writeln('### 지지충 (地支沖) [왕지충>생지충>고지충]');
      for (final c in jijiChungs) {
        final ji1 = c['ji1'] as String? ?? '';
        final ji2 = c['ji2'] as String? ?? '';
        final chungStrength = _getChungStrength(ji1, ji2);
        buffer.writeln('- ${c['pillar1']}주-${c['pillar2']}주: $ji1$ji2충 $chungStrength');
      }
      buffer.writeln('');
    }

    // 지지형 (삼형 > 상형 > 자묘형 > 자형)
    final jijiHyungs = hapchung['jiji_hyungs'] as List? ?? [];
    if (jijiHyungs.isNotEmpty) {
      buffer.writeln('### 지지형 (地支刑) [삼형>상형>자묘형>자형]');
      for (final h in jijiHyungs) {
        final desc = h['description'] ?? '${h['ji1']}${h['ji2']}형';
        final hyungType = h['hyung_type'] as String? ?? '';
        final hyungStrength = _getHyungStrength(hyungType);
        buffer.writeln('- ${h['pillar1']}주-${h['pillar2']}주: $desc $hyungStrength');
      }
      buffer.writeln('');
    }

    // 지지파
    final jijiPas = hapchung['jiji_pas'] as List? ?? [];
    if (jijiPas.isNotEmpty) {
      buffer.writeln('### 지지파 (地支破)');
      for (final p in jijiPas) {
        buffer.writeln('- ${p['pillar1']}주-${p['pillar2']}주: ${p['ji1']}${p['ji2']}파');
      }
      buffer.writeln('');
    }

    // 지지해
    final jijiHaes = hapchung['jiji_haes'] as List? ?? [];
    if (jijiHaes.isNotEmpty) {
      buffer.writeln('### 지지해 (地支害)');
      for (final h in jijiHaes) {
        buffer.writeln('- ${h['pillar1']}주-${h['pillar2']}주: ${h['ji1']}${h['ji2']}해');
      }
      buffer.writeln('');
    }

    // 원진
    final wonjins = hapchung['wonjins'] as List? ?? [];
    if (wonjins.isNotEmpty) {
      buffer.writeln('### 원진 (怨嗔)');
      for (final w in wonjins) {
        buffer.writeln('- ${w['pillar1']}주-${w['pillar2']}주: ${w['ji1']}${w['ji2']}원진');
      }
      buffer.writeln('');
    }

    return buffer.toString();
  }

  /// 충(沖) 강도 판별
  /// 왕지충(묘유,자오) > 생지충(인신,사해) > 고지충(진술,축미)
  String _getChungStrength(String ji1, String ji2) {
    final pair = {ji1, ji2};

    // 왕지충 (가장 강함)
    if (pair.containsAll({'묘', '유'}) || pair.containsAll({'卯', '酉'})) {
      return '(왕지충 원수충!)';
    }
    if (pair.containsAll({'자', '오'}) || pair.containsAll({'子', '午'})) {
      return '(왕지충)';
    }

    // 생지충 (강함)
    if (pair.containsAll({'인', '신'}) || pair.containsAll({'寅', '申'})) {
      return '(생지충 역마충돌!)';
    }
    if (pair.containsAll({'사', '해'}) || pair.containsAll({'巳', '亥'})) {
      return '(생지충)';
    }

    // 고지충 (중간)
    if (pair.containsAll({'진', '술'}) || pair.containsAll({'辰', '戌'})) {
      return '(고지충 오래지속)';
    }
    if (pair.containsAll({'축', '미'}) || pair.containsAll({'丑', '未'})) {
      return '(고지충 오래지속)';
    }

    return '';
  }

  /// 형(刑) 강도 판별
  /// 삼형 > 상형 > 자묘형 > 자형
  String _getHyungStrength(String hyungType) {
    switch (hyungType) {
      case '인사신삼형':
      case '寅巳申삼형':
        return '(삼형 관재/배신!)';
      case '축술미삼형':
      case '丑戌未삼형':
        return '(삼형신의깨짐!)';
      case '인사형':
      case '사신형':
      case '인신형':
      case '축술형':
      case '술미형':
      case '축미형':
        return '(상형)';
      case '자묘형':
      case '子卯형':
        return '(무례지형)';
      case '자형':
      case '진진형':
      case '오오형':
      case '유유형':
      case '해해형':
        return '(자형)';
      default:
        return '';
    }
  }
}