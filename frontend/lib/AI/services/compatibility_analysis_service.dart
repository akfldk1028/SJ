/// # 궁합 분석 서비스
///
/// ## 개요
/// 두 프로필 간의 궁합을 Dart 로직으로 분석합니다.
/// `profile_relations`에서 궁합 채팅 시작 시 자동으로 호출됩니다.
///
/// ## 파일 위치
/// `frontend/lib/AI/services/compatibility_analysis_service.dart`
///
/// ## v4.0 아키텍처 변경
/// - 기존: Gemini가 사주 계산 + 궁합 분석 (느리고 부정확)
/// - 변경: 두 프로필 모두 saju_analyses에서 조회 → Dart 궁합 계산 (빠르고 정확)
///
/// ## 실행 흐름
/// ```
/// 1. 궁합 채팅 시작
/// 2. profile_relations 조회
/// 3. compatibility_analysis_id 확인
///    - 있으면 → 캐시된 분석 사용
///    - 없으면 → Dart 궁합 계산 → compatibility_analyses 저장
/// 4. 채팅 시스템 프롬프트에 궁합 분석 결과 주입
/// ```
///
/// ## 사용 예시
/// ```dart
/// final service = CompatibilityAnalysisService();
/// final result = await service.analyzeCompatibility(
///   userId: user.id,
///   fromProfileId: myProfileId,
///   toProfileId: targetProfileId,
///   relationType: 'romantic_partner',
/// );
///
/// if (result.success) {
///   print('궁합 점수: ${result.data?['overall_score']}');
/// }
/// ```

import 'package:supabase_flutter/supabase_flutter.dart';

import 'compatibility_calculator.dart';

/// 궁합 분석 결과
class CompatibilityAnalysisResult {
  final bool success;
  final String? analysisId;
  final Map<String, dynamic>? data;
  final String? error;
  final int? tokensUsed;
  final int? processingTimeMs;

  const CompatibilityAnalysisResult({
    required this.success,
    this.analysisId,
    this.data,
    this.error,
    this.tokensUsed,
    this.processingTimeMs,
  });

  factory CompatibilityAnalysisResult.success({
    required String analysisId,
    required Map<String, dynamic> data,
    int? tokensUsed,
    int? processingTimeMs,
  }) =>
      CompatibilityAnalysisResult(
        success: true,
        analysisId: analysisId,
        data: data,
        tokensUsed: tokensUsed,
        processingTimeMs: processingTimeMs,
      );

  factory CompatibilityAnalysisResult.failure(String error) =>
      CompatibilityAnalysisResult(
        success: false,
        error: error,
      );

  factory CompatibilityAnalysisResult.cached({
    required String analysisId,
    required Map<String, dynamic> data,
  }) =>
      CompatibilityAnalysisResult(
        success: true,
        analysisId: analysisId,
        data: data,
      );
}

/// 궁합 분석 서비스
class CompatibilityAnalysisService {
  final SupabaseClient _client = Supabase.instance.client;

