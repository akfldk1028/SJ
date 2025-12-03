import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../profile/domain/entities/saju_profile.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../domain/entities/saju_chart.dart';
import '../../domain/services/jasi_service.dart';
import '../../domain/services/saju_calculation_service.dart';

part 'saju_chart_provider.g.dart';

/// 사주 계산 서비스 Provider
@riverpod
SajuCalculationService sajuCalculationService(Ref ref) {
  return SajuCalculationService();
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
