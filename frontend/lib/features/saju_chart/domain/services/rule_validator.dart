/// RuleEngine - 기본 검증기
///
/// Phase 10-A: 기반 구축 (MVP)
/// JSON 룰 파싱 시 필수 필드 체크
///
/// MVP 원칙:
/// - 필수 필드 존재 여부만 체크
/// - 스키마 검증, 타입 검증은 추후 Phase 10-C에서 추가
library;

import '../entities/rule.dart';
import '../entities/rule_condition.dart';

/// 룰 검증기
///
/// 역할:
/// 1. 필수 필드 존재 체크
/// 2. 기본 타입 검증
/// 3. 조건 구조 검증
class RuleValidator {
  /// 싱글톤 인스턴스
  static final RuleValidator instance = RuleValidator._();

  RuleValidator._();

  factory RuleValidator() => instance;

  // ============================================================================
  // 룰셋 검증
  // ============================================================================

  /// 전체 룰셋 JSON 검증
  ///
  /// [json] 룰셋 JSON
  /// 반환: 검증 결과
  ValidationResult validateRuleSet(Map<String, dynamic> json) {
    final errors = <ValidationError>[];

    // 1. 스키마 버전 체크
    if (!json.containsKey('schemaVersion')) {
      errors.add(const ValidationError(
        field: 'schemaVersion',
        message: '필수 필드 누락',
        severity: ValidationSeverity.warning,
      ));
    }

    // 2. 룰 타입 체크
    if (!json.containsKey('ruleType')) {
      errors.add(const ValidationError(
        field: 'ruleType',
        message: '필수 필드 누락',
        severity: ValidationSeverity.error,
      ));
    } else {
      final typeCode = json['ruleType'] as String?;
      if (typeCode != null && RuleType.fromCode(typeCode) == null) {
        errors.add(ValidationError(
          field: 'ruleType',
          message: '알 수 없는 룰 타입: $typeCode',
          severity: ValidationSeverity.error,
        ));
      }
    }

    // 3. 룰 배열 체크
    if (!json.containsKey('rules')) {
      errors.add(const ValidationError(
        field: 'rules',
        message: '필수 필드 누락',
        severity: ValidationSeverity.error,
      ));
    } else {
      final rules = json['rules'];
      if (rules is! List) {
        errors.add(const ValidationError(
          field: 'rules',
          message: '배열 타입이어야 합니다',
          severity: ValidationSeverity.error,
        ));
      } else {
        // 각 룰 검증
        for (var i = 0; i < rules.length; i++) {
          final ruleJson = rules[i];
          if (ruleJson is! Map<String, dynamic>) {
            errors.add(ValidationError(
              field: 'rules[$i]',
              message: '객체 타입이어야 합니다',
              severity: ValidationSeverity.error,
            ));
            continue;
          }

          final ruleResult = validateRule(ruleJson, index: i);
          errors.addAll(ruleResult.errors);
        }
      }
    }

    return ValidationResult(errors: errors);
  }

  // ============================================================================
  // 개별 룰 검증
  // ============================================================================

  /// 개별 룰 JSON 검증
  ///
  /// [json] 룰 JSON
  /// [index] 룰 인덱스 (에러 메시지용)
  /// 반환: 검증 결과
  ValidationResult validateRule(Map<String, dynamic> json, {int? index}) {
    final errors = <ValidationError>[];
    final prefix = index != null ? 'rules[$index].' : '';

    // 필수 필드 목록
    const requiredFields = ['id', 'name', 'when'];

    for (final field in requiredFields) {
      if (!json.containsKey(field)) {
        errors.add(ValidationError(
          field: '$prefix$field',
          message: '필수 필드 누락',
          severity: ValidationSeverity.error,
        ));
      }
    }

    // id 검증
    if (json.containsKey('id')) {
      final id = json['id'];
      if (id is! String || id.isEmpty) {
        errors.add(ValidationError(
          field: '${prefix}id',
          message: '비어있지 않은 문자열이어야 합니다',
          severity: ValidationSeverity.error,
        ));
      }
    }

    // name 검증
    if (json.containsKey('name')) {
      final name = json['name'];
      if (name is! String || name.isEmpty) {
        errors.add(ValidationError(
          field: '${prefix}name',
          message: '비어있지 않은 문자열이어야 합니다',
          severity: ValidationSeverity.error,
        ));
      }
    }

    // when 조건 검증
    if (json.containsKey('when')) {
      final when = json['when'];
      if (when is! Map<String, dynamic>) {
        errors.add(ValidationError(
          field: '${prefix}when',
          message: '객체 타입이어야 합니다',
          severity: ValidationSeverity.error,
        ));
      } else {
        final condResult = validateCondition(when, prefix: '${prefix}when.');
        errors.addAll(condResult.errors);
      }
    }

    // fortuneType 검증 (선택적)
    if (json.containsKey('fortuneType')) {
      final fortune = json['fortuneType'] as String?;
      if (fortune != null && FortuneType.fromString(fortune) == null) {
        errors.add(ValidationError(
          field: '${prefix}fortuneType',
          message: '알 수 없는 길흉 타입: $fortune',
          severity: ValidationSeverity.warning,
        ));
      }
    }

    // priority 검증 (선택적)
    if (json.containsKey('priority')) {
      final priority = json['priority'];
      if (priority is! int) {
        errors.add(ValidationError(
          field: '${prefix}priority',
          message: '정수 타입이어야 합니다',
          severity: ValidationSeverity.warning,
        ));
      }
    }

    return ValidationResult(errors: errors);
  }

