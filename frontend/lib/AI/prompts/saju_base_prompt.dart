/// # 기본 사주 분석 프롬프트 (GPT-5.2용)
///
/// ## 개요
/// 프로필 저장 시 1회 실행되는 평생 사주 분석 프롬프트입니다.
/// GPT-5.2 모델을 사용하여 가장 정확한 분석을 제공합니다.
///
/// ## 파일 위치
/// `frontend/lib/AI/prompts/saju_base_prompt.dart`
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

import '../core/ai_constants.dart';
import 'prompt_template.dart';

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
원국(原局)을 철저히 분석하여 정확하고 깊이 있는 사주 해석을 제공합니다.

## 분석 방법론 (반드시 순서대로)

### 1단계: 원국 구조 분석

### 2단계: 십성(十星) 분석


### 3단계: 신살(神殺) & 길성(吉星) 해석

### 4단계: 합충형파해(合沖刑破害) 분석

> 아래 데이터에 ★ 강도가 표시되어 있음. 강도가 높을수록 영향력 큼!

**합(合) 결속력 순서**
- 방합(★5 최강/고정적) > 삼합(★4 유연) > 반합(★3 불완전) > 육합(★2 부드러움)
- 방합 있으면 해당 오행 매우 강력! 삼합보다 방합 먼저 확인

**충(沖) 파괴력 순서**
- 왕지충(묘유/자오 ★5 원수충) > 생지충(인신/사해 ★4 역마) > 고지충(진술/축미 ★3)
- 충 영향력: 일지 > 월지 > 연지 > 시지

**형(刑) 흉의 강도 순서**
- 삼형(인사신/축술미 ★5 관재/배신) > 상형(2자 ★3) > 자묘형(★2 무례) > 자형(★1)
- 3자 모두 있으면 흉 최강! 2자만 있으면 감소

### 5단계: 12운성 분석


### 6단계: 종합 해 석 (아래 영역별로 상세 분석)
1. **재물운**: 정재/편재 위치, 강약, 충합 관계
2. **연애운**: 도화살, 홍염살, 재성/관성 상태
3. **결혼운**: 배우자궁(일지) 상태, 충합 여부
4. **사업운**: 식상생재 구조, 편재 활용도
5. **직장운**: 관성 상태, 인성의 지원 여부
6. **건강운**: 오행 편중, 충형 위치

### 7단계: 전통 vs AI시대 해석 비교 ⭐필수⭐
> **매우 중요**: 각 분석 항목에서 반드시 "고전에서는 ~했지만, 현대에서는 ~로 해석됩니다" 형식으로 설명하세요!

**[십성별 고전 vs 현대 해석 필수 포함]**

| 요소 | 고전(전통) 해석 | 현대(AI시대) 해석 | 설명 예시 |
|------|---------------|-----------------|----------|
| 식상(食傷) | 자녀운/표현력/재능 | 콘텐츠창작/SNS/유튜브/블로그/AI프롬프트작성 | "고전에서 식상은 자녀를 잘 기르고 표현력이 뛰어나다고 해석했지만, 현대에서는 유튜브/블로그 같은 1인 미디어나 AI 프롬프트 작성에 탁월한 재능으로 발현됩니다" |
| 역마살 | 먼여행/이사/타향살이 | 디지털노마드/해외근무/원격근무/글로벌비즈니스 | "고전에서 역마살은 타향에서 고생한다고 봤지만, 현대에서는 디지털노마드나 해외 원격근무로 오히려 성공 기회가 됩니다" |
| 도화살 | 색정/바람끼/주색잡기 | 인플루언서/대중인기/연예/마케팅/브랜딩 | "고전에서 도화살은 바람끼를 경계했지만, 현대에서는 대중에게 사랑받는 매력으로 인플루언서나 연예계에 유리합니다" |
| 인성(印星) | 학문/스승/어머니운 | AI활용능력/온라인학습/코딩/자격증/평생교육 | "고전에서 인성은 과거시험 합격을 뜻했지만, 현대에서는 AI 도구 활용 능력이나 온라인 자격증 취득에 유리합니다" |
| 재성(財星) | 재물/토지/처첩(여성)/안정 | 디지털자산/투자/N잡/스타트업/크립토 | "고전에서 재성은 논밭과 집을 뜻했지만, 현대에서는 디지털자산, 주식, 암호화폐 등 다양한 투자에 적용됩니다" |
| 관성(官星) | 벼슬/직장/남편운(여성) | 대기업/공무원/프리랜서플랫폼/CEO | "고전에서 관성은 과거급제와 관직을 뜻했지만, 현대에서는 대기업 임원이나 플랫폼 비즈니스 CEO를 의미합니다" |
| 비겁(比劫) | 형제/경쟁자/재물손실 | 네트워킹/커뮤니티/협업/팀빌딩/공동창업 | "고전에서 비겁은 형제와 재산 다툼을 경계했지만, 현대에서는 네트워킹과 협업 능력으로 스타트업 공동창업에 유리합니다" |
| 화개살 | 종교/예술/고독/출가운 | IT개발/연구직/1인창업/재택근무/딥워크 | "고전에서 화개살은 출가하거나 외롭다고 봤지만, 현대에서는 집중력이 필요한 IT개발이나 연구직에 적합합니다" |
| 문창귀인 | 학문성취/과거급제 | 블로그/작가/교육콘텐츠/온라인강의/AI연구 | "고전에서 문창귀인은 과거시험 합격을 뜻했지만, 현대에서는 콘텐츠 크리에이터나 AI 연구 분야에서 빛납니다" |
| 천을귀인 | 귀인의 도움/관운 | 멘토링/엔젤투자/헤드헌팅/스카우트 | "고전에서 천을귀인은 귀인을 만난다고 했는데, 현대에서는 엔젤투자자나 헤드헌터의 연락으로 나타납니다" |

