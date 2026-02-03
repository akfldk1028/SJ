import '../../../core/data/data.dart';
import 'models/saju_profile_model.dart';
import 'schema.dart';

/// Profile 뮤테이션 클래스
///
/// INSERT, UPDATE, DELETE 작업 담당
/// 오프라인 모드에서는 실패 반환
class ProfileMutations extends BaseMutations {
  const ProfileMutations();

  /// 프로필 생성
  Future<QueryResult<SajuProfileModel>> create(
    SajuProfileModel profile,
    String userId,
  ) async {
    return safeMutation(
      mutation: (client) async {
        final data = profile.toSupabaseMap(userId);
        final response = await client
            .from(profilesTable)
            .insert(data)
            .select(profileSelectColumns)
            .single();
        return SajuProfileModel.fromSupabaseMap(response);
      },
      errorPrefix: '프로필 생성 실패',
    );
  }

  /// 프로필 업데이트
  Future<QueryResult<SajuProfileModel>> update(
    SajuProfileModel profile,
    String userId,
  ) async {
    return safeMutation(
      mutation: (client) async {
        final data = profile.toSupabaseMap(userId);
        data.remove('id'); // id는 업데이트하지 않음
        data.remove('created_at'); // 생성일은 유지
        data['updated_at'] = DateTime.now().toUtc().toIso8601String();

        final response = await client
            .from(profilesTable)
            .update(data)
            .eq(ProfileColumns.id, profile.id)
            .select(profileSelectColumns)
            .single();
        return SajuProfileModel.fromSupabaseMap(response);
      },
      errorPrefix: '프로필 업데이트 실패',
    );
  }

  /// 프로필 삭제
  Future<QueryResult<void>> delete(String profileId) async {
    return safeMutation(
      mutation: (client) async {
        await client
            .from(profilesTable)
            .delete()
            .eq(ProfileColumns.id, profileId);
      },
      errorPrefix: '프로필 삭제 실패',
    );
  }

  /// Primary 프로필 설정
  ///
  /// 기존 Primary 해제 후 새로운 프로필을 Primary로 설정
  Future<QueryResult<void>> setPrimary(
    String profileId,
    String userId,
  ) async {
    return safeMutation(
      mutation: (client) async {
        // 트랜잭션처럼 동작 (RPC 함수 사용 권장이지만 일단 순차 실행)

        // 1. 기존 Primary 해제
        await client
            .from(profilesTable)
            .update({ProfileColumns.profileType: 'other'})
            .eq(ProfileColumns.userId, userId)
            .eq(ProfileColumns.profileType, 'primary');

        // 2. 새 프로필 Primary 설정
        await client
            .from(profilesTable)
            .update({
              ProfileColumns.profileType: 'primary',
              ProfileColumns.updatedAt: DateTime.now().toUtc().toIso8601String(),
            })
            .eq(ProfileColumns.id, profileId);
      },
      errorPrefix: 'Primary 프로필 설정 실패',
    );
  }

  /// 프로필 부분 업데이트
  Future<QueryResult<SajuProfileModel>> patch(
    String profileId,
    Map<String, dynamic> updates,
  ) async {
    return safeMutation(
      mutation: (client) async {
        updates['updated_at'] = DateTime.now().toUtc().toIso8601String();

        final response = await client
            .from(profilesTable)
            .update(updates)
            .eq(ProfileColumns.id, profileId)
            .select(profileSelectColumns)
            .single();
        return SajuProfileModel.fromSupabaseMap(response);
      },
      errorPrefix: '프로필 부분 업데이트 실패',
    );
  }

  /// Upsert (있으면 업데이트, 없으면 생성)
  Future<QueryResult<SajuProfileModel>> upsert(
    SajuProfileModel profile,
    String userId,
  ) async {
    return safeMutation(
      mutation: (client) async {
        final data = profile.toSupabaseMap(userId);

        final response = await client
            .from(profilesTable)
            .upsert(data)
            .select(profileSelectColumns)
            .single();
        return SajuProfileModel.fromSupabaseMap(response);
      },
      errorPrefix: '프로필 Upsert 실패',
    );
  }

  /// 여러 프로필 일괄 삭제
  Future<QueryResult<void>> deleteMany(List<String> profileIds) async {
    return safeMutation(
      mutation: (client) async {
        await client
            .from(profilesTable)
            .delete()
            .inFilter(ProfileColumns.id, profileIds);
      },
      errorPrefix: '프로필 일괄 삭제 실패',
    );
  }

  /// 메모 업데이트
  Future<QueryResult<void>> updateMemo(
    String profileId,
    String? memo,
  ) async {
    return safeMutation(
      mutation: (client) async {
        await client
            .from(profilesTable)
            .update({
              ProfileColumns.memo: memo,
              ProfileColumns.updatedAt: DateTime.now().toUtc().toIso8601String(),
            })
            .eq(ProfileColumns.id, profileId);
      },
      errorPrefix: '메모 업데이트 실패',
    );
  }
}

/// 싱글톤 인스턴스
const profileMutations = ProfileMutations();
