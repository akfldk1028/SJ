import 'package:hive_flutter/hive_flutter.dart';
import '../models/saju_profile_model.dart';

/// 프로필 로컬 데이터소스
///
/// Hive를 사용한 프로필 로컬 저장소
class ProfileLocalDatasource {
  static const String _boxName = 'saju_profiles';
  Box<Map<dynamic, dynamic>>? _box;

  /// Hive Box 초기화
  Future<void> init() async {
    if (_box != null && _box!.isOpen) return;

    // Hive 초기화 (main.dart에서 이미 했다면 스킵됨)
    if (!Hive.isBoxOpen(_boxName)) {
      _box = await Hive.openBox<Map<dynamic, dynamic>>(_boxName);
    } else {
      _box = Hive.box<Map<dynamic, dynamic>>(_boxName);
    }
  }

  /// Box 가져오기 (null safety 보장)
  Box<Map<dynamic, dynamic>> _getBox() {
    if (_box == null || !_box!.isOpen) {
      throw StateError('ProfileLocalDatasource not initialized. Call init() first.');
    }
    return _box!;
  }

  /// 모든 프로필 조회
  Future<List<SajuProfileModel>> getAll() async {
    await init();
    final box = _getBox();

    final profiles = <SajuProfileModel>[];
    for (var i = 0; i < box.length; i++) {
      final map = box.getAt(i);
      if (map != null) {
        profiles.add(SajuProfileModel.fromHiveMap(map));
      }
    }

    // 생성일시 역순 정렬
    profiles.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return profiles;
  }

  /// ID로 프로필 조회
  Future<SajuProfileModel?> getById(String id) async {
    await init();
    final box = _getBox();

    for (var i = 0; i < box.length; i++) {
      final map = box.getAt(i);
      if (map != null && map['id'] == id) {
        return SajuProfileModel.fromHiveMap(map);
      }
    }
    return null;
  }

  /// 활성 프로필 조회
  Future<SajuProfileModel?> getActive() async {
    await init();
    final box = _getBox();

    for (var i = 0; i < box.length; i++) {
      final map = box.getAt(i);
      if (map != null && (map['isActive'] as bool?) == true) {
        return SajuProfileModel.fromHiveMap(map);
      }
    }
    return null;
  }

  /// 프로필 저장
  ///
  /// 같은 ID가 이미 있으면 업데이트, 없으면 추가
  Future<void> save(SajuProfileModel profile) async {
    await init();
    final box = _getBox();

    // 기존 프로필 찾기
    int? existingIndex;
    for (var i = 0; i < box.length; i++) {
      final map = box.getAt(i);
      if (map != null && map['id'] == profile.id) {
        existingIndex = i;
        break;
      }
    }

    final data = profile.toHiveMap();

    if (existingIndex != null) {
      // 업데이트
      await box.putAt(existingIndex, data);
    } else {
      // 새로 추가
      await box.add(data);
    }
  }

  /// 프로필 업데이트
  Future<void> update(SajuProfileModel profile) async {
    await save(profile);
  }

  /// 프로필 삭제
  Future<void> delete(String id) async {
    await init();
    final box = _getBox();

    for (var i = 0; i < box.length; i++) {
      final map = box.getAt(i);
      if (map != null && map['id'] == id) {
        await box.deleteAt(i);
        return;
      }
    }
  }

  /// 모든 프로필을 비활성화
  Future<void> deactivateAll() async {
    await init();
    final box = _getBox();

    for (var i = 0; i < box.length; i++) {
      final map = box.getAt(i);
      if (map != null && (map['isActive'] as bool?) == true) {
        map['isActive'] = false;
        await box.putAt(i, map);
      }
    }
  }

  /// 특정 프로필 활성화 (다른 프로필은 비활성화)
  Future<void> setActive(String id) async {
    await init();
    final box = _getBox();

    // 모든 프로필 비활성화
    await deactivateAll();

    // 지정된 프로필만 활성화
    for (var i = 0; i < box.length; i++) {
      final map = box.getAt(i);
      if (map != null && map['id'] == id) {
        map['isActive'] = true;
        await box.putAt(i, map);
        return;
      }
    }
  }

  /// 프로필 개수 조회
  Future<int> count() async {
    await init();
    return _getBox().length;
  }

  /// 모든 프로필 삭제 (테스트용)
  Future<void> clear() async {
    await init();
    await _getBox().clear();
  }

  /// Box 닫기
  Future<void> dispose() async {
    if (_box != null && _box!.isOpen) {
      await _box!.close();
      _box = null;
    }
  }
}
