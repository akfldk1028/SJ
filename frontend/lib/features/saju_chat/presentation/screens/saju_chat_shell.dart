import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../ad/ad.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../router/routes.dart';
import '../../domain/models/chat_type.dart';
// mention_parser is now used via MentionSendHandler
import '../providers/chat_provider.dart';
import '../providers/chat_session_provider.dart';
import '../widgets/chat_input_field.dart';
import '../widgets/chat_message_list.dart';
// import '../widgets/disclaimer_banner.dart'; // 주석처리: 사주상담 참고용 안내 배너
// import '../widgets/error_banner.dart'; // 에러 배너 제거
import '../widgets/relation_selector_sheet.dart';
import '../widgets/suggested_questions.dart';
import '../providers/chat_persona_provider.dart';
import '../providers/conversational_ad_provider.dart';
import '../../data/models/conversational_ad_model.dart';
import '../../domain/models/chat_persona.dart';
import '../../domain/models/ai_persona.dart';
import '../widgets/token_depleted_banner.dart';
import '../widgets/persona_horizontal_selector.dart';
import '../widgets/deep_analysis_loading_banner.dart';
import '../widgets/ad_native_bubble.dart';
// import '../widgets/conversational_ad_widget.dart'; // 대화형 광고 위젯 제거
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../../profile/presentation/providers/relation_provider.dart';
// profile_relation_model is now used via MentionSendHandler
import '../widgets/mention_send_handler.dart';
import '../widgets/chat_mobile_layout.dart';
import '../widgets/chat_desktop_layout.dart';

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
    // 세션 로드 완료 대기 (100ms 추측 대기 대신 명시적 로드)
    final sessionNotifier = ref.read(chatSessionNotifierProvider.notifier);
    await sessionNotifier.loadSessions();

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
      // 세션이 있지만 선택되지 않았으면 chatType에 맞는 세션 선택
      if (_chatType != ChatType.general) {
        // 특정 chatType(궁합 등)으로 진입: 같은 타입 세션 찾기 or 새로 생성
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
      } else {
        sessionNotifier.selectSession(sessionState.sessions.first.id);
      }
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
        // 궁합용 CompatibilitySelection 설정 (텍스트 파싱 대신 UI 선택 데이터 직접 사용)
        _pendingCompatibilitySelection = CompatibilitySelection(
          relations: [relation],
          mentionTexts: [ownerMention, targetMention],
          includesOwner: true,
          ownerProfileId: activeProfile.id,
        );
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
              title: Text('saju_chat.newChat'.tr(), style: TextStyle(color: appTheme.textPrimary)),
              subtitle: Text('saju_chat.newChatSubtitle'.tr(), style: TextStyle(color: appTheme.textSecondary, fontSize: 12)),
              onTap: () {
                Navigator.pop(sheetContext);
                _handleNewChat();
              },
            ),
            // 채팅 기록
            ListTile(
              leading: Icon(Icons.history, color: appTheme.textPrimary),
              title: Text('saju_chat.chatHistory'.tr(), style: TextStyle(color: appTheme.textPrimary)),
              subtitle: Text('saju_chat.chatHistorySubtitle'.tr(), style: TextStyle(color: appTheme.textSecondary, fontSize: 12)),
              onTap: () {
                Navigator.pop(sheetContext);
                _scaffoldKey.currentState?.openDrawer();
              },
            ),
            Divider(color: appTheme.textMuted.withOpacity(0.2)),
            // 메인으로 돌아가기
            ListTile(
              leading: Icon(Icons.home_outlined, color: appTheme.textPrimary),
              title: Text('saju_chat.goToMain'.tr(), style: TextStyle(color: appTheme.textPrimary)),
              subtitle: Text('saju_chat.goToMainSubtitle'.tr(), style: TextStyle(color: appTheme.textSecondary, fontSize: 12)),
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

  /// 공통 _ChatContent 위젯 생성
  Widget _buildChatContent() {
    return _ChatContent(
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < _breakpoint;

        if (isMobile) {
          return ChatMobileLayout(
            chatType: _chatType,
            scaffoldKey: _scaffoldKey,
            onNewChat: _handleNewChat,
            onSessionSelected: _handleSessionSelected,
            onSessionDeleted: _handleSessionDeleted,
            onSessionRenamed: _handleSessionRenamed,
            onCompatibilityChat: _handleCompatibilityChat,
            chatContent: _buildChatContent(),
          );
        } else {
          return ChatDesktopLayout(
            chatType: _chatType,
            isSidebarVisible: _isSidebarVisible,
            onToggleSidebar: () => setState(() {
              _isSidebarVisible = !_isSidebarVisible;
            }),
            onNewChat: _handleNewChat,
            onSessionSelected: _handleSessionSelected,
            onSessionDeleted: _handleSessionDeleted,
            onSessionRenamed: _handleSessionRenamed,
            onCompatibilityChat: _handleCompatibilityChat,
            chatContent: _buildChatContent(),
          );
        }
      },
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
                    'saju_chat.askAnything'.tr(),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: appTheme.textPrimary,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'saju_chat.askAnythingSubtitle'.tr(),
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
              final hasMention = MentionSendHandler.hasMention(text);

              // 공통 멘션 파싱 로직
              final params = await MentionSendHandler.resolveMentionParams(
                text: text,
                ref: ref,
                pendingCompatibilitySelection: widget.pendingCompatibilitySelection,
                pendingTargetProfileId: widget.pendingTargetProfileId,
                fallbackTargetProfileId: widget.targetProfileId,
              );

              print('[_ChatContent] 세션 생성 요청: text=$text, hasMention=$hasMention, targetProfileId=${params.targetProfileId}, participantIds=${params.participantIds}, includesOwner=${params.includesOwner}');

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
                    targetProfileId: params.targetProfileId,
                    participantIds: params.participantIds,
                    includesOwner: params.includesOwner,
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
            .sendMessage(msg, widget.chatType, compatibilityParticipantIds: participantIds, includesOwner: includesOwner, targetProfileId: participantIds == null ? targetId : null);

        _isProcessingPendingMessage = false;
      });
    }

    // 에러 발생 시 처리: quota 에러는 SnackBar 표시 후 소거
    ref.listen(
      chatNotifierProvider(currentSessionId).select((s) => s.error),
      (previous, next) {
        if (next != null && previous != next) {
          // QUOTA_EXCEEDED 또는 토큰 관련 에러 → SnackBar로 사용자 피드백
          if (next.contains('토큰') || next.contains('한도')) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(next),
                  backgroundColor: const Color(0xFFD4AF37),
                  duration: const Duration(seconds: 3),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          }
          ref.read(chatNotifierProvider(currentSessionId).notifier).clearError();
        }
      },
    );

    // 네이티브 광고 로드 완료 시 스크롤 (안내 문구가 보이도록)
    ref.listen(
      conversationalAdNotifierProvider.select((s) => s.loadState),
      (previous, next) {
        if (next == AdLoadState.loaded) {
          widget.onScroll();
        }
      },
    );

    // 네이티브 광고 클릭(adWatched) 시 자동으로 토큰 충전 + 대화 재개
    ref.listen(
      conversationalAdNotifierProvider.select((s) => s.adWatched),
      (previous, next) {
        if (next == true && previous != true) {
          final adState = ref.read(conversationalAdNotifierProvider);
          final adNotifier = ref.read(conversationalAdNotifierProvider.notifier);
          // 토큰 충전
          if (adState.rewardedTokens != null && adState.rewardedTokens! > 0) {
            ref.read(chatNotifierProvider(currentSessionId).notifier)
                .addBonusTokens(adState.rewardedTokens!, isRewardedAd: true);
          }
          // 광고 모드 해제 → 바로 대화 재개
          adNotifier.dismissAd();
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

    // 토큰 소진 상태 체크 (입력창/칩 비활성화 → 광고 버튼 클릭 유도)
    final adState = ref.watch(conversationalAdNotifierProvider);
    final isTokenDepleted = adState.isAdMode && adState.adType == AdMessageType.tokenDepleted;

    // 상단 요소들 (가로 모드에서는 컴팩트하게)
    final topWidgets = <Widget>[
      // const DisclaimerBanner(), // 주석처리: 사주상담 참고용 안내 배너
      // 페르소나 가로 선택기 (원형 이모지 리스트)
      const PersonaHorizontalSelector(),
      // GPT-5.2 상세 분석 로딩 배너 (첫 프로필 분석 시 ~2분 소요)
      if (chatState.isDeepAnalysisRunning)
        const DeepAnalysisLoadingBanner(),
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
          child: _buildChatListWithAd(ref, chatState, currentSessionId),
        ),
        // 에러 배너 제거 (토큰 소진은 _TokenDepletedBanner에서 처리)
        // 추천 질문 표시 (로딩 중이 아니고 메시지가 있을 때)
        if (!chatState.isLoading && chatState.messages.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: SuggestedQuestions(
              questions: suggestedQuestions,
              enabled: !isTokenDepleted,
              onQuestionSelected: (question) {
                print('[_ChatContent] 추천 질문 선택: $question');
                ref
                    .read(chatNotifierProvider(currentSessionId).notifier)
                    .sendMessage(question, widget.chatType, targetProfileId: effectiveTargetProfileId);
              },
            ),
          ),
        // 토큰 소진 배너 (ChatInputField 바로 위)
        TokenDepletedBanner(sessionId: currentSessionId),
        ChatInputField(
          controller: widget.inputController,
          onSend: (text) async {
            final hasMention = MentionSendHandler.hasMention(text);

            // 공통 멘션 파싱 로직
            final params = await MentionSendHandler.resolveMentionParams(
              text: text,
              ref: ref,
              pendingCompatibilitySelection: widget.pendingCompatibilitySelection,
              pendingTargetProfileId: widget.pendingTargetProfileId,
              fallbackTargetProfileId: effectiveTargetProfileId,
            );

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
            print('  participantIds: ${params.participantIds}');
            print('  targetId: ${params.targetProfileId}');
            print('  includesOwner: ${params.includesOwner}');
            // 인터벌 광고 활성 시 처리
            final adStateNow = ref.read(conversationalAdNotifierProvider);
            if (adStateNow.isAdMode && adStateNow.adType == AdMessageType.inlineInterval) {
              if (!adStateNow.adWatched) {
                // 광고 미클릭 상태 → 메시지 전송 차단 (토큰 미지급)
                return;
              }
              // 광고 클릭 완료 → dismiss 후 메시지 전송
              ref.read(conversationalAdNotifierProvider.notifier).dismissAd();
            }

            ref
                .read(chatNotifierProvider(currentSessionId).notifier)
                .sendMessage(
                  text,
                  widget.chatType,
                  compatibilityParticipantIds: params.participantIds,
                  includesOwner: params.includesOwner,
                  // 하위 호환: participantIds가 없을 때만 targetId 사용
                  targetProfileId: params.participantIds == null ? params.targetProfileId : null,
                );

            // 멘션 전송 완료 시 콜백 호출
            if (hasMention && widget.onMentionSent != null) {
              widget.onMentionSent!();
            }
          },
          enabled: !chatState.isLoading && !isTokenDepleted,
          hintText: isTokenDepleted
              ? '위 버튼을 눌러 대화를 이어가세요'
              : widget.chatType.inputHint,
          hintColor: isTokenDepleted ? const Color(0xFFE91E63) : null,
        ),
      ],
    );
  }

  /// 네이티브 광고를 채팅 리스트 안에 trailingWidget으로 표시
  Widget _buildChatListWithAd(WidgetRef ref, dynamic chatState, String sessionId) {
    final adState = ref.watch(conversationalAdNotifierProvider);

    // 네이티브 광고 모드일 때만 채팅 리스트 끝에 광고 표시
    Widget? trailingWidget;
    if (adState.isAdMode &&
        adState.adType == AdMessageType.inlineInterval &&
        !adState.adWatched &&
        (adState.loadState == AdLoadState.loaded ||
            adState.loadState == AdLoadState.loading)) {
      final nativeAd = ref.read(conversationalAdNotifierProvider.notifier).nativeAd;
      final theme = Theme.of(context);
      trailingWidget = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AdNativeBubble(
            nativeAd: nativeAd,
            loadState: adState.loadState,
            personaEmoji: '📢',
          ),
          // 안내 문구 (AdMob 정책: "클릭하세요" 금지, 보상 안내는 허용)
          Padding(
            padding: const EdgeInsets.only(left: 56, top: 6, bottom: 8),
            child: Text(
              'saju_chat.adViewToContinue'.tr(),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                fontSize: 12,
              ),
            ),
          ),
        ],
      );
    }

    return ChatMessageList(
      messages: chatState.messages,
      streamingContent: chatState.streamingContent,
      scrollController: widget.scrollController,
      isLoading: chatState.isLoading,
      trailingWidget: trailingWidget,
      hideInlineAds: adState.isAdMode,
    );
  }
}

