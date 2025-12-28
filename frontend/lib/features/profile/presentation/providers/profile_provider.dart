import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/saju_profile.dart';
import '../../domain/entities/gender.dart';
import '../../domain/entities/relationship_type.dart';
import '../../domain/repositories/profile_repository.dart';
import '../../data/datasources/profile_local_datasource.dart';
import '../../data/repositories/profile_repository_impl.dart';
import '../../../saju_chart/domain/entities/daeun.dart' as daeun_entities;
import '../../../saju_chart/domain/entities/saju_chart.dart';
import '../../../saju_chart/domain/services/jasi_service.dart';
import '../../../saju_chart/domain/services/saju_calculation_service.dart';
import '../../../saju_chart/domain/services/true_solar_time_service.dart';
import '../../../saju_chart/presentation/providers/saju_chart_provider.dart'
    hide sajuAnalysisService;
import '../../../saju_chart/presentation/providers/saju_analysis_repository_provider.dart';
import '../../../menu/presentation/providers/daily_fortune_provider.dart';
import '../../../../AI/services/saju_analysis_service.dart';

part 'profile_provider.g.dart';

/// ProfileRepository Provider
@riverpod
ProfileRepository profileRepository(Ref ref) {
  final datasource = ProfileLocalDatasource();
  return ProfileRepositoryImpl(datasource);
}

