/// 사주 분석 프롬프트 템플릿
class SajuPrompts {
  /// GPT 사주 분석 시스템 프롬프트
  static const String analysisSystem = '''당신은 전문 사주명리학자입니다.
만세력 데이터를 기반으로 정확하고 체계적인 사주 분석을 제공합니다.

분석 규칙:
1. 오행(五行) 균형 분석
2. 일간 강약 판단
3. 용신(用神) 도출
4. 격국(格局) 판단
5. 대운/세운 흐름 분석

응답 형식 (JSON):
{
  "analysis": {
    "summary": "핵심 분석 요약 (2-3문장)",
    "oheng_balance": {
      "strong": ["목", "화"],
      "weak": ["금"],
      "missing": []
    },
    "day_strength": {
      "level": "신강/신약/중화",
      "score": 65,
      "reason": "판단 근거"
    },
    "yongsin": {
      "primary": "금",
      "secondary": "수",
      "reason": "용신 선정 이유"
    },
    "fortune": {
      "overall": "긍정적/보통/주의필요",
      "career": "직장운",
      "wealth": "재물운",
      "love": "애정운",
      "health": "건강운"
    },
    "advice": ["조언1", "조언2", "조언3"]
  }
}''';

  /// Gemini 대화 시스템 프롬프트
  static const String chatSystem = '''당신은 친근하고 재미있는 사주 상담사 "만톡이"입니다.

성격:
- 따뜻하고 공감 능력이 뛰어남
- 유머 감각이 있음
- 희망적이고 긍정적

대화 스타일:
- 딱딱한 분석 용어 대신 쉬운 말로 설명
- 적절한 이모지 사용 (2-3개)
- 긍정적이고 희망적인 톤 유지
- 구체적이고 실용적인 조언 제공
- 4-6문장으로 간결하게''';

  /// 오늘 운세 분석 프롬프트
  static String dailyFortune(Map<String, dynamic> birthInfo) {
    return '''## 생년월일시 정보
${_formatBirthInfo(birthInfo)}

## 요청
오늘 운세를 분석해주세요.
- 전반적인 운세 흐름
- 주의해야 할 점
- 행운을 높이는 팁''';
  }

  /// 궁합 분석 프롬프트
  static String compatibility({
    required Map<String, dynamic> person1,
    required Map<String, dynamic> person2,
  }) {
    return '''## 본인 정보
${_formatBirthInfo(person1)}

## 상대방 정보
${_formatBirthInfo(person2)}

## 요청
두 사람의 궁합을 분석해주세요.
- 전체 궁합 점수 (100점 만점)
- 잘 맞는 부분
- 주의해야 할 부분
- 관계 발전을 위한 조언''';
  }

  /// 신년 운세 프롬프트
  static String yearlyFortune(Map<String, dynamic> birthInfo, int year) {
    return '''## 생년월일시 정보
${_formatBirthInfo(birthInfo)}

## 요청
$year년 신년 운세를 분석해주세요.
- 전반적인 운세
- 월별 주요 포인트
- 올해의 행운 키워드
- 주의해야 할 시기''';
  }

  /// 사주 이미지 생성 프롬프트
  static String sajuImagePrompt({
    required String dayGan,
    required String oheng,
    required String mood,
  }) {
    final elementStyle = _ohengToStyle(oheng);

    return '''A mystical Korean fortune-telling themed illustration:
- Main element: ${_ganToSymbol(dayGan)}
- Color palette: $elementStyle
- Mood: $mood
- Style: Modern Korean traditional fusion, minimalist, elegant
- Include: subtle celestial elements, flowing energy lines
- Exclude: text, words, letters, realistic faces
- Art style: Soft watercolor with clean vector elements''';
  }

  static String _formatBirthInfo(Map<String, dynamic> info) {
    final buffer = StringBuffer();
    if (info['year'] != null) buffer.writeln('년: ${info['year']}');
    if (info['month'] != null) buffer.writeln('월: ${info['month']}');
    if (info['day'] != null) buffer.writeln('일: ${info['day']}');
    if (info['hour'] != null) buffer.writeln('시: ${info['hour']}');
    if (info['gender'] != null) buffer.writeln('성별: ${info['gender']}');
    return buffer.toString();
  }

  static String _ohengToStyle(String oheng) {
    switch (oheng) {
      case '목':
        return 'green tones, spring forest, growth energy';
      case '화':
        return 'red and orange tones, warm fire, passionate energy';
      case '토':
        return 'yellow and brown tones, earth, stable grounding energy';
      case '금':
        return 'white and silver tones, metallic shine, sharp clarity';
      case '수':
        return 'blue and black tones, flowing water, deep wisdom';
      default:
        return 'balanced natural tones, harmony';
    }
  }

  static String _ganToSymbol(String gan) {
    const symbols = {
      '갑': 'tall pine tree, strength',
      '을': 'flowering vine, flexibility',
      '병': 'bright sun, radiance',
      '정': 'warm candle flame, gentle warmth',
      '무': 'mountain, stability',
      '기': 'fertile field, nurturing',
      '경': 'sharp sword, precision',
      '신': 'refined jewelry, elegance',
      '임': 'vast ocean, depth',
      '계': 'gentle rain, wisdom',
    };
    return symbols[gan] ?? 'cosmic energy, balance';
  }
}
