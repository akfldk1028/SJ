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
import '../../data/services/ad_trigger_service.dart';
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

    // 토큰 소진 시 2가지 선택지 제공
    final isTokenDepleted = adState.adType == AdMessageType.tokenDepleted;
    // 보상형 광고: tokenDepleted (필수) + tokenNearLimit (스킵 가능)
    // 네이티브 광고: intervalAd (클릭 시 토큰)
    final isRewardedAd = isTokenDepleted ||
        adState.adType == AdMessageType.tokenNearLimit;
    final isRequired = isTokenDepleted;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. 토큰 소진 시 - 2개 버튼 선택 UI
        if (isTokenDepleted && !adState.adWatched)
          _buildTokenDepletedChoice(context, ref)
        // 2. 기타 광고 - 기존 전환 메시지
        else if (adState.transitionText != null && !adState.adWatched)
          AdTransitionBubble(
            message: isRewardedAd
                ? _createAdMessage(adState)
                : _createAdMessageWithoutCta(adState),
            personaEmoji: persona.emoji,
            personaName: persona.displayName,
            onCtaPressed: isRewardedAd ? () => _handleCtaPressed(ref) : null,
            onSkipPressed: !isRequired ? () => _handleSkip(ref) : null,
          ),

        const SizedBox(height: 8),

        // 3. 네이티브 광고 (인터벌 광고만 - 보상형은 전체화면 영상)
        if (!isRewardedAd &&
            (adState.loadState == AdLoadState.loaded ||
                adState.loadState == AdLoadState.loading))
          AdNativeBubble(
            nativeAd: ref.read(conversationalAdNotifierProvider.notifier).nativeAd,
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

  /// CTA 버튼 클릭 처리
  ///
  /// - tokenDepleted: 보상형 광고 표시
  /// - 그 외: 네이티브 광고 클릭을 유도하는 안내
  ///   (실제 토큰은 Native 광고 onAdClicked 콜백에서 지급)
  void _handleCtaPressed(WidgetRef ref) async {
    final notifier = ref.read(conversationalAdNotifierProvider.notifier);
    final adState = ref.read(conversationalAdNotifierProvider);

    // 토큰 소진 시 보상형 광고
    if (adState.adType == AdMessageType.tokenDepleted) {
      final success = await notifier.showRewardedAd();
      if (success) {
        notifier.onAdWatched();
      }
    }
    // Native 광고: CTA 버튼은 광고 영역으로 스크롤/주목 유도
    // 실제 토큰 보상은 광고 자체를 클릭해야 지급됨 (onAdClicked)
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

  /// 토큰 소진 시 2개 버튼 선택 UI
  Widget _buildTokenDepletedChoice(BuildContext context, WidgetRef ref) {
    final theme = context.appTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AI 메시지
          Row(
            children: [
              Text(
                persona.emoji,
                style: TextStyle(
                  fontSize: 16,
                  shadows: [
                    Shadow(
                      color: theme.primaryColor.withValues(alpha: 0.5),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                persona.displayName,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: theme.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // 메시지 버블
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: theme.isDark
                    ? [const Color(0xFF2A3540), const Color(0xFF1E2830)]
                    : [const Color(0xFFF8F9FA), const Color(0xFFF0F2F5)],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(18),
                bottomLeft: Radius.circular(18),
                bottomRight: Radius.circular(18),
              ),
              border: Border.all(
                color: theme.isDark
                    ? const Color(0xFFD4AF37).withValues(alpha: 0.2)
                    : const Color(0xFFD4AF37).withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              '대화가 즐거웠어요!\n토큰이 부족해서 잠시 쉬어야 할 것 같아요.',
              style: TextStyle(
                fontSize: 15,
                height: 1.6,
                color: theme.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // 2개 버튼
          Column(
            children: [
              // 영상 광고 버튼 (추천)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _handleVideoAdPressed(ref),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.play_circle_fill_rounded, size: 20),
                      SizedBox(width: 8),
                      Text(
                        '영상 보고 대화 계속하기',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              // 네이티브 광고 버튼
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => _handleNativeAdPressed(ref),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.textSecondary,
                    side: BorderSide(
                      color: theme.textSecondary.withValues(alpha: 0.15),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.article_outlined, size: 18, color: theme.textSecondary),
                      const SizedBox(width: 8),
                      Text(
                        '간단히 보고 조금 더 대화',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: theme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 영상 광고 선택 (1왕복 = 10,000 토큰)
  void _handleVideoAdPressed(WidgetRef ref) async {
    final notifier = ref.read(conversationalAdNotifierProvider.notifier);
    // 보상형 영상 광고 표시
    final success = await notifier.showRewardedAd(
      rewardTokens: AdTriggerService.depletedRewardTokensVideo,
    );
    if (success) {
      notifier.onAdWatched(rewardTokens: AdTriggerService.depletedRewardTokensVideo);
    }
  }

  /// 네이티브 광고 선택 (0.3왕복 = 3,000 토큰)
  void _handleNativeAdPressed(WidgetRef ref) async {
    final notifier = ref.read(conversationalAdNotifierProvider.notifier);
    // 네이티브 광고 로드 및 표시
    await notifier.loadNativeAd();
    notifier.onAdWatched(rewardTokens: AdTriggerService.depletedRewardTokensNative);
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
                  '후원자 소개',
                  style: TextStyle(
                    fontSize: 10,
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
