// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$profileRepositoryHash() => r'110e9b16f644327e2dde309cedfb4a69a403bccd';

/// ProfileRepository Provider
///
/// Copied from [profileRepository].
@ProviderFor(profileRepository)
final profileRepositoryProvider =
    AutoDisposeProvider<ProfileRepository>.internal(
      profileRepository,
      name: r'profileRepositoryProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$profileRepositoryHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ProfileRepositoryRef = AutoDisposeProviderRef<ProfileRepository>;
String _$allProfilesHash() => r'7fd8a6c741514dc59a1bcf31eb3ec06992906ee7';

/// 모든 프로필 목록 Provider (Alias for ProfileList)
///
/// Copied from [allProfiles].
@ProviderFor(allProfiles)
final allProfilesProvider =
    AutoDisposeFutureProvider<List<SajuProfile>>.internal(
      allProfiles,
      name: r'allProfilesProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$allProfilesHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AllProfilesRef = AutoDisposeFutureProviderRef<List<SajuProfile>>;
String _$profileListHash() => r'a626b2540abb39c53aac0f396e3fffd6c1d8728f';

/// 프로필 목록 Provider
///
/// Copied from [ProfileList].
@ProviderFor(ProfileList)
final profileListProvider =
    AutoDisposeAsyncNotifierProvider<ProfileList, List<SajuProfile>>.internal(
      ProfileList.new,
      name: r'profileListProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$profileListHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$ProfileList = AutoDisposeAsyncNotifier<List<SajuProfile>>;
String _$activeProfileHash() => r'503d0e0931fc03febab00264f749bcb68df615b9';

/// 현재 활성 프로필 Provider
///
/// Copied from [ActiveProfile].
@ProviderFor(ActiveProfile)
final activeProfileProvider =
    AutoDisposeAsyncNotifierProvider<ActiveProfile, SajuProfile?>.internal(
      ActiveProfile.new,
      name: r'activeProfileProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$activeProfileHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$ActiveProfile = AutoDisposeAsyncNotifier<SajuProfile?>;
String _$profileFormHash() => r'5d46196208fefb05d2165a6bb722cfba5649fa1d';

/// 프로필 폼 Provider
///
/// Copied from [ProfileForm].
@ProviderFor(ProfileForm)
final profileFormProvider =
    AutoDisposeNotifierProvider<ProfileForm, ProfileFormState>.internal(
      ProfileForm.new,
      name: r'profileFormProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$profileFormHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$ProfileForm = AutoDisposeNotifier<ProfileFormState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
