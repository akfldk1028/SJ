import '../../domain/entities/daeun.dart';
import '../../domain/entities/day_strength.dart';
import '../../domain/entities/gyeokguk.dart';
import '../../domain/entities/pillar.dart';
import '../../domain/entities/saju_analysis.dart';
import '../../domain/entities/saju_chart.dart';
import '../../domain/entities/sinsal.dart';
import '../../domain/entities/yongsin.dart';
import '../constants/sipsin_relations.dart';

/// SajuAnalysis를 Supabase와 연동하기 위한 Model 클래스
/// Entity ↔ Supabase Map 변환을 담당
class SajuAnalysisModel {
  final String? id;
  final String profileId;
  final SajuAnalysis analysis;

  const SajuAnalysisModel({
    this.id,
    required this.profileId,
    required this.analysis,
  });

  /// Entity를 Model로 변환
  factory SajuAnalysisModel.fromEntity({
    String? id,
    required String profileId,
    required SajuAnalysis analysis,
  }) {
    return SajuAnalysisModel(
      id: id,
      profileId: profileId,
      analysis: analysis,
    );
  }

  /// Supabase INSERT용 Map (snake_case)
  Map<String, dynamic> toSupabaseInsert() {
    final chart = analysis.chart;
    return {
      'profile_id': profileId,
      // 4주 기본 정보
      'year_gan': chart.yearPillar.gan,
      'year_ji': chart.yearPillar.ji,
      'month_gan': chart.monthPillar.gan,
      'month_ji': chart.monthPillar.ji,
      'day_gan': chart.dayPillar.gan,
      'day_ji': chart.dayPillar.ji,
      'hour_gan': chart.hourPillar?.gan,
      'hour_ji': chart.hourPillar?.ji,
      'corrected_datetime': chart.correctedDateTime.toIso8601String(),
      // JSONB 필드들
      'oheng_distribution': _ohengToJson(analysis.ohengDistribution),
      'day_strength': _dayStrengthToJson(analysis.dayStrength),
      'yongsin': _yongsinToJson(analysis.yongsin),
      'gyeokguk': _gyeokgukToJson(analysis.gyeokguk),
      'sipsin_info': _sipsinInfoToJson(analysis.sipsinInfo),
      'jijanggan_info': _jijangganInfoToJson(analysis.jijangganInfo),
      'sinsal_list': _sinsalListToJson(analysis.sinsalList),
      'daeun': analysis.daeun != null ? _daeunToJson(analysis.daeun!) : null,
      'current_seun':
          analysis.currentSeun != null
              ? _seunToJson(analysis.currentSeun!)
              : null,
    };
  }

  /// Supabase 전체 Map (ID 포함)
  Map<String, dynamic> toSupabaseMap() {
    final map = toSupabaseInsert();
    if (id != null) {
      map['id'] = id;
    }
    return map;
  }

