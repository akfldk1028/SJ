import 'package:hive_flutter/hive_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/models/base_character.dart';

part 'character_provider.g.dart';

/// Hive Box 이름
const String _characterBoxName = 'character_settings';
const String _characterKey = 'current_character';

/// 기본 캐릭터 상태 관리 Provider
///
/// 4개 기본 캐릭터 중 선택
/// MBTI 분면은 별도 Provider에서 관리
///
/// ## 사용 예시
/// ```dart
/// final character = ref.watch(characterNotifierProvider);
/// ref.read(characterNotifierProvider.notifier).setCharacter(BaseCharacter.master);
/// ```
@riverpod
class CharacterNotifier extends _$CharacterNotifier {
  Box<String>? _box;

  @override
  BaseCharacter build() {
    _initBox();
    return _loadFromHive();
  }

  /// Hive Box 초기화
  Future<void> _initBox() async {
    if (!Hive.isBoxOpen(_characterBoxName)) {
      _box = await Hive.openBox<String>(_characterBoxName);
    } else {
      _box = Hive.box<String>(_characterBoxName);
    }
  }

  /// Hive에서 저장된 캐릭터 로드
  BaseCharacter _loadFromHive() {
    try {
      if (Hive.isBoxOpen(_characterBoxName)) {
        final box = Hive.box<String>(_characterBoxName);
        final value = box.get(_characterKey);
        return BaseCharacter.fromString(value);
      }
    } catch (e) {
      // 에러 시 기본값 반환
    }
    return BaseCharacter.babyMonk;
  }

  /// 캐릭터 변경
  Future<void> setCharacter(BaseCharacter character) async {
    state = character;

    // Hive에 저장
    try {
      if (_box == null || !_box!.isOpen) {
        await _initBox();
      }
      await _box?.put(_characterKey, character.name);
    } catch (e) {
      // 저장 실패해도 state는 변경됨
    }
  }
}

/// 현재 캐릭터 Provider (read-only)
@riverpod
BaseCharacter currentCharacter(CurrentCharacterRef ref) {
  return ref.watch(characterNotifierProvider);
}
