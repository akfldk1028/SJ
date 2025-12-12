/// RuleEngine - 컴파일된 룰 구조
///
/// Phase 10-A: 기반 구축 (MVP)
/// JSON에서 파싱된 룰들을 실행 가능한 형태로 저장
///
/// MVP 원칙:
/// - 인덱싱 없이 단순 리스트 반환
/// - 성능 이슈 발생 시 인덱싱 추가 예정
library;

import 'rule.dart';

/// 컴파일된 룰셋
///
/// JSON 파일에서 로드 후 검증/파싱된 룰들을 담는 컨테이너
/// MVP: 단순 리스트 구조, 인덱싱은 Phase 10-D에서 추가
class CompiledRules {
  /// 룰셋 메타데이터
  final RuleSetMeta meta;

  /// 파싱된 룰 리스트
  final List<Rule> rules;

  /// 컴파일 시각
  final DateTime compiledAt;

  /// 소스 정보 (예: "assets/data/rules/sinsal_rules.json")
  final String? source;

  const CompiledRules({
    required this.meta,
    required this.rules,
    required this.compiledAt,
    this.source,
  });

  /// 빈 룰셋 생성
  factory CompiledRules.empty(RuleType type) {
    return CompiledRules(
      meta: RuleSetMeta(
        schemaVersion: '1.0.0',
        ruleType: type,
        version: '0.0.0',
        ruleCount: 0,
      ),
      rules: const [],
      compiledAt: DateTime.now(),
    );
  }

  /// 룰 개수
  int get ruleCount => rules.length;

  /// 활성화된 룰만 필터링
  List<Rule> get enabledRules => rules.where((r) => r.enabled).toList();

  /// 카테고리별 룰 필터링
  List<Rule> getRulesByCategory(String category) {
    return rules.where((r) => r.category == category).toList();
  }

  /// 길흉별 룰 필터링
  List<Rule> getRulesByFortuneType(FortuneType fortuneType) {
    return rules.where((r) => r.fortuneType == fortuneType).toList();
  }

  /// ID로 룰 조회
  Rule? getRuleById(String id) {
    for (final rule in rules) {
      if (rule.id == id) return rule;
    }
    return null;
  }

  /// 우선순위 정렬된 룰 리스트
  List<Rule> get sortedByPriority {
    final sorted = List<Rule>.from(rules);
    sorted.sort((a, b) => b.priority.compareTo(a.priority));
    return sorted;
  }

  @override
  String toString() =>
      'CompiledRules(${meta.ruleType.korean}, ${rules.length} rules)';
}

/// 여러 RuleType의 룰셋을 통합 관리
class CompiledRulesRegistry {
  final Map<RuleType, CompiledRules> _registry = {};

  /// 룰셋 등록
  void register(CompiledRules compiledRules) {
    _registry[compiledRules.meta.ruleType] = compiledRules;
  }

  /// 룰셋 조회
  CompiledRules? get(RuleType type) => _registry[type];

  /// 모든 룰셋 조회
  Iterable<CompiledRules> get all => _registry.values;

  /// 등록된 RuleType 목록
  Set<RuleType> get registeredTypes => _registry.keys.toSet();

  /// 특정 타입 룰셋 존재 여부
  bool hasType(RuleType type) => _registry.containsKey(type);

  /// 전체 룰 개수
  int get totalRuleCount =>
      _registry.values.fold(0, (sum, c) => sum + c.ruleCount);

  /// 특정 ID로 모든 룰셋에서 검색
  Rule? findRuleById(String id) {
    for (final compiled in _registry.values) {
      final rule = compiled.getRuleById(id);
      if (rule != null) return rule;
    }
    return null;
  }

  /// 초기화
  void clear() => _registry.clear();
}