  /// Supabase Map에서 Model 생성
  static SajuAnalysisModel fromSupabaseMap(Map<String, dynamic> map) {
    // 4주 생성
    final yearPillar = Pillar(
      gan: map['year_gan'] as String,
      ji: map['year_ji'] as String,
    );
    final monthPillar = Pillar(
      gan: map['month_gan'] as String,
      ji: map['month_ji'] as String,
    );
    final dayPillar = Pillar(
      gan: map['day_gan'] as String,
      ji: map['day_ji'] as String,
    );
    final hourPillar =
        map['hour_gan'] != null && map['hour_ji'] != null
            ? Pillar(
              gan: map['hour_gan'] as String,
              ji: map['hour_ji'] as String,
            )
            : null;

    // SajuChart 생성 (birth_city 등은 profile에서 가져와야 함)
    final chart = SajuChart(
      yearPillar: yearPillar,
      monthPillar: monthPillar,
      dayPillar: dayPillar,
      hourPillar: hourPillar,
      birthDateTime:
          map['corrected_datetime'] != null
              ? DateTime.parse(map['corrected_datetime'] as String)
              : DateTime.now(),
      correctedDateTime:
          map['corrected_datetime'] != null
              ? DateTime.parse(map['corrected_datetime'] as String)
              : DateTime.now(),
      birthCity: '', // profile에서 별도로 가져와야 함
      isLunarCalendar: false,
    );

    // JSONB 필드 파싱
    final ohengDistribution = _ohengFromJson(
      map['oheng_distribution'] as Map<String, dynamic>,
    );
    final dayStrength =
        map['day_strength'] != null
            ? _dayStrengthFromJson(map['day_strength'] as Map<String, dynamic>)
            : _defaultDayStrength();
    final yongsin =
        map['yongsin'] != null
            ? _yongsinFromJson(map['yongsin'] as Map<String, dynamic>)
            : _defaultYongsin();
    final gyeokguk =
        map['gyeokguk'] != null
            ? _gyeokgukFromJson(map['gyeokguk'] as Map<String, dynamic>)
            : _defaultGyeokguk();
    final sipsinInfo =
        map['sipsin_info'] != null
            ? _sipsinInfoFromJson(map['sipsin_info'] as Map<String, dynamic>)
            : _defaultSipsinInfo();
    final jijangganInfo =
        map['jijanggan_info'] != null
            ? _jijangganInfoFromJson(
              map['jijanggan_info'] as Map<String, dynamic>,
            )
            : _defaultJijangganInfo();
    final sinsalList =
        map['sinsal_list'] != null
            ? _sinsalListFromJson(map['sinsal_list'] as List<dynamic>)
            : <SinSalResult>[];
    final daeun =
        map['daeun'] != null
            ? _daeunFromJson(map['daeun'] as Map<String, dynamic>)
            : null;
    final currentSeun =
        map['current_seun'] != null
            ? _seunFromJson(map['current_seun'] as Map<String, dynamic>)
            : null;

    final analysis = SajuAnalysis(
      chart: chart,
      dayStrength: dayStrength,
      gyeokguk: gyeokguk,
      yongsin: yongsin,
      sinsalList: sinsalList,
      daeun: daeun,
      currentSeun: currentSeun,
      sipsinInfo: sipsinInfo,
      jijangganInfo: jijangganInfo,
      ohengDistribution: ohengDistribution,
    );

    return SajuAnalysisModel(
      id: map['id'] as String?,
      profileId: map['profile_id'] as String,
      analysis: analysis,
    );
  }

  // ========================================
  // Private: toJson 변환 메서드들
  // ========================================

  static Map<String, dynamic> _ohengToJson(OhengDistribution dist) {
    return {
      'mok': dist.mok,
      'hwa': dist.hwa,
      'to': dist.to,
      'geum': dist.geum,
      'su': dist.su,
      'strongest': dist.strongest.name,
      'weakest': dist.weakest.name,
      'missing': dist.missingOheng.map((e) => e.name).toList(),
    };
  }

  static Map<String, dynamic> _dayStrengthToJson(DayStrength ds) {
    return {
      'score': ds.score,
      'level': ds.level.name,
      'monthScore': ds.monthScore,
      'bigeopScore': ds.bigeopScore,
      'inseongScore': ds.inseongScore,
      'exhaustionScore': ds.exhaustionScore,
      'details': {
        'monthStatus': ds.details.monthStatus.name,
        'bigeopCount': ds.details.bigeopCount,
        'inseongCount': ds.details.inseongCount,
        'jaeseongCount': ds.details.jaeseongCount,
        'gwanseongCount': ds.details.gwanseongCount,
        'siksangCount': ds.details.siksangCount,
      },
    };
  }

  static Map<String, dynamic> _yongsinToJson(YongSinResult ys) {
    return {
      'yongsin': ys.yongsin.name,
      'heesin': ys.heesin.name,
      'gisin': ys.gisin.name,
      'gusin': ys.gusin.name,
      'hansin': ys.hansin.name,
      'method': ys.method.name,
      'reason': ys.reason,
    };
  }

  static Map<String, dynamic> _gyeokgukToJson(GyeokGukResult gg) {
    return {
      'name': gg.gyeokguk.name,
      'strength': gg.strength,
      'isSpecial': gg.isSpecial,
      'reason': gg.reason,
    };
  }

