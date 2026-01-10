// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'saju_profile.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SajuProfile {

/// 프로필 고유 ID
 String get id;/// 표시 이름 (최대 12자)
 String get displayName;/// 성별
 Gender get gender;/// 생년월일 (양력 기준으로 저장)
 DateTime get birthDate;/// 음력 여부
 bool get isLunar;/// 음력 윤달 여부 (음력일 때만 의미)
 bool get isLeapMonth;/// 출생시간 (분 단위, 0~1439)
/// null이면 시간을 모르는 경우
 int? get birthTimeMinutes;/// 시간 모름 여부
 bool get birthTimeUnknown;/// 야자시/조자시 설정
/// true: 야자시 (23:00-01:00을 다음날 자시로 계산)
/// false: 조자시 (23:00-01:00을 당일 자시로 계산)
 bool get useYaJasi;/// 출생 도시 (진태양시 계산용)
 String get birthCity;/// 진태양시 보정값 (분 단위)
/// 자동으로 계산되어 저장됨
 int get timeCorrection;/// 생성 일시
 DateTime get createdAt;/// 수정 일시
 DateTime get updatedAt;/// 현재 활성 프로필 여부
/// 한 번에 하나의 프로필만 활성화 가능
 bool get isActive;/// 관계 유형 (가족, 친구, 연인 등) - deprecated, profileType 사용 권장
 RelationshipType get relationType;/// 프로필 유형: 'primary' (본인) | 'other' (관계인)
/// DB의 profile_type 컬럼에 매핑
 String get profileType;/// 메모
 String? get memo;
/// Create a copy of SajuProfile
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SajuProfileCopyWith<SajuProfile> get copyWith => _$SajuProfileCopyWithImpl<SajuProfile>(this as SajuProfile, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SajuProfile&&(identical(other.id, id) || other.id == id)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.gender, gender) || other.gender == gender)&&(identical(other.birthDate, birthDate) || other.birthDate == birthDate)&&(identical(other.isLunar, isLunar) || other.isLunar == isLunar)&&(identical(other.isLeapMonth, isLeapMonth) || other.isLeapMonth == isLeapMonth)&&(identical(other.birthTimeMinutes, birthTimeMinutes) || other.birthTimeMinutes == birthTimeMinutes)&&(identical(other.birthTimeUnknown, birthTimeUnknown) || other.birthTimeUnknown == birthTimeUnknown)&&(identical(other.useYaJasi, useYaJasi) || other.useYaJasi == useYaJasi)&&(identical(other.birthCity, birthCity) || other.birthCity == birthCity)&&(identical(other.timeCorrection, timeCorrection) || other.timeCorrection == timeCorrection)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.relationType, relationType) || other.relationType == relationType)&&(identical(other.profileType, profileType) || other.profileType == profileType)&&(identical(other.memo, memo) || other.memo == memo));
}


@override
int get hashCode => Object.hash(runtimeType,id,displayName,gender,birthDate,isLunar,isLeapMonth,birthTimeMinutes,birthTimeUnknown,useYaJasi,birthCity,timeCorrection,createdAt,updatedAt,isActive,relationType,profileType,memo);

@override
String toString() {
  return 'SajuProfile(id: $id, displayName: $displayName, gender: $gender, birthDate: $birthDate, isLunar: $isLunar, isLeapMonth: $isLeapMonth, birthTimeMinutes: $birthTimeMinutes, birthTimeUnknown: $birthTimeUnknown, useYaJasi: $useYaJasi, birthCity: $birthCity, timeCorrection: $timeCorrection, createdAt: $createdAt, updatedAt: $updatedAt, isActive: $isActive, relationType: $relationType, profileType: $profileType, memo: $memo)';
}


}

