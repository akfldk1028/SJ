/// 공망(空亡) 테이블
/// 60갑자에서 천간 10개와 지지 12개의 조합에서 빠지는 2개의 지지
///
/// 공망은 기운이 비어있는 상태를 의미
/// 순(旬)별로 2개의 지지가 공망이 됨
library;

// ============================================================================
// 공망 정의
// ============================================================================

/// 공망 정보
class Gongmang {
  final String sunName; // 순 이름 (갑자순, 갑술순, ...)
  final String startGapja; // 순의 시작 갑자
  final String gongmang1; // 첫 번째 공망 지지
  final String gongmang2; // 두 번째 공망 지지

  const Gongmang({
    required this.sunName,
    required this.startGapja,
    required this.gongmang1,
    required this.gongmang2,
  });

  /// 특정 지지가 이 순의 공망인지 확인
  bool isGongmang(String ji) => gongmang1 == ji || gongmang2 == ji;
}

/// 6순 공망 테이블
const List<Gongmang> gongmangList = [
  // 갑자순 (갑자~계유): 공망 = 술, 해
  Gongmang(
    sunName: '갑자순',
    startGapja: '갑자',
    gongmang1: '술',
    gongmang2: '해',
  ),
  // 갑술순 (갑술~계미): 공망 = 신, 유
  Gongmang(
    sunName: '갑술순',
    startGapja: '갑술',
    gongmang1: '신',
    gongmang2: '유',
  ),
  // 갑신순 (갑신~계사): 공망 = 오, 미
  Gongmang(
    sunName: '갑신순',
    startGapja: '갑신',
    gongmang1: '오',
    gongmang2: '미',
  ),
  // 갑오순 (갑오~계묘): 공망 = 진, 사
  Gongmang(
    sunName: '갑오순',
    startGapja: '갑오',
    gongmang1: '진',
    gongmang2: '사',
  ),
  // 갑진순 (갑진~계축): 공망 = 인, 묘
  Gongmang(
    sunName: '갑진순',
    startGapja: '갑진',
    gongmang1: '인',
    gongmang2: '묘',
  ),
  // 갑인순 (갑인~계해): 공망 = 자, 축
  Gongmang(
    sunName: '갑인순',
    startGapja: '갑인',
    gongmang1: '자',
    gongmang2: '축',
  ),
];

// ============================================================================
// 60갑자 순서
// ============================================================================

/// 천간 순서
const List<String> _cheonganOrder = [
  '갑',
  '을',
  '병',
  '정',
  '무',
  '기',
  '경',
  '신',
  '임',
  '계',
];

/// 지지 순서
const List<String> _jijiOrder = [
  '자',
  '축',
  '인',
  '묘',
  '진',
  '사',
  '오',
  '미',
  '신',
  '유',
  '술',
  '해',
];

/// 60갑자 리스트 생성
List<String> _generateGapja60() {
  final result = <String>[];
  for (var i = 0; i < 60; i++) {
    final gan = _cheonganOrder[i % 10];
    final ji = _jijiOrder[i % 12];
    result.add('$gan$ji');
  }
  return result;
}

/// 60갑자 리스트
final List<String> gapja60List = _generateGapja60();

// ============================================================================
// 공망 계산
// ============================================================================

/// 갑자의 순(旬) 인덱스 계산 (0~5)
/// 각 순은 10개의 갑자로 구성
int getSunIndex(String gapja) {
  final index = gapja60List.indexOf(gapja);
  if (index == -1) {
    throw ArgumentError('유효하지 않은 갑자: $gapja');
  }
  return index ~/ 10;
}

/// 갑자로 공망 조회
Gongmang getGongmangByGapja(String gapja) {
  final sunIndex = getSunIndex(gapja);
  return gongmangList[sunIndex];
}

/// 천간+지지로 공망 조회
Gongmang getGongmang(String cheongan, String jiji) {
  return getGongmangByGapja('$cheongan$jiji');
}

/// 일주(일간+일지)의 공망 지지 조회
/// [dayGan] 일간
/// [dayJi] 일지
/// 반환: 공망인 지지 2개
List<String> getDayGongmang(String dayGan, String dayJi) {
  final gongmang = getGongmang(dayGan, dayJi);
  return [gongmang.gongmang1, gongmang.gongmang2];
}

/// 특정 지지가 공망인지 확인
/// [dayGan] 일간
/// [dayJi] 일지
/// [targetJi] 확인할 지지
bool isGongmangJi(String dayGan, String dayJi, String targetJi) {
  final gongmang = getGongmang(dayGan, dayJi);
  return gongmang.isGongmang(targetJi);
}

// ============================================================================
// 공망 해석
// ============================================================================

