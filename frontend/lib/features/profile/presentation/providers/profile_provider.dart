import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/saju_profile.dart';
import '../../domain/entities/gender.dart';
import '../../domain/repositories/profile_repository.dart';
import '../../data/datasources/profile_local_datasource.dart';
import '../../data/repositories/profile_repository_impl.dart';
import '../../../saju_chart/domain/services/true_solar_time_service.dart';

part 'profile_provider.g.dart';

/// ProfileRepository Provider
@riverpod
ProfileRepository profileRepository(Ref ref) {
  final datasource = ProfileLocalDatasource();
  return ProfileRepositoryImpl(datasource);
}

/// 프로필 목록 Provider
@riverpod
class ProfileList extends _$ProfileList {
  @override
  Future<List<SajuProfile>> build() async {
    final repository = ref.watch(profileRepositoryProvider);
    return await repository.getAll();
  }

  /// 프로필 새로 고침
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(profileRepositoryProvider);
      return await repository.getAll();
    });
  }

  /// 프로필 생성
  Future<void> createProfile(SajuProfile profile) async {
    final repository = ref.read(profileRepositoryProvider);
    await repository.save(profile);
    await refresh();
  }

  /// 프로필 업데이트
  Future<void> updateProfile(SajuProfile profile) async {
    final repository = ref.read(profileRepositoryProvider);
    await repository.update(profile);
    await refresh();
  }

  /// 프로필 삭제
  Future<void> deleteProfile(String id) async {
    final repository = ref.read(profileRepositoryProvider);
    await repository.delete(id);
    await refresh();
  }

  /// 활성 프로필 설정
  Future<void> setActiveProfile(String id) async {
    final repository = ref.read(profileRepositoryProvider);
    await repository.setActive(id);
    await refresh();
  }
}

/// 현재 활성 프로필 Provider
@riverpod
class ActiveProfile extends _$ActiveProfile {
  @override
  Future<SajuProfile?> build() async {
    final repository = ref.watch(profileRepositoryProvider);
    return await repository.getActive();
  }

  /// 활성 프로필 새로 고침
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(profileRepositoryProvider);
      return await repository.getActive();
    });
  }
}

/// 프로필 폼 상태
class ProfileFormState {
  final String displayName;
  final Gender? gender;
  final DateTime? birthDate;
  final bool isLunar;
  final bool isLeapMonth;
  final int? birthTimeMinutes;
  final bool birthTimeUnknown;
  final bool useYaJasi;
  final String birthCity;
  final int timeCorrection;

  const ProfileFormState({
    this.displayName = '',
    this.gender,
    this.birthDate,
    this.isLunar = false,
    this.isLeapMonth = false,
    this.birthTimeMinutes,
    this.birthTimeUnknown = false,
    this.useYaJasi = true,
    this.birthCity = '',
    this.timeCorrection = 0,
  });

  /// 폼 유효성 검사
  bool get isValid {
    // 필수 필드 체크
    if (displayName.isEmpty || displayName.length > 12) return false;
    if (gender == null) return false;
    if (birthDate == null) return false;
    if (birthCity.isEmpty) return false;

    // 생년월일 범위 체크
    final now = DateTime.now();
    if (birthDate!.year < 1900 || birthDate!.isAfter(now)) return false;

    // 출생시간 범위 체크 (시간 모름이 아닐 때)
    if (!birthTimeUnknown && birthTimeMinutes != null) {
      if (birthTimeMinutes! < 0 || birthTimeMinutes! > 1439) return false;
    }

    return true;
  }

  /// 진태양시 보정값 계산
  int calculateTimeCorrection() {
    if (birthCity.isEmpty) return 0;
    return TrueSolarTimeService.getLongitudeCorrectionMinutes(birthCity).round();
  }

