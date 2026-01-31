/// Chat 스키마 정의
///
/// Supabase chat_sessions, chat_messages 테이블 스키마 매핑

// ============================================================================
// Chat Sessions
// ============================================================================

/// 세션 테이블명
const String chatSessionsTable = 'chat_sessions';

/// 세션 컬럼명 상수
abstract class ChatSessionColumns {
  static const String id = 'id';
  static const String profileId = 'profile_id';
  static const String title = 'title';
  static const String chatType = 'chat_type';
  static const String messageCount = 'message_count';
  static const String lastMessagePreview = 'last_message_preview';
  static const String contextSummary = 'context_summary';
  static const String createdAt = 'created_at';
  static const String updatedAt = 'updated_at';
  static const String targetProfileId = 'target_profile_id';
  static const String totalTokensUsed = 'total_tokens_used';
  static const String userMessageCount = 'user_message_count';
  static const String assistantMessageCount = 'assistant_message_count';
  static const String chatPersona = 'chat_persona';
  static const String mbtiQuadrant = 'mbti_quadrant';
}

/// 세션 SELECT 컬럼
const String chatSessionSelectColumns = '''
  id,
  profile_id,
  title,
  chat_type,
  message_count,
  last_message_preview,
  context_summary,
  created_at,
  updated_at,
  target_profile_id,
  total_tokens_used,
  user_message_count,
  assistant_message_count,
  chat_persona,
  mbti_quadrant
''';

/// 세션 리스트용 (간략)
const String chatSessionListColumns = '''
  id,
  title,
  chat_type,
  message_count,
  last_message_preview,
  updated_at,
  chat_persona,
  mbti_quadrant
''';

// ============================================================================
// Chat Messages
// ============================================================================

/// 메시지 테이블명
const String chatMessagesTable = 'chat_messages';

/// 메시지 컬럼명 상수
abstract class ChatMessageColumns {
  static const String id = 'id';
  static const String sessionId = 'session_id';
  static const String content = 'content';
  static const String role = 'role';
  static const String status = 'status';
  static const String tokensUsed = 'tokens_used';
  static const String suggestedQuestions = 'suggested_questions';
  static const String createdAt = 'created_at';
}

/// 메시지 SELECT 컬럼
const String chatMessageSelectColumns = '''
  id,
  session_id,
  content,
  role,
  status,
  tokens_used,
  suggested_questions,
  created_at
''';

/// 메시지 리스트용 (간략)
const String chatMessageListColumns = '''
  id,
  content,
  role,
  created_at
''';

// ============================================================================
// Enums
// ============================================================================

/// 채팅 타입
enum ChatTypeDb {
  general('general'),
  today('today'),
  love('love'),
  career('career'),
  finance('finance'),
  health('health');

  final String value;
  const ChatTypeDb(this.value);
}

/// 메시지 역할
enum MessageRoleDb {
  user('user'),
  assistant('assistant'),
  system('system');

  final String value;
  const MessageRoleDb(this.value);
}

/// 메시지 상태
enum MessageStatusDb {
  sending('sending'),
  sent('sent'),
  error('error');

  final String value;
  const MessageStatusDb(this.value);
}
