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
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] as int),
      messageCount: (map['messageCount'] as int?) ?? 0,
      lastMessagePreview: map['lastMessagePreview'] as String?,
    );
  }
}
