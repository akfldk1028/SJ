import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../profile/domain/entities/saju_profile.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../domain/entities/daeun.dart';
import '../../domain/entities/saju_analysis.dart';
import '../../domain/entities/saju_chart.dart';
import '../../domain/services/jasi_service.dart';
import '../../domain/services/saju_analysis_service.dart';
import '../../domain/services/saju_calculation_service.dart';

part 'saju_chart_provider.g.dart';

/// 사주 계산 서비스 Provider
@riverpod
SajuCalculationService sajuCalculationService(Ref ref) {
  return SajuCalculationService();
}

/// 사주 종합 분석 서비스 Provider
@riverpod
SajuAnalysisService sajuAnalysisService(Ref ref) {
  return SajuAnalysisService();
}

/// 현재 활성 프로필의 사주차트 Provider
@riverpod
class CurrentSajuChart extends _$CurrentSajuChart {
  @override
  Future<SajuChart?> build() async {
    final activeProfile = await ref.watch(activeProfileProvider.future);
    if (activeProfile == null) return null;

    return _calculateChart(activeProfile);
  }

  /// 프로필로부터 사주차트 계산
  SajuChart _calculateChart(SajuProfile profile) {
    final service = ref.read(sajuCalculationServiceProvider);

    // 출생시간 계산 (분 → DateTime)
    DateTime birthDateTime;
    if (profile.birthTimeUnknown || profile.birthTimeMinutes == null) {
      // 시간 모름: 정오(12:00) 기준
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

  /// 특정 프로필로 사주 계산
  Future<SajuChart> calculateForProfile(SajuProfile profile) async {
    return _calculateChart(profile);
  }

  /// 새로고침
  Future<void> refresh() async {
    ref.invalidateSelf();
  }
}

/// 현재 사주 종합 분석 Provider
///
/// 분석 결과를 계산 (저장은 profile_provider에서 처리)
@riverpod
class CurrentSajuAnalysis extends _$CurrentSajuAnalysis {
  @override
  Future<SajuAnalysis?> build() async {
    final chart = await ref.watch(currentSajuChartProvider.future);
    if (chart == null) return null;

    final activeProfile = await ref.watch(activeProfileProvider.future);
    if (activeProfile == null) return null;

    final service = ref.read(sajuAnalysisServiceProvider);

    // 성별 변환
    final gender = activeProfile.gender.name == 'male' ? Gender.male : Gender.female;

    final analysis = service.analyze(
      chart: chart,
      gender: gender,
      currentYear: DateTime.now().year,
    );

    // NOTE: Supabase 저장은 profile_provider.dart의 saveProfile()에서 처리
    // 여기서 저장하면 activeProfile이 아직 업데이트되지 않아 이전 profile_id로 저장될 수 있음

    return analysis;
  }
}

/// 특정 프로필의 사주 분석 Provider (profileId 기반)
///
/// 관계도에서 다른 사람의 사주 상세를 볼 때 사용
@riverpod
Future<SajuAnalysis?> sajuAnalysisForProfile(Ref ref, String profileId) async {
  final profiles = await ref.watch(allProfilesProvider.future);
  final profile = profiles.where((p) => p.id == profileId).firstOrNull;
  if (profile == null) return null;

  final calcService = ref.read(sajuCalculationServiceProvider);
  final analysisService = ref.read(sajuAnalysisServiceProvider);

  // 출생시간 계산
  DateTime birthDateTime;
  if (profile.birthTimeUnknown || profile.birthTimeMinutes == null) {
    birthDateTime = DateTime(
      profile.birthDate.year, profile.birthDate.month, profile.birthDate.day, 12, 0,
    );
  } else {
    final hours = profile.birthTimeMinutes! ~/ 60;
    final minutes = profile.birthTimeMinutes! % 60;
    birthDateTime = DateTime(
      profile.birthDate.year, profile.birthDate.month, profile.birthDate.day, hours, minutes,
    );
  }

  final chart = calcService.calculate(
    birthDateTime: birthDateTime,
    birthCity: profile.birthCity,
    isLunarCalendar: profile.isLunar,
    isLeapMonth: profile.isLeapMonth,
    birthTimeUnknown: profile.birthTimeUnknown,
    jasiMode: profile.useYaJasi ? JasiMode.yaJasi : JasiMode.joJasi,
  );

  final gender = profile.gender.name == 'male' ? Gender.male : Gender.female;

  return analysisService.analyze(
    chart: chart,
    gender: gender,
    currentYear: DateTime.now().year,
  );
}

/// 특정 프로필의 사주차트 Provider (profileId 기반)
@riverpod
Future<SajuChart?> sajuChartForProfile(Ref ref, String profileId) async {
  final profiles = await ref.watch(allProfilesProvider.future);
  final profile = profiles.where((p) => p.id == profileId).firstOrNull;
  if (profile == null) return null;

  final calcService = ref.read(sajuCalculationServiceProvider);

  DateTime birthDateTime;
  if (profile.birthTimeUnknown || profile.birthTimeMinutes == null) {
    birthDateTime = DateTime(
      profile.birthDate.year, profile.birthDate.month, profile.birthDate.day, 12, 0,
    );
  } else {
    final hours = profile.birthTimeMinutes! ~/ 60;
    final minutes = profile.birthTimeMinutes! % 60;
    birthDateTime = DateTime(
      profile.birthDate.year, profile.birthDate.month, profile.birthDate.day, hours, minutes,
    );
  }

  return calcService.calculate(
    birthDateTime: birthDateTime,
    birthCity: profile.birthCity,
    isLunarCalendar: profile.isLunar,
    isLeapMonth: profile.isLeapMonth,
    birthTimeUnknown: profile.birthTimeUnknown,
    jasiMode: profile.useYaJasi ? JasiMode.yaJasi : JasiMode.joJasi,
  );
}

/// 사주차트 화면 상태
class SajuChartScreenState {
  final bool isLoading;
  final String? errorMessage;
  final bool showDetails;

  const SajuChartScreenState({
    this.isLoading = false,
    this.errorMessage,
    this.showDetails = false,
  });

  SajuChartScreenState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool? showDetails,
  }) {
    return SajuChartScreenState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      showDetails: showDetails ?? this.showDetails,
    );
  }
}

/// 사주차트 화면 상태 Provider
@riverpod
class SajuChartScreenNotifier extends _$SajuChartScreenNotifier {
  @override
  SajuChartScreenState build() {
    return const SajuChartScreenState();
  }

  void toggleDetails() {
    state = state.copyWith(showDetails: !state.showDetails);
  }

  void setLoading(bool loading) {
    state = state.copyWith(isLoading: loading);
  }

  void setError(String? message) {
    state = state.copyWith(errorMessage: message);
  }
}
