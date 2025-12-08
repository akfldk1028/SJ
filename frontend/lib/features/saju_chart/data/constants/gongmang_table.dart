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
enum GongmangType {
  /// 진공(眞空) - 완전한 공망
  jinGong('진공', '眞空', '공망의 기운이 완전히 작용'),

  /// 반공(半空) - 부분 공망
  banGong('반공', '半空', '공망의 기운이 일부만 작용'),

  /// 탈공(脫空) - 공망 해소
  talGong('탈공', '脫空', '공망이 해소되어 작용하지 않음');

  final String korean;
  final String hanja;
  final String description;

  const GongmangType(this.korean, this.hanja, this.description);
}

/// 공망 유형 판단 (간략화된 버전)
/// 실제로는 운에서 공망이 채워지는지 등을 봐야 함
GongmangType determineGongmangType({
  required String dayGan,
  required String dayJi,
  required String targetJi,
  String? currentDaeunJi, // 현재 대운의 지지
  String? currentSaeunJi, // 현재 세운의 지지
}) {
  final gongmangJijis = getDayGongmang(dayGan, dayJi);

  // 대상이 공망이 아니면 해당 없음
  if (!gongmangJijis.contains(targetJi)) {
    return GongmangType.talGong;
  }

  // 대운이나 세운에서 공망 지지가 들어오면 탈공
  if (currentDaeunJi == targetJi || currentSaeunJi == targetJi) {
    return GongmangType.talGong;
  }

  // 그 외에는 진공
  return GongmangType.jinGong;
}
