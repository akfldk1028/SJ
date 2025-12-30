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
  hwangeundaesa('황은대사', '皇恩大赦', '귀인의 도움, 위기 탈출', SinsalFortuneType.good),

  // === Phase 23 추가 신살 ===

  /// 금여(金輿) - 금수레, 좋은 배우자 운
  geumyeo('금여', '金輿', '좋은 배우자 운, 물질적 풍요', SinsalFortuneType.good),

  /// 삼기귀인(三奇貴人) - 세 가지 기이한 조합
  samgigwiin('삼기귀인', '三奇貴人', '특별한 재능, 학문 성취', SinsalFortuneType.good),

  /// 복성귀인(福星貴人) - 복을 주는 별
  bokseongGwiin('복성귀인', '福星貴人', '복록, 조력자 만남', SinsalFortuneType.good),

  /// 낙정관살(落井關殺) - 우물에 빠지는 살
  nakjeongGwansal('낙정관살', '落井關殺', '추락/익사 위험, 배신 주의', SinsalFortuneType.bad),

  /// 문곡귀인(文曲貴人) - 문창과 쌍으로 학문 귀인
  mungokgwiin('문곡귀인', '文曲貴人', '학문, 예술, 문서운', SinsalFortuneType.good),

  /// 태극귀인(太極貴人) - 큰 귀인
  taegukgwiin('태극귀인', '太極貴人', '큰 귀인의 도움', SinsalFortuneType.good),

  /// 천의귀인(天醫貴人) - 의료 관련 귀인
  cheonuigwiin('천의귀인', '天醫貴人', '의료 관련, 건강운', SinsalFortuneType.good),

  /// 천주귀인(天廚貴人) - 식복 관련 귀인
  cheonjugwiin('천주귀인', '天廚貴人', '식복, 음식 관련 복', SinsalFortuneType.good),

  /// 암록귀인(暗祿貴人) - 숨은 녹
  amnokgwiin('암록귀인', '暗祿貴人', '숨은 재물운, 음덕', SinsalFortuneType.good),

  /// 홍란살(紅鸞煞) - 결혼/연애운 (천희성과 짝)
  hongransal('홍란살', '紅鸞煞', '결혼운, 연애운', SinsalFortuneType.good),

  /// 천희살(天喜煞) - 경사, 기쁨
  cheonheesal('천희살', '天喜煞', '경사, 기쁜 일', SinsalFortuneType.good),

  // === Phase 24 추가 신살 (P2/P3) ===

  /// 건록(健祿) - 일간이 강하게 뿌리내림, 재정 건전
  geonrok('건록', '健祿', '자신감, 추진력, 재정 건전', SinsalFortuneType.good),

  /// 비인살(飛刃殺) - 양인의 충, 은밀한 날카로움
  biinsal('비인살', '飛刃殺', '은밀한 위험, 전문직 성향', SinsalFortuneType.bad),

  /// 효신살(梟神殺) - 일지에 인성, 어머니 영향
  hyosinsal('효신살', '梟神殺', '어머니 영향, 든든한 배경', SinsalFortuneType.mixed),

  /// 고신살(孤神殺) - 남자 배우자운 약화
  gosinsal('고신살', '孤神殺', '배우자운 약화, 독립심 강함', SinsalFortuneType.bad),

  /// 과숙살(寡宿殺) - 여자 배우자운 약화
  gwasuksal('과숙살', '寡宿殺', '배우자운 약화, 독립심 강함', SinsalFortuneType.bad),

  /// 천라지망(天羅地網) - 진술 상충
  cheollaJimang('천라지망', '天羅地網', '구속, 답답함, 돌파력 필요', SinsalFortuneType.bad),

  /// 원진살(怨嗔殺) - 육친 불화
  wonJinsal('원진살', '怨嗔殺', '관계 불화, 갈등', SinsalFortuneType.bad),

  /// 천살(天殺) - 하늘의 재앙
  cheonsal('천살', '天殺', '예기치 못한 재앙, 자연재해 주의', SinsalFortuneType.bad),

  /// 지살(地殺) - 땅의 재앙
  jisal('지살', '地殺', '이동 관련 위험, 이사 주의', SinsalFortuneType.bad);

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

// ============================================================================
// Phase 23: 추가 신살 계산 로직
// ============================================================================

