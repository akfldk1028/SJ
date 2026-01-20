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
        return '감성형';
      case MbtiQuadrant.NT:
        return '분석형';
      case MbtiQuadrant.SF:
        return '친근형';
      case MbtiQuadrant.ST:
        return '현실형';
    }
  }

  /// 설명
  String get description {
    switch (this) {
      case MbtiQuadrant.NF:
        return '따뜻하고 공감적인 상담';
      case MbtiQuadrant.NT:
        return '논리적이고 체계적인 분석';
      case MbtiQuadrant.SF:
        return '친근하고 유쾌한 대화';
      case MbtiQuadrant.ST:
        return '직설적이고 현실적인 조언';
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
  saOngJiMa,
  sewerSaju;

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
      case AiPersona.saOngJiMa:
        return 'sa_ong_ji_ma';
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
      case AiPersona.bookOfSaju:
        return '명리의 서';
      case AiPersona.saOngJiMa:
        return '새옹지마 할배';
      case AiPersona.sewerSaju:
        return '시궁창 술사';
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
      case AiPersona.saOngJiMa:
        return '👴';
      case AiPersona.sewerSaju:
        return '🤮';
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
      case AiPersona.bookOfSaju:
        return '살아있는 사주 고서';
      case AiPersona.saOngJiMa:
        return '긍정 재해석 전문가';
      case AiPersona.sewerSaju:
        return '네 사주의 구린내를 맡아주는 팩폭 장인';
    }
  }

  /// MBTI 4분면 (성향 분류)
  ///
  /// - NF: 감성형 (따뜻, 공감) - 할머니, 아기동자, 새옹지마
  /// - NT: 분석형 (논리, 체계) - 도사, 명리의서, AI상담사
  /// - SF: 친근형 (유쾌, 친근) - 복돌이
  /// - ST: 현실형 (직설, 스토리) - 송작가, 시궁창술사
  MbtiQuadrant get quadrant {
    switch (this) {
      // NF: 감성형 - 따뜻함, 공감, 감성적
      case AiPersona.grandma:      // 따뜻하고 정감있는
      case AiPersona.babyMonk:     // 귀여운 팩폭
      case AiPersona.saOngJiMa:    // 긍정 재해석
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

  /// 분면별 페르소나 목록 가져오기
  static List<AiPersona> getByQuadrant(MbtiQuadrant quadrant) {
    return AiPersona.values.where((p) => p.quadrant == quadrant).toList();
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
      case 'saOngJiMa':
        return AiPersona.saOngJiMa;
      case 'sewerSaju':
        return AiPersona.sewerSaju;
      default:
        return AiPersona.professional;
    }
  }
}