  static Map<String, dynamic> _sipsinInfoToJson(SajuSipsinInfo info) {
    return {
      'year': {
        'gan': info.yearGanSipsin.name,
        'ji': info.yearJiSipsin.name,
      },
      'month': {
        'gan': info.monthGanSipsin.name,
        'ji': info.monthJiSipsin.name,
      },
      'day': {'ji': info.dayJiSipsin.name},
      'hour':
          info.hourGanSipsin != null
              ? {
                'gan': info.hourGanSipsin!.name,
                'ji': info.hourJiSipsin?.name,
              }
              : null,
    };
  }

  static Map<String, dynamic> _jijangganInfoToJson(SajuJiJangGanInfo info) {
    return {
      'year': info.yearJi.map((e) => _jijangganItemToJson(e)).toList(),
      'month': info.monthJi.map((e) => _jijangganItemToJson(e)).toList(),
      'day': info.dayJi.map((e) => _jijangganItemToJson(e)).toList(),
      'hour': info.hourJi.map((e) => _jijangganItemToJson(e)).toList(),
    };
  }

  static Map<String, dynamic> _jijangganItemToJson(JiJangGanItem item) {
    return {
      'gan': item.gan,
      'sipsin': item.sipsin.name,
      'strength': item.strength,
      'type': item.type,
    };
  }

  static List<Map<String, dynamic>> _sinsalListToJson(
    List<SinSalResult> list,
  ) {
    return list
        .map(
          (s) => {
            'name': s.sinsal.name,
            'location': s.location,
            'relatedJi': s.relatedJi,
            'description': s.description,
          },
        )
        .toList();
  }

  static Map<String, dynamic> _daeunToJson(DaeUnResult daeun) {
    return {
      'startAge': daeun.startAge,
      'isForward': daeun.isForward,
      'gender': daeun.gender.name,
      'isYearGanYang': daeun.isYearGanYang,
      'list':
          daeun.daeUnList
              .map(
                (d) => {
                  'order': d.order,
                  'startAge': d.startAge,
                  'endAge': d.endAge,
                  'gan': d.pillar.gan,
                  'ji': d.pillar.ji,
                },
              )
              .toList(),
    };
  }

  static Map<String, dynamic> _seunToJson(SeUn seun) {
    return {
      'year': seun.year,
      'age': seun.age,
      'gan': seun.pillar.gan,
      'ji': seun.pillar.ji,
    };
  }

  // ========================================
  // Private: fromJson 변환 메서드들
  // ========================================

  static OhengDistribution _ohengFromJson(Map<String, dynamic> json) {
    return OhengDistribution(
      mok: (json['mok'] as num?)?.toInt() ?? 0,
      hwa: (json['hwa'] as num?)?.toInt() ?? 0,
      to: (json['to'] as num?)?.toInt() ?? 0,
      geum: (json['geum'] as num?)?.toInt() ?? 0,
      su: (json['su'] as num?)?.toInt() ?? 0,
    );
  }

  static DayStrength _dayStrengthFromJson(Map<String, dynamic> json) {
    final detailsJson = json['details'] as Map<String, dynamic>? ?? {};
    return DayStrength(
      score: (json['score'] as num?)?.toInt() ?? 50,
      level: _parseDayStrengthLevel(json['level'] as String?),
      monthScore: (json['monthScore'] as num?)?.toInt() ?? 0,
      bigeopScore: (json['bigeopScore'] as num?)?.toInt() ?? 0,
      inseongScore: (json['inseongScore'] as num?)?.toInt() ?? 0,
      exhaustionScore: (json['exhaustionScore'] as num?)?.toInt() ?? 0,
      details: DayStrengthDetails(
        monthStatus: _parseMonthStatus(detailsJson['monthStatus'] as String?),
        bigeopCount: (detailsJson['bigeopCount'] as num?)?.toInt() ?? 0,
        inseongCount: (detailsJson['inseongCount'] as num?)?.toInt() ?? 0,
        jaeseongCount: (detailsJson['jaeseongCount'] as num?)?.toInt() ?? 0,
        gwanseongCount: (detailsJson['gwanseongCount'] as num?)?.toInt() ?? 0,
        siksangCount: (detailsJson['siksangCount'] as num?)?.toInt() ?? 0,
      ),
    );
  }