// ----------------------------------------------------------------------------
// 금여(金輿) - 금수레
// 일간 기준으로 특정 지지가 금여
// 좋은 배우자 운, 물질적 풍요를 상징
// ----------------------------------------------------------------------------

/// 금여 테이블 (일간 → 금여 지지)
const Map<String, String> geumYeoTable = {
  '갑': '진', // 甲 → 辰
  '을': '사', // 乙 → 巳
  '병': '미', // 丙 → 未
  '정': '신', // 丁 → 申
  '무': '미', // 戊 → 未 (병과 동일)
  '기': '신', // 己 → 申 (정과 동일)
  '경': '술', // 庚 → 戌
  '신': '해', // 辛 → 亥
  '임': '축', // 壬 → 丑
  '계': '인', // 癸 → 寅
};

/// 금여 지지 조회
/// [dayGan] 일간
/// 반환: 금여 지지
String? getGeumYeoJi(String dayGan) {
  return geumYeoTable[dayGan];
}

/// 금여 여부 확인
/// [dayGan] 일간
/// [targetJi] 체크할 지지
bool isGeumYeo(String dayGan, String targetJi) {
  final geumYeoJi = geumYeoTable[dayGan];
  return geumYeoJi == targetJi;
}

// ----------------------------------------------------------------------------
// 삼기귀인(三奇貴人)
// 천간 조합으로 판단 (년월일 또는 월일시)
// - 천상삼기: 갑(甲), 무(戊), 경(庚) 순서
// - 인중삼기: 신(辛), 임(壬), 계(癸) 순서 (일부: 임계신)
// - 지하삼기: 을(乙), 병(丙), 정(丁) 순서
// ----------------------------------------------------------------------------

/// 삼기귀인 유형
enum SamgiType {
  /// 천상삼기 (갑무경)
  cheonSang('천상삼기', '天上三奇', '갑무경'),

  /// 인중삼기 (신임계)
  inJung('인중삼기', '人中三奇', '신임계'),

  /// 지하삼기 (을병정)
  jiHa('지하삼기', '地下三奇', '을병정');

  final String korean;
  final String hanja;
  final String combination;

  const SamgiType(this.korean, this.hanja, this.combination);
}

/// 삼기귀인 확인 결과
class SamgiResult {
  final bool hasSamgi;
  final SamgiType? type;
  final String location; // '년월일' 또는 '월일시'

  const SamgiResult({
    required this.hasSamgi,
    this.type,
    this.location = '',
  });

  static const SamgiResult none = SamgiResult(hasSamgi: false);
}

/// 삼기귀인 확인
/// 사주 4주의 천간을 순서대로 체크
SamgiResult checkSamgiGwiin({
  required String yearGan,
  required String monthGan,
  required String dayGan,
  String? hourGan,
}) {
  // 년월일 조합 체크
  final yearMonthDay = [yearGan, monthGan, dayGan];

  // 천상삼기 (갑무경)
  if (yearMonthDay[0] == '갑' && yearMonthDay[1] == '무' && yearMonthDay[2] == '경') {
    return const SamgiResult(hasSamgi: true, type: SamgiType.cheonSang, location: '년월일');
  }

  // 지하삼기 (을병정)
  if (yearMonthDay[0] == '을' && yearMonthDay[1] == '병' && yearMonthDay[2] == '정') {
    return const SamgiResult(hasSamgi: true, type: SamgiType.jiHa, location: '년월일');
  }

  // 인중삼기 (신임계) - 일부 학파에서는 임계신 순서
  if (yearMonthDay[0] == '신' && yearMonthDay[1] == '임' && yearMonthDay[2] == '계') {
    return const SamgiResult(hasSamgi: true, type: SamgiType.inJung, location: '년월일');
  }

  // 월일시 조합 체크 (시간이 있는 경우)
  if (hourGan != null) {
    final monthDayHour = [monthGan, dayGan, hourGan];

    // 천상삼기 (갑무경)
    if (monthDayHour[0] == '갑' && monthDayHour[1] == '무' && monthDayHour[2] == '경') {
      return const SamgiResult(hasSamgi: true, type: SamgiType.cheonSang, location: '월일시');
    }

    // 지하삼기 (을병정)
    if (monthDayHour[0] == '을' && monthDayHour[1] == '병' && monthDayHour[2] == '정') {
      return const SamgiResult(hasSamgi: true, type: SamgiType.jiHa, location: '월일시');
    }

    // 인중삼기 (신임계)
    if (monthDayHour[0] == '신' && monthDayHour[1] == '임' && monthDayHour[2] == '계') {
      return const SamgiResult(hasSamgi: true, type: SamgiType.inJung, location: '월일시');
    }
  }

  return SamgiResult.none;
}

