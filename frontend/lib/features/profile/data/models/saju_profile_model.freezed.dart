// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'saju_profile_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SajuProfileModel {

 String get id; String get displayName; String get gender;// Gender enum을 문자열로 저장
 DateTime get birthDate; bool get isLunar; bool get isLeapMonth; int? get birthTimeMinutes; bool get birthTimeUnknown; bool get useYaJasi; String get birthCity; int get timeCorrection; DateTime get createdAt; DateTime get updatedAt; bool get isActive; String get relationType;// RelationshipType enum name (deprecated)
/// 프로필 유형: 'primary' (본인) | 'other' (관계인)
/// DB의 profile_type 컬럼에 매핑
 String get profileType; String? get memo;/// UI/AI 응답 언어 (ko, ja, en)
 String get locale;
/// Create a copy of SajuProfileModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SajuProfileModelCopyWith<SajuProfileModel> get copyWith => _$SajuProfileModelCopyWithImpl<SajuProfileModel>(this as SajuProfileModel, _$identity);

  /// Serializes this SajuProfileModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SajuProfileModel&&(identical(other.id, id) || other.id == id)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.gender, gender) || other.gender == gender)&&(identical(other.birthDate, birthDate) || other.birthDate == birthDate)&&(identical(other.isLunar, isLunar) || other.isLunar == isLunar)&&(identical(other.isLeapMonth, isLeapMonth) || other.isLeapMonth == isLeapMonth)&&(identical(other.birthTimeMinutes, birthTimeMinutes) || other.birthTimeMinutes == birthTimeMinutes)&&(identical(other.birthTimeUnknown, birthTimeUnknown) || other.birthTimeUnknown == birthTimeUnknown)&&(identical(other.useYaJasi, useYaJasi) || other.useYaJasi == useYaJasi)&&(identical(other.birthCity, birthCity) || other.birthCity == birthCity)&&(identical(other.timeCorrection, timeCorrection) || other.timeCorrection == timeCorrection)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.relationType, relationType) || other.relationType == relationType)&&(identical(other.profileType, profileType) || other.profileType == profileType)&&(identical(other.memo, memo) || other.memo == memo)&&(identical(other.locale, locale) || other.locale == locale));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,displayName,gender,birthDate,isLunar,isLeapMonth,birthTimeMinutes,birthTimeUnknown,useYaJasi,birthCity,timeCorrection,createdAt,updatedAt,isActive,relationType,profileType,memo,locale);

@override
String toString() {
  return 'SajuProfileModel(id: $id, displayName: $displayName, gender: $gender, birthDate: $birthDate, isLunar: $isLunar, isLeapMonth: $isLeapMonth, birthTimeMinutes: $birthTimeMinutes, birthTimeUnknown: $birthTimeUnknown, useYaJasi: $useYaJasi, birthCity: $birthCity, timeCorrection: $timeCorrection, createdAt: $createdAt, updatedAt: $updatedAt, isActive: $isActive, relationType: $relationType, profileType: $profileType, memo: $memo, locale: $locale)';
}


}

