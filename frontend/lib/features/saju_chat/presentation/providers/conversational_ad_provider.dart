/// 대화형 광고 Provider
///
/// 토큰 기반 광고 트리거 및 상태 관리
/// Riverpod 3.0 annotation 스타일
library;

import 'dart:async';
import 'dart:io' show Platform;
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../ad/ad_config.dart';
import '../../data/models/conversational_ad_model.dart';
import '../../data/services/ad_trigger_service.dart';
import '../../domain/models/ad_persona_prompt.dart';
import '../../domain/models/ai_persona.dart';

part 'conversational_ad_provider.g.dart';

/// 모바일 플랫폼 체크
bool get _isMobile => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

/// 대화형 광고 상태 관리 Provider
///
/// 사용 예:
/// ```dart
/// // 토큰 사용량 체크 & 광고 트리거
/// ref.read(conversationalAdProvider.notifier).checkAndTrigger(
///   tokenUsage: tokenUsageInfo,
///   messageCount: messages.length,
///   persona: currentPersona,
/// );
///
/// // 광고 시청 완료 처리
/// ref.read(conversationalAdProvider.notifier).onAdWatched();
/// ```
@riverpod
class ConversationalAdNotifier extends _$ConversationalAdNotifier {
  NativeAd? _nativeAd;
  RewardedAd? _rewardedAd;

  @override
  ConversationalAdModel build() {
    // Provider dispose 시 광고 정리
    ref.onDispose(() {
      _nativeAd?.dispose();
      _rewardedAd?.dispose();
    });

    return const ConversationalAdModel();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 광고 트리거
  // ═══════════════════════════════════════════════════════════════════════════

  /// 토큰 사용량 체크 및 광고 트리거
  ///
  /// [tokenUsage]: 현재 토큰 사용량
  /// [messageCount]: 현재 메시지 수
  /// [persona]: 현재 AI 페르소나
  ///
  /// Returns: AdTriggerResult (트리거 결과)
  AdTriggerResult checkAndTrigger({
    required TokenUsageInfo tokenUsage,
    required int messageCount,
    required AiPersona persona,
  }) {
    // 이미 광고 모드면 스킵
    if (state.isAdMode) {
      return AdTriggerResult.none;
    }

    // 트리거 체크
    final trigger = AdTriggerService.checkTrigger(
      tokenUsage: tokenUsage,
      messageCount: messageCount,
    );

    if (trigger == AdTriggerResult.none) {
      return trigger;
    }

    // 광고 모드 활성화
    _activateAdMode(trigger, persona, tokenUsage.usageRate);

    return trigger;
  }

  /// 광고 모드 활성화
  void _activateAdMode(
    AdTriggerResult trigger,
    AiPersona persona,
    double tokenUsageRate,
  ) {
    final adType = AdTriggerService.triggerToAdType(trigger);
    if (adType == null) return;

    // 전환 문구 생성 (AI 생성 대신 템플릿 사용 - 토큰 절약)
    final transitionText = AdPersonaPrompt.getDefaultTransitionText(persona, trigger);
    final ctaText = AdPersonaPrompt.getCtaText(persona, trigger);
    final rewardTokens = AdTriggerService.getRewardTokens(trigger);

    state = state.copyWith(
      isAdMode: true,
      tokenUsageRate: tokenUsageRate,
      adType: adType,
      transitionText: transitionText,
      ctaText: ctaText,
      rewardedTokens: rewardTokens > 0 ? rewardTokens : null,
      loadState: AdLoadState.idle,
    );

    if (kDebugMode) {
      print('');
      print('┌──────────────────────────────────────────────────────────────┐');
      print('│  📢 [AD] CONVERSATIONAL AD TRIGGERED                         │');
      print('└──────────────────────────────────────────────────────────────┘');
      print('   🎯 Trigger: ${trigger.name}');
      print('   🎭 Persona: ${persona.displayName}');
      print('   📝 Transition: ${transitionText.substring(0, transitionText.length.clamp(0, 50))}...');
      print('   🎁 Reward: ${rewardTokens > 0 ? '$rewardTokens tokens' : 'none'}');
    }

    // 광고 로드 시작
    _loadAd(adType);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 광고 로드
  // ═══════════════════════════════════════════════════════════════════════════

  /// 광고 로드
  void _loadAd(AdMessageType adType) {
    if (!_isMobile) {
      // Web에서는 광고 스킵
      state = state.copyWith(loadState: AdLoadState.loaded);
      return;
    }

    state = state.copyWith(loadState: AdLoadState.loading);

    // 토큰 소진 시 보상형 광고, 그 외 네이티브 광고
    if (adType == AdMessageType.tokenDepleted) {
      _loadRewardedAd();
    } else {
      _loadNativeAd();
    }
  }

  /// Native 광고 로드
  void _loadNativeAd() {
    _nativeAd?.dispose();

    _nativeAd = NativeAd(
      adUnitId: AdUnitId.native,
      request: const AdRequest(),
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          if (kDebugMode) {
            print('   ✅ [AD] Native ad loaded');
          }
          state = state.copyWith(loadState: AdLoadState.loaded);
        },
        onAdFailedToLoad: (ad, error) {
          if (kDebugMode) {
            print('   ❌ [AD] Native ad failed: ${error.message}');
          }
          ad.dispose();
          _nativeAd = null;
          state = state.copyWith(
            loadState: AdLoadState.failed,
            errorMessage: error.message,
          );
        },
        onAdClicked: (ad) {
          if (kDebugMode) {
            print('   👆 [AD] Native ad clicked');
          }
        },
        onAdImpression: (ad) {
          if (kDebugMode) {
            print('   👁️ [AD] Native ad impression');
          }
          // 인상 기록 시 광고 시청 완료 처리
          _onAdImpression();
        },
      ),
      nativeTemplateStyle: NativeTemplateStyle(
        templateType: TemplateType.medium,
        mainBackgroundColor: const Color(0xFF1A1A24),
        cornerRadius: 16,
        callToActionTextStyle: NativeTemplateTextStyle(
          textColor: const Color(0xFFFFFFFF),
          backgroundColor: const Color(0xFFD4AF37), // 금색
          style: NativeTemplateFontStyle.bold,
          size: 14,
        ),
        primaryTextStyle: NativeTemplateTextStyle(
          textColor: const Color(0xFFE0E0E0),
          style: NativeTemplateFontStyle.bold,
          size: 14,
        ),
        secondaryTextStyle: NativeTemplateTextStyle(
          textColor: const Color(0xFFB0B0B0),
          style: NativeTemplateFontStyle.normal,
          size: 12,
        ),
      ),
    );

    _nativeAd!.load();
  }

