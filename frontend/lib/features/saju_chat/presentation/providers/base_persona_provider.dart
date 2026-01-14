import 'package:hive_flutter/hive_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/models/base_persona.dart';

part 'base_persona_provider.g.dart';

/// Hive Box 이름
const String _basePersonaBoxName = 'base_persona_settings';
const String _basePersonaKey = 'current_base_persona';

/// Base 페르소나 상태 관리 Provider
///
/// 사이드바에서 선택하는 MBTI 기반 Base 페르소나
/// SpecialCharacter와 완전히 별개
///
/// ## 사용 예시
/// ```dart
/// final basePerson = ref.watch(basePersonaNotifierProvider);
/// ref.read(basePersonaNotifierProvider.notifier).setBasePerson(BasePerson.ntStrategist);
/// ```
@riverpod
class BasePersonaNotifier extends _$BasePersonaNotifier {
  Box<String>? _box;

  @override
  BasePerson build() {
    _initBox();
    return _loadFromHive();
  }

  /// Hive Box 초기화
  Future<void> _initBox() async {
    if (!Hive.isBoxOpen(_basePersonaBoxName)) {
      _box = await Hive.openBox<String>(_basePersonaBoxName);
    } else {
      _box = Hive.box<String>(_basePersonaBoxName);
    }
  }

  /// Hive에서 저장된 Base 페르소나 로드
  BasePerson _loadFromHive() {
    try {
      if (Hive.isBoxOpen(_basePersonaBoxName)) {
        final box = Hive.box<String>(_basePersonaBoxName);
        final value = box.get(_basePersonaKey);
        return BasePerson.fromString(value);
      }
    } catch (e) {
      // 에러 시 기본값 반환
    }
    return BasePerson.nfCounselor;
  }

  /// Base 페르소나 변경
  Future<void> setBasePerson(BasePerson basePerson) async {
    state = basePerson;

    // Hive에 저장
    try {
      if (_box == null || !_box!.isOpen) {
        await _initBox();
      }
      await _box?.put(_basePersonaKey, basePerson.name);
    } catch (e) {
      // 저장 실패해도 state는 변경됨
    }
  }
}

/// 현재 Base 페르소나 Provider (read-only)
@riverpod
BasePerson currentBasePerson(CurrentBasePersonRef ref) {
  return ref.watch(basePersonaNotifierProvider);
}
