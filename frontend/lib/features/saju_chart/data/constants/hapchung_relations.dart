/// 합충형파해(合沖刑破害) 관계 테이블
/// 사주팔자의 천간/지지 간 특수 관계 정의
///
/// 합(合): 결합하여 새로운 기운 생성
/// 충(沖): 충돌하여 기운 파괴/변화
/// 형(刑): 형벌, 갈등 관계
/// 파(破): 깨뜨림, 손상 관계
/// 해(害): 해침, 방해 관계
/// 원진(怨嗔): 미움, 원망 관계
library;

// ============================================================================
// 천간합 (天干合) - 5합
// ============================================================================

/// 천간합 결과 오행
enum CheonganHapResult {
  to('토', '土'), // 갑기합화토
  geum('금', '金'), // 을경합화금
  su('수', '水'), // 병신합화수
  mok('목', '木'), // 정임합화목
  hwa('화', '火'); // 무계합화화

  final String korean;
  final String hanja;

  const CheonganHapResult(this.korean, this.hanja);
}

/// 천간합 정보
class CheonganHap {
  final String gan1;
  final String gan2;
  final CheonganHapResult result;
  final String description;

  const CheonganHap({
    required this.gan1,
    required this.gan2,
    required this.result,
    required this.description,
  });

  /// 두 천간이 합인지 확인
  bool matches(String a, String b) =>
      (gan1 == a && gan2 == b) || (gan1 == b && gan2 == a);
}

/// 천간합 테이블 (5합)
const List<CheonganHap> cheonganHapList = [
  CheonganHap(
    gan1: '갑',
    gan2: '기',
    result: CheonganHapResult.to,
    description: '갑기합화토(甲己合化土) - 중정지합',
  ),
  CheonganHap(
    gan1: '을',
    gan2: '경',
    result: CheonganHapResult.geum,
    description: '을경합화금(乙庚合化金) - 인의지합',
  ),
  CheonganHap(
    gan1: '병',
    gan2: '신',
    result: CheonganHapResult.su,
    description: '병신합화수(丙辛合化水) - 위엄지합',
  ),
  CheonganHap(
    gan1: '정',
    gan2: '임',
    result: CheonganHapResult.mok,
    description: '정임합화목(丁壬合化木) - 인수지합',
  ),
  CheonganHap(
    gan1: '무',
    gan2: '계',
    result: CheonganHapResult.hwa,
    description: '무계합화화(戊癸合化火) - 무정지합',
  ),
];

/// 빠른 조회용 Map
final Map<String, String> _cheonganHapPairs = {
  '갑': '기',
  '기': '갑',
  '을': '경',
  '경': '을',
  '병': '신',
  '신': '병',
  '정': '임',
  '임': '정',
  '무': '계',
  '계': '무',
};

/// 천간합 짝 조회
String? getCheonganHapPair(String gan) => _cheonganHapPairs[gan];

/// 두 천간이 합인지 확인
bool isCheonganHap(String gan1, String gan2) {
  return _cheonganHapPairs[gan1] == gan2;
}

/// 천간합 정보 조회
CheonganHap? getCheonganHapInfo(String gan1, String gan2) {
  for (final hap in cheonganHapList) {
    if (hap.matches(gan1, gan2)) return hap;
  }
  return null;
}

// ============================================================================
// 천간충 (天干沖) - 4충
// ============================================================================

/// 천간충 테이블
const Map<String, String> cheonganChungPairs = {
  '갑': '경', // 갑경충
  '경': '갑',
  '을': '신', // 을신충
  '신': '을',
  '병': '임', // 병임충
  '임': '병',
  '정': '계', // 정계충
  '계': '정',
  // 무기는 충이 없음 (토는 중앙이라 충돌 없음)
};

/// 두 천간이 충인지 확인
bool isCheonganChung(String gan1, String gan2) {
  return cheonganChungPairs[gan1] == gan2;
}

// ============================================================================
// 지지육합 (地支六合)
// ============================================================================

/// 지지육합 결과 오행
class JijiYukhap {
  final String ji1;
  final String ji2;
  final String resultOheng;
  final String description;

  const JijiYukhap({
    required this.ji1,
    required this.ji2,
    required this.resultOheng,
    required this.description,
  });

  bool matches(String a, String b) =>
      (ji1 == a && ji2 == b) || (ji1 == b && ji2 == a);
}

