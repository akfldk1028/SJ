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
import '../../../../ad/ad_tracking_service.dart';
import '../../../../purchase/purchase.dart';
import '../../data/models/conversational_ad_model.dart';
import '../../data/services/ad_trigger_service.dart';
import '../../data/services/conversation_window_manager.dart' show TokenUsageInfo;
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

  /// 토큰 경고 스킵 후 쿨다운 카운터 (0이면 쿨다운 아님)
  /// 스킵할 때마다 tokenWarningCooldownMessages로 설정, 매 체크마다 1씩 감소
  int _tokenWarningCooldown = 0;

  /// 이번 대화에서 보여준 인터벌 광고 수 (대화 세션 동안 유지)
  int _shownAdCount = 0;

  @override
  ConversationalAdModel build() {
    // Provider dispose 시 광고 정리
    ref.onDispose(() {
      _nativeAd?.dispose();
      _rewardedAd?.dispose();
    });

    // 새 세션이면 카운터 리셋
    _tokenWarningCooldown = 0;
    _shownAdCount = 0;

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

    // 쿨다운 감소 (매 체크마다)
    if (_tokenWarningCooldown > 0) {
      _tokenWarningCooldown--;
    }

    // 광고 제거 구매 여부 체크
    final purchaseState = ref.read(purchaseNotifierProvider);
    final isAdFree = purchaseState.valueOrNull?.entitlements
            .all[PurchaseConfig.entitlementAdFree]?.isActive == true;

    // 트리거 체크 (쿨다운 상태 + 광고 카운터 + 광고제거 전달)
    final trigger = AdTriggerService.checkTrigger(
      tokenUsage: tokenUsage,
      messageCount: messageCount,
      tokenWarningOnCooldown: _tokenWarningCooldown > 0,
      shownAdCount: _shownAdCount,
      isAdFree: isAdFree,
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

    // 토큰 관련(소진/경고) → 보상형 광고 (높은 eCPM + 유저 동기 높음)
    // 인터벌 → 네이티브 광고 (자연스러운 노출)
    if (adType == AdMessageType.tokenDepleted ||
        adType == AdMessageType.tokenNearLimit) {
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
          // 로드 실패 시 광고 모드 자동 해제 → 다음 트리거에서 재시도 가능
          state = const ConversationalAdModel();
          if (kDebugMode) {
            print('   🔄 [AD] Load failed → ad mode auto-dismissed');
          }
        },
        onAdClicked: (ad) {
          if (kDebugMode) {
            print('   👆 [AD] Native ad clicked → token reward!');
          }
          // 클릭 시에만 광고 시청 완료 처리 (수익 극대화)
          // impression만으로는 토큰 미지급 → 클릭 유도
          _onAdClicked();
        },
        onAdImpression: (ad) {
          if (kDebugMode) {
            print('   👁️ [AD] Native ad impression → token reward');
          }
          // v26: 서버 추적 추가 (native_impressions 카운터 증가)
          AdTrackingService.instance.trackNativeImpression(
            screen: 'saju_chat_${state.adType?.name ?? 'unknown'}',
          );
          // v23: impression에서도 보상 (impressionRewardTokens)
          // 완전 무보상이면 사용자 불만 → impression만으로도 보상
          state = state.copyWith(
            adWatched: true,
            rewardedTokens: AdTriggerService.impressionRewardTokens,
          );
          // 광고 카운터 증가 (빈도 제어용)
          _shownAdCount++;
          if (kDebugMode) {
            print('   📊 [AD] shownAdCount: $_shownAdCount, impression reward: ${AdTriggerService.impressionRewardTokens} tokens');
          }
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
          // 로드 실패 시 광고 모드 자동 해제 → stuck 방지
          state = const ConversationalAdModel();
          if (kDebugMode) {
            print('   🔄 [AD] Rewarded load failed → ad mode auto-dismissed');
          }
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
      onUserEarnedReward: (ad, reward) async {
        if (kDebugMode) {
          print('   🎁 [AD] Reward earned: ${reward.amount} ${reward.type}');
        }

        // 광고 이벤트 추적 (ad_events 테이블에 purpose: token_bonus로 기록)
        await AdTrackingService.instance.trackRewarded(
          rewardAmount: reward.amount.toInt(),
          rewardType: reward.type,
          screen: 'saju_chat_${state.adType?.name ?? 'unknown'}',
          purpose: AdPurpose.tokenBonus,
        );

        _onRewardEarned();
      },
    );

    return completer.future;
  }

  /// 광고 클릭 처리 (Native 광고 클릭 시 추가 토큰 보상)
  ///
  /// impression(1,500) + 클릭 보너스(1,500) = 총 3,000 토큰
  /// CPC 수입 $0.15~0.50 vs 추가 비용 $0.002 → 클릭할수록 이득
  void _onAdClicked() {
    if (state.adType != AdMessageType.tokenDepleted) {
      // 클릭 보너스: impression 보상 위에 추가
      final clickBonus = AdTriggerService.impressionRewardTokens;
      state = state.copyWith(
        adWatched: true,
        rewardedTokens: (state.rewardedTokens ?? 0) + clickBonus,
      );

      // Supabase에 클릭 이벤트 추적 (수익 분석용)
      AdTrackingService.instance.trackNativeClick(
        screen: 'saju_chat_${state.adType?.name ?? 'unknown'}',
      );

      if (kDebugMode) {
        print('   💰 [AD] Native ad CLICKED → +$clickBonus bonus tokens (total: ${state.rewardedTokens})');
      }
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

    // 토큰 경고 광고를 스킵한 경우 쿨다운 설정
    // → 다음 N개 메시지 동안 토큰 경고 억제 → 인터벌 광고 기회
    // → 쿨다운 끝나면 다시 토큰 경고 발동 (계속 압박)
    if (state.adType == AdMessageType.tokenNearLimit) {
      _tokenWarningCooldown = AdTriggerService.tokenWarningCooldownMessages;
      if (kDebugMode) {
        print('   ⏭️ [AD] Token warning skipped → cooldown ${_tokenWarningCooldown} messages');
      }
    }

    dismissAd();
    return true;
  }
}
