import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../router/routes.dart';

/// AI 대화하기 CTA 카드 - 메뉴 화면에서 채팅으로 유도
class AiChatCtaCard extends StatelessWidget {
  const AiChatCtaCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    final horizontalPadding = context.horizontalPadding;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: GestureDetector(
        onTap: () => context.push(Routes.sajuChat),
        child: Container(
          padding: EdgeInsets.all(context.scaledPadding(16)),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.primaryColor.withValues(alpha: 0.15),
                theme.primaryColor.withValues(alpha: 0.08),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.primaryColor.withValues(alpha: 0.2),
            ),
            boxShadow: [
              BoxShadow(
                color: theme.primaryColor.withValues(alpha: 0.1),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // 아이콘 원형 배경
              Container(
                width: context.scaledSize(44),
                height: context.scaledSize(44),
                decoration: BoxDecoration(
                  color: theme.primaryColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.chat_bubble_outline_rounded,
                  color: theme.primaryColor,
                  size: context.scaledIcon(22),
                ),
              ),
              SizedBox(width: context.scaledPadding(12)),
              // 텍스트 영역
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'menu.askAI'.tr(),
                      style: TextStyle(
                        fontSize: context.scaledFont(15),
                        fontWeight: FontWeight.w600,
                        color: theme.textPrimary,
                      ),
                    ),
                    SizedBox(height: context.scaledPadding(2)),
                    Text(
                      'menu.askAIDesc'.tr(),
                      style: TextStyle(
                        fontSize: context.scaledFont(12),
                        color: theme.textMuted,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              SizedBox(width: context.scaledPadding(8)),
              // 화살표 아이콘
              Icon(
                Icons.chevron_right_rounded,
                color: theme.primaryColor.withValues(alpha: 0.6),
                size: context.scaledIcon(24),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