  static YongSinResult _yongsinFromJson(Map<String, dynamic> json) {
    return YongSinResult(
      yongsin: _parseOheng(json['yongsin'] as String?),
      heesin: _parseOheng(json['heesin'] as String?),
      gisin: _parseOheng(json['gisin'] as String?),
      gusin: _parseOheng(json['gusin'] as String?),
      hansin: _parseOheng(json['hansin'] as String?),
      method: _parseYongsinMethod(json['method'] as String?),
      reason: json['reason'] as String? ?? '',
    );
  }

  static GyeokGukResult _gyeokgukFromJson(Map<String, dynamic> json) {
    return GyeokGukResult(
      gyeokguk: _parseGyeokguk(json['name'] as String?),
      strength: (json['strength'] as num?)?.toInt() ?? 50,
      isSpecial: json['isSpecial'] as bool? ?? false,
      reason: json['reason'] as String? ?? '',
    );
  }

  static SajuSipsinInfo _sipsinInfoFromJson(Map<String, dynamic> json) {
    final yearJson = json['year'] as Map<String, dynamic>? ?? {};
    final monthJson = json['month'] as Map<String, dynamic>? ?? {};
    final dayJson = json['day'] as Map<String, dynamic>? ?? {};
    final hourJson = json['hour'] as Map<String, dynamic>?;

    return SajuSipsinInfo(
      yearGanSipsin: _parseSipsin(yearJson['gan'] as String?),
      yearJiSipsin: _parseSipsin(yearJson['ji'] as String?),
      monthGanSipsin: _parseSipsin(monthJson['gan'] as String?),
      monthJiSipsin: _parseSipsin(monthJson['ji'] as String?),
      dayJiSipsin: _parseSipsin(dayJson['ji'] as String?),
      hourGanSipsin:
          hourJson != null ? _parseSipsin(hourJson['gan'] as String?) : null,
      hourJiSipsin:
          hourJson != null ? _parseSipsin(hourJson['ji'] as String?) : null,
    );
  }

  static SajuJiJangGanInfo _jijangganInfoFromJson(Map<String, dynamic> json) {
    return SajuJiJangGanInfo(
      yearJi: _parseJijangganList(json['year'] as List<dynamic>?),
      monthJi: _parseJijangganList(json['month'] as List<dynamic>?),
      dayJi: _parseJijangganList(json['day'] as List<dynamic>?),
      hourJi: _parseJijangganList(json['hour'] as List<dynamic>?),
    );
  }

  static List<JiJangGanItem> _parseJijangganList(List<dynamic>? list) {
    if (list == null) return [];
    return list.map((item) {
      final map = item as Map<String, dynamic>;
      return JiJangGanItem(
        gan: map['gan'] as String? ?? '',
        sipsin: _parseSipsin(map['sipsin'] as String?),
        strength: (map['strength'] as num?)?.toInt() ?? 0,
        type: map['type'] as String? ?? '',
      );
    }).toList();
  }

  static List<SinSalResult> _sinsalListFromJson(List<dynamic> list) {
    return list.map((item) {
      final map = item as Map<String, dynamic>;
      return SinSalResult(
        sinsal: _parseSinsal(map['name'] as String?),
        location: map['location'] as String? ?? '',
        relatedJi: map['relatedJi'] as String? ?? '',
        description: map['description'] as String? ?? '',
      );
    }).toList();
  }

  static DaeUnResult _daeunFromJson(Map<String, dynamic> json) {
    final listJson = json['list'] as List<dynamic>? ?? [];
    return DaeUnResult(
      startAge: (json['startAge'] as num?)?.toInt() ?? 0,
      isForward: json['isForward'] as bool? ?? true,
      gender: _parseGender(json['gender'] as String?),
      isYearGanYang: json['isYearGanYang'] as bool? ?? true,
      daeUnList:
          listJson.map((item) {
            final map = item as Map<String, dynamic>;
            return DaeUn(
              order: (map['order'] as num?)?.toInt() ?? 0,
              startAge: (map['startAge'] as num?)?.toInt() ?? 0,
              endAge: (map['endAge'] as num?)?.toInt() ?? 0,
              pillar: Pillar(
                gan: map['gan'] as String? ?? '',
                ji: map['ji'] as String? ?? '',
              ),
            );
          }).toList(),
    );
  }