// ----------------------------------------------------------------------------
// 복성귀인(福星貴人)
// 연간(年干) 기준으로 식신(食神) 천간이 있는 경우
// 또는 일간 기준 특정 지지 (갑인, 을축, 병자, 정유, 무신, 기미, 경오, 신사, 임진, 계묘)
// ----------------------------------------------------------------------------

/// 복성귀인 테이블 (연간 → 식신 천간)
const Map<String, String> bokseongGwiinGanTable = {
  '갑': '병', // 甲 → 丙 (식신)
  '을': '정', // 乙 → 丁
  '병': '무', // 丙 → 戊
  '정': '기', // 丁 → 己
  '무': '경', // 戊 → 庚
  '기': '신', // 己 → 辛
  '경': '임', // 庚 → 壬
  '신': '계', // 辛 → 癸
  '임': '갑', // 壬 → 甲
  '계': '을', // 癸 → 乙
};

/// 복성귀인 일주 (일간+일지 조합)
const Set<String> bokseongGwiinIlju = {
  '갑인', '을축', '병자', '정유', '무신',
  '기미', '경오', '신사', '임진', '계묘',
};

/// 복성귀인 일주 여부 확인
bool isBokseongGwiinIlju(String dayGan, String dayJi) {
  return bokseongGwiinIlju.contains('$dayGan$dayJi');
}

/// 복성귀인 천간 여부 확인 (연간 기준)
/// [yearGan] 연간
/// [targetGan] 체크할 천간 (월/일/시의 천간)
bool isBokseongGwiinGan(String yearGan, String targetGan) {
  final shikshin = bokseongGwiinGanTable[yearGan];
  return shikshin == targetGan;
}

// ----------------------------------------------------------------------------
// 낙정관살(落井關殺)
// 일간 기준으로 특정 지지가 낙정관살
// 우물/물에 빠지는 흉살, 배신/구설 주의
// ----------------------------------------------------------------------------

/// 낙정관살 테이블 (일간 → 낙정관살 지지)
const Map<String, String> nakjeongGwansalTable = {
  '갑': '유', // 甲 → 酉
  '을': '술', // 乙 → 戌
  '병': '신', // 丙 → 申
  '정': '해', // 丁 → 亥
  '무': '미', // 戊 → 未
  '기': '사', // 己 → 巳
  '경': '자', // 庚 → 子
  '신': '축', // 辛 → 丑
  '임': '술', // 壬 → 戌
  '계': '묘', // 癸 → 卯
};

/// 낙정관살 일주 (강하게 작용)
const Set<String> nakjeongGwansalIlju = {
  '기사', '경자', '병신', '임술', '계묘',
};

/// 낙정관살 지지 조회
String? getNakjeongGwansalJi(String dayGan) {
  return nakjeongGwansalTable[dayGan];
}

/// 낙정관살 여부 확인
/// [dayGan] 일간
/// [targetJi] 체크할 지지
bool isNakjeongGwansal(String dayGan, String targetJi) {
  final nakjeongJi = nakjeongGwansalTable[dayGan];
  return nakjeongJi == targetJi;
}

/// 낙정관살 일주 여부 (강력 작용)
bool isNakjeongGwansalIlju(String dayGan, String dayJi) {
  return nakjeongGwansalIlju.contains('$dayGan$dayJi');
}

// ----------------------------------------------------------------------------
// 문곡귀인(文曲貴人)
// 문창귀인과 쌍으로 학문 관련 귀인
// 일간 기준으로 특정 지지
// ----------------------------------------------------------------------------

