/// 대화형 광고 통합 위젯
///
/// 광고 전환 메시지 + 네이티브 광고를 통합 표시
/// Provider와 연동하여 상태 기반 UI 렌더링
/// 위젯 트리 최적화: Consumer로 선택적 리빌드
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/models/conversational_ad_model.dart';
import '../../domain/models/ai_persona.dart';
import '../providers/conversational_ad_provider.dart';
import '../providers/chat_provider.dart';
import 'ad_native_bubble.dart';
import 'ad_transition_bubble.dart';
import '../../domain/entities/ad_chat_message.dart';
import '../../domain/entities/chat_message.dart';

/// 대화형 광고 통합 위젯
///
/// 사용 예:
/// ```dart
/// ConversationalAdWidget(
///   persona: currentPersona,
///   sessionId: sessionId,
///   onAdComplete: () => resumeChat(),
/// )
/// ```
class ConversationalAdWidget extends ConsumerWidget {
  /// 현재 AI 페르소나
  final AiPersona persona;

  /// 세션 ID
  final String sessionId;

  /// 광고 완료 콜백 (대화 재개)
  final VoidCallback? onAdComplete;

  const ConversationalAdWidget({
    super.key,
    required this.persona,
    required this.sessionId,
    this.onAdComplete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 광고 상태 구독 (선택적 리빌드)
    final adState = ref.watch(conversationalAdNotifierProvider);

    // 광고 모드가 아니면 표시하지 않음
    if (!adState.isAdMode) {
      return const SizedBox.shrink();
    }

    // 보상형 광고: tokenDepleted (필수) + tokenNearLimit (스킵 가능)
    // 네이티브 광고: intervalAd (클릭 시 토큰)
    // 네이티브 선택: tokenDepleted에서 "광고 보고 3번 대화" 선택 시
    final isTokenDepleted = adState.adType == AdMessageType.tokenDepleted;
    final isRewardedAd = isTokenDepleted ||
        adState.adType == AdMessageType.tokenNearLimit;
    final isRequired = isTokenDepleted;

    // 참고: tokenDepleted에서 유저가 "네이티브 광고" 선택 시
    // _handleNativeAdPressed()에서 adType을 inlineInterval로 전환
    // → isRewardedAd = false로 변경되어 네이티브 광고 위젯이 표시됨

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. 페르소나 전환 메시지
        if (adState.transitionText != null && !adState.adWatched)
          AdTransitionBubble(
            message: isRequired
                ? _createTokenDepletedMessage(adState) // 2버튼용 CTA 텍스트
                : isRewardedAd
                    ? _createAdMessage(adState)
                    : _createAdMessageWithoutCta(adState),
            personaEmoji: persona.emoji,
            personaName: persona.displayName,
            // v3: tokenDepleted CTA는 TokenDepletedBanner에서 처리 (전면 광고)
            onCtaPressed: isRewardedAd && !isRequired
                ? () => _handleRewardedCtaPressed(ref)
                : null,
            onSkipPressed: !isRequired ? () => _handleSkip(ref) : null,
            // v3: 네이티브 CTA 제거 (전면 광고로 전환됨)
            secondaryCtaText: null,
            onSecondaryCtaPressed: null,
          ),

        const SizedBox(height: 8),

        // 3. 네이티브 광고 (인터벌 또는 tokenDepleted→네이티브 선택 후)
        if (!isRewardedAd &&
            (adState.loadState == AdLoadState.loaded ||
                adState.loadState == AdLoadState.loading))
          AdNativeBubble(
            nativeAd: ref.read(conversationalAdNotifierProvider.notifier).nativeAd,
            adWidget: ref.read(conversationalAdNotifierProvider.notifier).adFitNativeWidget,
            loadState: adState.loadState,
            onDismiss: adState.adWatched ? () => _handleAdComplete(ref) : null,
            personaEmoji: '📢',
          ),

        // 4. 광고 시청 완료 시 대화 재개 버튼
        if (adState.adWatched) ...[
          const SizedBox(height: 12),
          _buildResumeButton(context, ref),
        ],
      ],
    );
  }

  /// 광고 메시지 생성
  AdChatMessage _createAdMessage(ConversationalAdModel adState) {
    return AdChatMessage(
      id: 'ad_${DateTime.now().millisecondsSinceEpoch}',
      sessionId: sessionId,
      content: adState.transitionText ?? '',
      role: MessageRole.assistant,
      createdAt: DateTime.now(),
      adType: adState.adType ?? AdMessageType.inlineInterval,
      transitionText: adState.transitionText,
      ctaText: adState.ctaText,
      rewardTokens: adState.rewardedTokens,
    );
  }

  /// Native 광고용 메시지 (CTA 텍스트를 전환 문구에 합침)
  ///
  /// CTA 버튼 대신 전환 메시지 안에 "광고를 누르시면..." 안내를 포함
  /// → 유저가 네이티브 광고 자체를 클릭하도록 유도
  AdChatMessage _createAdMessageWithoutCta(ConversationalAdModel adState) {
    final combinedText = [
      adState.transitionText ?? '',
      if (adState.ctaText != null && adState.ctaText!.isNotEmpty)
        '\n${adState.ctaText}',
    ].join();

    return AdChatMessage(
      id: 'ad_${DateTime.now().millisecondsSinceEpoch}',
      sessionId: sessionId,
      content: combinedText,
      role: MessageRole.assistant,
      createdAt: DateTime.now(),
      adType: adState.adType ?? AdMessageType.inlineInterval,
      transitionText: combinedText,
      ctaText: null, // CTA 버튼 표시하지 않음
      rewardTokens: adState.rewardedTokens,
    );
  }

  /// 토큰 소진 시 메시지 생성 (전환 텍스트만, CTA는 TokenDepletedBanner에서 처리)
  AdChatMessage _createTokenDepletedMessage(ConversationalAdModel adState) {
    return AdChatMessage(
      id: 'ad_${DateTime.now().millisecondsSinceEpoch}',
      sessionId: sessionId,
      content: adState.transitionText ?? '',
      role: MessageRole.assistant,
      createdAt: DateTime.now(),
      adType: AdMessageType.tokenDepleted,
      transitionText: adState.transitionText,
      ctaText: null, // CTA는 TokenDepletedBanner에서 처리
      rewardTokens: null,
    );
  }

  /// 보상형 광고 CTA (tokenNearLimit용 - 현재 비활성화)
  void _handleRewardedCtaPressed(WidgetRef ref) async {
    final notifier = ref.read(conversationalAdNotifierProvider.notifier);
    final success = await notifier.showRewardedAd();
    if (success) {
      notifier.onAdWatched();
    }
  }

  /// 스킵 처리
  void _handleSkip(WidgetRef ref) {
    final notifier = ref.read(conversationalAdNotifierProvider.notifier);
    notifier.skipAd();
    onAdComplete?.call();
  }

  /// 광고 완료 처리
  ///
  /// Rewarded 광고를 끝까지 봤을 때만 토큰 충전
  /// (adWatched: true이고 rewardedTokens가 있는 경우)
  ///
  /// v27: 서버 저장은 provider에서 즉시 처리됨
  /// - Rewarded ad: trackRewarded() → rewarded_tokens_earned
  /// - Native ad: _saveNativeBonusToServer() → native_tokens_earned
  /// 여기서는 client-side(ConversationWindowManager) 보너스만 추가
  /// → isRewardedAd: true로 고정하여 RPC 중복 호출 방지
  void _handleAdComplete(WidgetRef ref) {
    final adState = ref.read(conversationalAdNotifierProvider);
    final adNotifier = ref.read(conversationalAdNotifierProvider.notifier);

    // 광고를 끝까지 봤으면 클라이언트 측 토큰 충전
    if (adState.adWatched &&
        adState.rewardedTokens != null &&
        adState.rewardedTokens! > 0) {
      // isRewardedAd: true → 서버 RPC 스킵 (provider에서 이미 저장됨)
      ref.read(chatNotifierProvider(sessionId).notifier)
          .addBonusTokens(adState.rewardedTokens!, isRewardedAd: true);
    }

    adNotifier.dismissAd();
    onAdComplete?.call();
  }

  /// 대화 재개 버튼
  Widget _buildResumeButton(BuildContext context, WidgetRef ref) {
    final theme = context.appTheme;
    final adState = ref.watch(conversationalAdNotifierProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ElevatedButton.icon(
        onPressed: () => _handleAdComplete(ref),
        icon: const Icon(Icons.chat_bubble_outline, size: 18),
        label: Text(
          adState.rewardedTokens != null && adState.rewardedTokens! > 0
              ? '대화 재개 (+${adState.rewardedTokens} 토큰 획득!)'
              : '대화 재개하기',
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

/// 인라인 광고 삽입 위젯 (메시지 리스트용)
///
/// 메시지 사이에 자연스럽게 삽입되는 간단한 광고
class InlineAdWidget extends StatelessWidget {
  final int index;

  const InlineAdWidget({super.key, required this.index});

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardColor.withValues(alpha:0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFD4AF37).withValues(alpha:0.15),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFFD4AF37).withValues(alpha:0.1),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text('💫', style: TextStyle(fontSize: 14)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '광고',
                  style: TextStyle(
                    fontSize: 15,
                    color: theme.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '관심 있으신 정보가 있을지도 몰라요',
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios,
            size: 14,
            color: theme.textSecondary,
          ),
        ],
      ),
    );
  }
}
