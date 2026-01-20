/// # 사주 분석 공통 쿼리
///
/// ## 개요
/// saju_analyses 테이블 조회 + 프롬프트용 파싱
/// 합충형파해, 신살, 십신 등을 GPT가 바로 사용할 수 있는 형태로 변환
///
/// ## 파일 위치
/// `frontend/lib/AI/fortune/common/saju_analyses_queries.dart`

import 'package:supabase_flutter/supabase_flutter.dart';

/// 사주 분석 쿼리 클래스
class SajuAnalysesQueries {
  final SupabaseClient _supabase;

  SajuAnalysesQueries(this._supabase);

  /// 운세 분석용 데이터 조회 (파싱된 형태)
  ///
  /// [profileId] 프로필 UUID
  /// 반환: FortuneInputData.sajuAnalyses에 전달할 파싱된 Map
  Future<Map<String, dynamic>?> getForFortuneInput(String profileId) async {
    try {
      final response = await _supabase
          .from('saju_analyses')
          .select('''
            year_gan, year_ji, month_gan, month_ji,
            day_gan, day_ji, hour_gan, hour_ji,
            yongsin, hapchung, day_strength,
            sinsal_list, twelve_sinsal, sipsin_info
          ''')
          .eq('profile_id', profileId)
          .limit(1)
          .maybeSingle();

      if (response == null) {
        print('[SajuAnalysesQueries] ⚠️ 데이터 없음: profileId=$profileId');
        return null;
      }

      print('[SajuAnalysesQueries] ✅ 조회 성공: day_gan=${response['day_gan']}');

      // 파싱된 결과 반환
      return _parseForPrompt(response);
    } catch (e) {
      print('[SajuAnalysesQueries] ❌ 조회 실패: $e');
      return null;
    }
  }

  /// 프롬프트용으로 파싱
  Map<String, dynamic> _parseForPrompt(Map<String, dynamic> raw) {
    return {
      // 사주 팔자 (그대로)
      'year_gan': raw['year_gan'],
      'year_ji': raw['year_ji'],
      'month_gan': raw['month_gan'],
      'month_ji': raw['month_ji'],
      'day_gan': raw['day_gan'],
      'day_ji': raw['day_ji'],
      'hour_gan': raw['hour_gan'],
      'hour_ji': raw['hour_ji'],

      // 용신 (그대로)
      'yongsin': raw['yongsin'],

      // 일간 강약 (그대로)
      'day_strength': raw['day_strength'],

      // 합충형파해 (파싱!)
      'hapchung': _parseHapchung(raw['hapchung']),

      // 신살 (파싱!)
      'sinsal': _parseSinsal(raw['sinsal_list'], raw['twelve_sinsal']),

      // 십신 (그대로)
      'sipsin_info': raw['sipsin_info'],
    };
  }

