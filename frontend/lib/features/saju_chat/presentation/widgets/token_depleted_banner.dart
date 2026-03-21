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
import '../../../../ad/ad_tracking_service.dart';
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
                  onPressed: () => _handleRewardedAndContinue(context, ref),
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

  /// 보상형 광고 → 광고 완료 후 서버 + 클라이언트 토큰 충전
  ///
  /// AdService 어댑터 패턴 사용 (AdMob 1순위 → Unity 2순위 fallback)
  /// stale ref 방지: async gap 전에 notifier 캡처
  void _handleRewardedAndContinue(BuildContext context, WidgetRef ref) async {
    final adNotifier = ref.read(conversationalAdNotifierProvider.notifier);
    final chatNotifier = ref.read(chatNotifierProvider(sessionId).notifier);

    const tokens = AdStrategy.depletedRewardTokensVideo;

    // 보상형 광고 로드 대기 (AdMob → Unity 어댑터 fallback)
    await AdService.instance.waitForRewardedLoad();
    final shown = await AdService.instance.showRewardedAd(
      screen: 'token_depleted_rewarded',
      purpose: AdPurpose.tokenBonus,
      onRewarded: (amount, type) async {
        // 보상 획득 → 서버 + 클라이언트 토큰 지급
        await TokenRewardService.grantRewardedAdTokens(
          tokens,
          screen: 'token_depleted_rewarded',
        );
        chatNotifier.addBonusTokens(tokens, isRewardedAd: true);
        debugPrint('[TokenDepletedBanner] 보상형 광고 완료 → +$tokens tokens (서버+클라이언트)');
      },
    );

    if (!shown) {
      // 보상형 광고 로드 실패 (AdMob + Unity 모두) → fallback 소량 토큰 지급
      const fallbackTokens = AdStrategy.depletedFallbackTokens;
      await TokenRewardService.grantRewardedAdTokens(
        fallbackTokens,
        screen: 'token_depleted_fallback',
        isFallback: true,
      );
      chatNotifier.addBonusTokens(fallbackTokens, isRewardedAd: false);
      AdService.instance.loadRewardedAd();
      debugPrint('[TokenDepletedBanner] 보상형 광고 실패 → fallback +$fallbackTokens tokens');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('saju_chat.adLoadFailMessage'.tr()),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }

    // 광고 모드 종료
    adNotifier.dismissAd();
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
