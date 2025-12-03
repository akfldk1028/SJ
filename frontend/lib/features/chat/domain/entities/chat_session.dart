/// 채팅 세션 엔티티 (Domain Layer - 순수 Dart)
class ChatSession {
  final String id;
  final String profileId;
  final String? title;
  final DateTime createdAt;
  final DateTime lastMessageAt;
  final int messageCount;

  const ChatSession({
    required this.id,
    required this.profileId,
    this.title,
    required this.createdAt,
    required this.lastMessageAt,
    this.messageCount = 0,
  });

  /// 제목이 없으면 기본 제목 반환
  String get displayTitle => title ?? '새 대화';

  /// 오늘 대화인지 확인
  bool get isToday {
    final now = DateTime.now();
    return lastMessageAt.year == now.year &&
        lastMessageAt.month == now.month &&
        lastMessageAt.day == now.day;
  }

  ChatSession copyWith({
    String? id,
    String? profileId,
    String? title,
    DateTime? createdAt,
    DateTime? lastMessageAt,
    int? messageCount,
  }) {
    return ChatSession(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      messageCount: messageCount ?? this.messageCount,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatSession &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
