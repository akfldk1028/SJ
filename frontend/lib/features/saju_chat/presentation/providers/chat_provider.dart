import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../../data/datasources/gemini_datasource.dart';
import '../../data/repositories/chat_repository_impl.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/models/chat_type.dart';
import '../../domain/repositories/chat_repository.dart';

part 'chat_provider.g.dart';

/// 채팅 상태
class ChatState {
  final List<ChatMessage> messages;
  final bool isLoading;
  final String? streamingContent;
  final String? error;

  const ChatState({
    this.messages = const [],
    this.isLoading = false,
    this.streamingContent,
    this.error,
  });

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    String? streamingContent,
    String? error,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      streamingContent: streamingContent,
      error: error,
    );
  }
}

/// ChatRepository Provider
@riverpod
ChatRepository chatRepository(ChatRepositoryRef ref) {
  return ChatRepositoryImpl(
    datasource: GeminiDatasource(),
  );
}

/// 채팅 상태 관리 Provider
@riverpod
class ChatNotifier extends _$ChatNotifier {
  final _uuid = const Uuid();

  @override
  ChatState build(ChatType chatType) {
    // 초기 환영 메시지 추가
    final welcomeMessage = ChatMessage(
      id: _uuid.v4(),
      content: chatType.welcomeMessage,
      role: MessageRole.assistant,
      createdAt: DateTime.now(),
    );

    return ChatState(messages: [welcomeMessage]);
  }

  /// 시스템 프롬프트 생성
  String _getSystemPrompt(ChatType chatType) {
    switch (chatType) {
      case ChatType.dailyFortune:
        return '''당신은 전문 사주 상담사입니다.
사용자의 오늘 운세에 대해 친절하고 긍정적으로 상담해 주세요.
한국어로 대답하고, 이모지를 적절히 사용해 주세요.
너무 부정적인 내용은 완화해서 전달해 주세요.''';

      case ChatType.sajuAnalysis:
        return '''당신은 전문 사주팔자 분석가입니다.
사용자의 생년월일시를 받아 사주팔자를 분석해 주세요.
한국어로 대답하고, 전문적이면서도 이해하기 쉽게 설명해 주세요.
음양오행, 천간지지 등의 개념을 활용해 주세요.''';

      case ChatType.compatibility:
        return '''당신은 전문 궁합 상담사입니다.
두 사람의 생년월일을 받아 궁합을 분석해 주세요.
한국어로 대답하고, 긍정적인 관점에서 조언해 주세요.
부정적인 내용도 개선 방안과 함께 전달해 주세요.''';

      default:
        return '''당신은 친절한 사주 상담 AI입니다.
사용자의 질문에 성실하게 답변해 주세요.
한국어로 대답해 주세요.''';
    }
  }

  /// 메시지 전송
  Future<void> sendMessage(String content) async {
    if (content.trim().isEmpty) return;

    final chatType = this.chatType;
    final repository = ref.read(chatRepositoryProvider);

    // 사용자 메시지 추가
    final userMessage = ChatMessage(
      id: _uuid.v4(),
      content: content,
      role: MessageRole.user,
      createdAt: DateTime.now(),
    );

    state = state.copyWith(
      messages: [...state.messages, userMessage],
      isLoading: true,
      error: null,
    );

    try {
      // 스트리밍 응답
      final stream = repository.sendMessageStream(
        userMessage: content,
        conversationHistory: state.messages,
        systemPrompt: _getSystemPrompt(chatType),
      );

      String fullContent = '';
      await for (final chunk in stream) {
        fullContent = chunk;
        state = state.copyWith(
          streamingContent: fullContent,
        );
      }

      // 스트리밍 완료 후 메시지로 추가
      final aiMessage = ChatMessage(
        id: _uuid.v4(),
        content: fullContent,
        role: MessageRole.assistant,
        createdAt: DateTime.now(),
      );

      state = state.copyWith(
        messages: [...state.messages, aiMessage],
        isLoading: false,
        streamingContent: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        streamingContent: null,
        error: '메시지 전송 중 오류가 발생했습니다.',
      );
    }
  }

  /// 대화 초기화
  void clearMessages() {
    final welcomeMessage = ChatMessage(
      id: _uuid.v4(),
      content: chatType.welcomeMessage,
      role: MessageRole.assistant,
      createdAt: DateTime.now(),
    );

    state = ChatState(messages: [welcomeMessage]);
  }
}