/// 문곡귀인 테이블 (일간 → 문곡 지지)
/// 문창과 다른 위치에서 학문운을 나타냄
const Map<String, String> mungokGwiinTable = {
  '갑': '해', // 甲 → 亥
  '을': '자', // 乙 → 子
  '병': '인', // 丙 → 寅
  '정': '묘', // 丁 → 卯
  '무': '신', // 戊 → 申
  '기': '유', // 己 → 酉
  '경': '해', // 庚 → 亥
  '신': '자', // 辛 → 子
  '임': '인', // 壬 → 寅
  '계': '묘', // 癸 → 卯
};

/// 문곡귀인 여부 확인
bool isMungokGwiin(String dayGan, String targetJi) {
  final mungokJi = mungokGwiinTable[dayGan];
  return mungokJi == targetJi;
}

/// 문곡귀인 지지 조회
String? getMungokGwiinJi(String dayGan) {
  return mungokGwiinTable[dayGan];
}

// ----------------------------------------------------------------------------
// 태극귀인(太極貴人)
// 일간 기준으로 특정 지지 조합
// 큰 귀인의 도움을 상징
// ----------------------------------------------------------------------------

/// 태극귀인 테이블 (일간 → 태극귀인 지지들)
const Map<String, List<String>> taegukGwiinTable = {
  '갑': ['자', '오'], // 甲 → 子, 午
  '을': ['자', '오'], // 乙 → 子, 午
  '병': ['묘', '유'], // 丙 → 卯, 酉
  '정': ['묘', '유'], // 丁 → 卯, 酉
  '무': ['축', '미'], // 戊 → 丑, 未
  '기': ['축', '미'], // 己 → 丑, 未
  '경': ['인', '해'], // 庚 → 寅, 亥
  '신': ['인', '해'], // 辛 → 寅, 亥
  '임': ['사', '신'], // 壬 → 巳, 申
  '계': ['사', '신'], // 癸 → 巳, 申
};

/// 태극귀인 여부 확인
bool isTaegukGwiin(String dayGan, String targetJi) {
  final taegukJis = taegukGwiinTable[dayGan] ?? [];
  return taegukJis.contains(targetJi);
}

/// 태극귀인 지지 목록 조회
List<String> getTaegukGwiinJis(String dayGan) {
  return taegukGwiinTable[dayGan] ?? [];
}

// ----------------------------------------------------------------------------
// 천의귀인(天醫貴人)
// 월지 기준으로 특정 지지
// 의료, 건강 관련 길성
// ----------------------------------------------------------------------------

/// 천의귀인 테이블 (월지 → 천의귀인 지지)
const Map<String, String> cheonuiGwiinTable = {
  '인': '축', // 寅月 → 丑
  '묘': '인', // 卯月 → 寅
  '진': '묘', // 辰月 → 卯
  '사': '진', // 巳月 → 辰
  '오': '사', // 午月 → 巳
  '미': '오', // 未月 → 午
  '신': '미', // 申月 → 未
  '유': '신', // 酉月 → 申
  '술': '유', // 戌月 → 酉
  '해': '술', // 亥月 → 戌
  '자': '해', // 子月 → 亥
  '축': '자', // 丑月 → 子
};

/// 천의귀인 여부 확인
/// [monthJi] 월지
/// [targetJi] 체크할 지지
bool isCheonuiGwiin(String monthJi, String targetJi) {
  final cheonuiJi = cheonuiGwiinTable[monthJi];
  return cheonuiJi == targetJi;
}

/// 천의귀인 지지 조회
String? getCheonuiGwiinJi(String monthJi) {
  return cheonuiGwiinTable[monthJi];
}

// ----------------------------------------------------------------------------
// 천주귀인(天廚貴人)
// 일간 기준으로 특정 지지
// 식복, 음식 관련 길성
// ----------------------------------------------------------------------------

/// 천주귀인 테이블 (일간 → 천주귀인 지지)
const Map<String, String> cheonjuGwiinTable = {
  '갑': '사', // 甲 → 巳
  '을': '오', // 乙 → 午
  '병': '사', // 丙 → 巳
  '정': '오', // 丁 → 午
  '무': '사', // 戊 → 巳
  '기': '오', // 己 → 午
  '경': '해', // 庚 → 亥
  '신': '자', // 辛 → 子
  '임': '해', // 壬 → 亥
  '계': '자', // 癸 → 子
};

