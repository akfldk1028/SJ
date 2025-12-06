import 'package:flutter/material.dart';

import '../../../domain/entities/chat_session.dart';
import '../../../domain/models/chat_type.dart';

/// 세션 목록 아이템
///
/// - ChatType 아이콘
/// - 제목 (1줄, ellipsis)
/// - 마지막 메시지 미리보기 (1줄, 회색)
/// - 탭하면 세션 선택
/// - 길게 누르면 팝업 메뉴 (이름 변경/삭제)
/// - 선택된 세션 하이라이트 표시
///
/// 위젯 트리 최적화:
/// - RepaintBoundary로 독립적 리페인트
/// - 작은 위젯으로 분리 (100줄 이하)
/// - const 사용 불가 (콜백 포함)
class SessionListTile extends StatelessWidget {
  final ChatSession session;
  final bool isSelected;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final Function(String newTitle)? onRename;

  const SessionListTile({
    super.key,
    required this.session,
    this.isSelected = false,
    this.onTap,
    this.onDelete,
    this.onRename,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return RepaintBoundary(
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: isSelected
              ? BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                )
              : null,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ChatType 아이콘
              _buildChatTypeIcon(theme),
              const SizedBox(width: 12),
              // 제목 + 미리보기
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 제목
                    Text(
                      session.title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    // 마지막 메시지 미리보기
                    if (session.lastMessagePreview != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        session.lastMessagePreview!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              // 팝업 메뉴
              _buildPopupMenu(context),
            ],
          ),
        ),
      ),
    );
  }

  /// ChatType별 아이콘
  Widget _buildChatTypeIcon(ThemeData theme) {
    IconData icon;
    Color color;

    switch (session.chatType) {
      case ChatType.dailyFortune:
        icon = Icons.wb_sunny;
        color = Colors.orange;
        break;
      case ChatType.sajuAnalysis:
        icon = Icons.auto_awesome;
        color = Colors.purple;
        break;
      case ChatType.compatibility:
        icon = Icons.favorite;
        color = Colors.pink;
        break;
      case ChatType.general:
        icon = Icons.chat_bubble;
        color = theme.colorScheme.primary;
    }

    return Icon(icon, size: 20, color: color);
  }

  /// 팝업 메뉴 (이름 변경, 삭제)
  Widget _buildPopupMenu(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_vert,
        size: 18,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'rename',
          child: Row(
            children: [
              Icon(Icons.edit, size: 18),
              SizedBox(width: 8),
              Text('이름 변경'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete, size: 18, color: Colors.red),
              SizedBox(width: 8),
              Text('삭제', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ],
      onSelected: (value) {
        if (value == 'rename') {
          _showRenameDialog(context);
        } else if (value == 'delete') {
          onDelete?.call();
        }
      },
    );
  }

  /// 이름 변경 다이얼로그
  void _showRenameDialog(BuildContext context) {
    final controller = TextEditingController(text: session.title);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('대화 이름 변경'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: '새 이름',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              final newTitle = controller.text.trim();
              if (newTitle.isNotEmpty) {
                onRename?.call(newTitle);
              }
              Navigator.pop(context);
            },
            child: const Text('변경'),
          ),
        ],
      ),
    );
  }
}
