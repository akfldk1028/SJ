import '../models/chat_type.dart';

/// 채팅 세션 엔티티 (순수 도메인 객체)
///
/// ChatGPT/Claude 스타일의 채팅 히스토리를 위한 세션 관리
/// - 각 대화는 하나의 세션으로 관리
/// - 메시지는 별도 저장, 세션은 메타데이터만 보관
class ChatSession {
  final String id;
  final String title;
  final ChatType chatType;
  final String? profileId;

  /// 궁합 채팅 시 상대방 프로필 ID
  /// - null이면 일반 채팅 (내 사주만)
  /// - 값이 있으면 궁합/타인 상담 (상대방 사주 포함)
  final String? targetProfileId;

  final DateTime createdAt;
  final DateTime updatedAt;
  final int messageCount;
  final String? lastMessagePreview;

  const ChatSession({
    required this.id,
    required this.title,
    required this.chatType,
    this.profileId,
    this.targetProfileId,
    required this.createdAt,
    required this.updatedAt,
    this.messageCount = 0,
    this.lastMessagePreview,
  });

  ChatSession copyWith({
    String? id,
    String? title,
    ChatType? chatType,
    String? profileId,
    String? targetProfileId,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? messageCount,
    String? lastMessagePreview,
  }) {
    return ChatSession(
      id: id ?? this.id,
      title: title ?? this.title,
      chatType: chatType ?? this.chatType,
      profileId: profileId ?? this.profileId,
      targetProfileId: targetProfileId ?? this.targetProfileId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      messageCount: messageCount ?? this.messageCount,
      lastMessagePreview: lastMessagePreview ?? this.lastMessagePreview,
    );
  }

  /// 세션 그룹 (날짜별 분류)
  SessionGroup get group => SessionGroup.fromDate(createdAt);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatSession &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// 세션 그룹 (날짜별 분류)
enum SessionGroup {
  today('오늘'),
  yesterday('어제'),
  last7Days('지난 7일'),
  last30Days('지난 30일'),
  older('이전');

  final String label;
  const SessionGroup(this.label);

  static SessionGroup fromDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final sessionDate = DateTime(date.year, date.month, date.day);
    final diff = today.difference(sessionDate).inDays;

    if (diff == 0) return SessionGroup.today;
    if (diff == 1) return SessionGroup.yesterday;
    if (diff <= 7) return SessionGroup.last7Days;
    if (diff <= 30) return SessionGroup.last30Days;
    return SessionGroup.older;
  }
}
