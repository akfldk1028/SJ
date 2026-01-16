import '../../../../AI/jina/personas/persona_registry.dart';
import '../../../../AI/jina/personas/persona_base.dart';

/// 채팅 페르소나 타입
///
/// - basePerson: MBTI 4축 조절 가능한 기본 페르소나
/// - specialCharacter: MBTI 조절 불가, 고정된 특수 캐릭터
enum ChatPersonaType {
  basePerson,
  specialCharacter,
}

/// 채팅 페르소나 (통합)
///
/// 오른쪽 대화창에서 선택하는 5개 페르소나:
/// - BasePerson 1개 (MBTI 4축 조절 가능)
/// - SpecialCharacter 4개 (MBTI 조절 불가, 고정 성격)
///
/// ## 구조
/// ```
/// ┌─────────────────────────────────────────────┐
/// │  사이드바              │      대화창         │
/// │  ┌───────────────┐    │  ┌──────────────┐  │
/// │  │ MBTI 4축      │    │  │ [Base] 👶🗣️👴😱│  │
/// │  │ (BasePerson   │    │  │              │  │
/// │  │  선택 시만    │    │  │ 5개 선택지   │  │
/// │  │  활성화)      │    │  │              │  │
/// │  └───────────────┘    │  └──────────────┘  │
/// └─────────────────────────────────────────────┘
/// ```
enum ChatPersona {
  /// BasePerson - MBTI 4축 조절 가능
  basePerson,

  /// 아기동자 - 반말과 팩폭, 꼬마도사 (MBTI 조절 불가)
  babyMonk,

  /// 송작가 - 스토리텔링 전문 캐릭터 (MBTI 조절 불가)
  scenarioWriter,

  /// 새옹지마 - 긍정 재해석 전문가 (MBTI 조절 불가)
  saOngJiMa,

  /// 하꼬무당 - 장비장군이 오셨다 (MBTI 조절 불가)
  newbieShaman,

  /// 시궁창 술사 - 팩폭 장인 (MBTI 조절 불가)
  sewerSaju;

  /// 타입 확인
  ChatPersonaType get type {
    if (this == ChatPersona.basePerson) {
      return ChatPersonaType.basePerson;
    }
    return ChatPersonaType.specialCharacter;
  }

  /// MBTI 조절 가능 여부
  bool get canAdjustMbti => this == ChatPersona.basePerson;

  /// PersonaRegistry ID 매핑
  String get personaId {
    switch (this) {
      case ChatPersona.basePerson:
        return 'base_person'; // MBTI에 따라 동적으로 변경됨
      case ChatPersona.babyMonk:
        return 'baby_monk';
      case ChatPersona.scenarioWriter:
        return 'saju_scenario_builder';
      case ChatPersona.saOngJiMa:
        return 'sa_ong_ji_ma';
      case ChatPersona.newbieShaman:
        return 'newbie_shaman';
      case ChatPersona.sewerSaju:
        return 'sewer_saju';
    }
  }

  /// PersonaBase 인스턴스 가져오기 (SpecialCharacter용)
  PersonaBase? get persona {
    if (this == ChatPersona.basePerson) return null;
    return PersonaRegistry.getByIdOrDefault(personaId);
  }

  /// 표시명
  String get displayName {
    switch (this) {
      case ChatPersona.basePerson:
        return 'Base';
      case ChatPersona.babyMonk:
        return '아기동자';
      case ChatPersona.scenarioWriter:
        return '송작가';
      case ChatPersona.saOngJiMa:
        return '새옹지마';
      case ChatPersona.newbieShaman:
        return '하꼬무당';
      case ChatPersona.sewerSaju:
        return '시궁창 술사';
    }
  }

  /// 이모지 아이콘
  String get emoji {
    switch (this) {
      case ChatPersona.basePerson:
        return '🎭'; // Base 페르소나 (MBTI 조절 가능)
      case ChatPersona.babyMonk:
        return '👶';
      case ChatPersona.scenarioWriter:
        return '🗣️';
      case ChatPersona.saOngJiMa:
        return '👴';
      case ChatPersona.newbieShaman:
        return '😱';
      case ChatPersona.sewerSaju:
        return '🤮';
    }
  }

  /// 짧은 설명
  String get description {
    switch (this) {
      case ChatPersona.basePerson:
        return 'MBTI 성향 조절 가능';
      case ChatPersona.babyMonk:
        return '반말과 팩폭, 꼬마도사';
      case ChatPersona.scenarioWriter:
        return '사주 스토리텔러';
      case ChatPersona.saOngJiMa:
        return '긍정 재해석 전문가';
      case ChatPersona.newbieShaman:
        return '장비장군이 오셨다';
      case ChatPersona.sewerSaju:
        return '팩폭 장인';
    }
  }

  /// 시스템 프롬프트 (SpecialCharacter용, BasePerson은 MBTI에 따라 동적)
  String? get fixedSystemPrompt {
    if (this == ChatPersona.basePerson) return null;
    return persona?.buildFullSystemPrompt();
  }

  /// 문자열에서 변환
  static ChatPersona fromString(String? value) {
    switch (value) {
      case 'basePerson':
        return ChatPersona.basePerson;
      case 'babyMonk':
        return ChatPersona.babyMonk;
      case 'scenarioWriter':
        return ChatPersona.scenarioWriter;
      case 'saOngJiMa':
        return ChatPersona.saOngJiMa;
      case 'newbieShaman':
        return ChatPersona.newbieShaman;
      case 'sewerSaju':
        return ChatPersona.sewerSaju;
      default:
        return ChatPersona.basePerson;
    }
  }
}
