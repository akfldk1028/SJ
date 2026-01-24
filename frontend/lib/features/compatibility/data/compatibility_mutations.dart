import 'package:flutter/foundation.dart';
import '../../../core/data/data.dart';
import 'models/compatibility_analysis_model.dart';
import 'compatibility_schema.dart';

/// Compatibility Analyses 뮤테이션 클래스
///
/// INSERT, UPDATE, DELETE 작업 담당
/// profile_relations 테이블과 연동 처리 포함
class CompatibilityMutations extends BaseMutations {
  const CompatibilityMutations();

  /// 궁합 분석 결과 생성
  ///
  /// 1. compatibility_analyses INSERT
  /// 2. profile_relations UPDATE (FK 연결)
  Future<QueryResult<CompatibilityAnalysisModel>> create({
    required String profile1Id,
    required String profile2Id,
    required String analysisType,
    String? relationType,
    int? overallScore,
    Map<String, dynamic>? categoryScores,
    Map<String, dynamic>? sajuAnalysis,
    String? summary,
    List<String>? strengths,
    List<String>? challenges,
    String? advice,
    String? modelProvider,
    String? modelName,
    int? tokensUsed,
    int? processingTimeMs,
    Map<String, dynamic>? ownerHapchung,
    Map<String, dynamic>? pairHapchung,
    // 인연 사주 상세 (선택적)
    String? targetYearGan,
    String? targetYearJi,
    String? targetMonthGan,
    String? targetMonthJi,
    String? targetDayGan,
    String? targetDayJi,
    String? targetHourGan,
    String? targetHourJi,
    Map<String, dynamic>? targetOhengDistribution,
    Map<String, dynamic>? targetHapchung,
    List<dynamic>? targetSinsalList,
    List<dynamic>? targetTwelveUnsung,
    Map<String, dynamic>? targetGilseong,
    String? targetDayMaster,
  }) async {
    debugPrint('🔍 [CompatibilityMutations.create] 시작');
    debugPrint('   - profile1Id: $profile1Id');
    debugPrint('   - profile2Id: $profile2Id');

    return safeMutation(
      mutation: (client) async {
        final data = <String, dynamic>{
          'profile1_id': profile1Id,
          'profile2_id': profile2Id,
          'analysis_type': analysisType,
          'relation_type': relationType,
          'overall_score': overallScore,
          'category_scores': categoryScores,
          'saju_analysis': sajuAnalysis,
          'summary': summary,
          'strengths': strengths,
          'challenges': challenges,
          'advice': advice,
          'model_provider': modelProvider,
          'model_name': modelName,
          'tokens_used': tokensUsed,
          'processing_time_ms': processingTimeMs,
          'owner_hapchung': ownerHapchung,
          'pair_hapchung': pairHapchung,
          // 인연 사주 상세
          'target_year_gan': targetYearGan,
          'target_year_ji': targetYearJi,
          'target_month_gan': targetMonthGan,
          'target_month_ji': targetMonthJi,
          'target_day_gan': targetDayGan,
          'target_day_ji': targetDayJi,
          'target_hour_gan': targetHourGan,
          'target_hour_ji': targetHourJi,
          'target_oheng_distribution': targetOhengDistribution,
          'target_hapchung': targetHapchung,
          'target_sinsal_list': targetSinsalList,
          'target_twelve_unsung': targetTwelveUnsung,
          'target_gilseong': targetGilseong,
          'target_day_master': targetDayMaster,
        };

        // null 값 제거
        data.removeWhere((key, value) => value == null);

        final response = await client
            .from(compatibilityAnalysesTable)
            .insert(data)
            .select(compatibilitySelectColumns)
            .single();

        debugPrint('✅ [CompatibilityMutations.create] 성공: ${response['id']}');

        return CompatibilityAnalysisModel.fromSupabaseMap(response);
      },
      errorPrefix: '궁합 분석 생성 실패',
    );
  }

  /// 궁합 분석 결과 수정
  Future<QueryResult<CompatibilityAnalysisModel>> update({
    required String analysisId,
    int? overallScore,
    Map<String, dynamic>? categoryScores,
    Map<String, dynamic>? sajuAnalysis,
    String? summary,
    String? analysisContent,
    List<String>? strengths,
    List<String>? challenges,
    String? advice,
    Map<String, dynamic>? pairHapchung,
  }) async {
    return safeMutation(
      mutation: (client) async {
        final data = <String, dynamic>{
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        };

        if (overallScore != null) data['overall_score'] = overallScore;
        if (categoryScores != null) data['category_scores'] = categoryScores;
        if (sajuAnalysis != null) data['saju_analysis'] = sajuAnalysis;
        if (summary != null) data['summary'] = summary;
        if (analysisContent != null) data['analysis_content'] = analysisContent;
        if (strengths != null) data['strengths'] = strengths;
        if (challenges != null) data['challenges'] = challenges;
        if (advice != null) data['advice'] = advice;
        if (pairHapchung != null) data['pair_hapchung'] = pairHapchung;

        final response = await client
            .from(compatibilityAnalysesTable)
            .update(data)
            .eq(CompatibilityColumns.id, analysisId)
            .select(compatibilitySelectColumns)
            .single();

        return CompatibilityAnalysisModel.fromSupabaseMap(response);
      },
      errorPrefix: '궁합 분석 수정 실패',
    );
  }

