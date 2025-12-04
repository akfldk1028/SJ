import 'package:flutter/material.dart';

import '../../domain/entities/chat_message.dart';
import 'message_bubble.dart';
import 'streaming_message_bubble.dart';

/// 채팅 메시지 목록 위젯
///
/// 위젯 트리 최적화:
/// - ListView.builder 사용 (가상화)
/// - const 생성자 사용
class ChatMessageList extends StatelessWidget {
  final List<ChatMessage> messages;
  final String? streamingContent;
  final ScrollController? scrollController;

  const ChatMessageList({
    super.key,
    required this.messages,
    this.streamingContent,
    this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    final itemCount = messages.length + (streamingContent != null ? 1 : 0);

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(vertical: 16),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        // 스트리밍 메시지는 마지막에 표시
        if (streamingContent != null && index == messages.length) {
          return StreamingMessageBubble(
            content: streamingContent!,
          );
        }

        final message = messages[index];
        return MessageBubble(
          key: ValueKey(message.id),
          message: message,
        );
      },
    );
  }
}