/// 궁성별 공망 해석
const Map<String, String> gongmangInterpretation = {
  '년지': '조상덕 부족, 유년기 어려움 가능성',
  '월지': '부모 인연 약함, 형제 관계 소원',
  '일지': '배우자 인연 약함, 결혼 생활 주의',
  '시지': '자녀 인연 약함, 노년 운 주의',
};

/// 공망 상태 분석
class GongmangAnalysis {
  final String pillarName; // 년/월/일/시
  final String jiji; // 해당 궁의 지지
  final bool isGongmang; // 공망 여부
  final String? interpretation; // 해석

  const GongmangAnalysis({
    required this.pillarName,
    required this.jiji,
    required this.isGongmang,
    this.interpretation,
  });
}

/// 사주 전체 공망 분석
/// [dayGan] 일간
/// [dayJi] 일지
/// [yearJi] 년지
/// [monthJi] 월지
/// [hourJi] 시지
List<GongmangAnalysis> analyzeAllGongmang({
  required String dayGan,
  required String dayJi,
  required String yearJi,
  required String monthJi,
  required String hourJi,
}) {
  final gongmangJijis = getDayGongmang(dayGan, dayJi);
  final result = <GongmangAnalysis>[];

  // 년지 분석
  final isYearGongmang = gongmangJijis.contains(yearJi);
  result.add(GongmangAnalysis(
    pillarName: '년지',
    jiji: yearJi,
    isGongmang: isYearGongmang,
    interpretation: isYearGongmang ? gongmangInterpretation['년지'] : null,
  ));

  // 월지 분석
  final isMonthGongmang = gongmangJijis.contains(monthJi);
  result.add(GongmangAnalysis(
    pillarName: '월지',
    jiji: monthJi,
    isGongmang: isMonthGongmang,
    interpretation: isMonthGongmang ? gongmangInterpretation['월지'] : null,
  ));

  // 일지는 자기 자신이므로 공망이 될 수 없음
  result.add(GongmangAnalysis(
    pillarName: '일지',
    jiji: dayJi,
    isGongmang: false,
    interpretation: null,
  ));

  // 시지 분석
  final isHourGongmang = gongmangJijis.contains(hourJi);
  result.add(GongmangAnalysis(
    pillarName: '시지',
    jiji: hourJi,
    isGongmang: isHourGongmang,
    interpretation: isHourGongmang ? gongmangInterpretation['시지'] : null,
  ));

  return result;
}

// ============================================================================
// 공망 유형
// ============================================================================

/// 공망 유형
/// - 진공(眞空): 일간의 음양과 공망지지의 음양이 일치할 때 (작용력 100%)
/// - 반공(半空): 일간의 음양과 공망지지의 음양이 불일치할 때 (작용력 50%)
/// - 해공(解空)/탈공(脫空): 충/합/형으로 공망이 해소될 때 (작용력 0%)
enum GongmangType {
  /// 진공(眞空) - 완전한 공망
  /// 양간(甲丙戊庚壬)이 양지(子寅辰午申戌)를 공망으로 가질 때
  /// 음간(乙丁己辛癸)이 음지(丑卯巳未酉亥)를 공망으로 가질 때
  jinGong('진공', '眞空', '일간과 공망지지의 음양이 일치하여 공망 작용이 강함'),

  /// 반공(半空) - 부분 공망
  /// 양간이 음지를 공망으로 가질 때
  /// 음간이 양지를 공망으로 가질 때
  banGong('반공', '半空', '일간과 공망지지의 음양이 불일치하여 공망 작용이 반감됨'),

  /// 해공(解空) - 충으로 공망 해소
  /// 공망 지지가 충을 받으면 공망이 해소됨
  haeGongChung('해공(충)', '解空(沖)', '충(沖)으로 공망이 깨어나 작용하지 않음'),

  /// 해공(解空) - 합으로 공망 해소
  /// 공망 지지가 육합/삼합을 이루면 공망이 해소됨
  haeGongHap('해공(합)', '解空(合)', '합(合)으로 공망이 채워져 작용하지 않음'),

  /// 해공(解空) - 형으로 공망 해소 (약한 효과)
  /// 공망 지지가 형을 받으면 약하게 해소됨
  haeGongHyung('해공(형)', '解空(刑)', '형(刑)으로 공망이 자극되어 약하게 해소됨'),

  /// 탈공(脫空) - 운에서 채워져 공망 해소
  /// 대운/세운에서 공망 지지가 들어오면 채워짐
  talGong('탈공', '脫空', '운에서 공망 지지가 채워져 작용하지 않음');

  final String korean;
  final String hanja;
  final String description;

  const GongmangType(this.korean, this.hanja, this.description);

  /// 해공(공망 해소) 여부
  bool get isResolved =>
      this == haeGongChung ||
      this == haeGongHap ||
      this == haeGongHyung ||
      this == talGong;

