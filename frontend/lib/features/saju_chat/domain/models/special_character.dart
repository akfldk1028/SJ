import '../../../../AI/jina/personas/persona_registry.dart';
import '../../../../AI/jina/personas/persona_base.dart';

/// 4개 특수 캐릭터 정의
///
/// 대화창에서 선택하는 개성 있는 캐릭터들
/// BasePerson(MBTI 4축)과 조합되어 16가지 AI 성격 생성
///
/// ## 위젯 트리 분리
/// ```
/// ┌─────────────────────────────────────────────┐
/// │  사이드바              │      대화창         │
/// │  ┌───────────────┐    │  ┌──────────────┐  │
/// │  │ BasePerson    │    │  │ 👶🗣️👴😱     │  │
/// │  │ (NF/NT/SF/ST) │    │  │ (특수 캐릭터) │  │
/// │  └───────────────┘    │  └──────────────┘  │
/// └─────────────────────────────────────────────┘
/// ```
enum SpecialCharacter {
  /// 아기동자 - 반말과 팩폭, 꼬마도사
  babyMonk,

  /// 송작가 - 스토리텔링 전문 캐릭터
  scenarioWriter,

  /// 음양 할배 - 어둠 속 빛을 찾는 반전의 대가
  yinYangGrandpa;

  /// PersonaRegistry ID 매핑
  String get personaId {
    switch (this) {
      case SpecialCharacter.babyMonk:
        return 'baby_monk';
      case SpecialCharacter.scenarioWriter:
        return 'saju_scenario_builder';
      case SpecialCharacter.yinYangGrandpa:
        return 'yin_yang_grandpa';
    }
  }

  /// PersonaBase 인스턴스 가져오기
  PersonaBase get persona => PersonaRegistry.getByIdOrDefault(personaId);

  /// 표시명
  String get displayName {
    switch (this) {
      case SpecialCharacter.babyMonk:
        return '아기동자';
      case SpecialCharacter.scenarioWriter:
        return '송작가';
      case SpecialCharacter.yinYangGrandpa:
        return '음양 할배';
    }
  }

  /// 이모지 아이콘
  String get emoji {
    switch (this) {
      case SpecialCharacter.babyMonk:
        return '👶';
      case SpecialCharacter.scenarioWriter:
        return '🗣️';
      case SpecialCharacter.yinYangGrandpa:
        return '☯️';
    }
  }

  /// 짧은 설명
  String get description {
    switch (this) {
      case SpecialCharacter.babyMonk:
        return '반말과 팩폭, 꼬마도사';
      case SpecialCharacter.scenarioWriter:
        return '사주 스토리텔러';
      case SpecialCharacter.yinYangGrandpa:
        return '어둠 속 빛, 반전의 대가';
    }
  }

  /// 캐릭터 modifier 프롬프트 (BasePerson에 추가됨)
  String get characterModifier => persona.buildFullSystemPrompt();

  /// 문자열에서 변환
  static SpecialCharacter fromString(String? value) {
    switch (value) {
      case 'babyMonk':
        return SpecialCharacter.babyMonk;
      case 'scenarioWriter':
        return SpecialCharacter.scenarioWriter;
      case 'yinYangGrandpa':
      case 'saOngJiMa': // 하위 호환
        return SpecialCharacter.yinYangGrandpa;
      default:
        return SpecialCharacter.babyMonk;
    }
  }
}
