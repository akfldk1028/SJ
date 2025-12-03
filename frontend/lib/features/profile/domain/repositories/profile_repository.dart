import '../entities/saju_profile.dart';

/// Profile Repository Interface
///
/// 주의: abstract class로 정의!
/// 구현은 data/repositories/에서
/// Flutter/Supabase import 금지!
abstract class ProfileRepository {
  /// 프로필 목록 조회
  Future<List<SajuProfile>> getProfiles();

  /// 프로필 단건 조회
  Future<SajuProfile?> getProfileById(String id);

  /// 활성 프로필 조회
  Future<SajuProfile?> getActiveProfile();

  /// 프로필 생성
  Future<SajuProfile> createProfile(SajuProfile profile);

  /// 프로필 수정
  Future<SajuProfile> updateProfile(SajuProfile profile);

  /// 프로필 삭제
  Future<void> deleteProfile(String id);

  /// 활성 프로필 설정
  Future<void> setActiveProfile(String id);

  /// 프로필 개수 조회
  Future<int> getProfileCount();
}
