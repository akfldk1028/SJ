import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/features/profile/domain/entities/gender.dart';
import 'package:frontend/features/profile/domain/entities/saju_profile.dart';
import 'package:frontend/features/profile/presentation/providers/profile_provider.dart';
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
  String? _currentSessionId;
  final ScrollController _scrollController = ScrollController();
  SajuProfile? _selectedTargetProfile;
  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    _initializeSession();
  }

  Future<void> _initializeSession() async {
    if (widget.sessionId != null) {
      setState(() {
        _currentSessionId = widget.sessionId;
        _isInitializing = false;
      });
      // TODO: Load target profile from session if exists
    } else {
      await _createNewSession();
    }
  }

  Future<void> _createNewSession() async {
    try {
      final session = await ref.read(chatSessionControllerProvider(widget.profileId).notifier)
          .createSession(
            targetProfileId: _selectedTargetProfile?.id,
            title: _selectedTargetProfile != null
                ? '${_selectedTargetProfile!.displayName}님과의 상담'
                : null,
          );
      setState(() {
        _currentSessionId = session.id;
        _isInitializing = false;
      });
    } catch (e) {
      // 세션 생성 실패 시에도 초기화 완료 처리 (UI 표시용)
      setState(() {
        _isInitializing = false;
      });
      debugPrint('Failed to create chat session: $e');
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

  void _showTargetSelectionSheet() {
    showShadSheet(
      side: ShadSheetSide.bottom,
      context: context,
      builder: (context) {
        final profilesAsync = ref.watch(allProfilesProvider);
        return ShadSheet(
          title: const Text('상담 대상 선택'),
          description: const Text('누구와의 관계가 궁금하신가요?'),
          child: profilesAsync.when(
            data: (profiles) {
              final targets = profiles.where((p) => p.id != widget.profileId).toList();
              if (targets.isEmpty) {
                return const Center(
                  child: Text('등록된 지인이 없습니다.\n[인연] 탭에서 지인을 추가해주세요.'),
                );
              }
              return ListView.builder(
                shrinkWrap: true,
                itemCount: targets.length,
                itemBuilder: (context, index) {
                  final profile = targets[index];
                  return ListTile(
                    leading: Text(
                      profile.gender == Gender.male ? '👨' : '👩',
                      style: const TextStyle(fontSize: 24),
                    ),
                    title: Text(profile.displayName),
                    subtitle: Text(profile.relationType.label),
                    onTap: () {
                      setState(() {
                        _selectedTargetProfile = profile;
                      });
                      _createNewSession(); // Start new session with new target
                      Navigator.pop(context);
                    },
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Error: $err')),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // 초기화 중이거나 세션 ID가 없으면 로딩 표시
    if (_isInitializing || _currentSessionId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('만톡 AI 상담')),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('채팅 준비 중...'),
            ],
          ),
        ),
      );
    }

    final messagesAsync = ref.watch(chatMessageControllerProvider(_currentSessionId!));

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
                            ref.read(chatMessageControllerProvider(_currentSessionId!).notifier)
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

          // Target Selection Chip
          if (_selectedTargetProfile != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.grey.withOpacity(0.1),
              child: Row(
                children: [
                  const Text('상담 대상: ', style: TextStyle(fontWeight: FontWeight.bold)),
                  Chip(
                    label: Text(_selectedTargetProfile!.displayName),
                    avatar: Text(_selectedTargetProfile!.gender == Gender.male ? '👨' : '👩'),
                    onDeleted: () {
                      setState(() {
                        _selectedTargetProfile = null;
                      });
                      _createNewSession();
                    },
                  ),
                ],
              ),
            ),

          // Input Area
          Column(
            children: [
              if (_selectedTargetProfile == null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ShadButton.outline(
                    width: double.infinity,
                    onPressed: _showTargetSelectionSheet,
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.person_add, size: 18),
                        SizedBox(width: 8),
                        Text('상담 대상(지인) 선택하기'),
                      ],
                    ),
                  ),
                ),
              ChatInputField(
                isLoading: messagesAsync.isLoading,
                onSend: (text) {
                  ref.read(chatMessageControllerProvider(_currentSessionId!).notifier)
                      .sendMessage(text);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
