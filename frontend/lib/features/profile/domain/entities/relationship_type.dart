import 'package:easy_localization/easy_localization.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

enum RelationshipType {
  @JsonValue('me')
  me('profile.relationTypeMe'),
  @JsonValue('family')
  family('profile.categoryFamily'),
  @JsonValue('friend')
  friend('profile.categoryFriend'),
  @JsonValue('lover')
  lover('profile.categoryLover'),
  @JsonValue('work')
  work('profile.relationWorkColleague'),
  @JsonValue('other')
  other('profile.categoryOther'),
  @JsonValue('admin')
  admin('profile.relationTypeAdmin'); // 개발자 모드 전용 - UI에서 숨김 처리

  final String _i18nKey;
  const RelationshipType(this._i18nKey);

  /// 다국어 표시 라벨 (UI용)
  String get label => _i18nKey.tr();

  String toJson() => name;
  static RelationshipType fromJson(String json) => values.byName(json);

  /// UI에서 선택 가능한 관계 유형만 반환 (admin 제외)
  static List<RelationshipType> get selectableValues =>
      values.where((type) => type != admin).toList();
}
