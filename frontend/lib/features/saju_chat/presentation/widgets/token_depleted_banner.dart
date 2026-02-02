/// 토큰 소진 시 광고 배너 (ChatInputField 바로 위)
///
/// v2: 클릭 광고만 사용 (영상 제거)
/// - 광고 보고 2번 더 대화하기 (Native Ad → 채팅창 안에 표시)
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/models/conversational_ad_model.dart';
import '../../data/services/ad_trigger_service.dart';
import '../providers/conversational_ad_provider.dart';
import '../providers/chat_provider.dart';

/// 토큰 소진 시 광고 배너
///
/// v2: 클릭 광고만 사용 (영상 제거)
/// tokenDepleted 상태에서만 버튼 1개 표시.
/// 네이티브 광고는 채팅 메시지 리스트 안에 trailingWidget으로 표시됨.
class TokenDepletedBanner extends ConsumerWidget {
  final String sessionId;

  const TokenDepletedBanner({super.key, required this.sessionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adState = ref.watch(conversationalAdNotifierProvider);

    // tokenDepleted: 광고 배너 표시
    // 나머지 상태(inlineInterval, adWatched)는 채팅 리스트 안에서 처리
    if (!adState.isAdMode || adState.adType != AdMessageType.tokenDepleted) {
      return const SizedBox.shrink();
    }

    return _buildAdBanner(context, ref);
  }

  /// 광고 배너 (클릭 광고만)
  Widget _buildAdBanner(BuildContext context, WidgetRef ref) {
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
          // 클릭 광고 버튼 (1개만)
          SizedBox(
            width: double.infinity,
            child: AdChoiceButton(
              label: '📋 광고 보고 2번 더 대화하기',
              isPrimary: true,
              onPressed: () => _handleNativeAd(ref),
            ),
          ),
        ],
      ),
    );
  }

  /// 네이티브 광고 선택 → 채팅 리스트 안에 광고 표시 (15,000 토큰)
  void _handleNativeAd(WidgetRef ref) {
    final notifier = ref.read(conversationalAdNotifierProvider.notifier);
    notifier.switchToNativeAd(
      rewardTokens: AdTriggerService.depletedRewardTokensNative,
    );
  }

  /// 광고 완료 → 토큰 충전 + 광고 모드 해제
  void _handleAdComplete(WidgetRef ref) {
    final adState = ref.read(conversationalAdNotifierProvider);
    final adNotifier = ref.read(conversationalAdNotifierProvider.notifier);

    // 광고를 끝까지 봤으면 클라이언트 측 토큰 충전
    if (adState.adWatched &&
        adState.rewardedTokens != null &&
        adState.rewardedTokens! > 0) {
      ref.read(chatNotifierProvider(sessionId).notifier)
          .addBonusTokens(adState.rewardedTokens!, isRewardedAd: true);
    }

    adNotifier.dismissAd();
  }
}

/// 광고 버튼
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
