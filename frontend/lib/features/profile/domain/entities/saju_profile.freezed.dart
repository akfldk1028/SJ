// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'saju_profile.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$SajuProfile {
  /// 프로필 고유 ID
  String get id => throw _privateConstructorUsedError;

  /// 표시 이름 (최대 12자)
  String get displayName => throw _privateConstructorUsedError;

  /// 성별
  Gender get gender => throw _privateConstructorUsedError;

  /// 생년월일 (양력 기준으로 저장)
  DateTime get birthDate => throw _privateConstructorUsedError;

  /// 음력 여부
  bool get isLunar => throw _privateConstructorUsedError;

  /// 음력 윤달 여부 (음력일 때만 의미)
  bool get isLeapMonth => throw _privateConstructorUsedError;

  /// 출생시간 (분 단위, 0~1439)
  /// null이면 시간을 모르는 경우
  int? get birthTimeMinutes => throw _privateConstructorUsedError;

  /// 시간 모름 여부
  bool get birthTimeUnknown => throw _privateConstructorUsedError;

  /// 야자시/조자시 설정
  /// true: 야자시 (23:00-01:00을 다음날 자시로 계산)
  /// false: 조자시 (23:00-01:00을 당일 자시로 계산)
  bool get useYaJasi => throw _privateConstructorUsedError;

  /// 출생 도시 (진태양시 계산용)
  String get birthCity => throw _privateConstructorUsedError;

  /// 진태양시 보정값 (분 단위)
  /// 자동으로 계산되어 저장됨
  int get timeCorrection => throw _privateConstructorUsedError;

  /// 생성 일시
  DateTime get createdAt => throw _privateConstructorUsedError;

  /// 수정 일시
  DateTime get updatedAt => throw _privateConstructorUsedError;

  /// 현재 활성 프로필 여부
  /// 한 번에 하나의 프로필만 활성화 가능
  bool get isActive => throw _privateConstructorUsedError;

  /// 관계 유형 (가족, 친구, 연인 등)
  RelationshipType get relationType => throw _privateConstructorUsedError;

  /// 메모
  String? get memo => throw _privateConstructorUsedError;

  /// Create a copy of SajuProfile
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SajuProfileCopyWith<SajuProfile> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SajuProfileCopyWith<$Res> {
  factory $SajuProfileCopyWith(
    SajuProfile value,
    $Res Function(SajuProfile) then,
  ) = _$SajuProfileCopyWithImpl<$Res, SajuProfile>;
  @useResult
  $Res call({
    String id,
    String displayName,
    Gender gender,
    DateTime birthDate,
    bool isLunar,
    bool isLeapMonth,
    int? birthTimeMinutes,
    bool birthTimeUnknown,
    bool useYaJasi,
    String birthCity,
    int timeCorrection,
    DateTime createdAt,
    DateTime updatedAt,
    bool isActive,
    RelationshipType relationType,
    String? memo,
  });
}

