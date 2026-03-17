/// 광고 전환 버블 위젯
///
/// AI 페르소나가 자연스럽게 광고로 전환하는 메시지 버블
/// 위젯 트리 최적화: const 생성자, 100줄 이하, 단일 책임
library;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/ad_chat_message.dart';

/// 광고 전환 버블
///
/// 사용 예:
/// ```dart
/// AdTransitionBubble(
///   message: adChatMessage,
///   personaEmoji: '🎭',
///   personaName: '도령',
///   onCtaPressed: () => showRewardedAd(),
/// )
/// ```
class AdTransitionBubble extends StatelessWidget {
  final AdChatMessage message;
  final String personaEmoji;
  final String personaName;
  final VoidCallback? onCtaPressed;
  final VoidCallback? onSkipPressed;

  /// 보조 CTA (토큰 소진 시 2가지 선택지)
  final String? secondaryCtaText;
  final VoidCallback? onSecondaryCtaPressed;

  const AdTransitionBubble({
    super.key,
    required this.message,
    this.personaEmoji = '🌙',
    this.personaName = '사담 AI',
    this.onCtaPressed,
    this.onSkipPressed,
    this.secondaryCtaText,
    this.onSecondaryCtaPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 페르소나 아바타 + 이름
          _buildPersonaHeader(theme),
          const SizedBox(height: 8),
          // 전환 메시지 버블
          _buildTransitionBubble(context, theme),
          // CTA 버튼 (필수 광고일 경우)
          if (message.ctaText != null && message.ctaText!.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildCtaSection(context, theme),
          ],
        ],
      ),
    );
  }

  Widget _buildPersonaHeader(AppThemeExtension theme) {
    return Row(
      children: [
        Text(
          personaEmoji,
          style: TextStyle(
            fontSize: 16,
            shadows: [
              Shadow(
                color: theme.primaryColor.withValues(alpha:0.5),
                blurRadius: 8,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          personaName,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: theme.primaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildTransitionBubble(BuildContext context, AppThemeExtension theme) {
    final transitionText = message.transitionText ?? message.content;

    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.8,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: theme.isDark
              ? [
                  const Color(0xFF2A3540),
                  const Color(0xFF1E2830),
                ]
              : [
                  const Color(0xFFF8F9FA),
                  const Color(0xFFF0F2F5),
                ],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(4),
          topRight: Radius.circular(18),
          bottomLeft: Radius.circular(18),
          bottomRight: Radius.circular(18),
        ),
        border: Border.all(
          color: theme.isDark
              ? const Color(0xFFD4AF37).withValues(alpha:0.2) // 금색 테두리 (광고 강조)
              : const Color(0xFFD4AF37).withValues(alpha:0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD4AF37).withValues(alpha:0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        transitionText,
        style: AppFonts.aiMessage(
          color: theme.textPrimary,
        ).copyWith(height: 1.6),
      ),
    );
  }

  Widget _buildCtaSection(BuildContext context, AppThemeExtension theme) {
    final isRequired = message.isRequired;

    // 2가지 선택지 (토큰 소진 시)
    if (secondaryCtaText != null && onSecondaryCtaPressed != null) {
      return Column(
        children: [
          // 메인 CTA (영상 광고)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onCtaPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD4AF37),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              child: Text(
                message.ctaText!,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // 보조 CTA (네이티브 광고)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onSecondaryCtaPressed,
              style: OutlinedButton.styleFrom(
                foregroundColor: theme.textSecondary,
                side: BorderSide(
                  color: theme.textSecondary.withValues(alpha: 0.3),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                secondaryCtaText!,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      );
    }

    // 기존 단일 CTA
    return Row(
      children: [
        const SizedBox(width: 4),
        // CTA 버튼
        Expanded(
          child: ElevatedButton(
            onPressed: onCtaPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD4AF37), // 금색
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (message.rewardTokens != null && message.rewardTokens! > 0) ...[
                  const Icon(Icons.card_giftcard, size: 18),
                  const SizedBox(width: 6),
                ],
                Text(
                  message.ctaText!,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                if (message.rewardTokens != null && message.rewardTokens! > 0) ...[
                  const SizedBox(width: 6),
                  Text(
                    '+${message.rewardTokens}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        // 스킵 버튼 (선택적 광고만)
        if (!isRequired && onSkipPressed != null) ...[
          const SizedBox(width: 8),
          TextButton(
            onPressed: onSkipPressed,
            style: TextButton.styleFrom(
              foregroundColor: theme.textSecondary,
            ),
            child: Text('saju_chat.skipAd'.tr()),
          ),
        ],
      ],
    );
  }
}
