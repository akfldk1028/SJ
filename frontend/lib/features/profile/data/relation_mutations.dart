import 'package:flutter/foundation.dart';
import '../../../core/data/data.dart';
import 'models/profile_relation_model.dart';
import 'relation_schema.dart';

/// Profile Relations 뮤테이션 클래스
///
/// INSERT, UPDATE, DELETE 작업 담당
/// 오프라인 모드에서는 실패 반환
class RelationMutations extends BaseMutations {
  const RelationMutations();

  /// 관계 생성
  Future<QueryResult<ProfileRelationModel>> create({
    required String userId,
    required String fromProfileId,
    required String toProfileId,
    required String relationType,
    String? displayName,
    String? memo,
    bool isFavorite = false,
    int sortOrder = 0,
    String? fromProfileAnalysisId,
    String? toProfileAnalysisId,
  }) async {
    debugPrint('🔍 [RelationMutations.create] 시작');
    debugPrint('   - userId: $userId');
    debugPrint('   - fromProfileId: $fromProfileId');
    debugPrint('   - toProfileId: $toProfileId');
    debugPrint('   - relationType: $relationType');
    debugPrint('   - fromProfileAnalysisId: $fromProfileAnalysisId');
    debugPrint('   - toProfileAnalysisId: $toProfileAnalysisId');

    return safeMutation(
      mutation: (client) async {
        final data = <String, dynamic>{
          'user_id': userId,
          'from_profile_id': fromProfileId,
          'to_profile_id': toProfileId,
          'relation_type': relationType,
          'display_name': displayName,
          'memo': memo,
          'is_favorite': isFavorite,
          'sort_order': sortOrder,
        };
        // v4.0: saju_analyses 연결 추가
        if (fromProfileAnalysisId != null) {
          data['from_profile_analysis_id'] = fromProfileAnalysisId;
        }
        if (toProfileAnalysisId != null) {
          data['to_profile_analysis_id'] = toProfileAnalysisId;
        }

        debugPrint('🔍 [RelationMutations.create] Supabase INSERT 호출');
        debugPrint('   - 테이블: $profileRelationsTable');
        debugPrint('   - 데이터: $data');

        final response = await client
            .from(profileRelationsTable)
            .insert(data)
            .select(relationSelectColumns)
            .single();

        debugPrint('✅ [RelationMutations.create] INSERT 성공');
        debugPrint('   - 응답: $response');

        return ProfileRelationModel.fromSupabaseMap(response);
      },
      errorPrefix: '관계 생성 실패',
    );
  }

  /// 관계 업데이트
  Future<QueryResult<ProfileRelationModel>> update({
    required String relationId,
    String? relationType,
    String? displayName,
    String? memo,
    bool? isFavorite,
    int? sortOrder,
  }) async {
    return safeMutation(
      mutation: (client) async {
        final data = <String, dynamic>{
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        };

        if (relationType != null) data['relation_type'] = relationType;
        if (displayName != null) data['display_name'] = displayName;
        if (memo != null) data['memo'] = memo;
        if (isFavorite != null) data['is_favorite'] = isFavorite;
        if (sortOrder != null) data['sort_order'] = sortOrder;

        final response = await client
            .from(profileRelationsTable)
            .update(data)
            .eq(RelationColumns.id, relationId)
            .select(relationSelectColumns)
            .single();
        return ProfileRelationModel.fromSupabaseMap(response);
      },
      errorPrefix: '관계 업데이트 실패',
    );
  }

