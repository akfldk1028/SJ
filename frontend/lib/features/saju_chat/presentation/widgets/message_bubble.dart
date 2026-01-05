import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../../../../core/theme/app_fonts.dart';
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
            _buildAvatar(theme),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: isUser
                    ? theme.colorScheme.primary
                    : theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
              ),
              child: _buildMessageContent(theme, isUser),
            ),
          ),
          if (isUser && showAvatar) ...[
            const SizedBox(width: 8),
            _buildAvatar(theme),
          ],
        ],
      ),
    );
  }

  /// 메시지 내용 빌드
  ///
  /// AI 메시지: Markdown 렌더링 + Gowun Dodum 폰트
  /// 사용자 메시지: Noto Sans KR (깔끔한 산세리프)
  Widget _buildMessageContent(ThemeData theme, bool isUser) {
    // 사용자 메시지: Noto Sans KR (plain text)
    if (isUser) {
      final userStyle = AppFonts.userMessage(
        color: theme.colorScheme.onPrimary,
      );
      return Text(message.content, style: userStyle);
    }

    // AI 메시지: Markdown 렌더링
    final aiStyle = AppFonts.aiMessage(
      color: theme.colorScheme.onSurface,
    );

    return MarkdownBody(
      data: message.content,
      selectable: true,
      styleSheet: MarkdownStyleSheet(
        p: aiStyle,
        strong: aiStyle.copyWith(fontWeight: FontWeight.bold),
        em: aiStyle.copyWith(fontStyle: FontStyle.italic),
        code: aiStyle.copyWith(
          fontFamily: 'monospace',
          backgroundColor: theme.colorScheme.surfaceContainerHighest,
        ),
        listBullet: aiStyle,
        a: aiStyle.copyWith(
          color: theme.colorScheme.primary,
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }

  Widget _buildAvatar(ThemeData theme) {
    return CircleAvatar(
      radius: 16,
      backgroundColor: message.isUser
          ? theme.colorScheme.primaryContainer
          : theme.colorScheme.secondaryContainer,
      child: Icon(
        message.isUser ? Icons.person : Icons.auto_awesome,
        size: 18,
        color: message.isUser
            ? theme.colorScheme.onPrimaryContainer
            : theme.colorScheme.onSecondaryContainer,
      ),
    );
  }
}
