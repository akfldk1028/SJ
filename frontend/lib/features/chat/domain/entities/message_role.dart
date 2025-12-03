/// 메시지 역할 (발신자)
enum MessageRole {
  user,      // 사용자 메시지
  assistant, // AI 응답
}

extension MessageRoleExtension on MessageRole {
  String get value {
    switch (this) {
      case MessageRole.user:
        return 'user';
      case MessageRole.assistant:
        return 'assistant';
    }
  }

  static MessageRole fromString(String value) {
    switch (value) {
      case 'user':
        return MessageRole.user;
      case 'assistant':
        return MessageRole.assistant;
      default:
        throw ArgumentError('Unknown MessageRole: $value');
    }
  }
}
