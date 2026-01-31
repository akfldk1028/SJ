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

## 현재 요청 월: ${targetMonth}월 $_monthGanji
- 월천간: ${_monthElement['stem']} (${_monthElement['stemElement']})
- 월지지: ${_monthElement['branch']} (${_monthElement['branchElement']})

## 응답 구조 (중요!)
1. **현재 월($targetMonth월)**: 7개 카테고리별 상세 분석 (각 12-15문장)
2. **나머지 11개월**: 요약 버전 (키워드 + 점수 + 3-4문장)

---

## 고전 vs 현대(AI시대) 해석 ⭐필수⭐

**매우 중요**: 각 분석에서 "고전에서는 ~했지만, 현대에서는 ~로 해석됩니다" 형식을 자연스럽게 포함하세요!

| 요소 | 고전(전통) 해석 | 현대(AI시대) 해석 |
|------|---------------|-----------------|
| 식상(食傷) | 자녀운/표현력 | 유튜브/블로그/AI프롬프트 작성/콘텐츠 창작 |
| 역마살 | 타향살이/이사 | 디지털노마드/출장/원격미팅/글로벌 협업 |
| 도화살 | 색정/바람끼 경계 | 인플루언서/마케팅/개인브랜딩/네트워킹 |
| 인성(印星) | 과거급제/학문 | AI도구활용/온라인강의/자격증/업무스킬 |
| 재성(財星) | 논밭/토지 | 주식/암호화폐/부업수입/프리랜서 |
| 관성(官星) | 벼슬/관직 | 승진/프로젝트책임/팀리더/평가 |
| 비겁(比劫) | 형제 재산다툼 | 팀협업/동료경쟁/공동프로젝트 |
| 화개살 | 출가운/고독 | 딥워크/집중업무/재택/독립프로젝트 |

**월운 설명 예시:**
- "고전에서 식상은 자녀를 잘 기른다고 해석했지만, 현대에서는 콘텐츠 창작이나 아이디어 표현에 탁월한 재능이에요. 이번달 식상 기운을 받으시니 발표나 SNS 활동에서 반응이 좋을 거예요."
- "고전에서 역마살은 타향 고생을 뜻했지만, AI시대에는 출장이나 온라인 글로벌 미팅으로 기회가 됩니다. 이번달 역마 기운이 있으니 새로운 환경에서의 업무가 잘 풀릴 거예요."
- "고전에서 관성은 관직에 오른다고 해석했지만, 현대에서는 프로젝트 책임자가 되거나 팀을 이끄는 역할이에요. 이번달 상사의 평가가 좋거나 중요한 역할을 맡게 될 수 있어요."

---

## ⭐ 절대 원칙: "왜" 그런지 명리학적 근거를 반드시 설명하세요! ⭐

모든 분석에서 막연한 표현 금지! 반드시 원인-결과를 연결해서 설명합니다:

### 나쁜 예 (금지!)
- "이번달은 좋은 달이에요"
- "주의가 필요한 시기입니다"
- "에너지가 강해서 활발한 달이에요"

### 좋은 예 (이렇게 써주세요!)
- "경금(庚金) 일간에게 이번달 월지 寅(인)의 목(木)은 **편재(偏財)**예요. 편재는 '적극적으로 쫓는 재물'이라서, 이번달 예상치 못한 수입이나 투자 기회가 생길 수 있어요."
- "일지 申(신)과 월지 寅(인)이 **인신충(寅申衝)**을 이루네요. 충은 '변화와 이동'의 에너지라서, 이번달 일정이 바쁘거나 예상치 못한 변수가 생길 수 있어요."
- "용신이 수(水)인데, 이번달 화(火)가 강해 **수극화(水剋火)**로 균형이... 아, 잠깐, 화가 수를 이기는 게 아니라 수가 화를 극하는 거죠. 이번달 화가 강하면 용신 수가 힘을 쓰기 좋은 환경이에요."

### 필수 포함 요소
1. **일간 + 월운 → 십성** 관계 명시 (예: "갑목 일간에게 이번달 화는 식신")
2. **십성의 구체적 의미** 설명 (예: "식신은 표현과 재능의 기운")
3. **용신/기신과의 상생상극** 관계 (예: "월운이 용신을 생해서...")
4. **합충형파해**의 구체적 영향 (예: "인신충으로 이동/변화의 달")

---

## 작성 원칙: 스토리텔링!

