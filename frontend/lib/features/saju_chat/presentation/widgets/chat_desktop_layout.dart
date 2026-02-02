import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../router/routes.dart';
import '../../domain/models/chat_type.dart';
import '../providers/chat_session_provider.dart';
import 'chat_history_sidebar/chat_history_sidebar.dart';

/// Desktop 레이아웃: Row [Sidebar | Content]
///
/// _buildDesktopLayout()에서 추출된 위젯.
/// saju_chat_shell.dart의 _SajuChatShellState에서 사용하던 로직과 동일.
class ChatDesktopLayout extends ConsumerWidget {
  final ChatType chatType;
  final bool isSidebarVisible;
  final VoidCallback onToggleSidebar;
  final VoidCallback onNewChat;
  final void Function(String sessionId) onSessionSelected;
  final Future<void> Function(String sessionId) onSessionDeleted;
  final Future<void> Function(String sessionId, String newTitle) onSessionRenamed;
  final VoidCallback onCompatibilityChat;

  /// 채팅 컨텐츠 위젯 (외부에서 주입)
  final Widget chatContent;

  const ChatDesktopLayout({
    super.key,
    required this.chatType,
    required this.isSidebarVisible,
    required this.onToggleSidebar,
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
      backgroundColor: appTheme.backgroundColor,
      body: SafeArea(
        child: Row(
          children: [
            // 사이드바 (토글 가능)
            if (isSidebarVisible) ...[
              ChatHistorySidebar(
                onNewChat: onNewChat,
                onSessionSelected: onSessionSelected,
                onSessionDeleted: onSessionDeleted,
                onSessionRenamed: onSessionRenamed,
                onDeleteCurrentSession: onSessionDeleted,
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
                                onNewChat();
                                break;
                              case 'go_main':
                                context.go(Routes.menu);
                                break;
                              case 'toggle_sidebar':
                                onToggleSidebar();
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
                                    isSidebarVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                    color: appTheme.textPrimary,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    isSidebarVisible ? '사이드바 숨기기' : '사이드바 보기',
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
                          onPressed: onNewChat,
                          tooltip: '새 채팅 시작 (페르소나 변경)',
                        ),
                        const SizedBox(width: 4),
                        // 현재 세션 제목
                        Expanded(
                          child: Text(
                            currentSession?.title ?? chatType.title,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: appTheme.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // 궁합 버튼 (2명 선택)
                        IconButton(
                          icon: Icon(Icons.group_add_outlined, color: appTheme.textPrimary),
                          onPressed: onCompatibilityChat,
                          tooltip: '궁합 보기',
                        ),
                      ],
                    ),
                  ),
                  // 채팅 컨텐츠
                  Expanded(
                    child: chatContent,
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