/// 천주귀인 여부 확인
bool isCheonjuGwiin(String dayGan, String targetJi) {
  final cheonjuJi = cheonjuGwiinTable[dayGan];
  return cheonjuJi == targetJi;
}

/// 천주귀인 지지 조회
String? getCheonjuGwiinJi(String dayGan) {
  return cheonjuGwiinTable[dayGan];
}

// ----------------------------------------------------------------------------
// 암록귀인(暗祿貴人)
// 일간 기준으로 정록의 충 위치
// 숨은 재물운, 음덕
// ----------------------------------------------------------------------------

/// 암록귀인 테이블 (일간 → 암록 지지)
/// 정록(正祿)의 충(沖) 위치
const Map<String, String> amnokGwiinTable = {
  '갑': '유', // 甲 정록=寅, 寅沖申 → 일부: 酉로 봄
  '을': '신', // 乙 정록=卯, 卯沖酉 → 申
  '병': '해', // 丙 정록=巳, 巳沖亥 → 亥
  '정': '술', // 丁 정록=午, 午沖子 → 戌
  '무': '해', // 戊 정록=巳, 巳沖亥 → 亥
  '기': '자', // 己 정록=午, 午沖子 → 子
  '경': '묘', // 庚 정록=申, 申沖寅 → 卯
  '신': '인', // 辛 정록=酉, 酉沖卯 → 寅
  '임': '사', // 壬 정록=亥, 亥沖巳 → 巳
  '계': '오', // 癸 정록=子, 子沖午 → 午
};

/// 암록귀인 여부 확인
bool isAmnokGwiin(String dayGan, String targetJi) {
  final amnokJi = amnokGwiinTable[dayGan];
  return amnokJi == targetJi;
}

/// 암록귀인 지지 조회
String? getAmnokGwiinJi(String dayGan) {
  return amnokGwiinTable[dayGan];
}

// ----------------------------------------------------------------------------
// 홍란살(紅鸞煞)과 천희살(天喜煞)
// 년지 기준으로 결혼운, 경사 관련
// 홍란과 천희는 서로 충(沖) 관계
// ----------------------------------------------------------------------------

/// 홍란살 테이블 (년지 → 홍란 지지)
const Map<String, String> hongranSalTable = {
  '자': '묘', // 子 → 卯
  '축': '인', // 丑 → 寅
  '인': '축', // 寅 → 丑
  '묘': '자', // 卯 → 子
  '진': '해', // 辰 → 亥
  '사': '술', // 巳 → 戌
  '오': '유', // 午 → 酉
  '미': '신', // 未 → 申
  '신': '미', // 申 → 未
  '유': '오', // 酉 → 午
  '술': '사', // 戌 → 巳
  '해': '진', // 亥 → 辰
};

/// 천희살 테이블 (년지 → 천희 지지)
/// 홍란의 충(沖) 위치
const Map<String, String> cheonheeSalTable = {
  '자': '유', // 子 → 酉 (卯沖酉)
  '축': '신', // 丑 → 申
  '인': '미', // 寅 → 未
  '묘': '오', // 卯 → 午
  '진': '사', // 辰 → 巳
  '사': '진', // 巳 → 辰
  '오': '묘', // 午 → 卯
  '미': '인', // 未 → 寅
  '신': '축', // 申 → 丑
  '유': '자', // 酉 → 子
  '술': '해', // 戌 → 亥
  '해': '술', // 亥 → 戌
};

/// 홍란살 여부 확인
/// [yearJi] 년지
/// [targetJi] 체크할 지지
bool isHongranSal(String yearJi, String targetJi) {
  final hongranJi = hongranSalTable[yearJi];
  return hongranJi == targetJi;
}

/// 홍란살 지지 조회
String? getHongranSalJi(String yearJi) {
  return hongranSalTable[yearJi];
}

/// 천희살 여부 확인
/// [yearJi] 년지
/// [targetJi] 체크할 지지
bool isCheonheeSal(String yearJi, String targetJi) {
  final cheonheeJi = cheonheeSalTable[yearJi];
  return cheonheeJi == targetJi;
}

/// 천희살 지지 조회
String? getCheonheeSalJi(String yearJi) {
  return cheonheeSalTable[yearJi];
}

// ============================================================================
// Phase 24: P2/P3 추가 신살 계산 로직
// ============================================================================

