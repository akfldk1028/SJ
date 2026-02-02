/// # Dart 궁합 계산기
///
/// ## 개요
/// 두 사람의 사주 데이터를 기반으로 궁합을 계산합니다.
/// Gemini API 호출 없이 Dart 로직으로 즉시 계산하여 속도가 빠릅니다.
///
/// ## 파일 위치
/// `frontend/lib/AI/services/compatibility_calculator.dart`
///
/// ## v4.0 아키텍처 변경
/// - 기존: Gemini가 사주 계산 + 궁합 분석 (느리고 부정확)
/// - 변경: GPT-5.2가 사주 계산 (saju_analyses) → Dart가 궁합 계산 (빠르고 정확)
///
/// ## 계산 요소
/// - 천간합 (5가지): 갑기합토, 을경합금, 병신합수, 정임합목, 무계합화
/// - 지지 육합 (6가지): 자축합토, 인해합목, 묘술합화, 진유합금, 사신합수, 오미합화
/// - 지지 삼합/반합 (4가지): 인오술합화, 해묘미합목, 사유축합금, 신자진합수
/// - 지지 방합 (4가지): 인묘진합목, 사오미합화, 신유술합금, 해자축합수
/// - 지지 충 (6가지): 자오충, 축미충, 인신충, 묘유충, 진술충, 사해충
/// - 지지 형: 삼형살(인사신, 축술미), 자묘형, 자형
/// - 지지 해 (6가지): 술유해, 신해해, 미자해, 축오해, 인사해, 묘진해
/// - 지지 파 (6가지): 유자파, 축진파, 인해파, 묘오파, 신사파, 술미파
/// - 원진 (6가지): 자미, 축오, 인사, 묘진, 신해, 유술
/// - 오행 상생상극

// ═══════════════════════════════════════════════════════════════════════════
// 헬퍼 익스텐션
// ═══════════════════════════════════════════════════════════════════════════

