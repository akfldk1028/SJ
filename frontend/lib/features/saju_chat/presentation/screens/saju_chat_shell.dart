import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/chat_type.dart';
import '../providers/chat_provider.dart';
import '../providers/chat_session_provider.dart';
import '../widgets/chat_history_sidebar/chat_history_sidebar.dart';
import '../widgets/chat_input_field.dart';
import '../widgets/chat_message_list.dart';
import '../widgets/disclaimer_banner.dart';
import '../widgets/error_banner.dart';
import '../widgets/suggested_questions.dart';
import '../../../profile/presentation/providers/profile_provider.dart';

/// 사주 채팅 Shell - 반응형 레이아웃 래퍼
///
/// 반응형 설계:
/// - Mobile (< 600px): Scaffold + Drawer (사이드바)
/// - Desktop/Tablet (>= 600px): Row [사이드바 | 채팅 영역]
///
/// 위젯 트리 최적화:
/// - const 생성자 사용
/// - 작은 위젯으로 분리 (AppBar, Content)
/// - 브레이크포인트 기반 레이아웃 전환
class SajuChatShell extends ConsumerStatefulWidget {
  final String? chatType;

  const SajuChatShell({
    super.key,
    this.chatType,
  });

  @override
  ConsumerState<SajuChatShell> createState() => _SajuChatShellState();
}

class _SajuChatShellState extends ConsumerState<SajuChatShell> {
  static const double _breakpoint = 600.0;
  late final ChatType _chatType;
  late final ScrollController _scrollController;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  /// Desktop 사이드바 표시 여부
  bool _isSidebarVisible = true;

