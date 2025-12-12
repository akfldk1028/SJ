/// RuleEngine - 핵심 매칭 엔진
///
/// Phase 10-A: 기반 구축 (MVP)
/// 사주 컨텍스트에 대해 룰을 평가하고 매칭 결과 반환
///
/// 주요 기능:
/// 1. 조건 평가 (evaluate)
/// 2. 룰 매칭 (match, matchAll)
/// 3. 결과 바인딩 (템플릿 변수 치환)
library;

import '../entities/rule.dart';
import '../entities/rule_condition.dart';
import '../entities/saju_context.dart';
import '../entities/compiled_rules.dart';
import '../../data/constants/hapchung_relations.dart';

/// RuleEngine - 룰 매칭 엔진
///
/// 사용 예:
/// ```dart
/// final engine = RuleEngine();
/// final context = SajuContext.fromChart(chart);
/// final results = engine.matchAll(compiledRules, context);
/// ```
class RuleEngine {
  /// 싱글톤 인스턴스
  static final RuleEngine instance = RuleEngine._();

  RuleEngine._();

  factory RuleEngine() => instance;

  // ============================================================================
  // 룰 매칭
  // ============================================================================

  /// 모든 룰에 대해 매칭 수행
  ///
  /// [compiledRules] 컴파일된 룰셋
  /// [context] 사주 컨텍스트
  /// [enabledOnly] 활성화된 룰만 평가 (기본: true)
  /// 반환: 매칭된 결과 리스트 (우선순위 정렬)
  List<RuleMatchResult> matchAll(
    CompiledRules compiledRules,
    SajuContext context, {
    bool enabledOnly = true,
  }) {
    final rules = enabledOnly ? compiledRules.enabledRules : compiledRules.rules;
    final results = <RuleMatchResult>[];

    for (final rule in rules) {
      final result = match(rule, context);
      if (result != null) {
        results.add(result);
      }
    }

    // 우선순위로 정렬
    results.sort((a, b) => b.rule.priority.compareTo(a.rule.priority));
    return results;
  }

  /// 단일 룰 매칭
  ///
  /// [rule] 평가할 룰
  /// [context] 사주 컨텍스트
  /// 반환: 매칭되면 RuleMatchResult, 아니면 null
  RuleMatchResult? match(Rule rule, SajuContext context) {
    final evalResult = evaluate(rule.when, context);

    if (!evalResult.matched) return null;

    // 바인딩 생성
    final bindings = <String, String>{
      'name': rule.name,
      'dayGan': context.dayGan,
      'dayJi': context.dayJi,
      ...evalResult.bindings,
    };

    return RuleMatchResult(
      rule: rule,
      matchedPositions: evalResult.matchedPositions,
      bindings: bindings,
      score: evalResult.score,
    );
  }

  /// 여러 룰셋에서 매칭
  List<RuleMatchResult> matchFromRegistry(
    CompiledRulesRegistry registry,
    SajuContext context, {
    List<RuleType>? types,
    bool enabledOnly = true,
  }) {
    final results = <RuleMatchResult>[];
    final targetTypes = types ?? registry.registeredTypes.toList();

    for (final type in targetTypes) {
      final compiled = registry.get(type);
      if (compiled != null) {
        results.addAll(matchAll(compiled, context, enabledOnly: enabledOnly));
      }
    }

    // 전체 우선순위 정렬
    results.sort((a, b) => b.rule.priority.compareTo(a.rule.priority));
    return results;
  }

  // ============================================================================
  // 조건 평가
  // ============================================================================

  /// 조건 평가
  ///
  /// [condition] 평가할 조건
  /// [context] 사주 컨텍스트
  /// 반환: 평가 결과
  EvalResult evaluate(RuleCondition condition, SajuContext context) {
    return switch (condition) {
      SimpleCondition() => _evaluateSimple(condition, context),
      CompositeCondition() => _evaluateComposite(condition, context),
    };
  }

