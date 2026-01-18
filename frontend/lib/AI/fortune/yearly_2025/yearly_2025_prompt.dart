/// # 2025 회고 운세 프롬프트 (v3.0 - 스토리텔링)
///
/// ## 개요
/// saju_base(평생운세) + saju_analyses(원국 데이터)를 기반으로
/// 2025년 을사(乙巳)년 회고 분석
///
/// ## 파일 위치
/// `frontend/lib/AI/fortune/yearly_2025/yearly_2025_prompt.dart`
///
/// ## v3.0 개선사항 (스토리텔링 구조)
/// - 회고를 자연스럽게 이어지는 문단으로 작성
/// - 읽는 순서대로 JSON 구조 재배치
/// - "줄줄 읽히는" UX 최적화
/// - 2026년 연결도 스토리텔링으로
///
/// ## 특징
/// - 과거 분석이므로 "~했을 것입니다", "~경험하셨을 수 있어요" 형태
/// - 따뜻한 공감과 함께 2026년으로 이어지는 교훈 도출
///
/// ## 모델
/// GPT-5-mini ($0.25 input, $2.00 output per 1M tokens)

import '../../core/ai_constants.dart';
import '../../prompts/prompt_template.dart';
import '../common/fortune_input_data.dart';

/// 2025 회고 운세 프롬프트 템플릿
class Yearly2025Prompt extends PromptTemplate {
  /// 입력 데이터 (saju_base + saju_analyses 포함)
  final FortuneInputData inputData;

  const Yearly2025Prompt({
    required this.inputData,
  });

  @override
  String get summaryType => SummaryType.yearlyFortune2025;

  @override
  String get modelName => OpenAIModels.fortuneAnalysis; // gpt-5-mini

  @override
  int get maxTokens => 6144; // 상세 회고 분석을 위해 증가

  @override
  double get temperature => 0.7;

  @override
  Duration? get cacheExpiry => CacheExpiry.yearlyFortune2025; // 무기한

