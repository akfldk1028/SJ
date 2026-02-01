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
String _$sajuAnalysisForProfileHash() =>
    r'3b33c4f7ae0d945afec7bc5398a075aba11431be';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// 특정 프로필의 사주 분석 Provider (profileId 기반)
///
/// 관계도에서 다른 사람의 사주 상세를 볼 때 사용
///
/// Copied from [sajuAnalysisForProfile].
@ProviderFor(sajuAnalysisForProfile)
const sajuAnalysisForProfileProvider = SajuAnalysisForProfileFamily();

/// 특정 프로필의 사주 분석 Provider (profileId 기반)
///
/// 관계도에서 다른 사람의 사주 상세를 볼 때 사용
///
/// Copied from [sajuAnalysisForProfile].
class SajuAnalysisForProfileFamily extends Family<AsyncValue<SajuAnalysis?>> {
  /// 특정 프로필의 사주 분석 Provider (profileId 기반)
  ///
  /// 관계도에서 다른 사람의 사주 상세를 볼 때 사용
  ///
  /// Copied from [sajuAnalysisForProfile].
  const SajuAnalysisForProfileFamily();

  /// 특정 프로필의 사주 분석 Provider (profileId 기반)
  ///
  /// 관계도에서 다른 사람의 사주 상세를 볼 때 사용
  ///
  /// Copied from [sajuAnalysisForProfile].
  SajuAnalysisForProfileProvider call(String profileId) {
    return SajuAnalysisForProfileProvider(profileId);
  }

  @override
  SajuAnalysisForProfileProvider getProviderOverride(
    covariant SajuAnalysisForProfileProvider provider,
  ) {
    return call(provider.profileId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'sajuAnalysisForProfileProvider';
}

/// 특정 프로필의 사주 분석 Provider (profileId 기반)
///
/// 관계도에서 다른 사람의 사주 상세를 볼 때 사용
///
/// Copied from [sajuAnalysisForProfile].
class SajuAnalysisForProfileProvider
    extends AutoDisposeFutureProvider<SajuAnalysis?> {
  /// 특정 프로필의 사주 분석 Provider (profileId 기반)
  ///
  /// 관계도에서 다른 사람의 사주 상세를 볼 때 사용
  ///
  /// Copied from [sajuAnalysisForProfile].
  SajuAnalysisForProfileProvider(String profileId)
    : this._internal(
        (ref) =>
            sajuAnalysisForProfile(ref as SajuAnalysisForProfileRef, profileId),
        from: sajuAnalysisForProfileProvider,
        name: r'sajuAnalysisForProfileProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$sajuAnalysisForProfileHash,
        dependencies: SajuAnalysisForProfileFamily._dependencies,
        allTransitiveDependencies:
            SajuAnalysisForProfileFamily._allTransitiveDependencies,
        profileId: profileId,
      );

  SajuAnalysisForProfileProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.profileId,
  }) : super.internal();

  final String profileId;

  @override
  Override overrideWith(
    FutureOr<SajuAnalysis?> Function(SajuAnalysisForProfileRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: SajuAnalysisForProfileProvider._internal(
        (ref) => create(ref as SajuAnalysisForProfileRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        profileId: profileId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<SajuAnalysis?> createElement() {
    return _SajuAnalysisForProfileProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is SajuAnalysisForProfileProvider &&
        other.profileId == profileId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, profileId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin SajuAnalysisForProfileRef on AutoDisposeFutureProviderRef<SajuAnalysis?> {
  /// The parameter `profileId` of this provider.
  String get profileId;
}

class _SajuAnalysisForProfileProviderElement
    extends AutoDisposeFutureProviderElement<SajuAnalysis?>
    with SajuAnalysisForProfileRef {
  _SajuAnalysisForProfileProviderElement(super.provider);

  @override
  String get profileId => (origin as SajuAnalysisForProfileProvider).profileId;
}

String _$sajuChartForProfileHash() =>
    r'44bd369619d9e76c3e12c8956f2b309c171f51b5';

/// 특정 프로필의 사주차트 Provider (profileId 기반)
///
/// Copied from [sajuChartForProfile].
@ProviderFor(sajuChartForProfile)
const sajuChartForProfileProvider = SajuChartForProfileFamily();

/// 특정 프로필의 사주차트 Provider (profileId 기반)
///
/// Copied from [sajuChartForProfile].
class SajuChartForProfileFamily extends Family<AsyncValue<SajuChart?>> {
  /// 특정 프로필의 사주차트 Provider (profileId 기반)
  ///
  /// Copied from [sajuChartForProfile].
  const SajuChartForProfileFamily();

  /// 특정 프로필의 사주차트 Provider (profileId 기반)
  ///
  /// Copied from [sajuChartForProfile].
  SajuChartForProfileProvider call(String profileId) {
    return SajuChartForProfileProvider(profileId);
  }

  @override
  SajuChartForProfileProvider getProviderOverride(
    covariant SajuChartForProfileProvider provider,
  ) {
    return call(provider.profileId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'sajuChartForProfileProvider';
}

/// 특정 프로필의 사주차트 Provider (profileId 기반)
///
/// Copied from [sajuChartForProfile].
class SajuChartForProfileProvider
    extends AutoDisposeFutureProvider<SajuChart?> {
  /// 특정 프로필의 사주차트 Provider (profileId 기반)
  ///
  /// Copied from [sajuChartForProfile].
  SajuChartForProfileProvider(String profileId)
    : this._internal(
        (ref) => sajuChartForProfile(ref as SajuChartForProfileRef, profileId),
        from: sajuChartForProfileProvider,
        name: r'sajuChartForProfileProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$sajuChartForProfileHash,
        dependencies: SajuChartForProfileFamily._dependencies,
        allTransitiveDependencies:
            SajuChartForProfileFamily._allTransitiveDependencies,
        profileId: profileId,
      );

  SajuChartForProfileProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.profileId,
  }) : super.internal();

  final String profileId;

  @override
  Override overrideWith(
    FutureOr<SajuChart?> Function(SajuChartForProfileRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: SajuChartForProfileProvider._internal(
        (ref) => create(ref as SajuChartForProfileRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        profileId: profileId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<SajuChart?> createElement() {
    return _SajuChartForProfileProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is SajuChartForProfileProvider && other.profileId == profileId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, profileId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin SajuChartForProfileRef on AutoDisposeFutureProviderRef<SajuChart?> {
  /// The parameter `profileId` of this provider.
  String get profileId;
}

class _SajuChartForProfileProviderElement
    extends AutoDisposeFutureProviderElement<SajuChart?>
    with SajuChartForProfileRef {
  _SajuChartForProfileProviderElement(super.provider);

  @override
  String get profileId => (origin as SajuChartForProfileProvider).profileId;
}

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
    r'2b79bb559d2625ff9d6195238b5105c19ce209d4';

/// 현재 사주 종합 분석 Provider
///
/// 분석 결과를 계산 (저장은 profile_provider에서 처리)
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
