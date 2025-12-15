import 'package:hive_flutter/hive_flutter.dart';

import '../../../../core/services/supabase_service.dart';
import '../models/saju_analysis_db_model.dart';

/// 사주 분석 결과 저장소
///
/// Supabase (원격) + Hive (로컬 캐시) 이중 저장소 패턴
/// - 온라인: Supabase 우선, Hive 캐시 동기화
/// - 오프라인: Hive만 사용
class SajuAnalysisRepository {
  static const String _boxName = 'saju_analyses';

  /// Hive 박스 가져오기
  Box<dynamic> get _box => Hive.box(_boxName);

  // ==================== CREATE ====================

  /// 사주 분석 결과 저장
  ///
  /// 온라인: Supabase에 저장 후 Hive 캐시
  /// 오프라인: Hive에만 저장 (나중에 동기화)
  Future<SajuAnalysisDbModel> save(SajuAnalysisDbModel model) async {
    // Hive에 먼저 저장 (오프라인 우선)
    await _saveToHive(model);

    // Supabase 연결 시 원격 저장
    if (SupabaseService.isConnected) {
      try {
        await _saveToSupabase(model);
      } catch (e) {
        // 원격 저장 실패 시 로컬에만 유지 (나중에 동기화)
        _markForSync(model.id);
        rethrow;
      }
    } else {
      // 오프라인 모드: 동기화 대기 목록에 추가
      _markForSync(model.id);
    }

    return model;
  }

  /// Supabase에 저장 (upsert)
  ///
  /// profile_id에 UNIQUE 제약조건이 있으므로
  /// 같은 프로필의 분석은 업데이트됨
  Future<void> _saveToSupabase(SajuAnalysisDbModel model) async {
    final table = SupabaseService.sajuAnalysesTable;
    if (table == null) return;

    // profile_id 충돌 시 업데이트 (onConflict 설정)
    await table.upsert(
      model.toSupabase(),
      onConflict: 'profile_id',
    );
  }

  /// Hive에 저장
  Future<void> _saveToHive(SajuAnalysisDbModel model) async {
    await _box.put(model.id, model.toHiveMap());
  }

  // ==================== READ ====================

  /// ID로 사주 분석 결과 조회
  ///
  /// 1. Hive 캐시 먼저 확인
  /// 2. 없으면 Supabase에서 조회 후 캐시
  Future<SajuAnalysisDbModel?> getById(String id) async {
    // 1. Hive 캐시 확인
    final cached = _getFromHive(id);
    if (cached != null) return cached;

    // 2. Supabase에서 조회
    if (SupabaseService.isConnected) {
      final remote = await _getFromSupabase(id);
      if (remote != null) {
        // 캐시에 저장
        await _saveToHive(remote);
        return remote;
      }
    }

    return null;
  }

  /// Hive에서 조회
  SajuAnalysisDbModel? _getFromHive(String id) {
    final data = _box.get(id);
    if (data == null) return null;
    return SajuAnalysisDbModel.fromHiveMap(Map<dynamic, dynamic>.from(data));
  }

  /// Supabase에서 조회
  Future<SajuAnalysisDbModel?> _getFromSupabase(String id) async {
    final table = SupabaseService.sajuAnalysesTable;
    if (table == null) return null;

    try {
      final response = await table.select().eq('id', id).maybeSingle();
      if (response == null) return null;
      return SajuAnalysisDbModel.fromSupabase(response);
    } catch (e) {
      return null;
    }
  }

  /// 프로필 ID로 사주 분석 결과 조회
  Future<SajuAnalysisDbModel?> getByProfileId(String profileId) async {
    // 1. Hive에서 먼저 검색
    for (final key in _box.keys) {
      final data = _box.get(key);
      if (data != null && data['profileId'] == profileId) {
        return SajuAnalysisDbModel.fromHiveMap(Map<dynamic, dynamic>.from(data));
      }
    }

    // 2. Supabase에서 조회
    if (SupabaseService.isConnected) {
      final table = SupabaseService.sajuAnalysesTable;
      if (table != null) {
        try {
          final response =
              await table.select().eq('profile_id', profileId).maybeSingle();
          if (response != null) {
            final model = SajuAnalysisDbModel.fromSupabase(response);
            await _saveToHive(model);
            return model;
          }
        } catch (e) {
          // 조회 실패
        }
      }
    }

    return null;
  }

  /// 모든 사주 분석 결과 조회 (로컬 캐시)
  List<SajuAnalysisDbModel> getAllLocal() {
    final results = <SajuAnalysisDbModel>[];
    for (final key in _box.keys) {
      final data = _box.get(key);
      if (data != null) {
        results.add(
          SajuAnalysisDbModel.fromHiveMap(Map<dynamic, dynamic>.from(data)),
        );
      }
    }
    return results;
  }

