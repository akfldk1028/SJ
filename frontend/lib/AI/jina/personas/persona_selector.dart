/// # 페르소나 선택 로직
///
/// ## 개요
/// 사용자 선호도나 상황에 따라 적절한 페르소나를 선택합니다.
///
/// ## 파일 위치
/// `frontend/lib/AI/jina/personas/persona_selector.dart`
///
/// ## 담당: Jina
///
/// ## 선택 로직
/// 1. 사용자 저장 선호도 확인
/// 2. 상황별 자동 추천 (옵션)
/// 3. 기본 페르소나 반환
///
/// ## 사용 예시
/// ```dart
/// // 사용자 선호도 기반
/// final persona = PersonaSelector.getForUser(userId);
///
/// // 특정 페르소나 선택
/// final persona = PersonaSelector.getById('wise_scholar');
///
/// // 기본 페르소나
/// final persona = PersonaSelector.defaultPersona;
/// ```

import 'persona_base.dart';
import 'persona_registry.dart';

/// 페르소나 선택기
///
/// 상황과 사용자 선호도에 따라 적절한 페르소나를 선택합니다.
class PersonaSelector {
  PersonaSelector._();

  // ═══════════════════════════════════════════════════════════════════════════
  // 기본 선택
  // ═══════════════════════════════════════════════════════════════════════════

  /// 기본 페르소나
  static PersonaBase get defaultPersona => PersonaRegistry.defaultPersona;

  /// ID로 페르소나 선택
  ///
  /// [id] 페르소나 ID (예: 'cute_friend')
  /// 반환: 해당 페르소나 또는 기본 페르소나
  static PersonaBase getById(String id) {
    return PersonaRegistry.getByIdOrDefault(id);
  }

  /// 모든 페르소나 목록
  static List<PersonaBase> get all => PersonaRegistry.all;

  // ═══════════════════════════════════════════════════════════════════════════
  // 상황별 추천
  // ═══════════════════════════════════════════════════════════════════════════

  /// 나이대별 추천 페르소나
  ///
  /// [age] 사용자 나이
  /// 반환: 추천 페르소나
  static PersonaBase getForAge(int age) {
    if (age < 25) {
      // 젊은 유저: 귀여운 친구
      return PersonaRegistry.getByIdOrDefault('cute_friend');
    } else if (age < 40) {
      // 20-30대: 친근한 언니
      return PersonaRegistry.getByIdOrDefault('friendly_sister');
    } else {
      // 40대 이상: 현명한 학자
      return PersonaRegistry.getByIdOrDefault('wise_scholar');
    }
  }

  /// 주제별 추천 페르소나
  ///
  /// [topic] 대화 주제
  /// 반환: 추천 페르소나
  static PersonaBase getForTopic(String topic) {
    final lowerTopic = topic.toLowerCase();

    // 진지한 분석 주제
    if (lowerTopic.contains('사주') ||
        lowerTopic.contains('분석') ||
        lowerTopic.contains('상세')) {
      return PersonaRegistry.getByIdOrDefault('wise_scholar');
    }

    // 연애/감정 주제
    if (lowerTopic.contains('연애') ||
        lowerTopic.contains('사랑') ||
        lowerTopic.contains('인연')) {
      return PersonaRegistry.getByIdOrDefault('cute_friend');
    }

    // 고민/조언 주제
    if (lowerTopic.contains('고민') ||
        lowerTopic.contains('힘들') ||
        lowerTopic.contains('조언')) {
      return PersonaRegistry.getByIdOrDefault('friendly_sister');
    }

    // 기본값
    return defaultPersona;
  }

  /// 카테고리별 페르소나 목록
  static List<PersonaBase> getByCategory(PersonaCategory category) {
    return PersonaRegistry.getByCategory(category);
  }

  /// 말투별 페르소나 목록
  static List<PersonaBase> getByTone(PersonaTone tone) {
    return PersonaRegistry.getByTone(tone);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 사용자 선호도 (향후 구현)
  // ═══════════════════════════════════════════════════════════════════════════

  // TODO: 사용자별 페르소나 선호도 저장/조회
  // - Hive에 선호도 저장
  // - 사용 빈도 기반 추천
  // - A/B 테스트 지원

  /// 사용자별 선호 페르소나 조회
  ///
  /// [userId] 사용자 ID
  /// 반환: 저장된 선호 페르소나 또는 기본값
  static PersonaBase getForUser(String userId) {
    // TODO: 사용자 선호도 조회 구현
    // final savedId = await _getUserPreference(userId);
    // if (savedId != null) {
    //   return PersonaRegistry.getByIdOrDefault(savedId);
    // }
    return defaultPersona;
  }

  /// 사용자 선호 페르소나 저장
  ///
  /// [userId] 사용자 ID
  /// [personaId] 선호 페르소나 ID
  static Future<void> saveUserPreference(
      String userId, String personaId) async {
    // TODO: Hive에 저장 구현
    // await _hive.put(userId, personaId);
  }
}
