import 'package:hive_flutter/hive_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../AI/jina/personas/persona_registry.dart';
import '../../domain/models/chat_persona.dart';
import '../../domain/models/ai_persona.dart';

part 'chat_persona_provider.g.dart';

/// Hive Box 이름
const String _chatPersonaBoxName = 'chat_persona_settings';
const String _chatPersonaKey = 'current_chat_persona';
const String _mbtiQuadrantKey = 'current_mbti_quadrant';

/// 채팅 페르소나 상태 관리 Provider
///
/// 5개 페르소나 중 선택:
/// - BasePerson (MBTI 조절 가능)
/// - SpecialCharacter 4개 (MBTI 조절 불가)
@riverpod
class ChatPersonaNotifier extends _$ChatPersonaNotifier {
  Box<String>? _box;

  @override
  ChatPersona build() {
    _initBox();
    return _loadFromHive();
  }

  Future<void> _initBox() async {
    if (!Hive.isBoxOpen(_chatPersonaBoxName)) {
      _box = await Hive.openBox<String>(_chatPersonaBoxName);
    } else {
      _box = Hive.box<String>(_chatPersonaBoxName);
    }
  }

  ChatPersona _loadFromHive() {
    try {
      if (Hive.isBoxOpen(_chatPersonaBoxName)) {
        final box = Hive.box<String>(_chatPersonaBoxName);
        final value = box.get(_chatPersonaKey);
        return ChatPersona.fromString(value);
      }
    } catch (e) {
      // 에러 시 기본값 반환
    }
    return ChatPersona.nfSensitive;
  }

  Future<void> setPersona(ChatPersona persona) async {
    state = persona;

    try {
      if (_box == null || !_box!.isOpen) {
        await _initBox();
      }
      await _box?.put(_chatPersonaKey, persona.name);
    } catch (e) {
      // 저장 실패해도 state는 변경됨
    }
  }
}

/// MBTI 분면 상태 Provider (BasePerson 전용)
///
/// BasePerson 선택 시에만 활성화
@riverpod
class MbtiQuadrantNotifier extends _$MbtiQuadrantNotifier {
  Box<String>? _box;

  @override
  MbtiQuadrant build() {
    _initBox();
    return _loadFromHive();
  }

  Future<void> _initBox() async {
    if (!Hive.isBoxOpen(_chatPersonaBoxName)) {
      _box = await Hive.openBox<String>(_chatPersonaBoxName);
    } else {
      _box = Hive.box<String>(_chatPersonaBoxName);
    }
  }

  MbtiQuadrant _loadFromHive() {
    try {
      if (Hive.isBoxOpen(_chatPersonaBoxName)) {
        final box = Hive.box<String>(_chatPersonaBoxName);
        final value = box.get(_mbtiQuadrantKey);
        return _fromString(value);
      }
    } catch (e) {
      // 에러 시 기본값 반환
    }
    return MbtiQuadrant.NF;
  }

  MbtiQuadrant _fromString(String? value) {
    switch (value) {
      case 'NF':
        return MbtiQuadrant.NF;
      case 'NT':
        return MbtiQuadrant.NT;
      case 'SF':
        return MbtiQuadrant.SF;
      case 'ST':
        return MbtiQuadrant.ST;
      default:
        return MbtiQuadrant.NF;
    }
  }

  Future<void> setQuadrant(MbtiQuadrant quadrant) async {
    state = quadrant;

    try {
      if (_box == null || !_box!.isOpen) {
        await _initBox();
      }
      await _box?.put(_mbtiQuadrantKey, quadrant.name);
    } catch (e) {
      // 저장 실패해도 state는 변경됨
    }
  }
}

/// 현재 ChatPersona가 MBTI 조절 가능한지 여부
@riverpod
bool canAdjustMbti(CanAdjustMbtiRef ref) {
  final persona = ref.watch(chatPersonaNotifierProvider);
  return persona.canAdjustMbti;
}

/// 최종 시스템 프롬프트 Provider
///
/// 모든 페르소나가 직접 personaId를 가지므로 단순화됨
/// - MBTI 페르소나: personaId로 직접 프롬프트 로드
/// - 특수 캐릭터: personaId로 직접 프롬프트 로드
/// - 레거시 basePerson: MBTI 분면에 따른 동적 프롬프트 (하위 호환)
@riverpod
String finalSystemPrompt(FinalSystemPromptRef ref) {
  final persona = ref.watch(chatPersonaNotifierProvider);

  if (persona.canAdjustMbti) {
    // 레거시 basePerson: MBTI에 따른 동적 프롬프트
    final mbtiQuadrant = ref.watch(mbtiQuadrantNotifierProvider);
    final personaId = _getBasePersonaId(mbtiQuadrant);
    final p = PersonaRegistry.getById(personaId);
    return p?.buildFullSystemPrompt() ?? '';
  }

  // MBTI 페르소나 및 특수 캐릭터: 직접 프롬프트 로드
  return persona.fixedSystemPrompt ?? '';
}

/// MBTI 분면에 해당하는 BasePerson ID (레거시 호환)
String _getBasePersonaId(MbtiQuadrant quadrant) {
  switch (quadrant) {
    case MbtiQuadrant.NF:
      return 'base_nf';
    case MbtiQuadrant.NT:
      return 'base_nt';
    case MbtiQuadrant.SF:
      return 'base_sf';
    case MbtiQuadrant.ST:
      return 'base_st';
  }
}
