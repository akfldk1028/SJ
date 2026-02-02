import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/models/chat_type.dart';
import '../providers/chat_session_provider.dart';
import 'chat_history_sidebar/chat_history_sidebar.dart';

/// Mobile 레이아웃: Scaffold + Drawer
///
/// _buildMobileLayout()에서 추출된 위젯.
/// saju_chat_shell.dart의 _SajuChatShellState에서 사용하던 로직과 동일.
class ChatMobileLayout extends ConsumerWidget {
  final ChatType chatType;
  final GlobalKey<ScaffoldState> scaffoldKey;
  final VoidCallback onNewChat;
  final void Function(String sessionId) onSessionSelected;
  final Future<void> Function(String sessionId) onSessionDeleted;
  final Future<void> Function(String sessionId, String newTitle) onSessionRenamed;
  final VoidCallback onCompatibilityChat;

  /// 채팅 컨텐츠 위젯 (외부에서 주입)
  final Widget chatContent;

  const ChatMobileLayout({
    super.key,
    required this.chatType,
    required this.scaffoldKey,
    required this.onNewChat,
    required this.onSessionSelected,
    required this.onSessionDeleted,
    required this.onSessionRenamed,
    required this.onCompatibilityChat,
    required this.chatContent,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionState = ref.watch(chatSessionNotifierProvider);
    final appTheme = context.appTheme;
    final currentSession = sessionState.sessions
        .where((s) => s.id == sessionState.currentSessionId)
        .firstOrNull;

    return Scaffold(
      key: scaffoldKey,
      backgroundColor: appTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: appTheme.backgroundColor,
        foregroundColor: appTheme.textPrimary,
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => scaffoldKey.currentState?.openDrawer(),
          tooltip: '메뉴',
        ),
        title: Text(
          currentSession?.title ?? chatType.title,
          style: TextStyle(color: appTheme.textPrimary),
        ),
        actions: [
          // + 새 채팅 버튼 (페르소나 변경 안내 포함)
          IconButton(
            icon: Icon(Icons.add, color: appTheme.primaryColor),
            onPressed: onNewChat,
            tooltip: '새 채팅 시작 (페르소나 변경)',
          ),
          // 궁합 버튼 (2명 선택)
          IconButton(
            icon: const Icon(Icons.group_add_outlined),
            onPressed: onCompatibilityChat,
            tooltip: '궁합 보기',
          ),
        ],
      ),
      drawer: Drawer(
        backgroundColor: appTheme.cardColor,
        child: ChatHistorySidebar(
          onNewChat: onNewChat,
          onSessionSelected: onSessionSelected,
          onSessionDeleted: onSessionDeleted,
          onSessionRenamed: onSessionRenamed,
          onDeleteCurrentSession: onSessionDeleted,
        ),
      ),
      body: chatContent,
    );
  }
}
