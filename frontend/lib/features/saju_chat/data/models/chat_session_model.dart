import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/chat_session.dart';
import '../../domain/models/chat_type.dart';

part 'chat_session_model.freezed.dart';
part 'chat_session_model.g.dart';

/// 채팅 세션 데이터 모델
///
/// Entity를 확장하여 JSON/Hive 직렬화 기능 추가
/// Hive TypeAdapter를 사용하지 않고 Map으로 저장
@freezed
abstract class ChatSessionModel with _$ChatSessionModel {
  const factory ChatSessionModel({
    required String id,
    required String title,
    required String chatType, // ChatType enum을 문자열로 저장
    String? profileId,
    String? targetProfileId, // 궁합 채팅 시 상대방 프로필 ID
    required DateTime createdAt,
    required DateTime updatedAt,
    @Default(0) int messageCount,
    String? lastMessagePreview,
  }) = _ChatSessionModel;

  const ChatSessionModel._();

  /// JSON 직렬화
  factory ChatSessionModel.fromJson(Map<String, dynamic> json) =>
      _$ChatSessionModelFromJson(json);

  /// Entity로 변환
  ChatSession toEntity() {
    return ChatSession(
      id: id,
      title: title,
      chatType: ChatType.fromString(chatType),
      profileId: profileId,
      targetProfileId: targetProfileId,
      createdAt: createdAt,
      updatedAt: updatedAt,
      messageCount: messageCount,
      lastMessagePreview: lastMessagePreview,
    );
  }

  /// Entity에서 생성
  static ChatSessionModel fromEntity(ChatSession entity) {
    return ChatSessionModel(
      id: entity.id,
      title: entity.title,
      chatType: entity.chatType.name,
      profileId: entity.profileId,
      targetProfileId: entity.targetProfileId,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      messageCount: entity.messageCount,
      lastMessagePreview: entity.lastMessagePreview,
    );
  }

  /// Hive에 저장할 Map으로 변환
  Map<String, dynamic> toHiveMap() {
    return {
      'id': id,
      'title': title,
      'chatType': chatType,
      'profileId': profileId,
      'targetProfileId': targetProfileId,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'messageCount': messageCount,
      'lastMessagePreview': lastMessagePreview,
    };
  }

  /// Hive Map에서 생성
  static ChatSessionModel fromHiveMap(Map<dynamic, dynamic> map) {
    return ChatSessionModel(
      id: map['id'] as String,
      title: map['title'] as String,
      chatType: map['chatType'] as String,
      profileId: map['profileId'] as String?,
      targetProfileId: map['targetProfileId'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] as int),
      messageCount: (map['messageCount'] as int?) ?? 0,
      lastMessagePreview: map['lastMessagePreview'] as String?,
    );
  }

  /// Supabase에 저장할 Map으로 변환 (snake_case)
  Map<String, dynamic> toSupabaseMap() {
    return {
      'id': id,
      'profile_id': profileId,
      'target_profile_id': targetProfileId,
      'title': title,
      'chat_type': chatType,
      'message_count': messageCount,
      'last_message_preview': lastMessagePreview,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Supabase INSERT용 (id, created_at, updated_at, message_count 제외)
  Map<String, dynamic> toSupabaseInsert() {
    return {
      'profile_id': profileId,
      'target_profile_id': targetProfileId,
      'title': title,
      'chat_type': chatType,
    };
  }

  /// Supabase Map에서 생성 (snake_case → camelCase)
  static ChatSessionModel fromSupabaseMap(Map<String, dynamic> map) {
    return ChatSessionModel(
      id: map['id'] as String,
      title: (map['title'] as String?) ?? '새 대화',
      chatType: (map['chat_type'] as String?) ?? 'general',
      profileId: map['profile_id'] as String?,
      targetProfileId: map['target_profile_id'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      messageCount: (map['message_count'] as int?) ?? 0,
      lastMessagePreview: map['last_message_preview'] as String?,
    );
  }
}