  /// 사용자의 모든 사주 분석 결과 조회 (Supabase)
  Future<List<SajuAnalysisDbModel>> getAllByUser() async {
    if (!SupabaseService.isConnected || !SupabaseService.isLoggedIn) {
      return getAllLocal();
    }

    final table = SupabaseService.sajuAnalysesTable;
    if (table == null) return getAllLocal();

    try {
      final response = await table.select().order('corrected_datetime');
      final results = (response as List)
          .map((json) =>
              SajuAnalysisDbModel.fromSupabase(json as Map<String, dynamic>))
          .toList();

      // 로컬 캐시 업데이트
      for (final model in results) {
        await _saveToHive(model);
      }

      return results;
    } catch (e) {
      return getAllLocal();
    }
  }

  // ==================== UPDATE ====================

  /// 사주 분석 결과 업데이트
  Future<SajuAnalysisDbModel> update(SajuAnalysisDbModel model) async {
    return save(model); // upsert 패턴
  }

  // ==================== DELETE ====================

  /// ID로 사주 분석 결과 삭제
  Future<void> delete(String id) async {
    // Hive에서 삭제
    await _box.delete(id);

    // Supabase에서 삭제
    if (SupabaseService.isConnected) {
      final table = SupabaseService.sajuAnalysesTable;
      if (table != null) {
        try {
          await table.delete().eq('id', id);
        } catch (e) {
          // 삭제 실패 로깅
        }
      }
    }
  }

  /// 프로필 ID로 사주 분석 결과 삭제
  Future<void> deleteByProfileId(String profileId) async {
    // Hive에서 삭제
    final keysToDelete = <dynamic>[];
    for (final key in _box.keys) {
      final data = _box.get(key);
      if (data != null && data['profileId'] == profileId) {
        keysToDelete.add(key);
      }
    }
    await _box.deleteAll(keysToDelete);

    // Supabase에서 삭제
    if (SupabaseService.isConnected) {
      final table = SupabaseService.sajuAnalysesTable;
      if (table != null) {
        try {
          await table.delete().eq('profile_id', profileId);
        } catch (e) {
          // 삭제 실패 로깅
        }
      }
    }
  }

  // ==================== SYNC ====================

  /// 동기화 대기 목록에 추가
  void _markForSync(String id) {
    final syncBox = Hive.box('chat_sessions'); // 임시로 기존 박스 사용
    final pendingSync = List<String>.from(syncBox.get('pending_saju_sync', defaultValue: <String>[]));
    if (!pendingSync.contains(id)) {
      pendingSync.add(id);
      syncBox.put('pending_saju_sync', pendingSync);
    }
  }

  /// 동기화 대기 목록에서 제거
  void _unmarkForSync(String id) {
    final syncBox = Hive.box('chat_sessions');
    final pendingSync = List<String>.from(syncBox.get('pending_saju_sync', defaultValue: <String>[]));
    pendingSync.remove(id);
    syncBox.put('pending_saju_sync', pendingSync);
  }

  /// 오프라인 데이터 동기화
  ///
  /// 앱 시작 시 또는 네트워크 복구 시 호출
  Future<SyncResult> syncPendingData() async {
    if (!SupabaseService.isConnected) {
      return SyncResult(synced: 0, failed: 0, pending: _getPendingSyncCount());
    }

    final syncBox = Hive.box('chat_sessions');
    final pendingSync = List<String>.from(
      syncBox.get('pending_saju_sync', defaultValue: <String>[]),
    );

    int synced = 0;
    int failed = 0;

    for (final id in List<String>.from(pendingSync)) {
      final model = _getFromHive(id);
      if (model == null) {
        _unmarkForSync(id);
        continue;
      }

      try {
        await _saveToSupabase(model);
        _unmarkForSync(id);
        synced++;
      } catch (e) {
        failed++;
      }
    }

    return SyncResult(
      synced: synced,
      failed: failed,
      pending: _getPendingSyncCount(),
    );
  }

  /// 동기화 대기 개수
  int _getPendingSyncCount() {
    final syncBox = Hive.box('chat_sessions');
    final pendingSync = syncBox.get('pending_saju_sync', defaultValue: <String>[]);
    return (pendingSync as List).length;
  }

  /// Supabase에서 모든 데이터 가져와서 로컬 동기화
  Future<int> pullFromRemote() async {
    if (!SupabaseService.isConnected || !SupabaseService.isLoggedIn) {
      return 0;
    }

    final results = await getAllByUser();
    return results.length;
  }
}

/// 동기화 결과
class SyncResult {
  final int synced;
  final int failed;
  final int pending;

  const SyncResult({
    required this.synced,
    required this.failed,
    required this.pending,
  });

  @override
  String toString() => 'SyncResult(synced: $synced, failed: $failed, pending: $pending)';
}
