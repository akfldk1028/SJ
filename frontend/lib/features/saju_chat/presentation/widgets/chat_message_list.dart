import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../ad/ad.dart';
import '../../domain/entities/chat_message.dart';
import 'message_bubble.dart';
import 'streaming_message_bubble.dart';
import 'thinking_bubble.dart';

/// 채팅 메시지 목록 위젯
///
/// 위젯 트리 최적화:
/// - ListView.builder 사용 (가상화)
/// - const 생성자 사용
/// - 모듈형 광고 삽입 (N개 메시지마다)
///
/// 광고 유형 (ad_strategy.dart에서 설정):
/// - inlineBanner: 간단한 배너 ($1~3 eCPM)
/// - nativeMedium: 채팅 버블 스타일 ($3~15 eCPM) ★ 기본값
/// - nativeCompact: 컴팩트 네이티브 ($2~8 eCPM)
class ChatMessageList extends StatelessWidget {
  final List<ChatMessage> messages;
  final String? streamingContent;
  final ScrollController? scrollController;
  final bool isLoading;

  /// 리스트 끝에 표시할 위젯 (광고 등 채팅 플로우에 포함)
  final Widget? trailingWidget;

  const ChatMessageList({
    super.key,
    required this.messages,
    this.streamingContent,
    this.scrollController,
    this.isLoading = false,
    this.trailingWidget,
  });

  @override
  Widget build(BuildContext context) {
    // 로딩 중(스트리밍 시작 전)이거나 스트리밍 중이면 추가 버블 표시
    final showLoadingBubble = isLoading && streamingContent == null;
    final showStreamingBubble = streamingContent != null;
    final hasTrailing = trailingWidget != null;
    final extraItemCount = (showLoadingBubble || showStreamingBubble ? 1 : 0)
        + (hasTrailing ? 1 : 0);

    // 인라인 광고 위치 계산 (Web 제외)
    // 광고는 반드시 AI 응답 뒤에만 삽입 (유저↔AI 대화쌍 사이 금지)
    final (totalCount, adIndices) = _calculateItemsWithAds(
      messages: messages,
      extraItems: extraItemCount,
    );

    // 디버그: 광고 위치 로깅
    debugPrint('[ChatMessageList] messages: ${messages.length}, ads: ${adIndices.length}, indices: $adIndices');

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(vertical: 16),
      itemCount: totalCount,
      itemBuilder: (context, index) {
        // 광고 인덱스인 경우 광고 표시 (Factory 패턴 사용)
        if (!kIsWeb && adIndices.contains(index)) {
          return ChatAdWidget(index: index);
        }

        // 실제 메시지 인덱스 계산 (광고 위치 제외)
        final messageIndex = _toMessageIndex(index, adIndices);

        // 마지막 아이템들: 로딩/스트리밍 버블 + trailing 위젯
        if (messageIndex >= messages.length) {
          // 로딩/스트리밍이 먼저, trailing은 그 뒤
          final extraIndex = messageIndex - messages.length;
          final hasLoadingOrStreaming = showLoadingBubble || showStreamingBubble;

          if (hasLoadingOrStreaming && extraIndex == 0) {
            if (showStreamingBubble) {
              return StreamingMessageBubble(
                content: streamingContent!,
              );
            }
            if (showLoadingBubble) {
              return const ThinkingBubble();
            }
          }

          // trailing 위젯 (광고 등)
          if (hasTrailing) {
            final trailingIndex = hasLoadingOrStreaming ? 1 : 0;
            if (extraIndex == trailingIndex) {
              return trailingWidget!;
            }
          }

          return const SizedBox.shrink();
        }

        final message = messages[messageIndex];

        // 빈 메시지는 렌더링하지 않음
        if (message.content.trim().isEmpty) {
          return const SizedBox.shrink();
        }

        return MessageBubble(
          key: ValueKey(message.id),
          message: message,
          isStreamingActive: isLoading,
        );
      },
    );
  }

  /// 광고 포함 아이템 계산
  ///
  /// 광고는 반드시 AI 응답(assistant) 뒤에만 삽입.
  /// 유저 메시지 → AI 응답 대화쌍 사이에는 절대 광고가 끼어들지 않음.
  ///
  /// Returns: (총 아이템 수, 광고 인덱스 Set)
  (int, Set<int>) _calculateItemsWithAds({
    required List<ChatMessage> messages,
    required int extraItems,
  }) {
    final messageCount = messages.length;

    // Web이거나 메시지가 최소 개수 미만이면 광고 없음
    if (kIsWeb || messageCount < AdStrategy.inlineAdMinMessages) {
      return (messageCount + extraItems, {});
    }

    const interval = AdStrategy.inlineAdMessageInterval;
    const maxAds = AdStrategy.inlineAdMaxCount;
    final Set<int> adIndices = {};
    int adCount = 0;

    // interval번째 메시지 뒤에 광고 삽입 (단, AI 응답 뒤에만)
    for (int i = interval; i <= messageCount && adCount < maxAds; i += interval) {
      // 광고가 들어갈 위치: 메시지 인덱스 i-1 (0-based)
      // 이 메시지가 AI 응답인지 확인
      int adAfterMsgIndex = i - 1;

      // AI 응답이 아니면 그 이전 AI 응답을 찾아서 삽입
      // (유저 메시지 뒤에 광고가 가면 → 유저↔AI 사이에 끼어듦)
      while (adAfterMsgIndex >= 0 && !messages[adAfterMsgIndex].isAi) {
        adAfterMsgIndex--;
      }

      // 적절한 AI 응답을 찾았으면 그 뒤에 광고 삽입
      if (adAfterMsgIndex >= 0) {
        final adIndex = adAfterMsgIndex + 1 + adCount;
        // 중복 방지
        if (!adIndices.contains(adIndex)) {
          adIndices.add(adIndex);
          adCount++;
        }
      }
    }

    return (messageCount + adCount + extraItems, adIndices);
  }

  /// ListView 인덱스를 실제 메시지 인덱스로 변환
  int _toMessageIndex(int index, Set<int> adIndices) {
    int adsBefore = 0;
    for (final adIndex in adIndices) {
      if (adIndex < index) {
        adsBefore++;
      }
    }
    return index - adsBefore;
  }
}
