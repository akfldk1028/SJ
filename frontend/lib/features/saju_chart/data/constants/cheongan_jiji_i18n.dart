/// 천간지지 다국어 매핑
///
/// DB/계산 레이어는 한글 키 유지 (갑, 을, 자, 축 등)
/// UI 표시 시 locale에 따라 변환
///
/// - ko: 한글 그대로 (무)
/// - ja: 일본어 음독 (ぼ)
/// - zh: 중국어 병음 (wù)
/// - en/기타: 로마자 (Mu)
///
/// 한자는 CJK 공통이므로 모든 언어에서 동일

/// 천간 한글 → 로마자/다국어 표시명
const Map<String, Map<String, String>> _cheonganI18n = {
  '갑': {'ko': '갑', 'ja': 'こう',  'zh': 'jiǎ',  'en': 'Gap'},
  '을': {'ko': '을', 'ja': 'おつ',  'zh': 'yǐ',   'en': 'Eul'},
  '병': {'ko': '병', 'ja': 'へい',  'zh': 'bǐng',  'en': 'Byeong'},
  '정': {'ko': '정', 'ja': 'てい',  'zh': 'dīng',  'en': 'Jeong'},
  '무': {'ko': '무', 'ja': 'ぼ',    'zh': 'wù',    'en': 'Mu'},
  '기': {'ko': '기', 'ja': 'き',    'zh': 'jǐ',    'en': 'Gi'},
  '경': {'ko': '경', 'ja': 'こう',  'zh': 'gēng',  'en': 'Gyeong'},
  '신': {'ko': '신', 'ja': 'しん',  'zh': 'xīn',   'en': 'Sin'},
  '임': {'ko': '임', 'ja': 'じん',  'zh': 'rén',   'en': 'Im'},
  '계': {'ko': '계', 'ja': 'き',    'zh': 'guǐ',   'en': 'Gye'},
};

/// 지지 한글 → 로마자/다국어 표시명
const Map<String, Map<String, String>> _jijiI18n = {
  '자': {'ko': '자', 'ja': 'し',    'zh': 'zǐ',    'en': 'Ja'},
  '축': {'ko': '축', 'ja': 'ちゅう','zh': 'chǒu',  'en': 'Chuk'},
  '인': {'ko': '인', 'ja': 'いん',  'zh': 'yín',   'en': 'In'},
  '묘': {'ko': '묘', 'ja': 'ぼう',  'zh': 'mǎo',   'en': 'Myo'},
  '진': {'ko': '진', 'ja': 'しん',  'zh': 'chén',  'en': 'Jin'},
  '사': {'ko': '사', 'ja': 'し',    'zh': 'sì',    'en': 'Sa'},
  '오': {'ko': '오', 'ja': 'ご',    'zh': 'wǔ',    'en': 'O'},
  '미': {'ko': '미', 'ja': 'び',    'zh': 'wèi',   'en': 'Mi'},
  '신': {'ko': '신', 'ja': 'しん',  'zh': 'shēn',  'en': 'Sin'},
  '유': {'ko': '유', 'ja': 'ゆう',  'zh': 'yǒu',   'en': 'Yu'},
  '술': {'ko': '술', 'ja': 'じゅつ','zh': 'xū',    'en': 'Sul'},
  '해': {'ko': '해', 'ja': 'がい',  'zh': 'hài',   'en': 'Hae'},
};

/// 오행 한글 → 다국어 표시명
const Map<String, Map<String, String>> _ohengI18n = {
  '목': {'ko': '목', 'ja': '木',  'zh': '木', 'en': 'Wood'},
  '화': {'ko': '화', 'ja': '火',  'zh': '火', 'en': 'Fire'},
  '토': {'ko': '토', 'ja': '土',  'zh': '土', 'en': 'Earth'},
  '금': {'ko': '금', 'ja': '金',  'zh': '金', 'en': 'Metal'},
  '수': {'ko': '수', 'ja': '水',  'zh': '水', 'en': 'Water'},
};

