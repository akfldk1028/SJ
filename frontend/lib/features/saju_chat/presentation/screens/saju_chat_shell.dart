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
// import '../widgets/disclaimer_banner.dart'; // 주석처리: 사주상담 참고용 안내 배너
import '../widgets/error_banner.dart';
import '../widgets/relation_selector_sheet.dart';
import '../widgets/suggested_questions.dart';
import '../widgets/persona_selector/persona_selector.dart';
import '../providers/persona_provider.dart';
import '../providers/chat_persona_provider.dart';
import '../providers/conversational_ad_provider.dart';
import '../../data/models/conversational_ad_model.dart';
import '../../domain/models/chat_persona.dart';
import '../../domain/models/ai_persona.dart';
import '../widgets/conversational_ad_widget.dart';
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

  /// 인연 관계도에서 진입 시 자동 멘션 삽입 여부
  final bool autoMention;

  const SajuChatShell({
    super.key,
    this.chatType,
    this.targetProfileId,
    this.autoMention = false,
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

  /// 사용자가 위로 스크롤한 상태 (자동 스크롤 억제)
  bool _isUserScrolling = false;


  /// 채팅 입력 필드 컨트롤러 (멘션 하이라이트 지원)
  late final MentionTextEditingController _inputController;

  /// 선택된 인연의 targetProfileId (멘션 전송 시 사용)
  String? _pendingTargetProfileId;

  /// 현재 페르소나에 맞는 정확한 mbtiQuadrant 반환
  ///
  /// - MBTI 페르소나 (nfSensitive, ntAnalytic 등): persona 자체의 mbtiQuadrant 사용
  /// - 특수 캐릭터 (babyMonk, sewerSaju 등): null (MBTI 무관)
  /// - 레거시 basePerson: mbtiQuadrantNotifierProvider에서 읽기
  MbtiQuadrant? _resolveCurrentMbtiQuadrant() {
    final currentPersona = ref.read(chatPersonaNotifierProvider);
    if (currentPersona.isMbtiPersona) {
      // MBTI 페르소나는 자체 mbtiQuadrant 사용 (절대 stale 안 됨)
      return currentPersona.mbtiQuadrant;
    } else if (currentPersona.canAdjustMbti) {
      // 레거시 basePerson만 Provider에서 읽기
      return ref.read(mbtiQuadrantNotifierProvider);
    }
    // 특수 캐릭터는 MBTI 없음
    return null;
  }

  @override
  void initState() {
    super.initState();
    _chatType = ChatType.fromString(widget.chatType);
    _scrollController = ScrollController();
    _scrollController.addListener(_onScrollChanged);
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

    // autoMention 모드: 세션 생성을 _autoInsertMention()에서 처리
    // 실패 시 아래 일반 세션 생성 로직으로 fallback
    if (widget.autoMention && widget.targetProfileId != null) {
      final success = await _autoInsertMention();
      if (success) return;
      // fallback: 일반 세션 생성으로 진행
      if (kDebugMode) {
        print('[SajuChatShell] autoMention 실패 → 일반 세션으로 fallback');
      }
    }

    final sessionNotifier = ref.read(chatSessionNotifierProvider.notifier);
    final sessionState = ref.read(chatSessionNotifierProvider);

    // 활성 프로필 ID 가져오기
    final activeProfile = await ref.read(activeProfileProvider.future);
    final profileId = activeProfile?.id;

    // 세션이 없으면 기본 세션 생성 (현재 페르소나 저장)
    if (sessionState.sessions.isEmpty) {
      final currentPersona = ref.read(chatPersonaNotifierProvider);
      await sessionNotifier.createSession(
        _chatType,
        profileId,
        chatPersona: currentPersona,
        mbtiQuadrant: _resolveCurrentMbtiQuadrant(),
      );
    } else if (sessionState.currentSessionId == null) {
      // 세션이 있지만 선택되지 않았으면 첫 번째 세션 선택
      sessionNotifier.selectSession(sessionState.sessions.first.id);
    } else if (_chatType != ChatType.general) {
      // 특정 chatType으로 진입했는데 현재 세션 타입이 다르면 새 세션 생성
      final currentSession = sessionState.sessions
          .where((s) => s.id == sessionState.currentSessionId)
          .firstOrNull;
      if (currentSession != null && currentSession.chatType != _chatType) {
        // 같은 타입의 기존 세션이 있으면 그걸 선택, 없으면 새로 생성
        final matchingSession = sessionState.sessions
            .where((s) => s.chatType == _chatType)
            .firstOrNull;
        if (matchingSession != null) {
          sessionNotifier.selectSession(matchingSession.id);
        } else {
          final currentPersona = ref.read(chatPersonaNotifierProvider);
          await sessionNotifier.createSession(
            _chatType,
            profileId,
            chatPersona: currentPersona,
            mbtiQuadrant: _resolveCurrentMbtiQuadrant(),
          );
        }
      }
    }
  }

  /// 인연 관계도에서 진입 시 멘션을 입력 필드에 삽입 (자동 전송 X)
  ///
  /// targetProfileId로 인연 정보를 찾아 [나 포함] @나/이름 @카테고리/이름 형태로
  /// 입력 필드에 삽입합니다. 사용자가 직접 질문을 추가해서 전송합니다.
  Future<bool> _autoInsertMention() async {
    final activeProfile = await ref.read(activeProfileProvider.future);
    if (activeProfile == null || !mounted) return false;

    try {
      // 인연 목록에서 해당 프로필 찾기
      final relations = await ref.read(relationListProvider(activeProfile.id).future);
      final relation = relations
          .where((r) => r.toProfileId == widget.targetProfileId)
          .firstOrNull;
      if (relation == null || !mounted) return false;

      // 멘션 텍스트 생성 (나 + 상대방)
      final ownerMention = '@나/${activeProfile.displayName}';
      final categoryLabel = relation.categoryLabel;
      final displayName = relation.effectiveDisplayName;
      final targetMention = '@$categoryLabel/$displayName';
      final fullMentionText = '[나 포함] $ownerMention $targetMention ';

      // 새 세션 생성 (initialMessage 없이 - 자동 전송 안 함)
      final sessionNotifier = ref.read(chatSessionNotifierProvider.notifier);
      final currentPersona = ref.read(chatPersonaNotifierProvider);
      await sessionNotifier.createSession(
        _chatType,
        activeProfile.id,
        targetProfileId: widget.targetProfileId,
        chatPersona: currentPersona,
        mbtiQuadrant: _resolveCurrentMbtiQuadrant(),
      );
      if (!mounted) return false;

      // 입력 필드에 멘션 삽입 (사용자가 질문 추가 후 직접 전송)
      setState(() {
        _inputController.text = fullMentionText;
        _inputController.selection = TextSelection.collapsed(
          offset: fullMentionText.length,
        );
        _pendingTargetProfileId = widget.targetProfileId;
      });

      if (kDebugMode) {
        print('[SajuChatShell] 멘션 입력 필드 삽입: $fullMentionText');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('[SajuChatShell] 멘션 삽입 실패: $e');
      }
      return false;
    }
  }

  /// 사용자 스크롤 위치 감지: 맨 아래 근처면 자동 스크롤 허용
  void _onScrollChanged() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    final atBottom = position.pixels >= position.maxScrollExtent - 50;
    _isUserScrolling = !atBottom;
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients || _isUserScrolling) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients && !_isUserScrolling) {
        _scrollController.jumpTo(
          _scrollController.position.maxScrollExtent,
        );
      }
    });
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
    await sessionNotifier.createSession(
      _chatType,
      activeProfile?.id,
      chatPersona: currentPersona,
      mbtiQuadrant: _resolveCurrentMbtiQuadrant(),
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
      print('[SajuChatShell] 🎯 인연 선택됨');
      print('   - singlePersonMode: ${selection.isSinglePersonMode}');
      print('   - 선택된 인연: ${selection.relations.length}명');
      print('   - 나 포함: ${selection.includesOwner}');
      print('   - 참가자 IDs: ${selection.participantIds}');
      print('   - 멘션: ${selection.combinedMentionText}');
    }

    // 개인 사주 모드: 1명만 선택 → 멘션만 입력 필드에 삽입
    if (selection.isSinglePersonMode && selection.relations.isNotEmpty) {
      final relation = selection.relations.first;
      final mentionText = selection.mentionTexts.first;

      setState(() {
        _inputController.text = '$mentionText ';
        _inputController.selection = TextSelection.collapsed(
          offset: _inputController.text.length,
        );
        _pendingTargetProfileId = relation.toProfileId;
        _pendingCompatibilitySelection = null;
      });
      return;
    }

    // 궁합 모드: 2명 선택 → 멘션만 입력 필드에 삽입
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
          // + 새 채팅 버튼 (페르소나 변경 안내 포함)
          IconButton(
            icon: Icon(Icons.add, color: appTheme.primaryColor),
            onPressed: _handleNewChat,
            tooltip: '새 채팅 시작 (페르소나 변경)',
          ),
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
                      // + 새 채팅 버튼 (햄버거 옆)
                      IconButton(
                        icon: Icon(Icons.add, color: appTheme.primaryColor),
                        onPressed: _handleNewChat,
                        tooltip: '새 채팅 시작 (페르소나 변경)',
                      ),
                      const SizedBox(width: 4),
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

