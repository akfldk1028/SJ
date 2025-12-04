import 'chat_message.dart';
import '../models/chat_type.dart';

/// 채팅 세션 엔티티
///
/// 하나의 대화 세션을 관리
class ChatSession {
  final String id;
  final ChatType chatType;
  final List<ChatMessage> messages;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const ChatSession({
    required this.id,
    required this.chatType,
    required this.messages,
    required this.createdAt,
    this.updatedAt,
  });

  ChatSession copyWith({
    String? id,
    ChatType? chatType,
    List<ChatMessage>? messages,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ChatSession(
      id: id ?? this.id,
      chatType: chatType ?? this.chatType,
      messages: messages ?? this.messages,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// 메시지 추가
  ChatSession addMessage(ChatMessage message) {
    return copyWith(
      messages: [...messages, message],
      updatedAt: DateTime.now(),
    );
  }

  /// 마지막 메시지
  ChatMessage? get lastMessage =>
      messages.isNotEmpty ? messages.last : null;

  /// 메시지 개수
  int get messageCount => messages.length;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatSession &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
