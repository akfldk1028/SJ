import '../../../../AI/jina/personas/persona_registry.dart';
import '../../../../AI/jina/personas/persona_base.dart';

/// 4개 특수 캐릭터 정의
///
/// MBTI 분면(base 성향)과 조합되는 개성 있는 캐릭터들
/// 4x4 조합: 4 MBTI × 4 캐릭터 = 16가지 AI 성격
///
/// ## 위젯 트리 분리
/// ```
/// ┌─────────────────────────────────────────────┐
/// │  사이드바              │      대화창         │
/// │  ┌───────────────┐    │  ┌──────────────┐  │
/// │  │ MBTI 4축      │    │  │ 🔴 🔵 🟢 🟠 │  │
/// │  │ (base 성향)   │    │  │ (특수 캐릭터) │  │
/// │  │ NF/NT/SF/ST   │    │  │              │  │
/// │  └───────────────┘    │  └──────────────┘  │
/// └─────────────────────────────────────────────┘
/// ```
enum BaseCharacter {
  /// 아기동자 - 반말과 팩폭, 꼬마도사
  babyMonk,

  /// 송작가 - 스토리텔링 전문 캐릭터
  scenarioWriter,

  /// 새옹지마 - 긍정 재해석 전문가
  saOngJiMa;

  /// PersonaRegistry ID 매핑
  String get personaId {
    switch (this) {
      case BaseCharacter.babyMonk:
        return 'baby_monk';
      case BaseCharacter.scenarioWriter:
        return 'saju_scenario_builder';
      case BaseCharacter.saOngJiMa:
        return 'sa_ong_ji_ma';
    }
  }

  /// PersonaBase 인스턴스 가져오기
  PersonaBase get persona => PersonaRegistry.getByIdOrDefault(personaId);

  /// 표시명
  String get displayName {
    switch (this) {
      case BaseCharacter.babyMonk:
        return '아기동자';
      case BaseCharacter.scenarioWriter:
        return '송작가';
      case BaseCharacter.saOngJiMa:
        return '새옹지마';
    }
  }

  /// 이모지 아이콘 (원래 캐릭터 이모지)
  String get emoji {
    switch (this) {
      case BaseCharacter.babyMonk:
        return '👶';
      case BaseCharacter.scenarioWriter:
        return '🗣️';
      case BaseCharacter.saOngJiMa:
        return '👴';
    }
  }

  /// 짧은 설명
  String get description {
    switch (this) {
      case BaseCharacter.babyMonk:
        return '반말과 팩폭, 꼬마도사';
      case BaseCharacter.scenarioWriter:
        return '사주 스토리텔러';
      case BaseCharacter.saOngJiMa:
        return '긍정 재해석 전문가';
    }
  }

  /// 기본 시스템 프롬프트 (MBTI modifier 없이)
  ///
  /// MBTI modifier는 별도로 추가됨
  String get baseSystemPrompt => persona.buildFullSystemPrompt();

  /// 문자열에서 변환
  static BaseCharacter fromString(String? value) {
    switch (value) {
      case 'babyMonk':
        return BaseCharacter.babyMonk;
      case 'scenarioWriter':
        return BaseCharacter.scenarioWriter;
      case 'saOngJiMa':
        return BaseCharacter.saOngJiMa;
      default:
        return BaseCharacter.babyMonk;
    }
  }
}