/// 모든 프로필 목록 Provider (Alias for ProfileList)
@riverpod
Future<List<SajuProfile>> allProfiles(Ref ref) async {
  final repository = ref.watch(profileRepositoryProvider);
  return repository.getAllProfiles();
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
    ref.invalidate(allProfilesProvider);
  }

  /// 프로필 업데이트
  Future<void> updateProfile(SajuProfile profile) async {
    final repository = ref.read(profileRepositoryProvider);
    await repository.update(profile);
    await refresh();
    ref.invalidate(allProfilesProvider);
  }

  /// 프로필 삭제
  Future<void> deleteProfile(String id) async {
    final repository = ref.read(profileRepositoryProvider);
    await repository.delete(id);
    await refresh();
    ref.invalidate(allProfilesProvider);
  }

  /// 활성 프로필 설정
  Future<void> setActiveProfile(String id) async {
    final repository = ref.read(profileRepositoryProvider);
    await repository.setActive(id);
    await refresh();
    ref.invalidate(activeProfileProvider);
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
  
  Future<void> saveProfile(SajuProfile profile) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(profileRepositoryProvider);
      await repository.saveProfile(profile);

      // 목록 갱신을 위해 allProfilesProvider invalidate
      ref.invalidate(allProfilesProvider);
      ref.invalidate(profileListProvider);

      // AI 분석 백그라운드 실행 (평생 사주 + 오늘의 운세)
      _triggerAiAnalysis(profile.id);

      return profile;
    });
  }

  /// AI 분석 백그라운드 트리거 (ActiveProfile용)
  void _triggerAiAnalysis(String profileId) {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      print('[ActiveProfile] AI 분석 스킵: 로그인 필요');
      return;
    }

    // Fire-and-forget: 백그라운드에서 실행
    sajuAnalysisService.analyzeOnProfileSave(
      userId: user.id,
      profileId: profileId,
      runInBackground: true,
      onComplete: (result) {
        // 분석 완료 시 UI 갱신을 위해 provider invalidate
        print('[ActiveProfile] AI 분석 완료 - UI 갱신');
        ref.invalidate(dailyFortuneProvider);
      },
    );

    print('[ActiveProfile] AI 분석 백그라운드 시작: $profileId');
  }
  
  Future<void> deleteProfile(String id) async {
    final repository = ref.read(profileRepositoryProvider);
    await repository.deleteProfile(id);
    ref.invalidate(allProfilesProvider);
    ref.invalidate(profileListProvider);
    
    // 만약 삭제된 프로필이 현재 활성 프로필이라면
    if (state.value?.id == id) {
      state = const AsyncValue.data(null);
    }
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
  final RelationshipType relationType;
  final String? memo;

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
    this.relationType = RelationshipType.me,
    this.memo,
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
    RelationshipType? relationType,
    String? memo,
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
      relationType: relationType ?? this.relationType,
      memo: memo ?? this.memo,
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
  
  void updateRelationType(RelationshipType value) {
    state = state.copyWith(relationType: value);
  }
  
  void updateMemo(String value) {
    state = state.copyWith(memo: value);
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
      relationType: profile.relationType,
      memo: profile.memo,
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
      relationType: state.relationType,
      memo: state.memo,
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
    ref.invalidate(allProfilesProvider);

    // 사주 분석 결과 자동 저장 (Supabase 연동)
    // 프로필 저장 후 사주 분석을 계산하고 DB에 저장
    await _saveAnalysisToDb(ref, profile);

    return profile;
  }

  /// 사주 분석 결과를 DB에 저장
  ///
  /// 직접 profile 객체로 사주 계산 후 저장 (activeProfileProvider 의존 제거)
  Future<void> _saveAnalysisToDb(Ref ref, SajuProfile profile) async {
    try {
      // 1. 직접 사주 차트 계산 (activeProfileProvider 미사용)
      final calculationService = ref.read(sajuCalculationServiceProvider);
      final chart = _calculateChartForProfile(calculationService, profile);

      // 2. 사주 분석 계산
      final analysisService = ref.read(sajuAnalysisServiceProvider);
      final daeunGender = profile.gender.name == 'male'
          ? daeun_entities.Gender.male
          : daeun_entities.Gender.female;
      final analysis = analysisService.analyze(
        chart: chart,
        gender: daeunGender,
        currentYear: DateTime.now().year,
      );

      // 3. DB에 저장 (profile.id 직접 전달)
      final dbNotifier = ref.read(currentSajuAnalysisDbProvider.notifier);
      await dbNotifier.saveFromAnalysisWithProfileId(profile.id, analysis);

      print('[Profile] 사주 분석 저장 완료: ${profile.id}');

      // 4. AI 분석 백그라운드 실행 (평생 사주 + 오늘의 운세)
      _triggerAiAnalysis(profile.id);
    } catch (e) {
      // 분석 저장 실패는 무시 (프로필 저장은 이미 완료됨)
      // ignore: avoid_print
      print('[Profile] 사주 분석 저장 실패 (무시됨): $e');
    }
  }

  /// 프로필로부터 사주차트 직접 계산 (Provider 의존 없음)
  SajuChart _calculateChartForProfile(
    SajuCalculationService service,
    SajuProfile profile,
  ) {
    DateTime birthDateTime;
    if (profile.birthTimeUnknown || profile.birthTimeMinutes == null) {
      birthDateTime = DateTime(
        profile.birthDate.year,
        profile.birthDate.month,
        profile.birthDate.day,
        12,
        0,
      );
    } else {
      final hours = profile.birthTimeMinutes! ~/ 60;
      final minutes = profile.birthTimeMinutes! % 60;
      birthDateTime = DateTime(
        profile.birthDate.year,
        profile.birthDate.month,
        profile.birthDate.day,
        hours,
        minutes,
      );
    }

    return service.calculate(
      birthDateTime: birthDateTime,
      birthCity: profile.birthCity,
      isLunarCalendar: profile.isLunar,
      isLeapMonth: profile.isLeapMonth,
      birthTimeUnknown: profile.birthTimeUnknown,
      jasiMode: profile.useYaJasi ? JasiMode.yaJasi : JasiMode.joJasi,
    );
  }

  /// AI 분석 백그라운드 트리거
  ///
  /// 평생 사주운세 (GPT-5.2) + 오늘의 운세 (Gemini) 병렬 실행
  void _triggerAiAnalysis(String profileId) {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      print('[Profile] AI 분석 스킵: 로그인 필요');
      return;
    }

    // Fire-and-forget: 백그라운드에서 실행
    sajuAnalysisService.analyzeOnProfileSave(
      userId: user.id,
      profileId: profileId,
      runInBackground: true,
      onComplete: (result) {
        // 분석 완료 시 UI 갱신을 위해 provider invalidate
        print('[Profile] AI 분석 완료 - UI 갱신');
        ref.invalidate(dailyFortuneProvider);
      },
    );

    print('[Profile] AI 분석 백그라운드 시작: $profileId');
  }
}
