import '../../../../features/profile/domain/entities/saju_profile.dart';
import 'zodiac_identity.dart';
import 'zodiac_resolver.dart';

/// 십이지신 일주(Day Pillar) 기반 페르소나 매칭
///
/// 일주의 지지(day branch)로 동물 페르소나를 매칭합니다.
/// 음력/진태양시/자시 보정 모두 적용 (ZodiacResolver 경유).
///
/// ## 사용법 (현재)
/// ```dart
/// // SajuProfile로 페르소나 ID (일주 기반, 정확)
/// final id = ZodiacPersonaMatcher.getPersonaIdFromProfile(profile); // zodiac_rat
///
/// // 60갑자 정체성 (색+동물)
/// final identity = ZodiacPersonaMatcher.getIdentityFromProfile(profile); // "흰 말 (庚午)"
///
/// // 올해 동물 (년주 기반 — 의도적, "올해의 띠"는 시대적 개념)
/// final yearId = ZodiacPersonaMatcher.getCurrentYearPersonaId(); // 2026 = zodiac_horse
/// ```
///
/// ## 띠(년주) 기반 메서드는 @Deprecated
/// - `getPersonaIdByBirthYear`, `getIdentity(birthYear)` — 양력 출생년만 봄
/// - 음력/진태양시 보정 안 됨 → 정확도 떨어짐. `*FromProfile` 사용.
class ZodiacPersonaMatcher {
  ZodiacPersonaMatcher._();

  // ═══════════════════════════════════════════════════════════════════════════
  // 매칭 API
  // ═══════════════════════════════════════════════════════════════════════════

  /// SajuProfile로 일주(Day Pillar) 기반 동물 페르소나 ID 반환
  ///
  /// 음력/진태양시/자시 보정 모두 적용. 정확한 매칭.
  /// [profile] 활성 프로필
  /// [localeCode] 도시 미입력 시 기본값 결정용
  static String getPersonaIdFromProfile(
    SajuProfile profile, {
    String? localeCode,
  }) {
    final identity =
        ZodiacResolver.fromProfile(profile, localeCode: localeCode);
    return identity.animalPersonaId;
  }

  /// 생년의 지지(earthly branch)로 띠 동물 페르소나 ID 반환
  ///
  /// ⚠️ DEPRECATED — 음력/진태양시 보정 없는 띠(년주) 기반.
  /// `getPersonaIdFromProfile(profile)` 사용 (일주 기반, 정확).
  ///
  /// 기준: 2020년 = 경자년(쥐, index 0)
  /// [birthYear] 양력 생년 (예: 1996)
  @Deprecated('Use getPersonaIdFromProfile(profile) — accurate Day Pillar')
  static String getPersonaIdByBirthYear(int birthYear) {
    final index = ((birthYear - 2020) % 12 + 12) % 12;
    return _zodiacPersonaIds[index];
  }

  /// 올해의 띠 동물 페르소나 ID
  static String getCurrentYearPersonaId() {
    return getPersonaIdByBirthYear(DateTime.now().year);
  }

  /// 올해의 띠 동물 이름 (한글)
  static String getCurrentYearAnimalName() {
    final id = getCurrentYearPersonaId();
    return getAnimalName(id);
  }

