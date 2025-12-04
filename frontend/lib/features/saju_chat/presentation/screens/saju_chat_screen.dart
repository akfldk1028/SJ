import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/models/chat_type.dart';
import '../providers/chat_provider.dart';
import '../widgets/chat_app_bar.dart';
import '../widgets/chat_input_field.dart';
import '../widgets/chat_message_list.dart';
import '../widgets/disclaimer_banner.dart';
import '../widgets/error_banner.dart';

/// 사주 AI 채팅 화면
///
/// 위젯 트리 최적화:
/// - 화면 조립만 담당 (100줄 이하)
/// - 로직은 ChatNotifier에서 관리
/// - UI 컴포넌트는 작은 위젯으로 분리
class SajuChatScreen extends ConsumerStatefulWidget {
  final String? chatType;

  const SajuChatScreen({
    super.key,
    this.chatType,
  });

  @override
  ConsumerState<SajuChatScreen> createState() => _SajuChatScreenState();
}

class _SajuChatScreenState extends ConsumerState<SajuChatScreen> {
  late final ChatType _chatType;
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _chatType = ChatType.fromString(widget.chatType);
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatNotifierProvider(_chatType));

    // 메시지가 추가되면 스크롤
    ref.listen(
      chatNotifierProvider(_chatType),
      (previous, next) {
        if (previous?.messages.length != next.messages.length ||
            previous?.streamingContent != next.streamingContent) {
          _scrollToBottom();
        }
      },
    );

    return Scaffold(
      appBar: ChatAppBar(
        title: _chatType.title,
        onBack: () => context.pop(),
        onClear: () {
          ref.read(chatNotifierProvider(_chatType).notifier).clearMessages();
        },
      ),
      body: Column(
        children: [
          const DisclaimerBanner(),
          Expanded(
            child: ChatMessageList(
              messages: chatState.messages,
              streamingContent: chatState.streamingContent,
              scrollController: _scrollController,
            ),
          ),
          if (chatState.error != null)
            ErrorBanner(message: chatState.error!),
          ChatInputField(
            onSend: (text) {
              ref
                  .read(chatNotifierProvider(_chatType).notifier)
                  .sendMessage(text);
            },
            enabled: !chatState.isLoading,
            hintText: _chatType.inputHint,
          ),
        ],
      ),
    );
  }
}

