/// # 페르소나 레지스트리
///
/// ## 개요
/// 모든 페르소나를 중앙에서 관리하는 레지스트리 시스템입니다.
/// 새 페르소나 추가 시 이 파일에만 등록하면 됩니다.
///
/// ## 파일 위치
/// `frontend/lib/AI/jina/personas/persona_registry.dart`
///
/// ## 담당: Jina
///
/// ## 새 페르소나 추가 방법
/// 1. `personas/` 폴더에 새 페르소나 클래스 생성
/// 2. 이 파일 import 추가
/// 3. `_allPersonas` 리스트에 인스턴스 추가
///
/// ## 사용 예시
/// ```dart
/// // ID로 페르소나 가져오기
/// final persona = PersonaRegistry.getById('cute_friend');
///
/// // 모든 페르소나 목록
/// final all = PersonaRegistry.all;
///
/// // 카테고리별 페르소나
/// final friends = PersonaRegistry.getByCategory(PersonaCategory.friend);
/// ```

import 'cute_friend.dart';
import 'friendly_sister.dart';
import 'grandma.dart';
import 'persona_base.dart';
import 'wise_scholar.dart';
import 'baby_monk.dart';
import 'scenario_writer.dart';
import 'newbie_shaman.dart';

/// 페르소나 레지스트리
///
/// 모든 페르소나를 중앙에서 관리합니다.
/// 싱글톤 패턴으로 구현되어 있습니다.
class PersonaRegistry {
  PersonaRegistry._();

  // ═══════════════════════════════════════════════════════════════════════════
  // 페르소나 등록 (새 페르소나 추가 시 여기에 추가!)
  // ═══════════════════════════════════════════════════════════════════════════

  /// 등록된 모든 페르소나 인스턴스
  ///
  /// **새 페르소나 추가 시 여기에 인스턴스를 추가하세요!**
  static final List<PersonaBase> _allPersonas = [
    FriendlySisterPersona(), // 기본 페르소나
    CuteFriendPersona(),
    WiseScholarPersona(),
    GrandmaPersona(),
    BabyMonkPersona(),
    SajuScenarioBuilderPersona(),
    NewbieShamanPersona(),
  ];

  /// 기본 페르소나 ID
  static const String defaultPersonaId = 'friendly_sister';

  // ═══════════════════════════════════════════════════════════════════════════
  // 조회 API
  // ═══════════════════════════════════════════════════════════════════════════

  /// 모든 페르소나 목록
  static List<PersonaBase> get all => List.unmodifiable(_allPersonas);

  /// 기본 페르소나
  static PersonaBase get defaultPersona =>
      getById(defaultPersonaId) ?? _allPersonas.first;

  /// ID로 페르소나 조회
  ///
  /// [id] 페르소나 고유 ID (예: 'cute_friend')
  /// 반환: 해당 페르소나 또는 null
  static PersonaBase? getById(String id) {
    try {
      return _allPersonas.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  /// ID로 페르소나 조회 (없으면 기본값)
  ///
  /// [id] 페르소나 고유 ID
  /// 반환: 해당 페르소나 또는 기본 페르소나
  static PersonaBase getByIdOrDefault(String id) {
    return getById(id) ?? defaultPersona;
  }

  /// 카테고리별 페르소나 목록
  ///
  /// [category] 페르소나 카테고리
  /// 반환: 해당 카테고리의 페르소나 목록
  static List<PersonaBase> getByCategory(PersonaCategory category) {
    return _allPersonas.where((p) => p.category == category).toList();
  }

  /// 말투별 페르소나 목록
  ///
  /// [tone] 말투 타입
  /// 반환: 해당 말투의 페르소나 목록
  static List<PersonaBase> getByTone(PersonaTone tone) {
    return _allPersonas.where((p) => p.tone == tone).toList();
  }

  /// 키워드로 페르소나 검색
  ///
  /// [keyword] 검색 키워드
  /// 반환: 키워드가 포함된 페르소나 목록
  static List<PersonaBase> searchByKeyword(String keyword) {
    final lowerKeyword = keyword.toLowerCase();
    return _allPersonas.where((p) {
      return p.name.toLowerCase().contains(lowerKeyword) ||
          p.description.toLowerCase().contains(lowerKeyword) ||
          p.keywords.any((k) => k.toLowerCase().contains(lowerKeyword));
    }).toList();
  }

  /// 페르소나 ID 목록
  static List<String> get allIds => _allPersonas.map((p) => p.id).toList();

  /// 카테고리 목록 (등록된 페르소나 기준)
  static List<PersonaCategory> get availableCategories {
    return _allPersonas.map((p) => p.category).toSet().toList();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 유틸리티
  // ═══════════════════════════════════════════════════════════════════════════

  /// 페르소나 개수
  static int get count => _allPersonas.length;

  /// 페르소나가 등록되어 있는지 확인
  static bool hasPersona(String id) {
    return _allPersonas.any((p) => p.id == id);
  }

  /// 레지스트리 정보 출력 (디버깅용)
  static String get debugInfo {
    final buffer = StringBuffer('PersonaRegistry:\n');
    buffer.writeln('  Total: $count personas');
    buffer.writeln('  Default: $defaultPersonaId');
    buffer.writeln('  Registered:');
    for (final p in _allPersonas) {
      buffer.writeln('    - ${p.id}: ${p.name} (${p.category.displayName})');
    }
    return buffer.toString();
  }
}
