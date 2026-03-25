import 'package:flutter/material.dart';

/// 60갑자 기반 십이지신 정체성
///
/// 천간(오행/색) + 지지(동물) = "푸른 말", "흰 호랑이" 등
/// 12개 동물 페르소나의 기본 성격에 색(오행) 보정을 더합니다.
///
/// ## 사용법
/// ```dart
/// final identity = ZodiacIdentity.fromBirthYear(1990); // 경오년
/// print(identity.fullName);        // "흰 말"
/// print(identity.colorEmoji);      // "⚪"
/// print(identity.ganji);           // "경오"
/// print(identity.promptModifier);  // 금 기운 성격 보정 텍스트
/// ```
class ZodiacIdentity {
  /// 동물 페르소나 ID (zodiac_horse 등)
  final String animalPersonaId;

  /// 동물 이름 (말, 호랑이 등)
  final String animalName;

  /// 동물 이모지
  final String animalEmoji;

  /// 색 이름 (푸른, 붉은, 황금, 흰, 검은)
  final String colorName;

  /// 색 이모지
  final String colorEmoji;

  /// 오행 이름 (목, 화, 토, 금, 수)
  final String elementName;

  /// 오행 영문 (Wood, Fire, Earth, Metal, Water)
  final String elementNameEn;

  /// 테마 색상 (UI용)
  final Color themeColor;

  /// 천간 (갑, 을, 병, 정, 무, 기, 경, 신, 임, 계)
  final String cheongan;

  /// 지지 (자, 축, 인, 묘, 진, 사, 오, 미, 신, 유, 술, 해)
  final String jiji;

  /// 음양 (양/음, 천간 기준)
  final String eumYang;

