import '../../../core/data/data.dart';
import 'models/saju_profile_model.dart';
import 'schema.dart';

/// Profile 쿼리 클래스
///
/// SELECT 작업 담당
/// 오프라인 모드 + 에러 처리 내장
class ProfileQueries extends BaseQueries {
  const ProfileQueries();

  /// 사용자의 모든 프로필 조회
  Future<QueryResult<List<SajuProfileModel>>> getAllByUserId(
    String userId,
  ) async {
    return safeListQuery(
      query: (client) async {
        final response = await client
            .from(profilesTable)
            .select(profileSelectColumns)
            .eq(ProfileColumns.userId, userId)
            .order(ProfileColumns.createdAt, ascending: false);
        return List<Map<String, dynamic>>.from(response);
      },
      fromJson: SajuProfileModel.fromSupabaseMap,
      errorPrefix: '프로필 목록 조회 실패',
    );
  }

  /// 프로필 ID로 단일 조회
  Future<QueryResult<SajuProfileModel?>> getById(String profileId) async {
    return safeSingleQuery(
      query: (client) async {
        final response = await client
            .from(profilesTable)
            .select(profileSelectColumns)
            .eq(ProfileColumns.id, profileId)
            .maybeSingle();
        return response;
      },
      fromJson: SajuProfileModel.fromSupabaseMap,
      errorPrefix: '프로필 조회 실패',
    );
  }

  /// 사용자의 기본(Primary) 프로필 조회
  Future<QueryResult<SajuProfileModel?>> getPrimaryByUserId(
    String userId,
  ) async {
    return safeSingleQuery(
      query: (client) async {
        final response = await client
            .from(profilesTable)
            .select(profileSelectColumns)
            .eq(ProfileColumns.userId, userId)
            .eq(ProfileColumns.isPrimary, true)
            .maybeSingle();
        return response;
      },
      fromJson: SajuProfileModel.fromSupabaseMap,
      errorPrefix: '기본 프로필 조회 실패',
    );
  }

  /// 특정 관계 유형의 프로필 목록 조회
  Future<QueryResult<List<SajuProfileModel>>> getByRelationType(
    String userId,
    String relationType,
  ) async {
    return safeListQuery(
      query: (client) async {
        final response = await client
            .from(profilesTable)
            .select(profileSelectColumns)
            .eq(ProfileColumns.userId, userId)
            .eq(ProfileColumns.relationType, relationType)
            .order(ProfileColumns.createdAt, ascending: false);
        return List<Map<String, dynamic>>.from(response);
      },
      fromJson: SajuProfileModel.fromSupabaseMap,
      errorPrefix: '관계 유형별 프로필 조회 실패',
    );
  }

  /// 프로필 개수 조회
  Future<QueryResult<int>> countByUserId(String userId) async {
    return safeQuery(
      query: (client) async {
        final response = await client
            .from(profilesTable)
            .select()
            .eq(ProfileColumns.userId, userId)
            .count();
        return response.count;
      },
      errorPrefix: '프로필 개수 조회 실패',
    );
  }

  /// 프로필 존재 여부 확인
  Future<QueryResult<bool>> exists(String profileId) async {
    return safeQuery(
      query: (client) async {
        final response = await client
            .from(profilesTable)
            .select(ProfileColumns.id)
            .eq(ProfileColumns.id, profileId)
            .maybeSingle();
        return response != null;
      },
      errorPrefix: '프로필 존재 확인 실패',
    );
  }

  /// 최근 업데이트된 프로필 조회
  Future<QueryResult<List<SajuProfileModel>>> getRecentlyUpdated(
    String userId, {
    int limit = 5,
  }) async {
    return safeListQuery(
      query: (client) async {
        final response = await client
            .from(profilesTable)
            .select(profileSelectColumns)
            .eq(ProfileColumns.userId, userId)
            .order(ProfileColumns.updatedAt, ascending: false)
            .limit(limit);
        return List<Map<String, dynamic>>.from(response);
      },
      fromJson: SajuProfileModel.fromSupabaseMap,
      errorPrefix: '최근 프로필 조회 실패',
    );
  }
}

/// 싱글톤 인스턴스
const profileQueries = ProfileQueries();
