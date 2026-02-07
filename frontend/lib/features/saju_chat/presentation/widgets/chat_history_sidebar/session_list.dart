import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/chat_session.dart';
import '../../providers/chat_session_provider.dart';
import 'session_group_header.dart';
import 'session_list_tile.dart';

/// 세션 목록 위젯
///
/// ConsumerWidget으로 chatSessionProvider 구독
/// 세션을 SessionGroup별로 그룹화하여 표시
///
/// 위젯 트리 최적화:
/// - ListView.builder 사용 (Lazy loading)
/// - 그룹별로 헤더 + 아이템 표시
/// - RepaintBoundary는 SessionListTile에서 처리
class SessionList extends ConsumerWidget {
  final Function(String sessionId)? onSessionSelected;
  final Function(String sessionId)? onSessionDeleted;
  final Function(String sessionId, String newTitle)? onSessionRenamed;

  const SessionList({
    super.key,
    this.onSessionSelected,
    this.onSessionDeleted,
    this.onSessionRenamed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Provider에서 세션 목록 가져오기
    final sessionState = ref.watch(chatSessionNotifierProvider);
    final sessions = sessionState.sessions;
    final currentSessionId = sessionState.currentSessionId;

    if (sessions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'saju_chat.noChatsYet'.tr(),
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    // 그룹별로 세션 분류
    final groupedSessions = _groupSessions(sessions);

    return ListView.builder(
      itemCount: groupedSessions.length,
      itemBuilder: (context, index) {
        final entry = groupedSessions[index];
        final group = entry.key;
        final groupSessions = entry.value;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 그룹 헤더
            SessionGroupHeader(group: group),
            // 그룹 내 세션들
            ...groupSessions.map((session) => SessionListTile(
                  key: ValueKey(session.id),
                  session: session,
                  isSelected: session.id == currentSessionId,
                  onTap: () => onSessionSelected?.call(session.id),
                  onDelete: () => onSessionDeleted?.call(session.id),
                  onRename: (newTitle) =>
                      onSessionRenamed?.call(session.id, newTitle),
                )),
          ],
        );
      },
    );
  }

  /// 세션을 그룹별로 분류
  List<MapEntry<SessionGroup, List<ChatSession>>> _groupSessions(
    List<ChatSession> sessions,
  ) {
    final Map<SessionGroup, List<ChatSession>> grouped = {};

    for (final session in sessions) {
      final group = session.group;
      grouped.putIfAbsent(group, () => []).add(session);
    }

    // 그룹 순서: today -> yesterday -> last7Days -> last30Days -> older
    final orderedGroups = [
      SessionGroup.today,
      SessionGroup.yesterday,
      SessionGroup.last7Days,
      SessionGroup.last30Days,
      SessionGroup.older,
    ];

    return orderedGroups
        .where((group) => grouped.containsKey(group))
        .map((group) => MapEntry(group, grouped[group]!))
        .toList();
  }

}
