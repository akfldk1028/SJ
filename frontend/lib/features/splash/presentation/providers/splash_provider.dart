import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/data/query_result.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../AI/services/saju_analysis_service.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../../profile/domain/entities/saju_profile.dart';
import '../../../saju_chart/data/models/saju_analysis_db_model.dart';
import '../../data/data.dart';

part 'splash_provider.g.dart';

// ============================================================================
// Splash State
// ============================================================================

/// Splash 상태
class SplashState {
  final PrefetchStatus status;
  final SajuProfile? profile;
  final SajuAnalysisDbModel? analysis;
  final String? errorMessage;
  final bool isFromCache;

  const SplashState({
    required this.status,
    this.profile,
    this.analysis,
    this.errorMessage,
    this.isFromCache = false,
  });

  /// 초기 상태
  const SplashState.initial()
      : status = PrefetchStatus.loading,
        profile = null,
        analysis = null,
        errorMessage = null,
        isFromCache = false;

  /// 데이터 있음
  factory SplashState.hasData({
    required SajuProfile profile,
    required SajuAnalysisDbModel analysis,
    bool isFromCache = false,
  }) {
    return SplashState(
      status: PrefetchStatus.hasData,
      profile: profile,
      analysis: analysis,
      isFromCache: isFromCache,
    );
  }

  /// 프로필만 있음 (분석 없음)
  factory SplashState.noAnalysis({
    required SajuProfile profile,
    bool isFromCache = false,
  }) {
    return SplashState(
      status: PrefetchStatus.noAnalysis,
      profile: profile,
      isFromCache: isFromCache,
    );
  }

  /// 프로필 없음 (신규 사용자)
  const SplashState.noProfile()
      : status = PrefetchStatus.noProfile,
        profile = null,
        analysis = null,
        errorMessage = null,
        isFromCache = false;

  /// 오프라인
  factory SplashState.offline({
    SajuProfile? profile,
    SajuAnalysisDbModel? analysis,
  }) {
    return SplashState(
      status: PrefetchStatus.offline,
      profile: profile,
      analysis: analysis,
      isFromCache: true,
    );
  }

  /// 에러
  factory SplashState.error(String message) {
    return SplashState(
      status: PrefetchStatus.error,
      errorMessage: message,
    );
  }

  /// 네비게이션 가능 여부
  bool get canNavigate =>
      status != PrefetchStatus.loading && status != PrefetchStatus.error;

  /// 메인 화면으로 이동 가능
  bool get shouldGoToMain =>
      status == PrefetchStatus.hasData || status == PrefetchStatus.offline;

  /// 온보딩으로 이동 필요
  bool get shouldGoToOnboarding => status == PrefetchStatus.noProfile;

  /// 분석 계산 필요
  bool get needsAnalysis => status == PrefetchStatus.noAnalysis;
}

// ============================================================================
// Splash Provider
// ============================================================================

/// Splash Pre-fetch Provider
///
/// 앱 시작 시 필수 데이터를 로드하고 상태를 관리
@riverpod
class Splash extends _$Splash {
  @override
  Future<SplashState> build() async {
    return _prefetch();
  }

  /// Pre-fetch 실행
  Future<SplashState> _prefetch() async {
    try {
      // 1. Supabase 인증 확인
      final user = await SupabaseService.ensureAuthenticated();

      if (user == null || !SupabaseService.isConnected) {
        // 오프라인 모드: Hive 캐시 사용
        return _loadFromCache();
      }

      final userId = user.id;
      if (kDebugMode) {
        print('[Splash] Pre-fetching for user: $userId');
      }

      // 2. Supabase에서 Pre-fetch
      final result = await splashQueries.prefetchPrimaryData(userId);

      switch (result) {
        case QuerySuccess(:final data) when data != null:
          // 데이터 있음
          if (data.hasAnalysis) {
            if (kDebugMode) {
              print('[Splash] Data loaded: ${data.profile.displayName}');
            }

            // Hive 캐시 업데이트
            await _updateCache(data);

            return SplashState.hasData(
              profile: data.profile.toEntity(),
              analysis: data.analysis!,
            );
          } else {
            // 프로필만 있고 saju_base 분석 없음 (기존 사용자)
            if (kDebugMode) {
              print('[Splash] Profile found but no saju_base analysis');
              print('[Splash] 🔥 Triggering GPT-5.2 analysis in background...');
            }

            // 백그라운드에서 GPT-5.2 분석 시작 (Fire-and-forget)
            // Gemini 채팅 전에 saju_origin 데이터가 준비되도록 함
            final profileId = data.profile.id;
            sajuAnalysisService.ensureSajuBaseAnalysis(
              userId: userId,
              profileId: profileId,
              runInBackground: true,
              onComplete: (result) {
                if (kDebugMode) {
                  print('[Splash] ✅ Background GPT-5.2 analysis completed: ${result.success}');
                }
              },
            );

            return SplashState.noAnalysis(
              profile: data.profile.toEntity(),
            );
          }

        case QuerySuccess():
          // 프로필 없음 (신규 사용자)
          if (kDebugMode) {
            print('[Splash] No profile found - new user');
          }
          return const SplashState.noProfile();

        case QueryOffline():
          // 오프라인
          if (kDebugMode) {
            print('[Splash] Offline - using cache');
          }
          return _loadFromCache();

        case QueryFailure(:final message):
          // 에러 발생 - 캐시로 폴백
          if (kDebugMode) {
            print('[Splash] Query failed: $message - falling back to cache');
          }
          return _loadFromCache();
      }
    } catch (e) {
      if (kDebugMode) {
        print('[Splash] Error: $e');
      }
      // 에러 시 캐시로 폴백
      return _loadFromCache();
    }
  }

