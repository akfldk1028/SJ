import 'package:freezed_annotation/freezed_annotation.dart';
import 'message_role.dart';

part 'chat_message.freezed.dart';
part 'chat_message.g.dart';

@freezed
class ChatMessage with _$ChatMessage {
  const factory ChatMessage({
    required String id,
    required String sessionId,
    required MessageRole role,
    required String content,
    required DateTime createdAt,
    @Default(false) bool isError,
  }) = _ChatMessage;

  factory ChatMessage.fromJson(Map<String, dynamic> json) =>
      _$ChatMessageFromJson(json);
}
