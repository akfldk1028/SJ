import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/gender.dart';
import '../../domain/entities/saju_profile.dart';

part 'profile_form_provider.g.dart';

/// Profile Form State
/// UI 폼 상태만 관리 (SRP)
class ProfileFormState {
  final String displayName;
  final Gender? gender;
  final DateTime? birthDate;
  final bool isLunar;
  final int? birthTimeMinutes;
  final bool birthTimeUnknown;
  final String? birthCity;

  const ProfileFormState({
    this.displayName = '',
    this.gender,
    this.birthDate,
    this.isLunar = false,
    this.birthTimeMinutes,
    this.birthTimeUnknown = false,
    this.birthCity,
  });

  /// 필수 필드가 모두 입력되었는지 확인
  bool get isValid {
    return displayName.isNotEmpty &&
        gender != null &&
        birthDate != null;
  }

  /// 출생 시간 문자열 (HH:mm)
  String? get birthTimeString {
    if (birthTimeUnknown || birthTimeMinutes == null) return null;
    final hours = birthTimeMinutes! ~/ 60;
    final minutes = birthTimeMinutes! % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
  }

  ProfileFormState copyWith({
    String? displayName,
    Gender? gender,
    DateTime? birthDate,
    bool? isLunar,
    int? birthTimeMinutes,
    bool? birthTimeUnknown,
    String? birthCity,
  }) {
    return ProfileFormState(
      displayName: displayName ?? this.displayName,
      gender: gender ?? this.gender,
      birthDate: birthDate ?? this.birthDate,
      isLunar: isLunar ?? this.isLunar,
      birthTimeMinutes: birthTimeMinutes ?? this.birthTimeMinutes,
      birthTimeUnknown: birthTimeUnknown ?? this.birthTimeUnknown,
      birthCity: birthCity ?? this.birthCity,
    );
  }
}

/// Profile Form Provider
/// 폼 입력 상태 관리
@riverpod
class ProfileForm extends _$ProfileForm {
  @override
  ProfileFormState build() {
    return const ProfileFormState();
  }

  /// 기존 프로필로 폼 초기화 (수정 모드)
  void initFromProfile(SajuProfile profile) {
    state = ProfileFormState(
      displayName: profile.displayName,
      gender: profile.gender,
      birthDate: profile.birthDate,
      isLunar: profile.isLunar,
      birthTimeMinutes: profile.birthTimeMinutes,
      birthTimeUnknown: profile.birthTimeUnknown,
      birthCity: profile.birthCity,
    );
  }

  /// 폼 초기화
  void reset() {
    state = const ProfileFormState();
  }

  /// 프로필명 변경
  void setDisplayName(String value) {
    state = state.copyWith(displayName: value);
  }

  /// 성별 변경
  void setGender(Gender value) {
    state = state.copyWith(gender: value);
  }

  /// 생년월일 변경
  void setBirthDate(DateTime value) {
    state = state.copyWith(birthDate: value);
  }

  /// 음양력 변경
  void setIsLunar(bool value) {
    state = state.copyWith(isLunar: value);
  }

  /// 출생시간 변경 (분 단위)
  void setBirthTimeMinutes(int? value) {
    state = state.copyWith(
      birthTimeMinutes: value,
      birthTimeUnknown: false,
    );
  }

  /// 출생시간 (시:분) 변경
  void setBirthTime(int hours, int minutes) {
    final totalMinutes = hours * 60 + minutes;
    setBirthTimeMinutes(totalMinutes);
  }

  /// 시간 모름 변경
  void setBirthTimeUnknown(bool value) {
    state = state.copyWith(
      birthTimeUnknown: value,
      birthTimeMinutes: value ? null : state.birthTimeMinutes,
    );
  }

  /// 출생지 변경
  void setBirthCity(String? value) {
    state = state.copyWith(birthCity: value);
  }

  /// 폼 상태를 SajuProfile Entity로 변환
  /// [existingId] 수정 모드일 때 기존 프로필 ID
  SajuProfile? toProfile({String? existingId}) {
    if (!state.isValid) return null;

    final now = DateTime.now();
    return SajuProfile(
      id: existingId ?? const Uuid().v4(),
      displayName: state.displayName,
      birthDate: state.birthDate!,
      birthTimeMinutes: state.birthTimeMinutes,
      birthTimeUnknown: state.birthTimeUnknown,
      isLunar: state.isLunar,
      gender: state.gender!,
      birthCity: state.birthCity ?? '',
      isActive: false,
      createdAt: now,
      updatedAt: now,
    );
  }
}