  /// 합충형파해 파싱 → 프롬프트용 간결한 형태
  Map<String, dynamic>? _parseHapchung(Map<String, dynamic>? hapchung) {
    if (hapchung == null) return null;

    final result = <String, dynamic>{};

    // 천간 합
    final cheonganHaps = _extractDescriptions(hapchung['cheongan_haps']);
    // 천간 충
    final cheonganChungs = _extractDescriptions(hapchung['cheongan_chungs']);

    if (cheonganHaps.isNotEmpty || cheonganChungs.isNotEmpty) {
      final combined = [...cheonganHaps, ...cheonganChungs];
      result['cheongan_hapchung'] = combined.join(', ');
    }

    // 지지 합 (육합, 삼합, 방합, 반합)
    final jijiHaps = <String>[];
    jijiHaps.addAll(_extractDescriptions(hapchung['jiji_yukhaps']));
    jijiHaps.addAll(_extractDescriptions(hapchung['jiji_samhaps']));
    jijiHaps.addAll(_extractDescriptions(hapchung['jiji_banghaps']));

    // 지지 충형파해
    final jijiNegatives = <String>[];
    jijiNegatives.addAll(_extractDescriptions(hapchung['jiji_chungs']));
    jijiNegatives.addAll(_extractDescriptions(hapchung['jiji_hyungs']));
    jijiNegatives.addAll(_extractDescriptions(hapchung['jiji_pas']));
    jijiNegatives.addAll(_extractDescriptions(hapchung['jiji_haes']));
    jijiNegatives.addAll(_extractDescriptions(hapchung['wonjins']));

    if (jijiHaps.isNotEmpty) {
      result['jiji_haps'] = jijiHaps.join(', ');
    }
    if (jijiNegatives.isNotEmpty) {
      result['jiji_chunghyungpaehae'] = jijiNegatives.join(', ');
    }

    // 합충 통계
    result['total_haps'] = hapchung['total_haps'] ?? 0;
    result['total_chungs'] = hapchung['total_chungs'] ?? 0;
    result['total_negatives'] = hapchung['total_negatives'] ?? 0;
    result['has_relations'] = hapchung['has_relations'] ?? false;

    // 프롬프트용 요약 문자열
    final summary = StringBuffer();
    if (result['cheongan_hapchung'] != null) {
      summary.writeln('- 천간 합충: ${result['cheongan_hapchung']}');
    }
    if (result['jiji_haps'] != null) {
      summary.writeln('- 지지 합: ${result['jiji_haps']}');
    }
    if (result['jiji_chunghyungpaehae'] != null) {
      summary.writeln('- 지지 충형파해: ${result['jiji_chunghyungpaehae']}');
    }
    result['summary'] = summary.toString().trim();

    return result;
  }

  /// 리스트에서 description 추출
  List<String> _extractDescriptions(dynamic list) {
    if (list == null || list is! List) return [];
    return list
        .map((item) => item['description'] as String?)
        .where((desc) => desc != null && desc.isNotEmpty)
        .cast<String>()
        .toList();
  }

  /// 신살 파싱 → 프롬프트용 간결한 형태
  Map<String, dynamic>? _parseSinsal(
    List<dynamic>? sinsalList,
    List<dynamic>? twelveSinsal,
  ) {
    final result = <String, dynamic>{};

    // 길신/흉신/중립 분류
    final gilsin = <String>[];
    final hyungsin = <String>[];
    final neutral = <String>[];

    if (sinsalList != null) {
      for (final item in sinsalList) {
        final name = item['name'] as String?;
        final type = item['type'] as String?;
        final location = item['location'] as String?;

        if (name == null) continue;

        final formatted = location != null ? '$name($location)' : name;

        switch (type) {
          case '길신':
            gilsin.add(formatted);
            break;
          case '흉신':
            hyungsin.add(formatted);
            break;
          default:
            neutral.add(formatted);
        }
      }
    }

    // 12신살 추가
    if (twelveSinsal != null) {
      for (final item in twelveSinsal) {
        final sinsal = item['sinsal'] as String?;
        final pillar = item['pillar'] as String?;
        final fortuneType = item['fortuneType'] as String?;

        if (sinsal == null) continue;

        final formatted = pillar != null ? '$sinsal($pillar)' : sinsal;

        if (fortuneType == '길') {
          gilsin.add(formatted);
        } else if (fortuneType == '흉') {
          hyungsin.add(formatted);
        } else {
          neutral.add(formatted);
        }
      }
    }

    if (gilsin.isNotEmpty) {
      result['gilsin'] = gilsin.join(', ');
    }
    if (hyungsin.isNotEmpty) {
      result['hyungsin'] = hyungsin.join(', ');
    }
    if (neutral.isNotEmpty) {
      result['neutral'] = neutral.join(', ');
    }

    // 프롬프트용 요약 문자열
    final summary = StringBuffer();
    if (gilsin.isNotEmpty) {
      summary.writeln('- 길신(吉神): ${gilsin.join(', ')}');
    }
    if (hyungsin.isNotEmpty) {
      summary.writeln('- 흉신(凶神): ${hyungsin.join(', ')}');
    }
    if (neutral.isNotEmpty) {
      summary.writeln('- 중립: ${neutral.join(', ')}');
    }
    result['summary'] = summary.toString().trim();

    return result.isEmpty ? null : result;
  }

  /// saju_analyses 존재 여부 확인
  Future<bool> exists(String profileId) async {
    final data = await getForFortuneInput(profileId);
    return data != null;
  }
}
