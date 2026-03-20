/// 토큰 소진 시 2버튼 배너 (ChatInputField 바로 위)
///
/// 깔끔한 2버튼만 표시:
/// - ▶ 계속하기 (전면 광고 5초 → 토큰 20K 충전)
/// - ✨ 프리미엄 (구매 페이지)
library;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../ad/ad_config.dart';
import '../../../../ad/ad_service.dart';
import '../../../../ad/ad_strategy.dart';
import '../../../../ad/token_reward_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../router/routes.dart';
import '../../data/models/conversational_ad_model.dart';
import '../providers/chat_provider.dart';
import '../providers/conversational_ad_provider.dart';

/// 토큰 소진 시 2버튼 배너
///
/// tokenDepleted 상태에서만 2버튼을 표시.
/// 네이티브 광고는 채팅 메시지 리스트 안에 trailingWidget으로 표시됨.
class TokenDepletedBanner extends ConsumerWidget {
  final String sessionId;

  const TokenDepletedBanner({super.key, required this.sessionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adState = ref.watch(conversationalAdNotifierProvider);

    // tokenDepleted: 2버튼 배너만 표시
    // 나머지 상태(inlineInterval, adWatched)는 채팅 리스트 안에서 처리
    if (!adState.isAdMode || adState.adType != AdMessageType.tokenDepleted) {
      return const SizedBox.shrink();
    }

    // 광고 킬스위치 OFF → 광고 버튼 없이 안내 + 프리미엄만
    if (!adEnabled) {
      return _buildAdDisabledBanner(context);
    }

    return _buildTwoButtonBanner(context, ref);
  }

  /// 광고 비활성화 시 배너 (프리미엄 구매만 안내)
  Widget _buildAdDisabledBanner(BuildContext context) {
    final appTheme = context.appTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: appTheme.isDark
            ? const Color(0xFF2D3A4A)
            : const Color(0xFFFFF8E1),
        border: Border(
          top: BorderSide(
            color: appTheme.isDark
                ? const Color(0xFFD4AF37).withValues(alpha: 0.3)
                : const Color(0xFFFFB300),
            width: 1,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'saju_chat.tokenDepletedAdMaintenance'.tr(),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: appTheme.isDark
                  ? const Color(0xFFE0E0E0)
                  : const Color(0xFF5D4037),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: AdChoiceButton(
              label: 'saju_chat.adFreeLabel'.tr(),
              isPrimary: true,
              onPressed: () => context.push(Routes.settingsPremium),
            ),
          ),
        ],
      ),
    );
  }

  /// 2버튼 배너 (전면 광고 + 프리미엄)
  Widget _buildTwoButtonBanner(BuildContext context, WidgetRef ref) {
    final appTheme = context.appTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: appTheme.isDark
            ? const Color(0xFF2D3A4A)
            : const Color(0xFFFFF8E1),
        border: Border(
          top: BorderSide(
            color: appTheme.isDark
                ? const Color(0xFFD4AF37).withValues(alpha: 0.3)
                : const Color(0xFFFFB300),
            width: 1,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 안내 텍스트
          Text(
            'saju_chat.tokenDepleted'.tr(),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: appTheme.isDark
                  ? const Color(0xFFE0E0E0)
                  : const Color(0xFF5D4037),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          // 2버튼 행 (전면 광고 + 프리미엄)
          Row(
            children: [
              // 전면 광고 → 토큰 충전
              Expanded(
                child: AdChoiceButton(
                  label: 'saju_chat.continueLabel'.tr(),
                  isPrimary: false,
                  onPressed: () => _handleInterstitialAndContinue(context, ref),
                ),
              ),
              const SizedBox(width: 10),
              // 프리미엄 구매 버튼
              Expanded(
                child: AdChoiceButton(
                  label: 'saju_chat.premiumLabel'.tr(),
                  isPrimary: true,
                  onPressed: () => context.push(Routes.settingsPremium),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 전면 광고 5초 → 광고 닫힌 후 서버 + 클라이언트 토큰 충전
  ///
  /// 더블탭 방지: adNotifier.setLoading()으로 즉시 상태 변경 → 배너 UI 비활성화
  /// stale ref 방지: async gap 전에 notifier 캡처
  void _handleInterstitialAndContinue(BuildContext context, WidgetRef ref) async {
    final adNotifier = ref.read(conversationalAdNotifierProvider.notifier);
    final chatNotifier = ref.read(chatNotifierProvider(sessionId).notifier);

    // 더블탭 방지: 즉시 광고 로딩 상태로 전환 → 버튼 재탭 차단
    adNotifier.dismissAd();

    // 전면 광고 로드 대기 (최대 5초) → 표시
    // bypassInterval: true → 토큰 소진은 필수 광고이므로 쿨다운 무시
    await AdService.instance.waitForInterstitialLoad();
    final shown = await AdService.instance.showInterstitialAd(
      bypassInterval: true,
      onDismissed: () async {
        // 광고가 닫힌 후에만 실행 (크래시 방지)
        const tokens = AdStrategy.depletedRewardTokensVideo;
        // 서버 측 토큰 지급
        await TokenRewardService.grantRewardedAdTokens(
          tokens,
          screen: 'token_depleted_interstitial',
        );
        // 클라이언트 측 토큰 업데이트 (ConversationWindowManager)
        chatNotifier.addBonusTokens(tokens, isRewardedAd: true);
        debugPrint('[TokenDepletedBanner] 전면 광고 완료 → +$tokens tokens (서버+클라이언트)');
      },
    );

    if (!shown) {
      // 전면 광고 로드 안 됨 → fallback 소량 토큰 지급 (ads_watched 미증가)
      const fallbackTokens = AdStrategy.depletedFallbackTokens;
      await TokenRewardService.grantRewardedAdTokens(
        fallbackTokens,
        screen: 'token_depleted_fallback',
        isFallback: true,
      );
      chatNotifier.addBonusTokens(fallbackTokens, isRewardedAd: false);
      // 다음을 위해 전면 광고 재로드
      AdService.instance.loadInterstitialAd();
      debugPrint('[TokenDepletedBanner] 광고 로드 실패 → fallback +$fallbackTokens tokens');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('saju_chat.adLoadFailMessage'.tr()),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}

/// 광고 선택 버튼 (2버튼 배너용)
class AdChoiceButton extends StatelessWidget {
  final String label;
  final bool isPrimary;
  final VoidCallback onPressed;

  const AdChoiceButton({
    super.key,
    required this.label,
    required this.isPrimary,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final appTheme = context.appTheme;

    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: isPrimary
            ? (appTheme.isDark ? const Color(0xFFD4AF37) : const Color(0xFFFF8F00))
            : (appTheme.isDark ? const Color(0xFF37474F) : const Color(0xFFEEEEEE)),
        foregroundColor: isPrimary
            ? Colors.white
            : (appTheme.isDark ? const Color(0xFFE0E0E0) : const Color(0xFF424242)),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: isPrimary ? 2 : 0,
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