/// 지지육합 테이블
const List<JijiYukhap> jijiYukhapList = [
  JijiYukhap(ji1: '자', ji2: '축', resultOheng: '토', description: '자축합토(子丑合土)'),
  JijiYukhap(ji1: '인', ji2: '해', resultOheng: '목', description: '인해합목(寅亥合木)'),
  JijiYukhap(ji1: '묘', ji2: '술', resultOheng: '화', description: '묘술합화(卯戌合火)'),
  JijiYukhap(ji1: '진', ji2: '유', resultOheng: '금', description: '진유합금(辰酉合金)'),
  JijiYukhap(ji1: '사', ji2: '신', resultOheng: '수', description: '사신합수(巳申合水)'),
  JijiYukhap(ji1: '오', ji2: '미', resultOheng: '토', description: '오미합토(午未合土)'),
];

/// 빠른 조회용 Map
final Map<String, String> _jijiYukhapPairs = {
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

/// 지지육합 짝 조회
String? getJijiYukhapPair(String ji) => _jijiYukhapPairs[ji];

/// 두 지지가 육합인지 확인
bool isJijiYukhap(String ji1, String ji2) {
  return _jijiYukhapPairs[ji1] == ji2;
}

/// 지지육합 정보 조회
JijiYukhap? getJijiYukhapInfo(String ji1, String ji2) {
  for (final hap in jijiYukhapList) {
    if (hap.matches(ji1, ji2)) return hap;
  }
  return null;
}

// ============================================================================
// 지지삼합 (地支三合) - 4국
// ============================================================================

/// 지지삼합 (오행국)
class JijiSamhap {
  final String ji1; // 생지
  final String ji2; // 왕지
  final String ji3; // 묘지
  final String resultOheng;
  final String description;

  const JijiSamhap({
    required this.ji1,
    required this.ji2,
    required this.ji3,
    required this.resultOheng,
    required this.description,
  });

  /// 세 지지가 삼합인지 확인
  bool matches(Set<String> jijis) {
    return jijis.contains(ji1) && jijis.contains(ji2) && jijis.contains(ji3);
  }

  /// 반합 (두 지지) 확인 - 왕지 포함 필수
  bool isHalfMatch(String a, String b) {
    final pair = {a, b};
    // 왕지(ji2)가 포함되어야 반합
    if (!pair.contains(ji2)) return false;
    return pair.contains(ji1) || pair.contains(ji3);
  }
}

/// 지지삼합 테이블 (4국)
const List<JijiSamhap> jijiSamhapList = [
  JijiSamhap(
    ji1: '인',
    ji2: '오',
    ji3: '술',
    resultOheng: '화',
    description: '인오술 화국(寅午戌 火局)',
  ),
  JijiSamhap(
    ji1: '사',
    ji2: '유',
    ji3: '축',
    resultOheng: '금',
    description: '사유축 금국(巳酉丑 金局)',
  ),
  JijiSamhap(
    ji1: '신',
    ji2: '자',
    ji3: '진',
    resultOheng: '수',
    description: '신자진 수국(申子辰 水局)',
  ),
  JijiSamhap(
    ji1: '해',
    ji2: '묘',
    ji3: '미',
    resultOheng: '목',
    description: '해묘미 목국(亥卯未 木局)',
  ),
];

/// 세 지지가 삼합인지 확인
JijiSamhap? findJijiSamhap(Set<String> jijis) {
  for (final samhap in jijiSamhapList) {
    if (samhap.matches(jijis)) return samhap;
  }
  return null;
}

/// 두 지지가 반합인지 확인 (왕지 포함 필수)
JijiSamhap? findJijiHalfSamhap(String ji1, String ji2) {
  for (final samhap in jijiSamhapList) {
    if (samhap.isHalfMatch(ji1, ji2)) return samhap;
  }
  return null;
}

// ============================================================================
// 지지방합 (地支方合) - 계절합
// ============================================================================

/// 지지방합 (계절 방위)
class JijiBanghap {
  final String ji1;
  final String ji2;
  final String ji3;
  final String resultOheng;
  final String season;
  final String direction;
  final String description;

  const JijiBanghap({
    required this.ji1,
    required this.ji2,
    required this.ji3,
    required this.resultOheng,
    required this.season,
    required this.direction,
    required this.description,
  });

  bool matches(Set<String> jijis) {
    return jijis.contains(ji1) && jijis.contains(ji2) && jijis.contains(ji3);
  }
}

/// 지지방합 테이블 (4방)
const List<JijiBanghap> jijiBanghapList = [
  JijiBanghap(
    ji1: '인',
    ji2: '묘',
    ji3: '진',
    resultOheng: '목',
    season: '봄',
    direction: '동',
    description: '인묘진 동방목(寅卯辰 東方木)',
  ),
  JijiBanghap(
    ji1: '사',
    ji2: '오',
    ji3: '미',
    resultOheng: '화',
    season: '여름',
    direction: '남',
    description: '사오미 남방화(巳午未 南方火)',
  ),
  JijiBanghap(
    ji1: '신',
    ji2: '유',
    ji3: '술',
    resultOheng: '금',
    season: '가을',
    direction: '서',
    description: '신유술 서방금(申酉戌 西方金)',
  ),
  JijiBanghap(
    ji1: '해',
    ji2: '자',
    ji3: '축',
    resultOheng: '수',
    season: '겨울',
    direction: '북',
    description: '해자축 북방수(亥子丑 北方水)',
  ),
];

/// 세 지지가 방합인지 확인
JijiBanghap? findJijiBanghap(Set<String> jijis) {
  for (final banghap in jijiBanghapList) {
    if (banghap.matches(jijis)) return banghap;
  }
  return null;
}

// ============================================================================
// 지지충 (地支沖) - 6충
// ============================================================================

/// 지지충 테이블
const Map<String, String> jijiChungPairs = {
  '자': '오', // 자오충
  '오': '자',
  '축': '미', // 축미충
  '미': '축',
  '인': '신', // 인신충
  '신': '인',
  '묘': '유', // 묘유충
  '유': '묘',
  '진': '술', // 진술충
  '술': '진',
  '사': '해', // 사해충
  '해': '사',
};

/// 두 지지가 충인지 확인
bool isJijiChung(String ji1, String ji2) {
  return jijiChungPairs[ji1] == ji2;
}

/// 지지충 짝 조회
String? getJijiChungPair(String ji) => jijiChungPairs[ji];

// ============================================================================
// 지지형 (地支刑) - 3형
// ============================================================================

/// 형 유형
enum HyungType {
  muEun('무은지형', '無恩之刑'), // 인사신 - 은혜 없는 형
  jiSe('지세지형', '持勢之刑'), // 축술미 - 권세 믿는 형
  jaHyung('자형', '自刑'), // 진진, 오오, 유유, 해해
}

/// 지지형 관계
class JijiHyung {
  final List<String> jijis;
  final HyungType type;
  final String description;

  const JijiHyung({
    required this.jijis,
    required this.type,
    required this.description,
  });
}

/// 지지형 테이블
const List<JijiHyung> jijiHyungList = [
  // 무은지형 (인→사→신→인)
  JijiHyung(
    jijis: ['인', '사'],
    type: HyungType.muEun,
    description: '인사형(寅巳刑) - 무은지형',
  ),
  JijiHyung(
    jijis: ['사', '신'],
    type: HyungType.muEun,
    description: '사신형(巳申刑) - 무은지형',
  ),
  JijiHyung(
    jijis: ['신', '인'],
    type: HyungType.muEun,
    description: '신인형(申寅刑) - 무은지형',
  ),

  // 지세지형 (축→술→미→축)
  JijiHyung(
    jijis: ['축', '술'],
    type: HyungType.jiSe,
    description: '축술형(丑戌刑) - 지세지형',
  ),
  JijiHyung(
    jijis: ['술', '미'],
    type: HyungType.jiSe,
    description: '술미형(戌未刑) - 지세지형',
  ),
  JijiHyung(
    jijis: ['미', '축'],
    type: HyungType.jiSe,
    description: '미축형(未丑刑) - 지세지형',
  ),

  // 자형
  JijiHyung(
    jijis: ['진', '진'],
    type: HyungType.jaHyung,
    description: '진진자형(辰辰自刑)',
  ),
  JijiHyung(
    jijis: ['오', '오'],
    type: HyungType.jaHyung,
    description: '오오자형(午午自刑)',
  ),
  JijiHyung(
    jijis: ['유', '유'],
    type: HyungType.jaHyung,
    description: '유유자형(酉酉自刑)',
  ),
  JijiHyung(
    jijis: ['해', '해'],
    type: HyungType.jaHyung,
    description: '해해자형(亥亥自刑)',
  ),
];

/// 두 지지가 형인지 확인
JijiHyung? findJijiHyung(String ji1, String ji2) {
  for (final hyung in jijiHyungList) {
    final pair = hyung.jijis;
    if ((pair[0] == ji1 && pair[1] == ji2) ||
        (pair[0] == ji2 && pair[1] == ji1)) {
      return hyung;
    }
  }
  return null;
}

/// 자형 여부 확인
bool isJaHyung(String ji) {
  return ji == '진' || ji == '오' || ji == '유' || ji == '해';
}

// ============================================================================
// 지지파 (地支破)
// ============================================================================

/// 지지파 테이블
const Map<String, String> jijiPaPairs = {
  '자': '유', // 자유파
  '유': '자',
  '축': '진', // 축진파
  '진': '축',
  '인': '해', // 인해파
  '해': '인',
  '묘': '오', // 묘오파
  '오': '묘',
  '사': '신', // 사신파
  '신': '사',
  '술': '미', // 술미파
  '미': '술',
};

/// 두 지지가 파인지 확인
bool isJijiPa(String ji1, String ji2) {
  return jijiPaPairs[ji1] == ji2;
}

/// 지지파 짝 조회
String? getJijiPaPair(String ji) => jijiPaPairs[ji];

// ============================================================================
// 지지해 (地支害) - 6해
// ============================================================================

/// 지지해 테이블
const Map<String, String> jijiHaePairs = {
  '자': '미', // 자미해
  '미': '자',
  '축': '오', // 축오해
  '오': '축',
  '인': '사', // 인사해
  '사': '인',
  '묘': '진', // 묘진해
  '진': '묘',
  '신': '해', // 신해해
  '해': '신',
  '유': '술', // 유술해
  '술': '유',
};

/// 두 지지가 해인지 확인
bool isJijiHae(String ji1, String ji2) {
  return jijiHaePairs[ji1] == ji2;
}

/// 지지해 짝 조회
String? getJijiHaePair(String ji) => jijiHaePairs[ji];

// ============================================================================
// 원진 (怨嗔) - 6원진
// ============================================================================

/// 원진 테이블 (서로 미워하는 관계)
const Map<String, String> wonjinPairs = {
  '자': '미', // 자미원진
  '미': '자',
  '축': '오', // 축오원진
  '오': '축',
  '인': '유', // 인유원진
  '유': '인',
  '묘': '신', // 묘신원진
  '신': '묘',
  '진': '해', // 진해원진
  '해': '진',
  '사': '술', // 사술원진
  '술': '사',
};

/// 두 지지가 원진인지 확인
bool isWonjin(String ji1, String ji2) {
  return wonjinPairs[ji1] == ji2;
}

/// 원진 짝 조회
String? getWonjinPair(String ji) => wonjinPairs[ji];

// ============================================================================
// 통합 관계 분석
// ============================================================================

/// 지지 관계 유형
enum JijiRelationType {
  yukhap('육합', '六合'),
  samhap('삼합', '三合'),
  banghap('방합', '方合'),
  chung('충', '沖'),
  hyung('형', '刑'),
  pa('파', '破'),
  hae('해', '害'),
  wonjin('원진', '怨嗔');

  final String korean;
  final String hanja;

  const JijiRelationType(this.korean, this.hanja);
}

/// 두 지지 간의 모든 관계 분석
List<JijiRelationType> analyzeJijiRelations(String ji1, String ji2) {
  final relations = <JijiRelationType>[];

  if (isJijiYukhap(ji1, ji2)) relations.add(JijiRelationType.yukhap);
  if (findJijiHalfSamhap(ji1, ji2) != null) relations.add(JijiRelationType.samhap);
  if (isJijiChung(ji1, ji2)) relations.add(JijiRelationType.chung);
  if (findJijiHyung(ji1, ji2) != null) relations.add(JijiRelationType.hyung);
  if (isJijiPa(ji1, ji2)) relations.add(JijiRelationType.pa);
  if (isJijiHae(ji1, ji2)) relations.add(JijiRelationType.hae);
  if (isWonjin(ji1, ji2)) relations.add(JijiRelationType.wonjin);

  return relations;
}

/// 천간 관계 유형
enum CheonganRelationType {
  hap('합', '合'),
  chung('충', '沖');

  final String korean;
  final String hanja;

  const CheonganRelationType(this.korean, this.hanja);
}

/// 두 천간 간의 모든 관계 분석
List<CheonganRelationType> analyzeCheonganRelations(String gan1, String gan2) {
  final relations = <CheonganRelationType>[];

  if (isCheonganHap(gan1, gan2)) relations.add(CheonganRelationType.hap);
  if (isCheonganChung(gan1, gan2)) relations.add(CheonganRelationType.chung);

  return relations;
}
