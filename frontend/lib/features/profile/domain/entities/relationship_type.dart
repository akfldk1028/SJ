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
  other('기타');

  final String label;
  const RelationshipType(this.label);

  String toJson() => name;
  static RelationshipType fromJson(String json) => values.byName(json);
}
