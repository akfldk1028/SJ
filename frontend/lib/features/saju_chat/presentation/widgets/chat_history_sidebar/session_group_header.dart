import 'package:flutter/material.dart';

import '../../../domain/entities/chat_session.dart';

/// 세션 그룹 헤더
///
/// 날짜별 그룹을 구분하는 헤더
/// (오늘, 어제, 지난 7일, 지난 30일, 이전)
///
/// 위젯 트리 최적화:
/// - const 생성자 사용
/// - 단순 텍스트 + 패딩만 표시
class SessionGroupHeader extends StatelessWidget {
  final SessionGroup group;

  const SessionGroupHeader({
    super.key,
    required this.group,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: 8,
      ),
      child: Text(
        group.label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
