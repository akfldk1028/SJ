import 'package:flutter/material.dart';

import '../../domain/entities/chat_message.dart';
import 'message_bubble.dart';
import 'streaming_message_bubble.dart';
import 'thinking_bubble.dart';

/// 채팅 메시지 목록 위젯
///
/// 위젯 트리 최적화:
/// - ListView.builder 사용 (가상화)
/// - const 생성자 사용
class ChatMessageList extends StatelessWidget {
  final List<ChatMessage> messages;
  final String? streamingContent;
  final ScrollController? scrollController;
  final bool isLoading;

  const ChatMessageList({
    super.key,
    required this.messages,
    this.streamingContent,
    this.scrollController,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    // 로딩 중(스트리밍 시작 전)이거나 스트리밍 중이면 추가 버블 표시
    final showLoadingBubble = isLoading && streamingContent == null;
    final showStreamingBubble = streamingContent != null;
    final extraItemCount = (showLoadingBubble || showStreamingBubble) ? 1 : 0;
    final itemCount = messages.length + extraItemCount;

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(vertical: 16),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        // 마지막 아이템: 로딩 또는 스트리밍 버블
        if (index == messages.length) {
          if (showStreamingBubble) {
            return StreamingMessageBubble(
              content: streamingContent!,
            );
          }
          if (showLoadingBubble) {
            return const ThinkingBubble();
          }
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