/// Iterable 확장 메서드
extension IterableExtension<T> on Iterable<T> {
  /// 조건을 만족하는 첫 번째 요소 반환 (없으면 null)
  T? firstWhereOrNull(bool Function(T element) test) {
    for (final element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 천간 (10 Heavenly Stems)
// ═══════════════════════════════════════════════════════════════════════════

/// 천간 열거형
enum Cheongan {
  gap('갑', '甲', '木', true),
  eul('을', '乙', '木', false),
  byeong('병', '丙', '火', true),
  jeong('정', '丁', '火', false),
  mu('무', '戊', '土', true),
  gi('기', '己', '土', false),
  gyeong('경', '庚', '金', true),
  sin('신', '辛', '金', false),
  im('임', '壬', '水', true),
  gye('계', '癸', '水', false);

  final String korean;
  final String hanja;
  final String oheng;
  final bool isYang; // 양(true) / 음(false)

  const Cheongan(this.korean, this.hanja, this.oheng, this.isYang);

  /// 한글(한자) 형식에서 파싱 (예: "갑(甲)" → Cheongan.gap)
  static Cheongan? fromKoreanHanja(String? value) {
    if (value == null || value.isEmpty) return null;
    final korean = value.split('(').first.trim();
    return Cheongan.values.firstWhereOrNull((e) => e.korean == korean);
  }

  /// 한글만으로 파싱 (예: "갑" → Cheongan.gap)
  static Cheongan? fromKorean(String? value) {
    if (value == null || value.isEmpty) return null;
    return Cheongan.values.firstWhereOrNull((e) => e.korean == value.trim());
  }

  /// 한글(한자) 형식으로 변환
  String toKoreanHanja() => '$korean($hanja)';
}

// ═══════════════════════════════════════════════════════════════════════════
// 지지 (12 Earthly Branches)
// ═══════════════════════════════════════════════════════════════════════════

/// 지지 열거형
enum Jiji {
  ja('자', '子', '水', true),
  chuk('축', '丑', '土', false),
  in_('인', '寅', '木', true),
  myo('묘', '卯', '木', false),
  jin('진', '辰', '土', true),
  sa('사', '巳', '火', false),
  o('오', '午', '火', true),
  mi('미', '未', '土', false),
  sin_('신', '申', '金', true),
  yu('유', '酉', '金', false),
  sul('술', '戌', '土', true),
  hae('해', '亥', '水', false);

  final String korean;
  final String hanja;
  final String oheng;
  final bool isYang;

  const Jiji(this.korean, this.hanja, this.oheng, this.isYang);

  /// 한글(한자) 형식에서 파싱 (예: "자(子)" → Jiji.ja)
  static Jiji? fromKoreanHanja(String? value) {
    if (value == null || value.isEmpty) return null;
    final korean = value.split('(').first.trim();
    return Jiji.values.firstWhereOrNull((e) => e.korean == korean);
  }

  /// 한글만으로 파싱
  static Jiji? fromKorean(String? value) {
    if (value == null || value.isEmpty) return null;
    return Jiji.values.firstWhereOrNull((e) => e.korean == value.trim());
  }

  /// 한글(한자) 형식으로 변환
  String toKoreanHanja() => '$korean($hanja)';
}

// ═══════════════════════════════════════════════════════════════════════════
// 오행 (Five Elements)
// ═══════════════════════════════════════════════════════════════════════════

/// 오행 열거형
enum Oheng {
  wood('木', '목'),
  fire('火', '화'),
  earth('土', '토'),
  metal('金', '금'),
  water('水', '수');

  final String hanja;
  final String korean;

  const Oheng(this.hanja, this.korean);

  /// 상생 관계 (나를 생해주는 오행)
  Oheng get generateMe {
    switch (this) {
      case Oheng.wood:
        return Oheng.water; // 수생목
      case Oheng.fire:
        return Oheng.wood; // 목생화
      case Oheng.earth:
        return Oheng.fire; // 화생토
      case Oheng.metal:
        return Oheng.earth; // 토생금
      case Oheng.water:
        return Oheng.metal; // 금생수
    }
  }

  /// 상생 관계 (내가 생해주는 오행)
  Oheng get iGenerate {
    switch (this) {
      case Oheng.wood:
        return Oheng.fire; // 목생화
      case Oheng.fire:
        return Oheng.earth; // 화생토
      case Oheng.earth:
        return Oheng.metal; // 토생금
      case Oheng.metal:
        return Oheng.water; // 금생수
      case Oheng.water:
        return Oheng.wood; // 수생목
    }
  }

  /// 상극 관계 (나를 극하는 오행)
  Oheng get controlMe {
    switch (this) {
      case Oheng.wood:
        return Oheng.metal; // 금극목
      case Oheng.fire:
        return Oheng.water; // 수극화
      case Oheng.earth:
        return Oheng.wood; // 목극토
      case Oheng.metal:
        return Oheng.fire; // 화극금
      case Oheng.water:
        return Oheng.earth; // 토극수
    }
  }

  /// 상극 관계 (내가 극하는 오행)
  Oheng get iControl {
    switch (this) {
      case Oheng.wood:
        return Oheng.earth; // 목극토
      case Oheng.fire:
        return Oheng.metal; // 화극금
      case Oheng.earth:
        return Oheng.water; // 토극수
      case Oheng.metal:
        return Oheng.wood; // 금극목
      case Oheng.water:
        return Oheng.fire; // 수극화
    }
  }

  /// 문자열에서 오행 파싱
  static Oheng? fromString(String? value) {
    if (value == null) return null;
    return Oheng.values.firstWhereOrNull(
      (e) => e.hanja == value || e.korean == value || e.name == value.toLowerCase(),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 합충형해파 계산 로직
// ═══════════════════════════════════════════════════════════════════════════

/// 천간합 (5가지)
/// 갑기합토, 을경합금, 병신합수, 정임합목, 무계합화
class CheonganHap {
  /// 천간합 조합과 결과 오행 (String key 방식 - Set equality 문제 해결)
  static const Map<String, (String, Oheng)> _hapPairs = {
    'gap-gi': ('갑기합토', Oheng.earth),
    'eul-gyeong': ('을경합금', Oheng.metal),
    'byeong-sin': ('병신합수', Oheng.water),
    'im-jeong': ('정임합목', Oheng.wood),
    'gye-mu': ('무계합화', Oheng.fire),
  };

  /// 두 천간을 정렬된 String key로 변환
  static String _makeKey(Cheongan a, Cheongan b) {
    final list = [a.name, b.name]..sort();
    return list.join('-');
  }

  /// 두 천간이 합인지 확인
  static (String, Oheng)? checkHap(Cheongan a, Cheongan b) {
    return _hapPairs[_makeKey(a, b)];
  }

  /// 두 천간이 합인지만 확인 (이름 반환)
  static String? checkHapName(Cheongan a, Cheongan b) {
    final result = checkHap(a, b);
    return result?.$1;
  }
}

/// 지지 육합 (6가지)
/// 자축합토, 인해합목, 묘술합화, 진유합금, 사신합수, 오미합화
class JijiYukhap {
  /// String key 방식 - Set equality 문제 해결
  static const Map<String, (String, Oheng)> _hapPairs = {
    'chuk-ja': ('자축합토', Oheng.earth),
    'hae-in_': ('인해합목', Oheng.wood),
    'myo-sul': ('묘술합화', Oheng.fire),
    'jin-yu': ('진유합금', Oheng.metal),
    'sa-sin_': ('사신합수', Oheng.water),
    'mi-o': ('오미합화', Oheng.fire), // 또는 토
  };

  /// 두 지지를 정렬된 String key로 변환
  static String _makeKey(Jiji a, Jiji b) {
    final list = [a.name, b.name]..sort();
    return list.join('-');
  }

  static (String, Oheng)? checkHap(Jiji a, Jiji b) {
    return _hapPairs[_makeKey(a, b)];
  }

  static String? checkHapName(Jiji a, Jiji b) {
    return checkHap(a, b)?.$1;
  }
}

/// 지지 삼합 (4가지)
/// 인오술합화, 해묘미합목, 사유축합금, 신자진합수
class JijiSamhap {
  /// List 방식으로 변경 - for-loop 검색용
  static const List<(Set<Jiji>, String, Oheng)> _hapTriplesList = [
    ({Jiji.in_, Jiji.o, Jiji.sul}, '인오술합화', Oheng.fire),
    ({Jiji.hae, Jiji.myo, Jiji.mi}, '해묘미합목', Oheng.wood),
    ({Jiji.sa, Jiji.yu, Jiji.chuk}, '사유축합금', Oheng.metal),
    ({Jiji.sin_, Jiji.ja, Jiji.jin}, '신자진합수', Oheng.water),
  ];

  /// 삼합의 중심(왕지) - 가장 강한 오행
  static const Map<Jiji, (String, Oheng)> centerJiji = {
    Jiji.o: ('오(午) - 화국 왕지', Oheng.fire),
    Jiji.myo: ('묘(卯) - 목국 왕지', Oheng.wood),
    Jiji.yu: ('유(酉) - 금국 왕지', Oheng.metal),
    Jiji.ja: ('자(子) - 수국 왕지', Oheng.water),
  };

  /// 두 지지가 반합인지 확인 (삼합의 2개)
  static String? checkBanhap(Jiji a, Jiji b) {
    if (a == b) return null; // 같은 지지는 반합 아님
    for (final entry in _hapTriplesList) {
      if (entry.$1.contains(a) && entry.$1.contains(b)) {
        final missingJiji = entry.$1.where((j) => j != a && j != b).first;
        return '${entry.$2.substring(0, 3)} 반합 (${missingJiji.korean} 부재)';
      }
    }
    return null;
  }

  /// 세 지지가 삼합인지 확인 (3개가 모두 달라야 함)
  static (String, Oheng)? checkSamhap(Jiji a, Jiji b, Jiji c) {
    // 3개가 모두 다른 지지여야 삼합 성립 (중복 방지)
    if (a == b || b == c || a == c) return null;
    for (final entry in _hapTriplesList) {
      if (entry.$1.contains(a) && entry.$1.contains(b) && entry.$1.contains(c)) {
        return (entry.$2, entry.$3);
      }
    }
    return null;
  }
}

/// 지지 방합 (4가지)
/// 인묘진합목, 사오미합화, 신유술합금, 해자축합수
class JijiBanghap {
  /// List 방식으로 변경 - for-loop 검색용
  static const List<(Set<Jiji>, String, Oheng)> _hapTriplesList = [
    ({Jiji.in_, Jiji.myo, Jiji.jin}, '인묘진합목', Oheng.wood),
    ({Jiji.sa, Jiji.o, Jiji.mi}, '사오미합화', Oheng.fire),
    ({Jiji.sin_, Jiji.yu, Jiji.sul}, '신유술합금', Oheng.metal),
    ({Jiji.hae, Jiji.ja, Jiji.chuk}, '해자축합수', Oheng.water),
  ];

  /// 두 지지가 방합의 일부인지 확인
  static String? checkPartialBanghap(Jiji a, Jiji b) {
    if (a == b) return null; // 같은 지지는 방합 아님
    for (final entry in _hapTriplesList) {
      if (entry.$1.contains(a) && entry.$1.contains(b)) {
        return '${entry.$2.substring(0, 3)} 방합의 일부';
      }
    }
    return null;
  }

  /// 세 지지가 방합인지 확인 (완전한 방합, 3개가 모두 달라야 함)
  static (String, Oheng)? checkBanghap(Jiji a, Jiji b, Jiji c) {
    // 3개가 모두 다른 지지여야 방합 성립 (중복 방지)
    if (a == b || b == c || a == c) return null;
    for (final entry in _hapTriplesList) {
      if (entry.$1.contains(a) && entry.$1.contains(b) && entry.$1.contains(c)) {
        return (entry.$2, entry.$3);
      }
    }
    return null;
  }
}

/// 지지 육충 (6가지)
/// 자오충, 축미충, 인신충, 묘유충, 진술충, 사해충
class JijiChung {
  /// String key 방식 - Set equality 문제 해결
  static const Map<String, String> _chungPairs = {
    'ja-o': '자오충',
    'chuk-mi': '축미충',
    'in_-sin_': '인신충',
    'myo-yu': '묘유충',
    'jin-sul': '진술충',
    'hae-sa': '사해충',
  };

  /// 충의 심각도 (1-10)
  static const Map<String, int> _chungSeverity = {
    'ja-o': 9, // 수화 충돌 - 매우 강함
    'in_-sin_': 8, // 목금 충돌 - 강함
    'myo-yu': 8, // 목금 충돌 - 강함
    'hae-sa': 7, // 화수 충돌 - 강함
    'chuk-mi': 5, // 토토 충돌 - 중간
    'jin-sul': 5, // 토토 충돌 - 중간
  };

  /// 두 지지를 정렬된 String key로 변환
  static String _makeKey(Jiji a, Jiji b) {
    final list = [a.name, b.name]..sort();
    return list.join('-');
  }

  static String? checkChung(Jiji a, Jiji b) {
    return _chungPairs[_makeKey(a, b)];
  }

  static int? getChungSeverity(Jiji a, Jiji b) {
    return _chungSeverity[_makeKey(a, b)];
  }
}

/// 지지 형 (삼형살, 자묘형, 자형)
class JijiHyung {
  // 삼형살 - 3개 지지 조합 (for-loop으로 검사)
  static const List<(Set<Jiji>, String)> _samhyungList = [
    ({Jiji.in_, Jiji.sa, Jiji.sin_}, '인사신 삼형살 (무은지형)'),
    ({Jiji.chuk, Jiji.sul, Jiji.mi}, '축술미 삼형살 (지세지형)'),
  ];

  // 자묘형 (무례지형) - String key 방식
  static const String _jaMyoKey = 'ja-myo';

  // 자형 (자기 형벌)
  static const Set<Jiji> jaHyungJiji = {
    Jiji.jin, // 진진자형
    Jiji.o, // 오오자형
    Jiji.yu, // 유유자형
    Jiji.hae, // 해해자형
  };

  /// 두 지지를 정렬된 String key로 변환
  static String _makeKey(Jiji a, Jiji b) {
    final list = [a.name, b.name]..sort();
    return list.join('-');
  }

  /// 두 지지가 형인지 확인
  /// 삼형살은 3개가 모두 모여야만 성립 → checkCompleteSamhyung 사용
  static String? checkHyung(Jiji a, Jiji b) {
    // 자묘형 - String key 비교
    if (_makeKey(a, b) == _jaMyoKey) return '자묘형 (무례지형)';
    // 자형
    if (a == b && jaHyungJiji.contains(a)) return '${a.korean}${a.korean}자형';
    // 삼형살은 2개만으로 성립하지 않음 (3개 완전 조합만 인정)
    return null;
  }

  /// 완전 삼형살 체크 (3개 지지가 모두 있는 경우만)
  ///
  /// 두 사람의 지지를 합쳐서 인사신/축술미 완전 삼형살 확인
  /// 삼형살이 완전히 성립하면 매우 강한 흉력
  /// ⚠️ 한 사람의 사주에서만 3개가 모이는 경우는 개인 삼형살이므로 궁합에서 제외
  static List<String> checkCompleteSamhyung(Set<Jiji> myJijis, Set<Jiji> targetJijis) {
    final allJijis = {...myJijis, ...targetJijis};
    final results = <String>[];
    for (final entry in _samhyungList) {
      if (entry.$1.every((j) => allJijis.contains(j))) {
        // 한 사람에게서만 모두 나오면 개인 삼형살 → 궁합 제외
        final allInMy = entry.$1.every((j) => myJijis.contains(j));
        final allInTarget = entry.$1.every((j) => targetJijis.contains(j));
        if (allInMy || allInTarget) continue;
        results.add(entry.$2);
      }
    }
    return results;
  }
}

/// 지지 해 (6가지)
/// 술유해, 신해해, 미자해, 축오해, 인사해, 묘진해
class JijiHae {
  /// String key 방식 - Set equality 문제 해결
  static const Map<String, String> _haePairs = {
    'sul-yu': '술유해',
    'hae-sin_': '신해해',
    'ja-mi': '미자해',
    'chuk-o': '축오해',
    'in_-sa': '인사해',
    'jin-myo': '묘진해',
  };

  /// 두 지지를 정렬된 String key로 변환
  static String _makeKey(Jiji a, Jiji b) {
    final list = [a.name, b.name]..sort();
    return list.join('-');
  }

  static String? checkHae(Jiji a, Jiji b) {
    return _haePairs[_makeKey(a, b)];
  }
}

/// 지지 파 (6가지)
/// 유자파, 축진파, 인해파, 묘오파, 신사파, 술미파
class JijiPa {
  /// String key 방식 - Set equality 문제 해결
  static const Map<String, String> _paPairs = {
    'ja-yu': '유자파',
    'chuk-jin': '축진파',
    'hae-in_': '인해파',
    'myo-o': '묘오파',
    'sa-sin_': '신사파',
    'mi-sul': '술미파',
  };

  /// 두 지지를 정렬된 String key로 변환
  static String _makeKey(Jiji a, Jiji b) {
    final list = [a.name, b.name]..sort();
    return list.join('-');
  }

  static String? checkPa(Jiji a, Jiji b) {
    return _paPairs[_makeKey(a, b)];
  }
}

/// 원진살 (怨嗔殺) - 6쌍 (양방향 12가지)
///
/// 원진살: 12지지를 원형으로 배치했을 때 서로 마주보며 원망하는 관계
/// 자↔미, 축↔오, 인↔유, 묘↔신, 진↔해, 사↔술
///
/// ⚠️ 주의: 원진(怨嗔)과 해(害/육해)는 다른 개념
/// - 원진: 자미, 축오, 인유, 묘신, 진해, 사술
/// - 해(害): 자미, 축오, 인사, 묘진, 신해, 유술
/// 자미·축오는 겹치지만 나머지 4쌍은 다름
class Wonjin {
  static const Map<Jiji, Jiji> wonjinPairs = {
    Jiji.ja: Jiji.mi, // 자미 원진 (쥐↔양)
    Jiji.mi: Jiji.ja, // 미자 원진
    Jiji.chuk: Jiji.o, // 축오 원진 (소↔말)
    Jiji.o: Jiji.chuk, // 오축 원진
    Jiji.in_: Jiji.yu, // 인유 원진 (범↔닭)
    Jiji.yu: Jiji.in_, // 유인 원진
    Jiji.myo: Jiji.sin_, // 묘신 원진 (토끼↔원숭이)
    Jiji.sin_: Jiji.myo, // 신묘 원진
    Jiji.jin: Jiji.hae, // 진해 원진 (용↔돼지)
    Jiji.hae: Jiji.jin, // 해진 원진
    Jiji.sa: Jiji.sul, // 사술 원진 (뱀↔개)
    Jiji.sul: Jiji.sa, // 술사 원진
  };

  static bool checkWonjin(Jiji a, Jiji b) {
    return wonjinPairs[a] == b;
  }

  static String? getWonjinName(Jiji a, Jiji b) {
    if (checkWonjin(a, b)) {
      return '${a.korean}${b.korean} 원진';
    }
    return null;
  }
}

/// 천간충 (天干沖/칠충) - 4가지
///
/// 천간의 정반대 방위, 음양이 같은 오행의 충돌
/// 갑경충, 을신충, 병임충, 정계충
class CheonganChung {
  static const Map<String, String> _chungPairs = {
    'gap-gyeong': '갑경충', // 木 vs 金 (양)
    'eul-sin': '을신충', // 木 vs 金 (음)
    'byeong-im': '병임충', // 火 vs 水 (양)
    'gye-jeong': '정계충', // 火 vs 水 (음)
  };

  static String _makeKey(Cheongan a, Cheongan b) {
    final list = [a.name, b.name]..sort();
    return list.join('-');
  }

  static String? checkChung(Cheongan a, Cheongan b) {
    return _chungPairs[_makeKey(a, b)];
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 궁합 계산 결과
// ═══════════════════════════════════════════════════════════════════════════

/// 합충형해파 분석 결과
class HapchungAnalysis {
  // ═══════════════════════════════════════════════════════════════════════════
  // 합 (긍정적) - 세분화
  // ═══════════════════════════════════════════════════════════════════════════

  /// 천간합 (오합) - 갑기합토, 을경합금, 병신합수, 정임합목, 무계합화
  final List<String> cheonganHap;

  /// 지지 육합 - 자축합토, 인해합목, 묘술합화, 진유합금, 사신합수, 오미합화
  final List<String> yukhap;

  /// 지지 삼합 - 인오술합화, 해묘미합목, 사유축합금, 신자진합수 (3개 완전)
  final List<String> samhap;

  /// 지지 반합 - 삼합의 2개만 있는 경우
  final List<String> banhap;

  /// 지지 방합 - 인묘진합목, 사오미합화, 신유술합금, 해자축합수
  final List<String> banghap;

  /// [하위호환] 모든 합을 통합한 리스트
  List<String> get hap => [
    ...cheonganHap.map((e) => '[천간합] $e'),
    ...yukhap.map((e) => '[육합] $e'),
    ...samhap.map((e) => '[삼합] $e'),
    ...banhap.map((e) => '[반합] $e'),
    ...banghap.map((e) => '[방합] $e'),
  ];

  // ═══════════════════════════════════════════════════════════════════════════
  // 충/형/해/파/원진 (부정적)
  // ═══════════════════════════════════════════════════════════════════════════

  /// 천간충 (부정적 - 정신적 충돌)
  final List<String> cheonganChung;

  /// 지지충 (부정적 - 가장 강함)
  final List<String> chung;

  /// 형 (부정적)
  final List<String> hyung;

  /// 해 (부정적)
  final List<String> hae;

  /// 파 (부정적)
  final List<String> pa;

  /// 원진 (부정적)
  final List<String> wonjin;

  const HapchungAnalysis({
    required this.cheonganHap,
    required this.yukhap,
    required this.samhap,
    required this.banhap,
    required this.banghap,
    required this.cheonganChung,
    required this.chung,
    required this.hyung,
    required this.hae,
    required this.pa,
    required this.wonjin,
  });

  /// 긍정적 요소 개수 (모든 합 합산)
  int get positiveCount =>
      cheonganHap.length + yukhap.length + samhap.length + banhap.length + banghap.length;

  /// 부정적 요소 개수
  int get negativeCount =>
      cheonganChung.length + chung.length + hyung.length + hae.length + pa.length + wonjin.length;

  /// JSON 변환 - 한글(한자) 형식으로 DB 저장
  Map<String, dynamic> toJson() => {
        // 합 세분화 (각각 별도 필드)
        'cheongan_hap': _toHanjaFormat(cheonganHap, 'cheongan_hap'),
        'yukhap': _toHanjaFormat(yukhap, 'yukhap'),
        'samhap': _toHanjaFormat(samhap, 'samhap'),
        'banhap': _toHanjaFormat(banhap, 'banhap'),
        'banghap': _toHanjaFormat(banghap, 'banghap'),
        // 하위호환: 모든 합을 통합한 hap 필드
        'hap': _toHanjaFormat(hap, 'hap'),
        // 천간충/지지충/형/해/파/원진
        'cheongan_chung': _toHanjaFormat(cheonganChung, 'cheongan_chung'),
        'chung': _toHanjaFormat(chung, 'chung'),
        'hyung': _toHanjaFormat(hyung, 'hyung'),
        'hae': _toHanjaFormat(hae, 'hae'),
        'pa': _toHanjaFormat(pa, 'pa'),
        'wonjin': _toHanjaFormat(wonjin, 'wonjin'),
      };

  /// 한글(한자) 형식으로 변환
  /// 예: "년지↔월지: 자축합토" → "년지(年支)↔월지(月支): 자축합토(子丑合土)"
  List<String> _toHanjaFormat(List<String> items, String type) {
    return items.map((item) {
      // 위치 라벨 한자 변환
      String result = item
          .replaceAll('년간', '년간(年干)')
          .replaceAll('월간', '월간(月干)')
          .replaceAll('일간', '일간(日干)')
          .replaceAll('시간', '시간(時干)')
          .replaceAll('년지', '년지(年支)')
          .replaceAll('월지', '월지(月支)')
          .replaceAll('일지', '일지(日支)')
          .replaceAll('시지', '시지(時支)');

      // 합충형해파 용어 한자 변환
      result = _addHanjaToTerms(result, type);

      return result;
    }).toList();
  }

  /// 사주 용어에 한자 추가
  String _addHanjaToTerms(String text, String type) {
    // 천간합
    text = text
        .replaceAll('갑기합토', '갑기합토(甲己合土)')
        .replaceAll('을경합금', '을경합금(乙庚合金)')
        .replaceAll('병신합수', '병신합수(丙辛合水)')
        .replaceAll('정임합목', '정임합목(丁壬合木)')
        .replaceAll('무계합화', '무계합화(戊癸合火)');

    // 천간충
    text = text
        .replaceAll('갑경충', '갑경충(甲庚沖)')
        .replaceAll('을신충', '을신충(乙辛沖)')
        .replaceAll('병임충', '병임충(丙壬沖)')
        .replaceAll('정계충', '정계충(丁癸沖)');

    // 지지 육합
    text = text
        .replaceAll('자축합토', '자축합토(子丑合土)')
        .replaceAll('인해합목', '인해합목(寅亥合木)')
        .replaceAll('묘술합화', '묘술합화(卯戌合火)')
        .replaceAll('진유합금', '진유합금(辰酉合金)')
        .replaceAll('사신합수', '사신합수(巳申合水)')
        .replaceAll('오미합화', '오미합화(午未合火)');

    // 지지 충
    text = text
        .replaceAll('자오충', '자오충(子午沖)')
        .replaceAll('축미충', '축미충(丑未沖)')
        .replaceAll('인신충', '인신충(寅申沖)')
        .replaceAll('묘유충', '묘유충(卯酉沖)')
        .replaceAll('진술충', '진술충(辰戌沖)')
        .replaceAll('사해충', '사해충(巳亥沖)');

    // 지지 형
    text = text
        .replaceAll('인사신 삼형살', '인사신 삼형살(寅巳申 三刑殺)')
        .replaceAll('축술미 삼형살', '축술미 삼형살(丑戌未 三刑殺)')
        .replaceAll('자묘형', '자묘형(子卯刑)')
        .replaceAll('무은지형', '무은지형(無恩之刑)')
        .replaceAll('지세지형', '지세지형(持勢之刑)')
        .replaceAll('무례지형', '무례지형(無禮之刑)');

    // 자형
    text = text
        .replaceAll('진진자형', '진진자형(辰辰自刑)')
        .replaceAll('오오자형', '오오자형(午午自刑)')
        .replaceAll('유유자형', '유유자형(酉酉自刑)')
        .replaceAll('해해자형', '해해자형(亥亥自刑)');

    // 지지 해
    text = text
        .replaceAll('술유해', '술유해(戌酉害)')
        .replaceAll('신해해', '신해해(申亥害)')
        .replaceAll('미자해', '미자해(未子害)')
        .replaceAll('축오해', '축오해(丑午害)')
        .replaceAll('인사해', '인사해(寅巳害)')
        .replaceAll('묘진해', '묘진해(卯辰害)');

    // 지지 파
    text = text
        .replaceAll('유자파', '유자파(酉子破)')
        .replaceAll('축진파', '축진파(丑辰破)')
        .replaceAll('인해파', '인해파(寅亥破)')
        .replaceAll('묘오파', '묘오파(卯午破)')
        .replaceAll('신사파', '신사파(申巳破)')
        .replaceAll('술미파', '술미파(戌未破)');

    // 원진
    text = text
        .replaceAll('자미 원진', '자미 원진(子未怨嗔)')
        .replaceAll('축오 원진', '축오 원진(丑午怨嗔)')
        .replaceAll('인사 원진', '인사 원진(寅巳怨嗔)')
        .replaceAll('묘진 원진', '묘진 원진(卯辰怨嗔)')
        .replaceAll('진묘 원진', '진묘 원진(辰卯怨嗔)')
        .replaceAll('사인 원진', '사인 원진(巳寅怨嗔)')
        .replaceAll('오축 원진', '오축 원진(午丑怨嗔)')
        .replaceAll('미자 원진', '미자 원진(未子怨嗔)')
        .replaceAll('신해 원진', '신해 원진(申亥怨嗔)')
        .replaceAll('유술 원진', '유술 원진(酉戌怨嗔)')
        .replaceAll('술유 원진', '술유 원진(戌酉怨嗔)')
        .replaceAll('해신 원진', '해신 원진(亥申怨嗔)');

    // 반합 (삼합 일부)
    text = text
        .replaceAll('인오술 반합', '인오술 반합(寅午戌 半合)')
        .replaceAll('인오 반합', '인오 반합(寅午 半合)')
        .replaceAll('오술 반합', '오술 반합(午戌 半合)')
        .replaceAll('인술 반합', '인술 반합(寅戌 半合)')
        .replaceAll('해묘미 반합', '해묘미 반합(亥卯未 半合)')
        .replaceAll('해묘 반합', '해묘 반합(亥卯 半合)')
        .replaceAll('묘미 반합', '묘미 반합(卯未 半合)')
        .replaceAll('해미 반합', '해미 반합(亥未 半合)')
        .replaceAll('사유축 반합', '사유축 반합(巳酉丑 半合)')
        .replaceAll('사유 반합', '사유 반합(巳酉 半合)')
        .replaceAll('유축 반합', '유축 반합(酉丑 半合)')
        .replaceAll('사축 반합', '사축 반합(巳丑 半合)')
        .replaceAll('신자진 반합', '신자진 반합(申子辰 半合)')
        .replaceAll('신자 반합', '신자 반합(申子 半合)')
        .replaceAll('자진 반합', '자진 반합(子辰 半合)')
        .replaceAll('신진 반합', '신진 반합(申辰 半合)');

    // 삼합 (3개 완전)
    text = text
        .replaceAll('인오술합화', '인오술합화(寅午戌合火)')
        .replaceAll('해묘미합목', '해묘미합목(亥卯未合木)')
        .replaceAll('사유축합금', '사유축합금(巳酉丑合金)')
        .replaceAll('신자진합수', '신자진합수(申子辰合水)');

    // 방합 (계절/방위)
    text = text
        .replaceAll('인묘진합목', '인묘진합목(寅卯辰合木)')
        .replaceAll('인묘진 방합', '인묘진 방합(寅卯辰 方合)')
        .replaceAll('인묘 방합', '인묘 방합(寅卯 方合)')
        .replaceAll('묘진 방합', '묘진 방합(卯辰 方合)')
        .replaceAll('인진 방합', '인진 방합(寅辰 方合)')
        .replaceAll('사오미합화', '사오미합화(巳午未合火)')
        .replaceAll('사오미 방합', '사오미 방합(巳午未 方合)')
        .replaceAll('사오 방합', '사오 방합(巳午 方合)')
        .replaceAll('오미 방합', '오미 방합(午未 方合)')
        .replaceAll('사미 방합', '사미 방합(巳未 方合)')
        .replaceAll('신유술합금', '신유술합금(申酉戌合金)')
        .replaceAll('신유술 방합', '신유술 방합(申酉戌 方合)')
        .replaceAll('신유 방합', '신유 방합(申酉 方合)')
        .replaceAll('유술 방합', '유술 방합(酉戌 方合)')
        .replaceAll('신술 방합', '신술 방합(申戌 方合)')
        .replaceAll('해자축합수', '해자축합수(亥子丑合水)')
        .replaceAll('해자축 방합', '해자축 방합(亥子丑 方合)')
        .replaceAll('해자 방합', '해자 방합(亥子 方合)')
        .replaceAll('자축 방합', '자축 방합(子丑 方合)')
        .replaceAll('해축 방합', '해축 방합(亥丑 方合)');

    return text;
  }
}

/// 궁합 계산 결과
class CompatibilityResult {
  /// 전체 점수 (0-100)
  final int overallScore;

  /// 카테고리별 점수
  final Map<String, int> categoryScores;

  /// 강점 목록
  final List<String> strengths;

  /// 도전/주의점 목록
  final List<String> challenges;

  /// 합충형해파 상세 분석
  final HapchungAnalysis hapchungDetails;

  /// 요약 설명
  final String summary;

  const CompatibilityResult({
    required this.overallScore,
    required this.categoryScores,
    required this.strengths,
    required this.challenges,
    required this.hapchungDetails,
    required this.summary,
  });

  /// JSON 변환
  Map<String, dynamic> toJson() => {
        'overall_score': overallScore,
        'category_scores': categoryScores,
        'strengths': strengths,
        'challenges': challenges,
        'hapchung_details': hapchungDetails.toJson(),
        'summary': summary,
      };
}

// ═══════════════════════════════════════════════════════════════════════════
// 궁합 계산기 메인 클래스
// ═══════════════════════════════════════════════════════════════════════════

/// 궁합 계산기
///
/// 두 사람의 saju_analyses 데이터를 받아 궁합을 계산합니다.
class CompatibilityCalculator {
  /// 두 사람의 사주로 궁합 계산
  ///
  /// ## 파라미터
  /// - `mySaju`: 나의 saju_analyses 데이터 (Map)
  /// - `targetSaju`: 상대의 saju_analyses 데이터 (Map)
  /// - `relationType`: 관계 유형 (romantic_partner, family_parent 등)
  ///
  /// ## 반환
  /// `CompatibilityResult` - 궁합 분석 결과
  CompatibilityResult calculate({
    required Map<String, dynamic> mySaju,
    required Map<String, dynamic> targetSaju,
    required String relationType,
  }) {
    print('[CompatibilityCalculator] 🧮 궁합 계산 시작');
    print('  - relationType: $relationType');

    // 1. 사주 데이터 파싱
    final myParsed = _parseSajuData(mySaju);
    final targetParsed = _parseSajuData(targetSaju);

    print('  - 나의 사주: ${_sajuToString(myParsed)}');
    print('  - 상대 사주: ${_sajuToString(targetParsed)}');

    // 2. 합충형해파 분석
    final hapchungAnalysis = _analyzeHapchung(myParsed, targetParsed);
    print('  - 합: ${hapchungAnalysis.hap.length}개');
    print('  - 충: ${hapchungAnalysis.chung.length}개');
    print('  - 형: ${hapchungAnalysis.hyung.length}개');
    print('  - 해: ${hapchungAnalysis.hae.length}개');
    print('  - 파: ${hapchungAnalysis.pa.length}개');
    print('  - 원진: ${hapchungAnalysis.wonjin.length}개');

    // 3. 오행 상생상극 분석
    final ohengAnalysis = _analyzeOheng(myParsed, targetParsed);

    // 4. 일주 궁합 (일간 기준)
    final iljuAnalysis = _analyzeIlju(myParsed, targetParsed);

    // 5. 점수 계산
    final scores = _calculateScores(
      hapchungAnalysis: hapchungAnalysis,
      ohengAnalysis: ohengAnalysis,
      iljuAnalysis: iljuAnalysis,
      relationType: relationType,
    );

    // 6. 강점/도전 추출
    final strengths = _extractStrengths(hapchungAnalysis, ohengAnalysis, iljuAnalysis);
    final challenges = _extractChallenges(hapchungAnalysis, ohengAnalysis, iljuAnalysis);

    // 7. 요약 생성
    final summary = _generateSummary(
      overallScore: scores['overall']!,
      hapchungAnalysis: hapchungAnalysis,
      relationType: relationType,
    );

    print('[CompatibilityCalculator] ✅ 궁합 계산 완료: ${scores['overall']}점');

    return CompatibilityResult(
      overallScore: scores['overall']!,
      categoryScores: Map<String, int>.from(scores)..remove('overall'),
      strengths: strengths,
      challenges: challenges,
      hapchungDetails: hapchungAnalysis,
      summary: summary,
    );
  }

  /// 사주 데이터 파싱
  _ParsedSaju _parseSajuData(Map<String, dynamic> saju) {
    return _ParsedSaju(
      yearGan: Cheongan.fromKoreanHanja(saju['year_gan'] as String?),
      yearJi: Jiji.fromKoreanHanja(saju['year_ji'] as String?),
      monthGan: Cheongan.fromKoreanHanja(saju['month_gan'] as String?),
      monthJi: Jiji.fromKoreanHanja(saju['month_ji'] as String?),
      dayGan: Cheongan.fromKoreanHanja(saju['day_gan'] as String?),
      dayJi: Jiji.fromKoreanHanja(saju['day_ji'] as String?),
      hourGan: Cheongan.fromKoreanHanja(saju['hour_gan'] as String?),
      hourJi: Jiji.fromKoreanHanja(saju['hour_ji'] as String?),
    );
  }

  /// 사주를 문자열로 변환 (디버깅용)
  String _sajuToString(_ParsedSaju saju) {
    final year = '${saju.yearGan?.korean ?? '?'}${saju.yearJi?.korean ?? '?'}';
    final month = '${saju.monthGan?.korean ?? '?'}${saju.monthJi?.korean ?? '?'}';
    final day = '${saju.dayGan?.korean ?? '?'}${saju.dayJi?.korean ?? '?'}';
    final hour = '${saju.hourGan?.korean ?? '?'}${saju.hourJi?.korean ?? '?'}';
    return '$year $month $day $hour';
  }

  /// 합충형해파 분석
  HapchungAnalysis _analyzeHapchung(_ParsedSaju my, _ParsedSaju target) {
    // 합 세분화 리스트
    final cheonganHap = <String>[]; // 천간합 (오합)
    final yukhap = <String>[]; // 지지 육합
    final samhap = <String>[]; // 지지 삼합 (3개 완전)
    final banhap = <String>[]; // 지지 반합 (삼합 2개)
    final banghap = <String>[]; // 지지 방합

    // 부정적 요소 리스트
    final cheonganChung = <String>[]; // 천간충
    final chung = <String>[];
    final hyung = <String>[];
    final hae = <String>[];
    final pa = <String>[];
    final wonjin = <String>[];

    // ═══════════════════════════════════════════════════════════════════════
    // 천간 조합 분석 (천간합)
    // ═══════════════════════════════════════════════════════════════════════
    final myGans = [my.yearGan, my.monthGan, my.dayGan, my.hourGan];
    final targetGans = [target.yearGan, target.monthGan, target.dayGan, target.hourGan];
    final ganLabels = ['년간', '월간', '일간', '시간'];

    for (int i = 0; i < 4; i++) {
      for (int j = 0; j < 4; j++) {
        final myGan = myGans[i];
        final targetGan = targetGans[j];
        if (myGan == null || targetGan == null) continue;

        // 천간합 체크
        final hapResult = CheonganHap.checkHapName(myGan, targetGan);
        if (hapResult != null) {
          cheonganHap.add('${ganLabels[i]}↔${ganLabels[j]}: $hapResult');
        }

        // 천간충 체크
        final ganChungResult = CheonganChung.checkChung(myGan, targetGan);
        if (ganChungResult != null) {
          cheonganChung.add('${ganLabels[i]}↔${ganLabels[j]}: $ganChungResult');
        }
      }
    }

    // ═══════════════════════════════════════════════════════════════════════
    // 지지 조합 분석 (육합, 반합, 방합, 충, 형, 해, 파, 원진)
    // ═══════════════════════════════════════════════════════════════════════
    final myJis = [my.yearJi, my.monthJi, my.dayJi, my.hourJi];
    final targetJis = [target.yearJi, target.monthJi, target.dayJi, target.hourJi];
    final jiLabels = ['년지', '월지', '일지', '시지'];

    for (int i = 0; i < 4; i++) {
      for (int j = 0; j < 4; j++) {
        final myJi = myJis[i];
        final targetJi = targetJis[j];
        if (myJi == null || targetJi == null) continue;

        // 지지 육합 체크
        final yukhapResult = JijiYukhap.checkHapName(myJi, targetJi);
        if (yukhapResult != null) {
          yukhap.add('${jiLabels[i]}↔${jiLabels[j]}: $yukhapResult');
        }

        // 반합 체크 (삼합의 2개)
        final banhapResult = JijiSamhap.checkBanhap(myJi, targetJi);
        if (banhapResult != null) {
          banhap.add('${jiLabels[i]}↔${jiLabels[j]}: $banhapResult');
        }

        // 방합 체크 (같은 계절/방위)
        final banghapResult = JijiBanghap.checkPartialBanghap(myJi, targetJi);
        if (banghapResult != null) {
          banghap.add('${jiLabels[i]}↔${jiLabels[j]}: $banghapResult');
        }

        // 충 체크
        final chungResult = JijiChung.checkChung(myJi, targetJi);
        if (chungResult != null) {
          chung.add('${jiLabels[i]}↔${jiLabels[j]}: $chungResult');
        }

        // 형 체크
        final hyungResult = JijiHyung.checkHyung(myJi, targetJi);
        if (hyungResult != null) {
          hyung.add('${jiLabels[i]}↔${jiLabels[j]}: $hyungResult');
        }

        // 해 체크
        final haeResult = JijiHae.checkHae(myJi, targetJi);
        if (haeResult != null) {
          hae.add('${jiLabels[i]}↔${jiLabels[j]}: $haeResult');
        }

        // 파 체크
        final paResult = JijiPa.checkPa(myJi, targetJi);
        if (paResult != null) {
          pa.add('${jiLabels[i]}↔${jiLabels[j]}: $paResult');
        }

        // 원진 체크
        if (Wonjin.checkWonjin(myJi, targetJi)) {
          wonjin.add('${jiLabels[i]}↔${jiLabels[j]}: ${myJi.korean}${targetJi.korean} 원진');
        }
      }
    }

    // ═══════════════════════════════════════════════════════════════════════
    // 삼합/방합/삼형살 체크 - 두 사람 지지 합쳐서 확인
    // ⚠️ 개인 합충형해파 필터링: 한 사람에게서만 나오는 3원소 조합은 제외
    // ═══════════════════════════════════════════════════════════════════════
    final allJisWithOwner = <(Jiji, bool)>[]; // (jiji, isMine=true/false)
    for (final ji in myJis) {
      if (ji != null) allJisWithOwner.add((ji, true));
    }
    for (final ji in targetJis) {
      if (ji != null) allJisWithOwner.add((ji, false));
    }

    // 삼합 체크 (중복 제거를 위해 Set 사용)
    final foundSamhap = <String>{};
    for (int i = 0; i < allJisWithOwner.length; i++) {
      for (int j = i + 1; j < allJisWithOwner.length; j++) {
        for (int k = j + 1; k < allJisWithOwner.length; k++) {
          // 개인 필터: 최소 양쪽 각 1개씩 포함되어야 커플 삼합
          final owners = {allJisWithOwner[i].$2, allJisWithOwner[j].$2, allJisWithOwner[k].$2};
          if (owners.length < 2) continue;
          final result = JijiSamhap.checkSamhap(
            allJisWithOwner[i].$1, allJisWithOwner[j].$1, allJisWithOwner[k].$1,
          );
          if (result != null && !foundSamhap.contains(result.$1)) {
            foundSamhap.add(result.$1);
            samhap.add('${result.$1} (${result.$2.korean}국)');
          }
        }
      }
    }

    // ═══════════════════════════════════════════════════════════════════════
    // 방합 체크 (3개 완전 조합) - 개인 필터 적용
    // ═══════════════════════════════════════════════════════════════════════
    final foundBanghap = <String>{};
    for (int i = 0; i < allJisWithOwner.length; i++) {
      for (int j = i + 1; j < allJisWithOwner.length; j++) {
        for (int k = j + 1; k < allJisWithOwner.length; k++) {
          final owners = {allJisWithOwner[i].$2, allJisWithOwner[j].$2, allJisWithOwner[k].$2};
          if (owners.length < 2) continue;
          final result = JijiBanghap.checkBanghap(
            allJisWithOwner[i].$1, allJisWithOwner[j].$1, allJisWithOwner[k].$1,
          );
          if (result != null && !foundBanghap.contains(result.$1)) {
            foundBanghap.add(result.$1);
            banghap.insert(0, '${result.$1} (${result.$2.korean}방)');
          }
        }
      }
    }

    // ═══════════════════════════════════════════════════════════════════════
    // 완전 삼형살 체크 - 개인 삼형살 제외 (한 사람에게서만 3개 모이면 궁합 제외)
    // ═══════════════════════════════════════════════════════════════════════
    final myJisSet = myJis.whereType<Jiji>().toSet();
    final targetJisSet = targetJis.whereType<Jiji>().toSet();
    final completeSamhyung = JijiHyung.checkCompleteSamhyung(myJisSet, targetJisSet);
    hyung.addAll(completeSamhyung);

    return HapchungAnalysis(
      cheonganHap: cheonganHap,
      yukhap: yukhap,
      samhap: samhap,
      banhap: banhap,
      banghap: banghap,
      cheonganChung: cheonganChung,
      chung: chung,
      hyung: hyung,
      hae: hae,
      pa: pa,
      wonjin: wonjin,
    );
  }

  /// 오행 상생상극 분석
  Map<String, dynamic> _analyzeOheng(_ParsedSaju my, _ParsedSaju target) {
    final myDayGan = my.dayGan;
    final targetDayGan = target.dayGan;

    if (myDayGan == null || targetDayGan == null) {
      return {'compatible': true, 'reason': '일간 정보 없음'};
    }

    final myOheng = Oheng.fromString(myDayGan.oheng);
    final targetOheng = Oheng.fromString(targetDayGan.oheng);

    if (myOheng == null || targetOheng == null) {
      return {'compatible': true, 'reason': '오행 정보 없음'};
    }

    // 상생 관계
    if (myOheng.generateMe == targetOheng || myOheng.iGenerate == targetOheng) {
      return {
        'compatible': true,
        'type': 'sangsaeng',
        'reason': '${myOheng.korean}과 ${targetOheng.korean}은 상생 관계',
      };
    }

    // 동일 오행
    if (myOheng == targetOheng) {
      return {
        'compatible': true,
        'type': 'same',
        'reason': '둘 다 ${myOheng.korean} 오행으로 동질감',
      };
    }

    // 상극 관계
    if (myOheng.controlMe == targetOheng || myOheng.iControl == targetOheng) {
      return {
        'compatible': false,
        'type': 'sanggeuk',
        'reason': '${myOheng.korean}과 ${targetOheng.korean}은 상극 관계',
      };
    }

    return {'compatible': true, 'reason': '특별한 관계 없음'};
  }

  /// 일주 궁합 분석 (일간 + 일지)
  Map<String, dynamic> _analyzeIlju(_ParsedSaju my, _ParsedSaju target) {
    final result = <String, dynamic>{};

    // 일간 합 확인
    if (my.dayGan != null && target.dayGan != null) {
      final ganHap = CheonganHap.checkHapName(my.dayGan!, target.dayGan!);
      if (ganHap != null) {
        result['day_gan_hap'] = ganHap;
      }
    }

    // 일지 합 확인
    if (my.dayJi != null && target.dayJi != null) {
      final jiHap = JijiYukhap.checkHapName(my.dayJi!, target.dayJi!);
      if (jiHap != null) {
        result['day_ji_hap'] = jiHap;
      }

      // 일지 충 확인
      final jiChung = JijiChung.checkChung(my.dayJi!, target.dayJi!);
      if (jiChung != null) {
        result['day_ji_chung'] = jiChung;
      }
    }

    // 일주 쌍합 (일간합 + 일지합)
    if (result.containsKey('day_gan_hap') && result.containsKey('day_ji_hap')) {
      result['ssanghap'] = true;
      result['ssanghap_description'] = '일주 쌍합 - 최고의 궁합';
    }

    return result;
  }

  /// 점수 계산 (명리학 기반 가중치 v4)
  ///
  /// ## v4 변경사항
  /// - 기본 65점 (넉넉한 기본 점수)
  /// - 개인 합충형해파 필터링 적용
  /// - 위치별 가중치: 일주 x2.0, 월주 x1.5, 년주 x1.0, 시주 x0.7
  /// - 합거충(合去沖): 합이 강하면 충/형/해/파 감점 최대 50% 줄임
  /// - 삼형살: 개인 삼형살 제외, 커플 삼형살만 별도 감점
  /// - 모든 관계에서 합 보너스 상향
  /// - 기본 65점, 합 보너스/충 감점 후 30~97점 범위
  Map<String, int> _calculateScores({
    required HapchungAnalysis hapchungAnalysis,
    required Map<String, dynamic> ohengAnalysis,
    required Map<String, dynamic> iljuAnalysis,
    required String relationType,
  }) {
    final isRomantic = relationType.startsWith('romantic_');

    // ═══════════════════════════════════════════════════════════════
    // 기본 점수 65점 (넉넉한 기본)
    // ═══════════════════════════════════════════════════════════════
    const baseScore = 65;

    // ═══════════════════════════════════════════════════════════════
    // 합 보너스 (위치 가중치 적용)
    // 합력 순서: 방합(완전) ≫ 삼합(완전) ≫ 천간합 ≈ 육합 ≫ 반합
    // ═══════════════════════════════════════════════════════════════

    // 방합 (方合) - 같은 계절/방위, 가장 강한 합력 ★★★
    // 방합은 3개 지지가 같은 계절이므로 팡팡 줌
    double banghapScore = 0;
    for (final b in hapchungAnalysis.banghap) {
      final w = _getPositionWeight(b);
      banghapScore += b.contains('일부') ? 6 * w : 20 * w;
    }
    banghapScore = banghapScore.clamp(0, 32);

    // 삼합 (三合) - 3개 완전 조합 ★★
    double samhapScore = 0;
    for (final s in hapchungAnalysis.samhap) {
      samhapScore += 16 * _getPositionWeight(s);
    }
    samhapScore = samhapScore.clamp(0, 30);

    // 천간합 (天干合) - 정신적 교감
    double cheonganHapScore = 0;
    for (final h in hapchungAnalysis.cheonganHap) {
      cheonganHapScore += 9 * _getPositionWeight(h);
    }
    cheonganHapScore = cheonganHapScore.clamp(0, 25);

    // 육합 (六合) - 실생활 조화
    double yukhapScore = 0;
    for (final y in hapchungAnalysis.yukhap) {
      yukhapScore += 10 * _getPositionWeight(y);
    }
    yukhapScore = yukhapScore.clamp(0, 25);

    // 반합 (半合) - 삼합의 일부
    double banhapScore = 0;
    for (final b in hapchungAnalysis.banhap) {
      banhapScore += 6 * _getPositionWeight(b);
    }
    banhapScore = banhapScore.clamp(0, 18);

    double totalHapScore = banghapScore + samhapScore + cheonganHapScore + yukhapScore + banhapScore;
    totalHapScore = totalHapScore.clamp(0, 60);

    // ═══════════════════════════════════════════════════════════════
    // 감점 (위치 가중치 적용)
    //
    // 흉력 순서: 충 > 원진 > 형 > 해 > 파
    // 도화충(자오/묘유)은 모든 관계에서 끌림 요소 → 약감점
    // ═══════════════════════════════════════════════════════════════

    // 천간충 (天干沖) - 사상의 차이 (약한 감점)
    double cheonganChungPenalty = 0;
    for (final c in hapchungAnalysis.cheonganChung) {
      cheonganChungPenalty += 2.5 * _getPositionWeight(c);
    }
    cheonganChungPenalty = cheonganChungPenalty.clamp(0, 6);

    // 지지충 (沖) - 에너지 충돌
    double chungPenalty = 0;
    for (final c in hapchungAnalysis.chung) {
      final w = _getPositionWeight(c);
      // 도화충(자오/묘유): 끌림과 자극의 요소 → 약한 감점
      if (c.contains('자오충') || c.contains('묘유충')) {
        chungPenalty += 3 * w;
      }
      // 인신충/사해충: 변화의 에너지
      else if (c.contains('인신충') || c.contains('사해충')) {
        chungPenalty += 4 * w;
      }
      // 축미충/진술충: 토토 충돌 - 가장 약한 충
      else {
        chungPenalty += 2.5 * w;
      }
    }
    chungPenalty = chungPenalty.clamp(0, 14);

    // 형 (刑) - 자묘형/자형만 (삼형살은 별도 처리)
    double hyungPenalty = 0;
    double samhyungsalPenalty = 0; // 완전 삼형살 별도
    for (final h in hapchungAnalysis.hyung) {
      final w = _getPositionWeight(h);
      if (h.contains('삼형살')) {
        // 완전 삼형살: 별도 강한 감점 (합거충 적용 제한)
        samhyungsalPenalty += 14;
      } else if (h.contains('자묘형')) {
        hyungPenalty += 3 * w;
      } else if (h.contains('자형')) {
        hyungPenalty += 1.5 * w;
      } else {
        hyungPenalty += 2.5 * w;
      }
    }
    hyungPenalty = hyungPenalty.clamp(0, 8);
    samhyungsalPenalty = samhyungsalPenalty.clamp(0, 20);

    // 원진 (怨嗔) - 서로 꺼리는 관계
    double wonjinPenalty = 0;
    for (final w in hapchungAnalysis.wonjin) {
      wonjinPenalty += 3 * _getPositionWeight(w);
    }
    wonjinPenalty = wonjinPenalty.clamp(0, 8);

    // 해 (害) - 가까운 사이의 갈등
    double haePenalty = 0;
    for (final h in hapchungAnalysis.hae) {
      haePenalty += 2.5 * _getPositionWeight(h);
    }
    haePenalty = haePenalty.clamp(0, 6);

    // 파 (破) - 가장 약한 흉력
    double paPenalty = 0;
    for (final p in hapchungAnalysis.pa) {
      paPenalty += 1.5 * _getPositionWeight(p);
    }
    paPenalty = paPenalty.clamp(0, 4);

    // 일반 감점 합계 (삼형살 제외)
    double regularPenalty = cheonganChungPenalty + chungPenalty + hyungPenalty + wonjinPenalty + haePenalty + paPenalty;
    regularPenalty = regularPenalty.clamp(0, 22);

    // ═══════════════════════════════════════════════════════════════
    // 합거충(合去沖) - 합이 강하면 일반 감점 줄임
    // 명리학: 합이 충을 해소하는 원칙
    // v4: 합거충 효과 강화 (최대 50% 감소)
    // 완전 삼형살은 합거충 적용 제한 (최대 25% 감소)
    // ═══════════════════════════════════════════════════════════════
    if (totalHapScore > 10) {
      final reduction = ((totalHapScore - 10) / 40).clamp(0.0, 0.5);
      regularPenalty *= (1.0 - reduction);
    }
    // 완전 삼형살: 합이 아무리 많아도 최대 25%만 감소
    if (totalHapScore > 20 && samhyungsalPenalty > 0) {
      samhyungsalPenalty *= 0.75;
    }

    double totalPenalty = regularPenalty + samhyungsalPenalty;

    // ═══════════════════════════════════════════════════════════════
    // 오행 상생상극 (일간 기준)
    // ═══════════════════════════════════════════════════════════════
    int ohengScore = 0;
    if (ohengAnalysis['compatible'] == true) {
      if (ohengAnalysis['type'] == 'sangsaeng') {
        ohengScore = 10;
      } else if (ohengAnalysis['type'] == 'same') {
        ohengScore = 6;
      }
    } else if (ohengAnalysis['compatible'] == false) {
      ohengScore = -4;
    }

    // ═══════════════════════════════════════════════════════════════
    // 일주 특수 보너스/감점 (일간+일지는 궁합의 핵심)
    // ═══════════════════════════════════════════════════════════════
    int iljuBonus = 0;
    if (iljuAnalysis['ssanghap'] == true) {
      iljuBonus = 20; // 일주 쌍합: 최고
    } else if (iljuAnalysis.containsKey('day_gan_hap')) {
      iljuBonus = 12; // 일간합
    } else if (iljuAnalysis.containsKey('day_ji_hap')) {
      iljuBonus = 12; // 일지합
    }
    if (iljuAnalysis.containsKey('day_ji_chung')) {
      iljuBonus -= 6; // 일지충
    }

    // ═══════════════════════════════════════════════════════════════
    // 관계 가중치 (모든 관계에서 합 보너스 증폭)
    // ═══════════════════════════════════════════════════════════════
    double hapWeight = 1.15; // 기본: 모든 관계 1.15배
    if (isRomantic) {
      hapWeight = 1.3; // 연인: 1.3배
    } else if (relationType.startsWith('family_')) {
      hapWeight = 1.2; // 가족: 1.2배
    }

    // ═══════════════════════════════════════════════════════════════
    // 최종 점수 계산
    // ═══════════════════════════════════════════════════════════════
    int totalScore = baseScore +
        (totalHapScore * hapWeight).round() +
        ohengScore +
        iljuBonus -
        totalPenalty.round();

    // 점수 범위 제한 (30-97)
    totalScore = totalScore.clamp(30, 97);

    return {
      'overall': totalScore,
    };
  }

  /// 위치 가중치 계산
  ///
  /// 일주(일간/일지) 관련 합충이 가장 중요 → 높은 가중치
  /// "년간↔월지: 자축합토" 같은 포맷에서 위치 추출
  double _getPositionWeight(String entry) {
    final match = RegExp(r'(년|월|일|시)(간|지)↔(년|월|일|시)(간|지)').firstMatch(entry);
    if (match == null) return 1.0; // 위치 정보 없으면 기본 1.0
    final pos1 = match.group(1)!;
    final pos2 = match.group(3)!;
    return (_posValue(pos1) + _posValue(pos2)) / 2;
  }

  /// 주(柱)별 중요도 값
  double _posValue(String pos) {
    switch (pos) {
      case '일': return 2.0;  // 일주: 궁합의 핵심
      case '월': return 1.5;  // 월주: 사회적 관계
      case '년': return 1.0;  // 년주: 초년/외적 관계
      case '시': return 0.7;  // 시주: 말년/내적 관계
      default: return 1.0;
    }
  }

  /// 강점 추출
  List<String> _extractStrengths(
    HapchungAnalysis hapchung,
    Map<String, dynamic> oheng,
    Map<String, dynamic> ilju,
  ) {
    final strengths = <String>[];

    // 일주 쌍합
    if (ilju['ssanghap'] == true) {
      strengths.add('일주 쌍합: 최고의 인연으로 서로에게 운명적 끌림');
    }

    // 일간합
    if (ilju.containsKey('day_gan_hap')) {
      strengths.add('일간합: 마음이 잘 통하고 서로 이해하는 관계');
    }

    // 일지합
    if (ilju.containsKey('day_ji_hap')) {
      strengths.add('일지합: 일상에서의 조화와 편안함');
    }

    // 합이 많은 경우
    if (hapchung.hap.length >= 3) {
      strengths.add('다양한 합의 관계: 여러 면에서 서로 잘 맞음');
    } else if (hapchung.hap.isNotEmpty) {
      for (final hap in hapchung.hap.take(2)) {
        final parts = hap.split(': ');
        if (parts.length > 1) {
          final hapName = parts[1];
          if (hapName.contains('천간합')) {
            strengths.add('천간합: 정신적 교감이 좋은 관계');
          } else if (hapName.contains('육합')) {
            strengths.add('지지합: 실생활에서의 조화');
          }
        }
      }
    }

    // 오행 상생
    if (oheng['type'] == 'sangsaeng') {
      strengths.add('오행 상생: ${oheng['reason']}');
    }

    // 충이 없는 경우
    if (hapchung.chung.isEmpty && hapchung.wonjin.isEmpty) {
      strengths.add('충/원진 없음: 큰 갈등 요소 없이 안정적');
    }

    return strengths.isEmpty ? ['서로 존중하며 발전하는 관계'] : strengths;
  }

  /// 도전/주의점 추출
  List<String> _extractChallenges(
    HapchungAnalysis hapchung,
    Map<String, dynamic> oheng,
    Map<String, dynamic> ilju,
  ) {
    final challenges = <String>[];

    // 일지충
    if (ilju.containsKey('day_ji_chung')) {
      challenges.add('일지충: 일상에서 마찰이 생길 수 있어 배려 필요');
    }

    // 충
    for (final chung in hapchung.chung.take(2)) {
      final parts = chung.split(': ');
      if (parts.length > 1) {
        final chungName = parts[1];
        if (chungName.contains('자오충')) {
          challenges.add('자오충: 감정적 충돌 주의, 서로 양보 필요');
        } else if (chungName.contains('인신충')) {
          challenges.add('인신충: 의견 충돌 시 대화로 해결');
        } else {
          challenges.add('$chungName: 서로 다른 점을 인정하고 존중');
        }
      }
    }

    // 형
    if (hapchung.hyung.isNotEmpty) {
      challenges.add('형살: 서로에게 상처 주지 않도록 말조심');
    }

    // 원진
    if (hapchung.wonjin.isNotEmpty) {
      challenges.add('원진: 오해가 생기기 쉬우니 소통을 자주');
    }

    // 해/파
    if (hapchung.hae.isNotEmpty || hapchung.pa.isNotEmpty) {
      challenges.add('해/파살: 작은 갈등이 커지지 않도록 관리');
    }

    // 오행 상극
    if (oheng['compatible'] == false) {
      challenges.add('오행 상극: ${oheng['reason']} - 서로 보완 필요');
    }

    return challenges.isEmpty ? ['특별한 주의사항 없음'] : challenges;
  }

  /// 요약 생성
  String _generateSummary({
    required int overallScore,
    required HapchungAnalysis hapchungAnalysis,
    required String relationType,
  }) {
    String relationName;
    if (relationType.startsWith('romantic_')) {
      relationName = '연인';
    } else if (relationType.startsWith('family_')) {
      relationName = '가족';
    } else if (relationType.startsWith('work_')) {
      relationName = '업무';
    } else if (relationType.startsWith('friend_')) {
      relationName = '친구';
    } else {
      relationName = '인연';
    }

    if (overallScore >= 85) {
      return '아주 좋은 $relationName 궁합입니다. 서로에게 긍정적인 영향을 주는 인연으로, 함께할수록 발전합니다.';
    } else if (overallScore >= 70) {
      return '좋은 $relationName 궁합입니다. 서로 잘 맞는 부분이 많아 편안한 관계를 유지할 수 있습니다.';
    } else if (overallScore >= 55) {
      return '보통의 $relationName 궁합입니다. 서로의 다름을 인정하고 노력하면 좋은 관계가 됩니다.';
    } else if (overallScore >= 40) {
      return '노력이 필요한 $relationName 궁합입니다. 서로 이해하고 배려하는 마음이 중요합니다.';
    } else {
      return '도전적인 $relationName 궁합입니다. 인내심을 갖고 소통하면 성장의 기회가 됩니다.';
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 내부 클래스
// ═══════════════════════════════════════════════════════════════════════════

/// 파싱된 사주 데이터
class _ParsedSaju {
  final Cheongan? yearGan;
  final Jiji? yearJi;
  final Cheongan? monthGan;
  final Jiji? monthJi;
  final Cheongan? dayGan;
  final Jiji? dayJi;
  final Cheongan? hourGan;
  final Jiji? hourJi;

  const _ParsedSaju({
    this.yearGan,
    this.yearJi,
    this.monthGan,
    this.monthJi,
    this.dayGan,
    this.dayJi,
    this.hourGan,
    this.hourJi,
  });
}

// ═══════════════════════════════════════════════════════════════════════════
// 전역 인스턴스
// ═══════════════════════════════════════════════════════════════════════════

/// 전역 궁합 계산기 인스턴스
final compatibilityCalculator = CompatibilityCalculator();