  /// 조언(advice) 업데이트
  ///
  /// AI 채팅 후 생성된 조언 저장용
  Future<QueryResult<CompatibilityAnalysisModel>> updateAdvice(
    String analysisId,
    String advice,
  ) async {
    return safeMutation(
      mutation: (client) async {
        final response = await client
            .from(compatibilityAnalysesTable)
            .update({
              'advice': advice,
              'updated_at': DateTime.now().toUtc().toIso8601String(),
            })
            .eq(CompatibilityColumns.id, analysisId)
            .select(compatibilitySelectColumns)
            .single();

        return CompatibilityAnalysisModel.fromSupabaseMap(response);
      },
      errorPrefix: '조언 업데이트 실패',
    );
  }

  /// 궁합 분석 삭제
  Future<QueryResult<void>> delete(String analysisId) async {
    return safeMutation(
      mutation: (client) async {
        // 1. profile_relations의 FK 먼저 해제
        await client
            .from('profile_relations')
            .update({
              'compatibility_analysis_id': null,
              'analysis_status': 'pending',
              'analysis_completed_at': null,
              'pair_hapchung': null,
            })
            .eq('compatibility_analysis_id', analysisId);

        // 2. compatibility_analyses 삭제
        await client
            .from(compatibilityAnalysesTable)
            .delete()
            .eq(CompatibilityColumns.id, analysisId);
      },
      errorPrefix: '궁합 분석 삭제 실패',
    );
  }

  /// 두 프로필 간 궁합 분석 삭제
  Future<QueryResult<void>> deleteByProfilePair(
    String profileId1,
    String profileId2,
  ) async {
    return safeMutation(
      mutation: (client) async {
        // 순서 무관하게 삭제
        await client
            .from(compatibilityAnalysesTable)
            .delete()
            .or('and(profile1_id.eq.$profileId1,profile2_id.eq.$profileId2),'
                'and(profile1_id.eq.$profileId2,profile2_id.eq.$profileId1)');
      },
      errorPrefix: '프로필 간 궁합 분석 삭제 실패',
    );
  }

  /// profile_relations과 연결
  ///
  /// 궁합 분석 생성 후 호출하여 FK 연결
  Future<QueryResult<void>> linkToProfileRelation({
    required String fromProfileId,
    required String toProfileId,
    required String analysisId,
    Map<String, dynamic>? pairHapchung,
  }) async {
    return safeMutation(
      mutation: (client) async {
        final updateData = <String, dynamic>{
          'compatibility_analysis_id': analysisId,
          'analysis_status': 'completed',
          'analysis_completed_at': DateTime.now().toUtc().toIso8601String(),
        };

        if (pairHapchung != null) {
          updateData['pair_hapchung'] = pairHapchung;
        }

        await client
            .from('profile_relations')
            .update(updateData)
            .eq('from_profile_id', fromProfileId)
            .eq('to_profile_id', toProfileId);

        debugPrint('✅ [CompatibilityMutations] profile_relations 연결 완료');
      },
      errorPrefix: 'profile_relations 연결 실패',
    );
  }

  /// profile_relations 연결 해제
  Future<QueryResult<void>> unlinkFromProfileRelation({
    required String fromProfileId,
    required String toProfileId,
  }) async {
    return safeMutation(
      mutation: (client) async {
        await client
            .from('profile_relations')
            .update({
              'compatibility_analysis_id': null,
              'analysis_status': 'pending',
              'analysis_completed_at': null,
              'pair_hapchung': null,
            })
            .eq('from_profile_id', fromProfileId)
            .eq('to_profile_id', toProfileId);
      },
      errorPrefix: 'profile_relations 연결 해제 실패',
    );
  }

  /// 특정 프로필의 모든 궁합 분석 삭제
  ///
  /// 프로필 삭제 시 호출
  Future<QueryResult<void>> deleteAllByProfile(String profileId) async {
    return safeMutation(
      mutation: (client) async {
        await client
            .from(compatibilityAnalysesTable)
            .delete()
            .or('profile1_id.eq.$profileId,profile2_id.eq.$profileId');
      },
      errorPrefix: '프로필 궁합 분석 전체 삭제 실패',
    );
  }
}

/// 싱글톤 인스턴스
const compatibilityMutations = CompatibilityMutations();