/// @nodoc
class _$SajuProfileCopyWithImpl<$Res, $Val extends SajuProfile>
    implements $SajuProfileCopyWith<$Res> {
  _$SajuProfileCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SajuProfile
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? displayName = null,
    Object? gender = null,
    Object? birthDate = null,
    Object? isLunar = null,
    Object? isLeapMonth = null,
    Object? birthTimeMinutes = freezed,
    Object? birthTimeUnknown = null,
    Object? useYaJasi = null,
    Object? birthCity = null,
    Object? timeCorrection = null,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? isActive = null,
    Object? relationType = null,
    Object? memo = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            displayName: null == displayName
                ? _value.displayName
                : displayName // ignore: cast_nullable_to_non_nullable
                      as String,
            gender: null == gender
                ? _value.gender
                : gender // ignore: cast_nullable_to_non_nullable
                      as Gender,
            birthDate: null == birthDate
                ? _value.birthDate
                : birthDate // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            isLunar: null == isLunar
                ? _value.isLunar
                : isLunar // ignore: cast_nullable_to_non_nullable
                      as bool,
            isLeapMonth: null == isLeapMonth
                ? _value.isLeapMonth
                : isLeapMonth // ignore: cast_nullable_to_non_nullable
                      as bool,
            birthTimeMinutes: freezed == birthTimeMinutes
                ? _value.birthTimeMinutes
                : birthTimeMinutes // ignore: cast_nullable_to_non_nullable
                      as int?,
            birthTimeUnknown: null == birthTimeUnknown
                ? _value.birthTimeUnknown
                : birthTimeUnknown // ignore: cast_nullable_to_non_nullable
                      as bool,
            useYaJasi: null == useYaJasi
                ? _value.useYaJasi
                : useYaJasi // ignore: cast_nullable_to_non_nullable
                      as bool,
            birthCity: null == birthCity
                ? _value.birthCity
                : birthCity // ignore: cast_nullable_to_non_nullable
                      as String,
            timeCorrection: null == timeCorrection
                ? _value.timeCorrection
                : timeCorrection // ignore: cast_nullable_to_non_nullable
                      as int,
            createdAt: null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            updatedAt: null == updatedAt
                ? _value.updatedAt
                : updatedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            isActive: null == isActive
                ? _value.isActive
                : isActive // ignore: cast_nullable_to_non_nullable
                      as bool,
            relationType: null == relationType
                ? _value.relationType
                : relationType // ignore: cast_nullable_to_non_nullable
                      as RelationshipType,
            memo: freezed == memo
                ? _value.memo
                : memo // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$SajuProfileImplCopyWith<$Res>
    implements $SajuProfileCopyWith<$Res> {
  factory _$$SajuProfileImplCopyWith(
    _$SajuProfileImpl value,
    $Res Function(_$SajuProfileImpl) then,
  ) = __$$SajuProfileImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String displayName,
    Gender gender,
    DateTime birthDate,
    bool isLunar,
    bool isLeapMonth,
    int? birthTimeMinutes,
    bool birthTimeUnknown,
    bool useYaJasi,
    String birthCity,
    int timeCorrection,
    DateTime createdAt,
    DateTime updatedAt,
    bool isActive,
    RelationshipType relationType,
    String? memo,
  });
}

