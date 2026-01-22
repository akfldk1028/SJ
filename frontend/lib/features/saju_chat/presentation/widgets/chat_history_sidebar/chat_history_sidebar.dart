import 'package:flutter/material.dart';

import 'persona_selector_grid.dart';
import 'sidebar_footer.dart';
import 'sidebar_header.dart';
import 'session_list.dart';

/// 채팅 히스토리 사이드바
///
/// ChatGPT/Claude 스타일의 대화 목록 사이드바
///
/// 위젯 트리 최적화:
/// - const 생성자 사용
/// - 280px 고정 너비
/// - 작은 위젯으로 분리 (Header, List, Footer)
class ChatHistorySidebar extends StatelessWidget {
  final VoidCallback? onNewChat;
  final Function(String sessionId)? onSessionSelected;
  final Function(String sessionId)? onSessionDeleted;
  final Function(String sessionId, String newTitle)? onSessionRenamed;

  const ChatHistorySidebar({
    super.key,
    this.onNewChat,
    this.onSessionSelected,
    this.onSessionDeleted,
    this.onSessionRenamed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // 가로 모드 체크 - orientation 직접 사용
    final orientation = MediaQuery.of(context).orientation;
    final isLandscape = orientation == Orientation.landscape;

    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          right: BorderSide(
            color: theme.colorScheme.outlineVariant,
            width: 0.5,
          ),
        ),
      ),
      child: Column(
        children: [
          SidebarHeader(onNewChat: onNewChat),
          // 페르소나 선택 그리드 - 가로 모드에서는 숨김
          if (!isLandscape) const PersonaSelectorGrid(),
          // 대화 히스토리 목록
          Expanded(
            child: SessionList(
              onSessionSelected: onSessionSelected,
              onSessionDeleted: onSessionDeleted,
              onSessionRenamed: onSessionRenamed,
            ),
          ),
          const SidebarFooter(),
        ],
      ),
    );
  }
}