  ProfileFormState copyWith({
    String? displayName,
    Gender? gender,
    DateTime? birthDate,
    bool? isLunar,
    bool? isLeapMonth,
    int? birthTimeMinutes,
    bool? birthTimeUnknown,
    bool? useYaJasi,
    String? birthCity,
    int? timeCorrection,
  }) {
    return ProfileFormState(
      displayName: displayName ?? this.displayName,
      gender: gender ?? this.gender,
      birthDate: birthDate ?? this.birthDate,
      isLunar: isLunar ?? this.isLunar,
      isLeapMonth: isLeapMonth ?? this.isLeapMonth,
      birthTimeMinutes: birthTimeMinutes ?? this.birthTimeMinutes,
      birthTimeUnknown: birthTimeUnknown ?? this.birthTimeUnknown,
      useYaJasi: useYaJasi ?? this.useYaJasi,
      birthCity: birthCity ?? this.birthCity,
      timeCorrection: timeCorrection ?? this.timeCorrection,
    );
  }
}

/// 프로필 폼 Provider
@riverpod
class ProfileForm extends _$ProfileForm {
  @override
  ProfileFormState build() {
    return const ProfileFormState();
  }

  /// 폼 필드 업데이트
  void updateDisplayName(String value) {
    state = state.copyWith(displayName: value);
  }

  void updateGender(Gender value) {
    state = state.copyWith(gender: value);
  }

  void updateBirthDate(DateTime value) {
    state = state.copyWith(birthDate: value);
  }

  void updateIsLunar(bool value) {
    state = state.copyWith(isLunar: value);
  }

  void updateIsLeapMonth(bool value) {
    state = state.copyWith(isLeapMonth: value);
  }

  void updateBirthTime(int? minutes) {
    state = state.copyWith(birthTimeMinutes: minutes);
  }

  void updateBirthTimeUnknown(bool value) {
    state = state.copyWith(
      birthTimeUnknown: value,
      birthTimeMinutes: value ? null : state.birthTimeMinutes,
    );
  }

  void updateUseYaJasi(bool value) {
    state = state.copyWith(useYaJasi: value);
  }

  void updateBirthCity(String value) {
    final correction = TrueSolarTimeService.getLongitudeCorrectionMinutes(value).round();
    state = state.copyWith(
      birthCity: value,
      timeCorrection: correction,
    );
  }

  /// 기존 프로필로 폼 초기화 (수정 모드)
  void loadProfile(SajuProfile profile) {
    state = ProfileFormState(
      displayName: profile.displayName,
      gender: profile.gender,
      birthDate: profile.birthDate,
      isLunar: profile.isLunar,
      isLeapMonth: profile.isLeapMonth,
      birthTimeMinutes: profile.birthTimeMinutes,
      birthTimeUnknown: profile.birthTimeUnknown,
      useYaJasi: profile.useYaJasi,
      birthCity: profile.birthCity,
      timeCorrection: profile.timeCorrection,
    );
  }

  /// 폼 초기화
  void reset() {
    state = const ProfileFormState();
  }

  /// 프로필 생성 및 저장
  Future<SajuProfile> saveProfile({String? editingId}) async {
    if (!state.isValid) {
      throw Exception('프로필 정보가 유효하지 않습니다.');
    }

    final now = DateTime.now();
    final profile = SajuProfile(
      id: editingId ?? const Uuid().v4(),
      displayName: state.displayName,
      gender: state.gender!,
      birthDate: state.birthDate!,
      isLunar: state.isLunar,
      isLeapMonth: state.isLeapMonth,
      birthTimeMinutes: state.birthTimeUnknown ? null : state.birthTimeMinutes,
      birthTimeUnknown: state.birthTimeUnknown,
      useYaJasi: state.useYaJasi,
      birthCity: state.birthCity,
      timeCorrection: state.timeCorrection,
      createdAt: now,
      updatedAt: now,
      isActive: editingId == null, // 새 프로필은 자동으로 활성화
    );

    final repository = ref.read(profileRepositoryProvider);
    if (editingId != null) {
      await repository.update(profile);
    } else {
      await repository.save(profile);
    }

    // 프로필 목록 새로 고침
    ref.invalidate(profileListProvider);
    ref.invalidate(activeProfileProvider);

    return profile;
  }
}
