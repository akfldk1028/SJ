import '../entities/saju_profile.dart';

/// 프로필 Repository 인터페이스
///
/// 프로필 데이터의 CRUD 작업을 정의
/// 실제 구현은 Data Layer에서 담당
abstract class ProfileRepository {
  /// 모든 프로필 조회
  ///
  /// 생성일시 역순으로 정렬하여 반환
  Future<List<SajuProfile>> getAll();

  /// 모든 프로필 조회 (Alias)
  Future<List<SajuProfile>> getAllProfiles();

  /// ID로 프로필 조회
  ///
  /// [id] 프로필 고유 ID
  /// 없으면 null 반환
  Future<SajuProfile?> getById(String id);

  /// 현재 활성화된 프로필 조회
  ///
  /// 활성 프로필이 없으면 null 반환
  Future<SajuProfile?> getActive();

  /// 현재 활성화된 프로필 조회 (Alias)
  Future<SajuProfile?> getActiveProfile();

  /// 프로필 저장
  ///
  /// [profile] 저장할 프로필
  /// 이미 존재하는 ID면 업데이트
  Future<void> save(SajuProfile profile);

  /// 프로필 저장 (Alias)
  Future<void> saveProfile(SajuProfile profile);

  /// 프로필 업데이트
  ///
  /// [profile] 업데이트할 프로필
  /// updatedAt 필드가 자동으로 갱신됨
  Future<void> update(SajuProfile profile);

  /// 프로필 삭제
  ///
  /// [id] 삭제할 프로필 ID
  /// 마지막 프로필은 삭제 불가 (최소 1개 유지)
  Future<void> delete(String id);

  /// 프로필 삭제 (Alias)
  Future<void> deleteProfile(String id);

  /// 활성 프로필 설정
  ///
  /// [id] 활성화할 프로필 ID
  /// 기존 활성 프로필은 자동으로 비활성화됨
  Future<void> setActive(String id);

  /// 프로필 개수 조회
  Future<int> count();

  /// 모든 프로필 삭제 (테스트용)
  Future<void> clear();
}