  /// 단순 조건 평가
  EvalResult _evaluateSimple(SimpleCondition condition, SajuContext context) {
    final fieldValue = context.getFieldValue(condition.field);

    // 필드 값이 없으면 매칭 실패
    if (fieldValue == null && condition.op != ConditionOp.exists) {
      return EvalResult.notMatched();
    }

    final conditionValue = condition.value;

    switch (condition.op) {
      case ConditionOp.eq:
        return fieldValue == conditionValue
            ? EvalResult.matched()
            : EvalResult.notMatched();

      case ConditionOp.ne:
        return fieldValue != conditionValue
            ? EvalResult.matched()
            : EvalResult.notMatched();

      case ConditionOp.contains: // 'in' operator
        return _evaluateIn(fieldValue, conditionValue, condition.field, context);

      case ConditionOp.notIn:
        final inResult = _evaluateIn(fieldValue, conditionValue, condition.field, context);
        return inResult.matched ? EvalResult.notMatched() : EvalResult.matched();

      case ConditionOp.startsWith:
        if (fieldValue is String && conditionValue is String) {
          return fieldValue.startsWith(conditionValue)
              ? EvalResult.matched()
              : EvalResult.notMatched();
        }
        return EvalResult.notMatched();

      case ConditionOp.endsWith:
        if (fieldValue is String && conditionValue is String) {
          return fieldValue.endsWith(conditionValue)
              ? EvalResult.matched()
              : EvalResult.notMatched();
        }
        return EvalResult.notMatched();

      case ConditionOp.exists:
        final exists = conditionValue == true ? fieldValue != null : fieldValue == null;
        return exists ? EvalResult.matched() : EvalResult.notMatched();

      case ConditionOp.gte:
        return _evaluateGte(fieldValue, conditionValue, condition.field, context);

      case ConditionOp.lte:
        return _evaluateLte(fieldValue, conditionValue, condition.field, context);

      // 특수 연산자 (사주 도메인)
      case ConditionOp.samhapMatch:
        return _evaluateSamhap(context);

      case ConditionOp.yukhapMatch:
        return _evaluateYukhap(context, conditionValue);

      case ConditionOp.chungMatch:
        return _evaluateChung(context, conditionValue);

      case ConditionOp.hyungMatch:
        return _evaluateHyung(context, conditionValue);

      // 논리 연산자는 CompositeCondition에서 처리
      case ConditionOp.and:
      case ConditionOp.or:
      case ConditionOp.not:
        return EvalResult.notMatched();
    }
  }

  /// 'in' 연산자 평가
  EvalResult _evaluateIn(
    dynamic fieldValue,
    dynamic conditionValue,
    ConditionField field,
    SajuContext context,
  ) {
    if (conditionValue is! List) {
      return EvalResult.notMatched();
    }

    final valueList = conditionValue;

    // 필드가 리스트인 경우 (ganAny, jiAny)
    if (fieldValue is List) {
      final matchedItems = <String>[];
      final matchedPositions = <String>[];

      for (var i = 0; i < fieldValue.length; i++) {
        if (valueList.contains(fieldValue[i])) {
          matchedItems.add(fieldValue[i].toString());

          // 위치 정보 추가
          if (field == ConditionField.jiAny) {
            matchedPositions.add(SajuContext.positionNames[i]);
          } else if (field == ConditionField.ganAny) {
            matchedPositions.add(['년간', '월간', '일간', '시간'][i]);
          }
        }
      }

      if (matchedItems.isNotEmpty) {
        return EvalResult(
          matched: true,
          matchedPositions: matchedPositions,
          bindings: {'matchedItems': matchedItems.join(', ')},
          score: matchedItems.length,
        );
      }
      return EvalResult.notMatched();
    }

    // 필드가 단일 값인 경우
    if (valueList.contains(fieldValue)) {
      return EvalResult(
        matched: true,
        bindings: {'matchedValue': fieldValue.toString()},
      );
    }
    return EvalResult.notMatched();
  }

  /// 복합 조건 평가
  EvalResult _evaluateComposite(CompositeCondition condition, SajuContext context) {
    switch (condition.op) {
      case ConditionOp.and:
        return _evaluateAnd(condition.conditions, context);

      case ConditionOp.or:
        return _evaluateOr(condition.conditions, context);

      case ConditionOp.not:
        if (condition.conditions.isEmpty) return EvalResult.notMatched();
        final result = evaluate(condition.conditions.first, context);
        return result.matched ? EvalResult.notMatched() : EvalResult.matched();

      default:
        return EvalResult.notMatched();
    }
  }

  /// AND 조건 평가
  EvalResult _evaluateAnd(List<RuleCondition> conditions, SajuContext context) {
    final allPositions = <String>[];
    final allBindings = <String, String>{};
    var totalScore = 0;

    for (final cond in conditions) {
      final result = evaluate(cond, context);
      if (!result.matched) {
        return EvalResult.notMatched();
      }

      allPositions.addAll(result.matchedPositions);
      allBindings.addAll(result.bindings);
      totalScore += result.score;
    }

    return EvalResult(
      matched: true,
      matchedPositions: allPositions,
      bindings: allBindings,
      score: totalScore,
    );
  }

  /// OR 조건 평가
  EvalResult _evaluateOr(List<RuleCondition> conditions, SajuContext context) {
    for (final cond in conditions) {
      final result = evaluate(cond, context);
      if (result.matched) {
        return result;
      }
    }
    return EvalResult.notMatched();
  }

  // ============================================================================
  // 특수 연산자 (사주 도메인)
  // ============================================================================

  /// 삼합 매칭
  EvalResult _evaluateSamhap(SajuContext context) {
    final jijis = context.allJi.toSet();
    final samhap = findJijiSamhap(jijis);

    if (samhap != null) {
      return EvalResult(
        matched: true,
        bindings: {
          'samhap': samhap.description,
          'resultOheng': samhap.resultOheng,
        },
      );
    }
    return EvalResult.notMatched();
  }

