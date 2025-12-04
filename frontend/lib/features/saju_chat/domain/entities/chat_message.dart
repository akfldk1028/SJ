/// 채팅 메시지 엔티티 (순수 도메인 객체)
///
/// 위젯 트리 최적화:
/// - immutable 객체로 불필요한 리빌드 방지
/// - copyWith으로 상태 변경 시 새 인스턴스 생성
class ChatMessage {
  final String id;
  final String content;
  final MessageRole role;
  final DateTime createdAt;
  final MessageStatus status;

  const ChatMessage({
    required this.id,
    required this.content,
    required this.role,
    required this.createdAt,
    this.status = MessageStatus.sent,
  });

  ChatMessage copyWith({
    String? id,
    String? content,
    MessageRole? role,
    DateTime? createdAt,
    MessageStatus? status,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      content: content ?? this.content,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
    );
  }

  bool get isUser => role == MessageRole.user;
  bool get isAi => role == MessageRole.assistant;
  bool get isSystem => role == MessageRole.system;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatMessage &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// 메시지 역할
enum MessageRole {
  user,
  assistant,
  system,
}

/// 메시지 상태
enum MessageStatus {
  sending,
  sent,
  error,
}
