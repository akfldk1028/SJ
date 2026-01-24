import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/saju_profile.dart';
import '../../domain/entities/gender.dart';
import '../../domain/entities/relationship_type.dart';
import '../../domain/repositories/profile_repository.dart';
import '../../../saju_chart/domain/entities/lunar_date.dart';
import '../../../saju_chart/domain/entities/lunar_validation.dart';
import '../../../saju_chart/domain/services/lunar_solar_converter.dart';
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
import '../../../monthly_fortune/presentation/providers/monthly_fortune_provider.dart';
import '../../../new_year_fortune/presentation/providers/new_year_fortune_provider.dart';
import '../../../yearly_2025_fortune/presentation/providers/yearly_2025_fortune_provider.dart';
import '../../../traditional_saju/presentation/providers/lifetime_fortune_provider.dart';
import '../../../../AI/services/saju_analysis_service.dart';
import '../../../../AI/data/mutations.dart';

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
    ref.invalidate(activeProfileProvider); // 활성 프로필일 수 있으므로 함께 갱신
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

      // GPT-5.2 분석 백그라운드 실행 (fire-and-forget)
      // 채팅 시작 시 saju_origin 없으면 그때 다시 트리거됨
      _triggerAiAnalysis(profile.id);

      return profile;
    });
  }

  /// GPT-5.2 분석 동기 실행 (완료 대기) - ActiveProfile용
  Future<void> _triggerAiAnalysisSync(String profileId) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      print('[ActiveProfile] AI 분석 스킵: 로그인 필요');
      return;
    }

    print('[ActiveProfile] GPT-5.2 분석 시작 (동기): $profileId');

    // 동기 실행: GPT-5.2 완료까지 대기
    final result = await sajuAnalysisService.analyzeOnProfileSave(
      userId: user.id,
      profileId: profileId,
      runInBackground: false,  // 완료 대기
    );

    if (result.sajuBase?.success == true) {
      print('[ActiveProfile] ✅ GPT-5.2 분석 완료: $profileId');
    } else {
      print('[ActiveProfile] ⚠️ GPT-5.2 분석 실패: ${result.sajuBase?.error}');
    }

    // UI 갱신
    ref.invalidate(dailyFortuneProvider);
  }

  /// AI 분석 백그라운드 트리거 (ActiveProfile용) - deprecated
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

  // Phase 18: 윤달 유효성 검증 필드
  /// 윤달 검증 에러 메시지
  final String? leapMonthError;

  /// 해당 연도 윤달 정보 (조회 결과)
  final LeapMonthInfo? leapMonthInfo;

  /// 윤달 체크박스 활성화 가능 여부
  final bool canSelectLeapMonth;

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
    this.leapMonthError,
    this.leapMonthInfo,
    this.canSelectLeapMonth = false,
  });

  /// 폼 유효성 검사
  bool get isValid {
    // 필수 필드 체크
    if (displayName.isEmpty || displayName.length > 12) {
      print('[isValid] FAIL: displayName invalid - "$displayName" (empty: ${displayName.isEmpty}, len: ${displayName.length})');
      return false;
    }
    if (gender == null) {
      print('[isValid] FAIL: gender is null');
      return false;
    }
    if (birthDate == null) {
      print('[isValid] FAIL: birthDate is null');
      return false;
    }
    if (birthCity.isEmpty) {
      print('[isValid] FAIL: birthCity is empty');
      return false;
    }

    // 도시가 유효한 목록에 있는지 확인
    if (!TrueSolarTimeService.cityLongitude.containsKey(birthCity)) {
      print('[isValid] FAIL: birthCity "$birthCity" not in cityLongitude');
      return false;
    }

    // 생년월일 범위 체크
    final now = DateTime.now();
    if (birthDate!.year < 1900 || birthDate!.isAfter(now)) {
      print('[isValid] FAIL: birthDate out of range - $birthDate');
      return false;
    }

    // 출생시간 범위 체크 (시간 모름이 아닐 때)
    if (!birthTimeUnknown && birthTimeMinutes != null) {
      if (birthTimeMinutes! < 0 || birthTimeMinutes! > 1439) {
        print('[isValid] FAIL: birthTimeMinutes out of range - $birthTimeMinutes');
        return false;
      }
    }

    // Phase 18: 윤달 유효성 검사 (음력일 때만)
    if (isLunar && leapMonthError != null) {
      print('[isValid] FAIL: leapMonthError - $leapMonthError');
      return false;
    }

    print('[isValid] PASS: all checks passed');
    return true;
  }

  /// 윤달 선택 가능 여부
  bool get isLeapMonthSelectable => isLunar && canSelectLeapMonth;

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
    String? leapMonthError,
    LeapMonthInfo? leapMonthInfo,
    bool? canSelectLeapMonth,
    bool clearLeapMonthError = false,
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
      leapMonthError: clearLeapMonthError ? null : (leapMonthError ?? this.leapMonthError),
      leapMonthInfo: leapMonthInfo ?? this.leapMonthInfo,
      canSelectLeapMonth: canSelectLeapMonth ?? this.canSelectLeapMonth,
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

  /// LunarSolarConverter 인스턴스 (윤달 검증용)
  final _lunarConverter = LunarSolarConverter();

  void updateBirthDate(DateTime value) {
    state = state.copyWith(birthDate: value);
    // 생년월일 변경 시 윤달 정보 업데이트
    _updateLeapMonthInfo();
  }

  void updateIsLunar(bool value) {
    state = state.copyWith(isLunar: value);
    if (value) {
      // 음력 선택 시 윤달 정보 업데이트
      _updateLeapMonthInfo();
    } else {
      // 양력 선택 시 윤달 관련 필드 초기화
      state = state.copyWith(
        isLeapMonth: false,
        leapMonthInfo: null,
        canSelectLeapMonth: false,
        clearLeapMonthError: true,
      );
    }
  }

  void updateIsLeapMonth(bool value) {
    state = state.copyWith(isLeapMonth: value);
    // 윤달 선택 변경 시 유효성 검증
    _validateLeapMonth();
  }

  /// 윤달 정보 업데이트 (생년월일/음력 변경 시 호출)
  void _updateLeapMonthInfo() {
    final date = state.birthDate;
    if (date == null || !state.isLunar) return;

    final leapMonthInfo = _lunarConverter.getLeapMonthInfo(date.year);
    final canSelect = leapMonthInfo.hasLeapMonth &&
        leapMonthInfo.leapMonth == date.month;

    state = state.copyWith(
      leapMonthInfo: leapMonthInfo,
      canSelectLeapMonth: canSelect,
      // 윤달 선택 불가능한데 체크되어 있으면 해제
      isLeapMonth: canSelect ? state.isLeapMonth : false,
      clearLeapMonthError: true,
    );

    // 윤달이 체크되어 있으면 유효성 검증
    if (state.isLeapMonth) {
      _validateLeapMonth();
    }
  }

  /// 윤달 유효성 검증
  void _validateLeapMonth() {
    final date = state.birthDate;
    if (date == null || !state.isLunar || !state.isLeapMonth) {
      state = state.copyWith(clearLeapMonthError: true);
      return;
    }

    final lunarDate = LunarDate(
      year: date.year,
      month: date.month,
      day: date.day,
      isLeapMonth: state.isLeapMonth,
    );

    final result = _lunarConverter.validateLunarDate(lunarDate);
    if (!result.isValid) {
      state = state.copyWith(leapMonthError: result.errorMessage);
    } else {
      state = state.copyWith(clearLeapMonthError: true);
    }
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
    // 기본 상태 설정
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

    // 음력일 경우 윤달 정보 업데이트
    if (profile.isLunar) {
      _updateLeapMonthInfo();
    }
  }

  /// ProfileRelationTarget으로 폼 초기화 (인연 수정 모드)
  void loadFromRelationTarget(dynamic target) {
    print('🔄 [ProfileForm.loadFromRelationTarget] 시작');
    print('  - target: $target');
    print('  - target type: ${target.runtimeType}');

    // ProfileRelationTarget의 필드들 추출
    final String displayName = target.displayName ?? '';
    final DateTime? birthDate = target.birthDate;
    final String genderStr = target.gender ?? 'male';
    final String? relationTypeStr = target.relationType;
    final int? birthTimeMinutes = target.birthTimeMinutes;
    final bool birthTimeUnknown = target.birthTimeUnknown ?? false;
    final bool isLunar = target.isLunar ?? false;
    final bool isLeapMonth = target.isLeapMonth ?? false;
    final String birthCity = target.birthCity ?? '';
    final bool useYaJasi = target.useYaJasi ?? true;

    print('📋 [ProfileForm.loadFromRelationTarget] 추출된 데이터:');
    print('  - displayName: $displayName');
    print('  - birthDate: $birthDate');
    print('  - gender: $genderStr');
    print('  - relationType: $relationTypeStr');
    print('  - birthTimeMinutes: $birthTimeMinutes');
    print('  - birthTimeUnknown: $birthTimeUnknown');
    print('  - isLunar: $isLunar');
    print('  - isLeapMonth: $isLeapMonth');
    print('  - birthCity: $birthCity');
    print('  - useYaJasi: $useYaJasi');

    // Gender 변환
    final gender = genderStr == 'female' ? Gender.female : Gender.male;

    // RelationType 변환
    RelationshipType relationType = RelationshipType.friend;
    if (relationTypeStr != null) {
      try {
        relationType = RelationshipType.values.firstWhere(
          (e) => e.name == relationTypeStr,
          orElse: () => RelationshipType.friend,
        );
      } catch (e) {
        print('⚠️ [ProfileForm.loadFromRelationTarget] relationType 변환 실패: $e');
      }
    }

    // 도시 시간 보정값 계산
    final timeCorrection = birthCity.isNotEmpty
        ? TrueSolarTimeService.getLongitudeCorrectionMinutes(birthCity).round()
        : 0;

    // 상태 설정
    state = ProfileFormState(
      displayName: displayName,
      gender: gender,
      birthDate: birthDate,
      isLunar: isLunar,
      isLeapMonth: isLeapMonth,
      birthTimeMinutes: birthTimeMinutes,
      birthTimeUnknown: birthTimeUnknown,
      useYaJasi: useYaJasi,
      birthCity: birthCity,
      timeCorrection: timeCorrection,
      relationType: relationType,
    );

    print('✅ [ProfileForm.loadFromRelationTarget] 폼 상태 설정 완료');
    print('  - state.displayName: ${state.displayName}');
    print('  - state.birthDate: ${state.birthDate}');
    print('  - state.gender: ${state.gender}');

    // 음력일 경우 윤달 정보 업데이트
    if (isLunar) {
      _updateLeapMonthInfo();
    }
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
    final repository = ref.read(profileRepositoryProvider);

    // 수정 모드: 기존 프로필의 isActive, createdAt 보존
    SajuProfile? existingProfile;
    if (editingId != null) {
      existingProfile = await repository.getById(editingId);
    }

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
      createdAt: existingProfile?.createdAt ?? now,
      updatedAt: now,
      isActive: existingProfile?.isActive ?? (editingId == null),
      relationType: state.relationType,
      memo: state.memo,
    );

    if (editingId != null) {
      await repository.update(profile);

      // 프로필 수정 시 기존 AI 분석 캐시 삭제 (생년월일 변경 대응)
      // 새로운 분석이 실행되도록 기존 캐시를 모두 무효화
      print('[ProfileForm] 프로필 수정 - AI 캐시 무효화 시작: $editingId');
      final aiMutations = AiMutations();
      final cacheResult = await aiMutations.invalidateAllForProfile(editingId);
      if (cacheResult.isSuccess) {
        print('[ProfileForm] AI 캐시 무효화 완료: ${cacheResult.data}개 삭제');
      } else {
        print('[ProfileForm] AI 캐시 무효화 실패: ${cacheResult.errorMessage}');
      }
    } else {
      await repository.save(profile);
    }

    // 프로필 목록 새로 고침
    ref.invalidate(profileListProvider);
    ref.invalidate(activeProfileProvider);
    ref.invalidate(allProfilesProvider);

    // Note: Fortune providers 무효화는 _triggerAiAnalysis() 완료 콜백에서 수행
    // (분석 완료 전 무효화하면 캐시 없음 → 영원히 로딩 상태)

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

      // 4. GPT-5.2 분석 백그라운드 실행 (fire-and-forget)
      // 채팅 시작 시 saju_origin 없으면 그때 다시 트리거됨
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

  /// GPT-5.2 분석 동기 실행 (완료 대기)
  ///
  /// 프로필 생성 시 GPT-5.2 분석이 완료되어야 채팅에서 saju_origin 참조 가능
  /// - runInBackground: false → 완료까지 대기
  /// - 오늘의 운세는 백그라운드로 계속 실행
  Future<void> _triggerAiAnalysisSync(String profileId) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      print('[Profile] AI 분석 스킵: 로그인 필요');
      return;
    }

    print('[Profile] GPT-5.2 분석 시작 (동기): $profileId');

    // 동기 실행: GPT-5.2 완료까지 대기
    final result = await sajuAnalysisService.analyzeOnProfileSave(
      userId: user.id,
      profileId: profileId,
      runInBackground: false,  // 완료 대기
    );

    if (result.sajuBase?.success == true) {
      print('[Profile] ✅ GPT-5.2 분석 완료: $profileId');
    } else {
      print('[Profile] ⚠️ GPT-5.2 분석 실패: ${result.sajuBase?.error}');
    }

    // UI 갱신
    ref.invalidate(dailyFortuneProvider);
  }

  /// AI 분석 백그라운드 트리거 (deprecated - 호환성 유지)
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
        // 분석 완료 시 UI 갱신을 위해 모든 fortune providers invalidate
        print('[Profile] AI 분석 완료 - 모든 Fortune providers 무효화');
        ref.invalidate(dailyFortuneProvider);
        ref.invalidate(monthlyFortuneProvider);
        ref.invalidate(newYearFortuneProvider);
        ref.invalidate(yearly2025FortuneProvider);
        ref.invalidate(lifetimeFortuneProvider);
      },
    );

    print('[Profile] AI 분석 백그라운드 시작: $profileId');
  }
}
