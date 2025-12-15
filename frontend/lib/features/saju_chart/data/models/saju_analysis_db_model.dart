import '../../domain/entities/pillar.dart';
import '../../domain/entities/saju_chart.dart';

/// Supabase saju_analyses 테이블과 매핑되는 DB 모델
///
/// 테이블 스키마:
/// - id: UUID (PK)
/// - profile_id: UUID (FK -> saju_profiles)
/// - year_gan/year_ji: TEXT (년주)
/// - month_gan/month_ji: TEXT (월주)
/// - day_gan/day_ji: TEXT (일주)
/// - hour_gan/hour_ji: TEXT (시주, nullable)
/// - corrected_datetime: TIMESTAMPTZ (진태양시 보정 후)
/// - oheng_distribution: JSONB (오행 분포)
/// - day_strength: JSONB (일간 강약)
/// - yongsin: JSONB (용신)
/// - gyeokguk: JSONB (격국)
/// - sipsin_info: JSONB (십신 정보)
/// - jijanggan_info: JSONB (지장간 정보)
class SajuAnalysisDbModel {
  final String id;
  final String profileId;
  final String yearGan;
  final String yearJi;
  final String monthGan;
  final String monthJi;
  final String dayGan;
  final String dayJi;
  final String? hourGan;
  final String? hourJi;
  final DateTime correctedDatetime;
  final Map<String, dynamic>? ohengDistribution;
  final Map<String, dynamic>? dayStrength;
  final Map<String, dynamic>? yongsin;
  final Map<String, dynamic>? gyeokguk;
  final Map<String, dynamic>? sipsinInfo;
  final Map<String, dynamic>? jijangganInfo;

  const SajuAnalysisDbModel({
    required this.id,
    required this.profileId,
    required this.yearGan,
    required this.yearJi,
    required this.monthGan,
    required this.monthJi,
    required this.dayGan,
    required this.dayJi,
    this.hourGan,
    this.hourJi,
    required this.correctedDatetime,
    this.ohengDistribution,
    this.dayStrength,
    this.yongsin,
    this.gyeokguk,
    this.sipsinInfo,
    this.jijangganInfo,
  });

  /// Supabase JSON -> Model
  factory SajuAnalysisDbModel.fromSupabase(Map<String, dynamic> json) {
    return SajuAnalysisDbModel(
      id: json['id'] as String,
      profileId: json['profile_id'] as String,
      yearGan: json['year_gan'] as String,
      yearJi: json['year_ji'] as String,
      monthGan: json['month_gan'] as String,
      monthJi: json['month_ji'] as String,
      dayGan: json['day_gan'] as String,
      dayJi: json['day_ji'] as String,
      hourGan: json['hour_gan'] as String?,
      hourJi: json['hour_ji'] as String?,
      correctedDatetime: DateTime.parse(json['corrected_datetime'] as String),
      ohengDistribution: json['oheng_distribution'] as Map<String, dynamic>?,
      dayStrength: json['day_strength'] as Map<String, dynamic>?,
      yongsin: json['yongsin'] as Map<String, dynamic>?,
      gyeokguk: json['gyeokguk'] as Map<String, dynamic>?,
      sipsinInfo: json['sipsin_info'] as Map<String, dynamic>?,
      jijangganInfo: json['jijanggan_info'] as Map<String, dynamic>?,
    );
  }

  /// Model -> Supabase JSON (insert/update용)
  Map<String, dynamic> toSupabase() {
    return {
      'id': id,
      'profile_id': profileId,
      'year_gan': yearGan,
      'year_ji': yearJi,
      'month_gan': monthGan,
      'month_ji': monthJi,
      'day_gan': dayGan,
      'day_ji': dayJi,
      'hour_gan': hourGan,
      'hour_ji': hourJi,
      'corrected_datetime': correctedDatetime.toIso8601String(),
      'oheng_distribution': ohengDistribution,
      'day_strength': dayStrength,
      'yongsin': yongsin,
      'gyeokguk': gyeokguk,
      'sipsin_info': sipsinInfo,
      'jijanggan_info': jijangganInfo,
    };
  }

  /// SajuChart Entity -> DB Model
  /// 분석 결과를 포함하여 변환
  static SajuAnalysisDbModel fromSajuChart({
    required String id,
    required String profileId,
    required SajuChart chart,
    Map<String, dynamic>? ohengDistribution,
    Map<String, dynamic>? dayStrength,
    Map<String, dynamic>? yongsin,
    Map<String, dynamic>? gyeokguk,
    Map<String, dynamic>? sipsinInfo,
    Map<String, dynamic>? jijangganInfo,
  }) {
    return SajuAnalysisDbModel(
      id: id,
      profileId: profileId,
      yearGan: chart.yearPillar.cheongan,
      yearJi: chart.yearPillar.jiji,
      monthGan: chart.monthPillar.cheongan,
      monthJi: chart.monthPillar.jiji,
      dayGan: chart.dayPillar.cheongan,
      dayJi: chart.dayPillar.jiji,
      hourGan: chart.hourPillar?.cheongan,
      hourJi: chart.hourPillar?.jiji,
      correctedDatetime: chart.correctedDateTime,
      ohengDistribution: ohengDistribution,
      dayStrength: dayStrength,
      yongsin: yongsin,
      gyeokguk: gyeokguk,
      sipsinInfo: sipsinInfo,
      jijangganInfo: jijangganInfo,
    );
  }

