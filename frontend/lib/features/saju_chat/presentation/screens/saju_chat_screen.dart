import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/features/saju_chat/presentation/providers/chat_provider.dart';
import 'package:frontend/features/saju_chat/presentation/widgets/chat_bubble.dart';
import 'package:frontend/features/saju_chat/presentation/widgets/chat_input_field.dart';
import 'package:frontend/features/saju_chat/presentation/widgets/suggested_questions.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class SajuChatScreen extends ConsumerStatefulWidget {
  final String? sessionId;
  final String profileId;

  const SajuChatScreen({
    super.key,
    this.sessionId,
    required this.profileId,
  });

  @override
  ConsumerState<SajuChatScreen> createState() => _SajuChatScreenState();
}

class _SajuChatScreenState extends ConsumerState<SajuChatScreen> {
  late String _currentSessionId;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _initializeSession();
  }

  Future<void> _initializeSession() async {
    if (widget.sessionId != null) {
      _currentSessionId = widget.sessionId!;
    } else {
      // Create new session if none provided
      // Note: In a real app, you might want to do this only when the first message is sent
      // or check for an existing empty session.
      final session = await ref.read(chatSessionControllerProvider(widget.profileId).notifier)
          .createSession();
      setState(() {
        _currentSessionId = session.id;
      });
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(chatMessageControllerProvider(_currentSessionId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('만톡 AI 상담'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              // TODO: Show history or navigate to history screen
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Warning Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            color: Colors.amber.withOpacity(0.1),
            child: const Text(
              '🔮 사주 결과는 참고용으로만 활용해주세요.',
              style: TextStyle(fontSize: 12, color: Colors.brown),
              textAlign: TextAlign.center,
            ),
          ),
          
          // Chat Area
          Expanded(
            child: messagesAsync.when(
              data: (messages) {
                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.chat_bubble_outline, size: 48, color: Colors.grey),
                        const SizedBox(height: 16),
                        const Text('AI와 대화를 시작해보세요!'),
                        const SizedBox(height: 24),
                        SuggestedQuestions(
                          onQuestionSelected: (text) {
                            ref.read(chatMessageControllerProvider(_currentSessionId).notifier)
                                .sendMessage(text);
                          },
                        ),
                      ],
                    ),
                  );
                }

                // Scroll to bottom when new messages arrive
                WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    return ChatBubble(message: messages[index]);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
            ),
          ),

          // Input Area
          ChatInputField(
            isLoading: messagesAsync.isLoading,
            onSend: (text) {
              ref.read(chatMessageControllerProvider(_currentSessionId).notifier)
                  .sendMessage(text);
            },
          ),
        ],
      ),
    );
  }
}
