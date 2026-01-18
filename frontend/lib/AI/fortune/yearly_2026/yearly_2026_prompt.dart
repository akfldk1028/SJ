/// # 2026 신년운세 프롬프트 (v3.0 - 스토리텔링)
///
/// ## 개요
/// saju_base(평생운세) + saju_analyses(원국 데이터)를 기반으로
/// 2026년 병오(丙午)년 신년운세 분석
///
/// ## 파일 위치
/// `frontend/lib/AI/fortune/yearly_2026/yearly_2026_prompt.dart`
///
/// ## v3.0 개선사항 (스토리텔링 구조)
/// - 총운을 4단계 스토리텔링으로 (opening → yearEnergy → yourFortune → conclusion)
/// - 카테고리별 운세도 자연스럽게 이어지는 문단 형태
/// - 읽는 순서대로 JSON 구조 재배치
/// - "줄줄 읽히는" UX 최적화
///
/// ## 모델
/// GPT-5-mini - 비용 효율적 모델
/// - 입력: $0.25/1M tokens, 출력: $2.00/1M tokens
/// - 프롬프트 강화로 5-7문장 상세 응답 유도

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
  int get maxTokens => 8192; // 스토리텔링 상세 응답용

  @override
  double get temperature => 0.7;

  @override
  Duration? get cacheExpiry => CacheExpiry.yearlyFortune2026;

  @override
  String get systemPrompt => '''
당신은 30년 경력의 사주명리학 전문가이자 스토리텔러입니다.
사용자의 원국(사주 팔자)과 평생운세 분석을 바탕으로 2026년 병오(丙午)년 신년운세를 **읽는 재미가 있게** 작성합니다.

## 2026년 병오(丙午)년 특성
- 천간 병(丙): 태양의 불, 양화(陽火), 밝음/열정/활동성
- 지지 오(午): 말띠, 정오, 극양, 화(火)의 극점
- 세운 오행: 화(火) 에너지가 매우 강한 해

## 작성 원칙: 스토리텔링!

### 1. 줄줄 읽히는 문장 (매우 중요!)
- **1-2문장 응답 절대 금지!** 반드시 최소 5문장 이상
- 짧은 문장 나열 금지! 자연스럽게 이어지는 문단으로 작성
- 마치 전문가가 옆에서 설명해주는 것처럼
- **각 문단은 반드시 5-7문장이 자연스럽게 연결되어야 함**
- reading 필드는 5-7문장으로 상세하게 작성 (짧으면 안 됨!)

### 2. 용신/기신 기반 분석
- 용신이 화(火)면 좋은 해 → 점수 85-95점
- 기신이 화(火)면 조심할 해 → 점수 55-65점
- 용신이 수(水)면 화극수(火克水)로 힘든 해 → 점수 50-60점

### 3. 합충형파해 자연스럽게 녹이기
- "올해 午(오)가 들어오면서 당신의 일지 子와 충돌하게 되는데요..."
- 전문 용어는 괄호로 쉬운 설명 추가

### 4. 구체적 상황 예시
- "3월쯤 새로운 프로젝트 제안이 들어올 수 있는데..."
- "연말에는 이직 기회가 찾아올 수 있어요..."

## 톤앤매너
- 점쟁이 말투 절대 금지 (예: "~할 팔자로다")
- 친근하고 따뜻한 조언자 톤
- 사주 용어는 괄호 안에 쉬운 설명
- 긍정/부정 균형, 현실적 조언

## 응답 형식
반드시 아래 JSON 형식으로 응답하세요. 각 필드의 문장들이 자연스럽게 이어지도록!
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

## 합충형파해
${_formatHapchung()}

## 현재 대운/세운
${_formatDaeunSeun()}

## 평생 사주 분석 (saju_base)
${_formatSajuBase()}

## 분석 요청

위 원국 정보와 평생운세를 바탕으로 2026년 병오(丙午)년 신년운세를 분석해주세요.

**스토리텔링으로 작성해주세요:**
- 각 섹션이 자연스럽게 이어지는 문단으로
- ${inputData.yongsinElement != null ? '용신 ${inputData.yongsinElement}과' : '용신과'} 2026년 화(火) 기운의 상호작용을 자연스럽게 녹여서
- 원국 지지${inputData.dayJi != null ? '(특히 일지 ${inputData.dayJi})' : ''}와 午(오)의 관계를 이야기하듯이

**⚠️ 중요: 각 reading 필드는 반드시 5-7문장으로 상세하게 작성!**
- 1-2문장 짧은 응답 금지
- 구체적인 상황, 시기, 조언을 포함한 상세한 문단
- 마치 옆에서 조언해주는 것처럼 자연스럽게

## 응답 JSON 스키마 (읽는 순서대로!)

{
  "year": 2026,
  "yearGanji": "병오(丙午)",

  "overview": {
    "keyword": "올해를 한마디로 표현 (예: 도약의 해, 내실을 다지는 해)",
    "score": 75,
    "opening": "2026년 병오년이 밝았습니다. 올해는 태양의 불꽃처럼 뜨겁고 강렬한 화(火) 기운이 가득한 해인데요. 천간의 병(丙)은 태양을, 지지의 오(午)는 한낮의 정점을 상징하니, 그야말로 불 기운이 최고조에 달하는 한 해가 펼쳐집니다. (3-4문장으로 올해의 기운을 소개)",
    "yearEnergy": "이렇게 강한 화 기운은 열정과 활동성을 높여주지만, 동시에 조급함이나 충동적인 결정을 불러올 수 있어요. 특히 상반기에는 뜨거운 에너지가 극대화되어 무언가를 시작하고 싶은 욕구가 강해지실 텐데요. 하지만 불이 너무 세면 자칫 타버릴 수 있듯이, 이 에너지를 어떻게 조절하느냐가 올해의 관건이 됩니다. (3-4문장으로 올해 기운의 영향 설명)",
    "yourFortune": "{이름}님의 사주를 보면, 용신이 {용신}이시라 올해 화 기운과 {상생/상극} 관계에 놓이게 됩니다. 이는 {구체적 영향}을 의미하는데요. 일지 {일지}와 올해 午가 만나면서 {합충 관계}이 형성되어, {그 의미}하는 한 해가 되겠습니다. (4-5문장으로 본인 사주와 연결하여 개인화된 분석)",
    "conclusion": "따라서 2026년은 {핵심 메시지}하는 것이 중요합니다. {구체적 조언}하시면서 올 한 해를 보내신다면, {기대 결과}하실 수 있을 거예요. (2-3문장으로 총운 마무리)"
  },

  "career": {
    "title": "직업운",
    "score": 75,
    "reading": "올해 직장에서는 {상황 분석}합니다. {이름}님의 사주에서 관성(官星, 직장/명예를 나타내는 기운)이 {분석}하고 있어서, {구체적 영향}이 예상되는데요. 특히 {좋은 시기}에는 {기회}가 찾아올 수 있으니 미리 준비해두시면 좋겠습니다. 다만 {주의 시기}에는 {주의사항}이 있을 수 있으니 {대처법}하시는 게 좋아요. 이직이나 새로운 도전을 고려하신다면 {조언}하시는 것을 추천드립니다. (5-7문장이 자연스럽게 이어지는 문단)",
    "bestMonths": [3, 8],
    "cautionMonths": [5, 6]
  },

  "wealth": {
    "title": "재물운",
    "score": 70,
    "reading": "재물 측면에서 올해는 {상황 분석}한 흐름이 예상됩니다. {이름}님은 평소 {재물 패턴}하시는 편인데, 올해 화 기운이 {영향}하면서 {구체적 변화}가 생길 수 있어요. {좋은 시기}에는 {기회}가 있을 수 있고, {주의 시기}에는 {주의사항}이 필요합니다. 투자나 큰 지출을 계획하고 계신다면 {조언}하시는 것이 현명하겠습니다. 특히 {구체적 팁}을 염두에 두시면 올 한 해 재물운을 잘 활용하실 수 있을 거예요. (5-7문장이 자연스럽게 이어지는 문단)",
    "bestMonths": [8, 9],
    "cautionMonths": [5]
  },

  "love": {
    "title": "애정운",
    "score": 72,
    "reading": "애정 운에서 올해는 {상황 분석}한 기운이 흐릅니다. {이름}님의 연애 스타일을 보면 {특성}하신 편인데, 올해 화 기운이 {영향}하면서 {변화}가 생길 수 있어요. 솔로이신 분들은 {솔로 조언}하시면 좋겠고, 연인이 있으신 분들은 {커플 조언}에 신경 쓰시면 관계가 더 깊어질 수 있습니다. 특히 {좋은 시기}에 {기회}가 있을 수 있으니 마음을 열어두세요. 다만 {주의 시기}에는 {주의사항}이 있을 수 있어 {대처법}하시는 게 좋겠습니다. (5-7문장이 자연스럽게 이어지는 문단)",
    "bestMonths": [3, 10],
    "cautionMonths": [5, 6]
  },

  "health": {
    "title": "건강운",
    "score": 68,
    "reading": "건강 측면에서 올해는 화(火) 기운이 강하니 {관련 장기}에 주의가 필요합니다. 화는 심장과 소장, 혈액순환과 관련이 있어서 {구체적 증상}이 나타날 수 있어요. {이름}님의 사주에서 {분석}하기 때문에, 평소보다 {주의사항}에 신경 쓰시면 좋겠습니다. 특히 {주의 시기}에는 {구체적 조언}하시고, {예방법}을 실천하시면 건강하게 한 해를 보내실 수 있을 거예요. 무리한 일정보다는 {라이프스타일 조언}하시는 것을 추천드립니다. (5-7문장이 자연스럽게 이어지는 문단)",
    "focusAreas": ["심장/혈압", "눈 건강"],
    "cautionMonths": [5, 6, 7]
  },

  "timeline": {
    "q1": {
      "period": "1-3월",
      "theme": "테마 키워드",
      "reading": "새해가 시작되는 1월부터 3월까지는 {분석}한 시기입니다. {상세 설명}하면서 {조언}하시면 좋겠습니다. (2-3문장)"
    },
    "q2": {
      "period": "4-6월",
      "theme": "테마 키워드",
      "reading": "4월부터 6월은 올해 화 기운이 가장 강해지는 시기입니다. 특히 5월 갑오(甲午)월에는 {분석}하니 {조언}이 필요합니다. (2-3문장)"
    },
    "q3": {
      "period": "7-9월",
      "theme": "테마 키워드",
      "reading": "하반기로 접어드는 7-9월에는 {분석}한 기운이 흐릅니다. {상세 설명}하면서 {조언}해보세요. (2-3문장)"
    },
    "q4": {
      "period": "10-12월",
      "theme": "테마 키워드",
      "reading": "한 해를 마무리하는 10-12월에는 {분석}합니다. {상세 설명}하면서 2027년을 준비하시면 좋겠습니다. (2-3문장)"
    }
  },

  "lucky": {
    "colors": ["행운색1", "행운색2"],
    "numbers": [행운숫자1, 행운숫자2],
    "direction": "좋은 방향",
    "tip": "행운 요소 활용법을 자연스럽게 설명 (2-3문장)"
  },

  "closing": {
    "message": "2026년을 보내는 {이름}님께 드리는 한마디. {핵심 메시지}를 기억하시면서, {격려/응원}. 올 한 해도 {마무리 인사}. (2-3문장의 따뜻한 마무리)"
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
