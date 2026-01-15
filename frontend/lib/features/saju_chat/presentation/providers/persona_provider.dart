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
    // 초기에는 기본값을 반환하고, 비동기로 저장값을 불러와 state를 갱신
    _loadAndSet();
    return AiPersona.professional;
  }

  Future<void> _loadAndSet() async {
    await _ensureBox();
    final loaded = _loadFromHive();
    if (state != loaded) {
      state = loaded;
    }
  }

  /// Hive Box를 준비하고 참조를 유지
  Future<void> _ensureBox() async {
    if (_box != null && _box!.isOpen) return;

    if (!Hive.isBoxOpen(_personaBoxName)) {
      _box = await Hive.openBox<String>(_personaBoxName);
    } else {
      _box = Hive.box<String>(_personaBoxName);
    }
  }

  /// Hive에서 저장된 페르소나 로드
  AiPersona _loadFromHive() {
    try {
      if (_box != null && _box!.isOpen) {
        final value = _box!.get(_personaKey);
        return AiPersona.fromString(value);
      }
    } catch (_) {
      // 에러 시 기본값 반환
    }
    return AiPersona.professional;
  }

  /// 페르소나 변경
  Future<void> setPersona(AiPersona persona) async {
    state = persona;

    // Hive에 저장 (박스 준비 후)
    try {
      await _ensureBox();
      await _box?.put(_personaKey, persona.name);
    } catch (_) {
      // 저장 실패해도 state는 변경됨
    }
  }
}

/// 현재 페르소나 Provider (read-only)
@riverpod
AiPersona currentPersona(CurrentPersonaRef ref) {
  return ref.watch(personaNotifierProvider);
}
