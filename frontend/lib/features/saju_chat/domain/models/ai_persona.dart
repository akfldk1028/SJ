import '../../../../AI/jina/personas/persona_registry.dart';
import '../../../../AI/jina/personas/persona_base.dart';

/// AI 페르소나 (캐릭터) 정의
///
/// UI 레이어에서 간단하게 사용하기 위한 Enum
/// 실제 AI 프롬프트는 AI/jina/personas/ 폴더의 PersonaBase에서 관리됨
///
/// ## 모듈화 설계
/// - UI: 이 enum 사용 (4개 선택지)
/// - AI: PersonaRegistry의 PersonaBase 사용 (상세 프롬프트)
/// - 연결: personaId getter로 매핑
///
/// ## Jina 팀원 안내
/// 새 페르소나 추가 시:
/// 1. AI/jina/personas/ 폴더에 PersonaBase 상속 클래스 생성
/// 2. PersonaRegistry에 등록
/// 3. 이 enum에 값 추가 + personaId 매핑
enum AiPersona {
  grandma,
  master,
  cute,
  professional,
  babyMonk,
  scenarioWriter,
  newbieShaman;

  /// PersonaRegistry ID 매핑
  ///
  /// AI/jina/personas/ 폴더의 PersonaBase.id와 매핑
  String get personaId {
    switch (this) {
      case AiPersona.grandma:
        return 'grandma';
      case AiPersona.master:
        return 'wise_scholar';
      case AiPersona.cute:
        return 'cute_friend';
      case AiPersona.professional:
        return 'friendly_sister';
      case AiPersona.babyMonk:
        return 'baby_monk';
      case AiPersona.scenarioWriter:
        return 'saju_scenario_builder';
      case AiPersona.newbieShaman:
        return 'newbie_shaman';
    }
  }

  /// PersonaBase 인스턴스 가져오기
  PersonaBase get persona => PersonaRegistry.getByIdOrDefault(personaId);

  /// 표시명
  String get displayName {
    switch (this) {
      case AiPersona.grandma:
        return '점순이 할머니';
      case AiPersona.master:
        return '청운 도사';
      case AiPersona.cute:
        return '복돌이';
      case AiPersona.professional:
        return 'AI 상담사';
      case AiPersona.babyMonk:
        return '아기동자';
      case AiPersona.scenarioWriter:
        return '송작가';
      case AiPersona.newbieShaman:
        return '하꼬무당(장비장군)';
    }
  }

  /// 이모지 아이콘
  String get emoji {
    switch (this) {
      case AiPersona.grandma:
        return '👵';
      case AiPersona.master:
        return '🧙';
      case AiPersona.cute:
        return '🐱';
      case AiPersona.professional:
        return '🔮';
      case AiPersona.babyMonk:
        return '👶';
      case AiPersona.scenarioWriter:
        return '🗣️';
      case AiPersona.newbieShaman:
        return '😱';
    }
  }

  /// 짧은 설명
  String get description {
    switch (this) {
      case AiPersona.grandma:
        return '따뜻하고 정감있는 말투';
      case AiPersona.master:
        return '위엄있고 철학적인 말투';
      case AiPersona.cute:
        return '귀엽고 친근한 말투';
      case AiPersona.professional:
        return '전문적이고 정중한 말투';
      case AiPersona.babyMonk:
        return '반말과 팩폭, 꼬마도사';
      case AiPersona.scenarioWriter:
        return '사주 스토리텔러';
      case AiPersona.newbieShaman:
        return '장비장군이 오셨다';
    }
  }

  /// 시스템 프롬프트 (PersonaRegistry에서 가져옴)
  ///
  /// PersonaBase.buildFullSystemPrompt()를 사용하여
  /// 공통 규칙(마크다운 금지 등)이 자동 적용됨
  String get systemPromptInstruction => persona.buildFullSystemPrompt();

  /// 문자열에서 변환
  static AiPersona fromString(String? value) {
    switch (value) {
      case 'grandma':
        return AiPersona.grandma;
      case 'master':
        return AiPersona.master;
      case 'cute':
        return AiPersona.cute;
      case 'professional':
        return AiPersona.professional;
      case 'babyMonk':
        return AiPersona.babyMonk;
      case 'scenarioWriter':
        return AiPersona.scenarioWriter;
      case 'newbieShaman':
        return AiPersona.newbieShaman;
      default:
        return AiPersona.professional;
    }
  }
}