**⭐ 반드시 지켜야 할 원칙 ⭐**
1. 모든 분석 항목에서 "고전에서는 ~라고 해석했지만, 현대에서는 ~로 적용됩니다" 패턴 사용
2. 단순 나열 금지! 왜 그렇게 해석이 달라졌는지 시대적 배경 설명
3. 구체적인 현대 직업/기회 예시 반드시 포함

## 분석 원칙
- **원국 우선**: 대운/세운보다 원국의 구조를 먼저 파악
- **육친 중심**: 십성을 통해 인간관계와 운세 해석
- **상호작용**: 글자 간 합충형파해를 놓치지 않음
- **균형 해석**: 좋은 점과 주의할 점을 함께 제시

## 응답 형식
반드시 JSON 형식으로만 응답하세요. 추가 설명 없이 순수 JSON만 출력하세요.

## 글쓰기 스타일 (매우 중요!)
**평생운세는 사용자가 책처럼 천천히 읽으며 공감할 수 있어야 합니다.**

1. **길이**: 모든 reading/description 필드는 최소 **15-20문장 이상** 작성
2. **어조**: 따뜻하고 공감하는 어조로, 마치 오랜 친구에게 조언하듯이
3. **스토리텔링**: 단순 나열이 아닌, "왜 그런지" 맥락을 설명하며 이야기 형식으로
4. **구체성**: 추상적 표현 대신 구체적인 상황과 예시 포함
5. **공감 표현**: "~하실 거예요", "~때문이에요", "걱정되시겠지만" 같은 공감 어투

