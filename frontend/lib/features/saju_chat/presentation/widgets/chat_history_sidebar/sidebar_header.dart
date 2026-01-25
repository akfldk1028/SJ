import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../../router/routes.dart';
import '../../providers/chat_session_provider.dart';

/// 사이드바 헤더
///
/// - 앱 타이틀 "사담" + 휴지통 버튼 (현재 세션 삭제)
/// - 새 채팅 버튼
/// - 메인으로 버튼
///
/// 위젯 트리 최적화:
/// - ConsumerWidget 사용 (currentSessionId 접근)
/// - shadcn_ui ShadButton 사용
class SidebarHeader extends ConsumerWidget {
  final VoidCallback? onNewChat;
  final Function(String sessionId)? onDeleteCurrentSession;

  const SidebarHeader({
    super.key,
    this.onNewChat,
    this.onDeleteCurrentSession,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final appTheme = context.appTheme;

    // 현재 선택된 세션 ID
    final currentSessionId = ref.watch(
      chatSessionNotifierProvider.select((s) => s.currentSessionId),
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outlineVariant,
            width: 0.5,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 앱 타이틀 + 휴지통 버튼
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '사담',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              // 휴지통 버튼 - 선택된 세션이 있을 때만 활성화
              if (currentSessionId != null)
                IconButton(
                  onPressed: () => _showDeleteConfirmDialog(
                    context,
                    currentSessionId,
                  ),
                  icon: Icon(
                    Icons.delete_outline,
                    size: 20,
                    color: appTheme.textSecondary,
                  ),
                  tooltip: '현재 채팅 삭제',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          // 메인으로 버튼
          SizedBox(
            width: double.infinity,
            child: ShadButton.outline(
              onPressed: () {
                // Drawer가 열려있으면 닫기
                if (Scaffold.maybeOf(context)?.isDrawerOpen ?? false) {
                  Navigator.of(context).pop();
                }
                context.go(Routes.menu);
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.home_outlined, size: 18, color: appTheme.textPrimary),
                  const SizedBox(width: 8),
                  Text('메인으로', style: TextStyle(color: appTheme.textPrimary)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          // 새 채팅 버튼
          SizedBox(
            width: double.infinity,
            child: ShadButton(
              onPressed: onNewChat,
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add, size: 18),
                  SizedBox(width: 8),
                  Text('새 채팅'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 삭제 확인 다이얼로그
  void _showDeleteConfirmDialog(BuildContext context, String sessionId) {
    showShadDialog(
      context: context,
      builder: (context) => ShadDialog.alert(
        title: const Text('채팅 삭제'),
        description: const Text('이 채팅을 삭제하시겠습니까?\n삭제된 대화는 복구할 수 없습니다.'),
        actions: [
          ShadButton.outline(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          ShadButton.destructive(
            onPressed: () {
              Navigator.of(context).pop();
              onDeleteCurrentSession?.call(sessionId);
            },
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }
}