// ----------------------------------------------------------------------------
// 건록(健祿)
// 일간 기준으로 비견이 되는 지지 (같은 오행, 같은 음양)
// 일간이 강하게 뿌리내리는 위치
// ----------------------------------------------------------------------------

/// 건록 테이블 (일간 → 건록 지지)
/// 일간과 같은 오행의 양지(양간은 양지, 음간은 음지)
const Map<String, String> geonrokTable = {
  '갑': '인', // 甲 → 寅 (木의 양지)
  '을': '묘', // 乙 → 卯 (木의 음지)
  '병': '사', // 丙 → 巳 (火의 양지)
  '정': '오', // 丁 → 午 (火의 음지)
  '무': '사', // 戊 → 巳 (土, 병과 동일)
  '기': '오', // 己 → 午 (土, 정과 동일)
  '경': '신', // 庚 → 申 (金의 양지)
  '신': '유', // 辛 → 酉 (金의 음지)
  '임': '해', // 壬 → 亥 (水의 양지)
  '계': '자', // 癸 → 子 (水의 음지)
};

/// 건록 지지 조회
String? getGeonrokJi(String dayGan) {
  return geonrokTable[dayGan];
}

/// 건록 여부 확인
/// [dayGan] 일간
/// [targetJi] 체크할 지지
bool isGeonrok(String dayGan, String targetJi) {
  final geonrokJi = geonrokTable[dayGan];
  return geonrokJi == targetJi;
}

// ----------------------------------------------------------------------------
// 비인살(飛刃殺)
// 양인살의 충(沖) 위치
// 양인보다 작용이 약하지만 은밀하게 작용
// ----------------------------------------------------------------------------

/// 비인살 테이블 (일간 → 비인 지지)
/// 양인살의 충 위치
const Map<String, String> biinsalTable = {
  '갑': '유', // 甲 양인=묘, 묘沖酉 → 酉
  '을': '술', // 乙 양인=진, 진沖戌 → 戌
  '병': '자', // 丙 양인=오, 오沖子 → 子
  '정': '축', // 丁 양인=미, 미沖丑 → 丑
  '무': '자', // 戊 양인=오, 오沖子 → 子
  '기': '축', // 己 양인=미, 미沖丑 → 丑
  '경': '묘', // 庚 양인=유, 유沖卯 → 卯
  '신': '진', // 辛 양인=술, 술沖辰 → 辰
  '임': '오', // 壬 양인=자, 자沖午 → 午
  '계': '미', // 癸 양인=축, 축沖未 → 未
};

/// 비인살 지지 조회
String? getBiinsalJi(String dayGan) {
  return biinsalTable[dayGan];
}

/// 비인살 여부 확인
bool isBiinsal(String dayGan, String targetJi) {
  final biinsalJi = biinsalTable[dayGan];
  return biinsalJi == targetJi;
}

// ----------------------------------------------------------------------------
// 효신살(梟神殺)
// 일지가 일간을 생하는 관계 (인성이 일지에 있음)
// 일주 조합으로 판단
// ----------------------------------------------------------------------------

/// 효신살 일주 목록 (정인이 일지에 있는 경우)
/// 갑자, 을해, 무오, 기사 등
const Set<String> hyosinsalIlju = {
  '갑자', // 甲子: 子水가 甲木을 생함 (정인)
  '을해', // 乙亥: 亥水가 乙木을 생함 (정인)
  '병인', // 丙寅: 寅木이 丙火를 생함 (정인)
  '정묘', // 丁卯: 卯木이 丁火를 생함 (정인)
  '무오', // 戊午: 午火가 戊土를 생함 (정인)
  '기사', // 己巳: 巳火가 己土를 생함 (정인)
  '경진', // 庚辰: 辰土가 庚金을 생함 (편인 - 토의 창고)
  '경술', // 庚戌: 戌土가 庚金을 생함 (편인)
  '신축', // 辛丑: 丑土가 辛金을 생함 (정인)
  '신미', // 辛未: 未土가 辛金을 생함 (정인)
  '임신', // 壬申: 申金이 壬水를 생함 (정인)
  '계유', // 癸酉: 酉金이 癸水를 생함 (정인)
};

