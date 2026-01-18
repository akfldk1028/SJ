/// # 2026 신년운세 프롬프트 (v5.0 - 명리학 심화)
///
/// ## 개요
/// saju_base(평생운세) + saju_analyses(원국 데이터)를 기반으로
/// 2026년 병오(丙午)년 신년운세 분석
///
/// ## 파일 위치
/// `frontend/lib/AI/fortune/yearly_2026/yearly_2026_prompt.dart`
///
/// ## v5.0 개선사항 (명리학 심화 + 쉬운 설명)
/// - 오행, 십성, 신살, 합충형해파 쉬운 설명 포함
/// - 7개 카테고리 (직장/사업/재물/연애/결혼/학업/건강)
/// - 각 카테고리별 6-8문장 상세 분석
/// - 전문용어는 쉽게 풀어서 설명
///
/// ## 모델
/// GPT-5-mini - 비용 효율적 모델
/// - 입력: $0.25/1M tokens, 출력: $2.00/1M tokens
/// - 프롬프트 강화로 6-8문장 상세 응답 유도

import '../../core/ai_constants.dart';
import '../../prompts/prompt_template.dart';
import '../common/fortune_input_data.dart';

/// 2026 신년운세 프롬프트 템플릿
class Yearly2026Prompt extends PromptTemplate {
  /// 입력 데이터 (saju_base + saju_analyses 포함)
  final FortuneInputData inputData;

  const Yearly2026Prompt({
    required this.inputData,
  });

  @override
  String get summaryType => SummaryType.yearlyFortune2026;

  @override
  String get modelName => OpenAIModels.gpt5Mini; // gpt-5-mini (비용 효율적)

  @override
  int get maxTokens => 10000; // v5: 7개 카테고리 상세 응답용

  @override
  double get temperature => 0.7;

  @override
  Duration? get cacheExpiry => CacheExpiry.yearlyFortune2026;

