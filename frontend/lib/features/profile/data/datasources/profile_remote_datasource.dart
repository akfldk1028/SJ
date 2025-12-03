import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/saju_profile_model.dart';

/// Profile Remote DataSource
///
/// Supabase와 통신하는 레이어
class ProfileRemoteDataSource {
  final SupabaseClient _client;

  static const String _tableName = 'saju_profiles';

  ProfileRemoteDataSource(this._client);

  /// 프로필 목록 조회
  Future<List<SajuProfileModel>> getProfiles() async {
    final response = await _client
        .from(_tableName)
        .select()
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => SajuProfileModel.fromJson(json))
        .toList();
  }

  /// 프로필 단건 조회
  Future<SajuProfileModel?> getProfileById(String id) async {
    final response = await _client
        .from(_tableName)
        .select()
        .eq('id', id)
        .maybeSingle();

    if (response == null) return null;
    return SajuProfileModel.fromJson(response);
  }

  /// 활성 프로필 조회
  Future<SajuProfileModel?> getActiveProfile() async {
    final response = await _client
        .from(_tableName)
        .select()
        .eq('is_active', true)
        .maybeSingle();

    if (response == null) return null;
    return SajuProfileModel.fromJson(response);
  }

  /// 프로필 생성
  Future<SajuProfileModel> createProfile(SajuProfileModel profile) async {
    final response = await _client
        .from(_tableName)
        .insert(profile.toInsertJson())
        .select()
        .single();

    return SajuProfileModel.fromJson(response);
  }

  /// 프로필 수정
  Future<SajuProfileModel> updateProfile(SajuProfileModel profile) async {
    final response = await _client
        .from(_tableName)
        .update(profile.toUpdateJson())
        .eq('id', profile.id)
        .select()
        .single();

    return SajuProfileModel.fromJson(response);
  }

  /// 프로필 삭제
  Future<void> deleteProfile(String id) async {
    await _client.from(_tableName).delete().eq('id', id);
  }

  /// 활성 프로필 설정
  /// 다른 프로필은 비활성화하고 지정된 프로필만 활성화
  Future<void> setActiveProfile(String id) async {
    // 모든 프로필 비활성화
    await _client.from(_tableName).update({'is_active': false});

    // 지정된 프로필 활성화
    await _client.from(_tableName).update({'is_active': true}).eq('id', id);
  }

  /// 프로필 개수 조회
  Future<int> getProfileCount() async {
    final response = await _client
        .from(_tableName)
        .select('id')
        .count(CountOption.exact);

    return response.count;
  }
}
