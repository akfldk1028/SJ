// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'saju_profile_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

SajuProfileModel _$SajuProfileModelFromJson(Map<String, dynamic> json) {
  return _SajuProfileModel.fromJson(json);
}

/// @nodoc
mixin _$SajuProfileModel {
  String get id => throw _privateConstructorUsedError;
  String get displayName => throw _privateConstructorUsedError;
  String get gender =>
      throw _privateConstructorUsedError; // Gender enum을 문자열로 저장
  DateTime get birthDate => throw _privateConstructorUsedError;
  bool get isLunar => throw _privateConstructorUsedError;
  bool get isLeapMonth => throw _privateConstructorUsedError;
  int? get birthTimeMinutes => throw _privateConstructorUsedError;
  bool get birthTimeUnknown => throw _privateConstructorUsedError;
  bool get useYaJasi => throw _privateConstructorUsedError;
  String get birthCity => throw _privateConstructorUsedError;
  int get timeCorrection => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  DateTime get updatedAt => throw _privateConstructorUsedError;
  bool get isActive => throw _privateConstructorUsedError;

  /// Serializes this SajuProfileModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of SajuProfileModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SajuProfileModelCopyWith<SajuProfileModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SajuProfileModelCopyWith<$Res> {
  factory $SajuProfileModelCopyWith(
    SajuProfileModel value,
    $Res Function(SajuProfileModel) then,
  ) = _$SajuProfileModelCopyWithImpl<$Res, SajuProfileModel>;
  @useResult
  $Res call({
    String id,
    String displayName,
    String gender,
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
  });
}

/// @nodoc
class _$SajuProfileModelCopyWithImpl<$Res, $Val extends SajuProfileModel>
    implements $SajuProfileModelCopyWith<$Res> {
  _$SajuProfileModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SajuProfileModel
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
                      as String,
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
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$SajuProfileModelImplCopyWith<$Res>
    implements $SajuProfileModelCopyWith<$Res> {
  factory _$$SajuProfileModelImplCopyWith(
    _$SajuProfileModelImpl value,
    $Res Function(_$SajuProfileModelImpl) then,
  ) = __$$SajuProfileModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String displayName,
    String gender,
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
  });
}

/// @nodoc
class __$$SajuProfileModelImplCopyWithImpl<$Res>
    extends _$SajuProfileModelCopyWithImpl<$Res, _$SajuProfileModelImpl>
    implements _$$SajuProfileModelImplCopyWith<$Res> {
  __$$SajuProfileModelImplCopyWithImpl(
    _$SajuProfileModelImpl _value,
    $Res Function(_$SajuProfileModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SajuProfileModel
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
  }) {
    return _then(
      _$SajuProfileModelImpl(
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
                  as String,
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
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$SajuProfileModelImpl extends _SajuProfileModel {
  const _$SajuProfileModelImpl({
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
  }) : super._();

  factory _$SajuProfileModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$SajuProfileModelImplFromJson(json);

  @override
  final String id;
  @override
  final String displayName;
  @override
  final String gender;
  // Gender enum을 문자열로 저장
  @override
  final DateTime birthDate;
  @override
  final bool isLunar;
  @override
  @JsonKey()
  final bool isLeapMonth;
  @override
  final int? birthTimeMinutes;
  @override
  @JsonKey()
  final bool birthTimeUnknown;
  @override
  @JsonKey()
  final bool useYaJasi;
  @override
  final String birthCity;
  @override
  @JsonKey()
  final int timeCorrection;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;
  @override
  @JsonKey()
  final bool isActive;

  @override
  String toString() {
    return 'SajuProfileModel(id: $id, displayName: $displayName, gender: $gender, birthDate: $birthDate, isLunar: $isLunar, isLeapMonth: $isLeapMonth, birthTimeMinutes: $birthTimeMinutes, birthTimeUnknown: $birthTimeUnknown, useYaJasi: $useYaJasi, birthCity: $birthCity, timeCorrection: $timeCorrection, createdAt: $createdAt, updatedAt: $updatedAt, isActive: $isActive)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SajuProfileModelImpl &&
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
                other.isActive == isActive));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
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
  );

  /// Create a copy of SajuProfileModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SajuProfileModelImplCopyWith<_$SajuProfileModelImpl> get copyWith =>
      __$$SajuProfileModelImplCopyWithImpl<_$SajuProfileModelImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$SajuProfileModelImplToJson(this);
  }
}

abstract class _SajuProfileModel extends SajuProfileModel {
  const factory _SajuProfileModel({
    required final String id,
    required final String displayName,
    required final String gender,
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
  }) = _$SajuProfileModelImpl;
  const _SajuProfileModel._() : super._();

  factory _SajuProfileModel.fromJson(Map<String, dynamic> json) =
      _$SajuProfileModelImpl.fromJson;

  @override
  String get id;
  @override
  String get displayName;
  @override
  String get gender; // Gender enum을 문자열로 저장
  @override
  DateTime get birthDate;
  @override
  bool get isLunar;
  @override
  bool get isLeapMonth;
  @override
  int? get birthTimeMinutes;
  @override
  bool get birthTimeUnknown;
  @override
  bool get useYaJasi;
  @override
  String get birthCity;
  @override
  int get timeCorrection;
  @override
  DateTime get createdAt;
  @override
  DateTime get updatedAt;
  @override
  bool get isActive;

  /// Create a copy of SajuProfileModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SajuProfileModelImplCopyWith<_$SajuProfileModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
