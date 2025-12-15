/// 12신살(十二神煞) 테이블
/// 년지 또는 일지를 기준으로 각 지지에 배치되는 신살
///
/// 12신살: 겁살, 재살, 천살, 지살, 연살, 월살, 망신, 장성, 반안, 역마, 육해, 화개
library;

// ============================================================================
// 12신살 정의
// ============================================================================

/// 12신살 종류
enum TwelveSinsal {
  /// 겁살(劫煞) - 재물 손실, 도둑 주의
  geopsal('겁살', '劫煞', '재물 손실, 도난 주의'),

  /// 재살(災煞) - 재앙, 사고 주의
  jaesal('재살', '災煞', '재앙, 사고 주의'),

  /// 천살(天煞) - 하늘의 재앙
  cheonsal('천살', '天煞', '하늘의 재앙, 예기치 못한 일'),

  /// 지살(地煞) - 땅의 재앙
  jisal('지살', '地煞', '땅의 재앙, 이사/이동 관련'),

  /// 연살(年煞) - 도화살, 이성 관계
  yeonsal('연살', '年煞', '도화살, 이성 인연, 매력'),

  /// 월살(月煞) - 고독, 외로움
  wolsal('월살', '月煞', '고독, 외로움, 독립심'),

  /// 망신(亡身) - 체면 손상
  mangshin('망신', '亡身', '체면 손상, 창피'),

  /// 장성(將星) - 권위, 리더십
  jangsung('장성', '將星', '권위, 리더십, 지휘력'),

  /// 반안(攀鞍) - 안정, 승진
  banan('반안', '攀鞍', '안정, 승진, 출세'),

  /// 역마(驛馬) - 이동, 변동
  yeokma('역마', '驛馬', '이동, 변동, 여행'),

  /// 육해(六害) - 육친 갈등
  yukhae('육해', '六害', '육친 갈등, 가족 문제'),

  /// 화개(華蓋) - 예술, 종교
  hwagae('화개', '華蓋', '예술, 종교, 학문');

  final String korean;
  final String hanja;
  final String meaning;

  const TwelveSinsal(this.korean, this.hanja, this.meaning);

  /// 길흉 판단
  String get fortuneType {
    switch (this) {
      case TwelveSinsal.jangsung:
      case TwelveSinsal.banan:
        return '길';
      case TwelveSinsal.yeokma:
      case TwelveSinsal.hwagae:
      case TwelveSinsal.yeonsal:
        return '길흉혼합';
      case TwelveSinsal.geopsal:
      case TwelveSinsal.jaesal:
      case TwelveSinsal.cheonsal:
      case TwelveSinsal.jisal:
      case TwelveSinsal.wolsal:
      case TwelveSinsal.mangshin:
      case TwelveSinsal.yukhae:
        return '흉';
    }
  }
}

/// 12신살 순서
const List<TwelveSinsal> sinsalOrder = [
  TwelveSinsal.geopsal,
  TwelveSinsal.jaesal,
  TwelveSinsal.cheonsal,
  TwelveSinsal.jisal,
  TwelveSinsal.yeonsal,
  TwelveSinsal.wolsal,
  TwelveSinsal.mangshin,
  TwelveSinsal.jangsung,
  TwelveSinsal.banan,
  TwelveSinsal.yeokma,
  TwelveSinsal.yukhae,
  TwelveSinsal.hwagae,
];

// ============================================================================
// 12신살 테이블 (기준 지지별)
// ============================================================================

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

/// 삼합 기준 지지 그룹
/// 인오술(화국), 사유축(금국), 신자진(수국), 해묘미(목국)
const Map<String, int> _samhapGroupBase = {
  // 인오술 - 화국 (기준: 인=2)
  '인': 2,
  '오': 2,
  '술': 2,
  // 사유축 - 금국 (기준: 사=5)
  '사': 5,
  '유': 5,
  '축': 5,
  // 신자진 - 수국 (기준: 신=8)
  '신': 8,
  '자': 8,
  '진': 8,
  // 해묘미 - 목국 (기준: 해=11)
  '해': 11,
  '묘': 11,
  '미': 11,
};