  /// 육합 매칭
  EvalResult _evaluateYukhap(SajuContext context, dynamic targetPairs) {
    final jijis = context.allJi;
    final matchedPairs = <String>[];

    for (var i = 0; i < jijis.length; i++) {
      for (var j = i + 1; j < jijis.length; j++) {
        if (isJijiYukhap(jijis[i], jijis[j])) {
          matchedPairs.add('${jijis[i]}${jijis[j]}');
        }
      }
    }

    if (matchedPairs.isNotEmpty) {
      return EvalResult(
        matched: true,
        bindings: {'yukhapPairs': matchedPairs.join(', ')},
        score: matchedPairs.length,
      );
    }
    return EvalResult.notMatched();
  }

  /// 충 매칭
  EvalResult _evaluateChung(SajuContext context, dynamic targetPairs) {
    final jijis = context.allJi;
    final matchedPairs = <String>[];

    for (var i = 0; i < jijis.length; i++) {
      for (var j = i + 1; j < jijis.length; j++) {
        if (isJijiChung(jijis[i], jijis[j])) {
          matchedPairs.add('${jijis[i]}${jijis[j]}');
        }
      }
    }

    if (matchedPairs.isNotEmpty) {
      return EvalResult(
        matched: true,
        bindings: {'chungPairs': matchedPairs.join(', ')},
        score: matchedPairs.length,
      );
    }
    return EvalResult.notMatched();
  }

  /// 형 매칭
  EvalResult _evaluateHyung(SajuContext context, dynamic targetPairs) {
    final jijis = context.allJi;
    final matchedHyungs = <String>[];

    for (var i = 0; i < jijis.length; i++) {
      for (var j = i + 1; j < jijis.length; j++) {
        final hyung = findJijiHyung(jijis[i], jijis[j]);
        if (hyung != null) {
          matchedHyungs.add(hyung.description);
        }
      }
    }

    if (matchedHyungs.isNotEmpty) {
      return EvalResult(
        matched: true,
        bindings: {'hyungs': matchedHyungs.join(', ')},
        score: matchedHyungs.length,
      );
    }
    return EvalResult.notMatched();
  }

  /// >= 연산자 평가 (카운트 비교용)
  ///
  /// jiCount/ganCount 필드와 함께 사용:
  /// { "field": "jiCount", "op": "gte", "value": { "진": 2 } }
  /// → 지지에 "진"이 2개 이상 있으면 매칭
  EvalResult _evaluateGte(
    dynamic fieldValue,
    dynamic conditionValue,
    ConditionField field,
    SajuContext context,
  ) {
    // Map 타입 (jiCount, ganCount)
    if (fieldValue is Map<String, int> && conditionValue is Map) {
      for (final entry in conditionValue.entries) {
        final key = entry.key as String;
        final minCount = entry.value as int;
        final actualCount = fieldValue[key] ?? 0;

        if (actualCount >= minCount) {
          // 매칭된 위치 정보 추가
          final positions = field == ConditionField.jiCount
              ? context.findPositionsWithJi(key)
              : <String>[];

          return EvalResult(
            matched: true,
            matchedPositions: positions,
            bindings: {
              'matchedKey': key,
              'count': actualCount.toString(),
            },
            score: actualCount,
          );
        }
      }
      return EvalResult.notMatched();
    }

    // 숫자 비교
    if (fieldValue is num && conditionValue is num) {
      return fieldValue >= conditionValue
          ? EvalResult.matched()
          : EvalResult.notMatched();
    }

    return EvalResult.notMatched();
  }

  /// <= 연산자 평가
  EvalResult _evaluateLte(
    dynamic fieldValue,
    dynamic conditionValue,
    ConditionField field,
    SajuContext context,
  ) {
    // Map 타입 (jiCount, ganCount)
    if (fieldValue is Map<String, int> && conditionValue is Map) {
      for (final entry in conditionValue.entries) {
        final key = entry.key as String;
        final maxCount = entry.value as int;
        final actualCount = fieldValue[key] ?? 0;

        if (actualCount <= maxCount && actualCount > 0) {
          return EvalResult(
            matched: true,
            bindings: {
              'matchedKey': key,
              'count': actualCount.toString(),
            },
          );
        }
      }
      return EvalResult.notMatched();
    }

    // 숫자 비교
    if (fieldValue is num && conditionValue is num) {
      return fieldValue <= conditionValue
          ? EvalResult.matched()
          : EvalResult.notMatched();
    }

    return EvalResult.notMatched();
  }
}

// ============================================================================
// 평가 결과
// ============================================================================

/// 조건 평가 결과
class EvalResult {
  /// 매칭 여부
  final bool matched;

  /// 매칭된 위치들
  final List<String> matchedPositions;

  /// 바인딩된 값들
  final Map<String, String> bindings;

  /// 매칭 점수 (여러 매칭 시 가중치)
  final int score;

  const EvalResult({
    required this.matched,
    this.matchedPositions = const [],
    this.bindings = const {},
    this.score = 0,
  });

  factory EvalResult.matched({
    List<String>? positions,
    Map<String, String>? bindings,
    int? score,
  }) {
    return EvalResult(
      matched: true,
      matchedPositions: positions ?? const [],
      bindings: bindings ?? const {},
      score: score ?? 1,
    );
  }

  factory EvalResult.notMatched() => const EvalResult(matched: false);
}