  /// 보상형 광고 로드
  void _loadRewardedAd() {
    _rewardedAd?.dispose();

    RewardedAd.load(
      adUnitId: AdUnitId.rewarded,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          if (kDebugMode) {
            print('   ✅ [AD] Rewarded ad loaded');
          }
          _rewardedAd = ad;
          state = state.copyWith(loadState: AdLoadState.loaded);
        },
        onAdFailedToLoad: (error) {
          if (kDebugMode) {
            print('   ❌ [AD] Rewarded ad failed: ${error.message}');
          }
          state = state.copyWith(
            loadState: AdLoadState.failed,
            errorMessage: error.message,
          );
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 광고 표시 & 완료
  // ═══════════════════════════════════════════════════════════════════════════

  /// Native 광고 위젯 가져오기
  NativeAd? get nativeAd => _nativeAd;

  /// 보상형 광고 표시
  Future<bool> showRewardedAd() async {
    if (_rewardedAd == null) {
      return false;
    }

    final completer = Completer<bool>();

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _rewardedAd = null;
        completer.complete(true);
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _rewardedAd = null;
        completer.complete(false);
      },
    );

    _rewardedAd!.show(
      onUserEarnedReward: (ad, reward) {
        if (kDebugMode) {
          print('   🎁 [AD] Reward earned: ${reward.amount} ${reward.type}');
        }
        _onRewardEarned();
      },
    );

    return completer.future;
  }

  /// 광고 인상 처리
  void _onAdImpression() {
    // 필수 광고가 아니면 인상만으로 시청 완료
    if (state.adType != AdMessageType.tokenDepleted) {
      state = state.copyWith(adWatched: true);
    }
  }

  /// 보상 획득 처리
  void _onRewardEarned() {
    state = state.copyWith(adWatched: true);
  }

  /// 광고 시청 완료 (수동 호출)
  void onAdWatched() {
    state = state.copyWith(adWatched: true);
  }

  /// 광고 모드 종료 & 대화 재개
  void dismissAd() {
    _nativeAd?.dispose();
    _nativeAd = null;
    _rewardedAd?.dispose();
    _rewardedAd = null;

    state = const ConversationalAdModel();

    if (kDebugMode) {
      print('   🔄 [AD] Ad dismissed, conversation resumed');
    }
  }

  /// 광고 스킵 (선택적 광고만)
  bool skipAd() {
    // 필수 광고는 스킵 불가
    if (state.adType == AdMessageType.tokenDepleted) {
      return false;
    }

    dismissAd();
    return true;
  }
}