  /// 관계 삭제 (+ 상대방 프로필도 함께 삭제)
  ///
  /// 1. 관계 정보 조회 (to_profile_id, compatibility_analysis_id)
  /// 2. 연결된 compatibility_analyses 삭제 시도 (RLS 실패해도 계속 진행)
  /// 3. profile_relations 삭제
  /// 4. to_profile (saju_profiles) 삭제
  Future<QueryResult<void>> delete(String relationId) async {
    debugPrint('🗑️ [RelationMutations.delete] 시작: relationId=$relationId');

    return safeMutation(
      mutation: (client) async {
        debugPrint('🔍 [RelationMutations.delete] Step 1: 관계 정보 조회');

        // 1. 먼저 관계 정보 조회 (to_profile_id, compatibility_analysis_id)
        final relation = await client
            .from(profileRelationsTable)
            .select('to_profile_id, compatibility_analysis_id')
            .eq(RelationColumns.id, relationId)
            .maybeSingle();

        debugPrint('🔍 [RelationMutations.delete] 조회 결과: $relation');

        if (relation == null) {
          debugPrint('⚠️ [RelationMutations.delete] 관계가 존재하지 않음');
          return;
        }

        final toProfileId = relation['to_profile_id'] as String?;

        // 2. 연결된 궁합 분석이 있으면 삭제 시도 (RLS 실패해도 무시)
        if (relation['compatibility_analysis_id'] != null) {
          final analysisId = relation['compatibility_analysis_id'] as String;
          debugPrint('🗑️ [RelationMutations.delete] Step 2: 궁합 분석 삭제 시도: $analysisId');

          try {
            await client
                .from('compatibility_analyses')
                .delete()
                .eq('id', analysisId);
            debugPrint('✅ [RelationMutations.delete] 궁합 분석 삭제 성공');
          } catch (e) {
            // RLS 정책으로 인해 삭제 실패할 수 있음 - 무시하고 계속 진행
            debugPrint('⚠️ [RelationMutations.delete] 궁합 분석 삭제 실패 (RLS?): $e');
          }
        } else {
          debugPrint('ℹ️ [RelationMutations.delete] Step 2 스킵: 연결된 궁합 분석 없음');
        }

        // 3. profile_relations 삭제
        debugPrint('🗑️ [RelationMutations.delete] Step 3: profile_relations 삭제');
        await client
            .from(profileRelationsTable)
            .delete()
            .eq(RelationColumns.id, relationId);

        // 4. 삭제 검증 (Supabase delete()는 void 반환, RLS 차단 시 silent fail)
        debugPrint('🔍 [RelationMutations.delete] Step 4: profile_relations 삭제 검증');
        final verifyResult = await client
            .from(profileRelationsTable)
            .select('id')
            .eq(RelationColumns.id, relationId)
            .maybeSingle();

        if (verifyResult != null) {
          debugPrint('❌ [RelationMutations.delete] profile_relations 삭제 검증 실패');
          throw Exception('관계 삭제 실패: RLS 정책에 의해 차단되었거나 권한이 없습니다');
        }

        debugPrint('✅ [RelationMutations.delete] profile_relations 삭제 완료');

        // 5. to_profile (saju_profiles) 삭제
        if (toProfileId != null) {
          debugPrint('🗑️ [RelationMutations.delete] Step 5: saju_profiles 삭제: $toProfileId');

          try {
            await client
                .from('saju_profiles')
                .delete()
                .eq('id', toProfileId);

            // 프로필 삭제 검증
            final profileVerify = await client
                .from('saju_profiles')
                .select('id')
                .eq('id', toProfileId)
                .maybeSingle();

            if (profileVerify != null) {
              debugPrint('⚠️ [RelationMutations.delete] saju_profiles 삭제 실패 (RLS?)');
            } else {
              debugPrint('✅ [RelationMutations.delete] saju_profiles 삭제 완료: $toProfileId');
            }
          } catch (e) {
            debugPrint('⚠️ [RelationMutations.delete] saju_profiles 삭제 실패: $e');
          }
        }

        debugPrint('✅ [RelationMutations.delete] 전체 삭제 완료: $relationId');
      },
      errorPrefix: '관계 삭제 실패',
    );
  }

