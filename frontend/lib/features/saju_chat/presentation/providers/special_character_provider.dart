import 'package:hive_flutter/hive_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/models/special_character.dart';

part 'special_character_provider.g.dart';

/// Hive Box 이름
const String _characterBoxName = 'special_character_settings';
const String _characterKey = 'current_special_character';

/// 특수 캐릭터 상태 관리 Provider
///
/// 대화창에서 선택하는 4개 특수 캐릭터
/// BasePerson(MBTI 4축)과 완전히 별개
///
/// ## 사용 예시
/// ```dart
/// final character = ref.watch(specialCharacterNotifierProvider);
/// ref.read(specialCharacterNotifierProvider.notifier).setCharacter(SpecialCharacter.babyMonk);
/// ```
@riverpod
class SpecialCharacterNotifier extends _$SpecialCharacterNotifier {
  Box<String>? _box;

  @override
  SpecialCharacter build() {
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
  SpecialCharacter _loadFromHive() {
    try {
      if (Hive.isBoxOpen(_characterBoxName)) {
        final box = Hive.box<String>(_characterBoxName);
        final value = box.get(_characterKey);
        return SpecialCharacter.fromString(value);
      }
    } catch (e) {
      // 에러 시 기본값 반환
    }
    return SpecialCharacter.babyMonk;
  }

  /// 캐릭터 변경
  Future<void> setCharacter(SpecialCharacter character) async {
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

/// 현재 특수 캐릭터 Provider (read-only)
@riverpod
SpecialCharacter currentSpecialCharacter(CurrentSpecialCharacterRef ref) {
  return ref.watch(specialCharacterNotifierProvider);
}
