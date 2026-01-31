import 'package:flutter/material.dart';
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

  /// 시궁창 술사 - 팩폭 장인 (MBTI 조절 불가)
  sewerSaju;

  /// UI에서 숨길 페르소나 여부
  bool get isHidden {
    switch (this) {
      case ChatPersona.scenarioWriter:
        return true; // 송작가 - 사용 안함
      default:
        return false;
    }
  }

  /// UI에 표시할 페르소나 목록 (isHidden=false만)
  static List<ChatPersona> get visibleValues =>
      ChatPersona.values.where((p) => !p.isHidden).toList();

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
      case ChatPersona.sewerSaju:
        return '시궁창 술사';
    }
  }

  /// 이모지 아이콘 (레거시, 호환성 유지)
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
      case ChatPersona.sewerSaju:
        return '🤮';
    }
  }

  /// Material 아이콘
  IconData get icon {
    switch (this) {
      case ChatPersona.basePerson:
        return Icons.person_outline_rounded; // 기본 사람
      case ChatPersona.babyMonk:
        return Icons.face_rounded; // 얼굴 (동자)
      case ChatPersona.scenarioWriter:
        return Icons.edit_note_rounded; // 작가/글쓰기
      case ChatPersona.saOngJiMa:
        return Icons.spa_rounded; // 평화/긍정
      case ChatPersona.sewerSaju:
        return Icons.bolt_rounded; // 번개/팩폭
    }
  }

  /// 짧은 이름 (UI 표시용, 2-3글자)
  String get shortName {
    switch (this) {
      case ChatPersona.basePerson:
        return 'MBTI';
      case ChatPersona.babyMonk:
        return '아기동자';
      case ChatPersona.scenarioWriter:
        return '송작가';
      case ChatPersona.saOngJiMa:
        return '새옹지마';
      case ChatPersona.sewerSaju:
        return '시궁창';
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
      case ChatPersona.sewerSaju:
        return '팩폭 장인';
    }
  }

  /// 상세 설명 (페르소나 설명 팝업용)
  String get detailedDescription {
    switch (this) {
      case ChatPersona.basePerson:
        return '기본 AI 상담사입니다. MBTI 4축(감성형·분석형·친근형·현실형)을 자유롭게 조절하여 원하는 스타일의 사주 상담을 받을 수 있습니다.\n\n성향 버튼을 터치하면 상담 스타일이 변경됩니다.';
      case ChatPersona.babyMonk:
        return '꼬마 도사 아기동자입니다. 반말로 거침없이 사주를 풀어주며, 핵심만 콕콕 짚어주는 팩폭 스타일입니다.\n\n가벼운 분위기에서 솔직한 사주 풀이를 원할 때 추천합니다.';
      case ChatPersona.scenarioWriter:
        return '사주를 하나의 이야기로 풀어내는 스토리텔러입니다. 당신의 사주를 마치 소설처럼 재미있게 해석해 줍니다.';
      case ChatPersona.saOngJiMa:
        return '새옹지마 할배는 어떤 사주든 긍정적으로 재해석해 주는 전문가입니다.\n\n나쁜 운도 좋게 해석하고, 힘든 시기에도 희망을 찾아줍니다. 위로가 필요할 때 추천합니다.';
      case ChatPersona.sewerSaju:
        return '시궁창 술사는 사주의 안 좋은 면을 거침없이 파헤치는 팩폭 장인입니다.\n\n독설과 사이다 발언으로 현실을 직시하게 해줍니다. 심장이 약하신 분은 주의!';
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
      case 'sewerSaju':
        return ChatPersona.sewerSaju;
      default:
        return ChatPersona.basePerson;
    }
  }
}