  static SeUn _seunFromJson(Map<String, dynamic> json) {
    return SeUn(
      year: (json['year'] as num?)?.toInt() ?? DateTime.now().year,
      age: (json['age'] as num?)?.toInt() ?? 0,
      pillar: Pillar(
        gan: json['gan'] as String? ?? '',
        ji: json['ji'] as String? ?? '',
      ),
    );
  }

  // ========================================
  // Private: Enum 파싱 헬퍼
  // ========================================

  static DayStrengthLevel _parseDayStrengthLevel(String? value) {
    if (value == null) return DayStrengthLevel.medium;
    return DayStrengthLevel.values.firstWhere(
      (e) => e.name == value,
      orElse: () => DayStrengthLevel.medium,
    );
  }

  static MonthStatus _parseMonthStatus(String? value) {
    if (value == null) return MonthStatus.neutral;
    return MonthStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => MonthStatus.neutral,
    );
  }

  static Oheng _parseOheng(String? value) {
    if (value == null) return Oheng.mok;
    return Oheng.values.firstWhere(
      (e) => e.name == value,
      orElse: () => Oheng.mok,
    );
  }

  static YongSinMethod _parseYongsinMethod(String? value) {
    if (value == null) return YongSinMethod.eokbu;
    return YongSinMethod.values.firstWhere(
      (e) => e.name == value,
      orElse: () => YongSinMethod.eokbu,
    );
  }

  static GyeokGuk _parseGyeokguk(String? value) {
    if (value == null) return GyeokGuk.junghwaGyeok;
    return GyeokGuk.values.firstWhere(
      (e) => e.name == value,
      orElse: () => GyeokGuk.junghwaGyeok,
    );
  }

  static SipSin _parseSipsin(String? value) {
    if (value == null) return SipSin.bigyeon;
    return SipSin.values.firstWhere(
      (e) => e.name == value,
      orElse: () => SipSin.bigyeon,
    );
  }

  static SinSal _parseSinsal(String? value) {
    if (value == null) return SinSal.cheonEulGwiIn;
    return SinSal.values.firstWhere(
      (e) => e.name == value,
      orElse: () => SinSal.cheonEulGwiIn,
    );
  }

  static Gender _parseGender(String? value) {
    if (value == null) return Gender.male;
    return Gender.values.firstWhere(
      (e) => e.name == value,
      orElse: () => Gender.male,
    );
  }

  // ========================================
  // Private: 기본값 생성 헬퍼
  // ========================================

  static DayStrength _defaultDayStrength() {
    return DayStrength(
      score: 50,
      level: DayStrengthLevel.medium,
      monthScore: 0,
      bigeopScore: 0,
      inseongScore: 0,
      exhaustionScore: 0,
      details: const DayStrengthDetails(
        monthStatus: MonthStatus.neutral,
        bigeopCount: 0,
        inseongCount: 0,
        jaeseongCount: 0,
        gwanseongCount: 0,
        siksangCount: 0,
      ),
    );
  }

  static YongSinResult _defaultYongsin() {
    return const YongSinResult(
      yongsin: Oheng.su,
      heesin: Oheng.geum,
      gisin: Oheng.to,
      gusin: Oheng.hwa,
      hansin: Oheng.mok,
      method: YongSinMethod.eokbu,
      reason: '',
    );
  }

  static GyeokGukResult _defaultGyeokguk() {
    return const GyeokGukResult(
      gyeokguk: GyeokGuk.junghwaGyeok,
      strength: 50,
      isSpecial: false,
      reason: '',
    );
  }

  static SajuSipsinInfo _defaultSipsinInfo() {
    return const SajuSipsinInfo(
      yearGanSipsin: SipSin.bigyeon,
      yearJiSipsin: SipSin.bigyeon,
      monthGanSipsin: SipSin.bigyeon,
      monthJiSipsin: SipSin.bigyeon,
      dayJiSipsin: SipSin.bigyeon,
    );
  }

  static SajuJiJangGanInfo _defaultJijangganInfo() {
    return const SajuJiJangGanInfo(
      yearJi: [],
      monthJi: [],
      dayJi: [],
      hourJi: [],
    );
  }
}
