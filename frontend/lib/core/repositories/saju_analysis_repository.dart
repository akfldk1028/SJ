import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import '../../features/saju_chart/domain/entities/saju_chart.dart';
import '../../features/saju_chart/domain/entities/saju_analysis.dart';
import '../../features/saju_chart/domain/entities/pillar.dart';
import '../../features/saju_chart/domain/entities/day_strength.dart';
import '../../features/saju_chart/domain/entities/gyeokguk.dart';
import '../../features/saju_chart/domain/entities/yongsin.dart';
import '../../features/saju_chart/domain/entities/sinsal.dart';
import '../../features/saju_chart/domain/entities/daeun.dart';
import '../../features/saju_chart/data/constants/sipsin_relations.dart';
import '../../features/saju_chart/data/constants/cheongan_jiji.dart';

/// Supabase saju_analyses 테이블 Repository
/// 복잡한 JSONB 필드 매핑 처리
class SajuAnalysisRepository {
  final SupabaseClient? _client;

  SajuAnalysisRepository() : _client = SupabaseService.client;

  /// Supabase 연결 여부
  bool get isConnected => _client != null;

  static const String _tableName = 'saju_analyses';

  // ============================================================
  // CREATE / UPDATE (UPSERT)
  // ============================================================

  /// 분석 결과 저장 (없으면 생성, 있으면 업데이트)
  Future<void> upsert(String profileId, SajuAnalysis analysis) async {
    if (_client == null) return;

    final data = _toSupabaseMap(profileId, analysis);

    await _client.from(_tableName).upsert(data, onConflict: 'profile_id');
  }

  // ============================================================
  // READ
  // ============================================================

  /// 프로필 ID로 분석 결과 조회
  Future<SajuAnalysis?> getByProfileId(String profileId) async {
    if (_client == null) return null;

    final response = await _client
        .from(_tableName)
        .select()
        .eq('profile_id', profileId)
        .maybeSingle();

    if (response == null) return null;
    return _fromSupabaseMap(response);
  }

  /// 분석 존재 여부 확인
  Future<bool> exists(String profileId) async {
    if (_client == null) return false;

    final response = await _client
        .from(_tableName)
        .select('id')
        .eq('profile_id', profileId)
        .maybeSingle();

    return response != null;
  }

  // ============================================================
  // DELETE
  // ============================================================

  /// 분석 결과 삭제
  Future<void> delete(String profileId) async {
    if (_client == null) return;
    await _client.from(_tableName).delete().eq('profile_id', profileId);
  }

  // ============================================================
  // 변환 함수: Flutter → Supabase
  // ============================================================

  Map<String, dynamic> _toSupabaseMap(String profileId, SajuAnalysis analysis) {
    final chart = analysis.chart;

    return {
      'profile_id': profileId,

      // 4주 (만세력 기본) - 한글(한자) 형식으로 저장
      'year_gan': _formatWithHanja(chart.yearPillar.gan, isCheongan: true),
      'year_ji': _formatWithHanja(chart.yearPillar.ji, isCheongan: false),
      'month_gan': _formatWithHanja(chart.monthPillar.gan, isCheongan: true),
      'month_ji': _formatWithHanja(chart.monthPillar.ji, isCheongan: false),
      'day_gan': _formatWithHanja(chart.dayPillar.gan, isCheongan: true),
      'day_ji': _formatWithHanja(chart.dayPillar.ji, isCheongan: false),
      'hour_gan': chart.hourPillar?.gan != null
          ? _formatWithHanja(chart.hourPillar!.gan, isCheongan: true)
          : null,
      'hour_ji': chart.hourPillar?.ji != null
          ? _formatWithHanja(chart.hourPillar!.ji, isCheongan: false)
          : null,

      // 보정된 출생시간
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
          analysis.currentSeun != null ? _seunToJson(analysis.currentSeun!) : null,

      // AI 요약은 별도로 업데이트
      // 'ai_summary': null,
    };
  }

