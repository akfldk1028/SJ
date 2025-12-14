/// RuleEngine - Repository 인터페이스
///
/// Phase 10-A: 기반 구축
/// 룰 로딩/저장/검증을 위한 Repository 추상화
///
/// 설계 원칙:
/// - 인터페이스는 완성형 (확장 대비)
/// - MVP 구현: loadFromAsset()만 우선 구현
/// - Phase 10-D: loadFromRemote() 추가 예정
library;

import '../entities/rule.dart';
import '../entities/compiled_rules.dart';

// ============================================================================
// Repository 인터페이스
// ============================================================================

/// 룰 저장소 인터페이스
///
/// 책임:
/// 1. JSON 룰 파일 로드 (Asset, Remote)
/// 2. 룰 검증 (Validator 위임)
/// 3. 룰 컴파일 (파싱 + 캐싱)
/// 4. 버전 관리
abstract class RuleRepository {
  // ============================================================================
  // 로드 메서드
  // ============================================================================

  /// Asset에서 룰 로드 (MVP - 필수 구현)
  ///
  /// [assetPath] assets/ 하위 경로 (예: "data/rules/sinsal_rules.json")
  /// 반환: 컴파일된 룰셋
  /// 예외: RuleLoadException (파일 없음, 파싱 실패, 검증 실패)
  Future<CompiledRules> loadFromAsset(String assetPath);

  /// 원격에서 룰 로드 (Phase 10-D - 추후 구현)
  ///
  /// [url] 원격 JSON URL
  /// [validateHash] SHA256 해시 검증 여부
  /// 반환: 컴파일된 룰셋
  Future<CompiledRules> loadFromRemote(String url, {bool validateHash = true});

  /// JSON 문자열에서 직접 로드
  ///
  /// [jsonString] JSON 룰 문자열
  /// [source] 소스 식별자 (디버깅용)
  Future<CompiledRules> loadFromString(String jsonString, {String? source});

  // ============================================================================
  // 타입별 로드 (편의 메서드)
  // ============================================================================

  /// 특정 RuleType의 기본 룰 로드
  ///
  /// 기본 경로 규칙: "data/rules/{type}_rules.json"
  Future<CompiledRules> loadByType(RuleType type);

  /// 여러 타입 룰 일괄 로드
  Future<List<CompiledRules>> loadMultipleTypes(List<RuleType> types);

  // ============================================================================
  // 캐시 관리
  // ============================================================================

  /// 캐시된 룰 조회
  CompiledRules? getCached(RuleType type);

  /// 캐시에 룰 저장
  void setCache(RuleType type, CompiledRules rules);

  /// 특정 타입 캐시 무효화
  void invalidateCache(RuleType type);

  /// 전체 캐시 초기화
  void clearCache();

  // ============================================================================
  // 버전 관리 (Phase 10-D)
  // ============================================================================

  /// 로컬 룰 버전 조회
  Future<String?> getLocalVersion(RuleType type);

  /// 원격 룰 버전 조회
  Future<String?> getRemoteVersion(RuleType type);

  /// 업데이트 필요 여부 확인
  Future<bool> needsUpdate(RuleType type);

  // ============================================================================
  // 유틸리티
  // ============================================================================

  /// 지원하는 RuleType 목록
  List<RuleType> get supportedTypes;

  /// 현재 로드된 룰 통계
  Map<RuleType, int> get loadedRuleCounts;
}

// ============================================================================
// 예외 클래스
// ============================================================================

/// 룰 로드 관련 예외
class RuleLoadException implements Exception {
  final String message;
  final String? source;
  final Object? cause;

  const RuleLoadException(this.message, {this.source, this.cause});

  @override
  String toString() {
    var result = 'RuleLoadException: $message';
    if (source != null) result += ' (source: $source)';
    if (cause != null) result += '\nCaused by: $cause';
    return result;
  }
}

/// 룰 검증 실패 예외
class RuleValidationException implements Exception {
  final String message;
  final List<String> errors;
  final String? ruleId;

  const RuleValidationException(
    this.message, {
    this.errors = const [],
    this.ruleId,
  });

  @override
  String toString() {
    var result = 'RuleValidationException: $message';
    if (ruleId != null) result += ' (rule: $ruleId)';
    if (errors.isNotEmpty) result += '\nErrors:\n  - ${errors.join('\n  - ')}';
    return result;
  }
}

/// 룰 컴파일 실패 예외
class RuleCompileException implements Exception {
  final String message;
  final String? ruleId;
  final Object? cause;

  const RuleCompileException(this.message, {this.ruleId, this.cause});

  @override
  String toString() {
    var result = 'RuleCompileException: $message';
    if (ruleId != null) result += ' (rule: $ruleId)';
    if (cause != null) result += '\nCaused by: $cause';
    return result;
  }
}
