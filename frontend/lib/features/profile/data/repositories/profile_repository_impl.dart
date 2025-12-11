import '../../domain/entities/saju_profile.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/profile_local_datasource.dart';
import '../models/saju_profile_model.dart';
import '../../../../core/repositories/saju_profile_repository.dart';
import '../../../../core/services/auth_service.dart';

/// 프로필 Repository 구현체
///
/// Local-First + Cloud Sync 패턴:
/// - Hive(로컬): 빠른 응답, 오프라인 지원
/// - Supabase(클라우드): 데이터 백업, 기기 간 동기화
class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileLocalDatasource _localDatasource;
  final SajuProfileRepository _supabaseRepository;
  final AuthService _authService;

  ProfileRepositoryImpl(this._localDatasource)
      : _supabaseRepository = SajuProfileRepository(),
        _authService = AuthService();

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

    // 1. 로컬 저장 (Hive) - 즉시 응답
    await _localDatasource.save(model);

    // 2. 새 프로필이 활성화 상태면 다른 프로필들 비활성화
    if (profile.isActive) {
      await _localDatasource.setActive(profile.id);
      print('[ProfileRepo] 새 프로필 활성화: ${profile.id}');
    }

    // 3. 클라우드 저장 (Supabase) - 비동기 백업
    await _syncToSupabase(profile, isNew: true);
  }

  @override
  Future<void> saveProfile(SajuProfile profile) async {
    await save(profile);
  }

  /// Supabase 동기화 (에러 발생해도 로컬 저장은 유지)
  Future<void> _syncToSupabase(SajuProfile profile, {required bool isNew}) async {
    try {
      // 로그인 상태 확인
      if (!_authService.isLoggedIn) {
        print('[ProfileRepo] Supabase 동기화 스킵: 로그인되지 않음');
        return;
      }

      if (isNew) {
        await _supabaseRepository.create(profile);
        print('[ProfileRepo] Supabase 프로필 생성 완료: ${profile.id}');
      } else {
        await _supabaseRepository.update(profile);
        print('[ProfileRepo] Supabase 프로필 업데이트 완료: ${profile.id}');
      }
    } catch (e) {
      // 클라우드 저장 실패해도 로컬 데이터는 유지
      print('[ProfileRepo] Supabase 동기화 실패 (로컬은 저장됨): $e');
    }
  }

  @override
  Future<void> update(SajuProfile profile) async {
    // updatedAt 자동 갱신
    final updatedProfile = profile.copyWith(
      updatedAt: DateTime.now(),
    );
    final model = SajuProfileModel.fromEntity(updatedProfile);

    // 1. 로컬 업데이트 (Hive)
    await _localDatasource.update(model);

    // 2. 클라우드 업데이트 (Supabase)
    await _syncToSupabase(updatedProfile, isNew: false);
  }

  @override
  Future<void> delete(String id) async {
    // 마지막 프로필 삭제 방지
    final count = await _localDatasource.count();
    if (count <= 1) {
      throw Exception('최소 1개의 프로필이 필요합니다.');
    }

    // 1. 로컬 삭제 (Hive)
    await _localDatasource.delete(id);

    // 2. 클라우드 삭제 (Supabase)
    await _deleteFromSupabase(id);

    // 삭제된 프로필이 활성 프로필이었다면 다른 프로필 활성화
    final activeProfile = await _localDatasource.getActive();
    if (activeProfile == null) {
      final profiles = await _localDatasource.getAll();
      if (profiles.isNotEmpty) {
        await _localDatasource.setActive(profiles.first.id);
      }
    }
  }

  /// Supabase에서 삭제
  Future<void> _deleteFromSupabase(String id) async {
    try {
      if (!_authService.isLoggedIn) {
        print('[ProfileRepo] Supabase 삭제 스킵: 로그인되지 않음');
        return;
      }

      await _supabaseRepository.delete(id);
      print('[ProfileRepo] Supabase 프로필 삭제 완료: $id');
    } catch (e) {
      print('[ProfileRepo] Supabase 삭제 실패 (로컬은 삭제됨): $e');
    }
  }

  @override
  Future<void> deleteProfile(String id) async {
    await delete(id);
  }

  @override
  Future<void> setActive(String id) async {
    // 1. 로컬 활성화 (Hive)
    await _localDatasource.setActive(id);

    // 2. 클라우드 활성화 (Supabase) - is_primary 설정
    try {
      if (_authService.isLoggedIn) {
        await _supabaseRepository.setPrimary(id);
        print('[ProfileRepo] Supabase 대표 프로필 설정 완료: $id');
      }
    } catch (e) {
      print('[ProfileRepo] Supabase 대표 프로필 설정 실패: $e');
    }
  }

  @override
  Future<int> count() async {
    return await _localDatasource.count();
  }

  @override
  Future<void> clear() async {
    await _localDatasource.clear();
  }

  // ============================================================
  // 클라우드 동기화 (앱 시작 시 호출 권장)
  // ============================================================

  /// 클라우드에서 프로필 동기화 (Cloud → Local)
  ///
  /// 앱 시작 시 호출하여 다른 기기에서 저장한 프로필을 로컬로 가져옴
  /// 동기화 전략: Cloud가 Source of Truth (클라우드 우선)
  Future<void> syncFromCloud() async {
    try {
      if (!_authService.isLoggedIn) {
        print('[ProfileRepo] 동기화 스킵: 로그인되지 않음');
        return;
      }

      // 클라우드에서 프로필 가져오기
      final cloudProfiles = await _supabaseRepository.getAll();
      print('[ProfileRepo] 클라우드 프로필 수: ${cloudProfiles.length}');

      if (cloudProfiles.isEmpty) {
        print('[ProfileRepo] 클라우드에 프로필 없음 - 동기화 스킵');
        return;
      }

      // 로컬 프로필과 병합
      final localProfiles = await _localDatasource.getAll();
      final localIds = localProfiles.map((p) => p.id).toSet();

      for (final cloudProfile in cloudProfiles) {
        if (!localIds.contains(cloudProfile.id)) {
          // 클라우드에만 있는 프로필 → 로컬에 추가
          final model = SajuProfileModel.fromEntity(cloudProfile);
          await _localDatasource.save(model);
          print('[ProfileRepo] 클라우드 → 로컬 동기화: ${cloudProfile.displayName}');
        }
      }

      // 대표 프로필 동기화
      final cloudPrimary = await _supabaseRepository.getPrimary();
      if (cloudPrimary != null) {
        await _localDatasource.setActive(cloudPrimary.id);
        print('[ProfileRepo] 대표 프로필 동기화: ${cloudPrimary.displayName}');
      }

      print('[ProfileRepo] 클라우드 동기화 완료');
    } catch (e) {
      print('[ProfileRepo] 클라우드 동기화 실패: $e');
    }
  }

  /// 로컬 프로필을 클라우드로 업로드 (Local → Cloud)
  ///
  /// 오프라인에서 생성한 프로필을 클라우드에 업로드
  Future<void> syncToCloud() async {
    try {
      if (!_authService.isLoggedIn) {
        print('[ProfileRepo] 업로드 스킵: 로그인되지 않음');
        return;
      }

      final localProfiles = await _localDatasource.getAll();
      final cloudProfiles = await _supabaseRepository.getAll();
      final cloudIds = cloudProfiles.map((p) => p.id).toSet();

      for (final localModel in localProfiles) {
        final localProfile = localModel.toEntity();
        if (!cloudIds.contains(localProfile.id)) {
          // 로컬에만 있는 프로필 → 클라우드에 업로드
          await _supabaseRepository.create(localProfile);
          print('[ProfileRepo] 로컬 → 클라우드 업로드: ${localProfile.displayName}');
        }
      }

      print('[ProfileRepo] 클라우드 업로드 완료');
    } catch (e) {
      print('[ProfileRepo] 클라우드 업로드 실패: $e');
    }
  }
}
