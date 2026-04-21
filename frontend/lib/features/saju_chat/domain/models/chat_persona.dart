import 'package:easy_localization/easy_localization.dart';
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
/// - 특수 캐릭터 3종: 아기동자, 음양 할배, 시궁창 술사
///
/// ## 구조
/// ```
/// ┌──────────────────────────────────────────────┐
/// │  대화창 상단 페르소나 선택기                    │
/// │  [감성형] [분석형] [친근형] [현실형]            │
/// │  [아기동자] [음양 할배] [시궁창]                 │
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

  /// 음양 할배 - 어둠 속 빛, 반전의 대가
  yinYangGrandpa,

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
      case ChatPersona.yinYangGrandpa:
        return 'yin_yang_grandpa';
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
        return 'saju_chat.persona_default'.tr();
      case ChatPersona.nfSensitive:
        return 'saju_chat.mbti_NF'.tr();
      case ChatPersona.ntAnalytic:
        return 'saju_chat.mbti_NT'.tr();
      case ChatPersona.sfFriendly:
        return 'saju_chat.mbti_SF'.tr();
      case ChatPersona.stRealistic:
        return 'saju_chat.mbti_ST'.tr();
      case ChatPersona.babyMonk:
        return 'saju_chat.persona_babyMonk'.tr();
      case ChatPersona.scenarioWriter:
        return 'saju_chat.persona_scenarioWriter'.tr();
      case ChatPersona.yinYangGrandpa:
        return 'saju_chat.persona_yinYangGrandpa'.tr();
      case ChatPersona.sewerSaju:
        return 'saju_chat.persona_sewerSaju'.tr();
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
      case ChatPersona.yinYangGrandpa:
        return '☯️';
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
      case ChatPersona.yinYangGrandpa:
        return Icons.contrast_rounded; // 음양 - 대비
      case ChatPersona.sewerSaju:
        return Icons.bolt_rounded;
    }
  }

  /// 짧은 이름 (UI 표시용)
  String get shortName {
    switch (this) {
      case ChatPersona.basePerson:
        return 'saju_chat.persona_default'.tr();
      case ChatPersona.nfSensitive:
        return 'saju_chat.mbti_NF'.tr();
      case ChatPersona.ntAnalytic:
        return 'saju_chat.mbti_NT'.tr();
      case ChatPersona.sfFriendly:
        return 'saju_chat.mbti_SF'.tr();
      case ChatPersona.stRealistic:
        return 'saju_chat.mbti_ST'.tr();
      case ChatPersona.babyMonk:
        return 'saju_chat.persona_babyMonk'.tr();
      case ChatPersona.scenarioWriter:
        return 'saju_chat.persona_scenarioWriter'.tr();
      case ChatPersona.yinYangGrandpa:
        return 'saju_chat.persona_yinYangGrandpa'.tr();
      case ChatPersona.sewerSaju:
        return 'saju_chat.persona_sewerSaju_short'.tr();
    }
  }

  /// 짧은 설명
  String get description {
    switch (this) {
      case ChatPersona.basePerson:
        return 'saju_chat.persona_default_desc'.tr();
      case ChatPersona.nfSensitive:
        return 'saju_chat.mbti_NF_desc'.tr();
      case ChatPersona.ntAnalytic:
        return 'saju_chat.mbti_NT_desc'.tr();
      case ChatPersona.sfFriendly:
        return 'saju_chat.mbti_SF_desc'.tr();
      case ChatPersona.stRealistic:
        return 'saju_chat.mbti_ST_desc'.tr();
      case ChatPersona.babyMonk:
        return 'saju_chat.persona_babyMonk_desc'.tr();
      case ChatPersona.scenarioWriter:
        return 'saju_chat.persona_scenarioWriter_desc'.tr();
      case ChatPersona.yinYangGrandpa:
        return 'saju_chat.persona_yinYangGrandpa_desc'.tr();
      case ChatPersona.sewerSaju:
        return 'saju_chat.persona_sewerSaju_descChat'.tr();
    }
  }

  /// 상세 설명 (페르소나 설명 팝업용)
  String get detailedDescription {
    switch (this) {
      case ChatPersona.basePerson:
        return 'saju_chat.persona_default_detail'.tr();
      case ChatPersona.nfSensitive:
        return 'saju_chat.persona_nf_detail'.tr();
      case ChatPersona.ntAnalytic:
        return 'saju_chat.persona_nt_detail'.tr();
      case ChatPersona.sfFriendly:
        return 'saju_chat.persona_sf_detail'.tr();
      case ChatPersona.stRealistic:
        return 'saju_chat.persona_st_detail'.tr();
      case ChatPersona.babyMonk:
        return 'saju_chat.persona_babyMonk_detail'.tr();
      case ChatPersona.scenarioWriter:
        return 'saju_chat.persona_scenarioWriter_detail'.tr();
      case ChatPersona.yinYangGrandpa:
        return 'saju_chat.persona_yinYangGrandpa_detail'.tr();
      case ChatPersona.sewerSaju:
        return 'saju_chat.persona_sewerSaju_detail'.tr();
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
      case 'yinYangGrandpa':
      case 'saOngJiMa': // 하위 호환
        return ChatPersona.yinYangGrandpa;
      case 'sewerSaju':
        return ChatPersona.sewerSaju;
      default:
        return ChatPersona.nfSensitive;
    }
  }
}