**나쁜 예**: "재물운이 좋습니다. 투자에 유리합니다."
**좋은 예**: "당신의 재물운은 특별한 흐름을 가지고 있어요. 정재가 월지에 자리잡고 있어서 안정적인 수입을 선호하시는 편이에요. 하지만 편재도 시주에 있어서 가끔은 '한번 해볼까?' 하는 모험 정신도 갖고 계시죠. 이런 균형감이 오히려 장점이에요. 너무 안전하게만 가면 기회를 놓칠 수 있고, 너무 공격적이면 리스크가 커지잖아요. 당신은 그 중간을 잘 잡을 수 있는 분이에요. 특히 35-45세 사이에 재물운이 활짝 열리는데, 이때 준비해둔 것들이 빛을 발할 거예요. 그러니 지금부터 조금씩 씨앗을 뿌려두세요."
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
  "saju_origin": {
    "saju": {
      "year": {"gan": "년간", "ji": "년지"},
      "month": {"gan": "월간", "ji": "월지"},
      "day": {"gan": "일간", "ji": "일지"},
      "hour": {"gan": "시간", "ji": "시지"}
    },
    "oheng": ${data.ohengJson},
    "day_master": "일간 오행",
    "yongsin": {
      "yongsin": "용신",
      "huisin": "희신",
      "gisin": "기신",
      "gusin": "구신",
      "hansin": "한신",
      "method": "억부법/조후법 등",
      "reason": "용신 선정 근거"
    },
    "singang_singak": {
      "is_singang": true,
      "score": 0,
      "level": "※필수※ 위 '신강/신약 (8단계 판정)' 섹션의 점수를 그대로 사용하여 8단계 기준에 맞는 등급 반환: 0-12=극약, 13-25=태약, 26-37=신약, 38-49=중화신약, 50-62=중화신강, 63-74=신강, 75-87=태강, 88-100=극왕"
    },
    "gyeokguk": {
      "name": "격국명",
      "is_special": false,
      "description": "격국 설명"
    },
    "sipsin": {
      "year_gan": "년간 십성",
      "year_ji": "년지 십성",
      "month_gan": "월간 십성",
      "month_ji": "월지 십성",
      "day_ji": "일지 십성",
      "hour_gan": "시간 십성",
      "hour_ji": "시지 십성"
    },
    "hapchung": {
      "summary": "합충형파해 요약",
      "total_haps": 0,
      "total_chungs": 0,
      "total_negatives": 0,
      "cheongan_haps": ["천간합 목록"],
      "jiji_yukhaps": ["지지육합 목록"],
      "jiji_samhaps": ["삼합/반합 목록"],
      "jiji_chungs": ["지지충 목록"],
      "jiji_hyungs": ["지지형 목록"],
      "jiji_pas": ["지지파 목록"],
      "jiji_haes": ["지지해 목록"],
      "wonjins": ["원진 목록"]
    },
    "sinsal": [
      {"name": "신살명", "pillar": "위치", "type": "길/흉/혼합", "meaning": "의미"}
    ],
    "gilseong": [
      {"name": "길성명", "pillar": "위치", "meaning": "의미"}
    ],
    "twelve_unsung": [
      {"pillar": "년주", "unsung": "운성명", "type": "길/평/흉"}
    ],
    "twelve_sinsal": [
      {"pillar": "년지", "sinsal": "12신살명", "type": "길/흉/혼합"}
    ],
    "daeun": {
      "start_age": 0,
      "is_forward": true,
      "current": {"gan": "간", "ji": "지", "start_age": 0, "end_age": 0},
      "list": [{"order": 1, "pillar": "간지", "start_age": 0, "end_age": 0}]
    }
  },

  "mySajuIntro": {
    "title": "나의 사주, 나는 누구인가요?",
    "reading": "{일간}{일지} 일주로 태어나신 {이름}님은 {일간 오행 자연물 비유} 같은 분이에요. {일간의 성격 특성 2-3문장}. 연주({연간연지})는 조상궁으로 {연주의 의미와 영향}. 월주({월간월지})는 부모궁/사회궁으로 {월주의 의미와 영향}. 일주({일간일지})는 나 자신과 배우자궁으로 {일주의 의미와 영향}. 시주({시간시지})는 자녀궁/말년궁으로 {시주의 의미와 영향}. 원국의 오행 균형을 보면 {오행 분석}. 용신이 {용신}이시라 {용신이 들어오면 좋아지는 점}. (7-8문장으로 사주 원국만 설명, 특정 연도 언급 금지)"
  },

  "summary": "이 사주의 핵심 특성을 최소 15문장으로 풍성하게 요약. 단순 나열이 아닌 스토리텔링 형식으로, 이 사람이 어떤 사람인지 공감하며 읽을 수 있게 작성. 마치 오래된 친구에게 '너 이런 사람이야'라고 설명하듯 따뜻하게",

  "wonGuk_analysis": {
    "day_master": "일간 분석 (예: 甲木일간으로 성장과 진취성을 상징)",
    "oheng_balance": "오행 균형 분석 (과다/부족 오행과 그 영향)",
    "singang_singak": "신강/신약 판정 근거와 의미",
    "gyeokguk": "격국 분석 (해당되는 경우)"
  },

  "sipsung_analysis": {
    "dominant_sipsung": ["사주에서 강한 십성 1-3개"],
    "weak_sipsung": ["사주에서 약한 십성 1-2개"],
    "key_interactions": "십성 간 주요 상호작용 분석",
    "life_implications": "십성 구조가 인생에 미치는 영향"
  },

  "hapchung_analysis": {
    "major_haps": ["주요 합의 의미와 영향"],
    "major_chungs": ["주요 충의 의미와 영향"],
    "other_interactions": "형/파/해/원진 영향 (있는 경우)",
    "overall_impact": "합충 구조가 인생에 미치는 종합 영향"
  },

  "personality": {
    "core_traits": ["핵심 성격 특성 5-7개"],
    "strengths": ["장점 5-7개"],
    "weaknesses": ["약점/주의점 4-5개"],
    "social_style": "대인관계 스타일 (5-7문장으로 구체적으로)",
    "description": "성격에 대한 상세 설명 최소 20문장! 단순 나열 금지! 이 사람이 어떤 상황에서 어떻게 행동하는지, 왜 그런 성향을 갖게 되었는지 사주 근거와 함께 스토리텔링 형식으로 풍부하게 설명. 공감 어조 필수!"
  },

  "wealth": {
    "overall_tendency": "전체적인 재물운 경향 (5-7문장)",
    "earning_style": "돈을 버는 방식/스타일 (5-7문장)",
    "spending_tendency": "소비 성향 (3-5문장)",
    "investment_aptitude": "투자 적성 (5-7문장)",
    "wealth_timing": "재물운이 좋은 시기/나이대 (구체적 나이 포함)",
    "cautions": ["재물 관련 주의사항 3-4개"],
    "reading": "재물운 종합 해석 최소 20문장! 정재/편재 위치와 강약을 바탕으로, 이 사람이 어떻게 돈을 벌고 모으는지, 어떤 투자가 맞는지, 언제 재물운이 열리는지 스토리텔링으로 설명. 공감 어조 필수!"
  },

  "love": {
    "attraction_style": "끌리는 이성 유형 (5-7문장)",
    "dating_pattern": "연애 패턴/스타일 (5-7문장)",
    "romantic_strengths": ["연애에서의 강점 3-4개"],
    "romantic_weaknesses": ["연애에서의 약점 3-4개"],
    "ideal_partner_traits": ["이상적인 파트너 특성 4-5개"],
    "love_timing": "연애운이 좋은 시기 (구체적 나이 포함)",
    "reading": "연애운 종합 해석 최소 20문장! 도화살, 홍염살, 재성/관성 상태를 바탕으로, 이 사람의 연애 스타일과 이상형, 연애 타이밍을 스토리텔링으로 설명. 공감 어조 필수!"
  },

  "marriage": {
    "spouse_palace_analysis": "배우자궁(일지) 분석 (7-10문장)",
    "marriage_timing": "결혼 적령기/좋은 시기 (구체적 나이 포함)",
    "spouse_characteristics": "배우자 특성 예상 (7-10문장)",
    "married_life_tendency": "결혼 생활 경향 (5-7문장)",
    "cautions": ["결혼 관련 주의사항 3-4개"],
    "reading": "결혼운 종합 해석 최소 20문장! 일지(배우자궁) 상태와 충합 여부를 바탕으로, 언제 어떤 배우자를 만날지, 결혼 생활은 어떨지 스토리텔링으로 설명. 공감 어조 필수!"
  },

  "career": {
    "suitable_fields": ["적합한 직업/분야 6-8개"],
    "unsuitable_fields": ["피해야 할 분야 3-4개"],
    "work_style": "업무 스타일 (5-7문장)",
    "leadership_potential": "리더십/관리자 적성 (5-7문장)",
    "career_timing": "직장운이 좋은 시기 (구체적 나이 포함)",
    "reading": "직업운 종합 해석 최소 20문장! 관성 상태와 인성 지원 여부를 바탕으로, 이 사람에게 맞는 일, 승진/이직 타이밍, 직장생활 스타일을 스토리텔링으로 설명. 공감 어조 필수!"
  },

  "business": {
    "entrepreneurship_aptitude": "사업 적성 분석 (5-7문장)",
    "suitable_business_types": ["적합한 사업 유형 5-6개"],
    "business_partner_traits": "좋은 사업 파트너 특성 (5-7문장)",
    "cautions": ["사업 시 주의사항 3-4개"],
    "success_factors": ["사업 성공 요인 3-4개"],
    "reading": "사업운 종합 해석 최소 20문장! 식상생재 구조와 편재 활용도를 바탕으로, 사업 적합성, 시작 타이밍, 파트너 선택을 스토리텔링으로 설명. 공감 어조 필수!"
  },

  "health": {
    "vulnerable_organs": ["건강 취약 장기/부위 3-5개"],
    "potential_issues": ["주의해야 할 건강 문제 3-4개"],
    "mental_health": "정신/심리 건강 경향 (5-7문장)",
    "lifestyle_advice": ["건강 관리 생활 습관 조언 4-5개"],
    "caution_periods": "건강 주의 시기 (구체적 나이 포함)",
    "reading": "건강운 종합 해석 최소 15문장! 오행 편중과 충형 위치를 바탕으로, 취약 부위와 관리법, 주의 시기를 스토리텔링으로 설명. 공감 어조 필수!"
  },

  "sinsal_gilseong": {
    "major_gilseong": ["주요 길성과 그 의미"],
    "major_sinsal": ["주요 신살과 그 의미"],
    "practical_implications": "신살/길성이 실생활에 미치는 영향"
  },

  "life_cycles": {
    "youth": "청년기(20-35세) 전망 최소 10문장. 이 시기에 어떤 기회와 시련이 있는지, 무엇에 집중해야 하는지 구체적으로",
    "middle_age": "중년기(35-55세) 전망 최소 10문장. 가정/직장/재물 관점에서 어떤 흐름이 있는지 구체적으로",
    "later_years": "후년기(55세 이후) 전망 최소 10문장. 건강/가족/여유 관점에서 어떤 삶이 펼쳐지는지",
    "key_years": ["인생 중요 전환점 예상 나이 4-5개 (예: 28세, 33세, 42세, 51세 등)"]
  },

  "peak_years": {
    "period": "최전성기 구간 (예: 38-48세)",
    "age_range": [38, 48],
    "why": "왜 이 시기가 최전성기인지 대운/세운/원국 관계를 바탕으로 최소 15문장으로 상세 설명. 이 시기에 용신운이 들어오는지, 어떤 기회가 열리는지 구체적으로",
    "what_to_prepare": "최전성기를 맞이하기 위해 지금부터 준비해야 할 것들 (5-7문장)",
    "what_to_do": "최전성기에 반드시 해야 할 것들 (5-7문장)",
    "cautions": "최전성기에도 주의해야 할 점 (3-5문장)"
  },

  "daeun_detail": {
    "intro": "대운 흐름 전체 소개 (10년 주기로 인생이 어떻게 변화하는지 개요, 5-7문장)",
    "cycles": [
      {
        "order": 1,
        "pillar": "대운 간지 (예: 甲子)",
        "age_range": "해당 나이 구간 (예: 8-17세)",
        "main_theme": "이 대운의 핵심 주제/테마",
        "fortune_level": "상/중상/중/중하/하 중 택1",
        "reading": "이 10년간의 운세 흐름을 최소 10문장으로 상세 설명. 용신과의 관계, 이 시기에 무엇을 해야 하는지, 주의사항 등",
        "opportunities": ["이 시기의 기회 2-3개"],
        "challenges": ["이 시기의 시련 2-3개"]
      }
    ],
    "best_daeun": {
      "period": "가장 좋은 대운 시기",
      "why": "왜 이 대운이 가장 좋은지 (7-10문장)"
    },
    "worst_daeun": {
      "period": "가장 주의해야 할 대운 시기",
      "why": "왜 이 대운을 조심해야 하는지 (7-10문장)"
    }
  },

  "children_fortune": {
    "has_children_luck": true,
    "ideal_timing": "자녀를 가지기 좋은 시기 (구체적 나이)",
    "number_tendency": "자녀 수 경향 (1명/2명/다자녀 등)",
    "child_gender_tendency": "자녀 성별 경향 (아들/딸/혼합)",
    "parent_child_relationship": "부모-자녀 관계 특성 (10문장 이상)",
    "child_raising_style": "양육 스타일과 조언 (7-10문장)",
    "cautions": ["자녀 관련 주의사항 3-4개"],
    "reading": "자녀운 종합 해석 최소 15문장! 시주(자녀궁) 상태와 식신/상관 위치를 바탕으로 자녀와의 인연, 자녀 교육법, 자녀가 부모에게 주는 영향 등을 스토리텔링으로 설명"
  },

  "family_relations": {
    "parents": {
      "father_relation": "아버지와의 관계 (5-7문장)",
      "mother_relation": "어머니와의 관계 (5-7문장)",
      "inheritance_luck": "부모로부터의 유산/도움 운 (3-5문장)"
    },
    "siblings": {
      "sibling_relation": "형제자매와의 관계 (5-7문장)",
      "rivalry_or_support": "경쟁/협력 경향"
    },
    "ancestors": {
      "ancestor_luck": "조상운/음덕 (5-7문장)",
      "family_karma": "가문의 업보나 특징 (3-5문장)"
    },
    "reading": "가족관계 종합 해석 최소 15문장! 년주(부모/조상궁), 월주(형제궁) 상태를 바탕으로 가족과의 인연, 가족에게서 받는 영향, 가족운 활용법 등을 설명"
  },

  "benefactor_fortune": {
    "has_benefactor": true,
    "benefactor_type": "귀인의 유형 (어른/동료/후배/이성 등)",
    "benefactor_timing": "귀인을 만나는 시기 (구체적 나이)",
    "how_to_meet": "귀인을 만나는 방법/상황 (5-7문장)",
    "benefactor_characteristics": "귀인의 특성 (띠/직업/성격 등)",
    "reading": "귀인운 종합 해석 최소 10문장! 천을귀인, 월덕귀인 등 길성 위치와 관성 상태를 바탕으로 어떤 귀인을 언제 만나는지, 어떻게 귀인의 도움을 받을 수 있는지 설명"
  },

  "timing_advice": {
    "job_change": {
      "good_years": ["이직/전직하기 좋은 나이 3-5개"],
      "bad_years": ["이직 피해야 할 나이 2-3개"],
      "advice": "이직/전직 관련 조언 (7-10문장)"
    },
    "business_start": {
      "good_years": ["사업 시작하기 좋은 나이 3-5개"],
      "bad_years": ["사업 피해야 할 나이 2-3개"],
      "suitable_partners": "사업 파트너로 좋은 띠/특성",
      "advice": "사업 시작 관련 조언 (7-10문장)"
    },
    "major_investment": {
      "good_years": ["큰 투자(부동산/주식 등) 좋은 나이 3-5개"],
      "bad_years": ["투자 피해야 할 나이 2-3개"],
      "advice": "투자 관련 조언 (5-7문장)"
    },
    "marriage_optimal": {
      "ideal_years": ["결혼하기 가장 좋은 나이 3-5개"],
      "avoid_years": ["결혼 피해야 할 나이 2-3개"],
      "spouse_type": "좋은 배우자 띠/특성",
      "advice": "결혼 시기 관련 조언 (7-10문장)"
    },
    "study_exam": {
      "good_years": ["시험/자격증 취득 좋은 나이 3-5개"],
      "study_aptitude": "학업/시험 적성 (5-7문장)",
      "advice": "학업/시험 관련 조언 (5-7문장)"
    }
  },

  "overall_advice": "종합적인 인생 조언 최소 20문장! 이 사람의 사주 전체를 아우르며, 인생을 어떻게 살아가면 좋을지 따뜻하고 구체적인 조언. 마치 인생 선배가 진심어린 조언을 하듯이",

  "lucky_elements": {
    "colors": ["행운의 색 2-3개"],
    "directions": ["좋은 방향 1-2개"],
    "numbers": [1, 6],
    "seasons": "유리한 계절",
    "partner_elements": ["궁합이 좋은 띠 2-3개"]
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
    buffer.writeln('│ ★★★ 이 값을 그대로 사용하세요 (재계산 금지) ★★★  │');
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
  String _buildDaeunSection(Map<String, dynamic>? daeun) {
    if (daeun == null || daeun.isEmpty) return '';

    final buffer = StringBuffer('\n## 대운 (大運)\n');

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

    // 대운 목록 (간략히)
    final list = daeun['list'];
    if (list != null && list is List && list.isNotEmpty) {
      final limitedList = list.take(5);
      buffer.writeln('- 대운 흐름: ${limitedList.map((d) {
        if (d is Map) return '${d['gan'] ?? ''}${d['ji'] ?? ''}';
        return d.toString();
      }).join(' → ')}...');
    }

    return buffer.toString();
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

    // 천간합 (★★★, 합화 시 ★★★★★)
    final cheonganHaps = hapchung['cheongan_haps'] as List? ?? [];
    if (cheonganHaps.isNotEmpty) {
      buffer.writeln('### 천간합 (天干合) [강도: ★★★]');
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

    // 지지육합 (★★ - 가장 부드러운 결합)
    final jijiYukhaps = hapchung['jiji_yukhaps'] as List? ?? [];
    if (jijiYukhaps.isNotEmpty) {
      buffer.writeln('### 지지육합 (地支六合) [강도: ★★ 부드러운 결합]');
      for (final y in jijiYukhaps) {
        final desc = y['description'] ?? '${y['ji1']}${y['ji2']}합';
        buffer.writeln('- ${y['pillar1']}주-${y['pillar2']}주: $desc');
      }
      buffer.writeln('');
    }

    // 삼합 (★★★★ 완성 / ★★★ 반합)
    final jijiSamhaps = hapchung['jiji_samhaps'] as List? ?? [];
    if (jijiSamhaps.isNotEmpty) {
      buffer.writeln('### 삼합 (三合) [강도: ★★★★ 강하고 유연함]');
      for (final s in jijiSamhaps) {
        final jijis = (s['jijis'] as List?)?.join('') ?? '';
        final pillars = (s['pillars'] as List?)?.join(',') ?? '';
        final isFull = s['is_full'] as bool? ?? true;
        final label = isFull ? '삼합(★★★★)' : '반합(★★★)';
        buffer.writeln('- ${pillars}주: $jijis $label (${s['result_oheng']}국)');
      }
      buffer.writeln('');
    }

    // 방합 (★★★★★ - 가장 강력!)
    final jijiBanghaps = hapchung['jiji_banghaps'] as List? ?? [];
    if (jijiBanghaps.isNotEmpty) {
      buffer.writeln('### 방합 (方合) [강도: ★★★★★ 가장 강력! 고정적]');
      for (final b in jijiBanghaps) {
        final jijis = (b['jijis'] as List?)?.join('') ?? '';
        final pillars = (b['pillars'] as List?)?.join(',') ?? '';
        buffer.writeln('- ${pillars}주: $jijis 방합(★★★★★) (${b['season']}, ${b['direction']}방)');
      }
      buffer.writeln('');
    }

    // 지지충 (강도별: 왕지충★★★★★ > 생지충★★★★ > 고지충★★★)
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

    // 지지형 (삼형★★★★★ > 상형★★★ > 자묘형★★ > 자형★)
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

    // 왕지충 ★★★★★
    if (pair.containsAll({'묘', '유'}) || pair.containsAll({'卯', '酉'})) {
      return '(왕지충★★★★★ 원수충!)';
    }
    if (pair.containsAll({'자', '오'}) || pair.containsAll({'子', '午'})) {
      return '(왕지충★★★★★)';
    }

    // 생지충 ★★★★
    if (pair.containsAll({'인', '신'}) || pair.containsAll({'寅', '申'})) {
      return '(생지충★★★★ 역마충돌!)';
    }
    if (pair.containsAll({'사', '해'}) || pair.containsAll({'巳', '亥'})) {
      return '(생지충★★★★)';
    }

    // 고지충 ★★★
    if (pair.containsAll({'진', '술'}) || pair.containsAll({'辰', '戌'})) {
      return '(고지충★★★ 오래지속)';
    }
    if (pair.containsAll({'축', '미'}) || pair.containsAll({'丑', '未'})) {
      return '(고지충★★★ 오래지속)';
    }

    return '';
  }

  /// 형(刑) 강도 판별
  /// 삼형 > 상형 > 자묘형 > 자형
  String _getHyungStrength(String hyungType) {
    switch (hyungType) {
      case '인사신삼형':
      case '寅巳申삼형':
        return '(삼형★★★★★ 관재/배신!)';
      case '축술미삼형':
      case '丑戌未삼형':
        return '(삼형★★★★★ 신의깨짐!)';
      case '인사형':
      case '사신형':
      case '인신형':
      case '축술형':
      case '술미형':
      case '축미형':
        return '(상형★★★)';
      case '자묘형':
      case '子卯형':
        return '(무례지형★★)';
      case '자형':
      case '진진형':
      case '오오형':
      case '유유형':
      case '해해형':
        return '(자형★)';
      default:
        return '';
    }
  }
}