  /// 두 프로필 간 관계 삭제
  ///
  /// 1. 연결된 compatibility_analyses 삭제 (있으면)
  /// 2. profile_relations 삭제
  Future<QueryResult<void>> deleteByProfilePair(
    String fromProfileId,
    String toProfileId,
  ) async {
    return safeMutation(
      mutation: (client) async {
        // 1. 먼저 관계 정보 조회하여 compatibility_analysis_id 확인
        final relation = await client
            .from(profileRelationsTable)
            .select('compatibility_analysis_id')
            .eq(RelationColumns.fromProfileId, fromProfileId)
            .eq(RelationColumns.toProfileId, toProfileId)
            .maybeSingle();

        // 2. 연결된 궁합 분석이 있으면 삭제
        if (relation != null && relation['compatibility_analysis_id'] != null) {
          final analysisId = relation['compatibility_analysis_id'] as String;
          debugPrint('🗑️ [RelationMutations.deleteByProfilePair] 연결된 궁합 분석 삭제: $analysisId');

          await client
              .from('compatibility_analyses')
              .delete()
              .eq('id', analysisId);
        }

        // 3. profile_relations 삭제
        await client
            .from(profileRelationsTable)
            .delete()
            .eq(RelationColumns.fromProfileId, fromProfileId)
            .eq(RelationColumns.toProfileId, toProfileId);

        // 4. 삭제 검증
        final verifyResult = await client
            .from(profileRelationsTable)
            .select('id')
            .eq(RelationColumns.fromProfileId, fromProfileId)
            .eq(RelationColumns.toProfileId, toProfileId)
            .maybeSingle();

        if (verifyResult != null) {
          debugPrint('❌ [RelationMutations.deleteByProfilePair] 삭제 검증 실패');
          throw Exception('삭제 실패: RLS 정책에 의해 차단되었거나 권한이 없습니다');
        }

        debugPrint('✅ [RelationMutations.deleteByProfilePair] 관계 삭제 완료');
      },
      errorPrefix: '프로필 간 관계 삭제 실패',
    );
  }

  /// 즐겨찾기 토글
  Future<QueryResult<ProfileRelationModel>> toggleFavorite(
    String relationId,
    bool isFavorite,
  ) async {
    return safeMutation(
      mutation: (client) async {
        final response = await client
            .from(profileRelationsTable)
            .update({
              'is_favorite': isFavorite,
              'updated_at': DateTime.now().toUtc().toIso8601String(),
            })
            .eq(RelationColumns.id, relationId)
            .select(relationSelectColumns)
            .single();
        return ProfileRelationModel.fromSupabaseMap(response);
      },
      errorPrefix: '즐겨찾기 토글 실패',
    );
  }

  /// 정렬 순서 업데이트
  Future<QueryResult<void>> updateSortOrder(
    String relationId,
    int sortOrder,
  ) async {
    return safeMutation(
      mutation: (client) async {
        await client
            .from(profileRelationsTable)
            .update({
              'sort_order': sortOrder,
              'updated_at': DateTime.now().toUtc().toIso8601String(),
            })
            .eq(RelationColumns.id, relationId);
      },
      errorPrefix: '정렬 순서 업데이트 실패',
    );
  }

  /// 여러 관계의 정렬 순서 일괄 업데이트
  Future<QueryResult<void>> updateSortOrders(
    Map<String, int> relationSortOrders,
  ) async {
    return safeMutation(
      mutation: (client) async {
        final now = DateTime.now().toUtc().toIso8601String();

        for (final entry in relationSortOrders.entries) {
          await client
              .from(profileRelationsTable)
              .update({
                'sort_order': entry.value,
                'updated_at': now,
              })
              .eq(RelationColumns.id, entry.key);
        }
      },
      errorPrefix: '정렬 순서 일괄 업데이트 실패',
    );
  }

  /// 메모 업데이트
  Future<QueryResult<void>> updateMemo(
    String relationId,
    String? memo,
  ) async {
    return safeMutation(
      mutation: (client) async {
        await client
            .from(profileRelationsTable)
            .update({
              'memo': memo,
              'updated_at': DateTime.now().toUtc().toIso8601String(),
            })
            .eq(RelationColumns.id, relationId);
      },
      errorPrefix: '메모 업데이트 실패',
    );
  }

  /// 표시명 업데이트
  Future<QueryResult<void>> updateDisplayName(
    String relationId,
    String? displayName,
  ) async {
    return safeMutation(
      mutation: (client) async {
        await client
            .from(profileRelationsTable)
            .update({
              'display_name': displayName,
              'updated_at': DateTime.now().toUtc().toIso8601String(),
            })
            .eq(RelationColumns.id, relationId);
      },
      errorPrefix: '표시명 업데이트 실패',
    );
  }

