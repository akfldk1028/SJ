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
String _$profileListHash() => r'd358b2737d7df7d48630d3e1e33570fc966b7d4b';

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
String _$activeProfileHash() => r'1bf4bc0869bd14b5729ea6bc999bdb68e5b2252f';

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
String _$profileFormHash() => r'7b8421913b89ffb16a549cffa0ecbf9e0ed93eeb';

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
