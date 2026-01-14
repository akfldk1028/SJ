import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/models/base_persona.dart';
import '../../domain/models/special_character.dart';
import 'base_persona_provider.dart';
import 'special_character_provider.dart';

part 'combined_persona_provider.g.dart';

/// BasePerson + SpecialCharacter 조합 프롬프트 Provider
///
/// 4x4 조합: 4개 BasePerson × 4개 SpecialCharacter = 16가지 AI 성격
///
/// ## 구조
/// ```
/// ┌─────────────────────────────────────────────────┐
/// │           Final System Prompt                   │
/// │  ┌─────────────────────────────────────────┐   │
/// │  │     BasePerson System Prompt            │   │
/// │  │   (NF 감성형, NT 분석형, SF 친근형...)    │   │
/// │  └─────────────────────────────────────────┘   │
/// │                    +                            │
/// │  ┌─────────────────────────────────────────┐   │
/// │  │     SpecialCharacter Modifier           │   │
/// │  │    (아기동자, 송작가, 새옹지마, 하꼬무당)   │   │
/// │  └─────────────────────────────────────────┘   │
/// └─────────────────────────────────────────────────┘
/// ```
///
/// ## 사용 예시
/// ```dart
/// final combinedPrompt = ref.watch(combinedPersonaPromptProvider);
/// final combinedInfo = ref.watch(combinedPersonaInfoProvider);
/// ```
@riverpod
String combinedPersonaPrompt(CombinedPersonaPromptRef ref) {
  final basePerson = ref.watch(basePersonaNotifierProvider);
  final specialCharacter = ref.watch(specialCharacterNotifierProvider);

  // Base 페르소나 시스템 프롬프트 (MBTI 기반)
  final basePrompt = basePerson.baseSystemPrompt;

  // 특수 캐릭터 modifier 프롬프트
  final characterModifier = specialCharacter.characterModifier;

  // 조합
  return '''
$basePrompt

---

[Character Modifier: ${specialCharacter.displayName}]
$characterModifier
''';
}

/// 조합된 페르소나 정보 (표시용)
///
/// UI에서 현재 선택된 BasePerson + SpecialCharacter 조합을 표시할 때 사용
@riverpod
CombinedPersonaInfo combinedPersonaInfo(CombinedPersonaInfoRef ref) {
  final basePerson = ref.watch(basePersonaNotifierProvider);
  final specialCharacter = ref.watch(specialCharacterNotifierProvider);

  return CombinedPersonaInfo(
    basePerson: basePerson,
    specialCharacter: specialCharacter,
    displayName: '${specialCharacter.displayName} (${basePerson.displayName})',
    shortDescription: '${specialCharacter.description} / ${basePerson.description}',
  );
}

/// 조합된 페르소나 정보 클래스
class CombinedPersonaInfo {
  final BasePerson basePerson;
  final SpecialCharacter specialCharacter;
  final String displayName;
  final String shortDescription;

  const CombinedPersonaInfo({
    required this.basePerson,
    required this.specialCharacter,
    required this.displayName,
    required this.shortDescription,
  });

  /// 16가지 조합 중 현재 조합 인덱스 (0-15)
  int get combinationIndex {
    return basePerson.index * 4 + specialCharacter.index;
  }

  /// 캐릭터 이모지
  String get emoji => specialCharacter.emoji;

  /// BasePerson 색상 코드
  int get basePersonColorValue => basePerson.colorValue;
}
