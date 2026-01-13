import '../../../../core/services/supabase_service.dart';
import '../../domain/entities/saju_profile.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/profile_local_datasource.dart';
import '../models/saju_profile_model.dart';

/// 프로필 Repository 구현체
///
/// LocalDataSource를 사용하여 프로필 관리
class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileLocalDatasource _localDatasource;

  ProfileRepositoryImpl(this._localDatasource);

  @override
  Future<List<SajuProfile>> getAll() async {
    final models = await _localDatasource.getAll();
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<List<SajuProfile>> getAllProfiles() async {
    return getAll();
  }

  @override
  Future<SajuProfile?> getById(String id) async {
    final model = await _localDatasource.getById(id);
    return model?.toEntity();
  }

  @override
  Future<SajuProfile?> getActive() async {
    final model = await _localDatasource.getActive();
    return model?.toEntity();
  }

  @override
  Future<SajuProfile?> getActiveProfile() async {
    return getActive();
  }

  @override
  Future<void> save(SajuProfile profile) async {
    final model = SajuProfileModel.fromEntity(profile);

    // 1. Hive에 저장 (로컬 우선)
    await _localDatasource.save(model);

    // 2. Supabase에 저장 (완료 대기 - RLS 정책이 프로필 존재 확인하므로)
    await _saveToSupabase(model);
  }

  /// Supabase에 프로필 저장 (비동기, 실패 시 throw)
  ///
  /// Phase 45: 인연 추가 시 FK 제약 문제 해결을 위해
  /// Supabase 저장 실패 시 에러를 throw하도록 변경
  Future<void> _saveToSupabase(SajuProfileModel model) async {
    _log('🔍 _saveToSupabase 시작: ${model.id}');

    try {
      // 익명 인증 확인
      final user = await SupabaseService.ensureAuthenticated();
      if (user == null) {
        _log('❌ Supabase 인증 실패: user is null');
        throw Exception('Supabase 인증이 필요합니다');
      }
      _log('   - user.id: ${user.id}');

      final table = SupabaseService.sajuProfilesTable;
      if (table == null) {
        _log('❌ sajuProfilesTable is null');
        throw Exception('Supabase 테이블을 사용할 수 없습니다');
      }

      final data = model.toSupabaseMap(user.id);
      _log('   - upsert 데이터: $data');

      await table.upsert(data);
      _log('✅ Profile saved to Supabase: ${model.id}');
    } catch (e) {
      _log('❌ Failed to save profile to Supabase: $e');
      // Phase 45: FK 제약 문제로 인해 에러를 throw
      rethrow;
    }
  }

  void _log(String message) {
    // ignore: avoid_print
    print('[ProfileRepository] $message');
  }

  @override
  Future<void> saveProfile(SajuProfile profile) async {
    await save(profile);
  }

  @override
  Future<void> update(SajuProfile profile) async {
    // updatedAt 자동 갱신
    final updatedProfile = profile.copyWith(
      updatedAt: DateTime.now(),
    );
    final model = SajuProfileModel.fromEntity(updatedProfile);

    // 1. Hive 업데이트
    await _localDatasource.update(model);

    // 2. Supabase 업데이트 (완료 대기 - RLS 정책이 프로필 존재 확인하므로)
    await _saveToSupabase(model);
  }

  @override
  Future<void> delete(String id) async {
    // 마지막 프로필 삭제 방지
    final count = await _localDatasource.count();
    if (count <= 1) {
      throw Exception('최소 1개의 프로필이 필요합니다.');
    }

    // 1. Hive에서 삭제
    await _localDatasource.delete(id);

    // 삭제된 프로필이 활성 프로필이었다면 다른 프로필 활성화
    final activeProfile = await _localDatasource.getActive();
    if (activeProfile == null) {
      final profiles = await _localDatasource.getAll();
      if (profiles.isNotEmpty) {
        await _localDatasource.setActive(profiles.first.id);
      }
    }

    // 2. Supabase에서 삭제 (백그라운드)
    _deleteFromSupabase(id);
  }

  /// Supabase에서 프로필 삭제 (비동기, 실패 무시)
  Future<void> _deleteFromSupabase(String id) async {
    try {
      final userId = SupabaseService.currentUserId;
      if (userId == null) return;

      final table = SupabaseService.sajuProfilesTable;
      if (table == null) return;

      await table.delete().eq('id', id).eq('user_id', userId);
      _log('Profile deleted from Supabase: $id');
    } catch (e) {
      _log('Failed to delete profile from Supabase: $e');
    }
  }

  @override
  Future<void> deleteProfile(String id) async {
    await delete(id);
  }

  @override
  Future<void> setActive(String id) async {
    await _localDatasource.setActive(id);
  }

  @override
  Future<int> count() async {
    return await _localDatasource.count();
  }

  @override
  Future<void> clear() async {
    await _localDatasource.clear();
  }

  @override
  Future<void> syncFromCloud() async {
    try {
      final userId = SupabaseService.currentUserId;
      if (userId == null) {
        _log('No user logged in, skipping cloud sync');
        return;
      }

      final table = SupabaseService.sajuProfilesTable;
      if (table == null) return;

      final response = await table.select().eq('user_id', userId);

      for (final data in response as List) {
        final model = SajuProfileModel.fromSupabaseMap(data);
        // 로컬에 없는 경우에만 저장
        final existing = await _localDatasource.getById(model.id);
        if (existing == null) {
          await _localDatasource.save(model);
          _log('Synced profile from cloud: ${model.id}');
        }
      }
    } catch (e) {
      _log('Failed to sync from cloud: $e');
    }
  }

  @override
  Future<void> syncToCloud() async {
    try {
      final user = await SupabaseService.ensureAuthenticated();
      if (user == null) {
        _log('No user authenticated, skipping cloud sync');
        return;
      }

      final profiles = await _localDatasource.getAll();
      for (final model in profiles) {
        await _saveToSupabase(model);
      }
      _log('All profiles synced to cloud');
    } catch (e) {
      _log('Failed to sync to cloud: $e');
    }
  }
}