  /// DB Model -> SajuChart Entity
  /// 기본 사주 정보만 변환 (분석 데이터는 별도 처리)
  SajuChart toSajuChart({
    required DateTime birthDateTime,
    required String birthCity,
    required bool isLunarCalendar,
  }) {
    return SajuChart(
      yearPillar: Pillar(cheongan: yearGan, jiji: yearJi),
      monthPillar: Pillar(cheongan: monthGan, jiji: monthJi),
      dayPillar: Pillar(cheongan: dayGan, jiji: dayJi),
      hourPillar: (hourGan != null && hourJi != null)
          ? Pillar(cheongan: hourGan!, jiji: hourJi!)
          : null,
      birthDateTime: birthDateTime,
      correctedDateTime: correctedDatetime,
      birthCity: birthCity,
      isLunarCalendar: isLunarCalendar,
    );
  }

  /// Hive 저장용 Map으로 변환
  Map<String, dynamic> toHiveMap() {
    return {
      'id': id,
      'profileId': profileId,
      'yearGan': yearGan,
      'yearJi': yearJi,
      'monthGan': monthGan,
      'monthJi': monthJi,
      'dayGan': dayGan,
      'dayJi': dayJi,
      'hourGan': hourGan,
      'hourJi': hourJi,
      'correctedDatetime': correctedDatetime.millisecondsSinceEpoch,
      'ohengDistribution': ohengDistribution,
      'dayStrength': dayStrength,
      'yongsin': yongsin,
      'gyeokguk': gyeokguk,
      'sipsinInfo': sipsinInfo,
      'jijangganInfo': jijangganInfo,
      'syncedAt': DateTime.now().millisecondsSinceEpoch,
    };
  }

  /// Hive Map -> Model
  factory SajuAnalysisDbModel.fromHiveMap(Map<dynamic, dynamic> map) {
    return SajuAnalysisDbModel(
      id: map['id'] as String,
      profileId: map['profileId'] as String,
      yearGan: map['yearGan'] as String,
      yearJi: map['yearJi'] as String,
      monthGan: map['monthGan'] as String,
      monthJi: map['monthJi'] as String,
      dayGan: map['dayGan'] as String,
      dayJi: map['dayJi'] as String,
      hourGan: map['hourGan'] as String?,
      hourJi: map['hourJi'] as String?,
      correctedDatetime: DateTime.fromMillisecondsSinceEpoch(
        map['correctedDatetime'] as int,
      ),
      ohengDistribution: _castMap(map['ohengDistribution']),
      dayStrength: _castMap(map['dayStrength']),
      yongsin: _castMap(map['yongsin']),
      gyeokguk: _castMap(map['gyeokguk']),
      sipsinInfo: _castMap(map['sipsinInfo']),
      jijangganInfo: _castMap(map['jijangganInfo']),
    );
  }

  /// dynamic Map -> Map<String, dynamic> 안전 변환
  static Map<String, dynamic>? _castMap(dynamic value) {
    if (value == null) return null;
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return null;
  }

  /// copyWith
  SajuAnalysisDbModel copyWith({
    String? id,
    String? profileId,
    String? yearGan,
    String? yearJi,
    String? monthGan,
    String? monthJi,
    String? dayGan,
    String? dayJi,
    String? hourGan,
    String? hourJi,
    DateTime? correctedDatetime,
    Map<String, dynamic>? ohengDistribution,
    Map<String, dynamic>? dayStrength,
    Map<String, dynamic>? yongsin,
    Map<String, dynamic>? gyeokguk,
    Map<String, dynamic>? sipsinInfo,
    Map<String, dynamic>? jijangganInfo,
  }) {
    return SajuAnalysisDbModel(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      yearGan: yearGan ?? this.yearGan,
      yearJi: yearJi ?? this.yearJi,
      monthGan: monthGan ?? this.monthGan,
      monthJi: monthJi ?? this.monthJi,
      dayGan: dayGan ?? this.dayGan,
      dayJi: dayJi ?? this.dayJi,
      hourGan: hourGan ?? this.hourGan,
      hourJi: hourJi ?? this.hourJi,
      correctedDatetime: correctedDatetime ?? this.correctedDatetime,
      ohengDistribution: ohengDistribution ?? this.ohengDistribution,
      dayStrength: dayStrength ?? this.dayStrength,
      yongsin: yongsin ?? this.yongsin,
      gyeokguk: gyeokguk ?? this.gyeokguk,
      sipsinInfo: sipsinInfo ?? this.sipsinInfo,
      jijangganInfo: jijangganInfo ?? this.jijangganInfo,
    );
  }

  @override
  String toString() {
    return 'SajuAnalysisDbModel(id: $id, profileId: $profileId, '
        '사주: $yearGan$yearJi $monthGan$monthJi $dayGan$dayJi ${hourGan ?? ""}${hourJi ?? ""})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SajuAnalysisDbModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