  @override
  String get systemPrompt => '''
당신은 30년 경력의 사주명리학 전문가이자 스토리텔러입니다.
사용자의 원국(사주 팔자)과 평생운세 분석을 바탕으로 2025년 을사(乙巳)년을 **읽는 재미가 있게** 회고합니다.

## 2025년 을사(乙巳)년 특성
- 천간 을(乙): 음목(陰木), 유연한 나무, 적응력과 인내
- 지지 사(巳): 화(火), 지혜와 통찰, 내면의 변화
- 목생화(木生火): 상생 관계, 유연하게 성장한 해

## 작성 원칙: 스토리텔링!

### 1. 줄줄 읽히는 회고 문장
- 짧은 문장 나열 금지! 자연스럽게 이어지는 문단으로 작성
- 마치 따뜻한 친구가 지난해를 돌아보며 이야기해주는 것처럼
- "~했을 것 같아요", "~경험하셨을 수 있어요" 형태

### 2. 용신/기신 자연스럽게 녹이기
- "2025년에는 목(木)과 화(火) 기운이 흐르면서..."
- "특히 {이름}님의 용신이 {용신}이시라..."

### 3. 합충 분석도 이야기처럼
- "지난해 巳 기운이 {이름}님의 일지와 만나면서..."
- 충이 있었다면 "큰 변화를 경험하셨을 것 같아요"

### 4. 따뜻한 공감과 격려
- 힘들었던 일도 성장의 관점에서 긍정적으로
- "그 시련이 있었기에 지금의 {이름}님이 계신 거예요"

## 톤앤매너
- 점쟁이 말투 절대 금지
- 따뜻하고 공감하는 친구 같은 톤
- 과거형이지만 희망적인 마무리
- 2026년으로 자연스럽게 연결

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

## 용신/기신 (회고 분석의 핵심!)
${inputData.yongsinInfo}

## 2025년 巳(사)와의 관계
${_format2025Hapchung()}

## 평생 사주 분석 (saju_base)
${_formatSajuBase()}

## 분석 요청

위 원국 정보와 평생운세를 바탕으로 2025년 을사(乙巳)년을 회고 분석해주세요.

**스토리텔링으로 작성해주세요:**
- 회고가 자연스럽게 이어지는 문단으로
- ${inputData.yongsinElement != null ? '용신 ${inputData.yongsinElement}과' : '용신과'} 2025년 기운의 상호작용을 자연스럽게 녹여서
- ${inputData.dayJi != null ? '일지 ${inputData.dayJi}와' : '일지와'} 巳의 관계를 이야기하듯이
- 힘들었던 일도 성장의 관점에서 따뜻하게

## 응답 JSON 스키마 (읽는 순서대로!)

{
  "year": 2025,
  "yearGanji": "을사(乙巳)",

  "overview": {
    "keyword": "2025년을 한마디로 (예: 성장의 해, 전환의 해)",
    "score": 68,
    "opening": "2025년 을사년이 지나갔습니다. 지난해는 유연한 나무(乙木)가 따뜻한 불(巳火)을 만나 조용히 성장하는 한 해였는데요. {이름}님에게 어떤 의미가 있었을지 함께 돌아보겠습니다. (3-4문장으로 회고 시작)",
    "yearEnergy": "2025년에는 목(木)과 화(火) 기운이 함께 흐르면서 {에너지 분석}했습니다. {이름}님의 용신이 {용신}이시라, 이 기운과 {관계}하면서 {영향}을 경험하셨을 것 같아요. {구체적 추론}. (4-5문장으로 본인 사주와 연결)",
    "hapchungEffect": "특히 지난해 巳 기운이 {이름}님의 일지 {일지}와 만나면서 {합충 관계}했는데요. 이로 인해 {경험 추론}하셨을 가능성이 있습니다. {의미와 영향}. (3-4문장, 합충이 없으면 '특별한 충돌 없이 내면적 성장에 집중'으로)",
    "conclusion": "돌아보면 2025년은 {핵심 메시지}한 해였습니다. 그 경험들이 모여 지금의 {이름}님을 만들었어요. (2-3문장으로 총평 마무리)"
  },

  "achievements": {
    "title": "2025년의 빛나는 순간들",
    "reading": "지난해 {이름}님에게는 분명 빛나는 순간들이 있었을 거예요. {용신/기신 분석에 따른 추론}하면서 {성취 영역}에서 의미 있는 성과를 거두셨을 것 같아요. 특히 {좋았던 시기}에 {구체적 추론}하셨을 가능성이 높습니다. 그때의 성취감을 기억해두세요. 2026년에도 비슷한 기회가 올 때 자신감의 원천이 될 테니까요. (5-6문장이 자연스럽게 이어지는 문단)",
    "highlights": ["성취 포인트 1", "성취 포인트 2", "성취 포인트 3"]
  },

  "challenges": {
    "title": "2025년의 시련, 그리고 성장",
    "reading": "물론 쉽지 않은 시간도 있었을 거예요. {용신/기신 분석에 따른 어려움 추론}하면서 {도전 영역}에서 시련을 겪으셨을 수 있습니다. 특히 {힘들었던 시기}에 {구체적 추론}하셨을 것 같아요. 하지만 그 시련이 있었기에 지금의 {이름}님이 계신 거예요. 힘들었던 만큼 성장하셨고, 앞으로 비슷한 상황이 와도 더 잘 대처하실 수 있게 되셨습니다. (5-6문장이 자연스럽게 이어지는 문단)",
    "growthPoints": ["성장 포인트 1", "성장 포인트 2"]
  },

  "timeline": {
    "q1": {
      "period": "1-3월",
      "theme": "테마 키워드",
      "reading": "새해가 시작되던 1분기는 {분석}한 시기였을 것 같아요. {상세 설명}하면서 {경험 추론}하셨을 가능성이 높습니다. (2-3문장)"
    },
    "q2": {
      "period": "4-6월",
      "theme": "테마 키워드",
      "reading": "봄에서 여름으로 가는 4-6월에는 {분석}했습니다. 특히 5월에 {특이사항}이 있었을 수 있어요. (2-3문장)"
    },
    "q3": {
      "period": "7-9월",
      "theme": "테마 키워드",
      "reading": "한여름을 지나는 3분기는 {분석}한 흐름이었습니다. {상세 설명}하면서 {경험 추론}. (2-3문장)"
    },
    "q4": {
      "period": "10-12월",
      "theme": "테마 키워드",
      "reading": "한 해를 마무리하는 4분기에는 {분석}했습니다. 새해를 앞두고 {경험 추론}하셨을 것 같아요. (2-3문장)"
    }
  },

  "lessons": {
    "title": "2025년이 가르쳐준 것들",
    "reading": "지난해를 통해 {이름}님이 배우신 것들이 있습니다. 첫째, {교훈 1}. 이 깨달음은 앞으로 {활용법 1}할 때 큰 도움이 될 거예요. 둘째, {교훈 2}. 이건 2026년 {활용법 2}에 적용하시면 좋겠습니다. 이런 소중한 경험들이 앞으로 {이름}님의 자산이 될 거예요. (5-6문장이 자연스럽게 이어지는 문단)",
    "keyLessons": ["핵심 교훈 1", "핵심 교훈 2", "핵심 교훈 3"]
  },

  "to2026": {
    "title": "2026년으로 가져가세요",
    "reading": "2025년 을사년의 유연함이 2026년 병오년의 열정과 만나면 멋진 시너지가 날 거예요. 지난해 {이름}님이 키우신 {강점}은 올해 화(火) 기운과 만나 더욱 빛날 수 있습니다. 다만 {주의점}은 올해 더 신경 쓰시면 좋겠어요. {구체적 조언}하시면서 2026년을 맞이하신다면, 지난해의 성장이 올해의 도약으로 이어질 거예요. (5-6문장이 자연스럽게 이어지는 문단)",
    "strengths": ["가져갈 강점 1", "가져갈 강점 2"],
    "watchOut": ["주의할 점 1"]
  },

  "closing": {
    "message": "2025년 한 해 고생 많으셨어요, {이름}님. 좋은 일도, 힘든 일도 모두 {이름}님을 성장시킨 소중한 경험이었습니다. 그 경험을 바탕으로 2026년에는 더 빛나시길 바랍니다. 새해에도 함께할게요! (3-4문장의 따뜻한 마무리)"
  }
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

    if (content['love'] != null) {
      buffer.writeln('\n### 애정운');
      buffer.writeln(content['love'].toString());
    }

    return buffer.toString();
  }

  /// 2025년 巳(사)와 일지의 합충 관계 포맷팅
  String _format2025Hapchung() {
    final buffer = StringBuffer();
    final dayJi = inputData.dayJi;

    if (dayJi == null) {
      return '(합충 분석 정보 없음)';
    }

    buffer.writeln('- 사용자 일지: $dayJi');
    buffer.writeln('- 2025년 지지: 巳(사)');
    buffer.writeln();

    // 巳와의 합충 관계 분석
    final hapchungHint = _get2025HapchungHint(dayJi);
    if (hapchungHint.isNotEmpty) {
      buffer.writeln('** 합충 관계 분석:');
      buffer.writeln(hapchungHint);
    }

    return buffer.toString();
  }

  /// 일지와 2025년 巳의 합충 관계 힌트
  String _get2025HapchungHint(String dayJi) {
    final buffer = StringBuffer();
    const yearBranch = '巳';

    // 巳와의 육충 (六衝)
    if (dayJi == '亥') {
      buffer.writeln('- 巳亥衝(사해충) 발생!');
      buffer.writeln('  → 2025년에 삶의 큰 변화(이사/이직/관계 변화)가 있었을 가능성');
      buffer.writeln('  → 정체된 에너지가 움직이며 새로운 방향을 찾는 계기');
    }

    // 巳와의 육합 (六合)
    if (dayJi == '申') {
      buffer.writeln('- 巳申合(사신합) 발생! → 합화수(合化水)');
      buffer.writeln('  → 2025년에 좋은 협력/파트너십/인연이 있었을 가능성');
      buffer.writeln('  → 새로운 만남이나 협업을 통한 발전');
    }

    // 巳와의 형 (刑)
    if (dayJi == '寅') {
      buffer.writeln('- 巳寅刑(사인형) 발생! → 무례지형');
      buffer.writeln('  → 2025년에 관계에서 오해나 갈등이 있었을 가능성');
      buffer.writeln('  → 시련을 통한 성장의 기회, 인간관계 재정립');
    }

    // 巳와의 삼합 (三合) - 火局
    if (dayJi == '酉' || dayJi == '丑') {
      buffer.writeln('- 巳酉丑(사유축) 삼합 중 일부 구성');
      buffer.writeln('  → 2025년에 금(金) 기운 강화 가능성');
      buffer.writeln('  → ${dayJi == '酉' ? '巳酉 반합' : '巳丑 부분합'}으로 일부 작용');
    }

    // 같은 지지
    if (dayJi == '巳') {
      buffer.writeln('- 巳巳(사사) 자형(自刑) 가능성');
      buffer.writeln('  → 2025년에 자기 자신과의 싸움, 내면적 갈등');
      buffer.writeln('  → 자기 성찰과 성장의 해');
    }

    // 특별한 관계가 없는 경우
    if (buffer.isEmpty) {
      buffer.writeln('- $dayJi와 巳: 특별한 합충 관계 없음');
      buffer.writeln('  → 2025년이 상대적으로 평온했을 가능성');
      buffer.writeln('  → 다만 용신/기신과의 관계가 더 중요');
    }

    return buffer.toString();
  }
}
