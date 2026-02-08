/// # 월별 운세 프롬프트 (v5.0 - 12개월 상세 통합)
///
/// ## 개요
/// saju_base(평생운세) + saju_analyses(원국 데이터)를 기반으로 12개월 전체 운세 분석
///
/// ## 파일 위치
/// `frontend/lib/AI/fortune/monthly/monthly_prompt.dart`
///
/// ## v5.0 개선사항 (12개월 상세화)
/// - 현재 월: 7개 카테고리 상세 분석 (12-15문장)
/// - 나머지 11개월: 상세 버전으로 확장! (6-8문장 + 3개 카테고리 하이라이트 + 행운요소)
/// - 광고 해금 시 충분한 가치 제공
/// - 한 번의 API 호출로 12개월 전체 분석
///
/// ## 모델
/// GPT-5-mini ($0.25 input, $2.00 output per 1M tokens)

import '../../core/ai_constants.dart';
import '../common/prompt_template.dart';
import '../common/fortune_input_data.dart';

/// 이번달 운세 프롬프트 템플릿
class MonthlyPrompt extends PromptTemplate {
  /// 입력 데이터 (saju_base + saju_analyses 포함)
  final FortuneInputData inputData;

  /// 대상 연도
  final int targetYear;

  /// 대상 월
  final int targetMonth;

  MonthlyPrompt({
    required this.inputData,
    required this.targetYear,
    required this.targetMonth,
  });

  @override
  String get summaryType => SummaryType.monthlyFortune;

  @override
  String get modelName => OpenAIModels.fortuneAnalysis; // gpt-5-mini

  @override
  int get maxTokens => 16000; // v5.0: 12개월 상세 분석용 (현재월 상세 + 11개월 확장)

  @override
  double get temperature => 0.7;

  @override
  Duration? get cacheExpiry => CacheExpiry.monthlyFortune;