  /// 프로필 ID로 관련 relation의 display_name 일괄 동기화
  ///
  /// saju_profiles 수정 시 profile_relations.display_name도 함께 갱신
  /// to_profile_id가 일치하는 모든 relation 업데이트
  Future<QueryResult<void>> syncDisplayNameByProfileId(
    String profileId,
    String displayName,
  ) async {
    return safeMutation(
      mutation: (client) async {
        await client
            .from(profileRelationsTable)
            .update({
              'display_name': displayName,
              'updated_at': DateTime.now().toUtc().toIso8601String(),
            })
            .eq('to_profile_id', profileId);
      },
      errorPrefix: '프로필 display_name 동기화 실패',
    );
  }

  /// 관계 유형 변경
  Future<QueryResult<ProfileRelationModel>> updateRelationType(
    String relationId,
    String relationType,
  ) async {
    return safeMutation(
      mutation: (client) async {
        final response = await client
            .from(profileRelationsTable)
            .update({
              'relation_type': relationType,
              'updated_at': DateTime.now().toUtc().toIso8601String(),
            })
            .eq(RelationColumns.id, relationId)
            .select(relationSelectColumns)
            .single();
        return ProfileRelationModel.fromSupabaseMap(response);
      },
      errorPrefix: '관계 유형 변경 실패',
    );
  }

  /// 특정 프로필의 모든 관계 삭제
  ///
  /// 1. 연결된 모든 compatibility_analyses 삭제
  /// 2. profile_relations 삭제
  /// 프로필 삭제 시 호출
  Future<QueryResult<void>> deleteAllByFromProfile(String fromProfileId) async {
    return safeMutation(
      mutation: (client) async {
        // 1. 먼저 모든 관계의 compatibility_analysis_id 조회
        final relations = await client
            .from(profileRelationsTable)
            .select('compatibility_analysis_id')
            .eq(RelationColumns.fromProfileId, fromProfileId);

        // 2. 연결된 궁합 분석들 삭제
        final analysisIds = (relations as List)
            .where((r) => r['compatibility_analysis_id'] != null)
            .map((r) => r['compatibility_analysis_id'] as String)
            .toList();

        if (analysisIds.isNotEmpty) {
          debugPrint('🗑️ [RelationMutations.deleteAllByFromProfile] 연결된 궁합 분석 ${analysisIds.length}개 삭제');
          await client
              .from('compatibility_analyses')
              .delete()
              .inFilter('id', analysisIds);
        }

        // 3. profile_relations 삭제
        await client
            .from(profileRelationsTable)
            .delete()
            .eq(RelationColumns.fromProfileId, fromProfileId);

        // 4. 삭제 검증
        final verifyResult = await client
            .from(profileRelationsTable)
            .select('id')
            .eq(RelationColumns.fromProfileId, fromProfileId);

        if ((verifyResult as List).isNotEmpty) {
          debugPrint('❌ [RelationMutations.deleteAllByFromProfile] 삭제 검증 실패: ${verifyResult.length}개 행 남아있음');
          throw Exception('전체 관계 삭제 실패: RLS 정책에 의해 일부 또는 전체가 차단되었습니다');
        }

        debugPrint('✅ [RelationMutations.deleteAllByFromProfile] 전체 관계 삭제 완료');
      },
      errorPrefix: '전체 관계 삭제 실패',
    );
  }

  /// Upsert (있으면 업데이트, 없으면 생성)
  Future<QueryResult<ProfileRelationModel>> upsert({
    required String userId,
    required String fromProfileId,
    required String toProfileId,
    required String relationType,
    String? displayName,
    String? memo,
    bool isFavorite = false,
    int sortOrder = 0,
  }) async {
    return safeMutation(
      mutation: (client) async {
        final data = {
          'user_id': userId,
          'from_profile_id': fromProfileId,
          'to_profile_id': toProfileId,
          'relation_type': relationType,
          'display_name': displayName,
          'memo': memo,
          'is_favorite': isFavorite,
          'sort_order': sortOrder,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        };

        final response = await client
            .from(profileRelationsTable)
            .upsert(
              data,
              onConflict: 'from_profile_id,to_profile_id',
            )
            .select(relationSelectColumns)
            .single();
        return ProfileRelationModel.fromSupabaseMap(response);
      },
      errorPrefix: '관계 Upsert 실패',
    );
  }

