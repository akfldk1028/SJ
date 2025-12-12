/// RuleEngine - JSON 파싱 모델
///
/// Phase 10-A: 기반 구축
/// JSON 룰 파일을 Dart 객체로 파싱하는 모델 클래스들
library;

import 'dart:convert';

import '../../domain/entities/rule.dart';
import '../../domain/entities/rule_condition.dart';

/// JSON에서 파싱된 Rule 구현체
///
/// JSON 구조:
/// ```json
/// {
///   "id": "cheon_eul_gwin",
///   "name": "천을귀인",
///   "hanja": "天乙貴人",
///   "type": "sinsal",
///   "category": "특수신살",
///   "fortuneType": "길",
///   "when": { ... },
///   "reasonTemplate": "일간 {dayGan}에서 {matchedJi}가 천을귀인",
///   "description": "귀인의 도움을 받는 길성",
///   "priority": 100,
///   "enabled": true
/// }
/// ```
class RuleModel implements Rule {
  @override
  final String id;

  @override
  final String name;

  @override
  final String? hanja;

  @override
  final RuleType type;

  @override
  final String category;

  @override
  final FortuneType fortuneType;

  @override
  final RuleCondition when;

  @override
  final String reasonTemplate;

  @override
  final String? description;

  @override
  final int priority;

  @override
  final bool enabled;

  const RuleModel({
    required this.id,
    required this.name,
    this.hanja,
    required this.type,
    required this.category,
    required this.fortuneType,
    required this.when,
    required this.reasonTemplate,
    this.description,
    this.priority = 0,
    this.enabled = true,
  });

  /// JSON에서 파싱
  factory RuleModel.fromJson(Map<String, dynamic> json, {RuleType? defaultType}) {
    // type 파싱
    final typeCode = json['type'] as String?;
    final type = typeCode != null
        ? RuleType.fromCode(typeCode) ?? defaultType ?? RuleType.sinsal
        : defaultType ?? RuleType.sinsal;

    // fortuneType 파싱
    final fortuneCode = json['fortuneType'] as String?;
    final fortuneType = fortuneCode != null
        ? FortuneType.fromString(fortuneCode) ?? FortuneType.jung
        : FortuneType.jung;

    // when 조건 파싱
    final whenJson = json['when'] as Map<String, dynamic>?;
    if (whenJson == null) {
      throw FormatException('when 필드가 필요합니다: ${json['id']}');
    }
    final when = RuleCondition.fromJson(whenJson);

    return RuleModel(
      id: json['id'] as String,
      name: json['name'] as String,
      hanja: json['hanja'] as String?,
      type: type,
      category: json['category'] as String? ?? type.korean,
      fortuneType: fortuneType,
      when: when,
      reasonTemplate: json['reasonTemplate'] as String? ?? '{name}',
      description: json['description'] as String?,
      priority: json['priority'] as int? ?? 0,
      enabled: json['enabled'] as bool? ?? true,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        if (hanja != null) 'hanja': hanja,
        'type': type.code,
        'category': category,
        'fortuneType': fortuneType.korean,
        'when': when.toJson(),
        'reasonTemplate': reasonTemplate,
        if (description != null) 'description': description,
        'priority': priority,
        'enabled': enabled,
      };

  @override
  String toString() => 'RuleModel($id: $name)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RuleModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// 룰셋 JSON 파싱 결과
class RuleSetParseResult {
  /// 메타데이터
  final RuleSetMeta meta;

  /// 파싱된 룰 리스트
  final List<RuleModel> rules;

  /// 파싱 중 발생한 경고/에러
  final List<String> warnings;

  const RuleSetParseResult({
    required this.meta,
    required this.rules,
    this.warnings = const [],
  });

  /// JSON에서 전체 룰셋 파싱
  ///
  /// [json] 룰셋 JSON
  /// [source] 소스 식별자 (디버깅용)
  factory RuleSetParseResult.fromJson(
    Map<String, dynamic> json, {
    String? source,
  }) {
    final warnings = <String>[];

    // 메타데이터 파싱
    final meta = RuleSetMeta.fromJson(json);

    // 기본 타입 (개별 룰에 type이 없을 때 사용)
    final defaultType = meta.ruleType;

    // 룰 리스트 파싱
    final rulesJson = json['rules'] as List? ?? [];
    final rules = <RuleModel>[];

    for (var i = 0; i < rulesJson.length; i++) {
      try {
        final ruleJson = rulesJson[i] as Map<String, dynamic>;
        final rule = RuleModel.fromJson(ruleJson, defaultType: defaultType);
        rules.add(rule);
      } catch (e) {
        final ruleId = (rulesJson[i] as Map<String, dynamic>?)?['id'] ?? 'unknown';
        warnings.add('룰 파싱 실패 [$i] ($ruleId): $e');
      }
    }

    return RuleSetParseResult(
      meta: RuleSetMeta(
        schemaVersion: meta.schemaVersion,
        ruleType: meta.ruleType,
        version: meta.version,
        lastModified: meta.lastModified,
        description: meta.description,
        ruleCount: rules.length,
      ),
      rules: rules,
      warnings: warnings,
    );
  }

  /// JSON으로 직렬화
  Map<String, dynamic> toJson() => {
        ...meta.toJson(),
        'rules': rules.map((r) => r.toJson()).toList(),
      };

  /// 파싱 성공 여부
  bool get isSuccess => warnings.isEmpty;

  /// 성공적으로 파싱된 룰 개수
  int get successCount => rules.length;
}

/// 룰셋 JSON 파서 헬퍼
class RuleParser {
  /// JSON 문자열에서 룰셋 파싱
  static RuleSetParseResult parseFromString(
    String jsonString, {
    String? source,
  }) {
    try {
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return RuleSetParseResult.fromJson(json, source: source);
    } catch (e) {
      throw FormatException('JSON 파싱 실패: $e');
    }
  }
}