/// @nodoc
abstract mixin class $SajuProfileCopyWith<$Res>  {
  factory $SajuProfileCopyWith(SajuProfile value, $Res Function(SajuProfile) _then) = _$SajuProfileCopyWithImpl;
@useResult
$Res call({
 String id, String displayName, Gender gender, DateTime birthDate, bool isLunar, bool isLeapMonth, int? birthTimeMinutes, bool birthTimeUnknown, bool useYaJasi, String birthCity, int timeCorrection, DateTime createdAt, DateTime updatedAt, bool isActive, RelationshipType relationType, String profileType, String? memo
});




}
/// @nodoc
class _$SajuProfileCopyWithImpl<$Res>
    implements $SajuProfileCopyWith<$Res> {
  _$SajuProfileCopyWithImpl(this._self, this._then);

  final SajuProfile _self;
  final $Res Function(SajuProfile) _then;

/// Create a copy of SajuProfile
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? displayName = null,Object? gender = null,Object? birthDate = null,Object? isLunar = null,Object? isLeapMonth = null,Object? birthTimeMinutes = freezed,Object? birthTimeUnknown = null,Object? useYaJasi = null,Object? birthCity = null,Object? timeCorrection = null,Object? createdAt = null,Object? updatedAt = null,Object? isActive = null,Object? relationType = null,Object? profileType = null,Object? memo = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,gender: null == gender ? _self.gender : gender // ignore: cast_nullable_to_non_nullable
as Gender,birthDate: null == birthDate ? _self.birthDate : birthDate // ignore: cast_nullable_to_non_nullable
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
as RelationshipType,profileType: null == profileType ? _self.profileType : profileType // ignore: cast_nullable_to_non_nullable
as String,memo: freezed == memo ? _self.memo : memo // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [SajuProfile].
extension SajuProfilePatterns on SajuProfile {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SajuProfile value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SajuProfile() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SajuProfile value)  $default,){
final _that = this;
switch (_that) {
case _SajuProfile():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SajuProfile value)?  $default,){
final _that = this;
switch (_that) {
case _SajuProfile() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String displayName,  Gender gender,  DateTime birthDate,  bool isLunar,  bool isLeapMonth,  int? birthTimeMinutes,  bool birthTimeUnknown,  bool useYaJasi,  String birthCity,  int timeCorrection,  DateTime createdAt,  DateTime updatedAt,  bool isActive,  RelationshipType relationType,  String profileType,  String? memo)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SajuProfile() when $default != null:
return $default(_that.id,_that.displayName,_that.gender,_that.birthDate,_that.isLunar,_that.isLeapMonth,_that.birthTimeMinutes,_that.birthTimeUnknown,_that.useYaJasi,_that.birthCity,_that.timeCorrection,_that.createdAt,_that.updatedAt,_that.isActive,_that.relationType,_that.profileType,_that.memo);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String displayName,  Gender gender,  DateTime birthDate,  bool isLunar,  bool isLeapMonth,  int? birthTimeMinutes,  bool birthTimeUnknown,  bool useYaJasi,  String birthCity,  int timeCorrection,  DateTime createdAt,  DateTime updatedAt,  bool isActive,  RelationshipType relationType,  String profileType,  String? memo)  $default,) {final _that = this;
switch (_that) {
case _SajuProfile():
return $default(_that.id,_that.displayName,_that.gender,_that.birthDate,_that.isLunar,_that.isLeapMonth,_that.birthTimeMinutes,_that.birthTimeUnknown,_that.useYaJasi,_that.birthCity,_that.timeCorrection,_that.createdAt,_that.updatedAt,_that.isActive,_that.relationType,_that.profileType,_that.memo);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String displayName,  Gender gender,  DateTime birthDate,  bool isLunar,  bool isLeapMonth,  int? birthTimeMinutes,  bool birthTimeUnknown,  bool useYaJasi,  String birthCity,  int timeCorrection,  DateTime createdAt,  DateTime updatedAt,  bool isActive,  RelationshipType relationType,  String profileType,  String? memo)?  $default,) {final _that = this;
switch (_that) {
case _SajuProfile() when $default != null:
return $default(_that.id,_that.displayName,_that.gender,_that.birthDate,_that.isLunar,_that.isLeapMonth,_that.birthTimeMinutes,_that.birthTimeUnknown,_that.useYaJasi,_that.birthCity,_that.timeCorrection,_that.createdAt,_that.updatedAt,_that.isActive,_that.relationType,_that.profileType,_that.memo);case _:
  return null;

}
}

}

/// @nodoc