/// 효신살 여부 확인 (일주 기준)
bool isHyosinsal(String dayGan, String dayJi) {
  return hyosinsalIlju.contains('$dayGan$dayJi');
}

// ----------------------------------------------------------------------------
// 고신살(孤神殺) - 남자
// 년지 기준으로 특정 지지에서 발생
// 배우자운 약화, 독립심 강함
// ----------------------------------------------------------------------------

/// 고신살 테이블 (년지 그룹 → 고신살 지지)
/// 해자축 → 인, 인묘진 → 사, 사오미 → 신, 신유술 → 해
const Map<String, String> gosinsalTable = {
  '해': '인', '자': '인', '축': '인',
  '인': '사', '묘': '사', '진': '사',
  '사': '신', '오': '신', '미': '신',
  '신': '해', '유': '해', '술': '해',
};

/// 고신살 지지 조회
String? getGosinsalJi(String yearJi) {
  return gosinsalTable[yearJi];
}

/// 고신살 여부 확인
/// [yearJi] 년지
/// [targetJi] 체크할 지지 (월/일/시)
bool isGosinsal(String yearJi, String targetJi) {
  final gosinsalJi = gosinsalTable[yearJi];
  return gosinsalJi == targetJi;
}

// ----------------------------------------------------------------------------
// 과숙살(寡宿殺) - 여자
// 년지 기준으로 특정 지지에서 발생
// 배우자운 약화, 독립심 강함
// ----------------------------------------------------------------------------

/// 과숙살 테이블 (년지 그룹 → 과숙살 지지)
/// 인묘진 → 축, 사오미 → 진, 신유술 → 미, 해자축 → 술
const Map<String, String> gwasuksalTable = {
  '인': '축', '묘': '축', '진': '축',
  '사': '진', '오': '진', '미': '진',
  '신': '미', '유': '미', '술': '미',
  '해': '술', '자': '술', '축': '술',
};

/// 과숙살 지지 조회
String? getGwasuksalJi(String yearJi) {
  return gwasuksalTable[yearJi];
}

/// 과숙살 여부 확인
bool isGwasuksal(String yearJi, String targetJi) {
  final gwasuksalJi = gwasuksalTable[yearJi];
  return gwasuksalJi == targetJi;
}

// ----------------------------------------------------------------------------
// 원진살(怨嗔殺)
// 육친 불화, 관계 갈등
// 특정 지지 조합에서 발생
// ----------------------------------------------------------------------------

/// 원진살 조합 (서로 원진 관계인 지지 쌍)
const Map<String, String> wonJinsalPairs = {
  '자': '미', '미': '자',
  '축': '오', '오': '축',
  '인': '유', '유': '인',
  '묘': '신', '신': '묘',
  '진': '해', '해': '진',
  '사': '술', '술': '사',
};

/// 원진살 여부 확인 (두 지지가 원진 관계인지)
bool isWonJinsal(String ji1, String ji2) {
  return wonJinsalPairs[ji1] == ji2;
}

/// 사주 내 원진살 개수 확인
int countWonJinsal(List<String> allJis) {
  int count = 0;
  for (int i = 0; i < allJis.length; i++) {
    for (int j = i + 1; j < allJis.length; j++) {
      if (isWonJinsal(allJis[i], allJis[j])) {
        count++;
      }
    }
  }
  return count;
}

// ----------------------------------------------------------------------------
// 천라지망(天羅地網)
// 진술 상충 조합
// 구속, 답답함
// ----------------------------------------------------------------------------

/// 천라지망 여부 확인 (사주에 진과 술이 모두 있는지)
bool hasCheollaJimang(List<String> allJis) {
  return allJis.contains('진') && allJis.contains('술');
}

/// 천라지망 강력 여부 (진술이 충 위치에 있는지)
bool isStrongCheollaJimang({
  required String yearJi,
  required String monthJi,
  required String dayJi,
  String? hourJi,
}) {
  // 년-일 또는 월-시 충이면 강력
  if ((yearJi == '진' && dayJi == '술') || (yearJi == '술' && dayJi == '진')) {
    return true;
  }
  if (hourJi != null) {
    if ((monthJi == '진' && hourJi == '술') || (monthJi == '술' && hourJi == '진')) {
      return true;
    }
  }
  return false;
}