  /// 월별 간지 계산
  /// TODO: 연도별 동적 계산으로 변경 (현재 2025-2026년 하드코딩)
  String get _monthGanji {
    // 2025년 월별 간지 (을사년)
    const ganji2025 = {
      1: '정축(丁丑)',
      2: '무인(戊寅)',
      3: '기묘(己卯)',
      4: '경진(庚辰)',
      5: '신사(辛巳)',
      6: '임오(壬午)',
      7: '계미(癸未)',
      8: '갑신(甲申)',
      9: '을유(乙酉)',
      10: '병술(丙戌)',
      11: '정해(丁亥)',
      12: '무자(戊子)',
    };

    // 2026년 월별 간지 (병오년)
    const ganji2026 = {
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

    if (targetYear == 2025) {
      return ganji2025[targetMonth] ?? '';
    } else if (targetYear == 2026) {
      return ganji2026[targetMonth] ?? '';
    }
    return '';
  }

  /// 월간 오행 (간지에서 추출)
  Map<String, String> get _monthElement {
    // 2026년 월별 오행
    const elements2026 = {
      1: {'stem': '庚', 'stemElement': '금(金)', 'branch': '寅', 'branchElement': '목(木)'},
      2: {'stem': '辛', 'stemElement': '금(金)', 'branch': '卯', 'branchElement': '목(木)'},
      3: {'stem': '壬', 'stemElement': '수(水)', 'branch': '辰', 'branchElement': '토(土)'},
      4: {'stem': '癸', 'stemElement': '수(水)', 'branch': '巳', 'branchElement': '화(火)'},
      5: {'stem': '甲', 'stemElement': '목(木)', 'branch': '午', 'branchElement': '화(火)'},
      6: {'stem': '乙', 'stemElement': '목(木)', 'branch': '未', 'branchElement': '토(土)'},
      7: {'stem': '丙', 'stemElement': '화(火)', 'branch': '申', 'branchElement': '금(金)'},
      8: {'stem': '丁', 'stemElement': '화(火)', 'branch': '酉', 'branchElement': '금(金)'},
      9: {'stem': '戊', 'stemElement': '토(土)', 'branch': '戌', 'branchElement': '토(土)'},
      10: {'stem': '己', 'stemElement': '토(土)', 'branch': '亥', 'branchElement': '수(水)'},
      11: {'stem': '庚', 'stemElement': '금(金)', 'branch': '子', 'branchElement': '수(水)'},
      12: {'stem': '辛', 'stemElement': '금(金)', 'branch': '丑', 'branchElement': '토(土)'},
    };

    // 2025년 월별 오행
    const elements2025 = {
      1: {'stem': '丁', 'stemElement': '화(火)', 'branch': '丑', 'branchElement': '토(土)'},
      2: {'stem': '戊', 'stemElement': '토(土)', 'branch': '寅', 'branchElement': '목(木)'},
      3: {'stem': '己', 'stemElement': '토(土)', 'branch': '卯', 'branchElement': '목(木)'},
      4: {'stem': '庚', 'stemElement': '금(金)', 'branch': '辰', 'branchElement': '토(土)'},
      5: {'stem': '辛', 'stemElement': '금(金)', 'branch': '巳', 'branchElement': '화(火)'},
      6: {'stem': '壬', 'stemElement': '수(水)', 'branch': '午', 'branchElement': '화(火)'},
      7: {'stem': '癸', 'stemElement': '수(水)', 'branch': '未', 'branchElement': '토(土)'},
      8: {'stem': '甲', 'stemElement': '목(木)', 'branch': '申', 'branchElement': '금(金)'},
      9: {'stem': '乙', 'stemElement': '목(木)', 'branch': '酉', 'branchElement': '금(金)'},
      10: {'stem': '丙', 'stemElement': '화(火)', 'branch': '戌', 'branchElement': '토(土)'},
      11: {'stem': '丁', 'stemElement': '화(火)', 'branch': '亥', 'branchElement': '수(水)'},
      12: {'stem': '戊', 'stemElement': '토(土)', 'branch': '子', 'branchElement': '수(水)'},
    };

    if (targetYear == 2025) {
      return elements2025[targetMonth] ?? {};
    } else if (targetYear == 2026) {
      return elements2026[targetMonth] ?? {};
    }
    return {};
  }

  @override
  String get systemPrompt => '''
당신은 30년 경력의 사주명리학 전문가이자 스토리텔러입니다.
사용자의 원국(사주 팔자)과 평생운세 분석을 바탕으로 ${targetYear}년 12개월 전체 운세를 분석합니다.

## 쉬운말 원칙 (최우선! 이 규칙을 가장 먼저 지키세요!)

사주를 전혀 모르는 20-30대가 읽는다고 가정하세요.
전문용어 없이도 "아, 이번달 이렇게 하면 되겠구나" 하고 바로 이해할 수 있게 써야 합니다.

### 절대 금지 용어 (이 단어들을 본문에 직접 쓰지 마세요)
- 십성 용어: 비견, 겁재, 식신, 상관, 정재, 편재, 정관, 편관, 정인, 편인
- 위치 용어: 일간, 월간, 연간, 시간, 일지, 월지 → "당신의 타고난 기운", "이번달의 기운" 등으로
- 신살 용어: 용신, 희신, 기신, 구신 → "당신에게 힘이 되는 기운", "조심해야 할 기운"
- 관계 용어: 상생, 상극, 합, 충, 형, 파, 해 → 자연현상 비유로 대체
- 천간/지지 한자: 갑을병정무기경신임계, 자축인묘진사오미신유술해 → 본문에 쓸 필요 없음
- 오행 한자 표기: 목(木), 화(火) 등 → "나무", "불", "흙", "금속", "물"로만

### 변환 규칙
| 전문 표현 | → 쉬운 표현 |
|-----------|------------|
| 갑목 일간에게 이번달 화는 식신 | 큰 나무의 기운을 타고난 당신에게 이번달 불기운은 표현의 에너지예요 |
| 편재가 들어와 | 예상치 못한 돈 기회가 생겨서 |
| 인신충 | 이번달 큰 변화의 바람이 불어요 |
| 용신 수가 힘을 받아 | 당신에게 가장 힘이 되는 물의 기운이 살아나서 |

### 만약 전문용어를 꼭 써야 한다면
"표현과 재능의 에너지(사주에서는 '식상'이라고 해요)" 처럼
**쉬운말 먼저, 전문용어는 괄호 안에 작게**

---

## 현재 요청 월: ${targetMonth}월 $_monthGanji
- 월천간: ${_monthElement['stem']} (${_monthElement['stemElement']})
- 월지지: ${_monthElement['branch']} (${_monthElement['branchElement']})

## 응답 구조 (중요!)
1. **현재 월($targetMonth월)**: 7개 카테고리별 상세 분석 (각 12-15문장)
2. **나머지 11개월**: 상세 버전! (키워드 + 점수 + 8-10문장 reading + 7개 카테고리 highlights + tip + idiom + lucky)
   - 광고 해금 후 사용자가 읽을 핵심 콘텐츠이므로 절대 짧게 쓰지 마세요!

---

## 고전 vs 현대(AI시대) 해석 (내부 참고용 - 본문에 한자/전문용어 쓰지 말 것!)

분석 시 이 표를 참고하되, 사용자에게는 쉬운 말로만 전달하세요.
"옛날에는 ~라고 봤지만, 요즘은 ~로 나타나요" 형식을 자연스럽게 포함하세요.

| 내부 참고 | 본문에 쓸 표현 | 현대 적용 |
|-----------|--------------|----------|
| 식상 | "표현력/창작 에너지" | 유튜브/블로그/콘텐츠 |
| 역마살 | "이동/변화의 기운" | 디지털노마드/출장 |
| 도화살 | "매력이 빛나는 기운" | 인플루언서/마케팅 |
| 인성 | "배움/보호의 기운" | AI도구/온라인강의 |
| 재성 | "재물/기회의 기운" | 주식/부업/프리랜서 |
| 관성 | "직장/책임의 기운" | 승진/프로젝트 |
| 비겁 | "경쟁/협력의 기운" | 팀협업/공동프로젝트 |
| 화개살 | "집중/몰입의 기운" | 딥워크/재택/연구 |

**월운 설명 예시 (쉬운말 버전):**
- "옛날에는 이 표현의 에너지를 자녀운으로 봤지만, 요즘은 콘텐츠 창작이나 아이디어 표현에 탁월한 재능이에요. 이번달 표현의 에너지가 강하니 발표나 SNS 활동에서 반응이 좋을 거예요."
- "옛날에는 이런 이동의 기운을 타향살이로 봤지만, 요즘은 출장이나 온라인 글로벌 미팅으로 기회가 됩니다. 이번달 새로운 환경에서의 업무가 잘 풀릴 거예요."
- "옛날에는 이런 직장의 기운을 관직에 오른다고 봤지만, 요즘은 프로젝트 책임자가 되거나 팀을 이끄는 역할이에요. 이번달 상사의 평가가 좋거나 중요한 역할을 맡게 될 수 있어요."

---

## ⭐ 절대 원칙: "왜" 그런지 근거를 반드시 설명하세요! ⭐

모든 분석에서 막연한 표현 금지! 반드시 원인-결과를 연결해서 설명합니다:

### 나쁜 예 (금지!)
- "이번달은 좋은 달이에요" (이유 없음)
- "주의가 필요한 시기입니다" (막연함)
- "편재(偏財)가 들어와서 돈운이 좋아요" (전문용어 직접 노출)

### 좋은 예 (이렇게 써주세요!)
- "이번달은 적극적으로 기회를 잡는 재물의 기운이 들어오는 시기예요. 평소보다 예상치 못한 수입이나 투자 기회가 생길 수 있어요. (사주 전문가 해석: 경금 일간에게 월지 인목은 편재)"
- "이번달은 큰 변화의 바람이 부는 시기예요. 일정이 바쁘거나 예상치 못한 변수가 생길 수 있지만, 이건 새로운 기회의 문이 열리는 신호이기도 해요."
- "당신에게 가장 힘이 되는 물의 기운이 이번달 살아나면서, 전체적으로 균형이 잡히는 좋은 흐름이에요."

### 분석 시 내부적으로 반드시 고려하되, 본문에는 쉬운말로만 표현
1. 타고난 기운과 이번달 기운의 관계 → 자연현상 비유로 풀어서
2. 관계의 구체적 의미 → "표현의 에너지", "재물의 기운" 등으로
3. 힘이 되는 기운/조심할 기운과의 관계 → 자연현상 비유로
4. 기운의 충돌/어울림 → "변화의 바람", "좋은 인연의 흐름" 등 일상어로

---

## 작성 원칙: 스토리텔링!

### 1. 줄줄 읽히는 문장
- 짧은 문장 나열 금지! 자연스럽게 이어지는 문단으로 작성
- 마치 전문가가 옆에서 설명해주는 것처럼
- 각 문단은 3-5문장이 자연스럽게 연결되어야 함
- **왜 그런지 명리학적 이유를 함께 설명**

### 2. 이번달 기운을 자연스럽게 녹이기
- "이번달 ${_monthElement['branchElement']} 기운이 들어오면서..."
- 전문 용어는 절대 직접 쓰지 말고, 쉬운말로 풀어서
- **힘이 되는 기운과 이번달 기운의 관계도 자연현상으로 설명**

### 3. 기운의 만남도 이야기처럼
- "특히 이번달 기운이 {이름}님의 타고난 기운과 만나면서..."
- 기운이 잘 맞으면 좋은 인연, 부딪히면 변화의 기회로 설명
- **왜 그런 영향이 있는지** 자연현상 비유로 설명

### 4. 구체적 상황 예시
- "첫째 주에는 미팅이나 계약이 잘 풀릴 수 있어요..."
- "셋째 주 중반쯤 건강 관리에 신경 쓰시면..."

## 톤앤매너
- 점쟁이 말투 절대 금지
- 친근하고 따뜻한 조언자 톤
- 사주 전문용어는 본문에 직접 쓰지 말 것 (꼭 필요하면 괄호 안에 작게)
- 긍정/부정 균형, 현실적 조언

## 응답 형식
반드시 아래 JSON 형식으로 응답하세요. 각 필드의 문장들이 자연스럽게 이어지도록!
''';

  @override
  String buildUserPrompt([Map<String, dynamic>? input]) {
    return '''
## 사용자 기본 정보
- 이름: ${inputData.profileName}
- 생년월일: ${inputData.birthDate}
${inputData.birthTime != null ? '- 태어난 시간: ${inputData.birthTime}' : ''}
- 성별: ${inputData.genderKorean}

## 사주 팔자 (원국)
${inputData.sajuPaljaTable}

## 일간 강약
${inputData.dayStrengthInfo}

## 용신/기신 (가장 중요!)
${inputData.yongsinInfo}

---
## ⭐ ${targetYear}년 ${targetMonth}월 $_monthGanji와 나의 오행 결합 분석 ⭐
${_formatMonthlyCombination()}
---

## 이번달과의 합충 관계
${_formatMonthlyHapchung()}

## 신살(神煞)
${inputData.sinsalInfo}

## 평생 사주 분석 (saju_base)
${_formatSajuBase()}

## 분석 요청

위 원국 정보와 **"이번달과 나의 오행 결합 분석"**을 바탕으로 ${targetYear}년 ${targetMonth}월 운세를 분석해주세요.

**⭐ 핵심: 일간(${inputData.dayGan ?? '?'}) + 월운(${_monthElement['branchElement'] ?? '?'}) = ${inputData.getSipseongFor(_extractPureElement(_monthElement['branchElement']) ?? '') ?? '?'} 관계를 중심으로!**

**스토리텔링으로 작성해주세요:**
- **십성(${inputData.getSipseongFor(_extractPureElement(_monthElement['branchElement']) ?? '') ?? '?'})이 이번달 어떤 영향을 미치는지** 자연스럽게 녹여서
- 월천간/월지와 ${inputData.yongsinElement != null ? '용신 ${inputData.yongsinElement}' : '용신'}의 관계
- 월지 ${_monthElement['branch']}와 ${inputData.dayJi != null ? '일지 ${inputData.dayJi}' : '일지'}의 관계를 이야기하듯이

## ⚠️ 점수 산정 규칙 (매우 중요!)
- 점수는 **반드시 이 사람의 사주 원국 + 해당 월의 간지 조합**으로 계산하세요
- **예시 점수를 절대 그대로 쓰지 마세요!** 사람마다, 달마다 달라야 합니다
- 범위: 30~95 (과감하게! 좋은 달은 90+, 나쁜 달은 40 이하도 OK)
- 카테고리 간 점수 차이를 크게 두세요 (최소 15점 이상 차이나는 항목이 있어야 함)
- 12개월 간 점수 차이도 크게! (최고 달과 최저 달 차이 30점 이상)
- 용신이 힘을 받는 달 → 해당 분야 높은 점수 (85+)
- 기신/구신이 강한 달 → 해당 분야 낮은 점수 (50 이하)
- 합충이 있는 달 → 변동폭 크게 (극단적 점수 가능)

## 응답 JSON 스키마 (v4.0: 12개월 통합)

**중요**: 현재 월($targetMonth월)은 상세 분석, 나머지 11개월은 요약!
**점수는 숫자만! 문자열 X. 예: "score": 42 (O), "score": "(30~95)" (X)**

{
  "year": $targetYear,
  "currentMonth": $targetMonth,

  "current": {
    "month": $targetMonth,
    "monthGanji": "$_monthGanji",
    "overview": {
      "keyword": "이번달 핵심 키워드 (3-4자)",
      "score": "(30~95, 일간+월운+용신 기반 계산)",
      "reading": "${targetMonth}월 총운입니다. 이번달은 $_monthGanji 월로, ${_monthElement['stemElement']}과 ${_monthElement['branchElement']} 기운이 함께 흐르는 시기입니다. {이름}님의 일간 {일간}에게 이번달 월지의 ${_monthElement['branchElement']} 기운이 {십성}으로 작용하면서 {영향 설명}. {용신/기신과의 관계 설명}. {합충이 있다면 설명}. 따라서 이번달은 {결론}하시면 좋겠습니다. (8-10문장)"
    },
    "categories": {
      "career": {
        "title": "직업운",
        "score": "(30~95, 관성+월운 기반)",
        "reading": "이번달 직장에서는 ${_monthGanji}의 {십성} 기운이 흐릅니다. {이름}님의 일간이 {일간}이시고, 월지의 ${_monthElement['branchElement']} 기운이 {십성}으로 작용해요. {십성}은 직장에서 {직장적 의미}를 의미합니다. 원국에서 관성이 {관성 특성}하신 편이라, 이번달 {구체적 영향}이 예상됩니다. {합충 영향}. 업무 성과를 높이려면 {업무 조언}하시고, 동료/상사 관계에서는 {관계 조언}을 기억하세요. {마무리 조언}. (반드시 12-15문장)"
      },
      "business": {
        "title": "사업운",
        "score": "(30~95, 재성+식상+월운 기반)",
        "reading": "사업 측면에서 이번달은 {십성} 기운이 영향을 미칩니다. {일간}에게 ${_monthElement['branchElement']} 기운이 {십성}으로 작용하고, 사업에서 {십성}은 {사업적 의미}를 의미해요. 원국의 재성이 {재성 강약}하셔서 {재성 영향}이 예상됩니다. 파트너십이나 거래처 관계에서는 {파트너 조언}. 사업 확장은 {확장 조언}, 신규 계약은 {계약 조언}을 참고하세요. {마무리 조언}. (반드시 12-15문장)"
      },
      "wealth": {
        "title": "재물운",
        "score": "(30~95, 재성+비겁+월운 기반)",
        "reading": "재물 측면에서 이번달은 {십성}의 기운이 흐릅니다. ${_monthElement['branchElement']} 기운이 {십성}으로 작용하고, 재물에서 {재물적 의미}를 나타냅니다. 원국에서 재성이 {재성 강약}하셔서 {원국 영향}. 투자는 {투자 조언}하시고, 지출 관리는 {지출 조언}을 권해드려요. {마무리 조언}. (반드시 12-15문장)"
      },
      "love": {
        "title": "애정운",
        "score": "(30~95, 일지+도화+월운 기반)",
        "reading": "애정운에서 이번달은 월지와 일지의 관계로 {연애 분위기}한 기운이 흐릅니다. 월지 ${_monthElement['branch']}가 일지와 {합/충/무관계}하면서 {합충 영향}. 원국에서 {배우자성}이 {특성}하셔서 {연애 영향}이 예상됩니다. 솔로이신 분들은 {솔로 조언}. 연인이 있으신 분들은 {커플 조언}. {마무리 조언}. (반드시 12-15문장)"
      },
      "marriage": {
        "title": "결혼운",
        "score": "(30~95, 배우자궁+월운 기반)",
        "reading": "결혼 관점에서 이번달은 배우자궁인 일지와 월지 ${_monthElement['branch']}의 관계가 핵심이에요. {합/충 분석}. {일간}에게 ${_monthElement['branchElement']} 기운이 {십성}으로 작용하고, 결혼에서 {십성}은 {결혼적 의미}를 나타내요. 미혼이신 분들은 {미혼 조언}. 기혼이신 분들은 {기혼 조언}. {마무리 조언}. (반드시 12-15문장)"
      },
      "health": {
        "title": "건강운",
        "score": "(30~95, 오행균형+월운 기반)",
        "reading": "건강 측면에서 이번달은 ${_monthElement['branchElement']} 기운이 강하게 흐릅니다. 오행에서 이 기운은 {해당 장부}에 해당하고, {건강 영향 원인}이 생길 수 있어요. 원국에서 {약한 오행}이 약하셔서 {오행 불균형}에 주의하세요. 운동으로는 {운동 추천}, 식이요법은 {음식 조언}이 도움됩니다. {마무리 조언}. (반드시 12-15문장)"
      },
      "study": {
        "title": "학업운",
        "score": "(30~95, 인성+식상+월운 기반)",
        "reading": "학업 관점에서 이번달 ${_monthElement['branchElement']} 기운이 {일간}에게 {십성}으로 작용해요. {십성}은 학업에서 {학업적 의미}를 뜻합니다. 원국에서 인성이 {인성 분석}하고 식상이 {식상 분석}하셔서 {구체적 영향}이 예상됩니다. 시험 준비는 {시험 조언}, 자격증은 {자격증 조언}을 참고하세요. {마무리 조언}. (반드시 12-15문장)"
      }
    },
    "lucky": {
      "colors": ["행운색1", "행운색2"],
      "numbers": ["숫자1", "숫자2"],
      "tip": "행운 요소 활용법 (2문장)"
    }
  },

  "months": {
    "month1": {
      "keyword": "1월 핵심 키워드 (3-4자)",
      "score": "(30~95, 1월 간지+원국 기반 - 예시 점수 복사 금지!)",
      "reading": "1월은 {월간지}의 기운으로 {일간}에게 {십성}이 작용합니다. 고전에서는 {전통해석}이지만 현대에서는 {현대해석}으로 볼 수 있어요. {용신/기신 관계 설명}. {합충이 있다면 변화/기회 설명}. 이 달의 핵심은 {핵심 포인트}입니다. {일간+월운 조합이 각 영역에 미치는 영향 설명}. {구체적 조언}하시면 좋은 결과를 얻을 수 있어요. 전반적으로 {마무리 조언}. (반드시 8-10문장, 광고 해금 후 사용자가 읽을 핵심 콘텐츠!)",
      "tip": "이 달의 핵심 실천 조언 (2문장, 구체적으로!)",
      "idiom": {"phrase": "사자성어 (한자 및 한글)", "meaning": "이 달에 어울리는 사자성어 의미와 적용 조언 (2문장)"},
      "highlights": {
        "career": {"score": "(30~95)", "summary": "직장에서 {십성} 기운으로 {핵심 영향}. {구체적 조언} (2문장)"},
        "business": {"score": "(30~95)", "summary": "사업/자영업에서 {핵심 영향}. {구체적 조언} (2문장)"},
        "wealth": {"score": "(30~95)", "summary": "재물 측면에서 {핵심 영향}. {구체적 조언} (2문장)"},
        "love": {"score": "(30~95)", "summary": "애정/관계에서 {핵심 영향}. {구체적 조언} (2문장)"},
        "marriage": {"score": "(30~95)", "summary": "결혼/가정에서 {핵심 영향}. {구체적 조언} (2문장)"},
        "health": {"score": "(30~95)", "summary": "건강 측면에서 {핵심 영향}. {구체적 조언} (2문장)"},
        "study": {"score": "(30~95)", "summary": "학업/자격증에서 {핵심 영향}. {구체적 조언} (2문장)"}
      },
      "lucky": {"color": "이 달 행운색 (용신 기반)", "number": "(용신 오행 기반 숫자)"}
    },
    "month2": {
      "keyword": "2월 키워드 (3-4자, 개별 계산!)",
      "score": "(30~95, 2월 간지+원국 기반)",
      "reading": "(8~10문장, 2월 간지 기반 분석)",
      "tip": "(2문장, 구체적 실천 조언)",
      "idiom": {"phrase": "사자성어", "meaning": "의미와 조언"},
      "highlights": {
        "career": {"score": "(30~95)", "summary": "(2문장)"},
        "business": {"score": "(30~95)", "summary": "(2문장)"},
        "wealth": {"score": "(30~95)", "summary": "(2문장)"},
        "love": {"score": "(30~95)", "summary": "(2문장)"},
        "marriage": {"score": "(30~95)", "summary": "(2문장)"},
        "health": {"score": "(30~95)", "summary": "(2문장)"},
        "study": {"score": "(30~95)", "summary": "(2문장)"}
      },
      "lucky": {"color": "행운색", "number": "(숫자)"}
    },
    "month3": {"keyword":"...", "score":"(30~95)", "reading":"(8~10문장)", "tip":"...", "idiom":{"phrase":"...", "meaning":"..."}, "highlights":{"career":{"score":"(30~95)","summary":"..."}, "business":{"score":"(30~95)","summary":"..."}, "wealth":{"score":"(30~95)","summary":"..."}, "love":{"score":"(30~95)","summary":"..."}, "marriage":{"score":"(30~95)","summary":"..."}, "health":{"score":"(30~95)","summary":"..."}, "study":{"score":"(30~95)","summary":"..."}}, "lucky":{"color":"...", "number":"(숫자)"}},
    "month4": {"keyword":"...", "score":"(30~95)", "reading":"(8~10문장)", "tip":"...", "idiom":{"phrase":"...", "meaning":"..."}, "highlights":{"career":{"score":"(30~95)","summary":"..."}, "business":{"score":"(30~95)","summary":"..."}, "wealth":{"score":"(30~95)","summary":"..."}, "love":{"score":"(30~95)","summary":"..."}, "marriage":{"score":"(30~95)","summary":"..."}, "health":{"score":"(30~95)","summary":"..."}, "study":{"score":"(30~95)","summary":"..."}}, "lucky":{"color":"...", "number":"(숫자)"}},
    "month5": {"keyword":"...", "score":"(30~95)", "reading":"(8~10문장)", "tip":"...", "idiom":{"phrase":"...", "meaning":"..."}, "highlights":{"career":{"score":"(30~95)","summary":"..."}, "business":{"score":"(30~95)","summary":"..."}, "wealth":{"score":"(30~95)","summary":"..."}, "love":{"score":"(30~95)","summary":"..."}, "marriage":{"score":"(30~95)","summary":"..."}, "health":{"score":"(30~95)","summary":"..."}, "study":{"score":"(30~95)","summary":"..."}}, "lucky":{"color":"...", "number":"(숫자)"}},
    "month6": {"keyword":"...", "score":"(30~95)", "reading":"(8~10문장)", "tip":"...", "idiom":{"phrase":"...", "meaning":"..."}, "highlights":{"career":{"score":"(30~95)","summary":"..."}, "business":{"score":"(30~95)","summary":"..."}, "wealth":{"score":"(30~95)","summary":"..."}, "love":{"score":"(30~95)","summary":"..."}, "marriage":{"score":"(30~95)","summary":"..."}, "health":{"score":"(30~95)","summary":"..."}, "study":{"score":"(30~95)","summary":"..."}}, "lucky":{"color":"...", "number":"(숫자)"}},
    "month7": {"keyword":"...", "score":"(30~95)", "reading":"(8~10문장)", "tip":"...", "idiom":{"phrase":"...", "meaning":"..."}, "highlights":{"career":{"score":"(30~95)","summary":"..."}, "business":{"score":"(30~95)","summary":"..."}, "wealth":{"score":"(30~95)","summary":"..."}, "love":{"score":"(30~95)","summary":"..."}, "marriage":{"score":"(30~95)","summary":"..."}, "health":{"score":"(30~95)","summary":"..."}, "study":{"score":"(30~95)","summary":"..."}}, "lucky":{"color":"...", "number":"(숫자)"}},
    "month8": {"keyword":"...", "score":"(30~95)", "reading":"(8~10문장)", "tip":"...", "idiom":{"phrase":"...", "meaning":"..."}, "highlights":{"career":{"score":"(30~95)","summary":"..."}, "business":{"score":"(30~95)","summary":"..."}, "wealth":{"score":"(30~95)","summary":"..."}, "love":{"score":"(30~95)","summary":"..."}, "marriage":{"score":"(30~95)","summary":"..."}, "health":{"score":"(30~95)","summary":"..."}, "study":{"score":"(30~95)","summary":"..."}}, "lucky":{"color":"...", "number":"(숫자)"}},
    "month9": {"keyword":"...", "score":"(30~95)", "reading":"(8~10문장)", "tip":"...", "idiom":{"phrase":"...", "meaning":"..."}, "highlights":{"career":{"score":"(30~95)","summary":"..."}, "business":{"score":"(30~95)","summary":"..."}, "wealth":{"score":"(30~95)","summary":"..."}, "love":{"score":"(30~95)","summary":"..."}, "marriage":{"score":"(30~95)","summary":"..."}, "health":{"score":"(30~95)","summary":"..."}, "study":{"score":"(30~95)","summary":"..."}}, "lucky":{"color":"...", "number":"(숫자)"}},
    "month10": {"keyword":"...", "score":"(30~95)", "reading":"(8~10문장)", "tip":"...", "idiom":{"phrase":"...", "meaning":"..."}, "highlights":{"career":{"score":"(30~95)","summary":"..."}, "business":{"score":"(30~95)","summary":"..."}, "wealth":{"score":"(30~95)","summary":"..."}, "love":{"score":"(30~95)","summary":"..."}, "marriage":{"score":"(30~95)","summary":"..."}, "health":{"score":"(30~95)","summary":"..."}, "study":{"score":"(30~95)","summary":"..."}}, "lucky":{"color":"...", "number":"(숫자)"}},
    "month11": {"keyword":"...", "score":"(30~95)", "reading":"(8~10문장)", "tip":"...", "idiom":{"phrase":"...", "meaning":"..."}, "highlights":{"career":{"score":"(30~95)","summary":"..."}, "business":{"score":"(30~95)","summary":"..."}, "wealth":{"score":"(30~95)","summary":"..."}, "love":{"score":"(30~95)","summary":"..."}, "marriage":{"score":"(30~95)","summary":"..."}, "health":{"score":"(30~95)","summary":"..."}, "study":{"score":"(30~95)","summary":"..."}}, "lucky":{"color":"...", "number":"(숫자)"}},
    "month12": {"keyword":"...", "score":"(30~95)", "reading":"(8~10문장)", "tip":"...", "idiom":{"phrase":"...", "meaning":"..."}, "highlights":{"career":{"score":"(30~95)","summary":"..."}, "business":{"score":"(30~95)","summary":"..."}, "wealth":{"score":"(30~95)","summary":"..."}, "love":{"score":"(30~95)","summary":"..."}, "marriage":{"score":"(30~95)","summary":"..."}, "health":{"score":"(30~95)","summary":"..."}, "study":{"score":"(30~95)","summary":"..."}}, "lucky":{"color":"...", "number":"(숫자)"}}
  },

  "closingMessage": "${targetYear}년을 보내는 {이름}님께. 12개월 전체를 보면 {연간 흐름 요약}. {격려/응원}. (2문장)"
}

**점수는 반드시 숫자만! 예: "score": 42 (O), "score": "(30~95)" (X)**
**12개월 점수가 65~75 사이에 몰려있으면 안 됩니다! 과감하게!**
''';
  }

  /// saju_base 내용을 포맷팅 (v3.0: Optional)
  /// - saju_base 없이도 운세 분석 가능 (saju_analyses만으로 충분)
  /// - saju_base가 있으면 참고 정보로 활용
  String _formatSajuBase() {
    final content = inputData.sajuBaseContent;

    // v3.0: sajuBaseContent가 null인 경우 (saju_analyses만 사용)
    if (content == null) {
      return '''
(saju_base 미사용 - v3.0)
※ 위의 사주 분석 데이터(saju_analyses)를 기반으로 운세를 분석합니다.
- 사주 팔자(천간/지지)
- 용신/희신/기신/구신
- 합충형파해
- 일간 강약
- 신살/십신
''';
    }

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

    return buffer.toString();
  }

  /// 이번달 월지와 일지의 합충 분석 포맷팅
  String _formatMonthlyHapchung() {
    final buffer = StringBuffer();
    final dayJi = inputData.dayJi;
    final monthBranch = _monthElement['branch'];

    if (dayJi == null || monthBranch == null) {
      return '(합충 분석 정보 없음)';
    }

    buffer.writeln('- 사용자 일지: $dayJi');
    buffer.writeln('- 이번달 월지: $monthBranch');
    buffer.writeln();

    // 주요 합충 관계 힌트
    final hapchungHints = _getHapchungHint(dayJi, monthBranch);
    if (hapchungHints.isNotEmpty) {
      buffer.writeln('** 합충 관계 분석 필요:');
      buffer.writeln(hapchungHints);
    }

    return buffer.toString();
  }

  /// 일지와 월지의 합충 관계 힌트
  String _getHapchungHint(String dayJi, String monthBranch) {
    // "진(辰)" → "辰" 한자 추출
    final dayJiHanja = _extractHanja(dayJi);
    final monthHanja = _extractHanja(monthBranch);

    // 육충 (六衝)
    const chung = {
      '子': '午', '午': '子',
      '丑': '未', '未': '丑',
      '寅': '申', '申': '寅',
      '卯': '酉', '酉': '卯',
      '辰': '戌', '戌': '辰',
      '巳': '亥', '亥': '巳',
    };

    // 육합 (六合)
    const hap = {
      '子': '丑', '丑': '子',
      '寅': '亥', '亥': '寅',
      '卯': '戌', '戌': '卯',
      '辰': '酉', '酉': '辰',
      '巳': '申', '申': '巳',
      '午': '未', '未': '午',
    };

    // 삼합 (三合)
    const samhap = {
      '寅': ['午', '戌'], // 火局
      '午': ['寅', '戌'],
      '戌': ['寅', '午'],
      '申': ['子', '辰'], // 水局
      '子': ['申', '辰'],
      '辰': ['申', '子'],
      '巳': ['酉', '丑'], // 金局
      '酉': ['巳', '丑'],
      '丑': ['巳', '酉'],
      '亥': ['卯', '未'], // 木局
      '卯': ['亥', '未'],
      '未': ['亥', '卯'],
    };

    final buffer = StringBuffer();

    // 충 체크
    if (chung[dayJiHanja] == monthHanja) {
      buffer.writeln(
          '- $dayJi와 $monthBranch: 육충(六衝) 발생 - 변화/이동/갈등 가능, 정체된 에너지 해소의 기회');
    }

    // 합 체크
    if (hap[dayJiHanja] == monthHanja) {
      buffer.writeln('- $dayJi와 $monthBranch: 육합(六合) 발생 - 협력/결합/좋은 인연의 달');
    }

    // 삼합 체크
    if (samhap[dayJiHanja]?.contains(monthHanja) ?? false) {
      String element;
      if (['寅', '午', '戌'].contains(dayJiHanja)) {
        element = '화국(火局)';
      } else if (['申', '子', '辰'].contains(dayJiHanja)) {
        element = '수국(水局)';
      } else if (['巳', '酉', '丑'].contains(dayJiHanja)) {
        element = '금국(金局)';
      } else {
        element = '목국(木局)';
      }
      buffer.writeln('- $dayJi와 $monthBranch: 삼합($element) 기운 작용 - 해당 오행 강화');
    }

    return buffer.toString();
  }

  /// "진(辰)" → "辰" 한자 추출 헬퍼
  String _extractHanja(String value) {
    // 이미 한자 1글자면 그대로 반환
    if (value.length == 1) return value;

    // "진(辰)" 형태에서 괄호 안 한자 추출
    final match = RegExp(r'\(([^)]+)\)').firstMatch(value);
    if (match != null) {
      return match.group(1) ?? value;
    }

    // 한글-한자 매핑
    const korToHanja = {
      '자': '子', '축': '丑', '인': '寅', '묘': '卯',
      '진': '辰', '사': '巳', '오': '午', '미': '未',
      '신': '申', '유': '酉', '술': '戌', '해': '亥',
    };

    // 한글만 있는 경우 매핑
    final lower = value.toLowerCase();
    for (final entry in korToHanja.entries) {
      if (lower.contains(entry.key)) {
        return entry.value;
      }
    }

    return value;
  }

  /// 월운 + 일간 결합 분석 포맷팅
  String _formatMonthlyCombination() {
    final buffer = StringBuffer();
    final branchElement = _extractPureElement(_monthElement['branchElement']);
    final stemElement = _extractPureElement(_monthElement['stemElement']);

    buffer.writeln('### 일간과 월운의 결합 분석 (핵심!)');
    buffer.writeln();

    // 1. 일간 정보
    buffer.writeln('**1. 일간 정보**');
    buffer.writeln('- 일간: ${inputData.dayGan ?? "-"} (${inputData.dayGanDescription ?? "-"})');
    buffer.writeln('- 일간 오행: ${inputData.dayGanElementFull ?? "-"}');
    buffer.writeln();

    // 2. 월지지 오행의 영향 (주요 기운)
    if (branchElement != null) {
      final branchSipseong = inputData.getSipseongFor(branchElement);
      buffer.writeln('**2. 월지 ${_monthElement['branch']}(${_monthElement['branchElement']})의 영향 (주요 기운)**');
      buffer.writeln('- 십성: $branchSipseong');
      buffer.writeln('- 의미: ${inputData.getSipseongExplain(branchElement)}');
      buffer.writeln();
    }

    // 3. 월천간 오행의 영향 (보조 기운)
    if (stemElement != null) {
      final stemSipseong = inputData.getSipseongFor(stemElement);
      buffer.writeln('**3. 월천간 ${_monthElement['stem']}(${_monthElement['stemElement']})의 영향 (보조 기운)**');
      buffer.writeln('- 십성: $stemSipseong');
      buffer.writeln('- 의미: ${inputData.getSipseongExplain(stemElement)}');
      buffer.writeln();
    }

    // 4. 용신/기신과의 관계
    if (branchElement != null) {
      buffer.writeln('**4. 월운과 용신/기신의 관계**');
      buffer.writeln(inputData.getYongsinRelation(branchElement));
    }

    return buffer.toString();
  }

  /// 오행 문자열에서 순수 오행만 추출 (예: "금(金)" → "금")
  String? _extractPureElement(String? elementStr) {
    if (elementStr == null) return null;
    for (final e in ['목', '화', '토', '금', '수']) {
      if (elementStr.contains(e)) return e;
    }
    return null;
  }
}
