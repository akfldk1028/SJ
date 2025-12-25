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
  // === 흉신 ===
  /// 괴강살(魁罡殺) - 강한 성격, 결단력
  goegang('괴강살', '魁罡殺', '강한 성격, 결단력', SinsalFortuneType.mixed),

  /// 양인살(羊刃殺) - 날카로움, 과격
  yangin('양인살', '羊刃殺', '날카로움, 과격함', SinsalFortuneType.bad),

  /// 백호대살(白虎大殺) - 혈광지액, 사고 위험
  baekhodaesal('백호대살', '白虎大殺', '혈광지사, 사고/질병 위험', SinsalFortuneType.bad),

  /// 현침살(懸針殺) - 바늘에 찔림, 신경 예민
  hyeonchimsal('현침살', '懸針殺', '신경 예민, 수술/사고 관련', SinsalFortuneType.mixed),

  /// 천라지망(天羅地網) - 구속, 속박
  cheollajimang('천라지망', '天羅地網', '구속, 속박', SinsalFortuneType.bad),

  /// 홍염살(紅艶煞) - 색정, 이성 관계
  hongyeom('홍염살', '紅艶煞', '색정, 이성 관계', SinsalFortuneType.mixed),

  /// 귀문관살(鬼門關殺) - 귀신과 관련, 영적 민감
  gwimungwansal('귀문관살', '鬼門關殺', '영적 민감성, 신비 체험', SinsalFortuneType.mixed),

  // === 길신 ===
  /// 천을귀인(天乙貴人) - 귀인의 도움
  cheoneulgwin('천을귀인', '天乙貴人', '귀인의 도움', SinsalFortuneType.good),

  /// 천덕귀인(天德貴人) - 하늘의 덕
  cheondeokgwiin('천덕귀인', '天德貴人', '하늘의 덕, 재난 면함', SinsalFortuneType.good),

  /// 월덕귀인(月德貴人) - 달의 덕
  woldeokgwiin('월덕귀인', '月德貴人', '달의 덕, 흉화 감소', SinsalFortuneType.good),

  /// 문창귀인(文昌貴人) - 학문, 시험
  munchanggwin('문창귀인', '文昌貴人', '학문, 시험 운', SinsalFortuneType.good),

  /// 학당귀인(學堂貴人) - 학업 성취
  hakdanggwiin('학당귀인', '學堂貴人', '학업 성취, 교육운', SinsalFortuneType.good),

  /// 천문성(天門星) - 하늘의 문, 영적 감각
  cheonmunseong('천문성', '天門星', '영적 감각, 직관력', SinsalFortuneType.good),

  /// 황은대사(皇恩大赦) - 임금의 은혜로 용서
  hwangeundaesa('황은대사', '皇恩大赦', '귀인의 도움, 위기 탈출', SinsalFortuneType.good);

  final String korean;
  final String hanja;
  final String meaning;
  final SinsalFortuneType fortuneType;

  const SpecialSinsal(this.korean, this.hanja, this.meaning, this.fortuneType);

  /// 길성 여부
  bool get isGood => fortuneType == SinsalFortuneType.good;

  /// 흉성 여부
  bool get isBad => fortuneType == SinsalFortuneType.bad;
}

/// 신살 길흉 유형
enum SinsalFortuneType {
  good('길', '吉'),
  bad('흉', '凶'),
  mixed('혼합', '混合');

  final String korean;
  final String hanja;

