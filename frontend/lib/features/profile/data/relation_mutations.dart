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
        };

        final response = await client
            .from(profileRelationsTable)
            .insert(data)
            .select(relationSelectColumns)
            .single();
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

  /// 관계 삭제
  Future<QueryResult<void>> delete(String relationId) async {
    return safeMutation(
      mutation: (client) async {
        await client
            .from(profileRelationsTable)
            .delete()
            .eq(RelationColumns.id, relationId);
      },
      errorPrefix: '관계 삭제 실패',
    );
  }

  /// 두 프로필 간 관계 삭제
  Future<QueryResult<void>> deleteByProfilePair(
    String fromProfileId,
    String toProfileId,
  ) async {
    return safeMutation(
      mutation: (client) async {
        await client
            .from(profileRelationsTable)
            .delete()
            .eq(RelationColumns.fromProfileId, fromProfileId)
            .eq(RelationColumns.toProfileId, toProfileId);
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
  /// 프로필 삭제 시 호출 (CASCADE로 처리되지만 명시적으로도 가능)
  Future<QueryResult<void>> deleteAllByFromProfile(String fromProfileId) async {
    return safeMutation(
      mutation: (client) async {
        await client
            .from(profileRelationsTable)
            .delete()
            .eq(RelationColumns.fromProfileId, fromProfileId);
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
