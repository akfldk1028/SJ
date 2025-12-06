import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// 사이드바 헤더
///
/// - 앱 타이틀 "만톡"
/// - 새 채팅 버튼
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
            '만톡',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
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
