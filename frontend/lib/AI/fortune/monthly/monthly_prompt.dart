/// # 이번달 운세 프롬프트 (v3.0 - 스토리텔링)
///
/// ## 개요
/// saju_base(평생운세) + saju_analyses(원국 데이터)를 기반으로 이번달 운세 분석
///
/// ## 파일 위치
/// `frontend/lib/AI/fortune/monthly/monthly_prompt.dart`
///
/// ## v3.0 개선사항 (스토리텔링 구조)
/// - 총운/카테고리별 운세를 자연스럽게 이어지는 문단으로
/// - 읽는 순서대로 JSON 구조 재배치
/// - "줄줄 읽히는" UX 최적화
/// - 주간별 흐름도 스토리텔링으로 개선
///
/// ## 모델
/// GPT-5-mini ($0.25 input, $2.00 output per 1M tokens)

import '../../core/ai_constants.dart';
import '../../prompts/prompt_template.dart';
import '../common/fortune_input_data.dart';

/// 이번달 운세 프롬프트 템플릿
class MonthlyPrompt extends PromptTemplate {
  /// 입력 데이터 (saju_base + saju_analyses 포함)
  final FortuneInputData inputData;

  /// 대상 연도
  final int targetYear;

  /// 대상 월
  final int targetMonth;

  const MonthlyPrompt({
    required this.inputData,
    required this.targetYear,
    required this.targetMonth,
  });

  @override
  String get summaryType => SummaryType.monthlyFortune;

  @override
  String get modelName => OpenAIModels.fortuneAnalysis; // gpt-5-mini