  // === 분석 상태 관련 ===

  /// 분석 상태 업데이트
  Future<QueryResult<ProfileRelationModel>> updateAnalysisStatus(
    String relationId,
    String status,
  ) async {
    return safeMutation(
      mutation: (client) async {
        final data = <String, dynamic>{
          'analysis_status': status,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        };

        // processing 상태면 요청 시간도 기록
        if (status == 'processing') {
          data['analysis_requested_at'] = DateTime.now().toUtc().toIso8601String();
        }

        final response = await client
            .from(profileRelationsTable)
            .update(data)
            .eq(RelationColumns.id, relationId)
            .select(relationSelectColumns)
            .single();
        return ProfileRelationModel.fromSupabaseMap(response);
      },
      errorPrefix: '분석 상태 업데이트 실패',
    );
  }

  /// 상대방(to_profile) 분석 ID 연결
  Future<QueryResult<ProfileRelationModel>> linkToProfileAnalysis(
    String relationId,
    String analysisId,
  ) async {
    return safeMutation(
      mutation: (client) async {
        final response = await client
            .from(profileRelationsTable)
            .update({
              'to_profile_analysis_id': analysisId,
              'analysis_status': 'completed',
              'updated_at': DateTime.now().toUtc().toIso8601String(),
            })
            .eq(RelationColumns.id, relationId)
            .select(relationSelectColumns)
            .single();
        return ProfileRelationModel.fromSupabaseMap(response);
      },
      errorPrefix: '상대방 분석 연결 실패',
    );
  }

  /// 나(from_profile) 분석 ID 연결
  Future<QueryResult<ProfileRelationModel>> linkFromProfileAnalysis(
    String relationId,
    String analysisId,
  ) async {
    return safeMutation(
      mutation: (client) async {
        final response = await client
            .from(profileRelationsTable)
            .update({
              'from_profile_analysis_id': analysisId,
              'updated_at': DateTime.now().toUtc().toIso8601String(),
            })
            .eq(RelationColumns.id, relationId)
            .select(relationSelectColumns)
            .single();
        return ProfileRelationModel.fromSupabaseMap(response);
      },
      errorPrefix: '나의 분석 연결 실패',
    );
  }

  /// 분석 요청 시작 (상태를 processing으로 변경)
  Future<QueryResult<ProfileRelationModel>> startAnalysis(
    String relationId,
  ) async {
    return updateAnalysisStatus(relationId, 'processing');
  }

  /// 분석 완료 (상태를 completed로 + 분석 ID 연결)
  Future<QueryResult<ProfileRelationModel>> completeAnalysis({
    required String relationId,
    required String toProfileAnalysisId,
    String? fromProfileAnalysisId,
  }) async {
    return safeMutation(
      mutation: (client) async {
        final data = <String, dynamic>{
          'to_profile_analysis_id': toProfileAnalysisId,
          'analysis_status': 'completed',
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        };

        if (fromProfileAnalysisId != null) {
          data['from_profile_analysis_id'] = fromProfileAnalysisId;
        }

        final response = await client
            .from(profileRelationsTable)
            .update(data)
            .eq(RelationColumns.id, relationId)
            .select(relationSelectColumns)
            .single();
        return ProfileRelationModel.fromSupabaseMap(response);
      },
      errorPrefix: '분석 완료 처리 실패',
    );
  }

  /// 분석 실패 처리
  Future<QueryResult<ProfileRelationModel>> failAnalysis(
    String relationId,
  ) async {
    return updateAnalysisStatus(relationId, 'failed');
  }
}

/// 싱글톤 인스턴스
const relationMutations = RelationMutations();
