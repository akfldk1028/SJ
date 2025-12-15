import '../../domain/entities/pillar.dart';
import '../../domain/entities/saju_chart.dart';
import '../constants/cheongan_jiji.dart';

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
/// - sinsal_list: JSONB (신살 목록)
/// - daeun: JSONB (대운 정보)
/// - current_seun: JSONB (현재 세운)
/// - twelve_unsung: JSONB (12운성 - 년/월/일/시주별)
/// - twelve_sinsal: JSONB (12신살 - 년/월/일/시주별)
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
  final List<Map<String, dynamic>>? sinsalList;
  final Map<String, dynamic>? daeun;
  final Map<String, dynamic>? currentSeun;
  final List<Map<String, dynamic>>? twelveUnsung;
  final List<Map<String, dynamic>>? twelveSinsal;

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
    this.sinsalList,
    this.daeun,
    this.currentSeun,
    this.twelveUnsung,
    this.twelveSinsal,
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
      sinsalList: (json['sinsal_list'] as List<dynamic>?)
          ?.map((e) => Map<String, dynamic>.from(e as Map))
          .toList(),
      daeun: json['daeun'] as Map<String, dynamic>?,
      currentSeun: json['current_seun'] as Map<String, dynamic>?,
      twelveUnsung: (json['twelve_unsung'] as List<dynamic>?)
          ?.map((e) => Map<String, dynamic>.from(e as Map))
          .toList(),
      twelveSinsal: (json['twelve_sinsal'] as List<dynamic>?)
          ?.map((e) => Map<String, dynamic>.from(e as Map))
          .toList(),
    );
  }

  /// Model -> Supabase JSON (insert/update용)
  /// 모든 천간/지지 필드를 한글(한자) 형식으로 변환하여 저장
  Map<String, dynamic> toSupabase() {
    return {
      'id': id,
      'profile_id': profileId,
      'year_gan': _formatWithHanja(yearGan, isCheongan: true),
      'year_ji': _formatWithHanja(yearJi, isCheongan: false),
      'month_gan': _formatWithHanja(monthGan, isCheongan: true),
      'month_ji': _formatWithHanja(monthJi, isCheongan: false),
      'day_gan': _formatWithHanja(dayGan, isCheongan: true),
      'day_ji': _formatWithHanja(dayJi, isCheongan: false),
      'hour_gan': hourGan != null
          ? _formatWithHanja(hourGan!, isCheongan: true)
          : null,
      'hour_ji': hourJi != null
          ? _formatWithHanja(hourJi!, isCheongan: false)
          : null,
      'corrected_datetime': correctedDatetime.toIso8601String(),
      'oheng_distribution': ohengDistribution,
      'day_strength': dayStrength,
      'yongsin': yongsin,
      'gyeokguk': gyeokguk,
      'sipsin_info': sipsinInfo,
      'jijanggan_info': jijangganInfo,
      'sinsal_list': sinsalList,
      'daeun': daeun,
      'current_seun': currentSeun,
      'twelve_unsung': twelveUnsung,
      'twelve_sinsal': twelveSinsal,
    };
  }

  /// 한글을 한글(한자) 형식으로 변환
  /// 예: "갑" → "갑(甲)", "자" → "자(子)"
  static String _formatWithHanja(String hangul, {required bool isCheongan}) {
    // 이미 한자가 포함되어 있으면 그대로 반환
    if (hangul.contains('(') && hangul.contains(')')) {
      return hangul;
    }

    final hanja = isCheongan ? cheonganHanja[hangul] : jijiHanja[hangul];
    if (hanja != null) {
      return '$hangul($hanja)';
    }
    return hangul;
  }

  /// 한글(한자) 형식에서 한글만 추출
  /// 예: "갑(甲)" → "갑", "자(子)" → "자"
  static String _extractHangul(String formatted) {
    if (formatted.contains('(')) {
      return formatted.substring(0, formatted.indexOf('('));
    }
    return formatted;
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
    List<Map<String, dynamic>>? sinsalList,
    Map<String, dynamic>? daeun,
    Map<String, dynamic>? currentSeun,
    List<Map<String, dynamic>>? twelveUnsung,
    List<Map<String, dynamic>>? twelveSinsal,
  }) {
    return SajuAnalysisDbModel(
      id: id,
      profileId: profileId,
      yearGan: chart.yearPillar.gan,
      yearJi: chart.yearPillar.ji,
      monthGan: chart.monthPillar.gan,
      monthJi: chart.monthPillar.ji,
      dayGan: chart.dayPillar.gan,
      dayJi: chart.dayPillar.ji,
      hourGan: chart.hourPillar?.gan,
      hourJi: chart.hourPillar?.ji,
      correctedDatetime: chart.correctedDateTime,
      ohengDistribution: ohengDistribution,
      dayStrength: dayStrength,
      yongsin: yongsin,
      gyeokguk: gyeokguk,
      sipsinInfo: sipsinInfo,
      jijangganInfo: jijangganInfo,
      sinsalList: sinsalList,
      daeun: daeun,
      currentSeun: currentSeun,
      twelveUnsung: twelveUnsung,
      twelveSinsal: twelveSinsal,
    );
  }

  /// DB Model -> SajuChart Entity
  /// 기본 사주 정보만 변환 (분석 데이터는 별도 처리)
  /// 한글(한자) 형식의 데이터에서 한글만 추출하여 Pillar 생성
  SajuChart toSajuChart({
    required DateTime birthDateTime,
    required String birthCity,
    required bool isLunarCalendar,
  }) {
    return SajuChart(
      yearPillar: Pillar(
        gan: _extractHangul(yearGan),
        ji: _extractHangul(yearJi),
      ),
      monthPillar: Pillar(
        gan: _extractHangul(monthGan),
        ji: _extractHangul(monthJi),
      ),
      dayPillar: Pillar(
        gan: _extractHangul(dayGan),
        ji: _extractHangul(dayJi),
      ),
      hourPillar: (hourGan != null && hourJi != null)
          ? Pillar(
              gan: _extractHangul(hourGan!),
              ji: _extractHangul(hourJi!),
            )
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
      'sinsalList': sinsalList,
      'daeun': daeun,
      'currentSeun': currentSeun,
      'twelveUnsung': twelveUnsung,
      'twelveSinsal': twelveSinsal,
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
      sinsalList: _castList(map['sinsalList']),
      daeun: _castMap(map['daeun']),
      currentSeun: _castMap(map['currentSeun']),
      twelveUnsung: _castList(map['twelveUnsung']),
      twelveSinsal: _castList(map['twelveSinsal']),
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

  /// dynamic List -> List<Map<String, dynamic>> 안전 변환
  static List<Map<String, dynamic>>? _castList(dynamic value) {
    if (value == null) return null;
    if (value is List) {
      return value
          .map((e) => e is Map ? Map<String, dynamic>.from(e) : <String, dynamic>{})
          .toList();
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
    List<Map<String, dynamic>>? sinsalList,
    Map<String, dynamic>? daeun,
    Map<String, dynamic>? currentSeun,
    List<Map<String, dynamic>>? twelveUnsung,
    List<Map<String, dynamic>>? twelveSinsal,
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
      sinsalList: sinsalList ?? this.sinsalList,
      daeun: daeun ?? this.daeun,
      currentSeun: currentSeun ?? this.currentSeun,
      twelveUnsung: twelveUnsung ?? this.twelveUnsung,
      twelveSinsal: twelveSinsal ?? this.twelveSinsal,
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