/// @nodoc
class __$$SajuProfileImplCopyWithImpl<$Res>
    extends _$SajuProfileCopyWithImpl<$Res, _$SajuProfileImpl>
    implements _$$SajuProfileImplCopyWith<$Res> {
  __$$SajuProfileImplCopyWithImpl(
    _$SajuProfileImpl _value,
    $Res Function(_$SajuProfileImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SajuProfile
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? displayName = null,
    Object? gender = null,
    Object? birthDate = null,
    Object? isLunar = null,
    Object? isLeapMonth = null,
    Object? birthTimeMinutes = freezed,
    Object? birthTimeUnknown = null,
    Object? useYaJasi = null,
    Object? birthCity = null,
    Object? timeCorrection = null,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? isActive = null,
    Object? relationType = null,
    Object? memo = freezed,
  }) {
    return _then(
      _$SajuProfileImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        displayName: null == displayName
            ? _value.displayName
            : displayName // ignore: cast_nullable_to_non_nullable
                  as String,
        gender: null == gender
            ? _value.gender
            : gender // ignore: cast_nullable_to_non_nullable
                  as Gender,
        birthDate: null == birthDate
            ? _value.birthDate
            : birthDate // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        isLunar: null == isLunar
            ? _value.isLunar
            : isLunar // ignore: cast_nullable_to_non_nullable
                  as bool,
        isLeapMonth: null == isLeapMonth
            ? _value.isLeapMonth
            : isLeapMonth // ignore: cast_nullable_to_non_nullable
                  as bool,
        birthTimeMinutes: freezed == birthTimeMinutes
            ? _value.birthTimeMinutes
            : birthTimeMinutes // ignore: cast_nullable_to_non_nullable
                  as int?,
        birthTimeUnknown: null == birthTimeUnknown
            ? _value.birthTimeUnknown
            : birthTimeUnknown // ignore: cast_nullable_to_non_nullable
                  as bool,
        useYaJasi: null == useYaJasi
            ? _value.useYaJasi
            : useYaJasi // ignore: cast_nullable_to_non_nullable
                  as bool,
        birthCity: null == birthCity
            ? _value.birthCity
            : birthCity // ignore: cast_nullable_to_non_nullable
                  as String,
        timeCorrection: null == timeCorrection
            ? _value.timeCorrection
            : timeCorrection // ignore: cast_nullable_to_non_nullable
                  as int,
        createdAt: null == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        updatedAt: null == updatedAt
            ? _value.updatedAt
            : updatedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        isActive: null == isActive
            ? _value.isActive
            : isActive // ignore: cast_nullable_to_non_nullable
                  as bool,
        relationType: null == relationType
            ? _value.relationType
            : relationType // ignore: cast_nullable_to_non_nullable
                  as RelationshipType,
        memo: freezed == memo
            ? _value.memo
            : memo // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc

class _$SajuProfileImpl extends _SajuProfile {
  const _$SajuProfileImpl({
    required this.id,
    required this.displayName,
    required this.gender,
    required this.birthDate,
    required this.isLunar,
    this.isLeapMonth = false,
    this.birthTimeMinutes,
    this.birthTimeUnknown = false,
    this.useYaJasi = true,
    required this.birthCity,
    this.timeCorrection = 0,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = false,
    this.relationType = RelationshipType.me,
    this.memo,
  }) : super._();

  /// 프로필 고유 ID
  @override
  final String id;

  /// 표시 이름 (최대 12자)
  @override
  final String displayName;

  /// 성별
  @override
  final Gender gender;

  /// 생년월일 (양력 기준으로 저장)
  @override
  final DateTime birthDate;

  /// 음력 여부
  @override
  final bool isLunar;

  /// 음력 윤달 여부 (음력일 때만 의미)
  @override
  @JsonKey()
  final bool isLeapMonth;

  /// 출생시간 (분 단위, 0~1439)
  /// null이면 시간을 모르는 경우
  @override
  final int? birthTimeMinutes;

  /// 시간 모름 여부
  @override
  @JsonKey()
  final bool birthTimeUnknown;

  /// 야자시/조자시 설정
  /// true: 야자시 (23:00-01:00을 다음날 자시로 계산)
  /// false: 조자시 (23:00-01:00을 당일 자시로 계산)
  @override
  @JsonKey()
  final bool useYaJasi;

  /// 출생 도시 (진태양시 계산용)
  @override
  final String birthCity;

  /// 진태양시 보정값 (분 단위)
  /// 자동으로 계산되어 저장됨
  @override
  @JsonKey()
  final int timeCorrection;

  /// 생성 일시
  @override
  final DateTime createdAt;

  /// 수정 일시
  @override
  final DateTime updatedAt;

  /// 현재 활성 프로필 여부
  /// 한 번에 하나의 프로필만 활성화 가능
  @override
  @JsonKey()
  final bool isActive;

  /// 관계 유형 (가족, 친구, 연인 등)
  @override
  @JsonKey()
  final RelationshipType relationType;

  /// 메모
  @override
  final String? memo;

  @override
  String toString() {
    return 'SajuProfile(id: $id, displayName: $displayName, gender: $gender, birthDate: $birthDate, isLunar: $isLunar, isLeapMonth: $isLeapMonth, birthTimeMinutes: $birthTimeMinutes, birthTimeUnknown: $birthTimeUnknown, useYaJasi: $useYaJasi, birthCity: $birthCity, timeCorrection: $timeCorrection, createdAt: $createdAt, updatedAt: $updatedAt, isActive: $isActive, relationType: $relationType, memo: $memo)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SajuProfileImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.displayName, displayName) ||
                other.displayName == displayName) &&
            (identical(other.gender, gender) || other.gender == gender) &&
            (identical(other.birthDate, birthDate) ||
                other.birthDate == birthDate) &&
            (identical(other.isLunar, isLunar) || other.isLunar == isLunar) &&
            (identical(other.isLeapMonth, isLeapMonth) ||
                other.isLeapMonth == isLeapMonth) &&
            (identical(other.birthTimeMinutes, birthTimeMinutes) ||
                other.birthTimeMinutes == birthTimeMinutes) &&
            (identical(other.birthTimeUnknown, birthTimeUnknown) ||
                other.birthTimeUnknown == birthTimeUnknown) &&
            (identical(other.useYaJasi, useYaJasi) ||
                other.useYaJasi == useYaJasi) &&
            (identical(other.birthCity, birthCity) ||
                other.birthCity == birthCity) &&
            (identical(other.timeCorrection, timeCorrection) ||
                other.timeCorrection == timeCorrection) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            (identical(other.isActive, isActive) ||
                other.isActive == isActive) &&
            (identical(other.relationType, relationType) ||
                other.relationType == relationType) &&
            (identical(other.memo, memo) || other.memo == memo));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    displayName,
    gender,
    birthDate,
    isLunar,
    isLeapMonth,
    birthTimeMinutes,
    birthTimeUnknown,
    useYaJasi,
    birthCity,
    timeCorrection,
    createdAt,
    updatedAt,
    isActive,
    relationType,
    memo,
  );

  /// Create a copy of SajuProfile
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SajuProfileImplCopyWith<_$SajuProfileImpl> get copyWith =>
      __$$SajuProfileImplCopyWithImpl<_$SajuProfileImpl>(this, _$identity);
}

abstract class _SajuProfile extends SajuProfile {
  const factory _SajuProfile({
    required final String id,
    required final String displayName,
    required final Gender gender,
    required final DateTime birthDate,
    required final bool isLunar,
    final bool isLeapMonth,
    final int? birthTimeMinutes,
    final bool birthTimeUnknown,
    final bool useYaJasi,
    required final String birthCity,
    final int timeCorrection,
    required final DateTime createdAt,
    required final DateTime updatedAt,
    final bool isActive,
    final RelationshipType relationType,
    final String? memo,
  }) = _$SajuProfileImpl;
  const _SajuProfile._() : super._();

  /// 프로필 고유 ID
  @override
  String get id;

  /// 표시 이름 (최대 12자)
  @override
  String get displayName;

  /// 성별
  @override
  Gender get gender;

  /// 생년월일 (양력 기준으로 저장)
  @override
  DateTime get birthDate;

  /// 음력 여부
  @override
  bool get isLunar;

  /// 음력 윤달 여부 (음력일 때만 의미)
  @override
  bool get isLeapMonth;

  /// 출생시간 (분 단위, 0~1439)
  /// null이면 시간을 모르는 경우
  @override
  int? get birthTimeMinutes;

  /// 시간 모름 여부
  @override
  bool get birthTimeUnknown;

  /// 야자시/조자시 설정
  /// true: 야자시 (23:00-01:00을 다음날 자시로 계산)
  /// false: 조자시 (23:00-01:00을 당일 자시로 계산)
  @override
  bool get useYaJasi;

  /// 출생 도시 (진태양시 계산용)
  @override
  String get birthCity;

  /// 진태양시 보정값 (분 단위)
  /// 자동으로 계산되어 저장됨
  @override
  int get timeCorrection;

  /// 생성 일시
  @override
  DateTime get createdAt;

  /// 수정 일시
  @override
  DateTime get updatedAt;

  /// 현재 활성 프로필 여부
  /// 한 번에 하나의 프로필만 활성화 가능
  @override
  bool get isActive;

  /// 관계 유형 (가족, 친구, 연인 등)
  @override
  RelationshipType get relationType;

  /// 메모
  @override
  String? get memo;

  /// Create a copy of SajuProfile
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SajuProfileImplCopyWith<_$SajuProfileImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
