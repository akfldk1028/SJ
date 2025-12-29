import 'package:hive_flutter/hive_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/models/ai_persona.dart';

part 'persona_provider.g.dart';

/// Hive Box 이름
const String _personaBoxName = 'persona_settings';
const String _personaKey = 'current_persona';

/// 페르소나 상태 관리 Provider
///
/// - Hive에서 기본값 로드
/// - 변경 시 Hive에 저장
@riverpod
class PersonaNotifier extends _$PersonaNotifier {
  Box<String>? _box;

  @override
  AiPersona build() {
    _initBox();
    return _loadFromHive();
  }

  /// Hive Box 초기화
  Future<void> _initBox() async {
    if (!Hive.isBoxOpen(_personaBoxName)) {
      _box = await Hive.openBox<String>(_personaBoxName);
    } else {
      _box = Hive.box<String>(_personaBoxName);
    }
  }

  /// Hive에서 저장된 페르소나 로드
  AiPersona _loadFromHive() {
    try {
      if (Hive.isBoxOpen(_personaBoxName)) {
        final box = Hive.box<String>(_personaBoxName);
        final value = box.get(_personaKey);
        return AiPersona.fromString(value);
      }
    } catch (e) {
      // 에러 시 기본값 반환
    }
    return AiPersona.professional;
  }

  /// 페르소나 변경
  Future<void> setPersona(AiPersona persona) async {
    state = persona;

    // Hive에 저장
    try {
      if (_box == null || !_box!.isOpen) {
        await _initBox();
      }
      await _box?.put(_personaKey, persona.name);
    } catch (e) {
      // 저장 실패해도 state는 변경됨
    }
  }
}

/// 현재 페르소나 Provider (read-only)
@riverpod
AiPersona currentPersona(CurrentPersonaRef ref) {
  return ref.watch(personaNotifierProvider);
}