/// ChatPersona → AiPersona 매핑 (광고 위젯용)
AiPersona _mapChatPersonaToAiPersona(ChatPersona persona) {
  return switch (persona) {
    ChatPersona.basePerson => AiPersona.professional,
    ChatPersona.nfSensitive => AiPersona.grandma,
    ChatPersona.ntAnalytic => AiPersona.master,
    ChatPersona.sfFriendly => AiPersona.cute,
    ChatPersona.stRealistic => AiPersona.professional,
    ChatPersona.babyMonk => AiPersona.babyMonk,
    ChatPersona.scenarioWriter => AiPersona.scenarioWriter,
    ChatPersona.saOngJiMa => AiPersona.saOngJiMa,
    ChatPersona.sewerSaju => AiPersona.sewerSaju,
  };
}

class _ChatContentState extends ConsumerState<_ChatContent> {
  /// pendingMessage 처리 중 플래그 (중복 전송 방지)
  bool _isProcessingPendingMessage = false;

  /// 스트리밍 스크롤 throttle용 타임스탬프
  DateTime _lastScrollTime = DateTime(0);

  @override
  Widget build(BuildContext context) {
    final sessionState = ref.watch(chatSessionNotifierProvider);
    final currentSessionId = sessionState.currentSessionId;
    final appTheme = context.appTheme;

    // 세션이 없으면 환영 메시지 + 입력 필드
    if (currentSessionId == null) {
      return Column(
        children: [
          // const DisclaimerBanner(), // 주석처리: 사주상담 참고용 안내 배너
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
              // persona에서 정확한 mbtiQuadrant 파생
              final resolvedMbti = currentPersona.isMbtiPersona
                  ? currentPersona.mbtiQuadrant
                  : currentPersona.canAdjustMbti
                      ? ref.read(mbtiQuadrantNotifierProvider)
                      : null;
              ref.read(chatSessionNotifierProvider.notifier)
                  .createSession(
                    widget.chatType,
                    activeProfile?.id,
                    initialMessage: text,
                    targetProfileId: targetId,
                    participantIds: participantIds,
                    includesOwner: includesOwner,
                    chatPersona: currentPersona,
                    mbtiQuadrant: resolvedMbti,
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

    // v8.0: 세션에 저장된 participantIds 복원 (궁합 연속 대화용)
    // chat_mentions에서 복원하는 것은 chat_provider.dart에서 처리하지만,
    // UI 레벨에서도 targetProfileId가 있으면 알 수 있도록 로그 출력
    if (kDebugMode) {
      print('[_ChatContent] build: session=${currentSession?.id?.substring(0, 8)}, targetProfileId=${currentSession?.targetProfileId}, widget.targetProfileId=${widget.targetProfileId}, effectiveTargetProfileId=$effectiveTargetProfileId');
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
            .sendMessage(msg, widget.chatType, compatibilityParticipantIds: participantIds, targetProfileId: participantIds == null ? targetId : null);

        _isProcessingPendingMessage = false;
      });
    }

    // 에러 발생 시 팝업 다이얼로그 표시
    ref.listen(
      chatNotifierProvider(currentSessionId).select((s) => s.error),
      (previous, next) {
        if (next != null && previous != next && context.mounted) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Color(0xFFD4AF37), size: 24),
                  SizedBox(width: 8),
                  Text('알림', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              content: Text(next, style: const TextStyle(fontSize: 14)),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    ref.read(chatNotifierProvider(currentSessionId).notifier).clearError();
                  },
                  child: const Text('확인'),
                ),
              ],
            ),
          );
        }
      },
    );

    // 메시지가 추가되면 스크롤 + 광고 체크
    // 스트리밍 중에는 300ms throttle로 스크롤 빈도 제한
    ref.listen(
      chatNotifierProvider(currentSessionId),
      (previous, next) {
        if (previous?.messages.length != next.messages.length) {
          // 새 메시지 추가 시 항상 스크롤
          widget.onScroll();
        } else if (previous?.streamingContent != next.streamingContent) {
          // 스트리밍 중 스크롤: 300ms throttle로 빈도 제한
          final now = DateTime.now();
          if (now.difference(_lastScrollTime).inMilliseconds >= 300) {
            _lastScrollTime = now;
            widget.onScroll();
          }
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

    // 디버그: UI에서 사용되는 suggestedQuestions 확인
    // print('[SajuChatShell] 마지막 AI 메시지 ID: ${lastAiMessage?.id}');
    // print('[SajuChatShell] suggestedQuestions: $suggestedQuestions');

    // 가로 모드 체크 (화면 높이가 400 미만이면 가로 모드로 간주)
    final isLandscape = MediaQuery.of(context).size.height < 400;

    // 상단 요소들 (가로 모드에서는 컴팩트하게)
    final topWidgets = <Widget>[
      // const DisclaimerBanner(), // 주석처리: 사주상담 참고용 안내 배너
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
        // 광고 모드 시 대화형 광고 표시 (모든 트리거 타입 처리)
        Builder(
          builder: (context) {
            final adState = ref.watch(conversationalAdNotifierProvider);
            // 광고 모드 활성화 시: tokenDepleted, tokenNearLimit, intervalAd 모두 처리
            if (adState.isAdMode) {
              final selectedPersona = ref.read(chatPersonaNotifierProvider);
              final aiPersona = _mapChatPersonaToAiPersona(selectedPersona);
              return ConversationalAdWidget(
                persona: aiPersona,
                sessionId: currentSessionId!,
                onAdComplete: () {
                  // ConversationalAdWidget 내부에서 토큰 충전 처리됨
                },
              );
            }
            // 일반 에러
            if (chatState.error != null) {
              return ErrorBanner(
                message: chatState.error!,
                onDismiss: () {
                  ref.read(chatNotifierProvider(currentSessionId!).notifier).clearError();
                },
              );
            }
            return const SizedBox.shrink();
          },
        ),
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
class _PersonaHorizontalSelector extends ConsumerStatefulWidget {
  const _PersonaHorizontalSelector();

  @override
  ConsumerState<_PersonaHorizontalSelector> createState() => _PersonaHorizontalSelectorState();
}

class _PersonaHorizontalSelectorState extends ConsumerState<_PersonaHorizontalSelector>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;

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
          final quadrantColor = _getPersonaColor(ChatPersona.fromMbtiQuadrant(currentQuadrant));

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
  Widget build(BuildContext context) {
    final currentPersona = ref.watch(chatPersonaNotifierProvider);
    final appTheme = context.appTheme;

    // 현재 세션의 메시지 수 확인 (대화 시작 후 페르소나 잠금)
    final sessionState = ref.watch(chatSessionNotifierProvider);
    final currentSessionId = sessionState.currentSessionId;
    final hasMessages = currentSessionId != null
        ? ref.watch(chatNotifierProvider(currentSessionId)).messages.isNotEmpty
        : false;

    // 페르소나 잠금 상태: 메시지가 있으면 변경 불가
    final isPersonaLocked = hasMessages;

    // 현재 페르소나의 색상
    final quadrantColor = _getPersonaColor(currentPersona);

    // 페르소나 아이템 크기 계산용 상수
    const double circleSize = 44;
    const double containerPadding = 16;

    // ═══════════════════════════════════════════════════════════════════════════
    // 접힌 상태: 선택된 페르소나만 표시 (컴팩트)
    // ═══════════════════════════════════════════════════════════════════════════
    if (!_isExpanded) {
      return GestureDetector(
        onTap: () => setState(() => _isExpanded = true),
        onLongPress: () => _showPersonaInfoDialog(context, currentPersona, quadrantColor),
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: appTheme.cardColor.withValues(alpha: 0.8),
            border: Border(
              bottom: BorderSide(
                color: appTheme.primaryColor.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              // 선택된 페르소나 아이콘
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: quadrantColor.withValues(alpha: 0.15),
                  border: Border.all(
                    color: quadrantColor.withValues(alpha: 0.5),
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Icon(
                    currentPersona.icon,
                    size: 18,
                    color: quadrantColor,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // 선택된 페르소나 이름
              Text(
                currentPersona.displayName,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: appTheme.textPrimary,
                ),
              ),
              // info 아이콘 (탭하면 설명 팝업)
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () => _showPersonaInfoDialog(context, currentPersona, quadrantColor),
                child: Icon(
                  Icons.info_outline_rounded,
                  size: 18,
                  color: appTheme.textMuted,
                ),
              ),
              const Spacer(),
              // 잠금 상태: "새 채팅을 눌러야 페르소나를 바꿀 수 있어요!" 안내
              if (isPersonaLocked)
                GestureDetector(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            const Icon(Icons.info_outline, color: Colors.white, size: 18),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                '상단의 + 버튼을 눌러 새 채팅을 시작하면\n페르소나를 변경할 수 있어요!',
                                style: TextStyle(fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                        backgroundColor: appTheme.primaryColor,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: appTheme.primaryColor.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: appTheme.primaryColor.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.lock_outline_rounded,
                          size: 14,
                          color: appTheme.primaryColor.withOpacity(0.7),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '+ 새 채팅에서 변경 가능',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: appTheme.primaryColor.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              // 펼치기 힌트
              if (!isPersonaLocked)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '페르소나 변경',
                      style: TextStyle(
                        fontSize: 12,
                        color: appTheme.textMuted,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.expand_more,
                      size: 20,
                      color: appTheme.textMuted,
                    ),
                  ],
                ),
            ],
          ),
        ),
      );
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // [TODO] XY축 MBTI 선택기 연동 (향후 구현)
    // ═══════════════════════════════════════════════════════════════════════════
    // 펼친 상태에서 MbtiAxisSelector를 표시하고, XY 좌표에 따라
    // 16개 MBTI 타입을 계산 → ChatPersona 자동 선택.
    // 구현 시 MbtiAxisSelector에 onPositionChanged 콜백을 추가하고
    // ChatPersona.fromXYPosition(x, y) 호출.
    // 참고: chat_persona.dart에 상세 설계 주석 참조
    // 참고: mbti_axis_selector.dart에 기존 XY축 위젯 구현 존재
    // ═══════════════════════════════════════════════════════════════════════════

    // ═══════════════════════════════════════════════════════════════════════════
    // 펼친 상태: 전체 페르소나 목록 (기존 UI)
    // ═══════════════════════════════════════════════════════════════════════════
    return Container(
      height: 90,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: appTheme.cardColor.withValues(alpha: 0.8),
      ),
      child: Row(
        children: [
          // 페르소나 목록 (가로 스크롤)
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: ChatPersona.visibleValues.map((persona) {
                  final isSelected = persona == currentPersona;
                  final personaColor = _getPersonaColor(persona);
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: _buildPersonaCircle(
                      context,
                      persona,
                      isSelected: isSelected,
                      accentColor: isSelected ? personaColor : appTheme.primaryColor,
                      size: circleSize,
                      isLocked: isPersonaLocked,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          // 접기 버튼
          GestureDetector(
            onTap: () => setState(() => _isExpanded = false),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: appTheme.textMuted.withValues(alpha: 0.1),
              ),
              child: Icon(
                Icons.expand_less,
                size: 20,
                color: appTheme.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 페르소나 상세 설명 팝업
  void _showPersonaInfoDialog(BuildContext context, ChatPersona persona, Color accentColor) {
    final appTheme = context.appTheme;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: appTheme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 페르소나 아이콘
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accentColor.withOpacity(0.15),
                border: Border.all(color: accentColor.withOpacity(0.4), width: 2),
              ),
              child: Center(
                child: Icon(persona.icon, size: 32, color: accentColor),
              ),
            ),
            const SizedBox(height: 14),
            // 이름
            Text(
              persona.displayName,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: appTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            // 짧은 설명 뱃지
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                persona.description,
                style: TextStyle(
                  fontSize: 13,
                  color: accentColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 16),
            // 상세 설명
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: appTheme.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                persona.detailedDescription,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.6,
                  color: appTheme.textSecondary,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('닫기', style: TextStyle(color: accentColor, fontSize: 15)),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonaCircle(
    BuildContext context,
    ChatPersona persona, {
    required bool isSelected,
    required Color accentColor,
    double size = 44,
    bool isLocked = false,
    VoidCallback? onTapSelected,
  }) {
    final appTheme = context.appTheme;
    final iconSize = (size * 0.5).clamp(18.0, 22.0);

    final displayName = persona.shortName;

    // 잠금 상태: 선택된 페르소나만 활성화 표시, 나머지는 흐리게
    final isDisabled = isLocked && !isSelected;

    return GestureDetector(
      onTap: isLocked
          ? null
          : () {
              if (isSelected && onTapSelected != null) {
                onTapSelected();
              } else {
                ref.read(chatPersonaNotifierProvider.notifier).setPersona(persona);
                // MBTI 페르소나면 mbtiQuadrant도 동기화
                if (persona.mbtiQuadrant != null) {
                  ref.read(mbtiQuadrantNotifierProvider.notifier).setQuadrant(persona.mbtiQuadrant!);
                }
                ref.read(chatSessionNotifierProvider.notifier)
                    .updateCurrentSessionPersona(
                      chatPersona: persona,
                      mbtiQuadrant: persona.isMbtiPersona
                          ? persona.mbtiQuadrant
                          : persona.canAdjustMbti
                              ? ref.read(mbtiQuadrantNotifierProvider)
                              : null,
                    );
              }
            },
      onLongPress: () => _showPersonaInfoDialog(context, persona, accentColor),
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
                fontSize: 12,
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
    );
  }

  Color _getPersonaColor(ChatPersona persona) {
    switch (persona) {
      case ChatPersona.nfSensitive:
        return const Color(0xFFE63946); // 빨강 - 감성
      case ChatPersona.ntAnalytic:
        return const Color(0xFF457B9D); // 파랑 - 분석
      case ChatPersona.sfFriendly:
        return const Color(0xFF2A9D8F); // 초록 - 친근
      case ChatPersona.stRealistic:
        return const Color(0xFFF4A261); // 주황 - 현실
      case ChatPersona.babyMonk:
        return const Color(0xFFAB47BC); // 보라 - 아기동자
      case ChatPersona.saOngJiMa:
        return const Color(0xFF66BB6A); // 녹색 - 새옹지마
      case ChatPersona.sewerSaju:
        return const Color(0xFF78909C); // 회색 - 시궁창
      default:
        return const Color(0xFF457B9D);
    }
  }
}

/// 광고 안내 배너 (토큰 소진 시)
///
/// "광고를 확인하면 대화를 이어갈 수 있어요!" 메시지 표시
class _AdPromptBanner extends StatelessWidget {
  final VoidCallback onWatchAd;

  const _AdPromptBanner({required this.onWatchAd});

  @override
  Widget build(BuildContext context) {
    final appTheme = context.appTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: appTheme.isDark
              ? [const Color(0xFF2D3A4A), const Color(0xFF1E2830)]
              : [const Color(0xFFFFF8E1), const Color(0xFFFFECB3)],
        ),
        border: Border(
          top: BorderSide(
            color: appTheme.isDark
                ? const Color(0xFFD4AF37).withValues(alpha: 0.3)
                : const Color(0xFFFFB300),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.play_circle_outline,
            size: 24,
            color: appTheme.isDark
                ? const Color(0xFFD4AF37)
                : const Color(0xFFFF8F00),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '광고를 보면 더 대화할 수 있어요!',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: appTheme.isDark
                    ? const Color(0xFFE0E0E0)
                    : const Color(0xFF5D4037),
              ),
            ),
          ),
          TextButton(
            onPressed: onWatchAd,
            style: TextButton.styleFrom(
              backgroundColor: appTheme.isDark
                  ? const Color(0xFFD4AF37)
                  : const Color(0xFFFF8F00),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text(
              '광고 보기',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
