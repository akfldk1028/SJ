/// RuleEngine - Repository 구현체
///
/// Phase 10-A: 기반 구축 (MVP)
/// Asset에서 JSON 룰 로드, 검증, 컴파일
///
/// MVP 원칙:
/// - loadFromAsset() 우선 구현
/// - loadFromRemote()는 Phase 10-D에서 구현
/// - 캐시는 메모리 기반 단순 구현
library;

import 'package:flutter/services.dart' show rootBundle;

import '../../domain/entities/rule.dart';
import '../../domain/entities/compiled_rules.dart';
import '../../domain/repositories/rule_repository.dart';
import '../../domain/services/rule_validator.dart';
import '../models/rule_models.dart';

/// RuleRepository 구현체
class RuleRepositoryImpl implements RuleRepository {
  /// 싱글톤 인스턴스
  static final RuleRepositoryImpl instance = RuleRepositoryImpl._();

  RuleRepositoryImpl._();

  factory RuleRepositoryImpl() => instance;

  /// 메모리 캐시
  final Map<RuleType, CompiledRules> _cache = {};

  /// 검증기
  final RuleValidator _validator = RuleValidator();

  // ============================================================================
  // 지원 타입 및 경로 매핑
  // ============================================================================

  @override
  List<RuleType> get supportedTypes => [
        RuleType.sinsal,
        RuleType.hapchung,
        RuleType.hyungpahae,
        RuleType.sipsin,
        RuleType.unsung,
        RuleType.jijanggan,
        RuleType.gongmang,
      ];

  /// 타입별 기본 Asset 경로
  String _getDefaultAssetPath(RuleType type) {
    return 'data/rules/${type.code}_rules.json';
  }

  // ============================================================================
  // 로드 메서드 구현
  // ============================================================================

  @override
  Future<CompiledRules> loadFromAsset(String assetPath) async {
    try {
      // Asset 파일 읽기
      final jsonString = await rootBundle.loadString('assets/$assetPath');
      return loadFromString(jsonString, source: assetPath);
    } catch (e) {
      throw RuleLoadException(
        'Asset 로드 실패: $assetPath',
        source: assetPath,
        cause: e,
      );
    }
  }

  @override
  Future<CompiledRules> loadFromRemote(String url, {bool validateHash = true}) async {
    // Phase 10-D에서 구현
    throw UnimplementedError('loadFromRemote는 Phase 10-D에서 구현 예정');
  }

  @override
  Future<CompiledRules> loadFromString(String jsonString, {String? source}) async {
    try {
      // 1. JSON 파싱
      final parseResult = RuleParser.parseFromString(jsonString, source: source);

      // 파싱 경고 로깅
      if (parseResult.warnings.isNotEmpty) {
        // TODO: 로거로 경고 출력
        for (final warning in parseResult.warnings) {
          // ignore: avoid_print
          print('[RuleRepository] Warning: $warning');
        }
      }

      // 2. 컴파일된 룰 생성
      final compiled = CompiledRules(
        meta: parseResult.meta,
        rules: parseResult.rules,
        compiledAt: DateTime.now(),
        source: source,
      );

      // 3. 캐시에 저장
      _cache[compiled.meta.ruleType] = compiled;

      return compiled;
    } catch (e) {
      throw RuleLoadException(
        'JSON 파싱 실패',
        source: source,
        cause: e,
      );
    }
  }

  @override
  Future<CompiledRules> loadByType(RuleType type) async {
    // 캐시 확인
    final cached = _cache[type];
    if (cached != null) return cached;

    // Asset에서 로드
    final path = _getDefaultAssetPath(type);
    return loadFromAsset(path);
  }

  @override
  Future<List<CompiledRules>> loadMultipleTypes(List<RuleType> types) async {
    final results = <CompiledRules>[];

    for (final type in types) {
      try {
        final compiled = await loadByType(type);
        results.add(compiled);
      } catch (e) {
        // 개별 타입 로드 실패는 무시하고 계속
        // ignore: avoid_print
        print('[RuleRepository] 타입 로드 실패: ${type.code} - $e');
      }
    }

    return results;
  }

  // ============================================================================
  // 캐시 관리
  // ============================================================================

  @override
  CompiledRules? getCached(RuleType type) => _cache[type];

  @override
  void setCache(RuleType type, CompiledRules rules) {
    _cache[type] = rules;
  }

  @override
  void invalidateCache(RuleType type) {
    _cache.remove(type);
  }

  @override
  void clearCache() {
    _cache.clear();
  }

  @override
  Map<RuleType, int> get loadedRuleCounts => {
        for (final entry in _cache.entries) entry.key: entry.value.ruleCount,
      };

  // ============================================================================
  // 버전 관리 (Phase 10-D)
  // ============================================================================

  @override
  Future<String?> getLocalVersion(RuleType type) async {
    final cached = _cache[type];
    return cached?.meta.version;
  }

  @override
  Future<String?> getRemoteVersion(RuleType type) async {
    // Phase 10-D에서 구현
    return null;
  }

  @override
  Future<bool> needsUpdate(RuleType type) async {
    // Phase 10-D에서 구현
    return false;
  }

  // ============================================================================
  // 검증 (내부용)
  // ============================================================================

  /// JSON 검증 (로드 전 사전 검증)
  ValidationResult validateJson(Map<String, dynamic> json) {
    return _validator.validateRuleSet(json);
  }
}

/// 편의를 위한 전역 인스턴스
RuleRepositoryImpl get ruleRepository => RuleRepositoryImpl.instance;
