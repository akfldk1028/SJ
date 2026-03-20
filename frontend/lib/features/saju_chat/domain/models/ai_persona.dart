import 'package:easy_localization/easy_localization.dart';
import '../../../../AI/jina/personas/persona_registry.dart';
import '../../../../AI/jina/personas/persona_base.dart';

/// MBTI 4분면 (성향 분류)
///
/// ```
///        N (직관)
///        │
///   NF   │   NT
/// (감성형) │ (분석형)
///        │
/// F ─────┼───── T
///        │
///   SF   │   ST
/// (친근형) │ (현실형)
///
/// ㅎㅎㅎㅎㅎㅎㅎㅎㅎㅎㄴㅇㅎㄴㅇ
///        │
///        S (감각)
/// ```
enum MbtiQuadrant {
  /// NF: 감성형 - 따뜻함, 공감, 직관적 감성
  NF,
  /// NT: 분석형 - 논리적, 체계적, 직관적 사고
  NT,
  /// SF: 친근형 - 유쾌함, 현실적, 감성적
  SF,
  /// ST: 현실형 - 직설적, 실용적, 논리적
  ST;

  /// 표시명
  String get displayName {
    switch (this) {
      case MbtiQuadrant.NF:
        return 'saju_chat.mbti_NF'.tr();
      case MbtiQuadrant.NT:
        return 'saju_chat.mbti_NT'.tr();
      case MbtiQuadrant.SF:
        return 'saju_chat.mbti_SF'.tr();
      case MbtiQuadrant.ST:
        return 'saju_chat.mbti_ST'.tr();
    }
  }

  /// 설명
  String get description {
    switch (this) {
      case MbtiQuadrant.NF:
        return 'saju_chat.mbti_NF_desc'.tr();
      case MbtiQuadrant.NT:
        return 'saju_chat.mbti_NT_desc'.tr();
      case MbtiQuadrant.SF:
        return 'saju_chat.mbti_SF_desc'.tr();
      case MbtiQuadrant.ST:
        return 'saju_chat.mbti_ST_desc'.tr();
    }
  }
}

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
  bookOfSaju,
  yinYangGrandpa,
  sewerSaju;

  /// UI에서 숨길 페르소나 여부
  bool get isHidden {
    switch (this) {
      case AiPersona.scenarioWriter:
        return true; // 송작가 - 사용 안함
      default:
        return false;
    }
  }

  /// UI에 표시할 페르소나 목록 (isHidden=false만)
  static List<AiPersona> get visibleValues =>
      AiPersona.values.where((p) => !p.isHidden).toList();

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
      case AiPersona.bookOfSaju:
        return 'book_of_saju';
      case AiPersona.yinYangGrandpa:
        return 'yin_yang_grandpa';
      case AiPersona.sewerSaju:
        return 'sewer_saju';
    }
  }

  /// PersonaBase 인스턴스 가져오기
  PersonaBase get persona => PersonaRegistry.getByIdOrDefault(personaId);

  /// 표시명
  String get displayName {
    switch (this) {
      case AiPersona.grandma:
        return 'saju_chat.persona_grandma'.tr();
      case AiPersona.master:
        return 'saju_chat.persona_master'.tr();
      case AiPersona.cute:
        return 'saju_chat.persona_cute'.tr();
      case AiPersona.professional:
        return 'saju_chat.persona_professional'.tr();
      case AiPersona.babyMonk:
        return 'saju_chat.persona_babyMonk'.tr();
      case AiPersona.scenarioWriter:
        return 'saju_chat.persona_scenarioWriter'.tr();
      case AiPersona.bookOfSaju:
        return 'saju_chat.persona_bookOfSaju'.tr();
      case AiPersona.yinYangGrandpa:
        return 'saju_chat.persona_yinYangGrandpa'.tr();
      case AiPersona.sewerSaju:
        return 'saju_chat.persona_sewerSaju'.tr();
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
      case AiPersona.bookOfSaju:
        return '📜';
      case AiPersona.yinYangGrandpa:
        return '☯️';
      case AiPersona.sewerSaju:
        return '🤮';
    }
  }

  /// 짧은 설명
  String get description {
    switch (this) {
      case AiPersona.grandma:
        return 'saju_chat.persona_grandma_desc'.tr();
      case AiPersona.master:
        return 'saju_chat.persona_master_desc'.tr();
      case AiPersona.cute:
        return 'saju_chat.persona_cute_desc'.tr();
      case AiPersona.professional:
        return 'saju_chat.persona_professional_desc'.tr();
      case AiPersona.babyMonk:
        return 'saju_chat.persona_babyMonk_desc'.tr();
      case AiPersona.scenarioWriter:
        return 'saju_chat.persona_scenarioWriter_desc'.tr();
      case AiPersona.bookOfSaju:
        return 'saju_chat.persona_bookOfSaju_desc'.tr();
      case AiPersona.yinYangGrandpa:
        return 'saju_chat.persona_yinYangGrandpa_desc'.tr();
      case AiPersona.sewerSaju:
        return 'saju_chat.persona_sewerSaju_desc'.tr();
    }
  }

  /// MBTI 4분면 (성향 분류)
  ///
  /// - NF: 감성형 (따뜻, 공감) - 할머니, 아기동자, 음양할배
  /// - NT: 분석형 (논리, 체계) - 도사, 명리의서, AI상담사
  /// - SF: 친근형 (유쾌, 친근) - 복돌이
  /// - ST: 현실형 (직설, 스토리) - 송작가, 시궁창술사
  MbtiQuadrant get quadrant {
    switch (this) {
      // NF: 감성형 - 따뜻함, 공감, 감성적
      case AiPersona.grandma:      // 따뜻하고 정감있는
      case AiPersona.babyMonk:     // 귀여운 팩폭
      case AiPersona.yinYangGrandpa: // 음양 반전
        return MbtiQuadrant.NF;

      // NT: 분석형 - 논리적, 체계적
      case AiPersona.master:       // 위엄있고 철학적
      case AiPersona.bookOfSaju:   // 사주 고서, 논리적
      case AiPersona.professional: // AI 상담사, 체계적
        return MbtiQuadrant.NT;

      // SF: 친근형 - 유쾌함, 친근함
      case AiPersona.cute:         // 복돌이, 귀엽고 친근
        return MbtiQuadrant.SF;

      // ST: 현실형 - 직설적, 스토리텔링, 팩트폭격
      case AiPersona.scenarioWriter: // 송작가, 스토리텔러
      case AiPersona.sewerSaju:      // 시궁창 술사, 팩폭
        return MbtiQuadrant.ST;
    }
  }

  /// 분면별 페르소나 목록 가져오기 (숨김 제외)
  static List<AiPersona> getByQuadrant(MbtiQuadrant quadrant) {
    return AiPersona.visibleValues.where((p) => p.quadrant == quadrant).toList();
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
      case 'bookOfSaju':
        return AiPersona.bookOfSaju;
      case 'yinYangGrandpa':
      case 'saOngJiMa': // 하위 호환
        return AiPersona.yinYangGrandpa;
      case 'sewerSaju':
        return AiPersona.sewerSaju;
      default:
        return AiPersona.professional;
    }
  }
}
