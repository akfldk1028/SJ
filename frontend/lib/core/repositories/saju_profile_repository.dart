import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import '../services/auth_service.dart';
import '../../features/profile/domain/entities/saju_profile.dart';
import '../../features/profile/domain/entities/gender.dart';
import '../../features/profile/domain/entities/relationship_type.dart';

/// Supabase saju_profiles 테이블 Repository
class SajuProfileRepository {
  late final SupabaseClient _client;
  final AuthService _authService;

  SajuProfileRepository() : _authService = AuthService() {
    final client = SupabaseService.client;
    if (client == null) {
      throw Exception('Supabase not initialized');
    }
    _client = client;
  }

  static const String _tableName = 'saju_profiles';

  // ============================================================
  // CREATE
  // ============================================================

  /// 새 프로필 생성
  Future<SajuProfile> create(SajuProfile profile) async {
    final userId = _authService.currentUserId;
    if (userId == null) throw Exception('로그인이 필요합니다.');

    final data = _toSupabaseMap(profile, userId);

    final response = await _client
        .from(_tableName)
        .insert(data)
        .select()
        .single();

    return _fromSupabaseMap(response);
  }

  // ============================================================
  // READ
  // ============================================================

  /// 현재 사용자의 모든 프로필 조회
  Future<List<SajuProfile>> getAll() async {
    final userId = _authService.currentUserId;
    if (userId == null) throw Exception('로그인이 필요합니다.');

    final response = await _client
        .from(_tableName)
        .select()
        .eq('user_id', userId)
        .order('is_primary', ascending: false)
        .order('created_at', ascending: false);

    return (response as List)
        .map((e) => _fromSupabaseMap(e as Map<String, dynamic>))
        .toList();
  }

  /// ID로 프로필 조회
  Future<SajuProfile?> getById(String id) async {
    final response = await _client
        .from(_tableName)
        .select()
        .eq('id', id)
        .maybeSingle();

    if (response == null) return null;
    return _fromSupabaseMap(response);
  }

  /// 대표 프로필 조회
  Future<SajuProfile?> getPrimary() async {
    final userId = _authService.currentUserId;
    if (userId == null) throw Exception('로그인이 필요합니다.');

    final response = await _client
        .from(_tableName)
        .select()
        .eq('user_id', userId)
        .eq('is_primary', true)
        .maybeSingle();

    if (response == null) return null;
    return _fromSupabaseMap(response);
  }

  // ============================================================
  // UPDATE
  // ============================================================

  /// 프로필 업데이트
  Future<SajuProfile> update(SajuProfile profile) async {
    final userId = _authService.currentUserId;
    if (userId == null) throw Exception('로그인이 필요합니다.');

    final data = _toSupabaseMap(profile, userId);
    // id와 created_at은 업데이트하지 않음
    data.remove('id');
    data.remove('created_at');

    final response = await _client
        .from(_tableName)
        .update(data)
        .eq('id', profile.id)
        .select()
        .single();

    return _fromSupabaseMap(response);
  }

  /// 대표 프로필 설정
  Future<void> setPrimary(String profileId) async {
    await _client
        .from(_tableName)
        .update({'is_primary': true})
        .eq('id', profileId);
    // 트리거가 자동으로 다른 프로필의 is_primary를 false로 변경
  }

  // ============================================================
  // DELETE
  // ============================================================

  /// 프로필 삭제
  Future<void> delete(String id) async {
    await _client.from(_tableName).delete().eq('id', id);
    // CASCADE로 saju_analyses, chat_sessions 등도 삭제됨
  }

  // ============================================================
  // 변환 함수
  // ============================================================

  /// SajuProfile → Supabase Map
  Map<String, dynamic> _toSupabaseMap(SajuProfile profile, String userId) {
    return {
      'id': profile.id,
      'user_id': userId,
      'display_name': profile.displayName,
      'relation_type': profile.relationType.name,
      'memo': profile.memo,
      'birth_date': profile.birthDate.toIso8601String().split('T')[0],
      'birth_time_minutes': profile.birthTimeMinutes,
      'birth_time_unknown': profile.birthTimeUnknown,
      'is_lunar': profile.isLunar,
      'is_leap_month': profile.isLeapMonth,
      'gender': profile.gender.name,
      'birth_city': profile.birthCity,
      'time_correction': profile.timeCorrection,
      'use_ya_jasi': profile.useYaJasi,
      'is_primary': profile.isActive, // isActive → is_primary
      'created_at': profile.createdAt.toIso8601String(),
      'updated_at': profile.updatedAt.toIso8601String(),
    };
  }

  /// Supabase Map → SajuProfile
  SajuProfile _fromSupabaseMap(Map<String, dynamic> map) {
    return SajuProfile(
      id: map['id'] as String,
      displayName: map['display_name'] as String,
      relationType: RelationshipType.fromJson(map['relation_type'] as String),
      memo: map['memo'] as String?,
      birthDate: DateTime.parse(map['birth_date'] as String),
      birthTimeMinutes: map['birth_time_minutes'] as int?,
      birthTimeUnknown: map['birth_time_unknown'] as bool? ?? false,
      isLunar: map['is_lunar'] as bool? ?? false,
      isLeapMonth: map['is_leap_month'] as bool? ?? false,
      gender: Gender.fromString(map['gender'] as String),
      birthCity: map['birth_city'] as String,
      timeCorrection: map['time_correction'] as int? ?? 0,
      useYaJasi: map['use_ya_jasi'] as bool? ?? true,
      isActive: map['is_primary'] as bool? ?? false, // is_primary → isActive
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }
}