  // ============================================================================
  // 조건 검증
  // ============================================================================

  /// 조건 JSON 검증
  ///
  /// [json] 조건 JSON
  /// [prefix] 필드명 접두사
  /// 반환: 검증 결과
  ValidationResult validateCondition(Map<String, dynamic> json, {String prefix = ''}) {
    final errors = <ValidationError>[];

    // op 필수
    if (!json.containsKey('op')) {
      errors.add(ValidationError(
        field: '${prefix}op',
        message: '필수 필드 누락',
        severity: ValidationSeverity.error,
      ));
      return ValidationResult(errors: errors);
    }

    final opCode = json['op'] as String?;
    if (opCode == null) {
      errors.add(ValidationError(
        field: '${prefix}op',
        message: '문자열 타입이어야 합니다',
        severity: ValidationSeverity.error,
      ));
      return ValidationResult(errors: errors);
    }

    final op = ConditionOp.fromCode(opCode);
    if (op == null) {
      errors.add(ValidationError(
        field: '${prefix}op',
        message: '알 수 없는 연산자: $opCode',
        severity: ValidationSeverity.error,
      ));
      return ValidationResult(errors: errors);
    }

    // 논리 연산자 (and, or, not)
    if (op.isLogical) {
      if (!json.containsKey('conditions')) {
        errors.add(ValidationError(
          field: '${prefix}conditions',
          message: '$opCode 연산자에는 conditions 필드가 필요합니다',
          severity: ValidationSeverity.error,
        ));
      } else {
        final conditions = json['conditions'];
        if (conditions is! List) {
          errors.add(ValidationError(
            field: '${prefix}conditions',
            message: '배열 타입이어야 합니다',
            severity: ValidationSeverity.error,
          ));
        } else {
          for (var i = 0; i < conditions.length; i++) {
            final cond = conditions[i];
            if (cond is! Map<String, dynamic>) {
              errors.add(ValidationError(
                field: '${prefix}conditions[$i]',
                message: '객체 타입이어야 합니다',
                severity: ValidationSeverity.error,
              ));
            } else {
              final condResult = validateCondition(cond, prefix: '${prefix}conditions[$i].');
              errors.addAll(condResult.errors);
            }
          }
        }
      }
    }
    // 비교 연산자
    else if (op.isComparison) {
      if (!json.containsKey('field')) {
        errors.add(ValidationError(
          field: '${prefix}field',
          message: '비교 조건에는 field 필드가 필요합니다',
          severity: ValidationSeverity.error,
        ));
      } else {
        final fieldCode = json['field'] as String?;
        if (fieldCode != null && ConditionField.fromCode(fieldCode) == null) {
          errors.add(ValidationError(
            field: '${prefix}field',
            message: '알 수 없는 필드: $fieldCode',
            severity: ValidationSeverity.error,
          ));
        }
      }

      // in, notIn 연산자는 value가 배열이어야 함
      if (op == ConditionOp.contains || op == ConditionOp.notIn) {
        if (json.containsKey('value') && json['value'] is! List) {
          errors.add(ValidationError(
            field: '${prefix}value',
            message: '$opCode 연산자의 value는 배열이어야 합니다',
            severity: ValidationSeverity.error,
          ));
        }
      }
    }

    return ValidationResult(errors: errors);
  }
}

// ============================================================================
// 검증 결과 클래스
// ============================================================================

/// 검증 에러 심각도
enum ValidationSeverity {
  /// 경고 (무시 가능)
  warning,

  /// 에러 (치명적)
  error,
}

/// 검증 에러
class ValidationError {
  /// 에러 발생 필드
  final String field;

  /// 에러 메시지
  final String message;

  /// 심각도
  final ValidationSeverity severity;

  const ValidationError({
    required this.field,
    required this.message,
    this.severity = ValidationSeverity.error,
  });

  bool get isError => severity == ValidationSeverity.error;
  bool get isWarning => severity == ValidationSeverity.warning;

  @override
  String toString() => '[$severity] $field: $message';
}

/// 검증 결과
class ValidationResult {
  final List<ValidationError> errors;

  const ValidationResult({this.errors = const []});

  /// 검증 성공 여부 (에러 없음)
  bool get isValid => errors.where((e) => e.isError).isEmpty;

  /// 에러 개수
  int get errorCount => errors.where((e) => e.isError).length;

  /// 경고 개수
  int get warningCount => errors.where((e) => e.isWarning).length;

  /// 에러만 필터링
  List<ValidationError> get errorsOnly => errors.where((e) => e.isError).toList();

  /// 경고만 필터링
  List<ValidationError> get warningsOnly => errors.where((e) => e.isWarning).toList();

  @override
  String toString() {
    if (isValid && warningCount == 0) return 'ValidationResult: OK';
    return 'ValidationResult: $errorCount errors, $warningCount warnings';
  }
}