  /// Hive 캐시에서 로드
  Future<SplashState> _loadFromCache() async {
    try {
      // 기존 Hive 기반 프로필 로드
      final activeProfile = await ref.read(activeProfileProvider.future);

      if (activeProfile != null) {
        if (kDebugMode) {
          print('[Splash] Cache hit: ${activeProfile.displayName}');
        }

        // TODO: Hive에서 분석 데이터도 로드
        // 현재는 프로필만 있으면 메인으로 이동
        return SplashState.offline(
          profile: activeProfile,
        );
      }

      // 활성 프로필이 없으면 전체 프로필 확인
      final allProfiles = await ref.read(allProfilesProvider.future);

      if (allProfiles.isNotEmpty) {
        // 첫 번째 프로필 활성화
        final repository = ref.read(profileRepositoryProvider);
        await repository.setActive(allProfiles.first.id);
        ref.invalidate(activeProfileProvider);

        return SplashState.offline(
          profile: allProfiles.first,
        );
      }

      // 캐시에도 데이터 없음
      return const SplashState.noProfile();
    } catch (e) {
      if (kDebugMode) {
        print('[Splash] Cache load error: $e');
      }
      return const SplashState.noProfile();
    }
  }

  /// Hive 캐시 업데이트
  Future<void> _updateCache(SplashPrefetchData data) async {
    try {
      final repository = ref.read(profileRepositoryProvider);
      final profile = data.profile.toEntity();

      // 프로필 저장 및 활성화
      await repository.save(profile);
      await repository.setActive(profile.id);

      // Provider 갱신
      ref.invalidate(activeProfileProvider);
      ref.invalidate(allProfilesProvider);

      if (kDebugMode) {
        print('[Splash] Cache updated: ${profile.displayName}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('[Splash] Cache update failed: $e');
      }
    }
  }

  /// 수동 새로고침
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _prefetch());
  }

  /// 분석 재계산 후 상태 업데이트
  Future<void> updateWithAnalysis(SajuAnalysisDbModel analysis) async {
    final currentState = state.valueOrNull;
    if (currentState?.profile != null) {
      state = AsyncValue.data(
        SplashState.hasData(
          profile: currentState!.profile!,
          analysis: analysis,
        ),
      );
    }
  }
}

// ============================================================================
// 편의 Provider
// ============================================================================

/// Pre-fetch 상태만 확인 (빠른 체크)
@riverpod
Future<PrefetchStatus> splashStatus(Ref ref) async {
  final user = SupabaseService.currentUser;

  if (user == null || !SupabaseService.isConnected) {
    // 오프라인 체크
    final activeProfile = await ref.read(activeProfileProvider.future);
    return activeProfile != null ? PrefetchStatus.offline : PrefetchStatus.noProfile;
  }

  final result = await splashQueries.checkPrefetchStatus(user.id);
  return result.data ?? PrefetchStatus.error;
}

/// Primary 프로필 ID (캐시 우선)
@riverpod
Future<String?> primaryProfileId(Ref ref) async {
  // 1. 캐시 먼저
  final activeProfile = await ref.watch(activeProfileProvider.future);
  if (activeProfile != null) {
    return activeProfile.id;
  }

  // 2. Supabase
  final user = SupabaseService.currentUser;
  if (user == null) return null;

  final result = await splashQueries.getPrimaryProfile(user.id);
  return result.data?.id;
}