/// 12신살 시작 위치 (삼합 기준)
/// 겁살은 삼합의 마지막 글자(고지/묘고) 다음 오행의 생지(生地)에서 시작
///
/// 공식 테이블:
/// - 사유축(금국): 축→인에서 겁살 시작 (인묘진사오미신유술해자축)
/// - 해묘미(목국): 미→신에서 겁살 시작 (신유술해자축인묘진사오미)
/// - 신자진(수국): 진→사에서 겁살 시작 (사오미신유술해자축인묘진)
/// - 인오술(화국): 술→해에서 겁살 시작 (해자축인묘진사오미신유술)
const Map<int, int> _sinsalStartOffset = {
  2: 11, // 인오술(화국) → 해(11)에서 겁살 시작
  5: 2,  // 사유축(금국) → 인(2)에서 겁살 시작
  8: 5,  // 신자진(수국) → 사(5)에서 겁살 시작
  11: 8, // 해묘미(목국) → 신(8)에서 겁살 시작
};

/// 12신살 계산
/// [baseJi] 기준 지지 (년지 또는 일지)
/// [targetJi] 대상 지지
/// 반환: 해당 지지의 12신살
TwelveSinsal? calculateSinsal(String baseJi, String targetJi) {
  final groupBase = _samhapGroupBase[baseJi];
  if (groupBase == null) return null;

  final startOffset = _sinsalStartOffset[groupBase];
  if (startOffset == null) return null;

  final targetIndex = _jijiOrder.indexOf(targetJi);
  if (targetIndex == -1) return null;

  // 겁살 시작 위치부터 순서대로 배치
  final sinsalIndex = (targetIndex - startOffset + 12) % 12;
  return sinsalOrder[sinsalIndex];
}

/// 특정 기준 지지의 모든 12신살 맵 생성
Map<String, TwelveSinsal> buildSinsalMap(String baseJi) {
  final result = <String, TwelveSinsal>{};
  for (final ji in _jijiOrder) {
    final sinsal = calculateSinsal(baseJi, ji);
    if (sinsal != null) {
      result[ji] = sinsal;
    }
  }
  return result;
}

/// 특정 기준 지지에서 특정 신살이 있는 지지 조회
String? findJijiBySinsal(String baseJi, TwelveSinsal sinsal) {
  final sinsalMap = buildSinsalMap(baseJi);
  for (final entry in sinsalMap.entries) {
    if (entry.value == sinsal) {
      return entry.key;
    }
  }
  return null;
}

// ============================================================================
// 주요 신살 개별 조회 함수
// ============================================================================

/// 역마살 지지 조회
String? getYeokmaJi(String baseJi) => findJijiBySinsal(baseJi, TwelveSinsal.yeokma);

/// 도화살(연살) 지지 조회
String? getDohwaJi(String baseJi) => findJijiBySinsal(baseJi, TwelveSinsal.yeonsal);

/// 화개살 지지 조회
String? getHwagaeJi(String baseJi) => findJijiBySinsal(baseJi, TwelveSinsal.hwagae);

/// 장성살 지지 조회
String? getJangsungJi(String baseJi) => findJijiBySinsal(baseJi, TwelveSinsal.jangsung);

// ============================================================================
// 특수 신살 (12신살 외)
// ============================================================================

/// 특수 신살 종류
enum SpecialSinsal {
  /// 괴강살(魁罡殺) - 강한 성격, 결단력
  goegang('괴강살', '魁罡殺', '강한 성격, 결단력'),

  /// 양인살(羊刃殺) - 날카로움, 과격
  yangin('양인살', '羊刃殺', '날카로움, 과격함'),

  /// 백호살(白虎殺) - 혈광지액
  baekho('백호살', '白虎殺', '혈광지액, 사고 주의'),