### 1. 줄줄 읽히는 문장
- 짧은 문장 나열 금지! 자연스럽게 이어지는 문단으로 작성
- 마치 전문가가 옆에서 설명해주는 것처럼
- 각 문단은 3-5문장이 자연스럽게 연결되어야 함
- **왜 그런지 명리학적 이유를 함께 설명**

### 2. 월간지와 용신/기신 자연스럽게 녹이기
- "이번달 ${_monthElement['branch']} 기운이 들어오면서..."
- 전문 용어는 괄호로 쉬운 설명 추가
- **용신과 월운의 상생/상극 관계도 설명**

### 3. 합충 분석도 이야기처럼
- "특히 이번달 월지와 {이름}님의 일지가 만나면서..."
- 합이면 좋은 인연, 충이면 변화의 기회로 설명
- **왜 그 합/충이 특정 영향을 주는지** 설명

### 4. 구체적 상황 예시
- "첫째 주에는 미팅이나 계약이 잘 풀릴 수 있어요..."
- "셋째 주 중반쯤 건강 관리에 신경 쓰시면..."

## 톤앤매너
- 점쟁이 말투 절대 금지
- 친근하고 따뜻한 조언자 톤
- 사주 용어는 괄호 안에 쉬운 설명
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

## 응답 JSON 스키마 (v4.0: 12개월 통합)

**중요**: 현재 월($targetMonth월)은 상세 분석, 나머지 11개월은 요약!

