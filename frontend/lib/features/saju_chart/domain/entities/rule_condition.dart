/// RuleEngine - 조건 타입 정의
///
/// Phase 10-A: 기반 구축
/// JSON 룰의 "when" 필드를 파싱하고 평가하는 조건 시스템
///
/// JSON 구조 예시:
/// ```json
/// {
///   "when": {
///     "op": "and",
///     "conditions": [
///       { "field": "dayGan", "op": "in", "value": ["갑", "무", "경"] },
///       { "field": "jiAny", "op": "in", "value": ["축", "미"] }
///     ]
///   }
/// }
/// ```
library;

// ============================================================================
// Condition Operators
// ============================================================================

/// 조건 연산자
enum ConditionOp {
  // 비교 연산자
  /// 같음 (==)
  eq('eq'),

  /// 같지 않음 (!=)
  ne('ne'),

  /// 포함 (리스트에 값 존재)
  contains('in'),

  /// 미포함 (리스트에 값 없음)
  notIn('notIn'),

  /// ~로 시작
  startsWith('startsWith'),

  /// ~로 끝남
  endsWith('endsWith'),

  /// 존재 여부 (null 체크)
  exists('exists'),

  /// 크거나 같음 (>=) - 카운트 비교용
  gte('gte'),

  /// 작거나 같음 (<=)
  lte('lte'),

  // 논리 연산자
  /// AND - 모든 조건 만족
  and('and'),

  /// OR - 하나 이상 만족
  or('or'),

  /// NOT - 조건 부정
  not('not'),

  // 특수 연산자 (사주 도메인)
  /// 삼합 매칭 (3개 지지가 삼합 형성)
  samhapMatch('samhapMatch'),

  /// 육합 매칭 (2개 지지가 육합)
  yukhapMatch('yukhapMatch'),

  /// 충 매칭 (2개 지지가 충)
  chungMatch('chungMatch'),

  /// 형 매칭 (2개 지지가 형)
  hyungMatch('hyungMatch');

  final String code;

  const ConditionOp(this.code);

  /// code로 ConditionOp 조회
  static ConditionOp? fromCode(String code) {
    // 'in'은 Dart 예약어라 contains로 매핑
    if (code == 'in') return ConditionOp.contains;

    for (final op in ConditionOp.values) {
      if (op.code == code) return op;
    }
    return null;
  }

  /// 비교 연산자인지 확인
  bool get isComparison => [eq, ne, contains, notIn, startsWith, endsWith, exists, gte, lte].contains(this);

  /// 논리 연산자인지 확인
  bool get isLogical => [and, or, not].contains(this);

  /// 특수(사주 도메인) 연산자인지 확인
  bool get isSpecial => [samhapMatch, yukhapMatch, chungMatch, hyungMatch].contains(this);
}

// ============================================================================
// Condition Field (사주 컨텍스트 필드)
// ============================================================================

/// 조건에서 참조할 수 있는 필드
enum ConditionField {
  // 천간 (天干)
  yearGan('yearGan', '년간'),
  monthGan('monthGan', '월간'),
  dayGan('dayGan', '일간'),
  hourGan('hourGan', '시간'),
  ganAny('ganAny', '천간 중 하나'),

  // 지지 (地支)
  yearJi('yearJi', '년지'),
  monthJi('monthJi', '월지'),
  dayJi('dayJi', '일지'),
  hourJi('hourJi', '시지'),
  jiAny('jiAny', '지지 중 하나'),
  jiCount('jiCount', '지지 개수'),
  ganCount('ganCount', '천간 개수'),

  // 일주 (日柱)
  dayPillar('dayPillar', '일주'),

  // 오행 (五行)
  dayOheng('dayOheng', '일간 오행'),
  yearJiOheng('yearJiOheng', '년지 오행'),

  // 음양 (陰陽)
  dayEumYang('dayEumYang', '일간 음양'),

  // 기타
  gender('gender', '성별'),
  birthYear('birthYear', '생년');

  final String code;
  final String korean;

  const ConditionField(this.code, this.korean);

  /// code로 ConditionField 조회
  static ConditionField? fromCode(String code) {
    for (final field in ConditionField.values) {
      if (field.code == code) return field;
    }
    return null;
  }

  /// 천간 필드인지 확인
  bool get isGan => [yearGan, monthGan, dayGan, hourGan, ganAny].contains(this);

  /// 지지 필드인지 확인
  bool get isJi => [yearJi, monthJi, dayJi, hourJi, jiAny].contains(this);
}

// ============================================================================
// Rule Condition
// ============================================================================

/// 룰 조건 (추상 인터페이스)
///
/// 두 가지 타입:
/// 1. SimpleCondition - 단일 필드 비교 (field op value)
/// 2. CompositeCondition - 복합 조건 (and/or/not)
sealed class RuleCondition {
  const RuleCondition();

  /// JSON에서 조건 파싱
  factory RuleCondition.fromJson(Map<String, dynamic> json) {
    final opCode = json['op'] as String?;
    if (opCode == null) {
      throw FormatException('조건에 op 필드가 필요합니다: $json');
    }

    final op = ConditionOp.fromCode(opCode);
    if (op == null) {
      throw FormatException('알 수 없는 연산자: $opCode');
    }

    // 논리 연산자 (and, or, not)
    if (op.isLogical) {
      final conditions = json['conditions'] as List?;
      if (conditions == null || conditions.isEmpty) {
        throw FormatException('$opCode 연산자에 conditions 배열이 필요합니다');
      }

      final parsedConditions = conditions
          .map((c) => RuleCondition.fromJson(c as Map<String, dynamic>))
          .toList();

      return CompositeCondition(op: op, conditions: parsedConditions);
    }

    // 단순 비교 연산자
    final fieldCode = json['field'] as String?;
    if (fieldCode == null) {
      throw FormatException('비교 조건에 field 필드가 필요합니다: $json');
    }

    final field = ConditionField.fromCode(fieldCode);
    if (field == null) {
      throw FormatException('알 수 없는 필드: $fieldCode');
    }

    final value = json['value'];
    return SimpleCondition(field: field, op: op, value: value);
  }

  /// JSON으로 변환
  Map<String, dynamic> toJson();
}

/// 단순 조건 (필드 비교)
///
/// 예: { "field": "dayGan", "op": "in", "value": ["갑", "기"] }
class SimpleCondition extends RuleCondition {
  final ConditionField field;
  final ConditionOp op;
  final dynamic value;

  const SimpleCondition({
    required this.field,
    required this.op,
    this.value,
  });

  @override
  Map<String, dynamic> toJson() => {
        'field': field.code,
        'op': op.code,
        if (value != null) 'value': value,
      };

  @override
  String toString() => 'SimpleCondition(${field.code} ${op.code} $value)';
}

/// 복합 조건 (논리 연산)
///
/// 예:
/// ```json
/// {
///   "op": "and",
///   "conditions": [
///     { "field": "dayGan", "op": "in", "value": ["갑", "무", "경"] },
///     { "field": "jiAny", "op": "in", "value": ["축", "미"] }
///   ]
/// }
/// ```
class CompositeCondition extends RuleCondition {
  final ConditionOp op;
  final List<RuleCondition> conditions;

  const CompositeCondition({
    required this.op,
    required this.conditions,
  });

  @override
  Map<String, dynamic> toJson() => {
        'op': op.code,
        'conditions': conditions.map((c) => c.toJson()).toList(),
      };

  @override
  String toString() => 'CompositeCondition(${op.code}, ${conditions.length} conditions)';
}
