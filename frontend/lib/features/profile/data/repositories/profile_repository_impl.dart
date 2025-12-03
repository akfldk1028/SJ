import '../../domain/entities/saju_profile.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/profile_remote_datasource.dart';
import '../models/saju_profile_model.dart';

/// Profile Repository 구현체
///
/// Domain의 ProfileRepository interface를 implements
class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileRemoteDataSource _remoteDataSource;

  ProfileRepositoryImpl(this._remoteDataSource);

  @override
  Future<List<SajuProfile>> getProfiles() async {
    final models = await _remoteDataSource.getProfiles();
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<SajuProfile?> getProfileById(String id) async {
    final model = await _remoteDataSource.getProfileById(id);
    return model?.toEntity();
  }

  @override
  Future<SajuProfile?> getActiveProfile() async {
    final model = await _remoteDataSource.getActiveProfile();
    return model?.toEntity();
  }

  @override
  Future<SajuProfile> createProfile(SajuProfile profile) async {
    final model = SajuProfileModel.fromEntity(profile);
    final created = await _remoteDataSource.createProfile(model);
    return created.toEntity();
  }

  @override
  Future<SajuProfile> updateProfile(SajuProfile profile) async {
    final model = SajuProfileModel.fromEntity(profile);
    final updated = await _remoteDataSource.updateProfile(model);
    return updated.toEntity();
  }

  @override
  Future<void> deleteProfile(String id) async {
    await _remoteDataSource.deleteProfile(id);
  }

  @override
  Future<void> setActiveProfile(String id) async {
    await _remoteDataSource.setActiveProfile(id);
  }

  @override
  Future<int> getProfileCount() async {
    return await _remoteDataSource.getProfileCount();
  }
}
