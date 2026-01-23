import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../../router/routes.dart';

/// 사이드바 헤더
///
/// - 앱 타이틀 "만톡"
/// - 새 채팅 버튼
/// - 메인으로 버튼
///
/// 위젯 트리 최적화:
/// - const 생성자 사용 (콜백 제외)
/// - shadcn_ui ShadButton 사용
class SidebarHeader extends StatelessWidget {
  final VoidCallback? onNewChat;

  const SidebarHeader({
    super.key,
    this.onNewChat,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appTheme = context.appTheme;

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
          // 앱 타이틀
          Text(
            '사담',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
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
}