  @override
  int get maxTokens => TokenLimits.monthlyFortuneMaxTokens; // 4096

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
사용자의 원국(사주 팔자)과 평생운세 분석을 바탕으로 ${targetYear}년 ${targetMonth}월 $_monthGanji 운세를 **읽는 재미가 있게** 작성합니다.

## 이번달 월간지 정보
- 월간지: $_monthGanji
- 월천간: ${_monthElement['stem']} (${_monthElement['stemElement']})
- 월지지: ${_monthElement['branch']} (${_monthElement['branchElement']})

## 작성 원칙: 스토리텔링!

### 1. 줄줄 읽히는 문장
- 짧은 문장 나열 금지! 자연스럽게 이어지는 문단으로 작성
- 마치 전문가가 옆에서 설명해주는 것처럼
- 각 문단은 3-5문장이 자연스럽게 연결되어야 함

### 2. 월간지와 용신/기신 자연스럽게 녹이기
- "이번달 ${_monthElement['branch']} 기운이 들어오면서..."
- 전문 용어는 괄호로 쉬운 설명 추가

### 3. 합충 분석도 이야기처럼
- "특히 이번달 월지와 {이름}님의 일지가 만나면서..."
- 합이면 좋은 인연, 충이면 변화의 기회로 설명

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

## 이번달과의 합충 관계
${_formatMonthlyHapchung()}

## 평생 사주 분석 (saju_base)
${_formatSajuBase()}

## 분석 요청

위 원국 정보와 평생운세를 바탕으로 ${targetYear}년 ${targetMonth}월 운세를 분석해주세요.

**스토리텔링으로 작성해주세요:**
- 각 섹션이 자연스럽게 이어지는 문단으로
- 월천간/월지와 ${inputData.yongsinElement != null ? '용신 ${inputData.yongsinElement}' : '용신'}의 관계를 자연스럽게 녹여서
- 월지 ${_monthElement['branch']}와 ${inputData.dayJi != null ? '일지 ${inputData.dayJi}' : '일지'}의 관계를 이야기하듯이

## 응답 JSON 스키마 (읽는 순서대로!)

{
  "year": $targetYear,
  "month": $targetMonth,
  "monthGanji": "$_monthGanji",

  "overview": {
    "keyword": "이번달을 한마디로 (예: 새로운 시작, 신중한 한 달)",
    "score": 72,
    "opening": "${targetMonth}월이 시작됩니다. 이번달은 $_monthGanji 월로, ${_monthElement['stemElement']}과 ${_monthElement['branchElement']} 기운이 함께 흐르는 시기인데요. {이번달 기운에 대한 설명}하면서 {분위기 설명}한 한 달이 될 것 같습니다. (3-4문장으로 이번달 기운 소개)",
    "monthEnergy": "이번달 ${_monthElement['branch']} 기운은 {특성 설명}합니다. {이름}님의 사주와 만나면서 {영향}이 예상되는데요. 특히 {용신/기신과의 관계}하기 때문에 {구체적 영향}할 것으로 보입니다. (3-4문장으로 본인 사주와 연결)",
    "hapchungEffect": "이번달 월지 ${_monthElement['branch']}와 {이름}님의 일지가 {합충 관계}하면서 {의미}한 에너지가 흐르게 됩니다. 이는 {구체적 영향}을 의미하니, {대처 조언}하시면 좋겠습니다. (2-3문장, 합충이 없으면 '특별한 충돌 없이 안정적인 흐름'으로)",
    "conclusion": "따라서 이번달은 {핵심 메시지}하는 것이 좋겠습니다. {마무리 조언}. (2문장으로 총운 마무리)"
  },

  "career": {
    "title": "직업운",
    "score": 70,
    "reading": "이번달 직장에서는 {상황 분석}한 흐름입니다. ${_monthElement['stemElement']} 기운이 {영향}하면서 {구체적 상황}이 예상되는데요. 특히 {좋은 시기}에는 {기회}가 있을 수 있고, {주의 시기}에는 {주의사항}에 신경 쓰시면 좋겠습니다. {마무리 조언}하시면 좋은 결과가 있을 거예요. (4-5문장이 자연스럽게 이어지는 문단)",
    "bestWeeks": [1, 4],
    "cautionWeeks": [2]
  },

  "wealth": {
    "title": "재물운",
    "score": 68,
    "reading": "재물 측면에서 이번달은 {상황 분석}합니다. {이름}님의 재물 패턴을 보면 {특성}하신 편인데, 이번달 기운과 만나면서 {영향}이 생길 수 있어요. {좋은 시기}에 {기회}가 있을 수 있고, {주의 시기}에는 {주의사항}이 필요합니다. {마무리 조언}하시면 안정적으로 한 달을 보내실 수 있을 거예요. (4-5문장이 자연스럽게 이어지는 문단)",
    "bestWeeks": [3, 4],
    "cautionWeeks": [2]
  },

  "love": {
    "title": "애정운",
    "score": 72,
    "reading": "애정 운에서 이번달은 {상황 분석}한 기운이 흐릅니다. ${_monthElement['branchElement']} 에너지가 {영향}하면서 {변화}가 생길 수 있어요. 솔로이신 분들은 {솔로 조언}하시면 좋겠고, 연인이 있으신 분들은 {커플 조언}에 신경 쓰시면 관계가 더 좋아질 수 있습니다. {마무리 조언}해보세요. (4-5문장이 자연스럽게 이어지는 문단)",
    "bestWeeks": [1, 3],
    "cautionWeeks": [2]
  },

  "health": {
    "title": "건강운",
    "score": 65,
    "reading": "건강 측면에서 이번달은 ${_monthElement['branchElement']} 기운이 강하니 {관련 장기/부위}에 신경 쓰시면 좋겠습니다. {구체적 증상}이 나타날 수 있으니 {예방법}을 실천해보세요. 특히 {주의 시기}에는 무리하지 마시고, {라이프스타일 조언}하시는 것을 추천드립니다. {마무리 조언}하시면 건강하게 한 달을 보내실 수 있을 거예요. (4-5문장이 자연스럽게 이어지는 문단)",
    "focusAreas": ["관련 부위1", "관련 부위2"],
    "cautionWeeks": [2, 3]
  },

  "weekly": {
    "week1": {
      "period": "1일 ~ 7일",
      "theme": "테마 키워드",
      "score": 70,
      "reading": "첫째 주는 {분석}한 시기입니다. {상세 설명}하면서 {조언}하시면 좋겠습니다. 특히 {일}일과 {일}일이 좋은 날이니 활용해보세요. (2-3문장)"
    },
    "week2": {
      "period": "8일 ~ 14일",
      "theme": "테마 키워드",
      "score": 68,
      "reading": "둘째 주에는 {분석}한 기운이 흐릅니다. {상세 설명}하면서 {조언}에 신경 쓰시면 좋겠습니다. (2-3문장)"
    },
    "week3": {
      "period": "15일 ~ 21일",
      "theme": "테마 키워드",
      "score": 72,
      "reading": "셋째 주는 {분석}합니다. {상세 설명}하면서 {조언}해보세요. (2-3문장)"
    },
    "week4": {
      "period": "22일 ~ 말일",
      "theme": "테마 키워드",
      "score": 75,
      "reading": "넷째 주로 접어들면서 {분석}한 흐름입니다. {상세 설명}하면서 다음 달을 준비하시면 좋겠습니다. (2-3문장)"
    }
  },

  "lucky": {
    "colors": ["행운색1", "행운색2"],
    "numbers": [행운숫자1, 행운숫자2],
    "foods": ["추천 음식1", "추천 음식2"],
    "tip": "행운 요소 활용법을 자연스럽게 설명 (2문장)"
  },

  "bestDays": [좋은날짜들],
  "cautionDays": [주의날짜들],

  "closing": {
    "message": "${targetMonth}월을 보내는 {이름}님께. {핵심 메시지}를 기억하시면서 {격려/응원}. 좋은 한 달 보내세요! (2문장의 따뜻한 마무리)"
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
    if (chung[dayJi] == monthBranch) {
      buffer.writeln('- $dayJi$monthBranch 충(衝) 발생: 변화/이동/갈등 가능, 정체된 에너지 해소의 기회');
    }

    // 합 체크
    if (hap[dayJi] == monthBranch) {
      buffer.writeln('- $dayJi$monthBranch 합(合) 발생: 협력/결합/좋은 인연의 달');
    }

    // 삼합 체크
    if (samhap[dayJi]?.contains(monthBranch) ?? false) {
      String element;
      if (['寅', '午', '戌'].contains(dayJi)) {
        element = '火局';
      } else if (['申', '子', '辰'].contains(dayJi)) {
        element = '水局';
      } else if (['巳', '酉', '丑'].contains(dayJi)) {
        element = '金局';
      } else {
        element = '木局';
      }
      buffer.writeln('- $dayJi와 $monthBranch: 삼합($element) 기운 작용, 해당 오행 강화');
    }

    return buffer.toString();
  }
}
