import '../../../core/data/data.dart';
import '../../profile/data/schema.dart' as profile_schema;

/// Splash Mutation 클래스
///
/// Pre-fetch 관련 쓰기 작업 담당
/// - 주로 동기화 상태 업데이트
/// - 캐시 관련 작업
///
/// 참고: Splash에서 직접적인 데이터 생성/수정은 거의 없음
/// 실제 데이터 생성은 각 feature의 mutations에서 처리
class SplashMutations extends BaseMutations {
  const SplashMutations();

  /// Primary 프로필 업데이트 (last_synced_at 갱신)
  ///
  /// 동기화 완료 시 호출
  Future<QueryResult<void>> markSynced(String profileId) async {
    return safeMutation(
      mutation: (client) async {
        await client
            .from(profile_schema.profilesTable)
            .update({
              profile_schema.ProfileColumns.updatedAt: DateTime.now().toIso8601String(),
            })
            .eq(profile_schema.ProfileColumns.id, profileId);
      },
      errorPrefix: '동기화 상태 업데이트 실패',
    );
  }

  /// 사용자의 Primary 프로필 설정
  ///
  /// 기존 Primary 해제 후 새로운 Primary 설정
  /// 최초 프로필 생성 시 또는 Primary 변경 시 사용
  Future<QueryResult<void>> ensurePrimaryProfile(
    String userId,
    String profileId,
  ) async {
    return safeMutation(
      mutation: (client) async {
        // 1. 기존 Primary 해제
        await client
            .from(profile_schema.profilesTable)
            .update({profile_schema.ProfileColumns.isPrimary: false})
            .eq(profile_schema.ProfileColumns.userId, userId)
            .eq(profile_schema.ProfileColumns.isPrimary, true);

        // 2. 새 Primary 설정
        await client
            .from(profile_schema.profilesTable)
            .update({profile_schema.ProfileColumns.isPrimary: true})
            .eq(profile_schema.ProfileColumns.id, profileId);
      },
      errorPrefix: 'Primary 프로필 설정 실패',
    );
  }

  /// 첫 프로필이면 자동으로 Primary 설정
  ///
  /// Onboarding 완료 후 호출
  Future<QueryResult<bool>> setFirstProfileAsPrimary(String userId) async {
    return safeMutation(
      mutation: (client) async {
        // 프로필 개수 확인
        final countResponse = await client
            .from(profile_schema.profilesTable)
            .select()
            .eq(profile_schema.ProfileColumns.userId, userId)
            .count();

        if (countResponse.count == 1) {
          // 첫 번째 프로필이면 Primary 설정
          await client
              .from(profile_schema.profilesTable)
              .update({profile_schema.ProfileColumns.isPrimary: true})
              .eq(profile_schema.ProfileColumns.userId, userId);
          return true;
        }
        return false;
      },
      errorPrefix: '첫 프로필 Primary 설정 실패',
    );
  }

  /// 프로필과 분석 데이터 동기화 확인
  ///
  /// Hive 캐시와 Supabase 데이터 비교 후 업데이트
  /// Returns: 업데이트 필요 여부
  Future<QueryResult<SyncCheckResult>> checkSyncNeeded(
    String profileId,
    DateTime? localUpdatedAt,
  ) async {
    return safeQuery(
      query: (client) async {
        final response = await client
            .from(profile_schema.profilesTable)
            .select(profile_schema.ProfileColumns.updatedAt)
            .eq(profile_schema.ProfileColumns.id, profileId)
            .maybeSingle();

        if (response == null) {
          return SyncCheckResult.notFound;
        }

        final remoteUpdatedAtStr = response[profile_schema.ProfileColumns.updatedAt] as String?;
        if (remoteUpdatedAtStr == null) {
          return SyncCheckResult.syncNeeded;
        }

        final remoteUpdatedAt = DateTime.parse(remoteUpdatedAtStr);

        if (localUpdatedAt == null) {
          return SyncCheckResult.syncNeeded;
        }

        if (remoteUpdatedAt.isAfter(localUpdatedAt)) {
          return SyncCheckResult.syncNeeded;
        }

        return SyncCheckResult.upToDate;
      },
      errorPrefix: '동기화 확인 실패',
    );
  }
}

// ============================================================================
// 동기화 결과 타입
// ============================================================================

/// 동기화 확인 결과
enum SyncCheckResult {
  /// 최신 상태
  upToDate,

  /// 동기화 필요
  syncNeeded,

  /// 원격에 데이터 없음
  notFound,

  /// 확인 실패
  error,
}

/// 싱글톤 인스턴스
const splashMutations = SplashMutations();
