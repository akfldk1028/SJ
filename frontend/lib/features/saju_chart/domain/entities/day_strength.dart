/// 일간 강약 분석 결과
/// 일간(나)의 세력이 강한지 약한지 판단
class DayStrength {
  /// 총점 (0-100)
  final int score;

  /// 강약 등급
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

  const DayStrength({
    required this.score,
    required this.level,
    required this.monthScore,
    required this.bigeopScore,
    required this.inseongScore,
    required this.exhaustionScore,
    required this.details,
  });

  /// 신강 여부
  bool get isStrong =>
      level == DayStrengthLevel.veryStrong || level == DayStrengthLevel.strong;

  /// 신약 여부
  bool get isWeak =>
      level == DayStrengthLevel.veryWeak || level == DayStrengthLevel.weak;

  /// 중화 여부
  bool get isNeutral => level == DayStrengthLevel.medium;
}

/// 일간 강약 등급
enum DayStrengthLevel {
  /// 신강 (80점 이상)
  veryStrong('신강', '身强'),

  /// 강 (65-79점)
  strong('강', '强'),

  /// 중 (40-64점)
  medium('중화', '中和'),

  /// 약 (25-39점)
  weak('약', '弱'),

  /// 신약 (24점 이하)
  veryWeak('신약', '身弱');

  final String korean;
  final String hanja;

  const DayStrengthLevel(this.korean, this.hanja);
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
