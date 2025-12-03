import '../../domain/entities/chat_message.dart';
import '../../domain/entities/message_role.dart';

/// ChatMessage 데이터 모델 (Data Layer)
/// Supabase JSON <-> Entity 변환
class ChatMessageModel extends ChatMessage {
  const ChatMessageModel({
    required super.id,
    required super.chatId,
    required super.role,
    required super.content,
    required super.createdAt,
    super.suggestedQuestions,
  });

  /// JSON -> Model
  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      id: json['id'] as String,
      chatId: json['chat_id'] as String,
      role: MessageRoleExtension.fromString(json['role'] as String),
      content: json['content'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      suggestedQuestions: json['suggested_questions'] != null
          ? List<String>.from(json['suggested_questions'] as List)
          : null,
    );
  }

  /// Model -> JSON (for insert)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chat_id': chatId,
      'role': role.value,
      'content': content,
      'created_at': createdAt.toIso8601String(),
      if (suggestedQuestions != null) 'suggested_questions': suggestedQuestions,
    };
  }

  /// Entity -> Model
  factory ChatMessageModel.fromEntity(ChatMessage entity) {
    return ChatMessageModel(
      id: entity.id,
      chatId: entity.chatId,
      role: entity.role,
      content: entity.content,
      createdAt: entity.createdAt,
      suggestedQuestions: entity.suggestedQuestions,
    );
  }

  /// API 응답 -> Model (Edge Function 응답)
  factory ChatMessageModel.fromApiResponse(
    Map<String, dynamic> json,
    String chatId,
  ) {
    return ChatMessageModel(
      id: json['messageId'] as String,
      chatId: chatId,
      role: MessageRole.assistant,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      suggestedQuestions: json['suggestedQuestions'] != null
          ? List<String>.from(json['suggestedQuestions'] as List)
          : null,
    );
  }
}
