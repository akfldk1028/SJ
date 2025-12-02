import 'pillar.dart';

/// 사주팔자 차트
/// 4개의 기둥(년주, 월주, 일주, 시주)으로 구성
class SajuChart {
  final Pillar yearPillar;   // 연주 (年柱)
  final Pillar monthPillar;  // 월주 (月柱)
  final Pillar dayPillar;    // 일주 (日柱) - 일간이 "나"
  final Pillar? hourPillar;  // 시주 (時柱) - 출생시간 모르면 null

  final DateTime birthDateTime;      // 입력된 출생일시
  final DateTime correctedDateTime;  // 보정된 출생일시 (진태양시)
  final String birthCity;            // 출생지
  final bool isLunarCalendar;        // 음력 여부

  const SajuChart({
    required this.yearPillar,
    required this.monthPillar,
    required this.dayPillar,
    this.hourPillar,
    required this.birthDateTime,
    required this.correctedDateTime,
    required this.birthCity,
    required this.isLunarCalendar,
  });

  /// 일간 (日干) - "나"를 나타내는 천간
  String get dayMaster => dayPillar.gan;

  /// 사주팔자 전체 문자열 (예: "갑자 을축 병인 정묘")
  String get fullSaju {
    final hour = hourPillar != null ? ' ${hourPillar!.fullName}' : '';
    return '${yearPillar.fullName} ${monthPillar.fullName} ${dayPillar.fullName}$hour';
  }

  /// 사주팔자 한자 표기
  String get fullSajuHanja {
    final hour = hourPillar != null ? ' ${hourPillar!.hanja}' : '';
    return '${yearPillar.hanja} ${monthPillar.hanja} ${dayPillar.hanja}$hour';
  }

  /// 출생시간 알 수 없음 여부
  bool get hasUnknownBirthTime => hourPillar == null;

  @override
  String toString() => fullSaju;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SajuChart &&
        other.yearPillar == yearPillar &&
        other.monthPillar == monthPillar &&
        other.dayPillar == dayPillar &&
        other.hourPillar == hourPillar &&
        other.birthDateTime == birthDateTime &&
        other.correctedDateTime == correctedDateTime &&
        other.birthCity == birthCity &&
        other.isLunarCalendar == isLunarCalendar;
  }

  @override
  int get hashCode => Object.hash(
        yearPillar,
        monthPillar,
        dayPillar,
        hourPillar,
        birthDateTime,
        correctedDateTime,
        birthCity,
        isLunarCalendar,
      );

  /// JSON 직렬화
  Map<String, dynamic> toJson() => {
        'yearPillar': yearPillar.toJson(),
        'monthPillar': monthPillar.toJson(),
        'dayPillar': dayPillar.toJson(),
        'hourPillar': hourPillar?.toJson(),
        'birthDateTime': birthDateTime.toIso8601String(),
        'correctedDateTime': correctedDateTime.toIso8601String(),
        'birthCity': birthCity,
        'isLunarCalendar': isLunarCalendar,
      };

  /// JSON 역직렬화
  factory SajuChart.fromJson(Map<String, dynamic> json) {
    return SajuChart(
      yearPillar: Pillar.fromJson(json['yearPillar'] as Map<String, dynamic>),
      monthPillar:
          Pillar.fromJson(json['monthPillar'] as Map<String, dynamic>),
      dayPillar: Pillar.fromJson(json['dayPillar'] as Map<String, dynamic>),
      hourPillar: json['hourPillar'] != null
          ? Pillar.fromJson(json['hourPillar'] as Map<String, dynamic>)
          : null,
      birthDateTime: DateTime.parse(json['birthDateTime'] as String),
      correctedDateTime: DateTime.parse(json['correctedDateTime'] as String),
      birthCity: json['birthCity'] as String,
      isLunarCalendar: json['isLunarCalendar'] as bool,
    );
  }
}