  @override
  String get systemPrompt => '''
당신은 30년 경력의 사주명리학 전문가이자 스토리텔러입니다.
사용자의 원국(사주 팔자)을 바탕으로 2026년 병오(丙午)년 신년운세를 **깊이 있고 읽는 재미가 있게** 작성합니다.

---

# 2026년 병오(丙午)년, 어떤 해인가요?

## 한마디로: "붉은 말의 해"

2026년은 병오(丙午)년입니다.
- **병(丙)**: 하늘의 태양처럼 밝고 뜨거운 불
- **오(午)**: 말띠, 한낮 정오의 가장 강렬한 기운
- 천간과 지지 모두 '불(火)'이라 에너지가 매우 강한 해예요.

## 납음(納音): 천하수(天河水)

납음은 그 해의 '숨은 성질'이에요.
2026년의 납음은 '천하수', 쉽게 말해 **은하수**입니다.
"불 기운이 이렇게 강한데 왜 물이지?" 싶으시죠?
이건 **"뜨거운 것이 극에 달하면 시원한 비가 내린다"**는 자연의 이치를 담고 있어요.

## 십이운성: 제왕(帝王)

병오는 '제왕'에 해당해요. 쉽게 말해 **"에너지가 최고조에 달한 상태"**입니다.
적극적으로 움직이면 큰 성과를 낼 수 있지만, 너무 과하면 탈이 날 수 있어요.

## 신살: 도화(桃花)

오(午)는 도화의 기운을 품고 있어요. 도화는 **'매력과 인연의 기운'**입니다.
- 이성에게 관심받는 일이 많아져요
- 인기가 올라가고 사람들이 모여들어요
- 다만 과하면 이성 문제나 구설에 주의

---

# 오행(五行) 쉽게 보기

세상 만물을 5가지로 분류한 거예요:
- **목(木)**: 나무, 봄, 성장, 간/담
- **화(火)**: 불, 여름, 활발, 심장/소장
- **토(土)**: 흙, 환절기, 중재, 위장/비장
- **금(金)**: 쇠, 가을, 결실, 폐/대장
- **수(水)**: 물, 겨울, 저장, 신장/방광

## 상생(서로 도와주는 관계)
- 목 → 화: 나무가 불을 키움
- 화 → 토: 불이 타면 재(흙)가 됨
- 토 → 금: 흙에서 금속이 나옴
- 금 → 수: 금속에서 물이 맺힘
- 수 → 목: 물이 나무를 키움

## 상극(서로 제어하는 관계)
- 목 → 토: 나무가 흙을 뚫음
- 화 → 금: 불이 금속을 녹임
- 토 → 수: 흙이 물을 막음
- 금 → 목: 도끼가 나무를 자름
- 수 → 화: 물이 불을 끔

---

# 십성(十星) 쉽게 보기

나(일간)와 다른 글자들의 관계를 10가지로 표현해요:

| 십성 | 쉬운 의미 |
|------|----------|
| 비견/겁재 | 나와 같은 기운, 형제/경쟁자 |
| 식신/상관 | 내가 표현하는 기운, 재능/창작 |
| 정재/편재 | 내가 다스리는 기운, 재물/돈 |
| 정관/편관 | 나를 다스리는 기운, 직장/권위 |
| 정인/편인 | 나를 낳아주는 기운, 학습/보호 |

## 2026년 불 기운이 '나'에게 미치는 영향

### 목(木) 일간 - 갑(甲), 을(乙)
- 화 = **식상** (표현의 기운)
- 당신의 재능과 아이디어가 세상에 표현되는 해!
- 창작활동, 발표, SNS에서 빛날 수 있어요
- 주의: 너무 많이 쏟아내면 에너지 소진

### 화(火) 일간 - 병(丙), 정(丁)
- 화 = **비겁** (같은 기운)
- 에너지가 넘치고 경쟁이 치열해지는 해
- 열정은 좋지만 충돌/번아웃 조심

### 토(土) 일간 - 무(戊), 기(己)
- 화 = **인성** (보호의 기운)
- 배움, 자격증, 귀인의 도움 받는 해
- 좋은 멘토를 만날 수 있어요

### 금(金) 일간 - 경(庚), 신(辛)
- 화 = **관살** (직장/압박의 기운)
- 힘들지만 성장하는 시기
- 스트레스 관리 필수

### 수(水) 일간 - 임(壬), 계(癸)
- 화 = **재성** (재물의 기운)
- 재물 기회가 많지만 쓸 곳도 많은 해
- 과욕 금물, 균형이 중요

---

# 합충형해파(合沖刑害破) 쉽게 보기

지지(띠) 사이의 관계예요:

## 합(合) - 어울림, 협력, 인연
- **육합**: 두 글자가 짝꿍처럼 만남 (예: 오미합)
- **삼합**: 세 글자가 팀을 이룸 (예: 인오술 삼합)
- 쉽게: "손잡고 협력하는 것"

## 충(沖) - 충돌, 갈등, 변화
- 자오충, 축미충, 인신충 등
- 쉽게: "정면으로 부딪히는 것"
- 꼭 나쁜 건 아님! 변화의 계기가 될 수도

## 해(害) - 방해, 훼방
- 축오해, 자미해 등
- 쉽게: "합을 방해하는 관계, 은근히 걸림돌"

---

# 주요 신살 쉽게 보기

| 신살 | 쉬운 의미 | 좋은 면 | 주의할 면 |
|------|----------|---------|----------|
| 도화살 | 매력의 기운 | 인기, 예술 | 이성 문제 |
| 역마살 | 이동의 기운 | 해외, 여행 | 불안정 |
| 화개살 | 영적 기운 | 깊은 사색 | 고독 |
| 천을귀인 | 귀인의 기운 | 위기에서 도움 | - |

---

# 작성 원칙 (매우 중요!)

## 1. 풍부하고 상세한 분석
- **모든 영역을 각각 6-8문장으로 상세히 작성**
- 위에서 설명한 오행, 십성, 합충, 신살을 자연스럽게 녹여서 설명
- 단, 어려운 용어는 쉬운 말로 풀어서!

## 2. 7개 영역별 특화 분석
- 직장운: 승진, 이직, 동료, 성과
- 사업운: 창업, 확장, 파트너십
- 재물운: 수입, 투자, 지출
- 연애운: 만남, 썸, 고백
- 결혼운: 결혼 적기, 배우자, 결혼생활
- 학업운: 시험, 자격증, 진학
- 건강운: 주의 부위, 예방법

## 3. 톤앤매너
- **점쟁이 말투 절대 금지** ("~하오", "~리라" X)
- 친근하고 따뜻하게 ("~해요", "~입니다")
- 전문적이면서도 쉽게 풀어서 설명
- 긍정/부정 균형, 현실적 조언

## 응답 형식
반드시 JSON 형식으로 응답하세요.
''';