/// @nodoc
abstract mixin class $SajuProfileModelCopyWith<$Res>  {
  factory $SajuProfileModelCopyWith(SajuProfileModel value, $Res Function(SajuProfileModel) _then) = _$SajuProfileModelCopyWithImpl;
@useResult
$Res call({
 String id, String displayName, String gender, DateTime birthDate, bool isLunar, bool isLeapMonth, int? birthTimeMinutes, bool birthTimeUnknown, bool useYaJasi, String birthCity, int timeCorrection, DateTime createdAt, DateTime updatedAt, bool isActive, String relationType, String profileType, String? memo, String locale
});




}
/// @nodoc
class _$SajuProfileModelCopyWithImpl<$Res>
    implements $SajuProfileModelCopyWith<$Res> {
  _$SajuProfileModelCopyWithImpl(this._self, this._then);

  final SajuProfileModel _self;
  final $Res Function(SajuProfileModel) _then;

/// Create a copy of SajuProfileModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? displayName = null,Object? gender = null,Object? birthDate = null,Object? isLunar = null,Object? isLeapMonth = null,Object? birthTimeMinutes = freezed,Object? birthTimeUnknown = null,Object? useYaJasi = null,Object? birthCity = null,Object? timeCorrection = null,Object? createdAt = null,Object? updatedAt = null,Object? isActive = null,Object? relationType = null,Object? profileType = null,Object? memo = freezed,Object? locale = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,gender: null == gender ? _self.gender : gender // ignore: cast_nullable_to_non_nullable
as String,birthDate: null == birthDate ? _self.birthDate : birthDate // ignore: cast_nullable_to_non_nullable
as DateTime,isLunar: null == isLunar ? _self.isLunar : isLunar // ignore: cast_nullable_to_non_nullable
as bool,isLeapMonth: null == isLeapMonth ? _self.isLeapMonth : isLeapMonth // ignore: cast_nullable_to_non_nullable
as bool,birthTimeMinutes: freezed == birthTimeMinutes ? _self.birthTimeMinutes : birthTimeMinutes // ignore: cast_nullable_to_non_nullable
as int?,birthTimeUnknown: null == birthTimeUnknown ? _self.birthTimeUnknown : birthTimeUnknown // ignore: cast_nullable_to_non_nullable
as bool,useYaJasi: null == useYaJasi ? _self.useYaJasi : useYaJasi // ignore: cast_nullable_to_non_nullable
as bool,birthCity: null == birthCity ? _self.birthCity : birthCity // ignore: cast_nullable_to_non_nullable
as String,timeCorrection: null == timeCorrection ? _self.timeCorrection : timeCorrection // ignore: cast_nullable_to_non_nullable
as int,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,relationType: null == relationType ? _self.relationType : relationType // ignore: cast_nullable_to_non_nullable
as String,profileType: null == profileType ? _self.profileType : profileType // ignore: cast_nullable_to_non_nullable
as String,memo: freezed == memo ? _self.memo : memo // ignore: cast_nullable_to_non_nullable
as String?,locale: null == locale ? _self.locale : locale // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [SajuProfileModel].
extension SajuProfileModelPatterns on SajuProfileModel {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SajuProfileModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SajuProfileModel() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SajuProfileModel value)  $default,){
final _that = this;
switch (_that) {
case _SajuProfileModel():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SajuProfileModel value)?  $default,){
final _that = this;
switch (_that) {
case _SajuProfileModel() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String displayName,  String gender,  DateTime birthDate,  bool isLunar,  bool isLeapMonth,  int? birthTimeMinutes,  bool birthTimeUnknown,  bool useYaJasi,  String birthCity,  int timeCorrection,  DateTime createdAt,  DateTime updatedAt,  bool isActive,  String relationType,  String profileType,  String? memo,  String locale)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SajuProfileModel() when $default != null:
return $default(_that.id,_that.displayName,_that.gender,_that.birthDate,_that.isLunar,_that.isLeapMonth,_that.birthTimeMinutes,_that.birthTimeUnknown,_that.useYaJasi,_that.birthCity,_that.timeCorrection,_that.createdAt,_that.updatedAt,_that.isActive,_that.relationType,_that.profileType,_that.memo,_that.locale);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String displayName,  String gender,  DateTime birthDate,  bool isLunar,  bool isLeapMonth,  int? birthTimeMinutes,  bool birthTimeUnknown,  bool useYaJasi,  String birthCity,  int timeCorrection,  DateTime createdAt,  DateTime updatedAt,  bool isActive,  String relationType,  String profileType,  String? memo,  String locale)  $default,) {final _that = this;
switch (_that) {
case _SajuProfileModel():
return $default(_that.id,_that.displayName,_that.gender,_that.birthDate,_that.isLunar,_that.isLeapMonth,_that.birthTimeMinutes,_that.birthTimeUnknown,_that.useYaJasi,_that.birthCity,_that.timeCorrection,_that.createdAt,_that.updatedAt,_that.isActive,_that.relationType,_that.profileType,_that.memo,_that.locale);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String displayName,  String gender,  DateTime birthDate,  bool isLunar,  bool isLeapMonth,  int? birthTimeMinutes,  bool birthTimeUnknown,  bool useYaJasi,  String birthCity,  int timeCorrection,  DateTime createdAt,  DateTime updatedAt,  bool isActive,  String relationType,  String profileType,  String? memo,  String locale)?  $default,) {final _that = this;
switch (_that) {
case _SajuProfileModel() when $default != null:
return $default(_that.id,_that.displayName,_that.gender,_that.birthDate,_that.isLunar,_that.isLeapMonth,_that.birthTimeMinutes,_that.birthTimeUnknown,_that.useYaJasi,_that.birthCity,_that.timeCorrection,_that.createdAt,_that.updatedAt,_that.isActive,_that.relationType,_that.profileType,_that.memo,_that.locale);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SajuProfileModel extends SajuProfileModel {
  const _SajuProfileModel({required this.id, required this.displayName, required this.gender, required this.birthDate, required this.isLunar, this.isLeapMonth = false, this.birthTimeMinutes, this.birthTimeUnknown = false, this.useYaJasi = true, required this.birthCity, this.timeCorrection = 0, required this.createdAt, required this.updatedAt, this.isActive = false, this.relationType = 'me', this.profileType = 'primary', this.memo, this.locale = 'ko'}): super._();
  factory _SajuProfileModel.fromJson(Map<String, dynamic> json) => _$SajuProfileModelFromJson(json);

@override final  String id;
@override final  String displayName;
@override final  String gender;
// Gender enum을 문자열로 저장
@override final  DateTime birthDate;
@override final  bool isLunar;
@override@JsonKey() final  bool isLeapMonth;
@override final  int? birthTimeMinutes;
@override@JsonKey() final  bool birthTimeUnknown;
@override@JsonKey() final  bool useYaJasi;
@override final  String birthCity;
@override@JsonKey() final  int timeCorrection;
@override final  DateTime createdAt;
@override final  DateTime updatedAt;
@override@JsonKey() final  bool isActive;
@override@JsonKey() final  String relationType;
// RelationshipType enum name (deprecated)
/// 프로필 유형: 'primary' (본인) | 'other' (관계인)
/// DB의 profile_type 컬럼에 매핑
@override@JsonKey() final  String profileType;
@override final  String? memo;
/// UI/AI 응답 언어 (ko, ja, en)
@override@JsonKey() final  String locale;

/// Create a copy of SajuProfileModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SajuProfileModelCopyWith<_SajuProfileModel> get copyWith => __$SajuProfileModelCopyWithImpl<_SajuProfileModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SajuProfileModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SajuProfileModel&&(identical(other.id, id) || other.id == id)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.gender, gender) || other.gender == gender)&&(identical(other.birthDate, birthDate) || other.birthDate == birthDate)&&(identical(other.isLunar, isLunar) || other.isLunar == isLunar)&&(identical(other.isLeapMonth, isLeapMonth) || other.isLeapMonth == isLeapMonth)&&(identical(other.birthTimeMinutes, birthTimeMinutes) || other.birthTimeMinutes == birthTimeMinutes)&&(identical(other.birthTimeUnknown, birthTimeUnknown) || other.birthTimeUnknown == birthTimeUnknown)&&(identical(other.useYaJasi, useYaJasi) || other.useYaJasi == useYaJasi)&&(identical(other.birthCity, birthCity) || other.birthCity == birthCity)&&(identical(other.timeCorrection, timeCorrection) || other.timeCorrection == timeCorrection)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.relationType, relationType) || other.relationType == relationType)&&(identical(other.profileType, profileType) || other.profileType == profileType)&&(identical(other.memo, memo) || other.memo == memo)&&(identical(other.locale, locale) || other.locale == locale));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,displayName,gender,birthDate,isLunar,isLeapMonth,birthTimeMinutes,birthTimeUnknown,useYaJasi,birthCity,timeCorrection,createdAt,updatedAt,isActive,relationType,profileType,memo,locale);

@override
String toString() {
  return 'SajuProfileModel(id: $id, displayName: $displayName, gender: $gender, birthDate: $birthDate, isLunar: $isLunar, isLeapMonth: $isLeapMonth, birthTimeMinutes: $birthTimeMinutes, birthTimeUnknown: $birthTimeUnknown, useYaJasi: $useYaJasi, birthCity: $birthCity, timeCorrection: $timeCorrection, createdAt: $createdAt, updatedAt: $updatedAt, isActive: $isActive, relationType: $relationType, profileType: $profileType, memo: $memo, locale: $locale)';
}


}

/// @nodoc
abstract mixin class _$SajuProfileModelCopyWith<$Res> implements $SajuProfileModelCopyWith<$Res> {
  factory _$SajuProfileModelCopyWith(_SajuProfileModel value, $Res Function(_SajuProfileModel) _then) = __$SajuProfileModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String displayName, String gender, DateTime birthDate, bool isLunar, bool isLeapMonth, int? birthTimeMinutes, bool birthTimeUnknown, bool useYaJasi, String birthCity, int timeCorrection, DateTime createdAt, DateTime updatedAt, bool isActive, String relationType, String profileType, String? memo, String locale
});




}
/// @nodoc
class __$SajuProfileModelCopyWithImpl<$Res>
    implements _$SajuProfileModelCopyWith<$Res> {
  __$SajuProfileModelCopyWithImpl(this._self, this._then);

  final _SajuProfileModel _self;
  final $Res Function(_SajuProfileModel) _then;

/// Create a copy of SajuProfileModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? displayName = null,Object? gender = null,Object? birthDate = null,Object? isLunar = null,Object? isLeapMonth = null,Object? birthTimeMinutes = freezed,Object? birthTimeUnknown = null,Object? useYaJasi = null,Object? birthCity = null,Object? timeCorrection = null,Object? createdAt = null,Object? updatedAt = null,Object? isActive = null,Object? relationType = null,Object? profileType = null,Object? memo = freezed,Object? locale = null,}) {
  return _then(_SajuProfileModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,gender: null == gender ? _self.gender : gender // ignore: cast_nullable_to_non_nullable
as String,birthDate: null == birthDate ? _self.birthDate : birthDate // ignore: cast_nullable_to_non_nullable
as DateTime,isLunar: null == isLunar ? _self.isLunar : isLunar // ignore: cast_nullable_to_non_nullable
as bool,isLeapMonth: null == isLeapMonth ? _self.isLeapMonth : isLeapMonth // ignore: cast_nullable_to_non_nullable
as bool,birthTimeMinutes: freezed == birthTimeMinutes ? _self.birthTimeMinutes : birthTimeMinutes // ignore: cast_nullable_to_non_nullable
as int?,birthTimeUnknown: null == birthTimeUnknown ? _self.birthTimeUnknown : birthTimeUnknown // ignore: cast_nullable_to_non_nullable
as bool,useYaJasi: null == useYaJasi ? _self.useYaJasi : useYaJasi // ignore: cast_nullable_to_non_nullable
as bool,birthCity: null == birthCity ? _self.birthCity : birthCity // ignore: cast_nullable_to_non_nullable
as String,timeCorrection: null == timeCorrection ? _self.timeCorrection : timeCorrection // ignore: cast_nullable_to_non_nullable
as int,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,relationType: null == relationType ? _self.relationType : relationType // ignore: cast_nullable_to_non_nullable
as String,profileType: null == profileType ? _self.profileType : profileType // ignore: cast_nullable_to_non_nullable
as String,memo: freezed == memo ? _self.memo : memo // ignore: cast_nullable_to_non_nullable
as String?,locale: null == locale ? _self.locale : locale // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
