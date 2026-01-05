import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/chat_message.dart';

/// 채팅 메시지 버블 위젯
///
/// 위젯 트리 최적화:
/// - const 생성자 사용
/// - 단일 책임 (메시지 표시만)
/// - 100줄 이하 유지
class MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool showAvatar;

  const MessageBubble({
    super.key,
    required this.message,
    this.showAvatar = true,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final theme = Theme.of(context);
    final appTheme = context.appTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 4,
      ),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser && showAvatar) ...[
            _buildAvatar(theme, appTheme),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                gradient: _getBubbleGradient(isUser, appTheme),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: _getShadowColor(isUser, appTheme),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                message.content,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: _getTextColor(isUser, appTheme),
                ),
              ),
            ),
          ),
          if (isUser && showAvatar) ...[
            const SizedBox(width: 8),
            _buildAvatar(theme, appTheme),
          ],
        ],
      ),
    );
  }

  LinearGradient _getBubbleGradient(bool isUser, AppThemeExtension appTheme) {
    if (isUser) {
      // 사용자 버블: 골드/테라코타 계열
      return LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: appTheme.isDark
            ? [const Color(0xFFD4A54A), const Color(0xFFB8894A)] // 밝은 골드
            : [const Color(0xFFD4846A), const Color(0xFFC27256)], // 테라코타
      );
    } else {
      // AI 버블: 다크 틸/쿨 그레이 계열
      return LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: appTheme.isDark
            ? [const Color(0xFF2A3540), const Color(0xFF1E2830)] // 틸 다크
            : [const Color(0xFFF5F5F5), const Color(0xFFEBEBEB)], // 쿨 그레이
      );
    }
  }

  Color _getShadowColor(bool isUser, AppThemeExtension appTheme) {
    if (isUser) {
      return appTheme.isDark
          ? const Color(0xFFD4A54A).withOpacity(0.3)
          : const Color(0xFFD4846A).withOpacity(0.25);
    } else {
      return appTheme.isDark
          ? Colors.black.withOpacity(0.3)
          : Colors.grey.withOpacity(0.15);
    }
  }

  Color _getTextColor(bool isUser, AppThemeExtension appTheme) {
    if (isUser) {
      return Colors.white;
    } else {
      return appTheme.isDark
          ? const Color(0xFFE8E8E8)
          : const Color(0xFF2D2D2D);
    }
  }

  Widget _buildAvatar(ThemeData theme, AppThemeExtension appTheme) {
    final isUserMessage = message.isUser;

    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isUserMessage
              ? (appTheme.isDark
                  ? [const Color(0xFFD4A54A), const Color(0xFFB8894A)]
                  : [const Color(0xFFD4846A), const Color(0xFFC27256)])
              : (appTheme.isDark
                  ? [const Color(0xFF4A6572), const Color(0xFF344955)]
                  : [const Color(0xFF78909C), const Color(0xFF607D8B)]),
        ),
        boxShadow: [
          BoxShadow(
            color: isUserMessage
                ? (appTheme.isDark
                    ? const Color(0xFFD4A54A).withOpacity(0.3)
                    : const Color(0xFFD4846A).withOpacity(0.25))
                : Colors.black.withOpacity(0.15),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(
        isUserMessage ? Icons.person : Icons.auto_awesome,
        size: 18,
        color: Colors.white,
      ),
    );
  }
}
