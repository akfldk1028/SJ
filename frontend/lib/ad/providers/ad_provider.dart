import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../ad_service.dart';
import '../ad_strategy.dart';

part 'ad_provider.g.dart';

/// 광고 상태 관리 Provider
///
/// 광고 표시 조건, 카운터, 쿨다운 관리
@riverpod
class AdController extends _$AdController {
  static const _keyInterstitialCount = 'ad_interstitial_count';
  static const _keyNewSessionAdCount = 'ad_new_session_count';
  static const _keyLastInterstitialTime = 'ad_last_interstitial_time';
  static const _keyChatCount = 'ad_chat_count';
  static const _keyLastResetDate = 'ad_last_reset_date';

  SharedPreferences? _prefs;

  @override
  AdState build() {
    _initPrefs();
    return const AdState();
  }

  Future<void> _initPrefs() async {
    // Web에서는 SharedPreferences 지원 안 될 수 있음
    if (kIsWeb) {
      state = state.copyWith(isInitialized: true);
      return;
    }

    try {
      _prefs = await SharedPreferences.getInstance();
      await _checkDailyReset();
      await _loadState();
      state = state.copyWith(isInitialized: true);
    } catch (e) {
      debugPrint('[AdController] SharedPreferences 초기화 실패: $e');
      state = state.copyWith(isInitialized: true);
    }
  }

  /// 날짜 변경 시 카운터 리셋
  Future<void> _checkDailyReset() async {
    final prefs = _prefs;
    if (prefs == null) return;

    final today = DateTime.now().toIso8601String().substring(0, 10);
    final lastReset = prefs.getString(_keyLastResetDate);

    if (lastReset != today) {
      await prefs.setInt(_keyInterstitialCount, 0);
      await prefs.setInt(_keyNewSessionAdCount, 0);
      await prefs.setInt(_keyChatCount, 0);
      await prefs.setString(_keyLastResetDate, today);
      debugPrint('[AdController] 일일 카운터 리셋');
    }
  }

  Future<void> _loadState() async {
    final prefs = _prefs;
    if (prefs == null) return;

    state = state.copyWith(
      interstitialCount: prefs.getInt(_keyInterstitialCount) ?? 0,
      newSessionAdCount: prefs.getInt(_keyNewSessionAdCount) ?? 0,
      chatCount: prefs.getInt(_keyChatCount) ?? 0,
      lastInterstitialTime: prefs.getInt(_keyLastInterstitialTime) ?? 0,
    );
  }

  Future<void> _saveState() async {
    final prefs = _prefs;
    if (prefs == null) return;

    await prefs.setInt(_keyInterstitialCount, state.interstitialCount);
    await prefs.setInt(_keyNewSessionAdCount, state.newSessionAdCount);
    await prefs.setInt(_keyChatCount, state.chatCount);
    await prefs.setInt(_keyLastInterstitialTime, state.lastInterstitialTime);
  }

  // ==================== 전면 광고 ====================

  /// 전면 광고 표시 가능 여부 체크
  AdCheckResult canShowInterstitial() {
    // Web에서는 광고 미지원
    if (kIsWeb) {
      return const AdCheckResult.skip('Web 플랫폼 미지원');
    }

    // 일일 한도 체크
    if (state.interstitialCount >= AdStrategy.interstitialDailyLimit) {
      return const AdCheckResult.skip('일일 한도 초과');
    }

    // 쿨다운 체크
    final now = DateTime.now().millisecondsSinceEpoch;
    final elapsed = (now - state.lastInterstitialTime) ~/ 1000;
    if (elapsed < AdStrategy.interstitialCooldownSeconds) {
      return AdCheckResult.skip('쿨다운 중 (${AdStrategy.interstitialCooldownSeconds - elapsed}초)');
    }

    // 광고 로드 상태 체크
    if (!AdService.instance.isInterstitialLoaded) {
      return const AdCheckResult.skip('광고 로드 안됨');
    }

    return const AdCheckResult.show();
  }

  /// 채팅 메시지 카운트 후 전면 광고 체크
  Future<bool> onChatMessage() async {
    state = state.copyWith(chatCount: state.chatCount + 1);

    // N개 메시지마다 전면 광고
    if (state.chatCount % AdStrategy.interstitialMessageInterval == 0) {
      return await showInterstitial();
    }

    return false;
  }

  /// 새 세션 시작 시 전면 광고
  Future<bool> onNewSession() async {
    if (!AdStrategy.showInterstitialOnNewSession) return false;

    if (state.newSessionAdCount >= AdStrategy.newSessionInterstitialDailyLimit) {
      debugPrint('[AdController] 새 세션 광고 일일 한도 초과');
      return false;
    }

    final result = await showInterstitial();
    if (result) {
      state = state.copyWith(newSessionAdCount: state.newSessionAdCount + 1);
      await _saveState();
    }

    return result;
  }

  /// 전면 광고 표시
  Future<bool> showInterstitial() async {
    final check = canShowInterstitial();
    if (!check.shouldShow) {
      debugPrint('[AdController] 전면 광고 스킵: ${check.reason}');
      return false;
    }

    final result = await AdService.instance.showInterstitialAd();
    if (result) {
      state = state.copyWith(
        interstitialCount: state.interstitialCount + 1,
        lastInterstitialTime: DateTime.now().millisecondsSinceEpoch,
      );
      await _saveState();
      debugPrint('[AdController] 전면 광고 표시 완료 (${state.interstitialCount}/${AdStrategy.interstitialDailyLimit})');
    }

    return result;
  }

  // ==================== 보상형 광고 ====================

  /// 보상형 광고 표시 가능 여부
  bool canShowRewarded() {
    if (kIsWeb) return false;
    return AdService.instance.isRewardedLoaded;
  }

  /// 보상형 광고 표시
  Future<bool> showRewarded({
    required void Function(int amount, String type) onRewarded,
  }) async {
    if (!canShowRewarded()) {
      debugPrint('[AdController] 보상형 광고 미준비');
      return false;
    }

    return await AdService.instance.showRewardedAd(onRewarded: onRewarded);
  }

  // ==================== 광고 초기화 ====================

  /// 광고 사전 로드
  Future<void> preloadAds() async {
    if (kIsWeb) return;

    await AdService.instance.initialize();
    await AdService.instance.loadInterstitialAd();
    await AdService.instance.loadRewardedAd();
    debugPrint('[AdController] 광고 사전 로드 완료');
  }
}

/// 광고 상태
class AdState {
  final bool isInitialized;
  final int interstitialCount; // 오늘 전면 광고 표시 횟수
  final int newSessionAdCount; // 오늘 새 세션 광고 횟수
  final int chatCount; // 채팅 메시지 카운트
  final int lastInterstitialTime; // 마지막 전면 광고 시간 (ms)

  const AdState({
    this.isInitialized = false,
    this.interstitialCount = 0,
    this.newSessionAdCount = 0,
    this.chatCount = 0,
    this.lastInterstitialTime = 0,
  });

  AdState copyWith({
    bool? isInitialized,
    int? interstitialCount,
    int? newSessionAdCount,
    int? chatCount,
    int? lastInterstitialTime,
  }) {
    return AdState(
      isInitialized: isInitialized ?? this.isInitialized,
      interstitialCount: interstitialCount ?? this.interstitialCount,
      newSessionAdCount: newSessionAdCount ?? this.newSessionAdCount,
      chatCount: chatCount ?? this.chatCount,
      lastInterstitialTime: lastInterstitialTime ?? this.lastInterstitialTime,
    );
  }
}