  @override
  String buildUserPrompt() {
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
## ⭐ 2026년 병오(丙午)와 나의 오행 결합 분석 ⭐
${inputData.getSeunCombinationAnalysis('화', '병오(丙午)')}
---

## 합충형파해
${_formatHapchung()}

## 현재 대운/세운
${_formatDaeunSeun()}

## 평생 사주 분석 (saju_base)
${_formatSajuBase()}

## 분석 요청

위 원국 정보와 **"2026년 병오와 나의 오행 결합 분석"**을 바탕으로 2026년 신년운세를 분석해주세요.

**⭐ 핵심: 일간(${inputData.dayGan ?? '?'}) + 세운(화) = ${inputData.getSipseongFor('화') ?? '?'} 관계를 중심으로 분석!**

**분석 시 반드시 포함할 요소:**
1. **십성 중심 분석**: ${inputData.dayGanElement ?? '일간'}일간에게 화(火)가 **${inputData.getSipseongFor('화') ?? '십성'}**이므로, 이것이 각 영역에 어떤 영향을 미치는지
2. **용신/기신 연결**: ${inputData.yongsinElement != null ? '용신 ${inputData.yongsinElement}과' : '용신과'} 2026년 화(火) 기운의 관계
3. **합충형해파**: 원국 지지${inputData.dayJi != null ? '(특히 일지 ${inputData.dayJi})' : ''}와 午(오)의 관계
4. **신살**: 도화살, 역마살 등 해당되는 신살

**⚠️ 매우 중요: 7개 영역 모두 각각 6-8문장으로 풍부하게!**
- 1-2문장 짧은 응답 절대 금지
- **십성(${inputData.getSipseongFor('화') ?? '?'})이 각 영역에 어떤 의미인지** 자연스럽게 녹여서 설명
- 구체적인 상황, 시기, 조언을 포함한 상세한 문단

## 응답 JSON 스키마

{
  "year": 2026,
  "yearGanji": "병오(丙午)",

  "yearInfo": {
    "alias": "붉은 말의 해",
    "napeum": "천하수(天河水) - 은하수",
    "napeumExplain": "뜨거운 열기가 극에 달하면 시원한 비가 내려요",
    "twelveUnsung": "제왕(帝王)",
    "unsungExplain": "에너지가 정점에 달한 상태예요",
    "mainSinsal": "도화(桃花)",
    "sinsalExplain": "매력과 인연의 기운이 강해지는 해예요"
  },

  "personalAnalysis": {
    "ilgan": "일간 오행과 쉬운 설명",
    "ilganExplain": "일간의 성격 특성 (쉽게)",
    "fireEffect": "화(火)가 이 일간에게 어떤 십성인지, 어떤 영향인지",
    "yongshinMatch": "용신과 올해 세운의 궁합 설명",
    "hapchungEffect": "원국과 세운 午의 합충 관계 설명",
    "sinsalEffect": "해당되는 신살과 그 영향"
  },

  "overview": {
    "keyword": "올해를 한마디로",
    "score": 75,
    "summary": "2026년 전체 흐름 요약 (5-6문장, 오행/십성/합충/신살 자연스럽게 녹여서)",
    "keyPoint": "올해 가장 중요한 포인트 (2-3문장)"
  },

  "categories": {
    "career": {
      "title": "직장운",
      "icon": "💼",
      "score": 75,
      "summary": "직장운 한줄 요약",
      "reading": "직장인 관점에서 올해는... 승진 가능성은... 이직을 고려한다면... 동료/상사와의 관계는... 업무 성과는... 주의할 점은... (반드시 6-8문장! 십성/합충 자연스럽게 녹여서!)",
      "bestMonths": [3, 8, 10],
      "cautionMonths": [5, 6],
      "actionTip": "구체적 행동 조언"
    },
    "business": {
      "title": "사업운",
      "icon": "🏢",
      "score": 72,
      "summary": "사업운 한줄 요약",
      "reading": "사업가/자영업자 관점에서 올해는... 매출 흐름은... 사업 확장은... 파트너십/협업은... 투자 유치는... 주의할 점은... (반드시 6-8문장!)",
      "bestMonths": [3, 9, 11],
      "cautionMonths": [5, 6],
      "actionTip": "구체적 행동 조언"
    },
    "wealth": {
      "title": "재물운",
      "icon": "💰",
      "score": 70,
      "summary": "재물운 한줄 요약",
      "reading": "금전적으로 올해는... 수입 흐름은... 투자 관점에서는... 지출 관리는... 재테크 방향은... 주의할 점은... (반드시 6-8문장! 재성과의 관계 설명!)",
      "bestMonths": [8, 9, 11],
      "cautionMonths": [5, 12],
      "actionTip": "구체적 행동 조언"
    },
    "love": {
      "title": "연애운",
      "icon": "💕",
      "score": 78,
      "summary": "연애운 한줄 요약",
      "reading": "연애 관점에서 올해는 도화 기운으로... 새로운 만남은... 썸/고백 타이밍은... 현재 연애 중이라면... 이별 위기가 있다면... 주의할 점은... (반드시 6-8문장! 도화살 영향 강조!)",
      "bestMonths": [3, 7, 10],
      "cautionMonths": [5, 6],
      "actionTip": "구체적 행동 조언"
    },
    "marriage": {
      "title": "결혼운",
      "icon": "💍",
      "score": 70,
      "summary": "결혼운 한줄 요약",
      "reading": "결혼 관점에서 올해는... 결혼 적기인지... 배우자를 만날 운은... 이미 기혼이라면 부부관계는... 결혼 준비 중이라면... 주의할 점은... (반드시 6-8문장!)",
      "bestMonths": [3, 10, 11],
      "cautionMonths": [5, 6],
      "actionTip": "구체적 행동 조언"
    },
    "study": {
      "title": "학업운",
      "icon": "📚",
      "score": 75,
      "summary": "학업운 한줄 요약",
      "reading": "학업/시험 관점에서 올해는... 집중력과 암기력은... 시험운/합격운은... 자격증 도전은... 진학/유학을 고려한다면... 주의할 점은... (반드시 6-8문장! 인성/식상 영향 설명!)",
      "bestMonths": [2, 3, 9],
      "cautionMonths": [5, 6, 7],
      "actionTip": "구체적 행동 조언"
    },
    "health": {
      "title": "건강운",
      "icon": "🏥",
      "score": 68,
      "summary": "건강운 한줄 요약",
      "reading": "건강 측면에서 올해는 불 기운이 강해서... 특히 주의할 신체 부위는... 정신건강/스트레스는... 추천 운동은... 식이요법은... 생활습관 조언은... (반드시 6-8문장! 오행과 장부 연결!)",
      "focusAreas": ["심장/혈압", "눈", "소화기"],
      "cautionMonths": [5, 6, 7],
      "actionTip": "구체적 행동 조언"
    }
  },

  "timeline": {
    "q1": { "period": "1-3월", "theme": "테마", "score": 75, "reading": "1분기 흐름 (3-4문장)" },
    "q2": { "period": "4-6월", "theme": "테마", "score": 60, "reading": "2분기 흐름 - 화 기운 최강 시기 (3-4문장)" },
    "q3": { "period": "7-9월", "theme": "테마", "score": 78, "reading": "3분기 흐름 (3-4문장)" },
    "q4": { "period": "10-12월", "theme": "테마", "score": 80, "reading": "4분기 흐름 (3-4문장)" }
  },

  "lucky": {
    "colors": ["빨강", "보라", "주황"],
    "numbers": [3, 7, 9],
    "direction": "남쪽",
    "items": ["붉은색 소품", "삼각형 패턴"]
  },

  "closing": {
    "yearMessage": "2026년 핵심 메시지 (2-3문장)",
    "finalAdvice": "따뜻한 마무리 인사 (2-3문장)"
  }
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

    return buffer.toString();
  }

  /// 합충형파해 정보 포맷팅
  String _formatHapchung() {
    final hapchung = inputData.hapchung;
    if (hapchung == null) return '(합충형파해 정보 없음)';

    final buffer = StringBuffer();

    if (hapchung['cheongan_hapchung'] != null) {
      buffer.writeln('- 천간 합충: ${hapchung['cheongan_hapchung']}');
    }

    if (hapchung['jiji_hapchung'] != null) {
      buffer.writeln('- 지지 합충형파해: ${hapchung['jiji_hapchung']}');
    }

    // 2026년 午(오)와의 관계 힌트 추가
    final dayJi = inputData.dayJi;
    if (dayJi != null) {
      buffer.writeln('\n** 2026년 午(오)와의 관계 분석 필요:');
      if (dayJi == '子') {
        buffer.writeln('- 일지 子와 세운 午: 子午衝(자오충) 발생 가능');
      } else if (dayJi == '寅' || dayJi == '戌') {
        buffer.writeln('- 일지 $dayJi와 세운 午: 寅午戌 삼합(火局) 가능');
      } else if (dayJi == '未') {
        buffer.writeln('- 일지 未와 세운 午: 午未合(오미합) 가능');
      }
    }

    return buffer.toString();
  }

  /// 대운/세운 정보 포맷팅
  String _formatDaeunSeun() {
    final buffer = StringBuffer();

    final daeun = inputData.daeun;
    if (daeun != null) {
      buffer.writeln('### 현재 대운');
      if (daeun['current'] != null) {
        buffer.writeln('- 현재: ${daeun['current']}');
      }
      if (daeun['upcoming'] != null) {
        buffer.writeln('- 다음 대운: ${daeun['upcoming']}');
      }
    } else {
      buffer.writeln('### 현재 대운');
      buffer.writeln('(대운 정보 없음)');
    }

    final seun = inputData.currentSeun;
    if (seun != null) {
      buffer.writeln('\n### 현재 세운');
      buffer.writeln('- ${seun['year']}년: ${seun['ganji'] ?? ''}');
    }

    return buffer.toString();
  }
}
