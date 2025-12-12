/// RuleEngine - 사주 컨텍스트 정의
///
/// Phase 10-A: 기반 구축
/// RuleEngine에서 조건 평가 시 참조하는 사주 데이터 컨텍스트
///
/// SajuChart를 감싸면서 RuleCondition에서 필요한 모든 필드에
/// 일관된 인터페이스로 접근할 수 있도록 제공
library;

import '../entities/saju_chart.dart';
import '../../data/constants/cheongan_jiji.dart';
import 'rule_condition.dart';

/// 사주 컨텍스트 - RuleEngine용 데이터 래퍼
///
/// 주요 역할:
/// 1. SajuChart 데이터를 RuleCondition 필드와 매핑
/// 2. 파생 데이터 계산 (오행, 음양 등)
/// 3. 필드 조회의 일관된 인터페이스 제공
class SajuContext {
  /// 원본 사주 차트
  final SajuChart chart;

  /// 성별 ('남' 또는 '여', 선택)
  final String? gender;

  /// 추가 메타데이터 (확장용)
  final Map<String, dynamic> metadata;

  // 캐시된 데이터 (lazy initialization)
  late final CheonganJijiData _data = CheonganJijiData.instance;

  SajuContext({
    required this.chart,
    this.gender,
    this.metadata = const {},
  });

  // ============================================================================
  // 천간 (天干) 접근자
  // ============================================================================

  /// 년간 (年干)
  String get yearGan => chart.yearPillar.gan;

  /// 월간 (月干)
  String get monthGan => chart.monthPillar.gan;

  /// 일간 (日干) - "나"
  String get dayGan => chart.dayPillar.gan;

  /// 시간 (時干, null 가능)
  String? get hourGan => chart.hourPillar?.gan;

  /// 모든 천간 리스트
  List<String> get allGan {
    final result = [yearGan, monthGan, dayGan];
    if (hourGan != null) result.add(hourGan!);
    return result;
  }

  // ============================================================================
  // 지지 (地支) 접근자
  // ============================================================================

  /// 년지 (年支)
  String get yearJi => chart.yearPillar.ji;

  /// 월지 (月支)
  String get monthJi => chart.monthPillar.ji;

  /// 일지 (日支)
  String get dayJi => chart.dayPillar.ji;

  /// 시지 (時支, null 가능)
  String? get hourJi => chart.hourPillar?.ji;

  /// 모든 지지 리스트
  List<String> get allJi {
    final result = [yearJi, monthJi, dayJi];
    if (hourJi != null) result.add(hourJi!);
    return result;
  }

  /// 지지별 개수 (자형 등 판단용)
  Map<String, int> get jiCount {
    final counts = <String, int>{};
    for (final ji in allJi) {
      counts[ji] = (counts[ji] ?? 0) + 1;
    }
    return counts;
  }

  /// 천간별 개수
  Map<String, int> get ganCount {
    final counts = <String, int>{};
    for (final gan in allGan) {
      counts[gan] = (counts[gan] ?? 0) + 1;
    }
    return counts;
  }

  // ============================================================================
  // 일주 (日柱)
  // ============================================================================

  /// 일주 문자열 (예: "갑자")
  String get dayPillar => chart.dayPillar.fullName;

  // ============================================================================
  // 오행 (五行) 파생 데이터
  // ============================================================================

  /// 일간 오행
  String? get dayOheng => _data.getCheonganByHangul(dayGan)?.oheng;

  /// 년지 오행
  String? get yearJiOheng => _data.getJijiByHangul(yearJi)?.oheng;

  /// 월지 오행
  String? get monthJiOheng => _data.getJijiByHangul(monthJi)?.oheng;

  /// 일지 오행
  String? get dayJiOheng => _data.getJijiByHangul(dayJi)?.oheng;

  /// 시지 오행
  String? get hourJiOheng =>
      hourJi != null ? _data.getJijiByHangul(hourJi!)?.oheng : null;

