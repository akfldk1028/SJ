// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'saju_chart_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$sajuCalculationServiceHash() =>
    r'2918ea5d2413d1972a92e58d55de5788947a1067';

/// 사주 계산 서비스 Provider
///
/// Copied from [sajuCalculationService].
@ProviderFor(sajuCalculationService)
final sajuCalculationServiceProvider =
    AutoDisposeProvider<SajuCalculationService>.internal(
      sajuCalculationService,
      name: r'sajuCalculationServiceProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$sajuCalculationServiceHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef SajuCalculationServiceRef =
    AutoDisposeProviderRef<SajuCalculationService>;
String _$sajuAnalysisServiceHash() =>
    r'8b2a8ed1260ea6e0f6d5d8ac040764e53e6f750b';

/// 사주 종합 분석 서비스 Provider
///
/// Copied from [sajuAnalysisService].
@ProviderFor(sajuAnalysisService)
final sajuAnalysisServiceProvider =
    AutoDisposeProvider<SajuAnalysisService>.internal(
      sajuAnalysisService,
      name: r'sajuAnalysisServiceProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$sajuAnalysisServiceHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef SajuAnalysisServiceRef = AutoDisposeProviderRef<SajuAnalysisService>;
String _$sajuAnalysisRepositoryHash() =>
    r'd9b60320604d86c0db57564136a63c3c45a104ca';

/// Supabase 사주 분석 Repository Provider
///
/// Copied from [sajuAnalysisRepository].
@ProviderFor(sajuAnalysisRepository)
final sajuAnalysisRepositoryProvider =
    AutoDisposeProvider<SajuAnalysisRepository>.internal(
      sajuAnalysisRepository,
      name: r'sajuAnalysisRepositoryProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$sajuAnalysisRepositoryHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef SajuAnalysisRepositoryRef =
    AutoDisposeProviderRef<SajuAnalysisRepository>;
String _$currentSajuChartHash() => r'aa69b5d61e6f1aa843513f3f5cda2a38eeec5d52';

/// 현재 활성 프로필의 사주차트 Provider
///
/// Copied from [CurrentSajuChart].
@ProviderFor(CurrentSajuChart)
final currentSajuChartProvider =
    AutoDisposeAsyncNotifierProvider<CurrentSajuChart, SajuChart?>.internal(
      CurrentSajuChart.new,
      name: r'currentSajuChartProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$currentSajuChartHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$CurrentSajuChart = AutoDisposeAsyncNotifier<SajuChart?>;
String _$currentSajuAnalysisHash() =>
    r'2fa0f9a751cbe3d14f898a18ba4120e730c6bd78';

/// 현재 사주 종합 분석 Provider
///
/// 분석 결과를 계산하고 Supabase에 자동 저장
///
/// Copied from [CurrentSajuAnalysis].
@ProviderFor(CurrentSajuAnalysis)
final currentSajuAnalysisProvider =
    AutoDisposeAsyncNotifierProvider<
      CurrentSajuAnalysis,
      SajuAnalysis?
    >.internal(
      CurrentSajuAnalysis.new,
      name: r'currentSajuAnalysisProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$currentSajuAnalysisHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$CurrentSajuAnalysis = AutoDisposeAsyncNotifier<SajuAnalysis?>;
String _$sajuChartScreenNotifierHash() =>
    r'7951dfa3c5dbac971f9fd6cb90cf84fe2c4d158f';

/// 사주차트 화면 상태 Provider
///
/// Copied from [SajuChartScreenNotifier].
@ProviderFor(SajuChartScreenNotifier)
final sajuChartScreenNotifierProvider =
    AutoDisposeNotifierProvider<
      SajuChartScreenNotifier,
      SajuChartScreenState
    >.internal(
      SajuChartScreenNotifier.new,
      name: r'sajuChartScreenNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$sajuChartScreenNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$SajuChartScreenNotifier = AutoDisposeNotifier<SajuChartScreenState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