  /// 공망 작용 강도 (0~100)
  int get effectStrength => switch (this) {
        GongmangType.jinGong => 100, // 진공: 100% 작용
        GongmangType.banGong => 50, // 반공: 50% 작용
        GongmangType.haeGongChung => 0, // 충으로 해소: 0%
        GongmangType.haeGongHap => 10, // 합으로 해소: 약간 남음
        GongmangType.haeGongHyung => 20, // 형으로 해소: 일부 남음
        GongmangType.talGong => 0, // 운에서 채워짐: 0%
      };
}

// ============================================================================
// 음양 판단
// ============================================================================

/// 양지(陽支) 리스트: 자, 인, 진, 오, 신, 술
const List<String> yangJiList = ['자', '인', '진', '오', '신', '술'];

/// 음지(陰支) 리스트: 축, 묘, 사, 미, 유, 해
const List<String> eumJiList = ['축', '묘', '사', '미', '유', '해'];

/// 양간(陽干) 리스트: 갑, 병, 무, 경, 임
const List<String> yangGanList = ['갑', '병', '무', '경', '임'];

/// 음간(陰干) 리스트: 을, 정, 기, 신, 계
const List<String> eumGanList = ['을', '정', '기', '신', '계'];

/// 천간이 양간인지 확인
bool isYangGan(String gan) => yangGanList.contains(gan);

/// 천간이 음간인지 확인
bool isEumGan(String gan) => eumGanList.contains(gan);

/// 지지가 양지인지 확인
bool isYangJi(String ji) => yangJiList.contains(ji);

/// 지지가 음지인지 확인
bool isEumJi(String ji) => eumJiList.contains(ji);

/// 천간과 지지의 음양이 일치하는지 확인
bool isSameYinYang(String gan, String ji) {
  return (isYangGan(gan) && isYangJi(ji)) || (isEumGan(gan) && isEumJi(ji));
}

// ============================================================================
// 해공(解空) 관계 테이블
// ============================================================================

/// 지지충 테이블 (6충)
const Map<String, String> _jijiChungMap = {
  '자': '오',
  '오': '자',
  '축': '미',
  '미': '축',
  '인': '신',
  '신': '인',
  '묘': '유',
  '유': '묘',
  '진': '술',
  '술': '진',
  '사': '해',
  '해': '사',
};

/// 지지육합 테이블 (6합)
const Map<String, String> _jijiYukhapMap = {
  '자': '축',
  '축': '자',
  '인': '해',
  '해': '인',
  '묘': '술',
  '술': '묘',
  '진': '유',
  '유': '진',
  '사': '신',
  '신': '사',
  '오': '미',
  '미': '오',
};

/// 지지삼합 테이블 (4국, 왕지 포함 반합)
const Map<String, Set<String>> _jijiSamhapMap = {
  // 인오술 화국
  '인': {'오', '술'},
  '오': {'인', '술'},
  '술': {'인', '오'},
  // 사유축 금국
  '사': {'유', '축'},
  '유': {'사', '축'},
  '축': {'사', '유'},
  // 신자진 수국
  '신': {'자', '진'},
  '자': {'신', '진'},
  '진': {'신', '자'},
  // 해묘미 목국
  '해': {'묘', '미'},
  '묘': {'해', '미'},
  '미': {'해', '묘'},
};

/// 지지형 관계 (무은지형, 지세지형)
const Map<String, Set<String>> _jijiHyungMap = {
  // 무은지형: 인→사→신
  '인': {'사', '신'},
  '사': {'인', '신'},
  '신': {'인', '사'},
  // 지세지형: 축→술→미
  '축': {'술', '미'},
  '술': {'축', '미'},
  '미': {'축', '술'},
};

/// 두 지지가 충인지 확인
bool hasChung(String ji1, String ji2) => _jijiChungMap[ji1] == ji2;

/// 두 지지가 육합인지 확인
bool hasYukhap(String ji1, String ji2) => _jijiYukhapMap[ji1] == ji2;

/// 두 지지가 삼합(반합 포함)인지 확인
bool hasSamhap(String ji1, String ji2) {
  final partners = _jijiSamhapMap[ji1];
  return partners != null && partners.contains(ji2);
}

/// 두 지지가 형인지 확인
bool hasHyung(String ji1, String ji2) {
  final partners = _jijiHyungMap[ji1];
  return partners != null && partners.contains(ji2);
}

// ============================================================================
// 공망 유형 판단 (개선된 버전)
// ============================================================================

/// 공망 유형 판단 결과
class GongmangTypeResult {
  final GongmangType type;
  final String reason;
  final String? relatedJi; // 해공 원인이 된 지지

  const GongmangTypeResult({
    required this.type,
    required this.reason,
    this.relatedJi,
  });
}

