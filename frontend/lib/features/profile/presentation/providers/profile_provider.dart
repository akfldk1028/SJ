import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/providers/supabase_provider.dart';
import '../../data/datasources/profile_remote_datasource.dart';
import '../../data/repositories/profile_repository_impl.dart';
import '../../domain/entities/saju_profile.dart';
import '../../domain/repositories/profile_repository.dart';

part 'profile_provider.g.dart';

/// Profile Repository Provider
/// DI: DataSource -> Repository 연결
@riverpod
ProfileRepository profileRepository(ProfileRepositoryRef ref) {
  final client = ref.watch(supabaseClientProvider);
  final dataSource = ProfileRemoteDataSource(client);
  return ProfileRepositoryImpl(dataSource);
}

/// Profile List Provider
/// 프로필 목록 관리 (CRUD)
@riverpod
class ProfileList extends _$ProfileList {
  @override
  Future<List<SajuProfile>> build() async {
    final repository = ref.watch(profileRepositoryProvider);
    return repository.getProfiles();
  }

  /// 프로필 추가
  Future<SajuProfile> addProfile(SajuProfile profile) async {
    final repository = ref.read(profileRepositoryProvider);
    final created = await repository.createProfile(profile);

    // 첫 번째 프로필이면 자동으로 활성화
    final currentProfiles = state.valueOrNull ?? [];
    if (currentProfiles.isEmpty) {
      await repository.setActiveProfile(created.id);
    }

    ref.invalidateSelf();
    await future;

    return created;
  }

  /// 프로필 수정
  Future<SajuProfile> updateProfile(SajuProfile profile) async {
    final repository = ref.read(profileRepositoryProvider);
    final updated = await repository.updateProfile(profile);

    ref.invalidateSelf();
    await future;

    return updated;
  }

  /// 프로필 삭제
  Future<bool> deleteProfile(String id) async {
    final repository = ref.read(profileRepositoryProvider);

    // 최소 1개 프로필 필요
    final count = await repository.getProfileCount();
    if (count <= 1) {
      return false;
    }

    await repository.deleteProfile(id);

    ref.invalidateSelf();
    await future;

    return true;
  }

  /// 활성 프로필 설정
  Future<void> setActiveProfile(String id) async {
    final repository = ref.read(profileRepositoryProvider);
    await repository.setActiveProfile(id);

    ref.invalidateSelf();
    await future;
  }
}

/// Active Profile Provider
/// 현재 활성화된 프로필
@riverpod
Future<SajuProfile?> activeProfile(ActiveProfileRef ref) async {
  final repository = ref.watch(profileRepositoryProvider);
  return repository.getActiveProfile();
}

/// Profile By Id Provider
/// 특정 ID의 프로필 조회 (family)
@riverpod
Future<SajuProfile?> profileById(ProfileByIdRef ref, String id) async {
  final repository = ref.watch(profileRepositoryProvider);
  return repository.getProfileById(id);
}
