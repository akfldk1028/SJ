import '../../domain/entities/pillar.dart';
import '../../domain/entities/saju_chart.dart';
import 'pillar_model.dart';

/// SajuChart 모델
/// Entity를 확장하여 JSON 직렬화 기능 추가
class SajuChartModel extends SajuChart {
  const SajuChartModel({
    required super.yearPillar,
    required super.monthPillar,
    required super.dayPillar,
    super.hourPillar,
    required super.birthDateTime,
    required super.correctedDateTime,
    required super.birthCity,
    required super.isLunarCalendar,
  });

  /// Entity를 Model로 변환
  factory SajuChartModel.fromEntity(SajuChart entity) {
    return SajuChartModel(
      yearPillar: entity.yearPillar,
      monthPillar: entity.monthPillar,
      dayPillar: entity.dayPillar,
      hourPillar: entity.hourPillar,
      birthDateTime: entity.birthDateTime,
      correctedDateTime: entity.correctedDateTime,
      birthCity: entity.birthCity,
      isLunarCalendar: entity.isLunarCalendar,
    );
  }

  /// Entity로 변환
  SajuChart toEntity() {
    return SajuChart(
      yearPillar: yearPillar,
      monthPillar: monthPillar,
      dayPillar: dayPillar,
      hourPillar: hourPillar,
      birthDateTime: birthDateTime,
      correctedDateTime: correctedDateTime,
      birthCity: birthCity,
      isLunarCalendar: isLunarCalendar,
    );
  }

  /// JSON 직렬화
  @override
  Map<String, dynamic> toJson() => {
        'yearPillar': PillarModel.fromEntity(yearPillar).toJson(),
        'monthPillar': PillarModel.fromEntity(monthPillar).toJson(),
        'dayPillar': PillarModel.fromEntity(dayPillar).toJson(),
        'hourPillar': hourPillar != null
            ? PillarModel.fromEntity(hourPillar!).toJson()
            : null,
        'birthDateTime': birthDateTime.toIso8601String(),
        'correctedDateTime': correctedDateTime.toIso8601String(),
        'birthCity': birthCity,
        'isLunarCalendar': isLunarCalendar,
        'fullSaju': fullSaju,
        'fullSajuHanja': fullSajuHanja,
        'dayMaster': dayMaster,
        'hasUnknownBirthTime': hasUnknownBirthTime,
      };

  /// JSON 역직렬화
  factory SajuChartModel.fromJson(Map<String, dynamic> json) {
    return SajuChartModel(
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

  /// copyWith
  SajuChartModel copyWith({
    Pillar? yearPillar,
    Pillar? monthPillar,
    Pillar? dayPillar,
    Pillar? hourPillar,
    DateTime? birthDateTime,
    DateTime? correctedDateTime,
    String? birthCity,
    bool? isLunarCalendar,
  }) {
    return SajuChartModel(
      yearPillar: yearPillar ?? this.yearPillar,
      monthPillar: monthPillar ?? this.monthPillar,
      dayPillar: dayPillar ?? this.dayPillar,
      hourPillar: hourPillar ?? this.hourPillar,
      birthDateTime: birthDateTime ?? this.birthDateTime,
      correctedDateTime: correctedDateTime ?? this.correctedDateTime,
      birthCity: birthCity ?? this.birthCity,
      isLunarCalendar: isLunarCalendar ?? this.isLunarCalendar,
    );
  }
}
