import 'package:freezed_annotation/freezed_annotation.dart';

enum RelationshipType {
  @JsonValue('me')
  me('나'),
  @JsonValue('family')
  family('가족'),
  @JsonValue('friend')
  friend('친구'),
  @JsonValue('lover')
  lover('연인'),
  @JsonValue('work')
  work('동료'),
  @JsonValue('other')
  other('기타'),
  @JsonValue('admin')
  admin('관리자'); // 개발자 모드 전용 - UI에서 숨김 처리

  final String label;
  const RelationshipType(this.label);

  String toJson() => name;
  static RelationshipType fromJson(String json) => values.byName(json);

  /// UI에서 선택 가능한 관계 유형만 반환 (admin 제외)
  static List<RelationshipType> get selectableValues =>
      values.where((type) => type != admin).toList();
}
