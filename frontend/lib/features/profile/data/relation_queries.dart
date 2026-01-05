import '../../../core/data/data.dart';
import 'models/profile_relation_model.dart';
import 'relation_schema.dart';

/// Profile Relations 쿼리 클래스
///
/// SELECT 작업 담당
/// 오프라인 모드 + 에러 처리 내장
class RelationQueries extends BaseQueries {
  const RelationQueries();

  /// 특정 프로필과 연관된 모든 관계 조회
  ///
  /// [fromProfileId]가 "나"인 경우, 나와 연결된 모든 사람들 조회
  Future<QueryResult<List<ProfileRelationModel>>> getByFromProfile(
    String fromProfileId,
  ) async {
    return safeListQuery(
      query: (client) async {
        final response = await client
            .from(profileRelationsTable)
            .select(relationWithProfileSelectColumns)
            .eq(RelationColumns.fromProfileId, fromProfileId)
            .order(RelationColumns.sortOrder, ascending: true)
            .order(RelationColumns.createdAt, ascending: false);
        return List<Map<String, dynamic>>.from(response);
      },
      fromJson: ProfileRelationModel.fromSupabaseMap,
      errorPrefix: '관계 목록 조회 실패',
    );
  }

  /// 사용자의 모든 관계 조회
  Future<QueryResult<List<ProfileRelationModel>>> getAllByUserId(
    String userId,
  ) async {
    return safeListQuery(
      query: (client) async {
        final response = await client
            .from(profileRelationsTable)
            .select(relationWithProfileSelectColumns)
            .eq(RelationColumns.userId, userId)
            .order(RelationColumns.sortOrder, ascending: true)
            .order(RelationColumns.createdAt, ascending: false);
        return List<Map<String, dynamic>>.from(response);
      },
      fromJson: ProfileRelationModel.fromSupabaseMap,
      errorPrefix: '전체 관계 목록 조회 실패',
    );
  }

  /// 관계 ID로 단일 조회
  Future<QueryResult<ProfileRelationModel?>> getById(String relationId) async {
    return safeSingleQuery(
      query: (client) async {
        final response = await client
            .from(profileRelationsTable)
            .select(relationWithProfileSelectColumns)
            .eq(RelationColumns.id, relationId)
            .maybeSingle();
        return response;
      },
      fromJson: ProfileRelationModel.fromSupabaseMap,
      errorPrefix: '관계 조회 실패',
    );
  }

  /// 두 프로필 간 관계 조회
  Future<QueryResult<ProfileRelationModel?>> getByProfilePair(
    String fromProfileId,
    String toProfileId,
  ) async {
    return safeSingleQuery(
      query: (client) async {
        final response = await client
            .from(profileRelationsTable)
            .select(relationWithProfileSelectColumns)
            .eq(RelationColumns.fromProfileId, fromProfileId)
            .eq(RelationColumns.toProfileId, toProfileId)
            .maybeSingle();
        return response;
      },
      fromJson: ProfileRelationModel.fromSupabaseMap,
      errorPrefix: '프로필 간 관계 조회 실패',
    );
  }

  /// 특정 관계 유형의 관계 목록 조회
  Future<QueryResult<List<ProfileRelationModel>>> getByRelationType(
    String fromProfileId,
    String relationType,
  ) async {
    return safeListQuery(
      query: (client) async {
        final response = await client
            .from(profileRelationsTable)
            .select(relationWithProfileSelectColumns)
            .eq(RelationColumns.fromProfileId, fromProfileId)
            .eq(RelationColumns.relationType, relationType)
            .order(RelationColumns.sortOrder, ascending: true);
        return List<Map<String, dynamic>>.from(response);
      },
      fromJson: ProfileRelationModel.fromSupabaseMap,
      errorPrefix: '관계 유형별 조회 실패',
    );
  }

  /// 카테고리별 관계 조회 (family_*, romantic_*, friend_*, work_*)
  Future<QueryResult<List<ProfileRelationModel>>> getByCategory(
    String fromProfileId,
    String categoryPrefix,
  ) async {
    return safeListQuery(
      query: (client) async {
        final response = await client
            .from(profileRelationsTable)
            .select(relationWithProfileSelectColumns)
            .eq(RelationColumns.fromProfileId, fromProfileId)
            .like(RelationColumns.relationType, '$categoryPrefix%')
            .order(RelationColumns.sortOrder, ascending: true);
        return List<Map<String, dynamic>>.from(response);
      },
      fromJson: ProfileRelationModel.fromSupabaseMap,
      errorPrefix: '카테고리별 관계 조회 실패',
    );
  }

  /// 즐겨찾기 관계 조회
  Future<QueryResult<List<ProfileRelationModel>>> getFavorites(
    String fromProfileId,
  ) async {
    return safeListQuery(
      query: (client) async {
        final response = await client
            .from(profileRelationsTable)
            .select(relationWithProfileSelectColumns)
            .eq(RelationColumns.fromProfileId, fromProfileId)
            .eq(RelationColumns.isFavorite, true)
            .order(RelationColumns.sortOrder, ascending: true);
        return List<Map<String, dynamic>>.from(response);
      },
      fromJson: ProfileRelationModel.fromSupabaseMap,
      errorPrefix: '즐겨찾기 관계 조회 실패',
    );
  }

  /// 관계 개수 조회
  Future<QueryResult<int>> countByFromProfile(String fromProfileId) async {
    return safeQuery(
      query: (client) async {
        final response = await client
            .from(profileRelationsTable)
            .select()
            .eq(RelationColumns.fromProfileId, fromProfileId)
            .count();
        return response.count;
      },
      errorPrefix: '관계 개수 조회 실패',
    );
  }

  /// 관계 존재 여부 확인
  Future<QueryResult<bool>> exists(
    String fromProfileId,
    String toProfileId,
  ) async {
    return safeQuery(
      query: (client) async {
        final response = await client
            .from(profileRelationsTable)
            .select(RelationColumns.id)
            .eq(RelationColumns.fromProfileId, fromProfileId)
            .eq(RelationColumns.toProfileId, toProfileId)
            .maybeSingle();
        return response != null;
      },
      errorPrefix: '관계 존재 확인 실패',
    );
  }

  /// 카테고리별 그룹핑된 관계 조회
  ///
  /// 반환: Map<카테고리, List<관계>>
  Future<QueryResult<Map<String, List<ProfileRelationModel>>>>
      getGroupedByCategory(String fromProfileId) async {
    final result = await getByFromProfile(fromProfileId);

    if (result.isFailure) {
      return QueryResult.failure(result.errorMessage ?? '알 수 없는 오류');
    }

    final grouped = <String, List<ProfileRelationModel>>{};
    for (final relation in result.data!) {
      final category = relation.categoryLabel;
      grouped.putIfAbsent(category, () => []).add(relation);
    }

    return QueryResult.success(grouped);
  }
}

/// 싱글톤 인스턴스
const relationQueries = RelationQueries();
