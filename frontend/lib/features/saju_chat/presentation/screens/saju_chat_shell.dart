import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../ad/ad.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../router/routes.dart';
import '../../domain/models/chat_type.dart';
import '../providers/chat_provider.dart';
import '../providers/chat_session_provider.dart';
import '../widgets/chat_history_sidebar/chat_history_sidebar.dart';
import '../widgets/chat_input_field.dart';
import '../widgets/chat_message_list.dart';
import '../widgets/disclaimer_banner.dart';
import '../widgets/error_banner.dart';
import '../widgets/relation_selector_sheet.dart';
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

  /// 상대방 프로필 ID (궁합/타인 상담 시 사용)
  /// - null이면 내 프로필 기준 상담
  /// - 값이 있으면 해당 프로필 기준 상담 (궁합도 가능)
  final String? targetProfileId;

  const SajuChatShell({
    super.key,
    this.chatType,
    this.targetProfileId,
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
    // 새 세션 광고 표시 (Web 제외)
    if (!kIsWeb) {
      await ref.read(adControllerProvider.notifier).onNewSession();
    }

    final sessionNotifier = ref.read(chatSessionNotifierProvider.notifier);
    final activeProfile = await ref.read(activeProfileProvider.future);
    await sessionNotifier.createSession(_chatType, activeProfile?.id);
  }

  /// 궁합 채팅 시작 (인연 선택)
  ///
  /// 1. RelationSelectorSheet 표시
  /// 2. 인연 선택 시 @카테고리/이름 형태로 초기 메시지 설정
  /// 3. targetProfileId와 함께 새 세션 생성
  Future<void> _handleCompatibilityChat() async {
    final selection = await RelationSelectorSheet.show(context);
    if (selection == null || !mounted) return;

    if (kDebugMode) {
      print('[SajuChatShell] 🎯 궁합 채팅 시작');
      print('   - 선택된 인연: ${selection.relation.displayName}');
      print('   - toProfileId: ${selection.relation.toProfileId}');
      print('   - 멘션: ${selection.mentionText}');
    }

    // 새 세션 광고 표시 (Web 제외)
    if (!kIsWeb) {
      await ref.read(adControllerProvider.notifier).onNewSession();
    }

    final sessionNotifier = ref.read(chatSessionNotifierProvider.notifier);
    final activeProfile = await ref.read(activeProfileProvider.future);

    // 궁합 채팅 세션 생성 (targetProfileId 포함)
    await sessionNotifier.createSession(
      _chatType,
      activeProfile?.id,
      initialMessage: '${selection.mentionText}님과의 궁합이 궁금해요',
      targetProfileId: selection.relation.toProfileId,
    );
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
    final appTheme = context.appTheme;
    final currentSession = sessionState.sessions
        .where((s) => s.id == sessionState.currentSessionId)
        .firstOrNull;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: appTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: appTheme.backgroundColor,
        foregroundColor: appTheme.textPrimary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(Routes.menu),
          tooltip: '메뉴로 돌아가기',
        ),
        title: Text(
          currentSession?.title ?? _chatType.title,
          style: TextStyle(color: appTheme.textPrimary),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
            tooltip: '채팅 기록',
          ),
          // 새 채팅 버튼 (PopupMenu)
          PopupMenuButton<String>(
            icon: const Icon(Icons.add),
            tooltip: '새 채팅',
            offset: const Offset(0, 40),
            color: appTheme.cardColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            onSelected: (value) {
              if (value == 'normal') {
                _handleNewChat();
              } else if (value == 'compatibility') {
                _handleCompatibilityChat();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem<String>(
                value: 'normal',
                child: Row(
                  children: [
                    Icon(Icons.chat_bubble_outline,
                      color: appTheme.textPrimary, size: 20),
                    const SizedBox(width: 12),
                    Text('일반 채팅',
                      style: TextStyle(color: appTheme.textPrimary)),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'compatibility',
                child: Row(
                  children: [
                    Icon(Icons.favorite_outline,
                      color: appTheme.primaryColor, size: 20),
                    const SizedBox(width: 12),
                    Text('궁합 채팅',
                      style: TextStyle(color: appTheme.textPrimary)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      drawer: Drawer(
        backgroundColor: appTheme.cardColor,
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
        targetProfileId: widget.targetProfileId,
      ),
    );
  }

  /// Desktop 레이아웃: Row [Sidebar | Content]
  Widget _buildDesktopLayout() {
    final sessionState = ref.watch(chatSessionNotifierProvider);
    final appTheme = context.appTheme;
    final currentSession = sessionState.sessions
        .where((s) => s.id == sessionState.currentSessionId)
        .firstOrNull;

    return Scaffold(
      backgroundColor: appTheme.backgroundColor,
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
            VerticalDivider(
              width: 1,
              color: appTheme.primaryColor.withOpacity(0.1),
            ),
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
                    color: appTheme.backgroundColor,
                    border: Border(
                      bottom: BorderSide(
                        color: appTheme.primaryColor.withOpacity(0.1),
                        width: 0.5,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      // 뒤로가기 버튼
                      IconButton(
                        icon: Icon(Icons.arrow_back, color: appTheme.textPrimary),
                        onPressed: () => context.go(Routes.menu),
                        tooltip: '메뉴로 돌아가기',
                      ),
                      // 햄버거 아이콘 (사이드바 토글)
                      IconButton(
                        icon: Icon(
                          _isSidebarVisible ? Icons.menu_open : Icons.menu,
                          color: appTheme.textPrimary,
                        ),
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
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: appTheme.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // 새 채팅 버튼 (PopupMenu)
                      PopupMenuButton<String>(
                        icon: Icon(Icons.add, color: appTheme.textPrimary),
                        tooltip: '새 채팅',
                        offset: const Offset(0, 40),
                        color: appTheme.cardColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        onSelected: (value) {
                          if (value == 'normal') {
                            _handleNewChat();
                          } else if (value == 'compatibility') {
                            _handleCompatibilityChat();
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem<String>(
                            value: 'normal',
                            child: Row(
                              children: [
                                Icon(Icons.chat_bubble_outline,
                                  color: appTheme.textPrimary, size: 20),
                                const SizedBox(width: 12),
                                Text('일반 채팅',
                                  style: TextStyle(color: appTheme.textPrimary)),
                              ],
                            ),
                          ),
                          PopupMenuItem<String>(
                            value: 'compatibility',
                            child: Row(
                              children: [
                                Icon(Icons.favorite_outline,
                                  color: appTheme.primaryColor, size: 20),
                                const SizedBox(width: 12),
                                Text('궁합 채팅',
                                  style: TextStyle(color: appTheme.textPrimary)),
                              ],
                            ),
                          ),
                        ],
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
                    targetProfileId: widget.targetProfileId,
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

  /// 궁합 채팅 시 상대방 프로필 ID
  final String? targetProfileId;

  const _ChatContent({
    required this.chatType,
    required this.scrollController,
    required this.onScroll,
    this.onCreateSession,
    this.targetProfileId,
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
    final appTheme = context.appTheme;

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
                    color: appTheme.textMuted,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '무엇이든 물어보세요',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: appTheme.textPrimary,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '사주, 운세, 궁합 등 궁금한 것을 입력해주세요',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: appTheme.textMuted,
                        ),
                  ),
                ],
              ),
            ),
          ),
          ChatInputField(
            onSend: (text) async {
              // 세션 생성 + 대기 메시지 설정 (UI 리빌드 후 자동 전송)
              print('[_ChatContent] 세션 생성 요청: text=$text, targetProfileId=${widget.targetProfileId}');
              final activeProfile = await ref.read(activeProfileProvider.future);
              ref.read(chatSessionNotifierProvider.notifier)
                  .createSession(
                    widget.chatType,
                    activeProfile?.id,
                    initialMessage: text,
                    targetProfileId: widget.targetProfileId,
                  );
            },
            enabled: true,
            hintText: widget.chatType.inputHint,
          ),
        ],
      );
    }

    final chatState = ref.watch(chatNotifierProvider(currentSessionId));
    final pendingMessage = sessionState.pendingMessage;

    // 현재 세션의 targetProfileId 가져오기 (세션에 저장된 값 우선)
    final currentSession = sessionState.sessions
        .where((s) => s.id == currentSessionId)
        .firstOrNull;
    final effectiveTargetProfileId = currentSession?.targetProfileId ?? widget.targetProfileId;

    if (kDebugMode && effectiveTargetProfileId != null) {
      print('[_ChatContent] 궁합 채팅 모드: targetProfileId=$effectiveTargetProfileId');
    }

    // pendingMessage가 있으면 즉시 전송 (세션 생성 직후)
    // 플래그로 중복 전송 방지
    if (pendingMessage != null && pendingMessage.isNotEmpty && !_isProcessingPendingMessage) {
      print('[_ChatContent] pendingMessage 발견: $pendingMessage, sessionId=$currentSessionId');
      _isProcessingPendingMessage = true;

      // 다음 프레임에서 실행 (build 중 state 변경 방지)
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        print('[_ChatContent] postFrameCallback에서 sendMessage 호출, targetProfileId=$effectiveTargetProfileId');

        final msg = pendingMessage; // 캡처
        final targetId = effectiveTargetProfileId; // 캡처
        ref.read(chatSessionNotifierProvider.notifier).clearPendingMessage();
        ref.read(chatNotifierProvider(currentSessionId).notifier)
            .sendMessage(msg, widget.chatType, targetProfileId: targetId);

        _isProcessingPendingMessage = false;
      });
    }

    // 메시지가 추가되면 스크롤 + 광고 체크
    ref.listen(
      chatNotifierProvider(currentSessionId),
      (previous, next) {
        if (previous?.messages.length != next.messages.length ||
            previous?.streamingContent != next.streamingContent) {
          widget.onScroll();
        }

        // AI 응답 완료 시 광고 체크 (메시지 수 증가 & 로딩 완료)
        if (!kIsWeb &&
            previous?.messages.length != next.messages.length &&
            !next.isLoading &&
            next.messages.isNotEmpty &&
            next.messages.last.isAi) {
          // 광고 카운터 체크 (비동기)
          ref.read(adControllerProvider.notifier).onChatMessage();
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
        // GPT-5.2 상세 분석 로딩 배너 (첫 프로필 분석 시 ~2분 소요)
        if (chatState.isDeepAnalysisRunning)
          const _DeepAnalysisLoadingBanner(),
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
                    .sendMessage(question, widget.chatType, targetProfileId: effectiveTargetProfileId);
              },
            ),
          ),
        ChatInputField(
          onSend: (text) {
            print('[_ChatContent] 메시지 전송: sessionId=$currentSessionId, text=$text, targetProfileId=$effectiveTargetProfileId');
            ref
                .read(chatNotifierProvider(currentSessionId).notifier)
                .sendMessage(text, widget.chatType, targetProfileId: effectiveTargetProfileId);
          },
          enabled: !chatState.isLoading,
          hintText: widget.chatType.inputHint,
        ),
      ],
    );
  }
}

/// GPT-5.2 상세 분석 로딩 배너
///
/// 첫 프로필 분석 시 ~2분 소요되므로 사용자에게 진행 상황을 안내합니다.
/// - 합충형파해, 십성, 신살 등 정밀 분석 진행
/// - 한 번 저장되면 이후에는 빠르게 로드됨
class _DeepAnalysisLoadingBanner extends StatelessWidget {
  const _DeepAnalysisLoadingBanner();

  @override
  Widget build(BuildContext context) {
    final appTheme = context.appTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: appTheme.primaryColor.withOpacity(0.1),
        border: Border(
          bottom: BorderSide(
            color: appTheme.primaryColor.withOpacity(0.2),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          // 로딩 스피너
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(appTheme.primaryColor),
            ),
          ),
          const SizedBox(width: 12),
          // 안내 텍스트
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '상세 사주 분석 중...',
                  style: TextStyle(
                    fontSize: 14,
                    color: appTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '합충형파해, 십성, 신살 등 정밀 분석 진행 (약 1~2분 소요)',
                  style: TextStyle(
                    fontSize: 12,
                    color: appTheme.textSecondary,
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
