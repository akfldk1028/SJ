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
  Future<void> save(SajuProfile profile) async {
    final model = SajuProfileModel.fromEntity(profile);
    await _localDatasource.save(model);
  }

  @override
  Future<void> update(SajuProfile profile) async {
    // updatedAt 자동 갱신
    final updatedProfile = profile.copyWith(
      updatedAt: DateTime.now(),
    );
    final model = SajuProfileModel.fromEntity(updatedProfile);
    await _localDatasource.update(model);
  }

  @override
  Future<void> delete(String id) async {
    // 마지막 프로필 삭제 방지
    final count = await _localDatasource.count();
    if (count <= 1) {
      throw Exception('최소 1개의 프로필이 필요합니다.');
    }

    await _localDatasource.delete(id);

    // 삭제된 프로필이 활성 프로필이었다면 다른 프로필 활성화
    final activeProfile = await _localDatasource.getActive();
    if (activeProfile == null) {
      final profiles = await _localDatasource.getAll();
      if (profiles.isNotEmpty) {
        await _localDatasource.setActive(profiles.first.id);
      }
    }
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
}