{
  "year": $targetYear,
  "currentMonth": $targetMonth,

  "current": {
    "month": $targetMonth,
    "monthGanji": "$_monthGanji",
    "overview": {
      "keyword": "이번달 핵심 키워드 (3-4자)",
      "score": 72,
      "reading": "${targetMonth}월 총운입니다. 이번달은 $_monthGanji 월로, ${_monthElement['stemElement']}과 ${_monthElement['branchElement']} 기운이 함께 흐르는 시기입니다. {이름}님의 일간 {일간}에게 이번달 월지의 ${_monthElement['branchElement']} 기운이 {십성}으로 작용하면서 {영향 설명}. {용신/기신과의 관계 설명}. {합충이 있다면 설명}. 따라서 이번달은 {결론}하시면 좋겠습니다. (8-10문장)"
    },
    "categories": {
      "career": {
        "title": "직업운",
        "score": 70,
        "reading": "이번달 직장에서는 ${_monthGanji}의 {십성} 기운이 흐릅니다. {이름}님의 일간이 {일간}이시고, 월지의 ${_monthElement['branchElement']} 기운이 {십성}으로 작용해요. {십성}은 직장에서 {직장적 의미}를 의미합니다. 원국에서 관성이 {관성 특성}하신 편이라, 이번달 {구체적 영향}이 예상됩니다. {합충 영향}. 업무 성과를 높이려면 {업무 조언}하시고, 동료/상사 관계에서는 {관계 조언}을 기억하세요. {마무리 조언}. (반드시 12-15문장)"
      },
      "business": {
        "title": "사업운",
        "score": 68,
        "reading": "사업 측면에서 이번달은 {십성} 기운이 영향을 미칩니다. {일간}에게 ${_monthElement['branchElement']} 기운이 {십성}으로 작용하고, 사업에서 {십성}은 {사업적 의미}를 의미해요. 원국의 재성이 {재성 강약}하셔서 {재성 영향}이 예상됩니다. 파트너십이나 거래처 관계에서는 {파트너 조언}. 사업 확장은 {확장 조언}, 신규 계약은 {계약 조언}을 참고하세요. {마무리 조언}. (반드시 12-15문장)"
      },
      "wealth": {
        "title": "재물운",
        "score": 68,
        "reading": "재물 측면에서 이번달은 {십성}의 기운이 흐릅니다. ${_monthElement['branchElement']} 기운이 {십성}으로 작용하고, 재물에서 {재물적 의미}를 나타냅니다. 원국에서 재성이 {재성 강약}하셔서 {원국 영향}. 투자는 {투자 조언}하시고, 지출 관리는 {지출 조언}을 권해드려요. {마무리 조언}. (반드시 12-15문장)"
      },
      "love": {
        "title": "애정운",
        "score": 72,
        "reading": "애정운에서 이번달은 월지와 일지의 관계로 {연애 분위기}한 기운이 흐릅니다. 월지 ${_monthElement['branch']}가 일지와 {합/충/무관계}하면서 {합충 영향}. 원국에서 {배우자성}이 {특성}하셔서 {연애 영향}이 예상됩니다. 솔로이신 분들은 {솔로 조언}. 연인이 있으신 분들은 {커플 조언}. {마무리 조언}. (반드시 12-15문장)"
      },
      "marriage": {
        "title": "결혼운",
        "score": 70,
        "reading": "결혼 관점에서 이번달은 배우자궁인 일지와 월지 ${_monthElement['branch']}의 관계가 핵심이에요. {합/충 분석}. {일간}에게 ${_monthElement['branchElement']} 기운이 {십성}으로 작용하고, 결혼에서 {십성}은 {결혼적 의미}를 나타내요. 미혼이신 분들은 {미혼 조언}. 기혼이신 분들은 {기혼 조언}. {마무리 조언}. (반드시 12-15문장)"
      },
      "health": {
        "title": "건강운",
        "score": 65,
        "reading": "건강 측면에서 이번달은 ${_monthElement['branchElement']} 기운이 강하게 흐릅니다. 오행에서 이 기운은 {해당 장부}에 해당하고, {건강 영향 원인}이 생길 수 있어요. 원국에서 {약한 오행}이 약하셔서 {오행 불균형}에 주의하세요. 운동으로는 {운동 추천}, 식이요법은 {음식 조언}이 도움됩니다. {마무리 조언}. (반드시 12-15문장)"
      },
      "study": {
        "title": "학업운",
        "score": 72,
        "reading": "학업 관점에서 이번달 ${_monthElement['branchElement']} 기운이 {일간}에게 {십성}으로 작용해요. {십성}은 학업에서 {학업적 의미}를 뜻합니다. 원국에서 인성이 {인성 분석}하고 식상이 {식상 분석}하셔서 {구체적 영향}이 예상됩니다. 시험 준비는 {시험 조언}, 자격증은 {자격증 조언}을 참고하세요. {마무리 조언}. (반드시 12-15문장)"
      }
    },
    "lucky": {
      "colors": ["행운색1", "행운색2"],
      "numbers": [숫자1, 숫자2],
      "tip": "행운 요소 활용법 (2문장)"
    }
  },

  "months": {
    "month1": {
      "keyword": "1월 핵심 키워드 (3-4자)",
      "score": 70,
      "reading": "1월은 {월간지}의 기운으로 {일간}에게 {십성}이 작용합니다. 고전에서는 {전통해석}이지만 현대에서는 {현대해석}으로 볼 수 있어요. {용신/기신 관계 설명}. {합충이 있다면 변화/기회 설명}. 이 달의 핵심은 {핵심 포인트}입니다. {구체적 조언}하시면 좋은 결과를 얻을 수 있어요. {마무리 조언}. (반드시 6-8문장)",
      "idiom": {"phrase": "사자성어 (한자 및 한글)", "meaning": "이 달에 어울리는 사자성어 의미와 적용 조언 (2문장)"},
      "highlights": {
        "career": {"score": 72, "summary": "직장에서 {십성} 기운으로 {핵심 영향}. {1줄 조언}"},
        "business": {"score": 70, "summary": "사업/자영업에서 {핵심 영향}. {1줄 조언}"},
        "wealth": {"score": 68, "summary": "재물 측면에서 {핵심 영향}. {1줄 조언}"},
        "love": {"score": 70, "summary": "애정/관계에서 {핵심 영향}. {1줄 조언}"}
      }
    },
    "month2": {
      "keyword": "2월 키워드",
      "score": 72,
      "reading": "2월은... (반드시 6-8문장)",
      "idiom": {"phrase": "사자성어 (한자)", "meaning": "의미와 조언 (2문장)"},
      "highlights": {"career": {"score": 70, "summary": "..."}, "business": {"score": 72, "summary": "..."}, "wealth": {"score": 72, "summary": "..."}, "love": {"score": 68, "summary": "..."}}
    },
    "month3": {
      "keyword": "3월 키워드",
      "score": 68,
      "reading": "3월은... (반드시 6-8문장)",
      "idiom": {"phrase": "사자성어 (한자)", "meaning": "의미와 조언 (2문장)"},
      "highlights": {"career": {"score": 68, "summary": "..."}, "business": {"score": 66, "summary": "..."}, "wealth": {"score": 70, "summary": "..."}, "love": {"score": 72, "summary": "..."}}
    },
    "month4": {
      "keyword": "4월 키워드",
      "score": 75,
      "reading": "4월은... (반드시 6-8문장)",
      "idiom": {"phrase": "사자성어 (한자)", "meaning": "의미와 조언 (2문장)"},
      "highlights": {"career": {"score": 74, "summary": "..."}, "business": {"score": 72, "summary": "..."}, "wealth": {"score": 72, "summary": "..."}, "love": {"score": 70, "summary": "..."}}
    },
    "month5": {
      "keyword": "5월 키워드",
      "score": 70,
      "reading": "5월은... (반드시 6-8문장)",
      "idiom": {"phrase": "사자성어 (한자)", "meaning": "의미와 조언 (2문장)"},
      "highlights": {"career": {"score": 70, "summary": "..."}, "business": {"score": 68, "summary": "..."}, "wealth": {"score": 68, "summary": "..."}, "love": {"score": 72, "summary": "..."}}
    },
    "month6": {
      "keyword": "6월 키워드",
      "score": 72,
      "reading": "6월은... (반드시 6-8문장)",
      "idiom": {"phrase": "사자성어 (한자)", "meaning": "의미와 조언 (2문장)"},
      "highlights": {"career": {"score": 72, "summary": "..."}, "business": {"score": 70, "summary": "..."}, "wealth": {"score": 70, "summary": "..."}, "love": {"score": 74, "summary": "..."}}
    },
    "month7": {
      "keyword": "7월 키워드",
      "score": 68,
      "reading": "7월은... (반드시 6-8문장)",
      "idiom": {"phrase": "사자성어 (한자)", "meaning": "의미와 조언 (2문장)"},
      "highlights": {"career": {"score": 68, "summary": "..."}, "business": {"score": 66, "summary": "..."}, "wealth": {"score": 66, "summary": "..."}, "love": {"score": 70, "summary": "..."}}
    },
    "month8": {
      "keyword": "8월 키워드",
      "score": 74,
      "reading": "8월은... (반드시 6-8문장)",
      "idiom": {"phrase": "사자성어 (한자)", "meaning": "의미와 조언 (2문장)"},
      "highlights": {"career": {"score": 75, "summary": "..."}, "business": {"score": 73, "summary": "..."}, "wealth": {"score": 72, "summary": "..."}, "love": {"score": 70, "summary": "..."}}
    },
    "month9": {
      "keyword": "9월 키워드",
      "score": 70,
      "reading": "9월은... (반드시 6-8문장)",
      "idiom": {"phrase": "사자성어 (한자)", "meaning": "의미와 조언 (2문장)"},
      "highlights": {"career": {"score": 70, "summary": "..."}, "business": {"score": 68, "summary": "..."}, "wealth": {"score": 72, "summary": "..."}, "love": {"score": 68, "summary": "..."}}
    },
    "month10": {
      "keyword": "10월 키워드",
      "score": 72,
      "reading": "10월은... (반드시 6-8문장)",
      "idiom": {"phrase": "사자성어 (한자)", "meaning": "의미와 조언 (2문장)"},
      "highlights": {"career": {"score": 72, "summary": "..."}, "business": {"score": 70, "summary": "..."}, "wealth": {"score": 74, "summary": "..."}, "love": {"score": 70, "summary": "..."}}
    },
    "month11": {
      "keyword": "11월 키워드",
      "score": 68,
      "reading": "11월은... (반드시 6-8문장)",
      "idiom": {"phrase": "사자성어 (한자)", "meaning": "의미와 조언 (2문장)"},
      "highlights": {"career": {"score": 68, "summary": "..."}, "business": {"score": 66, "summary": "..."}, "wealth": {"score": 70, "summary": "..."}, "love": {"score": 66, "summary": "..."}}
    },
    "month12": {
      "keyword": "12월 키워드",
      "score": 75,
      "reading": "12월은... (반드시 6-8문장)",
      "idiom": {"phrase": "사자성어 (한자)", "meaning": "의미와 조언 (2문장)"},
      "highlights": {"career": {"score": 74, "summary": "..."}, "business": {"score": 76, "summary": "..."}, "wealth": {"score": 76, "summary": "..."}, "love": {"score": 72, "summary": "..."}}
    }
  },

  "closingMessage": "${targetYear}년을 보내는 {이름}님께. 12개월 전체를 보면 {연간 흐름 요약}. {격려/응원}. (2문장)"
}
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