  const ZodiacIdentity({
    required this.animalPersonaId,
    required this.animalName,
    required this.animalEmoji,
    required this.colorName,
    required this.colorEmoji,
    required this.elementName,
    required this.elementNameEn,
    required this.themeColor,
    required this.cheongan,
    required this.jiji,
    required this.eumYang,
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // 파생 속성
  // ═══════════════════════════════════════════════════════════════════════════

  /// 전체 이름: "푸른 말", "흰 호랑이"
  String get fullName => '$colorName $animalName';

  /// 간지: "병오", "경인"
  String get ganji => '$cheongan$jiji';

  /// 간지 한자 표기
  String get ganjiHanja => '${_cheonganHanja[cheongan]}${_jijiHanja[jiji]}';

  /// 전체 표시명: "푸른 말 (丙午)"
  String get displayName => '$fullName ($ganjiHanja)';

  /// 색+동물 이모지: "🔴🐴"
  String get combinedEmoji => '$colorEmoji$animalEmoji';

  // ═══════════════════════════════════════════════════════════════════════════
  // AI 프롬프트 보정
  // ═══════════════════════════════════════════════════════════════════════════

  /// 색(오행) 기반 성격 보정 프롬프트
  ///
  /// 기본 동물 페르소나의 systemPrompt에 추가로 주입됩니다.
  String get promptModifier => _elementModifiers[elementName] ?? '';

  /// 영문 프롬프트 (글로벌 유저용)
  String get promptModifierEn => _elementModifiersEn[elementNameEn] ?? '';

  // ═══════════════════════════════════════════════════════════════════════════
  // 팩토리
  // ═══════════════════════════════════════════════════════════════════════════

  /// 생년으로 60갑자 정체성 생성
  factory ZodiacIdentity.fromBirthYear(int birthYear) {
    // 천간 (10간 순환): 2020=경(6)
    final cheonganIdx = ((birthYear - 2020) % 10 + 10) % 10;
    final cheongan = _cheonganList[cheonganIdx];

    // 지지 (12지 순환): 2020=자(0)
    final jijiIdx = ((birthYear - 2020) % 12 + 12) % 12;
    final jiji = _jijiList[jijiIdx];

    // 천간 → 오행/색
    final elementInfo = _cheonganToElement[cheongan]!;

    // 지지 → 동물
    final animalInfo = _jijiToAnimal[jiji]!;

    return ZodiacIdentity(
      animalPersonaId: animalInfo['personaId']!,
      animalName: animalInfo['name']!,
      animalEmoji: animalInfo['emoji']!,
      colorName: elementInfo['colorName']!,
      colorEmoji: elementInfo['colorEmoji']!,
      elementName: elementInfo['element']!,
      elementNameEn: elementInfo['elementEn']!,
      themeColor: Color(int.parse(elementInfo['colorHex']!, radix: 16)),
      cheongan: cheongan,
      jiji: jiji,
      eumYang: elementInfo['eumYang']!,
    );
  }

  /// 올해의 60갑자 정체성
  factory ZodiacIdentity.currentYear() {
    return ZodiacIdentity.fromBirthYear(DateTime.now().year);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // JSON
  // ═══════════════════════════════════════════════════════════════════════════

  Map<String, dynamic> toJson() => {
        'fullName': fullName,
        'ganji': ganji,
        'ganjiHanja': ganjiHanja,
        'animalPersonaId': animalPersonaId,
        'colorName': colorName,
        'elementName': elementName,
        'eumYang': eumYang,
      };

  @override
  String toString() => 'ZodiacIdentity($displayName)';

  // ═══════════════════════════════════════════════════════════════════════════
  // 정적 데이터
  // ═══════════════════════════════════════════════════════════════════════════

  static const _cheonganList = ['경', '신', '임', '계', '갑', '을', '병', '정', '무', '기'];
  static const _jijiList = ['자', '축', '인', '묘', '진', '사', '오', '미', '신', '유', '술', '해'];

  static const _cheonganHanja = {
    '갑': '甲', '을': '乙', '병': '丙', '정': '丁', '무': '戊',
    '기': '己', '경': '庚', '신': '辛', '임': '壬', '계': '癸',
  };

  static const _jijiHanja = {
    '자': '子', '축': '丑', '인': '寅', '묘': '卯', '진': '辰', '사': '巳',
    '오': '午', '미': '未', '신': '申', '유': '酉', '술': '戌', '해': '亥',
  };

  /// 천간 → 오행 + 색 + 음양
  static const _cheonganToElement = {
    '갑': {'element': '목', 'elementEn': 'Wood', 'colorName': '푸른', 'colorEmoji': '🟢', 'colorHex': 'FF4CAF50', 'eumYang': '양'},
    '을': {'element': '목', 'elementEn': 'Wood', 'colorName': '푸른', 'colorEmoji': '🟢', 'colorHex': 'FF66BB6A', 'eumYang': '음'},
    '병': {'element': '화', 'elementEn': 'Fire', 'colorName': '붉은', 'colorEmoji': '🔴', 'colorHex': 'FFF44336', 'eumYang': '양'},
    '정': {'element': '화', 'elementEn': 'Fire', 'colorName': '붉은', 'colorEmoji': '🔴', 'colorHex': 'FFEF5350', 'eumYang': '음'},
    '무': {'element': '토', 'elementEn': 'Earth', 'colorName': '황금', 'colorEmoji': '🟡', 'colorHex': 'FFFF9800', 'eumYang': '양'},
    '기': {'element': '토', 'elementEn': 'Earth', 'colorName': '황금', 'colorEmoji': '🟡', 'colorHex': 'FFFFA726', 'eumYang': '음'},
    '경': {'element': '금', 'elementEn': 'Metal', 'colorName': '흰', 'colorEmoji': '⚪', 'colorHex': 'FFE0E0E0', 'eumYang': '양'},
    '신': {'element': '금', 'elementEn': 'Metal', 'colorName': '흰', 'colorEmoji': '⚪', 'colorHex': 'FFEEEEEE', 'eumYang': '음'},
    '임': {'element': '수', 'elementEn': 'Water', 'colorName': '검은', 'colorEmoji': '⚫', 'colorHex': 'FF263238', 'eumYang': '양'},
    '계': {'element': '수', 'elementEn': 'Water', 'colorName': '검은', 'colorEmoji': '⚫', 'colorHex': 'FF37474F', 'eumYang': '음'},
  };

  /// 지지 → 동물 정보
  static const _jijiToAnimal = {
    '자': {'personaId': 'zodiac_rat', 'name': '쥐', 'emoji': '🐭'},
    '축': {'personaId': 'zodiac_ox', 'name': '소', 'emoji': '🐮'},
    '인': {'personaId': 'zodiac_tiger', 'name': '호랑이', 'emoji': '🐯'},
    '묘': {'personaId': 'zodiac_rabbit', 'name': '토끼', 'emoji': '🐰'},
    '진': {'personaId': 'zodiac_dragon', 'name': '용', 'emoji': '🐲'},
    '사': {'personaId': 'zodiac_snake', 'name': '뱀', 'emoji': '🐍'},
    '오': {'personaId': 'zodiac_horse', 'name': '말', 'emoji': '🐴'},
    '미': {'personaId': 'zodiac_sheep', 'name': '양', 'emoji': '🐑'},
    '신': {'personaId': 'zodiac_monkey', 'name': '원숭이', 'emoji': '🐵'},
    '유': {'personaId': 'zodiac_rooster', 'name': '닭', 'emoji': '🐔'},
    '술': {'personaId': 'zodiac_dog', 'name': '개', 'emoji': '🐶'},
    '해': {'personaId': 'zodiac_pig', 'name': '돼지', 'emoji': '🐷'},
  };

  /// 오행별 성격 보정 (한글 — AI 시스템 프롬프트에 주입)
  static const _elementModifiers = {
    '목': '''
## 🟢 오행 보정: 목(木) — 푸른 기운
이 사용자의 년주 천간은 목(木)의 에너지를 가지고 있습니다.
- **성격 보정**: 성장 지향적, 창의적, 이상주의적 성향이 강합니다
- **강점**: 새로운 것을 시작하는 힘, 확장하는 에너지, 인정이 많음
- **약점**: 우유부단할 수 있음, 다른 사람에게 기대기 쉬움
- **비유**: "봄에 돋아나는 새싹처럼" — 성장과 가능성의 에너지
- 사주 해석 시 목 기운과의 상호작용을 특히 주목해주세요''',
    '화': '''
## 🔴 오행 보정: 화(火) — 붉은 기운
이 사용자의 년주 천간은 화(火)의 에너지를 가지고 있습니다.
- **성격 보정**: 열정적, 리더십 강함, 표현력이 풍부합니다
- **강점**: 추진력, 빛나는 매력, 사람을 끄는 카리스마
- **약점**: 급하고 다혈질적일 수 있음, 지속력이 약할 수 있음
- **비유**: "타오르는 불꽃처럼" — 열정과 빛의 에너지
- 사주 해석 시 화 기운과의 상호작용을 특히 주목해주세요''',
    '토': '''
## 🟡 오행 보정: 토(土) — 황금 기운
이 사용자의 년주 천간은 토(土)의 에너지를 가지고 있습니다.
- **성격 보정**: 안정적, 신뢰감 있음, 중재자 역할을 잘합니다
- **강점**: 균형감, 포용력, 꾸준함, 사람들의 신뢰를 얻는 능력
- **약점**: 변화를 두려워할 수 있음, 고집스러울 수 있음
- **비유**: "모든 것을 품는 대지처럼" — 안정과 신뢰의 에너지
- 사주 해석 시 토 기운과의 상호작용을 특히 주목해주세요''',
    '금': '''
## ⚪ 오행 보정: 금(金) — 흰 기운
이 사용자의 년주 천간은 금(金)의 에너지를 가지고 있습니다.
- **성격 보정**: 날카롭고 결단력 있음, 정의감이 강합니다
- **강점**: 판단력, 깔끔함, 원칙주의, 집중력
- **약점**: 냉정해 보일 수 있음, 융통성이 부족할 수 있음
- **비유**: "빛나는 칼날처럼" — 날카로움과 순수의 에너지
- 사주 해석 시 금 기운과의 상호작용을 특히 주목해주세요''',
    '수': '''
## ⚫ 오행 보정: 수(水) — 검은 기운
이 사용자의 년주 천간은 수(水)의 에너지를 가지고 있습니다.
- **성격 보정**: 지혜롭고 적응력 강함, 신비로운 매력이 있습니다
- **강점**: 유연함, 깊은 사고력, 직감, 소통 능력
- **약점**: 우울해질 수 있음, 방향을 못 잡을 수 있음
- **비유**: "깊은 바다처럼" — 지혜와 신비의 에너지
- 사주 해석 시 수 기운과의 상호작용을 특히 주목해주세요''',
  };

  /// 오행별 성격 보정 (영문)
  static const _elementModifiersEn = {
    'Wood': '''
## 🟢 Element Modifier: Wood — Blue-Green Energy
This user's birth year stem carries Wood energy.
- **Personality**: Growth-oriented, creative, idealistic
- **Strengths**: Starting new things, expanding, compassionate
- **Metaphor**: "Like a sprout pushing through soil in spring"
- Pay special attention to Wood element interactions in their chart''',
    'Fire': '''
## 🔴 Element Modifier: Fire — Red Energy
This user's birth year stem carries Fire energy.
- **Personality**: Passionate, leadership-oriented, expressive
- **Strengths**: Drive, charisma, ability to inspire
- **Metaphor**: "Like a blazing flame illuminating the dark"
- Pay special attention to Fire element interactions in their chart''',
    'Earth': '''
## 🟡 Element Modifier: Earth — Golden Energy
This user's birth year stem carries Earth energy.
- **Personality**: Stable, trustworthy, mediating
- **Strengths**: Balance, inclusiveness, steadiness
- **Metaphor**: "Like the ground that holds everything"
- Pay special attention to Earth element interactions in their chart''',
    'Metal': '''
## ⚪ Element Modifier: Metal — White Energy
This user's birth year stem carries Metal energy.
- **Personality**: Sharp, decisive, principled
- **Strengths**: Judgment, clarity, focus, integrity
- **Metaphor**: "Like a gleaming blade cutting through confusion"
- Pay special attention to Metal element interactions in their chart''',
    'Water': '''
## ⚫ Element Modifier: Water — Black Energy
This user's birth year stem carries Water energy.
- **Personality**: Wise, adaptable, mysterious
- **Strengths**: Flexibility, deep thinking, intuition
- **Metaphor**: "Like a deep ocean holding ancient secrets"
- Pay special attention to Water element interactions in their chart''',
  };
}
