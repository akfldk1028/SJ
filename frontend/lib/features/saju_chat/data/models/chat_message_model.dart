import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/chat_message.dart';

part 'chat_message_model.freezed.dart';
part 'chat_message_model.g.dart';

/// 채팅 메시지 데이터 모델
///
/// Entity를 확장하여 JSON/Hive 직렬화 기능 추가
/// Hive TypeAdapter를 사용하지 않고 Map으로 저장
@freezed
abstract class ChatMessageModel with _$ChatMessageModel {
  const factory ChatMessageModel({
    required String id,
    required String sessionId,
    required String content,
    required String role, // MessageRole enum을 문자열로 저장
    required DateTime createdAt,
    @Default('sent') String status, // MessageStatus enum을 문자열로 저장
  }) = _ChatMessageModel;

  const ChatMessageModel._();

  /// JSON 직렬화
  factory ChatMessageModel.fromJson(Map<String, dynamic> json) =>
      _$ChatMessageModelFromJson(json);

  /// Entity로 변환
  ChatMessage toEntity() {
    return ChatMessage(
      id: id,
      sessionId: sessionId,
      content: content,
      role: _parseRole(role),
      createdAt: createdAt,
      status: _parseStatus(status),
    );
  }

  /// Entity에서 생성
  static ChatMessageModel fromEntity(ChatMessage entity) {
    return ChatMessageModel(
      id: entity.id,
      sessionId: entity.sessionId,
      content: entity.content,
      role: entity.role.name,
      createdAt: entity.createdAt,
      status: entity.status.name,
    );
  }

  /// Hive에 저장할 Map으로 변환
  Map<String, dynamic> toHiveMap() {
    return {
      'id': id,
      'sessionId': sessionId,
      'content': content,
      'role': role,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'status': status,
    };
  }

  /// Hive Map에서 생성
  static ChatMessageModel fromHiveMap(Map<dynamic, dynamic> map) {
    return ChatMessageModel(
      id: map['id'] as String,
      sessionId: map['sessionId'] as String,
      content: map['content'] as String,
      role: map['role'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
      status: (map['status'] as String?) ?? 'sent',
    );
  }

  /// 문자열을 MessageRole로 변환
  static MessageRole _parseRole(String role) {
    switch (role) {
      case 'user':
        return MessageRole.user;
      case 'assistant':
        return MessageRole.assistant;
      case 'system':
        return MessageRole.system;
      default:
        return MessageRole.user;
    }
  }

  /// 문자열을 MessageStatus로 변환
  static MessageStatus _parseStatus(String status) {
    switch (status) {
      case 'sending':
        return MessageStatus.sending;
      case 'sent':
        return MessageStatus.sent;
      case 'error':
        return MessageStatus.error;
      default:
        return MessageStatus.sent;
    }
  }
}