  // ============================================================================
  // 음양 (陰陽) 파생 데이터
  // ============================================================================

  /// 일간 음양
  String? get dayEumYang => _data.getCheonganByHangul(dayGan)?.eumYang;

  // ============================================================================
  // 기타 컨텍스트 데이터
  // ============================================================================

  /// 생년
  int get birthYear => chart.birthDateTime.year;

  // ============================================================================
  // 필드 접근 인터페이스 (RuleCondition 평가용)
  // ============================================================================

  /// ConditionField로 값 조회
  ///
  /// 반환값:
  /// - 단일 값: String 또는 int
  /// - 다중 값 (ganAny, jiAny): List<String>
  /// - null: 해당 필드 없음 또는 값 없음
  dynamic getFieldValue(ConditionField field) {
    switch (field) {
      // 천간
      case ConditionField.yearGan:
        return yearGan;
      case ConditionField.monthGan:
        return monthGan;
      case ConditionField.dayGan:
        return dayGan;
      case ConditionField.hourGan:
        return hourGan;
      case ConditionField.ganAny:
        return allGan;

      // 지지
      case ConditionField.yearJi:
        return yearJi;
      case ConditionField.monthJi:
        return monthJi;
      case ConditionField.dayJi:
        return dayJi;
      case ConditionField.hourJi:
        return hourJi;
      case ConditionField.jiAny:
        return allJi;
      case ConditionField.jiCount:
        return jiCount;
      case ConditionField.ganCount:
        return ganCount;

      // 일주
      case ConditionField.dayPillar:
        return dayPillar;

      // 오행
      case ConditionField.dayOheng:
        return dayOheng;
      case ConditionField.yearJiOheng:
        return yearJiOheng;

      // 음양
      case ConditionField.dayEumYang:
        return dayEumYang;

      // 기타
      case ConditionField.gender:
        return gender;
      case ConditionField.birthYear:
        return birthYear;
    }
  }

  /// 문자열 필드명으로 값 조회 (JSON 조건에서 사용)
  dynamic getFieldValueByName(String fieldName) {
    final field = ConditionField.fromCode(fieldName);
    if (field == null) return null;
    return getFieldValue(field);
  }

  // ============================================================================
  // 위치별 지지 조회 (신살 분석용)
  // ============================================================================

  /// 위치 인덱스로 지지 조회 (0:년, 1:월, 2:일, 3:시)
  String? getJiByPosition(int position) {
    switch (position) {
      case 0:
        return yearJi;
      case 1:
        return monthJi;
      case 2:
        return dayJi;
      case 3:
        return hourJi;
      default:
        return null;
    }
  }

  /// 위치명으로 지지 조회
  String? getJiByPositionName(String positionName) {
    switch (positionName) {
      case '년지':
      case 'yearJi':
        return yearJi;
      case '월지':
      case 'monthJi':
        return monthJi;
      case '일지':
      case 'dayJi':
        return dayJi;
      case '시지':
      case 'hourJi':
        return hourJi;
      default:
        return null;
    }
  }

  /// 위치명 리스트 (순서 보장)
  static const List<String> positionNames = ['년지', '월지', '일지', '시지'];

  /// 특정 지지가 있는 위치들 반환
  List<String> findPositionsWithJi(String ji) {
    final positions = <String>[];
    if (yearJi == ji) positions.add('년지');
    if (monthJi == ji) positions.add('월지');
    if (dayJi == ji) positions.add('일지');
    if (hourJi == ji) positions.add('시지');
    return positions;
  }

  // ============================================================================
  // 팩토리 메서드
  // ============================================================================

  /// SajuChart에서 컨텍스트 생성
  factory SajuContext.fromChart(
    SajuChart chart, {
    String? gender,
    Map<String, dynamic>? metadata,
  }) {
    return SajuContext(
      chart: chart,
      gender: gender,
      metadata: metadata ?? const {},
    );
  }

  @override
  String toString() =>
      'SajuContext(${chart.fullSaju}, gender: $gender)';
}
