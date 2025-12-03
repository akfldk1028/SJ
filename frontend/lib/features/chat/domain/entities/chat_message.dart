import 'message_role.dart';

/// 채팅 메시지 엔티티 (Domain Layer - 순수 Dart)
class ChatMessage {
  final String id;
  final String chatId;
  final MessageRole role;
  final String content;
  final DateTime createdAt;
  final List<String>? suggestedQuestions;

  const ChatMessage({
    required this.id,
    required this.chatId,
    required this.role,
    required this.content,
    required this.createdAt,
    this.suggestedQuestions,
  });

  /// 사용자 메시지인지 확인
  bool get isUser => role == MessageRole.user;

  /// AI 메시지인지 확인
  bool get isAssistant => role == MessageRole.assistant;

  /// 추천 질문이 있는지 확인
  bool get hasSuggestedQuestions =>
      suggestedQuestions != null && suggestedQuestions!.isNotEmpty;

  ChatMessage copyWith({
    String? id,
    String? chatId,
    MessageRole? role,
    String? content,
    DateTime? createdAt,
    List<String>? suggestedQuestions,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      role: role ?? this.role,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      suggestedQuestions: suggestedQuestions ?? this.suggestedQuestions,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatMessage &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