class _SajuProfile extends SajuProfile {
  const _SajuProfile({required this.id, required this.displayName, required this.gender, required this.birthDate, required this.isLunar, this.isLeapMonth = false, this.birthTimeMinutes, this.birthTimeUnknown = false, this.useYaJasi = true, required this.birthCity, this.timeCorrection = 0, required this.createdAt, required this.updatedAt, this.isActive = false, this.relationType = RelationshipType.me, this.profileType = 'primary', this.memo}): super._();
  

/// 프로필 고유 ID
@override final  String id;
/// 표시 이름 (최대 12자)
@override final  String displayName;
/// 성별
@override final  Gender gender;
/// 생년월일 (양력 기준으로 저장)
@override final  DateTime birthDate;
/// 음력 여부
@override final  bool isLunar;
/// 음력 윤달 여부 (음력일 때만 의미)
@override@JsonKey() final  bool isLeapMonth;
/// 출생시간 (분 단위, 0~1439)
/// null이면 시간을 모르는 경우
@override final  int? birthTimeMinutes;
/// 시간 모름 여부
@override@JsonKey() final  bool birthTimeUnknown;
/// 야자시/조자시 설정
/// true: 야자시 (23:00-01:00을 다음날 자시로 계산)
/// false: 조자시 (23:00-01:00을 당일 자시로 계산)
@override@JsonKey() final  bool useYaJasi;
/// 출생 도시 (진태양시 계산용)
@override final  String birthCity;
/// 진태양시 보정값 (분 단위)
/// 자동으로 계산되어 저장됨
@override@JsonKey() final  int timeCorrection;
/// 생성 일시
@override final  DateTime createdAt;
/// 수정 일시
@override final  DateTime updatedAt;
/// 현재 활성 프로필 여부
/// 한 번에 하나의 프로필만 활성화 가능
@override@JsonKey() final  bool isActive;
/// 관계 유형 (가족, 친구, 연인 등) - deprecated, profileType 사용 권장
@override@JsonKey() final  RelationshipType relationType;
/// 프로필 유형: 'primary' (본인) | 'other' (관계인)
/// DB의 profile_type 컬럼에 매핑
@override@JsonKey() final  String profileType;
/// 메모
@override final  String? memo;

/// Create a copy of SajuProfile
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SajuProfileCopyWith<_SajuProfile> get copyWith => __$SajuProfileCopyWithImpl<_SajuProfile>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SajuProfile&&(identical(other.id, id) || other.id == id)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.gender, gender) || other.gender == gender)&&(identical(other.birthDate, birthDate) || other.birthDate == birthDate)&&(identical(other.isLunar, isLunar) || other.isLunar == isLunar)&&(identical(other.isLeapMonth, isLeapMonth) || other.isLeapMonth == isLeapMonth)&&(identical(other.birthTimeMinutes, birthTimeMinutes) || other.birthTimeMinutes == birthTimeMinutes)&&(identical(other.birthTimeUnknown, birthTimeUnknown) || other.birthTimeUnknown == birthTimeUnknown)&&(identical(other.useYaJasi, useYaJasi) || other.useYaJasi == useYaJasi)&&(identical(other.birthCity, birthCity) || other.birthCity == birthCity)&&(identical(other.timeCorrection, timeCorrection) || other.timeCorrection == timeCorrection)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.relationType, relationType) || other.relationType == relationType)&&(identical(other.profileType, profileType) || other.profileType == profileType)&&(identical(other.memo, memo) || other.memo == memo));
}


@override
int get hashCode => Object.hash(runtimeType,id,displayName,gender,birthDate,isLunar,isLeapMonth,birthTimeMinutes,birthTimeUnknown,useYaJasi,birthCity,timeCorrection,createdAt,updatedAt,isActive,relationType,profileType,memo);

@override
String toString() {
  return 'SajuProfile(id: $id, displayName: $displayName, gender: $gender, birthDate: $birthDate, isLunar: $isLunar, isLeapMonth: $isLeapMonth, birthTimeMinutes: $birthTimeMinutes, birthTimeUnknown: $birthTimeUnknown, useYaJasi: $useYaJasi, birthCity: $birthCity, timeCorrection: $timeCorrection, createdAt: $createdAt, updatedAt: $updatedAt, isActive: $isActive, relationType: $relationType, profileType: $profileType, memo: $memo)';
}


}

/// @nodoc
abstract mixin class _$SajuProfileCopyWith<$Res> implements $SajuProfileCopyWith<$Res> {
  factory _$SajuProfileCopyWith(_SajuProfile value, $Res Function(_SajuProfile) _then) = __$SajuProfileCopyWithImpl;
@override @useResult
$Res call({
 String id, String displayName, Gender gender, DateTime birthDate, bool isLunar, bool isLeapMonth, int? birthTimeMinutes, bool birthTimeUnknown, bool useYaJasi, String birthCity, int timeCorrection, DateTime createdAt, DateTime updatedAt, bool isActive, RelationshipType relationType, String profileType, String? memo
});




}
/// @nodoc
class __$SajuProfileCopyWithImpl<$Res>
    implements _$SajuProfileCopyWith<$Res> {
  __$SajuProfileCopyWithImpl(this._self, this._then);

  final _SajuProfile _self;
  final $Res Function(_SajuProfile) _then;

/// Create a copy of SajuProfile
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? displayName = null,Object? gender = null,Object? birthDate = null,Object? isLunar = null,Object? isLeapMonth = null,Object? birthTimeMinutes = freezed,Object? birthTimeUnknown = null,Object? useYaJasi = null,Object? birthCity = null,Object? timeCorrection = null,Object? createdAt = null,Object? updatedAt = null,Object? isActive = null,Object? relationType = null,Object? profileType = null,Object? memo = freezed,}) {
  return _then(_SajuProfile(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,gender: null == gender ? _self.gender : gender // ignore: cast_nullable_to_non_nullable
as Gender,birthDate: null == birthDate ? _self.birthDate : birthDate // ignore: cast_nullable_to_non_nullable
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
as RelationshipType,profileType: null == profileType ? _self.profileType : profileType // ignore: cast_nullable_to_non_nullable
as String,memo: freezed == memo ? _self.memo : memo // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
