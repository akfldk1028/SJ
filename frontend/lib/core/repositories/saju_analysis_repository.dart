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
import '../../features/saju_chart/domain/services/gilseong_service.dart';
import '../../features/saju_chart/domain/services/hapchung_service.dart';

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
    if (_client == null) {
      print('[SajuAnalysisRepo] ❌ getByProfileId($profileId): _client is null');
      return null;
    }

    try {
      final response = await _client
          .from(_tableName)
          .select()
          .eq('profile_id', profileId)
          .maybeSingle();

      if (response == null) {
        print('[SajuAnalysisRepo] ⚠️ getByProfileId($profileId): 데이터 없음 (null)');
        return null;
      }

      print('[SajuAnalysisRepo] ✅ getByProfileId($profileId): 데이터 발견');
      print('   year_gan=${response['year_gan']}, year_ji=${response['year_ji']}');
      print('   month_gan=${response['month_gan']}, month_ji=${response['month_ji']}');
      print('   day_gan=${response['day_gan']}, day_ji=${response['day_ji']}');
      print('   hour_gan=${response['hour_gan']}, hour_ji=${response['hour_ji']}');

      final result = _fromSupabaseMap(response);
      print('   파싱 완료: ${result.chart.yearPillar.gan}${result.chart.yearPillar.ji} ${result.chart.monthPillar.gan}${result.chart.monthPillar.ji} ${result.chart.dayPillar.gan}${result.chart.dayPillar.ji} ${result.chart.hourPillar?.gan ?? '?'}${result.chart.hourPillar?.ji ?? '?'}');
      return result;
    } catch (e, st) {
      print('[SajuAnalysisRepo] ❌ getByProfileId($profileId) 오류: $e');
      print('   스택: ${st.toString().split('\n').take(3).join('\n   ')}');
      return null;
    }
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

      // 길성(吉星) 분석 결과 - Phase 16-C 추가
      'gilseong': _gilseongToJson(analysis.chart),

      // 합충형파해(合沖刑破害) 분석 결과
      'hapchung': _hapchungToJson(analysis.chart),

      // AI 요약은 별도로 업데이트
      // 'ai_summary': null,
    };
  }

  Map<String, dynamic> _ohengToJson(OhengDistribution dist) {
    // 오행 분포를 한글(한자) 형식으로 저장
    String formatOheng(Oheng o) => '${o.korean}(${o.hanja})';

    return {
      // 개수는 숫자로 저장
      '목(木)': dist.mok,
      '화(火)': dist.hwa,
      '토(土)': dist.to,
      '금(金)': dist.geum,
      '수(水)': dist.su,
      // 최강/최약/결핍은 한글(한자) 형식
      'strongest': formatOheng(dist.strongest),
      'weakest': formatOheng(dist.weakest),
      'missing': dist.missingOheng.map((e) => formatOheng(e)).toList(),
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
      // 오행을 한글(한자) 형식으로 저장
      'yongsin': '${yongsin.yongsin.korean}(${yongsin.yongsin.hanja})',
      'heesin': '${yongsin.heesin.korean}(${yongsin.heesin.hanja})',
      'gisin': '${yongsin.gisin.korean}(${yongsin.gisin.hanja})',
      'gusin': '${yongsin.gusin.korean}(${yongsin.gusin.hanja})',
      'hansin': '${yongsin.hansin.korean}(${yongsin.hansin.hanja})',
      // 용신 선정 방식도 한글(한자) 형식
      'method': '${yongsin.method.korean}(${yongsin.method.hanja})',
      'reason': yongsin.reason,
    };
  }

  Map<String, dynamic> _gyeokgukToJson(GyeokGukResult gyeokguk) {
    return {
      // 격국을 한글(한자) 형식으로 저장
      'gyeokguk': '${gyeokguk.gyeokguk.korean}(${gyeokguk.gyeokguk.hanja})',
      'name': gyeokguk.gyeokguk.name, // enum 이름 (역변환용)
      'strength': gyeokguk.strength,
      'isSpecial': gyeokguk.isSpecial,
      'reason': gyeokguk.reason,
    };
  }

  Map<String, dynamic> _sipsinInfoToJson(SajuSipsinInfo info) {
    // 십신을 한글(한자) 형식으로 저장
    String formatSipsin(SipSin sipsin) => '${sipsin.korean}(${sipsin.hanja})';

    return {
      'year': {
        'gan': formatSipsin(info.yearGanSipsin),
        'ji': formatSipsin(info.yearJiSipsin),
      },
      'month': {
        'gan': formatSipsin(info.monthGanSipsin),
        'ji': formatSipsin(info.monthJiSipsin),
      },
      'day': {
        'gan': '비견(比肩)',  // 일간 자신은 비견
        'ji': formatSipsin(info.dayJiSipsin),
      },
      'hour': info.hourGanSipsin != null
          ? {
              'gan': formatSipsin(info.hourGanSipsin!),
              'ji': info.hourJiSipsin != null ? formatSipsin(info.hourJiSipsin!) : null,
            }
          : null,
    };
  }

  Map<String, dynamic> _jijangganInfoToJson(SajuJiJangGanInfo info) {
    // 지장간을 한글(한자) 형식으로 저장
    List<String> formatJijanggan(List<JiJangGanItem> jijangganList) {
      return jijangganList.map((e) => _formatWithHanja(e.gan, isCheongan: true)).toList();
    }

    return {
      'year': formatJijanggan(info.yearJi),
      'month': formatJijanggan(info.monthJi),
      'day': formatJijanggan(info.dayJi),
      'hour': formatJijanggan(info.hourJi),
    };
  }

  List<Map<String, dynamic>> _sinsalListToJson(List<SinSalResult> sinsals) {
    return sinsals
        .map((s) => {
              // 신살을 한글(한자) 형식으로 저장
              'name': '${s.sinsal.korean}(${s.sinsal.hanja})',
              'location': s.location,
              'relatedJi': _formatWithHanja(s.relatedJi, isCheongan: false),
              'description': s.description,
              'type': s.sinsal.type.name,
            })
        .toList();
  }

  /// 길성(吉星) 분석 결과를 JSON으로 변환
  /// Phase 16-C: 기둥별 특수 신살 저장
  Map<String, dynamic> _gilseongToJson(SajuChart chart) {
    final result = GilseongService.analyzeFromChart(chart);

    // 기둥별 결과를 JSON으로 변환 - 한글(한자) 형식 적용
    Map<String, dynamic> pillarToJson(PillarGilseongResult pillar) {
      return {
        'pillarName': pillar.pillarName,
        'gan': _formatWithHanja(pillar.gan, isCheongan: true),
        'ji': _formatWithHanja(pillar.ji, isCheongan: false),
        'sinsals': pillar.sinsals.map((s) => {
          // 신살을 한글(한자) 형식으로 저장
          'name': '${s.korean}(${s.hanja})',
          'meaning': s.meaning,
          'fortuneType': s.fortuneType.name,
        }).toList(),
      };
    }

    return {
      'year': pillarToJson(result.yearResult),
      'month': pillarToJson(result.monthResult),
      'day': pillarToJson(result.dayResult),
      'hour': result.hourResult != null
          ? pillarToJson(result.hourResult!)
          : null,
      'hasGwiMunGwanSal': result.hasGwiMunGwanSal,
      'totalGoodCount': result.totalGoodCount,
      'totalBadCount': result.totalBadCount,
      'allUniqueSinsals': result.allUniqueSinsals.map((s) => {
        // 한글(한자) 형식으로 통일
        'name': '${s.korean}(${s.hanja})',
        'fortuneType': s.fortuneType.name,
      }).toList(),
      'summary': result.summary,
    };
  }

  /// 합충형파해(合沖刑破害) 분석 결과를 JSON으로 변환
  /// 천간합/충, 지지육합/삼합/방합/충/형/파/해/원진 저장
  /// 한글(한자) 형식 적용
  Map<String, dynamic> _hapchungToJson(SajuChart chart) {
    final result = HapchungService.analyzeSaju(
      yearGan: chart.yearPillar.gan,
      monthGan: chart.monthPillar.gan,
      dayGan: chart.dayPillar.gan,
      hourGan: chart.hourPillar?.gan ?? '',
      yearJi: chart.yearPillar.ji,
      monthJi: chart.monthPillar.ji,
      dayJi: chart.dayPillar.ji,
      hourJi: chart.hourPillar?.ji ?? '',
    );

    // 기둥 이름을 한글(한자) 형식으로 변환
    String formatPillarName(String name) {
      const pillarMap = {
        '년주': '년주(年柱)',
        '월주': '월주(月柱)',
        '일주': '일주(日柱)',
        '시주': '시주(時柱)',
      };
      return pillarMap[name] ?? name;
    }

    return {
      // 집계 정보
      'has_relations': result.hasRelations,
      'total_haps': result.totalHaps,
      'total_chungs': result.totalChungs,
      'total_negatives': result.totalNegatives,

      // 천간 관계 - 한글(한자) 형식 적용
      'cheongan_haps': result.cheonganHaps.map((h) => {
            'gan1': _formatWithHanja(h.gan1, isCheongan: true),
            'gan2': _formatWithHanja(h.gan2, isCheongan: true),
            'pillar1': formatPillarName(h.pillar1),
            'pillar2': formatPillarName(h.pillar2),
            'description': h.description,
          }).toList(),
      'cheongan_chungs': result.cheonganChungs.map((c) => {
            'gan1': _formatWithHanja(c.gan1, isCheongan: true),
            'gan2': _formatWithHanja(c.gan2, isCheongan: true),
            'pillar1': formatPillarName(c.pillar1),
            'pillar2': formatPillarName(c.pillar2),
            'description': c.description,
          }).toList(),

      // 지지 관계 - 합 (한글(한자) 형식 적용)
      'jiji_yukhaps': result.jijiYukhaps.map((y) => {
            'ji1': _formatWithHanja(y.ji1, isCheongan: false),
            'ji2': _formatWithHanja(y.ji2, isCheongan: false),
            'pillar1': formatPillarName(y.pillar1),
            'pillar2': formatPillarName(y.pillar2),
            'description': y.description,
          }).toList(),
      'jiji_samhaps': result.jijiSamhaps.map((s) => {
            'jijis': s.jijis.map((j) => _formatWithHanja(j, isCheongan: false)).toList(),
            'pillars': s.pillars.map((p) => formatPillarName(p)).toList(),
            'result_oheng': s.resultOheng,
            'is_full': s.isFullSamhap,
          }).toList(),
      'jiji_banghaps': result.jijiBanghaps.map((b) => {
            'jijis': b.jijis.map((j) => _formatWithHanja(j, isCheongan: false)).toList(),
            'pillars': b.pillars.map((p) => formatPillarName(p)).toList(),
            'season': b.season,
            'direction': b.direction,
          }).toList(),

      // 지지 관계 - 충 (한글(한자) 형식 적용)
      'jiji_chungs': result.jijiChungs.map((c) => {
            'ji1': _formatWithHanja(c.ji1, isCheongan: false),
            'ji2': _formatWithHanja(c.ji2, isCheongan: false),
            'pillar1': formatPillarName(c.pillar1),
            'pillar2': formatPillarName(c.pillar2),
            'description': c.description,
          }).toList(),

      // 지지 관계 - 형/파/해/원진 (한글(한자) 형식 적용)
      'jiji_hyungs': result.jijiHyungs.map((h) => {
            'ji1': _formatWithHanja(h.ji1, isCheongan: false),
            'ji2': _formatWithHanja(h.ji2, isCheongan: false),
            'pillar1': formatPillarName(h.pillar1),
            'pillar2': formatPillarName(h.pillar2),
            'description': h.description,
          }).toList(),
      'jiji_pas': result.jijiPas.map((p) => {
            'ji1': _formatWithHanja(p.ji1, isCheongan: false),
            'ji2': _formatWithHanja(p.ji2, isCheongan: false),
            'pillar1': formatPillarName(p.pillar1),
            'pillar2': formatPillarName(p.pillar2),
          }).toList(),
      'jiji_haes': result.jijiHaes.map((h) => {
            'ji1': _formatWithHanja(h.ji1, isCheongan: false),
            'ji2': _formatWithHanja(h.ji2, isCheongan: false),
            'pillar1': formatPillarName(h.pillar1),
            'pillar2': formatPillarName(h.pillar2),
          }).toList(),
      'wonjins': result.wonjins.map((w) => {
            'ji1': _formatWithHanja(w.ji1, isCheongan: false),
            'ji2': _formatWithHanja(w.ji2, isCheongan: false),
            'pillar1': formatPillarName(w.pillar1),
            'pillar2': formatPillarName(w.pillar2),
          }).toList(),
    };
  }

  Map<String, dynamic> _daeunToJson(DaeUnResult daeun) {
    return {
      'startAge': daeun.startAge,
      'isForward': daeun.isForward,
      'gender': daeun.gender.name,
      'isYearGanYang': daeun.isYearGanYang,
      'list': daeun.daeUnList.map((d) {
        final ganFormatted = _formatWithHanja(d.pillar.gan, isCheongan: true);
        final jiFormatted = _formatWithHanja(d.pillar.ji, isCheongan: false);
        return {
          'startAge': d.startAge,
          'endAge': d.endAge,
          'order': d.order,
          // 대운 간지를 "경(庚)술(戌)" 형식으로 저장
          'pillar': '$ganFormatted$jiFormatted',
          'gan': ganFormatted,
          'ji': jiFormatted,
        };
      }).toList(),
    };
  }

  Map<String, dynamic> _seunToJson(SeUn seun) {
    final ganFormatted = _formatWithHanja(seun.pillar.gan, isCheongan: true);
    final jiFormatted = _formatWithHanja(seun.pillar.ji, isCheongan: false);
    return {
      'year': seun.year,
      'age': seun.age,
      // 세운 간지를 "병(丙)오(午)" 형식으로 저장
      'pillar': '$ganFormatted$jiFormatted',
      'gan': ganFormatted,
      'ji': jiFormatted,
    };
  }

  // ============================================================
  // 변환 함수: Supabase → Flutter
  // ============================================================

  SajuAnalysis _fromSupabaseMap(Map<String, dynamic> map) {
    // SajuChart 구성 - 한글(한자) 형식에서 한글만 추출
    // null 체크 추가: DB 데이터가 불완전할 수 있음
    final yearGan = map['year_gan'] as String? ?? '갑';
    final yearJi = map['year_ji'] as String? ?? '자';
    final monthGan = map['month_gan'] as String? ?? '갑';
    final monthJi = map['month_ji'] as String? ?? '자';
    final dayGan = map['day_gan'] as String? ?? '갑';
    final dayJi = map['day_ji'] as String? ?? '자';
    final hourGan = map['hour_gan'] as String?;
    final hourJi = map['hour_ji'] as String?;
    final correctedDatetime = map['corrected_datetime'] as String?;

    final chart = SajuChart(
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
      hourPillar: hourGan != null && hourJi != null
          ? Pillar(
              gan: _extractHangul(hourGan),
              ji: _extractHangul(hourJi),
            )
          : null,
      birthDateTime: correctedDatetime != null
          ? DateTime.parse(correctedDatetime)
          : DateTime.now(),
      correctedDateTime: correctedDatetime != null
          ? DateTime.parse(correctedDatetime)
          : DateTime.now(),
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
      ohengDistribution: _ohengFromJson(map['oheng_distribution'] as Map<String, dynamic>?),
    );
  }

  OhengDistribution _ohengFromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const OhengDistribution(mok: 0, hwa: 0, to: 0, geum: 0, su: 0);
    }
    // DB에 저장된 키 형식 3가지:
    // 1. 한자 포함: "금(金)", "목(木)", "수(水)", "토(土)", "화(火)"
    // 2. 한글만: "금", "목", "수", "토", "화"
    // 3. 영어: "mok", "hwa", "to", "geum", "su"
    int getOhengValue(String hanjaKey, String koreanKey, String englishKey) {
      return json[hanjaKey] as int? ?? json[koreanKey] as int? ?? json[englishKey] as int? ?? 0;
    }
    return OhengDistribution(
      mok: getOhengValue('목(木)', '목', 'mok'),
      hwa: getOhengValue('화(火)', '화', 'hwa'),
      to: getOhengValue('토(土)', '토', 'to'),
      geum: getOhengValue('금(金)', '금', 'geum'),
      su: getOhengValue('수(水)', '수', 'su'),
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
    final score = (json['score'] as num?)?.toInt() ?? 50;
    return DayStrength(
      score: score,
      level: DayStrengthLevel.fromScore(score),
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
    // DB에 저장된 형식: "정관격(正官格)", "중화격(中和格)" 등 한글(한자) 형식
    // Dart enum 이름: "jeonggwanGyeok", "junghwaGyeok" 등 영어 형식
    final gyeokgukStr = json['gyeokguk'] as String? ??
        json['name'] as String? ??
        'junghwaGyeok';
    final mappedGyeokguk = switch (gyeokgukStr) {
      // 한글(한자) 형식 → enum 이름 변환
      '정관격(正官格)' => 'jeonggwanGyeok',
      '정재격(正財格)' => 'jeongjaeGyeok',
      '식신격(食神格)' => 'siksinGyeok',
      '정인격(正印格)' => 'jeonginGyeok',
      '상관격(傷官格)' => 'sanggwanGyeok',
      '편인격(偏印格)' => 'pyeoninGyeok',
      '편재격(偏財格)' => 'pyeonjaeGyeok',
      '칠살격(七殺格)' => 'chilsalGyeok',
      '비견격(比肩格)' => 'bigyeonGyeok',
      '겁재격(劫財格)' => 'geopjaeGyeok',
      '종왕격(從旺格)' => 'jongwangGyeok',
      '종살격(從殺格)' => 'jongsalGyeok',
      '종재격(從財格)' => 'jongjaeGyeok',
      '중화격(中和格)' => 'junghwaGyeok',
      // 한글만 있는 형식
      '정관격' => 'jeonggwanGyeok',
      '정재격' => 'jeongjaeGyeok',
      '식신격' => 'siksinGyeok',
      '정인격' => 'jeonginGyeok',
      '상관격' => 'sanggwanGyeok',
      '편인격' => 'pyeoninGyeok',
      '편재격' => 'pyeonjaeGyeok',
      '칠살격' => 'chilsalGyeok',
      '비견격' => 'bigyeonGyeok',
      '겁재격' => 'geopjaeGyeok',
      '종왕격' => 'jongwangGyeok',
      '종살격' => 'jongsalGyeok',
      '종재격' => 'jongjaeGyeok',
      '중화격' => 'junghwaGyeok',
      _ => gyeokgukStr,
    };
    return GyeokGukResult(
      gyeokguk: GyeokGuk.values.byName(mappedGyeokguk),
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
    // DB에 저장된 형식: "억부법(抑扶法)", "조후법(調候法)" 등 한글(한자) 형식
    // Dart enum 이름: "eokbu", "johu" 등 영어 형식
    final methodStr = json['method'] as String? ?? 'eokbu';
    final mappedMethod = switch (methodStr) {
      // 한글(한자) 형식 → enum 이름 변환
      '억부법(抑扶法)' => 'eokbu',
      '조후법(調候法)' => 'johu',
      '통관법(通關法)' => 'tonggwan',
      '병약법(病藥法)' => 'byeongYak',
      // 한글만 있는 형식
      '억부법' => 'eokbu',
      '조후법' => 'johu',
      '통관법' => 'tonggwan',
      '병약법' => 'byeongYak',
      _ => methodStr,
    };
    return YongSinResult(
      yongsin: _ohengFromKorean(json['yongsin'] as String? ?? '목'),
      heesin: _ohengFromKorean(json['heesin'] as String? ?? '수'),
      gisin: _ohengFromKorean(json['gisin'] as String? ?? '금'),
      gusin: _ohengFromKorean(json['gusin'] as String? ?? '토'),
      hansin: _ohengFromKorean(json['hansin'] as String? ?? '화'),
      reason: json['reason'] as String? ?? '',
      method: YongSinMethod.values.byName(mappedMethod),
    );
  }

  Oheng _ohengFromKorean(String korean) {
    // DB에 저장된 형식: "목(木)", "화(火)" 등 한글(한자) 형식도 지원
    switch (korean) {
      // 한글만
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
      // 한글(한자) 형식
      case '목(木)':
        return Oheng.mok;
      case '화(火)':
        return Oheng.hwa;
      case '토(土)':
        return Oheng.to;
      case '금(金)':
        return Oheng.geum;
      case '수(水)':
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
      // DB에 저장된 형식: "경(庚)술(戌)" 문자열 또는 gan/ji 개별 필드
      final pillarStr = dMap['pillar'] as String?;
      String gan = dMap['gan'] as String? ?? '갑';
      String ji = dMap['ji'] as String? ?? '자';

      // pillar 문자열에서 간지 추출: "경(庚)술(戌)" → 간="경", 지="술"
      if (pillarStr != null && gan == '갑' && ji == '자') {
        final parsed = _parsePillarString(pillarStr);
        gan = parsed.$1;
        ji = parsed.$2;
      }

      return DaeUn(
        startAge: dMap['startAge'] as int? ?? 0,
        endAge: dMap['endAge'] as int? ?? 0,
        order: dMap['order'] as int? ?? 0,
        pillar: Pillar(
          gan: gan,
          ji: ji,
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

    // DB에 저장된 형식: "병(丙)오(午)" 문자열 또는 gan/ji 개별 필드
    final pillarStr = json['pillar'] as String?;
    String gan = json['gan'] as String? ?? '갑';
    String ji = json['ji'] as String? ?? '자';

    // pillar 문자열에서 간지 추출
    if (pillarStr != null && gan == '갑' && ji == '자') {
      final parsed = _parsePillarString(pillarStr);
      gan = parsed.$1;
      ji = parsed.$2;
    }

    return SeUn(
      year: json['year'] as int? ?? DateTime.now().year,
      age: json['age'] as int? ?? 0,
      pillar: Pillar(
        gan: gan,
        ji: ji,
      ),
    );
  }

  /// pillar 문자열 파싱: "경(庚)술(戌)" → ("경", "술")
  (String, String) _parsePillarString(String pillarStr) {
    // 형식: "X(Y)Z(W)" 에서 X와 Z 추출
    // 예: "경(庚)술(戌)" → ("경", "술")
    final regex = RegExp(r'([가-힣])\([^)]+\)([가-힣])\([^)]+\)');
    final match = regex.firstMatch(pillarStr);
    if (match != null) {
      return (match.group(1)!, match.group(2)!);
    }
    // 한자 없는 간단한 형식: "경술" → ("경", "술")
    if (pillarStr.length >= 2) {
      return (pillarStr[0], pillarStr[1]);
    }
    return ('갑', '자');
  }

  SajuSipsinInfo _sipsinInfoFromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return SajuSipsinInfo(
        yearGanSipsin: SipSin.bigyeon,
        monthGanSipsin: SipSin.bigyeon,
        yearJiSipsin: SipSin.bigyeon,
        monthJiSipsin: SipSin.bigyeon,
        dayJiSipsin: SipSin.bigyeon,
      );
    }

    // DB 포맷 2가지 지원:
    // 포맷1 (flat): {"yearGan":"정인(正印)", "monthGan":"겁재(劫財)", "yearJi":"정재(正財)", ...}
    // 포맷2 (nested): {"year":{"gan":"식신(食神)","ji":"편재(偏財)"}, "month":{...}, ...}
    final isNested = json.containsKey('year') && json['year'] is Map;

    String? getVal(String flatKey, String pillar, String ganJi) {
      if (isNested) {
        final p = json[pillar] as Map<String, dynamic>?;
        return p?[ganJi] as String?;
      }
      return json[flatKey] as String?;
    }

    return SajuSipsinInfo(
      yearGanSipsin: _parseSipsin(getVal('yearGan', 'year', 'gan')),
      monthGanSipsin: _parseSipsin(getVal('monthGan', 'month', 'gan')),
      yearJiSipsin: _parseSipsin(getVal('yearJi', 'year', 'ji')),
      monthJiSipsin: _parseSipsin(getVal('monthJi', 'month', 'ji')),
      dayJiSipsin: _parseSipsin(getVal('dayJi', 'day', 'ji')),
      hourGanSipsin: _parseSipsinNullable(getVal('hourGan', 'hour', 'gan')),
      hourJiSipsin: _parseSipsinNullable(getVal('hourJi', 'hour', 'ji')),
    );
  }

  /// 십성 문자열 파싱: "정인(正印)" → SipSin.jeongin
  SipSin _parseSipsin(String? value) {
    if (value == null || value.isEmpty) return SipSin.bigyeon;
    // "정인(正印)" → "정인" 추출
    final korean = value.contains('(') ? value.split('(').first : value;
    for (final s in SipSin.values) {
      if (s.korean == korean) return s;
    }
    return SipSin.bigyeon;
  }

  /// nullable 십성 파싱
  SipSin? _parseSipsinNullable(String? value) {
    if (value == null || value.isEmpty) return null;
    return _parseSipsin(value);
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
  /// Phase 61: "(寅)" 처럼 한글 없는 경우도 처리
  String _extractHangul(String formatted) {
    if (formatted.isEmpty) return formatted;

    if (formatted.contains('(')) {
      final idx = formatted.indexOf('(');
      if (idx > 0) {
        // 정상: "갑(甲)" → "갑"
        return formatted.substring(0, idx);
      } else {
        // 비정상: "(甲)" → 한자에서 한글 역변환
        final hanjaMatch = RegExp(r'\(([^)]+)\)').firstMatch(formatted);
        if (hanjaMatch != null) {
          final hanja = hanjaMatch.group(1)!;
          // 천간 한자 → 한글
          final cheonganEntry = cheonganHanja.entries
              .where((e) => e.value == hanja)
              .firstOrNull;
          if (cheonganEntry != null) return cheonganEntry.key;
          // 지지 한자 → 한글
          final jijiEntry = jijiHanja.entries
              .where((e) => e.value == hanja)
              .firstOrNull;
          if (jijiEntry != null) return jijiEntry.key;
        }
        return formatted; // 변환 실패시 원본 반환
      }
    }
    return formatted;
  }
}