/// 공망 유형 판단 (개선된 버전)
/// [dayGan] 일간
/// [dayJi] 일지
/// [targetJi] 확인할 지지 (년지/월지/시지)
/// [allJijis] 사주 내 모든 지지 (년지, 월지, 일지, 시지)
/// [currentDaeunJi] 현재 대운의 지지 (옵션)
/// [currentSaeunJi] 현재 세운의 지지 (옵션)
GongmangTypeResult determineGongmangTypeAdvanced({
  required String dayGan,
  required String dayJi,
  required String targetJi,
  required List<String> allJijis,
  String? currentDaeunJi,
  String? currentSaeunJi,
}) {
  final gongmangJijis = getDayGongmang(dayGan, dayJi);

  // 대상이 공망이 아니면 해당 없음 (일반적인 탈공)
  if (!gongmangJijis.contains(targetJi)) {
    return const GongmangTypeResult(
      type: GongmangType.talGong,
      reason: '공망 지지가 아님',
    );
  }

  // 1. 대운/세운에서 공망 지지가 들어오면 탈공
  if (currentDaeunJi == targetJi) {
    return GongmangTypeResult(
      type: GongmangType.talGong,
      reason: '대운에서 $targetJi가 들어와 공망이 채워짐',
      relatedJi: currentDaeunJi,
    );
  }
  if (currentSaeunJi == targetJi) {
    return GongmangTypeResult(
      type: GongmangType.talGong,
      reason: '세운에서 $targetJi가 들어와 공망이 채워짐',
      relatedJi: currentSaeunJi,
    );
  }

  // 2. 사주 내 다른 지지와의 관계 확인 (해공)
  for (final otherJi in allJijis) {
    if (otherJi == targetJi) continue; // 자기 자신 제외

    // 충(沖)으로 해공 - 가장 강력
    if (hasChung(targetJi, otherJi)) {
      return GongmangTypeResult(
        type: GongmangType.haeGongChung,
        reason: '$targetJi와 $otherJi가 충(沖)하여 공망이 해소됨',
        relatedJi: otherJi,
      );
    }
  }

  for (final otherJi in allJijis) {
    if (otherJi == targetJi) continue;

    // 육합으로 해공
    if (hasYukhap(targetJi, otherJi)) {
      return GongmangTypeResult(
        type: GongmangType.haeGongHap,
        reason: '$targetJi와 $otherJi가 육합(六合)하여 공망이 채워짐',
        relatedJi: otherJi,
      );
    }

    // 삼합(반합)으로 해공
    if (hasSamhap(targetJi, otherJi)) {
      return GongmangTypeResult(
        type: GongmangType.haeGongHap,
        reason: '$targetJi와 $otherJi가 삼합(三合) 관계로 공망이 완화됨',
        relatedJi: otherJi,
      );
    }
  }

  for (final otherJi in allJijis) {
    if (otherJi == targetJi) continue;

    // 형(刑)으로 해공 - 가장 약함
    if (hasHyung(targetJi, otherJi)) {
      return GongmangTypeResult(
        type: GongmangType.haeGongHyung,
        reason: '$targetJi와 $otherJi가 형(刑)하여 공망이 약하게 해소됨',
        relatedJi: otherJi,
      );
    }
  }

  // 3. 해공이 없으면 진공/반공 판단 (음양 일치 여부)
  if (isSameYinYang(dayGan, targetJi)) {
    // 일간과 공망지지의 음양이 일치 → 진공
    final ganType = isYangGan(dayGan) ? '양간' : '음간';
    final jiType = isYangJi(targetJi) ? '양지' : '음지';
    return GongmangTypeResult(
      type: GongmangType.jinGong,
      reason: '$dayGan($ganType)와 $targetJi($jiType)의 음양 일치로 진공',
    );
  } else {
    // 일간과 공망지지의 음양이 불일치 → 반공
    final ganType = isYangGan(dayGan) ? '양간' : '음간';
    final jiType = isYangJi(targetJi) ? '양지' : '음지';
    return GongmangTypeResult(
      type: GongmangType.banGong,
      reason: '$dayGan($ganType)와 $targetJi($jiType)의 음양 불일치로 반공',
    );
  }
}

/// 공망 유형 판단 (간략화된 버전 - 호환성 유지)
/// @deprecated 대신 determineGongmangTypeAdvanced 사용 권장
GongmangType determineGongmangType({
  required String dayGan,
  required String dayJi,
  required String targetJi,
  String? currentDaeunJi,
  String? currentSaeunJi,
}) {
  final result = determineGongmangTypeAdvanced(
    dayGan: dayGan,
    dayJi: dayJi,
    targetJi: targetJi,
    allJijis: [dayJi], // 간략 버전에서는 일지만 포함
    currentDaeunJi: currentDaeunJi,
    currentSaeunJi: currentSaeunJi,
  );
  return result.type;
}