  /// 궁합 분석 실행 (캐시 확인 → 없으면 새로 분석)
  ///
  /// ## 파라미터
  /// - `userId`: 요청 사용자 ID (RLS용)
  /// - `fromProfileId`: 나의 프로필 ID
  /// - `toProfileId`: 상대방 프로필 ID
  /// - `relationType`: 관계 유형 (romantic_partner, family_parent 등)
  /// - `forceRefresh`: true면 캐시 무시하고 새로 분석
  Future<CompatibilityAnalysisResult> analyzeCompatibility({
    required String userId,
    required String fromProfileId,
    required String toProfileId,
    required String relationType,
    bool forceRefresh = false,
  }) async {
    final stopwatch = Stopwatch()..start();

    try {
      print('[CompatibilityService] 🎯 궁합 분석 시작');
      print('  - from: $fromProfileId');
      print('  - to: $toProfileId');
      print('  - relation: $relationType');

      // 1. 캐시 확인 (forceRefresh가 아닌 경우)
      if (!forceRefresh) {
        final cached = await _getCachedAnalysis(fromProfileId, toProfileId);
        if (cached != null) {
          // Phase 53: 순서가 바뀐 경우 캐시 무효화하고 새로 분석
          // target_* 필드들이 현재 "나"의 사주를 가리키게 되어 잘못된 분석이 됨
          final isSwapped = cached['_isSwapped'] as bool? ?? false;
          if (isSwapped) {
            print('[CompatibilityService] ⚠️ 순서가 바뀐 캐시 - 새로 분석 진행');
            // 캐시 무시하고 아래에서 새로 분석
          } else {
            print('[CompatibilityService] ✅ 캐시된 분석 사용: ${cached['id']}');
            return CompatibilityAnalysisResult.cached(
              analysisId: cached['id'],
              data: cached,
            );
          }
        }
      }

      // 2. 두 프로필의 사주 데이터 조회
      // v4.0: 나와 인연 모두 saju_analyses에서 조회 (둘 다 GPT-5.2 계산)
      final myData = await _getProfileWithSaju(fromProfileId);
      final targetData = await _getProfileWithSaju(toProfileId);

      if (myData == null) {
        return CompatibilityAnalysisResult.failure('나의 프로필을 찾을 수 없습니다');
      }
      if (targetData == null) {
        return CompatibilityAnalysisResult.failure('상대방 프로필을 찾을 수 없습니다');
      }

      // 사주 분석 데이터 확인
      final mySaju = myData['saju_analysis'] as Map<String, dynamic>?;
      final targetSaju = targetData['saju_analysis'] as Map<String, dynamic>?;

      if (mySaju == null) {
        return CompatibilityAnalysisResult.failure(
            '나의 사주 분석이 필요합니다. 채팅을 먼저 시작해주세요.');
      }
      if (targetSaju == null) {
        return CompatibilityAnalysisResult.failure(
            '인연의 사주 분석이 아직 완료되지 않았습니다. 잠시 후 다시 시도해주세요.');
      }

      print('[CompatibilityService] 📊 사주 데이터 확인');
      print('  - 나: ${mySaju['year_gan']}${mySaju['year_ji']} ${mySaju['month_gan']}${mySaju['month_ji']} ${mySaju['day_gan']}${mySaju['day_ji']} ${mySaju['hour_gan'] ?? '?'}${mySaju['hour_ji'] ?? '?'}');
      print('  - 인연: ${targetSaju['year_gan']}${targetSaju['year_ji']} ${targetSaju['month_gan']}${targetSaju['month_ji']} ${targetSaju['day_gan']}${targetSaju['day_ji']} ${targetSaju['hour_gan'] ?? '?'}${targetSaju['hour_ji'] ?? '?'}');

      // 3. Dart 궁합 계산 (v4.0: Gemini 제거, Dart 로직 사용)
      final calculationResult = compatibilityCalculator.calculate(
        mySaju: mySaju,
        targetSaju: targetSaju,
        relationType: relationType,
      );

      // 4. 결과 저장
      // v4.0: Dart 계산 결과 저장
      final savedId = await _saveAnalysisResult(
        userId: userId,
        fromProfileId: fromProfileId,
        toProfileId: toProfileId,
        relationType: relationType,
        calculationResult: calculationResult,
        mySajuData: mySaju,
        targetSajuData: targetSaju,
        processingTimeMs: stopwatch.elapsedMilliseconds,
      );

      // 5. profile_relations 업데이트 (Phase 51: pair_hapchung 추가)
      final pairHapchungData = {
        ...calculationResult.hapchungDetails.toJson(),
        'overall_score': calculationResult.overallScore,
        'positive_count': calculationResult.hapchungDetails.positiveCount,
        'negative_count': calculationResult.hapchungDetails.negativeCount,
      };

      await _updateProfileRelation(
        fromProfileId: fromProfileId,
        toProfileId: toProfileId,
        analysisId: savedId,
        pairHapchung: pairHapchungData,
      );

      stopwatch.stop();
      print('[CompatibilityService] ✅ 분석 완료: $savedId');
      print('  - 소요시간: ${stopwatch.elapsedMilliseconds}ms');
      print('  - 점수: ${calculationResult.overallScore}점');

      return CompatibilityAnalysisResult.success(
        analysisId: savedId,
        data: calculationResult.toJson(),
        processingTimeMs: stopwatch.elapsedMilliseconds,
      );
    } catch (e, stack) {
      print('[CompatibilityService] ❌ 오류: $e');
      print(stack);
      return CompatibilityAnalysisResult.failure(e.toString());
    }
  }

