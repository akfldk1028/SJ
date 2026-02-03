import 'package:flutter/material.dart';
import '../../../../AI/jina/personas/persona_registry.dart';
import '../../../../AI/jina/personas/persona_base.dart';
import 'ai_persona.dart' show MbtiQuadrant;

/// 채팅 페르소나 타입
///
/// - mbtiPersona: MBTI 기반 기본 페르소나 (4종)
/// - specialCharacter: 고정된 특수 캐릭터
enum ChatPersonaType {
  basePerson, // 레거시 호환
  mbtiPersona,
  specialCharacter,
}

/// 채팅 페르소나 (통합)
///
/// 대화창에서 선택하는 7개 페르소나:
/// - MBTI 4종: 감성형(NF), 분석형(NT), 친근형(SF), 현실형(ST)
/// - 특수 캐릭터 3종: 아기동자, 새옹지마, 시궁창 술사
///
/// ## 구조
/// ```
/// ┌──────────────────────────────────────────────┐
/// │  대화창 상단 페르소나 선택기                    │
/// │  [감성형] [분석형] [친근형] [현실형]            │
/// │  [아기동자] [새옹지마] [시궁창]                 │
/// └──────────────────────────────────────────────┘
/// ```
enum ChatPersona {
  /// [레거시] BasePerson - 기존 세션 호환용 (UI에서 숨김)
  basePerson,

  /// 감성형 (NF) - 따뜻하고 공감적인 상담
  nfSensitive,

  /// 분석형 (NT) - 논리적이고 체계적인 분석
  ntAnalytic,

  /// 친근형 (SF) - 친근하고 유쾌한 대화
  sfFriendly,

  /// 현실형 (ST) - 직설적이고 현실적인 조언
  stRealistic,

  /// 아기동자 - 반말과 팩폭, 꼬마도사
  babyMonk,

  /// 송작가 - 스토리텔링 전문 캐릭터 (숨김)
  scenarioWriter,

  /// 새옹지마 - 긍정 재해석 전문가
  saOngJiMa,

  /// 시궁창 술사 - 팩폭 장인
  sewerSaju;

