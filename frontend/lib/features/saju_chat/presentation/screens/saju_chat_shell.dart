import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../ad/ad.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../router/routes.dart';
import '../../domain/models/chat_type.dart';
import '../../domain/services/mention_parser.dart';
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
import '../../../profile/presentation/providers/relation_provider.dart';
import '../../../profile/data/models/profile_relation_model.dart';

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

    // 세션이 없으면 기본 세션 생성 (현재 페르소나 저장)
    if (sessionState.sessions.isEmpty) {
      final currentPersona = ref.read(chatPersonaNotifierProvider);
      final currentMbti = ref.read(mbtiQuadrantNotifierProvider);
      await sessionNotifier.createSession(
        _chatType,
        profileId,
        chatPersona: currentPersona,
        mbtiQuadrant: currentMbti,
      );
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
    // 현재 선택된 페르소나를 새 세션에 저장
    final currentPersona = ref.read(chatPersonaNotifierProvider);
    final currentMbti = ref.read(mbtiQuadrantNotifierProvider);
    await sessionNotifier.createSession(
      _chatType,
      activeProfile?.id,
      chatPersona: currentPersona,
      mbtiQuadrant: currentMbti,
    );
  }

  /// 단일 인연 멘션 (채팅 중 @멘션용)
  ///
  /// 1. RelationSelectorSheet 표시
  /// 2. 인연 선택 시 @카테고리/이름 형태를 입력 필드에 추가
  /// 3. 사용자가 메시지를 덧붙여 전송하면 해당 인연과의 궁합 모드로 처리
  Future<void> _handleSingleMention() async {
    final selection = await RelationSelectorSheet.show(context);
    if (selection == null || !mounted) return;

    if (kDebugMode) {
      print('[SajuChatShell] 🎯 인연 선택됨 (단일 멘션)');
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

  /// 궁합 채팅 시작 (v5.0: 항상 2명만 - 합충형해파는 1:1 관계)
  ///
  /// 1. RelationSelectorSheet.showForCompatibility() 표시
  /// 2. 딱 2명만 선택 (나 포함: 나+1명, 나 제외: 2명)
  /// 3. 선택 완료 시 CompatibilityAnalysisService로 분석 시작
  Future<void> _handleCompatibilityChat() async {
    final selection = await RelationSelectorSheet.showForCompatibility(context);
    if (selection == null || !mounted) return;

    if (kDebugMode) {
      print('[SajuChatShell] 🎯 궁합 인연 선택됨 (2명)');
      print('   - 선택된 인연: ${selection.relations.length}명');
      print('   - 나 포함: ${selection.includesOwner}');
      print('   - 참가자 IDs: ${selection.participantIds}');
      print('   - 멘션: ${selection.combinedMentionText}');
    }

    // 멘션 텍스트를 입력 필드에 삽입
    setState(() {
      final mentionText = selection.combinedMentionText;
      final prefix = selection.includesOwner ? '[나 포함] ' : '[나 제외] ';
      _inputController.text = '$prefix$mentionText ';
      _inputController.selection = TextSelection.collapsed(
        offset: _inputController.text.length,
      );

      // 궁합용 데이터 저장 (추후 sendMessage에서 사용)
      _pendingCompatibilitySelection = selection;
    });
  }

  /// 궁합 인연 선택 데이터 (sendMessage 전달용) - 항상 2명
  CompatibilitySelection? _pendingCompatibilitySelection;

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

  /// 모바일 채팅 메뉴 표시 (햄버거 버튼)
  void _showChatMenu(BuildContext context) {
    final appTheme = context.appTheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: appTheme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 핸들바
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: appTheme.textMuted.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            // 새 채팅
            ListTile(
              leading: Icon(Icons.add_comment_outlined, color: appTheme.primaryColor),
              title: Text('새 채팅', style: TextStyle(color: appTheme.textPrimary)),
              subtitle: Text('새로운 대화 시작', style: TextStyle(color: appTheme.textSecondary, fontSize: 12)),
              onTap: () {
                Navigator.pop(sheetContext);
                _handleNewChat();
              },
            ),
            // 채팅 기록
            ListTile(
              leading: Icon(Icons.history, color: appTheme.textPrimary),
              title: Text('채팅 기록', style: TextStyle(color: appTheme.textPrimary)),
              subtitle: Text('이전 대화 기록 보기', style: TextStyle(color: appTheme.textSecondary, fontSize: 12)),
              onTap: () {
                Navigator.pop(sheetContext);
                _scaffoldKey.currentState?.openDrawer();
              },
            ),
            Divider(color: appTheme.textMuted.withOpacity(0.2)),
            // 메인으로 돌아가기
            ListTile(
              leading: Icon(Icons.home_outlined, color: appTheme.textPrimary),
              title: Text('메인으로', style: TextStyle(color: appTheme.textPrimary)),
              subtitle: Text('메인 화면으로 이동', style: TextStyle(color: appTheme.textSecondary, fontSize: 12)),
              onTap: () {
                Navigator.pop(sheetContext);
                context.go(Routes.menu);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
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
          icon: const Icon(Icons.menu),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
          tooltip: '메뉴',
        ),
        title: Text(
          currentSession?.title ?? _chatType.title,
          style: TextStyle(color: appTheme.textPrimary),
        ),
        actions: [
          // 궁합 버튼 (2명 선택)
          IconButton(
            icon: const Icon(Icons.group_add_outlined),
            onPressed: _handleCompatibilityChat,
            tooltip: '궁합 보기',
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
          onDeleteCurrentSession: _handleSessionDeleted,
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
        pendingCompatibilitySelection: _pendingCompatibilitySelection,
        onMentionSent: () => setState(() {
          _pendingTargetProfileId = null;
          _pendingCompatibilitySelection = null;
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
      body: SafeArea(
        child: Row(
          children: [
            // 사이드바 (토글 가능)
            if (_isSidebarVisible) ...[
              ChatHistorySidebar(
                onNewChat: _handleNewChat,
                onSessionSelected: _handleSessionSelected,
                onSessionDeleted: _handleSessionDeleted,
                onSessionRenamed: _handleSessionRenamed,
                onDeleteCurrentSession: _handleSessionDeleted,
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
                      // 햄버거 메뉴 (새 채팅, 메인으로 이동, 사이드바 토글)
                      PopupMenuButton<String>(
                        icon: Icon(Icons.menu, color: appTheme.textPrimary),
                        tooltip: '메뉴',
                        color: appTheme.cardColor,
                        onSelected: (value) {
                          switch (value) {
                            case 'new_chat':
                              _handleNewChat();
                              break;
                            case 'go_main':
                              context.go(Routes.menu);
                              break;
                            case 'toggle_sidebar':
                              setState(() {
                                _isSidebarVisible = !_isSidebarVisible;
                              });
                              break;
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'new_chat',
                            child: Row(
                              children: [
                                Icon(Icons.add_comment_outlined, color: appTheme.textPrimary, size: 20),
                                const SizedBox(width: 12),
                                Text('새 채팅', style: TextStyle(color: appTheme.textPrimary)),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'go_main',
                            child: Row(
                              children: [
                                Icon(Icons.home_outlined, color: appTheme.textPrimary, size: 20),
                                const SizedBox(width: 12),
                                Text('메인으로', style: TextStyle(color: appTheme.textPrimary)),
                              ],
                            ),
                          ),
                          const PopupMenuDivider(),
                          PopupMenuItem(
                            value: 'toggle_sidebar',
                            child: Row(
                              children: [
                                Icon(
                                  _isSidebarVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                  color: appTheme.textPrimary,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  _isSidebarVisible ? '사이드바 숨기기' : '사이드바 보기',
                                  style: TextStyle(color: appTheme.textPrimary),
                                ),
                              ],
                            ),
                          ),
                        ],
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
                      // 궁합 버튼 (2명 선택)
                      IconButton(
                        icon: Icon(Icons.group_add_outlined, color: appTheme.textPrimary),
                        onPressed: _handleCompatibilityChat,
                        tooltip: '궁합 보기',
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
                    pendingCompatibilitySelection: _pendingCompatibilitySelection,
                    onMentionSent: () => setState(() {
                      _pendingTargetProfileId = null;
                      _pendingCompatibilitySelection = null;
                    }),
                  ),
                ),
              ],
            ),
          ),
        ],
        ),
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

  /// 궁합 인연 선택 데이터 (v5.0: 항상 2명만)
  final CompatibilitySelection? pendingCompatibilitySelection;

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
    this.pendingCompatibilitySelection,
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

              // targetProfileId 및 participantIds 결정
              String? targetId;
              List<String>? participantIds;
              bool includesOwner = true; // 기본값: "나 포함"

              // 1. UI 선택으로 pendingCompatibilitySelection이 있으면 우선 사용
              if (widget.pendingCompatibilitySelection != null) {
                final selection = widget.pendingCompatibilitySelection!;
                // targetProfileId: 항상 상대방 ID
                // - 나 포함: relations의 첫 번째 = 상대방
                // - 나 제외: relations의 두 번째 = 상대방 (첫 번째는 기준 인물)
                targetId = selection.targetProfileId;
                participantIds = selection.participantIds;
                includesOwner = selection.includesOwner;
                print('[_ChatContent] UI 선택 궁합 모드: participantIds=$participantIds, targetId=$targetId, includesOwner=$includesOwner');
              }
              // 2. UI 선택 없이 직접 타이핑한 멘션이 있으면 파싱
              else if (hasMention) {
                final activeProfile = await ref.read(activeProfileProvider.future);
                if (activeProfile != null) {
                  // 인연 목록 가져오기
                  final relationsAsync = await ref.read(relationListProvider(activeProfile.id).future);

                  // 멘션 파싱
                  final parser = MentionParser(
                    ownerProfileId: activeProfile.id,
                    ownerName: activeProfile.displayName,
                    relations: relationsAsync,
                  );
                  final parseResult = parser.parse(text);

                  print('[_ChatContent] 멘션 파싱 결과: mentions=${parseResult.mentions.length}, includesOwner=${parseResult.includesOwner}, targetId=${parseResult.targetProfileId}');

                  // 파싱된 targetProfileId 사용
                  targetId = parseResult.targetProfileId;
                  participantIds = parseResult.participantIds;
                  includesOwner = parseResult.includesOwner;

                  // 파싱 실패 시 UI 선택된 값 사용
                  if (targetId == null && widget.pendingTargetProfileId != null) {
                    targetId = widget.pendingTargetProfileId;
                    print('[_ChatContent] 파싱 실패, UI 선택 값 사용: $targetId');
                  }
                }
              }
              // 3. 기본값
              else {
                targetId = widget.targetProfileId;
              }

              print('[_ChatContent] 세션 생성 요청: text=$text, hasMention=$hasMention, targetProfileId=$targetId, participantIds=$participantIds, includesOwner=$includesOwner');

              final activeProfile = await ref.read(activeProfileProvider.future);
              // 현재 선택된 페르소나를 세션에 저장
              final currentPersona = ref.read(chatPersonaNotifierProvider);
              final currentMbti = ref.read(mbtiQuadrantNotifierProvider);
              ref.read(chatSessionNotifierProvider.notifier)
                  .createSession(
                    widget.chatType,
                    activeProfile?.id,
                    initialMessage: text,
                    targetProfileId: targetId,
                    participantIds: participantIds,
                    includesOwner: includesOwner,
                    chatPersona: currentPersona,
                    mbtiQuadrant: currentMbti,
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
    final pendingParticipantIds = sessionState.pendingParticipantIds;
    final pendingIncludesOwner = sessionState.pendingIncludesOwner;
    if (pendingMessage != null && pendingMessage.isNotEmpty && !_isProcessingPendingMessage) {
      print('[_ChatContent] pendingMessage 발견: $pendingMessage, sessionId=$currentSessionId, pendingParticipantIds=$pendingParticipantIds, pendingIncludesOwner=$pendingIncludesOwner');
      _isProcessingPendingMessage = true;

      // 다음 프레임에서 실행 (build 중 state 변경 방지)
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        print('[_ChatContent] postFrameCallback에서 sendMessage 호출, targetProfileId=$effectiveTargetProfileId, participantIds=$pendingParticipantIds, includesOwner=$pendingIncludesOwner');

        final msg = pendingMessage; // 캡처
        final targetId = effectiveTargetProfileId; // 캡처
        final participantIds = pendingParticipantIds; // 캡처
        final includesOwner = pendingIncludesOwner; // 캡처
        ref.read(chatSessionNotifierProvider.notifier).clearPendingMessage();
        ref.read(chatNotifierProvider(currentSessionId).notifier)
            .sendMessage(msg, widget.chatType, targetProfileId: targetId, multiParticipantIds: participantIds, includesOwner: includesOwner);

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

    // 가로 모드 체크 (화면 높이가 400 미만이면 가로 모드로 간주)
    final isLandscape = MediaQuery.of(context).size.height < 400;

    // 상단 요소들 (가로 모드에서는 컴팩트하게)
    final topWidgets = <Widget>[
      const DisclaimerBanner(),
      // 페르소나 가로 선택기 (원형 이모지 리스트)
      const _PersonaHorizontalSelector(),
      // GPT-5.2 상세 분석 로딩 배너 (첫 프로필 분석 시 ~2분 소요)
      if (chatState.isDeepAnalysisRunning)
        const _DeepAnalysisLoadingBanner(),
    ];

    return Column(
      children: [
        // 가로 모드: 상단 요소들을 축소 가능한 영역으로 감싸기
        if (isLandscape)
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 60),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: topWidgets,
              ),
            ),
          )
        else
          ...topWidgets,
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
          onSend: (text) async {
            // 멘션 패턴 감지: @카테고리/이름
            final mentionPattern = RegExp(r'@[^\s/]+/[^\s]+');
            final hasMention = mentionPattern.hasMatch(text);

            // targetProfileId 및 participantIds 결정
            String? targetId;
            List<String>? participantIds;
            bool includesOwner = true; // 기본값: "나 포함"

            // 1. UI 선택으로 pendingCompatibilitySelection이 있으면 우선 사용
            if (widget.pendingCompatibilitySelection != null) {
              final selection = widget.pendingCompatibilitySelection!;
              // targetProfileId: 항상 상대방 ID (나 제외)
              targetId = selection.targetProfileId;
              participantIds = selection.participantIds;
              includesOwner = selection.includesOwner;
              print('[_ChatContent] UI 선택 궁합 메시지 전송: targetId=$targetId, participantIds=$participantIds, includesOwner=$includesOwner');
            }
            // 2. UI 선택 없이 직접 타이핑한 멘션이 있으면 파싱
            else if (hasMention) {
              final activeProfile = await ref.read(activeProfileProvider.future);
              if (activeProfile != null) {
                // Phase 56-57: 향상된 멘션 파싱 로직
                // "[나 제외]" 패턴 또는 두 멘션 모두 "나"가 아닌 경우 감지
                final isExcludeOwnerMode = text.contains('[나 제외]') || text.contains('나 제외');

                // 모든 멘션 추출
                final allMentions = RegExp(r'@([^\s/]+)/([^\s@]+)').allMatches(text).toList();
                final hasOwnerMention = allMentions.any((m) => m.group(1) == '나');

                // "나 제외" 모드: 두 멘션 모두 "나"가 아니거나, 명시적으로 [나 제외] 포함
                final isThirdPartyMode = isExcludeOwnerMode ||
                    (allMentions.length >= 2 && !hasOwnerMention);

                print('[_ChatContent] Phase 57: isThirdPartyMode=$isThirdPartyMode, isExcludeOwnerMode=$isExcludeOwnerMode, hasOwnerMention=$hasOwnerMention, mentionCount=${allMentions.length}');

                if (isThirdPartyMode && allMentions.length >= 2) {
                  // "나 제외" 모드: 두 사람 모두 관계 목록에서 ID 찾기
                  final relations = await ref.read(relationListProvider(activeProfile.id).future);

                  final List<String> foundIds = [];
                  for (final match in allMentions) {
                    final category = match.group(1) ?? '';
                    final name = match.group(2) ?? '';

                    // 이름으로 관계에서 프로필 ID 찾기
                    String? profileId;
                    for (final relation in relations) {
                      final displayName = relation.displayName ?? relation.toProfile?.displayName ?? '';
                      if (displayName == name || displayName.contains(name) || name.contains(displayName)) {
                        profileId = relation.toProfileId;
                        break;
                      }
                    }

                    if (profileId != null) {
                      foundIds.add(profileId);
                      print('[_ChatContent] Phase 57: @$category/$name → profileId=$profileId');
                    } else {
                      print('[_ChatContent] Phase 57: @$category/$name → 찾기 실패');
                    }
                  }

                  if (foundIds.length >= 2) {
                    participantIds = foundIds.take(2).toList();
                    targetId = participantIds.first;
                    includesOwner = false;
                    print('[_ChatContent] Phase 57: 나 제외 궁합 - participantIds=$participantIds');
                  } else {
                    print('[_ChatContent] Phase 57: 나 제외 모드이지만 2명 찾기 실패 (found=${foundIds.length})');
                  }
                } else {
                  // 기존 로직: "나 포함" 모드 또는 단일 멘션
                  // Phase 56: 2단계 파싱 로직
                  // 1단계: 첫 번째 멘션 추출하여 "기준 인물" 파악
                  final firstMention = MentionParser.extractFirstMention(text);

                  String ownerProfileId = activeProfile.id;
                  String ownerName = activeProfile.displayName;
                  List<ProfileRelationModel> relations = await ref.read(relationListProvider(activeProfile.id).future);

                  // 2단계: @나/XXX 형태이고 XXX가 로그인 사용자와 다르면
                  // → XXX의 관계 목록으로 재조회
                  if (firstMention.isOwnerCategory &&
                      firstMention.name != null &&
                      firstMention.name != activeProfile.displayName) {

                    print('[_ChatContent] Phase 56: 기준 인물 변경 감지 - ${firstMention.name}');

                    // 로그인 사용자의 관계 목록에서 기준 인물(예: 박재현) 프로필 ID 찾기
                    final tempParser = MentionParser(
                      ownerProfileId: activeProfile.id,
                      ownerName: activeProfile.displayName,
                      relations: relations,
                    );
                    final baseProfileId = tempParser.findProfileIdByName(firstMention.name!);

                    if (baseProfileId != null) {
                      // 기준 인물의 관계 목록 재조회
                      final baseRelations = await ref.read(relationListProvider(baseProfileId).future);

                      print('[_ChatContent] Phase 56: 기준 인물 관계 재조회 - ${firstMention.name} (${baseRelations.length}명)');

                      // 기준 인물 정보로 교체
                      ownerProfileId = baseProfileId;
                      ownerName = firstMention.name!;
                      relations = baseRelations;
                    } else {
                      print('[_ChatContent] Phase 56: 기준 인물 프로필 ID 찾기 실패 - ${firstMention.name}');
                    }
                  }

                  // 멘션 파싱 (기준 인물 기준)
                  final parser = MentionParser(
                    ownerProfileId: ownerProfileId,
                    ownerName: ownerName,
                    relations: relations,
                  );
                  final parseResult = parser.parse(text);

                  print('[_ChatContent] 멘션 파싱 결과: mentions=${parseResult.mentions.length}, targetId=${parseResult.targetProfileId}, includesOwner=${parseResult.includesOwner}');

                  // 파싱된 targetProfileId 및 participantIds 사용
                  targetId = parseResult.targetProfileId;
                  participantIds = parseResult.participantIds;
                  includesOwner = parseResult.includesOwner;
                }

                // 파싱 실패 시 UI 선택된 값 또는 세션 값 사용
                if (targetId == null) {
                  targetId = widget.pendingTargetProfileId ?? effectiveTargetProfileId;
                  print('[_ChatContent] 파싱 실패, fallback 값 사용: $targetId');
                }
              }
            }
            // 3. 기본값 (세션에 저장된 targetProfileId)
            else {
              targetId = effectiveTargetProfileId;
            }

            // v6.0 (Phase 57): 단순화된 파라미터 전달
            // - 궁합 모드: compatibilityParticipantIds로 2명의 ID 전달
            // - 일반 모드: 파라미터 없이 전달 (owner 사주 사용)
            print('');
            print('╔══════════════════════════════════════════════════════════════╗');
            print('║  [_ChatContent] 메시지 전송 준비                              ║');
            print('╚══════════════════════════════════════════════════════════════╝');
            print('  sessionId: $currentSessionId');
            print('  text: $text');
            print('  hasMention: $hasMention');
            print('  pendingCompatibilitySelection: ${widget.pendingCompatibilitySelection != null}');
            print('  participantIds: $participantIds');
            print('  targetId: $targetId');
            print('  includesOwner: $includesOwner');
            ref
                .read(chatNotifierProvider(currentSessionId).notifier)
                .sendMessage(
                  text,
                  widget.chatType,
                  compatibilityParticipantIds: participantIds,
                  // 하위 호환: participantIds가 없을 때만 targetId 사용
                  targetProfileId: participantIds == null ? targetId : null,
                );

            // 멘션 전송 완료 시 콜백 호출
            if (hasMention && widget.onMentionSent != null) {
              widget.onMentionSent!();
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
/// 모바일: MBTI 버튼 탭 시 BottomSheet로 4축 선택기 표시
/// ```
class _PersonaHorizontalSelector extends ConsumerWidget {
  const _PersonaHorizontalSelector();

  /// MBTI 4축 선택기 BottomSheet 표시
  void _showMbtiSelectorSheet(BuildContext context, WidgetRef ref) {
    final appTheme = context.appTheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: appTheme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (sheetContext) => Consumer(
        builder: (consumerContext, consumerRef, _) {
          final currentQuadrant = consumerRef.watch(mbtiQuadrantNotifierProvider);
          final quadrantColor = _getQuadrantColor(currentQuadrant);

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 핸들바
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: appTheme.textMuted.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // 제목
                  Text(
                    'AI 성향 선택 (MBTI)',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: appTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '터치하거나 드래그해서 성향을 선택하세요',
                    style: TextStyle(
                      fontSize: 13,
                      color: appTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // MBTI 4축 선택기
                  MbtiAxisSelector(
                    selectedQuadrant: currentQuadrant,
                    onQuadrantSelected: (quadrant) {
                      consumerRef.read(mbtiQuadrantNotifierProvider.notifier).setQuadrant(quadrant);
                      // 메시지 없는 세션이면 세션의 MBTI도 업데이트
                      consumerRef.read(chatSessionNotifierProvider.notifier)
                          .updateCurrentSessionPersona(mbtiQuadrant: quadrant);
                    },
                    size: 300,
                  ),
                  const SizedBox(height: 24),
                  // 선택된 분면 표시 (실시간 업데이트)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    decoration: BoxDecoration(
                      color: quadrantColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: quadrantColor.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: quadrantColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              currentQuadrant.displayName,
                              style: TextStyle(
                                color: quadrantColor,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              currentQuadrant.description,
                              style: TextStyle(
                                color: quadrantColor.withValues(alpha: 0.8),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentPersona = ref.watch(chatPersonaNotifierProvider);
    final currentQuadrant = ref.watch(mbtiQuadrantNotifierProvider);
    final canAdjustMbti = ref.watch(canAdjustMbtiProvider);
    final appTheme = context.appTheme;

    // 현재 세션의 메시지 수 확인 (대화 시작 후 페르소나 잠금)
    final sessionState = ref.watch(chatSessionNotifierProvider);
    final currentSessionId = sessionState.currentSessionId;
    final hasMessages = currentSessionId != null
        ? ref.watch(chatNotifierProvider(currentSessionId)).messages.isNotEmpty
        : false;

    // 페르소나 잠금 상태: 메시지가 있으면 변경 불가
    final isPersonaLocked = hasMessages;

    // MBTI 분면별 색상 (BasePerson 선택 시)
    final quadrantColor = canAdjustMbti ? _getQuadrantColor(currentQuadrant) : appTheme.primaryColor;

    // 페르소나 아이템 크기 계산용 상수
    const double circleSize = 44;
    const double containerPadding = 16;

    return Container(
      height: 90,
      padding: const EdgeInsets.symmetric(horizontal: containerPadding, vertical: 6),
      decoration: BoxDecoration(
        color: appTheme.cardColor.withValues(alpha: 0.8),
      ),
      child: Row(
        children: [
          // 왼쪽: MBTI 버튼 영역 (항상 같은 공간 차지)
          SizedBox(
            width: 56,
            child: (canAdjustMbti && !isPersonaLocked)
                ? Align(
                    alignment: Alignment.centerLeft,
                    child: _buildMbtiButton(
                      context,
                      ref,
                      quadrantColor: quadrantColor,
                      currentQuadrant: currentQuadrant,
                    ),
                  )
                : null,
          ),
          // 중앙: 페르소나 목록
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: ChatPersona.visibleValues.map((persona) {
                    final isSelected = persona == currentPersona;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: _buildPersonaCircle(
                        context,
                        ref,
                        persona,
                        isSelected: isSelected,
                        accentColor: quadrantColor,
                        size: circleSize,
                        isLocked: isPersonaLocked,
                        onTapSelected: (canAdjustMbti && isSelected && !isPersonaLocked)
                            ? () => _showMbtiSelectorSheet(context, ref)
                            : null,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
          // 오른쪽: 대칭을 위한 빈 공간
          const SizedBox(width: 56),
        ],
      ),
    );
  }

  /// MBTI 버튼 빌드 (왼쪽 고정 위치)
  Widget _buildMbtiButton(
    BuildContext context,
    WidgetRef ref, {
    required Color quadrantColor,
    required MbtiQuadrant currentQuadrant,
  }) {
    return GestureDetector(
      onTap: () => _showMbtiSelectorSheet(context, ref),
      child: Tooltip(
        message: 'AI 성향 변경 (${currentQuadrant.displayName})',
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: quadrantColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: quadrantColor.withValues(alpha: 0.4),
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.tune_rounded,
                size: 18,
                color: quadrantColor,
              ),
              const SizedBox(height: 2),
              Text(
                currentQuadrant.name,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: quadrantColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPersonaCircle(
    BuildContext context,
    WidgetRef ref,
    ChatPersona persona, {
    required bool isSelected,
    required Color accentColor,
    double size = 44,
    bool isLocked = false,
    VoidCallback? onTapSelected,
  }) {
    final appTheme = context.appTheme;
    final iconSize = (size * 0.5).clamp(18.0, 22.0); // 16-20 → 18-22

    final displayName = persona.shortName;

    // 잠금 상태: 선택된 페르소나만 활성화 표시, 나머지는 흐리게
    final isDisabled = isLocked && !isSelected;
    final tooltipMessage = isLocked && !isSelected
        ? '새 채팅에서 변경 가능'
        : '${persona.displayName}\n${persona.description}';

    return Tooltip(
      message: tooltipMessage,
      child: GestureDetector(
        onTap: isLocked
            ? null // 잠금 상태면 탭 무시
            : () {
                if (isSelected && onTapSelected != null) {
                  // 이미 선택된 상태에서 탭하면 onTapSelected 콜백 호출
                  onTapSelected();
                } else {
                  ref.read(chatPersonaNotifierProvider.notifier).setPersona(persona);
                  // 메시지 없는 세션이면 세션의 페르소나도 업데이트
                  ref.read(chatSessionNotifierProvider.notifier)
                      .updateCurrentSessionPersona(chatPersona: persona);
                }
              },
        child: Opacity(
          opacity: isDisabled ? 0.4 : 1.0,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected
                      ? accentColor.withValues(alpha: 0.15)
                      : appTheme.backgroundColor.withValues(alpha: 0.3),
                  border: Border.all(
                    color: isSelected
                        ? accentColor.withValues(alpha: 0.5)
                        : appTheme.textMuted.withValues(alpha: 0.15),
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Center(
                  child: Icon(
                    persona.icon,
                    size: iconSize,
                    color: isSelected
                        ? accentColor
                        : appTheme.textMuted.withValues(alpha: 0.6),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                displayName,
                style: TextStyle(
                  fontSize: 12, // 11 → 12
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected
                      ? accentColor
                      : appTheme.textMuted.withValues(alpha: 0.8),
                  letterSpacing: -0.3,
                ),
              ),
            ],
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
