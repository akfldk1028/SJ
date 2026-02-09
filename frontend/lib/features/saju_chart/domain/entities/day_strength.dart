/// 일간 강약 분석 결과
/// 일간(나)의 세력이 강한지 약한지 판단
class DayStrength {
  /// 총점 (0-100)
  final int score;

  /// 강약 등급 (8단계)
  final DayStrengthLevel level;

  /// 월령 득실 점수
  final int monthScore;

  /// 비겁 점수
  final int bigeopScore;

  /// 인성 점수
  final int inseongScore;

  /// 재관식상 감점
  final int exhaustionScore;

  /// 세부 분석 정보
  final DayStrengthDetails details;

  /// 득령 여부 (월지 정기가 일간을 생하거나 같은 오행)
  final bool deukryeong;

  /// 득지 여부 (일지 정기가 일간을 생하거나 같은 오행)
  final bool deukji;

  /// 득시 여부 (시지 정기가 일간을 생하거나 같은 오행)
  final bool deuksi;

  /// 득세 여부 (비겁/인성이 3개 이상)
  final bool deukse;

  const DayStrength({
    required this.score,
    required this.level,
    required this.monthScore,
    required this.bigeopScore,
    required this.inseongScore,
    required this.exhaustionScore,
    required this.details,
    this.deukryeong = false,
    this.deukji = false,
    this.deuksi = false,
    this.deukse = false,
  });

  /// 신강 여부 (중화신강 이상)
  bool get isStrong => score >= 50;

  /// 신약 여부 (중화신약 이하)
  bool get isWeak => score < 50;

  /// 중화 여부 (중화신강 또는 중화신약)
  bool get isNeutral =>
      level == DayStrengthLevel.junghwaSingang ||
      level == DayStrengthLevel.junghwaSinyak;

  /// 득 개수 (득령/득지/득시/득세 중 true인 개수)
  int get deukCount =>
      (deukryeong ? 1 : 0) +
      (deukji ? 1 : 0) +
      (deuksi ? 1 : 0) +
      (deukse ? 1 : 0);
}

/// 일간 강약 등급 (8단계 - 포스텔러 기준)
enum DayStrengthLevel {
  /// 극왕 (85-100점)
  geukwang('극왕', '極旺'),

  /// 태강 (72-84점)
  taegang('태강', '太强'),

  /// 신강 (60-71점)
  singang('신강', '身强'),

  /// 중화신강 (47-59점)
  junghwaSingang('중화신강', '中和身强'),

  /// 중화신약 (34-46점)
  junghwaSinyak('중화신약', '中和身弱'),

  /// 신약 (22-33점)
  sinyak('신약', '身弱'),

  /// 태약 (11-21점)
  taeyak('태약', '太弱'),

  /// 극약 (0-10점)
  geukyak('극약', '極弱');

  final String korean;
  final String hanja;

  const DayStrengthLevel(this.korean, this.hanja);

  /// score(0-100)로 등급 결정 (경계값 단일 소스)
  ///
  /// 캐시 로딩 시에도 이 메서드로 재계산하여
  /// 경계값 변경이 기존 사용자에게도 즉시 반영됨
  static DayStrengthLevel fromScore(int score) {
    if (score >= 85) return DayStrengthLevel.geukwang;       // 85%+ 극왕
    if (score >= 72) return DayStrengthLevel.taegang;        // 72-84% 태강
    if (score >= 60) return DayStrengthLevel.singang;        // 60-71% 신강
    if (score >= 47) return DayStrengthLevel.junghwaSingang; // 47-59% 중화신강
    if (score >= 34) return DayStrengthLevel.junghwaSinyak;  // 34-46% 중화신약
    if (score >= 22) return DayStrengthLevel.sinyak;         // 22-33% 신약
    if (score >= 11) return DayStrengthLevel.taeyak;         // 11-21% 태약
    return DayStrengthLevel.geukyak;                          // 0-10% 극약
  }

  /// 8단계 인덱스 (0=극약 ~ 7=극왕)
  int get index8 {
    switch (this) {
      case DayStrengthLevel.geukyak:
        return 0;
      case DayStrengthLevel.taeyak:
        return 1;
      case DayStrengthLevel.sinyak:
        return 2;
      case DayStrengthLevel.junghwaSinyak:
        return 3;
      case DayStrengthLevel.junghwaSingang:
        return 4;
      case DayStrengthLevel.singang:
        return 5;
      case DayStrengthLevel.taegang:
        return 6;
      case DayStrengthLevel.geukwang:
        return 7;
    }
  }
}

/// 일간 강약 세부 분석
class DayStrengthDetails {
  /// 월령 득실 상태
  final MonthStatus monthStatus;

  /// 비겁(비견+겁재) 개수
  final int bigeopCount;

  /// 인성(편인+정인) 개수
  final int inseongCount;

  /// 재성(편재+정재) 개수
  final int jaeseongCount;

  /// 관성(편관+정관) 개수
  final int gwanseongCount;

  /// 식상(식신+상관) 개수
  final int siksangCount;

  /// 일간을 돕는 요소 수 (비겁+인성)
  int get supportCount => bigeopCount + inseongCount;

  /// 일간을 설기하는 요소 수 (재관식상)
  int get exhaustCount => jaeseongCount + gwanseongCount + siksangCount;

  const DayStrengthDetails({
    required this.monthStatus,
    required this.bigeopCount,
    required this.inseongCount,
    required this.jaeseongCount,
    required this.gwanseongCount,
    required this.siksangCount,
  });
}

/// 월령 득실 상태
enum MonthStatus {
  /// 득월 (월지가 일간을 생하거나 같은 오행)
  deukwol('득월', '得月'),

  /// 중립 (월지가 일간과 상생도 상극도 아님)
  neutral('중립', '中立'),

  /// 실월 (월지가 일간을 극하거나 설기)
  silwol('실월', '失月');

  final String korean;
  final String hanja;

  const MonthStatus(this.korean, this.hanja);
}