  /// 천라지망(天羅地網) - 구속, 속박
  cheollajimang('천라지망', '天羅地網', '구속, 속박'),

  /// 천을귀인(天乙貴人) - 귀인의 도움
  cheoneulgwin('천을귀인', '天乙貴人', '귀인의 도움'),

  /// 문창귀인(文昌貴人) - 학문, 시험
  munchanggwin('문창귀인', '文昌貴人', '학문, 시험 운'),

  /// 홍염살(紅艶煞) - 색정, 이성 관계
  hongyeom('홍염살', '紅艶煞', '색정, 이성 관계');

  final String korean;
  final String hanja;
  final String meaning;

  const SpecialSinsal(this.korean, this.hanja, this.meaning);
}

/// 괴강 일주 (경진, 경술, 임진, 임술)
const Set<String> goeGangIlju = {'경진', '경술', '임진', '임술'};

/// 괴강살 여부 확인
bool isGoeGang(String dayGan, String dayJi) {
  return goeGangIlju.contains('$dayGan$dayJi');
}

/// 양인살 지지 (일간 기준)
const Map<String, String> yangInJiji = {
  '갑': '묘',
  '을': '진',
  '병': '오',
  '정': '미',
  '무': '오',
  '기': '미',
  '경': '유',
  '신': '술',
  '임': '자',
  '계': '축',
};

/// 양인살 지지 조회
String? getYangInJi(String dayGan) => yangInJiji[dayGan];

/// 양인살 여부 확인
bool isYangIn(String dayGan, String targetJi) {
  return yangInJiji[dayGan] == targetJi;
}

/// 천을귀인 지지 (일간 기준)
const Map<String, List<String>> cheonEulGwinJiji = {
  '갑': ['축', '미'],
  '을': ['자', '신'],
  '병': ['해', '유'],
  '정': ['해', '유'],
  '무': ['축', '미'],
  '기': ['자', '신'],
  '경': ['축', '미'],
  '신': ['인', '오'],
  '임': ['묘', '사'],
  '계': ['묘', '사'],
};

/// 천을귀인 지지 조회
List<String> getCheonEulGwinJi(String dayGan) {
  return cheonEulGwinJiji[dayGan] ?? [];
}

/// 천을귀인 여부 확인
bool isCheonEulGwin(String dayGan, String targetJi) {
  return getCheonEulGwinJi(dayGan).contains(targetJi);
}

// ============================================================================
// 통합 신살 분석
// ============================================================================

/// 신살 분석 결과
class SinsalAnalysis {
  final String jiji;
  final TwelveSinsal? twelveSinsal;
  final List<SpecialSinsal> specialSinsals;

  const SinsalAnalysis({
    required this.jiji,
    this.twelveSinsal,
    this.specialSinsals = const [],
  });

  bool get hasSinsal => twelveSinsal != null || specialSinsals.isNotEmpty;
}

/// 사주 전체 신살 분석
List<SinsalAnalysis> analyzeSajuSinsal({
  required String yearJi,
  required String monthJi,
  required String dayGan,
  required String dayJi,
  required String hourJi,
}) {
  final results = <SinsalAnalysis>[];

  // 년지 기준 12신살 맵
  final yearSinsalMap = buildSinsalMap(yearJi);

  // 각 주(柱) 분석
  for (final entry in [
    ('년', yearJi),
    ('월', monthJi),
    ('일', dayJi),
    ('시', hourJi),
  ]) {
    final ji = entry.$2;
    final specialList = <SpecialSinsal>[];

    // 양인살 확인
    if (isYangIn(dayGan, ji)) {
      specialList.add(SpecialSinsal.yangin);
    }

    // 천을귀인 확인
    if (isCheonEulGwin(dayGan, ji)) {
      specialList.add(SpecialSinsal.cheoneulgwin);
    }

    results.add(SinsalAnalysis(
      jiji: ji,
      twelveSinsal: yearSinsalMap[ji],
      specialSinsals: specialList,
    ));
  }

  return results;
}
