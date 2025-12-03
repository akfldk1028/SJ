import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

import '../providers/chat_provider.dart';
import '../widgets/chat_input_field.dart';
import '../widgets/chat_message_bubble.dart';
import '../widgets/streaming_message_bubble.dart';

/// AI 사주 채팅 화면 (실시간 스트리밍, Shadcn UI)
class SajuChatScreen extends ConsumerStatefulWidget {
  const SajuChatScreen({
    super.key,
    required this.profileId,
    this.sessionId,
  });

  final String profileId;
  final String? sessionId;

  @override
  ConsumerState<SajuChatScreen> createState() => _SajuChatScreenState();
}

class _SajuChatScreenState extends ConsumerState<SajuChatScreen> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// 메시지 목록 맨 아래로 스크롤
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider(widget.profileId));
    final chatNotifier = ref.read(chatProvider(widget.profileId).notifier);
    final theme = Theme.of(context);

    // 메시지 또는 스트리밍 변경 시 스크롤
    ref.listen(
      chatProvider(widget.profileId),
      (previous, next) {
        if (previous?.messages.length != next.messages.length ||
            previous?.streamingContent != next.streamingContent) {
          _scrollToBottom();
        }
      },
    );

    return Scaffold(
      headers: [
        AppBar(
          leading: [
            IconButton.ghost(
              icon: const Icon(RadixIcons.arrowLeft),
              onPressed: () => context.go('/home'),
            ),
          ],
          title: const Text('AI 사주 상담'),
          trailing: [
            IconButton.ghost(
              icon: const Icon(RadixIcons.reload),
              onPressed: chatNotifier.startNewChat,
            ),
          ],
        ),
      ],
      child: Column(
        children: [
          // 메시지 목록
          Expanded(
            child: chatState.messages.isEmpty && !chatState.isStreaming
                ? _buildEmptyState(context, theme, chatNotifier)
                : _buildMessageList(chatState, chatNotifier),
          ),

          // 에러 표시
          if (chatState.error != null)
            _buildErrorBanner(context, theme, chatState.error!, chatNotifier),

          // 입력 필드
          ChatInputField(
            onSend: chatNotifier.sendMessage,
            isLoading: chatState.isLoading,
          ),
        ],
      ),
    );
  }

  /// 빈 상태 (첫 대화)
  Widget _buildEmptyState(
    BuildContext context,
    ThemeData theme,
    Chat chatNotifier,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.scaleAlpha(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                RadixIcons.star,
                size: 40,
                color: theme.colorScheme.primary,
              ),
            ),
            const Gap(24),
            Text(
              'AI 사주 상담을 시작해보세요',
              style: theme.typography.h4.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const Gap(8),
            Text(
              '운세, 궁합, 진로 등 무엇이든 물어보세요',
              style: theme.typography.small.copyWith(
                color: theme.colorScheme.mutedForeground,
              ),
            ),
            const Gap(32),

            // 예시 질문들
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _buildSampleQuestion(context, theme, '올해 운세는 어때요?', chatNotifier),
                _buildSampleQuestion(context, theme, '이직해도 괜찮을까요?', chatNotifier),
                _buildSampleQuestion(context, theme, '연애운이 궁금해요', chatNotifier),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 예시 질문 칩
  Widget _buildSampleQuestion(
    BuildContext context,
    ThemeData theme,
    String question,
    Chat chatNotifier,
  ) {
    return OutlineButton(
      size: ButtonSize.small,
      onPressed: () => chatNotifier.sendMessage(question),
      child: Text(question),
    );
  }

  /// 메시지 목록
  Widget _buildMessageList(ChatState state, Chat notifier) {
    final itemCount = state.messages.length + (state.isStreaming ? 1 : 0);

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: 16),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        // 스트리밍 중인 메시지
        if (state.isStreaming && index == itemCount - 1) {
          return StreamingMessageBubble(
            content: state.streamingContent ?? '',
          );
        }

        // 일반 메시지
        final message = state.messages[index];
        return ChatMessageBubble(
          message: message,
          onSuggestedQuestionTap: notifier.selectSuggestedQuestion,
        );
      },
    );
  }

  /// 에러 배너
  Widget _buildErrorBanner(
    BuildContext context,
    ThemeData theme,
    String error,
    Chat notifier,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      color: theme.colorScheme.destructive.scaleAlpha(0.1),
      child: Row(
        children: [
          Icon(
            RadixIcons.crossCircled,
            size: 16,
            color: theme.colorScheme.destructive,
          ),
          const Gap(8),
          Expanded(
            child: Text(
              error,
              style: theme.typography.small.copyWith(
                color: theme.colorScheme.destructive,
              ),
            ),
          ),
          GhostButton(
            size: ButtonSize.small,
            onPressed: notifier.clearError,
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }
}
