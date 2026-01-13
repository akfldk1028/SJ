/// # 궁합 분석 서비스
///
/// ## 개요
/// 두 프로필 간의 궁합을 Gemini AI로 분석합니다.
/// `profile_relations`에서 궁합 채팅 시작 시 자동으로 호출됩니다.
///
/// ## 파일 위치
/// `frontend/lib/AI/services/compatibility_analysis_service.dart`
///
/// ## 실행 흐름
/// ```
/// 1. 궁합 채팅 시작
/// 2. profile_relations 조회
/// 3. compatibility_analysis_id 확인
///    - 있으면 → 캐시된 분석 사용
///    - 없으면 → Gemini 분석 실행 → compatibility_analyses 저장
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

import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/ai_constants.dart';
import '../prompts/compatibility_prompt.dart';
import 'ai_api_service.dart';

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
  final AiApiService _aiService = AiApiService();

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
          print('[CompatibilityService] ✅ 캐시된 분석 사용: ${cached['id']}');
          return CompatibilityAnalysisResult.cached(
            analysisId: cached['id'],
            data: cached,
          );
        }
      }

      // 2. 두 프로필의 사주 데이터 조회
      final myData = await _getProfileWithSaju(fromProfileId);
      final targetData = await _getProfileWithSaju(toProfileId);

      if (myData == null) {
        return CompatibilityAnalysisResult.failure('나의 프로필을 찾을 수 없습니다');
      }
      if (targetData == null) {
        return CompatibilityAnalysisResult.failure('상대방 프로필을 찾을 수 없습니다');
      }

      // 3. Gemini 궁합 분석 실행
      final analysisResult = await _runGeminiAnalysis(
        myData: myData,
        targetData: targetData,
        relationType: relationType,
      );

      if (!analysisResult.success) {
        return CompatibilityAnalysisResult.failure(
            analysisResult.error ?? 'Gemini 분석 실패');
      }

      // 4. 결과 저장
      final savedId = await _saveAnalysisResult(
        userId: userId,
        fromProfileId: fromProfileId,
        toProfileId: toProfileId,
        relationType: relationType,
        analysisData: analysisResult.content!,
        tokensUsed: (analysisResult.promptTokens ?? 0) +
            (analysisResult.completionTokens ?? 0),
        processingTimeMs: stopwatch.elapsedMilliseconds,
      );

      // 5. profile_relations 업데이트
      await _updateProfileRelation(
        fromProfileId: fromProfileId,
        toProfileId: toProfileId,
        analysisId: savedId,
      );

      stopwatch.stop();
      print('[CompatibilityService] ✅ 분석 완료: $savedId');
      print('  - 소요시간: ${stopwatch.elapsedMilliseconds}ms');

      return CompatibilityAnalysisResult.success(
        analysisId: savedId,
        data: analysisResult.content!,
        tokensUsed: (analysisResult.promptTokens ?? 0) +
            (analysisResult.completionTokens ?? 0),
        processingTimeMs: stopwatch.elapsedMilliseconds,
      );
    } catch (e, stack) {
      print('[CompatibilityService] ❌ 오류: $e');
      print(stack);
      return CompatibilityAnalysisResult.failure(e.toString());
    }
  }

  /// 캐시된 분석 조회
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

      return response;
    } catch (e) {
      print('[CompatibilityService] 캐시 조회 오류: $e');
      return null;
    }
  }

  /// 프로필 + 사주 분석 데이터 조회
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

  /// Gemini 궁합 분석 실행
  Future<AiApiResponse> _runGeminiAnalysis({
    required Map<String, dynamic> myData,
    required Map<String, dynamic> targetData,
    required String relationType,
  }) async {
    final myProfile = myData['profile'] as Map<String, dynamic>;
    final mySaju = myData['saju_analysis'] as Map<String, dynamic>?;

    final targetProfile = targetData['profile'] as Map<String, dynamic>;
    final targetSaju = targetData['saju_analysis'] as Map<String, dynamic>?;

    // 입력 데이터 구성
    final inputData = {
      'my_profile_id': myProfile['id'],
      'my_name': myProfile['display_name'] ?? '나',
      'my_birth_date': myProfile['birth_date'] ?? '',
      'my_gender': myProfile['gender'] ?? 'male',
      'my_saju': mySaju != null
          ? {
              'year_gan': mySaju['year_gan'],
              'year_ji': mySaju['year_ji'],
              'month_gan': mySaju['month_gan'],
              'month_ji': mySaju['month_ji'],
              'day_gan': mySaju['day_gan'],
              'day_ji': mySaju['day_ji'],
              'hour_gan': mySaju['hour_gan'],
              'hour_ji': mySaju['hour_ji'],
            }
          : null,
      'my_oheng': mySaju?['oheng_distribution'],
      'my_yongsin': mySaju?['yongsin'],
      'my_hapchung': mySaju?['hapchung'],
      'my_sinsal': mySaju?['sinsal_list'],
      'my_unsung': mySaju?['twelve_unsung'],
      'target_profile_id': targetProfile['id'],
      'target_name': targetProfile['display_name'] ?? '상대방',
      'target_birth_date': targetProfile['birth_date'] ?? '',
      'target_gender': targetProfile['gender'] ?? 'male',
      'target_saju': targetSaju != null
          ? {
              'year_gan': targetSaju['year_gan'],
              'year_ji': targetSaju['year_ji'],
              'month_gan': targetSaju['month_gan'],
              'month_ji': targetSaju['month_ji'],
              'day_gan': targetSaju['day_gan'],
              'day_ji': targetSaju['day_ji'],
              'hour_gan': targetSaju['hour_gan'],
              'hour_ji': targetSaju['hour_ji'],
            }
          : null,
      'target_oheng': targetSaju?['oheng_distribution'],
      'target_yongsin': targetSaju?['yongsin'],
      'target_hapchung': targetSaju?['hapchung'],
      'target_sinsal': targetSaju?['sinsal_list'],
      'target_unsung': targetSaju?['twelve_unsung'],
      'relation_type': relationType,
    };

    // 프롬프트 생성
    final prompt = CompatibilityPrompt(relationType: relationType);
    final messages = prompt.buildMessages(inputData);

    // Gemini API 호출
    return await _aiService.callGemini(
      messages: messages,
      model: prompt.modelName,
      maxTokens: prompt.maxTokens,
      temperature: prompt.temperature,
      logType: 'compatibility_analysis',
    );
  }

  /// 분석 결과 저장
  Future<String> _saveAnalysisResult({
    required String userId,
    required String fromProfileId,
    required String toProfileId,
    required String relationType,
    required Map<String, dynamic> analysisData,
    required int tokensUsed,
    required int processingTimeMs,
  }) async {
    final response = await _client.from('compatibility_analyses').insert({
      'profile1_id': fromProfileId,
      'profile2_id': toProfileId,
      'analysis_type': _getAnalysisType(relationType),
      'relation_type': relationType,
      'overall_score': analysisData['overall_score'],
      'category_scores': analysisData['category_scores'],
      'saju_analysis': analysisData['detailed_analysis'],
      'summary': analysisData['summary'],
      'strengths': analysisData['strengths'],
      'challenges': analysisData['challenges'],
      'advice': jsonEncode(analysisData['advice']),
      'model_provider': 'google',
      'model_name': GoogleModels.gemini20Flash,
      'tokens_used': tokensUsed,
      'processing_time_ms': processingTimeMs,
    }).select('id').single();

    return response['id'] as String;
  }

  /// profile_relations 업데이트
  Future<void> _updateProfileRelation({
    required String fromProfileId,
    required String toProfileId,
    required String analysisId,
  }) async {
    try {
      await _client
          .from('profile_relations')
          .update({
            'compatibility_analysis_id': analysisId,
            'analysis_status': 'completed',
            'analysis_completed_at': DateTime.now().toIso8601String(),
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