  const SinsalFortuneType(this.korean, this.hanja);
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

// ============================================================================
// 추가 특수 신살 계산 로직 (Phase 16-A)
// ============================================================================

// ----------------------------------------------------------------------------
// 백호대살 (白虎大殺)
// 일주 기준으로만 성립
// ----------------------------------------------------------------------------

/// 백호대살 일주 목록
const Set<String> baekHoDaeSalIlju = {
  '갑진', // 甲辰
  '을미', // 乙未
  '병술', // 丙戌
  '정축', // 丁丑
  '무진', // 戊辰
  '임술', // 壬戌
  '계축', // 癸丑
};

/// 백호대살 여부 확인 (일주 기준)
bool isBaekHoDaeSal(String dayGan, String dayJi) {
  return baekHoDaeSalIlju.contains('$dayGan$dayJi');
}

// ----------------------------------------------------------------------------
// 현침살 (懸針殺)
// 천간: 갑(甲), 신(辛)
// 지지: 신(申), 묘(卯), 오(午)
// 강한 발동 일주: 갑신, 신묘, 갑오
// ----------------------------------------------------------------------------

/// 현침살 천간
const Set<String> hyeonChimSalGan = {'갑', '신'};

/// 현침살 지지
const Set<String> hyeonChimSalJi = {'신', '묘', '오'};

/// 현침살 강력 일주
const Set<String> hyeonChimSalStrongIlju = {'갑신', '신묘', '갑오'};

/// 현침살 여부 확인 (천간 또는 지지)
bool isHyeonChimSal(String? gan, String? ji) {
  if (gan != null && hyeonChimSalGan.contains(gan)) return true;
  if (ji != null && hyeonChimSalJi.contains(ji)) return true;
  return false;
}

/// 현침살 강력 여부 (일주 기준)
bool isStrongHyeonChimSal(String dayGan, String dayJi) {
  return hyeonChimSalStrongIlju.contains('$dayGan$dayJi');
}

// ----------------------------------------------------------------------------
// 천덕귀인 (天德貴人)
// 월지를 기준으로 특정 천간/지지 체크
// ----------------------------------------------------------------------------

/// 천덕귀인 테이블 (월지 → 천덕귀인 글자)
/// 천간이면 해당 천간이 사주에 있으면 됨
/// 지지이면 해당 지지가 사주에 있으면 됨
const Map<String, String> cheonDeokGwiInTable = {
  '인': '정', // 寅 → 丁
  '묘': '신', // 卯 → 申 (지지)
  '진': '임', // 辰 → 壬
  '사': '신', // 巳 → 辛 (천간) - 卯와 구분: 월지가 사이므로 신(辛)
  '오': '해', // 午 → 亥 (지지)
  '미': '갑', // 未 → 甲
  '신': '계', // 申 → 癸
  '유': '인', // 酉 → 寅 (지지)
  '술': '병', // 戌 → 丙
  '해': '을', // 亥 → 乙
  '자': '사', // 子 → 巳 (지지)
  '축': '경', // 丑 → 庚
};

/// 천덕귀인 여부 확인
/// [monthJi] 월지
/// [targetGan] 체크할 천간 (null 가능)
/// [targetJi] 체크할 지지 (null 가능)
bool isCheonDeokGwiIn(String monthJi, String? targetGan, String? targetJi) {
  final gwiin = cheonDeokGwiInTable[monthJi];
  if (gwiin == null) return false;

  // 천간과 지지 모두 체크
  if (targetGan == gwiin) return true;
  if (targetJi == gwiin) return true;
  return false;
}

/// 월지에 따른 천덕귀인 글자 조회
String? getCheonDeokGwiInChar(String monthJi) {
  return cheonDeokGwiInTable[monthJi];
}

// ----------------------------------------------------------------------------
// 월덕귀인 (月德貴人)
// 월지 삼합 기준으로 양간 체크
// ----------------------------------------------------------------------------

/// 월덕귀인 테이블 (월지 → 양간)
const Map<String, String> wolDeokGwiInTable = {
  // 인오술 삼합 → 병
  '인': '병',
  '오': '병',
  '술': '병',
  // 신자진 삼합 → 임
  '신': '임',
  '자': '임',
  '진': '임',
  // 사유축 삼합 → 경
  '사': '경',
  '유': '경',
  '축': '경',
  // 해묘미 삼합 → 갑
  '해': '갑',
  '묘': '갑',
  '미': '갑',
};

/// 월덕귀인 여부 확인
/// [monthJi] 월지
/// [targetGan] 체크할 천간
bool isWolDeokGwiIn(String monthJi, String? targetGan) {
  if (targetGan == null) return false;
  final gwiin = wolDeokGwiInTable[monthJi];
  return gwiin == targetGan;
}

/// 월지에 따른 월덕귀인 천간 조회
String? getWolDeokGwiInGan(String monthJi) {
  return wolDeokGwiInTable[monthJi];
}

// ----------------------------------------------------------------------------
// 천문성 (天門星)
// 1순위: 해(亥), 묘(卯), 미(未), 술(戌)
// 2순위: 인(寅), 유(酉)
// ----------------------------------------------------------------------------

/// 천문성 1순위 지지 (강함)
const Set<String> cheonMunSeongPrimary = {'해', '묘', '미', '술'};

/// 천문성 2순위 지지 (약함)
const Set<String> cheonMunSeongSecondary = {'인', '유'};

/// 천문성 여부 확인
bool isCheonMunSeong(String ji) {
  return cheonMunSeongPrimary.contains(ji) ||
         cheonMunSeongSecondary.contains(ji);
}

/// 천문성 강력 여부 (1순위)
bool isStrongCheonMunSeong(String ji) {
  return cheonMunSeongPrimary.contains(ji);
}

// ----------------------------------------------------------------------------
// 황은대사 (皇恩大赦)
// 월지 기준으로 특정 지지 조합
// ----------------------------------------------------------------------------

/// 황은대사 테이블 (월지 → 황은대사 지지 목록)
const Map<String, List<String>> hwangEunDaeSaTable = {
  '자': ['술', '해'],
  '축': ['자', '해'],
  '인': ['술'],
  '묘': ['인', '술'],
  '진': ['인'],
  '사': ['축', '진'],
  '오': ['묘', '진'],
  '미': ['사', '진'],
  '신': ['오', '미'],
  '유': ['신', '미'],
  '술': ['유', '신'],
  '해': ['술', '유'],
};

/// 황은대사 여부 확인
/// [monthJi] 월지
/// [targetJi] 체크할 지지 (일지 또는 시지)
bool isHwangEunDaeSa(String monthJi, String targetJi) {
  final daeSaJis = hwangEunDaeSaTable[monthJi];
  if (daeSaJis == null) return false;
  return daeSaJis.contains(targetJi);
}

/// 월지에 따른 황은대사 지지 목록 조회
List<String> getHwangEunDaeSaJis(String monthJi) {
  return hwangEunDaeSaTable[monthJi] ?? [];
}

// ----------------------------------------------------------------------------
// 학당귀인 (學堂貴人)
// 일간 기준으로 특정 지지
// ----------------------------------------------------------------------------

/// 학당귀인 테이블 (일간 → 지지)
const Map<String, String> hakDangGwiInTable = {
  '갑': '사', // 甲 → 巳
  '을': '오', // 乙 → 午
  '병': '인', // 丙 → 寅
  '정': '유', // 丁 → 酉
  '무': '인', // 戊 → 寅
  '기': '유', // 己 → 酉
  '경': '사', // 庚 → 巳
  '신': '자', // 辛 → 子
  '임': '신', // 壬 → 申
  '계': '묘', // 癸 → 卯
};

/// 학당귀인 여부 확인
/// [dayGan] 일간
/// [targetJi] 체크할 지지
bool isHakDangGwiIn(String dayGan, String targetJi) {
  final gwiin = hakDangGwiInTable[dayGan];
  return gwiin == targetJi;
}

/// 일간에 따른 학당귀인 지지 조회
String? getHakDangGwiInJi(String dayGan) {
  return hakDangGwiInTable[dayGan];
}

// ----------------------------------------------------------------------------
// 귀문관살 (鬼門關殺)
// 인신사해 중 2개 이상
// ----------------------------------------------------------------------------

/// 귀문관살 지지
const Set<String> gwiMunGwanSalJis = {'인', '신', '사', '해'};

/// 귀문관살 여부 확인 (사주 전체에서 2개 이상)
bool isGwiMunGwanSal(List<String> allJis) {
  int count = 0;
  for (final ji in allJis) {
    if (gwiMunGwanSalJis.contains(ji)) {
      count++;
    }
  }
  return count >= 2;
}

/// 특정 지지가 귀문관살 지지인지 확인
bool isGwiMunGwanSalJi(String ji) {
  return gwiMunGwanSalJis.contains(ji);
}