  /// 올해의 간지 표기
  static String getCurrentYearGanji() {
    final year = DateTime.now().year;
    final cheonganIndex = (year - 2020 + 6) % 10; // 2020=경(6)
    final jijiIndex = (year - 2020) % 12;
    return '${_cheongan[cheonganIndex]}${_jiji[jijiIndex]}';
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 유틸리티
  // ═══════════════════════════════════════════════════════════════════════════

  /// 페르소나 ID → 동물 이모지
  static String getAnimalEmoji(String personaId) {
    return _emojiMap[personaId] ?? '🐾';
  }

  /// 페르소나 ID → 동물 이름 (한글)
  static String getAnimalName(String personaId) {
    return _nameMap[personaId] ?? '동물';
  }

  /// 페르소나 ID → 오행 (한글)
  static String getElement(String personaId) {
    return _elementMap[personaId] ?? '토';
  }

  /// 십이지신 페르소나인지 확인
  static bool isZodiacPersona(String personaId) {
    return _zodiacPersonaIds.contains(personaId);
  }

  /// 모든 십이지신 페르소나 ID 목록
  static List<String> get allPersonaIds => List.unmodifiable(_zodiacPersonaIds);

  // ═══════════════════════════════════════════════════════════════════════════
  // 60갑자 정체성 (색 + 동물)
  // ═══════════════════════════════════════════════════════════════════════════

  /// SajuProfile로 일주 기반 60갑자 정체성 (색+동물) 생성
  ///
  /// [profile] 활성 프로필 (음력/진태양시/자시 보정 적용)
  /// [localeCode] 도시 미입력 시 기본값
  /// 반환: ZodiacIdentity ("흰 말", "푸른 쥐" 등) — 일주 기반, 정확
  static ZodiacIdentity getIdentityFromProfile(
    SajuProfile profile, {
    String? localeCode,
  }) {
    return ZodiacResolver.fromProfile(profile, localeCode: localeCode);
  }

  /// 생년으로 60갑자 정체성 (색+동물) 생성
  ///
  /// ⚠️ DEPRECATED — 띠(년주) 기반. 일주 정확도 떨어짐.
  /// `getIdentityFromProfile(profile)` 사용.
  @Deprecated('Use getIdentityFromProfile(profile) — accurate Day Pillar')
  static ZodiacIdentity getIdentity(int birthYear) {
    // ignore: deprecated_member_use_from_same_package
    return ZodiacIdentity.fromBirthYear(birthYear);
  }

  /// 올해의 60갑자 정체성
  static ZodiacIdentity get currentYearIdentity {
    return ZodiacIdentity.currentYear();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 내부 데이터
  // ═══════════════════════════════════════════════════════════════════════════

  /// 지지 순서: 자(0)축(1)인(2)묘(3)진(4)사(5)오(6)미(7)신(8)유(9)술(10)해(11)
  static const _zodiacPersonaIds = [
    'zodiac_rat', // 자 - 쥐
    'zodiac_ox', // 축 - 소
    'zodiac_tiger', // 인 - 호랑이
    'zodiac_rabbit', // 묘 - 토끼
    'zodiac_dragon', // 진 - 용
    'zodiac_snake', // 사 - 뱀
    'zodiac_horse', // 오 - 말
    'zodiac_sheep', // 미 - 양
    'zodiac_monkey', // 신 - 원숭이
    'zodiac_rooster', // 유 - 닭
    'zodiac_dog', // 술 - 개
    'zodiac_pig', // 해 - 돼지
  ];

  static const _cheongan = ['갑', '을', '병', '정', '무', '기', '경', '신', '임', '계'];
  static const _jiji = ['자', '축', '인', '묘', '진', '사', '오', '미', '신', '유', '술', '해'];

  static const _emojiMap = {
    'zodiac_rat': '🐭',
    'zodiac_ox': '🐮',
    'zodiac_tiger': '🐯',
    'zodiac_rabbit': '🐰',
    'zodiac_dragon': '🐲',
    'zodiac_snake': '🐍',
    'zodiac_horse': '🐴',
    'zodiac_sheep': '🐑',
    'zodiac_monkey': '🐵',
    'zodiac_rooster': '🐔',
    'zodiac_dog': '🐶',
    'zodiac_pig': '🐷',
  };

  static const _nameMap = {
    'zodiac_rat': '쥐',
    'zodiac_ox': '소',
    'zodiac_tiger': '호랑이',
    'zodiac_rabbit': '토끼',
    'zodiac_dragon': '용',
    'zodiac_snake': '뱀',
    'zodiac_horse': '말',
    'zodiac_sheep': '양',
    'zodiac_monkey': '원숭이',
    'zodiac_rooster': '닭',
    'zodiac_dog': '개',
    'zodiac_pig': '돼지',
  };

  static const _elementMap = {
    'zodiac_rat': '수',
    'zodiac_ox': '토',
    'zodiac_tiger': '목',
    'zodiac_rabbit': '목',
    'zodiac_dragon': '토',
    'zodiac_snake': '화',
    'zodiac_horse': '화',
    'zodiac_sheep': '토',
    'zodiac_monkey': '금',
    'zodiac_rooster': '금',
    'zodiac_dog': '토',
    'zodiac_pig': '수',
  };
}