  @override
  void initState() {
    super.initState();
    _chatType = ChatType.fromString(widget.chatType);
    _scrollController = ScrollController();
    _initializeSession();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// 세션 초기화: 세션 로드 후 없으면 기본 세션 생성
  Future<void> _initializeSession() async {
    // 세션 로드가 완료될 때까지 잠시 대기
    await Future.delayed(const Duration(milliseconds: 100));

    if (!mounted) return;

    final sessionNotifier = ref.read(chatSessionNotifierProvider.notifier);
    final sessionState = ref.read(chatSessionNotifierProvider);

    // 활성 프로필 ID 가져오기
    final activeProfile = await ref.read(activeProfileProvider.future);
    final profileId = activeProfile?.id;

    // 세션이 없으면 기본 세션 생성
    if (sessionState.sessions.isEmpty) {
      await sessionNotifier.createSession(_chatType, profileId);
    } else if (sessionState.currentSessionId == null) {
      // 세션이 있지만 선택되지 않았으면 첫 번째 세션 선택
      sessionNotifier.selectSession(sessionState.sessions.first.id);
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  /// 새 채팅 시작
  Future<void> _handleNewChat() async {
    final sessionNotifier = ref.read(chatSessionNotifierProvider.notifier);
    final activeProfile = await ref.read(activeProfileProvider.future);
    await sessionNotifier.createSession(_chatType, activeProfile?.id);
  }

  /// 세션 선택
  void _handleSessionSelected(String sessionId) {
    final sessionNotifier = ref.read(chatSessionNotifierProvider.notifier);
    sessionNotifier.selectSession(sessionId);

    // Mobile에서는 Drawer 닫기
    if (MediaQuery.of(context).size.width < _breakpoint) {
      Navigator.of(context).pop();
    }
  }

  /// 세션 삭제
  Future<void> _handleSessionDeleted(String sessionId) async {
    final sessionNotifier = ref.read(chatSessionNotifierProvider.notifier);
    await sessionNotifier.deleteSession(sessionId);
  }

  /// 세션 이름 변경
  Future<void> _handleSessionRenamed(String sessionId, String newTitle) async {
    final sessionNotifier = ref.read(chatSessionNotifierProvider.notifier);
    await sessionNotifier.renameSession(sessionId, newTitle);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < _breakpoint;

        if (isMobile) {
          return _buildMobileLayout();
        } else {
          return _buildDesktopLayout();
        }
      },
    );
  }

  /// Mobile 레이아웃: Scaffold + Drawer
  Widget _buildMobileLayout() {
    final sessionState = ref.watch(chatSessionNotifierProvider);
    final currentSession = sessionState.sessions
        .where((s) => s.id == sessionState.currentSessionId)
        .firstOrNull;

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: Text(currentSession?.title ?? _chatType.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _handleNewChat,
            tooltip: '새 채팅',
          ),
        ],
      ),
      drawer: Drawer(
        child: ChatHistorySidebar(
          onNewChat: _handleNewChat,
          onSessionSelected: _handleSessionSelected,
          onSessionDeleted: _handleSessionDeleted,
          onSessionRenamed: _handleSessionRenamed,
        ),
      ),
      body: _ChatContent(
        chatType: _chatType,
        scrollController: _scrollController,
        onScroll: _scrollToBottom,
        onCreateSession: _handleNewChat,
      ),
    );
  }

  /// Desktop 레이아웃: Row [Sidebar | Content]
  Widget _buildDesktopLayout() {
    final sessionState = ref.watch(chatSessionNotifierProvider);
    final currentSession = sessionState.sessions
        .where((s) => s.id == sessionState.currentSessionId)
        .firstOrNull;

    return Scaffold(
      body: Row(
        children: [
          // 사이드바 (토글 가능)
          if (_isSidebarVisible) ...[
            ChatHistorySidebar(
              onNewChat: _handleNewChat,
              onSessionSelected: _handleSessionSelected,
              onSessionDeleted: _handleSessionDeleted,
              onSessionRenamed: _handleSessionRenamed,
            ),
            const VerticalDivider(width: 1),
          ],
          // 채팅 영역
          Expanded(
            child: Column(
              children: [
                // Desktop AppBar (사이드바 토글 + 제목)
                Container(
                  height: 56,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: Theme.of(context).colorScheme.outlineVariant,
                        width: 0.5,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      // 햄버거 아이콘 (사이드바 토글)
                      IconButton(
                        icon: const Icon(Icons.menu),
                        onPressed: () {
                          setState(() {
                            _isSidebarVisible = !_isSidebarVisible;
                          });
                        },
                        tooltip: _isSidebarVisible ? '사이드바 숨기기' : '사이드바 보기',
                      ),
                      const SizedBox(width: 8),
                      // 현재 세션 제목
                      Expanded(
                        child: Text(
                          currentSession?.title ?? _chatType.title,
                          style: Theme.of(context).textTheme.titleMedium,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // 새 채팅 버튼
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: _handleNewChat,
                        tooltip: '새 채팅',
                      ),
                    ],
                  ),
                ),
                // 채팅 컨텐츠
                Expanded(
                  child: _ChatContent(
                    chatType: _chatType,
                    scrollController: _scrollController,
                    onScroll: _scrollToBottom,
                    onCreateSession: _handleNewChat,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 채팅 컨텐츠 영역 (메시지 목록 + 입력 필드)
///
/// ConsumerStatefulWidget으로 변경하여 pendingMessage 처리를 안정적으로 수행
class _ChatContent extends ConsumerStatefulWidget {
  final ChatType chatType;
  final ScrollController scrollController;
  final VoidCallback onScroll;
  final VoidCallback? onCreateSession;

  const _ChatContent({
    required this.chatType,
    required this.scrollController,
    required this.onScroll,
    this.onCreateSession,
  });

  @override
  ConsumerState<_ChatContent> createState() => _ChatContentState();
}

class _ChatContentState extends ConsumerState<_ChatContent> {
  /// pendingMessage 처리 중 플래그 (중복 전송 방지)
  bool _isProcessingPendingMessage = false;

  @override
  Widget build(BuildContext context) {
    final sessionState = ref.watch(chatSessionNotifierProvider);
    final currentSessionId = sessionState.currentSessionId;

    // 세션이 없으면 환영 메시지 + 입력 필드
    if (currentSessionId == null) {
      return Column(
        children: [
          const DisclaimerBanner(),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 64,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '무엇이든 물어보세요',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '사주, 운세, 궁합 등 궁금한 것을 입력해주세요',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                  ),
                ],
              ),
            ),
          ),
          ChatInputField(
            onSend: (text) async {
              // 세션 생성 + 대기 메시지 설정 (UI 리빌드 후 자동 전송)
              print('[_ChatContent] 세션 생성 요청: text=$text');
              final activeProfile = await ref.read(activeProfileProvider.future);
              ref.read(chatSessionNotifierProvider.notifier)
                  .createSession(widget.chatType, activeProfile?.id, initialMessage: text);
            },
            enabled: true,
            hintText: widget.chatType.inputHint,
          ),
        ],
      );
    }

    final chatState = ref.watch(chatNotifierProvider(currentSessionId));
    final pendingMessage = sessionState.pendingMessage;

    // pendingMessage가 있으면 즉시 전송 (세션 생성 직후)
    // 플래그로 중복 전송 방지
    if (pendingMessage != null && pendingMessage.isNotEmpty && !_isProcessingPendingMessage) {
      print('[_ChatContent] pendingMessage 발견: $pendingMessage, sessionId=$currentSessionId');
      _isProcessingPendingMessage = true;

      // 다음 프레임에서 실행 (build 중 state 변경 방지)
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        print('[_ChatContent] postFrameCallback에서 sendMessage 호출');

        final msg = pendingMessage; // 캡처
        ref.read(chatSessionNotifierProvider.notifier).clearPendingMessage();
        ref.read(chatNotifierProvider(currentSessionId).notifier)
            .sendMessage(msg, widget.chatType);

        _isProcessingPendingMessage = false;
      });
    }

    // 메시지가 추가되면 스크롤
    ref.listen(
      chatNotifierProvider(currentSessionId),
      (previous, next) {
        if (previous?.messages.length != next.messages.length ||
            previous?.streamingContent != next.streamingContent) {
          widget.onScroll();
        }
      },
    );

    // 마지막 AI 메시지의 suggestedQuestions 가져오기
    final lastAiMessage = chatState.messages
        .where((m) => m.isAi)
        .lastOrNull;
    final suggestedQuestions = lastAiMessage?.suggestedQuestions;

    return Column(
      children: [
        const DisclaimerBanner(),
        Expanded(
          child: ChatMessageList(
            messages: chatState.messages,
            streamingContent: chatState.streamingContent,
            scrollController: widget.scrollController,
            isLoading: chatState.isLoading,
          ),
        ),
        if (chatState.error != null) ErrorBanner(message: chatState.error!),
        // 추천 질문 표시 (로딩 중이 아니고 메시지가 있을 때)
        if (!chatState.isLoading && chatState.messages.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: SuggestedQuestions(
              questions: suggestedQuestions,
              onQuestionSelected: (question) {
                print('[_ChatContent] 추천 질문 선택: $question');
                ref
                    .read(chatNotifierProvider(currentSessionId).notifier)
                    .sendMessage(question, widget.chatType);
              },
            ),
          ),
        ChatInputField(
          onSend: (text) {
            print('[_ChatContent] 메시지 전송: sessionId=$currentSessionId, text=$text');
            ref
                .read(chatNotifierProvider(currentSessionId).notifier)
                .sendMessage(text, widget.chatType);
          },
          enabled: !chatState.isLoading,
          hintText: widget.chatType.inputHint,
        ),
      ],
    );
  }
}
