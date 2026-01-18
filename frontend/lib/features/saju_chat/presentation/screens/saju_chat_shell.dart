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
import '../widgets/persona_selector/persona_selector.dart';
import '../providers/persona_provider.dart';
import '../providers/chat_persona_provider.dart';
import '../../domain/models/chat_persona.dart';
import '../../domain/models/ai_persona.dart';
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

  /// 채팅 입력 필드 컨트롤러 (멘션 하이라이트 지원)
  late final MentionTextEditingController _inputController;

  /// 선택된 인연의 targetProfileId (멘션 전송 시 사용)
  String? _pendingTargetProfileId;

  @override
  void initState() {
    super.initState();
    _chatType = ChatType.fromString(widget.chatType);
    _scrollController = ScrollController();
    _inputController = MentionTextEditingController();
    _initializeSession();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _inputController.dispose();
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
  /// 2. 인연 선택 시 @카테고리/이름 형태를 입력 필드에 추가
  /// 3. 사용자가 메시지를 덧붙여 전송하면 궁합 모드로 처리
  Future<void> _handleCompatibilityChat() async {
    final selection = await RelationSelectorSheet.show(context);
    if (selection == null || !mounted) return;

    if (kDebugMode) {
      print('[SajuChatShell] 🎯 인연 선택됨');
      print('   - 선택된 인연: ${selection.relation.displayName}');
      print('   - toProfileId: ${selection.relation.toProfileId}');
      print('   - 멘션: ${selection.mentionText}');
    }

    // 멘션 텍스트를 커서 위치에 삽입 (기존 텍스트 유지)
    setState(() {
      final currentText = _inputController.text;
      final cursorPos = _inputController.selection.baseOffset;

      // 커서 위치가 유효하지 않으면 끝에 추가
      final insertPos = (cursorPos >= 0 && cursorPos <= currentText.length)
          ? cursorPos
          : currentText.length;

      // 멘션 앞뒤에 공백 확보
      final needSpaceBefore = insertPos > 0 && currentText[insertPos - 1] != ' ';
      final needSpaceAfter = insertPos < currentText.length && currentText[insertPos] != ' ';

      final mentionWithSpaces = '${needSpaceBefore ? ' ' : ''}${selection.mentionText}${needSpaceAfter ? ' ' : ''} ';

      // 기존 텍스트에 멘션 삽입
      final newText = currentText.substring(0, insertPos) +
                      mentionWithSpaces +
                      currentText.substring(insertPos);

      _inputController.text = newText;
      _inputController.selection = TextSelection.collapsed(
        offset: insertPos + mentionWithSpaces.length,
      );
      // 선택된 인연의 targetProfileId 저장
      _pendingTargetProfileId = selection.relation.toProfileId;
    });
  }

  /// 다중 궁합 채팅 시작 (Phase 50: 2~4명 선택)
  ///
  /// 1. RelationSelectorSheet.showMulti() 표시
  /// 2. 여러 명 선택 + "나 포함/제외" 토글
  /// 3. 선택 완료 시 MultiCompatibilityAnalysisService로 분석 시작
  Future<void> _handleMultiCompatibilityChat() async {
    final multiSelection = await RelationSelectorSheet.showMulti(context);
    if (multiSelection == null || !mounted) return;

    if (kDebugMode) {
      print('[SajuChatShell] 🎯 다중 인연 선택됨');
      print('   - 선택된 인연 수: ${multiSelection.relations.length}명');
      print('   - 나 포함: ${multiSelection.includesOwner}');
      print('   - 참가자 IDs: ${multiSelection.participantIds}');
      print('   - 멘션: ${multiSelection.combinedMentionText}');
    }

    // 다중 멘션 텍스트를 입력 필드에 삽입
    setState(() {
      final mentionText = multiSelection.combinedMentionText;
      final prefix = multiSelection.includesOwner ? '[나 포함] ' : '[나 제외] ';
      _inputController.text = '$prefix$mentionText ';
      _inputController.selection = TextSelection.collapsed(
        offset: _inputController.text.length,
      );

      // 다중 궁합용 데이터 저장 (추후 sendMessage에서 사용)
      _pendingMultiSelection = multiSelection;
    });
  }

  /// 다중 인연 선택 데이터 (sendMessage 전달용)
  MultiRelationSelection? _pendingMultiSelection;

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
          // 인연 선택 버튼 (1명 - 기존)
          IconButton(
            icon: const Icon(Icons.person_add_outlined),
            onPressed: _handleCompatibilityChat,
            tooltip: '1:1 궁합',
          ),
          // 다중 궁합 버튼 (2~4명 - Phase 50)
          IconButton(
            icon: const Icon(Icons.group_add_outlined),
            onPressed: _handleMultiCompatibilityChat,
            tooltip: '다중 궁합 (2~4명)',
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
        inputController: _inputController,
        pendingTargetProfileId: _pendingTargetProfileId,
        pendingMultiSelection: _pendingMultiSelection,
        onMentionSent: () => setState(() {
          _pendingTargetProfileId = null;
          _pendingMultiSelection = null;
        }),
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
                      // 인연 선택 버튼 (1명 - 기존)
                      IconButton(
                        icon: Icon(Icons.person_add_outlined, color: appTheme.textPrimary),
                        onPressed: _handleCompatibilityChat,
                        tooltip: '1:1 궁합',
                      ),
                      // 다중 궁합 버튼 (2~4명 - Phase 50)
                      IconButton(
                        icon: Icon(Icons.group_add_outlined, color: appTheme.textPrimary),
                        onPressed: _handleMultiCompatibilityChat,
                        tooltip: '다중 궁합 (2~4명)',
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
                    inputController: _inputController,
                    pendingTargetProfileId: _pendingTargetProfileId,
                    pendingMultiSelection: _pendingMultiSelection,
                    onMentionSent: () => setState(() {
                      _pendingTargetProfileId = null;
                      _pendingMultiSelection = null;
                    }),
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

  /// 외부 입력 필드 컨트롤러 (멘션 삽입용)
  final TextEditingController? inputController;

  /// 멘션으로 선택된 인연의 targetProfileId (단일 궁합)
  final String? pendingTargetProfileId;

  /// 다중 인연 선택 데이터 (Phase 50: 다중 궁합)
  final MultiRelationSelection? pendingMultiSelection;

  /// 멘션 전송 완료 후 콜백 (targetProfileId 초기화용)
  final VoidCallback? onMentionSent;

  const _ChatContent({
    required this.chatType,
    required this.scrollController,
    required this.onScroll,
    this.onCreateSession,
    this.targetProfileId,
    this.inputController,
    this.pendingTargetProfileId,
    this.pendingMultiSelection,
    this.onMentionSent,
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
            controller: widget.inputController,
            onSend: (text) async {
              // 멘션 패턴 감지: @카테고리/이름
              final mentionPattern = RegExp(r'@[^\s/]+/[^\s]+');
              final hasMention = mentionPattern.hasMatch(text);
              final targetId = hasMention ? widget.pendingTargetProfileId : widget.targetProfileId;

              print('[_ChatContent] 세션 생성 요청: text=$text, hasMention=$hasMention, targetProfileId=$targetId');

              final activeProfile = await ref.read(activeProfileProvider.future);
              ref.read(chatSessionNotifierProvider.notifier)
                  .createSession(
                    widget.chatType,
                    activeProfile?.id,
                    initialMessage: text,
                    targetProfileId: targetId,
                  );

              // 멘션 전송 완료 시 콜백 호출
              if (hasMention && widget.onMentionSent != null) {
                widget.onMentionSent!();
              }
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
        // 페르소나 가로 선택기 (원형 이모지 리스트)
        const _PersonaHorizontalSelector(),
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
          controller: widget.inputController,
          onSend: (text) {
            // 다중 궁합 감지: [나 포함] 또는 [나 제외] prefix
            final isMultiCompatibility = text.startsWith('[나 포함]') || text.startsWith('[나 제외]');

            // 멘션 패턴 감지: @카테고리/이름
            final mentionPattern = RegExp(r'@[^\s/]+/[^\s]+');
            final hasMention = mentionPattern.hasMatch(text);

            if (isMultiCompatibility && widget.pendingMultiSelection != null) {
              // 다중 궁합 모드
              final multiSelection = widget.pendingMultiSelection!;
              print('[_ChatContent] 다중 궁합 메시지 전송: sessionId=$currentSessionId, text=$text');
              print('  - participantIds: ${multiSelection.participantIds}');
              print('  - includesOwner: ${multiSelection.includesOwner}');

              ref
                  .read(chatNotifierProvider(currentSessionId).notifier)
                  .sendMessage(
                    text,
                    widget.chatType,
                    multiParticipantIds: multiSelection.participantIds,
                    includesOwner: multiSelection.includesOwner,
                  );

              // 멘션 전송 완료 시 콜백 호출
              if (widget.onMentionSent != null) {
                widget.onMentionSent!();
              }
            } else {
              // 단일 궁합 또는 일반 채팅 모드
              // 멘션이 있으면 pendingTargetProfileId 사용, 없으면 기존 effectiveTargetProfileId 사용
              final targetId = hasMention ? widget.pendingTargetProfileId : effectiveTargetProfileId;

              print('[_ChatContent] 메시지 전송: sessionId=$currentSessionId, text=$text, hasMention=$hasMention, targetProfileId=$targetId');
              ref
                  .read(chatNotifierProvider(currentSessionId).notifier)
                  .sendMessage(text, widget.chatType, targetProfileId: targetId);

              // 멘션 전송 완료 시 콜백 호출
              if (hasMention && widget.onMentionSent != null) {
                widget.onMentionSent!();
              }
            }
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

/// 페르소나 가로 선택기 (채팅 화면 상단)
///
/// 5개 페르소나 선택:
/// - BasePerson 1개 (MBTI 4축 조절 가능)
/// - SpecialCharacter 4개 (MBTI 조절 불가, 고정 성격)
///
/// ## 위젯 트리 분리
/// ```
/// 대화창: 🎭 👶 🗣️ 👴 😱 (5개 선택지)
/// 사이드바: MBTI 4축 선택기 (Base 선택 시만 활성화)
/// ```
class _PersonaHorizontalSelector extends ConsumerWidget {
  const _PersonaHorizontalSelector();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentPersona = ref.watch(chatPersonaNotifierProvider);
    final currentQuadrant = ref.watch(mbtiQuadrantNotifierProvider);
    final canAdjustMbti = ref.watch(canAdjustMbtiProvider);
    final appTheme = context.appTheme;

    // MBTI 분면별 색상 (BasePerson 선택 시)
    final quadrantColor = canAdjustMbti ? _getQuadrantColor(currentQuadrant) : appTheme.primaryColor;

    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: appTheme.cardColor,
        border: Border(
          bottom: BorderSide(
            color: appTheme.primaryColor.withValues(alpha: 0.1),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          // 현재 MBTI 표시 (BasePerson 선택 시만)
          if (canAdjustMbti)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: quadrantColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: quadrantColor.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    currentQuadrant.name,
                    style: TextStyle(
                      color: quadrantColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    currentQuadrant.displayName,
                    style: TextStyle(
                      color: quadrantColor.withValues(alpha: 0.8),
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
            ),
          if (canAdjustMbti) const SizedBox(width: 12),
          // 5개 페르소나 원형 리스트
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: ChatPersona.values.map((persona) {
                return _buildPersonaCircle(
                  context,
                  ref,
                  persona,
                  isSelected: persona == currentPersona,
                  accentColor: quadrantColor,
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonaCircle(
    BuildContext context,
    WidgetRef ref,
    ChatPersona persona, {
    required bool isSelected,
    required Color accentColor,
  }) {
    final appTheme = context.appTheme;
    final isBase = persona == ChatPersona.basePerson;

    return Tooltip(
      message: '${persona.displayName}\n${persona.description}',
      child: GestureDetector(
        onTap: () {
          ref.read(chatPersonaNotifierProvider.notifier).setPersona(persona);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isSelected
                ? accentColor.withValues(alpha: 0.2)
                : appTheme.cardColor,
            border: Border.all(
              color: isSelected
                  ? accentColor
                  : isBase
                      ? appTheme.primaryColor.withValues(alpha: 0.4)
                      : appTheme.primaryColor.withValues(alpha: 0.2),
              width: isSelected ? 2.5 : isBase ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: accentColor.withValues(alpha: 0.3),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              persona.emoji,
              style: const TextStyle(fontSize: 26),
            ),
          ),
        ),
      ),
    );
  }

  Color _getQuadrantColor(MbtiQuadrant quadrant) {
    switch (quadrant) {
      case MbtiQuadrant.NF:
        return const Color(0xFFE63946);
      case MbtiQuadrant.NT:
        return const Color(0xFF457B9D);
      case MbtiQuadrant.SF:
        return const Color(0xFF2A9D8F);
      case MbtiQuadrant.ST:
        return const Color(0xFFF4A261);
    }
  }
}