  Map<String, dynamic> _ohengToJson(OhengDistribution dist) {
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

  Map<String, dynamic> _dayStrengthToJson(DayStrength strength) {
    return {
      'level': strength.level.name,
      'score': strength.score,
      'monthScore': strength.monthScore,
      'bigeopScore': strength.bigeopScore,
      'inseongScore': strength.inseongScore,
      'exhaustionScore': strength.exhaustionScore,
      'isStrong': strength.isStrong,
      'isWeak': strength.isWeak,
    };
  }

  Map<String, dynamic> _yongsinToJson(YongSinResult yongsin) {
    return {
      'yongsin': yongsin.yongsin.korean,
      'heesin': yongsin.heesin.korean,
      'gisin': yongsin.gisin.korean,
      'gusin': yongsin.gusin.korean,
      'hansin': yongsin.hansin.korean,
      'method': yongsin.method.name,
      'reason': yongsin.reason,
    };
  }

  Map<String, dynamic> _gyeokgukToJson(GyeokGukResult gyeokguk) {
    return {
      'gyeokguk': gyeokguk.gyeokguk.name,
      'korean': gyeokguk.gyeokguk.korean,
      'hanja': gyeokguk.gyeokguk.hanja,
      'strength': gyeokguk.strength,
      'isSpecial': gyeokguk.isSpecial,
      'reason': gyeokguk.reason,
    };
  }

  Map<String, dynamic> _sipsinInfoToJson(SajuSipsinInfo info) {
    return {
      'year': {
        'gan': info.yearGanSipsin.korean,
        'ji': info.yearJiSipsin.korean,
      },
      'month': {
        'gan': info.monthGanSipsin.korean,
        'ji': info.monthJiSipsin.korean,
      },
      'day': {
        'gan': '비견',  // 일간 자신은 비견
        'ji': info.dayJiSipsin.korean,
      },
      'hour': info.hourGanSipsin != null
          ? {
              'gan': info.hourGanSipsin!.korean,
              'ji': info.hourJiSipsin?.korean,
            }
          : null,
    };
  }

  Map<String, dynamic> _jijangganInfoToJson(SajuJiJangGanInfo info) {
    return {
      'year': info.yearJi.map((e) => e.gan).toList(),
      'month': info.monthJi.map((e) => e.gan).toList(),
      'day': info.dayJi.map((e) => e.gan).toList(),
      'hour': info.hourJi.map((e) => e.gan).toList(),
    };
  }

  List<Map<String, dynamic>> _sinsalListToJson(List<SinSalResult> sinsals) {
    return sinsals
        .map((s) => {
              'name': s.sinsal.korean,
              'hanja': s.sinsal.hanja,
              'location': s.location,
              'relatedJi': s.relatedJi,
              'description': s.description,
              'type': s.sinsal.type.name,
            })
        .toList();
  }

  Map<String, dynamic> _daeunToJson(DaeUnResult daeun) {
    return {
      'startAge': daeun.startAge,
      'isForward': daeun.isForward,
      'gender': daeun.gender.name,
      'isYearGanYang': daeun.isYearGanYang,
      'list': daeun.daeUnList
          .map((d) => {
                'startAge': d.startAge,
                'endAge': d.endAge,
                'order': d.order,
                'gan': d.pillar.gan,
                'ji': d.pillar.ji,
              })
          .toList(),
    };
  }

  Map<String, dynamic> _seunToJson(SeUn seun) {
    return {
      'year': seun.year,
      'age': seun.age,
      'gan': seun.pillar.gan,
      'ji': seun.pillar.ji,
    };
  }

  // ============================================================
  // 변환 함수: Supabase → Flutter
  // ============================================================

  SajuAnalysis _fromSupabaseMap(Map<String, dynamic> map) {
    // SajuChart 구성 - 한글(한자) 형식에서 한글만 추출
    final chart = SajuChart(
      yearPillar: Pillar(
        gan: _extractHangul(map['year_gan'] as String),
        ji: _extractHangul(map['year_ji'] as String),
      ),
      monthPillar: Pillar(
        gan: _extractHangul(map['month_gan'] as String),
        ji: _extractHangul(map['month_ji'] as String),
      ),
      dayPillar: Pillar(
        gan: _extractHangul(map['day_gan'] as String),
        ji: _extractHangul(map['day_ji'] as String),
      ),
      hourPillar: map['hour_gan'] != null
          ? Pillar(
              gan: _extractHangul(map['hour_gan'] as String),
              ji: _extractHangul(map['hour_ji'] as String),
            )
          : null,
      birthDateTime: DateTime.parse(map['corrected_datetime'] as String),
      correctedDateTime: DateTime.parse(map['corrected_datetime'] as String),
      birthCity: '', // DB에 저장 안 됨, profile에서 가져와야 함
      isLunarCalendar: false, // DB에 저장 안 됨
    );

    return SajuAnalysis(
      chart: chart,
      dayStrength: _dayStrengthFromJson(map['day_strength'] as Map<String, dynamic>?),
      gyeokguk: _gyeokgukFromJson(map['gyeokguk'] as Map<String, dynamic>?),
      yongsin: _yongsinFromJson(map['yongsin'] as Map<String, dynamic>?),
      sinsalList: _sinsalListFromJson(map['sinsal_list'] as List?),
      daeun: _daeunFromJson(map['daeun'] as Map<String, dynamic>?),
      currentSeun: _seunFromJson(map['current_seun'] as Map<String, dynamic>?),
      sipsinInfo: _sipsinInfoFromJson(map['sipsin_info'] as Map<String, dynamic>?),
      jijangganInfo: _jijangganInfoFromJson(map['jijanggan_info'] as Map<String, dynamic>?),
      ohengDistribution: _ohengFromJson(map['oheng_distribution'] as Map<String, dynamic>),
    );
  }

  OhengDistribution _ohengFromJson(Map<String, dynamic> json) {
    return OhengDistribution(
      mok: json['mok'] as int? ?? 0,
      hwa: json['hwa'] as int? ?? 0,
      to: json['to'] as int? ?? 0,
      geum: json['geum'] as int? ?? 0,
      su: json['su'] as int? ?? 0,
    );
  }

  DayStrength _dayStrengthFromJson(Map<String, dynamic>? json) {
    // DayStrength는 복잡한 구조라서 Flutter에서 다시 계산하는 것이 안전
    // DB에서는 참고용으로만 저장하고, 실제 앱에서는 재계산
    final defaultDetails = DayStrengthDetails(
      monthStatus: MonthStatus.neutral,
      bigeopCount: 0,
      inseongCount: 0,
      jaeseongCount: 0,
      gwanseongCount: 0,
      siksangCount: 0,
    );

    if (json == null) {
      return DayStrength(
        score: 50,
        level: DayStrengthLevel.junghwaSingang,
        monthScore: 0,
        bigeopScore: 0,
        inseongScore: 0,
        exhaustionScore: 0,
        details: defaultDetails,
      );
    }
    // 이전 enum 값 매핑 (하위 호환성)
    final levelStr = json['level'] as String? ?? 'junghwaSingang';
    final mappedLevel = switch (levelStr) {
      'medium' => 'junghwaSingang',
      'veryStrong' => 'geukwang',
      'strong' => 'singang',
      'weak' => 'sinyak',
      'veryWeak' => 'geukyak',
      _ => levelStr,
    };
    return DayStrength(
      score: json['score'] as int? ?? 50,
      level: DayStrengthLevel.values.byName(mappedLevel),
      monthScore: json['monthScore'] as int? ?? 0,
      bigeopScore: json['bigeopScore'] as int? ?? 0,
      inseongScore: json['inseongScore'] as int? ?? 0,
      exhaustionScore: json['exhaustionScore'] as int? ?? 0,
      details: defaultDetails,
    );
  }

  GyeokGukResult _gyeokgukFromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const GyeokGukResult(
        gyeokguk: GyeokGuk.junghwaGyeok,
        strength: 50,
        isSpecial: false,
        reason: '',
      );
    }
    return GyeokGukResult(
      gyeokguk: GyeokGuk.values.byName(json['gyeokguk'] as String? ?? 'junghwaGyeok'),
      strength: json['strength'] as int? ?? 50,
      isSpecial: json['isSpecial'] as bool? ?? false,
      reason: json['reason'] as String? ?? '',
    );
  }

  YongSinResult _yongsinFromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return YongSinResult(
        yongsin: Oheng.mok,
        heesin: Oheng.su,
        gisin: Oheng.geum,
        gusin: Oheng.to,
        hansin: Oheng.hwa,
        reason: '',
        method: YongSinMethod.eokbu,
      );
    }
    return YongSinResult(
      yongsin: _ohengFromKorean(json['yongsin'] as String? ?? '목'),
      heesin: _ohengFromKorean(json['heesin'] as String? ?? '수'),
      gisin: _ohengFromKorean(json['gisin'] as String? ?? '금'),
      gusin: _ohengFromKorean(json['gusin'] as String? ?? '토'),
      hansin: _ohengFromKorean(json['hansin'] as String? ?? '화'),
      reason: json['reason'] as String? ?? '',
      method: YongSinMethod.values.byName(json['method'] as String? ?? 'eokbu'),
    );
  }

  Oheng _ohengFromKorean(String korean) {
    switch (korean) {
      case '목':
        return Oheng.mok;
      case '화':
        return Oheng.hwa;
      case '토':
        return Oheng.to;
      case '금':
        return Oheng.geum;
      case '수':
        return Oheng.su;
      default:
        return Oheng.mok;
    }
  }

  List<SinSalResult> _sinsalListFromJson(List? json) {
    if (json == null || json.isEmpty) return [];
    // SinSalResult 구조가 복잡해서 빈 리스트 반환
    // 실제 앱에서는 Flutter에서 계산해서 사용
    return [];
  }

  DaeUnResult? _daeunFromJson(Map<String, dynamic>? json) {
    if (json == null) return null;

    final list = (json['list'] as List?)?.map((d) {
      final dMap = d as Map<String, dynamic>;
      return DaeUn(
        startAge: dMap['startAge'] as int,
        endAge: dMap['endAge'] as int,
        order: dMap['order'] as int,
        pillar: Pillar(
          gan: dMap['gan'] as String,
          ji: dMap['ji'] as String,
        ),
      );
    }).toList();

    // gender 문자열을 Gender enum으로 변환
    Gender gender = Gender.male;
    final genderStr = json['gender'] as String?;
    if (genderStr == 'female') {
      gender = Gender.female;
    }

    return DaeUnResult(
      startAge: json['startAge'] as int? ?? 0,
      isForward: json['isForward'] as bool? ?? true,
      daeUnList: list ?? [],
      gender: gender,
      isYearGanYang: json['isYearGanYang'] as bool? ?? true,
    );
  }

  SeUn? _seunFromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    return SeUn(
      year: json['year'] as int,
      age: json['age'] as int,
      pillar: Pillar(
        gan: json['gan'] as String,
        ji: json['ji'] as String,
      ),
    );
  }

  SajuSipsinInfo _sipsinInfoFromJson(Map<String, dynamic>? json) {
    // 십신 정보는 Flutter에서 다시 계산하는 것이 안전
    // DB에서는 참고용으로만 저장
    return SajuSipsinInfo(
      yearGanSipsin: SipSin.bigyeon,
      monthGanSipsin: SipSin.bigyeon,
      yearJiSipsin: SipSin.bigyeon,
      monthJiSipsin: SipSin.bigyeon,
      dayJiSipsin: SipSin.bigyeon,
    );
  }

  SajuJiJangGanInfo _jijangganInfoFromJson(Map<String, dynamic>? json) {
    // 지장간 정보도 Flutter에서 다시 계산
    return const SajuJiJangGanInfo(
      yearJi: [],
      monthJi: [],
      dayJi: [],
      hourJi: [],
    );
  }

  // ============================================================
  // AI 요약 업데이트 (별도 메서드)
  // ============================================================

  /// AI 요약 저장
  Future<void> updateAiSummary(String profileId, Map<String, dynamic> summary) async {
    if (_client == null) return;
    await _client
        .from(_tableName)
        .update({'ai_summary': summary})
        .eq('profile_id', profileId);
  }

  /// AI 요약 조회
  Future<Map<String, dynamic>?> getAiSummary(String profileId) async {
    if (_client == null) return null;
    final response = await _client
        .from(_tableName)
        .select('ai_summary')
        .eq('profile_id', profileId)
        .maybeSingle();

    if (response == null) return null;
    return response['ai_summary'] as Map<String, dynamic>?;
  }

  // ============================================================
  // 헬퍼 함수: 한글(한자) 형식 변환
  // ============================================================

  /// 한글을 한글(한자) 형식으로 변환
  /// 예: "갑" → "갑(甲)", "자" → "자(子)"
  /// 이미 한자가 포함되어 있으면 그대로 반환
  String _formatWithHanja(String hangul, {required bool isCheongan}) {
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
  String _extractHangul(String formatted) {
    if (formatted.contains('(')) {
      return formatted.substring(0, formatted.indexOf('('));
    }
    return formatted;
  }
}