  /// UI에서 숨길 페르소나 여부
  bool get isHidden {
    switch (this) {
      case ChatPersona.basePerson:
        return true; // 레거시 - UI에서 숨김
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
    switch (this) {
      case ChatPersona.basePerson:
        return ChatPersonaType.basePerson;
      case ChatPersona.nfSensitive:
      case ChatPersona.ntAnalytic:
      case ChatPersona.sfFriendly:
      case ChatPersona.stRealistic:
        return ChatPersonaType.mbtiPersona;
      default:
        return ChatPersonaType.specialCharacter;
    }
  }

  /// MBTI 페르소나 여부
  bool get isMbtiPersona => type == ChatPersonaType.mbtiPersona;

  /// MBTI 조절 가능 여부 (레거시 호환 - MBTI 페르소나는 이미 고정된 MBTI를 가짐)
  bool get canAdjustMbti => this == ChatPersona.basePerson;

  /// MBTI 분면 매핑 (MBTI 페르소나용)
  MbtiQuadrant? get mbtiQuadrant {
    switch (this) {
      case ChatPersona.nfSensitive:
        return MbtiQuadrant.NF;
      case ChatPersona.ntAnalytic:
        return MbtiQuadrant.NT;
      case ChatPersona.sfFriendly:
        return MbtiQuadrant.SF;
      case ChatPersona.stRealistic:
        return MbtiQuadrant.ST;
      default:
        return null;
    }
  }

  /// MbtiQuadrant에서 ChatPersona로 변환
  static ChatPersona fromMbtiQuadrant(MbtiQuadrant quadrant) {
    switch (quadrant) {
      case MbtiQuadrant.NF:
        return ChatPersona.nfSensitive;
      case MbtiQuadrant.NT:
        return ChatPersona.ntAnalytic;
      case MbtiQuadrant.SF:
        return ChatPersona.sfFriendly;
      case MbtiQuadrant.ST:
        return ChatPersona.stRealistic;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // [TODO] XY축 기반 MBTI 16타입 → 페르소나 자동 선택 (향후 구현)
  // ═══════════════════════════════════════════════════════════════════════════
  //
  // MbtiAxisSelector의 XY좌표(-1~1)를 16개 MBTI 타입으로 세분화하고,
  // 각 타입에 맞는 ChatPersona를 자동 선택하는 기능.
  //
  // ## 구조
  // ```
  //        N (직관)
  //        │
  //   INFP  INFJ │ INTJ  INTP
  //   ENFP  ENFJ │ ENTJ  ENTP
  // F ───────────●─────────── T
  //   ESFP  ESFJ │ ESTJ  ESTP
  //   ISFP  ISFJ │ ISTJ  ISTP
  //        │
  //        S (감각)
  // ```
  //
  // ## XY좌표 → 16타입 매핑 로직
  // - X축: F(-1) ↔ T(+1) (감정 vs 사고)
  // - Y축: N(-1) ↔ S(+1) (직관 vs 감각)
  // - 각 분면을 4등분 → 16개 영역
  //   - E/I: |x| 기준 (중심 가까우면 I, 멀면 E)
  //   - J/P: |y| 기준 (중심 가까우면 P, 멀면 J)
  //
  // ## 16타입 → ChatPersona 매핑 (예시)
  // ```dart
  // static ChatPersona fromMbti16Type(String mbtiType) {
  //   // NF 그룹 → 감성형
  //   if (['INFP', 'INFJ', 'ENFP', 'ENFJ'].contains(mbtiType)) {
  //     return ChatPersona.nfSensitive;
  //   }
  //   // NT 그룹 → 분석형
  //   if (['INTP', 'INTJ', 'ENTP', 'ENTJ'].contains(mbtiType)) {
  //     return ChatPersona.ntAnalytic;
  //   }
  //   // SF 그룹 → 친근형
  //   if (['ISFP', 'ISFJ', 'ESFP', 'ESFJ'].contains(mbtiType)) {
  //     return ChatPersona.sfFriendly;
  //   }
  //   // ST 그룹 → 현실형
  //   if (['ISTP', 'ISTJ', 'ESTP', 'ESTJ'].contains(mbtiType)) {
  //     return ChatPersona.stRealistic;
  //   }
  //   return ChatPersona.nfSensitive;
  // }
  //
  // /// XY좌표(-1~1)로부터 16타입 MBTI 문자열 반환
  // static String getMbti16TypeFromPosition(double x, double y) {
  //   // 1) N vs S (y축: 음수=N, 양수=S)
  //   final ns = y < 0 ? 'N' : 'S';
  //   // 2) F vs T (x축: 음수=F, 양수=T)
  //   final ft = x < 0 ? 'F' : 'T';
  //   // 3) E vs I (중심에서의 거리: 가까우면 I, 멀면 E)
  //   final ei = x.abs() > 0.5 ? 'E' : 'I';
  //   // 4) J vs P (중심에서의 거리: 가까우면 P, 멀면 J)
  //   final jp = y.abs() > 0.5 ? 'J' : 'P';
  //   return '$ei$ns$ft$jp'; // e.g. "INFP", "ESTJ"
  // }
  //
  // /// XY좌표로부터 ChatPersona 자동 선택
  // static ChatPersona fromXYPosition(double x, double y) {
  //   final mbtiType = getMbti16TypeFromPosition(x, y);
  //   return fromMbti16Type(mbtiType);
  // }
  // ```
  //
  // ## 사용법 (MbtiAxisSelector 연동)
  // ```dart
  // MbtiAxisSelector(
  //   onQuadrantSelected: (quadrant) {
  //     // 기존: 4분면만 선택
  //   },
  //   // 향후: onPositionChanged 콜백 추가
  //   // onPositionChanged: (x, y) {
  //   //   final mbtiType = ChatPersona.getMbti16TypeFromPosition(x, y);
  //   //   final persona = ChatPersona.fromMbti16Type(mbtiType);
  //   //   ref.read(chatPersonaNotifierProvider.notifier).setPersona(persona);
  //   //   // UI에 현재 MBTI 타입 표시: "INFP - 감성형"
  //   // },
  // )
  // ```
  // ═══════════════════════════════════════════════════════════════════════════

  /// PersonaRegistry ID 매핑
  String get personaId {
    switch (this) {
      case ChatPersona.basePerson:
        return 'base_person';
      case ChatPersona.nfSensitive:
        return 'base_nf';
      case ChatPersona.ntAnalytic:
        return 'base_nt';
      case ChatPersona.sfFriendly:
        return 'base_sf';
      case ChatPersona.stRealistic:
        return 'base_st';
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

  /// PersonaBase 인스턴스 가져오기
  PersonaBase? get persona {
    return PersonaRegistry.getById(personaId);
  }

  /// 표시명
  String get displayName {
    switch (this) {
      case ChatPersona.basePerson:
        return '기본'; // 레거시
      case ChatPersona.nfSensitive:
        return '감성형';
      case ChatPersona.ntAnalytic:
        return '분석형';
      case ChatPersona.sfFriendly:
        return '친근형';
      case ChatPersona.stRealistic:
        return '현실형';
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

  /// 이모지 아이콘 (레거시)
  String get emoji {
    switch (this) {
      case ChatPersona.basePerson:
        return '🎭';
      case ChatPersona.nfSensitive:
        return '💗';
      case ChatPersona.ntAnalytic:
        return '🔬';
      case ChatPersona.sfFriendly:
        return '😊';
      case ChatPersona.stRealistic:
        return '💪';
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
        return Icons.person_outline_rounded;
      case ChatPersona.nfSensitive:
        return Icons.favorite_rounded; // 하트 - 감성
      case ChatPersona.ntAnalytic:
        return Icons.psychology_rounded; // 뇌 - 분석
      case ChatPersona.sfFriendly:
        return Icons.emoji_emotions_rounded; // 웃는 얼굴 - 친근
      case ChatPersona.stRealistic:
        return Icons.gavel_rounded; // 망치 - 현실/직설
      case ChatPersona.babyMonk:
        return Icons.face_rounded;
      case ChatPersona.scenarioWriter:
        return Icons.edit_note_rounded;
      case ChatPersona.saOngJiMa:
        return Icons.spa_rounded;
      case ChatPersona.sewerSaju:
        return Icons.bolt_rounded;
    }
  }

  /// 짧은 이름 (UI 표시용)
  String get shortName {
    switch (this) {
      case ChatPersona.basePerson:
        return '기본';
      case ChatPersona.nfSensitive:
        return '감성형';
      case ChatPersona.ntAnalytic:
        return '분석형';
      case ChatPersona.sfFriendly:
        return '친근형';
      case ChatPersona.stRealistic:
        return '현실형';
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
        return '기본 상담';
      case ChatPersona.nfSensitive:
        return '따뜻하고 공감적인 상담';
      case ChatPersona.ntAnalytic:
        return '논리적이고 체계적인 분석';
      case ChatPersona.sfFriendly:
        return '친근하고 유쾌한 대화';
      case ChatPersona.stRealistic:
        return '직설적이고 현실적인 조언';
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
        return '기본 AI 상담사입니다.';
      case ChatPersona.nfSensitive:
        return '따뜻하고 공감적인 감성형 상담사입니다.\n\n당신의 마음을 먼저 읽고, 사주 풀이에 따뜻한 감성을 담아 전달합니다. 위로와 공감이 필요할 때 추천합니다.';
      case ChatPersona.ntAnalytic:
        return '논리적이고 체계적인 분석형 상담사입니다.\n\n오행, 십성, 합충 등 사주 이론을 정확히 분석하여 근거 있는 해석을 제공합니다. 깊이 있는 사주 풀이를 원할 때 추천합니다.';
      case ChatPersona.sfFriendly:
        return '친근하고 유쾌한 친구 같은 상담사입니다.\n\n편하게 대화하며 사주를 쉽고 재미있게 풀어줍니다. 가볍게 사주를 알아보고 싶을 때 추천합니다.';
      case ChatPersona.stRealistic:
        return '직설적이고 현실적인 조언을 해주는 상담사입니다.\n\n돌려 말하지 않고 핵심만 짚어주며, 실용적인 관점에서 사주를 해석합니다. 명쾌한 답을 원할 때 추천합니다.';
      case ChatPersona.babyMonk:
        return '꼬마 도사 아기동자입니다. 반말로 거침없이 사주를 풀어주며, 핵심만 콕콕 짚어주는 팩폭 스타일입니다.\n\n가벼운 분위기에서 솔직한 사주 풀이를 원할 때 추천합니다.';
      case ChatPersona.scenarioWriter:
        return '사주를 하나의 이야기로 풀어내는 스토리텔러입니다.';
      case ChatPersona.saOngJiMa:
        return '새옹지마 할배는 어떤 사주든 긍정적으로 재해석해 주는 전문가입니다.\n\n나쁜 운도 좋게 해석하고, 힘든 시기에도 희망을 찾아줍니다. 위로가 필요할 때 추천합니다.';
      case ChatPersona.sewerSaju:
        return '시궁창 술사는 사주의 안 좋은 면을 거침없이 파헤치는 팩폭 장인입니다.\n\n독설과 사이다 발언으로 현실을 직시하게 해줍니다. 심장이 약하신 분은 주의!';
    }
  }

  /// 시스템 프롬프트
  String? get fixedSystemPrompt {
    final p = persona;
    return p?.buildFullSystemPrompt();
  }

  /// 문자열에서 변환
  static ChatPersona fromString(String? value) {
    switch (value) {
      case 'basePerson':
        return ChatPersona.nfSensitive; // 레거시 → 감성형으로 매핑
      case 'nfSensitive':
        return ChatPersona.nfSensitive;
      case 'ntAnalytic':
        return ChatPersona.ntAnalytic;
      case 'sfFriendly':
        return ChatPersona.sfFriendly;
      case 'stRealistic':
        return ChatPersona.stRealistic;
      case 'babyMonk':
        return ChatPersona.babyMonk;
      case 'scenarioWriter':
        return ChatPersona.scenarioWriter;
      case 'saOngJiMa':
        return ChatPersona.saOngJiMa;
      case 'sewerSaju':
        return ChatPersona.sewerSaju;
      default:
        return ChatPersona.nfSensitive;
    }
  }
}