/// 음양 한글 → 다국어 표시명
const Map<String, Map<String, String>> _eumyangI18n = {
  '양': {'ko': '양', 'ja': '陽',  'zh': '阳', 'en': 'Yang'},
  '음': {'ko': '음', 'ja': '陰',  'zh': '阴', 'en': 'Yin'},
};

/// 띠 동물 한글 → 다국어 표시명
const Map<String, Map<String, String>> _animalI18n = {
  '쥐':     {'ko': '쥐',     'ja': 'ねずみ', 'zh': '鼠', 'en': 'Rat'},
  '소':     {'ko': '소',     'ja': 'うし',   'zh': '牛', 'en': 'Ox'},
  '호랑이': {'ko': '호랑이', 'ja': 'とら',   'zh': '虎', 'en': 'Tiger'},
  '토끼':   {'ko': '토끼',   'ja': 'うさぎ', 'zh': '兔', 'en': 'Rabbit'},
  '용':     {'ko': '용',     'ja': 'たつ',   'zh': '龙', 'en': 'Dragon'},
  '뱀':     {'ko': '뱀',     'ja': 'へび',   'zh': '蛇', 'en': 'Snake'},
  '말':     {'ko': '말',     'ja': 'うま',   'zh': '马', 'en': 'Horse'},
  '양':     {'ko': '양',     'ja': 'ひつじ', 'zh': '羊', 'en': 'Goat'},
  '원숭이': {'ko': '원숭이', 'ja': 'さる',   'zh': '猴', 'en': 'Monkey'},
  '닭':     {'ko': '닭',     'ja': 'とり',   'zh': '鸡', 'en': 'Rooster'},
  '개':     {'ko': '개',     'ja': 'いぬ',   'zh': '狗', 'en': 'Dog'},
  '돼지':   {'ko': '돼지',   'ja': 'いのしし','zh': '猪', 'en': 'Pig'},
};

// ============================================================================
// 공개 API
// ============================================================================

/// 사주 용어 다국어 변환 유틸리티
class SajuI18n {
  SajuI18n._();

  /// 천간 한글 → locale별 표시명
  /// 예: ('무', 'en') → 'Mu', ('무', 'ko') → '무'
  static String cheongan(String hangul, String locale) {
    return _lookup(_cheonganI18n, hangul, locale);
  }

  /// 지지 한글 → locale별 표시명
  static String jiji(String hangul, String locale) {
    return _lookup(_jijiI18n, hangul, locale);
  }

  /// 오행 한글 → locale별 표시명
  static String oheng(String hangul, String locale) {
    return _lookup(_ohengI18n, hangul, locale);
  }

  /// 음양 한글 → locale별 표시명
  static String eumyang(String hangul, String locale) {
    return _lookup(_eumyangI18n, hangul, locale);
  }

  /// 띠 동물 한글 → locale별 표시명
  static String animal(String hangul, String locale) {
    return _lookup(_animalI18n, hangul, locale);
  }

  /// 천간 표시 형식: "무(戊)" 또는 "Mu(戊)" 등
  /// [hanja]는 cheongan_jiji.dart에서 가져옴
  static String cheonganWithHanja(String hangul, String hanja, String locale) {
    if (locale == 'ko') return '$hangul($hanja)';
    final localized = cheongan(hangul, locale);
    return '$localized($hanja)';
  }

  /// 지지 표시 형식
  static String jijiWithHanja(String hangul, String hanja, String locale) {
    if (locale == 'ko') return '$hangul($hanja)';
    final localized = jiji(hangul, locale);
    return '$localized($hanja)';
  }

  // 내부 조회 헬퍼
  static String _lookup(
    Map<String, Map<String, String>> table,
    String key,
    String locale,
  ) {
    final entry = table[key];
    if (entry == null) return key; // fallback: 원본 반환
    // ko, ja, zh는 전용 값, 나머지는 en 사용
    return entry[locale] ?? entry['en'] ?? key;
  }
}
