/// RuleEngine - Rule 인터페이스 정의
///
/// Phase 10-A: 기반 구축
/// 목적: 하드코딩된 룰을 JSON으로 분리하여 운영 유연성 확보
///
/// 설계 원칙:
/// - 인터페이스는 완성형 (확장 대비)
/// - 구현은 MVP (빠른 출시)
/// - 하위 호환성 (기존 로직 유지)
library;

import 'rule_condition.dart';

// ============================================================================
// Rule Type
// ============================================================================

/// 룰 카테고리 (룰 종류별 분류)
enum RuleType {
  /// 신살 (神殺) - 12신살 + 특수신살
  sinsal('sinsal', '신살'),

  /// 합충 (合沖) - 천간합/충, 지지육합/삼합/방합/충
  hapchung('hapchung', '합충'),

  /// 형파해 (刑破害) - 지지형/파/해/원진
  hyungpahae('hyungpahae', '형파해'),

  /// 십성 (十星) - 비견, 겁재, 식신 등
  sipsin('sipsin', '십성'),

  /// 12운성 (十二運星) - 장생, 목욕, 관대 등
  unsung('unsung', '12운성'),

  /// 지장간 (支藏干) - 지지 속 숨은 천간
  jijanggan('jijanggan', '지장간'),

  /// 공망 (空亡) - 60갑자 빈 지지
  gongmang('gongmang', '공망'),

  /// 격국 (格局) - 사주 구조 패턴
  gyeokguk('gyeokguk', '격국'),

  /// 대운 (大運) - 10년 운세 주기
  daeun('daeun', '대운');

  final String code;
  final String korean;

  const RuleType(this.code, this.korean);

  /// code로 RuleType 조회
  static RuleType? fromCode(String code) {
    for (final type in RuleType.values) {
      if (type.code == code) return type;
    }
    return null;
  }
}

/// 룰 길흉 분류
enum FortuneType {
  /// 길 (吉) - 좋은 작용
  gil('길', '吉'),

  /// 흉 (凶) - 나쁜 작용
  hyung('흉', '凶'),

  /// 중 (中) - 중립/혼합
  jung('중', '中');

  final String korean;
  final String hanja;

  const FortuneType(this.korean, this.hanja);

  /// 문자열로 FortuneType 조회
  static FortuneType? fromString(String value) {
    switch (value) {
      case '길':
      case 'gil':
        return FortuneType.gil;
      case '흉':
      case 'hyung':
        return FortuneType.hyung;
      case '중':
      case 'jung':
      case '길흉혼합':
        return FortuneType.jung;
      default:
        return null;
    }
  }
}

// ============================================================================
// Rule Interface
// ============================================================================

/// 룰 인터페이스 - 모든 룰의 기본 구조
///
/// JSON 구조 예시:
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
abstract class Rule {
  /// 룰 고유 ID (snake_case)
  String get id;

  /// 룰 이름 (한글)
  String get name;

  /// 룰 이름 (한자, 선택)
  String? get hanja;

  /// 룰 타입
  RuleType get type;

  /// 세부 카테고리 (예: "12신살", "특수신살", "천간합")
  String get category;

  /// 길흉 분류
  FortuneType get fortuneType;

  /// 매칭 조건
  RuleCondition get when;

  /// 결과 템플릿 (예: "{dayGan}에서 {matchedJi}가 {name}")
  String get reasonTemplate;

  /// 상세 설명
  String? get description;

  /// 우선순위 (높을수록 먼저 표시, 기본 0)
  int get priority;

  /// 활성화 여부
  bool get enabled;

  /// JSON으로 변환
  Map<String, dynamic> toJson();
}

// ============================================================================
// Rule Match Result
// ============================================================================

/// 룰 매칭 결과
class RuleMatchResult {
  /// 매칭된 룰
  final Rule rule;

  /// 매칭된 위치들 (예: ["년지", "일지"])
  final List<String> matchedPositions;

  /// 바인딩된 값들 (템플릿 치환용)
  final Map<String, String> bindings;

  /// 매칭 점수 (같은 룰 여러 개 매칭 시 정렬용)
  final int score;

  const RuleMatchResult({
    required this.rule,
    this.matchedPositions = const [],
    this.bindings = const {},
    this.score = 0,
  });

  /// 결과 메시지 생성 (템플릿 바인딩)
  String get reason {
    var result = rule.reasonTemplate;
    for (final entry in bindings.entries) {
      result = result.replaceAll('{${entry.key}}', entry.value);
    }
    // 바인딩 안된 플레이스홀더 제거
    result = result.replaceAll(RegExp(r'\{[^}]+\}'), '');
    return result.trim();
  }

  /// 룰 이름 + 한자
  String get displayName {
    if (rule.hanja != null && rule.hanja!.isNotEmpty) {
      return '${rule.name}(${rule.hanja})';
    }
    return rule.name;
  }

  @override
  String toString() => 'RuleMatchResult(${rule.name}, positions: $matchedPositions)';
}

// ============================================================================
// Rule Set Metadata
// ============================================================================

/// 룰셋 메타데이터 (JSON 파일 헤더)
class RuleSetMeta {
  /// 스키마 버전 (예: "1.0.0")
  final String schemaVersion;

  /// 룰 타입
  final RuleType ruleType;

  /// 룰셋 버전 (예: "2024.12.08")
  final String version;

  /// 마지막 수정일
  final DateTime? lastModified;

  /// 설명
  final String? description;

  /// 룰 개수
  final int ruleCount;

  const RuleSetMeta({
    required this.schemaVersion,
    required this.ruleType,
    required this.version,
    this.lastModified,
    this.description,
    this.ruleCount = 0,
  });

  factory RuleSetMeta.fromJson(Map<String, dynamic> json) {
    return RuleSetMeta(
      schemaVersion: json['schemaVersion'] as String? ?? '1.0.0',
      ruleType: RuleType.fromCode(json['ruleType'] as String? ?? '') ?? RuleType.sinsal,
      version: json['version'] as String? ?? '1.0.0',
      lastModified: json['lastModified'] != null
          ? DateTime.tryParse(json['lastModified'] as String)
          : null,
      description: json['description'] as String?,
      ruleCount: (json['rules'] as List?)?.length ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'schemaVersion': schemaVersion,
        'ruleType': ruleType.code,
        'version': version,
        if (lastModified != null) 'lastModified': lastModified!.toIso8601String(),
        if (description != null) 'description': description,
      };
}
