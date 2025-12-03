import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/services/gemini_service.dart';
import '../../../profile/domain/entities/gender.dart';
import '../../../profile/domain/entities/saju_profile.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/message_role.dart';

part 'chat_provider.g.dart';

/// 현재 채팅 상태
class ChatState {
  final String profileId;
  final List<ChatMessage> messages;
  final bool isLoading;
  final bool isStreaming;
  final String? error;
  final String? streamingContent; // 스트리밍 중인 응답 내용

  const ChatState({
    required this.profileId,
    this.messages = const [],
    this.isLoading = false,
    this.isStreaming = false,
    this.error,
    this.streamingContent,
  });

  ChatState copyWith({
    String? profileId,
    List<ChatMessage>? messages,
    bool? isLoading,
    bool? isStreaming,
    String? error,
    String? streamingContent,
  }) {
    return ChatState(
      profileId: profileId ?? this.profileId,
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isStreaming: isStreaming ?? this.isStreaming,
      error: error,
      streamingContent: streamingContent,
    );
  }
}

/// 채팅 Notifier (Gemini 스트리밍 채팅)
@riverpod
class Chat extends _$Chat {
  GeminiService? _geminiService;

  @override
  ChatState build(String profileId) {
    // Gemini 서비스 초기화
    _initGemini(profileId);

    return ChatState(profileId: profileId);
  }

  /// Gemini 서비스 초기화 (프로필 컨텍스트 포함)
  Future<void> _initGemini(String profileId) async {
    _geminiService = ref.read(geminiServiceProvider);

    // 프로필 정보 가져오기
    final profile = await ref.read(profileByIdProvider(profileId).future);

    if (profile != null) {
      final profileContext = _buildProfileContext(profile);
      _geminiService!.startNewChat(profileContext: profileContext);
    } else {
      _geminiService!.startNewChat();
    }
  }

  /// 프로필 정보를 문자열로 변환
  String _buildProfileContext(SajuProfile profile) {
    final buffer = StringBuffer();

    buffer.writeln('이름: ${profile.displayName}');
    buffer.writeln('성별: ${profile.gender == Gender.male ? "남성" : "여성"}');
    buffer.writeln(
        '생년월일: ${profile.birthDate.year}년 ${profile.birthDate.month}월 ${profile.birthDate.day}일');

    if (profile.isLunar) {
      buffer.writeln('(음력)');
    }

    if (!profile.birthTimeUnknown && profile.birthTimeMinutes != null) {
      final hour = profile.birthTimeMinutes! ~/ 60;
      final minute = profile.birthTimeMinutes! % 60;
      buffer.writeln('출생시간: ${hour.toString().padLeft(2, '0')}시 ${minute.toString().padLeft(2, '0')}분');
    } else {
      buffer.writeln('출생시간: 알 수 없음');
    }

    if (profile.birthPlace != null) {
      buffer.writeln('출생지: ${profile.birthPlace}');
    }

    return buffer.toString();
  }

  /// 스트리밍 메시지 전송
  Future<void> sendMessage(String content) async {
    if (content.trim().isEmpty) return;
    if (state.isLoading || state.isStreaming) return;

    // Gemini 서비스가 없으면 초기화 대기
    if (_geminiService == null) {
      await _initGemini(state.profileId);
    }

    // 사용자 메시지 즉시 추가
    final userMessage = ChatMessage(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      chatId: state.profileId,
      role: MessageRole.user,
      content: content,
      createdAt: DateTime.now(),
    );

    state = state.copyWith(
      messages: [...state.messages, userMessage],
      isLoading: true,
      isStreaming: true,
      streamingContent: '',
      error: null,
    );

    try {
      final buffer = StringBuffer();

      // 스트리밍 응답 받기
      await for (final chunk in _geminiService!.sendMessageStream(content)) {
        buffer.write(chunk);

        // 스트리밍 중 UI 업데이트
        state = state.copyWith(
          streamingContent: buffer.toString(),
        );
      }

      // 스트리밍 완료 - AI 응답 메시지 추가
      final aiMessage = ChatMessage(
        id: 'ai_${DateTime.now().millisecondsSinceEpoch}',
        chatId: state.profileId,
        role: MessageRole.assistant,
        content: buffer.toString(),
        createdAt: DateTime.now(),
      );

      state = state.copyWith(
        messages: [...state.messages, aiMessage],
        isLoading: false,
        isStreaming: false,
        streamingContent: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isStreaming: false,
        streamingContent: null,
        error: 'AI 응답 오류: ${e.toString()}',
      );
    }
  }

  /// 추천 질문 선택
  void selectSuggestedQuestion(String question) {
    sendMessage(question);
  }

  /// 새 대화 시작
  void startNewChat() {
    _geminiService?.resetChat();
    state = ChatState(profileId: state.profileId);
    _initGemini(state.profileId);
  }

  /// 에러 초기화
  void clearError() {
    state = state.copyWith(error: null);
  }
}
