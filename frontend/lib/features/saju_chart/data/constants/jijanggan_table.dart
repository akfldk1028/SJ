/// 지장간(地藏干) 테이블
/// 12지지 각각에 숨어있는 천간과 세력 비율
///
/// 지장간은 지지 속에 감춰진 천간의 기운으로
/// - 정기(正氣): 가장 강한 주된 기운 (본기)
/// - 중기(中氣): 중간 세력의 기운
/// - 여기(餘氣): 잔여 기운
///
/// 세력 비율은 절기 경과일에 따라 변동 가능

/// 지장간 정보 클래스
class JiJangGan {
  /// 천간
  final String gan;

  /// 세력 비율 (0-100)
  final int strength;

  /// 기운 유형 (정기/중기/여기)
  final JiJangGanType type;

  const JiJangGan({
    required this.gan,
    required this.strength,
    required this.type,
  });
}

/// 지장간 기운 유형
enum JiJangGanType {
  /// 정기 (본기) - 가장 강한 기운
  jeongGi,

  /// 중기 - 중간 기운
  jungGi,

  /// 여기 - 잔여 기운
  yeoGi,
}

/// 지지별 지장간 테이블
/// 순서: [여기, 중기, 정기] (세력 순)
const Map<String, List<JiJangGan>> jiJangGanTable = {
  // 자(子) - 계수(癸水)만 있음
  '자': [
    JiJangGan(gan: '계', strength: 100, type: JiJangGanType.jeongGi),
  ],

  // 축(丑) - 계수, 신금, 기토
  '축': [
    JiJangGan(gan: '계', strength: 9, type: JiJangGanType.yeoGi),
    JiJangGan(gan: '신', strength: 3, type: JiJangGanType.jungGi),
    JiJangGan(gan: '기', strength: 18, type: JiJangGanType.jeongGi),
  ],

  // 인(寅) - 무토, 병화, 갑목
  '인': [
    JiJangGan(gan: '무', strength: 7, type: JiJangGanType.yeoGi),
    JiJangGan(gan: '병', strength: 7, type: JiJangGanType.jungGi),
    JiJangGan(gan: '갑', strength: 16, type: JiJangGanType.jeongGi),
  ],

  // 묘(卯) - 을목만 있음
  '묘': [
    JiJangGan(gan: '을', strength: 100, type: JiJangGanType.jeongGi),
  ],

  // 진(辰) - 을목, 계수, 무토
  '진': [
    JiJangGan(gan: '을', strength: 9, type: JiJangGanType.yeoGi),
    JiJangGan(gan: '계', strength: 3, type: JiJangGanType.jungGi),
    JiJangGan(gan: '무', strength: 18, type: JiJangGanType.jeongGi),
  ],

  // 사(巳) - 무토, 경금, 병화
  '사': [
    JiJangGan(gan: '무', strength: 7, type: JiJangGanType.yeoGi),
    JiJangGan(gan: '경', strength: 7, type: JiJangGanType.jungGi),
    JiJangGan(gan: '병', strength: 16, type: JiJangGanType.jeongGi),
  ],

  // 오(午) - 기토, 정화
  '오': [
    JiJangGan(gan: '기', strength: 9, type: JiJangGanType.yeoGi),
    JiJangGan(gan: '정', strength: 21, type: JiJangGanType.jeongGi),
  ],

  // 미(未) - 정화, 을목, 기토
  '미': [
    JiJangGan(gan: '정', strength: 9, type: JiJangGanType.yeoGi),
    JiJangGan(gan: '을', strength: 3, type: JiJangGanType.jungGi),
    JiJangGan(gan: '기', strength: 18, type: JiJangGanType.jeongGi),
  ],

  // 신(申) - 무토, 임수, 경금
  '신': [
    JiJangGan(gan: '무', strength: 7, type: JiJangGanType.yeoGi),
    JiJangGan(gan: '임', strength: 7, type: JiJangGanType.jungGi),
    JiJangGan(gan: '경', strength: 16, type: JiJangGanType.jeongGi),
  ],

  // 유(酉) - 신금만 있음
  '유': [
    JiJangGan(gan: '신', strength: 100, type: JiJangGanType.jeongGi),
  ],

  // 술(戌) - 신금, 정화, 무토
  '술': [
    JiJangGan(gan: '신', strength: 9, type: JiJangGanType.yeoGi),
    JiJangGan(gan: '정', strength: 3, type: JiJangGanType.jungGi),
    JiJangGan(gan: '무', strength: 18, type: JiJangGanType.jeongGi),
  ],

  // 해(亥) - 무토, 갑목, 임수
  '해': [
    JiJangGan(gan: '무', strength: 7, type: JiJangGanType.yeoGi),
    JiJangGan(gan: '갑', strength: 7, type: JiJangGanType.jungGi),
    JiJangGan(gan: '임', strength: 16, type: JiJangGanType.jeongGi),
  ],
};

/// 지지의 지장간 목록 조회
List<JiJangGan> getJiJangGan(String ji) {
  return jiJangGanTable[ji] ?? [];
}

/// 지지의 정기(본기) 조회
String? getJeongGi(String ji) {
  final jijanggan = jiJangGanTable[ji];
  if (jijanggan == null) return null;

  for (final gan in jijanggan) {
    if (gan.type == JiJangGanType.jeongGi) {
      return gan.gan;
    }
  }
  return null;
}

/// 지지의 중기 조회
String? getJungGi(String ji) {
  final jijanggan = jiJangGanTable[ji];
  if (jijanggan == null) return null;

  for (final gan in jijanggan) {
    if (gan.type == JiJangGanType.jungGi) {
      return gan.gan;
    }
  }
  return null;
}

/// 지지의 여기 조회
String? getYeoGi(String ji) {
  final jijanggan = jiJangGanTable[ji];
  if (jijanggan == null) return null;

  for (final gan in jijanggan) {
    if (gan.type == JiJangGanType.yeoGi) {
      return gan.gan;
    }
  }
  return null;
}

/// 지장간 세력 비율 테이블 (절기 일수 기반)
/// 각 지지별 [여기 일수, 중기 일수, 정기 일수]
const Map<String, List<int>> jiJangGanDaysTable = {
  '자': [0, 0, 30], // 계수만
  '축': [9, 3, 18], // 계수9일, 신금3일, 기토18일
  '인': [7, 7, 16], // 무토7일, 병화7일, 갑목16일
  '묘': [0, 0, 30], // 을목만
  '진': [9, 3, 18], // 을목9일, 계수3일, 무토18일
  '사': [7, 7, 16], // 무토7일, 경금7일, 병화16일
  '오': [9, 0, 21], // 기토9일, 정화21일 (중기 없음)
  '미': [9, 3, 18], // 정화9일, 을목3일, 기토18일
  '신': [7, 7, 16], // 무토7일, 임수7일, 경금16일
  '유': [0, 0, 30], // 신금만
  '술': [9, 3, 18], // 신금9일, 정화3일, 무토18일
  '해': [7, 7, 16], // 무토7일, 갑목7일, 임수16일
};
