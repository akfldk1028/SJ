import 'package:shadcn_flutter/shadcn_flutter.dart';

import '../../domain/entities/chat_message.dart';

/// 채팅 메시지 버블 위젯 (Shadcn UI)
class ChatMessageBubble extends StatelessWidget {
  const ChatMessageBubble({
    super.key,
    required this.message,
    this.onSuggestedQuestionTap,
  });

  final ChatMessage message;
  final ValueChanged<String>? onSuggestedQuestionTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUser = message.isUser;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 4,
      ),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            // AI 아바타
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                RadixIcons.star,
                size: 18,
                color: Colors.white,
              ),
            ),
            const Gap(8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                // 메시지 버블
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isUser
                        ? theme.colorScheme.primary
                        : theme.colorScheme.secondary,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(12),
                      topRight: const Radius.circular(12),
                      bottomLeft: Radius.circular(isUser ? 12 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 12),
                    ),
                  ),
                  child: Text(
                    message.content,
                    style: theme.typography.base.copyWith(
                      color: isUser
                          ? theme.colorScheme.primaryForeground
                          : theme.colorScheme.secondaryForeground,
                    ),
                  ),
                ),

                // 추천 질문 (AI 메시지만)
                if (!isUser && message.hasSuggestedQuestions) ...[
                  const Gap(8),
                  _buildSuggestedQuestions(context, theme),
                ],
              ],
            ),
          ),
          if (isUser) ...[
            const Gap(8),
            // 사용자 아바타
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: theme.colorScheme.secondary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                RadixIcons.person,
                size: 18,
                color: theme.colorScheme.secondaryForeground,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 추천 질문 버튼들
  Widget _buildSuggestedQuestions(BuildContext context, ThemeData theme) {
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: message.suggestedQuestions!.map((question) {
        return OutlineButton(
          size: ButtonSize.small,
          onPressed: () => onSuggestedQuestionTap?.call(question),
          child: Text(
            question,
            style: theme.typography.small,
          ),
        );
      }).toList(),
    );
  }
}
