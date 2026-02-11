/// 토큰 소진 시 2버튼 배너 (ChatInputField 바로 위)
///
/// 청운도사 페르소나 헤더/전환 메시지 없이 깔끔한 2버튼만 표시.
/// - 영상 보고 5번 대화 (Rewarded Video)
/// - 광고 보고 3번 대화 (Native Ad → 채팅창 안에 표시)
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../ad/ad_config.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../router/routes.dart';
import '../../data/models/conversational_ad_model.dart';
import '../../data/services/ad_trigger_service.dart';
import '../providers/conversational_ad_provider.dart';
// import '../providers/chat_provider.dart'; // 영상 광고 활성화 시 복원

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
            '토큰이 소진되었어요. 현재 광고 서비스 점검 중이에요',
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
              label: '✨ 광고 없이 이용하기',
              isPrimary: true,
              onPressed: () => context.push(Routes.settingsPremium),
            ),
          ),
        ],
      ),
    );
  }

  /// 2버튼 배너 (영상 광고 / 네이티브 광고)
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
            '토큰이 소진되었어요! 광고를 보면 대화를 계속할 수 있어요',
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
          // 2버튼 행 (광고 + 구매)
          Row(
            children: [
              // 네이티브 광고 버튼
              Expanded(
                child: AdChoiceButton(
                  label: '📋 바로 대화 계속하기',
                  isPrimary: false,
                  onPressed: () => _handleNativeAd(ref),
                ),
              ),
              const SizedBox(width: 10),
              // 프리미엄 구매 버튼
              Expanded(
                child: AdChoiceButton(
                  label: '✨ 광고 없이 이용하기',
                  isPrimary: true,
                  onPressed: () => context.push(Routes.settingsPremium),
                ),
              ),
              // // 영상 광고 버튼 (추후 활성화)
              // const SizedBox(width: 10),
              // Expanded(
              //   child: AdChoiceButton(
              //     label: '🎬 영상 보고 5번 대화',
              //     isPrimary: false,
              //     onPressed: () => _handleVideoAd(ref),
              //   ),
              // ),
            ],
          ),
        ],
      ),
    );
  }

  // /// 영상 광고 선택 (Rewarded Video → 5번 대화) - 추후 활성화
  // void _handleVideoAd(WidgetRef ref) async {
  //   final notifier = ref.read(conversationalAdNotifierProvider.notifier);
  //   final success = await notifier.showRewardedAd(
  //     rewardTokens: AdTriggerService.depletedRewardTokensVideo,
  //   );
  //   if (success) {
  //     notifier.onAdWatched(
  //       rewardTokens: AdTriggerService.depletedRewardTokensVideo,
  //     );
  //     _handleAdComplete(ref);
  //   }
  // }

  /// 네이티브 광고 선택 → 채팅 리스트 안에 광고 표시
  void _handleNativeAd(WidgetRef ref) {
    final notifier = ref.read(conversationalAdNotifierProvider.notifier);
    notifier.switchToNativeAd(
      rewardTokens: AdTriggerService.depletedRewardTokensNative,
    );
  }

  // /// 광고 완료 → 토큰 충전 + 광고 모드 해제 - 추후 영상 광고 활성화 시 사용
  // void _handleAdComplete(WidgetRef ref) {
  //   final adState = ref.read(conversationalAdNotifierProvider);
  //   final adNotifier = ref.read(conversationalAdNotifierProvider.notifier);
  //   if (adState.adWatched &&
  //       adState.rewardedTokens != null &&
  //       adState.rewardedTokens! > 0) {
  //     ref.read(chatNotifierProvider(sessionId).notifier)
  //         .addBonusTokens(adState.rewardedTokens!, isRewardedAd: true);
  //   }
  //   adNotifier.dismissAd();
  // }
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