  /// 캐시된 분석 조회
  ///
  /// ## 순서 처리 (v5.1 Phase 53)
  /// - profile1_id, profile2_id 조합으로 조회 (순서 무관)
  /// - 단, 조회 후 순서가 바뀐 경우 `_isSwapped` 플래그 추가
  /// - 호출자가 이 플래그를 보고 적절히 처리해야 함
  Future<Map<String, dynamic>?> _getCachedAnalysis(
    String fromProfileId,
    String toProfileId,
  ) async {
    try {
      // profile1_id, profile2_id 조합으로 조회 (순서 무관)
      final response = await _client
          .from('compatibility_analyses')
          .select()
          .or('and(profile1_id.eq.$fromProfileId,profile2_id.eq.$toProfileId),'
              'and(profile1_id.eq.$toProfileId,profile2_id.eq.$fromProfileId)')
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null) return null;

      // Phase 53: 순서 확인 - profile1_id가 fromProfileId와 일치하는지
      final isSwapped = response['profile1_id'] != fromProfileId;

      if (isSwapped) {
        print('[CompatibilityService] ⚠️ 캐시된 분석의 순서가 바뀜 - 데이터 스왑 필요');
        // _isSwapped 플래그 추가 (호출자가 사용)
        response['_isSwapped'] = true;
      } else {
        response['_isSwapped'] = false;
      }

      return response;
    } catch (e) {
      print('[CompatibilityService] 캐시 조회 오류: $e');
      return null;
    }
  }

  /// 프로필 + 사주 분석 데이터 조회
  ///
  /// v4.0: 나와 인연 모두 동일한 로직으로 saju_analyses 조회
  Future<Map<String, dynamic>?> _getProfileWithSaju(String profileId) async {
    try {
      // 프로필 조회
      final profile = await _client
          .from('saju_profiles')
          .select()
          .eq('id', profileId)
          .maybeSingle();

      if (profile == null) return null;

      // 사주 분석 조회
      final sajuAnalysis = await _client
          .from('saju_analyses')
          .select()
          .eq('profile_id', profileId)
          .maybeSingle();

      return {
        'profile': profile,
        'saju_analysis': sajuAnalysis,
      };
    } catch (e) {
      print('[CompatibilityService] 프로필 조회 오류: $e');
      return null;
    }
  }

  /// 분석 결과 저장
  ///
  /// ## v4.0 변경사항
  /// - Dart 궁합 계산 결과 저장
  /// - 나와 인연 모두 saju_analyses 데이터 사용 (GPT-5.2 계산)
  /// - Gemini 호출 제거
  ///
  /// ## 저장 데이터
  /// - saju_analysis: 합충형해파 상세 분석 결과 (JSONB)
  /// - target_year_gan/ji, target_month_gan/ji 등: 인연 사주 개별 필드
  Future<String> _saveAnalysisResult({
    required String userId,
    required String fromProfileId,
    required String toProfileId,
    required String relationType,
    required CompatibilityResult calculationResult,
    required Map<String, dynamic> mySajuData,
    required Map<String, dynamic> targetSajuData,
    required int processingTimeMs,
  }) async {
    print('[CompatibilityService] 💾 Dart 궁합 계산 결과 저장');

    // 인연 사주 개별 필드 추출
    final targetYearGan = targetSajuData['year_gan'] as String?;
    final targetYearJi = targetSajuData['year_ji'] as String?;
    final targetMonthGan = targetSajuData['month_gan'] as String?;
    final targetMonthJi = targetSajuData['month_ji'] as String?;
    final targetDayGan = targetSajuData['day_gan'] as String?;
    final targetDayJi = targetSajuData['day_ji'] as String?;
    final targetHourGan = targetSajuData['hour_gan'] as String?;
    final targetHourJi = targetSajuData['hour_ji'] as String?;
    final targetOheng = targetSajuData['oheng_distribution'] as Map<String, dynamic>?;
    final targetHapchung = targetSajuData['hapchung'] as Map<String, dynamic>?;
    final targetSinsalList = targetSajuData['sinsal_list'] as List<dynamic>?;
    final targetTwelveUnsung = targetSajuData['twelve_unsung'] as List<dynamic>?;
    final targetGilseong = targetSajuData['gilseong'] as Map<String, dynamic>?;
    final targetDayMaster = _extractDayMaster(targetDayGan);

    print('  - 인연 사주: $targetYearGan$targetYearJi $targetMonthGan$targetMonthJi $targetDayGan$targetDayJi ${targetHourGan ?? '?'}${targetHourJi ?? '?'}');

    // Phase 51: 나의 개인 합충형해파 추출
    final ownerHapchung = mySajuData['hapchung'] as Map<String, dynamic>?;

    // Phase 51: 두 사람 간 합충형해파 (pair_hapchung) - 궁합의 핵심!
    final pairHapchungData = {
      ...calculationResult.hapchungDetails.toJson(),
      'overall_score': calculationResult.overallScore,
      'positive_count': calculationResult.hapchungDetails.positiveCount,
      'negative_count': calculationResult.hapchungDetails.negativeCount,
    };

    print('  - 나의 합충형해파: ${ownerHapchung != null ? "있음" : "없음"}');
    print('  - 두 사람 간 합충형해파: 합 ${calculationResult.hapchungDetails.positiveCount}개, 충/형/해/파/원진 ${calculationResult.hapchungDetails.negativeCount}개');

    final response = await _client.from('compatibility_analyses').insert({
      'profile1_id': fromProfileId,
      'profile2_id': toProfileId,
      'analysis_type': _getAnalysisType(relationType),
      'relation_type': relationType,
      'overall_score': calculationResult.overallScore,
      'category_scores': calculationResult.categoryScores,
      'saju_analysis': calculationResult.hapchungDetails.toJson(),
      'summary': calculationResult.summary,
      'strengths': calculationResult.strengths,
      'challenges': calculationResult.challenges,
      'advice': null, // v4.0: 조언은 채팅에서 생성
      'model_provider': 'dart', // v4.0: Dart 계산
      'model_name': 'compatibility_calculator_v5',
      'tokens_used': 0, // Dart 계산은 토큰 사용 없음
      'processing_time_ms': processingTimeMs,
      // 인연 사주 개별 필드
      'target_year_gan': targetYearGan,
      'target_year_ji': targetYearJi,
      'target_month_gan': targetMonthGan,
      'target_month_ji': targetMonthJi,
      'target_day_gan': targetDayGan,
      'target_day_ji': targetDayJi,
      'target_hour_gan': targetHourGan,
      'target_hour_ji': targetHourJi,
      'target_oheng_distribution': targetOheng,
      'target_hapchung': targetHapchung,
      'target_sinsal_list': targetSinsalList,
      'target_twelve_unsung': targetTwelveUnsung,
      'target_gilseong': targetGilseong,
      'target_day_master': targetDayMaster,
      // Phase 51: 나의 합충형해파 + 두 사람 간 합충형해파
      'owner_hapchung': ownerHapchung,
      'pair_hapchung': pairHapchungData,
    }).select('id').single();

    return response['id'] as String;
  }

  /// 천간에서 일간(오행) 추출
  String? _extractDayMaster(String? dayGan) {
    if (dayGan == null) return null;
    // 한글(한자) 형식에서 한글만 추출: "갑(甲)" → "갑"
    final korean = dayGan.split('(').first;
    const ganToOheng = {
      '갑': '木', '을': '木',
      '병': '火', '정': '火',
      '무': '土', '기': '土',
      '경': '金', '신': '金',
      '임': '水', '계': '水',
    };
    return ganToOheng[korean];
  }

  /// profile_relations 업데이트
  ///
  /// Phase 51: pair_hapchung도 함께 저장
  Future<void> _updateProfileRelation({
    required String fromProfileId,
    required String toProfileId,
    required String analysisId,
    Map<String, dynamic>? pairHapchung,
  }) async {
    try {
      await _client
          .from('profile_relations')
          .update({
            'compatibility_analysis_id': analysisId,
            'analysis_status': 'completed',
            'analysis_completed_at': DateTime.now().toIso8601String(),
            // Phase 51: 두 사람 간 합충형해파 저장
            if (pairHapchung != null) 'pair_hapchung': pairHapchung,
          })
          .eq('from_profile_id', fromProfileId)
          .eq('to_profile_id', toProfileId);
    } catch (e) {
      print('[CompatibilityService] profile_relations 업데이트 오류: $e');
      // 에러가 나도 분석 결과는 저장되었으므로 무시
    }
  }

  /// 관계 유형 → 분석 유형 매핑
  String _getAnalysisType(String relationType) {
    if (relationType.startsWith('romantic_')) return 'love';
    if (relationType.startsWith('family_')) return 'family';
    if (relationType.startsWith('work_') ||
        relationType == 'business_partner') {
      return 'business';
    }
    if (relationType.startsWith('friend_')) return 'friendship';
    return 'general';
  }

  /// 궁합 분석 결과 조회 (ID로)
  Future<Map<String, dynamic>?> getAnalysisById(String analysisId) async {
    try {
      return await _client
          .from('compatibility_analyses')
          .select()
          .eq('id', analysisId)
          .maybeSingle();
    } catch (e) {
      print('[CompatibilityService] 분석 조회 오류: $e');
      return null;
    }
  }

  /// 두 프로필 간 궁합 분석 결과 조회
  Future<Map<String, dynamic>?> getAnalysisByProfiles(
    String profileId1,
    String profileId2,
  ) async {
    return await _getCachedAnalysis(profileId1, profileId2);
  }

  /// 궁합 분석이 존재하는지 확인
  Future<bool> hasAnalysis(String fromProfileId, String toProfileId) async {
    final cached = await _getCachedAnalysis(fromProfileId, toProfileId);
    return cached != null;
  }

  /// 궁합 분석 결과 삭제 (재분석 필요 시)
  Future<void> deleteAnalysis(String analysisId) async {
    await _client.from('compatibility_analyses').delete().eq('id', analysisId);
  }
}
