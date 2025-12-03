import '../../domain/entities/chat_session.dart';

/// ChatSession 데이터 모델 (Data Layer)
/// Supabase JSON <-> Entity 변환
class ChatSessionModel extends ChatSession {
  const ChatSessionModel({
    required super.id,
    required super.profileId,
    super.title,
    required super.createdAt,
    required super.lastMessageAt,
    super.messageCount,
  });

  /// JSON -> Model
  factory ChatSessionModel.fromJson(Map<String, dynamic> json) {
    return ChatSessionModel(
      id: json['id'] as String,
      profileId: json['profile_id'] as String,
      title: json['title'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      lastMessageAt: DateTime.parse(json['last_message_at'] as String),
      messageCount: json['message_count'] as int? ?? 0,
    );
  }

  /// Model -> JSON (for insert)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'profile_id': profileId,
      if (title != null) 'title': title,
      'created_at': createdAt.toIso8601String(),
      'last_message_at': lastMessageAt.toIso8601String(),
      'message_count': messageCount,
    };
  }

  /// Entity -> Model
  factory ChatSessionModel.fromEntity(ChatSession entity) {
    return ChatSessionModel(
      id: entity.id,
      profileId: entity.profileId,
      title: entity.title,
      createdAt: entity.createdAt,
      lastMessageAt: entity.lastMessageAt,
      messageCount: entity.messageCount,
    );
  }
}
